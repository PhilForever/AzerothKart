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

if type(namespace) == "table" then namespace.Presentation = Presentation end
return Presentation
