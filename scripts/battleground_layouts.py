"""Battlegrounds Cup layouts for build_battlegrounds.py: two-floor courses.

A battleground course is a dungeon course on two floors (LayeredTrack.lua,
docs/LAYERED_TRACKS.md): axis-aligned rooms, each on floor 0 (the ground:
the field, the tunnels, the bases' halls) or floor 1 (above it: the plateau
over each tunnel, each base's roof), joined only by straight ramps. A kart
meets only its own floor's walls; a ramp belongs to both floors, and a kart
that leaves it by its high end is on floor 1, by its low end on floor 0.
Collision on each floor is Dungeon.lua's: the kart centre stays WALL_INSET
inside the rooms, and rooms meet where they overlap by DOOR_OVERLAP.

The contract's authoring rules hold (build_battlegrounds.validate checks
them, LayeredTrack.new checks them again at load): a ramp's interior, all of
it but 2 x WALL_INSET at either end, lies in no room of either floor; its
ends meet the floors they lead to; ramps stand more than 16 units apart;
gates and Boots pads keep clear of ramps; the spawn stands on its floor.

Each ramp's end is laid exactly on the kart floor's edge of the room it
joins (the room overlaps the ramp by WALL_INSET), so the floor runs onto the
ramp with no lip: no stub of the ramp's side walls stands out into a room.

World units, bottom-left origin, one texel per unit in the pictures. The
gulch is point-symmetric about its centre: the Horde's half is the
Alliance's turned half a circle (`mirror`).
"""
from city_layouts import WALL_INSET, prop

TA = "war3.w3mod:terrainart/"
ASHEN = "war3.w3mod:doodads/ashenvale/"
SUMMER = "war3.w3mod:doodads/lordaeronsummer/"
ORC = "war3.w3mod:buildings/orc/"
SILVER = "war3.w3mod:doodads/silvermoon/structures/"

DOOR_OVERLAP = 2 * WALL_INSET
NORTH, SOUTH, EAST, WEST = (0, 1), (0, -1), (1, 0), (-1, 0)


def room(name, x0, y0, x1, y1, level=0, floor="field", cover=None):
    """A rectangle of floor on `level`, painted in the `floor` style.
    `cover`: the roof overlay above it (a floor 0 room under a plateau or a
    roof), which fades while the player's kart is in the room."""
    assert x1 - x0 > 2 * WALL_INSET and y1 - y0 > 2 * WALL_INSET, name
    assert level in (0, 1), name
    return {"name": name, "x0": x0, "y0": y0, "x1": x1, "y1": y1, "surface": "road",
            "level": level, "floor": floor, "cover": cover}


def ramp(rid, name, x0, y0, x1, y1, axis, ascending):
    """A straight ramp from floor 0 (its low end) to floor 1 (its high end).
    `axis` "x" or "y" is the way along it; `ascending` 1 puts the low end at
    its west/south end, -1 at its east/north end."""
    assert axis in ("x", "y") and ascending in (1, -1), rid
    return {"id": rid, "name": name, "x0": x0, "y0": y0, "x1": x1, "y1": y1, "axis": axis,
            "ascending": ascending}


def gate(name, ax, ay, bx, by, normal, level=0):
    return {"name": name, "ax": ax, "ay": ay, "bx": bx, "by": by, "nx": normal[0], "ny": normal[1],
            "level": level}


def pad(pid, x, y, radius, level=0, boost_ticks=78):
    """A Boots pad: a kart that drives onto its disc on its floor boosts
    (78 ticks: a tier-2 drift boost), once each pass."""
    return {"id": pid, "x": x, "y": y, "radius": radius, "level": level, "boostTicks": boost_ticks}


def overlay(oid, name, x0, y0, x1, y1, under, footprint=None):
    """A roof picture over floor 0: drawn over karts below it and under karts
    on it, it fades while the player's kart is on floor 0 in one of the
    `under` rooms (named). The box is the picture drawn; `footprint` (the
    box when not given), within it, the hill or roof painted, the rest of
    the box kept for what stands out from it (a corner tower)."""
    out = {"id": oid, "name": name, "x0": x0, "y0": y0, "x1": x1, "y1": y1, "under": list(under)}
    out["footprint"] = tuple(footprint) if footprint else (x0, y0, x1, y1)
    return out


# ---------------------------------------------------------------------------
# The half-turn: the Horde's half of the gulch from the Alliance's.


def mirror(item, width, height, rename):
    """`item` (a room, ramp, gate, pad, solid, overlay or route point) turned
    half a circle about the world's centre; `rename` maps its names."""
    if isinstance(item, tuple):
        return (width - item[0], height - item[1])
    out = dict(item)
    for key in ("name", "id"):
        if key in out:
            out[key] = rename(out[key])
    if "under" in out:
        out["under"] = [rename(n) for n in out["under"]]
    if "cover" in out and out["cover"]:
        out["cover"] = rename(out["cover"])
    if "x0" in out:
        out["x0"], out["x1"] = width - item["x1"], width - item["x0"]
        out["y0"], out["y1"] = height - item["y1"], height - item["y0"]
    if "ax" in out:
        out["ax"], out["ay"] = width - item["ax"], height - item["ay"]
        out["bx"], out["by"] = width - item["bx"], height - item["by"]
        out["nx"], out["ny"] = -item["nx"], -item["ny"]
    if "ascending" in out:
        out["ascending"] = -item["ascending"]
    if "radius" in out and "boostTicks" in out:
        out["x"], out["y"] = width - item["x"], height - item["y"]
    elif "width" in out and "x" in out:            # a solid box
        out["x"] = width - item["x"] - item["width"]
        out["y"] = height - item["y"] - item["height"]
    return out


# ---------------------------------------------------------------------------
# Warsong Gulch.
#
# The owner (2026-10-27): "Battlegrounds Cup - let's try Warsong Gulch first.
# It's going to be groundbreaking if we can make it work. The challenge is the
# two tunnels, and possibly floors." Asked, he chose a fixed loop of three
# laps, "at each base, in by the tunnel, round the flag, out by the ramp"; a
# flag room with "Two doors: drive through"; the banana and the roof as an
# "Optional way in"; the grid at mid, facing the Alliance base; a guiding
# arrow on Warsong only; a Boots pad in each tunnel.
#
# Silverwing Hold (the Alliance's, north), as one lap meets it:
#
# - the tunnel, from its mouth in the field's north wall (west of the
#   middle) straight north under the plateau, its Boots near its far end,
#   into the entry hall;
# - the entry hall: its door north into the flag room, which the karts
#   cross east to west past the flag, and leave by the door in its south
#   wall into the front hall, at the base's west end;
# - the front door: south out of the front hall, a short ramp climbs onto
#   the plateau, the hill over the tunnel;
# - the plateau (floor 1), with the graveyard and the fence on it: the
#   karts cross it east, right over the tunnel they came in by, to
# - the ramp, down south off the plateau's east end into a gully, and out
#   into the field's north-east corner.
#
# The optional way in: the tunnel exit, a side door of the tunnel, runs
# east under the plateau to the banana, which climbs north to the terrace,
# the east end of Silverwing Hold's roof; the connector, a ramp down west
# from the terrace, lands in the entry hall beside the flag room's door.
# The roof (floor 1) runs on west from the terrace over the flag room.
#
# A ramp's side walls are walls on both floors, and no room of the other
# floor comes near a ramp's end (build_battlegrounds checks both), so a
# kart changes floor only by driving a ramp from end to end.
#
# Mid, between the bases: the stumps in the middle of the field. The run
# north passes them on the west, the run south on the east; the finish line
# runs from the field's west wall to the stumps.

WG_WIDTH, WG_HEIGHT = 1024, 2048

WG_FIELD = room("field", 140, 680, 884, 1368, floor="field")

WG_ALLIANCE_ROOMS = [
    room("alliance tunnel", 340, 1332, 460, 1720, floor="tunnel", cover="alliance hill"),
    room("alliance tunnel exit", 424, 1530, 800, 1630, floor="tunnel", cover="alliance hill"),
    room("alliance banana foot", 764, 1530, 884, 1658, floor="tunnel", cover="alliance hill"),
    room("alliance gully", 764, 1332, 884, 1418, floor="gully"),
    room("alliance entry hall", 340, 1684, 620, 1832, floor="hall", cover="alliance roof"),
    room("alliance entry door", 490, 1796, 610, 1886, floor="door", cover="alliance roof"),
    room("alliance flag room", 100, 1850, 640, 2028, floor="flag room", cover="alliance roof"),
    room("alliance exit door", 140, 1796, 260, 1886, floor="door", cover="alliance roof"),
    room("alliance front hall", 100, 1684, 300, 1832, floor="hall", cover="alliance roof"),
    room("alliance plateau", 120, 1492, 884, 1620, level=1, floor="plateau"),
    room("alliance terrace", 694, 1732, 884, 2028, level=1, floor="terrace"),
    room("alliance roof", 100, 1940, 884, 2028, level=1, floor="roof"),
]

WG_ALLIANCE_RAMPS = [
    ramp("alliance_ramp", "alliance ramp", 764, 1400, 884, 1510, "y", 1),
    ramp("alliance_front", "alliance front door", 140, 1602, 260, 1702, "y", -1),
    ramp("alliance_connector", "alliance connector", 602, 1732, 712, 1832, "x", 1),
    ramp("alliance_banana", "alliance banana", 764, 1640, 884, 1750, "y", 1),
]

# The roofs over floor 0 (see `overlay`). The camera leans north, so the two
# halves are not drawn as mirrors: it sees the Alliance hill's cliff face
# rise over the field (painted on the ground, below the hill's box) and only
# the top of the Horde's, right to the field's edge.
WG_OVERLAYS = [
    # The hills: the plateau's top and the slopes over each tunnel and its exit.
    overlay("alliance_hill", "alliance hill", 120, 1416, 884, 1684,
            ("alliance tunnel", "alliance tunnel exit", "alliance banana foot")),
    overlay("horde_hill", "horde hill", 140, 364, 904, 680,
            ("horde tunnel", "horde tunnel exit", "horde banana foot")),
    # The bases' roofs, over their halls and flag rooms; the terraces.
    overlay("alliance_roof", "alliance roof", 64, 1684, 924, 2048,
            ("alliance entry hall", "alliance entry door", "alliance flag room", "alliance exit door",
             "alliance front hall"), footprint=(100, 1684, 884, 2048)),
    overlay("horde_roof", "horde roof", 100, 0, 960, 404,
            ("horde entry hall", "horde entry door", "horde flag room", "horde exit door", "horde front hall"),
            footprint=(140, 0, 924, 364)),
]

WG_ALLIANCE_GATES = [
    gate("Alliance tunnel", 340, 1380, 460, 1380, NORTH),
    gate("Alliance flag", 380, 1850, 380, 2028, WEST),
    gate("Alliance ramp", 764, 1372, 884, 1372, SOUTH),
]

WG_ALLIANCE_PADS = [pad("alliance_boots", 400, 1668, 14)]

# The reviewed way through Silverwing Hold, from the field below the tunnel's
# mouth to the field below the gully (kart centres).
WG_ALLIANCE_ROUTE = [
    (400, 1340), (400, 1730), (530, 1770), (550, 1820), (550, 1910), (440, 1925), (330, 1925), (220, 1925),
    (200, 1890), (200, 1602), (240, 1560), (760, 1555), (824, 1525), (824, 1350),
]


def wg_horde(name):
    return name.replace("alliance", "horde").replace("Alliance", "Horde")


def _wg_mirror(item):
    return mirror(item, WG_WIDTH, WG_HEIGHT, wg_horde)


WG_SPAWN = (300, 984, "north", 0)
WG_ROUTE = ([WG_SPAWN[:2], (300, 1100), (390, 1300)] + WG_ALLIANCE_ROUTE
            + [(790, 1260), (785, 1170), (700, 1024), (630, 760)]
            + [_wg_mirror(p) for p in WG_ALLIANCE_ROUTE]
            + [(240, 780), (239, 878), (300, 940), (300, 1060)])

WARSONG = {
    "id": "warsong_gulch",
    "name": "Warsong Gulch",
    "version": 1,
    "size": (WG_WIDTH, WG_HEIGHT),
    "laps": 3,
    "rooms": [WG_FIELD] + WG_ALLIANCE_ROOMS + [_wg_mirror(r) for r in WG_ALLIANCE_ROOMS],
    "ramps": WG_ALLIANCE_RAMPS + [_wg_mirror(r) for r in WG_ALLIANCE_RAMPS],
    "overlays": WG_OVERLAYS,
    # In lap order: the Alliance's three, the Horde's three, then mid.
    "gates": WG_ALLIANCE_GATES + [_wg_mirror(g) for g in WG_ALLIANCE_GATES]
    + [gate("Mid", 140, 1024, 468, 1024, NORTH)],          # to mid's stumps: geometry() places it
    "pads": WG_ALLIANCE_PADS + [_wg_mirror(p) for p in WG_ALLIANCE_PADS],
    # Every solid is its scenery's (`props`: mid's stumps, the huts, each
    # flag), blocking where it is drawn.
    "solids": [],
    "spawn": WG_SPAWN,
    "route": WG_ROUTE,
}

# ---------------------------------------------------------------------------
# Warsong Gulch's painting (battleground_paint.py).
#
# The gulch from the karts' camera: Ashenvale's grass and trees on the
# Alliance's half, the Barrens' dirt on the Horde's, meeting at mid. Each
# side's style: its terrain, its cliffs and its fortress (Silverwing Hold's
# violet stone and pale wood; the Warsong Lumber Mill's logs and planks).

WG_TERRAIN = [   # draw order, lowest first
    {"name": "bdirt", "tile": TA + "barrens/barrens_dirt.dds", "variety": 40},
    {"name": "brough", "tile": TA + "barrens/barrens_dirtrough.dds", "variety": 40},
    {"name": "bgrass", "tile": TA + "barrens/barrens_grass.dds", "variety": 45},
    {"name": "adirt", "tile": TA + "ashenvale/ashen_dirt.dds", "variety": 30},
    {"name": "agrass", "tile": TA + "ashenvale/ashen_grass.dds", "variety": 40},
    {"name": "alumpy", "tile": TA + "ashenvale/ashen_grasslumpy.dds", "variety": 40},
    {"name": "aleaves", "tile": TA + "ashenvale/ashen_leaves.dds", "shade": (0.95, 1.0, 1.05)},
]


def _seeds(points):
    return [(x, y) for x, y in points] + [(WG_WIDTH - x, WG_HEIGHT - y) for x, y in points]


WG_DISTRICTS = [
    # The Alliance's half: Ashenvale's grass, lumpier toward the cliffs.
    {"name": "Ashenvale field", "ground": "agrass",
     "seeds": [(330, 1100), (600, 1180), (450, 1300), (700, 1360), (260, 1300), (520, 1500),
               (840, 1260), (840, 1120), (180, 1160), (840, 1360), (180, 1340)]},
    {"name": "Ashenvale woods", "ground": "alumpy",
     "seeds": [(60, 1200), (970, 1250), (60, 1700), (970, 1700), (60, 1950), (970, 1980), (40, 1450),
               (980, 1450), (500, 2040)]},
    # The Horde's half: the Barrens' dirt and scrub.
    {"name": "Barrens field", "ground": "bdirt",
     "seeds": [(694, 948), (424, 868), (574, 748), (324, 688), (764, 748), (504, 548),
               (184, 788), (184, 928), (844, 888), (184, 688), (844, 708)]},
    {"name": "Barrens scrub", "ground": "brough",
     "seeds": [(964, 848), (54, 798), (964, 348), (54, 348), (964, 98), (54, 68), (984, 598), (44, 598),
               (524, 8)]},
]


def _lane(points, half):
    """Zones of worn ground along a polyline: a quad per segment."""
    out = []
    for (ax, ay), (bx, by) in zip(points, points[1:]):
        dx, dy = bx - ax, by - ay
        n = (dx * dx + dy * dy) ** 0.5
        nx, ny = -dy / n * half, dx / n * half
        out.append(("poly", [(ax + nx, ay + ny), (bx + nx, by + ny), (bx - nx, by - ny), (ax - nx, ay - ny)]))
    return out


# The field's worn lanes: north up the west side to the Alliance tunnel,
# south down the east side to the Horde's (each half its own dirt).
WG_LANE_NORTH = [(250, 720), (300, 940), (300, 1100), (390, 1300), (400, 1368)]
WG_LANE_SOUTH = [(824, 1368), (790, 1260), (700, 1024), (630, 760), (624, 680)]
WG_ZONES = ([{"terrain": "adirt", "shape": s} for s in _lane([p for p in WG_LANE_NORTH if p[1] >= 1000], 26)]
            + [{"terrain": "brough", "shape": s} for s in _lane([p for p in WG_LANE_NORTH if p[1] <= 1100], 26)]
            + [{"terrain": "adirt", "shape": s} for s in _lane([p for p in WG_LANE_SOUTH if p[1] >= 1000], 26)]
            + [{"terrain": "brough", "shape": s} for s in _lane([p for p in WG_LANE_SOUTH if p[1] <= 1100], 26)]
            + [{"terrain": "adirt", "shape": ("circle", (512, 1060, 70))},
               {"terrain": "brough", "shape": ("circle", (512, 988, 70))}])

WG_SIDES = {
    "alliance": {
        "cliff": (TA + "ashenvale/ashen_cliff1.dds", (0, 0, 192, 64), (0.92, 0.96, 1.0)),
        "rock": {"tile": TA + "ashenvale/ashen_rock.dds", "shade": (0.86, 0.9, 0.98)},
        "dirt": {"tile": TA + "ashenvale/ashen_dirt.dds", "shade": (0.92, 0.9, 0.9)},
        "tunnel": {"tile": TA + "barrens/barrens_dirt.dds", "shade": (0.74, 0.64, 0.58)},
        "earth": (40, 34, 36),
        "wall": {"face": (TA + "ruins/ruins_cliff1.dds", (0, 0, 192, 64), (0.92, 0.86, 1.04, 0.25)),
                 "top": (58, 50, 72), "coping": (170, 160, 196), "height": 70},
        "floor": {"parquet": {"block": 32, "plank": 8, "colour": (112, 84, 96)}},
        "door": {"tile": TA + "ruins/ruins_roundtiles.dds", "shade": (1.05, 0.95, 1.15, 0.45)},
        "runner": ((40, 58, 128), (196, 196, 220)),
        "deck": (176, 168, 182), "roof": (92, 70, 140), "ridge": (196, 190, 220),
        "walk": {"tile": TA + "ruins/ruins_largebricks.dds", "shade": (0.92, 0.88, 1.02, 0.35)},
        "lamp": (120, 160, 255),
    },
    "horde": {
        "cliff": (TA + "barrens/barrens_cliff1.dds", (0, 0, 192, 64), (1.0, 0.94, 0.86)),
        "rock": {"tile": TA + "barrens/barrens_dirtrough.dds", "shade": 0.86},
        "dirt": {"tile": TA + "barrens/barrens_dirt.dds", "shade": 0.9},
        "tunnel": {"tile": TA + "barrens/barrens_dirtrough.dds", "shade": (0.8, 0.68, 0.56)},
        "earth": (44, 34, 26),
        "wall": {"face": (TA + "barrens/barrens_cliff0.dds", (0, 0, 192, 64), (0.92, 0.82, 0.7)),
                 "top": (66, 46, 30), "coping": (150, 112, 74), "height": 70},
        "floor": {"parquet": {"block": 48, "plank": 12, "colour": (140, 98, 58)}},
        "door": {"tile": TA + "barrens/barrens_pebbles.dds", "shade": 0.9},
        "runner": ((128, 26, 20), (30, 22, 18)),
        "deck": (120, 84, 52), "roof": (110, 74, 44), "ridge": (60, 40, 26),
        "walk": {"planks": (126, 88, 54)},
        "lamp": (255, 150, 60),
    },
}

WARSONG.update({
    "folder": "WarsongGulch",
    "lean": 0.6, "team": (0.12, 0.3, 0.86), "supersample": 3,
    "replaceables": {31: "war3.w3mod:replaceabletextures/ashenvaletree/ashentree.dds",
                     32: "war3.w3mod:replaceabletextures/ashenvaletree/ashentree.dds",
                     33: "war3.w3mod:replaceabletextures/barrenstree/barrenstree.dds"},
    "terrain": WG_TERRAIN, "districts": WG_DISTRICTS, "zones": WG_ZONES, "sides": WG_SIDES,
    # The pitched roofs over each base's halls (the rest of a roof's box is
    # its walk, floor 1, or its walls' tops). The Alliance's begin above its
    # front wall, which the camera sees; the Horde's front faces away.
    "hips": [(100, 1726, 336, 1850), (336, 1726, 602, 1850), (100, 1850, 694, 1940),
             (688, 198, 924, 364), (422, 198, 688, 364), (330, 108, 924, 198)],
    "props": [], "roof_props": [],
})

# ---------------------------------------------------------------------------
# Warsong Gulch's scenery. Each placement on the Alliance's half has its
# Horde twin turned half a circle (the course is fair both ways round), each
# in its own side's models. Solid scenery blocks where it is drawn (`blocks`,
# as in the dungeons): a hut's or a stump's round, a tree's crown.

TREES_A = ["war3.w3mod:doodads/terrain/ashentree/ashentree%d.mdx" % n for n in range(10)]
TREES_H = ["war3.w3mod:doodads/terrain/barrenstree/barrenstree%d.mdx" % n for n in range(10)]
ROCKS_A = [ASHEN + "rocks/ashenrock/ashenrock%d.mdx" % n for n in range(10)]
ROCKS_H = ["war3.w3mod:doodads/barrens/rocks/barrens_rocks/barrens_rocks%d.mdx" % n for n in range(10)]
HORDE_RED = (0.62, 0.08, 0.06)
ALLIANCE_BLUE = (0.12, 0.3, 0.86)
# Silvermoon's teal domes and gold trim made Silverwing Hold's violet and
# silver, as Darnassus's.
NIGHTELF_ROOFS = [(150.0, 235.0, 272.0, 0.12, 1.0, 0.95), (20.0, 70.0, 250.0, 0.25, 0.25, 1.05)]


def _blocks(item, kind="round"):
    item["blocks"] = kind
    return item


def _twin(alliance, horde, x, y, yaw=270, scale=0.4, solid=False, blocks=None, name=None, team=True,
          horde_scale=None, **kw):
    """An Alliance placement and its Horde twin, turned half a circle (the
    Horde's own model, at `horde_scale` when its size differs)."""
    a = prop(alliance, x, y, yaw=yaw, scale=scale, solid=solid, name=name and "alliance_" + name,
             team=ALLIANCE_BLUE if team else None, **kw)
    hkw = dict(kw)
    hkw.pop("recolor", None)
    hkw.pop("stone", None)
    h = prop(horde, WG_WIDTH - x, WG_HEIGHT - y, yaw=(yaw + 180) % 360, scale=horde_scale or scale,
             solid=solid, name=name and "horde_" + name, team=HORDE_RED if team else None, **hkw)
    if blocks:
        _blocks(a, blocks)
        _blocks(h, blocks)
    return [a, h]


def _strip(x0, x1, y0, y1, step, seed, models, scales, avoid=()):
    """Trees along the cliff tops: one every `step` units down a strip,
    jittered across it by a hash (no PRNG), skipping `avoid` boxes."""
    from paintkit import hash2
    out = []
    y = y0
    k = 0
    while y < y1:
        x = x0 + hash2(k, seed, 7) % max(1, x1 - x0)
        yy = y + hash2(k, seed, 9) % (step // 2)
        if not any(a[0] <= x <= a[2] and a[1] <= yy <= a[3] for a in avoid):
            model = models[hash2(k, seed, 11) % len(models)]
            scale = scales[0] + (scales[1] - scales[0]) * (hash2(k, seed, 13) % 100) / 100
            out.append(prop(model, x, yy, yaw=hash2(k, seed, 17) % 8 * 45, scale=round(scale, 3),
                            alpha_shadow=True, name="tree"))
        y += step
        k += 1
    return out


WG_FIELD_PROPS = (
    # Mid: the hollow stump the field's runs pass either side of.
    [_blocks(prop(ASHEN + "props/ashenhollowstump/ashenhollowstump.mdx", 512, 1000, yaw=225, scale=0.62,
                  solid=True, name="mid_stumps"))]
    # The huts: the Leaf hut west and the Zerker hut east on the Alliance's
    # half; the Horde's twins.
    + _twin("war3.w3mod:buildings/other/furbolghut/furbolghut.mdx", "war3.w3mod:buildings/orc/trollburrow/trollburrow.mdx",
            210, 1240, yaw=315, scale=0.34, horde_scale=0.38, solid=True, blocks="round", name="leaf_hut")
    + _twin("war3.w3mod:buildings/other/furbolghut2/furbolghut2.mdx", "war3.w3mod:buildings/orc/trollburrow/trollburrow.mdx",
            705, 1190, yaw=225, scale=0.34, horde_scale=0.38, solid=True, blocks="round", name="zerker_hut")
    # Rocks and a tree or two out on the field.
    + _twin(ROCKS_A[3], ROCKS_H[3], 600, 1290, yaw=45, scale=0.4, solid=True, blocks="round", name="rock", cut=0.5,
            team=False)
    + _twin(ROCKS_A[6], ROCKS_H[6], 232, 1068, yaw=135, scale=0.36, solid=True, blocks="round", name="rock", cut=0.5,
            team=False)
    + _twin(TREES_A[2], TREES_H[2], 172, 1296, yaw=45, scale=0.26, solid=True, blocks="round", name="tree",
            alpha_shadow=True, team=False)
    + _twin(TREES_A[5], TREES_H[5], 858, 1100, yaw=180, scale=0.27, solid=True, blocks="round", name="tree",
            alpha_shadow=True, team=False)
)

# The cliff tops round the gulch: Ashenvale's trees north of mid, the
# Barrens' south; clear of the bases' walls.
WG_WOODS = (_strip(16, 64, 1040, 1680, 40, 1, TREES_A, (0.3, 0.4))
            + _strip(960, 1008, 1040, 1700, 40, 2, TREES_A, (0.3, 0.4))
            + _strip(10, 40, 1700, 2020, 48, 3, TREES_A, (0.26, 0.32))
            + _strip(16, 64, 20, 1000, 42, 4, TREES_H, (0.32, 0.42))
            + _strip(960, 1008, 380, 1000, 40, 5, TREES_H, (0.32, 0.42))
            + _strip(984, 1012, 30, 350, 48, 6, TREES_H, (0.26, 0.32)))

WG_GROUND_PROPS = (
    # Each flag stands toward its flag room's north wall (the camera sees a
    # banner lean north) and blocks where it is drawn: the karts round it on
    # the south. Both racers drive both bases, so the two rooms need not be
    # mirrors: the Alliance's flag is on the far side of its room, the
    # Horde's on the near side.
    [_blocks(prop(SUMMER + "props/bannerhuman/bannerhuman0.mdx", 380, 1984, yaw=270, scale=0.36, solid=True,
                  team=ALLIANCE_BLUE, name="alliance_flag"), "drawn"),
     _blocks(prop(SUMMER + "props/bannerorc/bannerorc0.mdx", 644, 156, yaw=270, scale=0.36, solid=True,
                  team=HORDE_RED, name="horde_flag"), "drawn")]
    # Braziers either side of each tunnel's mouth.
    + _twin(ASHEN + "props/brazier/brazier.mdx", SUMMER + "props/brazier/brazier.mdx", 322, 1380, scale=0.26,
            name="brazier", team=False)
    + _twin(ASHEN + "props/brazier/brazier.mdx", SUMMER + "props/brazier/brazier.mdx", 478, 1380, scale=0.26,
            name="brazier", team=False)
)

WG_HILL_PROPS = (
    # The graveyard over the tunnel, between the plateau and the hold.
    _twin(SUMMER + "props/grave/grave.mdx", SUMMER + "props/grave/grave.mdx", 320, 1640, scale=0.3, team=False,
          name="grave")
    + _twin("war3.w3mod:doodads/northrend/props/northrendtombstone/northrendtombstone0.mdx",
            "war3.w3mod:doodads/barrens/props/barrens_bones/barrens_bones0.mdx", 370, 1636, scale=0.3, team=False,
            name="grave")
    + _twin("war3.w3mod:doodads/northrend/props/northrendtombstone/northrendtombstone1.mdx",
            SUMMER + "props/grave/grave.mdx", 420, 1640, scale=0.3, team=False, name="grave")
    + _twin("war3.w3mod:doodads/northrend/props/northrendtombstone/northrendtombstone2.mdx",
            "war3.w3mod:doodads/barrens/props/barrens_bones/barrens_bones2.mdx", 470, 1636, scale=0.3, team=False,
            name="grave")
    + _twin(ASHEN + "props/sentinelstatue/sentinelstatue.mdx", "war3.w3mod:doodads/barrens/props/taurentotem/taurentotem0.mdx",
            540, 1634, scale=0.24, team=False, name="graveyard_statue")
    # The fence along the hill's crest over the field (the Horde's, stakes).
    + [prop("war3.w3mod:doodads/village/props/village_fencelong/village_fencelong.mdx", x, 1460, yaw=90,
            scale=0.3, name="alliance_fence") for x in (190, 270, 520, 600, 680)]
    + [prop("war3.w3mod:_de.w3mod:doodads/lordaeronsummer/structures/palisade/palisade%d.mdx" % (k % 2),
            WG_WIDTH - x, WG_HEIGHT - 1462, yaw=90 * (k % 4), scale=0.55, name="horde_stake")
       for k, x in enumerate(range(160, 340, 22)) if True]
    + [prop("war3.w3mod:_de.w3mod:doodads/lordaeronsummer/structures/palisade/palisade%d.mdx" % (k % 2),
            WG_WIDTH - x, WG_HEIGHT - 1462, yaw=90 * (k % 4), scale=0.55, name="horde_stake")
       for k, x in enumerate(range(500, 760, 22))]
    # Rocks and scrub on the hills' slopes.
    + _twin(ASHEN + "plants/ashenbush0/ashenbush0.mdx", ROCKS_H[1], 620, 1448, scale=0.3, horde_scale=0.36,
            team=False, name="scrub", cut=0.5)
    + _twin(ROCKS_A[1], ROCKS_H[4], 250, 1448, scale=0.34, team=False, name="scrub", cut=0.5)
    + _twin(ASHEN + "plants/ashenbush0/ashenbush0.mdx", ROCKS_H[7], 720, 1640, scale=0.28, horde_scale=0.34,
            team=False, name="scrub", cut=0.5)
)

WG_ROOF_PROPS = (
    # Silverwing Hold's towers at its front corners; the Lumber Mill's watch
    # towers at its.
    _twin(SILVER + "silvermoontowerdoodadsmedium/silvermoontowerdoodadsmedium.mdx", ORC + "watchtower/watchtower.mdx",
          112, 1722, scale=0.26, horde_scale=0.34, recolor=NIGHTELF_ROOFS, name="tower")
    + _twin(SILVER + "silvermoontowerdoodadsmedium/silvermoontowerdoodadsmedium.mdx", ORC + "watchtower/watchtower.mdx",
            588, 1722, scale=0.26, horde_scale=0.34, recolor=NIGHTELF_ROOFS, name="tower")
    # The Warsong Lumber Mill itself over the Horde's west hall.
    + [prop(ORC + "warmill/warmill.mdx", 806, 292, yaw=90, scale=0.38, team=HORDE_RED, name="warmill")]
)

WARSONG.update({"props": WG_FIELD_PROPS + WG_GROUND_PROPS + WG_WOODS,
                "roof_props": WG_HILL_PROPS + WG_ROOF_PROPS})

BATTLEGROUNDS = [WARSONG]
