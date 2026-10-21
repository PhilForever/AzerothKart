-- Mocked addon adapter checks; no client traffic or transport-capacity claim.
local originalPrint = print
local globals = {"C_ChatInfo", "Enum", "GetTime", "InCombatLockdown",
    "DEFAULT_CHAT_FRAME", "print", "CreateFrame"}
local sendNames = {"Success", "InvalidPrefix", "InvalidMessage", "AddonMessageThrottle",
    "InvalidChatType", "NotInGroup", "TargetRequired", "InvalidChannel", "ChannelThrottle",
    "GeneralError", "NotInGuild", "AddOnMessageLockdown", "TargetOffline"}

local function withMock(test)
    local previous = {}
    for _,name in ipairs(globals) do previous[#previous+1] = {name=name,value=_G[name]} end
    local env = {now=0,combat=false,registerCalls=0,registerResult=0,sends={},output={},
        createdFrames=0,eventCalls=0,unregisterCalls=0,scriptCalls=0,sendResult=0}
    local onEvent = function() end
    env.frame = {events={},scripts={OnEvent=onEvent}}
    function env.frame:RegisterEvent(event)
        env.eventCalls = env.eventCalls+1
        assert(event == "CHAT_MSG_ADDON_LOGGED")
        if env.eventThrows then error("mock event refusal") end
        if env.eventResult == false then return false end
        self.events[event] = true
        return env.eventResult -- nil is the normal event-registration return.
    end
    function env.frame:UnregisterEvent(event)
        env.unregisterCalls = env.unregisterCalls+1
        assert(event == "CHAT_MSG_ADDON_LOGGED")
        self.events[event] = nil
    end
    function env.frame:SetScript(name,callback)
        env.scriptCalls = env.scriptCalls+1
        assert(name == "OnUpdate", "the bootstrap OnEvent handler must remain owned by Core")
        if callback and env.updateThrows then error("mock script refusal") end
        self.scripts[name] = callback
    end
    local function output(message)
        assert(type(message) == "string")
        env.output[#env.output+1] = message
    end
    _G.CreateFrame = function() env.createdFrames=env.createdFrames+1; error("must reuse bootstrap frame") end
    _G.GetTime = function()
        if env.clockThrows then error("mock clock refusal") end
        return env.now
    end
    _G.InCombatLockdown = function()
        if env.combatThrows then error("mock combat-state refusal") end
        return env.combat
    end
    _G.DEFAULT_CHAT_FRAME = {AddMessage=function(_,message) output(message) end}
    _G.print = output
    local results = {}
    for index,name in ipairs(sendNames) do results[name] = index-1 end
    _G.Enum = {RegisterAddonMessagePrefixResult={Success=0,DuplicatePrefix=1},
        SendAddonMessageResult=results}
    _G.C_ChatInfo = {
        RegisterAddonMessagePrefix=function(prefix)
            env.registerCalls = env.registerCalls+1
            assert(prefix == "AZKART1")
            if env.registerThrows then error("mock registration refusal") end
            return env.registerResult
        end,
        SendAddonMessageLogged=function(prefix,payload,channel,target)
            assert(prefix == "AZKART1" and channel == "WHISPER" and target == (env.expectedPeer or "Tester-Realm"))
            env.sends[#env.sends+1] = {payload=payload,channel=channel,target=target}
            if env.sendThrows then error("private mock API error must not enter evidence") end
            return env.sendResult
        end,
        SendAddonMessage=function() error("unlogged route must never be used") end,
        InChatMessagingLockdown=function()
            if env.chatThrows then error("mock chat state unavailable") end
            return env.chatLocked == true
        end,
    }
    local ok,err = pcall(function()
        local namespace = {UI={active=false}}
        local probe = assert(loadfile("addon/AzerothKart/NetworkProbe.lua"))("AzerothKart",namespace)
        local transport = assert(loadfile("addon/AzerothKart/TransportProbe.lua"))("AzerothKart",namespace)
        assert(namespace.TransportProbe == transport and namespace.NetworkProbe == probe)
        assert(env.registerCalls == 0 and #env.sends == 0 and env.createdFrames == 0,
            "loading modules must not create UI, register a prefix or send")
        transport.Init(env.frame,output)
        assert(env.eventCalls == 0 and env.scriptCalls == 0 and #env.output == 0,
            "initialization must remain idle until an explicit experiment command")
        test(env,transport,probe,namespace)
        assert(env.frame.scripts.OnEvent == onEvent and env.createdFrames == 0)
    end)
    for _,item in ipairs(previous) do _G[item.name] = item.value end
    if not ok then error(err,0) end
end

local function stopped(env,transport)
    assert(transport.state and transport.state.phase == "stopped")
    assert(not transport.IsActive() and env.frame.akNetworkOwner==nil,"probe releases its own frame lease")
    assert(env.frame.scripts.OnUpdate == nil and env.frame.events.CHAT_MSG_ADDON_LOGGED == nil,
        "all terminal paths release the update callback and receive event")
end

withMock(function(env,t)
    local otherOwner,otherUpdate={},function() end
    env.frame.akNetworkOwner=otherOwner
    env.frame.scripts.OnUpdate=otherUpdate
    env.frame.events.CHAT_MSG_ADDON_LOGGED=true
    local scripts,events,unregisters=env.scriptCalls,env.eventCalls,env.unregisterCalls
    t.Stop("inactive probe")
    assert(not t.IsActive() and not t.Command("listen Amber Stone ABC123"))
    assert(env.frame.akNetworkOwner==otherOwner and env.frame.scripts.OnUpdate==otherUpdate
        and env.frame.events.CHAT_MSG_ADDON_LOGGED and env.scriptCalls==scripts
        and env.eventCalls==events and env.unregisterCalls==unregisters
        and env.registerCalls==0,"inactive probe never acquires or tears down another adapter's lease")
end)
local function quiet(env,count)
    assert(#env.output == count, "packets must not emit automatic per-packet chat output")
end

for _,hook in ipairs({"prefix","event","update"}) do
    withMock(function(env,t)
        local function revoke()
            t.Stop("cancelled while arming")
            assert(not t.Command("listen Birch Vale DEF456"),"nested arm cannot replace an in-progress arm")
        end
        if hook=="prefix" then
            local register=C_ChatInfo.RegisterAddonMessagePrefix
            C_ChatInfo.RegisterAddonMessagePrefix=function(prefix)
                local result=register(prefix); revoke(); return result
            end
        elseif hook=="event" then
            local register=env.frame.RegisterEvent
            env.frame.RegisterEvent=function(self,event)
                local result=register(self,event); revoke(); return result
            end
        else
            local set=env.frame.SetScript
            env.frame.SetScript=function(self,name,callback)
                local result=set(self,name,callback)
                if callback then revoke() end
                return result
            end
        end
        assert(not t.Command("listen Birch Vale ABC123"),"revoked "..hook.." hook refuses probe startup")
        assert(not t.IsActive() and not t.state and t.usedCount==0 and env.frame.akNetworkOwner==nil
            and env.frame.scripts.OnUpdate==nil and not env.frame.events.CHAT_MSG_ADDON_LOGGED,
            "reentrant cancellation cannot leave a lease-less active probe")
    end)
end

withMock(function(env,t,p)
    assert(t.Command("start Tester-Realm ABC123"))
    local o = t.state.options
    assert(o.mode == "send" and o.peer == "Tester-Realm" and o.session == "ABC123")
    assert(o.rate == 0.5 and o.bytes == 16 and o.duration == 120)
    assert(env.registerCalls == 1 and env.frame.events.CHAT_MSG_ADDON_LOGGED)
    assert(env.frame.scripts.OnUpdate == t.Update and #env.sends == 0 and t.usedCount == 1)
    local count = #env.output
    env.now=1.999; t.Update(); assert(#env.sends == 0)
    env.now=2; t.Update(); assert(#env.sends == 1 and #env.sends[1].payload == 16)
    assert(assert(p.decode(env.sends[1].payload)).sequence == 1)
    env.now=6; t.Update(); t.Update()
    assert(#env.sends == 2 and assert(p.decode(env.sends[2].payload)).sequence == 3,
        "a delayed callback sends only the current slot, with no catch-up burst")
    assert(p.summary(t.state).missed_slots == 1)
    assert(p.summary(t.state).ack_matched_unique == 0,
        "a Success enum records local acceptance, never invented delivery")
    quiet(env,count)
    t.Command("stop"); stopped(env,t)
    local afterStop=#env.output
    env.now=7; t.Update(); t.Stop("again")
    assert(#env.sends == 2); quiet(env,afterStop)
end)

-- Real failure shape: the surname must not be consumed as the session, and
-- the session must not become a numeric rate. No invented realm is required.
for _,case in ipairs({
    {command="listen Amber Stone AKT722",peer="Amber Stone",session="AKT722"},
    {command='listen "Amber Stone" AKT722',peer="Amber Stone",session="AKT722"},
    {command='start "  Amber   Stone " 123456',peer="Amber Stone",session="123456"},
    {command="start Amber Stone 123456 1",peer="Amber Stone",session="123456",rate=1},
    {command="start Amber Stone AKT722 2 64",peer="Amber Stone",session="AKT722",rate=2,bytes=64},
    {command='start "Amber Rune-Smith" AKT722 4 128 10',peer="Amber Rune-Smith",session="AKT722",rate=4,bytes=128,duration=10},
    {command="listen Amber Rune-Smith AKT722 0.5 220 120",peer="Amber Rune-Smith",session="AKT722",bytes=220},
    {command="listen Tester ABC123",peer="Tester",session="ABC123"},
}) do
    withMock(function(env,t,p)
        env.expectedPeer=case.peer
        assert(t.Command(case.command))
        local o=t.state.options
        assert(o.peer==case.peer and o.session==case.session)
        assert(o.rate==(case.rate or 0.5) and o.bytes==(case.bytes or 16) and o.duration==(case.duration or 120))
        assert(env.output[1]:find("WHISPER_LOGGED",1,true),"arming identifies the transport route")
        if o.mode=="listen" then
            t.Message(p.PREFIX,assert(p.encode("D",o.session,1,o.bytes)),"WHISPER",case.peer)
        else env.now=1/o.rate; t.Update() end
        assert(#env.sends==1 and env.sends[1].target==case.peer,"native API receives the complete canonical target")
        t.Stop(); stopped(env,t)
        local before=#env.output; t.Report()
        assert(env.output[before+1]:find("route=WHISPER_LOGGED",1,true))
    end)
end

withMock(function(env,t,p)
    assert(t.Command("help") and #env.output==6,"explicit help prints the short connection-test steps")
    assert(not t.state and t.usedCount==0 and env.registerCalls==0 and #env.sends==0 and
           env.eventCalls==0 and env.scriptCalls==0,"help never arms, registers or sends")
    local guide=table.concat(env.output,"\n")
    assert(guide:find('listen "Your Firstname Surname"',1,true) and
           guide:find('start "Friend Firstname Surname"',1,true) and
           guide:find("20 seconds",1,true) and guide:find("2 minutes 15 seconds",1,true) and guide:find("BOTH say Stopped",1,true) and
           guide:find("net evidence",1,true) and guide:find("net stop",1,true),
        "help explains both roles, ordering, waiting, output and cancellation")
    for _,line in ipairs(env.output) do assert(#line<=256,"help remains bounded") end
    assert(t.Command("start Tester-Realm ABC123"))
    local state,used,events,scripts=t.state,t.usedCount,env.eventCalls,env.scriptCalls
    local before=p.summary(state)
    assert(t.Command("help"))
    assert(t.state==state and t.usedCount==used and env.registerCalls==1 and #env.sends==0 and
           env.eventCalls==events and env.scriptCalls==scripts and
           p.summary(state).data_attempts==before.data_attempts,
        "reading help cannot reset or interrupt an existing experiment")
    t.Stop()
end)

for _,argument in ipairs({"", "start", "start Tester-Realm",
    "start Tester-Realm abc123", "start Tester-Realm ABC123 8",
    "start Tester-Realm ABC123 1 255", "start Tester-Realm ABC123 1 16 9",
    "start Tester-Realm ABC123 1 16 121", "start Tester-Realm ABC123 1 16 10.5",
    "start Tester-Realm ABC123 nope", "start Tester-Realm ABC123 1 16 10 extra",
    'listen "Amber Stone AKT722', 'listen Amber "Stone" AKT722',
    'listen "Amber Stone" AKT722 extra', 'listen "" AKT722',
    'listen "Amber Stone" AKT722 1 16 10 extra',
    'listen Amber ABCDEF AKT722', -- ambiguous: quote the name rather than guess.
    'listen Amber Stone AKT722 123456',
    'listen Amber|Stone AKT722', 'listen Amber\tStone AKT722',
    'listen "'..string.rep("x",97)..'" AKT722',
    string.rep("x",257)}) do
    withMock(function(env,t)
        assert(not t.Command(argument), "invalid command must be refused")
        assert(not t.state and t.usedCount == 0 and env.registerCalls == 0 and #env.sends == 0)
    end)
end
withMock(function(env,t)
    assert(not t.Command(nil) and not t.Command({}))
    t.Command("report"); t.Command("evidence"); t.Command("stop")
    assert(env.registerCalls == 0 and #env.sends == 0 and not t.state)
end)

local unavailable = {
    function() _G.C_ChatInfo=nil end,
    function() C_ChatInfo.RegisterAddonMessagePrefix=nil end,
    function() C_ChatInfo.SendAddonMessageLogged=nil end,
    function() _G.Enum=nil end,
    function() Enum.RegisterAddonMessagePrefixResult=nil end,
    function() Enum.SendAddonMessageResult=nil end,
    function() Enum.SendAddonMessageResult.TargetOffline=nil end,
    function() Enum.SendAddonMessageResult.ChannelThrottle=0 end,
    function() Enum.RegisterAddonMessagePrefixResult.Success=true end,
    function() _G.GetTime=nil end,
    function() _G.InCombatLockdown=nil end,
    function(env) env.clockThrows=true end,
    function(env) env.combatThrows=true end,
    function(env) env.combat=true end,
    function(env) env.combat=nil end,
    function(env) env.chatLocked=true end,
    function(env) env.chatThrows=true end,
    function(env,_,namespace) namespace.UI.active=true end,
}
for _,refuse in ipairs(unavailable) do
    withMock(function(env,t,_,namespace)
        refuse(env,t,namespace)
        assert(not t.Command("start Tester-Realm ABC123"))
        assert(not t.state and #env.sends == 0 and t.usedCount == 0)
        assert(env.frame.scripts.OnUpdate == nil and not env.frame.events.CHAT_MSG_ADDON_LOGGED)
    end)
end
withMock(function(env,t)
    -- IOU's tested route does not depend on the unlogged function or the
    -- broad outgoing-restriction diagnostic. Actual chat lockdown still wins.
    C_ChatInfo.SendAddonMessage=nil
    C_ChatInfo.AreOutgoingAddonChatMessagesRestricted=function() return true end
    assert(t.Command("start Tester-Realm ABC123"))
    env.now=2; t.Update(); assert(#env.sends==1)
    env.chatLocked=true; env.now=3; t.Update(); stopped(env,t)
    env.chatLocked=false; env.now=4; t.Update(); assert(#env.sends==1)
end)
for _,kind in ipairs({"false", "nil", "throws"}) do
    withMock(function(env,t)
        if kind == "throws" then env.registerThrows=true
        elseif kind == "false" then env.registerResult=false
        else env.registerResult=nil end
        assert(not t.Command("start Tester-Realm ABC123"))
        assert(env.registerCalls == 1 and #env.sends == 0 and not t.state and t.usedCount == 0)
    end)
end
withMock(function(env,t)
    env.registerResult=1 -- DuplicatePrefix is a valid registration enum, not send success.
    assert(t.Command("listen Tester-Realm ABC123 2 128 20"))
    assert(t.state.options.mode == "listen" and t.state.options.rate == 2)
    assert(t.state.options.bytes == 128 and t.state.options.duration == 20 and #env.sends == 0)
    t.Stop(); stopped(env,t)
end)
for _,kind in ipairs({"eventFalse", "eventError", "updateError"}) do
    withMock(function(env,t)
        env.eventThrows=kind == "eventError"
        env.updateThrows=kind == "updateError"
        if kind == "eventFalse" then env.eventResult=false end
        assert(not t.Command("start Tester-Realm ABC123"))
        assert(#env.sends == 0 and not t.state and t.usedCount == 0)
        assert(env.frame.scripts.OnUpdate == nil and not env.frame.events.CHAT_MSG_ADDON_LOGGED)
    end)
end

for _,raw in ipairs({3,8}) do
    withMock(function(env,t,p)
        env.sendResult=raw
        assert(t.Command("start Tester-Realm ABC123 1 64 10"))
        env.now=1; t.Update(); stopped(env,t)
        local summary=p.summary(t.state)
        assert(summary.throttle_events == 1 and summary.data_enqueue_failed == 1)
        env.now=2; t.Update(); assert(#env.sends == 1, "throttle must abort without retry")
    end)
end
for _,kind in ipairs({"true", "false", "nil", "unknown", "failure", "throws"}) do
    withMock(function(env,t,p)
        if kind == "true" then env.sendResult=true
        elseif kind == "false" then env.sendResult=false
        elseif kind == "nil" then env.sendResult=nil
        elseif kind == "unknown" then env.sendResult=99
        elseif kind == "failure" then env.sendResult=12
        else env.sendThrows=true end
        assert(t.Command("start Tester-Realm ABC123 1 16 10"))
        env.now=1; t.Update(); stopped(env,t)
        local summary=p.summary(t.state)
        if kind == "failure" or kind == "throws" then assert(summary.data_enqueue_failed == 1)
        else assert(summary.data_enqueue_unknown == 1) end
        env.now=2; t.Update(); assert(#env.sends == 1)
        t.Report(); t.Evidence()
        for _,line in ipairs(env.output) do assert(not line:find("private mock API error",1,true)) end
    end)
end

withMock(function(env,t,p)
    assert(t.Command("listen Tester-Realm ABC123"))
    local data=assert(p.encode("D","ABC123",1,16))
    local count=#env.output
    t.Message("OTHER",data,"WHISPER","Tester-Realm")
    assert(p.summary(t.state).rx_total == 0)
    t.Message(p.PREFIX,data,"WHISPER","Imposter-Realm")
    t.Message(p.PREFIX,data,"PARTY","Tester-Realm")
    t.Message(p.PREFIX,assert(p.encode("D","OLD123",1,16)),"WHISPER","Tester-Realm")
    t.Message(p.PREFIX,"malformed","WHISPER","Tester-Realm")
    assert(#env.sends == 0)
    t.Message(p.PREFIX,data,"WHISPER","tEsTeR-rEaLm")
    assert(#env.sends == 1)
    local ack=assert(p.decode(env.sends[1].payload))
    assert(ack.kind == "A" and ack.session == "ABC123" and ack.sequence == 1)
    env.now=0.1; t.Message(p.PREFIX,data,"WHISPER","Tester-Realm")
    assert(#env.sends == 1 and p.summary(t.state).duplicates == 1,
        "duplicate DATA must not generate another ACK")
    local summary=p.summary(t.state)
    assert(summary.rx_unique == 1 and summary.rx_rejected == 4 and summary.ack_enqueue_accepted == 1)
    quiet(env,count)
    t.Stop(); stopped(env,t)
end)
withMock(function(env,t,p)
    assert(t.Command("start Tester-Realm ABC123 1 16 10"))
    env.now=1; t.Update()
    env.now=1.1; t.Message(p.PREFIX,assert(p.encode("A","ABC123",1,16)),"WHISPER","Tester-Realm")
    assert(#env.sends == 1 and p.summary(t.state).ack_matched_unique == 1,
        "ACK receive is recorded without acknowledging an ACK")
    t.Stop()
end)

local interrupts = {
    function(_,t) t.Command("stop") end,
    function(_,t) t.HandleEvent("PLAYER_REGEN_DISABLED") end,
    function(_,t) t.HandleEvent("PLAYER_LEAVING_WORLD") end,
    function(_,t) t.HandleEvent("PLAYER_LOGOUT") end,
    function(env,t) env.combat=true; t.Update() end,
    function(_,t,namespace) namespace.UI.active=true; t.Update() end,
    function(env,t) env.clockThrows=true; t.Update() end,
    function(env,t) env.now=nil; t.Update() end,
    function(env,t) env.now=0/0; t.Update() end,
    function(env,t) env.now=math.huge; t.Update() end,
    function(env,t) env.now=-1; t.Update() end,
    function(env,t) env.now=0.5; t.Update() end, -- valid number, backwards from last send.
}
for _,interrupt in ipairs(interrupts) do
    withMock(function(env,t,p,namespace)
        assert(t.Command("start Tester-Realm ABC123 1 16 10"))
        env.now=1; t.Update(); assert(#env.sends == 1)
        interrupt(env,t,namespace); stopped(env,t)
        local count=#env.output
        env.combat=false; env.clockThrows=false; env.now=2; namespace.UI.active=false
        t.HandleEvent("PLAYER_REGEN_ENABLED"); t.Update()
        t.Message(p.PREFIX,assert(p.encode("A","ABC123",1,16)),"WHISPER","Tester-Realm")
        assert(#env.sends == 1 and p.summary(t.state).ack_matched_unique == 0)
        stopped(env,t); quiet(env,count)
    end)
end

withMock(function(env,t,p)
    assert(t.Command("start Tester-Realm ABC123 4 220 120"))
    env.now=0.25; t.Update(); t.Stop()
    assert(t.usedCount == 1 and p.summary(t.state).data_attempts == 1)
    assert(not t.Command("start Tester-Realm ABC123 4 220 120"),
        "a used session cannot be silently reused after interruption")
    assert(t.Command("listen Tester-Realm DEF456 4 220 120"))
    assert(t.usedCount == 2 and env.registerCalls == 1,
        "a fresh explicit session resets metrics without registering the prefix again")
    assert(p.summary(t.state).data_attempts == 0 and p.summary(t.state).rx_unique == 0)
    local before=#env.output
    t.Report()
    assert(#env.output-before <= 8, "summary output has a bounded number of lines")
    before=#env.output; t.Evidence()
    assert(#env.output-before == 13, "480 sequences use three fixed-size chunks for each of four bitmaps")
    assert(env.output[before+1]:find("sent session=",1,true)
        and env.output[before+4]:find("received session=",1,true)
        and env.output[before+7]:find("acks_sent session=",1,true)
        and env.output[before+10]:find("acks_received session=",1,true),
        "evidence distinguishes both DATA and ACK paths")
    for index=before+1,#env.output do assert(#env.output[index] <= 256) end
    assert(#env.sends == 1, "report and evidence commands never send packets")
    t.Stop()
end)
withMock(function(env,t)
    for index=1,64 do
        assert(t.Command("listen Tester-Realm "..("ID%04d"):format(index)))
        t.Stop()
    end
    assert(t.usedCount == 64 and env.registerCalls == 1 and #env.sends == 0)
    assert(not t.Command("listen Tester-Realm NEW123"), "session-ID history must remain bounded")
    assert(t.usedCount == 64 and not env.frame.events.CHAT_MSG_ADDON_LOGGED and not env.frame.scripts.OnUpdate)
end)

originalPrint("Opt-in transport adapter: guarded capabilities/enums, bounded traffic/evidence and terminal cleanup verified with mocks")
