-- Explicit two-peer control bridge. No registration, output or UI on load.
-- Legacy START is a proposal. Coordinated mode yields a backend race bundle;
-- it never opens a canvas, captures input or drives the simulation itself.
local _, AK = ...
assert(type(AK)=="table", "addon namespace required")
local Session, Protocol = assert(AK.PeerSession), assert(AK.RaceProtocol)
local Clock, ClockProtocol, RaceStart = AK.StartClock, AK.ClockProtocol, AK.RaceStart
local Live, LiveProtocol = AK.LiveRace, AK.LiveProtocol
local Grid=AK.RaceGrid
local Transport = {ROUTE="WHISPER_LOGGED"}
AK.SessionTransport = Transport

local frame, control, lastView, lastError, lastNow, busy, drainDeadline
local coordinated, clockState, raceGate, trackSet, lastClock
local liveMode, liveRun, lastLive
local liveKartId,liveGrid,gridInfo
local registered, sendAPI, sendSuccess, failedCodes, throttleCodes = {}
local used, usedCount, attempts, lastAttempt = {}, 0, {}, nil
local traffic = {attempts=0, accepted=0, failed=0, unknown=0, throttled=0,
    payloadBytes=0, prefixBytes=0, windowCalls=0, windowBytes=0}
local sendNames = {"Success", "InvalidPrefix", "InvalidMessage", "AddonMessageThrottle",
    "InvalidChatType", "NotInGroup", "TargetRequired", "InvalidChannel", "ChannelThrottle",
    "GeneralError", "NotInGuild", "AddOnMessageLockdown", "TargetOffline"}
local stopReasons = {combat=true, world_leave=true, logout=true, local_drive=true,
    error=true, clock_error=true, chat_lock=true, lease_lost=true,
    capabilities=true, prefix_registration=true, event_registration=true,
    update_registration=true, controller_error=true, send_error=true,
    send_failed=true, send_unknown=true, send_throttled=true, stopped=true, focus_lost=true}

local function copy(value)
    if type(value)~="table" then return value end
    local result = {}
    for key, item in pairs(value) do result[key]=copy(item) end
    return result
end
local function owns() return frame and frame.akNetworkOwner==Transport end
local function release()
    if not owns() then return end
    -- Core alone owns OnEvent. The lease covers this callback and event.
    pcall(frame.SetScript, frame, "OnUpdate", nil)
    pcall(frame.UnregisterEvent, frame, "CHAT_MSG_ADDON_LOGGED")
    frame.akNetworkOwner = nil
end
local function closeView(reason)
    local view = control and Session.view(control) or copy(lastView) or {phase="idle"}
    view.phase, view.reason, view.deadline = "closed", reason, nil
    view.pendingKind, view.pendingAttempts, view.hasPendingOutput = nil, 0, false
    view.canInvite, view.canJoin, view.canSetReady, view.canStart, view.canLeave = false,false,false,false,false
    lastView = view
end
local function hardStop(reason)
    reason = stopReasons[reason] and reason or "error"
    if control then closeView(reason) end
    if clockState then
        Clock.cancel(clockState,math.floor((lastNow or 0)*1000),"error")
        lastClock=Clock.view(clockState)
    end
    if raceGate then RaceStart.cancel(raceGate) end
    if liveGrid then Grid.stop(liveGrid,math.floor((lastNow or 0)*1000),"stopped"); liveGrid=nil end
    if liveRun then
        pcall(Live.stop,liveRun,math.floor((lastNow or 0)*1000),reason=="clock_error" and "clock" or reason)
        lastLive=Live.view(liveRun)
        liveRun=nil
    end
    clockState, raceGate, trackSet = nil,nil,nil
    control, drainDeadline = nil, nil
    lastError = reason
    release()
    return false, reason
end
local function prune(now)
    while attempts[1] and now-attempts[1].at>=1 do table.remove(attempts,1) end
    local bytes = 0
    for _, attempt in ipairs(attempts) do bytes=bytes+attempt.bytes end
    traffic.windowCalls, traffic.windowBytes = #attempts, bytes
end
local function readClock()
    if type(GetTime)~="function" then return nil end
    local ok, now = pcall(function()
        local value = GetTime()
        if type(value)=="number" and value==value and value>=0 and value<math.huge
            and (not lastNow or value>=lastNow) then return value end
    end)
    if ok and now then lastNow=now; prune(now); return now end
end
local function blocked()
    local ok, reason = pcall(function()
        if AK.UI and AK.UI.active and not (liveMode and (liveRun or (lastLive and control))
            and AK.UI.liveActive==true) then
            return "local_drive"
        end
        if type(InCombatLockdown)~="function" or InCombatLockdown()~=false then return "combat" end
        if type(C_ChatInfo)=="table" and type(C_ChatInfo.InChatMessagingLockdown)=="function"
            and C_ChatInfo.InChatMessagingLockdown()~=false then return "chat_lock" end
    end)
    if not ok then return "error" end
    return reason
end
local function checked()
    if not owns() then return nil, "lease_lost" end
    local reason = blocked()
    if reason then return nil, reason end
    local now = readClock()
    if not now then return nil, "clock_error" end
    return now
end
local function finish(now)
    if not control then return end
    local view = Session.view(control)
    if view.phase~="closed" then return end
    if clockState then
        Clock.cancel(clockState,math.floor(now*1000),"left")
        lastClock=Clock.view(clockState)
        clockState=nil
    end
    if raceGate then RaceStart.cancel(raceGate); raceGate=nil end
    if liveGrid then Grid.stop(liveGrid,math.floor(now*1000),"stopped"); liveGrid=nil end
    if liveRun then
        local snapshot=Live.view(liveRun)
        if snapshot.phase~="closed" then Live.stop(liveRun,math.floor(now*1000),"stopped") end
        lastLive=Live.view(liveRun)
        liveRun=nil
    end
    if view.hasPendingOutput then
        drainDeadline = drainDeadline or now+2
        if now<drainDeadline then return end
        view.hasPendingOutput=false
    end
    lastView, control, drainDeadline, trackSet = view, nil, nil, nil
    release()
end
local function readyToSend(now, bytes)
    return (not lastAttempt or now-lastAttempt>=0.5)
        and #attempts<2 and traffic.windowBytes+bytes<=158
end

local function capabilities(wantClock,wantLive)
    if not owns() or type(C_ChatInfo)~="table"
        or type(C_ChatInfo.RegisterAddonMessagePrefix)~="function"
        or type(C_ChatInfo.SendAddonMessageLogged)~="function" or type(Enum)~="table"
        or type(Enum.RegisterAddonMessagePrefixResult)~="table"
        or type(Enum.SendAddonMessageResult)~="table" then return false,"capabilities" end
    local register, results = Enum.RegisterAddonMessagePrefixResult, Enum.SendAddonMessageResult
    local function code(value)
        return type(value)=="number" and value==value and value>=0 and value<=32 and value%1==0
    end
    if not code(register.Success) or not code(register.DuplicatePrefix)
        or register.Success==register.DuplicatePrefix then return false,"capabilities" end
    local seen, failed, throttled = {}, {}, {}
    for _, name in ipairs(sendNames) do
        local value = results[name]
        if not code(value) or seen[value] then return false,"capabilities" end
        seen[value]=true
        if name~="Success" then failed[value]=true end
    end
    throttled[results.AddonMessageThrottle], throttled[results.ChannelThrottle]=true,true
    sendAPI, sendSuccess = C_ChatInfo.SendAddonMessageLogged, results.Success
    failedCodes, throttleCodes = failed, throttled
    local prefixes={Protocol.PREFIX}
    if wantClock then prefixes[2]=ClockProtocol.PREFIX end
    if wantLive then prefixes[3]=LiveProtocol.PREFIX end
    if wantLive then prefixes[4]=Grid.PREFIX end
    for _, prefix in ipairs(prefixes) do
        if not registered[prefix] then
            local raw = C_ChatInfo.RegisterAddonMessagePrefix(prefix)
            if raw~=register.Success and raw~=register.DuplicatePrefix then return false,"prefix_registration" end
            if not owns() then return false,"lease_lost" end
            registered[prefix]=true
        end
    end
    return true
end
local function classify(raw)
    if type(raw)~="number" or raw~=raw or raw==math.huge or raw==-math.huge then return "unknown" end
    if raw==sendSuccess then return "accepted" end
    if throttleCodes[raw] then return "throttled" end
    if failedCodes[raw] then return "failed" end
    return "unknown"
end
local function nativeSend(expected, payload, peer, prefix, stampMS)
    if control~=expected then return "failed" end
    local now, reason = checked()
    if not now then hardStop(reason); return "failed" end
    if control~=expected or not owns() then return "failed" end
    prefix=prefix or Protocol.PREFIX
    local clockPacket=coordinated and prefix==ClockProtocol.PREFIX
    local livePacket=liveMode and liveRun and prefix==LiveProtocol.PREFIX
    local gridPacket=liveMode and liveGrid and prefix==Grid.PREFIX
    local cap=clockPacket and ClockProtocol.MAX_BYTES or (livePacket and LiveProtocol.MAX_BYTES
        or (gridPacket and Grid.MAX_BYTES or 23))
    if (prefix~=Protocol.PREFIX and not clockPacket and not livePacket and not gridPacket) or type(payload)~="string"
        or #payload>cap or not readyToSend(now,#payload+#prefix) then
        hardStop("error"); return "failed"
    end
    -- PING/PONG stamps are formed at the paced update, never at enqueue time.
    -- Refuse a stalled native boundary instead of hiding its timestamp error.
    if clockPacket and (not stampMS or math.floor(now*1000)-stampMS>2) then
        hardStop("clock_error"); return "failed"
    end
    -- Charge every attempted native call, including throws/unknown results.
    lastAttempt=now
    attempts[#attempts+1]={at=now,bytes=#payload+#prefix}
    traffic.attempts=traffic.attempts+1
    traffic.payloadBytes=traffic.payloadBytes+#payload
    traffic.prefixBytes=traffic.prefixBytes+#prefix
    prune(now)
    local sendingFrame=frame
    sendingFrame.akNetworkSending=Transport
    local ok, outcome = pcall(function()
        return classify(sendAPI(prefix,payload,"WHISPER",peer))
    end)
    if sendingFrame.akNetworkSending==Transport then sendingFrame.akNetworkSending=nil end
    if not ok then
        traffic.failed=traffic.failed+1
        if control==expected then hardStop("send_error") end
        return "failed"
    end
    traffic[outcome]=traffic[outcome]+1
    return outcome
end

function Transport.Init(coreFrame)
    if busy or control or owns() then return false,"busy" end
    local ok, valid = pcall(function()
        local kind=type(coreFrame)
        return (kind=="table" or kind=="userdata") and type(coreFrame.RegisterEvent)=="function"
            and type(coreFrame.UnregisterEvent)=="function" and type(coreFrame.SetScript)=="function"
    end)
    if not ok or not valid then return false,"invalid_frame" end
    frame=coreFrame
    return true
end
function Transport.IsActive() return control~=nil end
function Transport.Stop(reason)
    -- Stop is intentionally allowed during a send callback; a new arm is not.
    local active = control~=nil
    if active or owns() then hardStop(reason) end
    return active
end

local function arm(role, peer, code, trackId, wantClock, wantLive, kartId)
    if busy or control or not frame or frame.akNetworkOwner or frame.akNetworkSending then
        return false,"busy"
    end
    busy=true
    local function fail(reason)
        lastError=reason
        release()
        busy=false
        return false,reason
    end
    -- Validate and construct geometry metadata without touching UI.track.
    if wantClock and (type(Clock)~="table" or type(ClockProtocol)~="table"
        or type(RaceStart)~="table" or type(AK.Race)~="table") then return fail("invalid_options") end
    if wantLive and (type(Live)~="table" or type(LiveProtocol)~="table" or type(AK.Loop)~="table"
        or type(Grid)~="table") then
        return fail("invalid_options")
    end
    kartId=kartId or "goblin_mortar_trike"
    if wantLive and not Grid.encode({kind="PROFILE",session=code,kartId=kartId}) then return fail("invalid_options") end
    local tracks
    local ok, candidate = pcall(function()
        local mirage = AK.MirageRaceway.new(AK.Track.crossesGate)
        tracks=wantClock and {test_oval=copy(AK.Track),mirage_raceway=copy(mirage)} or nil
        return {role=role,peer=peer,session=code,physicsVersion=AK.Physics.VERSION,
            trackVersions={test_oval=AK.Track.version,mirage_raceway=mirage.version},laps=3}
    end)
    if not ok then return fail("invalid_options") end
    -- A dummy explicit clock validates options before reserving native hooks.
    local state = Session.new(candidate,0,Protocol)
    if not state then return fail("invalid_options") end
    if role=="host" and (type(trackId)~="string" or not candidate.trackVersions[trackId]) then
        return fail("invalid_argument")
    end
    if used[code] then return fail("reused_session") end
    if usedCount>=64 then return fail("session_limit") end
    frame.akNetworkOwner=Transport
    local now, reason = checked()
    if not now then return fail(reason) end
    state = Session.new(candidate,now,Protocol)
    if role=="host" then
        local invited, why = Session.invite(state,now,trackId)
        if not invited then return fail(why) end
    end
    local apiOK, capable, why = pcall(capabilities,wantClock,wantLive)
    if not apiOK or not capable then return fail(apiOK and why or "capabilities") end
    if not owns() then return fail("lease_lost") end
    -- Native hook callbacks can call Stop. Keep the candidate private until all
    -- hooks succeed and verify that the lease was not revoked reentrantly.
    local eventOK, eventResult = pcall(frame.RegisterEvent,frame,"CHAT_MSG_ADDON_LOGGED")
    if not eventOK or eventResult==false or not owns() then return fail("event_registration") end
    local updateOK = pcall(frame.SetScript,frame,"OnUpdate",Transport.Update)
    if not updateOK or not owns() then return fail("update_registration") end
    control, lastView, lastError, drainDeadline = state, nil, nil, nil
    coordinated, clockState, raceGate, lastClock, trackSet = wantClock==true,nil,nil,nil,tracks
    liveMode,liveRun,lastLive=wantLive==true,nil,nil
    liveKartId,liveGrid,gridInfo=kartId,nil,nil
    used[code], usedCount=true,usedCount+1
    busy=false
    return true
end
function Transport.Host(peer,code,trackId) return arm("host",peer,code,trackId) end
function Transport.Listen(peer,code) return arm("guest",peer,code) end
function Transport.HostCoordinated(peer,code,trackId) return arm("host",peer,code,trackId,true) end
function Transport.ListenCoordinated(peer,code) return arm("guest",peer,code,nil,true) end
function Transport.HostLive(peer,code,trackId,kartId) return arm("host",peer,code,trackId,true,true,kartId) end
function Transport.ListenLive(peer,code,kartId) return arm("guest",peer,code,nil,true,true,kartId) end

local function action(method,...)
    if busy then return false,"busy" end
    if not control then return false,"inactive" end
    busy=true
    local now, reason = checked()
    if not now then hardStop(reason); busy=false; return false,reason end
    local expected=control
    local ok, accepted, why = pcall(method,expected,now,...)
    if not ok then hardStop("controller_error"); busy=false; return false,"controller_error" end
    if control==expected then finish(now) end
    if not accepted then lastError=why end
    busy=false
    return accepted==true,why
end
function Transport.Join() return action(Session.join) end
function Transport.Ready(ready)
    if liveMode and ready==true and (not liveGrid or Grid.view(liveGrid).phase~="ready") then return false,"grid_pending" end
    return action(Session.setReady,ready)
end
function Transport.Start(startTick,seed)
    if coordinated and control then return false,"coordinated_start_required" end
    return action(Session.start,startTick,seed)
end
function Transport.PrepareStart(seed)
    if not coordinated then return false,"coordinated_mode_required" end
    if liveMode and (not liveGrid or Grid.view(liveGrid).phase~="ready") then return false,"grid_pending" end
    -- Seed is backend metadata until a seeded subsystem exists; no UI setting.
    if seed==nil then seed=0 end
    return action(Session.start,AK.Race.COUNTDOWN_TICKS,seed)
end
function Transport.Leave()
    if liveRun then
        -- Freeze first. The existing control cancellation then drains through
        -- the same owner and persistent native gate; no extra sender exists.
        Live.stop(liveRun,math.floor((lastNow or 0)*1000),"stopped")
        lastLive=Live.view(liveRun)
    end
    return action(Session.cancel,"left",true)
end

local function ensureGrid(now,expected)
    if not liveMode or liveRun or control~=expected then return false end
    local view=Session.view(expected)
    if view.phase~="lobby" and view.phase~="starting" and view.phase~="coordinating" then return false end
    if not liveGrid then
        local track=view.offer and trackSet and trackSet[view.offer.trackId]
        local localPose,peerPose
        if track then localPose,peerPose=Grid.pose(track,view.role) end
        if control~=expected or not owns() then return false end
        if not localPose or not peerPose then hardStop("controller_error"); return false end
        local candidate=Grid.new({session=view.session,role=view.role,kartId=liveKartId},math.floor(now*1000))
        if control~=expected or not owns() then
            if candidate then Grid.stop(candidate,math.floor(now*1000),"stopped") end
            return false
        end
        if not candidate then hardStop("controller_error"); return false end
        liveGrid=candidate
        gridInfo={localPose=localPose,peerPose=peerPose,localKartId=liveKartId,ready=false}
    end
    return true
end

local function gridFailure(now)
    if not liveGrid or not control then return end
    local view=Grid.view(liveGrid)
    if view.phase=="closed" then
        lastError="grid_"..(view.reason or "error")
        if view.reason and view.reason:match("^send_") then hardStop(view.reason); return end
        Session.cancel(control,now,"error",true)
        finish(now)
    else
        gridInfo.peerKartId,gridInfo.ready=view.peerKartId,view.phase=="ready"
    end
end

local function handoff(now)
    if not coordinated or not control or clockState then return end
    local view=Session.view(control)
    if view.phase~="starting" then return end
    local proposal=Session.handoffStart(control,now)
    if not proposal then return end -- Host still waits for the control ACK.
    if proposal.startTick~=AK.Race.COUNTDOWN_TICKS or not view.offer or view.offer.laps~=3
        or not trackSet[view.offer.trackId]
        or trackSet[view.offer.trackId].version~=view.offer.trackVersion then
        hardStop("controller_error"); return
    end
    if liveMode and (not gridInfo or not gridInfo.ready) then hardStop("controller_error"); return end
    clockState=Clock.new({role=view.role,session=view.session,seed=proposal.seed,countdownMS=liveMode and 3000 or 0},
        math.floor(now*1000),ClockProtocol)
    if not clockState then hardStop("clock_error") end
end

local function clockFailure(now)
    if not control or not clockState then return end
    local view=Clock.view(clockState)
    if view.phase=="closed" then
        lastClock=copy(view)
        lastError="clock_"..(view.reason or "error")
        -- Best effort control CANCEL uses the very same paced budget. No race
        -- ticket survives a failed or ambiguous local clock negotiation.
        Session.cancel(control,now,"error",true)
        finish(now)
    end
end

local function initializeRace(now,expected,view)
    local ms=math.floor(now*1000)
    local ticket,why=Clock.takeTicket(clockState,ms)
    clockFailure(now)
    if not ticket or control~=expected then return nil,why end
    local track=view.offer and trackSet[view.offer.trackId]
    if liveMode then
        if not gridInfo or not gridInfo.ready then return nil,"grid" end
        track=copy(track)
        local pose=copy(gridInfo.localPose)
        track.spawn=function() return copy(pose) end
    end
    raceGate,why=RaceStart.new(ticket,track,view.offer.physicsVersion)
    if not raceGate then return nil,why end
    return RaceStart.take(raceGate,ms,AK.Physics,AK.Race,AK.Checkpoints,AK.Laps)
end

local function adoptLive(now,expected)
    if not liveMode or liveRun or not clockState or control~=expected then return end
    local view=Session.view(expected)
    local bundle,why=initializeRace(now,expected,view)
    if not bundle then
        if raceGate or (clockState and Clock.view(clockState).phase=="launched") then hardStop("controller_error") end
        return false,why
    end
    -- No lease/hook transition here. Initializer reentry may revoke ownership.
    if control~=expected or not owns() then return false,"closed" end
    local token=Live.new(bundle,view.peer,math.floor(now*1000),{
        Physics=AK.Physics,Race=AK.Race,Checkpoints=AK.Checkpoints,Laps=AK.Laps,
        Loop=AK.Loop,LiveProtocol=LiveProtocol})
    if not token then hardStop("controller_error"); return false,"controller_error" end
    if control~=expected or not owns() then Live.stop(token,math.floor(now*1000),"stopped"); return false,"closed" end
    if not Session.beginRace(expected,now) then
        Live.stop(token,math.floor(now*1000),"stopped"); hardStop("controller_error"); return false,"controller_error"
    end
    liveRun,lastLive=token,nil
    lastClock=Clock.view(clockState)
    clockState,raceGate,trackSet=nil,nil,nil
    return true
end

local function finishLive(now)
    if not liveRun or not control then return end
    local snapshot=Live.view(liveRun)
    if snapshot.phase=="closed" then
        lastLive=snapshot
        if snapshot.reason and snapshot.reason:match("^send_") then
            hardStop(snapshot.reason); return
        end
        if snapshot.reason=="clock" then hardStop("clock_error"); return end
        -- Completed poses are already repeated three times. Other local exits
        -- receive at most the existing one-shot paced control cancellation.
        Session.cancel(control,now,snapshot.reason=="peer_timeout" and "timeout" or "left",
            snapshot.reason~="completed_unverified")
        finish(now)
    end
end

function Transport.Update()
    if busy then return false,"busy" end
    if not control then return false,"inactive" end
    busy=true
    local now, reason = checked()
    if not now then hardStop(reason); busy=false; return false,reason end
    local expected=control
    if liveRun then
        local token=liveRun
        local ok,sent,why=pcall(Live.update,token,math.floor(now*1000),function(payload,peer,prefix)
            return nativeSend(expected,payload,peer,prefix)
        end,readyToSend(now,LiveProtocol.MAX_BYTES+#LiveProtocol.PREFIX))
        if not ok then hardStop("controller_error"); busy=false; return false,"controller_error" end
        if liveRun==token and control==expected and (sent or why~="paced") then finishLive(lastNow) end
        busy=false
        return sent==true,why
    end
    -- Reserve enough budget for the largest control message; no queued output
    -- is consumed while pacing blocks a send. Timeouts still advance.
    local ok, sent, why = pcall(Session.update,expected,now,
        function(payload,peer) return nativeSend(expected,payload,peer) end,
        readyToSend(now,23+#Protocol.PREFIX))
    if not ok then hardStop("controller_error"); busy=false; return false,"controller_error" end
    now=lastNow -- Includes validated reentrant receive/native preflight clocks.
    if control==expected then
        local view=Session.view(expected)
        if view.phase=="closed" and view.reason and view.reason:match("^send_") then lastError=view.reason end
        finish(now)
    end
    if control==expected and coordinated then
        -- A native callback may deliver a scoped reply at a later GetTime.
        -- Reconcile that clock before another controller advance or stamp.
        now,reason=checked()
        if not now then hardStop(reason); busy=false; return false,reason end
    end
    if control==expected and liveMode then
        local gridOK,gridSent=pcall(function()
            if not ensureGrid(now,expected) then return false end
            local token=liveGrid
            local attempted=Grid.update(token,math.floor(now*1000),function(payload)
                return nativeSend(expected,payload,Session.view(expected).peer,Grid.PREFIX)
            end,not sent and readyToSend(now,Grid.MAX_BYTES+#Grid.PREFIX))
            if liveGrid==token and control==expected then gridFailure(lastNow) end
            return attempted
        end)
        if not gridOK then hardStop("controller_error"); busy=false; return false,"controller_error" end
        sent=sent or gridSent
        if control==expected then
            -- A scoped receive can advance GetTime during the profile native
            -- send callback. Do not feed its earlier stamp into the clock FSM.
            now,reason=checked()
            if not now then hardStop(reason); busy=false; return false,reason end
        end
    end
    if control==expected then
        local handed, err=pcall(handoff,now)
        if not handed then hardStop("controller_error"); busy=false; return false,"controller_error" end
        if control==expected and clockState then
            local ms=math.floor(now*1000)
            local clockOK, clockSent = pcall(Clock.update,clockState,ms,
                function(payload)
                    return nativeSend(expected,payload,Session.view(expected).peer,ClockProtocol.PREFIX,ms)
                end, not sent and readyToSend(now,ClockProtocol.MAX_BYTES+#ClockProtocol.PREFIX))
            if not clockOK then hardStop("controller_error"); busy=false; return false,"controller_error" end
            sent=sent or clockSent
            clockFailure(lastNow)
            if liveMode and control==expected and clockState then
                local adopted=pcall(adoptLive,lastNow,expected)
                if not adopted then hardStop("controller_error"); busy=false; return false,"controller_error" end
            end
        end
    end
    busy=false
    return sent==true,why
end
function Transport.Message(prefix,payload,channel,nativeSender)
    if liveMode and not liveRun and control and prefix==Grid.PREFIX then
        local now,reason=checked()
        if not now then return hardStop(reason) end
        local expected=control
        local view=Session.view(expected)
        local function key(v)
            if type(v)~="string" or #v>96 or v:find("[%z\001-\031\127|]") then return nil end
            return (v:gsub(" +"," "):match("^ *(.-) *$"):gsub("[A-Z]",function(c) return string.char(c:byte()+32) end))
        end
        if channel~="WHISPER" or key(nativeSender)~=key(view.peer) then return false,"unrelated" end
        local ok,accepted,why=pcall(function()
            if not ensureGrid(now,expected) then return false,"phase" end
            return Grid.receive(liveGrid,math.floor(now*1000),payload)
        end)
        if not ok then return hardStop("controller_error") end
        if control==expected then gridFailure(now) end
        return accepted==true,why
    end
    if liveRun and control then
        local now,reason=checked()
        if not now then return hardStop(reason) end
        local token=liveRun
        if prefix==LiveProtocol.PREFIX then
            local ok,accepted,why=pcall(Live.receive,token,math.floor(now*1000),prefix,payload,channel,nativeSender)
            if not ok then return hardStop("controller_error") end
            if liveRun==token then finishLive(lastNow) end
            return accepted==true,why
        elseif prefix==Protocol.PREFIX then
            -- Only a scoped control CANCEL applies after GO. Old READY/START
            -- retries cannot reopen the race or advance the dormant controller.
            local message=Protocol.decode(payload)
            if message and message.kind=="CANCEL" then
                local ok,accepted,why=pcall(Session.receive,control,now,prefix,payload,channel,nativeSender)
                if not ok then return hardStop("controller_error") end
                if control and Session.view(control).phase=="closed" then
                    Live.stop(token,math.floor(now*1000),accepted and "peer_stopped" or "error")
                    -- CANCEL is already best-effort/one-shot. Validate its
                    -- sequence through the controller, then retire its unused
                    -- ACK with the lease rather than adding a new notice loop.
                    hardStop(accepted and "stopped" or "controller_error")
                end
                return accepted==true,why
            end
        end
        return false,"unrelated"
    end
    local clockPacket=coordinated and ClockProtocol and prefix==ClockProtocol.PREFIX
    if not control or (prefix~=Protocol.PREFIX and not clockPacket) then return false,"unrelated" end
    -- Message may run reentrantly during the native call to defer a matching
    -- ACK; it never invokes Update or sends from the event stack.
    local now, reason = checked()
    if not now then return hardStop(reason) end
    local expected=control
    if clockPacket then
        local view=Session.view(expected)
        local function key(value)
            if type(value)~="string" or #value>96 or value:find("[%z\001-\031\127|]") then return nil end
            return (value:gsub(" +"," "):match("^ *(.-) *$"):gsub("[A-Z]",function(c)
                return string.char(c:byte()+32)
            end))
        end
        if not clockState or channel~="WHISPER" or key(nativeSender)~=key(view.peer) then
            return false,"unrelated"
        end
        local ok,accepted,why=pcall(Clock.receive,clockState,math.floor(now*1000),payload)
        if not ok then return hardStop("controller_error") end
        if control==expected then clockFailure(now) end
        return accepted==true,why
    end
    local ok, accepted, why = pcall(Session.receive,expected,now,prefix,payload,channel,nativeSender)
    if not ok then return hardStop("controller_error") end
    if control==expected then
        finish(now)
        if control==expected then
            local handed=pcall(handoff,now)
            if not handed then return hardStop("controller_error") end
        end
    end
    return accepted==true,why
end
function Transport.HandleEvent(event)
    if event=="PLAYER_REGEN_DISABLED" then return Transport.Stop("combat") end
    if event=="PLAYER_LEAVING_WORLD" then return Transport.Stop("world_leave") end
    if event=="PLAYER_LOGOUT" then return Transport.Stop("logout") end
end
function Transport.GetView()
    local view = control and Session.view(control) or copy(lastView)
        or {phase="idle",canJoin=false,canSetReady=false,canStart=false,canLeave=false,hasPendingOutput=false}
    local free=not busy and not control and usedCount<64 and frame~=nil
        and frame.akNetworkOwner==nil and frame.akNetworkSending==nil
    view.canHost, view.canListen = free, free
    view.transportBusy = busy==true or (frame~=nil and (frame.akNetworkOwner~=nil
        or frame.akNetworkSending~=nil)) or control~=nil
    view.route, view.lastError, view.traffic = Transport.ROUTE,lastError,copy(traffic)
    view.coordinated=coordinated==true
    view.clock=clockState and Clock.view(clockState) or copy(lastClock)
    view.canPrepareStart=coordinated==true and view.canStart==true
    if coordinated then view.canStart=false end
    view.liveMode=liveMode==true
    view.live=liveRun and Live.view(liveRun) or copy(lastLive)
    if liveMode and gridInfo then
        view.grid=copy(gridInfo)
        view.grid.staged=control~=nil and not view.live and gridInfo.ready and
            (view.phase=="starting" or view.phase=="coordinating") or false
        view.grid.cue="GET READY"
        local clock=view.clock
        if clock and clock.phase=="armed" and clock.localEpochMS then
            local remaining=clock.localEpochMS-math.floor((lastNow or 0)*1000)
            view.grid.remainingMS=math.max(0,remaining)
            view.grid.localEpochMS=clock.localEpochMS
            if remaining>0 and remaining<=3000 then view.grid.cue=tostring(math.ceil(remaining/1000)) end
        end
    end
    if liveMode and not (gridInfo and gridInfo.ready) then
        view.canSetReady,view.canPrepareStart=false,false
    end
    if view.live then
        view.live.localKartId=gridInfo and gridInfo.localKartId
        view.live.peerKartId=gridInfo and gridInfo.peerKartId
        view.phase=view.live.phase=="running" and "racing" or view.live.phase
        view.reason=view.live.reason
        view.canJoin,view.canSetReady,view.canStart,view.canPrepareStart=false,false,false,false
        view.canLeave=control~=nil
    end
    return view
end

function Transport.AdvanceLive(input)
    if busy then return nil,"busy" end
    if not liveRun or not control then
        if liveMode and lastLive and lastLive.phase=="closed" then
            local snapshot=copy(lastLive)
            snapshot.localKartId=gridInfo and gridInfo.localKartId
            snapshot.peerKartId=gridInfo and gridInfo.peerKartId
            return snapshot
        end
        return nil,"inactive"
    end
    busy=true
    local now,why=checked()
    if not now then hardStop(why); busy=false; return nil,why end
    local token,expected=liveRun,control
    local ok,count,reason=pcall(Live.advance,token,math.floor(now*1000),input)
    if not ok then hardStop("controller_error"); busy=false; return nil,"controller_error" end
    if liveRun~=token or control~=expected then busy=false; return nil,"closed" end
    local snapshot=Live.view(token)
    snapshot.localKartId=gridInfo and gridInfo.localKartId
    snapshot.peerKartId=gridInfo and gridInfo.peerKartId
    if snapshot.phase=="closed" then finishLive(lastNow) end
    busy=false
    -- Terminal state is a valid final presentation snapshot. Returning only
    -- an error would make UI cleanup try to cancel the already-draining peer
    -- notice again and potentially discard it.
    if count==nil and snapshot.phase~="closed" then return nil,reason end
    return snapshot
end
function Transport.TakeStartProposal()
    if coordinated then return nil,"coordinated_start_owned" end
    if busy then return nil,"busy" end
    if not control then return nil,"inactive" end
    busy=true
    local now, reason = checked()
    if not now then hardStop(reason); busy=false; return nil,reason end
    -- Advance deadline checks without emitting any queued output.
    local ok = pcall(Session.update,control,now,function() return "failed" end,false)
    if not ok then hardStop("controller_error"); busy=false; return nil,"controller_error" end
    finish(now)
    local proposal=control and Session.takeStartProposal(control) or nil
    busy=false
    return proposal
end

-- Backend ownership handoff only. Rendering/menu navigation must never consume
-- this bundle or launch a simulation just because a screen becomes visible.
function Transport.TakeRaceStart()
    if liveMode and control then return nil,"live_start_owned" end
    if busy then return nil,"busy" end
    if not coordinated or not control or not clockState then return nil,"inactive" end
    busy=true
    local now,reason=checked()
    if not now then hardStop(reason); busy=false; return nil,reason end
    local expected=control
    local ok=pcall(Session.update,expected,now,function() return "failed" end,false)
    if not ok then hardStop("controller_error"); busy=false; return nil,"controller_error" end
    finish(now)
    if control~=expected or not clockState then busy=false; return nil,"closed" end
    local view=Session.view(expected)
    local initOK,bundle,why=pcall(function()
        return initializeRace(now,expected,view)
    end)
    if not initOK then hardStop("controller_error"); busy=false; return nil,"controller_error" end
    if not bundle then
        if raceGate or (clockState and Clock.view(clockState).phase=="launched") then
            hardStop("controller_error")
        end
        busy=false; return nil,why
    end
    if control~=expected or not owns() then busy=false; return nil,"closed" end
    lastClock=Clock.view(clockState)
    lastView=view
    lastView.phase,lastView.hasPendingOutput,lastView.deadline="launched",false,nil
    lastView.canJoin,lastView.canSetReady,lastView.canStart,lastView.canLeave=false,false,false,false
    lastView.pendingKind,lastView.pendingAttempts=nil,0
    control,clockState,raceGate,trackSet=nil,nil,nil,nil
    release()
    busy=false
    return bundle
end

return Transport
