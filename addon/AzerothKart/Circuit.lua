-- Data-defined city circuits (the Capital Cities Cup), independent of clocks
-- and WoW APIs.
--
-- The road is Mirage Raceway's capsule road: every point within roadRadius
-- of the road network (a closed centerline plus open branches, such as a
-- start grid's approach). A city circuit is a street circuit: with
-- wallRadius, the kart centre stays within wallRadius of that network (a
-- rough kerb-side strip beyond the paving) or inside a plaza, and everything
-- else is wall: the buildings, canal parapets and district walls the scenery
-- draws there. Plazas are paved capsules (an open square the course runs
-- through). Solids are axis-aligned boxes inside the drivable area (a
-- fountain on a plaza). Without wallRadius the ground beyond the road is
-- rough, as on Mirage Raceway, bounded only by the perimeter and solids.
--
-- Solid boxes use Track's swept-box resolution for the test oval. The street
-- walls are smooth: a step ending outside the drivable area is moved back to
-- the nearest drivable point, so a kart slides along a curving wall, and the
-- contact counts as a hit (Physics scrubs speed). Lookups use a 64-unit grid.
local _, namespace = ...
local Circuit = {}

local CELL = 64
local MARGIN = 32        -- grid reach beyond a capsule; more than any one step

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
-- box, or nil (Track.lua's sweep, for the test oval's crates).
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

-- Squared distance from (x, y) to a capsule's axis and the nearest axis point.
local function axisDistance(p, x, y)
    local t = 0
    if p.lengthSquared > 0 then
        t = ((x-p.x)*p.dx+(y-p.y)*p.dy)/p.lengthSquared
        if t < 0 then t = 0 elseif t > 1 then t = 1 end
    end
    local cx,cy = p.x+t*p.dx,p.y+t*p.dy
    local ex,ey = x-cx,y-cy
    return ex*ex+ey*ey,cx,cy
end

-- definition: {id, version, name, width, height, wallInset, roadRadius,
-- wallRadius (optional), fullSpeedToWalls (optional boolean), centerline={{x,y}...} (closed), branches=
-- {{{x,y}...}...} (open), plazas={{ax,ay,bx,by,radius}...} (optional, with
-- wallRadius), gates={{name,ax,ay,bx,by,nx,ny}...}, spawn={x,y,heading},
-- solids={{id,x,y,width,height}...}}.
function Circuit.new(definition, crossesGate)
    assert(type(definition) == "table", "circuit definition required")
    assert(type(crossesGate) == "function", "directional gate predicate required")
    local d = definition
    assert(type(d.id) == "string" and finite(d.width) and finite(d.height) and finite(d.roadRadius)
        and finite(d.wallInset) and type(d.centerline) == "table" and #d.centerline >= 3
        and type(d.gates) == "table" and #d.gates > 0 and type(d.spawn) == "table",
        "complete circuit geometry required")
    assert(d.fullSpeedToWalls == nil or type(d.fullSpeedToWalls) == "boolean",
        "fullSpeedToWalls must be boolean")
    local fullSpeedToWalls = d.fullSpeedToWalls == true
    local corridor = d.wallRadius ~= nil
    assert(not corridor or (finite(d.wallRadius) and d.wallRadius >= d.roadRadius),
        "wall radius must enclose the road")
    assert(corridor or d.plazas == nil, "plazas need street walls")
    local track = {
        id=d.id, version=d.version or 1, name=d.name, width=d.width, height=d.height,
        wallInset=d.wallInset, checkpointMaxStep=d.checkpointMaxStep or 5,
        roadWidth=2*d.roadRadius, roadRadius=d.roadRadius, wallRadius=d.wallRadius,
        fullSpeedToWalls=fullSpeedToWalls,
        crossesGate=crossesGate,
        centerline=copyList(d.centerline), gates=copyList(d.gates), solids=copyList(d.solids),
        plazas=copyList(d.plazas),
    }
    local spawnX,spawnY,spawnHeading = d.spawn.x,d.spawn.y,d.spawn.heading
    local inset = track.wallInset
    local solids = track.solids
    local reach = d.wallRadius or d.roadRadius

    -- Capsules: each road segment (paved to roadRadius, drivable to wallRadius)
    -- and each plaza (paved and drivable to its radius).
    local capsules, length = {}, 0
    local function add(ax, ay, bx, by, paved, drivable)
        local dx,dy = bx-ax,by-ay
        capsules[#capsules+1] = {x=ax, y=ay, dx=dx, dy=dy, lengthSquared=dx*dx+dy*dy,
            paved=paved*paved, drivable=drivable*drivable, radius=drivable}
        return math.sqrt(dx*dx+dy*dy)
    end
    local line = track.centerline
    for index=1,#line do
        local a,b = line[index],line[index%#line+1]
        if a.x ~= b.x or a.y ~= b.y then
            length = length+add(a.x,a.y,b.x,b.y,d.roadRadius,reach)
        end
    end
    track.length = length
    track.branches = {}
    for branchIndex,branch in ipairs(d.branches or {}) do
        track.branches[branchIndex] = copyList(branch)
        for index=2,#branch do
            local a,b = branch[index-1],branch[index]
            if a.x ~= b.x or a.y ~= b.y then add(a.x,a.y,b.x,b.y,d.roadRadius,reach) end
        end
    end
    for _,plaza in ipairs(track.plazas) do
        assert(finite(plaza.ax) and finite(plaza.ay) and finite(plaza.bx) and finite(plaza.by)
            and finite(plaza.radius) and plaza.radius > 0, "plaza capsule required")
        add(plaza.ax,plaza.ay,plaza.bx,plaza.by,plaza.radius,plaza.radius)
    end

    -- The grid: each cell lists the capsules whose drivable radius plus
    -- MARGIN reaches it.
    local columns,rows = math.floor(track.width/CELL)+1,math.floor(track.height/CELL)+1
    local cells = {}
    for index,c in ipairs(capsules) do
        local r = c.radius+MARGIN
        local x0 = math.max(0,math.floor((math.min(c.x,c.x+c.dx)-r)/CELL))
        local x1 = math.min(columns-1,math.floor((math.max(c.x,c.x+c.dx)+r)/CELL))
        local y0 = math.max(0,math.floor((math.min(c.y,c.y+c.dy)-r)/CELL))
        local y1 = math.min(rows-1,math.floor((math.max(c.y,c.y+c.dy)+r)/CELL))
        for row=y0,y1 do
            for column=x0,x1 do
                local key = row*columns+column+1
                local list = cells[key]
                if not list then list = {}; cells[key] = list end
                list[#list+1] = index
            end
        end
    end
    local function near(x, y)
        if x < 0 or y < 0 or x >= columns*CELL or y >= rows*CELL then return nil end
        return cells[math.floor(y/CELL)*columns+math.floor(x/CELL)+1]
    end

    -- "road", "rough" or nil (outside every capsule).
    local function ground(x, y)
        local list = near(x,y)
        if not list then return nil end
        local rough = false
        for i=1,#list do
            local c = capsules[list[i]]
            local distance = axisDistance(c,x,y)
            if distance <= c.paved then return "road" end
            if distance <= c.drivable then rough = true end
        end
        -- Surface policy only: preserve the painted paving and wall radii.
        return rough and (fullSpeedToWalls and "road" or "rough") or nil
    end

    local function inSolid(x, y, grow)
        for i=1,#solids do
            local box = solids[i]
            if x > box.x-grow and x < box.x+box.width+grow
                and y > box.y-grow and y < box.y+box.height+grow then return true end
        end
        return false
    end

    -- The nearest drivable point to (x, y) (just inside a capsule's wall),
    -- searching the grid cell's capsules, or every capsule when `anywhere`.
    local function nearestDrivable(x, y, anywhere)
        local list = near(x,y)
        local count = list and #list or 0
        if anywhere then count = #capsules end
        local bestX,bestY,best
        for i=1,count do
            local c = capsules[anywhere and i or list[i]]
            local distance,cx,cy = axisDistance(c,x,y)
            local gap = math.sqrt(distance)-c.radius
            if not best or gap < best then
                if distance <= 0 then
                    bestX,bestY = cx,cy
                else
                    local k = (c.radius-0.001)/math.sqrt(distance)
                    bestX,bestY = cx+(x-cx)*k,cy+(y-cy)*k
                end
                best = gap
            end
        end
        return bestX,bestY
    end

    -- Road grip covers the paving, or the whole corridor when requested.
    -- Other circuits retain the existing rough shoulder response.
    function track.isDrivable(x,y)
        if not finite(x) or not finite(y) then return false end
        return ground(x,y) == "road"
    end

    function track.surfaceAt(x,y)
        if not finite(x) or not finite(y) then return "wall" end
        if x < inset or x > track.width-inset or y < inset or y > track.height-inset then
            return "wall"
        end
        for i=1,#solids do
            local box = solids[i]
            if x >= box.x and x <= box.x+box.width
                and y >= box.y and y <= box.y+box.height then return "wall" end
        end
        local found = ground(x,y)
        if found == "road" then return "road" end
        if found == "rough" or not corridor then return "grass" end
        return "wall"
    end

    function track.constrainPosition(x,y)
        assert(finite(x) and finite(y), "finite track coordinates required")
        local cx = math.max(inset,math.min(track.width-inset,x))
        local cy = math.max(inset,math.min(track.height-inset,y))
        return cx,cy,cx ~= x or cy ~= y
    end

    local function allowed(x, y)
        return x >= inset and x <= track.width-inset and y >= inset and y <= track.height-inset
            and not inSolid(x,y,inset) and (not corridor or ground(x,y) ~= nil)
    end

    -- A centre that starts inside an expanded box (never by driving: the
    -- sweep stops at its faces) moves to the nearest face point that is
    -- outside every expanded box, inside the perimeter and (with street
    -- walls) drivable. Adjacent boxes cannot trap it. Ties prefer the earlier
    -- box and face (left, right, bottom, top). With no such point the kart
    -- returns to the spawn. A centre outside the street walls moves to the
    -- nearest drivable point.
    local function recover(x,y)
        if corridor and ground(x,y) == nil then
            local px,py = nearestDrivable(x,y,true)
            if px and allowed(px,py) then return px,py,true end
            return spawnX,spawnY,true
        end
        local bestX,bestY,best
        local trapped = false
        for i=1,#solids do
            local box = solids[i]
            local minX,maxX = box.x-inset,box.x+box.width+inset
            local minY,maxY = box.y-inset,box.y+box.height+inset
            if x > minX and x < maxX and y > minY and y < maxY then
                trapped = true
                local faces = {{minX,y},{maxX,y},{x,minY},{x,maxY}}
                for _,face in ipairs(faces) do
                    local fx,fy = face[1],face[2]
                    local distance = math.abs(fx-x)+math.abs(fy-y)
                    if allowed(fx,fy) and (not best or distance < best) then
                        bestX,bestY,best = fx,fy,distance
                    end
                end
            end
        end
        if not trapped then return x,y,false end
        if best then return bestX,bestY,true end
        return spawnX,spawnY,true
    end

    -- Swept centre movement with the perimeter and every solid; contacts
    -- remove only the remaining normal displacement (Physics scrubs speed).
    -- Then the street walls: an end point outside them moves to the nearest
    -- drivable point, never further from the start than the step was long.
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
        for _=1,3 do
            if dx == 0 and dy == 0 then break end
            local best,blockX,blockY = 1,nil,nil
            if dx < 0 and x+dx < inset then
                best,blockX,blockY = earlier(best,blockX,blockY,(inset-x)/dx,inset,nil)
            elseif dx > 0 and x+dx > track.width-inset then
                best,blockX,blockY = earlier(best,blockX,blockY,
                    (track.width-inset-x)/dx,track.width-inset,nil)
            end
            if dy < 0 and y+dy < inset then
                best,blockX,blockY = earlier(best,blockX,blockY,(inset-y)/dy,nil,inset)
            elseif dy > 0 and y+dy > track.height-inset then
                best,blockX,blockY = earlier(best,blockX,blockY,
                    (track.height-inset-y)/dy,nil,track.height-inset)
            end
            for i=1,#solids do
                local box = solids[i]
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
        if corridor and ground(x,y) == nil then
            hit = true
            local px,py = nearestDrivable(x,y,false)
            local stepX,stepY = targetX-startX,targetY-startY
            local moveX,moveY = (px or startX)-startX,(py or startY)-startY
            if px and allowed(px,py)
                and moveX*moveX+moveY*moveY <= stepX*stepX+stepY*stepY then
                x,y = px,py
            else
                x,y = startX,startY
            end
        end
        return x,y,hit
    end

    function track.spawn()
        return {x=spawnX,y=spawnY,heading=spawnHeading}
    end
    return track
end

if type(namespace) == "table" then namespace.Circuit = Circuit end
return Circuit
