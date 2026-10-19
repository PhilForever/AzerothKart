-- Connected synthetic circuits test session timing, not human input/handling.
local T=dofile("addon/AzerothKart/Track.lua")
local C=dofile("addon/AzerothKart/Checkpoints.lua")
local L=dofile("addon/AzerothKart/Loop.lua")
local Laps=dofile("addon/AzerothKart/Laps.lua")
local Race=dofile("addon/AzerothKart/Race.lua")
local function pose(x,y,tick) return {x=x,y=y,tick=tick} end
local function crossing(race,index)
    local gate=T.gates[index]
    local x,y=(gate.ax+gate.bx)/2,(gate.ay+gate.by)/2
    local previous=pose(x-gate.nx,y-gate.ny,race.lastTick)
    local current=pose(x+gate.nx,y+gate.ny,race.lastTick+1)
    return Race.step(race,previous,current,T,C,Laps),previous,current
end

local fresh=Race.new(T,C,Laps)
assert(fresh.status=="running" and fresh.targetLaps==3 and fresh.startTick==0
    and fresh.lastTick==0 and fresh.totalTicks==0 and fresh.finishTick==nil
    and fresh.reason==nil and fresh.laps.completedLaps==0,"fresh three-lap run")
local partial=crossing(fresh,1)
assert(partial~=fresh and partial.lastTick==1 and partial.totalTicks==1
    and partial.laps.checkpoints.passed==1 and fresh.laps.checkpoints.passed==0,
    "session stepping preserves previous state")
for _,interrupted in ipairs({false,true}) do
    local stopped=Race.stop(partial,nil,interrupted)
    assert(stopped.status==(interrupted and "interrupted" or "stopped")
        and stopped.reason==(interrupted and "Game interrupted by combat" or "Stopped")
        and stopped.laps==partial.laps and stopped.lastTick==1 and stopped.totalTicks==1
        and stopped.finishTick==nil and stopped.laps.completedLaps==0,
        "partial stop freezes the exact unfinished lap without an award")
    assert(Race.step(stopped,nil,nil,nil,nil,nil)==stopped
        and Race.stop(stopped,"Different reason",not interrupted)==stopped,
        "stopped/interrupted sessions remain terminal by identity")
end
assert(Race.stop(partial,"Focus lost").reason=="Focus lost","explicit stop reason retained")
assert(Race.stop(partial,"Game interrupted by combat",true).status=="interrupted",
    "explicit combat interruption is terminal")
local reset=Race.new(T,C,Laps)
assert(reset~=partial and reset.laps~=partial.laps and reset.laps.checkpoints.passed==0
    and reset.laps.completedLaps==0 and reset.totalTicks==0 and reset.reason==nil,
    "fresh Start clears the prior session without mutating it")
local offset=Race.new(T,C,Laps,200)
for _=1,3 do for index=1,4 do offset=crossing(offset,index) end end
assert(offset.status=="finished" and offset.startTick==200 and offset.lastTick==212
    and offset.totalTicks==12 and offset.finishTick==212 and offset.laps.completedLaps==3,
    "explicit initial tick is the run timing origin")
for _,bad in ipairs({-1,0.5,math.huge,-math.huge,0/0,"1",false}) do
    assert(not pcall(Race.new,T,C,Laps,bad),"invalid initial tick delegates rejection to Laps")
    assert(Race.step(fresh,pose(0,0,bad),pose(0,0,1),T,C,Laps)==fresh
        and Race.step(fresh,pose(0,0,0),pose(0,0,bad),T,C,Laps)==fresh,
        "invalid consecutive ticks cannot advance a race")
end
assert(Race.step(fresh,pose(0,0,0),pose(0,0,2),T,C,Laps)==fresh
    and Race.step(partial,pose(0,0,0),pose(0,0,1),T,C,Laps)==partial,
    "gapped and duplicate ticks preserve the exact race state")
local refusing={new=Laps.new,step=function(laps) return laps end}
assert(Race.step(fresh,pose(0,0,0),pose(0,0,1),T,C,refusing)==fresh,
    "a refused lap step cannot advance an independent run clock")

-- Four complete connected centerline circuits, phase-shifted off gate lines.
-- Only the first three belong to the race; later reports must not alter it.
local poses={}
for tick=0,2400 do
    local angle=(tick+0.25)*2*math.pi/600
    poses[tick]=pose(T.centerX+T.lineX*math.cos(angle),T.centerY+T.lineY*math.sin(angle),tick)
    if tick>0 then
        local dx,dy=poses[tick].x-poses[tick-1].x,poses[tick].y-poses[tick-1].y
        assert(dx*dx+dy*dy<T.checkpointMaxStep^2,"credible connected fixed-step path")
    end
end
local reference,state={},fresh
for tick=1,1800 do
    state=Race.step(state,poses[tick-1],poses[tick],T,C,Laps)
    reference[tick]=state
    assert(state.lastTick==tick and state.totalTicks==tick
        and state.laps.lastTick==tick and state.laps.checkpoints.lastTick==tick,
        "one shared run/lap/checkpoint clock")
    if tick<1800 then assert(state.status=="running","no early finish") end
end
assert(state.status=="finished" and state.reason=="Three-lap run complete"
    and state.finishTick==1800 and state.totalTicks==1800 and state.laps.completedLaps==3
    and state.laps.lastLapTicks==600 and state.laps.currentLapTicks==0,
    "the third circuit records one exact terminal result")
for tick=1801,2400 do
    assert(Race.step(state,poses[tick-1],poses[tick],T,C,Laps)==state,
        "a fourth circuit cannot advance any terminal race state")
end
assert(Race.step(state,poses[1799],poses[1800],T,C,Laps)==state
    and Race.stop(state,"Game interrupted by combat",true)==state
    and Race.stop(state,"Closed")==state,"duplicate finish and later stops cannot replace a finish")
local raceFields={"status","targetLaps","startTick","lastTick","totalTicks","finishTick","reason"}
local lapFields={"completedLaps","lapStartTick","currentLapTicks","lastLapTicks","lastTick","lastFinishTick"}
local checkpointFields={"nextGate","passed","complete","lastTick"}
for _,fps in ipairs({30,60,144}) do
    local clock,replay,tick=L.new(1/60,5),Race.new(T,C,Laps),0
    for _=1,1800*fps/60 do
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
        end)
    end
    assert(tick==1800 and clock.droppedSeconds==0 and replay.status=="finished",
        "each render cadence reaches the same fixed-tick finish")
end
print("race: immutable three-lap finish/stop/interruption; 1800-tick synthetic run matches at 30/60/144 Hz")
