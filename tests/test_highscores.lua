-- Local score data only: no real persistence, identity, clock or publication.
local namespace = {}
local H = assert(loadfile("addon/AzerothKart/Highscores.lua"))("AzerothKart", namespace)
assert(namespace.Highscores == H and H.VERSION == 1 and H.RULES_VERSION == 1)
assert(H.MAX_BOARDS == 32 and H.MAX_ROWS == 50)
local CONTEXT = {trackId = "test_oval", trackVersion = 2, physicsVersion = 10,
    lapCount = 3, tickRate = 60, rulesVersion = 1}
local function copy(source)
    local result = {}
    for key, value in pairs(source) do result[key] = type(value) == "table" and copy(value) or value end
    return result
end
local function record(name, ticks, stamp, context)
    local result = copy(context or CONTEXT)
    result.playerName, result.totalTicks, result.finishedAt = name or "Amber Stone", ticks or 1800, stamp or 1792750000
    result.kartId = "steam_tank"
    return result
end
local function submit(store, value)
    local changed, reason
    store, changed, reason = H.Submit(store, value)
    assert(changed and reason == "recorded", reason)
    return store
end
local function unchanged(store, value, expected)
    local result, changed, reason = H.Submit(store, value)
    assert(result == store and not changed and reason == expected, tostring(reason))
end
local function rejectSave(raw, expected)
    local result, writable, reason = H.Load(raw)
    assert(result == raw and writable == false and reason == (expected or "invalid_store"))
    unchanged(raw, record(), expected or "invalid_store")
    local view = H.View(raw, CONTEXT)
    assert(type(view) == "table" and next(view) == nil)
end

-- Names preserve the complete native identity, punctuation and UTF-8.
assert(H.NormalizeName("  Amber   Stone  ") == "Amber Stone")
assert(H.NormalizeName("Alone") == "Alone")
assert(H.NormalizeName("Anne-Marie O'Brian") == "Anne-Marie O'Brian")
local utfName = string.char(195, 133) .. "se " .. string.char(230, 157, 142)
assert(H.NormalizeName(utfName) == utfName)
assert(H.NormalizeName(string.rep("A", 96)) == string.rep("A", 96))
for _, bad in ipairs({false, 1, {}, "", "   ", string.rep("A", 97), string.rep(" ", 97) .. "A",
    "Amber\tStone", "Amber\nStone", "Amber\000Stone", "Amber\127Stone", "|cff00ff00Amber|r",
    string.char(128), string.char(192, 175), string.char(194), string.char(224, 128, 128),
    string.char(237, 160, 128), string.char(240, 128, 128, 128), string.char(244, 144, 128, 128),
    string.char(245, 128, 128, 128), string.char(255)}) do
    assert(H.NormalizeName(bad) == nil)
end
assert(H.NormalizeName(nil) == nil)
for _, value in ipairs({string.char(194, 128), string.char(223, 191), string.char(224, 160, 128),
    string.char(237, 159, 191), string.char(239, 191, 191), string.char(240, 144, 128, 128),
    string.char(244, 143, 191, 191)}) do assert(H.NormalizeName(value) == value) end

local store, writable, problem = H.Load(nil)
assert(writable and problem == nil and store.version == 1 and next(store.boards) == nil)
local second = H.Load(nil)
assert(second ~= store and second.boards ~= store.boards)
local key = H.BoardKey(CONTEXT)
assert(key == "test_oval:2:10:3:60:1" and H.BoardKey(record()) == key)
local initial = record()
local nextStore = submit(store, initial)
assert(next(store.boards) == nil and initial.playerName == "Amber Stone")
assert(nextStore ~= store and #nextStore.boards[key].rows == 1)
local view = H.View(nextStore, CONTEXT)
assert(view[1].playerName == "Amber Stone" and view[1].totalTicks == 1800
    and view[1].finishedAt == initial.finishedAt and view[1].kartId == "steam_tank")
view[1].totalTicks, initial.totalTicks = 1, 5
view[1].playerName = "Changed"
assert(H.View(nextStore, CONTEXT)[1].totalTicks == 1800
    and H.View(nextStore, CONTEXT)[1].playerName == "Amber Stone", "detached input and view")
local loaded, canWrite = H.Load(nextStore)
assert(canWrite and loaded ~= nextStore and loaded.boards ~= nextStore.boards
    and loaded.boards[key] ~= nextStore.boards[key]
    and loaded.boards[key].rows[1] ~= nextStore.boards[key].rows[1], "load returns detached data")
loaded.boards[key].rows[1].totalTicks = 11
assert(nextStore.boards[key].rows[1].totalTicks == 1800)
-- The caller's unrelated saved fields are outside this module's schema.
local database = {schemaVersion = 1, preferences = {track = "mirage_raceway"}, custom = {keep = true}, highscores = nextStore}
local preferences, custom = database.preferences, database.custom
database.highscores = H.Load(database.highscores)
assert(database.schemaVersion == 1 and database.preferences == preferences
    and database.custom == custom and database.custom.keep)

-- One best per complete ASCII-folded name; ties preserve the recorded date.
unchanged(nextStore, record("  AMBER   STONE  ", 1801), "not_better")
unchanged(nextStore, record("amber stone", 1800, 1), "not_better")
local faster = submit(nextStore, record("AMBER STONE", 1700, initial.finishedAt + 1))
assert(#H.View(faster, CONTEXT) == 1 and H.View(faster, CONTEXT)[1].totalTicks == 1700
    and H.View(faster, CONTEXT)[1].finishedAt == initial.finishedAt + 1
    and H.View(nextStore, CONTEXT)[1].totalTicks == 1800)
faster = submit(faster, record("Amber Vale", 1700, initial.finishedAt))
faster = submit(faster, record("Birch Vale", 1600, initial.finishedAt + 2))
faster = submit(faster, record("Cedar Vale", 1700, initial.finishedAt))
local ranked = H.View(faster, CONTEXT)
assert(#ranked == 4 and ranked[1].playerName == "Birch Vale"
    and ranked[2].playerName == "Amber Vale" and ranked[3].playerName == "Cedar Vale"
    and ranked[4].playerName == "AMBER STONE", "ticks, then date, then full name")
-- Non-ASCII letters retain exact bytes rather than being locale-folded.
local lowerUtfName = string.char(195, 165) .. "se " .. string.char(230, 157, 142)
faster = submit(faster, record(utfName))
faster = submit(faster, record(lowerUtfName))
assert(#H.View(faster, CONTEXT) == 6)
local sameCosmetics = record("Birch Vale", 1500)
sameCosmetics.kartId = "goblin_drag_car"
faster = submit(faster, sameCosmetics)
assert(#H.View(faster, CONTEXT) == 6 and H.View(faster, CONTEXT)[1].kartId == "goblin_drag_car")

-- Every compatibility field isolates records; all cosmetic choices share it.
for _, field in ipairs({"trackId", "trackVersion", "physicsVersion", "lapCount", "tickRate", "rulesVersion"}) do
    local context = copy(CONTEXT)
    context[field] = field == "trackId" and "mirage_raceway" or context[field] + 1
    assert(H.BoardKey(context) ~= key and #H.View(nextStore, context) == 0)
    local isolated = submit(nextStore, record(nil, nil, nil, context))
    assert(#H.View(isolated, context) == 1 and #H.View(isolated, CONTEXT) == 1)
end
assert(H.BoardKey(nil) == nil and H.BoardKey({}) == nil)
for _, bad in ipairs({false, {}, "1", 0, -1, 0.5, 0/0, math.huge, -math.huge, 2147483648}) do
    for _, field in ipairs({"trackVersion", "physicsVersion", "lapCount", "tickRate", "rulesVersion"}) do
        local context = copy(CONTEXT)
        context[field] = bad
        assert(H.BoardKey(context) == nil)
        unchanged(nextStore, record(nil, nil, nil, context), "invalid_record")
    end
end
for _, bad in ipairs({"", "abc-def", "a:b", "With space", string.rep("A", 65), utfName, false, {}}) do
    local context = copy(CONTEXT)
    context.trackId = bad
    assert(H.BoardKey(context) == nil)
    unchanged(nextStore, record(nil, nil, nil, context), "invalid_record")
end
for _, field in ipairs({"totalTicks", "finishedAt"}) do
    local maximum = field == "totalTicks" and H.MAX_TICKS or H.MAX_TIMESTAMP
    for _, bad in ipairs({false, {}, "100", 0, -1, 0.5, 0/0, math.huge, -math.huge, maximum + 1}) do
        local candidate = record()
        candidate[field] = bad
        unchanged(nextStore, candidate, "invalid_record")
    end
    local candidate = record("Limit " .. field)
    candidate[field] = maximum
    assert(select(2, H.Submit(nextStore, candidate)))
end
for _, field in ipairs({"playerName", "kartId", "totalTicks", "finishedAt", "trackId", "rulesVersion"}) do
    local missing = record()
    missing[field] = nil
    unchanged(nextStore, missing, "invalid_record")
end
local extra = record()
extra.unexpected = true
unchanged(nextStore, extra, "invalid_record")
unchanged(nextStore, setmetatable(record(), {}), "invalid_record")
assert(H.BoardKey(setmetatable(copy(CONTEXT), {})) == nil)
for _, bad in ipairs({"", "a-b", "With space", string.rep("A", 65), utfName, false, {}}) do
    local candidate = record()
    candidate.kartId = bad
    unchanged(nextStore, candidate, "invalid_record")
end

-- Full boards retain the best fifty with deterministic ordering and no eviction
-- of a better entry. A full category set refuses a new compatibility partition.
local full = H.Load(nil)
for index = 1, H.MAX_ROWS do
    full = submit(full, record(("Player %02d"):format(index), 1000 + index, 100 + index))
end
local fullRows = H.View(full, CONTEXT)
assert(#fullRows == H.MAX_ROWS and fullRows[1].totalTicks == 1001 and fullRows[50].totalTicks == 1050)
unchanged(full, record("Slow Newcomer", 1051), "outside_top")
local trimmed = submit(full, record("Fast Newcomer", 900))
assert(#H.View(trimmed, CONTEXT) == H.MAX_ROWS)
local trimmedRows = H.View(trimmed, CONTEXT)
assert(trimmedRows[1].playerName == "Fast Newcomer" and trimmedRows[50].playerName == "Player 49")
assert(H.View(full, CONTEXT)[50].playerName == "Player 50", "original full board stays unchanged")
local categories = H.Load(nil)
for index = 1, H.MAX_BOARDS do
    local context = copy(CONTEXT)
    context.trackVersion = index
    categories = submit(categories, record(nil, nil, nil, context))
end
local newContext = copy(CONTEXT)
newContext.trackVersion = H.MAX_BOARDS + 1
unchanged(categories, record(nil, nil, nil, newContext), "board_capacity")
assert(select(2, H.Submit(categories, record("Existing Board", 1000))), "full category set permits existing-board updates")

-- Malformed/future saves are never silently repaired or overwritten.
for _, bad in ipairs({false, 0, "old", {}, {version = 0, boards = {}}, {version = 1},
    {version = 1, boards = false}, {version = 1, boards = {}, custom = true},
    setmetatable({version = 1, boards = {}}, {})}) do rejectSave(bad) end
rejectSave({version = 2, boards = {unknown = {keep = true}}, custom = {future = true}}, "unsupported_version")
rejectSave({version = 2147483647, boards = {}}, "unsupported_version")
for _, damage in ipairs({
    function(raw) raw.boards[key].unexpected = true end,
    function(raw) raw.boards[key].trackId = "another" end,
    function(raw) raw.boards[key].rows = false end,
    function(raw) raw.boards[key].rows[1].totalTicks = -1 end,
    function(raw) raw.boards[key].rows[1].trackVersion = 8 end,
    function(raw) raw.boards[key].rows[1].playerName = "Bad|Name" end,
    function(raw) raw.boards[key].rows[1].playerName = string.char(255) end,
    function(raw) raw.boards[key].rows[2] = copy(raw.boards[key].rows[1]) end,
    function(raw) raw.boards[key].rows[2] = copy(raw.boards[key].rows[1]); raw.boards[key].rows[2].playerName = "AMBER STONE" end,
    function(raw) raw.boards[key].rows[3] = raw.boards[key].rows[1]; raw.boards[key].rows[1] = nil end,
    function(raw) raw.boards[key].rows.extra = true end,
    function(raw) raw.boards[key].rows = setmetatable(raw.boards[key].rows, {}) end,
    function(raw) raw.boards[key].rows[1] = setmetatable(raw.boards[key].rows[1], {}) end,
    function(raw) raw.boards.badkey = raw.boards[key] end,
    function(raw) raw.boards[key] = raw end,
    function(raw) raw.boards = raw end,
}) do
    local damaged = copy(nextStore)
    damage(damaged)
    rejectSave(damaged)
end
local tooMany = copy(categories)
local context = copy(newContext)
local overKey = H.BoardKey(context)
tooMany.boards[overKey] = context
tooMany.boards[overKey].rows = {}
rejectSave(tooMany)
local tooLong = copy(full)
tooLong.boards[key].rows[51] = record("Extra Player")
rejectSave(tooLong)

-- Loading valid but unsorted entries returns a sorted detached representation.
local unordered = copy(faster)
local sourceRows = unordered.boards[key].rows
sourceRows[1], sourceRows[2] = sourceRows[2], sourceRows[1]
local firstBefore = sourceRows[1]
local ordered = H.Load(unordered)
assert(unordered.boards[key].rows[1] == firstBefore and H.View(ordered, CONTEXT)[1].playerName == "Birch Vale")
local safeMeta = setmetatable({}, {__index = function() error("untrusted metamethod invoked") end})
rejectSave(safeMeta)
unchanged(nextStore, safeMeta, "invalid_record")
assert(H.BoardKey(safeMeta) == nil)

print("highscores: bounded detached bests, exact ticks/version partitions, UTF-8 identities, stable ties and untouched invalid/future saves")
