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
    local e={identity=identity,offset=offset,now=offset,frames={},sends={},output={},objects=0}
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
        assert(prefix=="AZKART2" or prefix=="AZKCLK1" or prefix=="AZKRUN1")
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
function p:untilTrue(predicate)
    for _=1,3600 do if predicate() then return end; self:step() end
    error("fully loaded clients did not reach expected menu/race state")
end

local h,g=p.host,p.guest
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
p:untilTrue(function() return h.ns.UI.liveActive and g.ns.UI.liveActive end)
local counts={host=h.objects,guest=g.objects}
for _,e in ipairs({h,g}) do
    assert(e.ns.UI.active and e.ns.UI.window.keyboard and not e.ns.UI.window.propagate)
    assert(e.ns.UI.trackId=="mirage_raceway" and e.ns.UI.race.countdownTicks==0)
    e:run(e.ns.UI.window.scripts.OnKeyDown,e.ns.UI.window,"W")
end
for _=1,180 do p:step() end
for _,role in ipairs({"host","guest"}) do
    local e=p[role]; local ui=e.ns.UI
    assert(ui.active and ui.state.tick>=175 and ui.state.tick<=190)
    assert(ui.liveView.remote and ui.liveView.remote.tick>0 and ui.liveView.remoteVerified==false)
    assert(e.sawMovingOpponent and visible(ui.opponentLabel),
        "received peer pose reaches the real pooled canvas marker and label")
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
