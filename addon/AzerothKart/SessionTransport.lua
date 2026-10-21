-- Explicit two-peer control bridge. No registration, output or UI on load.
-- START is a proposal; this adapter never starts or changes a race.
local _, AK = ...
assert(type(AK)=="table", "addon namespace required")
local Session, Protocol = assert(AK.PeerSession), assert(AK.RaceProtocol)
local Transport = {ROUTE="WHISPER_LOGGED"}
AK.SessionTransport = Transport

local frame, control, lastView, lastError, lastNow, busy, drainDeadline
local registered, sendAPI, sendSuccess, failedCodes, throttleCodes
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
    send_failed=true, send_unknown=true, send_throttled=true}

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
        if AK.UI and AK.UI.active then return "local_drive" end
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
    if view.hasPendingOutput then
        drainDeadline = drainDeadline or now+2
        if now<drainDeadline then return end
        view.hasPendingOutput=false
    end
    lastView, control, drainDeadline = view, nil, nil
    release()
end
local function readyToSend(now, bytes)
    return (not lastAttempt or now-lastAttempt>=0.5)
        and #attempts<2 and traffic.windowBytes+bytes<=158
end

local function capabilities()
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
    if not registered then
        local raw = C_ChatInfo.RegisterAddonMessagePrefix(Protocol.PREFIX)
        if raw~=register.Success and raw~=register.DuplicatePrefix then return false,"prefix_registration" end
        registered=true
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
local function nativeSend(expected, payload, peer)
    if control~=expected then return "failed" end
    local now, reason = checked()
    if not now then hardStop(reason); return "failed" end
    if control~=expected or not owns() then return "failed" end
    if type(payload)~="string" or #payload>23 or not readyToSend(now,#payload+#Protocol.PREFIX) then
        hardStop("error"); return "failed"
    end
    -- Charge every attempted native call, including throws/unknown results.
    lastAttempt=now
    attempts[#attempts+1]={at=now,bytes=#payload+#Protocol.PREFIX}
    traffic.attempts=traffic.attempts+1
    traffic.payloadBytes=traffic.payloadBytes+#payload
    traffic.prefixBytes=traffic.prefixBytes+#Protocol.PREFIX
    prune(now)
    local sendingFrame=frame
    sendingFrame.akNetworkSending=Transport
    local ok, outcome = pcall(function()
        return classify(sendAPI(Protocol.PREFIX,payload,"WHISPER",peer))
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

local function arm(role, peer, code, trackId)
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
    local ok, candidate = pcall(function()
        local mirage = AK.MirageRaceway.new(AK.Track.crossesGate)
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
    local apiOK, capable, why = pcall(capabilities)
    if not apiOK or not capable then return fail(apiOK and why or "capabilities") end
    if not owns() then return fail("lease_lost") end
    -- Native hook callbacks can call Stop. Keep the candidate private until all
    -- hooks succeed and verify that the lease was not revoked reentrantly.
    local eventOK, eventResult = pcall(frame.RegisterEvent,frame,"CHAT_MSG_ADDON_LOGGED")
    if not eventOK or eventResult==false or not owns() then return fail("event_registration") end
    local updateOK = pcall(frame.SetScript,frame,"OnUpdate",Transport.Update)
    if not updateOK or not owns() then return fail("update_registration") end
    control, lastView, lastError, drainDeadline = state, nil, nil, nil
    used[code], usedCount=true,usedCount+1
    busy=false
    return true
end
function Transport.Host(peer,code,trackId) return arm("host",peer,code,trackId) end
function Transport.Listen(peer,code) return arm("guest",peer,code) end

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
function Transport.Ready(ready) return action(Session.setReady,ready) end
function Transport.Start(startTick,seed) return action(Session.start,startTick,seed) end
function Transport.Leave() return action(Session.cancel,"left",true) end

function Transport.Update()
    if busy then return false,"busy" end
    if not control then return false,"inactive" end
    busy=true
    local now, reason = checked()
    if not now then hardStop(reason); busy=false; return false,reason end
    local expected=control
    -- Reserve enough budget for the largest control message; no queued output
    -- is consumed while pacing blocks a send. Timeouts still advance.
    local ok, sent, why = pcall(Session.update,expected,now,
        function(payload,peer) return nativeSend(expected,payload,peer) end,
        readyToSend(now,23+#Protocol.PREFIX))
    if not ok then hardStop("controller_error"); busy=false; return false,"controller_error" end
    if control==expected then
        local view=Session.view(expected)
        if view.phase=="closed" and view.reason and view.reason:match("^send_") then lastError=view.reason end
        finish(now)
    end
    busy=false
    return sent==true,why
end
function Transport.Message(prefix,payload,channel,nativeSender)
    if not control or prefix~=Protocol.PREFIX then return false,"unrelated" end
    -- Message may run reentrantly during the native call to defer a matching
    -- ACK; it never invokes Update or sends from the event stack.
    local now, reason = checked()
    if not now then return hardStop(reason) end
    local expected=control
    local ok, accepted, why = pcall(Session.receive,expected,now,prefix,payload,channel,nativeSender)
    if not ok then return hardStop("controller_error") end
    if control==expected then finish(now) end
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
    return view
end
function Transport.TakeStartProposal()
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

return Transport
