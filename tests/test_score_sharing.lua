-- Mocked native world/roster/whisper integration, not live Forever evidence.
local originalPrint=print
local GLOBALS={"AzerothKartDB","C_ChatInfo","Enum","GetTime","GetServerTime",
    "InCombatLockdown","NameUtil","UnitNameUnmodified","Constants","issecretvalue",
    "CreateFrame","JoinPermanentChannel","GetChannelName","GetNumDisplayChannels","GetChannelDisplayInfo",
    "DEFAULT_CHAT_FRAME","SetSelectedDisplayChannel","GetSelectedDisplayChannel",
    "ListChannelByName","date","GetNumGroupMembers","IsInRaid"}
local function pack(...) return {n=select("#",...),...} end
local function using(client,fn,...)
    local prior={}
    for _,name in ipairs(GLOBALS) do prior[#prior+1]={name=name,value=_G[name]};_G[name]=client.globals[name] end
    _G.AzerothKartDB=client.db
    local result=pack(pcall(fn,...))
    for _,entry in ipairs(prior) do _G[entry.name]=entry.value end
    if not result[1] then error(result[2],0) end
    return unpack(result,2,result.n)
end
local function folded(value)
    return (value:gsub("[A-Z]",function(char) return string.char(char:byte()+32) end))
end
local function bus()
    local network={now=0,clients={},ordered={},queue={}}
    function network:roster()
        local names={}
        for _,client in ipairs(self.ordered) do
            if client.enabled and client.joined then names[#names+1]=client.name end
        end
        return names
    end
    function network:rosterEvent()
        for _,client in ipairs(self.ordered) do
            if client.enabled and client.joined then
                self.queue[#self.queue+1]={to=client,event="CHANNEL_ROSTER_UPDATE",args={3,#self:roster()}}
            end
        end
    end
    function network:client(name,db)
        local client={name=name,db=db or {schemaVersion=1},namespace={},frames={},messages={},
            sends={},refreshes=0,joins=0,registered={},enabled=true,joined=false,
            combat=false,chatLocked=false,core={},globals={}}
        self.clients[folded(name)]=client;self.ordered[#self.ordered+1]=client
        local g=client.globals
        g.GetTime=function() return network.now end
        g.GetServerTime=function() return 1792860000+math.floor(network.now) end
        g.NameUtil={GetUnmodifiedUnitFullName=function(unit)
            if unit=="player" then return name end
            if client.groupPending then return nil end
            local index=tonumber(unit:match("^raid(%d+)$"))
            if index then return client.group and client.group[index] end
            index=tonumber(unit:match("^party(%d+)$"))
            assert(index,"only native group units are enumerated")
            local peers={}
            for _,member in ipairs(client.group or {}) do
                if folded(member)~=folded(name) then peers[#peers+1]=member end
            end
            return peers[index]
        end}
        g.GetNumGroupMembers=function() return client.group and #client.group or 0 end
        g.IsInRaid=function() return client.raid==true end
        g.InCombatLockdown=function() return client.combat end
        g.issecretvalue=function() return false end
        g.Enum={RegisterAddonMessagePrefixResult={Success=0,DuplicatePrefix=1},SendAddonMessageResult={Success=0}}
        g.DEFAULT_CHAT_FRAME={AddMessage=function(_,text) client.messages[#client.messages+1]=text end}
        g.SetSelectedDisplayChannel=function() error("sharing cannot change native channel selection") end
        g.GetSelectedDisplayChannel=function() error("sharing does not need native selection") end
        g.ListChannelByName=function() error("sharing cannot require a manual roster command") end
        g.JoinPermanentChannel=function(channel)
            assert(channel=="AzerothKartScores","only the dedicated opt-in channel is joined")
            client.joins=client.joins+1;client.joined=true;network:rosterEvent();return 0,channel
        end
        g.GetChannelName=function(channel)
            assert(channel=="AzerothKartScores")
            return client.joined and 6 or 0,channel
        end
        g.GetNumDisplayChannels=function() return client.joined and 3 or 2 end
        g.GetChannelDisplayInfo=function(index)
            if index==1 then return "Channels",true,true,nil,nil,false end
            if index==2 then return "General",false,true,1,1,true end
            if index==3 and client.joined then
                return "AzerothKartScores",false,true,6,client.rosterCountPending and 0 or #network:roster(),true
            end
        end
        g.C_ChatInfo={
            RegisterAddonMessagePrefix=function(prefix)
                local duplicate=client.registered[prefix];client.registered[prefix]=true
                return duplicate and 1 or 0
            end,
            InChatMessagingLockdown=function() return client.chatLocked end,
            GetChannelRosterInfo=function(display,index)
                assert(display==3,"roster display index is different from local channel ID6")
                if client.rosterPending then return nil end
                return network:roster()[index],false,false,"unused-guid"
            end,
            SendAddonMessageLogged=function(prefix,payload,route,target)
                assert(prefix=="AZKSCR2" and route=="WHISPER","only the current bounded logged whisper route")
                assert(#prefix+#payload<=158,"every attempt respects the shared byte ceiling")
                local previous=client.sends[#client.sends]
                assert(not previous or network.now-previous.at>=1,"one send per client per second maximum")
                assert(client.core.akNetworkOwner==client.namespace.ScoreSharing
                    and client.core.akNetworkSending==client.namespace.ScoreSharing,
                    "native call has transient ownership and reentry markers")
                local packet={from=client,to=network.clients[folded(target)],prefix=prefix,
                    payload=payload,route=route,sender=name,at=network.now}
                client.sends[#client.sends+1]=packet
                if client.onSend then client.onSend(packet) end
                network.queue[#network.queue+1]=packet
                return 0
            end,
        }
        g.CreateFrame=function(kind)
            assert(kind=="Frame","one pooled frame is enough")
            local frame={scripts={},events={}}
            function frame:SetScript(event,fn) self.scripts[event]=fn end
            function frame:RegisterEvent(event) self.events[event]=true;return true end
            client.frames[#client.frames+1]=frame
            return frame
        end
        using(client,function()
            for _,module in ipairs({"Track","MirageRaceway","Circuit","CapitalCities","Dungeon","LayeredTrack","ScarletCrusade","Battlegrounds","Courses",
                "Physics","Highscores","SoloRecords","ScoreSync","ScoreDiscovery","ScoreSharing"}) do
                assert(loadfile("addon/AzerothKart/"..module..".lua"))("AzerothKart",client.namespace)
            end
            client.namespace.Menu={OnScoresChanged=function() client.refreshes=client.refreshes+1 end}
            client.namespace.SoloRecords.Init()
            client.namespace.ScoreSharing.Init(client.core)
        end)
        assert(#client.frames==1,"initialization creates only one score receiver/update frame")
        client.frame=client.frames[1]
        function client:fire(event,...)
            local args=pack(...)
            using(self,function() self.frame.scripts.OnEvent(self.frame,event,unpack(args,1,args.n)) end)
        end
        function client:view(trackId)
            return using(self,function() return self.namespace.SoloRecords.GetView(trackId or "mirage_raceway") end)
        end
        function client:finish(ticks,trackId)
            return using(self,function()
                local records=self.namespace.SoloRecords
                local track=self.namespace.Courses.build(trackId or "mirage_raceway",self.namespace.Track.crossesGate)
                local token=records.Begin(track,"goblin_mortar_trike")
                local laps=track.laps or 3
                local race={status="finished",targetLaps=laps,laps={completedLaps=laps},
                    startTick=180,finishTick=180+ticks,totalTicks=ticks}
                return records.Finish(token,race,false),token,race
            end)
        end
        return client
    end
    function network:flush()
        local count=0
        while #self.queue>0 do
            count=count+1;assert(count<1000,"native event queue cannot loop indefinitely")
            local item=table.remove(self.queue,1)
            local target=item.to
            if target and target.enabled then
                if item.event then target:fire(item.event,unpack(item.args))
                elseif target.registered[item.prefix] then
                    target:fire("CHAT_MSG_ADDON_LOGGED",item.prefix,item.payload,item.route,item.sender)
                end
            end
        end
    end
    function network:step(seconds)
        local ticks=seconds/0.25
        assert(ticks%1==0,"test cadence uses exact quarter seconds")
        for _=1,ticks do
            self.now=self.now+0.25
            for _,client in ipairs(self.ordered) do
                if client.enabled then
                    using(client,function() client.frame.scripts.OnUpdate(client.frame,0.25) end)
                end
            end
            self:flush()
        end
    end
    function network:untilTrue(test,seconds)
        for _=1,seconds/0.25 do if test() then return end;self:step(0.25) end
        assert(test(),"automatic native flow did not converge before the bounded deadline")
    end
    return network
end
local function group(clients,names,raid)
    for _,client in ipairs(clients) do
        client.group=names
        client.raid=raid or false
        client:fire("GROUP_ROSTER_UPDATE")
    end
end

local function congratulations(client)
    local count=0
    for _,message in ipairs(client.messages) do
        if message:find("Top 3",1,true) or message:find("Top 10",1,true) or message:find("New #1",1,true) then
            count=count+1
        end
    end
    return count
end

-- The actual expanded Courses catalogue must initialize native sharing. Every
-- board catches up automatically; a new one-run sprint then publishes promptly.
do
    local allMaps=bus()
    local owner,learner=allMaps:client("Course Keeper"),allMaps:client("Course Learner")
    local historical=owner.namespace.SoloRecords.Context(owner.namespace.Courses.build("mirage_raceway",owner.namespace.Track.crossesGate))
    historical.physicsVersion,historical.playerName,historical.totalTicks=11,owner.name,9999
    historical.finishedAt,historical.kartId=1792750000,"goblin_mortar_trike"
    owner.db.highscores=owner.namespace.Highscores.Submit(owner.namespace.Highscores.Load(nil),historical)
    using(owner,function() owner.namespace.SoloRecords.Init() end)
    local ids={}
    for _,course in ipairs(owner.namespace.Courses.LIST) do
        if owner.namespace.Courses.available(course.id) then ids[#ids+1]=course.id end
    end
    assert(#ids==13,"thirteen finished courses, including Arathi and layered Warsong")
    for index,id in ipairs(ids) do
        local saved=owner:finish(2000+index,id)
        assert(saved.saved,"eligible current board saves: "..id)
        assert(saved.playerName=="Course Keeper" and saved.placement and saved.placement.rank==1
            and saved.placement.knownPlayers==1 and saved.placement.previousRank==nil,
            "even a cold first finish returns exact placement without preseeding itself: "..id)
    end
    owner:fire("PLAYER_ENTERING_WORLD");learner:fire("PLAYER_ENTERING_WORLD");allMaps:flush()
    allMaps:untilTrue(function()
        for _,id in ipairs(ids) do if #learner:view(id).rows~=1 then return false end end
        return true
    end,90)
    for index,id in ipairs(ids) do
        local row=learner:view(id).rows[1]
        assert(row.playerName==owner.name and row.totalTicks==2000+index,
            "automatic login catch-up retains the correct production board: "..id)
        assert(row.physicsVersion==(id=="warsong_gulch" and 13 or 12),
            "mixed Physics versions retain the exact per-map board: "..id)
    end
    assert(learner:view("scarlet_graveyard").rows[1].lapCount==1)
    assert(learner:view("thunder_bluff_skyway").rows[1].lapCount==3)
    assert(learner:view("warsong_gulch").rows[1].lapCount==3)
    assert(learner:view("arathi_basin").rows[1].lapCount==3
        and learner:view("arathi_basin").rows[1].physicsVersion==12,
        "Arathi catch-up uses its own flat three-lap board")
    assert(owner.namespace.Highscores.View(owner.db.highscores,historical)[1].totalTicks==9999,
        "adding Physics13 sharing never migrates/deletes historical Physics11 records")
    assert(learner:view("scarlet_graveyard").rows[1].trackVersion==3
        and learner:view("thunder_bluff_skyway").rows[1].trackVersion==2,
        "catch-up uses the reviewed drive-fix geometry versions")
    assert(#learner:view("test_oval").rows==0 and congratulations(learner)==0,
        "retired boards remain hidden and login catch-up never celebrates")
    local result=owner:finish(1800,"scarlet_graveyard")
    assert(result.saved and owner:view("scarlet_graveyard").rows[1].lapCount==1)
    allMaps:untilTrue(function() return learner:view("scarlet_graveyard").rows[1].totalTicks==1800 end,5)
    for _,id in ipairs({"scarlet_library","scarlet_armory","scarlet_cathedral"}) do
        assert(learner:view(id).rows[1].lapCount==1,"new dungeon catch-up retains sprint context: "..id)
        assert(owner:finish(1700,id).saved,"new dungeon finish saves: "..id)
        allMaps:untilTrue(function() return learner:view(id).rows[1].totalTicks==1700 end,5)
    end
    local warsong=owner:finish(1600,"warsong_gulch")
    assert(warsong.saved and warsong.placement and owner:view("warsong_gulch").context.physicsVersion==13)
    allMaps:untilTrue(function() return learner:view("warsong_gulch").rows[1].totalTicks==1600 end,5)
    local arathi=owner:finish(1500,"arathi_basin")
    assert(arathi.saved and arathi.placement and owner:view("arathi_basin").context.physicsVersion==12)
    allMaps:untilTrue(function() return learner:view("arathi_basin").rows[1].totalTicks==1500 end,5)
    assert(learner:view("mirage_raceway").rows[1].physicsVersion==12,
        "new layered finish notification does not merge into an existing flat board")
end

-- Only native world/roster events start discovery and handshake; finishing a
-- real eligible SoloRecords run is the sole publishing action in this path.
local network=bus()
local a,b=network:client("Amber Stone"),network:client("Birch Vale")
a:fire("PLAYER_ENTERING_WORLD");b:fire("PLAYER_ENTERING_WORLD")
network:flush()
network:untilTrue(function() return a:view().connected==1 and b:view().connected==1 end,15)
assert(a.joins==1 and b.joins==1,"login joins automatically without a manual command")
local loadCount,originalLoad=0,a.namespace.Highscores.Load
a.namespace.Highscores.Load=function(...)
    loadCount=loadCount+1;return originalLoad(...)
end
a:fire("CHAT_MSG_ADDON_LOGGED","UNRELATED","other addon data","WHISPER",b.name)
a:fire("CHAT_MSG_ADDON_LOGGED","AZKSCR1","1 H old build","WHISPER",b.name)
a:fire("CHAT_MSG_ADDON_LOGGED","AZKSCR2","other route","PARTY",b.name)
a:fire("CHAT_MSG_ADDON_LOGGED","AZKSCR2","unknown sender","WHISPER","Unlisted Racer")
a.namespace.Highscores.Load=originalLoad
assert(loadCount==0,"unrelated prefix/route/unlisted sender is rejected before parsing the whole cache")
local beforeRefresh=b.refreshes
local result,token,race=a:finish(1800)
assert(result.saved and result.message:find("Top 3",1,true),"eligible finish visibly congratulates a top3 entry")
assert(congratulations(a)==1 and congratulations(b)==0)
local finishedAt=network.now
network:untilTrue(function() return #b:view().rows==1 end,5)
assert(network.now-finishedAt<=2,"connected peers receive a new best promptly under the paced mock route")
assert(b:view().rows[1].playerName==a.name and b:view().rows[1].totalTicks==1800
    and b.refreshes>beforeRefresh,"peer board updates automatically and refreshes the visible menu")
local record=a:view().rows[1]
local lastNew
for _,packet in ipairs(a.sends) do if packet.payload:find("^2 N ") then lastNew=packet end end
assert(lastNew,"a completed best generated an automatic result packet")
b:fire("CHAT_MSG_ADDON_LOGGED",lastNew.prefix,lastNew.payload,lastNew.route,lastNew.sender)
b:fire("CHAT_MSG_ADDON_LOGGED",lastNew.prefix,lastNew.payload,lastNew.route,lastNew.sender)
local replay=using(a,function() return a.namespace.SoloRecords.Finish(token,race,false) end)
assert(replay==nil and congratulations(a)==1 and congratulations(b)==0,
    "replayed packets/callbacks never repeat local congratulations")
local copied=b:view();copied.rows[1].totalTicks=1
assert(b:view().rows[1].totalTicks==1800,"menu receives detached cached rows")
assert(b.db.communityScores and b.db.communityScores~=a.db.communityScores,"each client persists its own cache")

-- A fresh namespace models an actual addon reload using the same saved table.
b:fire("PLAYER_LEAVING_WORLD");b.enabled,b.joined=false,false
local saved=b.db
local reloaded=network:client(b.name,saved)
reloaded:fire("PLAYER_ENTERING_WORLD");network:flush();network:step(3)
assert(reloaded:view().rows[1].totalTicks==1800 and congratulations(reloaded)==0,
    "reload preserves shared records and catches up quietly")
local newcomer=network:client("Cedar Vale")
newcomer:fire("PLAYER_ENTERING_WORLD");network:flush()
network:untilTrue(function() return #newcomer:view().rows==1 end,30)
assert(newcomer:view().rows[1].playerName==a.name and congratulations(newcomer)==0,
    "login catch-up needs no exports, commands or repeated celebrations")

-- Combat, client chat lockdown and another Core lease defer queued work.
for _,reason in ipairs({"combat","chat","lease"}) do
    local client=a
    if reason=="combat" then client.combat=true
    elseif reason=="chat" then client.chatLocked=true
    else client.core.akNetworkOwner={} end
    local sent=#client.sends
    assert(client:finish(1800-({combat=100,chat=200,lease=300})[reason]).saved)
    network:step(3)
    assert(#client.sends==sent,"blocked native state must suppress outgoing score packets: "..reason)
    client.combat,client.chatLocked,client.core.akNetworkOwner=false,false,nil
    network:step(2)
    assert(#client.sends==sent,"sharing waits two observed idle seconds after yielding: "..reason)
    network:step(0.5)
    assert(#client.sends>sent,"queued results resume after the idle guard: "..reason)
end
local sawReentry=false
a.onSend=function()
    sawReentry=true
    assert(a.core.akNetworkOwner and a.core.akNetworkSending,
        "a reentrant race/probe arm sees an occupied Core lease")
end
assert(a:finish(1400).saved);network:step(2)
assert(sawReentry and a.core.akNetworkOwner==nil and a.core.akNetworkSending==nil,
    "transient send markers prevent reentry and clean up afterward")
for _,client in ipairs(network.ordered) do assert(#client.frames==1,"ticks allocate no additional score frames") end

-- Visible notices use actual prior community placement, not merely a new PB.
local H=a.namespace.Highscores
local context=a.namespace.SoloRecords.Context(a.namespace.Courses.build("mirage_raceway",a.namespace.Track.crossesGate))
local ranking=H.Load(nil)
for index=1,12 do
    local row={}
    for field,value in pairs(context) do row[field]=value end
    row.playerName=index==12 and "Ranked Racer" or ("Racer %02d"):format(index)
    row.totalTicks,row.finishedAt,row.kartId=1000+index*100,1792756800,"goblin_mortar_trike"
    ranking=H.Merge(ranking,context,{row})
end
local rankedNetwork=bus()
local ranked=rankedNetwork:client("Ranked Racer",{schemaVersion=1,
    highscores=H.Load(ranking),communityScores=H.Load(ranking)})
ranked:fire("PLAYER_ENTERING_WORLD");rankedNetwork:flush()
local topTen=ranked:finish(1950)
assert(topTen.saved and topTen.message:find("Top 10",1,true) and topTen.message:find("#10",1,true),
    "a real cached rank12 to rank10 transition produces the visible top10 notice")
assert(topTen.playerName=="Ranked Racer" and topTen.placement.rank==10
    and topTen.placement.knownPlayers==12 and topTen.placement.scope=="known_board",
    "the exact finish carries its captured name and shared placement to presentation")
topTen.placement.rank=999
assert(ranked:view().rows[10].playerName=="Ranked Racer",
    "presentation metadata cannot mutate retained score rows")
local topThree=ranked:finish(1250)
assert(topThree.saved and topThree.message:find("Top 3",1,true) and congratulations(ranked)==2,
    "the later rank10 to rank3 transition produces one highest-tier celebration")
local withinTier=ranked:finish(1150)
assert(withinTier.saved and congratulations(ranked)==2,"improving within a tier does not replay its entry notice")
assert(withinTier.placement and withinTier.placement.rank==2,
    "a better time within the same tier still supplies exact placement without a new chat notice")
local firstPlace=ranked:finish(1000)
assert(firstPlace.saved and firstPlace.message:find("New #1",1,true) and congratulations(ranked)==3,
    "taking first from an existing ranked position produces its own visible notice")

-- Root/community replacements remain untouched and cannot drain a pending queue.
local isolated=bus()
local x,y=isolated:client("Dawn Ember"),isolated:client("Ember Dawn")
x:fire("PLAYER_ENTERING_WORLD");y:fire("PLAYER_ENTERING_WORLD");isolated:flush()
isolated:untilTrue(function() return x:view().connected==1 and y:view().connected==1 end,15)
assert(x:finish(1700).saved)
local replacement={schemaVersion=999,communityScores={version=999,keep={true}},custom={keep=true}}
local inner=replacement.communityScores
x.db=replacement
local sent=#x.sends
isolated:step(4)
assert(x.db==replacement and replacement.communityScores==inner and inner.keep[1] and replacement.custom.keep,
    "root replacement is never migrated or overwritten")
assert(#x.sends==sent,"a changed root blocks pending outgoing work immediately")

-- A valid in-place cache edit is still external data, not permission to replace
-- the edited table or send already-queued records from an obsolete snapshot.
local editedNetwork=bus()
local edited,other=editedNetwork:client("Frost Ember"),editedNetwork:client("Ember Frost")
edited:fire("PLAYER_ENTERING_WORLD");other:fire("PLAYER_ENTERING_WORLD");editedNetwork:flush()
editedNetwork:untilTrue(function() return edited:view().connected==1 and other:view().connected==1 end,15)
assert(edited:finish(1900).saved)
local editedChild=edited.db.communityScores
local editedKey=edited.namespace.Highscores.BoardKey(edited.namespace.SoloRecords.Context(edited.namespace.Courses.build("mirage_raceway",edited.namespace.Track.crossesGate)))
local editedRow=editedChild.boards[editedKey].rows[1]
local editedStamp=editedRow.finishedAt+10
editedRow.finishedAt=editedStamp
assert(select(2,edited.namespace.Highscores.Load(editedChild)),"the external edit remains a valid store")
local editedSent=#edited.sends
editedNetwork:step(4)
assert(edited.db.communityScores==editedChild and editedChild.boards[editedKey].rows[1]==editedRow
    and editedRow.finishedAt==editedStamp and #edited.sends==editedSent,
    "valid in-place edits are preserved and block draining a stale publication queue")

-- The native roster can be larger than the explicitly bounded synchronization
-- trial. Clear prior admission, expose capacity status, then reconnect normally
-- when a complete later roster fits again; never retain a stale connected view.
local crowdedNetwork=bus()
local crowded,friend=crowdedNetwork:client("Crowded Racer"),crowdedNetwork:client("Known Racer")
crowded:fire("PLAYER_ENTERING_WORLD");friend:fire("PLAYER_ENTERING_WORLD");crowdedNetwork:flush()
crowdedNetwork:untilTrue(function() return crowded:view().connected==1 and friend:view().connected==1 end,15)
local normalRoster=crowdedNetwork.roster
crowdedNetwork.roster=function(self)
    local names=normalRoster(self)
    for index=1,32 do names[#names+1]=("Additional Racer %02d"):format(index) end
    return names
end
local beforeCrowding=#crowded.sends
crowdedNetwork:rosterEvent();crowdedNetwork:flush()
crowdedNetwork:untilTrue(function()
    return crowded:view().publication=="Sharing capacity reached (32-peer test limit)"
end,2) -- allow the native event debounce before the next bounded scan
local crowdedView=crowded:view()
assert(crowdedView.connected==0 and crowdedView.peers==0 and crowdedView.queued==0
    and crowdedView.publication=="Sharing capacity reached (32-peer test limit)",
    "a 33-peer roster clears stale connection state and shows the explicit capacity limit: "
        ..tostring(crowdedView.connected).."/"..tostring(crowdedView.peers).."/"
        ..tostring(crowdedView.queued).."/"..tostring(crowdedView.publication))
local oldHello=friend.sends[1]
crowded:fire("CHAT_MSG_ADDON_LOGGED",oldHello.prefix,oldHello.payload,oldHello.route,oldHello.sender)
crowdedNetwork:step(2)
assert(crowded:view().connected==0 and #crowded.sends==beforeCrowding,
    "formerly admitted peers cannot revive the over-capacity engine or trigger sends")
crowdedNetwork.roster=normalRoster
crowdedNetwork:rosterEvent();crowdedNetwork:flush()
crowdedNetwork:untilTrue(function() return crowded:view().connected==1 and friend:view().connected==1 end,15)
assert(crowded:view().publication=="Automatic sharing connected" and #crowded.sends>beforeCrowding,
    "a later complete roster below capacity recovers without manual exchange or reload")

for _,community in ipairs({{version=999,boards={},custom={keep=true}},
        {version=1,boards=false},false}) do
    local protected=bus()
    local db={schemaVersion=1,communityScores=community,preferences={keep=true}}
    local preferences=db.preferences
    local client=protected:client("Future Keeper",db)
    client:fire("PLAYER_ENTERING_WORLD");protected:flush();protected:step(3)
    assert(db.communityScores==community and db.preferences==preferences and #client.sends==0 and client.joins==0,
        "malformed/future community data remains preserved and read-only")
    local localResult=client:finish(2000)
    assert(localResult.saved and db.highscores and db.communityScores==community,
        "read-only community state does not prevent ordinary local personal bests")
end

local failedRegistration=bus()
local retryClient=failedRegistration:client("Registration Retry")
local registerCalls=0
retryClient.globals.C_ChatInfo.RegisterAddonMessagePrefix=function()
    registerCalls=registerCalls+1;return 99
end
retryClient:fire("PLAYER_ENTERING_WORLD")
failedRegistration:step(10)
assert(registerCalls==1 and #retryClient.sends==0,
    "a refused prefix registration does not hammer the native API each background update")
failedRegistration:step(30)
assert(registerCalls==2,"registration recovers through a bounded retry interval")

-- Reproduce the reported permanent channel-cache wait. Merely joining must
-- not magically populate the mock roster; current native group names suffice.
do
    local n=bus()
    local a=n:client("Fourtwenty Blazeit",{schemaVersion=1,preferences={keep=true}})
    local b=n:client("Bæppmeg Plis")
    a.rosterPending,a.rosterCountPending=true,true
    b.rosterPending,b.rosterCountPending=true,true
    group({a,b},{a.name,b.name})
    a:fire("PLAYER_ENTERING_WORLD");b:fire("PLAYER_ENTERING_WORLD");n:flush()
    n:untilTrue(function() return a:view().connected==1 and b:view().connected==1 end,15)
    assert(a:view().discovery.channel=="pending" and a:view().discovery.group=="ready"
        and a:view().publication=="Automatic sharing connected (known peers)",
        "group discovery connects without a requested public roster or hidden UI selection")
    assert(a:finish(638,"scarlet_graveyard").saved and b:finish(865,"scarlet_graveyard").saved)
    n:untilTrue(function() return #a:view("scarlet_graveyard").rows==2
        and #b:view("scarlet_graveyard").rows==2 end,15)
    for _,client in ipairs({a,b}) do
        local rows=client:view("scarlet_graveyard").rows
        assert(rows[1].playerName==a.name and rows[1].totalTicks==638
            and rows[2].playerName==b.name and rows[2].totalTicks==865,
            "both boards display the same two saved sprint totals in rank order")
        assert(#client.frames==1)
    end
    a.groupPending=true
    a:fire("GROUP_ROSTER_UPDATE")
    assert(a:finish(630,"scarlet_graveyard").saved)
    n:untilTrue(function() return b:view("scarlet_graveyard").rows[1].totalTicks==630 end,5)
    assert(a:view().connected==1,
        "a pending group event preserves the valid lease and urgent update rather than clearing its queue")
    a.groupPending=false
    a:fire("GROUP_ROSTER_UPDATE")
    n:step(31)
    assert(a:view().connected==1 and b:view().connected==1 and a.db.preferences.keep,
        "repeated channel-cache misses cannot erase a valid group admission or preferences")
    group({a,b},{}) -- a native authoritative leave, rather than pending data
    local previousReceived=a:view().lastReceived
    local oldHello=b.sends[1]
    a:fire("CHAT_MSG_ADDON_LOGGED",oldHello.prefix,oldHello.payload,oldHello.route,oldHello.sender)
    assert(a:view().lastReceived==previousReceived,
        "an explicit group leave invalidates that source before the next scan")
    n:step(0.25)
    local beforeA,beforeB=#a.sends,#b.sends
    n:step(3)
    assert(a:view().peers==0 and b:view().peers==0 and #a.sends==beforeA and #b.sends==beforeB,
        "leaving the group removes that source and its queued traffic")
    assert(#a:view("scarlet_graveyard").rows==2 and #b:view("scarlet_graveyard").rows==2,
        "losing discovery never deletes learned scores")
end

-- A validated session peer also works ungrouped. Configured-but-unconfirmed
-- candidates are covered at SessionTransport's native receive boundary.
do
    local n=bus()
    local a,b=n:client("Session Racer"),n:client("Session Friend")
    a.rosterPending,a.rosterCountPending=true,true
    b.rosterPending,b.rosterCountPending=true,true
    a:fire("PLAYER_ENTERING_WORLD");b:fire("PLAYER_ENTERING_WORLD");n:flush();n:step(2)
    assert(#a.sends==0 and #b.sends==0)
    using(a,function() assert(a.namespace.ScoreSharing.RememberPeer(b.name)) end)
    using(b,function() assert(b.namespace.ScoreSharing.RememberPeer(a.name)) end)
    n:untilTrue(function() return a:view().connected==1 and b:view().connected==1 end,15)
    assert(a:view().discovery.remembered==1 and a:view().discovery.group=="ready")
    assert(a:finish(1600).saved)
    n:untilTrue(function() return #b:view().rows==1 end,5)
    b.enabled=false
    n.now=n.now+1801
    local priorReceived=a:view().lastReceived
    local hello=b.sends[1]
    a.core.akNetworkOwner={}
    a:fire("CHAT_MSG_ADDON_LOGGED",hello.prefix,hello.payload,hello.route,hello.sender)
    assert(a:view().lastReceived==priorReceived,
        "an expired remembered contact cannot renew itself before an idle scan, even during a race lease")
    a.core.akNetworkOwner=nil
    n:step(0.25)
    assert(a:view().peers==0 and a:view().discovery.remembered==0 and #a:view().rows==1,
        "an offline remembered partner expires after30minutes without deleting scores")
end

-- Overlapping sources are deduplicated. A transient channel miss cannot tear
-- down an active queue; an indefinitely missing source has an exact lease end.
do
    local n=bus()
    local a,b=n:client("Cache Keeper"),n:client("Cache Friend")
    group({a,b},{a.name,b.name},true)
    a:fire("PLAYER_ENTERING_WORLD");b:fire("PLAYER_ENTERING_WORLD");n:flush()
    n:untilTrue(function() return a:view().connected==1 and b:view().connected==1 end,15)
    assert(a:view().peers==1 and b:view().peers==1,"channel and raid do not duplicate the same recipient")
    a.rosterPending=true
    a:fire("CHANNEL_ROSTER_UPDATE")
    assert(a:finish(1500).saved)
    n:untilTrue(function() return #b:view().rows==1 end,5)
    assert(a:view().connected==1 and a:view().peers==1)
    a.groupPending=true
    a:fire("CHANNEL_ROSTER_UPDATE")
    n:step(31)
    assert(a:view().peers==0 and #a:view().rows==1,
        "partial data expires both channel/group admission rather than retaining stale peers forever")
end

-- Group leases also expire on receive, not only when the next idle update
-- gets a chance to reconcile sources after a long foreground race/combat.
do
    local n=bus()
    local a,b=n:client("Group Lease Keeper"),n:client("Group Lease Friend")
    a.rosterPending,a.rosterCountPending=true,true
    b.rosterPending,b.rosterCountPending=true,true
    group({a,b},{a.name,b.name})
    a:fire("PLAYER_ENTERING_WORLD");b:fire("PLAYER_ENTERING_WORLD");n:flush()
    n:untilTrue(function() return a:view().connected==1 and b:view().connected==1 end,15)
    local previous=a:view().lastReceived
    local hello=b.sends[1]
    a.groupPending=true;a.core.akNetworkOwner={}
    n.now=n.now+16
    a:fire("CHAT_MSG_ADDON_LOGGED",hello.prefix,hello.payload,hello.route,hello.sender)
    assert(a:view().lastReceived==previous,"a pending group cannot keep receiving beyond its15second lease")
end

originalPrint("score sharing: automatic native-roster whispers, finish notices, quiet catch-up/reload, bounded pacing and preserved saves (mock APIs)")
