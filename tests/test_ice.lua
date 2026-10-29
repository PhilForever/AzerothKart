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
assert(P.versionForTrack(ice)==16 and P.versionForTrack(road)==12)
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

-- The whole ice surface supports ordinary drift thresholds and rewards,
-- including ice over a grass underlay away from the painted road.
local function ready(t,ticks,kart)
    local state=P.new(t);state.speed=150;state.steering=1
    for i=1,ticks do
        state=step(state,t,{accelerate=true,left=true,drift=true},kart)
        assert(state.drifting and state.driftTicks==i,"every eligible ice tick charges")
        assert(state.driftTier==(i>=P.DRIFT_TIER2_TICKS and 2 or i>=P.DRIFT_TIER1_TICKS and 1 or 0),
            "ice uses the ordinary tier timing")
    end
    return state
end
for _,underlay in ipairs({"road","grass"}) do
    local field=track(function() return true end,underlay)
    for _,kart in ipairs({"basic","steam_tank","dwarven_biker"}) do
        for _,tier in ipairs({1,2}) do
            local ticks=tier==1 and P.DRIFT_TIER1_TICKS or P.DRIFT_TIER2_TICKS
            local state=ready(field,ticks,kart)
            assert(state.slipAngle>0,"holding drift still slides on ice")
            local released=step(state,field,{accelerate=true},kart)
            local reward=tier==1 and P.BOOST_TIER1_TICKS or P.BOOST_TIER2_TICKS
            assert(not released.drifting and released.driftTicks==0 and released.driftTier==0
                and released.boostTicks==reward-1 and released.speed>state.speed,
                "releasing an earned tier boosts on every ice underlay/profile")
            local held=step(released,field,{accelerate=true,left=true,drift=true},kart)
            assert(not held.drifting and held.driftTicks==0 and held.boostTicks==reward-2,
                "an active boost cannot recharge itself")
        end
    end
end
-- Painted road boundaries within the ice are visual: neither charge nor
-- release is cancelled when the ice remains under the kart.
local mixed=track(function() return true end)
mixed.surfaceAt=function(x) return x<0 and "road" or "grass" end
local crossing=P.new(mixed);crossing.x=-1;crossing.speed=150;crossing.steering=1
crossing.drifting=true;crossing.driftDirection=1;crossing.driftTicks=P.DRIFT_TIER1_TICKS;crossing.driftTier=1
crossing=step(crossing,mixed,{accelerate=true,left=true,drift=true})
assert(crossing.surface=="grass" and crossing.onIce and crossing.drifting
    and crossing.driftTicks==P.DRIFT_TIER1_TICKS+1,"ice charge ignores the painted road edge")
crossing=step(crossing,mixed,{accelerate=true})
assert(crossing.boostTicks==P.BOOST_TIER1_TICKS-1,"off-road ice can spend the carried tier")
local charged=ready(ice,P.DRIFT_TIER1_TICKS)
local correction=step(charged,ice,{accelerate=true,right=true,drift=true})
assert(correction.driftGraceTicks==1 and correction.driftTicks==charged.driftTicks,
    "an ice steering correction retains earned charge without increasing it")
correction=step(correction,ice,{accelerate=true})
assert(correction.boostTicks==P.BOOST_TIER1_TICKS-1,"releasing during ice correction grace pays the tier")
local braked=step(charged,ice,{brake=true,left=true,drift=true})
assert(not braked.drifting and braked.driftTicks==0 and braked.driftTier==0 and braked.boostTicks==0,
    "braking clears ice charge without reward")

-- A held road charge continues onto ice; no extra release or tier is invented.
local entering=track(function(x) return x>=0 end)
charged=P.new(entering);charged.x=-1;charged.speed=150;charged.steering=1
charged.drifting=true;charged.driftDirection=1;charged.driftTicks=P.DRIFT_TIER1_TICKS;charged.driftTier=1
charged=step(charged,entering,{accelerate=true,left=true,drift=true})
assert(charged.onIce and charged.drifting and charged.driftTicks==P.DRIFT_TIER1_TICKS+1 and charged.boostTicks==0,
    "road charge continues at the ice boundary")
charged=step(charged,entering,{accelerate=true})
assert(charged.boostTicks==P.BOOST_TIER1_TICKS-1,"the carried road tier can release on ice")
-- Ice over rough snow is eligible too; leaving the ice cancels on that tick.
local snowExit=track(function(x) return x<0 end,"grass")
charged=P.new(snowExit);charged.x=-1;charged.speed=150;charged.steering=1
charged.drifting=true;charged.driftDirection=1;charged.driftTicks=P.DRIFT_TIER1_TICKS;charged.driftTier=1
charged=step(charged,snowExit,{accelerate=true,left=true,drift=true})
assert(not charged.onIce and not charged.drifting and charged.driftTicks==0 and charged.driftTier==0,
    "leaving onto ordinary snow clears charge")
charged=step(charged,snowExit,{accelerate=true})
assert(charged.boostTicks==0,"snow cannot bank an ice tier for release")
-- Returning to road can continue/release during the traction recovery window.
local roadExit=track(function(x) return x<0 end)
charged=P.new(roadExit);charged.x=-1;charged.speed=150;charged.steering=1
charged.drifting=true;charged.driftDirection=1;charged.driftTicks=P.DRIFT_TIER1_TICKS;charged.driftTier=1
charged=step(charged,roadExit,{accelerate=true,left=true,drift=true})
assert(not charged.onIce and charged.iceRecoveryTicks==15 and charged.drifting,
    "road recovery retains a valid ice charge")
charged=step(charged,roadExit,{accelerate=true})
assert(charged.boostTicks==P.BOOST_TIER1_TICKS-1,"road recovery allows release")
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
-- Actual Alterac mask coverage: every collision-free first drift step from
-- a passable ice cell charges, regardless of its road/snow classification.
local AK={}
for _,name in ipairs({"Track","Circuit","Battlegrounds"}) do
    assert(loadfile("addon/AzerothKart/"..name..".lua"))("AzerothKart",AK)
end
local valley=AK.Circuit.new(AK.Battlegrounds.alterac_valley,AK.Track.crossesGate)
local map=AK.Battlegrounds.alterac_valley.iceMap
local onRoad,offRoad=0,0
for row=0,map.rows-1 do
    for col=0,map.columns-1 do
        local x,y=(col+0.5)*map.cellSize,(row+0.5)*map.cellSize
        if valley.iceAt(x,y) then
            local state=P.new(valley);state.x=x;state.y=y;state.surface=valley.surfaceAt(x,y);state.heading=0;state.speed=150;state.steering=1
            local nextState=step(state,valley,{accelerate=true,left=true,drift=true})
            if nextState.impacts==0 and nextState.onIce then
                assert(nextState.drifting and nextState.driftTicks==1,"passable Alterac ice charges everywhere")
                if state.surface=="road" then onRoad=onRoad+1 else offRoad=offRoad+1 end
            end
        end
    end
end
assert(onRoad>100 and offRoad>100,"coverage includes road and off-road ice")
print(("ice mask drift coverage: %d road / %d off-road collision-free samples"):format(onRoad,offRoad))
print("ice: traction, whole-field drift tiers/boosts, recovery, cancellation and determinism PASS")
