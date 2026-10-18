local L=dofile("addon/AzerothKart/Loop.lua")
local function near(a,b,message)
    assert(math.abs(a-b)<1e-10,message)
end
local clock=L.new(1/60,5)
local count=0
local simulated=0
local function step(dt)
    count=count+1
    simulated=simulated+dt
end
assert(L.advance(clock,1/120,step)==0,"fractional frame must wait for full tick")
assert(L.advance(clock,1/120,step)==1,"fractional frames combine into one tick")
assert(count==1 and clock.steps==1 and clock.frames==2,"clock metrics count work")
near(clock.accumulator,0,"no residual after exact tick")

local hitch=0.537
assert(L.advance(clock,hitch,step)==5,"hitch work must respect catch-up budget")
assert(clock.lastSteps==5 and clock.hitchFrames==1,"hitch metrics count dropped frames")
assert(clock.maxElapsed==hitch,"record full frame time before dropping ticks")
assert(clock.accumulator>=0 and clock.accumulator<clock.dt,"retain only fractional tick")
near(simulated+clock.droppedSeconds+clock.accumulator,1/60+hitch,
     "simulated + dropped + residual must account for elapsed time")
assert(clock.droppedSeconds>0.4,"a long hitch cannot vanish through elapsed clamp")
local residual=clock.accumulator
assert(L.advance(clock,clock.dt-residual,step)==1,"hitch fractional remainder must survive")

local before={}
for key,value in pairs(clock) do before[key]=value end
for _,invalid in ipairs({-1,math.huge,-math.huge,"0.1",false}) do
    assert(L.advance(clock,invalid,step)==0,"invalid elapsed must be ignored")
end
assert(L.advance(clock,nil,step)==0,"nil elapsed must be ignored")
assert(L.advance(clock,0/0,step)==0,"NaN elapsed must be ignored")
for key,value in pairs(before) do assert(clock[key]==value,"invalid elapsed changed "..key) end

for _,config in ipairs({{0,5},{-1,5},{math.huge,5},{1/60,0},{1/60,1.5}}) do
    assert(not pcall(L.new,config[1],config[2]),"invalid clock configuration must reject")
end
local extreme=L.new()
assert(L.advance(extreme,1e308,function() end)==5,"finite extreme frame remains bounded")
assert(extreme.accumulator>=0 and extreme.accumulator<extreme.dt,
       "finite extreme elapsed must not poison accumulator")
assert(extreme.droppedSeconds<math.huge,"finite dropped time must remain finite")
local beforeGlobal=_G.AzerothKart
dofile("addon/AzerothKart/Loop.lua")
assert(_G.AzerothKart==beforeGlobal,"loop import must remain pure")
