-- M0 presentation/input adapter. Mocked tests do not establish client API safety.
local _, AK = ...
assert(type(AK) == "table", "addon namespace required")
local Track, Physics, Input, Loop = AK.Track, AK.Physics, AK.Input, AK.Loop
local UI = {
    active=false, keys=Input.new(), input={}, pendingPropagationRelease=false,
    objects={frames=0, textures=0, fontStrings=0}, stopReason="Not started",
}
AK.UI = UI

local function inCombat()
    -- Missing combat API fails closed for keyboard capture.
    return type(InCombatLockdown) ~= "function" or InCombatLockdown()
end

local function report(line)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("Azeroth Kart: " .. line)
    else print("Azeroth Kart: " .. line) end
end

local function frame(kind, name, parent, template)
    UI.objects.frames = UI.objects.frames + 1
    return CreateFrame(kind, name, parent, template)
end

local function texture(parent, layer)
    UI.objects.textures = UI.objects.textures + 1
    return parent:CreateTexture(nil, layer)
end

local function text(parent, anchor, x, y, value)
    UI.objects.fontStrings = UI.objects.fontStrings + 1
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint(anchor, parent, anchor, x, y)
    label:SetText(value)
    return label
end

function UI.ReleaseInput()
    Input.clear(UI.keys)
    Input.sample(UI.keys, UI.input)
    if not UI.window then return end
    -- EnableKeyboard(false) at combat onset still requires the F2 live probe.
    if type(UI.window.EnableKeyboard) == "function" then UI.window:EnableKeyboard(false) end
    if inCombat() then
        UI.pendingPropagationRelease = true
    else
        if type(UI.window.SetPropagateKeyboardInput) == "function" then
            UI.window:SetPropagateKeyboardInput(true)
        end
        UI.pendingPropagationRelease = false
    end
end

function UI.Stop(reason)
    UI.active = false
    UI.stopReason = reason or "Test drive stopped"
    UI.ReleaseInput()
    if UI.clock then UI.clock.accumulator = 0 end
    if UI.status then UI.status:SetText(UI.stopReason .. " | Click Start to capture again") end
    if UI.startButton then UI.startButton:Enable() end
    if UI.stopButton then UI.stopButton:Disable() end
end

function UI.InterruptCombat()
    if not UI.active then return end -- terminal once for the current test drive
    UI.result = {status="interrupted", reason="Game interrupted by combat", tick=UI.state.tick}
    -- There is no race/placement engine in M0; never fabricate a classification.
    UI.Stop(UI.result.reason)
    UI.window:Hide()
    report(UI.result.reason)
end

local function keyEvent(key, down)
    if not UI.active then return end
    if inCombat() then UI.InterruptCombat(); return end
    if type(GetCurrentKeyBoardFocus) == "function" and GetCurrentKeyBoardFocus() then
        UI.Stop("Text input has focus"); return
    end
    if type(key) ~= "string" then return end
    key = string.upper(key)
    if key == "ESCAPE" then UI.Stop("Exited test drive"); return end
    if key == "W" or key == "UP" or key == "S" or key == "DOWN"
        or key == "A" or key == "LEFT" or key == "D" or key == "RIGHT" then
        Input.set(UI.keys, key, down)
    elseif down then
        -- Enter/chat/menu bindings release capture before normal UI handling.
        UI.Stop("Other key released controls")
    end
end

local function drawTrack(canvas)
    -- Static placeholder tiles; collision remains the analytical annulus.
    for n=0,95 do
        local angle = n / 96 * math.pi * 2
        local piece = texture(canvas, "BACKGROUND")
        piece:SetColorTexture(0.26,0.25,0.23,1)
        piece:SetSize(79,68)
        piece:SetPoint("CENTER",canvas,"BOTTOMLEFT",
            Track.centerX + Track.lineX * math.cos(angle),
            Track.centerY + Track.lineY * math.sin(angle))
    end
    local line = texture(canvas, "ARTWORK")
    line:SetColorTexture(0.98,0.93,0.45,0.9)
    line:SetSize(5,95)
    line:SetPoint("CENTER",canvas,"BOTTOMLEFT",Track.centerX+Track.lineX,Track.centerY)
end

local function render()
    UI.kart:ClearAllPoints()
    UI.kart:SetPoint("CENTER",UI.canvas,"BOTTOMLEFT",UI.state.x,UI.state.y)
    UI.kart:SetRotation(UI.state.heading - math.pi/2)
end

function UI.Create()
    if UI.window then return end
    local window = frame("Frame","AzerothKartMainWindow",UIParent,"BackdropTemplate")
    UI.window = window
    window:SetSize(856,640)
    window:SetPoint("CENTER")
    window:SetFrameStrata("DIALOG")
    window:SetClampedToScreen(true)
    window:EnableMouse(true)
    UI.ReleaseInput() -- guarded even when ADDON_LOADED happens in combat
    window:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",
        edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=12,
        insets={left=4,right=4,top=4,bottom=4}})
    window:SetBackdropColor(0.09,0.10,0.13,0.98)
    window:Hide()
    window:SetScript("OnKeyDown",function(_,key) keyEvent(key,true) end)
    window:SetScript("OnKeyUp",function(_,key) keyEvent(key,false) end)
    window:SetScript("OnHide",function()
        if UI.active then UI.Stop("Window hidden") else UI.ReleaseInput() end
    end)

    local title = text(window,"TOPLEFT",28,-20,"AZEROTH KART |cff777777[M0 LOCAL PROBE]|r")
    title:SetJustifyH("LEFT")
    local close = frame("Button",nil,window,"UIPanelButtonTemplate")
    close:SetSize(72,24)
    close:SetPoint("TOPRIGHT",-16,-12)
    close:SetText("Close")
    close:SetScript("OnClick",function() UI.Stop("Closed"); window:Hide() end)

    UI.canvas = frame("Frame",nil,window)
    UI.canvas:SetSize(Track.width,Track.height)
    UI.canvas:SetPoint("TOP",0,-58)
    local grass = texture(UI.canvas,"BACKGROUND")
    grass:SetAllPoints(UI.canvas)
    grass:SetColorTexture(0.08,0.24,0.12,1)
    drawTrack(UI.canvas)
    UI.kart = texture(UI.canvas,"OVERLAY")
    UI.kart:SetColorTexture(0.98,0.54,0.14,1)
    UI.kart:SetSize(17,31)
    UI.state = Physics.new(Track)
    render()

    UI.status = text(window,"BOTTOMLEFT",28,67,"Out of combat: Start Test Drive")
    UI.status:SetJustifyH("LEFT")
    UI.hud = text(window,"BOTTOMLEFT",28,44,"Speed: 0 | Ticks: 0")
    UI.hud:SetJustifyH("LEFT")
    UI.startButton = frame("Button",nil,window,"UIPanelButtonTemplate")
    UI.startButton:SetSize(130,24)
    UI.startButton:SetPoint("BOTTOMLEFT",28,12)
    UI.startButton:SetText("Start Test Drive")
    UI.startButton:SetScript("OnClick",function() UI.Start() end)
    UI.stopButton = frame("Button",nil,window,"UIPanelButtonTemplate")
    UI.stopButton:SetSize(90,24)
    UI.stopButton:SetPoint("BOTTOMLEFT",170,12)
    UI.stopButton:SetText("Stop")
    UI.stopButton:SetScript("OnClick",function() UI.Stop("Stopped") end)
    UI.stopButton:Disable()
    UI.probeButton = frame("Button",nil,window,"UIPanelButtonTemplate")
    UI.probeButton:SetSize(112,24)
    UI.probeButton:SetPoint("BOTTOMRIGHT",-28,12)
    UI.probeButton:SetText("Print Probe")
    UI.probeButton:SetScript("OnClick",function() UI.ReportProbe() end)
    window:SetScript("OnUpdate",function(_,elapsed) UI.OnUpdate(elapsed) end)
end

function UI.Start()
    if not UI.window or not UI.window:IsShown() then return end
    if inCombat() then UI.status:SetText("Cannot start while in combat"); return end
    if type(GetCurrentKeyBoardFocus) ~= "function"
        or type(UI.window.EnableKeyboard) ~= "function"
        or type(UI.window.SetPropagateKeyboardInput) ~= "function"
        or not (AK.events and AK.events.GLOBAL_MOUSE_DOWN) then
        UI.status:SetText("Input safety APIs unavailable; run /akart probe"); return
    end
    if GetCurrentKeyBoardFocus() then UI.status:SetText("Close text input before starting"); return end
    UI.ReleaseInput()
    UI.state = Physics.new(Track)
    UI.clock = Loop.new(Physics.FIXED_DT,5)
    UI.hudElapsed = 0
    UI.result = nil
    UI.stopReason = "Driving"
    UI.window:SetPropagateKeyboardInput(false)
    UI.window:EnableKeyboard(true)
    UI.active = true
    render()
    UI.status:SetText("Controls active: W/A/S/D or arrows | Esc / other key to release")
    UI.startButton:Disable()
    UI.stopButton:Enable()
end

local function step(dt)
    Input.sample(UI.keys,UI.input)
    UI.state = Physics.step(UI.state,UI.input,dt,Track)
end

function UI.OnUpdate(elapsed)
    if not UI.active then return end
    if inCombat() then UI.InterruptCombat(); return end
    if GetCurrentKeyBoardFocus() then UI.Stop("Text input has focus"); return end
    if type(IsGameWindowFocused) == "function" and not IsGameWindowFocused() then
        UI.Stop("Game window lost focus"); return
    end
    local steps = Loop.advance(UI.clock,elapsed,step)
    render()
    UI.hudElapsed = UI.hudElapsed + steps * Physics.FIXED_DT
    if UI.hudElapsed >= 0.25 then
        UI.hudElapsed = 0
        UI.hud:SetText(("Speed: %d | Ticks: %d | Dropped: %.3fs"):format(
            math.floor(math.abs(UI.state.speed)+0.5),UI.state.tick,UI.clock.droppedSeconds))
    end
end

function UI.OnCombatEnded()
    if UI.pendingPropagationRelease and UI.window and not inCombat()
        and type(UI.window.SetPropagateKeyboardInput) == "function" then
        UI.window:SetPropagateKeyboardInput(true)
        UI.pendingPropagationRelease = false
    end
end

function UI.HandleEvent(event)
    if event == "PLAYER_REGEN_ENABLED" then UI.OnCombatEnded(); return end
    if not UI.active then return end
    if event == "PLAYER_REGEN_DISABLED" then UI.InterruptCombat()
    elseif event == "GLOBAL_MOUSE_DOWN" then
        -- Bounds cannot identify which overlapping UI owns the click. M0 gives
        -- up capture on every click; the Start click's down precedes OnClick.
        UI.Stop("Mouse click released controls")
    elseif event == "PLAYER_LEAVING_WORLD" or event == "PLAYER_LOGOUT" then
        UI.Stop(event)
    end
end

function UI.ReportProbe()
    local version,build,_,interface
    if type(GetBuildInfo) == "function" then version,build,_,interface = GetBuildInfo() end
    local toc = "unknown"
    if C_AddOns and type(C_AddOns.GetAddOnMetadata) == "function" then
        toc = C_AddOns.GetAddOnMetadata("AzerothKart","X-AzerothKart-TOC") or toc
    end
    local c = UI.clock
    report(("M0 version=%s build=%s interface=%s selectedTOC=%s focusApi=%s"):format(
        tostring(version),tostring(build),tostring(interface),toc,tostring(type(IsGameWindowFocused)=="function")))
    report(("frames=%d ticks=%d maxElapsed=%.4f droppedSeconds=%.4f hitchFrames=%d accumulator=%.5f"):format(
        c and c.frames or 0,c and c.steps or 0,c and c.maxElapsed or 0,
        c and c.droppedSeconds or 0,c and c.hitchFrames or 0,c and c.accumulator or 0))
    report(("UI frames=%d textures=%d fontStrings=%d active=%s stopReason=%s"):format(
        UI.objects.frames,UI.objects.textures,UI.objects.fontStrings,tostring(UI.active),UI.stopReason))
    report("eventRegistrationFailures=" .. (AK.eventFailures or "none"))
    report(("combatApi=%s textFocusApi=%s keyboardApi=%s propagationApi=%s"):format(
        tostring(type(InCombatLockdown)=="function"),tostring(type(GetCurrentKeyBoardFocus)=="function"),
        tostring(UI.window and type(UI.window.EnableKeyboard)=="function" or false),
        tostring(UI.window and type(UI.window.SetPropagateKeyboardInput)=="function" or false)))
end

function UI.Toggle()
    UI.Create()
    if UI.window:IsShown() then UI.Stop("Closed"); UI.window:Hide()
    else UI.window:Show() end
end

return UI
