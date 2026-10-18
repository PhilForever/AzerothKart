-- Purely UI implementation. API/focus behavior MUST be tested in Forever.
local AK = _G.AzerothKart or {}
_G.AzerothKart = AK
local Track, Physics = AK.Track, AK.Physics
local UI = {active=false, accumulator=0, keys={}, pendingPropagationRelease=false}
AK.UI = UI

local function inCombat()
    return type(InCombatLockdown) == "function" and InCombatLockdown()
end

local function makeText(parent, size, anchor, x, y, value)
    local f = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f:SetPoint(anchor, parent, anchor, x, y)
    f:SetText(value or "")
    return f
end

local function normalizeKey(key)
    if type(key) ~= "string" then return nil end
    return string.upper(key)
end

local function setControlsFromKey(self, key, down)
    key = normalizeKey(key)
    if not key then return end
    if key == "ESCAPE" and down then
        UI.Stop("Exited test drive")
        return
    end
    if key == "W" or key == "UP" then UI.keys.accelerate = down end
    if key == "S" or key == "DOWN" then UI.keys.brake = down end
    if key == "A" or key == "LEFT" then UI.keys.left = down end
    if key == "D" or key == "RIGHT" then UI.keys.right = down end
end

function UI.ReleaseInput()
    UI.keys = {}
    if not UI.window then return end
    -- EnableKeyboard is documented; test if safe at combat onset in actual client.
    UI.window:EnableKeyboard(false)
    if inCombat() then
        -- Never invoke restricted SetPropagateKeyboardInput while in combat.
        UI.pendingPropagationRelease = true
        return
    end
    UI.window:SetPropagateKeyboardInput(true)
    UI.pendingPropagationRelease = false
end

function UI.Stop(reason)
    UI.active = false
    UI.ReleaseInput()
    UI.accumulator = 0
    if UI.status then UI.status:SetText(reason or "Test drive stopped") end
    if UI.startButton then UI.startButton:Enable() end
    if UI.stopButton then UI.stopButton:Disable() end
end

local function drawTrack(canvas)
    -- Pooled visible tiles approximating an oval. Analytical collision is independent.
    for n=0,95 do
        local t = (n/96) * math.pi * 2
        local tx = Track.centerX + Track.lineX * math.cos(t)
        local ty = Track.centerY + Track.lineY * math.sin(t)
        local piece = canvas:CreateTexture(nil,"BACKGROUND")
        piece:SetColorTexture(0.26,0.25,0.23,1)
        piece:SetSize(79,68)
        piece:SetPoint("CENTER",canvas,"BOTTOMLEFT",tx,ty)
    end
    -- Start line marks x-positive centerline; local prototype has no lap checking.
    local line = canvas:CreateTexture(nil,"ARTWORK")
    line:SetColorTexture(0.98,0.93,0.45,0.9)
    line:SetSize(5,95)
    line:SetPoint("CENTER",canvas,"BOTTOMLEFT",Track.centerX+Track.lineX, Track.centerY)
end

function UI.Create()
    if UI.window then return end
    local window = CreateFrame("Frame","AzerothKartMainWindow",UIParent,"BackdropTemplate")
    UI.window=window
    window:SetSize(856,590)
    window:SetPoint("CENTER")
    window:SetFrameStrata("DIALOG")
    window:SetClampedToScreen(true)
    window:EnableMouse(true)
    window:EnableKeyboard(false)
    window:SetPropagateKeyboardInput(true)
    window:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",
        edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", edgeSize=12,
        insets={left=4,right=4,top=4,bottom=4}})
    window:SetBackdropColor(0.09,0.10,0.13,0.98)
    window:Hide()
    window:SetScript("OnKeyDown",function(self,key) if UI.active then setControlsFromKey(self,key,true) end end)
    window:SetScript("OnKeyUp",function(self,key) if UI.active then setControlsFromKey(self,key,false) end end)
    window:SetScript("OnHide",function() if UI.active then UI.Stop("Window hidden") end end)

    local title=makeText(window,18,"TOPLEFT",30,-18,"AZEROTH KART |cff777777[TEST DRIVE]|r")
    title:SetJustifyH("LEFT")
    local close=CreateFrame("Button",nil,window,"UIPanelButtonTemplate")
    close:SetSize(72,24)
    close:SetPoint("TOPRIGHT",-16,-12)
    close:SetText("Close")
    close:SetScript("OnClick",function() UI.Stop("Closed"); window:Hide() end)

    local canvas=CreateFrame("Frame",nil,window)
    UI.canvas=canvas
    canvas:SetSize(Track.width,Track.height)
    canvas:SetPoint("TOP",0,-58)
    local grass=canvas:CreateTexture(nil,"BACKGROUND")
    grass:SetAllPoints(canvas)
    grass:SetColorTexture(0.08,0.24,0.12,1)
    drawTrack(canvas)

    local kart=canvas:CreateTexture(nil,"OVERLAY")
    UI.kart=kart
    kart:SetColorTexture(0.98,0.54,0.14,1)
    kart:SetSize(17,31)
    kart:SetPoint("CENTER",canvas,"BOTTOMLEFT",Track.spawn().x,Track.spawn().y)

    UI.status=makeText(window,13,"BOTTOMLEFT",30,21,"Out of combat: Start Test Drive")
    UI.status:SetJustifyH("LEFT")
    UI.hud=makeText(window,13,"BOTTOMRIGHT",-150,21,"Speed: 0")
    UI.startButton=CreateFrame("Button",nil,window,"UIPanelButtonTemplate")
    UI.startButton:SetSize(116,24)
    UI.startButton:SetPoint("BOTTOM",window,"BOTTOM",-65,15)
    UI.startButton:SetText("Start Test Drive")
    UI.startButton:SetScript("OnClick",function() UI.Start() end)
    UI.stopButton=CreateFrame("Button",nil,window,"UIPanelButtonTemplate")
    UI.stopButton:SetSize(90,24)
    UI.stopButton:SetPoint("BOTTOM",window,"BOTTOM",60,15)
    UI.stopButton:SetText("Stop")
    UI.stopButton:SetScript("OnClick",function() UI.Stop("Stopped") end)
    UI.stopButton:Disable()

    window:SetScript("OnUpdate",function(_,elapsed) UI.OnUpdate(elapsed) end)
end

function UI.Start()
    if not UI.window then return end
    if inCombat() then
        UI.status:SetText("Cannot start while in combat")
        return
    end
    UI.state=Physics.new(Track)
    UI.keys={}
    UI.accumulator=0
    UI.pendingPropagationRelease=false
    -- Only deliberate Start click captures keys. Restricted call is outside combat.
    UI.window:SetPropagateKeyboardInput(false)
    UI.window:EnableKeyboard(true)
    UI.active=true
    UI.status:SetText("Controls captured: W/A/S/D or arrows · Esc to stop")
    UI.startButton:Disable()
    UI.stopButton:Enable()
end

function UI.OnUpdate(elapsed)
    if not UI.active then return end
    if inCombat() then
        UI.Stop("Combat interrupted test drive")
        return
    end
    elapsed = math.min(elapsed or 0,0.10)
    UI.accumulator=UI.accumulator+elapsed
    local steps=0
    while UI.accumulator>=Physics.FIXED_DT and steps<5 do
        UI.state=Physics.step(UI.state,UI.keys,Physics.FIXED_DT,Track)
        UI.accumulator=UI.accumulator-Physics.FIXED_DT
        steps=steps+1
    end
    if steps==5 and UI.accumulator>=Physics.FIXED_DT then
        -- Avoid spiral of death after a frame hitch. Record metrics in M1.
        UI.accumulator=0
    end
    UI.kart:ClearAllPoints()
    UI.kart:SetPoint("CENTER",UI.canvas,"BOTTOMLEFT",UI.state.x,UI.state.y)
    UI.kart:SetRotation(UI.state.heading - math.pi/2)
    UI.hud:SetText(("Speed: %d | Ticks: %d"):format(math.floor(math.abs(UI.state.speed)+0.5),UI.state.tick))
end

function UI.OnCombatEnded()
    if UI.pendingPropagationRelease and UI.window then
        UI.window:SetPropagateKeyboardInput(true)
        UI.pendingPropagationRelease=false
    end
end

function UI.Toggle()
    UI.Create()
    if UI.window:IsShown() then
        UI.Stop("Closed")
        UI.window:Hide()
    else
        UI.window:Show()
    end
end

return UI
