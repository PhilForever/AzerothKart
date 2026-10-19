-- Fixed-length solo runs. Pure immutable state, independent of clocks/UI.
local _, namespace = ...
local Race = {}

local function requireLaps(laps)
    assert(type(laps) == "table" and type(laps.new) == "function"
        and type(laps.step) == "function", "lap module required")
end

function Race.new(track, checkpoints, laps, tick)
    requireLaps(laps)
    if tick == nil then tick = 0 end
    return {
        status="running", laps=laps.new(track,checkpoints,tick), targetLaps=3,
        startTick=tick, lastTick=tick, totalTicks=0, finishTick=nil, reason=nil,
    }
end

function Race.step(race, previous, current, track, checkpoints, laps)
    assert(type(race) == "table", "race state required")
    if race.status ~= "running" then return race end
    requireLaps(laps)
    local progress = laps.step(race.laps,previous,current,track,checkpoints)
    if progress == race.laps then return race end
    local finished = progress.completedLaps >= race.targetLaps
    return {
        status=finished and "finished" or "running", laps=progress,
        targetLaps=race.targetLaps, startTick=race.startTick,
        lastTick=current.tick, totalTicks=current.tick-race.startTick,
        finishTick=finished and current.tick or nil,
        reason=finished and "Three-lap run complete" or nil,
    }
end

function Race.stop(race, reason, interrupted)
    assert(type(race) == "table", "race state required")
    if race.status ~= "running" then return race end
    interrupted = interrupted == true
    return {
        status=interrupted and "interrupted" or "stopped", laps=race.laps,
        targetLaps=race.targetLaps, startTick=race.startTick,
        lastTick=race.lastTick, totalTicks=race.totalTicks,
        finishTick=race.finishTick,
        reason=reason or (interrupted and "Game interrupted by combat" or "Stopped"),
    }
end

if type(namespace) == "table" then namespace.Race = Race end
return Race
