-- Warsong Gulch, the Battlegrounds Cup's first course (version 2, laid on the
-- real gulch): its generated two-floor geometry (Battlegrounds.lua, from
-- scripts/battleground_layouts.py) on Codex's LayeredTrack, Physics pads and
-- Checkpoints. Pure offline checks: the course is registered for solo and
-- two-peer racing; its look, covers and drive in the client are separate,
-- pending checks (docs/art/tracks/warsong-gulch.md).
local AK = {}
for _,name in ipairs({"Track", "MirageRaceway", "Circuit", "CapitalCities", "Dungeon", "ScarletCrusade",
        "LayeredTrack", "Battlegrounds", "Courses", "Physics", "Checkpoints", "RaceGrid", "Presentation"}) do
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
-- A straight push in legal steps: 4 units at a time (LayeredTrack refuses
-- any request over MAX_STEP before it looks at a wall), each from where the
-- kart stands, resolved against the walls and solids, with Checkpoints
-- watching the gate it is told is next (Codex's review of v2).
local function push(x, y, ux, uy, length, level, gate)
    local progress = {nextGate=gate, passed=gate - 1, complete=false, lastTick=0}
    local pose, contact = {x=x, y=y, level=level, tick=0}, false
    for _=1,math.ceil(length / 4) do
        local mx, my, hit, lvl = track.resolveMovement(pose.x, pose.y, pose.x + ux * 4, pose.y + uy * 4, pose.level)
        contact = contact or hit
        local current = {x=mx, y=my, level=lvl, tick=pose.tick + 1}
        progress = Checkpoints.step(progress, pose, current, track)
        pose = current
    end
    return pose.x, pose.y, contact, pose.level, progress.passed == gate
end
-- The wall between each base's way in and way out ends at its flag: driving
-- across from the tunnel's side stops at the wall, or wedges between the
-- Alliance flag and the wall's end, and takes nothing; round the Horde flag's
-- southern cap the kart slides on, west across the flag's gate, and takes it.
local x, y, hit, level, taken = push(500, 1890, -1, 0, 100, 1, 2)
assert(hit and level == 1 and math.abs(x - 480) < 1e-9 and y == 1890 and not taken,
    "the hold's wall between the tunnel and the lobby stops a kart at the tunnel's side")
x, y, hit, level, taken = push(500, 1915, -1, 0, 100, 1, 2)
assert(hit and level == 1 and x > 470 and y > 1900 and not taken,
    "against the Alliance flag the kart slides into the corner it makes with the wall: " .. x .. "," .. y)
x, y, hit, level, taken = push(510, 240, -1, 0, 90, 0, 5)
assert(hit and level == 0 and math.abs(x - 498) < 1e-9 and y == 240 and not taken,
    "the mill's wall between the tunnel and the west passage")
x, y, hit, level, taken = push(510, 205, -1, 0, 160, 0, 5)
assert(hit and level == 0 and x < 470 and math.abs(y - 177.902) < 0.01 and taken,
    "round the Horde flag's southern cap and on west: the flag's gate, taken: " .. x .. "," .. y)

-- The reviewed route: kart-centre steps of at most 4 units through
-- LayeredTrack, the floor changing only on ramps, never meeting a wall; the
-- gates counted by Checkpoints, which needs both poses on the gate's floor.
-- The route's gate crossings (the guiding arrow's way) are where it counts them.
-- At every step the guiding arrow (Presentation.guideHeading, given the
-- kart's floor) points where the kart can drive: a straight run along it, in
-- 2-unit steps, to the point it aims at meets no wall or solid.
local route = AK.Courses.route("warsong_gulch")
local function clearRun(fromX, fromY, heading, length, lvl)
    local px, py = fromX, fromY
    for k=1,math.ceil(length / 2) do
        local s = math.min(2, length - (k - 1) * 2)
        local mx, my, hit, next = track.resolveMovement(px, py, px + math.cos(heading) * s, py + math.sin(heading) * s, lvl)
        if hit then return false end
        px, py, lvl = mx, my, next
    end
    return true
end
local progress = Checkpoints.new(track, 0)
local previous = {x=spawn.x, y=spawn.y, level=spawn.level, tick=0}
local names, walls, levels, crossed, aimed, blind = {}, 0, {0}, {}, 0, 0
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
        if not progress.complete then
            local heading, reach, along = AK.Presentation.guideHeading(track, progress, mx, my, route, lvl)
            aimed = aimed + 1
            if not (along and clearRun(mx, my, heading, reach, lvl)) then blind = blind + 1 end
        end
    end
end
assert(walls == 0, "the route never meets a wall: " .. walls)
assert(aimed > 1000 and blind == 0, "from every step of the lap the arrow points where the kart can drive: "
    .. blind .. " of " .. aimed .. " do not")
-- Codex's reproduction: leaving the front yard toward the plateau, the point
-- 110 on lies across the corner (a run at it meets the wall 36 units out);
-- the arrow aims along the yard first.
local heading, reach, along = AK.Presentation.guideHeading(track, {passed=3, nextGate=4, complete=false},
    390, 1685, route, 1)
assert(along and clearRun(390, 1685, heading, reach, 1) and heading < -math.pi / 4,
    "at the front yard's turn the arrow points down the yard, not across the corner: " .. math.deg(heading))
local straight = AK.Presentation.guideHeading(track, {passed=3, nextGate=4, complete=false}, 390, 1685, route)
assert(not clearRun(390, 1685, straight, 46, 1), "without the kart's floor it would point into the corner")
assert(table.concat(names, ",") == "Alliance tunnel,Alliance flag,Alliance front door,Horde tunnel,Horde flag,"
    .. "Horde side door,Mid" and progress.complete, "the route passes the gates in lap order: " .. table.concat(names, ","))
assert(table.concat(levels, "") == "010", "up the tunnel's climb into the hold, down the east path to the field")
assert(table.concat(crossed, ",") == table.concat(data.routeGates, ","),
    "each gate's route point is where the route crosses it: " .. table.concat(crossed, ","))
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
x, y, hit, level = push(745, 1530, -1, 0, 20, 0, 4)
assert(hit and level == 0 and math.abs(x - 738) < 1e-9, "the east path's side is a wall")
x, y, hit, level = track.resolveMovement(522, 1650, 522, 1662, 1)
assert(hit and level == 1 and math.abs(y - 1654) < 1e-9,
    "the plateau's edge stops a kart above the climb's foot (a 12-unit move, stopped 4 on)")

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
