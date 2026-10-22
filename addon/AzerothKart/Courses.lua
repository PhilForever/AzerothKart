-- The selectable courses, grouped into cups: presentation data (names,
-- scenery picture, off-road wording, dust colour) plus which pure geometry
-- builds each one. Independent of WoW APIs; UI and the menus read it.
local _, namespace = ...
local Courses = {}

local TRACKS = "Interface\\AddOns\\AzerothKart\\Assets\\Tracks\\"

Courses.CUPS = {
    {id="proving", name="Proving Grounds"},
    {id="capital", name="Capital Cities Cup"},
}

-- Display order. A course marked `soon` is listed but cannot be selected.
-- background: the scenery picture for the follow camera (one texel per world
-- unit); without it the course is drawn whole with pooled shapes (Test Oval).
-- short: the name on the window's Track button, where space is tight.
Courses.LIST = {
    {id="test_oval", name="Test Oval", cup="proving", geometry="oval",
        status="Test Oval | Start for 3 laps"},
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
    {id="darnassus_canopy", name="Darnassus Canopy Run", cup="capital", soon=true},
    {id="orgrimmar_canyon", name="Orgrimmar Canyon Rush", short="Orgrimmar", cup="capital", geometry="city",
        background=TRACKS .. "Orgrimmar\\Background.tga",
        dust={0.82,0.58,0.40}, ground={0.26,0.14,0.09},
        status="Orgrimmar Canyon Rush | Start for 3 laps | Full speed to the street walls"},
    {id="thunder_bluff_skyway", name="Thunder Bluff Skyway", cup="capital", soon=true},
    {id="undercity_slime", name="Undercity Slime Circuit", cup="capital", soon=true},
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

-- The next selectable course after `id` in display order, wrapping round.
function Courses.next(id)
    local start = byId[id] and byId[id].index or 0
    for step=1,#Courses.LIST do
        local course = Courses.LIST[(start+step-1)%#Courses.LIST+1]
        if not course.soon then return course.id end
    end
    return id
end

-- The pure track for a course; crossesGate is the shared gate predicate.
-- Built tracks are kept: geometry never changes after load.
local built = {}
function Courses.build(id, crossesGate)
    local course = byId[id]
    if not course or course.soon then return nil end
    if built[id] then return built[id] end
    local track
    if course.geometry == "oval" then
        track = namespace.Track
    elseif course.geometry == "mirage" then
        track = namespace.MirageRaceway.new(crossesGate)
    elseif course.geometry == "city" then
        local definition = namespace.CapitalCities and namespace.CapitalCities[id]
        track = definition and namespace.Circuit.new(definition, crossesGate)
    end
    built[id] = track
    return track
end

if type(namespace) == "table" then namespace.Courses = Courses end
return Courses
