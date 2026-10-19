-- Repeatable local practice laps. Pure fixed-tick state, independent of clocks/UI.
local _, namespace = ...
local Laps = {}

local function validTick(tick)
    return type(tick) == "number" and tick == tick and tick >= 0
        and tick < math.huge and tick % 1 == 0
end

local function requireCheckpoints(checkpoints)
    assert(type(checkpoints) == "table" and type(checkpoints.new) == "function"
        and type(checkpoints.step) == "function", "checkpoint module required")
end

function Laps.new(track, checkpoints, tick)
    requireCheckpoints(checkpoints)
    if tick == nil then tick = 0 end
    assert(validTick(tick), "nonnegative integer initial tick required")
    return {
        checkpoints=checkpoints.new(track,tick), completedLaps=0,
        lapStartTick=tick, currentLapTicks=0, lastLapTicks=nil,
        lastTick=tick, lastFinishTick=nil,
    }
end

function Laps.step(laps, previous, current, track, checkpoints)
    assert(type(laps) == "table" and type(laps.checkpoints) == "table", "lap state required")
    requireCheckpoints(checkpoints)
    if type(previous) ~= "table" or type(current) ~= "table"
        or not validTick(laps.lastTick) or not validTick(previous.tick) or not validTick(current.tick)
        or previous.tick ~= laps.lastTick or current.tick ~= previous.tick+1
        or laps.checkpoints.lastTick ~= laps.lastTick then return laps end

    local progress = checkpoints.step(laps.checkpoints,previous,current,track)
    -- Checkpoint acceptance is authoritative for the shared consecutive tick.
    -- Invalid positions/long motion still consume a tick there, without awards.
    if progress == laps.checkpoints or type(progress) ~= "table"
        or progress.lastTick ~= current.tick then return laps end
    local finished = progress.complete
        and (laps.lastFinishTick == nil or current.tick > laps.lastFinishTick)
    return {
        checkpoints=finished and checkpoints.new(track,current.tick) or progress,
        completedLaps=laps.completedLaps+(finished and 1 or 0),
        lapStartTick=finished and current.tick or laps.lapStartTick,
        currentLapTicks=finished and 0 or current.tick-laps.lapStartTick,
        lastLapTicks=finished and current.tick-laps.lapStartTick or laps.lastLapTicks,
        lastTick=current.tick,
        lastFinishTick=finished and current.tick or laps.lastFinishTick,
    }
end

if type(namespace) == "table" then namespace.Laps = Laps end
return Laps
