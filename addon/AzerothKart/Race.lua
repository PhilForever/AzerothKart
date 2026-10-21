-- Fixed-length solo runs. Pure immutable state, independent of clocks/UI.
local _, namespace = ...
local Race = {}
Race.COUNTDOWN_TICKS = 180
Race.GO_CUE_TICKS = 60

local function validTick(tick)
    return type(tick) == "number" and tick == tick and tick >= 0
        and tick < math.huge and tick % 1 == 0
end

local function requireLaps(laps)
    assert(type(laps) == "table" and type(laps.new) == "function"
        and type(laps.step) == "function", "lap module required")
end

function Race.new(track, checkpoints, laps, tick)
    requireLaps(laps)
    if tick == nil then tick = 0 end
    return {
        status="countdown", laps=laps.new(track,checkpoints,tick), targetLaps=3,
        countdownTicks=Race.COUNTDOWN_TICKS, startTick=nil,
        lastTick=tick, totalTicks=0, finishTick=nil, reason=nil,
    }
end

-- A coordinated backend has already waited for GO. Its first driving tick is
-- tick+1; packet receipt time and the solo countdown never count as race time.
function Race.newRunning(track, checkpoints, laps, tick)
    if tick == nil then tick = 0 end
    assert(validTick(tick), "nonnegative integer initial tick required")
    local race = Race.new(track,checkpoints,laps,tick)
    race.status, race.countdownTicks, race.startTick = "running", 0, tick
    return race
end

function Race.step(race, previous, current, track, checkpoints, laps)
    assert(type(race) == "table", "race state required")
    if race.status ~= "running" and race.status ~= "countdown" then return race end
    requireLaps(laps)
    if race.status == "countdown" then
        if type(previous) ~= "table" or type(current) ~= "table"
            or not validTick(race.lastTick) or not validTick(previous.tick)
            or not validTick(current.tick) or previous.tick ~= race.lastTick
            or current.tick ~= previous.tick+1 then return race end
        local remaining = race.countdownTicks-1
        local go = remaining == 0
        return {
            status=go and "running" or "countdown",
            laps=go and laps.new(track,checkpoints,current.tick) or race.laps,
            targetLaps=race.targetLaps, countdownTicks=remaining,
            startTick=go and current.tick or nil, lastTick=current.tick,
            totalTicks=0, finishTick=nil, reason=nil,
        }
    end
    local progress = laps.step(race.laps,previous,current,track,checkpoints)
    if progress == race.laps then return race end
    local finished = progress.completedLaps >= race.targetLaps
    return {
        status=finished and "finished" or "running", laps=progress,
        targetLaps=race.targetLaps, countdownTicks=race.countdownTicks, startTick=race.startTick,
        lastTick=current.tick, totalTicks=current.tick-race.startTick,
        finishTick=finished and current.tick or nil,
        reason=finished and "Three-lap run complete" or nil,
    }
end

function Race.stop(race, reason, interrupted)
    assert(type(race) == "table", "race state required")
    if race.status ~= "running" and race.status ~= "countdown" then return race end
    interrupted = interrupted == true
    return {
        status=interrupted and "interrupted" or "stopped", laps=race.laps,
        targetLaps=race.targetLaps, countdownTicks=race.countdownTicks, startTick=race.startTick,
        lastTick=race.lastTick, totalTicks=race.totalTicks,
        finishTick=race.finishTick,
        reason=reason or (interrupted and "Game interrupted by combat" or "Stopped"),
    }
end

function Race.cue(race)
    assert(type(race) == "table", "race state required")
    if race.status == "countdown" then
        if race.countdownTicks > 120 then return "3" end
        if race.countdownTicks > 60 then return "2" end
        return "1"
    end
    if race.status == "running" and race.totalTicks < Race.GO_CUE_TICKS then return "GO" end
end

if type(namespace) == "table" then namespace.Race = Race end
return Race
