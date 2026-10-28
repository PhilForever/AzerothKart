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

World units, bottom-left origin, one texel per unit in the pictures.
Warsong Gulch is laid out on the real gulch (version 2): the track's world
is the battleground's own ground at three units to the yard (see the
Warsong section below).
"""
import json
from pathlib import Path

from city_layouts import WALL_INSET, prop

TA = "war3.w3mod:terrainart/"
ASHEN = "war3.w3mod:doodads/ashenvale/"
SUMMER = "war3.w3mod:doodads/lordaeronsummer/"
ORC = "war3.w3mod:buildings/orc/"
SILVER = "war3.w3mod:doodads/silvermoon/structures/"

DOOR_OVERLAP = 2 * WALL_INSET
NORTH, SOUTH, EAST, WEST = (0, 1), (0, -1), (1, 0), (-1, 0)


def room(name, x0, y0, x1, y1, level=0, floor="field", cover=None, runner=None):
    """A rectangle of floor on `level`, painted in the `floor` style.
    `cover`: the roof overlay above it (a floor 0 room under a plateau or a
    roof), which fades while the player's kart is in the room. `runner`: a
    box of the side's carpet on a base's floor."""
    assert x1 - x0 > 2 * WALL_INSET and y1 - y0 > 2 * WALL_INSET, name
    assert level in (0, 1), name
    out = {"name": name, "x0": x0, "y0": y0, "x1": x1, "y1": y1, "surface": "road",
           "level": level, "floor": floor, "cover": cover}
    if runner:
        out["runner"] = tuple(runner)
    return out


def ramp(rid, name, x0, y0, x1, y1, axis, ascending, indoor=False):
    """A straight ramp from floor 0 (its low end) to floor 1 (its high end).
    `axis` "x" or "y" is the way along it; `ascending` 1 puts the low end at
    its west/south end, -1 at its east/north end. `indoor`: painted in its
    base's floor, not the ground's."""
    assert axis in ("x", "y") and ascending in (1, -1), rid
    out = {"id": rid, "name": name, "x0": x0, "y0": y0, "x1": x1, "y1": y1, "axis": axis,
           "ascending": ascending}
    if indoor:
        out["indoor"] = True
    return out


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
# Warsong Gulch, version 2: the real gulch.
#
# The owner drove version 1 (2026-10-28): "it's not really driveable - I
# mean you can drive, and try to follow the arrow, but it's not really
# intuitive unfortunately. I think you should inspect the actual warsong
# gulch in the game files or something to figure this out." Asked what
# confused him, he named all four: the arrow pointing through walls, karts
# out of sight under roofs, too many rooms and doors, unclear checkpoints;
# and he kept the lap traced on the real gulch ("Front, as traced").
#
# The world is the battleground's own ground (map PVPZone03, read from the
# owner's client with scripts/wowcasc.py), three units to the yard: a
# placement at (px east, pz south) in yards stands at X = (px - 15430) * 3,
# Y = (16182 - pz) * 3. The rooms follow the walkable ground the client's
# terrain and buildings make, widened for karts (a tunnel 12 yards wide in
# the game is 120 units here); the huts, the tunnels' mouths, the bases and
# the paths keep their places.
#
# The lap, as a flag carrier runs it:
#
# - from mid, north up the field into the Alliance tunnel's mouth, in the
#   middle of the field's north wall;
# - Silverwing Hold: the tunnel runs north under the plateau and climbs into
#   the hold (floor 1); round the flag at the flag room's middle; south down
#   the lobby, beside the tunnel, out of the front door onto the plateau;
#   east across the plateau, over the tunnel, and down the east path into
#   the field's north-east corner;
# - south down the field's east side, west of the Alliance's east hut, into
#   the Horde tunnel's mouth, in the middle of the field's south wall;
# - the Warsong Lumber Mill: the tunnel runs south under the hill into the
#   mill; round the flag; north up the west passage and west out of the side
#   door; north up the slope below the west tower into the field's
#   south-west corner;
# - north-east across the field, east of the Horde's west hut, to mid.
#
# Only Silverwing Hold has two floors: the plateau the lap crosses stands
# over its tunnel. The Lumber Mill's tunnel runs under the hill, which no
# kart drives on. Over each tunnel the ground it passes under is a roof
# picture that fades while the player's kart is in the tunnel; the bases
# themselves are drawn open, their floors in sight.
#
# Each flag is the end of the wall between the way in and the way out: the
# lap rounds it, and its gate runs from the flag to the far wall.

WG_WIDTH, WG_HEIGHT = 1024, 2048

WG_ROOMS = [
    # Floor 0: the field and the two corners the lap uses.
    room("field", 64, 660, 960, 1440),
    room("field north-east", 600, 1404, 960, 1498),          # the east path's foot
    room("field south-west", 64, 540, 420, 696),             # the slope's foot
    # Silverwing Hold: the tunnel (floor 0) under the plateau; the hold and
    # the plateau (floor 1).
    room("alliance tunnel", 462, 1404, 582, 1718, floor="tunnel", cover="alliance hill"),
    room("alliance tunnel top", 462, 1792, 582, 1920, level=1, floor="hall"),
    room("alliance flag room", 336, 1884, 582, 2036, level=1, floor="flag room"),
    room("alliance lobby", 336, 1700, 440, 1920, level=1, floor="hall", runner=(370, 1700, 406, 1884)),
    room("alliance front yard", 290, 1636, 434, 1736, level=1, floor="plateau"),
    room("alliance plateau", 290, 1572, 840, 1672, level=1, floor="plateau"),
    # The Warsong Lumber Mill (floor 0).
    room("horde tunnel", 480, 214, 600, 696, floor="tunnel", cover="horde hill"),
    room("horde flag room", 360, 70, 620, 250, floor="flag room"),
    room("horde west passage", 360, 214, 460, 340, floor="hall", runner=(392, 232, 428, 340)),
    room("horde side door", 280, 240, 396, 340, floor="slope"),
    room("horde slope", 160, 240, 316, 600, floor="slope"),
]

WG_RAMPS = [
    # The tunnel's climb into the hold, under its south end.
    ramp("alliance_tunnel", "alliance tunnel climb", 462, 1700, 582, 1810, "y", 1, indoor=True),
    # The east path, down off the plateau.
    ramp("alliance_ramp", "alliance east path", 720, 1480, 840, 1590, "y", 1),
]

# The ground over each tunnel (see `overlay`): from the field's wall to the
# hold's climb, and to the mill.
WG_OVERLAYS = [
    overlay("alliance_hill", "alliance hill", 444, 1440, 600, 1700, ("alliance tunnel",)),
    overlay("horde_hill", "horde hill", 462, 340, 618, 660, ("horde tunnel",)),
]

# In lap order. Each tunnel's gate is its mouth; each flag's runs from the
# flag to the wall beyond it; the doors' are the doors.
WG_GATES = [
    gate("Alliance tunnel", 462, 1428, 582, 1428, NORTH),
    gate("Alliance flag", 451, 1940, 451, 2036, WEST, level=1),
    gate("Alliance front door", 336, 1730, 440, 1730, SOUTH, level=1),
    gate("Horde tunnel", 480, 672, 600, 672, SOUTH),
    gate("Horde flag", 470, 70, 470, 196, WEST),
    gate("Horde side door", 340, 240, 340, 340, WEST),
    gate("Mid", 64, 1056, 960, 1056, NORTH),
]

WG_PADS = [pad("alliance_boots", 522, 1600, 14), pad("horde_boots", 540, 480, 14)]

# The flags: each a round solid at the end of the wall it caps (the banner
# is drawn on it, scenery).
WG_FLAGS = [
    {"id": "alliance_flag", "x": 437, "y": 1912, "width": 28, "height": 28, "shape": "disc", "level": 1},
    {"id": "horde_flag", "x": 456, "y": 196, "width": 28, "height": 28, "shape": "disc", "level": 0},
]

WG_SPAWN = (522, 990, "north", 0)

# The reviewed way round (kart centres), from the grid back over mid.
WG_ROUTE = [
    (522, 990), (522, 1100), (522, 1440),                                   # north to the Alliance tunnel
    (522, 1690), (522, 1830),                                               # the tunnel, up into the hold
    (522, 1950), (500, 1985), (451, 1995), (400, 1985), (388, 1940),        # round the flag
    (388, 1860), (388, 1700),                                               # the lobby, out of the front door
    (396, 1640), (460, 1622), (780, 1622),                                  # east across the plateau
    (780, 1600), (780, 1470),                                               # down the east path
    (740, 1400), (690, 1330), (680, 1150), (600, 900), (545, 760), (540, 690),  # the field's east side
    (540, 260), (540, 200), (525, 125), (470, 110), (415, 125), (410, 200),  # the tunnel; round the flag
    (410, 290), (340, 290), (238, 290),                                     # the west passage; the side door
    (238, 560), (260, 640), (310, 720), (330, 820),                         # up the slope, past the west hut
    (430, 1000), (480, 1080), (500, 1110),                                  # over mid
]

WARSONG = {
    "id": "warsong_gulch",
    "name": "Warsong Gulch",
    "version": 2,
    "size": (WG_WIDTH, WG_HEIGHT),
    "laps": 3,
    "rooms": WG_ROOMS,
    "ramps": WG_RAMPS,
    "overlays": WG_OVERLAYS,
    "gates": WG_GATES,
    "pads": WG_PADS,
    # The flags; the scenery's solids (the huts) join them from `props`.
    "solids": WG_FLAGS,
    "spawn": WG_SPAWN,
    "route": WG_ROUTE,
}

# ---------------------------------------------------------------------------
# Warsong Gulch's painting (battleground_paint.py).
#
# The ground is the gulch's own (wow_map_survey.py measured it from the
# owner's client into warsong_gulch_survey.json: each ground texture's weight
# and the terrain's height, every four units): each client texture is drawn
# as the Warcraft III tile that stands for it (Ashenvale's on the Alliance's
# half, the Barrens' on the Horde's, as in the game), shaded by the relief.

WG_GROUND = {
    "kalidarferns_s": {"tile": TA + "ashenvale/ashen_grass.dds"},
    "ashenvaleferns_s": {"tile": TA + "ashenvale/ashen_grasslumpy.dds"},
    "alpha3ashenvaleroots_s": {"tile": TA + "ashenvale/ashen_leaves.dds"},
    "kalidarrock_s": {"tile": TA + "ashenvale/ashen_rock.dds"},
    "ashenvaleroad_s": {"tile": TA + "lordaeronsummer/lords_dirt.dds", "shade": 0.86, "boost": 2.2},
    "barrensbasedirt_s": {"tile": TA + "barrens/barrens_dirt.dds"},
    "barrensbasegrassgrey_s": {"tile": TA + "barrens/barrens_dirtgrass.dds"},
    "barrensbasegrass_s": {"tile": TA + "barrens/barrens_grass.dds"},
    "badlandsrock_s": {"tile": TA + "barrens/barrens_dirtrough.dds"},
    "barrensrocklighter_s": {"tile": TA + "barrens/barrens_rock.dds"},
    "barrensroad01_s": {"tile": TA + "barrens/barrens_desert.dds", "boost": 2.2},
}

# Each side's building and cliffs: Silverwing Hold's violet stone and pale
# flagstones; the Warsong Lumber Mill's planks and timber.
WG_SIDES = {
    "alliance": {
        "cliff": (TA + "ashenvale/ashen_cliff1.dds", (0, 0, 192, 64), (0.92, 0.96, 1.0)),
        "rock": {"tile": TA + "ashenvale/ashen_rock.dds", "shade": (0.86, 0.9, 0.98)},
        "tunnel": {"tile": TA + "barrens/barrens_dirt.dds", "shade": (0.74, 0.64, 0.58)},
        "earth": (40, 34, 36),
        "wall": {"face": (TA + "ruins/ruins_cliff1.dds", (0, 0, 192, 64), (0.92, 0.86, 1.04, 0.25)),
                 "top": (58, 50, 72), "coping": (170, 160, 196), "height": 70},
        "floor": {"tile": TA + "cityscape/city_squaretiles.dds", "shade": (0.94, 0.92, 1.02)},
        "runner": ((40, 58, 128), (196, 196, 220)),
        "lamp": (120, 160, 255),
        "portal": (150, 136, 178),
    },
    "horde": {
        "cliff": (TA + "barrens/barrens_cliff1.dds", (0, 0, 192, 64), (1.0, 0.94, 0.86)),
        "rock": {"tile": TA + "barrens/barrens_dirtrough.dds", "shade": 0.86},
        "tunnel": {"tile": TA + "barrens/barrens_dirtrough.dds", "shade": (0.8, 0.68, 0.56)},
        "earth": (44, 34, 26),
        "wall": {"face": (TA + "barrens/barrens_cliff0.dds", (0, 0, 192, 64), (0.92, 0.82, 0.7)),
                 "top": (66, 46, 30), "coping": (150, 112, 74), "height": 70},
        "floor": {"parquet": {"block": 48, "plank": 12, "colour": (140, 98, 58)}},
        "runner": ((128, 26, 20), (30, 22, 18)),
        "lamp": (255, 150, 60),
        "portal": (120, 84, 52),
    },
}

# The tunnels' mouths: the Alliance's an arch in the field's north cliff (the
# camera sees its face), the Horde's a timber lintel on the hill's edge.
WG_PORTALS = [
    {"kind": "arch", "side": "alliance", "x0": 474, "x1": 570, "y": 1440, "rise": 30},
    {"kind": "lintel", "side": "horde", "x0": 480, "x1": 600, "y": 660},
]

HORDE_RED = (0.62, 0.08, 0.06)
ALLIANCE_BLUE = (0.12, 0.3, 0.86)


def _blocks(item, kind="round"):
    item["blocks"] = kind
    return item


WARSONG.update({
    "folder": "WarsongGulch",
    "lean": 0.6, "team": ALLIANCE_BLUE, "supersample": 3,
    "replaceables": {31: "war3.w3mod:replaceabletextures/ashenvaletree/ashentree.dds",
                     32: "war3.w3mod:replaceabletextures/ashenvaletree/ashentree.dds",
                     33: "war3.w3mod:replaceabletextures/barrenstree/barrenstree.dds"},
    "survey": "warsong_gulch_survey.json",
    "ground": WG_GROUND,
    "relief": {"light": (-0.5, 0.6, 0.62), "exaggerate": 1.4, "ambient": 0.5},
    "sides": WG_SIDES,
    "portals": WG_PORTALS,
})

# ---------------------------------------------------------------------------
# Warsong Gulch's scenery.
#
# By hand: the huts on the field (solid, at the client's places), each
# flag's banner, each base's towers and the Lumber Mill. From the survey:
# every tree, bush, stump, log, stake, lamp, brazier, siege engine, barrel,
# crate, tent and watch tower the client's map places, as the Warcraft III
# model that stands for its kind, at its place, its size and (but for the
# round ones, turned at random) its turn to the nearest eighth. Survey
# scenery is `optional`: the painter leaves out any that would stand on a
# floor the camera sees, across a cover's edge or in a base's walls.

SUMMER = "war3.w3mod:doodads/lordaeronsummer/"
D3 = "war3.w3mod:doodads/"
SILVER = "war3.w3mod:doodads/silvermoon/structures/"
TREES_A = [D3 + "terrain/ashentree/ashentree%d.mdx" % n for n in (0, 2, 3, 5, 7)]
TREES_H = [D3 + "terrain/barrenstree/barrenstree%d.mdx" % n for n in (0, 2, 3, 5, 7)]
BUSH = D3 + "ashenvale/plants/ashenbush0/ashenbush0.mdx"
STUMP = D3 + "ashenvale/props/ashenhollowstump/ashenhollowstump.mdx"
LOG = D3 + "ashenvale/props/ashenlogstraight/ashenlogstraight.mdx"
STAKES = ["war3.w3mod:_de.w3mod:doodads/lordaeronsummer/structures/palisade/palisade%d.mdx" % n for n in (0, 1)]
LANTERN = SUMMER + "props/lanternpost/lanternpost0.mdx"
BRAZIER = SUMMER + "props/brazier/brazier.mdx"
CATAPULT = "war3.w3mod:units/orc/catapult/catapult.mdx"
BARRELS = "war3.w3mod:buildings/other/barrelsunit/barrelsunit.mdx"
CRATES = [SUMMER + "terrain/crates/crates%d.mdx" % n for n in (0, 1)]
TENT = "war3.w3mod:buildings/other/tent/tent.mdx"
WATCHTOWER = "war3.w3mod:buildings/orc/watchtower/watchtower.mdx"
DRY = (0.92, 0.74, 0.5)                      # a bush on the Barrens' side
# Silvermoon's teal domes and gold trim made Silverwing Hold's violet and
# silver, as Darnassus's.
NIGHTELF_ROOFS = [(150.0, 235.0, 272.0, 0.12, 1.0, 0.95), (20.0, 70.0, 250.0, 0.25, 0.25, 1.05)]

# (the client's model names starting so, the Alliance half's models, the
# Horde half's, sizes (the client's small, medium, large), round, options)
WG_KINDS = [
    (("kalidartree", "ashenvaletree"), TREES_A, TREES_A, (0.22, 0.27, 0.32), True, {"alpha_shadow": True}),
    (("barrenstree",), TREES_H, TREES_H, (0.24, 0.29, 0.34), True, {"alpha_shadow": True}),
    (("kalidarbush", "duskwoodbush", "barrensbush"), [BUSH], [BUSH], (0.15, 0.19, 0.23), True, {}),
    (("ashenvaletreestump", "stonetreestump"), [STUMP], [STUMP], (0.13, 0.16, 0.19), True, {}),
    (("stonetreelog",), [LOG], [LOG], (0.18, 0.21, 0.24), False, {}),
    (("generaloutpost", "burntoutpost"), STAKES, STAKES, (0.6, 0.72, 0.84), False, {}),
    (("kalidarstreetlamp", "nightelflantern"), [LANTERN], [LANTERN], (0.28,) * 3, False,
     {"light": (34, (80, 120, 255))}),
    (("orcbrazier", "freestandingtorch", "tallbrazier", "orcpvpbonfire"), [BRAZIER], [BRAZIER], (0.3,) * 3, False,
     {"light": (38, (255, 140, 50))}),
    (("catapult",), [CATAPULT], [CATAPULT], (0.26,) * 3, False, {}),
    (("orcbarrel",), [BARRELS], [BARRELS], (0.22,) * 3, False, {}),
    (("orccrate", "elfcrate"), CRATES, CRATES, (0.22,) * 3, False, {}),
]
WG_BUILDINGS = {"nightelftent01_pvp": (TENT, 0.22), "nightelftent02_pvp": (TENT, 0.22),
                "ctforc_aclifftower": (WATCHTOWER, 0.34)}


def _dressing():
    """The survey's placements as optional scenery (see above)."""
    from paintkit import hash2
    placements = json.loads(Path(__file__).with_name(WARSONG["survey"]).read_text(encoding="utf-8"))["placements"]
    out = []
    for kind, model, x, y, height, yaw, scale in placements:
        xi, yi = int(round(x)), int(round(y))
        if not (0 <= xi < WG_WIDTH and 0 <= yi < WG_HEIGHT):
            continue
        alliance = yi >= WG_HEIGHT // 2
        if kind == "building":
            if model not in WG_BUILDINGS:
                continue
            path, size = WG_BUILDINGS[model]
            item = prop(path, xi, yi, yaw=int(round(yaw / 45)) % 8 * 45, scale=size, name=model,
                        team=None if alliance else HORDE_RED)
        else:
            found = next((k for k in WG_KINDS if model.startswith(k[0])), None)
            if found is None:
                continue
            _, models_a, models_h, sizes, round_, options = found
            models = models_a if alliance else models_h
            path = models[hash2(xi, yi, 31) % len(models)]
            size = sizes[0] if scale < 0.85 else (sizes[1] if scale <= 1.25 else sizes[2])
            turn = hash2(xi, yi, 37) % 4 * 90 if round_ else int(round(yaw / 45)) % 8 * 45
            extra = dict(options)
            if path == BUSH and not alliance:
                extra["tint"] = DRY
            if path == CATAPULT:
                extra["team"] = ALLIANCE_BLUE if alliance else HORDE_RED
            item = prop(path, xi, yi, yaw=turn, scale=size, name=model, **extra)
        item["optional"] = True
        out.append(item)
    return out


ROCKS_H = [D3 + "barrens/rocks/barrens_rocks/barrens_rocks%d.mdx" % n for n in (1, 3, 5, 7)]


def _woods():
    """The hills' woods, which the client's map draws as one canopy: on the
    Alliance's half, Ashenvale trees wherever the ground stands 335 yards and
    up (the hills round the field; the field and the plateau lie lower or are
    floor), every 44 units, jittered; on the Horde's, a dry bush or a rock
    every 66. Optional, as the survey's scenery."""
    import base64
    import zlib
    from paintkit import hash2
    data = json.loads(Path(__file__).with_name(WARSONG["survey"]).read_text(encoding="utf-8"))
    relief = zlib.decompress(base64.b64decode(data["relief"]["texels"]))
    grid, cols = data["grid"], data["columns"]
    base, step = data["relief"]["base"], data["relief"]["step"]
    seen = [(r["x0"], r["y0"], r["x1"], r["y1"]) for r in WG_ROOMS if not r["cover"]]
    seen += [(r["x0"], r["y0"], r["x1"], r["y1"]) for r in WG_RAMPS]

    def clear(x, y, reach):
        return all(max(b[0] - x, 0, x - b[2]) ** 2 + max(b[1] - y, 0, y - b[3]) ** 2 > reach * reach for b in seen)
    out = []
    for gy in range(0, WG_HEIGHT, 44):
        for gx in range(0, WG_WIDTH, 44):
            alliance = gy >= 1100
            if not alliance and (gx // 44 + gy // 44) % 3:
                continue
            x = gx + hash2(gx, gy, 41) % 30
            y = gy + hash2(gx, gy, 43) % 30
            v = relief[(WG_HEIGHT - 1 - y) // grid * cols + x // grid]
            if v == 255 or base + v * step < 335 or not clear(x, y, 40):
                continue
            k = hash2(gx, gy, 47)
            if alliance:
                item = prop(TREES_A[k % len(TREES_A)], x, y, yaw=k // 7 % 4 * 90, scale=(0.24, 0.28, 0.32)[k // 29 % 3],
                            alpha_shadow=True, name="woods")
            elif k % 2:
                item = prop(BUSH, x, y, yaw=k // 7 % 4 * 90, scale=0.2, tint=DRY, name="scrub")
            else:
                item = prop(ROCKS_H[k // 3 % len(ROCKS_H)], x, y, yaw=k // 7 % 4 * 90, scale=0.3, cut=0.5, name="rock")
            item["optional"] = True
            out.append(item)
    return out


WG_PROPS = [
    # The huts on the field: the night elves' two on the Alliance's half, the
    # orcs' two on the Horde's, at the client's places (turned to the
    # nearest eighth).
    _blocks(prop("war3.w3mod:buildings/other/furbolghut/furbolghut.mdx", 245, 1301, yaw=90, scale=0.28,
                 solid=True, name="alliance_west_hut", team=ALLIANCE_BLUE)),
    _blocks(prop("war3.w3mod:buildings/other/furbolghut2/furbolghut2.mdx", 770, 1294, yaw=135, scale=0.28,
                 solid=True, name="alliance_east_hut", team=ALLIANCE_BLUE)),
    _blocks(prop("war3.w3mod:buildings/orc/trollburrow/trollburrow.mdx", 233, 767, yaw=315, scale=0.34,
                 solid=True, name="horde_west_hut", team=HORDE_RED)),
    _blocks(prop("war3.w3mod:buildings/orc/trollburrow/trollburrow.mdx", 847, 690, yaw=45, scale=0.34,
                 solid=True, name="horde_east_hut", team=HORDE_RED)),
    # Each flag on its dais (the dais is the solid: WG_FLAGS).
    prop(SUMMER + "props/bannerhuman/bannerhuman0.mdx", 451, 1921, yaw=270, scale=0.34, team=ALLIANCE_BLUE,
         name="alliance_banner"),
    prop(SUMMER + "props/bannerorc/bannerorc0.mdx", 470, 205, yaw=270, scale=0.34, team=HORDE_RED,
         name="horde_banner"),
    # Lamps either side of each tunnel's mouth, on the ground over the tunnel
    # (they fade with its cover): the Alliance's blue lanterns, the Horde's
    # braziers.
    prop(LANTERN, 456, 1452, scale=0.28, light=(34, (80, 120, 255)), name="alliance_mouth_lamp"),
    prop(LANTERN, 582, 1452, scale=0.28, light=(34, (80, 120, 255)), name="alliance_mouth_lamp"),
    prop(BRAZIER, 470, 640, scale=0.3, light=(38, (255, 140, 50)), name="horde_mouth_brazier"),
    prop(BRAZIER, 610, 640, scale=0.3, light=(38, (255, 140, 50)), name="horde_mouth_brazier"),
    # Silverwing Hold's towers at its corners; the Lumber Mill east of the
    # Horde's flag room, and its watch tower by the side door.
    prop(SILVER + "silvermoontowerdoodadsmedium/silvermoontowerdoodadsmedium.mdx", 300, 1760, scale=0.26,
         recolor=NIGHTELF_ROOFS, team=ALLIANCE_BLUE, name="alliance_tower"),
    prop(SILVER + "silvermoontowerdoodadsmedium/silvermoontowerdoodadsmedium.mdx", 624, 1720, scale=0.26,
         recolor=NIGHTELF_ROOFS, team=ALLIANCE_BLUE, name="alliance_tower"),
    prop(SILVER + "silvermoontowerdoodadsmedium/silvermoontowerdoodadsmedium.mdx", 316, 1996, scale=0.22,
         recolor=NIGHTELF_ROOFS, team=ALLIANCE_BLUE, name="alliance_tower"),
    prop(SILVER + "silvermoontowerdoodadsmedium/silvermoontowerdoodadsmedium.mdx", 604, 1996, scale=0.22,
         recolor=NIGHTELF_ROOFS, team=ALLIANCE_BLUE, name="alliance_tower"),
    prop("war3.w3mod:buildings/orc/warmill/warmill.mdx", 704, 196, yaw=180, scale=0.36, team=HORDE_RED,
         name="horde_warmill"),
    prop(WATCHTOWER, 352, 384, scale=0.34, team=HORDE_RED, name="horde_west_tower"),
]

WARSONG.update({"props": WG_PROPS + _dressing() + _woods(), "roof_props": []})

BATTLEGROUNDS = [WARSONG]
