-- A repeatable clean-line reward comparison, not a shipped AI or human lap claim.
-- All three runs use the same ellipse/steering policy and actual track/gates.
local Track=dofile("addon/AzerothKart/Track.lua")
local Checkpoints=dofile("addon/AzerothKart/Checkpoints.lua")
local Laps=dofile("addon/AzerothKart/Laps.lua")
local Race=dofile("addon/AzerothKart/Race.lua")
local atan2=math.atan2 or math.atan
local function run(driftEnabled,priorReward)
    -- A fresh module owns its own constants/closures. The reward-only reference
    -- keeps current geometry, kart profile and steering; it is not an old build.
    local P=dofile("addon/AzerothKart/Physics.lua")
    assert(P.BOOST_TIER1_TICKS>30 and P.BOOST_TIER2_TICKS>48 and P.BOOST_ACCEL>=300,
        "payoff fixture targets stronger rewards than the prior 30/48-tick boost")
    if priorReward then
        P.BOOST_TIER1_TICKS,P.BOOST_TIER2_TICKS,P.BOOST_ACCEL=30,48,300
    end
    local state=P.new(Track)
    local race=Race.newRunning(Track,Checkpoints,Laps,0)
    local roughTicks,boostedTicks,boosts,distance=0,0,0,0
    local radiusX,radiusY,lookAhead=250,140,150
    for tick=1,5000 do
        -- Follow one intended ellipse. A look-ahead point and a small steering
        -- prediction keep the digital-input controller smooth without braking.
        -- Slip compensation follows the same travel line rather than treating
        -- a sideways-facing kart as if its heading were its velocity direction.
        local angle=atan2((state.y-Track.centerY)/radiusY,
            (state.x-Track.centerX)/radiusX)
        local tangent=math.sqrt((radiusX*math.sin(angle))^2+(radiusY*math.cos(angle))^2)
        local target=angle+lookAhead/tangent
        local x=Track.centerX+radiusX*math.cos(target)
        local y=Track.centerY+radiusY*math.sin(target)
        local error=(atan2(y-state.y,x-state.x)+state.slipAngle
            -state.heading-state.steering*0.16+math.pi)%(2*math.pi)-math.pi
        local previous=state
        state=P.step(state,{
            accelerate=true,left=error>0.025,right=error< -0.025,
            -- Spend tier two immediately, then hold no new charge during boost.
            drift=driftEnabled and state.boostTicks==0 and state.driftTier<2,
        },P.FIXED_DT,Track,"goblin_mortar_trike")
        race=Race.step(race,previous,state,Track,Checkpoints,Laps)
        if state.surface=="grass" then roughTicks=roughTicks+1 end
        if state.boostTicks>0 then boostedTicks=boostedTicks+1 end
        if state.boostTicks>previous.boostTicks then boosts=boosts+1 end
        distance=distance+math.sqrt((state.x-previous.x)^2+(state.y-previous.y)^2)
        if race.status=="finished" then
            assert(race.laps.completedLaps==3 and race.totalTicks==tick,
                "each comparison must finish three real ordered checkpoint laps")
            assert(roughTicks==0 and state.impacts==0,
                "grass or collision penalties must not explain this comparison")
            return {ticks=tick,seconds=tick*P.FIXED_DT,boosts=boosts,
                boostedTicks=boostedTicks,distance=distance}
        end
    end
    error("payoff controller did not finish within the bounded fixture")
end

local plain=run(false,false)
local reference=run(true,true)
local improved=run(true,false)
assert(plain.boosts==0 and plain.boostedTicks==0,
    "the non-drifting reference must receive no boost reward")
assert(reference.boosts>0 and improved.boosts>0,
    "both drifting runs must actually charge and release boosts")
assert(improved.boostedTicks>reference.boostedTicks,
    "the longer rewards must provide more useful boosted travel time")
local payoff=(plain.ticks-improved.ticks)/plain.ticks
assert(payoff>=0.02 and payoff<=0.12,
    "this clean-line fixture needs a useful but bounded 2-12% drift payoff")
assert(improved.ticks<reference.ticks,
    "the new reward must outperform the prior reward on the same controller")
-- The steering policy adapts to the resulting handling, so trajectories differ.
-- This fixture establishes one feasible reward, not optimal driving, identical
-- input vectors between modes, multiplayer latency or universal lap balance.
print(("drift payoff, clean Test Oval 3 laps: plain=%d/%.3fs priorReward=%d/%.3fs "..
    "newReward=%d/%.3fs gain=%.2f%% boosts=%d boostedTicks=%d (0 grass/impacts)")
    :format(plain.ticks,plain.seconds,reference.ticks,reference.seconds,
        improved.ticks,improved.seconds,payoff*100,improved.boosts,improved.boostedTicks))
