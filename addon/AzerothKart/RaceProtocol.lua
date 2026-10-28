-- Pure control-message codec. No transport, clock agreement or session controller.
local _, namespace = ...
local Protocol = {VERSION=2, PREFIX="AZKART2", MAX_BYTES=128, MAX_SEQUENCE=46655}
local digits = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
local tags = {INVITE="I", JOIN="J", READY="R", START="S", CANCEL="X", ACK="A"}
local kinds = {I="INVITE", J="JOIN", R="READY", S="START", X="CANCEL", A="ACK"}
local lengths = {INVITE=17, JOIN=11, READY=12, START=23, CANCEL=12, ACK=15}
-- Code 0 is retired. Preserve Mirage's existing wire code and packet layout.
local trackCodes = {mirage_raceway="1", stormwind_city="2", ironforge_gp="3",
    darnassus_canopy="4", orgrimmar_canyon="5", undercity_slime="6", thunder_bluff_skyway="7",
    scarlet_graveyard="8", scarlet_library="9", scarlet_armory="A", scarlet_cathedral="B", warsong_gulch="C", arathi_basin="D", alterac_valley="E"}
local trackIds = {["1"]="mirage_raceway", ["2"]="stormwind_city", ["3"]="ironforge_gp",
    ["4"]="darnassus_canopy", ["5"]="orgrimmar_canyon", ["6"]="undercity_slime", ["7"]="thunder_bluff_skyway",
    ["8"]="scarlet_graveyard", ["9"]="scarlet_library", A="scarlet_armory", B="scarlet_cathedral", C="warsong_gulch", D="arathi_basin", E="alterac_valley"}
local reasonCodes = {left="0", timeout="1", incompatible="2", combat="3", world_leave="4", error="5"}
local reasons = {["0"]="left", ["1"]="timeout", ["2"]="incompatible", ["3"]="combat",
    ["4"]="world_leave", ["5"]="error"}
local fields = {
    INVITE={physicsVersion=true, trackId=true, trackVersion=true, laps=true},
    JOIN={}, READY={ready=true}, START={startTick=true, seed=true},
    CANCEL={reason=true}, ACK={ackKind=true, ackSequence=true},
}
local commonFields = {kind=true, session=true, sequence=true}
local MAX_TICK, MAX_SEED = 36^6-1, 2147483647

local function integer(value, minimum, maximum)
    return type(value)=="number" and value==value and value>=minimum and value<=maximum
        and value%1==0
end

local function sessionOK(value)
    return type(value)=="string" and #value==6 and not value:find("[^A-Z0-9]")
end

local function encodeInteger(value, width, minimum, maximum)
    if not integer(value, minimum, maximum) then return nil end
    local parts = {}
    for index=width,1,-1 do
        local digit = value%36
        parts[index] = digits:sub(digit+1,digit+1)
        value = math.floor(value/36)
    end
    return table.concat(parts)
end

local function decodeInteger(payload, first, last)
    local value = 0
    for index=first,last do
        value = value*36 + assert(digits:find(payload:sub(index,index),1,true))-1
    end
    return value
end

function Protocol.encode(message)
    if type(message)~="table" or getmetatable(message)~=nil then return nil,"invalid_message" end
    local kind = message.kind
    if type(kind)~="string" or not tags[kind] then return nil,"invalid_kind" end
    for field in pairs(message) do
        if not commonFields[field] and not fields[kind][field] then return nil,"invalid_fields" end
    end
    if not sessionOK(message.session) then return nil,"invalid_session" end
    local sequence = encodeInteger(message.sequence,3,1,Protocol.MAX_SEQUENCE)
    if not sequence then return nil,"invalid_sequence" end
    local body = ""
    if kind=="INVITE" then
        local physics = encodeInteger(message.physicsVersion,2,1,1295)
        local track = type(message.trackId)=="string" and trackCodes[message.trackId]
        local version = encodeInteger(message.trackVersion,2,1,1295)
        local laps = encodeInteger(message.laps,1,1,9)
        if not physics or not track or not version or not laps then return nil,"invalid_invite" end
        body = physics..track..version..laps
    elseif kind=="READY" then
        if type(message.ready)~="boolean" then return nil,"invalid_ready" end
        body = message.ready and "1" or "0"
    elseif kind=="START" then
        local tick = encodeInteger(message.startTick,6,0,MAX_TICK)
        local seed = encodeInteger(message.seed,6,0,MAX_SEED)
        if not tick or not seed then return nil,"invalid_start" end
        body = tick..seed
    elseif kind=="CANCEL" then
        body = type(message.reason)=="string" and reasonCodes[message.reason]
        if not body then return nil,"invalid_cancel" end
    elseif kind=="ACK" then
        local ackTag = type(message.ackKind)=="string" and tags[message.ackKind]
        local ackSequence = encodeInteger(message.ackSequence,3,1,Protocol.MAX_SEQUENCE)
        if not ackTag or ackTag=="A" or not ackSequence then return nil,"invalid_ack" end
        body = ackTag..ackSequence
    end
    return "2"..tags[kind]..message.session..sequence..body
end

function Protocol.decode(payload)
    if type(payload)~="string" or #payload<11 or #payload>Protocol.MAX_BYTES then return nil,"invalid_size" end
    if payload:find("[^A-Z0-9]") then return nil,"invalid_alphabet" end
    if payload:sub(1,1)~="2" then return nil,"invalid_version" end
    local kind = kinds[payload:sub(2,2)]
    if not kind then return nil,"invalid_kind" end
    if #payload~=lengths[kind] then return nil,"invalid_size" end
    local session = payload:sub(3,8)
    if not sessionOK(session) then return nil,"invalid_session" end
    local sequence = decodeInteger(payload,9,11)
    if sequence==0 then return nil,"invalid_sequence" end
    local message = {kind=kind, session=session, sequence=sequence}
    if kind=="INVITE" then
        message.physicsVersion = decodeInteger(payload,12,13)
        message.trackId = trackIds[payload:sub(14,14)]
        message.trackVersion = decodeInteger(payload,15,16)
        message.laps = decodeInteger(payload,17,17)
        if message.physicsVersion==0 or not message.trackId or message.trackVersion==0
            or message.laps<1 or message.laps>9 then return nil,"invalid_invite" end
    elseif kind=="READY" then
        local ready = payload:sub(12,12)
        if ready~="0" and ready~="1" then return nil,"invalid_ready" end
        message.ready = ready=="1"
    elseif kind=="START" then
        message.startTick = decodeInteger(payload,12,17)
        message.seed = decodeInteger(payload,18,23)
        if message.seed>MAX_SEED then return nil,"invalid_start" end
    elseif kind=="CANCEL" then
        message.reason = reasons[payload:sub(12,12)]
        if not message.reason then return nil,"invalid_cancel" end
    elseif kind=="ACK" then
        message.ackKind = kinds[payload:sub(12,12)]
        message.ackSequence = decodeInteger(payload,13,15)
        if not message.ackKind or message.ackKind=="ACK" or message.ackSequence==0 then return nil,"invalid_ack" end
    end
    return message
end

if type(namespace)=="table" then namespace.RaceProtocol = Protocol end
return Protocol
