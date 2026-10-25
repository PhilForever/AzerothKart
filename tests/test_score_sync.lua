-- Pure bounded message delivery simulation; not evidence of native channel reach.
local AK={}
local H=assert(loadfile("addon/AzerothKart/Highscores.lua"))("AzerothKart",AK)
local S=assert(loadfile("addon/AzerothKart/ScoreSync.lua"))("AzerothKart",AK)
local ids={"test_oval","mirage_raceway","stormwind_city","ironforge_gp",
    "darnassus_canopy","orgrimmar_canyon","undercity_slime"}
local contexts={}
for i,id in ipairs(ids) do contexts[i]={trackId=id,trackVersion=1,physicsVersion=11,
    lapCount=3,tickRate=60,rulesVersion=1} end
local function copy(t)
    if type(t)~="table" then return t end
    local out={};for k,v in pairs(t) do out[k]=copy(v) end;return out
end
local function record(name,ticks,board,stamp)
    local r=copy(contexts[board or 1]);r.playerName=name;r.totalTicks=ticks
    r.finishedAt,r.kartId=stamp or 1792750000,"goblin_mortar_trike";return r
end
local function store(records)
    local out=H.Load(nil)
    for _,r in ipairs(records or {}) do out=select(1,H.Merge(out,r,{r})) end
    return out
end
local function new(name,records)
    return assert(S.new({name=name,contexts=contexts,store=store(records)},0))
end
local function signature(token)
    local parts={}
    for _,context in ipairs(contexts) do
        for _,r in ipairs(H.View(S.snapshot(token),context)) do
            parts[#parts+1]=table.concat({r.trackId,r.playerName,r.totalTicks,r.finishedAt,r.kartId},"/")
        end
    end
    return table.concat(parts,"\n")
end
local function pair(aRecords,bRecords)
    local a,b=new("Amber Stone",aRecords),new("Birch Vale",bRecords)
    assert(S.discover(a,{"Amber Stone","Birch Vale"},0))
    assert(S.discover(b,{"Amber Stone","Birch Vale"},0))
    return a,b
end
local function drive(a,b,first,last,drop)
    for now=first,last do
        local function send(from,to,expected,name)
            return function(peer,payload)
                assert(peer==expected and #payload<=S.MAX_BYTES)
                local m=assert(S.decode(payload))
                if not drop or not drop(from,m,now) then assert(S.receive(to,name,payload,now)) end
                return true
            end
        end
        S.update(a,now,send(a,b,"Birch Vale","Amber Stone"))
        S.update(b,now,send(b,a,"Amber Stone","Birch Vale"))
    end
end

-- Full names survive numeric/code fields without delimiters or fragmentation.
local utfName=string.char(195,133).."se "..string.char(230,157,142)
for _,name in ipairs({"Lene Conradi","  AMBER   STONE  ",utfName,string.rep("A",96),"Anne-Marie O'Brian"}) do
    local r=record(name,H.MAX_TICKS);r.finishedAt=H.MAX_TIMESTAMP
    local payload=assert(S.encode({kind="NEW",record=r}))
    assert(#payload+#S.PREFIX<=158,"current context plus maximum name fits native window")
    local decoded=assert(S.decode(payload))
    assert(decoded.record.playerName==H.NormalizeName(name) and decoded.record.totalTicks==H.MAX_TICKS)
    assert(decoded.record.finishedAt==H.MAX_TIMESTAMP and not payload:find("[|\n\t]"))
end
for _,bad in ipairs({"","1 R O","2 Q O","1 Q X","1 Q O extra","1\tQ O",string.rep("X",241),
    "1 N O 1 11 3 60 1 0 1792750000 0 Amber Stone","1 E O 1 51","1 E O 01 0",
    "1 N O 1 11 3 60 1 1000 1792750000 0 |Hbad|h","1 H 11 1 1 1 1 1 1 1"}) do
    assert(S.decode(bad)==nil,"malformed packets refuse before data merge")
end
assert(S.new({name="Amber Stone",contexts=contexts,store={version=999,boards={},keep=true}},0)==nil)
local unknownKart=record("Amber Stone",1000);unknownKart.kartId="future_kart"
local unknownStore=store({unknownKart})
assert(S.new({name="Amber Stone",contexts=contexts,store=unknownStore},0)==nil,
    "unencodable current saved rows refuse initialization instead of crashing the first digest")
assert(H.View(unknownStore,contexts[1])[1].kartId=="future_kart","existing unsupported data stays intact")
assert(S.new({name="|Hbad",contexts=contexts},0)==nil)
local broken=copy(contexts);broken[7]=copy(broken[1])
assert(S.new({name="Amber Stone",contexts=broken},0)==nil,"each fixed context is unique")
local early=new("Amber Stone");assert(S.discover(early,{"Birch Vale"},0))
assert(S.receive(early,"Birch Vale",assert(S.encode({kind="NEW",record=record("Birch Vale",900)})),0),
    "a validated direct update may arrive before HELLO without losing the new score")
assert(H.Rank(S.snapshot(early),contexts[1],"Birch Vale")==1)

-- A local PB between outgoing and incoming HELLO must survive that handshake.
local flightA,flightB=pair({}, {})
assert(S.update(flightA,0,function(_,payload)
    assert(S.decode(payload).kind=="HELLO")
    return S.receive(flightB,"Amber Stone",payload,0)
end))
assert(select(2,S.publish(flightA,record("Amber Stone",900),0.1)))
assert(S.view(flightA).connected==0 and S.view(flightA).queued>=1)
assert(S.update(flightB,1,function(_,payload)
    assert(S.decode(payload).kind=="HELLO")
    return S.receive(flightA,"Birch Vale",payload,1)
end))
assert(S.update(flightA,1,function(_,payload)
    assert(S.decode(payload).kind=="NEW","the first post-handshake packet publishes the queued PB")
    return S.receive(flightB,"Amber Stone",payload,1)
end))
assert(H.Rank(S.snapshot(flightB),contexts[1],"Amber Stone")==1,
    "an in-flight handshake does not postpone a new result until the 60-second digest")

-- Automatic HELLO/request/row/end exchange converges both saved snapshots.
local a,b=pair({record("Amber Stone",900),record("Cedar Vale",800)},{record("Birch Vale",1000)})
drive(a,b,0,25)
assert(signature(a)==signature(b) and #H.View(S.snapshot(a),contexts[1])==3)
assert(S.view(a).connected==1 and S.view(a).received>0 and S.view(a).lastReceived)
local detached=S.snapshot(a);detached.boards[H.BoardKey(contexts[1])].rows[1].totalTicks=1
assert(H.View(S.snapshot(a),contexts[1])[1].totalTicks==800,"saved snapshot is detached")
local oldRevision=S.view(a).revision
local notice,changed=S.publish(a,record("Amber Stone",700),30)
assert(changed and notice.rank==1 and notice.tier==3)
local beforeAttempts=S.view(a).attempted
local nextPayload
assert(S.update(a,30,function(_,payload) nextPayload=payload;return S.receive(b,"Amber Stone",payload,30) end))
assert(S.decode(nextPayload).kind=="NEW" and H.Rank(S.snapshot(b),contexts[1],"Amber Stone")==1)
assert(S.view(a).attempted==beforeAttempts+1 and S.view(a).revision==oldRevision+1)
assert(not S.update(a,30,function() error("paced callback must not run") end))
local replay,again=S.publish(a,record("Amber Stone",700),31)
assert(replay==nil and not again and S.view(a).revision==oldRevision+1,"same finish does not repeat notice")
assert(not select(2,S.publish(a,record("Birch Vale",1),31)),"local publishing cannot impersonate a peer")
assert(not S.receive(a,"Unknown Player",nextPayload,31),"only discovered participants are admitted")
assert(not S.receive(a,"Birch Vale",nextPayload,31),"direct announcement must match native sender")
assert(not S.receive(a,"Birch Vale",assert(S.encode({kind="ROW",record=record("Birch Vale",1)})),31),
    "unsolicited catchup data is rejected")
local wrong=record("Birch Vale",1);wrong.physicsVersion=12
assert(not S.receive(a,"Birch Vale",assert(S.encode({kind="NEW",record=wrong})),31),"wrong rules do not merge")

-- Tier crossings happen only through publish, not through catch-up reception.
local ranks={}
for i=1,11 do ranks[#ranks+1]=record(("Racer %02d"):format(i),1000+i*100) end
ranks[#ranks+1]=record("Amber Stone",2200)
local ranked=new("Amber Stone",ranks)
local ten=assert(S.publish(ranked,record("Amber Stone",1950),1))
assert(ten.rank==10 and ten.enteredTier==10)
local three=assert(S.publish(ranked,record("Amber Stone",1250),2))
assert(three.rank==3 and three.enteredTier==3)
local replayPlacement,replayed=S.publish(ranked,record("Amber Stone",1250),3)
assert(not replayPlacement and not replayed)
local original=signature(ranked)
assert(not select(2,S.publish(ranked,record("Amber Stone",1250,1,1),4)))
assert(signature(ranked)==original,"equal-time metadata cannot create a local announcement")

-- Local updates preempt a long bulk response; responses are lazy and bounded.
local many={}
for i=1,49 do many[i]=record(("Player %02d"):format(i),1000+i*10) end
many[50]=record("Amber Stone",2000)
local sender,receiver=pair(many,{})
drive(sender,receiver,0,3)
assert(select(2,S.publish(sender,record("Amber Stone",500),4)))
local urgent
assert(S.update(sender,4,function(_,payload) urgent=assert(S.decode(payload));return true end))
assert(urgent.kind=="NEW" and urgent.record.totalTicks==500,"new PB takes priority over bulk rows")
assert(S.view(sender).queued<=60,"one-peer jobs remain bounded even for full board catchup")

-- A locally accepted but lost row causes retry after END; valid partial rows
-- are kept, and the eventual replay converges without duplicate entries.
local lostA,lostB=pair({record("Amber Stone",900),record("Cedar Vale",800)}, {})
local dropped=false
drive(lostA,lostB,0,40,function(from,m)
    if from==lostA and m.kind=="ROW" and not dropped then dropped=true;return true end
end)
assert(dropped and signature(lostA)==signature(lostB),"dropped catchup row is recovered automatically")

-- Failed sends are paced/backed off, and callback reentry cannot double-send.
local failed=new("Amber Stone")
assert(S.discover(failed,{"Birch Vale"},0))
for _,now in ipairs({0,2,6}) do
    assert(not S.update(failed,now,function() error("simulated native failure") end))
end
assert(S.view(failed).attempted==3 and S.view(failed).failed==3)
S.update(failed,7,function() error("must back off") end)
assert(S.view(failed).attempted==3)
assert(S.update(failed,66,function()
    assert(not S.update(failed,66,function() error("no recursive send") end))
    return true
end))
assert(S.view(failed).attempted==4 and S.view(failed).sent==1)
assert(not S.discover(failed,{[1]="Birch Vale",[3]="Cedar Vale"},66),"invalid roster is atomic")
assert(S.view(failed).peers==1)
assert(S.discover(failed,{},67) and S.view(failed).peers==0 and S.view(failed).queued==0)
assert(not S.update(failed,66,function() return true end) and S.view(failed).phase=="closed", "backward time closes controller")

local names={}
for i=1,33 do names[i]="Player "..i end
local bounded=new("Amber Stone")
assert(not S.discover(bounded,names,0) and S.view(bounded).peers==0)
names[33]=nil;assert(S.discover(bounded,names,0) and S.view(bounded).peers==32)
local rx=new("Amber Stone");assert(S.discover(rx,{"Birch Vale"},0))
local hello
local remote=new("Birch Vale");assert(S.discover(remote,{"Amber Stone"},0))
S.update(remote,0,function(_,payload) hello=payload;return true end)
for i=1,8 do assert(S.receive(rx,"Birch Vale",hello,0)) end
local allowed,rate=S.receive(rx,"Birch Vale",hello,0)
assert(not allowed and rate=="rate" and S.view(rx).queued<=8)
assert(S.receive(rx,"Birch Vale",hello,1),"incoming allowance refills with explicit time")
print("score sync: bounded readable packets, automatic catchup/convergence, priority PB publication, tier notices, retries and roster/identity guards")
