-- Opt-in bounded transport experiment. Pure Lua; not a multiplayer protocol.
local _, namespace = ...
local Probe = {PREFIX="AZKART1", ACK_DEADLINE=5, DRAIN_SECONDS=10,
    MAX_SEQUENCES=480, MAX_EVENTS=2048, MAX_REJECTED=1000}
local rates, sizes = {[0.5]=true,[1]=true,[2]=true,[4]=true}, {[16]=true,[64]=true,[128]=true,[220]=true}
local digits = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
local counterNames = {"data_attempts","ack_attempts","data_enqueue_accepted","data_enqueue_failed",
    "data_enqueue_unknown","ack_enqueue_accepted","ack_enqueue_failed","ack_enqueue_unknown",
    "throttle_events","send_errors","rx_total","rx_unique","rx_rejected","duplicates",
    "reordered_unique","ack_matched_unique","ack_timeouts_at_deadline","late_acks",
    "missed_slots","aggregate_attempted_bytes"}
local function finite(n) return type(n)=="number" and n==n and n~=math.huge and n~=-math.huge end
local function sessionOK(s) return type(s)=="string" and #s==6 and not s:find("[^A-Z0-9]") end
local function integer(n) return finite(n) and n==math.floor(n) end
local function peerOK(p)
    return type(p)=="string" and #p<=128 and p:match("^[^%s|%-]+%-.+$")
        and not p:find("[%c%s|]")
end

function Probe.encode(kind, session, sequence, bytes)
    if (kind~="D" and kind~="A") or not sessionOK(session)
        or not integer(sequence) or sequence<1 or sequence>Probe.MAX_SEQUENCES
        or not sizes[bytes] or (kind=="A" and bytes~=16) then return nil,"invalid_packet" end
    local hi,lo=math.floor(sequence/36),sequence%36
    return "1"..kind..session..digits:sub(hi+1,hi+1)..digits:sub(lo+1,lo+1)..string.rep(".",bytes-10)
end

function Probe.decode(payload, expectedBytes)
    if type(payload)~="string" or not sizes[#payload] then return nil,"size" end
    local kind,session=payload:sub(2,2),payload:sub(3,8)
    if payload:sub(1,1)~="1" then return nil,"version" end
    if (kind~="D" and kind~="A") or not sessionOK(session) then return nil,"syntax" end
    if (kind=="A" and #payload~=16) or (kind=="D" and expectedBytes and #payload~=expectedBytes) then
        return nil,"size"
    end
    local a,b=digits:find(payload:sub(9,9),1,true),digits:find(payload:sub(10,10),1,true)
    if not a or not b then return nil,"sequence" end
    local sequence=(a-1)*36+b-1
    if sequence<1 or sequence>Probe.MAX_SEQUENCES then return nil,"sequence" end
    if payload:sub(11)~=string.rep(".",#payload-10) then return nil,"padding" end
    return {kind=kind,session=session,sequence=sequence,bytes=#payload}
end

function Probe.new(options, now)
    if type(options)~="table" or not finite(now) or now<0 then return nil,"invalid_options" end
    local mode,rate,bytes,duration=options.mode,options.rate or 0.5,options.bytes or 16,options.duration or 120
    if (mode~="send" and mode~="listen") or not peerOK(options.peer) or not sessionOK(options.session)
        or not rates[rate] or not sizes[bytes] or not integer(duration) or duration<10 or duration>120 then
        return nil,"invalid_options"
    end
    local state={options={mode=mode,peer=options.peer,session=options.session,rate=rate,bytes=bytes,duration=duration},
        phase=mode=="send" and "sending" or "listening",reason=nil,start=now,last_now=now,
        max_sequence=math.floor(rate*duration),last_slot=0,highest_rx=0,highest_ack=0,
        sent={},seen={},acks={},ack_sent={},ack_tokens=4,ack_refill_at=now,
        data_codes={},ack_codes={},reject_reasons={},rtts={},gaps={}}
    for _,name in ipairs(counterNames) do state[name]=0 end
    return state
end

local function clock(state,now)
    if state.phase=="stopped" then return false end
    if not finite(now) or now<state.last_now then
        state.phase,state.reason="stopped","invalid_clock"
        state.stopped_at=state.last_now
        return false
    end
    state.last_now=now
    return true
end
local function outstanding(state)
    local n=0
    for _,entry in pairs(state.sent) do if entry.outcome=="accepted" and not entry.acked then n=n+1 end end
    return n
end
local function finish(state,now,reason)
    state.phase,state.reason,state.stopped_at="stopped",reason,now
    state.outstanding_after_drain=outstanding(state)
end
function Probe.stop(state,now,reason)
    if not clock(state,now) then return false end
    finish(state,now,type(reason)=="string" and reason or "cancelled")
    return true
end
local function drain(state,at,reason)
    if state.phase~="sending" and state.phase~="draining" then return end
    local untilAt=at+Probe.DRAIN_SECONDS
    if not state.drain_until or untilAt<state.drain_until then
        state.phase,state.reason,state.drain_until="draining",reason,untilAt
    end
end
local function advance(state,now)
    if not clock(state,now) then return false end
    if state.options.mode=="send" then
        local expiredAt
        for _,entry in pairs(state.sent) do
            if entry.outcome=="accepted" and not entry.acked and not entry.timed_out
                and now-entry.at>=Probe.ACK_DEADLINE then
                entry.timed_out=true
                state.ack_timeouts_at_deadline=state.ack_timeouts_at_deadline+1
                local deadline=entry.at+Probe.ACK_DEADLINE
                expiredAt=not expiredAt and deadline or math.min(expiredAt,deadline)
            end
        end
        local endAt=state.start+state.options.duration
        local stopAt,reason=expiredAt,"ack_deadline"
        -- The exact end instant still permits update's final scheduled slot.
        -- Receive also uses this path, so a missing update cannot extend the window.
        if now>endAt and (not stopAt or endAt<stopAt) then stopAt,reason=endAt,"window_complete" end
        if stopAt then
            if state.phase=="sending" and reason=="window_complete" then
                state.missed_slots=state.missed_slots+math.max(0,state.max_sequence-state.last_slot)
                state.last_slot=state.max_sequence
            end
            drain(state,stopAt,reason)
        end
        if state.phase=="draining" and now>=state.drain_until then finish(state,now,state.reason) end
    elseif state.phase=="draining" then
        if now>=state.drain_until then finish(state,now,state.reason) end
    elseif state.first_rx then
        local endAt=state.first_rx+state.options.duration
        if now>=endAt and state.last_rx+5>=endAt then
            state.phase,state.reason,state.drain_until="draining","window_complete",endAt+Probe.DRAIN_SECONDS
            if now>=state.drain_until then finish(state,now,state.reason) end
        elseif now-state.last_rx>=5 then finish(state,now,"listener_idle") end
    elseif now-state.start>=30 then finish(state,now,"listen_expired") end
    return state.phase~="stopped"
end
local function rawCode(raw)
    local t=type(raw)
    if t=="nil" then return "nil" end
    if t=="boolean" then return raw and "boolean:true" or "boolean:false" end
    if t=="number" and finite(raw) then return "number:"..tostring(raw) end
    return t -- Never copy arbitrary text, error objects or secret-like values into evidence.
end
local function recordCode(map,raw,isError)
    local key=isError and "error" or rawCode(raw)
    if not map[key] then
        local count=0
        for _ in pairs(map) do count=count+1 end
        if count>=31 then key="other" end
    end
    map[key]=(map[key] or 0)+1
end
local function send(state,now,kind,sequence,sendFn)
    if state.phase=="stopped" then return false end
    local class=kind=="D" and "data" or "ack"
    if kind=="A" then
        state.ack_tokens=math.min(4,state.ack_tokens+(now-state.ack_refill_at)*4)
        state.ack_refill_at=now
        if state.ack_tokens+1e-9<1 then finish(state,now,"ack_rate_limit"); return false end
        state.ack_tokens=math.max(0,state.ack_tokens-1)
    end
    local bytes=kind=="D" and state.options.bytes or 16
    local payload=Probe.encode(kind,state.options.session,sequence,bytes)
    state[class.."_attempts"]=state[class.."_attempts"]+1
    state.aggregate_attempted_bytes=state.aggregate_attempted_bytes+bytes
    -- Register before invoking an injected sender, including synchronous test delivery.
    local entries=kind=="D" and state.sent or state.ack_sent
    entries[sequence]={at=now,outcome="pending"}
    local ok,outcome,raw=pcall(sendFn,kind,payload)
    if not ok then
        outcome="failed"
        state.send_errors=state.send_errors+1
        recordCode(state[class.."_codes"],nil,true)
    else recordCode(state[class.."_codes"],raw) end
    local throttled=outcome=="throttled"
    if throttled then
        state.throttle_events=state.throttle_events+1
        outcome="failed"
    elseif outcome~="accepted" and outcome~="failed" then outcome="unknown" end
    state[class.."_enqueue_"..outcome]=state[class.."_enqueue_"..outcome]+1
    entries[sequence].outcome=outcome
    if outcome~="accepted" then
        finish(state,now,not ok and "send_error" or (throttled and "throttled" or "enqueue_"..outcome))
    end
    return outcome=="accepted"
end

function Probe.update(state,now,sendFn)
    if not advance(state,now) then return false end
    if state.phase~="sending" then return true end
    local elapsed=now-state.start
    local slot=math.min(state.max_sequence,math.floor(elapsed*state.options.rate+1e-9))
    if slot>state.last_slot then
        state.missed_slots=state.missed_slots+slot-state.last_slot-1
        state.last_slot=slot
        send(state,now,"D",slot,sendFn)
    end
    if now>=state.start+state.options.duration and state.phase=="sending" then
        drain(state,state.start+state.options.duration,"window_complete")
    end
    return state.phase~="stopped"
end
local function reject(state,now,reason)
    state.rx_rejected=state.rx_rejected+1
    state.reject_reasons[reason]=(state.reject_reasons[reason] or 0)+1
    if state.rx_rejected>=Probe.MAX_REJECTED then finish(state,now,"rejected_limit") end
    return false
end

function Probe.receive(state,now,prefix,payload,channel,eventSender,sendFn)
    if not advance(state,now) or prefix~=Probe.PREFIX then return false end
    if state.rx_total>=Probe.MAX_EVENTS then finish(state,now,"receive_limit"); return false end
    state.rx_total=state.rx_total+1
    if channel~="WHISPER" then return reject(state,now,"channel") end
    if type(eventSender)~="string" or #eventSender>128
        or eventSender:lower()~=state.options.peer:lower() then return reject(state,now,"sender") end
    local packet,err=Probe.decode(payload,state.options.bytes)
    if not packet then return reject(state,now,err) end
    if packet.session~=state.options.session then return reject(state,now,"session") end
    local seq=packet.sequence
    if seq>state.max_sequence then return reject(state,now,"sequence") end
    if packet.kind=="D" then
        if state.options.mode~="listen" then return reject(state,now,"kind") end
        if state.seen[seq] then state.duplicates=state.duplicates+1; return true end
        state.seen[seq]=true
        state.rx_unique=state.rx_unique+1
        if seq<state.highest_rx then state.reordered_unique=state.reordered_unique+1 end
        state.highest_rx=math.max(state.highest_rx,seq)
        if state.last_rx then state.gaps[#state.gaps+1]=(now-state.last_rx)*1000 end
        state.first_rx=state.first_rx or now
        state.last_rx=now
        send(state,now,"A",seq,sendFn)
    else
        if state.options.mode~="send" then return reject(state,now,"kind") end
        local entry=state.sent[seq]
        if not entry or (entry.outcome~="accepted" and entry.outcome~="pending") then return reject(state,now,"unsent") end
        if entry.acked then state.duplicates=state.duplicates+1; return true end
        entry.acked,state.acks[seq]=true,true
        state.ack_matched_unique=state.ack_matched_unique+1
        if entry.timed_out then state.late_acks=state.late_acks+1 end
        state.rtts[#state.rtts+1]=(now-entry.at)*1000
    end
    return true
end

local function timings(out,name,values)
    local sorted={}
    for i,value in ipairs(values) do sorted[i]=value end
    table.sort(sorted)
    local n=#sorted
    out[name.."_samples"]=n
    for _,percent in ipairs({50,95,99}) do
        out[name.."_p"..percent.."_ms"]=n>0 and sorted[math.ceil(n*percent/100)] or "NA"
    end
    out[name.."_max_ms"]=n>0 and sorted[n] or "NA"
end
function Probe.summary(state)
    local out={phase=state.phase,reason=state.reason or "",scheduled_data_attempts=state.max_sequence,
        outstanding_after_drain=state.outstanding_after_drain or outstanding(state),
        elapsed_seconds=(state.stopped_at or state.last_now)-state.start}
    for _,name in ipairs(counterNames) do out[name]=state[name] end
    timings(out,"rtt",state.rtts)
    timings(out,"gap",state.gaps)
    return out
end
function Probe.evidence(state,kind)
    if kind~="sent" and kind~="received" and kind~="acks_sent" and kind~="acks_received" then
        return nil,"invalid_evidence"
    end
    local bitmap={}
    for seq=1,state.max_sequence do
        if kind=="received" or kind=="acks_received" then
            local entries=kind=="received" and state.seen or state.acks
            bitmap[seq]=entries[seq] and "1" or "."
        else
            local entries=kind=="sent" and state.sent or state.ack_sent
            local entry=entries[seq]
            bitmap[seq]=not entry and "." or (entry.outcome=="accepted" and "1"
                or (entry.outcome=="failed" and "f" or "u"))
        end
    end
    return table.concat(bitmap)
end

if type(namespace)=="table" then namespace.NetworkProbe=Probe end
return Probe
