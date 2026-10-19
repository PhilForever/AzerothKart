local P=dofile("addon/AzerothKart/Performance.lua")
assert(P.LIMIT==600,"profiler attempts have a fixed bounded budget")
local expectedFields={
    attempts=true,samples=true,invalid=true,
    simulationMs=true,simulationMaxMs=true,renderMs=true,renderMaxMs=true,
    totalMs=true,totalMaxMs=true,
}
local stats=P.new()
local fieldCount=0
for field,value in pairs(stats) do
    assert(expectedFields[field] and value==0,"new aggregate has only zeroed scalar fields")
    fieldCount=fieldCount+1
end
assert(fieldCount==9,"no individual samples or auxiliary tables retained")
assert(P.new()~=stats,"each measurement owns its aggregate")

assert(P.record(stats,100,102,105),"record simulation/render spans")
assert(P.record(stats,900,900,900),"zero-resolution samples are valid")
assert(P.record(stats,10,14,15),"samples are independent timestamp spans")
assert(stats.attempts==3 and stats.samples==3 and stats.invalid==0)
assert(stats.simulationMs==6 and stats.simulationMaxMs==4,"simulation totals/max")
assert(stats.renderMs==4 and stats.renderMaxMs==3,"render totals/max")
assert(stats.totalMs==10 and stats.totalMaxMs==5,"total spans include both phases")
assert(stats.simulationMs/stats.samples==2,"derived mean includes zero samples")
assert(math.abs(stats.renderMs/stats.samples-4/3)<1e-12,"render mean derives from total/count")
assert(math.abs(stats.totalMs/stats.samples-10/3)<1e-12,"total mean derives from total/count")

local function snapshot(value)
    local copy={}
    for field,number in pairs(value) do copy[field]=number end
    return copy
end
local function assertRejected(value,begin,mid,finish,message)
    local before=snapshot(value)
    assert(not P.record(value,begin,mid,finish),message)
    for field,number in pairs(before) do
        local delta=(field=="attempts" or field=="invalid") and 1 or 0
        assert(value[field]==number+delta,message.." changed "..field)
    end
end

assert(not P.validTimestamp(nil),"nil timestamp rejects")
-- nil cannot be traversed with ipairs, so test it explicitly in each position.
assertRejected(stats,nil,1,2,"missing initial timestamp")
assertRejected(stats,0,nil,2,"missing middle timestamp")
assertRejected(stats,0,1,nil,"missing final timestamp")
for _,value in ipairs({"1",false,0/0,math.huge,-math.huge,-1}) do
    assert(not P.validTimestamp(value),"invalid timestamp must reject")
    assertRejected(stats,value,1,2,"invalid initial timestamp")
    assertRejected(stats,0,value,2,"invalid middle timestamp")
    assertRejected(stats,0,1,value,"invalid final timestamp")
end
assert(P.validTimestamp(0) and P.validTimestamp(1e308),"finite nonnegative timestamps accept")
assertRejected(stats,10,9,11,"backwards simulation clock")
assertRejected(stats,10,11,10,"backwards render clock")

-- Finite inputs can overflow accumulated totals; preserve all prior aggregates.
local extreme=P.new()
assert(P.record(extreme,0,1e308,1e308),"large finite initial sample")
assertRejected(extreme,0,1e308,1e308,"simulation total overflow")
local extremeRender=P.new()
assert(P.record(extremeRender,0,0,1e308),"large finite render sample")
assertRejected(extremeRender,0,0,1e308,"render total overflow")
local extremeTotal=P.new()
assert(P.record(extremeTotal,0,5e307,1e308),"large finite combined sample")
assertRejected(extremeTotal,0,5e307,1e308,"combined total overflow")

-- Failed attempts consume budget too; all later calls must be mutation-free.
local capped=P.new()
for index=1,P.LIMIT do
    if index%2==0 then
        assertRejected(capped,0,nil,1,"invalid attempt consumes budget")
    else
        assert(P.record(capped,0,1,3),"valid attempt before cap")
    end
end
assert(capped.attempts==600 and capped.samples==300 and capped.invalid==300)
assert(capped.simulationMs==300 and capped.renderMs==600 and capped.totalMs==900)
local frozen=snapshot(capped)
assert(not P.record(capped,0,1,3),"valid call after cap rejects")
assert(not P.record(capped,nil,nil,nil),"invalid call after cap rejects")
for field,number in pairs(frozen) do assert(capped[field]==number,"cap preserves "..field) end

local beforeGlobal=_G.AzerothKart
local imported=dofile("addon/AzerothKart/Performance.lua")
assert(type(imported.record)=="function" and _G.AzerothKart==beforeGlobal,
       "standalone import requires no global addon namespace")
local namespace={}
local injected=assert(loadfile("addon/AzerothKart/Performance.lua"))("AzerothKart",namespace)
assert(injected==namespace.Performance,"injected namespace receives returned module")
assert(_G.AzerothKart==beforeGlobal,"namespace registration leaves global addon untouched")
