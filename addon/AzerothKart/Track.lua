-- Minimal analytical track geometry. Pure Lua, independent of WoW APIs.
local _, namespace = ...

local Track = {}
Track.width, Track.height = 800, 480
Track.centerX, Track.centerY = 400, 240
Track.outerX, Track.outerY = 370, 218
Track.innerX, Track.innerY = 170, 84
Track.lineX, Track.lineY = 266, 151
-- Center clearance encloses the 17x31 kart at any rotation (half diagonal <18).
Track.wallInset = 18
-- Four road-spanning gates follow the counterclockwise route from the spawn.
-- Normals point in the required travel direction; the final gate is Start.
Track.gates = {
    {name="North", ax=Track.centerX, ay=Track.centerY+Track.innerY,
        bx=Track.centerX, by=Track.centerY+Track.outerY, nx=-1, ny=0},
    {name="West", ax=Track.centerX-Track.outerX, ay=Track.centerY,
        bx=Track.centerX-Track.innerX, by=Track.centerY, nx=0, ny=-1},
    {name="South", ax=Track.centerX, ay=Track.centerY-Track.outerY,
        bx=Track.centerX, by=Track.centerY-Track.innerY, nx=1, ny=0},
    {name="Start", ax=Track.centerX+Track.innerX, ay=Track.centerY,
        bx=Track.centerX+Track.outerX, by=Track.centerY, nx=0, ny=1},
}
-- Current fixed-step maximum is 260/60 units; this is a local sanity bound,
-- not multiplayer validation or a claim of cheat resistance.
Track.checkpointMaxStep = 5

local function finite(value)
    return type(value) == "number" and value == value
        and value > -math.huge and value < math.huge
end

function Track.crossesGate(previous, current, gate)
    if type(previous) ~= "table" or type(current) ~= "table" or type(gate) ~= "table" then
        return false
    end
    if not (finite(previous.x) and finite(previous.y) and finite(current.x) and finite(current.y)
        and finite(gate.ax) and finite(gate.ay) and finite(gate.bx) and finite(gate.by)
        and finite(gate.nx) and finite(gate.ny)) then return false end
    local gx,gy = gate.bx-gate.ax,gate.by-gate.ay
    local lengthSquared = gx*gx+gy*gy
    local normalSquared = gate.nx*gate.nx+gate.ny*gate.ny
    if not finite(lengthSquared) or lengthSquared <= 0
        or not finite(normalSquared) or normalSquared <= 0
        or gx*gate.nx+gy*gate.ny ~= 0 then return false end
    local before = (previous.x-gate.ax)*gate.nx+(previous.y-gate.ay)*gate.ny
    local after = (current.x-gate.ax)*gate.nx+(current.y-gate.ay)*gate.ny
    if not finite(before) or not finite(after) or before >= 0 or after < 0 then return false end
    local denominator = after-before
    if not finite(denominator) then return false end
    local fraction = -before/denominator
    local x = previous.x+(current.x-previous.x)*fraction
    local y = previous.y+(current.y-previous.y)*fraction
    local along = (x-gate.ax)*gx+(y-gate.ay)*gy
    return finite(along) and along >= 0 and along <= lengthSquared
end

function Track.isDrivable(x, y)
    if type(x) ~= "number" or type(y) ~= "number" then return false end
    if x ~= x or y ~= y then return false end -- reject NaN
    local dx = x - Track.centerX
    local dy = y - Track.centerY
    local out = (dx / Track.outerX)^2 + (dy / Track.outerY)^2
    local inside = (dx / Track.innerX)^2 + (dy / Track.innerY)^2
    return out <= 1 and inside >= 1
end

-- isDrivable remains the road mask; grass is traversable inside separate walls.
function Track.surfaceAt(x, y)
    if not finite(x) or not finite(y) then return "wall" end
    local inset = Track.wallInset
    if x < inset or x > Track.width-inset or y < inset or y > Track.height-inset then
        return "wall"
    end
    return Track.isDrivable(x,y) and "road" or "grass"
end

function Track.constrainPosition(x, y)
    assert(finite(x) and finite(y), "finite track coordinates required")
    local inset = Track.wallInset
    local cx = math.max(inset,math.min(Track.width-inset,x))
    local cy = math.max(inset,math.min(Track.height-inset,y))
    return cx,cy,cx ~= x or cy ~= y
end

function Track.spawn()
    return {x=Track.centerX + Track.lineX, y=Track.centerY, heading=math.pi/2}
end

if type(namespace) == "table" then namespace.Track = Track end
return Track
