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
