-- Fixed-step clock with bounded catch-up and explicit lost-time accounting.
local _, namespace = ...
local Loop = {}

local function finiteNumber(value)
    return type(value) == "number" and value == value and
           value > -math.huge and value < math.huge
end

function Loop.new(dt, maxSteps)
    dt, maxSteps = dt or 1/60, maxSteps or 5
    assert(finiteNumber(dt) and dt > 0, "positive finite timestep required")
    assert(finiteNumber(maxSteps) and maxSteps >= 1 and maxSteps % 1 == 0,
           "positive integer step budget required")
    return {
        dt=dt, maxSteps=maxSteps, accumulator=0,
        frames=0, steps=0, elapsedSeconds=0, droppedSeconds=0, hitchFrames=0,
        maxElapsed=0, lastSteps=0,
    }
end

function Loop.advance(clock, elapsed, stepFn)
    if not finiteNumber(elapsed) or elapsed < 0 then return 0 end
    assert(type(stepFn) == "function", "step callback required")
    clock.frames = clock.frames + 1
    -- Delivered active frame intervals, not wall-clock duration or addon CPU.
    clock.elapsedSeconds = clock.elapsedSeconds + elapsed
    clock.maxElapsed = math.max(clock.maxElapsed, elapsed)
    clock.accumulator = clock.accumulator + elapsed

    -- Floating-point sums at 30/60/144 FPS can fall a few ulps below a tick.
    -- This tolerance is relative to dt and never admits a meaningful extra tick.
    local epsilon = clock.dt * 1e-9
    local available = math.floor((clock.accumulator + epsilon) / clock.dt)
    local count = math.min(available, clock.maxSteps)
    for _=1,count do stepFn(clock.dt) end
    clock.accumulator = clock.accumulator - count * clock.dt
    clock.steps = clock.steps + count
    clock.lastSteps = count

    local dropped = available - count
    if dropped > 0 then
        local seconds
        if available == math.huge then
            -- A finite but absurd elapsed can overflow elapsed/dt. Keep the
            -- clock bounded without turning its accumulator into infinity.
            local remainder = math.fmod(clock.accumulator, clock.dt)
            seconds = clock.accumulator - remainder
            clock.accumulator = remainder
        else
            seconds = dropped * clock.dt
            clock.accumulator = clock.accumulator - seconds
        end
        clock.droppedSeconds = clock.droppedSeconds + seconds
        clock.hitchFrames = clock.hitchFrames + 1
    end
    if clock.accumulator < 0 and clock.accumulator > -epsilon then
        clock.accumulator = 0
    end
    return count
end

if type(namespace) == "table" then namespace.Loop = Loop end
return Loop
