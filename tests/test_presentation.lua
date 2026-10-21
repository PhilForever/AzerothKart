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

-- Kart sprite registry and the shipped TGA bytes. This checks the packaging
-- contract and offline alpha only; client loading, filtering and facing are
-- separate in-game checks.
assert(P.KART_FOOTPRINT_WIDTH == 17 and P.KART_FOOTPRINT_HEIGHT == 31,
       "sprite body matches the primitive footprint and the 18-unit wall clearance")
near(P.KART_FOOTPRINT_WIDTH * camera.scale, 25.5, "sprite body width at the close camera")
assert(type(P.KART_SPRITES[P.DEFAULT_KART]) == "table", "the default kart sprite is registered")
local function powerOfTwo(value)
    if type(value) ~= "number" or value < 1 or value % 1 ~= 0 then return false end
    while value > 1 do
        if value % 2 ~= 0 then return false end
        value = value / 2
    end
    return true
end
local addonPrefix = "Interface\\AddOns\\AzerothKart\\"
local spriteFiles = 0
local coverageFloors = {goblin_mortar_trike=0.12, steam_tank=0.12,
    dwarven_biker=0.12, gryphon_rider=0.08, gyrocopter=0.06}
for id, sprite in pairs(P.KART_SPRITES) do
    local w, h = sprite.textureWidth, sprite.textureHeight
    assert(type(sprite.path) == "string" and sprite.path:sub(1, #addonPrefix) == addonPrefix
           and sprite.path:find("\\Assets\\Karts\\[%w]+%.tga$"), id .. ": addon kart TGA path")
    assert(powerOfTwo(w) and powerOfTwo(h), id .. ": power-of-two texture")
    assert(w * sprite.quadHeight == h * sprite.quadWidth, id .. ": square texels in world units")
    assert(sprite.quadWidth >= P.KART_FOOTPRINT_WIDTH and sprite.quadHeight >= P.KART_FOOTPRINT_HEIGHT,
           id .. ": quad pads the body rather than cropping it")
    local file = assert(io.open("addon/AzerothKart/" .. (sprite.path:sub(#addonPrefix + 1):gsub("\\", "/")),
                                "rb"), id .. ": declared sprite file exists in the addon")
    local data = file:read("*a")
    file:close()
    local function u16(index) return data:byte(index) + 256 * data:byte(index + 1) end
    assert(data:byte(1) == 0 and data:byte(2) == 0 and data:byte(3) == 2 and u16(13) == w
           and u16(15) == h and data:byte(17) == 32 and data:byte(18) == 8,
           id .. ": uncompressed BGRA32, eight alpha bits, bottom-left origin")
    assert(#data == 18 + w * h * 4, id .. ": exact payload size")
    local function alpha(column, rowFromTop)
        return data:byte(18 + ((h - 1 - rowFromTop) * w + column) * 4 + 4)
    end
    if sprite.frames then
        -- Directional sheet: an even grid of square frames, each with a
        -- transparent border so filtering never pulls in a neighbor, a
        -- substantial vehicle, and distinct pictures for opposite headings.
        local columns, frames = sprite.columns, sprite.frames
        local rows = frames / columns
        assert(frames % columns == 0 and w % columns == 0 and h % rows == 0, id .. ": even frame grid")
        local fw, fh = w / columns, h / rows
        assert(fw == fh and fw / sprite.quadWidth == fh / sprite.quadHeight, id .. ": square frames and texels")
        assert(type(sprite.pivotX) == "number" and type(sprite.pivotY) == "number", id .. ": frame pivot")
        local fewest, most = fw * fh, 0
        for frame = 0, frames - 1 do
            local ox, oy = (frame % columns) * fw, math.floor(frame / columns) * fh
            local solid = 0
            for row = 0, fh - 1 do
                for column = 0, fw - 1 do
                    local a = alpha(ox + column, oy + row)
                    if row == 0 or column == 0 or row == fh - 1 or column == fw - 1 then
                        assert(a == 0, id .. ": frame " .. frame .. " keeps a transparent border")
                    end
                    if a == 255 then solid = solid + 1 end
                end
            end
            -- Thin flyers have explicit lower floors; ground kart coverage
            -- must not regress when a new aircraft is registered.
            local floor = assert(coverageFloors[id], id .. ": directional coverage floor declared")
            assert(solid > floor * fw * fh, id .. ": frame " .. frame .. " shows the vehicle")
            fewest, most = math.min(fewest, solid), math.max(most, solid)
            local l, r, top, b = P.kartFrameCoords(sprite, frame)
            assert(math.abs(l - ox / w) < 1e-12 and math.abs(r - (ox + fw) / w) < 1e-12 and
                   math.abs(top - oy / h) < 1e-12 and math.abs(b - (oy + fh) / h) < 1e-12,
                   id .. ": frame " .. frame .. " crop matches the sheet layout")
        end
        for frame = 0, frames / 2 - 1 do
            local other = frame + frames / 2
            local ox, oy = (frame % columns) * fw, math.floor(frame / columns) * fh
            local px, py = (other % columns) * fw, math.floor(other / columns) * fh
            local differs = false
            for row = 0, fh - 1 do
                for column = 0, fw - 1 do
                    if alpha(ox + column, oy + row) ~= alpha(px + column, py + row) then differs = true end
                end
            end
            assert(differs, id .. ": opposite headings " .. frame .. "/" .. other .. " are different pictures")
        end
        -- Heading lookup: east is frame 0, counter-clockwise, nearest frame, any turn count.
        local step = 2 * math.pi / frames
        assert(P.kartFrame(sprite, 0) == 0 and P.kartFrame(sprite, math.pi / 2) == frames / 4 and
               P.kartFrame(sprite, math.pi) == frames / 2 and P.kartFrame(sprite, -math.pi / 2) == 3 * frames / 4,
               id .. ": cardinal headings map to their frames")
        assert(P.kartFrame(sprite, 0.49 * step) == 0 and P.kartFrame(sprite, 0.51 * step) == 1 and
               P.kartFrame(sprite, -0.49 * step) == 0 and P.kartFrame(sprite, -0.51 * step) == frames - 1 and
               P.kartFrame(sprite, 2 * math.pi + step) == 1 and P.kartFrame(sprite, -4 * math.pi + 2 * step) == 2,
               id .. ": nearest frame with wrap-around")
        spriteFiles = spriteFiles + 1
        print(("offline kart sheet %s: %dx%d TGA, %d frames of %dx%d, %d-%d opaque texels per frame")
            :format(id, w, h, frames, fw, fh, fewest, most))
    else
        local perUnit = w / sprite.quadWidth
        local halfW, halfH = P.KART_FOOTPRINT_WIDTH * perUnit / 2, P.KART_FOOTPRINT_HEIGHT * perUnit / 2
        local visible, solid = 0, 0
        local left, right, top, bottom = w, -1, h, -1
        for row = 0, h - 1 do
            for column = 0, w - 1 do
                local a = alpha(column, row)
                if a > 0 then
                    assert(math.abs(column + 0.5 - w / 2) <= halfW and math.abs(row + 0.5 - h / 2) <= halfH,
                           id .. ": visible texels stay inside the 17x31 body")
                    assert(column > 0 and column < w - 1 and row > 0 and row < h - 1,
                           id .. ": a transparent border protects filtered edges")
                    visible = visible + 1
                    if a == 255 then solid = solid + 1 end
                    left, right = math.min(left, column), math.max(right, column)
                    top, bottom = math.min(top, row), math.max(bottom, row)
                end
            end
        end
        assert(solid > 0.4 * 4 * halfW * halfH, id .. ": substantial opaque silhouette")
        assert(math.abs((left + right + 1) / 2 - w / 2) <= 0.5 and math.abs((top + bottom + 1) / 2 - h / 2) <= 1,
               id .. ": silhouette centered on the quad (kart pivot)")
        if id == "goblin_drag_car" then
            -- North-facing landmarks: pointed nose up, open front corners, wide rear slicks.
            assert(alpha(w / 2, 16) > 0 and alpha(w / 2 - 1, 16) > 0, id .. ": nose points north")
            for row = 15, 21 do
                for column = 5, 21 do
                    assert(alpha(column, row) == 0 and alpha(w - 1 - column, row) == 0,
                           id .. ": front corners stay open")
                end
            end
            assert(alpha(8, 96) == 255 and alpha(w - 9, 96) == 255, id .. ": wide rear slicks sit south")
        end
        spriteFiles = spriteFiles + 1
        print(("offline kart sprite %s: %dx%d TGA, %d visible/%d opaque texels inside %dx%d body")
            :format(id, w, h, visible, solid, P.KART_FOOTPRINT_WIDTH, P.KART_FOOTPRINT_HEIGHT))
    end
end
assert(spriteFiles >= 1, "at least one kart sprite is validated")

-- Drift and boost effects: the shipped atlases match Presentation.EFFECTS, and
-- the particle logic follows drift/boost state without writing it. Offline
-- only; client loading, blending and look are in-game checks.
do
    local E = P.EFFECTS
    local function atlas(path, w, h)
        assert(path:sub(1, #addonPrefix) == addonPrefix and path:find("\\Assets\\Effects\\[%w]+%.tga$"),
               path .. ": addon effect TGA path")
        assert(powerOfTwo(w) and powerOfTwo(h), path .. ": power-of-two texture")
        local file = assert(io.open("addon/AzerothKart/" .. (path:sub(#addonPrefix + 1):gsub("\\", "/")), "rb"),
                            path .. ": declared effect atlas exists in the addon")
        local data = file:read("*a")
        file:close()
        local function u16(index) return data:byte(index) + 256 * data:byte(index + 1) end
        assert(data:byte(1) == 0 and data:byte(3) == 2 and u16(13) == w and u16(15) == h and data:byte(17) == 32
               and data:byte(18) == 8 and #data == 18 + w * h * 4, path .. ": BGRA32, bottom-left, declared size")
        return function(column, rowFromTop) return data:byte(18 + ((h - 1 - rowFromTop) * w + column) * 4 + 4) end
    end
    local particleAlpha = atlas(E.particlesPath, E.particlesWidth, E.particlesHeight)
    local flameAlpha = atlas(E.flamePath, E.flameWidth, E.flameHeight)
    -- Each cell: the crop matches the layout, a transparent border, paint, and
    -- (for sparks and flames) alpha weighted toward the cell's direction.
    local function cell(alpha, kind, index, size, w, h, dx, dy)
        local l, r, top, b = P.effectCoords(kind, index)
        local ox, oy = l * w, top * h
        assert(ox % 1 == 0 and oy % 1 == 0 and math.abs((r - l) * w - size) < 1e-9
               and math.abs((b - top) * h - size) < 1e-9, kind .. " " .. index .. ": crop matches the atlas layout")
        local covered, mx, my = 0, 0, 0
        for row = 0, size - 1 do
            for column = 0, size - 1 do
                local a = alpha(ox + column, oy + row)
                if row == 0 or column == 0 or row == size - 1 or column == size - 1 then
                    assert(a == 0, kind .. " " .. index .. ": cell keeps a transparent border")
                end
                if a > 0 then
                    covered = covered + 1
                    mx = mx + ((column + 0.5) / size * 2 - 1) * a
                    my = my + (1 - (row + 0.5) / size * 2) * a
                end
            end
        end
        assert(covered > size * size / 40, kind .. " " .. index .. ": cell is painted")
        if dx then assert(mx * dx + my * dy > 0, kind .. " " .. index .. ": cell points along its direction") end
    end
    for index = 0, E.smokeVariants - 1 do
        cell(particleAlpha, "smoke", index, E.smokeCell, E.particlesWidth, E.particlesHeight)
    end
    for index = 0, E.sparkDirections - 1 do
        local angle = index * tau / E.sparkDirections
        cell(particleAlpha, "spark", index, E.sparkCell, E.particlesWidth, E.particlesHeight,
             math.cos(angle), math.sin(angle))
    end
    for index = 0, E.flameDirections - 1 do       -- the sheet camera foreshortens north by 0.8
        local angle = index * tau / E.flameDirections
        cell(flameAlpha, "flame", index, E.flameCell, E.flameWidth, E.flameHeight,
             math.cos(angle), 0.8 * math.sin(angle))
    end

    local trike = P.KART_SPRITES.goblin_mortar_trike.effects
    local options = {anchors = trike, dust = {0.9, 0.85, 0.8}, boostFullTicks = 48}
    local function live(fx, now)
        local smoke, sparks, newestSpark = 0, 0, nil
        for _, p in ipairs(fx.smoke) do if P.particleAt(p, now) then smoke = smoke + 1 end end
        for _, p in ipairs(fx.sparks) do
            if P.particleAt(p, now) then
                sparks = sparks + 1
                if not newestSpark or p.born > newestSpark.born then newestSpark = p end
            end
        end
        return smoke, sparks, newestSpark
    end
    -- Drive the effects tick by tick through a state script, checking that
    -- no state is ever written.
    local function run(fx, from, ticks, fields)
        local previous
        for tick = from, from + ticks - 1 do
            local state = {x = 500, y = 200 + 3 * tick, heading = math.pi / 2, tick = tick, speed = 180,
                           drifting = false, driftTier = 0, driftTicks = 0, driftGraceTicks = 0,
                           driftDirection = 0, boostTicks = 0, surface = "road"}
            for key, value in pairs(fields) do state[key] = type(value) == "function" and value(tick) or value end
            local before = {}
            for key, value in pairs(state) do before[key] = value end
            local now = P.advanceEffects(fx, previous, state, 1, options)
            assert(now == tick, "a stopped or exact frame draws at the current tick")
            for key, value in pairs(before) do assert(state[key] == value, "effects never write state: " .. key) end
            for key in pairs(state) do assert(before[key] ~= nil, "effects add no state fields: " .. key) end
            previous = state
        end
        return previous
    end
    local fx = P.newEffects()
    assert(#fx.smoke == E.smokeCount and #fx.sparks == E.sparkCount and #fx.flames == E.flameCount,
           "fixed effect pools")
    local last = run(fx, 1, 20, {})
    local smoke, sparks = live(fx, last.tick)
    assert(smoke == 0 and sparks == 0 and not fx.flames[1].on, "plain driving emits nothing")
    for tier = 0, 2 do
        last = run(fx, last.tick + 1, 12, {drifting = true, driftTier = tier, driftDirection = 1})
        local smokeNow, sparksNow, newest = live(fx, last.tick)
        assert(smokeNow > 0 and sparksNow > 0, "drift tier " .. tier .. " shows dust and sparks")
        local color = E.sparkColors[tier]
        assert(newest.r == color[1] and newest.g == color[2] and newest.b == color[3],
               "drift tier " .. tier .. " sparks use the meter's colour")
    end
    local _, sparks2 = live(fx, last.tick)
    -- Release: the first boost tick bursts soot from every exhaust; flames burn.
    local puffsBefore = fx.puffs
    last = run(fx, last.tick + 1, 1, {boostTicks = 48})
    assert(fx.puffs == puffsBefore + 2 * #trike.exhausts, "a fired boost bursts soot from every pipe")
    assert(fx.flames[1].on and fx.flames[2].on and fx.flames[1].cell == 24,
           "both pipes burn, pointing behind a north-facing kart (heading 3pi/2)")
    assert(fx.flames[1].front and fx.flames[2].front, "a north-facing kart shows its exhausts in front")
    -- Same tick (same flicker), less boost left: a smaller flame.
    local fading = P.newEffects()
    run(fading, last.tick, 1, {boostTicks = 6})
    assert(fading.flames[1].size < fx.flames[1].size, "the flame shrinks as the boost runs out")
    last = run(fx, last.tick + 1, 40, {boostTicks = 30})
    last = run(fx, last.tick + 1, 1, {boostTicks = 20, heading = -math.pi / 2})
    assert(fx.flames[1].cell == 8 and not fx.flames[1].front and not fx.flames[2].front,
           "a south-facing kart's flames point north, behind its body")
    last = run(fx, last.tick + 1, 1, {})
    assert(not fx.flames[1].on and not fx.flames[2].on, "flames stop with the boost")
    -- Effects age with ticks and fade out; the pools never grow.
    for _, p in ipairs(fx.smoke) do
        if p.on then
            local x, y, size, a = P.particleAt(p, p.born + 1)
            local x2, y2, size2, a2 = P.particleAt(p, p.born + p.life - 1)
            assert(size2 > size and a2 < a and P.particleAt(p, p.born + p.life + 0.001) == nil,
                   "puffs grow, fade and expire")
        end
    end
    assert(#fx.smoke == E.smokeCount and #fx.sparks == E.sparkCount, "pools keep their size")
    -- Interpolated frames sit between ticks; a new run (tick going back) clears.
    local previous = {x = 0, y = 0, heading = 0, tick = 99}
    local current = {x = 3, y = 0, heading = 0, tick = 100, boostTicks = 0}
    assert(P.advanceEffects(fx, previous, current, 0.25, options) == 99.25, "effect time follows the drawn pose")
    P.advanceEffects(fx, nil, {x = 0, y = 0, heading = 0, tick = 0}, 1, options)
    smoke, sparks = live(fx, 0)
    assert(smoke == 0 and sparks == 0 and not fx.flames[1].on, "a restarted run clears all effects")
    -- The same states give the same particles.
    local a, b = P.newEffects(), P.newEffects()
    for _, f in ipairs({a, b}) do
        run(f, 1, 30, {drifting = true, driftTier = 2, driftDirection = -1})
        run(f, 31, 10, {boostTicks = 48})
    end
    for _, pool in ipairs({"smoke", "sparks"}) do
        for i, p in ipairs(a[pool]) do
            for key, value in pairs(p) do assert(b[pool][i][key] == value, "deterministic effects: " .. key) end
        end
    end
    -- Overhead art has no near side; its flames burn behind the kart.
    local overhead = P.newEffects()
    local overheadOptions = {anchors = P.DEFAULT_EFFECT_ANCHORS, dust = options.dust, boostFullTicks = 48}
    P.advanceEffects(overhead, nil, {x = 0, y = 0, heading = math.pi / 2, tick = 1, boostTicks = 0}, 1, overheadOptions)
    P.advanceEffects(overhead, nil, {x = 0, y = 3, heading = math.pi / 2, tick = 2, boostTicks = 30}, 1, overheadOptions)
    assert(overhead.flames[1].on and not overhead.flames[1].front and not overhead.flames[2].on,
           "the primitive kart's single rear exhaust burns behind it")
    print(("offline effects: %dx%d particle and %dx%d flame atlases; %d smoke/%d spark pools; "
        .. "tier colours, boost flames and soot follow state without writing it (%d sparks at tier 2)")
        :format(E.particlesWidth, E.particlesHeight, E.flameWidth, E.flameHeight, E.smokeCount, E.sparkCount, sparks2))
end

-- Mirage background registration: the shipped TGA against the actual Lua
-- geometry. Interior road texels must stay darker than the 0.5-3 unit salt rim
-- outside every edge, so the painted boundary matches isDrivable. Offline bytes
-- only; client appearance is a separate in-game check.
do
    local Oval = dofile("addon/AzerothKart/Track.lua")
    local Mirage = dofile("addon/AzerothKart/MirageRaceway.lua").new(Oval.crossesGate)
    local file = assert(io.open("addon/AzerothKart/Assets/Tracks/SaltFlats/Background.tga", "rb"))
    local data = file:read("*a")
    file:close()
    local size = 1024
    assert(#data == 18 + size * size * 4 and data:byte(3) == 2 and data:byte(17) == 32
           and data:byte(18) == 8, "background stays an uncompressed bottom-left BGRA32 TGA")
    local line = Mirage.centerline
    local function centerDistance(px, py)
        local best = math.huge
        for i = 1, #line do
            local a, b = line[i], line[i % #line + 1]
            local dx, dy = b.x - a.x, b.y - a.y
            local u = math.max(0, math.min(1, ((px - a.x) * dx + (py - a.y) * dy) / (dx * dx + dy * dy)))
            local ox, oy = px - (a.x + u * dx), py - (a.y + u * dy)
            best = math.min(best, ox * ox + oy * oy)
        end
        return math.sqrt(best)
    end
    local function luma(x, y)
        local offset = 18 + (y * size + x) * 4
        return 0.299 * data:byte(offset + 3) + 0.587 * data:byte(offset + 2) + 0.114 * data:byte(offset + 1)
    end
    local road, rim = 0, 0
    for y = 0, size - 1, 3 do
        for x = 0, size - 1, 3 do
            local px, py = x + 0.5, y + 0.5
            local d = centerDistance(px, py)
            if Mirage.isDrivable(px, py) then
                local startLine = y >= 351 and y <= 368 and x >= 643 and x <= 756
                if d <= 44 and not startLine then
                    assert(luma(x, y) <= 180, ("painted road too light at (%d,%d)"):format(x, y))
                    road = road + 1
                end
            elseif d - 56 >= 0.5 and d - 56 <= 3 then
                assert(luma(x, y) >= 190, ("salt rim too dark at (%d,%d)"):format(x, y))
                rim = rim + 1
            end
        end
    end
    assert(road > 15000 and rim > 900, "registration samples cover the whole circuit")
    print(("offline Mirage background: %d road / %d rim samples agree with isDrivable"):format(road, rim))
end

assert(_G.AzerothKart == beforeGlobal, "offline import must not create or replace an addon global")
local namespace = {sentinel=marker}
local loaded = assert(loadfile("addon/AzerothKart/Presentation.lua"))("AzerothKart", namespace)
assert(namespace.Presentation == loaded and namespace.sentinel == marker,
       "addon import registers with its explicit namespace")
assert(_G.AzerothKart == beforeGlobal, "namespace import must not replace an addon global")
print("offline presentation: close follow camera/cropped UVs/marker clipping, aspect-fit mapping, poses and drift meter")
