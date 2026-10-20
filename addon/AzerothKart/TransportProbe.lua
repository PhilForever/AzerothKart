-- Guarded, opt-in WHISPER experiment adapter. No traffic or registration on load.
local _, AK = ...
assert(type(AK) == "table", "addon namespace required")
local Probe = assert(AK.NetworkProbe, "pure network probe required")
local Transport = {used={}, usedCount=0}
AK.TransportProbe = Transport

local function report(message)
    if Transport.reporter then Transport.reporter(message)
    elseif DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("Azeroth Kart net: "..message)
    else print("Azeroth Kart net: "..message) end
end

local function active()
    return Transport.state and Transport.state.phase ~= "stopped"
end

local function clock()
    if type(GetTime) ~= "function" then return nil end
    local ok,value = pcall(function()
        local result = GetTime()
        if type(result) == "number" and result == result and result >= 0
            and result < math.huge then return result end
    end)
    if ok then return value end
end

local function blocked()
    if AK.UI and AK.UI.active then return "local drive active" end
    if type(InCombatLockdown) ~= "function" then return "combat API unavailable" end
    local ok,clear = pcall(function() return InCombatLockdown() == false end)
    if not ok or not clear then return "combat or unavailable combat state" end
end

local function cleanup()
    local frame = Transport.frame
    if not frame then return end
    pcall(frame.SetScript,frame,"OnUpdate",nil)
    pcall(frame.UnregisterEvent,frame,"CHAT_MSG_ADDON")
end

local function finished()
    if not Transport.state or Transport.state.phase ~= "stopped" then return end
    cleanup()
    if not Transport.notified then
        Transport.notified = true
        report("Stopped: "..tostring(Transport.state.reason).."; /akart net report")
    end
end

function Transport.Init(frame, reporter)
    Transport.frame,Transport.reporter = frame,reporter
end

function Transport.Stop(reason)
    if active() then
        Probe.stop(Transport.state,Transport.lastNow or 0,reason or "manual stop")
        finished()
    else cleanup() end
end

local function classify(raw)
    local kind = type(raw)
    if kind ~= "number" and kind ~= "nil" and kind ~= "boolean" then return "unknown",kind end
    if kind == "number" and (raw ~= raw or raw == math.huge or raw == -math.huge) then
        return "unknown","nonfinite"
    end
    if raw == Transport.sendSuccess then return "accepted",raw end
    if Transport.throttleCodes[raw] then return "throttled",raw end
    if Transport.failureCodes[raw] then return "failed",raw end
    return "unknown",raw
end

local function send(kind,payload)
    -- Every packet is addon-owned printable data, never a secret game value.
    local raw = Transport.sendAPI(Probe.PREFIX,payload,"WHISPER",Transport.state.options.peer)
    local ok,outcome,safeRaw = pcall(classify,raw)
    if not ok then error("opaque send result") end -- Abort; never unwrap protected values.
    return outcome,safeRaw
end

function Transport.Update()
    if not active() then return end
    local reason = blocked()
    if reason then Transport.Stop(reason); return end
    local now = clock()
    if not now then Transport.Stop("clock unavailable"); return end
    if now < Transport.lastNow then Transport.Stop("clock moved backwards"); return end
    Transport.lastNow = now
    local ok = pcall(Probe.update,Transport.state,now,send)
    if not ok then Transport.Stop("probe update refused") end
    finished()
end

function Transport.Message(prefix,payload,channel,sender)
    if not active() or prefix ~= Probe.PREFIX then return end
    local reason = blocked()
    if reason then Transport.Stop(reason); return end
    local now = clock()
    if not now then Transport.Stop("clock unavailable"); return end
    if now < Transport.lastNow then Transport.Stop("clock moved backwards"); return end
    Transport.lastNow = now
    local ok = pcall(Probe.receive,Transport.state,now,prefix,payload,channel,sender,send)
    if not ok then Transport.Stop("probe receive refused") end
    finished()
end

function Transport.HandleEvent(event)
    if event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_LEAVING_WORLD"
        or event == "PLAYER_LOGOUT" then Transport.Stop(event) end
end

local sendNames = {"Success","InvalidPrefix","InvalidMessage","AddonMessageThrottle",
    "InvalidChatType","NotInGroup","TargetRequired","InvalidChannel","ChannelThrottle",
    "GeneralError","NotInGuild","AddOnMessageLockdown","TargetOffline"}

local function capabilities()
    if not Transport.frame or type(C_ChatInfo) ~= "table"
        or type(C_ChatInfo.RegisterAddonMessagePrefix) ~= "function"
        or type(C_ChatInfo.SendAddonMessage) ~= "function" or type(Enum) ~= "table"
        or type(Enum.RegisterAddonMessagePrefixResult) ~= "table"
        or type(Enum.SendAddonMessageResult) ~= "table" then return false end
    local register,results = Enum.RegisterAddonMessagePrefixResult,Enum.SendAddonMessageResult
    local function code(value)
        return type(value) == "number" and value >= 0 and value <= 32 and value % 1 == 0
    end
    if not code(register.Success) or not code(register.DuplicatePrefix)
        or register.Success == register.DuplicatePrefix then return false end
    local seen,failed,throttled = {},{},{}
    for _,name in ipairs(sendNames) do
        local value = results[name]
        if not code(value) or seen[value] then return false end
        seen[value] = true
        if name ~= "Success" then failed[value] = true end
    end
    throttled[results.AddonMessageThrottle],throttled[results.ChannelThrottle] = true,true
    Transport.sendAPI,Transport.sendSuccess = C_ChatInfo.SendAddonMessage,results.Success
    Transport.failureCodes,Transport.throttleCodes = failed,throttled
    if not Transport.registered then
        local ok,raw = pcall(C_ChatInfo.RegisterAddonMessagePrefix,Probe.PREFIX)
        Transport.registrationAttempted = true
        Transport.registrationError = not ok
        if ok then Transport.registrationResult = raw else Transport.registrationResult = nil end
        if not ok or (raw ~= register.Success and raw ~= register.DuplicatePrefix) then return false end
        Transport.registered = true
    end
    return true
end

local function rawTag(value)
    local ok,tag = pcall(function()
        local kind = type(value)
        if kind == "nil" then return "nil" end
        if kind == "number" or kind == "boolean" then return kind..":"..tostring(value) end
        return kind
    end)
    return ok and tag or "opaque"
end

local function arm(options)
    if active() then report("Stop the existing probe first"); return false end
    local reason = blocked()
    if reason then report("Refused: "..reason); return false end
    local now = clock()
    if not now then report("Refused: clock unavailable"); return false end
    local state,errorMessage = Probe.new(options,now)
    if not state then report("Refused: "..tostring(errorMessage)); return false end
    if Transport.used[state.options.session] then report("Refused: use a fresh session ID"); return false end
    if Transport.usedCount >= 64 then report("Refused: 64-session limit; reload and choose a fresh ID"); return false end
    local ok,ready = pcall(capabilities)
    if not ok or not ready then
        report("Refused: ChatInfo APIs/enums/prefix registration unavailable (raw="..
            (Transport.registrationError and "error" or rawTag(Transport.registrationResult))..")")
        return false
    end
    local eventOK,result = pcall(Transport.frame.RegisterEvent,Transport.frame,"CHAT_MSG_ADDON")
    if not eventOK or result == false then cleanup(); report("Refused: CHAT_MSG_ADDON unavailable"); return false end
    local updateOK = pcall(Transport.frame.SetScript,Transport.frame,"OnUpdate",Transport.Update)
    if not updateOK then cleanup(); report("Refused: probe update unavailable"); return false end
    Transport.state,Transport.lastNow,Transport.notified = state,now,false
    Transport.used[state.options.session],Transport.usedCount = true,Transport.usedCount+1
    report(("Armed %s session=%s WHISPER %.1f DATA/s bytes=%d seconds=%d; peer must opt in")
        :format(options.mode,state.options.session,state.options.rate,state.options.bytes,state.options.duration))
    return true
end

local function codes(values)
    local keys,parts = {},{}
    for key in pairs(values or {}) do keys[#keys+1] = key end
    table.sort(keys)
    for _,key in ipairs(keys) do parts[#parts+1] = key.."="..tostring(values[key]) end
    return #parts > 0 and table.concat(parts,",") or "none"
end

local function value(item)
    return type(item) == "number" and ("%.3f"):format(item) or "NA"
end

function Transport.Report()
    if not Transport.state then report("Idle: no experiment run"); return end
    local s = Probe.summary(Transport.state)
    local o = Transport.state.options
    report(("session=%s phase=%s reason=%s rate=%.1f bytes=%d seconds=%d elapsedSeconds=%.3f prefixRaw=%s")
        :format(o.session,Transport.state.phase,tostring(Transport.state.reason or "none"),
            o.rate,o.bytes,o.duration,s.elapsed_seconds,rawTag(Transport.registrationResult)))
    report(("DATA calls=%d accepted=%d failed=%d unknown=%d planned=%d missedSlots=%d; ACK calls=%d accepted=%d failed=%d unknown=%d")
        :format(s.data_attempts,s.data_enqueue_accepted,s.data_enqueue_failed,s.data_enqueue_unknown,
            s.scheduled_data_attempts,s.missed_slots,s.ack_attempts,s.ack_enqueue_accepted,
            s.ack_enqueue_failed,s.ack_enqueue_unknown))
    report(("RX total=%d unique=%d rejected=%d duplicate=%d reordered=%d; matchedACK=%d timedOut=%d late=%d outstanding=%d")
        :format(s.rx_total,s.rx_unique,s.rx_rejected,s.duplicates,s.reordered_unique,
            s.ack_matched_unique,s.ack_timeouts_at_deadline,s.late_acks,s.outstanding_after_drain))
    report(("throttle=%d errors=%d attemptedPayloadBytes=%d prefixBytes=%d; DATA codes={%s}; ACK codes={%s}; rejects={%s}")
        :format(s.throttle_events,s.send_errors,s.aggregate_attempted_bytes,
            (s.data_attempts+s.ack_attempts)*#Probe.PREFIX,
            codes(Transport.state.data_codes),codes(Transport.state.ack_codes),codes(Transport.state.reject_reasons)))
    report(("RTT ms n=%d p50=%s p95=%s p99=%s max=%s")
        :format(s.rtt_samples,value(s.rtt_p50_ms),value(s.rtt_p95_ms),value(s.rtt_p99_ms),value(s.rtt_max_ms)))
    report(("arrival gaps ms n=%d p50=%s p95=%s p99=%s max=%s; nearest-rank")
        :format(s.gap_samples,value(s.gap_p50_ms),value(s.gap_p95_ms),value(s.gap_p99_ms),value(s.gap_max_ms)))
    report("Local acceptance is not delivery; missing ACK is not proven loss. /akart net evidence for reconciliation.")
end

function Transport.Evidence()
    if not Transport.state then report("Idle: no experiment run"); return end
    for _,kind in ipairs({"sent","received","acks_sent","acks_received"}) do
        local bitmap = Probe.evidence(Transport.state,kind)
        for index=1,#bitmap,160 do
            report(("%s session=%s seq=%d..%d %s"):format(kind,Transport.state.options.session,
                index,math.min(index+159,#bitmap),bitmap:sub(index,index+159)))
        end
    end
    report("Evidence: sent/acks_sent 1=accepted f=failed u=unknown .=not attempted; received 1=seen; acks_received 1=matched")
end

function Transport.Command(argument)
    if type(argument) ~= "string" or #argument > 256 then report("Invalid net command"); return false end
    local words = {}
    for word in argument:gmatch("%S+") do
        if #words >= 6 then report("Too many net arguments"); return false end
        words[#words+1] = word
    end
    if #words == 1 then
        if words[1] == "stop" then Transport.Stop("manual stop"); return true end
        if words[1] == "report" then Transport.Report(); return true end
        if words[1] == "evidence" then Transport.Evidence(); return true end
    end
    if (words[1] ~= "start" and words[1] ~= "listen") or #words < 3 then
        report("/akart net start|listen Peer-Realm ABC123 [pps] [bytes] [seconds]; stop|report|evidence")
        return false
    end
    local rate,bytes,duration = 0.5,16,120
    if words[4] then rate = tonumber(words[4]) end
    if words[5] then bytes = tonumber(words[5]) end
    if words[6] then duration = tonumber(words[6]) end
    if not rate or not bytes or not duration then report("Invalid numeric net argument"); return false end
    return arm({mode=words[1] == "start" and "send" or "listen",peer=words[2],
        session=words[3],rate=rate,bytes=bytes,duration=duration})
end

return Transport
