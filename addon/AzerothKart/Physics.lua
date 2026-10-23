-- Local arcade handling prototype, not production race simulation.
-- Pure Lua: takes explicit state, input, timestep, track.
local _, namespace = ...

local Physics = {}
Physics.VERSION = 9
Physics.FIXED_DT = 1/60
Physics.MAX_SPEED = 200
Physics.REVERSE_MAX = 55
Physics.ACCEL = 155
Physics.BRAKE = 260
Physics.COAST = 78
Physics.STEER_RATE = 2.6
Physics.STEERING_RISE_RATE = 8
Physics.STEERING_CENTER_RATE = 16
Physics.LOW_SPEED_STEER_BONUS = 1.2
Physics.LOW_SPEED_STEER_LIMIT = 80
Physics.WALL_SCRAPE_DRAG = 40
Physics.WALL_SPEED_RETAIN = 0.95
Physics.DRIFT_MIN_SPEED = 90
Physics.DRIFT_TIER1_TICKS = 30
Physics.DRIFT_TIER2_TICKS = 60
Physics.DRIFT_GRACE_TICKS = 12
Physics.BOOST_TIER1_TICKS = 30
Physics.BOOST_TIER2_TICKS = 48
Physics.BOOST_MAX_SPEED = 260
Physics.BOOST_ACCEL = 300
Physics.DRIFT_STEER_MULTIPLIER = 0.75
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
        drifting=false, driftDirection=0, driftTicks=0, driftTier=0, driftGraceTicks=0,
        boostTicks=0, slipAngle=0, surface=surfaceAt(track,start.x,start.y), steering=0,
    }
end

local function normalizedControls(input)
    input = input or {}
    return not not input.accelerate, not not input.brake,
           (input.left and 1 or 0) + (input.right and -1 or 0),
           not not input.drift, not not (input.left and input.right)
end

function Physics.step(state, input, dt, track)
    assert(state and track, "state and track required")
    dt = dt or Physics.FIXED_DT
    assert(dt > 0 and dt <= 0.05, "unexpected physics timestep")
    local accel, brake, steer, driftHeld, opposing = normalizedControls(input)
    local steering = math.max(-1,math.min(1,state.steering or 0))
    if opposing then
        -- Explicit opposing keys cancel immediately, even after a held turn.
        steering = 0
    elseif steer == 0 or steering * steer < 0 then
        -- Finish centering on this tick; a reversal builds its new sign next tick.
        steering = approachZero(steering,Physics.STEERING_CENTER_RATE*dt)
    else
        steering = approach(steering,steer,Physics.STEERING_RISE_RATE*dt)
    end
    local startSurface = surfaceAt(track,state.x,state.y)
    local speed = state.speed
    if accel then speed = speed + Physics.ACCEL * dt end
    if brake then speed = speed - Physics.BRAKE * dt end
    if not accel and not brake then speed = approachZero(speed, Physics.COAST*dt) end
    local boostTicks = state.boostTicks or 0
    if brake or startSurface ~= "road" then boostTicks = 0 end

    -- Charge counts fixed simulation ticks, never render frames or wall time.
    -- Brief corrections pause an existing charge; only actual single-direction
    -- steering earns more. The bounded grace cannot bank charge on a straight.
    -- Space release may pay a held charge during that correction window.
    local drifting, direction, driftTicks, tier, grace = false, 0, 0, 0, 0
    local eligible = startSurface == "road" and not brake and speed >= Physics.DRIFT_MIN_SPEED
    local charging = eligible and steering * steer > 0
    local wasDrifting = state.drifting == true
    if wasDrifting and eligible then
        if not driftHeld then
            if (state.driftTier or 0) > 0 then
                boostTicks = math.max(boostTicks, state.driftTier == 2 and
                    Physics.BOOST_TIER2_TICKS or Physics.BOOST_TIER1_TICKS)
            end
        elseif charging then
            drifting, direction = true, steer
            driftTicks = math.min(Physics.DRIFT_TIER2_TICKS, (state.driftTicks or 0) + 1)
        elseif (state.driftGraceTicks or 0) < Physics.DRIFT_GRACE_TICKS then
            drifting, direction = true, state.driftDirection
            driftTicks = state.driftTicks or 0
            grace = (state.driftGraceTicks or 0) + 1
        end
    elseif driftHeld and charging then
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
    -- Parking/recovery turns get help that fades out before drift speed.
    -- Racing-speed and drift yaw retain their existing response.
    local parkingAssist = Physics.LOW_SPEED_STEER_BONUS *
        (1-math.min(1,math.abs(speed)/Physics.LOW_SPEED_STEER_LIMIT))
    local yaw = (Physics.STEER_RATE * (0.28 + speedRatio * 0.72) + parkingAssist) * dt
    if drifting then yaw = yaw * Physics.DRIFT_STEER_MULTIPLIER end
    if speed < 0 then yaw = -yaw end
    local heading = state.heading + steering * yaw
    local slip = state.slipAngle or 0
    if drifting and grace == 0 then
        slip = approach(slip, direction * Physics.MAX_SLIP_ANGLE, Physics.SLIP_BUILD_RATE * dt)
    else
        slip = approachZero(slip, Physics.SLIP_RECOVER_RATE * dt)
    end
    local travelHeading = heading - slip
    -- x points right, y points up; (cos,sin) is forward.
    local nx = state.x + math.cos(travelHeading) * speed * dt
    local ny = state.y + math.sin(travelHeading) * speed * dt
    local targetX,targetY = nx,ny
    local hit
    if track.resolveMovement then
        -- Optional swept solids receive the whole fixed-step segment. The
        -- render pose is never used for collision or written back into it.
        nx,ny,hit = track.resolveMovement(state.x,state.y,nx,ny)
    elseif track.constrainPosition then
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
        -- Geometry has already removed blocked displacement. Charge the
        -- initial loss once according to permitted movement, then use a
        -- time-scaled scrape drag while contact persists. Repeated glances
        -- must not compound a 75% speed cut or prevent steering from building.
        local dx,dy = targetX-state.x,targetY-state.y
        local mx,my = nx-state.x,ny-state.y
        local requestedSquared,movedSquared = dx*dx+dy*dy,mx*mx+my*my
        if requestedSquared<=1e-12 or movedSquared<=1e-12 then
            speed = 0 -- A fully blocked frontal/corner hit cannot drive through.
        elseif state.surface~="wall" then
            -- Recovery from an invalid pose may move further than requested;
            -- it must never award speed or count as a larger impact reward.
            speed = speed * math.min(1,math.sqrt(movedSquared/requestedSquared)) * Physics.WALL_SPEED_RETAIN
        else
            speed = approachZero(speed,Physics.WALL_SCRAPE_DRAG*dt)
        end
        -- A small contact ceiling makes wall riding slower even under full
        -- throttle, without multiplying the impact penalty every fixed tick.
        speed = math.max(-Physics.REVERSE_MAX*Physics.WALL_SPEED_RETAIN,
            math.min(Physics.MAX_SPEED*Physics.WALL_SPEED_RETAIN,speed))
        drifting, direction, driftTicks, tier, boostTicks, slip = false, 0, 0, 0, 0, 0
        grace = 0
    end
    if surface ~= "road" then
        if startSurface == "road" then speed = grassSpeed(speed,dt) end
        -- Crossing into grass cancels even a charged release on this step.
        drifting, direction, driftTicks, tier, boostTicks, slip = false, 0, 0, 0, 0, 0
        grace = 0
    end

    return {
        x=nx, y=ny, heading=heading, speed=speed,
        tick=state.tick+1, impacts=state.impacts + (hit and 1 or 0),
        drifting=drifting, driftDirection=direction, driftTicks=driftTicks, driftTier=tier,
        driftGraceTicks=grace,
        boostTicks=boostTicks, slipAngle=slip, surface=hit and "wall" or surface, steering=steering,
    }
end

if type(namespace) == "table" then namespace.Physics = Physics end
return Physics
