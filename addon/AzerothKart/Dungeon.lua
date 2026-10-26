-- Open dungeon courses (the Scarlet Crusade Cup's sprints), independent of
-- clocks and WoW APIs.
--
-- A dungeon is its floor: axis-aligned rooms (halls, corridors, a chamber, a
-- cloister's lawns and paths), each "road" (stone) or "rough" (a lawn: the
-- rough ground Physics slows on), and round rooms (`shape="disc"`: the disc
-- inscribed in the room's square, such as a round library). There is no
-- road to follow. The kart
-- centre stays wallInset inside the union of the rooms (the walls stand a
-- kart's half-diagonal clear of it) and outside every solid box (a grave, a
-- tomb, a pillar) grown by the same inset, as the test oval's crates are,
-- and outside every round solid (`shape="disc"`: a round pool) grown so.
-- The gates, crossed in order, guard the doorways; the last is the finish.
-- `laps` sets the run's length (a sprint: one run to the last gate).
--
-- Solids use swept boxes or circles: a kart slides along a contact's tangent
-- and the contact counts as a hit, even if both movement endpoints are clear.
-- A step ending outside the floor moves back to the nearest allowed point no further from the
-- start than the step was long, so a kart slides along a wall (a round wall
-- too: its nearest point is along the radius) and round a round solid. Where rooms meet, their floors overlap by at least
-- twice the inset (a doorway): the union of the inset rooms is then open
-- from one to the other. Lookups use a 64-unit grid.
local _, namespace = ...
local Dungeon = {}

local CELL = 64
local MARGIN = 32        -- grid reach beyond a room or a solid; more than any one step
local SURFACES = {road="road", rough="grass"}

local function finite(value)
    return type(value) == "number" and value == value
        and value > -math.huge and value < math.huge
end

local function copyList(list)
    local out = {}
    for index,item in ipairs(list or {}) do
        local entry = {}
        for key,value in pairs(item) do entry[key] = value end
        out[index] = entry
    end
    return out
end

-- Entry time and blocking plane(s) of a swept centre through one expanded
-- box, or nil (Track.lua's sweep).
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

-- First entry into an expanded round solid, with its outward contact normal.
-- The stable quadratic root avoids subtracting nearly equal values for a
-- shallow grazing contact. Starting on the rim may block inward movement;
-- tangent/outward movement is free. Exact tangency does not enter the solid.
local function sweepDisc(x, y, dx, dy, disc)
    if disc.reach <= 0 then return nil end
    local px,py = x-disc.cx,y-disc.cy
    local a = dx*dx+dy*dy
    local b = px*dx+py*dy
    if a == 0 or b >= 0 then return nil end
    local c = px*px+py*py-disc.reachSquared
    local time = 0
    if c > 0 then
        local discriminant = b*b-a*c
        if discriminant <= 0 then return nil end
        time = c/(-b+math.sqrt(discriminant))
        if time < 0 or time >= 1 then return nil end
    end
    local nx,ny = px+dx*time,py+dy*time
    local length = math.sqrt(nx*nx+ny*ny)
    if length == 0 then return nil end -- invalid starts are recovered first
    return time,nx/length,ny/length
end

-- definition: {id, version, name, width, height, wallInset,
-- checkpointMaxStep (optional), laps (optional, 1-9),
-- rooms={{x,y,width,height,surface,shape}...} (surface "road" or "rough";
-- shape nil, "rect" or "disc", a disc's square with width == height),
-- solids={{id,x,y,width,height,shape}...} (shape as a room's: a round
-- solid is the disc in its square), gates={{name,ax,ay,bx,by,nx,ny}...},
-- spawn={x,y,heading}}. Bottom-left origin, as every track.
function Dungeon.new(definition, crossesGate)
    assert(type(definition) == "table", "dungeon definition required")
    assert(type(crossesGate) == "function", "directional gate predicate required")
    local d = definition
    assert(type(d.id) == "string" and finite(d.width) and d.width > 0 and finite(d.height) and d.height > 0
        and finite(d.wallInset) and d.wallInset >= 0 and type(d.rooms) == "table" and #d.rooms > 0
        and type(d.gates) == "table" and #d.gates > 0 and type(d.spawn) == "table",
        "complete dungeon geometry required")
    assert(d.laps == nil or (finite(d.laps) and d.laps >= 1 and d.laps <= 9 and d.laps % 1 == 0),
        "a dungeon's lap count must be an integer from 1 to 9")
    local inset = d.wallInset
    local track = {
        id=d.id, version=d.version or 1, name=d.name, width=d.width, height=d.height,
        wallInset=inset, checkpointMaxStep=d.checkpointMaxStep or 5, laps=d.laps,
        crossesGate=crossesGate,
        rooms=copyList(d.rooms), gates=copyList(d.gates), solids=copyList(d.solids),
    }
    -- The kart centre's floor: each room inset on every side (a round
    -- room's radius less the inset).
    local rooms = {}
    for index,room in ipairs(track.rooms) do
        assert(finite(room.x) and finite(room.y) and finite(room.width) and finite(room.height)
            and room.width > 2*inset and room.height > 2*inset, "a room wider than two insets required")
        assert(SURFACES[room.surface], "a room is road or rough")
        assert(room.shape == nil or room.shape == "rect" or (room.shape == "disc" and room.width == room.height),
            "a room is a rectangle, or a disc in its square")
        local r = {x0=room.x, y0=room.y, x1=room.x+room.width, y1=room.y+room.height,
            minX=room.x+inset, minY=room.y+inset, maxX=room.x+room.width-inset, maxY=room.y+room.height-inset,
            road=room.surface == "road", disc=room.shape == "disc"}
        if r.disc then
            r.cx, r.cy, r.radius = room.x+room.width/2, room.y+room.height/2, room.width/2
            r.reach = r.radius-inset
            r.reachSquared, r.radiusSquared = r.reach*r.reach, r.radius*r.radius
        end
        rooms[index] = r
    end
    local solids = {}
    local anyDisc = false
    for index,box in ipairs(track.solids) do
        assert(finite(box.x) and finite(box.y) and finite(box.width) and finite(box.height)
            and box.width >= 0 and box.height >= 0, "finite solid box required")
        assert(box.shape == nil or box.shape == "rect" or (box.shape == "disc" and box.width == box.height),
            "a solid is a box, or a disc in its square")
        local s = {x0=box.x, y0=box.y, x1=box.x+box.width, y1=box.y+box.height,
            minX=box.x-inset, minY=box.y-inset, maxX=box.x+box.width+inset, maxY=box.y+box.height+inset,
            disc=box.shape == "disc"}
        if s.disc then
            -- The kart centre keeps the inset outside the disc's rim.
            s.cx, s.cy, s.radius = box.x+box.width/2, box.y+box.height/2, box.width/2
            s.reach = s.radius+inset
            s.reachSquared, s.radiusSquared = s.reach*s.reach, s.radius*s.radius
            anyDisc = true
        end
        solids[index] = s
    end

    -- The grid: each cell lists the rooms and solids whose kart-centre
    -- bounds plus MARGIN reach it.
    local columns,rows = math.floor(track.width/CELL)+1,math.floor(track.height/CELL)+1
    local function register(cells, index, minX, minY, maxX, maxY)
        local x0 = math.max(0,math.floor((minX-MARGIN)/CELL))
        local x1 = math.min(columns-1,math.floor((maxX+MARGIN)/CELL))
        local y0 = math.max(0,math.floor((minY-MARGIN)/CELL))
        local y1 = math.min(rows-1,math.floor((maxY+MARGIN)/CELL))
        for row=y0,y1 do
            for column=x0,x1 do
                local key = row*columns+column+1
                local list = cells[key]
                if not list then list = {}; cells[key] = list end
                list[#list+1] = index
            end
        end
    end
    local roomCells,solidCells = {},{}
    for index,room in ipairs(rooms) do register(roomCells,index,room.x0,room.y0,room.x1,room.y1) end
    for index,box in ipairs(solids) do register(solidCells,index,box.minX,box.minY,box.maxX,box.maxY) end
    local function cellOf(cells, x, y)
        if x < 0 or y < 0 or x >= columns*CELL or y >= rows*CELL then return nil end
        return cells[math.floor(y/CELL)*columns+math.floor(x/CELL)+1]
    end

    -- The kart centre's floor of one room.
    local function inRoom(room, x, y)
        if x < room.minX or x > room.maxX or y < room.minY or y > room.maxY then return false end
        if not room.disc then return true end
        local dx,dy = x-room.cx,y-room.cy
        return dx*dx+dy*dy <= room.reachSquared
    end

    local function onFloor(x, y)
        local list = cellOf(roomCells,x,y)
        if not list then return false end
        for i=1,#list do
            if inRoom(rooms[list[i]],x,y) then return true end
        end
        return false
    end

    -- Inside one solid as the kart centre meets it: a box grown by the inset
    -- (its faces allowed), or a round solid's disc grown so (its rim allowed).
    local function insideSolid(box, x, y)
        if box.disc then
            local dx,dy = x-box.cx,y-box.cy
            return dx*dx+dy*dy < box.reachSquared
        end
        return x > box.minX and x < box.maxX and y > box.minY and y < box.maxY
    end

    local function inSolid(x, y)
        local list = cellOf(solidCells,x,y)
        if not list then return false end
        for i=1,#list do
            if insideSolid(solids[list[i]],x,y) then return true end
        end
        return false
    end

    -- Inside a round solid's reach (the swept boxes never end inside a box).
    local function inDisc(x, y)
        if not anyDisc then return false end
        local list = cellOf(solidCells,x,y)
        if not list then return false end
        for i=1,#list do
            local box = solids[list[i]]
            if box.disc and insideSolid(box,x,y) then return true end
        end
        return false
    end

    local function allowed(x, y)
        return x >= inset and x <= track.width-inset and y >= inset and y <= track.height-inset
            and onFloor(x,y) and not inSolid(x,y)
    end

    -- "road", "grass" (a lawn) or nil (off the floor): the painted floor
    -- under the kart's centre, stone wherever any stone room covers it.
    local function ground(x, y)
        local list = cellOf(roomCells,x,y)
        if not list then return nil end
        local rough = false
        for i=1,#list do
            local room = rooms[list[i]]
            if x >= room.x0 and x <= room.x1 and y >= room.y0 and y <= room.y1 then
                local inside = true
                if room.disc then
                    local dx,dy = x-room.cx,y-room.cy
                    inside = dx*dx+dy*dy <= room.radiusSquared
                end
                if inside then
                    if room.road then return "road" end
                    rough = true
                end
            end
        end
        return rough and "grass" or nil
    end

    -- One candidate for the nearest allowed point to (x, y); with a step
    -- bound, only points within it of the start count.
    local function candidate(px, py, x, y, startX, startY, maxStepSquared, bestX, bestY, best)
        if not allowed(px,py) then return bestX,bestY,best end
        if maxStepSquared then
            local sx,sy = px-startX,py-startY
            if sx*sx+sy*sy > maxStepSquared then return bestX,bestY,best end
        end
        local dx,dy = px-x,py-y
        local distance = dx*dx+dy*dy
        if not best or distance < best then return px,py,distance end
        return bestX,bestY,best
    end

    -- The nearest point of one room's inset floor to (x, y): clamped into a
    -- rectangle, or along the radius onto a round room's reach (a hair
    -- inside it, so rounding never leaves the point off the floor).
    local function roomPoint(room, x, y)
        if not room.disc then
            return math.max(room.minX,math.min(room.maxX,x)),math.max(room.minY,math.min(room.maxY,y))
        end
        local dx,dy = x-room.cx,y-room.cy
        local squared = dx*dx+dy*dy
        if squared <= room.reachSquared then return x,y end
        local k = (room.reach-1e-6)/math.sqrt(squared)
        return room.cx+dx*k,room.cy+dy*k
    end

    -- Points just outside a round solid's reach nearest (x, y): along the
    -- radius through it and, with a step bound, where the reach meets the
    -- circle of the step's length round the start (a radial point can lie
    -- a little beyond that bound when a kart only grazes the solid).
    local OUTSIDE = 1e-6
    local function discCandidates(box, px, py, x, y, startX, startY, maxStepSquared, bestX, bestY, best)
        local reach = box.reach+OUTSIDE
        local dx,dy = px-box.cx,py-box.cy
        local length = math.sqrt(dx*dx+dy*dy)
        if length > 0 then
            bestX,bestY,best = candidate(box.cx+dx*reach/length,box.cy+dy*reach/length,
                x,y,startX,startY,maxStepSquared,bestX,bestY,best)
        end
        if maxStepSquared and startX then
            local ex,ey = startX-box.cx,startY-box.cy
            local apart = math.sqrt(ex*ex+ey*ey)
            local step = math.sqrt(maxStepSquared)*(1-1e-9)
            if apart > 0 and apart <= reach+step and apart >= math.abs(reach-step) then
                local along = (reach*reach-step*step+apart*apart)/(2*apart)
                local across = reach*reach-along*along
                if across >= 0 then
                    across = math.sqrt(across)
                    local ux,uy = ex/apart,ey/apart
                    local mx,my = box.cx+ux*along,box.cy+uy*along
                    bestX,bestY,best = candidate(mx-uy*across,my+ux*across,x,y,startX,startY,maxStepSquared,
                        bestX,bestY,best)
                    bestX,bestY,best = candidate(mx+uy*across,my-ux*across,x,y,startX,startY,maxStepSquared,
                        bestX,bestY,best)
                end
            end
        end
        return bestX,bestY,best
    end

    -- The nearest allowed floor point to (x, y): each room's nearest inset
    -- point or, where that lies inside a grown solid, the solid's faces (a
    -- round solid's reach). Searches the start cell's rooms, or every room
    -- when `anywhere`.
    local function nearestFloor(x, y, anywhere, startX, startY, maxStepSquared)
        local list = cellOf(roomCells,startX or x,startY or y)
        local count = anywhere and #rooms or (list and #list or 0)
        local bestX,bestY,best
        for i=1,count do
            local room = rooms[anywhere and i or list[i]]
            local px,py = roomPoint(room,x,y)
            if inSolid(px,py) then
                for k=1,#solids do
                    local box = solids[k]
                    if insideSolid(box,px,py) then
                        if box.disc then
                            bestX,bestY,best = discCandidates(box,px,py,x,y,startX,startY,maxStepSquared,
                                bestX,bestY,best)
                        else
                            bestX,bestY,best = candidate(box.minX,py,x,y,startX,startY,maxStepSquared,bestX,bestY,best)
                            bestX,bestY,best = candidate(box.maxX,py,x,y,startX,startY,maxStepSquared,bestX,bestY,best)
                            bestX,bestY,best = candidate(px,box.minY,x,y,startX,startY,maxStepSquared,bestX,bestY,best)
                            bestX,bestY,best = candidate(px,box.maxY,x,y,startX,startY,maxStepSquared,bestX,bestY,best)
                        end
                    end
                end
            else
                bestX,bestY,best = candidate(px,py,x,y,startX,startY,maxStepSquared,bestX,bestY,best)
            end
        end
        return bestX,bestY
    end

    function track.isDrivable(x, y)
        if not finite(x) or not finite(y) then return false end
        return allowed(x,y) and ground(x,y) == "road"
    end

    function track.surfaceAt(x, y)
        if not finite(x) or not finite(y) then return "wall" end
        if x < inset or x > track.width-inset or y < inset or y > track.height-inset then return "wall" end
        local list = cellOf(solidCells,x,y)
        for i=1,(list and #list or 0) do
            local box = solids[list[i]]
            if box.disc then
                local dx,dy = x-box.cx,y-box.cy
                if dx*dx+dy*dy <= box.radiusSquared then return "wall" end
            elseif x >= box.x0 and x <= box.x1 and y >= box.y0 and y <= box.y1 then
                return "wall"
            end
        end
        if not onFloor(x,y) then return "wall" end
        return ground(x,y) or "wall"
    end

    function track.constrainPosition(x, y)
        assert(finite(x) and finite(y), "finite track coordinates required")
        local cx = math.max(inset,math.min(track.width-inset,x))
        local cy = math.max(inset,math.min(track.height-inset,y))
        return cx,cy,cx ~= x or cy ~= y
    end

    local spawnX,spawnY,spawnHeading = d.spawn.x,d.spawn.y,d.spawn.heading
    assert(finite(spawnX) and finite(spawnY) and finite(spawnHeading) and allowed(spawnX,spawnY),
        "the spawn stands on the floor, clear of every solid")

    -- A centre off the floor or inside a grown solid (never by driving)
    -- moves to the nearest allowed floor point, or back to the spawn.
    local function recover(x, y)
        if allowed(x,y) then return x,y,false end
        local px,py = nearestFloor(x,y,true)
        if px then return px,py,true end
        return spawnX,spawnY,true
    end

    -- Swept centre movement with the perimeter and nearby solid boxes/discs.
    -- Contacts remove only remaining inward-normal displacement (Physics
    -- scrubs speed). A bounded extra contact loop permits circle/box corners;
    -- discarded remainder cannot tunnel when that bound is exhausted. The
    -- room-floor correction remains within the original step's length.
    function track.resolveMovement(x, y, targetX, targetY)
        assert(finite(x) and finite(y) and finite(targetX) and finite(targetY),
            "finite track coordinates required")
        local dx,dy = targetX-x,targetY-y
        assert(finite(dx) and finite(dy), "finite track displacement required")
        local hit, recovered
        x,y,hit = track.constrainPosition(x,y)
        x,y,recovered = recover(x,y)
        hit = hit or recovered
        local startX,startY = x,y
        -- A step within half the margin meets only the start cell's solids.
        local near = math.abs(dx) <= MARGIN/2 and math.abs(dy) <= MARGIN/2
        local list = near and cellOf(solidCells,x,y) or nil
        local count = near and (list and #list or 0) or #solids
        for _=1,(anyDisc and 8 or 3) do
            if dx == 0 and dy == 0 then break end
            local best,blockX,blockY = 1,nil,nil
            local normalX,normalY
            if dx < 0 and x+dx < inset then
                best,blockX,blockY = earlier(best,blockX,blockY,(inset-x)/dx,inset,nil)
            elseif dx > 0 and x+dx > track.width-inset then
                best,blockX,blockY = earlier(best,blockX,blockY,(track.width-inset-x)/dx,track.width-inset,nil)
            end
            if dy < 0 and y+dy < inset then
                best,blockX,blockY = earlier(best,blockX,blockY,(inset-y)/dy,nil,inset)
            elseif dy > 0 and y+dy > track.height-inset then
                best,blockX,blockY = earlier(best,blockX,blockY,(track.height-inset-y)/dy,nil,track.height-inset)
            end
            for i=1,count do
                local box = solids[near and list[i] or i]
                if box.disc then
                    local time,nx,ny = sweepDisc(x,y,dx,dy,box)
                    if time and time < best then
                        best,blockX,blockY,normalX,normalY = time,nil,nil,nx,ny
                    end
                else
                    local time,planeX,planeY = sweepBox(x,y,dx,dy,box.minX,box.minY,box.maxX,box.maxY)
                    if time and time <= best then
                        best,blockX,blockY = earlier(best,blockX,blockY,time,planeX,planeY)
                        normalX,normalY = nil,nil
                    end
                end
            end
            -- Stop a nanounit before a circle's entry along the already-clear
            -- incoming segment. An outward radial nudge could instead put the
            -- centre inside a neighbouring box at a shared corner.
            local travel = best
            if normalX then travel = math.max(0,best-1e-9/math.sqrt(dx*dx+dy*dy)) end
            x,y = x+dx*travel,y+dy*travel
            if not blockX and not blockY and not normalX then break end
            hit = true
            dx,dy = dx*(1-best),dy*(1-best)
            if blockX then x,dx = blockX,0 end
            if blockY then y,dy = blockY,0 end
            if normalX then
                local inward = dx*normalX+dy*normalY
                if inward < 0 then
                    dx,dy = dx-inward*normalX,dy-inward*normalY
                end
            end
        end
        if not onFloor(x,y) or inDisc(x,y) then
            hit = true
            local stepX,stepY = targetX-startX,targetY-startY
            local stepSquared = stepX*stepX+stepY*stepY
            local px,py = nearestFloor(x,y,not near,startX,startY,stepSquared)
            if px then x,y = px,py else x,y = startX,startY end
        end
        return x,y,hit
    end

    function track.spawn()
        return {x=spawnX,y=spawnY,heading=spawnHeading}
    end
    return track
end

if type(namespace) == "table" then namespace.Dungeon = Dungeon end
return Dungeon
