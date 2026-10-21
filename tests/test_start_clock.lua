-- Explicit synthetic clocks and packet delivery. These are not client measurements.
local namespace={}
local Protocol=assert(loadfile("addon/AzerothKart/ClockProtocol.lua"))("AzerothKart",namespace)
local Clock=assert(loadfile("addon/AzerothKart/StartClock.lua"))("AzerothKart",namespace)
assert(namespace.StartClock==Clock)
assert(Clock.SEND_INTERVAL_MS==500 and Clock.RETRY_INTERVAL_MS==2000 and Clock.MAX_ATTEMPTS==3)
local CODE="CLK123"
local function fresh(role,now,options)
    options=options or {}
    return assert(Clock.new({role=role,session=CODE,seed=options.seed or 17},now or 100000,Protocol))
end
local function wire(kind,sequence,fields)
    local packet={kind=kind,session=CODE,sequence=sequence}
    for key,value in pairs(fields or {}) do packet[key]=value end
    return assert(Protocol.encode(packet))
end
local function view(state) return Clock.view(state) end
local function closed(state,reason)
    assert(view(state).phase=="closed","expected closed, got "..tostring(view(state).phase))
    if reason then assert(view(state).reason==reason,"reason "..tostring(view(state).reason)) end
    assert(not view(state).hasPendingOutput)
end
local function pair(config)
    config=config or {}
    local p={now=100000,offset=config.offset or 5000,packets={},history={},config=config}
    p.host=fresh("host",p.now)
    p.guest=fresh("guest",p.now+p.offset)
    function p:localTime(role) return self.now+(role=="guest" and self.offset or 0) end
    function p:send(from)
        return function(payload)
            local message=assert(Protocol.decode(payload))
            local packet={from=from,to=from=="host" and "guest" or "host",payload=payload,
                message=message,sent=self.now}
            self.history[#self.history+1]=packet
            if self.config.outcome then
                local result=self.config.outcome(packet)
                if result and result~="accepted" then return result end
            end
            if not self.config.drop or not self.config.drop(packet) then
                local delay=self.config.delay and self.config.delay(packet)
                    or (from=="host" and 100 or 600)
                packet.at=self.now+delay
                self.packets[#self.packets+1]=packet
                if self.config.duplicate and self.config.duplicate(packet) then
                    self.packets[#self.packets+1]={from=from,to=packet.to,payload=payload,
                        message=message,sent=self.now,at=packet.at+50}
                end
            end
            return "accepted"
        end
    end
    function p:flush()
        local waiting={}
        table.sort(self.packets,function(a,b) return a.at<b.at end)
        for _,packet in ipairs(self.packets) do
            if packet.at<=self.now then
                Clock.receive(self[packet.to],self:localTime(packet.to),packet.payload)
            else waiting[#waiting+1]=packet end
        end
        self.packets=waiting
    end
    function p:step(amount)
        self.now=self.now+(amount or 50)
        self:flush()
        for _,role in ipairs({"host","guest"}) do
            local allowed=not self.config.budget or self.config.budget(role,self.now)
            local before=#self.history
            Clock.update(self[role],self:localTime(role),self:send(role),allowed)
            assert(#self.history-before<=1,"at most one attempted send per update")
        end
        self:flush()
    end
    function p:pumpUntil(predicate,steps)
        for _=1,steps or 600 do if predicate(self) then return true end; self:step() end
        return predicate(self)
    end
    function p:armed()
        return self:pumpUntil(function(q)
            return view(q.host).phase=="armed" and view(q.guest).phase=="armed"
        end)
    end
    return p
end
local function pacing(p)
    local last={}
    for _,packet in ipairs(p.history) do
        if last[packet.from] then assert(packet.sent-last[packet.from]>=500,"local send pacing") end
        last[packet.from]=packet.sent
        assert(#packet.payload<=Protocol.MAX_BYTES)
    end
end

-- Invalid clocks/options refuse before queuing any message; timestamp width never wraps.
do
    local options={role="host",session=CODE,seed=17}
    for _,now in ipairs({-1,0/0,math.huge,1.5,Protocol.MAX_TIME-29999}) do
        assert(Clock.new(options,now,Protocol)==nil)
    end
    for _,value in ipairs({"hostile",false,42}) do
        assert(Clock.new({role=value,session=CODE,seed=17},100000,Protocol)==nil)
    end
    assert(Clock.new({role="host",session="abcdef",seed=17},100000,Protocol)==nil)
    assert(Clock.new({role="host",session=CODE,seed=-1},100000,Protocol)==nil)
    local host=fresh("host")
    assert(not Clock.update(host,100000,function() error("must not call") end,"yes"))
    assert(view(host).stats.sendAttempts==0)
    assert(not Clock.update(host,100000,function() error("budget wait") end,false))
    assert(view(host).pendingAttempts==0)
    Clock.update(host,99999,function() error("backward") end)
    closed(host,"clock_error")
    local guest=fresh("guest")
    assert(not Clock.receive(guest,100000,"invalid"))
    local unrelated=assert(Protocol.encode({kind="PING",session="OTHER1",sequence=1,sample=1,t1=100000}))
    assert(not Clock.receive(guest,100000,unrelated))
    assert(view(guest).stats.received==0)
    Clock.update(guest,130000,function() error("deadline") end,false)
    closed(guest,"timeout")
end

-- Three real four-timestamp exchanges under a deliberately asymmetric 700 ms path.
-- The interval contains the injected clock offset; its midpoint is not claimed exact.
do
    local p=pair()
    assert(p:armed(),"coordinator should arm under bounded synthetic delay")
    local h,g=view(p.host),view(p.guest)
    assert(h.samples==3 and g.samples==3 and #h.sampleDetails==3)
    assert(h.rttMS==700 and h.offsetLowMS<=p.offset and h.offsetHighMS>=p.offset)
    assert(h.offsetLowMS==4398 and h.offsetHighMS==5102 and h.uncertaintyMS==352)
    assert(h.peerAcknowledged==true and g.peerAcknowledged==false)
    assert(g.localEpochMS==g.hostEpochMS+math.floor((g.offsetLowMS+g.offsetHighMS)/2))
    assert(g.hostEpochMS==h.hostEpochMS)
    assert(Clock.takeTicket(p.host,p:localTime("host"))==nil)
    local syntheticSkew=math.abs((g.localEpochMS-p.offset)-h.localEpochMS)
    assert(syntheticSkew<=g.uncertaintyMS,"bounded estimate, no one-way symmetry assumption")
    local hostEpoch=h.localEpochMS
    local guestEpoch=g.localEpochMS
    local guestTicket=assert(Clock.takeTicket(p.guest,guestEpoch))
    local hostTicket=assert(Clock.takeTicket(p.host,hostEpoch))
    assert(hostTicket.seed==17 and guestTicket.seed==17)
    assert(hostTicket.peerAcknowledged and not guestTicket.peerAcknowledged)
    assert(view(p.host).phase=="launched" and view(p.guest).phase=="launched")
    assert(Clock.takeTicket(p.host,hostEpoch)==nil)
    hostTicket.seed=999
    assert(Clock.takeTicket(p.host,hostEpoch)==nil,"copy cannot rearm")
    h.sampleDetails[1].rttMS=9
    h.stats.sendsAccepted=999
    assert(view(p.host).sampleDetails[1].rttMS==700 and view(p.host).stats.sendsAccepted~=999)
    pacing(p)
end

-- Paced guest queue time is subtracted from RTT, rather than mistaken for link delay.
do
    local p=pair({budget=function(role,now)
        return role=="host" or now%1000==0
    end})
    assert(p:armed())
    for _,sample in ipairs(view(p.host).sampleDetails) do
        assert(sample.t3MS-sample.t2MS>0)
        assert(sample.rttMS==700,"subtract guest processing/queue duration")
    end
    pacing(p)
end

-- Loss, delayed duplicates and reordered old packets neither reapply phases nor rearm.
do
    local dropped={}
    local p=pair({drop=function(packet)
        local key=packet.from..packet.message.kind
        if packet.message.kind=="PREPARE"
            or (packet.message.kind=="ACK" and packet.message.ackKind=="COMMIT") then
            if not dropped[key] then dropped[key]=true; return true end
        end
    end,duplicate=function(packet) return packet.message.kind=="PING" or packet.message.kind=="PREPARE" end})
    assert(p:armed(),"bounded retry recovers lost clock/control packets")
    assert(view(p.host).samples==3 and view(p.guest).samples==3)
    assert(view(p.guest).stats.duplicates>0 and view(p.host).stats.retries>0)
    local lastPing
    for _,packet in ipairs(p.history) do
        if packet.message.kind=="PING" then
            if lastPing and lastPing.message.sequence==packet.message.sequence then
                assert(lastPing.payload==packet.payload,"retries retain original t1")
            end
            lastPing=packet
        end
    end
    local h=view(p.host)
    local ticket=assert(Clock.takeTicket(p.host,h.localEpochMS))
    assert(ticket.session==CODE and Clock.takeTicket(p.host,h.localEpochMS)==nil)
    pacing(p)
end

-- Native callback failure cannot confirm a reentrant synthetic peer response.
do
    for _,outcome in ipairs({"failed","throttled","unknown"}) do
        local host=fresh("host")
        local attempts=0
        Clock.update(host,100000,function(payload)
            attempts=attempts+1
            local ping=assert(Protocol.decode(payload))
            local nested,why=Clock.update(host,100001,function() error("nested send") end)
            assert(nested==false and why=="send_in_progress")
            assert(Clock.receive(host,100000,wire("PONG",1,
                {sample=ping.sample,t1=ping.t1,t2=105000,t3=105000})))
            return outcome
        end)
        closed(host,"send_"..outcome)
        assert(attempts==1 and view(host).samples==0)
    end
    local host=fresh("host")
    Clock.update(host,100000,function(payload)
        local ping=assert(Protocol.decode(payload))
        assert(Clock.receive(host,100000,wire("PONG",1,
            {sample=ping.sample,t1=ping.t1,t2=105000,t3=105000})))
        return "accepted"
    end)
    assert(view(host).samples==1 and view(host).pendingKind=="PING")
    local stopped=fresh("host")
    Clock.update(stopped,100000,function()
        assert(Clock.cancel(stopped,100000,"left"))
        return "accepted"
    end)
    closed(stopped,"left")
    assert(Clock.takeTicket(stopped,100000)==nil)
end

-- A forged pre-send reply cannot shadow a later legitimate PONG or ACK.
do
    local host=fresh("host")
    assert(not Clock.receive(host,100000,wire("PONG",1,
        {sample=1,t1=100000,t2=105000,t3=105000})))
    assert(view(host).samples==0)
    assert(Clock.update(host,100000,function() return "accepted" end))
    assert(Clock.receive(host,100000,wire("PONG",1,
        {sample=1,t1=100000,t2=105000,t3=105000})))
    assert(view(host).samples==1)
    assert(not Clock.receive(host,100000,wire("ACK",2,{ackKind="PREPARE",ackSequence=2})))
    assert(view(host).phase=="calibrating")
end

-- Negative/over-limit corrected RTT and disjoint interval samples stop the launch.
do
    local host=fresh("host")
    Clock.update(host,100000,function() return "accepted" end)
    Clock.receive(host,100100,wire("PONG",1,{sample=1,t1=100000,t2=105000,t3=105200}))
    closed(host,"clock_error")
    host=fresh("host")
    Clock.update(host,100000,function() return "accepted" end)
    Clock.receive(host,102001,wire("PONG",1,{sample=1,t1=100000,t2=105000,t3=105000}))
    closed(host,"clock_error")
    host=fresh("host")
    local payload
    Clock.update(host,100000,function(value) payload=value; return "accepted" end)
    Clock.receive(host,100100,wire("PONG",1,{sample=1,t1=100000,t2=105050,t3=105050}))
    assert(view(host).samples==1)
    Clock.update(host,100500,function(value) payload=value; return "accepted" end)
    local ping=assert(Protocol.decode(payload))
    Clock.receive(host,100600,wire("PONG",2,{sample=2,t1=ping.t1,t2=106550,t3=106550}))
    closed(host,"contradiction")
end

-- Reused sequence with changed contents fails closed; duplicate input is bounded.
do
    local guest=fresh("guest")
    local ping=wire("PING",1,{sample=1,t1=95000})
    assert(Clock.receive(guest,100000,ping))
    assert(not Clock.receive(guest,100000,wire("PING",1,{sample=1,t1=95001})))
    closed(guest,"conflicting_sequence")
    guest=fresh("guest")
    assert(Clock.receive(guest,100000,ping))
    for _=2,Clock.MAX_EVENTS do assert(Clock.receive(guest,100000,ping)) end
    assert(not Clock.receive(guest,100000,ping))
    closed(guest,"event_limit")
end

-- PREPARE must advertise an interval consistent with every observed guest upper bound.
-- Merely overlapping the bound is insufficient: its impossible midpoint would move GO.
do
    local p=pair({offset=0,drop=function(packet) return packet.message.kind=="PREPARE" end})
    assert(p:pumpUntil(function(q) return view(q.host).phase=="preparing" end))
    assert(view(p.guest).phase=="calibrating" and view(p.guest).samples==3)
    local prepare
    for _,packet in ipairs(p.history) do
        if packet.message.kind=="PREPARE" then prepare=packet.message end
    end
    assert(prepare)
    assert(not Clock.receive(p.guest,p:localTime("guest"),wire("PREPARE",prepare.sequence,
        {epoch=prepare.epoch,low=0,high=2000})))
    closed(p.guest,"contradiction")
end

-- Cached timestamp retries are deliberately conservative: sample loss does not
-- invent a new t1 or hide a long corrected RTT behind an optimistic estimate.
do
    local first=true
    local p=pair({drop=function(packet)
        if packet.message.kind=="PING" and first then first=false; return true end
    end})
    assert(p:pumpUntil(function(q) return view(q.host).phase=="closed" end))
    closed(p.host,"clock_error")
    assert(view(p.host).samples==0)
    local before,after
    for _,packet in ipairs(p.history) do
        if packet.message.kind=="PING" then
            if not before then before=packet else after=packet; break end
        end
    end
    assert(before and after and before.payload==after.payload)
    assert(after.sent-before.sent==2000)
end

-- Guest launch is withheld until its native COMMIT ACK is accepted; failure or
-- callback cancellation drops the ticket even if the packet was seen remotely.
do
    local p=pair({outcome=function(packet)
        if packet.message.kind=="ACK" and packet.message.ackKind=="COMMIT" then return "failed" end
    end})
    assert(p:pumpUntil(function(q) return view(q.guest).phase=="closed" end))
    closed(p.guest,"send_failed")
    assert(Clock.takeTicket(p.guest,p:localTime("guest"))==nil)
    local host=fresh("host")
    Clock.update(host,100000,function(payload)
        local ping=assert(Protocol.decode(payload))
        local pong=wire("PONG",1,{sample=ping.sample,t1=ping.t1,t2=105000,t3=105000})
        for _=1,Clock.MAX_QUEUE do assert(Clock.receive(host,100000,pong)) end
        assert(not Clock.receive(host,100000,pong))
        return "accepted"
    end)
    closed(host,"queue_limit")
    assert(view(host).samples==0)
end

-- Missing final ACK permits guest-only arming: this protocol never promises atomic GO.
do
    local p=pair({drop=function(packet)
        return packet.message.kind=="ACK" and packet.message.ackKind=="COMMIT"
    end})
    assert(p:pumpUntil(function(q) return view(q.guest).phase=="armed" end))
    assert(view(p.host).phase=="committing" and not view(p.host).peerAcknowledged)
    assert(p:pumpUntil(function(q) return view(q.host).phase=="closed" end))
    closed(p.host,"timeout")
    assert(Clock.takeTicket(p.host,p:localTime("host"))==nil)
    local g=view(p.guest)
    if g.phase=="armed" then
        local ticket=assert(Clock.takeTicket(p.guest,g.localEpochMS))
        assert(ticket.peerAcknowledged==false,"guest launch does not prove host ACK receipt")
    end
end

-- Budget-starved handshake, >250 ms callback delay and explicit cancellation never launch.
do
    local p=pair({drop=function(packet) return packet.message.kind=="PREPARE" end})
    assert(p:pumpUntil(function(q) return view(q.host).phase=="closed" end))
    assert(Clock.takeTicket(p.host,p:localTime("host"))==nil)
    local good=pair()
    assert(good:armed())
    local h=view(good.host)
    assert(Clock.takeTicket(good.host,h.localEpochMS+251)==nil)
    closed(good.host,"late")
    assert(Clock.cancel(good.guest,good:localTime("guest"),"left"))
    closed(good.guest,"left")
    assert(Clock.takeTicket(good.guest,view(good.guest).localEpochMS)==nil)
    local noDelivery=pair({drop=function() return true end})
    assert(noDelivery:pumpUntil(function(q) return view(q.host).phase=="closed" end))
    closed(noDelivery.host,"timeout")
    assert(view(noDelivery.host).stats.sendAttempts==3)
end

return true
