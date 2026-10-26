-- Injected cached-roster doubles; no native discovery or delivery evidence.
local namespace={}
assert(loadfile("addon/AzerothKart/Highscores.lua"))("AzerothKart",namespace)
local D=assert(loadfile("addon/AzerothKart/ScoreDiscovery.lua"))("AzerothKart",namespace)
assert(namespace.ScoreDiscovery==D)
local CHANNEL,SELF="AzerothKartScores","Lene Conradi"
local function fixture()
    local e={rows={"Lene Conradi","Flaturlative Breeze"},calls={},count=2,total=3}
    local api={
        GetNumDisplayChannels=function() return e.total end,
        GetChannelDisplayInfo=function(index)
            if index==1 then return "Custom",true,true,nil,nil,false end
            if index==2 then return "General",false,true,1,50,true end
            if index==3 then return "aZeRoThKaRtScOrEs",false,true,6,e.count,true end
        end,
        C_ChatInfo={GetChannelRosterInfo=function(display,index)
            e.calls[#e.calls+1]={display,index}
            assert(display==3,"roster reads must use displayIndex, not local channel ID6")
            return e.rows[index],false,false,"ignored-guid"
        end},
        SetSelectedDisplayChannel=function() error("must not change native channel selection") end,
        ListChannelByName=function() error("must not request a roster or print chat") end,
        JoinPermanentChannel=function() error("reader never joins channels") end,
        CreateFrame=function() error("reader never creates a frame") end,
    }
    return e,api
end
local function reject(api,reason)
    local out,why=D.Read(api,CHANNEL,SELF)
    assert(out==nil and why==reason,tostring(why).." expected "..reason)
end

local e,api=fixture()
local snapshot=assert(D.Read(api,CHANNEL,SELF))
assert(snapshot.ready and snapshot.displayIndex==3 and snapshot.localID==6
    and snapshot.members==2 and #snapshot.peers==1 and snapshot.peers[1]=="Flaturlative Breeze")
assert(#e.calls==2 and e.calls[1][1]==3 and e.rows[1]==SELF,"input and native UI state untouched")
snapshot.peers[1]="changed"; snapshot.localID=999
assert(D.Read(api,CHANNEL,SELF).peers[1]=="Flaturlative Breeze","snapshots are detached")
e.rows={SELF};e.count=1
local alone=assert(D.Read(api,CHANNEL,SELF))
assert(alone.ready and #alone.peers==0 and alone.members==1,"a populated self-only roster is ready")
e.count=0;reject(api,"pending")
e.count=2;e.rows={SELF};reject(api,"pending")
e.rows={SELF,"Invalid|Name"};reject(api,"pending")
e.rows={SELF,string.char(255)};reject(api,"pending")
e.rows={SELF,{}};reject(api,"pending")

e,api=fixture()
local utf=string.char(195,133).."sa Stone"
e.rows={SELF,"  flaturlative   breeze  ","FLATURLATIVE BREEZE",utf,"Zebra Stone","lene conradi"}
e.count=#e.rows
local names=assert(D.Read(api,CHANNEL,SELF)).peers
assert(#names==3 and names[1]=="FLATURLATIVE BREEZE" and names[2]=="Zebra Stone" and names[3]==utf,
    "full names normalize/dedupe by ASCII case and sort deterministically by UTF8 bytes")
e.rows={utf,"Zebra Stone","FLATURLATIVE BREEZE",SELF,"flaturlative breeze","LENE CONRADI"}
local reordered=assert(D.Read(api,CHANNEL,SELF)).peers
for index,name in ipairs(names) do assert(reordered[index]==name,"roster order cannot affect peer order") end

e,api=fixture()
for _,missing in ipairs({"GetNumDisplayChannels","GetChannelDisplayInfo","C_ChatInfo"}) do
    local original=api[missing];api[missing]=nil;reject(api,"unsupported");api[missing]=original
end
local getter=api.C_ChatInfo.GetChannelRosterInfo
api.C_ChatInfo.GetChannelRosterInfo=nil;reject(api,"unsupported")
api.C_ChatInfo.GetChannelRosterInfo=getter
for _,bad in ipairs({false,"bad",{}}) do reject(bad,"unsupported") end
assert(select(2,D.Read(api,"",SELF))=="invalid_channel")
assert(select(2,D.Read(api,CHANNEL,"|Hbad|h"))=="invalid_name")
assert(select(2,D.Read(api,CHANNEL,nil))=="invalid_name")
api.issecretvalue=false;reject(api,"unsupported");api.issecretvalue=nil
e.total=129;reject(api,"too_large")
e.total=-1;reject(api,"unreadable")
e.total=1.5;reject(api,"unreadable")
e.total=0/0;reject(api,"unreadable")
e.total=0;reject(api,"pending")
e.total=3;e.count=257;reject(api,"too_large")
e.count=-1;reject(api,"unreadable")
e.count=1.5;reject(api,"unreadable")
e.count=nil;reject(api,"pending")

e,api=fixture()
local originalInfo=api.GetChannelDisplayInfo
api.GetChannelDisplayInfo=function(index)
    if index==3 then return CHANNEL,false,false,0,2,true end
    return originalInfo(index)
end
reject(api,"unreadable")
api.GetChannelDisplayInfo=function(index)
    if index==3 then return CHANNEL,false,false,6,2,false end
    return originalInfo(index)
end
reject(api,"pending")
api.GetChannelDisplayInfo=function(index)
    if index==2 or index==3 then return CHANNEL,false,false,index,2,true end
    return originalInfo(index)
end
reject(api,"ambiguous")
api.GetChannelDisplayInfo=function() error("native refusal") end;reject(api,"api_error")
api.GetChannelDisplayInfo=originalInfo
api.GetNumDisplayChannels=function() error("native refusal") end;reject(api,"api_error")
api.GetNumDisplayChannels=function() return 3 end
api.C_ChatInfo.GetChannelRosterInfo=function() error("native refusal") end;reject(api,"api_error")

-- All native values used in comparisons/types must be screened first.
e,api=fixture()
local secret={}
api.issecretvalue=function(value) return value==secret end
e.rows[2]=secret;reject(api,"protected")
e.rows[2]="Flaturlative Breeze";e.count=secret;reject(api,"protected")
e.count=2;e.total=secret;reject(api,"protected")
e.total=3
api.GetChannelDisplayInfo=function(index)
    if index==3 then return secret,false,false,6,2,true end
    return originalInfo(index)
end
reject(api,"protected")
api.GetChannelDisplayInfo=originalInfo
assert(select(2,D.Read(api,secret,SELF))=="protected")
assert(select(2,D.Read(api,CHANNEL,secret))=="protected")
api.issecretvalue=function() error("unreadable secret test") end;reject(api,"protected")
api.issecretvalue=function() return nil end;reject(api,"protected")

-- A refresh replacing the display entry during a native callback is retried.
e,api=fixture()
local nativeRoster=api.C_ChatInfo.GetChannelRosterInfo
api.C_ChatInfo.GetChannelRosterInfo=function(display,index)
    local name=nativeRoster(display,index)
    if index==2 then e.count=3 end
    return name
end
reject(api,"pending")

-- Native group getters provide an independent complete roster when a channel
-- has never populated its member cache. These doubles do not prove live APIs.
local GROUP_SELF,GROUP_FRIEND="Fourtwenty Blazeit","Bæppmeg Plis"
local function groupFixture()
    local state={count=2,raid=false,names={player=GROUP_SELF,party1=GROUP_FRIEND},calls=0}
    local groupApi={
        GetNumGroupMembers=function() return state.count end,
        IsInRaid=function() return state.raid end,
        NameUtil={GetUnmodifiedUnitFullName=function(unit)
            state.calls=state.calls+1
            local name=state.names[unit]
            if state.onRead then state.onRead(unit,state.calls) end
            return name
        end},
        SetSelectedDisplayChannel=function() error("group discovery cannot select a channel") end,
        JoinPermanentChannel=function() error("group discovery cannot join a channel") end,
        CreateFrame=function() error("group discovery cannot allocate frames") end,
    }
    return state,groupApi
end
local function rejectGroup(groupApi,reason,selfName)
    local value,why=D.ReadGroup(groupApi,selfName or GROUP_SELF)
    assert(value==nil and why==reason,tostring(why).." expected group "..reason)
end

local g,groupApi=groupFixture()
local group=assert(D.ReadGroup(groupApi,GROUP_SELF))
assert(group.ready and not group.raid and group.members==2 and #group.peers==1
    and group.peers[1]==GROUP_FRIEND and g.calls==4,
    "two full native names can be read without a channel member cache")
group.peers[1]="changed"
assert(D.ReadGroup(groupApi,GROUP_SELF).peers[1]==GROUP_FRIEND,"group snapshots are detached")
g.count=0;g.names={};g.calls=0
assert(#D.ReadGroup(groupApi,GROUP_SELF).peers==0 and g.calls==0,"solo has no invented peers or unit reads")
g.count=1;g.names.player=GROUP_SELF
assert(D.ReadGroup(groupApi,GROUP_SELF).members==1 and #D.ReadGroup(groupApi,GROUP_SELF).peers==0)

g,groupApi=groupFixture()
g.count,g.raid=5,true
g.names={raid1=GROUP_FRIEND,raid2="  ZEBRA   STONE  ",raid3="zebra stone",
    raid4=GROUP_SELF,raid5="Amber Stone"}
local raid=assert(D.ReadGroup(groupApi,GROUP_SELF))
assert(raid.raid and raid.members==5 and #raid.peers==3 and raid.peers[1]=="Amber Stone"
    and raid.peers[2]==GROUP_FRIEND and raid.peers[3]=="ZEBRA STONE",
    "raid members dedupe ASCII case and sort stable UTF8 bytes, excluding self wherever listed")
g.names.raid4="Other Person"
rejectGroup(groupApi,"pending") -- a raid missing the native self identity is incomplete
g.names.raid4=GROUP_SELF
g.names.raid2,g.names.raid5=g.names.raid5,g.names.raid2
local reordered=assert(D.ReadGroup(groupApi,GROUP_SELF))
for index,name in ipairs(raid.peers) do assert(reordered.peers[index]==name,"unit order does not change group order") end
g.count=40
for index=1,40 do g.names["raid"..index]=("Native Racer %02d"):format(index) end
g.names.raid37=GROUP_SELF
assert(D.MAX_GROUP_MEMBERS==40 and #D.ReadGroup(groupApi,GROUP_SELF).peers==39,
    "the bounded discovery cap is native group size, not racing capacity")

for _,missing in ipairs({"GetNumGroupMembers","IsInRaid","NameUtil"}) do
    g,groupApi=groupFixture();groupApi[missing]=nil
    rejectGroup(groupApi,"unsupported");assert(g.calls==0)
end
g,groupApi=groupFixture();groupApi.NameUtil.GetUnmodifiedUnitFullName=nil;rejectGroup(groupApi,"unsupported")
for _,bad in ipairs({false,"bad",{}}) do rejectGroup(bad,"unsupported") end
g,groupApi=groupFixture();groupApi.issecretvalue=false;rejectGroup(groupApi,"unsupported")
groupApi.issecretvalue=nil
assert(select(2,D.ReadGroup(groupApi,nil))=="invalid_name")
assert(select(2,D.ReadGroup(groupApi,"Bad|Name"))=="invalid_name")
for _,bad in ipairs({-1,1.5,0/0}) do g.count=bad;rejectGroup(groupApi,"unreadable") end
g.count=41;rejectGroup(groupApi,"too_large")
g.count=nil;rejectGroup(groupApi,"pending")
g.count=2;g.raid=1;rejectGroup(groupApi,"unreadable")
g.raid=nil;rejectGroup(groupApi,"pending")
g.count,g.raid=0,true;rejectGroup(groupApi,"pending")

g,groupApi=groupFixture()
groupApi.GetNumGroupMembers=function() error("native refusal") end;rejectGroup(groupApi,"api_error")
g,groupApi=groupFixture()
groupApi.IsInRaid=function() error("native refusal") end;rejectGroup(groupApi,"api_error")
g,groupApi=groupFixture()
groupApi.NameUtil.GetUnmodifiedUnitFullName=function() error("native refusal") end;rejectGroup(groupApi,"api_error")
for _,bad in ipairs({false,"Bad|Name",string.char(255),{}}) do
    g,groupApi=groupFixture();g.names.party1=bad;rejectGroup(groupApi,"pending")
end
g,groupApi=groupFixture();g.names.party1=nil;rejectGroup(groupApi,"pending")
g.names.party1=GROUP_FRIEND;g.names.player="Wrong Identity";rejectGroup(groupApi,"pending")

g,groupApi=groupFixture()
local protected={}
groupApi.issecretvalue=function(value) return value==protected end
g.names.party1=protected;rejectGroup(groupApi,"protected")
g.names.party1=GROUP_FRIEND;g.count=protected;rejectGroup(groupApi,"protected")
g.count=2;g.raid=protected;rejectGroup(groupApi,"protected")
g.raid=false;assert(select(2,D.ReadGroup(groupApi,protected))=="protected")
groupApi.issecretvalue=function() error("secret check refused") end;rejectGroup(groupApi,"protected")
groupApi.issecretvalue=function() return nil end;rejectGroup(groupApi,"protected")

for _,change in ipairs({"count","kind","member"}) do
    g,groupApi=groupFixture()
    g.onRead=function(_,calls)
        if calls~=2 then return end
        if change=="count" then g.count=3
        elseif change=="kind" then g.raid=true
        else g.names.party1="Changed Roster" end
    end
    rejectGroup(groupApi,"pending")
end

print("score discovery: bounded cached channels and independent native groups; full names, stable copies, partial/protected refusal and no UI mutations")
