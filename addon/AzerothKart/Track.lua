-- Minimal analytical track geometry. Pure Lua, independent of WoW APIs.
local _, namespace = ...

local Track = {}
Track.id, Track.version = "test_oval", 2
Track.width, Track.height = 800, 480
Track.centerX, Track.centerY = 400, 240
Track.outerX, Track.outerY = 370, 218
Track.innerX, Track.innerY = 170, 84
Track.lineX, Track.lineY = 266, 151
-- Center clearance encloses the 17x31 kart at any rotation (half diagonal <18).
Track.wallInset = 18
-- Physical rectangles, bottom-left origin; read-only after module creation.
-- Rendering uses these dimensions. Movement expands each side by wallInset.
-- Only the test oval has these fixtures; Mirage keeps its own geometry.
Track.obstacles = {
    {id="north_crate", x=270, y=400, width=32, height=24},
    {id="south_crate", x=490, y=60, width=32, height=24},
}
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
    for i=1,#Track.obstacles do
        local box = Track.obstacles[i]
        if x >= box.x and x <= box.x+box.width
            and y >= box.y and y <= box.y+box.height then return "wall" end
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

-- Return entry time and the exact blocking plane(s), or nil. Open interiors
-- let a kart move away from a face or slide along it without repeated impacts.
-- An isolated corner touch also stays free: it has no interior time interval.
local function sweepBox(x, y, dx, dy, minX, minY, maxX, maxY)
    local nearX,farX,planeX = -math.huge,math.huge,nil
    local nearY,farY,planeY = -math.huge,math.huge,nil
    if dx == 0 then
        if x <= minX or x >= maxX then return nil end
    elseif dx > 0 then
        nearX,farX,planeX = (minX-x)/dx,(maxX-x)/dx,minX
    else
        nearX,farX,planeX = (maxX-x)/dx,(minX-x)/dx,maxX
    end
    if dy == 0 then
        if y <= minY or y >= maxY then return nil end
    elseif dy > 0 then
        nearY,farY,planeY = (minY-y)/dy,(maxY-y)/dy,minY
    else
        nearY,farY,planeY = (maxY-y)/dy,(minY-y)/dy,maxY
    end
    local entry,exit = math.max(nearX,nearY),math.min(farX,farY)
    if entry < 0 or entry >= 1 or exit <= entry then return nil end
    if nearX < entry then planeX = nil end
    if nearY < entry then planeY = nil end
    return entry,planeX,planeY
end

local function earlier(best, blockX, blockY, time, planeX, planeY)
    if time < best then return time,planeX,planeY end
    if time == best then return best,blockX or planeX,blockY or planeY end
    return best,blockX,blockY
end

-- Swept center movement, without temporary tables or endpoint-only tunneling.
-- Boundary contacts remove only the remaining normal displacement; heading and
-- scalar speed response belong to Physics. At most two axes can be removed.
-- Starting overlaps recover to the nearest expanded face (ties: left, right,
-- bottom, top), retaining the requested displacement after recovery. Recovery
-- is bounded and guaranteed for these separate, perimeter-contained fixtures;
-- overlapping obstacle clusters require an authored recovery policy first.
function Track.resolveMovement(x, y, targetX, targetY)
    assert(finite(x) and finite(y) and finite(targetX) and finite(targetY),
        "finite track coordinates required")
    local dx,dy = targetX-x,targetY-y
    assert(finite(dx) and finite(dy), "finite track displacement required")
    local inset = Track.wallInset
    local hit
    x,y,hit = Track.constrainPosition(x,y)
    for _=1,4 do
        local recovered = false
        for i=1,#Track.obstacles do
            local box = Track.obstacles[i]
            local minX,maxX = box.x-inset,box.x+box.width+inset
            local minY,maxY = box.y-inset,box.y+box.height+inset
            if x > minX and x < maxX and y > minY and y < maxY then
                local distance,axis,plane = x-minX,"x",minX
                if maxX-x < distance then distance,axis,plane = maxX-x,"x",maxX end
                if y-minY < distance then distance,axis,plane = y-minY,"y",minY end
                if maxY-y < distance then axis,plane = "y",maxY end
                if axis == "x" then x = plane else y = plane end
                hit,recovered = true,true
            end
        end
        if not recovered then break end
    end
    for _=1,3 do
        if dx == 0 and dy == 0 then break end
        local best,blockX,blockY = 1,nil,nil
        if dx < 0 and x+dx < inset then
            best,blockX,blockY = earlier(best,blockX,blockY,(inset-x)/dx,inset,nil)
        elseif dx > 0 and x+dx > Track.width-inset then
            best,blockX,blockY = earlier(best,blockX,blockY,
                (Track.width-inset-x)/dx,Track.width-inset,nil)
        end
        if dy < 0 and y+dy < inset then
            best,blockX,blockY = earlier(best,blockX,blockY,(inset-y)/dy,nil,inset)
        elseif dy > 0 and y+dy > Track.height-inset then
            best,blockX,blockY = earlier(best,blockX,blockY,
                (Track.height-inset-y)/dy,nil,Track.height-inset)
        end
        for i=1,#Track.obstacles do
            local box = Track.obstacles[i]
            local time,planeX,planeY = sweepBox(x,y,dx,dy,box.x-inset,box.y-inset,
                box.x+box.width+inset,box.y+box.height+inset)
            if time then
                best,blockX,blockY = earlier(best,blockX,blockY,time,planeX,planeY)
            end
        end
        x,y = x+dx*best,y+dy*best
        if not blockX and not blockY then break end
        hit = true
        dx,dy = dx*(1-best),dy*(1-best)
        if blockX then x,dx = blockX,0 end
        if blockY then y,dy = blockY,0 end
    end
    return x,y,hit
end

function Track.spawn()
    return {x=Track.centerX + Track.lineX, y=Track.centerY, heading=math.pi/2}
end

if type(namespace) == "table" then namespace.Track = Track end
return Track
