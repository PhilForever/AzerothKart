-- One-shot backend GO gate. Pure Lua: explicit clock, geometry and modules.
local _, namespace = ...
local RaceStart = {}
RaceStart.MAX_CLOCK_MS = 36^7-1
RaceStart.MAX_LATE_MS = 250

-- Tokens expose no reusable ticket or mutable authoritative state. Collection
-- of an unused token also collects its private context.
local gates = setmetatable({}, {__mode="k"})
local fields = {
    session=true, role=true, seed=true, localEpochMS=true, hostEpochMS=true,
    offsetLowMS=true, offsetHighMS=true, uncertaintyMS=true, peerAcknowledged=true,
}
local function finite(value)
    return type(value)=="number" and value==value and value>-math.huge and value<math.huge
end
local function integer(value,low,high)
    return finite(value) and value%1==0 and value>=low and value<=high
end
local function plain(value) return type(value)=="table" and getmetatable(value)==nil end
local function copy(value,seen)
    if type(value)~="table" then return value end
    assert(getmetatable(value)==nil,"plain track data required")
    if seen[value] then return seen[value] end
    local result={}
    seen[value]=result
    for key,item in pairs(value) do
        assert(type(key)=="string" or type(key)=="number","plain track keys required")
        result[key]=copy(item,seen)
    end
    return result
end
local function validTicket(ticket)
    if not plain(ticket) then return false end
    for key in pairs(ticket) do if not fields[key] then return false end end
    local maximum=RaceStart.MAX_CLOCK_MS
    if type(ticket.session)~="string" or not ticket.session:match("^[0-9A-Z][0-9A-Z][0-9A-Z][0-9A-Z][0-9A-Z][0-9A-Z]$")
        or (ticket.role~="host" and ticket.role~="guest")
        or not integer(ticket.seed,0,2147483647)
        or not integer(ticket.localEpochMS,0,maximum)
        or not integer(ticket.hostEpochMS,0,maximum)
        or not integer(ticket.offsetLowMS,-maximum,maximum)
        or not integer(ticket.offsetHighMS,-maximum,maximum)
        or not finite(ticket.uncertaintyMS) then return false end
    local width=ticket.offsetHighMS-ticket.offsetLowMS
    if width<0 or width>2004 or ticket.uncertaintyMS<width/2
        or ticket.uncertaintyMS>1002 then return false end
    if ticket.role=="host" then
        return ticket.localEpochMS==ticket.hostEpochMS and ticket.peerAcknowledged==true
    end
    return ticket.localEpochMS==ticket.hostEpochMS+math.floor((ticket.offsetLowMS+ticket.offsetHighMS)/2)
        and ticket.peerAcknowledged==false
end
local function validTrack(track)
    if not plain(track) or type(track.id)~="string" or track.id==""
        or not integer(track.version,1,1295) or not finite(track.width) or track.width<=0
        or not finite(track.height) or track.height<=0 or type(track.spawn)~="function"
        or type(track.isDrivable)~="function" or type(track.crossesGate)~="function"
        or not finite(track.checkpointMaxStep) or track.checkpointMaxStep<=0
        or not plain(track.gates) or #track.gates==0 then return false end
    for index=1,#track.gates do
        local gate=track.gates[index]
        if not plain(gate) then return false end
        for _,field in ipairs({"ax","ay","bx","by","nx","ny"}) do
            if not finite(gate[field]) then return false end
        end
    end
    return true
end

function RaceStart.new(ticket,track,physicsVersion,kartId)
    if not validTicket(ticket) then return nil,"ticket" end
    if not integer(physicsVersion,1,1295) then return nil,"physics_version" end
    if kartId~=nil and (type(kartId)~="string" or #kartId<1 or #kartId>64
        or not kartId:match("^[a-z0-9_]+$")) then return nil,"kart" end
    if not validTrack(track) then return nil,"track" end
    local ok,captured=pcall(copy,track,{})
    if not ok then return nil,"track" end
    -- Data is copied; function closures remain the supplied geometry functions.
    -- Existing track modules/factories must stay read-only after construction.
    local token={}
    gates[token]={ticket=copy(ticket,{}),track=captured,physicsVersion=physicsVersion,kartId=kartId}
    return token
end

function RaceStart.cancel(gate)
    local context=gates[gate]
    if not context then return false end
    context.closed=true
    return true
end

function RaceStart.take(gate,nowMS,physics,race,checkpoints,laps)
    local context=gates[gate]
    if not context then return nil,"gate" end
    if context.closed then return nil,"closed" end
    if not integer(nowMS,0,RaceStart.MAX_CLOCK_MS)
        or (context.lastMS and nowMS<context.lastMS) then
        context.closed=true
        return nil,"clock"
    end
    context.lastMS=nowMS
    local ticket=context.ticket
    if nowMS<ticket.localEpochMS then return nil,"waiting" end
    -- Close before calling dependencies: a thrown initializer or a reentrant
    -- caller cannot award a second start or retry a partly-created simulation.
    context.closed=true
    if nowMS-ticket.localEpochMS>RaceStart.MAX_LATE_MS then return nil,"late" end
    local version=type(physics)=="table" and physics.VERSION
    local features=context.track.boostOnGrass==true or context.track.layered==true or
        (type(context.track.pads)=="table" and next(context.track.pads)~=nil)
    if features and type(physics)=="table" and type(physics.versionForTrack)=="function" then
        local ok,value=pcall(physics.versionForTrack,context.track)
        version=ok and value or nil
    end
    if features and (type(physics)~="table" or type(physics.versionForTrack)~="function") then version=nil end
    if version~=context.physicsVersion then
        return nil,"physics_version"
    end
    if type(physics.new)~="function" or not finite(physics.FIXED_DT) or physics.FIXED_DT<=0
        or type(race)~="table" or type(race.newRunning)~="function"
        or type(checkpoints)~="table" or type(checkpoints.new)~="function"
        or type(checkpoints.step)~="function" or type(laps)~="table"
        or type(laps.new)~="function" or type(laps.step)~="function" then
        return nil,"dependencies"
    end
    -- Validate the captured identity, never retain a caller-supplied parameter
    -- table. A missing optional ID preserves legacy balanced initialization.
    if context.kartId~=nil then
        if type(physics.GetHandling)~="function" then return nil,"dependencies" end
        local valid,handling=pcall(physics.GetHandling,context.kartId)
        if not valid or not plain(handling) then return nil,"kart" end
    end
    local ok,vehicle,progress=pcall(function()
        return physics.new(context.track),race.newRunning(context.track,checkpoints,laps,0)
    end)
    if not ok or type(vehicle)~="table" or type(progress)~="table" then
        return nil,"initialization"
    end
    return {
        session=ticket.session, role=ticket.role, seed=ticket.seed,
        trackId=context.track.id, trackVersion=context.track.version,
        physicsVersion=context.physicsVersion, localEpochMS=ticket.localEpochMS,
        hostEpochMS=ticket.hostEpochMS, uncertaintyMS=ticket.uncertaintyMS,
        peerAcknowledged=ticket.peerAcknowledged, track=context.track,
        vehicle=vehicle, race=progress, fixedDt=physics.FIXED_DT, kartId=context.kartId,
    }
end

if type(namespace)=="table" then namespace.RaceStart=RaceStart end
return RaceStart
