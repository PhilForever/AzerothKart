-- Pure two-peer, fixed-profile agreement and deterministic starting grid.
-- Native sender/channel authentication belongs to SessionTransport.
local _, namespace = ...
local Grid = {PREFIX="AZKGRD1", VERSION=1, MAX_BYTES=12, SEND_INTERVAL_MS=500,
    RETRY_INTERVAL_MS=2000, MAX_ATTEMPTS=3, DURATION_MS=10000,
    MAX_EVENTS=64, MAX_EVENTS_PER_SECOND=8, MAX_QUEUE=8, MAX_TIME=36^7-1}
local kartIds = {"goblin_mortar_trike", "steam_tank", "dwarven_biker", "dwarf_car",
    "orc_demolisher", "meat_wagon", "glaive_thrower", "gryphon_rider", "gyrocopter",
    "goblin_drag_car"}
Grid.KART_IDS={}
local codes, ids = {basic="Z"}, {Z="basic"}
for index,id in ipairs(kartIds) do
    Grid.KART_IDS[index]=id
    local code=tostring(index-1)
    codes[id],ids[code]=code,id
end
local states=setmetatable({}, {__mode="k"})
local function plain(v) return type(v)=="table" and getmetatable(v)==nil end
local function finite(v) return type(v)=="number" and v==v and v>-math.huge and v<math.huge end
local function integer(v,lo,hi) return finite(v) and v%1==0 and v>=lo and v<=hi end
local function session(v) return type(v)=="string" and #v==6 and not v:find("[^A-Z0-9]") end
local function copy(v)
    if type(v)~="table" then return v end
    local out={}; for k,item in pairs(v) do out[k]=copy(item) end; return out
end

function Grid.encode(message)
    if not plain(message) then return nil,"invalid_message" end
    for k in pairs(message) do
        if k~="kind" and k~="session" and k~="kartId" then return nil,"invalid_fields" end
    end
    local tag=message.kind=="PROFILE" and "P" or message.kind=="ACK" and "A"
    if not tag then return nil,"invalid_kind" end
    if not session(message.session) then return nil,"invalid_session" end
    local code=type(message.kartId)=="string" and codes[message.kartId]
    if not code then return nil,"invalid_kart" end
    return "1"..tag..message.session.."001"..code
end

function Grid.decode(payload)
    if type(payload)~="string" or #payload~=Grid.MAX_BYTES then return nil,"invalid_size" end
    if payload:find("[^A-Z0-9]") then return nil,"invalid_alphabet" end
    if payload:sub(1,1)~="1" then return nil,"invalid_version" end
    local tag=payload:sub(2,2)
    local kind=tag=="P" and "PROFILE" or tag=="A" and "ACK"
    if not kind then return nil,"invalid_kind" end
    if payload:sub(9,11)~="001" then return nil,"invalid_sequence" end
    local id=ids[payload:sub(12,12)]
    if not id then return nil,"invalid_kart" end
    return {kind=kind,session=payload:sub(3,8),kartId=id}
end

local function close(s,reason)
    if s.phase=="closed" then return end
    s.phase,s.reason,s.pendingACK,s.deferred="closed",reason,false,{}
end
local function advance(s,now)
    if not integer(now,0,Grid.MAX_TIME) or now<s.lastNow then
        close(s,"clock_error"); return false,"clock_error"
    end
    s.lastNow=now
    if s.phase=="closed" then return false,s.reason end
    if s.phase~="ready" and (now>=s.deadline or (not s.profileAcknowledged
        and s.profileAttempts>=Grid.MAX_ATTEMPTS and now>=s.nextProfileAt)) then
        close(s,"timeout"); return false,"timeout"
    end
    return true
end
local function ready(s)
    if s.phase~="closed" and s.profileAcknowledged and s.peerKartId and s.peerACKAccepted then
        s.phase="ready"
    end
end
local function process(s,message)
    if message.kind=="PROFILE" then
        if s.peerKartId and s.peerKartId~=message.kartId then
            close(s,"contradiction"); return false,"contradiction"
        end
        if s.peerKartId then s.stats.duplicates=s.stats.duplicates+1 end
        s.peerKartId,s.pendingACK=message.kartId,true
        ready(s)
        return true
    end
    if message.kartId~=s.localKartId or s.profileAccepted<1 then
        s.stats.rejected=s.stats.rejected+1; return false,"unexpected_ack"
    end
    if s.profileAcknowledged then s.stats.duplicates=s.stats.duplicates+1 end
    s.profileAcknowledged=true
    ready(s)
    return true
end

function Grid.new(options,now)
    if not plain(options) or not session(options.session)
        or (options.role~="host" and options.role~="guest")
        or type(options.kartId)~="string" or not codes[options.kartId]
        or not integer(now,0,Grid.MAX_TIME-Grid.DURATION_MS) then return nil,"invalid_options" end
    for key in pairs(options) do
        if key~="session" and key~="role" and key~="kartId" then return nil,"invalid_options" end
    end
    local token={}
    states[token]={session=options.session,role=options.role,localKartId=options.kartId,
        phase="exchanging",lastNow=now,deadline=now+Grid.DURATION_MS,
        nextProfileAt=now,profileAttempts=0,profileAccepted=0,profileAcknowledged=false,
        pendingACK=false,peerACKAccepted=false,deferred={},eventCount=0,recentEvents={},
        stats={sendAttempts=0,sendsAccepted=0,retries=0,received=0,rejected=0,duplicates=0}}
    return token
end

function Grid.update(token,now,sendFn,sendAllowed)
    local s=states[token]
    if not s then return false,"invalid_token" end
    if s.sending then return false,"send_in_progress" end
    if type(sendFn)~="function" or (sendAllowed~=nil and type(sendAllowed)~="boolean") then
        return false,"invalid_argument"
    end
    local active,why=advance(s,now); if not active then return false,why end
    if sendAllowed==false then return false,"budget" end
    if s.lastSend and now-s.lastSend<Grid.SEND_INTERVAL_MS then return false,"pacing" end
    local kind,id
    if s.pendingACK then kind,id="ACK",s.peerKartId
    elseif not s.profileAcknowledged and now>=s.nextProfileAt then kind,id="PROFILE",s.localKartId
    else return false,"waiting" end
    local payload=Grid.encode({kind=kind,session=s.session,kartId=id})
    s.lastSend,s.sending=now,true
    s.stats.sendAttempts=s.stats.sendAttempts+1
    if kind=="PROFILE" then
        s.profileAttempts=s.profileAttempts+1
        if s.profileAttempts>1 then s.stats.retries=s.stats.retries+1 end
        s.nextProfileAt=now+Grid.RETRY_INTERVAL_MS
    else s.pendingACK=false end
    local ok,outcome=pcall(sendFn,payload)
    s.sending=false
    if s.phase=="closed" then return true,s.reason end -- A reentrant Stop always wins.
    if not ok or outcome~="accepted" then
        local reason=not ok and "send_error" or outcome=="failed" and "send_failed"
            or outcome=="throttled" and "send_throttled" or "send_unknown"
        close(s,reason); return true,reason
    end
    s.stats.sendsAccepted=s.stats.sendsAccepted+1
    if kind=="PROFILE" then s.profileAccepted=s.profileAccepted+1
    else s.peerACKAccepted=true end
    local deferred=s.deferred; s.deferred={}
    for _,message in ipairs(deferred) do
        if s.phase=="closed" then break end
        process(s,message)
    end
    ready(s)
    return true,"accepted"
end

function Grid.receive(token,now,payload)
    local s=states[token]; if not s then return false,"invalid_token" end
    local active,why=advance(s,now); if not active then return false,why end
    local message,problem=Grid.decode(payload)
    if not message then s.stats.rejected=s.stats.rejected+1; return false,problem end
    if message.session~=s.session then return false,"unrelated" end
    s.eventCount,s.stats.received=s.eventCount+1,s.stats.received+1
    if s.eventCount>Grid.MAX_EVENTS then close(s,"event_limit"); return false,s.reason end
    local recent={}
    for _,at in ipairs(s.recentEvents) do if now-at<1000 then recent[#recent+1]=at end end
    if #recent>=Grid.MAX_EVENTS_PER_SECOND then close(s,"peer_flood"); return false,s.reason end
    recent[#recent+1]=now; s.recentEvents=recent
    if s.sending then
        if #s.deferred>=Grid.MAX_QUEUE then close(s,"queue_limit"); return false,s.reason end
        s.deferred[#s.deferred+1]=message
        return true,"deferred"
    end
    return process(s,message)
end

function Grid.stop(token,now,reason)
    local s=states[token]; if not s then return false,"invalid_token" end
    if type(reason)~="string" or #reason<1 or #reason>48 or reason:find("[^a-z_]") then
        return false,"invalid_argument"
    end
    local active,why=advance(s,now); if not active then return false,why end
    close(s,reason); return true
end

function Grid.view(token)
    local s=states[token]; if not s then return nil,"invalid_token" end
    return {session=s.session,role=s.role,phase=s.phase,reason=s.reason,
        localKartId=s.localKartId,peerKartId=s.peerKartId,deadlineMS=s.deadline,
        profileAttempts=s.profileAttempts,profileAccepted=s.profileAccepted,
        localProfileAcknowledged=s.profileAcknowledged,peerACKAccepted=s.peerACKAccepted,
        hasPendingOutput=s.phase~="closed" and (s.pendingACK or not s.profileAcknowledged),
        stats=copy(s.stats)}
end

function Grid.pose(track,role)
    if not plain(track) or (role~="host" and role~="guest")
        or not finite(track.width) or not finite(track.height) or track.width<=0 or track.height<=0
        or type(track.spawn)~="function" or type(track.isDrivable)~="function" then return nil,"track" end
    local ok,spawn=pcall(track.spawn)
    if not ok or not plain(spawn) or not finite(spawn.x) or not finite(spawn.y)
        or not finite(spawn.heading) then return nil,"spawn" end
    local dx,dy=-math.sin(spawn.heading)*18,math.cos(spawn.heading)*18
    local host={x=spawn.x-dx,y=spawn.y-dy,heading=spawn.heading}
    local guest={x=spawn.x+dx,y=spawn.y+dy,heading=spawn.heading}
    for _,pose in ipairs({host,guest}) do
        if not finite(pose.x) or not finite(pose.y) or pose.x<0 or pose.x>track.width
            or pose.y<0 or pose.y>track.height then return nil,"grid_bounds" end
        local legal,drivable=pcall(track.isDrivable,pose.x,pose.y)
        if not legal or drivable~=true then return nil,"grid_clearance" end
    end
    if role=="host" then return host,guest end
    return guest,host
end

if type(namespace)=="table" then namespace.RaceGrid=Grid end
return Grid
