-- Solo driving presentation/input adapter. Mocked tests do not establish client API safety.
local _, AK = ...
assert(type(AK) == "table", "addon namespace required")
local Track, Physics, Input, Loop = AK.Track, AK.Physics, AK.Input, AK.Loop
local Oval = Track
local Performance = AK.Performance
local Presentation = AK.Presentation
local Checkpoints = AK.Checkpoints
local Laps = AK.Laps
local Race = AK.Race
local UI = {
    active=false, keys=Input.new(), input={}, pendingPropagationRelease=false,
    objects={frames=0, textures=0, fontStrings=0}, stopReason="Not started",
    performanceEnabled=false,
    track=Track, trackId="test_oval",
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

local function text(parent, anchor, x, y, value, font)
    UI.objects.fontStrings = UI.objects.fontStrings + 1
    local label = parent:CreateFontString(nil, "OVERLAY", font or "GameFontNormal")
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
    local heldTier = 0
    if phase == "holding" then
        if UI.state.driftTicks >= Physics.DRIFT_TIER2_TICKS then heldTier = 2
        elseif UI.state.driftTicks >= Physics.DRIFT_TIER1_TICKS then heldTier = 1 end
    end
    local changed = phase ~= UI.meterPhase or heldTier ~= UI.meterHeldTier
    local stopped = not UI.active and UI.state.tick > 0
    if changed then
        UI.meterPhase = phase
        UI.meterHeldTier = heldTier
        if phase == "boost" then UI.meterFill:SetColorTexture(0.20,1.00,0.88,1)
        elseif phase == "tier2" or heldTier == 2 then
            UI.meterFill:SetColorTexture(1.00,0.35,0.78,1)
        elseif phase == "tier1" or heldTier == 1 then
            UI.meterFill:SetColorTexture(1.00,0.86,0.20,1)
        else UI.meterFill:SetColorTexture(0.35,0.65,1.00,1) end
        UI.meterTier1Label:SetText(phase == "boost" and "0.4 s" or "Tier 1")
        UI.meterTier2Label:SetText(phase == "boost" and "0.8 s" or "Tier 2")
    end
    if changed or stopped ~= UI.meterStopped then
        UI.meterStopped = stopped
        local caption = "DRIFT CHARGE"
        if phase == "boost" then caption = "BOOST REMAINING"
        elseif phase == "holding" then
            caption = heldTier > 0 and "CHARGE HELD | Steer or release Space to boost" or
                "CHARGE HELD | Hold Space + steer to resume"
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

local function bestLapText(laps)
    if laps.bestLapTicks == nil then return "Best: --" end
    return ("Best: %.2fs (lap %d)"):format(
        laps.bestLapTicks*Physics.FIXED_DT,laps.bestLapNumber)
end

local function refreshSummary()
    if not UI.summary then return end
    local race = UI.race
    if not race or race.status == "countdown" or race.status == "running"
        or UI.dismissedSummaryRace == race then
        UI.summary:Hide(); return
    end
    if UI.summaryRace ~= race then
        UI.summaryRace = race
        if race.status == "finished" then
            UI.summaryTitle:SetText("RUN COMPLETE")
            UI.summaryDetail:SetText(("3/3 laps | Total: %.2fs\nLast lap: %.2fs\n%s"):format(
                race.totalTicks*Physics.FIXED_DT,race.laps.lastLapTicks*Physics.FIXED_DT,
                bestLapText(race.laps)))
        else
            UI.summaryTitle:SetText(race.status == "interrupted" and
                "GAME INTERRUPTED BY COMBAT" or "RUN STOPPED")
            UI.summaryDetail:SetText(("Laps: %d/3 | Time: %.2fs\nCurrent lap: %.2fs\n%s"):format(
                race.laps.completedLaps,race.totalTicks*Physics.FIXED_DT,
                race.laps.currentLapTicks*Physics.FIXED_DT,bestLapText(race.laps)))
        end
        UI.summaryHint:SetText("Restart or close results to view the track")
    end
    UI.summary:Show()
end

function UI.DismissSummary()
    local race = UI.race
    if UI.active or not race or race.status == "countdown" or race.status == "running" then return end
    -- Dismiss presentation only. Retain the stopped race, pose, clock and HUD;
    -- repeated Stop/Close/reopen must not resurrect this same result panel.
    UI.dismissedSummaryRace = race
    if UI.summary then UI.summary:Hide() end
end

local function refreshCountdown()
    if not UI.countdownCue then return end
    local cue = UI.active and UI.race and Race.cue(UI.race) or nil
    if cue == UI.cueText then return end
    UI.cueText = cue
    if cue then
        UI.countdownCue:SetText(cue)
        UI.countdownCue:Show()
    else
        UI.countdownCue:Hide()
    end
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
        local caption = ("Laps: %d | Current: %.2fs | Last: %s | %s"):format(
            laps.completedLaps,laps.currentLapTicks*Physics.FIXED_DT,last,bestLapText(laps))
        if not UI.active and UI.state.tick > 0 then caption = "Last drive | " .. caption end
        UI.lapHud:SetText(caption)
    end
    if UI.driftHud then
        local state = UI.state
        local salt = UI.trackId == "mirage_raceway"
        local surface = state.surface == "grass" and (salt and "Rough salt" or "Grass") or
            (state.surface == "wall" and "Wall" or "Road")
        local feedback = "Drift: hold Space + turn at speed 90+ | Release Space to boost"
        if state.surface == "grass" then
            feedback = (salt and "Slowing on rough salt" or "Slowing on grass") ..
                " | Rejoin the road to drift"
        elseif state.surface == "wall" then
            feedback = "Steer away from the barrier and rejoin the road"
        elseif state.boostTicks > 0 then
            feedback = ("BOOST | %.2fs remaining"):format(state.boostTicks * Physics.FIXED_DT)
        elseif state.drifting then
            if (state.driftGraceTicks or 0) > 0 then
                feedback = "Correcting | Charge held briefly | Hold Space + steer to resume"
            elseif state.driftTier > 0 then
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
    if UI.kartButton and UI.kartButtonActive ~= UI.active then
        UI.kartButtonActive = UI.active
        if UI.active then UI.kartButton:Disable() else UI.kartButton:Enable() end
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
    if UI.status then UI.status:SetText(UI.stopReason .. " | Start a new run or choose a track") end
    if UI.startButton then UI.startButton:Enable() end
    if UI.stopButton then UI.stopButton:Disable() end
    if UI.trackButton then UI.trackButton:Enable() end
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
    if key == "ENTER" or key == "NUMPADENTER" then
        -- Deliberate chat entry releases capture before normal chat handling.
        if down then UI.Stop("Chat opened") end
        return
    end
    -- Unassigned keys are consumed without ending the run or clearing held
    -- controls. Active capture still prevents their normal WoW bindings.
    Input.set(UI.keys, key, down)
end

local function drawEllipse(canvas, radiusX, radiusY, rows, layer, r, g, b)
    -- Static raster bands of the same analytical ellipse used by collision.
    -- Midpoint sampling has at most half a band's vertical edge uncertainty.
    local height = 2 * radiusY / rows
    for row=0,rows-1 do
        local dy = -radiusY + (row + 0.5) * height
        local halfWidth = radiusX * math.sqrt(math.max(0,1-(dy/radiusY)^2))
        local piece = texture(canvas, layer)
        UI.ovalTextures[#UI.ovalTextures+1] = piece
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
    UI.ovalTextures = {}
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
    -- Two Test Oval collision fixtures, pooled once and driven by the same
    -- physical rectangles as the solver. Mirage has no solid props.
    UI.obstacleTextures = {}
    for index in ipairs(Oval.obstacles) do
        local piece = texture(canvas,"ARTWORK")
        piece:SetColorTexture(0.88,0.25,0.12,1)
        UI.obstacleTextures[index] = piece
    end
end

local function drawWalls(canvas)
    UI.wallTextures = {}
    -- Static perimeter markers; collision keeps the kart's center farther in.
    local thickness = 4
    local function strip(x,y,width,height)
        local piece = texture(canvas,"ARTWORK")
        UI.wallTextures[#UI.wallTextures+1] = piece
        piece:SetColorTexture(0.42,0.44,0.48,1)
        piece:SetSize(width,height)
        piece:SetPoint("BOTTOMLEFT",canvas,"BOTTOMLEFT",x,y)
    end
    strip(0,0,Track.width,thickness)
    strip(0,Track.height-thickness,Track.width,thickness)
    strip(0,thickness,thickness,Track.height-2*thickness)
    strip(Track.width-thickness,thickness,thickness,Track.height-2*thickness)
end

local function placeWorldRect(piece,x,y,width,height)
    local px,py,pw,ph = Presentation.clipRect(UI.view,x,y,width,height)
    if not px then piece:Hide(); return end
    piece:ClearAllPoints()
    piece:SetPoint("BOTTOMLEFT",UI.canvas,"BOTTOMLEFT",px,py)
    piece:SetSize(pw,ph)
    piece:Show()
end

local function placeTrackMarkers()
    for index,gate in ipairs(Track.gates) do
        local width = gate.ax == gate.bx and 5 or math.abs(gate.bx-gate.ax)
        local height = gate.ay == gate.by and 5 or math.abs(gate.by-gate.ay)
        placeWorldRect(UI.gateTextures[index],(gate.ax+gate.bx-width)/2,
            (gate.ay+gate.by-height)/2,width,height)
    end
    local thickness = 4
    placeWorldRect(UI.wallTextures[1],0,0,Track.width,thickness)
    placeWorldRect(UI.wallTextures[2],0,Track.height-thickness,Track.width,thickness)
    placeWorldRect(UI.wallTextures[3],0,thickness,thickness,Track.height-2*thickness)
    placeWorldRect(UI.wallTextures[4],Track.width-thickness,thickness,thickness,Track.height-2*thickness)
end

-- Drift/boost effects: pooled textures created once and hidden while idle.
-- Presentation owns the particles; UI only places, crops and tints them, and
-- never writes simulation state. Smoke sits above the track markers, sparks
-- just below the kart, and each exhaust flame (outer and inner layer) burns
-- just behind or just in front of the kart, as its pipe faces the camera.
local FLAME_FRONT, FLAME_BEHIND = 2, -4
local OVAL_DUST, MIRAGE_DUST = {0.86,0.86,0.84}, {0.95,0.90,0.81}

local function createEffects(canvas)
    local E = Presentation.EFFECTS
    UI.fx,UI.fxShown,UI.fxCells,UI.fxLayers = nil,{},{},{}
    local pools = {
        {count=E.smokeCount, layer="ARTWORK", sublevel=6, path=E.particlesPath},
        {count=E.sparkCount, layer="OVERLAY", sublevel=-2, path=E.particlesPath},
        {count=2*E.flameCount, layer="OVERLAY", sublevel=FLAME_FRONT, path=E.flamePath},
    }
    local ready = true
    for _,pool in ipairs(pools) do
        pool.list = {}
        for i = 1, pool.count do
            local piece = texture(canvas,pool.layer)
            pool.list[i] = piece
            -- Flames alternate outer/inner; an inner layer sits one sublevel up.
            local sublevel = pool.sublevel + ((pool.path == E.flamePath and i % 2 == 0) and 1 or 0)
            if type(piece.SetDrawLayer) ~= "function"
                or not pcall(piece.SetDrawLayer,piece,pool.layer,sublevel) then ready = false end
            UI.fxLayers[piece] = sublevel
            piece:Hide()
            UI.fxShown[piece] = false
        end
    end
    UI.fxSmoke,UI.fxSparks,UI.fxFlames = pools[1].list,pools[2].list,pools[3].list
    -- All or nothing: a refused load, crop or tint leaves every effect
    -- hidden; the kart and race are unaffected.
    for _,pool in ipairs(pools) do
        for _,piece in ipairs(pool.list) do
            if ready then
                if type(piece.SetTexture) ~= "function" or type(piece.SetTexCoord) ~= "function"
                    or type(piece.SetVertexColor) ~= "function" then ready = false
                else
                    local ok,loaded = pcall(piece.SetTexture,piece,pool.path)
                    ready = ok and loaded == true and pcall(piece.SetTexCoord,piece,0,1,0,1)
                        and pcall(piece.SetVertexColor,piece,1,1,1,0)
                end
            end
        end
    end
    if ready then UI.fx = Presentation.newEffects() end
end

local function hideEffect(piece)
    if UI.fxShown[piece] then
        piece:Hide()
        UI.fxShown[piece] = false
    end
end

-- A particle quad must fit the canvas whole; there is no clipping API.
local function placeEffect(piece, kind, cell, x, y, size, r, g, b, a)
    local view,half = UI.view,size/2
    if a <= 0 or x-half < 0 or y-half < 0 or x+half > view.canvasWidth or y+half > view.canvasHeight then
        hideEffect(piece)
        return
    end
    if UI.fxCells[piece] ~= cell then
        UI.fxCells[piece] = cell
        piece:SetTexCoord(Presentation.effectCoords(kind,cell))
    end
    piece:ClearAllPoints()
    piece:SetPoint("CENTER",UI.canvas,"BOTTOMLEFT",x,y)
    piece:SetSize(size,size)
    piece:SetVertexColor(r,g,b,a)
    if not UI.fxShown[piece] then
        piece:Show()
        UI.fxShown[piece] = true
    end
end

local function resetEffects()
    if UI.fx then Presentation.clearEffects(UI.fx) end
    for _,piece in ipairs(UI.fxSmoke) do hideEffect(piece) end
    for _,piece in ipairs(UI.fxSparks) do hideEffect(piece) end
    for _,piece in ipairs(UI.fxFlames) do hideEffect(piece) end
    UI.fxOptions = {
        anchors=UI.kartSprite and UI.kartSprite.effects or Presentation.DEFAULT_EFFECT_ANCHORS,
        dust=UI.trackId == "mirage_raceway" and MIRAGE_DUST or OVAL_DUST,
        boostFullTicks=Physics.BOOST_TIER2_TICKS,
    }
end

-- (kartX, kartY) is the drawn kart pose on the canvas.
local function renderEffects(kartX, kartY, alpha)
    local fx = UI.fx
    if not fx then return end
    local now = Presentation.advanceEffects(fx,UI.previousState,UI.state,alpha,UI.fxOptions)
    local view = UI.view
    local scale = view.scale
    for i,p in ipairs(fx.smoke) do
        local x,y,size,a = Presentation.particleAt(p,now)
        if x then
            x,y = Presentation.project(view,x,y)
            placeEffect(UI.fxSmoke[i],"smoke",p.cell,x,y,size*scale,p.r,p.g,p.b,a)
        else hideEffect(UI.fxSmoke[i]) end
    end
    for i,p in ipairs(fx.sparks) do
        local x,y,size,a = Presentation.particleAt(p,now)
        if x then
            x,y = Presentation.project(view,x,y)
            placeEffect(UI.fxSparks[i],"spark",p.cell,x,y,size*scale,p.r,p.g,p.b,a)
        else hideEffect(UI.fxSparks[i]) end
    end
    local E = Presentation.EFFECTS
    for i,flame in ipairs(fx.flames) do
        local outer,inner = UI.fxFlames[2*i-1],UI.fxFlames[2*i]
        if flame.on then
            local layer = flame.front and FLAME_FRONT or FLAME_BEHIND
            if UI.fxLayers[outer] ~= layer then
                outer:SetDrawLayer("OVERLAY",layer)
                inner:SetDrawLayer("OVERLAY",layer+1)
                UI.fxLayers[outer],UI.fxLayers[inner] = layer,layer+1
            end
            local x,y,size = kartX+flame.ox*scale,kartY+flame.oy*scale,flame.size*scale
            placeEffect(outer,"flame",flame.cell,x,y,size,
                E.flameOuter[1],E.flameOuter[2],E.flameOuter[3],flame.alpha)
            placeEffect(inner,"flame",flame.cell,x,y,size*E.flameInnerScale,
                E.flameInner[1],E.flameInner[2],E.flameInner[3],flame.alpha)
        else
            hideEffect(outer)
            hideEffect(inner)
        end
    end
end

-- A loaded sprite draws its padded quad (one frame of a directional sheet);
-- the primitive keeps its 17x31 body. Both share the view's scale.
local function sizeKart()
    local sprite = UI.kartSprite
    UI.kart:SetSize((sprite and sprite.quadWidth or Presentation.KART_FOOTPRINT_WIDTH)*UI.view.scale,
        (sprite and sprite.quadHeight or Presentation.KART_FOOTPRINT_HEIGHT)*UI.view.scale)
end

local function layoutTrack()
    local mirage = UI.trackId == "mirage_raceway"
    UI.view = mirage and Presentation.cameraViewport(Track.width,Track.height,800,480,1.5) or
        Presentation.fitViewport(Track.width,Track.height,800,480)
    UI.cameraCropReady = false
    for _,piece in ipairs(UI.ovalTextures) do
        if mirage then piece:Hide() else piece:Show() end
    end
    if mirage then UI.mirageBackground:Show() else UI.mirageBackground:Hide() end
    UI.grass:SetColorTexture(mirage and 0.12 or 0.08,mirage and 0.11 or 0.24,
        mirage and 0.09 or 0.12,1)
    UI.mirageBackground:ClearAllPoints()
    UI.mirageBackground:SetPoint("BOTTOMLEFT",UI.canvas,"BOTTOMLEFT",0,0)
    UI.mirageBackground:SetSize(800,480)
    placeTrackMarkers()
    for index,piece in ipairs(UI.obstacleTextures) do
        if mirage then piece:Hide()
        else
            local obstacle = Oval.obstacles[index]
            placeWorldRect(piece,obstacle.x,obstacle.y,obstacle.width,obstacle.height)
        end
    end
    sizeKart()
    UI.gatePassed,UI.gateStopped = nil,nil
    resetEffects()
end

-- Kart visual: one pooled Texture shows the chosen kart sprite, or the
-- original primitive when the guarded load fails. Loaded art is never tinted:
-- the drift/boost effects show the phase. Only the primitive keeps phase
-- colours (indices follow render: 0 normal, 1 charging, 2/3 tier ready,
-- 4 boost). SetColorTexture replaces a texture's image with a solid colour,
-- so only the primitive may use it.
local kartColors = {
    [0]={0.98,0.54,0.14}, {0.35,0.65,1.00}, {1.00,0.86,0.20}, {1.00,0.35,0.78}, {0.20,1.00,0.88},
}

-- Every application establishes the complete visual configuration. A failed
-- sheet load may already have cropped a previous single image (or vice versa),
-- so restoration must set UVs and orientation as well as the texture and tint.
local function applyKartSprite(sprite,frame,heading)
    local kart = UI.kart
    if not sprite or type(kart.SetTexture) ~= "function"
        or type(kart.SetVertexColor) ~= "function" or type(kart.SetTexCoord) ~= "function"
        or type(kart.SetRotation) ~= "function" then return false end
    local ok,loaded = pcall(kart.SetTexture,kart,sprite.path)
    if not ok or loaded ~= true then return false end
    if sprite.frames then
        if not pcall(kart.SetTexCoord,kart,Presentation.kartFrameCoords(sprite,frame or 0)) then return false end
    elseif not pcall(kart.SetTexCoord,kart,0,1,0,1) then return false end
    if not pcall(kart.SetRotation,kart,sprite.frames and 0 or (heading or math.pi/2)-math.pi/2) then return false end
    return (pcall(kart.SetVertexColor,kart,1,1,1,1))
end

local function usePrimitiveKart()
    UI.kartSprite,UI.kartFrame,UI.kartId,UI.kartTint = nil,nil,nil,nil
    local kart = UI.kart
    -- Solid colour is independent of a stale image crop. Best-effort resets
    -- also remove the old tint/orientation; a refused rotation remains disabled
    -- for this primitive rather than throwing again on every render.
    if type(kart.SetTexCoord) == "function" then pcall(kart.SetTexCoord,kart,0,1,0,1) end
    if type(kart.SetVertexColor) == "function" then pcall(kart.SetVertexColor,kart,1,1,1,1) end
    UI.kartRotationReady = type(kart.SetRotation) == "function" and pcall(kart.SetRotation,kart,0)
end

local function loadKartSprite()
    -- Once, at creation; a refusal keeps the primitive.
    local sprite = Presentation.KART_SPRITES[Presentation.DEFAULT_KART]
    UI.kartSprite,UI.kartFrame,UI.kartId = nil,nil,nil
    if applyKartSprite(sprite) then
        UI.kartFrame = sprite.frames and 0 or nil
        UI.kartSprite,UI.kartId = sprite,Presentation.DEFAULT_KART
        UI.kartTint,UI.kartRotationReady = 0,true
    else usePrimitiveKart() end
end

local function kartLabel()
    return "Kart: " .. (UI.kartSprite and UI.kartSprite.name or "Basic")
end

local function tintKart(tint)
    if UI.kartSprite then UI.kart:SetVertexColor(1,1,1,1); return end
    local color = kartColors[tint] or kartColors[0]
    UI.kart:SetColorTexture(color[1],color[2],color[3],1)
end

-- Cosmetic kart choice while stopped: the art loads with the same guarded
-- checks as at creation. A refusal restores the entire current visual, or
-- falls back to the primitive if that restoration also fails. It never
-- touches the run, its result, the track or the simulation state; every kart
-- drives the same 17x31 body. The choice is not saved.
function UI.SelectKart(id)
    local sprite = Presentation.KART_SPRITES[id]
    if not UI.kart or UI.active or not sprite then return false end
    if id == UI.kartId then return true end
    local previous,previousFrame = UI.kartSprite,UI.kartFrame
    local _,_,heading = Presentation.pose(UI.previousState,UI.state,1)
    local nextFrame = sprite.frames and Presentation.kartFrame(sprite,heading) or nil
    local selected = applyKartSprite(sprite,nextFrame,heading)
    if selected then
        UI.kartSprite,UI.kartId = sprite,id
        UI.kartFrame,UI.kartTint,UI.kartRotationReady = nextFrame,0,true
    elseif previous and applyKartSprite(previous,previousFrame,heading) then
        UI.kartFrame,UI.kartTint,UI.kartRotationReady = previousFrame,0,true
    else
        usePrimitiveKart()
    end
    sizeKart()
    resetEffects()
    render()
    if UI.kartButton then UI.kartButton:SetText(kartLabel()) end
    return selected
end

function UI.SelectTrack(id)
    if not UI.window or not UI.window:IsShown() or UI.active or inCombat() then return false end
    if id ~= "test_oval" and id ~= "mirage_raceway" then return false end
    if id == UI.trackId then return true end
    if id == "mirage_raceway" and type(UI.mirageBackground.SetTexCoord) ~= "function" then
        refuseStart("Mirage camera unavailable | Test Oval remains available")
        return false
    end
    if id == "mirage_raceway" and not UI.mirageTextureReady then
        -- The client documents a boolean load result. Missing/erroring/failed
        -- texture loads leave the old track and its stopped result untouched.
        local loader = UI.mirageBackground.SetTexture
        local ok,loaded = false,false
        if type(loader) == "function" then
            ok,loaded = pcall(loader,UI.mirageBackground,
                "Interface\\AddOns\\AzerothKart\\Assets\\Tracks\\SaltFlats\\Background.tga")
        end
        if not ok or loaded ~= true then
            refuseStart("Mirage background unavailable | Test Oval remains available")
            return false
        end
        UI.mirageTextureReady = true
    end
    if id == "mirage_raceway" then
        UI.mirageTrack = UI.mirageTrack or AK.MirageRaceway.new(Oval.crossesGate)
        if not UI.cameraApiReady then
            local probe = Presentation.cameraViewport(UI.mirageTrack.width,UI.mirageTrack.height,800,480,1.5)
            local spawn = UI.mirageTrack.spawn()
            Presentation.follow(probe,spawn.x,spawn.y,spawn.heading,60)
            local ok = pcall(UI.mirageBackground.SetTexCoord,UI.mirageBackground,
                Presentation.texCoords(probe))
            if not ok then
                refuseStart("Mirage camera unavailable | Test Oval remains available")
                return false
            end
            UI.cameraApiReady = true
        end
        Track = UI.mirageTrack
    else Track = Oval end
    UI.ReleaseInput()
    UI.track,UI.trackId = Track,id
    UI.state = Physics.new(Track)
    UI.laps = Laps.new(Track,Checkpoints,UI.state.tick)
    UI.checkpoints,UI.previousState = UI.laps.checkpoints,UI.state
    UI.race,UI.result,UI.clock,UI.performance,UI.summaryRace = nil,nil,nil,nil,nil
    UI.dismissedSummaryRace = nil
    UI.hudElapsed = 0
    UI.stopReason = "Track selected"
    UI.summary:Hide()
    UI.trackButton:SetText(id == "mirage_raceway" and "Track: Mirage Raceway" or "Track: Test Oval")
    layoutTrack()
    render()
    refreshHud()
    UI.status:SetText(id == "mirage_raceway" and
        "Mirage Raceway | Start for 3 laps | Off-road: rough salt" or
        "Test Oval | Start for 3 laps")
    return true
end

render = function()
    local alpha = UI.active and UI.clock and UI.clock.accumulator/UI.clock.dt or 1
    local x,y,heading = Presentation.pose(UI.previousState,UI.state,alpha)
    if UI.view.follow then
        local oldX,oldY = UI.view.offsetX,UI.view.offsetY
        Presentation.follow(UI.view,x,y,heading,60)
        if oldX ~= UI.view.offsetX or oldY ~= UI.view.offsetY or not UI.cameraCropReady then
            UI.mirageBackground:SetTexCoord(Presentation.texCoords(UI.view))
            placeTrackMarkers()
            UI.cameraCropReady = true
        end
    end
    x,y = Presentation.project(UI.view,x,y)
    UI.kart:ClearAllPoints()
    local sprite = UI.kartSprite
    if sprite and sprite.frames then
        -- Directional sheet: show the nearest pre-rendered heading, unrotated,
        -- and only touch its crop when the frame changes.
        local frame = Presentation.kartFrame(sprite,heading)
        if frame ~= UI.kartFrame then
            UI.kartFrame = frame
            UI.kart:SetTexCoord(Presentation.kartFrameCoords(sprite,frame))
        end
        local scale = UI.view.scale
        UI.kart:SetPoint("CENTER",UI.canvas,"BOTTOMLEFT",x + sprite.pivotX*scale,y + sprite.pivotY*scale)
    else
        UI.kart:SetPoint("CENTER",UI.canvas,"BOTTOMLEFT",x,y)
        if UI.kartRotationReady ~= false then
            UI.kartRotationReady = pcall(UI.kart.SetRotation,UI.kart,heading - math.pi/2)
        end
    end
    renderEffects(x,y,alpha)
    local state = UI.state
    local tint = UI.kartSprite and 0 or
        (state.boostTicks > 0 and 4 or (state.drifting and (1 + state.driftTier) or 0))
    if tint ~= UI.kartTint then
        UI.kartTint = tint
        tintKart(tint)
    end
    refreshMeter()
    refreshCheckpoints()
    refreshCountdown()
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
    UI.canvas:SetSize(800,480)
    UI.canvas:SetPoint("TOP",0,-58)
    local grass = texture(UI.canvas,"BACKGROUND")
    UI.grass = grass
    grass:SetAllPoints(UI.canvas)
    grass:SetColorTexture(0.08,0.24,0.12,1)
    -- Mixed snapping states can cover the road within one default sublayer.
    -- Keep the canvas backdrop explicitly below the outer road bands.
    grass:SetDrawLayer("BACKGROUND",-1)
    drawTrack(UI.canvas)
    drawWalls(UI.canvas)
    UI.mirageBackground = texture(UI.canvas,"BACKGROUND")
    UI.mirageBackground:Hide()
    UI.kart = texture(UI.canvas,"OVERLAY")
    loadKartSprite()
    createEffects(UI.canvas)
    layoutTrack()
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
    UI.trackButton = frame("Button",nil,window,"UIPanelButtonTemplate")
    UI.trackButton:SetSize(208,24)
    UI.trackButton:SetPoint("BOTTOMLEFT",280,12)
    UI.trackButton:SetText("Track: Test Oval")
    UI.trackButton:SetScript("OnClick",function()
        UI.SelectTrack(UI.trackId == "test_oval" and "mirage_raceway" or "test_oval")
    end)
    -- Cosmetic kart cycle; refused while a run is active (refreshHud keeps
    -- the button disabled then).
    UI.kartButton = frame("Button",nil,window,"UIPanelButtonTemplate")
    UI.kartButton:SetSize(212,24)
    UI.kartButton:SetPoint("BOTTOMLEFT",496,12)
    UI.kartButton:SetText(kartLabel())
    UI.kartButton:SetScript("OnClick",function() UI.SelectKart(Presentation.nextKart(UI.kartId)) end)
    UI.probeButton = frame("Button",nil,window,"UIPanelButtonTemplate")
    UI.probeButton:SetSize(112,24)
    UI.probeButton:SetPoint("BOTTOMRIGHT",-28,12)
    UI.probeButton:SetText("Print Probe")
    UI.probeButton:SetScript("OnClick",function() UI.ReportProbe() end)
    UI.summary = frame("Frame",nil,UI.canvas,"BackdropTemplate")
    UI.summary:SetSize(380,190)
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
    UI.dismissSummaryButton = frame("Button",nil,UI.summary,"UIPanelButtonTemplate")
    UI.dismissSummaryButton:SetSize(130,24)
    UI.dismissSummaryButton:SetPoint("BOTTOMRIGHT",-24,16)
    UI.dismissSummaryButton:SetText("Close results")
    UI.dismissSummaryButton:SetScript("OnClick",function() UI.DismissSummary() end)
    UI.summary:Hide()
    UI.countdownCue = text(UI.canvas,"CENTER",0,0,"",
        GameFontNormalHuge and "GameFontNormalHuge" or "GameFontNormal")
    UI.countdownCue:Hide()
    window:SetScript("OnUpdate",function(_,elapsed) UI.OnUpdate(elapsed) end)
end

function UI.Start()
    if not UI.window or not UI.window:IsShown() then return end
    if inCombat() then refuseStart("Cannot start while in combat"); return end
    if type(GetCurrentKeyBoardFocus) ~= "function"
        or type(UI.window.EnableKeyboard) ~= "function"
        or type(UI.window.SetPropagateKeyboardInput) ~= "function" then
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
    UI.dismissedSummaryRace = nil
    UI.summary:Hide()
    UI.stopReason = "Countdown"
    UI.window:SetPropagateKeyboardInput(false)
    UI.window:EnableKeyboard(true)
    UI.active = true
    render()
    refreshHud()
    UI.status:SetText("3 laps | Hold W/Up for GO | A/D or arrows: steer | Stop / Esc: end run")
    UI.startButton:Disable()
    UI.stopButton:Enable()
    UI.trackButton:Disable()
end

-- Reuse neutral input during prestart. The zero-speed spawn remains fixed,
-- while physics/probe ticks continue and the real held keys are still sampled.
local countdownInput = {}
local function step(dt)
    Input.sample(UI.keys,UI.input)
    UI.previousState = UI.state
    local countdown = UI.race.status == "countdown"
    UI.state = Physics.step(UI.state,countdown and countdownInput or UI.input,dt,Track)
    UI.race = Race.step(UI.race,UI.previousState,UI.state,Track,Checkpoints,Laps)
    UI.laps = UI.race.laps
    UI.checkpoints = UI.laps.checkpoints
    if countdown and UI.race.status == "running" then
        UI.stopReason = "Driving"
        UI.status:SetText("3 laps | W/A/S/D or arrows | Space + turn: drift | Stop / Esc: end run")
    end
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
    local raceStatus = UI.race.status
    local steps = Loop.advance(UI.clock,elapsed,step)
    local afterSimulation = p and readPerformanceClock(UI.performanceReader)
    if UI.race.status == "finished" then
        UI.result = {status="finished",reason=UI.race.reason,tick=UI.state.tick,
            totalTicks=UI.race.totalTicks,completedLaps=UI.laps.completedLaps}
        UI.Stop(UI.result.reason)
    else
        render()
        UI.hudElapsed = UI.hudElapsed + steps * Physics.FIXED_DT
        if UI.hudElapsed >= 0.25 or UI.laps.completedLaps ~= completedLaps
            or UI.race.status ~= raceStatus then
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
    if event == "PLAYER_LEAVING_WORLD" or event == "PLAYER_LOGOUT" then
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
    report(("UI frames=%d textures=%d fontStrings=%d active=%s stopReason=%s track=%s"):format(
        UI.objects.frames,UI.objects.textures,UI.objects.fontStrings,tostring(UI.active),UI.stopReason,UI.trackId))
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
