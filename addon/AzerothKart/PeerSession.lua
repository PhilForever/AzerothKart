-- Pure two-peer control state. START proposes parameters; it never starts a race.
local _, namespace = ...
local Session = {SEND_INTERVAL=0.5, RETRY_INTERVAL=2, MAX_ATTEMPTS=3,
    MAX_ACK_QUEUE=8, MAX_SEEN=64, MAX_EVENTS=256}
local reasons = {left=true, timeout=true, incompatible=true, combat=true,
    world_leave=true, error=true}
local tracks = {test_oval=true, mirage_raceway=true}

local function finite(value)
    return type(value)=="number" and value==value and value~=math.huge and value~=-math.huge
end
local function integer(value, low, high)
    return finite(value) and value%1==0 and value>=low and value<=high
end
local function plain(value) return type(value)=="table" and getmetatable(value)==nil end
local function copy(value)
    if type(value)~="table" then return value end
    local result = {}
    for key, item in pairs(value) do result[key] = copy(item) end
    return result
end
local function name(value)
    if type(value)~="string" or #value>96 or value:find("[%z\001-\031\127|]") then return nil end
    value = value:gsub(" +", " "):match("^ *(.-) *$")
    return value~="" and value or nil
end
local function nameKey(value)
    return (value:gsub("[A-Z]", function(letter) return string.char(letter:byte()+32) end))
end
local function close(state, reason, final, now)
    state.phase, state.reason, state.deadline = "closed", reason, nil
    state.pending, state.acks, state.proposal = nil, {}, nil
    state.final = final and {payload=final, expires=now+2} or nil
end
local function advance(state, now)
    if not finite(now) or now<0 or now<state.lastNow then
        close(state, "clock_error", nil, state.lastNow)
        return false, "clock_error"
    end
    state.lastNow = now
    if state.phase=="closed" then
        if state.final and now>=state.final.expires then state.final=nil end
        return false, "closed"
    end
    if state.deadline and now>=state.deadline then
        close(state, "timeout", nil, now)
        return false, "timeout"
    end
    local pending = state.pending
    if pending and not pending.inFlight and pending.attempts>=Session.MAX_ATTEMPTS
        and now-pending.lastAttempt>=Session.RETRY_INTERVAL then
        close(state, "ack_timeout", nil, now)
        return false, "ack_timeout"
    end
    return true
end
local function encode(state, message)
    if state.nextSequence>state.codec.MAX_SEQUENCE then
        close(state, "sequence_limit", nil, state.lastNow)
        return nil
    end
    message.session, message.sequence = state.options.session, state.nextSequence
    local ok, payload = pcall(state.codec.encode, message)
    if not ok or type(payload)~="string" or #payload>state.codec.MAX_BYTES then
        close(state, "codec_error", nil, state.lastNow)
        return nil
    end
    state.nextSequence = state.nextSequence+1
    return payload
end
local function command(state, message, now)
    local payload = encode(state, message)
    if not payload then return false, state.reason end
    state.pending = {kind=message.kind, sequence=message.sequence, payload=payload,
        attempts=0, acceptedAttempts=0, nextAt=now}
    return true
end
local function seen(state, message, payload, ack)
    if state.seenCount>=Session.MAX_SEEN then
        close(state, "seen_limit", nil, state.lastNow)
        return false
    end
    state.seen[message.sequence] = {payload=payload, kind=message.kind, ack=ack}
    state.seenCount = state.seenCount+1
    return true
end
local function queueAck(state, message, cached)
    for _, entry in ipairs(state.acks) do
        if entry.remoteSequence==message.sequence then return entry.payload end
    end
    if #state.acks>=Session.MAX_ACK_QUEUE then
        close(state, "ack_queue_limit", nil, state.lastNow)
        return nil
    end
    local payload = cached or encode(state, {kind="ACK", ackKind=message.kind,
        ackSequence=message.sequence})
    if not payload then return nil end
    state.acks[#state.acks+1] = {remoteSequence=message.sequence, payload=payload}
    return payload
end
local function lobby(state, now)
    state.phase, state.deadline = "lobby", now+120
end
local function confirm(state, pending, now)
    if state.pending~=pending then return end
    state.pending = nil
    state.stats.acksMatched = state.stats.acksMatched+1
    if pending.kind=="JOIN" then
        lobby(state, now)
    elseif pending.kind=="READY" then
        state.localReadyConfirmed = true
    elseif pending.kind=="START" then
        state.startStatus = "acknowledged"
        state.start.peerAcknowledged = true
        state.proposal = copy(state.start)
    end
end
local function refuse(state, reason)
    state.stats.rejected = state.stats.rejected+1
    return false, reason
end

function Session.new(options, now, codec)
    if not plain(options) or not finite(now) or now<0 or not plain(codec)
        or type(codec.encode)~="function" or type(codec.decode)~="function"
        or type(codec.PREFIX)~="string" or not integer(codec.MAX_SEQUENCE,1,46655)
        or not integer(codec.MAX_BYTES,11,128) then return nil, "invalid_options" end
    local peer, laps = name(options.peer), options.laps==nil and 3 or options.laps
    if (options.role~="host" and options.role~="guest") or not peer
        or type(options.session)~="string" or #options.session~=6
        or options.session:find("[^A-Z0-9]") or not integer(options.physicsVersion,1,1295)
        or not integer(laps,1,9) or not plain(options.trackVersions) then
        return nil, "invalid_options"
    end
    local trackVersions, count = {}, 0
    for id, version in pairs(options.trackVersions) do
        if not tracks[id] or not integer(version,1,1295) then return nil, "invalid_options" end
        trackVersions[id], count = version, count+1
    end
    if count==0 then return nil, "invalid_options" end
    local state = {options={role=options.role, peer=peer, session=options.session,
        physicsVersion=options.physicsVersion, trackVersions=trackVersions, laps=laps},
        codec=codec, peerKey=nameKey(peer), lastNow=now, nextSequence=1,
        phase=options.role=="host" and "idle" or "listening",
        deadline=options.role=="guest" and now+30 or nil,
        localReady=false, peerReady=false, localReadyConfirmed=false,
        acks={}, seen={}, seenCount=0, commandHighwater=0, eventCount=0,
        stats={sendAttempts=0, sendsAccepted=0, retries=0, received=0,
            rejected=0, duplicates=0, acksMatched=0}}
    return state
end

function Session.invite(state, now, trackId)
    local ok, why = advance(state, now)
    if not ok then return false, why end
    if state.options.role~="host" or state.phase~="idle" then return false, "invalid_phase" end
    local version = type(trackId)=="string" and state.options.trackVersions[trackId]
    if not version then return false, "invalid_argument" end
    local offer = {physicsVersion=state.options.physicsVersion, trackId=trackId,
        trackVersion=version, laps=state.options.laps}
    local message = copy(offer)
    message.kind = "INVITE"
    if not command(state, message, now) then return false, state.reason end
    state.offer, state.phase, state.deadline = offer, "inviting", now+30
    return true
end

function Session.join(state, now)
    local ok, why = advance(state, now)
    if not ok then return false, why end
    if state.options.role~="guest" or state.phase~="invited" or state.pending then
        return false, "invalid_phase"
    end
    if not command(state, {kind="JOIN"}, now) then return false, state.reason end
    state.phase, state.deadline = "joining", now+10
    return true
end

function Session.setReady(state, now, ready)
    local ok, why = advance(state, now)
    if not ok then return false, why end
    if type(ready)~="boolean" then return false, "invalid_argument" end
    if state.phase~="lobby" or state.pending then return false, "invalid_phase" end
    if not command(state, {kind="READY", ready=ready}, now) then return false, state.reason end
    state.localReady, state.localReadyConfirmed = ready, false
    return true
end

function Session.start(state, now, startTick, seed)
    local ok, why = advance(state, now)
    if not ok then return false, why end
    if state.options.role~="host" or state.phase~="lobby" or state.pending
        or not state.localReady or not state.localReadyConfirmed or not state.peerReady then
        return false, "invalid_phase"
    end
    if not integer(startTick,0,36^6-1) or not integer(seed,0,2147483647) then
        return false, "invalid_argument"
    end
    if not command(state, {kind="START", startTick=startTick, seed=seed}, now) then
        return false, state.reason
    end
    state.start = {session=state.options.session, startTick=startTick, seed=seed,
        peerAcknowledged=false}
    state.phase, state.startStatus, state.deadline = "starting", "awaiting_ack", now+10
    return true
end

function Session.cancel(state, now, reason, notify)
    local ok, why = advance(state, now)
    if not ok then return false, why end
    if type(reason)~="string" or not reasons[reason]
        or (notify~=nil and type(notify)~="boolean") then
        return false, "invalid_argument"
    end
    local payload
    if notify then
        payload = encode(state, {kind="CANCEL", reason=reason})
        if not payload then return false, state.reason end
    end
    close(state, reason, payload, now)
    return true
end

function Session.update(state, now, sendFn, sendAllowed)
    if state.sending then return false, "send_in_progress" end
    if sendAllowed~=nil and type(sendAllowed)~="boolean" then return false, "invalid_argument" end
    local active = advance(state, now)
    if not active and not state.final then return false end
    if sendAllowed==false then return false end -- Budget waits still observe deadlines/clocks.
    if state.lastSend and now-state.lastSend<Session.SEND_INTERVAL then return false end
    local payload, pending, final
    if state.phase=="closed" then
        if not state.final then return false end
        payload, final = state.final.payload, true
        state.final = nil -- A terminal notification gets one best-effort attempt.
    elseif #state.acks>0 then
        payload = table.remove(state.acks,1).payload
    elseif state.pending and now>=state.pending.nextAt then
        pending, payload = state.pending, state.pending.payload
    else
        return false
    end
    state.lastSend = now
    state.stats.sendAttempts = state.stats.sendAttempts+1
    if pending then
        pending.attempts, pending.lastAttempt, pending.nextAt = pending.attempts+1, now,
            now+Session.RETRY_INTERVAL
        if pending.attempts>1 then state.stats.retries=state.stats.retries+1 end
        pending.inFlight = true
    end
    state.sending = true
    local ok, outcome = pcall(sendFn, payload, state.options.peer)
    state.sending = false
    if pending then pending.inFlight=false end
    if not ok or outcome~="accepted" then
        local reason = not ok and "send_error" or (outcome=="failed" and "send_failed"
            or outcome=="throttled" and "send_throttled" or "send_unknown")
        close(state, reason, nil, state.lastNow)
        return true, reason
    end
    state.stats.sendsAccepted = state.stats.sendsAccepted+1
    if pending and state.pending==pending and state.phase~="closed" then
        pending.acceptedAttempts = pending.acceptedAttempts+1
        if pending.kind=="INVITE" then state.inviteSent=true end
        if pending.kind=="JOIN" then state.joinSent=true end
        if pending.deferredAck then confirm(state, pending, state.lastNow) end
    end
    return true, final and "final" or "accepted"
end

function Session.receive(state, now, prefix, payload, channel, nativeSender)
    local ok, why = advance(state, now)
    if not ok then return false, why end
    local sender = name(nativeSender)
    if prefix~=state.codec.PREFIX or channel~="WHISPER" or not sender
        or nameKey(sender)~=state.peerKey then return false, "unrelated" end
    local decoded, message = pcall(state.codec.decode, payload)
    if not decoded or not message then return refuse(state, "invalid_packet") end
    if message.session~=state.options.session then return false, "unrelated" end
    state.eventCount, state.stats.received = state.eventCount+1, state.stats.received+1
    if state.eventCount>Session.MAX_EVENTS then
        close(state, "event_limit", nil, now)
        return false, state.reason
    end
    local previous = state.seen[message.sequence]
    if previous then
        if previous.payload~=payload then
            close(state, "conflicting_sequence", nil, now)
            return false, state.reason
        end
        state.stats.duplicates = state.stats.duplicates+1
        if message.kind~="ACK" and not queueAck(state, message, previous.ack) then
            return false, state.reason
        end
        return true, "duplicate"
    end
    if message.kind=="ACK" then
        local pending = state.pending
        if not pending or pending.kind~=message.ackKind or pending.sequence~=message.ackSequence
            or pending.attempts==0 then return refuse(state, "unexpected_ack") end
        if not seen(state, message, payload) then return false, state.reason end
        if pending.inFlight then pending.deferredAck=true else confirm(state,pending,now) end
        return true
    end
    if message.sequence<=state.commandHighwater then return refuse(state, "stale_command") end
    local kind, implicitJoin, implicitReady = message.kind, false, false
    if kind=="INVITE" then
        if state.options.role~="guest" or state.phase~="listening" then
            return refuse(state, "invalid_phase")
        end
        if message.physicsVersion~=state.options.physicsVersion
            or state.options.trackVersions[message.trackId]~=message.trackVersion then
            close(state, "incompatible", nil, now)
            return false, state.reason
        end
    elseif kind=="JOIN" then
        if state.options.role~="host" or state.phase~="inviting" or not state.inviteSent then
            return refuse(state, "invalid_phase")
        end
    elseif kind=="READY" then
        implicitJoin = state.options.role=="guest" and state.phase=="joining" and state.joinSent
        if state.phase~="lobby" and not implicitJoin then return refuse(state,"invalid_phase") end
    elseif kind=="START" then
        local pending = state.pending
        implicitReady = pending and pending.kind=="READY" and pending.acceptedAttempts>0
            and state.localReady
        if state.options.role~="guest" or state.phase~="lobby" or not state.localReady
            or not state.peerReady or (not state.localReadyConfirmed and not implicitReady) then
            return refuse(state, "invalid_phase")
        end
    elseif kind~="CANCEL" then
        return refuse(state, "invalid_packet")
    end
    if state.seenCount>=Session.MAX_SEEN then
        close(state, "seen_limit", nil, now)
        return false, state.reason
    end
    local ack = queueAck(state, message)
    if not ack or not seen(state, message, payload, ack) then return false, state.reason end
    state.commandHighwater = message.sequence
    if kind=="INVITE" then
        -- The host's valid laps count is an offer, not a guest compatibility version.
        state.offer = {physicsVersion=message.physicsVersion, trackId=message.trackId,
            trackVersion=message.trackVersion, laps=message.laps}
        state.phase, state.deadline = "invited", now+30
    elseif kind=="JOIN" then
        state.pending = nil -- JOIN also proves receipt of INVITE if its ACK was lost.
        lobby(state, now)
    elseif kind=="READY" then
        if implicitJoin then
            state.pending = nil
            lobby(state, now)
        end
        state.peerReady = message.ready
    elseif kind=="START" then
        if implicitReady then state.pending, state.localReadyConfirmed=nil, true end
        state.start = {session=message.session, startTick=message.startTick, seed=message.seed,
            peerAcknowledged=false}
        state.phase, state.startStatus, state.deadline = "starting", "received", now+10
        state.proposal = copy(state.start)
    elseif kind=="CANCEL" then
        close(state, "peer_"..message.reason, ack, now)
    end
    return true
end

function Session.view(state)
    local active = state.phase~="closed"
    local free = active and state.pending==nil
    return {role=state.options.role, peer=state.options.peer, session=state.options.session,
        phase=state.phase, localReady=state.localReady, peerReady=state.peerReady,
        localReadyConfirmed=state.localReadyConfirmed, startStatus=state.startStatus,
        pendingKind=state.pending and state.pending.kind or nil,
        pendingAttempts=state.pending and state.pending.attempts or 0,
        reason=state.reason, deadline=state.deadline,
        canInvite=free and state.options.role=="host" and state.phase=="idle",
        canJoin=free and state.options.role=="guest" and state.phase=="invited",
        canSetReady=free and state.phase=="lobby",
        canStart=free and state.options.role=="host" and state.phase=="lobby"
            and state.localReady and state.localReadyConfirmed and state.peerReady,
        canLeave=active, hasPendingOutput=state.final~=nil or #state.acks>0 or state.pending~=nil,
        offer=copy(state.offer), start=copy(state.start), stats=copy(state.stats)}
end

function Session.takeStartProposal(state)
    local proposal = state.proposal
    state.proposal = nil
    return proposal and copy(proposal) or nil
end

-- Explicit opt-in ownership transfer to a bounded clock coordinator. Legacy
-- START remains parameter data and retains its original ten-second deadline.
function Session.handoffStart(state, now)
    local ok, why = advance(state, now)
    if not ok then return nil, why end
    if state.phase~="starting" or not state.proposal then return nil, "invalid_phase" end
    local proposal=Session.takeStartProposal(state)
    state.phase, state.deadline = "coordinating", now+30
    return proposal
end

-- Backend-only transition after an actual coordinated GO was initialized.
-- The live owner now supplies bounded race duration/liveness. Keep this
-- controller solely for its existing paced terminal cancellation semantics.
function Session.beginRace(state, now)
    local ok,why=advance(state,now)
    if not ok then return false,why end
    if state.phase~="coordinating" then return false,"invalid_phase" end
    state.phase,state.deadline,state.pending,state.proposal="racing",nil,nil,nil
    state.acks={}
    return true
end

if type(namespace)=="table" then namespace.PeerSession=Session end
return Session
