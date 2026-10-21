-- Actual Physics/Race initialization at an explicit coordinated local GO.
local T=dofile("addon/AzerothKart/Track.lua")
local P=dofile("addon/AzerothKart/Physics.lua")
local C=dofile("addon/AzerothKart/Checkpoints.lua")
local Laps=dofile("addon/AzerothKart/Laps.lua")
local Race=dofile("addon/AzerothKart/Race.lua")
local Start=dofile("addon/AzerothKart/RaceStart.lua")
local function ticket(role)
    local guest=role=="guest"
    return {session="AKT999",role=guest and "guest" or "host",seed=98765,
        localEpochMS=guest and 10001 or 10000,hostEpochMS=10000,
        offsetLowMS=-3,offsetHighMS=5,uncertaintyMS=4,peerAcknowledged=not guest}
end
local function take(gate,now) return Start.take(gate,now,P,Race,C,Laps) end
local function shallow(source)
    local result={}
    for key,value in pairs(source) do result[key]=value end
    return result
end
assert(Start.MAX_CLOCK_MS==36^7-1 and Start.MAX_LATE_MS==250,"bounded clock and late gate")
local hostTicket=ticket()
local host=assert(Start.new(hostTicket,T,P.VERSION))
hostTicket.localEpochMS,hostTicket.seed=1,0
host.ticket,host.closed,host.lastMS={},false,0
local waiting,why=take(host,9999)
assert(waiting==nil and why=="waiting","before GO creates no authoritative state")
local bundle=assert(take(host,10000))
assert(bundle.session=="AKT999" and bundle.role=="host" and bundle.seed==98765
    and bundle.localEpochMS==10000 and bundle.hostEpochMS==10000
    and bundle.uncertaintyMS==4 and bundle.peerAcknowledged==true
    and bundle.trackId==T.id and bundle.trackVersion==T.version
    and bundle.physicsVersion==P.VERSION and bundle.fixedDt==1/60,
    "ticket is captured and seed remains metadata for current non-random physics")
assert(bundle.vehicle.tick==0 and bundle.vehicle.speed==0 and bundle.race.status=="running"
    and bundle.race.startTick==0 and bundle.race.lastTick==0 and bundle.race.totalTicks==0
    and bundle.race.countdownTicks==0 and bundle.race.laps.lapStartTick==0
    and bundle.race.laps.completedLaps==0,"GO creates fresh actual physics/race without countdown catch-up")
assert(take(host,10000)==nil and take(host,10001)==nil,"GO is consumable exactly once")
host.closed=false
assert(take(host,10000)==nil,"public token writes cannot rearm a consumed start")

local guest=assert(Start.new(ticket("guest"),T,P.VERSION))
local guestWait,guestReason=take(guest,10000)
assert(guestWait==nil and guestReason=="waiting","guest waits for its mapped local epoch")
local guestBundle=assert(take(guest,10001))
assert(guestBundle.role=="guest" and guestBundle.localEpochMS==10001
    and guestBundle.peerAcknowledged==false,"guest does not claim host received the final ACK")
local late=assert(Start.new(ticket(),T,P.VERSION))
local noLate,lateReason=take(late,10251)
assert(noLate==nil and lateReason=="late" and take(late,10000)==nil,
    "late callback cannot start or simulate a catch-up race")
assert(take(assert(Start.new(ticket(),T,P.VERSION)),10250),"inclusive 250ms local lateness budget")
local backwards=assert(Start.new(ticket(),T,P.VERSION))
take(backwards,9999)
local noBackwards,backwardsReason=take(backwards,9998)
assert(noBackwards==nil and backwardsReason=="clock" and take(backwards,10000)==nil,
    "backwards clock closes the gate")
for _,bad in ipairs({-1,0.5,math.huge,-math.huge,0/0,"10000",false,Start.MAX_CLOCK_MS+1}) do
    local badGate=assert(Start.new(ticket(),T,P.VERSION))
    local result,reason=take(badGate,bad)
    assert(result==nil and reason=="clock" and take(badGate,10000)==nil,"invalid clock is terminal")
end
local cancelled=assert(Start.new(ticket(),T,P.VERSION))
assert(Start.cancel(cancelled) and take(cancelled,10000)==nil,"cancelled race never starts")
assert(not Start.cancel({}) and take({},10000)==nil,"foreign gate is refused")

local changes={
    {"session","bad"},{"role","spectator"},{"seed",-1},{"seed",2147483648},
    {"localEpochMS",9999},{"hostEpochMS",-1},{"offsetLowMS",6},
    {"offsetHighMS",2002},{"uncertaintyMS",3.9},{"uncertaintyMS",1003},
    {"peerAcknowledged",false},{"extra",true},
}
for _,change in ipairs(changes) do
    local bad=ticket()
    bad[change[1]]=change[2]
    assert(Start.new(bad,T,P.VERSION)==nil,"invalid ticket: "..change[1])
end
for key in pairs(ticket()) do
    local bad=ticket()
    bad[key]=nil
    assert(Start.new(bad,T,P.VERSION)==nil,"missing ticket field: "..key)
end
local badGuest=ticket("guest")
badGuest.localEpochMS=10000
assert(Start.new(badGuest,T,P.VERSION)==nil,"guest epoch must use the declared midpoint mapping")
assert(Start.new(setmetatable(ticket(),{}),T,P.VERSION)==nil
    and Start.new(ticket(),T,0)==nil and Start.new(ticket(),T,1296)==nil,
    "plain tickets and bounded physics version required")
local badTrack=shallow(T)
badTrack.gates={}
assert(Start.new(ticket(),badTrack,P.VERSION)==nil,"track requires actual ordered gates")

local source=shallow(T)
source.gates={}
for index,gate in ipairs(T.gates) do source.gates[index]=shallow(gate) end
local captured=assert(Start.new(ticket(),source,P.VERSION))
source.id,source.version,source.width,source.gates[1].ax="changed",99,1,-1000
local capturedBundle=assert(take(captured,10000))
assert(capturedBundle.trackId==T.id and capturedBundle.trackVersion==T.version
    and capturedBundle.track.width==T.width and capturedBundle.track.gates[1].ax==T.gates[1].ax
    and capturedBundle.track~=source and capturedBundle.track.gates~=source.gates
    and capturedBundle.track.spawn==source.spawn,"track data captured; geometry function references preserved")

local mismatched=assert(Start.new(ticket(),T,P.VERSION))
local otherPhysics=shallow(P)
otherPhysics.VERSION=P.VERSION+1
local noVersion,versionReason=Start.take(mismatched,10000,otherPhysics,Race,C,Laps)
assert(noVersion==nil and versionReason=="physics_version" and take(mismatched,10000)==nil,
    "version mismatch is terminal")
local missing=assert(Start.new(ticket(),T,P.VERSION))
local noDeps,depsReason=Start.take(missing,10000,P,{},C,Laps)
assert(noDeps==nil and depsReason=="dependencies" and take(missing,10000)==nil,
    "missing initializer cannot be retried")
local throwing=assert(Start.new(ticket(),T,P.VERSION))
local failed=shallow(P)
failed.new=function() error("fixture failure") end
local noState,stateReason=Start.take(throwing,10000,failed,Race,C,Laps)
assert(noState==nil and stateReason=="initialization" and take(throwing,10000)==nil,
    "initialization exception cannot create a later duplicate start")
local reentrant=assert(Start.new(ticket(),T,P.VERSION))
local guarded=shallow(P)
guarded.new=function(track)
    assert(take(reentrant,10000)==nil,"initializer reentry cannot consume the same GO")
    return P.new(track)
end
assert(Start.take(reentrant,10000,guarded,Race,C,Laps),"ordinary initialization survives refused reentry")

-- Equal metadata, initial geometry and input tape produce exactly equal state.
-- Current Physics has no RNG; the seed is deliberately not claimed as applied.
for tick=1,900 do
    local input={accelerate=tick%240<210,brake=tick%240>=225,
        left=tick%180<65,right=tick%180>=100 and tick%180<145,drift=tick%120<90}
    for _,run in ipairs({bundle,guestBundle}) do
        local previous=run.vehicle
        run.vehicle=P.step(previous,input,run.fixedDt,run.track)
        run.race=Race.step(run.race,previous,run.vehicle,run.track,C,Laps)
    end
    for key,value in pairs(bundle.vehicle) do
        assert(value==guestBundle.vehicle[key],"identical input replay diverged: "..key)
    end
    assert(bundle.race.lastTick==tick and guestBundle.race.lastTick==tick
        and bundle.race.totalTicks==tick and guestBundle.race.totalTicks==tick
        and bundle.race.laps.completedLaps==guestBundle.race.laps.completedLaps,
        "race timing begins on the first driving tick independent of local clock epoch")
end
print("race_start: one-shot bounded GO initializes actual Physics/Race; 900-tick deterministic replay")
