-- Connected synthetic circuits test session timing, not human input/handling.
local T=dofile("addon/AzerothKart/Track.lua")
local C=dofile("addon/AzerothKart/Checkpoints.lua")
local L=dofile("addon/AzerothKart/Loop.lua")
local Laps=dofile("addon/AzerothKart/Laps.lua")
local Race=dofile("addon/AzerothKart/Race.lua")
local function pose(x,y,tick) return {x=x,y=y,tick=tick} end
local function advanceCountdown(race,count)
    for _=1,count or Race.COUNTDOWN_TICKS do
        race=Race.step(race,pose(666,240,race.lastTick),pose(666,240,race.lastTick+1),T,C,Laps)
    end
    return race
end
local function crossing(race,index)
    local gate=T.gates[index]
    local x,y=(gate.ax+gate.bx)/2,(gate.ay+gate.by)/2
    local previous=pose(x-gate.nx,y-gate.ny,race.lastTick)
    local current=pose(x+gate.nx,y+gate.ny,race.lastTick+1)
    return Race.step(race,previous,current,T,C,Laps),previous,current
end

assert(Race.COUNTDOWN_TICKS==180 and Race.GO_CUE_TICKS==60,"fixed countdown and GO cue lengths")
local fresh=Race.new(T,C,Laps)
assert(fresh.status=="countdown" and fresh.targetLaps==3 and fresh.startTick==nil
    and fresh.lastTick==0 and fresh.totalTicks==0 and fresh.finishTick==nil
    and fresh.reason==nil and fresh.laps.completedLaps==0 and fresh.countdownTicks==180
    and fresh.laps.bestLapTicks==nil and fresh.laps.bestLapNumber==nil
    and Race.cue(fresh)=="3","fresh three-lap countdown")
local countdown=fresh
for tick=1,180 do
    -- Even plausible gate crossings are ignored until GO.
    countdown=crossing(countdown,(tick-1)%4+1)
    local expected=tick<60 and "3" or tick<120 and "2" or tick<180 and "1" or "GO"
    assert(Race.cue(countdown)==expected and countdown.countdownTicks==180-tick,
        "countdown cue changes at exact 60-tick boundaries")
    assert(countdown.totalTicks==0 and countdown.laps.completedLaps==0
        and countdown.laps.currentLapTicks==0 and countdown.laps.checkpoints.passed==0,
        "pre-GO ticks never advance lap time or award gates")
    if tick<180 then
        assert(countdown.status=="countdown" and countdown.startTick==nil
            and countdown.laps==fresh.laps,"countdown retains untouched original lap state")
    end
end
local running=countdown
assert(running.status=="running" and running.startTick==180 and running.lastTick==180
    and running.laps~=fresh.laps and running.laps.lapStartTick==180
    and running.laps.lastTick==180 and running.laps.checkpoints.lastTick==180,
    "GO creates a fresh lap origin without a driving tick")
assert(running.laps.bestLapTicks==nil and running.laps.bestLapNumber==nil,
    "GO starts with no completed-lap best")
assert(fresh.status=="countdown" and fresh.lastTick==0 and fresh.countdownTicks==180,
    "countdown transitions preserve previous immutable states")
local partial=crossing(running,1)
assert(partial~=running and partial.lastTick==181 and partial.totalTicks==1
    and partial.laps.checkpoints.passed==1 and running.laps.checkpoints.passed==0,
    "first running tick advances race and lap together")
local cueState=running
for tick=1,60 do
    cueState=Race.step(cueState,pose(666,240,cueState.lastTick),pose(666,240,cueState.lastTick+1),T,C,Laps)
    assert(Race.cue(cueState)==(tick<60 and "GO" or nil),"GO cue expires at the sixtieth driving tick")
end
for _,source in ipairs({advanceCountdown(fresh,17),partial}) do
    for _,interrupted in ipairs({false,true}) do
        local stopped=Race.stop(source,nil,interrupted)
        assert(stopped.status==(interrupted and "interrupted" or "stopped")
            and stopped.reason==(interrupted and "Game interrupted by combat" or "Stopped")
            and stopped.laps==source.laps and stopped.lastTick==source.lastTick
            and stopped.totalTicks==source.totalTicks and stopped.startTick==source.startTick
            and stopped.countdownTicks==source.countdownTicks and stopped.finishTick==nil
            and stopped.laps.completedLaps==0 and Race.cue(stopped)==nil,
            "pre/post-GO cancellation freezes the exact unfinished state without an award")
        assert(Race.step(stopped,nil,nil,nil,nil,nil)==stopped
            and Race.stop(stopped,"Different reason",not interrupted)==stopped,
            "stopped/interrupted sessions remain terminal by identity")
    end
end
assert(Race.stop(partial,"Focus lost").reason=="Focus lost","explicit stop reason retained")
local completed=running
for index=1,4 do completed=crossing(completed,index) end
assert(completed.laps.bestLapTicks==4 and completed.laps.bestLapNumber==1,
    "a completed running lap establishes the session best")
for _,interrupted in ipairs({false,true}) do
    local frozen=Race.stop(completed,nil,interrupted)
    assert(frozen.laps==completed.laps and frozen.laps.bestLapTicks==4
        and frozen.laps.bestLapNumber==1 and Race.stop(frozen,"Changed")==frozen,
        "ordinary and combat stops preserve the completed run best")
end
local reset=Race.new(T,C,Laps)
assert(reset~=partial and reset.laps~=partial.laps and reset.laps.checkpoints.passed==0
    and reset.laps.completedLaps==0 and reset.totalTicks==0 and reset.reason==nil
    and reset.countdownTicks==180 and reset.startTick==nil and Race.cue(reset)=="3",
    "fresh Start resets the full countdown without mutating the previous run")
assert(reset.laps.bestLapTicks==nil and reset.laps.bestLapNumber==nil
    and completed.laps.bestLapTicks==4,"fresh Start never inherits a prior run best")
local offset=advanceCountdown(Race.new(T,C,Laps,200))
assert(offset.startTick==380 and offset.lastTick==380 and offset.totalTicks==0,
    "countdown uses the explicit initial simulation tick")
for _=1,3 do for index=1,4 do offset=crossing(offset,index) end end
assert(offset.status=="finished" and offset.startTick==380 and offset.lastTick==392
    and offset.totalTicks==12 and offset.finishTick==392 and offset.laps.completedLaps==3
    and offset.laps.bestLapTicks==4 and offset.laps.bestLapNumber==1,
    "run timing begins at offset GO, excluding the countdown")
for _,bad in ipairs({-1,0.5,math.huge,-math.huge,0/0,"1",false}) do
    assert(not pcall(Race.new,T,C,Laps,bad),"invalid initial tick delegates rejection to Laps")
    for _,source in ipairs({fresh,running}) do
        assert(Race.step(source,pose(0,0,bad),pose(0,0,source.lastTick+1),T,C,Laps)==source
            and Race.step(source,pose(0,0,source.lastTick),pose(0,0,bad),T,C,Laps)==source,
            "invalid ticks cannot advance either countdown or racing")
    end
end
for _,source in ipairs({fresh,running}) do
    assert(Race.step(source,nil,pose(0,0,source.lastTick+1),T,C,Laps)==source
        and Race.step(source,pose(0,0,source.lastTick),nil,T,C,Laps)==source
        and Race.step(source,pose(0,0,source.lastTick),pose(0,0,source.lastTick+2),T,C,Laps)==source
        and Race.step(source,pose(0,0,source.lastTick),pose(0,0,source.lastTick),T,C,Laps)==source,
        "missing, duplicate and gapped samples preserve exact state")
end
assert(Race.step(partial,pose(0,0,180),pose(0,0,181),T,C,Laps)==partial,
    "an older report cannot change the active race")
local refusing={new=Laps.new,step=function(laps) return laps end}
assert(Race.step(running,pose(0,0,180),pose(0,0,181),T,C,refusing)==running,
    "a refused lap step cannot advance an independent run clock")

-- Countdown followed by four connected circuits, phase-shifted off gate lines.
-- Only the first three circuits belong to the race.
local poses={}
for tick=0,2580 do
    local angle=(math.max(0,tick-180)+0.25)*2*math.pi/600
    poses[tick]=pose(T.centerX+T.lineX*math.cos(angle),T.centerY+T.lineY*math.sin(angle),tick)
    if tick>0 then
        local dx,dy=poses[tick].x-poses[tick-1].x,poses[tick].y-poses[tick-1].y
        assert(dx*dx+dy*dy<T.checkpointMaxStep^2,"credible connected fixed-step path")
    end
end
local reference,state={},fresh
for tick=1,1980 do
    state=Race.step(state,poses[tick-1],poses[tick],T,C,Laps)
    reference[tick]=state
    local lapTick=tick>=180 and tick or 0
    assert(state.lastTick==tick and state.totalTicks==math.max(0,tick-180)
        and state.laps.lastTick==lapTick and state.laps.checkpoints.lastTick==lapTick,
        "countdown excludes race time, then run/lap/checkpoint clocks agree")
    if tick<1980 then assert(state.status~="finished","no early finish") end
end
assert(state.status=="finished" and state.reason=="Three-lap run complete"
    and state.startTick==180 and state.finishTick==1980 and state.totalTicks==1800
    and state.countdownTicks==0 and state.laps.completedLaps==3
    and state.laps.lastLapTicks==600 and state.laps.currentLapTicks==0 and Race.cue(state)==nil
    and state.laps.bestLapTicks==600 and state.laps.bestLapNumber==1,
    "third circuit records one exact finish excluding countdown ticks")
for tick=1981,2580 do
    assert(Race.step(state,poses[tick-1],poses[tick],T,C,Laps)==state,
        "a fourth circuit cannot advance any terminal race state")
end
assert(Race.step(state,poses[1979],poses[1980],T,C,Laps)==state
    and Race.stop(state,"Game interrupted by combat",true)==state
    and Race.stop(state,"Closed")==state,"duplicate finish and later stops cannot replace a finish")
local raceFields={"status","targetLaps","countdownTicks","startTick","lastTick","totalTicks","finishTick","reason"}
local lapFields={"completedLaps","lapStartTick","currentLapTicks","lastLapTicks","bestLapTicks","bestLapNumber","lastTick","lastFinishTick"}
local checkpointFields={"nextGate","passed","complete","lastTick"}
for _,fps in ipairs({30,60,144}) do
    local clock,replay,tick=L.new(1/60,5),Race.new(T,C,Laps),0
    for _=1,1980*fps/60 do
        L.advance(clock,1/fps,function()
            tick=tick+1
            replay=Race.step(replay,poses[tick-1],poses[tick],T,C,Laps)
            for _,field in ipairs(raceFields) do
                assert(replay[field]==reference[tick][field],"race cadence differs: "..fps.." Hz "..field)
            end
            for _,field in ipairs(lapFields) do
                assert(replay.laps[field]==reference[tick].laps[field],"lap cadence differs: "..fps.." Hz "..field)
            end
            for _,field in ipairs(checkpointFields) do
                assert(replay.laps.checkpoints[field]==reference[tick].laps.checkpoints[field],
                    "checkpoint cadence differs: "..fps.." Hz "..field)
            end
            assert(Race.cue(replay)==Race.cue(reference[tick]),"cue cadence differs")
        end)
    end
    assert(tick==1980 and clock.droppedSeconds==0 and replay.status=="finished",
        "each render cadence reaches the same countdown, GO and finish")
end
print("race: fixed-tick 3/2/1/GO, immutable finish/cancel; 1980-tick countdown/run matches at 30/60/144 Hz")
