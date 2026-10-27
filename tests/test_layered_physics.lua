-- Opt-in floors/pads do not change the existing flat handling state or scores.
local P=dofile("addon/AzerothKart/Physics.lua")
local T=dofile("addon/AzerothKart/Track.lua")
local Loop=dofile("addon/AzerothKart/Loop.lua")
local function near(a,b,label) assert(math.abs(a-b)<1e-9,label or (tostring(a).." ~= "..tostring(b))) end
local function pad(id,x,y,radius,level,ticks)
    return {id=id,x=x,y=y,radius=radius,level=level,boostTicks=ticks or 78}
end
local function plane(pads)
    return {spawn=function() return {x=0,y=20,heading=0} end,
        isDrivable=function() return true end,
        surfaceAt=function() return "road" end,
        resolveMovement=function(_,_,x,y) return x,y,false end,pads=pads}
end
local function moving(track,x,level)
    local s=P.new(track); s.x=x; s.y=20; s.speed=200
    if track.layered then s.level=level or 0 end
    return s
end

assert(P.VERSION==12 and P.FEATURE_VERSION==13 and P.versionForTrack(T)==12
    and P.versionForTrack(plane({}))==12,"existing courses retain legacy physics compatibility")
local one=plane({pad("boots",10,20,1)})
assert(P.versionForTrack(one)==13 and P.new(one).level==nil,"pads opt in without inventing a flat floor state")
local old=moving(one,8)
local entry=P.step(old,{accelerate=true},P.FIXED_DT,one)
assert(entry.x>11 and entry.boostTicks==78 and old.x==8 and old.boostTicks==0,
    "swept centre entry awards a pass even when both endpoints miss a small pad")
near(entry.speed,200,"entry movement retains normal speed; boost begins next tick")
local boosted=P.step(entry,{accelerate=true},P.FIXED_DT,one)
assert(boosted.speed>200 and boosted.boostTicks==77,"pad reward uses existing boost acceleration/duration")
entry.heading=math.pi; entry.speed=200
local reentry=P.step(entry,{accelerate=true},P.FIXED_DT,one)
assert(reentry.boostTicks==78,"leaving the disc re-arms it for a later pass")

local wide=plane({pad("wide",200,20,100)})
local inside=moving(wide,150); inside.boostTicks=50
for _=1,20 do inside=P.step(inside,{accelerate=true},P.FIXED_DT,wide) end
assert(inside.x<300 and inside.boostTicks==30,"remaining inside never refreshes the reward")
local spawnInside=plane({pad("spawn",0,20,20)})
assert(P.step(P.new(spawnInside),{},P.FIXED_DT,spawnInside).boostTicks==0,
    "spawning inside is not a repeated entry")
local already=moving(one,8); already.boostTicks=100
assert(P.step(already,{accelerate=true},P.FIXED_DT,one).boostTicks==99,
    "a pad cannot shorten a stronger retained boost")
local two=plane({pad("first",10,20,1,0,48),pad("second",12,20,1,0,78)})
assert(P.step(moving(two,8),{accelerate=true},P.FIXED_DT,two).boostTicks==78,
    "overlapping pad entries combine by maximum duration, never addition")

local wall=plane({pad("wall",10,20,1)})
wall.resolveMovement=function(x,y) return x,y,true end
assert(P.step(moving(wall,8),{accelerate=true},P.FIXED_DT,wall).boostTicks==0,
    "intended travel through a wall cannot pick up a pad")
wall.resolveMovement=function(_,y) return 9.5,y,true end
assert(P.step(moving(wall,8),{accelerate=true},P.FIXED_DT,wall).boostTicks==0,
    "actual wall contact retains cancellation precedence even inside a pad")
local grass=plane({pad("grass",10,20,1)})
grass.surfaceAt=function(x) return x>=9 and "grass" or "road" end
assert(P.step(moving(grass,8),{accelerate=true},P.FIXED_DT,grass).boostTicks==0,
    "non-road arrival cancels pad reward")
assert(P.step(moving(one,8),{brake=true},P.FIXED_DT,one).boostTicks==0,
    "braking retains cancellation precedence")

local function floors(pads)
    local track=plane(pads)
    track.layered=true; track.levelCount=2
    track.validLevel=function(level) return level==0 or level==1 end
    track.spawn=function() return {x=0,y=20,heading=0,level=0} end
    track.surfaceAt=function(_,_,level) assert(track.validLevel(level)); return "road" end
    track.resolveMovement=function(x,y,nx,ny,level)
        assert(track.validLevel(level))
        if level==0 and x<10 and nx>=10 then
            return nx,ny,false,1,10,y+(ny-y)*(10-x)/(nx-x)
        elseif level==1 and x>10 and nx<=10 then
            return nx,ny,false,0,10,y+(ny-y)*(10-x)/(nx-x)
        end
        return nx,ny,false,level
    end
    return track
end
local layered=floors()
assert(P.versionForTrack(layered)==13 and P.new(layered).level==0)
local low=moving(layered,8,0)
local high=P.step(low,{accelerate=true},P.FIXED_DT,layered)
assert(high.level==1 and low.level==0,"only resolved movement changes the retained floor")
high.heading=math.pi; high.speed=200
assert(P.step(high,{accelerate=true},P.FIXED_DT,layered).level==0,"ramp transfer works in reverse")
local split=floors({pad("below",8,20,1,0,48),pad("above",8,20,1,1,78)})
local transferred=P.step(moving(split,6.9,0),{accelerate=true},P.FIXED_DT,split)
assert(transferred.level==1 and transferred.boostTicks==48,
    "movement before the ramp end cannot collect an overlapping upper-floor pad")
split=floors({pad("after",12,20,1,0,78)})
assert(P.step(moving(split,6.9,0),{accelerate=true},P.FIXED_DT,split).boostTicks==0,
    "movement after a ramp end cannot collect a lower-floor pad")
split=floors({pad("enter_level",10,20,1,1,78)})
assert(P.step(moving(split,6.9,0),{accelerate=true},P.FIXED_DT,split).boostTicks==78,
    "entering a new level within its pad is one real level-aware entry")
for _,bad in ipairs({-1,2,false,0/0,"0"}) do
    local s=moving(layered,8); s.level=bad
    assert(not pcall(P.step,s,{},P.FIXED_DT,layered),"invalid floor state rejects")
end
local badSpawn=floors(); badSpawn.spawn=function() return {x=0,y=20,heading=0,level=false} end
assert(not pcall(P.new,badSpawn),"invalid spawn floor cannot silently become zero")

assert(P.ValidatePads(nil) and P.ValidatePads({}))
for _,bad in ipairs({false,"pads",{[2]=pad("gap",10,20,1)},
    {pad("same",10,20,1),pad("same",30,20,1)},
    {pad("zero",10,20,0)},{pad("huge",10,20,257)},
    {pad("bad_level",10,20,1,2)},{pad("bad_ticks",10,20,1,0,601)},
    {pad("bad_coord",0/0,20,1)},setmetatable({},{})}) do
    assert(not P.ValidatePads(bad) and not pcall(P.new,plane(bad)),"malformed pad data refuses construction")
end
assert(not pcall(P.new,plane({pad("unreachable",10,20,1,1)})),"flat track cannot hide an unreachable upper-floor pad")
local many={};for i=1,33 do many[i]=pad("p"..i,i*2,20,1) end
assert(not P.ValidatePads(many),"pad count is bounded")

-- Captured before this change from Physics12's720-tick seeded legacy tape.
-- These are independent regression values, not a second physics algorithm.
local goldens={
    goblin_mortar_trike={661.46536449133964,1.9713663593230188,68.633333333333297,566},
    steam_tank={680.2386926097987,1.8735537751199229,67.046666666666667,556},
    gryphon_rider={697.1377054434804,1.8811143458498099,69.333333333333329,573},
}
for id,expected in pairs(goldens) do
    local s=P.new(T);local seed=1729
    for tick=1,720 do
        seed=(seed*48271)%2147483647
        s=P.step(s,{accelerate=seed%11>1,brake=seed%19==0,left=seed%8<3,
            right=seed%8>4,drift=seed%13>2},P.FIXED_DT,T,id)
    end
    near(s.x,expected[1]);near(s.y,462);near(s.heading,expected[2]);near(s.speed,expected[3])
    assert(s.impacts==expected[4] and s.tick==720 and s.surface=="wall" and s.level==nil)
    assert(not s.drifting and s.driftDirection==0 and s.driftTicks==0 and s.driftTier==0
        and s.driftGraceTicks==0 and s.boostTicks==0 and s.slipAngle==0)
    near(s.steering,0.46666666666666673)
    local count=0;for _ in pairs(s) do count=count+1 end
    assert(count==15,"flat state shape is unchanged")
end

-- Actual adapter/physics/checkpoint integration: drive up, pass a lower-only
-- pillar on the roof, then reverse down. Replay the resulting input tape at
-- different render cadences, comparing every state field at every tick.
local AK={Physics=P}
for _,name in ipairs({"Track","Dungeon","LayeredTrack","Checkpoints"}) do
    assert(loadfile("addon/AzerothKart/"..name..".lua"))("AzerothKart",AK)
end
local traceTrack=AK.LayeredTrack.new({id="layered_physics_fixture",version=1,
    width=440,height=260,wallInset=2,laps=3,checkpointMaxStep=5,
    rooms={
        {x=20,y=20,width=124,height=200,surface="road",level=0},
        {x=216,y=80,width=204,height=80,surface="road",level=0},
        {x=20,y=20,width=124,height=200,surface="road",level=1},
        {x=216,y=80,width=204,height=80,surface="road",level=1},
    },
    solids={{id="lower_pillar",x=300,y=116,width=10,height=8,level=0}},
    ramps={{id="ramp",x=140,y=100,width=80,height=40,axis="x",ascending=1,lowLevel=0,highLevel=1}},
    pads={pad("ground_boots",80,120,8,0,48),pad("wrong_floor",80,120,8,1,78),
        pad("roof_boots",280,120,8,1,78)},
    gates={{name="Ground",ax=100,ay=100,bx=100,by=140,nx=1,ny=0,level=0},
        {name="Roof",ax=260,ay=100,bx=260,by=140,nx=1,ny=0,level=1}},
    spawn={x=40,y=120,heading=0,level=0}},AK.Track.crossesGate)
assert(traceTrack.surfaceAt(305,120,0)=="wall" and traceTrack.surfaceAt(305,120,1)=="road")
local wrongGate={gates={{name="Other floor",ax=100,ay=100,bx=100,by=140,nx=1,ny=0,level=1}},
    checkpointMaxStep=5,crossesGate=traceTrack.crossesGate}
local tape,reference={},{}
local state=P.new(traceTrack)
local progress,wrong=AK.Checkpoints.new(traceTrack,0),AK.Checkpoints.new(wrongGate,0)
local reverse,up,down,lowerBoost,upperBoost,pastLowerSolid=false,0,0,false,false,false
for tick=1,720 do
    if state.x>=310 then reverse=true end
    local input=reverse and {brake=true} or {accelerate=true}
    tape[tick]=input
    local previous=state
    state=P.step(state,input,P.FIXED_DT,traceTrack)
    reference[tick]=state
    progress=AK.Checkpoints.step(progress,previous,state,traceTrack)
    wrong=AK.Checkpoints.step(wrong,previous,state,wrongGate)
    if previous.level~=state.level then
        if state.level==1 then up=up+1 else down=down+1 end
    end
    if state.level==0 and state.x<140 then
        assert(state.boostTicks<=48,"overlapping upper-floor boots cannot boost a ground kart")
        lowerBoost=lowerBoost or state.boostTicks==48
    elseif state.level==1 then
        upperBoost=upperBoost or state.boostTicks==78
        pastLowerSolid=pastLowerSolid or state.x>310
    end
end
assert(up==1 and down==1 and lowerBoost and upperBoost and pastLowerSolid,
    "the real tape drives both ramp directions, own-floor pads and past another floor's solid")
assert(progress.complete and progress.passed==2 and wrong.passed==0,
    "actual Physics levels admit own-floor gates and reject an overlapping wrong-floor gate")
for _,fps in ipairs({30,60,144}) do
    local clock=Loop.new(P.FIXED_DT,5);local replay=P.new(traceTrack)
    for _=1,720*fps/60 do
        Loop.advance(clock,1/fps,function(dt)
            replay=P.step(replay,tape[replay.tick+1],dt,traceTrack)
            for key,value in pairs(reference[replay.tick]) do assert(replay[key]==value,"render-cadence invariant: "..key) end
        end)
    end
    assert(replay.tick==720 and clock.droppedSeconds==0)
end
print("layered physics: level-aware resolved motion, swept per-pass pads, split-floor entries, flat Physics12 goldens and real-adapter720tick30/60/144cadence replay PASS")
