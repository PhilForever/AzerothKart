-- Front-end checks (Menu.lua) against a Lua-only widget mock. This is NOT proof
-- of the client's templates, fonts, layout or input safety; the actual client
-- check is in docs/art/ui/front-end.md.
-- The addon's files, in the TOC's order, as the client loads them.
local namespaceNames = {}
for line in io.lines("addon/AzerothKart/AzerothKart_Camelot.toc") do
    local name = line:match("^%s*([%w_]+)%.lua%s*$")
    if name then namespaceNames[#namespaceNames + 1] = name end
end
assert(namespaceNames[1] == "Track" and namespaceNames[#namespaceNames] == "Core", "TOC load order read")
local globalNames = {"CreateFrame", "UIParent", "InCombatLockdown", "GetCurrentKeyBoardFocus",
    "IsGameWindowFocused", "GetBuildInfo", "GetFramerate", "GetTime", "debugprofilestop",
    "DEFAULT_CHAT_FRAME", "C_AddOns", "SlashCmdList", "SLASH_AZEROTHKART1", "SLASH_AZEROTHKART2",
    "AzerothKart", "AzerothKartDB", "print", "PlaySound", "SOUNDKIT", "UISpecialFrames"}

local function withMock(savedDB, test, prepare)
    local previous = {}
    for index,name in ipairs(globalNames) do previous[index] = {name=name, value=_G[name]} end
    local env = {frames={}, counts={frames=0, textures=0, fontStrings=0}, output={}, focus=nil,
        textureModes={}, textureCalls=0, children={}, combat=false}
    local methods = {}
    local function object(kind)
        env.counts[kind] = env.counts[kind] + 1
        return setmetatable({scripts={}, events={}, shown=true, enabled=true}, {
            __index=function(_, key) return methods[key] or function() end end})
    end
    function methods:SetScript(name, callback) self.scripts[name] = callback end
    function methods:RegisterEvent(event) self.events[event] = true end
    function methods:UnregisterEvent(event) self.events[event] = nil end
    function methods:IsShown() return self.shown end
    local function cascade(frame, script)
        for _,child in ipairs(env.children[frame] or {}) do
            if child.shown then
                if child.scripts[script] then child.scripts[script](child) end
                cascade(child, script)
            end
        end
    end
    env.cascade = cascade
    function methods:Show()
        if self.shown then return end
        self.shown = true
        if self.scripts.OnShow then self.scripts.OnShow(self) end
        cascade(self, "OnShow")
    end
    function methods:Hide()
        if not self.shown then return end
        self.shown = false
        if self.scripts.OnHide then self.scripts.OnHide(self) end
        cascade(self, "OnHide")
    end
    -- Alt+Z: the parent hides and returns; the window's own flag stays shown.
    function env.parentToggle(frame)
        for _,script in ipairs({"OnHide", "OnShow"}) do
            if frame.scripts[script] then frame.scripts[script](frame) end
            cascade(frame, script)
        end
    end
    function methods:Enable() self.enabled = true end
    function methods:Disable() self.enabled = false end
    function methods:IsEnabled() return self.enabled end
    function methods:SetText(text) self.text = text end
    function methods:GetText() return self.text end
    function methods:SetSize(width, height) self.width, self.height = width, height end
    function methods:SetPoint(...) self.point = {...} end
    function methods:SetTexture(path)
        env.textureCalls = env.textureCalls + 1
        local mode = env.textureModes[path]
        if mode == "false" then return false end
        if mode == "throws" then error("mock texture refuses") end
        self.texturePath = path
        return true
    end
    function methods:SetTexCoord(...) self.texCoords = {...} end
    function methods:SetRotation(value) self.rotation = value end
    function methods:SetVertexColor(...) self.vertexColor = {...} end
    function methods:SetColorTexture(...) self.color = {...} end
    function methods:SetScale(value) self.scale = value end
    function methods:SetChecked(value) self.checked = value end
    function methods:LockHighlight() self.locked = true end
    function methods:UnlockHighlight() self.locked = false end
    function methods:SetFrameLevel(level) self.level = level end
    function methods:GetFrameLevel() return rawget(self, "level") or 1 end
    function methods:GetName() return rawget(self, "name") end
    function methods:GetChecked() return rawget(self, "checked") end
    function methods:CreateTexture(_, layer)
        local item = object("textures")
        item.parent, item.layer = self, layer
        return item
    end
    function methods:CreateFontString() local item = object("fontStrings"); item.parent = self; return item end
    _G.CreateFrame = function(kind, name, parent, template)
        if env.refuseTemplate and template == env.refuseTemplate then error("mock template missing") end
        local frame = object("frames")
        frame.kind, frame.name, frame.parent, frame.template = kind, name, parent, template
        env.frames[#env.frames + 1] = frame
        if parent then
            env.children[parent] = env.children[parent] or {}
            table.insert(env.children[parent], frame)
        end
        return frame
    end
    _G.UIParent = {}
    _G.InCombatLockdown = function() return env.combat end
    _G.GetCurrentKeyBoardFocus = function() return env.focus end
    _G.IsGameWindowFocused = function() return true end
    _G.GetBuildInfo = function() return "mock", "0", "test", 16001 end
    _G.GetFramerate = function() return 60 end
    _G.GetTime = function() return 0 end
    _G.debugprofilestop = function() return 0 end
    _G.DEFAULT_CHAT_FRAME = {AddMessage=function(_, text) env.output[#env.output + 1] = tostring(text) end}
    _G.SlashCmdList, _G.C_AddOns, _G.AzerothKart = {}, nil, nil
    _G.print = function() end
    _G.AzerothKartDB = savedDB
    env.sounds = {}
    _G.SOUNDKIT = {IG_MAINMENU_OPTION=852, IG_MAINMENU_OPEN=850, IG_MAINMENU_OPTION_CHECKBOX_ON=856,
        IG_MAINMENU_OPTION_CHECKBOX_OFF=857, UI_BATTLEGROUND_COUNTDOWN_TIMER=25477,
        UI_BATTLEGROUND_COUNTDOWN_FINISHED=25478, LFG_REWARDS=17316}
    _G.PlaySound = function(kit) env.sounds[#env.sounds + 1] = kit end
    _G.UISpecialFrames = {}
    local ok, err = pcall(function()
        local namespace = {}
        for _,name in ipairs(namespaceNames) do
            assert(loadfile("addon/AzerothKart/" .. name .. ".lua"))("AzerothKart", namespace)
        end
        env.namespace = namespace
        if prepare then prepare(env, namespace) end
        for _,frame in ipairs(env.frames) do
            if frame.events.ADDON_LOADED and frame.scripts.OnEvent then
                frame.scripts.OnEvent(frame, "ADDON_LOADED", "AzerothKart")
            end
        end
        test(env, namespace.UI, namespace.Menu, namespace)
    end)
    for _,entry in ipairs(previous) do _G[entry.name] = entry.value end
    assert(ok, err)
end

local function click(button) assert(button.scripts.OnClick, "button has a click handler"); button.scripts.OnClick(button) end
local function find(env, parent, text)
    for _,frame in ipairs(env.frames) do
        if frame.text == text and (not parent or frame.parent == parent) then return frame end
    end
    error("no control labelled " .. text)
end
local function counts(env)
    local copy = {}
    for key,value in pairs(env.counts) do copy[key] = value end
    return copy
end
local function sameCounts(env, before, label)
    for key,value in pairs(before) do assert(env.counts[key] == value, label .. ": allocated " .. key) end
end
local function visible(region)
    local walk = region
    while walk do
        if rawget(walk, "shown") == false then return false end
        walk = rawget(walk, "parent")
    end
    return true
end

-- Pure helpers ----------------------------------------------------------------
withMock(nil, function(_, _, Menu, AK)
    local f = Menu.formatTime
    assert(f(0) == "0:00.00" and f(62.345) == "1:02.35" and f(9.96, 1) == "0:10.0" and f(3600) == "60:00.00",
        "times read minutes, seconds and hundredths (or tenths)")
    assert(f(nil) == "--" and f(-1) == "--" and f(0 / 0) == "--" and f(math.huge) == "--",
        "missing or impossible times show a dash")
    local defaults = Menu.readPreferences(nil)
    assert(defaults.track == nil and defaults.kart == nil and defaults.effects == true and
           defaults.devInfo == false and defaults.scale == 1, "no saved data gives the defaults")
    local saved = Menu.readPreferences({preferences={track="mirage_raceway", kart="gyrocopter",
        effects=false, devInfo=true, scale=1.1}})
    assert(saved.track == "mirage_raceway" and saved.kart == "gyrocopter" and saved.effects == false and
           saved.devInfo == true and saved.scale == 1.1, "valid saved choices are kept")
    local junk = Menu.readPreferences({preferences={track="moon", kart=12, effects="yes", devInfo=1, scale=7}})
    assert(junk.track == nil and junk.kart == nil and junk.effects == true and junk.devInfo == false and
           junk.scale == 1, "unknown ids, types and sizes fall back to defaults")
    assert(Menu.readPreferences({preferences="broken"}).scale == 1, "a non-table record is ignored")

    local Physics = AK.Physics
    local lap, time, best = Menu.raceLines(nil, {bestLapTicks=nil})
    assert(lap == "LAP 1/3" and time == "0:00.0" and best == "BEST --", "before a run: lap one, zero clock")
    local running = {status="running", targetLaps=3, totalTicks=754,
        laps={completedLaps=1, bestLapTicks=600}}
    lap, time, best = Menu.raceLines(running, running.laps)
    assert(lap == "LAP 2/3" and time == "0:12.6" and best == "BEST 0:10.00",
        "a running clock shows tenths and the lap in progress: " .. time)
    local finished = {status="finished", targetLaps=3, totalTicks=1830,
        laps={completedLaps=3, bestLapTicks=590}}
    lap, time = Menu.raceLines(finished, finished.laps)
    assert(lap == "FINISHED" and time == "0:30.50", "a finished run shows hundredths")
    assert(Physics.FIXED_DT == 1 / 60, "times use the fixed simulation step")

    -- Lobby copy maps copied PeerSession views; capabilities come only from them.
    local soon = Menu.lobbyPresentation(nil)
    assert(not soon.available and not soon.host and not soon.join and not soon.ready and not soon.start
        and not soon.leave, "without a session bridge every lobby control stays disabled")
    local Session, Protocol = AK.PeerSession, AK.RaceProtocol
    local function options(role)
        return {role=role, peer=role == "host" and "Birch Vale" or "Amber Stone", session="ABC123",
            physicsVersion=7, trackVersions={test_oval=2, mirage_raceway=1}, laps=3}
    end
    local host = assert(Session.new(options("host"), 0, Protocol))
    local copy = Menu.lobbyPresentation(Session.view(host))
    assert(copy.available and copy.host and not copy.join and not copy.ready and not copy.start and copy.leave
        and copy.title == "Hosting" and copy.status == "Pick a track, then invite your friend.",
        "an idle host may invite and leave")
    assert(Session.invite(host, 0, "test_oval"))
    local payload
    Session.update(host, 0.5, function(message) payload = message; return "accepted" end)
    copy = Menu.lobbyPresentation(Session.view(host))
    assert(not copy.host and copy.status:find("Sending invite", 1, true) and copy.status:find("1 of 3", 1, true),
        "a pending invite shows its attempt and cannot be repeated: " .. copy.status)
    local guest = assert(Session.new(options("guest"), 0, Protocol))
    copy = Menu.lobbyPresentation(Session.view(guest))
    assert(copy.title == "Joining" and copy.status == "Waiting for Amber Stone to invite you." and not copy.join,
        "a listening guest waits for the named host")
    assert(Session.receive(guest, 0.6, Protocol.PREFIX, payload, "WHISPER", "Amber Stone"))
    copy = Menu.lobbyPresentation(Session.view(guest))
    assert(copy.join and copy.status == "Amber Stone invited you to race. Join to enter the lobby."
        and copy.friend == "Amber Stone (not joined)", "an invited guest may join")
    assert(Session.cancel(guest, 1, "left", false))
    copy = Menu.lobbyPresentation(Session.view(guest))
    assert(copy.status == "You left the session." and not copy.join and not copy.leave and copy.friend == "Open slot",
        "a closed session explains itself and offers nothing")
    copy = Menu.lobbyPresentation({phase="lobby", role="guest", peer="Amber Stone", localReady=true,
        localReadyConfirmed=false, peerReady=true, canSetReady=true, canLeave=true})
    assert(copy.ready and copy.readyLabel == "Not ready" and copy.you == "Ready (sending)" and
           copy.friendReady == "Ready" and copy.friend == "Amber Stone" and not copy.start,
        "lobby readiness and its unconfirmed send are visible")
    copy = Menu.lobbyPresentation({phase="closed", role="host", peer="Birch Vale", reason="peer_combat"})
    assert(copy.status == "Birch Vale entered combat.", "peer reasons name the peer")
    assert(Menu.lobbyPresentation({phase="warp", canInvite=true}).available == false,
        "an unknown phase is not presented as a working session")
end)

-- Creation, the main menu and the object budget -------------------------------
withMock({schemaVersion=1, custom={keep=true}}, function(env, UI, Menu)
    assert(not Menu.disabled and Menu.root and UI.window, "the front end builds with the window")
    -- Core's bootstrap event frame is the only uncounted object.
    assert(UI.objects.frames + 1 == env.counts.frames and UI.objects.textures == env.counts.textures and
           UI.objects.fontStrings == env.counts.fontStrings,
        ("every created object is counted: %d/%d/%d against %d/%d/%d"):format(UI.objects.frames,
            UI.objects.textures, UI.objects.fontStrings, env.counts.frames, env.counts.textures,
            env.counts.fontStrings))
    assert(UI.objects.frames == 65 and UI.objects.textures == 160 and UI.objects.fontStrings == 79,
        ("explicit budget 65/160/79, got %d/%d/%d"):format(UI.objects.frames, UI.objects.textures,
            UI.objects.fontStrings))
    assert(AzerothKartDB.preferences == nil, "creation saves nothing")
    local before = counts(env)
    local state, track, kart = UI.state, UI.trackId, UI.kartId
    UI.Toggle()
    assert(UI.window:IsShown() and Menu.screen == "home" and Menu.root:IsShown() and
           Menu.screens.home:IsShown(), "opening the window shows the main menu")
    for _,button in ipairs({UI.startButton, UI.stopButton, UI.trackButton, UI.kartButton, UI.probeButton,
        Menu.view.mainMenu}) do
        assert(not button:IsShown(), "the race bar hides behind the menus")
    end
    local labels = {}
    for _,button in ipairs(Menu.view.homeButtons) do labels[#labels + 1] = button.text end
    assert(table.concat(labels, ",") == "Single Player,Multiplayer |cffff8c26(soon)|r,Garage,How to Play,Settings",
        "the main menu offers clear choices: " .. table.concat(labels, ","))
    for _,screen in ipairs({"multiplayer", "help", "settings", "garage", "tracks", "karts", "home"}) do
        Menu.Show(screen)
        assert(Menu.screen == screen and Menu.screens[screen]:IsShown(), screen .. " shows")
        local shown, seen = 0, {}
        for _,box in pairs(Menu.screens) do -- the garage reuses the kart dialog
            if box:IsShown() and not seen[box] then shown = shown + 1 end
            seen[box] = true
        end
        assert(shown == 1, screen .. " shows one dialog at a time")
    end
    assert(UI.state == state and UI.trackId == track and UI.kartId == kart and UI.race == nil and not UI.active,
        "browsing menus never touches the run, track or kart")
    sameCounts(env, before, "menu navigation")
    assert(AzerothKartDB.custom.keep == true and AzerothKartDB.schemaVersion == 1 and AzerothKartDB.preferences == nil,
        "browsing saves nothing and other saved fields stay intact")
end)

-- Single Player: track, kart, race, results and back to the menu -------------
withMock({schemaVersion=1}, function(env, UI, Menu)
    UI.Toggle()
    local before = counts(env)
    click(Menu.view.homeButtons[1])
    assert(Menu.screen == "tracks" and Menu.view.trackStep:IsShown(), "Single Player starts with the track")
    click(Menu.view.trackButtons.mirage_raceway)
    assert(UI.trackId == "mirage_raceway" and AzerothKartDB.preferences.track == "mirage_raceway",
        "choosing a track selects and remembers it")
    assert(Menu.view.trackPreview.texturePath == Menu.PREVIEW_PATH and
           Menu.view.trackPreview.texCoords[2] == 0.5, "the preview shows the chosen track's cell")
    click(Menu.view.trackNext)
    assert(Menu.screen == "karts" and Menu.view.race.text == "Race!", "Next leads to the kart choice")
    click(Menu.view.kartButtons.steam_tank)
    assert(UI.kartId == "steam_tank" and AzerothKartDB.preferences.kart == "steam_tank" and
           Menu.view.stage.texturePath == UI.kartSprite.path, "choosing a kart selects, previews and remembers it")
    local stage, turntable = Menu.view.stage, Menu.view.stageFrame0
    local first = stage.texCoords[1] .. "," .. stage.texCoords[3]
    turntable.scripts.OnUpdate(turntable, 0.5)
    assert(stage.texCoords[1] .. "," .. stage.texCoords[3] ~= first, "the garage turntable spins the sheet")
    env.focus = {}
    click(Menu.view.race)
    assert(not UI.active and Menu.screen == "karts" and UI.status.text:find("Close text input", 1, true),
        "a refused start keeps the menu and explains why")
    env.focus = nil
    click(Menu.view.race)
    assert(UI.active and UI.race.status == "countdown" and not Menu.root:IsShown() and Menu.screen == nil,
        "Race! starts a countdown and uncovers the track")
    assert(UI.stopButton:IsShown() and not UI.startButton:IsShown() and not UI.trackButton:IsShown() and
           Menu.view.capture:IsShown(), "while racing only Stop shows, with the capture notice")
    assert(Menu.view.lap.text == "LAP 1/3" and Menu.view.time.text == "0:00.0", "the countdown shows lap one")
    for _ = 1, 180 + 90 do UI.OnUpdate(1 / 60) end
    assert(UI.race.status == "running" and Menu.view.time.text == "0:01.5", "the race clock runs: " ..
        tostring(Menu.view.time.text))
    Menu.Show("home")
    assert(Menu.screen == nil and not Menu.root:IsShown(), "no menu can cover a live run")
    click(UI.stopButton)
    assert(not UI.active and UI.summary:IsShown() and Menu.screen == nil, "Stop shows the results")
    assert(not UI.startButton:IsShown() and not UI.stopButton:IsShown() and not Menu.view.capture:IsShown(),
        "the results dialog owns the choices")
    assert(Menu.view.resultLine.text:find("Mirage Raceway", 1, true) and
           Menu.view.resultLine.text:find("Steam Tank", 1, true), "results name the track and kart")
    click(find(env, UI.summary, "Main Menu"))
    assert(Menu.screen == "home" and not UI.summary:IsShown() and UI.dismissedSummaryRace == UI.race,
        "Main Menu dismisses the results and returns home")
    UI.Toggle(); UI.Toggle()
    assert(Menu.screen == "home" and not UI.summary:IsShown(), "dismissed results do not come back on reopen")
    sameCounts(env, before, "a full single-player round")
end)

-- Results paths, the track view and remembered lap times -----------------------
withMock(nil, function(env, UI, Menu, AK)
    UI.Toggle()
    local Track = AK.Track
    click(Menu.view.homeButtons[1]); click(Menu.view.trackNext); click(Menu.view.race)
    for _ = 1, 180 do UI.OnUpdate(1 / 60) end
    local function cross(index, wait)
        for _ = 1, wait do UI.OnUpdate(1 / 60) end
        local gate = Track.gates[index]
        UI.state.x = (gate.ax + gate.bx) / 2 - gate.nx
        UI.state.y = (gate.ay + gate.by) / 2 - gate.ny
        UI.state.heading = gate.nx == 1 and 0 or gate.nx == -1 and math.pi or
            gate.ny == 1 and math.pi / 2 or -math.pi / 2
        UI.state.speed, UI.state.steering = 200, 0
        UI.OnUpdate(1 / 60)
    end
    for lap = 1, 3 do
        for index = 1, 4 do cross(index, lap == 2 and 2 or 5) end
    end
    assert(not UI.active and UI.race.status == "finished" and UI.summary:IsShown(), "three laps finish the run")
    local laps = Menu.view.resultLaps.text
    assert(laps:find("Lap 1", 1, true) and laps:find("Lap 2", 1, true) and laps:find("Lap 3", 1, true) and
           laps:find("|cff66ff66Lap 2", 1, true), "results list each lap and mark the fastest: " .. laps)
    assert(Menu.view.lap.text == "FINISHED", "the race HUD shows the finish")
    click(UI.dismissSummaryButton)
    assert(not UI.summary:IsShown() and Menu.screen == nil and UI.startButton:IsShown() and
           UI.trackButton:IsShown() and UI.kartButton:IsShown() and Menu.view.mainMenu:IsShown() and
           not UI.stopButton:IsShown(), "Close results leaves the track view with the bar")
    click(Menu.view.mainMenu)
    assert(Menu.screen == "home", "the bar's Main Menu returns home")
    click(Menu.view.homeButtons[1]); click(Menu.view.trackNext); click(Menu.view.race)
    UI.Stop("second run")
    click(find(env, UI.summary, "Change Kart"))
    assert(Menu.screen == "karts" and not UI.summary:IsShown(), "Change Kart reopens the kart choice")
    click(Menu.view.race)
    UI.Stop("third run")
    click(find(env, UI.summary, "Change Track"))
    assert(Menu.screen == "tracks", "Change Track reopens the track choice")
    click(Menu.view.trackNext); click(Menu.view.race)
    UI.Stop("fourth run")
    click(UI.restartButton)
    assert(UI.active and Menu.screen == nil, "Restart races again straight away")
end)

-- Garage, settings and their saved effect ----------------------------------------
withMock({schemaVersion=1}, function(env, UI, Menu)
    UI.Toggle()
    click(Menu.view.homeButtons[3])
    assert(Menu.screen == "garage" and Menu.view.race.text == "Done" and not Menu.view.kartStep:IsShown(),
        "the garage is the kart choice without the race step")
    local order = env.namespace.Presentation.KART_ORDER
    click(find(env, Menu.screens.garage, ">"))
    assert(UI.kartId == order[2], "the arrows step through the karts")
    click(find(env, Menu.screens.garage, "<")); click(find(env, Menu.screens.garage, "<"))
    assert(UI.kartId == order[#order], "the arrows wrap around")
    env.textureModes[env.namespace.Presentation.KART_SPRITES.gyrocopter.path] = "false"
    local before = UI.kartId
    click(Menu.view.kartButtons.gyrocopter)
    assert(UI.kartId == before and Menu.view.race.text == "Done" and AzerothKartDB.preferences.kart == before and
           Menu.messages.garage.text == "Gyrocopter could not load; keeping " ..
               env.namespace.Presentation.KART_SPRITES[before].name .. ".",
        "a kart that cannot load keeps the current one, says so and is not remembered")
    click(Menu.view.race)
    assert(Menu.screen == "home" and not UI.active and UI.race == nil, "Done returns home without racing")
    click(Menu.view.homeButtons[5])
    assert(Menu.screen == "settings", "Settings opens")
    Menu.SetScale(1.25)
    assert(UI.window.scale == 1.25 and AzerothKartDB.preferences.scale == 1.25, "window size applies and saves")
    Menu.SetScale(3)
    assert(UI.window.scale == 1.25, "unknown sizes are ignored")
    click(Menu.view.effects)
    assert(UI.effectsOff and AzerothKartDB.preferences.effects == false, "effects can be switched off")
    click(Menu.view.devInfo)
    assert(AzerothKartDB.preferences.devInfo == true and UI.hud:IsShown(), "developer info shows the timing line")
    Menu.Show(nil)
    assert(UI.probeButton:IsShown(), "developer info shows Print Probe on the track view")
    click(Menu.view.mainMenu); click(Menu.view.homeButtons[1]); click(Menu.view.trackNext); click(Menu.view.race)
    UI.state.drifting, UI.state.driftTier, UI.state.boostTicks = true, 2, 30
    for _ = 1, 300 do UI.OnUpdate(1 / 60) end
    for _,list in ipairs({UI.fxSmoke, UI.fxSparks, UI.fxFlames}) do
        for _,piece in ipairs(list) do assert(not piece:IsShown(), "no effect shows while switched off") end
    end
    UI.Stop("settings run")
end)

-- Saved choices come back after a reload ------------------------------------------
withMock({schemaVersion=1, preferences={version=1, track="mirage_raceway", kart="gyrocopter",
    effects=false, devInfo=true, scale=1.1}}, function(env, UI, Menu)
    assert(UI.kartId == "gyrocopter" and UI.effectsOff and UI.window.scale == 1.1,
        "the kart, effects and window size return at load")
    assert(UI.trackId == "test_oval", "the track waits for the window, which Mirage's loader needs")
    UI.Toggle()
    assert(UI.trackId == "mirage_raceway" and Menu.screen == "home", "the saved track returns on first open")
    Menu.Show(nil)
    assert(UI.probeButton:IsShown() and UI.hud:IsShown(), "developer info returns")
end)

-- Choices made with the bar's quick buttons are remembered too, and a saved
-- choice that fails to load is kept for next time rather than overwritten.
local BACKGROUND = "Interface\\AddOns\\AzerothKart\\Assets\\Tracks\\SaltFlats\\Background.tga"
withMock({schemaVersion=1, preferences={version=1, kart="gyrocopter", track="mirage_raceway"}}, function(env, UI, Menu, AK)
    assert(UI.kartId == "goblin_mortar_trike" and AzerothKartDB.preferences.kart == "gyrocopter",
        "a saved kart that cannot load keeps the default without forgetting the choice")
    UI.Toggle()
    assert(UI.trackId == "test_oval" and AzerothKartDB.preferences.track == "mirage_raceway",
        "a saved track that cannot load keeps the default without forgetting the choice")
    env.textureModes = {}
    Menu.Show(nil)
    click(UI.kartButton)
    assert(UI.kartId == "steam_tank" and AzerothKartDB.preferences.kart == "steam_tank",
        "the bar's kart button is remembered")
    click(UI.trackButton)
    assert(UI.trackId == "mirage_raceway" and AzerothKartDB.preferences.track == "mirage_raceway",
        "the bar's track button selects and is remembered")
    click(UI.trackButton)
    assert(UI.trackId == "test_oval" and AzerothKartDB.preferences.track == "test_oval",
        "switching back is remembered too")
end, function(env, AK)
    env.textureModes[AK.Presentation.KART_SPRITES.gyrocopter.path] = "false"
    env.textureModes[BACKGROUND] = "false"
end)

-- Only a real close resets the window: Alt+Z keeps the screen the player was on.
withMock(nil, function(env, UI, Menu)
    UI.Toggle()
    click(Menu.view.homeButtons[5])
    local opens = 0
    for _,kit in ipairs(env.sounds) do if kit == 850 then opens = opens + 1 end end
    env.parentToggle(UI.window)
    local after = 0
    for _,kit in ipairs(env.sounds) do if kit == 850 then after = after + 1 end end
    assert(Menu.screen == "settings" and after == opens, "a hidden UI coming back keeps Settings, silently")
    UI.Toggle(); UI.Toggle()
    assert(Menu.screen == "home", "closing and reopening returns to the main menu")
end)

-- Combat: no saved-track restore while fighting; it happens on the next open.
withMock({schemaVersion=1, preferences={version=1, track="mirage_raceway"}}, function(env, UI, Menu)
    env.combat = true
    UI.Toggle()
    assert(UI.trackId == "test_oval" and Menu.screen == "home", "no track change during combat")
    click(Menu.view.homeButtons[1]); click(Menu.view.trackButtons.mirage_raceway)
    assert(UI.trackId == "test_oval" and Menu.messages.tracks.text == "Leave combat to change tracks.",
        "a combat refusal says so plainly")
    env.combat = false
    UI.Toggle(); UI.Toggle()
    assert(UI.trackId == "mirage_raceway" and AzerothKartDB.preferences.track == "mirage_raceway",
        "the saved track returns on the next open out of combat")
end)

-- A deliberate choice is remembered even when it was already current, and it
-- replaces a saved-track restore still waiting for an open out of combat.
withMock({schemaVersion=1, preferences={version=1, track="mirage_raceway"}}, function(env, UI, Menu)
    env.combat = true
    UI.Toggle()
    env.combat = false
    assert(UI.trackId == "test_oval" and not Menu.trackRestored, "the restore waits for an open out of combat")
    click(Menu.view.homeButtons[1]); click(Menu.view.trackButtons.test_oval)
    assert(UI.trackId == "test_oval" and AzerothKartDB.preferences.track == "test_oval",
        "choosing the current track is remembered")
    UI.Toggle(); UI.Toggle()
    assert(UI.trackId == "test_oval" and AzerothKartDB.preferences.track == "test_oval",
        "the player's choice is not overridden by the old saved track")
end)
withMock({schemaVersion=1, preferences={version=1, track="mirage_raceway", kart="gyrocopter"}},
    function(env, UI, Menu, AK)
    UI.Toggle()
    assert(UI.trackId == "test_oval" and UI.kartId == "goblin_mortar_trike", "both saved choices failed to load")
    UI.Toggle(); UI.Toggle()
    assert(AzerothKartDB.preferences.track == "mirage_raceway" and AzerothKartDB.preferences.kart == "gyrocopter",
        "an untouched failed restore keeps the saved choices")
    click(Menu.view.homeButtons[1]); click(Menu.view.trackButtons.test_oval)
    assert(AzerothKartDB.preferences.track == "test_oval", "choosing the fallback track replaces the failed one")
    click(Menu.view.trackNext); click(Menu.view.kartButtons.goblin_mortar_trike)
    assert(UI.kartId == "goblin_mortar_trike" and AzerothKartDB.preferences.kart == "goblin_mortar_trike",
        "choosing the fallback kart replaces the failed one")
end, function(env, AK)
    env.textureModes[AK.Presentation.KART_SPRITES.gyrocopter.path] = "false"
    env.textureModes[BACKGROUND] = "false"
end)
withMock({schemaVersion=1, preferences={version=1, track="mirage_raceway"}}, function(env, UI, Menu)
    env.combat = true
    UI.Toggle()
    env.combat = false
    Menu.Show(nil)
    click(UI.trackButton)
    assert(UI.trackId == "mirage_raceway" and AzerothKartDB.preferences.track == "mirage_raceway", "the bar's choice")
    click(UI.trackButton)
    assert(UI.trackId == "test_oval" and AzerothKartDB.preferences.track == "test_oval",
        "the bar's Track button is remembered before any restore")
    UI.Toggle(); UI.Toggle()
    assert(UI.trackId == "test_oval", "and a waiting restore no longer replaces it")
end)

-- Saving keeps what this version does not know and never replaces a newer record.
withMock({schemaVersion=1, preferences={version=1, kart="steam_tank", futureField="keep"}}, function(env, UI, Menu)
    UI.Toggle(); click(Menu.view.homeButtons[3]); click(Menu.view.kartButtons.gyrocopter)
    assert(AzerothKartDB.preferences.kart == "gyrocopter" and AzerothKartDB.preferences.futureField == "keep"
        and AzerothKartDB.preferences.version == 1, "unknown preference fields survive a save")
end)
withMock({schemaVersion=1, preferences={version=2, kart="steam_tank", newShape={1}}}, function(env, UI, Menu)
    assert(UI.kartId == "steam_tank", "a newer record's known fields are still read")
    UI.Toggle(); click(Menu.view.homeButtons[3]); click(Menu.view.kartButtons.gyrocopter)
    assert(UI.kartId == "gyrocopter" and AzerothKartDB.preferences.version == 2 and
           AzerothKartDB.preferences.kart == "steam_tank", "a newer version's record is never overwritten")
end)

-- Window sizes that would not fit the screen are offered disabled, and a saved
-- size that no longer fits falls back to the largest that does.
withMock({schemaVersion=1, preferences={version=1, scale=1.25}}, function(env, UI, Menu)
    assert(UI.window.scale == 1, "a saved 125% shrinks to 100% on a 1366x768 screen")
    UI.Toggle(); click(Menu.view.homeButtons[5])
    local disabled = {}
    for _,frame in ipairs(env.frames) do
        if frame.parent == Menu.screens.settings and tostring(frame.text):find("%%") and not frame:IsEnabled() then
            disabled[#disabled + 1] = frame.text
        end
    end
    table.sort(disabled)
    assert(table.concat(disabled, ",") == "110%,125%", "sizes too big for the screen are disabled: " ..
        table.concat(disabled, ","))
    Menu.SetScale(1.1)
    assert(UI.window.scale == 1 and AzerothKartDB.preferences.scale == 1.25, "a size that does not fit is refused")
end, function()
    UIParent.GetWidth = function() return 1366 end
    UIParent.GetHeight = function() return 768 end
end)

-- Multiplayer stays a clearly marked preview until a session bridge exists ------
withMock(nil, function(env, UI, Menu)
    UI.Toggle()
    click(Menu.view.homeButtons[2])
    local view = Menu.view
    assert(Menu.screen == "multiplayer" and not view.host:IsEnabled() and not view.join:IsEnabled() and
           not view.ready:IsEnabled() and not view.start:IsEnabled() and not view.leave:IsEnabled(),
        "every multiplayer control is disabled while it is coming soon")
    assert(view.lobbyTitle.text == "Lobby preview" and view.friend.text == "Open slot",
        "the preview shows no invented player")
    Menu.SetSessionBridge({view=function()
        return {phase="lobby", role="host", peer="Birch Vale", localReady=true, localReadyConfirmed=true,
            peerReady=true, canSetReady=true, canStart=true, canLeave=true}
    end})
    assert(view.ready:IsEnabled() and view.start:IsEnabled() and view.leave:IsEnabled() and
           not view.host:IsEnabled() and view.lobbyTitle.text == "Hosting" and view.friend.text == "Birch Vale",
        "a future bridge's capabilities, and only those, enable controls")
    assert(view.start.scripts.OnClick == nil and view.ready.scripts.OnClick == nil,
        "no session command is wired yet")
    Menu.SetSessionBridge({view=function() error("bridge failure") end})
    assert(not view.leave:IsEnabled() and view.lobbyTitle.text == "Lobby preview",
        "a failing bridge falls back to the disabled preview")
    Menu.SetSessionBridge(nil)
end)

-- A front end that cannot build hands the window back to the basic controls -----
withMock(nil, function(env, UI, Menu)
    assert(Menu.disabled and env.output[1]:find("menus unavailable", 1, true),
        "a build failure is reported once")
    UI.Toggle()
    assert(UI.window:IsShown() and UI.startButton:IsShown() and UI.trackButton:IsShown() and
           UI.kartButton:IsShown() and not (Menu.root and Menu.root:IsShown()), "the basic window remains usable")
    assert(not Menu.view.mainMenu or not Menu.view.mainMenu:IsShown(), "nothing the menus added covers the bar")
    UI.Start()
    assert(UI.active and UI.stopButton:IsShown(), "racing still starts")
    click(UI.stopButton)
    assert(not UI.active, "Stop still ends the run")
end, function(_, AK) AK.Presentation.KART_ORDER = nil end)

-- Sounds: menu clicks, countdown beeps, the finish fanfare, and a mute switch ------
withMock(nil, function(env, UI, Menu, AK)
    assert(#UISpecialFrames == 0, "the Escape that stops a run must not also close the window")
    UI.Toggle()
    assert(env.sounds[#env.sounds] == 850, "opening plays the menu-open sound")
    click(Menu.view.homeButtons[1])
    assert(env.sounds[#env.sounds] == 852, "menu buttons click")
    click(Menu.view.trackNext)
    env.sounds = {}
    click(Menu.view.race)
    for _ = 1, 200 do UI.OnUpdate(1 / 60) end
    assert(table.concat(env.sounds, ",") == "852,25477,25477,25477,25478",
        "Race! clicks, then the countdown ticks three times and sounds GO: " .. table.concat(env.sounds, ","))
    local Track = AK.Track
    for _ = 1, 3 do
        for index = 1, 4 do
            local gate = Track.gates[index]
            UI.state.x, UI.state.y = (gate.ax + gate.bx) / 2 - gate.nx, (gate.ay + gate.by) / 2 - gate.ny
            UI.state.heading = gate.nx == 1 and 0 or gate.nx == -1 and math.pi or
                gate.ny == 1 and math.pi / 2 or -math.pi / 2
            UI.state.speed, UI.state.steering = 200, 0
            UI.OnUpdate(1 / 60)
        end
    end
    assert(UI.race.status == "finished" and env.sounds[#env.sounds] == 17316, "finishing plays the fanfare")
    local fanfares = #env.sounds
    UI.Toggle(); UI.Toggle()
    assert(UI.summary:IsShown() and Menu.screen == nil and env.sounds[#env.sounds] ~= 17316 and
           #env.sounds == fanfares + 1, "reopening shows the results again without another fanfare")
    click(find(env, UI.summary, "Main Menu")); click(Menu.view.homeButtons[5])
    click(Menu.view.sound)
    assert(AzerothKartDB.preferences.sound == false, "sound effects can be switched off and are saved")
    env.sounds = {}
    click(find(env, Menu.screens.settings, "Back")); click(Menu.view.homeButtons[1])
    click(Menu.view.trackNext); click(Menu.view.race)
    for _ = 1, 200 do UI.OnUpdate(1 / 60) end
    assert(#env.sounds == 0, "muted menus and countdown stay silent")
    UI.Stop("sound run")
end)

-- Missing client templates fall back to plain panel buttons -----------------------
withMock(nil, function(env, UI, Menu)
    assert(not Menu.disabled and Menu.view.homeButtons[1].template == "UIPanelButtonTemplate",
        "the Game Menu button template is optional")
end, function(env) env.refuseTemplate = "MainMenuFrameButtonTemplate" end)

print("mock menus: 7 screens, single-player flow, results paths, garage, settings, saved choices, " ..
    "coming-soon multiplayer and fallbacks (client appearance still pending)")
