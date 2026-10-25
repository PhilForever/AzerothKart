-- Explicit finite group-route diagnostic. Never enables a multiplayer route.
-- Logged multicast delivery needs peer receipts; a successful send is not proof.
local _, AK = ...
local Probe = {PREFIX="AZKGRP1", DATA_SECONDS=20, DRAIN_SECONDS=4, QUIET_SECONDS=1, PLANNED=10}
AK.GroupProbe = Probe
local frame, reporter, state, arming
local used, usedCount = {}, 0
local MAX_CLOCK = 10000000000
local sendNames = {"Success","InvalidPrefix","InvalidMessage","AddonMessageThrottle",
    "InvalidChatType","NotInGroup","TargetRequired","InvalidChannel","ChannelThrottle",
    "GeneralError","NotInGuild","AddOnMessageLockdown","TargetOffline"}

local function plain(value)
    if type(issecretvalue)=="function" then
        local ok,secret=pcall(issecretvalue,value)
        if not ok or secret then return false end
    end
    return true
end
local function read(fn,...)
    if type(fn)~="function" then return nil end
    local ok,value=pcall(fn,...)
    if ok and plain(value) then return value end
end
local function integer(value,minimum,maximum)
    return plain(value) and type(value)=="number" and value==value and value%1==0
        and value>=minimum and value<=maximum
end
local function key(value)
    return (value:gsub("[A-Z]",function(c) return string.char(c:byte()+32) end))
end
local function fullName(value)
    if not plain(value) or type(value)~="string" or #value<1 or #value>96
        or value:find("[%c|]") then return nil end
    value=value:gsub("^ +",""):gsub(" +$",""):gsub(" +"," ")
    return value~="" and value or nil
end
local function active() return state and state.phase~="stopped" end
local function owned(current)
    return state==current and active() and frame and frame.akNetworkOwner==Probe
end
local function report(text)
    if reporter then pcall(reporter,text)
    elseif DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("Azeroth Kart group: "..text)
    else print("Azeroth Kart group: "..text) end
end
local function blocked()
    if AK.UI and (AK.UI.active or AK.UI.liveArmed) then return "drive_active" end
    if read(InCombatLockdown)~=false then return "combat_or_unavailable" end
    if type(C_ChatInfo)=="table" and type(C_ChatInfo.InChatMessagingLockdown)=="function"
        and read(C_ChatInfo.InChatMessagingLockdown)~=false then return "chat_locked" end
end
local function clock()
    local now=read(GetTime)
    if type(now)~="number" or now~=now or now<0 or now>MAX_CLOCK
        or (state and active() and now<state.lastNow) then return nil end
    if active() then state.lastNow=now end
    return now
end
local function roster(route)
    local raid=read(IsInRaid)
    if type(raid)~="boolean" or (route=="RAID")~=raid then return nil,"group_route" end
    local count=read(GetNumGroupMembers)
    if not integer(count,2,8) or type(NameUtil)~="table"
        or type(NameUtil.GetUnmodifiedUnitFullName)~="function" then return nil,"group_roster" end
    local own=fullName(read(NameUtil.GetUnmodifiedUnitFullName,"player"))
    if not own then return nil,"identity" end
    local names,order={},{}
    local function add(unit)
        local name=fullName(read(NameUtil.GetUnmodifiedUnitFullName,unit))
        if not name or names[key(name)] then return false end
        names[key(name)]=name; order[#order+1]=key(name); return true
    end
    if raid then
        for index=1,count do if not add("raid"..index) then return nil,"group_roster" end end
    else
        if not add("player") then return nil,"group_roster" end
        for index=1,count-1 do if not add("party"..index) then return nil,"group_roster" end end
    end
    if not names[key(own)] then return nil,"group_roster" end
    table.sort(order)
    return {names=names,order=order,own=own,ownKey=key(own),count=count}
end
local function sameRoster(a,b)
    if not b or a.ownKey~=b.ownKey or a.count~=b.count then return false end
    for index,name in ipairs(a.order) do if b.order[index]~=name then return false end end
    return true
end
local function sequenceMask(seen)
    local out={}
    for sequence=1,Probe.PLANNED do out[sequence]=seen[sequence] and "1" or "." end
    return table.concat(out)
end
local function latency(samples)
    local sorted={}
    for index,value in ipairs(samples) do sorted[index]=value end
    table.sort(sorted)
    local count=#sorted
    return {count=count,p50=count>0 and sorted[math.ceil(count*0.50)] or nil,
        p95=count>0 and sorted[math.ceil(count*0.95)] or nil,max=sorted[count]}
end
function Probe.GetView()
    local view={phase="idle",reason="not_run",planned=Probe.PLANNED,sent=0,accepted=0,
        received=0,acksSent=0,matched=0,duplicates=0,reordered=0,selfEchoes=0,
        rejected=0,missedSlots=0,deferred=0,throttles=0,errors=0,peers={}}
    if not state then return view end
    for field,value in pairs(state) do
        if type(value)~="table" and type(value)~="function" then view[field]=value end
    end
    view.localName,view.localKey,view.sendAPI,view.success=nil,nil,nil,nil
    view.elapsedSeconds=(state.lastNow or state.startedAt)-state.startedAt
    view.dataAttempts=sequenceMask(state.sentSequences)
    view.peers={}
    for _,nameKey in ipairs(state.roster.order) do
        if nameKey~=state.localKey then
            local peer=state.peers[nameKey]
            view.peers[#view.peers+1]={name=peer.name,received=peer.received,matched=peer.matched,
                duplicates=peer.duplicates,reordered=peer.reordered,
                sequences=sequenceMask(peer.seen),rttMS=latency(peer.rtt)}
        end
    end
    return view
end
function Probe.Report()
    local s=Probe.GetView()
    report(("%s (%s) | %s %s session=%s sent=%d accepted=%d DATA=%d ACKsent=%d matched=%d"):format(
        s.phase,s.reason,s.role or "none",s.route or "unselected",s.session or "none",
        s.sent,s.accepted,s.received,s.acksSent,s.matched))
    report(("build=%s planned=%d attempts=%s missedSlots=%d selfEcho=%d duplicate=%d reordered=%d rejected=%d throttle=%d errors=%d"):format(
        s.build or "unknown",s.planned,s.dataAttempts or "..........",s.missedSlots,s.selfEchoes,s.duplicates,
        s.reordered,s.rejected,s.throttles,s.errors))
    for _,peer in ipairs(s.peers) do
        report(("%s | receipts=%s DATA=%d ACK=%d RTTms n=%d p50=%s p95=%s max=%s"):format(
            peer.name,peer.sequences,peer.received,peer.matched,peer.rttMS.count,
            tostring(peer.rttMS.p50 or "NA"),tostring(peer.rttMS.p95 or "NA"),tostring(peer.rttMS.max or "NA")))
    end
    report("Peer receipts prove only this route/window. Missing receipts are not proven loss; no eight-racer or race-route acceptance.")
end
function Probe.IsActive() return not not (arming or active()) end
function Probe.Init(eventFrame,callback)
    if Probe.IsActive() then return false end
    frame,reporter=eventFrame,callback
    return true
end
function Probe.Stop(reason)
    if not active() then return false end
    local current=state
    current.phase,current.reason="stopped",reason or "manual_stop"
    current.queue={}
    if frame and frame.akNetworkOwner==Probe then
        pcall(frame.SetScript,frame,"OnUpdate",nil)
        for _,event in ipairs({"CHAT_MSG_ADDON_LOGGED","GROUP_ROSTER_UPDATE"}) do
            pcall(frame.UnregisterEvent,frame,event)
        end
        if frame.akNetworkOwner==Probe then frame.akNetworkOwner=nil end
    end
    Probe.Report()
    return true
end
local function verify(now)
    if not active() then return nil end
    if not owned(state) then Probe.Stop("lease_lost"); return nil end
    local reason=blocked()
    if reason then Probe.Stop(reason); return nil end
    if not now then now=clock() end
    if not now then Probe.Stop("clock_unavailable"); return nil end
    if now>=state.deadline then Probe.Stop(state.hostKey and "window_complete" or "no_host"); return nil end
    return now
end
local function encode(kind,session,sequence,stamp)
    return table.concat({"1",kind,session,tostring(sequence),("%.0f"):format(stamp)}," ")
end
local function decimal(text,minimum,maximum)
    if not text:match("^%d+$") or (#text>1 and text:sub(1,1)=="0") then return nil end
    local value=tonumber(text)
    return integer(value,minimum,maximum) and value or nil
end
local function decode(payload)
    if not plain(payload) or type(payload)~="string" or #payload>96 then return nil end
    local kind,session,sequence,stamp=payload:match("^1 ([DA]) ([A-Z0-9]+) (%d+) (%d+)$")
    if not kind or #session~=6 then return nil end
    sequence,stamp=decimal(sequence,1,Probe.PLANNED),decimal(stamp,0,MAX_CLOCK*1000)
    if not sequence or not stamp then return nil end
    return kind,session,sequence,stamp
end
local function reject(reason)
    state.rejected=state.rejected+1; state.lastReject=reason
    if state.rejected>=64 then Probe.Stop("rejected_limit") end
    return false
end
local function send(kind,payload,target,now,sequence,stamp)
    local current=state
    if now<current.nextAttempt then return false end
    local budget=AK.SessionTransport and AK.SessionTransport.ReserveDiagnosticSend
    local ok,reserved,why=pcall(budget,Probe,now,#Probe.PREFIX+#payload)
    if not owned(current) then return false end
    if not ok or not plain(reserved) or type(reserved)~="boolean" then Probe.Stop("budget_unavailable"); return false end
    if not reserved then
        if why~="budget" then Probe.Stop("budget_unavailable"); return false end
        current.deferred=current.deferred+1; current.nextAttempt=now+0.05; return false
    end
    current.nextAttempt=now+0.5
    current.sent=current.sent+1
    if kind=="D" then current.sentSequences[sequence]={stamp=stamp,sentAtMS=math.floor(now*1000)} end
    frame.akNetworkSending=Probe
    local sendingFrame=frame
    ok,reserved=pcall(current.sendAPI,Probe.PREFIX,payload,kind=="D" and current.route or "WHISPER",target)
    if sendingFrame.akNetworkSending==Probe then sendingFrame.akNetworkSending=nil end
    if not owned(current) then return false end
    if not ok or not plain(reserved) or not integer(reserved,0,32) then
        current.errors=current.errors+1; Probe.Stop("send_error_or_opaque"); return false
    end
    current.lastSendResult=reserved
    if reserved~=current.success then
        if current.throttleCodes[reserved] then current.throttles=current.throttles+1
        else current.errors=current.errors+1 end
        Probe.Stop(current.throttleCodes[reserved] and "throttled" or "send_refused"); return false
    end
    current.accepted=current.accepted+1
    if kind=="A" then current.acksSent=current.acksSent+1 end
    return true
end
function Probe.Update()
    local now=verify()
    if not now then return end
    local current=state
    if current.role=="host" then
        if now-current.startedAt<Probe.QUIET_SECONDS then return end
        if now-current.startedAt>=Probe.DATA_SECONDS then
            current.missedSlots=current.missedSlots+math.max(0,Probe.PLANNED-current.nextSequence+1)
            current.nextSequence=Probe.PLANNED+1; current.phase="draining"; return
        end
        local slot=math.floor((now-current.startedAt-Probe.QUIET_SECONDS)/2)+1
        if slot>current.nextSequence then
            current.missedSlots=current.missedSlots+slot-current.nextSequence
            current.nextSequence=slot
        end
        if slot~=current.nextSequence then return end
        local stamp=math.floor(now*1000)
        if send("D",encode("D",current.session,slot,stamp),nil,now,slot,stamp) and owned(current) then
            current.nextSequence=slot+1
        end
    elseif #current.queue>0 then
        local packet=current.queue[1]
        if send("A",packet.payload,packet.target,now) and owned(current) then table.remove(current.queue,1) end
    end
end
function Probe.Message(prefix,payload,channel,sender)
    if not active() or not plain(prefix) or prefix~=Probe.PREFIX then return end
    local now=verify()
    if not now then return end
    state.eventCount=state.eventCount+1
    if state.eventCount>256 then Probe.Stop("event_limit"); return end
    if not plain(channel) or type(channel)~="string" then reject("route"); return end
    sender=fullName(sender)
    if not sender or not state.roster.names[key(sender)] then reject("sender"); return end
    local kind,session,sequence,stamp=decode(payload)
    if not kind or session~=state.session then reject("packet_or_session"); return end
    if (kind=="D" and channel~=state.route) or (kind=="A" and channel~="WHISPER") then reject("route"); return end
    local senderKey=key(sender)
    if senderKey==state.localKey then state.selfEchoes=state.selfEchoes+1; return end
    local peer=state.peers[senderKey]
    if (state.role=="host")~=(kind=="A") then reject("role"); return end
    if kind=="D" then
        if state.hostKey and state.hostKey~=senderKey then Probe.Stop("multiple_hosts"); return end
        if not state.hostKey then
            state.hostKey=senderKey; state.deadline=now+Probe.DATA_SECONDS+Probe.DRAIN_SECONDS
        end
    else
        local attempted=state.sentSequences[sequence]
        if not attempted or attempted.stamp~=stamp then reject("unattempted_ack"); return end
    end
    if peer.seen[sequence] then
        peer.duplicates=peer.duplicates+1; state.duplicates=state.duplicates+1; return
    end
    if sequence<peer.lastSequence then peer.reordered=peer.reordered+1; state.reordered=state.reordered+1 end
    peer.lastSequence=math.max(peer.lastSequence,sequence); peer.seen[sequence]=true
    if kind=="D" then
        peer.received=peer.received+1; state.received=state.received+1
        state.queue[#state.queue+1]={target=state.roster.names[senderKey],payload=encode("A",session,sequence,stamp)}
    else
        local rtt=math.floor(now*1000)-state.sentSequences[sequence].sentAtMS
        if rtt<0 then Probe.Stop("clock_unavailable"); return end
        peer.rtt[#peer.rtt+1]=rtt; peer.matched=peer.matched+1; state.matched=state.matched+1
    end
end
function Probe.HandleEvent(event)
    if not active() then return end
    if event=="GROUP_ROSTER_UPDATE" then
        local current=roster(state.route)
        if not sameRoster(state.roster,current) then Probe.Stop("group_changed") end
    elseif event=="PLAYER_REGEN_DISABLED" or event=="PLAYER_LEAVING_WORLD" or event=="PLAYER_LOGOUT" then
        Probe.Stop(event)
    end
end
local function arm(role,code,route)
    if active() or not frame or frame.akNetworkOwner or frame.akNetworkSending then return false,"network_busy" end
    if not plain(role) or (role~="host" and role~="listen") then return false,"role" end
    if not plain(code) or type(code)~="string" or not code:match("^[A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9]$") then return false,"session" end
    if used[code] then return false,"reused_session" end
    if usedCount>=64 then return false,"session_limit" end
    if route==nil then
        local raid=read(IsInRaid)
        if type(raid)~="boolean" then return false,"group_route" end
        route=raid and "RAID" or "PARTY"
    end
    if not plain(route) or (route~="RAID" and route~="PARTY") then return false,"group_route" end
    local reason=blocked()
    if reason then return false,reason end
    local now=clock()
    if not now then return false,"clock_unavailable" end
    local group,why=roster(route)
    if not group then return false,why end
    if type(C_ChatInfo)~="table" or type(C_ChatInfo.RegisterAddonMessagePrefix)~="function"
        or type(C_ChatInfo.SendAddonMessageLogged)~="function" or type(Enum)~="table"
        or type(Enum.RegisterAddonMessagePrefixResult)~="table" or type(Enum.SendAddonMessageResult)~="table"
        or type(AK.SessionTransport)~="table" or type(AK.SessionTransport.ReserveDiagnosticSend)~="function" then
        return false,"capabilities"
    end
    local reg,results=Enum.RegisterAddonMessagePrefixResult,Enum.SendAddonMessageResult
    if not integer(reg.Success,0,32) or not integer(reg.DuplicatePrefix,0,32)
        or reg.Success==reg.DuplicatePrefix then return false,"enums" end
    local seen,throttleCodes={},{}
    for _,name in ipairs(sendNames) do
        local value=results[name]
        if not integer(value,0,32) or seen[value] then return false,"enums" end
        seen[value]=true
    end
    local build
    if type(GetBuildInfo)=="function" then
        local ok,_,value=pcall(GetBuildInfo)
        if ok and plain(value) and type(value)=="string" and #value<=16 and value:match("^%d+$") then build=value end
    end
    -- Native preflight callbacks may have acquired another activity meanwhile.
    -- Never overwrite that lease or activate over newly captured driving input.
    reason=blocked()
    if reason then return false,reason end
    if frame.akNetworkOwner or frame.akNetworkSending or (AK.UI and (AK.UI.active or AK.UI.liveArmed)) then
        return false,"network_busy"
    end
    throttleCodes[results.AddonMessageThrottle],throttleCodes[results.ChannelThrottle]=true,true
    state={phase=role=="host" and "sending" or "listening",reason="checking",role=role,route=route,session=code,
        startedAt=now,lastNow=now,deadline=now+(role=="host" and 24 or 30),nextAttempt=now+Probe.QUIET_SECONDS,nextSequence=1,
        localName=group.own,localKey=group.ownKey,roster=group,hostKey=role=="host" and group.ownKey or nil,
        sent=0,accepted=0,received=0,acksSent=0,matched=0,selfEchoes=0,duplicates=0,reordered=0,
        rejected=0,missedSlots=0,deferred=0,throttles=0,errors=0,eventCount=0,
        sentSequences={},queue={},peers={},build=build,sendAPI=C_ChatInfo.SendAddonMessageLogged,
        success=results.Success,throttleCodes=throttleCodes}
    for _,nameKey in ipairs(group.order) do
        if nameKey~=group.ownKey then
            state.peers[nameKey]={name=group.names[nameKey],seen={},lastSequence=0,received=0,matched=0,
                duplicates=0,reordered=0,rtt={}}
        end
    end
    frame.akNetworkOwner=Probe
    local current=state
    local ok,result=pcall(C_ChatInfo.RegisterAddonMessagePrefix,Probe.PREFIX)
    if not owned(current) then return false,"interrupted" end
    if not ok or not plain(result) or (result~=reg.Success and result~=reg.DuplicatePrefix) then
        Probe.Stop("prefix_refused"); return false,"prefix_refused"
    end
    for _,event in ipairs({"CHAT_MSG_ADDON_LOGGED","GROUP_ROSTER_UPDATE"}) do
        ok,result=pcall(frame.RegisterEvent,frame,event)
        if not owned(current) then return false,"interrupted" end
        if not ok or not plain(result) or result==false then Probe.Stop("event_refused"); return false,"event_refused" end
    end
    ok,result=pcall(frame.SetScript,frame,"OnUpdate",function() Probe.Update() end)
    if not owned(current) then return false,"interrupted" end
    if not ok or not plain(result) or result==false then Probe.Stop("update_refused"); return false,"update_refused" end
    used[code]=true; usedCount=usedCount+1
    report(("Armed %s %s %s for20seconds plus4seconds receipts; all group members must opt in. No race route is enabled."):format(role,code,route))
    return true
end
function Probe.Start(role,code,route)
    if arming then return false,"arming" end
    arming=true
    local ok,result,reason=pcall(arm,role,code,route)
    if not ok then Probe.Stop("start_error"); result,reason=false,"start_error" end
    arming=false
    if not result then report("Refused: "..tostring(reason)) end
    return result,reason
end
function Probe.Command(argument)
    if argument=="report" then Probe.Report(); return true end
    if argument=="stop" then return Probe.Stop("manual_stop") end
    local role,code,route
    if type(argument)=="string" then
        role,code,route=argument:match("^(host) +([A-Z0-9]+) *([A-Z]*)$")
        if not role then role,code,route=argument:match("^(listen) +([A-Z0-9]+) *([A-Z]*)$") end
    end
    if role then return Probe.Start(role,code,route~="" and route or nil) end
    report("All members opt in: listeners /akart net group listen CODE PARTY|RAID, then one host /akart net group host CODE PARTY|RAID.")
    report("Use one fresh6character uppercase/digit CODE; /akart net group report or stop. This is a finite route check, not an eight-player race.")
    return false
end
return Probe
