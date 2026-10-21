-- Pure codec checks only; no live clock or Forever transport claim.
local namespace = {}
local P = assert(loadfile("addon/AzerothKart/ClockProtocol.lua"))("AzerothKart",namespace)
assert(namespace.ClockProtocol==P and P.VERSION==1 and P.PREFIX=="AZKCLK1")
assert(P.MAX_BYTES==64 and P.MAX_SEQUENCE==46655 and P.MAX_TIME==36^7-1)

local function copy(source)
    local result = {}
    for key,value in pairs(source) do result[key]=value end
    return result
end
local function same(first,second)
    for key,value in pairs(first) do assert(second[key]==value,"field mismatch: "..tostring(key)) end
    for key,value in pairs(second) do assert(first[key]==value,"extra field: "..tostring(key)) end
end
local function message(kind,extra)
    local result = {kind=kind,session="ABC123",sequence=1}
    for key,value in pairs(extra or {}) do result[key]=value end
    return result
end
local function changed(source,field,value)
    local result = copy(source); result[field]=value
    return result
end
local function roundtrip(input,expected,length)
    local before = copy(input)
    local wire = assert(P.encode(input))
    assert(wire==expected,"exact wire differs: "..wire)
    assert(#wire==length and #wire<=P.MAX_BYTES)
    for _=1,3 do assert(P.encode(input)==wire,"deterministic encoding") end
    local decoded = assert(P.decode(wire))
    assert(decoded~=input,"decoder returns a fresh table")
    same(input,decoded); same(input,before)
    assert(P.encode(decoded)==wire,"canonical wire round trip")
    return wire
end
local ping = message("PING",{sample=1,t1=0})
local pong = message("PONG",{sample=3,t1=0,t2=36,t3=P.MAX_TIME})
local prepare = message("PREPARE",{epoch=36,low=-10,high=10})
local commit = message("COMMIT",{epoch=P.MAX_TIME})
local valid = {
    roundtrip(ping,"1PABC1230011".."0000000",19),
    roundtrip(pong,"1OABC1230013".."0000000".."0000010".."ZZZZZZZ",33),
    roundtrip(prepare,"1RABC123001".."0000010".."-000000A".."+000000A",34),
    roundtrip(commit,"1CABC123001ZZZZZZZ",18),
    roundtrip(message("ACK",{ackKind="PREPARE",ackSequence=1}),"1AABC123001R001",15),
    roundtrip(message("ACK",{ackKind="COMMIT",ackSequence=46655}),"1AABC123001CZZZ",15),
}
roundtrip(message("PING",{sample=2,t1=P.MAX_TIME,session="ZZZZZZ",sequence=46655}),
    "1PZZZZZZZZZ2ZZZZZZZ",19)
roundtrip(message("PREPARE",{epoch=0,low=0,high=0}),
    "1RABC123001".."0000000".."+0000000".."+0000000",34)
roundtrip(message("PREPARE",{epoch=P.MAX_TIME,low=P.MAX_TIME,high=P.MAX_TIME}),
    "1RABC123001".."ZZZZZZZ".."+ZZZZZZZ".."+ZZZZZZZ",34)
roundtrip(message("PREPARE",{epoch=P.MAX_TIME,low=-P.MAX_TIME,high=-P.MAX_TIME}),
    "1RABC123001".."ZZZZZZZ".."-ZZZZZZZ".."-ZZZZZZZ",34)
assert(P.encode(message("PREPARE",{epoch=0,low=-1002,high=1002})))
for index,reason in ipairs({"timeout","clock_error","contradiction","late","error","left"}) do
    valid[#valid+1] = roundtrip(message("CANCEL",{reason=reason}),"1XABC123001"..tostring(index-1),12)
end

local function refusedEncode(input)
    local ok,wire,problem = pcall(P.encode,input)
    assert(ok and wire==nil and type(problem)=="string" and #problem<=32,"fixed encode refusal")
end
local function refusedDecode(payload)
    local ok,result,problem = pcall(P.decode,payload)
    assert(ok and result==nil and type(problem)=="string" and #problem<=32,"fixed decode refusal")
end
for _,value in ipairs({true,1,"PING"}) do refusedEncode(value); refusedDecode(value) end
refusedEncode(nil); refusedDecode(nil); refusedDecode({})
refusedEncode(setmetatable(copy(ping),{__index=function() error("metamethod must not run") end}))
refusedEncode(setmetatable(copy(ping),{__metatable=false}))
for _,input in ipairs({ping,pong,prepare,commit,message("ACK",{ackKind="COMMIT",ackSequence=1}),
    message("CANCEL",{reason="left"})}) do
    refusedEncode(changed(input,"extra",true))
    refusedEncode(changed(input,1,"unexpected numeric key"))
    for field in pairs(input) do refusedEncode(changed(input,field,nil)) end
end
for _,kind in ipairs({"", "P", "ping", "UNKNOWN", false, 1, {}}) do
    refusedEncode(changed(ping,"kind",kind))
end
for _,session in ipairs({"", "ABC12", "ABC1234", "abc123", "ABC 23", "ABC|23", "AB+123",
    "AB-123", "ABC\00023", "ABC\12723", 123456, false, {}}) do
    refusedEncode(changed(ping,"session",session))
end
local badNumbers = {-1,0.5,0/0,math.huge,-math.huge,"1",true,{}}
for _,value in ipairs(badNumbers) do
    for _,field in ipairs({"sequence","sample","t1"}) do refusedEncode(changed(ping,field,value)) end
    for _,field in ipairs({"t2","t3"}) do refusedEncode(changed(pong,field,value)) end
    refusedEncode(changed(prepare,"epoch",value))
    refusedEncode(changed(commit,"epoch",value))
    refusedEncode(message("ACK",{ackKind="COMMIT",ackSequence=value}))
end
for _,field in ipairs({"sequence","sample"}) do refusedEncode(changed(ping,field,0)) end
refusedEncode(changed(ping,"sequence",46656)); refusedEncode(changed(ping,"sample",4))
for _,field in ipairs({"t1","t2","t3"}) do refusedEncode(changed(pong,field,P.MAX_TIME+1)) end
refusedEncode(changed(prepare,"epoch",P.MAX_TIME+1))
refusedEncode(changed(commit,"epoch",P.MAX_TIME+1))
for _,value in ipairs({0.5,0/0,math.huge,-math.huge,"1",true,{},P.MAX_TIME+1,-P.MAX_TIME-1}) do
    refusedEncode(changed(prepare,"low",value)); refusedEncode(changed(prepare,"high",value))
end
refusedEncode(changed(prepare,"low",11))
refusedEncode(message("PREPARE",{epoch=0,low=-1002,high=1003}))
for _,kind in ipairs({"PING","PONG","ACK","CANCEL","COMMIT ",0,false,{}}) do
    refusedEncode(message("ACK",{ackKind=kind,ackSequence=1}))
end
refusedEncode(message("ACK",{ackKind="PREPARE",ackSequence=0}))
refusedEncode(message("ACK",{ackKind="COMMIT",ackSequence=46656}))
for _,reason in ipairs({"", "LEFT", "combat", "untrusted text", 0, false, {}}) do
    refusedEncode(message("CANCEL",{reason=reason}))
end

for _,wire in ipairs(valid) do
    for index=0,#wire-1 do refusedDecode(wire:sub(1,index)) end
    refusedDecode(wire.."0"); refusedDecode(wire.." "); refusedDecode(wire.."\n")
    -- Every byte is syntax checked, including otherwise unused sign positions.
    for index=1,#wire do
        for _,bad in ipairs({"a","|"," ","\000","\127","\n","\195"}) do
            refusedDecode(wire:sub(1,index-1)..bad..wire:sub(index+1))
        end
        if wire:sub(index,index)~="+" and wire:sub(index,index)~="-" then
            refusedDecode(wire:sub(1,index-1).."+"..wire:sub(index+1))
            refusedDecode(wire:sub(1,index-1).."-"..wire:sub(index+1))
        end
    end
end
for _,wire in ipairs({"",string.rep("Z",65),"0PABC12300110000000","2PABC12300110000000",
    "1QABC12300110000000","1PABC12300010000000","1PABC12300100000000","1PABC12300140000000",
    "1AABC123001A001","1AABC123001P001","1AABC123001O001","1AABC123001X001",
    "1AABC123001C000","1XABC1230016",
    "1RABC123001".."0000000".."-0000000".."+0000000",
    "1RABC123001".."0000000".."+0000000".."-0000000",
    "1RABC123001".."0000000".."+0000001".."+0000000",
    "1RABC123001".."0000000".."-ZZZZZZZ".."+ZZZZZZZ"}) do refusedDecode(wire) end
print("Pure start-clock codec: canonical bounded clocks, signed intervals, exact packets and malformed-byte refusals verified offline")
