-- Bounded local, client-reported solo bests. Pure data: no clock, UI or transport.
local _, namespace = ...
local Highscores = {}
Highscores.VERSION = 1
Highscores.RULES_VERSION = 1
Highscores.MAX_BOARDS = 32
Highscores.MAX_ROWS = 50
Highscores.MAX_TICKS = 5184000 -- 24 hours at the current 60 Hz simulation rate.
Highscores.MAX_TIMESTAMP = 4102444800 -- 2100-01-01 UTC.

local MAX_INTEGER = 2147483647
local CONTEXT = {"trackId", "trackVersion", "physicsVersion", "lapCount", "tickRate", "rulesVersion"}
local ROW = {"trackId", "trackVersion", "physicsVersion", "lapCount", "tickRate", "rulesVersion",
    "playerName", "totalTicks", "finishedAt", "kartId"}
local function allowed(fields)
    local out = {}
    for _, field in ipairs(fields) do out[field] = true end
    return out
end
local BOARD_FIELDS = allowed(CONTEXT)
BOARD_FIELDS.rows = true
local ROW_FIELDS = allowed(ROW)

local function plainTable(value)
    return type(value) == "table" and getmetatable(value) == nil
end

local function onlyFields(value, fields)
    if not plainTable(value) then return false end
    for key in next, value do if not fields[key] then return false end end
    return true
end

local function integer(value, minimum, maximum)
    return type(value) == "number" and value == value and value >= minimum
        and value <= maximum and value % 1 == 0
end

local function identifier(value)
    return type(value) == "string" and #value >= 1 and #value <= 64
        and value:match("^[A-Za-z0-9_]+$") ~= nil
end

-- Lua 5.1 has no utf8 library. Reject truncated/overlong encodings, surrogate
-- codepoints and values beyond Unicode; never change the player's UTF-8 bytes.
local function utf8(value)
    local index, length = 1, #value
    local function continuation(at, low, high)
        local byte = value:byte(at)
        return byte ~= nil and byte >= (low or 128) and byte <= (high or 191)
    end
    while index <= length do
        local byte = value:byte(index)
        if byte <= 127 then index = index + 1
        elseif byte >= 194 and byte <= 223 and continuation(index + 1) then
            index = index + 2
        elseif byte == 224 and continuation(index + 1, 160, 191) and continuation(index + 2) then
            index = index + 3
        elseif ((byte >= 225 and byte <= 236) or (byte >= 238 and byte <= 239))
                and continuation(index + 1) and continuation(index + 2) then
            index = index + 3
        elseif byte == 237 and continuation(index + 1, 128, 159) and continuation(index + 2) then
            index = index + 3
        elseif byte == 240 and continuation(index + 1, 144, 191)
                and continuation(index + 2) and continuation(index + 3) then
            index = index + 4
        elseif byte >= 241 and byte <= 243 and continuation(index + 1)
                and continuation(index + 2) and continuation(index + 3) then
            index = index + 4
        elseif byte == 244 and continuation(index + 1, 128, 143)
                and continuation(index + 2) and continuation(index + 3) then
            index = index + 4
        else return false end
    end
    return true
end

function Highscores.NormalizeName(value)
    if type(value) ~= "string" or #value == 0 or #value > 96
            or value:find("[%z\001-\031\127|]") or not utf8(value) then return nil end
    local normalized = value:gsub(" +", " "):match("^ *(.-) *$")
    return normalized ~= "" and normalized or nil
end

local function nameKey(name)
    -- string.lower is locale-sensitive in Lua 5.1; fold only ASCII letters.
    return (name:gsub("[A-Z]", function(char) return string.char(char:byte() + 32) end))
end

local function contextKey(context)
    if not plainTable(context) or not identifier(context.trackId) then return nil end
    local parts = {context.trackId}
    for index = 2, #CONTEXT do
        local value = context[CONTEXT[index]]
        if not integer(value, 1, MAX_INTEGER) then return nil end
        parts[#parts + 1] = ("%d"):format(value)
    end
    return table.concat(parts, ":")
end

-- Accept a record/board as context too; public callers need not strip metadata.
function Highscores.BoardKey(context)
    return contextKey(context)
end

local function copyFields(source, fields)
    local copy = {}
    for _, field in ipairs(fields) do copy[field] = source[field] end
    return copy
end

local function row(source, key)
    if not onlyFields(source, ROW_FIELDS) or contextKey(source) ~= key then return nil end
    local name = Highscores.NormalizeName(source.playerName)
    if not name or not integer(source.totalTicks, 1, Highscores.MAX_TICKS)
            or not integer(source.finishedAt, 1, Highscores.MAX_TIMESTAMP)
            or not identifier(source.kartId) then return nil end
    local copy = copyFields(source, ROW)
    copy.playerName = name
    return copy
end

-- Lua 5.1 string ordering can use the process locale. Compare numeric bytes so
-- UTF-8 names rank identically on clients with different locale settings.
local function bytesBefore(a, b)
    for index = 1, math.min(#a, #b) do
        local first, second = a:byte(index), b:byte(index)
        if first ~= second then return first < second end
    end
    return #a < #b
end

local function before(a, b)
    if a.totalTicks ~= b.totalTicks then return a.totalTicks < b.totalTicks end
    if a.finishedAt ~= b.finishedAt then return a.finishedAt < b.finishedAt end
    local aKey, bKey = nameKey(a.playerName), nameKey(b.playerName)
    if aKey ~= bKey then return bytesBefore(aKey, bKey) end
    return bytesBefore(a.playerName, b.playerName)
end

local function rows(source, key)
    if not plainTable(source) then return nil end
    local count = 0
    for index in next, source do
        if not integer(index, 1, Highscores.MAX_ROWS) then return nil end
        count = count + 1
        if count > Highscores.MAX_ROWS then return nil end
    end
    local copy, players = {}, {}
    for index = 1, count do
        local parsed = row(source[index], key)
        if not parsed then return nil end
        local player = nameKey(parsed.playerName)
        if players[player] then return nil end
        players[player], copy[index] = true, parsed
    end
    table.sort(copy, before)
    return copy
end

local function parseStore(source)
    if not plainTable(source) then return nil, "invalid_store" end
    if integer(source.version, Highscores.VERSION + 1, MAX_INTEGER) then
        return nil, "unsupported_version"
    end
    if source.version ~= Highscores.VERSION
            or not onlyFields(source, {version = true, boards = true})
            or not plainTable(source.boards) then return nil, "invalid_store" end
    local copy, count = {version = Highscores.VERSION, boards = {}}, 0
    for key, board in next, source.boards do
        count = count + 1
        if count > Highscores.MAX_BOARDS or type(key) ~= "string"
                or not onlyFields(board, BOARD_FIELDS) or contextKey(board) ~= key then
            return nil, "invalid_store"
        end
        local parsed = rows(board.rows, key)
        if not parsed then return nil, "invalid_store" end
        local copiedBoard = copyFields(board, CONTEXT)
        copiedBoard.rows = parsed
        copy.boards[key] = copiedBoard
    end
    return copy
end

-- Only absence initializes v1. Unknown/malformed saves are returned by identity,
-- read-only, so the native owner can preserve them instead of replacing data.
function Highscores.Load(raw)
    if raw == nil then return {version = Highscores.VERSION, boards = {}}, true end
    local copy, reason = parseStore(raw)
    if not copy then return raw, false, reason end
    return copy, true
end

function Highscores.Submit(store, record)
    local nextStore, reason = parseStore(store)
    if not nextStore then return store, false, reason end
    local key = contextKey(record)
    local parsed = key and row(record, key)
    if not parsed then return store, false, "invalid_record" end
    local board = nextStore.boards[key]
    if not board then
        local count = 0
        for _ in next, nextStore.boards do count = count + 1 end
        if count >= Highscores.MAX_BOARDS then return store, false, "board_capacity" end
        board = copyFields(parsed, CONTEXT)
        board.rows = {}
        nextStore.boards[key] = board
    end
    local player, replaced = nameKey(parsed.playerName), false
    for index, existing in ipairs(board.rows) do
        if nameKey(existing.playerName) == player then
            if parsed.totalTicks >= existing.totalTicks then return store, false, "not_better" end
            board.rows[index], replaced = parsed, true
            break
        end
    end
    if not replaced then board.rows[#board.rows + 1] = parsed end
    table.sort(board.rows, before)
    if #board.rows > Highscores.MAX_ROWS then
        local removed = table.remove(board.rows)
        if removed == parsed then return store, false, "outside_top" end
    end
    return nextStore, true, "recorded"
end

function Highscores.View(store, context)
    local parsed, reason = parseStore(store)
    if not parsed then return {}, reason end
    local key = contextKey(context)
    if not key then return {}, "invalid_context" end
    local board = parsed.boards[key]
    return board and board.rows or {}
end

-- Community merging is separate from Submit: a local equal-time finish keeps
-- its original date, while replicas need an arrival-order-independent winner.
-- These tie-breaks apply only to rows for the same normalized player identity.
local function canonicalBefore(a, b)
    if a.totalTicks ~= b.totalTicks then return a.totalTicks < b.totalTicks end
    if a.finishedAt ~= b.finishedAt then return a.finishedAt < b.finishedAt end
    if a.playerName ~= b.playerName then return bytesBefore(a.playerName, b.playerName) end
    return bytesBefore(a.kartId, b.kartId)
end

local function sameRow(a, b)
    for _, field in ipairs(ROW) do
        if a[field] ~= b[field] then return false end
    end
    return true
end

local function sameRows(a, b)
    if #a ~= #b then return false end
    for index, value in ipairs(a) do
        if not sameRow(value, b[index]) then return false end
    end
    return true
end

-- Merge(store, context, records) -> store, changed, reason.
-- Atomically validate one dense batch of at most MAX_ROWS same-board records;
-- duplicates are permitted and canonicalized. No native sender is authenticated
-- here: the transport must supply policy-accepted records and board contexts.
-- For a fixed admitted board, top-N canonical union is associative, commutative
-- and idempotent. The independent MAX_BOARDS admission limit is not a discovery
-- or convergence policy; callers must use an agreed compatibility catalogue.
-- Inputs are never mutated. A rejection/no-op returns the original store.
function Highscores.Merge(store, context, records)
    local nextStore, reason = parseStore(store)
    if not nextStore then return store, false, reason end
    local key = contextKey(context)
    if not key then return store, false, "invalid_context" end
    if not plainTable(records) then return store, false, "invalid_records" end
    local count = 0
    for index in next, records do
        if not integer(index, 1, Highscores.MAX_ROWS) then
            return store, false, "invalid_records"
        end
        count = count + 1
        if count > Highscores.MAX_ROWS then return store, false, "invalid_records" end
    end
    local incoming = {}
    for index = 1, count do
        incoming[index] = row(records[index], key)
        if not incoming[index] then return store, false, "invalid_records" end
    end
    if count == 0 then return store, false, "unchanged" end
    local board = nextStore.boards[key]
    if not board then
        local boardCount = 0
        for _ in next, nextStore.boards do boardCount = boardCount + 1 end
        if boardCount >= Highscores.MAX_BOARDS then return store, false, "board_capacity" end
        board = copyFields(context, CONTEXT)
        board.rows = {}
    end
    local players = {}
    for _, value in ipairs(board.rows) do players[nameKey(value.playerName)] = value end
    for _, value in ipairs(incoming) do
        local identity = nameKey(value.playerName)
        local previous = players[identity]
        if not previous or canonicalBefore(value, previous) then players[identity] = value end
    end
    local merged = {}
    for _, value in pairs(players) do merged[#merged + 1] = value end
    table.sort(merged, before)
    for index = #merged, Highscores.MAX_ROWS + 1, -1 do merged[index] = nil end
    if sameRows(board.rows, merged) then return store, false, "unchanged" end
    board.rows = merged
    nextStore.boards[key] = board
    return nextStore, true, "merged"
end

local function rankIn(store, key, identity)
    local board = store.boards[key]
    if board then
        for index, value in ipairs(board.rows) do
            if nameKey(value.playerName) == identity then return index, value end
        end
    end
end

-- Rank(store, context, name) -> ordinal rank, detached row, error.
-- Ranks describe this stored board only, never completeness or a global quorum.
function Highscores.Rank(store, context, playerName)
    local parsed, reason = parseStore(store)
    if not parsed then return nil, nil, reason end
    local key, name = contextKey(context), Highscores.NormalizeName(playerName)
    if not key then return nil, nil, "invalid_context" end
    if not name then return nil, nil, "invalid_name" end
    local rank, value = rankIn(parsed, key, nameKey(name))
    if not rank then return nil, nil, "not_ranked" end
    return rank, value
end

-- FinishPlacement(beforeStore, afterStore, record) -> placement, error.
-- Call only for a once-latched eligible LOCAL finish, never from network receive
-- or catch-up. This pure, non-consuming assessment emits nothing and keeps no
-- notification history: repeated identical inputs give the identical placement.
-- The caller owns the once-only latch. The exact finish must be retained and
-- improve the known prior time.
-- tier reports current top 3/10; enteredTier is only the highest newly crossed
-- threshold, so a move from outside top 10 to rank 2 yields one top-3 event.
function Highscores.FinishPlacement(beforeStore, afterStore, record)
    local previous, problem = parseStore(beforeStore)
    if not previous then return nil, problem end
    local current, reason = parseStore(afterStore)
    if not current then return nil, reason end
    local key = contextKey(record)
    local parsed = key and row(record, key)
    if not parsed then return nil, "invalid_record" end
    local identity = nameKey(parsed.playerName)
    local previousRank, previousRow = rankIn(previous, key, identity)
    local rank, currentRow = rankIn(current, key, identity)
    if not currentRow or not sameRow(currentRow, parsed) then return nil, "not_retained" end
    if previousRow and parsed.totalTicks >= previousRow.totalTicks then return nil, "not_improved" end
    local tier = rank <= 3 and 3 or (rank <= 10 and 10 or nil)
    local enteredTier
    if rank <= 3 and (not previousRank or previousRank > 3) then enteredTier = 3
    elseif rank <= 10 and (not previousRank or previousRank > 10) then enteredTier = 10 end
    return {rank=rank, previousRank=previousRank, tier=tier, enteredTier=enteredTier,
        knownPlayers=#current.boards[key].rows, scope="known_board"}
end

if type(namespace) == "table" then namespace.Highscores = Highscores end
return Highscores
