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

print("score discovery: bounded cached display-index rosters, full-name peers, pending/secret refusal and no native UI mutations")
