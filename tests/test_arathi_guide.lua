-- The guide is presentation only: use the real Arathi collision resolver to
-- check both legitimate ways around the Stables, including the original bug.
local AK = {}
for _,name in ipairs({"Track", "MirageRaceway", "Circuit", "CapitalCities", "Dungeon", "ScarletCrusade",
    "LayeredTrack", "Battlegrounds", "ArathiGrass", "Courses", "Physics", "Checkpoints", "Presentation"}) do
    assert(loadfile("addon/AzerothKart/"..name..".lua"))("AzerothKart", AK)
end
-- Claude pin (Arathi version 2): the owner keeps the guiding arrow for
-- Warsong Gulch alone, so Arathi hands no route to the arrow and its yard is
-- a meadow of slow grass. This regression of the guide round a solid keeps
-- Arathi's real geometry with the Stables' yard paved, as version 1 had it,
-- and the reviewed route from its data.
local definition = {}
for key,value in pairs(AK.Battlegrounds.arathi_basin) do definition[key] = value end
definition.plazas = {}
for index,plaza in ipairs(AK.Battlegrounds.arathi_basin.plazas) do
    definition.plazas[index] = {ax=plaza.ax, ay=plaza.ay, bx=plaza.bx, by=plaza.by, radius=plaza.radius}
end
assert(AK.Courses.route("arathi_basin") == nil, "Arathi Basin hands no route to the arrow")
local track = AK.Circuit.new(definition, AK.Track.crossesGate)
local route = {points=definition.route, gates=definition.routeGates}
local progress = {passed=2, nextGate=3, complete=false}

local function clearRay(x, y, heading, length)
    for k=1,math.ceil(length/2) do
        local step = math.min(2, length-(k-1)*2)
        local nx,ny,hit = track.resolveMovement(x,y,x+math.cos(heading)*step,y+math.sin(heading)*step)
        if hit then return false end
        x,y=nx,ny
    end
    return true
end

-- The older road-grip query intentionally continues to report road at the
-- barn. The new guide-specific query excludes the kart's expanded collision
-- footprint without changing the handling query.
assert(track.isDrivable(400,1720) and not track.isGuideDrivable(400,1720))
for _,pose in ipairs({{430,1700}, {335,1600}, {440,1680}, {420,1750},
    {350,1632}, {300,1755}, {285,1750}, {460,1700}}) do
    local x,y=pose[1],pose[2]
    assert(track.isGuideDrivable(x,y), "valid kart centre by the barn")
    local heading, distance, along = AK.Presentation.guideHeading(track,progress,x,y,route,0)
    assert(heading and along and distance>0, "both barn routes retain useful guidance")
    assert(clearRay(x,y,heading,distance), "the complete guide ray clears walls and the barn")
    assert(clearRay(x,y,heading,AK.Presentation.GUIDE_ARROW.reach), "the visible arrow clears the barn")
end
assert(progress.passed==2 and progress.nextGate==3 and not progress.complete,
    "presentation reads checkpoint progress without mutating it")

-- A legal approach from the reviewed route to the southern alternative.
local x,y=612,1755
for _,target in ipairs({{430,1700}, {430,1600}, {335,1600}}) do
    local dx,dy=target[1]-x,target[2]-y
    local steps=math.ceil(math.sqrt(dx*dx+dy*dy)/4)
    local sx,sy=x,y
    for i=1,steps do
        local tx,ty=sx+dx*i/steps,sy+dy*i/steps
        local nx,ny,hit=track.resolveMovement(x,y,tx,ty)
        assert(not hit and math.abs(nx-tx)<1e-7 and math.abs(ny-ty)<1e-7,
            "the southern alternative is reachable without collision")
        x,y=nx,ny
    end
end

-- If no checked point is clear the guide hides, rather than reverting to a
-- straight line through a solid. Gate highlights remain independently drawn.
local blocked={gates=track.gates, isDrivable=function() return true end,
    isGuideDrivable=function() return false end}
assert(AK.Presentation.guideHeading(blocked,progress,430,1700,route,0)==nil,
    "no-clear-route fallback does not point through an obstruction")
-- The fixed guide must also stay clear along the entire authored lap, not
-- just at the reported barn poses. Use actual checkpoints and collision.
local data=AK.Battlegrounds.arathi_basin
local start=track.spawn()
local previous={x=start.x,y=start.y,tick=0}
local raceProgress=AK.Checkpoints.new(track,0)
local checked=0
for i=2,#data.route do
    local point=data.route[i]
    local dx,dy=point.x-previous.x,point.y-previous.y
    local originX,originY=previous.x,previous.y
    local steps=math.max(1,math.ceil(math.sqrt(dx*dx+dy*dy)/4))
    for k=1,steps do
        local tx,ty=originX+dx*k/steps,originY+dy*k/steps
        local nx,ny,hit=track.resolveMovement(previous.x,previous.y,tx,ty)
        assert(not hit,"the authored route remains clear")
        local current={x=nx,y=ny,tick=previous.tick+1}
        raceProgress=AK.Checkpoints.step(raceProgress,previous,current,track)
        previous=current
        if not raceProgress.complete then
            local h,d,along=AK.Presentation.guideHeading(track,raceProgress,nx,ny,route,0)
            assert(h and along and clearRay(nx,ny,h,d) and clearRay(nx,ny,h,AK.Presentation.GUIDE_ARROW.reach),
                "route and visible guide rays stay clear throughout the lap")
            checked=checked+1
        end
    end
end
assert(checked>1000 and raceProgress.complete,"all route gates are reached with clear guidance")
print("Arathi guide: both reachable Stables routes, solid clearance and no-clear fallback PASS")
