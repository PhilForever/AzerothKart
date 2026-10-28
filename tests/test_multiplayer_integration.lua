-- Two fully loaded addon instances, real menu callbacks and real fixed-step
-- modules over delayed native mocks. This is not actual Forever evidence.
local originalPrint=print
local names={"CreateFrame","UIParent","InCombatLockdown","GetCurrentKeyBoardFocus",
    "IsGameWindowFocused","GetBuildInfo","GetFramerate","GetTime","debugprofilestop",
    "DEFAULT_CHAT_FRAME","C_AddOns","SlashCmdList","SLASH_AZEROTHKART1","SLASH_AZEROTHKART2",
    "AzerothKart","AzerothKartDB","print","PlaySound","SOUNDKIT","UISpecialFrames",
    "C_ChatInfo","Enum"}
local modules={}
for line in io.lines("addon/AzerothKart/AzerothKart_Camelot.toc") do
    local name=line:match("^%s*([%w_]+)%.lua%s*$")
    if name then modules[#modules+1]=name end
end

assert(modules[#modules]=="Core")
local HOST,GUEST="Amber Stone","Birch Vale"
local function visible(item)
    while item do
        if rawget(item,"shown")==false then return false end
        item=rawget(item,"parent")
    end
    return true
end
local function client(identity,offset)
    local e={identity=identity,offset=offset,now=offset,frames={},sends={},output={},objects=0,
        cues={},cueOrder={}}
    local methods={}
    local function object(parent)
        e.objects=e.objects+1
        return setmetatable({parent=parent,scripts={},events={},shown=true,enabled=true},
            {__index=function(_,key)
                if methods[key] then return methods[key] end
                if key:match("^[A-Z]") then return function() end end
            end})
    end
    function methods:SetScript(name,callback) self.scripts[name]=callback end
    function methods:RegisterEvent(name) self.events[name]=true end
    function methods:UnregisterEvent(name) self.events[name]=nil end
    function methods:IsShown() return self.shown end
    function methods:Show()
        if self.shown then return end
        self.shown=true
        if self.scripts.OnShow then self.scripts.OnShow(self) end
    end
    function methods:Hide()
        if not self.shown then return end
        self.shown=false
        if self.scripts.OnHide then self.scripts.OnHide(self) end
    end
    function methods:SetText(text) self.text=text end
    function methods:GetText() return self.text end
    function methods:Enable() self.enabled=true end
    function methods:Disable() self.enabled=false end
    function methods:IsEnabled() return self.enabled end
    function methods:SetFocus() e.focus=self end
    function methods:ClearFocus() if e.focus==self then e.focus=nil end end
    function methods:SetSize(w,h) self.width,self.height=w,h end
    function methods:SetPoint(...) self.point={...} end
    function methods:ClearAllPoints() self.point=nil end
    function methods:SetTexture(path) self.path=path; return true end
    function methods:SetTexCoord(...) self.uv={...} end
    function methods:SetRotation(v) self.rotation=v end
    function methods:SetDrawLayer(layer,sublevel) self.drawLayer,self.sublevel=layer,sublevel or 0 end
    function methods:SetAlpha(v) self.alpha=v end
    function methods:SetChecked(v) self.checked=v end
    function methods:GetChecked() return rawget(self,"checked") end
    function methods:SetFrameLevel(v) self.level=v end
    function methods:GetFrameLevel() return rawget(self,"level") or 1 end
    function methods:GetName() return rawget(self,"name") end
    function methods:EnableKeyboard(v) self.keyboard=v end
    function methods:SetPropagateKeyboardInput(v) self.propagate=v end
    function methods:CreateTexture() return object(self) end
    function methods:CreateFontString() return object(self) end
    local results={}
    for i,name in ipairs({"Success","InvalidPrefix","InvalidMessage","AddonMessageThrottle",
        "InvalidChatType","NotInGroup","TargetRequired","InvalidChannel","ChannelThrottle",
        "GeneralError","NotInGuild","AddOnMessageLockdown","TargetOffline"}) do results[name]=i-1 end
    e.globals={UIParent={},SlashCmdList={},AzerothKartDB={},UISpecialFrames={},
        Enum={RegisterAddonMessagePrefixResult={Success=0,DuplicatePrefix=1},SendAddonMessageResult=results},
        InCombatLockdown=function() return false end,
        GetCurrentKeyBoardFocus=function() return e.focus end,
        IsGameWindowFocused=function() return true end,
        GetBuildInfo=function() return "mock","0","test",16001 end,
        GetFramerate=function() return 60 end,GetTime=function() return e.now end,
        debugprofilestop=function() return 0 end,PlaySound=function() end,SOUNDKIT={},
        print=function() end,
        DEFAULT_CHAT_FRAME={AddMessage=function(_,text) e.output[#e.output+1]=text end}}
    e.globals.CreateFrame=function(kind,name,parent)
        local frame=object(parent); frame.kind,frame.name=kind,name
        e.frames[#e.frames+1]=frame
        return frame
    end
    e.globals.C_ChatInfo={RegisterAddonMessagePrefix=function(prefix)
        assert(prefix=="AZKART2" or prefix=="AZKCLK1" or prefix=="AZKRUN2" or prefix=="AZKRUN3" or prefix=="AZKGRD1")
        return 0
    end,InChatMessagingLockdown=function() return false end,
    SendAddonMessageLogged=function(prefix,payload,channel,target)
        assert(channel=="WHISPER")
        local packet={prefix=prefix,payload=payload,channel=channel,target=target,
            sender=e.identity,time=e.now}
        e.sends[#e.sends+1]=packet
        if e.onSend then e.onSend(packet) end
        return 0
    end,SendAddonMessage=function() error("unlogged fallback forbidden") end}
    function e:run(fn,...)
        local previous={}
        for i,name in ipairs(names) do previous[i]={name=name,value=_G[name]}; _G[name]=self.globals[name] end
        local ok,a,b=pcall(fn,...)
        for _,entry in ipairs(previous) do
            self.globals[entry.name]=_G[entry.name]; _G[entry.name]=entry.value
        end
        if not ok then error(a,0) end
        return a,b
    end
    function e:view() return self:run(self.ns.SessionTransport.GetView) end
    function e:click(button)
        assert(button.enabled and visible(button),"menu action is reachable and enabled")
        return self:run(assert(button.scripts.OnClick),button)
    end
    e:run(function()
        local ns={}; e.ns=ns
        for _,module in ipairs(modules) do
            assert(loadfile("addon/AzerothKart/"..module..".lua"))("AzerothKart",ns)
        end
        for _,frame in ipairs(e.frames) do
            if frame.events.ADDON_LOADED then e.core=frame; break end
        end
        assert(e.core and e.core.scripts.OnEvent)
        e.core.scripts.OnEvent(e.core,"ADDON_LOADED","AzerothKart")
        local onCue=ns.Menu.OnCue
        ns.Menu.OnCue=function(cue)
            if cue then
                e.cues[cue]=(e.cues[cue] or 0)+1
                e.cueOrder[#e.cueOrder+1]=cue
            end
            return onCue(cue)
        end
        assert(ns.Menu.bridge and type(ns.Menu.bridge.action)=="function","Core installs real command bridge")
        ns.UI.Toggle()
        ns.Menu.Show("multiplayer")
    end)
    return e
end

local p={host=client(HOST,0),guest=client(GUEST,5),now=0,queue={}}
for _,role in ipairs({"host","guest"}) do
    local e=p[role]
    e.onSend=function(packet)
        p.queue[#p.queue+1]={to=role=="host" and "guest" or "host",packet=packet,at=p.now+0.35}
    end
end
function p:step()
    self.now=self.now+1/60
    for _,role in ipairs({"host","guest"}) do
        local e=self[role]; e.now=self.now+e.offset
        e:run(function()
            for _,frame in ipairs(e.frames) do
                if visible(frame) and frame.scripts.OnUpdate then frame.scripts.OnUpdate(frame,1/60) end
            end
        end)
        local ui=e.ns.UI
        if ui.gridStaged then
            assert(not ui.active and not ui.liveActive and ui.state.tick==0
                and (not ui.race or ui.race.totalTicks==0)
                and (not ui.laps or ui.laps.completedLaps==0),
                "visible starting-grid/countdown frames never advance Physics, race time or laps")
            assert(visible(ui.opponent) and visible(ui.opponentLabel),
                "both karts are visible on the staged grid")
            e.stagedGrid=ui.gridView
            if not e.heldBeforeGO then
                e:run(ui.window.scripts.OnKeyDown,ui.window,"W")
                assert(ui.keys.W==true)
                e.heldBeforeGO=true
            end
        elseif ui.liveActive and not e.goPose then
            e.goPose={x=ui.state.x,y=ui.state.y,heading=ui.state.heading}
            assert(e.heldBeforeGO and ui.keys.W==true,
                "held throttle from the grid survives authoritative GO adoption")
        end
        if ui.liveView and ui.liveView.remote and ui.liveView.remote.tick>0
            and visible(ui.opponent) and visible(ui.opponentLabel) and ui.opponent.point then
            e.sawMovingOpponent=true
        end
    end
    local queue=self.queue; self.queue={}
    for _,entry in ipairs(queue) do
        if entry.at>self.now then self.queue[#self.queue+1]=entry else
            local e,packet=self[entry.to],entry.packet
            assert(packet.target==e.identity)
            if e.core.events.CHAT_MSG_ADDON_LOGGED then
                e:run(e.core.scripts.OnEvent,e.core,"CHAT_MSG_ADDON_LOGGED",
                    packet.prefix,packet.payload,packet.channel,packet.sender)
            end
        end
    end
end
function p:untilTrue(predicate,maxTicks)
    for _=1,maxTicks or 3600 do if predicate() then return end; self:step() end
    local detail={}
    for _,role in ipairs({"host","guest"}) do
        local e=self[role]
        local view=e:view()
        detail[#detail+1]=role..":"..tostring(view.phase)..":"..tostring(view.reason)
            ..":"..tostring(view.lastError)..":"..tostring(e.ns.Menu.messages.multiplayer.text)
            ..":session="..tostring(view.session)..":last="
            ..tostring(e.sends[#e.sends] and e.sends[#e.sends].payload)
    end
    error("fully loaded clients did not reach expected menu/race state | "..table.concat(detail," | "))
end

local h,g=p.host,p.guest
h:run(function() assert(h.ns.UI.SelectKart("steam_tank")) end)
g:run(function() assert(g.ns.UI.SelectKart("goblin_drag_car")) end)
for _,entry in ipairs({{h,GUEST},{g,HOST}}) do
    entry[1]:run(function()
        local view=entry[1].ns.Menu.view
        view.peerName:SetText(entry[2]); view.sessionCode:SetText("ABC123")
        view.sessionCode:SetFocus()
    end)
end
g:click(g.ns.Menu.view.listen); h:click(h.ns.Menu.view.host)
assert(not h.focus and not g.focus,"Host/Listen release their edit-box focus")
p:untilTrue(function() return g.ns.Menu.view.join.enabled end)
g:click(g.ns.Menu.view.join)
p:untilTrue(function() return h.ns.Menu.view.ready.enabled and g.ns.Menu.view.ready.enabled end)
h:click(h.ns.Menu.view.ready); g:click(g.ns.Menu.view.ready)
assert(h.ns.UI.liveArmed and g.ns.UI.liveArmed and not h.ns.UI.active and not g.ns.UI.active)
p:untilTrue(function() return h.ns.Menu.view.start.enabled end)
h:click(h.ns.Menu.view.start)
local counts={host=h.objects,guest=g.objects}
p:untilTrue(function() return h.ns.UI.liveActive and g.ns.UI.liveActive end)
for _,e in ipairs({h,g}) do
    assert(e.ns.UI.active and e.ns.UI.window.keyboard and not e.ns.UI.window.propagate)
    assert(e.ns.UI.trackId=="mirage_raceway" and e.ns.UI.race.countdownTicks==0)
    assert(e.stagedGrid and e.cues["GET READY"] and e.cues["3"]==1 and e.cues["2"]==1
        and e.cues["1"]==1,"every peer sees GET READY and one transition through each countdown numeral")
    assert(e.cueOrder[1]=="GET READY" and e.cueOrder[2]=="3" and e.cueOrder[3]=="2"
        and e.cueOrder[4]=="1","the visible grid precedes the three-second numeric countdown")
end
assert(math.abs((h.goPose.x-g.goPose.x)^2+(h.goPose.y-g.goPose.y)^2-36^2)<0.001,
    "coordinated GO starts the real vehicles in distinct 36-unit-apart slots")
assert(h.goPose.x==g.stagedGrid.peerPose.x and h.goPose.y==g.stagedGrid.peerPose.y
    and g.goPose.x==h.stagedGrid.peerPose.x and g.goPose.y==h.stagedGrid.peerPose.y)
for _=1,180 do p:step() end
for _,role in ipairs({"host","guest"}) do
    local e=p[role]; local ui=e.ns.UI
    assert(ui.active and ui.state.tick>=175 and ui.state.tick<=190)
    assert(ui.state.speed>0,"pre-GO held W accelerates the real kart after GO")
    assert(ui.liveView.remote and ui.liveView.remote.tick>0 and ui.liveView.remoteVerified==false)
    assert(e.sawMovingOpponent and visible(ui.opponentLabel),
        "received peer pose reaches the real pooled canvas marker and label")
    assert(ui.opponentAssetId==(role=="host" and "goblin_drag_car" or "steam_tank")
        and ui.opponentSprite and ui.opponent.path==ui.opponentSprite.path,
        "the pooled opponent renders the other player's agreed selected kart")
    assert(e.objects==counts[role],"live menu/canvas updates allocate no widgets")
    for i,packet in ipairs(e.sends) do
        if i>1 then assert(packet.time-e.sends[i-1].time>=0.5) end
    end
end
local hostTick=h.ns.UI.state.tick
h:click(h.ns.UI.stopButton)
p:untilTrue(function() return not h:view().transportBusy and not g:view().transportBusy end)
for _=1,60 do p:step() end
assert(h.ns.UI.state.tick==hostTick,"Stop freezes the exact displayed local state")
for _,e in ipairs({h,g}) do
    local ui=e.ns.UI
    assert(not ui.active and not ui.liveActive and ui.window.keyboard==false and ui.window.propagate==true)
    assert(ui.result and ui.result.resultVerified==false)
    assert(e.core.akNetworkOwner==nil and not e.core.events.CHAT_MSG_ADDON_LOGGED)
end
originalPrint("Multiplayer integration: actual Core/Menu/UI/Transport callbacks drive two delayed mocked peers, show observations and stop safely")

-- A bounded position tape finishes actual Race/Checkpoints/Laps through the
-- complete native/menu bridge. Handling was exercised above; only this tape's
-- poses replace Physics.step so the lifecycle test does not need a racing AI.
local function installFinishTape(e,delay)
    local track=e.ns.UI.track
    local goals={}
    for _=1,track.laps or 3 do
        for _,gate in ipairs(track.gates) do
            local length=math.sqrt(gate.nx*gate.nx+gate.ny*gate.ny)
            local nx,ny=gate.nx/length,gate.ny/length
            local x,y=(gate.ax+gate.bx)/2,(gate.ay+gate.by)/2
            goals[#goals+1]={x=x-nx*2,y=y-ny*2}
            goals[#goals+1]={x=x+nx*2,y=y+ny*2}
        end
    end
    local tape={goals=goals,index=1,delay=delay or 0}
    e.finishTape=tape
    if e.originalPhysicsStep then return end
    e.originalPhysicsStep=e.ns.Physics.step
    e.ns.Physics.step=function(previous,input,dt,geometry,kartId)
        local active=e.finishTape
        if not active then return e.originalPhysicsStep(previous,input,dt,geometry,kartId) end
        local current={};for key,value in pairs(previous) do current[key]=value end
        current.tick=previous.tick+1
        if active.delay>0 then active.delay=active.delay-1;current.speed=0;return current end
        local goal=active.goals[active.index]
        if not goal then current.speed=0;return current end
        local dx,dy=goal.x-previous.x,goal.y-previous.y
        local distance=math.sqrt(dx*dx+dy*dy)
        local step=math.min(4,distance)
        assert(step<=geometry.checkpointMaxStep,"finish tape respects real gate movement bound")
        if distance>0 then
            current.x,current.y=previous.x+dx/distance*step,previous.y+dy/distance*step
            current.heading=math.atan2(dy,dx)
        end
        current.speed=step/dt
        if distance<=4 then active.index=active.index+1 end
        return current
    end
end

local function freshPair()
    local q={host=client(HOST,0),guest=client(GUEST,5),now=0,queue={},step=p.step,untilTrue=p.untilTrue}
    for _,role in ipairs({"host","guest"}) do
        local e=q[role]
        e.onSend=function(packet)
            q.queue[#q.queue+1]={to=role=="host" and "guest" or "host",packet=packet,at=q.now+0.35}
        end
        e.finishSounds=0
        e.globals.SOUNDKIT={LFG_REWARDS=999}
        e.globals.PlaySound=function(kit) if kit==999 then e.finishSounds=e.finishSounds+1 end end
    end
    return q
end

local function readyAndLaunch(q)
    local a,b=q.host,q.guest
    q:untilTrue(function() return a:view().canSetReady and b:view().canSetReady
        and a.ns.Menu.view.ready.enabled and b.ns.Menu.view.ready.enabled end)
    a:click(a.ns.Menu.view.ready);b:click(b.ns.Menu.view.ready)
    q:untilTrue(function() return a.ns.Menu.view.start.enabled end)
    a:click(a.ns.Menu.view.start)
    q:untilTrue(function() return a.ns.UI.liveActive and b.ns.UI.liveActive end)
end

local function assertBudget(e)
    for index,packet in ipairs(e.sends) do
        assert(#packet.prefix+#packet.payload<=158,"every round retains the native packet ceiling")
        if index>1 then assert(packet.time-e.sends[index-1].time>=0.5,
            "native cadence is persistent across results and a rematch") end
        local calls,bytes=0,0
        for prior=index,1,-1 do
            local entry=e.sends[prior]
            if packet.time-entry.time>=1 then break end
            calls,bytes=calls+1,bytes+#entry.prefix+#entry.payload
        end
        assert(calls<=2 and bytes<=158,"rematch cannot reset the rolling native budget")
    end
end

do
    local q=freshPair()
    local a,b=q.host,q.guest
    for _,entry in ipairs({{a,GUEST},{b,HOST}}) do
        entry[1]:run(function()
            entry[1].ns.Menu.view.peerName:SetText(entry[2])
            entry[1].ns.Menu.view.sessionCode:SetText("RMT001")
        end)
    end
    b:click(b.ns.Menu.view.listen);a:click(a.ns.Menu.view.host)
    q:untilTrue(function() return b.ns.Menu.view.join.enabled end)
    b:click(b.ns.Menu.view.join)
    readyAndLaunch(q)
    local originalSession=a:view().session
    local created={host=a.objects,guest=b.objects}
    installFinishTape(a,0);installFinishTape(b,120)
    q:untilTrue(function() return a.ns.UI.race.status=="finished" and b.ns.UI.race.status=="running" end)
    local frozenRace=a.ns.UI.race
    local pending=a:view().results
    assert(pending and pending.verified==false and not pending.complete,
        "a local finish retains a pending peer result, never an invented last place")
    for _,row in ipairs(pending.rows) do assert(row.rank==nil,"no rank before both finish observations") end
    assert(not a.ns.UI.window.keyboard and a.ns.UI.window.propagate==true,
        "the first finisher releases keyboard capture while the friend keeps racing")
    q:untilTrue(function() return a:view().phase=="postrace" and b:view().phase=="postrace" end)
    for _,e in ipairs({a,b}) do
        local view=e:view()
        assert(view.room and view.room.peer==(e==a and GUEST or HOST) and view.results.complete
            and view.results.verified==false,"both results retain the scoped roster and local observations")
        assert(view.results.rows[1].rank==1 and view.results.rows[2].rank==2,
            "completed observations produce local placements")
        local localRank=e==a and 1 or 2
        for _,row in ipairs(view.results.rows) do
            if row.localPlayer then assert(row.rank==localRank and row.totalTicks==e.ns.UI.race.totalTicks) end
        end
        assert(e.ns.UI.summaryTitle.text:find("UNVERIFIED",1,true)
            and e.ns.UI.summaryDetail.text:find("1.",1,true),"real results widgets show local placements")
        assert(e.finishSounds==1,"late peer finish does not replay the local fanfare")
    end
    assert(a.ns.UI.race==frozenRace,"late peer finish preserves the completed local race identity")
    a:run(a.ns.UI.Start)
    assert(not a.ns.UI.active and a.ns.UI.race==frozenRace and a:view().room,
        "direct Restart cannot silently turn retained multiplayer into solo")
    b:click(b.ns.UI.dismissSummaryButton)
    assert(not b.ns.UI.summary:IsShown() and b:view().room and b.core.akNetworkOwner,
        "closing results keeps the same-player room")
    b:click(b.ns.Menu.view.mainMenu)
    assert(b.ns.Menu.screen=="multiplayer" and b:view().room,
        "post-results navigation returns to the room rather than single-player menus")
    a:click(a.ns.Menu.view.resultChangeTrack)
    assert(a.ns.Menu.screen=="multiplayer" and a:view().room and not a.ns.UI.active)
    a:click(a.ns.Menu.view.lobbyTrackChoice)
    assert(a.ns.Menu.lobbyTrackId=="stormwind_city","the host stages the next multiplayer map")
    local oldPacket
    for _,packet in ipairs(a.sends) do if packet.prefix==a.ns.LiveProtocol.PREFIX then oldPacket=packet end end
    assert(oldPacket)
    for _,e in ipairs({a,b}) do
        e.finishTape=nil;e.heldBeforeGO=nil;e.goPose=nil;e.stagedGrid=nil
    end
    a:click(a.ns.Menu.view.ready) -- Play Again in a post-race host lobby.
    q:untilTrue(function() return b.ns.Menu.view.join.enabled end)
    assert(a:view().session~=originalSession and b:view().session==a:view().session
        and a:view().peer==GUEST and b:view().peer==HOST,"fresh rematch keeps both exact full-name peers")
    assert(not a.ns.UI.active and not b.ns.UI.active and not a.ns.UI.window.keyboard
        and not b.ns.UI.window.keyboard,"new offer alone cannot capture controls or start a race")
    b:click(b.ns.Menu.view.join)
    readyAndLaunch(q)
    for _,e in ipairs({a,b}) do
        assert(e.ns.UI.multiplayer and e.ns.UI.trackId=="stormwind_city" and e.ns.UI.race.startTick==0
            and e.ns.UI.race.laps.completedLaps==0,"new shared GO resets rules and uses the chosen map")
        assert(e.cues["3"]==2 and e.cues["2"]==2 and e.cues["1"]==2,
            "the rematch gets a fresh full countdown")
    end
    local before=b:view().live.remoteSequence
    b:run(b.core.scripts.OnEvent,b.core,"CHAT_MSG_ADDON_LOGGED",oldPacket.prefix,
        oldPacket.payload,oldPacket.channel,oldPacket.sender)
    assert(b:view().live.remoteSequence==before,"old-race telemetry cannot alter the new round")
    installFinishTape(a,120);installFinishTape(b,0)
    q:untilTrue(function() return a:view().phase=="postrace" and b:view().phase=="postrace" end)
    for _,e in ipairs({a,b}) do
        local view=e:view()
        assert(view.results.complete and view.results.verified==false and view.room.trackId=="stormwind_city")
        for _,row in ipairs(view.results.rows) do
            if row.localPlayer then assert(row.rank==(e==b and 1 or 2),"next round ranks use fresh finish ticks") end
        end
        assert(e.finishSounds==2 and e.objects==created[e==a and "host" or "guest"],
            "two races finish once each without allocating results or lobby widgets")
        e:run(function()
            assert(#e.ns.SoloRecords.GetView("mirage_raceway").rows==0
                and #e.ns.SoloRecords.GetView("stormwind_city").rows==0,
                "multiplayer finish never publishes a solo score")
        end)
        assertBudget(e)
    end
    -- A third round changes from a circuit to a new one-run dungeon through
    -- the same actual room/menu flow. No retyped peer/code or solo fallback.
    local secondSession=a:view().session
    a:click(a.ns.Menu.view.resultChangeTrack)
    for _=1,#a.ns.Courses.LIST do
        if a.ns.Menu.lobbyTrackId=="scarlet_graveyard" then break end
        a:click(a.ns.Menu.view.lobbyTrackChoice)
    end
    assert(a.ns.Menu.lobbyTrackId=="scarlet_graveyard"
        and a.ns.Menu.view.lobbyTrack.text=="Next choice: Scarlet Graveyard    Sprint: 1 run"
        and a.ns.UI.trackId=="stormwind_city",
        "host stages the sprint and its one-run rule without replacing finished geometry")
    for _,e in ipairs({a,b}) do
        e.finishTape=nil;e.heldBeforeGO=nil;e.goPose=nil;e.stagedGrid=nil
    end
    b:click(b.ns.UI.restartButton) -- Guest Play Again returns to the retained room.
    a:click(a.ns.Menu.view.ready)
    q:untilTrue(function() return b.ns.Menu.view.join.enabled end)
    assert(a:view().session~=secondSession and a:view().session==b:view().session
        and a:view().peer==GUEST and b:view().peer==HOST
        and a:view().offer.laps==1 and b:view().offer.laps==1,
        "one-run rematch offers a fresh session with the same full-name peers")
    b:click(b.ns.Menu.view.join)
    readyAndLaunch(q)
    for _,e in ipairs({a,b}) do
        assert(e.ns.UI.trackId=="scarlet_graveyard" and e.ns.UI.race.targetLaps==1
            and e.ns.UI.race.laps.completedLaps==0 and e.ns.UI.race.startTick==0,
            "shared sprint GO adopts the actual one-run race target")
        assert(e.cues["3"]==3 and e.cues["2"]==3 and e.cues["1"]==3,
            "sprints retain the complete shared countdown")
        assert(e.ns.Menu.view.lap.text=="SPRINT","live dungeon HUD shows sprint instead of lap1/3")
    end
    installFinishTape(a,0);installFinishTape(b,120)
    q:untilTrue(function() return a.ns.UI.race.status=="finished" and b.ns.UI.race.status=="running" end)
    assert(not a:view().results.complete and a:view().results.rows[1].rank==nil,
        "one-run local finish also waits for the peer before assigning places")
    q:untilTrue(function() return a:view().phase=="postrace" and b:view().phase=="postrace" end)
    for _,e in ipairs({a,b}) do
        local view=e:view()
        assert(view.results.complete and not view.results.verified and view.room.trackId=="scarlet_graveyard"
            and e.ns.UI.race.laps.completedLaps==1,
            "both racers finish one ordered run and return to the retained sprint room")
        assert(e.finishSounds==3 and e.objects==created[e==a and "host" or "guest"],
            "sprint result/room refreshes allocate nothing and finish only once")
        e:run(function()
            for _,course in ipairs(e.ns.Courses.LIST) do
                assert(#e.ns.SoloRecords.GetView(course.id).rows==0,
                    "multiplayer sprint/circuit results cannot enter any solo board")
            end
        end)
        assertBudget(e)
    end
    a:click(a.ns.UI.restartButton)
    assert(a.ns.Menu.screen=="multiplayer" and not a.ns.UI.active and a:view().room,
        "Play Again from results queues another same-peer offer, never solo Start")
    a:run(a.ns.UI.MultiplayerAction,"leave");b:run(b.ns.UI.MultiplayerAction,"leave")
    q:untilTrue(function() return not a:view().transportBusy and not b:view().transportBusy end)
    assert(not a.ns.UI.multiplayer and not b.ns.UI.multiplayer,"explicit Leave finally releases multiplayer mode")
    originalPrint("Multiplayer rematch integration: three complete observed races including one-run sprint, delayed peer results, same roster/new sessions/maps, full countdowns, persistent budget and no solo score PASS")
end

-- Offline assisted driving, not a racing AI or native gameplay evidence. Only
-- heading is aimed at the reviewed centre line; the real Physics step owns
-- position, speed, collisions, floor changes and pad rewards on every tick.
local function installWarsongDriver(e,delay)
    local goals={}
    for _=1,3 do
        for index=2,#e.ns.Battlegrounds.warsong_gulch.route do
            goals[#goals+1]=e.ns.Battlegrounds.warsong_gulch.route[index]
        end
    end
    local driver={goals=goals,index=1,delay=delay,levels={0},pads=0,steps=0}
    e.routeDriver=driver
    local physics=e.ns.Physics.step
    e.ns.Physics.step=function(previous,input,dt,track,kartId)
        local active=e.routeDriver
        if not active then return physics(previous,input,dt,track,kartId) end
        local aimed={};for key,value in pairs(previous) do aimed[key]=value end
        local controls={accelerate=true}
        if active.delay>0 then
            active.delay=active.delay-1;controls={}
        else
            local goal=active.goals[active.index]
            if goal and (goal.x-previous.x)^2+(goal.y-previous.y)^2<20.25 then
                active.index=active.index+1;goal=active.goals[active.index]
            end
            if goal then aimed.heading=math.atan2(goal.y-previous.y,goal.x-previous.x) end
        end
        local current=physics(aimed,controls,dt,track,kartId)
        assert(current.impacts==0,"the authored Warsong driving route must stay collision-free")
        assert((current.x-previous.x)^2+(current.y-previous.y)^2<=track.checkpointMaxStep^2,
            "actual boosted Physics steps stay inside the checkpoint movement bound")
        if current.level~=previous.level then active.levels[#active.levels+1]=current.level end
        if current.boostTicks>previous.boostTicks then active.pads=active.pads+1 end
        active.steps=active.steps+1
        return current
    end
    return driver
end

do
    local q=freshPair()
    local a,b=q.host,q.guest
    for _,entry in ipairs({{a,GUEST},{b,HOST}}) do
        entry[1]:run(function()
            entry[1].ns.Menu.view.peerName:SetText(entry[2])
            entry[1].ns.Menu.view.sessionCode:SetText("WSG001")
        end)
    end
    for _=1,#a.ns.Courses.LIST do
        if a.ns.Menu.lobbyTrackId=="warsong_gulch" then break end
        a:click(a.ns.Menu.view.lobbyTrackChoice)
    end
    assert(a.ns.Menu.lobbyTrackId=="warsong_gulch","Warsong is selectable in the real multiplayer menu")
    b:click(b.ns.Menu.view.listen);a:click(a.ns.Menu.view.host)
    q:untilTrue(function() return b.ns.Menu.view.join.enabled end)
    b:click(b.ns.Menu.view.join)
    readyAndLaunch(q)
    local created={a.objects,b.objects}
    local drivers={installWarsongDriver(a,0),installWarsongDriver(b,60)}
    for _,e in ipairs({a,b}) do
        local ui=e.ns.UI
        assert(e:view().offer.trackId=="warsong_gulch" and e:view().offer.physicsVersion==13
            and ui.track.layered and ui.state.level==0 and ui.race.targetLaps==3,
            "full native/menu negotiation selects the actual three-lap layered course")
        assert(e.stagedGrid.localPose.level==0 and e.stagedGrid.peerPose.level==0
            and e.cues["3"]==1 and e.cues["2"]==1 and e.cues["1"]==1,
            "both karts are staged on ground before the complete shared countdown")
    end
    local function observe()
        for _,e in ipairs({a,b}) do
            local ui=e.ns.UI
            e.sawLocalHigh=e.sawLocalHigh or ui.kart.sublevel==3
            e.sawRemoteHigh=e.sawRemoteHigh or ui.opponent.sublevel==3
            e.sawRemoteGround=e.sawRemoteGround or ui.opponent.sublevel==-5
        end
    end
    q:untilTrue(function()
        observe()
        return a.ns.UI.race.status=="finished" and b.ns.UI.race.status=="running"
    end,12000)
    assert(not a:view().results.complete,"Warsong keeps local placements pending while its peer still races")
    local finishedRace=a.ns.UI.race
    q:untilTrue(function()
        observe()
        return a:view().phase=="postrace" and b:view().phase=="postrace"
    end)
    local previousSession=a:view().session
    for index,e in ipairs({a,b}) do
        local driver,ui=drivers[index],e.ns.UI
        assert(ui.race.laps.completedLaps==3 and e:view().results.complete
            and not e:view().results.verified and e.finishSounds==1,
            "actual layered Physics/Checkpoints/Laps finish three laps exactly once")
        assert(table.concat(driver.levels,"")=="0101010101010" and driver.pads==6,
            "each actual lap climbs each base's outside ramp, leaves down its tunnel's climb and uses both boost pads")
        assert(e.sawLocalHigh and e.sawRemoteHigh and e.sawRemoteGround,
            "real floor telemetry drives pooled local/remote layers above and below the roofs: "
                ..index..":"..tostring(e.sawLocalHigh)..":"..tostring(e.sawRemoteHigh)..":"..tostring(e.sawRemoteGround))
        assert(e.objects==created[index],"layer transitions and results allocate no UI objects")
        local layeredPackets=0
        for _,packet in ipairs(e.sends) do
            if packet.prefix=="AZKRUN3" then
                layeredPackets=layeredPackets+1
                assert(#packet.payload==40 and e.ns.LiveProtocol.Layered.decode(packet.payload),
                    "actual Warsong telemetry uses the bounded floor-aware codec")
            end
        end
        assert(layeredPackets>0)
        assertBudget(e)
        e.routeDriver=nil;e.heldBeforeGO=nil;e.goPose=nil;e.stagedGrid=nil
    end
    assert(a.ns.UI.race==finishedRace,"delayed final telemetry does not restart the local race")
    a:click(a.ns.Menu.view.resultChangeTrack)
    for _=1,#a.ns.Courses.LIST do
        if a.ns.Menu.lobbyTrackId=="mirage_raceway" then break end
        a:click(a.ns.Menu.view.lobbyTrackChoice)
    end
    assert(a.ns.Menu.lobbyTrackId=="mirage_raceway")
    b:click(b.ns.UI.restartButton) -- Guest Play Again opens the retained lobby.
    assert(b.ns.Menu.screen=="multiplayer" and b:view().room,
        "guest explicitly returns from Warsong results to the same room")
    local receive=b.ns.SessionTransport.Message
    b.ns.SessionTransport.Message=function(prefix,payload,...)
        local accepted,reason=receive(prefix,payload,...)
        local message=prefix==b.ns.RaceProtocol.PREFIX and b.ns.RaceProtocol.decode(payload)
        if message and message.kind=="INVITE" and message.session~=previousSession then
            assert(accepted,"guest accepts the real layered-to-flat rematch: "..tostring(reason))
        end
        return accepted,reason
    end
    a:click(a.ns.Menu.view.ready)
    assert(a:view().phase=="inviting" and a:view().offer.trackId=="mirage_raceway"
        and a:view().offer.physicsVersion==12,"host offers the flat rematch with its own physics context")
    q:untilTrue(function() return b.ns.Menu.view.join.enabled end)
    assert(a:view().session~=previousSession and a:view().peer==GUEST and b:view().peer==HOST,
        "Warsong results retain the same roster for a fresh flat-course session")
    b:click(b.ns.Menu.view.join);readyAndLaunch(q)
    for _=1,90 do q:step() end
    for index,e in ipairs({a,b}) do
        local ui=e.ns.UI
        assert(e:view().offer.physicsVersion==12 and ui.trackId=="mirage_raceway"
            and ui.state.level==nil and e.cues["3"]==2 and e.cues["2"]==2 and e.cues["1"]==2,
            "flat rematch restores its original physics/state and full countdown")
        assert(ui.kart.sublevel==0 and ui.opponent.sublevel==0 and ui.opponentSublevel==0,
            "actual kart and cached opponent draw layers return to flat ordering")
        assert(e.objects==created[index])
        e:run(function()
            for _,course in ipairs(e.ns.Courses.LIST) do
                assert(#e.ns.SoloRecords.GetView(course.id).rows==0,"multiplayer cannot enter a solo leaderboard")
            end
        end)
        assertBudget(e)
    end
    a:run(a.ns.UI.MultiplayerAction,"leave");b:run(b.ns.UI.MultiplayerAction,"leave")
    q:untilTrue(function() return not a:view().transportBusy and not b:view().transportBusy end)
    originalPrint("Warsong multiplayer integration: real assisted Physics, 3 laps, ramps/pads/floor codec, delayed results and same-peer flat rematch PASS (offline mocks)")
end


-- Arathi is negotiated via actual menus and the same delayed two-client
-- transport as the other courses; this exercises the new flat Physics14
-- admission and live telemetry, without claiming native delivery or feel.
do
    local q=freshPair()
    local a,b=q.host,q.guest
    for _,entry in ipairs({{a,GUEST},{b,HOST}}) do
        entry[1]:run(function()
            entry[1].ns.Menu.view.peerName:SetText(entry[2])
            entry[1].ns.Menu.view.sessionCode:SetText("ARA001")
        end)
    end
    for _=1,#a.ns.Courses.LIST do
        if a.ns.Menu.lobbyTrackId=="arathi_basin" then break end
        a:click(a.ns.Menu.view.lobbyTrackChoice)
    end
    assert(a.ns.Menu.lobbyTrackId=="arathi_basin","host can offer Arathi in the real lobby")
    b:click(b.ns.Menu.view.listen);a:click(a.ns.Menu.view.host)
    q:untilTrue(function() return b.ns.Menu.view.join.enabled end)
    b:click(b.ns.Menu.view.join);readyAndLaunch(q)
    for _=1,90 do q:step() end
    for _,e in ipairs({a,b}) do
        local ui,view=e.ns.UI,e:view()
        assert(view.offer.trackId=="arathi_basin" and view.offer.trackVersion==2 -- Claude pin: Arathi version 2
            and view.offer.physicsVersion==14 and view.offer.laps==3
            and ui.trackId=="arathi_basin" and ui.track.boostOnGrass and not ui.track.layered and ui.race.targetLaps==3
            and ui.state.tick>0 and ui.state.level==nil,
            "both racers launch actual Arathi with the correct geometry, physics and target")
        assert(e.stagedGrid and e.cues["3"]==1 and e.cues["2"]==1 and e.cues["1"]==1,
            "the pooled two-kart grid precedes the full countdown")
        local sawFlat=false
        for _,packet in ipairs(e.sends) do
            if packet.prefix=="AZKRUN2" then sawFlat=true;assert(#packet.payload==40) end
        end
        assert(sawFlat,"Arathi uses the existing flat live codec")
        assertBudget(e)
    end
    a:run(a.ns.UI.MultiplayerAction,"leave");b:run(b.ns.UI.MultiplayerAction,"leave")
    q:untilTrue(function() return not a:view().transportBusy and not b:view().transportBusy end)
    originalPrint("Arathi multiplayer: menu/peer/grid/countdown/flat telemetry and budget PASS (offline mocks)")
end
