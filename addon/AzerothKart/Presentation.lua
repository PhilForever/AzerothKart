-- Pure presentation values; never feed them back into simulation.
local _, namespace = ...
local Presentation = {}
local pi, tau = math.pi, 2 * math.pi

local function finite(value)
    return type(value) == "number" and value == value
        and value > -math.huge and value < math.huge
end

function Presentation.fitViewport(worldWidth, worldHeight, canvasWidth, canvasHeight)
    assert(finite(worldWidth) and worldWidth > 0 and finite(worldHeight) and worldHeight > 0
        and finite(canvasWidth) and canvasWidth > 0 and finite(canvasHeight) and canvasHeight > 0,
        "finite positive world and canvas dimensions required")
    local scale = math.min(canvasWidth/worldWidth,canvasHeight/worldHeight)
    local width,height = worldWidth*scale,worldHeight*scale
    assert(finite(scale) and scale > 0 and finite(width) and width > 0
        and finite(height) and height > 0, "viewport scale must be representable")
    return {
        scale=scale, offsetX=(canvasWidth-width)/2, offsetY=(canvasHeight-height)/2,
        width=width, height=height, worldWidth=worldWidth, worldHeight=worldHeight,
        canvasWidth=canvasWidth, canvasHeight=canvasHeight,
    }
end

-- Unlike the overview, a camera fills the canvas and exposes a smaller part of
-- the world. Covering the canvas is the minimum zoom, so UVs stay inside the art.
function Presentation.cameraViewport(worldWidth, worldHeight, canvasWidth, canvasHeight, scale)
    assert(finite(worldWidth) and worldWidth > 0 and finite(worldHeight) and worldHeight > 0
        and finite(canvasWidth) and canvasWidth > 0 and finite(canvasHeight) and canvasHeight > 0,
        "finite positive world and canvas dimensions required")
    if scale == nil then scale = 1.5 end
    assert(finite(scale) and scale > 0, "finite positive camera scale required")
    scale = math.max(scale, canvasWidth/worldWidth, canvasHeight/worldHeight)
    local viewWidth,viewHeight = canvasWidth/scale,canvasHeight/scale
    local offsetX,offsetY = (canvasWidth-worldWidth*scale)/2,(canvasHeight-worldHeight*scale)/2
    assert(finite(scale) and finite(viewWidth) and viewWidth > 0
        and finite(viewHeight) and viewHeight > 0 and finite(offsetX) and finite(offsetY),
        "camera scale must be representable")
    return {
        scale=scale, offsetX=offsetX, offsetY=offsetY, width=canvasWidth, height=canvasHeight,
        worldWidth=worldWidth, worldHeight=worldHeight,
        canvasWidth=canvasWidth, canvasHeight=canvasHeight,
        viewWidth=viewWidth, viewHeight=viewHeight, follow=true,
    }
end

local function requireViewport(view, x, y)
    assert(type(view) == "table" and finite(view.scale) and view.scale > 0
        and finite(view.offsetX) and finite(view.offsetY), "finite viewport transform required")
    assert(finite(x) and finite(y), "finite coordinates required")
end

-- Both spaces use a bottom-left origin with positive Y pointing upward. The
-- inverse deliberately accepts points outside the fitted rectangle without clamping.
function Presentation.project(view, x, y)
    requireViewport(view,x,y)
    local px,py = view.offsetX+x*view.scale,view.offsetY+y*view.scale
    assert(finite(px) and finite(py), "projected coordinates must be finite")
    return px,py
end

function Presentation.unproject(view, x, y)
    requireViewport(view,x,y)
    local wx,wy = (x-view.offsetX)/view.scale,(y-view.offsetY)/view.scale
    assert(finite(wx) and finite(wy), "world coordinates must be finite")
    return wx,wy
end

local function requireCamera(view)
    requireViewport(view,0,0)
    assert(view.follow == true and finite(view.worldWidth) and view.worldWidth > 0
        and finite(view.worldHeight) and view.worldHeight > 0
        and finite(view.canvasWidth) and view.canvasWidth > 0
        and finite(view.canvasHeight) and view.canvasHeight > 0
        and finite(view.viewWidth) and view.viewWidth > 0 and view.viewWidth <= view.worldWidth
        and finite(view.viewHeight) and view.viewHeight > 0 and view.viewHeight <= view.worldHeight,
        "bounded camera viewport required")
end

-- Follow the interpolated render pose, not the fixed-step state. Mutating only
-- these two offsets reuses the viewport without per-frame camera allocations.
function Presentation.follow(view, x, y, heading, lookAhead)
    requireCamera(view)
    assert(finite(x) and finite(y) and finite(heading), "finite camera pose required")
    if lookAhead == nil then lookAhead = 60 end
    assert(finite(lookAhead) and lookAhead >= 0, "finite nonnegative camera lookahead required")
    local centerX,centerY = x+math.cos(heading)*lookAhead,y+math.sin(heading)*lookAhead
    assert(finite(centerX) and finite(centerY), "camera target must be representable")
    local left = math.max(0,math.min(view.worldWidth-view.viewWidth,centerX-view.viewWidth/2))
    local bottom = math.max(0,math.min(view.worldHeight-view.viewHeight,centerY-view.viewHeight/2))
    view.offsetX,view.offsetY = -left*view.scale,-bottom*view.scale
    return view
end

-- WoW's four-number texture coordinates are left/right/top/bottom, while the
-- simulation uses a bottom-left origin. This is a crop, not a stretched map.
function Presentation.texCoords(view)
    requireCamera(view)
    local left,bottom = -view.offsetX/view.scale,-view.offsetY/view.scale
    return math.max(0,math.min(1,left/view.worldWidth)),
           math.max(0,math.min(1,(left+view.viewWidth)/view.worldWidth)),
           math.max(0,math.min(1,1-(bottom+view.viewHeight)/view.worldHeight)),
           math.max(0,math.min(1,1-bottom/view.worldHeight))
end

-- Axis-aligned world rectangles (gates and perimeter strips) are cropped before
-- UI placement, keeping markers inside the canvas without a clipping API.
function Presentation.clipRect(view, x, y, width, height)
    requireViewport(view,x,y)
    assert(finite(view.canvasWidth) and view.canvasWidth > 0
        and finite(view.canvasHeight) and view.canvasHeight > 0,
        "finite positive canvas dimensions required")
    assert(finite(width) and width >= 0 and finite(height) and height >= 0,
        "finite nonnegative rectangle dimensions required")
    local px,py = Presentation.project(view,x,y)
    local right,top = px+width*view.scale,py+height*view.scale
    assert(finite(right) and finite(top), "rectangle bounds must be representable")
    local left,bottom = math.max(0,px),math.max(0,py)
    right,top = math.min(view.canvasWidth,right),math.min(view.canvasHeight,top)
    if left >= right or bottom >= top then return nil end
    return left,bottom,right-left,top-bottom
end

function Presentation.pose(previous, current, alpha)
    assert(current, "current pose required")
    -- Missing/invalid timing draws the exact latest state. Infinities clamp
    -- naturally below; NaN must be handled before comparisons/arithmetic.
    if type(alpha) ~= "number" or alpha ~= alpha then alpha = 1 end
    if not previous or alpha >= 1 then return current.x, current.y, current.heading end
    if alpha <= 0 then return previous.x, previous.y, previous.heading end

    -- Physics headings may accumulate whole turns. Only the shortest rotation
    -- matters between consecutive states; a half-turn chooses the negative arc.
    local delta = (current.heading - previous.heading + pi) % tau - pi
    return previous.x + (current.x - previous.x) * alpha,
           previous.y + (current.y - previous.y) * alpha,
           previous.heading + delta * alpha
end

function Presentation.meter(state, config)
    assert(state and config, "state and meter config required")
    -- Surface cancellation takes precedence even for a retained/stale charge.
    if state.surface == "grass" or state.surface == "wall" then return 0, "idle" end
    local boostTicks = state.boostTicks or 0
    if boostTicks > 0 then
        -- Both boost tiers share one capacity, so the shorter reward visibly
        -- contains less boost instead of displaying an equally full meter.
        return math.min(1, boostTicks / config.BOOST_TIER2_TICKS), "boost"
    end
    local ticks = state.driftTicks or 0
    if not state.drifting or ticks <= 0 then return 0, "idle" end
    if (state.driftGraceTicks or 0) > 0 then
        return math.min(1, ticks / config.DRIFT_TIER2_TICKS), "holding"
    end
    local phase = "charging"
    if ticks >= config.DRIFT_TIER2_TICKS then phase = "tier2"
    elseif ticks >= config.DRIFT_TIER1_TICKS then phase = "tier1" end
    return math.min(1, ticks / config.DRIFT_TIER2_TICKS), phase
end

-- Kart art metadata: pure data, read-only by convention. Art never feeds
-- collision, gates, input or race timing; quads scale with the same uniform
-- view transform as the world.
-- * A single image (no `frames`) is a strict-overhead, north-facing sprite
--   centred on the kart's physical centre and rotated by heading - pi/2. Its
--   visible texels stay inside the 17x31 world-unit body of the primitive.
-- * A directional sheet (`frames`, `columns`) holds pre-rendered headings:
--   frame k faces heading k * 2pi / frames, counter-clockwise from east, read
--   left to right and top to bottom. The nearest frame is shown unrotated; one
--   frame covers quadWidth x quadHeight world units, and its centre sits
--   (pivotX, pivotY) world units east/north of the kart's position on screen.
Presentation.KART_FOOTPRINT_WIDTH = 17
Presentation.KART_FOOTPRINT_HEIGHT = 31
Presentation.DEFAULT_KART = "goblin_mortar_trike"
-- Sheets rendered from Warcraft III models by scripts/build_wc3_kart.py; see
-- docs/art/karts/ for each model's source, author, terms and credits.
local function sheet(file, name, quad, pivotX, effects)
    return {
        name = name, path = "Interface\\AddOns\\AzerothKart\\Assets\\Karts\\" .. file,
        textureWidth = 1024, textureHeight = 1024, quadWidth = quad, quadHeight = quad,
        frames = 64, columns = 8, pivotX = pivotX, pivotY = 0, effects = effects,
    }
end
Presentation.KART_SPRITES = {
    goblin_drag_car = {
        name = "Goblin Drag Car",
        path = "Interface\\AddOns\\AzerothKart\\Assets\\Karts\\GoblinDragCar.tga",
        textureWidth = 64, textureHeight = 128, -- texels; power-of-two TGA
        quadWidth = 20, quadHeight = 40,        -- world units; 3.2 texels per unit
    },
    -- Rendered from the Warcraft III Goblin Mortar Trike model by erwtenpeller
    -- and Chriz (Vast Graphics); see docs/art/karts/goblin-mortar-trike.md.
    goblin_mortar_trike = {
        name = "Goblin Mortar Trike",
        path = "Interface\\AddOns\\AzerothKart\\Assets\\Karts\\GoblinMortarTrike.tga",
        textureWidth = 1024, textureHeight = 1024, -- texels; 8x8 sheet of 128x128 frames
        quadWidth = 41, quadHeight = 41,           -- world units per frame; 3.12 texels per unit
        frames = 64, columns = 8,                  -- 5.625 degrees between headings
        pivotX = 3, pivotY = 0,                    -- frame centre offset; room for the south-east shadow
        -- Effect anchors from the model: the rear tyres' trailing edge (the
        -- model's own wheel-dust emitters) and its two exhaust stacks.
        effects = {
            wheels = {{-5.9, 6.0}, {-5.9, -6.0}},
            exhausts = {{-13.9, 5.4, 10.6}, {-14.8, -4.9, 10.5}},
            view = {0.8, 0.6},                     -- the sheet camera's tilt (cos, sin)
        },
    },
    -- Anchors below come from build_wc3_kart.py --emitters: each model's own
    -- exhaust and dust emitters and its lowest geometry. Flyers' "wheels" put
    -- dust on the ground under them; a gryphon leaves wingtip trails instead
    -- of exhaust flame.
    steam_tank = sheet("SteamTank.tga", "Steam Tank", 45, 3.7, {
        wheels = {{-7.9, 7.4}, {-7.9, -7.6}},
        exhausts = {{-12.9, 7.9, 12.9}, {-12.9, -8.2, 12.9}},  -- its two smoke stacks
        view = {0.8, 0.6},
    }),
    dwarven_biker = sheet("DwarvenBiker.tga", "Dwarven Biker", 41, 3, {
        wheels = {{-5.5, 6.0}, {-5.5, -6.0}},
        exhausts = {{-13.6, 5.4, 10.6}, {-14.4, -4.9, 10.5}},
        view = {0.8, 0.6},
    }),
    gryphon_rider = sheet("GryphonRider.tga", "Gryphon Rider", 41, 2.6, {
        wheels = {{-6, 3}, {-6, -3}}, exhausts = {},
        trails = {{3.3, 16, 8.9}, {3.3, -16, 8.9}},             -- wingtips
        view = {0.8, 0.6},
    }),
    gyrocopter = sheet("Gyrocopter.tga", "Gyrocopter", 58, 4, {
        wheels = {{-3.4, 6.5}, {-3.4, -6.5}},                  -- skids, 4 units up
        exhausts = {{-3.4, 8.6, 14.7}, {-3.4, -8.6, 14.7}},    -- the wing engines
        view = {0.8, 0.6},
    }),
}
-- The Kart button's cycle while stopped. Karts are cosmetic: every one drives
-- the same 17x31 physics body.
Presentation.KART_ORDER = {
    "goblin_mortar_trike", "steam_tank", "dwarven_biker", "gryphon_rider", "gyrocopter", "goblin_drag_car",
}

-- The kart after `id` in KART_ORDER (wrapping); the first for an unknown id.
function Presentation.nextKart(id)
    local order = Presentation.KART_ORDER
    for index, kart in ipairs(order) do
        if kart == id then return order[index % #order + 1] end
    end
    return order[1]
end
-- The drag car's slicks end 14 units behind its centre; its rocket bell's lip
-- is at 15.3 (scripts/build_kart_sprites.py). Overhead art has no tilt.
Presentation.KART_SPRITES.goblin_drag_car.effects = {
    wheels = {{-14.0, 6.6}, {-14.0, -6.6}}, exhausts = {{-15.3, 0, 0}}, view = {1, 0},
}

-- Nearest directional frame (0-based) for a heading in radians.
function Presentation.kartFrame(sprite, heading)
    assert(type(sprite) == "table" and type(sprite.frames) == "number" and finite(heading),
        "directional sprite and finite heading required")
    return math.floor((heading % tau) / tau * sprite.frames + 0.5) % sprite.frames
end

-- Texture coordinates (left, right, top, bottom) of one frame of a sheet.
function Presentation.kartFrameCoords(sprite, frame)
    local columns = sprite.columns
    local rows = sprite.frames / columns
    local column, row = frame % columns, math.floor(frame / columns)
    return column / columns, (column + 1) / columns, row / rows, (row + 1) / rows
end

-- Drift and boost effects. Presentation-only particles: dust and sparks in the
-- meter's tier colours from the rear tyres while drifting, a flame and soot
-- from the exhausts while boosting. advanceEffects reads two simulation states
-- and never writes them. Effect time is the interpolated tick, so effects
-- freeze with the race and the same states always give the same particles.
-- Positions and sizes are world units. Anchors are in the kart's own frame
-- (+x forward, +y left, z up); `view` is the art's camera tilt (cos, sin), so
-- an anchor lands where the sprite draws that point.
Presentation.EFFECTS = {
    particlesPath = "Interface\\AddOns\\AzerothKart\\Assets\\Effects\\Particles.tga",
    flamePath = "Interface\\AddOns\\AzerothKart\\Assets\\Effects\\Flame.tga",
    particlesWidth = 256, particlesHeight = 128, -- smoke row, then two spark rows
    smokeCell = 64, smokeVariants = 4,
    sparkCell = 32, sparkDirections = 16, sparkColumns = 8, sparkTop = 64,
    flameWidth = 512, flameHeight = 256,         -- flame k points along heading k * 2pi/32
    flameCell = 64, flameDirections = 32, flameColumns = 8,
    smokeCount = 20, sparkCount = 14, flameCount = 2, -- pools; each flame has two layers
    sparkColors = {[0] = {0.40, 0.68, 1.00}, {1.00, 0.80, 0.16}, {1.00, 0.36, 0.78}}, -- charging, tier 1, tier 2
    sootColor = {0.24, 0.22, 0.21}, trailColor = {0.97, 0.97, 0.95},
    flameOuter = {1.00, 0.52, 0.12}, flameInner = {1.00, 0.93, 0.62}, flameInnerScale = 0.6,
    flameReach = 14,                             -- pipe to cell edge at full boost, world units
}
-- Overhead art without effect data (the primitive kart): the rear corners.
Presentation.DEFAULT_EFFECT_ANCHORS = {
    wheels = {{-13, 7}, {-13, -7}}, exhausts = {{-15.5, 0, 0}}, view = {1, 0},
}

local atan2 = math.atan2 or math.atan
local EFFECT_GAP = 30 -- a longer jump between ticks (new run, track change) restarts effects

local function cellCoords(x, y, size, width, height)
    return x / width, (x + size) / width, y / height, (y + size) / height
end

-- Texture coordinates (left, right, top, bottom) of one effect cell.
function Presentation.effectCoords(kind, cell)
    local E = Presentation.EFFECTS
    if kind == "smoke" then
        return cellCoords(cell * E.smokeCell, 0, E.smokeCell, E.particlesWidth, E.particlesHeight)
    elseif kind == "spark" then
        return cellCoords((cell % E.sparkColumns) * E.sparkCell,
            E.sparkTop + math.floor(cell / E.sparkColumns) * E.sparkCell, E.sparkCell,
            E.particlesWidth, E.particlesHeight)
    end
    assert(kind == "flame", "smoke, spark or flame cell required")
    return cellCoords((cell % E.flameColumns) * E.flameCell,
        math.floor(cell / E.flameColumns) * E.flameCell, E.flameCell, E.flameWidth, E.flameHeight)
end

local function newParticle()
    return {on=false, born=0, life=1, x=0, y=0, vx=0, vy=0, rise=0,
            s0=1, s1=1, a0=1, r=1, g=1, b=1, cell=0, spark=false}
end

function Presentation.clearEffects(fx)
    for _,p in ipairs(fx.smoke) do p.on = false end
    for _,p in ipairs(fx.sparks) do p.on = false end
    for _,f in ipairs(fx.flames) do f.on = false end
    fx.tick, fx.seed, fx.puffs, fx.boost = nil, 20261020, 0, 0
end

-- Fixed pools, allocated once; spawning reuses the oldest slot.
function Presentation.newEffects()
    local E = Presentation.EFFECTS
    local fx = {smoke={}, sparks={}, flames={}, nextSmoke=1, nextSpark=1, now=0}
    for i = 1, E.smokeCount do fx.smoke[i] = newParticle() end
    for i = 1, E.sparkCount do fx.sparks[i] = newParticle() end
    for i = 1, E.flameCount do
        fx.flames[i] = {on=false, ox=0, oy=0, cell=0, size=0, alpha=0, front=true}
    end
    Presentation.clearEffects(fx)
    return fx
end

-- Park-Miller steps: exact in Lua 5.1 doubles and Lua 5.4 integers alike.
local function random(fx)
    fx.seed = fx.seed * 16807 % 2147483647
    return fx.seed / 2147483647
end

local function hash01(n)
    local value = (n % 2147483646 + 1) * 16807 % 2147483647
    return value * 16807 % 2147483647 / 2147483647
end

local function take(fx, list, key)
    local index = fx[key]
    fx[key] = index % #list + 1
    return list[index]
end

-- Where the art shows a kart-frame anchor, plus the anchor's northward offset.
local function anchorAt(anchor, x, y, c, s, view)
    local wx, wy = anchor[1] * c - anchor[2] * s, anchor[1] * s + anchor[2] * c
    return x + wx, y + wy * view[1] + (anchor[3] or 0) * view[2], wy
end

local function puff(fx, born, x, y, vx, vy, rise, s0, s1, life, a0, color)
    local p = take(fx, fx.smoke, "nextSmoke")
    p.on, p.born, p.life, p.spark = true, born, life, false
    p.x, p.y, p.vx, p.vy, p.rise = x, y, vx, vy, rise
    p.s0, p.s1, p.a0 = s0, s1, a0
    p.r, p.g, p.b = color[1], color[2], color[3]
    fx.puffs = fx.puffs + 1
    p.cell = fx.puffs % Presentation.EFFECTS.smokeVariants
end

local function spark(fx, born, x, y, vx, vy, life, size, color)
    local E = Presentation.EFFECTS
    local p = take(fx, fx.sparks, "nextSpark")
    p.on, p.born, p.life, p.spark = true, born, life, true
    p.x, p.y, p.vx, p.vy, p.rise = x, y, vx, vy, 0
    p.s0, p.s1, p.a0 = size, size, 1
    p.r, p.g, p.b = color[1], color[2], color[3]
    p.cell = math.floor(atan2(vy, vx) % tau / tau * E.sparkDirections + 0.5) % E.sparkDirections
end

-- One simulation step's emission; `born` is the step's start, (x, y, heading)
-- the pose there and (kvx, kvy) the kart's travel per tick.
local function emit(fx, tick, x, y, heading, kvx, kvy, state, options)
    local E, anchors = Presentation.EFFECTS, options.anchors
    local view, c, s = anchors.view, math.cos(heading), math.sin(heading)
    local born = tick - 1
    if state.drifting then
        local tier = state.driftTier or 0
        if tick % 2 == 0 then                              -- one wheel per tick, alternating
            local wheels = anchors.wheels
            local wheel = wheels[math.floor(tick / 2) % #wheels + 1]
            local px, py = anchorAt(wheel, x, y, c, s, view)
            puff(fx, born, px, py, -c * 0.35 + kvx * 0.18 + (random(fx) - 0.5) * 0.3,
                -s * 0.35 + kvy * 0.18 + (random(fx) - 0.5) * 0.3, 0,
                5 + random(fx), 15 + 4 * random(fx), 24 + 8 * random(fx), 0.7, options.dust)
        end
        -- A denser, bigger spray as the charge grows; sparse while a steering
        -- correction holds it.
        local every = (state.driftGraceTicks or 0) > 0 and 4 or (tier == 2 and 1 or (tier == 1 and 2 or 3))
        if tick % every == 0 then
            local wheels = anchors.wheels
            local wheel = wheels[math.floor(tick / every) % #wheels + 1]
            local px, py = anchorAt(wheel, x, y, c, s, view)
            local back = 0.6 + 0.6 * random(fx)
            local side = (wheel[2] >= 0 and 1 or -1) * (0.15 + 0.45 * random(fx))
                - (state.driftDirection or 0) * 0.3        -- lean to the outside of the turn
            spark(fx, born, px, py, -c * back - s * side + kvx * 0.35, -s * back + c * side + kvy * 0.35,
                8 + 4 * random(fx), 8 + 1.5 * tier, E.sparkColors[tier] or E.sparkColors[0])
        end
    end
    local boost = state.boostTicks or 0
    if boost > 0 and anchors.trails and tick % 2 == 0 then -- pale wind from a flyer's wingtips
        for _,tip in ipairs(anchors.trails) do
            local px, py = anchorAt(tip, x, y, c, s, view)
            puff(fx, born, px, py, -c * 0.6 + kvx * 0.4, -s * 0.6 + kvy * 0.4, 0,
                2.5, 7 + random(fx), 14 + 4 * random(fx), 0.55, E.trailColor)
        end
    end
    if boost > 0 and #anchors.exhausts > 0 then
        local pipes = anchors.exhausts
        local burst = fx.boost == 0                         -- the boost just fired
        for n = 1, burst and 2 * #pipes or (tick % 2 == 0 and 1 or 0) do
            local pipe = pipes[(burst and n or math.floor(tick / 2)) % #pipes + 1]
            local px, py = anchorAt(pipe, x, y, c, s, view)
            puff(fx, born, px, py, -c * 0.8 + kvx * 0.3 + (random(fx) - 0.5) * 0.25,
                -s * 0.8 + kvy * 0.3 + (random(fx) - 0.5) * 0.25, 0.06,
                4, (burst and 17 or 13) + 2 * random(fx), 30 + 8 * random(fx), burst and 0.7 or 0.6, E.sootColor)
        end
    end
    fx.boost = boost
end

local function updateFlames(fx, state, heading, now, options)
    local E, anchors = Presentation.EFFECTS, options.anchors
    local boost = state.boostTicks or 0
    local view, c, s = anchors.view, math.cos(heading), math.sin(heading)
    local cell = math.floor((heading + pi) % tau / tau * E.flameDirections + 0.5) % E.flameDirections
    local strength = 0.55 + 0.45 * math.min(1, boost / (options.boostFullTicks or 48))
    local tick = math.floor(now)
    for i,flame in ipairs(fx.flames) do
        local pipe = anchors.exhausts[i]
        flame.on = boost > 0 and pipe ~= nil
        if flame.on then
            local ox, oy, north = anchorAt(pipe, 0, 0, c, s, view)
            local flicker = hash01(tick * 4 + i)
            flame.ox, flame.oy, flame.cell = ox, oy, cell
            flame.size = 2 * E.flameReach * strength * (0.9 + 0.2 * flicker)
            flame.alpha = 0.85 + 0.15 * hash01(tick * 4 + i + 2)
            -- A pipe on the kart's far (north) side burns behind the body;
            -- overhead art has no near side.
            flame.front = view[2] > 0 and north < 1.5
        end
    end
end

-- Advance effects to the drawn pose; returns the effect time in ticks.
-- options: anchors, dust colour and boostFullTicks (the boost that shows the
-- full flame). Only `fx` is written.
function Presentation.advanceEffects(fx, previous, current, alpha, options)
    assert(type(fx) == "table" and type(current) == "table" and type(options) == "table"
        and type(options.anchors) == "table", "effects, current state and options required")
    local tick = current.tick or 0
    if fx.tick == nil or tick < fx.tick or tick - fx.tick > EFFECT_GAP then
        Presentation.clearEffects(fx)
        fx.tick, fx.x, fx.y, fx.heading = tick, current.x, current.y, current.heading
        fx.boost = current.boostTicks or 0
    elseif tick > fx.tick then
        local steps = tick - fx.tick
        local kvx, kvy = (current.x - fx.x) / steps, (current.y - fx.y) / steps
        local turn = (current.heading - fx.heading + pi) % tau - pi
        for j = 1, steps do
            emit(fx, fx.tick + j, fx.x + kvx * (j - 1), fx.y + kvy * (j - 1),
                fx.heading + turn * (j - 1) / steps, kvx, kvy, current, options)
        end
        fx.tick, fx.x, fx.y, fx.heading = tick, current.x, current.y, current.heading
    end
    local _, _, heading = Presentation.pose(previous, current, alpha)
    local now = tick
    if previous and previous ~= current and previous.tick == tick - 1 and type(alpha) == "number"
        and alpha == alpha and alpha < 1 then
        now = tick - 1 + math.max(0, alpha)
    end
    fx.now = now
    updateFlames(fx, current, heading, now, options)
    return now
end

-- A particle's world position, size and opacity at effect time `now`, or nil.
function Presentation.particleAt(p, now)
    if not p.on then return nil end
    local age = now - p.born
    if age < 0 or age >= p.life then return nil end
    local k = age / p.life
    local travel = age * (1 - 0.5 * k)            -- eases to half speed
    local size = p.s0 + (p.s1 - p.s0) * math.sqrt(k)
    local alpha
    if p.spark then alpha = p.a0 * (1 - k * k * k)
    else alpha = p.a0 * math.min(1, age / 3) * (1 - k) * (1 - k) end
    return p.x + p.vx * travel, p.y + p.vy * travel + p.rise * age, size, alpha
end

if type(namespace) == "table" then namespace.Presentation = Presentation end
return Presentation
