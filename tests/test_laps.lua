-- Synthetic lap paths test fixed-tick accounting, not a client/input replay.
local T=dofile("addon/AzerothKart/Track.lua")
local C=dofile("addon/AzerothKart/Checkpoints.lua")
local L=dofile("addon/AzerothKart/Loop.lua")
local Laps=dofile("addon/AzerothKart/Laps.lua")
local function pose(x,y,tick) return {x=x,y=y,tick=tick} end
local function crossing(index,tick,reverse)
    local gate=T.gates[index]
    local x,y=(gate.ax+gate.bx)/2,(gate.ay+gate.by)/2
    local direction=reverse and -1 or 1
    return pose(x-gate.nx*direction,y-gate.ny*direction,tick-1),
        pose(x+gate.nx*direction,y+gate.ny*direction,tick)
end
local function cross(laps,index,reverse)
    local previous,current=crossing(index,laps.lastTick+1,reverse)
    return Laps.step(laps,previous,current,T,C),previous,current
end

local fresh=Laps.new(T,C)
assert(fresh.completedLaps==0 and fresh.lapStartTick==0 and fresh.currentLapTicks==0
    and fresh.lastLapTicks==nil and fresh.lastFinishTick==nil and fresh.lastTick==0
    and fresh.bestLapTicks==nil and fresh.bestLapNumber==nil
    and fresh.checkpoints.nextGate==1 and fresh.checkpoints.passed==0
    and fresh.checkpoints.lastTick==0 and not fresh.checkpoints.complete,"fresh practice lap")
local state=fresh
local previous,current
-- Isolated valid gate vectors exercise wrapper bookkeeping; the connected
-- credible trajectory below separately exercises actual repeated circuits.
for index=1,4 do state,previous,current=cross(state,index) end
assert(state.completedLaps==1 and state.lastLapTicks==4 and state.lapStartTick==4
    and state.currentLapTicks==0 and state.lastFinishTick==4 and state.lastTick==4
    and state.bestLapTicks==4 and state.bestLapNumber==1,
    "ordered circuit awards one lap and resets the tick origin")
assert(state.checkpoints.nextGate==1 and state.checkpoints.passed==0
    and not state.checkpoints.complete and state.checkpoints.lastTick==4,
    "completion immediately rearms North at the same tick")
assert(fresh.completedLaps==0 and fresh.lastTick==0 and fresh.checkpoints.passed==0,
    "stepping never mutates incoming lap or checkpoint state")
assert(Laps.step(state,previous,current,T,C)==state,"duplicate finish cannot award another lap")
for _=1,3 do
    state=cross(state,4,true)
    state=cross(state,4,false)
end
assert(state.completedLaps==1 and state.lastFinishTick==4 and state.lastLapTicks==4
    and state.currentLapTicks==6 and state.checkpoints.passed==0,
    "start-line jitter advances time but cannot bypass the next circuit")
state=cross(state,1)
state=cross(state,4)
assert(state.completedLaps==1 and state.checkpoints.passed==1
    and state.checkpoints.nextGate==2,"Start cannot complete a partially ordered circuit")

local skipped=cross(fresh,2)
assert(skipped.currentLapTicks==1 and skipped.checkpoints.passed==0 and skipped.completedLaps==0,
    "skipped gate advances practice time without a lap")
local wrong=cross(fresh,1,true)
assert(wrong.currentLapTicks==1 and wrong.checkpoints.passed==0 and wrong.completedLaps==0,
    "wrong-way crossing advances practice time without a lap")
local gate=T.gates[1]
local midY=(gate.ay+gate.by)/2
local invalid=Laps.step(fresh,pose(gate.ax+1,midY,0),pose(0/0,midY,1),T,C)
assert(invalid.lastTick==1 and invalid.currentLapTicks==1 and invalid.checkpoints.passed==0,
    "malformed position consumes the same practice/checkpoint tick")
local jump=Laps.step(fresh,pose(gate.ax+4,midY,0),pose(gate.ax-4,midY,1),T,C)
assert(jump.lastTick==1 and jump.currentLapTicks==1 and jump.checkpoints.passed==0,
    "implausible movement advances time without a gate")
local recovered=cross(jump,1)
assert(recovered.currentLapTicks==2 and recovered.checkpoints.passed==1,
    "valid sequential crossing recovers after ignored movement")
assert(Laps.step(fresh,pose(0,0,0),pose(0,0,2),T,C)==fresh,"gapped tick freezes both clocks")
assert(Laps.step(state,pose(0,0,0),pose(0,0,1),T,C)==state,"older sample returns identical state")
assert(Laps.step(fresh,pose(0,0,0),pose(0,0,0),T,C)==fresh,"same-tick sample returns identical state")
for _,bad in ipairs({-1,0.5,math.huge,-math.huge,0/0,"1",false}) do
    assert(not pcall(Laps.new,T,C,bad),"invalid initial tick rejected")
    assert(Laps.step(fresh,pose(0,0,bad),pose(0,0,1),T,C)==fresh,"invalid previous tick rejected")
    assert(Laps.step(fresh,pose(0,0,0),pose(0,0,bad),T,C)==fresh,"invalid current tick rejected")
end
local refusing={new=C.new,step=function(progress) return progress end}
assert(Laps.step(fresh,pose(0,0,0),pose(0,0,1),T,refusing)==fresh,
    "checkpoint refusal cannot advance an independent lap clock")
local mismatched={new=C.new,step=function() return {lastTick=2,complete=true} end}
assert(Laps.step(fresh,pose(0,0,0),pose(0,0,1),T,mismatched)==fresh,
    "unconsumed current checkpoint tick cannot award or advance time")
local offset=Laps.new(T,C,200)
for index=1,4 do offset=cross(offset,index) end
assert(offset.completedLaps==1 and offset.lastLapTicks==4 and offset.lapStartTick==204
    and offset.lastTick==204 and offset.checkpoints.lastTick==204
    and offset.bestLapTicks==4 and offset.bestLapNumber==1,"explicit nonzero timing origin")
local reset=Laps.new(T,C)
assert(reset~=state and reset.checkpoints~=state.checkpoints and reset.completedLaps==0
    and reset.lastLapTicks==nil and reset.currentLapTicks==0 and state.completedLaps==1
    and reset.bestLapTicks==nil and reset.bestLapNumber==nil and state.bestLapTicks==4,
    "fresh drive resets practice progress without changing the frozen previous drive")

-- Isolated crossings vary completed durations without confusing human handling
-- or the connected cadence fixture below with artificial gate-to-gate jumps.
local function timedCircuit(laps,duration)
    for _=1,duration-4 do
        laps=Laps.step(laps,pose(666,240,laps.lastTick),pose(666,240,laps.lastTick+1),T,C)
    end
    local before,after
    for index=1,4 do laps,before,after=cross(laps,index) end
    return laps,before,after
end
local first=timedCircuit(Laps.new(T,C),8)
assert(first.bestLapTicks==8 and first.bestLapNumber==1,"first completion establishes the run best")
local slower=timedCircuit(first,10)
assert(slower.lastLapTicks==10 and slower.bestLapTicks==8 and slower.bestLapNumber==1,
    "slower completed laps preserve the earlier best")
local faster=timedCircuit(slower,6)
assert(faster.bestLapTicks==6 and faster.bestLapNumber==3
    and slower.bestLapTicks==8 and first.bestLapTicks==8,
    "strictly faster completion updates duration and number immutably")
local tied,finishPrevious,finishCurrent=timedCircuit(faster,6)
assert(tied.completedLaps==4 and tied.bestLapTicks==6 and tied.bestLapNumber==3,
    "equal completed durations retain the earliest best lap")
assert(Laps.step(tied,finishPrevious,finishCurrent,T,C)==tied,
    "repeated finish cannot replace or renumber the best")
local incomplete=tied
for index=1,3 do incomplete=cross(incomplete,index) end
assert(incomplete.currentLapTicks==3 and incomplete.completedLaps==4
    and incomplete.bestLapTicks==6 and incomplete.bestLapNumber==3,
    "an unfinished lap faster so far cannot replace the completed best")
local outOfOrder=cross(tied,4)
local wrongDirection=cross(tied,1,true)
local malformed=Laps.step(tied,pose(666,240,tied.lastTick),pose(0/0,240,tied.lastTick+1),T,C)
for _,unchangedBest in ipairs({outOfOrder,wrongDirection,malformed}) do
    assert(unchangedBest.completedLaps==4 and unchangedBest.bestLapTicks==6
        and unchangedBest.bestLapNumber==3,"unawarded movement cannot replace the best")
end
assert(Laps.step(tied,pose(666,240,tied.lastTick),pose(666,240,tied.lastTick+2),T,C)==tied,
    "a tick gap preserves the exact best-bearing state")
local variableReset=Laps.new(T,C,900)
assert(variableReset.bestLapTicks==nil and variableReset.bestLapNumber==nil
    and variableReset.completedLaps==0 and tied.bestLapNumber==3,
    "new timing origins never carry a previous run best")

-- Three connected synthetic centerline circuits, beginning just past Start.
-- The phase offset avoids ambiguous floating-point arrivals exactly on a gate.
local poses={}
for tick=0,1800 do
    local angle=(tick+0.25)*2*math.pi/600
    poses[tick]=pose(T.centerX+T.lineX*math.cos(angle),T.centerY+T.lineY*math.sin(angle),tick)
    if tick>0 then
        local dx,dy=poses[tick].x-poses[tick-1].x,poses[tick].y-poses[tick-1].y
        assert(dx*dx+dy*dy<T.checkpointMaxStep^2,"connected synthetic path stays below movement bound")
    end
end
local fields={"completedLaps","lapStartTick","currentLapTicks","lastLapTicks","bestLapTicks","bestLapNumber","lastTick","lastFinishTick"}
local checkpointFields={"nextGate","passed","complete","lastTick"}
local reference={}
state=Laps.new(T,C)
for tick=1,1800 do
    local prior=state
    state=Laps.step(state,poses[tick-1],poses[tick],T,C)
    assert(state.completedLaps-prior.completedLaps>=0 and state.completedLaps-prior.completedLaps<=1,
        "at most one lap per actual fixed step")
    assert(state.lastTick==state.checkpoints.lastTick and state.lastTick==tick,"shared tick invariant")
    reference[tick]=state
end
assert(state.completedLaps==3 and state.lastLapTicks==600 and state.currentLapTicks==0
    and state.lastFinishTick==1800 and state.checkpoints.nextGate==1
    and state.bestLapTicks==600 and state.bestLapNumber==1,"three repeatable timed circuits")
for _,fps in ipairs({30,60,144}) do
    local clock,replay,tick=L.new(1/60,5),Laps.new(T,C),0
    for _=1,1800*fps/60 do
        L.advance(clock,1/fps,function()
            tick=tick+1
            replay=Laps.step(replay,poses[tick-1],poses[tick],T,C)
            for _,field in ipairs(fields) do
                assert(replay[field]==reference[tick][field],"lap cadence differs: "..fps.." Hz "..field)
            end
            for _,field in ipairs(checkpointFields) do
                assert(replay.checkpoints[field]==reference[tick].checkpoints[field],
                    "nested checkpoint cadence differs: "..fps.." Hz "..field)
            end
        end)
    end
    assert(tick==1800 and clock.droppedSeconds==0,"synthetic lap replay consumes exact fixed ticks")
end
print("laps: once-only timing and earliest completed run best; 1800-tick synthetic path matches at 30/60/144 Hz")
