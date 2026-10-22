-- City circuits (Circuit.lua) and the course catalog (Courses.lua): street
-- walls, plazas, solids, gates and the generated Stormwind City Circuit.
-- Pure offline checks; the scenery's look and the drive in the client are
-- separate, pending checks (docs/art/tracks/stormwind.md).
local namespace = {}
local function load(name)
    local chunk = assert(loadfile("addon/AzerothKart/" .. name .. ".lua"))
    chunk("AzerothKart", namespace)
end
for _,name in ipairs({"Track", "MirageRaceway", "Circuit", "CapitalCities", "Courses", "Physics", "Checkpoints"}) do
    load(name)
end
local Track, Circuit, Courses = namespace.Track, namespace.Circuit, namespace.Courses
local Physics, Checkpoints = namespace.Physics, namespace.Checkpoints

local function near(a, b, tolerance) return math.abs(a - b) <= (tolerance or 1e-6) end
local function distance(ax, ay, bx, by) return math.sqrt((bx - ax) ^ 2 + (by - ay) ^ 2) end

-- A small square street: road radius 20, walls at 30, a plaza with a statue.
local square = Circuit.new({
    id="square", width=400, height=400, wallInset=6, roadRadius=20, wallRadius=30,
    centerline={{x=100,y=100}, {x=300,y=100}, {x=300,y=300}, {x=100,y=300}},
    gates={{name="East", ax=270, ay=200, bx=330, by=200, nx=0, ny=1},
           {name="Start", ax=70, ay=200, bx=130, by=200, nx=0, ny=-1}},
    plazas={{ax=200, ay=300, bx=200, by=300, radius=60}},
    solids={{id="statue", x=190, y=320, width=20, height=10}},
    spawn={x=200, y=100, heading=0},
}, Track.crossesGate)

assert(square.surfaceAt(200, 100) == "road" and square.surfaceAt(200, 125) == "grass"
    and square.surfaceAt(200, 135) == "wall", "road, kerbside strip and wall across the street")
assert(square.isDrivable(200, 115) and not square.isDrivable(200, 125), "only the paving is road")
assert(square.surfaceAt(200, 200) == "wall", "the block inside the loop is wall")
assert(square.surfaceAt(200, 350) == "road" and square.surfaceAt(160, 340) == "road",
    "the plaza is open paving beyond the street's own walls")
assert(square.surfaceAt(200, 325) == "wall", "a solid on the plaza is wall")

-- Driving into a wall stops at the wall radius, slides along it, counts a hit.
local x, y, hit = square.resolveMovement(200, 128, 200, 133)
assert(hit and near(y, 130, 0.01) and near(x, 200, 0.01), "a step through the wall ends at it")
assert(square.surfaceAt(x, y) == "grass", "the wall's foot is the kerbside strip, never wall")
x, y, hit = square.resolveMovement(200, 129, 204, 133)
assert(hit and x > 203.5 and near(y, 130, 0.05), "a glancing step keeps its motion along the wall")
x, y, hit = square.resolveMovement(200, 100, 203, 101)
assert(not hit and x == 203 and y == 101, "free road movement is exact")

-- The plaza's statue blocks with the kart clearance; the street wall holds
-- even where it meets the plaza.
x, y, hit = square.resolveMovement(200, 311, 200, 316)
assert(hit and near(y, 314, 1e-9) and x == 200, "the statue stops a kart at its expanded face")
x, y, hit = square.resolveMovement(255, 340, 262, 350)
assert(hit and distance(x, y, 200, 300) <= 60 + 1e-6, "the plaza's own edge is a wall")

-- A centre outside every street (never by driving) returns to the nearest
-- drivable point; one inside a solid leaves it by the nearest face.
x, y, hit = square.resolveMovement(200, 200, 200, 200)
assert(hit and square.surfaceAt(x, y) ~= "wall", "a centre in the block is recovered onto the street")
x, y, hit = square.resolveMovement(200, 322, 200, 322)
assert(hit and square.surfaceAt(x, y) ~= "wall" and (y <= 314 or y >= 336 or x <= 184 or x >= 216),
    "a centre in the statue leaves by a face")

-- A resolved step never moves further than it was asked to (the checkpoint
-- step bound relies on it), including round the plaza's corners.
local seed = 12345
local function random()
    seed = (seed * 1103515245 + 12345) % 2147483648
    return seed / 2147483648
end
for _=1,4000 do
    -- Settle the start first: a centre inside a solid's clearance is recovered
    -- (never reached by driving), which is not a step.
    local rx, ry = 60 + random() * 280, 60 + random() * 300
    local px, py = square.resolveMovement(rx, ry, rx, ry)
    if square.surfaceAt(px, py) ~= "wall" then
        local angle = random() * 2 * math.pi
        local step = random() * 260 / 60
        local tx, ty = px + math.cos(angle) * step, py + math.sin(angle) * step
        local qx, qy = square.resolveMovement(px, py, tx, ty)
        assert(distance(px, py, qx, qy) <= step + 1e-9, "no resolved step outruns its request")
        assert(square.surfaceAt(qx, qy) ~= "wall", "a resolved step ends on drivable ground")
    end
end
assert(not pcall(Circuit.new, {id="bad", width=10, height=10, wallInset=1, roadRadius=5, wallRadius=4,
    centerline={{x=1,y=1},{x=2,y=1},{x=2,y=2}}, gates={{}}, spawn={x=1,y=1}}, Track.crossesGate),
    "walls must enclose the road")

-- The catalog: cups in order, coming-soon cities listed but not selectable.
assert(#Courses.CUPS == 2 and Courses.CUPS[2].name == "Capital Cities Cup", "two cups")
local soon = 0
for _,course in ipairs(Courses.LIST) do
    if course.soon then
        soon = soon + 1
        assert(course.cup == "capital" and not Courses.available(course.id) and
            Courses.build(course.id, Track.crossesGate) == nil, "a coming-soon city cannot be built")
    end
end
assert(soon == 4 and Courses.available("stormwind_city") and Courses.available("ironforge_gp"),
    "Stormwind and Ironforge are ready; four cities are coming")
assert(Courses.next("test_oval") == "mirage_raceway" and Courses.next("mirage_raceway") == "stormwind_city"
    and Courses.next("stormwind_city") == "ironforge_gp" and Courses.next("ironforge_gp") == "test_oval",
    "the Track button cycles the ready tracks")
assert(Courses.build("test_oval", Track.crossesGate) == Track, "the oval is the original track")
local stormwind = Courses.build("stormwind_city", Track.crossesGate)
assert(stormwind and Courses.build("stormwind_city", Track.crossesGate) == stormwind, "built once, kept")

-- A walk of a city's course from its spawn (the approach, then the loop
-- twice until the lap completes): the gate names passed in order, and how
-- many walk points met a wall.
local function walk(track, data)
    local spawn = track.spawn()
    assert(track.surfaceAt(spawn.x, spawn.y) == "road", data.id .. ": the start grid is on the road")
    local path = {}
    for _,point in ipairs(data.branches[1]) do path[#path + 1] = point end
    for _=1,2 do
        for _,point in ipairs(data.centerline) do path[#path + 1] = point end
    end
    local start = 1
    for index,point in ipairs(path) do
        if distance(point.x, point.y, spawn.x, spawn.y) < distance(path[start].x, path[start].y, spawn.x, spawn.y) then
            start = index
        end
    end
    local progress = Checkpoints.new(track, 0)
    local previous = {x=spawn.x, y=spawn.y, tick=0}
    local names, walls = {}, 0
    for index=start + 1,#path do
        local target = path[index]
        local steps = math.max(1, math.ceil(distance(previous.x, previous.y, target.x, target.y) / 4))
        local fromX, fromY = previous.x, previous.y
        for k=1,steps do
            local px = fromX + (target.x - fromX) * k / steps
            local py = fromY + (target.y - fromY) * k / steps
            if track.surfaceAt(px, py) == "wall" then walls = walls + 1 end
            local current = {x=px, y=py, tick=previous.tick + 1}
            local before = progress.passed
            progress = Checkpoints.step(progress, previous, current, track)
            if progress.passed > before then names[#names + 1] = track.gates[progress.passed].name end
            previous = current
        end
        if progress.complete then break end
    end
    assert(progress.complete, data.id .. ": the walk completes the lap")
    return table.concat(names, ","), walls
end

-- Stormwind: the spawn sits on the Valley of Heroes road; the walk passes
-- the six district gates in order and completes the lap's checkpoints.
local data = namespace.CapitalCities.stormwind_city
assert(stormwind.wallRadius == 76 and stormwind.roadRadius == 56 and #stormwind.gates == 6,
    "Stormwind's street: 112-unit road, 20-unit kerbside strips, six gates")
local spawn = stormwind.spawn()
local names, walls = walk(stormwind, data)
assert(names == "Old Town,Dwarven District,Cathedral Square,The Park,Mage Quarter,Trade District",
    "the course passes the district gates in order: " .. names)
-- Nothing stands in Stormwind's street: the course runs past the
-- Cathedral's steps with Cathedral Square and its fountain beyond the far
-- wall, so the centerline never meets a wall.
assert(#stormwind.solids == 0 and #data.plazas == 0, "no solids or open plazas in Stormwind's street")
assert(walls == 0, "the course's centerline never meets a wall")

-- A short drive from the grid in Physics: full throttle up the Valley of
-- Heroes stays on the road and covers ground.
local state = Physics.new(stormwind)
for _=1,120 do
    state = Physics.step(state, {accelerate=true}, Physics.FIXED_DT, stormwind)
end
assert(state.surface == "road" and distance(state.x, state.y, spawn.x, spawn.y) > 150 and state.impacts == 0,
    "two seconds of throttle run cleanly up the approach")
-- Steering hard right into the Valley's wall: contact scrubs speed and the
-- kart stays inside the street.
for _=1,240 do
    state = Physics.step(state, {accelerate=true, right=true}, Physics.FIXED_DT, stormwind)
    assert(stormwind.surfaceAt(state.x, state.y) ~= "wall", "the kart never ends a step in a wall")
end
assert(state.impacts > 0, "the street's walls stop a kart that steers into them")

-- Ironforge: the spawn sits in the gate hall; the walk passes the seven
-- district gates in order, through the Great Forge, and never meets a wall
-- (no plazas or solids). Throttle from the grid stays on the road.
local ironforge = Courses.build("ironforge_gp", Track.crossesGate)
local ironData = namespace.CapitalCities.ironforge_gp
assert(ironforge and ironforge.wallRadius == 76 and #ironforge.gates == 7 and #ironforge.solids == 0
    and #ironData.plazas == 0, "Ironforge's street: the same road and walls, seven gates, nothing in the way")
local ironNames, ironWalls = walk(ironforge, ironData)
assert(ironNames == "Mystic Ward,Forlorn Cavern,Hall of Explorers,Great Forge,Tinker Town,Military Ward,The Commons",
    "Ironforge's gates in order: " .. ironNames)
assert(ironWalls == 0, "Ironforge's centerline never meets a wall")
local iron = Physics.new(ironforge)
for _=1,90 do
    iron = Physics.step(iron, {accelerate=true}, Physics.FIXED_DT, ironforge)
end
assert(iron.surface == "road" and iron.impacts == 0, "throttle from Ironforge's grid stays on the road")
print(("circuit: street walls, plazas and solids; Stormwind %d-unit loop, %d gates in order; "
    .. "Ironforge %d-unit loop, %d gates in order; %d solids")
    :format(math.floor(stormwind.length + 0.5), #stormwind.gates, math.floor(ironforge.length + 0.5),
        #ironforge.gates, #stormwind.solids + #ironforge.solids))
