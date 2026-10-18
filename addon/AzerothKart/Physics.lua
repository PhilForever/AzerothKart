-- First game-feel/keyboard probe, not production race simulation.
-- Pure Lua: takes explicit state, input, timestep, track.
local AK = _G.AzerothKart or {}
_G.AzerothKart = AK

local Physics = {}
Physics.VERSION = 1
Physics.FIXED_DT = 1/60
Physics.MAX_SPEED = 200
Physics.REVERSE_MAX = 55
Physics.ACCEL = 155
Physics.BRAKE = 260
Physics.COAST = 78
Physics.STEER_RATE = 2.6

local function approachZero(v, amount)
    if v > 0 then return math.max(0, v-amount) end
    if v < 0 then return math.min(0, v+amount) end
    return 0
end

function Physics.new(track)
    track = assert(track, "track required")
    local start = track.spawn()
    return {x=start.x, y=start.y, heading=start.heading, speed=0, tick=0, impacts=0}
end

local function normalizedControls(input)
    input = input or {}
    return not not input.accelerate, not not input.brake,
           (input.left and -1 or 0) + (input.right and 1 or 0)
end

function Physics.step(state, input, dt, track)
    assert(state and track, "state and track required")
    dt = dt or Physics.FIXED_DT
    assert(dt > 0 and dt <= 0.05, "unexpected physics timestep")
    local accel, brake, steer = normalizedControls(input)
    local speed = state.speed
    if accel then speed = speed + Physics.ACCEL * dt end
    if brake then speed = speed - Physics.BRAKE * dt end
    if not accel and not brake then speed = approachZero(speed, Physics.COAST*dt) end
    speed = math.max(-Physics.REVERSE_MAX, math.min(Physics.MAX_SPEED, speed))

    -- Directional steering; reverse turns opposite. No drifting in M0.
    local speedRatio = math.min(1, math.abs(speed)/Physics.MAX_SPEED)
    local yaw = Physics.STEER_RATE * (0.28 + speedRatio * 0.72) * dt
    if speed < 0 then yaw = -yaw end
    local heading = state.heading + steer * yaw
    -- x points right, y points up; (cos,sin) is forward.
    local nx = state.x + math.cos(heading) * speed * dt
    local ny = state.y + math.sin(heading) * speed * dt
    local hit = not track.isDrivable(nx,ny)
    if hit then
        nx,ny = state.x,state.y
        speed = speed * 0.25
    end

    return {
        x=nx, y=ny, heading=heading, speed=speed,
        tick=state.tick+1, impacts=state.impacts + (hit and 1 or 0),
    }
end

AK.Physics = Physics
return Physics
