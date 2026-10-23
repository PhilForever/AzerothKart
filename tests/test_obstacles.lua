local T=dofile("addon/AzerothKart/Track.lua")
local M=dofile("addon/AzerothKart/MirageRaceway.lua")
local P=dofile("addon/AzerothKart/Physics.lua")
local L=dofile("addon/AzerothKart/Loop.lua")

assert(T.id=="test_oval" and T.version==2 and #T.obstacles==2,
    "versioned obstacles belong only to Test Oval")
assert(M.obstacles==nil and M.resolveMovement==nil,"Mirage geometry remains unchanged")
local geometry={}
for i,box in ipairs(T.obstacles) do
    geometry[i]={id=box.id,x=box.x,y=box.y,width=box.width,height=box.height}
    assert(box.x-T.wallInset>=T.wallInset and box.y-T.wallInset>=T.wallInset
        and box.x+box.width+T.wallInset<=T.width-T.wallInset
        and box.y+box.height+T.wallInset<=T.height-T.wallInset,
        "expanded fixtures stay clear of the perimeter")
    assert(T.isDrivable(box.x,box.y),"test fixture is placed on the oval road")
    assert(T.surfaceAt(box.x,box.y)=="wall","physical obstacle including edge is wall")
    assert(T.surfaceAt(box.x+box.width/2,box.y+box.height/2)=="wall",
        "physical obstacle interior is wall")
end
assert(T.surfaceAt(252,410)=="road","clearance margin does not repaint the road mask")
assert(T.isDrivable(280,410),"obstacles do not alter the analytical road mask")

local function clear(x,y)
    assert(x>=T.wallInset and x<=T.width-T.wallInset
        and y>=T.wallInset and y<=T.height-T.wallInset,"resolved center inside perimeter")
    for _,box in ipairs(T.obstacles) do
        assert(not (x>box.x-T.wallInset and x<box.x+box.width+T.wallInset
            and y>box.y-T.wallInset and y<box.y+box.height+T.wallInset),
            "resolved center must not penetrate an expanded obstacle")
    end
end
local function move(x,y,targetX,targetY,wantX,wantY,wantHit,label)
    local actualX,actualY,hit=T.resolveMovement(x,y,targetX,targetY)
    assert(math.abs(actualX-wantX)<1e-9 and math.abs(actualY-wantY)<1e-9,
        label..": incorrect resolved position")
    assert(hit==wantHit,label..": incorrect contact flag")
    clear(actualX,actualY)
    return actualX,actualY
end

move(200,410,380,410,252,410,true,"head-on sweep crosses the whole obstacle")
move(380,410,200,410,320,410,true,"reverse-direction sweep")
move(286,350,286,470,286,382,true,"bottom-face sweep beats later perimeter")
move(286,460,286,350,286,442,true,"top-face sweep")
move(200,390,300,430,252,430,true,"impact preserves tangent displacement")
move(200,330,300,430,252,382,true,"exact corner blocks both inward axes")
move(200,434,304,330,304,330,false,"single-point corner graze stays free")
move(252,400,240,410,240,410,false,"moving away from a contact face")
move(252,400,252,450,252,450,false,"sliding along a face without normal motion")
move(200,382,400,382,400,382,false,"edge grazing does not collide")
move(200,410,252,410,252,410,false,"arrival exactly at clearance edge stays free")
move(400,70,700,70,472,70,true,"second obstacle is swept")

local x,y=252,410
for _=1,20 do
    x,y=move(x,y,x+4,y+1,252,y+1,true,"consecutive contact remains outside")
end
move(x,y,x-10,y,242,430,false,"consecutive contact can release immediately")

-- Recovery is deterministic, including exact nearest-face ties, and stable on
-- a following zero movement. It is not a dynamic obstacle relocation system.
x,y=move(286,414,286,414,286,442,true,"nearest top face recovers an overlap")
move(x,y,x,y,x,y,false,"recovered zero movement remains stable")
move(286,414,290,414,290,442,true,"recovery retains requested displacement")
move(286,414,286,414,286,442,true,"repeated recovery chooses the same face")
move(286,412,286,412,286,382,true,"equal vertical faces choose bottom")
move(260,390,260,390,252,390,true,"left beats bottom on equal distance")
move(312,390,312,390,320,390,true,"right beats bottom on equal distance")
move(286,390,286,390,286,382,true,"nearest bottom face")

move(50,240,-50,300,18,300,true,"perimeter retains tangential movement")
move(750,450,850,550,782,462,true,"perimeter corner blocks both axes")
move(18,240,18,300,18,300,false,"perimeter tangency remains free")
move(18,240,30,250,30,250,false,"moving away from perimeter")
move(0,240,0,240,18,240,true,"out-of-bounds start recovers to perimeter")
local oldX,oldY,oldHit=T.constrainPosition(286,412)
assert(oldX==286 and oldY==412 and not oldHit,"legacy constraint stays perimeter-only")
for _,invalid in ipairs({0/0,math.huge,-math.huge,"400",false}) do
    assert(not pcall(T.resolveMovement,invalid,240,400,240),"invalid start x rejected")
    assert(not pcall(T.resolveMovement,400,invalid,400,240),"invalid start y rejected")
    assert(not pcall(T.resolveMovement,400,240,invalid,240),"invalid target x rejected")
    assert(not pcall(T.resolveMovement,400,240,400,invalid),"invalid target y rejected")
end
assert(not pcall(T.resolveMovement,-1e308,240,1e308,240),
    "overflowing displacement rejected despite finite endpoints")

-- A charged drift and active boost still cancel on a solid contact, while
-- the useful movement and held steering remain available for recovery.
local charged=P.new(T)
charged.x,charged.y,charged.heading,charged.speed=251.5,410,0,200
charged.drifting,charged.driftDirection,charged.driftTicks,charged.driftTier=true,1,60,2
charged.driftGraceTicks,charged.boostTicks,charged.slipAngle,charged.steering=5,20,0.2,1
local contact=P.step(charged,{accelerate=true,left=true,drift=true},P.FIXED_DT,T)
assert(contact.x==252 and contact.surface=="wall" and contact.impacts==1,
    "charged step hits the obstacle through the swept movement hook")
assert(contact.speed>0 and contact.speed<charged.speed,
    "an angled solid contact loses speed without discarding all useful motion")
assert(not contact.drifting and contact.driftDirection==0 and contact.driftTicks==0
    and contact.driftTier==0 and contact.driftGraceTicks==0 and contact.boostTicks==0
    and contact.slipAngle==0 and contact.steering==charged.steering,
    "solid contact clears drift, correction grace, boost and slip but retains steering")
assert(charged.x==251.5 and charged.boostTicks==20 and charged.drifting,
    "solid collision does not mutate the supplied Physics state")
contact.heading=math.pi
local released=P.step(contact,{accelerate=true},P.FIXED_DT,T)
assert(released.x<contact.x and released.impacts==contact.impacts and released.surface=="road",
    "steering away releases a solid contact immediately")

-- Explicit starting pose faces the first fixture so this tape cannot pass
-- vacuously without collisions. All controls after that approach are seeded.
local fields={"x","y","heading","speed","tick","impacts","drifting","driftDirection",
    "driftTicks","driftTier","boostTicks","slipAngle","surface","steering","driftGraceTicks"}
local ticks,seed=900,1729
local tape,reference={},{}
for tick=1,ticks do
    seed=(seed*48271)%2147483647
    tape[tick]={accelerate=tick<=120 or seed%11>1,brake=tick>120 and seed%19==0,
        left=tick>120 and seed%8<3,right=tick>120 and seed%8>4,drift=seed%13>2}
end
local function start()
    local state=P.new(T)
    state.x,state.y,state.heading=200,410,0
    return state
end
local function equal(actual,expected,label)
    for _,field in ipairs(fields) do
        assert(actual[field]==expected[field],label..": changed "..field)
    end
end
local state=start()
local obstacleImpact=false
for tick=1,ticks do
    state=P.step(state,tape[tick],P.FIXED_DT,T)
    clear(state.x,state.y)
    reference[tick]=state
    if tick<=120 and state.impacts>0 then
        assert(state.x==252 and state.surface=="wall","approach hits obstacle, not perimeter")
        obstacleImpact=true
    end
end
assert(obstacleImpact,"seeded tape must actually hit an obstacle")
for _,fps in ipairs({30,60,144}) do
    local clock=L.new(P.FIXED_DT,5)
    local replay=start()
    local function step(dt)
        local tick=replay.tick+1
        replay=P.step(replay,tape[tick],dt,T)
        equal(replay,reference[tick],fps.." FPS at tick "..tick)
    end
    for _=1,ticks*fps/60 do L.advance(clock,1/fps,step) end
    assert(replay.tick==ticks and clock.droppedSeconds==0,"steady cadence keeps all ticks")
    equal(replay,state,"final state at "..fps.." FPS")
end
for i,box in ipairs(T.obstacles) do
    for key,value in pairs(geometry[i]) do
        assert(box[key]==value,"collision queries must not mutate geometry")
    end
end
print("Obstacle sweep/slide/recovery checks and 900-tick tape at 30/60/144 FPS PASS (15 fields)")
