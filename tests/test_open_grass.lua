-- Opt-in passability grid: arbitrary grass around circuit roads. Pure Lua.
local Track=dofile('addon/AzerothKart/Track.lua')
local Circuit=dofile('addon/AzerothKart/Circuit.lua')
local columns,rows,size=20,20,10
local function mask(blocked)
    local out={}
    for b=0,columns*rows/8-1 do
        local value=0
        for bit=0,7 do
            local index=b*8+bit
            local col,row=index%columns,math.floor(index/columns)
            if not blocked[col..','..row] then value=value+2^bit end
        end
        out[#out+1]=string.char(value)
    end
    return {cellSize=size,columns=columns,rows=rows,data=table.concat(out)}
end
local function definition(blocked)
    return {id='open_grass_fixture',version=3,width=200,height=200,wallInset=2,
        roadRadius=10,wallRadius=20,fullSpeedToWalls=true,
        centerline={{x=20,y=50},{x=180,y=50},{x=180,y=150},{x=20,y=150}},
        gates={{name='Start',ax=20,ay=40,bx=20,by=60,nx=1,ny=0}},
        solids={{id='rock',x=90,y=90,width=10,height=10}},
        spawn={x=20,y=50,heading=0},grassMap=mask(blocked or {})}
end
local function close(a,b) return math.abs(a-b)<1e-5 end
local plain=definition()
local course=Circuit.new(plain,Track.crossesGate)
assert(course.surfaceAt(30,50)=='road' and course.isDrivable(30,50))
assert(course.surfaceAt(50,80)=='grass' and not course.isDrivable(50,80),
    'mask opens slow grass beyond former corridor')
local x,y,hit=course.resolveMovement(50,69,50,75)
assert(not hit and x==50 and y==75,'cross former corridor into grass')
x,y,hit=course.resolveMovement(50,75,50,69)
assert(not hit and x==50 and y==69,'return from grass to road')
x,y,hit=course.resolveMovement(20,80,-20,80)
assert(hit and close(x,2) and y==80,'map inset still blocks')
x,y,hit=course.resolveMovement(80,95,100,95)
assert(hit and close(x,88) and y==95,'expanded solid remains swept')

local blocked={['8,7']=true,['8,8']=true,['8,9']=true}
local wall=Circuit.new(definition(blocked),Track.crossesGate)
assert(wall.surfaceAt(85,75)=='wall' and not wall.isDrivable(85,75))
x,y,hit=wall.resolveMovement(75,75,95,75)
assert(hit and x<80 and close(x,80) and y==75,'crossing a one-cell wall cannot tunnel')
x,y,hit=wall.resolveMovement(75,75,85,82)
assert(hit and x<80 and close(x,80) and y>81.9,'glancing wall contact slides tangentially')
x,y,hit=wall.resolveMovement(85,75,85,75)
assert(hit and x==20 and y==50,'invalid masked pose recovers to valid spawn')

-- Corner crossing cannot clip between diagonal blocked cells. Check both
-- movement directions, including endpoint exactly on the cell boundary.
local corner=Circuit.new(definition({['8,8']=true}),Track.crossesGate)
x,y,hit=corner.resolveMovement(75,75,85,85)
assert(hit and x<80 and y<80 and close(x,80) and close(y,80),'blocked diagonal corner')
x,y,hit=corner.resolveMovement(75,75,80,80)
assert(hit and x<80 and y<80,'blocked diagonal endpoint')
local rev=Circuit.new(definition({['7,7']=true}),Track.crossesGate)
x,y,hit=rev.resolveMovement(85,85,75,75)
assert(hit and x>80 and y>80 and close(x,80) and close(y,80),'reverse blocked diagonal corner')
local pinch=Circuit.new(definition({['8,7']=true,['7,8']=true}),Track.crossesGate)
x,y,hit=pinch.resolveMovement(75,75,85,85)
assert(hit and x<80 and y<80,'blocked orthogonal corner pinch')
local freeCorner=Circuit.new(definition(),Track.crossesGate)
x,y,hit=freeCorner.resolveMovement(75,75,85,85)
assert(not hit and x==85 and y==85,'open diagonal is unchanged')

for _,bad in ipairs({
    {cellSize=0,columns=20,rows=20,data=string.rep('\255',50)},
    {cellSize=10,columns=19,rows=20,data=string.rep('\255',48)},
    {cellSize=10,columns=20,rows=20,data='short'},
    {cellSize=10,columns=20,rows=20,data=string.rep('\0',50)},
}) do
    local d=definition();d.grassMap=bad
    assert(not pcall(Circuit.new,d,Track.crossesGate),'malformed mask or blocked spawn refused')
end
local legacy=definition();legacy.grassMap=nil
local old=Circuit.new(legacy,Track.crossesGate)
assert(old.surfaceAt(50,80)=='wall','default corridor unchanged')

-- Thousands of real-size steps: admitted end positions, bounded displacement,
-- and bit-for-bit deterministic duplicate paths, including blocked contacts.
local one,two={x=30,y=50},{x=30,y=50}
local seed=424243
for i=1,3000 do
    seed=(seed*16807)%2147483647
    local angle=seed/2147483647*2*math.pi
    local dx,dy=math.cos(angle)*4.3,math.sin(angle)*4.3
    local ax,ay,ah=wall.resolveMovement(one.x,one.y,one.x+dx,one.y+dy)
    local bx,by,bh=wall.resolveMovement(two.x,two.y,two.x+dx,two.y+dy)
    assert(ax==bx and ay==by and ah==bh,'deterministic masked movement')
    assert((ax-one.x)^2+(ay-one.y)^2<=4.3^2+1e-6,'masked step never outruns request')
    assert(wall.surfaceAt(ax,ay)~='wall','masked movement ends in allowed ground')
    one.x,one.y,two.x,two.y=ax,ay,bx,by
end
print('open grass: mask admission, swept barriers, corner guards, legacy and deterministic steps PASS')
