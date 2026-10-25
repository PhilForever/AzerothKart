-- Bounded route diagnostics using API doubles, not evidence of Forever delivery.
local originalPrint = print
local PREFIX, CHANNEL = "AZKSCP1", "AzerothKartScoresProbe"
local globals = {"C_ChatInfo", "Enum", "GetTime", "GetServerTime", "NameUtil",
    "InCombatLockdown", "JoinPermanentChannel", "GetChannelName", "LeaveChannelByName",
    "issecretvalue", "CreateFrame", "DEFAULT_CHAT_FRAME", "print"}

local function fixture(test)
    local saved = {}
    for _, name in ipairs(globals) do saved[#saved+1] = {name, _G[name]} end
    local e = {now=0, epoch=1792756800, identity="Lene Conradi", channelId=0,
        sends={}, joins=0, leaves=0, registrations=0, eventCalls=0, updateInstalls=0, output={}, events={},
        registerResult=0, sendResult=0, combat=false, chatLocked=false}
    local originalEvent = function() end
    e.frame = {scripts={OnEvent=originalEvent}}
    function e.frame:RegisterEvent(event)
        assert(event=="CHAT_MSG_ADDON_LOGGED", "only the logged receive event is needed")
        e.eventCalls=e.eventCalls+1
        if e.eventThrows then error("mock event refusal") end
        e.events[event]=true
    end
    function e.frame:UnregisterEvent(event) e.events[event]=nil end
    function e.frame:SetScript(name, fn)
        assert(name=="OnUpdate", "Core keeps its OnEvent handler")
        if fn then e.updateInstalls=e.updateInstalls+1 end
        if fn and e.updateThrows then error("mock update refusal") end
        self.scripts[name]=fn
    end
    local function output(message) e.output[#e.output+1]=message end
    _G.print, _G.DEFAULT_CHAT_FRAME = output, {AddMessage=function(_,message) output(message) end}
    _G.CreateFrame = function() error("probe must reuse Core's existing frame") end
    _G.issecretvalue = function(value) return value==e.secret and e.secret~=nil end
    _G.GetTime = function()
        if e.clockThrows then error("mock clock refusal") end
        return e.now
    end
    _G.GetServerTime = function() return e.epoch end
    _G.NameUtil = {GetUnmodifiedUnitFullName=function(unit)
        assert(unit=="player"); return e.identity
    end}
    _G.InCombatLockdown = function()
        if e.combatThrows then error("mock combat refusal") end
        return e.combat
    end
    _G.Enum = {RegisterAddonMessagePrefixResult={Success=0,DuplicatePrefix=1},
        SendAddonMessageResult={Success=0, InvalidPrefix=1, InvalidMessage=2,
            AddonMessageThrottle=3, InvalidChatType=4, NotInGroup=5, TargetRequired=6,
            InvalidChannel=7, ChannelThrottle=8, GeneralError=9,
            NotInGuild=10, AddOnMessageLockdown=11, TargetOffline=12}}
    _G.C_ChatInfo = {
        RegisterAddonMessagePrefix=function(prefix)
            assert(prefix==PREFIX); e.registrations=e.registrations+1
            if e.registerThrows then error("mock registration refusal") end
            if e.onRegister then e.onRegister() end
            return e.registerResult
        end,
        SendAddonMessageLogged=function(prefix,payload,route,target)
            assert(prefix==PREFIX and route=="CHANNEL" and target==7,
                "only the dedicated numeric channel route is allowed")
            assert(type(payload)=="string" and #payload<=128)
            e.sends[#e.sends+1]={payload=payload, time=e.now, target=target}
            if e.sendThrows then error("mock native send refusal") end
            if e.onSend then e.onSend() end
            return e.sendResult
        end,
        SendAddonMessage=function() error("no unlogged route fallback") end,
        InChatMessagingLockdown=function()
            if e.chatThrows then error("mock chat lockdown refusal") end
            return e.chatLocked
        end,
    }
    _G.GetChannelName = function(name)
        assert(name==CHANNEL or name==7)
        if e.channelThrows then error("mock channel lookup refusal") end
        return e.channelId, e.channelId==7 and CHANNEL or nil
    end
    _G.JoinPermanentChannel = function(name)
        assert(name==CHANNEL); e.joins=e.joins+1
        if e.joinThrows then error("mock channel join refusal") end
        if not e.deferJoin then e.channelId=7 end
        if e.onJoin then e.onJoin() end
        return e.channelId
    end
    _G.LeaveChannelByName = function(name)
        assert(name==CHANNEL); e.leaves=e.leaves+1; e.channelId=0
    end
    local ok, err = pcall(function()
        local ns={UI={active=false}}
        local p=assert(loadfile("addon/AzerothKart/ScoreChannelProbe.lua"))("AzerothKart",ns)
        p=p or ns.ScoreChannelProbe
        assert(p and ns.ScoreChannelProbe==p)
        assert(e.registrations==0 and e.joins==0 and #e.sends==0,
            "module load must not register, join, or send")
        p.Init(e.frame,output)
        assert(e.registrations==0 and e.joins==0 and #e.sends==0
            and not next(e.events) and not e.frame.scripts.OnUpdate,
            "Init must stay idle until the explicit check action")
        assert(p.GetView().phase=="idle")
        test(e,p,ns)
        assert(e.frame.scripts.OnEvent==originalEvent)
    end)
    for _, item in ipairs(saved) do _G[item[1]]=item[2] end
    assert(ok,err)
end

local function advance(e,p,now) e.now=now; p.Update() end
local function stopped(e,p)
    assert(p.GetView().phase=="stopped")
    assert(e.frame.akNetworkOwner==nil and e.frame.scripts.OnUpdate==nil
        and not next(e.events), "terminal cleanup must release this probe's lease")
end
local function message(p,payload,sender,id,route,prefix)
    p.Message(prefix or PREFIX,payload,route or "CHANNEL",sender or "Amber Stone",
        "7. "..CHANNEL,0,id or 7,CHANNEL,0)
end
local function start(e,p)
    assert(p.Start(), "explicit check should arm with supported native capabilities")
    p.Update()
    local view=p.GetView()
    assert(view.phase=="checking" and view.channelId==7)
    assert(type(view.token)=="string" and #view.token<=40 and view.token:match("^[%d%-]+$"))
    return view.token
end
local function spaced(e)
    assert(#e.sends<=6, "entire check has a fixed six-send ceiling")
    for i=2,#e.sends do
        assert(e.sends[i].time-e.sends[i-1].time>=2, "no catchup or receive-triggered send burst")
    end
end

fixture(function(e,p)
    local token=start(e,p)
    assert(e.joins==1 and #e.sends==1 and e.sends[1].payload=="1|H|"..token)
    assert(p.GetView().sent==1 and p.GetView().accepted==1
        and p.GetView().selfEchoes==0 and p.GetView().peerAcks==0,
        "native acceptance alone is never delivery evidence")
    message(p,"1|H|"..token,e.identity)
    local view=p.GetView()
    assert(view.selfEchoes==1 and view.peerHellos==0 and view.peerAcks==0,
        "local echo does not count as another client")
    view.accepted=999; view.phase="broken"
    assert(p.GetView().accepted==1 and p.GetView().phase=="checking", "diagnostic view is detached")
    local outputCount=#e.output
    advance(e,p,5.99); assert(#e.sends==1)
    advance(e,p,6); advance(e,p,12); advance(e,p,29.99)
    assert(#e.sends==3 and #e.output==outputCount, "checks do not emit per-packet chat")
    advance(e,p,30); stopped(e,p)
    assert(e.leaves==1 and p.GetView().sent==3 and p.GetView().accepted==3)
    advance(e,p,100); p.Stop("again"); assert(#e.sends==3 and e.leaves==1)
    spaced(e)
end)

fixture(function(e,p)
    e.channelId=7
    start(e,p); p.Stop("manual")
    stopped(e,p)
    assert(e.joins==0 and e.leaves==0 and e.channelId==7,
        "preexisting channel membership belongs to the user")
end)

fixture(function(e,p)
    local owner, callback={},function() end
    e.frame.akNetworkOwner=owner; e.frame.scripts.OnUpdate=callback
    e.events.CHAT_MSG_ADDON_LOGGED=true
    assert(not p.Start()); p.Stop("inactive")
    assert(e.frame.akNetworkOwner==owner and e.frame.scripts.OnUpdate==callback
        and e.events.CHAT_MSG_ADDON_LOGGED and e.registrations==0 and e.joins==0,
        "an idle probe must never mutate another transport's lease")
end)

fixture(function(e,p)
    e.deferJoin=true
    assert(p.Start()); assert(p.GetView().phase=="joining" and #e.sends==0)
    advance(e,p,7.99); assert(#e.sends==0)
    advance(e,p,8.01); stopped(e,p)
    assert(e.leaves==1 and #e.sends==0, "failed joins are bounded and cleaned up")
end)

fixture(function(e,p)
    e.deferJoin=true
    assert(p.Start()); e.now=3; e.channelId=7; p.Update()
    assert(#e.sends==1)
    advance(e,p,27); p.Update()
    assert(#e.sends<=2, "a long frame does not replay multiple missed HELLOs")
    advance(e,p,30); stopped(e,p); spaced(e)
end)

fixture(function(e,p)
    local token=start(e,p)
    for i=1,20 do
        message(p,"1|H|1792756800-20-"..i,"Peer "..i)
        message(p,"1|H|1792756800-20-"..i,"Peer "..i)
    end
    assert(#e.sends==1, "receiving a HELLO only queues a bounded reply")
    for i=1,29 do advance(e,p,i) end
    local acknowledgments=0
    for _,send in ipairs(e.sends) do
        if send.payload:sub(1,4)=="1|A|" then acknowledgments=acknowledgments+1 end
    end
    assert(acknowledgments==3, "only three distinct peer HELLOs may earn replies")
    spaced(e)
    message(p,"1|A|"..token.."|1792756800-20-1","Peer 1")
    message(p,"1|A|"..token.."|1792756800-20-1","Peer 1")
    assert(p.GetView().peerAcks==1, "duplicate valid ACKs are counted once")
    p.Stop("manual")
    local previous=token
    token=start(e,p)
    assert(token~=previous, "explicit repeat checks need a fresh token")
    message(p,"1|A|"..previous.."|1792756800-20-1","Peer 1")
    assert(p.GetView().peerAcks==0, "old check acknowledgments cannot prove this check")
    p.Stop("done")
end)

fixture(function(e,p)
    local token=start(e,p)
    local hello="1|H|1792756800-20-1"
    message(p,hello,"Amber Stone",8)
    message(p,hello,"Amber Stone",7,"WHISPER")
    message(p,hello,"Amber Stone",7,"CHANNEL","OTHER")
    message(p,"2|H|1792756800-20-1")
    message(p,"1|H|not-a-token")
    message(p,"1|H|"..string.rep("1",41))
    message(p,"1|H|1792756800-20-1|extra")
    message(p,hello,"Amber\nStone")
    message(p,"1|A|"..token.."|1792756800-20-1",e.identity)
    assert(p.GetView().peerHellos==0 and p.GetView().peerAcks==0 and #e.sends==1,
        "wrong route, namespace, channel, syntax, identity and self ACKs are ignored")
    message(p,hello)
    message(p,"1|A|"..token.."|1792756800-20-1")
    assert(p.GetView().peerHellos==1 and p.GetView().peerAcks==1)
    p.Stop("done")
end)

for _,kind in ipairs({"nil","false","unknown","throttle","throws"}) do
    fixture(function(e,p)
        if kind=="nil" then e.sendResult=nil
        elseif kind=="false" then e.sendResult=false
        elseif kind=="unknown" then e.sendResult=999
        elseif kind=="throttle" then e.sendResult=8
        else e.sendThrows=true end
        assert(p.Start()); p.Update(); stopped(e,p)
        assert(#e.sends==1 and p.GetView().accepted==0 and e.leaves==1)
        advance(e,p,20); assert(#e.sends==1, "send refusal never triggers retries or fallback")
    end)
end

for _,kind in ipairs({"combat","chatLocked","identity","epoch","missingJoin","registration","event","update"}) do
    fixture(function(e,p)
        if kind=="combat" then e.combat=true
        elseif kind=="chatLocked" then e.chatLocked=true
        elseif kind=="identity" then e.identity=nil
        elseif kind=="epoch" then e.epoch=0/0
        elseif kind=="missingJoin" then _G.JoinPermanentChannel=nil
        elseif kind=="registration" then e.registerResult=false
        elseif kind=="event" then e.eventThrows=true
        else e.updateThrows=true end
        assert(not p.Start(), "invalid native capability must refuse startup: "..kind)
        assert(#e.sends==0 and e.frame.akNetworkOwner==nil and not e.frame.scripts.OnUpdate
            and not next(e.events), "refused startup must leave no active lease")
    end)
end

for _,kind in ipairs({"register_success","register_duplicate","send_success"}) do
    fixture(function(e,p)
        if kind=="register_success" then
            Enum.RegisterAddonMessagePrefixResult.Success=0.5; e.registerResult=0.5
        elseif kind=="register_duplicate" then
            Enum.RegisterAddonMessagePrefixResult.DuplicatePrefix=1.5; e.registerResult=1.5
        else
            Enum.SendAddonMessageResult.Success=0.5; e.sendResult=0.5
        end
        assert(not p.Start(), "fractional capability enum must be rejected: "..kind)
        assert(e.registrations==0 and e.joins==0 and #e.sends==0
            and e.frame.akNetworkOwner==nil and not e.frame.scripts.OnUpdate and not next(e.events),
            "contradictory capability enums must fail before any native mutation")
    end)
end

for _,kind in ipairs({"register","join"}) do
    fixture(function(e,p)
        local nestedResult, callbacks=nil,0
        local function cancel()
            callbacks=callbacks+1
            e.onRegister,e.onJoin=nil,nil
            p.Stop("cancelled during "..kind)
            nestedResult=p.Start()
        end
        if kind=="register" then e.onRegister=cancel else e.onJoin=cancel end
        assert(not p.Start(), "synchronous cancellation must refuse the outer startup")
        stopped(e,p)
        assert(callbacks==1 and nestedResult==false and e.registrations==1,
            "a cancelled native startup cannot be replaced while the old startup is unwinding")
        assert(e.updateInstalls==0 and #e.sends==0,
            "cancelled startup must not install a later update or send")
        if kind=="register" then
            assert(e.eventCalls==0 and e.joins==0 and e.leaves==0,
                "prefix cancellation must not continue into receive registration or channel joining")
        else
            assert(e.eventCalls==1 and e.joins==1 and e.leaves==1 and e.channelId==0,
                "channel cancellation cleans only its own attempted membership")
        end
        start(e,p)
        p.Stop("fresh explicit check")
        stopped(e,p)
    end)
end

fixture(function(e,p)
    local nestedResult, stoppedToken
    e.onSend=function()
        e.onSend=nil
        p.Stop("cancelled in native send")
        stoppedToken=p.GetView().token
        nestedResult=p.Start()
    end
    assert(p.Start()); p.Update()
    stopped(e,p)
    assert(nestedResult==false and #e.sends==1 and p.GetView().accepted==0
        and p.GetView().reason=="cancelled in native send" and e.frame.akNetworkSending==nil,
        "a cancelled send cannot count as accepted or restart before the native call unwinds")
    local token=start(e,p)
    assert(token~=stoppedToken and p.GetView().sent==1 and p.GetView().accepted==1,
        "a fresh explicit check is independent of the cancelled native send")
    message(p,"1|A|"..stoppedToken.."|1792756800-20-1")
    assert(p.GetView().peerAcks==0)
    p.Stop("done")
end)

for _,kind in ipairs({"PLAYER_REGEN_DISABLED","PLAYER_LEAVING_WORLD","PLAYER_LOGOUT","drive","clock","secret"}) do
    fixture(function(e,p,ns)
        start(e,p)
        if kind=="drive" then ns.UI.active=true; advance(e,p,1)
        elseif kind=="clock" then e.now=0/0; p.Update()
        elseif kind=="secret" then e.secret=e.now; p.Update()
        else p.HandleEvent(kind) end
        stopped(e,p)
        assert(#e.sends==1 and e.leaves==1, "lifecycle/unsafe native state ends finite check")
    end)
end

fixture(function(e,p)
    start(e,p)
    e.secret="1|H|1792756800-20-1"
    local ok=pcall(message,p,e.secret)
    assert(ok and p.GetView().peerHellos==0 and #e.sends==1,
        "secret-valued input is never parsed or answered")
    p.Stop("done")
end)

fixture(function(e,p,ns)
    ns.SessionTransport={DiagnosticTrafficQuiet=function(now) return now>=1 end}
    assert(not p.Start() and e.registrations==0 and #e.sends==0 and not e.frame.akNetworkOwner,
        "group-probe quiet handoff does not register, join or acquire a second diagnostic")
    e.now=1
    assert(p.Start())
    p.Stop("done")
end)

originalPrint("Score channel probe: finite opt-in traffic, native refusal, peer evidence and lifecycle cleanup verified with mocks")
