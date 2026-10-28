-- Local arcade handling prototype, not production race simulation.
-- Pure Lua: takes explicit state, input, timestep, track.
local _, namespace = ...

local Physics = {}
Physics.VERSION = 12
-- Existing courses retain their replay/score context. New opt-in mechanics
-- have a separate compatibility version without retiming flat driving.
Physics.FEATURE_VERSION = 13
Physics.GRASS_BOOST_VERSION = 14
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
Physics.WALL_SPEED_RETAIN = 0.90
Physics.WALL_SPEED_CAP = 0.80
Physics.DRIFT_MIN_SPEED = 90
Physics.DRIFT_TIER1_TICKS = 30
Physics.DRIFT_TIER2_TICKS = 60
Physics.DRIFT_GRACE_TICKS = 12
Physics.BOOST_TIER1_TICKS = 48
Physics.BOOST_TIER2_TICKS = 78
Physics.BOOST_MAX_SPEED = 260
Physics.BOOST_ACCEL = 420
Physics.DRIFT_STEER_MULTIPLIER = 0.75
Physics.MAX_SLIP_ANGLE = 0.40
Physics.SLIP_BUILD_RATE = 1.8
Physics.SLIP_RECOVER_RATE = 3.0
Physics.GRASS_MAX_SPEED = 70
Physics.GRASS_REVERSE_MAX = 30
Physics.GRASS_DRAG = 360

-- Private handling data: never accept mutable parameter tables from UI/network.
-- All profiles share body geometry, boost/drift rewards, reverse and wall rules.
local profiles = {
    balanced={id="balanced", name="Balanced", maxSpeed=200, accel=155, brake=260,
        steerRate=2.6, steeringRiseRate=8, maxSlipAngle=0.40, slipRecoverRate=3},
    heavy={id="heavy", name="Heavy", maxSpeed=208, accel=142.6, brake=280.8,
        steerRate=2.392, steeringRiseRate=6.8, maxSlipAngle=0.36, slipRecoverRate=3.3},
    agile={id="agile", name="Agile", maxSpeed=192, accel=167.4, brake=239.2,
        steerRate=2.808, steeringRiseRate=9.2, maxSlipAngle=0.44, slipRecoverRate=2.7},
}
local kartProfiles = {
    basic="balanced", goblin_mortar_trike="balanced", dwarf_car="balanced",
    glaive_thrower="balanced", goblin_drag_car="balanced",
    steam_tank="heavy", orc_demolisher="heavy", meat_wagon="heavy",
    dwarven_biker="agile", gryphon_rider="agile", gyrocopter="agile",
}
local function handlingFor(kartId)
    if kartId == nil then return profiles.balanced end
    if type(kartId) ~= "string" then return nil end
    return profiles[kartProfiles[kartId]]
end

-- Detached values for menu/diagnostics. Calling this never changes active runs.
function Physics.GetHandling(kartId)
    local profile = handlingFor(kartId)
    if not profile then return nil, "invalid_kart" end
    local copy = {}
    for key, value in pairs(profile) do copy[key] = value end
    return copy
end

local function approachZero(v, amount)
    if v > 0 then return math.max(0, v-amount) end
    if v < 0 then return math.min(0, v+amount) end
    return 0
end

local function approach(value, target, amount)
    if value < target then return math.min(target, value + amount) end
    return math.max(target, value - amount)
end

local function finite(value)
    return type(value)=="number" and value==value and value>-math.huge and value<math.huge
end

local function validLevel(track, level)
    return finite(level) and level%1==0 and level>=0 and level<=1
        and (not track.validLevel or track.validLevel(level)==true)
end

function Physics.versionForTrack(track)
    if type(track)=="table" and track.boostOnGrass==true then return Physics.GRASS_BOOST_VERSION end
    return type(track)=="table" and (track.layered==true
        or (type(track.pads)=="table" and next(track.pads)~=nil))
        and Physics.FEATURE_VERSION or Physics.VERSION
end

-- Track construction validates author data once. Runtime pad scans are
-- bounded and read-only; no per-kart mutable pad/contact registry is needed.
function Physics.ValidatePads(pads)
    if pads==nil then return true end
    if type(pads)~="table" or getmetatable(pads)~=nil or #pads>32 then return false,"pads" end
    local count,ids=0,{}
    for index,pad in pairs(pads) do
        count=count+1
        if type(index)~="number" or index%1~=0 or index<1 or index>#pads
            or type(pad)~="table" or getmetatable(pad)~=nil
            or type(pad.id)~="string" or #pad.id<1 or #pad.id>32
            or not pad.id:match("^[A-Za-z0-9_%-]+$") or ids[pad.id]
            or not finite(pad.x) or pad.x<0 or pad.x>11663.75
            or not finite(pad.y) or pad.y<0 or pad.y>11663.75
            or not finite(pad.radius) or pad.radius<1 or pad.radius>256
            or not finite(pad.boostTicks) or pad.boostTicks%1~=0 or pad.boostTicks<1 or pad.boostTicks>600
            or (pad.level~=nil and (not finite(pad.level) or pad.level%1~=0 or pad.level<0 or pad.level>1)) then
            return false,"pad"
        end
        ids[pad.id]=true
    end
    if count~=#pads then return false,"pads" end
    return true
end

local function surfaceAt(track, x, y, level)
    if track.surfaceAt then
        if track.layered==true then return track.surfaceAt(x,y,level) end
        return track.surfaceAt(x,y)
    end
    -- Small open-plane/solid-wall fixtures can retain the original contract.
    if track.layered==true then return track.isDrivable(x,y,level) and "road" or "wall" end
    return track.isDrivable(x,y) and "road" or "wall"
end

local function entersPad(pad,x,y,nx,ny,alreadyOnLevel)
    local dx,dy=x-pad.x,y-pad.y
    local radiusSquared=pad.radius*pad.radius
    if alreadyOnLevel and dx*dx+dy*dy<=radiusSquared then return false end
    local sx,sy=nx-x,ny-y
    local lengthSquared=sx*sx+sy*sy
    local at=lengthSquared>0 and math.max(0,math.min(1,-(dx*sx+dy*sy)/lengthSquared)) or 0
    dx,dy=dx+sx*at,dy+sy*at
    return dx*dx+dy*dy<=radiusSquared
end

local function enteredBoost(track,x,y,nx,ny,oldLevel,newLevel,switchX,switchY)
    local reward=0
    for _,pad in ipairs(track.pads or {}) do
        local level=pad.level or 0
        local entered=false
        if oldLevel==newLevel then
            entered=level==oldLevel and entersPad(pad,x,y,nx,ny,true)
        else
            assert(finite(switchX) and finite(switchY),"level transition requires a pad movement split")
            entered=(level==oldLevel and entersPad(pad,x,y,switchX,switchY,true))
                or (level==newLevel and entersPad(pad,switchX,switchY,nx,ny,false))
        end
        if entered then reward=math.max(reward,pad.boostTicks) end
    end
    return reward
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
    assert(Physics.ValidatePads(track.pads),"invalid boost pads")
    local start = track.spawn()
    local level=start.level
    if level==nil then level=0 end
    if track.layered==true then assert(validLevel(track,level),"invalid spawn level") end
    for _,pad in ipairs(track.pads or {}) do
        assert(pad.level==nil or pad.level==0 or (track.layered==true and validLevel(track,pad.level)),
            "boost pad level unavailable")
    end
    local state = {
        x=start.x, y=start.y, heading=start.heading, speed=0, tick=0, impacts=0,
        drifting=false, driftDirection=0, driftTicks=0, driftTier=0, driftGraceTicks=0,
        boostTicks=0, slipAngle=0, surface=surfaceAt(track,start.x,start.y,level), steering=0,
    }
    if track.layered==true then state.level=level end
    return state
end

local function normalizedControls(input)
    input = input or {}
    return not not input.accelerate, not not input.brake,
           (input.left and 1 or 0) + (input.right and -1 or 0),
           not not input.drift, not not (input.left and input.right)
end

function Physics.step(state, input, dt, track, kartId)
    assert(state and track, "state and track required")
    local handling = assert(handlingFor(kartId), "unknown kart handling")
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
        steering = approach(steering,steer,handling.steeringRiseRate*dt)
    end
    local level=0
    if track.layered==true then
        level=state.level
        if level==nil then level=0 end
    end
    if track.layered==true then assert(validLevel(track,level),"invalid kart level") end
    local oldLevel=level
    local startSurface = surfaceAt(track,state.x,state.y,level)
    local speed = state.speed
    if accel then speed = speed + handling.accel * dt end
    if brake then speed = speed - handling.brake * dt end
    if not accel and not brake then speed = approachZero(speed, Physics.COAST*dt) end
    local boostTicks = state.boostTicks or 0
    local grassBoost = track.boostOnGrass==true
    if brake or (startSurface ~= "road" and not (grassBoost and startSurface == "grass")) then boostTicks = 0 end

    -- Charge counts fixed simulation ticks, never render frames or wall time.
    -- Brief corrections pause an existing charge; only actual single-direction
    -- steering earns more. The bounded grace cannot bank charge on a straight.
    -- Space release may pay a held charge during that correction window.
    local drifting, direction, driftTicks, tier, grace = false, 0, 0, 0, 0
    -- Charging resumes after boost expires; longer rewards must not recharge
    -- themselves behind the boost meter into continuous turbo.
    local eligible = startSurface == "road" and not brake and boostTicks == 0
        and speed >= Physics.DRIFT_MIN_SPEED
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
        local speedCap = boosting and Physics.BOOST_MAX_SPEED or handling.maxSpeed
        speed = math.max(-Physics.REVERSE_MAX, math.min(speedCap, speed))
    elseif grassBoost and startSurface == "grass" and boosting then
        speed = math.max(-Physics.REVERSE_MAX, math.min(handling.maxSpeed, speed))
    else
        speed = grassSpeed(speed,dt)
    end
    -- The release step is the first boosted step; the returned count is the
    -- number remaining. Holding drift cannot repeatedly award the charge.
    if boosting then boostTicks = boostTicks - 1 end

    -- Directional steering; reverse turns opposite. Slip separates the kart's
    -- facing direction from travel direction for an actual bounded slide.
    local speedRatio = math.min(1, math.abs(speed)/handling.maxSpeed)
    -- Parking/recovery turns get help that fades out before drift speed.
    -- Racing-speed and drift yaw retain their existing response.
    local parkingAssist = Physics.LOW_SPEED_STEER_BONUS *
        (1-math.min(1,math.abs(speed)/Physics.LOW_SPEED_STEER_LIMIT))
    local yaw = (handling.steerRate * (0.28 + speedRatio * 0.72) + parkingAssist) * dt
    if drifting then yaw = yaw * Physics.DRIFT_STEER_MULTIPLIER end
    if speed < 0 then yaw = -yaw end
    local heading = state.heading + steering * yaw
    local slip = state.slipAngle or 0
    if drifting and grace == 0 then
        slip = approach(slip, direction * handling.maxSlipAngle, Physics.SLIP_BUILD_RATE * dt)
    else
        slip = approachZero(slip, handling.slipRecoverRate * dt)
    end
    local travelHeading = heading - slip
    -- x points right, y points up; (cos,sin) is forward.
    local nx = state.x + math.cos(travelHeading) * speed * dt
    local ny = state.y + math.sin(travelHeading) * speed * dt
    local targetX,targetY = nx,ny
    local hit,switchX,switchY
    if track.resolveMovement then
        -- Optional swept solids receive the whole fixed-step segment. The
        -- render pose is never used for collision or written back into it.
        if track.layered==true then
            local resolvedLevel
            nx,ny,hit,resolvedLevel,switchX,switchY = track.resolveMovement(state.x,state.y,nx,ny,level)
            if resolvedLevel~=nil then level=resolvedLevel end
            assert(validLevel(track,level),"invalid resolved level")
        else nx,ny,hit = track.resolveMovement(state.x,state.y,nx,ny) end
    elseif track.constrainPosition then
        -- Clamp each axis, preserving any valid tangential displacement.
        nx,ny,hit = track.constrainPosition(nx,ny)
    else
        hit = surfaceAt(track,nx,ny,level) == "wall"
        if hit then nx,ny = state.x,state.y end
    end
    local surface = surfaceAt(track,nx,ny,level)
    local protectedGrass = grassBoost and surface == "grass" and boosting and not hit
    if boosting and (hit or (surface ~= "road" and not protectedGrass)) then
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
        speed = math.max(-Physics.REVERSE_MAX*Physics.WALL_SPEED_CAP,
            math.min(handling.maxSpeed*Physics.WALL_SPEED_CAP,speed))
        drifting, direction, driftTicks, tier, boostTicks, slip = false, 0, 0, 0, 0, 0
        grace = 0
    end
    if surface ~= "road" then
        if protectedGrass then
            -- The final active boost tick still protects the kart. Its road
            -- speed cap is per handling profile; it never increases speed.
            speed = math.max(-Physics.REVERSE_MAX, math.min(handling.maxSpeed, speed))
        else
            if startSurface == "road" or (grassBoost and startSurface == "grass" and boosting) then
                speed = grassSpeed(speed,dt)
            end
            boostTicks = 0
        end
        -- Grass never permits drift charging, even while a boost is active.
        drifting, direction, driftTicks, tier, slip = false, 0, 0, 0, 0
        grace = 0
    end

    -- Pad entry is determined from resolved movement, not intended travel
    -- through a wall. The reward begins on the next fixed step; collision,
    -- braking and non-road cancellation keep their existing precedence.
    if track.pads and not brake and not hit and surface=="road" then
        boostTicks=math.max(boostTicks,enteredBoost(track,state.x,state.y,nx,ny,oldLevel,level,switchX,switchY))
    end
    local nextState = {
        x=nx, y=ny, heading=heading, speed=speed,
        tick=state.tick+1, impacts=state.impacts + (hit and 1 or 0),
        drifting=drifting, driftDirection=direction, driftTicks=driftTicks, driftTier=tier,
        driftGraceTicks=grace,
        boostTicks=boostTicks, slipAngle=slip, surface=hit and "wall" or surface, steering=steering,
    }
    if track.layered==true then nextState.level=level end
    return nextState
end

if type(namespace) == "table" then namespace.Physics = Physics end
return Physics
