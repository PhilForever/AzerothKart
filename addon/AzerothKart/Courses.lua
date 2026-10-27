-- The selectable courses, grouped into cups: presentation data (names,
-- scenery picture, off-road wording, dust colour) plus which pure geometry
-- builds each one. Independent of WoW APIs; UI and the menus read it.
-- A Scarlet Crusade Cup course is a dungeon sprint: one run from the start
-- to the last gate (its geometry sets `laps`). A Battlegrounds Cup course is
-- a course on two floors (LayeredTrack.lua): Warsong Gulch, coming soon.
local _, namespace = ...
local Courses = {DEFAULT_ID="mirage_raceway"}

local TRACKS = "Interface\\AddOns\\AzerothKart\\Assets\\Tracks\\"

Courses.CUPS = {
    {id="proving", name="Proving Grounds"},
    {id="capital", name="Capital Cities Cup"},
    {id="scarlet", name="Scarlet Crusade Cup"},
    {id="battlegrounds", name="Battlegrounds Cup"},
}

-- Display order. A course marked `soon` is listed but cannot be selected.
-- background: the scenery picture for the follow camera (one texel per world
-- unit). Development geometry fixtures are deliberately absent from this list.
-- short: the name on the window's Track button, where space is tight.
Courses.LIST = {
    {id="mirage_raceway", name="Mirage Raceway", cup="proving", geometry="mirage",
        background=TRACKS .. "SaltFlats\\Background.tga",
        rough={label="Rough salt", feedback="Slowing on rough salt"},
        dust={0.95,0.90,0.81}, ground={0.12,0.11,0.09},
        status="Mirage Raceway | Start for 3 laps | Off-road: rough salt"},
    {id="stormwind_city", name="Stormwind City Circuit", short="Stormwind City", cup="capital", geometry="city",
        background=TRACKS .. "Stormwind\\Background.tga",
        dust={0.86,0.84,0.80}, ground={0.20,0.27,0.16},
        status="Stormwind City Circuit | Start for 3 laps | Full speed to the street walls"},
    {id="ironforge_gp", name="Ironforge Grand Prix", short="Ironforge", cup="capital", geometry="city",
        background=TRACKS .. "Ironforge\\Background.tga",
        rough={label="Off-road", feedback="Slowing off the road"},
        dust={0.70,0.64,0.58}, ground={0.12,0.10,0.09},
        status="Ironforge Grand Prix | Start for 3 laps | Walls and landmarks are solid"},
    {id="darnassus_canopy", name="Darnassus Canopy Run", short="Darnassus", cup="capital", geometry="city",
        background=TRACKS .. "Darnassus\\Background.tga",
        dust={0.84,0.82,0.88}, ground={0.16,0.20,0.10},
        status="Darnassus Canopy Run | Start for 3 laps | Full speed to the street walls"},
    {id="orgrimmar_canyon", name="Orgrimmar Canyon Rush", short="Orgrimmar", cup="capital", geometry="city",
        background=TRACKS .. "Orgrimmar\\Background.tga",
        dust={0.82,0.58,0.40}, ground={0.26,0.14,0.09},
        status="Orgrimmar Canyon Rush | Start for 3 laps | Full speed to the street walls"},
    {id="thunder_bluff_skyway", name="Thunder Bluff Skyway", short="Thunder Bluff", cup="capital", geometry="city",
        background=TRACKS .. "ThunderBluff\\Background.tga",
        dust={0.86,0.82,0.74}, ground={0.43,0.47,0.38},
        status="Thunder Bluff Skyway | Start for 3 laps | Full speed to the street walls"},
    {id="undercity_slime", name="Undercity Slime Circuit", short="Undercity", cup="capital", geometry="city",
        background=TRACKS .. "Undercity\\Background.tga",
        dust={0.62,0.70,0.56}, ground={0.10,0.10,0.09},
        status="Undercity Slime Circuit | Start for 3 laps | Full speed to the street walls"},
    {id="scarlet_graveyard", name="Scarlet Graveyard", short="Graveyard", cup="scarlet", geometry="dungeon",
        background=TRACKS .. "ScarletGraveyard\\Background.tga",
        dust={0.78,0.74,0.68}, ground={0.05,0.05,0.05},
        status="Scarlet Graveyard | Sprint to Honor's Tomb | Full speed on the grass; graves block"},
    {id="scarlet_library", name="Scarlet Library", short="Library", cup="scarlet", geometry="dungeon",
        background=TRACKS .. "ScarletLibrary\\Background.tga",
        dust={0.80,0.74,0.66}, ground={0.05,0.05,0.05},
        status="Scarlet Library | Sprint to Arcanist Doan | Full speed across the cloister's lawn"},
    {id="scarlet_armory", name="Scarlet Armory", short="Armory", cup="scarlet", geometry="dungeon",
        background=TRACKS .. "ScarletArmory\\Background.tga",
        dust={0.80,0.72,0.62}, ground={0.05,0.05,0.05},
        status="Scarlet Armory | Sprint to Herod | Down the Hall of Champions' stairs to finish"},
    {id="scarlet_cathedral", name="Scarlet Cathedral", short="Cathedral", cup="scarlet", geometry="dungeon",
        background=TRACKS .. "ScarletCathedral\\Background.tga",
        dust={0.78,0.74,0.68}, ground={0.05,0.05,0.05},
        status="Scarlet Cathedral | Sprint to the altar | Up the stairs and turn at the landing"},
    -- Two floors: in by each base's tunnel, round its flag, out by its ramp.
    -- Listed, not selectable, until Codex reviews the geometry and assigns its
    -- course, wire and score IDs (docs/LAYERED_TRACKS.md).
    {id="warsong_gulch", name="Warsong Gulch", short="Warsong", cup="battlegrounds", geometry="layered",
        soon=true, guideArrow=true,
        background=TRACKS .. "WarsongGulch\\Background.tga", roofs=TRACKS .. "WarsongGulch\\Roofs.tga",
        dust={0.80,0.74,0.60}, ground={0.14,0.17,0.10},
        status="Warsong Gulch | Start for 3 laps | In by each tunnel, round the flag, out by the ramp"},
}

local byId = {}
for index,course in ipairs(Courses.LIST) do
    course.index = index
    byId[course.id] = course
end

function Courses.get(id)
    return byId[id]
end

function Courses.available(id)
    local course = byId[id]
    return course ~= nil and not course.soon
end

-- All production courses use the same two-peer controller. Geometry supplies
-- the race target: three laps on circuits, one ordered run on dungeon sprints.
function Courses.multiplayer(id)
    return Courses.available(id)
end

-- The next selectable course after `id` in display order, wrapping round.
-- Optional multiplayerOnly filters the lobby without changing the solo cycle.
function Courses.next(id, multiplayerOnly)
    local start = byId[id] and byId[id].index or 0
    for step=1,#Courses.LIST do
        local course = Courses.LIST[(start+step-1)%#Courses.LIST+1]
        if not course.soon and (not multiplayerOnly or Courses.multiplayer(course.id)) then return course.id end
    end
    return id
end

-- A two-floor course's roofs (presentation data beside its geometry): boxes
-- of its roof picture drawn over the ground, each with the boxes under it
-- that fade it (Presentation.roofAlpha). nil for every other course.
function Courses.roofs(id)
    local course = byId[id]
    if not course or course.geometry ~= "layered" then return nil end
    local definition = namespace.Battlegrounds and namespace.Battlegrounds[id]
    return definition and definition.overlays
end

-- The pure track for a course; crossesGate is the shared gate predicate.
-- Built tracks are kept: geometry never changes after load.
local built = {}
function Courses.build(id, crossesGate)
    local course = byId[id]
    if not course or course.soon then return nil end
    if built[id] then return built[id] end
    local track
    if course.geometry == "mirage" then
        track = namespace.MirageRaceway.new(crossesGate)
    elseif course.geometry == "city" then
        local definition = namespace.CapitalCities and namespace.CapitalCities[id]
        track = definition and namespace.Circuit.new(definition, crossesGate)
    elseif course.geometry == "dungeon" then
        local definition = namespace.ScarletCrusade and namespace.ScarletCrusade[id]
        track = definition and namespace.Dungeon and namespace.Dungeon.new(definition, crossesGate)
    elseif course.geometry == "layered" then
        local definition = namespace.Battlegrounds and namespace.Battlegrounds[id]
        track = definition and namespace.LayeredTrack and namespace.LayeredTrack.new(definition, crossesGate)
    end
    built[id] = track
    return track
end

if type(namespace) == "table" then namespace.Courses = Courses end
return Courses
