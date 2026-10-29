"""A Battlegrounds Cup sprint for build_battlegrounds.py: Alterac Valley.

A sprint is an open circuit (Circuit.lua with `open` and `laps` 1): the
karts run once from the grid along the course's road to its last gate. Its
street is the karts' full grip only (no street walls: the owner, "no
fences"); off it the ground is drivable at grass speed out to the
battleground's natural walls, Circuit.lua's packed passability grid
(`grassMap`, as Arathi's open grass). Its ice (`iceMap`, the same grid) is
proposed to Codex as a surface of its own; Circuit.lua does not read it yet.

sprint_geometry(d, wc3, cache) builds the runtime definition (plain Python
values): the open centerline and its narrows (bridges), the spawn, the
scenery it keeps (sprint_props: the dressing drawn clear of the street and
off the water; the painter draws the same list), the passability and ice
grids (sprint_maps), the gates (sprint_gates: each a
straight cut across the open ground near a place, wall to wall, checked to
part the grid so no way leads round it), the inert elevation and the
reviewed route. validate_sprint walks the route through the gates in order.
lua_maps packs a grid as Circuit.lua reads it.

Standard library only.
"""
from collections import deque
from math import sqrt

from build_city_tracks import narrow_segments
from city_layouts import KART, WALL_INSET


def _segment(x, y, ax, ay, bx, by):
    """(distance, t) from (x, y) to the segment from a to b."""
    dx, dy = bx - ax, by - ay
    length = dx * dx + dy * dy
    t = 0.0 if length == 0 else max(0.0, min(1.0, ((x - ax) * dx + (y - ay) * dy) / length))
    ex, ey = x - ax - t * dx, y - ay - t * dy
    return sqrt(ex * ex + ey * ey), t


class Lanes:
    """Distance from a point to the open centerline (and which segment is
    nearest), by a bucket grid of the segments."""

    def __init__(self, line, reach, bucket=128):
        self.line, self.bucket = line, bucket
        self.cells = {}
        for k in range(1, len(line)):
            (ax, ay), (bx, by) = line[k - 1], line[k]
            for j in range(int((min(ay, by) - reach) // bucket), int((max(ay, by) + reach) // bucket) + 1):
                for i in range(int((min(ax, bx) - reach) // bucket), int((max(ax, bx) + reach) // bucket) + 1):
                    self.cells.setdefault((i, j), []).append(k)

    def nearest(self, x, y):
        """(distance, segment k (1-based: joining point k to point k + 1)),
        or (None, None) beyond the grid's reach."""
        best, which = None, None
        for k in self.cells.get((int(x // self.bucket), int(y // self.bucket)), ()):
            (ax, ay), (bx, by) = self.line[k - 1], self.line[k]
            d, _ = _segment(x, y, ax, ay, bx, by)
            if best is None or d < best:
                best, which = d, k
        return best, which


def sprint_heights(d, g):
    """The ground's height (world units above the course's lowest point)
    under each centerline point: the survey's terrain, the mean over 48
    units of the line either side, straight across each narrows (a
    bridge's deck)."""
    import base64
    import json
    import zlib
    from pathlib import Path
    survey = json.loads((Path(__file__).resolve().parent / d["survey"]).read_text(encoding="utf-8"))
    relief = zlib.decompress(base64.b64decode(survey["relief"]["texels"]))
    grid, cols, rows = survey["grid"], survey["columns"], survey["rows"]
    base, step = survey["relief"]["base"], survey["relief"]["step"]
    height = g["height"]

    def ground(x, y):
        c = max(0, min(cols - 1, int(x // grid)))
        r = max(0, min(rows - 1, int((height - y) // grid)))
        v = relief[r * cols + c]
        assert v != 255, "the course runs over a hole in the terrain at (%.0f, %.0f)" % (x, y)
        return base + v * step
    line = g["centerline"]
    n = len(line)
    raw = [ground(x, y) for x, y in line]
    arcs = [0.0]
    for i in range(1, n):
        (ax, ay), (bx, by) = line[i - 1], line[i]
        arcs.append(arcs[-1] + sqrt((bx - ax) ** 2 + (by - ay) ** 2))
    for narrow in g["narrows"]:
        first, last = narrow["first"] - 1, narrow["last"]
        span = (arcs[last] - arcs[first]) or 1.0
        for i in range(first + 1, last):
            t = (arcs[i] - arcs[first]) / span
            raw[i] = raw[first] + (raw[last] - raw[first]) * t
    smooth = []
    for i in range(n):
        acc, count = 0.0, 0
        for j in range(n):
            if abs(arcs[j] - arcs[i]) <= 48:
                acc += raw[j]
                count += 1
        smooth.append(acc / count)
    low = min(smooth)
    return {"centerline": [round((h - low) * 3, 1) for h in smooth], "branches": []}


_STREETS = {}


def sprint_street(d, g):
    """The painter's street (city_paint.Street: lanes, gaps, edges) for a
    sprint's geometry, built once and shared by sprint_props and the
    painter."""
    from city_paint import Street
    entry = _STREETS.get(id(g))
    if entry is None or entry[0] is not g:
        entry = _STREETS[id(g)] = (g, Street(g, g["kart"], d["street_reach"], d["street_far"]))
    return entry[1]


def sprint_props(d, g, wc3, cache, log=print):
    """The scenery a sprint keeps: every landmark (a `building`, where it
    stands), and each piece of the survey's dressing whose model, as drawn
    (leaning north), stays off the street, and that stands off the client's
    water. The rest is left out of the picture and of the karts' way alike
    (sprint_maps reads the kept list)."""
    from pathlib import Path
    from battleground_paint import Survey
    from city_paint import body_clear, sprite_for
    from wc3render import forget_textures
    sv = Survey(Path(__file__).resolve().parent / d["survey"])
    street = sprint_street(d, g)
    height = g["height"]
    kept, near, wet = [], 0, 0
    for item in d["props"]:
        if item.get("building"):
            kept.append(item)
            continue
        X, Y = int(round(item["x"])), int(round(item["y"]))
        row = min(sv.rows - 1, max(0, (height - 1 - Y) // sv.grid))
        col = min(sv.cols - 1, max(0, X // sv.grid))
        if sv.water is not None and sv.water[row * sv.cols + col] > 0:
            wet += 1
            continue
        sprite = sprite_for(wc3, d, item, cache)
        forget_textures()
        if not body_clear(street, sprite, X, Y):
            near += 1
            continue
        kept.append(item)
    log("  scenery: %d kept; %d left out over the street, %d on the water" % (len(kept), near, wet))
    return kept


def sprint_maps(d, g, wc3, cache, log=print):
    """The passability and ice grids (d["maps"]: `cell` units a cell, row 0
    the world's south edge): {"grass": bytearray, "ice": bytearray, "cell",
    "columns", "rows"} (one byte a cell, 1 open / ice). Closed: the world's
    edge, ground steeper than `steep` (the survey's terrain evened `smooth`
    times, as the painted cliffs: where a face is more than half rock),
    every building's, rock's and tent's plan and each tree's trunk (`trunk`
    units), all grown by the karts' inset; and a bridge's sides beyond its
    deck. Always open: the street's grip (the road and its margin; a
    bridge's deck), but for a building's plan. Ice: only `field`, the
    survey's `plane` within `box` above `least`, evened, filled and grown by
    `grow` units: the Field of Strife's frozen middle, the one patch of ice
    the owner asked for. The valley's other frozen ponds and icy ground are
    snow underfoot (open, slow as the rest off the street)."""
    from pathlib import Path
    from battleground_paint import Survey, _bilinear, survey_heights
    from city_paint import sprite_for
    from wc3render import forget_textures
    spec = d["maps"]
    cell, inset = spec["cell"], WALL_INSET
    width, height = g["width"], g["height"]
    cols, rows = width // cell, height // cell
    sv = Survey(Path(__file__).resolve().parent / d["survey"])
    scols, srows, gs = sv.cols, sv.rows, sv.grid
    hts = survey_heights(sv, spec["smooth"])

    def slope(x, y):
        """Yards per yard at world (x, y) (bilinear between survey texels)."""
        row = height - 1 - y
        u, v = (x + 0.5) / gs - 0.5, (row + 0.5) / gs - 0.5
        c, r = max(1, min(scols - 2, int(u + 0.5))), max(1, min(srows - 2, int(v + 0.5)))
        gx = (hts[r * scols + c + 1] - hts[r * scols + c - 1]) / (2.0 * gs)
        gy = (hts[(r - 1) * scols + c] - hts[(r + 1) * scols + c]) / (2.0 * gs)
        return 3.0 * sqrt(gx * gx + gy * gy)

    # Hazards, a cell at a time (its four quarter points).
    hazard = bytearray(cols * rows)
    steep = spec["steep"]
    for r in range(rows):
        for c in range(cols):
            x0, y0 = c * cell, r * cell
            for qx, qy in ((0.25, 0.25), (0.75, 0.25), (0.25, 0.75), (0.75, 0.75)):
                if slope(int(x0 + qx * cell), int(y0 + qy * cell)) >= steep:
                    hazard[r * cols + c] = 1
                    break
    steep_cells = sum(hazard)
    # The scenery's plans and trunks (and the buildings' own, kept apart:
    # they stay closed on the street too).
    building = bytearray(cols * rows)
    placed = 0
    for item in d.get("props", ()):
        blocks = item.get("blocks_karts")
        if not blocks:
            continue
        X, Y = int(round(item["x"])), int(round(item["y"]))
        points = []
        if blocks == "trunk":
            radius = spec["trunk"]
            points = [(dx, dy) for dy in range(-radius, radius + 1) for dx in range(-radius, radius + 1)
                      if dx * dx + dy * dy <= radius * radius]
        else:
            sprite = sprite_for(wc3, d, item, cache)
            forget_textures()
            points = sprite["plan_points"]
        target = building if item.get("building") else hazard
        for dx, dy in points:
            x, y = X + dx, Y + dy
            if 0 <= x < width and 0 <= y < height:
                target[(y // cell) * cols + x // cell] = 1
        placed += 1
    # Grown by the karts' inset: a cell is shut when any of it lies nearer
    # than the inset to a closed cell (the kart's centre may stand anywhere
    # in an open cell).
    span = inset // cell + 1
    offsets = [(dc, dr) for dr in range(-span, span + 1) for dc in range(-span, span + 1)
               if (max(0, abs(dc) - 1) * cell) ** 2 + (max(0, abs(dr) - 1) * cell) ** 2 < inset * inset]

    def grown(mask):
        out = bytearray(mask)
        for r in range(rows):
            for c in range(cols):
                if not mask[r * cols + c]:
                    continue
                for dc, dr in offsets:
                    cc, rr = c + dc, r + dr
                    if 0 <= cc < cols and 0 <= rr < rows:
                        out[rr * cols + cc] = 1
        return out
    closed = grown(hazard)
    walls = grown(building)
    # The street, the bridges' sides; the world's edge.
    line = g["centerline"]
    grip, road = g["roadRadius"], d["course"]["road_half"]
    narrow = {}
    for n in g["narrows"]:
        for k in range(n["first"], n["last"] + 1):
            narrow[k] = n["wallRadius"]
    lanes = Lanes(line, grip + 80)
    street = bytearray(cols * rows)
    for r in range(rows):
        y = (r + 0.5) * cell
        for c in range(cols):
            x = (c + 0.5) * cell
            i = r * cols + c
            lane, k = lanes.nearest(x, y)
            if lane is None:
                continue
            radius = narrow.get(k, grip)
            if lane <= radius:
                street[i] = 1
                assert not (lane <= road and walls[i]), \
                    "a building stands on the road at (%.0f, %.0f)" % (x, y)
                if not walls[i]:
                    closed[i] = 0
            elif k in narrow and lane <= grip + 40:
                closed[i] = 1                     # the bridge's parapets: no way off its sides
    for r in range(rows):
        for c in range(cols):
            x, y = (c + 0.5) * cell, (r + 0.5) * cell
            if x < inset + cell or x > width - inset - cell or y < inset + cell or y > height - inset - cell:
                closed[r * cols + c] = 1
            if walls[r * cols + c]:
                closed[r * cols + c] = 1
    grass = bytearray(1 - v for v in closed)
    # The ice: the Field of Strife's patch alone.
    every = list(sv.planes.values())
    ice = bytearray(cols * rows)
    field = spec["field"]
    fplane = sv.planes[field["plane"]]
    fx0, fy0, fx1, fy1 = field["box"]
    patch = bytearray(cols * rows)
    for r in range(fy0 // cell, fy1 // cell + 1):
        y = int((r + 0.5) * cell)
        row = height - 1 - y
        for c in range(fx0 // cell, fx1 // cell + 1):
            x = int((c + 0.5) * cell)
            if not (fx0 <= x <= fx1 and fy0 <= y <= fy1):
                continue
            total = sum(_bilinear(p, scols, srows, gs, x, row) for p in every)
            if total > 0 and _bilinear(fplane, scols, srows, gs, x, row) >= field["least"] * total:
                patch[r * cols + c] = 1
    # The field's patch evened (a cell takes its 3 x 3 majority), its holes
    # filled (the closed ground not reachable from outside it), then grown.
    for _ in range(field["smooth"]):
        even = bytearray(cols * rows)
        for r in range(1, rows - 1):
            for c in range(1, cols - 1):
                s = sum(patch[(r + dr) * cols + c + dc] for dr in (-1, 0, 1) for dc in (-1, 0, 1))
                even[r * cols + c] = 1 if s >= 5 else 0
        patch = even
    c0, r0, c1, r1 = fx0 // cell, fy0 // cell, fx1 // cell, fy1 // cell
    outside = bytearray(cols * rows)
    todo = deque()
    for c in range(c0, c1 + 1):
        for r in (r0, r1):
            if not patch[r * cols + c]:
                outside[r * cols + c] = 1
                todo.append((c, r))
    for r in range(r0, r1 + 1):
        for c in (c0, c1):
            if not patch[r * cols + c] and not outside[r * cols + c]:
                outside[r * cols + c] = 1
                todo.append((c, r))
    while todo:
        c, r = todo.popleft()
        for dc, dr in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            cc, rr = c + dc, r + dr
            if c0 <= cc <= c1 and r0 <= rr <= r1 and not patch[rr * cols + cc] and not outside[rr * cols + cc]:
                outside[rr * cols + cc] = 1
                todo.append((cc, rr))
    filled = bytearray(cols * rows)
    for r in range(r0, r1 + 1):
        for c in range(c0, c1 + 1):
            if not outside[r * cols + c]:
                filled[r * cols + c] = 1
    grow = field["grow"] // cell
    disc = [(dc, dr) for dr in range(-grow, grow + 1) for dc in range(-grow, grow + 1) if dc * dc + dr * dr <= grow * grow]
    for r in range(r0, r1 + 1):
        for c in range(c0, c1 + 1):
            if filled[r * cols + c]:
                for dc, dr in disc:
                    cc, rr = c + dc, r + dr
                    if 0 <= cc < cols and 0 <= rr < rows:
                        ice[rr * cols + cc] = 1
    log("  maps: %d x %d cells of %d; steep %d, open %d, ice %d (the field's %d); %d blockers" % (
        cols, rows, cell, steep_cells, sum(grass), sum(ice), sum(filled), placed))
    return {"grass": grass, "ice": ice, "street": street, "cell": cell, "columns": cols, "rows": rows}


def _reachable(maps, start, blocked):
    """Open cells reachable from cell `start` (4-connected, through no cell
    in `blocked`)."""
    cols, rows, grass = maps["columns"], maps["rows"], maps["grass"]
    seen = bytearray(cols * rows)
    c, r = start
    seen[r * cols + c] = 1
    todo = deque([start])
    while todo:
        c, r = todo.popleft()
        for dc, dr in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            cc, rr = c + dc, r + dr
            if 0 <= cc < cols and 0 <= rr < rows:
                i = rr * cols + cc
                if grass[i] and not seen[i] and i not in blocked:
                    seen[i] = 1
                    todo.append((cc, rr))
    return seen


def sprint_gates(d, g, maps, log=print):
    """Each gate (d["gate_cuts"]: name, "y" or "x", value): the straight line
    across the open ground there, through the course, from wall to wall
    (the run of open cells it crosses that holds the course's crossing: the
    first after the gate before it, as the karts meet it); tried nearest the
    value first, within 160 units, until it parts the grid: with its cells
    shut, the finish cannot be reached from the grid. A "y" gate is crossed
    northwards, an "x" gate westwards."""
    cell, cols, rows, grass = maps["cell"], maps["columns"], maps["rows"], maps["grass"]
    line = g["centerline"]
    sx, sy = g["spawn"][:2]
    ex, ey = line[-1]
    start, end = (int(sx // cell), int(sy // cell)), (int(ex // cell), int(ey // cell))
    assert grass[start[1] * cols + start[0]] and grass[end[1] * cols + end[0]], "the grid and the finish are open"
    gates = []
    after = (1, -1.0)                         # the gate before's crossing: segment, fraction
    for name, axis, value in d["gate_cuts"]:
        found = None
        for offset in sorted(range(-160, 161, cell), key=abs):
            v = value + offset
            # Where the course first crosses the line after the gate before.
            cross = None
            for k in range(after[0], len(line)):
                (ax, ay), (bx, by) = line[k - 1], line[k]
                a, b = (ay, by) if axis == "y" else (ax, bx)
                if (a - v) * (b - v) <= 0 and a != b:
                    t = (v - a) / (b - a)
                    if k == after[0] and t <= after[1]:
                        continue
                    cross = (ax + (bx - ax) * t, ay + (by - ay) * t)
                    at = (k, t)
                    break
            if cross is None:
                continue
            # The run of open cells along the line holding the crossing.
            if axis == "y":
                r = int(v // cell)
                c = int(cross[0] // cell)
                if not grass[r * cols + c]:
                    continue
                lo = hi = c
                while lo > 0 and grass[r * cols + lo - 1]:
                    lo -= 1
                while hi < cols - 1 and grass[r * cols + hi + 1]:
                    hi += 1
                blocked = {r * cols + cc for cc in range(lo, hi + 1)}
                gate = {"name": name, "ax": lo * cell, "ay": v, "bx": (hi + 1) * cell, "by": v, "nx": 0, "ny": 1}
            else:
                c = int(v // cell)
                r = int(cross[1] // cell)
                if not grass[r * cols + c]:
                    continue
                lo = hi = r
                while lo > 0 and grass[(lo - 1) * cols + c]:
                    lo -= 1
                while hi < rows - 1 and grass[(hi + 1) * cols + c]:
                    hi += 1
                blocked = {rr * cols + c for rr in range(lo, hi + 1)}
                gate = {"name": name, "ax": v, "ay": lo * cell, "bx": v, "by": (hi + 1) * cell, "nx": -1, "ny": 0}
            seen = _reachable(maps, start, blocked)
            if seen[end[1] * cols + end[0]]:
                continue                      # a way round: try the next line
            found, crossed = gate, at
            break
        assert found, "no cut across the valley near the gate %s" % name
        after = crossed
        span = abs(found["bx"] - found["ax"]) + abs(found["by"] - found["ay"])
        log("  gate %s: %s %d, %d units across" % (name, axis, found["ay"] if axis == "y" else found["ax"], span))
        gates.append(found)
    return gates


def sprint_geometry(d, wc3=None, cache=None, log=print):
    """A sprint's runtime definition (see the module's notes)."""
    if wc3 is None:
        raise SystemExit("--wc3 is required: the scenery's plans stand in the karts' way")
    cache = {} if cache is None else cache
    width, height = d["size"]
    line = list(d["centerline"])
    g = {"kind": "sprint", "id": d["id"], "name": d["name"], "version": d["version"], "width": width,
         "height": height, "wallInset": WALL_INSET, "roadRadius": d["road_radius"], "wallRadius": d["wall_radius"],
         "fullSpeedToWalls": bool(d.get("full_speed_to_walls")), "kart": KART, "centerline": line,
         "open": True, "laps": d["laps"], "narrows": narrow_segments(d, line), "branches": [], "plazas": [],
         "solids": [], "spawn": tuple(d["spawn"])}
    sx, sy = g["spawn"][:2]
    assert (sx, sy) in line, "the spawn stands on a centerline point"
    g["elevation"] = sprint_heights(d, g)
    d["props"] = sprint_props(d, g, wc3, cache, log)
    maps = sprint_maps(d, g, wc3, cache, log)
    g["maps"] = maps
    g["gates"] = sprint_gates(d, g, maps, log)
    k = line.index((sx, sy))
    g["route"] = line[k::2] + ([line[-1]] if (len(line) - 1 - k) % 2 else [])
    return g


def validate_sprint(g):
    """The reviewed route from the grid to the finish: every step on open
    ground (the passability grid), through every gate in order, the last
    one the finish."""
    from build_battlegrounds import crosses
    maps = g["maps"]
    cell, cols, grass = maps["cell"], maps["columns"], maps["grass"]
    route = g["route"]
    gates = g["gates"]
    passed, crossings, nxt = [], [], 0
    x, y = route[0]
    for index, (bx, by) in enumerate(route[1:], 1):
        n = max(1, int(sqrt((bx - x) ** 2 + (by - y) ** 2) / 4.0) + 1)
        ax, ay = x, y
        for k in range(1, n + 1):
            tx, ty = ax + (bx - ax) * k / n, ay + (by - ay) * k / n
            assert grass[int(ty // cell) * cols + int(tx // cell)], "the route meets a wall at (%.0f, %.0f)" % (tx, ty)
            if nxt < len(gates) and crosses(gates[nxt], x, y, tx, ty):
                passed.append(gates[nxt]["name"])
                crossings.append(index)
                nxt += 1
            x, y = tx, ty
    assert passed == [gt["name"] for gt in gates], "the route passes the gates in order: %s" % passed
    g["routeGates"] = crossings
    return {"passed": passed, "levels": [0], "ramps": [], "crossings": crossings}


def packed(cells, cols, rows):
    """A grid (one byte a cell, row 0 south) as Circuit.lua's packed bits:
    row-major from the world's south edge, the least significant bit first."""
    out = bytearray((cols * rows + 7) // 8)
    for i in range(cols * rows):
        if cells[i]:
            out[i // 8] |= 1 << (i % 8)
    return bytes(out)


def lua_bytes(data, width=96):
    """A Lua string expression for `data`: printable ASCII as itself, every
    other byte as a three-digit escape, in table.concat'ed pieces."""
    pieces = []
    for k in range(0, len(data), width):
        text = []
        for b in data[k:k + width]:
            if 32 <= b < 127 and b not in (34, 92):
                text.append(chr(b))
            else:
                text.append("\\%03d" % b)
        pieces.append('"' + "".join(text) + '"')
    return "table.concat({\n" + ",\n".join("        " + p for p in pieces) + "\n    })"
