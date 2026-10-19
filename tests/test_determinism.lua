local T=dofile("addon/AzerothKart/Track.lua")
local P=dofile("addon/AzerothKart/Physics.lua")
local L=dofile("addon/AzerothKart/Loop.lua")
local fields={"x","y","heading","speed","tick","impacts","drifting","driftDirection",
              "driftTicks","driftTier","boostTicks","slipAngle"}
local ticks=10000

-- Local Park-Miller generator creates reproducible bounded test input vectors.
-- Simulation has no random mechanic yet and never touches shared math.randomseed.
local function inputTape(seed)
    local tape={}
    for tick=1,ticks do
        seed=(seed*48271)%2147483647
        tape[tick]={
            accelerate=seed%11>1,
            brake=seed%19==0,
            left=seed%8<3,
            right=seed%8>4,
            drift=seed%13>2,
        }
    end
    return tape
end

local function sameState(a,b,context)
    for _,key in ipairs(fields) do
        assert(a[key]==b[key],context..": non-deterministic field "..key)
    end
end

local tape=inputTape(1729)
local repeated=inputTape(1729)
local different=inputTape(1730)
local changed=false
for tick=1,ticks do
    for _,key in ipairs({"accelerate","brake","left","right","drift"}) do
        assert(tape[tick][key]==repeated[tick][key],"seeded input tape must repeat")
        if tape[tick][key]~=different[tick][key] then changed=true end
    end
end
assert(changed,"different seeds must exercise different inputs")

local reference={}
local state=P.new(T)
for tick=1,ticks do
    state=P.step(state,tape[tick],P.FIXED_DT,T)
    reference[tick]=state
end

for _,fps in ipairs({30,60,144}) do
    local clock=L.new(P.FIXED_DT,5)
    local replay=P.new(T)
    local function step(dt)
        local tick=replay.tick+1
        assert(tick<=ticks,"render cadence must not invent ticks")
        replay=P.step(replay,repeated[tick],dt,T)
        sameState(replay,reference[tick],fps.." FPS tick "..tick)
    end
    for _=1,ticks*fps/60 do L.advance(clock,1/fps,step) end
    assert(replay.tick==ticks,"expected exactly 10k ticks at "..fps.." FPS")
    assert(clock.droppedSeconds==0,"steady render cadence must not drop ticks")
    sameState(replay,state,"final state at "..fps.." FPS")
end
