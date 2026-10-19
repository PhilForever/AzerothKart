-- Focused M1 mechanics check. This does not establish client handling quality.
local P=dofile("addon/AzerothKart/Physics.lua")
local L=dofile("addon/AzerothKart/Loop.lua")
local open={
    spawn=function() return {x=0,y=0,heading=0} end,
    isDrivable=function() return true end,
}
local function ready()
    local s=P.new(open)
    s.speed=P.MAX_SPEED
    return s
end
local function charge(ticks, direction)
    local s=ready()
    for _=1,ticks do
        s=P.step(s,{accelerate=true,drift=true,left=direction~= -1,right=direction== -1},P.FIXED_DT,open)
    end
    return s
end
local function release(s)
    return P.step(s,{accelerate=true,left=s.driftDirection==1,right=s.driftDirection==-1},P.FIXED_DT,open)
end
local function noCharge(s, context)
    assert(not s.drifting and s.driftDirection==0 and s.driftTicks==0 and s.driftTier==0,context)
end

assert(P.VERSION==4,"surface handling changes replay compatibility")
local initial=P.new(open)
noCharge(initial,"fresh drift state")
assert(initial.boostTicks==0 and initial.slipAngle==0,"fresh boost/slip state")
local short=charge(P.DRIFT_TIER1_TICKS-1)
assert(short.drifting and short.driftTier==0 and short.driftTicks==53,"first tier begins at tick 54")
assert(release(short).boostTicks==0,"short charge must not boost")
local one=charge(P.DRIFT_TIER1_TICKS)
assert(one.driftTier==1 and one.driftTicks==54,"first charge tier")
assert(one.slipAngle>0 and one.slipAngle<=P.MAX_SLIP_ANGLE,"left slide has bounded positive slip")
local boosted=release(one)
noCharge(boosted,"release clears charge")
assert(boosted.boostTicks==P.BOOST_TIER1_TICKS-1 and boosted.speed>P.MAX_SPEED,"release awards tier-one boost and consumes its first tick")
local two=charge(P.DRIFT_TIER2_TICKS+20,-1)
assert(two.driftTier==2 and two.driftTicks==P.DRIFT_TIER2_TICKS,"charge caps at tier two")
assert(two.slipAngle<0 and two.slipAngle>=-P.MAX_SLIP_ANGLE,"right slide has bounded negative slip")
local longBoost=release(two)
assert(longBoost.boostTicks==P.BOOST_TIER2_TICKS-1,"tier-two duration includes the release tick")
local longDuration=longBoost.boostTicks
for _=1,longDuration do
    longBoost=P.step(longBoost,{accelerate=true},P.FIXED_DT,open)
    assert(longBoost.speed<=P.BOOST_MAX_SPEED and longBoost.speed>=0,"boost speed remains bounded")
end
assert(longBoost.boostTicks==0,"boost expires on fixed ticks")
longBoost=P.step(longBoost,{accelerate=true},P.FIXED_DT,open)
assert(longBoost.speed<=P.MAX_SPEED,"expired boost restores normal cap")
assert(longBoost.slipAngle==0,"released slide recovers grip")

local forward={accelerate=true,drift=true,left=true}
local slide=P.step(ready(),forward,P.FIXED_DT,open)
local travel=math.atan(slide.y/slide.x)
assert(travel<slide.heading and math.abs((slide.heading-travel)-slide.slipAngle)<1e-12,
       "travel lags facing direction by measured slip")
for _,input in ipairs({
    {accelerate=true,drift=true},
    {accelerate=true,drift=true,left=true,right=true},
    {accelerate=true,drift=true,right=true},
    {brake=true,drift=true,left=true},
    {brake=true,left=true},
    {accelerate=true,right=true},
}) do
    local cancelled=P.step(one,input,P.FIXED_DT,open)
    noCharge(cancelled,"lost steering, opposite turn or brake cancels")
    assert(cancelled.boostTicks==0,"invalid release/turn must not award boost")
end
local slow=charge(P.DRIFT_TIER1_TICKS)
slow.speed=P.DRIFT_MIN_SPEED-1
slow=P.step(slow,{drift=true,left=true},P.FIXED_DT,open)
noCharge(slow,"insufficient speed cancels charge")
assert(slow.boostTicks==0,"slow drift has no reward")
local reverse=ready()
reverse.speed=-P.REVERSE_MAX
noCharge(P.step(reverse,{drift=true,left=true},P.FIXED_DT,open),"reverse cannot drift")
local braked=P.step(boosted,{brake=true},P.FIXED_DT,open)
assert(braked.boostTicks==0 and braked.speed<=P.MAX_SPEED,"brake cancels boost")
local wall={spawn=open.spawn,isDrivable=function() return false end}
local impact=P.step(one,{accelerate=true,left=true},P.FIXED_DT,wall)
noCharge(impact,"wall cancels even charged release")
assert(impact.boostTicks==0 and impact.slipAngle==0 and impact.impacts==one.impacts+1,
       "wall clears boost and slip")
local boostImpact=P.step(boosted,{accelerate=true},P.FIXED_DT,wall)
assert(boostImpact.boostTicks==0,"wall cancels active boost")
local notHeld=ready()
notHeld.driftTier=2
assert(release(notHeld).boostTicks==0,"a tier without an active held drift cannot pay")

-- Short seeded tape deliberately includes sustained charges and releases;
-- compare every state field at every fixed tick across render schedules.
local fields={"x","y","heading","speed","tick","impacts","drifting","driftDirection",
              "driftTicks","driftTier","boostTicks","slipAngle","surface"}
local tape,seed={},1729
local direction=1
for tick=1,720 do
    local phase=(tick-1)%180
    if phase==0 then seed=(seed*48271)%2147483647; direction=seed%2==0 and 1 or -1 end
    tape[tick]={accelerate=true,left=direction==1,right=direction==-1,drift=phase<120}
end
local reference,s={},ready()
local driftSeen,boostSeen=false,false
for tick=1,#tape do
    s=P.step(s,tape[tick],P.FIXED_DT,open)
    reference[tick]=s
    driftSeen=driftSeen or s.drifting
    boostSeen=boostSeen or s.boostTicks>0
end
assert(driftSeen and boostSeen,"tape exercises drifting and release boosts")
for _,fps in ipairs({30,60,144}) do
    local clock,replay=L.new(P.FIXED_DT,5),ready()
    for _=1,#tape*fps/60 do
        L.advance(clock,1/fps,function(dt)
            local tick=replay.tick+1
            replay=P.step(replay,tape[tick],dt,open)
            for _,key in ipairs(fields) do
                assert(replay[key]==reference[tick][key],"drift replay differs: "..fps.." FPS "..key.." tick "..tick)
            end
        end)
    end
    assert(replay.tick==#tape and clock.droppedSeconds==0,"drift tape consumes exact fixed ticks")
end
