local P=dofile("addon/AzerothKart/NetworkProbe.lua")
local function options(mode,rate,bytes,duration,session)
    return {mode=mode or "send",peer="Tester-Realm",session=session or "ABC123",
        rate=rate or 1,bytes=bytes or 64,duration=duration or 10}
end
local function fresh(mode,rate,bytes,duration,session)
    return assert(P.new(options(mode,rate,bytes,duration,session),0))
end
local function accepted() return "accepted",0 end
local function packet(kind,seq,bytes,session)
    return assert(P.encode(kind,session or "ABC123",seq,bytes or (kind=="A" and 16 or 64)))
end
local function receive(s,time,payload,sender,channel)
    return P.receive(s,time,P.PREFIX,payload,channel or "WHISPER",sender or "Tester-Realm",accepted)
end
local function near(a,b) assert(math.abs(a-b)<1e-7,tostring(a).." ~= "..tostring(b)) end

for _,bytes in ipairs({16,64,128,220}) do
    for _,seq in ipairs({1,35,36,479,480}) do
        local text=packet("D",seq,bytes)
        local decoded=assert(P.decode(text,bytes))
        assert(#text==bytes and decoded.kind=="D" and decoded.sequence==seq and decoded.session=="ABC123")
        assert(#packet("A",seq)==16)
    end
end
assert(packet("D",480,16):sub(9,10)=="DC","two base36 digits cover the maximum window")
for _,text in ipairs({"",string.rep(".",255),"2DABC12301......","1XABC12301......",
    "1Dabc12301......","1DABC12300......","1DABC123DD......","1DABC1230?......",
    "1DABC12301.....!","1AABC12301"..string.rep(".",54)}) do
    assert(not P.decode(text),"malformed codec input accepted")
end
assert(not P.decode(packet("D",1,64),16) and P.decode(packet("A",1),220))
assert(not P.encode("D","ABC123",481,16) and not P.encode("A","ABC123",1,64))

local config=options()
local frozen=assert(P.new(config,0))
config.peer,config.rate="SomeoneElse-Realm",4
assert(frozen.options.peer=="Tester-Realm" and frozen.options.rate==1,"copy experiment configuration")
for _,field in ipairs({"mode","peer","session","rate","bytes","duration"}) do
    local bad=options()
    bad[field]=({mode="race",peer="Tester",session="abc123",rate=8,bytes=255,duration=121})[field]
    assert(not P.new(bad,0),"reject invalid option "..field)
end
assert(not P.new(options(),0/0) and not P.new(options(),math.huge) and not P.new(options(),-1))
assert(not P.new(options("send",1,16,10.5),0))
local defaults=assert(P.new({mode="listen",peer="Tester-Realm",session="ABC123"},0))
assert(defaults.options.rate==0.5 and defaults.options.bytes==16 and defaults.options.duration==120)

-- Full 4/s window: no first-frame burst; final slot at 120s; synchronous ACK is safe.
local full=fresh("send",4,220,120)
local now,calls=0,0
local function echo(kind,payload)
    calls=calls+1
    local decoded=assert(P.decode(payload))
    assert(kind=="D" and #payload==220)
    assert(receive(full,now,packet("A",decoded.sequence)))
    return "accepted",0
end
P.update(full,0,echo)
assert(calls==0)
for i=1,480 do now=i/4; P.update(full,now,echo) end
assert(calls==480 and full.phase=="draining" and full.data_attempts==480)
assert(full.ack_matched_unique==480 and full.missed_slots==0)
assert(P.evidence(full,"sent")==string.rep("1",480))
assert(P.evidence(full,"acks_received")==string.rep("1",480))
local fullSummary=P.summary(full)
assert(fullSummary.scheduled_data_attempts==480 and fullSummary.aggregate_attempted_bytes==480*220)
assert(fullSummary.rtt_samples==480 and fullSummary.rtt_p99_ms==0)
P.update(full,130,echo)
assert(full.phase=="stopped" and P.summary(full).outstanding_after_drain==0)
assert(P.summary(full).elapsed_seconds==130,"elapsed snapshot includes the bounded drain")
P.update(full,140,echo)
assert(P.summary(full).elapsed_seconds==130,"stopped elapsed time is frozen")
assert(calls==480,"terminal experiment never sends again")
local capped=fresh("send",4,16,120)
local code=0
local function varied(kind,payload)
    code=code+1
    receive(capped,now,packet("A",assert(P.decode(payload)).sequence))
    return "accepted",code
end
for i=1,480 do now=i/4; P.update(capped,now,varied) end
local keys,total=0,0
for _,count in pairs(capped.data_codes) do keys=keys+1; total=total+count end
assert(keys<=32 and total==480 and capped.data_codes.other,"raw return-code map has a fixed key cap")

local hitch=fresh("send",4)
P.update(hitch,0.25,accepted)
P.update(hitch,2,accepted)
P.update(hitch,2,accepted)
assert(hitch.data_attempts==2 and hitch.missed_slots==6 and hitch.last_slot==8)
assert(P.evidence(hitch,"sent"):sub(1,8)=="1......1","skip missed slots without a backlog")
local afterWindow=fresh("send",4)
P.update(afterWindow,10.01,accepted)
assert(afterWindow.data_attempts==0 and afterWindow.missed_slots==40 and afterWindow.phase=="draining")
assert(afterWindow.drain_until==20,"normal drain uses scheduled window end, not callback time")
local pastDeadline=fresh("send",1,64,120)
P.update(pastDeadline,1,accepted); P.update(pastDeadline,2,accepted)
P.update(pastDeadline,100,accepted)
assert(pastDeadline.phase=="stopped" and pastDeadline.reason=="ack_deadline")
assert(pastDeadline.drain_until==16 and pastDeadline.data_attempts==2)
assert(pastDeadline.ack_timeouts_at_deadline==2,"count every observed expiry, regardless of map iteration order")
assert(not receive(pastDeadline,101,packet("A",1)) and pastDeadline.ack_matched_unique==0
    and pastDeadline.rx_total==0,"hitch cannot reopen an expired ACK drain")
local pastWindow=fresh("send",4)
P.update(pastWindow,100,accepted)
assert(pastWindow.phase=="stopped" and pastWindow.reason=="window_complete"
    and pastWindow.drain_until==20 and pastWindow.missed_slots==40 and pastWindow.data_attempts==0)
local receiveOnly=fresh("send",1,64,10)
P.update(receiveOnly,9,accepted)
assert(not receive(receiveOnly,21,packet("A",9)),"receive must enforce normal expiry without an update")
assert(receiveOnly.phase=="stopped" and receiveOnly.reason=="window_complete"
    and receiveOnly.drain_until==20 and receiveOnly.ack_timeouts_at_deadline==1
    and receiveOnly.ack_matched_unique==0 and receiveOnly.rx_total==0)

-- Unknown/failed/throttle/throw abort on first call; no retry and no raw error leakage.
for _,case in ipairs({
    {"accepted",nil,"nil","1"},{"accepted",false,"boolean:false","1"},
    {"accepted",true,"boolean:true","1"},{"accepted",42,"number:42","1"},
    {"failed",7,"number:7","f"},{"unknown",nil,"nil","u"},
    {"throttled",3,"number:3","f"},{"garbage","sensitive text","string","u"},
}) do
    local s=fresh()
    P.update(s,1,function() return case[1],case[2] end)
    assert(s.data_codes[case[3]]==1 and P.evidence(s,"sent"):sub(1,1)==case[4])
    if case[1]~="accepted" then
        assert(s.phase=="stopped")
        P.update(s,2,function() error("must not retry") end)
        assert(s.data_attempts==1)
    end
    if case[1]=="throttled" then assert(s.throttle_events==1 and s.reason=="throttled") end
end
local thrown=fresh()
P.update(thrown,1,function() error("do not preserve this secret-like error") end)
assert(thrown.phase=="stopped" and thrown.reason=="send_error" and thrown.send_errors==1)
assert(thrown.data_codes.error==1 and thrown.data_codes["nil"]==nil)

local timeout=fresh()
P.update(timeout,1,accepted)
P.update(timeout,6,accepted)
assert(timeout.phase=="draining" and timeout.data_attempts==1 and timeout.ack_timeouts_at_deadline==1)
assert(receive(timeout,6.25,packet("A",1)))
assert(timeout.late_acks==1 and timeout.ack_matched_unique==1)
assert(receive(timeout,6.5,packet("A",1)))
assert(timeout.duplicates==1 and #timeout.rtts==1)
P.update(timeout,16,accepted)
assert(timeout.phase=="stopped" and timeout.ack_timeouts_at_deadline==1)
assert(P.summary(timeout).outstanding_after_drain==0)
local missing=fresh()
P.update(missing,1,accepted); P.update(missing,6,accepted); P.update(missing,16,accepted)
assert(P.summary(missing).outstanding_after_drain==1,"unmatched ACK is evidence, not a loss classification")
local cancel=fresh()
P.update(cancel,1,accepted)
assert(P.stop(cancel,1.1,"cancelled") and cancel.phase=="stopped")
assert(not receive(cancel,2,packet("A",1)) and cancel.ack_matched_unique==0)
local backwards=fresh()
P.update(backwards,1,accepted); P.update(backwards,0,accepted)
assert(backwards.reason=="invalid_clock" and backwards.phase=="stopped")
local invalid=fresh(); P.update(invalid,math.huge,accepted)
assert(invalid.reason=="invalid_clock" and invalid.data_attempts==0)

local listener=fresh("listen")
assert(not P.receive(listener,0,"OTHER",packet("D",1),"WHISPER","Tester-Realm",accepted))
assert(listener.rx_total==0,"only matching-prefix traffic belongs in this ledger")
assert(not receive(listener,0,packet("D",1),"Imposter-Realm"))
assert(not receive(listener,0,packet("D",1),"Tester"))
assert(not receive(listener,0,packet("D",1),nil,"PARTY"))
assert(not receive(listener,0,packet("D",1,64,"OLD123")))
assert(not receive(listener,0,packet("D",1,16)))
assert(not receive(listener,0,packet("D",11)))
assert(not receive(listener,0,packet("A",1)))
assert(receive(listener,0.1,packet("D",3),"tEsTeR-rEaLm"))
assert(receive(listener,0.2,packet("D",1)))
assert(receive(listener,0.5,packet("D",2)))
assert(receive(listener,0.7,packet("D",2)))
assert(listener.rx_unique==3 and listener.reordered_unique==2 and listener.duplicates==1)
assert(listener.ack_attempts==3 and listener.aggregate_attempted_bytes==48,"one ACK per unique DATA only")
assert(P.evidence(listener,"received")=="111.......")
assert(P.evidence(listener,"acks_sent")=="111.......")
local ls=P.summary(listener)
assert(ls.gap_samples==2); near(ls.gap_p50_ms,100); near(ls.gap_p95_ms,300)
P.update(listener,5.5,accepted)
assert(listener.phase=="stopped" and listener.reason=="listener_idle","duplicates do not keep listener alive")
local armed=fresh("listen"); P.update(armed,30,accepted)
assert(armed.reason=="listen_expired" and armed.ack_attempts==0)
local delayed=fresh("listen")
assert(receive(delayed,29,packet("D",1)))
P.update(delayed,30,accepted)
assert(delayed.phase=="listening","duration starts at first valid DATA, not arm time")
local reconnected=fresh("listen",1,64,10,"NEW123")
assert(not receive(reconnected,0,packet("D",1)) and reconnected.rx_unique==0)
assert(receive(reconnected,0,packet("D",1,64,"NEW123")))
assert(reconnected.rx_unique==1 and reconnected.ack_attempts==1,"fresh explicit session resets sequence space")

local regular=fresh("listen",4,64,120)
for i=1,480 do assert(receive(regular,i/4,packet("D",i))) end
assert(regular.ack_attempts==480 and regular.phase=="listening","normal4/s stream fits ACK guard")
assert(P.evidence(regular,"acks_sent")==string.rep("1",480))
P.update(regular,120.25,accepted)
assert(regular.phase=="draining" and regular.reason=="window_complete")
local burst=fresh("listen",4,64,120)
for i=1,480 do receive(burst,0,packet("D",i)) end
assert(burst.phase=="stopped" and burst.reason=="ack_rate_limit")
assert(burst.rx_unique==5 and burst.ack_attempts==4 and burst.ack_enqueue_accepted==4)
assert(P.evidence(burst,"received"):sub(1,6)=="11111.")
assert(P.evidence(burst,"acks_sent"):sub(1,6)=="1111..","valid flood cannot create an ACK burst")
local draining=fresh("listen",4,64,10)
for i=1,39 do assert(receive(draining,(i-1)/4,packet("D",i))) end
P.update(draining,10,accepted)
assert(draining.phase=="draining")
assert(receive(draining,10.5,packet("D",40)),"normal drain accepts a bounded late DATA and ACKs it")
assert(draining.ack_attempts==40 and P.evidence(draining,"acks_sent")==string.rep("1",40))
P.update(draining,16,accepted)
assert(draining.phase=="draining","explicit normal drain has no listener-idle early abort")
P.update(draining,20,accepted)
assert(draining.phase=="stopped" and draining.reason=="window_complete")
assert(not receive(draining,20.1,packet("D",40)) and draining.ack_attempts==40)
local expired=fresh("listen",4)
assert(receive(expired,0,packet("D",1)))
assert(not receive(expired,5,packet("D",2)) and expired.ack_attempts==1,
    "idle deadline is checked before a late packet can trigger an ACK")

local ackFailure=fresh("listen")
P.receive(ackFailure,0,P.PREFIX,packet("D",1),"WHISPER","Tester-Realm",function() return "unknown",false end)
assert(ackFailure.phase=="stopped" and ackFailure.ack_enqueue_unknown==1 and ackFailure.ack_codes["boolean:false"]==1)
assert(P.evidence(ackFailure,"acks_sent")=="u.........")
local flood=fresh("listen")
for _=1,P.MAX_REJECTED+10 do receive(flood,0,"malformed") end
assert(flood.rx_total==P.MAX_REJECTED and flood.rx_rejected==P.MAX_REJECTED and flood.reason=="rejected_limit")
local duplicates=fresh("listen")
for _=1,P.MAX_EVENTS+10 do receive(duplicates,0,packet("D",1)) end
assert(duplicates.rx_total==P.MAX_EVENTS and duplicates.rx_unique==1 and duplicates.ack_attempts==1)
assert(duplicates.phase=="stopped" and duplicates.reason=="receive_limit")

local ranks=fresh("send",4)
P.update(ranks,0.25,accepted); P.update(ranks,0.5,accepted); P.update(ranks,0.75,accepted)
assert(receive(ranks,1,packet("A",1)))
assert(receive(ranks,1.1,packet("A",2)))
assert(receive(ranks,1.2,packet("A",3)))
local rs=P.summary(ranks)
assert(rs.rtt_samples==3); near(rs.rtt_p50_ms,600); near(rs.rtt_p95_ms,750); near(rs.rtt_p99_ms,750)
local empty=P.summary(fresh())
assert(empty.rtt_samples==0 and empty.rtt_p50_ms=="NA" and empty.rtt_max_ms=="NA")
assert(empty.gap_samples==0 and empty.gap_p99_ms=="NA")
assert(not P.evidence(fresh(),"anything_else"))
print("Bounded pure network probe: exact codec, pacing/deadlines, untrusted traffic, outcomes and evidence verified offline")
