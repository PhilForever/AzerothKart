-- Solo driving presentation/input adapter. Mocked tests do not establish client API safety.
local _, AK = ...
assert(type(AK) == "table", "addon namespace required")
local Physics, Input, Loop = AK.Physics, AK.Input, AK.Loop
local GateGeometry = AK.Track
local Performance = AK.Performance
local Presentation = AK.Presentation
local Checkpoints = AK.Checkpoints
local Laps = AK.Laps
local Race = AK.Race
local Courses = AK.Courses
local defaultId = Courses.DEFAULT_ID
local Track = assert(Courses.build(defaultId,GateGeometry.crossesGate),"default course unavailable")
-- Gate strips are pooled for the course with the most gates; unused ones hide.
local GATE_POOL = 8
local UI = {
    active=false, keys=Input.new(), input={}, pendingPropagationRelease=false,
    objects={frames=0, textures=0, fontStrings=0}, stopReason="Not started",
    performanceEnabled=false,
    track=Track, trackId=defaultId,
}
AK.UI = UI
local render, pollLive, finishLive, applyLiveView
local function resetRemotePosition()
    UI.remoteX,UI.remoteY,UI.remoteOffsetX,UI.remoteOffsetY,UI.remotePositionAt=nil,nil,nil,nil,nil
    UI.remoteBlockedSince=nil
    UI.remoteDisplayLevel=nil
end
-- Only the validated Ready transaction may load a shared race's map while
-- multiplayer mode is retained. Public solo selectors cannot dissolve a room.
local liveTrackSelection
-- Captured at a successful solo Start, never derived from the current artwork.
local soloKartId

local function pendingNativeLive()
    local transport=AK.SessionTransport
    if not transport then return nil end
    local view=transport.GetView()
    if view.liveMode and view.transportBusy then return view end
end

local function livePending()
    return UI.multiplayer and UI.liveSession and AK.SessionTransport
        and AK.SessionTransport.GetView().transportBusy
end

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
        local boostSeconds = Physics.BOOST_TIER2_TICKS * Physics.FIXED_DT
        UI.meterTier1Label:SetText(phase == "boost" and ("%.2g s"):format(boostSeconds/2) or "Tier 1")
        UI.meterTier2Label:SetText(phase == "boost" and ("%.2g s"):format(boostSeconds) or "Tier 2")
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
            caption = UI.race.targetLaps == 1 and "Checkpoints: sprint complete" or "Checkpoints: 3-lap run complete"
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
    local results=UI.multiplayer and UI.multiplayerResults
    local resultsKey=""
    if results and type(results.rows)=="table" then
        resultsKey=tostring(results.session)..":"..tostring(results.complete)
        for index=1,2 do
            local row=results.rows[index]
            if type(row)=="table" then
                resultsKey=resultsKey..":"..tostring(row.name)..":"..tostring(row.status)
                    ..":"..tostring(row.totalTicks)..":"..tostring(row.rank)..":"..tostring(row.tie)
            end
        end
    end
    if UI.summaryRace ~= race or UI.summaryResultsKey~=resultsKey then
        UI.summaryRace = race
        UI.summaryResultsKey=resultsKey
        local sprint = race.targetLaps == 1
        if UI.multiplayer and results and type(results.rows)=="table" then
            UI.summaryTitle:SetText(results.complete and "LOCAL PLACEMENTS — UNVERIFIED" or
                (race.status=="finished" and "FINISHED — WAITING FOR FRIEND" or "MULTIPLAYER RESULTS"))
            local lines={}
            for index=1,2 do
                local row=results.rows[index]
                if type(row)=="table" then
                    local rank=row.rank and ((row.tie and "=" or "")..tostring(row.rank)) or "—"
                    local ticks=row.totalTicks
                    local time=type(ticks)=="number" and ticks==ticks and ticks>=0 and ticks<math.huge
                        and ("%.2fs"):format(ticks*Physics.FIXED_DT) or "--"
                    local status=row.status=="finished" and time or
                        (row.status=="stopped" and "Did not finish" or "Waiting for finish")
                    lines[#lines+1]=rank..". "..tostring(row.name or "Friend").." | "..status
                end
            end
            UI.summaryDetail:SetText(table.concat(lines,"\n"))
        elseif race.status == "finished" then
            UI.summaryTitle:SetText(UI.multiplayer and "LOCAL FINISH — UNVERIFIED" or "RUN COMPLETE")
            if sprint then
                UI.summaryDetail:SetText(("Sprint | Total: %.2fs\nAll %d gates"):format(
                    race.totalTicks*Physics.FIXED_DT,#Track.gates))
            else
                UI.summaryDetail:SetText(("3/3 laps | Total: %.2fs\nLast lap: %.2fs\n%s"):format(
                    race.totalTicks*Physics.FIXED_DT,race.laps.lastLapTicks*Physics.FIXED_DT,
                    bestLapText(race.laps)))
            end
        else
            UI.summaryTitle:SetText(race.status == "interrupted" and
                "GAME INTERRUPTED BY COMBAT" or "RUN STOPPED")
            if sprint then
                UI.summaryDetail:SetText(("Sprint | Time: %.2fs\nGates: %d/%d"):format(
                    race.totalTicks*Physics.FIXED_DT,race.laps.checkpoints.passed,#Track.gates))
            else
                UI.summaryDetail:SetText(("Laps: %d/3 | Time: %.2fs\nCurrent lap: %.2fs\n%s"):format(
                    race.laps.completedLaps,race.totalTicks*Physics.FIXED_DT,
                    race.laps.currentLapTicks*Physics.FIXED_DT,bestLapText(race.laps)))
            end
        end
        UI.summaryHint:SetText(UI.multiplayer and "Local observations | Unverified placements" or
            "Restart or close results to view the track")
    end
    if AK.Menu and type(AK.Menu.RefreshResults)=="function" then AK.Menu.RefreshResults() end
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
    local cue = UI.gridStaged and UI.gridView and UI.gridView.cue or
        (UI.active and UI.race and Race.cue(UI.race) or nil)
    if cue == UI.cueText then return end
    UI.cueText = cue
    if cue then
        UI.countdownCue:SetText(cue)
        UI.countdownCue:Show()
    else
        UI.countdownCue:Hide()
    end
    if AK.Menu then AK.Menu.OnCue(cue) end -- countdown sounds (presentation only)
end

local function refreshHud()
    if not UI.hud or not UI.state then return end
    if UI.gridStaged then
        UI.hud:SetText("Starting grid | Simulation and race clock begin at GO")
        UI.lapHud:SetText("Laps: 0 | Current: 0.00s")
        UI.checkpointHud:SetText("Hold W/Up for GO | Stop / Esc: leave")
        UI.driftHud:SetText("Both karts are staged | Waiting for the shared start")
        if AK.Menu then AK.Menu.Sync() end
        return
    end
    local c = UI.clock
    UI.hud:SetText(("Speed: %d | Ticks: %d | Dropped: %.3fs | Sample: %.1fs"):format(
        math.floor(math.abs(UI.state.speed)+0.5),UI.state.tick,
        c and c.droppedSeconds or 0,c and c.elapsedSeconds or 0))
    if UI.lapHud and UI.laps then
        local laps = UI.laps
        local last = laps.lastLapTicks and ("%.2fs"):format(laps.lastLapTicks*Physics.FIXED_DT) or "--"
        local caption = ("Laps: %d | Current: %.2fs | Last: %s | %s"):format(
            laps.completedLaps,laps.currentLapTicks*Physics.FIXED_DT,last,bestLapText(laps))
        if Track.laps == 1 then -- a sprint: one run, timed to the last gate
            caption = ("Sprint | Time: %.2fs | Last run: %s"):format(laps.currentLapTicks*Physics.FIXED_DT,last)
        end
        if not UI.active and UI.state.tick > 0 then caption = "Last drive | " .. caption end
        UI.lapHud:SetText(caption)
    end
    if UI.driftHud then
        local state = UI.state
        local course = Courses and Courses.get(UI.trackId)
        local rough = course and course.rough
        local surface = state.surface == "grass" and (rough and rough.label or "Grass") or
            (state.surface == "wall" and "Wall" or "Road")
        local feedback = "Drift: hold Space + turn at speed 90+ | Release Space to boost"
        if state.surface == "grass" then
            feedback = (rough and rough.feedback or "Slowing on grass") ..
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
    -- The front end follows Start/Stop/lap changes here (presentation only).
    if AK.Menu then AK.Menu.Sync() end
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
    local pending=pendingNativeLive()
    if UI.liveArmed or UI.liveActive or (UI.multiplayer and UI.liveSession) or pending then
        UI.liveSession=UI.liveSession or (pending and pending.session)
        UI.active,UI.liveArmed,UI.liveActive,UI.gridStaged = false,false,false,false
        UI.ReleaseInput() -- release before a paced Leave checks the local-drive guard
        local transport = AK.SessionTransport
        if transport then
            local hardReason = reason=="Game interrupted by combat" and "combat" or
                (reason=="PLAYER_LEAVING_WORLD" and "world_leave" or
                (reason=="PLAYER_LOGOUT" and "logout" or nil))
            if hardReason or inCombat() then
                UI.liveStopAccepted=transport.Stop(hardReason or "combat")
            else
                UI.liveStopAccepted=transport.Leave()
                if not UI.liveStopAccepted and transport.GetView().transportBusy then
                    transport.Stop("stopped")
                end
            end
            local view = transport.GetView()
            if view.live and applyLiveView then
                applyLiveView(view.live)
                UI.result={status=UI.race.status,reason=reason or "Stopped",tick=UI.state.tick,
                    totalTicks=UI.race.totalTicks,completedLaps=UI.laps.completedLaps,resultVerified=false}
            end
        end
    end
    UI.active = false
    UI.gridStaged,UI.gridView,UI.remotePath,UI.remotePathAt=false,nil,nil,nil
    UI.remotePathSample,UI.remotePathSequence=nil,nil
    UI.remoteHeading,UI.remoteHeadingAt=nil,nil
    -- Closing an already interrupted drive cannot replace its terminal reason.
    resetRemotePosition()
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
    if UI.status then UI.status:SetText(UI.stopReason .. (UI.multiplayer and
        " | Multiplayer ended | Return to lobby or Leave Multiplayer" or " | Start a new run or choose a track")) end
    if UI.startButton then UI.startButton:Enable() end
    if UI.stopButton then UI.stopButton:Disable() end
    if UI.trackButton then UI.trackButton:Enable() end
    if UI.multiplayer then
        UI.startButton:Disable()
        UI.restartButton:Disable()
        UI.trackButton:Disable()
        if UI.kartButton then UI.kartButton:Disable() end
    end
end

function UI.InterruptCombat()
    if not UI.active then
        if UI.liveArmed then UI.Stop("Game interrupted by combat") end
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
    if not UI.active and not UI.gridStaged then return end
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
    -- Pure geometry fixtures may supply an untextured course in offline
    -- tests. Shipped courses use scenery and allocate none of these bands.
    if Track == GateGeometry then
        drawEllipse(canvas,Track.outerX,Track.outerY,64,"BACKGROUND",0.26,0.25,0.23)
        drawEllipse(canvas,Track.innerX,Track.innerY,32,"BORDER",0.08,0.24,0.12)
    end
    UI.gateTextures = {}
    for index=1,GATE_POOL do
        local line = texture(canvas,"ARTWORK")
        line:SetColorTexture(0.55,0.58,0.62,0.65)
        local gate = Track.gates[index]
        if gate then
            line:SetSize(gate.ax == gate.bx and 5 or math.abs(gate.bx-gate.ax),
                gate.ay == gate.by and 5 or math.abs(gate.by-gate.ay))
            line:SetPoint("CENTER",canvas,"BOTTOMLEFT",(gate.ax+gate.bx)/2,(gate.ay+gate.by)/2)
        else line:Hide() end
        UI.gateTextures[index] = line
    end
    UI.obstacleTextures = {}
    if Track == GateGeometry then
        for index in ipairs(GateGeometry.obstacles) do
            local piece = texture(canvas,"ARTWORK")
            piece:SetColorTexture(0.88,0.25,0.12,1)
            UI.obstacleTextures[index] = piece
        end
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
    for index,piece in ipairs(UI.gateTextures) do
        local gate = Track.gates[index]
        if gate then
            local width = gate.ax == gate.bx and 5 or math.abs(gate.bx-gate.ax)
            local height = gate.ay == gate.by and 5 or math.abs(gate.by-gate.ay)
            placeWorldRect(piece,(gate.ax+gate.bx-width)/2,(gate.ay+gate.by-height)/2,width,height)
        else piece:Hide() end
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
-- Draw sublevels (OVERLAY) of a kart and its effects. Flat courses keep the
-- original set. A two-floor course's roofs sit at ROOF_SUBLEVEL: a kart on
-- the ground draws below them (`low`), on floor 1 or a ramp above (`high`),
-- each set in the same order (flames behind, sparks, kart, outline, flames
-- in front; an inner flame one sublevel over its outer). Dust and wind
-- puffs (`smoke`, a layer and sublevel) stay under every OVERLAY texture,
-- as created, except over the roofs, where they share the outer back
-- flame's sublevel.
local SMOKE_GROUND = {"ARTWORK", 6}
local KART_LAYERS = {
    flat={behind=FLAME_BEHIND, sparks=-2, kart=0, outline=1, front=FLAME_FRONT, smoke=SMOKE_GROUND},
    low={behind=-8, sparks=-6, kart=-5, outline=-4, front=-3, smoke=SMOKE_GROUND},
    high={behind=0, sparks=2, kart=3, outline=4, front=5, smoke={"OVERLAY", 0}},
}
local ROOF_SUBLEVEL, MAX_ROOFS = -1, 4

-- The player's kart and its effects to one set; the flames take theirs
-- each frame (renderEffects). Guarded: a refused call keeps the old layer.
local function setKartLayers(set)
    if UI.kartLayers == set then return end
    UI.kartLayers = set
    if UI.kart and type(UI.kart.SetDrawLayer) == "function" then
        pcall(UI.kart.SetDrawLayer,UI.kart,"OVERLAY",set.kart)
    end
    if UI.kartOutline and type(UI.kartOutline.SetDrawLayer) == "function" then
        pcall(UI.kartOutline.SetDrawLayer,UI.kartOutline,"OVERLAY",set.outline)
    end
    for _,piece in ipairs(UI.fxSparks or {}) do
        if UI.fxLayers[piece] ~= set.sparks and type(piece.SetDrawLayer) == "function"
            and pcall(piece.SetDrawLayer,piece,"OVERLAY",set.sparks) then
            UI.fxLayers[piece] = set.sparks
        end
    end
    for _,piece in ipairs(UI.fxSmoke or {}) do
        if UI.fxLayers[piece] ~= set.smoke and type(piece.SetDrawLayer) == "function"
            and pcall(piece.SetDrawLayer,piece,set.smoke[1],set.smoke[2]) then
            UI.fxLayers[piece] = set.smoke
        end
    end
end

local function createEffects(canvas)
    local E = Presentation.EFFECTS
    UI.fx,UI.fxShown,UI.fxCells,UI.fxLayers = nil,{},{},{}
    local pools = {
        {count=E.smokeCount, layer=SMOKE_GROUND[1], sublevel=SMOKE_GROUND[2], path=E.particlesPath},
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
    for _,piece in ipairs(UI.fxSmoke) do UI.fxLayers[piece] = SMOKE_GROUND end -- a layer and sublevel
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
        dust=(Courses and Courses.get(UI.trackId) or {}).dust or OVAL_DUST,
        boostFullTicks=Physics.BOOST_TIER2_TICKS,
    }
end

-- Settings switch: off clears and hides every effect; on resumes emission
-- from the next simulation tick. Simulation never reads this flag.
function UI.SetEffectsEnabled(enabled)
    enabled = enabled ~= false
    if enabled == not UI.effectsOff then return end
    UI.effectsOff = not enabled
    if UI.fxSmoke then resetEffects() end
end

-- (kartX, kartY) is the drawn kart pose on the canvas.
local function renderEffects(kartX, kartY, alpha)
    local fx = UI.fx
    if not fx or UI.effectsOff then return end
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
            local set = UI.kartLayers or KART_LAYERS.flat
            local layer = flame.front and set.front or set.behind
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
    if UI.kartOutline and sprite then -- the outline shares the kart's quad
        UI.kartOutline:SetSize(sprite.quadWidth*UI.view.scale,sprite.quadHeight*UI.view.scale)
    end
end

-- A two-floor course's roof picture, loaded into the pooled roof textures
-- once per picture: true when the course has none or it is loaded. Its
-- upper floor is drawn only there, so a refusal leaves the pool unready
-- (UI.roofsPath nil) and SelectTrack and Start refuse the course, as they
-- refuse a missing background.
local function loadRoofs(course)
    if not (course and course.roofs) then return true end
    if UI.roofsPath == course.roofs then return true end
    UI.roofsPath = nil
    local roofs = Courses.roofs and Courses.roofs(course.id)
    if not roofs or not UI.roofTextures or #roofs > #UI.roofTextures then return false end
    for index=1,#roofs do
        local piece = UI.roofTextures[index]
        if type(piece.SetTexture) ~= "function" or type(piece.SetTexCoord) ~= "function"
            or type(piece.SetAlpha) ~= "function" then return false end
        local ok,loaded = pcall(piece.SetTexture,piece,course.roofs)
        if not ok or loaded ~= true then return false end
    end
    UI.roofsPath = course.roofs
    return true
end

-- A two-floor course's roofs and guiding arrow; each roof texture keeps one
-- roof's box. Other courses hide them and keep the flat draw layers, the
-- friend's kart included.
local function layoutRoofs(course)
    UI.roofs,UI.roofCropX,UI.roofCropY = nil,nil,nil
    for index,piece in ipairs(UI.roofTextures or {}) do
        piece:Hide()
        UI.roofAlphas[index] = nil
    end
    if course and course.roofs and loadRoofs(course) then UI.roofs = Courses.roofs(course.id) end
    UI.guideReady,UI.guideFrame = false,nil
    if UI.guideArrow then
        UI.guideArrow:Hide()
        local arrow = UI.guideArrow
        if course and course.guideArrow and type(arrow.SetTexture) == "function"
            and type(arrow.SetTexCoord) == "function" then
            local ok,loaded = pcall(arrow.SetTexture,arrow,Presentation.GUIDE_ARROW.path)
            UI.guideReady = ok and loaded == true
        end
    end
    setKartLayers(Track.layered and KART_LAYERS.low or KART_LAYERS.flat)
    -- The friend's kart: a two-floor course sets its sublevel as it draws
    -- (renderOpponent); any other course has it back at 0, as created.
    if not Track.layered and UI.opponentSublevel ~= nil and UI.opponentSublevel ~= 0 and UI.opponent
        and type(UI.opponent.SetDrawLayer) == "function"
        and pcall(UI.opponent.SetDrawLayer,UI.opponent,"OVERLAY",0) then
        UI.opponentSublevel = 0
    end
end

-- SelectTrack's roof check, before anything of the course shows: refused,
-- the course is refused as for a missing background. The pool may hold a
-- part load: another current course lays its own roofs out again; this
-- course, already current, stays roofless until a retry loads them.
local function roofsLoaded(course)
    if loadRoofs(course) then return true end
    refuseStart(course.name .. " roofs unavailable | Choose another track; previous selection retained")
    local current = Courses.get(UI.trackId)
    layoutRoofs(current ~= course and current or nil)
    return false
end

-- Each roof over its box, cropped as the camera moves, at its opacity for
-- the player's kart (whole unless it is on the ground under the roof).
local function placeRoofs(wx, wy, high)
    local view = UI.view
    local moved = UI.roofCropX ~= view.offsetX or UI.roofCropY ~= view.offsetY
    for index,roof in ipairs(UI.roofs) do
        local piece = UI.roofTextures[index]
        if moved then
            local px,py,pw,ph,left,right,top,bottom = Presentation.roofCrop(view,roof)
            if px then
                piece:ClearAllPoints()
                piece:SetPoint("BOTTOMLEFT",UI.canvas,"BOTTOMLEFT",px,py)
                piece:SetSize(pw,ph)
                piece:SetTexCoord(left,right,top,bottom)
                piece:Show()
            else piece:Hide() end
        end
        local alpha = Presentation.roofAlpha(roof,wx,wy,high)
        if UI.roofAlphas[index] ~= alpha then
            UI.roofAlphas[index] = alpha
            piece:SetAlpha(alpha)
        end
    end
    UI.roofCropX,UI.roofCropY = view.offsetX,view.offsetY
end

-- The guiding arrow beside the player's kart, toward the lap's next gate,
-- while a run is on; hidden at the gate and wherever it would leave the canvas.
local function placeGuide(wx, wy)
    local arrow = UI.guideArrow
    local heading,distance
    if UI.active and not UI.gridStaged then heading,distance = Presentation.guideHeading(Track,UI.checkpoints,wx,wy) end
    local G = Presentation.GUIDE_ARROW
    if heading and distance > G.reach then
        local scale = UI.view.scale
        local ax,ay = Presentation.project(UI.view,wx+math.cos(heading)*G.reach,wy+math.sin(heading)*G.reach)
        local half = G.size*scale/2
        if ax-half >= 0 and ay-half >= 0 and ax+half <= 800 and ay+half <= 480 then
            local frame = Presentation.arrowFrame(heading)
            if frame ~= UI.guideFrame then
                UI.guideFrame = frame
                arrow:SetTexCoord(Presentation.arrowCoords(frame))
            end
            arrow:ClearAllPoints()
            arrow:SetPoint("CENTER",UI.canvas,"BOTTOMLEFT",ax,ay)
            arrow:SetSize(2*half,2*half)
            arrow:Show()
            return
        end
    end
    arrow:Hide()
end

local function layoutTrack()
    -- Shipped courses use the follow camera over their scenery picture.
    local course = Courses and Courses.get(UI.trackId)
    local follow = course ~= nil and course.background ~= nil
    UI.view = follow and Presentation.cameraViewport(Track.width,Track.height,800,480,1.5) or
        Presentation.fitViewport(Track.width,Track.height,800,480)
    UI.cameraCropReady = false
    for _,piece in ipairs(UI.ovalTextures) do
        if follow then piece:Hide() else piece:Show() end
    end
    if follow then UI.mirageBackground:Show() else UI.mirageBackground:Hide() end
    local ground = follow and course.ground or {0.08,0.24,0.12}
    UI.grass:SetColorTexture(ground[1],ground[2],ground[3],1)
    UI.mirageBackground:ClearAllPoints()
    UI.mirageBackground:SetPoint("BOTTOMLEFT",UI.canvas,"BOTTOMLEFT",0,0)
    UI.mirageBackground:SetSize(800,480)
    placeTrackMarkers()
    layoutRoofs(course)
    for index,piece in ipairs(UI.obstacleTextures) do
        if Track ~= GateGeometry then piece:Hide()
        else
            local obstacle = GateGeometry.obstacles[index]
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
local function applyKartSprite(sprite,frame,heading,target)
    local kart = target or UI.kart
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

-- The optional bright line round the player's own kart (Settings: "Outline
-- my kart"). Its sheet has the kart sheet's frames at half resolution and
-- loads with the same guards, once per kart while the setting is on; a
-- refused load hides the line and is not retried. It is drawn over the kart
-- (never covering it) with the kart's crop, quad and position, and tinted;
-- the kart itself stays untinted. Single images and the primitive have none.
local function applyKartOutline()
    local piece,sprite = UI.kartOutline,UI.kartSprite
    if not piece then return end
    local path = UI.outlineOn and sprite and sprite.frames and sprite.outline or nil
    if path ~= UI.outlinePath then
        UI.outlinePath,UI.outlineReady,UI.outlineFrame = path,false,nil
        if path and type(piece.SetTexture) == "function" and type(piece.SetTexCoord) == "function"
            and type(piece.SetVertexColor) == "function" then
            local ok,loaded = pcall(piece.SetTexture,piece,path)
            local color = Presentation.KART_OUTLINE.color
            UI.outlineReady = ok and loaded == true
                and pcall(piece.SetVertexColor,piece,color[1],color[2],color[3],1)
        end
    end
    if UI.outlineReady then piece:Show() else piece:Hide() end
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
    applyKartOutline()
end

local function kartLabel()
    return "Kart: " .. (UI.kartSprite and UI.kartSprite.name or "Basic")
end

local function tintKart(tint)
    if UI.kartSprite then UI.kart:SetVertexColor(1,1,1,1); return end
    local color = kartColors[tint] or kartColors[0]
    UI.kart:SetColorTexture(color[1],color[2],color[3],1)
end

-- Kart choice while stopped: the art loads with the same guarded
-- checks as at creation. A refusal restores the entire current visual, or
-- falls back to the primitive if that restoration also fails. It never
-- touches the run, its result, the track or the simulation state; every kart
-- shares the same 17x31 body. Handling is captured only on the next Start.
function UI.SelectKart(id)
    if UI.multiplayer then return false end
    local sprite = Presentation.KART_SPRITES[id]
    if not UI.kart or UI.active or UI.liveArmed or livePending() or pendingNativeLive() or not sprite then return false end
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
    applyKartOutline()
    sizeKart()
    resetEffects()
    render()
    if UI.kartButton then UI.kartButton:SetText(kartLabel()) end
    if AK.Menu then AK.Menu.OnKartChanged() end -- remember a deliberate choice
    return selected
end

-- Settings switch for the line round the player's own kart, in a run or
-- stopped. Presentation only: the simulation never reads it.
function UI.SetKartOutline(enabled)
    enabled = enabled == true
    if enabled == (UI.outlineOn == true) then return end
    UI.outlineOn = enabled
    if not UI.kartOutline or not UI.view then return end
    applyKartOutline()
    sizeKart()
    render()
end

function UI.SelectTrack(id)
    if not UI.window or not UI.window:IsShown() or UI.active or UI.liveArmed or inCombat()
        or ((UI.multiplayer or livePending()) and liveTrackSelection~=id) then return false end
    local course = Courses and Courses.get(id)
    if not course or course.soon then return false end
    local background = course.background
    if id == UI.trackId and (not background or UI.backgroundPath == background)
        and (not course.roofs or UI.roofsPath == course.roofs) then return true end
    local staging = UI.backgroundStaging
    local backgroundTarget = UI.backgroundPath == background and UI.mirageBackground or staging
    if background and type(backgroundTarget.SetTexCoord) ~= "function" then
        refuseStart(course.name .. " camera unavailable | Choose another track; previous selection retained")
        return false
    end
    local selected = Courses.build(id,GateGeometry.crossesGate)
    if not selected then return false end
    if background and UI.backgroundPath ~= background then
        -- Validate and load only the hidden staging texture. A failed load
        -- can destroy its old image; the currently displayed texture and UVs
        -- are never touched and need no fallible rollback.
        local probe = Presentation.cameraViewport(selected.width,selected.height,800,480,1.5)
        local spawn = selected.spawn()
        Presentation.follow(probe,spawn.x,spawn.y,spawn.heading,60)
        local ok = pcall(staging.SetTexCoord,staging,
            Presentation.texCoords(probe))
        if not ok then
            refuseStart(course.name .. " camera unavailable | Choose another track; previous selection retained")
            return false
        end
        local loader = staging.SetTexture
        local ok,loaded = false,false
        if type(loader) == "function" then
            ok,loaded = pcall(loader,staging,background)
        end
        if not ok or loaded ~= true then
            refuseStart(course.name .. " background unavailable | Choose another track; previous selection retained")
            return false
        end
        -- A two-floor course's roof picture is scenery too (its upper floor).
        if not roofsLoaded(course) then return false end
        UI.mirageBackground:Hide()
        UI.mirageBackground,UI.backgroundStaging = staging,UI.mirageBackground
        UI.backgroundPath = background
        UI.cameraApiReady = true
        UI.mirageTextureReady = id == "mirage_raceway"
    elseif not roofsLoaded(course) then return false end
    if id == UI.trackId then
        -- Loading the default's picture changes presentation only. Keep the
        -- already constructed pose and timing references on first open.
        layoutTrack()
        render()
        refreshHud()
        UI.status:SetText(course.status)
        return true
    end
    if id == "mirage_raceway" then UI.mirageTrack = selected end
    Track = selected
    UI.ReleaseInput()
    UI.track,UI.trackId = Track,id
    UI.state = Physics.new(Track)
    UI.laps = Laps.new(Track,Checkpoints,UI.state.tick)
    UI.checkpoints,UI.previousState = UI.laps.checkpoints,UI.state
    UI.race,UI.result,UI.clock,UI.performance,UI.summaryRace = nil,nil,nil,nil,nil
    if not liveTrackSelection then UI.multiplayer,UI.liveSession=false,nil end
    UI.liveView=nil
    UI.gridStaged,UI.gridView,UI.remotePath,UI.remotePathAt=false,nil,nil,nil
    UI.remotePathSample,UI.remotePathSequence=nil,nil
    UI.remoteHeading,UI.remoteHeadingAt=nil,nil
    UI.dismissedSummaryRace = nil
    resetRemotePosition()
    UI.hudElapsed = 0
    UI.stopReason = "Track selected"
    UI.summary:Hide()
    UI.trackButton:SetText("Track: " .. (course.short or course.name))
    layoutTrack()
    render()
    refreshHud()
    UI.status:SetText(course.status)
    return true
end

local function opponentSprite(id)
    id = type(id)=="string" and id or "basic"
    if UI.opponentAssetId==id then return UI.opponentSprite end
    UI.opponentAssetId,UI.opponentFrame,UI.opponentPhase=id,nil,nil
    local sprite = Presentation.KART_SPRITES[id]
    if sprite and applyKartSprite(sprite,0,nil,UI.opponent) then
        UI.opponentSprite,UI.opponentFrame=sprite,sprite.frames and 0 or nil
        UI.opponentRotationReady=true
    else
        UI.opponentSprite=nil
        -- One guarded attempt per profile change, never an image load each
        -- render. Missing or refused peer art keeps the cyan primitive.
        if type(UI.opponent.SetTexCoord)=="function" then pcall(UI.opponent.SetTexCoord,UI.opponent,0,1,0,1) end
        if type(UI.opponent.SetVertexColor)=="function" then pcall(UI.opponent.SetVertexColor,UI.opponent,1,1,1,1) end
        UI.opponentRotationReady=type(UI.opponent.SetRotation)=="function"
            and pcall(UI.opponent.SetRotation,UI.opponent,0)
        UI.opponent:SetColorTexture(0.18,0.85,1,1)
    end
    return UI.opponentSprite
end

local function renderOpponent()
    if not UI.opponent then return end
    local view = UI.liveView
    local grid = UI.gridStaged and UI.gridView
    local remote = grid and grid.peerPose or (view and view.remote)
    if not UI.multiplayer or not remote then
        UI.opponentLevel=nil
        UI.remoteHeading,UI.remoteHeadingAt=nil,nil
        resetRemotePosition()
        UI.opponentWorldX,UI.opponentWorldY=nil,nil
        UI.opponent:Hide()
        UI.opponentLabel:Hide()
        if UI.opponentTag then UI.opponentTag:Hide() end
        return
    end
    local wx,wy,heading,predicted
    local level=remote.level or 0
    UI.opponentLevel=level
    if grid then
        wx,wy,heading=remote.x,remote.y,remote.heading
        UI.remoteHeading,UI.remoteHeadingAt=nil,nil
        resetRemotePosition()
    else
        local now=view.elapsedMS
        local validTime=type(now)=="number" and now==now and now>=0 and now<math.huge
        if UI.remoteDisplayLevel~=nil and UI.remoteDisplayLevel~=level then resetRemotePosition() end
        local elapsed=validTime and UI.remotePositionAt and math.max(0,now-UI.remotePositionAt) or 0
        local correcting=validTime and view.phase=="running" and remote.status=="running"
            and not view.remoteStale
        local offsetX,offsetY=Presentation.remoteCorrection(UI.remoteOffsetX or 0,UI.remoteOffsetY or 0,elapsed)
        local oldPath,oldSample=UI.remotePath,UI.remotePathSample
        -- Geometry may make a smooth path to the revised estimate impossible.
        -- Do not replenish blocked correction debt forever, including across
        -- healthy packets: reseed the display after a bounded 600ms interval.
        if validTime and UI.remoteBlockedSince and now-UI.remoteBlockedSince>=600 then
            resetRemotePosition()
            offsetX,offsetY,oldPath=0,0,nil
        end
        local replaced=false
        -- Cache bounded collision-aware display prediction once per packet.
        -- Its age includes transit time; no extra received-interval delay.
        if UI.remotePathAt~=remote.receivedAtMS or UI.remotePathSample~=remote.sampleMS
            or UI.remotePathLevel~=level
            or UI.remotePathSequence~=view.remoteSequence or not UI.remotePath then
            replaced=true
            UI.remotePathAt=remote.receivedAtMS
            UI.remotePathLevel=level
            UI.remotePathSample,UI.remotePathSequence=remote.sampleMS,view.remoteSequence
            -- Transit time has already consumed part of the forecast. Cover
            -- one normal 500ms update interval plus 100ms jitter, bounded by
            -- the presentation cap. No extra packet or receive-time delay.
            local age=remote.sampleAgeMS or view.remoteAgeMS or 0
            if type(age)~="number" or age~=age or age<0 or age==math.huge then age=0 end
            UI.remotePath=Presentation.buildRemotePath(view.remotePrevious,remote,Track,age+600)
        end
        wx,wy,heading,predicted=Presentation.remotePose(UI.remotePath,remote.sampleAgeMS or view.remoteAgeMS or 0)
        if correcting and wx then
            if replaced and oldPath and UI.remotePositionAt and type(oldSample)=="number"
                and type(remote.sampleMS)=="number" then
                -- Continue the OLD trajectory at this same timestamp before
                -- rebasing. Anchoring last frame would freeze every packet.
                local age=(remote.sampleAgeMS or view.remoteAgeMS or 0)+remote.sampleMS-oldSample
                local oldX,oldY=Presentation.remotePose(oldPath,age)
                if oldX then offsetX,offsetY=oldX+offsetX-wx,oldY+offsetY-wy end
            end
            local targetX,targetY=wx+offsetX,wy+offsetY
            local blocked=false
            if UI.remoteX and (offsetX~=0 or offsetY~=0) and type(Track.resolveMovement)=="function" then
                local x,y,_,resolvedLevel=Track.resolveMovement(UI.remoteX,UI.remoteY,targetX,targetY,level)
                local dx,dy=targetX-UI.remoteX,targetY-UI.remoteY
                -- Invalid-observation recovery must not create a display warp.
                if type(x)=="number" and type(y)=="number" and x==x and y==y
                    and (not Track.layered or resolvedLevel==level)
                    and (x-UI.remoteX)^2+(y-UI.remoteY)^2<=dx*dx+dy*dy+1e-6 then
                    blocked=math.abs(x-targetX)>1e-6 or math.abs(y-targetY)>1e-6
                    targetX,targetY=x,y
                else targetX,targetY,blocked=UI.remoteX,UI.remoteY,true end
            end
            UI.remoteOffsetX,UI.remoteOffsetY=targetX-wx,targetY-wy
            UI.remoteBlockedSince=blocked and (UI.remoteBlockedSince or now) or nil
            wx,wy=targetX,targetY
            UI.remoteX,UI.remoteY,UI.remotePositionAt=wx,wy,now
            UI.remoteDisplayLevel=level
        else resetRemotePosition() end
        -- A new packet can revise the inferred yaw sharply. Reconcile only
        -- its displayed heading, leaving the transit-aware x/y path untouched.
        -- Use the copied controller clock, never the number of render calls.
        local elapsed=0
        if type(now)=="number" and now==now and now>=0 and now<math.huge then
            if UI.remoteHeadingAt and now>=UI.remoteHeadingAt then
                elapsed=now-UI.remoteHeadingAt
            end
            UI.remoteHeadingAt=math.max(UI.remoteHeadingAt or now,now)
        end
        heading=Presentation.remoteHeading(UI.remoteHeading,heading,elapsed)
        UI.remoteHeading=heading
    end
    if not wx then
        UI.opponentLevel=nil
        UI.opponentWorldX,UI.opponentWorldY=nil,nil
        UI.opponent:Hide(); UI.opponentLabel:Hide()
        if UI.opponentTag then UI.opponentTag:Hide() end
        return
    end
    -- Where the friend's kart is drawn: the HUD places the racers from it.
    UI.opponentWorldX,UI.opponentWorldY=wx,wy
    local x,y = Presentation.project(UI.view,wx,wy)
    local scale = UI.view.scale
    local sprite=opponentSprite((grid and grid.peerKartId) or (view and view.peerKartId) or
        (UI.gridView and UI.gridView.peerKartId))
    local px,py=sprite and sprite.pivotX or 0,sprite and sprite.pivotY or 0
    local width,height=sprite and sprite.quadWidth or 36,sprite and sprite.quadHeight or 36
    local cx,cy=x+px*scale,y+py*scale
    local visible = cx>=width*scale/2 and cx<=800-width*scale/2
        and cy>=height*scale/2 and cy<=480-height*scale/2
    if visible then
        UI.opponent:SetSize((sprite and sprite.quadWidth or 17)*scale,
            (sprite and sprite.quadHeight or 31)*scale)
        UI.opponent:ClearAllPoints()
        UI.opponent:SetPoint("CENTER",UI.canvas,"BOTTOMLEFT",cx,cy)
        if sprite and sprite.frames then
            local frame=Presentation.kartFrame(sprite,heading)
            -- A winged friend beats its wings on the race's copied clock, half
            -- a beat from the player's, and glides while their report says
            -- they boost. Grid, ended and stale reports use the rest pose:
            -- a last observed boost is not a current boost after contact ends.
            local phase=0
            if sprite.wings and not grid and view.phase=="running"
                and remote.status=="running" and not view.remoteStale
                and type(view.elapsedMS)=="number" then
                phase=Presentation.wingPhase(sprite,view.elapsedMS/1000+sprite.wings.beat/2,remote.boosting==true)
            end
            if frame~=UI.opponentFrame or phase~=(UI.opponentPhase or 0) then
                UI.opponentFrame,UI.opponentPhase=frame,phase
                UI.opponent:SetTexCoord(Presentation.kartFrameCoords(sprite,frame,phase))
            end
        elseif UI.opponentRotationReady then
            UI.opponentRotationReady = pcall(UI.opponent.SetRotation,UI.opponent,heading-math.pi/2)
        end
        if Track.layered then
            -- Under the roofs on the ground, over them on floor 1 or a ramp:
            -- a friend under a roof the player is not under is hidden by it.
            local sublevel = (Presentation.drawnHigh(Track,wx,wy,level) and KART_LAYERS.high or KART_LAYERS.low).kart
            if UI.opponentSublevel ~= sublevel and type(UI.opponent.SetDrawLayer) == "function"
                and pcall(UI.opponent.SetDrawLayer,UI.opponent,"OVERLAY",sublevel) then
                UI.opponentSublevel = sublevel
            end
        elseif UI.opponentSublevel ~= nil and UI.opponentSublevel ~= 0 and type(UI.opponent.SetDrawLayer) == "function"
            and pcall(UI.opponent.SetDrawLayer,UI.opponent,"OVERLAY",0) then
            UI.opponentSublevel = 0
        end
        UI.opponent:SetAlpha(view and view.remoteStale and 0.35 or 1)
        UI.opponent:Show()
    else UI.opponent:Hide() end
    local peer = (view and view.peer) or UI.gridPeer or "Friend"
    local label = peer .. (grid and " | starting grid" or
        (view.remoteStale and " | signal stale" or (predicted and " | estimated kart" or " | observed kart")))
    if not visible then
        local pose=grid and grid.localPose or UI.state
        local distance=math.sqrt((wx-pose.x)^2+(wy-pose.y)^2)
        local vertical=y>480 and "north" or (y<0 and "south" or "")
        local horizontal=x>800 and "east" or (x<0 and "west" or "")
        local direction=vertical..(vertical~="" and horizontal~="" and "-" or "")..horizontal
        if direction=="" then direction="at edge" end
        label=peer.." | off-screen "..direction..(" | %.0f units"):format(distance)
        if view and view.remoteStale then label=label.." | signal stale" end
    end
    if label~=UI.opponentCaption then
        UI.opponentCaption=label
        UI.opponentLabel:SetText(label)
    end
    UI.opponentLabel:Show()
    local tag=UI.opponentTag
    if tag then
        -- The name over the kart's drawn top; off screen, held inside the
        -- canvas edge toward the kart, with the distance to it.
        local tagX,tagY=cx,cy+height*scale/2+4
        local caption=peer
        if not visible then
            tagX=math.max(70,math.min(730,cx))
            tagY=math.max(8,math.min(456,cy))
            local pose=grid and grid.localPose or UI.state
            caption=("%s (%d away)"):format(peer,math.floor(math.sqrt((wx-pose.x)^2+(wy-pose.y)^2)+0.5))
        end
        if caption~=UI.opponentTagText then
            UI.opponentTagText=caption
            tag:SetText(caption)
        end
        tag:ClearAllPoints()
        tag:SetPoint("BOTTOM",UI.canvas,"BOTTOMLEFT",tagX,tagY)
        if type(tag.SetAlpha)=="function" then tag:SetAlpha(view and view.remoteStale and 0.45 or 1) end
        tag:Show()
    end
end

render = function()
    local alpha = UI.active and UI.clock and UI.clock.accumulator/UI.clock.dt or 1
    local gridPose=UI.gridStaged and UI.gridView and UI.gridView.localPose
    local x,y,heading
    if gridPose then x,y,heading=gridPose.x,gridPose.y,gridPose.heading
    else x,y,heading=Presentation.pose(UI.previousState,UI.state,alpha) end
    if UI.view.follow then
        local oldX,oldY = UI.view.offsetX,UI.view.offsetY
        Presentation.follow(UI.view,x,y,heading,60)
        if oldX ~= UI.view.offsetX or oldY ~= UI.view.offsetY or not UI.cameraCropReady then
            UI.mirageBackground:SetTexCoord(Presentation.texCoords(UI.view))
            placeTrackMarkers()
            UI.cameraCropReady = true
        end
    end
    if Track.layered then
        -- Two floors: the kart draws under the roofs on the ground, over them
        -- on floor 1 or a ramp; a roof fades while the kart is under it.
        local level = gridPose and gridPose.level or UI.state.level or 0
        local high = Presentation.drawnHigh(Track,x,y,level)
        setKartLayers(high and KART_LAYERS.high or KART_LAYERS.low)
        if UI.roofs then placeRoofs(x,y,high) end
    end
    if UI.guideReady then placeGuide(x,y) end
    x,y = Presentation.project(UI.view,x,y)
    UI.kart:ClearAllPoints()
    local sprite = UI.kartSprite
    if sprite and sprite.frames then
        -- Directional sheet: show the nearest pre-rendered heading, unrotated,
        -- and only touch its crop when the frame changes. A winged sheet beats
        -- its wings on the run's own clock and glides while boosting; with no
        -- run it shows its rest pose (phase 0, as a freshly applied sheet).
        local frame = Presentation.kartFrame(sprite,heading)
        local phase = 0
        if sprite.wings and UI.active then
            local state = UI.state
            phase = Presentation.wingPhase(sprite,(state.tick + alpha)*Physics.FIXED_DT,(state.boostTicks or 0) > 0)
        end
        if frame ~= UI.kartFrame or phase ~= (UI.kartPhase or 0) then
            UI.kartFrame,UI.kartPhase = frame,phase
            UI.kart:SetTexCoord(Presentation.kartFrameCoords(sprite,frame,phase))
        end
        local scale = UI.view.scale
        UI.kart:SetPoint("CENTER",UI.canvas,"BOTTOMLEFT",x + sprite.pivotX*scale,y + sprite.pivotY*scale)
        if UI.outlineReady then -- the player's line: the same frame, pose and place
            local line = UI.kartOutline
            if UI.outlineFrame ~= frame or UI.outlinePhase ~= phase then
                UI.outlineFrame,UI.outlinePhase = frame,phase
                line:SetTexCoord(Presentation.kartFrameCoords(sprite,frame,phase))
            end
            line:ClearAllPoints()
            line:SetPoint("CENTER",UI.canvas,"BOTTOMLEFT",x + sprite.pivotX*scale,y + sprite.pivotY*scale)
        end
    else
        UI.kart:SetPoint("CENTER",UI.canvas,"BOTTOMLEFT",x,y)
        if UI.kartRotationReady ~= false then
            UI.kartRotationReady = pcall(UI.kart.SetRotation,UI.kart,heading - math.pi/2)
        end
    end
    if not UI.gridStaged then renderEffects(x,y,alpha) end
    local state = UI.state
    local tint = (UI.gridStaged or UI.kartSprite) and 0 or
        (state.boostTicks > 0 and 4 or (state.drifting and (1 + state.driftTier) or 0))
    if tint ~= UI.kartTint then
        UI.kartTint = tint
        tintKart(tint)
    end
    renderOpponent()
    refreshMeter()
    refreshCheckpoints()
    refreshCountdown()
    if AK.Menu then AK.Menu.RefreshRaceHud() end
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
        if UI.active or UI.liveArmed or (UI.multiplayer and UI.liveSession) or pendingNativeLive() then
            UI.Stop("Window hidden") else UI.ReleaseInput() end
    end)
    -- Presentation only: the front end shows its main menu or the results.
    window:SetScript("OnShow",function()
        -- Background loading needs a shown window. Until this succeeds the
        -- real course remains selected, but Start cannot drive a blank map.
        if not UI.active and not UI.liveArmed then UI.SelectTrack(UI.trackId) end
        if AK.Menu then AK.Menu.OnWindowShown() end
    end)

    local close = frame("Button",nil,window,"UIPanelButtonTemplate")
    close:SetSize(72,24)
    close:SetPoint("TOPRIGHT",-18,-16) -- inside the dialog border
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
    UI.backgroundStaging = texture(UI.canvas,"BACKGROUND")
    UI.backgroundStaging:Hide()
    -- A two-floor course's roofs: pooled textures, one per roof box, cropped
    -- from its roof picture as the camera moves; hidden on other courses.
    UI.roofTextures,UI.roofAlphas = {},{}
    for index=1,MAX_ROOFS do
        local piece = texture(UI.canvas,"OVERLAY")
        if type(piece.SetDrawLayer) == "function" then
            pcall(piece.SetDrawLayer,piece,"OVERLAY",ROOF_SUBLEVEL)
        end
        piece:Hide()
        UI.roofTextures[index] = piece
    end
    UI.kart = texture(UI.canvas,"OVERLAY")
    -- The player's optional outline: just over the kart, under its front flames.
    UI.kartOutline = texture(UI.canvas,"OVERLAY")
    if type(UI.kartOutline.SetDrawLayer) == "function" then
        pcall(UI.kartOutline.SetDrawLayer,UI.kartOutline,"OVERLAY",1)
    end
    UI.kartOutline:Hide()
    UI.kartLayers = KART_LAYERS.flat -- as created: the kart at 0, its outline at 1
    loadKartSprite()
    UI.opponent = texture(UI.canvas,"OVERLAY")
    UI.opponent:SetColorTexture(0.18,0.85,1,1)
    UI.opponentRotationReady = type(UI.opponent.SetRotation)=="function"
        and pcall(UI.opponent.SetRotation,UI.opponent,0)
    UI.opponent:Hide()
    -- The guiding arrow (a course's `guideArrow`), over every kart and roof.
    UI.guideArrow = texture(UI.canvas,"OVERLAY")
    if type(UI.guideArrow.SetDrawLayer) == "function" then
        pcall(UI.guideArrow.SetDrawLayer,UI.guideArrow,"OVERLAY",7)
    end
    UI.guideArrow:Hide()
    UI.opponentLabel = text(UI.canvas,"BOTTOMLEFT",12,12,"")
    UI.opponentLabel:Hide()
    -- The friend's name tag: over their kart, or along the canvas edge toward it.
    UI.opponentTag = text(UI.canvas,"BOTTOM",0,0,"",
        _G.GameFontHighlightSmallOutline ~= nil and "GameFontHighlightSmallOutline" or "GameFontHighlightSmall")
    UI.opponentTag:Hide()
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
    UI.status = text(window,"BOTTOMLEFT",28,133,"Out of combat: Start Race")
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
    UI.startButton:SetText("Start Race")
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
    local initialCourse = Courses.get(UI.trackId)
    UI.trackButton:SetText("Track: " .. (initialCourse.short or initialCourse.name))
    UI.trackButton:SetScript("OnClick",function()
        -- The next course that loads; a refused one is skipped this click.
        local id = UI.trackId
        for _=1,#Courses.LIST do
            id = Courses.next(id)
            if id == UI.trackId or UI.SelectTrack(id) then break end
            if UI.active or inCombat() then break end
        end
    end)
    -- Kart cycle; refused while a run is active (refreshHud keeps
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
    UI.restartButton:SetScript("OnClick",function()
        if UI.multiplayer then
            UI.status:SetText("Return to the multiplayer lobby to play again")
        else UI.Start() end
    end)
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
    -- Menus, the header, the race HUD overlay and results styling (Menu.lua)
    -- arrange the objects above; their text and behaviour stay here. If the
    -- front end fails to build, the basic controls above keep working.
    if AK.Menu then
        local ok,err = pcall(AK.Menu.Create,UI)
        if not ok then AK.Menu.Disable(err) end
    end
end

local function captureEligibility()
    if not UI.window or not UI.window:IsShown() then return false,"window_hidden" end
    if inCombat() then return false,"combat" end
    if type(GetCurrentKeyBoardFocus)~="function"
        or type(UI.window.EnableKeyboard)~="function"
        or type(UI.window.SetPropagateKeyboardInput)~="function" then return false,"input_api" end
    if GetCurrentKeyBoardFocus() then return false,"text_focus" end
    if type(IsGameWindowFocused)=="function" and not IsGameWindowFocused() then return false,"focus_lost" end
    return true
end

function UI.MultiplayerAction(action,...)
    local transport = AK.SessionTransport
    if not transport then return false,"unavailable" end
    if action=="leave" then
        if UI.liveArmed or UI.liveActive or UI.multiplayer then
            UI.Stop("Stopped")
            UI.multiplayer,UI.liveSession,UI.liveView,UI.multiplayerResults=false,nil,nil,nil
            UI.DismissSummary()
            UI.startButton:Enable(); UI.restartButton:Enable(); UI.trackButton:Enable()
            if UI.kartButton then UI.kartButton:Enable(); UI.kartButtonActive=false end
            return true -- deliberate local exit, never a peer-delivery claim
        end
        return transport.Leave()
    end
    if UI.active then return false,"local_drive" end
    if not UI.window or not UI.window:IsShown() then return false,"window_hidden" end
    if inCombat() then return false,"combat" end
    local accepted,reason
    if action=="return_lobby" then
        local view=transport.GetView()
        if not UI.multiplayer or not view.room then return false,"invalid_phase" end
        return true
    elseif action=="rematch" then
        local view=transport.GetView()
        local id=(...) or (view.room and view.room.trackId)
        if not UI.multiplayer or not view.canRematch or not Courses.multiplayer(id)
            or type(transport.Rematch)~="function" then return false,"invalid_phase" end
        accepted,reason=transport.Rematch(id)
        if accepted then
            UI.liveArmed,UI.liveActive,UI.gridStaged=false,false,false
            UI.liveSession=nil
            UI.ReleaseInput()
        end
    elseif action=="host" then
        local peer,code,trackId=...
        accepted,reason=transport.HostLive(peer,code,trackId,UI.kartId or "basic")
    elseif action=="listen" then
        local peer,code=...
        accepted,reason=transport.ListenLive(peer,code,UI.kartId or "basic")
    elseif action=="join" then accepted,reason=transport.Join()
    elseif action=="ready" then
        local ready=...
        if type(ready)~="boolean" then return false,"ready" end
        if ready then
            local eligible,why=captureEligibility()
            if not eligible then return false,why end
            local view=transport.GetView()
            local id=view.offer and view.offer.trackId
            if not view.liveMode or not view.canSetReady then return false,"invalid_phase" end
            if not Courses.multiplayer(id) then return false,"track" end
            liveTrackSelection=id
            local loaded,selected=pcall(UI.SelectTrack,id)
            liveTrackSelection=nil
            if not loaded or not selected then return false,"track_unavailable" end
            local current=transport.GetView()
            if current.session~=view.session or not current.canSetReady then return false,"invalid_phase" end
        end
        accepted,reason=transport.Ready(ready)
        if accepted then
            UI.liveArmed=ready
            UI.liveSession=ready and transport.GetView().session or nil
        end
    elseif action=="start" then
        if not UI.liveArmed then return false,"not_armed" end
        accepted,reason=transport.PrepareStart()
    else return false,"action" end
    if accepted and (action=="host" or action=="listen") then
        UI.liveArmed,UI.liveActive,UI.liveSession=false,false,nil
        UI.multiplayer,UI.liveView,UI.multiplayerResults=false,nil,nil
        UI.gridStaged,UI.gridView,UI.remotePath,UI.remotePathAt=false,nil,nil,nil
        UI.remotePathSample,UI.remotePathSequence=nil,nil
        UI.remoteHeading,UI.remoteHeadingAt=nil,nil
        UI.opponentAssetId=nil
        resetRemotePosition()
    end
    return accepted,reason
end

applyLiveView = function(view)
    UI.liveView=view
    UI.state,UI.previousState=view.vehicle,view.previous
    UI.race,UI.clock=view.race,view.clock
    UI.laps=UI.race.laps
    UI.checkpoints=UI.laps.checkpoints
end

finishLive = function(reason)
    UI.active,UI.liveActive,UI.liveArmed,UI.gridStaged=false,false,false,false
    UI.ReleaseInput()
    UI.previousState=UI.state
    UI.stopReason=reason or "Experimental race ended"
    UI.result={status=UI.race.status,reason=UI.stopReason,tick=UI.state.tick,
        totalTicks=UI.race.totalTicks,completedLaps=UI.laps.completedLaps,resultVerified=false}
    if AK.SessionTransport then
        local view=AK.SessionTransport.GetView()
        UI.multiplayerResults=view.results or UI.multiplayerResults
    end
    render()
    refreshHud()
    refreshSummary()
    UI.status:SetText(UI.stopReason .. " | Experimental result, unverified")
    UI.startButton:Disable()
    UI.restartButton:Disable()
    UI.stopButton:Disable()
    UI.trackButton:Disable()
end

pollLive = function()
    if not UI.liveArmed and not UI.liveSession and not UI.multiplayer then return end
    local transport=AK.SessionTransport
    if not transport then return end
    local view=transport.GetView()
    if UI.multiplayer then UI.multiplayerResults=view.results or UI.multiplayerResults end
    local live=view.live
    local grid=view.grid
    if UI.gridStaged and view.phase=="closed" then UI.Stop("Start session ended"); return end
    if UI.liveArmed and view.session==UI.liveSession and grid and grid.ready and grid.staged
        and grid.localPose and grid.peerPose then
        local eligible,why=captureEligibility()
        if not eligible then
            if why=="combat" then UI.InterruptCombat() else UI.Stop("Live start unavailable") end
            return
        end
        UI.gridView,UI.gridPeer=grid,view.peer
        if not UI.gridStaged then
            UI.gridStaged,UI.multiplayer=true,true
            -- A deliberate fresh start replaces an ended display only now.
            -- This is a tick-zero presentation reset, not backend adoption or
            -- a pre-GO simulation step; the role poses remain separate.
            UI.state=Physics.new(Track)
            UI.previousState=UI.state
            UI.laps=Laps.new(Track,Checkpoints,0)
            UI.checkpoints=UI.laps.checkpoints
            UI.race,UI.clock=nil,nil
            UI.soloRun,UI.scoreResult=nil,nil
            UI.result,UI.summaryRace,UI.dismissedSummaryRace=nil,nil,nil
            UI.summary:Hide()
            resetEffects()
            UI.ReleaseInput()
            UI.window:SetPropagateKeyboardInput(false)
            UI.window:EnableKeyboard(true)
            UI.startButton:Disable(); UI.stopButton:Enable(); UI.trackButton:Disable(); UI.kartButton:Disable()
            UI.kartButtonActive=true
        end
        render()
        refreshHud()
        UI.status:SetText("Starting grid | Hold W/Up for GO | Stop / Esc: leave")
    end
    if live and live.session==UI.liveSession then
        if UI.liveArmed and view.phase=="racing" then
            local eligible=captureEligibility()
            if not eligible or live.trackId~=UI.trackId then UI.Stop("Live start unavailable"); return end
            applyLiveView(live)
            local staged=UI.gridStaged
            UI.multiplayer,UI.liveActive,UI.active,UI.liveArmed,UI.gridStaged=true,true,true,false,false
            UI.result,UI.summaryRace,UI.dismissedSummaryRace=nil,nil,nil
            UI.hudElapsed=0
            UI.performance=UI.performanceEnabled and Performance.new() or nil
            UI.summary:Hide()
            -- Staged controls stay held through GO. Capture is already owned;
            -- clearing it here would discard the player's held throttle.
            if not staged then
                UI.ReleaseInput()
                UI.window:SetPropagateKeyboardInput(false)
                UI.window:EnableKeyboard(true)
            end
            UI.stopReason="Experimental live race"
            UI.startButton:Disable()
            UI.stopButton:Enable()
            UI.trackButton:Disable()
            render()
            refreshHud()
            UI.status:SetText("Experimental two-player race | Stop / Esc: leave | No agreed standings")
        elseif UI.multiplayer then
            local changed=live.phase~=UI.liveView.phase
            -- Keep local frozen result identity while observing the friend.
            -- Closing transport must not replay results/fanfare.
            UI.liveView=live
            renderOpponent()
            if changed and live.phase=="closed" and UI.race.status~="finished" then
                applyLiveView(live)
                finishLive(live.reason)
            end
        elseif view.phase=="closed" then UI.liveArmed=false end
    elseif view.phase=="closed" then
        if UI.gridStaged then UI.Stop("Start session ended"); return end
        UI.liveArmed=false
    end
    if UI.multiplayer and not UI.active then
        UI.startButton:Disable(); UI.trackButton:Disable(); UI.kartButton:Disable()
        refreshSummary()
    end
    if not view.transportBusy and view.phase=="closed" then
        UI.liveArmed,UI.liveSession=false,nil
    end
end

function UI.Start()
    if UI.multiplayer then
        refuseStart("Return to the multiplayer lobby, or Leave Multiplayer first"); return
    end
    if not UI.window or not UI.window:IsShown() then return end
    if inCombat() then refuseStart("Cannot start while in combat"); return end
    local course = Courses.get(UI.trackId)
    if not course or course.soon or (course.background and
        (UI.backgroundPath ~= course.background or not UI.cameraApiReady))
        or (course.roofs and UI.roofsPath ~= course.roofs) then
        refuseStart("Track scenery unavailable; choose another track or reopen to retry"); return
    end
    if type(GetCurrentKeyBoardFocus) ~= "function"
        or type(UI.window.EnableKeyboard) ~= "function"
        or type(UI.window.SetPropagateKeyboardInput) ~= "function" then
        refuseStart("Input safety APIs unavailable; run /akart probe"); return
    end
    if GetCurrentKeyBoardFocus() then refuseStart("Close text input before starting"); return end
    local chosenKartId = UI.kartId or "basic"
    if not Physics.GetHandling(chosenKartId) then
        refuseStart("Kart handling unavailable; choose another kart"); return
    end
    if AK.SessionTransport then AK.SessionTransport.Stop("local_drive") end
    UI.ReleaseInput()
    UI.liveArmed,UI.liveActive,UI.liveSession,UI.multiplayer,UI.liveView=false,false,nil,false,nil
    UI.gridStaged,UI.gridView,UI.remotePath,UI.remotePathAt=false,nil,nil,nil
    UI.remotePathSample,UI.remotePathSequence=nil,nil
    UI.remoteHeading,UI.remoteHeadingAt=nil,nil
    soloKartId = chosenKartId
    resetRemotePosition()
    UI.state = Physics.new(Track)
    UI.race = Race.new(Track,Checkpoints,Laps,UI.state.tick)
    UI.soloRun = AK.SoloRecords.Begin(Track, chosenKartId)
    UI.scoreResult = nil
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
    UI.status:SetText((UI.race.targetLaps == 1 and "Sprint" or "3 laps")
        .. " | Hold W/Up for GO | A/D or arrows: steer | Stop / Esc: end run")
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
    UI.state = Physics.step(UI.state,countdown and countdownInput or UI.input,dt,Track,soloKartId)
    UI.race = Race.step(UI.race,UI.previousState,UI.state,Track,Checkpoints,Laps)
    UI.laps = UI.race.laps
    UI.checkpoints = UI.laps.checkpoints
    if countdown and UI.race.status == "running" then
        UI.stopReason = "Driving"
        UI.status:SetText((UI.race.targetLaps == 1 and "Sprint" or "3 laps")
            .. " | W/A/S/D or arrows | Space + turn: drift | Stop / Esc: end run")
    end
    return UI.race.status ~= "finished"
end

function UI.OnUpdate(elapsed)
    if not UI.active then pollLive(); return end
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
    local steps
    if UI.liveActive then
        Input.sample(UI.keys,UI.input)
        local live,reason=AK.SessionTransport.AdvanceLive(UI.input)
        if not live then UI.Stop(reason or "Live update failed"); return end
        local previousTick=UI.state.tick
        applyLiveView(live)
        steps=UI.state.tick-previousTick
        if live.phase~="running" then finishLive(live.reason or "Local finish — waiting for friend"); return end
    else
        local droppedBefore = UI.clock.droppedSeconds
        steps = Loop.advance(UI.clock,elapsed,step)
        -- Post-finish remainder is deliberately discarded by Loop and is not
        -- racing time. Only lost ticks while still running invalidate a score.
        if UI.soloRun and UI.race.status == "running"
            and UI.clock.droppedSeconds - droppedBefore > Physics.FIXED_DT * 0.5 then
            UI.soloRun.timingLost = true
        end
    end
    local afterSimulation = p and readPerformanceClock(UI.performanceReader)
    if UI.race.status == "finished" then
        UI.active = false -- prevent native-hook reentry from advancing a finished kart
        local ok, score = pcall(AK.SoloRecords.Finish, UI.soloRun, UI.race,
            UI.multiplayer or UI.liveActive or UI.liveSession or UI.gridStaged)
        UI.scoreResult = ok and score or {message="Score unavailable; run finished normally"}
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
    if not UI.active and not UI.liveArmed then return end
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
