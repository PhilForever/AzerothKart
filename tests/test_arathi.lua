-- Arathi Basin, the Battlegrounds Cup's second registered course (version
-- 2, after the owner's drive): its generated circuit (Battlegrounds.lua,
-- from scripts/battleground_layouts.py) on Codex's Circuit.lua, laid on the
-- basin's real roads, the Stables' yard a meadow of slow grass, no guiding
-- arrow. Pure offline checks: its look and drive in the client are
-- separate, pending checks (docs/art/tracks/arathi-basin.md).
local AK = {}
for _,name in ipairs({"Track", "MirageRaceway", "Circuit", "CapitalCities", "Dungeon", "ScarletCrusade",
        "LayeredTrack", "Battlegrounds", "ArathiGrass", "Courses", "Physics", "Checkpoints", "Presentation"}) do
    assert(loadfile("addon/AzerothKart/" .. name .. ".lua"))("AzerothKart", AK)
end
local Track, Circuit, Checkpoints = AK.Track, AK.Circuit, AK.Checkpoints
local data = AK.Battlegrounds.arathi_basin
local function distance(ax, ay, bx, by) return math.sqrt((bx - ax) ^ 2 + (by - ay) ^ 2) end

-- The contract's own constructor accepts it: the cities' street (road
-- radius 56, the karts' reach 76, full grip to the walls), the walls'
-- clearance at their junctions, two bridges narrowed, the Stables' yard (a
-- meadow: Circuit's grass plaza) and its barn.
local savedMask = data.grassMap
data.grassMap = nil
assert(AK.Courses.build("arathi_basin", Track.crossesGate) == nil,
    "missing generated collision data must not silently use the old track")
data.grassMap = savedMask
local track = Circuit.new(data, Track.crossesGate)
assert(track.version == 3 and track.width == 2048 and track.height == 2048 and track.roadRadius == 56
    and track.wallRadius == 76 and track.fullSpeedToWalls and track.wallClearance == 14 and #track.wallVertices > 0
    and #track.gates == 5 and #track.narrows == 2 and #track.plazas == 1 and track.plazas[1].surface == "grass"
    and #track.solids == 1 and #track.branches == 0,
    "Arathi Basin version 3: 2048 x 2048, five gates, two bridges, the Stables' meadow and barn")
assert(track.laps == nil and AK.Physics.versionForTrack(track) == AK.Physics.VERSION,
    "three laps on the flat physics: no floors, no pads")
assert(track.length > 4900 and track.length < 5300, "about 5,100 units a lap: " .. track.length)
local names = {}
for _,gate in ipairs(data.gates) do names[#names + 1] = gate.name end
assert(table.concat(names, ",") == "Gold Mine,Stables,Lumber Mill,Farm,Defiler's Den",
    "the gates in lap order, named for the bases they pass; the finish for the Horde's")

-- The grid: on the east road, facing north up it, the finish line just
-- behind it (the karts cross it only to end a lap).
local spawn = track.spawn()
local finish = data.gates[#data.gates]
assert(track.surfaceAt(spawn.x, spawn.y) == "road" and math.abs(spawn.heading - math.pi / 2) < 1e-12
    and spawn.x > 1600 and finish.ay == finish.by and finish.ny == 1 and spawn.y > finish.ay
    and spawn.y - finish.ay < 80 and spawn.x > finish.ax and spawn.x < finish.bx,
    "the grid faces north on the east road, the finish behind it")

-- Each bridge is a narrows: its deck narrower than the road (the karts'
-- reach 42 from its middle), the river beside it a wall; the road off the
-- bridge is full width again.
for _,deck in ipairs({{x=1584, y=810}, {x=241, y=1518}}) do
    assert(track.surfaceAt(deck.x, deck.y) == "road" and track.surfaceAt(deck.x - 38, deck.y) == "road"
        and track.surfaceAt(deck.x + 38, deck.y) == "road" and track.surfaceAt(deck.x - 50, deck.y) == "wall"
        and track.surfaceAt(deck.x + 50, deck.y) == "wall", "a bridge's deck, walled on both sides: " .. deck.x)
end
assert(track.surfaceAt(1650 - 70, 600) == "road" and track.surfaceAt(1650 + 70, 600) == "road",
    "south of the east bridge's approach the road is full width")

-- The Stables: the barn is solid; the yard round it is a meadow, slow grass
-- (the shortcut south of the barn, from the gate to the west bridge); the
-- road round north of it, and the west road beside the meadow, keep the
-- street's full grip. The yard still drives on both sides of the barn.
local barn = data.solids[1]
local bx, by = barn.x + barn.width / 2, barn.y + barn.height / 2
assert(barn.id == "stables" and track.surfaceAt(bx, by) == "wall", "the barn stands solid in the yard")
for _,p in ipairs({{bx, barn.y - 40}, {450, 1640}, {520, 1650}, {bx, barn.y + barn.height + 40}}) do
    assert(track.surfaceAt(p[1], p[2]) == "grass" and not track.isDrivable(p[1], p[2]),
        "the meadow is slow grass: " .. p[1] .. ", " .. p[2])
end
for _,p in ipairs({{410, 1838}, {340, 1860}, {240, 1680}, {612, 1755}}) do
    assert(track.surfaceAt(p[1], p[2]) == "road", "the road round the Stables keeps full grip: " .. p[1] .. ", " .. p[2])
end
local function push(x, y, ux, uy, length)
    local px, py, contact = x, y, false
    for _=1,math.ceil(length / 4) do
        local mx, my, hit = track.resolveMovement(px, py, px + ux * 4, py + uy * 4)
        contact = contact or hit
        px, py = mx, my
    end
    return px, py, contact
end
local x, y, hit = push(barn.x + barn.width + 60, by, -1, 0, 120)
assert(hit and math.abs(x - (barn.x + barn.width + track.wallInset)) < 1e-9 and y == by,
    "driving west into the barn stops at its east face")
x, y, hit = push(barn.x + barn.width + 60, barn.y + barn.height + 40, -1, 0, 260)
assert(not hit and x < barn.x - 40, "north of the barn the yard is open: " .. x)
x, y, hit = push(barn.x + barn.width + 60, barn.y - 40, -1, 0, 260)
assert(not hit and x < barn.x - 40, "south of the barn the yard is open: " .. x)

-- The reviewed route (review data since version 2: no guiding arrow, the
-- owner keeps it for Warsong Gulch alone): kart-centre steps of at most 4
-- units through Circuit.resolveMovement, never meeting a wall; the gates
-- counted in lap order by Checkpoints where the route's gate crossings say.
local course = AK.Courses.get("arathi_basin")
assert(not course.guideArrow and AK.Courses.route("arathi_basin") == nil,
    "no guiding arrow on Arathi Basin: the way is plain")
assert(data.route[1].x == spawn.x and data.route[1].y == spawn.y
    and data.route[#data.route].x == spawn.x and data.route[#data.route].y == spawn.y,
    "the route runs from the grid round to it")
local progress = Checkpoints.new(track, 0)
local previous = {x=spawn.x, y=spawn.y, tick=0}
local passed, walls, crossed, steps_ = {}, 0, {}, 0
for index=2,#data.route do
    local target = data.route[index]
    local fromX, fromY = previous.x, previous.y
    local steps = math.max(1, math.ceil(distance(fromX, fromY, target.x, target.y) / 4))
    for k=1,steps do
        local tx, ty = fromX + (target.x - fromX) * k / steps, fromY + (target.y - fromY) * k / steps
        local mx, my, contact = track.resolveMovement(previous.x, previous.y, tx, ty)
        if contact or math.abs(mx - tx) > 1e-9 or math.abs(my - ty) > 1e-9 then walls = walls + 1 end
        local current = {x=mx, y=my, tick=previous.tick + 1}
        local before = progress.passed
        progress = Checkpoints.step(progress, previous, current, track)
        if progress.passed > before then
            passed[#passed + 1] = track.gates[progress.passed].name
            crossed[#crossed + 1] = index
        end
        previous = current
        steps_ = steps_ + 1
    end
end
assert(walls == 0, "the route never meets a wall: " .. walls)
assert(table.concat(passed, ",") == table.concat(names, ",") and progress.complete,
    "the route passes the gates in lap order: " .. table.concat(passed, ","))
assert(table.concat(crossed, ",") == table.concat(data.routeGates, ","),
    "each gate's route point is where the route crosses it: " .. table.concat(crossed, ","))
assert(steps_ > 1000, "the lap walked in " .. steps_ .. " steps")

-- The heights (inert, ADR 0015): one per centerline point, world units
-- above the lap's lowest ground: the Gold Mine's hollow at 0, the Lumber
-- Mill's hill the highest, the grid between.
local heights = data.elevation.centerline
assert(#heights == #data.centerline and #data.elevation.branches == 0, "a height per centerline point")
local low, high, lowAt, highAt = math.huge, -math.huge, nil, nil
for index,h in ipairs(heights) do
    if h < low then low, lowAt = h, index end
    if h > high then high, highAt = h, index end
end
local function near(index, x, y, reach)
    local p = data.centerline[index]
    return distance(p.x, p.y, x, y) < reach
end
assert(low == 0 and high > 300 and near(lowAt, 1300, 1640, 220) and near(highAt, 500, 680, 260)
    and heights[1] > 100 and heights[1] < high,
    "down to the Gold Mine (0), up to the Lumber Mill (" .. high .. "), the grid between (" .. heights[1] .. ")")

-- Arathi is registered for solo and two-peer races with flat Physics14.
assert(course and not course.soon and course.cup == "battlegrounds"
    and course.geometry == "circuit" and not course.guideArrow
    and AK.Courses.available("arathi_basin") and AK.Courses.multiplayer("arathi_basin"),
    "Arathi Basin is available in the Battlegrounds Cup")
assert(AK.Courses.next("warsong_gulch") == "arathi_basin"
    and AK.Courses.next("arathi_basin") == "mirage_raceway", "the Track button includes Arathi")
local built = assert(AK.Courses.build("arathi_basin", Track.crossesGate))
assert(built.id == "arathi_basin" and built.version == 3 and built.length == track.length
    and #built.gates == 5 and (built.laps or 3) == 3 and not built.layered
    and AK.Physics.versionForTrack(built) == 14 and AK.Courses.roofs("arathi_basin") == nil,
    "the catalogue builds version 3 as a flat, three-lap Physics14 circuit with no roofs")
-- Temporarily model a future coming-soon entry without changing the real catalogue.
course.soon = true
assert(not AK.Courses.available("arathi_basin") and not AK.Courses.multiplayer("arathi_basin")
    and AK.Courses.build("arathi_basin", Track.crossesGate) == nil
    and AK.Courses.next("warsong_gulch") == "mirage_raceway",
    "a temporarily gated course cannot be selected or raced")
course.soon = nil
assert(AK.Courses.build("arathi_basin", Track.crossesGate) == built,
    "restoring availability reuses the built geometry")
print("Arathi Basin version 3: five gates, two bridges, the Stables' meadow and barn, route walked, no arrow")
