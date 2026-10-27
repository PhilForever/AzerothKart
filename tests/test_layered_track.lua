-- Pure geometry foundation only; no Warsong art, native renderer or release claim.
local AK={}
for _,name in ipairs({"Track","Dungeon","LayeredTrack"}) do
    assert(loadfile("addon/AzerothKart/"..name..".lua"))("AzerothKart",AK)
end
local function clone(t)
    if type(t)~="table" then return t end
    local out={}; for k,v in pairs(t) do out[k]=clone(v) end; return out
end
local function near(a,b) return math.abs(a-b)<1e-6 end
local definition={id="layer_fixture",version=1,width=440,height=260,wallInset=2,laps=3,
    checkpointMaxStep=5,
    rooms={
        {x=20,y=20,width=124,height=200,surface="road",level=0},
        {x=216,y=80,width=204,height=80,surface="road",level=0},
        {x=140,y=142,width=80,height=98,surface="road",level=0},
        {x=20,y=20,width=124,height=200,surface="road",level=1},
        {x=216,y=80,width=204,height=80,surface="road",level=1},
        {x=100,y=20,width=220,height=60,surface="road",level=1},
    },
    solids={{id="pillar",x=60,y=120,width=10,height=10,level=0}},
    ramps={{id="up",x=140,y=100,width=80,height=40,axis="x",ascending=1,lowLevel=0,highLevel=1}},
    gates={{name="Ground",ax=80,ay=40,bx=80,by=70,nx=1,ny=0,level=0},
        {name="Roof",ax=260,ay=100,bx=260,by=140,nx=1,ny=0,level=1}},
    spawn={x=40,y=40,heading=0,level=0},
}
local before=clone(definition)
local track=AK.LayeredTrack.new(definition,AK.Track.crossesGate)
assert(track.layered and track.levelCount==2 and track.validLevel(0) and track.validLevel(1)
    and not track.validLevel(2) and not track.validLevel(nil),"explicit floor0/1 identity")
assert(track.spawn().level==0 and track.spawn().x==40,"spawn returns an explicit floor copy")
local spawn=track.spawn();spawn.level=1;assert(track.spawn().level==0,"spawn view detached")
assert(track.surfaceAt(65,125,0)=="wall" and track.surfaceAt(65,125,1)=="road",
    "a lower solid has no collision on an overlapping upper floor")
assert(track.surfaceAt(65,125)=="wall" and not track.isDrivable(65,125,0)
    and track.isDrivable(65,125,1),"omitted level preserves floor0")
assert(track.surfaceAt(65,125,2)=="wall" and not track.isDrivable(65,125,2),"unknown floors fail closed")
assert(track.surfaceAt(65,125,false)=="wall" and not track.isDrivable(65,125,false)
    and not pcall(track.resolveMovement,40,40,41,40,false),"false is not an omitted floor")
local x,y,hit,l=track.resolveMovement(50,125,66,125,0)
assert(hit and near(x,58) and y==125 and l==0,"own-floor pillar stops and preserves level")
x,y,hit,l=track.resolveMovement(50,125,66,125,1)
assert(not hit and x==66 and y==125 and l==1,"same x/y on upper floor ignores lower pillar")

-- Enter the low end, stop/turn while inside and leave high. A normal step
-- spanning the final plane uses destination-floor collision after the split.
x,y,hit,l=track.resolveMovement(135,120,145,120,0)
assert(not hit and x==145 and l==0,"low-end entry retains floor until destination end")
x,y,hit,l=track.resolveMovement(x,y,x,y,0)
assert(not hit and x==145 and y==120 and l==0,"stationary ramp state does not change floor")
x,y,hit,l=track.resolveMovement(180,120,180,125,0)
assert(not hit and x==180 and y==125 and l==0,"turning on ramp keeps entry floor")
local sx,sy
x,y,hit,l,sx,sy=track.resolveMovement(215,120,225,120,0)
assert(not hit and x==225 and y==120 and l==1 and sx==220 and sy==120,
    "normal step switches exactly at high endpoint and returns split scalars")
assert(select("#",track.resolveMovement(215,120,225,120,0))==6,"one transition returns point without allocating a trace")
local blocked=clone(definition)
blocked.solids[#blocked.solids+1]={id="upper_after_join",x=228,y=116,width=8,height=8,level=1}
local afterJoin=AK.LayeredTrack.new(blocked,AK.Track.crossesGate)
x,y,hit,l,sx,sy=afterJoin.resolveMovement(215,120,231,120,0)
assert(hit and near(x,226) and y==120 and l==1 and sx==220 and sy==120,
    "destination-floor wall applies within the remainder of the transfer step")
x,y,hit,l=track.resolveMovement(225,120,215,120,1)
assert(not hit and x==215 and l==1,"high-floor reverse enters high ramp end")
x,y,hit,l,sx,sy=track.resolveMovement(145,120,135,120,1)
assert(not hit and x==135 and l==0 and sx==140 and sy==120,"reverse downhill transfer uses low endpoint")
x,y,hit,l=track.resolveMovement(145,120,135,120,0)
assert(not hit and l==0 and x==135,"backing out low end does not switch floors")
x,y,hit,l=track.resolveMovement(215,120,225,120,1)
assert(not hit and l==1 and x==225,"backing out high end does not switch floors")

-- Wrong-end and side entrances cannot turn overlapping floor into a ramp.
x,y,hit,l=track.resolveMovement(225,120,215,120,0)
assert(hit and x>=220 and l==0,"lower-floor kart cannot enter the high end")
x,y,hit,l=track.resolveMovement(135,120,145,120,1)
assert(hit and x<=140 and l==1,"upper-floor kart cannot enter the low end")
x,y,hit,l=track.resolveMovement(180,130,185,145,0)
assert(hit and y<=138 and l==0,"ramp side is a wall while sliding keeps the same floor")
x,y,hit,l=track.resolveMovement(130,90,145,95,0)
assert(l==0,"a side/corner approach cannot award a floor")
x,y,hit,l=track.resolveMovement(180,150,180,134,0)
assert(hit and y>=144 and l==0,"nearest-floor projection cannot pull a side entrant onto the ramp")
x,y,hit,l=track.resolveMovement(180,120,180,150,0)
assert(hit and x==180 and y==120 and l==0,"oversized request is refused safely")

-- Mirroring the ascent and rotating the ramp preserve endpoint semantics.
local mirrored=clone(definition)
mirrored.ramps[1].ascending=-1
local reverse=AK.LayeredTrack.new(mirrored,AK.Track.crossesGate)
x,y,hit,l,sx,sy=reverse.resolveMovement(145,120,135,120,0)
assert(not hit and x==135 and l==1 and sx==140,"mirrored low-to-high direction")
local rotated=clone(definition)
rotated.width,rotated.height=definition.height,definition.width
for _,room in ipairs(rotated.rooms) do room.x,room.y,room.width,room.height=room.y,room.x,room.height,room.width end
for _,solid in ipairs(rotated.solids) do solid.x,solid.y,solid.width,solid.height=solid.y,solid.x,solid.height,solid.width end
for _,gate in ipairs(rotated.gates) do gate.ax,gate.ay,gate.bx,gate.by,gate.nx,gate.ny=gate.ay,gate.ax,gate.by,gate.bx,gate.ny,gate.nx end
rotated.ramps[1].x,rotated.ramps[1].y,rotated.ramps[1].width,rotated.ramps[1].height=100,140,40,80
rotated.ramps[1].axis="y"
local vertical=AK.LayeredTrack.new(rotated,AK.Track.crossesGate)
x,y,hit,l,sx,sy=vertical.resolveMovement(120,215,120,225,0)
assert(not hit and y==225 and l==1 and sx==120 and sy==220,"vertical ramp transfer")

for _,bad in ipairs({"overlap","short","unknown_level","false_level","gate_on_ramp","gate_spans_ramp","pad_on_ramp","spawn_on_ramp","side_solid"}) do
    local d=clone(definition)
    if bad=="overlap" then d.rooms[#d.rooms+1]={x=160,y=110,width=40,height=30,surface="road",level=0}
    elseif bad=="short" then d.ramps[1].width=20
    elseif bad=="unknown_level" then d.rooms[1].level=2
    elseif bad=="false_level" then d.rooms[1].level=false
    elseif bad=="gate_on_ramp" then d.gates[1].ax,d.gates[1].bx,d.gates[1].ay,d.gates[1].by=180,180,110,130
    elseif bad=="gate_spans_ramp" then d.gates[1].ax,d.gates[1].ay,d.gates[1].bx,d.gates[1].by=30,40,170,120
    elseif bad=="pad_on_ramp" then d.pads={{id="boots",x=180,y=120,radius=4,level=0,boostTicks=78}}
    elseif bad=="spawn_on_ramp" then d.spawn.x,d.spawn.y=180,120
    else d.solids[#d.solids+1]={id="block",x=170,y=115,width=10,height=10,level=1} end
    assert(not pcall(AK.LayeredTrack.new,d,AK.Track.crossesGate),"ambiguous/invalid authored geometry rejects: "..bad)
end

do
    local two=clone(definition)
    two.rooms[2].width,two.rooms[5].width=24,24
    two.rooms[#two.rooms+1]={x=312,y=80,width=108,height=80,surface="road",level=0}
    two.rooms[#two.rooms+1]={x=312,y=80,width=108,height=80,surface="road",level=1}
    two.ramps[2]={id="second",x=236,y=100,width=80,height=40,axis="x",ascending=1}
    two.gates[2].ax,two.gates[2].bx=350,350
    local ok,why=pcall(AK.LayeredTrack.new,two,AK.Track.crossesGate)
    assert(not ok and tostring(why):find("gap",1,true),
        "exact16gap cannot land a transfer on another ramp's forbidden entry plane")
    two.ramps[2].x=237
    two.rooms[#two.rooms-1].x,two.rooms[#two.rooms-1].width=313,107
    two.rooms[#two.rooms].x,two.rooms[#two.rooms].width=313,107
    local separated=AK.LayeredTrack.new(two,AK.Track.crossesGate)
    local x,y,hit,l=separated.resolveMovement(220,120,236,120,0)
    assert(x==236 and not hit and l==1)
    x,y,hit,l=separated.resolveMovement(x,y,240,120,l)
    assert(hit and x<237 and l==1,"separate ramps still enforce the second portal's own entry level")
end

-- Deterministic tape through either end, mixed free/side-wall steps, both
-- layers and invalid long requests. The source geometry remains untouched.
local function replay()
    local x,y,l=135,120,0
    local tape={}
    for tick=1,240 do
        local direction=tick%120<60 and 1 or -1
        local nx,ny,contact,nextLevel=track.resolveMovement(x,y,x+direction*2,y+(tick%3-1)*0.05,l)
        assert((nx-x)^2+(ny-y)^2<=4.01,"normal movement respects requested displacement bound")
        tape[tick]={nx,ny,contact,nextLevel};x,y,l=nx,ny,nextLevel
    end
    return tape
end
local a,b=replay(),replay()
for tick=1,#a do for i=1,4 do assert(a[tick][i]==b[tick][i],"repeatable floor movement") end end
assert(definition.rooms[1].level==before.rooms[1].level and definition.ramps[1].width==before.ramps[1].width,
    "constructor and movement do not mutate authored geometry")
print("layered track: floor-isolated collision, bidirectional split ramps, side/wrong-end guards, validation and deterministic tape PASS")
