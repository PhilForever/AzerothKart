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
        createdFrames=0,registerResult=0,sendResult=0,sends={},output={},raceCalls=0}
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
        self.events[event]=nil
    end
    function e.frame:SetScript(name,callback)
        assert(name=="OnUpdate","Core retains ownership of OnEvent")
        e.scriptCalls=e.scriptCalls+1
        if callback and e.updateThrows then error("private update error") end
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
            assert(prefix=="AZKART2" or prefix=="AZKART1" or prefix=="AZKCLK1")
            e.registerCalls=e.registerCalls+1
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
        for _,module in ipairs({"Physics","Track","MirageRaceway","RaceProtocol","PeerSession",
            "ClockProtocol","StartClock","RaceStart","NetworkProbe","TransportProbe"}) do
            assert(loadfile("addon/AzerothKart/"..module..".lua"))("AzerothKart",ns)
        end
        if clockTest then
            for _,module in ipairs({"Checkpoints","Laps","Race"}) do
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
local function pair(clockTest)
    local p={host=client(HOST,clockTest),guest=client(GUEST,clockTest),now=0,queue={}}
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
        assert(self.guest:call(clockTest and "ListenCoordinated" or "Listen",HOST,CODE))
        assert(self.host:call(clockTest and "HostCoordinated" or "Host",GUEST,CODE,track or "test_oval"))
        self:untilTrue(function() return self.guest:view().canJoin end)
        assert(self.guest:call("Join"))
        self:untilTrue(function()
            return self.host:view().phase=="lobby" and self.guest:view().phase=="lobby"
                and not self.host:view().pendingKind and not self.guest:view().pendingKind
        end)
    end
    function p:ready()
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
    for _,args in ipairs({{"","ABC123","test_oval"},{GUEST,"bad","test_oval"},
        {GUEST,CODE,"unknown"},{"Bad|Name",CODE,"test_oval"}}) do refusal(e,"Host",unpack(args)) end
    assert(e.registerCalls==0,"invalid commands do not touch native APIs")
    assert(e:call("Host",GUEST,CODE,"test_oval"))
    refusal(e,"Listen",HOST,"DEF456")
    assert(e:view().phase=="inviting" and #e.sends==0,"actions queue output, never send directly")
    e:call("Stop","left"); detached(e)
    refusal(e,"Host",GUEST,CODE,"test_oval")
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
        and p.host.namespace.Physics.VERSION==7 and p.host.namespace.Track.version==2,
        "control proposals never activate or mutate local simulation")
    assertPacing(p.host); assertPacing(p.guest)
    p.host:call("Stop","left"); p.guest:call("Stop","left")
end

do
    local e=client(GUEST)
    assert(e:call("Listen","  Åmber   Stone  ",CODE))
    local offer=wire(e,"INVITE",1,{physicsVersion=7,trackId="test_oval",trackVersion=2,laps=3})
    receive(e,offer,"Åmber Stone","OTHER")
    receive(e,offer,"Åmber Stone",nil,"PARTY")
    receive(e,offer,"Åmber Wrong")
    receive(e,wire(e,"INVITE",1,{session="OLD123",physicsVersion=7,trackId="test_oval",trackVersion=2,laps=3}),"Åmber Stone")
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
    refusal(e,"Host",GUEST,CODE,"test_oval"); detached(e)
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
    receive(e,wire(e,"INVITE",1,{physicsVersion=8,trackId="test_oval",trackVersion=2,laps=3}))
    assert(e:view().phase=="closed" and e:view().reason=="incompatible" and #e.sends==0)
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
    assert(e:call("Host",GUEST,CODE,"test_oval")); e:update(1); detached(e)
    assert(#e.sends==1 and e:call("TakeStartProposal")==nil)
    local failed=e:view()
    assert(type(failed.reason or failed.lastError)=="string")
    e:update(10); assert(#e.sends==1,"failed native acceptance cannot retry or auto-resume")
    for _,message in ipairs(e.output) do assert(not message:find("private",1,true)) end
end

-- Success=0 records local acceptance only: absent a peer ACK, retry is bounded.
do
    local e=client(); assert(e:call("Host",GUEST,CODE,"test_oval"))
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
    local e=client(); assert(e:call("Host",GUEST,CODE,"test_oval")); e:update(0.5)
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
    local e=client(); assert(e:call("Host",GUEST,CODE,"test_oval")); e:update(0)
    assert(e:call("Leave")); e:update(0.1); assert(#e.sends==1)
    e:update(0.5)
    assert(#e.sends==2 and e.namespace.RaceProtocol.decode(e.sends[2].payload).kind=="CANCEL")
    e:update(0.5); assert(#e.sends==2); detached(e); assertPacing(e)
    assert(e:call("Host",GUEST,"DEF456","test_oval")); e:update(0.6)
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
    local e=client(); assert(e:call("Host",GUEST,CODE,"test_oval"))
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
    local e=client(); assert(e:call("Host",GUEST,CODE,"test_oval"))
    e.onSend=function() e:call("Stop","left") end
    e:update(0.5); detached(e); e:update(1)
    assert(#e.sends==1 and e:call("TakeStartProposal")==nil)
end

-- Ending a lease from inside a native callback must not let the other adapter
-- acquire the frame until that native call has unwound, in either direction.
do
    local e=client(); assert(e:call("Host",GUEST,CODE,"test_oval"))
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
    local e=client(); assert(e:call("Host",GUEST,CODE,"test_oval"))
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
        assert(bundle.trackId=="mirage_raceway" and bundle.trackVersion==1 and bundle.physicsVersion==7)
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
    p.host.namespace.Physics.VERSION=8
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
    refusal(e,"HostCoordinated",GUEST,CODE,"test_oval"); detached(e)
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

originalPrint("Session logged-whisper adapter: explicit actions, scoped identities, paced native acceptance and cleanup verified with mocks")
