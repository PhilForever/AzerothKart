-- M0 analytical baseline, not game-feel acceptance. No road impacts in this probe.
local P = dofile("addon/AzerothKart/Physics.lua")
local open = {
    spawn=function() return {x=0,y=0,heading=math.pi/2} end,
    isDrivable=function() return true end,
}
local state = P.new(open)
local half, full
for tick=1,120 do
    state = P.step(state,{accelerate=true},P.FIXED_DT,open)
    if not half and state.speed >= P.MAX_SPEED/2 then half = tick end
    if not full and state.speed >= P.MAX_SPEED then full = tick end
end
assert(half and full and half < full,"acceleration baseline reaches both targets")
local brakeTicks, brakeDistance = 0, 0
local x,y = state.x,state.y
while state.speed > 0 and brakeTicks < 120 do
    local oldX,oldY = state.x,state.y
    state = P.step(state,{brake=true},P.FIXED_DT,open)
    brakeTicks = brakeTicks+1
    brakeDistance = brakeDistance + math.sqrt((state.x-oldX)^2+(state.y-oldY)^2)
end
assert(brakeTicks < 120 and state.speed <= 0,"braking crosses zero within budget")
assert(brakeDistance > 0 and state.y > y and math.abs(state.x-x)<1e-10,"braking remains straight")
print(("handling v%d (open plane): accel50=%d ticks accel100=%d ticks brakeToZero=%d ticks path=%.3f units")
    :format(P.VERSION,half,full,brakeTicks,brakeDistance))
