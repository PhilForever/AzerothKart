-- Native adapter checks with two isolated mocked clients; no live-client claim.
local originalPrint = print
local unpack = unpack or table.unpack
local globalNames = {"C_ChatInfo","Enum","GetTime","InCombatLockdown","CreateFrame",
    "DEFAULT_CHAT_FRAME","print"}
local sendNames = {"Success","InvalidPrefix","InvalidMessage","AddonMessageThrottle",
    "InvalidChatType","NotInGroup","TargetRequired","InvalidChannel","ChannelThrottle",
    "GeneralError","NotInGuild","AddOnMessageLockdown","TargetOffline"}
local HOST,GUEST,CODE = "Amber Stone","Birch Vale","ABC123"

local function client(identity,clockTest)
    local e = {identity=identity or HOST,now=0,registerCalls=0,eventCalls=0,scriptCalls=0,
        createdFrames=0,registerResult=0,sendResult=0,sends={},output={},raceCalls=0,
        registeredPrefixes={},unregisterCalls=0,detachCalls=0}
    local originalEvent = function() end
    e.frame = {events={},scripts={OnEvent=originalEvent}}
    function e.frame:RegisterEvent(event)
        assert(event=="CHAT_MSG_ADDON_LOGGED")
        e.eventCalls=e.eventCalls+1
        if e.eventThrows then error("private event error") end
        if e.eventResult==false then return false end
        self.events[event]=true
        return e.eventResult
    end
    function e.frame:UnregisterEvent(event)
        assert(event=="CHAT_MSG_ADDON_LOGGED")
        e.unregisterCalls=e.unregisterCalls+1
        self.events[event]=nil
    end
    function e.frame:SetScript(name,callback)
        assert(name=="OnUpdate","Core retains ownership of OnEvent")
        e.scriptCalls=e.scriptCalls+1
        if callback and e.updateThrows then error("private update error") end
        if not callback then e.detachCalls=e.detachCalls+1 end
        self.scripts[name]=callback
    end
    local results = {}
    for index,name in ipairs(sendNames) do results[name]=index-1 end
    local function output(message) e.output[#e.output+1]=message end
    e.globals = {Enum={RegisterAddonMessagePrefixResult={Success=0,DuplicatePrefix=1},
        SendAddonMessageResult=results},
        GetTime=function() if e.clockThrows then error("private clock error") end; return e.now end,
        InCombatLockdown=function()
            if e.combatThrows then error("private combat error") end
            return e.combat==true
        end,
        CreateFrame=function() e.createdFrames=e.createdFrames+1; error("must reuse Core frame") end,
        DEFAULT_CHAT_FRAME={AddMessage=function(_,message) output(message) end},print=output}
    e.globals.C_ChatInfo = {
        RegisterAddonMessagePrefix=function(prefix)
            assert(prefix=="AZKART2" or prefix=="AZKART1" or prefix=="AZKCLK1"
                or prefix=="AZKGRD1" or prefix=="AZKRUN2" or prefix=="AZKRUN3")
            e.registerCalls=e.registerCalls+1
            e.registeredPrefixes[prefix]=true
            if e.registerThrows then error("private registration error") end
            return e.registerResult
        end,
        SendAddonMessageLogged=function(prefix,payload,channel,target)
            assert(channel=="WHISPER" and type(target)=="string")
            local packet={prefix=prefix,payload=payload,channel=channel,target=target,time=e.now,
                sender=e.identity}
            e.sends[#e.sends+1]=packet
            if e.onSend then e.onSend(packet) end
            if e.sendThrows then error("private send error") end
            return e.sendResult
        end,
        SendAddonMessage=function() error("no unlogged fallback") end,
        InChatMessagingLockdown=function()
            if e.chatThrows then error("private chat error") end
            return e.chatLocked==true
        end,
    }
    function e:run(callback,...)
        local previous={}
        for index,name in ipairs(globalNames) do previous[index]=_G[name]; _G[name]=self.globals[name] end
        local ok,a,b,c=pcall(callback,...)
        for index,name in ipairs(globalNames) do _G[name]=previous[index] end
        if not ok then error(a,0) end
        return a,b,c
    end
    function e:call(method,...)
        return self:run(assert(self.transport[method],method),...)
    end
    function e:view() return self:call("GetView") end
    function e:update(time)
        if time~=nil then self.now=time end
        return self:call("Update")
    end
    e:run(function()
        local ns={UI={active=false},Race=setmetatable({}, {__index=function()
            return function() e.raceCalls=e.raceCalls+1; error("session control must not start Race") end
        end})}
        for _,module in ipairs({"Physics","Track","MirageRaceway","Circuit","CapitalCities","Dungeon","ScarletCrusade","Courses","RaceProtocol","PeerSession",
            "ClockProtocol","StartClock","RaceStart","NetworkProbe","TransportProbe"}) do
            assert(loadfile("addon/AzerothKart/"..module..".lua"))("AzerothKart",ns)
        end
        if clockTest then
            for _,module in ipairs({"Checkpoints","Laps","Race","Loop","RaceGrid","LiveProtocol","LiveRace"}) do
                assert(loadfile("addon/AzerothKart/"..module..".lua"))("AzerothKart",ns)
            end
        end
        assert(loadfile("addon/AzerothKart/SessionTransport.lua"))("AzerothKart",ns)
        e.namespace,e.transport,e.probe=ns,ns.SessionTransport,ns.TransportProbe
        assert(e.transport and e.transport.state==nil,"adapter must not expose mutable session state")
        e.transport.Init(e.frame)
        e.probe.Init(e.frame,output)
    end)
    assert(e.registerCalls==0 and #e.sends==0 and e.eventCalls==0 and e.scriptCalls==0
        and e.createdFrames==0,"module loading/Init must remain idle")
    assert(e.frame.scripts.OnEvent==originalEvent)
    return e
end

local function refusal(e,method,...)
    local ok,reason=e:call(method,...)
    assert(ok==false and type(reason)=="string",method.." must return a fixed refusal")
    assert(not reason:find("private",1,true),"native error details must not enter public errors")
end
local function detached(e)
    assert(not e:call("IsActive") and e.frame.akNetworkOwner==nil
        and e.frame.akNetworkSending==nil
        and e.frame.scripts.OnUpdate==nil and not e.frame.events.CHAT_MSG_ADDON_LOGGED,
        "terminal adapter must release its frame lease and hooks")
end
local function wire(e,kind,sequence,extra)
    local message={session=CODE,kind=kind,sequence=sequence}
    for key,value in pairs(extra or {}) do message[key]=value end
    return assert(e.namespace.RaceProtocol.encode(message))
end
local function receive(e,payload,sender,prefix,channel)
    return e:call("Message",prefix or "AZKART2",payload,channel or "WHISPER",sender or HOST)
end
local function assertPacing(e)
    for index,packet in ipairs(e.sends) do
        if index>1 then assert(packet.time-e.sends[index-1].time>=0.5,"all native attempts share pacing") end
        local calls,bytes=0,0
        for _,other in ipairs(e.sends) do
            if other.time>packet.time-1 and other.time<=packet.time then
                calls,bytes=calls+1,bytes+#other.prefix+#other.payload
            end
        end
        assert(calls<=2 and bytes<=158,"rolling one-second adapter budget")
    end
end
local function pair(clockTest,liveTest)
    local p={host=client(HOST,clockTest),guest=client(GUEST,clockTest),now=0,queue={},
        karts={host="steam_tank",guest="goblin_drag_car"}}
    for _,role in ipairs({"host","guest"}) do
        p[role].onSend=function(packet)
            if p.drop and p.drop(packet) then return end
            p.queue[#p.queue+1]={to=role=="host" and "guest" or "host",packet=packet,
                deliveryAt=p.now+(p.delay or 0)}
        end
    end
    function p:step(amount)
        self.now=self.now+(amount or 0.5)
        for _,role in ipairs({"host","guest"}) do
            local e=self[role]
            local before=#e.sends
            e:update(self.now+(self.offset and self.offset[role] or 0))
            assert(#e.sends-before<=1,"hitches cannot send catch-up bursts")
        end
        local queue=self.queue; self.queue={}
        for _,entry in ipairs(queue) do
            if entry.deliveryAt>self.now then self.queue[#self.queue+1]=entry else
                local e,packet=self[entry.to],entry.packet
                assert(packet.target==e.identity,"complete full native identity must be preserved")
                receive(e,packet.payload,packet.sender,packet.prefix,packet.channel)
            end
        end
    end
    function p:untilTrue(predicate)
        for _=1,clockTest and 60 or 20 do if predicate() then return end; self:step() end
        error("two-client mocked exchange did not reach expected state")
    end
    function p:lobby(track)
        assert(self.guest:call(liveTest and "ListenLive" or (clockTest and "ListenCoordinated" or "Listen"),
            HOST,CODE,liveTest and self.karts.guest or nil))
        assert(self.host:call(liveTest and "HostLive" or (clockTest and "HostCoordinated" or "Host"),
            GUEST,CODE,track or "mirage_raceway",liveTest and self.karts.host or nil))
        self:untilTrue(function() return self.guest:view().canJoin end)
        assert(self.guest:call("Join"))
        self:untilTrue(function()
            return self.host:view().phase=="lobby" and self.guest:view().phase=="lobby"
                and not self.host:view().pendingKind and not self.guest:view().pendingKind
        end)
    end
    function p:ready()
        if liveTest then
            self:untilTrue(function() return self.host:view().canSetReady and self.guest:view().canSetReady end)
            assert(self.host:view().grid.ready and self.guest:view().grid.ready,
                "both cosmetic profiles must be agreed before Ready is available")
        end
        assert(self.host:call("Ready",true)); assert(self.guest:call("Ready",true))
        self:untilTrue(function()
            return (self.host:view().canStart or self.host:view().canPrepareStart)
                and not self.guest:view().pendingKind
        end)
    end
    return p
end

do
    local e=client()
    assert(e:view().phase=="idle" and e:view().canHost and e:view().canListen)
    e:update(5); e:call("HandleEvent","PLAYER_REGEN_ENABLED")
    assert(#e.sends==0 and e.registerCalls==0 and e.raceCalls==0)
    assert(e:call("TakeStartProposal")==nil)
    for _,args in ipairs({{"","ABC123","mirage_raceway"},{GUEST,"bad","mirage_raceway"},
        {GUEST,CODE,"unknown"},{GUEST,CODE,"test_oval"},
        {"Bad|Name",CODE,"mirage_raceway"}}) do refusal(e,"Host",unpack(args)) end
    assert(e.registerCalls==0,"invalid commands do not touch native APIs")
    assert(e:call("Host",GUEST,CODE,"mirage_raceway"))
    refusal(e,"Listen",HOST,"DEF456")
    assert(e:view().phase=="inviting" and #e.sends==0,"actions queue output, never send directly")
    e:call("Stop","left"); detached(e)
    refusal(e,"Host",GUEST,CODE,"mirage_raceway")
    assert(e:call("Host",GUEST,"DEF456","mirage_raceway"))
    assert(e.registerCalls==1,"registered prefix is reused only after explicit new session")
    e:call("Stop","left"); detached(e)
end

do
    local p=pair()
    p:lobby("mirage_raceway")
    assert(p.guest:view().offer.physicsVersion==p.guest.namespace.Physics.VERSION
        and p.guest:view().offer.trackVersion==1 and p.guest:view().offer.trackId=="mirage_raceway")
    refusal(p.guest,"Start",180,42); refusal(p.host,"Start",180,42)
    p:ready()
    assert(p.host:call("Start",180,42))
    p:untilTrue(function() return p.host:view().startStatus=="acknowledged" end)
    local h,g=p.host:call("TakeStartProposal"),p.guest:call("TakeStartProposal")
    assert(h.startTick==180 and h.seed==42 and h.peerAcknowledged==true)
    assert(g.startTick==180 and g.seed==42 and g.peerAcknowledged==false)
    h.seed=0; g.startTick=0
    assert(p.host:call("TakeStartProposal")==nil and p.guest:call("TakeStartProposal")==nil)
    assert(p.host:view().start.seed==42 and p.guest:view().start.startTick==180)
    local copied=p.guest:view()
    copied.offer.trackVersion=99; copied.start.seed=0; copied.stats.sendAttempts=999
    copied.traffic.attempts=999
    assert(p.guest:view().offer.trackVersion==1 and p.guest:view().start.seed==42
        and p.guest:view().stats.sendAttempts~=999 and p.guest:view().traffic.attempts~=999)
    assert(p.host.raceCalls==0 and p.guest.raceCalls==0 and not p.host.namespace.UI.active
        and p.host.namespace.Physics.VERSION==12 and p.host.namespace.Track.version==2,
        "control proposals never activate or mutate local simulation")
    assertPacing(p.host); assertPacing(p.guest)
    p.host:call("Stop","left"); p.guest:call("Stop","left")
end

do
    local e=client(GUEST)
    assert(e:call("Listen","  Åmber   Stone  ",CODE))
    local offer=wire(e,"INVITE",1,{physicsVersion=e.namespace.Physics.VERSION,
        trackId="mirage_raceway",trackVersion=1,laps=3})
    receive(e,offer,"Åmber Stone","OTHER")
    receive(e,offer,"Åmber Stone",nil,"PARTY")
    receive(e,offer,"Åmber Wrong")
    receive(e,wire(e,"INVITE",1,{session="OLD123",physicsVersion=e.namespace.Physics.VERSION,
        trackId="mirage_raceway",trackVersion=1,laps=3}),"Åmber Stone")
    receive(e,"malformed","Åmber Stone")
    assert(e:view().phase=="listening" and #e.sends==0)
    receive(e,offer,"Åmber sToNe")
    assert(e:view().canJoin and #e.sends==0,"receive callback queues ACK until paced Update")
    e:update(0.5)
    assert(#e.sends==1 and e.sends[1].target=="Åmber Stone")
    assert(e.namespace.RaceProtocol.decode(e.sends[1].payload).kind=="ACK")
    e:call("Stop","left"); detached(e)
end

-- Missing/ambiguous enums and native setup refusals may not leak hooks or lease.
do
    local e=client(GUEST)
    local remembered={}
    e.namespace.ScoreSharing={RememberPeer=function(peer)
        assert(e.frame.akNetworkOwner==e.transport and #e.sends==0,
            "remembering an accepted control peer cannot send or replace the race lease")
        remembered[#remembered+1]=peer
    end}
    assert(e:call("Listen","  Åmber   Stone  ",CODE))
    assert(#remembered==0,"an outgoing configured name alone is not an observed peer")
    local offer=wire(e,"INVITE",1,{physicsVersion=e.namespace.Physics.VERSION,
        trackId="mirage_raceway",trackVersion=1,laps=3})
    receive(e,offer,"Åmber Stone","OTHER")
    receive(e,offer,"Åmber Stone",nil,"PARTY")
    receive(e,offer,"Åmber Wrong")
    receive(e,wire(e,"INVITE",1,{session="OLD123",physicsVersion=e.namespace.Physics.VERSION,
        trackId="mirage_raceway",trackVersion=1,laps=3}),"Åmber Stone")
    receive(e,"malformed","Åmber Stone")
    assert(#remembered==0,"unrelated, malformed and rejected packets do not admit score peers")
    assert(receive(e,offer,"Åmber sToNe"))
    assert(#remembered==1 and remembered[1]=="Åmber sToNe" and e:view().canJoin,
        "accepted incoming discovery preserves the complete native sender, including surname")
    e:call("Stop","stopped"); detached(e)
end
do
    local e=client(GUEST)
    local calls=0
    e.namespace.ScoreSharing={RememberPeer=function()
        calls=calls+1; error("private score callback failure")
    end}
    assert(e:call("Listen",HOST,CODE))
    assert(receive(e,wire(e,"INVITE",1,{physicsVersion=e.namespace.Physics.VERSION,
        trackId="mirage_raceway",trackVersion=1,laps=3})))
    assert(calls==1 and e:view().canJoin and e:call("IsActive") and #e.sends==0,
        "a failing score callback does not turn a valid session packet into a controller error")
    e:call("Stop","stopped"); detached(e)
end
do
    local e=client(GUEST)
    local foreign,callback={},function() end
    e.namespace.ScoreSharing={RememberPeer=function()
        e:call("Stop","stopped")
        e.frame.akNetworkOwner=foreign
        e.frame.scripts.OnUpdate=callback
    end}
    assert(e:call("Listen",HOST,CODE))
    assert(receive(e,wire(e,"INVITE",1,{physicsVersion=e.namespace.Physics.VERSION,
        trackId="mirage_raceway",trackVersion=1,laps=3})))
    assert(not e:call("IsActive") and e.frame.akNetworkOwner==foreign
        and e.frame.scripts.OnUpdate==callback and #e.sends==0,
        "a callback stop wins and the old receive cannot clear a newly acquired foreign lease")
end
do
    local e=client()
    e.namespace.ScoreSharing={RememberPeer=function()
        e:call("Stop","stopped")
        assert(e.frame.akNetworkSending==e.transport,
            "a score callback cannot clear a native send still unwinding")
        refusal(e,"Listen",GUEST,"DEF456")
    end}
    assert(e:call("Host",GUEST,CODE,"mirage_raceway"))
    e.onSend=function(packet)
        local message=assert(e.namespace.RaceProtocol.decode(packet.payload))
        receive(e,wire(e,"ACK",1,{ackKind=message.kind,ackSequence=message.sequence}),GUEST)
    end
    e:update(0.5); detached(e)
    assert(#e.sends==1 and e.frame.akNetworkSending==nil,
        "the accepted-peer hook preserves native callback reentry cleanup")
end

-- Missing/ambiguous enums and native setup refusals may not leak hooks or lease.
local setupFailures={
    function(e) e.globals.Enum=nil end,
    function(e) e.globals.Enum.SendAddonMessageResult.TargetOffline=nil end,
    function(e) e.globals.Enum.SendAddonMessageResult.TargetOffline=0 end,
    function(e) e.globals.Enum.RegisterAddonMessagePrefixResult.DuplicatePrefix=0 end,
    function(e) e.globals.C_ChatInfo.SendAddonMessageLogged=nil end,
    function(e) e.registerResult=false end,
    function(e) e.registerResult=nil end,
    function(e) e.registerThrows=true end,
    function(e) e.eventResult=false end,
    function(e) e.eventThrows=true end,
    function(e) e.updateThrows=true end,
}
for _,configure in ipairs(setupFailures) do
    local e=client(); configure(e)
    refusal(e,"Host",GUEST,CODE,"mirage_raceway"); detached(e)
    assert(#e.sends==0)
end
do
    local e=client(); e.registerResult=1
    assert(e:call("Listen",GUEST,CODE),"DuplicatePrefix is a valid native registration outcome")
    e:call("Stop","left"); detached(e)
end
do
    local e=client()
    for index=1,64 do
        assert(e:call("Listen",GUEST,("SID%03d"):format(index)))
        e:call("Stop","left")
    end
    refusal(e,"Listen",GUEST,"NEW123")
    assert(not e:view().canHost and not e:view().canListen,"history limit disables unavailable arm actions")
    assert(e.registerCalls==1 and #e.sends==0,"session ID history is bounded without native traffic")
    detached(e)
end
do
    local e=client(GUEST); assert(e:call("Listen",HOST,CODE))
    receive(e,wire(e,"INVITE",1,{physicsVersion=e.namespace.Physics.VERSION+1,
        trackId="mirage_raceway",trackVersion=1,laps=3}))
    assert(e:view().phase=="closed" and e:view().reason=="incompatible" and #e.sends==0)
    detached(e)
end
for _,oldVersion in ipairs({7,8,9}) do
    -- Previous handling revisions must be refused before the live start.
    local e=client(GUEST,true); assert(e:call("ListenLive",HOST,CODE,"steam_tank"))
    receive(e,wire(e,"INVITE",1,{physicsVersion=oldVersion,trackId="mirage_raceway",trackVersion=1,laps=3}))
    local rejected=e:view()
    assert(rejected.phase=="closed" and rejected.reason=="incompatible"
        and rejected.clock==nil and rejected.live==nil and not e.namespace.UI.active and #e.sends==0,
        "older physics cannot enter the current live start sequence")
    assert(e:call("TakeRaceStart")==nil)
    e:update(30)
    assert(#e.sends==0,"incompatible offers cannot produce delayed grid or clock traffic")
    detached(e)
end

for _,mode in ipairs({"nil","true","unknown","failed","throttled","throws"}) do
    local e=client()
    if mode=="nil" then e.sendResult=nil
    elseif mode=="true" then e.sendResult=true
    elseif mode=="unknown" then e.sendResult=99
    elseif mode=="failed" then e.sendResult=12
    elseif mode=="throttled" then e.sendResult=3
    else e.sendThrows=true end
    assert(e:call("Host",GUEST,CODE,"mirage_raceway")); e:update(1); detached(e)
    assert(#e.sends==1 and e:call("TakeStartProposal")==nil)
    local failed=e:view()
    assert(type(failed.reason or failed.lastError)=="string")
    e:update(10); assert(#e.sends==1,"failed native acceptance cannot retry or auto-resume")
    for _,message in ipairs(e.output) do assert(not message:find("private",1,true)) end
end

-- Success=0 records local acceptance only: absent a peer ACK, retry is bounded.
do
    local e=client(); assert(e:call("Host",GUEST,CODE,"mirage_raceway"))
    receive(e,wire(e,"ACK",1,{ackKind="INVITE",ackSequence=1}),GUEST)
    assert(e:view().pendingKind=="INVITE" and #e.sends==0,"an ACK before any actual send cannot confirm")
    for _,time in ipairs({0,0.1,2,4,6}) do e:update(time) end
    assert(#e.sends==3 and e:view().phase=="closed")
    assert(e.sends[1].payload==e.sends[2].payload and e.sends[2].payload==e.sends[3].payload)
    detached(e); assertPacing(e)
end
do
    local p=pair()
    local dropped=false
    p.drop=function(packet)
        local message=assert(p.host.namespace.RaceProtocol.decode(packet.payload))
        if not dropped and message.kind=="INVITE" then dropped=true; return true end
    end
    p:lobby()
    local attempts={}
    for _,packet in ipairs(p.host.sends) do
        if p.host.namespace.RaceProtocol.decode(packet.payload).kind=="INVITE" then
            attempts[#attempts+1]=packet.payload
        end
    end
    assert(dropped and #attempts==2 and attempts[1]==attempts[2],"a lost invite retries identical scoped bytes")
    assertPacing(p.host); assertPacing(p.guest)
    p.host:call("Stop","left"); p.guest:call("Stop","left")
end

-- Every terminal safety path clears proposals, releases hooks, and stays stopped.
local interrupts={
    function(e) e.combat=true; e:update() end,
    function(e) e.chatLocked=true; e:update() end,
    function(e) e.namespace.UI.active=true; e:update() end,
    function(e) e.clockThrows=true; e:update() end,
    function(e) e.now=0/0; e:update() end,
    function(e) e.now=-1; e:update() end,
    function(e) e.now=0.25; e:update() end,
    function(e) e:call("HandleEvent","PLAYER_REGEN_DISABLED") end,
    function(e) e:call("HandleEvent","PLAYER_LEAVING_WORLD") end,
    function(e) e:call("HandleEvent","PLAYER_LOGOUT") end,
}
for _,interrupt in ipairs(interrupts) do
    local e=client(); assert(e:call("Host",GUEST,CODE,"mirage_raceway")); e:update(0.5)
    local oldUpdate=e.frame.scripts.OnUpdate
    interrupt(e); detached(e)
    e.now=2; e.combat=false; e.chatLocked=false; e.clockThrows=false; e.namespace.UI.active=false
    e:call("HandleEvent","PLAYER_REGEN_ENABLED"); e:update()
    if oldUpdate then e:run(oldUpdate,e.frame,1) end
    assert(#e.sends==1 and e:call("TakeStartProposal")==nil)
    detached(e)
end

-- Shared Core-frame lease: neither inactive adapter may detach the active one.
do
    local e=client()
    assert(e:call("Listen",GUEST,CODE))
    local callback,owner=e.frame.scripts.OnUpdate,e.frame.akNetworkOwner
    assert(type(owner)=="table")
    e:run(e.probe.Stop,"manual stop")
    assert(e.frame.akNetworkOwner==owner and e.frame.scripts.OnUpdate==callback)
    assert(not e:run(e.probe.Command,"listen Birch Vale DEF456"))
    assert(e.frame.akNetworkOwner==owner and e.frame.scripts.OnUpdate==callback)
    e:call("Stop","left"); detached(e)
    assert(e:run(e.probe.Command,"listen Birch Vale DEF456"))
    owner,callback=e.frame.akNetworkOwner,e.frame.scripts.OnUpdate
    refusal(e,"Listen",GUEST,"GHI789")
    e:call("Stop","left")
    assert(e.frame.akNetworkOwner==owner and e.frame.scripts.OnUpdate==callback)
    e:run(e.probe.Stop,"manual stop"); detached(e)
end

-- Leaving uses a single paced terminal notice, then relinquishes the lease.
do
    local e=client(); assert(e:call("Host",GUEST,CODE,"mirage_raceway")); e:update(0)
    assert(e:call("Leave")); e:update(0.1); assert(#e.sends==1)
    e:update(0.5)
    assert(#e.sends==2 and e.namespace.RaceProtocol.decode(e.sends[2].payload).kind=="CANCEL")
    e:update(0.5); assert(#e.sends==2); detached(e); assertPacing(e)
    assert(e:call("Host",GUEST,"DEF456","mirage_raceway")); e:update(0.6)
    assert(#e.sends==2,"a fresh session cannot reset the previous send budget")
    e:update(1); assert(#e.sends==3); e:call("Stop","left"); detached(e)
end
do
    local e=client(GUEST); assert(e:call("Listen",HOST,CODE))
    receive(e,wire(e,"CANCEL",1,{reason="left"}))
    assert(e:view().phase=="closed" and #e.sends==0)
    e:update(0.5)
    assert(#e.sends==1 and e.namespace.RaceProtocol.decode(e.sends[1].payload).kind=="ACK")
    detached(e); e:update(2); assert(#e.sends==1)
end

-- Nested native callbacks must not advance clocks or revive a stopped session.
for _,outcome in ipairs({0,12}) do
    local e=client(); assert(e:call("Host",GUEST,CODE,"mirage_raceway"))
    e.onSend=function(packet)
        local message=assert(e.namespace.RaceProtocol.decode(packet.payload))
        receive(e,wire(e,"ACK",1,{ackKind=message.kind,ackSequence=message.sequence}),GUEST)
        e.now=100; e:call("Update"); e.now=0.5
    end
    e.sendResult=outcome; e:update(0.5)
    assert(#e.sends==1)
    if outcome==0 then
        assert(e:view().phase=="inviting" and e:view().pendingKind==nil)
        e.onSend=nil; e:update(1); assert(e:call("IsActive")); e:call("Stop","left")
    else detached(e) end
end
do
    local e=client(); assert(e:call("Host",GUEST,CODE,"mirage_raceway"))
    e.onSend=function() e:call("Stop","left") end
    e:update(0.5); detached(e); e:update(1)
    assert(#e.sends==1 and e:call("TakeStartProposal")==nil)
end

-- Ending a lease from inside a native callback must not let the other adapter
-- acquire the frame until that native call has unwound, in either direction.
do
    local e=client(); assert(e:call("Host",GUEST,CODE,"mirage_raceway"))
    e.onSend=function()
        e:call("Stop","error")
        assert(e.frame.akNetworkSending==e.transport and e:view().transportBusy)
        assert(not e:run(e.probe.Command,"listen Birch Vale DEF456"))
    end
    e:update(0.5); detached(e)
    e.onSend=nil
    assert(e:run(e.probe.Command,"listen Birch Vale DEF456"))
    e:run(e.probe.Stop,"manual stop"); detached(e)
end
do
    local e=client()
    assert(e:run(e.probe.Command,"start Birch Vale DEF456"))
    e.onSend=function()
        e:run(e.probe.Stop,"manual stop")
        assert(e.frame.akNetworkSending==e.probe and not e:view().canListen)
        refusal(e,"Listen",GUEST,CODE)
    end
    e.now=2; e:run(e.probe.Update); detached(e)
    e.onSend=nil
    assert(e:call("Listen",GUEST,CODE)); e:call("Stop","error"); detached(e)
end
do
    local e=client(); assert(e:call("Host",GUEST,CODE,"mirage_raceway"))
    local reads=0
    e.globals.InCombatLockdown=function()
        reads=reads+1
        if reads==2 then e:call("Stop","error") end
        return false
    end
    e:update(0.5); detached(e)
    assert(#e.sends==0 and e:view().traffic.attempts==0,
        "Stop during a pre-send guard must prevent the native call")
end

local function armedPair(track)
    local p=pair(true); p:lobby(track); p:ready()
    assert(p.host.registerCalls==2 and p.guest.registerCalls==2,"clock mode explicitly registers both prefixes")
    refusal(p.host,"Start",180,42)
    assert(p.host:call("TakeStartProposal")==nil,"coordinator alone owns its START proposal")
    assert(p.host:call("PrepareStart",42))
    assert(#p.host.sends>0 and p.host:view().clock==nil,"PrepareStart queues only; it does not activate a race")
    p:untilTrue(function()
        return p.host:view().clock and p.guest:view().clock
            and p.host:view().clock.phase=="armed" and p.guest:view().clock.phase=="armed"
    end)
    return p
end
do
    local p=armedPair("mirage_raceway")
    local hv,gv=p.host:view(),p.guest:view()
    assert(hv.phase=="coordinating" and gv.phase=="coordinating")
    assert(hv.clock.samples==3 and gv.clock.samples==3 and hv.clock.rttMS==0)
    assert(hv.clock.peerAcknowledged and not gv.clock.peerAcknowledged,
        "copied view must preserve the last-ACK ambiguity")
    hv.clock.localEpochMS=0; hv.clock.sampleDetails[1].t1MS=-1
    assert(p.host:view().clock.localEpochMS>0 and p.host:view().clock.sampleDetails[1].t1MS>=0)
    local clockWire=assert(p.host.namespace.ClockProtocol.encode({kind="PING",session=CODE,sequence=300,sample=1,t1=0}))
    local before=p.guest:view().clock.stats.received
    assert(not receive(p.guest,clockWire,"Other Person","AZKCLK1"))
    assert(not receive(p.guest,clockWire,HOST,"AZKCLK1","PARTY"))
    assert(p.guest:view().clock.stats.received==before,"clock path preserves complete native sender and channel scope")
    local epoch=p.host:view().clock.localEpochMS/1000
    assert(p.host:call("TakeRaceStart")==nil and p.guest:call("TakeRaceStart")==nil)
    p:step(epoch-p.now)
    local h=assert(p.host:call("TakeRaceStart"))
    local g=assert(p.guest:call("TakeRaceStart"))
    for _,bundle in ipairs({h,g}) do
        assert(bundle.trackId=="mirage_raceway" and bundle.trackVersion==1
            and bundle.physicsVersion==p.host.namespace.Physics.VERSION)
        assert(bundle.seed==42 and bundle.fixedDt==1/60 and bundle.vehicle.tick==0
            and bundle.race.status=="running" and bundle.race.startTick==0
            and bundle.race.laps.completedLaps==0,"real Physics/Race begin once at GO without another countdown")
    end
    assert(h.vehicle~=g.vehicle and h.race~=g.race and h.track~=g.track)
    for _,e in ipairs({p.host,p.guest}) do
        detached(e); assert(e:call("TakeRaceStart")==nil and e:view().phase=="launched")
        assertPacing(e)
        assert(e.createdFrames==0 and #e.output==0,"backend creates no UI or chat output")
    end
end
do
    local p=armedPair()
    local epoch=p.host:view().clock.localEpochMS/1000
    p:step(epoch-p.now+0.251)
    assert(p.host:call("TakeRaceStart")==nil and p.guest:call("TakeRaceStart")==nil)
    assert(p.host:view().phase=="closed" and p.host:view().clock.reason=="late")
    assertPacing(p.host); assertPacing(p.guest)
end
for _,event in ipairs({"PLAYER_REGEN_DISABLED","PLAYER_LEAVING_WORLD","PLAYER_LOGOUT"}) do
    local p=armedPair()
    p.host:call("HandleEvent",event); detached(p.host)
    assert(p.host:call("TakeRaceStart")==nil and p.host:view().clock.phase=="closed")
end
for _,method in ipairs({"new","take"}) do
    local p=armedPair()
    local epoch=p.host:view().clock.localEpochMS/1000
    p:step(epoch-p.now)
    p.host.namespace.RaceStart[method]=function() error("private initializer failure") end
    local bundle,why=p.host:call("TakeRaceStart")
    assert(bundle==nil and why=="controller_error")
    detached(p.host)
    assert(p.host:view().canHost,"initializer exceptions cannot retain the native lease or busy guard")
end
do
    local p=armedPair()
    local epoch=p.host:view().clock.localEpochMS/1000
    p:step(epoch-p.now)
    p.host.namespace.Physics.VERSION=p.host.namespace.Physics.VERSION+1
    assert(p.host:call("TakeRaceStart")==nil,"launch must retain the negotiated physics version")
    detached(p.host)
end
do
    local p=armedPair()
    local epoch=p.host:view().clock.localEpochMS/1000
    p:step(epoch-p.now)
    p.host.namespace.Physics.new=function()
        p.host:call("Stop","error")
        return {tick=0}
    end
    assert(p.host:call("TakeRaceStart")==nil,"a reentrant Stop during initialization cannot return a launch")
    detached(p.host)
end
do
    -- Complete the control START ACK reentrantly, at a later validated clock.
    local p=pair(true); p:lobby(); p:ready()
    local e=p.host
    local original=e.onSend
    e.onSend=function(packet)
        if packet.prefix=="AZKART2" then
            local message=e.namespace.RaceProtocol.decode(packet.payload)
            if message.kind=="START" then
                e.now=e.now+0.125
                receive(e,wire(e,"ACK",300,{ackKind="START",ackSequence=message.sequence}),GUEST)
                return
            end
        end
        original(packet)
    end
    assert(e:call("PrepareStart",42)); e:update(p.now+0.5)
    assert(e:view().phase=="coordinating" and e:view().clock.phase=="calibrating"
        and e:view().clock.reason==nil,"handoff must use the refreshed callback clock")
    e:call("Stop","error"); detached(e)
end
do
    local e=client(HOST,true)
    e.globals.C_ChatInfo.RegisterAddonMessagePrefix=function(prefix)
        e.registerCalls=e.registerCalls+1
        return prefix=="AZKCLK1" and 99 or 0
    end
    refusal(e,"HostCoordinated",GUEST,CODE,"mirage_raceway"); detached(e)
    assert(#e.sends==0,"failed clock registration never starts control traffic")
end
do
    local p=pair(true)
    p.delay,p.offset=0.35,{host=0,guest=5}
    p:lobby(); p:ready(); assert(p.host:call("PrepareStart",42))
    p:untilTrue(function()
        return p.host:view().clock and p.guest:view().clock
            and p.host:view().clock.phase=="armed" and p.guest:view().clock.phase=="armed"
    end)
    local h,g=p.host:view().clock,p.guest:view().clock
    assert(h.rttMS>=700 and h.rttMS<=1000 and h.offsetLowMS<=5000 and h.offsetHighMS>=5000,
        "native adapter preserves delayed delivery and independent clock offsets")
    local bundles={}
    for _=1,120 do
        p:step(0.1)
        for _,role in ipairs({"host","guest"}) do
            if not bundles[role] then bundles[role]=p[role]:call("TakeRaceStart") end
        end
        if bundles.host and bundles.guest then break end
    end
    assert(bundles.host and bundles.guest and bundles.host.vehicle.tick==0 and bundles.guest.vehicle.tick==0)
    assert(bundles.guest.localEpochMS-bundles.host.hostEpochMS==math.floor((g.offsetLowMS+g.offsetHighMS)/2))
    assertPacing(p.host); assertPacing(p.guest); detached(p.host); detached(p.guest)
end

-- Live mode adopts the one-shot bundle inside the existing transport owner.
-- Real fixed-step modules and two isolated native mocks are used throughout.
local function livePair(track,delayed,beforeLobby)
    local p=pair(true,true)
    if delayed then p.delay,p.offset=0.35,{host=0,guest=5} end
    if beforeLobby then beforeLobby(p) end
    p:lobby(track); p:ready()
    local leases={}
    for _,role in ipairs({"host","guest"}) do
        local e=p[role]
        assert(e.registerCalls==(e.registeredPrefixes.AZKRUN3 and 5 or 4)
            and e.registeredPrefixes.AZKRUN2 and e.registeredPrefixes.AZKGRD1,
            "live telemetry registration requires deliberate live opt-in")
        local grid=e:view().grid
        local peerRole=role=="host" and "guest" or "host"
        assert(grid.ready and grid.localKartId==p.karts[role] and grid.peerKartId==p.karts[peerRole])
        assert(math.abs((grid.localPose.x-grid.peerPose.x)^2
            +(grid.localPose.y-grid.peerPose.y)^2-36^2)<0.001,
            "agreed kart profiles provide two separate collision-legal grid slots")
        leases[role]={owner=e.frame.akNetworkOwner,update=e.frame.scripts.OnUpdate,
            registrations=e.eventCalls,scripts=e.scriptCalls}
        local v,why=e:call("AdvanceLive",{accelerate=true})
        assert(v==nil and type(why)=="string","input cannot advance a live race before GO")
    end
    assert(p.host:call("PrepareStart",42))
    p:untilTrue(function()
        return p.host:view().clock and p.guest:view().clock
            and p.host:view().clock.phase=="armed" and p.guest:view().clock.phase=="armed"
    end)
    for _=1,160 do
        if p.host:view().live and p.guest:view().live then break end
        p:step(0.1)
    end
    for _,role in ipairs({"host","guest"}) do
        local e,lease=p[role],leases[role]
        local v=e:view()
        assert(v.liveMode and v.phase=="racing" and v.live and v.live.phase=="running")
        assert(v.live.vehicle.tick==0 and v.live.race.totalTicks==0,
            "native GO adoption does not step simulation or add a second countdown")
        assert(v.live.vehicle.x==v.grid.localPose.x and v.live.vehicle.y==v.grid.localPose.y
            and v.live.localKartId==p.karts[role]
            and v.live.peerKartId==p.karts[role=="host" and "guest" or "host"],
            "GO adopts the staged role-specific spawn and agreed visual identities")
        assert(e.frame.akNetworkOwner==lease.owner and e.frame.scripts.OnUpdate==lease.update
            and e.eventCalls==lease.registrations and e.scriptCalls==lease.scripts
            and e.unregisterCalls==0 and e.detachCalls==0,
            "GO retains the identical native lease, hooks and budget owner")
        local bundle,why=e:call("TakeRaceStart")
        assert(bundle==nil and why=="live_start_owned","UI cannot steal a backend-owned live launch")
        assert(e.createdFrames==0 and #e.output==0)
    end
    return p
end

local function drivePair(p,seconds)
    for _=1,math.floor(seconds*60+0.5) do
        p:step(1/60)
        for _,role in ipairs({"host","guest"}) do
            local e=p[role]
            if e:view().live and e:view().live.phase=="running" then
                local view,why=e:call("AdvanceLive",{accelerate=true,left=role=="guest"})
                assert(view and why==nil,"deliberate input advances the adopted live controller")
            end
        end
    end
end

-- The real course catalogue, geometry snapshots and native lease are shared
-- by every available map; a city offer must not fall back to Mirage or Oval.
for _,id in ipairs({"mirage_raceway","stormwind_city","ironforge_gp",
    "darnassus_canopy","orgrimmar_canyon","undercity_slime","thunder_bluff_skyway"}) do
    local p=livePair(id)
    for _,role in ipairs({"host","guest"}) do
        local e=p[role]
        local track=e.namespace.Courses.build(id,e.namespace.Track.crossesGate)
        local view=e:view()
        assert(view.offer.trackId==id and view.offer.trackVersion==track.version
            and view.live.trackId==id and view.live.trackVersion==track.version,
            "GO preserves the negotiated production map and version: "..id)
        assert(view.live.vehicle.x==view.grid.localPose.x
            and track.isDrivable(view.live.vehicle.x,view.live.vehicle.y))
        assertPacing(e)
        e:call("Stop","left"); detached(e)
    end
end

do
    local p=livePair()
    local captured={}
    for _,role in ipairs({"host","guest"}) do
        local e=p[role]
        captured[role]={id=p.karts[role],vehicle=e:view().live.vehicle}
        local presentation=e:view()
        presentation.grid.localKartId="dwarven_biker"
        presentation.live.localKartId="dwarven_biker"
        e.namespace.UI.kartId="dwarven_biker"
    end
    p:step(1/60)
    for _,role in ipairs({"host","guest"}) do
        local e,initial=p[role],captured[role]
        local view=assert(e:call("AdvanceLive",{accelerate=true,left=true}))
        local expected=initial.vehicle
        for _=initial.vehicle.tick+1,view.vehicle.tick do
            expected=e.namespace.Physics.step(expected,{accelerate=true,left=true},
                e.namespace.Physics.FIXED_DT,e.namespace.Courses.build("mirage_raceway",e.namespace.Track.crossesGate),initial.id)
        end
        for field,value in pairs(expected) do
            assert(view.vehicle[field]==value,"transport GO keeps agreed handling: "..field)
        end
        assert(view.localKartId==initial.id,"mutable copied/UI identity cannot replace the agreed live kart")
        e:call("Stop","left")
    end
end

do
    local e=client(HOST,true)
    assert(not e.registeredPrefixes.AZKRUN2)
    assert(e:call("HostCoordinated",GUEST,CODE,"mirage_raceway"))
    assert(not e.registeredPrefixes.AZKRUN2,"legacy coordination does not register live telemetry")
    assert(not e.registeredPrefixes.AZKGRD1,"legacy coordination does not exchange live kart profiles")
    e:call("Stop","error"); detached(e)
end
do
    local e=client(HOST,true)
    e.globals.C_ChatInfo.RegisterAddonMessagePrefix=function(prefix)
        e.registerCalls=e.registerCalls+1
        return prefix=="AZKRUN2" and 99 or 0
    end
    refusal(e,"HostLive",GUEST,CODE,"mirage_raceway"); detached(e)
    assert(#e.sends==0,"failed live registration must not start lobby traffic")
end

do
    local p=pair(true,true)
    local profiles={}
    p.drop=function(packet)
        if packet.prefix=="AZKGRD1" and packet.sender==HOST then
            local message=assert(p.host.namespace.RaceGrid.decode(packet.payload))
            if message.kind=="PROFILE" then
                profiles[#profiles+1]=packet.payload
                return #profiles==1
            end
        end
    end
    p:lobby()
    assert(not p.host:view().canSetReady or not p.guest:view().canSetReady,
        "an unacknowledged kart profile does not permit early Ready")
    local unrelated=assert(p.host.namespace.RaceGrid.encode({kind="PROFILE",session="OLD123",kartId="dwarf_car"}))
    assert(not receive(p.host,unrelated,GUEST,"AZKGRD1"))
    assert(not receive(p.host,unrelated,"Other Person","AZKGRD1"))
    p:ready()
    assert(#profiles==2 and profiles[1]==profiles[2],
        "a lost profile retries its identical bounded native message before Ready")
    for _,e in ipairs({p.host,p.guest}) do assertPacing(e); e:call("Stop","stopped"); detached(e) end
end

do
    local p=pair(true,true)
    p.drop=function(packet) return packet.prefix=="AZKGRD1" end
    p:lobby()
    refusal(p.host,"Ready",true); refusal(p.host,"PrepareStart",42)
    for _=1,30 do p:step(0.5) end
    for _,e in ipairs({p.host,p.guest}) do
        detached(e)
        assert(e:view().phase=="closed" and not e:view().live,
            "exhausted cosmetic agreement fails closed without an unagreed grid or live race")
        assertPacing(e)
    end
end

do
    local p=livePair("mirage_raceway",true)
    assert(p.host:view().clock.rttMS>=700 and p.host:view().clock.rttMS<=1000)
    -- The live canvas may mark its deliberate capture active, while an
    -- unrelated solo capture remains a terminal conflict.
    for _,role in ipairs({"host","guest"}) do
        p[role].namespace.UI.active=true; p[role].namespace.UI.liveActive=true
    end
    drivePair(p,3)
    for _,role in ipairs({"host","guest"}) do
        local e=p[role]
        local v=e:view()
        assert(v.phase=="racing" and v.live.vehicle.tick>=175 and v.live.vehicle.tick<=185)
        assert(v.live.remote and v.live.remote.tick>0 and not v.live.remoteVerified
            and not v.live.resultVerified,"remote progress is explicitly observational")
        assert(v.live.trackId=="mirage_raceway" and v.live.race.countdownTicks==0)
        local prefixes={}
        for _,packet in ipairs(e.sends) do prefixes[packet.prefix]=true end
        assert(prefixes.AZKART2 and prefixes.AZKCLK1 and prefixes.AZKGRD1 and prefixes.AZKRUN2,
            "one native sender carries lobby, clock and latest-only live output")
        assertPacing(e)
        local copied=e:call("AdvanceLive",{})
        copied.vehicle.x=-1; copied.race.laps.completedLaps=3; copied.remote.x=-1
        assert(e:view().live.vehicle.x>=0 and e:view().live.race.laps.completedLaps~=3
            and e:view().live.remote.x>=0,"presentation receives copied live state")
    end
    local h=p.host
    local before=h:view().live
    local function pose(extra)
        local m={kind="STATE",session=CODE,sequence=before.remoteSequence+10,
            sampleMS=(before.remote.sampleMS or 0)+1,tick=before.remote.tick+1,x=before.remote.x,y=before.remote.y,
            headingQ=0,speedQ=0,driftTier=0,boosting=false,completedLaps=2,
            passed=0,status="running"}
        for k,v in pairs(extra or {}) do m[k]=v end
        return assert(h.namespace.LiveProtocol.encode(m))
    end
    assert(not receive(h,pose(),"Someone Else","AZKRUN2"))
    assert(not receive(h,pose(),GUEST,"AZKRUN2","PARTY"))
    assert(not receive(h,pose({session="OLD123"}),GUEST,"AZKRUN2"))
    local payload=pose()
    assert(receive(h,payload,GUEST,"AZKRUN2"))
    assert(not receive(h,payload,GUEST,"AZKRUN2"),"duplicate poses have no authority")
    local after=h:view().live
    assert(after.vehicle.x==before.vehicle.x and after.vehicle.y==before.vehicle.y
        and after.vehicle.tick==before.vehicle.tick
        and after.race.totalTicks==before.race.totalTicks
        and after.race.laps.completedLaps==before.race.laps.completedLaps
        and after.remote.completedLaps==2 and after.counters.stale>before.counters.stale,
        "valid peer claims never move local physics or award local laps")
    for _,role in ipairs({"host","guest"}) do
        local e=p[role]
        e:call("Stop","stopped"); detached(e)
        local frozen=e:view().live
        assert(frozen and frozen.phase=="closed" and frozen.vehicle.tick>0)
        local detachCount=e.detachCalls
        e:update(e.now+1); e:call("Stop","stopped")
        assert(e:view().live.vehicle.tick==frozen.vehicle.tick and e.detachCalls==detachCount,
            "terminal live state stays available and native cleanup happens once")
    end
end

-- All native live safety paths freeze the current run and relinquish the
-- lease. They must not regress into a new solo race or a fresh native sender.
for _,interrupt in ipairs({
    function(e) e.combat=true; e:update() end,
    function(e) e.chatLocked=true; e:update() end,
    function(e) e.namespace.UI.active=true; e.namespace.UI.liveActive=false; e:update() end,
    function(e) e.clockThrows=true; e:update() end,
    function(e) e.now=e.now-0.1; e:update() end,
    function(e) e:call("HandleEvent","PLAYER_REGEN_DISABLED") end,
    function(e) e:call("HandleEvent","PLAYER_LEAVING_WORLD") end,
    function(e) e:call("HandleEvent","PLAYER_LOGOUT") end,
}) do
    local p=livePair()
    drivePair(p,0.2)
    local e=p.host
    local tick,sends,oldUpdate=e:view().live.vehicle.tick,#e.sends,e.frame.scripts.OnUpdate
    interrupt(e); detached(e)
    assert(e:view().live.phase=="closed" and e:view().live.vehicle.tick==tick)
    local detachCount=e.detachCalls
    e.now=p.now+1; e.combat=false; e.chatLocked=false; e.clockThrows=false
    e.namespace.UI.active=false; e:call("HandleEvent","PLAYER_REGEN_ENABLED")
    e:run(oldUpdate,e.frame,1); e:update()
    local view,why=e:call("AdvanceLive",{accelerate=true})
    assert(view and view.phase=="closed" and view.vehicle.tick==tick and why==nil,
        "post-exit rendering may read the copied frozen run without advancing it")
    assert(e:view().live.vehicle.tick==tick and #e.sends==sends and e.detachCalls==detachCount)
    p.guest:call("Stop","stopped"); detached(p.guest)
end

for _,outcome in ipairs({"failed","throttled","unknown","throws"}) do
    local p=livePair()
    drivePair(p,0.2)
    local e=p.host
    if outcome=="failed" then e.sendResult=12
    elseif outcome=="throttled" then e.sendResult=3
    elseif outcome=="unknown" then e.sendResult=nil
    else e.sendThrows=true end
    local sends,tick=#e.sends,e:view().live.vehicle.tick
    p:step(0.51)
    detached(e)
    assert(#e.sends==sends+1 and e.sends[#e.sends].prefix=="AZKRUN2")
    assert(e:view().live.phase=="closed" and e:view().live.vehicle.tick==tick)
    e:update(e.now+2); assert(#e.sends==sends+1,"native live failures cannot retry or auto-resume")
    assertPacing(e)
    for _,message in ipairs(e.output) do assert(not message:find("private",1,true)) end
    p.guest:call("Stop","stopped"); detached(p.guest)
end

do
    local p=livePair()
    drivePair(p,0.2)
    p.drop=function(packet) return packet.prefix=="AZKRUN2" and packet.sender==GUEST end
    -- Fresh wrong-session/unauthorized traffic must not become a keepalive.
    local remote=p.host:view().live.remote
    local foreign=assert(p.host.namespace.LiveProtocol.encode({kind="STATE",session="OLD123",
        sequence=100,sampleMS=(remote.sampleMS or 0)+1,tick=remote.tick+1,x=remote.x,y=remote.y,headingQ=0,speedQ=0,
        driftTier=0,boosting=false,completedLaps=0,passed=0,status="running"}))
    for _=1,12 do
        p:step(0.5)
        if p.host:call("IsActive") then
            assert(not receive(p.host,foreign,GUEST,"AZKRUN2"))
            assert(not receive(p.host,foreign,"Other Person","AZKRUN2"))
        end
        for _,role in ipairs({"host","guest"}) do
            local e=p[role]
            if e:call("IsActive") then e:call("AdvanceLive",{accelerate=true}) end
        end
    end
    detached(p.host)
    assert(p.host:view().live.reason=="peer_timeout" and p.host:view().live.vehicle.tick>0)
    assert(p.host.namespace.RaceProtocol.decode(p.host.sends[#p.host.sends].payload).kind=="CANCEL",
        "peer timeout gets at most the existing paced terminal control notice")
    assertPacing(p.host); assertPacing(p.guest)
    p.guest:call("Stop","stopped"); detached(p.guest)
end

do
    local p=livePair()
    drivePair(p,32)
    local h,g=p.host,p.guest
    assert(h:view().phase=="racing" and g:view().phase=="racing",
        "live driving retires the old thirty-second lobby deadline")
    local tick=h:view().live.vehicle.tick
    assert(h:call("Leave"))
    for _=1,8 do
        p:step(0.5)
        if not h:call("IsActive") and not g:call("IsActive") then break end
    end
    detached(h); detached(g)
    assert(h:view().live.vehicle.tick==tick and h:view().live.phase=="closed"
        and g:view().live.phase=="closed","post-lobby Leave freezes both adopted races")
    local cancels=0
    for _,packet in ipairs(h.sends) do
        if packet.prefix=="AZKART2" and h.namespace.RaceProtocol.decode(packet.payload).kind=="CANCEL" then
            cancels=cancels+1
        end
    end
    assert(cancels==1,"a live Leave sends exactly one paced control cancellation")
    assertPacing(h); assertPacing(g)
end

do
    local p=livePair()
    drivePair(p,0.2)
    local e=p.host
    local sends,tick=#e.sends,e:view().live.vehicle.tick
    e.onSend=function(packet)
        assert(packet.prefix=="AZKRUN2")
        e:call("Stop","stopped")
        assert(e.frame.akNetworkSending==e.transport)
        assert(not e:run(e.probe.Command,"listen Birch Vale DEF456"),
            "a live send callback cannot transfer the native lease before unwinding")
    end
    p:step(0.51)
    detached(e)
    assert(#e.sends==sends+1 and e:view().live.vehicle.tick==tick
        and e:view().live.phase=="closed","native completion cannot revive a reentrantly stopped live run")
    e.onSend=nil; e:update(e.now+1)
    assert(#e.sends==sends+1)
    assertPacing(e)
    p.guest:call("Stop","stopped"); detached(p.guest)
end

do
    local p=pair(true,true)
    p:lobby(); p:ready(); assert(p.host:call("PrepareStart",42))
    p:untilTrue(function()
        return p.host:view().clock and p.guest:view().clock
            and p.host:view().clock.phase=="armed" and p.guest:view().clock.phase=="armed"
    end)
    p.host.namespace.LiveRace.new=function() error("private live initializer failure") end
    for _=1,160 do
        if p.host:view().phase=="closed" then break end
        p:step(0.1)
    end
    detached(p.host)
    assert(p.host:view().reason=="controller_error" and not p.host:view().live
        and p.host:view().canHost,"failed GO adoption cannot leak its lease or return a partial live run")
    p.guest:call("Stop","stopped"); detached(p.guest)
end

do
    local p=livePair()
    local h=p.host
    local oldSequence
    for _,packet in ipairs(p.guest.sends) do
        if packet.prefix=="AZKART2" then
            local message=assert(h.namespace.RaceProtocol.decode(packet.payload))
            if message.kind=="READY" then oldSequence=message.sequence; break end
        end
    end
    assert(oldSequence,"the host actually received its peer's pre-GO READY command")
    local cancel=wire(h,"CANCEL",oldSequence,{reason="left"})
    assert(not receive(h,cancel,"Other Person"))
    assert(not receive(h,wire(h,"CANCEL",oldSequence,{reason="left",session="OLD123"}),GUEST))
    assert(h:view().phase=="racing" and h:call("IsActive"),
        "unrelated native peers or sessions cannot cancel an adopted race")
    local tick,sends=h:view().live.vehicle.tick,#h.sends
    local accepted,why=receive(h,cancel,GUEST)
    assert(not accepted and why=="conflicting_sequence",
        "post-GO CANCEL preserves the control controller's received-sequence history")
    detached(h)
    assert(h:view().live.phase=="closed" and h:view().live.reason=="error"
        and h:view().lastError=="controller_error" and h:view().live.vehicle.tick==tick
        and #h.sends==sends,"a conflicting old command fails closed without masquerading as a fresh peer Leave")
    p.guest:call("Stop","stopped"); detached(p.guest)
end

-- Diagnostics and normal racing share the same rolling window across a
-- lease handoff, even after an interrupted diagnostic has released its frame.
do
    local e=client()
    local probe={}
    e.namespace.GroupProbe=probe
    assert(not e:call("ReserveDiagnosticSend",probe,0,20),"a diagnostic must own the frame")
    e.frame.akNetworkOwner=probe
    assert(not e:call("ReserveDiagnosticSend",{},0,20),"another caller cannot spend a diagnostic lease")
    for _,bad in ipairs({-1,0/0,math.huge}) do
        assert(not e:call("ReserveDiagnosticSend",probe,bad,20))
    end
    for _,bad in ipairs({0,1.5,159,math.huge}) do
        assert(not e:call("ReserveDiagnosticSend",probe,0,bad))
    end
    assert(e:call("ReserveDiagnosticSend",probe,0,120))
    assert(not e:call("ReserveDiagnosticSend",probe,0.49,1),"half-second pacing is shared")
    assert(not e:call("ReserveDiagnosticSend",probe,0.5,39),"158 counted bytes is a shared ceiling")
    assert(e:call("ReserveDiagnosticSend",probe,0.5,38))
    assert(not e:call("DiagnosticTrafficQuiet",1.49) and e:call("DiagnosticTrafficQuiet",1.5),
        "standalone experiments wait one full second after the last group reservation")
    assert(not e:call("DiagnosticTrafficQuiet",0/0))
    assert(not e:call("ReserveDiagnosticSend",probe,0.75,1))
    assert(not e:call("ReserveDiagnosticSend",probe,0.4,1),"diagnostics cannot move the clock backwards")
    assert(#e.sends==0 and e.registerCalls==0,"budget reservation itself never touches native messaging")
    e.frame.akNetworkOwner=nil
    e.now=0.75
    assert(e:call("Host",GUEST,CODE,"mirage_raceway"))
    e:update(0.75); assert(#e.sends==0,"arming a race does not clear the diagnostic's native window")
    e:update(1); assert(#e.sends==1,"a normal send resumes only after cadence and bytes permit it")
    assert(not e:call("ReserveDiagnosticSend",probe,1.5,20),"a live controller cannot grant a probe budget")
    e:call("Stop","stopped"); detached(e)
end

-- Exercise room/result transitions using real transport, clock/grid and
-- fixed-step driving. A short race-rule fixture finishes after N simulation
-- ticks so this lifecycle test need not steer three physical laps per round.
local function finishAt(e,ticks)
    e.finishTick=ticks
    if e.finishFixture then return end
    e.finishFixture=true
    local step=e.namespace.Race.step
    e.namespace.Race.step=function(race,previous,current,...)
        local nextRace=step(race,previous,current,...)
        if nextRace.status=="running" and current.tick>=e.finishTick then
            nextRace.status,nextRace.finishTick,nextRace.totalTicks="finished",current.tick,current.tick
            nextRace.laps.completedLaps,nextRace.laps.checkpoints.passed=nextRace.targetLaps,0
        end
        return nextRace
    end
end
local function finishRound(p)
    local pending=false
    for _=1,360 do
        p:step(1/60)
        for _,role in ipairs({"host","guest"}) do
            local e=p[role]
            local v=e:view()
            if v.live and v.live.phase=="running" then assert(e:call("AdvanceLive",{accelerate=true})) end
            local result=e:view().results
            if result and result.rows[1].status=="finished" and not result.complete then
                pending=true
                assert(result.rows[1].rank==nil,"local-only finishes cannot have a fabricated placement")
            end
        end
        if p.host:view().phase=="postrace" and p.guest:view().phase=="postrace" then return pending end
    end
    error("two finished peers did not retain their postrace room")
end
local function nextGo(p)
    p:untilTrue(function() return p.guest:view().canJoin end)
    assert(p.guest:view().live==nil and p.host:view().live==nil,
        "a next-round offer must not expose the previous live token for adoption")
    assert(p.guest:call("Join"))
    p:untilTrue(function() return p.host:view().phase=="lobby" and p.guest:view().phase=="lobby"
        and not p.host:view().pendingKind and not p.guest:view().pendingKind end)
    p:ready();assert(p.host:call("PrepareStart",42))
    for _=1,160 do
        if p.host:view().phase=="racing" and p.guest:view().phase=="racing" then return end
        p:step(0.1)
    end
    error("next shared round did not reach GO")
end

-- Every dungeon sprint follows the same native adapter/grid/clock/live/result
-- lifecycle, with one-run metadata rather than a forged three-lap offer.
-- Race completion is the bounded fixture above; actual gate traversal is
-- independently checked by the dungeon and LiveRace tests.
for _,id in ipairs({"scarlet_graveyard","scarlet_library","scarlet_armory","scarlet_cathedral"}) do
    local p=livePair(id,true)
    for _,role in ipairs({"host","guest"}) do
        local e=p[role]
        local view=e:view()
        assert(view.offer.trackId==id and view.offer.laps==1 and view.live.race.targetLaps==1
            and view.live.trackVersion==e.namespace.Courses.build(id,e.namespace.Track.crossesGate).version,
            "sprint geometry/version/target survives native GO: "..id)
        finishAt(e,role=="host" and 20 or 65)
    end
    assert(finishRound(p),"one sprint finisher remains pending until its peer reports: "..id)
    assert(p.host:view().results.complete and p.host:view().results.rows[1].completedLaps==1
        and p.host:view().room.peer==GUEST and p.guest:view().room.peer==HOST)
    assert(p.host:call("Rematch"),"sprint keeps the same-player rematch room")
    nextGo(p)
    assert(p.host:view().offer.laps==1 and p.guest:view().offer.laps==1
        and p.host:view().live.race.targetLaps==1 and p.host:view().session=="ABC124")
    finishAt(p.host,45);finishAt(p.guest,15)
    assert(finishRound(p))
    assert(p.host:view().results.complete and p.host:view().results.rows[1].name==GUEST,
        "sprint rematch produces fresh reported results")
    for _,e in ipairs({p.host,p.guest}) do assertPacing(e) end
    assert(p.host:call("Leave"));p:step(0.5);p:step(0.5);p:step(1)
    detached(p.host);detached(p.guest)
end

do
    local p=livePair()
    local leases={}
    for _,role in ipairs({"host","guest"}) do
        local e=p[role]
        finishAt(e,role=="host" and 30 or 90)
        leases[role]={owner=e.frame.akNetworkOwner,update=e.frame.scripts.OnUpdate,eventCalls=e.eventCalls}
    end
    assert(finishRound(p),"the first finisher shows pending results before the late peer finishes")
    local h,g=p.host:view(),p.guest:view()
    assert(h.room.peer==GUEST and g.room.peer==HOST and h.canRematch and not g.canRematch)
    assert(h.results.complete and not h.results.verified and h.results.rows[1].localPlayer
        and h.results.rows[1].rank==1 and h.results.rows[1].totalTicks==30
        and g.results.rows[1].name==HOST and g.results.rows[1].totalTicks==30)
    local resultSession=h.results.session
    local oldPacket
    for _,packet in ipairs(p.host.sends) do if packet.prefix=="AZKRUN2" then oldPacket=packet end end
    assert(oldPacket)
    local attempts=h.traffic.attempts
    refusal(p.guest,"Rematch","stormwind_city")
    refusal(p.host,"Rematch","test_oval")
    assert(p.host:view().room and p.host:view().traffic.attempts==attempts,
        "a refused rematch cannot send, leave the room or switch to solo")
    h.room.peer,h.results.rows[1].totalTicks="Mutated",999
    assert(p.host:view().room.peer==GUEST and p.host:view().results.rows[1].totalTicks==30)
    local fake=assert(p.guest.namespace.RaceProtocol.encode({kind="INVITE",session="ABC124",sequence=1,
        physicsVersion=p.guest.namespace.Physics.VERSION,trackId="stormwind_city",trackVersion=999,laps=3}))
    assert(not receive(p.guest,fake,"Other Person") and p.guest:view().phase=="postrace")
    assert(not receive(p.guest,fake,HOST) and p.guest:view().phase=="postrace"
        and p.guest:view().session==CODE,"a refused next offer cannot consume its code or replace the old room")
    assert(p.host:call("Rematch","stormwind_city"))
    assert(p.host:view().session=="ABC124" and p.host:view().offer.trackId=="stormwind_city"
        and p.host:view().results.session==resultSession and p.host:view().live==nil)
    nextGo(p)
    for _,role in ipairs({"host","guest"}) do
        local e,v=p[role],p[role]:view()
        assert(v.live.session=="ABC124" and v.live.trackId=="stormwind_city" and v.live.vehicle.tick==0)
        assert(v.room.peer==(role=="host" and GUEST or HOST) and v.results.session=="ABC124")
        local lease=leases[role]
        assert(e.frame.akNetworkOwner==lease.owner and e.frame.scripts.OnUpdate==lease.update
            and e.eventCalls==lease.eventCalls and e.unregisterCalls==0,
            "rematch retains the same native owner/hooks and traffic window")
    end
    local before=p.guest:view().live.vehicle.tick
    assert(not receive(p.guest,oldPacket.payload,oldPacket.sender,oldPacket.prefix))
    assert(p.guest:view().live.vehicle.tick==before and p.guest:view().live.remote==nil,
        "old-round telemetry cannot enter the fresh round")
    finishAt(p.host,50);finishAt(p.guest,20)
    assert(finishRound(p))
    assert(p.host:view().results.rows[1].name==GUEST and p.host:view().results.rows[1].rank==1
        and p.host:view().results.session=="ABC124","second-round placements cannot retain old results")
    for _,e in ipairs({p.host,p.guest}) do assertPacing(e) end
    assert(p.host:call("Leave") and p.host:view().room==nil)
    p:step(0.5);p:step(0.5);p:step(1)
    detached(p.host);detached(p.guest)
    assert(not p.host:view().canRematch and not p.guest:view().room,"Leave clears the selected multiplayer room")
end

-- A host can offer again while a finished guest is still draining terminal
-- poses, without waiting for a coincidental last-packet ordering.
do
    local p=livePair();finishAt(p.host,10);finishAt(p.guest,11)
    for _=1,300 do
        p:step(1/60)
        for _,e in ipairs({p.host,p.guest}) do
            if e:view().live and e:view().live.phase=="running" then e:call("AdvanceLive",{}) end
        end
        if p.host:view().canRematch then break end
    end
    assert(p.host:view().canRematch and p.guest:view().live.race.status=="finished")
    assert(p.host:call("Rematch"))
    p:untilTrue(function() return p.guest:view().canJoin end)
    assert(p.guest:view().session=="ABC124" and p.guest:view().results.complete)
    p.host:call("Stop","stopped");p.guest:call("Stop","stopped")
end

-- Postrace inactivity and explicit lifecycle exits cannot keep an idle lease.
for _,event in ipairs({"expiry","PLAYER_REGEN_DISABLED","PLAYER_LEAVING_WORLD","PLAYER_LOGOUT"}) do
    local p=livePair();finishAt(p.host,5);finishAt(p.guest,5);finishRound(p)
    if event=="expiry" then p.host:update(p.now+301) else p.host:call("HandleEvent",event) end
    assert(p.host:view().room==nil and not p.host:view().canRematch)
    detached(p.host)
    p.guest:call("Stop","stopped")
end

-- Missing terminal delivery keeps an honest pending result and the known
-- players, rather than guessing last place or falling into single player.
do
    local p=livePair();finishAt(p.host,5);finishAt(p.guest,8)
    p.drop=function(packet)
        local message=packet.prefix=="AZKRUN2" and p.host.namespace.LiveProtocol.decode(packet.payload)
        return packet.sender==GUEST and message and message.status=="finished"
    end
    finishRound(p)
    local view=p.host:view()
    assert(view.phase=="postrace" and view.room.peer==GUEST and not view.results.complete
        and view.results.rows[1].status=="finished" and view.results.rows[1].rank==nil
        and view.results.rows[2].status=="pending" and view.canRematch)
    p.drop=nil
    assert(p.host:call("Rematch"));nextGo(p)
    p.host:call("Stop","stopped");p.guest:call("Stop","stopped")
end

-- Never wrap, asymmetrically skip a used id, or erase the lifetime session cap.
for _,mode in ipairs({"wrap","collision","capacity"}) do
    local oldCode=CODE
    if mode=="wrap" then CODE="ZZZZZZ" end
    local p=livePair(nil,nil,function(pair)
        if mode=="collision" then
            assert(pair.host:call("Host",GUEST,"ABC124","mirage_raceway"))
            pair.host:call("Stop","stopped")
        elseif mode=="capacity" then
            for index=0,62 do
                assert(pair.host:call("Host",GUEST,("CAP%03d"):format(index),"mirage_raceway"))
                pair.host:call("Stop","stopped")
            end
        end
        -- Observation counters for this deliberate current lease only. Native
        -- attempt/pacing accounting is never cleared by these preliminary arms.
        pair.host.unregisterCalls,pair.host.detachCalls=0,0
    end)
    CODE=oldCode
    finishAt(p.host,5);finishAt(p.guest,5);finishRound(p)
    local expected=mode=="wrap" and "next_session_limit" or (mode=="collision" and "reused_session" or "session_limit")
    assert(not p.host:view().canRematch and p.host:view().room.rematchReason==expected)
    local sends=#p.host.sends
    local accepted,why=p.host:call("Rematch")
    assert(not accepted and why==expected and p.host:view().room and #p.host.sends==sends)
    p.host:call("Stop","stopped");p.guest:call("Stop","stopped")
end

-- Native callbacks cannot commit a rematch after Stop releases/replaces its
-- owner. This covers both the action preflight and the receive candidate build.
for _,where in ipairs({"clock","candidate"}) do
    local p=livePair();finishAt(p.host,5);finishAt(p.guest,5);finishRound(p)
    if where=="clock" then
        local get=p.host.globals.GetTime
        p.host.globals.GetTime=function() p.host:call("Stop","stopped");return get() end
        assert(not p.host:call("Rematch"));detached(p.host)
        p.host.globals.GetTime=get
    else
        local build=p.guest.namespace.Courses.build
        p.guest.namespace.Courses.build=function(...)
            p.guest:call("Stop","stopped")
            return build(...)
        end
        assert(p.host:call("Rematch"))
        p:step(0.5);detached(p.guest)
        assert(p.guest:view().room==nil and p.guest:view().session==CODE,
            "a canceled candidate cannot consume/adopt the next round")
    end
    p.host:call("Stop","stopped");p.guest:call("Stop","stopped")
end

-- Rejected next-round offers from the selected peer cannot allocate an
-- unbounded number of private candidate/geometry snapshots per callback.
do
    local p=livePair();finishAt(p.host,5);finishAt(p.guest,5);finishRound(p)
    local fake=assert(p.guest.namespace.RaceProtocol.encode({kind="INVITE",session="ABC124",sequence=1,
        physicsVersion=p.guest.namespace.Physics.VERSION,trackId="stormwind_city",trackVersion=999,laps=3}))
    local builds,build=0,p.guest.namespace.Courses.build
    p.guest.namespace.Courses.build=function(...) builds=builds+1;return build(...) end
    for _=1,8 do assert(not receive(p.guest,fake,HOST) and p.guest:view().room) end
    local before=builds
    assert(not receive(p.guest,fake,HOST) and builds==before and p.guest:view().room==nil
        and p.guest:view().lastError=="peer_flood")
    detached(p.guest);p.host:call("Stop","stopped")
end

-- A failed fresh-controller dependency must be a fixed terminal refusal,
-- never an escaping Lua error or a permanent busy owner. Restore the injected
-- function and perform a new explicit arm to prove the action lock is free.
for _,method in ipairs({"new","invite"}) do
    local p=livePair();finishAt(p.host,5);finishAt(p.guest,5);finishRound(p)
    local e=p.host
    local original=e.namespace.PeerSession[method]
    e.namespace.PeerSession[method]=function() error("private rematch dependency error") end
    local called,accepted,why=pcall(function() return e:call("Rematch") end)
    e.namespace.PeerSession[method]=original
    assert(called and not accepted and why=="controller_error" and e:view().room==nil,
        "a throwing host rematch dependency fails closed with a fixed public reason: "..method)
    detached(e)
    assert(e:view().canHost and not e:view().transportBusy,
        "a failed rematch cannot strand busy=true: "..method)
    assert(e:call("Host",GUEST,"ERR001","mirage_raceway"))
    e:call("Stop","stopped");p.guest:call("Stop","stopped")
end

for _,method in ipairs({"new","receive"}) do
    local p=livePair();finishAt(p.host,5);finishAt(p.guest,5);finishRound(p)
    local e=p.guest
    local offer=assert(e.namespace.RaceProtocol.encode({kind="INVITE",session="ABC124",sequence=1,
        physicsVersion=e.namespace.Physics.VERSION,trackId="mirage_raceway",trackVersion=1,laps=3}))
    local original=e.namespace.PeerSession[method]
    e.namespace.PeerSession[method]=function() error("private guest candidate error") end
    local called,accepted,why=pcall(receive,e,offer,HOST)
    e.namespace.PeerSession[method]=original
    assert(called and not accepted and why=="controller_error" and e:view().room==nil,
        "a throwing guest candidate cannot escape the native message callback: "..method)
    detached(e)
    assert(e:view().canListen and not e:view().transportBusy)
    assert(e:call("Listen",HOST,"ERR002"))
    e:call("Stop","stopped");p.host:call("Stop","stopped")
end

do
    local p=livePair();finishAt(p.host,50);finishAt(p.guest,5);drivePair(p,0.2)
    local e=p.guest
    assert(e:view().live.race.status=="finished","fixture is draining a local finish")
    local offer=assert(e.namespace.RaceProtocol.encode({kind="INVITE",session="ABC124",sequence=1,
        physicsVersion=e.namespace.Physics.VERSION,trackId="mirage_raceway",trackVersion=1,laps=3}))
    local callbacks=0
    e.onSend=function(packet)
        assert(packet.prefix=="AZKRUN2")
        callbacks=callbacks+1
        local original=e.namespace.PeerSession.new
        e.namespace.PeerSession.new=function() error("private nested candidate error") end
        local called,accepted,why=pcall(receive,e,offer,HOST)
        e.namespace.PeerSession.new=original
        assert(called and not accepted and why=="controller_error")
        assert(e.frame.akNetworkSending==e.transport and e:view().transportBusy,
            "a nested candidate failure retains the current native-send marker until unwinding")
    end
    e:update(e.now+1)
    assert(callbacks==1 and e:view().room==nil and e:view().canHost and not e:view().transportBusy,
        "the outer Update unlocks once after a nested receive failure")
    detached(e);assertPacing(e)
    e.onSend=nil;p.host:call("Stop","stopped")
end

-- A synthetic stacked course exercises native selection/registration without
-- registering an unfinished Warsong map. Production flat metadata stays12.
do
    local p=livePair("mirage_raceway",true,function(pair)
        for _,role in ipairs({"host","guest"}) do
            local e=pair[role]
            local original=e.namespace.Courses.build
            local source=original("mirage_raceway",e.namespace.Track.crossesGate)
            local track={};for key,value in pairs(source) do track[key]=value end
            track.layered,track.levelCount=true,2
            track.validLevel=function(level) return level==0 or level==1 end
            local start=source.spawn()
            track.spawn=function() return {x=start.x,y=start.y,heading=start.heading,level=1} end
            track.resolveMovement=function(x,y,tx,ty,level)
                local nx,ny,hit
                if source.resolveMovement then nx,ny,hit=source.resolveMovement(x,y,tx,ty)
                else nx,ny,hit=source.constrainPosition(tx,ty) end
                return nx,ny,hit,level
            end
            e.namespace.Courses.build=function(id,...)
                if id=="mirage_raceway" then return track end
                return original(id,...)
            end
        end
    end)
    for _,role in ipairs({"host","guest"}) do
        local e=p[role]
        assert(e.registeredPrefixes.AZKRUN3 and e.registerCalls==5
            and e:view().offer.physicsVersion==13 and e:view().live.vehicle.level==1,
            "native offer and GO retain the exact layered compatibility/floor")
    end
    drivePair(p,1.5)
    for _,role in ipairs({"host","guest"}) do
        local e=p[role]
        assert(e:view().live.remote.level==1,"logged layered observation reaches the other copied view")
        local packets=0
        for _,packet in ipairs(e.sends) do
            if packet.prefix=="AZKRUN3" then
                packets=packets+1
                assert(#packet.payload==40 and e.namespace.LiveProtocol.Layered.decode(packet.payload).level==1)
            end
        end
        assert(packets>0,"native adapter selected the layered codec instead of flat telemetry")
        assertPacing(e)
        e:call("Stop","stopped")
    end
end
originalPrint("Session logged-whisper adapter: explicit actions, scoped identities, negotiated live GO, persistent pacing and cleanup verified with mocks")
