-- Opt-in ice traction: deterministic movement metrics, not visual assertions.
local P=dofile("addon/AzerothKart/Physics.lua")
local function track(query,surface,hit)
    return {iceAt=query,spawn=function() return {x=-100,y=0,heading=0} end,
        surfaceAt=function() return surface or "road" end,
        resolveMovement=function(x,y,nx,ny)
            if hit then return x+(nx-x)*0.7,y+(ny-y)*0.7,true end
            return nx,ny,false
        end}
end

local ice=track(function() return true end)
local road=track(nil)
local function step(s,t,input,kart) return P.step(s,input or {},P.FIXED_DT,t,kart) end
local function close(a,b) return math.abs(a-b)<1e-9 end
local function stopping(t)
    local s=P.new(t);s.speed=200
    local distance,ticks=0,0
    while s.speed>0 and ticks<1000 do
        local previous=s;s=step(s,t,{brake=true});ticks=ticks+1
        if s.speed>0 then distance=distance+math.sqrt((s.x-previous.x)^2+(s.y-previous.y)^2) end
    end
    assert(s.speed<=0,"braking must eventually stop")
    return distance,ticks*P.FIXED_DT
end
local roadDistance,roadSeconds=stopping(road)
local iceDistance,iceSeconds=stopping(ice)
assert(iceDistance>roadDistance*2.3 and iceDistance<roadDistance*2.7
    and iceSeconds>roadSeconds*2.3 and iceSeconds<roadSeconds*2.7,
    "ice needs roughly two and a half times the road stopping distance and time")
print(("ice braking from200: road %.2fu / %.2fs; ice %.2fu / %.2fs")
    :format(roadDistance,roadSeconds,iceDistance,iceSeconds))
assert(P.versionForTrack(ice)==15 and P.versionForTrack(road)==12)
assert(P.versionForTrack({boostOnGrass=true})==14 and P.versionForTrack({layered=true})==13)
assert(P.new(road).onIce==nil and P.new(road).iceRecoveryTicks==nil,"legacy state shape stays exact")
assert(P.new(ice).onIce==true and P.new(ice).iceRecoveryTicks==0)

for _,kart in ipairs({"basic","steam_tank","dwarven_biker"}) do
    local dry,frozen=P.new(road),P.new(ice)
    for _=1,60 do
        dry=step(dry,road,{accelerate=true},kart)
        frozen=step(frozen,ice,{accelerate=true},kart)
    end
    assert(close(frozen.speed/dry.speed,0.70),"one-second ice acceleration is slower for every handling profile")
    dry.speed,frozen.speed=150,150
    for _=1,20 do dry=step(dry,road,{brake=true},kart);frozen=step(frozen,ice,{brake=true},kart) end
    assert(close((150-frozen.speed)/(150-dry.speed),0.40),"ice braking distance grows for every profile")
end

local dry,frozen=P.new(road),P.new(ice)
dry.speed,frozen.speed=180,180;dry.steering,frozen.steering=1,1
for _=1,20 do dry=step(dry,road,{accelerate=true,left=true});frozen=step(frozen,ice,{accelerate=true,left=true}) end
assert(frozen.heading<dry.heading*0.65,"heading turns substantially less on ice")
assert(frozen.slipAngle>0.2 and dry.slipAngle==0,"ice retains sideways movement without holding drift")
local before=frozen
frozen=step(frozen,ice,{accelerate=true,left=true})
local dx,dy=frozen.x-before.x,frozen.y-before.y
local cross=math.sin(frozen.heading)*dx-math.cos(frozen.heading)*dy
assert(cross>0.2,"movement direction lags the turned kart heading")
local retained=frozen.slipAngle
for _=1,10 do frozen=step(frozen,ice,{accelerate=true}) end
assert(frozen.slipAngle>0 and frozen.slipAngle<retained,"releasing steering recovers traction slowly")

local charged=P.new(ice);charged.speed=150
charged.drifting=true;charged.driftTicks=P.DRIFT_TIER2_TICKS;charged.driftTier=2
charged=step(charged,ice,{accelerate=true,left=true,drift=true})
assert(not charged.drifting and charged.driftTicks==0 and charged.boostTicks==0,"ice cannot build or bank a drift reward")
local entering=track(function(x) return x>=0 end)
charged=P.new(entering);charged.x=-1;charged.speed=150;charged.steering=1
charged.drifting=true;charged.driftDirection=1;charged.driftTicks=P.DRIFT_TIER2_TICKS;charged.driftTier=2
charged=step(charged,entering,{accelerate=true,left=true,drift=true})
assert(charged.onIce and not charged.drifting and charged.driftTicks==0 and charged.boostTicks==0,
    "held charge is cleared at the road-to-ice boundary")
charged=step(charged,entering,{accelerate=true})
assert(charged.boostTicks==0,"releasing after entry cannot spend a road charge banked onto ice")
local boosted=P.new(ice);boosted.speed=240;boosted.boostTicks=8
boosted=step(boosted,ice,{accelerate=true})
assert(boosted.speed>240 and boosted.boostTicks==7,"earned road boost remains usable across ice")
local snowIce=track(function() return true end,"grass")
local s=P.new(snowIce);s.speed=180;s=step(s,snowIce,{accelerate=true})
assert(s.speed>180,"ice outside road has no rough-snow speed cap")
local snow=track(nil,"grass");s=P.new(snow);s.speed=180;s=step(s,snow,{accelerate=true})
assert(s.speed<180,"ordinary snow still slows")

-- Leaving the patch retains momentum, then restores road grip over 15 ticks.
local edge=track(function(x) return x<0 end)
s=P.new(edge);s.x=-1;s.speed=150;s.slipAngle=0.4
s=step(s,edge,{accelerate=true})
assert(not s.onIce and s.x>0 and s.iceRecoveryTicks==15 and s.slipAngle>0.38,"edge crossing does not snap velocity")
local initial=s.slipAngle
for i=1,15 do
    s=step(s,edge,{accelerate=true})
    assert(s.iceRecoveryTicks==15-i and not s.onIce,"bounded exit recovery")
end
assert(s.slipAngle<initial,"normal grip returns after the patch")
local snowEdge=track(function(x) return x<0 end,"grass")
s=P.new(snowEdge);s.x=-1;s.speed=180
s=step(s,snowEdge,{accelerate=true})
assert(not s.onIce and s.surface=="grass" and s.speed<180,
    "ice-to-snow crossing slows on the crossing tick, without a free extra ice step")
local wallIce=track(function() return true end,"road",true)
s=P.new(wallIce);s.speed=180;s.boostTicks=10;s.slipAngle=0.4
s=step(s,wallIce,{accelerate=true,left=true})
assert(s.impacts==1 and s.boostTicks==0 and s.slipAngle==0 and s.iceRecoveryTicks==0,"wall contact clears ice slide and boost")

-- Two identical input tapes produce identical complete state on every tick.
local a,b=P.new(edge),P.new(edge)
for i=1,2000 do
    local input={accelerate=true,left=i%180<55,right=i%180>125,brake=i%500>470,drift=i%100<50}
    a,b=step(a,edge,input),step(b,edge,input)
    for key,value in pairs(a) do assert(value==b[key],"ice deterministic field "..key) end
end

-- The pure query consumes a validated packed bit map, including safe bounds.
local T=dofile("addon/AzerothKart/Track.lua")
local C=dofile("addon/AzerothKart/Circuit.lua")
local function definition()
    return {id="ice_fixture",version=1,width=160,height=160,wallInset=2,
        roadRadius=10,wallRadius=20,centerline={{x=20,y=20},{x=140,y=20},{x=140,y=140},{x=20,y=140}},
        gates={{name="Finish",ax=20,ay=10,bx=20,by=30,nx=1,ny=0}},spawn={x=20,y=20,heading=0},
        grassMap={cellSize=10,columns=16,rows=16,data=string.rep("\255",32)},
        iceMap={cellSize=10,columns=16,rows=16,data=string.rep("\0",12).."\64"..string.rep("\0",19)}}
end
local d=definition();local t=C.new(d,T.crossesGate)
assert(t.iceAt(65,65) and not t.iceAt(55,65),"packed ice bit is mapped in world coordinates")
assert(not t.iceAt(-1,0) and not t.iceAt(0/0,0) and not t.iceAt(200,200),"invalid coordinates are never ice")
for _,bad in ipairs({{cellSize=8,columns=20,rows=20,data="short"},{cellSize=10,columns=16,rows=16,data="short"}}) do
    d=definition();d.iceMap=bad;assert(not pcall(C.new,d,T.crossesGate),"malformed ice map refused")
end
d=definition();d.iceMap=nil;assert(C.new(d,T.crossesGate).iceAt==nil,"legacy track has no ice feature")
print("ice: reduced acceleration/braking/steering, momentum, snow override, recovery, cancellation and determinism PASS")
