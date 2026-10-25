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
    function methods:SetFocus() env.focus = self end
    function methods:ClearFocus() if env.focus == self then env.focus = nil end end
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
    local _, blankWritable = Menu.readPreferences(nil)
    local _, futureRootWritable = Menu.readPreferences({schemaVersion=777, preferences={version=1}})
    assert(blankWritable and not futureRootWritable, "blank defaults are writable but a future root is read-only")

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
    -- Bootstrap and the single background score receiver are outside UI's pool.
    assert(UI.objects.frames + 2 == env.counts.frames and UI.objects.textures == env.counts.textures and
           UI.objects.fontStrings == env.counts.fontStrings,
        ("every created object is counted: %d/%d/%d against %d/%d/%d"):format(UI.objects.frames,
            UI.objects.textures, UI.objects.fontStrings, env.counts.frames, env.counts.textures,
            env.counts.fontStrings))
    -- Twelve track buttons under three cup headings; eight pooled gate strips.
    -- Ten kart buttons; the lobby adds two EditBoxes and Listen/track buttons.
    -- The observational remote kart adds one texture and one font string.
    -- Saved highscores add six frames and 52 labels, including the results notice.
    -- The player's kart outline adds a texture, its Settings check a button and two labels.
    assert(UI.objects.frames == 90 and UI.objects.textures == 167 and UI.objects.fontStrings == 136,
        ("explicit budget 90/167/136, got %d/%d/%d"):format(UI.objects.frames, UI.objects.textures,
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
    local experimental = Menu.bridge and type(Menu.bridge.action) == "function"
    local mpLabel = experimental and "Multiplayer |cffff8c26(experimental)|r" or "Multiplayer |cffff8c26(soon)|r"
    assert(table.concat(labels, ",") == "Single Player," .. mpLabel .. ",Garage,How to Play,Settings,Highscores",
        "the main menu offers clear choices: " .. table.concat(labels, ","))
    for _,screen in ipairs({"multiplayer", "help", "settings", "garage", "tracks", "karts", "highscores", "home"}) do
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

-- Saved highscores are a pooled, read-only view; browsing cannot select a track.
withMock({schemaVersion=1, custom={keep=true}}, function(env, UI, Menu, AK)
    local before, selected, state = counts(env), UI.trackId, UI.state
    local db, rows, reads, requested = AzerothKartDB, {}, 0, {}
    for index=1,25 do
        rows[index] = {playerName="Racer " .. index, totalTicks=3600 + index,
            finishedAt=1700000000 + index, kartId="steam_tank"}
    end
    rows[1].playerName = "Pipe|Name"
    AK.SoloRecords = {
        GetView=function(id)
            reads = reads + 1; requested[#requested + 1] = id
            return {scope="local", publication="Global publishing pending", writable=true,
                rows=rows, trackId=id, lastResult={message="Saved on this computer."}}
        end,
        FormatTime=function(ticks) return "T" .. ticks end,
        FormatDate=function(epoch) return "D" .. epoch end,
    }
    local select = UI.SelectTrack
    UI.SelectTrack = function() error("highscore browsing must not select a driving track") end
    UI.Toggle()
    assert(reads == 0, "opening the home menu does not read or sort scores")
    click(Menu.view.homeButtons[6])
    assert(Menu.screen == "highscores" and reads == 1 and requested[1] == selected,
        "Highscores opens the current track's saved board on explicit request")
    assert(Menu.view.highscoreScope.text == "Local cache | Global publishing pending" and
        Menu.view.highscorePage.text == "Page 1 / 3" and not Menu.view.highscorePrevious.enabled and
        Menu.view.highscoreNext.enabled, "local scope, pending publication and bounded pages are explicit")
    local first = Menu.view.highscoreRows[1]
    assert(#Menu.view.highscoreRows == 10 and first.rank.text == "1" and first.name.text == "Pipe||Name" and
        first.total.text == "T3601" and first.date.text == "D1700000001",
        "ten pooled rows show escaped names, full totals and UTC dates from the backend")
    for _=1,20 do Menu.Sync(); UI.OnUpdate(1 / 60) end
    assert(reads == 1, "frame updates and menu sync never query or sort records")
    click(Menu.view.highscoreNext)
    assert(reads == 2 and Menu.view.highscoreRows[1].rank.text == "11" and Menu.view.highscorePage.text == "Page 2 / 3",
        "Next refreshes the second bounded page")
    click(Menu.view.highscoreNext)
    assert(Menu.view.highscoreRows[1].rank.text == "21" and Menu.view.highscoreRows[5].name.text == "Racer 25" and
        Menu.view.highscoreRows[6].name.text == "" and not Menu.view.highscoreNext.enabled,
        "the last page clears unused rows and disables Next")
    click(Menu.view.highscorePrevious)
    assert(Menu.view.highscorePage.text == "Page 2 / 3", "Previous returns one page")
    click(Menu.view.highscoreTrack)
    assert(Menu.highscorePage == 1 and requested[#requested] ~= selected and UI.trackId == selected,
        "track browsing resets only the board page and leaves the driving track alone")
    click(find(env, Menu.screens.highscores, "Back")); click(Menu.view.homeButtons[6])
    assert(Menu.screen == "highscores" and requested[#requested] == selected and Menu.highscorePage == 1,
        "reopening uses the current driving track without changing it")
    assert(UI.state == state and UI.race == nil and not UI.active and AzerothKartDB == db and
        AzerothKartDB.custom.keep and AzerothKartDB.preferences == nil and rows[1].playerName == "Pipe|Name",
        "browsing preserves physics, saved preferences and borrowed rows")
    UI.SelectTrack = select
    sameCounts(env, before, "highscore pages, track browsing and revisit")
end)

withMock({schemaVersion=1, highscores={version=99, future="keep"}}, function(env, UI, Menu, AK)
    local saved, before = AzerothKartDB.highscores, counts(env)
    AK.SoloRecords = {GetView=function()
        return {scope="local", writable=false, problem="future_schema", rows={}}
    end}
    UI.Toggle(); click(Menu.view.homeButtons[6])
    assert(Menu.view.highscoreStatus.text == "Saved records are read-only in this build." and
        Menu.view.highscoreEmpty.text == "Saved records cannot be displayed in this build." and
        not Menu.view.highscoreNext.enabled and not Menu.view.highscorePrevious.enabled,
        "an unknown future store remains read-only with no fake ranking")
    assert(AzerothKartDB.highscores == saved and saved.version == 99 and saved.future == "keep",
        "the board never rewrites unknown saved versions")
    AK.SoloRecords = nil
    Menu.Show("home"); Menu.Show("highscores")
    assert(Menu.view.highscoreEmpty.text == "Saved records unavailable.", "missing backend has a graceful empty state")
    AK.SoloRecords = {GetView=function() error("unavailable") end}
    click(Menu.view.highscoreTrack)
    assert(Menu.view.highscoreEmpty.text == "Saved records unavailable.", "a refused backend cannot break the menu")
    UI.scoreResult = {message="Solo time saved. Global publishing pending."}
    Menu.OnResults()
    assert(Menu.view.resultScore.text == UI.scoreResult.message, "results show the preallocated save notice")
    UI.scoreResult = nil; Menu.OnResults()
    assert(Menu.view.resultScore.text == "", "a later run cannot retain the previous result's save notice")
    sameCounts(env, before, "unknown, absent and refused score backends and result notice")
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
    assert(not Menu.view.outline:GetChecked() and AzerothKartDB.preferences.outline == nil and
           not UI.kartOutline:IsShown(), "the kart outline starts off")
    click(Menu.view.outline)
    assert(AzerothKartDB.preferences.outline == true and UI.outlineOn and UI.kartOutline:IsShown() and
           Menu.view.outline:GetChecked() == true, "the kart outline switches on, shows and is remembered")
    assert(Menu.readPreferences({preferences={outline=true}}).outline == true and
           Menu.readPreferences({preferences={outline="yes"}}).outline == nil, "a saved outline is read defensively")
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

-- A saved kart outline returns at load, drawn round the saved kart.
withMock({schemaVersion=1, preferences={version=1, kart="goblin_drag_car", outline=true}}, function(env, UI, Menu)
    local sprite = env.namespace.Presentation.KART_SPRITES.goblin_drag_car
    assert(UI.kartId == "goblin_drag_car" and UI.outlineOn and Menu.prefs.outline == true and
           UI.kartOutline:IsShown() and UI.kartOutline.texturePath == sprite.outline,
        "the saved outline returns on the saved kart")
end)

-- A saved city follows the same deferred restore and explicit-selection path
-- as Mirage. Neither the first open nor choosing it starts a race.
withMock({schemaVersion=1, preferences={version=1, track="ironforge_gp"}}, function(env, UI, Menu, AK)
    assert(UI.trackId == "test_oval" and not UI.active and UI.race == nil,
        "saved Ironforge waits for a shown window without starting a run")
    local before = counts(env)
    UI.Toggle()
    assert(UI.trackId == "ironforge_gp" and Menu.screen == "home" and UI.state.tick == 0 and
           not UI.active and UI.race == nil and UI.clock == nil,
        "first open restores Ironforge and keeps the main menu idle")
    click(Menu.view.homeButtons[1])
    assert(Menu.view.trackPreview.texturePath == Menu.PREVIEW_CELLS.ironforge.path and
           Menu.view.trackPreview:IsShown(), "saved Ironforge shows its own preview")
    click(Menu.view.trackButtons.stormwind_city)
    click(Menu.view.trackButtons.ironforge_gp)
    assert(UI.trackId == "ironforge_gp" and AzerothKartDB.preferences.track == "ironforge_gp" and
           Menu.screen == "tracks" and not UI.active and UI.race == nil and UI.clock == nil and
           UI.state.tick == 0, "choosing Ironforge remembers it and waits for Race!")
    local preview, cell = Menu.view.trackPreview, Menu.PREVIEW_CELLS.ironforge
    assert(UI.backgroundPath == AK.Courses.get("ironforge_gp").background and
           preview.texturePath == cell.path and preview.width == cell.width and preview.height == cell.height and
           preview.texCoords[1] == cell.left and preview.texCoords[2] == cell.right and
           preview.texCoords[3] == cell.top and preview.texCoords[4] == cell.bottom,
        "an explicit Ironforge choice loads its scenery and complete preview cell")
    sameCounts(env, before, "saved and explicitly selected Ironforge")
end)

-- Both new cities use deferred saved selection and their own preview cells.
-- A refused background must preserve an actual ended run, not just an idle pose.
for _,city in ipairs({{id="darnassus_canopy",cell="darnassus",refusal="false"},
                     {id="undercity_slime",cell="undercity",refusal="throws"}}) do
    withMock({schemaVersion=1,preferences={version=1,track=city.id}},function(env,UI,Menu,AK)
        local before=counts(env)
        assert(UI.trackId=="test_oval" and not UI.active and UI.race==nil,
            city.id..": saved city waits for the shown window")
        UI.Toggle()
        assert(UI.trackId==city.id and UI.backgroundPath==AK.Courses.get(city.id).background
            and Menu.screen=="home" and UI.state.tick==0 and UI.race==nil and UI.clock==nil
            and not UI.active and AzerothKartDB.preferences.track==city.id,
            city.id..": first open restores its scenery without starting a run")
        click(Menu.view.homeButtons[1])
        local preview,cell=Menu.view.trackPreview,Menu.PREVIEW_CELLS[city.cell]
        assert(preview:IsShown() and preview.texturePath==cell.path
            and preview.width==cell.width and preview.height==cell.height
            and preview.texCoords[1]==cell.left and preview.texCoords[2]==cell.right
            and preview.texCoords[3]==cell.top and preview.texCoords[4]==cell.bottom,
            city.id..": saved selection displays its complete city preview")
        sameCounts(env,before,city.id..": saved restore and preview")
    end)
    withMock({schemaVersion=1,preferences={version=1,track="mirage_raceway"}},function(env,UI,Menu,AK)
        UI.Toggle(); Menu.Show(nil); UI.Start(); UI.OnUpdate(1/60)
        env.combat=true; UI.InterruptCombat(); env.combat=false; UI.OnCombatEnded(); UI.Toggle()
        assert(UI.result and UI.result.status=="interrupted" and UI.summary:IsShown(),
            "fixture preserves the actual interrupted result before choosing another track")
        click(find(env,UI.summary,"Change Track"))
        local state,race,clock,result,laps,progress=UI.state,UI.race,UI.clock,UI.result,UI.laps,UI.checkpoints
        local track,id,background,picture=UI.track,UI.trackId,UI.backgroundPath,UI.mirageBackground
        local coords={}
        for index,value in ipairs(picture.texCoords) do coords[index]=value end
        local oldResultReason,oldTicks=result.reason,race.totalTicks
        local before=counts(env)
        env.textureModes[AK.Courses.get(city.id).background]=city.refusal
        click(Menu.view.trackButtons[city.id])
        assert(UI.track==track and UI.trackId==id and UI.backgroundPath==background
            and UI.mirageBackground==picture and picture.texturePath==background,
            city.id..": refused scenery preserves the old authoritative track and visible picture")
        for index,value in ipairs(coords) do
            assert(picture.texCoords[index]==value,city.id..": refusal preserves the old camera crop")
        end
        assert(UI.state==state and UI.race==race and UI.clock==clock and UI.result==result
            and UI.laps==laps and UI.checkpoints==progress and not UI.active
            and result.reason==oldResultReason and race.totalTicks==oldTicks,
            city.id..": refusal preserves the actual result, pose, laps and timing references")
        assert(AzerothKartDB.preferences.track==id and Menu.prefs.track==id and Menu.screen=="tracks"
            and Menu.messages.tracks.text:find("background unavailable",1,true),
            city.id..": refusal explains the failure without saving a failed selection")
        sameCounts(env,before,city.id..": refused background selection")
    end)
end

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
    assert(UI.trackId == "stormwind_city" and AzerothKartDB.preferences.track == "stormwind_city",
        "the bar's track button steps on to the city circuit")
    click(UI.trackButton)
    assert(UI.trackId == "ironforge_gp" and AzerothKartDB.preferences.track == "ironforge_gp",
        "and on to Ironforge")
    click(UI.trackButton)
    assert(UI.trackId == "darnassus_canopy" and AzerothKartDB.preferences.track == "darnassus_canopy",
        "and on to Darnassus")
    click(UI.trackButton)
    assert(UI.trackId == "orgrimmar_canyon" and AzerothKartDB.preferences.track == "orgrimmar_canyon",
        "and on to Orgrimmar")
    click(UI.trackButton)
    assert(UI.trackId == "thunder_bluff_skyway" and AzerothKartDB.preferences.track == "thunder_bluff_skyway",
        "and on to Thunder Bluff")
    click(UI.trackButton)
    assert(UI.trackId == "undercity_slime" and AzerothKartDB.preferences.track == "undercity_slime",
        "and on to Undercity")
    click(UI.trackButton)
    assert(UI.trackId == "scarlet_graveyard" and AzerothKartDB.preferences.track == "scarlet_graveyard",
        "and on to the Scarlet Graveyard sprint")
    click(UI.trackButton)
    assert(UI.trackId == "scarlet_library" and AzerothKartDB.preferences.track == "scarlet_library",
        "and on to the Scarlet Library sprint")
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

-- Every city is ready: Thunder Bluff is an ordinary choice now. A course
-- still marked coming soon (a fixture) is listed, disabled and inert.
withMock(nil, function(env, UI, Menu)
    UI.Toggle(); click(Menu.view.homeButtons[1])
    assert(Menu.view.trackButtons.thunder_bluff_skyway and Menu.view.soonButtons.thunder_bluff_skyway == nil,
        "Thunder Bluff is listed as a ready track")
    local soon = Menu.view.soonButtons.soon_fixture
    assert(soon and not soon:IsEnabled() and not soon.scripts.OnClick and soon.text:find("(soon)", 1, true),
        "a coming-soon city is listed, disabled and inert")
end, function(env, AK)
    table.insert(AK.Courses.LIST, {id="soon_fixture", name="Coming Course", cup="capital", soon=true})
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
    assert(UI.trackId == "stormwind_city" and AzerothKartDB.preferences.track == "stormwind_city",
        "the bar's Track button is remembered before any restore")
    UI.Toggle(); UI.Toggle()
    assert(UI.trackId == "stormwind_city", "and a waiting restore no longer replaces it")
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
withMock({schemaVersion=777, preferences={version=1, track="test_oval", kart="steam_tank", effects=true,
    sound=true, devInfo=false, scale=1, futureField={keep="exact"}}, unknown={keep=true}}, function(env, UI, Menu)
    local root, preferences = AzerothKartDB, AzerothKartDB.preferences
    local unknown, child = root.unknown, preferences.futureField
    assert(not Menu.prefsWritable, "an unsupported root never grants preference write permission")
    UI.Toggle(); click(Menu.view.homeButtons[5])
    Menu.SetScale(1.1); click(Menu.view.effects); click(Menu.view.sound); click(Menu.view.devInfo)
    click(find(env, Menu.screens.settings, "Back"))
    click(Menu.view.homeButtons[3]); click(Menu.view.kartButtons.gyrocopter)
    click(Menu.view.race); click(Menu.view.homeButtons[1]); click(Menu.view.trackButtons.mirage_raceway)
    click(find(env, Menu.screens.tracks, "Back")); click(Menu.view.homeButtons[6])
    assert(AzerothKartDB == root and root.schemaVersion == 777 and root.preferences == preferences and
        root.unknown == unknown and unknown.keep and preferences.version == 1 and preferences.track == "test_oval" and
        preferences.kart == "steam_tank" and preferences.effects and preferences.sound and not preferences.devInfo and
        preferences.scale == 1 and preferences.futureField == child and child.keep == "exact",
        "settings, kart/track buttons and highscore navigation preserve the exact future root and child")
    assert(UI.kartId == "gyrocopter" and UI.trackId == "mirage_raceway" and Menu.screen == "highscores",
        "read-only persistence does not disable ordinary menu choices")
end)
withMock({schemaVersion=1, preferences={version=1, kart="steam_tank"}}, function(env, UI, Menu)
    assert(Menu.prefsWritable, "fixture initially permits preference writes")
    local future = {version=777, kart="steam_tank", newShape={keep="exact"}}
    local shape = future.newShape
    AzerothKartDB.preferences = future
    UI.Toggle(); click(Menu.view.homeButtons[5])
    Menu.SetScale(1.1); click(Menu.view.effects); click(Menu.view.sound); click(Menu.view.devInfo)
    click(find(env, Menu.screens.settings, "Back")); click(Menu.view.homeButtons[3])
    click(Menu.view.kartButtons.gyrocopter)
    assert(AzerothKartDB.preferences == future and future.version == 777 and future.kart == "steam_tank" and
        future.newShape == shape and shape.keep == "exact" and future.scale == nil and future.effects == nil,
        "each save rechecks a future preference child installed after menu creation")
end)
withMock({schemaVersion=1, preferences={version=1, sound=true, futureField="keep"}}, function(env, UI, Menu)
    local preferences = AzerothKartDB.preferences
    AzerothKartDB.schemaVersion = 777
    UI.Toggle(); click(Menu.view.homeButtons[5]); click(Menu.view.sound)
    assert(AzerothKartDB.schemaVersion == 777 and AzerothKartDB.preferences == preferences and
        preferences.sound and preferences.futureField == "keep", "each save also rechecks the current root version")
end)
withMock({schemaVersion=1, preferences={version=2, track="mirage_raceway", kart="gyrocopter",
    newShape={owner="future", keep=true}}}, function(env, UI, Menu, AK)
    local record = AzerothKartDB.preferences
    local unknown = record.newShape
    UI.Toggle()
    assert(UI.trackId == "test_oval" and UI.kartId == "goblin_mortar_trike",
        "failed choices in a newer record leave the current fallback ids")
    click(Menu.view.homeButtons[1]); click(Menu.view.trackNext); click(Menu.view.race)
    UI.OnUpdate(1 / 60)
    UI.Stop("preference regression")
    click(find(env, UI.summary, "Change Track"))
    local state, race, clock, laps, checkpoints = UI.state, UI.race, UI.clock, UI.laps, UI.checkpoints
    local keys, input, before = UI.keys, UI.input, {}
    assert(state and race and clock and laps and checkpoints, "a stopped run supplies real state to preserve")
    AK.Input.set(keys, "W", true)
    AK.Input.sample(keys, input)
    for key,value in pairs(state) do before[key] = value end
    local function unchanged()
        assert(UI.state == state and UI.race == race and UI.clock == clock and UI.laps == laps and
               UI.checkpoints == checkpoints and not UI.active,
            "choosing current ids keeps the stopped run and its timing references")
        for key,value in pairs(before) do assert(state[key] == value, "vehicle state stays unchanged: " .. key) end
        assert(UI.keys == keys and UI.input == input and keys.W == true and input.accelerate == true and
               not input.brake and not input.left and not input.right and not input.drift,
            "choosing current ids does not clear or replace input")
        assert(AzerothKartDB.preferences == record and record.version == 2 and
               record.track == "mirage_raceway" and record.kart == "gyrocopter" and
               record.newShape == unknown and unknown.owner == "future" and unknown.keep == true,
            "explicit fallback choices never replace or change a newer preference record")
    end
    click(Menu.view.trackButtons.test_oval)
    assert(Menu.prefs.track == "test_oval" and Menu.trackRestored,
        "the current track choice still supersedes restoration in memory")
    unchanged()
    click(Menu.view.trackNext); click(Menu.view.kartButtons.goblin_mortar_trike)
    assert(Menu.prefs.kart == "goblin_mortar_trike", "the current kart choice is kept in memory")
    unchanged()
end, function(env, AK)
    env.textureModes[AK.Presentation.KART_SPRITES.gyrocopter.path] = "false"
    env.textureModes[BACKGROUND] = "false"
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

-- A read-only/absent bridge never enables a command ------------------------------
withMock(nil, function(env, UI, Menu)
    Menu.SetSessionBridge(nil)
    UI.Toggle()
    click(Menu.view.homeButtons[2])
    local view = Menu.view
    assert(Menu.screen == "multiplayer" and not view.host:IsEnabled() and not view.listen:IsEnabled() and
           not view.join:IsEnabled() and not view.ready:IsEnabled() and not view.start:IsEnabled() and
           not view.leave:IsEnabled(), "every multiplayer control stays disabled without an action bridge")
    assert(view.lobbyTitle.text == "Lobby preview" and view.friend.text == "Open slot",
        "the preview shows no invented player")
    Menu.SetSessionBridge({view=function()
        return {phase="lobby", role="host", peer="Birch Vale", localReady=true, localReadyConfirmed=true,
            peerReady=true, canSetReady=true, canPrepareStart=true, coordinated=true, canLeave=true}
    end})
    assert(not view.ready:IsEnabled() and not view.start:IsEnabled() and not view.leave:IsEnabled() and
           view.lobbyTitle.text == "Hosting" and view.friend.text == "Birch Vale",
        "the legacy view-only bridge displays copied state without actionable controls")
    click(view.ready); click(view.start)
    assert(not UI.active and UI.race == nil, "disabled bridge commands cannot start a solo run")
    Menu.SetSessionBridge({view=function() error("bridge failure") end, action=function() error("unreachable") end})
    assert(not view.leave:IsEnabled() and view.lobbyTitle.text == "Lobby preview",
        "a failing bridge falls back to a disabled preview")
    Menu.SetSessionBridge(nil)
end)

-- Explicit host/listen/join/ready/start actions, copied status and 5Hz display ----
withMock(nil, function(env, UI, Menu)
    UI.Toggle(); Menu.Show("multiplayer")
    local view, commands, polls = Menu.view, {}, 0
    local session = {phase="idle", canHost=true, canListen=true, canLeave=false}
    local refusal, thrown
    Menu.SetSessionBridge({view=function() polls = polls + 1; return session end,
        action=function(name, ...)
            assert(env.focus == nil, "EditBox focus is released before the UI safety wrapper")
            commands[#commands + 1] = {name, ...}
            if thrown then error("not player-facing") end
            if refusal then return false, refusal end
            if name == "host" then
                session = {phase="inviting", role="host", peer=commands[#commands][2],
                    offer={trackId=commands[#commands][4]}, canLeave=true, pendingKind="INVITE", pendingAttempts=1}
            elseif name == "listen" then
                session = {phase="listening", role="guest", peer=commands[#commands][2], canLeave=true}
            elseif name == "join" then
                session.phase, session.canJoin, session.canSetReady = "lobby", false, true
            elseif name == "ready" then
                session.localReady = commands[#commands][2]
            elseif name == "start" then
                session.phase, session.canPrepareStart, session.canSetReady = "coordinating", false, false
                session.clock = {phase="calibrating"}
            elseif name == "leave" then
                session = {phase="closed", reason="left", canLeave=false}
            end
            return true
        end})
    local before = counts(env)
    local vehicle, race, input, clock, track = UI.state, UI.race, UI.input, UI.clock, UI.trackId
    assert(view.host:IsEnabled() and view.listen:IsEnabled() and not view.join:IsEnabled() and
           not view.ready:IsEnabled() and not view.start:IsEnabled(), "fresh session requires deliberate arming")
    assert(Menu.view.homeButtons[2].text:find("experimental", 1, true), "actions enable the experimental menu label")
    view.peerName:SetText("Lene Conradi")
    view.sessionCode:SetText("bad")
    click(view.listen)
    assert(#commands == 0 and Menu.messages.multiplayer.text:find("six uppercase", 1, true),
        "invalid code never reaches the native wrapper")
    view.sessionCode:SetText("AKT901")
    view.peerName:SetText("")
    click(view.host)
    assert(#commands == 0 and Menu.messages.multiplayer.text:find("complete Forever", 1, true),
        "missing full peer name never reaches the native wrapper")
    view.peerName:SetText("Lene Conradi")
    view.peerName:SetFocus()
    click(view.listen)
    assert(commands[1][1] == "listen" and commands[1][2] == "Lene Conradi" and commands[1][3] == "AKT901" and
           #commands[1] == 3 and not view.join:IsEnabled(), "Listen preserves the complete name and never joins automatically")
    session.phase, session.canJoin, session.offer = "invited", true, {trackId="test_oval"}
    local readBefore = polls
    Menu.screens.multiplayer.scripts.OnUpdate(Menu.screens.multiplayer, 0.1)
    assert(polls == readBefore, "lobby does not poll every simulation frame")
    Menu.screens.multiplayer.scripts.OnUpdate(Menu.screens.multiplayer, 0.1)
    assert(polls == readBefore + 1 and view.join:IsEnabled() and not view.ready:IsEnabled(),
        "a received offer becomes actionable through the bounded 5Hz display refresh")
    assert(view.lobbyTrack.text == "Track: Test Oval    Laps: 3" and UI.trackId == track,
        "offered track is shown without selecting geometry from a display update")
    click(view.join)
    assert(commands[2][1] == "join" and #commands[2] == 1 and view.ready:IsEnabled() and
           session.localReady == nil, "Join enters the lobby without declaring readiness")
    view.sessionCode:SetFocus()
    click(view.ready)
    assert(commands[3][1] == "ready" and commands[3][2] == true and view.ready.text == "Not ready",
        "Ready is an explicit boolean action and releases typing focus first")
    click(view.ready)
    assert(commands[4][1] == "ready" and commands[4][2] == false, "Not ready explicitly withdraws readiness")
    click(find(env, Menu.screens.multiplayer, "Back"))
    assert(Menu.screen == "home" and commands[5][1] == "leave" and #commands == 5,
        "Back deliberately leaves a pending session exactly once")
    local hiddenPolls = polls
    Menu.screens.multiplayer.scripts.OnUpdate(Menu.screens.multiplayer, 2)
    assert(polls == hiddenPolls, "hidden lobby stops polling")
    session = {phase="idle", canHost=true, canListen=true}
    Menu.Show("multiplayer")
    click(view.lobbyTrackChoice)
    assert(Menu.lobbyTrackId == "test_oval" and UI.trackId == track, "host track choice cycles only supported metadata")
    click(view.lobbyTrackChoice)
    assert(Menu.lobbyTrackId == "mirage_raceway", "supported track cycle wraps without adding cities")
    view.peerName:SetText("  Flaturlative Breeze  "); view.sessionCode:SetText("AKT902")
    refusal = "reused_session"
    click(view.host)
    assert(Menu.messages.multiplayer.text:find("already used", 1, true) and view.host:IsEnabled(),
        "refused actions show fixed feedback and never invent a connection")
    refusal = "|Hunknown-secret-error|h"
    click(view.host)
    assert(not Menu.messages.multiplayer.text:find("unknown-secret", 1, true), "untrusted reasons are never echoed")
    refusal, thrown = nil, true
    click(view.host)
    assert(not Menu.messages.multiplayer.text:find("not player-facing", 1, true), "thrown errors have fixed feedback")
    thrown = false
    click(view.host)
    local host = commands[#commands]
    assert(host[1] == "host" and host[2] == "Flaturlative Breeze" and host[3] == "AKT902" and
           host[4] == "mirage_raceway" and not view.host:IsEnabled(), "Host preserves surname and passes only supported track metadata")
    local afterHost = #commands
    click(view.host)
    assert(#commands == afterHost, "stale enabled/click callbacks revalidate current capabilities")
    session = {phase="lobby", role="host", peer="Flaturlative Breeze", localReady=true,
        localReadyConfirmed=true, peerReady=true, coordinated=true, canStart=false, canPrepareStart=true,
        canLeave=true, canSetReady=true}
    Menu.screens.multiplayer.scripts.OnUpdate(Menu.screens.multiplayer, 0.2)
    assert(view.start:IsEnabled(), "coordinated start uses canPrepareStart, never legacy canStart")
    click(view.start)
    assert(commands[#commands][1] == "start" and #commands[#commands] == 1 and not UI.active and UI.race == nil,
        "Start sends no UI tick/seed settings and never invokes solo Start")
    assert(view.lobbyStatus.text:find("Measuring start timing", 1, true), "clock calibration is visible")
    session.clock.phase = "armed"
    Menu.screens.multiplayer.scripts.OnUpdate(Menu.screens.multiplayer, 0.2)
    assert(view.lobbyStatus.text:find("Start armed", 1, true), "armed status is shown without consuming a GO ticket")
    session.phase = "racing"
    local countAtGO = #commands
    Menu.Show(nil)
    assert(#commands == countAtGO, "backend GO hides the lobby without leaving the live race")
    assert(UI.state == vehicle and UI.race == race and UI.input == input and UI.clock == clock and
           UI.trackId == track and not UI.active, "menu commands and refresh alone cannot write authoritative driving state")
    sameCounts(env, before, "all lobby phases and explicit actions")
    Menu.SetSessionBridge(nil)
end)

-- Leaving finished live results releases the session before browsing solo -----
for _,choice in ipairs({{"Main Menu", "home"}, {"Change Track", "tracks"}, {"Change Kart", "karts"}}) do
    withMock(nil, function(env, UI, Menu)
        UI.Toggle(); Menu.Show(nil); UI.Start(); UI.Stop("results navigation")
        assert(UI.summary:IsShown() and Menu.screen == nil and not UI.active,
            "the results panel is separate from menu screens")
        UI.multiplayer, UI.liveSession = true, "AKT903"
        local session = {phase="finishing", liveMode=true, transportBusy=true, canLeave=true}
        local leaves = 0
        Menu.SetSessionBridge({view=function() return session end, action=function(action)
            assert(action == "leave", "results navigation can only leave; never ready or start")
            leaves = leaves + 1
            session = {phase="closed", liveMode=true, transportBusy=false, canLeave=false, reason="left"}
            return true
        end})
        Menu.Show("multiplayer")
        assert(leaves == 0, "opening the lobby only displays an existing finishing session")
        Menu.Show(nil)
        assert(leaves == 0, "showing the race/results canvas never implicitly ends a finishing session")
        click(find(env, UI.summary, choice[1]))
        assert(leaves == 1 and Menu.screen == choice[2] and not UI.active,
            choice[1] .. " explicitly leaves the draining live run exactly once")
        Menu.Show("garage")
        assert(leaves == 1, "subsequent navigation cannot repeat a completed Leave")
        Menu.SetSessionBridge(nil)
    end)
end

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

-- The shared starting grid is a race scene without solo simulation. Showing
-- that canvas must not invoke Leave merely because active is still false.
withMock(nil,function(env,UI,Menu)
    UI.Toggle(); Menu.Show("multiplayer")
    local before=counts(env)
    local commands={}
    local session={phase="coordinating",liveMode=true,transportBusy=true,canLeave=true,
        clock={phase="armed"},grid={ready=true,staged=true,cue="3"}}
    Menu.SetSessionBridge({view=function() return session end,action=function(action)
        commands[#commands+1]=action; return true
    end})
    local state,race,clock=UI.state,UI.race,UI.clock
    UI.gridStaged,UI.liveArmed,UI.multiplayer,UI.liveSession=true,true,true,"GRID01"
    UI.gridView=session.grid
    Menu.Sync(); Menu.RefreshRaceHud()
    assert(Menu.screen==nil and not Menu.root:IsShown() and Menu.overlay:IsShown()
        and UI.stopButton:IsShown() and not UI.startButton:IsShown(),
        "a staged grid uncovers the race canvas and Stop before simulation starts")
    assert(Menu.view.lap.text=="STARTING GRID" and Menu.view.time.text=="0:00.0"
        and Menu.view.best.text=="HOLD W/UP FOR GO",
        "grid HUD describes the pending start rather than an old lap or race time")
    Menu.Show("home")
    assert(Menu.screen==nil and #commands==0,
        "grid canvas transitions and attempts to cover it never implicitly send Leave")
    assert(UI.state==state and UI.race==race and UI.clock==clock and not UI.active,
        "grid navigation leaves authoritative state untouched")
    env.sounds={}
    Menu.OnCue("GET READY"); Menu.OnCue("3"); Menu.OnCue("2"); Menu.OnCue("1"); Menu.OnCue("GO")
    assert(table.concat(env.sounds,",")=="25477,25477,25477,25478",
        "shared grid has only the three numeric countdown beeps and GO")
    sameCounts(env,before,"shared grid scene and HUD")
    UI.gridStaged,UI.liveArmed,UI.multiplayer,UI.liveSession=false,false,false,nil
    UI.gridView=nil
    Menu.SetSessionBridge(nil)
end)

-- Missing client templates fall back to plain panel buttons -----------------------
withMock(nil, function(env, UI, Menu)
    assert(not Menu.disabled and Menu.view.homeButtons[1].template == "UIPanelButtonTemplate",
        "the Game Menu button template is optional")
end, function(env) env.refuseTemplate = "MainMenuFrameButtonTemplate" end)

withMock(nil, function(env, UI, Menu)
    UI.Toggle(); Menu.Show("garage")
    local before = counts(env)
    for _,choice in ipairs({{"steam_tank","Heavy"}, {"dwarven_biker","Agile"},
            {"goblin_mortar_trike","Balanced"}, {"goblin_drag_car","Balanced"}}) do
        Menu.ChooseKart(choice[1])
        assert(UI.kartId == choice[1])
        assert(Menu.view.kartHandling.text:find(choice[2],1,true),
            "the picker names the actual selected handling profile")
        assert(not UI.active, "browsing profiles never starts a race")
    end
    sameCounts(env,before,"handling descriptions reuse existing text")
end)

withMock(nil, function(env, UI, Menu, AK)
    local rows={{playerName="First Racer",totalTicks=2400,finishedAt=1792756800}}
    local reads=0
    AK.SoloRecords={GetView=function()
        reads=reads+1
        return {scope="community",publication="Automatic sharing connected",writable=true,
            rows=rows,connected=2,queued=1}
    end,FormatTime=function(ticks) return tostring(ticks) end,
        FormatDate=function(epoch) return tostring(epoch) end}
    UI.Toggle();Menu.Show("highscores")
    local before=counts(env)
    assert(Menu.view.highscoreRows[1].name.text=="First Racer")
    rows[1]={playerName="New Leader",totalTicks=2300,finishedAt=1792756801}
    Menu.OnScoresChanged()
    assert(Menu.view.highscoreRows[1].name.text=="New Leader"
        and Menu.view.highscoreScope.text:find("Shared community scores",1,true)
        and Menu.view.highscoreStatus.text:find("2 connected",1,true),
        "a received score refreshes the visible board without another click")
    Menu.Show("home")
    local oldReads=reads
    Menu.OnScoresChanged()
    assert(Menu.screen=="home" and reads==oldReads,
        "background synchronization does not open or refresh a hidden board")
    sameCounts(env,before,"automatic board refresh reuses pooled rows")
end)

-- The Scarlet Crusade Cup: its heading, Scarlet Graveyard and Scarlet
-- Library, then two dungeons coming soon; a sprint's race lines count its
-- gates instead of laps, and its saved board says it holds one-run times.
withMock(nil, function(env, UI, Menu, AK)
    UI.Toggle(); click(Menu.view.homeButtons[1])
    local buttons, soon = Menu.view.trackButtons, Menu.view.soonButtons
    assert(buttons.scarlet_graveyard and buttons.scarlet_library and not soon.scarlet_library
        and soon.scarlet_armory and soon.scarlet_monastery and not soon.scarlet_armory:IsEnabled(),
        "the cup lists the Graveyard and the Library, then two coming-soon dungeons")
    local rows = Menu.trackRows()
    assert(rows[#rows - 4].heading == "Scarlet Crusade Cup" and rows[#rows - 3].track.id == "scarlet_graveyard"
        and rows[#rows - 2].track.id == "scarlet_library", "the third cup's heading, then its ready sprints")
    click(buttons.scarlet_library)
    assert(UI.trackId == "scarlet_library" and Menu.previewReady
        and Menu.view.trackPreview.width == 320 and Menu.view.trackPreview.height == 320,
        "the Library shows its square preview")
    click(buttons.scarlet_graveyard)
    assert(UI.trackId == "scarlet_graveyard" and Menu.previewReady
        and Menu.view.trackPreview.width == 320 and Menu.view.trackPreview.height == 160,
        "choosing it shows its twice-as-wide preview")
    local lap, time, gates = Menu.raceLines(nil, nil)
    assert(lap == "SPRINT" and time == "0:00.0" and gates == "GATES 0/3", "before the sprint: its gates, no laps")
    local running = {status="running", targetLaps=1, totalTicks=754, laps={completedLaps=0, checkpoints={passed=2}}}
    lap, time, gates = Menu.raceLines(running, running.laps)
    assert(lap == "SPRINT" and time == "0:12.6" and gates == "GATES 2/3", "a running sprint counts its gates")
    local finished = {status="finished", targetLaps=1, totalTicks=1830, laps={completedLaps=1, checkpoints={passed=0}}}
    lap, time, gates = Menu.raceLines(finished, finished.laps)
    assert(lap == "FINISHED" and time == "0:30.50" and gates == "GATES 3/3", "a finished sprint")
    local before = counts(env)
    AK.SoloRecords = {GetView=function(id)
        return {scope="local", writable=true, rows={}, trackId=id,
            context={trackId=id, lapCount=id:find("^scarlet_") and 1 or 3}}
    end}
    Menu.Show("home"); click(Menu.view.homeButtons[6])
    assert(Menu.screen == "highscores" and Menu.view.highscoreTrack.text == "Track: Scarlet Graveyard"
        and Menu.view.highscoreRule.text == "Fastest completed sprints, one run each, for the current rules",
        "the Graveyard's saved board holds one-run sprint times")
    click(Menu.view.highscoreTrack)
    assert(Menu.view.highscoreTrack.text == "Track: Scarlet Library"
        and Menu.view.highscoreRule.text == "Fastest completed sprints, one run each, for the current rules",
        "so does the Library's")
    click(Menu.view.highscoreTrack)
    assert(Menu.view.highscoreRule.text == "Fastest completed three-lap totals for the current rules",
        "the next board holds three-lap totals again")
    sameCounts(env, before, "the board's rule line reuses its label")
end)

print("mock menus: 8 screens, single-player flow, saved highscore pages, results paths, garage, settings, saved choices, " ..
    "explicit experimental lobby actions and fallbacks (client appearance still pending)")
