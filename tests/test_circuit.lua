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
local squareDefinition = {
    id="square", width=400, height=400, wallInset=6, roadRadius=20, wallRadius=30,
    centerline={{x=100,y=100}, {x=300,y=100}, {x=300,y=300}, {x=100,y=300}},
    gates={{name="East", ax=270, ay=200, bx=330, by=200, nx=0, ny=1},
           {name="Start", ax=70, ay=200, bx=130, by=200, nx=0, ny=-1}},
    plazas={{ax=200, ay=300, bx=200, by=300, radius=60}},
    solids={{id="statue", x=190, y=320, width=20, height=10}},
    spawn={x=200, y=100, heading=0},
}
local square = Circuit.new(squareDefinition, Track.crossesGate)

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

-- Full street grip is opt-in and does not change geometry or wall response.
local fastDefinition = {}
for key,value in pairs(squareDefinition) do fastDefinition[key] = value end
fastDefinition.fullSpeedToWalls = true
local fastStreet = Circuit.new(fastDefinition, Track.crossesGate)
assert(square.surfaceAt(200,125) == "grass" and not square.fullSpeedToWalls,
    "the default circuit still slows on its shoulder")
assert(fastStreet.surfaceAt(200,125) == "road" and fastStreet.isDrivable(200,125) and
       fastStreet.surfaceAt(200,135) == "wall", "full road grip extends to the existing wall")
local fx,fy,fh = fastStreet.resolveMovement(200,129,204,133)
local sx,sy,sh = square.resolveMovement(200,129,204,133)
assert(fx == sx and fy == sy and fh == sh, "surface policy does not move or weaken walls")
for _,mode in ipairs({"throttle", "boost", "release", "drift"}) do
    local middle,edge = Physics.new(fastStreet),Physics.new(fastStreet)
    middle.x,middle.y,middle.heading,middle.speed = 150,100,0,Physics.MAX_SPEED
    edge.x,edge.y,edge.heading,edge.speed = 150,125,0,Physics.MAX_SPEED
    local input = {accelerate=true}
    for _,state in ipairs({middle,edge}) do
        if mode == "boost" then state.boostTicks = 20
        elseif mode == "release" then
            state.drifting,state.driftDirection,state.driftTicks,state.driftTier = true,1,30,1
        end
    end
    if mode == "drift" then input.drift,input.left = true,true end
    for _=1,10 do
        middle = Physics.step(middle,input,Physics.FIXED_DT,fastStreet)
        edge = Physics.step(edge,input,Physics.FIXED_DT,fastStreet)
        assert(middle.impacts == 0 and edge.impacts == 0 and edge.surface == "road",
            "the shoulder comparison stays clear of walls: " .. mode)
        for key,value in pairs(middle) do
            if key == "y" then assert(near(edge.y,value+25), "only the lane offset differs")
            elseif type(value) == "number" then assert(near(edge[key],value), "shoulder handling matches: " .. key)
            else assert(edge[key] == value, "shoulder handling matches: " .. key) end
        end
    end
    assert(edge.speed >= Physics.MAX_SPEED, "the street shoulder never applies rough drag: " .. mode)
    if mode == "boost" or mode == "release" then assert(edge.boostTicks > 0, "shoulder retains boost") end
    if mode == "drift" then assert(edge.drifting and edge.driftTicks > 0, "shoulder builds drift") end
end

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
assert(soon == 5 and Courses.available("stormwind_city"), "Stormwind is ready; five cities are coming")
assert(Courses.next("test_oval") == "mirage_raceway" and Courses.next("mirage_raceway") == "stormwind_city"
    and Courses.next("stormwind_city") == "test_oval", "the Track button cycles the ready tracks")
assert(Courses.build("test_oval", Track.crossesGate) == Track, "the oval is the original track")
local stormwind = Courses.build("stormwind_city", Track.crossesGate)
assert(stormwind and Courses.build("stormwind_city", Track.crossesGate) == stormwind, "built once, kept")

-- Stormwind: the spawn sits on the Valley of Heroes road; a walk of the
-- course (the approach, then the loop and back to the gate) passes the six
-- district gates in order and completes the lap's checkpoints.
local data = namespace.CapitalCities.stormwind_city
assert(stormwind.wallRadius == 76 and stormwind.roadRadius == 56 and #stormwind.gates == 6,
    "Stormwind keeps its painted street and existing wall geometry")
assert(stormwind.version == 2 and stormwind.fullSpeedToWalls and data.fullSpeedToWalls,
    "Stormwind v2 opts into full grip up to its walls")
-- A real authored shoulder point is road; the original policy remains rough.
local oldDefinition = {}
for key,value in pairs(data) do oldDefinition[key] = value end
oldDefinition.fullSpeedToWalls = false
local oldStreet = Circuit.new(oldDefinition, Track.crossesGate)
local shoulders = 0
for index=2,#data.branches[1] do
    local a,b = data.branches[1][index-1],data.branches[1][index]
    local dx,dy = b.x-a.x,b.y-a.y
    local length = math.sqrt(dx*dx+dy*dy)
    if length > 0 then
        for _,sign in ipairs({-1,1}) do
            local px,py = (a.x+b.x)/2-sign*dy/length*66,(a.y+b.y)/2+sign*dx/length*66
            if oldStreet.surfaceAt(px,py) == "grass" then
                shoulders = shoulders+1
                assert(stormwind.surfaceAt(px,py) == "road" and stormwind.isDrivable(px,py),
                    "Stormwind's former rough shoulder now has road handling")
            end
        end
    end
end
assert(shoulders > 0, "authored Stormwind shoulder points were checked")
local spawn = stormwind.spawn()
assert(stormwind.surfaceAt(spawn.x, spawn.y) == "road", "the start grid is on the road")
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
local progress = Checkpoints.new(stormwind, 0)
local previous = {x=spawn.x, y=spawn.y, tick=0}
local names, walls = {}, 0
for index=start + 1,#path do
    local target = path[index]
    local steps = math.max(1, math.ceil(distance(previous.x, previous.y, target.x, target.y) / 4))
    local fromX, fromY = previous.x, previous.y
    for k=1,steps do
        local px = fromX + (target.x - fromX) * k / steps
        local py = fromY + (target.y - fromY) * k / steps
        if stormwind.surfaceAt(px, py) == "wall" then walls = walls + 1 end
        local current = {x=px, y=py, tick=previous.tick + 1}
        local before = progress.passed
        progress = Checkpoints.step(progress, previous, current, stormwind)
        if progress.passed > before then names[#names + 1] = stormwind.gates[progress.passed].name end
        previous = current
    end
    if progress.complete then break end
end
assert(progress.complete and table.concat(names, ",") ==
    "Old Town,Dwarven District,Cathedral Square,The Park,Mage Quarter,Trade District",
    "the course passes the district gates in order: " .. table.concat(names, ","))
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
print(("circuit: street walls, plazas and solids; Stormwind %d-unit loop, %d gates in order; %d solids")
    :format(math.floor(stormwind.length + 0.5), #stormwind.gates, #stormwind.solids))
