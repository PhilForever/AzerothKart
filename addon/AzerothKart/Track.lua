-- Minimal analytical track geometry. Pure Lua, independent of WoW APIs.
local AK = _G.AzerothKart or {}
_G.AzerothKart = AK

local Track = {}
Track.width, Track.height = 800, 480
Track.centerX, Track.centerY = 400, 240
Track.outerX, Track.outerY = 370, 218
Track.innerX, Track.innerY = 170, 84
Track.lineX, Track.lineY = 266, 151

function Track.isDrivable(x, y)
    if type(x) ~= "number" or type(y) ~= "number" then return false end
    if x ~= x or y ~= y then return false end -- reject NaN
    local dx = x - Track.centerX
    local dy = y - Track.centerY
    local out = (dx / Track.outerX)^2 + (dy / Track.outerY)^2
    local inside = (dx / Track.innerX)^2 + (dy / Track.innerY)^2
    return out <= 1 and inside >= 1
end

function Track.spawn()
    return {x=Track.centerX + Track.lineX, y=Track.centerY, heading=math.pi/2}
end

AK.Track = Track
return Track
