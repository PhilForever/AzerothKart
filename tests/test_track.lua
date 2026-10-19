local T=dofile("addon/AzerothKart/Track.lua")
local s=T.spawn()
assert(T.isDrivable(s.x,s.y),"spawn should be drivable")
assert(not T.isDrivable(400,240),"island cannot be driven on")
assert(not T.isDrivable(0,0),"off-track should reject")
assert(not T.isDrivable(800,480),"outside oval should reject")
assert(T.isDrivable(400,240+T.lineY),"centerline top should be drivable")
assert(not T.isDrivable(0/0,240),"NaN coordinate should reject")
assert(not T.isDrivable(math.huge,240),"infinite coordinate should reject")
assert(not T.isDrivable(400,-math.huge),"infinite coordinate should reject")
assert(not T.isDrivable("400",240),"non-number coordinate should reject")
assert(T.surfaceAt(s.x,s.y)=="road","spawn surface is road")
assert(T.surfaceAt(T.centerX,T.centerY)=="grass","island is traversable grass")
assert(T.surfaceAt(T.centerX+T.outerX+1,T.centerY)=="grass","outside oval remains grass inside walls")
assert(T.surfaceAt(T.wallInset-1,T.centerY)=="wall","outside inset is wall")
for _,invalid in ipairs({0/0,math.huge,-math.huge,"400"}) do
    assert(T.surfaceAt(invalid,T.centerY)=="wall","invalid x must not classify as road or grass")
    assert(T.surfaceAt(T.centerX,invalid)=="wall","invalid y must not classify as road or grass")
end
local x,y,hit=T.constrainPosition(s.x,s.y)
assert(x==s.x and y==s.y and not hit,"in-bounds constraint preserves position")
x,y,hit=T.constrainPosition(0,T.centerY)
assert(x==T.wallInset and y==T.centerY and hit,"wall clamps only penetrating axis")
x,y,hit=T.constrainPosition(T.width,T.height)
assert(x==T.width-T.wallInset and y==T.height-T.wallInset and hit,"corner clamps both axes")

-- Pure module imports must neither require nor mutate a global addon namespace.
local before=_G.AzerothKart
local loadedTrack=dofile("addon/AzerothKart/Track.lua")
local loadedPhysics=dofile("addon/AzerothKart/Physics.lua")
assert(type(loadedTrack.spawn)=="function" and type(loadedPhysics.step)=="function")
assert(_G.AzerothKart==before,"pure imports must not mutate _G.AzerothKart")
local namespace={}
assert(loadfile("addon/AzerothKart/Track.lua"))("AzerothKart",namespace)
assert(loadfile("addon/AzerothKart/Physics.lua"))("AzerothKart",namespace)
assert(type(namespace.Track)=="table" and type(namespace.Physics)=="table",
       "client namespace injection must register returned modules")
