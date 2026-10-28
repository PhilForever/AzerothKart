-- Pure bounded message delivery simulation; not evidence of native channel reach.
local AK={}
local H=assert(loadfile("addon/AzerothKart/Highscores.lua"))("AzerothKart",AK)
local S=assert(loadfile("addon/AzerothKart/ScoreSync.lua"))("AzerothKart",AK)
local ids={"mirage_raceway","stormwind_city","ironforge_gp",
    "darnassus_canopy","orgrimmar_canyon","undercity_slime","thunder_bluff_skyway","scarlet_graveyard",
    "scarlet_library","scarlet_armory","scarlet_cathedral","warsong_gulch","arathi_basin"}
local versions={stormwind_city=3,ironforge_gp=4,undercity_slime=2,thunder_bluff_skyway=2,
    scarlet_graveyard=3,scarlet_library=3,scarlet_armory=2,scarlet_cathedral=3,warsong_gulch=3,arathi_basin=2}
local contexts={}
for i,id in ipairs(ids) do contexts[i]={trackId=id,
    trackVersion=versions[id] or 1,
    physicsVersion=id=="arathi_basin" and 14 or id=="warsong_gulch" and 13 or 12,
    lapCount=id:match("^scarlet_") and 1 or 3,tickRate=60,rulesVersion=1} end
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
                assert(peer==expected and #payload<=S.MAX_BYTES and #payload+#S.PREFIX<=158)
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
assert(S.PREFIX=="AZKSCR2" and S.MAX_BYTES==151,"schema 2 uses a separate bounded native prefix family")
for _,bad in ipairs({"","2 R O","2 Q O","2 Q X","2 Q O extra","2\tQ O",string.rep("X",152),
    "2 N O 1 12 3 60 1 0 1792750000 0 Amber Stone","2 E O 1 51","2 E O 01 0",
    "2 N O 1 12 3 60 1 1000 1792750000 0 |Hbad|h","2 H 12 1 1 1 1 1 1 1",
    "2 N M 1 12 3 60 1 0 1792750000 0 Amber Stone","2 E M 1 51","2 E M 01 0",
    "2 N M 1 12 3 60 1 1000 1792750000 0 |Hbad|h",
    "1 Q M","1 E M 0 0","1 N M 1 12 3 60 1 1000 1792750000 0 Amber Stone"}) do
    assert(S.decode(bad)==nil,"malformed packets refuse before data merge")
end
assert(S.new({name="Amber Stone",contexts=contexts,store={version=999,boards={},keep=true}},0)==nil)
local unknownKart=record("Amber Stone",1000);unknownKart.kartId="future_kart"
local unknownStore=store({unknownKart})
assert(S.new({name="Amber Stone",contexts=contexts,store=unknownStore},0)==nil,
    "unencodable current saved rows refuse initialization instead of crashing the first digest")
assert(H.View(unknownStore,contexts[1])[1].kartId=="future_kart","existing unsupported data stays intact")
assert(S.new({name="|Hbad",contexts=contexts},0)==nil)
local broken=copy(contexts);broken[#contexts]=copy(broken[1])
assert(S.new({name="Amber Stone",contexts=broken},0)==nil,"each fixed context is unique")
do
    local retired=record("Amber Stone",1000)
    retired.trackId,retired.kartId="test_oval","future_fixture_kart"
    local historical=store({retired})
    local token=assert(S.new({name="Amber Stone",contexts=contexts,store=historical},0))
    assert(H.View(S.snapshot(token),retired)[1].kartId=="future_fixture_kart",
        "retired saved rows remain intact and do not block the active production catalogue")
    assert(S.encode({kind="NEW",record=retired})==nil and S.encode({kind="ROW",record=retired})==nil)
    assert(S.encode({kind="REQUEST",code="O"})==nil
        and S.encode({kind="END",code="O",hash=0,count=0})==nil,
        "retired score records, requests and replies have no public encoding")
    for _,payload in ipairs({"2 Q O","2 E O 0 0",
        "2 N O 1 12 3 60 1 1000 1792750000 0 Amber Stone"}) do
        assert(S.decode(payload)==nil,"retired wire records cannot re-enter the active board")
    end
    local _,published,reason=S.publish(token,retired,0)
    assert(not published and reason=="record","historical scores are never automatically published")
    local retiredContext=copy(contexts);retiredContext[#contexts]=copy(contexts[1])
    retiredContext[#contexts].trackId="test_oval"
    assert(S.new({name="Amber Stone",contexts=retiredContext},0)==nil)
    local missing=copy(contexts);missing[#contexts]=nil
    assert(S.new({name="Amber Stone",contexts=missing},0)==nil,"all active contexts are required")
    assert(S.discover(token,{"Birch Vale"},0))
    assert(S.update(token,0,function(_,payload)
        local hello=assert(S.decode(payload))
        assert(hello.kind=="HELLO" and #hello.hashes==#contexts+1 and hello.hashes[1]==0,
            "the retired O digest slot stays zero without shifting any live course code")
        return true
    end))
end
do
    -- Every active board has its own stable wire code, including all four
    -- one-run sprints. Expanded HELLOs fit the unchanged native byte budget.
    assert(#contexts==13,"thirteen active production boards, with no Test Oval")
    local codes={"M","S","I","D","R","U","T","G","L","A","C","W","B"}
    local rows,otherRows={},{}
    for index,context in ipairs(contexts) do
        local row=record("Amber Stone",1000+index,index)
        local payload=assert(S.encode({kind="NEW",record=row}))
        local decoded=assert(S.decode(payload))
        assert(decoded.code==codes[index] and decoded.record.trackId==context.trackId
            and decoded.record.lapCount==context.lapCount,"stable course code and lap count")
        rows[#rows+1]=row
        otherRows[#otherRows+1]=record("Birch Vale",2000+index,index)
    end
    for index=8,11 do assert(rows[index].lapCount==1,"each Scarlet course shares a one-run score") end
    local a,b=pair(rows,otherRows)
    drive(a,b,0,110) -- One packet/second per peer; both ends start with distinct scores on every board.
    assert(signature(a)==signature(b),"all thirteen mixed-physics boards converge through automatic catch-up")
    for _,context in ipairs(contexts) do assert(#H.View(S.snapshot(b),context)==2) end
    local maximum={}
    for index=1,#contexts+1 do maximum[index]=4294967295 end
    maximum[1]=0 -- retired O is never a legal nonzero digest
    local payload=assert(S.encode({kind="HELLO",catalogHash=4294967295,hashes=maximum}))
    local hello=assert(S.decode(payload))
    assert(#payload+#S.PREFIX==145 and #payload<=S.MAX_BYTES and #hello.hashes==14
        and hello.catalogHash==4294967295 and hello.hashes[14]==4294967295,
        "fixed hexadecimal HELLO fits every full-range digest under the existing native byte ceiling")
    local nonzeroRetired=copy(maximum);nonzeroRetired[1]=4294967295
    assert(S.encode({kind="HELLO",catalogHash=4294967295,hashes=nonzeroRetired})==nil,
        "a retired digest cannot be advertised as an active board")
    for _,replacement in ipairs({"00000001","FFFFFFFF","0","000000000","0000000g","ffffffff"}) do
        local invalidPayload=payload:gsub("^(2 H %x+) 00000000 ","%1 "..replacement.." ",1)
        assert(S.decode(invalidPayload)==nil,"nonzero, noncanonical or malformed retired digests are rejected")
    end
    assert(S.decode(payload:gsub("FFFFFFFF","ffffffff",1))==nil,"hexadecimal fields are canonical uppercase")
    assert(S.decode(payload:gsub("2 H ","2 H  ",1))==nil,"extra HELLO whitespace is rejected")
    assert(S.decode(payload.." 00000000")==nil,"extra digest slots cannot change the catalogue shape")
    local oldHello=payload:sub(1,-10)
    assert(S.decode(oldHello)==nil,
        "a prior thirteen-slot AZKSCR2 HELLO cannot silently omit Arathi")
    local oldPeer=new("Amber Stone")
    assert(S.discover(oldPeer,{"Birch Vale"},0))
    local accepted,why=S.receive(oldPeer,"Birch Vale",oldHello,0)
    assert(not accepted and why=="hello" and S.view(oldPeer).connected==0,
        "the previous catalogue cannot appear connected or schedule catch-up")
    assert(S.decode("1 H 11 1 0 0 0 0 0 0 0")==nil,
        "older seven-slot catalogues cannot silently handshake with new boards")
    assert(S.decode("1 H 11 1 0 0 0 0 0 0 0 0 0")==nil,
        "the previous nine-slot catalogue cannot silently omit Library, Armory or Cathedral")
    assert(S.decode("1 H 12 1 0 0 0 0 0 0 0 0 0 0 0 0")==nil,
        "the former decimal single-physics family cannot silently handshake")
    print("score sync catalogue: 13 active mixed-physics boards/14 slots, O=0, maximum HELLO145B including prefix")
end
do
    local largest=record(string.rep("A",96),H.MAX_TICKS,12,H.MAX_TIMESTAMP)
    largest.trackVersion,largest.physicsVersion,largest.rulesVersion,largest.lapCount=1295,1295,1295,9
    for _,kind in ipairs({"NEW","ROW"}) do
        local payload=assert(S.encode({kind=kind,record=largest}))
        assert(#payload+#S.PREFIX==150 and #payload<=S.MAX_BYTES,
            "every legal context field, timestamp, tick count and 96-byte name fits the native ceiling")
        local parsed=assert(S.decode(payload)).record
        assert(H.BoardKey(parsed)==H.BoardKey(largest) and parsed.playerName==largest.playerName)
    end
    for _,code in ipairs({"M","S","I","D","R","U","T","G","L","A","C","W","B"}) do
        for _,message in ipairs({{kind="REQUEST",code=code},
            {kind="END",code=code,hash=4294967295,count=S.MAX_ROWS}}) do
            local payload=assert(S.encode(message))
            assert(#payload<=S.MAX_BYTES and #payload+#S.PREFIX<=158 and S.decode(payload))
        end
    end
    local maximumContexts=copy(contexts)
    for _,context in ipairs(maximumContexts) do
        context.trackVersion,context.physicsVersion,context.rulesVersion,context.lapCount=1295,1295,1295,9
    end
    local high=assert(S.new({name=largest.playerName,contexts=maximumContexts,store=store({largest})},0))
    assert(S.discover(high,{"Birch Vale"},0))
    assert(S.update(high,0,function(_,payload)
        assert(#payload<=S.MAX_BYTES and #payload+#S.PREFIX==145 and S.decode(payload).kind=="HELLO")
        return true
    end),"maximum legal saved records must not fail while making the first digest")
    local bounds={{"trackVersion",0},{"trackVersion",1296},{"physicsVersion",1296},
        {"rulesVersion",1296},{"lapCount",10},{"tickRate",59},{"tickRate",61}}
    for _,invalid in ipairs(bounds) do
        local row=copy(largest);row[invalid[1]]=invalid[2]
        assert(S.encode({kind="NEW",record=row})==nil,"unencodable wire contexts are rejected explicitly")
        local selected=copy(contexts);selected[1][invalid[1]]=invalid[2]
        assert(S.new({name="Amber Stone",contexts=selected},0)==nil,
            "a current catalogue cannot admit contexts beyond its native wire bounds")
    end
    for _,payload in ipairs({"2 N W 1296 13 3 60 1 1000 1792750000 0 Amber Stone",
        "2 N W 1 1296 3 60 1 1000 1792750000 0 Amber Stone",
        "2 N W 1 13 10 60 1 1000 1792750000 0 Amber Stone",
        "2 N W 1 13 3 61 1 1000 1792750000 0 Amber Stone",
        "2 N W 1 13 3 60 1296 1000 1792750000 0 Amber Stone"}) do
        assert(S.decode(payload)==nil,"incoming contexts obey the same finite wire bounds")
    end
    local historical=copy(largest);historical.playerName="Old Racer";historical.physicsVersion=2147483647
    local saved=store({historical,record("Amber Stone",1000)})
    local token=assert(S.new({name="Amber Stone",contexts=contexts,store=saved},0))
    assert(H.View(S.snapshot(token),historical)[1].totalTicks==H.MAX_TICKS
        and H.View(saved,historical)[1].physicsVersion==2147483647,
        "older unsupported board contexts remain saved without being advertised")
end
local early=new("Amber Stone");assert(S.discover(early,{"Birch Vale"},0))
assert(S.receive(early,"Birch Vale",assert(S.encode({kind="NEW",record=record("Birch Vale",900)})),0),
    "a validated direct update may arrive before HELLO without losing the new score")
assert(H.Rank(S.snapshot(early),contexts[1],"Birch Vale")==1)
for index=9,13 do
    assert(S.receive(early,"Birch Vale",assert(S.encode({kind="NEW",record=record("Birch Vale",900,index)})),index-8),
        "compatible direct new-course scores remain admissible before HELLO")
    assert(H.Rank(S.snapshot(early),contexts[index],"Birch Vale")==1)
end
do
    local localToken=new("Amber Stone")
    assert(S.discover(localToken,{"Birch Vale"},0))
    local swapped=copy(contexts)
    swapped[1].physicsVersion,swapped[12].physicsVersion=13,12
    local foreign=assert(S.new({name="Birch Vale",contexts=swapped},0))
    assert(S.discover(foreign,{"Amber Stone"},0))
    assert(S.update(foreign,0,function(_,payload)
        local accepted,why=S.receive(localToken,"Birch Vale",payload,0)
        assert(not accepted and why=="incompatible",
            "a catalogue with the same versions assigned to the wrong boards cannot handshake")
        return true
    end))
    assert(S.view(localToken).connected==0 and S.view(localToken).received==0)
    for _,index in ipairs({1,12,13}) do
        local wrong=record("Birch Vale",1,index)
        wrong.physicsVersion=index==1 and 13 or 12
        local accepted,why=S.receive(localToken,"Birch Vale",assert(S.encode({kind="NEW",record=wrong})),index)
        assert(not accepted and why=="context" and #H.View(S.snapshot(localToken),contexts[index])==0,
            "exact board physics remains mandatory for pre-handshake announcements")
    end
    local oldArathi=copy(contexts);oldArathi[13].physicsVersion=12
    local oldPeer=assert(S.new({name="Birch Vale",contexts=oldArathi},0))
    assert(S.discover(oldPeer,{"Amber Stone"},0))
    assert(S.update(oldPeer,0,function(_,payload)
        local accepted,why=S.receive(localToken,"Birch Vale",payload,13)
        assert(not accepted and why=="incompatible",
            "an Arathi Physics12 catalogue cannot silently join Physics14 sharing")
        return true
    end))
    local changed=copy(contexts);changed[12].rulesVersion=2
    local rulePeer=assert(S.new({name="Birch Vale",contexts=changed},0))
    assert(S.discover(rulePeer,{"Amber Stone"},0))
    assert(S.update(rulePeer,0,function(_,payload)
        local accepted,why=S.receive(localToken,"Birch Vale",payload,13)
        assert(not accepted and why=="incompatible","the catalogue also binds each board's lap/rule context")
        return true
    end))
end

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
local wrong=record("Birch Vale",1);wrong.physicsVersion=13
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
