-- Bounded community-score replication. Pure: explicit roster, time and send callback.
-- Native identity/lease checks, persistence and UI notifications belong to ScoreSharing.
local _, AK = ...
local H = assert(AK and AK.Highscores, "Highscores required")
local Sync = {PREFIX="AZKSCR1", MAX_BYTES=240, MAX_PEERS=32, SEND_INTERVAL=1,
    HELLO_INTERVAL=60, REQUEST_TIMEOUT=120, MAX_ROWS=50}
AK.ScoreSync = Sync
local courseIds={"mirage_raceway","stormwind_city","ironforge_gp",
    "darnassus_canopy","orgrimmar_canyon","undercity_slime","thunder_bluff_skyway","scarlet_graveyard"}
-- O remains a zero-digest placeholder, never an admitted course. Active
-- production codes stay stable; new courses append their own digest slots.
local courseCodes={"O","M","S","I","D","R","U","T","G"}
local ACTIVE_BOARDS,HELLO_SLOTS=#courseIds,#courseCodes
local courseToCode,codeToCourse={},{}
for i,id in ipairs(courseIds) do courseToCode[id],codeToCourse[courseCodes[i+1]]=courseCodes[i+1],id end
local kartIds={"goblin_mortar_trike","steam_tank","dwarven_biker","dwarf_car",
    "orc_demolisher","meat_wagon","glaive_thrower","gryphon_rider","gyrocopter","goblin_drag_car"}
local kartToCode,codeToKart={basic="Z"},{Z="basic"}
for i,id in ipairs(kartIds) do kartToCode[id],codeToKart[tostring(i-1)]=tostring(i-1),id end
local states=setmetatable({}, {__mode="k"})
local contextFields={"trackId","trackVersion","physicsVersion","lapCount","tickRate","rulesVersion"}
local function plain(v) return type(v)=="table" and getmetatable(v)==nil end
local function integer(v,lo,hi) return type(v)=="number" and v==v and v>=lo and v<=hi and v%1==0 end
local function identity(name)
    name=H.NormalizeName(name)
    if name then return (name:gsub("[A-Z]",function(c) return string.char(c:byte()+32) end)) end
end
local function decimal(v) return ("%.0f"):format(v) end
local function hash(text)
    local a,b=1,0
    for i=1,#text do a=(a+text:byte(i))%65521;b=(b+a)%65521 end
    return b*65536+a -- A change detector, never authentication or a signature.
end
local function count(t) local n=0;for _ in pairs(t) do n=n+1 end;return n end
local function dense(t,limit)
    if not plain(t) then return nil end
    local n=0
    for k in pairs(t) do if not integer(k,1,limit) then return nil end;n=n+1 end
    for i=1,n do if t[i]==nil then return nil end end
    return n
end
local function validRecord(record)
    if not plain(record) or not courseToCode[record.trackId] or not kartToCode[record.kartId] then return nil end
    local empty=H.Load(nil)
    local result,changed=H.Merge(empty,record,{record})
    return changed and H.View(result,record)[1] or nil
end
local function recordText(record,tag)
    local r=validRecord(record)
    if not r then return nil,"record" end
    return table.concat({"1",tag,courseToCode[r.trackId],decimal(r.trackVersion),decimal(r.physicsVersion),
        decimal(r.lapCount),decimal(r.tickRate),decimal(r.rulesVersion),decimal(r.totalTicks),
        decimal(r.finishedAt),kartToCode[r.kartId],r.playerName}," ")
end
function Sync.encode(message)
    if not plain(message) then return nil,"message" end
    local text
    if message.kind=="ROW" or message.kind=="NEW" then
        text=recordText(message.record,message.kind=="ROW" and "R" or "N")
    elseif message.kind=="REQUEST" and codeToCourse[message.code] then text="1 Q "..message.code
    elseif message.kind=="END" and codeToCourse[message.code]
        and integer(message.hash,0,4294967295) and integer(message.count,0,Sync.MAX_ROWS) then
        text=table.concat({"1 E",message.code,decimal(message.hash),decimal(message.count)}," ")
    elseif message.kind=="HELLO" and integer(message.physicsVersion,1,2147483647)
        and integer(message.catalogHash,0,4294967295) and dense(message.hashes,HELLO_SLOTS)==HELLO_SLOTS then
        local parts={"1 H",decimal(message.physicsVersion),decimal(message.catalogHash)}
        for _,value in ipairs(message.hashes) do
            if not integer(value,0,4294967295) then return nil,"hash" end
            parts[#parts+1]=decimal(value)
        end
        text=table.concat(parts," ")
    end
    if not text or #text>Sync.MAX_BYTES then return nil,"message" end
    return text
end
local function number(text,low,high)
    if type(text)~="string" or not text:match("^%d+$") or (#text>1 and text:sub(1,1)=="0") then return nil end
    local value=tonumber(text)
    return integer(value,low,high) and value or nil
end
local function tokens(text,n)
    local out,pos={},1
    for i=1,n do
        local at=text:find(" ",pos,true)
        if not at or at==pos then return nil end
        out[i],pos=text:sub(pos,at-1),at+1
    end
    out[n+1]=text:sub(pos)
    return out
end
function Sync.decode(payload)
    if type(payload)~="string" or #payload>Sync.MAX_BYTES or payload:find("[%z\001-\031\127|]") then return nil,"payload" end
    local tag,rest=payload:match("^1 ([A-Z]) (.+)$")
    if tag=="R" or tag=="N" then
        local p=tokens(rest,9)
        if not p or not codeToCourse[p[1]] or not codeToKart[p[9]] then return nil,"record" end
        local r={trackId=codeToCourse[p[1]],trackVersion=number(p[2],1,2147483647),
            physicsVersion=number(p[3],1,2147483647),lapCount=number(p[4],1,2147483647),
            tickRate=number(p[5],1,2147483647),rulesVersion=number(p[6],1,2147483647),
            totalTicks=number(p[7],1,H.MAX_TICKS),finishedAt=number(p[8],1,H.MAX_TIMESTAMP),
            kartId=codeToKart[p[9]],playerName=p[10]}
        r=validRecord(r)
        if not r then return nil,"record" end
        return {kind=tag=="R" and "ROW" or "NEW",code=p[1],record=r}
    elseif tag=="Q" and codeToCourse[rest] then return {kind="REQUEST",code=rest}
    elseif tag=="E" then
        local code,stamp,n=rest:match("^([A-Z]) (%d+) (%d+)$")
        stamp,n=number(stamp,0,4294967295),number(n,0,Sync.MAX_ROWS)
        if codeToCourse[code] and stamp and n then return {kind="END",code=code,hash=stamp,count=n} end
    elseif tag=="H" then
        local p={};for field in rest:gmatch("[^ ]+") do p[#p+1]=field end
        if #p~=HELLO_SLOTS+2 or table.concat(p," ")~=rest then return nil,"hello" end
        local physics,catalog=number(p[1],1,2147483647),number(p[2],0,4294967295)
        local hashes={}
        for i=1,HELLO_SLOTS do hashes[i]=number(p[i+2],0,4294967295);if not hashes[i] then return nil,"hello" end end
        if physics and catalog then return {kind="HELLO",physicsVersion=physics,catalogHash=catalog,hashes=hashes} end
    end
    return nil,"message"
end
local function boardHash(s,code,rows)
    if not s.contexts[code] then return 0 end
    local parts={H.BoardKey(s.contexts[code])}
    for _,record in ipairs(rows or H.View(s.store,s.contexts[code])) do parts[#parts+1]=assert(recordText(record,"R")) end
    return hash(table.concat(parts,"\n"))
end
local function hashes(s)
    local out={};for i,code in ipairs(courseCodes) do out[i]=boardHash(s,code) end;return out
end
local function clock(s,now)
    if not s then return false,"token" end
    if s.closed then return false,"closed" end
    if type(now)~="number" or now~=now or now<0 or now>1e10 or now<s.now then s.closed=true;return false,"clock" end
    s.now=now;return true
end
function Sync.new(options,now)
    if not plain(options) or not H.NormalizeName(options.name)
        or dense(options.contexts,ACTIVE_BOARDS)~=ACTIVE_BOARDS then return nil,"options" end
    local store,writable=H.Load(options.store)
    if not writable then return nil,"store" end
    local s={name=H.NormalizeName(options.name),key=identity(options.name),contexts={},store=store,
        peers={},order={},cursor=0,revision=0,received=0,sent=0,failed=0,attempted=0,now=0,lastAttempt=-1,
        rxAt=0,rxCount=0}
    local catalogue={}
    for _,context in ipairs(options.contexts) do
        local code=plain(context) and courseToCode[context.trackId]
        if not code or s.contexts[code] or not H.BoardKey(context) then return nil,"contexts" end
        local copied={};for _,field in ipairs(contextFields) do copied[field]=context[field] end
        s.contexts[code]=copied
        s.physicsVersion=s.physicsVersion or copied.physicsVersion
        if copied.physicsVersion~=s.physicsVersion then return nil,"contexts" end
    end
    for _,code in ipairs(courseCodes) do
        local context=s.contexts[code]
        catalogue[#catalogue+1]=context and H.BoardKey(context) or "retired:O"
        if context then
            for _,record in ipairs(H.View(s.store,context)) do
                if not validRecord(record) then return nil,"store" end
            end
        end
    end
    s.catalogHash=hash(table.concat(catalogue,"\n"))
    local ok,why=clock(s,now)
    if not ok then return nil,why end
    s.lastAttempt=now-1
    local token={};states[token]=s;return token
end
function Sync.discover(token,names,now)
    local s=states[token];local ok,why=clock(s,now);if not ok then return false,why end
    local n=dense(names,Sync.MAX_PEERS+1);if not n then return false,"roster" end
    local admitted,order={},{}
    for _,name in ipairs(names) do
        local normalized,key=H.NormalizeName(name),identity(name)
        if not normalized then return false,"roster" end
        if key~=s.key and not admitted[key] then
            if #order>=Sync.MAX_PEERS then return false,"capacity" end
            admitted[key]=s.peers[key] or {name=normalized,hello=true,nextHello=now,want={},reply={},urgent={},
                nextTry=now,failures=0,rxAt=now,rxCount=0}
            order[#order+1]=key
        end
    end
    s.peers,s.order=admitted,order
    if s.cursor>#order then s.cursor=0 end
    return true
end
local function merge(s,record)
    local code=courseToCode[record.trackId]
    if not code or H.BoardKey(record)~=H.BoardKey(s.contexts[code]) then return false,"context" end
    local store,changed,why=H.Merge(s.store,s.contexts[code],{record})
    if changed then s.store,s.revision=store,s.revision+1 end
    return changed,why
end
function Sync.publish(token,record,now)
    local s=states[token];local ok,why=clock(s,now);if not ok then return nil,false,why end
    local parsed=validRecord(record)
    if not parsed or identity(parsed.playerName)~=s.key then return nil,false,"record" end
    local _,previous=H.Rank(s.store,parsed,parsed.playerName)
    if previous and parsed.totalTicks>=previous.totalTicks then return nil,false,"not_better" end
    local prior=s.store
    local changed,reason=merge(s,parsed)
    if changed then
        local code=courseToCode[parsed.trackId]
        -- Keep a PB published during an in-flight handshake. Actual delivery
        -- waits for compatibility, but the update must not wait for a later digest.
        for _,peer in pairs(s.peers) do peer.urgent[code]=parsed end
    end
    local placement=changed and H.FinishPlacement(prior,s.store,parsed) or nil
    return placement,changed,reason
end
function Sync.receive(token,name,payload,now)
    local s=states[token];local ok,why=clock(s,now);if not ok then return false,why end
    local peer=s.peers[identity(name)];if not peer then return false,"peer" end
    if now-s.rxAt>=1 then s.rxAt,s.rxCount=now,0 end
    if now-peer.rxAt>=1 then peer.rxAt,peer.rxCount=now,0 end
    s.rxCount,peer.rxCount=s.rxCount+1,peer.rxCount+1
    if s.rxCount>128 or peer.rxCount>8 then return false,"rate" end
    local m,problem=Sync.decode(payload);if not m then return false,problem end
    if m.kind=="HELLO" then
        if m.physicsVersion~=s.physicsVersion or m.catalogHash~=s.catalogHash then
            peer.compatible=false;return false,"incompatible"
        end
        peer.compatible=true
        for i,code in ipairs(courseCodes) do
            if s.contexts[code] and m.hashes[i]~=boardHash(s,code) then peer.want[code]=true end
        end
    else
        -- A direct current-context update may beat our HELLO on the wire.
        -- Roster admission, exact context and native sender still validate it.
        if not peer.compatible and m.kind~="NEW" then return false,"handshake" end
        if m.kind=="NEW" or m.kind=="ROW" then
            if m.kind=="NEW" and identity(m.record.playerName)~=identity(name) then return false,"sender" end
            if H.BoardKey(m.record)~=H.BoardKey(s.contexts[m.code]) then return false,"context" end
            if m.kind=="ROW" then
                if not peer.waiting or peer.waiting.code~=m.code then return false,"unsolicited" end
                local waiting=peer.waiting
                if not waiting.seen[payload] then
                    if waiting.received>=Sync.MAX_ROWS then return false,"capacity" end
                    waiting.seen[payload],waiting.received=true,waiting.received+1
                end
            end
            local changed,reason=merge(s,m.record)
            if reason~="merged" and reason~="unchanged" then return false,reason end
            s.received=s.received+1
        elseif m.kind=="REQUEST" then
            if not peer.active or peer.active.code~=m.code then peer.reply[m.code]=true end
        elseif m.kind=="END" then
            if not peer.waiting or peer.waiting.code~=m.code then return false,"unsolicited" end
            if peer.waiting.received~=m.count then peer.want[m.code]=true
            elseif boardHash(s,m.code)~=m.hash then peer.hello=true end
            peer.waiting=nil
        end
    end
    s.lastReceived=now;return true
end
local function nextCode(t)
    for _,code in ipairs(courseCodes) do if t[code] then return code end end
end
local function candidate(s,peer,priority,now)
    if now<peer.nextTry then return nil end
    if priority==1 and peer.compatible then
        local code=nextCode(peer.urgent)
        if code then return {kind="NEW",code=code,record=peer.urgent[code]} end
    elseif priority==2 and (peer.hello or now>=peer.nextHello) then
        return {kind="HELLO",physicsVersion=s.physicsVersion,catalogHash=s.catalogHash,hashes=hashes(s)}
    elseif priority==3 and peer.compatible and not peer.waiting then
        local code=nextCode(peer.want);if code then return {kind="REQUEST",code=code} end
    elseif priority==4 and peer.compatible then
        if not peer.active then
            local code=nextCode(peer.reply)
            if code then
                local rows=H.View(s.store,s.contexts[code])
                peer.active={code=code,rows=rows,index=1,hash=boardHash(s,code,rows)}
                peer.reply[code]=nil
            end
        end
        local active=peer.active
        if active then
            if active.rows[active.index] then return {kind="ROW",record=active.rows[active.index],active=active} end
            return {kind="END",code=active.code,hash=active.hash,count=#active.rows,active=active}
        end
    end
end
function Sync.update(token,now,sendFn)
    local s=states[token];local ok,why=clock(s,now);if not ok then return false,why end
    if s.sending or type(sendFn)~="function" then return false,"callback" end
    if now-s.lastAttempt<Sync.SEND_INTERVAL then return false,"paced" end
    for _,peer in pairs(s.peers) do
        if peer.waiting and now>=peer.waiting.deadline then peer.want[peer.waiting.code]=true;peer.waiting=nil end
    end
    for priority=1,4 do
        for offset=1,#s.order do
            local index=(s.cursor+offset-1)%#s.order+1
            local peer=s.peers[s.order[index]]
            local m=candidate(s,peer,priority,now)
            if m then
                local payload=Sync.encode(m)
                if not payload then return false,"encoding" end
                s.lastAttempt,s.attempted,s.sending=now,s.attempted+1,true
                local called,accepted=pcall(sendFn,peer.name,payload)
                s.sending,s.cursor=false,index
                if called and accepted==true then
                    s.sent,peer.failures=s.sent+1,0
                    if m.kind=="NEW" then if peer.urgent[m.code]==m.record then peer.urgent[m.code]=nil end
                    elseif m.kind=="HELLO" then peer.hello,peer.nextHello=false,now+Sync.HELLO_INTERVAL
                    elseif m.kind=="REQUEST" then
                        peer.want[m.code]=nil
                        peer.waiting={code=m.code,deadline=now+Sync.REQUEST_TIMEOUT,received=0,seen={}}
                    elseif peer.active==m.active then
                        if m.kind=="ROW" then peer.active.index=peer.active.index+1 else peer.active=nil end
                    end
                    return true
                end
                s.failed,peer.failures=s.failed+1,peer.failures+1
                peer.nextTry=now+2^peer.failures
                if peer.failures>=3 then
                    peer.urgent,peer.reply,peer.active,peer.waiting,peer.hello={},{},nil,nil,true
                    peer.failures,peer.nextTry=0,now+Sync.HELLO_INTERVAL
                end
                return false,"send"
            end
        end
    end
    return false,"idle"
end
function Sync.snapshot(token)
    local s=states[token];if not s then return nil end
    return H.Load(s.store)
end
function Sync.view(token)
    local s=states[token];if not s then return {phase="unavailable",peers=0,queued=0} end
    local queued,connected=0,0
    for _,peer in pairs(s.peers) do
        queued=queued+count(peer.urgent)+count(peer.want)+count(peer.reply)+(peer.hello and 1 or 0)
        if peer.active then queued=queued+#peer.active.rows-peer.active.index+2 end
        if peer.compatible then connected=connected+1 end
    end
    return {phase=s.closed and "closed" or "active",revision=s.revision,received=s.received,
        sent=s.sent,failed=s.failed,attempted=s.attempted,peers=#s.order,connected=connected,
        queued=queued,lastReceived=s.lastReceived}
end
return Sync
