-- Warsong Gulch, the Battlegrounds Cup's first course: its generated two-floor
-- geometry (Battlegrounds.lua, from scripts/battleground_layouts.py) on Codex's
-- LayeredTrack, Physics pads and Checkpoints. Pure offline checks: the course
-- is registered for solo and two-peer racing; its look, roofs and drive in the
-- client are separate, pending checks (docs/art/tracks/warsong-gulch.md).
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
    and track.laps == 3 and #track.gates == 7 and #track.ramps == 8 and #track.pads == 2
    and track.surfaceAt(380, 2000, 0) == "wall" and track.surfaceAt(644, 175, 0) == "wall",
    "Warsong: 1024 x 2048, two floors, eight ramps, seven gates, two Boots, three laps; each flag stands solid")
assert(Physics.ValidatePads(data.pads) and Physics.versionForTrack(track) == Physics.FEATURE_VERSION,
    "the Boots are valid pads; the course needs the floors-and-pads physics")
local spawn = track.spawn()
assert(spawn.level == 0 and math.abs(spawn.heading - math.pi / 2) < 1e-12 and track.surfaceAt(spawn.x, spawn.y, 0) == "road",
    "the grid stands at mid on the ground, facing the Alliance base")
for _,room in ipairs(data.rooms) do assert(room.surface == "road", "the whole gulch drives at full grip") end

-- Two floors at one place: the Alliance tunnel runs under the plateau.
assert(track.surfaceAt(400, 1560, 0) == "road" and track.surfaceAt(400, 1560, 1) == "road",
    "the tunnel below and the plateau above share x/y")
assert(track.surfaceAt(300, 1560, 0) == "wall" and track.surfaceAt(300, 1560, 1) == "road",
    "beside the tunnel the hill is solid below and drivable on top")
assert(track.surfaceAt(440, 1980, 0) == "road" and track.surfaceAt(440, 1980, 1) == "road",
    "the flag room below and the roof's walk above")
-- The Horde's half is the Alliance's turned half a circle.
for _,p in ipairs({{400, 1560}, {300, 1560}, {440, 1925}, {824, 1460}, {660, 1780}, {600, 1580}, {440, 1980}}) do
    for level=0,1 do
        assert(track.surfaceAt(p[1], p[2], level) == track.surfaceAt(1024 - p[1], 2048 - p[2], level),
            "point-symmetric floors at " .. p[1] .. "," .. p[2])
    end
end

-- The reviewed route: kart-centre steps of at most 4 units through
-- LayeredTrack, the floor changing only on ramps, never meeting a wall; the
-- gates counted by Checkpoints, which needs both poses on the gate's floor.
local progress = Checkpoints.new(track, 0)
local previous = {x=spawn.x, y=spawn.y, level=spawn.level, tick=0}
local names, walls, levels = {}, 0, {0}
for index=2,#data.route do
    local target = data.route[index]
    local fromX, fromY = previous.x, previous.y
    local steps = math.max(1, math.ceil(distance(fromX, fromY, target.x, target.y) / 4))
    for k=1,steps do
        local tx, ty = fromX + (target.x - fromX) * k / steps, fromY + (target.y - fromY) * k / steps
        local mx, my, contact, level = track.resolveMovement(previous.x, previous.y, tx, ty, previous.level)
        if contact or math.abs(mx - tx) > 1e-9 or math.abs(my - ty) > 1e-9 then walls = walls + 1 end
        if level ~= previous.level then levels[#levels + 1] = level end
        local current = {x=mx, y=my, level=level, tick=previous.tick + 1}
        local before = progress.passed
        progress = Checkpoints.step(progress, previous, current, track)
        if progress.passed > before then names[#names + 1] = track.gates[progress.passed].name end
        previous = current
    end
end
assert(walls == 0, "the route never meets a wall: " .. walls)
assert(table.concat(names, ",") == "Alliance tunnel,Alliance flag,Alliance ramp,Horde tunnel,Horde flag,Horde ramp,Mid"
    and progress.complete, "the route passes the gates in lap order: " .. table.concat(names, ","))
assert(table.concat(levels, "") == "01010", "up the front door to the plateau and down the ramp, at each base")

-- The flag counts only on the ground: a kart on the roof above it passes.
local roof = Checkpoints.new(track, 0)
roof.nextGate = 2
local stepped = Checkpoints.step(roof, {x=382, y=1925, level=1, tick=0}, {x=378, y=1925, level=1, tick=1}, track)
assert(stepped.passed == 0, "driving over the flag room on the roof is not a capture")
stepped = Checkpoints.step(roof, {x=382, y=1925, level=0, tick=0}, {x=378, y=1925, level=0, tick=1}, track)
assert(stepped.passed == 1, "crossing the flag room west on the ground is")

-- Ramps change floor end to end only; their sides are walls on both floors.
local x, y, hit, level = track.resolveMovement(824, 1390, 824, 1402, 0)
assert(not hit and level == 0 and y == 1402, "up the Alliance ramp from the gully, still on the ground")
x, y, hit, level = track.resolveMovement(824, 1505, 824, 1515, 0)
assert(not hit and level == 1 and y == 1515, "off its top onto the plateau")
x, y, hit, level = track.resolveMovement(790, 1460, 770, 1460, 0)
assert(hit and level == 0 and x >= 782, "the ramp's side is a wall")
x, y, hit, level = track.resolveMovement(824, 1595, 824, 1606, 1)
assert(hit and level == 1 and y <= 1602, "the plateau's edge stops a kart above the banana's foot")
x, y, hit, level = track.resolveMovement(824, 1630, 824, 1646, 0)
assert(not hit and level == 0, "the banana climbs from its foot, under the plateau")
x, y, hit, level = track.resolveMovement(708, 1780, 716, 1780, 0)
assert(not hit and level == 1, "the connector meets the terrace at its top")

-- The Boots: a kart driving through the Alliance tunnel's pad boosts once.
local kart = Physics.new(track)
kart.x, kart.y, kart.heading, kart.speed, kart.level = 400, 1630, math.pi / 2, 180, 0
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
    and production.id == data.id and production.version == 1 and production.laps == 3
    and production.layered and Physics.versionForTrack(production) == 13,
    "the real layered three-lap track is available in solo and two-peer racing")
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
print("Warsong Gulch: two floors, eight ramps, seven gates, two Boots; route walked")
