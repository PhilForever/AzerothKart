-- Pure presentation values; never feed them back into simulation.
local _, namespace = ...
local Presentation = {}
local pi, tau = math.pi, 2 * math.pi

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
    local phase = "charging"
    if ticks >= config.DRIFT_TIER2_TICKS then phase = "tier2"
    elseif ticks >= config.DRIFT_TIER1_TICKS then phase = "tier1" end
    return math.min(1, ticks / config.DRIFT_TIER2_TICKS), phase
end

if type(namespace) == "table" then namespace.Presentation = Presentation end
return Presentation
