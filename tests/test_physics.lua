local T=dofile("addon/AzerothKart/Track.lua")
local P=dofile("addon/AzerothKart/Physics.lua")
local state=P.new(T)
assert(state.tick==0 and state.speed==0,"initial state")
for i=1,20 do state=P.step(state,{accelerate=true},P.FIXED_DT,T) end
assert(state.speed>0 and state.tick==20,"acceleration/tick progression")
local speed=state.speed
state=P.step(state,{},P.FIXED_DT,T)
assert(state.speed<speed,"coasting slows")
local prev=state.heading
state=P.step(state,{left=true},P.FIXED_DT,T)
assert(state.heading<prev,"left steering changes heading")
local edge={x=769,y=240,heading=0,speed=200,tick=20,impacts=0}
local collided=P.step(edge,{accelerate=true},P.FIXED_DT,T)
assert(collided.impacts==1,"outer bound collision detected")
assert(collided.x==edge.x and collided.y==edge.y,"collision rejects penetration")
assert(collided.speed<edge.speed,"collision scrubs speed")
assert(P.VERSION==1,"version should be defined")
