-- Pure experimental start-clock packets. Millisecond clocks never wrap.
local _, namespace = ...
local Protocol = {VERSION=1, PREFIX="AZKCLK1", MAX_BYTES=64,
    MAX_SEQUENCE=46655, MAX_TIME=36^7-1}
local digits = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
local tags = {PING="P", PONG="O", PREPARE="R", COMMIT="C", ACK="A", CANCEL="X"}
local kinds = {P="PING", O="PONG", R="PREPARE", C="COMMIT", A="ACK", X="CANCEL"}
local lengths = {PING=19, PONG=33, PREPARE=34, COMMIT=18, ACK=15, CANCEL=12}
local reasonCodes = {timeout="0", clock_error="1", contradiction="2", late="3", error="4", left="5"}
local reasons = {["0"]="timeout", ["1"]="clock_error", ["2"]="contradiction",
    ["3"]="late", ["4"]="error", ["5"]="left"}
local fields = {
    PING={sample=true, t1=true}, PONG={sample=true, t1=true, t2=true, t3=true},
    PREPARE={epoch=true, low=true, high=true}, COMMIT={epoch=true},
    ACK={ackKind=true, ackSequence=true}, CANCEL={reason=true},
}
local commonFields = {kind=true, session=true, sequence=true}

local function integer(value, minimum, maximum)
    return type(value)=="number" and value==value and value>=minimum and value<=maximum
        and value%1==0
end

local function sessionOK(value)
    return type(value)=="string" and #value==6 and not value:find("[^A-Z0-9]")
end

local function encodeInteger(value, width, minimum, maximum)
    if not integer(value,minimum,maximum) then return nil end
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
        local digit = digits:find(payload:sub(index,index),1,true)
        if not digit then return nil end
        value = value*36+digit-1
    end
    return value
end

local function encodeSigned(value)
    if not integer(value,-Protocol.MAX_TIME,Protocol.MAX_TIME) then return nil end
    return (value<0 and "-" or "+")..encodeInteger(math.abs(value),7,0,Protocol.MAX_TIME)
end

local function decodeSigned(payload, first)
    local sign = payload:sub(first,first)
    local value = decodeInteger(payload,first+1,first+7)
    if (sign~="+" and sign~="-") or not value or (sign=="-" and value==0) then return nil end
    return sign=="-" and -value or value
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
    local body
    if kind=="PING" or kind=="PONG" then
        local sample = encodeInteger(message.sample,1,1,3)
        local t1 = encodeInteger(message.t1,7,0,Protocol.MAX_TIME)
        if not sample or not t1 then return nil,"invalid_sample" end
        body = sample..t1
        if kind=="PONG" then
            local t2 = encodeInteger(message.t2,7,0,Protocol.MAX_TIME)
            local t3 = encodeInteger(message.t3,7,0,Protocol.MAX_TIME)
            if not t2 or not t3 then return nil,"invalid_sample" end
            body = body..t2..t3
        end
    elseif kind=="PREPARE" then
        local epoch = encodeInteger(message.epoch,7,0,Protocol.MAX_TIME)
        local low,high = encodeSigned(message.low),encodeSigned(message.high)
        if not epoch or not low or not high or message.low>message.high
            or message.high-message.low>2004 then return nil,"invalid_prepare" end
        body = epoch..low..high
    elseif kind=="COMMIT" then
        body = encodeInteger(message.epoch,7,0,Protocol.MAX_TIME)
        if not body then return nil,"invalid_commit" end
    elseif kind=="ACK" then
        local ackTag = (message.ackKind=="PREPARE" or message.ackKind=="COMMIT") and tags[message.ackKind]
        local ackSequence = encodeInteger(message.ackSequence,3,1,Protocol.MAX_SEQUENCE)
        if not ackTag or not ackSequence then return nil,"invalid_ack" end
        body = ackTag..ackSequence
    elseif kind=="CANCEL" then
        body = type(message.reason)=="string" and reasonCodes[message.reason]
        if not body then return nil,"invalid_cancel" end
    end
    return "1"..tags[kind]..message.session..sequence..body
end

function Protocol.decode(payload)
    if type(payload)~="string" or #payload<11 or #payload>Protocol.MAX_BYTES then return nil,"invalid_size" end
    if payload:find("[^A-Z0-9+%-]") then return nil,"invalid_alphabet" end
    if payload:sub(1,1)~="1" then return nil,"invalid_version" end
    local kind = kinds[payload:sub(2,2)]
    if not kind then return nil,"invalid_kind" end
    if #payload~=lengths[kind] then return nil,"invalid_size" end
    local session = payload:sub(3,8)
    if not sessionOK(session) then return nil,"invalid_session" end
    local sequence = decodeInteger(payload,9,11)
    if not sequence or sequence==0 then return nil,"invalid_sequence" end
    local message = {kind=kind, session=session, sequence=sequence}
    if kind=="PING" or kind=="PONG" then
        message.sample = decodeInteger(payload,12,12)
        message.t1 = decodeInteger(payload,13,19)
        if kind=="PONG" then
            message.t2 = decodeInteger(payload,20,26)
            message.t3 = decodeInteger(payload,27,33)
        end
    elseif kind=="PREPARE" then
        message.epoch = decodeInteger(payload,12,18)
        message.low = decodeSigned(payload,19)
        message.high = decodeSigned(payload,27)
    elseif kind=="COMMIT" then
        message.epoch = decodeInteger(payload,12,18)
    elseif kind=="ACK" then
        message.ackKind = kinds[payload:sub(12,12)]
        message.ackSequence = decodeInteger(payload,13,15)
    elseif kind=="CANCEL" then
        message.reason = reasons[payload:sub(12,12)]
    end
    -- Reusing the strict encoder validates every field and enforces canonical signs.
    local canonical,problem = Protocol.encode(message)
    if not canonical then return nil,problem end
    if canonical~=payload then return nil,"noncanonical_message" end
    return message
end

if type(namespace)=="table" then namespace.ClockProtocol = Protocol end
return Protocol
