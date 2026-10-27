-- Synthetic checkpoint paths verify geometry/tick rules, not client lap quality.
local T=dofile("addon/AzerothKart/Track.lua")
local C=dofile("addon/AzerothKart/Checkpoints.lua")
local L=dofile("addon/AzerothKart/Loop.lua")
local function pose(x,y,tick) return {x=x,y=y,tick=tick} end
local gate=T.gates[1]
local midY=(gate.ay+gate.by)/2
local before,after=pose(gate.ax+1,midY,0),pose(gate.ax-1,midY,1)

assert(#T.gates==4 and T.gates[1].name=="North" and T.gates[2].name=="West"
    and T.gates[3].name=="South" and T.gates[4].name=="Start","counterclockwise gate ordering")
assert(gate.ax==T.centerX and gate.ay==T.centerY+T.innerY
    and gate.by==T.centerY+T.outerY,"gate span derives from analytical road radii")
assert(T.checkpointMaxStep==5,"fixed-step movement sanity bound")
assert(T.crossesGate(before,after,gate),"forward finite-segment crossing")
assert(not T.crossesGate(after,before,gate),"reverse crossing is rejected")
assert(not T.crossesGate(before,before,gate),"stationary pose is rejected")
local onLine=pose(gate.ax,midY,1)
assert(T.crossesGate(before,onLine,gate),"arrival exactly on line counts once")
assert(not T.crossesGate(onLine,after,gate),"departure from line never counts again")
assert(not T.crossesGate(pose(gate.ax,midY-1),pose(gate.ax,midY+1),gate),
    "movement parallel to gate does not count")
for _,y in ipairs({gate.ay,gate.by}) do
    assert(T.crossesGate(pose(gate.ax+1,y),pose(gate.ax-1,y),gate),"gate endpoints are inclusive")
end
for _,y in ipairs({gate.ay-1,gate.by+1}) do
    assert(not T.crossesGate(pose(gate.ax+1,y),pose(gate.ax-1,y),gate),"outside finite gate span")
end
assert(T.crossesGate(pose(gate.ax+2,gate.ay-2),pose(gate.ax-2,gate.ay+2),gate),
    "intersection point, rather than endpoint, controls gate-span acceptance")
assert(not T.crossesGate({},after,gate) and not T.crossesGate(before,after,{}),"malformed poses/gates")
for _,bad in ipairs({math.huge,-math.huge,0/0,"bad",true,false}) do
    assert(not T.crossesGate(pose(bad,midY),after,gate),"nonfinite/non-numeric prior coordinate")
    assert(not T.crossesGate(before,pose(gate.ax-1,bad),gate),"nonfinite/non-numeric next coordinate")
end

local progress=C.new(T)
assert(progress.nextGate==1 and progress.passed==0 and not progress.complete and progress.lastTick==0,
    "fresh checkpoint state")
local awarded=C.step(progress,before,after,T)
assert(awarded.nextGate==2 and awarded.passed==1 and awarded.lastTick==1 and not awarded.complete,
    "one expected gate awards one progress step")
assert(progress.nextGate==1 and progress.passed==0 and progress.lastTick==0,
    "stepping leaves incoming progress unchanged")
do
    local layered={gates={{name=gate.name,ax=gate.ax,ay=gate.ay,bx=gate.bx,by=gate.by,
        nx=gate.nx,ny=gate.ny,level=1}},crossesGate=T.crossesGate,checkpointMaxStep=5}
    local a,b=pose(before.x,before.y,0),pose(after.x,after.y,1)
    a.level,b.level=0,0
    assert(C.step(C.new(layered),a,b,layered).passed==0,"same x/y crossing below an upper gate awards nothing")
    a.level,b.level=0,1
    assert(C.step(C.new(layered),a,b,layered).passed==0,"a ramp transfer cannot also award a gate on either floor")
    a.level,b.level=1,1
    assert(C.step(C.new(layered),a,b,layered).passed==1,"ordered gate on the kart's own floor counts normally")
    for _,bad in ipairs({false,2,-1,0.5,0/0}) do
        b.level=bad
        assert(C.step(C.new(layered),a,b,layered).passed==0,"malformed floor cannot award progress")
    end
end
assert(C.step(awarded,before,after,T)==awarded,"duplicate report returns the same progress")
assert(C.step(awarded,pose(before.x,before.y,0),pose(after.x,after.y,2),T)==awarded,
    "out-of-order previous tick is rejected")
assert(C.step(awarded,pose(before.x,before.y,1),pose(after.x,after.y,3),T)==awarded,
    "gap tick report is rejected")
assert(C.step(progress,pose(before.x,before.y,0),pose(after.x,after.y,0),T)==progress,
    "same-tick movement is rejected")
for _,badTick in ipairs({-1,0.5,math.huge,0/0,"1",false}) do
    assert(C.step(progress,before,pose(after.x,after.y,badTick),T)==progress,"malformed tick is rejected")
    assert(not pcall(C.new,T,badTick),"malformed initial tick is rejected")
end
local west=T.gates[2]
local wrong=C.step(progress,pose((west.ax+west.bx)/2,west.ay+1,0),
    pose((west.ax+west.bx)/2,west.ay-1,1),T)
assert(wrong.passed==0 and wrong.nextGate==1 and wrong.lastTick==1,"cannot skip to a later gate")
local recovery=C.step(wrong,pose(before.x,before.y,1),pose(after.x,after.y,2),T)
assert(recovery.passed==1,"sequential progress remains usable after ignored wrong gate")
local jump=C.step(progress,pose(gate.ax+4,midY,0),pose(gate.ax-4,midY,1),T)
assert(jump.passed==0 and jump.lastTick==1,"implausible movement consumes tick without awarding")
local recovered=C.step(jump,pose(before.x,before.y,1),pose(after.x,after.y,2),T)
assert(recovered.passed==1,"valid consecutive movement recovers after an implausible sample")
local boundary=C.step(progress,pose(gate.ax+2.5,midY,0),pose(gate.ax-2.5,midY,1),T)
assert(boundary.passed==1,"movement at the inclusive sanity bound is accepted")
local malformed=C.step(progress,before,pose(0/0,midY,1),T)
assert(malformed.passed==0 and malformed.lastTick==1,"invalid position consumes consecutive tick")
malformed=C.step(malformed,pose(0/0,midY,1),pose(before.x,before.y,2),T)
malformed=C.step(malformed,pose(before.x,before.y,2),pose(after.x,after.y,3),T)
assert(malformed.passed==1 and malformed.lastTick==3,"valid poses recover after invalid position samples")
local offset=C.new(T,20)
assert(C.step(offset,pose(before.x,before.y,20),pose(after.x,after.y,21),T).passed==1,
    "progress may start at an explicit fixed tick")

-- A synthetic centerline trajectory circles the oval once, then continues.
-- Each displacement is below the current maximum; this is not an input replay.
local poses={[0]=pose(T.spawn().x,T.spawn().y,0)}
for tick=1,900 do
    local angle=tick*2*math.pi/720
    poses[tick]=pose(T.centerX+T.lineX*math.cos(angle),T.centerY+T.lineY*math.sin(angle),tick)
    local dx,dy=poses[tick].x-poses[tick-1].x,poses[tick].y-poses[tick-1].y
    assert(dx*dx+dy*dy<T.checkpointMaxStep^2,"synthetic path uses credible displacements")
end
local reference,state={},C.new(T)
for tick=1,900 do
    local prior=state
    state=C.step(state,poses[tick-1],poses[tick],T)
    assert(state.passed-prior.passed>=0 and state.passed-prior.passed<=1,"at most one award per step")
    reference[tick]=state
end
assert(state.complete and state.passed==4 and state.nextGate==5,"four gates complete one ordered circuit")
assert(state.lastTick<900 and C.step(state,poses[899],poses[900],T)==state,
    "completion freezes without wrapping into another circuit")
for _,fps in ipairs({30,60,144}) do
    local clock,replay,tick=L.new(1/60,5),C.new(T),0
    for _=1,900*fps/60 do
        L.advance(clock,1/fps,function()
            tick=tick+1
            replay=C.step(replay,poses[tick-1],poses[tick],T)
            for _,field in ipairs({"nextGate","passed","complete","lastTick"}) do
                assert(replay[field]==reference[tick][field],"checkpoint cadence differs: "..fps.." Hz "..field)
            end
        end)
    end
    assert(tick==900 and clock.droppedSeconds==0,"synthetic path consumes exact fixed ticks")
end
print("checkpoints: directional ordered gates; 900-tick synthetic path matches at 30/60/144 Hz")
