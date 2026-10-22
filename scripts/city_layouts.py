"""Capital Cities Cup layouts: the authored geometry of each city circuit.

Shared by build_city_tracks.py (scenery, preview pictures) and the generated
addon/AzerothKart/Courses.lua data. World units: x east, y north, origin at
the map's south-west corner. One terrain cell of Warcraft III art is 32 units
(scenery models are drawn at 0.25 world units per model unit).

A city circuit is a street circuit traced through the city: a smooth closed
centerline (plus open branches such as the start grid's approach). The road
is every point within ROAD_RADIUS of it (the same capsule road as Mirage
Raceway); the kart centre may go WALL_RADIUS from it (a rough kerb-side strip)
and no further: beyond stand the city's walls, buildings and canal parapets,
drawn KART units further out so a kart at the wall does not overlap them.
Plazas are open paved squares on the course. Gates are axis-aligned lines
from wall to wall, named after the district they open; the last is the
start/finish line. Solids are axis-aligned boxes inside the street (a
fountain on a plaza).
"""
from math import atan2, cos, pi, sin, sqrt

ROAD_RADIUS = 56          # road width 112, as on Mirage
WALL_RADIUS = 76          # the kart centre's reach: a 20-unit rough strip beyond the paving
KART = 14                 # the street's walls stand this far beyond WALL_RADIUS
WALL_INSET = 18           # kart centre clearance from the perimeter and solids
ARC_STEP = 24.0           # target centerline spacing round a corner


def fillet(corners):
    """Dense closed centerline from [(x, y, radius)] corners (radius 0: sharp)."""
    n = len(corners)
    points = []
    for i in range(n):
        px, py, _ = corners[i - 1]
        cx, cy, r = corners[i]
        nx, ny, _ = corners[(i + 1) % n]
        ax, ay = px - cx, py - cy
        bx, by = nx - cx, ny - cy
        la, lb = sqrt(ax * ax + ay * ay), sqrt(bx * bx + by * by)
        ax, ay, bx, by = ax / la, ay / la, bx / lb, by / lb
        if r <= 0:
            points.append((cx, cy))
            continue
        # Half the interior angle between the legs; tangent distance r / tan(half).
        half = abs(atan2(ax * by - ay * bx, ax * bx + ay * by)) / 2.0
        t = r * cos(half) / sin(half)
        assert t < la / 2 + 1e-6 and t < lb / 2 + 1e-6, f"fillet radius {r} too large at corner {i}"
        sx, sy = cx + ax * t, cy + ay * t            # tangent point on the incoming leg
        ex, ey = cx + bx * t, cy + by * t            # tangent point on the outgoing leg
        # Arc centre: along the bisector, at distance r / sin(half).
        mx, my = ax + bx, ay + by
        ml = sqrt(mx * mx + my * my)
        d = r / sin(half)
        ox, oy = cx + mx / ml * d, cy + my / ml * d
        a0, a1 = atan2(sy - oy, sx - ox), atan2(ey - oy, ex - ox)
        sweep = a1 - a0
        while sweep > pi:
            sweep -= 2 * pi
        while sweep < -pi:
            sweep += 2 * pi
        steps = max(2, int(abs(sweep) * r / ARC_STEP + 0.999))
        for k in range(steps + 1):
            a = a0 + sweep * k / steps
            points.append((ox + r * cos(a), oy + r * sin(a)))
    out = []
    for x, y in points:
        q = (round(x, 1), round(y, 1))
        if not out or (abs(out[-1][0] - q[0]) > 0.05 or abs(out[-1][1] - q[1]) > 0.05):
            out.append(q)
    if abs(out[0][0] - out[-1][0]) < 0.05 and abs(out[0][1] - out[-1][1]) < 0.05:
        out.pop()
    return out


def gate(name, x, y, heading):
    """An axis-aligned gate across a straight road through (x, y), facing `heading`
    ('north', 'south', 'east', 'west'): the required travel direction."""
    nx, ny = {"north": (0, 1), "south": (0, -1), "east": (1, 0), "west": (-1, 0)}[heading]
    if nx:
        return {"name": name, "ax": x, "ay": y - ROAD_RADIUS, "bx": x, "by": y + ROAD_RADIUS, "nx": nx, "ny": ny}
    return {"name": name, "ax": x - ROAD_RADIUS, "ay": y, "bx": x + ROAD_RADIUS, "by": y, "nx": nx, "ny": ny}


def catmull_rom(points, closed=True, step=16.0, tension=0.5):
    """A smooth curve through `points` (centripetal Catmull-Rom), resampled to
    about `step` units, rounded to 0.1. Open curves keep both end points."""
    pts = list(points)
    n = len(pts)
    out = []
    count = n if closed else n - 1
    for i in range(count):
        p0 = pts[(i - 1) % n] if closed or i > 0 else pts[0]
        p1, p2 = pts[i], pts[(i + 1) % n]
        p3 = pts[(i + 2) % n] if closed or i + 2 < n else pts[-1]

        def knot(t, a, b):
            d = sqrt((b[0] - a[0]) ** 2 + (b[1] - a[1]) ** 2)
            return t + max(d, 1e-6) ** tension
        t0 = 0.0
        t1 = knot(t0, p0, p1)
        t2 = knot(t1, p1, p2)
        t3 = knot(t2, p2, p3)
        length = sqrt((p2[0] - p1[0]) ** 2 + (p2[1] - p1[1]) ** 2)
        k = max(1, int(length / step + 0.5))
        for j in range(k):
            t = t1 + (t2 - t1) * j / k

            def lerp(a, b, ta, tb):
                if tb - ta == 0:
                    return a
                w = (t - ta) / (tb - ta)
                return (a[0] + (b[0] - a[0]) * w, a[1] + (b[1] - a[1]) * w)
            a1, a2, a3 = lerp(p0, p1, t0, t1), lerp(p1, p2, t1, t2), lerp(p2, p3, t2, t3)
            b1, b2 = lerp(a1, a2, t0, t2), lerp(a2, a3, t1, t3)
            out.append(lerp(b1, b2, t1, t2))
    if not closed:
        out.append(pts[-1])
    rounded = []
    for x, y in out:
        q = (round(x, 1), round(y, 1))
        if not rounded or abs(rounded[-1][0] - q[0]) > 0.05 or abs(rounded[-1][1] - q[1]) > 0.05:
            rounded.append(q)
    return rounded


def smooth(points, passes=1, closed=True):
    """Light neighbour averaging of hand-traced control points."""
    pts = list(points)
    for _ in range(passes):
        n = len(pts)
        new = []
        for i in range(n):
            if not closed and (i == 0 or i == n - 1):
                new.append(pts[i])
                continue
            a, b, c = pts[i - 1], pts[i], pts[(i + 1) % n]
            new.append(((a[0] + 2 * b[0] + c[0]) / 4, (a[1] + 2 * b[1] + c[1]) / 4))
        pts = new
    return pts


def gate_on(name, line, x, y, radius=None):
    """An axis-aligned gate across the street where the centerline passes
    nearest (x, y): across the travel direction, long enough to span the
    street wall to wall at that angle, facing the direction of travel."""
    radius = radius or WALL_RADIUS
    best, index = None, 0
    for i in range(len(line)):
        d = (line[i][0] - x) ** 2 + (line[i][1] - y) ** 2
        if best is None or d < best:
            best, index = d, i
    (ax, ay), (bx, by) = line[index - 1], line[(index + 1) % len(line)]
    cx, cy = line[index]
    dx, dy = bx - ax, by - ay
    length = sqrt(dx * dx + dy * dy)
    dx, dy = dx / length, dy / length
    def reach(ux, uy):
        # Distance along (ux, uy) from the centre to the road edge, by bisection
        # against the local centerline (the road may curve across the gate).
        lo, hi = 0.0, 4.0 * radius
        near = [(line[(index + k) % len(line)], line[(index + k + 1) % len(line)]) for k in range(-12, 12)]

        def inside(t):
            px, py = cx + ux * t, cy + uy * t
            return min(_segment_distance(px, py, a, b) for a, b in near) < radius
        for _ in range(40):
            mid = (lo + hi) / 2
            if inside(mid):
                lo = mid
            else:
                hi = mid
        return hi + 1.0
    if abs(dy) >= abs(dx):        # mostly north/south travel: a horizontal gate
        ny = 1 if dy > 0 else -1
        return {"name": name, "ax": round(cx - reach(-1, 0), 1), "ay": round(cy, 1),
                "bx": round(cx + reach(1, 0), 1), "by": round(cy, 1), "nx": 0, "ny": ny}
    nx = 1 if dx > 0 else -1
    return {"name": name, "ax": round(cx, 1), "ay": round(cy - reach(0, -1), 1), "bx": round(cx, 1),
            "by": round(cy + reach(0, 1), 1), "nx": nx, "ny": 0}


def _segment_distance(px, py, a, b):
    (ax, ay), (bx, by) = a, b
    dx, dy = bx - ax, by - ay
    length = dx * dx + dy * dy
    t = 0.0 if length == 0 else max(0.0, min(1.0, ((px - ax) * dx + (py - ay) * dy) / length))
    ex, ey = px - (ax + t * dx), py - (ay + t * dy)
    return sqrt(ex * ex + ey * ey)




# ---------------------------------------------------------------------------
# Scenery helpers.
#
# prop(model, x, y, ...) places one Warcraft III model with its origin at
# world (x, y), its front turned to `yaw` degrees (270: facing south, the
# game's default). solid=True turns its ground extent (shrunk by `margin`)
# into a collision box: only for models standing inside the street. `recolor`
# moves texture hues: [(low, high, target, min_saturation[, saturation_scale,
# value_scale])] in degrees; `stone` = (gain, offset) pales the greyish
# texels a recolor leaves alone (wc3render.render).

CITY = "war3.w3mod:doodads/cityscape/"
HUMAN = "war3.w3mod:buildings/human/"
OTHER = "war3.w3mod:buildings/other/"
SUMMER = "war3.w3mod:doodads/lordaeronsummer/"
TERRAIN = "war3.w3mod:doodads/terrain/"
DALARAN = "war3.w3mod:doodads/dalaran/structures/"
TERRAINART = "war3.w3mod:terrainart/"


def prop(model, x, y, yaw=270, scale=0.25, sequence="Stand", solid=False, margin=4, name=None, tint=None,
         team=None, recolor=None, stone=None, light=None, cut=None, alpha_shadow=False):
    """`light` = (radius, (r, g, b)): a pool of light painted on the ground
    round the model (a brazier's, a lantern's). `cut`: drop the model's
    triangles lying wholly this low (world units; a Barrens rock's patch of
    ground). `alpha_shadow`: the shadow follows the texture's cut-outs."""
    item = {"model": model, "x": x, "y": y, "yaw": yaw, "scale": scale, "sequence": sequence,
            "solid": solid, "margin": margin, "name": name or model.rsplit("/", 1)[-1].rsplit(".", 1)[0],
            "tint": tint, "team": team, "recolor": recolor}
    if stone:
        item["stone"] = tuple(stone)
    if light:
        item["light"] = light
    if cut is not None:
        item["cut"] = cut
    if alpha_shadow:
        item["alpha_shadow"] = True
    return item


def mesh_prop(mesh, x, y, yaw=270, scale=1.0, **kw):
    """prop() for a procedural model (city_meshes: the Great Forge's anvil
    and pumps), `scale` world units per mesh unit. It is drawn like a
    Warcraft III model but reads no Warcraft III file."""
    item = prop("mesh:" + mesh, x, y, yaw=yaw, scale=scale, name=mesh, **kw)
    item["mesh"] = mesh
    return item


def box(name, x0, y0, x1, y1):
    return {"id": name, "x": x0, "y": y0, "width": x1 - x0, "height": y1 - y0}


def kind(model, **kw):
    """A palette entry for generated buildings: the model and its options
    (`limit`: at most this many in each district)."""
    reach = kw.pop("reach", None)
    yaws = kw.pop("yaws", None)
    weight = kw.pop("weight", None)
    limit = kw.pop("limit", None)
    entry = {"prop": prop(model, 0, 0, **kw)}
    if limit is not None:
        entry["limit"] = limit
    if weight is not None:
        entry["weight"] = weight
    if reach is not None:
        entry["reach"] = reach
    if yaws is not None:
        entry["yaws"] = yaws
    return entry


# Roof recolors: Warcraft III's green and red slate made Stormwind's blue,
# or the Mage Quarter's violet.
BLUE_ROOFS = [(70.0, 175.0, 222.0, 0.16)]
VIOLET_ROOFS = [(70.0, 175.0, 272.0, 0.16), (195.0, 250.0, 272.0, 0.16)]
# The Cathedral of Light as Stormwind has it: its dark moss slate made bright
# gold, its grey stone pale and warm.
GOLD_ROOFS = [(70.0, 175.0, 40.0, 0.10, 2.4, 2.6)]
CATHEDRAL_STONE, CATHEDRAL_TINT = (1.5, 0.34), (1.03, 1.0, 0.95)


# ---------------------------------------------------------------------------
# Stormwind City Circuit
#
# The route follows the owner's own line on the in-game Stormwind map: the
# start grid in the Valley of Heroes, through the main gate into the Trade
# District, along the canal by Old Town, round the head of the canal in the
# Dwarven District, through Cathedral Square, down the canal past the Park,
# along the Mage Quarter and back into the Trade District. The canals stay
# on the karts' left all lap; the districts line the right. Positions are
# traced on that map (882 x 590 pixels) and carried into the world by MAP;
# the canal outlines were traced from the map's water (low-saturation
# texels) with an offline tracing aid, then simplified by hand.

MAP = {"scale": 4.65, "left": 228, "bottom": 530}   # world = ((mx - left), (bottom - my)) * scale


def W(mx, my):
    return ((mx - MAP["left"]) * MAP["scale"], (MAP["bottom"] - my) * MAP["scale"])


def poly(*points):
    """A world polygon from map points."""
    return [W(*q) for q in points]


def mprop(model, mx, my, **kw):
    """prop() at a map position."""
    x, y = W(mx, my)
    return prop(model, round(x, 1), round(y, 1), **kw)


SW_LOOP = [  # driving order, from the main gate north through the Trade District
    (520, 372), (521, 350), (522, 333), (526, 321), (533, 314), (540, 308), (547, 302), (555, 297),
    (566, 292), (573, 283),
    (570, 272), (563, 262), (561, 250), (563, 238), (572, 226), (575, 214), (572, 204), (562, 201),
    (548, 205), (536, 205), (525, 198), (514, 185), (504, 170), (496, 160), (486, 156), (476, 159),
    (471, 169), (473, 181), (467, 194), (455, 201), (443, 205), (430, 208), (416, 210), (400, 211),
    (384, 211), (369, 213), (357, 219), (349, 230), (345, 245), (343, 261), (343, 276), (342, 286),
    (339, 294), (335, 302), (331, 310), (324, 320), (316, 333), (303, 345), (295, 357), (297, 369), (307, 373), (320, 366),
    (338, 359), (360, 358), (382, 362), (400, 370), (413, 377), (426, 380), (439, 379), (451, 375),
    (462, 372), (474, 373), (487, 378), (500, 385), (511, 387),
]
SW_VALLEY = [(626, 506), (604, 482), (576, 450), (548, 418), (527, 395), (520, 380)]   # start spur

def straighten(line, at, length):
    """`line` with the stretch of `length` centred on arc `at` made straight:
    its points move onto the chord between the stretch's ends (a bridge)."""
    cum = [0.0]
    for i in range(1, len(line)):
        cum.append(cum[-1] + sqrt((line[i][0] - line[i - 1][0]) ** 2 + (line[i][1] - line[i - 1][1]) ** 2))

    def point(s):
        for i in range(1, len(line)):
            if cum[i] >= s:
                t = (s - cum[i - 1]) / max(1e-9, cum[i] - cum[i - 1])
                (ax, ay), (bx, by) = line[i - 1], line[i]
                return ax + (bx - ax) * t, ay + (by - ay) * t
        return line[-1]
    lo, hi = at - length / 2, at + length / 2
    (ax, ay), (bx, by) = point(lo), point(hi)
    out = []
    for i, p in enumerate(line):
        if lo < cum[i] < hi:
            t = (cum[i] - lo) / (hi - lo)
            p = (round(ax + (bx - ax) * t, 1), round(ay + (by - ay) * t, 1))
        out.append(p)
    return out


# The bridges between districts (map point at the canal, length along the
# street, how far the canal runs out left and right): the street is made
# straight across each, with a short straight approach at both ends.
SW_BRIDGES = [
    ("Old Town bridge", (540, 308), 132, 96, 170),
    ("Park bridge", (337, 298), 132, 96, 70),
    ("Trade District bridge", (432, 380), 132, 96, 140),
]
STORMWIND_LINE = catmull_rom([W(*p) for p in smooth(SW_LOOP, passes=2)], step=16.0)
STORMWIND_SPUR = catmull_rom([W(*p) for p in SW_VALLEY], closed=False, step=16.0)


def arc_at(line, mx, my, to_world=None):
    """Arc length along the closed `line` (from its first point) where it
    passes nearest the map point (mx, my) (Stormwind's map unless
    `to_world` gives another city's)."""
    x, y = (to_world or W)(mx, my)
    best, at, total = None, 0.0, 0.0
    for i in range(len(line)):
        a, b = line[i], line[(i + 1) % len(line)]
        dx, dy = b[0] - a[0], b[1] - a[1]
        length = sqrt(dx * dx + dy * dy)
        t = 0.0 if length == 0 else max(0.0, min(1.0, ((x - a[0]) * dx + (y - a[1]) * dy) / (length * length)))
        d = (a[0] + dx * t - x) ** 2 + (a[1] + dy * t - y) ** 2
        if best is None or d < best:
            best, at = d, total + length * t
        total += length
    return round(at, 1)


for _name, _point, _length, _left, _right in SW_BRIDGES:
    STORMWIND_LINE = straighten(STORMWIND_LINE, arc_at(STORMWIND_LINE, *_point), _length + 70)


def sw_arc(mx, my):
    return arc_at(STORMWIND_LINE, mx, my)


# Cathedral Square: the course passes right at the foot of the Cathedral's
# steps (the owner's line on his screenshot of the square), the square and
# its fountain across the street. World units.
CATHEDRAL_AT = sw_arc(392, 211)
CATHEDRAL_SQUARE = [(652.0, 1404.0), (884.0, 1404.0), (884.0, 1184.0), (652.0, 1184.0)]
CATHEDRAL_FOUNTAIN = (768.0, 1290.0)


def along_spur(distance, spur=None):
    """The point `distance` units along a start spur (Stormwind's unless
    given), and its heading."""
    spur = spur or STORMWIND_SPUR
    total = 0.0
    for i in range(1, len(spur)):
        (ax, ay), (bx, by) = spur[i - 1], spur[i]
        step = sqrt((bx - ax) ** 2 + (by - ay) ** 2)
        if total + step >= distance:
            t = (distance - total) / step
            return (round(ax + (bx - ax) * t, 1), round(ay + (by - ay) * t, 1)), atan2(by - ay, bx - ax)
        total += step
    raise ValueError(distance)


STORMWIND_TERRAIN = [   # draw order, lowest first
    {"name": "grass", "tile": TERRAINART + "lordaeronsummer/lords_grass.dds", "variety": 45},
    {"name": "grassdark", "tile": TERRAINART + "lordaeronsummer/lords_grassdark.dds", "variety": 45},
    {"name": "dirt", "tile": TERRAINART + "cityscape/city_dirtrough.dds", "variety": 40},
    {"name": "blackmarble", "tile": TERRAINART + "cityscape/city_blackmarble.dds", "shade": 1.5},
    {"name": "squares", "tile": TERRAINART + "cityscape/city_squaretiles.dds", "shade": 0.90},
    {"name": "bricks", "tile": TERRAINART + "cityscape/city_bricktiles.dds", "shade": 0.86},
    {"name": "dalaran", "tile": TERRAINART + "dalaran/dalaran_squaretiles.dds", "shade": 0.92},
    {"name": "marble", "tile": TERRAINART + "cityscape/city_whitemarble.dds", "shade": 0.82},
    {"name": "round", "tile": TERRAINART + "cityscape/city_roundtiles.dds", "shade": 0.88},
]

# Warm stone for Old Town, soot for the Dwarven District.
OLD_TOWN, DWARVEN = (1.06, 0.94, 0.86), (0.86, 0.82, 0.80)

# The city's blue-roofed timber houses (Warcraft III's Lordaeron city
# buildings; green slate recolored blue), shared by most districts.
HOUSES = [
    kind(OTHER + "citybuildinglarge_135/citybuildinglarge_135.mdx", recolor=BLUE_ROOFS),
    kind(OTHER + "citybuildinglarge_90/citybuildinglarge_90.mdx", recolor=BLUE_ROOFS),
    kind(OTHER + "citybuildingsmall0_2/citybuildingsmall0_2.mdx", recolor=BLUE_ROOFS),
    kind(OTHER + "citybuildingsmall0_0/citybuildingsmall0_0.mdx", recolor=BLUE_ROOFS),
    kind(OTHER + "citybuildingsmall90_0/citybuildingsmall90_0.mdx", recolor=BLUE_ROOFS),
    kind(OTHER + "citybuildingsmall90_1/citybuildingsmall90_1.mdx", recolor=BLUE_ROOFS),
    kind(OTHER + "citybuildingsmall135_2/citybuildingsmall135_2.mdx", recolor=BLUE_ROOFS),
    kind(OTHER + "citybuildingsmall45_1/citybuildingsmall45_1.mdx", recolor=BLUE_ROOFS),
]
TREES = [
    kind(TERRAIN + "lordaerontree/lordaerontree%d.mdx" % n) for n in (0, 1, 2, 3, 4, 5)
] + [kind(TERRAIN + "cityscapetree/cityscapetree%d.mdx" % n) for n in (0, 1)]

# Low street furniture for the strip a tall building must leave between its
# roof and a street to its north (heights lean north).
BENCH = kind(CITY + "props/citystonebench/citystonebench.mdx")
FLOWERS = kind(CITY + "plants/flowerbedstraight/flowerbedstraight.mdx")
BUSH = kind(CITY + "plants/citybush/citybush.mdx")
POT = kind(CITY + "plants/pottedplant/pottedplant.mdx", weight=0.5)
CRATES = kind(CITY + "props/emptycrates/emptycrates0.mdx", weight=0.6)
CART = kind(SUMMER + "props/haycart/haycart.mdx", weight=0.4)
BARROW = kind(SUMMER + "props/wheelbarrel/wheelbarrel.mdx", weight=0.4)
STREET_TRIM = [BENCH, FLOWERS, BUSH, POT, CRATES]

# Stormwind's people, standing back from the street to watch: citizens,
# the city guard, priests by the Cathedral (Warcraft III units).
UNITS = "war3.w3mod:units/"
MAN = kind(UNITS + "critters/villagerman/villagerman.mdx")
MAN1 = kind(UNITS + "critters/villagerman1/villagerman1.mdx")
WOMAN = kind(UNITS + "critters/villagerwoman/villagerwoman.mdx")
KID = kind(UNITS + "critters/villagerkid/villagerkid.mdx", weight=0.6)
KID1 = kind(UNITS + "critters/villagerkid1/villagerkid1.mdx", weight=0.6)
PEASANT = kind(UNITS + "human/peasant/peasant.mdx", weight=0.6)
GUARD = kind(UNITS + "human/footman/footman.mdx", weight=0.5)
PRIEST = kind(UNITS + "human/priest/priest.mdx")
CITIZENS = [MAN, MAN1, WOMAN, KID, KID1, PEASANT, GUARD]

STORMWIND_DISTRICTS = [
    {"name": "Trade District", "ground": "squares",
     "seeds": [W(482, 338), W(512, 372), W(455, 386), W(540, 404)],
     "buildings": HOUSES + [
         kind(OTHER + "marketplace/marketplace.mdx", reach=70, weight=0.6),
         kind(OTHER + "fruitstand/fruitstand.mdx", reach=70, weight=0.6),
     ],
     "trim": STREET_TRIM + [CART, BARROW], "people": CITIZENS},
    {"name": "Old Town", "ground": "bricks", "tint": OLD_TOWN,
     "seeds": [W(630, 252), W(652, 300), W(612, 330), W(606, 214)],
     "buildings": HOUSES + [
         kind(OTHER + "citybuildingsmall0_1/citybuildingsmall0_1.mdx"),
         kind(OTHER + "citybuildingsmall45_0/citybuildingsmall45_0.mdx"),
         kind(OTHER + "citybuildingsmall90_2/citybuildingsmall90_2.mdx"),
         kind(HUMAN + "humanbarracks/humanbarracks.mdx"),
     ],
     "trim": STREET_TRIM + [CART], "people": CITIZENS},
    {"name": "Dwarven District", "ground": "blackmarble", "tint": DWARVEN,
     "seeds": [W(520, 136), W(566, 160), W(470, 132), W(610, 150)],
     "buildings": [
         kind(HUMAN + "blacksmith/blacksmith.mdx"),
         kind(HUMAN + "workshop/workshop.mdx"),
         kind(HUMAN + "humanlumbermill/humanlumbermill.mdx"),
         kind(OTHER + "grainwarehouse/grainwarehouse.mdx"),
         kind(OTHER + "citybuildingsmall0_2/citybuildingsmall0_2.mdx", recolor=BLUE_ROOFS),
         kind(OTHER + "citybuildingsmall90_0/citybuildingsmall90_0.mdx", recolor=BLUE_ROOFS),
     ],
     "trim": [CRATES, BARROW, kind(SUMMER + "props/armorrack/armorrack.mdx"),
              kind(SUMMER + "props/weapons/weapons.mdx")], "people": [PEASANT, MAN1, GUARD]},
    {"name": "Cathedral Square", "ground": "marble",
     "seeds": [W(380, 206), W(430, 264), W(340, 236), W(470, 232)],
     "buildings": HOUSES, "trim": [BENCH, FLOWERS, BUSH, kind(CITY + "props/city_oblisk/city_oblisk.mdx")],
     "people": [PRIEST, PRIEST, MAN, WOMAN, KID, GUARD]},
    {"name": "The Park", "ground": "grass",
     "seeds": [W(244, 300), W(262, 252), W(270, 340)],
     "buildings": TREES + [kind(CITY + "plants/citybush/citybush.mdx")],
     "trim": [BUSH, FLOWERS, kind(CITY + "plants/flowerbedangled/flowerbedangled.mdx"), BENCH],
     "people": [KID, KID1, WOMAN, MAN]},
    {"name": "Mage Quarter", "ground": "dalaran",
     "seeds": [W(322, 440), W(380, 420), W(276, 400), W(350, 395)],
     "buildings": [
         kind(DALARAN + "dalaranbuildinga/dalaranbuildinga.mdx"),
         kind(DALARAN + "dalaranbuildingb/dalaranbuildingb.mdx"),
         kind(DALARAN + "dalaranenclavehouse/dalaranenclavehouse.mdx"),
         kind(DALARAN + "dalaranenclavehouseb/dalaranenclavehouseb.mdx"),
         kind(OTHER + "citybuildinglarge_0/citybuildinglarge_0.mdx", recolor=VIOLET_ROOFS),
         kind(OTHER + "citybuildingsmall45_2/citybuildingsmall45_2.mdx", recolor=VIOLET_ROOFS),
         kind(OTHER + "citybuildingsmall135_0/citybuildingsmall135_0.mdx", recolor=VIOLET_ROOFS),
     ],
     "trim": [BENCH, POT, kind(CITY + "props/crystallamp/crystallamp.mdx")], "people": [MAN, WOMAN, PRIEST]},
    {"name": "Valley of Heroes", "ground": "marble",
     "seeds": [W(596, 470), W(566, 440), W(620, 500)], "buildings": [], "trim": [BUSH],
     "people": [GUARD, MAN, WOMAN]},
    {"name": "Stormwind Keep", "ground": "round",
     "seeds": [W(690, 130)], "buildings": HOUSES},
    {"name": "Canal islands", "ground": "round",
     "seeds": [W(522, 248), W(370, 330)], "buildings": HOUSES, "trim": [BENCH, FLOWERS, BUSH],
     "people": CITIZENS},
]

# Canals and lakes (map pixels), then the dry ground inside them.
STORMWIND_WATER = [
    # The north-east basin: the Trade District and Old Town arms, the head by
    # the Dwarven District and the arm down to Cathedral Square.
    poly((480, 171), (479, 175), (481, 176), (481, 179), (484, 180), (487, 184), (488, 192), (491, 197),
         (498, 193), (502, 195), (503, 198), (506, 200), (505, 208), (500, 211), (495, 210), (495, 241),
         (492, 243), (492, 251), (488, 254), (488, 257), (463, 276), (459, 283), (459, 286), (447, 291),
         (446, 295), (451, 297), (452, 302), (454, 302), (466, 292), (476, 288), (479, 285), (493, 278),
         (502, 277), (507, 273), (515, 277), (521, 276), (530, 282), (546, 297), (546, 300), (551, 303),
         (551, 308), (557, 307), (561, 309), (562, 314), (565, 316), (565, 318), (568, 318), (568, 313),
         (573, 310), (581, 312), (583, 316), (583, 321), (579, 323), (579, 326), (584, 329), (587, 335),
         (592, 337), (596, 343), (603, 344), (606, 342), (607, 338), (609, 337), (607, 327), (604, 325),
         (604, 323), (599, 317), (586, 307), (585, 303), (581, 299), (578, 300), (573, 297), (573, 291),
         (564, 282), (564, 279), (555, 273), (555, 268), (552, 266), (552, 253), (554, 239), (559, 236),
         (565, 238), (567, 236), (567, 233), (572, 230), (576, 225), (576, 213), (581, 210), (587, 212),
         (594, 202), (602, 198), (610, 191), (610, 184), (607, 178), (605, 178), (604, 181), (586, 189),
         (578, 197), (574, 199), (571, 198), (571, 207), (567, 209), (564, 207), (557, 207), (550, 211),
         (541, 211), (533, 209), (522, 203), (512, 193), (505, 182), (501, 179), (494, 179), (490, 181),
         (485, 178), (485, 170)),
    # The south-west basin round its island: north-west arm, north and west
    # bands, the east arm by the Trade District and the Mage Quarter arm.
    poly((307, 263), (311, 271), (324, 283), (328, 295), (331, 295), (341, 287), (340, 283), (331, 276),
         (323, 260), (321, 260), (321, 263), (316, 266)),
    poly((336, 295), (380, 297), (420, 298), (438, 302), (438, 310), (418, 310), (380, 309), (346, 309)),
    poly((374, 306), (365, 305), (354, 300), (351, 297), (347, 297), (336, 307), (337, 322), (331, 333),
         (322, 341), (309, 349), (305, 353), (305, 355), (297, 361), (297, 365), (299, 367), (299, 376),
         (310, 376), (318, 369), (319, 357), (324, 354), (330, 353), (335, 342), (344, 335), (344, 329),
         (346, 325), (346, 309), (353, 307), (357, 309), (359, 313), (362, 313), (365, 311), (373, 310)),
    poly((435, 302), (430, 302), (429, 304), (417, 309), (411, 309), (401, 305), (400, 308), (402, 309),
         (402, 313), (397, 316), (394, 315), (394, 319), (398, 321), (398, 329), (392, 332), (391, 343),
         (399, 348), (400, 355), (404, 356), (409, 353), (414, 355), (417, 363), (420, 362), (420, 353),
         (418, 352), (418, 343), (416, 342), (416, 338), (419, 336), (422, 328), (429, 321), (429, 319),
         (439, 312), (439, 308)),
    poly((437, 390), (437, 394), (433, 398), (433, 402), (435, 404), (435, 407), (442, 408), (443, 397),
         (439, 395), (439, 390)),
    poly((286, 371), (282, 371), (282, 373), (286, 376), (284, 385), (279, 388), (271, 386), (272, 390),
         (275, 393), (280, 392), (287, 386), (294, 383), (294, 379), (290, 377)),
    poly((308, 243), (306, 243), (299, 249), (304, 259), (306, 259), (306, 253), (311, 249)),
    # The Valley of Heroes' lakes either side of the approach.
    poly((659, 345), (649, 345), (651, 349), (651, 356), (642, 363), (637, 370), (627, 376), (627, 378),
         (618, 385), (609, 396), (598, 403), (598, 407), (602, 409), (603, 412), (610, 418), (612, 425),
         (618, 425), (626, 430), (626, 434), (623, 436), (621, 443), (614, 447), (606, 455), (608, 469),
         (612, 471), (619, 471), (624, 474), (630, 472), (639, 473), (642, 475), (653, 473), (665, 467),
         (672, 460), (672, 446), (679, 443), (682, 438), (682, 428), (684, 427), (683, 414), (685, 413),
         (683, 402), (687, 400), (684, 388), (684, 375), (676, 364), (669, 358), (667, 353)),
    poly((485, 494), (485, 496), (488, 498), (488, 504), (483, 508), (485, 514), (490, 512), (499, 519),
         (508, 522), (547, 522), (561, 526), (568, 530), (568, 540), (572, 543), (574, 543), (575, 536),
         (584, 528), (598, 519), (599, 516), (603, 513), (604, 508), (603, 503), (593, 497), (592, 490),
         (588, 487), (588, 484), (581, 480), (574, 483), (568, 483), (566, 487), (559, 491), (553, 491),
         (549, 489), (548, 483), (538, 484), (533, 480), (527, 482), (523, 480), (520, 476), (520, 472),
         (525, 469), (532, 472), (534, 475), (538, 474), (537, 468), (532, 464), (532, 461), (530, 459),
         (526, 459), (504, 475), (495, 485), (489, 489), (489, 492)),
]
STORMWIND_LAND = [
    # The north-east basin's island (four towers round a fountain).
    poly((499, 222), (508, 218), (512, 220), (514, 223), (527, 224), (530, 226), (542, 224), (549, 228),
         (550, 237), (549, 241), (546, 243), (546, 257), (544, 258), (544, 263), (546, 264), (545, 274),
         (541, 276), (532, 272), (515, 272), (512, 270), (504, 271), (495, 264), (495, 258), (500, 255),
         (501, 234), (498, 231)),
]

STORMWIND_START, STORMWIND_START_HEADING = along_spur(60.0)


def beside_spur(distance, offset):
    """The world point `offset` units left (+) or right (-) of the start spur,
    `distance` units along it."""
    (x, y), heading = along_spur(distance)
    return round(x - sin(heading) * offset, 1), round(y + cos(heading) * offset, 1)


def spur_prop(model, distance, offset, **kw):
    x, y = beside_spur(distance, offset)
    return prop(model, x, y, **kw)


# The Valley of Heroes: the heroes' statues either side of the approach, the
# kings' banners, and the main gate's towers where it enters the city.
VALLEY = []
for _k, _d in enumerate((150, 280, 410)):
    _statue = CITY + ("props/knightstatuea/knightstatuea.mdx" if _k % 2 == 0 else "props/city_statue/city_statue.mdx")
    VALLEY.append(spur_prop(_statue, _d, 182, yaw=45))
    VALLEY.append(spur_prop(_statue, _d + 60, -146, yaw=225))
VALLEY += [
    spur_prop(CITY + "structures/citywallentrance/citywallentrance.mdx", 600, 206),
    spur_prop(CITY + "structures/citywallentrance/citywallentrance.mdx", 600, -152),
]

STORMWIND = {
    "id": "stormwind_city",
    "version": 3,
    "wall_clearance": KART,  # clearance from the exposed painted union boundary
    "full_speed_to_walls": True,  # owner: no shoulder slowdown before the walls
    "name": "Stormwind City Circuit",
    "folder": "Stormwind",
    "size": (2048, 2048),
    "team": (0.16, 0.30, 0.74),                  # Stormwind blue banners and roofs
    "lean": 0.6,
    "kart_clearance": KART,
    "street_reach": 100,
    "centerline": STORMWIND_LINE,
    "branches": [STORMWIND_SPUR],
    # No open paving: in Cathedral Square the street runs between the
    # Cathedral's steps and the square (scenery, below).
    "plazas": [],
    "gates": [
        gate_on("Old Town", STORMWIND_LINE, *W(561, 252)),
        gate_on("Dwarven District", STORMWIND_LINE, *W(546, 205)),
        gate_on("Cathedral Square", STORMWIND_LINE, *W(346, 272)),
        gate_on("The Park", STORMWIND_LINE, *W(322, 321)),
        gate_on("Mage Quarter", STORMWIND_LINE, *W(352, 358)),
        gate_on("Trade District", STORMWIND_LINE, *W(521, 352)),
    ],
    "spawn": STORMWIND_START + (STORMWIND_START_HEADING,),
    "replaceables": {11: TERRAINART + "cityscape/city_cliff1.dds",
                     31: "war3.w3mod:replaceabletextures/lordaerontree/lordaeronsummertree.dds"},
    "terrain": STORMWIND_TERRAIN,
    "districts": STORMWIND_DISTRICTS,
    "zones": [
        {"terrain": "grassdark", "shape": ("poly", poly((228, 270), (282, 268), (288, 320), (240, 350),
                                                         (228, 350)))},
    ],
    "water": STORMWIND_WATER,
    "land": STORMWIND_LAND,
    # Canals beside the street (loop arcs from map points): the north-east
    # basin on the left from Old Town to Cathedral Square, the south-west
    # basin's north-west arm on the right below the square, then the basin on
    # the left past the Park and the Mage Quarter.
    "canals": [
        {"from": sw_arc(546, 304), "to": sw_arc(458, 201), "side": "left", "width": 92},
        {"from": sw_arc(348, 233), "to": sw_arc(338, 298), "side": "right", "width": 64},
        {"from": sw_arc(338, 298), "to": sw_arc(426, 380), "side": "left", "width": 92},
    ],
    # Stone bridges between the districts: the street over the canal, its
    # deck, parapets and lamps (loop arc, length along the street, how far
    # the canal runs out on each side).
    "bridges": [{"name": name, "at": sw_arc(*point), "length": length, "left": left, "right": right}
                for name, point, length, left, right in SW_BRIDGES],
    # Street paving by stretch (loop arcs from map points; the first match
    # wins; "branch" paves the start approach): each district its own.
    "sections": [
        {"name": "Old Town", "from": sw_arc(546, 304), "to": sw_arc(575, 214),
         "road": (TERRAINART + "cityscape/city_bricktiles.dds", 0.86)},
        {"name": "Dwarven District", "from": sw_arc(575, 214), "to": sw_arc(468, 192),
         "road": (TERRAINART + "cityscape/city_roundtiles.dds", 0.74)},
        {"name": "Cathedral Square", "from": sw_arc(468, 192), "to": sw_arc(338, 298),
         "road": (TERRAINART + "cityscape/city_roundtiles.dds", 0.92)},
        {"name": "The Park", "from": sw_arc(338, 298), "to": sw_arc(298, 368),
         "road": (TERRAINART + "cityscape/city_roundtiles.dds", 0.96)},
        {"name": "Mage Quarter", "from": sw_arc(298, 368), "to": sw_arc(432, 380),
         "road": (TERRAINART + "cityscape/city_roundtiles.dds", 0.88)},
        {"name": "Valley of Heroes", "branch": 1, "road": (TERRAINART + "cityscape/city_whitemarble.dds", 0.86)},
    ],
    "road_default": (TERRAINART + "cityscape/city_roundtiles.dds", 0.96),      # the Trade District
    # Side streets closed off for the race: a paved alley leaving the street
    # between the houses, its mouth walled (loop arc, side, width, length).
    "alleys": [
        {"at": sw_arc(523, 340), "side": "right", "width": 52, "length": 120},
        {"at": sw_arc(570, 252), "side": "right", "width": 48, "length": 110},
        {"at": sw_arc(505, 172), "side": "right", "width": 48, "length": 110},
        {"at": sw_arc(372, 362), "side": "right", "width": 48, "length": 110},
        {"at": sw_arc(478, 374), "side": "right", "width": 52, "length": 120},
    ],
    "bridge_depth": 15,
    "arch_every": 34,
    "water_texture": "war3.w3mod:replaceabletextures/water/water00.dds",
    "water_tint": (0.18, 0.38, 0.44),
    "water_rim": (196, 190, 176),
    "quay_face": (150, 144, 132),
    "quay_depth": 8,
    "road_tile": TERRAINART + "cityscape/city_roundtiles.dds",
    "road_shade": 0.92,
    "sidewalk_tile": TERRAINART + "cityscape/city_squaretiles.dds",
    "sidewalk_shade": 0.86,
    "plaza_tile": TERRAINART + "cityscape/city_whitemarble.dds",
    "plaza_shade": 0.88,
    # The Cathedral's steps: from the street's edge up to its doors, the
    # kingdom's blue carpet down the middle (loop arc, side, width across,
    # depth from the street's edge, carpet width). No wall in front of them.
    "steps": [{"name": "Cathedral steps", "at": CATHEDRAL_AT, "side": "right", "width": 136, "depth": 20,
               "tread": 5, "carpet": 28}],
    # Cathedral Square opposite the steps: white marble round the fountain,
    # behind a stone balustrade (world polygon, inlaid rings: centre, radius,
    # width). Houses keep off it; benches and people may stand on it.
    "squares": [{"name": "Cathedral Square", "shape": CATHEDRAL_SQUARE, "rings": [
        (CATHEDRAL_FOUNTAIN[0], CATHEDRAL_FOUNTAIN[1], 74, 6), (CATHEDRAL_FOUNTAIN[0], CATHEDRAL_FOUNTAIN[1], 52, 3)]}],
    "curb_color": (214, 208, 194),
    "gutter_color": (96, 92, 86),
    "hedged": ["The Park"],
    # A lantern-topped stone post at each corner of every bridge.
    "bridge_posts": {"prop": prop(CITY + "structures/city_lowwall_tallendcapwithlantern/"
                                  "city_lowwall_tallendcapwithlantern.mdx", 0, 0), "offset": 7, "inset": 10},
    "wall": {"thickness": 4, "height": 10, "pillar_height": 17, "pillar_every": 56,
             "face": (170, 164, 150), "cap": (224, 218, 204), "shadow": (96, 92, 86)},
    "fill": {"step": 20, "reach": 520, "gap": 2, "spacing": 3},
    "trim": {"step": 22, "reach": 60, "gap": 3, "spacing": 12},
    "people": {"step": 26, "reach": 34, "gap": 2, "spacing": 7},
    # The city guard at both ends of every bridge.
    "bridge_guards": {"prop": prop(UNITS + "human/footman/footman.mdx", 0, 0), "offset": 9, "beyond": 12},
    "furniture": [
        {"prop": prop(CITY + "props/lanternpost/lanternpost.mdx", 0, 0), "every": 150, "offset": 5,
         "start": 40, "where": "water"},
        {"prop": prop(CITY + "props/banner_long/banner_long.mdx", 0, 0), "every": 230, "offset": 6,
         "start": 120, "where": "land"},
    ],
    "solids": [],
    "props": [
        # Cathedral Square: the Cathedral of Light at the head of its steps,
        # right beside the street (`front`: placed out from the course point
        # until its plan clears the steps), lamps either side of the steps;
        # the square's fountain, lamps and trees across the street.
        dict(mprop(CITY + "structures/cathedral/cathedral.mdx", 392, 170, scale=0.42, recolor=GOLD_ROOFS,
                   stone=CATHEDRAL_STONE, tint=CATHEDRAL_TINT),
             front={"at": CATHEDRAL_AT, "side": "right", "gap": 20}),
        dict(mprop(CITY + "props/lanternpost/lanternpost.mdx", 392, 196),
             front={"at": CATHEDRAL_AT, "side": "right", "gap": 3, "across": 78}),
        dict(mprop(CITY + "props/lanternpost/lanternpost.mdx", 392, 196),
             front={"at": CATHEDRAL_AT, "side": "right", "gap": 3, "across": -78}),
        # Two priests of the Light on the upper steps, either side of the carpet.
        dict(prop(UNITS + "human/priest/priest.mdx", 0, 0),
             front={"at": CATHEDRAL_AT, "side": "right", "out": 106, "across": 26}),
        dict(prop(UNITS + "human/priest/priest.mdx", 0, 0),
             front={"at": CATHEDRAL_AT, "side": "right", "out": 106, "across": -26}),
        prop(CITY + "props/city_fountain/city_fountain.mdx", *CATHEDRAL_FOUNTAIN),
        prop(CITY + "props/lanternpost/lanternpost.mdx", CATHEDRAL_FOUNTAIN[0] - 80, CATHEDRAL_FOUNTAIN[1] + 28),
        prop(CITY + "props/lanternpost/lanternpost.mdx", CATHEDRAL_FOUNTAIN[0] + 80, CATHEDRAL_FOUNTAIN[1] + 28),
        prop(CITY + "props/lanternpost/lanternpost.mdx", CATHEDRAL_FOUNTAIN[0] - 80, CATHEDRAL_FOUNTAIN[1] - 52),
        prop(CITY + "props/lanternpost/lanternpost.mdx", CATHEDRAL_FOUNTAIN[0] + 80, CATHEDRAL_FOUNTAIN[1] - 52),
        prop(TERRAIN + "cityscapetree/cityscapetree0.mdx", CATHEDRAL_FOUNTAIN[0] - 100, CATHEDRAL_FOUNTAIN[1] - 82),
        prop(TERRAIN + "cityscapetree/cityscapetree1.mdx", CATHEDRAL_FOUNTAIN[0] + 100, CATHEDRAL_FOUNTAIN[1] - 82),
        # The north-east canal island: four blue-roofed guard towers round a fountain.
        mprop(HUMAN + "humantower/humantower.mdx", 511, 236, sequence="Stand Upgrade First"),
        mprop(HUMAN + "humantower/humantower.mdx", 537, 236, sequence="Stand Upgrade First"),
        mprop(HUMAN + "humantower/humantower.mdx", 511, 262, sequence="Stand Upgrade First"),
        mprop(HUMAN + "humantower/humantower.mdx", 537, 262, sequence="Stand Upgrade First"),
        mprop(CITY + "props/city_fountain/city_fountain.mdx", 524, 250),
        # The south-west canal island (by the Mage Quarter).
        mprop(HUMAN + "humantower/humantower.mdx", 362, 318, sequence="Stand Upgrade First"),
        mprop(HUMAN + "humantower/humantower.mdx", 384, 318, sequence="Stand Upgrade First"),
        mprop(OTHER + "marketplace/marketplace.mdx", 373, 333),
        # Old Town: SI:7 (the barracks) and the Pig and Whistle.
        mprop(HUMAN + "humanbarracks/humanbarracks.mdx", 612, 268, tint=OLD_TOWN),
        mprop(OTHER + "tavern/tavern.mdx", 606, 300),
        # Dwarven District: the forges.
        mprop(HUMAN + "blacksmith/blacksmith.mdx", 556, 168, tint=DWARVEN),
        mprop(HUMAN + "workshop/workshop.mdx", 592, 166, tint=DWARVEN),
        mprop(SUMMER + "props/brazier/brazier.mdx", 538, 174),
        mprop(SUMMER + "props/brazier/brazier.mdx", 578, 178),
        # Mage Quarter: the Wizard's Sanctum's spire and its lesser towers.
        mprop(DALARAN + "dalaranvioletholdspire/dalaranvioletholdspire.mdx", 330, 420, scale=0.2),
        mprop(DALARAN + "dalaranenclavespire/dalaranenclavespire.mdx", 296, 440),
        mprop(DALARAN + "dalaranmagusturret/dalaranmagusturret.mdx", 360, 452),
        mprop(HUMAN + "arcanesanctum/arcanesanctum.mdx", 384, 410),
        # The Valley of Heroes and the main gate.
        *VALLEY,
        # Stormwind Keep, north-east.
        mprop(HUMAN + "townhall/townhall.mdx", 676, 150, sequence="Stand Upgrade Second", scale=0.32),
        # The Park: a stand of old trees by the canal.
        mprop(TERRAIN + "lordaerontree/lordaerontree1.mdx", 270, 300),
        mprop(TERRAIN + "lordaerontree/lordaerontree0.mdx", 262, 330),
        mprop(TERRAIN + "lordaerontree/lordaerontree2.mdx", 280, 268),
    ],
}


# ---------------------------------------------------------------------------
# Ironforge Grand Prix
#
# The route is the owner's line on the in-game Ironforge map (998 x 657
# pixels): from the Gates through the Commons, up the Commons' great ring,
# round the north through the Mystic Ward, the Forlorn Cavern and past the
# Hall of Explorers, down into the Great Forge and round its southern forge,
# out past Tinker Town, through the Military Ward and back along the ring.
# Clockwise. Where his line touches itself north-east of the Forge, the two
# passes are kept a street apart. The city is underground: its halls are
# open floor, everything else the mountain's rock.

IF_MAP = {"scale": 3.45, "left": 160, "bottom": 575}


def IW(mx, my):
    return ((mx - IF_MAP["left"]) * IF_MAP["scale"], (IF_MAP["bottom"] - my) * IF_MAP["scale"])


def ipoly(*points):
    return [IW(*q) for q in points]


def iprop(model, mx, my, **kw):
    x, y = IW(mx, my)
    return prop(model, round(x, 1), round(y, 1), **kw)


IF_LOOP = [  # driving order, from the gate hall's junction north up the Commons
    (250, 393), (243, 372), (239, 352), (239, 330), (241, 307), (244, 285), (247, 265), (249, 245),
    (252, 225), (256, 207), (262, 191), (271, 177), (284, 162), (300, 149), (320, 138), (338, 126),
    (351, 113), (362, 100), (374, 88), (390, 79), (410, 76), (440, 76), (470, 76), (500, 76), (530, 76),
    (555, 78), (575, 83), (591, 92), (602, 104), (608, 120), (610, 138), (607, 155), (599, 168),
    (586, 177), (568, 183), (545, 186), (520, 187), (495, 187), (472, 189), (450, 195), (431, 205),
    (416, 219), (405, 236), (399, 255), (397, 274), (400, 290), (412, 298), (430, 299), (450, 300),
    (466, 305), (473, 320), (473, 340), (475, 358), (482, 373), (495, 383), (512, 388), (529, 386),
    (544, 377), (555, 362), (561, 343), (564, 322), (566, 300), (568, 280), (573, 262), (583, 248),
    (598, 238), (617, 232), (640, 229), (662, 230), (682, 236), (697, 248), (707, 264), (712, 282),
    (712, 300), (709, 318), (705, 337), (701, 357), (696, 377), (689, 398), (679, 416), (665, 431),
    (649, 444), (632, 456), (614, 468), (596, 480), (578, 491), (560, 502), (541, 512), (520, 519),
    (497, 524), (472, 527), (446, 528), (420, 526), (396, 521), (373, 511), (352, 498), (331, 481),
    (312, 463), (295, 446), (279, 429), (264, 412),
]
IF_GATE_HALL = [(205, 490), (213, 471), (222, 451), (231, 431), (240, 413), (250, 393)]   # start spur
IRONFORGE_LINE = catmull_rom([IW(*p) for p in smooth(IF_LOOP, passes=2)], step=16.0)
IRONFORGE_SPUR = catmull_rom([IW(*p) for p in IF_GATE_HALL], closed=False, step=16.0)


def if_arc(mx, my):
    return arc_at(IRONFORGE_LINE, mx, my, IW)


# The Forlorn Cavern's narrow passages: from the Mystic Ward in, and out by
# its north-east stair towards the Hall of Explorers (loop arcs).
IF_NARROWS = [(if_arc(363, 99), if_arc(410, 76)), (if_arc(565, 80), if_arc(606, 112))]

IRONFORGE_START, IRONFORGE_START_HEADING = along_spur(60.0, IRONFORGE_SPUR)
# The Gates: across the gate hall, behind the start grid's end.
IRONFORGE_GATE = (round(IRONFORGE_SPUR[0][0] - cos(IRONFORGE_START_HEADING) * 112, 1),
                  round(IRONFORGE_SPUR[0][1] - sin(IRONFORGE_START_HEADING) * 112, 1))

IF_FORGE_HALL = ipoly((420, 215), (485, 205), (550, 215), (585, 260), (590, 330), (560, 395), (485, 405),
                      (420, 380), (395, 320), (395, 260))
# The floor between the Great Forge's two forges, inside the course's turn
# round the southern one (world units; its edges run under lava and street).
IF_FORGE_ISLAND = [(1060, 1060), (1110, 1052), (1200, 1083), (1255, 1130), (1300, 1190), (1370, 1190),
                   (1360, 1050), (1320, 900), (1170, 900), (1100, 960), (1050, 1010)]

T = TERRAINART
# The Dungeon tileset's red rock made the grey-brown of dwarven stone:
# (red, green, blue, saturation) shading.
DWARF_STONE = (1.75, 1.62, 1.45, 0.30)
IRONFORGE_TERRAIN = [   # draw order, lowest first
    {"name": "snow", "tile": T + "lordaeronwinter/lordw_snow.dds", "variety": 40},
    {"name": "rough", "tile": T + "dungeon2/ggreystones.dds", "shade": (2.6, 2.45, 2.3, 0.2), "variety": 40},
    {"name": "flags", "tile": T + "dungeon/cave_squaretiles.dds", "shade": DWARF_STONE},
    {"name": "bricks", "tile": T + "dungeon/cave_brick.dds", "shade": (1.6, 1.45, 1.3, 0.45)},
    {"name": "mystic", "tile": T + "dalaran/dalaran_squaretiles.dds", "shade": 0.85},
    {"name": "tinker", "tile": T + "dungeon2/gsquaretiles.dds", "shade": (1.5, 1.45, 1.35, 0.55)},
    {"name": "marble", "tile": T + "cityscape/city_whitemarble.dds", "shade": (0.66, 0.62, 0.56)},
    {"name": "forge", "tile": T + "dungeon/cave_squaretiles.dds", "shade": (1.35, 1.12, 0.98, 0.45)},
    {"name": "military", "tile": T + "cityscape/city_bricktiles.dds", "shade": (0.72, 0.66, 0.62, 0.8)},
    {"name": "round", "tile": T + "cityscape/city_roundtiles.dds", "shade": 0.84},
]

# Roof recolours: Warcraft III's blue slate made dwarven dark slate, the
# Military Ward's red, the Mystic Ward's violet, Tinker Town's verdigris.
SLATE_ROOFS = [(195.0, 250.0, 28.0, 0.16, 0.35, 0.80)]
RED_ROOFS = [(195.0, 250.0, 2.0, 0.16, 1.0, 0.92)]
MYSTIC_ROOFS = [(195.0, 250.0, 272.0, 0.16)]
GNOME_ROOFS = [(195.0, 250.0, 150.0, 0.16, 0.55, 0.9)]
# A statue: every hue to warm grey, the stone brightened.
STATUE = [(0.0, 360.1, 30.0, 0.0, 0.10, 1.0)]

DUNGEON = "war3.w3mod:doodads/dungeon/"
UNDERGROUND = "war3.w3mod:doodads/underground/"
NORTH = "war3.w3mod:doodads/northrend/"
FIRE_LIGHT = (36, (74, 42, 12))              # a brazier's pool of light on the stone
TORCH_LIGHT = (26, (58, 34, 10))
ARCANE_LIGHT = (32, (44, 26, 74))
BRAZIER = kind(SUMMER + "props/brazier/brazier.mdx", light=FIRE_LIGHT, limit=14)
TORCH = kind(SUMMER + "props/torchhuman/torchhuman.mdx", light=TORCH_LIGHT, weight=0.7, limit=12)
BARRELS = kind(OTHER + "barrelsunit/barrelsunit.mdx", weight=0.7, limit=6)
BOXES = kind(OTHER + "boxunit/boxunit.mdx", weight=0.6, limit=5)
CRATES2 = kind(OTHER + "cratesunit/cratesunit.mdx", weight=0.6, limit=5)
WEAPONS = kind(SUMMER + "props/weapons/weapons.mdx", weight=0.6, limit=6)
ARMOR = kind(SUMMER + "props/armorrack/armorrack.mdx", weight=0.6, limit=5)
MINECART = kind(DUNGEON + "props/minecart/minecart.mdx", weight=0.5, limit=3)
DWARVES = [kind(UNITS + "human/rifleman/rifleman.mdx", weight=0.6),
           kind(UNITS + "human/peasant/peasant.mdx", weight=0.6), kind(UNITS + "human/footman/footman.mdx", weight=0.3),
           kind(UNITS + "critters/villagerman/villagerman.mdx"), kind(UNITS + "critters/villagerman1/villagerman1.mdx"),
           kind(UNITS + "critters/villagerwoman/villagerwoman.mdx"),
           kind(UNITS + "critters/villagerkid/villagerkid.mdx", weight=0.4)]

DWARF_HOUSES = [
    kind(HUMAN + "blacksmith/blacksmith.mdx", recolor=SLATE_ROOFS, limit=6),
    kind(HUMAN + "workshop/workshop.mdx", recolor=SLATE_ROOFS, limit=5),
    kind(HUMAN + "humanbarracks/humanbarracks.mdx", recolor=SLATE_ROOFS, weight=0.8, limit=3),
    kind(HUMAN + "gryphonaviary/gryphonaviary.mdx", weight=0.5, limit=2),
    kind(OTHER + "tavern/tavern.mdx", weight=0.8, limit=2),
    kind(HUMAN + "humanlumbermill/humanlumbermill.mdx", recolor=SLATE_ROOFS, weight=0.5, limit=2),
]

IRONFORGE_DISTRICTS = [
    {"name": "The Commons", "ground": "flags",
     "seeds": [IW(205, 300), IW(205, 220), IW(225, 420), IW(300, 520), IW(420, 550), IW(330, 340), IW(340, 440),
               IW(420, 460)],
     "buildings": DWARF_HOUSES + [kind(OTHER + "marketplace/marketplace.mdx", reach=70, limit=2),
                                  kind(OTHER + "fruitstand/fruitstand.mdx", reach=70, weight=0.6, limit=3)],
     "density": {"buildings": 0.6, "trim": 0.8, "people": 0.8},
     "trim": [BRAZIER, BARRELS, BOXES, CRATES2, MINECART], "people": DWARVES},
    {"name": "Gates", "ground": "round", "seeds": [IW(195, 505), IW(170, 470)], "buildings": [],
     "trim": [BRAZIER, TORCH], "people": [kind(UNITS + "human/footman/footman.mdx"),
                                          kind(UNITS + "human/rifleman/rifleman.mdx")]},
    {"name": "Mystic Ward", "ground": "mystic", "recolor": MYSTIC_ROOFS,
     "seeds": [IW(240, 130), IW(310, 90), IW(205, 170), IW(350, 60)],
     "buildings": [kind(HUMAN + "arcanesanctum/arcanesanctum.mdx", limit=3),
                   kind(HUMAN + "arcanevault/arcanevault.mdx", limit=3),
                   kind(OTHER + "magetower/magetower.mdx", limit=2),
                   kind(OTHER + "magicvault/magicvault.mdx", weight=0.4, limit=2)],
     "density": {"buildings": 0.7, "trim": 0.7, "people": 0.6},
     "trim": [kind(CITY + "props/crystallamp/crystallamp.mdx", light=ARCANE_LIGHT),
              kind(DUNGEON + "props/bigbookshelf/bigbookshelf.mdx", limit=4)],
     "people": [kind(UNITS + "human/priest/priest.mdx"), kind(UNITS + "critters/villagerwoman/villagerwoman.mdx")]},
    {"name": "Forlorn Cavern", "ground": "rough",
     "seeds": [IW(480, 120), IW(420, 50), IW(540, 40), IW(410, 140)],
     "buildings": [kind(DUNGEON + "rocks/dungeonrock/dungeonrock0.mdx", limit=5, recolor=STATUE),
                   kind(DUNGEON + "rocks/dungeonstalagmite/dungeonstalagmite0.mdx", limit=6, recolor=STATUE),
                   kind(DUNGEON + "props/junkpile/junkpile0.mdx", limit=3),
                   kind(DUNGEON + "props/junkpile/junkpile1.mdx", limit=3)],
     "density": {"buildings": 0.35, "trim": 0.6},
     "trim": [kind(DUNGEON + "props/chainpost/chainpost.mdx", limit=6), TORCH], "people": []},
    {"name": "Hall of Explorers", "ground": "marble",
     "seeds": [IW(660, 140), IW(700, 80), IW(650, 60), IW(740, 170)],
     "buildings": [kind(DUNGEON + "props/bigbookshelf/bigbookshelf.mdx", limit=10),
                   kind(DUNGEON + "props/bookshelf/bookshelf.mdx", limit=6),
                   kind(DUNGEON + "props/table/table.mdx", weight=0.5, limit=5),
                   kind(HUMAN + "altarofkings/altarofkings.mdx", weight=0.6, recolor=SLATE_ROOFS, limit=1)],
     "density": {"buildings": 0.6, "trim": 0.7, "people": 0.6},
     "trim": [kind(SUMMER + "props/ribbones/ribbones0.mdx", weight=0.5, limit=3),
              kind(NORTH + "props/north_bones/north_bones0.mdx", weight=0.4, limit=2), ARMOR, BRAZIER],
     "people": [kind(UNITS + "human/rifleman/rifleman.mdx"), kind(UNITS + "critters/villagerman/villagerman.mdx")]},
    {"name": "Great Forge", "ground": "forge",
     "seeds": [IW(485, 300), IW(440, 240), IW(530, 340), IW(600, 300), IW(420, 330)],
     "buildings": [kind(HUMAN + "blacksmith/blacksmith.mdx", recolor=SLATE_ROOFS, limit=8),
                   kind(HUMAN + "gryphonaviary/gryphonaviary.mdx", weight=0.3, limit=1)],
     "density": {"buildings": 0.8, "trim": 0.8, "people": 0.6},
     "trim": [BRAZIER, WEAPONS, ARMOR, BARRELS], "people": DWARVES[:3]},
    {"name": "Tinker Town", "ground": "tinker", "recolor": GNOME_ROOFS,
     "seeds": [IW(660, 310), IW(640, 360), IW(760, 335), IW(740, 280)],
     "buildings": [kind(HUMAN + "workshop/workshop.mdx", limit=6),
                   kind(OTHER + "powergenerator/powergenerator.mdx", limit=2),
                   kind(HUMAN + "arcanesanctum/arcanesanctum.mdx", weight=0.5, limit=2),
                   kind(DUNGEON + "props/junkpile/junkpile0.mdx", limit=3),
                   kind(DUNGEON + "props/junkpile/junkpile1.mdx", limit=3)],
     "density": {"buildings": 0.7, "trim": 0.7, "people": 0.5},
     "trim": [kind(DUNGEON + "props/sewervent/sewervent0.mdx", limit=4), MINECART, BARRELS,
              kind(UNITS + "other/dwarfcar/dwarfcar.mdx", weight=0.4, limit=2),
              kind(UNITS + "human/gyrocopter/gyrocopter.mdx", weight=0.4, limit=2), TORCH],
     "people": [kind(UNITS + "human/mortarteam/mortarteam.mdx"), kind(UNITS + "human/peasant/peasant.mdx")]},
    {"name": "Military Ward", "ground": "military", "recolor": RED_ROOFS,
     "seeds": [IW(660, 500), IW(600, 545), IW(730, 450), IW(560, 450)],
     "buildings": [kind(HUMAN + "humanbarracks/humanbarracks.mdx", limit=3),
                   kind(HUMAN + "humantower/humantower.mdx", limit=4),
                   kind(UNITS + "human/warwagon/warwagon.mdx", weight=0.6, limit=5)],
     "density": {"buildings": 0.7, "trim": 0.7, "people": 0.7},
     "trim": [WEAPONS, ARMOR, kind(SUMMER + "props/bannerhuman/bannerhuman0.mdx", recolor=RED_ROOFS, limit=6),
              BRAZIER],
     "people": [kind(UNITS + "human/footman/footman.mdx"), kind(UNITS + "human/rifleman/rifleman.mdx"),
                kind(UNITS + "human/mortarteam/mortarteam.mdx", weight=0.5)]},
]

IRONFORGE = {
    "id": "ironforge_gp",
    "version": 3,
    "wall_clearance": KART,  # use the exposed painted wall, including the gate-hall junction
    # The owner's request (2026-10-22): the Forlorn Cavern's entrance and
    # exit tight as in the game: no shoulder, the wall where the shoulder
    # began (the paving's edge), so the kart centre keeps a kart's half-length
    # inside it. A tunnel through the rock (rock.tunnel).
    "narrows": [
        {"name": "Forlorn Cavern entrance", "from": IF_NARROWS[0][0], "to": IF_NARROWS[0][1],
         "wall_radius": ROAD_RADIUS - KART},
        {"name": "Forlorn Cavern exit", "from": IF_NARROWS[1][0], "to": IF_NARROWS[1][1],
         "wall_radius": ROAD_RADIUS - KART},
    ],
    "name": "Ironforge Grand Prix",
    "folder": "Ironforge",
    "size": (2048, 2048),
    "team": (0.16, 0.30, 0.74),
    "lean": 0.6,
    "kart_clearance": KART,
    "street_reach": 100,
    "centerline": IRONFORGE_LINE,
    "branches": [IRONFORGE_SPUR],
    "plazas": [],
    "gates": [
        gate_on("Mystic Ward", IRONFORGE_LINE, *IW(260, 195)),
        gate_on("Forlorn Cavern", IRONFORGE_LINE, *IW(470, 76)),
        gate_on("Hall of Explorers", IRONFORGE_LINE, *IW(610, 138)),
        gate_on("Great Forge", IRONFORGE_LINE, *IW(473, 340)),
        gate_on("Tinker Town", IRONFORGE_LINE, *IW(712, 291)),
        gate_on("Military Ward", IRONFORGE_LINE, *IW(600, 478)),
        gate_on("The Commons", IRONFORGE_LINE, *IW(239, 340)),
    ],
    "spawn": IRONFORGE_START + (IRONFORGE_START_HEADING,),
    "replaceables": {11: T + "dungeon/cave_cliff1.dds",
                     31: "war3.w3mod:replaceabletextures/lordaerontree/lordaeronsnowtree.dds"},
    "terrain": IRONFORGE_TERRAIN,
    "districts": IRONFORGE_DISTRICTS,
    # Outside the Gates: Dun Morogh's snow.
    "zones": [{"terrain": "snow", "shape": ("poly", ipoly((160, 575), (160, 500), (178, 506), (200, 528),
                                                           (222, 575)))}],
    # The Forlorn Cavern's lake and the Mystic Ward's pool.
    "water": [
        ipoly((470, 106), (500, 106), (518, 113), (526, 128), (524, 145), (512, 156), (486, 158), (462, 156),
              (449, 145), (448, 125), (455, 112)),
        ipoly((282, 92), (296, 88), (309, 93), (314, 105), (309, 117), (296, 121), (283, 117), (277, 105)),
    ],
    "land": [],
    "canals": [],
    "bridges": [],
    "rock": {
        "band": 165,
        "floors": [
            ipoly((205, 70), (265, 45), (345, 45), (350, 110), (300, 160), (230, 200), (195, 160)),   # Mystic Ward
            ipoly((615, 60), (720, 55), (760, 100), (755, 190), (700, 215), (650, 200), (620, 150)),  # Hall of Explorers
            ipoly((640, 250), (740, 250), (745, 315), (800, 320), (800, 360), (740, 365), (700, 390),
                  (630, 380)),                                                                 # Tinker Town, the tram
            ipoly((560, 420), (700, 400), (770, 440), (770, 570), (560, 570)),                # Military Ward
            ipoly((400, 40), (580, 40), (600, 70), (600, 180), (420, 180), (395, 90)),        # Forlorn Cavern
            IF_FORGE_HALL,                                                                     # the Great Forge's hall
            ipoly((160, 575), (160, 500), (178, 506), (200, 528), (222, 575)),                # outside the Gates
            ipoly((178, 190), (215, 160), (260, 150), (300, 175), (300, 230), (290, 330), (300, 420),
                  (330, 470), (420, 505), (520, 505), (560, 540), (520, 572), (400, 572), (300, 548),
                  (225, 490), (190, 420), (172, 330), (172, 250)),                             # the Commons' ring
        ],
        "top": (T + "dungeon/cave_darkrocks.dds", (1.0, 0.95, 0.9, 0.25)),
        "face": (T + "cityscape/city_roundtiles.dds", (1.0, 0.96, 0.9, 0.6)),
        "height": 56, "fade": 90, "dark": 0.34, "course": 7,
        "tunnel": 140,          # rock this far either side of a narrows' centerline
    },
    # The Great Forge's two forges, molten, with their stone ridges.
    "lava": {
        "pools": [
            ipoly((428, 222), (450, 214), (480, 211), (508, 214), (528, 222), (534, 238), (522, 250), (505, 262),
                  (482, 270), (455, 271), (432, 262), (425, 242)),
            ipoly((502, 305), (520, 304), (536, 312), (541, 330), (536, 348), (522, 358), (505, 360), (499, 340),
                  (498, 320)),
            ipoly((692, 468), (703, 466), (712, 471), (717, 480), (715, 491), (707, 498), (695, 499), (686, 492),
                  (683, 481), (686, 473)),                                                     # Military Ward's pit
        ],
        "tile": (T + "dungeon/cave_lava.dds", 1.0),
        "glow": (120, 52, 10), "glow_reach": 44,
        "rim": (30, 22, 20), "rim_width": 3, "rim_height": 10,
    },
    "rings": [
        {"on": "water", "center": IW(487, 132), "radii": [12, 26, 40, 54, 68, 82], "width": 4,
         "color": (150, 146, 132)},
        {"on": "water", "center": IW(296, 105), "radii": [10, 22, 34], "width": 3, "color": (170, 150, 190)},
    ],
    # Between the Great Forge's two forges: no generated buildings, trim or
    # braziers, only the Great Anvil and the pumps (the props below).
    "reserved": [IF_FORGE_ISLAND],
    "lights": [],
    "sections": [
        {"name": "Mystic Ward", "from": if_arc(258, 200), "to": if_arc(380, 84),
         "road": (T + "dungeon/cave_squaretiles.dds", (1.95, 1.85, 1.8, 0.25))},
        {"name": "Forlorn Cavern", "from": if_arc(380, 84), "to": if_arc(606, 112),
         "road": (T + "dungeon/cave_squaretiles.dds", (1.45, 1.4, 1.38, 0.15))},
        {"name": "Hall of Explorers", "from": if_arc(606, 112), "to": if_arc(560, 185),
         "road": (T + "cityscape/city_whitemarble.dds", 0.86)},
        {"name": "Great Forge", "from": if_arc(450, 195), "to": if_arc(573, 262),
         "road": (T + "dungeon/cave_squaretiles.dds", (1.7, 1.42, 1.2, 0.5))},
        {"name": "Tinker Town", "from": if_arc(573, 262), "to": if_arc(701, 357),
         "road": (T + "dungeon2/gsquaretiles.dds", (1.6, 1.55, 1.45, 0.4))},
        {"name": "Military Ward", "from": if_arc(701, 357), "to": if_arc(541, 512),
         "road": (T + "cityscape/city_bricktiles.dds", (0.85, 0.8, 0.75, 0.7))},
        {"name": "Gate hall", "branch": 1, "road": (T + "cityscape/city_whitemarble.dds", 0.8)},
    ],
    "road_default": (T + "dungeon/cave_squaretiles.dds", (1.9, 1.78, 1.6, 0.3)),     # the Commons
    "alleys": [],
    "steps": [],
    "squares": [],
    "bridge_depth": 15,
    "arch_every": 34,
    "water_texture": "war3.w3mod:replaceabletextures/water/water00.dds",
    "water_tint": (0.10, 0.20, 0.26),
    "water_rim": (120, 112, 100),
    "quay_face": (110, 102, 92),
    "quay_depth": 8,
    "road_tile": T + "dungeon/cave_squaretiles.dds",
    "road_shade": 1.0,
    "sidewalk_tile": T + "dungeon/cave_squaretiles.dds",
    "sidewalk_shade": (1.6, 1.5, 1.38, 0.28),
    "plaza_tile": T + "cityscape/city_whitemarble.dds",
    "plaza_shade": 0.88,
    "curb_color": (132, 122, 110),
    "gutter_color": (52, 46, 42),
    "hedged": [],
    "bridge_posts": None,
    "wall": {"thickness": 4, "height": 10, "pillar_height": 17, "pillar_every": 56,
             "face": (150, 140, 128), "cap": (190, 180, 166), "shadow": (70, 64, 58)},
    "fill": {"step": 20, "reach": 140, "gap": 2, "spacing": 3},
    "trim": {"step": 36, "reach": 50, "gap": 3, "spacing": 16},
    "people": {"step": 28, "reach": 34, "gap": 2, "spacing": 8},
    # Dwarven stone and iron: dark railings along lava and water, stone
    # foundations along the halls.
    "wall_styles": {
        "parapet": ((88, 82, 78), (126, 118, 108), (46, 42, 40)),
        "land": ((118, 108, 98), (150, 140, 126), (66, 60, 54)),
    },
    "furniture": [
        {"prop": prop(SUMMER + "props/brazier/brazier.mdx", 0, 0), "every": 170, "offset": 6, "start": 60,
         "where": "land"},
    ],
    "solids": [],
    "props": [
        # The Gates of Ironforge behind the start grid, Dun Morogh's snow beyond.
        dict(prop(DUNGEON + "terrain/dungeonporticulisgate45/dungeonporticulisgate45.mdx",
                  *IRONFORGE_GATE, yaw=180, scale=0.4), nudge=True),
        iprop(TERRAIN + "lordaerontree/lordaerontree1.mdx", 168, 548),
        iprop(TERRAIN + "lordaerontree/lordaerontree3.mdx", 182, 566),
        iprop(TERRAIN + "lordaerontree/lordaerontree0.mdx", 200, 570),
        # Modimus Anvilmar's statue stands guard in the gate hall.
        dict(iprop(UNITS + "human/muradin/muradin.mdx", 240, 472, scale=1.0, yaw=225, recolor=STATUE,
                   stone=(1.3, 0.25)), nudge=True),
        # The Commons: the Vault of Ironforge (the bank) and the auction house.
        dict(iprop(OTHER + "magicvault/magicvault.mdx", 312, 330, scale=0.4, yaw=180), nudge=True),
        dict(iprop(OTHER + "marketplace/marketplace.mdx", 190, 360, yaw=0), nudge=True),
        # The Great Forge, as in the game: no buildings between its forges,
        # only the Great Anvil and the pumps (world units).
        mesh_prop("great_anvil", 1186, 1006, scale=0.575),
        mesh_prop("great_pump", 1292, 1088),
        mesh_prop("great_pump", 1270, 955, scale=0.8),
        mesh_prop("pump", 1240, 1048, yaw=315, scale=1.3),
        mesh_prop("pump", 1225, 958, yaw=225, scale=1.3),
        # Tinker Town's great machine and the Deeprun Tram's gate.
        dict(iprop(OTHER + "powergenerator/powergenerator.mdx", 660, 315, scale=0.6), nudge=True),
        iprop(DUNGEON + "terrain/dungeonporticulisgate/dungeonporticulisgate.mdx", 772, 340, yaw=180),
        # The Hall of Explorers: a great fossil skeleton on show, the library's shelves.
        dict(iprop(SUMMER + "props/ribbones/ribbones0.mdx", 695, 135, scale=1.1), nudge=True),
        dict(iprop(SUMMER + "props/ribbones/ribbones2.mdx", 720, 175, scale=0.8), nudge=True),
        iprop(DUNGEON + "props/bigbookshelf/bigbookshelf.mdx", 660, 70, scale=0.35),
        iprop(DUNGEON + "props/bigbookshelf/bigbookshelf.mdx", 690, 66, scale=0.35),
        iprop(DUNGEON + "props/bigbookshelf/bigbookshelf.mdx", 720, 70, scale=0.35),
        iprop(DUNGEON + "props/table/table.mdx", 670, 100, scale=0.35),
        iprop(DUNGEON + "props/table/table.mdx", 712, 100, scale=0.35),
        # The Military Ward: the Hall of Arms and a steam tank.
        dict(iprop(HUMAN + "humanbarracks/humanbarracks.mdx", 680, 535, scale=0.4, recolor=RED_ROOFS), nudge=True),
        dict(iprop(UNITS + "human/warwagon/warwagon.mdx", 625, 525, yaw=180), nudge=True),
    ],
}


# ---------------------------------------------------------------------------
# Orgrimmar Canyon Rush
#
# The owner's blue line on the in-game Orgrimmar map (1219 x 914 pixels; his
# second picture, a half-size copy registered onto the first): a loop round
# the Cleft of Shadow, driven counter-clockwise. From the Valley of
# Strength north to the Drag, up the Drag's east side, west along the north
# past the Valley of Wisdom, down the Cleft's west rim and back into the
# Valley of Strength. His first line started at the West Gate and ran the
# canyon road out and back; that stretch cannot be lapped, so the karts
# start on the canyon road's last straight, behind a gate of the city wall,
# and join the loop in the Valley of Strength. Orgrimmar lies in Durotar's
# red canyons: the open valleys are floor, the rest the canyon's rock, and
# the Cleft of Shadow is a chasm sunk below the city.

OG_MAP = {"scale": 3.7, "left": 394, "bottom": 797}


def OW(mx, my):
    return ((mx - OG_MAP["left"]) * OG_MAP["scale"], (OG_MAP["bottom"] - my) * OG_MAP["scale"])


def opoly(*points):
    return [OW(*q) for q in points]


def oprop(model, mx, my, **kw):
    x, y = OW(mx, my)
    return prop(model, round(x, 1), round(y, 1), **kw)


OG_LOOP = [  # driving order (counter-clockwise), from the Valley of Strength where the start road joins
    (680, 728), (700, 728), (713, 718), (713, 699), (711, 680), (707, 663), (701, 646), (698, 627), (692, 610),
    (684, 593), (677, 577), (671, 560), (679, 543), (694, 534), (713, 532), (730, 528), (749, 526), (766, 522),
    (785, 520), (802, 515), (814, 501), (821, 486), (827, 469), (831, 452), (835, 435), (842, 419), (848, 402),
    (852, 385), (850, 366), (846, 349), (838, 332), (829, 317), (812, 311), (795, 305), (776, 303), (757, 303),
    (738, 303), (719, 303), (701, 303), (684, 301), (667, 303), (648, 301), (631, 305), (614, 309), (597, 315),
    (581, 326), (570, 339), (557, 351), (543, 362), (532, 378), (524, 393), (519, 410), (515, 427), (511, 444),
    (505, 461), (501, 478), (501, 496), (505, 513), (509, 530), (513, 547), (521, 562), (528, 577), (536, 593),
    (549, 606), (559, 621), (570, 636), (581, 650), (593, 663), (602, 678), (616, 692), (629, 703), (642, 715),
    (658, 722),
]
OG_CANYON = [(484, 716), (520, 722), (556, 728), (592, 734), (626, 737), (654, 733), (679, 725)]   # start spur
ORGRIMMAR_LINE = catmull_rom([OW(*p) for p in smooth(OG_LOOP, passes=2)], step=16.0)
ORGRIMMAR_SPUR = catmull_rom([OW(*p) for p in OG_CANYON], closed=False, step=16.0)


def og_arc(mx, my):
    return arc_at(ORGRIMMAR_LINE, mx, my, OW)


ORGRIMMAR_START, ORGRIMMAR_START_HEADING = along_spur(80.0, ORGRIMMAR_SPUR)
OG_GATE_SETBACK = WALL_RADIUS + KART + 2 + 119
OG_GATE_ROAD_END = 250            # the road's paving beyond the gate runs from here to the map's edge
# The city wall's gate across the canyon road, behind the start grid.
# Its front (119 units east of the model's origin, turned to face the
# city) stands just beyond the end of the road.
ORGRIMMAR_GATE = (round(ORGRIMMAR_SPUR[0][0] - OG_GATE_SETBACK, 1), ORGRIMMAR_SPUR[0][1])

# The Cleft of Shadow: the chasm's rim as the map draws it (its lavender
# floor), simplified by hand.
OG_CLEFT = opoly((553, 436), (572, 426), (590, 414), (619, 398), (645, 390), (668, 386), (686, 394), (702, 402),
                 (716, 392), (724, 398), (714, 416), (718, 436), (712, 452), (700, 468), (684, 482), (668, 492),
                 (656, 504), (630, 508), (600, 516), (586, 516), (570, 502), (562, 480), (556, 456))

BARRENS = T + "barrens/"
ORGRIMMAR_TERRAIN = [   # draw order, lowest first
    {"name": "dirt", "tile": BARRENS + "barrens_dirt.dds", "variety": 40},
    {"name": "road", "tile": T + "outland/outland_dirtlight.dds", "shade": (1.0, 0.94, 0.88), "variety": 30},
    {"name": "rough", "tile": BARRENS + "barrens_dirtrough.dds", "variety": 40},
    {"name": "dark", "tile": BARRENS + "barrens_desertdark.dds", "variety": 40},
    {"name": "grass", "tile": BARRENS + "barrens_grass.dds", "variety": 45},
    {"name": "desert", "tile": BARRENS + "barrens_desert.dds", "variety": 40},
    {"name": "pebbles", "tile": BARRENS + "barrens_pebbles.dds", "shade": 0.92},
]

ORC = "war3.w3mod:buildings/orc/"
BARRENS_DOODADS = "war3.w3mod:doodads/barrens/"
OUTLAND = "war3.w3mod:doodads/outland/"
ORC_UNITS = UNITS + "orc/"
HORDE_RED = (0.62, 0.08, 0.06)
SANDSTONE = (1.0, 0.80, 0.64)     # Warcraft III's grey Orgrimmar walls in Durotar's red stone
ASHENVALE_TOTEM = "war3.w3mod:doodads/ashenvale/props/totem/totem%d.mdx"

# Huts and halls of the Horde (Warcraft III's orc buildings), shared by the
# valleys; each district adds its own.
ORC_HUTS = [
    kind(OTHER + "pigfarm/pigfarm.mdx", weight=0.6, limit=12),
    kind(ORC + "trollburrow/trollburrow.mdx", weight=0.8, limit=8),
    kind(ORC + "orcbarracks/orcbarracks.mdx", limit=3),
    kind(ORC + "warmill/warmill.mdx", limit=3),
    kind(ORC + "spiritlodge/spiritlodge.mdx", weight=0.7, limit=2),
    kind(ORC + "voodoolounge/voodoolounge.mdx", weight=0.7, limit=2),
    kind(OTHER + "chieftainhut/chieftainhut.mdx", limit=3),
    kind(OTHER + "tent/tent.mdx", weight=0.6, limit=4),
    kind(OTHER + "tent1/tent1.mdx", weight=0.6, limit=4),
]
ORC_BANNER = kind(SUMMER + "props/bannerorc/bannerorc0.mdx", limit=6)
ORC_BANNER1 = kind(SUMMER + "props/bannerorc/bannerorc1.mdx", limit=6)
ORC_TRIM = [ORC_BANNER, ORC_BANNER1, BARRELS, CRATES2, kind(SUMMER + "props/hay/hay0.mdx", weight=0.5, limit=4),
            kind(SUMMER + "props/trough/trough0.mdx", weight=0.5, limit=4),
            kind(SUMMER + "props/hitchingpost/hitchingpost.mdx", weight=0.5, limit=4)]
CACTI = [kind(BARRENS_DOODADS + "plants/cactus/cactus%d.mdx" % n, limit=3) for n in (0, 2, 5, 7)]
ROCKS = [kind(BARRENS_DOODADS + "rocks/barrens_rocks/barrens_rocks%d.mdx" % n, cut=0.5, limit=3) for n in (0, 3, 6)]
PALMS = [kind(BARRENS_DOODADS + "plants/barrens_treedoodad/barrens_treedoodad%d.mdx" % n, alpha_shadow=True,
              limit=4) for n in (0, 3, 6)]
GRUNT = kind(ORC_UNITS + "grunt/grunt.mdx")
PEON = kind(ORC_UNITS + "peon/peon.mdx")
TROLL = kind(ORC_UNITS + "headhunter/headhunter.mdx")
TAUREN = kind(ORC_UNITS + "tauren/tauren.mdx", weight=0.5)
SHAMAN = kind(ORC_UNITS + "shaman/shaman.mdx", weight=0.6)
WITCH = kind(ORC_UNITS + "witchdoctor/witchdoctor.mdx", weight=0.6)
KODO = kind(ORC_UNITS + "kotobeastnorider/kotobeastnorider.mdx", weight=0.3, limit=3)
HORDE = [GRUNT, PEON, TROLL, TAUREN, SHAMAN, WITCH]

ORGRIMMAR_DISTRICTS = [
    {"name": "Valley of Strength", "ground": "desert",
     "seeds": [OW(640, 640), OW(606, 600), OW(700, 770), OW(760, 680), OW(660, 560)],
     "buildings": ORC_HUTS + [kind(ORC + "greathall/greathall.mdx", weight=0.5, limit=1),
                              kind(ORC + "watchtower/watchtower.mdx", weight=0.6, limit=3),
                              kind(ORC + "beastiary/beastiary.mdx", weight=0.5, limit=1)],
     "density": {"buildings": 0.8, "trim": 0.8, "people": 0.8},
     "trim": ORC_TRIM + [WEAPONS, ARMOR], "people": HORDE + [KODO]},
    {"name": "The Drag", "ground": "dirt",
     "seeds": [OW(760, 470), OW(890, 450), OW(880, 560), OW(770, 560), OW(905, 360)],
     "buildings": [kind(OTHER + "merchant/merchant.mdx", limit=3),
                   kind(OTHER + "tent/tent.mdx", limit=6), kind(OTHER + "tent1/tent1.mdx", limit=6),
                   kind(OTHER + "pigfarm/pigfarm.mdx", limit=8), kind(ORC + "trollburrow/trollburrow.mdx", limit=4),
                   kind(ORC + "voodoolounge/voodoolounge.mdx", limit=2),
                   kind(OTHER + "taurentent/taurentent.mdx", weight=0.6, limit=3),
                   kind(OTHER + "mercenary/mercenary.mdx", weight=0.4, limit=1)],
     "density": {"buildings": 0.85, "trim": 0.8, "people": 0.9},
     "trim": ORC_TRIM, "people": HORDE + [KODO]},
    {"name": "Cleft of Shadow", "ground": "dark", "tint": (0.92, 0.86, 0.92),
     "seeds": [OW(640, 450), OW(600, 420), OW(690, 440), OW(610, 490)],
     "buildings": [kind(ORC + "voodoolounge/voodoolounge.mdx", limit=6),
                   kind(ORC + "altarofstorms/altarofstorms.mdx", limit=3),
                   kind(ORC + "trollburrow/trollburrow.mdx", limit=8),
                   kind(OTHER + "centaurtent/centaurtent.mdx", limit=6),
                   kind(OTHER + "pigfarm/pigfarm.mdx", limit=10)],
     "density": {"buildings": 0.5, "trim": 0.8, "people": 0.7},
     "trim": [kind(SUMMER + "props/skullonstick/skullonstick%d.mdx" % n, limit=3) for n in (0, 2)] +
             [kind(SUMMER + "props/headonspear/headonspear0.mdx", limit=4),
              kind(SUMMER + "props/skullpile/skullpile0.mdx", limit=3),
              kind(SUMMER + "props/cauldronwithheads/cauldronwithheads.mdx", limit=2)],
     "people": [WITCH, TROLL, kind(ORC_UNITS + "heroshadowhunter/heroshadowhunter.mdx", limit=2), PEON]},
    {"name": "Valley of Wisdom", "ground": "grass",
     "seeds": [OW(450, 330), OW(440, 430), OW(470, 520), OW(560, 265)],
     "buildings": [kind(ORC + "spiritlodge/spiritlodge.mdx", limit=3), kind(ORC + "taurentotem/taurentotem.mdx", limit=2),
                   kind(OTHER + "chieftainhut/chieftainhut.mdx", limit=3),
                   kind(OTHER + "taurentent2/taurentent2.mdx", limit=4), kind(OTHER + "pigfarm/pigfarm.mdx", limit=4)]
     + PALMS,
     "density": {"buildings": 0.7, "trim": 0.7, "people": 0.6},
     "trim": [kind(ASHENVALE_TOTEM % n, limit=3) for n in (0, 1, 2)] + [ORC_BANNER] + CACTI,
     "people": [SHAMAN, TAUREN, kind(ORC_UNITS + "spiritwalker/spiritwalker.mdx", limit=2), GRUNT]},
    {"name": "Under the north wall", "ground": "dirt",
     "seeds": [OW(640, 345), OW(740, 340), OW(800, 350)],
     "buildings": ORC_HUTS + [kind(ORC + "watchtower/watchtower.mdx", limit=2)],
     "density": {"buildings": 0.8, "trim": 0.8, "people": 0.8},
     "trim": ORC_TRIM, "people": HORDE},
    {"name": "Valley of Honor", "ground": "grass",
     "seeds": [OW(930, 290)],
     "buildings": [kind(ORC + "beastiary/beastiary.mdx", limit=1), kind(ORC + "spiritlodge/spiritlodge.mdx", limit=1)]
     + PALMS, "trim": [ORC_BANNER1], "people": [GRUNT, TAUREN]},
    {"name": "Canyon", "ground": "rough",
     "seeds": [OW(440, 700), OW(520, 770), OW(430, 640), OW(560, 690)],
     "buildings": ROCKS + CACTI, "density": {"buildings": 0.5},
     "trim": CACTI, "people": [GRUNT]},
    {"name": "Valley of Spirits", "ground": "grass",
     "seeds": [OW(450, 775)],
     "buildings": PALMS + [kind(OTHER + "taurentent/taurentent.mdx", limit=2)], "trim": CACTI,
     "people": [TROLL, WITCH]},
]

ORGRIMMAR = {
    "id": "orgrimmar_canyon",
    "version": 1,
    "wall_clearance": KART,
    "full_speed_to_walls": True,   # as the owner chose for Stormwind: full grip up to the walls
    "name": "Orgrimmar Canyon Rush",
    "folder": "Orgrimmar",
    "size": (2048, 2048),
    "team": HORDE_RED,
    "lean": 0.6,
    "kart_clearance": KART,
    "street_reach": 100,
    "centerline": ORGRIMMAR_LINE,
    "branches": [ORGRIMMAR_SPUR],
    "plazas": [],
    "gates": [
        gate_on("The Drag", ORGRIMMAR_LINE, *OW(835, 435)),
        gate_on("Valley of Wisdom", ORGRIMMAR_LINE, *OW(701, 303)),
        gate_on("Cleft of Shadow", ORGRIMMAR_LINE, *OW(505, 461)),
        gate_on("Valley of Strength", ORGRIMMAR_LINE, *OW(711, 680)),
    ],
    "spawn": ORGRIMMAR_START + (ORGRIMMAR_START_HEADING,),
    "replaceables": {11: BARRENS + "barrens_cliff0.dds",
                     33: "war3.w3mod:replaceabletextures/barrenstree/barrenstree.dds"},
    "terrain": ORGRIMMAR_TERRAIN,
    "districts": ORGRIMMAR_DISTRICTS,
    # The canyon road on through the gate, out of the city.
    "zones": [{"terrain": "road", "shape": ("rect", (0, ORGRIMMAR_GATE[1] - 64, OG_GATE_ROAD_END,
                                                     ORGRIMMAR_GATE[1] + 64))}],
    # The Valley of Spirits' pool, by the start.
    "water": [opoly((466, 760), (484, 750), (504, 752), (518, 764), (520, 782), (508, 798), (486, 802), (470, 792),
                    (462, 776))],
    "land": [],
    "canals": [],
    "bridges": [],
    # Durotar's red rock round the valleys: everything but the valleys' floors
    # and a band along the street, the canyon walls rising behind it.
    "rock": {
        "band": 124,
        "floors": [
            ORGRIMMAR_LINE,                                                           # inside the loop
            opoly((394, 244), (520, 244), (560, 290), (548, 330), (512, 370), (494, 430), (490, 500), (484, 560),
                  (456, 610), (394, 620)),                                            # Valley of Wisdom
            opoly((560, 744), (620, 770), (690, 797), (800, 797), (812, 700), (780, 620), (760, 560),
                  (724, 548)),                                                        # Valley of Strength
            opoly((862, 330), (947, 330), (947, 580), (840, 590), (824, 552)),        # the Drag's east
            opoly((840, 244), (947, 244), (947, 335), (868, 336), (850, 300)),        # towards the Valley of Honor
            opoly((394, 724), (470, 728), (532, 742), (546, 797), (394, 797)),        # Valley of Spirits
            opoly((394, 640), (440, 640), (460, 700), (430, 760), (394, 760)),        # inside the West Gate
        ],
        "top": (T + "outland/outland_rock.dds", (1.6, 1.22, 1.06, 0.75)),
        "face_texture": (BARRENS + "barrens_cliff0.dds", (0, 0, 192, 63), (1.12, 0.94, 0.86, 1.0)),
        "height": 80, "fade": 40, "dark": 0.9,
    },
    # The Cleft of Shadow, sunk below the city.
    "pits": {
        "shapes": [OG_CLEFT],
        "floor": (BARRENS + "barrens_desertdark.dds", (0.9, 0.76, 0.92, 0.6)),
        "face": (BARRENS + "barrens_cliff0.dds", (0, 0, 192, 63), (0.96, 0.80, 0.86, 0.9)),
        "depth": 46, "shadow": 14, "rim": (58, 34, 30), "margin": 10, "clear": 6,
    },
    # Ragefire Chasm's mouth: a fissure of fire in the Cleft's floor.
    "lava": {
        "pools": [opoly((684, 446), (690, 438), (697, 434), (703, 426), (710, 421), (714, 424), (709, 431),
                        (704, 439), (697, 446), (690, 452), (685, 453))],
        "tile": (T + "dungeon/cave_lava.dds", 0.86),
        "glow": (96, 40, 8), "glow_reach": 28,
        "rim": (40, 24, 20), "rim_width": 2, "rim_height": 4,
    },
    "rings": [],
    # The gate's passage and the road beyond it: no generated scenery.
    "reserved": [[(0, ORGRIMMAR_GATE[1] - 110), (OG_GATE_ROAD_END, ORGRIMMAR_GATE[1] - 110),
                  (OG_GATE_ROAD_END, ORGRIMMAR_GATE[1] + 110), (0, ORGRIMMAR_GATE[1] + 110)]],
    "lights": [],
    "sections": [],
    "road_default": (T + "outland/outland_dirtlight.dds", (1.0, 0.94, 0.88)),
    "alleys": [
        # The bridge to the Valley of Honor, closed for the race.
        {"at": og_arc(850, 362), "side": "right", "width": 64, "length": 320},
    ],
    "steps": [],
    "squares": [],
    "bridge_depth": 15,
    "arch_every": 34,
    "water_texture": "war3.w3mod:replaceabletextures/water/water00.dds",
    "water_tint": (0.16, 0.34, 0.36),
    "water_rim": (150, 112, 80),
    "quay_face": (122, 80, 56),
    "quay_depth": 6,
    "road_tile": T + "outland/outland_dirtlight.dds",
    "road_shade": 1.0,
    "sidewalk_tile": BARRENS + "barrens_pebbles.dds",
    "sidewalk_shade": (0.95, 0.85, 0.8, 0.7),
    "plaza_tile": BARRENS + "barrens_desert.dds",
    "plaza_shade": 0.9,
    "curb_color": (92, 58, 36),
    "gutter_color": (58, 36, 24),
    "hedged": [],
    "bridge_posts": None,
    # Orgrimmar's timber palisade along the street, an iron spike every few strides.
    "land_wall": {"style": "palisade", "height": 8, "spike_every": 14, "spike_height": 14},
    "wall": {"thickness": 4, "height": 10, "pillar_height": 17, "pillar_every": 56,
             "face": (96, 62, 40), "cap": (134, 94, 60), "shadow": (54, 36, 24)},
    "fill": {"step": 20, "reach": 440, "gap": 12, "spacing": 7},
    "trim": {"step": 26, "reach": 44, "gap": 3, "spacing": 10},
    "people": {"step": 22, "reach": 34, "gap": 2, "spacing": 6},
    "furniture": [
        {"prop": prop(SUMMER + "props/bannerorc/bannerorc1.mdx", 0, 0), "every": 210, "offset": 6, "start": 100,
         "where": "land"},
    ],
    "solids": [],
    "props": [
        # The gate of the city wall across the canyon road, behind the start grid.
        prop(BARRENS_DOODADS + "terrain/orgrimmargate_completed/orgrimmargate_completed.mdx",
             *ORGRIMMAR_GATE, yaw=0, scale=0.3, tint=SANDSTONE),
        prop(BARRENS_DOODADS + "terrain/orgrimmarwallsegment_completed/orgrimmarwallsegment_completed.mdx",
             ORGRIMMAR_GATE[0] + 4, ORGRIMMAR_GATE[1] + 270, yaw=0, scale=0.3, tint=SANDSTONE),
        # The Valley of Wisdom: Grommash Hold.
        dict(oprop(ORC + "greathall/greathall.mdx", 486, 342, sequence="Stand Upgrade Second", scale=0.45),
             nudge=True),
        # The Valley of Strength: the bank (a stronghold) and the wind riders' roost.
        dict(oprop(ORC + "greathall/greathall.mdx", 640, 642, sequence="Stand Upgrade First", scale=0.3), nudge=True),
        dict(oprop(ORC + "watchtower/watchtower.mdx", 768, 612, scale=0.35), nudge=True),
        dict(oprop(OTHER + "wyverncage/wyverncage.mdx", 790, 640), nudge=True),
        dict(oprop(ORC_UNITS + "riderlesswyvern/riderlesswyvern.mdx", 752, 650, yaw=225), nudge=True),
        # Thrall at Grommash Hold's door; a tauren by the Valley of Wisdom's totems.
        dict(oprop(ORC_UNITS + "thrallmountless/thrallmountless.mdx", 487, 371), nudge=True),
        dict(oprop(ORC_UNITS + "tauren/tauren.mdx", 452, 420, yaw=315), nudge=True),
        # The Drag: a kodo by the stalls.
        dict(prop(ORC_UNITS + "kotobeastnorider/kotobeastnorider.mdx", 1880, 1180, yaw=180), nudge=True),
        # The Cleft of Shadow: its warlocks' altar and the Darkfire lounge.
        oprop(ORC + "altarofstorms/altarofstorms.mdx", 640, 470, scale=0.3),
        oprop(ORC + "voodoolounge/voodoolounge.mdx", 680, 455),
        # Rock spires and an arch on the canyon's rock (world units).
        dict(oprop(OUTLAND + "rocks/outland_spires/outland_spires4.mdx", 470, 660, scale=0.35), nudge=True),
        dict(oprop(OUTLAND + "rocks/outland_spires/outland_spires0.mdx", 540, 780, scale=0.3), nudge=True),
        dict(prop(OUTLAND + "rocks/outland_spires/outland_spires2.mdx", 900, 50, scale=0.32), nudge=True),
        dict(prop(BARRENS_DOODADS + "rocks/barrens_spires/barrens_spires0.mdx", 1720, 210, scale=0.3, cut=2.1),
             nudge=True),
        dict(prop(OUTLAND + "rocks/outland_spires/outland_spires6.mdx", 1930, 470, scale=0.34), nudge=True),
        dict(prop(BARRENS_DOODADS + "structures/brockarch/brockarch.mdx", 1860, 120, scale=0.3), nudge=True),
        dict(prop(BARRENS_DOODADS + "rocks/barrens_spires/barrens_spires4.mdx", 1990, 640, scale=0.26, cut=2.1),
             nudge=True),
        dict(prop(OUTLAND + "rocks/outland_spires/outland_spires8.mdx", 60, 860, scale=0.3), nudge=True),
        dict(prop(OUTLAND + "rocks/outland_spires/outland_spires3.mdx", 610, 450, scale=0.3), nudge=True),
        dict(prop(BARRENS_DOODADS + "rocks/barrens_spires/barrens_spires2.mdx", 500, 470, scale=0.22, cut=2.1),
             nudge=True),
    ],
}

CITIES = [STORMWIND, IRONFORGE, ORGRIMMAR]
