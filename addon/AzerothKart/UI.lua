-- Solo driving presentation/input adapter. Mocked tests do not establish client API safety.
local _, AK = ...
assert(type(AK) == "table", "addon namespace required")
local Track, Physics, Input, Loop = AK.Track, AK.Physics, AK.Input, AK.Loop
local Performance = AK.Performance
local Presentation = AK.Presentation
local Checkpoints = AK.Checkpoints
local Laps = AK.Laps
local Race = AK.Race
local UI = {
    active=false, keys=Input.new(), input={}, pendingPropagationRelease=false,
    objects={frames=0, textures=0, fontStrings=0}, stopReason="Not started",
    performanceEnabled=false,
}
AK.UI = UI
local render

local function inCombat()
    -- Missing combat API fails closed for keyboard capture.
    return type(InCombatLockdown) ~= "function" or InCombatLockdown()
end

local function report(line)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("Azeroth Kart: " .. line)
    else print("Azeroth Kart: " .. line) end
end

local function readPerformanceClock(reader)
    -- Never reset the client's shared profiling timer. An unavailable/erroring
    -- reader produces an invalid diagnostic sample, not a driving failure.
    if type(reader) ~= "function" then return nil end
    local ok,value = pcall(reader)
    if ok then return value end
end

function UI.PerformanceCommand(argument)
    if argument == "" then UI.ReportPerformance(); return end
    if argument ~= "on" and argument ~= "off" then
        report("Usage: /akart perf [on|off]"); return
    end
    if UI.active then report("Stop the test drive before changing profiling"); return end
    if argument == "off" then
        UI.performanceEnabled = false
        UI.performanceReader = nil
        report("Profiling off; stopped sample retained until the next Start")
        return
    end
    local reader = debugprofilestop
    local value = readPerformanceClock(reader)
    -- Validation is guarded too: opaque values must never cause arithmetic
    -- failures in the input/simulation path or bypass client protections.
    local ok,valid = pcall(Performance.validTimestamp,value)
    if not ok or not valid then
        UI.performanceEnabled = false
        UI.performanceReader = nil
        report("Profiling unavailable: no valid debugprofilestop reading")
        return
    end
    UI.performanceEnabled = true
    UI.performanceReader = reader
    report(("Profiling armed for next Start: up to %d active updates"):format(Performance.LIMIT))
end

function UI.ReportPerformance()
    local p = UI.performance
    local samples = p and p.samples or 0
    local status = not p and "not-started" or
        (p.attempts >= Performance.LIMIT and "complete" or (UI.active and "collecting" or "stopped"))
    report(("perf armed=%s api=%s state=%s attempts=%d samples=%d invalid=%d limit=%d"):format(
        tostring(UI.performanceEnabled),tostring(type(debugprofilestop)=="function"),status,
        p and p.attempts or 0,samples,p and p.invalid or 0,Performance.LIMIT))
    local count = samples > 0 and samples or 1
    report(("perf elapsedMs simAvg=%.4f simMax=%.4f renderAvg=%.4f renderMax=%.4f totalAvg=%.4f totalMax=%.4f"):format(
        p and p.simulationMs/count or 0,p and p.simulationMaxMs or 0,
        p and p.renderMs/count or 0,p and p.renderMaxMs or 0,
        p and p.totalMs/count or 0,p and p.totalMaxMs or 0))
    report("perf scope=Loop.advance+render+HUD includesProbeOverhead=true exclusiveCPU=false")
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

local meterWidth,meterHeight = 300,12
local function refreshMeter()
    if not UI.meterFill or not UI.state then return end
    local fraction,phase = Presentation.meter(UI.state,Physics)
    if fraction ~= UI.meterFraction then
        UI.meterFraction = fraction
        if fraction <= 0 then UI.meterFill:Hide()
        else
            UI.meterFill:SetSize(meterWidth*fraction,meterHeight)
            UI.meterFill:Show()
        end
    end
    local changed = phase ~= UI.meterPhase
    local stopped = not UI.active and UI.state.tick > 0
    if changed then
        UI.meterPhase = phase
        if phase == "boost" then UI.meterFill:SetColorTexture(0.20,1.00,0.88,1)
        elseif phase == "tier2" then UI.meterFill:SetColorTexture(1.00,0.35,0.78,1)
        elseif phase == "tier1" then UI.meterFill:SetColorTexture(1.00,0.86,0.20,1)
        else UI.meterFill:SetColorTexture(0.35,0.65,1.00,1) end
        UI.meterTier1Label:SetText(phase == "boost" and "0.4 s" or "Tier 1")
        UI.meterTier2Label:SetText(phase == "boost" and "0.8 s" or "Tier 2")
    end
    if changed or stopped ~= UI.meterStopped then
        UI.meterStopped = stopped
        local caption = "DRIFT CHARGE"
        if phase == "boost" then caption = "BOOST REMAINING"
        elseif phase == "tier2" then caption = "TIER 2 READY | Release Space to boost"
        elseif phase == "tier1" then caption = "TIER 1 READY | Release Space to boost"
        elseif phase == "charging" then caption = "DRIFT CHARGE | Hold Space + turn" end
        if stopped then caption = "Last drive | " .. caption end
        UI.meterCaption:SetText(caption)
    end
end

local function createMeter(window)
    UI.meterBackground = texture(window,"BACKGROUND")
    UI.meterBackground:SetColorTexture(0.14,0.16,0.19,1)
    UI.meterBackground:SetSize(meterWidth,meterHeight)
    UI.meterBackground:SetPoint("BOTTOMLEFT",window,"BOTTOMLEFT",28,52)
    UI.meterFill = texture(window,"ARTWORK")
    UI.meterFill:SetSize(meterWidth,meterHeight)
    UI.meterFill:SetPoint("BOTTOMLEFT",window,"BOTTOMLEFT",28,52)
    UI.meterTier1Mark = texture(window,"OVERLAY")
    UI.meterTier1Mark:SetColorTexture(0.95,0.95,0.95,1)
    UI.meterTier1Mark:SetSize(2,meterHeight+4)
    UI.meterTier1Mark:SetPoint("BOTTOMLEFT",window,"BOTTOMLEFT",28+meterWidth/2-1,50)
    UI.meterTier2Mark = texture(window,"OVERLAY")
    UI.meterTier2Mark:SetColorTexture(0.95,0.95,0.95,1)
    UI.meterTier2Mark:SetSize(2,meterHeight+4)
    UI.meterTier2Mark:SetPoint("BOTTOMLEFT",window,"BOTTOMLEFT",28+meterWidth-1,50)
    UI.meterCaption = text(window,"BOTTOMLEFT",28,68,"")
    UI.meterCaption:SetJustifyH("LEFT")
    UI.meterTier1Label = text(window,"BOTTOMLEFT",28+meterWidth/2-18,38,"Tier 1")
    UI.meterTier2Label = text(window,"BOTTOMLEFT",28+meterWidth-36,38,"Tier 2")
    refreshMeter()
end

local function refreshCheckpoints()
    if not UI.checkpointHud or not UI.checkpoints then return end
    local progress = UI.checkpoints
    local changed = UI.gatePassed ~= progress.passed
    if changed then
        UI.gatePassed = progress.passed
        for index,piece in ipairs(UI.gateTextures) do
            if index <= progress.passed then piece:SetColorTexture(0.25,0.80,0.72,0.9)
            elseif index == progress.nextGate and not progress.complete then
                piece:SetColorTexture(0.98,0.93,0.45,0.9)
            else piece:SetColorTexture(0.55,0.58,0.62,0.65) end
        end
    end
    local stopped = not UI.active and UI.state.tick > 0
    if changed or stopped ~= UI.gateStopped then
        UI.gateStopped = stopped
        local caption = ("Checkpoints: %d/%d | "):format(progress.passed,#Track.gates)
        if UI.race and UI.race.status == "finished" then
            caption = "Checkpoints: 3-lap run complete"
        elseif progress.complete then caption = caption .. "Course complete"
        else caption = caption .. "Next: " .. Track.gates[progress.nextGate].name end
        if stopped then caption = "Last drive | " .. caption end
        UI.checkpointHud:SetText(caption)
    end
end

local function refreshSummary()
    if not UI.summary then return end
    local race = UI.race
    if not race or race.status == "running" then UI.summary:Hide(); return end
    if UI.summaryRace ~= race then
        UI.summaryRace = race
        if race.status == "finished" then
            UI.summaryTitle:SetText("RUN COMPLETE")
            UI.summaryDetail:SetText(("3/3 laps | Total: %.2fs\nLast lap: %.2fs"):format(
                race.totalTicks*Physics.FIXED_DT,race.laps.lastLapTicks*Physics.FIXED_DT))
        else
            UI.summaryTitle:SetText(race.status == "interrupted" and
                "GAME INTERRUPTED BY COMBAT" or "RUN STOPPED")
            UI.summaryDetail:SetText(("Laps: %d/3 | Time: %.2fs\nCurrent lap: %.2fs"):format(
                race.laps.completedLaps,race.totalTicks*Physics.FIXED_DT,
                race.laps.currentLapTicks*Physics.FIXED_DT))
        end
        UI.summaryHint:SetText("Controls released | Restart for a fresh run")
    end
    UI.summary:Show()
end

local function refreshHud()
    if not UI.hud or not UI.state then return end
    local c = UI.clock
    UI.hud:SetText(("Speed: %d | Ticks: %d | Dropped: %.3fs | Sample: %.1fs"):format(
        math.floor(math.abs(UI.state.speed)+0.5),UI.state.tick,
        c and c.droppedSeconds or 0,c and c.elapsedSeconds or 0))
    if UI.lapHud and UI.laps then
        local laps = UI.laps
        local last = laps.lastLapTicks and ("%.2fs"):format(laps.lastLapTicks*Physics.FIXED_DT) or "--"
        local caption = ("Laps: %d | Current: %.2fs | Last: %s"):format(
            laps.completedLaps,laps.currentLapTicks*Physics.FIXED_DT,last)
        if not UI.active and UI.state.tick > 0 then caption = "Last drive | " .. caption end
        UI.lapHud:SetText(caption)
    end
    if UI.driftHud then
        local state = UI.state
        local surface = state.surface == "grass" and "Grass" or
            (state.surface == "wall" and "Wall" or "Road")
        local feedback = "Drift: hold Space + turn at speed 90+ | Release Space to boost"
        if state.surface == "grass" then
            feedback = "Slowing on grass | Rejoin the road to drift"
        elseif state.surface == "wall" then
            feedback = "Steer away from the barrier and rejoin the road"
        elseif state.boostTicks > 0 then
            feedback = ("BOOST | %.2fs remaining"):format(state.boostTicks * Physics.FIXED_DT)
        elseif state.drifting then
            if state.driftTier > 0 then
                feedback = ("Drifting | Tier %d ready | Release Space to boost"):format(state.driftTier)
            else
                feedback = ("Drifting | Charge %d%% | Hold Space + turn"):format(
                    math.floor(state.driftTicks / Physics.DRIFT_TIER1_TICKS * 100))
            end
        end
        feedback = surface .. " | " .. feedback
        if not UI.active and state.tick > 0 then feedback = "Last drive | " .. feedback end
        UI.driftHud:SetText(feedback)
    end
end

local function refuseStart(reason)
    if UI.result and UI.result.status == "interrupted" then
        reason = UI.result.reason .. " | " .. reason
    end
    UI.status:SetText(reason)
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
    -- Closing an already interrupted drive cannot replace its terminal reason.
    if UI.result and (UI.result.status == "interrupted" or UI.result.status == "finished") then
        reason = UI.result.reason
    end
    if UI.race then UI.race = Race.stop(UI.race,reason,false) end
    UI.stopReason = reason or "Test drive stopped"
    UI.ReleaseInput()
    UI.previousState = UI.state
    if UI.kart and UI.state then render() end
    -- Freeze the complete timing sample, including its fractional remainder.
    -- Inactive OnUpdate does no work; a fresh Start creates a new clock.
    refreshHud()
    refreshSummary()
    if UI.status then UI.status:SetText(UI.stopReason .. " | Click Start to capture again") end
    if UI.startButton then UI.startButton:Enable() end
    if UI.stopButton then UI.stopButton:Disable() end
end

function UI.InterruptCombat()
    if not UI.active then
        -- Combat onset clears even an idle/results window. A stopped drive
        -- already ended: keep its sample/result and do not announce it again.
        if UI.window and UI.window:IsShown() then UI.window:Hide() end
        return
    end
    UI.result = {status="interrupted", reason="Game interrupted by combat", tick=UI.state.tick}
    if UI.race then
        UI.race = Race.stop(UI.race,UI.result.reason,true)
        UI.result.totalTicks = UI.race.totalTicks
        UI.result.completedLaps = UI.laps.completedLaps
    end
    -- Preserve actual solo progress; no remote placement is synthesized.
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
    if not Input.set(UI.keys, key, down) and down then
        -- Enter/chat/menu bindings release capture before normal UI handling.
        UI.Stop("Other key released controls")
    end
end

local function drawEllipse(canvas, radiusX, radiusY, rows, layer, r, g, b)
    -- Static raster bands of the same analytical ellipse used by collision.
    -- Midpoint sampling has at most half a band's vertical edge uncertainty.
    local height = 2 * radiusY / rows
    for row=0,rows-1 do
        local dy = -radiusY + (row + 0.5) * height
        local halfWidth = radiusX * math.sqrt(math.max(0,1-(dy/radiusY)^2))
        local piece = texture(canvas, layer)
        piece:SetColorTexture(r,g,b,1)
        piece:SetSize(2 * halfWidth,height)
        piece:SetPoint("BOTTOMLEFT",canvas,"BOTTOMLEFT",
            Track.centerX-halfWidth,Track.centerY+dy-height/2)
        -- Fractional bands share edges without texture sharpening/snapping.
        -- Optional setters are creation-only; failure keeps the basic renderer.
        if type(piece.SetTexelSnappingBias) == "function" then
            pcall(piece.SetTexelSnappingBias,piece,0)
        end
        if type(piece.SetSnapToPixelGrid) == "function" then
            pcall(piece.SetSnapToPixelGrid,piece,false)
        end
    end
end

local function drawTrack(canvas)
    -- Keep the 96-road-texture budget; mask the inner island above the road.
    drawEllipse(canvas,Track.outerX,Track.outerY,64,"BACKGROUND",0.26,0.25,0.23)
    drawEllipse(canvas,Track.innerX,Track.innerY,32,"BORDER",0.08,0.24,0.12)
    UI.gateTextures = {}
    for index,gate in ipairs(Track.gates) do
        local line = texture(canvas,"ARTWORK")
        line:SetColorTexture(0.55,0.58,0.62,0.65)
        line:SetSize(gate.ax == gate.bx and 5 or math.abs(gate.bx-gate.ax),
            gate.ay == gate.by and 5 or math.abs(gate.by-gate.ay))
        line:SetPoint("CENTER",canvas,"BOTTOMLEFT",(gate.ax+gate.bx)/2,(gate.ay+gate.by)/2)
        UI.gateTextures[index] = line
    end
end

local function drawWalls(canvas)
    -- Static perimeter markers; collision keeps the kart's center farther in.
    local thickness = 4
    local function strip(x,y,width,height)
        local piece = texture(canvas,"ARTWORK")
        piece:SetColorTexture(0.42,0.44,0.48,1)
        piece:SetSize(width,height)
        piece:SetPoint("BOTTOMLEFT",canvas,"BOTTOMLEFT",x,y)
    end
    strip(0,0,Track.width,thickness)
    strip(0,Track.height-thickness,Track.width,thickness)
    strip(0,thickness,thickness,Track.height-2*thickness)
    strip(Track.width-thickness,thickness,thickness,Track.height-2*thickness)
end

render = function()
    local alpha = UI.active and UI.clock and UI.clock.accumulator/UI.clock.dt or 1
    local x,y,heading = Presentation.pose(UI.previousState,UI.state,alpha)
    UI.kart:ClearAllPoints()
    UI.kart:SetPoint("CENTER",UI.canvas,"BOTTOMLEFT",x,y)
    UI.kart:SetRotation(heading - math.pi/2)
    local state = UI.state
    local tint = state.boostTicks > 0 and 4 or (state.drifting and (1 + state.driftTier) or 0)
    if tint ~= UI.kartTint then
        UI.kartTint = tint
        if tint == 4 then UI.kart:SetColorTexture(0.20,1.00,0.88,1)
        elseif tint == 3 then UI.kart:SetColorTexture(1.00,0.35,0.78,1)
        elseif tint == 2 then UI.kart:SetColorTexture(1.00,0.86,0.20,1)
        elseif tint == 1 then UI.kart:SetColorTexture(0.35,0.65,1.00,1)
        else UI.kart:SetColorTexture(0.98,0.54,0.14,1) end
    end
    refreshMeter()
    refreshCheckpoints()
end

function UI.Create()
    if UI.window then return end
    local window = frame("Frame","AzerothKartMainWindow",UIParent,"BackdropTemplate")
    UI.window = window
    window:SetSize(856,762)
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

    local title = text(window,"TOPLEFT",28,-20,"AZEROTH KART |cff777777[SOLO DRIVE]|r")
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
    -- Mixed snapping states can cover the road within one default sublayer.
    -- Keep the canvas backdrop explicitly below the outer road bands.
    grass:SetDrawLayer("BACKGROUND",-1)
    drawTrack(UI.canvas)
    drawWalls(UI.canvas)
    UI.kart = texture(UI.canvas,"OVERLAY")
    UI.kart:SetSize(17,31)
    UI.state = Physics.new(Track)
    UI.laps = Laps.new(Track,Checkpoints,UI.state.tick)
    UI.checkpoints = UI.laps.checkpoints
    UI.previousState = UI.state
    render()

    UI.lapHud = text(window,"BOTTOMLEFT",28,176,"")
    UI.lapHud:SetJustifyH("LEFT")
    UI.checkpointHud = text(window,"BOTTOMLEFT",28,154,"")
    UI.checkpointHud:SetJustifyH("LEFT")
    refreshCheckpoints()
    UI.status = text(window,"BOTTOMLEFT",28,133,"Out of combat: Start Test Drive")
    UI.status:SetJustifyH("LEFT")
    UI.hud = text(window,"BOTTOMLEFT",28,110,"Speed: 0 | Ticks: 0")
    UI.hud:SetJustifyH("LEFT")
    UI.driftHud = text(window,"BOTTOMLEFT",28,86,"")
    UI.driftHud:SetJustifyH("LEFT")
    createMeter(window)
    refreshHud()
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
    UI.summary = frame("Frame",nil,UI.canvas,"BackdropTemplate")
    UI.summary:SetSize(380,170)
    UI.summary:SetPoint("CENTER")
    UI.summary:EnableMouse(true)
    UI.summary:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",
        edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=12,
        insets={left=4,right=4,top=4,bottom=4}})
    UI.summary:SetBackdropColor(0.07,0.08,0.11,0.98)
    UI.summaryTitle = text(UI.summary,"TOPLEFT",24,-20,"")
    UI.summaryDetail = text(UI.summary,"TOPLEFT",24,-54,"")
    UI.summaryDetail:SetJustifyH("LEFT")
    UI.summaryHint = text(UI.summary,"BOTTOMLEFT",24,54,"")
    UI.restartButton = frame("Button",nil,UI.summary,"UIPanelButtonTemplate")
    UI.restartButton:SetSize(130,24)
    UI.restartButton:SetPoint("BOTTOMLEFT",24,16)
    UI.restartButton:SetText("Restart")
    UI.restartButton:SetScript("OnClick",function() UI.Start() end)
    UI.summary:Hide()
    window:SetScript("OnUpdate",function(_,elapsed) UI.OnUpdate(elapsed) end)
end

function UI.Start()
    if not UI.window or not UI.window:IsShown() then return end
    if inCombat() then refuseStart("Cannot start while in combat"); return end
    if type(GetCurrentKeyBoardFocus) ~= "function"
        or type(UI.window.EnableKeyboard) ~= "function"
        or type(UI.window.SetPropagateKeyboardInput) ~= "function"
        or not (AK.events and AK.events.GLOBAL_MOUSE_DOWN) then
        refuseStart("Input safety APIs unavailable; run /akart probe"); return
    end
    if GetCurrentKeyBoardFocus() then refuseStart("Close text input before starting"); return end
    UI.ReleaseInput()
    UI.state = Physics.new(Track)
    UI.race = Race.new(Track,Checkpoints,Laps,UI.state.tick)
    UI.laps = UI.race.laps
    UI.checkpoints = UI.laps.checkpoints
    UI.previousState = UI.state
    UI.clock = Loop.new(Physics.FIXED_DT,5)
    UI.performance = UI.performanceEnabled and Performance.new() or nil
    UI.hudElapsed = 0
    UI.result = nil
    UI.summaryRace = nil
    UI.summary:Hide()
    UI.stopReason = "Driving"
    UI.window:SetPropagateKeyboardInput(false)
    UI.window:EnableKeyboard(true)
    UI.active = true
    render()
    refreshHud()
    UI.status:SetText("3 laps | W/A/S/D or arrows | Space + turn: drift | Esc: release controls")
    UI.startButton:Disable()
    UI.stopButton:Enable()
end

local function step(dt)
    Input.sample(UI.keys,UI.input)
    UI.previousState = UI.state
    UI.state = Physics.step(UI.state,UI.input,dt,Track)
    UI.race = Race.step(UI.race,UI.previousState,UI.state,Track,Checkpoints,Laps)
    UI.laps = UI.race.laps
    UI.checkpoints = UI.laps.checkpoints
    return UI.race.status ~= "finished"
end

function UI.OnUpdate(elapsed)
    if not UI.active then return end
    if inCombat() then UI.InterruptCombat(); return end
    if GetCurrentKeyBoardFocus() then UI.Stop("Text input has focus"); return end
    if type(IsGameWindowFocused) == "function" and not IsGameWindowFocused() then
        UI.Stop("Game window lost focus"); return
    end
    local p = UI.performance
    if p and p.attempts >= Performance.LIMIT then p = nil end
    local begin = p and readPerformanceClock(UI.performanceReader)
    local completedLaps = UI.laps.completedLaps
    local steps = Loop.advance(UI.clock,elapsed,step)
    local afterSimulation = p and readPerformanceClock(UI.performanceReader)
    if UI.race.status == "finished" then
        UI.result = {status="finished",reason=UI.race.reason,tick=UI.state.tick,
            totalTicks=UI.race.totalTicks,completedLaps=UI.laps.completedLaps}
        UI.Stop(UI.result.reason)
    else
        render()
        UI.hudElapsed = UI.hudElapsed + steps * Physics.FIXED_DT
        if UI.hudElapsed >= 0.25 or UI.laps.completedLaps ~= completedLaps then
            UI.hudElapsed = 0
            refreshHud()
        end
    end
    if p then
        local finish = readPerformanceClock(UI.performanceReader)
        local attempts = p.attempts
        local ok = pcall(Performance.record,p,begin,afterSimulation,finish)
        if not ok then
            p.attempts = attempts + 1
            p.invalid = p.invalid + 1
        end
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
    if event == "PLAYER_REGEN_DISABLED" then UI.InterruptCombat(); return end
    if not UI.active then return end
    if event == "GLOBAL_MOUSE_DOWN" then
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
    report(("activeFrameSeconds=%.4f simulatedSeconds=%.4f callbackHz=%.2f"):format(
        c and c.elapsedSeconds or 0,c and c.steps*c.dt or 0,
        c and c.elapsedSeconds>0 and c.frames/c.elapsedSeconds or 0))
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
