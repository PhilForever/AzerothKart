local beforeGlobal = _G.AzerothKart
local P = dofile("addon/AzerothKart/Presentation.lua")
local pi, tau = math.pi, 2 * math.pi
local function near(actual, expected, message)
    assert(math.abs(actual - expected) < 1e-10, message)
end
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
local state = {surface="road", drifting=true, driftTicks=53, driftTier=2, boostTicks=0}
local function meter(ticks, fraction, phase)
    state.driftTicks = ticks
    local actualFraction, actualPhase = P.meter(state, config)
    near(actualFraction, fraction, "meter fraction at " .. ticks)
    assert(actualPhase == phase, "meter phase at " .. ticks)
end
-- Read actual ticks rather than a possibly stale/inconsistent driftTier.
meter(0, 0, "idle")
meter(53, 53/108, "charging")
meter(54, 54/108, "tier1")
meter(107, 107/108, "tier1")
meter(108, 1, "tier2")
meter(500, 1, "tier2")
state.drifting = false
meter(108, 0, "idle")
for _, remaining in ipairs({29, 47, 48, 100}) do
    state.boostTicks = remaining
    local fraction, phase = P.meter(state, config)
    near(fraction, math.min(1, remaining/48), "shared boost capacity")
    assert(phase == "boost", "boost takes precedence over charge")
end
state.boostTicks = 0
meter(108, 0, "idle")
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
assert(config.DRIFT_TIER1_TICKS == 54 and config.DRIFT_TIER2_TICKS == 108
       and config.BOOST_TIER2_TICKS == 48, "meter preserves injected configuration")

assert(_G.AzerothKart == beforeGlobal, "offline import must not create or replace an addon global")
local namespace = {sentinel=marker}
local loaded = assert(loadfile("addon/AzerothKart/Presentation.lua"))("AzerothKart", namespace)
assert(namespace.Presentation == loaded and namespace.sentinel == marker,
       "addon import registers with its explicit namespace")
assert(_G.AzerothKart == beforeGlobal, "namespace import must not replace an addon global")
print("offline presentation: scalar poses, shortest-arc heading, tiered drift/boost meter and untouched states")
