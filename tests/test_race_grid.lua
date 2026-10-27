-- Synthetic two-peer profile agreement, not a native transport measurement.
local namespace={}
local G=assert(loadfile("addon/AzerothKart/RaceGrid.lua"))("AzerothKart",namespace)
assert(namespace.RaceGrid==G and G.PREFIX=="AZKGRD1" and G.VERSION==1 and G.MAX_BYTES==12)
local CODE="GRD123"
local function wire(kind,id,code) return assert(G.encode({kind=kind,session=code or CODE,kartId=id})) end
local function fresh(role,id,now)
    return assert(G.new({session=CODE,role=role or "host",kartId=id or "steam_tank"},now or 0))
end
local function v(token) return assert(G.view(token)) end
local function closed(token,reason)
    assert(v(token).phase=="closed" and v(token).reason==reason)
    assert(v(token).hasPendingOutput==false)
end
local function accept() return "accepted" end

do
    local track={layered=true,width=400,height=400,
        spawn=function() return {x=200,y=200,heading=0,level=1} end,
        validLevel=function(level) return level==0 or level==1 end,
        isDrivable=function(x,y,level) return level==1 and x>100 and x<300 and y>100 and y<300 end}
    local host,guest=G.pose(track,"host")
    assert(host and guest and host.level==1 and guest.level==1,
        "starting grid preserves the explicit floor and queries only that floor")
    track.spawn=function() return {x=200,y=200,heading=0} end
    local bad,why=G.pose(track,"host")
    assert(not bad and why=="spawn_level","layered grid cannot guess a missing floor")
end

-- Canonical fixed sequence, exact fields, known kart IDs and detached packets.
for index,id in ipairs(G.KART_IDS) do
    for _,kind in ipairs({"PROFILE","ACK"}) do
        local payload=wire(kind,id)
        assert(#payload==12 and payload:sub(9,11)=="001" and payload:sub(12)==tostring(index-1))
        local decoded=assert(G.decode(payload))
        assert(decoded.kind==kind and decoded.session==CODE and decoded.kartId==id)
        decoded.kartId="basic"
        assert(G.decode(payload).kartId==id)
    end
end
assert(wire("PROFILE","basic")=="1PGRD123001Z")
assert(G.encode({kind="PROFILE",session=CODE,kartId="steam_tank",sequence=1})==nil)
assert(G.encode(setmetatable({kind="PROFILE",session=CODE,kartId="steam_tank"},{}))==nil)
for _,bad in ipairs({false,"",{},0,"steam_tank_bad"}) do
    assert(G.encode({kind="PROFILE",session=CODE,kartId=bad})==nil)
end
for _,bad in ipairs({false,{},"", "1PGRD123001A", "1PGRD1230001", "1PGRD1230021",
    "1PGRD123001z", "2PGRD1230011", "1XGRD1230011", "1PGRD12300111", "1PGRD12!0011"}) do
    assert(G.decode(bad)==nil)
end
for _,bad in ipairs({-1,0.5,0/0,math.huge,G.MAX_TIME-G.DURATION_MS+1}) do
    assert(G.new({session=CODE,role="host",kartId="basic"},bad)==nil)
end
assert(G.new({session=CODE,role="spectator",kartId="basic"},0)==nil)
assert(G.new({session="grd123",role="host",kartId="basic"},0)==nil)
assert(G.new({session=CODE,role="host",kartId="basic",other=true},0)==nil)

local function pair(drop)
    local p={now=0,host=fresh("host","steam_tank"),guest=fresh("guest","dwarf_car"),
        packets={},history={},dropped=false}
    function p:send(role)
        return function(payload)
            local message=assert(G.decode(payload))
            self.history[#self.history+1]={role=role,at=self.now,kind=message.kind,payload=payload}
            if drop and not self.dropped and drop(role,message) then self.dropped=true
            else self.packets[#self.packets+1]={to=role=="host" and "guest" or "host",
                at=self.now+350,payload=payload} end
            return "accepted"
        end
    end
    function p:step()
        local waiting={}
        for _,packet in ipairs(self.packets) do
            if packet.at<=self.now then G.receive(self[packet.to],self.now,packet.payload)
            else waiting[#waiting+1]=packet end
        end
        self.packets=waiting
        for _,role in ipairs({"host","guest"}) do
            local before=#self.history
            G.update(self[role],self.now,self:send(role))
            assert(#self.history-before<=1)
        end
        self.now=self.now+50
    end
    function p:run()
        for _=1,190 do
            self:step()
            if v(self.host).phase=="ready" and v(self.guest).phase=="ready" then break end
        end
        assert(v(self.host).phase=="ready" and v(self.guest).phase=="ready")
        assert(v(self.host).peerKartId=="dwarf_car" and v(self.guest).peerKartId=="steam_tank")
        local last={}
        for _,packet in ipairs(self.history) do
            if last[packet.role] then assert(packet.at-last[packet.role]>=500) end
            last[packet.role]=packet.at
        end
    end
    return p
end
pair():run()
local profileDrop=pair(function(role,m) return role=="host" and m.kind=="PROFILE" end)
profileDrop:run()
assert(v(profileDrop.host).stats.retries>=1)
local ackDrop=pair(function(role,m) return role=="guest" and m.kind=="ACK" end)
ackDrop:run()
assert(v(ackDrop.host).stats.retries>=1 and v(ackDrop.guest).stats.duplicates>=1)

-- ACK priority, bounded duplicate re-ACK and copied token/view data.
do
    local s=fresh()
    assert(G.receive(s,0,wire("PROFILE","dwarf_car")))
    assert(G.receive(s,0,wire("PROFILE","dwarf_car")))
    assert(G.update(s,0,function(payload) assert(G.decode(payload).kind=="ACK"); return "accepted" end))
    assert(v(s).phase=="exchanging" and v(s).profileAttempts==0)
    assert(not G.update(s,499,accept))
    assert(G.update(s,500,function(payload) assert(G.decode(payload).kind=="PROFILE"); return "accepted" end))
    assert(G.receive(s,500,wire("ACK","steam_tank")))
    assert(v(s).phase=="ready" and not v(s).hasPendingOutput)
    assert(G.receive(s,501,wire("PROFILE","dwarf_car")))
    assert(v(s).hasPendingOutput)
    assert(G.update(s,1000,accept))
    assert(not v(s).hasPendingOutput)
    local out=v(s); out.phase="closed"; out.stats.sendAttempts=999
    s.phase="closed"; s.peerKartId="basic"
    assert(v(s).phase=="ready" and v(s).peerKartId=="dwarf_car" and v(s).stats.sendAttempts==3)
    assert(not G.receive(s,1001,wire("PROFILE","basic")))
    closed(s,"contradiction")
end

-- Failed native outcomes cannot promote a reentrant ACK; accepted sends can.
for _,outcome in ipairs({"accepted","failed","throttled","unknown"}) do
    local s=fresh()
    assert(not G.receive(s,0,wire("ACK","steam_tank")))
    assert(G.update(s,0,function()
        local received,reason=G.receive(s,0,wire("ACK","steam_tank"))
        assert(received and reason=="deferred")
        assert(not v(s).localProfileAcknowledged)
        local updated,why=G.update(s,0,accept)
        assert(not updated and why=="send_in_progress")
        return outcome
    end))
    if outcome=="accepted" then assert(v(s).localProfileAcknowledged and v(s).phase=="exchanging")
    else closed(s,"send_"..outcome) end
end
do
    local s=fresh()
    assert(G.update(s,0,function()
        assert(G.receive(s,0,wire("ACK","steam_tank")))
        assert(G.stop(s,0,"left")); return "accepted"
    end))
    closed(s,"left")
    assert(not v(s).localProfileAcknowledged)
    local failure=fresh()
    assert(G.update(failure,0,function() error("native failure") end))
    closed(failure,"send_error")
end

-- Exactly three PROFILE attempts, no burst/catch-up, bounded rates and clocks.
do
    local s=fresh()
    assert(not G.update(s,0,accept,false) and v(s).profileAttempts==0)
    for _,at in ipairs({0,2000,4000}) do assert(G.update(s,at,accept)) end
    assert(not G.update(s,5999,accept) and v(s).profileAttempts==3)
    assert(not G.update(s,6000,accept)); closed(s,"timeout")
    local slow=fresh()
    assert(G.update(slow,9000,accept) and v(slow).profileAttempts==1)
    assert(not G.update(slow,10000,accept)); closed(slow,"timeout")
    local clock=fresh()
    assert(G.update(clock,500,accept))
    assert(not G.receive(clock,499,wire("PROFILE","basic"))); closed(clock,"clock_error")
    local unrelated=fresh()
    for _=1,100 do assert(not G.receive(unrelated,0,wire("PROFILE","basic","OTHER1"))) end
    assert(v(unrelated).stats.received==0)
    local flood=fresh()
    for _=1,8 do assert(G.receive(flood,0,wire("PROFILE","basic"))) end
    assert(not G.receive(flood,0,wire("PROFILE","basic"))); closed(flood,"peer_flood")
    local capped=fresh()
    for block=0,7 do
        for _=1,8 do assert(G.receive(capped,block*1000,wire("PROFILE","basic"))) end
    end
    assert(not G.receive(capped,8000,wire("PROFILE","basic"))); closed(capped,"event_limit")
end

-- Every production course provides the same immutable 36-unit two-peer grid.
do
    local AK={}
    for _,module in ipairs({"Track","MirageRaceway","Circuit","CapitalCities","Dungeon","ScarletCrusade","Courses"}) do
        assert(loadfile("addon/AzerothKart/"..module..".lua"))("AzerothKart",AK)
    end
    local ready=0
    for _,course in ipairs(AK.Courses.LIST) do
      if AK.Courses.multiplayer(course.id) then
        ready=ready+1
        local track=assert(AK.Courses.build(course.id,AK.Track.crossesGate))
        local original=track.spawn()
        local host,guest=G.pose(track,"host")
        local guestLocal,hostRemote=G.pose(track,"guest")
        assert(host and guest and guestLocal and hostRemote)
        assert(math.abs(math.sqrt((host.x-guest.x)^2+(host.y-guest.y)^2)-36)<1e-8)
        assert(host.x==hostRemote.x and host.y==hostRemote.y
            and guest.x==guestLocal.x and guest.y==guestLocal.y)
        assert(track.isDrivable(host.x,host.y) and track.isDrivable(guest.x,guest.y))
        for _,pose in ipairs({host,guest}) do
            local x,y,hit
            if track.resolveMovement then x,y,hit=track.resolveMovement(pose.x,pose.y,pose.x,pose.y)
            else x,y,hit=track.constrainPosition(pose.x,pose.y) end
            assert(not hit and x==pose.x and y==pose.y,"grid includes the kart's physical wall clearance: "..course.id)
        end
        assert(host.heading==original.heading and guest.heading==original.heading)
        assert(track.spawn().x==original.x and track.spawn().y==original.y)
      end
    end
    assert(ready==11,"all eleven finished courses, including four sprints and no development fixture, were checked")
    local bad={width=10,height=10,spawn=function() return {x=5,y=5,heading=0} end,
        isDrivable=function() return true end}
    assert(G.pose(bad,"host")==nil)
    bad.width,bad.height=100,100; bad.spawn=function() return {x=50,y=50,heading=0} end
    bad.isDrivable=function() return false end
    assert(G.pose(bad,"host")==nil)
    bad.isDrivable=function() error("bad geometry") end
    assert(G.pose(bad,"host")==nil)
end
assert(G.view({})==nil and not G.update({},0,accept) and not G.receive({},0,"")
    and not G.stop({},0,"left"))
print("RaceGrid: strict 12-byte profiles, bounded agreement/retries/reentry and eleven-course two-peer grids PASS")
