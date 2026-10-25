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

-- Invalid dungeons are refused.
for _,bad in ipairs({
    {rooms={{x=20, y=20, width=15, height=100, surface="road"}}},
    {rooms={{x=20, y=20, width=200, height=160, surface="lava"}}},
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
assert(context.lapCount == 1 and context.trackId == "crypt", "a sprint's score context is one run")
assert(Records.Context(Track).lapCount == 3, "the oval's score context keeps three laps")

-- The Scarlet Crusade Cup: the catalogue's third cup. Scarlet Graveyard is
-- ready; the Library, the Armory and the Monastery are coming soon.
assert(#Courses.CUPS == 3 and Courses.CUPS[3].id == "scarlet" and Courses.CUPS[3].name == "Scarlet Crusade Cup",
    "the Scarlet Crusade Cup")
local graveyardCourse = Courses.get("scarlet_graveyard")
assert(graveyardCourse.cup == "scarlet" and graveyardCourse.geometry == "dungeon" and Courses.available("scarlet_graveyard"),
    "Scarlet Graveyard is a ready dungeon")
for _,id in ipairs({"scarlet_library", "scarlet_armory", "scarlet_monastery"}) do
    local course = Courses.get(id)
    assert(course and course.cup == "scarlet" and course.soon and not Courses.available(id)
        and Courses.build(id, Track.crossesGate) == nil, id .. " is coming soon")
end
assert(Courses.next("undercity_slime") == "scarlet_graveyard" and Courses.next("scarlet_graveyard") == "test_oval",
    "the Track button steps on to the Graveyard, then round to the oval")

-- Scarlet Graveyard: one run from the entrance to Honor's Tomb. The spawn
-- stands on stone; the reviewed route crosses the three gates in order and
-- never meets a wall or a solid; the cloister's lawn is grass.
local graveyard = Courses.build("scarlet_graveyard", Track.crossesGate)
local data = namespace.ScarletCrusade.scarlet_graveyard
assert(graveyard and graveyard.laps == 1 and graveyard.width == 2048 and graveyard.height == 1024
    and #graveyard.gates == 3, "the Graveyard: a 2048 x 1024 sprint with three gates")
assert(Courses.build("scarlet_graveyard", Track.crossesGate) == graveyard, "the built course is kept")
local spawn = graveyard.spawn()
assert(graveyard.surfaceAt(spawn.x, spawn.y) == "road" and near(spawn.heading, math.pi), "the grid faces west on stone")
assert(graveyard.surfaceAt(400, 820) == "grass" and graveyard.surfaceAt(400, 620) == "road",
    "the cloister's lawn is grass, its path stone")
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

print(("dungeon: rooms, lawns, solids and sliding walls; 4000 random steps; sprint race and one-run scores; "
    .. "Scarlet Graveyard %d rooms, %d solids, gates in order"):format(#graveyard.rooms, #graveyard.solids))
