-- Bounded backend race owner and observational peer telemetry. Pure Lua.
-- No native transport, UI activation, shared winner or opponent collision.
local _, namespace = ...
local Live = {MAX_DURATION_MS=1800000, PEER_TIMEOUT_MS=5000, STALE_MS=1500}
local runs, claimed = setmetatable({}, {__mode="k"}), setmetatable({}, {__mode="k"})
local reasons = {stopped=true, combat=true, world_leave=true, logout=true,
    focus_lost=true, peer_stopped=true, peer_timeout=true, clock=true,
    duration=true, sequence=true, peer_flood=true, simulation=true,
    send_failed=true, send_unknown=true, send_throttled=true, error=true}
local controls = {accelerate=true, brake=true, left=true, right=true, drift=true}
local function finite(v) return type(v)=="number" and v==v and v>-math.huge and v<math.huge end
local function integer(v, low, high) return finite(v) and v%1==0 and v>=low and v<=high end
local function plain(v) return type(v)=="table" and getmetatable(v)==nil end
local function copy(v, seen)
    if type(v)~="table" then return v end
    assert(plain(v), "plain data required")
    seen=seen or {}
    if seen[v] then return seen[v] end
    local out={}; seen[v]=out
    for key,value in pairs(v) do out[key]=copy(value,seen) end
    return out
end
local function identity(v)
    if type(v)~="string" or #v<1 or #v>96 or v:find("[%z\001-\031\127|]") then return nil end
    local out=v:gsub(" +"," "):match("^ *(.-) *$")
    if out=="" then return nil end
    return (out:gsub("[A-Z]",function(c) return string.char(c:byte()+32) end))
end
local function close(s, reason)
    if s.phase=="closed" then return end
    s.phase, s.reason, s.pendingTerminal="closed",reason,0
    s.race=s.modules.Race.stop(s.race,reason,reason=="combat")
    s.previous=s.vehicle
end
local function time(s, now)
    if not integer(now,0,36^7-1) or now<s.lastNow then close(s,"clock"); return false,"clock" end
    s.lastNow=now
    if s.phase=="closed" then return false,s.reason end
    if now-s.startedAt>=Live.MAX_DURATION_MS then close(s,"duration"); return false,"duration" end
    if now-s.peerAt>=Live.PEER_TIMEOUT_MS then close(s,"peer_timeout"); return false,"peer_timeout" end
    if s.remote and s.remote.status=="running" and now-s.peerProgressAt>=Live.PEER_TIMEOUT_MS then
        close(s,"peer_timeout"); return false,"peer_timeout"
    end
    return true
end
local function dependencies(m)
    if not plain(m) then return false end
    for module,methods in pairs({Physics={"step"},Race={"step","stop"},
        Checkpoints={"step"},Laps={"step"},Loop={"new","advance"},LiveProtocol={"encode","decode"}}) do
        if type(m[module])~="table" then return false end
        for _,method in ipairs(methods) do if type(m[module][method])~="function" then return false end end
    end
    return m.LiveProtocol.PREFIX=="AZKRUN2" and m.LiveProtocol.MAX_BYTES==40
        and m.Physics.FIXED_DT==1/60
end

-- Takes one actual tick-zero RaceStart bundle; copies data, preserving only
-- read-only module/geometry functions. Public token fields have no authority.
function Live.new(bundle, peer, nowMS, modules)
    if not plain(bundle) or claimed[bundle] then return nil,"bundle" end
    if not dependencies(modules) then return nil,"dependencies" end
    if not identity(peer) then return nil,"peer" end
    local b=bundle
    if type(b.session)~="string" or not b.session:match("^[A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9]$")
        or (b.role~="host" and b.role~="guest") or not integer(b.seed,0,2147483647)
        or not integer(b.localEpochMS,0,36^7-1) or not integer(b.hostEpochMS,0,36^7-1)
        or not integer(nowMS,b.localEpochMS,b.localEpochMS+250)
        or b.fixedDt~=1/60 or b.physicsVersion~=modules.Physics.VERSION
        or (b.kartId~=nil and (type(b.kartId)~="string" or #b.kartId<1 or #b.kartId>64
            or not b.kartId:match("^[a-z0-9_]+$")))
        or not plain(b.track) or b.track.id~=b.trackId or b.track.version~=b.trackVersion
        or not finite(b.track.width) or not finite(b.track.height)
        or b.track.width<=0 or b.track.width>11663.75 or b.track.height<=0 or b.track.height>11663.75
        or type(b.track.gates)~="table" or #b.track.gates<1 or #b.track.gates>8
        or not plain(b.vehicle) or b.vehicle.tick~=0 or not finite(b.vehicle.x) or not finite(b.vehicle.y)
        or b.vehicle.x<0 or b.vehicle.x>b.track.width or b.vehicle.y<0 or b.vehicle.y>b.track.height
        or not finite(b.vehicle.heading) or not finite(b.vehicle.speed)
        or not plain(b.race) or b.race.status~="running" or b.race.startTick~=0
        or b.race.lastTick~=0 or b.race.totalTicks~=0 or b.race.targetLaps~=3
        or b.race.countdownTicks~=0 or not plain(b.race.laps) or b.race.laps.completedLaps~=0
        or b.race.laps.lastTick~=0 or b.race.laps.lapStartTick~=0 or b.race.laps.currentLapTicks~=0
        or not plain(b.race.laps.checkpoints) or b.race.laps.checkpoints.lastTick~=0
        or b.race.laps.checkpoints.passed~=0 or b.race.laps.checkpoints.nextGate~=1
        or b.race.laps.checkpoints.complete~=false then return nil,"bundle" end
    for _,key in ipairs({"speed","impacts","driftDirection","driftTicks","driftTier",
        "driftGraceTicks","boostTicks","slipAngle","steering"}) do
        if b.vehicle[key]~=0 then return nil,"bundle" end
    end
    if b.vehicle.drifting~=false or (b.vehicle.surface~="road" and b.vehicle.surface~="grass"
        and b.vehicle.surface~="wall") then return nil,"bundle" end
    local ok,captured=pcall(copy,b)
    if not ok then return nil,"bundle" end
    local token={}
    local m={}; for k,v in pairs(modules) do m[k]=v end
    -- Reserve before invoking injected code; an initializer failure consumes
    -- this bundle too, rather than permitting a reentrant or partial retry.
    claimed[bundle]=true
    if captured.kartId~=nil then
        if type(m.Physics.GetHandling)~="function" then return nil,"dependencies" end
        local valid,handling=pcall(m.Physics.GetHandling,captured.kartId)
        if not valid or not plain(handling) then return nil,"bundle" end
    end
    local clockOK,clock=pcall(m.Loop.new,b.fixedDt,5)
    if not clockOK or not plain(clock) or clock.dt~=b.fixedDt or clock.maxSteps~=5 then
        return nil,"dependencies"
    end
    for _,key in ipairs({"accumulator","frames","steps","elapsedSeconds","droppedSeconds",
        "hitchFrames","maxElapsed","lastSteps"}) do
        if clock[key]~=0 then return nil,"dependencies" end
    end
    runs[token]={modules=m, bundle=captured, kartId=captured.kartId, track=captured.track, vehicle=captured.vehicle,
        previous=captured.vehicle, race=captured.race, clock=clock, peer=peer, peerKey=identity(peer),
        phase="running", startedAt=nowMS, lastNow=nowMS, advancedAt=nowMS,
        peerAt=nowMS, peerProgressAt=nowMS, sequence=0, remoteSequence=0,
        sentAt=nil, sends={}, incoming={}, pendingTerminal=0, busy=false,
        counters={attempted=0,accepted=0,received=0,rejected=0,stale=0}}
    return token
end

function Live.advance(token, nowMS, input)
    local s=runs[token]; if not s then return nil,"run" end
    if s.busy then return nil,"busy" end
    if not plain(input) then return nil,"input" end
    local sampled={}
    for key,value in pairs(input) do
        if not controls[key] or type(value)~="boolean" then return nil,"input" end
        sampled[key]=value
    end
    local valid,why=time(s,nowMS); if not valid then return nil,why end
    local elapsed=(nowMS-s.advancedAt)/1000; s.advancedAt=nowMS
    if s.phase~="running" then return 0 end
    s.busy=true
    local ok,count=pcall(s.modules.Loop.advance,s.clock,elapsed,function(dt)
        local previous=s.vehicle
        local current=s.modules.Physics.step(previous,sampled,dt,s.track,s.kartId)
        local race=s.modules.Race.step(s.race,previous,current,s.track,s.modules.Checkpoints,s.modules.Laps)
        if s.phase=="closed" then return false end -- Stop from an injected callback wins.
        s.previous,s.vehicle,s.race=previous,current,race
        if race.status=="finished" then s.phase="finishing"; s.pendingTerminal=3; return false end
        if current.tick>=s.modules.LiveProtocol.MAX_TICK then close(s,"duration"); return false end
    end)
    s.busy=false
    if not ok then close(s,"simulation"); return nil,"simulation" end
    return count
end

local function packet(s)
    local p,v,r=s.modules.LiveProtocol,s.vehicle,s.race
    local turn=2*math.pi
    return p.encode({kind="STATE",session=s.bundle.session,sequence=s.sequence+1,tick=v.tick,
        x=math.floor(v.x*4+0.5)/4,y=math.floor(v.y*4+0.5)/4,
        headingQ=math.floor((v.heading%turn)/turn*46656+0.5)%46656,
        speedQ=math.floor(v.speed*10+0.5),driftTier=v.driftTier or 0,
        boosting=(v.boostTicks or 0)>0,completedLaps=r.laps.completedLaps,
        passed=r.laps.checkpoints.passed,status=r.status,
        sampleMS=math.max(0,s.advancedAt-s.bundle.localEpochMS)})
end

-- Only output path: latest pose, never a history queue, ACK or catch-up burst.
-- The future native adapter MUST additionally retain its persistent cross-phase
-- pacing gate; these per-run guards are not permission for a second sender.
function Live.update(token, nowMS, sendFn, sendAllowed)
    local s=runs[token]; if not s then return false,"run" end
    if s.busy then return false,"busy" end
    local valid,why=time(s,nowMS); if not valid then return false,why end
    if s.sequence>=s.modules.LiveProtocol.MAX_SEQUENCE then close(s,"sequence"); return false,"sequence" end
    if sendAllowed==false or (s.sentAt and nowMS-s.sentAt<500) then return false,"paced" end
    if type(sendFn)~="function" then return false,"sender" end
    while s.sends[1] and nowMS-s.sends[1].at>=1000 do table.remove(s.sends,1) end
    local ok,payload=pcall(packet,s)
    if not ok or not payload then close(s,"simulation"); return false,"simulation" end
    local bytes=#payload+#s.modules.LiveProtocol.PREFIX
    local spent=0; for _,attempt in ipairs(s.sends) do spent=spent+attempt.bytes end
    if #s.sends>=2 or spent+bytes>158 then return false,"paced" end
    s.sequence=s.sequence+1; s.sentAt=nowMS
    s.sends[#s.sends+1]={at=nowMS,bytes=bytes}
    s.counters.attempted=s.counters.attempted+1
    s.busy=true
    local sent,outcome=pcall(sendFn,payload,s.peer,s.modules.LiveProtocol.PREFIX)
    s.busy=false
    if not sent or outcome~="accepted" then
        local reason=outcome=="throttled" and "send_throttled" or
            (outcome=="unknown" and "send_unknown" or "send_failed")
        close(s,reason); return false,reason
    end
    s.counters.accepted=s.counters.accepted+1
    if s.phase=="finishing" then s.pendingTerminal=math.max(0,s.pendingTerminal-1) end
    if s.phase=="finishing" and s.pendingTerminal==0 and s.remote and s.remote.status=="finished" then
        close(s,"completed_unverified")
    end
    return true
end

function Live.receive(token, nowMS, prefix, payload, channel, sender)
    local s=runs[token]; if not s then return false,"run" end
    local p=s.modules.LiveProtocol
    if prefix~=p.PREFIX or channel~="WHISPER" or identity(sender)~=s.peerKey then return false,"unrelated" end
    local valid,why=time(s,nowMS); if not valid then return false,why end
    -- Scoped malformed/duplicate floods also count, with bounded storage.
    while s.incoming[1] and nowMS-s.incoming[1]>=1000 do table.remove(s.incoming,1) end
    if #s.incoming>=8 then close(s,"peer_flood"); return false,"peer_flood" end
    s.incoming[#s.incoming+1]=nowMS
    local function reject(reason) s.counters.rejected=s.counters.rejected+1; return false,reason end
    local ok,message=pcall(p.decode,payload)
    if not ok or not message then return reject("packet") end
    if message.session~=s.bundle.session then return reject("session") end
    if message.sequence<=s.remoteSequence then s.counters.stale=s.counters.stale+1; return false,"stale" end
    if message.x>s.track.width or message.y>s.track.height or message.passed>=#s.track.gates
        or (message.completedLaps==3)~=(message.status=="finished")
        or (message.status=="finished" and message.passed~=0) then return reject("bounds") end
    if s.remote and message.tick<s.remote.tick then return reject("tick") end
    if s.remote and message.sampleMS<s.remote.sampleMS then return reject("stamp") end
    if s.remote and s.remote.status=="finished" and message.status~="finished" then return reject("terminal") end
    -- Fresh sequence numbers with a frozen running tick are not fresh progress.
    if not s.remote or message.tick>s.remote.tick or message.status~="running" then s.peerProgressAt=nowMS end
    if nowMS-s.peerProgressAt>=Live.PEER_TIMEOUT_MS then close(s,"peer_timeout"); return false,"peer_timeout" end
    local remote={x=message.x,y=message.y,heading=message.headingQ/46656*(2*math.pi),
        speed=message.speedQ/10,tick=message.tick,driftTier=message.driftTier,boosting=message.boosting,
        completedLaps=message.completedLaps,passed=message.passed,status=message.status,receivedAtMS=nowMS}
    remote.sampleMS=message.sampleMS
    s.remotePrevious,s.remote=s.remote or remote,remote
    s.remoteSequence,s.peerAt=message.sequence,nowMS
    s.counters.received=s.counters.received+1
    if message.status=="stopped" or message.status=="interrupted" then close(s,"peer_stopped") end
    return true
end

function Live.stop(token, nowMS, reason)
    local s=runs[token]; if not s then return false,"run" end
    if s.phase=="closed" then return false,s.reason end
    if not integer(nowMS,s.lastNow,36^7-1) then close(s,"clock"); return false,"clock" end
    s.lastNow=nowMS
    close(s,reasons[reason] and reason or "error")
    return true
end

-- Copies only: received poses/progress are unverified observations, never local
-- physics corrections, checkpoint awards, standings or agreed finish results.
function Live.view(token)
    local s=runs[token]; if not s then return nil,"run" end
    local remote=copy(s.remote)
    if remote then remote.sampleAgeMS=math.max(0,s.lastNow-s.bundle.localEpochMS-remote.sampleMS) end
    return {phase=s.phase,reason=s.reason,session=s.bundle.session,role=s.bundle.role,peer=s.peer,
        trackId=s.bundle.trackId,trackVersion=s.bundle.trackVersion,physicsVersion=s.bundle.physicsVersion,
        localEpochMS=s.bundle.localEpochMS,hostEpochMS=s.bundle.hostEpochMS,
        uncertaintyMS=s.bundle.uncertaintyMS,peerAcknowledged=s.bundle.peerAcknowledged,
        vehicle=copy(s.vehicle),previous=copy(s.previous),race=copy(s.race),clock=copy(s.clock),
        alpha=s.phase=="running" and s.clock.accumulator/s.clock.dt or 1,
        remote=remote,remotePrevious=copy(s.remotePrevious),remoteVerified=false,
        elapsedMS=math.max(0,s.lastNow-s.bundle.localEpochMS),
        remoteAgeMS=s.remote and s.lastNow-s.remote.receivedAtMS or nil,
        remoteStale=not s.remote or s.lastNow-s.remote.receivedAtMS>Live.STALE_MS,
        resultVerified=false,sequence=s.sequence,remoteSequence=s.remoteSequence,
        counters=copy(s.counters)}
end

if type(namespace)=="table" then namespace.LiveRace=Live end
return Live
