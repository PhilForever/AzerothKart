-- Focused keyboard steering metrics; client handling quality remains untested.
local P=dofile("addon/AzerothKart/Physics.lua")
local L=dofile("addon/AzerothKart/Loop.lua")
local dt=P.FIXED_DT
local open={
    spawn=function() return {x=0,y=0,heading=0} end,
    isDrivable=function() return true end,
}
local function ready()
    local s=P.new(open)
    s.speed=P.MAX_SPEED
    return s
end
local function close(actual,expected,message)
    assert(math.abs(actual-expected)<1e-12,message)
end
local leftInput={accelerate=true,left=true}
local rightInput={accelerate=true,right=true}

assert(P.STEERING_RISE_RATE==8 and P.STEERING_CENTER_RATE==16,"initial steering tuning")
local left,right=ready(),ready()
assert(left.steering==0,"fresh steering is neutral")
for tick=1,8 do
    left=P.step(left,leftInput,dt,open)
    right=P.step(right,rightInput,dt,open)
    close(left.steering,math.min(1,tick*P.STEERING_RISE_RATE*dt),"steering rises progressively")
    close(right.steering,-left.steering,"left/right steering symmetry")
    close(right.heading,-left.heading,"left/right yaw symmetry")
    close(right.x,left.x,"left/right forward displacement symmetry")
    close(right.y,-left.y,"left/right sideways displacement symmetry")
    if tick<8 then assert(left.steering<1,"full steering must not arrive before tick eight") end
end
assert(left.steering==1 and right.steering==-1,"full steering arrives at eight fixed ticks")
local held=P.step(left,leftInput,dt,open)
assert(held.steering==1,"held steering stays bounded")

local centered=left
for tick=1,4 do
    centered=P.step(centered,{accelerate=true},dt,open)
    close(centered.steering,math.max(0,1-tick*P.STEERING_CENTER_RATE*dt),"release centers faster than rise")
end
assert(centered.steering==0,"release reaches neutral in four fixed ticks")
local reversed=left
for tick=1,12 do
    reversed=P.step(reversed,rightInput,dt,open)
    if tick<4 then assert(reversed.steering>0,"reversal first centers the old turn") end
    if tick==4 then assert(reversed.steering==0,"reversal spends four ticks centering") end
    if tick>4 and tick<12 then assert(reversed.steering<0 and reversed.steering>-1,"opposite turn ramps after neutral") end
end
assert(reversed.steering==-1,"full opposite turn arrives after twelve fixed ticks")
local both=P.step(left,{accelerate=true,left=true,right=true},dt,open)
assert(both.steering==0 and both.heading==left.heading,"opposing held keys cancel steering immediately")
local reverse=ready()
reverse.speed=-P.REVERSE_MAX
reverse=P.step(reverse,{brake=true,left=true},dt,open)
assert(reverse.steering>0 and reverse.heading<0,"reverse flips yaw, not steering state")

local legacy={x=0,y=0,heading=0,speed=100,tick=0,impacts=0}
local upgraded=P.step(legacy,leftInput,dt,open)
close(upgraded.steering,P.STEERING_RISE_RATE*dt,"legacy fixtures default to neutral steering")
assert(legacy.steering==nil,"stepping does not mutate the incoming state")

-- A correction preserves earned charge while steering centers, then resumes
-- only when the actual progressive steering agrees with the new raw intent.
local charged=ready()
for _=1,P.DRIFT_TIER1_TICKS do
    charged=P.step(charged,{accelerate=true,left=true,drift=true},dt,open)
end
assert(charged.driftTier==1 and charged.steering==1,"charged steering fixture")
local lost=P.step(charged,{accelerate=true,drift=true},dt,open)
assert(lost.steering>0 and lost.drifting and lost.driftTicks==charged.driftTicks
    and lost.driftGraceTicks==1 and lost.boostTicks==0,
    "brief raw steering release holds charge without increasing it")
local opposite=charged
for tick=1,5 do
    opposite=P.step(opposite,{accelerate=true,right=true,drift=true},dt,open)
    assert(opposite.boostTicks==0,"reversing raw intent never cashes out the old charge")
    if tick<=4 then
        assert(opposite.drifting and opposite.driftTicks==charged.driftTicks
            and opposite.driftGraceTicks==tick and opposite.driftDirection==1,
            "opposite drift pauses charge while the old steering centers")
    else
        assert(opposite.steering<0 and opposite.drifting and opposite.driftDirection==-1
            and opposite.driftTicks==charged.driftTicks+1 and opposite.driftGraceTicks==0,
            "opposite drift keeps earned charge once actual steering matches intent")
    end
end

-- At full speed/steering the drift's yaw is 25% lower than a normal turn.
-- Measuring the actual step protects the handling change, rather than merely
-- checking that its tuning constant was changed.
local tight=ready()
tight.steering=1
local normal=P.step(tight,leftInput,dt,open)
local wide=P.step(tight,{accelerate=true,left=true,drift=true},dt,open)
local normalYaw,driftYaw=normal.heading-tight.heading,wide.heading-tight.heading
close(driftYaw/normalYaw,0.75,"drift uses a wider, gentler turn than normal steering")
assert(wide.drifting and wide.speed==normal.speed,"wider drift does not reduce straight-line speed")
local wall={spawn=open.spawn,isDrivable=function() return false end}
local hit=P.step(charged,leftInput,dt,wall)
assert(hit.impacts==charged.impacts+1 and hit.steering==0,"collision resets progressive steering")
local grass={spawn=open.spawn,isDrivable=function() return false end,surfaceAt=function() return "grass" end,
             constrainPosition=function(x,y) return x,y,false end}
local offRoad=P.step(charged,{accelerate=true,left=true,drift=true},dt,grass)
assert(offRoad.steering==1 and not offRoad.drifting and offRoad.boostTicks==0,
    "grass retains steering for recovery while clearing drift")

-- Identical seed and input vectors must reproduce all state at each fixed tick.
local fields={"x","y","heading","speed","tick","impacts","drifting","driftDirection",
              "driftTicks","driftTier","boostTicks","slipAngle","surface","steering","driftGraceTicks"}
local function tapeFor(seed)
    local tape={}
    for tick=1,360 do
        local phase=(tick-1)%60
        if phase==0 then seed=(seed*48271)%2147483647 end
        local sign=seed%2==0 and 1 or -1
        local turn=phase<32 and sign or (phase>=36 and phase<56 and -sign or 0)
        tape[tick]={accelerate=true,left=turn==1 or phase>=56,right=turn==-1 or phase>=56,
                    drift=phase>=8 and phase<54}
    end
    return tape
end
local tape,repeated=tapeFor(1729),tapeFor(1729)
local reference,state={},ready()
for tick=1,#tape do
    state=P.step(state,tape[tick],dt,open)
    assert(state.steering>=-1 and state.steering<=1,"steering remains bounded throughout the tape")
    reference[tick]=state
end
for _,fps in ipairs({30,60,144}) do
    local clock,replay=L.new(dt,5),ready()
    for _=1,#tape*fps/60 do
        L.advance(clock,1/fps,function(stepDt)
            local tick=replay.tick+1
            replay=P.step(replay,repeated[tick],stepDt,open)
            for _,field in ipairs(fields) do
                assert(replay[field]==reference[tick][field],"steering replay differs: "..fps.." FPS "..field.." tick "..tick)
            end
        end)
    end
    assert(replay.tick==#tape and clock.droppedSeconds==0,"steering tape consumes exact fixed ticks")
end
print("steering: full=8 ticks neutral=4 ticks reversal=12 ticks; drift yaw=75% normal; 360-tick seeded cadence replay")
