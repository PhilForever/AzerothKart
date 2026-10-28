-- Azeroth Kart front end: the main menu, track and kart choice, the experimental
-- two-player lobby, help, settings, the race HUD overlay and the results
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
-- Copy and data. Karts share a 17x31 body; Physics owns their handling profiles.

-- The track list's copy, in display order within each cup (Courses.CUPS).
-- Courses marked `soon` in Courses.LIST are listed after these, disabled,
-- even when their copy is ready here.
Menu.TRACKS = {
    {id="mirage_raceway", name="Mirage Raceway", cell=0,
        blurb="A sun-baked salt circuit on the dry Shimmering Flats, run between the rival goblin and gnome camps.",
        facts={"3 laps, 4 gates", "Counterclockwise: North, West, South, Start", "Off the road, rough salt slows you down"}},
    {id="stormwind_city", name="Stormwind City Circuit", cell="stormwind",
        blurb="Start in the Valley of Heroes, through the gate into the Trade District, then the canals: "
            .. "Old Town, the Dwarven District, Cathedral Square, the Park and the Mage Quarter.",
        facts={"3 laps, 6 gates named for the districts", "The canals stay on your left all lap",
            "Full speed to the street walls"}},
    {id="ironforge_gp", name="Ironforge Grand Prix", cell="ironforge",
        blurb="From the Gates round the Commons, the Mystic Ward and the Forlorn Cavern, through the "
            .. "Great Forge's fire, then Tinker Town and the Military Ward.",
        facts={"3 laps, 7 gates named for the districts", "Tight tunnels in and out of the Forlorn Cavern",
            "Mind the lava: the forges' walls are solid"}},
    {id="darnassus_canopy", name="Darnassus Canopy Run", cell="darnassus",
        blurb="Start on the Warrior's Terrace, north past the Craftsmen's Terrace, down past the Cenarion "
            .. "Enclave to the Temple Gardens' lake, round the Temple of the Moon and up past the Tradesmen's Terrace.",
        facts={"3 laps, 6 gates named for the districts", "Down from the upper terraces to the lake and back up",
            "Full speed to the street walls"}},
    {id="orgrimmar_canyon", name="Orgrimmar Canyon Rush", cell="orgrimmar",
        blurb="Start on the canyon road behind the city gate, then round the Cleft of Shadow: the Valley of "
            .. "Strength, the Drag, the Valley of Wisdom and down the Cleft's rim.",
        facts={"3 laps, 4 gates named for the districts", "Counterclockwise round the Cleft of Shadow",
            "Full speed to the street walls"}},
    {id="thunder_bluff_skyway", name="Thunder Bluff Skyway", cell="thunderbluff",
        blurb="Start where the lift arrives and lap the Lower Rise high over Mulgore, out over rope bridges "
            .. "to the Spirit Rise, the Elder Rise and the Hunter Rise and back.",
        facts={"3 laps, 6 gates named for the rises", "Six narrow rope bridges, a long way down",
            "Full speed to the street walls"}},
    {id="undercity_slime", name="Undercity Slime Circuit", cell="undercity",
        blurb="Start by the slime below the Apothecarium and race round the canal ring: past the Rogues' and "
            .. "Magic Quarters, under the Ruins of Lordaeron and back by the War Quarter, over a bridge at every section.",
        facts={"3 laps, 6 gates named for the quarters", "Six bridges over the slime: sharp turns on and off",
            "Full speed to the street walls"}},
    {id="scarlet_graveyard", name="Scarlet Graveyard", cell="scarletgraveyard",
        blurb="Through the monastery's portal and up the hall to the Chamber of Atonement, down the stairs into "
            .. "the Forlorn Cloister and across its graveyard to Honor's Tomb. No road here: find your way.",
        facts={"Sprint: one run through 3 gates", "Full speed on the grass; graves and tombs block",
            "The finish is Honor's Tomb"}},
    {id="scarlet_library", name="Scarlet Library", cell="scarletlibrary",
        blurb="From the portal down the long hall to the Huntsman's Cloister, past Houndmaster Loksey's kennel, "
            .. "then up through the Gallery of Treasures and the Athenaeum to Arcanist Doan's round library.",
        facts={"Sprint: one run through 4 gates", "Full speed across the cloister's lawn",
            "The finish is the round library's door"}},
    {id="scarlet_armory", name="Scarlet Armory", cell="scarletarmory",
        blurb="From the portal across the Training Grounds, the one open sky, up into the Footman's and the "
            .. "Crusader's Armories, along the long hall into the round Hall of Champions and down its stairs "
            .. "to Herod.",
        facts={"Sprint: one run through 5 gates", "Full speed across the Training Grounds",
            "The finish is down the stairs, beside Herod"}},
    {id="scarlet_cathedral", name="Scarlet Cathedral", cell="scarletcathedral",
        blurb="From the portal into the Chapel Gardens, round their pools, up the stairs beside the falls and "
            .. "off their landing, through the cathedral's door and up the nave to the altar, where Mograine and "
            .. "Whitemane stand.",
        facts={"Sprint: one run through 4 gates", "The pools block; the stairs turn at a landing",
            "The finish is before the altar"}},
    -- The Battlegrounds Cup's course (version 2: laid out on the real gulch).
    -- A course listed as coming soon shows in trackRows without a board.
    {id="warsong_gulch", name="Warsong Gulch", cell="warsonggulch",
        blurb="The real gulch: up the Alliance tunnel into Silverwing Hold, round the flag, out of the front "
            .. "door and down the east path; then down the Horde tunnel into the Lumber Mill, round its flag "
            .. "and out of the side door, every lap.",
        facts={"3 laps, 7 gates: both flags every lap", "Laid out from the game's own map",
            "Boots in each tunnel; the arrow shows the way"}},
}

local WC3C = "Model: ITE project (wc3c), author unknown"
local BLIZZARD = "Model: Blizzard Entertainment (Warcraft III)"
Menu.KARTS = {
    goblin_mortar_trike={blurb="A goblin three-wheeler with a mortar bolted on the back and exhaust to spare.",
        credit="Model: erwtenpeller and Chriz (Vast Graphics)"},
    steam_tank={blurb="A dwarven siege engine, smoke stacks blazing.", credit=WC3C},
    dwarven_biker={blurb="A dwarf on a roaring two-wheeler, built on the trike's frame.", credit=WC3C},
    gryphon_rider={blurb="A gryphon skimming low over the salt. No engine: it trails wind instead of flame.",
        credit=WC3C},
    gyrocopter={blurb="A gnomish flying machine, hovering just above the track.", credit=WC3C},
    dwarf_car={blurb="A dwarven steam car, all brass and rivets, a pipe puffing at the back.", credit=BLIZZARD},
    orc_demolisher={blurb="The Horde's siege cart: tusks, spikes and two pots of fire on the back.",
        credit=BLIZZARD},
    meat_wagon={blurb="The Scourge's bone cart on spiked wheels. No engine: it trails wind when it boosts.",
        credit=BLIZZARD},
    glaive_thrower={blurb="A Night Elf ballista on wheels, its great glaive cocked. It trails wind, not flame.",
        credit=BLIZZARD},
    goblin_drag_car={blurb="Mirage Raceway's own rocket car: two shark-faced pods roped to a goblin on a cart.",
        credit="Model: Blizzard Entertainment (World of Warcraft)"},
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
    "Pass the gates in order (the HUD names the next one); each full circuit is a lap. Three laps finish the race; "
        .. "a Scarlet Crusade sprint is one run to its last gate.",
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
    orgrimmar={path="Interface\\AddOns\\AzerothKart\\Assets\\Tracks\\Orgrimmar\\Preview.tga",
        left=0, right=1, top=0, bottom=1, width=320, height=320},
    darnassus={path="Interface\\AddOns\\AzerothKart\\Assets\\Tracks\\Darnassus\\Preview.tga",
        left=0, right=1, top=0, bottom=1, width=320, height=320},
    undercity={path="Interface\\AddOns\\AzerothKart\\Assets\\Tracks\\Undercity\\Preview.tga",
        left=0, right=1, top=0, bottom=1, width=320, height=320},
    thunderbluff={path="Interface\\AddOns\\AzerothKart\\Assets\\Tracks\\ThunderBluff\\Preview.tga",
        left=0, right=1, top=0, bottom=1, width=320, height=320},
    -- The Graveyard's picture is twice as wide as tall (2048 x 1024 world units); the Library's and the
    -- Armory's are square; the Cathedral's is twice as tall as wide (1024 x 2048).
    scarletgraveyard={path="Interface\\AddOns\\AzerothKart\\Assets\\Tracks\\ScarletGraveyard\\Preview.tga",
        left=0, right=1, top=0, bottom=1, width=320, height=160},
    scarletlibrary={path="Interface\\AddOns\\AzerothKart\\Assets\\Tracks\\ScarletLibrary\\Preview.tga",
        left=0, right=1, top=0, bottom=1, width=320, height=320},
    scarletarmory={path="Interface\\AddOns\\AzerothKart\\Assets\\Tracks\\ScarletArmory\\Preview.tga",
        left=0, right=1, top=0, bottom=1, width=320, height=320},
    scarletcathedral={path="Interface\\AddOns\\AzerothKart\\Assets\\Tracks\\ScarletCathedral\\Preview.tga",
        left=0, right=1, top=0, bottom=1, width=160, height=320},
    -- Warsong Gulch's preview shows the gulch from above, its covers on (1024 x 2048).
    warsonggulch={path="Interface\\AddOns\\AzerothKart\\Assets\\Tracks\\WarsongGulch\\Preview.tga",
        left=0, right=1, top=0, bottom=1, width=160, height=320},
}

-- The kart screen's handling bars: Physics' handling profiles, read through
-- Physics.GetHandling and never written. Each of a bar's six windows is 4%
-- of the Balanced kart's value, which fills four: Heavy's 4% more speed
-- fills five, Agile's 8% quicker acceleration all six. StatBars.tga
-- (scripts/build_stat_bars.py) is 512x64: row 0 the empty bar, row 1 the
-- full one, each 480x32 texels for a 240x16 bar; the full bar is drawn over
-- the empty one, cropped from the left to the kart's value.
Menu.STATS_PATH = "Interface\\AddOns\\AzerothKart\\Assets\\UI\\StatBars.tga"
Menu.KART_STATS = {
    {key="maxSpeed", label="Speed"},
    {key="accel", label="Acceleration"},
    {key="steerRate", label="Turning"},
    {key="brake", label="Braking"},
}
Menu.STAT_SEGMENTS, Menu.STAT_PAR, Menu.STAT_STEP = 6, 4, 0.04
Menu.STAT_WIDTH, Menu.STAT_HEIGHT, Menu.STAT_U = 240, 16, 480 / 512

-- The share of a bar a handling value fills against the Balanced kart's
-- (`par`): four windows of six at par, one more or fewer per 4%, never less
-- than half a window nor more than the bar. nil for a value it cannot read.
function Menu.statFill(value, par)
    if type(value) ~= "number" or type(par) ~= "number" or value ~= value or par ~= par or par <= 0 then
        return nil
    end
    local windows = Menu.STAT_PAR + (value / par - 1) / Menu.STAT_STEP
    return math.max(0.5, math.min(Menu.STAT_SEGMENTS, windows)) / Menu.STAT_SEGMENTS
end

-- The results window's celebration art (scripts/build_celebration_art.py):
-- a 512x256 atlas of a sunburst, gold, silver and bronze medals and a laurel
-- wreath, as {left, right, top, bottom} texture coordinates; and how many
-- confetti pieces fall (plain coloured squares).
Menu.CELEBRATION_PATH = "Interface\\AddOns\\AzerothKart\\Assets\\UI\\Celebration.tga"
Menu.CELEBRATION_COORDS = {rays={0, 0.5, 0, 1}, gold={0.5, 0.75, 0, 0.5}, silver={0.75, 1, 0, 0.5},
    bronze={0.5, 0.75, 0.5, 1}, wreath={0.75, 1, 0.5, 1}}
Menu.CONFETTI = 12

-- Use the once-latched local finish's exact copied placement; never guess
-- identity from equal totals or rerank an old finish using a later board cache.
function Menu.scorePlacement(result, trackId)
    if type(result) ~= "table" or result.saved ~= true then return nil end
    local place = result.placement
    if type(place) ~= "table" or place.scope ~= "known_board" then return nil end
    local rank, count = place.rank, place.knownPlayers
    if type(rank) ~= "number" or rank < 1 or rank % 1 ~= 0
        or type(count) ~= "number" or count < rank or count % 1 ~= 0 then return nil end
    local kind = "best"
    if rank == 1 then kind = count > 1 and "record" or "first"
    elseif rank <= 3 then kind = "top3"
    elseif rank <= 10 then kind = "top10" end
    return {rank=rank, count=count, shared=true, kind=kind}
end

-- The player's full name for display (their own row on a board, the
-- results' racers): read once through SoloRecords, kept for the session.
function Menu.PlayerName()
    local finish = UI.scoreResult
    if type(finish) == "table" and type(finish.playerName) == "string" then return finish.playerName end
    local backend = AK.SoloRecords
    if Menu.playerName == nil and type(backend) == "table" and type(backend.PlayerName) == "function" then
        local ok, name = pcall(backend.PlayerName)
        if ok and type(name) == "string" then Menu.playerName = name end
    end
    return Menu.playerName
end

-- The racers of a live two-player race as Presentation.standings reads them,
-- into the two tables given (reused: the HUD asks every frame): the local
-- race, and the friend's latest reported observation, placed where their
-- kart is drawn. Returns them, or nil outside a live race. Display only.
function Menu.liveRacers(mine, theirs)
    local live, race, laps, state, track = UI.liveView, UI.race, UI.laps, UI.state, UI.track
    if not (UI.multiplayer and type(live) == "table" and race and laps and state and track) then return nil end
    mine.out = race.status == "stopped" or race.status == "interrupted"
    mine.finishTicks = race.status == "finished" and race.totalTicks or nil
    mine.progress = Presentation.raceProgress(track, laps.completedLaps, laps.checkpoints.passed, state.x, state.y)
    local remote = live.remote
    theirs.finishTicks, theirs.progress, theirs.out = nil, nil, false
    if type(remote) == "table" then
        theirs.finishTicks = remote.status == "finished" and remote.tick or nil
        theirs.out = remote.status == "stopped" or remote.status == "interrupted"
        theirs.progress = Presentation.raceProgress(track, remote.completedLaps, remote.passed,
            UI.opponentWorldX or remote.x, UI.opponentWorldY or remote.y)
    end
    if not theirs.finishTicks and (live.reason == "peer_stopped" or live.reason == "peer_timeout") then
        theirs.out = true
    end
    return mine, theirs
end

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
    position={"Game48Font", "GameFontNormalHuge3Outline", "GameFontNormalHuge3", "GameFontNormalHuge"},
    banner={"Game42Font", "Game36Font", "GameFontNormalHuge3", "GameFontNormalHuge"},
}

local GOLD, WHITE, RED = {1, 0.82, 0}, {1, 1, 1}, {1, 0.35, 0.3}
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
    local rootWritable = db == nil or (type(db) == "table" and db.schemaVersion == 1)
    local raw = type(db) == "table" and db.preferences
    if type(raw) ~= "table" then return prefs, rootWritable end
    local writable = rootWritable and not (type(raw.version) == "number" and raw.version > 1)
    if type(raw.track) == "string" and Courses and Courses.available(raw.track) then prefs.track = raw.track end
    if type(raw.kart) == "string" and Presentation.KART_SPRITES[raw.kart] then prefs.kart = raw.kart end
    if type(raw.effects) == "boolean" then prefs.effects = raw.effects end
    if type(raw.devInfo) == "boolean" then prefs.devInfo = raw.devInfo end
    if type(raw.sound) == "boolean" then prefs.sound = raw.sound end
    if type(raw.outline) == "boolean" then prefs.outline = raw.outline end -- off unless saved on
    for _,scale in ipairs(Menu.SCALES) do
        if raw.scale == scale then prefs.scale = scale end
    end
    return prefs, writable
end

-- The race HUD's big lines for a race (or none yet): lap, time and best. A
-- sprint (one run to the last gate) shows SPRINT and its gates instead.
function Menu.raceLines(race, laps)
    local track = UI and UI.track
    local target = race and race.targetLaps or (track and track.laps) or 3
    local gates = track and track.gates and #track.gates or 0
    local function gateLine(progress)
        return ("GATES %d/%d"):format(progress and progress.passed or 0, gates)
    end
    if not race or race.status == "countdown" then
        if target == 1 then return "SPRINT", Menu.formatTime(0, 1), gateLine(nil) end
        return ("LAP 1/%d"):format(target), Menu.formatTime(0, 1),
            "BEST " .. Menu.formatTime(laps and laps.bestLapTicks and laps.bestLapTicks * Physics.FIXED_DT)
    end
    local completed = race.laps.completedLaps
    local seconds = race.totalTicks * Physics.FIXED_DT
    if target == 1 then
        local passed = race.status == "finished" and {passed=gates} or race.laps.checkpoints
        return race.status == "finished" and "FINISHED" or "SPRINT",
            Menu.formatTime(seconds, race.status == "running" and 1 or 2), gateLine(passed)
    end
    local lap = race.status == "finished" and "FINISHED" or
        ("LAP %d/%d"):format(math.min(completed + 1, target), target)
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
    coordinating="Coordinating the start. Keep this window open.",
    racing="Race running. The other kart is an observation; karts do not collide.",
    finishing="Your run finished. Waiting briefly for the other kart's finish observation.",
    postrace="Same players are here. The host can play again or choose another map.",
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
    completed_unverified="Both finish observations received. No agreed winner is calculated.",
    peer_stopped="Your friend ended their run.",
    peer_silent="No recent race update from your friend. Start again with a fresh code.",
    peer_stalled="Your friend's race stopped progressing. Start again with a fresh code.",
}
local CLOCK_PHASES = {
    calibrating="Measuring start timing. Keep this window open.",
    preparing="Preparing the coordinated start. Keep this window open.",
    committing="Confirming the coordinated start. Keep this window open.",
    armed="Start armed. Hold W/Up on the starting grid for GO.",
    launched="Starting the race...",
    closed="Start coordination ended. Use a fresh code to try again.",
}
local PENDING = {INVITE="Sending invite", JOIN="Joining", READY="Sending ready", START="Starting", CANCEL="Leaving"}

function Menu.lobbyPresentation(view)
    local copy = {available=false, title="Coming soon", status="Not connected",
        host=false, join=false, ready=false, start=false, leave=false, readyLabel="Ready",
        you="Not ready", friend="Open slot", friendReady=""}
    if type(view) ~= "table" or (view.phase ~= "closed" and not PHASES[view.phase]) then return copy end
    local peer = type(view.peer) == "string" and view.peer ~= "" and view.peer or "your friend"
    copy.available = true
    copy.title = view.role == "host" and "Hosting" or view.role == "guest" and "Joining" or "Race a friend"
    if view.phase == "closed" then
        local reason = REASONS[view.reason] or "The session ended. Use a fresh code to try again."
        copy.status = reason:find("%%s") and reason:format(peer) or reason
    else
        local status = PHASES[view.phase]
        copy.status = status:find("%%s") and status:format(peer) or status
        if view.pendingKind and PENDING[view.pendingKind] then
            copy.status = ("%s... (try %d of 3)"):format(PENDING[view.pendingKind], math.max(1, view.pendingAttempts or 1))
        end
        if view.phase == "coordinating" and type(view.clock) == "table" then
            copy.status = CLOCK_PHASES[view.clock.phase] or PHASES.coordinating
        end
    end
    copy.host, copy.listen, copy.join = view.canHost == true or view.canInvite == true,
        view.canListen == true, view.canJoin == true
    copy.ready, copy.start, copy.leave = view.canSetReady == true,
        (view.coordinated and view.canPrepareStart == true) or (not view.coordinated and view.canStart == true),
        view.canLeave == true
    copy.readyLabel = view.phase == "postrace" and "Play Again" or (view.localReady and "Not ready" or "Ready")
    if view.phase == "postrace" then
        copy.ready = view.canRematch == true
        copy.status = view.role == "host" and
            "Choose a map, then Play Again. Your friend will receive the new invite." or
            "Waiting for the host to choose the next race. The same players remain together."
    end
    copy.you = view.localReady and (view.localReadyConfirmed and "Ready" or "Ready (sending)") or "Not ready"
    local joined = view.phase == "lobby" or view.phase == "starting" or view.phase == "coordinating"
        or view.phase == "racing" or view.phase == "finishing" or view.phase == "postrace"
    copy.friend = joined and peer or ((view.phase == "closed" or not view.peer) and "Open slot" or peer .. " (not joined)")
    copy.friendReady = joined and (view.peerReady and "Ready" or "Not ready") or ""
    if view.phase == "postrace" then
        copy.host,copy.listen,copy.join,copy.start = false,false,false,false
        copy.you,copy.friendReady = "Not ready","Not ready"
    end
    return copy
end

-- ---------------------------------------------------------------------------
-- Sounds: the client's own interface sound kits (Mainline SoundKitConstants),
-- played only when present and never when the player switches sounds off.

Menu.SOUNDS = {click="IG_MAINMENU_OPTION", open="IG_MAINMENU_OPEN", checkOn="IG_MAINMENU_OPTION_CHECKBOX_ON",
    checkOff="IG_MAINMENU_OPTION_CHECKBOX_OFF", tick="UI_BATTLEGROUND_COUNTDOWN_TIMER",
    go="UI_BATTLEGROUND_COUNTDOWN_FINISHED", finish="LFG_REWARDS",
    -- The results window's celebrations: a top-ten board place, and a top
    -- three, #1 or a race won (in place of the finish fanfare).
    top10="IG_QUEST_LIST_COMPLETE", top3="UI_EPICLOOT_TOAST"}

function Menu.Play(name)
    if Menu.prefs and Menu.prefs.sound == false then return end
    local kit = type(SOUNDKIT) == "table" and SOUNDKIT[Menu.SOUNDS[name] or ""]
    if kit and type(PlaySound) == "function" then pcall(PlaySound, kit) end
end

-- The countdown's 3, 2, 1 tick and GO sounds as the cue changes.
function Menu.OnCue(cue)
    if Menu.disabled then return end
    if cue == "GO" then Menu.Play("go")
    elseif cue == "3" or cue == "2" or cue == "1" then Menu.Play("tick") end
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
    if type(AzerothKartDB) ~= "table" or AzerothKartDB.schemaVersion ~= 1 or not Menu.prefsWritable then return end
    local record, old = {}, AzerothKartDB.preferences
    -- Recheck at write time: another component may have replaced the child
    -- since Menu.Create captured its initial writable flag.
    if type(old) == "table" and type(old.version) == "number" and old.version > 1 then return end
    if type(old) == "table" then
        for key,value in pairs(old) do record[key] = value end -- keep fields this version does not know
    end
    local p = Menu.prefs
    record.version, record.track, record.kart, record.effects = 1, p.track, p.kart, p.effects
    record.devInfo, record.scale, record.sound = p.devInfo, p.scale, p.sound
    record.outline = p.outline
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
    local box = panel(root, DIALOG, 300, 314, "TOP", 0, -124)
    Menu.screens.home = box
    box:Hide()
    local entries = {
        {"Single Player", function() Menu.Show("tracks") end},
        {"Multiplayer |cffff8c26(soon)|r", function() Menu.Show("multiplayer") end},
        {"Garage", function() Menu.Show("garage") end},
        {"How to Play", function() Menu.Show("help") end},
        {"Settings", function() Menu.Show("settings") end},
        {"Highscores", function() Menu.Show("highscores") end},
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

-- A bounded saved-record view. Browsing never selects a driving track, writes
-- saved data, or publishes anything. The backend is queried only by deliberate
-- open/track/page actions; Sync/OnUpdate do not refresh or sort this board.
local THREE_LAP_RULE = "Fastest completed three-lap totals for the current rules"
local SPRINT_RULE = "Fastest completed sprints, one run each, for the current rules"
local function buildHighscores()
    local box = screenBox("highscores", "Saved Highscores", 780, 570)
    local view = Menu.view
    view.highscoreScope = newText(box, FONT.gray, "TOP", 0, -65, "Local cache | Global publishing pending")
    view.highscoreTrack = newButton(box, "Track", 420, 30, "TOP", 0, -91, function()
        -- The next board, past any course still coming soon (it has none).
        local index = Menu.highscoreTrackIndex or 1
        for _=1,#Menu.TRACKS do
            index = index % #Menu.TRACKS + 1
            local course = Courses and Courses.get(Menu.TRACKS[index].id)
            if not (course and course.soon) then break end
        end
        Menu.highscoreTrackIndex = index
        Menu.highscorePage = 1
        refresh.highscores()
    end)
    view.highscoreRule = newText(box, FONT.graySmall, "TOPLEFT", 38, -140, THREE_LAP_RULE)
    newText(box, FONT.normal, "TOPLEFT", 38, -170, "Rank")
    newText(box, FONT.normal, "TOPLEFT", 96, -170, "Name")
    newText(box, FONT.normal, "TOPLEFT", 422, -170, "Total")
    newText(box, FONT.normal, "TOPLEFT", 548, -170, "Date UTC")
    view.highscoreRows = {}
    for index=1,10 do
        local row = {}
        local y = -199 - (index - 1) * 23
        row.rank = newText(box, FONT.white, "TOPLEFT", 38, y, "")
        row.name = wrap(newText(box, FONT.white, "TOPLEFT", 96, y, ""), 306)
        call(row.name, "SetWordWrap", false)
        call(row.name, "SetMaxLines", 1)
        row.total = newText(box, FONT.white, "TOPLEFT", 422, y, "")
        row.date = newText(box, FONT.white, "TOPLEFT", 548, y, "")
        view.highscoreRows[index] = row
    end
    view.highscoreEmpty = newText(box, FONT.gray, "TOP", 0, -215, "")
    view.highscoreStatus = wrap(newText(box, FONT.graySmall, "BOTTOM", 0, 108, ""), 700, "CENTER")
    call(view.highscoreStatus, "SetMaxLines", 2)
    view.highscorePage = newText(box, FONT.normal, "BOTTOM", 0, 72, "Page 1 / 1")
    view.highscorePrevious = newButton(box, "Previous", 130, 28, "BOTTOMLEFT", 170, 66, function()
        Menu.highscorePage = math.max(1, (Menu.highscorePage or 1) - 1)
        refresh.highscores()
    end)
    view.highscoreNext = newButton(box, "Next", 130, 28, "BOTTOMRIGHT", -170, 66, function()
        Menu.highscorePage = (Menu.highscorePage or 1) + 1
        refresh.highscores()
    end)
    newButton(box, "Back", 150, 30, "BOTTOMLEFT", 30, 22, function() Menu.Show("home") end)
    refresh.highscores = function()
        local index = Menu.highscoreTrackIndex or 1
        local track = Menu.TRACKS[index] or Menu.TRACKS[1]
        local backend = AK.SoloRecords
        local snapshot
        if type(backend) == "table" and type(backend.GetView) == "function" then
            local ok, result = pcall(backend.GetView, track.id)
            if ok and type(result) == "table" then snapshot = result end
        end
        local me = Menu.PlayerName()
        local rows = snapshot and type(snapshot.rows) == "table" and snapshot.rows or {}
        local pages = math.max(1, math.ceil(#rows / 10))
        if Menu.highscoreFindSelf then
            -- Opened from the results: the page with the player's own row.
            Menu.highscoreFindSelf = nil
            for rank,row in ipairs(rows) do
                if type(row) == "table" and me and row.playerName == me then
                    Menu.highscorePage = math.ceil(rank / 10)
                    break
                end
            end
        end
        local page = math.max(1, math.min(Menu.highscorePage or 1, pages))
        Menu.highscorePage = page
        view.highscoreTrack:SetText("Track: " .. track.name)
        -- A sprint's board (lap count 1) holds one-run times, not three-lap totals.
        local context = snapshot and type(snapshot.context) == "table" and snapshot.context
        view.highscoreRule:SetText(context and context.lapCount == 1 and SPRINT_RULE or THREE_LAP_RULE)
        view.highscoreScope:SetText(snapshot and snapshot.scope=="community"
            and "Shared community scores | "..tostring(snapshot.publication or "Connecting")
            or "Local cache | Global publishing pending")
        view.highscorePage:SetText(("Page %d / %d"):format(page, pages))
        setEnabled(view.highscorePrevious, page > 1)
        setEnabled(view.highscoreNext, page < pages)
        view.highscoreEmpty:SetText(not snapshot and "Saved records unavailable." or
            (#rows == 0 and snapshot.problem and "Saved records cannot be displayed in this build." or
            (#rows == 0 and "No completed solo records for this track yet." or "")))
        local status = snapshot and snapshot.lastResult
        local note = type(status) == "table" and type(status.message) == "string" and status.message or ""
        if snapshot and snapshot.scope=="community" then
            note=("%d connected | %d queued updates | Scores reported by players")
                :format(snapshot.connected or 0,snapshot.queued or 0)
        end
        if snapshot and snapshot.writable == false then note = "Saved records are read-only in this build." end
        view.highscoreStatus:SetText(note)
        for slot,line in ipairs(view.highscoreRows) do
            local rank = (page - 1) * 10 + slot
            local row = rows[rank]
            if type(row) == "table" then
                line.rank:SetText(tostring(rank))
                local name = type(row.playerName) == "string" and row.playerName or "Unknown player"
                line.name:SetText(name:gsub("|", "||"))
                -- The player's own row in gold.
                local own = me ~= nil and row.playerName == me
                for _,cell in ipairs({line.rank, line.name, line.total, line.date}) do
                    color(cell, own and GOLD or WHITE)
                end
                local total, date = "--", "--"
                if type(backend.FormatTime) == "function" then
                    local ok, text = pcall(backend.FormatTime, row.totalTicks)
                    if ok and type(text) == "string" then total = text end
                end
                if type(backend.FormatDate) == "function" then
                    local ok, text = pcall(backend.FormatDate, row.finishedAt)
                    if ok and type(text) == "string" then date = text end
                end
                line.total:SetText(total)
                line.date:SetText(date)
            else
                line.rank:SetText(""); line.name:SetText(""); line.total:SetText(""); line.date:SetText("")
            end
        end
    end
end

function Menu.OnScoresChanged()
    if Menu.screen=="highscores" and refresh.highscores then refresh.highscores() end
end

-- From the results: the run's own board, at the page with the player's row.
function Menu.ShowBoard(trackId)
    for index,track in ipairs(Menu.TRACKS) do
        if track.id == trackId then Menu.highscoreTrackIndex = index end
    end
    Menu.highscorePage, Menu.highscoreFindSelf = 1, true
    UI.DismissSummary()
    Menu.Show("highscores")
end

-- The list: each cup's heading, its tracks (Menu.TRACKS order), then its
-- coming-soon entries (Courses.LIST), disabled.
function Menu.trackRows()
    local rows = {}
    for _,cup in ipairs(Courses and Courses.CUPS or {{id="proving", name="Proving Grounds"}}) do
        rows[#rows + 1] = {heading=cup.name}
        for _,track in ipairs(Menu.TRACKS) do
            local course = Courses and Courses.get(track.id)
            if (course and course.cup or "proving") == cup.id and not (course and course.soon) then
                rows[#rows + 1] = {track=track}
            end
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
    -- Four cups: a 24-unit heading and a 32-unit row step keep the list
    -- clear of the Back button.
    local y = -78
    for _,row in ipairs(Menu.trackRows()) do
        if row.heading then
            color(newText(box, FONT.normal, "TOPLEFT", 38, y - 5, row.heading), GOLD)
            y = y - 24
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
            y = y - 32
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
-- A winged kart beats its wings for four of them and glides for two, so both
-- of its race poses show.
local SPIN = 2 * math.pi / 6
Menu.STAGE_GLIDE = {from = 4, every = 6}
local function spin(elapsed)
    local view = Menu.view
    local sprite = view.stageSprite
    if not sprite or not view.stageReady then return end
    view.stageHeading = (view.stageHeading + (elapsed or 0) * SPIN) % (2 * math.pi)
    view.stageTime = ((view.stageTime or 0) + (elapsed or 0)) % Menu.STAGE_GLIDE.every
    if sprite.frames then
        local frame = Presentation.kartFrame(sprite, view.stageHeading)
        local phase = Presentation.wingPhase(sprite, view.stageTime, view.stageTime >= Menu.STAGE_GLIDE.from)
        if frame ~= view.stageFrame or phase ~= view.stagePhase then
            view.stageFrame, view.stagePhase = frame, phase
            view.stage:SetTexCoord(Presentation.kartFrameCoords(sprite, frame, phase))
        end
    else view.stage:SetRotation(view.stageHeading - math.pi / 2) end
end

local function showStage(sprite)
    local view = Menu.view
    if view.stageSprite == sprite then return end
    view.stageSprite, view.stageFrame, view.stagePhase, view.stageHeading = sprite, nil, nil, -math.pi / 4
    view.stageTime = 0
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

-- The four handling bars for a profile: each loads the bars' picture once
-- (a failed load is not retried), then shows the full bar over the empty one
-- cropped to the kart's share. False when the bars cannot be shown.
local function showStats(bars, profile)
    local view = Menu.view
    if view.statsReady == nil then
        view.statsReady = true
        for _,bar in ipairs(bars) do
            for _,region in ipairs({bar.empty, bar.fill}) do
                local ok, loaded = call(region, "SetTexture", Menu.STATS_PATH)
                view.statsReady = view.statsReady and ok and loaded == true
            end
            call(bar.empty, "SetTexCoord", 0, Menu.STAT_U, 0, 0.5)
        end
    end
    local par = Physics.GetHandling(nil)                     -- the Balanced profile
    local shown = view.statsReady and profile ~= nil and par ~= nil
    for _,bar in ipairs(bars) do
        local share = shown and Menu.statFill(profile[bar.stat.key], par[bar.stat.key]) or nil
        if shown and not share then shown = false end
        bar.share = share
    end
    for _,bar in ipairs(bars) do
        setShown(bar.label, shown)
        setShown(bar.empty, shown)
        setShown(bar.fill, shown)
        if shown then
            bar.fill:SetSize(Menu.STAT_WIDTH * bar.share, Menu.STAT_HEIGHT)
            call(bar.fill, "SetTexCoord", 0, Menu.STAT_U * bar.share, 0.5, 1)
        end
    end
    return shown
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
    -- The handling profile's name over its four bars; if the bars' picture
    -- cannot load, the line tells the tradeoffs in words instead.
    local handling = wrap(newText(box, FONT.normal, "TOPLEFT", 420, -210, ""), 330)
    Menu.view.kartHandling = handling
    local handlingCopy = {
        balanced="Balanced | Even launch, braking and cornering.",
        heavy="Heavy | Faster cruise and stronger brakes; slower launch and wider turns.",
        agile="Agile | Quicker launch and turns; lower cruising speed and gentler brakes.",
    }
    local bars = {}
    for index,stat in ipairs(Menu.KART_STATS) do
        local y = -230 - (index - 1) * 22
        local empty = newTexture(box, "ARTWORK")
        empty:SetSize(Menu.STAT_WIDTH, Menu.STAT_HEIGHT)
        empty:SetPoint("TOPLEFT", box, "TOPLEFT", 750 - Menu.STAT_WIDTH, y)
        local fill = newTexture(box, "OVERLAY")
        fill:SetPoint("TOPLEFT", empty, "TOPLEFT", 0, 0)
        bars[index] = {stat=stat, empty=empty, fill=fill,
            label=newText(box, FONT.normal, "TOPLEFT", 420, y - 2, stat.label)}
    end
    Menu.view.statBars = bars
    local glow = newTexture(box, "ARTWORK")
    glow:SetColorTexture(1, 0.82, 0, 0.30)
    local buttons = {}
    for index,id in ipairs(order) do
        local column, row = (index - 1) % 2, math.floor((index - 1) / 2)
        buttons[id] = newButton(box, Presentation.KART_SPRITES[id].name, 160, 28, "TOPLEFT",
            420 + column * 172, -330 - row * 38, function() Menu.ChooseKart(id) end)
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
        local profile = Physics.GetHandling(UI.kartId)
        if showStats(bars, profile) then handling:SetText("Handling: " .. profile.name)
        else handling:SetText(profile and handlingCopy[profile.id] or "Handling unavailable") end
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

-- The bridge returns copied snapshots. Navigation and display never consume a
-- GO ticket, change readiness or call the simulation directly.
local function sessionView()
    local bridge = Menu.bridge
    if not bridge or type(bridge.view) ~= "function" then return nil end
    local ok, copied = pcall(bridge.view)
    return ok and type(copied) == "table" and copied or nil
end

local function sessionCommands()
    return Menu.bridge and type(Menu.bridge.action) == "function"
end

local function releaseLobbyFocus()
    for _,key in ipairs({"peerName", "sessionCode"}) do call(Menu.view[key], "ClearFocus") end
end

local ACTION_ERRORS = {
    busy="A session or final notice is still active. Leave it and wait a moment.",
    inactive="This session has ended. Use a fresh code to try again.",
    combat="Leave combat before joining or readying a race.",
    chat_focus="Finish typing or close chat, then try again.",
    text_focus="Finish typing or close chat, then try again.",
    focus="Focus the WoW window, then try again.",
    focus_lost="Focus the WoW window, then try again.",
    window_focus="Focus the WoW window, then try again.",
    window_hidden="Open Azeroth Kart before joining a race.",
    local_drive="Stop your current run before opening a multiplayer session.",
    not_armed="Click Ready before starting the coordinated race.",
    capabilities="The required Forever logged-whisper API is unavailable.",
    prefix_registration="Forever could not register the race channel.",
    event_registration="Forever could not enable race messages.",
    update_registration="Forever could not enable the race update callback.",
    reused_session="That code was already used. Both players must enter a fresh six-character code.",
    session_limit="This addon session has reached its session limit. Reload before using a fresh code.",
    invalid_argument="Check the complete character name and six uppercase letters or digits in the code.",
    invalid_options="Check the complete character name and six uppercase letters or digits in the code.",
    invalid_phase="The session changed. Check its status and try the available action.",
    incompatible="Both players need the same Azeroth Kart build and supported track.",
    track_load="The offered track could not load. Leave and try a supported track.",
    track_unavailable="The offered track could not load. Leave and try a supported track.",
    track="That track is unavailable. Leave and choose a finished track.",
    input_unavailable="Race controls are unavailable. Leave and try again.",
    input_api="Race controls are unavailable in this client. Leave and try again.",
    send_failed="Forever refused the send. Leave and try again with a fresh code.",
    send_unknown="Forever could not confirm the send. Leave and try again with a fresh code.",
    send_throttled="Forever limited the send. Leave and try again with a fresh code.",
    postrace="Wait for this race to finish before choosing the next race.",
    host_only="The host chooses the next race and map.",
    room="This multiplayer room has ended. Leave Multiplayer to return to the main menu.",
}

local function lobbyAction(action, trackId)
    local session, view = sessionView(), Menu.view
    local copy = Menu.lobbyPresentation(session)
    if action == "ready" and session and session.phase == "postrace" then action = "rematch" end
    local allowed = action == "start" and copy.start or action == "ready" and copy.ready
        or action == "host" and copy.host or action == "listen" and copy.listen
        or action == "join" and copy.join or action == "leave" and (copy.leave or UI.multiplayer)
        or action == "rematch" and session and session.canRematch == true
        or action == "return_lobby" and session and type(session.room) == "table"
    if not sessionCommands() or not allowed then return false end
    releaseLobbyFocus()
    local ok, accepted, reason
    if action == "host" or action == "listen" then
        -- A Forever name includes its surname, spaces, punctuation and UTF-8.
        -- There are no realm names. Only trim accidental outer spaces.
        local peer = view.peerName:GetText()
        local code = view.sessionCode:GetText()
        peer = type(peer) == "string" and peer:match("^ *(.-) *$") or ""
        if peer == "" or #peer > 96 or peer:find("[%z\001-\031\127|]") then
            toast("multiplayer", "Enter your friend's complete Forever character name, including the surname.")
            return false
        end
        if type(code) ~= "string" or #code ~= 6 or code:find("[^A-Z0-9]") then
            toast("multiplayer", "Both players: enter the same fresh code of six uppercase letters or digits.")
            return false
        end
        if action == "host" then ok, accepted, reason = pcall(Menu.bridge.action, action, peer, code, Menu.lobbyTrackId)
        else ok, accepted, reason = pcall(Menu.bridge.action, action, peer, code) end
    elseif action == "rematch" then
        ok, accepted, reason = pcall(Menu.bridge.action, action, trackId or Menu.lobbyTrackId)
    elseif action == "ready" then
        ok, accepted, reason = pcall(Menu.bridge.action, action, not session.localReady)
    else ok, accepted, reason = pcall(Menu.bridge.action, action) end
    if ok and accepted == true then toast("multiplayer", "")
    else toast("multiplayer", ACTION_ERRORS[reason] or "That action could not complete. Check the session status and try again.") end
    if refresh.multiplayer then refresh.multiplayer() end
    return ok and accepted == true
end

-- Explicit results navigation keeps the same multiplayer room. Only Leave
-- may return it to the solo menus; no results action calls the solo loop.
function Menu.ReturnLobby()
    if not UI.multiplayer then return false end
    local session = sessionView()
    local room = session and type(session.room) == "table" and session.room
    if not room or not lobbyAction("return_lobby") then return false end
    if Courses.multiplayer(room.trackId) then Menu.lobbyTrackId = room.trackId end
    UI.DismissSummary()
    Menu.Show("multiplayer")
    return true
end

function Menu.ReplayResults()
    if not UI.multiplayer then return false end
    local session = sessionView()
    local room = session and type(session.room) == "table" and session.room
    if not room then return false end
    local role = session.role or room.role
    if role == "host" then
        if not session.canRematch or not lobbyAction("rematch", room.trackId) then return false end
    elseif role == "guest" then
        if session.canJoin and not lobbyAction("join") then return false end
    else return false end
    return Menu.ReturnLobby()
end

local function buildMultiplayer()
    local box = screenBox("multiplayer", "Multiplayer")
    local view = Menu.view
    local badge = newText(box, FONT.large, "TOP", 0, -66, "COMING SOON")
    color(badge, SOON)
    wrap(newText(box, FONT.white, "TOP", 0, -96,
        "Experimental two-player racing. Karts do not collide; results have no agreed winner. " ..
        "Both players need this build. The guest listens first; the host then sends the invite."), 700, "CENTER")
    newText(box, FONT.small, "TOPLEFT", 44, -150, "Friend's full Forever character name")
    local function input(y, maxLetters)
        local field = newFrame("EditBox", box, "InputBoxTemplate") or newFrame("EditBox", box)
        field:SetSize(292, 30)
        field:SetPoint("TOPLEFT", box, "TOPLEFT", 48, y)
        call(field, "SetFontObject", _G.GameFontHighlight or _G.GameFontNormal)
        call(field, "SetAutoFocus", false)
        call(field, "SetMaxLetters", maxLetters)
        field:SetText("")
        field:SetScript("OnEnterPressed", function(self) call(self, "ClearFocus") end)
        field:SetScript("OnEscapePressed", function(self) call(self, "ClearFocus") end)
        return field
    end
    view.peerName = input(-173, 96)
    newText(box, FONT.small, "TOPLEFT", 44, -215, "Shared fresh code (6 uppercase letters or digits)")
    view.sessionCode = input(-236, 6)
    wrap(newText(box, FONT.graySmall, "TOPLEFT", 44, -270,
        "Use a new code every attempt; it is a public room label."), 296)
    Menu.lobbyTrackId = "mirage_raceway"
    view.lobbyTrackChoice = newButton(box, "Track: Mirage Raceway", 300, 28, "TOPLEFT", 40, -296, function()
        local session = sessionView()
        if not sessionCommands() or not session or not (session.canHost or session.canChangeMap) then return end
        Menu.lobbyTrackId = Courses.next(Menu.lobbyTrackId,true)
        refresh.multiplayer()
    end)
    view.host = newButton(box, "Host / Invite", 146, 34, "TOPLEFT", 40, -338,
        function() lobbyAction("host") end, true)
    view.listen = newButton(box, "Listen for Host", 146, 34, "TOPLEFT", 194, -338,
        function() lobbyAction("listen") end, true)
    view.join = newButton(box, "Join Received Invite", 300, 34, "TOPLEFT", 40, -382,
        function() lobbyAction("join") end, true)
    wrap(newText(box, FONT.small, "TOPLEFT", 44, -430,
        "Guest: Listen, then Join the received invite. Both: click Ready. Host: click Start. " ..
        "Ready permits race controls at GO. Leave ends the session; no automatic reconnect."), 296)
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
    view.ready = newButton(card, "Ready", 100, 26, "BOTTOMLEFT", 16, 16, function() lobbyAction("ready") end)
    view.start = newButton(card, "Start", 100, 26, "BOTTOM", 0, 16, function() lobbyAction("start") end)
    view.leave = newButton(card, "Leave", 100, 26, "BOTTOMRIGHT", -16, 16, function() lobbyAction("leave") end)
    newButton(box, "Back", 150, 30, "BOTTOMLEFT", 30, 26, function()
        if UI.multiplayer and not lobbyAction("leave") then return end
        Menu.Show("home")
    end)
    refresh.multiplayer = function()
        local session = sessionView()
        local copy, commands = Menu.lobbyPresentation(session), sessionCommands()
        badge:SetText(commands and "EXPERIMENTAL: TWO PLAYERS" or "COMING SOON")
        view.lobbyTitle:SetText(copy.available and copy.title or "Lobby preview")
        view.youKart:SetText(kartName())
        view.youReady:SetText(copy.you)
        view.friend:SetText(copy.friend)
        view.friendReady:SetText(copy.friendReady)
        local room = session and type(session.room) == "table" and session.room
        if room then
            local peer = session.peer or room.peer
            if type(peer) == "string" and view.peerName:GetText() ~= peer then view.peerName:SetText(peer) end
            if type(session.session) == "string" and view.sessionCode:GetText() ~= session.session then
                view.sessionCode:SetText(session.session)
            end
        end
        local offered = session and type(session.offer) == "table" and session.offer.trackId
        local staged = session and session.phase == "postrace" and session.canChangeMap == true
        local chosen = trackInfo(staged and Menu.lobbyTrackId or offered or (room and room.trackId) or Menu.lobbyTrackId)
        local course = chosen and Courses.get(chosen.id)
        local sprint = course and course.geometry == "dungeon"
        -- Read catalogue/offer metadata only; a lobby refresh never selects
        -- or constructs geometry. A sprint is one ordered run, not three laps.
        if offered and not staged and session.offer.laps then sprint = session.offer.laps == 1 end
        view.lobbyTrack:SetText((staged and "Next choice: %s    %s" or "Track: %s    %s"):
            format(chosen and chosen.name or "Unavailable", sprint and "Sprint: 1 run" or "Laps: 3"))
        view.lobbyTrackChoice:SetText("Track: " .. (trackInfo(Menu.lobbyTrackId) or Menu.TRACKS[1]).name)
        view.lobbyStatus:SetText(copy.available and copy.status or "Not connected. Hosting and joining are unavailable.")
        view.ready:SetText(copy.readyLabel)
        for _,key in ipairs({"host", "listen", "join", "ready", "start", "leave"}) do
            setEnabled(view[key], commands and copy[key] == true)
        end
        local free = commands and session and (session.canHost or session.canListen)
        setEnabled(view.lobbyTrackChoice, commands and session and (session.canHost or session.canChangeMap))
        for _,field in ipairs({view.peerName, view.sessionCode}) do
            call(field, free and "Enable" or "Disable")
            if not free then call(field, "ClearFocus") end
        end
    end
    -- The shown lobby alone polls copied display state at 5 Hz. No simulation
    -- ticks, packets, widgets, chat messages or catch-up refresh burst here.
    local elapsedSinceRefresh = 0
    box:SetScript("OnUpdate", function(_, elapsed)
        if Menu.screen ~= "multiplayer" or not box:IsShown() then return end
        elapsedSinceRefresh = elapsedSinceRefresh + (elapsed or 0)
        if elapsedSinceRefresh >= 0.2 then elapsedSinceRefresh = 0; refresh.multiplayer() end
    end)
end

-- Additive {view, action} bridge; the legacy view-only form can still display
-- copied diagnostics, but never enables a command without an action handler.
function Menu.SetSessionBridge(bridge)
    Menu.bridge = type(bridge) == "table" and bridge or nil
    if Menu.view.homeButtons then
        Menu.view.homeButtons[2]:SetText(sessionCommands() and "Multiplayer |cffff8c26(experimental)|r" or
            "Multiplayer |cffff8c26(soon)|r")
    end
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
        "Biker, Gryphon Rider and Gyrocopter from the wc3c ITE project; the other karts are Blizzard's own, " ..
        "the Goblin Pod Racer from World of Warcraft. The Mirage scenery and the effects are original."),
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
    view.outline = check("Outline my kart", "A bright yellow line round your own kart, so you never lose it.", -226,
        function() Menu.SetOutline(not Menu.prefs.outline) end)
    view.sound = check("Sound effects", "Menu clicks, the countdown beeps and the finish fanfare.", -296,
        function() Menu.SetSound(not Menu.prefs.sound) end)
    view.devInfo = check("Show developer info", "Adds the timing line and the Print Probe button under the track.", -366,
        function() Menu.SetDevInfo(not Menu.prefs.devInfo) end)
    newButton(box, "Reset window position", 220, 28, "TOPLEFT", 60, -440, function() Menu.ResetPosition() end)
    newText(box, FONT.graySmall, "TOPLEFT", 296, -446, "Drag the window by its title bar to move it.")
    newText(box, FONT.graySmall, "BOTTOM", 0, 100, "Settings are saved for your account.")
    newButton(box, "Back", 150, 30, "BOTTOMLEFT", 30, 26, function() Menu.Show("home") end)
    refresh.settings = function()
        markSelected(sizes, glow, Menu.prefs.scale)
        for scale,button in pairs(sizes) do setEnabled(button, Menu.Fits(scale)) end
        call(view.effects, "SetChecked", Menu.prefs.effects)
        call(view.outline, "SetChecked", Menu.prefs.outline == true)
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

function Menu.SetOutline(enabled)
    Menu.prefs.outline = enabled == true
    if UI.SetKartOutline then UI.SetKartOutline(Menu.prefs.outline) end
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
    -- A two-player race's place, large in the bottom-right corner ("1st",
    -- "of 2" under it), from each racer's own progress (Menu.liveRacers).
    view.position = newText(overlay, FONT.position, "BOTTOMRIGHT", -18, 30, "")
    view.positionOf = newText(overlay, FONT.white, "BOTTOMRIGHT", -20, 14, "")
    for _,label in ipairs({view.position, view.positionOf}) do
        call(label, "SetShadowOffset", 2, -2)
        call(label, "SetShadowColor", 0, 0, 0, 1)
        label:Hide()
    end
    view.racerMine, view.racerTheirs = {}, {}
end

-- A place's colour: gold, silver, bronze, then white.
local PLACE_COLORS = {{1, 0.82, 0}, {0.82, 0.86, 0.92}, {0.86, 0.56, 0.32}}

-- The race HUD's place: shown in a live two-player race once it runs (not on
-- the grid), from the copied views; text set only when the place changes.
local function refreshPlace()
    local view = Menu.view
    if not view.position then return end
    local race, place, tied, estimated = UI.race
    if not UI.gridStaged and race then
        if race.status == "running" then
            local mine, theirs = Menu.liveRacers(view.racerMine, view.racerTheirs)
            place = mine and (Presentation.ahead(theirs, mine) and 2 or 1) or nil
            estimated = place ~= nil
        elseif UI.multiplayer and race.status == "finished" then
            local results = UI.multiplayerResults
            for _,row in ipairs(type(results) == "table" and results.rows or {}) do
                if row.localPlayer then place, tied = row.rank, row.tie end
            end
        end
    end
    local key = tostring(place) .. ":" .. tostring(tied) .. ":" .. tostring(estimated)
    if key == view.shownPlace then return end
    view.shownPlace = key
    if not place then
        view.position:Hide(); view.positionOf:Hide()
        return
    end
    view.position:SetText((tied and "=" or "") .. Presentation.ordinal(place))
    color(view.position, PLACE_COLORS[place] or WHITE)
    view.positionOf:SetText(estimated and "of 2 (est.)" or "of 2 (reported)")
    view.position:Show(); view.positionOf:Show()
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
-- and more ways out. Title, detail, hint, Restart and Close results keep their
-- text and behaviour. Over them, when there is something to celebrate (a new
-- personal best, above all one high on a shared board, or a two-player
-- race's place): a banner, a medal or wreath on a turning sunburst over the
-- dialog's top edge, falling confetti, and in a two-player race the racers in
-- their places. Everything is made here, once; showing results makes nothing.
local RESULT_HEIGHT, CELEBRATION_HEIGHT = 336, 420
local CONFETTI_COLORS = {{1, 0.82, 0.1}, {0.86, 0.12, 0.14}, {1, 1, 1}, {0.3, 0.78, 0.36}, {0.32, 0.6, 1},
    {1, 0.56, 0.12}}
-- The banner for each celebration, the art under it, its confetti and sound.
local CELEBRATIONS = {
    record={banner="NEW #1!", art="gold", rays=true, confetti=Menu.CONFETTI, sound="top3"},
    first={banner="FIRST ON THE BOARD!", art="gold", rays=true, confetti=Menu.CONFETTI, sound="top3"},
    top3={banner="TOP 3!", rays=true, confetti=Menu.CONFETTI, sound="top3"},
    top10={banner="TOP 10!", art="wreath", rays=true, confetti=8, sound="top10"},
    won={banner="1st PLACE!", art="gold", rays=true, confetti=Menu.CONFETTI, sound="top3"},
    second={banner="2nd PLACE", art="silver"},
    tied={banner="JOINT 1st PLACE", art="gold"},
    alone={banner="FINISHED!"},
    waiting={banner="FINISHED!"},
}

local function arrangeResults()
    local summary = UI.summary
    summary:SetSize(460, RESULT_HEIGHT)
    local level = (UI.canvas:GetFrameLevel() or 1) + 8 -- above the race overlay
    call(summary, "SetFrameLevel", level)
    for _,button in ipairs({UI.restartButton, UI.dismissSummaryButton}) do call(button, "SetFrameLevel", level + 1) end
    backdrop(summary, _G.BACKDROP_DARK_DIALOG_32_32 or DARK_DIALOG)
    local view = Menu.view
    view.resultFonts = {huge=fontName(FONT.huge), large=fontName(FONT.large)}
    view.resultLine = newText(summary, FONT.white, "TOP", 0, -60, "")
    local detail = fontName(FONT.largeWhite)
    if _G[detail] ~= nil then call(UI.summaryDetail, "SetFontObject", _G[detail]) end
    call(UI.summaryDetail, "SetSpacing", 4)
    view.resultLaps = newText(summary, FONT.white, "TOP", 0, -172, "")
    view.resultScore = wrap(newText(summary, FONT.graySmall, "TOP", 0, -196, ""), 404, "CENTER")
    call(view.resultScore, "SetMaxLines", 2)
    UI.summaryHint:ClearAllPoints()
    UI.summaryHint:SetPoint("BOTTOM", summary, "BOTTOM", 0, 92)
    UI.summaryHint:SetJustifyH("CENTER")
    color(UI.summaryHint, {0.62, 0.62, 0.62})
    -- The celebration: the sunburst behind the medal, the medal (or wreath,
    -- its rank written in it), the banner and its line.
    view.rays = newTexture(summary, "BORDER")          -- under the medal (ARTWORK)
    view.rays:SetSize(140, 140)
    view.rays:SetPoint("CENTER", summary, "TOP", 0, 14)
    view.medal = newTexture(summary, "ARTWORK")
    view.medal:SetSize(84, 84)
    view.medal:SetPoint("CENTER", summary, "TOP", 0, 14)
    view.medalRank = newText(summary, FONT.large, "CENTER", 0, 3, "", view.medal, "CENTER")
    color(view.medalRank, GOLD)
    view.banner = newText(summary, FONT.banner, "TOP", 0, -34, "")
    view.bannerSub = newText(summary, FONT.normal, "TOP", 0, -80, "")
    for _,label in ipairs({view.banner, view.medalRank}) do
        call(label, "SetShadowOffset", 2, -2)
        call(label, "SetShadowColor", 0, 0, 0, 1)
    end
    for _,piece in ipairs({view.rays, view.medal, view.medalRank, view.banner, view.bannerSub}) do piece:Hide() end
    -- The racers in their places (two-player races).
    view.standings = {}
    for index=1,2 do
        local y = -156 - (index - 1) * 24
        local row = {left=newText(summary, FONT.white, "TOPLEFT", 44, y, ""),
            right=newText(summary, FONT.white, "TOPRIGHT", -44, y, "")}
        row.right:SetJustifyH("RIGHT")
        row.left:Hide(); row.right:Hide()
        view.standings[index] = row
    end
    view.confetti = {}
    for index=1,Menu.CONFETTI do
        local piece = newTexture(summary, "OVERLAY")
        local rgb = CONFETTI_COLORS[(index - 1) % #CONFETTI_COLORS + 1]
        piece:SetColorTexture(rgb[1], rgb[2], rgb[3], 1)
        if index % 2 == 0 then piece:SetSize(5, 9) else piece:SetSize(7, 6) end
        piece:Hide()
        view.confetti[index] = piece
    end
    -- Ways out: Restart, the board, Close; then Kart, Track, Main Menu.
    UI.restartButton:ClearAllPoints()
    UI.restartButton:SetPoint("BOTTOMLEFT", summary, "BOTTOMLEFT", 28, 54)
    UI.restartButton:SetSize(128, 28)
    view.highscoresButton = newButton(summary, "Highscores", 128, 28, "BOTTOM", 0, 54,
        function() Menu.ShowBoard(UI.trackId) end)
    call(view.highscoresButton, "SetFrameLevel", level + 1)
    UI.dismissSummaryButton:ClearAllPoints()
    UI.dismissSummaryButton:SetPoint("BOTTOMRIGHT", summary, "BOTTOMRIGHT", -28, 54)
    UI.dismissSummaryButton:SetSize(128, 28)
    UI.restartButton:SetScript("OnClick", function()
        if UI.multiplayer then Menu.ReplayResults() else UI.Start() end
    end)
    local function leave(screen)
        return function()
            UI.DismissSummary()
            Menu.Show(screen)
        end
    end
    view.resultChangeKart = newButton(summary, "Change Kart", 128, 26, "BOTTOMLEFT", 28, 20, leave("karts"))
    view.resultChangeTrack = newButton(summary, "Change Track", 128, 26, "BOTTOM", 0, 20, function()
        if UI.multiplayer then Menu.ReturnLobby() else leave("tracks")() end
    end)
    view.resultHome = newButton(summary, "Main Menu", 128, 26, "BOTTOMRIGHT", -28, 20, function()
        if UI.multiplayer and not lobbyAction("leave") then return end
        UI.DismissSummary()
        Menu.Show("home")
    end)
    Menu.celebration = {}
    summary:SetScript("OnShow", function() Menu.OnResults() end)
    summary:SetScript("OnHide", function() Menu.barKey = nil; Menu.Sync() end)
    summary:SetScript("OnUpdate", function(_, elapsed) Menu.AnimateResults(elapsed) end)
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

-- The dialog's layouts: plain, or taller with the banner over it; with the
-- racers' rows in place of the run's detail in a two-player race. Rows, from
-- the top: {title, track and kart, detail or first racer, laps, note}.
local RESULT_ROWS = {
    plain={-26, -60, -86, -172, -196}, plainRacers={-26, -60, -92, -148, -172},
    banner={-104, -128, -152, -234, -256}, bannerRacers={-104, -128, -156, -210, -234},
}
local function layoutResults(banner, racers)
    local summary, view = UI.summary, Menu.view
    local rows = RESULT_ROWS[(banner and "banner" or "plain") .. (racers and "Racers" or "")]
    local function place(region, y, anchor, x)
        region:ClearAllPoints()
        region:SetPoint(anchor or "TOP", summary, anchor or "TOP", x or 0, y)
    end
    summary:SetSize(460, banner and CELEBRATION_HEIGHT or RESULT_HEIGHT)
    -- Lower, with the banner: the medal over the top edge stays clear of the
    -- window's header.
    summary:ClearAllPoints()
    summary:SetPoint("CENTER", UI.canvas, "CENTER", 0, banner and -14 or 0)
    local font = _G[banner and view.resultFonts.large or view.resultFonts.huge]
    if font ~= nil then call(UI.summaryTitle, "SetFontObject", font) end
    UI.summaryTitle:SetJustifyH("CENTER")
    place(UI.summaryTitle, rows[1])
    place(view.resultLine, rows[2])
    place(UI.summaryDetail, rows[3])
    UI.summaryDetail:SetJustifyH("CENTER")
    setShown(UI.summaryDetail, not racers)
    for index,row in ipairs(view.standings) do
        place(row.left, rows[3] - (index - 1) * 24, "TOPLEFT", 44)
        place(row.right, rows[3] - (index - 1) * 24, "TOPRIGHT", -44)
    end
    place(view.resultLaps, rows[4])
    place(view.resultScore, rows[5])
end

-- Final rows consume the controller's retained results, not the HUD's
-- transient progress estimates. This preserves unknown finishes and tied ranks.
local function refreshStandings()
    local view, results = Menu.view, UI.multiplayerResults
    local rows = type(results) == "table" and results.rows
    local mine, theirs, shown
    for index, row in ipairs(view.standings) do
        local racer = type(rows) == "table" and rows[index]
        if type(racer) == "table" then
            shown = true
            local name = racer.localPlayer and (Menu.PlayerName() or racer.name or "You") or racer.name or "Your friend"
            name = name:gsub("|", "||")
            local rank = racer.rank and ((racer.tie and "=" or "") .. Presentation.ordinal(racer.rank)) or "--"
            row.left:SetText(rank .. "   " .. name .. (racer.localPlayer and " |cff9a9a9a(you)|r" or ""))
            local time = racer.status == "finished" and type(racer.totalTicks) == "number"
                and Menu.formatTime(racer.totalTicks * Physics.FIXED_DT)
                or (racer.status == "stopped" and "|cff9a9a9aDid not finish|r" or "|cff9a9a9aWaiting for finish|r")
            row.right:SetText(time)
            color(row.left, racer.localPlayer and GOLD or WHITE)
            row.left:Show(); row.right:Show()
            if racer.localPlayer then mine = racer else theirs = racer end
        else row.left:Hide(); row.right:Hide() end
    end
    if not shown or not mine or mine.status ~= "finished" then return nil end
    local peer = theirs and type(theirs.name) == "string" and theirs.name:gsub("|", "||") or "Your friend"
    if results.complete and theirs and theirs.status == "finished" and mine.rank and theirs.rank then
        if mine.tie or theirs.tie then
            view.bannerSub:SetText("Equal reported finish times | Local observations")
            return "tied"
        end
        local gap = math.abs(theirs.totalTicks - mine.totalTicks) * Physics.FIXED_DT
        if mine.rank == 1 then
            view.bannerSub:SetText(("%s finished %.2fs behind you"):format(peer, gap))
            return "won"
        end
        view.bannerSub:SetText(("You finished %.2fs behind %s"):format(gap, peer))
        return "second"
    end
    view.bannerSub:SetText(theirs and theirs.status == "stopped" and (peer .. " did not finish") or
        ("Waiting for " .. peer .. " to finish"))
    return "waiting"
end

-- Show the celebration `kind` (CELEBRATIONS), its animation starting over
-- only when `fresh` (once per finished run; reopening shows it still).
local function celebrate(kind, placement, fresh)
    local view, c = Menu.view, Menu.celebration
    local spec = kind and CELEBRATIONS[kind]
    c.kind, c.spec = kind, spec
    if not spec then
        for _,piece in ipairs({view.rays, view.medal, view.medalRank, view.banner, view.bannerSub}) do piece:Hide() end
        for _,piece in ipairs(view.confetti) do piece:Hide() end
        c.time = nil
        return
    end
    view.banner:SetText(spec.banner)
    color(view.banner, spec.art == "silver" and {0.86, 0.9, 0.96} or GOLD)
    view.banner:Show(); view.bannerSub:Show()
    local art = spec.art
    if placement and kind == "top3" then art = placement.rank == 2 and "silver" or "bronze" end
    -- The art loads once; a refused picture leaves the banner alone.
    if art and view.celebrationReady == nil then
        local ok, loaded = call(view.medal, "SetTexture", Menu.CELEBRATION_PATH)
        local okRays, loadedRays = call(view.rays, "SetTexture", Menu.CELEBRATION_PATH)
        view.celebrationReady = ok and loaded == true and okRays and loadedRays == true
    end
    local ready = art and view.celebrationReady
    if ready then
        local coords = Menu.CELEBRATION_COORDS[art]
        view.medal:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
        view.medal:SetSize(84, 84)
        view.medal:Show()
        view.medalRank:SetText(art == "wreath" and placement and ("#" .. placement.rank) or "")
        setShown(view.medalRank, art == "wreath")
    else
        view.medal:Hide(); view.medalRank:Hide()
    end
    if ready and spec.rays then
        local coords = Menu.CELEBRATION_COORDS.rays
        view.rays:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
        call(view.rays, "SetAlpha", 0.9)
        view.rays:Show()
    else view.rays:Hide() end
    c.rays = ready and spec.rays and true or false
    if fresh then
        c.time, c.confetti = 0, ready and spec.confetti or 0
        if spec.sound then Menu.Play(spec.sound) end
    elseif c.time == nil or c.time >= 3 then
        c.time, c.confetti = 3, 0                          -- reopened: still, no confetti
    end
    for _,piece in ipairs(view.confetti) do piece:Hide() end   -- AnimateResults shows them, placed
end

-- Later copied result/capability changes are quiet: no lap recording,
-- fanfare, confetti restart or authoritative race/session writes.
function Menu.RefreshResults()
    if Menu.disabled or not Menu.view or not Menu.view.resultHome then return end
    local view, multiplayer = Menu.view, UI.multiplayer == true
    local commands = sessionCommands()
    local session = multiplayer and sessionView() or nil
    local room = session and type(session.room) == "table" and session.room
    local role = room and (session.role or room.role)
    local host, guest = role == "host", role == "guest"
    UI.restartButton:SetText(multiplayer and "Play Again" or "Restart")
    setShown(view.resultChangeKart, not multiplayer)
    view.resultChangeTrack:SetText(multiplayer and (host and "Change Map" or "Lobby") or "Change Track")
    view.resultHome:SetText(multiplayer and "Leave Multiplayer" or "Main Menu")
    setEnabled(view.highscoresButton, not multiplayer)
    local kind, placement
    if multiplayer then
        setEnabled(UI.restartButton, commands and room and (host and session.canRematch == true or guest))
        setEnabled(view.resultChangeTrack, commands and room and (guest or host and session.canChangeMap == true))
        setEnabled(view.resultHome, commands)
        kind = refreshStandings()
        view.resultScore:SetText("Local observations; unverified places and times from each racer's clock.")
    else
        setEnabled(view.resultChangeTrack, true)
        setEnabled(view.resultHome, true)
        for _,row in ipairs(view.standings) do row.left:Hide(); row.right:Hide() end
        local score = UI.scoreResult
        view.resultScore:SetText(type(score) == "table" and type(score.message) == "string" and score.message or "")
        placement = UI.race and UI.race.status == "finished" and Menu.scorePlacement(score, UI.trackId) or nil
        kind = placement and CELEBRATIONS[placement.kind] and placement.kind or nil
        if kind then view.bannerSub:SetText(("#%d of %d in known shared scores"):format(placement.rank, placement.count)) end
    end
    color(view.resultScore, not multiplayer and type(UI.scoreResult) == "table" and UI.scoreResult.saved == true
        and GOLD or {0.5, 0.5, 0.5})
    layoutResults(kind ~= nil, multiplayer and view.standings[1].left:IsShown() or false)
    if kind and not multiplayer then call(view.highscoresButton, "LockHighlight")
    else call(view.highscoresButton, "UnlockHighlight") end
    if Menu.celebration.kind ~= kind then
        Menu.celebration.time, Menu.celebration.confetti = 3, 0
        celebrate(kind, placement, false)
    end
end

function Menu.OnResults()
    local view = Menu.view
    recordLaps()
    local race = UI.race
    local fresh = race and race.status == "finished" and Menu.fanfareRace ~= race
    if fresh then Menu.fanfareRace = race end -- once per finished run, not on every reopen
    view.resultLine:SetText(("%s    %s"):format(trackName(), kartName()))
    local times, best = {}, nil
    for _,ticks in ipairs(view.lapTimes) do
        if not best or ticks < best then best = ticks end
    end
    local sprint = race and race.targetLaps == 1
    for index,ticks in ipairs(view.lapTimes) do
        local line = (sprint and "Run  %s" or ("Lap " .. index .. "  %s")):format(Menu.formatTime(ticks * Physics.FIXED_DT))
        times[index] = ticks == best and #view.lapTimes > 1 and "|cff66ff66" .. line .. "|r" or line
    end
    view.resultLaps:SetText(#times > 0 and table.concat(times, "     ") or "")
    Menu.RefreshResults()
    local placement = not UI.multiplayer and Menu.scorePlacement(UI.scoreResult, UI.trackId) or nil
    local kind = Menu.celebration.kind
    local spec = kind and CELEBRATIONS[kind]
    if fresh and not (spec and spec.sound) then Menu.Play("finish") end
    if not fresh then Menu.celebration.time, Menu.celebration.confetti = 3, 0 end
    celebrate(kind, placement, fresh)
    Menu.barKey = nil
    Menu.Sync()
end

-- The results' motion, while shown: the medal pops in, the banner fades in,
-- confetti falls for under three seconds and the sunburst turns. Copied
-- final rows refresh quietly through RefreshResults. Nothing is created.
function Menu.AnimateResults(elapsed)
    local view, c = Menu.view, Menu.celebration
    if Menu.disabled or not c or type(elapsed) ~= "number" or elapsed < 0 then return end
    if c.rays then
        c.angle = ((c.angle or 0) + elapsed * 0.35) % (2 * math.pi)
        call(view.rays, "SetRotation", c.angle)
    end
    if c.time == nil or c.time >= 3 then return end
    c.time = c.time + elapsed
    local t = c.time
    -- The medal: 40% to 115% in 0.18s, back to full by 0.32s.
    local size = 84
    if t < 0.18 then size = 84 * (0.4 + 0.75 * t / 0.18)
    elseif t < 0.32 then size = 84 * (1.15 - 0.15 * (t - 0.18) / 0.14) end
    view.medal:SetSize(size, size)
    call(view.banner, "SetAlpha", math.min(1, t / 0.25))
    for index=1,c.confetti or 0 do
        local piece = view.confetti[index]
        local delay = (index * 7 % 10) / 20
        local age = t - delay
        if age < 0 or t >= 3 then piece:Hide()
        else
            local x = 40 + (index * 37) % 380 + (6 + index % 4 * 3) * math.sin((2 + index % 3) * age + index)
            local y = 24 - (70 + index * 13 % 50) * age
            piece:ClearAllPoints()
            piece:SetPoint("CENTER", UI.summary, "TOPLEFT", x, y)
            call(piece, "SetRotation", index * 0.7 + age * (1.5 + index % 3))
            call(piece, "SetAlpha", age > 2.1 and math.max(0, 1 - (age - 2.1) / 0.6) or 1)
            piece:Show()
        end
    end
    if c.time >= 3 then
        for _,piece in ipairs(view.confetti) do piece:Hide() end
        view.medal:SetSize(84, 84)
        call(view.banner, "SetAlpha", 1)
    end
end

-- Per-frame presentation from render(): the big lap/time/best lines. Cheap
-- numbers are compared first, so strings are only built when the shown text
-- can change (the running clock shows tenths: every sixth tick).
function Menu.RefreshRaceHud()
    local view = Menu.view
    if Menu.disabled or not view.lap then return end
    refreshPlace()
    local race, laps, progress = UI.race, UI.laps, UI.checkpoints
    local status = UI.gridStaged and "grid" or (race and race.status or "none")
    local ticks = race and race.totalTicks or 0
    local unit = status == "running" and math.floor(ticks / 6) or ticks
    local best = laps and laps.bestLapTicks or -1
    local nextGate = progress and not progress.complete and progress.nextGate or 0
    local completed = laps and laps.completedLaps or 0
    if status == view.hudStatus and unit == view.hudUnit and best == view.hudBest
        and nextGate == view.hudGate and completed == view.hudLaps and UI.track == view.hudTrack then return end
    -- (a sprint's gate count rides on nextGate: it changes with every gate)
    view.hudStatus, view.hudUnit, view.hudBest = status, unit, best
    view.hudGate, view.hudLaps, view.hudTrack = nextGate, completed, UI.track
    local lap, time, bestText
    if UI.gridStaged then lap,time,bestText="STARTING GRID",Menu.formatTime(0,1),"HOLD W/UP FOR GO"
    else lap,time,bestText=Menu.raceLines(race,laps) end
    view.lap:SetText(lap)
    view.time:SetText(time)
    view.best:SetText(bestText)
    local gates = UI.track and UI.track.gates
    local gate = ""
    if UI.gridStaged then gate="Both karts ready | Stop / Esc: leave"
    elseif race and status ~= "finished" and gates and gates[nextGate] then
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
    if UI.active or UI.gridStaged then return "race" end
    if UI.summary and UI.summary:IsShown() then return "results" end
    return "track"
end

function Menu.Sync()
    if Menu.disabled or not Menu.root then return end
    rememberTrack()
    local driving = UI.active or UI.gridStaged or false
    if driving ~= Menu.wasActive then
        Menu.wasActive = driving
        if driving and Menu.screen then Menu.Show(nil); return end
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
    if screen and (UI.active or UI.gridStaged) then screen = nil end -- never cover a live run/grid
    if screen and screen ~= "multiplayer" and UI.multiplayer then screen = "multiplayer" end
    if screen == "highscores" and Menu.screen ~= "highscores" then
        Menu.highscoreTrackIndex, Menu.highscorePage = 1, 1
        for index,track in ipairs(Menu.TRACKS) do
            if track.id == UI.trackId then Menu.highscoreTrackIndex = index; break end
        end
    end
    local leavingLobby = Menu.screen == "multiplayer" and screen ~= "multiplayer"
    local session = (leavingLobby or (screen and screen ~= "multiplayer" and UI.multiplayer)) and sessionView()
    if not UI.active and not UI.gridStaged and session and session.canLeave and sessionCommands() and
        leavingLobby and screen and session.phase ~= "racing" and session.phase ~= "finishing" then
        lobbyAction("leave")
    end
    if leavingLobby then releaseLobbyFocus() end
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
    if UI.active or UI.gridStaged or (UI.summary and UI.summary:IsShown()) then Menu.Show(nil)
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
    buildHighscores()
    buildTracks()
    buildKarts()
    buildMultiplayer()
    buildHelp()
    buildSettings()
    applyScale()
    if UI.SetEffectsEnabled then UI.SetEffectsEnabled(Menu.prefs.effects) end
    if Menu.prefs.kart and Menu.prefs.kart ~= UI.kartId then UI.SelectKart(Menu.prefs.kart) end
    if UI.SetKartOutline then UI.SetKartOutline(Menu.prefs.outline == true) end -- after the kart: one load
    Menu.seenKart = UI.kartId or false
    Menu.seenTrack = UI.trackId
    Menu.wasActive = UI.active
    Menu.RefreshRaceHud()
    Menu.Sync()
end

return Menu
