local beforeGlobal = _G.AzerothKart
local P = dofile("addon/AzerothKart/Presentation.lua")
local pi, tau = math.pi, 2 * math.pi
local function near(actual, expected, message)
    assert(math.abs(actual - expected) < 1e-10, message)
end

local square = P.fitViewport(1024,1024,800,480)
assert(square.scale==0.46875 and square.offsetX==160 and square.offsetY==0
       and square.width==480 and square.height==480, "square world is centered without stretching")
assert(square.worldWidth==1024 and square.worldHeight==1024 and
       square.canvasWidth==800 and square.canvasHeight==480, "viewport retains its source dimensions")
assert(P.fitViewport(1024,1024,800,480)~=square, "viewport factory returns a fresh value")
local snapshotView = {}
for key,value in pairs(square) do snapshotView[key]=value end
local function projected(view,x,y,expectedX,expectedY,label)
    local px,py = P.project(view,x,y)
    near(px,expectedX,label.." x")
    near(py,expectedY,label.." y")
    local wx,wy = P.unproject(view,px,py)
    near(wx,x,label.." round-trip x")
    near(wy,y,label.." round-trip y")
end
projected(square,0,0,160,0,"square bottom-left")
projected(square,1024,1024,640,480,"square top-right")
projected(square,512,512,400,240,"square center")
projected(square,-512,1536,-80,720,"outside world remains unclamped")
local outsideX,outsideY = P.unproject(square,40,-120)
assert(outsideX==-256 and outsideY==-256, "letterbox and outside canvas coordinates stay unclamped")
local landscape = P.fitViewport(1600,400,800,480)
assert(landscape.scale==0.5 and landscape.offsetX==0 and landscape.offsetY==140
       and landscape.width==800 and landscape.height==200, "landscape world is letterboxed vertically")
projected(landscape,1600,400,800,340,"landscape top-right")
local portrait = P.fitViewport(400,1600,800,480)
assert(portrait.scale==0.3 and portrait.offsetX==340 and portrait.offsetY==0
       and portrait.width==120 and portrait.height==480, "portrait world is letterboxed horizontally")
projected(portrait,200,800,400,240,"portrait center")
assert(select("#",P.project(square,0,0))==2 and select("#",P.unproject(square,160,0))==2,
       "viewport mapping returns two scalars without allocating point tables")
for key,value in pairs(square) do assert(snapshotView[key]==value,"projection changed viewport "..key) end
for key,value in pairs(snapshotView) do assert(square[key]==value,"projection lost viewport "..key) end
for _,invalid in ipairs({false,"1024",0,-1,0/0,math.huge,-math.huge}) do
    assert(not pcall(P.fitViewport,invalid,1024,800,480), "invalid world width must reject")
    assert(not pcall(P.fitViewport,1024,invalid,800,480), "invalid world height must reject")
    assert(not pcall(P.fitViewport,1024,1024,invalid,480), "invalid canvas width must reject")
    assert(not pcall(P.fitViewport,1024,1024,800,invalid), "invalid canvas height must reject")
end
assert(not pcall(P.fitViewport,nil,1024,800,480), "missing dimensions must reject")
for _,map in ipairs({P.project,P.unproject}) do
    for _,invalid in ipairs({false,"1024",0/0,math.huge,-math.huge}) do
        assert(not pcall(map,square,invalid,0) and not pcall(map,square,0,invalid),
            "mapping rejects nonfinite or nonnumeric coordinates")
    end
    assert(not pcall(map,nil,0,0) and not pcall(map,square,nil,0),
        "mapping requires a viewport and both coordinates")
    for _,view in ipairs({{}, {scale=0,offsetX=0,offsetY=0},
        {scale=math.huge,offsetX=0,offsetY=0}, {scale=1,offsetX=0/0,offsetY=0},
        {scale=1,offsetX=0,offsetY=math.huge}}) do
        assert(not pcall(map,view,0,0), "mapping rejects invalid transforms")
    end
end
assert(not pcall(P.fitViewport,1e-308,1e-308,1e308,1e308)
       and not pcall(P.fitViewport,1e308,1e308,1e-308,1e-308),
       "unrepresentable viewport scales cannot produce poisoned transforms")
assert(not pcall(P.project,{scale=2,offsetX=0,offsetY=0},1e308,0)
       and not pcall(P.unproject,{scale=0.1,offsetX=0,offsetY=0},1e308,0),
       "unrepresentable mapped coordinates must reject")

local function pose(previous, current, alpha, x, y, heading, message)
    local px, py, ph = P.pose(previous, current, alpha)
    near(px, x, message .. " x")
    near(py, y, message .. " y")
    near(ph, heading, message .. " heading")
end

local marker = {}
local previous = {x=-10, y=8, heading=0.2, tick=19, marker=marker}
local current = {x=30, y=-12, heading=0.8, tick=20, marker=marker}
pose(previous, current, 0.5, 10, -2, 0.5, "midpoint")
pose(previous, current, 0.25, 0, 3, 0.35, "quarter tick")
pose(previous, current, 0, previous.x, previous.y, previous.heading, "previous endpoint")
pose(previous, current, 1, current.x, current.y, current.heading, "current endpoint")
pose(previous, current, -100, previous.x, previous.y, previous.heading, "negative clamp")
pose(previous, current, 100, current.x, current.y, current.heading, "positive clamp")
pose(previous, current, -math.huge, previous.x, previous.y, previous.heading, "negative infinity")
pose(previous, current, math.huge, current.x, current.y, current.heading, "positive infinity")
pose(previous, current, nil, current.x, current.y, current.heading, "default latest")
pose(previous, current, 0/0, current.x, current.y, current.heading, "NaN latest")
pose(previous, current, false, current.x, current.y, current.heading, "boolean latest")
pose(previous, current, "0.5", current.x, current.y, current.heading, "string latest")
pose(nil, current, 0, current.x, current.y, current.heading, "missing previous")
assert(not pcall(P.pose, previous, nil, 0.5), "current pose is required")

local nearEnd = {x=0, y=0, heading=tau - 0.1}
local nearStart = {x=2, y=4, heading=0.1}
pose(nearEnd, nearStart, 0.5, 1, 2, tau, "forward across zero")
pose(nearStart, nearEnd, 0.5, 1, 2, 0, "reverse across zero")
local wrappedX, wrappedY, wrappedHeading = P.pose(nearEnd, nearStart, 1)
assert(wrappedX == nearStart.x and wrappedY == nearStart.y and wrappedHeading == nearStart.heading,
       "current endpoint preserves the exact raw heading after wrap")
local _, _, previousHeading = P.pose(nearStart, nearEnd, 0)
assert(previousHeading == nearStart.heading, "previous endpoint preserves exact raw heading")
local manyTurns = {x=4, y=8, heading=40 * tau + 0.1}
local negativeTurns = {x=8, y=12, heading=-30 * tau + 0.3}
pose(manyTurns, negativeTurns, 0.5, 6, 10, 40 * tau + 0.2, "unbounded headings")
local _, _, rawHeading = P.pose(manyTurns, negativeTurns, 1)
assert(rawHeading == negativeTurns.heading, "latest endpoint never normalizes physics heading")
pose({x=0, y=0, heading=0}, {x=0, y=0, heading=pi}, 0.5,
     0, 0, -pi/2, "half-turn tie is deterministic")

assert(previous.x == -10 and previous.y == 8 and previous.heading == 0.2 and
       previous.tick == 19 and previous.marker == marker, "previous simulation state stays unchanged")
assert(current.x == 30 and current.y == -12 and current.heading == 0.8 and
       current.tick == 20 and current.marker == marker, "current simulation state stays unchanged")
assert(select("#", P.pose(previous, current, 0.5)) == 3,
       "render pose returns exactly three scalars")

local config = dofile("addon/AzerothKart/Physics.lua")
local state = {surface="road", drifting=true, driftTicks=29, driftTier=2, boostTicks=0, driftGraceTicks=0}
local function meter(ticks, fraction, phase)
    state.driftTicks = ticks
    local actualFraction, actualPhase = P.meter(state, config)
    near(actualFraction, fraction, "meter fraction at " .. ticks)
    assert(actualPhase == phase, "meter phase at " .. ticks)
end
-- Read actual ticks rather than a possibly stale/inconsistent driftTier.
meter(0, 0, "idle")
meter(29, 29/60, "charging")
meter(30, 30/60, "tier1")
meter(59, 59/60, "tier1")
meter(60, 1, "tier2")
meter(500, 1, "tier2")
state.driftGraceTicks = 1
meter(30, 0.5, "holding")
state.driftGraceTicks = 12
meter(60, 1, "holding")
state.driftGraceTicks = 0
state.drifting = false
meter(60, 0, "idle")
for _, remaining in ipairs({29, 47, 48, 100}) do
    state.boostTicks = remaining
    local fraction, phase = P.meter(state, config)
    near(fraction, math.min(1, remaining/48), "shared boost capacity")
    assert(phase == "boost", "boost takes precedence over charge")
end
state.boostTicks = 0
meter(60, 0, "idle")
for _, surface in ipairs({"grass", "wall"}) do
    state.surface, state.drifting, state.boostTicks = surface, true, 47
    local fraction, phase = P.meter(state, config)
    assert(fraction == 0 and phase == "idle", "surface cancellation clears the meter")
end
local track = dofile("addon/AzerothKart/Track.lua")
local freshState = config.new(track)
local fraction, phase = P.meter(freshState, config)
assert(fraction == 0 and phase == "idle", "fresh drive starts with an empty meter")
state.surface = "road"
local snapshot = {}
for key, value in pairs(state) do snapshot[key] = value end
assert(select("#", P.meter(state, config)) == 2, "meter returns exactly two scalars")
for key, value in pairs(state) do assert(snapshot[key] == value, "meter preserves state") end
for key, value in pairs(snapshot) do assert(state[key] == value, "meter retains every state field") end
assert(config.DRIFT_TIER1_TICKS == 30 and config.DRIFT_TIER2_TICKS == 60
       and config.BOOST_TIER2_TICKS == 48, "meter preserves injected configuration")

assert(_G.AzerothKart == beforeGlobal, "offline import must not create or replace an addon global")
local namespace = {sentinel=marker}
local loaded = assert(loadfile("addon/AzerothKart/Presentation.lua"))("AzerothKart", namespace)
assert(namespace.Presentation == loaded and namespace.sentinel == marker,
       "addon import registers with its explicit namespace")
assert(_G.AzerothKart == beforeGlobal, "namespace import must not replace an addon global")
print("offline presentation: aspect-fit scalar mapping, poses, shortest-arc heading, drift/boost meter and untouched states")
