-- Automatic community cache/discovery boundary. Scores are client-reported.
-- One pooled receiver frame; sends cooperate with the existing Core lease.
local _, AK = ...
local H, Sync = AK.Highscores, AK.ScoreSync
local Sharing = {PREFIX="AZKSCR1", CHANNEL="AzerothKartScores"}
AK.ScoreSharing = Sharing
local frame, core, root, source, expected, engine, contexts, byTrack
local writable, problem, world, registered = false, nil, false, false
local lastNow, nextScan, nextJoin, nextSend, idleSince, savedRevision = nil, 0, 0, 0, nil, -1
local nextRegistration=0
local allowed, status, statusKey = {}, "Waiting for world", nil
local notified, announcing = {}, false

local function plain(value)
    if type(issecretvalue)=="function" then
        local ok, secret=pcall(issecretvalue,value)
        if not ok or secret then return false end
    end
    return true
end
local function read(fn,...)
    if type(fn)~="function" then return nil end
    local ok,value=pcall(fn,...)
    if ok and plain(value) then return value end
end
local function clock()
    local now=read(GetTime)
    if type(now)~="number" or now~=now or now<0 or now==math.huge
        or (lastNow and now<lastNow) then return nil end
    lastNow=now
    return now
end
local function key(name)
    return (name:gsub("[A-Z]",function(c) return string.char(c:byte()+32) end))
end
local function equal(a,b)
    if type(a)~=type(b) then return false end
    if type(a)~="table" then return a==b end
    for k,v in pairs(a) do if not equal(v,b[k]) then return false end end
    for k in pairs(b) do if a[k]==nil then return false end end
    return true
end
local function unchanged(quick)
    if not writable or AzerothKartDB~=root or type(root)~="table"
        or root.schemaVersion~=1 or root.communityScores~=source then return false end
    if source~=nil and (type(source)~="table" or getmetatable(source)~=nil or source.version~=H.VERSION) then
        return false
    end
    if quick then return true end
    local parsed,valid=H.Load(source)
    return valid and equal(parsed,expected)
end
local function persist(force)
    if not engine then return false end
    local view=Sync.view(engine)
    if not force and view.revision==savedRevision and unchanged(true) then return true end
    if not unchanged() then
        writable,problem=false,"Saved community scores changed; reload to continue"
        return false
    end
    local snapshot=Sync.snapshot(engine)
    local parsed,valid=H.Load(snapshot)
    if not valid then writable,problem=false,"Community cache unavailable"; return false end
    root.communityScores,source,expected=parsed,parsed,H.Load(parsed)
    savedRevision=view.revision
    return true
end
local function changed()
    local view=engine and Sync.view(engine) or {}
    local current=table.concat({status,tostring(view.revision or 0),tostring(view.connected or 0),
        tostring(view.queued or 0),tostring(problem or "")},":")
    if current==statusKey then return end
    statusKey=current
    if AK.Menu and type(AK.Menu.OnScoresChanged)=="function" then pcall(AK.Menu.OnScoresChanged) end
end
local function buildContexts()
    contexts,byTrack={},{}
    for _,course in ipairs(AK.Courses.LIST) do
        if not course.soon then
            local track=AK.Courses.build(course.id,AK.Track.crossesGate)
            local context=AK.SoloRecords.Context(track)
            if context then contexts[#contexts+1]=context; byTrack[course.id]=context end
        end
    end
end
local function activate(now)
    if engine then return true end
    if not writable then return false end
    local name=AK.SoloRecords.PlayerName()
    if not name then status="Waiting for full player name"; return false end
    local seeded=H.Load(source)
    local personal,valid=H.Load(root.highscores)
    if valid then
        for _,context in ipairs(contexts) do
            seeded=H.Merge(seeded,context,H.View(personal,context))
        end
    end
    local token,reason=Sync.new({name=name,contexts=contexts,store=seeded},now)
    if not token then status="Score synchronization unavailable"; problem=reason; return false end
    engine=token
    persist(true)
    return writable
end
local function unblocked()
    if not world then return false,"Waiting for world" end
    if not writable then return false,problem or "Community scores are read-only" end
    if not unchanged(true) then
        writable,problem=false,"Saved community scores changed; reload to continue"
        return false,problem
    end
    if read(InCombatLockdown)~=false then return false,"Sharing paused during combat" end
    local chat=type(C_ChatInfo)=="table" and C_ChatInfo
    if not chat then return false,"Score messaging unavailable" end
    if type(chat.InChatMessagingLockdown)=="function"
        and read(chat.InChatMessagingLockdown)~=false then return false,"Sharing paused by client" end
    if core and (core.akNetworkOwner or core.akNetworkSending) then
        return false,"Sharing queued while multiplayer or a probe is active"
    end
    return true
end
local function prefixReady(now)
    if registered then return true end
    if now<nextRegistration then return false end
    nextRegistration=now+30
    local enums=type(Enum)=="table" and Enum.RegisterAddonMessagePrefixResult
    if type(enums)~="table" or type(C_ChatInfo.RegisterAddonMessagePrefix)~="function"
        or type(C_ChatInfo.SendAddonMessageLogged)~="function" then return false end
    local success,duplicate=read(function() return enums.Success end),read(function() return enums.DuplicatePrefix end)
    if type(success)~="number" then return false end
    local value=read(C_ChatInfo.RegisterAddonMessagePrefix,Sharing.PREFIX)
    registered=value==success or (type(duplicate)=="number" and value==duplicate)
    return registered
end
local function discover(now)
    if now<nextScan then return end
    nextScan=now+10
    local name=AK.SoloRecords.PlayerName()
    local snapshot,reason=AK.ScoreDiscovery.Read({
        GetNumDisplayChannels=GetNumDisplayChannels,GetChannelDisplayInfo=GetChannelDisplayInfo,
        C_ChatInfo=C_ChatInfo,issecretvalue=issecretvalue},Sharing.CHANNEL,name)
    if snapshot then
        if #snapshot.peers>Sync.MAX_PEERS then
            allowed={};Sync.discover(engine,{},now)
            status="Sharing capacity reached (32-peer test limit)"
            return
        end
        local accepted=Sync.discover(engine,snapshot.peers,now)
        if not accepted then
            allowed={};Sync.discover(engine,{},now)
            status="Channel member list unavailable"
            return
        end
        allowed={}
        for _,peer in ipairs(snapshot.peers) do allowed[key(peer)]=true end
        local view=Sync.view(engine)
        status=(view.connected or 0)>0 and "Automatic sharing connected"
            or (#snapshot.peers>0 and "Players discovered; connecting" or "Waiting for other racers")
    else
        allowed={}
        Sync.discover(engine,{},now)
        status=reason=="unsupported" and "Channel member list unavailable"
            or "Waiting for channel member list"
        if now>=nextJoin then
            nextJoin=now+60
            local joined=read(GetChannelName,Sharing.CHANNEL)
            if not (type(joined)=="number" and joined>0) and type(JoinPermanentChannel)=="function" then
                pcall(JoinPermanentChannel,Sharing.CHANNEL)
            end
        end
    end
end
local function nativeSend(peer,payload)
    if not unblocked() then return false end
    if not unchanged() then
        writable,problem=false,"Saved community scores changed; reload to continue"
        status=problem;return false
    end
    if type(peer)~="string" or not allowed[key(peer)] then return false end
    if not core or core.akNetworkOwner or core.akNetworkSending then return false end
    if #payload+#Sharing.PREFIX>158 then return false end
    local resultEnums=type(Enum)=="table" and Enum.SendAddonMessageResult
    local success=type(resultEnums)=="table" and read(function() return resultEnums.Success end)
    if type(success)~="number" then return false end
    -- These transient markers prevent a reentrant race/probe arm during Send.
    core.akNetworkOwner,core.akNetworkSending=Sharing,Sharing
    local ok,result=pcall(C_ChatInfo.SendAddonMessageLogged,Sharing.PREFIX,payload,"WHISPER",peer)
    if core.akNetworkSending==Sharing then core.akNetworkSending=nil end
    if core.akNetworkOwner==Sharing then core.akNetworkOwner=nil end
    return ok and plain(result) and type(result)=="number" and result==success
end
function Sharing.Update()
    local now=clock()
    if not now then status="Score clock unavailable"; changed(); return end
    local ready,why=unblocked()
    if not ready then idleSince=nil; status=why; changed(); return end
    idleSince=idleSince or now
    if not activate(now) then changed(); return end
    if not prefixReady(now) then status="Score messaging unavailable"; changed(); return end
    discover(now)
    -- Leave two idle seconds after another lease before starting our own budget.
    if now-idleSince>=2 and now>=nextSend then
        nextSend=now+1
        Sync.update(engine,now,nativeSend)
    end
    persist()
    changed()
end
function Sharing.Message(prefix,payload,route,sender)
    if not engine or not world or not writable then return end
    if not plain(prefix) or not plain(payload) or not plain(route) or not plain(sender) then return end
    if prefix~=Sharing.PREFIX or route~="WHISPER" or type(payload)~="string" or #payload>240 then return end
    local name=H.NormalizeName(sender)
    if not name or not allowed[key(name)] then return end
    if not unchanged(true) then
        writable,problem=false,"Saved community scores changed; reload to continue"
        changed();return
    end
    local now=clock()
    if not now then return end
    local handled=Sync.receive(engine,name,payload,now)
    if handled then
        persist()
        local view=Sync.view(engine)
        if (view.connected or 0)>0 then status="Automatic sharing connected" end
        changed()
    end
end
local function publish(record)
    local now=clock()
    if not now or not activate(now) or not unchanged() then return nil end
    local ok,placement=pcall(Sync.publish,engine,record,now)
    if not ok or not persist() then return nil end
    changed()
    if type(placement)~="table" then return nil end
    local board=H.BoardKey(record)
    local stamp=board..":"..record.totalTicks..":"..record.finishedAt..":"..record.playerName
    if notified[board]==stamp then return nil end
    notified[board]=stamp
    local message
    if placement.rank==1 and placement.previousRank and placement.previousRank>1 then
        message="New #1 in known shared scores!"
    elseif placement.enteredTier==3 then
        message="Top 3 in known shared scores! #"..placement.rank
    elseif placement.enteredTier==10 then
        message="Top 10 in known shared scores! #"..placement.rank
    end
    if message and DEFAULT_CHAT_FRAME and type(DEFAULT_CHAT_FRAME.AddMessage)=="function" then
        pcall(DEFAULT_CHAT_FRAME.AddMessage,DEFAULT_CHAT_FRAME,"|cffffd100Azeroth Kart: "..message.."|r")
    end
    return message
end
function Sharing.Publish(record)
    if announcing then return nil end
    announcing=true
    local ok,notice=pcall(publish,record)
    announcing=false
    if ok then return notice end
end
function Sharing.GetView(trackId)
    if not engine then return nil end
    local context=byTrack[trackId]
    local course=AK.Courses.get(trackId)
    local view=Sync.view(engine)
    return {scope="community",publication=status,writable=writable and unchanged(),
        problem=problem,trackId=trackId,trackName=course and course.name or "Unknown track",
        context=context,rows=context and H.View(Sync.snapshot(engine),context) or {},
        peers=view.peers or 0,connected=view.connected or 0,queued=view.queued or 0,
        received=view.received or 0,lastReceived=view.lastReceived}
end
function Sharing.Report()
    local view=engine and Sync.view(engine) or {}
    local message=("Azeroth Kart scores: %s | discovered=%d connected=%d queued=%d received=%d")
        :format(status,view.peers or 0,view.connected or 0,view.queued or 0,view.received or 0)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(message) else print(message) end
end
function Sharing.Init(coreFrame)
    core=coreFrame
    root=AzerothKartDB
    source=nil
    if type(root)=="table" then source=root.communityScores end
    expected,writable,problem=H.Load(source)
    if type(root)~="table" or root.schemaVersion~=1 then writable=false; problem="Saved data version unavailable" end
    buildContexts()
    frame=CreateFrame("Frame")
    local events={"PLAYER_ENTERING_WORLD","PLAYER_LEAVING_WORLD","PLAYER_LOGOUT",
        "CHAT_MSG_ADDON_LOGGED","CHANNEL_ROSTER_UPDATE","CHANNEL_UI_UPDATE","CHAT_MSG_CHANNEL_NOTICE"}
    for _,event in ipairs(events) do
        local ok,result=pcall(frame.RegisterEvent,frame,event)
        if not ok or not plain(result) or result==false then
            writable=false;problem="Score events unavailable"
        end
    end
    frame:SetScript("OnEvent",function(_,event,...)
        if event=="PLAYER_ENTERING_WORLD" then
            world=true;nextScan,nextJoin=0,0;idleSince=nil;Sharing.Update()
        elseif event=="PLAYER_LEAVING_WORLD" or event=="PLAYER_LOGOUT" then
            world=false;idleSince=nil;allowed={};status="Sharing paused outside world";changed()
        elseif event=="CHAT_MSG_ADDON_LOGGED" then Sharing.Message(...)
        else nextScan=math.min(nextScan,(lastNow or 0)+1) end
    end)
    local elapsedTotal=0
    frame:SetScript("OnUpdate",function(_,elapsed)
        if not world then return end
        elapsedTotal=elapsedTotal+elapsed
        if elapsedTotal<0.25 then return end
        elapsedTotal=0
        Sharing.Update()
    end)
end
return Sharing
