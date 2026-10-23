-- Regressions for useful wall sliding and recovery, not client-feel acceptance.
local P=dofile("addon/AzerothKart/Physics.lua")
local T=dofile("addon/AzerothKart/Track.lua")
local C=dofile("addon/AzerothKart/Circuit.lua")
local M=dofile("addon/AzerothKart/MirageRaceway.lua").new(T.crossesGate)
local D=dofile("addon/AzerothKart/CapitalCities.lua")
local Loop=dofile("addon/AzerothKart/Loop.lua")
local dt=P.FIXED_DT
local function near(a,b,message)
    assert(math.abs(a-b)<1e-8,message)
end
local function placed(track,x,y,heading,speed)
    local state=P.new(track)
    state.x,state.y,state.heading,state.speed=x,y,heading,speed
    state.surface=track.surfaceAt and track.surfaceAt(x,y) or "road"
    return state
end
local function advance(state,input,track,ticks)
    for _=1,ticks do state=P.step(state,input,dt,track) end
    return state
end
local square=C.new({id="slide_test",width=400,height=400,wallInset=6,
    roadRadius=20,wallRadius=30,fullSpeedToWalls=true,
    centerline={{x=100,y=100},{x=300,y=100},{x=300,y=300},{x=100,y=300}},
    gates={{name="Start",ax=200,ay=80,bx=200,by=120,nx=1,ny=0}},
    spawn={x=200,y=100,heading=0}},T.crossesGate)

-- A road-only city wall keeps useful travel for many consecutive contacts.
-- This fails the old quarter-speed-every-tick response by a wide margin.
local upper=placed(square,200,129.999,math.pi/4,200)
local lower=placed(square,200,70.001,-math.pi/4,200)
upper=advance(upper,{accelerate=true},square,30)
lower=advance(lower,{accelerate=true},square,30)
assert(upper.impacts==30 and upper.speed>130 and upper.x>250,
    "a sustained 45-degree wall slide keeps moving instead of sticking")
near(upper.x,lower.x,"opposite walls retain mirrored forward travel")
near(upper.y+lower.y,200,"opposite walls retain mirrored contact positions")
near(upper.speed,lower.speed,"opposite walls retain mirrored speed")
assert(square.surfaceAt(upper.x,upper.y)=="road" and upper.y<=130,
    "the slide keeps the original city wall and full road grip")

local graze=placed(square,200,129.999,math.pi/12,200)
graze=advance(graze,{accelerate=true},square,20)
assert(graze.speed>180 and graze.speed<=190 and graze.x>260 and graze.impacts==20,
    "sustained shallow contact stays mobile but cannot regain full road speed")
local brushStart=placed(square,200,129.999,math.pi/60,200)
local brush=P.step(brushStart,{accelerate=true},dt,square)
assert(brush.speed>180 and brush.speed<=190 and brush.steering==brushStart.steering,
    "a very shallow first brush has a small noticeable penalty without losing control")
local clean=placed(square,200,100,math.pi/60,200)
clean=P.step(clean,{accelerate=true},dt,square)
assert(clean.speed==200 and brush.speed<clean.speed*0.96 and brush.speed>clean.speed*0.90,
    "the new contact penalty is small and applies only on contact")
local clear=P.step(placed(square,250,130,-math.pi/4,190),{accelerate=true},dt,square)
assert(clear.impacts==0 and clear.speed>190,
    "leaving the wall immediately releases the contact speed ceiling")

-- The same center sweep remains useful against an actual Test Oval crate.
local solid=placed(T,252,390,math.pi/4,200)
solid=advance(solid,{accelerate=true},T,15)
assert(solid.x==252 and solid.y>415 and solid.speed>130 and solid.impacts==15,
    "an actual solid face permits a sustained glancing slide")
local away=P.step(placed(T,252,410,math.pi,100),{accelerate=true},dt,T)
assert(away.x<252 and away.impacts==0,
    "moving away from a solid face is immediately free")

-- Perimeter walls are still walls on both track implementations. Their
-- existing rough-ground cap is separate from collision tuning.
for _,track in ipairs({T,M}) do
    local boundary=track.width-track.wallInset
    local side=placed(track,boundary,240,5*math.pi/12,200)
    side=advance(side,{accelerate=true},track,30)
    assert(side.x==boundary and side.y>290 and side.speed>60 and side.impacts==30,
        track.id..": a perimeter brush slides with its existing rough grip")
    local frontal=P.step(placed(track,boundary,240,0,200),{accelerate=true},dt,track)
    assert(frontal.x==boundary and frontal.y==240 and frontal.speed==0,
        track.id..": a completely blocked frontal hit stops")
    local corner=P.step(placed(track,boundary,track.height-track.wallInset,math.pi/4,200),
        {accelerate=true},dt,track)
    assert(corner.speed==0 and corner.impacts==1,
        track.id..": a fully blocked corner stops once without penetration")
end

-- Reverse slides retain their sign, and releasing throttle cannot create
-- speed through contact. Use the normal reverse cap, not an invalid -200.
local reverse=placed(square,200,129.999,-3*math.pi/4,-P.REVERSE_MAX)
for _=1,20 do
    reverse=P.step(reverse,{brake=true},dt,square)
    assert(reverse.speed<=0 and reverse.speed>=-52.25,
        "a reverse wall slide remains signed with the same small contact penalty")
end
assert(reverse.x>210 and reverse.impacts==20,
    "reverse motion can slide along the same wall")
local coast=placed(square,200,129.999,math.pi/4,160)
for _=1,20 do
    local before=coast
    coast=P.step(coast,{},dt,square)
    assert(coast.speed>=0 and coast.speed<=before.speed,
        "neither an initial nor persistent wall contact adds coasting energy")
    assert(before.tick+1==coast.tick,"contact consumes exactly one fixed tick")
end

-- The actual Stormwind wall uses exposed union geometry rather than a
-- synthetic straight boundary. This owner-visible type must also stay mobile.
local city=C.new(D.stormwind_city,T.crossesGate)
local cityStart=placed(city,1425.861093044,729.801009360,0.974798895,200)
local citySlide=advance(cityStart,{accelerate=true},city,30)
assert(citySlide.impacts>20 and citySlide.speed>100
    and (citySlide.x-cityStart.x)^2+(citySlide.y-cityStart.y)^2>35^2,
    "an exposed Stormwind wall keeps an angled kart moving")
assert(city.surfaceAt(citySlide.x,citySlide.y)=="road",
    "the real city slide cannot cross the wall or enter a hidden slow strip")

-- Retaining progressive steering makes a head-on contact escapable with
-- throttle and a turn; reversing or rewriting the heading is unnecessary.
local recovery=placed(T,252,410,0,200)
local releaseTick
for tick=1,75 do
    recovery=P.step(recovery,{accelerate=true,left=true},dt,T)
    if recovery.surface~="wall" and not releaseTick then releaseTick=tick end
    assert(recovery.speed>=0,"the recovery tape never reverses")
    assert(not (recovery.x>252 and recovery.x<320 and recovery.y>382 and recovery.y<442),
        "turning out of contact never penetrates the expanded solid")
end
assert(releaseTick and releaseTick<=65 and recovery.steering==1 and recovery.y>440,
    "held throttle/turn escapes the solid within the bounded recovery window")

local open={spawn=function() return {x=0,y=0,heading=0} end,
    isDrivable=function() return true end}
local stationary=P.new(open)
stationary=advance(stationary,{left=true},open,60)
assert(stationary.x==0 and stationary.y==0 and stationary.speed==0,
    "stationary turn assistance adds no translation")
assert(stationary.heading>math.pi/2 and stationary.heading<2.1,
    "one second of stationary steering turns through a useful bounded angle")
for _,speed in ipairs({90,200}) do
    local fast=P.new(open)
    fast.speed,fast.steering=speed,1
    local turned=P.step(fast,{},dt,open)
    local expected=turned.steering*P.STEER_RATE*(0.28+math.abs(turned.speed)/P.MAX_SPEED*0.72)*dt
    near(turned.heading,expected,"racing-speed yaw is unchanged")
end

-- Repeated seeded inputs reproduce every unchanged state field, even when
-- presentation delivers the fixed ticks at different frame cadences.
local fields={"x","y","heading","speed","tick","impacts","drifting","driftDirection",
    "driftTicks","driftTier","boostTicks","slipAngle","surface","steering","driftGraceTicks"}
local function tapeFor(seed)
    local tape={}
    for tick=1,240 do
        seed=seed*48271%2147483647
        tape[tick]={accelerate=true,left=tick>45 and seed%7<2,
            right=tick>45 and seed%7>4,drift=seed%11<7}
    end
    return tape
end
local tape,repeated=tapeFor(1729),tapeFor(1729)
local function initial() return placed(square,200,129.999,math.pi/4,200) end
local reference,state={},initial()
for tick=1,#tape do
    state=P.step(state,tape[tick],dt,square)
    reference[tick]=state
end
assert(reference[30].impacts==30,"the deterministic tape actually exercises persistent contact")
for _,fps in ipairs({30,144}) do
    local clock,replay=Loop.new(dt,5),initial()
    for _=1,#tape*fps/60 do
        Loop.advance(clock,1/fps,function(stepDt)
            local tick=replay.tick+1
            replay=P.step(replay,repeated[tick],stepDt,square)
            for _,field in ipairs(fields) do
                assert(replay[field]==reference[tick][field],
                    "wall-slide cadence changed "..field.." at tick "..tick)
            end
        end)
    end
    assert(replay.tick==#tape and clock.droppedSeconds==0,"wall-slide cadence consumes the exact tape")
end
print(("wall handling v%d: 45deg/30ticks speed=%.3f travel=%.3f; solid escape=%dticks; stationary60ticks=%.3frad")
    :format(P.VERSION,upper.speed,upper.x-200,releaseTick,stationary.heading))
