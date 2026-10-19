-- Local arcade handling prototype, not production race simulation.
-- Pure Lua: takes explicit state, input, timestep, track.
local _, namespace = ...

local Physics = {}
Physics.VERSION = 4
Physics.FIXED_DT = 1/60
Physics.MAX_SPEED = 200
Physics.REVERSE_MAX = 55
Physics.ACCEL = 155
Physics.BRAKE = 260
Physics.COAST = 78
Physics.STEER_RATE = 2.6
Physics.DRIFT_MIN_SPEED = 90
Physics.DRIFT_TIER1_TICKS = 54
Physics.DRIFT_TIER2_TICKS = 108
Physics.BOOST_TIER1_TICKS = 30
Physics.BOOST_TIER2_TICKS = 48
Physics.BOOST_MAX_SPEED = 260
Physics.BOOST_ACCEL = 300
Physics.DRIFT_STEER_MULTIPLIER = 1.15
Physics.MAX_SLIP_ANGLE = 0.40
Physics.SLIP_BUILD_RATE = 1.8
Physics.SLIP_RECOVER_RATE = 3.0
Physics.GRASS_MAX_SPEED = 70
Physics.GRASS_REVERSE_MAX = 30
Physics.GRASS_DRAG = 360

local function approachZero(v, amount)
    if v > 0 then return math.max(0, v-amount) end
    if v < 0 then return math.min(0, v+amount) end
    return 0
end

local function approach(value, target, amount)
    if value < target then return math.min(target, value + amount) end
    return math.max(target, value - amount)
end

local function surfaceAt(track, x, y)
    if track.surfaceAt then return track.surfaceAt(x,y) end
    -- Small open-plane/solid-wall fixtures can retain the original contract.
    return track.isDrivable(x,y) and "road" or "wall"
end

local function grassSpeed(speed, dt)
    -- Excess inherited road/boost speed decays instead of snapping to the cap.
    -- Drag exceeds both throttle and braking, including held reverse input.
    if speed > Physics.GRASS_MAX_SPEED then
        return math.max(Physics.GRASS_MAX_SPEED,speed-Physics.GRASS_DRAG*dt)
    elseif speed < -Physics.GRASS_REVERSE_MAX then
        return math.min(-Physics.GRASS_REVERSE_MAX,speed+Physics.GRASS_DRAG*dt)
    end
    return speed
end

function Physics.new(track)
    track = assert(track, "track required")
    local start = track.spawn()
    return {
        x=start.x, y=start.y, heading=start.heading, speed=0, tick=0, impacts=0,
        drifting=false, driftDirection=0, driftTicks=0, driftTier=0,
        boostTicks=0, slipAngle=0, surface=surfaceAt(track,start.x,start.y),
    }
end

local function normalizedControls(input)
    input = input or {}
    return not not input.accelerate, not not input.brake,
           (input.left and 1 or 0) + (input.right and -1 or 0),
           not not input.drift
end

function Physics.step(state, input, dt, track)
    assert(state and track, "state and track required")
    dt = dt or Physics.FIXED_DT
    assert(dt > 0 and dt <= 0.05, "unexpected physics timestep")
    local accel, brake, steer, driftHeld = normalizedControls(input)
    local startSurface = surfaceAt(track,state.x,state.y)
    local speed = state.speed
    if accel then speed = speed + Physics.ACCEL * dt end
    if brake then speed = speed - Physics.BRAKE * dt end
    if not accel and not brake then speed = approachZero(speed, Physics.COAST*dt) end
    local boostTicks = state.boostTicks or 0
    if brake or startSurface ~= "road" then boostTicks = 0 end

    -- Charge counts fixed simulation ticks, never render frames or wall time.
    -- Releasing drift pays only an existing drift with its turn/speed intact.
    local drifting, direction, driftTicks, tier = false, 0, 0, 0
    local eligible = startSurface == "road" and not brake and steer ~= 0
        and speed >= Physics.DRIFT_MIN_SPEED
    local wasDrifting = state.drifting == true
    local sameTurn = state.driftDirection == steer
    if wasDrifting then
        if eligible and sameTurn then
            if driftHeld then
                drifting, direction = true, steer
                driftTicks = math.min(Physics.DRIFT_TIER2_TICKS, (state.driftTicks or 0) + 1)
            elseif (state.driftTier or 0) > 0 then
                boostTicks = math.max(boostTicks, state.driftTier == 2 and
                    Physics.BOOST_TIER2_TICKS or Physics.BOOST_TIER1_TICKS)
            end
        end
    elseif driftHeld and eligible then
        drifting, direction, driftTicks = true, steer, 1
    end
    if driftTicks >= Physics.DRIFT_TIER2_TICKS then tier = 2
    elseif driftTicks >= Physics.DRIFT_TIER1_TICKS then tier = 1 end

    local boosting = boostTicks > 0
    local speedBeforeBoost = speed
    if boosting then speed = speed + Physics.BOOST_ACCEL * dt end
    if startSurface == "road" then
        local speedCap = boosting and Physics.BOOST_MAX_SPEED or Physics.MAX_SPEED
        speed = math.max(-Physics.REVERSE_MAX, math.min(speedCap, speed))
    else
        speed = grassSpeed(speed,dt)
    end
    -- The release step is the first boosted step; the returned count is the
    -- number remaining. Holding drift cannot repeatedly award the charge.
    if boosting then boostTicks = boostTicks - 1 end

    -- Directional steering; reverse turns opposite. Slip separates the kart's
    -- facing direction from travel direction for an actual bounded slide.
    local speedRatio = math.min(1, math.abs(speed)/Physics.MAX_SPEED)
    local yaw = Physics.STEER_RATE * (0.28 + speedRatio * 0.72) * dt
    if drifting then yaw = yaw * Physics.DRIFT_STEER_MULTIPLIER end
    if speed < 0 then yaw = -yaw end
    local heading = state.heading + steer * yaw
    local slip = state.slipAngle or 0
    if drifting then
        slip = approach(slip, direction * Physics.MAX_SLIP_ANGLE, Physics.SLIP_BUILD_RATE * dt)
    else
        slip = approachZero(slip, Physics.SLIP_RECOVER_RATE * dt)
    end
    local travelHeading = heading - slip
    -- x points right, y points up; (cos,sin) is forward.
    local nx = state.x + math.cos(travelHeading) * speed * dt
    local ny = state.y + math.sin(travelHeading) * speed * dt
    local hit
    if track.constrainPosition then
        -- Clamp each axis, preserving any valid tangential displacement.
        nx,ny,hit = track.constrainPosition(nx,ny)
    else
        hit = surfaceAt(track,nx,ny) == "wall"
        if hit then nx,ny = state.x,state.y end
    end
    local surface = surfaceAt(track,nx,ny)
    if boosting and (hit or surface ~= "road") then
        -- Do not retain a release/boost acceleration reward on grass entry.
        speed = math.min(speed,speedBeforeBoost)
    end
    if hit then
        -- One scrub per contact step, even when both axes hit a corner.
        speed = speed * 0.25
        drifting, direction, driftTicks, tier, boostTicks, slip = false, 0, 0, 0, 0, 0
    end
    if surface ~= "road" then
        if startSurface == "road" then speed = grassSpeed(speed,dt) end
        -- Crossing into grass cancels even a charged release on this step.
        drifting, direction, driftTicks, tier, boostTicks, slip = false, 0, 0, 0, 0, 0
    end

    return {
        x=nx, y=ny, heading=heading, speed=speed,
        tick=state.tick+1, impacts=state.impacts + (hit and 1 or 0),
        drifting=drifting, driftDirection=direction, driftTicks=driftTicks, driftTier=tier,
        boostTicks=boostTicks, slipAngle=slip, surface=hit and "wall" or surface,
    }
end

if type(namespace) == "table" then namespace.Physics = Physics end
return Physics
