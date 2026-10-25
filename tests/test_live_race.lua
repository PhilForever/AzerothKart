-- Backend tests with real simulation modules and synthetic transport/time only.
local Physics=dofile("addon/AzerothKart/Physics.lua")
local Race=dofile("addon/AzerothKart/Race.lua")
local Checkpoints=dofile("addon/AzerothKart/Checkpoints.lua")
local Laps=dofile("addon/AzerothKart/Laps.lua")
local Loop=dofile("addon/AzerothKart/Loop.lua")
local Start=dofile("addon/AzerothKart/RaceStart.lua")
local Protocol=dofile("addon/AzerothKart/LiveProtocol.lua")
local Live=dofile("addon/AzerothKart/LiveRace.lua")
local Track=dofile("addon/AzerothKart/Track.lua")
local modules={Physics=Physics,Race=Race,Checkpoints=Checkpoints,Laps=Laps,Loop=Loop,LiveProtocol=Protocol}
local function shallow(value) local out={}; for k,v in pairs(value) do out[k]=v end; return out end
local function bundle(role,track,offset,kartId)
    role,track,offset=role or "host",track or Track,offset or 0
    local ticket={session="RACE01",role=role,seed=47,localEpochMS=10000+offset,
        hostEpochMS=10000,offsetLowMS=offset,offsetHighMS=offset,uncertaintyMS=0,
        peerAcknowledged=role=="host"}
    return assert(Start.take(assert(Start.new(ticket,track,Physics.VERSION,kartId)),10000+offset,Physics,Race,Checkpoints,Laps))
end
local function new(track,m)
    return assert(Live.new(bundle("host",track),"Birch Vale",10000,m or modules))
end
local function message(sequence,tick,changes)
    local m={kind="STATE",session="RACE01",sequence=sequence,tick=tick,x=666,y=240,
        headingQ=0,speedQ=0,driftTier=0,boosting=false,completedLaps=0,passed=0,status="running",sampleMS=math.floor(tick*1000/60)}
    for k,v in pairs(changes or {}) do m[k]=v end
    return assert(Protocol.encode(m))
end
local function receive(run,now,seq,tick,changes)
    return Live.receive(run,now,Protocol.PREFIX,message(seq,tick,changes),"WHISPER","Birch Vale")
end
local function same(a,b)
    if type(a)~="table" then assert(a==b); return end
    for k,v in pairs(a) do same(v,b[k]) end
    for k in pairs(b) do assert(a[k]~=nil) end
end

-- The backend owns its captured handling identity; presentation/bundle writes
-- cannot substitute another kart after GO. Compare actual profile-specific
-- motion with the same deterministic Physics steps, not just copied metadata.
local handlingResults={}
for _,id in ipairs({"steam_tank","dwarven_biker"}) do
    local launch=bundle("host",nil,nil,id)
    local expected=launch.vehicle
    local run=assert(Live.new(launch,"Birch Vale",10000,modules))
    launch.kartId=id=="steam_tank" and "dwarven_biker" or "steam_tank"
    local copied=Live.view(run); copied.kartId=launch.kartId
    local input={accelerate=true,left=true}
    for frame=1,20 do
        local count=assert(Live.advance(run,10000+frame*20,input))
        for _=1,count do expected=Physics.step(expected,input,Physics.FIXED_DT,Track,id) end
        same(Live.view(run).vehicle,expected)
    end
    handlingResults[id]=Live.view(run).vehicle
end
assert(handlingResults.steam_tank.speed<handlingResults.dwarven_biker.speed
    and handlingResults.steam_tank.heading<handlingResults.dwarven_biker.heading,
    "live heavy and agile karts use their actual distinct acceleration and turning")
for _,bad in ipairs({false,{},"","unknown_kart","Steam Tank"}) do
    local invalid=bundle(); invalid.kartId=bad
    assert(not Live.new(invalid,"Birch Vale",10000,modules),"invalid bundle kart cannot start a run")
end
local profileReentry=bundle("host",nil,nil,"steam_tank")
local profileModules=shallow(modules); profileModules.Physics=shallow(Physics)
profileModules.Physics.GetHandling=function(id)
    assert(not Live.new(profileReentry,"Birch Vale",10000,modules),"profile validation cannot claim the same bundle twice")
    return Physics.GetHandling(id)
end
assert(Live.new(profileReentry,"Birch Vale",10000,profileModules))

local source=bundle()
local owner=assert(Live.new(source,"Birch Vale",10000,modules))
assert(not Live.new(source,"Birch Vale",10000,modules),"one bundle cannot create duplicate owners")
source.vehicle.x,source.race.laps.completedLaps,source.track.width=0,3,1
owner.phase,owner.vehicle,owner.modules="running",{},{}
local initial=Live.view(owner)
assert(initial.vehicle.x==666 and initial.race.laps.completedLaps==0 and initial.vehicle.tick==0)
initial.vehicle.x,initial.race.laps.completedLaps,initial.clock.accumulator=0,3,100
assert(Live.view(owner).vehicle.x==666 and Live.view(owner).clock.accumulator==0,"copied views cannot write owner")
assert(not Live.new(bundle(),"Birch Vale",9999,modules),"no pre-GO adoption")
assert(not Live.new(bundle(),"Birch Vale",10251,modules),"no late adoption")
assert(Live.new(bundle(),"Birch Vale",10250,modules),"inclusive late limit")
assert(not Live.new(bundle()," \n ",10000,modules),"untrusted identities refused")
assert(not Live.new(bundle(),"Birch Vale",10000,{}),"dependencies checked")
local reentrantBundle=bundle()
local injected=shallow(modules); injected.Loop=shallow(Loop)
injected.Loop.new=function(dt,limit)
    assert(not Live.new(reentrantBundle,"Birch Vale",10000,modules),"initializer cannot claim twice")
    return Loop.new(dt,limit)
end
assert(Live.new(reentrantBundle,"Birch Vale",10000,injected))
local failedBundle=bundle()
injected.Loop.new=function() error("initializer failed") end
assert(not Live.new(failedBundle,"Birch Vale",10000,injected)
    and not Live.new(failedBundle,"Birch Vale",10000,modules),"partial initializer cannot be retried")
for _,badClock in ipairs({false,{}, {dt=1/60,maxSteps=5,accumulator=0}}) do
    local invalid=bundle()
    injected.Loop.new=function() return badClock end
    assert(not Live.new(invalid,"Birch Vale",10000,injected),"malformed clock return refused")
end
injected.Loop.new=function() return nil end
assert(not Live.new(bundle(),"Birch Vale",10000,injected),"nil initializer return refused")
for _,mutate in ipairs({
    function(b) b.race.laps.checkpoints=nil end,
    function(b) b.race.laps.checkpoints.passed=1 end,
    function(b) b.vehicle.x=-1 end,
    function(b) b.vehicle.speed=0/0 end,
    function(b) b.vehicle.driftTier=2 end,
}) do
    local invalid=bundle(); mutate(invalid)
    assert(not Live.new(invalid,"Birch Vale",10000,modules),"mutated non-fresh bundle refused")
end
assert(not Live.advance(owner,10010,{accelerate=1}),"explicit sampled booleans only")
assert(not Live.advance(owner,10010,setmetatable({},{})),"no input metatables")
assert(Live.advance(owner,10010,{accelerate=true})==0)
assert(Live.advance(owner,10020,{accelerate=true})==1)
assert(Live.view(owner).vehicle.tick==1 and Live.view(owner).race.totalTicks==1,"no second countdown")
local adoptLate=assert(Live.new(bundle(),"Birch Vale",10200,modules))
assert(Live.advance(adoptLate,10200,{accelerate=true})==0,"late adoption cannot backfill GO ticks")
assert(Live.advance(adoptLate,11200,{accelerate=true})==5,"hitch catch-up is bounded")
local hitch=Live.view(adoptLate)
assert(hitch.vehicle.tick==5 and hitch.clock.droppedSeconds>0.9)

-- Twenty synthetic seconds, independent clocks 5s apart, 700ms round-trip.
-- No ACK per snapshot; each endpoint stays within the native candidate ceiling.
local a=assert(Live.new(bundle(),"Birch Vale",10000,modules))
local b=assert(Live.new(bundle("guest",nil,5000),"Amber Stone",15000,modules))
local wire,attempts={},{}
local function sender(target,offset,identity,now)
    return function(payload,peer,prefix)
        assert(#payload==40 and #prefix==7 and type(peer)=="string")
        wire[#wire+1]={target=target,at=now+350,offset=offset,sender=identity,prefix=prefix,payload=payload}
        attempts[#attempts+1]={at=now,identity=identity,bytes=#payload+#prefix}
        return "accepted"
    end
end
for ms=0,20000,10 do
    while wire[1] and wire[1].at<=ms do
        local p=table.remove(wire,1)
        assert(Live.receive(p.target,10000+ms+p.offset,p.prefix,p.payload,"WHISPER",p.sender))
    end
    local input={accelerate=ms%2000<1750,left=ms%1500<500,right=ms%1500>=1000,drift=ms%3000<2200}
    assert(Live.advance(a,10000+ms,input))
    assert(Live.advance(b,15000+ms,input))
    Live.update(a,10000+ms,sender(b,5000,"Amber Stone",ms))
    Live.update(b,15000+ms,sender(a,0,"Birch Vale",ms))
end
local av,bv=Live.view(a),Live.view(b)
same(av.vehicle,bv.vehicle); same(av.race,bv.race)
assert(av.vehicle.tick==1200 and av.remote.tick>1100 and av.phase=="running" and bv.phase=="running")
assert(av.counters.accepted==41 and bv.counters.accepted==41 and not av.remoteStale)
for index,attempt in ipairs(attempts) do
    local calls,bytes=0,0
    for previous=1,index do
        local p=attempts[previous]
        if p.identity==attempt.identity and attempt.at-p.at<1000 then calls=calls+1; bytes=bytes+p.bytes end
    end
    assert(calls<=2 and bytes<=158,"bounded synthetic local rolling output")
end
assert(av.resultVerified==false and av.remoteVerified==false and bv.peerAcknowledged==false)
local saved=Live.view(a)
saved.remote.x,saved.remotePrevious.tick=0,0
assert(Live.view(a).remote.x~=0 and Live.view(a).remotePrevious.tick>0,"no remote view aliases")

-- Unauthorized/malformed/stale/out-of-order data never moves local authority.
local scoped=new(); local before=Live.view(scoped)
for _,entry in ipairs({{"WRONG","WHISPER","Birch Vale"},{Protocol.PREFIX,"PARTY","Birch Vale"},
    {Protocol.PREFIX,"WHISPER","Birch"},{Protocol.PREFIX,"WHISPER","Other Vale"}}) do
    assert(not Live.receive(scoped,10010,entry[1],message(1,100),entry[2],entry[3]))
end
assert(receive(scoped,10010,1,100,{completedLaps=2,passed=3}),"telemetry may report unverified progress")
assert(not receive(scoped,10020,1,100) and not receive(scoped,10030,1,100),"duplicates refused")
assert(not receive(scoped,10040,2,99),"backward peer tick refused")
assert(not receive(scoped,10050,2,101,{session="OLD001"}),"old session refused")
assert(not receive(scoped,10060,2,101,{x=801}),"map bounds checked")
assert(not receive(scoped,10070,2,101,{passed=4}),"course gate count checked")
same(before.vehicle,Live.view(scoped).vehicle); same(before.race,Live.view(scoped).race)
assert(Live.view(scoped).race.laps.completedLaps==0,"received progress cannot award local laps")
local duplicate=new()
assert(receive(duplicate,10000,1,1))
assert(not receive(duplicate,14000,1,1))
assert(not Live.advance(duplicate,15000,{}))
assert(Live.view(duplicate).reason=="peer_timeout","replayed packets cannot extend liveness")
local frozen=new()
assert(receive(frozen,10000,1,1))
assert(receive(frozen,14000,2,1))
assert(not receive(frozen,15000,3,1) and Live.view(frozen).reason=="peer_timeout",
    "fresh sequence on frozen running tick cannot extend progress forever")
local silentFrozen=new()
assert(receive(silentFrozen,10000,1,1))
assert(receive(silentFrozen,14999,2,1))
assert(not Live.advance(silentFrozen,15000,{}) and Live.view(silentFrozen).reason=="peer_timeout",
    "progress timeout fires on update without requiring another incoming packet")
local flood=new()
for seq=1,8 do assert(receive(flood,10000,seq,seq)) end
assert(not receive(flood,10000,9,9) and Live.view(flood).reason=="peer_flood","bounded inbound rate")
local stale=new()
assert(receive(stale,10000,1,1))
Live.advance(stale,11600,{})
assert(Live.view(stale).remoteStale and Live.view(stale).remoteAgeMS==1600)

-- Explicit stop and failure freeze exact partial progress with no restart.
for _,reason in ipairs({"stopped","combat","world_leave","logout","focus_lost"}) do
    local run=new(); Live.advance(run,10050,{accelerate=true}); local state=Live.view(run)
    assert(Live.stop(run,10050,reason)); assert(not Live.stop(run,10050,reason))
    assert(not Live.advance(run,10100,{accelerate=true}))
    assert(not Live.update(run,10100,function() error("no post-stop output") end))
    local stopped=Live.view(run)
    same(state.vehicle,stopped.vehicle)
    assert(stopped.reason==reason and stopped.race.status==(reason=="combat" and "interrupted" or "stopped"))
end
local backwards=new(); Live.advance(backwards,10010,{})
assert(not Live.advance(backwards,10009,{}) and Live.view(backwards).reason=="clock")
local duration=new()
assert(not Live.advance(duration,10000+Live.MAX_DURATION_MS,{})
    and Live.view(duration).reason=="duration","finite session lifetime")
local failedModules=shallow(modules); failedModules.Physics=shallow(Physics)
failedModules.Physics.step=function() error("private simulation failure") end
local failure=new(nil,failedModules)
assert(not Live.advance(failure,10020,{accelerate=true}) and Live.view(failure).reason=="simulation"
    and Live.view(failure).vehicle.tick==0,"simulation failure retains prior accepted tick")
local nestedAdvance
local callbackModules=shallow(modules); callbackModules.Physics=shallow(Physics)
callbackModules.Physics.step=function(state,input,dt,track)
    assert(Live.stop(nestedAdvance,10020,"stopped"))
    return Physics.step(state,input,dt,track)
end
nestedAdvance=new(nil,callbackModules)
Live.advance(nestedAdvance,10020,{accelerate=true})
assert(Live.view(nestedAdvance).phase=="closed" and Live.view(nestedAdvance).vehicle.tick==0
    and Live.view(nestedAdvance).race.status=="stopped","simulation callback cannot resurrect stopped state")
for _,outcome in ipairs({"failed","unknown","throttled","throw"}) do
    local run=new()
    assert(not Live.update(run,10000,function() if outcome=="throw" then error("private") end; return outcome end))
    local v=Live.view(run)
    assert(v.phase=="closed" and v.counters.attempted==1 and v.counters.accepted==0)
    assert(not Live.update(run,10500,function() error("cannot retry hard send failure") end))
end
local reentrant=new()
assert(Live.update(reentrant,10000,function()
    assert(not Live.update(reentrant,10000,function() error("nested send") end))
    assert(not Live.advance(reentrant,10000,{}))
    assert(Live.stop(reentrant,10000,"stopped"))
    return "accepted"
end))
assert(Live.view(reentrant).phase=="closed" and Live.view(reentrant).sequence==1,"send completion cannot resurrect stop")
local denied=new(); assert(not Live.update(denied,10000,function() error("external gate") end,false))
assert(Live.view(denied).counters.attempted==0)

-- A controlled one-gate fixture awards on every forward step. Actual Physics,
-- Checkpoints, Laps and Race stop exactly on lap3 even in a five-step callback.
local finishTrack=shallow(Track)
finishTrack.gates={Track.gates[1]}
finishTrack.crossesGate=function(previous,current) return current.y>previous.y end
local finishing=new(finishTrack)
assert(Live.advance(finishing,10100,{accelerate=true})==3)
local final=Live.view(finishing)
assert(final.vehicle.tick==3 and final.race.totalTicks==3 and final.race.laps.completedLaps==3
    and final.phase=="finishing" and final.race.status=="finished")
assert(Live.advance(finishing,10200,{accelerate=true})==0)
same(final.vehicle,Live.view(finishing).vehicle)
assert(receive(finishing,10200,1,3,{completedLaps=3,status="finished"}))
for _,now in ipairs({10200,10700,11200}) do assert(Live.update(finishing,now,function() return "accepted" end)) end
assert(Live.view(finishing).phase=="closed" and Live.view(finishing).reason=="completed_unverified"
    and Live.view(finishing).resultVerified==false,"both reports do not become an official winner")
local peerStop=new(); assert(receive(peerStop,10010,1,1,{status="stopped"}))
assert(Live.view(peerStop).reason=="peer_stopped")

print("live_race: actual GO/physics/laps, 1200-tick two-peer tape, 700ms synthetic RTT, bounded telemetry and frozen cleanup")
