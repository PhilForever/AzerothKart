-- Two discrete floors over the existing Dungeon solver. Ramps reserve their
-- footprint, so occupancy is unambiguous without a second kart/ramp state.
-- No height/airborne physics, clock, renderer or WoW API dependency.
local _, AK = ...
local LayeredTrack = {MAX_STEP=16}
local EPS = 1e-7

local function finite(n)
    return type(n)=="number" and n==n and n>-math.huge and n<math.huge
end
local function level(n) return n==0 or n==1 end
local function floorOf(n) if n==nil then return 0 end; return n end
local function copy(value)
    local out={}
    for key,item in pairs(value or {}) do out[key]=item end
    return out
end
local function list(value)
    local out={}
    for i,item in ipairs(value or {}) do out[i]=copy(item) end
    return out
end
local function inside(r,x,y)
    return x>=r.minX and x<=r.maxX and y>=r.minY and y<=r.maxY
end
local function distanceToRect(x,y,minX,minY,maxX,maxY)
    local dx=math.max(minX-x,0,x-maxX)
    local dy=math.max(minY-y,0,y-maxY)
    return math.sqrt(dx*dx+dy*dy)
end
local function overlaps(a,b)
    return a.x<b.x+b.width and b.x<a.x+a.width
        and a.y<b.y+b.height and b.y<a.y+a.height
end

-- First entry to the usable ramp corridor, with the crossed coordinate axis.
-- Touching a corner alone does not enter. Starting points are outside here.
local function entry(r,x,y,dx,dy)
    local tx0,tx1,ty0,ty1=-math.huge,math.huge,-math.huge,math.huge
    if dx==0 then if x<r.minX or x>r.maxX then return nil end
    elseif dx>0 then tx0,tx1=(r.minX-x)/dx,(r.maxX-x)/dx
    else tx0,tx1=(r.maxX-x)/dx,(r.minX-x)/dx end
    if dy==0 then if y<r.minY or y>r.maxY then return nil end
    elseif dy>0 then ty0,ty1=(r.minY-y)/dy,(r.maxY-y)/dy
    else ty0,ty1=(r.maxY-y)/dy,(r.minY-y)/dy end
    local near,far=math.max(tx0,ty0),math.min(tx1,ty1)
    if near<0 or near>1 or far<=near then return nil end
    return near,tx0>=ty0 and "x" or "y"
end

function LayeredTrack.new(d,crossesGate)
    assert(type(d)=="table" and type(AK.Dungeon)=="table","layered definition and Dungeon required")
    assert(type(d.rooms)=="table" and #d.rooms>0 and type(d.ramps)=="table" and #d.ramps>0,
        "two-floor rooms and at least one ramp required")
    assert(finite(d.wallInset) and d.wallInset>=0 and type(d.spawn)=="table","layered inset/spawn required")
    local inset=d.wallInset
    local ramps,ids={},{}
    for _,raw in ipairs(d.ramps) do
        local r=copy(raw)
        assert(type(r.id)=="string" and #r.id>0 and not ids[r.id],"unique ramp id required")
        ids[r.id]=true
        assert(finite(r.x) and finite(r.y) and finite(r.width) and finite(r.height)
            and r.width>2*inset and r.height>2*inset,"finite ramp wider than two insets required")
        assert(r.axis=="x" or r.axis=="y","ramp axis x or y required")
        if r.ascending==nil then r.ascending=1 end
        if r.lowLevel==nil then r.lowLevel=0 end
        if r.highLevel==nil then r.highLevel=1 end
        assert((r.ascending==1 or r.ascending==-1) and r.lowLevel==0 and r.highLevel==1,
            "ramp joins floor0 to floor1, ascending1 or -1")
        local length=r.axis=="x" and r.width or r.height
        assert(length>=2*LayeredTrack.MAX_STEP,"ramp length must be at least32")
        r.minX,r.maxX=r.x+inset,r.x+r.width-inset
        r.minY,r.maxY=r.y+inset,r.y+r.height-inset
        if r.axis=="x" then r.minX,r.maxX=r.x,r.x+r.width
        else r.minY,r.maxY=r.y,r.y+r.height end
        local interior=copy(r)
        if r.axis=="x" then interior.x,interior.width=r.x+2*inset,r.width-4*inset
        else interior.y,interior.height=r.y+2*inset,r.height-4*inset end
        -- The exclusive interior must remain nonempty; end overlap is only
        -- the normal Dungeon doorway overlap, not another drivable floor.
        assert(interior.width>0 and interior.height>0,"ramp needs a reserved interior beyond its joins")
        for _,room in ipairs(d.rooms) do
            assert(level(floorOf(room.level)),"room level must be0 or1")
            assert(not overlaps(interior,room),"ordinary floor overlaps reserved ramp interior")
        end
        for _,solid in ipairs(d.solids or {}) do
            assert(level(floorOf(solid.level)),"solid level must be0 or1")
            local grown={x=solid.x-inset,y=solid.y-inset,width=solid.width+2*inset,height=solid.height+2*inset}
            assert(not overlaps(grown,{x=r.minX,y=r.minY,width=r.maxX-r.minX,height=r.maxY-r.minY}),
                "solid blocks the usable ramp corridor")
        end
        for _,prior in ipairs(ramps) do
            local dx=math.max(prior.minX-r.maxX,r.minX-prior.maxX,0)
            local dy=math.max(prior.minY-r.maxY,r.minY-prior.maxY,0)
            assert(dx*dx+dy*dy>(LayeredTrack.MAX_STEP+EPS)^2,"ramps need more than a16unit gap")
        end
        ramps[#ramps+1]=r
    end

    local floors={}
    for floor=0,1 do
        local rooms,solids={},{}
        for _,room in ipairs(d.rooms) do if (floorOf(room.level))==floor then rooms[#rooms+1]=copy(room) end end
        assert(#rooms>0,"each floor needs an ordinary room")
        for _,solid in ipairs(d.solids or {}) do
            assert(level(floorOf(solid.level)),"solid level must be0 or1")
            if (floorOf(solid.level))==floor then solids[#solids+1]=copy(solid) end
        end
        for _,r in ipairs(ramps) do
            local room={x=r.x,y=r.y,width=r.width,height=r.height,surface="road"}
            -- Extend only the longitudinal painted footprint: its inset
            -- centre floor reaches the exact end plane, avoiding a hidden lip.
            if r.axis=="x" then room.x,room.width=room.x-inset,room.width+2*inset
            else room.y,room.height=room.y-inset,room.height+2*inset end
            rooms[#rooms+1]=room
        end
        local first=ramps[1]
        local spawn={x=(first.minX+first.maxX)/2,y=(first.minY+first.maxY)/2,heading=0}
        floors[floor]=AK.Dungeon.new({id=d.id,version=d.version,name=d.name,width=d.width,height=d.height,
            wallInset=inset,checkpointMaxStep=d.checkpointMaxStep,laps=d.laps,
            rooms=rooms,solids=solids,gates=d.gates,spawn=spawn},crossesGate)
    end
    local function clear(floor,x,y)
        local nx,ny=floors[floor].resolveMovement(x,y,x,y)
        return math.abs(nx-x)<EPS and math.abs(ny-y)<EPS
    end
    for _,r in ipairs(ramps) do
        local minQ=r.axis=="x" and r.minX or r.minY
        local maxQ=r.axis=="x" and r.maxX or r.maxY
        local middle=r.axis=="x" and (r.minY+r.maxY)/2 or (r.minX+r.maxX)/2
        local lowQ=r.ascending==1 and minQ or maxQ
        local highQ=r.ascending==1 and maxQ or minQ
        local lowX,lowY=r.axis=="x" and lowQ or middle,r.axis=="x" and middle or lowQ
        local highX,highY=r.axis=="x" and highQ or middle,r.axis=="x" and middle or highQ
        -- Check the real floor just beyond either end, not the shared ramp's
        -- synthetic doorway. Its correct floor must genuinely connect there.
        local outward=0.01
        local lx,ly=lowX,lowY; local hx,hy=highX,highY
        if r.axis=="x" then lx,hx=lx-r.ascending*outward,hx+r.ascending*outward
        else ly,hy=ly-r.ascending*outward,hy+r.ascending*outward end
        assert(clear(0,lx,ly) and clear(1,hx,hy),"ramp ends must connect their actual floors")
    end
    local spawn=copy(d.spawn); spawn.level=floorOf(spawn.level)
    assert(level(spawn.level) and clear(spawn.level,spawn.x,spawn.y),"spawn needs its own clear floor")
    for _,r in ipairs(ramps) do assert(not inside(r,spawn.x,spawn.y),"spawn must be outside ramps") end
    for _,gate in ipairs(d.gates) do
        local l=floorOf(gate.level)
        assert(level(l),"gate level must be0 or1")
        local x,y=(gate.ax+gate.bx)/2,(gate.ay+gate.by)/2
        assert(clear(l,x,y),"gate centre must lie on its own floor")
        for _,r in ipairs(ramps) do
            local margin=d.checkpointMaxStep or 5
            local gateBox={x=math.min(gate.ax,gate.bx)-margin,y=math.min(gate.ay,gate.by)-margin,
                width=math.abs(gate.bx-gate.ax)+2*margin,height=math.abs(gate.by-gate.ay)+2*margin}
            assert(not overlaps(gateBox,{x=r.minX,y=r.minY,width=r.maxX-r.minX,height=r.maxY-r.minY}),
                "entire gate must be beyond ramp transition step")
        end
    end
    for _,pad in ipairs(d.pads or {}) do
        assert(finite(pad.x) and finite(pad.y) and finite(pad.radius) and pad.radius>0
            and level(floorOf(pad.level)),"pad needs finite disc and its own level")
        assert(clear(floorOf(pad.level),pad.x,pad.y),"pad centre must lie on its own floor")
        for _,r in ipairs(ramps) do
            assert(distanceToRect(pad.x,pad.y,r.minX,r.minY,r.maxX,r.maxY)>pad.radius+LayeredTrack.MAX_STEP,
                "pad disc must be16units clear of ramp")
        end
    end
    local track={id=d.id,version=d.version or 1,name=d.name,width=d.width,height=d.height,
        wallInset=inset,checkpointMaxStep=d.checkpointMaxStep or 5,laps=d.laps,
        layered=true,levelCount=2,rooms=list(d.rooms),solids=list(d.solids),gates=list(d.gates),
        ramps=list(d.ramps),pads=list(d.pads),crossesGate=crossesGate,validLevel=level}
    function track.spawn() return copy(spawn) end
    function track.isDrivable(x,y,l)
        l=floorOf(l)
        return level(l) and floors[l].isDrivable(x,y) or false
    end
    function track.surfaceAt(x,y,l)
        l=floorOf(l)
        return level(l) and floors[l].surfaceAt(x,y) or "wall"
    end
    function track.constrainPosition(x,y,l)
        l=floorOf(l); assert(level(l),"level0 or1 required")
        return floors[l].constrainPosition(x,y)
    end
    function track.resolveMovement(x,y,tx,ty,l)
        l=floorOf(l)
        assert(level(l) and finite(x) and finite(y) and finite(tx) and finite(ty),"finite movement and level0/1 required")
        local dx,dy=tx-x,ty-y
        if not finite(dx) or not finite(dy) or dx*dx+dy*dy>LayeredTrack.MAX_STEP^2+1e-8 then return x,y,true,l end
        local current
        for _,r in ipairs(ramps) do if inside(r,x,y) then current=r; break end end
        if current then
            local r=current
            -- The transverse faces are always walls; no side-entry/side-exit
            -- can silently pick another overlapping floor.
            local clamped=false
            if r.axis=="x" then
                local nextY=math.max(r.minY,math.min(r.maxY,ty)); clamped=nextY~=ty; ty=nextY
            else
                local nextX=math.max(r.minX,math.min(r.maxX,tx)); clamped=nextX~=tx; tx=nextX
            end
            dx,dy=tx-x,ty-y
            local q,tq=r.axis=="x" and x or y,r.axis=="x" and tx or ty
            local minQ,maxQ=r.axis=="x" and r.minX or r.minY,r.axis=="x" and r.maxX or r.maxY
            local endQ=tq>maxQ and maxQ or (tq<minQ and minQ or nil)
            if endQ then
                local fraction=(endQ-q)/(tq-q)
                local sx,sy=x+dx*fraction,y+dy*fraction
                local nx,ny,hit=floors[l].resolveMovement(x,y,sx,sy)
                if math.abs(nx-sx)>EPS or math.abs(ny-sy)>EPS then return nx,ny,true,l end
                local nextLevel=((endQ==maxQ)==(r.ascending==1)) and 1 or 0
                if not clear(nextLevel,sx,sy) then return nx,ny,true,l end
                nx,ny,hit=floors[nextLevel].resolveMovement(sx,sy,tx,ty)
                if nextLevel~=l then return nx,ny,hit or clamped,nextLevel,sx,sy end
                return nx,ny,hit or clamped,l
            end
            local nx,ny,hit=floors[l].resolveMovement(x,y,tx,ty)
            return nx,ny,hit or clamped,l
        end
        for _,r in ipairs(ramps) do
            local time,axis=entry(r,x,y,dx,dy)
            if time then
                local ex,ey=x+dx*time,y+dy*time
                local q=r.axis=="x" and ex or ey
                local minQ,maxQ=r.axis=="x" and r.minX or r.minY,r.axis=="x" and r.maxX or r.maxY
                local entryLevel=((math.abs(q-maxQ)<EPS)==(r.ascending==1)) and 1 or 0
                if axis~=r.axis or entryLevel~=l then
                    local distance=math.sqrt(dx*dx+dy*dy)
                    local t=math.max(0,time-(distance>0 and EPS/distance or 0))
                    local nx,ny=floors[l].resolveMovement(x,y,x+dx*t,y+dy*t)
                    -- Dungeon's nearest-floor correction can otherwise pick
                    -- the ramp side across a narrow gap. A virtual entry wall
                    -- must not leave the kart inside the prohibited corridor.
                    if inside(r,nx,ny) then return x,y,true,l end
                    return nx,ny,true,l
                end
            end
        end
        local nx,ny,hit=floors[l].resolveMovement(x,y,tx,ty)
        return nx,ny,hit,l
    end
    return track
end

AK.LayeredTrack=LayeredTrack
return LayeredTrack
