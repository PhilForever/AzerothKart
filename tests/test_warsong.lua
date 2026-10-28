-- Warsong Gulch, the Battlegrounds Cup's first course (version 3, laid on the
-- real gulch, both bases driven alike): its generated two-floor geometry
-- (Battlegrounds.lua, from scripts/battleground_layouts.py) on Codex's
-- LayeredTrack, Physics pads and Checkpoints. Pure offline checks: the course
-- is registered for solo and two-peer racing; its look, covers and drive in
-- the client are separate, pending checks (docs/art/tracks/warsong-gulch.md).
local AK = {}
for _,name in ipairs({"Track", "MirageRaceway", "Circuit", "CapitalCities", "Dungeon", "ScarletCrusade",
        "LayeredTrack", "Battlegrounds", "ArathiGrass", "Courses", "Physics", "Checkpoints", "RaceGrid", "Presentation"}) do
    assert(loadfile("addon/AzerothKart/" .. name .. ".lua"))("AzerothKart", AK)
end
local Track, LayeredTrack, Physics, Checkpoints = AK.Track, AK.LayeredTrack, AK.Physics, AK.Checkpoints
local data = AK.Battlegrounds.warsong_gulch
local function distance(ax, ay, bx, by) return math.sqrt((bx - ax) ^ 2 + (by - ay) ^ 2) end

-- The contract's own constructor accepts the course: ramps reserved, their
-- ends on their floors, gates and pads clear of them, the spawn on floor 0.
local track = LayeredTrack.new(data, Track.crossesGate)
assert(track.layered and track.levelCount == 2 and track.width == 1024 and track.height == 2048
    and track.laps == 3 and #track.gates == 7 and #track.ramps == 4 and #track.pads == 2
    and track.surfaceAt(451, 1926, 1) == "wall" and track.surfaceAt(611, 135, 1) == "wall"
    and track.surfaceAt(559, 1046, 0) == "wall",
    "Warsong: 1024 x 2048, two floors, four ramps, seven gates, two Boots, three laps; each flag and mid's stumps solid")
assert(Physics.ValidatePads(data.pads) and Physics.versionForTrack(track) == Physics.FEATURE_VERSION,
    "the Boots are valid pads; the course needs the floors-and-pads physics")
local spawn = track.spawn()
assert(spawn.level == 0 and math.abs(spawn.heading - math.pi / 2) < 1e-12 and track.surfaceAt(spawn.x, spawn.y, 0) == "road"
    and spawn.x > 600, "the grid stands east of mid on the ground, facing north up the field's east side")
for _,room in ipairs(data.rooms) do assert(room.surface == "road", "the whole gulch drives at full grip") end

-- Two floors at one place, at each base: its tunnel runs under its plateau;
-- the hold and the mill are floor 1. The Horde's base is the Alliance's
-- turned half a circle about (531, 1030.5).
assert(track.surfaceAt(522, 1622, 0) == "road" and track.surfaceAt(522, 1622, 1) == "road"
    and track.surfaceAt(540, 439, 0) == "road" and track.surfaceAt(540, 439, 1) == "road",
    "each tunnel below and its plateau above share x/y")
assert(track.surfaceAt(400, 1622, 0) == "wall" and track.surfaceAt(400, 1622, 1) == "road"
    and track.surfaceAt(662, 439, 0) == "wall" and track.surfaceAt(662, 439, 1) == "road",
    "beside each tunnel the hill is solid below and drivable on top")
assert(track.surfaceAt(388, 1800, 1) == "road" and track.surfaceAt(388, 1800, 0) == "wall"
    and track.surfaceAt(400, 1990, 1) == "road" and track.surfaceAt(674, 261, 1) == "road"
    and track.surfaceAt(674, 261, 0) == "wall" and track.surfaceAt(662, 71, 1) == "road",
    "Silverwing Hold's and the Lumber Mill's lobbies and flag rooms are floor 1")
local raised = 0
for _,room in ipairs(data.rooms) do
    if room.level == 1 and room.y > 1024 then
        local turned = false
        for _,other in ipairs(data.rooms) do
            turned = turned or (other.level == 1 and other.x == 1062 - room.x - room.width
                and other.y == 2061 - room.y - room.height and other.width == room.width and other.height == room.height)
        end
        assert(turned, "each of Silverwing Hold's floor-1 rooms has its turned twin at the mill: " .. room.x .. "," .. room.y)
        raised = raised + 1
    end
end
assert(raised == 5, "five floor-1 rooms a side: the plateau, the front yard, the lobby, the flag room, the tunnel's top")

-- A straight push in legal steps: 4 units at a time (LayeredTrack refuses
-- any request over MAX_STEP before it looks at a wall), each from where the
-- kart stands, resolved against the walls and solids, with Checkpoints
-- watching the gate it is told is next.
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
-- The wall between each lobby and its tunnel's top ends at the flag: driving
-- at it from either side stops at it, or wedges between the flag and the
-- wall's end, and takes nothing; round the flag's far cap the kart slides on
-- across the flag's gate and takes it, as it does passing beyond the flag.
local x, y, hit, level, taken = push(400, 1890, 1, 0, 100, 1, 2)
assert(hit and level == 1 and math.abs(x - 422) < 1e-9 and y == 1890 and not taken,
    "the hold's wall between the lobby and the tunnel's top stops a kart at the lobby's side")
x, y, hit, level, taken = push(500, 1890, -1, 0, 100, 1, 2)
assert(hit and level == 1 and math.abs(x - 480) < 1e-9 and y == 1890 and not taken, "and at the tunnel's side")
x, y, hit, level, taken = push(400, 1915, 1, 0, 100, 1, 2)
assert(hit and level == 1 and x < 440 and y > 1900 and y < 1915 and not taken,
    "against the Alliance flag the kart slides into the corner it makes with the wall: " .. x .. "," .. y)
x, y, hit, level, taken = push(400, 1945, 1, 0, 120, 1, 2)
assert(hit and level == 1 and x > 451 and y > 1950 and taken,
    "round the Alliance flag's northern cap and on east: the flag's gate, taken: " .. x .. "," .. y)
x, y, hit, level, taken = push(400, 1990, 1, 0, 120, 1, 2)
assert(not hit and x == 520 and taken, "east beyond the flag: taken")
x, y, hit, level, taken = push(562, 171, 1, 0, 100, 1, 5)
assert(hit and level == 1 and math.abs(x - 582) < 1e-9 and y == 171 and not taken,
    "the mill's wall between the tunnel's top and the lobby stops a kart at the tunnel's side")
x, y, hit, level, taken = push(674, 171, -1, 0, 100, 1, 5)
assert(hit and level == 1 and math.abs(x - 640) < 1e-9 and y == 171 and not taken, "and at the lobby's side")
x, y, hit, level, taken = push(674, 146, -1, 0, 100, 1, 5)
assert(hit and level == 1 and x > 622 and y > 146 and y < 160 and not taken,
    "against the Horde flag the kart slides into the corner it makes with the wall: " .. x .. "," .. y)
x, y, hit, level, taken = push(674, 116, -1, 0, 120, 1, 5)
assert(hit and level == 1 and x < 611 and y < 111 and taken,
    "round the Horde flag's southern cap and on west: the flag's gate, taken: " .. x .. "," .. y)
x, y, hit, level, taken = push(674, 71, -1, 0, 120, 1, 5)
assert(not hit and x == 554 and taken, "west beyond the flag: taken")

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
assert(table.concat(names, ",") == "Alliance front door,Alliance flag,Alliance tunnel,Horde front door,Horde flag,"
    .. "Horde tunnel,Mid" and progress.complete, "the route passes the gates in lap order: " .. table.concat(names, ","))
assert(table.concat(levels, "") == "01010",
    "up each base's outside ramp onto its plateau, down its tunnel's climb to the field")
assert(table.concat(crossed, ",") == table.concat(data.routeGates, ","),
    "each gate's route point is where the route crosses it: " .. table.concat(crossed, ","))
assert(route and route.points == data.route and route.gates == data.routeGates and not AK.Courses.route("mirage_raceway"),
    "the guided course hands its route to the arrow; other courses have none")
-- Version 2's front-yard corner (Codex's review), now driven the other way:
-- from the yard the arrow points up through the front door.
local heading, reach, along = AK.Presentation.guideHeading(track, {passed=0, nextGate=1, complete=false},
    390, 1685, route, 1)
assert(along and clearRun(390, 1685, heading, reach, 1) and math.abs(heading - math.pi / 2) < math.pi / 8,
    "in the Alliance's front yard the arrow points up through the door: " .. math.deg(heading))
heading, reach, along = AK.Presentation.guideHeading(track, {passed=3, nextGate=4, complete=false},
    672, 376, route, 1)
assert(along and clearRun(672, 376, heading, reach, 1) and math.abs(heading + math.pi / 2) < math.pi / 8,
    "in the Horde's, down through its door: " .. math.deg(heading))

-- Each flag counts rounding it the lap's way only: the Alliance's east, the
-- Horde's west.
local flag = Checkpoints.new(track, 0)
flag.nextGate, flag.passed = 2, 1
local stepped = Checkpoints.step(flag, {x=453, y=1990, level=1, tick=0}, {x=449, y=1990, level=1, tick=1}, track)
assert(stepped.passed == 1, "rounding the Alliance flag west is not a capture")
stepped = Checkpoints.step(flag, {x=449, y=1990, level=1, tick=0}, {x=453, y=1990, level=1, tick=1}, track)
assert(stepped.passed == 2, "rounding it east is")
flag.nextGate, flag.passed = 5, 4
stepped = Checkpoints.step(flag, {x=609, y=71, level=1, tick=0}, {x=613, y=71, level=1, tick=1}, track)
assert(stepped.passed == 4, "rounding the Horde flag east is not a capture")
stepped = Checkpoints.step(flag, {x=613, y=71, level=1, tick=0}, {x=609, y=71, level=1, tick=1}, track)
assert(stepped.passed == 5, "rounding it west is")

-- Ramps change floor end to end only; their sides are walls on both floors.
x, y, hit, level = track.resolveMovement(780, 1475, 780, 1485, 0)
assert(not hit and level == 0 and y == 1485, "onto the east path from the field, still on the ground")
x, y, hit, level = track.resolveMovement(780, 1585, 780, 1600, 0)
assert(not hit and level == 1 and y == 1600, "off its top onto the plateau")
x, y, hit, level = track.resolveMovement(522, 1815, 522, 1805, 1)
assert(not hit and level == 1 and y == 1805, "onto the tunnel's climb from the hold, still on floor 1")
x, y, hit, level = track.resolveMovement(522, 1702, 522, 1690, 1)
assert(not hit and level == 0 and y == 1690, "off its foot into the tunnel")
x, y, hit, level = track.resolveMovement(282, 586, 282, 576, 0)
assert(not hit and level == 0 and y == 576, "onto the west path from the field, still on the ground")
x, y, hit, level = track.resolveMovement(282, 476, 282, 461, 0)
assert(not hit and level == 1 and y == 461, "off its top onto the Horde's plateau")
x, y, hit, level = track.resolveMovement(540, 246, 540, 256, 1)
assert(not hit and level == 1 and y == 256, "onto the Horde tunnel's climb from the mill, still on floor 1")
x, y, hit, level = track.resolveMovement(540, 359, 540, 371, 1)
assert(not hit and level == 0 and y == 371, "off its foot into the tunnel")
x, y, hit, level = push(745, 1530, -1, 0, 20, 0, 4)
assert(hit and level == 0 and math.abs(x - 738) < 1e-9, "the east path's side is a wall")
x, y, hit, level = push(317, 531, 1, 0, 20, 0, 1)
assert(hit and level == 0 and math.abs(x - 324) < 1e-9, "and the west path's")
x, y, hit, level = track.resolveMovement(522, 1650, 522, 1662, 1)
assert(hit and level == 1 and math.abs(y - 1654) < 1e-9,
    "the Alliance's plateau edge stops a kart above the climb's foot (a 12-unit move, stopped 4 on)")
x, y, hit, level = track.resolveMovement(540, 411, 540, 399, 1)
assert(hit and level == 1 and math.abs(y - 407) < 1e-9, "and the Horde's")

-- The Boots: a kart driving down each tunnel through its pad boosts once.
for _,run in ipairs({{522, 1640, -math.pi / 2, "Alliance"}, {540, 420, math.pi / 2, "Horde"}}) do
    local kart = Physics.new(track)
    kart.x, kart.y, kart.heading, kart.speed, kart.level = run[1], run[2], run[3], 180, 0
    local boosted = false
    for _=1,30 do
        kart = Physics.step(kart, {accelerate=true}, Physics.FIXED_DT, track)
        boosted = boosted or (kart.boostTicks or 0) > 0
    end
    assert(boosted and kart.level == 0 and kart.impacts == 0, "the Boots boost a kart in the " .. run[4] .. " tunnel")
end

-- The shared grid: both karts side by side on the ground east of mid.
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
    and production.id == data.id and production.version == 3 and production.laps == 3
    and production.layered and Physics.versionForTrack(production) == 13,
    "the real layered three-lap track (version 3) is available in solo and two-peer racing")
assert(AK.Courses.build("warsong_gulch", Track.crossesGate) == production,
    "production geometry is built once and retained")
local flat, layered, soon = 0, 0, 0
for _,entry in ipairs(AK.Courses.LIST) do
    local built = AK.Courses.build(entry.id, Track.crossesGate)
    assert(built or entry.soon, "every registered course builds: " .. entry.id)
    if entry.soon then
        soon = soon + 1
    elseif entry.id == "warsong_gulch" then
        layered = layered + 1
    else
        flat = flat + 1
        assert(not built.layered and Physics.versionForTrack(built) == 12,
            "existing flat course keeps Physics12: " .. entry.id)
    end
end
assert(flat == 12 and layered == 1 and soon == 1 and AK.Courses.get("alterac_valley").soon
    and Physics.VERSION == 12 and Physics.FEATURE_VERSION == 13,
    "Warsong keeps a separate feature context while all twelve flat courses retain Physics12")
assert(not AK.Courses.get("test_oval") and not AK.Courses.available("test_oval")
    and not AK.Courses.multiplayer("test_oval") and not AK.Courses.build("test_oval", Track.crossesGate),
    "the development oval stays retired")
assert(AK.Courses.CUPS[#AK.Courses.CUPS].id == "battlegrounds"
    and AK.Courses.CUPS[#AK.Courses.CUPS].name == "Battlegrounds Cup", "the fourth cup")
print("Warsong Gulch v3: two floors, four ramps, seven gates, two Boots; both bases alike; route walked, arrow clear")
