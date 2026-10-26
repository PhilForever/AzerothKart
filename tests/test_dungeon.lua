-- Dungeon sprints (Dungeon.lua), the one-run race and the Scarlet Crusade
-- Cup: rooms, lawns, solids, sliding walls, unavoidable gates and the
-- generated Scarlet Graveyard. Pure offline checks; the dungeon's look and
-- the drive in the client are separate, pending checks
-- (docs/art/tracks/scarlet-graveyard.md).
local namespace = {}
local function load(name)
    local chunk = assert(loadfile("addon/AzerothKart/" .. name .. ".lua"))
    chunk("AzerothKart", namespace)
end
for _,name in ipairs({"Track", "MirageRaceway", "Circuit", "CapitalCities", "Dungeon", "ScarletCrusade", "Courses",
        "Physics", "Checkpoints", "Laps", "Race", "Highscores", "SoloRecords"}) do
    load(name)
end
local Track, Dungeon, Courses = namespace.Track, namespace.Dungeon, namespace.Courses
local Physics, Checkpoints, Laps, Race = namespace.Physics, namespace.Checkpoints, namespace.Laps, namespace.Race
local Records = namespace.SoloRecords

local function near(a, b, tolerance) return math.abs(a - b) <= (tolerance or 1e-6) end
local function distance(ax, ay, bx, by) return math.sqrt((bx - ax) ^ 2 + (by - ay) ^ 2) end
local function segmentRadius(ax, ay, bx, by, cx, cy)
    local dx,dy = bx-ax,by-ay
    local squared = dx*dx+dy*dy
    local t = squared > 0 and math.max(0,math.min(1,((cx-ax)*dx+(cy-ay)*dy)/squared)) or 0
    return distance(cx,cy,ax+dx*t,ay+dy*t)
end
local function copy(t)
    local out = {}
    for key,value in pairs(t) do out[key] = value end
    return out
end

-- A small dungeon: a stone hall, a door east into a lawn with a stone path
-- across it and a grave on the grass. Inset 10: doors overlap by 20.
local definition = {
    id="crypt", width=600, height=400, wallInset=10, laps=1,
    rooms={
        {x=20, y=20, width=200, height=160, surface="road"},      -- the hall: x 20-220, y 20-180
        {x=200, y=60, width=120, height=80, surface="road"},      -- the door: x 200-320, y 60-140
        {x=300, y=20, width=280, height=360, surface="rough"},    -- the lawn: x 300-580, y 20-380
        {x=300, y=80, width=280, height=40, surface="road"},      -- the path: x 300-580, y 80-120
    },
    solids={{id="grave", x=440, y=200, width=20, height=10}},
    gates={{name="Door", ax=260, ay=60, bx=260, by=140, nx=1, ny=0},
           {name="End", ax=550, ay=20, bx=550, by=380, nx=1, ny=0}},
    spawn={x=60, y=100, heading=0},
}
local crypt = Dungeon.new(definition, Track.crossesGate)
assert(crypt.laps == 1 and crypt.wallInset == 10 and #crypt.rooms == 4 and #crypt.gates == 2, "a sprint dungeon")

-- Surfaces: stone, the lawn's grass, walls between and beyond the rooms,
-- the grave's own box and the perimeter.
assert(crypt.surfaceAt(60, 100) == "road" and crypt.surfaceAt(400, 100) == "road", "the hall and the path are stone")
assert(crypt.surfaceAt(400, 250) == "grass", "the lawn is grass: rough ground")
assert(crypt.surfaceAt(250, 170) == "wall" and crypt.surfaceAt(60, 175) == "wall",
    "masonry beside the door, and the hall's wall within a kart's inset")
assert(crypt.surfaceAt(445, 205) == "wall" and crypt.surfaceAt(5, 100) == "wall", "a solid and the perimeter are wall")
assert(crypt.isDrivable(60, 100) and crypt.isDrivable(400, 100) and not crypt.isDrivable(400, 250)
    and not crypt.isDrivable(445, 205), "only the stone floor is road")

-- Movement: exact in the open; a step into a wall ends at the kart's inset
-- and slides along it; the door joins the hall to the lawn.
local x, y, hit = crypt.resolveMovement(100, 100, 103, 101)
assert(not hit and x == 103 and y == 101, "free movement is exact")
x, y, hit = crypt.resolveMovement(100, 168, 104, 173)
assert(hit and near(y, 170) and near(x, 104), "a step into the north wall slides along it")
x, y, hit = crypt.resolveMovement(214, 100, 218, 100)
assert(not hit and x == 218, "the hall runs on into the door")
local px, py = 200, 100
for _=1,40 do
    px, py, hit = crypt.resolveMovement(px, py, px + 4, py)
    assert(not hit, "driving through the door never meets a wall")
end
assert(px == 360 and crypt.surfaceAt(px, py) == "road", "through the door onto the path")
x, y, hit = crypt.resolveMovement(208, 165, 213, 165)
assert(hit and near(x, 210) and y == 165, "beside the door the wall holds")
-- The grave blocks with the inset and slides as the test oval's crates do.
x, y, hit = crypt.resolveMovement(428, 205, 433, 205)
assert(hit and near(x, 430) and y == 205, "the grave stops a kart at its grown face")
x, y, hit = crypt.resolveMovement(428, 205, 433, 209)
assert(hit and near(x, 430) and near(y, 209), "and the kart slides along it")
-- A centre in the masonry or inside a grown solid (never by driving) moves
-- to the nearest floor point; with none, back to the spawn.
x, y, hit = crypt.resolveMovement(250, 300, 250, 300)
assert(hit and near(x, 310) and y == 300 and crypt.surfaceAt(x, y) == "grass", "a centre in the wall moves to the nearest floor")
x, y, hit = crypt.resolveMovement(445, 205, 445, 205)
assert(hit and (near(x, 430) or near(x, 470) or near(y, 190) or near(y, 220)), "a centre in a grave leaves by a face")

-- 4,000 random steps from random floor points: never further than asked,
-- never ending in a wall, a solid or off the floor.
local seed = 7
local function random()
    seed = (seed * 1103515245 + 12345) % 2147483648
    return seed / 2147483648
end
local moves = 0
while moves < 4000 do
    local sx, sy = 20 + random() * 560, 20 + random() * 360
    local fx, fy, recovered = crypt.resolveMovement(sx, sy, sx, sy)
    if not recovered then
        local tx, ty = sx + (random() - 0.5) * 8, sy + (random() - 0.5) * 8
        local ex, ey = crypt.resolveMovement(sx, sy, tx, ty)
        assert(distance(sx, sy, ex, ey) <= distance(sx, sy, tx, ty) + 1e-9, "never further than requested")
        assert(crypt.surfaceAt(ex, ey) ~= "wall", "never ending in a wall")
        local back = {crypt.resolveMovement(ex, ey, ex, ey)}
        assert(not back[3], "every end point is an allowed floor point")
        moves = moves + 1
    else
        assert(crypt.surfaceAt(fx, fy) ~= "wall", "a recovered centre stands on the floor")
    end
end

-- A round room (a round library): a corridor from the west into a rotunda of
-- radius 100 about (300, 200). Inset 10: the kart centre reaches 90 from the
-- centre, and the corridor runs 50 units into the disc's square.
local rotunda = Dungeon.new({
    id="rotunda", width=500, height=400, wallInset=10, laps=1,
    rooms={
        {x=20, y=160, width=240, height=80, surface="road"},                 -- the corridor: x 20-260, y 160-240
        {x=200, y=100, width=200, height=200, surface="road", shape="disc"}, -- the rotunda
    },
    gates={{name="In", ax=150, ay=160, bx=150, by=240, nx=1, ny=0}},
    spawn={x=60, y=200, heading=0},
}, Track.crossesGate)
assert(rotunda.surfaceAt(300, 200) == "road" and rotunda.surfaceAt(300, 285) == "road" and rotunda.isDrivable(300, 285),
    "the rotunda's floor is stone to the kart's reach")
assert(rotunda.surfaceAt(300, 295) == "wall" and rotunda.surfaceAt(300, 305) == "wall"
    and rotunda.surfaceAt(372, 272) == "wall" and rotunda.surfaceAt(360, 260) == "road",
    "a round wall: off the reach, beyond the radius, and the square's corner")
px, py = 60, 200
for _=1,60 do
    px, py, hit = rotunda.resolveMovement(px, py, px + 4, py)
    assert(not hit, "the corridor runs on into the rotunda")
end
assert(px == 300 and py == 200, "to the rotunda's centre")
x, y, hit = rotunda.resolveMovement(300, 288, 304, 292)
assert(hit and near(distance(300, 200, x, y), 90, 1e-3) and x > 302 and distance(300, 288, x, y) <= math.sqrt(32),
    "a step into the round wall slides along it")
local around = 0
px, py = 300, 288
for _=1,200 do            -- pushing on east-north-east, the kart follows the curve round
    local ex, ey = rotunda.resolveMovement(px, py, px + 4, py + 2)
    assert(distance(300, 200, ex, ey) <= 90 + 1e-9, "the kart stays within the round wall")
    if ex ~= px or ey ~= py then around = around + 1 end
    px, py = ex, ey
end
assert(around > 20 and near(px, 300 + 90 * 4 / math.sqrt(20), 0.1) and near(py, 200 + 90 * 2 / math.sqrt(20), 0.1),
    "and slides round it to where the wall faces the push")
seed = 11
moves = 0
while moves < 2000 do
    local sx, sy = 200 + random() * 200, 100 + random() * 200
    local fx, fy, recovered = rotunda.resolveMovement(sx, sy, sx, sy)
    if not recovered then
        local tx, ty = sx + (random() - 0.5) * 8, sy + (random() - 0.5) * 8
        local ex, ey = rotunda.resolveMovement(sx, sy, tx, ty)
        assert(distance(sx, sy, ex, ey) <= distance(sx, sy, tx, ty) + 1e-9, "never further than requested")
        assert(not ({rotunda.resolveMovement(ex, ey, ex, ey)})[3], "every end point is on the round floor")
        moves = moves + 1
    else
        assert(rotunda.surfaceAt(fx, fy) ~= "wall", "a recovered centre stands on the floor")
    end
end

-- A round solid (a round pool): a court with a pool of radius 60 about
-- (300, 200). Inset 10: the kart centre keeps 70 from the pool's centre.
local pond = Dungeon.new({
    id="pond", width=600, height=400, wallInset=10, laps=1,
    rooms={{x=20, y=20, width=560, height=360, surface="road"}},
    solids={{id="pool", x=240, y=140, width=120, height=120, shape="disc"}},
    gates={{name="Past", ax=450, ay=20, bx=450, by=380, nx=1, ny=0}},
    spawn={x=60, y=200, heading=0},
}, Track.crossesGate)
assert(pond.solids[1].shape == "disc", "the round solid keeps its shape")
assert(pond.surfaceAt(300, 200) == "wall" and pond.surfaceAt(300, 259) == "wall" and pond.surfaceAt(300, 261) == "road"
    and pond.surfaceAt(345, 245) == "road" and pond.isDrivable(300, 271) and not pond.isDrivable(300, 265),
    "the pool is wall to its rim, its square's corners floor; the kart keeps its inset off the rim")
px, py = 60, 200
for _=1,60 do
    px, py, hit = pond.resolveMovement(px, py, px + 4, py)
end
assert(hit and near(px, 230, 1e-3) and near(py, 200, 1e-3), "head on, the pool stops the kart at its reach")
px, py = 200, 129
for _=1,50 do
    px, py, hit = pond.resolveMovement(px, py, px + 4, py)
    assert(not hit, "a kart passing clear of the pool's reach never meets it")
end
assert(px == 400 and py == 129, "and drives on past it")
local slid = 0
px, py = 230, 200
for _=1,80 do            -- pushing on east-north-east from the pool's west side
    local ex, ey, contact = pond.resolveMovement(px, py, px + 4, py + 2)
    assert(distance(300, 200, ex, ey) >= 70, "the kart stays out of the pool")
    assert(distance(px, py, ex, ey) <= math.sqrt(20) + 1e-9, "never further than requested")
    if contact and ey < 300 then slid = slid + 1 end
    px, py = ex, ey
end
assert(slid > 10 and px > 300, "it slides round the pool's north side and on past it")
x, y, hit = pond.resolveMovement(200,200,400,200)
assert(hit and near(x,230,1e-8) and near(y,200),
    "a long segment with both endpoints outside cannot tunnel through the pool")
x, y, hit = pond.resolveMovement(400,200,200,200)
assert(hit and near(x,370,1e-8) and near(y,200), "the opposite long sweep stops at its first entry")
x, y, hit = pond.resolveMovement(230,200,234,202)
assert(hit and near(x,230,1e-8) and near(y,202,1e-8),
    "starting on the rim removes inward movement and preserves tangential movement")
x, y, hit = pond.resolveMovement(230,200,226,200)
assert(not hit and x==226 and y==200, "starting on the rim can drive outward freely")
x, y, hit = pond.resolveMovement(230,200,230,204)
assert(not hit and x==230 and y==204, "a tangent from the rim does not enter the pool")
x, y, hit = pond.resolveMovement(200,270,400,270)
assert(not hit and x==400 and y==270, "exact tangency along the whole segment is free")
-- Each requested segment is shorter than the maximum60Hz step, with both
-- endpoints legal but a middle point inside the pool's clearance. Checking
-- returned endpoints alone misses the original crossing defect.
for degree=0,359 do
    local angle=degree*math.pi/180
    local nx,ny=math.cos(angle),math.sin(angle)
    local tx,ty=-ny,nx
    local sx,sy=300+nx*69.99-tx*2.15,200+ny*69.99-ty*2.15
    local ex,ey,contact=pond.resolveMovement(sx,sy,sx+tx*4.3,sy+ty*4.3)
    assert(contact,"a shallow crossing registers contact in every direction")
    assert(segmentRadius(sx,sy,ex,ey,300,200)>=70-1e-7,
        "the resolved movement segment clears the entire round obstacle")
    assert(distance(sx,sy,ex,ey)>4.25 and distance(sx,sy,ex,ey)<=4.3+1e-8,
        "grazing contact slides without a stall or excess displacement")
end
x, y, hit = pond.resolveMovement(300, 210, 300, 210)
assert(hit and near(x, 300) and near(y, 270, 1e-3), "a centre in the pool (never by driving) leaves it along the radius")
seed = 13
moves = 0
while moves < 2000 do
    local sx, sy = 200 + random() * 200, 100 + random() * 200
    local fx, fy, recovered = pond.resolveMovement(sx, sy, sx, sy)
    if not recovered then
        local tx, ty = sx + (random() - 0.5) * 12, sy + (random() - 0.5) * 12
        local ex, ey = pond.resolveMovement(sx, sy, tx, ty)
        assert(distance(sx, sy, ex, ey) <= distance(sx, sy, tx, ty) + 1e-9, "never further than requested")
        assert(distance(300, 200, ex, ey) >= 70, "never ending within the pool's reach")
        assert(segmentRadius(sx,sy,ex,ey,300,200)>=70-1e-7,
            "random movement clears the pool along its segment, not only at the endpoint")
        assert(not ({pond.resolveMovement(ex, ey, ex, ey)})[3], "every end point is allowed")
        moves = moves + 1
    else
        assert(distance(300, 200, fx, fy) >= 70 and pond.surfaceAt(fx, fy) ~= "wall", "a recovered centre is clear")
    end
end

-- A box and a round solid can meet within one requested movement. The bounded
-- contact loop keeps the corner blocked and permits driving back out of it.
local corner = Dungeon.new({
    id="pool_corner", width=600, height=400, wallInset=10, laps=1,
    rooms={{x=20,y=20,width=560,height=360,surface="road"}},
    solids={{x=240,y=140,width=120,height=120,shape="disc"},
        {x=225,y=230,width=20,height=20}},
    gates={{name="Past",ax=450,ay=20,bx=450,by=380,nx=1,ny=0}},
    spawn={x=60,y=200,heading=0},
},Track.crossesGate)
x,y,hit=corner.resolveMovement(200,200,400,400)
assert(hit and x<240 and y<=220+1e-8 and distance(200,200,x,y)<=math.sqrt(80000),
    "multiple circle/box contacts keep the concave corner blocked")
local ax,ay,again=corner.resolveMovement(x,y,x,y)
assert(not again and ax==x and ay==y,"a multi-contact endpoint needs no recovery")
ax,ay,again=corner.resolveMovement(x,y,x-4,y-4)
assert(not again and ax<x and ay<y,"driving away from a multi-contact corner stays free")
local tieX,tieY
for _,boxFirst in ipairs({false,true}) do
    local pool={x=240,y=140,width=120,height=120,shape="disc"}
    local box={x=268,y=110,width=60,height=80}
    local tie= Dungeon.new({
        id="pool_tie",width=600,height=400,wallInset=10,laps=1,
        rooms={{x=20,y=20,width=560,height=360,surface="road"}},
        solids=boxFirst and {box,pool} or {pool,box},
        gates={{name="Past",ax=450,ay=20,bx=450,by=380,nx=1,ny=0}},
        spawn={x=60,y=200,heading=0},
    },Track.crossesGate)
    -- Both entry times are exactly0.5 at(258,144), where the circle's
    -- normal is(-0.6,-0.8) and the box blocks positive X.
    ax,ay,again=tie.resolveMovement(200,100,316,188)
    assert(again and ax<258 and ay>144 and segmentRadius(200,100,ax,ay,300,200)>=70-1e-7,
        "equal box/disc entry resolves both normals and preserves the free tangent")
    assert(not ({tie.resolveMovement(ax,ay,ax,ay)})[3],"equal-entry output is allowed")
    if tieX then assert(ax==tieX and ay==tieY,"equal contact is independent of solid list order") end
    tieX,tieY=ax,ay
end

-- Invalid dungeons are refused.
for _,bad in ipairs({
    {rooms={{x=20, y=20, width=15, height=100, surface="road"}}},
    {rooms={{x=20, y=20, width=200, height=160, surface="lava"}}},
    {rooms={{x=20, y=20, width=200, height=160, surface="road", shape="disc"}}},
    {rooms={{x=20, y=20, width=200, height=200, surface="road", shape="oval"}}},
    {solids={{id="pool", x=440, y=200, width=40, height=30, shape="disc"}}},
    {solids={{id="pool", x=440, y=200, width=40, height=40, shape="oval"}}},
    {laps=0}, {laps=1.5}, {laps=10},
    {spawn={x=250, y=300, heading=0}},
    {spawn={x=445, y=205, heading=0}, rooms=definition.rooms},
}) do
    local d = copy(definition)
    for key,value in pairs(bad) do d[key] = value end
    assert(not pcall(Dungeon.new, d, Track.crossesGate), "an invalid dungeon is refused")
end

-- The race: a dungeon's `laps` sets the run's length; every other course
-- keeps three. A sprint finishes at its last gate after one run.
assert(Race.new(Track, Checkpoints, Laps, 0).targetLaps == 3, "the oval runs three laps")
local sprint = Race.new(crypt, Checkpoints, Laps, 0)
assert(sprint.targetLaps == 1 and sprint.status == "countdown", "a sprint is one run")
assert(not pcall(Race.new, {laps=0, gates=crypt.gates, crossesGate=crypt.crossesGate, checkpointMaxStep=5},
    Checkpoints, Laps, 0), "an invalid lap count is refused")
local previous = {x=60, y=100, tick=0}
for tick=1,Race.COUNTDOWN_TICKS do
    local current = {x=60, y=100, tick=tick}
    sprint = Race.step(sprint, previous, current, crypt, Checkpoints, Laps)
    previous = current
end
assert(sprint.status == "running", "GO after the countdown")
local route = {{x=60, y=100}, {x=290, y=100}, {x=560, y=100}}
for index=2,#route do
    local target = route[index]
    local steps = math.ceil(distance(previous.x, previous.y, target.x, target.y) / 4)
    local fromX, fromY = previous.x, previous.y
    for k=1,steps do
        local current = {x=fromX + (target.x - fromX) * k / steps, y=fromY + (target.y - fromY) * k / steps,
            tick=previous.tick + 1}
        sprint = Race.step(sprint, previous, current, crypt, Checkpoints, Laps)
        previous = current
    end
end
assert(sprint.status == "finished" and sprint.reason == "Sprint complete" and sprint.laps.completedLaps == 1
    and sprint.totalTicks == sprint.finishTick - sprint.startTick and sprint.totalTicks > 0,
    "one run through both gates finishes the sprint")

-- Scores: a sprint keeps its own one-run boards; laps elsewhere stay three.
local context = Records.Context(crypt)
assert(context == nil and Records.Context(Track) == nil, "developer fixtures cannot create production score contexts")
assert(Records.Context(Courses.build("mirage_raceway",Track.crossesGate)).lapCount == 3, "existing production circuits keep three laps")

-- The Scarlet Crusade Cup: the catalogue's third cup, its four dungeons
-- ready: Scarlet Graveyard, Library, Armory and Cathedral. None is coming
-- soon.
assert(#Courses.CUPS == 3 and Courses.CUPS[3].id == "scarlet" and Courses.CUPS[3].name == "Scarlet Crusade Cup",
    "the Scarlet Crusade Cup")
local scarlet = 0
for _,course in ipairs(Courses.LIST) do
    if course.cup == "scarlet" then
        scarlet = scarlet + 1
        assert(course.geometry == "dungeon" and not course.soon and Courses.available(course.id),
            course.id .. " is a ready dungeon")
    end
end
assert(scarlet == 4 and Courses.get("scarlet_cathedral") and not Courses.get("scarlet_monastery"),
    "four dungeons, the last the Cathedral")
assert(Courses.next("undercity_slime") == "scarlet_graveyard" and Courses.next("scarlet_graveyard") == "scarlet_library"
    and Courses.next("scarlet_library") == "scarlet_armory" and Courses.next("scarlet_armory") == "scarlet_cathedral"
    and Courses.next("scarlet_cathedral") == "mirage_raceway",
    "the Track button steps on through the four dungeons, then round to Mirage")

-- Scarlet Graveyard: one run from the entrance to Honor's Tomb. The spawn
-- stands on stone; the reviewed route crosses the three gates in order and
-- never meets a wall or a solid. The cloister's lawn drives as its path
-- does (the owner: "the same terrain should have the same effects across
-- maps - at least maps in the same "cup""); the geometry stays version 2,
-- the stone path still the fastest way.
local graveyard = Courses.build("scarlet_graveyard", Track.crossesGate)
local data = namespace.ScarletCrusade.scarlet_graveyard
assert(Records.Context(graveyard).lapCount==1 and Records.Context(graveyard).trackId=="scarlet_graveyard", "the production sprint has its own one-run score context")
assert(not Courses.multiplayer("scarlet_graveyard") and Courses.next("undercity_slime",true)=="mirage_raceway", "solo sprint does not create an unsupported multiplayer offer")
assert(graveyard and graveyard.laps == 1 and graveyard.width == 2048 and graveyard.height == 1024
    and #graveyard.gates == 3, "the Graveyard: a 2048 x 1024 sprint with three gates")
assert(Courses.build("scarlet_graveyard", Track.crossesGate) == graveyard, "the built course is kept")
local spawn = graveyard.spawn()
assert(graveyard.surfaceAt(spawn.x, spawn.y) == "road" and near(spawn.heading, math.pi), "the grid faces west on stone")
assert(graveyard.surfaceAt(400, 820) == "road" and graveyard.surfaceAt(400, 620) == "road",
    "the cloister's lawn drives as its path does")
for _,room in ipairs(data.rooms) do assert(room.surface == "road", "nothing slows the karts: " .. room.x) end
-- Version 2: the chamber's west wall stands either side of its door, where
-- the karts stopped at a wall the picture did not show; the door is the way
-- from the chamber into the west hall.
assert(graveyard.version == 2 and graveyard.surfaceAt(1350, 580) == "wall" and graveyard.surfaceAt(1350, 440) == "wall"
    and graveyard.surfaceAt(1350, 500) == "road", "the karts leave the chamber west by its door")
local progress = Checkpoints.new(graveyard, 0)
previous = {x=spawn.x, y=spawn.y, tick=0}
local names, walls = {}, 0
for index=2,#data.route do
    local target = data.route[index]
    local steps = math.max(1, math.ceil(distance(previous.x, previous.y, target.x, target.y) / 4))
    local fromX, fromY = previous.x, previous.y
    for k=1,steps do
        local tx, ty = fromX + (target.x - fromX) * k / steps, fromY + (target.y - fromY) * k / steps
        local mx, my, contact = graveyard.resolveMovement(previous.x, previous.y, tx, ty)
        if contact or mx ~= tx or my ~= ty then walls = walls + 1 end
        local current = {x=tx, y=ty, tick=previous.tick + 1}
        local before = progress.passed
        progress = Checkpoints.step(progress, previous, current, graveyard)
        if progress.passed > before then names[#names + 1] = graveyard.gates[progress.passed].name end
        previous = current
    end
end
assert(table.concat(names, ",") == "Chamber of Atonement,Forlorn Cloister,Honor's Tomb" and progress.complete,
    "the route passes the gates in order: " .. table.concat(names, ","))
assert(walls == 0, "the route never meets a wall or a solid")
-- Full throttle from the grid runs cleanly west along the entrance hall.
local state = Physics.new(graveyard)
for _=1,60 do state = Physics.step(state, {accelerate=true}, Physics.FIXED_DT, graveyard) end
assert(state.surface == "road" and state.impacts == 0 and state.x < spawn.x - 40, "a clean launch from the grid")
-- The graveyard's graves are solid on the lawn.
local graves = 0
for _,box in ipairs(graveyard.solids) do
    if graveyard.surfaceAt(box.x + box.width / 2, box.y + box.height / 2) == "wall" then graves = graves + 1 end
end
assert(graves == #graveyard.solids and graves >= 20, "every solid blocks (graves, the fountain, the tomb's dead)")

-- Scarlet Library (version 3): one run from the portal to the round
-- library. The grid faces north on stone; the reviewed route crosses the
-- four gates in order and never meets a wall or a solid. Loksey's kennel is
-- a side room with no gate (the owner: "the room is nice but not part of
-- the checkpoints"). The courtyard's lawn drives as its paths do, and the
-- courtyard is open (the owner, stopped between the fountain and a tree in
-- version 2: "cant even fit through here"): a clear ring round the
-- fountain and clear ways in from the four sides of the arcade. The
-- fountain's court and the round library are round rooms.
local library = Courses.build("scarlet_library", Track.crossesGate)
local libraryData = namespace.ScarletCrusade.scarlet_library
assert(library and library.laps == 1 and library.width == 2048 and library.height == 2048 and #library.gates == 4
    and library.version == 3, "the Library: a 2048 x 2048 sprint with four gates, version 3")
for _,gate in ipairs(library.gates) do assert(not gate.name:find("Loksey"), "no gate in Loksey's kennel") end
for _,room in ipairs(libraryData.rooms) do assert(room.surface == "road", "nothing slows the karts: " .. room.x) end
assert(library.surfaceAt(660, 300) == "road" and library.surfaceAt(660, 520) == "road",
    "the kennel and its door stay open floor")
assert(not ({library.resolveMovement(505, 820, 590, 820)})[3] and not ({library.resolveMovement(505, 820, 505, 812)})[3],
    "the courtyard's cross path is clear where a huntsman stood in version 1")
-- Round the fountain, 75 from its middle, in 5-degree steps: never a wall
-- or a solid; then in from each side of the arcade to that ring.
px, py = 660 + 75, 823
for k = 1, 72 do
    local angle = k * math.pi / 36
    local tx, ty = 660 + 75 * math.cos(angle), 823 + 75 * math.sin(angle)
    local mx, my, contact = library.resolveMovement(px, py, tx, ty)
    assert(not contact and mx == tx and my == ty, ("the ring round the fountain is clear (%.0f, %.0f)"):format(tx, ty))
    px, py = tx, ty
end
for _,way in ipairs({{505, 823, 585, 823}, {815, 823, 735, 823}, {660, 665, 660, 748}, {660, 975, 660, 898}}) do
    local mx, my, contact = library.resolveMovement(way[1], way[2], way[3], way[4])
    assert(not contact and mx == way[3] and my == way[4],
        ("a clear way in from the arcade at (%d, %d)"):format(way[1], way[2]))
end
local round = {}
for _,room in ipairs(libraryData.rooms) do
    if room.shape == "disc" then round[#round + 1] = room end
end
assert(#round == 2, "two round rooms: the fountain's court and the round library")
spawn = library.spawn()
assert(library.surfaceAt(spawn.x, spawn.y) == "road" and near(spawn.heading, math.pi / 2), "the grid faces north on stone")
assert(library.surfaceAt(600, 760) == "road" and library.surfaceAt(660, 700) == "road"
    and library.surfaceAt(1810, 450) == "road" and library.surfaceAt(1810, 340) == "wall",
    "the courtyard's lawn drives as its path does; the round library is stone to its round wall")
progress = Checkpoints.new(library, 0)
previous = {x=spawn.x, y=spawn.y, tick=0}
names, walls = {}, 0
for index=2,#libraryData.route do
    local target = libraryData.route[index]
    local steps = math.max(1, math.ceil(distance(previous.x, previous.y, target.x, target.y) / 4))
    local fromX, fromY = previous.x, previous.y
    for k=1,steps do
        local tx, ty = fromX + (target.x - fromX) * k / steps, fromY + (target.y - fromY) * k / steps
        local mx, my, contact = library.resolveMovement(previous.x, previous.y, tx, ty)
        if contact or mx ~= tx or my ~= ty then walls = walls + 1 end
        local current = {x=tx, y=ty, tick=previous.tick + 1}
        local before = progress.passed
        progress = Checkpoints.step(progress, previous, current, library)
        if progress.passed > before then names[#names + 1] = library.gates[progress.passed].name end
        previous = current
    end
end
assert(table.concat(names, ",") == "Huntsman's Cloister,Gallery of Treasures,Athenaeum,Arcanist Doan"
    and progress.complete, "the route passes the gates in order: " .. table.concat(names, ","))
assert(walls == 0, "the route never meets a wall or a solid")
-- Full throttle from the grid runs cleanly north up the portal hall.
state = Physics.new(library)
for _=1,60 do state = Physics.step(state, {accelerate=true}, Physics.FIXED_DT, library) end
assert(state.surface == "road" and state.impacts == 0 and state.y > spawn.y + 40, "a clean launch from the grid")
local blocking = 0
for _,box in ipairs(library.solids) do
    if library.surfaceAt(box.x + box.width / 2, box.y + box.height / 2) == "wall" then blocking = blocking + 1 end
end
assert(blocking == #library.solids and blocking >= 40, "every solid blocks (columns, trees, pillars, the living)")

-- Scarlet Armory (version 2): one run from the portal to Herod. The grid
-- faces east on stone; the reviewed route crosses the five gates in order,
-- straight through the Training Grounds' yard, and never meets a wall or a
-- solid. The yard, paved with flags in its grass, no longer slows the
-- karts (the owner: "should be able to drive through this without being
-- slowed"); its dummies, targets and their backstops block where they are
-- drawn. The Hall of Champions is a round room, and the finish runs across
-- its middle through Herod, who blocks.
local armory = Courses.build("scarlet_armory", Track.crossesGate)
local armoryData = namespace.ScarletCrusade.scarlet_armory
assert(armory and armory.laps == 1 and armory.width == 2048 and armory.height == 2048 and #armory.gates == 5
    and armory.version == 2, "the Armory: a 2048 x 2048 sprint with five gates, version 2")
for _,room in ipairs(armoryData.rooms) do assert(room.surface == "road", "nothing slows the karts: " .. room.x) end
round = {}
for _,room in ipairs(armoryData.rooms) do
    if room.shape == "disc" then round[#round + 1] = room end
end
assert(#round == 1 and round[1].width == 350 and round[1].height == 350, "one round room: the Hall of Champions")
spawn = armory.spawn()
assert(armory.surfaceAt(spawn.x, spawn.y) == "road" and near(spawn.heading, 0), "the grid faces east on stone")
assert(armory.surfaceAt(900, 400) == "road" and armory.surfaceAt(715, 420) == "road"
    and armory.surfaceAt(960, 585) == "road", "the yard drives as its stone walks do")
local yardSolids = 0
for _,box in ipairs(armory.solids) do
    if box.x >= 760 and box.x + box.width <= 1160 and box.y >= 300 and box.y + box.height <= 540 then
        yardSolids = yardSolids + 1
    end
end
assert(yardSolids >= 14, "the yard's dummies, targets, backstops, bushes and flowers block")
x, y, hit = armory.resolveMovement(900, 330, 900, 300)
assert(not hit and x == 900 and y == 300, "between the dummies the yard is open")
assert(armory.surfaceAt(1570, 1975) == "road" and armory.surfaceAt(1570, 1990) == "wall"
    and armory.surfaceAt(1720, 1978) == "wall", "the Hall of Champions is stone to its round wall, less the inset")
local finish = armory.gates[5]
assert(finish.name == "Herod" and finish.ay == 1828 and finish.by == 1828 and armory.surfaceAt(1570, 1828) == "wall"
    and armory.surfaceAt(1500, 1828) == "road" and armory.surfaceAt(1640, 1828) == "road",
    "the finish crosses the hall's middle, either side of Herod")
progress = Checkpoints.new(armory, 0)
previous = {x=spawn.x, y=spawn.y, tick=0}
names, walls = {}, 0
for index=2,#armoryData.route do
    local target = armoryData.route[index]
    local steps = math.max(1, math.ceil(distance(previous.x, previous.y, target.x, target.y) / 4))
    local fromX, fromY = previous.x, previous.y
    for k=1,steps do
        local tx, ty = fromX + (target.x - fromX) * k / steps, fromY + (target.y - fromY) * k / steps
        local mx, my, contact = armory.resolveMovement(previous.x, previous.y, tx, ty)
        if contact or mx ~= tx or my ~= ty then walls = walls + 1 end
        local current = {x=tx, y=ty, tick=previous.tick + 1}
        local before = progress.passed
        progress = Checkpoints.step(progress, previous, current, armory)
        if progress.passed > before then names[#names + 1] = armory.gates[progress.passed].name end
        previous = current
    end
end
assert(table.concat(names, ",") == "Training Grounds,Footman's Armory,Crusader's Armory,Hall of Champions,Herod"
    and progress.complete, "the route passes the gates in order: " .. table.concat(names, ","))
assert(walls == 0, "the route never meets a wall or a solid")
-- Full throttle from the grid runs cleanly east along the entrance hall.
state = Physics.new(armory)
for _=1,60 do state = Physics.step(state, {accelerate=true}, Physics.FIXED_DT, armory) end
assert(state.surface == "road" and state.impacts == 0 and state.x > spawn.x + 40, "a clean launch from the grid")
blocking = 0
for _,box in ipairs(armory.solids) do
    if armory.surfaceAt(box.x + box.width / 2, box.y + box.height / 2) == "wall" then blocking = blocking + 1 end
end
assert(blocking == #armory.solids and blocking >= 30, "every solid blocks (columns, targets, dummies, the living)")

-- Scarlet Cathedral (version 3): one run from the portal to the altar. The
-- grid faces west on stone; the reviewed route crosses the four gates in
-- order and never meets a wall or a solid. The gardens' lawns no longer
-- slow the karts; their pools are water the karts drive round, the round
-- pool a round solid; the stairs beside the falls are the only way up, the
-- champions' statues standing on raised plinths either side; each long
-- flight climbs to a landing walled by a parapet, and a short flight turns
-- outward onto the lawn (version 3); the trees and bushes block at their
-- crowns, round solids. The finish runs across the chancel before the
-- altar.
local cathedral = Courses.build("scarlet_cathedral", Track.crossesGate)
local cathedralData = namespace.ScarletCrusade.scarlet_cathedral
assert(cathedral and cathedral.laps == 1 and cathedral.width == 1024 and cathedral.height == 2048
    and #cathedral.gates == 4 and cathedral.version == 3, "the Cathedral: a 1024 x 2048 sprint with four gates, version 3")
for _,room in ipairs(cathedralData.rooms) do assert(room.surface == "road", "nothing slows the karts: " .. room.x) end
-- (Version 3's round pool: 115 in radius about (512, 865), its reach 133.)
local grazingX,grazingY,grazingHit=cathedral.resolveMovement(509.85,997.99,514.15,997.99)
assert(grazingHit and segmentRadius(509.85,997.99,grazingX,grazingY,512,865)>=133-1e-7
    and distance(509.85,997.99,grazingX,grazingY)<=4.3+1e-8,
    "production Cathedral normal-step grazing hits the round pool without crossing its clearance")
assert(not ({cathedral.resolveMovement(grazingX,grazingY,grazingX,grazingY)})[3],
    "the corrected production grazing endpoint needs no recovery")
print(("dungeon swept pool: production4.3-unit graze hit=%s, clearance=%.9f;360rotated grazes and circle/box ties covered"):format(
    tostring(grazingHit),segmentRadius(509.85,997.99,grazingX,grazingY,512,865)))
local roundRooms, roundSolids = 0, 0
for _,room in ipairs(cathedralData.rooms) do if room.shape == "disc" then roundRooms = roundRooms + 1 end end
for _,solid in ipairs(cathedralData.solids) do if solid.shape == "disc" then roundSolids = roundSolids + 1 end end
assert(roundRooms == 1 and roundSolids == 11,
    "one round room (Fairbanks' chamber); round solids: the round pool, ten trees' crowns and bushes")
spawn = cathedral.spawn()
assert(cathedral.surfaceAt(spawn.x, spawn.y) == "road" and near(spawn.heading, math.pi), "the grid faces west on stone")
assert(cathedral.surfaceAt(390, 446) == "road" and cathedral.surfaceAt(255, 446) == "road"
    and cathedral.surfaceAt(300, 900) == "road" and cathedral.surfaceAt(155, 900) == "road",
    "the gardens' lawns drive as their walks do")
assert(cathedral.surfaceAt(512, 470) == "wall" and cathedral.surfaceAt(512, 640) == "wall"
    and cathedral.surfaceAt(512, 978) == "wall" and cathedral.surfaceAt(600, 920) == "wall"
    and cathedral.surfaceAt(512, 985) == "road", "the lower pool, the falls and the round pool to its rim block")
assert(cathedral.surfaceAt(270, 610) == "wall" and cathedral.surfaceAt(754, 610) == "wall"
    and cathedral.surfaceAt(394, 610) == "road" and cathedral.surfaceAt(630, 610) == "road",
    "the plinths are stone the karts drive round; the stairs beside the falls are floor")
assert(cathedral.surfaceAt(394, 784) == "wall" and cathedral.surfaceAt(630, 784) == "wall"
    and cathedral.surfaceAt(394, 714) == "road" and cathedral.surfaceAt(300, 714) == "road"
    and cathedral.surfaceAt(724, 714) == "road", "parapets wall the landings; the short flights are floor")
-- The stairs are the only way up: driving north at a plinth's face stops at
-- it; up a long flight runs clean onto its landing, where the parapet stops
-- a kart driving on north; the short flight leads off the landing onto the
-- lawn, west on the west stairs and east on the east.
px, py = 270, 500
for _=1,60 do px, py = cathedral.resolveMovement(px, py, px, py + 4) end
assert(near(py, 542, 1e-6), "a plinth's face stops the karts")
x, y, hit = cathedral.resolveMovement(394, 520, 394, 700)
assert(not hit and y == 700, "up the west stairs onto the landing")
x, y, hit = cathedral.resolveMovement(630, 520, 630, 700)
assert(not hit and y == 700, "up the east stairs onto the landing")
px, py = 394, 700
for _=1,30 do px, py = cathedral.resolveMovement(px, py, px, py + 4) end
assert(near(py, 772 - 18, 1e-6), "the parapet stops a kart driving on north from the landing")
x, y, hit = cathedral.resolveMovement(394, 714, 230, 714)
assert(not hit and x == 230, "the west landing's short flight leads west onto the lawn")
x, y, hit = cathedral.resolveMovement(630, 714, 794, 714)
assert(not hit and x == 794, "the east landing's short flight leads east onto the lawn")
-- A tree blocks at its crown, as drawn: from the north a kart stops at the
-- crown's reach, never on the leaves.
local crown
for _,solid in ipairs(cathedralData.solids) do
    if solid.shape == "disc" and solid.x <= 360 and solid.x + solid.width >= 360 and solid.y <= 360
        and solid.y + solid.height >= 360 then crown = solid end
end
assert(crown and cathedral.surfaceAt(360, 360) == "wall", "the lower west tree's crown covers its trunk")
px, py = crown.x + crown.width / 2, crown.y + crown.height + 40
for _=1,30 do px, py = cathedral.resolveMovement(px, py, px, py - 4) end
assert(near(py, crown.y + crown.height + 18, 1e-6), "a kart stops at the crown's edge, not at a hidden trunk")
local finishGate = cathedral.gates[4]
assert(finishGate.name == "High Altar" and finishGate.ay == 1700 and finishGate.by == 1700
    and finishGate.ax == 295 and finishGate.bx == 729, "the finish crosses the chancel before the altar")
-- Head on into the round pool from its west lawn: the kart stops at the
-- pool's reach and, pushing on, slides round its rim, never into it.
px, py = 300, 900
local touched = false
for _=1,40 do
    local ex, ey, contact = cathedral.resolveMovement(px, py, px + 4, py)
    assert(distance(512, 865, ex, ey) >= 133, "never into the round pool")
    if contact and not touched then
        touched = true
        assert(near(distance(512, 865, ex, ey), 133, 1e-3), "stopped at the pool's reach")
    end
    px, py = ex, ey
end
assert(touched and py > 900, "and slides round its rim")
progress = Checkpoints.new(cathedral, 0)
previous = {x=spawn.x, y=spawn.y, tick=0}
names, walls = {}, 0
for index=2,#cathedralData.route do
    local target = cathedralData.route[index]
    local steps = math.max(1, math.ceil(distance(previous.x, previous.y, target.x, target.y) / 4))
    local fromX, fromY = previous.x, previous.y
    for k=1,steps do
        local tx, ty = fromX + (target.x - fromX) * k / steps, fromY + (target.y - fromY) * k / steps
        local mx, my, contact = cathedral.resolveMovement(previous.x, previous.y, tx, ty)
        if contact or mx ~= tx or my ~= ty then walls = walls + 1 end
        local current = {x=tx, y=ty, tick=previous.tick + 1}
        local before = progress.passed
        progress = Checkpoints.step(progress, previous, current, cathedral)
        if progress.passed > before then names[#names + 1] = cathedral.gates[progress.passed].name end
        previous = current
    end
end
assert(table.concat(names, ",") == "Chapel Gardens,Upper Gardens,Crusader's Chapel,High Altar"
    and progress.complete, "the route passes the gates in order: " .. table.concat(names, ","))
assert(walls == 0, "the route never meets a wall or a solid")
-- Full throttle from the grid runs cleanly west along the entrance hall.
state = Physics.new(cathedral)
for _=1,60 do state = Physics.step(state, {accelerate=true}, Physics.FIXED_DT, cathedral) end
assert(state.surface == "road" and state.impacts == 0 and state.x < spawn.x - 40, "a clean launch from the grid")
blocking = 0
for _,box in ipairs(cathedral.solids) do
    if cathedral.surfaceAt(box.x + box.width / 2, box.y + box.height / 2) == "wall" then blocking = blocking + 1 end
end
assert(blocking == #cathedral.solids and blocking >= 40, "every solid blocks (pools, pillars, trees, the living)")

print(("dungeon: rooms (and round rooms), lawns, solids (and round solids) and sliding walls; random steps; sprint "
    .. "race and one-run scores; Scarlet Graveyard %d rooms, %d solids; Scarlet Library %d rooms, %d solids; "
    .. "Scarlet Armory %d rooms, %d solids; Scarlet Cathedral %d rooms, %d solids; gates in order")
    :format(#graveyard.rooms, #graveyard.solids, #library.rooms, #library.solids, #armory.rooms, #armory.solids,
        #cathedral.rooms, #cathedral.solids))
