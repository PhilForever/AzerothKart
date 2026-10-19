-- Ordered local checkpoint progress. Pure fixed-tick state, not a lap engine.
local _, namespace = ...
local Checkpoints = {}

local function finite(value)
    return type(value) == "number" and value == value
        and value > -math.huge and value < math.huge
end

local function validTick(tick)
    return finite(tick) and tick >= 0 and tick % 1 == 0
end

function Checkpoints.new(track, tick)
    assert(type(track) == "table" and type(track.gates) == "table" and #track.gates > 0,
        "ordered track gates required")
    assert(type(track.crossesGate) == "function" and finite(track.checkpointMaxStep)
        and track.checkpointMaxStep > 0, "checkpoint geometry and step bound required")
    if tick == nil then tick = 0 end
    assert(validTick(tick), "nonnegative integer initial tick required")
    return {nextGate=1, passed=0, complete=false, lastTick=tick}
end

function Checkpoints.step(progress, previous, current, track)
    assert(type(progress) == "table" and type(track) == "table", "progress and track required")
    if progress.complete then return progress end
    if type(previous) ~= "table" or type(current) ~= "table"
        or not validTick(previous.tick) or not validTick(current.tick)
        or previous.tick ~= progress.lastTick or current.tick ~= previous.tick+1
        or current.tick <= previous.tick then return progress end

    local nextProgress = {
        nextGate=progress.nextGate, passed=progress.passed, complete=false, lastTick=current.tick,
    }
    -- Consume consecutive malformed/implausible poses without an award. This
    -- prevents a bad movement sample from freezing all later valid progress.
    if not (finite(previous.x) and finite(previous.y) and finite(current.x) and finite(current.y)) then
        return nextProgress
    end
    local dx,dy = current.x-previous.x,current.y-previous.y
    local distanceSquared = dx*dx+dy*dy
    local bound = track.checkpointMaxStep
    if not finite(distanceSquared) or not finite(bound) or bound <= 0
        or distanceSquared > bound*bound then return nextProgress end
    local gate = track.gates[progress.nextGate]
    if track.crossesGate(previous,current,gate) then
        nextProgress.passed = progress.passed+1
        nextProgress.nextGate = progress.nextGate+1
        nextProgress.complete = nextProgress.passed == #track.gates
    end
    return nextProgress
end

if type(namespace) == "table" then namespace.Checkpoints = Checkpoints end
return Checkpoints
