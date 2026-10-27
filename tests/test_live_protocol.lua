-- Offline telemetry syntax only: these checks establish no delivery or authority.
local namespace = {}
local P = assert(loadfile("addon/AzerothKart/LiveProtocol.lua"))("AzerothKart",namespace)
assert(namespace.LiveProtocol==P and P.VERSION==2 and P.PREFIX=="AZKRUN2")
assert(P.MAX_BYTES==40 and P.MAX_SEQUENCE==46655 and P.MAX_TICK==108000)

local function copy(source)
    local result = {}
    for key,value in pairs(source) do result[key]=value end
    return result
end
local function same(first,second)
    for key,value in pairs(first) do assert(second[key]==value,"field mismatch: "..tostring(key)) end
    for key,value in pairs(second) do assert(first[key]==value,"extra field: "..tostring(key)) end
end
local base = {kind="STATE", session="ABC123", sequence=1, tick=0, x=0, y=0,
    headingQ=0, speedQ=-550, driftTier=0, boosting=false, completedLaps=0, passed=0,
    status="running", sampleMS=0}
local function changed(field,value)
    local result = copy(base); result[field]=value
    return result
end
local function roundtrip(message,expected)
    local before = copy(message)
    local wire = assert(P.encode(message))
    assert(#wire==40 and not wire:find("[^A-Z0-9]"),"fixed ASCII wire")
    if expected then assert(wire==expected,"exact wire differs") end
    for _=1,3 do assert(P.encode(message)==wire,"encoding must be deterministic") end
    local decoded = assert(P.decode(wire))
    same(message,decoded); same(message,before)
    assert(P.encode(decoded)==wire,"canonical decode/encode round trip")
    decoded.x=10; decoded.session="ZZZZZZ"
    same(message,before)
    same(assert(P.decode(wire)),before)
    return wire
end
local wire = roundtrip(base,"2SABC123001"..string.rep("0",29))
local maximum = {kind="STATE", session="ZZZZZZ", sequence=46655, tick=108000,
    x=11663.75, y=11663.75, headingQ=46655, speedQ=2600, driftTier=2, boosting=true,
    completedLaps=3, passed=8, status="interrupted",sampleMS=1800000}
roundtrip(maximum,"2SZZZZZZZZZ002BC0ZZZZZZZZZ2FI21383012KW0")
for _,status in ipairs({"running","finished","stopped","interrupted"}) do
    local sample = copy(base)
    sample.status,sample.x,sample.y,sample.headingQ,sample.speedQ = status,100.25,2048,1537,0
    roundtrip(sample)
end
for _,speed in ipairs({-550,-549,-1,0,1,2599,2600}) do roundtrip(changed("speedQ",speed)) end
for _,position in ipairs({0,0.25,1,13.75,11663.5,11663.75}) do
    roundtrip(changed("x",position)); roundtrip(changed("y",position))
end

local function refusedEncode(input)
    local ok,result,problem = pcall(P.encode,input)
    assert(ok and result==nil and type(problem)=="string" and #problem<=32,"fixed encode refusal")
end
local function refusedDecode(payload)
    local ok,result,problem = pcall(P.decode,payload)
    assert(ok and result==nil and type(problem)=="string" and #problem<=32,"fixed decode refusal")
end
refusedEncode(nil); refusedEncode(true); refusedEncode(1); refusedEncode("STATE")
refusedEncode(setmetatable(copy(base),{__index=function() error("must not invoke metamethods") end}))
refusedEncode(setmetatable(copy(base),{__metatable=false}))
refusedEncode(changed("unknown","untrusted")); refusedEncode(changed(1,0))
refusedEncode(changed({},0)); refusedEncode(changed("version",1))
for field in pairs(base) do refusedEncode(changed(field,nil)) end
for _,kind in ipairs({"S","state","UNKNOWN","",1,false,{}}) do refusedEncode(changed("kind",kind)) end
for _,session in ipairs({"","ABC12","ABC1234","abc123","ABC 23","ABC|23","ABC\00023",
    "ABC\12723",123456,false,{}}) do refusedEncode(changed("session",session)) end
for _,field in ipairs({"sequence","tick","x","y","headingQ","speedQ","driftTier","completedLaps","passed","sampleMS"}) do
    for _,value in ipairs({0/0,math.huge,-math.huge,"0",true,false,{}}) do
        refusedEncode(changed(field,value))
    end
end
for _,field in ipairs({"sequence","tick","headingQ","speedQ","driftTier","completedLaps","passed","sampleMS"}) do
    refusedEncode(changed(field,0.5))
end
for field,bounds in pairs({sequence={1,46655}, tick={0,108000}, x={0,11663.75},
    y={0,11663.75}, headingQ={0,46655}, speedQ={-550,2600}, driftTier={0,2},
    completedLaps={0,3}, passed={0,8},sampleMS={0,1800000}}) do
    refusedEncode(changed(field,bounds[1]-1)); refusedEncode(changed(field,bounds[2]+1))
end
for _,field in ipairs({"x","y"}) do
    refusedEncode(changed(field,0.1)); refusedEncode(changed(field,100.125))
end
for _,value in ipairs({0,1,"true","false",{}}) do refusedEncode(changed("boosting",value)) end
for _,value in ipairs({"RUNNING","finish","0","",0,false,{}}) do refusedEncode(changed("status",value)) end

refusedDecode(nil); refusedDecode(true); refusedDecode(1); refusedDecode({})
for index=0,#wire-1 do refusedDecode(wire:sub(1,index)) end
refusedDecode(wire.."0"); refusedDecode(wire.." "); refusedDecode(wire.."\n")
refusedDecode(string.rep("0",1000))
local function replaced(first,last,value)
    return wire:sub(1,first-1)..value..wire:sub(last+1)
end
for _,value in ipairs({"a","|"," ","\000","\127","\n"}) do
    for index=1,#wire do refusedDecode(replaced(index,index,value)) end
end
refusedDecode(replaced(1,1,"0")); refusedDecode(replaced(1,1,"1"))
refusedDecode(replaced(2,2,"R")); refusedDecode(replaced(9,11,"000"))
refusedDecode(replaced(12,17,"002BC1")); refusedDecode(replaced(12,17,"ZZZZZZ"))
refusedDecode(replaced(27,29,"2FJ")); refusedDecode(replaced(27,29,"ZZZ"))
refusedDecode(replaced(30,30,"3")); refusedDecode(replaced(31,31,"2"))
refusedDecode(replaced(32,32,"4")); refusedDecode(replaced(33,33,"9"))
refusedDecode(replaced(34,34,"4")); refusedDecode(replaced(34,34,"Z"))
refusedDecode(replaced(35,40,"012KW1")); refusedDecode(replaced(35,40,"ZZZZZZ"))
print("Pure live telemetry codec: exact 40-byte timestamped packets, bounded quantized fields, strict syntax and detached round trips verified offline")

-- Layered courses negotiate a separate codec. Flat packets stay byte-exact;
-- explicit level0/1 uses spare drift-byte values without growing the packet.
local layered=P.Layered
assert(layered.VERSION==3 and layered.PREFIX=="AZKRUN3" and layered.MAX_BYTES==40)
for level=0,1 do
    for tier=0,2 do
        local input=copy(base);input.level,input.driftTier=level,tier
        local payload=assert(layered.encode(input))
        assert(#payload==40 and #payload+#layered.PREFIX==47 and payload:sub(1,2)=="3S")
        same(assert(layered.decode(payload)),input)
        assert(not P.decode(payload) and not layered.decode(assert(P.encode(base))),
            "flat and layered protocol versions never silently mix")
        for index=0,#payload-1 do assert(not layered.decode(payload:sub(1,index))) end
        assert(not layered.decode(payload.."0"))
        local corrupted=payload:sub(1,29).."6"..payload:sub(31)
        assert(not layered.decode(corrupted),"unused packed level/drift values are rejected")
    end
end
local missing=copy(base)
assert(not layered.encode(missing),"layered state must carry its explicit level")
for _,invalid in ipairs({-1,2,0.5,0/0,math.huge,false,"1",{}}) do
    local input=copy(base);input.level=invalid
    assert(not layered.encode(input),"invalid floor is not guessed or coerced")
end
local flatWithLevel=copy(base);flatWithLevel.level=0
assert(not P.encode(flatWithLevel),"legacy flat syntax is unchanged")
print("Layered live codec: explicit0/1 floors and drift tiers, strict3S/2S separation, same40-byte payload PASS")
