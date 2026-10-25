-- Profile tradeoffs and deterministic replay; native game feel remains pending.
local P=dofile("addon/AzerothKart/Physics.lua")
local L=dofile("addon/AzerothKart/Loop.lua")
local T=dofile("addon/AzerothKart/Track.lua")
local dt=P.FIXED_DT
local open={spawn=function() return {x=0,y=0,heading=0} end,isDrivable=function() return true end}
local fields={"x","y","heading","speed","tick","impacts","drifting","driftDirection",
    "driftTicks","driftTier","driftGraceTicks","boostTicks","slipAngle","surface","steering"}
local cases={{kart="goblin_mortar_trike",id="balanced"},{kart="steam_tank",id="heavy"},
    {kart="dwarven_biker",id="agile"}}
local function close(a,b,message) assert(math.abs(a-b)<1e-9,message) end
local function same(a,b,message)
    for _,field in ipairs(fields) do assert(a[field]==b[field],message.." "..field) end
end
assert(P.VERSION==11,"kart profiles start a new handling compatibility version")
local mapping={basic="balanced",goblin_mortar_trike="balanced",dwarf_car="balanced",
    glaive_thrower="balanced",goblin_drag_car="balanced",steam_tank="heavy",
    orc_demolisher="heavy",meat_wagon="heavy",dwarven_biker="agile",
    gryphon_rider="agile",gyrocopter="agile"}
assert(P.GetHandling().id=="balanced")
for kart,id in pairs(mapping) do assert(P.GetHandling(kart).id==id,"known kart maps to its profile") end
for _,bad in ipairs({false,1,{},"","unknown_kart","Heavy","STEAM_TANK"}) do
    local profile,reason=P.GetHandling(bad)
    assert(profile==nil and reason=="invalid_kart","unknown handling is rejected")
    assert(not pcall(P.step,P.new(open),{},dt,open,bad),"unknown step cannot silently use another profile")
end
local copied=P.GetHandling("steam_tank")
copied.accel,copied.maxSpeed,copied.id=9999,9999,"changed"
assert(P.GetHandling("steam_tank").accel==148.8 and P.GetHandling("steam_tank").id=="heavy")
local fresh=P.new(open)
local count=0
for _ in pairs(fresh) do count=count+1 end
assert(count==#fields,"handling identity is explicit input, not a new authoritative state field")
same(P.step(fresh,{accelerate=true},dt,open),
    P.step(fresh,{accelerate=true},dt,open,"basic"),"legacy nil/basic balanced step")
assert(fresh.speed==0 and fresh.tick==0,"step leaves its input state untouched")

local metrics={}
for _,case in ipairs(cases) do
    local kart,h=case.kart,P.GetHandling(case.kart)
    local state=P.new(open)
    local metric={}
    for tick=1,1200 do
        state=P.step(state,{accelerate=true},dt,open,kart)
        if not metric.half and state.speed>=100 then metric.half=tick end
        if not metric.full and state.speed>=h.maxSpeed then metric.full=tick end
        if not metric.straight and state.x>=2000 then metric.straight=tick;break end
    end
    assert(metric.straight and state.speed==h.maxSpeed,"straight reaches bounded cruising cap")
    local braked=P.new(open);braked.speed=h.maxSpeed
    metric.stop,metric.brakeDistance=0,0
    while braked.speed>0 and metric.stop<120 do
        local x=braked.x
        braked=P.step(braked,{brake=true},dt,open,kart)
        metric.brakeDistance=metric.brakeDistance+braked.x-x
        metric.stop=metric.stop+1
    end
    assert(braked.speed<=0 and metric.stop<120,"every kart can brake to rest")
    local turn=P.new(open);turn.speed,turn.steering=h.maxSpeed,1
    local turned=P.step(turn,{accelerate=true,left=true},dt,open,kart)
    metric.radius=h.maxSpeed/((turned.heading-turn.heading)/dt)
    local initial=P.step(P.new(open),{left=true},dt,open,kart)
    close(initial.steering,h.steeringRiseRate*dt,"profile steering rise is active")
    local reversed=P.new(open)
    for _=1,120 do reversed=P.step(reversed,{brake=true},dt,open,kart) end
    close(reversed.speed,-55,"all karts retain common reverse limit")
    local boost=P.new(open);boost.speed,boost.boostTicks=h.maxSpeed,100
    for _=1,90 do
        boost=P.step(boost,{accelerate=true},dt,open,kart)
        assert(boost.speed<=260,"boost never exceeds common cap")
    end
    close(boost.speed,260,"all karts reach common boost cap")
    local bend=P.new(T);bend.speed=h.maxSpeed
    local tierOne
    for tick=1,60 do
        bend=P.step(bend,{accelerate=true,left=true,drift=true},dt,T,kart)
        assert(bend.impacts==0 and bend.surface=="road","each profile charges on the actual oval opening bend")
        assert(bend.driftTicks==tick,"charge still counts identical fixed ticks")
        if tick==30 then tierOne=bend end
    end
    assert(tierOne.driftTier==1 and bend.driftTier==2,"same drift tier thresholds for every kart")
    for _,reward in ipairs({{state=tierOne,ticks=30},{state=bend,ticks=48}}) do
        local released=P.step(reward.state,{accelerate=true,left=true},dt,open,kart)
        assert(released.boostTicks==reward.ticks-1 and released.speed>h.maxSpeed,
            "release awards the shared boost duration and consumes its first tick")
    end
    local wall={spawn=open.spawn,isDrivable=open.isDrivable,
        resolveMovement=function(_,_,x,y) return x,y,true end}
    local brush=P.new(wall);brush.speed=100
    brush=P.step(brush,{accelerate=true},dt,wall,kart)
    close(brush.speed,(100+h.accel*dt)*0.90,"first contact retains 90% after common geometry adjustment")
    local scrape=P.new(wall);scrape.speed,scrape.surface=h.maxSpeed,"wall"
    scrape=P.step(scrape,{accelerate=true},dt,wall,kart)
    close(scrape.speed,h.maxSpeed*0.80,"scraping is capped at 80% of this kart's top speed")
    local blocked={spawn=open.spawn,isDrivable=open.isDrivable,
        resolveMovement=function(x,y) return x,y,true end}
    local hit=P.new(blocked);hit.speed=h.maxSpeed
    hit=P.step(hit,{accelerate=true,left=true},dt,blocked,kart)
    assert(hit.speed==0 and hit.impacts==1 and hit.steering>0,"frontal block stops but preserves recovery steering")
    metrics[case.id]=metric
    print(("kart %s: 0-100=%d cap=%d straight2000=%d brake=%d distance=%.3f turnRadius=%.3f")
        :format(case.id,metric.half,metric.full,metric.straight,metric.stop,metric.brakeDistance,metric.radius))
end
local b,h,a=metrics.balanced,metrics.heavy,metrics.agile
assert(a.half<b.half and b.half<h.half,"agile launch advantage trades against heavy acceleration")
assert(h.straight<b.straight and b.straight<a.straight,"heavy cruising advantage trades against agile top speed")
assert(h.stop<b.stop and b.stop<a.stop,"heavy has stronger braking, agile requires earlier braking")
assert(a.radius<b.radius and b.radius<h.radius,"agile turns tighter while heavy needs wider lines")
assert(math.abs(h.straight/b.straight-1)<0.03 and math.abs(a.straight/b.straight-1)<0.03,
    "first-pass straight tradeoffs remain modest rather than different performance tiers")

-- Identical seed/input vectors replay all 15 fields at different render rates.
local ticks=10000
local function tapeFor(seed)
    local tape={}
    for tick=1,ticks do
        seed=(seed*48271)%2147483647
        tape[tick]={accelerate=seed%11>1,brake=seed%19==0,
            left=seed%8<3,right=seed%8>4,drift=seed%13>2}
    end
    return tape
end
local tape,repeated=tapeFor(1729),tapeFor(1729)
for tick=1,ticks do
    for _,field in ipairs({"accelerate","brake","left","right","drift"}) do
        assert(tape[tick][field]==repeated[tick][field],"seed reproduces the input vectors")
    end
end
for _,case in ipairs(cases) do
    local reference,state={},P.new(T)
    for tick=1,ticks do
        state=P.step(state,tape[tick],dt,T,case.kart)
        reference[tick]=state
    end
    for _,fps in ipairs({30,60,144}) do
        local clock,replay=L.new(dt,5),P.new(T)
        for _=1,ticks*fps/60 do
            L.advance(clock,1/fps,function(stepDt)
                local tick=replay.tick+1
                assert(tick<=ticks,"render cadence cannot invent ticks")
                replay=P.step(replay,repeated[tick],stepDt,T,case.kart)
                same(replay,reference[tick],case.id.." "..fps.."FPS tick "..tick)
            end)
        end
        assert(replay.tick==ticks and clock.droppedSeconds==0,"10k exact fixed ticks without dropping time")
        same(replay,state,"final replay state")
    end
end
print("kart handling: modest measured tradeoffs, common wall/drift/boost rules, copied profiles and 10k-tick seeded replays at 30/60/144 FPS")
