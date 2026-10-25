"""Scarlet Crusade Cup layouts for build_dungeon_tracks.py: dungeon sprints.

A dungeon course is open floor, not a road: axis-aligned rooms (halls,
corridors, chambers, a cloister's lawns and paths), each "road" (stone) or
"rough" (grass, which slows), with solid scenery standing on them. The
course is a sprint (`laps` 1): one run from the spawn through the gates, in
order, to the finish. Collision is Dungeon.lua's: the kart centre stays
WALL_INSET inside the rooms and outside every solid box grown by the same
inset. Where rooms meet, they overlap by at least DOOR_OVERLAP (twice the
inset), so the karts' floor runs on from one to the other.

World units, bottom-left origin, one texel per unit in the picture. The
painter (dungeon_paint.py) reads `floor` styles, walls, lights and props
from the same layout.
"""
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
    room("chamber door", 1640, 380, 1760, 520, floor="door"),
    room("chamber", 1380, 300, 1640, 660, floor="chamber"),
    room("chamber wings", 1340, 340, 1680, 620, floor="chamber"),
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
    return any(r["x0"] <= x <= r["x1"] and r["y0"] <= y <= r["y1"] for r in rooms)


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
     prop(BRAZIER, 205, 528, scale=0.3, light=TOMBLIGHT, tint=(0.7, 1.0, 0.75)),
     prop(SUMMER + "skullpile/skullpile1.mdx", 55, 705, scale=0.26),
     prop(SUMMER + "skullpile/skullpile2.mdx", 55, 534, scale=0.26)]
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
       prop(CITY + "props/citystonebench/citystonebench.mdx", 830, 905, scale=0.28),
       prop(CITY + "props/citystonebench/citystonebench.mdx", 960, 905, scale=0.28),
       prop(CITY + "props/citystonebench/citystonebench.mdx", 830, 466, scale=0.28),
       prop(CITY + "props/citystonebench/citystonebench.mdx", 960, 466, scale=0.28),
       prop(SUMMER + "sittingcorpse/sittingcorpse.mdx", 610, 760, scale=0.3),
       prop(NORTHREND + "props/northrendbrokencolumn/northrendbrokencolumn0.mdx", 740, 900, scale=0.2,
            solid=solid_at(740, 900, 8, 8), name="broken column", tint=(0.9, 0.9, 0.92)),
       prop(DE + "units/human/scarletfootman/scarletfootman.mdx", 1005, 745, yaw=225, scale=0.3,
            solid=solid_at(1005, 745, 6, 6), name="Scarlet guard"),
       prop(DE + "units/human/scarletfootman/scarletfootman.mdx", 1005, 500, yaw=135, scale=0.3,
            solid=solid_at(1005, 500, 6, 6), name="Scarlet guard"),
       prop(UNITS + "creeps/bansheeghost/bansheeghost.mdx", 430, 800, yaw=315, scale=0.26, name="ghost"),
       prop(UNITS + "creeps/bansheeghost/bansheeghost.mdx", 610, 470, yaw=45, scale=0.26, name="ghost"),
       prop(UNITS + "creeps/bansheeghost/bansheeghost.mdx", 840, 600, yaw=180, scale=0.26, name="ghost"),
       prop(UNITS + "creeps/zombie/zombie.mdx", 520, 790, yaw=225, scale=0.3, solid=solid_at(520, 790, 6, 6),
            name="zombie"),
       prop(UNITS + "undead/skeleton/skeleton.mdx", 390, 420, yaw=90, scale=0.3, solid=solid_at(390, 420, 6, 6),
            name="skeleton")]
    + [prop(BANNER % 0, 1022, 724, scale=0.3), prop(BANNER % 1, 1022, 508, scale=0.3)]
    # The Chamber of Atonement: a torture table in the middle, Interrogator
    # Vishas and a torturer by the east wing, an iron maiden, a cage and
    # chain posts by the north wall, braziers at the cross's corners.
    + [prop(DUNGEON + "torturetable/torturetable.mdx", 1510, 480, yaw=0, scale=0.34, solid=True, margin=2,
            name="torture table"),
       prop(DE + "units/human/scarletinvoker/scarletinvoker.mdx", 1600, 600, yaw=225, scale=0.32,
            solid=solid_at(1600, 600, 7, 7), name="Interrogator Vishas"),
       prop(DE + "units/human/scarletcleric/scarletcleric.mdx", 1560, 410, yaw=135, scale=0.28,
            solid=solid_at(1560, 410, 7, 7), name="torturer"),
       prop(DUNGEON + "ironmaiden/ironmaiden.mdx", 1420, 642, scale=0.3, name="iron maiden"),
       prop(SUMMER + "cage/cage.mdx", 1640, 588, scale=0.26, solid=solid_at(1640, 588, 9, 8), name="cage"),
       prop(DUNGEON + "chainpost/chainpost.mdx", 1500, 650, scale=0.24, name="chains"),
       prop(SUMMER + "skullpile/skullpile0.mdx", 1352, 600, scale=0.26),
       prop(SUMMER + "skullpile/skullpile3.mdx", 1352, 356, scale=0.26),
       prop(SUMMER + "weapons/weapons.mdx", 1668, 356, scale=0.3)]
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
       prop(SUMMER + "armorrack/armorrack.mdx", 1190, 650, yaw=0, scale=0.3),
       prop(DUNGEON + "bench/bench.mdx", 1192, 470, yaw=0, scale=0.3)]
    + wall_props(SG_ROOMS, "north hall", "east", TORCH, 120, light=TORCHLIGHT, scale=0.3, start=150)
    + wall_props(SG_ROOMS, "north hall", "west", TORCH, 120, light=TORCHLIGHT, scale=0.3, start=270)
    + wall_props(SG_ROOMS, "stairs", "north", TORCH, 110, light=TORCHLIGHT, scale=0.3, start=1060)
    + wall_props(SG_ROOMS, "west hall", "east", TORCH, 110, light=TORCHLIGHT, scale=0.3, start=640)
    + [prop(TORCH, 1735, 222, scale=0.3, light=TORCHLIGHT)]
    + _graveyard(SG_KEEP)
)

SCARLET_GRAVEYARD = {
    "id": "scarlet_graveyard", "name": "Scarlet Graveyard", "version": 1, "folder": "ScarletGraveyard",
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

DUNGEONS = [SCARLET_GRAVEYARD]
