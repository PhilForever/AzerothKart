-- Original local Mirage Raceway blockout, independent of clocks and WoW APIs.
local _, namespace = ...
local MirageRaceway = {}

local function finite(value)
    return type(value) == "number" and value == value
        and value > -math.huge and value < math.huge
end

function MirageRaceway.new(crossesGate)
    assert(type(crossesGate) == "function", "directional gate predicate required")
    local track = {
        id="mirage_raceway", version=1, width=1024, height=1024,
        wallInset=18, checkpointMaxStep=5, roadWidth=112, roadRadius=56,
        crossesGate=crossesGate,
        centerline={
            {x=700,y=360}, {x=700,y=700}, {x=690,y=825}, {x=620,y=900},
            {x=495,y=900}, {x=390,y=865}, {x=340,y=780}, {x=355,y=690},
            {x=410,y=600}, {x=410,y=440}, {x=410,y=300}, {x=430,y=210},
            {x=495,y=140}, {x=585,y=140}, {x=665,y=190}, {x=700,y=260},
        },
        gates={
            {name="North",ax=550,ay=844,bx=550,by=956,nx=-1,ny=0},
            {name="West",ax=354,ay=520,bx=466,by=520,nx=0,ny=-1},
            {name="South",ax=540,ay=84,bx=540,by=196,nx=1,ny=0},
            {name="Start",ax=644,ay=360,bx=756,by=360,nx=0,ny=1},
        },
    }
    local segments, length = {}, 0
    for index=1,#track.centerline do
        local start = track.centerline[index]
        local finish = track.centerline[index%#track.centerline+1]
        local dx,dy = finish.x-start.x,finish.y-start.y
        local lengthSquared = dx*dx+dy*dy
        segments[index] = {x=start.x,y=start.y,dx=dx,dy=dy,lengthSquared=lengthSquared}
        length = length+math.sqrt(lengthSquared)
    end
    track.length = length
    local radiusSquared = track.roadRadius*track.roadRadius

    -- The road is the union of closed capsules around every centerline segment.
    -- Queries allocate no tables and use the construction-time segment cache.
    function track.isDrivable(x,y)
        if not finite(x) or not finite(y) then return false end
        for index=1,#segments do
            local segment = segments[index]
            local projection = ((x-segment.x)*segment.dx+(y-segment.y)*segment.dy)
                / segment.lengthSquared
            projection = math.max(0,math.min(1,projection))
            local dx = x-(segment.x+projection*segment.dx)
            local dy = y-(segment.y+projection*segment.dy)
            if dx*dx+dy*dy <= radiusSquared then return true end
        end
        return false
    end

    function track.surfaceAt(x,y)
        if not finite(x) or not finite(y) then return "wall" end
        local inset = track.wallInset
        if x < inset or x > track.width-inset or y < inset or y > track.height-inset then
            return "wall"
        end
        -- Existing Physics uses "grass" for traversable rough ground, here salt.
        return track.isDrivable(x,y) and "road" or "grass"
    end

    function track.constrainPosition(x,y)
        assert(finite(x) and finite(y), "finite track coordinates required")
        local inset = track.wallInset
        local cx = math.max(inset,math.min(track.width-inset,x))
        local cy = math.max(inset,math.min(track.height-inset,y))
        return cx,cy,cx ~= x or cy ~= y
    end

    function track.spawn()
        return {x=700,y=360,heading=math.pi/2}
    end
    return track
end

if type(namespace) == "table" then namespace.MirageRaceway = MirageRaceway end
return MirageRaceway
