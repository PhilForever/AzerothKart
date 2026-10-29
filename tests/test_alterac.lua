-- Alterac Valley, the Battlegrounds Cup's third course, listed as coming
-- soon: one run (a sprint) from the Horde's side to the Alliance's along the
-- valley's real road, Frostwolf Village to Dun Baldar. Its generated
-- definition (Battlegrounds.lua, from scripts/battleground_layouts.py and
-- scripts/battleground_sprint.py) on Circuit.lua's open course: full grip a
-- few kart lengths either side of the road (no fences), slow snow beyond
-- (its grassMap) out to the valley's natural walls, and the Field of
-- Strife's ice (its iceMap: inert until Codex's slide). Its scenery is four
-- tiles (Courses.lua). Pure offline checks: its look and drive in the
-- client are separate, pending checks (docs/art/tracks/alterac-valley.md).
local AK = {}
for _,name in ipairs({"Track", "MirageRaceway", "Circuit", "CapitalCities", "Dungeon", "ScarletCrusade",
        "LayeredTrack", "Battlegrounds", "ArathiGrass", "Courses", "Physics", "Checkpoints", "Presentation"}) do
    assert(loadfile("addon/AzerothKart/" .. name .. ".lua"))("AzerothKart", AK)
end
local Track, Circuit, Checkpoints, Courses = AK.Track, AK.Circuit, AK.Checkpoints, AK.Courses
local data = AK.Battlegrounds.alterac_valley
local function distance(ax, ay, bx, by) return math.sqrt((bx - ax) ^ 2 + (by - ay) ^ 2) end

-- The generated definition: 2048 x 7168 at three units to the yard, an open
-- centerline run once, the street's full grip 145 from the road's middle
-- (its 52 and three kart lengths), the Dun Baldar bridge narrowed to 42.
assert(data and data.id == "alterac_valley" and data.version == 2 and data.width == 2048 and data.height == 7168
    and data.open == true and data.laps == 1 and data.fullSpeedToWalls == true
    and data.roadRadius == 145 and data.wallRadius == 145 and #data.narrows == 1
    and data.narrows[1].wallRadius == 42 and #data.solids == 0,
    "Alterac Valley version 2: 2048 x 7168, open, one run, full grip 145 either side, one bridge")
local track = Circuit.new(data, Track.crossesGate)
assert(track.open and track.laps == 1 and #track.gates == 8 and track.length > 7800 and track.length < 8800,
    "the valley's road, about 8,300 units: " .. track.length)
local names = {}
for _,gate in ipairs(data.gates) do names[#names + 1] = gate.name end
assert(table.concat(names, ",") == "Frostwolf Village,Tower Point,Iceblood Tower,Field of Strife,"
    .. "Stonehearth Outpost,Icewing Bunker,Dun Baldar Bridge,Dun Baldar",
    "eight gates named for the places on the way, the finish Dun Baldar's")

-- The grid: on the road below Frostwolf Village, facing north, the first
-- gate ahead of it.
local spawn = track.spawn()
assert(track.surfaceAt(spawn.x, spawn.y) == "road" and math.abs(spawn.heading - math.pi / 2) < 1e-12
    and spawn.y < data.gates[1].ay and spawn.y > 600, "the grid faces north on the road at Frostwolf")

-- The two packed grids, as Circuit.lua reads the first: a bit a cell of 8
-- units, row 0 the world's south edge.
local function bit(map, x, y)
    local col, row = math.floor(x / map.cellSize), math.floor(y / map.cellSize)
    local index = row * map.columns + col
    local byte = string.byte(map.data, math.floor(index / 8) + 1)
    return math.floor(byte / 2 ^ (index % 8)) % 2 == 1
end
for _,key in ipairs({"grassMap", "iceMap"}) do
    local map = data[key]
    assert(type(map) == "table" and map.cellSize == 8 and map.columns == 256 and map.rows == 896
        and #map.data == 256 * 896 / 8, "the " .. key .. " covers the valley in cells of 8")
end

-- Off the road, past its full grip, the valley is drivable slow snow, not a
-- fence, out to its natural walls: the slopes too steep to climb (where the
-- picture's cliffs show), the buildings, rocks and tree trunks. The road
-- runs between steep sides much of the way: a kart length past the grip's
-- edge about two points in five are open (measured), and the Field of
-- Strife is open across hundreds of units.
local snow, probes = 0, 0
for index=1,#data.centerline - 1,4 do
    local a, b = data.centerline[index], data.centerline[index + 1]
    local length = distance(a.x, a.y, b.x, b.y)
    if length > 0 then
        local nx, ny = -(b.y - a.y) / length, (b.x - a.x) / length
        for _,side in ipairs({1, -1}) do
            local x, y = a.x + side * nx * 176, a.y + side * ny * 176
            probes = probes + 1
            if track.surfaceAt(x, y) == "grass" then snow = snow + 1 end
        end
    end
end
assert(snow > probes * 0.3, "beside the road the snow is open: " .. snow .. " of " .. probes)
local field, fieldOpen = data.gates[4], 0
for x=field.ax,field.bx,8 do
    if track.surfaceAt(x, field.ay) ~= "wall" then fieldOpen = fieldOpen + 8 end
end
assert(field.name == "Field of Strife" and fieldOpen > 500, "the Field of Strife is open: " .. fieldOpen)
-- And the karts keep their grip out to the grip's edge (no shoulder).
local near = 0
for index=1,#data.centerline - 1,8 do
    local a, b = data.centerline[index], data.centerline[index + 1]
    local length = distance(a.x, a.y, b.x, b.y)
    if length > 0 and not (index >= data.narrows[1].first - 4 and index <= data.narrows[1].last + 4) then
        local nx, ny = -(b.y - a.y) / length, (b.x - a.x) / length
        for _,side in ipairs({1, -1}) do
            local s = track.surfaceAt(a.x + side * nx * 120, a.y + side * ny * 120)
            if s == "road" or s == "wall" then near = near + 1 else
                error("a kart's length from the grip's edge is still the street: " .. a.x .. ", " .. a.y)
            end
        end
    end
end
assert(near > 100, "the street's grip, checked at " .. near .. " points")
-- The bridge's deck at Dun Baldar is the one place walled in (its parapets).
local bridge = data.centerline[math.floor((data.narrows[1].first + data.narrows[1].last) / 2)]
assert(track.surfaceAt(bridge.x, bridge.y) == "road" and track.surfaceAt(bridge.x, bridge.y + 60) == "wall"
    and track.surfaceAt(bridge.x, bridge.y - 60) == "wall", "the bridge's deck, walled on both sides")

-- The ice: the Field of Strife alone, the road across it included; none at
-- the grid or the finish.
local x0, y0, x1, y1, cells = math.huge, math.huge, -math.huge, -math.huge, 0
local ice = data.iceMap
for row=0,ice.rows - 1 do
    for col=0,ice.columns - 1 do
        if bit(ice, col * 8 + 4, row * 8 + 4) then
            cells = cells + 1
            x0, y0 = math.min(x0, col * 8), math.min(y0, row * 8)
            x1, y1 = math.max(x1, col * 8 + 8), math.max(y1, row * 8 + 8)
        end
    end
end
assert(cells > 3000 and x0 >= 500 and x1 <= 1380 and y0 >= 3500 and y1 <= 4560,
    ("the ice is the Field of Strife's: %d cells in %d..%d x %d..%d"):format(cells, x0, x1, y0, y1))
local iced = 0
for _,p in ipairs(data.centerline) do
    if bit(ice, p.x, p.y) then iced = iced + 1 end
end
local finish = data.gates[#data.gates]
assert(iced > 20 and not bit(ice, spawn.x, spawn.y) and not bit(ice, finish.ax, (finish.ay + finish.by) / 2),
    "the road crosses the ice (" .. iced .. " centerline points), the grid and the finish are dry")

-- The reviewed route from the grid to the finish: kart-centre steps of at
-- most 4 units through Circuit.resolveMovement, never meeting a wall; the
-- gates counted in order by Checkpoints where the route's crossings say,
-- the run complete at the last.
assert(data.route[1].x == spawn.x and data.route[1].y == spawn.y, "the route starts on the grid")
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
    "the route passes the gates in order: " .. table.concat(passed, ","))
assert(table.concat(crossed, ",") == table.concat(data.routeGates, ","),
    "each gate's route point is where the route crosses it: " .. table.concat(crossed, ","))
assert(steps_ > 1900, "the run walked in " .. steps_ .. " steps")

-- A gate is a cut across the open ground: with its line shut, no way leads
-- round it (the generator's flood fill); here, both its ends stand at the
-- valley's natural walls or the world's edge, not on open snow.
for _,gate in ipairs(data.gates) do
    local ux, uy = gate.bx - gate.ax, gate.by - gate.ay
    local length = math.sqrt(ux * ux + uy * uy)
    ux, uy = ux / length, uy / length
    for _,e in ipairs({{gate.ax - ux * 12, gate.ay - uy * 12}, {gate.bx + ux * 12, gate.by + uy * 12}}) do
        assert(track.surfaceAt(e[1], e[2]) == "wall", "the " .. gate.name .. " gate reaches a wall at "
            .. e[1] .. ", " .. e[2])
    end
end

-- Version 2 (the owner: "put this gate at the start of the bridge so that
-- the pillars have something to stand on (in the snow)"): Dun Baldar
-- Bridge's gate is across the deck where the karts come onto it, past the
-- bank (975) within the approach's walls (to 999), crossed westwards; its
-- posts, and every post Presentation moves off the rule's ground, stand on
-- the open snow near their gate's end, not over the gorge or on a tower.
local bridgeGate = data.gates[7]
assert(bridgeGate.name == "Dun Baldar Bridge" and bridgeGate.ax == bridgeGate.bx and bridgeGate.ax > 975
    and bridgeGate.ax < 999 and math.abs(bridgeGate.by - bridgeGate.ay) <= 2 * 42 and bridgeGate.nx == -1,
    "the bridge's gate is across its mouth: " .. bridgeGate.ax)
local stands, standing = AK.Presentation.GATE_STYLES.alterac_valley.stands, 0
for _,gate in ipairs(data.gates) do
    local stand = stands[gate.name]
    for side,point in ipairs(stand and {stand[1], stand[2]} or {}) do
        if point then
            local ex, ey = side == 1 and gate.ax or gate.bx, side == 1 and gate.ay or gate.by
            assert(bit(data.grassMap, point[1], point[2]) and distance(point[1], point[2], ex, ey) < 60,
                gate.name .. "'s post " .. side .. " stands on the snow by its end")
            standing = standing + 1
        end
    end
end
assert(standing == 4 and stands["Dun Baldar Bridge"][1][1] > bridgeGate.ax
    and stands["Dun Baldar Bridge"][2][1] > bridgeGate.ax, "the bridge's posts on the bank, either side of its mouth")

-- The heights (inert, ADR 0015): one per centerline point.
assert(#data.elevation.centerline == #data.centerline and #data.elevation.branches == 0,
    "a height per centerline point")

-- Registered only with both generated masks and the opt-in ice query.
local course = Courses.get("alterac_valley")
assert(course and not course.soon and course.cup == "battlegrounds" and course.geometry == "circuit"
    and not course.guideArrow and Courses.available("alterac_valley")
    and Courses.multiplayer("alterac_valley")
    and Courses.next("arathi_basin") == "alterac_valley" and Courses.next("alterac_valley")=="mirage_raceway",
    "Alterac Valley is registered for solo and the current multiplayer flow")
for _,key in ipairs({"grassMap","iceMap"}) do
    local saved=data[key];data[key]=nil
    assert(Courses.build("alterac_valley",Track.crossesGate)==nil,"missing "..key.." refuses construction")
    data[key]=saved
end
local production=assert(Courses.build("alterac_valley",Track.crossesGate))
assert(production.laps==1 and not production.layered and type(production.iceAt)=="function"
    and AK.Physics.versionForTrack(production)==16,"Alterac uses one-run flat ice Physics16")
-- Its scenery: four tiles, bands of the world from south to north, each a
-- picture at most 2048 a side, the first its background.
local tiles = course.tiles
assert(type(tiles) == "table" and #tiles == 4 and tiles[1].path == course.background, "four tiles")
local top = 0
for index,tile in ipairs(tiles) do
    assert(tile.x0 == 0 and tile.x1 == data.width and tile.y0 == top and tile.y1 > tile.y0
        and tile.y1 - tile.y0 <= 2048 and tile.path:find("AlteracValley\\Background" .. index .. ".tga", 1, true),
        "tile " .. index .. " is the next band of the valley")
    top = tile.y1
end
assert(top == data.height, "the tiles cover the valley")
print("Alterac Valley version 2: a sprint of eight gates (the bridge's at its mouth), open snow, the Field of "
    .. "Strife's ice, route walked")
