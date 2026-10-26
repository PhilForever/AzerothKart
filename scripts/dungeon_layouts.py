"""Scarlet Crusade Cup layouts for build_dungeon_tracks.py: dungeon sprints.

A dungeon course is open floor, not a road: axis-aligned rooms (halls,
corridors, chambers, a cloister's lawns and paths), each "road" (stone) or
"rough" (grass, which slows), with solid scenery standing on them. The
course is a sprint (`laps` 1): one run from the spawn through the gates, in
order, to the finish. Collision is Dungeon.lua's: the kart centre stays
WALL_INSET inside the rooms and outside every solid box grown by the same
inset. Where rooms meet, they overlap by at least DOOR_OVERLAP (twice the
inset), so the karts' floor runs on from one to the other; rooms that do not
meet keep a wall between them, never abutting where the karts would stop at
an unpainted wall (build_dungeon_tracks.hidden_walls). Scenery the karts
could drive over is solid; the rest stands against the walls.

World units, bottom-left origin, one texel per unit in the picture. The
painter (dungeon_paint.py) reads `floor` styles, walls, lights and props
from the same layout.
"""
import math

from city_layouts import WALL_INSET, prop

T = "war3.w3mod:terrainart/"
CITY = "war3.w3mod:doodads/cityscape/"
SUMMER = "war3.w3mod:doodads/lordaeronsummer/props/"
DUNGEON = "war3.w3mod:doodads/dungeon/props/"
NORTHREND = "war3.w3mod:doodads/northrend/"
TREES = "war3.w3mod:doodads/terrain/lordaerontree/"
DE = "war3.w3mod:_de.w3mod:"
UNITS = "war3.w3mod:units/"
DOOR_OVERLAP = 2 * WALL_INSET


def room(name, x0, y0, x1, y1, surface="road", floor="hall"):
    """A rectangle of floor: (x0, y0) to (x1, y1), `surface` "road" or
    "rough", painted in the layout's `floor` style."""
    assert x1 - x0 > 2 * WALL_INSET and y1 - y0 > 2 * WALL_INSET, name
    return {"name": name, "x0": x0, "y0": y0, "x1": x1, "y1": y1, "surface": surface, "floor": floor}


def disc_room(name, cx, cy, radius, surface="road", floor="hall"):
    """A round room: the disc of `radius` about (cx, cy), in its square."""
    assert radius > 2 * WALL_INSET, name
    return {"name": name, "x0": cx - radius, "y0": cy - radius, "x1": cx + radius, "y1": cy + radius,
            "surface": surface, "floor": floor, "shape": "disc"}


def gate(name, ax, ay, bx, by, nx, ny):
    return {"name": name, "ax": ax, "ay": ay, "bx": bx, "by": by, "nx": nx, "ny": ny}


def solid_at(x, y, half_w, half_h):
    """An explicit solid box centred on (x, y)."""
    return (x - half_w, y - half_h, x + half_w, y + half_h)


# ---------------------------------------------------------------------------
# Scarlet Graveyard.
#
# The owner (2026-10-25): "This will be A-B sprint type maps. Scarlet
# Crusade Cup ... Let's start with Scarlet Graveyard. It starts in a closed
# space and enters into an open graveyard. You don't need to put a
# traditional track here, just recreate the dungeon and let players find
# their way to the end." His map (the Scarlet Monastery Graveyard's) marks
# the route: in at the entrance (south-east), west and up the hall, into the
# Chamber of Atonement, out of its west side and down the stairs into the
# Forlorn Cloister, then west across the graveyard to Honor's Tomb: "END!".
# He chose (asked): grass slows, graves block.
#
# The map's rooms are drawn here at karting scale: halls and doors are wide
# enough for a kart (130 to 160 units), the rest keeps the map's layout and
# proportions within a 2048 x 1024 world.

SG_ROOMS = [
    # The entrance hall, in from the instance portal on its east wall, and
    # the long hall north to the Chamber of Atonement.
    room("entrance", 1720, 70, 2010, 230),
    room("north hall", 1720, 70, 1870, 560),
    # The Chamber of Atonement: a round chamber drawn as a cross of two
    # rectangles, its door in from the hall on the east and out on the west.
    # A wall stands between it and the west hall either side of the west
    # door (version 2: the two floors met there with no wall painted, and
    # the karts stopped short of it, the owner's "invisible wall").
    room("chamber door", 1640, 380, 1760, 520, floor="door"),
    room("chamber", 1380, 300, 1640, 660, floor="chamber"),
    room("chamber wings", 1360, 340, 1680, 620, floor="chamber"),
    room("chamber west door", 1300, 440, 1400, 560, floor="door"),
    room("west hall", 1180, 420, 1340, 720),
    room("stairs", 1000, 550, 1220, 690, floor="stairs"),
    # The Forlorn Cloister: the graveyard's lawn, open to the sky, with the
    # stone path across it, the round court in its middle and the paved
    # cloister walks of its east end.
    room("cloister", 260, 300, 1040, 940, surface="rough", floor="lawn"),
    room("cloister path", 260, 550, 1040, 690, floor="path"),
    room("cloister court", 440, 510, 580, 730, floor="court"),
    room("north walk", 780, 760, 1010, 920, floor="walk"),
    room("south walk", 780, 320, 1010, 480, floor="walk"),
    # Honor's Tomb, a cross-shaped crypt at the cloister's west end.
    room("tomb door", 180, 560, 300, 680, floor="tomb"),
    room("tomb", 40, 510, 220, 730, floor="tomb"),
    room("tomb north", 80, 690, 180, 820, floor="tomb"),
    room("tomb south", 80, 400, 180, 550, floor="tomb"),
    room("tomb west", 10, 570, 80, 670, floor="tomb"),
]

# The gates, in driving order: each spans a doorway from wall to wall, its
# normal pointing the way the karts go. The last is the finish.
SG_GATES = [
    gate("Chamber of Atonement", 1700, 380, 1700, 520, -1, 0),
    gate("Forlorn Cloister", 1110, 550, 1110, 690, -1, 0),
    gate("Honor's Tomb", 240, 560, 240, 680, -1, 0),
]

# A line through the gates the tests walk (kart centre, clear of walls and
# solids): the reviewed way to the end, not a road.
SG_ROUTE = [
    (1945, 150), (1830, 150), (1795, 185), (1795, 420), (1765, 450), (1640, 450),
    (1590, 560), (1440, 560), (1390, 520), (1330, 500), (1260, 520), (1230, 600),
    (1190, 620), (600, 620), (560, 700), (460, 700), (425, 620), (200, 620),
]


def on_floor(rooms, x, y):
    """Inside a room's painted floor (a round room's disc)."""
    for r in rooms:
        if not (r["x0"] <= x <= r["x1"] and r["y0"] <= y <= r["y1"]):
            continue
        if r.get("shape") != "disc":
            return True
        radius = (r["x1"] - r["x0"]) / 2
        dx, dy = x - (r["x0"] + r["x1"]) / 2, y - (r["y0"] + r["y1"]) / 2
        if dx * dx + dy * dy <= radius * radius:
            return True
    return False


def wall_props(rooms, name, side, model, every, offset=7, margin=40, start=None, **kw):
    """Models along one wall of a room, `offset` units out from it (inside
    the karts' inset, so they never stand in a kart's way: not solid), every
    `every` units, skipping doorways (where the floor runs on beyond the
    wall)."""
    r = next(room for room in rooms if room["name"] == name)
    out = []
    if side in ("north", "south"):
        y = r["y1"] - offset if side == "north" else r["y0"] + offset
        behind = y + 2 * offset if side == "north" else y - 2 * offset
        for x in range(start or r["x0"] + margin, r["x1"] - margin + 1, every):
            if not on_floor(rooms, x, behind) and not on_floor(rooms, x - 30, behind) \
                    and not on_floor(rooms, x + 30, behind):
                out.append(prop(model, x, y, **kw))
    else:
        x = r["x1"] - offset if side == "east" else r["x0"] + offset
        behind = x + 2 * offset if side == "east" else x - 2 * offset
        for y in range(start or r["y0"] + margin, r["y1"] - margin + 1, every):
            if not on_floor(rooms, behind, y) and not on_floor(rooms, behind, y - 30) \
                    and not on_floor(rooms, behind, y + 30):
                out.append(prop(model, x, y, **kw))
    return out


def _grave(kind, x, y, yaw=270, scale=0.3):
    """A gravestone (solid: its footprint)."""
    return prop(kind, x, y, yaw=yaw, scale=scale, solid=True, margin=1)


GRAVES = [CITY + "props/citygrave/citygrave%d.mdx" % n for n in (0, 1, 2, 3)] + [
    SUMMER + "grave/grave.mdx",
    NORTHREND + "props/northrendtombstone/northrendtombstone%d.mdx" % 0,
    NORTHREND + "props/northrendtombstone/northrendtombstone%d.mdx" % 2,
    NORTHREND + "props/northrendgrave/northrendgrave.mdx",
]
TORCH = SUMMER + "torchhuman/torchhuman.mdx"
BRAZIER = SUMMER + "brazier/brazier.mdx"
LANTERN = CITY + "props/lanternpost/lanternpost0.mdx"
BANNER = DE + "doodads/cityscape/props/scarletcrusadestandingbanners/scarletcrusadestandingbanners%d.mdx"
TORCHLIGHT = (78, (92, 58, 20))
FIRELIGHT = (118, (112, 66, 22))
LANTERNLIGHT = (96, (58, 62, 52))
TOMBLIGHT = (104, (34, 84, 52))


def _keep_out(x, y, zones):
    return any(x0 <= x <= x1 and y0 <= y <= y1 for x0, y0, x1, y1 in zones)


def _graveyard(keep):
    """Rows of graves on the cloister's lawns, clear of the path, the court,
    the walks, the doors and the `keep` zones (crypts, trees), with room to
    drive between them. Deterministic: the kind and a small offset come from
    the position."""
    out = []
    from city_paint import hash32
    lawns = [                      # (x0, x1, y0, y1): either side of the path
        (300, 750, 740, 900),      # the north lawn, west of the north walk
        (300, 750, 340, 500),      # the south lawn
    ]
    for x0, x1, y0, y1 in lawns:
        for row, y in enumerate(range(y0 + 10, y1, 74)):
            for x in range(x0 + 20 + (row % 2) * 40, x1, 84):
                if _keep_out(x, y, keep):
                    continue
                h = hash32(x, y, 301)
                kind = GRAVES[h % len(GRAVES)]
                dx, dy = h % 13 - 6, (h >> 8) % 9 - 4
                out.append(_grave(kind, x + dx, y + dy))
    return out


def _tree(n, x, y, scale=0.17):
    """A dead tree on the lawn: its trunk solid."""
    return prop(TREES + "lordaerontree%d.mdx" % n, x, y, scale=scale, solid=solid_at(x, y, 7, 7),
                name="dead tree")


# Crypts and trees on the lawns; the graves keep clear of them.
SG_CRYPTS = [
    prop(NORTHREND + "structures/northrendcrypt/northrendcrypt.mdx", 360, 862, scale=0.21, solid=True,
         margin=8, name="crypt", tint=(0.86, 0.86, 0.9)),
    prop(NORTHREND + "structures/northrendcrypt/northrendcrypt.mdx", 680, 368, scale=0.21, solid=True,
         margin=8, name="crypt", tint=(0.86, 0.86, 0.9)),
]
SG_TREES = [_tree(0, 560, 880), _tree(3, 690, 800), _tree(2, 330, 480), _tree(4, 470, 352), _tree(1, 980, 720),
            _tree(3, 960, 520)]
SG_KEEP = [(290, 790, 440, 920), (610, 300, 760, 440), (530, 850, 590, 910), (660, 770, 720, 830),
           (300, 450, 360, 510), (440, 330, 500, 380)]

SG_PROPS = (
    # Honor's Tomb: Bloodmage Thalnos before a stone tomb; coffins in the
    # crypt's side arms, braziers of green fire by the door.
    [prop(UNITS + "human/herobloodelf/herobloodelf.mdx", 110, 620, yaw=0, scale=0.34, solid=True,
          margin=2, name="Bloodmage Thalnos"),
     prop(DE + "doodads/undercity/props/crypttomb/crypttomb.mdx", 45, 620, yaw=0, scale=0.34, solid=True,
          margin=1, name="tomb"),
     prop(DE + "doodads/undercity/props/coffin/coffin_wooden0.mdx", 130, 790, scale=0.22, solid=True,
          margin=2, name="coffins"),
     prop(DE + "doodads/undercity/props/coffin/coffin_wooden1.mdx", 130, 436, scale=0.22, solid=True,
          margin=2, name="coffins"),
     prop(BRAZIER, 205, 712, scale=0.3, light=TOMBLIGHT, tint=(0.7, 1.0, 0.75)),
     prop(BRAZIER, 206, 528, scale=0.3, light=TOMBLIGHT, tint=(0.7, 1.0, 0.75)),
     prop(SUMMER + "skullpile/skullpile1.mdx", 47, 705, scale=0.26),
     prop(SUMMER + "skullpile/skullpile2.mdx", 48, 527, scale=0.26)]
    # The Forlorn Cloister: the court's ruined fountain, lanterns along the
    # path's north edge, crypts and dead trees among the graves, statues on
    # the paved walks, the dead walking and Scarlet guards by the stairs.
    + [prop(CITY + "props/fountainruined/fountainruined.mdx", 510, 620, scale=0.24, solid=True, margin=6,
            name="cloister fountain")]
    + [prop(LANTERN, x, 700, scale=0.2, solid=solid_at(x, 700, 4, 4), light=LANTERNLIGHT, name="lantern")
       for x in (330, 680, 860)]
    + SG_CRYPTS + SG_TREES
    + [prop(CITY + "props/city_oblisk/city_oblisk.mdx", 895, 838, scale=0.24, solid=True, margin=3,
            name="obelisk"),
       prop(CITY + "props/city_oblisk/city_oblisk.mdx", 895, 398, scale=0.24, solid=True, margin=3,
            name="obelisk"),
       prop(CITY + "props/citystonebench/citystonebench.mdx", 830, 905, scale=0.28, solid=True, margin=2,
            name="stone bench"),
       prop(CITY + "props/citystonebench/citystonebench.mdx", 960, 905, scale=0.28, solid=True, margin=2,
            name="stone bench"),
       prop(CITY + "props/citystonebench/citystonebench.mdx", 830, 466, scale=0.28, solid=True, margin=2,
            name="stone bench"),
       prop(CITY + "props/citystonebench/citystonebench.mdx", 960, 466, scale=0.28, solid=True, margin=2,
            name="stone bench"),
       prop(SUMMER + "sittingcorpse/sittingcorpse.mdx", 610, 760, scale=0.3, solid=solid_at(610, 760, 6, 6),
            name="corpse"),
       prop(NORTHREND + "props/northrendbrokencolumn/northrendbrokencolumn0.mdx", 740, 900, scale=0.2,
            solid=solid_at(740, 900, 8, 8), name="broken column", tint=(0.9, 0.9, 0.92)),
       prop(DE + "units/human/scarletfootman/scarletfootman.mdx", 1005, 745, yaw=225, scale=0.3,
            solid=solid_at(1005, 745, 6, 6), name="Scarlet guard"),
       prop(DE + "units/human/scarletfootman/scarletfootman.mdx", 1005, 500, yaw=135, scale=0.3,
            solid=solid_at(1005, 500, 6, 6), name="Scarlet guard"),
       prop(UNITS + "creeps/bansheeghost/bansheeghost.mdx", 430, 800, yaw=315, scale=0.26,
            solid=solid_at(430, 800, 6, 6), name="ghost"),
       prop(UNITS + "creeps/bansheeghost/bansheeghost.mdx", 610, 470, yaw=45, scale=0.26,
            solid=solid_at(610, 470, 6, 6), name="ghost"),
       prop(UNITS + "creeps/zombie/zombie.mdx", 520, 790, yaw=225, scale=0.3, solid=solid_at(520, 790, 6, 6),
            name="zombie"),
       prop(UNITS + "undead/skeleton/skeleton.mdx", 390, 420, yaw=90, scale=0.3, solid=solid_at(390, 420, 6, 6),
            name="skeleton")]
    + [prop(BANNER % 0, 1033, 724, scale=0.3), prop(BANNER % 1, 1033, 508, scale=0.3)]
    # The Chamber of Atonement: a torture table in the middle, Interrogator
    # Vishas and a torturer by the east wing, an iron maiden, a cage and
    # chain posts by the north wall, braziers at the cross's corners.
    + [prop(DUNGEON + "torturetable/torturetable.mdx", 1510, 480, yaw=0, scale=0.34, solid=True, margin=2,
            name="torture table"),
       prop(DE + "units/human/scarletinvoker/scarletinvoker.mdx", 1600, 600, yaw=225, scale=0.32,
            solid=solid_at(1600, 600, 7, 7), name="Interrogator Vishas"),
       prop(DE + "units/human/scarletcleric/scarletcleric.mdx", 1560, 410, yaw=135, scale=0.28,
            solid=solid_at(1560, 410, 7, 7), name="torturer"),
       prop(DUNGEON + "ironmaiden/ironmaiden.mdx", 1420, 652, scale=0.3, name="iron maiden"),
       prop(SUMMER + "cage/cage.mdx", 1640, 588, scale=0.26, solid=solid_at(1640, 588, 9, 8), name="cage"),
       prop(DUNGEON + "chainpost/chainpost.mdx", 1500, 650, scale=0.24, name="chains"),
       prop(SUMMER + "skullpile/skullpile0.mdx", 1368, 610, scale=0.26),
       prop(SUMMER + "skullpile/skullpile3.mdx", 1370, 348, scale=0.26),
       prop(SUMMER + "weapons/weapons.mdx", 1670, 356, scale=0.3)]
    + [prop(BRAZIER, x, y, scale=0.3, light=FIRELIGHT) for x, y in ((1392, 646), (1628, 646), (1392, 314),
                                                                     (1628, 314))]
    # The halls: Scarlet banners on the north walls and torches along them.
    + [prop(BANNER % 2, 1880, 222, scale=0.3), prop(BANNER % 0, 1955, 222, scale=0.3),
       prop(BANNER % 1, 1760, 552, scale=0.3), prop(BANNER % 2, 1830, 552, scale=0.3),
       prop(BANNER % 0, 1225, 712, scale=0.3), prop(BANNER % 1, 1295, 712, scale=0.3),
       prop(DE + "units/human/scarletfootman/scarletfootman.mdx", 1984, 204, yaw=225, scale=0.3,
            solid=solid_at(1984, 204, 6, 6), name="Scarlet guard"),
       prop(DE + "units/human/scarletfootman/scarletfootman.mdx", 1984, 96, yaw=135, scale=0.3,
            solid=solid_at(1984, 96, 6, 6), name="Scarlet guard"),
       prop(SUMMER + "armorrack/armorrack.mdx", 1190, 681, yaw=0, scale=0.3),
       prop(DUNGEON + "bench/bench.mdx", 1191, 470, yaw=0, scale=0.3)]
    + wall_props(SG_ROOMS, "north hall", "east", TORCH, 120, light=TORCHLIGHT, scale=0.3, start=150)
    + wall_props(SG_ROOMS, "north hall", "west", TORCH, 120, light=TORCHLIGHT, scale=0.3, start=270)
    + wall_props(SG_ROOMS, "stairs", "north", TORCH, 110, light=TORCHLIGHT, scale=0.3, start=1060)
    + wall_props(SG_ROOMS, "west hall", "east", TORCH, 110, light=TORCHLIGHT, scale=0.3, start=640)
    + [prop(TORCH, 1735, 222, scale=0.3, light=TORCHLIGHT)]
    + _graveyard(SG_KEEP)
)

SCARLET_GRAVEYARD = {
    "id": "scarlet_graveyard", "name": "Scarlet Graveyard", "version": 2, "folder": "ScarletGraveyard",
    "size": (2048, 1024), "laps": 1,
    "rooms": SG_ROOMS, "gates": SG_GATES, "route": SG_ROUTE, "spawn": (1945, 150, "west"),
    "props": SG_PROPS,
    # Painting (dungeon_paint.py).
    "lean": 0.6, "team": (0.72, 0.04, 0.04), "supersample": 3,
    "replaceables": {31: "war3.w3mod:replaceabletextures/dalaranruinstree/dalaranruinstree.dds"},
    "floors": {
        "hall": {"tile": T + "cityscape/city_squaretiles.dds", "shade": (1.0, 0.94, 0.84, 0.9)},
        "door": {"tile": T + "cityscape/city_squaretiles.dds", "shade": (1.0, 0.94, 0.84, 0.9)},
        "stairs": {"tile": T + "cityscape/city_bricktiles.dds", "shade": (0.95, 0.9, 0.84)},
        "chamber": {"tile": T + "dungeon/cave_squaretiles.dds", "shade": (1.0, 0.9, 0.86)},
        "lawn": {"tile": T + "dalaranruins/druins_grass.dds", "shade": (0.95, 1.0, 0.95)},
        "path": {"tile": T + "village/village_stonepath.dds", "shade": (0.86, 0.84, 0.8, 0.7)},
        "court": {"tile": T + "cityscape/city_roundtiles.dds", "shade": (0.92, 0.92, 0.9)},
        "walk": {"tile": T + "cityscape/city_bricktiles.dds", "shade": (0.84, 0.82, 0.78)},
        "tomb": {"tile": T + "cityscape/city_blackmarble.dds", "shade": (1.5, 1.5, 1.55, 0.25)},
    },
    # The walls: faces on every wall the camera sees (the north side of a
    # room) from a Warcraft III city wall, `height` world units tall.
    "wall": {"face": (T + "cityscape/city_cliff1.dds", (0, 0, 192, 64), (0.9, 0.84, 0.76)),
             "height": 70, "top": (34, 30, 30), "coping": (150, 140, 124)},
    "open_sky": ["cloister", "cloister path", "cloister court", "north walk", "south walk"],
    "portal": (1972, 150, 40),
    "stairs": {"room": "stairs", "tread": 14, "from": 44, "to": 44},
    # The red runners: (the run's corner points, width).
    "carpets": [([(1950, 150), (1795, 150), (1795, 546)], 40),
                ([(1330, 500), (1262, 500), (1262, 620), (1044, 620)], 40)],
    "kerbed": ["path", "court", "walk"],
}

# ---------------------------------------------------------------------------
# Scarlet Library.
#
# The owner (2026-10-25): "Scarlet Library. Everything is inside except the
# first courtyard with the fountain/statue in the middle, everything else is
# inside - ending in the iconic round library." His map (the Library's,
# MapsForTanks) marks the route: from the portal ("!") north and east into
# the long hall, south to the Huntsman's Cloister and down its west walk, in
# and back out of Houndmaster Loksey's kennel across the red line he drew
# there, up the east hall into the Gallery of Treasures, east through two
# columned halls, south down the Athenaeum and through the last hall to
# Arcanist Doan's round library: "END!", at the red line across its door.
#
# The map's rooms at karting scale in a 2048 x 2048 world: halls 120 to 140
# units wide, the cloister's courtyard 280 square, the round library 200 in
# radius. Only the courtyard is open to the sky.

SL_ROOMS = [
    # The portal hall, the upper hall east, and the long hall south to the
    # cloister.
    room("portal hall", 20, 1600, 140, 1930),
    room("upper hall", 20, 1800, 360, 1930),
    room("long hall", 230, 900, 360, 2010),
    room("cloister door", 324, 970, 436, 1070, floor="door"),
    # The Huntsman's Cloister: the open courtyard (its lawn, a cross of paths
    # and the fountain's round court), then the four roofed walks round it,
    # painted over the courtyard's edges.
    room("courtyard", 484, 644, 836, 996, surface="rough", floor="lawn"),
    room("courtyard path", 630, 644, 690, 996, floor="path"),
    room("courtyard cross path", 484, 790, 836, 850, floor="path"),
    disc_room("fountain court", 660, 820, 90, floor="court"),
    room("west walk", 400, 560, 520, 1080, floor="walk"),
    room("north walk", 400, 960, 920, 1080, floor="walk"),
    room("east walk", 800, 560, 920, 1080, floor="walk"),
    room("south walk", 400, 560, 920, 680, floor="walk"),
    # Houndmaster Loksey's kennel, south of the cloister: in and back out.
    room("kennel door", 590, 444, 730, 596, floor="door"),
    room("kennel", 510, 110, 810, 480, floor="kennel"),
    # The east hall, north to the Gallery of Treasures, with a side room.
    room("cloister east door", 884, 760, 996, 880, floor="door"),
    room("east hall", 960, 640, 1090, 1470),
    room("east alcove door", 888, 1280, 1000, 1360, floor="door"),
    room("east alcove", 780, 1250, 924, 1390),
    # The Gallery of Treasures: a long hall, two alcoves on its west side,
    # niches on its east.
    room("gallery door", 1054, 1270, 1166, 1380, floor="door"),
    room("gallery", 1130, 1180, 1320, 1990, floor="gallery"),
    room("gallery alcove north door", 1054, 1820, 1166, 1910, floor="door"),
    room("gallery alcove north", 960, 1800, 1090, 1930, floor="gallery"),
    room("gallery alcove south door", 1054, 1580, 1166, 1670, floor="door"),
    room("gallery alcove south", 960, 1560, 1090, 1690, floor="gallery"),
    room("gallery niche south", 1284, 1250, 1360, 1340, floor="gallery"),
    room("gallery niche north", 1284, 1420, 1360, 1510, floor="gallery"),
    # Two columned halls east, each a cross (its corners stepped in).
    room("first hall door", 1284, 1760, 1396, 1880, floor="door"),
    room("first hall", 1360, 1730, 1550, 1910, floor="columns"),
    room("first hall cross", 1395, 1690, 1515, 1950, floor="columns"),
    room("second hall door", 1514, 1760, 1626, 1880, floor="door"),
    room("second hall", 1590, 1730, 1780, 1910, floor="columns"),
    room("second hall cross", 1625, 1690, 1745, 1950, floor="columns"),
    # The Athenaeum, south, with niches on its west side.
    room("Athenaeum door", 1744, 1760, 1856, 1880, floor="door"),
    room("Athenaeum", 1820, 1180, 2010, 1990, floor="athenaeum"),
    room("Athenaeum niche north", 1784, 1460, 1856, 1550, floor="athenaeum"),
    room("Athenaeum niche south", 1784, 1300, 1856, 1390, floor="athenaeum"),
    # The last hall, and Arcanist Doan's round library.
    room("last hall door", 1855, 1114, 1975, 1216, floor="door"),
    room("last hall", 1690, 950, 2010, 1110, floor="columns"),
    room("last hall cross", 1730, 910, 1970, 1150, floor="columns"),
    room("library door", 1750, 690, 1870, 950, floor="door"),
    disc_room("round library", 1810, 560, 200, floor="library"),
]

# The gates, in driving order. Loksey's spans his kennel: the karts drive in
# across it, turn and come back out (crossing it backwards counts nothing).
SL_GATES = [
    gate("Huntsman's Cloister", 230, 1700, 360, 1700, 0, -1),
    gate("Houndmaster Loksey", 510, 400, 810, 400, 0, -1),
    gate("Gallery of Treasures", 1110, 1270, 1110, 1380, 1, 0),
    gate("Athenaeum", 1800, 1760, 1800, 1880, 1, 0),
    gate("Arcanist Doan", 1750, 800, 1870, 800, 0, -1),
]

SL_ROUTE = [
    (80, 1668), (80, 1865), (295, 1865), (295, 1020), (460, 1020), (460, 620), (620, 620),
    (620, 300), (660, 250), (700, 300), (700, 620), (860, 620), (860, 820), (1025, 820),
    (1025, 1325), (1225, 1325), (1225, 1820), (1915, 1820), (1915, 1160), (1860, 1030),
    (1810, 900), (1810, 700),
]

COLUMN = CITY + "structures/city_columnsingle/city_columnsingle.mdx"
PILLAR = DE + "doodads/lordaeroncapital/structures/pillarinterior/pillarinterior0.mdx"
SHELF = DUNGEON + "bookshelfwall/bookshelfwall.mdx"
SHELF45 = DUNGEON + "bookshelfwall45/bookshelfwall45.mdx"
BIGSHELF = DUNGEON + "bigbookshelf/bigbookshelf.mdx"
HUNTSMAN = DE + "units/human/scarlethuntsman/scarlethuntsman.mdx"
HOUND = DE + "units/creeps/darkhound/darkhound.mdx"
HOUND_TINT = (1.0, 0.42, 0.36)          # Warcraft III's dark hound, as the Scarlet tracking hounds
CANDLELIGHT = (70, (96, 70, 30))


def _column(x, y):
    """One of the cloister arcade's columns: solid at its base."""
    return prop(COLUMN, x, y, scale=0.2, solid=solid_at(x, y, 7, 7), name="arcade column")


def _pillar(x, y):
    """A columned hall's square pillar: solid."""
    return prop(PILLAR, x, y, scale=0.3, solid=solid_at(x, y, 12, 12), name="pillar")


def _hound(x, y, yaw):
    return prop(HOUND, x, y, yaw=yaw, scale=0.24, tint=HOUND_TINT, solid=solid_at(x, y, 6, 6), name="hound")


SL_PROPS = (
    # The portal hall: two Scarlet guards by the portal, banners and torches.
    [prop(DE + "units/human/scarletfootman/scarletfootman.mdx", 40, 1704, yaw=0, scale=0.3,
          solid=solid_at(40, 1704, 5, 5), name="Scarlet guard"),
     prop(DE + "units/human/scarletfootman/scarletfootman.mdx", 120, 1704, yaw=180, scale=0.3,
          solid=solid_at(120, 1704, 5, 5), name="Scarlet guard"),
     prop(BANNER % 0, 60, 1922, scale=0.3), prop(BANNER % 1, 190, 1922, scale=0.3),
     prop(BANNER % 2, 295, 2002, scale=0.3)]
    + wall_props(SL_ROOMS, "portal hall", "west", TORCH, 130, light=TORCHLIGHT, scale=0.3, start=1650)
    + wall_props(SL_ROOMS, "long hall", "west", TORCH, 170, light=TORCHLIGHT, scale=0.3, start=960)
    + wall_props(SL_ROOMS, "long hall", "east", TORCH, 170, light=TORCHLIGHT, scale=0.3, start=1045)
    + [prop(BANNER % (k % 3), 353, y, scale=0.3) for k, y in enumerate((1180, 1460, 1760))]
    # The Huntsman's Cloister: the arcade's columns round the courtyard, an
    # opening in the middle of each side; the statue in its fountain, four
    # trees and bushes (solid: nothing stands on the lawn the karts drive
    # over); huntsmen and their hounds.
    + [_column(x, y) for x, y in ((520, 680), (520, 725), (520, 915), (520, 960), (800, 680), (800, 725),
                                  (800, 915), (800, 960), (565, 680), (755, 680), (565, 960), (755, 960))]
    + [prop(CITY + "props/city_statue/city_statue.mdx", 660, 820, scale=0.25, solid=True, margin=6,
            name="cloister fountain")]
    + [prop(TREES + "lordaerontree%d.mdx" % n, x, y, scale=0.28, solid=solid_at(x, y, 7, 7), name="tree")
       for n, (x, y) in enumerate(((590, 750), (730, 750), (590, 890), (730, 890)))]
    + [prop(CITY + "plants/citybush/citybush.mdx", x, y, scale=0.22, solid=True, margin=3, name="bush")
       for x, y in ((548, 770), (548, 870), (772, 770), (772, 870), (610, 708), (710, 708), (610, 932),
                    (710, 932))]
    + [prop(HUNTSMAN, 548, 830, yaw=0, scale=0.3, solid=solid_at(548, 830, 6, 6), name="huntsman"),
       prop(HUNTSMAN, 772, 720, yaw=135, scale=0.3, solid=solid_at(772, 720, 6, 6), name="huntsman"),
       _hound(615, 915, 45), _hound(705, 725, 225), _hound(565, 720, 90)]
    + wall_props(SL_ROOMS, "west walk", "west", TORCH, 150, light=TORCHLIGHT, scale=0.3, start=620)
    + wall_props(SL_ROOMS, "east walk", "east", TORCH, 150, light=TORCHLIGHT, scale=0.3, start=620)
    + wall_props(SL_ROOMS, "north walk", "north", TORCH, 140, light=TORCHLIGHT, scale=0.3, start=500)
    + [prop(BANNER % 0, 500, 1072, scale=0.3), prop(BANNER % 1, 890, 1072, scale=0.3)]
    # Houndmaster Loksey's kennel: the houndmaster and his hounds at the
    # back, cages, bones, hay and braziers (the big ones solid, the rest
    # against the walls).
    + [prop(HUNTSMAN, 660, 172, yaw=90, scale=0.42, solid=solid_at(660, 172, 9, 9), name="Houndmaster Loksey"),
       _hound(600, 210, 45), _hound(722, 214, 135), _hound(770, 140, 135),
       prop(SUMMER + "cage/cage.mdx", 532, 140, scale=0.26, solid=True, margin=2, name="cage"),
       prop(SUMMER + "cageempty/cageempty.mdx", 532, 440, scale=0.26, solid=True, margin=2, name="cage"),
       prop(SUMMER + "ribbones/ribbones1.mdx", 790, 300, scale=0.26, solid=True, margin=4, name="bones"),
       prop(SUMMER + "skullpile/skullpile2.mdx", 516, 290, scale=0.24),
       prop(SUMMER + "weapons/weapons.mdx", 802, 440, scale=0.3),
       prop(SUMMER + "trough/trough0.mdx", 802, 220, yaw=0, scale=0.3),
       prop(SUMMER + "hay/hay0.mdx", 531, 205, scale=0.22, solid=True, margin=4, name="hay"),
       prop(SUMMER + "hay/hay3.mdx", 797, 370, scale=0.22), prop(SUMMER + "hay/hay4.mdx", 519, 360, scale=0.22)]
    + [prop(SUMMER + "hayclump/hayclump.mdx", x, y, scale=0.26, solid=True, margin=4, name="hay")
       for x, y in ((565, 330), (755, 330))]
    + [prop(BRAZIER, x, y, scale=0.3, light=FIRELIGHT) for x, y in ((526, 462), (792, 462), (524, 128),
                                                                    (792, 128))]
    # The east hall and its side room: torches, a reading table.
    + wall_props(SL_ROOMS, "east hall", "west", TORCH, 160, light=TORCHLIGHT, scale=0.3, start=700)
    + wall_props(SL_ROOMS, "east hall", "east", TORCH, 160, light=TORCHLIGHT, scale=0.3, start=780)
    + [prop(DUNGEON + "tablenchair/tablenchair.mdx", 850, 1320, scale=0.3, solid=True, margin=4, name="table"),
       prop(BIGSHELF, 850, 1382, yaw=270, scale=0.3),
       prop(SUMMER + "armorrack/armorrack.mdx", 1082, 1180, yaw=180, scale=0.3)]
    # The Gallery of Treasures: hoards in its niches and alcoves, chests,
    # shields and armour along its walls, statues, braziers.
    + [prop(DUNGEON + "treasurepile/treasurepile0.mdx", 1338, 1295, scale=0.22, solid=True, margin=4,
            name="treasure"),
       prop(DUNGEON + "treasurepile/treasurepile1.mdx", 1338, 1465, scale=0.22, solid=True, margin=4,
            name="treasure"),
       prop("war3.w3mod:objects/inventoryitems/treasurechest/treasurechest.mdx", 1160, 1462, yaw=0, scale=0.5,
            solid=True, margin=3, name="treasure chest"),
       prop("war3.w3mod:objects/inventoryitems/treasurechest/treasurechest.mdx", 1160, 1742, yaw=0, scale=0.5,
            solid=True, margin=3, name="treasure chest"),
       prop(CITY + "props/crystalshield/crystalshield.mdx", 1296, 1730, scale=0.28, solid=True, margin=6,
            name="shield"),
       prop(DE + "doodads/lordaeroncapital/props/statues/lordaeron_statue_sword.mdx", 996, 1625, yaw=0,
            scale=0.1, solid=True, margin=8, name="statue"),
       prop(DE + "doodads/lordaeroncapital/props/statues/lordaeron_statue_sword.mdx", 996, 1865, yaw=0,
            scale=0.1, solid=True, margin=8, name="statue"),
       prop(DE + "doodads/undercity/props/treasurechest/treasurechest.mdx", 1311, 1640, yaw=180, scale=0.3),
       prop(DE + "doodads/undercity/props/treasurechest/treasurechest.mdx", 1310, 1968, yaw=270, scale=0.3),
       prop(SUMMER + "armorrack/armorrack.mdx", 1307, 1560, yaw=180, scale=0.3),
       prop(SUMMER + "armorrack/armorrack.mdx", 1142, 1480, yaw=0, scale=0.3),
       prop(BANNER % 0, 1170, 1982, scale=0.3), prop(BANNER % 2, 1280, 1982, scale=0.3)]
    + [prop(BRAZIER, x, y, scale=0.3, light=FIRELIGHT) for x, y in ((1144, 1196), (1306, 1196), (1146, 1972),
                                                                    (1304, 1972))]
    # The columned halls: two square pillars each, braziers in the corners,
    # banners on the north walls.
    + [_pillar(x, y) for x, y in ((1455, 1750), (1455, 1890), (1685, 1750), (1685, 1890))]
    + [prop(BRAZIER, x, y, scale=0.26, light=FIRELIGHT) for x, y in ((1370, 1742), (1540, 1742), (1370, 1898),
                                                                     (1540, 1898), (1600, 1742), (1770, 1742),
                                                                     (1600, 1898), (1770, 1898))]
    + [prop(BANNER % 1, 1455, 1942, scale=0.3), prop(BANNER % 0, 1685, 1942, scale=0.3)]
    # The Athenaeum: bookshelves down both walls, reading tables in its
    # niches, candles, a Scarlet cleric at his books.
    + [prop(SHELF, 1827, y, yaw=180, scale=0.3) for y in (1240, 1440, 1610, 1700, 1940)]
    + [prop(SHELF, 2003, y, yaw=0, scale=0.3) for y in (1240, 1340, 1440, 1540, 1640, 1740, 1840, 1940)]
    + [prop(DUNGEON + "tablenchair/tablenchair.mdx", 1820, 1345, yaw=0, scale=0.28, solid=True, margin=4,
            name="table"),
       prop(DUNGEON + "tablenchair/tablenchair.mdx", 1820, 1505, yaw=0, scale=0.28, solid=True, margin=4,
            name="table"),
       prop(DE + "units/human/scarletcleric/scarletcleric.mdx", 1985, 1490, yaw=180, scale=0.28,
            solid=solid_at(1985, 1490, 6, 6), name="Scarlet cleric")]
    + [prop(BRAZIER, x, y, scale=0.22, light=CANDLELIGHT) for x, y in ((1836, 1390), (1836, 1560), (1994, 1290),
                                                                       (1994, 1590), (1994, 1890))]
    # The last hall: two pillars, braziers, banners.
    + [_pillar(1780, 1030), _pillar(1940, 1030)]
    + [prop(BRAZIER, x, y, scale=0.26, light=FIRELIGHT) for x, y in ((1702, 960), (1998, 960), (1702, 1100),
                                                                     (1998, 1100))]
    + [prop(BANNER % 2, 1760, 1142, scale=0.3), prop(BANNER % 0, 1820, 1142, scale=0.3)]
    # Arcanist Doan's round library: bookshelves round the north of its
    # wall (on the south wall a shelf would lean over the floor), Doan at
    # its centre before a lectern, banners, and candles round him (solid).
    + [prop(DE + "units/human/scarletinvoker/scarletinvokerhero.mdx", 1810, 548, yaw=90, scale=0.42,
            solid=solid_at(1810, 548, 9, 9), name="Arcanist Doan"),
       prop("war3.w3mod:buildings/other/bookofsummoning/bookofsummoning.mdx", 1810, 596, yaw=270, scale=0.26,
            solid=solid_at(1810, 596, 7, 6), name="lectern")]
    + [prop(SHELF, 2004, 560, yaw=0, scale=0.32), prop(SHELF, 1616, 560, yaw=180, scale=0.32),
       prop(SHELF45, 1945, 695, yaw=90, scale=0.3), prop(SHELF45, 1675, 695, yaw=0, scale=0.3)]
    + [prop(BANNER % (k % 3), x, y, scale=0.3) for k, (x, y) in
       enumerate(((1740, 735), (1880, 735), (1983, 632), (1637, 632)))]
    + [prop(BRAZIER, x, y, scale=0.22, light=CANDLELIGHT, solid=solid_at(x, y, 5, 5), name="candles")
       for x, y in ((1704, 454), (1916, 454), (1704, 666), (1916, 666))]
)

SCARLET_LIBRARY = {
    "id": "scarlet_library", "name": "Scarlet Library", "version": 1, "folder": "ScarletLibrary",
    "size": (2048, 2048), "laps": 1,
    "rooms": SL_ROOMS, "gates": SL_GATES, "route": SL_ROUTE, "spawn": (80, 1668, "north"),
    "props": SL_PROPS,
    "lean": 0.6, "team": (0.72, 0.04, 0.04), "supersample": 3,
    "replaceables": {31: "war3.w3mod:replaceabletextures/lordaerontree/lordaeronsummertree.dds"},
    "floors": {
        "hall": {"tile": T + "cityscape/city_squaretiles.dds", "shade": (0.92, 0.88, 0.82, 0.8)},
        "door": {"tile": T + "cityscape/city_squaretiles.dds", "shade": (0.92, 0.88, 0.82, 0.8)},
        "walk": {"tile": T + "cityscape/city_squaretiles.dds", "shade": (1.0, 0.95, 0.86, 0.9)},
        "lawn": {"tile": T + "cityscape/city_grass.dds", "shade": (0.92, 1.0, 0.9)},
        "path": {"tile": T + "village/village_stonepath.dds", "shade": (0.95, 0.95, 0.92, 0.6)},
        "court": {"tile": T + "cityscape/city_roundtiles.dds", "shade": (0.92, 0.92, 0.9)},
        "kennel": {"tile": T + "dungeon/cave_squaretiles.dds", "shade": (1.0, 0.9, 0.86)},
        "gallery": {"tile": T + "dalaran/dalaran_whitemarble.dds", "shade": (0.82, 0.78, 0.72)},
        "columns": {"tile": T + "dalaran/dalaran_squaretiles.dds", "shade": (0.95, 0.92, 0.9, 0.25)},
        "athenaeum": {"tile": T + "cityscape/city_bricktiles.dds", "shade": (0.86, 0.8, 0.72)},
        "library": {"tile": T + "blackcitadel/citadel_darktiles.dds", "shade": (0.95, 1.0, 1.1, 0.15)},
    },
    "wall": {"face": (T + "cityscape/city_cliff1.dds", (0, 0, 192, 64), (0.9, 0.84, 0.76)),
             "height": 70, "top": (34, 30, 30), "coping": (150, 140, 124)},
    "open_sky": ["courtyard", "courtyard path", "courtyard cross path", "fountain court"],
    "portal": (80, 1640, 38),
    "carpets": [([(295, 1990), (295, 1020), (430, 1020)], 40),
                ([(1025, 700), (1025, 1325), (1225, 1325)], 40),
                ([(1225, 1210), (1225, 1820), (1915, 1820), (1915, 1030), (1810, 1030), (1810, 744)], 42)],
    "kerbed": ["path", "court"],
    # The round library's floor: dark stone, a gold ring, the red carpet.
    "rings": {"room": "round library", "bands": [(104, "floor"), (116, "gold"), (188, "carpet")]},
    # The courtyard under the monastery's green-tinged night sky.
    "moonlight": (204, 232, 214), "mist": (146, 164, 156),
}

# ---------------------------------------------------------------------------
# Scarlet Armory.
#
# The owner (2026-10-26): "let's get to work on Scarlet Armory. Image 3 is
# the training grounds area. Final room is the iconic round room with
# stairs leading down to herod (image 4). Same style. Free driving through
# the whole map. The Training grounds is the only outside you see on this
# map." He sent the wing's in-game map and a battle map of it (Sanctum of
# Maps), and chose (asked) the finish line down at Herod, across the Hall
# of Champions' middle. The way, from the maps: the entrance hall from the
# portal, the Training Grounds (its yard the one open sky), stairs up into
# the Footman's Armory, round by its east side room and stairs to the
# Crusader's Armory, out of its north-west corner, along the long hall and
# into the round Hall of Champions, down its ring of stairs to Herod.
#
# At karting scale in a 2048 x 2048 world: halls 120 to 130 units wide, the
# yard 400 x 240, each armory 460 x 360 round two great square pillars (the
# map's two octagons), the round hall 175 in radius, low enough in the world
# that its north wall and the statues before it are drawn whole.

SA_ROOMS = [
    # The entrance hall, east from the portal, and its door north.
    room("entrance hall", 350, 40, 1010, 170),
    room("training door", 750, 130, 880, 250, floor="door"),
    # The Training Grounds: the yard open to the sky, the four roofed walks
    # round it painted over its edges.
    room("training yard", 670, 210, 1250, 630, surface="rough", floor="yard"),
    room("south walk", 670, 210, 1250, 300, floor="walk"),
    room("north walk", 670, 540, 1250, 630, floor="walk"),
    room("west walk", 670, 210, 760, 630, floor="walk"),
    room("east walk", 1160, 210, 1250, 630, floor="walk"),
    # Stairs up from the north walk into the Footman's Armory.
    room("training stairs", 790, 590, 920, 710, floor="stairs"),
    # The Footman's Armory: two bands and three aisles round its two great
    # pillars (the masonry left between them).
    room("footman south", 750, 670, 1210, 815, floor="armory"),
    room("footman north", 750, 885, 1210, 1030, floor="armory"),
    room("footman west", 750, 670, 850, 1030, floor="armory"),
    room("footman aisle", 920, 670, 1040, 1030, floor="armory"),
    room("footman east", 1110, 670, 1210, 1030, floor="armory"),
    # Its east side room, the stairs up and the Crusader's side room.
    room("footman landing", 1170, 910, 1330, 1030, floor="landing"),
    room("armory stairs", 1190, 990, 1310, 1110, floor="stairs"),
    room("crusader landing", 1170, 1070, 1330, 1190, floor="landing"),
    # The Crusader's Armory, as the Footman's.
    room("crusader south", 750, 1070, 1210, 1215, floor="armory"),
    room("crusader north", 750, 1285, 1210, 1430, floor="armory"),
    room("crusader west", 750, 1070, 850, 1430, floor="armory"),
    room("crusader aisle", 920, 1070, 1040, 1430, floor="armory"),
    room("crusader east", 1110, 1070, 1210, 1430, floor="armory"),
    # Out of its north-west corner: the antechamber, the hall north and the
    # long hall east to the Hall of Champions' door.
    room("antechamber", 570, 1310, 790, 1430, floor="landing"),
    room("north hall", 590, 1390, 710, 1550),
    room("long hall", 590, 1510, 1770, 1630),
    room("champions door", 1510, 1590, 1630, 1740, floor="door"),
    # The Hall of Champions: a round hall, its floor in rings down a ring of
    # stairs to the arena where Herod stands.
    disc_room("Hall of Champions", 1570, 1828, 175, floor="champions"),
]

# The gates, in driving order. The last is the finish, across the round
# hall's middle beside Herod: the karts drive down the stairs to cross it.
SA_GATES = [
    gate("Training Grounds", 750, 200, 880, 200, 0, 1),
    gate("Footman's Armory", 790, 650, 920, 650, 0, 1),
    gate("Crusader's Armory", 1190, 1050, 1310, 1050, 0, 1),
    gate("Hall of Champions", 1510, 1650, 1630, 1650, 0, 1),
    gate("Herod", 1395, 1828, 1745, 1828, 0, 1),
]

SA_ROUTE = [
    (500, 105), (815, 105), (815, 255), (715, 255), (715, 585), (855, 585), (855, 700), (1100, 745),
    (1160, 800), (1160, 960), (1250, 960), (1250, 1130), (1160, 1130), (800, 1130), (800, 1360), (650, 1360), (650, 1570),
    (1570, 1570), (1570, 1690), (1525, 1770), (1525, 1880),
]

SCARECROW = DE + "doodads/lordaeroncapital/props/scarecrow/scarecrow%d.mdx"
ARCHERY = SUMMER + "archeryrange/archeryrange.mdx"
WEAPONS = SUMMER + "weapons/weapons.mdx"
ARMORRACK = SUMMER + "armorrack/armorrack.mdx"
CRATES = CITY + "props/emptycrates/emptycrates%d.mdx"
SMITHY = DE + "doodads/lordaeroncapital/props/smithytools/smithytools%d.mdx"
FURNITURE = DE + "doodads/lordaeroncapital/props/lordaeronfurniture/lordaeronfurniture%d.mdx"
STATUES = [DE + "doodads/lordaeroncapital/props/statues/lordaeron_statue_sword.mdx",
           DE + "doodads/lordaeroncapital/props/statues/lordaeron_statue_shield.mdx"]
STATUE_TINT = (0.78, 0.86, 0.84)        # the hall's pale green-grey stone
FOOTMAN = DE + "units/human/scarletfootman/scarletfootman.mdx"
# Reforged has no Herod: Dagren the Orcslayer's bulk, his armour turned the
# Crusade's crimson (Renault Mograine himself stands in the Cathedral).
HEROD = DE + "units/human/herodagren/herodagren.mdx"
HEROD_RECOLOR = ((10, 75, 356, 0.18, 1.5, 0.95),)


def _unit(model, x, y, yaw, scale, name, half=6):
    """A Scarlet soldier standing guard: solid at his feet."""
    return prop(model, x, y, yaw=yaw, scale=scale, solid=solid_at(x, y, half, half), name=name)


SA_PROPS = (
    # The entrance hall: guards by the portal, banners and torches.
    [_unit(FOOTMAN, 440, 150, 270, 0.3, "Scarlet guard", 5), _unit(FOOTMAN, 440, 60, 90, 0.3, "Scarlet guard", 5),
     prop(BANNER % 0, 600, 162, scale=0.3), prop(BANNER % 1, 980, 162, scale=0.3)]
    + wall_props(SA_ROOMS, "entrance hall", "north", TORCH, 120, light=TORCHLIGHT, scale=0.3, start=520)
    # The Training Grounds: the arcade's columns round the yard (an opening
    # in each side), archery targets down its east side, training dummies,
    # hay and a bush; racks of weapons and armour along the walks.
    + [_column(x, y) for x, y in ((760, 300), (840, 300), (1080, 300), (1160, 300), (760, 540), (840, 540),
                                  (1080, 540), (1160, 540), (760, 420), (1160, 420))]
    + [prop(ARCHERY, 1118, y, yaw=270, scale=0.45, solid=True, margin=2, name="archery target")
       for y in (350, 405, 460, 515)]
    + [prop(SCARECROW % (k % 3), x, y, yaw=yaw, scale=0.28, solid=solid_at(x, y, 6, 6), name="training dummy")
       for k, (x, y, yaw) in enumerate(((850, 370, 0), (960, 460, 315), (1010, 355, 45), (880, 490, 270)))]
    + [prop(SUMMER + "hayclump/hayclump.mdx", 1060, 510, scale=0.24, solid=True, margin=4, name="hay"),
       prop(CITY + "plants/citybush/citybush.mdx", 800, 340, scale=0.22, solid=True, margin=3, name="bush")]
    + [prop(ARMORRACK, 677, y, yaw=0, scale=0.3) for y in (340, 480)]
    + [prop(ARMORRACK, 1243, y, yaw=180, scale=0.3) for y in (290, 530)]
    + [prop(WEAPONS, x, 622, yaw=270, scale=0.44) for x in (722, 1060)]
    + [prop(BANNER % 2, 980, 622, scale=0.3), prop(BANNER % 0, 1200, 622, scale=0.3)]
    + [prop(CRATES % 0, 1220, 240, scale=0.3, solid=True, margin=3, name="crates")]
    + wall_props(SA_ROOMS, "west walk", "west", TORCH, 150, light=TORCHLIGHT, scale=0.3, start=270)
    + wall_props(SA_ROOMS, "east walk", "east", TORCH, 150, light=TORCHLIGHT, scale=0.3, start=270)
    # The Footman's Armory: armour stands down its side walls, weapon racks
    # face on along its north wall, a forge and an anvil, crates and Scarlet
    # footmen at their drill by the pillars. (A rack seen end on from above
    # is a stick: racks stand face on only against north walls.)
    + [prop(ARMORRACK, 758, y, yaw=0, scale=0.42) for y in (735, 815, 895)]
    + [prop(ARMORRACK, 1202, y, yaw=180, scale=0.42) for y in (760, 840)]
    + [prop(WEAPONS, x, 1022, yaw=270, scale=0.46) for x in (900, 1075)]
    + [prop(SMITHY % 0, 820, 975, scale=0.3, solid=True, margin=6, name="forge"),
       prop(SMITHY % 1, 980, 960, scale=0.3, solid=True, margin=2, name="anvil"),
       prop(CRATES % 1, 1180, 700, scale=0.3, solid=True, margin=3, name="crates"),
       _unit(FOOTMAN, 885, 790, 270, 0.3, "Scarlet footman"), _unit(FOOTMAN, 1075, 790, 270, 0.3, "Scarlet footman")]
    + [prop(BANNER % 1, 1000, 1022, scale=0.3), prop(BANNER % 2, 1150, 1022, scale=0.3)]
    # The landings and the stairs between the armories.
    + [prop(BRAZIER, 1318, 920, scale=0.26, light=FIRELIGHT), prop(BRAZIER, 1318, 1180, scale=0.26, light=FIRELIGHT)]
    # The Crusader's Armory: armour stands, weapon racks along its north
    # wall, a table of arms, junk.
    + [prop(ARMORRACK, 758, y, yaw=0, scale=0.42) for y in (1120, 1200, 1280)]
    + [prop(ARMORRACK, 1202, y, yaw=180, scale=0.42) for y in (1250, 1330)]
    + [prop(WEAPONS, x, 1422, yaw=270, scale=0.46) for x in (930, 1110)]
    + [prop(FURNITURE % 0, 980, 1370, scale=0.3, solid=True, margin=3, name="table"),
       prop(DUNGEON + "junkpile/junkpile0.mdx", 1150, 1380, scale=0.3, solid=True, margin=4, name="junk"),
       prop(SMITHY % 3, 870, 1395, scale=0.3, solid=True, margin=3, name="cart"),
       _unit(FOOTMAN, 885, 1190, 270, 0.3, "Scarlet footman"), _unit(FOOTMAN, 1075, 1190, 270, 0.3, "Scarlet footman")]
    + [prop(BANNER % 0, 820, 1422, scale=0.3), prop(BANNER % 1, 1060, 1422, scale=0.3)]
    # The halls: torches and banners.
    + wall_props(SA_ROOMS, "north hall", "west", TORCH, 130, light=TORCHLIGHT, scale=0.3, start=1420)
    + wall_props(SA_ROOMS, "long hall", "north", TORCH, 140, light=TORCHLIGHT, scale=0.3, start=680)
    + [prop(BANNER % 2, 1450, 1622, scale=0.3), prop(BANNER % 0, 1690, 1622, scale=0.3)]
    # The Hall of Champions: Herod in its arena, candles round it on the
    # stairs, statues of champions round the north of its wall facing him
    # (on the south wall they would lean out over the floor), a Scarlet
    # banner between them.
    + [prop(HEROD, 1570, 1828, yaw=270, scale=0.46, recolor=HEROD_RECOLOR, solid=solid_at(1570, 1828, 9, 9),
            name="Herod")]
    + [prop(BRAZIER, 1570 + dx, 1828 + dy, scale=0.22, light=CANDLELIGHT, solid=solid_at(1570 + dx, 1828 + dy, 5, 5),
            name="candles") for dx, dy in ((-78, 78), (78, 78), (-78, -78), (78, -78))]
    + [prop(STATUES[k], 1570 + round(172 * math.cos(math.radians(a))), 1828 + round(172 * math.sin(math.radians(a))),
            yaw=yaw, scale=0.08, tint=STATUE_TINT)
       for k, a, yaw in ((0, 160, 0), (1, 125, 315), (1, 55, 225), (0, 20, 180))]
    + [prop(BANNER % 2, 1570, 1995, scale=0.32)]
)

SCARLET_ARMORY = {
    "id": "scarlet_armory", "name": "Scarlet Armory", "version": 1, "folder": "ScarletArmory",
    "size": (2048, 2048), "laps": 1,
    "rooms": SA_ROOMS, "gates": SA_GATES, "route": SA_ROUTE, "spawn": (500, 105, "east"),
    "props": SA_PROPS,
    "lean": 0.6, "team": (0.72, 0.04, 0.04), "supersample": 3,
    "replaceables": {31: "war3.w3mod:replaceabletextures/lordaerontree/lordaeronsummertree.dds"},
    "floors": {
        "hall": {"tile": T + "cityscape/city_squaretiles.dds", "shade": (0.92, 0.88, 0.82, 0.8)},
        "door": {"tile": T + "cityscape/city_squaretiles.dds", "shade": (0.92, 0.88, 0.82, 0.8)},
        "walk": {"tile": T + "dalaran/dalaran_squaretiles.dds", "shade": (0.86, 0.86, 0.84, 0.4)},
        "yard": {"tile": T + "cityscape/city_grass.dds", "shade": (0.92, 1.0, 0.9)},
        "stairs": {"tile": T + "cityscape/city_bricktiles.dds", "shade": (0.95, 0.9, 0.84)},
        "armory": {"tile": T + "dalaranruins/druins_bricktiles.dds", "shade": (1.08, 0.96, 0.82, 0.5)},
        "landing": {"tile": T + "cityscape/city_squaretiles.dds", "shade": (0.86, 0.80, 0.72, 0.7)},
        "champions": {"tile": T + "cityscape/city_squaretiles.dds", "shade": (1.06, 0.92, 0.70, 0.6)},
    },
    "wall": {"face": (T + "cityscape/city_cliff1.dds", (0, 0, 192, 64), (0.9, 0.84, 0.76)),
             "height": 70, "top": (34, 30, 30), "coping": (150, 140, 124)},
    "open_sky": ["training yard"],
    "portal": (440, 105, 38),
    "carpets": [([(560, 105), (815, 105), (815, 230)], 40),
                ([(650, 1570), (1570, 1570), (1570, 1686)], 42),
                # The armories' red mats.
                ([(975, 722), (975, 752)], 64), ([(860, 1335), (900, 1335)], 52),
                ([(1100, 1110), (1130, 1110)], 48)],
    "kerbed": ["walk"], "lawn": "yard",
    "stairs": [{"room": "training stairs", "tread": 10, "axis": "y", "from": 40, "to": 40},
               {"room": "armory stairs", "tread": 10, "axis": "y", "from": 40, "to": 40}],
    # The Hall of Champions' floor: the arena's red carpet with its gold
    # lozenge, a gold ring, the stairs down to it, the upper floor round them.
    "rings": {"room": "Hall of Champions", "bands": [(83, "carpet"), (88, "gold"), (138, "stairs", 9)],
              "diamond": 53},
    # The yard's stepping stones in the grass.
    "stones": {"floor": "yard", "step": 46, "radius": 13, "density": 62},
    "moonlight": (204, 232, 214), "mist": (146, 164, 156),
}

# ---------------------------------------------------------------------------
# Scarlet Cathedral.
#
# The owner (2026-10-26): "Scarlet Cathedral next." He sent the wing's
# in-game map, a battle map of it (Sanctum of Maps), a screenshot of the
# Chapel Gardens and one of the cathedral's nave, and chose (asked) the
# finish at the altar and the gardens' pools as water the karts drive round.
# The way, from the maps: from the portal west along the entrance hall,
# north into the Chapel Gardens (the open sky): round the lower pool, up the
# platforms or the stairs beside the falls, round the round pool, up the
# terrace to the cathedral's door; up the nave, across the transept and the
# chancel's steps to the altar, where Mograine and Whitemane stand. The
# chancel's hall runs on north to the round chamber behind it.
#
# At karting scale in a 1024 x 2048 world (the wing is twice as tall as it
# is wide): halls and doors 120 wide, walks 100, the nave 484 x 380 with two
# rows of three pillars, the transept 904 x 190, the round pool 140 in
# radius.

SC_ROOMS = [
    # The entrance hall, west from the portal, and the gate north.
    room("entrance hall", 440, 50, 900, 170),
    room("garden gate", 452, 130, 572, 266, floor="door"),
    # The Chapel Gardens' lower garden: its lawn, the walks round it painted
    # over its edges.
    room("lower garden", 205, 230, 819, 600, surface="rough", floor="lawn"),
    room("south walk", 205, 230, 819, 320, floor="walk"),
    room("lower west walk", 205, 230, 305, 600, floor="walk"),
    room("lower east walk", 719, 230, 819, 600, floor="walk"),
    # The upper garden round the round pool and its walks; up to it, the
    # platforms either side and the stairs beside the falls (the falls
    # between them are water), painted over the lawns' edges.
    room("upper garden", 105, 600, 919, 1040, surface="rough", floor="lawn"),
    room("upper west walk", 105, 600, 205, 1040, floor="walk"),
    room("upper east walk", 819, 600, 919, 1040, floor="walk"),
    room("west platform", 205, 560, 372, 660, floor="cobbles"),
    room("west stairs", 336, 560, 452, 700, floor="stairs"),
    room("east stairs", 572, 560, 688, 700, floor="stairs"),
    room("east platform", 652, 560, 819, 660, floor="cobbles"),
    # The terrace and the steps up to the cathedral's door.
    room("cathedral terrace", 265, 1000, 759, 1096, floor="terrace"),
    room("door steps", 412, 1040, 612, 1096, floor="stairs"),
    # The Crusader's Chapel: the nave, the transept, its two side chapels,
    # the chancel up its steps, the hall north to the round chamber.
    room("cathedral door", 452, 1060, 572, 1176, floor="nave"),
    room("nave", 270, 1140, 754, 1520, floor="nave"),
    room("transept", 60, 1480, 964, 1670, floor="nave"),
    room("west chapel", 90, 1634, 250, 1770, floor="wood"),
    room("east chapel", 774, 1634, 934, 1770, floor="wood"),
    room("chancel", 295, 1634, 729, 1800, floor="wood"),
    room("chancel steps", 432, 1626, 592, 1672, floor="stairs"),
    room("chancel hall", 452, 1764, 572, 1920, floor="wood"),
    disc_room("Fairbanks' chamber", 512, 1930, 70, floor="wood"),
]

# Water the karts drive round, each pool a solid of its shape: the lower
# pool, the falls down into it, the round pool above.
SC_POOLS = [
    {"name": "lower pool", "shape": "rect", "x0": 432, "y0": 380, "x1": 592, "y1": 566},
    {"name": "falls", "shape": "rect", "x0": 452, "y0": 560, "x1": 572, "y1": 706},
    {"name": "round pool", "shape": "disc", "cx": 512, "cy": 830, "radius": 140},
]

# The gates, in driving order. The last is the finish, across the chancel
# in front of the altar.
SC_GATES = [
    gate("Chapel Gardens", 452, 200, 572, 200, 0, 1),
    gate("Upper Gardens", 205, 590, 819, 590, 0, 1),
    gate("Crusader's Chapel", 452, 1118, 572, 1118, 0, 1),
    gate("High Altar", 295, 1700, 729, 1700, 0, 1),
]

SC_ROUTE = [
    (790, 110), (512, 110), (512, 280), (255, 280), (255, 625), (155, 640), (155, 1000), (512, 1050),
    (512, 1200), (512, 1640), (512, 1712),
]

FOUNTAIN = DE + "doodads/cityscape/props/city_fountain/city_fountain.mdx"
LION = DE + "doodads/lordaeronfall/props/lionstatue/lionstatue.mdx"
BENCH = DE + "doodads/cityscape/props/citywoodbench/citywoodbench.mdx"
BOOKSHELF = DE + "doodads/lordaeroncapital/props/lordaeronbookshelf/lordaeronbookshelf%d.mdx"
CLERIC = DE + "units/human/scarletcleric/scarletcleric.mdx"
MOGRAINE = DE + "units/human/herorenaultmograine/herorenaultmograine.mdx"
WHITEMANE = DE + "units/human/herosallywhitemane/herosallywhitemane.mdx"
SUMMER_TREE = TREES + "lordaerontree%d.mdx"


def _tree_green(n, x, y, scale=0.28):
    """A summer tree in the gardens: its trunk solid."""
    return prop(SUMMER_TREE % n, x, y, scale=scale, solid=solid_at(x, y, 7, 7), name="tree")


def _bush(x, y):
    return prop(CITY + "plants/citybush/citybush.mdx", x, y, scale=0.22, solid=True, margin=3, name="bush")


def _nave_pillar(x, y):
    """One of the cathedral's great square pillars: solid."""
    return prop(PILLAR, x, y, scale=0.42, solid=solid_at(x, y, 16, 16), name="pillar")


SC_PROPS = (
    # The entrance hall: guards by the portal, banners and torches.
    [_unit(FOOTMAN, 850, 150, 270, 0.3, "Scarlet guard", 5), _unit(FOOTMAN, 850, 70, 90, 0.3, "Scarlet guard", 5),
     prop(BANNER % 0, 620, 162, scale=0.3), prop(BANNER % 1, 760, 162, scale=0.3)]
    + wall_props(SC_ROOMS, "entrance hall", "north", TORCH, 140, light=TORCHLIGHT, scale=0.3, start=550)
    # The lower garden: four trees on its lawn, bushes, lanterns and benches
    # along its walks' outer walls.
    + [_tree_green(n, x, y) for n, (x, y) in enumerate(((360, 372), (664, 372), (360, 520), (664, 520)))]
    + [_bush(x, y) for x, y in ((330, 450), (694, 450))]
    + wall_props(SC_ROOMS, "lower west walk", "west", LANTERN, 140, light=LANTERNLIGHT, scale=0.2, start=300)
    + wall_props(SC_ROOMS, "lower east walk", "east", LANTERN, 140, light=LANTERNLIGHT, scale=0.2, start=300)
    + [prop(BENCH, 213, y, yaw=0, scale=0.3) for y in (370, 510)]
    + [prop(BENCH, 811, y, yaw=180, scale=0.3) for y in (370, 510)]
    # Up to the upper garden: the giant champions' statues on the platforms,
    # lions over the falls.
    + [prop(STATUES[0], x, 618, yaw=yaw, scale=0.12, tint=STATUE_TINT, solid=solid_at(x, 618, 14, 12),
            name="champion's statue") for x, yaw in ((300, 0), (724, 180))]
    + [prop(LION, x, 706, yaw=270, scale=0.12) for x in (464, 560)]
    # The upper garden: the fountain in the round pool, trees and bushes on
    # its lawn, lanterns along its walks.
    + [prop(FOUNTAIN, 512, 830, scale=0.32)]
    + [_tree_green(n, x, y) for n, (x, y) in enumerate(((262, 730), (762, 730), (262, 985), (762, 985)), 1)]
    + [_bush(x, y) for x, y in ((310, 860), (714, 860))]
    + wall_props(SC_ROOMS, "upper west walk", "west", LANTERN, 140, light=LANTERNLIGHT, scale=0.2, start=680)
    + wall_props(SC_ROOMS, "upper east walk", "east", LANTERN, 140, light=LANTERNLIGHT, scale=0.2, start=680)
    # The terrace before the cathedral: trees at its ends, lanterns and
    # banners on the facade either side of the door.
    + [_tree_green(n, x, 1060) for n, x in ((2, 300), (4, 724))]
    + [prop(LANTERN, x, 1089, scale=0.2, light=LANTERNLIGHT) for x in (392, 632)]
    + [prop(BANNER % 0, 340, 1089, scale=0.3), prop(BANNER % 1, 684, 1089, scale=0.3)]
    # The nave: its two rows of pillars, candles before them, the Crusade's
    # clerics and footmen lining the carpet, torches and banners on its walls.
    + [_nave_pillar(x, y) for x in (412, 612) for y in (1220, 1345, 1488)]
    + [prop(BRAZIER, x, y - 26, scale=0.22, light=CANDLELIGHT) for x in (412, 612) for y in (1220, 1345)]
    + [_unit(CLERIC if k % 2 else FOOTMAN, x, y, yaw, 0.3, "Scarlet " + ("cleric" if k % 2 else "footman"))
       for k, (x, y, yaw) in enumerate(((440, 1250, 0), (584, 1250, 180), (440, 1375, 0), (584, 1375, 180)))]
    + wall_props(SC_ROOMS, "nave", "west", TORCH, 125, light=TORCHLIGHT, scale=0.3, start=1200)
    + wall_props(SC_ROOMS, "nave", "east", TORCH, 125, light=TORCHLIGHT, scale=0.3, start=1200)
    # The transept: its two great pillars, braziers and banners at its ends.
    + [_nave_pillar(x, 1575) for x in (180, 844)]
    + [prop(BRAZIER, x, 1490, scale=0.26, light=FIRELIGHT) for x in (68, 956)]
    + [prop(BANNER % 2, 272, 1664, scale=0.3), prop(BANNER % 2, 752, 1664, scale=0.3)]
    # The chancel: pillars at its front, the altar with Mograine and
    # Whitemane before it, candles, banners on its north wall.
    + [_pillar(x, 1660) for x in (410, 614)]
    + [prop(FURNITURE % 0, 512, 1752, scale=0.34, solid=True, margin=3, name="altar")]
    + [_unit(MOGRAINE, 466, 1728, 270, 0.36, "Scarlet Commander Mograine", 7),
       _unit(WHITEMANE, 558, 1728, 270, 0.36, "High Inquisitor Whitemane", 7)]
    + [prop(BRAZIER, x, 1772, scale=0.22, light=CANDLELIGHT, solid=solid_at(x, 1772, 5, 5), name="candles")
       for x in (436, 588)]
    + [prop(BANNER % 0, 350, 1792, scale=0.3), prop(BANNER % 1, 674, 1792, scale=0.3)]
    + wall_props(SC_ROOMS, "chancel", "north", TORCH, 110, light=TORCHLIGHT, scale=0.3, start=400)
    # The side chapels: a reading table and shelves; crates and a guard.
    + [prop(BOOKSHELF % 0, x, 1765, scale=0.27) for x in (130, 210)]
    + [prop(FURNITURE % 1, 170, 1700, scale=0.3, solid=True, margin=3, name="table"),
       _unit(CLERIC, 140, 1690, 0, 0.3, "Scarlet cleric")]
    + [prop(CRATES % 0, 900, 1745, scale=0.3, solid=True, margin=3, name="crates"),
       prop(CRATES % 1, 808, 1745, scale=0.3, solid=True, margin=3, name="crates"),
       _unit(FOOTMAN, 854, 1700, 270, 0.3, "Scarlet footman")]
    # Fairbanks' chamber, behind the chancel: his shelves round the wall.
    + [prop(BOOKSHELF % 1, x, y, yaw=yaw, scale=0.26) for x, y, yaw in ((474, 1988, 315), (550, 1988, 225))]
    + [_unit(CLERIC, 512, 1945, 270, 0.32, "High Inquisitor Fairbanks", 6)]
)

SCARLET_CATHEDRAL = {
    "id": "scarlet_cathedral", "name": "Scarlet Cathedral", "version": 1, "folder": "ScarletCathedral",
    "size": (1024, 2048), "laps": 1,
    "rooms": SC_ROOMS, "gates": SC_GATES, "route": SC_ROUTE, "spawn": (790, 110, "west"),
    "props": SC_PROPS, "pools": SC_POOLS,
    "lean": 0.6, "team": (0.72, 0.04, 0.04), "supersample": 3,
    "replaceables": {31: "war3.w3mod:replaceabletextures/lordaerontree/lordaeronsummertree.dds"},
    "floors": {
        "hall": {"tile": T + "cityscape/city_squaretiles.dds", "shade": (0.92, 0.88, 0.82, 0.8)},
        "door": {"tile": T + "cityscape/city_squaretiles.dds", "shade": (0.92, 0.88, 0.82, 0.8)},
        "lawn": {"tile": T + "cityscape/city_grass.dds", "shade": (0.92, 1.0, 0.9)},
        "walk": {"tile": T + "cityscape/city_roundtiles.dds", "shade": (0.96, 0.95, 0.92)},
        "cobbles": {"tile": T + "village/village_cobblepath.dds", "shade": (1.1, 1.06, 1.0)},
        "stairs": {"tile": T + "cityscape/city_bricktiles.dds", "shade": (0.92, 0.9, 0.86)},
        "terrace": {"tile": T + "cityscape/city_squaretiles.dds", "shade": (0.86, 0.85, 0.84, 0.25)},
        "nave": {"tile": T + "cityscape/city_squaretiles.dds", "shade": (0.80, 0.76, 0.72, 0.45)},
        "wood": {"parquet": {"block": 32, "plank": 8}},
    },
    "wall": {"face": (T + "cityscape/city_cliff1.dds", (0, 0, 192, 64), (0.86, 0.84, 0.8)),
             "height": 70, "top": (34, 30, 30), "coping": (150, 140, 124)},
    "open_sky": ["lower garden", "south walk", "lower west walk", "lower east walk", "west platform",
                 "west stairs", "east stairs", "east platform", "upper garden", "upper west walk",
                 "upper east walk", "cathedral terrace", "door steps"],
    "portal": (850, 110, 38),
    "carpets": [([(860, 110), (512, 110), (512, 250)], 40),
                # The gardens' walks' runners.
                ([(255, 300), (255, 580)], 26), ([(769, 300), (769, 580)], 26),
                ([(155, 640), (155, 1010)], 26), ([(869, 640), (869, 1010)], 26),
                ([(512, 1150), (512, 1640)], 60),
                ([(350, 1250), (350, 1430)], 36), ([(674, 1250), (674, 1430)], 36),
                ([(512, 1676), (512, 1745)], 50),
                ([(512, 1790), (512, 1925)], 40)],
    "kerbed": ["walk", "cobbles", "terrace"], "lawn": "lawn",
    "stairs": [{"room": "west stairs", "tread": 10, "axis": "y", "from": 40, "to": 10},
               {"room": "east stairs", "tread": 10, "axis": "y", "from": 40, "to": 10},
               {"room": "door steps", "tread": 8, "axis": "y"},
               {"room": "chancel steps", "tread": 8, "axis": "y", "from": 8, "to": 8}],
    "water": {"rim": 5, "tint": (0.20, 0.40, 0.46)},
    "waterfalls": [{"x0": 452, "x1": 572, "y": 574, "drop": 28}],
    "jets": [(472, 420, 10), (552, 420, 10), (472, 470, 10), (552, 470, 10), (472, 520, 10), (552, 520, 10)],
    "moonlight": (204, 232, 214), "mist": (146, 164, 156),
}

DUNGEONS = [SCARLET_GRAVEYARD, SCARLET_LIBRARY, SCARLET_ARMORY, SCARLET_CATHEDRAL]
