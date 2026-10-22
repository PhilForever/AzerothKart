-- Azeroth Kart front end: the main menu, track and kart choice, the coming-
-- soon multiplayer lobby, help, settings, the race HUD overlay and the results
-- dialog. Presentation only: it calls UI's public commands (Start,
-- SelectTrack, SelectKart, DismissSummary, SetEffectsEnabled) and never writes
-- simulation, race or session state. A menu screen never starts a race by
-- itself; only an explicit Race!/Start/Restart click calls UI.Start.
--
-- The look is the client's own: classic dialog backdrops, the dialog header,
-- the Game Menu's big red buttons, panel buttons, check buttons and font
-- objects, each verified in the build-70450 interface source. Every template
-- falls back to a plain panel button or backdrop, and every font to
-- GameFontNormal. Mocked tests do not establish client API safety.
local _, AK = ...
assert(type(AK) == "table", "addon namespace required")
local Presentation = AK.Presentation
local Physics = AK.Physics
local Courses = AK.Courses

local Menu = {screen=nil, screens={}, view={}}
AK.Menu = Menu
local UI

-- ---------------------------------------------------------------------------
-- Copy and data. Karts are cosmetic: every one drives the same 17x31 body.

-- The track list's copy, in display order within each cup (Courses.CUPS).
-- Courses marked `soon` in Courses.LIST are listed after these, disabled.
Menu.TRACKS = {
    {id="mirage_raceway", name="Mirage Raceway", cell=0,
        blurb="A sun-baked salt circuit on the dry Shimmering Flats, run between the rival goblin and gnome camps.",
        facts={"3 laps, 4 gates", "Counterclockwise: North, West, South, Start", "Off the road, rough salt slows you down"}},
    {id="test_oval", name="Test Oval", cell=1,
        blurb="The proving loop: one wide oval to learn the drift, with two solid crates to dodge.",
        facts={"3 laps, 4 gates", "Counterclockwise: North, West, South, Start", "Grass slows you down; crates stop you"}},
    {id="stormwind_city", name="Stormwind City Circuit", cell="stormwind",
        blurb="Start in the Valley of Heroes, through the gate into the Trade District, then the canals: "
            .. "Old Town, the Dwarven District, Cathedral Square, the Park and the Mage Quarter.",
        facts={"3 laps, 6 gates named for the districts", "The canals stay on your left all lap",
            "Full speed to the street walls"}},
    {id="ironforge_gp", name="Ironforge Grand Prix", cell="ironforge",
        blurb="From the Gates round the Commons, the Mystic Ward and the Forlorn Cavern, through the "
            .. "Great Forge's fire, then Tinker Town and the Military Ward.",
        facts={"3 laps, 7 gates named for the districts", "A long lap: the city's whole ring and its heart",
            "Mind the lava: the forges' railings are solid"}},
}

local WC3C = "Model: ITE project (wc3c), author unknown"
Menu.KARTS = {
    goblin_mortar_trike={blurb="A goblin three-wheeler with a mortar bolted on the back and exhaust to spare.",
        credit="Model: erwtenpeller and Chriz (Vast Graphics)"},
    steam_tank={blurb="A dwarven siege engine, smoke stacks blazing.", credit=WC3C},
    dwarven_biker={blurb="A dwarf on a roaring two-wheeler, built on the trike's frame.", credit=WC3C},
    gryphon_rider={blurb="A gryphon skimming low over the salt. No engine: it trails wind instead of flame.",
        credit=WC3C},
    gyrocopter={blurb="A gnomish flying machine, hovering just above the track.", credit=WC3C},
    goblin_drag_car={blurb="A rocket-powered goblin dragster, happiest on the straights.",
        credit="Original Azeroth Kart art"},
}

Menu.CONTROLS = {
    {"W / Up", "Accelerate"},
    {"S / Down", "Brake, then reverse"},
    {"A / D, Left / Right", "Steer"},
    {"Space + turn", "Drift (at speed 90+)"},
    {"Release Space", "Boost"},
    {"Stop / Esc", "End the run"},
    {"Enter", "Chat (ends the run)"},
}

Menu.RULES = {
    "Pass the gates in order (the HUD names the next one); each full circuit is a lap. Three laps finish the race.",
    "Hold a drift to charge it: blue, then gold at Tier 1 (0.5 s), then pink at Tier 2 (1 s). Release Space for a boost.",
    "Grass and rough salt slow you and cancel drift and boost. Stormwind has full grip to the walls; wall contact scrubs speed.",
    "Your best lap is kept for the current run. Entering combat closes the game.",
}

Menu.SCALES = {0.8, 0.9, 1, 1.1, 1.25}
Menu.WINDOW_WIDTH, Menu.WINDOW_HEIGHT = 856, 762
Menu.PREVIEW_PATH = "Interface\\AddOns\\AzerothKart\\Assets\\UI\\TrackPreviews.tga"
-- TrackPreviews.tga: 1024x512, one 512x512 cell per track. Mirage fills its
-- cell; the 5:3 Oval painting sits centered in the top 300 rows of its cell.
-- A city has its own 512x512 Preview.tga beside its scenery (`path`).
Menu.PREVIEW_CELLS = {
    [0]={left=0, right=0.5, top=0, bottom=1, width=320, height=320},
    [1]={left=0.5+6/1024, right=1-6/1024, top=0, bottom=300/512, width=320, height=192},
    stormwind={path="Interface\\AddOns\\AzerothKart\\Assets\\Tracks\\Stormwind\\Preview.tga",
        left=0, right=1, top=0, bottom=1, width=320, height=320},
    ironforge={path="Interface\\AddOns\\AzerothKart\\Assets\\Tracks\\Ironforge\\Preview.tga",
        left=0, right=1, top=0, bottom=1, width=320, height=320},
}

-- Fixed fonts; each falls back to GameFontNormal when the client lacks it.
local FONT = {
    logo={"Fancy48Font", "GameFontNormalHuge3", "GameFontNormalHuge"},
    title={"Fancy32Font", "GameFontNormalHuge2", "GameFontNormalHuge"},
    huge={"GameFontNormalHuge3", "GameFontNormalHuge"},
    large={"GameFontNormalLarge"},
    largeWhite={"GameFontHighlightLarge"},
    normal={"GameFontNormal"},
    white={"GameFontHighlight"},
    small={"GameFontHighlightSmall"},
    gray={"GameFontDisable"},
    graySmall={"GameFontDisableSmall"},
    lap={"GameFontNormalHuge3Outline", "GameFontNormalHuge3", "GameFontNormalHuge"},
    timer={"GameFontHighlightHuge2", "GameFontHighlightHuge", "GameFontNormalHuge"},
    countdown={"Game72Font", "Game48Font", "GameFontNormalHuge3", "GameFontNormalHuge"},
}

local GOLD, WHITE, RED, GREEN = {1, 0.82, 0}, {1, 1, 1}, {1, 0.35, 0.3}, {0.45, 1, 0.45}
local SOON = {1, 0.55, 0.15}

-- Classic dialog backdrops, as defined by the client's Backdrop.lua presets.
local DIALOG = {bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", tile=true, tileEdge=true,
    tileSize=32, edgeSize=32, insets={left=11, right=12, top=12, bottom=11}}
local DARK_DIALOG = {bgFile="Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", tile=true, tileEdge=true,
    tileSize=32, edgeSize=32, insets={left=11, right=12, top=12, bottom=11}}
-- The same tooltip-bordered flat card the window already used.
local CARD = {bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize=14, insets={left=4, right=4, top=4, bottom=4}}

-- ---------------------------------------------------------------------------
-- Pure helpers, exported for tests.

-- "m:ss.cc" (or tenths); nil or a negative time shows "--".
function Menu.formatTime(seconds, decimals)
    if type(seconds) ~= "number" or seconds ~= seconds or seconds < 0 or seconds == math.huge then return "--" end
    decimals = decimals == 1 and 1 or 2
    local unit = decimals == 1 and 10 or 100
    local total = math.floor(seconds * unit + 0.5)
    local minutes = math.floor(total / (60 * unit))
    local rest = total - minutes * 60 * unit
    local whole = math.floor(rest / unit)
    local fraction = rest - whole * unit
    return ("%d:%02d.%0" .. decimals .. "d"):format(minutes, whole, fraction)
end

-- Saved preferences (AzerothKartDB.preferences, version 1), defensively
-- parsed: unknown ids, types and sizes fall back to defaults, and other
-- AzerothKartDB fields are never touched. The second result says whether this
-- version may write the record: a newer version's record is read, not replaced.
function Menu.readPreferences(db)
    local prefs = {effects=true, devInfo=false, scale=1, sound=true}
    local raw = type(db) == "table" and db.preferences
    if type(raw) ~= "table" then return prefs, true end
    local writable = not (type(raw.version) == "number" and raw.version > 1)
    if type(raw.track) == "string" and Courses and Courses.available(raw.track) then prefs.track = raw.track end
    if type(raw.kart) == "string" and Presentation.KART_SPRITES[raw.kart] then prefs.kart = raw.kart end
    if type(raw.effects) == "boolean" then prefs.effects = raw.effects end
    if type(raw.devInfo) == "boolean" then prefs.devInfo = raw.devInfo end
    if type(raw.sound) == "boolean" then prefs.sound = raw.sound end
    for _,scale in ipairs(Menu.SCALES) do
        if raw.scale == scale then prefs.scale = scale end
    end
    return prefs, writable
end

-- The race HUD's big lines for a race (or none yet): lap, time and best.
function Menu.raceLines(race, laps)
    local target = race and race.targetLaps or 3
    if not race or race.status == "countdown" then
        return ("LAP 1/%d"):format(target), Menu.formatTime(0, 1),
            "BEST " .. Menu.formatTime(laps and laps.bestLapTicks and laps.bestLapTicks * Physics.FIXED_DT)
    end
    local completed = race.laps.completedLaps
    local lap = race.status == "finished" and "FINISHED" or
        ("LAP %d/%d"):format(math.min(completed + 1, target), target)
    local seconds = race.totalTicks * Physics.FIXED_DT
    local best = race.laps.bestLapTicks
    return lap, Menu.formatTime(seconds, race.status == "running" and 1 or 2),
        "BEST " .. Menu.formatTime(best and best * Physics.FIXED_DT)
end

-- Lobby copy for a copied PeerSession view (or nil while multiplayer is not
-- available). Capabilities come only from the view; nothing here decides
-- whether a command is permitted, and unknown phases show as unavailable.
local PHASES = {
    idle="Pick a track, then invite your friend.",
    listening="Waiting for %s to invite you.",
    inviting="Invite sent. Waiting for %s to join.",
    invited="%s invited you to race. Join to enter the lobby.",
    joining="Joining %s's race.",
    lobby="In the lobby. Ready up when you are set.",
    starting="Start proposed. Waiting for the race to begin.",
}
local REASONS = {
    left="You left the session.", peer_left="%s left the session.",
    timeout="The session timed out.", peer_timeout="%s's session timed out.",
    ack_timeout="%s stopped answering.",
    incompatible="Your versions or track do not match. Both players need the same Azeroth Kart.",
    peer_incompatible="Your versions or track do not match. Both players need the same Azeroth Kart.",
    combat="Entering combat closed the session.", peer_combat="%s entered combat.",
    world_leave="Changing zones closed the session.", peer_world_leave="%s changed zones.",
    send_throttled="WoW is limiting addon messages. Try again in a moment.",
    send_failed="Could not reach %s.", send_unknown="Could not reach %s.", send_error="Could not reach %s.",
}
local PENDING = {INVITE="Sending invite", JOIN="Joining", READY="Sending ready", START="Starting", CANCEL="Leaving"}

function Menu.lobbyPresentation(view)
    local copy = {available=false, title="Coming soon", status="Not connected",
        host=false, join=false, ready=false, start=false, leave=false, readyLabel="Ready",
        you="Not ready", friend="Open slot", friendReady=""}
    if type(view) ~= "table" or (view.phase ~= "closed" and not PHASES[view.phase]) then return copy end
    local peer = type(view.peer) == "string" and view.peer ~= "" and view.peer or "your friend"
    copy.available = true
    copy.title = view.role == "host" and "Hosting" or "Joining"
    if view.phase == "closed" then
        local reason = REASONS[view.reason] or ("Session ended (" .. tostring(view.reason) .. ").")
        copy.status = reason:find("%%s") and reason:format(peer) or reason
    else
        local status = PHASES[view.phase]
        copy.status = status:find("%%s") and status:format(peer) or status
        if view.pendingKind and PENDING[view.pendingKind] then
            copy.status = ("%s... (try %d of 3)"):format(PENDING[view.pendingKind], math.max(1, view.pendingAttempts or 1))
        end
    end
    copy.host, copy.join = view.canInvite == true, view.canJoin == true
    copy.ready, copy.start, copy.leave = view.canSetReady == true, view.canStart == true, view.canLeave == true
    copy.readyLabel = view.localReady and "Not ready" or "Ready"
    copy.you = view.localReady and (view.localReadyConfirmed and "Ready" or "Ready (sending)") or "Not ready"
    local joined = view.phase == "lobby" or view.phase == "starting"
    copy.friend = joined and peer or (view.phase == "closed" and "Open slot" or peer .. " (not joined)")
    copy.friendReady = joined and (view.peerReady and "Ready" or "Not ready") or ""
    return copy
end

-- ---------------------------------------------------------------------------
-- Sounds: the client's own interface sound kits (Mainline SoundKitConstants),
-- played only when present and never when the player switches sounds off.

Menu.SOUNDS = {click="IG_MAINMENU_OPTION", open="IG_MAINMENU_OPEN", checkOn="IG_MAINMENU_OPTION_CHECKBOX_ON",
    checkOff="IG_MAINMENU_OPTION_CHECKBOX_OFF", tick="UI_BATTLEGROUND_COUNTDOWN_TIMER",
    go="UI_BATTLEGROUND_COUNTDOWN_FINISHED", finish="LFG_REWARDS"}

function Menu.Play(name)
    if Menu.prefs and Menu.prefs.sound == false then return end
    local kit = type(SOUNDKIT) == "table" and SOUNDKIT[Menu.SOUNDS[name] or ""]
    if kit and type(PlaySound) == "function" then pcall(PlaySound, kit) end
end

-- The countdown's 3, 2, 1 tick and GO sounds as the cue changes.
function Menu.OnCue(cue)
    if Menu.disabled then return end
    if cue == "GO" then Menu.Play("go") elseif cue then Menu.Play("tick") end
end

-- ---------------------------------------------------------------------------
-- Counted widget helpers. Template internals are not counted, as in UI.lua.

local function count(kind) UI.objects[kind] = UI.objects[kind] + 1 end

local function inCombat()
    return type(InCombatLockdown) == "function" and InCombatLockdown() and true or false
end

local function newFrame(kind, parent, template)
    local ok, made = pcall(CreateFrame, kind, nil, parent, template)
    if not ok or not made then return nil end
    count("frames")
    return made
end

local function fontName(list)
    for _,name in ipairs(list) do
        if _G[name] ~= nil then return name end
    end
    return "GameFontNormal"
end

local function call(object, method, ...)
    local fn = object and object[method]
    if type(fn) ~= "function" then return false end
    return pcall(fn, object, ...)
end

local function newText(parent, font, anchor, x, y, value, relative, relativePoint)
    count("fontStrings")
    local label = parent:CreateFontString(nil, "OVERLAY", fontName(font or FONT.normal))
    if anchor then label:SetPoint(anchor, relative or parent, relativePoint or anchor, x or 0, y or 0) end
    if value then label:SetText(value) end
    return label
end

local function wrap(label, width, justify)
    label:SetWidth(width)
    label:SetJustifyH(justify or "LEFT")
    call(label, "SetWordWrap", true)
    return label
end

local function color(region, rgb, alpha)
    call(region, "SetTextColor", rgb[1], rgb[2], rgb[3], alpha or 1)
end

local function newTexture(parent, layer)
    count("textures")
    return parent:CreateTexture(nil, layer or "ARTWORK")
end

local function backdrop(frameObject, info, r, g, b, a, br, bg, bb)
    if not call(frameObject, "SetBackdrop", info) then return false end
    if r then call(frameObject, "SetBackdropColor", r, g, b, a or 1) end
    if br then call(frameObject, "SetBackdropBorderColor", br, bg, bb, 1) end
    return true
end

-- A dialog box (classic marble and stone) or a dark card, with mouse capture
-- so clicks never reach the canvas or the bar below.
local function panel(parent, info, width, height, anchor, x, y, r, g, b, a)
    local box = newFrame("Frame", parent, "BackdropTemplate") or newFrame("Frame", parent)
    box:SetSize(width, height)
    box:SetPoint(anchor or "CENTER", parent, anchor or "CENTER", x or 0, y or 0)
    backdrop(box, info, r, g, b, a)
    box:EnableMouse(true)
    return box
end

local function fonts(button, normal, highlight, disabled)
    for method,name in pairs({SetNormalFontObject=normal, SetHighlightFontObject=highlight,
        SetDisabledFontObject=disabled}) do
        if _G[name] ~= nil then call(button, method, _G[name]) end
    end
end

-- big: the Game Menu's red three-slice button; otherwise a panel button.
local function newButton(parent, label, width, height, anchor, x, y, onClick, big)
    local button = big and newFrame("Button", parent, "MainMenuFrameButtonTemplate")
        or newFrame("Button", parent, "UIPanelButtonTemplate") or newFrame("Button", parent)
    button:SetSize(width, height)
    button:SetPoint(anchor, parent, anchor, x, y)
    button:SetText(label)
    if onClick then
        button:SetScript("OnClick", function(...)
            Menu.Play("click")
            onClick(...)
        end)
    end
    return button
end

local function setEnabled(button, enabled)
    if enabled then button:Enable() else button:Disable() end
end

local function setShown(region, shown)
    if shown then region:Show() else region:Hide() end
end

-- A gold glow behind the selected list button, plus its locked highlight.
local function markSelected(buttons, glow, chosen)
    for id,button in pairs(buttons) do
        if id == chosen then
            call(button, "LockHighlight")
            glow:ClearAllPoints()
            glow:SetPoint("TOPLEFT", button, "TOPLEFT", -4, 4)
            glow:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 4, -4)
            glow:Show()
        else call(button, "UnlockHighlight") end
    end
    if chosen == nil or buttons[chosen] == nil then glow:Hide() end
end

-- ---------------------------------------------------------------------------
-- Preferences (account-wide AzerothKartDB.preferences, version 1).

local function save()
    if type(AzerothKartDB) ~= "table" or not Menu.prefsWritable then return end
    local record, old = {}, AzerothKartDB.preferences
    if type(old) == "table" then
        for key,value in pairs(old) do record[key] = value end -- keep fields this version does not know
    end
    local p = Menu.prefs
    record.version, record.track, record.kart, record.effects = 1, p.track, p.kart, p.effects
    record.devInfo, record.scale, record.sound = p.devInfo, p.scale, p.sound
    AzerothKartDB.preferences = record
end

local function trackInfo(id)
    for _,track in ipairs(Menu.TRACKS) do
        if track.id == id then return track end
    end
end

local function kartName(id)
    local sprite = Presentation.KART_SPRITES[id or UI.kartId]
    return id and sprite and sprite.name or (UI.kartSprite and UI.kartSprite.name or "Basic kart")
end

local function trackName() return (trackInfo(UI.trackId) or Menu.TRACKS[1]).name end

-- ---------------------------------------------------------------------------
-- Screens. Each is a dialog on the menu root; Show() displays one at a time.

local refresh = {}
local message -- per-screen message lines, keyed by screen

local function toast(screen, text, rgb)
    local line = message[screen]
    if not line then return end
    line:SetText(text or "")
    color(line, rgb or RED)
end

local function screenBox(name, title, width, height)
    local box = panel(Menu.root, DIALOG, width or 780, height or 600, "TOP", 0, -53)
    Menu.screens[name] = box
    box:Hide()
    local heading = newText(box, FONT.title, "TOP", 0, -26, title)
    color(heading, GOLD)
    message[name] = newText(box, FONT.normal, "BOTTOM", 0, 70, "")
    return box, heading
end

local function buildHome()
    local root = Menu.root
    local logo = newText(root, FONT.logo, "TOP", 0, -32, "Azeroth Kart")
    color(logo, GOLD)
    call(logo, "SetShadowOffset", 2, -2)
    call(logo, "SetShadowColor", 0, 0, 0, 1)
    Menu.view.logo = logo
    Menu.view.tagline = newText(root, FONT.white, "TOP", 0, -90,
        "Goblin-powered racing from the Shimmering Flats to Stormwind")
    local box = panel(root, DIALOG, 300, 270, "TOP", 0, -124)
    Menu.screens.home = box
    box:Hide()
    local entries = {
        {"Single Player", function() Menu.Show("tracks") end},
        {"Multiplayer |cffff8c26(soon)|r", function() Menu.Show("multiplayer") end},
        {"Garage", function() Menu.Show("garage") end},
        {"How to Play", function() Menu.Show("help") end},
        {"Settings", function() Menu.Show("settings") end},
    }
    Menu.view.homeButtons = {}
    for index,entry in ipairs(entries) do
        Menu.view.homeButtons[index] = newButton(box, entry[1], 236, 36, "TOP", 0, -26 - (index - 1) * 44, entry[2], true)
    end
    Menu.view.selection = newText(box, FONT.normal, "TOP", 0, -24, "", box, "BOTTOM")
    Menu.view.footer = newText(root, FONT.graySmall, "BOTTOM", 0, 22,
        "Fan-made addon, not affiliated with Blizzard Entertainment. Your track, kart and settings are remembered.")
    refresh.home = function()
        Menu.view.selection:SetText(("Track: %s    Kart: %s"):format(trackName(), kartName()))
    end
end

-- The list: each cup's heading, its tracks (Menu.TRACKS order), then its
-- coming-soon entries (Courses.LIST), disabled.
function Menu.trackRows()
    local rows = {}
    for _,cup in ipairs(Courses and Courses.CUPS or {{id="proving", name="Proving Grounds"}}) do
        rows[#rows + 1] = {heading=cup.name}
        for _,track in ipairs(Menu.TRACKS) do
            local course = Courses and Courses.get(track.id)
            if (course and course.cup or "proving") == cup.id then rows[#rows + 1] = {track=track} end
        end
        for _,course in ipairs(Courses and Courses.LIST or {}) do
            if course.cup == cup.id and course.soon then rows[#rows + 1] = {soon=course} end
        end
    end
    return rows
end

local function buildTracks()
    local box = screenBox("tracks", "Choose a Track", 780, 640)
    Menu.view.trackStep = newText(box, FONT.gray, "TOPRIGHT", -30, -34, "Step 1 of 2")
    local glow = newTexture(box, "ARTWORK")
    glow:SetColorTexture(1, 0.82, 0, 0.30)
    local buttons, soon = {}, {}
    local y = -78
    for _,row in ipairs(Menu.trackRows()) do
        if row.heading then
            color(newText(box, FONT.normal, "TOPLEFT", 38, y - 6, row.heading), GOLD)
            y = y - 26
        else
            local track, course = row.track, row.soon
            local label = track and track.name or (course.name .. "  |cffff8c26(soon)|r")
            local button = newButton(box, label, 310, 30, "TOPLEFT", 34, y, track and function()
                if UI.SelectTrack(track.id) then
                    Menu.Chose("track", track.id)
                    toast("tracks", "")
                elseif inCombat() then toast("tracks", "Leave combat to change tracks.")
                else toast("tracks", UI.status and UI.status:GetText() or "That track is unavailable.") end
                refresh.tracks()
            end or nil)
            fonts(button, "GameFontNormal", "GameFontHighlight", "GameFontDisable")
            if track then buttons[track.id] = button
            else button:Disable(); soon[course.id] = button end
            y = y - 34
        end
    end
    local card = panel(box, CARD, 340, 340, "TOPRIGHT", -32, -72, 0.05, 0.05, 0.06, 1)
    local preview = newTexture(card, "ARTWORK")
    preview:SetPoint("CENTER")
    local missing = newText(card, FONT.gray, "CENTER", 0, 0, "Preview unavailable")
    local name = wrap(newText(box, FONT.large, "TOPRIGHT", -32, -422), 340)
    local blurb = wrap(newText(box, FONT.white, "TOPRIGHT", -32, -446), 340)
    local facts = {}
    for index=1,3 do facts[index] = wrap(newText(box, FONT.normal, "TOPRIGHT", -32, -510 - (index - 1) * 20), 340) end
    newButton(box, "Back", 150, 30, "BOTTOMLEFT", 30, 26, function() Menu.Show("home") end)
    Menu.view.trackNext = newButton(box, "Next: Choose Kart", 240, 36, "BOTTOMRIGHT", -30, 22,
        function() Menu.Show("karts") end, true)
    Menu.view.trackButtons, Menu.view.trackPreview, Menu.view.soonButtons = buttons, preview, soon
    Menu.previewLoaded = {}
    refresh.tracks = function()
        local track = trackInfo(UI.trackId) or Menu.TRACKS[1]
        markSelected(buttons, glow, UI.trackId)
        name:SetText(track.name)
        blurb:SetText(track.blurb)
        for index,line in ipairs(facts) do line:SetText(track.facts[index] or "") end
        local cell = Menu.PREVIEW_CELLS[track.cell]
        local path = cell.path or Menu.PREVIEW_PATH
        -- A guarded load when the picture changes; one that failed is not retried.
        if Menu.previewLoaded[path] ~= false and Menu.previewPath ~= path then
            local ok, loaded = call(preview, "SetTexture", path)
            Menu.previewLoaded[path] = ok and loaded == true
            Menu.previewPath = Menu.previewLoaded[path] and path or nil
        end
        Menu.previewReady = Menu.previewPath == path
        setShown(preview, Menu.previewReady)
        setShown(missing, not Menu.previewReady)
        if Menu.previewReady then
            preview:SetSize(cell.width, cell.height)
            preview:SetTexCoord(cell.left, cell.right, cell.top, cell.bottom)
        end
    end
end

-- The garage turntable spins the chosen kart's sheet once every six seconds.
local SPIN = 2 * math.pi / 6
local function spin(elapsed)
    local view = Menu.view
    local sprite = view.stageSprite
    if not sprite or not view.stageReady then return end
    view.stageHeading = (view.stageHeading + (elapsed or 0) * SPIN) % (2 * math.pi)
    if sprite.frames then
        local frame = Presentation.kartFrame(sprite, view.stageHeading)
        if frame ~= view.stageFrame then
            view.stageFrame = frame
            view.stage:SetTexCoord(Presentation.kartFrameCoords(sprite, frame))
        end
    else view.stage:SetRotation(view.stageHeading - math.pi / 2) end
end

local function showStage(sprite)
    local view = Menu.view
    if view.stageSprite == sprite then return end
    view.stageSprite, view.stageFrame, view.stageHeading = sprite, nil, -math.pi / 4
    local ok, loaded = false, false
    if sprite then ok, loaded = call(view.stage, "SetTexture", sprite.path) end
    view.stageReady = ok and loaded == true
    setShown(view.stage, view.stageReady)
    setShown(view.stageMissing, not view.stageReady)
    if not view.stageReady then return end
    -- About seven pixels per world unit, shrunk to fit the 340-pixel stage; the
    -- frame centre sits pivot units east/north of the kart, as on the track.
    local scale = math.min(7, 320 / math.max(sprite.quadWidth, sprite.quadHeight))
    view.stage:SetSize(sprite.quadWidth * scale, sprite.quadHeight * scale)
    view.stage:ClearAllPoints()
    view.stage:SetPoint("CENTER", view.stageFrame0, "CENTER", (sprite.pivotX or 0) * scale, (sprite.pivotY or 0) * scale)
    if sprite.frames then call(view.stage, "SetRotation", 0)
    else call(view.stage, "SetTexCoord", 0, 1, 0, 1) end
    spin(0)
end

local function buildKarts()
    local box = screenBox("karts", "Choose Your Kart")
    Menu.screens.garage = box
    Menu.view.kartStep = newText(box, FONT.gray, "TOPRIGHT", -30, -34, "Step 2 of 2")
    local stage = panel(box, CARD, 360, 340, "TOPLEFT", 30, -80, 0.80, 0.75, 0.64, 1, 0.35, 0.30, 0.22)
    stage:SetScript("OnUpdate", function(_, elapsed) spin(elapsed) end)
    Menu.view.stage = newTexture(stage, "ARTWORK")
    Menu.view.stage:SetPoint("CENTER", stage, "CENTER", 0, 0)
    Menu.view.stageFrame0 = stage
    Menu.view.stageMissing = newText(stage, FONT.gray, "CENTER", 0, 0, "Preview unavailable")
    local order = Presentation.KART_ORDER
    local function step(delta)
        local index = 1
        for i,id in ipairs(order) do if id == UI.kartId then index = i end end
        Menu.ChooseKart(order[(index - 1 + delta) % #order + 1])
    end
    newButton(box, "<", 60, 30, "TOPLEFT", 30, -432, function() step(-1) end)
    newButton(box, ">", 60, 30, "TOPLEFT", 330, -432, function() step(1) end)
    local counter = newText(box, FONT.white, "TOP", 0, -20, "", stage, "BOTTOM")
    Menu.view.stageSprite = false
    local name = newText(box, FONT.huge, "TOPLEFT", 420, -84)
    local blurb = wrap(newText(box, FONT.white, "TOPLEFT", 420, -120), 330)
    local credit = wrap(newText(box, FONT.graySmall, "TOPLEFT", 420, -190), 330)
    local same = wrap(newText(box, FONT.small, "TOPLEFT", 420, -214,
        "Every kart handles the same: pick the look you like."), 330)
    color(same, GREEN)
    local glow = newTexture(box, "ARTWORK")
    glow:SetColorTexture(1, 0.82, 0, 0.30)
    local buttons = {}
    for index,id in ipairs(order) do
        local column, row = (index - 1) % 2, math.floor((index - 1) / 2)
        buttons[id] = newButton(box, Presentation.KART_SPRITES[id].name, 160, 28, "TOPLEFT",
            420 + column * 172, -262 - row * 38, function() Menu.ChooseKart(id) end)
    end
    newButton(box, "Back", 150, 30, "BOTTOMLEFT", 30, 26, function()
        Menu.Show(Menu.screen == "garage" and "home" or "tracks")
    end)
    Menu.view.race = newButton(box, "Race!", 240, 36, "BOTTOMRIGHT", -30, 22, function()
        if Menu.screen == "garage" then Menu.Show("home"); return end
        UI.Start()
        if UI.active then Menu.Show(nil)
        else toast("karts", UI.status and UI.status:GetText() or "The race could not start.") end
    end, true)
    Menu.view.kartButtons = buttons
    refresh.karts = function()
        local garage = Menu.screen == "garage"
        setShown(Menu.view.kartStep, not garage)
        Menu.view.race:SetText(garage and "Done" or "Race!")
        local sprite = UI.kartSprite
        markSelected(buttons, glow, UI.kartId)
        name:SetText(sprite and sprite.name or "Basic kart")
        local copy = Menu.KARTS[UI.kartId]
        blurb:SetText(copy and copy.blurb or "The kart art could not load, so a plain kart stands in.")
        credit:SetText(copy and copy.credit or "")
        local index = 0
        for i,id in ipairs(order) do if id == UI.kartId then index = i end end
        counter:SetText(("%d / %d"):format(index, #order))
        showStage(sprite)
    end
    refresh.garage = refresh.karts
    message.garage = message.karts
end

function Menu.ChooseKart(id)
    local screen = Menu.screen == "garage" and "garage" or "karts"
    if UI.SelectKart(id) then
        Menu.Chose("kart", UI.kartId)
        toast(screen, "")
    else
        local sprite = Presentation.KART_SPRITES[id]
        toast(screen, ("%s could not load; keeping %s."):format(sprite and sprite.name or "That kart", kartName()))
    end
    if refresh[screen] and Menu.screen == screen then refresh[screen]() end
end

local function buildMultiplayer()
    local box = screenBox("multiplayer", "Multiplayer")
    local badge = newText(box, FONT.large, "TOP", 0, -66, "COMING SOON")
    color(badge, SOON)
    wrap(newText(box, FONT.white, "TOP", 0, -96,
        "Race a friend in real time: one of you hosts and invites the other by character name. " ..
        "Two-player racing is being built and tested now; hosting and joining open here as soon as it is ready."),
        700, "CENTER")
    local view = Menu.view
    view.host = newButton(box, "Host a Race", 300, 36, "TOPLEFT", 40, -168, nil, true)
    wrap(newText(box, FONT.small, "TOPLEFT", 44, -210, "Invite one friend by full character name."), 296)
    view.join = newButton(box, "Join a Race", 300, 36, "TOPLEFT", 40, -248, nil, true)
    wrap(newText(box, FONT.small, "TOPLEFT", 44, -290, "Accept your friend's invite."), 296)
    newText(box, FONT.normal, "TOPLEFT", 40, -340, "Help test it now")
    wrap(newText(box, FONT.small, "TOPLEFT", 40, -362,
        "Type /akart net help in chat for the two-player connection test with a friend."), 300)
    local card = panel(box, CARD, 360, 300, "TOPRIGHT", -30, -150, 0.04, 0.04, 0.05, 0.95)
    view.lobbyTitle = newText(card, FONT.large, "TOP", 0, -14, "Lobby")
    newText(card, FONT.large, "TOPLEFT", 20, -50, "1")
    newText(card, FONT.largeWhite, "TOPLEFT", 44, -50, "You")
    view.youKart = newText(card, FONT.small, "TOPLEFT", 44, -72, "")
    view.youReady = newText(card, FONT.gray, "TOPRIGHT", -20, -52, "")
    newText(card, FONT.large, "TOPLEFT", 20, -104, "2")
    view.friend = newText(card, FONT.gray, "TOPLEFT", 44, -104, "")
    view.friendReady = newText(card, FONT.gray, "TOPRIGHT", -20, -106, "")
    view.lobbyTrack = newText(card, FONT.white, "TOPLEFT", 20, -158, "")
    view.lobbyStatus = wrap(newText(card, FONT.normal, "TOPLEFT", 20, -186, ""), 320)
    view.ready = newButton(card, "Ready", 100, 26, "BOTTOMLEFT", 16, 16)
    view.start = newButton(card, "Start", 100, 26, "BOTTOM", 0, 16)
    view.leave = newButton(card, "Leave", 100, 26, "BOTTOMRIGHT", -16, 16)
    newButton(box, "Back", 150, 30, "BOTTOMLEFT", 30, 26, function() Menu.Show("home") end)
    refresh.multiplayer = function()
        local bridge, session = Menu.bridge, nil
        if bridge and type(bridge.view) == "function" then
            local ok, copied = pcall(bridge.view)
            session = ok and copied or nil
        end
        local copy = Menu.lobbyPresentation(session)
        setShown(badge, not copy.available)
        view.lobbyTitle:SetText(copy.available and copy.title or "Lobby preview")
        view.youKart:SetText(kartName())
        view.youReady:SetText(copy.you)
        view.friend:SetText(copy.friend)
        view.friendReady:SetText(copy.friendReady)
        view.lobbyTrack:SetText(("Track: %s    Laps: 3"):format(trackName()))
        view.lobbyStatus:SetText(copy.available and copy.status or "Not connected. Hosting and joining are coming soon.")
        view.ready:SetText(copy.readyLabel)
        for _,key in ipairs({"host", "join", "ready", "start", "leave"}) do setEnabled(view[key], copy[key]) end
    end
end

-- Proposed for Codex's session adapter (not wired to any command yet): it
-- registers {view = function() return copiedPeerSessionView end}. Only the
-- view's capabilities enable controls; with no bridge, everything stays
-- disabled and marked Coming soon.
function Menu.SetSessionBridge(bridge)
    Menu.bridge = type(bridge) == "table" and bridge or nil
    if Menu.screen == "multiplayer" and refresh.multiplayer then refresh.multiplayer() end
end

local function buildHelp()
    local box = screenBox("help", "How to Play")
    newText(box, FONT.large, "TOPLEFT", 40, -84, "Controls")
    local keys, actions = {}, {}
    for index,row in ipairs(Menu.CONTROLS) do keys[index], actions[index] = row[1], row[2] end
    -- Two columns of equal line height, one font string each.
    for _,column in ipairs({{FONT.normal, 40, keys}, {FONT.white, 200, actions}}) do
        local lines = newText(box, column[1], "TOPLEFT", column[2], -116, table.concat(column[3], "\n"))
        lines:SetJustifyH("LEFT")
        call(lines, "SetSpacing", 12)
    end
    newText(box, FONT.large, "TOPLEFT", 410, -84, "Racing")
    local rules = wrap(newText(box, FONT.white, "TOPLEFT", 410, -116, table.concat(Menu.RULES, "\n\n")), 340)
    call(rules, "SetSpacing", 3)
    wrap(newText(box, FONT.graySmall, "TOPLEFT", 40, -440,
        "The keyboard is only captured during a race you start yourself, out of combat. " ..
        "Kart models: Goblin Mortar Trike by erwtenpeller and Chriz (Vast Graphics); Steam Tank, Dwarven " ..
        "Biker, Gryphon Rider and Gyrocopter from the wc3c ITE project. Scenery, drag car and effects are original."),
        700)
    newButton(box, "Back", 150, 30, "BOTTOMLEFT", 30, 26, function() Menu.Show("home") end)
end

local function buildSettings()
    local box = screenBox("settings", "Settings")
    local view = Menu.view
    newText(box, FONT.large, "TOPLEFT", 60, -100, "Window size")
    local glow = newTexture(box, "ARTWORK")
    glow:SetColorTexture(1, 0.82, 0, 0.30)
    local sizes = {}
    for index,scale in ipairs(Menu.SCALES) do
        sizes[scale] = newButton(box, ("%d%%"):format(math.floor(scale * 100 + 0.5)), 90, 28, "TOPLEFT",
            250 + (index - 1) * 102, -94, function() Menu.SetScale(scale) end)
    end
    local function check(label, detail, y, onClick)
        local button = newFrame("CheckButton", box, "UICheckButtonTemplate") or newFrame("CheckButton", box)
        button:SetSize(32, 32)
        button:SetPoint("TOPLEFT", box, "TOPLEFT", 56, y)
        button:SetScript("OnClick", function()
            onClick()
            Menu.Play(button:GetChecked() and "checkOn" or "checkOff")
        end)
        newText(box, FONT.large, "TOPLEFT", 96, y - 4, label)
        wrap(newText(box, FONT.small, "TOPLEFT", 96, y - 26, detail), 560)
        return button
    end
    view.effects = check("Drift and boost effects", "Tyre dust, sparks, exhaust flames and soot.", -156,
        function() Menu.SetEffects(not Menu.prefs.effects) end)
    view.sound = check("Sound effects", "Menu clicks, the countdown beeps and the finish fanfare.", -226,
        function() Menu.SetSound(not Menu.prefs.sound) end)
    view.devInfo = check("Show developer info", "Adds the timing line and the Print Probe button under the track.", -296,
        function() Menu.SetDevInfo(not Menu.prefs.devInfo) end)
    newButton(box, "Reset window position", 220, 28, "TOPLEFT", 60, -376, function() Menu.ResetPosition() end)
    newText(box, FONT.graySmall, "TOPLEFT", 296, -382, "Drag the window by its title bar to move it.")
    newText(box, FONT.graySmall, "BOTTOM", 0, 100, "Settings are saved for your account.")
    newButton(box, "Back", 150, 30, "BOTTOMLEFT", 30, 26, function() Menu.Show("home") end)
    refresh.settings = function()
        markSelected(sizes, glow, Menu.prefs.scale)
        for scale,button in pairs(sizes) do setEnabled(button, Menu.Fits(scale)) end
        call(view.effects, "SetChecked", Menu.prefs.effects)
        call(view.sound, "SetChecked", Menu.prefs.sound)
        call(view.devInfo, "SetChecked", Menu.prefs.devInfo)
    end
end

-- ---------------------------------------------------------------------------
-- Settings commands.

-- Whether the whole window fits the screen at a size (unknown screen: yes).
function Menu.Fits(scale)
    local okW, width = call(UIParent, "GetWidth")
    local okH, height = call(UIParent, "GetHeight")
    if not okW or not okH or type(width) ~= "number" or type(height) ~= "number" then return true end
    return Menu.WINDOW_WIDTH * scale <= width and Menu.WINDOW_HEIGHT * scale <= height
end

-- The saved size, or the largest smaller size that fits this screen.
local function applyScale()
    local chosen = Menu.SCALES[1]
    for _,scale in ipairs(Menu.SCALES) do
        if scale <= Menu.prefs.scale and Menu.Fits(scale) then chosen = scale end
    end
    call(UI.window, "SetScale", chosen)
end

function Menu.SetScale(scale)
    for _,allowed in ipairs(Menu.SCALES) do
        if scale == allowed and Menu.Fits(scale) then
            Menu.prefs.scale = scale
            call(UI.window, "SetScale", scale)
            save()
        end
    end
    if Menu.screen == "settings" then refresh.settings() end
end

function Menu.SetEffects(enabled)
    Menu.prefs.effects = enabled == true
    if UI.SetEffectsEnabled then UI.SetEffectsEnabled(Menu.prefs.effects) end
    save()
    if Menu.screen == "settings" then refresh.settings() end
end

function Menu.SetSound(enabled)
    Menu.prefs.sound = enabled == true
    save()
    if Menu.screen == "settings" then refresh.settings() end
end

function Menu.SetDevInfo(enabled)
    Menu.prefs.devInfo = enabled == true
    save()
    Menu.barKey = nil
    Menu.Sync()
    if Menu.screen == "settings" then refresh.settings() end
end

function Menu.ResetPosition()
    UI.window:ClearAllPoints()
    UI.window:SetPoint("CENTER")
end

-- ---------------------------------------------------------------------------
-- Race HUD overlay, bottom bar and results dialog.

local function buildRaceOverlay()
    local overlay = newFrame("Frame", UI.canvas)
    overlay:SetAllPoints(UI.canvas)
    call(overlay, "SetFrameLevel", (UI.canvas:GetFrameLevel() or 1) + 4)
    Menu.overlay = overlay
    local function plate(anchor, x, width)
        local piece = newTexture(overlay, "BACKGROUND")
        piece:SetColorTexture(0, 0, 0, 0.45)
        piece:SetSize(width, 62)
        piece:SetPoint(anchor, overlay, anchor, x, 0)
    end
    plate("TOPLEFT", 0, 190)
    plate("TOPRIGHT", 0, 190)
    local view = Menu.view
    view.lap = newText(overlay, FONT.lap, "TOPLEFT", 16, -10, "")
    view.time = newText(overlay, FONT.timer, "TOPRIGHT", -16, -10, "")
    view.best = newText(overlay, FONT.white, "TOPRIGHT", -16, -40, "")
    view.gate = newText(overlay, FONT.white, "TOPLEFT", 16, -40, "")
    for _,label in ipairs({view.lap, view.time, view.best, view.gate}) do
        call(label, "SetShadowOffset", 1, -1)
        call(label, "SetShadowColor", 0, 0, 0, 1)
    end
    color(view.time, WHITE)
    view.capture = newText(overlay, FONT.small, "BOTTOM", 0, 8, "Controls active - Esc to release")
    view.capture:Hide()
end

-- UI's HUD lines and meter keep their rows; the bottom bar is rearranged so
-- Start and Stop never share a spot (a double click cannot start and stop).
local function arrangeRaceScreen()
    local function place(region, x, y, anchor)
        region:ClearAllPoints()
        region:SetPoint(anchor or "BOTTOMLEFT", UI.window, anchor or "BOTTOMLEFT", x, y)
    end
    color(UI.hud, {0.62, 0.62, 0.62})
    color(UI.status, GOLD)
    for _,line in ipairs({UI.lapHud, UI.checkpointHud, UI.driftHud}) do color(line, {0.92, 0.92, 0.88}) end
    local bar = {
        {UI.startButton, 24, 150, "Start Race"}, {UI.trackButton, 182, 210}, {UI.kartButton, 400, 210},
        {UI.stopButton, 618, 110, "Stop"},
    }
    for _,entry in ipairs(bar) do
        local button, x, width, label = entry[1], entry[2], entry[3], entry[4]
        place(button, x, 12)
        button:SetSize(width, 24)
        if label then button:SetText(label) end
    end
    UI.probeButton:ClearAllPoints()
    UI.probeButton:SetPoint("BOTTOMRIGHT", UI.window, "BOTTOMRIGHT", -24, 12)
    UI.probeButton:SetSize(100, 24)
    Menu.view.mainMenu = newButton(UI.window, "Main Menu", 110, 24, "BOTTOMLEFT", 618, 12,
        function() Menu.Show("home") end)
    local cue = UI.countdownCue
    local big = fontName(FONT.countdown)
    if _G[big] ~= nil then call(cue, "SetFontObject", _G[big]) end
    color(cue, GOLD)
    call(cue, "SetShadowOffset", 3, -3)
    call(cue, "SetShadowColor", 0, 0, 0, 1)
end

-- UI's results panel restyled as a dark dialog, with track/kart, lap times
-- and three more ways out. Title, detail, hint, Restart and Close results
-- keep their text and behaviour.
local function arrangeResults()
    local summary = UI.summary
    summary:SetSize(460, 312)
    local level = (UI.canvas:GetFrameLevel() or 1) + 8 -- above the race overlay
    call(summary, "SetFrameLevel", level)
    for _,button in ipairs({UI.restartButton, UI.dismissSummaryButton}) do call(button, "SetFrameLevel", level + 1) end
    backdrop(summary, _G.BACKDROP_DARK_DIALOG_32_32 or DARK_DIALOG)
    local function place(region, anchor, x, y, justify)
        region:ClearAllPoints()
        region:SetPoint(anchor, summary, anchor, x, y)
        if justify then region:SetJustifyH(justify) end
    end
    local huge = fontName(FONT.huge)
    if _G[huge] ~= nil then call(UI.summaryTitle, "SetFontObject", _G[huge]) end
    place(UI.summaryTitle, "TOP", 0, -26, "CENTER")
    local view = Menu.view
    view.resultLine = newText(summary, FONT.white, "TOP", 0, -60, "")
    local detail = fontName(FONT.largeWhite)
    if _G[detail] ~= nil then call(UI.summaryDetail, "SetFontObject", _G[detail]) end
    call(UI.summaryDetail, "SetSpacing", 4)
    place(UI.summaryDetail, "TOP", 0, -86, "CENTER")
    view.resultLaps = newText(summary, FONT.white, "TOP", 0, -172, "")
    place(UI.summaryHint, "BOTTOM", 0, 92, "CENTER")
    color(UI.summaryHint, {0.62, 0.62, 0.62})
    place(UI.restartButton, "BOTTOMLEFT", 28, 54)
    UI.restartButton:SetSize(196, 28)
    place(UI.dismissSummaryButton, "BOTTOMRIGHT", -28, 54)
    UI.dismissSummaryButton:SetSize(196, 28)
    local function leave(screen)
        return function()
            UI.DismissSummary()
            Menu.Show(screen)
        end
    end
    newButton(summary, "Change Kart", 128, 26, "BOTTOMLEFT", 28, 20, leave("karts"))
    newButton(summary, "Change Track", 128, 26, "BOTTOM", 0, 20, leave("tracks"))
    newButton(summary, "Main Menu", 128, 26, "BOTTOMRIGHT", -28, 20, leave("home"))
    summary:SetScript("OnShow", function() Menu.OnResults() end)
    summary:SetScript("OnHide", function() Menu.barKey = nil; Menu.Sync() end)
end

-- Completed lap times seen by presentation (never written into Laps/Race).
-- A countdown starts a fresh list; refreshHud runs on every lap completion.
local function recordLaps()
    local race, view = UI.race, Menu.view
    if not race then return end
    local laps = race.laps
    if race.status == "countdown" or laps.completedLaps < #view.lapTimes then view.lapTimes = {} end
    while #view.lapTimes < laps.completedLaps and laps.lastLapTicks do
        view.lapTimes[#view.lapTimes + 1] = laps.lastLapTicks
    end
end

function Menu.OnResults()
    local view = Menu.view
    recordLaps()
    if UI.race and UI.race.status == "finished" and Menu.fanfareRace ~= UI.race then
        Menu.fanfareRace = UI.race -- once per finished run, not on every reopen
        Menu.Play("finish")
    end
    view.resultLine:SetText(("%s    %s"):format(trackName(), kartName()))
    local times, best = {}, nil
    for _,ticks in ipairs(view.lapTimes) do
        if not best or ticks < best then best = ticks end
    end
    for index,ticks in ipairs(view.lapTimes) do
        local line = ("Lap %d  %s"):format(index, Menu.formatTime(ticks * Physics.FIXED_DT))
        times[index] = ticks == best and #view.lapTimes > 1 and "|cff66ff66" .. line .. "|r" or line
    end
    view.resultLaps:SetText(#times > 0 and table.concat(times, "     ") or "")
    Menu.barKey = nil
    Menu.Sync()
end

-- Per-frame presentation from render(): the big lap/time/best lines. Cheap
-- numbers are compared first, so strings are only built when the shown text
-- can change (the running clock shows tenths: every sixth tick).
function Menu.RefreshRaceHud()
    local view = Menu.view
    if Menu.disabled or not view.lap then return end
    local race, laps, progress = UI.race, UI.laps, UI.checkpoints
    local status = race and race.status or "none"
    local ticks = race and race.totalTicks or 0
    local unit = status == "running" and math.floor(ticks / 6) or ticks
    local best = laps and laps.bestLapTicks or -1
    local nextGate = progress and not progress.complete and progress.nextGate or 0
    local completed = laps and laps.completedLaps or 0
    if status == view.hudStatus and unit == view.hudUnit and best == view.hudBest
        and nextGate == view.hudGate and completed == view.hudLaps and UI.track == view.hudTrack then return end
    view.hudStatus, view.hudUnit, view.hudBest = status, unit, best
    view.hudGate, view.hudLaps, view.hudTrack = nextGate, completed, UI.track
    local lap, time, bestText = Menu.raceLines(race, laps)
    view.lap:SetText(lap)
    view.time:SetText(time)
    view.best:SetText(bestText)
    local gates = UI.track and UI.track.gates
    local gate = ""
    if race and status ~= "finished" and gates and gates[nextGate] then
        gate = "Next gate: " .. gates[nextGate].name
    end
    view.gate:SetText(gate)
end

-- Deliberate kart and track changes are remembered however they are made
-- (menus or the bar's quick buttons). Restoration at load and on first open
-- sets the baseline, so a failed restore never overwrites the saved choice.
-- The player's deliberate, successful choice of a track or kart on a menu
-- screen is remembered even when it was already current (a saved choice that
-- failed to load leaves the default showing), and a track choice replaces a
-- saved-track restore still waiting for an open out of combat.
function Menu.Chose(kind, id)
    if Menu.disabled or not Menu.prefs then return end
    if kind == "track" then
        Menu.seenTrack, Menu.prefs.track, Menu.trackRestored = UI.trackId, id, true
    else
        Menu.seenKart, Menu.prefs.kart = UI.kartId, id
    end
    save()
end

function Menu.OnKartChanged()
    if Menu.disabled or Menu.seenKart == nil or not UI.kartId or UI.kartId == Menu.seenKart then return end
    Menu.seenKart, Menu.prefs.kart = UI.kartId, UI.kartId
    save()
end

-- A track change made elsewhere (the bar's Track button) is the player's
-- choice too, and also replaces a waiting restore.
local function rememberTrack()
    if Menu.restoring or Menu.seenTrack == nil or UI.trackId == Menu.seenTrack then return end
    Menu.seenTrack, Menu.prefs.track, Menu.trackRestored = UI.trackId, UI.trackId, true
    save()
end

-- ---------------------------------------------------------------------------
-- Scenes: a menu screen, or the race view (driving, results or the track).

local function scene()
    if Menu.screen then return "menu" end
    if UI.active then return "race" end
    if UI.summary and UI.summary:IsShown() then return "results" end
    return "track"
end

function Menu.Sync()
    if Menu.disabled or not Menu.root then return end
    rememberTrack()
    if UI.active ~= Menu.wasActive then
        Menu.wasActive = UI.active
        if UI.active and Menu.screen then Menu.Show(nil); return end
    end
    if UI.race then recordLaps() end
    local current = scene()
    local key = current .. (Menu.prefs.devInfo and "+dev" or "")
    if key == Menu.barKey then return end
    Menu.barKey = key
    local track = current == "track"
    setShown(UI.startButton, track)
    setShown(UI.trackButton, track)
    setShown(UI.kartButton, track)
    setShown(Menu.view.mainMenu, track)
    setShown(UI.stopButton, current == "race")
    setShown(UI.probeButton, Menu.prefs.devInfo and current ~= "menu")
    setShown(UI.hud, Menu.prefs.devInfo)
    setShown(Menu.view.capture, current == "race")
    setShown(Menu.overlay, current ~= "menu")
end

function Menu.Show(screen)
    if Menu.disabled or not Menu.root then return end
    if screen and UI.active then screen = nil end -- never cover a live run
    for _,box in pairs(Menu.screens) do box:Hide() end
    Menu.screen = screen
    local home = screen == "home"
    setShown(Menu.view.logo, home)
    setShown(Menu.view.tagline, home)
    setShown(Menu.view.footer, home)
    if screen then
        Menu.root:Show()
        Menu.screens[screen]:Show()
        toast(screen, "")
        if refresh[screen] then refresh[screen]() end
    else Menu.root:Hide() end
    Menu.barKey = nil
    Menu.Sync()
end

-- The window just opened: restore the saved track once, then show results
-- if a run's results are still up, otherwise the main menu.
function Menu.OnWindowShown()
    if Menu.disabled or not Menu.root or not Menu.closed then return end
    Menu.closed = false
    -- The saved track is applied on the first open out of combat (the loader
    -- needs a shown window, and selection is refused in combat).
    if not Menu.trackRestored and not inCombat() then
        Menu.trackRestored = true
        local track = Menu.prefs.track
        Menu.restoring = true
        if track and track ~= UI.trackId and not UI.active then UI.SelectTrack(track) end
        Menu.restoring = false
        Menu.seenTrack = UI.trackId
    end
    Menu.Play("open")
    if UI.active or (UI.summary and UI.summary:IsShown()) then Menu.Show(nil)
    else Menu.Show("home") end
end

-- ---------------------------------------------------------------------------
-- Window chrome: the dialog header and a drag handle along the top edge.

local function buildChrome()
    local window = UI.window
    backdrop(window, _G.BACKDROP_DARK_DIALOG_32_32 or DARK_DIALOG)
    local header = newFrame("Frame", window, "DialogHeaderTemplate")
    if header and call(header, "Setup", "Azeroth Kart") then
        header:ClearAllPoints()
        header:SetPoint("TOP", window, "TOP", 0, 11)
        Menu.header = header
    else
        local title = newText(window, FONT.large, "TOP", 0, -18, "Azeroth Kart")
        color(title, GOLD)
    end
    -- A hidden watcher tells a real close (the window itself hidden) from
    -- its parent being hidden (Alt+Z, cinematics), which keeps the screen.
    local watcher = newFrame("Frame", window)
    watcher:SetScript("OnHide", function() if not window:IsShown() then Menu.closed = true end end)
    Menu.closed = true
    call(window, "SetMovable", true)
    local handle = newFrame("Frame", window)
    handle:SetPoint("TOPLEFT", window, "TOPLEFT", 12, -6)
    handle:SetPoint("BOTTOMRIGHT", window, "TOPRIGHT", -100, -42)
    handle:EnableMouse(true)
    call(handle, "RegisterForDrag", "LeftButton")
    handle:SetScript("OnDragStart", function() call(window, "StartMoving") end)
    handle:SetScript("OnDragStop", function() call(window, "StopMovingOrSizing") end)
end

local function buildRoot()
    local root = newFrame("Frame", UI.window)
    Menu.root = root
    root:SetPoint("TOPLEFT", UI.window, "TOPLEFT", 12, -44)
    root:SetPoint("BOTTOMRIGHT", UI.window, "BOTTOMRIGHT", -12, 12)
    call(root, "SetFrameLevel", (UI.window:GetFrameLevel() or 1) + 20)
    root:EnableMouse(true)
    local dim = newTexture(root, "BACKGROUND")
    dim:SetColorTexture(0, 0, 0, 0.62)
    dim:SetPoint("TOPLEFT", root, "TOPLEFT", 16, -14)
    dim:SetPoint("BOTTOMRIGHT", root, "TOPLEFT", 816, -494)
    local cover = newTexture(root, "BACKGROUND")
    cover:SetColorTexture(0.03, 0.03, 0.04, 1)
    cover:SetPoint("TOPLEFT", root, "TOPLEFT", 0, -494)
    cover:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", 0, 0)
    root:Hide()
end

-- Called by UI.Create through pcall when this module fails to build: hide
-- whatever was made and hand the window back to UI's basic controls.
function Menu.Disable(err)
    Menu.disabled = true
    if Menu.root then Menu.root:Hide() end
    if Menu.overlay then Menu.overlay:Hide() end
    if Menu.view.mainMenu then Menu.view.mainMenu:Hide() end
    if UI then
        for _,button in ipairs({UI.startButton, UI.stopButton, UI.trackButton, UI.kartButton, UI.probeButton}) do
            if button then button:Show() end
        end
        if UI.hud then UI.hud:Show() end
    end
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("Azeroth Kart: menus unavailable (" .. tostring(err) .. "); basic controls remain.")
    end
end

function Menu.Create(ui)
    UI = ui
    message = {}
    Menu.messages = message
    Menu.view.lapTimes = {}
    Menu.prefs, Menu.prefsWritable = Menu.readPreferences(AzerothKartDB)
    buildChrome()
    buildRaceOverlay()
    arrangeRaceScreen()
    arrangeResults()
    buildRoot()
    buildHome()
    buildTracks()
    buildKarts()
    buildMultiplayer()
    buildHelp()
    buildSettings()
    applyScale()
    if UI.SetEffectsEnabled then UI.SetEffectsEnabled(Menu.prefs.effects) end
    if Menu.prefs.kart and Menu.prefs.kart ~= UI.kartId then UI.SelectKart(Menu.prefs.kart) end
    Menu.seenKart = UI.kartId or false
    Menu.seenTrack = UI.trackId
    Menu.wasActive = UI.active
    Menu.RefreshRaceHud()
    Menu.Sync()
end

return Menu
