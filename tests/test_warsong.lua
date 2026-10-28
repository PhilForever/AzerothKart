-- Warsong Gulch, the Battlegrounds Cup's first course (version 2, laid on the
-- real gulch): its generated two-floor geometry (Battlegrounds.lua, from
-- scripts/battleground_layouts.py) on Codex's LayeredTrack, Physics pads and
-- Checkpoints. Pure offline checks: the course is registered for solo and
-- two-peer racing; its look, covers and drive in the client are separate,
-- pending checks (docs/art/tracks/warsong-gulch.md).
local AK = {}
for _,name in ipairs({"Track", "MirageRaceway", "Circuit", "CapitalCities", "Dungeon", "ScarletCrusade",
        "LayeredTrack", "Battlegrounds", "Courses", "Physics", "Checkpoints", "RaceGrid"}) do
    assert(loadfile("addon/AzerothKart/" .. name .. ".lua"))("AzerothKart", AK)
end
local Track, LayeredTrack, Physics, Checkpoints = AK.Track, AK.LayeredTrack, AK.Physics, AK.Checkpoints
local data = AK.Battlegrounds.warsong_gulch
local function distance(ax, ay, bx, by) return math.sqrt((bx - ax) ^ 2 + (by - ay) ^ 2) end

-- The contract's own constructor accepts the course: ramps reserved, their
-- ends on their floors, gates and pads clear of them, the spawn on floor 0.
local track = LayeredTrack.new(data, Track.crossesGate)
assert(track.layered and track.levelCount == 2 and track.width == 1024 and track.height == 2048
    and track.laps == 3 and #track.gates == 7 and #track.ramps == 2 and #track.pads == 2
    and track.surfaceAt(451, 1926, 1) == "wall" and track.surfaceAt(470, 210, 0) == "wall",
    "Warsong: 1024 x 2048, two floors, two ramps, seven gates, two Boots, three laps; each flag stands solid")
assert(Physics.ValidatePads(data.pads) and Physics.versionForTrack(track) == Physics.FEATURE_VERSION,
    "the Boots are valid pads; the course needs the floors-and-pads physics")
local spawn = track.spawn()
assert(spawn.level == 0 and math.abs(spawn.heading - math.pi / 2) < 1e-12 and track.surfaceAt(spawn.x, spawn.y, 0) == "road",
    "the grid stands at mid on the ground, facing the Alliance tunnel")
for _,room in ipairs(data.rooms) do assert(room.surface == "road", "the whole gulch drives at full grip") end

-- Two floors at one place: the Alliance tunnel runs under the plateau.
assert(track.surfaceAt(522, 1622, 0) == "road" and track.surfaceAt(522, 1622, 1) == "road",
    "the tunnel below and the plateau above share x/y")
assert(track.surfaceAt(400, 1622, 0) == "wall" and track.surfaceAt(400, 1622, 1) == "road",
    "beside the tunnel the hill is solid below and drivable on top")
assert(track.surfaceAt(388, 1800, 1) == "road" and track.surfaceAt(388, 1800, 0) == "wall"
    and track.surfaceAt(400, 1990, 1) == "road", "Silverwing Hold's lobby and flag room are floor 1")
assert(track.surfaceAt(540, 150, 0) == "road" and track.surfaceAt(540, 150, 1) == "wall"
    and track.surfaceAt(238, 450, 0) == "road", "the Lumber Mill and the slope below it are floor 0")
-- The wall between each base's way in and way out ends at its flag: no
-- kart passes between them.
local x, y, hit, level = track.resolveMovement(500, 1890, 400, 1890, 1)
assert(hit and level == 1 and x >= 480, "the hold's wall between the tunnel and the lobby")
x, y, hit, level = track.resolveMovement(500, 1915, 400, 1915, 1)
assert(hit and level == 1 and x >= 470, "and the flag at its end")
x, y, hit, level = track.resolveMovement(510, 240, 420, 240, 0)
assert(hit and level == 0 and x >= 498, "the mill's wall between the tunnel and the west passage")
x, y, hit, level = track.resolveMovement(510, 205, 420, 205, 0)
assert(hit and level == 0 and x >= 490, "and the flag at its end")

-- The reviewed route: kart-centre steps of at most 4 units through
-- LayeredTrack, the floor changing only on ramps, never meeting a wall; the
-- gates counted by Checkpoints, which needs both poses on the gate's floor.
-- The route's gate crossings (the guiding arrow's way) are where it counts them.
local progress = Checkpoints.new(track, 0)
local previous = {x=spawn.x, y=spawn.y, level=spawn.level, tick=0}
local names, walls, levels, crossed = {}, 0, {0}, {}
for index=2,#data.route do
    local target = data.route[index]
    local fromX, fromY = previous.x, previous.y
    local steps = math.max(1, math.ceil(distance(fromX, fromY, target.x, target.y) / 4))
    for k=1,steps do
        local tx, ty = fromX + (target.x - fromX) * k / steps, fromY + (target.y - fromY) * k / steps
        local mx, my, contact, lvl = track.resolveMovement(previous.x, previous.y, tx, ty, previous.level)
        if contact or math.abs(mx - tx) > 1e-9 or math.abs(my - ty) > 1e-9 then walls = walls + 1 end
        if lvl ~= previous.level then levels[#levels + 1] = lvl end
        local current = {x=mx, y=my, level=lvl, tick=previous.tick + 1}
        local before = progress.passed
        progress = Checkpoints.step(progress, previous, current, track)
        if progress.passed > before then
            names[#names + 1] = track.gates[progress.passed].name
            crossed[#crossed + 1] = index
        end
        previous = current
    end
end
assert(walls == 0, "the route never meets a wall: " .. walls)
assert(table.concat(names, ",") == "Alliance tunnel,Alliance flag,Alliance front door,Horde tunnel,Horde flag,"
    .. "Horde side door,Mid" and progress.complete, "the route passes the gates in lap order: " .. table.concat(names, ","))
assert(table.concat(levels, "") == "010", "up the tunnel's climb into the hold, down the east path to the field")
assert(table.concat(crossed, ",") == table.concat(data.routeGates, ","),
    "each gate's route point is where the route crosses it: " .. table.concat(crossed, ","))
local route = AK.Courses.route("warsong_gulch")
assert(route and route.points == data.route and route.gates == data.routeGates and not AK.Courses.route("mirage_raceway"),
    "the guided course hands its route to the arrow; other courses have none")

-- The flag counts rounding it the lap's way only.
local flag = Checkpoints.new(track, 0)
flag.nextGate = 2
local stepped = Checkpoints.step(flag, {x=449, y=1990, level=1, tick=0}, {x=453, y=1990, level=1, tick=1}, track)
assert(stepped.passed == 0, "rounding the Alliance flag the wrong way is not a capture")
stepped = Checkpoints.step(flag, {x=453, y=1990, level=1, tick=0}, {x=449, y=1990, level=1, tick=1}, track)
assert(stepped.passed == 1, "rounding it west is")

-- Ramps change floor end to end only; their sides are walls on both floors.
x, y, hit, level = track.resolveMovement(522, 1690, 522, 1702, 0)
assert(not hit and level == 0 and y == 1702, "up the tunnel's climb from the tunnel, still on the ground")
x, y, hit, level = track.resolveMovement(522, 1805, 522, 1815, 0)
assert(not hit and level == 1 and y == 1815, "off its top into the hold")
x, y, hit, level = track.resolveMovement(780, 1600, 780, 1585, 1)
assert(not hit and level == 1, "from the plateau onto the east path")
x, y, hit, level = track.resolveMovement(780, 1485, 780, 1475, 1)
assert(not hit and level == 0 and y == 1475, "off its foot into the field")
x, y, hit, level = track.resolveMovement(745, 1530, 725, 1530, 0)
assert(hit and level == 0 and x >= 738, "the east path's side is a wall")
x, y, hit, level = track.resolveMovement(522, 1650, 522, 1666, 1)
assert(hit and level == 1 and y <= 1654, "the plateau's edge stops a kart above the climb's foot")

-- The Boots: a kart driving up the Alliance tunnel through its pad boosts once.
local kart = Physics.new(track)
kart.x, kart.y, kart.heading, kart.speed, kart.level = 522, 1560, math.pi / 2, 180, 0
local boosted = false
for _=1,30 do
    kart = Physics.step(kart, {accelerate=true}, Physics.FIXED_DT, track)
    boosted = boosted or (kart.boostTicks or 0) > 0
end
assert(boosted and kart.level == 0 and kart.impacts == 0, "the Boots boost a kart in the tunnel")

-- The shared grid: both karts side by side on the ground at mid.
local host, guest = AK.RaceGrid.pose(track, "host")
assert(host and guest and host.level == 0 and guest.level == 0
    and track.isDrivable(host.x, host.y, 0) and track.isDrivable(guest.x, guest.y, 0),
    "both grid poses stand on floor 0")

-- Registered in its own cup. Building through the production catalogue must
-- preserve the reviewed geometry, shared start and feature compatibility.
local course = AK.Courses.get("warsong_gulch")
assert(course and not course.soon and course.cup == "battlegrounds" and course.geometry == "layered",
    "Warsong is registered in the Battlegrounds Cup")
local production = assert(AK.Courses.build("warsong_gulch", Track.crossesGate))
assert(AK.Courses.available("warsong_gulch") and AK.Courses.multiplayer("warsong_gulch")
    and production.id == data.id and production.version == 2 and production.laps == 3
    and production.layered and Physics.versionForTrack(production) == 13,
    "the real layered three-lap track (version 2) is available in solo and two-peer racing")
assert(AK.Courses.build("warsong_gulch", Track.crossesGate) == production,
    "production geometry is built once and retained")
local flat, layered = 0, 0
for _,entry in ipairs(AK.Courses.LIST) do
    local built = assert(AK.Courses.build(entry.id, Track.crossesGate))
    if entry.id == "warsong_gulch" then
        layered = layered + 1
    else
        flat = flat + 1
        assert(not built.layered and Physics.versionForTrack(built) == 12,
            "existing flat course keeps Physics12: " .. entry.id)
    end
end
assert(flat == 11 and layered == 1 and Physics.VERSION == 12 and Physics.FEATURE_VERSION == 13,
    "Warsong adds a separate feature context without retiming the eleven existing courses")
assert(not AK.Courses.get("test_oval") and not AK.Courses.available("test_oval")
    and not AK.Courses.multiplayer("test_oval") and not AK.Courses.build("test_oval", Track.crossesGate),
    "the development oval stays retired")
assert(AK.Courses.CUPS[#AK.Courses.CUPS].id == "battlegrounds"
    and AK.Courses.CUPS[#AK.Courses.CUPS].name == "Battlegrounds Cup", "the fourth cup")
print("Warsong Gulch v2: two floors, two ramps, seven gates, two Boots; route walked, arrow's crossings agree")
