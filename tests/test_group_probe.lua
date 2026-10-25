-- API doubles establish accounting/lifecycle only, never native multicast.
local originalPrint=print
local globalNames={"C_ChatInfo","Enum","GetTime","GetBuildInfo","NameUtil","IsInRaid","GetNumGroupMembers",
    "InCombatLockdown","issecretvalue","CreateFrame"}
local names={"Amber Stone","Birch Vale","Cedar Grove","Dusk Thorn",
    "Ember Reed","Frost Brook","Golden Leaf","Hazel Wood"}
local PREFIX="AZKGRP1"
local unpack=unpack or table.unpack
local function using(e,fn,...)
    local saved={}
    for index,name in ipairs(globalNames) do saved[index]=_G[name]; _G[name]=e.globals[name] end
    local result={pcall(fn,...)}
    for index,name in ipairs(globalNames) do _G[name]=saved[index] end
    assert(result[1],result[2])
    return unpack(result,2)
end
local function client(index,count,raid)
    local e={identity=names[index],members={},raid=raid,now=0,combat=false,locked=false,registrations=0,
        attempts={},reserved={},reports={},events={},registerResult=0,sendResult=0,globals={}}
    for i=1,count do e.members[i]=names[i] end
    local originalEvent=function() end
    e.frame={scripts={OnEvent=originalEvent}}
    function e.frame:RegisterEvent(event)
        assert(event=="CHAT_MSG_ADDON_LOGGED" or event=="GROUP_ROSTER_UPDATE")
        if e.eventThrows then error("mock event failure") end
        e.events[event]=true
    end
    function e.frame:UnregisterEvent(event) e.events[event]=nil end
    function e.frame:SetScript(name,callback)
        assert(name=="OnUpdate","Core keeps the event script")
        if callback and e.updateThrows then error("mock update failure") end
        self.scripts[name]=callback
    end
    e.globals.Enum={RegisterAddonMessagePrefixResult={Success=0,DuplicatePrefix=1},
        SendAddonMessageResult={Success=0,InvalidPrefix=1,InvalidMessage=2,AddonMessageThrottle=3,
            InvalidChatType=4,NotInGroup=5,TargetRequired=6,InvalidChannel=7,ChannelThrottle=8,
            GeneralError=9,NotInGuild=10,AddOnMessageLockdown=11,TargetOffline=12}}
    e.globals.GetTime=function() if e.clockThrows then error("mock clock failure") end; return e.now end
    e.globals.GetBuildInfo=function() return "1.60.1","70532" end
    e.globals.IsInRaid=function() return e.raid end
    e.globals.GetNumGroupMembers=function() return #e.members end
    e.globals.InCombatLockdown=function() return e.combat end
    e.globals.issecretvalue=function(value) return e.secret~=nil and value==e.secret end
    e.globals.CreateFrame=function() error("GroupProbe must not allocate a frame") end
    e.globals.NameUtil={GetUnmodifiedUnitFullName=function(unit)
        if unit=="player" then return e.identity end
        local i=tonumber(unit:match("^raid(%d+)$"))
        if i then return e.members[i] end
        i=tonumber(unit:match("^party(%d+)$"))
        if i then
            local other={}
            for _,name in ipairs(e.members) do if name~=e.identity then other[#other+1]=name end end
            return other[i]
        end
    end}
    e.globals.C_ChatInfo={RegisterAddonMessagePrefix=function(prefix)
        assert(prefix==PREFIX); e.registrations=e.registrations+1
        if e.onRegister then e.onRegister() end
        if e.registerThrows then error("mock register failure") end
        return e.registerResult
    end,SendAddonMessageLogged=function(prefix,payload,route,target)
        assert(prefix==PREFIX and type(payload)=="string" and #prefix+#payload<=158)
        local packet={prefix=prefix,payload=payload,route=route,target=target,time=e.now}
        e.attempts[#e.attempts+1]=packet
        if e.onSend then e.onSend(packet) end
        if e.sendThrows then error("mock send failure") end
        return e.sendResult
    end,SendAddonMessage=function() error("no unlogged fallback") end,
        InChatMessagingLockdown=function() return e.locked end}
    e.ns={UI={active=false},SessionTransport={ReserveDiagnosticSend=function(owner,now,bytes)
        assert(owner==e.probe and e.frame.akNetworkOwner==owner and not e.frame.akNetworkSending)
        assert(now==e.now and bytes>=1 and bytes<=158)
        if e.budgetMode then return false,e.budgetMode end
        if e.budgetOpaque then return e.budgetOpaque end
        local calls,total=0,0
        for _,attempt in ipairs(e.reserved) do
            if now-attempt.time<1 then calls=calls+1;total=total+attempt.bytes end
        end
        local last=e.reserved[#e.reserved]
        if (last and now-last.time<0.5) or calls>=2 or total+bytes>158 then return false,"budget" end
        e.reserved[#e.reserved+1]={time=now,bytes=bytes}
        return true
    end}}
    using(e,function()
        e.probe=assert(loadfile("addon/AzerothKart/GroupProbe.lua"))("AzerothKart",e.ns)
        assert(e.probe==e.ns.GroupProbe and e.registrations==0 and #e.attempts==0)
        assert(e.probe.Init(e.frame,function(text) e.reports[#e.reports+1]=text end))
        assert(not next(e.events) and not e.frame.scripts.OnUpdate and not e.probe.IsActive(),
            "load and Init are idle")
    end)
    function e:call(method,...) return using(self,self.probe[method],...) end
    function e:update(now) self.now=now; return self:call("Update") end
    function e:message(packet,sender)
        return self:call("Message",packet.prefix,packet.payload,packet.route,sender)
    end
    function e:stopped(reason)
        local view=self:call("GetView")
        assert(view.phase=="stopped" and view.reason==reason, tostring(view.reason).." expected "..reason)
        assert(not self.probe.IsActive() and not self.frame.akNetworkOwner and
            not self.frame.akNetworkSending and not self.frame.scripts.OnUpdate and not next(self.events))
        assert(self.frame.scripts.OnEvent==originalEvent)
        return view
    end
    return e
end
local function data(sequence,stamp,code,route)
    return {prefix=PREFIX,payload=("1 D %s %d %d"):format(code or "ABC123",sequence,stamp or 0),route=route or "PARTY"}
end

-- A normal two-member PARTY and an eight-member RAID exercise exact fan-out
-- with one broadcaster, not eight independent race telemetry senders.
for _,configuration in ipairs({{count=2,raid=false,route="PARTY"},{count=8,raid=true,route="RAID"}}) do
    local clients={}
    for i=1,configuration.count do clients[i]=client(i,configuration.count,configuration.raid) end
    local host=clients[1]
    for i=2,#clients do assert(clients[i]:call("Command","listen ABC123 "..configuration.route)) end
    assert(host:call("Command","host ABC123 "..configuration.route))
    for i,e in ipairs(clients) do
        e.onSend=function(packet)
            assert(e.frame.akNetworkSending==e.probe,"native callback holds the reentry marker")
            if packet.route==configuration.route then
                assert(i==1 and packet.target==nil,"one native multicast, never seven sends")
                for _,receiver in ipairs(clients) do receiver:message(packet,e.identity) end
            else
                assert(packet.route=="WHISPER" and packet.target==host.identity and i~=1)
                host:message(packet,e.identity)
            end
        end
    end
    for tick=0,250 do
        local now=tick/10
        for _,e in ipairs(clients) do e.now=now end
        for _,e in ipairs(clients) do e:update(now) end
    end
    local view=host:stopped("window_complete")
    assert(view.build=="70532" and view.sent==10 and view.accepted==10 and view.matched==10*(#clients-1)
        and view.selfEchoes==10 and view.missedSlots==0 and view.errors==0)
    assert(#host.attempts==10 and #view.peers==#clients-1 and view.dataAttempts=="1111111111")
    for _,peer in ipairs(view.peers) do assert(peer.matched==10 and peer.rttMS.count==10 and peer.sequences=="1111111111") end
    for i=2,#clients do
        local received=clients[i]:stopped("window_complete")
        assert(received.received==10 and received.acksSent==10 and #clients[i].attempts==10)
        assert(received.peers[1].name==host.identity and received.peers[1].received==10)
    end
    view.peers[1].name="mutated"; view.peers[1].rttMS.count=999
    assert(host:call("GetView").peers[1].name==names[2] and host:call("GetView").peers[1].rttMS.count==10,
        "views and nested RTT arrays are detached")
    assert(not host:call("Start","host","ABC123",configuration.route),"a finished code cannot rearm")
end

-- Accepted multicast without any peer is not a delivery pass; hitches skip
-- slots rather than spending a backlog in a burst.
do
    local e=client(1,2,false)
    assert(e:call("Start","host","ABC123","PARTY"))
    e:update(0); e:update(0.999); assert(#e.attempts==0,"quiet handoff precedes the first send")
    e:update(1); e:update(1); e:update(9); e:update(9); e:update(20); e:update(24)
    local v=e:stopped("window_complete")
    assert(v.sent==2 and v.accepted==2 and v.matched==0 and v.missedSlots==8
        and v.dataAttempts=="1...1.....","hitches cannot send missed DATA slots")
end

-- Duplicates/reordering and rejected sender/session/route are measured without
-- producing duplicate ACK traffic. Unattempted ACKs cannot create evidence.
do
    local e=client(2,3,false)
    assert(e:call("Start","listen","ABC123","PARTY"))
    e:message(data(1),"Outsider Person")
    e:message(data(1,0,"WRONG1"),names[1])
    e:message(data(1,0,nil,"RAID"),names[1])
    e:message(data(2),names[1]); e:message(data(2),names[1]); e:message(data(1),names[1])
    assert(#e.attempts==0,"events only enqueue ACKs")
    e:update(0); e:update(0.999); assert(#e.attempts==0,"listeners observe the same quiet handoff")
    e:update(1); e:update(1); e:update(1.499); assert(#e.attempts==1)
    e:update(1.5); assert(#e.attempts==2)
    local v=e:call("GetView")
    assert(v.rejected==3 and v.received==2 and v.duplicates==1 and v.reordered==1 and v.acksSent==2)
    e:message(data(3),names[3]); e:stopped("multiple_hosts")
    local h=client(1,2,false)
    assert(h:call("Start","host","DEF456","PARTY"))
    h:message({prefix=PREFIX,payload="1 A DEF456 1 0",route="WHISPER"},names[2])
    assert(h:call("GetView").matched==0 and h:call("GetView").lastReject=="unattempted_ack")
    h:call("Stop","manual_stop"); h:stopped("manual_stop")
end

for _,kind in ipairs({"budget","unavailable","opaque"}) do
    local e=client(1,2,false)
    assert(e:call("Start","host","ABC123","PARTY"))
    if kind=="opaque" then e.budgetOpaque={} else e.budgetMode=kind end
    e:update(1)
    assert(#e.attempts==0)
    if kind=="budget" then
        assert(e:call("GetView").deferred==1 and e.probe.IsActive())
        e.budgetMode=nil; e:update(1.05); assert(#e.attempts==1)
        e:call("Stop","manual_stop")
    else e:stopped("budget_unavailable") end
end

do
    local h=client(1,2,false)
    assert(h:call("Start","host","ABC123","PARTY")); h:update(1)
    h.now=1.3
    h:message({prefix=PREFIX,payload="1 A ABC123 1 1000",route="WHISPER"},names[2])
    local peer=h:call("GetView").peers[1]
    assert(peer.matched==1 and peer.rttMS.p50==300 and peer.rttMS.p95==300,
        "RTT uses the sender's attempted timestamp, not the listener's clock")
    h:call("Stop","manual_stop")
end
do
    local e=client(1,2,false)
    assert(e:call("Start","host","ABC123","PARTY"))
    local other,handler={},function() end
    e.frame.akNetworkOwner=other; e.frame.scripts.OnUpdate=handler
    e:update(1)
    assert(e:call("GetView").reason=="lease_lost" and e.frame.akNetworkOwner==other
        and e.frame.scripts.OnUpdate==handler and #e.attempts==0,
        "losing a lease stops diagnostics without tearing down the new owner's scripts")
end

for _,kind in ipairs({"throttle","failure","nil","secret","throws"}) do
    local e=client(1,2,false)
    assert(e:call("Start","host","ABC123","PARTY"))
    if kind=="throttle" then e.sendResult=3
    elseif kind=="failure" then e.sendResult=12
    elseif kind=="nil" then e.sendResult=nil
    elseif kind=="secret" then e.secret=13; e.sendResult=13
    else e.sendThrows=true end
    e:update(1)
    assert(#e.attempts==1 and #e.reserved==1)
    e:stopped(kind=="throttle" and "throttled" or kind=="failure" and "send_refused" or "send_error_or_opaque")
end

for _,event in ipairs({"PLAYER_REGEN_DISABLED","PLAYER_LEAVING_WORLD","PLAYER_LOGOUT","GROUP_ROSTER_UPDATE"}) do
    local e=client(1,2,true)
    assert(e:call("Start","host","ABC123","RAID"))
    if event=="GROUP_ROSTER_UPDATE" then e.members[2]="Changed Member" end
    e:call("HandleEvent",event)
    e:stopped(event=="GROUP_ROSTER_UPDATE" and "group_changed" or event)
    e:update(100); assert(#e.attempts==0)
end
do
    local e=client(1,2,true)
    assert(e:call("Start","host","ABC123","RAID"))
    e:call("HandleEvent","GROUP_ROSTER_UPDATE")
    assert(e.probe.IsActive(),"same roster event is inert")
    e:update(1); e:update(0.9); e:stopped("clock_unavailable")
end
do
    local e=client(2,2,false)
    assert(e:call("Command","listen ABC123"),"route can follow the explicitly read native group form")
    e:update(30); e:stopped("no_host"); assert(#e.attempts==0)
end
for _,kind in ipairs({"solo","large","route","secret_name","missing_api","prefix","event","update","busy"}) do
    local e=client(1,2,false)
    if kind=="solo" then table.remove(e.members)
    elseif kind=="large" then for i=3,9 do e.members[i]="Member "..i end
    elseif kind=="route" then e.raid=true
    elseif kind=="secret_name" then e.secret=e.identity
    elseif kind=="missing_api" then e.globals.NameUtil=nil
    elseif kind=="prefix" then e.registerResult=5
    elseif kind=="event" then e.eventThrows=true
    elseif kind=="update" then e.updateThrows=true
    else e.frame.akNetworkOwner={} end
    assert(not e:call("Start","host","ABC123","PARTY"),kind.." must refuse")
    assert(#e.attempts==0 and not e.probe.IsActive())
    if kind~="busy" then assert(not e.frame.akNetworkOwner and not next(e.events) and not e.frame.scripts.OnUpdate) end
end
do
    local e=client(1,2,false)
    local other={}
    e.globals.GetBuildInfo=function() e.frame.akNetworkOwner=other; return "1.60.1","70532" end
    assert(not e:call("Start","host","ABC123","PARTY") and e.frame.akNetworkOwner==other
        and e.registrations==0 and #e.attempts==0,"a native preflight reentry cannot overwrite another lease")
end
do
    local e=client(1,2,false)
    assert(e:call("Start","host","ABC123","PARTY"))
    e.onSend=function()
        e:call("Stop","manual_stop")
        assert(e.frame.akNetworkSending==e.probe,"stop retains marker until native callback unwinds")
        assert(not e:call("Start","host","DEF456","PARTY"),"reentry cannot acquire an in-flight native call")
    end
    e:update(1); e:stopped("manual_stop")
    assert(#e.attempts==1)
end
originalPrint("group probe: finite PARTY/RAID fan-out, eight-member mocked receipts, pacing/identity/roster/lease guards and isolated evidence PASS (native delivery NOT RUN)")
