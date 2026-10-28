-- Arathi's optional grass boost is isolated from legacy tracks and physics.
local P=dofile("addon/AzerothKart/Physics.lua")
local function course(enabled,hit)
    return {boostOnGrass=enabled,spawn=function() return {x=-1,y=0,heading=0} end,
        surfaceAt=function(x) return x>=0 and "grass" or "road" end,
        resolveMovement=function(x,y,nx,ny)
            if hit then return x+(nx-x)*0.7,y+(ny-y)*0.7,true end
            return nx,ny,false
        end}
end
local function state(t,x,speed,ticks)
    local s=P.new(t);s.x=x;s.speed=speed;s.boostTicks=ticks
    return s
end
local function step(s,t,input,kart) return P.step(s,input or {accelerate=true},P.FIXED_DT,t,kart) end
local t=course(true)
assert(P.versionForTrack(t)==14 and P.versionForTrack(course(false))==12)
for _,kart in ipairs({"basic","steam_tank","dwarven_biker"}) do
    local max=P.GetHandling(kart).maxSpeed
    local s=step(state(t,-1,250,5),t,nil,kart)
    assert(s.surface=="grass" and s.speed==max and s.boostTicks==4,"road to grass clamps to profile road cap")
    s=step(s,t,nil,kart)
    assert(s.speed==max and s.boostTicks==3,"grass sustains normal top speed")
    s=step(state(t,2,100,5),t,nil,kart)
    assert(s.speed>100 and s.speed<max,"grass boost accelerates without teleporting to top speed")
end
local last=step(state(t,5,180,1),t)
assert(last.boostTicks==0 and last.speed>180,"final boost tick still protects grass")
local expired=step(last,t)
assert(expired.boostTicks==0 and expired.speed<last.speed,"grass slows immediately after expiry")
local noBoost=step(state(t,5,180,0),t)
assert(noBoost.speed<180,"unboosted grass remains slow")
local brake=step(state(t,5,180,10),t,{brake=true})
assert(brake.boostTicks==0 and brake.speed<180,"braking cancels grass boost and slows")
local hitTrack=course(true,true)
local hit=step(state(hitTrack,5,180,10),hitTrack)
assert(hit.impacts==1 and hit.boostTicks==0 and hit.speed<180,"wall contact cancels boost")
local released=state(t,-1,150,0)
released.drifting=true;released.driftTier=1;released.driftTicks=P.DRIFT_TIER1_TICKS
released.driftDirection=1
released=step(released,t,{accelerate=true})
assert(released.surface=="grass" and released.boostTicks==P.BOOST_TIER1_TICKS-1
    and not released.drifting and released.driftTier==0,"road release survives grass crossing; drift ends")
local back=state(t,1,160,5);back.heading=math.pi
back=step(back,t)
assert(back.surface=="road" and back.boostTicks==4,"boost survives returning to road")
local legacy=course(false)
local old=step(state(legacy,-1,180,10),legacy)
assert(old.surface=="grass" and old.boostTicks==0 and old.speed<180,"legacy grass cancellation remains")
local first,second=state(t,-1,150,20),state(t,-1,150,20)
for i=1,80 do
    local input={accelerate=true,left=i%8<4}
    first,second=step(first,t,input),step(second,t,input)
    for key,value in pairs(first) do assert(value==second[key],"deterministic grass step: "..key) end
end
-- Production construction (not just a hand-made flag) opts in only Arathi.
local AK={}
for _,name in ipairs({"Track","MirageRaceway","Circuit","CapitalCities","Dungeon","ScarletCrusade",
    "LayeredTrack","Battlegrounds","ArathiGrass","Courses","Physics"}) do
    assert(loadfile("addon/AzerothKart/"..name..".lua"))("AzerothKart",AK)
end
local arathi=assert(AK.Courses.build("arathi_basin",AK.Track.crossesGate))
assert(arathi.boostOnGrass and AK.Physics.versionForTrack(arathi)==14 and not arathi.layered,
    "production Arathi constructor opts into flat physics 14")
assert(AK.Courses.build("arathi_basin",AK.Track.crossesGate)==arathi,"flag is fixed before track caching")
local mirage=assert(AK.Courses.build("mirage_raceway",AK.Track.crossesGate))
local warsong=assert(AK.Courses.build("warsong_gulch",AK.Track.crossesGate))
assert(AK.Physics.versionForTrack(mirage)==12 and AK.Physics.versionForTrack(warsong)==13,
    "legacy and layered tracks keep their previous compatibility")
print("grass_boost: course opt-in, caps, expiry, cancellation, legacy and deterministic replay PASS")
