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
from math import sqrt
from pathlib import Path

from city_layouts import WALL_INSET, catmull_rom, prop

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
# Warsong Gulch, version 3: the real gulch, both bases driven alike.
#
# The owner drove version 1 (2026-10-28): "it's not really driveable ... I
# think you should inspect the actual warsong gulch in the game files or
# something to figure this out." Version 2 laid the lap on the real gulch.
# Driving version 2 he corrected its Horde side: "outside ramp goes into
# lobby into flag room into tunnel down to mid". The game files put that
# outside ramp on the west of the gulch, the Alliance's on the east (the
# gulch turns half a circle into itself about its middle); shown the two
# ways the lap could then run, he chose both bases the same way round.
#
# The world is the battleground's own ground (map PVPZone03, read from the
# owner's client with scripts/wowcasc.py), three units to the yard: a
# placement at (px east, pz south) in yards stands at X = (px - 15430) * 3,
# Y = (16182 - pz) * 3. The rooms follow the walkable ground the client's
# terrain and buildings make, widened for karts (a tunnel 13 yards wide in
# the game is 120 units here); the huts, mid's stumps, the tunnels' mouths,
# the bases, the outside ramps and the paths keep their places.
#
# Each base, as a flag carrier runs it: up its outside ramp onto the
# plateau (floor 1), along the plateau over its own tunnel to the front
# yard (the Horde's graveyard beside it), in at the front door, along the
# lobby beside the tunnel, round the flag, down the tunnel's climb (floor
# 0) and out along the tunnel to its mouth on the field.
#
# The lap, a loop round mid:
#
# - from the grid east of mid, north up the field's east side, west of the
#   Alliance's east hut, to the foot of the east path;
# - Silverwing Hold: up the east path, west along the plateau, north in at
#   the front door, up the lobby, round the flag (east), down the climb and
#   south out of the tunnel's mouth in the middle of the field's north wall;
# - south-west down the field's west side, west of mid's stumps and east of
#   the Horde's west hut, to the foot of the west path;
# - the Warsong Lumber Mill, the same way round: up the west path, east
#   along the plateau, south in at the front door, down the lobby, round
#   the flag (west), down the climb and north out of the tunnel's mouth in
#   the middle of the field's south wall;
# - north-east to the finish, from mid's stumps to the field's east wall.
#
# Over each tunnel the ground it passes under is a cover picture that fades
# while the player's kart is in the tunnel; the plateau runs over it. The
# bases are drawn open, their floors in sight. Each flag is the end of the
# wall between the lobby and the tunnel's top: the lap rounds it, and its
# gate runs from the flag to the far wall.
#
# The Horde's base is the Alliance's turned half a circle (mirror()) about
# (531, 1030.5): the flags' middle, nine units west so that it stands on the
# Horde's tunnel. The field is not quite so turned (the tunnels' mouths lie
# 18 units north of it), so the Horde's tunnel, its cover and the west
# path's foot are laid as the field meets them.

WG_WIDTH, WG_HEIGHT = 1024, 2048
WG_TURN = (1062, 2061)


def _horde(item):
    """The Alliance's `item` turned into the Horde's (see above)."""
    names = {"alliance east path": "horde west path"}

    def rename(name):
        return names.get(name, name.replace("alliance", "horde").replace("Alliance", "Horde"))
    out = mirror(item, *WG_TURN, rename)
    if isinstance(out, dict) and out.get("runner"):
        x0, y0, x1, y1 = item["runner"]
        out["runner"] = (WG_TURN[0] - x1, WG_TURN[1] - y1, WG_TURN[0] - x0, WG_TURN[1] - y0)
    return out


# Silverwing Hold: the tunnel (floor 0) under the plateau; the hold, its
# front yard and the plateau (floor 1).
WG_ALLIANCE_BASE = [
    room("alliance tunnel top", 462, 1792, 582, 1920, level=1, floor="hall"),
    room("alliance flag room", 336, 1884, 582, 2036, level=1, floor="flag room"),
    room("alliance lobby", 336, 1700, 440, 1920, level=1, floor="hall", runner=(370, 1700, 406, 1884)),
    room("alliance front yard", 290, 1636, 434, 1736, level=1, floor="plateau"),
    room("alliance plateau", 290, 1572, 840, 1672, level=1, floor="plateau"),
]

WG_ROOMS = [
    # Floor 0: the field and the outside ramps' feet.
    room("field", 64, 660, 960, 1440),
    room("field north-east", 600, 1404, 960, 1498),          # the east path's foot
    room("field south-west", 64, 563, 462, 696),             # the west path's foot
    room("alliance tunnel", 462, 1404, 582, 1718, floor="tunnel", cover="alliance hill"),
    *WG_ALLIANCE_BASE,
    room("horde tunnel", 480, 343, 600, 696, floor="tunnel", cover="horde hill"),
    *[_horde(r) for r in WG_ALLIANCE_BASE],
]

WG_ALLIANCE_RAMPS = [
    # The tunnel's climb into the hold, under its south end.
    ramp("alliance_tunnel", "alliance tunnel climb", 462, 1700, 582, 1810, "y", 1, indoor=True),
    # The east path, up onto the plateau.
    ramp("alliance_ramp", "alliance east path", 720, 1480, 840, 1590, "y", 1),
]
WG_RAMPS = WG_ALLIANCE_RAMPS + [_horde(r) for r in WG_ALLIANCE_RAMPS]

# The ground over each tunnel (see `overlay`): from the field's wall to the
# climb.
WG_OVERLAYS = [
    overlay("alliance_hill", "alliance hill", 444, 1440, 600, 1700, ("alliance tunnel",)),
    overlay("horde_hill", "horde hill", 462, 361, 618, 660, ("horde tunnel",)),
]

# In lap order. Each base's: its front door, its flag (from the flag to the
# far wall), its tunnel's mouth; the finish last, from mid's stumps to the
# field's east wall (build_battlegrounds.geometry lays it across the
# stumps' middle).
WG_ALLIANCE_GATES = [
    gate("Alliance front door", 336, 1730, 440, 1730, NORTH, level=1),
    gate("Alliance flag", 451, 1940, 451, 2036, EAST, level=1),
]
WG_GATES = WG_ALLIANCE_GATES + [gate("Alliance tunnel", 462, 1428, 582, 1428, SOUTH)] \
    + [_horde(g) for g in WG_ALLIANCE_GATES] + [gate("Horde tunnel", 480, 672, 600, 672, NORTH),
                                               gate("Mid", 960, 1028, 600, 1028, NORTH)]

WG_PADS = [pad("alliance_boots", 522, 1600, 14)]
WG_PADS.append(_horde(WG_PADS[0]))

# The flags: each a round solid at the end of the wall it caps (the banner
# is drawn on it, scenery).
WG_FLAGS = [{"id": "alliance_flag", "x": 437, "y": 1912, "width": 28, "height": 28, "shape": "disc", "level": 1}]
WG_FLAGS.append(_horde(WG_FLAGS[0]))

WG_SPAWN = (680, 960, "north", 0)

# The reviewed way round (kart centres), from the grid back over the finish.
WG_ALLIANCE_ROUTE = [
    (780, 1470), (780, 1600), (780, 1622), (460, 1622), (396, 1640),        # up the east path, along the plateau
    (388, 1700), (388, 1860), (388, 1940),                                  # in at the front door, up the lobby
    (400, 1985), (451, 1995), (500, 1985), (522, 1950),                     # round the flag
    (522, 1830), (522, 1690), (522, 1440),                                  # down the climb and the tunnel
]
WG_ROUTE = (
    [(680, 960), (685, 1100), (690, 1330), (740, 1400)]                     # up the field's east side
    + WG_ALLIANCE_ROUTE
    + [(522, 1380), (500, 1300), (440, 1150), (420, 1030), (380, 900),      # down the west side, past mid
       (330, 780), (300, 680)]                                              # and the Horde's west hut
    + [_horde(p) for p in WG_ALLIANCE_ROUTE]                                # the Lumber Mill, the same way round
    + [(540, 700), (570, 780), (630, 880), (680, 980), (685, 1100)]         # to the finish
)

WARSONG = {
    "id": "warsong_gulch",
    "name": "Warsong Gulch",
    "version": 3,
    "size": (WG_WIDTH, WG_HEIGHT),
    "laps": 3,
    "rooms": WG_ROOMS,
    "ramps": WG_RAMPS,
    "overlays": WG_OVERLAYS,
    "gates": WG_GATES,
    "pads": WG_PADS,
    # The flags; the scenery's solids (mid's stumps, the huts) join them
    # from `props`.
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
    # Mid: the stumps in the middle of the field, which the lap passes on
    # either side (north on the east, south on the west).
    _blocks(prop(ASHEN + "props/ashenhollowstump/ashenhollowstump.mdx", 550, 1028, yaw=225, scale=0.62,
                 solid=True, name="mid_stumps")),
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
    prop(SUMMER + "props/bannerorc/bannerorc0.mdx", 611, 130, yaw=270, scale=0.34, team=HORDE_RED,
         name="horde_banner"),
    # Lamps either side of each tunnel's mouth, on the ground over the tunnel
    # (they fade with its cover): the Alliance's blue lanterns, the Horde's
    # braziers.
    prop(LANTERN, 456, 1452, scale=0.28, light=(34, (80, 120, 255)), name="alliance_mouth_lamp"),
    prop(LANTERN, 582, 1452, scale=0.28, light=(34, (80, 120, 255)), name="alliance_mouth_lamp"),
    prop(BRAZIER, 470, 640, scale=0.3, light=(38, (255, 140, 50)), name="horde_mouth_brazier"),
    prop(BRAZIER, 610, 640, scale=0.3, light=(38, (255, 140, 50)), name="horde_mouth_brazier"),
    # Silverwing Hold's towers at its corners; the Lumber Mill's saw house
    # east of its lobby, and its watch tower below the plateau.
    prop(SILVER + "silvermoontowerdoodadsmedium/silvermoontowerdoodadsmedium.mdx", 300, 1760, scale=0.26,
         recolor=NIGHTELF_ROOFS, team=ALLIANCE_BLUE, name="alliance_tower"),
    prop(SILVER + "silvermoontowerdoodadsmedium/silvermoontowerdoodadsmedium.mdx", 624, 1720, scale=0.26,
         recolor=NIGHTELF_ROOFS, team=ALLIANCE_BLUE, name="alliance_tower"),
    prop(SILVER + "silvermoontowerdoodadsmedium/silvermoontowerdoodadsmedium.mdx", 316, 1996, scale=0.22,
         recolor=NIGHTELF_ROOFS, team=ALLIANCE_BLUE, name="alliance_tower"),
    prop(SILVER + "silvermoontowerdoodadsmedium/silvermoontowerdoodadsmedium.mdx", 604, 1996, scale=0.22,
         recolor=NIGHTELF_ROOFS, team=ALLIANCE_BLUE, name="alliance_tower"),
    prop("war3.w3mod:buildings/orc/warmill/warmill.mdx", 830, 230, yaw=180, scale=0.36, team=HORDE_RED,
         name="horde_warmill"),
    prop(WATCHTOWER, 352, 320, scale=0.34, team=HORDE_RED, name="horde_west_tower"),
]

WARSONG.update({"props": WG_PROPS + _dressing() + _woods(), "roof_props": []})

# ---------------------------------------------------------------------------
# Arathi Basin: a circuit round the basin, on one floor.
#
# The owner (2026-10-28), with his way round drawn on the basin's map: "Let's
# take what we learned creating this map and make Arathi Basin. (No insides
# here but heavy slopes)", and asked which way: "East > DOWN to Gold Mine >
# Up to the stables > UP to the Lumbermill and then down to the farm and
# around".
#
# The world is the basin's own ground (map PVPZone04, read from the owner's
# client with scripts/wowcasc.py and measured by wow_map_survey.py into
# arathi_basin_survey.json), three units to the yard as Warsong Gulch's: a
# placement at (px east, pz south) in yards stands at X = (px - 15760) * 3,
# Y = (16450 - pz) * 3, over 2048 x 2048 units.
#
# A Battlegrounds Cup circuit is a city circuit (Circuit.lua, the Capital
# Cities Cup's street rules: the karts' centres keep within WALL_RADIUS of the
# course, full grip to the walls) laid on the basin's real roads (the
# client's road texture, "rubble", traced from the survey), widened for karts:
#
# - the grid on the east road just north of its junction with the farm road
#   (the owner's X lies on the road from there to Defiler's Den), facing up
#   the road, the finish line behind it;
# - north up the east road and over the east bridge, past the pond to the
#   river road's fork, then down the Gold Mine's road along the lake's west
#   shore into the mine's hollow (the lap's lowest ground, 110 yards below
#   the basin's datum) and through its yard past the mine's mouth;
# - up the north road to the Stables (50 yards up): round the barn either
#   way, by the road to Trollbane Hall and down the west road, or by the yard
#   between the barn and the river (narrower, shorter);
# - over the west bridge, down the west road to its fork, and up the hill on
#   the Lumber Mill's road (60 yards up in under 200), along the cliff top
#   past the mill;
# - down the escarpment (70 yards in 160) to the junction at the south
#   bridge (the road over it to the Blacksmith stays shut), sharp back east
#   along the farm road past the Farm and round to the finish.
#
# The bridges are narrows (their decks, BRIDGE_RADIUS); the ground the
# course runs over gives the painted relief and each centerline point's
# height (the inert `elevation` data of ADR 0015: the slopes are drawn, not
# yet felt).

AB_SIZE = (2048, 2048)
AB_ORIGIN = (15760.0, 16450.0)
AB_LOOP = [
    # The east road, north from the grid to the east bridge.
    (1648, 560), (1650, 610), (1640, 655), (1616, 698), (1595, 735), (1586, 775), (1584, 815), (1582, 858),
    # Past the pond to the river road's fork; down the Gold Mine's road, west of the lake.
    (1574, 900), (1548, 936), (1514, 970), (1481, 1010), (1456, 1058), (1438, 1116), (1428, 1182),
    (1421, 1250), (1417, 1318), (1411, 1384), (1400, 1446),
    # Through the mine's hollow and its yard.
    (1384, 1508), (1362, 1568), (1330, 1622), (1285, 1663), (1225, 1693), (1158, 1716),
    # Up the north road to the Stables.
    (1088, 1738), (1018, 1761), (948, 1785), (878, 1803), (808, 1807), (738, 1793), (670, 1770), (612, 1755),
    # North of the barn on the road to Trollbane Hall, then down the west road.
    (550, 1774), (480, 1806), (410, 1838), (340, 1860), (284, 1858), (247, 1822), (232, 1768), (230, 1706),
    (233, 1645), (239, 1595),
    # The west bridge; the west road to its fork.
    (242, 1548), (242, 1505), (241, 1460), (248, 1412), (268, 1365), (293, 1325), (315, 1280), (328, 1230),
    (333, 1180),
    # Up the hill, along the cliff top past the Lumber Mill (version 2: the
    # street's north-east fence at the brink, the cliff face beyond it).
    (325, 1140), (295, 1110), (262, 1080), (243, 1040), (238, 995), (248, 948), (270, 905), (296, 860),
    (322, 818), (342, 770), (374, 726), (414, 694), (452, 663), (478, 622), (518, 590), (556, 558), (612, 546),
    # Down the escarpment to the junction at the south bridge.
    (670, 537), (728, 519), (795, 510), (852, 507), (895, 530), (920, 575), (937, 620), (948, 655), (955, 685),
    # Sharp back east along the farm road, past the Farm to the finish.
    (985, 675), (1030, 645), (1078, 612), (1128, 578), (1180, 552), (1235, 530), (1292, 506), (1347, 482),
    (1400, 463), (1458, 449), (1517, 441), (1573, 441), (1614, 456), (1638, 490),
]
AB_BRIDGE_RADIUS = 42
# The bridges on the course: their decks' ends (a short abutment onto either
# bank), the road straight across and AB_APPROACH units either side, where
# it narrows to the deck's width (so the road's full width never reaches the
# water beside a deck).
AB_BRIDGES = [("east bridge", (1586, 752), (1582, 868)), ("west bridge", (242, 1578), (241, 1458))]
AB_APPROACH = 84


def _ab_line():
    from city_layouts import arc_at, straighten
    line = catmull_rom(AB_LOOP, step=16.0)
    for _name, a, b in AB_BRIDGES:
        at = (arc_at(line, *a, to_world=_world) + arc_at(line, *b, to_world=_world)) / 2
        length = sqrt((b[0] - a[0]) ** 2 + (b[1] - a[1]) ** 2)
        line = straighten(line, at, length + 40)
    return line


def _world(x, y):
    return x, y


ARATHI_LINE = _ab_line()


def _ab_arc(x, y):
    from city_layouts import arc_at
    return arc_at(ARATHI_LINE, x, y, to_world=_world)


def _nearest(line, x, y):
    return min(line, key=lambda p: (p[0] - x) ** 2 + (p[1] - y) ** 2)


# The Stables' yard (a plaza), from the north road to the west road's foot
# by the bridge and down to the river: the barn stands in it (a solid), so a
# kart goes round it either way, by the road north of it or across the yard.
# Version 2: the yard is a meadow (slow grass, Circuit.lua's grass plaza).
AB_YARD_RADIUS = 96
AB_YARD = [((520, 1696), (300, 1690))]

# In lap order, each across the course where it passes the base it is named
# for; the finish (named for the Horde's base, down the road behind the
# grid) last.
AB_GATES = [
    ("Gold Mine", (1250, 1680)),
    ("Stables", (662, 1767)),
    ("Lumber Mill", (498, 606)),
    ("Farm", (1400, 463)),
    ("Defiler's Den", (1649, 566)),
]


def _ab_gates():
    from city_layouts import gate_on
    return [gate_on(name, ARATHI_LINE, x, y) for name, (x, y) in AB_GATES]


AB_SPAWN = _nearest(ARATHI_LINE, 1647, 625)

ARATHI = {
    "id": "arathi_basin",
    "name": "Arathi Basin",
    "version": 3,
    "kind": "circuit",
    "size": AB_SIZE,
    "laps": 3,
    "centerline": ARATHI_LINE,
    "branches": [],
    # The Stables' yard is a meadow (version 2, the owner): slow grass all
    # round the barn, a shortcut from the gate to the west bridge that pays
    # only with a boost; the road round north of the barn keeps full speed.
    "plazas": [{"ax": a[0], "ay": a[1], "bx": b[0], "by": b[1], "radius": AB_YARD_RADIUS, "surface": "grass"}
               for a, b in AB_YARD],
    "narrows": [{"name": name, "from": round(_ab_arc(*a) - AB_APPROACH, 1), "to": round(_ab_arc(*b) + AB_APPROACH, 1),
                 "wall_radius": AB_BRIDGE_RADIUS} for name, a, b in AB_BRIDGES],
    "gates": _ab_gates(),
    "spawn": AB_SPAWN + ("north",),
    "solids": [],
    "full_speed_to_walls": True,
    "wall_clearance": 14,
    "survey": "arathi_basin_survey.json",
}

BATTLEGROUNDS = [WARSONG, ARATHI]

# ---------------------------------------------------------------------------
# Arathi Basin's painting (battleground_paint.build_circuit).
#
# The ground is the basin's own (arathi_basin_survey.json): each of the
# client's six Arathi Highlands textures drawn as the Warcraft III tile that
# stands for it (Lordaeron's summer grass made the Highlands' olive, its dirt
# and rough dirt for the roads, its rock, the village's crops for the Farm's
# fields), shaded by the relief (evened, the hollows a little darker); the
# river and pools by their measured depth. The street: a dirt road down its
# middle with grass to a timber rail fence; stone decks and parapets on the
# bridges and along the water.

AB_GROUND = {
    "arathihighlandsgrassbase_s": {"tile": TA + "lordaeronsummer/lords_grass.dds", "shade": (1.9, 1.38, 0.8, 0.38)},
    "arathihighlandsgrasshighlight_s": {"tile": TA + "lordaeronsummer/lords_grass.dds",
                                        "shade": (2.15, 1.56, 0.86, 0.38)},
    "arathihighlandsdirt_s": {"tile": TA + "lordaeronsummer/lords_dirt.dds", "shade": (0.8, 0.88, 0.96, 0.6)},
    "arathihighlandsrockbase_s": {"tile": TA + "lordaeronsummer/lords_rock.dds", "shade": (0.9, 0.93, 0.98, 0.2)},
    "arathihighlandsrubblebase_s": {"tile": TA + "lordaeronsummer/lords_dirtrough.dds",
                                    "shade": (0.98, 1.06, 1.16, 0.45), "boost": 2.0},
    "arathihighlandscropbase_s": {"tile": TA + "village/village_crops.dds", "shade": (1.8, 1.7, 1.5)},
}

ARATHI.update({
    "folder": "ArathiBasin",
    "lean": 0.6, "team": (0.5, 0.48, 0.44), "supersample": 3,
    "replaceables": {31: "war3.w3mod:replaceabletextures/lordaerontree/lordaeronsummertree.dds"},
    "ground": AB_GROUND,
    "relief": {"light": (-0.5, 0.6, 0.62), "exaggerate": 1.7, "ambient": 0.42, "smooth": 3, "height_tint": 0.18},
    "water": {"shallow": (78, 104, 98), "deep": (30, 50, 62), "bank": (120, 120, 96), "shore": 0.35, "full": 8.0,
              "rim": 0.9, "smooth": 2},
    "course": {
        "road": {"tile": TA + "lordaeronsummer/lords_dirtrough.dds", "shade": (0.98, 1.06, 1.16, 0.45)},
        "verge": {"tile": TA + "lordaeronsummer/lords_grass.dds", "shade": (1.9, 1.38, 0.8, 0.38)},
        "yard": {"tile": TA + "lordaeronsummer/lords_dirtrough.dds", "shade": (0.98, 1.06, 1.16, 0.45)},
        "deck": {"tile": TA + "village/village_stonepath.dds", "shade": (1.5, 1.55, 1.7, 0.5)},
        "road_half": 50, "rut": (24, 3),
    },
    "street_reach": 24, "street_far": 240,
    "decks": [(a, b) for _name, a, b in AB_BRIDGES],
    "fences": {"models": ("westfallfence", "gatesegment", "gatepost"), "link": 13.5},
    # The two bridges the course does not cross (the roads to the Blacksmith),
    # as the client's map lays them.
    "bridges": [{"a": (920, 1473), "b": (920, 1578), "width": 46}, {"a": (955, 750), "b": (932, 852), "width": 46}],
    "wall": {"thickness": 4},
    "rope_fence": {"land": {"every": 30, "post": 5, "post_height": 22, "ropes": [(16.0, 0.0), (9.0, 0.0)],
                            "rope_rows": 2},
                   "field": {"every": 12, "post": 3, "post_height": 16, "ropes": [(11.0, 0.0), (6.0, 0.0)],
                             "rope_rows": 2},
                   "post": ((112, 80, 50), (150, 112, 72), (58, 40, 24)),
                   "rope": ((156, 118, 74), (88, 62, 38))},
})

# ---------------------------------------------------------------------------
# Arathi Basin's scenery: the bases' buildings by hand at the client's
# places (Warcraft III's that stand for them), every node's flag beside the
# course, and the survey's trees, bushes, fences, hay, carts, crates and
# graves as optional scenery (left out where they would stand on the street).

HUMAN = "war3.w3mod:buildings/human/"
OTHER = "war3.w3mod:buildings/other/"
AB_PROPS = [
    prop(SUMMER + "structures/barn/barn.mdx", 357, 1704, yaw=225, scale=0.3, solid=True, margin=6, name="stables"),
    prop(OTHER + "goldmine/goldmine.mdx", 1490, 1730, yaw=225, scale=0.46, name="gold_mine"),
    prop(HUMAN + "humanlumbermill/humanlumbermill.mdx", 312, 548, yaw=225, scale=0.38, name="lumber_mill"),
    prop(HUMAN + "farm/farm.mdx", 1400, 628, yaw=270, scale=0.5, name="farm"),
    # The Farm's windmill and granary, at the client's windmill and north of
    # its silo (which stands on the course).
    dict(prop(SUMMER + "structures/windmill/windmill.mdx", 1496, 688, yaw=225, scale=0.34, name="farm_windmill"),
         nudge=True),
    dict(prop(SUMMER + "structures/granary/granary.mdx", 1530, 610, yaw=270, scale=0.3, name="farm_granary"),
         nudge=True),
    prop(HUMAN + "blacksmith/blacksmith.mdx", 896, 1123, yaw=225, scale=0.44, name="blacksmith"),
    prop(HUMAN + "townhall/townhall.mdx", 96, 1990, yaw=315, scale=0.4, name="trollbane_hall", team=ALLIANCE_BLUE),
    prop(HUMAN + "townhall/townhall.mdx", 1792, 266, yaw=135, scale=0.4, name="defilers_den", team=HORDE_RED,
         tint=(0.78, 0.74, 0.8)),
]
for _name, (_x, _y) in (("stables_flag", (400, 1950)), ("lumber_mill_flag", (398, 600)),
                        ("blacksmith_flag", (780.3, 1081.1)), ("farm_flag", (1297.3, 568.6)),
                        ("gold_mine_flag", (1375.4, 1590.8))):
    AB_PROPS.append(dict(prop(SUMMER + "props/bannerhuman/bannerhuman0.mdx", _x, _y, scale=0.36, name=_name),
                         nudge=True))

ARATHI.update({"props": AB_PROPS})

# Version 2 (the owner, after driving version 1): where a real road leaves
# the course, no fence across it: the road runs on, seamless, and what
# stands in it blocks it, painted at the street's edge where the karts stop
# ("a group of angry alliance players" on the upper road above the Gold
# Mine, forcing the karts down to the mine; spilled lumber on the lower road
# under the Lumber Mill's cliff). Each opening: a road's mouth (the client's
# road texture crossing the street's edge within `reach` of `at`) and what
# stands in it (AB_BLOCKERS: model, sequence, scale, team colour).
UNITS = "war3.w3mod:units/"
AB_BLOCKERS = {
    "alliance": [(UNITS + "human/footman/footman.mdx", "Stand Defend", 0.45, ALLIANCE_BLUE),
                 (UNITS + "human/footman/footman.mdx", "Attack - 1", 0.45, ALLIANCE_BLUE),
                 (UNITS + "human/rifleman/rifleman.mdx", "Stand Ready", 0.45, ALLIANCE_BLUE),
                 (UNITS + "human/footman/footman.mdx", "Stand Defend", 0.45, ALLIANCE_BLUE),
                 (UNITS + "human/priest/priest.mdx", "Spell Attack", 0.45, ALLIANCE_BLUE)],
    "horde": [(UNITS + "orc/grunt/grunt.mdx", "Stand Ready", 0.45, HORDE_RED),
              (UNITS + "orc/grunt/grunt.mdx", "Attack - 1", 0.45, HORDE_RED),
              (UNITS + "orc/headhunter/headhunter.mdx", "stand ready", 0.45, HORDE_RED),
              (UNITS + "orc/tauren/tauren.mdx", "Stand Ready", 0.34, HORDE_RED)],
    "lumber": [(D3 + "ashenvale/props/ashenlogstraight/ashenlogstraight.mdx", "Stand", 0.11, None),
               (SUMMER + "props/haycartbroken/haycartbroken.mdx", "Stand", 0.28, None),
               (D3 + "ashenvale/props/ashenlogstraight/ashenlogstraight.mdx", "Stand", 0.13, None),
               (D3 + "ashenvale/props/ashenlogstraight/ashenlogstraight.mdx", "Stand", 0.1, None)],
    "supplies": [(BARRELS, "Stand", 0.2, None), (SUMMER + "terrain/crates/crates1.mdx", "Stand", 0.26, None),
                 (SUMMER + "props/haycartbroken/haycartbroken.mdx", "Stand", 0.28, None),
                 (SUMMER + "terrain/crates/crates0.mdx", "Stand", 0.26, None)],
}
AB_OPENINGS = [
    {"name": "the upper road above the Gold Mine", "at": (1323, 1222), "reach": 75, "blockers": "alliance",
     "spacing": 19},
    {"name": "the upper road at the Stables", "at": (720, 1682), "reach": 50, "blockers": "alliance"},
    {"name": "the road to Trollbane Hall", "at": (185, 1912), "reach": 28, "blockers": "alliance"},
    {"name": "the north road at the Stables", "at": (532, 1894), "reach": 45, "blockers": "alliance"},
    {"name": "the lower road under the Lumber Mill", "at": (392, 1066), "reach": 32, "blockers": "lumber"},
    {"name": "the lower road at the south bridge", "at": (856, 703), "reach": 32, "blockers": "lumber"},
    {"name": "the road to the Blacksmith", "at": (944, 770), "reach": 40, "blockers": "supplies"},
    {"name": "the road to Defiler's Den", "at": (1675, 378), "reach": 30, "blockers": "horde"},
]
ARATHI.update({
    "openings": AB_OPENINGS,
    "blockers": AB_BLOCKERS,
    # The client's roads off the course, drawn as the course's road.
    "survey_roads": {"plane": "arathihighlandsrubblebase_s", "smooth": 2, "threshold": 0.36, "ragged": 0.05,
                     "least": 40},
    # The drops (the owner: the Gold Mine's pit under the upper road, the
    # Lumber Mill's straight cliff down to the lower road): ground steeper
    # than 0.8 (yards per yard) a rock face, wholly from 1.5.
    "cliffs": {"from": 1.0, "full": 1.7, "smooth": 1, "strata": 1.6, "light": (-0.6, 0.8, 0.95),
               "face": (TA + "lordaeronsummer/lords_cliff0.dds", (0, 0, 192, 63), (1.06, 1.02, 1.1, 0.3)),
               "flatten": 0.3, "dark": 0.3, "bright": 0.85, "brink": (236, 230, 216), "lip": 0.55, "foot": 0.5,
               "shadow": (22, 0.42)},
})
ARATHI["relief"]["occlusion"] = {"step": 4, "reach": 256, "strength": 0.6}
ARATHI["course"]["meadow"] = {"tile": TA + "lordaeronsummer/lords_grass.dds", "shade": (1.3, 1.28, 0.66, 0.5),
                              "tuft_every": 19, "tip": (186, 194, 110), "root": (52, 74, 30)}

# Version 2, after the owner's second look ("remove the fences where the red
# line is. following the road is obvious - and the map has natural
# boundaries"): the timber fence stays only where it marks something - the
# fork above the Gold Mine beside the Alliance's group, the Stables' meadow
# and the west bridge's inner end, the home straight's Farm side from the
# finish to the east bridge, the junction under the south bridge, Trollbane's
# corner, Defiler's road and the bridges' ends. Elsewhere the street's edge
# is open ground (the karts' walls stand where they did). Each stretch: a
# side of the lap ("inner" or "outer") from the loop segment nearest one
# point to the one nearest another, in the course's order.
AB_OPEN_EDGES = [
    ("inner", (962, 684), (1649, 569)),       # the south bridge's junction past the Farm to the finish
    ("inner", (1582, 851), (1431, 1157)),     # the east bridge to the fork above the Gold Mine
    ("inner", (1412, 1376), (729, 1790)),     # the fork round under the Gold Mine to the Stables' meadow
    ("inner", (242, 1498), (940, 629)),       # the west bridge past the Lumber Mill to the south bridge's junction
    ("outer", (1628, 471), (1590, 782)),      # Defiler's road past the finish to the east bridge
    ("outer", (1579, 879), (290, 1860)),      # the east bridge round the Gold Mine and along the top to Trollbane's
    ("outer", (252, 1829), (240, 1541)),      # Trollbane's corner to the west bridge
    ("outer", (242, 1483), (1608, 452)),      # the west bridge round the Lumber Mill and the bottom to Defiler's road
]
ARATHI["open_edges"] = AB_OPEN_EDGES
# Beyond an open edge, where the ground is grass: the long grass the verge's
# mowing stops at, a little darker toward the edge and tufted, so a kart's
# reach still shows (battleground_paint.paint_wild_edges).
ARATHI["course"]["wild"] = {"planes": ("arathihighlandsgrassbase_s", "arathihighlandsgrasshighlight_s",
                                       "arathihighlandscropbase_s"),
                            "least": 0.5, "reach": 9, "shade": 64, "tuft_every": 15,
                            "tip": (186, 194, 110), "root": (52, 74, 30)}

# The survey's scenery: (the client's model names starting so, the Warcraft
# III models that stand for them, sizes (the client's small, medium, large),
# round (turned at random to a quarter) or turned as placed (to the nearest
# eighth), options). The field fences are drawn along their own line
# (ARATHI["fences"]); the river's weed, fish and floating wreckage, the tools
# and the rest are left out, as is anything standing in the water.
LORDAERON_TREES = [D3 + "terrain/lordaerontree/lordaerontree%d.mdx" % n for n in range(10)]
ARATHI_OLIVE = (0.86, 0.9, 0.5)                 # a bush the Highlands' olive
AB_KINDS = [
    (("arathitree0", "duskwoodbrowntree", "duskwoodspookytree"), LORDAERON_TREES, (0.22, 0.27, 0.32), True,
     {"alpha_shadow": True}),
    (("alteracshrub", "lochmodanshrub", "lochmodanshurb", "duskwoodbush", "duskwoodspookybush", "feralasferns",
      "lochtallgrass"), [BUSH], (0.13, 0.17, 0.21), True, {"tint": ARATHI_OLIVE}),
    (("haystack", "shadowfanghaypile", "duskwoodhaystack"), [SUMMER + "props/hay/hay%d.mdx" % n for n in range(5)],
     (0.24, 0.28, 0.32), True, {}),
    (("westfallwagon", "badlandssunkenwagon", "westfallhaywagon", "brokencart"), [SUMMER + "props/haycart/haycart.mdx"],
     (0.3,) * 3, False, {}),
    (("westfallbarrel", "barrel01", "brokenbarrel", "oildrum"), [BARRELS], (0.2,) * 3, True, {}),
    (("stormwindcrate", "replacecrate", "crate0", "westfallcrate", "graincrate", "crategrain"), CRATES, (0.24,) * 3,
     False, {}),
    (("tombstone",), [SUMMER + "props/grave/grave.mdx"], (0.26,) * 3, False, {}),
    (("elwynncliffrock", "arathirock", "duskwoodrockwall", "rockwallend"),
     [SUMMER + "rocks/lords_rock/lords_rock%d.mdx" % n for n in range(10)], (0.3, 0.36, 0.42), True, {"cut": 0.5}),
    (("arathistump", "stonetreelog"), [STUMP], (0.14, 0.17, 0.2), True, {}),
    (("caveminewheelbarrow", "caveminecar"), [SUMMER + "props/wheelbarrel/wheelbarrel.mdx"], (0.3,) * 3, False, {}),
    (("generallantern",), [LANTERN], (0.28,) * 3, False, {}),
    (("westfallscarecrow",), [SUMMER + "props/bannerhuman/bannerhuman1.mdx"], (0.3,) * 3, False, {}),
]


def _ab_dressing():
    """The survey's placements as optional scenery (see above)."""
    from paintkit import hash2
    placements = json.loads(Path(__file__).with_name(ARATHI["survey"]).read_text(encoding="utf-8"))["placements"]
    out = []
    for kind, model, x, y, height, yaw, scale in placements:
        xi, yi = int(round(x)), int(round(y))
        if kind != "doodad" or not (0 <= xi < AB_SIZE[0] and 0 <= yi < AB_SIZE[1]):
            continue
        found = next((k for k in AB_KINDS if model.startswith(k[0])), None)
        if found is None:
            continue
        _, models, sizes, round_, options = found
        path = models[hash2(xi, yi, 31) % len(models)]
        size = sizes[0] if scale < 0.85 else (sizes[1] if scale <= 1.25 else sizes[2])
        turn = hash2(xi, yi, 37) % 4 * 90 if round_ else int(round(yaw / 45)) % 8 * 45
        item = prop(path, xi, yi, yaw=turn, scale=size, name=model, **options)
        item["optional"] = True
        out.append(item)
    return out


ARATHI["props"] = AB_PROPS + _ab_dressing()


# ---------------------------------------------------------------------------
# Alterac Valley (the Battlegrounds Cup's third course; the owner, 2026-10-28:
# "Let's get started on Alterac Valley. This is going to be a long sprint.
# Starting on the horde side - no fences - but allow for driving and drifting
# a few kart lengths outside the road - after that, our regular speed
# reduction like grass", with the way drawn on the battleground's map: from
# the Horde's side by Frostwolf Keep, up the valley's road through the Field
# of Strife, to Dun Baldar).
#
# A sprint (one run, from the grid to the last gate) on the valley's own
# ground (alterac_valley_survey.json, the map PVPZone01), three units to the
# yard as Warsong Gulch's and Arathi Basin's: a placement at (px east, pz
# south) in yards stands at X = (px - 17014) * 3, Y = (18633 - pz) * 3, over
# 2048 x 7168 units (the valley's floor from Frostwolf to Dun Baldar).
#
# A Battlegrounds Cup sprint is an open circuit (Circuit.lua with `open` and
# `laps` 1) on the valley's real road (the client's road texture,
# "winterspringdirt", traced from the survey along the owner's line):
#
# - the grid east of the frozen lake below Frostwolf Keep, facing north;
# - north along the lake's shore, west on the track to the valley's road by
#   Frostwolf Village, north up the road past Coldtooth Mine's turning,
#   round Tower Point's hill and down past Iceblood Tower;
# - across the Field of Strife (its trampled middle frozen over: the owner's
#   patch of ice), past Stonehearth Outpost and up to Icewing Bunker;
# - north along the icy basin's eastern road, over the gorge on Dun Baldar's
#   bridge (a narrows) and into Dun Baldar: the finish.
#
# No street walls (the owner: "no fences"): the street is the karts' full
# grip, the road and AV_MARGIN beyond its edge (three kart lengths, packed
# snow); beyond it the snow is drivable at grass speed (Physics' grass) out
# to the valley's natural walls: its steep slopes, buildings, rocks and trees
# (`grassMap`, generated from the survey and the scenery: Circuit.lua's
# packed passability grid, as Arathi's open grass). The Field of Strife's
# ice is `iceMap` (the same packed grid): proposed to Codex as an ice
# surface (worse grip and turning, a slide); until Codex adds it, inert.

AV_SIZE = (2048, 7168)
AV_ORIGIN = (17014.0, 18633.0)
# The road's control points, traced along the client's road texture (a
# least-cost path on the survey's road weight, held near the owner's line,
# simplified), south to north.
AV_ROUTE = [
    # The grid, east of the frozen lake; north along its shore.
    (1680, 690), (1680, 749), (1680, 901), (1680, 1053), (1680, 1205), (1644, 1257), (1616, 1285),
    # West on the track to the valley's road.
    (1528, 1253), (1440, 1285), (1330, 1295), (1220, 1305),
    # North up the road past Frostwolf Village and Coldtooth Mine's turning.
    (1256, 1385), (1248, 1509), (1300, 1557), (1348, 1657), (1352, 1797), (1304, 1961), (1332, 2153),
    # Round Tower Point's hill.
    (1392, 2209), (1480, 2245), (1504, 2297), (1448, 2369), (1448, 2437), (1388, 2533), (1256, 2577),
    (1300, 2697), (1344, 2817), (1316, 2841), (1204, 2837), (1128, 2897),
    # Down past Iceblood Tower to the Field of Strife.
    (1116, 3009), (1172, 3065), (1180, 3121), (1032, 3217), (992, 3277), (980, 3398), (968, 3520),
    (956, 3641),
    # Across the Field of Strife (its frozen middle).
    (1052, 3757), (1040, 3853), (1072, 3885), (1064, 4073), (1000, 4141), (992, 4313), (960, 4333),
    # Past Stonehearth Outpost, up to Icewing Bunker.
    (904, 4453), (848, 4573), (884, 4689), (880, 4889), (1024, 4985), (1068, 5005), (1124, 4997),
    (1284, 5077), (1352, 5161), (1384, 5287), (1416, 5413),
    # North along the icy basin's eastern road.
    (1392, 5469), (1320, 5541), (1300, 5605), (1320, 5759), (1340, 5913), (1296, 5977), (1272, 6077),
    (1200, 6165), (1128, 6253), (1128, 6365), (1168, 6505), (1112, 6585), (1056, 6609),
    # Over the gorge on Dun Baldar's bridge, into Dun Baldar.
    (860, 6621), (724, 6613), (680, 6585), (544, 6565), (430, 6600), (398, 6614),
]
# Dun Baldar's bridge (the client's pvp_bridge01): its deck from bank to
# bank, straight, walled at AV_BRIDGE_RADIUS and AV_APPROACH units beyond.
AV_BRIDGE_RADIUS = 42
AV_APPROACH = 24
AV_BRIDGES = [("Dun Baldar bridge", (975, 6610), (605, 6588))]
# The karts' full grip: the road (AV_ROAD_HALF either side of its middle)
# and AV_MARGIN beyond (three kart lengths of 31 units).
AV_ROAD_HALF = 52
AV_MARGIN = 93
AV_GRIP = AV_ROAD_HALF + AV_MARGIN


def _open_arc(line, x, y):
    """Arc length along the open `line` where it passes nearest (x, y)."""
    best, at, total = None, 0.0, 0.0
    for i in range(1, len(line)):
        (ax, ay), (bx, by) = line[i - 1], line[i]
        dx, dy = bx - ax, by - ay
        length = sqrt(dx * dx + dy * dy)
        t = 0.0 if length == 0 else max(0.0, min(1.0, ((x - ax) * dx + (y - ay) * dy) / (length * length)))
        d = (ax + dx * t - x) ** 2 + (ay + dy * t - y) ** 2
        if best is None or d < best:
            best, at = d, total + length * t
        total += length
    return round(at, 1)


def _av_line():
    from city_layouts import straighten
    line = catmull_rom(AV_ROUTE, closed=False, step=16.0)
    for _name, a, b in AV_BRIDGES:
        at = (_open_arc(line, *a) + _open_arc(line, *b)) / 2
        length = sqrt((b[0] - a[0]) ** 2 + (b[1] - a[1]) ** 2)
        line = straighten(line, at, length + 2 * AV_APPROACH)
    return line


ALTERAC_LINE = _av_line()

# The gates, in the course's order, each a straight cut across the valley's
# drivable ground near a place (build_battlegrounds.sprint_gates: across the
# whole open ground there, wall to wall, so no way round it): ("y", Y) a
# line along Y crossed northwards, ("x", X) a line along X crossed westwards
# (the last stretch runs west into Dun Baldar). The last gate is the finish.
AV_GATES = [
    ("Frostwolf Village", "y", 1500),
    ("Tower Point", "y", 2470),
    ("Iceblood Tower", "y", 3060),
    ("Field of Strife", "y", 3960),
    ("Stonehearth Outpost", "y", 4720),
    ("Icewing Bunker", "y", 5400),
    ("Dun Baldar Bridge", "x", 800),
    ("Dun Baldar", "x", 430),
]
AV_SPAWN = _nearest(ALTERAC_LINE, 1680, 760)

ALTERAC = {
    "id": "alterac_valley",
    "name": "Alterac Valley",
    "version": 1,
    "kind": "sprint",
    "size": AV_SIZE,
    "laps": 1,
    "centerline": ALTERAC_LINE,
    "branches": [],
    "plazas": [],
    "narrows": [{"name": name, "from": round(_open_arc(ALTERAC_LINE, *a) - AV_APPROACH, 1),
                 "to": round(_open_arc(ALTERAC_LINE, *b) + AV_APPROACH, 1), "wall_radius": AV_BRIDGE_RADIUS}
                for name, a, b in AV_BRIDGES],
    "gate_cuts": AV_GATES,
    "spawn": AV_SPAWN + ("north",),
    "solids": [],
    "full_speed_to_walls": True,
    "road_radius": AV_GRIP, "wall_radius": AV_GRIP,
    "survey": "alterac_valley_survey.json",
}

# The valley's natural walls (build_battlegrounds.sprint_maps): ground
# steeper than `steep` yards per yard (the survey's terrain, evened once:
# where the painted cliffs are more than half a rock face), every building's
# plan and the trunks of the trees and the rocks the scenery stands there,
# each grown by the karts' inset; the street's grip (the road, its margin,
# the bridge's deck) is always open. A grid of `cell` units (Circuit.lua's
# grassMap). The ice (`iceMap`, the same grid): the Field of Strife's
# trampled middle frozen over (the survey's road texture within the field's
# box, evened, filled and grown), the one patch the owner asked for; the
# valley's other frozen ponds are snow underfoot.
ALTERAC["maps"] = {
    "cell": 8, "steep": 1.35, "smooth": 1, "trunk": 7,
    "field": {"plane": "winterspringdirt_s", "box": (560, 3560, 1320, 4500), "least": 0.3, "smooth": 4,
              "grow": 40},
}
BATTLEGROUNDS.append(ALTERAC)

# ---------------------------------------------------------------------------
# Alterac Valley's painting (battleground_paint.build_sprint).
#
# The ground is the valley's own (alterac_valley_survey.json): the client's
# snows as Warcraft III's Lordaeron winter and Northrend snow, its rocky
# patches and rock as Lordaeron winter rock, its roads as Lordaeron winter
# dirt, its ice as Northrend ice; lit by the relief from the north-west, the
# hollows darker and the sky's openness dimming the gorges. Steep ground is
# rock face (Lordaeron winter's cliff in strata). The street: the road down
# its middle, packed snow to the karts' full grip (three kart lengths beyond
# the road's edge), deep snow beyond; the ice glassy (Icecrown's) where the
# karts would slide; the frozen water as ice. In four pictures, 2048 units
# wide, south to north (the follow camera's tiles).

AV_GROUND = {
    "ironforgesnow01solid_s": {"tile": TA + "lordaeronwinter/lordw_snow.dds", "shade": (0.98, 1.0, 1.04, 0.22)},
    "winterspringsnowsolid_s": {"tile": TA + "northrend/north_snow.dds", "shade": (0.98, 1.0, 1.04, 0.22)},
    "winterspringsnowripple_s": {"tile": TA + "northrend/north_snow.dds", "shade": (0.95, 0.98, 1.04, 0.3)},
    "ironforgesnow03ripple_s": {"tile": TA + "lordaeronwinter/lordw_snow.dds", "shade": (0.95, 0.98, 1.04, 0.3)},
    "winterspringicesnowalpha_s": {"tile": TA + "northrend/north_snow.dds", "shade": (0.94, 0.98, 1.06, 0.3)},
    "ironforgefootprintsalpha_s": {"tile": TA + "lordaeronwinter/lordw_snow.dds", "shade": (0.94, 0.96, 1.0, 0.3)},
    "ironforgesnow05scrapebrown_s": {"tile": TA + "lordaeronwinter/lordw_rock.dds", "shade": (0.9, 0.9, 0.96, 0.35)},
    "deadwindpassrockbase_s": {"tile": TA + "lordaeronwinter/lordw_rock.dds", "shade": (0.82, 0.84, 0.9, 0.4)},
    "badlandsrock_s": {"tile": TA + "lordaeronwinter/lordw_rock.dds", "shade": (0.88, 0.84, 0.86, 0.4)},
    "blastedlandsrockcrackhighlight_s": {"tile": TA + "lordaeronwinter/lordw_rock.dds",
                                         "shade": (0.8, 0.82, 0.88, 0.4)},
    "winterspringdirt_s": {"tile": TA + "lordaeronwinter/lordw_dirt.dds", "shade": (1.08, 0.98, 0.9, 0.45),
                           "boost": 1.6},
    "blastedlandsdirt01_s": {"tile": TA + "lordaeronwinter/lordw_dirtrough.dds", "shade": (1.0, 0.94, 0.88, 0.45)},
    "deadwindpassdirt_s": {"tile": TA + "lordaeronwinter/lordw_dirtrough.dds", "shade": (0.96, 0.9, 0.86, 0.45)},
    "blastedlandsblack_s": {"tile": TA + "lordaeronwinter/lordw_dirtrough.dds", "shade": (0.42, 0.4, 0.4, 0.3)},
    "black_s": {"tile": TA + "lordaeronwinter/lordw_dirtrough.dds", "shade": (0.3, 0.3, 0.32, 0.3)},
    "winterspringice_s": {"tile": TA + "northrend/north_ice.dds", "shade": (1.0, 1.04, 1.06, 0.2)},
    "ironforgeice01_s": {"tile": TA + "northrend/north_ice.dds", "shade": (1.0, 1.04, 1.06, 0.2)},
    "winterspringicecracked_s": {"tile": TA + "northrend/north_ice.dds", "shade": (0.96, 1.0, 1.04, 0.2)},
    "winterspringicesmooth_s": {"tile": TA + "northrend/north_ice.dds", "shade": (1.04, 1.06, 1.08, 0.2)},
}

ALTERAC.update({
    "folder": "AlteracValley",
    "lean": 0.6, "team": (0.5, 0.5, 0.52), "supersample": 3,
    # Warcraft III's Northrend trees take their bark and needles from
    # replaceable texture 34 (31 is Lordaeron's, 32 Ashenvale's).
    "replaceables": {34: "war3.w3mod:replaceabletextures/northrendtree/northtree.dds"},
    "ground": AV_GROUND,
    "relief": {"light": (-0.5, 0.6, 0.62), "exaggerate": 1.5, "ambient": 0.48, "smooth": 3, "height_tint": 0.12,
               "occlusion": {"step": 4, "reach": 256, "strength": 0.5}},
    "cliffs": {"from": 1.0, "full": 1.7, "smooth": 1, "strata": 1.6, "light": (-0.6, 0.8, 0.95),
               "face": (TA + "lordaeronwinter/lordw_cliff0.dds", (0, 0, 192, 63), (0.86, 0.88, 0.96, 0.3)),
               "flatten": 0.3, "dark": 0.32, "bright": 0.9, "brink": (244, 246, 252), "lip": 0.6, "foot": 0.45,
               "shadow": (22, 0.38)},
    # The street's surfaces keep to the tiles' plain variations (the snow's
    # without its tufts and stones, the dirt's without its tufts): a calm
    # street against the valley's busier deep snow. The ice is Icecrown's,
    # calmed toward `glass` (by `calm` / 256), the road on through it by
    # `road` / 256. A bridge: its deck `half` either side of its line (the
    # karts' reach, 42, and half a kart), stone parapets `parapet` thick
    # (`height`, posts every `post` units `post_height`), wing walls at its
    # ends out to `wing` (where the narrows' sides stop being shut; lower,
    # `wing_height`, a post at their ends), its
    # shadow on the gorge (`shadow`: width, darkest factor) and the gorge
    # darkened and blued with its depth below the deck (`depth`: yards to
    # the darkest, tint / 256).
    "course": {
        "road": {"tile": TA + "lordaeronwinter/lordw_dirt.dds", "shade": (1.08, 0.98, 0.9, 0.45),
                 "variations": (16, 20, 24, 28, 17, 18, 21)},
        "packed": {"tile": TA + "lordaeronwinter/lordw_snow.dds", "shade": (0.86, 0.88, 0.94, 0.3),
                   "variations": (16, 20, 24, 28, 17, 21)},
        "ice": {"tile": TA + "icecrown/ice_ice.dds", "shade": (0.78, 0.92, 1.0, 0.25),
                "glass": (200, 230, 244), "calm": 150, "road": 80},
        "deck": {"tile": TA + "village/village_stonepath.dds", "shade": (1.4, 1.45, 1.6, 0.5)},
        "bridge": {"half": 50, "parapet": 6, "post": 32, "height": 10, "post_height": 16, "shadow": (28, 0.55),
                   "wing": AV_GRIP + 40, "wing_height": 7, "depth": (40, 150)},
        "road_half": AV_ROAD_HALF, "grip": AV_GRIP, "rut": (24, 3),
    },
    "wall_styles": {"bridge": ((148, 152, 162), (214, 218, 226), (84, 86, 96))},
    "street_reach": 24, "street_far": 240,
    "decks": [(a, b) for _name, a, b in AV_BRIDGES],
    "wall": {"thickness": 4},
    "tiles": [(0, 2048), (2048, 2048), (4096, 2048), (6144, 1024)],
    # The track screen's picture: the Field of Strife's square, from Iceblood
    # Garrison to Stonehearth Outpost (world rows from 3000, 2048 high).
    "preview": (3000, 2048),
    "water": {"shallow": (206, 226, 238), "deep": (132, 172, 206), "bank": (236, 242, 248), "shore": 0.35,
              "full": 8.0, "rim": 0.9, "smooth": 2},
    "survey_roads": {"plane": "winterspringdirt_s", "smooth": 2, "threshold": 0.36, "ragged": 0.05, "least": 40},
})

# ---------------------------------------------------------------------------
# Alterac Valley's scenery: the bases' and the battle's buildings by hand at
# the client's places (Warcraft III's that stand for them: Dun Baldar a
# castle, Stonehearth Outpost a keep, Frostwolf Keep an orc fortress, the
# bunkers human towers, the Horde's towers orc watch towers, Iceblood
# Garrison an orc barracks), and the survey's trees, rocks, tents, graves,
# bones, barrels and crates. Every building, rock, tent and tree trunk
# stands in the karts' way (ALTERAC["maps"]); bones, graves, barrels and
# crates do not.

HUMAN = "war3.w3mod:buildings/human/"
ORCB = "war3.w3mod:buildings/orc/"
OTHERB = "war3.w3mod:buildings/other/"
NORTHREND = D3 + "northrend/"


def _av(model, x, y, scale, yaw=270, sequence="Stand", team=None, name=None, **kw):
    item = prop(model, x, y, yaw=yaw, scale=scale, sequence=sequence, team=team, name=name, **kw)
    item["blocks_karts"] = "plan"
    item["building"] = True
    return item


AV_PROPS = [
    # Dun Baldar and its bunkers, its stable, Irondeep Mine.
    _av(HUMAN + "townhall/townhall.mdx", 200, 6705, 0.62, yaw=315, sequence="Stand Upgrade Second",
        team=ALLIANCE_BLUE, name="dun_baldar"),
    _av(HUMAN + "humantower/humantower.mdx", 547, 6708, 0.42, team=ALLIANCE_BLUE, name="dun_baldar_north_bunker"),
    _av(HUMAN + "humantower/humantower.mdx", 405, 6402, 0.42, team=ALLIANCE_BLUE, name="dun_baldar_south_bunker"),
    _av(HUMAN + "humanbarracks/humanbarracks.mdx", 167, 6498, 0.38, yaw=315, team=ALLIANCE_BLUE,
        name="dun_baldar_stable"),
    _av(OTHERB + "goldmine/goldmine.mdx", 1130, 7074, 0.46, yaw=270, name="irondeep_mine"),
    # The Stormpike lumber mill and aid station.
    _av(HUMAN + "humanlumbermill/humanlumbermill.mdx", 1717, 6166, 0.4, yaw=225, team=ALLIANCE_BLUE,
        name="stormpike_lumber_mill"),
    _av(HUMAN + "gryphonaviary/gryphonaviary.mdx", 1711, 5729, 0.38, yaw=225, team=ALLIANCE_BLUE,
        name="stormpike_aid_station"),
    # Icewing and Stonehearth Bunkers; Stonehearth Outpost and its village.
    _av(HUMAN + "humantower/humantower.mdx", 1240, 5352, 0.42, team=ALLIANCE_BLUE, name="icewing_bunker"),
    _av(HUMAN + "humantower/humantower.mdx", 1521, 4261, 0.42, team=ALLIANCE_BLUE, name="stonehearth_bunker"),
    _av(HUMAN + "townhall/townhall.mdx", 1080, 4740, 0.5, yaw=270, sequence="Stand Upgrade First",
        team=ALLIANCE_BLUE, name="stonehearth_outpost"),
    _av(HUMAN + "farm/farm.mdx", 1438, 4751, 0.42, yaw=225, name="stonehearth_house"),
    _av(HUMAN + "farm/farm.mdx", 1373, 4809, 0.36, yaw=270, name="stonehearth_hovel"),
    _av(HUMAN + "humanbarracks/humanbarracks.mdx", 1492, 4693, 0.34, yaw=225, team=ALLIANCE_BLUE,
        name="stonehearth_stable"),
    _av(HUMAN + "blacksmith/blacksmith.mdx", 1868, 4339, 0.4, yaw=225, name="stonehearth_blacksmith"),
    # The Field of Strife's south: Iceblood Garrison and its towers, the
    # Horde's camp west of the field.
    _av(ORCB + "orcbarracks/orcbarracks.mdx", 662, 3085, 0.48, yaw=270, team=HORDE_RED, name="iceblood_garrison"),
    _av(ORCB + "watchtower/watchtower.mdx", 945, 2982, 0.44, team=HORDE_RED, name="iceblood_tower"),
    _av(ORCB + "watchtower/watchtower.mdx", 834, 3488, 0.36, team=HORDE_RED, name="iceblood_watch_east"),
    _av(ORCB + "watchtower/watchtower.mdx", 459, 3515, 0.36, team=HORDE_RED, name="iceblood_watch_west"),
    _av(OTHERB + "tent/tent.mdx", 456, 4695, 0.34, yaw=225, name="field_camp_tent"),
    _av(OTHERB + "tent/tent.mdx", 517, 4800, 0.3, yaw=270, name="field_camp_tent_2"),
    # Tower Point; Coldtooth Mine.
    _av(ORCB + "watchtower/watchtower.mdx", 1248, 2394, 0.44, team=HORDE_RED, name="tower_point"),
    _av(ORCB + "watchtower/watchtower.mdx", 1500, 2622, 0.38, team=HORDE_RED, name="tower_point_watch"),
    _av(OTHERB + "goldmine/goldmine.mdx", 761, 1839, 0.46, yaw=315, name="coldtooth_mine"),
    # Frostwolf: the keep, its two towers, the village's great hall, war
    # mill, tents and the kennel by the relief hut.
    _av(ORCB + "greathall/greathall.mdx", 841, 596, 0.6, yaw=270, sequence="Stand Upgrade Second",
        team=HORDE_RED, name="frostwolf_keep"),
    _av(ORCB + "watchtower/watchtower.mdx", 958, 806, 0.44, team=HORDE_RED, name="west_frostwolf_tower"),
    _av(ORCB + "watchtower/watchtower.mdx", 1108, 791, 0.44, team=HORDE_RED, name="east_frostwolf_tower"),
    _av(ORCB + "greathall/greathall.mdx", 909, 979, 0.42, yaw=270, sequence="stand", team=HORDE_RED,
        name="frostwolf_great_hall"),
    _av(ORCB + "warmill/warmill.mdx", 1089, 948, 0.36, yaw=225, team=HORDE_RED, name="frostwolf_war_mill"),
    _av(OTHERB + "tent/tent.mdx", 943, 712, 0.32, yaw=270, name="frostwolf_tent"),
    _av(OTHERB + "tent/tent.mdx", 1215, 1034, 0.32, yaw=225, name="frostwolf_tent_2"),
    _av(OTHERB + "tent/tent.mdx", 1208, 1107, 0.32, yaw=270, name="frostwolf_tent_3"),
    _av(OTHERB + "tent/tent.mdx", 962, 1155, 0.32, yaw=315, name="frostwolf_tent_4"),
    _av(OTHERB + "tent/tent.mdx", 1137, 413, 0.32, yaw=270, name="frostwolf_tent_5"),
    _av(ORCB + "beastiary/beastiary.mdx", 1966, 914, 0.36, yaw=225, team=HORDE_RED, name="frostwolf_kennel"),
    _av(OTHERB + "tent/tent.mdx", 2005, 1000, 0.3, yaw=270, name="relief_hut_tent"),
]

NORTH_TREES = [D3 + "terrain/northrendtree/northrendtree%d.mdx" % n for n in range(10)]
NORTH_ROCKS = [NORTHREND + "rocks/north_rocks/north_rocks%d.mdx" % n for n in range(10)]
NORTH_THORNS = [NORTHREND + "plants/north_thorns/north_thorns%d.mdx" % n for n in range(7)]
NORTH_BONES = [NORTHREND + "props/north_bones/north_bones%d.mdx" % n for n in range(10)]
NORTH_GRAVES = [NORTHREND + "props/northrendtombstone/northrendtombstone%d.mdx" % n for n in range(3)]
# (the client's model names starting so, the Warcraft III models that stand
# for them, sizes (small, medium, large), round (turned at random), options,
# what stands in the karts' way: a tree's trunk, a model's plan, or nothing).
AV_KINDS = [
    (("ironforgesnowtree", "wintertree", "wintersmalltree", "ironforgetree", "ironforgepine", "winterspringtree",
      "wintermidtree", "newwinterspringtree", "burntstonetree", "stonetree0"), NORTH_TREES, (0.22, 0.28, 0.34),
     True, {"alpha_shadow": True}, "trunk"),
    (("winterspringrock", "snowytowerrock", "desolacerock", "elwynnrock", "ironforgecliff"), NORTH_ROCKS,
     (0.28, 0.34, 0.4), True, {}, "plan"),
    (("orctent", "gnolltent", "durotarorctent", "excavationtent"), [TENT], (0.24, 0.28, 0.32), False, {}, "plan"),
    (("winterspringbush", "ironforgebush", "ironforgeangledbush", "ironforgesnowybush"), NORTH_THORNS,
     (0.2, 0.24, 0.28), True, {}, None),
    (("ironstump", "stonetreelog", "winterspringfallen"), [STUMP], (0.14, 0.17, 0.2), True, {}, None),
    (("tombstone", "cemetarygate"), NORTH_GRAVES, (0.24, 0.28, 0.32), False, {}, None),
    (("blastedlandsbone", "blastedlandsskull", "blastedlandsspine", "bone0", "dwarvebone", "kotobeastbone",
      "battlegladebones", "battlegladeskull", "battlegladebskeleton", "corpseskeleton", "westfallskeleton",
      "tigerskull", "boarskull", "tallstriderskull"), NORTH_BONES, (0.2, 0.24, 0.28), True, {}, None),
    (("orcbarrel", "westfallbarrel", "barrel0", "brokenbarrel", "powderkeg", "beerkeg"), [BARRELS],
     (0.18, 0.2, 0.22), True, {}, None),
    (("orccrate", "replacecrate", "stormwindcrate", "westfallcrate", "crate0", "crategrain"), CRATES,
     (0.22, 0.24, 0.26), False, {}, None),
    (("generaltorch", "tallbrazier", "lochlamppost", "generallantern"), [LANTERN], (0.26,) * 3, False, {}, None),
]
# Scenery keeps this far from the course's middle (beyond the karts' full
# grip): the street is clear for the drift the owner asked for.
AV_CLEAR = AV_GRIP + 34


def _route_distance(x, y):
    best = None
    for i in range(1, len(ALTERAC_LINE)):
        (ax, ay), (bx, by) = ALTERAC_LINE[i - 1], ALTERAC_LINE[i]
        if abs(ax - x) > 600 and abs(bx - x) > 600 or abs(ay - y) > 600 and abs(by - y) > 600:
            continue
        dx, dy = bx - ax, by - ay
        length = dx * dx + dy * dy
        t = 0.0 if length == 0 else max(0.0, min(1.0, ((x - ax) * dx + (y - ay) * dy) / length))
        d = (ax + dx * t - x) ** 2 + (ay + dy * t - y) ** 2
        if best is None or d < best:
            best = d
    return sqrt(best) if best is not None else 1e9


def _av_dressing():
    """The survey's placements as scenery: away from the course's middle
    (AV_CLEAR), each as its kind's model (AV_KINDS). The build leaves out
    any drawn over the street or standing in the client's water
    (battleground_sprint.sprint_props)."""
    from paintkit import hash2
    survey = json.loads(Path(__file__).with_name(ALTERAC["survey"]).read_text(encoding="utf-8"))
    out = []
    for kind, model, x, y, height, yaw, scale in survey["placements"]:
        xi, yi = int(round(x)), int(round(y))
        if kind != "doodad" or not (24 <= xi < AV_SIZE[0] - 24 and 24 <= yi < AV_SIZE[1] - 24):
            continue
        found = next((k for k in AV_KINDS if model.startswith(k[0])), None)
        if found is None or _route_distance(xi, yi) < AV_CLEAR:
            continue
        _, models, sizes, round_, options, blocks = found
        path = models[hash2(xi, yi, 31) % len(models)]
        size = sizes[0] if scale < 0.85 else (sizes[1] if scale <= 1.25 else sizes[2])
        turn = hash2(xi, yi, 37) % 4 * 90 if round_ else int(round(yaw / 45)) % 8 * 45
        item = prop(path, xi, yi, yaw=turn, scale=size, name=model, **options)
        if blocks:
            item["blocks_karts"] = blocks
        out.append(item)
    return out


ALTERAC["props"] = AV_PROPS + _av_dressing()
