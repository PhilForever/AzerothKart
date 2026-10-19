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

local function withMock(savedDB, initialCombat, test, unsupportedEvent, snappingMode)
    local previous = {}
    for _,name in ipairs(globalNames) do
        previous[#previous+1] = {name=name, value=_G[name]}
    end
    local env = {
        combat=initialCombat or false, focus=nil, focused=true, mouseInside=true,
        frames={}, textures={}, output={}, counts={frames=0, textures=0, fontStrings=0},
        propagationCalls=0, combatPropagationCalls=0, keyboardReleaseCalls=0,
        profileTime=0, profileCalls=0, snappingCalls=0, drawLayerCalls=0,
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
    function methods:SetSize(width,height) self.width,self.height=width,height end
    function methods:SetPoint(...) self.point={...} end
    function methods:SetColorTexture(...) self.color={...} end
    function methods:SetDrawLayer(layer,sublevel)
        env.drawLayerCalls=env.drawLayerCalls+1
        self.layer,self.sublevel=layer,sublevel or 0
    end
    local function geometryReady(item)
        return type(rawget(item,"color"))=="table" and
            type(rawget(item,"width"))=="number" and
            type(rawget(item,"height"))=="number" and
            type(rawget(item,"point"))=="table"
    end
    function methods:SetTexelSnappingBias(value)
        env.snappingCalls=env.snappingCalls+1
        self.snappingBias=value
        self.biasAfterGeometry=geometryReady(self)
    end
    function methods:SetSnapToPixelGrid(value)
        env.snappingCalls=env.snappingCalls+1
        self.snapToGrid=value
        self.gridAfterGeometry=geometryReady(self)
    end
    function methods:CreateTexture(_,layer)
        local item=object("textures")
        item.parent,item.layer,item.sublevel=self,layer,0
        if snappingMode=="missing" then
            item.SetTexelSnappingBias,item.SetSnapToPixelGrid=false,false
        elseif snappingMode=="throws" then
            item.SetTexelSnappingBias=function() error("mock snapping API refuses") end
            item.SetSnapToPixelGrid=function() error("mock grid API refuses") end
        end
        env.textures[#env.textures+1]=item
        return item
    end
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
        env.profileCalls=env.profileCalls+1
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
        for _,name in ipairs({"Track", "Physics", "Input", "Loop", "Performance", "UI", "Core"}) do
            assert(loadfile("addon/AzerothKart/"..name..".lua"))("AzerothKart",namespace)
        end
        env.namespace=namespace
        test(env,namespace.UI)
    end)
    for _,entry in ipairs(previous) do _G[entry.name]=entry.value end
    assert(ok,err)
end

-- Check the actual static rectangles, rather than a second copy of the drawing
-- formula. Row sampling can differ from the analytical edge by at most half a
-- band vertically; samples farther than 3.5 units away must classify identically.
local renderSummary
withMock(nil, false, function(env,UI)
    env.fire("ADDON_LOADED","AzerothKart")
    local Track=env.namespace.Track
    local outer,inner={},{}
    local grass,grassCount=nil,0
    local function sameColor(actual,r,g,b)
        return type(actual)=="table" and actual[1]==r and actual[2]==g
            and actual[3]==b and actual[4]==1
    end
    for _,item in ipairs(env.textures) do
        local color=rawget(item,"color")
        local bands
        if sameColor(color,0.26,0.25,0.23) then
            assert(item.layer=="BACKGROUND","outer road must use its background layer")
            bands=outer
        elseif sameColor(color,0.08,0.24,0.12) and item.layer=="BORDER" then
            bands=inner
        elseif sameColor(color,0.08,0.24,0.12) and item.layer=="BACKGROUND" then
            grass,grassCount=item,grassCount+1
        end
        if bands then
            assert(rawget(item,"snappingBias")==0 and rawget(item,"snapToGrid")==false,
                "road band disables texture sharpening/pixel snapping at creation")
            assert(rawget(item,"biasAfterGeometry")==true and rawget(item,"gridAfterGeometry")==true,
                "road snapping is configured after color, size and anchor setup")
            if bands==outer then
                assert(item.sublevel==0,"outer bands retain their default background sublevel")
            end
            local point=rawget(item,"point")
            assert(type(point)=="table" and point[2]==UI.canvas and point[3]=="BOTTOMLEFT",
                "road bands must use canvas coordinates")
            local width,height=rawget(item,"width"),rawget(item,"height")
            assert(type(width)=="number" and type(height)=="number" and width>0 and height>0,
                "road bands must have positive finite dimensions")
            local x,y=point[4],point[5]
            assert(type(x)=="number" and type(y)=="number","road bands need numeric positions")
            if point[1]=="CENTER" then x,y=x-width/2,y-height/2
            else assert(point[1]=="BOTTOMLEFT","unsupported band anchor") end
            local rect={left=x,right=x+width,bottom=y,top=y+height}
            assert(rect.left>=0 and rect.right<=Track.width and
                   rect.bottom>=0 and rect.top<=Track.height,"road band escaped the canvas")
            bands[#bands+1]=rect
        end
    end
    assert(#outer==64 and #inner==32,"road uses 64 outer bands and 32 island bands")
    assert(grassCount==1 and grass.sublevel==-1,
        "full-canvas grass must be explicitly below the outer bands")
    assert(rawget(grass,"snappingBias")==nil and rawget(grass,"snapToGrid")==nil,
        "grass snapping stays unchanged; explicit draw priority separates it from the road")
    assert(env.drawLayerCalls==1,"only the grass configures an explicit draw sublevel once")
    assert(env.snappingCalls==192,"only the 96 road bands configure snapping once")
    assert(UI.objects.frames==6 and UI.objects.textures==99 and UI.objects.fontStrings==3,
        "aligned placeholder must retain the existing explicit UI object budget")
    local function covered(rectangles,x,y)
        for _,rect in ipairs(rectangles) do
            if y>=rect.bottom and y<=rect.top and x>=rect.left and x<=rect.right then
                return true
            end
        end
        return false
    end
    local function paintedRoad(x,y)
        return covered(outer,x,y) and not covered(inner,x,y)
    end
    assert(Track.isDrivable(400,440) and paintedRoad(400,440),
        "drivable road near the top must be painted instead of misleading grass")
    local function nearBoundary(x,y,radiusX,radiusY)
        local dx=x-Track.centerX
        if math.abs(dx)>radiusX then return false end
        local extent=radiusY*math.sqrt(math.max(0,1-(dx/radiusX)^2))
        return math.abs(y-(Track.centerY-extent))<=3.5 or
               math.abs(y-(Track.centerY+extent))<=3.5
    end
    local checked=0
    for y=0,Track.height,2 do
        for x=0,Track.width,2 do
            if not nearBoundary(x,y,Track.outerX,Track.outerY) and
               not nearBoundary(x,y,Track.innerX,Track.innerY) then
                assert(paintedRoad(x,y)==Track.isDrivable(x,y),
                    ("render/track mismatch away from boundary at (%d,%d)"):format(x,y))
                checked=checked+1
            end
        end
    end
    assert(checked>90000,"dense grid must cover the canvas away from raster edges")
    renderSummary=("mock road: %d outer + %d island bands; %d grid points agree outside 3.5-unit vertical margin")
        :format(#outer,#inner,checked)
end)
originalPrint(renderSummary.." (client appearance still pending)")

for _,mode in ipairs({"missing", "throws"}) do
    withMock(nil,false,function(env,UI)
        env.fire("ADDON_LOADED","AzerothKart")
        UI.Toggle(); UI.Start(); UI.OnUpdate(1/60)
        assert(UI.active and UI.state.tick==1,"optional snapping APIs cannot block driving: "..mode)
        assert(UI.objects.frames==6 and UI.objects.textures==99 and UI.objects.fontStrings==3,
            "snapping fallback preserves UI object budget: "..mode)
        assert(env.drawLayerCalls==1,"grass priority remains explicit when snapping is unavailable: "..mode)
    end,nil,mode)
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
    local snappingCalls,drawLayerCalls=env.snappingCalls,env.drawLayerCalls
    local function assertPooled()
        assert(env.snappingCalls==snappingCalls and env.drawLayerCalls==drawLayerCalls,
            "updates/reopen never reconfigure snapping or draw priority")
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

-- Optional profiler readings are diagnostic only; normal updates do no reads.
withMock(nil, false, function(env,UI)
    env.fire("ADDON_LOADED","AzerothKart")
    UI.Toggle(); UI.Start()
    for _=1,10 do UI.OnUpdate(1/60) end
    assert(not UI.performanceEnabled and UI.performance==nil and env.profileCalls==0,
        "profiling is off by default with zero profiler calls")
    local clock=UI.clock
    SlashCmdList.AZEROTHKART("perf on")
    assert(UI.active and UI.clock==clock and not UI.performanceEnabled,
        "changing profiling during capture is refused without changing driving")
    UI.Stop("profile setup")
    local before=#env.output
    SlashCmdList.AZEROTHKART("  perf  ")
    assert(#env.output==before+3 and env.output[before+1]:find("state=not-started",1,true),
        "explicit perf query has three bounded lines and labels absent samples")
    SlashCmdList.AZEROTHKART("perf nonsense")
    assert(UI.window:IsShown() and env.output[#env.output]:find("Usage:",1,true),
        "invalid perf arguments show usage rather than toggling the window")
    SlashCmdList.AZEROTHKART(" perf on ")
    assert(UI.performanceEnabled and env.profileCalls==1,"arming checks one valid clock reading")
    UI.Start()
    local sample=UI.performance
    before=#env.output
    env.key(UI,"OnKeyDown","W")
    for frame=1,650 do
        if frame==100 then env.key(UI,"OnKeyDown","A") end
        if frame==200 then env.key(UI,"OnKeyUp","A") end
        UI.OnUpdate(1/60)
    end
    assert(sample.attempts==600 and sample.samples==600 and sample.invalid==0,
        "profiled sample caps at 600 active updates")
    assert(env.profileCalls==1801,"no profiler calls occur after the window is full")
    assert(math.abs(sample.simulationMs-6)<1e-8 and math.abs(sample.renderMs-6)<1e-8 and
           math.abs(sample.totalMs-12)<1e-8,"profile phases accumulate known mock milliseconds")
    assert(#env.output==before,"sampling/completion never prints per-frame chat")
    assert(UI.objects.frames==6 and UI.objects.textures==99 and UI.objects.fontStrings==3,
        "profiling creates no UI objects")
    local state={}
    for key,value in pairs(UI.state) do state[key]=value end
    UI.Stop("profile stopped"); UI.Toggle(); UI.Toggle()
    for _=1,10 do UI.OnUpdate(1) end
    assert(UI.performance==sample and sample.samples==600 and env.profileCalls==1801,
        "Stop and reopen freeze the same diagnostic window")
    before=#env.output
    SlashCmdList.AZEROTHKART("perf")
    assert(#env.output==before+3 and env.output[before+1]:find("state=complete",1,true),
        "completed window is reported explicitly")
    assert(env.output[before+2]:find("totalAvg=0.0200",1,true) and
           env.output[before+3]:find("exclusiveCPU=false",1,true),"timing units/scope are explicit")
    SlashCmdList.AZEROTHKART("perf off")
    assert(not UI.performanceEnabled and UI.performance==sample,"off retains the stopped result")
    UI.Start()
    assert(UI.performance==nil,"a new unprofiled Start clears the prior diagnostic window")
    env.key(UI,"OnKeyDown","W")
    for frame=1,650 do
        if frame==100 then env.key(UI,"OnKeyDown","A") end
        if frame==200 then env.key(UI,"OnKeyUp","A") end
        UI.OnUpdate(1/60)
    end
    for key,value in pairs(state) do
        assert(UI.state[key]==value,"profiling altered deterministic driving field "..key)
    end
    assert(env.profileCalls==1801,"unprofiled drive never reads the profiler")
    UI.Stop("fresh profile")
    SlashCmdList.AZEROTHKART("perf on"); UI.Start()
    assert(UI.performance~=sample and UI.performance.attempts==0,
        "a fresh profiled Start creates a new empty window")
end)

withMock(nil, false, function(env,UI)
    env.fire("ADDON_LOADED","AzerothKart")
    UI.Toggle()
    local reader=debugprofilestop
    for _,mode in ipairs({"missing", "throws", "string", "nan", "infinity", "negative"}) do
        if mode=="missing" then _G.debugprofilestop=nil
        else _G.debugprofilestop=function()
            if mode=="throws" then error("mock timer unavailable") end
            if mode=="string" then return "invalid" end
            if mode=="nan" then return 0/0 end
            if mode=="infinity" then return math.huge end
            return -1
        end end
        SlashCmdList.AZEROTHKART("perf on")
        assert(not UI.performanceEnabled,"invalid arm reading rejected: "..mode)
        UI.Start(); UI.OnUpdate(1/60)
        assert(UI.active and UI.state.tick==1,"unavailable profiler cannot block driving: "..mode)
        UI.Stop("unavailable profile")
    end
    -- A reader can fail after arming. Invalid attempts are bounded and must not
    -- become valid zero-cost samples or abort the fixed-step simulation.
    local calls=0
    _G.debugprofilestop=function()
        calls=calls+1
        if calls==1 then return 10 end
        if calls%3==0 then error("mock timer reset/error") end
        return "bad"
    end
    SlashCmdList.AZEROTHKART("perf on"); UI.Start()
    local before=#env.output
    for _=1,610 do UI.OnUpdate(1/60) end
    assert(UI.active and UI.state.tick==610,"clock errors do not stop simulation")
    assert(UI.performance.attempts==600 and UI.performance.samples==0 and UI.performance.invalid==600,
        "invalid reads consume the bounded attempt budget without fabricated samples")
    assert(calls==1801 and #env.output==before,"invalid sampling remains bounded and silent")
    UI.Stop("invalid sample retained")
    _G.debugprofilestop=reader
    SlashCmdList.AZEROTHKART("perf on"); UI.Start()
    local validTimestamp=env.namespace.Performance.validTimestamp
    env.namespace.Performance.validTimestamp=function() error("mock opaque timestamp cannot be compared") end
    for _=1,610 do UI.OnUpdate(1/60) end
    env.namespace.Performance.validTimestamp=validTimestamp
    assert(UI.active and UI.state.tick==610 and UI.performance.attempts==600 and
           UI.performance.invalid==600 and UI.performance.samples==0,
        "arithmetic/validation refusal remains bounded and cannot interrupt driving")
end)

-- Combat onset must also clear an open stopped window. It is not a new
-- interruption of a drive that already ended, and must retain its sample.
for _,scenario in ipairs({"never started", "stopped", "interrupted"}) do
    withMock(nil, false, function(env,UI)
        env.combat=true; env.fire("PLAYER_REGEN_DISABLED")
        assert(not UI.window,"combat before own load does not construct UI")
        env.combat=false
        env.fire("ADDON_LOADED","AzerothKart")
        UI.Toggle()
        if scenario~="never started" then
            UI.Start()
            env.key(UI,"OnKeyDown","W")
            UI.OnUpdate(1/60+0.004)
            if scenario=="interrupted" then
                env.combat=true; env.fire("PLAYER_REGEN_DISABLED")
                env.combat=false; env.fire("PLAYER_REGEN_ENABLED")
                UI.Toggle()
            else
                UI.Stop("Mouse click released controls")
            end
        end
        local clock, state, result=UI.clock, UI.state, UI.result
        local reason, hud, status=UI.stopReason, UI.hud.text, UI.status.text
        local counters, stateValues={}, {}
        for key,value in pairs(clock or {}) do counters[key]=value end
        for key,value in pairs(state) do stateValues[key]=value end
        local output, allocations=#env.output, {}
        for key,value in pairs(env.counts) do allocations[key]=value end
        env.combat=true; env.fire("PLAYER_REGEN_DISABLED")
        assert(not UI.window:IsShown(),scenario..": combat hides stopped window")
        env.fire("PLAYER_REGEN_DISABLED"); UI.InterruptCombat(); UI.OnUpdate(1)
        assert(not UI.active and UI.window.keyboard==false and next(UI.keys)==nil,
            scenario..": combat leaves capture released")
        assert(UI.clock==clock and UI.state==state and UI.result==result,
            scenario..": combat preserves stopped sample/result identities")
        for key,value in pairs(counters) do
            assert(clock[key]==value,scenario..": combat changed stopped clock "..key)
        end
        for key,value in pairs(stateValues) do
            assert(state[key]==value,scenario..": combat changed stopped state "..key)
        end
        assert(UI.stopReason==reason and UI.hud.text==hud and UI.status.text==status,
            scenario..": stopped reason/HUD retained")
        assert(#env.output==output,scenario..": no new interrupted-drive announcement")
        assert(env.combatPropagationCalls==0,scenario..": combat never sets propagation")
        for key,value in pairs(allocations) do
            assert(env.counts[key]==value,scenario..": combat allocated UI objects")
        end
        -- A deliberate reopen can still inspect the old note and Start refusal.
        UI.Toggle(); UI.Start(); UI.OnUpdate(1)
        assert(UI.window:IsShown() and not UI.active,
            scenario..": explicit combat-time inspection stays inactive")
        assert(UI.status.text:find("Cannot start while in combat",1,true),
            scenario..": combat Start refusal remains visible")
        assert(UI.result==result and #env.output==output,
            scenario..": inspection cannot duplicate or replace a result")
        UI.Toggle()
        env.combat=false; env.fire("PLAYER_REGEN_ENABLED")
        assert(not UI.window:IsShown() and not UI.active,
            scenario..": combat ending cannot reopen or resume")
    end)
end

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
