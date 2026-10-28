-- Representative Arathi natural-boundary checks; fixed points are not exhaustive.
local AK={}
for _,name in ipairs({"Track","Circuit","Battlegrounds","ArathiGrass"}) do
    assert(loadfile("addon/AzerothKart/"..name..".lua"))("AzerothKart",AK)
end
local track=AK.Circuit.new(AK.Battlegrounds.arathi_basin,AK.Track.crossesGate)
local function close(a,b) return math.abs(a-b)<0.0001 end
local function lineClear(p)
    local x,y=p[1],p[2]
    for i=1,48 do
        local nx,ny=p[1]+(p[3]-p[1])*i/48,p[2]+(p[4]-p[2])*i/48
        local rx,ry,hit=track.resolveMovement(x,y,nx,ny)
        assert(not hit and close(rx,nx) and close(ry,ny),"open passage obstructed at sample "..i)
        x,y=rx,ry
    end
end
-- One real crossing in each of Claude's eight removed-fence stretches.
local openings={
    {1086.6,688.7,1095.7,701.8}, {1484.4,903.6,1473.4,892.0},
    {1344.4,1368.0,1328.5,1366.1}, {325.0,1403.0,339.3,1410.2},
    {1711.0,505.2,1726.9,502.9}, {1534.4,1053.1,1548.0,1061.4},
    {182.5,1844.7,168.0,1851.5}, {203.4,1342.2,189.1,1335.0},
}
for i,p in ipairs(openings) do
    assert(track.surfaceAt(p[1],p[2])=="road", "opening "..i.." starts on road")
    assert(track.surfaceAt(p[3],p[4])=="grass", "opening "..i.." ends on grass")
    lineClear(p);lineClear({p[3],p[4],p[1],p[2]})
end
-- A straight passage reaches 100 units beyond the old road edge.
lineClear({1344.4,1368.0,1237.1,1355.5})
assert(track.surfaceAt(1237.1,1355.5)=="grass")
-- Retained home-straight fence and the Gold Mine/Defiler painted road
-- blockers, approached from both the race road and the off-road side.
for _,p in ipairs({{1582.2,589.4,1534.2,592.0},
                    {1357.5,1199.8,1309.8,1194.5},
                    {1642.0,393.6,1666.0,352.1}}) do
    assert(track.surfaceAt(p[1],p[2])~="wall" and track.surfaceAt(p[3],p[4])~="wall")
    local _,_,hit1=track.resolveMovement(p[1],p[2],p[3],p[4])
    local _,_,hit2=track.resolveMovement(p[3],p[4],p[1],p[2])
    assert(hit1 and hit2,"retained obstruction must block both directions")
end
-- Blacksmith road mouth is blocked; the far side itself is water/cliff,
-- so there is no safe opposing-side start there for a reverse approach.
assert(track.surfaceAt(945,740)=="road" and track.surfaceAt(945,760)=="wall")
local _,_,blacksmithHit=track.resolveMovement(945,740,945,760)
assert(blacksmithHit,"blacksmith road mouth remains blocked")
-- The east bridge deck stays driveable and its side stays blocked.
assert(track.surfaceAt(1580,800)=="road" and track.surfaceAt(1660,800)=="wall")
local _,_,bridgeHit=track.resolveMovement(1580,800,1660,800)
assert(bridgeHit,"east bridge parapet remains blocked")
-- Deep water and a steep face remain non-drivable, not slow grass.
assert(track.surfaceAt(42,1826)=="wall" and track.surfaceAt(822,2006)=="wall")
print("Arathi grass map: eight openings, distant grass, bidirectional barriers, water and cliff PASS")
