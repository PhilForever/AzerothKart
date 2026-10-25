-- Pure merging/ranks only. No native sharing, sender authentication or popups.
local H = assert(loadfile("addon/AzerothKart/Highscores.lua"))("AzerothKart", {})
local CONTEXT = {trackId="test_oval", trackVersion=2, physicsVersion=10,
    lapCount=3, tickRate=60, rulesVersion=1}
local function copy(value)
    if type(value) ~= "table" then return value end
    local out = {}
    for key, item in pairs(value) do out[key] = copy(item) end
    return out
end
local function record(name, ticks, stamp, kart)
    local out = copy(CONTEXT)
    out.playerName, out.totalTicks, out.finishedAt, out.kartId =
        name or "Amber Stone", ticks or 1800, stamp or 1792750000, kart or "steam_tank"
    return out
end
local function empty() return H.Load(nil) end
local function merge(store, batch, context)
    local out, changed, reason = H.Merge(store, context or CONTEXT, batch)
    assert(reason == "merged" or reason == "unchanged", tostring(reason))
    assert(changed == (reason == "merged"))
    return out, changed
end
local function signature(store)
    local parts = {}
    for _, value in ipairs(H.View(store, CONTEXT)) do
        parts[#parts+1] = table.concat({value.playerName, value.totalTicks,
            value.finishedAt, value.kartId}, "/")
    end
    return table.concat(parts, "\n")
end
local function same(a, b) assert(signature(a) == signature(b), "replicas must converge") end
local function unchanged(store, batch, expected, context)
    local before = signature(store)
    local out, changed, reason = H.Merge(store, context or CONTEXT, batch)
    assert(out == store and not changed and reason == expected, tostring(reason))
    assert(signature(store) == before, "rejection/no-op must not mutate the input")
end

local a = {record("Amber Stone", 1800, 200), record("Birch Vale", 1700, 200)}
local b = {record("Amber Stone", 1800, 100), record("Cedar Vale", 1600, 100)}
local c = {record("AMBER STONE", 1800, 100, "gryphon_rider"),
    record("AMBER STONE", 1800, 100, "goblin_drag_car"), record("Birch Vale", 1500, 300)}
local ab = merge(merge(empty(), a), b)
same(ab, merge(merge(empty(), b), a))
local abc = merge(ab, c)
same(abc, merge(merge(empty(), c), H.View(ab, CONTEXT)))
same(abc, merge(merge(merge(empty(), c), a), b))
same(abc, merge(merge(empty(), a), H.View(merge(merge(empty(), b), c), CONTEXT)))
local dup, changed = merge(abc, H.View(abc, CONTEXT))
assert(dup == abc and not changed, "idempotent merge retains original identity")
local rank, amber = H.Rank(abc, CONTEXT, " amber   stone ")
assert(rank == 3 and amber.playerName == "AMBER STONE" and amber.finishedAt == 100
    and amber.kartId == "goblin_drag_car", "canonical date, spelling and kart tie-breaks")
amber.totalTicks = 1
assert(select(2, H.Rank(abc, CONTEXT, "Amber Stone")).totalTicks == 1800, "rank returns detached data")

-- Equal-time/equal-date ordering uses raw UTF-8 bytes rather than locale collation.
local upperA = string.char(195, 133) .. "sa Stone"
local lowerA = string.char(195, 165) .. "sa Stone"
local macronA = string.char(196, 128) .. "sa Stone"
local unicode = merge(empty(), {record(macronA, 1000, 100), record(lowerA, 1000, 100),
    record("Zebra Stone", 1000, 100), record(upperA, 1000, 100)})
local unicodeRows = H.View(unicode, CONTEXT)
assert(unicodeRows[1].playerName == "Zebra Stone" and unicodeRows[2].playerName == upperA
    and unicodeRows[3].playerName == lowerA and unicodeRows[4].playerName == macronA)
same(unicode, merge(empty(), {record(upperA, 1000, 100), record("Zebra Stone", 1000, 100),
    record(lowerA, 1000, 100), record(macronA, 1000, 100)}))

-- Equal local finishes retain the old date; community canonicalization is additive.
local localStore = assert(H.Submit(empty(), a[1]))
local localOut, localChanged, localWhy = H.Submit(localStore, b[1])
assert(localOut == localStore and not localChanged and localWhy == "not_better")
assert(H.View(localStore, CONTEXT)[1].finishedAt == 200)
assert(H.View(merge(localStore, b), CONTEXT)[2].finishedAt == 100)

-- Truncation cannot drop a later global top-N row: every discarded row already
-- has N better distinct players. Better future scores can re-enter the board.
local first, second, third = {}, {}, {}
for index = 1, 50 do
    first[index] = record(("Player %03d"):format(index), 1000+index, 100)
    second[index] = record(("Player %03d"):format(index+25), 1000+index+25, 100)
    third[index] = record(("Player %03d"):format(index+50), 900+index+50, 100)
end
local left = merge(merge(merge(empty(), first), second), third)
local right = merge(merge(empty(), third), H.View(merge(merge(empty(), second), first), CONTEXT))
same(left, right)
assert(#H.View(left, CONTEXT) == 50)
unchanged(left, {record("Very Slow", 5000)}, "unchanged")
local improved = merge(left, {record("Very Slow", 500)})
assert(H.Rank(improved, CONTEXT, "Very Slow") == 1 and #H.View(improved, CONTEXT) == 50)
local shuffled = {}
for index = #third, 1, -1 do shuffled[#shuffled+1] = third[index] end
same(merge(empty(), third), merge(empty(), shuffled))
same(merge(empty(), {a[1], a[1], b[1]}), merge(empty(), {b[1], a[1], a[1]}))

-- Whole-batch validation, including holes, lengths, metatables and mismatched
-- contexts, runs before mutation. A valid leading record cannot leak through.
local malformed = record("Invalid", 1)
malformed.totalTicks = 0/0
unchanged(abc, {record("Valid New", 500), malformed}, "invalid_records")
local other = record("Other Rules", 1); other.trackVersion = 3
unchanged(abc, {record("Valid New", 500), other}, "invalid_records")
for _, batch in ipairs({false, "bad", {a[1], [3]=b[1]}, {extra=a[1]},
    setmetatable({a[1]}, {}), {setmetatable(a[1], {})}}) do
    unchanged(abc, batch, "invalid_records")
end
local tooMany = {}
for index = 1, 51 do tooMany[index] = a[1] end
unchanged(abc, tooMany, "invalid_records")
unchanged(abc, {}, "unchanged")
unchanged(empty(), {}, "unchanged")
local badContext = copy(CONTEXT); badContext.tickRate = 0
unchanged(abc, a, "invalid_context", badContext)
local copiedInput = record("Detached", 700)
local original = empty()
local detached = merge(original, {copiedInput})
copiedInput.totalTicks = 2
assert(#H.View(original, CONTEXT) == 0 and H.View(detached, CONTEXT)[1].totalTicks == 700)
local future = {version=999, boards={}, keep="future"}
local futureOut, futureChanged, futureWhy = H.Merge(future, CONTEXT, a)
assert(futureOut == future and not futureChanged and futureWhy == "unsupported_version" and future.keep == "future")
local malformedStore = {version=1, boards=false}
assert(H.Merge(malformedStore, CONTEXT, a) == malformedStore)
local meta = setmetatable({}, {__index=function() error("untrusted metamethod called") end})
assert(H.Merge(meta, CONTEXT, a) == meta)
assert(H.Merge(abc, CONTEXT, meta) == abc)
assert(H.Rank(meta, CONTEXT, "Amber Stone") == nil)
assert(H.FinishPlacement(meta, abc, a[1]) == nil)

local differentContext = copy(CONTEXT); differentContext.trackVersion = 3
local differentRecord = record("New Version", 1); differentRecord.trackVersion = 3
local isolated = merge(abc, {differentRecord}, differentContext)
same(isolated, abc)
assert(H.Rank(isolated, differentContext, "New Version") == 1)
local fullBoards = empty()
for index = 1, H.MAX_BOARDS do
    local context = copy(CONTEXT); context.trackVersion = index
    local value = record(); value.trackVersion = index
    fullBoards = merge(fullBoards, {value}, context)
end
local excessContext = copy(CONTEXT); excessContext.trackVersion = H.MAX_BOARDS + 1
local excess = record(); excess.trackVersion = excessContext.trackVersion
unchanged(fullBoards, {excess}, "board_capacity", excessContext)
assert(select(2, H.Merge(fullBoards, CONTEXT, {record("Faster Existing", 500)})), "full store accepts existing-board updates")

-- One local finish may cross several thresholds, but reports only the highest.
local ranking = {}
for index = 1, 12 do ranking[index] = record(("Racer %02d"):format(index), 1000+index*100, 200) end
local before = merge(empty(), ranking)
local function placement(prior, candidate)
    local after = merge(prior, {candidate})
    return assert(H.FinishPlacement(prior, after, candidate)), after
end
local candidate = record("Racer 12", 1950, 300)
local notice, topTen = placement(before, candidate)
assert(notice.rank == 10 and notice.previousRank == 12 and notice.tier == 10
    and notice.enteredTier == 10 and notice.knownPlayers == 12 and notice.scope == "known_board")
local sameAssessment = assert(H.FinishPlacement(before, topTen, candidate))
assert(sameAssessment.enteredTier == notice.enteredTier and sameAssessment.rank == notice.rank,
    "pure assessment does not consume the event; the local-finish caller owns its once-only latch")
local topThreeRecord = record("Racer 12", 1250, 400)
local topThree, topThreeStore = placement(topTen, topThreeRecord)
assert(topThree.rank == 3 and topThree.previousRank == 10 and topThree.tier == 3 and topThree.enteredTier == 3)
local stillTopThree = placement(topThreeStore, record("Racer 12", 1150, 500))
assert(stillTopThree.rank == 2 and stillTopThree.tier == 3 and stillTopThree.enteredTier == nil)
local directTopThree = placement(before, record("Racer 12", 1250, 400))
assert(directTopThree.enteredTier == 3, "one event when crossing top10 and top3 together")
local firstKnown = placement(empty(), record("New Racer", 1000))
assert(firstKnown.rank == 1 and firstKnown.scope == "known_board" and firstKnown.knownPlayers == 1)

local replayStore = merge(topTen, {candidate})
local replay, replayReason = H.FinishPlacement(topTen, replayStore, candidate)
assert(replay == nil and replayReason == "not_improved", "duplicate finish/packet cannot repeat a placement")
local metadata = copy(candidate); metadata.finishedAt = 1
local metadataStore = merge(topTen, {metadata})
assert(H.FinishPlacement(topTen, metadataStore, metadata) == nil, "canonical metadata changes are not new finishes")
local mismatch = copy(topThreeRecord); mismatch.finishedAt = 401
local absent, absentReason = H.FinishPlacement(topTen, topThreeStore, mismatch)
assert(absent == nil and absentReason == "not_retained", "notice must describe the exact retained finish")
assert(H.FinishPlacement(topTen, topThreeStore, record("Unknown Racer", 1)) == nil)
assert(H.FinishPlacement(topTen, future, candidate) == nil)
assert(select(3, H.Rank(abc, CONTEXT, "Missing")) == "not_ranked")
assert(select(3, H.Rank(abc, CONTEXT, "|Hbad|h")) == "invalid_name")
assert(select(3, H.Rank(abc, badContext, "Amber Stone")) == "invalid_context")

print("community scores: atomic convergent bounded merges, canonical ties, detached ranks and local-finish top3/top10 transitions (no network)")
