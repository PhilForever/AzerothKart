-- Focused surface handling and short replay checks; no client handling claim.
local T=dofile("addon/AzerothKart/Track.lua")
local P=dofile("addon/AzerothKart/Physics.lua")
local L=dofile("addon/AzerothKart/Loop.lua")
local dt=P.FIXED_DT
local function noCharge(s,context)
    assert(not s.drifting and s.driftDirection==0 and s.driftTicks==0 and s.driftTier==0
        and s.driftGraceTicks==0,context)
    assert(s.boostTicks==0 and s.slipAngle==0,context..": boost/slip cleared")
end
local function place(x,y,heading,speed)
    local s=P.new(T)
    s.x,s.y,s.heading,s.speed=x,y,heading,speed
    s.surface=T.surfaceAt(x,y)
    return s
end

-- The island is a slowdown surface, not an impassable hole in the track.
local exit=place(T.centerX+T.innerX+1,T.centerY,math.pi,P.MAX_SPEED)
exit.drifting,exit.driftDirection,exit.driftTicks,exit.driftTier=true,1,54,1
exit.boostTicks,exit.slipAngle=20,0.2
exit.driftGraceTicks=5
local grass=P.step(exit,{accelerate=true,left=true,drift=true},dt,T)
assert(grass.surface=="grass" and grass.x<exit.x and grass.impacts==0,"road exit crosses onto grass without impact")
noCharge(grass,"entering grass cancels a charged drift and active boost")
assert(grass.steering>0,"grass preserves steering while clearing the drift")
assert(grass.speed<exit.speed,"grass entry removes this step's boost acceleration before slowing")
exit.boostTicks=0
local released=P.step(exit,{accelerate=true,left=true},dt,T)
assert(released.surface=="grass" and released.speed<exit.speed,
    "charged release onto grass cannot retain a boost speed reward")
noCharge(released,"grass entry cancels the release reward")
local reentry=place(T.centerX+T.innerX-0.5,T.centerY,0,P.GRASS_MAX_SPEED)
reentry=P.step(reentry,{accelerate=true},dt,T)
assert(reentry.surface=="road" and reentry.x>T.centerX+T.innerX and reentry.impacts==0,"grass permits road reentry")
local road=P.step(reentry,{accelerate=true},dt,T)
assert(road.speed>reentry.speed,"road restores normal acceleration")

-- Keep speed measurements on grass so crossing the road cannot mask a cap.
local allGrass={
    spawn=T.spawn,isDrivable=function() return false end,
    surfaceAt=function() return "grass" end,
    constrainPosition=function(x,y) return x,y,false end,
}
local fast=P.new(allGrass)
fast.speed=P.BOOST_MAX_SPEED
local slowing=P.step(fast,{accelerate=true},dt,allGrass)
assert(slowing.speed<fast.speed and slowing.speed>P.GRASS_MAX_SPEED,"grass eases down inherited boost speed")
assert(fast.speed-slowing.speed<=P.GRASS_DRAG*dt,"grass drag applies at most once per step")
for _=1,180 do slowing=P.step(slowing,{accelerate=true},dt,allGrass) end
assert(slowing.speed==P.GRASS_MAX_SPEED,"held throttle settles at grass forward limit")
local forward=P.new(allGrass)
for _=1,90 do forward=P.step(forward,{accelerate=true},dt,allGrass) end
assert(forward.speed==P.GRASS_MAX_SPEED,"grass throttle reaches its lower forward limit")
local reverse=P.new(allGrass)
for _=1,90 do reverse=P.step(reverse,{brake=true},dt,allGrass) end
assert(reverse.speed==-P.GRASS_REVERSE_MAX,"grass brake reaches its lower reverse limit")
fast.drifting,fast.driftDirection,fast.driftTicks,fast.driftTier=true,1,108,2
fast.boostTicks,fast.slipAngle=20,0.4
local cancelled=P.step(fast,{accelerate=true,left=true,drift=true},dt,allGrass)
noCharge(cancelled,"starting on grass cannot sustain drift or boost")

-- Clamp the crossed axis and retain motion along the wall. A corner scrubs
-- speed once, rather than multiplying the penalty separately for both axes.
local boundX,boundY=T.width-T.wallInset,T.height-T.wallInset
local side=place(boundX,T.centerY,math.pi/4,P.MAX_SPEED)
local corner=place(boundX,boundY,math.pi/4,P.MAX_SPEED)
side=P.step(side,{accelerate=true},dt,T)
corner=P.step(corner,{accelerate=true},dt,T)
assert(side.x==boundX and side.y>T.centerY and side.surface=="wall" and side.impacts==1,"wall retains tangential movement")
assert(corner.x==boundX and corner.y==boundY and corner.impacts==1,"corner remains inside both walls")
assert(side.speed==corner.speed and side.speed>0,"corner contact applies one speed scrub")
side.heading=math.pi
local recovered=P.step(side,{accelerate=true},dt,T)
assert(recovered.x<side.x and recovered.impacts==side.impacts and recovered.surface=="grass","steering away recovers from a wall")
local charged=place(boundX,T.centerY,0,P.MAX_SPEED)
charged.drifting,charged.driftDirection,charged.driftTicks,charged.driftTier=true,1,108,2
charged.boostTicks,charged.slipAngle=20,0.4
local wall=P.step(charged,{accelerate=true,left=true,drift=true},dt,T)
assert(wall.surface=="wall","charged fixture reaches wall")
noCharge(wall,"wall clears drift, boost and slip")
assert(wall.steering==0,"wall contact resets steering")

-- Real track geometry with a spawn near its wall ensures this short replay
-- covers both grass and contact. All simulation fields must match each tick.
local replayTrack={
    spawn=function() return {x=boundX-2,y=T.centerY,heading=0} end,
    isDrivable=T.isDrivable,surfaceAt=T.surfaceAt,constrainPosition=T.constrainPosition,
}
local fields={"x","y","heading","speed","tick","impacts","drifting","driftDirection",
              "driftTicks","driftTier","boostTicks","slipAngle","surface","steering","driftGraceTicks"}
local function tapeFor(seed)
    local tape,direction={},1
    for tick=1,360 do
        local phase=(tick-1)%90
        if phase==0 then seed=(seed*48271)%2147483647; direction=seed%2==0 and 1 or -1 end
        tape[tick]={accelerate=true,left=tick>90 and direction==1,right=tick>90 and direction==-1,
                    drift=tick>180 and phase<60}
    end
    return tape
end
local tape,repeated=tapeFor(1729),tapeFor(1729)
local reference,state={},P.new(replayTrack)
local grassSeen,wallSeen=false,false
for tick=1,#tape do
    state=P.step(state,tape[tick],dt,replayTrack)
    reference[tick]=state
    grassSeen=grassSeen or state.surface=="grass"
    wallSeen=wallSeen or state.surface=="wall"
end
assert(grassSeen and wallSeen,"surface replay exercises grass and walls")
for _,fps in ipairs({30,60,144}) do
    local clock,replay=L.new(dt,5),P.new(replayTrack)
    for _=1,#tape*fps/60 do
        L.advance(clock,1/fps,function(stepDt)
            local tick=replay.tick+1
            replay=P.step(replay,repeated[tick],stepDt,replayTrack)
            for _,field in ipairs(fields) do
                assert(replay[field]==reference[tick][field],"surface replay differs: "..fps.." FPS "..field.." tick "..tick)
            end
        end)
    end
    assert(replay.tick==#tape and clock.droppedSeconds==0,"surface replay consumes exact fixed ticks")
end
