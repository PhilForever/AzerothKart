-- Original geometry and synthetic trajectories, not client feel or route trust.
local Oval=dofile("addon/AzerothKart/Track.lua")
local Mirage=dofile("addon/AzerothKart/MirageRaceway.lua")
local C=dofile("addon/AzerothKart/Checkpoints.lua")
local Laps=dofile("addon/AzerothKart/Laps.lua")
local Race=dofile("addon/AzerothKart/Race.lua")
local Loop=dofile("addon/AzerothKart/Loop.lua")
local Physics=dofile("addon/AzerothKart/Physics.lua")
local T=Mirage.new(Oval.crossesGate)
local function pose(x,y,tick) return {x=x,y=y,tick=tick} end

assert(T.id=="mirage_raceway" and T.version==1 and T.width==1024 and T.height==1024
    and T.wallInset==18 and T.checkpointMaxStep==5 and T.roadWidth==112 and T.roadRadius==56
    and #T.centerline==16 and #T.gates==4 and T.crossesGate==Oval.crossesGate,
    "versioned blockout geometry and injected gate predicate")
assert(not pcall(Mirage.new),"factory requires an explicit gate predicate")
local length=0
for index=1,#T.centerline do
    local a,b=T.centerline[index],T.centerline[index%#T.centerline+1]
    assert(T.isDrivable(a.x,a.y) and T.isDrivable((a.x+b.x)/2,(a.y+b.y)/2),
        "all centerline vertices and segment midpoints belong to the road")
    local dx,dy=b.x-a.x,b.y-a.y
    length=length+math.sqrt(dx*dx+dy*dy)
    -- A segment is within its endpoint bounding box. Expanding that box by
    -- the radius encloses the entire capsule, including both round caps.
    assert(a.x-T.roadRadius>=T.wallInset and a.x+T.roadRadius<=T.width-T.wallInset
        and a.y-T.roadRadius>=T.wallInset and a.y+T.roadRadius<=T.height-T.wallInset,
        "every complete road capsule lies inside the perimeter inset")
end
assert(T.length==length and T.length>0,"closed-loop length includes the last-to-first segment")
for _,x in ipairs({644,756}) do
    assert(T.isDrivable(x,500) and T.surfaceAt(x,500)=="road","inclusive straight road edges")
end
assert(T.isDrivable(644.001,500) and T.isDrivable(755.999,500)
    and not T.isDrivable(643.999,500) and not T.isDrivable(756.001,500),
    "capsule predicate respects the exact 56-unit half width")
assert(T.isDrivable(550,956) and T.isDrivable(540,84)
    and not T.isDrivable(550,956.001) and not T.isDrivable(540,83.999),
    "upper and lower road edge bounds")
assert(T.isDrivable(700,310),"closing segment is part of the road")
assert(T.surfaceAt(100,100)=="grass" and T.surfaceAt(18,18)=="grass"
    and T.surfaceAt(1006,1006)=="grass" and T.surfaceAt(17.999,100)=="wall"
    and T.surfaceAt(1006.001,100)=="wall" and T.surfaceAt(100,17.999)=="wall"
    and T.surfaceAt(100,1006.001)=="wall","rough salt is traversable only inside the walls")
for _,bad in ipairs({math.huge,-math.huge,0/0,"bad",true,false}) do
    assert(not T.isDrivable(bad,500) and not T.isDrivable(700,bad)
        and T.surfaceAt(bad,500)=="wall" and T.surfaceAt(700,bad)=="wall"
        and not pcall(T.constrainPosition,bad,500),"malformed coordinates are rejected")
end
assert(not T.isDrivable(1e300,1e300) and not T.isDrivable(-1e300,-1e300),
    "finite but extreme coordinates are outside the road")
local x,y,hit=T.constrainPosition(-20,1050)
assert(x==18 and y==1006 and hit,"wall constraints clamp axes independently")
x,y,hit=T.constrainPosition(700,500)
assert(x==700 and y==500 and not hit,"in-bounds positions are unchanged")
local spawn,otherSpawn=T.spawn(),T.spawn()
assert(spawn~=otherSpawn and spawn.x==700 and spawn.y==360 and spawn.heading==math.pi/2
    and T.surfaceAt(spawn.x,spawn.y)=="road","fresh north-facing road spawn")
local start=T.gates[4]
assert((spawn.x-start.ax)*start.nx+(spawn.y-start.ay)*start.ny==0,
    "spawn lies on the start plane without awarding a crossing")
local another=Mirage.new(Oval.crossesGate)
assert(another~=T and another.centerline~=T.centerline and another.centerline[1]~=T.centerline[1]
    and another.gates~=T.gates and another.gates[1]~=T.gates[1],"factory instances own their geometry")
another.centerline[1].x=1
another.gates[1].ax=1
assert(T.centerline[1].x==700 and T.gates[1].ax==550,"one instance cannot mutate another")

local function crossing(index,tick,reverse)
    local gate=T.gates[index]
    local x,y=(gate.ax+gate.bx)/2,(gate.ay+gate.by)/2
    local direction=reverse and -1 or 1
    return pose(x-gate.nx*direction,y-gate.ny*direction,tick-1),
        pose(x+gate.nx*direction,y+gate.ny*direction,tick)
end
for index,name in ipairs({"North","West","South","Start"}) do
    local before,after=crossing(index,1)
    assert(T.gates[index].name==name and T.crossesGate(before,after,T.gates[index])
        and not T.crossesGate(after,before,T.gates[index]),"correct directional finite gate")
end
local checkpoint=C.new(T)
local before,after=crossing(2,1)
local skipped=C.step(checkpoint,before,after,T)
assert(skipped.passed==0 and skipped.nextGate==1,"later gates cannot bypass the order")
before,after=crossing(1,1,true)
assert(C.step(checkpoint,before,after,T).passed==0,"wrong-way checkpoint crossing does not award")
before,after=crossing(1,1)
local accepted=C.step(checkpoint,before,after,T)
assert(accepted.passed==1 and C.step(accepted,before,after,T)==accepted,
    "one directional crossing awards exactly once")
local laps=Laps.new(T,C)
for index=1,4 do
    before,after=crossing(index,laps.lastTick+1)
    laps=Laps.step(laps,before,after,T,C)
end
assert(laps.completedLaps==1 and laps.bestLapTicks==4 and laps.bestLapNumber==1
    and Laps.step(laps,before,after,T,C)==laps,"lap wrapper shares the new ordered geometry")

-- Neutral countdown, then connected centerline samples with each step <=4.
-- Rounding segment step counts to tens also makes all render replays exact.
local poses={[0]=pose(spawn.x,spawn.y,0)}
for tick=1,Race.COUNTDOWN_TICKS do poses[tick]=pose(spawn.x,spawn.y,tick) end
local tick=Race.COUNTDOWN_TICKS
local lapSteps=0
for circuit=1,3 do
    for index=1,#T.centerline do
        local a,b=T.centerline[index],T.centerline[index%#T.centerline+1]
        local dx,dy=b.x-a.x,b.y-a.y
        local steps=math.ceil(math.sqrt(dx*dx+dy*dy)/40)*10
        if circuit==1 then lapSteps=lapSteps+steps end
        for step=1,steps do
            tick=tick+1
            poses[tick]=pose(a.x+dx*step/steps,a.y+dy*step/steps,tick)
            local px,py=poses[tick].x-poses[tick-1].x,poses[tick].y-poses[tick-1].y
            assert(px*px+py*py<=T.checkpointMaxStep^2 and T.isDrivable(poses[tick].x,poses[tick].y),
                "connected synthetic circuits stay on road with credible fixed-step displacement")
        end
    end
end
local totalTicks=tick
local reference,state={},Race.new(T,C,Laps)
for fixedTick=1,totalTicks do
    state=Race.step(state,poses[fixedTick-1],poses[fixedTick],T,C,Laps)
    reference[fixedTick]=state
    if fixedTick<=180 then
        assert(state.totalTicks==0 and state.laps.completedLaps==0,
            "countdown excludes racing time and route awards")
    elseif fixedTick<totalTicks then
        assert(state.status=="running","the first two circuits cannot finish the race")
    end
end
assert(state.status=="finished" and state.laps.completedLaps==3 and state.startTick==180
    and state.finishTick==totalTicks and state.totalTicks==3*lapSteps
    and state.laps.lastLapTicks==lapSteps and state.laps.bestLapTicks==lapSteps
    and state.laps.bestLapNumber==1,"three connected circuits finish with tick-based local results")
assert(Race.step(state,poses[totalTicks-1],poses[totalTicks],T,C,Laps)==state,
    "repeated Mirage finish retains the terminal session")
local raceFields={"status","targetLaps","countdownTicks","startTick","lastTick","totalTicks","finishTick","reason"}
local lapFields={"completedLaps","lapStartTick","currentLapTicks","lastLapTicks","bestLapTicks","bestLapNumber","lastTick","lastFinishTick"}
local checkpointFields={"nextGate","passed","complete","lastTick"}
for _,fps in ipairs({30,60,144}) do
    local clock,replay,fixedTick=Loop.new(1/60,5),Race.new(T,C,Laps),0
    for _=1,totalTicks*fps/60 do
        Loop.advance(clock,1/fps,function()
            fixedTick=fixedTick+1
            replay=Race.step(replay,poses[fixedTick-1],poses[fixedTick],T,C,Laps)
            for _,field in ipairs(raceFields) do
                assert(replay[field]==reference[fixedTick][field],"Mirage race cadence differs: "..field)
            end
            for _,field in ipairs(lapFields) do
                assert(replay.laps[field]==reference[fixedTick].laps[field],"Mirage lap cadence differs: "..field)
            end
            for _,field in ipairs(checkpointFields) do
                assert(replay.laps.checkpoints[field]==reference[fixedTick].laps.checkpoints[field],
                    "Mirage checkpoint cadence differs: "..field)
            end
        end)
    end
    assert(fixedTick==totalTicks and clock.droppedSeconds==0 and replay.status=="finished",
        "synthetic countdown and three-lap route match at each render cadence")
end
-- A short actual-input tape checks that the new surface/constraint adapter
-- produces identical physics fields, independently of synthetic route poses.
local inputs,physicsReference={},{}
local physicsState=Physics.new(T)
for fixedTick=1,360 do
    inputs[fixedTick]={accelerate=fixedTick<=300,brake=fixedTick>300,
        left=fixedTick>90 and fixedTick<=180,right=fixedTick>240 and fixedTick<=300,
        drift=fixedTick>120 and fixedTick<=170}
    physicsState=Physics.step(physicsState,inputs[fixedTick],Physics.FIXED_DT,T)
    physicsReference[fixedTick]=physicsState
end
for _,fps in ipairs({30,60,144}) do
    local clock,replay,fixedTick=Loop.new(Physics.FIXED_DT,5),Physics.new(T),0
    for _=1,6*fps do
        Loop.advance(clock,1/fps,function(dt)
            fixedTick=fixedTick+1
            replay=Physics.step(replay,inputs[fixedTick],dt,T)
            for field,value in pairs(physicsReference[fixedTick]) do
                assert(replay[field]==value,"Mirage physics input replay differs: "..field)
            end
        end)
    end
    assert(fixedTick==360 and clock.droppedSeconds==0,"Mirage input replay uses exact fixed ticks")
end
print(("mirage: capsule road/gates; %.3f-unit centerline, %d-tick synthetic countdown/run at 30/60/144 Hz")
    :format(T.length,totalTicks))
