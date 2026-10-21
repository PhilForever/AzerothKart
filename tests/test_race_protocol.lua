-- Offline codec checks only: these packets do not implement a live handshake.
local namespace = {}
local P = assert(loadfile("addon/AzerothKart/RaceProtocol.lua"))("AzerothKart",namespace)
assert(namespace.RaceProtocol==P and P.VERSION==2 and P.PREFIX=="AZKART2")
assert(P.MAX_BYTES==128 and P.MAX_SEQUENCE==46655)

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
local function roundtrip(input,expected)
    local before = copy(input)
    local wire = assert(P.encode(input))
    assert(wire==expected,"exact wire differs")
    assert(#wire<=P.MAX_BYTES and not wire:find("[^A-Z0-9]"))
    for _=1,3 do assert(P.encode(input)==wire,"repeat encoding must be deterministic") end
    local decoded = assert(P.decode(wire))
    same(input,decoded); same(input,before)
    assert(P.encode(decoded)==wire,"canonical decode/encode round trip")
    return wire
end

local invite = message("INVITE",{physicsVersion=7,trackId="test_oval",trackVersion=2,laps=3})
local inviteWire = roundtrip(invite,"2IABC123001070023")
assert(#inviteWire==17)
roundtrip(message("INVITE",{physicsVersion=1,trackId="mirage_raceway",trackVersion=1,laps=1}),
    "2IABC123001011011")
local maximum = message("INVITE",{physicsVersion=1295,trackId="mirage_raceway",trackVersion=1295,laps=9})
maximum.session,maximum.sequence="ZZZZZZ",46655
roundtrip(maximum,"2IZZZZZZZZZZZ1ZZ9")
-- Compatibility is controller policy: unknown numeric versions remain valid data.
local future = message("INVITE",{physicsVersion=1294,trackId="test_oval",trackVersion=1294,laps=9})
same(assert(P.decode(assert(P.encode(future)))),future)

local joinWire = roundtrip(message("JOIN"),"2JABC123001")
roundtrip(message("JOIN",{sequence=46655,session="000000"}),"2J000000ZZZ")
roundtrip(message("READY",{ready=false}),"2RABC1230010")
roundtrip(message("READY",{ready=true}),"2RABC1230011")
local startWire = roundtrip(message("START",{startTick=0,seed=0}),"2SABC123001000000000000")
roundtrip(message("START",{startTick=36^6-1,seed=2147483647}),"2SABC123001ZZZZZZZIK0ZJ")
for index,reason in ipairs({"left","timeout","incompatible","combat","world_leave","error"}) do
    roundtrip(message("CANCEL",{reason=reason}),"2XABC123001"..tostring(index-1))
end
for _,kind in ipairs({"INVITE","JOIN","READY","START","CANCEL"}) do
    local tag = ({INVITE="I",JOIN="J",READY="R",START="S",CANCEL="X"})[kind]
    roundtrip(message("ACK",{ackKind=kind,ackSequence=1}),"2AABC123001"..tag.."001")
    roundtrip(message("ACK",{ackKind=kind,ackSequence=46655}),"2AABC123001"..tag.."ZZZ")
end

local function refusedEncode(input)
    local ok,wire,problem = pcall(P.encode,input)
    assert(ok and wire==nil and type(problem)=="string" and #problem<=32,"fixed encode refusal")
end
local function changed(base,field,value)
    local result = copy(base); result[field]=value
    return result
end
refusedEncode(nil); refusedEncode(true); refusedEncode(1); refusedEncode("JOIN")
refusedEncode(setmetatable(message("JOIN"),{__index=function() error("do not invoke metamethods") end}))
refusedEncode(message("JOIN",{extra="untrusted text"}))
refusedEncode(message("JOIN",{ready=false}))
for _,kind in ipairs({"", "I", "invite", "UNKNOWN", "ACK ", false, 1, {}}) do
    refusedEncode(changed(invite,"kind",kind))
end
for _,session in ipairs({"", "ABC12", "ABC1234", "abc123", "ABC 23", "ABC|23", "ABC\00023", "ABC\12723", 123456, false, {}}) do
    refusedEncode(changed(invite,"session",session))
end
refusedEncode(changed(invite,"session",nil))
local badNumbers = {-1,0.5,0/0,math.huge,-math.huge,"1",true,{}}
for _,value in ipairs(badNumbers) do
    for _,field in ipairs({"sequence","physicsVersion","trackVersion","laps"}) do
        refusedEncode(changed(invite,field,value))
    end
    for _,field in ipairs({"startTick","seed"}) do
        refusedEncode(changed(message("START",{startTick=0,seed=0}),field,value))
    end
    refusedEncode(message("ACK",{ackKind="INVITE",ackSequence=value}))
end
for _,field in ipairs({"sequence","physicsVersion","trackVersion","laps"}) do
    refusedEncode(changed(invite,field,0)); refusedEncode(changed(invite,field,nil))
end
refusedEncode(changed(invite,"sequence",46656))
refusedEncode(changed(invite,"physicsVersion",1296)); refusedEncode(changed(invite,"trackVersion",1296))
refusedEncode(changed(invite,"laps",10))
for _,track in ipairs({"", "unknown", "TEST_OVAL", 0, false, {}}) do
    refusedEncode(changed(invite,"trackId",track))
end
refusedEncode(changed(invite,"trackId",nil))
for _,value in ipairs({0,1,"true","false",{}}) do refusedEncode(message("READY",{ready=value})) end
refusedEncode(message("READY"))
refusedEncode(message("START",{startTick=36^6,seed=0}))
refusedEncode(message("START",{startTick=0,seed=2147483648}))
refusedEncode(message("START",{seed=0})); refusedEncode(message("START",{startTick=0}))
for _,reason in ipairs({"", "LEFT", "arbitrary text", 0, false, {}}) do
    refusedEncode(message("CANCEL",{reason=reason}))
end
refusedEncode(message("CANCEL"))
for _,kind in ipairs({"ACK","A","invite","UNKNOWN",0,false,{}}) do
    refusedEncode(message("ACK",{ackKind=kind,ackSequence=1}))
end
refusedEncode(message("ACK",{ackSequence=1}))
refusedEncode(message("ACK",{ackKind="JOIN"}))
refusedEncode(message("ACK",{ackKind="JOIN",ackSequence=0}))
refusedEncode(message("ACK",{ackKind="JOIN",ackSequence=46656}))

local function refusedDecode(payload)
    local ok,result,problem = pcall(P.decode,payload)
    assert(ok and result==nil and type(problem)=="string" and #problem<=32,"fixed decode refusal")
end
refusedDecode(nil); refusedDecode(true); refusedDecode(2); refusedDecode({})
for _,payload in ipairs({"",string.rep("Z",129),"1JABC123001","3JABC123001","2BABC123001",
    "2Jabc123001","2JABC123000","2JABC12300a","2JABC12300|","2JABC12300 ",
    "2JABC12300\000","2JABC12300\127","2JABC12300\n","2JABC12300\195\184",
    "2IABC123001000023","2IABC123001072023","2IABC123001070003",
    "2IABC123001070020","2IABC12300107002A","2RABC1230012",
    "2SABC123001000000ZIK0ZK","2XABC1230016","2XABC123001Z",
    "2AABC123001A001","2AABC123001B001","2AABC123001J000"}) do
    refusedDecode(payload)
end
for _,wire in ipairs({inviteWire,joinWire,startWire,"2RABC1230011","2XABC1230010","2AABC123001I001"}) do
    for index=0,#wire-1 do refusedDecode(wire:sub(1,index)) end
    refusedDecode(wire.."0"); refusedDecode(wire.." "); refusedDecode(wire.."\n")
end
print("Pure race control codec: bounded exact packets, strict fields, compatibility data and deterministic round trips verified offline")
