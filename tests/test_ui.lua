-- Lua-only regression doubles: this is NOT proof of Forever focus/combat safety.
-- The real client must still execute the F1/F2/F5 manual acceptance probes.
local originalPrint = print
local globalNames = {
    "CreateFrame", "UIParent", "InCombatLockdown", "MouseIsOver",
    "GetCurrentKeyBoardFocus", "IsGameWindowFocused", "GetBuildInfo",
    "GetFramerate", "GetTime", "debugprofilestop", "DEFAULT_CHAT_FRAME", "C_AddOns",
    "SlashCmdList", "SLASH_AZEROTHKART1", "SLASH_AZEROTHKART2",
    "AzerothKart", "AzerothKartDB", "print",
}

local function withMock(savedDB, initialCombat, test, unsupportedEvent)
    local previous = {}
    for _,name in ipairs(globalNames) do
        previous[#previous+1] = {name=name, value=_G[name]}
    end
    local env = {
        combat=initialCombat or false, focus=nil, focused=true, mouseInside=true,
        frames={}, output={}, counts={frames=0, textures=0, fontStrings=0},
        propagationCalls=0, combatPropagationCalls=0, keyboardReleaseCalls=0,
        profileTime=0,
    }
    local methods = {}
    local function object(kind)
        env.counts[kind] = env.counts[kind]+1
        return setmetatable({scripts={}, events={}, shown=true, enabled=true}, {
            __index=function(_,key)
                return methods[key] or function() end
            end,
        })
    end
    function methods:SetScript(name, callback) self.scripts[name]=callback end
    function methods:RegisterEvent(event)
        if event==unsupportedEvent then error("mock unsupported event") end
        self.events[event]=true
    end
    function methods:UnregisterEvent(event) self.events[event]=nil end
    function methods:IsShown() return self.shown end
    function methods:Show()
        if self.shown then return end
        self.shown=true
        if self.scripts.OnShow then self.scripts.OnShow(self) end
    end
    function methods:Hide()
        if not self.shown then return end
        self.shown=false
        if self.scripts.OnHide then self.scripts.OnHide(self) end
    end
    function methods:Enable() self.enabled=true end
    function methods:Disable() self.enabled=false end
    function methods:IsEnabled() return self.enabled end
    function methods:EnableKeyboard(enabled)
        self.keyboard=enabled
        if not enabled then
            env.keyboardReleaseCalls=env.keyboardReleaseCalls+1
        end
    end
    function methods:SetPropagateKeyboardInput(propagate)
        env.propagationCalls=env.propagationCalls+1
        if env.combat then
            env.combatPropagationCalls=env.combatPropagationCalls+1
        end
        self.propagate=propagate
    end
    function methods:SetText(text)
        self.text=text
        self.textWrites=(rawget(self,"textWrites") or 0)+1
    end
    function methods:GetText() return self.text end
    function methods:CreateTexture() return object("textures") end
    function methods:CreateFontString() return object("fontStrings") end

    _G.CreateFrame=function(_,name,parent)
        local frame=object("frames")
        frame.name, frame.parent=name,parent
        env.frames[#env.frames+1]=frame
        return frame
    end
    _G.UIParent={}
    _G.InCombatLockdown=function() return env.combat end
    _G.MouseIsOver=function() return env.mouseInside end
    _G.GetCurrentKeyBoardFocus=function() return env.focus end
    _G.IsGameWindowFocused=function() return env.focused end
    _G.GetBuildInfo=function() return "mock", "0", "test", 16001 end
    _G.GetFramerate=function() return 60 end
    _G.GetTime=function() return env.profileTime/1000 end
    _G.debugprofilestop=function()
        env.profileTime=env.profileTime+0.01
        return env.profileTime
    end
    _G.print=function(...)
        local words={}
        for n=1,select("#",...) do words[n]=tostring(select(n,...)) end
        env.output[#env.output+1]=table.concat(words," ")
    end
    _G.DEFAULT_CHAT_FRAME={AddMessage=function(_,text)
        env.output[#env.output+1]=tostring(text)
    end}
    _G.SlashCmdList={}
    _G.C_AddOns=nil
    _G.AzerothKart=nil
    _G.AzerothKartDB=savedDB

    function env.fire(event, arg1)
        for _,frame in ipairs(env.frames) do
            if frame.events[event] and frame.scripts.OnEvent then
                frame.scripts.OnEvent(frame,event,arg1)
            end
        end
    end
    function env.key(ui, script, key)
        assert(ui.window.scripts[script], "missing keyboard callback: "..script)
        ui.window.scripts[script](ui.window,key)
    end
    local ok, err=pcall(function()
        local namespace={}
        for _,name in ipairs({"Track", "Physics", "Input", "Loop", "UI", "Core"}) do
            assert(loadfile("addon/AzerothKart/"..name..".lua"))("AzerothKart",namespace)
        end
        env.namespace=namespace
        test(env,namespace.UI)
    end)
    for _,entry in ipairs(previous) do _G[entry.name]=entry.value end
    assert(ok,err)
end

local summary
withMock({schemaVersion=1, custom={keep=true}}, false, function(env,UI)
    local originalDB=AzerothKartDB
    env.fire("ADDON_LOADED","UnrelatedAddon")
    assert(not UI.window,"unrelated ADDON_LOADED must not create UI")
    assert(AzerothKartDB==originalDB,"unrelated load must not repair saves")
    assert(#env.frames==1,"bootstrap creates only its event frame")
    local bootstrapFrames=env.counts.frames
    env.fire("ADDON_LOADED","AzerothKart")
    assert(UI.window and not UI.window:IsShown(),"load creates hidden probe window")
    assert(AzerothKartDB==originalDB and AzerothKartDB.custom.keep,
        "valid unknown save fields must survive initialization")
    assert(not env.frames[1].events.ADDON_LOADED,"load event unregisters after own load")
    for _,event in ipairs({"PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
                          "GLOBAL_MOUSE_DOWN", "PLAYER_LEAVING_WORLD", "PLAYER_LOGOUT"}) do
        assert(env.frames[1].events[event],"missing lifecycle registration: "..event)
    end
    assert(UI.objects.frames==env.counts.frames-bootstrapFrames,"frame counter matches wrappers")
    assert(UI.objects.textures==env.counts.textures,"texture counter matches wrappers")
    assert(UI.objects.fontStrings==env.counts.fontStrings,"font counter matches wrappers")
    local counts={frames=env.counts.frames,textures=env.counts.textures,
                  fontStrings=env.counts.fontStrings}
    local function assertPooled()
        for kind,count in pairs(counts) do
            assert(env.counts[kind]==count,"UI object count grew: "..kind)
        end
    end
    local held=UI.keys
    local function assertReleased(reason)
        assert(not UI.active,reason..": drive stopped")
        assert(UI.window.keyboard==false,reason..": keyboard disabled")
        assert(UI.keys==held and next(held)==nil,reason..": held table cleared in place")
        assert(not UI.input.accelerate and not UI.input.brake and
               not UI.input.left and not UI.input.right,reason..": sampled input cleared")
    end
    local function start()
        env.focus=nil; env.focused=true; env.mouseInside=true; env.combat=false
        if not UI.window:IsShown() then UI.Toggle() end
        UI.Start()
        assert(UI.active and UI.window.keyboard,"deliberate Start captures keyboard")
        assert(UI.window.propagate==false,"active input does not propagate")
        assert(UI.state.tick==0 and UI.state.speed==0,"restart resets simulation")
        assert(UI.clock.frames==0 and UI.clock.steps==0,"restart resets clock")
        assert(next(held)==nil,"restart clears prior held keys")
    end
    UI.Start()
    assert(not UI.active,"hidden window cannot capture keyboard")
    UI.Toggle(); env.focus={}; UI.Start()
    assert(not UI.active,"text input focus prevents Start capture")
    env.focus=nil
    start()
    env.key(UI,"OnKeyDown","W")
    env.key(UI,"OnKeyDown","UP")
    env.key(UI,"OnKeyUp","W")
    UI.OnUpdate(1/60)
    assert(UI.input.accelerate and UI.state.speed>0,
        "releasing W must not clear separately held Up")
    env.key(UI,"OnKeyUp","UP")
    UI.OnUpdate(1/60)
    assert(not UI.input.accelerate,"releasing both aliases clears throttle")
    for _,key in ipairs({"ESCAPE","ENTER","F"}) do
        start(); env.key(UI,"OnKeyDown","W"); UI.OnUpdate(1/60)
        env.key(UI,"OnKeyDown",key)
        assertReleased("keyboard exit "..key)
    end
    start(); env.key(UI,"OnKeyDown","A"); UI.Stop("test")
    assertReleased("Stop")
    start(); UI.window:Hide(); assertReleased("OnHide")
    start(); UI.stopButton.scripts.OnClick(UI.stopButton); assertReleased("Stop button")
    local closeButton
    for _,frame in ipairs(env.frames) do
        if frame.text=="Close" then closeButton=frame end
    end
    assert(closeButton and closeButton.scripts.OnClick,"clickable Close control exists")
    start(); closeButton.scripts.OnClick(closeButton); assertReleased("Close button")
    assert(not UI.window:IsShown(),"Close hides window")
    start(); UI.Toggle(); assertReleased("toggle closed")
    start(); env.mouseInside=true; env.fire("GLOBAL_MOUSE_DOWN","LeftButton")
    assertReleased("click inside or overlapping other UI")
    start(); env.mouseInside=false; env.fire("GLOBAL_MOUSE_DOWN","LeftButton")
    assertReleased("click outside window")
    start(); env.focus={}; UI.OnUpdate(1/60); assertReleased("chat edit box focus")
    start(); env.focus={}; env.key(UI,"OnKeyDown","W")
    assertReleased("chat focus noticed by keyboard callback")
    start(); env.focused=false; UI.OnUpdate(1/60); assertReleased("application focus loss")
    env.focused=true; UI.OnUpdate(1/60)
    assert(not UI.active,"application focus regain must not resume")
    start(); _G.IsGameWindowFocused=nil; UI.OnUpdate(1/60)
    assert(UI.active,"optional focus API absence must not crash")
    _G.IsGameWindowFocused=function() return env.focused end
    UI.Stop("optional API probe")
    for _,event in ipairs({"PLAYER_LEAVING_WORLD","PLAYER_LOGOUT"}) do
        start(); env.key(UI,"OnKeyDown","W"); UI.OnUpdate(1/60)
        env.fire(event); assertReleased(event)
    end
    start(); env.key(UI,"OnKeyDown","W"); UI.OnUpdate(1/60)
    env.combat=true
    local releaseCalls=env.keyboardReleaseCalls
    local interruptionOutput=#env.output
    local interruptedTick=UI.state.tick
    env.fire("PLAYER_REGEN_DISABLED")
    assertReleased("combat event")
    assert(not UI.window:IsShown(),"combat closes the racing window")
    assert(UI.result.status=="interrupted" and UI.result.reason=="Game interrupted by combat",
        "combat keeps the explicit interruption result")
    assert(UI.result.tick==interruptedTick and UI.stopReason==UI.result.reason,
        "hiding preserves the terminal tick/reason")
    local result=UI.result
    env.fire("PLAYER_REGEN_DISABLED"); UI.OnUpdate(1); UI.InterruptCombat()
    assert(UI.result==result and UI.state.tick==interruptedTick,"interruption is terminal once")
    assert(#env.output==interruptionOutput+1,"combat interruption note emitted once")
    assert(env.keyboardReleaseCalls>releaseCalls,"combat explicitly disables keyboard")
    assert(UI.pendingPropagationRelease,"combat defers propagation setter")
    local setters=env.propagationCalls
    UI.Start(); UI.ReleaseInput(); UI.Create(); UI.OnUpdate(1/60)
    assert(env.propagationCalls==setters,"combat paths never invoke propagation setter")
    env.combat=false; env.fire("PLAYER_REGEN_ENABLED")
    assert(not UI.pendingPropagationRelease and UI.window.propagate,
        "combat end restores propagation")
    assert(not UI.active,"combat end must not resume")
    UI.Toggle()
    assert(UI.result==result and UI.status.text:find("Game interrupted by combat",1,true),
        "deliberate reopen retains interruption note until new Start")
    local interruptedClock, interruptedState = UI.clock, UI.state
    local clockValues, stateValues = {}, {}
    for key,value in pairs(interruptedClock) do clockValues[key]=value end
    for key,value in pairs(interruptedState) do stateValues[key]=value end
    local interruptedHud = UI.hud.text
    local function assertRetained(label)
        assertReleased(label)
        assert(UI.result==result and UI.result.tick==interruptedTick,
            label..": terminal result identity/tick retained")
        assert(UI.stopReason==result.reason and UI.status.text:find(result.reason,1,true),
            label..": interruption stays visible and authoritative")
        assert(UI.clock==interruptedClock and UI.state==interruptedState,
            label..": stopped clock/state retained")
        for key,value in pairs(clockValues) do
            assert(UI.clock[key]==value,label..": stopped clock changed "..key)
        end
        for key,value in pairs(stateValues) do
            assert(UI.state[key]==value,label..": stopped state changed "..key)
        end
        assert(UI.hud.text==interruptedHud,label..": stopped HUD retained")
        assert(#env.output==interruptionOutput+1,label..": no duplicate interruption output")
        assertPooled()
    end
    for attempt=1,2 do
        UI.Toggle()
        assert(not UI.window:IsShown(),"repeated toggle closes interrupted window")
        assertRetained("toggle close "..attempt)
        local hiddenStatus=UI.status.text
        UI.Start()
        assert(UI.status.text==hiddenStatus,"hidden Start leaves terminal status unchanged")
        assertRetained("hidden Start "..attempt)
        UI.Toggle()
        assertRetained("toggle reopen "..attempt)
    end
    closeButton.scripts.OnClick(closeButton)
    assert(not UI.window:IsShown(),"Close button hides interrupted window")
    assertRetained("Close button")
    UI.Toggle()
    assertRetained("Close button reopen")
    UI.Stop("Idle stop after interruption")
    assertRetained("inactive Stop")
    local function refusedStart(label, reason)
        UI.Start()
        assertRetained(label)
        assert(UI.status.text:find(reason,1,true),label..": actual Start refusal stays visible")
    end
    env.combat=true
    refusedStart("combat Start refusal","Cannot start while in combat")
    env.combat=false; env.fire("PLAYER_REGEN_ENABLED")
    env.focus={}
    refusedStart("text focus Start refusal","Close text input before starting")
    env.focus=nil
    env.namespace.events.GLOBAL_MOUSE_DOWN=false
    refusedStart("mouse event Start refusal","Input safety APIs unavailable")
    env.namespace.events.GLOBAL_MOUSE_DOWN=true
    local textFocusAPI=GetCurrentKeyBoardFocus
    _G.GetCurrentKeyBoardFocus=nil
    refusedStart("missing text focus Start refusal","Input safety APIs unavailable")
    _G.GetCurrentKeyBoardFocus=textFocusAPI
    for _,method in ipairs({"EnableKeyboard","SetPropagateKeyboardInput"}) do
        local prior=UI.window[method]
        UI.window[method]=false
        refusedStart("missing "..method.." Start refusal","Input safety APIs unavailable")
        UI.window[method]=prior
    end
    start()
    assert(UI.result==nil and UI.clock~=interruptedClock,
        "successful explicit Start clears interrupted result and replaces clock")
    assert(not UI.status.text:find(result.reason,1,true),
        "successful Start clears visible interruption note")
    UI.Stop("Ordinary stop")
    assert(UI.stopReason=="Ordinary stop" and UI.status.text:find("Ordinary stop",1,true),
        "later ordinary stop uses its own reason")
    assert(not UI.status.text:find(result.reason,1,true),
        "later ordinary stop does not resurrect interruption note")
    closeButton.scripts.OnClick(closeButton)
    assert(UI.stopReason=="Closed" and not UI.status.text:find(result.reason,1,true),
        "later ordinary Close uses its own reason without stale interruption note")
    start(); env.combat=true; UI.OnUpdate(1/60)
    assertReleased("OnUpdate combat fallback")
    assert(not UI.window:IsShown(),"combat OnUpdate fallback also closes the window")
    env.combat=false; env.fire("PLAYER_REGEN_ENABLED")
    for _,api in ipairs({"InCombatLockdown","GetCurrentKeyBoardFocus"}) do
        UI.Stop("capability probe")
        local prior=_G[api]
        _G[api]=nil
        UI.Start()
        assert(not UI.active,"missing safety API prevents capture: "..api)
        _G[api]=prior
        UI.OnCombatEnded()
    end
    env.namespace.events.GLOBAL_MOUSE_DOWN=false
    UI.Start()
    assert(not UI.active,"missing click-away event prevents capture")
    env.namespace.events.GLOBAL_MOUSE_DOWN=true
    for _,method in ipairs({"EnableKeyboard","SetPropagateKeyboardInput"}) do
        UI.Stop("keyboard capability probe")
        local prior=UI.window[method]
        UI.window[method]=false
        UI.Start()
        assert(not UI.active,"missing keyboard method prevents capture: "..method)
        UI.window[method]=prior
    end
    start()
    local outputBefore=#env.output
    for _=1,1000 do UI.OnUpdate(1/144) end
    assert(UI.clock.frames==1000 and UI.clock.steps>0,"measurable clock advances")
    UI.OnUpdate(1)
    assert(UI.clock.lastSteps<=UI.clock.maxSteps and UI.clock.droppedSeconds>0,
        "frame hitch is bounded and lost time measured")
    assert(#env.output==outputBefore,"OnUpdate must not print chat diagnostics")
    assertPooled()
    UI.Stop("pool probe")
    for _=1,5 do UI.Toggle(); UI.Toggle(); UI.Create() end
    assertPooled()
    UI.ReportProbe()
    assert(#env.output>outputBefore,"explicit probe reports measurable output")
    assert(env.combatPropagationCalls==0,"all mock combat paths avoid propagation setters")
    summary=("mock UI: frames=%d textures=%d fontStrings=%d; tickFrames=%d; combatPropagationCalls=%d")
        :format(UI.objects.frames,UI.objects.textures,UI.objects.fontStrings,
                1001,env.combatPropagationCalls)
end)

withMock(nil, false, function(env,UI)
    env.fire("ADDON_LOADED","AzerothKart")
    local function probe()
        local first=#env.output+1
        SlashCmdList.AZEROTHKART("probe")
        assert(#env.output==first+5,"explicit probe has six bounded report lines")
        return env.output[first+1],env.output[first+2]
    end
    local _,duration=probe()
    assert(duration:find("activeFrameSeconds=0.0000 simulatedSeconds=0.0000 callbackHz=0.00",1,true),
        "probe before Start has finite zero timing metrics")
    UI.Toggle(); UI.Start()
    assert(UI.hud.text=="Speed: 0 | Ticks: 0 | Dropped: 0.000s | Sample: 0.0s",
        "Start immediately displays a fresh sample")
    env.key(UI,"OnKeyDown","W")
    UI.OnUpdate(1/60+0.004)
    assert(UI.state.tick==1 and UI.hud.text:find("Ticks: 0",1,true),
        "active HUD updates stay throttled")
    UI.Stop("timing sample")
    assert(UI.hud.text:find("Ticks: 1",1,true) and UI.hud.text:find("Speed: 3",1,true),
        "Stop flushes final tick/speed even before the next HUD interval")
    local clock=UI.clock
    assert(math.abs(clock.accumulator-0.004)<1e-10,"Stop retains final fractional remainder")
    assert(math.abs(clock.elapsedSeconds-clock.steps*clock.dt-clock.droppedSeconds-clock.accumulator)<1e-10,
        "stopped timing sample accounts for all delivered frame time")
    local counters={}
    for key,value in pairs(clock) do counters[key]=value end
    local hud=UI.hud.text
    local frameLine,timeLine=probe()
    assert(timeLine:find("activeFrameSeconds=0.0207 simulatedSeconds=0.0167 callbackHz=48.39",1,true),
        "probe reports measured frame duration, executed simulation time and callback cadence")
    local output=#env.output
    for _=1,10 do UI.OnUpdate(1) end
    UI.Toggle(); UI.Toggle()
    for key,value in pairs(counters) do
        assert(clock[key]==value,"stopped/reopened sample changed "..key)
    end
    assert(UI.hud.text==hud and #env.output==output,"stopped samples retain their HUD text and do not print automatically")
    local repeatedFrame,repeatedTime=probe()
    assert(repeatedFrame==frameLine and repeatedTime==timeLine,"repeated stopped reports retain identical timing")
    UI.Start()
    assert(UI.clock~=clock and UI.clock.elapsedSeconds==0 and UI.clock.accumulator==0,
        "fresh Start replaces the frozen clock and its remainder")
    assert(UI.hud.text=="Speed: 0 | Ticks: 0 | Dropped: 0.000s | Sample: 0.0s",
        "fresh Start clears the old stopped HUD immediately")
    local writes=UI.hud.textWrites
    output=#env.output
    for _=1,144 do UI.OnUpdate(1/144) end
    assert(UI.hud.textWrites>writes and UI.hud.textWrites-writes<=4,
        "HUD writes stay bounded at four per simulated second during motion")
    UI.OnUpdate(0.537)
    UI.Stop("hitch timing sample")
    assert(UI.clock.lastSteps==5 and UI.clock.droppedSeconds>0.4,"hitch keeps bounded catch-up")
    assert(UI.hud.text:find("Ticks: "..UI.state.tick,1,true),"hitch Stop flushes final HUD")
    assert(math.abs(UI.clock.elapsedSeconds-UI.clock.steps*UI.clock.dt-
           UI.clock.droppedSeconds-UI.clock.accumulator)<1e-10,"hitch sample retains all elapsed time")
    assert(#env.output==output,"active sampling and Stop do not print periodic chat")
end)

withMock(nil, false, function(env,UI)
    env.fire("ADDON_LOADED","AzerothKart")
    assert(not env.namespace.events.GLOBAL_MOUSE_DOWN,"unsupported event not claimed available")
    assert(env.namespace.eventFailures=="GLOBAL_MOUSE_DOWN","unsupported event reported")
    UI.Toggle(); UI.Start()
    assert(not UI.active,"unsupported global mouse event fails closed")
end, "GLOBAL_MOUSE_DOWN")

-- Cold load and toggle in combat may construct ordinary UI, but cannot capture
-- input or invoke the guarded propagation setter. Real API legality is pending.
withMock(nil, true, function(env,UI)
    env.fire("ADDON_LOADED","AzerothKart")
    assert(UI.window and not UI.window:IsShown(),"combat startup creates hidden probe UI")
    assert(UI.window.keyboard==false,"combat startup keeps keyboard disabled")
    UI.Create(); UI.Toggle(); UI.Start()
    assert(not UI.active,"combat cannot start capture")
    assert(env.combatPropagationCalls==0,"combat startup never sets propagation")
    env.combat=false; env.fire("PLAYER_REGEN_ENABLED")
    assert(not UI.active,"deferred startup does not resume a drive")
    assert(UI.window.propagate,"combat end restores propagation after cold load")
    if UI.window:IsShown() then UI.Toggle() end
    UI.Toggle()
    assert(UI.window and UI.window:IsShown(),"explicit toggle can create after combat")
end)

for _,fixture in ipairs({
    {value=false}, {value="bad save"}, {value=42},
    {value={custom="preserve"}},
    {value={schemaVersion="bad",custom="preserve"}},
    {value={schemaVersion=0/0,custom="preserve"}},
    {value={schemaVersion=math.huge,custom="preserve"}},
    {value={schemaVersion=0,custom="preserve"}},
    {value={schemaVersion=1.5,custom="preserve"}},
    {value={schemaVersion=42,custom="preserve"}},
}) do
    local originalSchema=type(fixture.value)=="table" and fixture.value.schemaVersion or nil
    withMock(fixture.value, false, function(env)
        env.fire("ADDON_LOADED","AzerothKart")
        assert(type(AzerothKartDB)=="table","non-table save receives minimal table")
        local expected=originalSchema
        if expected==nil then expected=1 end
        local actual=AzerothKartDB.schemaVersion
        assert(actual==expected or (actual~=actual and expected~=expected),
            "M0 schema marker initialized only when absent; existing values preserved")
        if type(fixture.value)=="table" then
            assert(AzerothKartDB==fixture.value and AzerothKartDB.custom=="preserve",
                "save repair preserves unknown fields in place")
        end
    end)
end
originalPrint(summary.." (mock regression only; live-client probes pending)")
