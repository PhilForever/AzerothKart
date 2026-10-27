-- Pure, bounded observational telemetry. Peer authorization and delivery are
-- controller policy; a valid packet grants no race or physics authority.
local _, namespace = ...
local Protocol = {VERSION=2, PREFIX="AZKRUN2", MAX_BYTES=40, MAX_SEQUENCE=46655, MAX_TICK=108000}
local Layered = {VERSION=3, PREFIX="AZKRUN3", MAX_BYTES=40, MAX_SEQUENCE=46655, MAX_TICK=108000}
Protocol.Layered=Layered
local digits = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
local statuses = {running="0", finished="1", stopped="2", interrupted="3"}
local statusNames = {["0"]="running", ["1"]="finished", ["2"]="stopped", ["3"]="interrupted"}
local fields = {kind=true, session=true, sequence=true, tick=true, x=true, y=true,
    headingQ=true, speedQ=true, driftTier=true, boosting=true, completedLaps=true,
    passed=true, status=true, sampleMS=true}

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

local function coordinate(value)
    if type(value)~="number" then return nil end
    -- Public x/y are world units at quarter-unit resolution. The wire carries
    -- their integer indices; the codec never rounds caller state implicitly.
    return encodeInteger(value*4,3,0,46655)
end

local function encode(message, layered)
    if type(message)~="table" or getmetatable(message)~=nil then return nil,"invalid_message" end
    if message.kind~="STATE" then return nil,"invalid_kind" end
    for field in pairs(message) do
        if not fields[field] and not (layered and field=="level") then return nil,"invalid_fields" end
    end
    if not sessionOK(message.session) then return nil,"invalid_session" end
    local sequence = encodeInteger(message.sequence,3,1,Protocol.MAX_SEQUENCE)
    if not sequence then return nil,"invalid_sequence" end
    local tick = encodeInteger(message.tick,6,0,Protocol.MAX_TICK)
    if not tick then return nil,"invalid_tick" end
    local x,y = coordinate(message.x),coordinate(message.y)
    if not x or not y then return nil,"invalid_position" end
    -- headingQ spans one turn in 46656 bins. speedQ is signed in the
    -- controller's declared speed units; its wire index is offset by 550.
    local heading = encodeInteger(message.headingQ,3,0,46655)
    if not heading then return nil,"invalid_heading" end
    if not integer(message.speedQ,-550,2600) then return nil,"invalid_speed" end
    local speed = encodeInteger(message.speedQ+550,3,0,3150)
    if not integer(message.driftTier,0,2) then return nil,"invalid_drift" end
    if layered and not integer(message.level,0,1) then return nil,"invalid_level" end
    -- Level uses the drift byte's spare values, not another packet byte.
    local drift = encodeInteger(message.driftTier+(layered and message.level*3 or 0),1,0,5)
    if type(message.boosting)~="boolean" then return nil,"invalid_boosting" end
    local laps = encodeInteger(message.completedLaps,1,0,3)
    local passed = encodeInteger(message.passed,1,0,8)
    if not laps or not passed then return nil,"invalid_progress" end
    local status = type(message.status)=="string" and statuses[message.status]
    if not status then return nil,"invalid_status" end
    local stamp=encodeInteger(message.sampleMS,6,0,1800000)
    if not stamp then return nil,"invalid_sample" end
    return (layered and "3S" or "2S")..message.session..sequence..tick..x..y..heading..speed..drift
        ..(message.boosting and "1" or "0")..laps..passed..status..stamp
end

local function decode(payload, layered)
    if type(payload)~="string" or #payload~=Protocol.MAX_BYTES then return nil,"invalid_size" end
    if payload:find("[^A-Z0-9]") then return nil,"invalid_alphabet" end
    if payload:sub(1,1)~=(layered and "3" or "2") then return nil,"invalid_version" end
    if payload:sub(2,2)~="S" then return nil,"invalid_kind" end
    local sequence = decodeInteger(payload,9,11)
    if sequence==0 then return nil,"invalid_sequence" end
    local tick = decodeInteger(payload,12,17)
    if tick>Protocol.MAX_TICK then return nil,"invalid_tick" end
    local speed = decodeInteger(payload,27,29)
    if speed>3150 then return nil,"invalid_speed" end
    local drift = decodeInteger(payload,30,30)
    if drift>(layered and 5 or 2) then return nil,"invalid_drift" end
    local boosting = payload:sub(31,31)
    if boosting~="0" and boosting~="1" then return nil,"invalid_boosting" end
    local laps,passed = decodeInteger(payload,32,32),decodeInteger(payload,33,33)
    if laps>3 or passed>8 then return nil,"invalid_progress" end
    local status = statusNames[payload:sub(34,34)]
    if not status then return nil,"invalid_status" end
    local sampleMS=decodeInteger(payload,35,40)
    if sampleMS>1800000 then return nil,"invalid_sample" end
    local message={kind="STATE", session=payload:sub(3,8), sequence=sequence, tick=tick,
        x=decodeInteger(payload,18,20)/4, y=decodeInteger(payload,21,23)/4,
        headingQ=decodeInteger(payload,24,26), speedQ=speed-550, driftTier=drift%3,
        boosting=boosting=="1", completedLaps=laps, passed=passed, status=status,sampleMS=sampleMS}
    if layered then message.level=math.floor(drift/3) end
    return message
end

function Protocol.encode(message) return encode(message,false) end
function Protocol.decode(payload) return decode(payload,false) end
function Layered.encode(message) return encode(message,true) end
function Layered.decode(payload) return decode(payload,true) end

if type(namespace)=="table" then namespace.LiveProtocol = Protocol end
return Protocol
