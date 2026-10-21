-- Pure, opt-in two-peer start-clock coordination. Local acceptance is not delivery.
local _, namespace = ...
local Clock = {SEND_INTERVAL_MS=500, RETRY_INTERVAL_MS=2000, MAX_ATTEMPTS=3,
    MAX_QUEUE=8, MAX_SEEN=64, MAX_EVENTS=256, DURATION_MS=30000,
    LEAD_MS=8000, HANDSHAKE_MARGIN_MS=1000, MAX_LATENESS_MS=250,
    MAX_RTT_MS=2000, QUANTIZATION_MS=2}
local reasons = {timeout=true, clock_error=true, contradiction=true, late=true,
    error=true, left=true}
local function integer(value, low, high)
    return type(value)=="number" and value==value and value%1==0
        and value>=low and value<=high
end
local function plain(value) return type(value)=="table" and getmetatable(value)==nil end
local function copy(value)
    if type(value)~="table" then return value end
    local result = {}
    for key,item in pairs(value) do result[key]=copy(item) end
    return result
end
local function close(state, reason)
    state.phase, state.reason = "closed", reason
    state.pending, state.queue, state.deferred = nil, {}, {}
    state.ticketTaken = true
end
local function advance(state, now)
    if not integer(now,0,state.codec.MAX_TIME) or now<state.lastNow then
        close(state,"clock_error")
        return false,"clock_error"
    end
    state.lastNow = now
    if state.phase=="closed" then return false,"closed" end
    if state.phase=="launched" then return false,"already_taken" end
    if now>=state.deadline then
        close(state,"timeout")
        return false,"timeout"
    end
    if state.localEpochMS then
        if state.phase=="armed" then
            if now>state.localEpochMS+Clock.MAX_LATENESS_MS then
                close(state,"late")
                return false,"late"
            end
        elseif now>=state.localEpochMS-Clock.HANDSHAKE_MARGIN_MS then
            close(state,"late")
            return false,"late"
        end
    end
    local pending = state.pending
    if pending and not pending.inFlight and pending.attempts>=Clock.MAX_ATTEMPTS
        and now>=pending.nextAt then
        close(state,"timeout")
        return false,"timeout"
    end
    return true
end
local function refuse(state, reason)
    state.stats.rejected=state.stats.rejected+1
    return false,reason
end
local function make(state, fields, lazy)
    if state.nextSequence>state.codec.MAX_SEQUENCE then
        close(state,"sequence_limit")
        return nil
    end
    local message = copy(fields)
    message.session, message.sequence = state.options.session, state.nextSequence
    state.nextSequence = state.nextSequence+1
    local entry = {message=message, kind=message.kind, sequence=message.sequence,
        attempts=0, acceptedAttempts=0, nextAt=state.lastNow}
    if not lazy then
        local ok,payload = pcall(state.codec.encode,message)
        if not ok or type(payload)~="string" or #payload>state.codec.MAX_BYTES then
            close(state,"codec_error")
            return nil
        end
        entry.payload=payload
    end
    return entry
end
local function command(state, fields, lazy)
    local entry=make(state,fields,lazy)
    if not entry then return false end
    state.pending=entry
    return true
end
local function remember(state, message, payload, response)
    if state.seenCount>=Clock.MAX_SEEN then close(state,"seen_limit"); return false end
    state.seen[message.sequence]={payload=payload,response=response}
    state.seenCount=state.seenCount+1
    return true
end
local function enqueue(state, entry)
    for _,queued in ipairs(state.queue) do
        if queued==entry then return true end
    end
    if #state.queue>=Clock.MAX_QUEUE then close(state,"queue_limit"); return false end
    state.queue[#state.queue+1]=entry
    return true
end
local function ack(state, message)
    return make(state,{kind="ACK",ackKind=message.kind,ackSequence=message.sequence})
end
local function arm(state)
    if state.phase=="closed" or state.phase=="launched" or state.phase=="armed" then return end
    state.phase, state.pending = "armed",nil
    state.peerAcknowledged = state.options.role=="host"
end
local function completeSample(state, pending, message, now)
    local t1,t2,t3,t4 = message.t1,message.t2,message.t3,now
    if t1~=pending.message.t1 or message.sample~=pending.message.sample
        or t3<t2 or t4<t1 then return refuse(state,"unexpected_pong") end
    local rtt = (t4-t1)-(t3-t2)
    if rtt<0 or rtt>Clock.MAX_RTT_MS then
        close(state,"clock_error"); return false,state.reason
    end
    local low,high = t3-t4-Clock.QUANTIZATION_MS,t2-t1+Clock.QUANTIZATION_MS
    if not integer(low,-state.codec.MAX_TIME,state.codec.MAX_TIME)
        or not integer(high,-state.codec.MAX_TIME,state.codec.MAX_TIME) then
        close(state,"clock_error"); return false,state.reason
    end
    if state.offsetLowMS then
        low,high=math.max(low,state.offsetLowMS),math.min(high,state.offsetHighMS)
    end
    if low>high then close(state,"contradiction"); return false,state.reason end
    state.offsetLowMS,state.offsetHighMS,state.rttMS = low,high,rtt
    state.uncertaintyMS=math.ceil((high-low)/2)
    state.sampleCount=state.sampleCount+1
    state.sampleDetails[state.sampleCount]={t1MS=t1,t2MS=t2,t3MS=t3,t4MS=t4,rttMS=rtt,
        offsetLowMS=low,offsetHighMS=high}
    state.pending=nil
    if state.sampleCount<3 then
        return command(state,{kind="PING",sample=state.sampleCount+1},true)
    end
    local epoch=now+Clock.LEAD_MS
    if epoch+Clock.MAX_LATENESS_MS>=state.deadline or epoch>state.codec.MAX_TIME then
        close(state,"timeout"); return false,state.reason
    end
    state.hostEpochMS,state.localEpochMS,state.phase=epoch,epoch,"preparing"
    return command(state,{kind="PREPARE",epoch=epoch,low=low,high=high})
end

local process
process = function(state, now, payload, message)
    local previous=state.seen[message.sequence]
    if previous then
        if previous.payload~=payload then
            close(state,"conflicting_sequence"); return false,state.reason
        end
        state.stats.duplicates=state.stats.duplicates+1
        if previous.response and not enqueue(state,previous.response) then return false,state.reason end
        return true,"duplicate"
    end
    if message.kind=="CANCEL" then
        if not remember(state,message,payload) then return false,state.reason end
        close(state,"peer_"..message.reason)
        return true
    end
    if message.kind=="ACK" then
        local pending=state.pending
        if state.options.role~="host" or not pending or pending.kind~=message.ackKind
            or pending.sequence~=message.ackSequence or pending.acceptedAttempts==0 then
            return refuse(state,"unexpected_ack")
        end
        if not remember(state,message,payload) then return false,state.reason end
        state.stats.acksMatched=state.stats.acksMatched+1
        state.pending=nil
        if message.ackKind=="PREPARE" then
            state.phase="committing"
            if not command(state,{kind="COMMIT",epoch=state.hostEpochMS}) then
                return false,state.reason
            end
        else
            arm(state)
        end
        return true
    end
    if message.sequence<=state.commandHighwater then return refuse(state,"stale_command") end
    local response
    if message.kind=="PING" then
        if state.options.role~="guest" or state.phase~="calibrating"
            or message.sample~=state.sampleCount+1 then return refuse(state,"invalid_phase") end
        response=make(state,{kind="PONG",sample=message.sample,t1=message.t1,t2=now},true)
        if not response then return false,state.reason end
    elseif message.kind=="PONG" then
        local pending=state.pending
        if state.options.role~="host" or state.phase~="calibrating" or not pending
            or pending.kind~="PING" or pending.acceptedAttempts==0 then
            return refuse(state,"unexpected_pong")
        end
        -- Validate before remembering: an unsolicited early packet must not shadow a later reply.
        if message.sample~=pending.message.sample or message.t1~=pending.message.t1 then
            return refuse(state,"unexpected_pong")
        end
        if not remember(state,message,payload) then return false,state.reason end
        state.commandHighwater=message.sequence
        return completeSample(state,pending,message,now)
    elseif message.kind=="PREPARE" then
        if state.options.role~="guest" or state.phase~="calibrating" or state.sampleCount~=3 then
            return refuse(state,"invalid_phase")
        end
        local mapped=message.epoch+math.floor((message.low+message.high)/2)
        local lead=mapped-now
        if not integer(mapped,0,state.codec.MAX_TIME) or lead<3000 or lead>12000
            or mapped+Clock.MAX_LATENESS_MS>=state.deadline then
            close(state,"late"); return false,state.reason
        end
        -- Honest intersection bounds cannot extend beyond any recorded t2-t1 bound.
        for _,sample in ipairs(state.sampleDetails) do
            if message.high>sample.t2MS-sample.t1MS+Clock.QUANTIZATION_MS then
                close(state,"contradiction"); return false,state.reason
            end
        end
        state.offsetLowMS,state.offsetHighMS=message.low,message.high
        state.uncertaintyMS=math.ceil((message.high-message.low)/2)
        state.hostEpochMS,state.localEpochMS=message.epoch,mapped
        state.phase="preparing"
        response=ack(state,message)
        if not response then return false,state.reason end
        response.prepareAck=true
    elseif message.kind=="COMMIT" then
        if state.options.role~="guest" or state.phase~="preparing" or not state.prepareAckSent
            or message.epoch~=state.hostEpochMS then return refuse(state,"invalid_phase") end
        state.phase="committing"
        response=ack(state,message)
        if not response then return false,state.reason end
        response.commitAck=true
    else
        return refuse(state,"invalid_packet")
    end
    if not remember(state,message,payload,response) then return false,state.reason end
    state.commandHighwater=message.sequence
    if response and not enqueue(state,response) then return false,state.reason end
    return true
end

function Clock.new(options, now, codec)
    if not plain(options) or not plain(codec) or type(codec.encode)~="function"
        or type(codec.decode)~="function" or not integer(codec.MAX_BYTES,34,64)
        or not integer(codec.MAX_SEQUENCE,1,46655) or not integer(codec.MAX_TIME,30000,36^7-1)
        or not integer(now,0,codec.MAX_TIME-Clock.DURATION_MS)
        or (options.role~="host" and options.role~="guest")
        or type(options.session)~="string" or #options.session~=6
        or options.session:find("[^A-Z0-9]") or not integer(options.seed,0,2147483647) then
        return nil,"invalid_options"
    end
    local state={options={role=options.role,session=options.session,seed=options.seed},
        codec=codec,phase="calibrating",lastNow=now,deadline=now+Clock.DURATION_MS,
        nextSequence=1,queue={},seen={},seenCount=0,commandHighwater=0,
        eventCount=0,deferred={},sampleCount=0,sampleDetails={},peerAcknowledged=false,
        stats={sendAttempts=0,sendsAccepted=0,retries=0,received=0,rejected=0,
            duplicates=0,acksMatched=0}}
    if options.role=="host" and not command(state,{kind="PING",sample=1},true) then
        return nil,state.reason
    end
    return state
end

function Clock.update(state, now, sendFn, sendAllowed)
    if state.sending then return false,"send_in_progress" end
    if sendAllowed~=nil and type(sendAllowed)~="boolean" then return false,"invalid_argument" end
    local active,why=advance(state,now)
    if not active then return false,why end
    if sendAllowed==false then return false end
    if state.lastSend and now-state.lastSend<Clock.SEND_INTERVAL_MS then return false end
    local entry,pending
    if #state.queue>0 then
        entry=table.remove(state.queue,1)
    elseif state.pending and now>=state.pending.nextAt then
        entry,pending=state.pending,true
    else
        return false
    end
    if not entry.payload then
        if entry.kind=="PING" then entry.message.t1=now end
        if entry.kind=="PONG" then entry.message.t3=now end
        local ok,payload=pcall(state.codec.encode,entry.message)
        if not ok or type(payload)~="string" or #payload>state.codec.MAX_BYTES then
            close(state,"codec_error"); return false,state.reason
        end
        entry.payload=payload
    end
    state.lastSend=now
    entry.attempts,entry.lastAttempt,entry.nextAt=entry.attempts+1,now,now+Clock.RETRY_INTERVAL_MS
    state.stats.sendAttempts=state.stats.sendAttempts+1
    if entry.attempts>1 then state.stats.retries=state.stats.retries+1 end
    entry.inFlight,state.sending=true,true
    local ok,outcome=pcall(sendFn,entry.payload)
    entry.inFlight,state.sending=false,false
    if state.phase=="closed" then return true,state.reason end
    if not ok or outcome~="accepted" then
        local reason=not ok and "send_error" or (outcome=="failed" and "send_failed"
            or outcome=="throttled" and "send_throttled" or "send_unknown")
        close(state,reason)
        return true,reason
    end
    entry.acceptedAttempts=entry.acceptedAttempts+1
    state.stats.sendsAccepted=state.stats.sendsAccepted+1
    if not pending and entry.kind=="PONG" and not entry.counted then
        entry.counted=true
        state.sampleCount=state.sampleCount+1
        state.sampleDetails[state.sampleCount]={t1MS=entry.message.t1,t2MS=entry.message.t2,
            t3MS=entry.message.t3}
    end
    if entry.prepareAck then state.prepareAckSent=true end
    if entry.commitAck then arm(state) end
    local deferred=state.deferred
    state.deferred={}
    for _,packet in ipairs(deferred) do
        if state.phase=="closed" then break end
        process(state,packet.now,packet.payload,packet.message)
    end
    return true,"accepted"
end

function Clock.receive(state, now, payload)
    local active,why=advance(state,now)
    if not active then return false,why end
    local ok,message=pcall(state.codec.decode,payload)
    if not ok or not message then return refuse(state,"invalid_packet") end
    if message.session~=state.options.session then return false,"unrelated" end
    state.eventCount,state.stats.received=state.eventCount+1,state.stats.received+1
    if state.eventCount>Clock.MAX_EVENTS then close(state,"event_limit"); return false,state.reason end
    if state.sending then
        if #state.deferred>=Clock.MAX_QUEUE then close(state,"queue_limit"); return false,state.reason end
        state.deferred[#state.deferred+1]={now=now,payload=payload,message=message}
        return true,"deferred"
    end
    return process(state,now,payload,message)
end

function Clock.cancel(state, now, reason)
    if type(reason)~="string" or not reasons[reason] then return false,"invalid_argument" end
    local active,why=advance(state,now)
    if not active then return false,why end
    close(state,reason)
    return true
end

function Clock.takeTicket(state, now)
    if state.sending then return nil,"send_in_progress" end
    local active,why=advance(state,now)
    if not active then return nil,why end
    if state.phase~="armed" then return nil,"not_armed" end
    if now<state.localEpochMS then return nil,"waiting" end
    state.phase,state.ticketTaken="launched",true
    state.pending,state.queue,state.deferred=nil,{},{}
    return {session=state.options.session,role=state.options.role,seed=state.options.seed,
        localEpochMS=state.localEpochMS,hostEpochMS=state.hostEpochMS,
        offsetLowMS=state.offsetLowMS,offsetHighMS=state.offsetHighMS,
        uncertaintyMS=state.uncertaintyMS,peerAcknowledged=state.peerAcknowledged}
end

function Clock.view(state)
    return {role=state.options.role,session=state.options.session,phase=state.phase,reason=state.reason,
        deadlineMS=state.deadline,samples=state.sampleCount,sampleDetails=copy(state.sampleDetails),
        rttMS=state.rttMS,offsetLowMS=state.offsetLowMS,offsetHighMS=state.offsetHighMS,
        uncertaintyMS=state.uncertaintyMS,localEpochMS=state.localEpochMS,
        hostEpochMS=state.hostEpochMS,peerAcknowledged=state.peerAcknowledged,
        pendingKind=state.pending and state.pending.kind,
        pendingAttempts=state.pending and state.pending.attempts or 0,
        hasPendingOutput=#state.queue>0 or state.pending~=nil,stats=copy(state.stats)}
end

if type(namespace)=="table" then namespace.StartClock=Clock end
return Clock
