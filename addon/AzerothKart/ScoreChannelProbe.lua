-- Explicit finite capability check; never publishes scores or runs on login.
-- Logged CHANNEL is a candidate, not established by WHISPER's client evidence.
local _, AK = ...
local Probe = {PREFIX="AZKSCP1", CHANNEL="AzerothKartScoresProbe"}
AK.ScoreChannelProbe = Probe
local frame, reporter, state, serial = nil, nil, nil, 0
local arming, finishing = false, false

local function plain(value)
    if type(issecretvalue) == "function" then
        local ok, secret = pcall(issecretvalue, value)
        if not ok or secret then return false end
    end
    return true
end

local function read(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, ...)
    if ok and plain(value) then return value end
end

local function number(value, minimum, maximum)
    return plain(value) and type(value)=="number" and value==value
        and value>=minimum and value<=maximum
end

local function name(value)
    return plain(value) and type(value)=="string" and #value>0 and #value<=96
        and not value:find("[%c|]") and value or nil
end

local function active()
    return state and (state.phase=="joining" or state.phase=="checking")
end

function Probe.IsActive() return not not active() end

local function report(text)
    if reporter then pcall(reporter, text)
    elseif DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("Azeroth Kart scores: "..text)
    else print("Azeroth Kart scores: "..text) end
end

local function blocked()
    if AK.UI and AK.UI.active then return "drive_active" end
    if read(InCombatLockdown)~=false then return "combat_or_unavailable" end
    if type(C_ChatInfo)=="table" and type(C_ChatInfo.InChatMessagingLockdown)=="function"
        and read(C_ChatInfo.InChatMessagingLockdown)~=false then return "chat_locked" end
end

local function channel()
    local ok, id, channelName = pcall(GetChannelName, Probe.CHANNEL)
    if not ok or not plain(id) or not plain(channelName) then return nil end
    if id==0 then return 0 end
    if number(id,1,1000) and id%1==0 and name(channelName)
        and channelName:lower()==Probe.CHANNEL:lower() then return id end
end

function Probe.GetView()
    local view={phase="idle",reason="not_run",sent=0,accepted=0,selfEchoes=0,peerHellos=0,peerAcks=0}
    if state then
        for key,value in pairs(state) do
            if type(value)~="table" and type(value)~="function" then view[key]=value end
        end
    end
    -- No mutable queue, native function or identity roster is exposed.
    view.localName=nil
    return view
end

function Probe.Report()
    local s=Probe.GetView()
    report(("%s (%s) | sent=%d accepted=%d selfEcho=%d peerHello=%d peerACK=%d"):format(
        s.phase,s.reason,s.sent,s.accepted,s.selfEchoes,s.peerHellos,s.peerAcks))
    report("route=CHANNEL_LOGGED channel="..tostring(s.channelId or "unresolved")
        .." send="..tostring(s.sendResult or "not_attempted").." build="..tostring(s.build or "unknown")
        .." cleanup="..tostring(s.cleanup or "not_needed"))
    if s.eventCount then
        report("event route="..tostring(s.eventRoute).." localID="..tostring(s.eventLocalId)
            .." name="..tostring(s.eventName).." rejected="..tostring(s.lastReject or "none"))
    end
    if s.peerAcks>0 then
        report("Peer reply observed. Scores remain unpublished; offline/global coverage is unverified.")
    elseif s.selfEchoes>0 then
        report("Self echo only. Delivery to another player is still unverified.")
    else report("No peer delivery proof. Acceptance alone does not establish delivery.") end
end

function Probe.Stop(reason)
    if not active() then return end
    finishing=true
    state.phase,state.reason="stopped",reason or "manual_stop"
    if frame and frame.akNetworkOwner==Probe then
        pcall(frame.SetScript,frame,"OnUpdate",nil)
        pcall(frame.UnregisterEvent,frame,"CHAT_MSG_ADDON_LOGGED")
        if state.joinedByProbe then
            local ok,result=pcall(LeaveChannelByName,Probe.CHANNEL)
            state.cleanup=ok and plain(result) and result~=false and "leave_requested" or "leave_failed"
        else state.cleanup="membership_preserved" end
        frame.akNetworkOwner=nil
    end
    state.queue,state.peers,state.acks={},{},{}
    Probe.Report()
    finishing=false
end

local function clock()
    local now=read(GetTime)
    if not number(now,0,100000000000) then return nil end
    if state and now<state.lastNow then return nil end
    if state then state.lastNow=now end
    return now
end

local function send(payload,now)
    local current=state
    state.sent,state.nextSend=state.sent+1,now+2
    frame.akNetworkSending=Probe
    local ok,result=pcall(C_ChatInfo.SendAddonMessageLogged,Probe.PREFIX,payload,"CHANNEL",state.channelId)
    if frame.akNetworkSending==Probe then frame.akNetworkSending=nil end
    if state~=current or not active() or frame.akNetworkOwner~=Probe then return end
    if not ok or not plain(result) then
        state.sendResult="error_or_protected"; Probe.Stop("send_refused"); return
    end
    if number(result,0,32) and result%1==0 then state.sendResult="number:"..tostring(result)
    else state.sendResult=type(result) end
    if result~=state.sendSuccess then Probe.Stop("send_not_accepted"); return end
    state.accepted=state.accepted+1
end

function Probe.Update()
    if not active() then return end
    local reason=blocked()
    if reason then Probe.Stop(reason); return end
    local now=clock()
    if not now then Probe.Stop("clock_unavailable"); return end
    if now>=state.deadline then Probe.Stop("check_complete"); return end
    if state.phase=="joining" then
        local id=channel()
        if id and id>0 then
            state.phase,state.channelId,state.joinedAt="checking",id,now
        elseif now>=state.joinDeadline then Probe.Stop("join_timeout"); return
        else return end
    end
    if now<state.nextSend or state.sent>=6 then return end
    -- Re-resolve immediately before each send; never target a reused channel ID.
    if channel()~=state.channelId then Probe.Stop("channel_changed"); return end
    if #state.queue>0 then
        send(table.remove(state.queue,1),now)
    elseif state.hellosSent<3 and now>=state.joinedAt+state.hellosSent*6 then
        state.hellosSent=state.hellosSent+1
        send("1|H|"..state.token,now)
    end
end

local function token(value)
    return type(value)=="string" and #value>=1 and #value<=40 and value:match("^[%d%-]+$")
end

local function receive(prefix,payload,route,sender,_,__,localID,channelName)
    if not plain(prefix) or prefix~=Probe.PREFIX then return end
    state.eventCount=math.min(100,(state.eventCount or 0)+1)
    if state.eventCount==1 then
        state.eventRoute=name(route) or "unreadable"
        state.eventLocalId=number(localID,0,1000) and localID or "unreadable"
        state.eventName=name(channelName) or "unavailable"
    end
    for _,value in ipairs({prefix,payload,route,sender,localID}) do
        if not plain(value) then state.lastReject="protected_event"; return end
    end
    if prefix~=Probe.PREFIX or route~="CHANNEL" or localID~=state.channelId
        or type(payload)~="string" or #payload>90 or not name(sender) then state.lastReject="event_fields"; return end
    if channelName~=nil and (not name(channelName) or channelName:lower()~=Probe.CHANNEL:lower()) then
        state.lastReject="channel_name"; return
    end
    local own=sender:lower()==state.localName:lower()
    local hello=payload:match("^1|H|([%d%-]+)$")
    if token(hello) then
        if own then
            if hello==state.token then state.selfEchoes=math.min(3,state.selfEchoes+1) end
        elseif not state.peers[sender:lower()] and state.peerHellos<3 then
            state.peers[sender:lower()]=hello
            state.peerHellos=state.peerHellos+1
            state.queue[#state.queue+1]="1|A|"..hello.."|"..state.token
        end
        return
    end
    local recipient,other=payload:match("^1|A|([%d%-]+)|([%d%-]+)$")
    if not own and state.hellosSent>0 and recipient==state.token and token(other)
        and not state.acks[sender:lower()] and state.peerAcks<3 then
        state.acks[sender:lower()]=true; state.peerAcks=state.peerAcks+1
    end
end

function Probe.Message(...)
    if not active() or state.phase~="checking" then return end
    local reason=blocked()
    if reason then Probe.Stop(reason); return end
    local now=clock()
    if not now then Probe.Stop("clock_unavailable"); return end
    if now>=state.deadline then Probe.Stop("check_complete"); return end
    -- Never unwrap protected/secret values; discard unreadable events.
    pcall(receive,...)
end

function Probe.Init(eventFrame,callback) frame,reporter=eventFrame,callback end

local function arm()
    if active() then report("Check already running; /akart scores stop to cancel."); return false end
    if not frame or frame.akNetworkOwner or frame.akNetworkSending then
        report("Network busy. Leave the multiplayer lobby or stop its probe first."); return false
    end
    local reason=blocked()
    if reason then report("Check refused: "..reason); return false end
    if type(C_ChatInfo)~="table" or type(C_ChatInfo.RegisterAddonMessagePrefix)~="function"
        or type(C_ChatInfo.SendAddonMessageLogged)~="function" or type(JoinPermanentChannel)~="function"
        or type(GetChannelName)~="function" or type(LeaveChannelByName)~="function"
        or type(Enum)~="table" or type(Enum.RegisterAddonMessagePrefixResult)~="table"
        or type(Enum.SendAddonMessageResult)~="table" then report("Channel APIs unavailable"); return false end
    local r=Enum.RegisterAddonMessagePrefixResult
    local success=Enum.SendAddonMessageResult.Success
    if not number(r.Success,0,32) or not number(r.DuplicatePrefix,0,32)
        or not number(success,0,32) or r.Success%1~=0 or r.DuplicatePrefix%1~=0
        or success%1~=0 or r.Success==r.DuplicatePrefix then report("Result enums unavailable"); return false end
    local now,epoch=read(GetTime),read(GetServerTime)
    local identity=type(NameUtil)=="table" and name(read(NameUtil.GetUnmodifiedUnitFullName,"player"))
    local id=channel()
    if not number(now,0,100000000000) or not number(epoch,1,4102444800) or not identity or not id then
        report("Readable identity, clock or channel lookup unavailable"); return false
    end
    if AK.SessionTransport and not AK.SessionTransport.DiagnosticTrafficQuiet(now) then
        report("Wait one second after the group check before starting another probe"); return false
    end
    serial=serial+1
    state={phase="joining",reason="checking",lastNow=now,deadline=now+30,joinDeadline=now+8,
        nextSend=now,joinedAt=now,channelId=id,localName=identity,sendSuccess=success,
        token=("%d-%d-%d"):format(epoch,math.floor(now*1000),serial),
        sent=0,accepted=0,hellosSent=0,selfEchoes=0,peerHellos=0,peerAcks=0,queue={},peers={},acks={}}
    if type(GetBuildInfo)=="function" then
        local ok,_,build=pcall(GetBuildInfo)
        if ok and plain(build) and type(build)=="string" and #build<=24 then state.build=build end
    end
    frame.akNetworkOwner=Probe
    local current=state
    local function owned() return state==current and active() and frame.akNetworkOwner==Probe end
    local ok,result=pcall(C_ChatInfo.RegisterAddonMessagePrefix,Probe.PREFIX)
    if not owned() then return false end
    if not ok or not plain(result) or (result~=r.Success and result~=r.DuplicatePrefix) then
        Probe.Stop("prefix_refused"); return false
    end
    ok,result=pcall(frame.RegisterEvent,frame,"CHAT_MSG_ADDON_LOGGED")
    if not owned() then return false end
    if not ok or result==false then Probe.Stop("event_refused"); return false end
    if id==0 then
        state.joinedByProbe=true
        ok,result=pcall(JoinPermanentChannel,Probe.CHANNEL)
        if not owned() then return false end
        if not ok or not plain(result) or result==false then Probe.Stop("join_refused"); return false end
    end
    ok,result=pcall(frame.SetScript,frame,"OnUpdate",Probe.Update)
    if not owned() then return false end
    if not ok or result==false then Probe.Stop("update_refused"); return false end
    report("Checking dedicated score channel for 30 seconds (no scores sent). Result prints automatically.")
    return true
end

function Probe.Start()
    if arming or finishing then return false end
    arming=true
    local ok,result=pcall(arm)
    if not ok then Probe.Stop("start_error") end
    arming=false
    return ok and result or false
end

function Probe.HandleEvent(event)
    if event=="PLAYER_REGEN_DISABLED" or event=="PLAYER_LEAVING_WORLD" or event=="PLAYER_LOGOUT" then
        Probe.Stop(event)
    end
end

function Probe.Command(argument)
    if argument=="check" then return Probe.Start()
    elseif argument=="report" then Probe.Report()
    elseif argument=="stop" then Probe.Stop()
    else report("/akart scores check (30s), /akart scores report, /akart scores stop") end
end
