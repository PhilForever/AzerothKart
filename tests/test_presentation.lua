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

local camera = P.cameraViewport(1024,1024,800,480,1.5)
assert(camera.scale==1.5 and camera.width==800 and camera.height==480
       and camera.follow==true, "close camera fills the full landscape canvas uniformly")
near(camera.viewWidth,800/1.5,"camera visible world width")
near(camera.viewHeight,320,"camera visible world height")
assert(P.cameraViewport(1024,1024,800,480).scale==1.5,"close camera has a deliberate default zoom")
local cameraBefore = {}
for key,value in pairs(camera) do cameraBefore[key]=value end
assert(P.follow(camera,700,360,pi/2)==camera,"follow reuses the same viewport")
projected(camera,700,360,400,150,"Mirage start has forward road space")
near(112*camera.scale,168,"Mirage road is 168 canvas units wide")
near(17*camera.scale,25.5,"placeholder kart is readable at the close camera scale")
for key,value in pairs(cameraBefore) do
    if key~="offsetX" and key~="offsetY" then
        assert(camera[key]==value,"follow only changes presentation offsets: "..key)
    end
end
local function crop(view,left,right,top,bottom,label)
    local l,r,t,b = P.texCoords(view)
    near(l,left,label.." left"); near(r,right,label.." right")
    near(t,top,label.." top"); near(b,bottom,label.." bottom")
    assert(l>=0 and r<=1 and t>=0 and b<=1 and l<r and t<b,
        label.." stays inside the image with upright UV ordering")
end
local spawnLeft,spawnBottom = P.unproject(camera,0,0)
crop(camera,spawnLeft/1024,(spawnLeft+800/1.5)/1024,
    1-(spawnBottom+320)/1024,1-spawnBottom/1024,"spawn crop")
assert(select("#",P.texCoords(camera))==4,"camera crop returns four scalars")
local offsetX,offsetY = camera.offsetX,camera.offsetY
P.texCoords(camera)
assert(camera.offsetX==offsetX and camera.offsetY==offsetY,"UV lookup does not move the camera")
P.follow(camera,0,0,pi)
assert(camera.offsetX==0 and camera.offsetY==0,"lookahead clamps at the bottom-left world edge")
crop(camera,0,(800/1.5)/1024,1-320/1024,1,"bottom-left crop")
P.follow(camera,1024,1024,0)
near(camera.offsetX,800-1024*1.5,"right-edge camera clamp")
near(camera.offsetY,480-1024*1.5,"top-edge camera clamp")
crop(camera,1-(800/1.5)/1024,1,0,320/1024,"top-right crop")
local covered = P.cameraViewport(1024,1024,800,480,0.1)
assert(covered.scale==800/1024,"too-wide requested view clamps to cover the canvas")
P.follow(covered,0,1024,pi/2)
crop(covered,0,1,0,480/800,"cover zoom has no side margins or out-of-world UVs")
P.follow(camera,700,360,pi/2,0)
projected(camera,700,360,400,240,"zero lookahead centers the kart")
P.follow(camera,600,360,0)
projected(camera,600,360,310,240,"heading changes shift visible road ahead without rotating art")

P.follow(camera,512,512,0,0)
local left,bottom = P.unproject(camera,0,0)
local function clipped(x,y,width,height,expectedX,expectedY,expectedW,expectedH,label)
    local px,py,w,h = P.clipRect(camera,x,y,width,height)
    near(px,expectedX,label.." x"); near(py,expectedY,label.." y")
    near(w,expectedW,label.." width"); near(h,expectedH,label.." height")
end
clipped(left+10,bottom+20,112,2,15,30,168,3,"fully visible gate")
clipped(left-10,bottom+10,20,20,0,15,15,30,"left-edge gate fragment")
clipped(left+10,bottom+310,20,20,15,465,30,15,"top-edge wall fragment")
clipped(left-10,bottom-10,1000,1000,0,0,800,480,"rectangle covering the camera")
assert(P.clipRect(camera,left-20,bottom,10,10)==nil
       and P.clipRect(camera,left,bottom-20,10,10)==nil,
       "offscreen regions hide instead of leaking onto other UI")
assert(P.clipRect(camera,left-10,bottom,10,10)==nil
       and P.clipRect(camera,left,bottom,0,10)==nil,
       "edge-only or empty rectangles have no visible fragment")
assert(select("#",P.clipRect(camera,left,bottom,20,20))==4,
       "clipping returns scalar dimensions without allocating rectangles")
local cameraKeys = {}
for key,value in pairs(camera) do cameraKeys[key]=value end
P.clipRect(camera,left-10,bottom,20,20)
P.texCoords(camera)
for key,value in pairs(cameraKeys) do assert(camera[key]==value,"crop/clip keeps the camera unchanged") end
for _,invalid in ipairs({false,"1.5",0,-1,0/0,math.huge,-math.huge}) do
    assert(not pcall(P.cameraViewport,1024,1024,800,480,invalid),"invalid zoom rejects")
end
assert(not pcall(P.cameraViewport,0,1024,800,480)
       and not pcall(P.cameraViewport,1024,1024,0,480),"invalid camera dimensions reject")
assert(not pcall(P.follow,square,0,0,0)
       and not pcall(P.texCoords,square),"an overview cannot accidentally use follow-camera UVs")
assert(not pcall(P.follow,camera,0/0,0,0)
       and not pcall(P.follow,camera,0,0,math.huge)
       and not pcall(P.follow,camera,0,0,0,-1),"invalid camera target/lookahead rejects")
assert(not pcall(P.clipRect,camera,0,0,-1,20)
       and not pcall(P.clipRect,camera,0,0,20,math.huge),"invalid rectangle dimensions reject")

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
print("offline presentation: close follow camera/cropped UVs/marker clipping, aspect-fit mapping, poses and drift meter")
