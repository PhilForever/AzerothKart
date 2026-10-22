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

-- Reviewed narrows (Ironforge v3): loop segments walled at their own
-- smaller radius and paved no further, so no rough strip; elsewhere the
-- street is unchanged. The square's south side (segment 1) narrows to 15.
local narrowDefinition = {}
for key,value in pairs(squareDefinition) do narrowDefinition[key] = value end
narrowDefinition.narrows = {{name="South", first=1, last=1, wallRadius=15}}
local narrowStreet = Circuit.new(narrowDefinition, Track.crossesGate)
assert(narrowStreet.surfaceAt(200,100) == "road" and narrowStreet.surfaceAt(200,114) == "road" and
       narrowStreet.isDrivable(200,114) and narrowStreet.surfaceAt(200,116) == "wall" and
       narrowStreet.surfaceAt(200,84) == "wall",
    "a narrows is road up to its own wall, with no rough strip")
assert(narrowStreet.surfaceAt(300,200) == "road" and narrowStreet.surfaceAt(325,200) == "grass" and
       narrowStreet.surfaceAt(335,200) == "wall", "the rest of the street keeps its shoulder and walls")
assert(#narrowStreet.narrows == 1 and narrowStreet.narrows[1].wallRadius == 15 and #square.narrows == 0,
    "the narrows are part of the track's copied definition")
x, y, hit = narrowStreet.resolveMovement(200,113,200,118)
assert(hit and near(y,115,0.01) and narrowStreet.surfaceAt(x,y) == "road", "the narrows' wall stops a kart")
x, y, hit = narrowStreet.resolveMovement(150,100,154,101)
assert(not hit and x == 154 and y == 101, "free movement inside a narrows is exact")
local shoulderNarrowDefinition = {}
for key,value in pairs(squareDefinition) do shoulderNarrowDefinition[key] = value end
shoulderNarrowDefinition.narrows = {{first=1,last=1,wallRadius=25}}
local shoulderNarrow = Circuit.new(shoulderNarrowDefinition, Track.crossesGate)
assert(shoulderNarrow.surfaceAt(200,119) == "road" and
       shoulderNarrow.surfaceAt(200,124) == "grass" and
       shoulderNarrow.surfaceAt(200,126) == "wall",
    "a narrows wider than the paving retains its smaller rough shoulder")

-- The closing segment joins point n back to point 1. Overlaps use the
-- smaller radius regardless of declaration order; open branches stay wide.
local closingDefinition = {}
for key,value in pairs(squareDefinition) do closingDefinition[key] = value end
closingDefinition.narrows = {{name="West",first=4,last=4,wallRadius=18},
                            {name="West tight",first=4,last=4,wallRadius=12}}
closingDefinition.branches = {{{x=100,y=250},{x=40,y=250}}}
local closingStreet = Circuit.new(closingDefinition, Track.crossesGate)
closingDefinition.narrows = {closingDefinition.narrows[2],closingDefinition.narrows[1]}
local reversedStreet = Circuit.new(closingDefinition, Track.crossesGate)
for _,street in ipairs({closingStreet,reversedStreet}) do
    assert(street.surfaceAt(111,150) == "road" and street.surfaceAt(113,150) == "wall" and
           street.surfaceAt(87,150) == "wall", "the closing segment uses the smallest overlapping radius")
    assert(street.surfaceAt(200,125) == "grass", "narrowing the closing segment leaves segment 1 unchanged")
    assert(street.surfaceAt(40,275) == "grass" and street.surfaceAt(40,285) == "wall",
        "narrows do not change an open branch's shoulder or wall")
end
closingDefinition.narrows[1].wallRadius = 30
assert(closingStreet.narrows[2].wallRadius == 12, "track narrows do not alias the source entries")
closingStreet.narrows[1].wallRadius = 30
assert(closingDefinition.narrows[2].wallRadius == 18, "source entries do not alias track metadata")
assert(closingStreet.surfaceAt(113,150) == "wall", "changing copied metadata does not mutate built collision")

for _,bad in ipairs({{first=0,last=1,wallRadius=15}, {first=2,last=1,wallRadius=15},
                     {first=1,last=5,wallRadius=15}, {first=1,last=1,wallRadius=31},
                     {first=1,last=1,wallRadius=0}, {first=1.5,last=2,wallRadius=15}}) do
    local definition = {}
    for key,value in pairs(squareDefinition) do definition[key] = value end
    definition.narrows = {bad}
    assert(not pcall(Circuit.new, definition, Track.crossesGate), "an invalid narrows is refused")
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
assert(soon == 3 and Courses.available("stormwind_city") and Courses.available("ironforge_gp")
    and Courses.available("orgrimmar_canyon"), "Stormwind, Ironforge and Orgrimmar are ready; three cities are coming")
assert(Courses.next("test_oval") == "mirage_raceway" and Courses.next("mirage_raceway") == "stormwind_city"
    and Courses.next("stormwind_city") == "ironforge_gp" and Courses.next("ironforge_gp") == "orgrimmar_canyon"
    and Courses.next("orgrimmar_canyon") == "test_oval", "the Track button cycles the ready tracks")
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
    "Stormwind keeps its painted street and existing wall geometry")
assert(stormwind.version == 3 and stormwind.fullSpeedToWalls and data.fullSpeedToWalls,
    "Stormwind v3 retains full grip up to its painted walls")
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
-- Reported Park/Mage corner: shrinking each visual capsule separately
-- created an invisible V across this paved wedge. Clearance is measured
-- from the exposed union boundary, including its concave apex.
assert(stormwind.wallClearance == 14 and #data.wallVertices > 0,
    "Stormwind supplies analytic exposed-wall junctions and kart clearance")
assert(stormwind.surfaceAt(450,850) == "road", "the reported paved wedge is open street")
local px,py,contact = stormwind.resolveMovement(442,849,445,846)
assert(px == 445 and py == 846 and not contact,
    "driving forward through the reported corner is exact and does not stick")
local apexX,apexY = 476.2652153292576,866.3694266226744
local ux,uy = 450-apexX,850-apexY
local normal = math.sqrt(ux*ux+uy*uy)
ux,uy = ux/normal,uy/normal
assert(stormwind.surfaceAt(apexX+ux*14.1,apexY+uy*14.1) == "road" and
       stormwind.surfaceAt(apexX+ux*13.9,apexY+uy*13.9) == "wall",
    "the kart stops at body clearance from the white wall, not the invisible V")
local ax,ay = apexX+ux*14.2,apexY+uy*14.2
px,py,contact = stormwind.resolveMovement(ax,ay,apexX+ux*12,apexY+uy*12)
assert(contact and near(distance(px,py,apexX,apexY),14,0.01) and
       distance(ax,ay,px,py) <= 2.2+1e-6 and stormwind.surfaceAt(px,py) == "road",
    "a real white-wall contact keeps clearance and the requested movement bound")
-- A nearly tangential movement around the real concave corner also slides:
-- its unconstrained radial projection is outside the permitted step circle.
local slideX,slideY,targetX,targetY = 463.107639253,861.580460576,465.908781114,858.511674377
local requested = distance(slideX,slideY,targetX,targetY)
px,py,contact = stormwind.resolveMovement(slideX,slideY,targetX,targetY)
assert(contact and distance(slideX,slideY,px,py) > 1 and
       distance(slideX,slideY,px,py) <= requested+1e-9 and
       distance(px,py,apexX,apexY) >= 14 and stormwind.surfaceAt(px,py) == "road",
    "a reachable bounded slide around the white corner cannot freeze at its start")
-- Straight walls keep their existing clearance: no global radius increase.
local a,b = data.branches[1][1],data.branches[1][2]
local dx,dy = b.x-a.x,b.y-a.y
local length = math.sqrt(dx*dx+dy*dy)
local mx,my = (a.x+b.x)/2,(a.y+b.y)/2
assert(stormwind.surfaceAt(mx-dy/length*75,my+dx/length*75) == "road" and
       stormwind.surfaceAt(mx-dy/length*78,my+dx/length*78) == "wall",
    "straight walls still stop the kart centre near the original 76-unit reach")
-- The solver also considers another reachable projection for old definitions.
local legacyDefinition = {}
for key,value in pairs(data) do legacyDefinition[key] = value end
legacyDefinition.wallClearance,legacyDefinition.wallVertices = nil,nil
local legacy = Circuit.new(legacyDefinition,Track.crossesGate)
px,py,contact = legacy.resolveMovement(442,849,445,846)
assert(contact and distance(442,849,px,py) > 0.5 and
       distance(442,849,px,py) <= math.sqrt(18)+1e-6 and legacy.surfaceAt(px,py) ~= "wall",
    "a valid bounded slide is not discarded because a different projection is too far")
local drive = Physics.new(stormwind)
drive.x,drive.y,drive.heading,drive.speed = 442,849,-math.pi/4,Physics.MAX_SPEED
for _=1,10 do
    drive = Physics.step(drive,{accelerate=true},Physics.FIXED_DT,stormwind)
    assert(drive.impacts == 0 and near(drive.speed,Physics.MAX_SPEED),
        "a full-speed Physics drive crosses the reported corner without phantom impacts")
end
assert(distance(442,849,drive.x,drive.y) > 33, "the full-speed corner drive makes forward progress")

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
assert(ironforge.version == 3 and ironforge.wallClearance == 14 and #ironData.wallVertices > 0,
    "Ironforge v3 uses the existing exposed-wall clearance for its painted gate-hall junction")
assert(not ironforge.fullSpeedToWalls and not ironData.fullSpeedToWalls,
    "the Stormwind-only full-speed policy does not change Ironforge's rough shoulder")
local oldIronDefinition = {}
for key,value in pairs(ironData) do oldIronDefinition[key] = value end
oldIronDefinition.wallClearance,oldIronDefinition.wallVertices = nil,nil
local oldIron = Circuit.new(oldIronDefinition,Track.crossesGate)
assert(oldIron.surfaceAt(232,641) == "wall" and ironforge.surfaceAt(232,641) == "grass",
    "the gate-hall's painted corner is usable rough pavement, not an invisible wall")
local ironX,ironY,ironHit = ironforge.resolveMovement(234,641,232,641)
assert(ironX == 232 and ironY == 641 and not ironHit,
    "a normal bounded step through Ironforge's concave corner moves without phantom contact")
local ia,ib = ironData.branches[1][1],ironData.branches[1][2]
local idx,idy = ib.x-ia.x,ib.y-ia.y
local ilength = math.sqrt(idx*idx+idy*idy)
local imx,imy = (ia.x+ib.x)/2,(ia.y+ib.y)/2
assert(ironforge.surfaceAt(imx-idy/ilength*66,imy+idx/ilength*66) == "grass" and
       ironforge.surfaceAt(imx-idy/ilength*75,imy+idx/ilength*75) == "grass" and
       ironforge.surfaceAt(imx-idy/ilength*78,imy+idx/ilength*78) == "wall",
    "Ironforge keeps its rough shoulder and original clearance along a straight wall")
for _,gate in ipairs(ironforge.gates) do
    assert(ironforge.surfaceAt(gate.ax,gate.ay) == "wall" and
           ironforge.surfaceAt(gate.bx,gate.by) == "wall",
        "both ends still close the corrected street: " .. gate.name)
end
-- v3: the Forlorn Cavern's entrance and exit are narrows (the owner's
-- request): the wall stands at the paving's edge (56 painted, the kart
-- centre 14 inside it at 42), all road, no shoulder; beyond them the rough
-- shoulder and the 76-unit reach remain.
assert(#ironData.narrows == 2 and ironData.narrows[1].name == "Forlorn Cavern entrance" and
       ironData.narrows[2].name == "Forlorn Cavern exit", "Ironforge has its two Forlorn Cavern narrows")
local function across(index, offset)
    local line = ironData.centerline
    local a,b = line[index],line[index%#line+1]
    local dx,dy = b.x-a.x,b.y-a.y
    local length = math.sqrt(dx*dx+dy*dy)
    return (a.x+b.x)/2-dy/length*offset,(a.y+b.y)/2+dx/length*offset
end
for _,narrow in ipairs(ironData.narrows) do
    assert(narrow.wallRadius == 42, "the kart centre keeps a half-length inside the paving's edge")
    local middle = math.floor((narrow.first+narrow.last)/2)
    for _,side in ipairs({-1,1}) do
        assert(ironforge.surfaceAt(across(middle,side*40)) == "road" and
               ironforge.isDrivable(across(middle,side*40)) and
               ironforge.surfaceAt(across(middle,side*44)) == "wall",
            "no shoulder in the " .. narrow.name)
        assert(ironforge.surfaceAt(across(narrow.first-12,side*66)) == "grass" and
               ironforge.surfaceAt(across(narrow.first-12,side*78)) == "wall",
            "the street before the " .. narrow.name .. " keeps its shoulder")
    end
end
-- The exposed-wall correction adds a thin safe arc beyond individually
-- shrunken capsules at concave joins. In a fully paved tunnel this must not
-- become an off-road pocket, while the exact same wall shape can retain a
-- shoulder when its paving is narrower than the narrows' radius.
local tunnelCornerX,tunnelCornerY = 790.1041330568827,1652.2604655230214
assert(ironforge.surfaceAt(tunnelCornerX,tunnelCornerY) == "road" and
       ironforge.isDrivable(tunnelCornerX,tunnelCornerY),
    "the entrance tunnel's exposed corner has no tiny rough pocket")
local roughTunnelDefinition = {}
for key,value in pairs(ironData) do roughTunnelDefinition[key] = value end
roughTunnelDefinition.roadRadius = 40
local roughTunnel = Circuit.new(roughTunnelDefinition, Track.crossesGate)
assert(roughTunnel.surfaceAt(tunnelCornerX,tunnelCornerY) == "grass" and
       not roughTunnel.isDrivable(tunnelCornerX,tunnelCornerY),
    "an exposed corner with narrower paving retains the default rough policy")
local tunnelVertexX,tunnelVertexY = 796.09033192,1639.60371143
local justOutsideX = tunnelVertexX+(tunnelCornerX-tunnelVertexX)*(13.999/14.001)
local justOutsideY = tunnelVertexY+(tunnelCornerY-tunnelVertexY)*(13.999/14.001)
assert(ironforge.surfaceAt(justOutsideX,justOutsideY) == "wall" and
       roughTunnel.surfaceAt(justOutsideX,justOutsideY) == "wall",
    "the tunnel corner's surface correction keeps the same wall clearance")
-- Steering hard into a narrows' wall: contact, and never a step into it.
local tunnel = Physics.new(ironforge)
local entry = ironData.narrows[1]
local ta,tb = ironData.centerline[entry.first],ironData.centerline[entry.first+1]
tunnel.x,tunnel.y,tunnel.heading = ta.x,ta.y,(math.atan2 or math.atan)(tb.y-ta.y,tb.x-ta.x)
for _=1,90 do
    tunnel = Physics.step(tunnel, {accelerate=true, right=true}, Physics.FIXED_DT, ironforge)
    assert(ironforge.surfaceAt(tunnel.x,tunnel.y) ~= "wall", "a kart never ends a step in the tunnel's wall")
end
assert(tunnel.impacts > 0, "the tunnel's wall stops a kart steering into it")
local ironNames, ironWalls = walk(ironforge, ironData)
assert(ironNames == "Mystic Ward,Forlorn Cavern,Hall of Explorers,Great Forge,Tinker Town,Military Ward,The Commons",
    "Ironforge's gates in order: " .. ironNames)
assert(ironWalls == 0, "Ironforge's centerline never meets a wall")
local iron = Physics.new(ironforge)
for _=1,90 do
    iron = Physics.step(iron, {accelerate=true}, Physics.FIXED_DT, ironforge)
end
assert(iron.surface == "road" and iron.impacts == 0, "throttle from Ironforge's grid stays on the road")

-- Orgrimmar: the spawn sits on the canyon road behind the city gate; the
-- walk joins the loop in the Valley of Strength and passes the four
-- district gates in order round the Cleft of Shadow, never meeting a wall.
-- Full grip to the street walls, as in Stormwind. Throttle from the grid
-- stays on the road.
local orgrimmar = Courses.build("orgrimmar_canyon", Track.crossesGate)
local orcData = namespace.CapitalCities.orgrimmar_canyon
assert(orgrimmar and orgrimmar.wallRadius == 76 and #orgrimmar.gates == 4 and #orgrimmar.solids == 0
    and #orcData.plazas == 0 and #orcData.branches == 1, "Orgrimmar's street: the same road and walls, four gates")
assert(orgrimmar.version == 1 and orgrimmar.wallClearance == 14 and #orcData.wallVertices > 0
    and orgrimmar.fullSpeedToWalls and orcData.fullSpeedToWalls,
    "Orgrimmar uses the exposed-wall clearance and full grip to the walls")
local orcNames, orcWalls = walk(orgrimmar, orcData)
assert(orcNames == "The Drag,Valley of Wisdom,Cleft of Shadow,Valley of Strength",
    "Orgrimmar's gates in order: " .. orcNames)
assert(orcWalls == 0, "Orgrimmar's centerline never meets a wall")
for _,gate in ipairs(orgrimmar.gates) do
    assert(orgrimmar.surfaceAt(gate.ax,gate.ay) == "wall" and orgrimmar.surfaceAt(gate.bx,gate.by) == "wall",
        "both ends of a gate close the street: " .. gate.name)
end
local orc = Physics.new(orgrimmar)
for _=1,90 do
    orc = Physics.step(orc, {accelerate=true}, Physics.FIXED_DT, orgrimmar)
end
assert(orc.surface == "road" and orc.impacts == 0, "throttle from Orgrimmar's grid stays on the road")
print(("circuit: street walls, plazas and solids; Stormwind %d-unit loop, %d gates in order; "
    .. "Ironforge %d-unit loop, %d gates in order; Orgrimmar %d-unit loop, %d gates in order; %d solids")
    :format(math.floor(stormwind.length + 0.5), #stormwind.gates, math.floor(ironforge.length + 0.5),
        #ironforge.gates, math.floor(orgrimmar.length + 0.5), #orgrimmar.gates,
        #stormwind.solids + #ironforge.solids + #orgrimmar.solids))
