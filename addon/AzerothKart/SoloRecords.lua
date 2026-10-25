-- Native finish/persistence boundary. No networking, simulation writes or timers.
local _, AK = ...
local Scores, Physics, Courses = AK.Highscores, AK.Physics, AK.Courses
local Records = {}
AK.SoloRecords = Records
local db, source, store, writable, problem

local function plain(value)
    if type(issecretvalue) == "function" then
        local ok, secret = pcall(issecretvalue, value)
        if not ok or secret then return false end
    end
    return true
end

local function read(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, ...)
    if ok and plain(value) then return value end
end

local function localName()
    local name = type(NameUtil) == "table" and read(NameUtil.GetUnmodifiedUnitFullName, "player")
    name = Scores.NormalizeName(name)
    if name then return name end
    if type(UnitNameUnmodified) ~= "function" then return nil end
    local ok, first, surname = pcall(UnitNameUnmodified, "player")
    if not ok or not plain(first) or not plain(surname) or type(first) ~= "string" then return nil end
    if surname ~= nil and surname ~= "" then
        local constants = type(Constants) == "table" and Constants.CharacterNameSeparatorConsts
        local separator = type(constants) == "table" and constants.CHARACTERNAME_SURNAME_SEPARATOR
        if type(surname) ~= "string" or not plain(separator) or type(separator) ~= "string" then return nil end
        first = first .. separator .. surname
    end
    return Scores.NormalizeName(first)
end

function Records.PlayerName() return localName() end

local function integer(value, minimum, maximum)
    return plain(value) and type(value) == "number" and value == value
        and value >= minimum and value <= maximum and value % 1 == 0
end

function Records.Init()
    db = AzerothKartDB
    source = nil
    if type(db) == "table" then source = db.highscores end
    store, writable, problem = Scores.Load(source)
    if type(db) ~= "table" or db.schemaVersion ~= 1 then
        writable, problem = false, "Saved data version unavailable; scores are read-only"
    elseif not writable then
        problem = "Saved highscores unavailable (" .. tostring(problem) .. "); existing data kept"
    end
end

function Records.Context(track)
    if type(track) ~= "table" then return nil end
    -- A sprint course (track.laps 1) keeps its own one-run boards.
    local context = {trackId=track.id, trackVersion=track.version,
        physicsVersion=Physics.VERSION, lapCount=track.laps or 3, tickRate=60, rulesVersion=Scores.RULES_VERSION}
    if Scores.BoardKey(context) then return context end
end

-- Called only after a successful deliberate solo Start, not on rejected Starts.
function Records.Begin(track, kartId)
    return {context=Records.Context(track), kartId=kartId, attempted=false, timingLost=false}
end

function Records.FormatTime(ticks)
    if not integer(ticks, 0, 5184000) then return "--" end
    local centiseconds = math.floor(ticks * 100 / 60 + 0.5)
    return ("%d:%02d.%02d"):format(math.floor(centiseconds / 6000),
        math.floor(centiseconds / 100) % 60, centiseconds % 100)
end

function Records.FormatDate(epoch)
    if not integer(epoch, 1, 4102444800) then return "--" end
    local text = read(date, "!%Y-%m-%d", epoch)
    if type(text) == "string" and text:match("^%d%d%d%d%-%d%d%-%d%d$") then return text end
    return "Date unavailable"
end

local function result(message, ticks, saved)
    return {message=message, totalTicks=ticks, saved=saved or false, publication="pending"}
end

local function unchangedSave()
    return type(db) == "table" and AzerothKartDB == db and db.schemaVersion == 1
        and db.highscores == source
end

function Records.Finish(run, race, multiplayer)
    if type(run) ~= "table" or run.attempted then return nil end
    -- Latch before APIs/storage: errors and UI reentry must not retry a finish.
    run.attempted = true
    if multiplayer or type(race) ~= "table" or race.status ~= "finished"
        or not run.context or race.targetLaps ~= run.context.lapCount
        or type(race.laps) ~= "table" or race.laps.completedLaps ~= race.targetLaps
        or not integer(race.totalTicks, 1, 5184000)
        or not integer(race.startTick, 0, 2147483647)
        or not integer(race.finishTick, 1, 2147483647)
        or race.finishTick - race.startTick ~= race.totalTicks then return nil end
    local ticks = race.totalTicks
    if run.timingLost then return result("Score not saved: frame timing lost during this run", ticks) end
    if not writable then return result(problem or "Scores unavailable; existing data kept", ticks) end
    if not unchangedSave() then
        return result("Saved scores changed; reload before saving another score", ticks)
    end
    local playerName = localName()
    if not playerName then return result("Score not saved: full player name unavailable", ticks) end
    local stamp = read(GetServerTime)
    if not integer(stamp, 1, 4102444800) then
        return result("Score not saved: server date unavailable", ticks)
    end
    local record = {}
    for key, value in pairs(run.context) do record[key] = value end
    record.playerName, record.totalTicks, record.finishedAt, record.kartId = playerName, ticks, stamp, run.kartId
    -- A native callback may have changed data since Init. Re-parse the exact
    -- current child after those calls rather than overwriting from a stale view.
    if not unchangedSave() then
        return result("Saved scores changed; reload before saving another score", ticks)
    end
    local current, canWrite, loadReason = Scores.Load(source)
    if not canWrite then return result("Score not saved (" .. tostring(loadReason) .. "); existing data kept", ticks) end
    local updated, changed, reason = Scores.Submit(current, record)
    store = current
    if changed then
        if not unchangedSave() then
            return result("Saved scores changed; reload before saving another score", ticks)
        end
        -- Only this independently versioned child is written. Preferences and
        -- unknown top-level fields remain intact; no SavedVariables file I/O.
        db.highscores, source, store = updated, updated, updated
        local message="Personal best saved: " .. Records.FormatTime(ticks)
        if AK.ScoreSharing and type(AK.ScoreSharing.Publish)=="function" then
            local ok,notice=pcall(AK.ScoreSharing.Publish,record)
            if ok and type(notice)=="string" then message=notice.." | "..message end
        end
        return result(message, ticks, true)
    end
    if reason == "not_better" then
        return result("Total " .. Records.FormatTime(ticks) .. " | Personal best unchanged", ticks)
    end
    return result("Score not saved (" .. tostring(reason) .. "); existing data kept", ticks)
end

function Records.GetView(trackId)
    if AK.ScoreSharing and type(AK.ScoreSharing.GetView)=="function" then
        local ok,shared=pcall(AK.ScoreSharing.GetView,trackId)
        if ok and type(shared)=="table" then return shared end
    end
    local course = Courses.get(trackId)
    local track = Courses.build(trackId, AK.Track.crossesGate)
    local context = Records.Context(track)
    local current, valid, loadReason = Scores.Load(source)
    local canWrite = writable and unchangedSave() and valid or false
    local currentProblem = problem
    if not valid then currentProblem = "Saved highscores unavailable (" .. tostring(loadReason) .. "); existing data kept"
    elseif writable and not canWrite then currentProblem = "Saved scores changed; reload before saving another score" end
    return {scope="local", publication="Global publishing pending", writable=canWrite,
        problem=currentProblem, trackId=trackId, trackName=course and course.name or "Unknown track",
        context=context, rows=context and valid and Scores.View(current, context) or {}}
end

return Records
