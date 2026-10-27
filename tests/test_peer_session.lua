-- Pure two-peer controller checks. All packets and clocks stay inside this file.
local namespace = {}
local Protocol = assert(loadfile("addon/AzerothKart/RaceProtocol.lua"))("AzerothKart",namespace)
local Session = assert(loadfile("addon/AzerothKart/PeerSession.lua"))("AzerothKart",namespace)
assert(namespace.PeerSession==Session)
assert(Session.SEND_INTERVAL==0.5 and Session.RETRY_INTERVAL==2 and Session.MAX_ATTEMPTS==3)

local HOST, GUEST, CODE = "Amber Stone", "Birch Vale", "ABC123"
local function options(role,extra)
    local value = {role=role,peer=role=="host" and GUEST or HOST,session=CODE,
        physicsVersion=7,trackVersions={stormwind_city=2,mirage_raceway=1},laps=3}
    for key,item in pairs(extra or {}) do value[key]=item end
    return value
end
local function fresh(role,extra,now)
    return assert(Session.new(options(role,extra),now or 0,Protocol))
end
local function view(state) return Session.view(state) end
local function phase(state,expected)
    assert(view(state).phase==expected,"expected "..expected..", got "..tostring(view(state).phase))
end
local function wire(kind,sequence,extra)
    local message = {kind=kind,sequence=sequence,session=CODE}
    for key,value in pairs(extra or {}) do message[key]=value end
    return assert(Protocol.encode(message))
end
local function deliver(state,now,payload,sender,prefix,channel)
    return Session.receive(state,now,prefix or Protocol.PREFIX,payload,channel or "WHISPER",sender or HOST)
end
local function refused(callback,...)
    local ok,reason = callback(...)
    assert(ok==false and type(reason)=="string","expected fixed refusal")
end
local function closed(state,reason)
    phase(state,"closed")
    if reason then assert(view(state).reason==reason,"unexpected close reason: "..tostring(view(state).reason)) end
    assert(not view(state).canInvite and not view(state).canJoin and not view(state).canStart)
end

-- Every production map can be offered without admitting the retired fixture.
for _,id in ipairs({"mirage_raceway","stormwind_city","ironforge_gp",
    "darnassus_canopy","orgrimmar_canyon","undercity_slime","thunder_bluff_skyway",
    "scarlet_graveyard","scarlet_library","scarlet_armory","scarlet_cathedral"}) do
    local versions={[id]=3}
    local target=id:find("scarlet_",1,true)==1 and 1 or 3
    local targets={[id]=target}
    local host=fresh("host",{trackVersions=versions,trackLaps=targets})
    local guest=fresh("guest",{trackVersions=versions,trackLaps=targets})
    targets[id]=9 -- configuration is captured, not borrowed
    assert(Session.invite(host,0,id))
    assert(Session.update(host,0,function(payload)
        assert(deliver(guest,0,payload))
        return "accepted"
    end))
    assert(view(guest).offer.trackId==id and view(guest).offer.laps==target and view(guest).canJoin)
end
for _,id in ipairs({"mirage_raceway","scarlet_graveyard"}) do
    local target=id=="mirage_raceway" and 3 or 1
    local guest=fresh("guest",{trackVersions={[id]=3},trackLaps={[id]=target}})
    local mismatched=wire("INVITE",1,{physicsVersion=7,trackId=id,trackVersion=3,laps=target==1 and 3 or 1})
    assert(not deliver(guest,0,mismatched) and view(guest).reason=="incompatible"
        and not view(guest).canJoin,"course target must match the captured native catalogue")
end
for _,targets in ipairs({false,{mirage_raceway=0},{mirage_raceway=1.5},
    {mirage_raceway=3},{mirage_raceway=3,stormwind_city=3,test_oval=3}}) do
    assert(not Session.new(options("host",{trackLaps=targets}),0,Protocol),"invalid/incomplete/foreign target catalogue")
end
assert(Session.new(options("host",{trackVersions={test_oval=2}}),0,Protocol)==nil,
    "retired course metadata cannot arm a controller")
do
    local host,guest=fresh("host"),fresh("guest")
    refused(Session.invite,host,0,"test_oval")
    refused(deliver,guest,0,"2IABC123001070023")
    assert(view(host).phase=="idle" and view(guest).phase=="listening"
        and not view(guest).hasPendingOutput,"retired offers never acknowledge or change phase")
end

-- The callback represents native local acceptance, never delivery. Delivery is
-- explicitly queued afterward, so an ACK can be dropped without hiding a send.
local function pair(configuration)
    configuration = configuration or {}
    local p = {host=fresh("host",configuration.host),guest=fresh("guest",configuration.guest),
        now=0,packets={},history={},drop=configuration.drop}
    function p:send(from)
        return function(payload,peer)
            assert(peer==(from=="host" and GUEST or HOST),"complete peer identity preserved")
            local decoded = assert(Protocol.decode(payload))
            local packet = {from=from,to=from=="host" and "guest" or "host",payload=payload,
                message=decoded,time=self.now}
            self.history[#self.history+1]=packet
            if not self.drop or not self.drop(packet) then self.packets[#self.packets+1]=packet end
            return "accepted"
        end
    end
    function p:flush()
        local packets = self.packets
        self.packets={}
        for _,packet in ipairs(packets) do
            Session.receive(self[packet.to],self.now,Protocol.PREFIX,packet.payload,"WHISPER",
                packet.from=="host" and HOST or GUEST)
        end
    end
    function p:step(amount)
        self.now=self.now+(amount or 0.5)
        for _,role in ipairs({"host","guest"}) do
            local before=#self.history
            Session.update(self[role],self.now,self:send(role))
            assert(#self.history-before<=1,"one callback can attempt at most one packet")
        end
        self:flush()
    end
    function p:pump(count) for _=1,count or 16 do self:step() end end
    function p:lobby(track)
        assert(Session.invite(self.host,self.now,track or "stormwind_city"))
        for _=1,20 do if view(self.guest).canJoin then break end; self:step() end
        phase(self.guest,"invited")
        assert(Session.join(self.guest,self.now))
        for _=1,20 do
            if view(self.host).phase=="lobby" and view(self.guest).phase=="lobby"
                and not view(self.host).pendingKind and not view(self.guest).pendingKind then break end
            self:step()
        end
        phase(self.host,"lobby"); phase(self.guest,"lobby")
    end
    function p:ready()
        assert(Session.setReady(self.host,self.now,true))
        assert(Session.setReady(self.guest,self.now,true))
        for _=1,20 do
            if view(self.host).canStart and not view(self.guest).pendingKind then break end
            self:step()
        end
        assert(view(self.host).canStart,"both explicit readiness declarations must be confirmed")
    end
    return p
end

do
    local host,guest=fresh("host"),fresh("guest")
    phase(host,"idle"); phase(guest,"listening")
    assert(view(host).canInvite and not view(host).canJoin and not view(guest).canInvite)
    refused(Session.join,guest,0)
    refused(Session.start,guest,0,180,42)
    refused(Session.start,host,0,180,42)
    refused(Session.setReady,host,0,true)
    local calls=0
    assert(not Session.update(host,0,function() calls=calls+1 end))
    assert(calls==0,"constructing/idle controller creates no traffic")
    assert(Session.invite(host,0,"stormwind_city"))
    refused(Session.invite,host,0,"mirage_raceway")
    refused(Session.join,host,0)
    refused(Session.setReady,host,0,true)
    assert(Session.takeStartProposal(host)==nil)
end

do
    -- An offer chooses the track and lap count; a guest's local solo selection
    -- and default laps do not override a compatible host offer.
    local p=pair({guest={laps=1,trackVersions={mirage_raceway=1}}})
    p:lobby("mirage_raceway")
    assert(view(p.guest).offer.trackId=="mirage_raceway" and view(p.guest).offer.laps==3)
    refused(Session.start,p.host,p.now,180,42)
    refused(Session.start,p.guest,p.now,180,42)
    p:ready()
    assert(Session.start(p.host,p.now,180,42))
    refused(Session.start,p.host,p.now,180,42)
    phase(p.host,"starting")
    p:pump(4)
    phase(p.host,"starting"); phase(p.guest,"starting")
    local hostStart,guestStart=assert(Session.takeStartProposal(p.host)),assert(Session.takeStartProposal(p.guest))
    for _,proposal in ipairs({hostStart,guestStart}) do
        assert(proposal.session==CODE and proposal.startTick==180 and proposal.seed==42)
    end
    assert(hostStart.peerAcknowledged==true)
    assert(Session.takeStartProposal(p.host)==nil and Session.takeStartProposal(p.guest)==nil)
    hostStart.seed=8; guestStart.startTick=99
    assert(view(p.host).start.seed==42 and view(p.guest).start.startTick==180)
    -- Replayed commands do not create another proposal or restart local state.
    for _,packet in ipairs(p.history) do
        if packet.message.kind~="ACK" then
            Session.receive(p[packet.to],p.now,Protocol.PREFIX,packet.payload,"WHISPER",
                packet.from=="host" and HOST or GUEST)
        end
    end
    assert(Session.takeStartProposal(p.host)==nil and Session.takeStartProposal(p.guest)==nil)
end

do
    local dropped=false
    local p=pair({drop=function(packet)
        if packet.message.kind=="ACK" and packet.message.ackKind=="START" and not dropped then
            dropped=true; return true
        end
        return false
    end})
    p:lobby(); p:ready()
    assert(Session.start(p.host,p.now,180,42))
    p:step()
    assert(Session.takeStartProposal(p.guest).peerAcknowledged==false)
    assert(Session.takeStartProposal(p.host)==nil,"host must wait for its own START ACK")
    p:pump(7)
    assert(dropped and Session.takeStartProposal(p.host).peerAcknowledged==true)
    assert(Session.takeStartProposal(p.guest)==nil,"retried START must not deliver a second proposal")
end

do
    local input=options("host")
    local host=assert(Session.new(input,0,Protocol))
    input.peer="Wrong Person"; input.trackVersions.stormwind_city=99; input.physicsVersion=1
    assert(Session.invite(host,0,"stormwind_city"))
    local before=view(host)
    before.phase="lobby"; before.peer="Changed Person"; before.offer.trackVersion=99
    before.offer.laps=9; before.stats.sendAttempts=999
    assert(view(host).phase~="lobby" and view(host).peer==GUEST)
    assert(view(host).offer.trackVersion==2 and view(host).offer.laps==3)
    assert(view(host).stats.sendAttempts==0,"view counters are copied")
    local sent
    assert(Session.update(host,0,function(payload,peer) sent=payload; assert(peer==GUEST); return "accepted" end))
    assert(Protocol.decode(sent).physicsVersion==7 and Protocol.decode(sent).trackVersion==2)
end

do
    local guest=fresh("guest",{peer="\195\133se Vale"})
    local invite=wire("INVITE",1,{physicsVersion=7,trackId="stormwind_city",trackVersion=2,laps=3})
    deliver(guest,0,invite,"\195\165se Vale")
    phase(guest,"listening")
    assert(deliver(guest,0,invite,"\195\133SE VALE"),"only ASCII letters are case folded")
    phase(guest,"invited")
end

do
    local guest=fresh("guest")
    local invite=wire("INVITE",1,{physicsVersion=7,trackId="stormwind_city",trackVersion=2,laps=3})
    for _,bad in ipairs({
        {payload=invite,sender="Amber"},{payload=invite,sender="Amber Wrong"},
        {payload=invite,sender="Amber Stone-Realm"},{payload=invite,channel="PARTY"},
        {payload=invite,prefix="AZKART1"},{payload=invite:gsub(CODE,"XYZ123",1)},
        {payload="not a control message"},{payload=invite.."0"},
    }) do
        deliver(guest,0,bad.payload,bad.sender,bad.prefix,bad.channel)
        phase(guest,"listening")
    end
    local calls=0
    Session.update(guest,0,function() calls=calls+1; return "accepted" end)
    assert(calls==0,"unscoped/malformed packets must not cause ACK traffic")
    assert(deliver(guest,0,invite,"  AMBER   STONE "))
    phase(guest,"invited")
    assert(Session.update(guest,0,function(payload)
        assert(Protocol.decode(payload).kind=="ACK"); return "accepted"
    end))
end

do
    for _,extra in ipairs({{physicsVersion=8},{trackVersions={stormwind_city=1}},{trackVersions={mirage_raceway=1}}}) do
        local guest=fresh("guest",extra)
        local invite=wire("INVITE",1,{physicsVersion=7,trackId="stormwind_city",trackVersion=2,laps=3})
        refused(deliver,guest,0,invite)
        closed(guest,"incompatible")
        assert(not view(guest).hasPendingOutput)
    end
end

do
    local guest=fresh("guest")
    deliver(guest,0,wire("START",1,{startTick=180,seed=42}))
    deliver(guest,0,wire("READY",2,{ready=true}))
    phase(guest,"listening")
    assert(Session.takeStartProposal(guest)==nil and not view(guest).hasPendingOutput)
    local p=pair(); p:lobby()
    assert(Session.receive(p.host,p.now,Protocol.PREFIX,wire("READY",100,{ready=true}),"WHISPER",GUEST))
    assert(view(p.host).peerReady)
    Session.receive(p.host,p.now,Protocol.PREFIX,wire("READY",99,{ready=false}),"WHISPER",GUEST)
    assert(view(p.host).peerReady,"older unseen readiness cannot undo newer readiness")
    Session.receive(p.host,p.now,Protocol.PREFIX,wire("READY",100,{ready=true}),"WHISPER",GUEST)
    assert(view(p.host).peerReady)
    Session.receive(p.host,p.now,Protocol.PREFIX,wire("READY",100,{ready=false}),"WHISPER",GUEST)
    closed(p.host)
end

do
    -- ACKs and commands share a wire sequence space, but reordered ACK numbers
    -- must not make a causal command look older than the last command.
    local host=fresh("host")
    assert(Session.invite(host,0,"stormwind_city"))
    assert(Session.update(host,0,function() return "accepted" end))
    assert(deliver(host,0,wire("ACK",100,{ackKind="INVITE",ackSequence=1}),GUEST))
    assert(deliver(host,0,wire("JOIN",2),GUEST))
    phase(host,"lobby")

    -- A host START cannot confirm a READY that has only been queued locally.
    -- Once the READY has native acceptance, START is a causal confirmation
    -- when the separate READY ACK was delayed or lost.
    local p=pair(); p:lobby()
    local guest=p.guest
    assert(Session.setReady(guest,p.now,true))
    assert(deliver(guest,p.now,wire("READY",100,{ready=true})))
    refused(deliver,guest,p.now,wire("START",101,{startTick=180,seed=42}))
    assert(Session.takeStartProposal(guest)==nil and not view(guest).localReadyConfirmed)
    assert(Session.update(guest,p.now+0.5,function() return "accepted" end)) -- queued ACK first
    assert(Session.update(guest,p.now+1,function() return "accepted" end)) -- local READY
    assert(deliver(guest,p.now+1,wire("START",102,{startTick=180,seed=42})))
    assert(view(guest).localReadyConfirmed)
    assert(Session.takeStartProposal(guest).seed==42)
end

do
    local droppedInvite,droppedACK=false,false
    local p=pair({drop=function(packet)
        if packet.message.kind=="INVITE" and not droppedInvite then droppedInvite=true; return true end
        if packet.message.kind=="ACK" and packet.message.ackKind=="INVITE" and not droppedACK then
            droppedACK=true; return true
        end
        return false
    end})
    p:lobby(); p:ready()
    assert(droppedInvite and droppedACK)
    local last={}
    for _,packet in ipairs(p.history) do
        if last[packet.from] then assert(packet.time-last[packet.from]>=0.5,"ACK/control/retry share pacing") end
        last[packet.from]=packet.time
    end
end

do
    local host=fresh("host")
    assert(Session.invite(host,0,"stormwind_city"))
    local attempts=0
    for _,now in ipairs({0,0.1,0.5,1,2,2.5,4,4.5,6,10,30}) do
        Session.update(host,now,function() attempts=attempts+1; return "accepted" end)
    end
    assert(attempts==Session.MAX_ATTEMPTS,"retries are bounded")
    closed(host,"ack_timeout")
    refused(Session.invite,host,30,"stormwind_city")
    assert(not view(host).hasPendingOutput,"timeout leaves no hidden retry/restart")
end

do
    for _,outcome in ipairs({"failed","unknown","throttled",false}) do
        local host=fresh("host"); assert(Session.invite(host,0,"stormwind_city"))
        assert(Session.update(host,0,function() return outcome end))
        closed(host)
        assert(not view(host).hasPendingOutput)
    end
    local host=fresh("host"); assert(Session.invite(host,0,"stormwind_city"))
    assert(Session.update(host,0,function() error("fake native error") end))
    closed(host)
end

do
    -- An ACK for a queued command is not proof a native send ever happened.
    local host=fresh("host"); assert(Session.invite(host,0,"stormwind_city"))
    deliver(host,0,wire("ACK",10,{ackKind="INVITE",ackSequence=1}),GUEST)
    assert(view(host).pendingKind=="INVITE" and view(host).pendingAttempts==0)
    for _,outcome in ipairs({"accepted","failed"}) do
        local current=fresh("host"); assert(Session.invite(current,0,"stormwind_city"))
        assert(Session.update(current,0,function(payload)
            local command=assert(Protocol.decode(payload))
            deliver(current,0,wire("ACK",10,{ackKind="INVITE",ackSequence=command.sequence}),GUEST)
            assert(view(current).pendingKind=="INVITE","reentrant ACK waits for native outcome")
            return outcome
        end))
        if outcome=="accepted" then
            assert(view(current).pendingKind==nil)
        else closed(current) end
    end
end

do
    local host=fresh("host"); assert(Session.invite(host,0,"stormwind_city"))
    local calls=0
    local function accepted() calls=calls+1; return "accepted" end
    assert(Session.update(host,0,accepted))
    assert(not Session.update(host,0.1,accepted))
    assert(Session.update(host,5,accepted))
    assert(calls==2,"a hitch emits one retry, never a catch-up burst")
    assert(not Session.update(host,5.1,accepted))
    for _,bad in ipairs({-1,0/0,math.huge,-math.huge,"1",false}) do
        local current=fresh("host")
        Session.update(current,bad,accepted)
        closed(current,"clock_error")
    end
    local current=fresh("host",nil,10)
    Session.update(current,9,accepted)
    closed(current,"clock_error")
    for _,entry in ipairs({{value=false},{value="bad"},{value=0/0},{value=-1},{}}) do
        local sent=fresh("host")
        assert(Session.invite(sent,0,"stormwind_city"))
        assert(Session.update(sent,0,accepted))
        local ok=pcall(Session.update,sent,entry.value,function() error("invalid clock sent a packet") end)
        assert(ok,"invalid times after an actual send must close without arithmetic errors")
        closed(sent,"clock_error")
    end
    local reentrant=fresh("host")
    assert(Session.invite(reentrant,0,"stormwind_city"))
    local sends=0
    assert(Session.update(reentrant,0,function()
        sends=sends+1
        local sent,reason=Session.update(reentrant,2,function() sends=sends+1; return "accepted" end)
        assert(sent==false and reason=="send_in_progress")
        sent,reason=Session.update(reentrant,30,function() sends=sends+1; return "accepted" end)
        assert(sent==false and reason=="send_in_progress")
        return "accepted"
    end))
    assert(sends==1,"nested callbacks cannot bypass shared pacing or create a second send")
    assert(not Session.update(reentrant,0.5,accepted))
    phase(reentrant,"inviting")
    assert(view(reentrant).reason==nil,"refused nested update must not change clocks or deadlines")
end

do
    local guest=fresh("guest")
    local invite=wire("INVITE",1,{physicsVersion=7,trackId="stormwind_city",trackVersion=2,laps=3})
    assert(deliver(guest,1,invite))
    local deadline=view(guest).deadline
    assert(deliver(guest,2,invite))
    assert(view(guest).deadline==deadline,"duplicates cannot prolong user-decision deadlines")
    Session.update(guest,deadline+0.1,function() return "accepted" end)
    closed(guest)
    local p=pair(); p:lobby()
    for sequence=100,100+Session.MAX_ACK_QUEUE do
        Session.receive(p.host,p.now,Protocol.PREFIX,wire("READY",sequence,{ready=sequence%2==0}),"WHISPER",GUEST)
    end
    closed(p.host)
end

do
    local p=pair(); p:lobby()
    assert(Session.cancel(p.host,p.now,"left",true))
    closed(p.host,"left")
    p:pump(6)
    closed(p.guest,"peer_left")
    local cancels=0
    for _,packet in ipairs(p.history) do if packet.from=="host" and packet.message.kind=="CANCEL" then cancels=cancels+1 end end
    assert(cancels==1,"local cancellation is one bounded best-effort notification")
    assert(Session.takeStartProposal(p.host)==nil and Session.takeStartProposal(p.guest)==nil)
    assert(not view(p.host).hasPendingOutput and not view(p.guest).hasPendingOutput)
end

do
    local host=fresh("host")
    assert(Session.invite(host,0,"stormwind_city"))
    local calls=0
    local function send() calls=calls+1; return "accepted" end
    assert(not Session.update(host,0,send,false) and not Session.update(host,1,send,false))
    assert(calls==0 and view(host).pendingAttempts==0,"budget waits do not consume send/retry attempts")
    assert(Session.update(host,1,send,true) and calls==1)
    refused(Session.update,host,1,send,"allowed")
    local guest=fresh("guest")
    assert(not Session.update(guest,30,send,false))
    closed(guest,"timeout")
    assert(calls==1,"budget waits must still expire sessions without sending")
end

do
    local p=pair(); p:lobby(); p:ready()
    assert(Session.start(p.host,p.now,180,42))
    assert(Session.handoffStart(p.host,p.now)==nil,"host cannot hand off an unacknowledged START")
    p:pump(3)
    for _,role in ipairs({"host","guest"}) do
        local state=p[role]
        local proposal=assert(Session.handoffStart(state,p.now))
        assert(proposal.seed==42 and proposal.startTick==180)
        assert(view(state).phase=="coordinating" and view(state).deadline==p.now+30)
        assert(not view(state).canStart and not view(state).canSetReady)
        assert(Session.handoffStart(state,p.now)==nil and Session.takeStartProposal(state)==nil,
            "coordinator ownership consumes the proposal once")
        Session.update(state,p.now+11,function() error("deadline check must not send") end,false)
        phase(state,"coordinating")
        Session.update(state,p.now+30,function() error("expired controller must not send") end,false)
        closed(state,"timeout")
    end
end

-- A post-race room is bounded and never carries readiness into another race.
do
    local p=pair();p:lobby();p:ready()
    assert(Session.start(p.host,p.now,180,42));p:pump(3)
    for _,role in ipairs({"host","guest"}) do
        local state=p[role]
        assert(Session.handoffStart(state,p.now));assert(Session.beginRace(state,p.now))
        assert(Session.enterPostRace(state,p.now))
        local v=view(state)
        assert(v.phase=="postrace" and v.deadline==p.now+300 and not v.localReady and not v.peerReady
            and not v.localReadyConfirmed and not v.canStart and not v.canSetReady and v.canLeave)
        assert(not Session.enterPostRace(state,p.now) and not Session.setReady(state,p.now,true))
        Session.update(state,p.now+299,function() error("idle postrace cannot send") end,false)
        phase(state,"postrace")
        Session.update(state,p.now+300,function() error("expired postrace cannot send") end,false)
        closed(state,"timeout")
    end
    assert(Session.nextSession("ABC123")=="ABC124" and Session.nextSession("00000Z")=="000010")
    local code,why=Session.nextSession("ZZZZZZ")
    assert(code==nil and why=="next_session_limit","round ids never wrap onto an earlier session")
    for _,bad in ipairs({"bad","abc123","ABC12!",false,{},123}) do assert(Session.nextSession(bad)==nil) end
end

print("Pure peer sessions: explicit handshake/readiness, scoped compatibility, bounded delivery and terminal cleanup verified offline")
