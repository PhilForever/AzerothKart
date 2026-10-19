local T=dofile("addon/AzerothKart/Track.lua")
local P=dofile("addon/AzerothKart/Physics.lua")
local state=P.new(T)
assert(state.tick==0 and state.speed==0 and state.steering==0,"initial state")
for i=1,20 do state=P.step(state,{accelerate=true},P.FIXED_DT,T) end
assert(state.speed>0 and state.tick==20,"acceleration/tick progression")
local speed=state.speed
state=P.step(state,{},P.FIXED_DT,T)
assert(state.speed<speed,"coasting slows")
local prev=state.heading
state=P.step(state,{left=true},P.FIXED_DT,T)
assert(state.heading>prev,"left steering turns counterclockwise")
local left=P.step(P.new(T),{accelerate=true,left=true},P.FIXED_DT,T)
local right=P.step(P.new(T),{accelerate=true,right=true},P.FIXED_DT,T)
assert(left.x<T.spawn().x,"left from north must move toward screen-left")
assert(right.x>T.spawn().x,"right from north must move toward screen-right")
local both=P.step(P.new(T),{accelerate=true,left=true,right=true},P.FIXED_DT,T)
assert(both.heading==T.spawn().heading,"opposing steering inputs cancel")
local edge={x=T.width-T.wallInset,y=240,heading=0,speed=200,tick=20,impacts=0}
local collided=P.step(edge,{accelerate=true},P.FIXED_DT,T)
assert(collided.impacts==1,"outer bound collision detected")
assert(collided.x==edge.x and collided.y==edge.y and collided.surface=="wall","wall clamps penetration")
assert(collided.speed<edge.speed,"collision scrubs speed")
assert(P.VERSION==6,"drift correction grace changes replay compatibility")

-- Measure handling without track impacts obscuring speed clamps.
local openTrack={spawn=T.spawn,isDrivable=function() return true end}
local straight=P.new(openTrack)
for _=1,120 do straight=P.step(straight,{accelerate=true},P.FIXED_DT,openTrack) end
assert(straight.speed==P.MAX_SPEED,"acceleration reaches bounded top speed")
local stopped=straight
for _=1,180 do stopped=P.step(stopped,{},P.FIXED_DT,openTrack) end
assert(stopped.speed==0,"coasting reaches rest without sign reversal")
local reverse=straight
for _=1,120 do reverse=P.step(reverse,{brake=true},P.FIXED_DT,openTrack) end
assert(reverse.speed==-P.REVERSE_MAX,"brake reaches bounded reverse speed")
local reverseLeft=P.step(reverse,{brake=true,left=true},P.FIXED_DT,openTrack)
assert(reverseLeft.heading<reverse.heading,"reverse changes steering direction")
for _,dt in ipairs({0,-1,0.051,math.huge}) do
    assert(not pcall(P.step,straight,{},dt,openTrack),"invalid timestep must reject")
end
assert(not pcall(P.step,straight,{},0/0,openTrack),"NaN timestep must reject")
local legacyWall={spawn=T.spawn,isDrivable=function() return false end}
local rejected=P.step(straight,{accelerate=true},P.FIXED_DT,legacyWall)
assert(rejected.x==straight.x and rejected.y==straight.y and rejected.impacts==straight.impacts+1,
       "legacy road-only track doubles retain rejecting collision fallback")
