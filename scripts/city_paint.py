"""Paint one Capital Cities Cup city for build_city_tracks.py.

A city circuit is a street circuit: the course runs between walls through
the city, and the picture shows the city around it from the karts' camera
(height leans north by the city's `lean`). Layers, bottom to top:

1. Ground: Warcraft III terrain tiles on the game's own 32-unit corner grid.
   Each corner takes the tileset of its district (the nearest district seed,
   or an explicit zone); every cell draws its lowest type whole and each
   higher type through the tileset's transition shape, as the game does.
2. Water (canals, lakes): the tileset's water texture, tinted, darker along
   the banks, with the stone quay face below every bank that faces the camera
   and the bank's shadow on the water.
3. The street: every texel within the karts' reach of the course (the wall
   radius plus a kart's half-length) is paved: the road from wall to wall
   (a city street has no shoulders), a kerb at each wall's foot, bridge
   decks, the chequered finish line and plazas (marble), with the walls'
   shadows. A city may keep the old rough kerb-side strip (sidewalk flags
   beyond the road radius) with `shoulders`.
   A city on several levels (`elevation`) then shows them: retaining walls,
   raised streets, brinks, the sun's shadows and lit ramps (Relief).
4. Everything with height, north to south so nearer things cover farther
   ones: the stone balustrade along both street edges (with pillars), the
   city's landmarks, generated district buildings, lamps and banners. Each
   model is rendered by wc3render.py with its ground shadow; no model's body
   may cover the street (its shadow may).

One texel per world unit; row 0 is the north edge. Integer compositing.
"""
import hashlib
from array import array
from math import atan2, cos, floor, pi, sin, sqrt
from pathlib import Path

import city_layouts as L
import city_meshes as M
import wc3render as R
from circuit_boundary import loop_radii
from paintkit import encode_png, encode_tga

ROOT = Path(__file__).resolve().parents[1]
CELL = 32                  # world units per terrain cell (64 source texels, halved)
BUCKET = 64                # street distance-field buckets
FAR = 1.0e9


def hash32(a, b, seed):
    h = (a * 374761393 + b * 668265263 + seed * 2147483647) & 0xFFFFFFFF
    h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
    return h ^ (h >> 16)


# ---------------------------------------------------------------------------
# Picture: three channel planes, row 0 north.


class Picture:
    def __init__(self, width, height, color=(0, 0, 0)):
        self.w, self.h = width, height
        n = width * height
        self.r = bytearray([color[0]]) * n
        self.g = bytearray([color[1]]) * n
        self.b = bytearray([color[2]]) * n

    def over(self, i, r, g, b, a):
        if a >= 255:
            self.r[i], self.g[i], self.b[i] = r, g, b
        elif a > 0:
            k = 255 - a
            self.r[i] = (r * a + self.r[i] * k + 127) // 255
            self.g[i] = (g * a + self.g[i] * k + 127) // 255
            self.b[i] = (b * a + self.b[i] * k + 127) // 255

    def scale(self, i, k):
        """Darken (or lighten) one texel by k/256, clamped."""
        self.r[i] = min(255, self.r[i] * k >> 8)
        self.g[i] = min(255, self.g[i] * k >> 8)
        self.b[i] = min(255, self.b[i] * k >> 8)

    def tga(self):
        """Type-2 BGRA32, opaque, bottom-left origin (paintkit.encode_tga's header)."""
        import struct
        header = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, self.w, self.h, 32, 8)
        body = bytearray(self.w * self.h * 4)
        o = 0
        for row in range(self.h - 1, -1, -1):
            base = row * self.w
            body[o:o + 4 * self.w:4] = self.b[base:base + self.w]
            body[o + 1:o + 4 * self.w:4] = self.g[base:base + self.w]
            body[o + 2:o + 4 * self.w:4] = self.r[base:base + self.w]
            body[o + 3:o + 4 * self.w:4] = b"\xff" * self.w
            o += 4 * self.w
        return header + bytes(body)

    def rows(self, step=1, box=None):
        """Top-down [r, g, b, a] rows, box-filtered by `step` (exact integers),
        optionally of a (left, top, width, height) part."""
        left, top, width, height = box or (0, 0, self.w, self.h)
        out = []
        n = step * step
        for j in range(top, top + height - step + 1, step):
            row = []
            for i in range(left, left + width - step + 1, step):
                tr = tg = tb = 0
                for dj in range(step):
                    base = (j + dj) * self.w + i
                    for di in range(step):
                        tr += self.r[base + di]
                        tg += self.g[base + di]
                        tb += self.b[base + di]
                row.append([(tr + n // 2) // n, (tg + n // 2) // n, (tb + n // 2) // n, 255])
            out.append(row)
        return out


# ---------------------------------------------------------------------------
# Terrain tiles.


class Tileset:
    """Warcraft III terrain atlases cut into 32 x 32 RGBA cells.

    Cells 0-15 are the transition shapes (index = 8 TL + 4 TR + 2 BL + 1 BR,
    for the corners the type holds; 0 and 15 are whole); a 512-wide atlas adds
    16 whole variations as cells 16-31."""

    def __init__(self, wc3):
        self.wc3, self.cache = wc3, {}
        self.strata = {}         # Strata regions of plain textures, by (path, region, shade)

    def cells(self, path, shade=1.0):
        """`shade` multiplies the colour: one factor, or (red, green, blue[,
        saturation]) to move a tileset's hue: the colour first goes toward
        its grey by the saturation, then each channel is scaled (the Dungeon
        set's red rock made the grey-brown of a dwarven city, say)."""
        if (path, shade) in self.cache:
            return self.cache[(path, shade)]
        w, h, tex = R.read_dds(R.archive_file(self.wc3, path).read_bytes())
        if isinstance(shade, tuple):
            sr, sg, sb = shade[:3]
            sat = shade[3] if len(shade) > 3 else 1.0
            ints = []
            for t in tex:
                grey = 0.30 * t[0] + 0.59 * t[1] + 0.11 * t[2]
                r, g, b = (grey + (t[0] - grey) * sat, grey + (t[1] - grey) * sat, grey + (t[2] - grey) * sat)
                ints.append((min(255, int(r * sr * 255 + 0.5)), min(255, int(g * sg * 255 + 0.5)),
                             min(255, int(b * sb * 255 + 0.5)), int(t[3] * 255 + 0.5)))
        else:
            ints = [(min(255, int(t[0] * shade * 255 + 0.5)), min(255, int(t[1] * shade * 255 + 0.5)),
                     min(255, int(t[2] * shade * 255 + 0.5)), int(t[3] * 255 + 0.5)) for t in tex]
        cells = []
        for index in range(32 if w >= 512 else 16):
            cx = (index % 4) * 64 + (256 if index >= 16 else 0)
            cy = ((index % 16) // 4) * 64
            cell = []
            for y in range(0, 64, 2):
                for x in range(0, 64, 2):
                    a = ints[(cy + y) * w + cx + x]
                    b = ints[(cy + y) * w + cx + x + 1]
                    c = ints[(cy + y + 1) * w + cx + x]
                    d = ints[(cy + y + 1) * w + cx + x + 1]
                    cell.append(tuple((a[k] + b[k] + c[k] + d[k] + 2) // 4 for k in range(4)))
            cells.append(cell)
        self.cache[(path, shade)] = cells
        return cells

    def whole(self, path, x, y, seed=3, shade=1.0):
        """The color of a paved surface at world texel (x, y): the tileset's
        whole cells (variations where the atlas has them), tiled on its grid."""
        cells = self.cells(path, shade)
        pool = cells[16:] if len(cells) > 16 else cells[15:16]
        cell = pool[hash32(x // CELL, y // CELL, seed) % len(pool)]
        return cell[((CELL - 1 - (y % CELL)) * CELL) + (x % CELL)]


class Strata:
    """A region of a plain Warcraft III texture (a cliff model's layered
    rock), shaded like a terrain tile (`shade`: a factor or (red, green, blue[,
    saturation])), laid along a face two texels per world unit and stretched
    over its height: a canyon wall's strata."""

    def __init__(self, tiles, spec):
        path, region, shade = spec
        key = (path, tuple(region), shade)
        if key not in tiles.strata:
            w, h, tex = R.read_dds(R.archive_file(tiles.wc3, path).read_bytes())
            x0, y0, x1, y1 = region
            rows = []
            for y in range(y0, y1):
                row = []
                for x in range(x0, x1):
                    t = tex[y * w + x]
                    if isinstance(shade, tuple):
                        sr, sg, sb = shade[:3]
                        sat = shade[3] if len(shade) > 3 else 1.0
                        grey = 0.30 * t[0] + 0.59 * t[1] + 0.11 * t[2]
                        row.append((min(255, int((grey + (t[0] - grey) * sat) * sr * 255 + 0.5)),
                                    min(255, int((grey + (t[1] - grey) * sat) * sg * 255 + 0.5)),
                                    min(255, int((grey + (t[2] - grey) * sat) * sb * 255 + 0.5))))
                    else:
                        row.append((min(255, int(t[0] * shade * 255 + 0.5)), min(255, int(t[1] * shade * 255 + 0.5)),
                                    min(255, int(t[2] * shade * 255 + 0.5))))
                rows.append(row)
            tiles.strata[key] = rows
        self.rows = tiles.strata[key]
        self.width, self.height = len(self.rows[0]), len(self.rows)

    def sample(self, x, k, rise):
        """The colour at world column x, k rows down from the top of a face
        `rise` rows tall."""
        row = self.rows[min(self.height - 1, max(0, k) * self.height // max(1, rise))]
        return row[(x * 2) % self.width]

    def tile(self, x, y):
        """The colour at world texel (x, y), the region tiled flat two texels
        per world unit (a plateau's surface: Teldrassil's bark)."""
        return self.rows[(self.height - 1) - (y * 2) % self.height][(x * 2) % self.width]


def district_at(city, x, y):
    """The district whose seed (world point) is nearest to (x, y)."""
    best, found = None, None
    for district in city["districts"]:
        for sx, sy in district["seeds"]:
            d = (x - sx) ** 2 + (y - sy) ** 2
            if best is None or d < best:
                best, found = d, district
    return found


def corner_types(city, width, height):
    """Terrain type index at every grid corner (columns x rows of corners)."""
    names = [t["name"] for t in city["terrain"]]
    cols, rows = width // CELL + 1, height // CELL + 1
    grid = [[0] * cols for _ in range(rows)]
    for j in range(rows):
        for i in range(cols):
            grid[j][i] = names.index(district_at(city, i * CELL, j * CELL)["ground"])
    for zone in city.get("zones", []):
        index = names.index(zone["terrain"])
        shape = zone["shape"]
        for j in range(rows):
            for i in range(cols):
                if inside(shape, i * CELL, j * CELL):
                    grid[j][i] = index
    return grid


def inside(shape, x, y):
    kind = shape[0]
    if kind == "poly":
        points = shape[1]
        hit = False
        n = len(points)
        for k in range(n):
            ax, ay = points[k - 1]
            bx, by = points[k]
            if (ay > y) != (by > y) and x < ax + (y - ay) * (bx - ax) / (by - ay):
                hit = not hit
        return hit
    if kind == "circle":
        cx, cy, r = shape[1]
        return (x - cx) ** 2 + (y - cy) ** 2 <= r * r
    if kind == "rect":
        x0, y0, x1, y1 = shape[1]
        return x0 <= x <= x1 and y0 <= y <= y1
    raise ValueError(kind)


def paint_terrain(pic, city, tiles):
    types = city["terrain"]
    grid = corner_types(city, pic.w, pic.h)
    for cy in range(pic.h // CELL):
        top = pic.h - (cy + 1) * CELL         # picture row of the cell's north edge
        for cx in range(pic.w // CELL):
            bl, br = grid[cy][cx], grid[cy][cx + 1]
            tl, tr = grid[cy + 1][cx], grid[cy + 1][cx + 1]
            present = sorted({bl, br, tl, tr})     # draw order: the terrain list order
            base = types[present[0]]
            cells = tiles.cells(base["tile"], base.get("shade", 1.0))
            if len(cells) > 16:
                pick = hash32(cx, cy, 7) % 100
                cell = cells[16 + hash32(cx, cy, 11) % 16] if pick < base.get("variety", 30) else cells[15]
            else:
                cell = cells[15]
            blit(pic, cell, cx * CELL, top, opaque=True)
            for t in present[1:]:
                mask = 8 * (tl == t) + 4 * (tr == t) + 2 * (bl == t) + (br == t)
                blit(pic, tiles.cells(types[t]["tile"], types[t].get("shade", 1.0))[mask], cx * CELL, top)


def blit(pic, cell, x0, top, opaque=False):
    k = 0
    for y in range(CELL):
        base = (top + y) * pic.w + x0
        for x in range(CELL):
            r, g, b, a = cell[k]
            k += 1
            if opaque:
                pic.r[base + x], pic.g[base + x], pic.b[base + x] = r, g, b
            elif a:
                pic.over(base + x, r, g, b, a)


# ---------------------------------------------------------------------------
# The street: a distance field round the course.


class Street:
    """Per texel near the course: `gap`, the distance beyond the karts' reach
    (the wall radius plus a kart's half-length, KART; <= 0 inside the street,
    capped at `reach`); `lane`, the distance to the nearest road axis, with
    that segment's index and parameter (for kerbs and the finish line); the
    outward normal (nx, ny) of the street edge nearest the texel; `plaza`, set
    inside a plaza's reach. Texel index: row * w + column, row 0 north."""

    def __init__(self, geometry, kart, reach, far):
        self.w, self.h = geometry["width"], geometry["height"]
        self.road = geometry["roadRadius"]
        self.wall = geometry.get("wallRadius") or geometry["roadRadius"]
        self.kart, self.reach, self.far = kart, reach, far
        loop = geometry["centerline"]
        self.loop_count = len(loop)
        self.narrows = geometry.get("narrows") or []
        # Each loop segment's wall: the street's, nearer in a narrows.
        radii = loop_radii(geometry) if geometry.get("wallRadius") else [self.wall] * len(loop)
        caps = []          # (ax, ay, bx, by, visual radius, lane index or -1)
        segs, turn = [], []
        for i in range(len(loop)):
            segs.append((loop[i - 1], loop[i]))
            turn.append(_turn(loop[i - 2], loop[i - 1], loop[i]))
        for branch in geometry.get("branches", []):
            for i in range(1, len(branch)):
                segs.append((branch[i - 1], branch[i]))
                turn.append(0.0)
        self.segs, self.turn = segs, turn
        self.cum = []
        total = 0.0
        for (ax, ay), (bx, by) in segs:
            self.cum.append(total)
            total += sqrt((bx - ax) ** 2 + (by - ay) ** 2)
        self.total = total
        for k, ((ax, ay), (bx, by)) in enumerate(segs):
            caps.append((ax, ay, bx, by, (radii[k] if k < len(loop) else self.wall) + kart, k))
        for p in geometry.get("plazas", []):
            caps.append((p["ax"], p["ay"], p["bx"], p["by"], p["radius"] + kart, -1))
        self.caps = caps
        self.buckets = self._buckets(reach)
        self.far_buckets = self._buckets(far)
        n = self.w * self.h
        self.gap = array("f", [reach]) * n
        self.lane = array("f", [FAR]) * n
        self.seg = array("i", [-1]) * n
        self.at = array("f", [0.0]) * n
        self.nx = array("f", [0.0]) * n
        self.ny = array("f", [0.0]) * n
        self.plaza = bytearray(n)
        w, h = self.w, self.h
        for (bi, bj), found in self.buckets.items():
            for y in range(bj * BUCKET, min(h, (bj + 1) * BUCKET)):
                row = h - 1 - y
                py = y + 0.5
                for x in range(bi * BUCKET, min(w, (bi + 1) * BUCKET)):
                    px = x + 0.5
                    best_gap, best_lane, which, at, nx, ny, plaza = reach, FAR, -1, 0.0, 0.0, 0.0, 0
                    for k in found:
                        ax, ay, bx, by, radius, lane = caps[k]
                        dx, dy = bx - ax, by - ay
                        length = dx * dx + dy * dy
                        t = 0.0 if length == 0 else ((px - ax) * dx + (py - ay) * dy) / length
                        t = 0.0 if t < 0.0 else (1.0 if t > 1.0 else t)
                        ex, ey = px - (ax + t * dx), py - (ay + t * dy)
                        d = sqrt(ex * ex + ey * ey)
                        g = d - radius
                        if g < best_gap:
                            best_gap = g
                            if d > 0:
                                nx, ny = ex / d, ey / d
                        if lane >= 0:
                            if d < best_lane:
                                best_lane, which, at = d, lane, t
                        elif g <= 0:
                            plaza = 1
                    i = row * w + x
                    self.gap[i] = best_gap
                    self.lane[i] = best_lane
                    self.seg[i] = which
                    self.at[i] = at
                    self.nx[i], self.ny[i] = nx, ny
                    self.plaza[i] = plaza

    def _buckets(self, reach):
        buckets = {}
        for k, (ax, ay, bx, by, radius, _) in enumerate(self.caps):
            r = radius + reach
            for j in range(int(floor((min(ay, by) - r) / BUCKET)), int(floor((max(ay, by) + r) / BUCKET)) + 1):
                for i in range(int(floor((min(ax, bx) - r) / BUCKET)), int(floor((max(ax, bx) + r) / BUCKET)) + 1):
                    if 0 <= i * BUCKET < self.w and 0 <= j * BUCKET < self.h:
                        buckets.setdefault((i, j), []).append(k)
        return buckets

    def index(self, x, y):
        return (self.h - 1 - y) * self.w + x

    def along(self, i):
        """Arc length along the course of texel i's nearest road point."""
        k = self.seg[i]
        if k < 0:
            return 0.0
        (ax, ay), (bx, by) = self.segs[k]
        return self.cum[k] + self.at[i] * sqrt((bx - ax) ** 2 + (by - ay) ** 2)

    def nearest(self, x, y):
        """(gap, nx, ny) at any point within reach of the street, by search."""
        found = self.far_buckets.get((int(floor(x / BUCKET)), int(floor(y / BUCKET))), [])
        best, nx, ny = self.far, 0.0, 0.0
        for k in found:
            ax, ay, bx, by, radius, _ = self.caps[k]
            dx, dy = bx - ax, by - ay
            length = dx * dx + dy * dy
            t = 0.0 if length == 0 else max(0.0, min(1.0, ((x - ax) * dx + (y - ay) * dy) / length))
            ex, ey = x - (ax + t * dx), y - (ay + t * dy)
            d = sqrt(ex * ex + ey * ey)
            if d - radius < best:
                best = d - radius
                if d > 0:
                    nx, ny = ex / d, ey / d
        return best, nx, ny


def _turn(a, b, c):
    ux, uy = b[0] - a[0], b[1] - a[1]
    vx, vy = c[0] - b[0], c[1] - b[1]
    lu, lv = sqrt(ux * ux + uy * uy) or 1.0, sqrt(vx * vx + vy * vy) or 1.0
    return (ux * vy - uy * vx) / (lu * lv)    # sine of the turn: + left, - right


# ---------------------------------------------------------------------------
# Water.


def fill_polygon(mask, w, h, points, value=1):
    """Set mask texels whose centres lie inside the polygon (even-odd)."""
    ys = [p[1] for p in points]
    row0 = max(0, int(floor(h - max(ys))))
    row1 = min(h - 1, int(floor(h - min(ys))))
    n = len(points)
    for row in range(row0, row1 + 1):
        y = h - row - 0.5
        xs = []
        for k in range(n):
            ax, ay = points[k - 1]
            bx, by = points[k]
            if (ay > y) != (by > y):
                xs.append(ax + (y - ay) * (bx - ax) / (by - ay))
        xs.sort()
        for k in range(0, len(xs) - 1, 2):
            c0 = max(0, int(floor(xs[k] - 0.5)) + 1)
            c1 = min(w - 1, int(floor(xs[k + 1] - 0.5)))
            if c1 >= c0:
                base = row * w
                mask[base + c0:base + c1 + 1] = bytes([value]) * (c1 - c0 + 1)


def dilate(mask, w, h, radius=1):
    """Square dilation of a 0/1 byte mask by `radius` texels, row by row as
    big integers (one byte per texel)."""
    full = (1 << (8 * w)) - 1
    rows = []
    for r in range(h):
        v = int.from_bytes(mask[r * w:(r + 1) * w], "big")
        acc = v
        for k in range(1, radius + 1):
            acc |= (v << (8 * k)) | (v >> (8 * k))
        rows.append(acc & full)
    out = bytearray(w * h)
    for r in range(h):
        acc = 0
        for k in range(max(0, r - radius), min(h, r + radius + 1)):
            acc |= rows[k]
        if acc:
            out[r * w:(r + 1) * w] = acc.to_bytes(w, "big")
    return out


def bank_distance(water, w, h, limit):
    """Per water texel, the (square) distance in texels to the nearest dry
    texel, capped at `limit`; 0 on dry texels. Rows as big integers."""
    full = (1 << (8 * w)) - 1
    ones = int.from_bytes(b"\x01" * w, "big")
    wet = [int.from_bytes(water[r * w:(r + 1) * w], "big") for r in range(h)]
    reached = [ones ^ v for v in wet]
    out = [0] * h
    for d in range(1, limit + 1):
        hor = [(v | (v << 8) | (v >> 8)) & full for v in reached]
        grown = [hor[r] | (hor[r - 1] if r else 0) | (hor[r + 1] if r + 1 < h else 0) for r in range(h)]
        for r in range(h):
            out[r] += (grown[r] & (reached[r] ^ ones)) * d
        reached = grown
    result = bytearray(w * h)
    for r in range(h):
        value = out[r] + (wet[r] & (reached[r] ^ ones)) * limit
        if value:
            result[r * w:(r + 1) * w] = value.to_bytes(w, "big")
    return result


def course_point(street, arc):
    """Point and unit tangent of the loop at arc length `arc`."""
    k = max(0, min(len(street.segs) - 1, _segment_at(street, arc)))
    (ax, ay), (bx, by) = street.segs[k]
    length = sqrt((bx - ax) ** 2 + (by - ay) ** 2) or 1.0
    t = max(0.0, min(1.0, (arc - street.cum[k]) / length))
    return ax + (bx - ax) * t, ay + (by - ay) * t, (bx - ax) / length, (by - ay) / length


def water_masks(city, geometry, street):
    """(water, bridge): the city's water and the canal under each bridge.

    Basins and lakes are the city's traced polygons less its dry land. Along
    the course the canals follow the street: inside the loop, the band
    beside the street's wall is water only where a canal runs (`canals`:
    loop arc ranges, the side and the band's width) and dry elsewhere, so the
    traced basins never leave slivers by the street. `bridges` carry a canal
    under the course: a strip across the street at a loop arc, the street
    passing over it on a bridge. The street and its walls are dry."""
    w, h = street.w, street.h
    thick = city["wall"]["thickness"]
    water = bytearray(w * h)
    for poly in city["water"]:
        fill_polygon(water, w, h, poly)
    for poly in city.get("land", []):
        fill_polygon(water, w, h, poly, 0)
    inner = bytearray(w * h)
    fill_polygon(inner, w, h, geometry["centerline"])
    bands = city.get("canals", [])
    widest = max([b["width"] for b in bands] + [0])
    loop_count = len(geometry["centerline"])
    for i in range(w * h):
        gap = street.gap[i]
        if gap <= thick + 0.5:
            water[i] = 0
            continue
        if gap > thick + widest + 0.5:
            continue
        k = street.seg[i]
        if k < 0 or k >= loop_count:
            continue
        (ax, ay), (bx, by) = street.segs[k]
        t = street.at[i]
        row, col = divmod(i, w)
        x, y = col + 0.5, h - 1 - row + 0.5
        cross = (bx - ax) * (y - (ay + (by - ay) * t)) - (by - ay) * (x - (ax + (bx - ax) * t))
        side = "left" if cross > 0 else "right"
        arc = street.along(i)
        wet = False
        for band in bands:
            if band["side"] == side and band["from"] <= arc <= band["to"] and gap <= thick + band["width"] + 0.5:
                wet = True
                break
        if wet:
            water[i] = 1
        elif inner[i] and gap <= thick + widest + 0.5:
            water[i] = 0
    bridge = bytearray(w * h)
    forced = bytearray(w * h)
    hung = []
    for c in city.get("bridges", []):
        px, py, tx, ty = course_point(street, c["at"])
        nx, ny = -ty, tx                       # left of travel
        half = c["length"] / 2 - 10            # the ends rest on the banks
        left = street.wall + street.kart + thick + c.get("left", 0)
        right = street.wall + street.kart + thick + c.get("right", 0)
        corners = [(px + tx * half + nx * left, py + ty * half + ny * left),
                   (px - tx * half + nx * left, py - ty * half + ny * left),
                   (px - tx * half - nx * right, py - ty * half - ny * right),
                   (px + tx * half - nx * right, py + ty * half - ny * right)]
        face = 2 if c.get("deck") == "planks" else 1      # its side: timber piles or stone arches
        # A bridge over a traced canal carries the canal under it (`force`);
        # one over a river drawn whole only marks its sides.
        if c.get("force", True):
            fill_polygon(bridge, w, h, corners, face)
            fill_polygon(forced, w, h, corners)
        else:
            hung.append((corners, face))
    for i in range(w * h):
        if forced[i]:
            if street.gap[i] > thick + 0.5:
                water[i] = 1
    # Over a river drawn whole, a bridge's side hangs only below its deck,
    # not below the river's own banks within its strip.
    span = city.get("bridge_depth", 15)
    for corners, face in hung:
        own = bytearray(w * h)
        fill_polygon(own, w, h, corners)
        xs, ys = [p[0] for p in corners], [p[1] for p in corners]
        for y in range(max(0, int(floor(min(ys)))), min(h, int(floor(max(ys))) + 1)):
            row = h - 1 - y
            for x in range(max(0, int(floor(min(xs)))), min(w, int(floor(max(xs))) + 1)):
                i = row * w + x
                if not own[i] or not water[i]:
                    continue
                j, k = i - w, 0
                while j >= 0 and water[j] and k < span:
                    j -= w
                    k += 1
                if j >= 0 and k < span and street.gap[j] <= thick + 0.5:
                    bridge[i] = face
    return water, bridge


def paint_water(pic, city, water, tiles, bridge):
    """Water texels get the tinted water texture, darker near the banks. Below
    a bank that faces the camera (land or street just north) the stone quay
    face shows, then the bank's shadow on the water; every bank has a rim.
    Below a bridge the face is deeper and pierced by arches."""
    w, h = pic.w, pic.h
    surface = city.get("water_tile")          # (terrain tile, shade): a liquid that is not water
    if surface is None:
        tex_w, tex_h, tex = R.read_dds(R.archive_file(tiles.wc3, city["water_texture"]).read_bytes())
    tint = city["water_tint"]
    rim = city["water_rim"]
    face = city["quay_face"]
    depth = city.get("quay_depth", 8)
    near = bank_distance(water, w, h, 12)
    up = bytearray(w * h)           # water texels straight above (north), capped
    for i in range(w, w * h):
        if water[i] and water[i - w]:
            up[i] = min(250, up[i - w] + 1)
    span = city.get("bridge_depth", 15)
    arch = city.get("arch_every", 34)
    timber = city.get("deck_planks", (104, 72, 44))
    piles = city.get("pile_every", 30)
    for i in range(w * h):
        if not water[i]:
            continue
        row, c = divmod(i, w)
        k = up[i]
        dim = 1.0
        if bridge[i] == 2 and k < span and row - k - 1 >= 0:
            # A timber bridge's side: its edge beam, then its piles standing
            # in the water, the deck's shadow on the water between them.
            pile = c % piles < 4
            if k < 3 or pile:
                if k < 3:
                    shade = 0.80 - 0.12 * k
                else:
                    shade = 0.64 - 0.30 * k / span
                    if c % piles == 0:
                        shade *= 0.72                              # the pile's shaded side
                pic.r[i] = min(255, int(timber[0] * shade + 0.5))
                pic.g[i] = min(255, int(timber[1] * shade + 0.5))
                pic.b[i] = min(255, int(timber[2] * shade + 0.5))
                continue
            dim = city.get("deck_shadow", 0.55)
        elif bridge[i] and k < span and row - k - 1 >= 0:
            # A bridge's side: a parapet course, then arches over the water.
            phase = c % arch - arch / 2.0 + 0.5
            radius = arch * 0.36
            opening = abs(phase) < radius and k >= 4 + radius - sqrt(max(0.0, radius * radius - phase * phase))
            if opening:
                shade = 0.30 + 0.02 * (span - k)
            else:
                shade = 0.96 - 0.28 * k / span
                if k == 3 or (k > 3 and (c + (k // 4) * 5) % 11 == 0):
                    shade *= 0.78
            pic.r[i] = min(255, int(face[0] * shade + 0.5))
            pic.g[i] = min(255, int(face[1] * shade + 0.5))
            pic.b[i] = min(255, int(face[2] * shade + 0.5))
            continue
        if dim == 1.0 and k < depth and row - k - 1 >= 0:
            # Quay face: courses of ashlar, joints offset each course.
            course = k // 3
            joint = (c + course * 7) % 14 == 0 or k % 3 == 2
            shade = 0.92 - 0.30 * k / depth
            if joint:
                shade *= 0.72
            pic.r[i] = min(255, int(face[0] * shade + 0.5))
            pic.g[i] = min(255, int(face[1] * shade + 0.5))
            pic.b[i] = min(255, int(face[2] * shade + 0.5))
            continue
        shade = 0.70 + 0.30 * near[i] / 12.0              # darker along the banks
        if dim != 1.0:
            shade *= dim                                   # under a timber deck
        elif k < depth + 7 and row - k - 1 >= 0:
            shade *= 0.62                                  # the bank's shadow
        if surface is not None:
            # A liquid drawn from a terrain tile (Undercity's slime).
            r, g, b, _ = tiles.whole(surface[0], c, h - 1 - row, seed=29, shade=surface[1])
            pic.r[i] = min(255, int(r * shade + 0.5))
            pic.g[i] = min(255, int(g * shade + 0.5))
            pic.b[i] = min(255, int(b * shade + 0.5))
            continue
        tx, ty = (c * 2) % tex_w, (row * 2) % tex_h
        acc0 = acc1 = acc2 = 0.0
        for dy in (0, 1):
            for dx in (0, 1):
                t = tex[((ty + dy) % tex_h) * tex_w + (tx + dx) % tex_w]
                acc0 += t[0]
                acc1 += t[1]
                acc2 += t[2]
        light = (acc0 + acc1 + acc2) / 12.0
        pic.r[i] = min(255, int((tint[0] * 0.75 + light * 0.225) * shade * 255 + 0.5))
        pic.g[i] = min(255, int((tint[1] * 0.75 + light * 0.25) * shade * 255 + 0.5))
        pic.b[i] = min(255, int((tint[2] * 0.75 + light * 0.275) * shade * 255 + 0.5))
    # The rim: dry texels within two of the water, light stone.
    edge = dilate(water, w, h, 2)
    for i in range(w * h):
        if edge[i] and not water[i]:
            pic.r[i], pic.g[i], pic.b[i] = rim


# ---------------------------------------------------------------------------
# Underground cities: the mountain's rock round the halls, lava, light.

FLIP = bytes([1, 0]) + bytes(254)          # bytes.translate table: 0 <-> 1


def rock_mask(city, street):
    """The solid rock of an underground city: everything outside its open
    floors (`rock.floors`, world polygons, and every point within
    `rock.band` units of the course: the halls the street runs through)
    plus raised stone blocks standing on them (`rock.blocks`: a forge's
    hearth, a pier) and the rock a narrows cuts through (`rock.tunnel`
    units either side of its centerline, square at its ends), less the
    street, which is always open. None for a city in the open air."""
    spec = city.get("rock")
    if not spec:
        return None
    w, h = street.w, street.h
    open_ = bytearray(w * h)
    band = spec.get("band", 0)
    if band:
        for (ax, ay), (bx, by) in street.segs:
            length = sqrt((bx - ax) ** 2 + (by - ay) ** 2)
            for k in range(max(1, int(length / 8.0 + 0.999)) + 1):
                t = k / max(1, int(length / 8.0 + 0.999))
                fill_disc(open_, w, h, ax + (bx - ax) * t, ay + (by - ay) * t, band)
    for poly in spec["floors"]:
        fill_polygon(open_, w, h, poly)
    for poly in spec.get("blocks", []):
        fill_polygon(open_, w, h, poly, 0)
    if spec.get("tunnel"):
        for narrow in street.narrows:
            close_tunnel(open_, street, narrow, spec["tunnel"])
    rock = bytearray(bytes(open_).translate(FLIP))
    for (bi, bj) in street.buckets:
        for y in range(bj * BUCKET, min(h, (bj + 1) * BUCKET)):
            row = h - 1 - y
            for x in range(bi * BUCKET, min(w, (bi + 1) * BUCKET)):
                i = row * w + x
                if street.gap[i] <= 0.5:
                    rock[i] = 0
    return rock


def close_tunnel(open_, street, narrow, reach):
    """Close every texel within `reach` of a narrows' loop segments (Lua's
    first..last: Street segment k % n), cut square across both ends so the
    halls either side stay open: the rock a tunnel runs through."""
    w, h = street.w, street.h
    count = street.loop_count
    segs = [street.segs[k % count] for k in range(narrow["first"], narrow["last"] + 1)]
    xs = [p[0] for s in segs for p in s]
    ys = [p[1] for s in segs for p in s]
    last = len(segs) - 1
    for y in range(max(0, int(floor(min(ys) - reach))), min(h, int(floor(max(ys) + reach)) + 1)):
        py = y + 0.5
        base = (h - 1 - y) * w
        for x in range(max(0, int(floor(min(xs) - reach))), min(w, int(floor(max(xs) + reach)) + 1)):
            px = x + 0.5
            best, which, at = None, 0, 0.0
            for m, ((ax, ay), (bx, by)) in enumerate(segs):
                dx, dy = bx - ax, by - ay
                length = dx * dx + dy * dy
                t = 0.0 if length == 0 else ((px - ax) * dx + (py - ay) * dy) / length
                c = 0.0 if t < 0.0 else (1.0 if t > 1.0 else t)
                ex, ey = px - (ax + c * dx), py - (ay + c * dy)
                d = ex * ex + ey * ey
                if best is None or d < best:
                    best, which, at = d, m, t
            if best > reach * reach or (which == 0 and at < 0.0) or (which == last and at > 1.0):
                continue
            open_[base + x] = 0


def fill_disc(mask, w, h, cx, cy, radius, value=1):
    """Set mask texels whose centres lie within `radius` of (cx, cy)."""
    for y in range(max(0, int(floor(cy - radius))), min(h, int(floor(cy + radius)) + 1)):
        dy = y + 0.5 - cy
        if dy * dy > radius * radius:
            continue
        dx = sqrt(radius * radius - dy * dy)
        c0 = max(0, int(floor(cx - dx - 0.5)) + 1)
        c1 = min(w - 1, int(floor(cx + dx - 0.5)))
        if c1 >= c0:
            base = (h - 1 - y) * w
            mask[base + c0:base + c1 + 1] = bytes([value]) * (c1 - c0 + 1)


def paint_rings(pic, city, masks):
    """Concentric stone ridges over water or lava (`rings`: centre, radii,
    width, colour, which surface): the Forlorn Cavern's spiral, the Great
    Forge's channels."""
    w, h = pic.w, pic.h
    for ring in city.get("rings", []):
        mask = masks.get(ring.get("on", "water"))
        if mask is None:
            continue
        cx, cy = ring["center"]
        half = ring["width"] / 2
        outer = max(ring["radii"]) + half + 1
        r, g, b = ring["color"]
        for y in range(max(0, int(cy - outer)), min(h, int(cy + outer) + 2)):
            for x in range(max(0, int(cx - outer)), min(w, int(cx + outer) + 2)):
                i = (h - 1 - y) * w + x
                if not mask[i]:
                    continue
                d = sqrt((x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2)
                for radius in ring["radii"]:
                    e = abs(d - radius)
                    if e < half:
                        k = 0.8 if e > half - 1 else 1.0
                        pic.r[i] = int(r * k)
                        pic.g[i] = int(g * k)
                        pic.b[i] = int(b * k)
                        break


def lava_mask(city, street):
    """The city's lava pools less the street and its walls, as its water:
    where a pool meets the street, the street's wall is the pool's shore."""
    spec = city.get("lava")
    if not spec:
        return None
    w, h = street.w, street.h
    dry = city["wall"]["thickness"] + 0.5
    lava = bytearray(w * h)
    for poly in spec["pools"]:
        fill_polygon(lava, w, h, poly)
    for i in range(w * h):
        if lava[i] and street.gap[i] <= dry:
            lava[i] = 0
    return lava


def lava_rims(city, lava, street, rock):
    """Wall columns round the lava pools where the street's own walls do not
    stand: every dry texel within `rim_width` of the lava (beyond the street
    and its walls, off the rock), in the "lava" style, as wall_columns gives
    them."""
    spec = city["lava"]
    width = spec.get("rim_width", 3)
    height = spec.get("rim_height", 10)
    w, h = street.w, street.h
    dry = city["wall"]["thickness"] + 0.5
    near = bank_distance(bytearray(bytes(lava).translate(FLIP)), w, h, width + 1)
    rows = {}
    for i in range(w * h):
        d = near[i]
        if not d or d > width or lava[i] or street.gap[i] <= dry or (rock is not None and rock[i]):
            continue
        row, x = divmod(i, w)
        rows.setdefault(h - 1 - row, []).append((x, height, "lava"))
    return rows


def paint_rock(pic, city, rock, tiles):
    """The cut-away mountain: the rock's top in its tile, darker deeper in;
    where the rock rises north of open ground its face shows, lean x height
    tall, shaded and banded, with a lit rim on top; a dark line where the
    rock's top drops to open ground north of it; open ground at the rock's
    foot a little darker."""
    spec = city["rock"]
    w, h = pic.w, pic.h
    rise = max(1, int(spec["height"] * city["lean"] + 0.5))
    fade = spec.get("fade", 48)
    dark = spec.get("dark", 0.4)
    deep = bank_distance(rock, w, h, fade)
    top_tile, top_shade = spec.get("top", (None, None))
    # A plateau's top in a plain texture (top_texture), instead of a terrain tile.
    top_plain = Strata(tiles, spec["top_texture"]) if spec.get("top_texture") else None
    face_tile, face_shade = spec.get("face", (None, None))
    # A canyon's walls: the face in a cliff texture's strata (face_texture),
    # instead of a terrain tile with painted courses.
    strata = Strata(tiles, spec["face_texture"]) if spec.get("face_texture") else None
    up = bytearray(w * h)               # rock texels counted north from open ground
    for row in range(h - 1, -1, -1):
        base = row * w
        below = base + w
        for c in range(w):
            i = base + c
            if rock[i]:
                if row == h - 1:
                    up[i] = 255
                elif rock[below + c]:
                    up[i] = min(255, up[below + c] + 1)
                else:
                    up[i] = 1
    for i in range(w * h):
        if not rock[i]:
            continue
        row, x = divmod(i, w)
        y = h - 1 - row
        k = up[i]
        if k <= rise and strata is not None:
            r, g, b = strata.sample(x, rise - k, rise)
            s = 0.95 if k >= rise - 1 else 0.62 + 0.38 * k / rise    # the lit brink; the foot in shadow
        elif k <= rise:
            r, g, b, _ = tiles.whole(face_tile, x, y, seed=17, shade=face_shade)
            course = spec.get("course", 0)
            if k >= rise - 1:
                s = 0.95                                     # the lit coping
            elif course:
                # Dressed stone: courses of blocks, joints offset each course.
                s = 0.50 + 0.30 * k / rise
                if k % course == 0 or (x + (k // course) * 11) % 22 == 0:
                    s *= 0.62
            else:
                s = 0.42 + 0.30 * k / rise                   # shadowed, darkest at the foot
                if (k + hash32(x // 9, 0, 19) % 3) % 7 == 0:
                    s *= 0.8                                 # strata
        else:
            if top_plain is not None:
                r, g, b = top_plain.tile(x, y)
            else:
                r, g, b, _ = tiles.whole(top_tile, x, y, seed=23, shade=top_shade)
            s = dark + (1.0 - dark) * (1.0 - deep[i] / fade)
            if row > 0 and not rock[i - w]:
                s *= 0.55                                    # the drop to open ground north
        pic.r[i] = min(255, int(r * s + 0.5))
        pic.g[i] = min(255, int(g * s + 0.5))
        pic.b[i] = min(255, int(b * s + 0.5))
    near = bank_distance(bytearray(bytes(rock).translate(FLIP)), w, h, 8)
    for i in range(w * h):
        if not rock[i] and near[i] < 8:
            pic.scale(i, 180 + 76 * near[i] // 8)


def paint_lava(pic, city, lava, tiles):
    """Lava pools: the tileset's lava, a dark crust along the shores and a
    hot core, a dark stone rim (under the walls that stand round them)."""
    spec = city["lava"]
    w, h = pic.w, pic.h
    tile, shade = spec["tile"]
    near = bank_distance(lava, w, h, 10)
    for i in range(w * h):
        if not lava[i]:
            continue
        row, x = divmod(i, w)
        y = h - 1 - row
        r, g, b, _ = tiles.whole(tile, x, y, seed=29, shade=shade)
        d = near[i]
        if d <= 2:
            s = 0.45                                          # crust
        else:
            s = min(1.15, 0.7 + 0.08 * d)
        pic.r[i] = min(255, int(r * s + 0.5))
        pic.g[i] = min(255, int(g * s + (12 if d > 6 else 0) + 0.5))
        pic.b[i] = min(255, int(b * s + 0.5))
    edge = dilate(lava, w, h, 2)
    rim = spec.get("rim", (52, 42, 38))
    for i in range(w * h):
        if edge[i] and not lava[i]:
            pic.r[i], pic.g[i], pic.b[i] = rim


def paint_glow(pic, city, lava, rock):
    """Light: lava lights everything near it, and each of the city's lights
    (x, y, radius, (r, g, b)) a pool round it; both add to the colour."""
    w, h = pic.w, pic.h
    spec = city.get("lava")
    if spec and lava is not None:
        reach = spec.get("glow_reach", 40)
        gr, gg, gb = spec.get("glow", (110, 46, 8))
        dist = bank_distance(bytearray(bytes(lava).translate(FLIP)), w, h, reach)
        for i in range(w * h):
            d = dist[i]
            if lava[i] or d >= reach or d == 0:
                continue
            f = (1.0 - d / reach) ** 2
            pic.r[i] = min(255, pic.r[i] + int(gr * f + 0.5))
            pic.g[i] = min(255, pic.g[i] + int(gg * f + 0.5))
            pic.b[i] = min(255, pic.b[i] + int(gb * f + 0.5))
    paint_lights(pic, city.get("lights", []))


def paint_water_glow(pic, city, water):
    """Glowing water (Undercity's slime) lights the stone round it as lava
    does: `water_glow` (r, g, b) added, fading over `water_glow_reach` texels."""
    w, h = pic.w, pic.h
    reach = city.get("water_glow_reach", 24)
    gr, gg, gb = city["water_glow"]
    dist = bank_distance(bytearray(bytes(water).translate(FLIP)), w, h, reach)
    for i in range(w * h):
        d = dist[i]
        if water[i] or d >= reach or d == 0:
            continue
        f = (1.0 - d / reach) ** 2
        pic.r[i] = min(255, pic.r[i] + int(gr * f + 0.5))
        pic.g[i] = min(255, pic.g[i] + int(gg * f + 0.5))
        pic.b[i] = min(255, pic.b[i] + int(gb * f + 0.5))


def paint_lights(pic, lights):
    """Warm pools of light, (x, y, radius, (r, g, b)) each, added to the colour."""
    w, h = pic.w, pic.h
    for lx, ly, radius, (gr, gg, gb) in lights:
        for y in range(max(0, int(ly - radius)), min(h, int(ly + radius) + 1)):
            for x in range(max(0, int(lx - radius)), min(w, int(lx + radius) + 1)):
                d = sqrt((x + 0.5 - lx) ** 2 + (y + 0.5 - ly) ** 2)
                if d >= radius:
                    continue
                f = (1.0 - d / radius) ** 2
                i = (h - 1 - y) * w + x
                pic.r[i] = min(255, pic.r[i] + int(gr * f + 0.5))
                pic.g[i] = min(255, pic.g[i] + int(gg * f + 0.5))
                pic.b[i] = min(255, pic.b[i] + int(gb * f + 0.5))


# ---------------------------------------------------------------------------
# Sunken ground: a chasm below the city's level (the Cleft of Shadow).


def pit_mask(city, street):
    """The city's sunken ground (`pits.shapes`: world polygons) less the
    street and its walls, which keep to the city's level. None without pits."""
    spec = city.get("pits")
    if not spec:
        return None
    w, h = street.w, street.h
    dry = city["wall"]["thickness"] + 0.5 + spec.get("margin", 0)
    pit = bytearray(w * h)
    for poly in spec["shapes"]:
        fill_polygon(pit, w, h, poly)
    for i in range(w * h):
        if pit[i] and street.gap[i] <= dry:
            pit[i] = 0
    return pit


def paint_pits(pic, city, pit, tiles):
    """Sunken ground from the karts' camera: the floor in its tile, darker
    toward the edges; below every edge with the city's level just north,
    the chasm's far wall drops `depth` rows in a cliff's strata (`face`, as
    rock.face_texture), lit at the brink, then its shadow on the floor; a
    dark lip all round. Returns the texels no model may stand on: the wall,
    its shadow's first rows and a band along every edge, inside and out."""
    spec = city["pits"]
    w, h = pic.w, pic.h
    floor_tile, floor_shade = spec["floor"]
    depth = spec.get("depth", 24)
    shade_rows = spec.get("shadow", 10)
    strata = Strata(tiles, spec["face"])
    near = bank_distance(pit, w, h, 16)
    up = bytearray(w * h)               # pit texels straight above (north), capped
    for i in range(w, w * h):
        if pit[i] and pit[i - w]:
            up[i] = min(250, up[i - w] + 1)
    keep = bytearray(w * h)
    for i in range(w * h):
        if not pit[i]:
            continue
        row, x = divmod(i, w)
        y = h - 1 - row
        k = up[i]
        walled = row - k - 1 >= 0      # a dry texel above the pit's top: a far wall
        if walled and k < depth:
            r, g, b = strata.sample(x, k, depth)
            s = 0.92 if k < 2 else 0.80 - 0.40 * k / depth
            keep[i] = 1
        else:
            r, g, b, _ = tiles.whole(floor_tile, x, y, seed=37, shade=floor_shade)
            s = 0.62 + 0.38 * min(16, near[i]) / 16.0
            if walled and k < depth + shade_rows:
                s *= 0.60
                keep[i] = 1
            elif near[i] < spec.get("clear", 6):
                keep[i] = 1
        pic.r[i] = min(255, int(r * s + 0.5))
        pic.g[i] = min(255, int(g * s + 0.5))
        pic.b[i] = min(255, int(b * s + 0.5))
    edge = dilate(pit, w, h, 2)
    rim = spec.get("rim", (60, 36, 28))
    for i in range(w * h):
        if edge[i] and not pit[i]:
            pic.r[i], pic.g[i], pic.b[i] = rim
    around = dilate(pit, w, h, spec.get("clear", 6))
    for i in range(w * h):
        if around[i] and not pit[i]:
            keep[i] = 1
    return keep


# ---------------------------------------------------------------------------
# Elevation: terraces, ramps and raised streets (city_layouts: `elevation`).
#
# Every texel has a height: its level's (the last level polygon holding it,
# else the ground's), or on the street and its walls the street's height
# where it passes. The street is the picture's reference: it is drawn where
# it lies, and what is higher or lower than it shows round it. Seen from the
# karts' camera (looking north, the sun in the north-west):
#
# - where higher ground lies north of lower ground, its south-facing wall
#   shows, lean x the difference tall: drawn on the higher ground's southern
#   rows, as the rock's faces are, unless the higher side is the street (a
#   raised street): then it hangs below the street's southern wall, on the
#   lower ground, as a chasm's far wall does;
# - where the ground drops away northward, the brink is lit and the foot of
#   the drop darkened (that wall faces away from the camera);
# - higher ground shades lower ground to its south-east (the sun's shadow);
# - a ramp is lit by its slope: climbing toward the sun darker, away lighter.

SHADOW_ROW = 1.0 / 0.76                    # height a sun ray climbs per row north (shadow vector 0.57, -0.76)


def fill_polygon_value(field, w, h, points, value):
    """fill_polygon for an array of heights: set `value` inside the polygon."""
    ys = [p[1] for p in points]
    row0 = max(0, int(floor(h - max(ys))))
    row1 = min(h - 1, int(floor(h - min(ys))))
    n = len(points)
    for row in range(row0, row1 + 1):
        y = h - row - 0.5
        xs = []
        for k in range(n):
            ax, ay = points[k - 1]
            bx, by = points[k]
            if (ay > y) != (by > y):
                xs.append(ax + (y - ay) * (bx - ax) / (by - ay))
        xs.sort()
        for k in range(0, len(xs) - 1, 2):
            c0 = max(0, int(floor(xs[k] - 0.5)) + 1)
            c1 = min(w - 1, int(floor(xs[k + 1] - 0.5)))
            if c1 >= c0:
                base = row * w
                field[base + c0:base + c1 + 1] = array("d", [value]) * (c1 - c0 + 1)


class Relief:
    """The city's heights: `height[i]` per texel, `street[i]` set on the
    street and its walls, and the street's profile."""

    def __init__(self, city, geometry, street, course):
        spec = city["elevation"]
        w, h = street.w, street.h
        self.spec = spec
        self.ground = float(spec.get("ground", 0.0))
        self.height = array("d", [self.ground]) * (w * h)
        for level in spec.get("levels", []):
            fill_polygon_value(self.height, w, h, level[0], float(level[1]))
        self.profile = L.Profile(spec["street"], course.loop_length)
        # Branch segments follow the loop's in Street.segs: which branch each is.
        owner = []
        for b, branch in enumerate(geometry.get("branches", [])):
            owner += [b] * (len(branch) - 1)
        heights = [float(v) for v in spec.get("branches", [])]
        thick = city["wall"]["thickness"]
        self.street = bytearray(w * h)
        loop = course.loop
        for (bi, bj) in street.buckets:
            for y in range(bj * BUCKET, min(h, (bj + 1) * BUCKET)):
                row = h - 1 - y
                for x in range(bi * BUCKET, min(w, (bi + 1) * BUCKET)):
                    i = row * w + x
                    k = street.seg[i]
                    if k < 0 or street.gap[i] > thick + 0.5:
                        continue
                    self.street[i] = 1
                    if k < loop:
                        self.height[i] = self.profile.at(street.along(i))[0]
                    else:
                        b = owner[k - loop]
                        self.height[i] = heights[b] if b < len(heights) else self.ground


def paint_relief(pic, city, street, course, relief, tiles, rock=None, water=None, pit=None):
    """Paint what the city's heights show (see above). Returns the texels no
    model may stand on: every wall drawn and the brinks."""
    spec = relief.spec
    w, h = pic.w, pic.h
    n = w * h
    lean = city["lean"]
    height, on_street = relief.height, relief.street
    keep = bytearray(n)
    strata = Strata(tiles, spec["face_texture"]) if spec.get("face_texture") else None
    face_tile, face_shade = spec.get("face", (None, None))
    course_rows = spec.get("course", 0)
    lip = spec.get("lip", 1.16)

    def blocked(j):
        return on_street[j] or (rock is not None and rock[j]) or (pit is not None and pit[j])

    # A level's own paving, exactly to its edge (a sunken hall's floor).
    for level in spec.get("levels", []):
        if len(level) < 3:
            continue
        tile, shade = level[2]
        mask = bytearray(n)
        fill_polygon(mask, w, h, level[0])
        for i in range(n):
            if mask[i] and not blocked(i) and (water is None or not water[i]):
                row, x = divmod(i, w)
                r, g, b, _ = tiles.whole(tile, x, h - 1 - row, seed=53, shade=shade)
                pic.r[i], pic.g[i], pic.b[i] = r, g, b

    def face(j, x, k, rise):
        """Texel j of a wall `rise` rows tall, k rows below its brink."""
        if strata is not None:
            r, g, b = strata.sample(x, k, rise)
            s = 0.98 if k == 0 else 0.56 + 0.36 * (rise - k) / rise
        else:
            row = j // w
            r, g, b, _ = tiles.whole(face_tile, x, h - 1 - row, seed=47, shade=face_shade)
            if k == 0:
                s = 1.0
            else:
                s = 0.52 + 0.34 * (rise - k) / rise
                if course_rows and (k % course_rows == 0 or (x + (k // course_rows) * 11) % 22 == 0):
                    s *= 0.66                                # dressed stone: courses, joints offset
        pic.r[j] = min(255, int(r * s + 0.5))
        pic.g[j] = min(255, int(g * s + 0.5))
        pic.b[j] = min(255, int(b * s + 0.5))
        keep[j] = 1

    # Walls and brinks, column by column down every north-south step.
    for i in range(w, n):
        north = i - w
        hn, hs = height[north], height[i]
        if hn - hs >= 0.5:
            rise = int((hn - hs) * lean + 0.5)
            if rise < 1:
                continue
            x = i % w
            if on_street[north] and not on_street[i]:
                # A raised street: its wall hangs below it on the lower ground.
                for k in range(rise):
                    j = i + k * w
                    if j >= n or blocked(j) or (water is not None and water[j]) or abs(height[j] - hs) > 0.25:
                        break
                    face(j, x, k, rise)
            elif not on_street[north]:
                # Higher ground (or a terrace) north: its wall on its own southern rows.
                for k in range(rise):
                    j = north - k * w
                    if j < 0 or blocked(j) or (water is not None and water[j]) or abs(height[j] - hn) > 0.25:
                        break
                    face(j, x, rise - 1 - k, rise)
        elif hs - hn >= 0.5 and not on_street[i] and not blocked(i):
            # The ground drops away north: the brink lit, the foot shaded.
            k = int(lip * 256)
            pic.scale(i, k)
            keep[i] = 1
            for d, dark in ((1, 180), (2, 212), (3, 236)):
                j = i - d * w
                if j < 0 or blocked(j):
                    break
                pic.scale(j, dark)

    # A ramp lit by its slope (exaggerated, so a gentle ramp still reads),
    # its paving's joints laid across it every `ramp_joints` units.
    gain = spec.get("slope_shade", 2.0)
    joints = spec.get("ramp_joints", 0)
    lx, ly, lz = R.kart.LX, R.kart.LY, R.kart.LZ          # the scenery's north-west sun
    flat = R.kart.AMBIENT + R.kart.DIFFUSE * lz
    for (bi, bj) in street.buckets:
        for y in range(bj * BUCKET, min(h, (bj + 1) * BUCKET)):
            row = h - 1 - y
            for x in range(bi * BUCKET, min(w, (bi + 1) * BUCKET)):
                i = row * w + x
                k = street.seg[i]
                if k < 0 or k >= course.loop or street.gap[i] > 0.5:
                    continue
                arc = street.along(i)
                slope = relief.profile.at(arc)[1]
                if slope == 0.0:
                    continue
                (ax, ay), (bx, by) = street.segs[k]
                length = sqrt((bx - ax) ** 2 + (by - ay) ** 2) or 1.0
                gx, gy = gain * slope * (bx - ax) / length, gain * slope * (by - ay) / length
                dot = (lz - gx * lx - gy * ly) / sqrt(gx * gx + gy * gy + 1.0)
                f = (R.kart.AMBIENT + R.kart.DIFFUSE * (dot if dot > 0.0 else 0.0)) / flat
                if joints and street.lane[i] <= street.road - 1.0 and arc % joints < 1.6:
                    steep = abs(slope) / 0.08
                    f *= 1.0 - 0.24 * (steep if steep < 1.0 else 1.0)
                pic.scale(i, int(f * 256 + 0.5))

    # Height's light: higher ground a little brighter, lower ground darker.
    lift = spec.get("height_light", 0.0)
    if lift:
        for i in range(n):
            v = height[i]
            if v != 0.0 and (rock is None or not rock[i]):
                pic.scale(i, int(256 * (1.0 + lift * v) + 0.5))

    # The sun's shadows: S, the highest a sun ray from each texel meets.
    strength = spec.get("shadow", 0.34)
    soft = spec.get("shadow_soft", 5.0)
    previous = list(height[0:w])
    for row in range(1, h):
        base = row * w
        here = height[base:base + w]
        current = list(here)
        reach = previous[0] - SHADOW_ROW
        for x in range(w):
            if x:
                reach = 0.75 * previous[x - 1] + 0.25 * previous[x] - SHADOW_ROW
            hx = here[x]
            if reach > hx:
                current[x] = reach
                depth = reach - hx
                if depth > 0.5:
                    i = base + x
                    if rock is None or not rock[i]:
                        pic.scale(i, int(256 * (1.0 - strength * min(1.0, depth / soft)) + 0.5))
        previous = current
    return keep


# ---------------------------------------------------------------------------
# The street surface.


class Course:
    """Where along the course a street texel is: its loop arc, whether it is
    on a bridge, its paving section, which side of the street it lies, and
    the closed-off alleys. Arcs come from the city's map-anchored layout."""

    def __init__(self, city, geometry, street):
        self.street = street
        self.loop = len(geometry["centerline"])
        self.loop_length = street.cum[self.loop - 1] + sqrt(
            (street.segs[self.loop - 1][1][0] - street.segs[self.loop - 1][0][0]) ** 2 +
            (street.segs[self.loop - 1][1][1] - street.segs[self.loop - 1][0][1]) ** 2)
        self.bridges = [(b["at"] - b["length"] / 2, b["at"] + b["length"] / 2, b) for b in city.get("bridges", [])]
        self.sections = city.get("sections", [])
        self.default = city["road_default"]
        self.alleys = []
        for a in city.get("alleys", []):
            self.alleys.append((a["at"] - a["width"] / 2, a["at"] + a["width"] / 2, a["side"], a))

    def arc(self, i):
        """(loop arc or None for a branch, branch number) of texel i's nearest road point."""
        k = self.street.seg[i]
        if k < 0:
            return None, 0
        if k < self.loop:
            return self.street.along(i), 0
        return None, 1

    def side(self, i, x, y):
        street = self.street
        k = street.seg[i]
        (ax, ay), (bx, by) = street.segs[k]
        t = street.at[i]
        cross = (bx - ax) * (y + 0.5 - (ay + (by - ay) * t)) - (by - ay) * (x + 0.5 - (ax + (bx - ax) * t))
        return "left" if cross > 0 else "right"

    def bridge(self, arc):
        if arc is None:
            return None
        for lo, hi, b in self.bridges:
            if lo <= arc <= hi:
                return b
        return None

    def road(self, arc, branch):
        for s in self.sections:
            if branch and s.get("branch") == branch:
                return s["road"]
            if arc is not None and "from" in s and _within(arc, s["from"], s["to"], self.loop_length):
                return s["road"]
        return self.default

    def alley(self, arc, side):
        if arc is None:
            return None
        for lo, hi, s, a in self.alleys:
            if s == side and lo <= arc <= hi:
                return a
        return None


def _within(arc, lo, hi, total):
    if lo <= hi:
        return lo <= arc <= hi
    return arc >= lo or arc <= hi            # wraps past the loop's start


def deck_color(arc, offset, seed, style=None, palette=None):
    """A bridge deck: stone slabs laid across the street (`palette`: the
    stone's colour), or for `style` "planks" timber boards across it, their
    ends staggered (`palette`: the wood's colour)."""
    if style == "planks":
        board = int(arc // 9)
        along = arc % 9
        across = offset + 400.0 + (board % 3) * 23
        grain = hash32(board, int(across // 64), seed) % 21 - 10
        wr, wg, wb = palette or (104, 72, 44)
        r, g, b = wr + grain, wg + grain * 3 // 4, wb + grain // 2
        if along < 1.5:
            r, g, b = r * 2 // 5, g * 2 // 5, b * 2 // 5          # the gap between boards
        elif across % 64 < 1.3:
            r, g, b = r * 3 // 5, g * 3 // 5, b * 3 // 5          # a board's end
        return r, g, b
    slab = int(arc // 20)
    along = arc % 20
    across = offset + 400.0 + (slab % 2) * 13
    vary = hash32(slab, int(across // 26), seed) % 21 - 10
    sr, sg, sb = palette or (196, 186, 166)
    r, g, b = sr + vary, sg + vary, sb + vary
    if along < 1.3 or across % 26 < 1.3:
        r, g, b = r * 3 // 4, g * 3 // 4, b * 3 // 4
    return r, g, b


def paint_street(pic, city, geometry, street, tiles, course):
    """Pave every texel inside the street: each district's road paving with a
    stone kerb and pavement to the walls, bridge decks over the canals,
    plazas, the walls' shadows and the finish line."""
    w, h = pic.w, pic.h
    road = street.road
    curb, joint = city["curb_color"], city["gutter_color"]
    sun_x, sun_y = -0.6, 0.8         # toward the sun (north-west): walls there shade the street
    for (bi, bj) in sorted(street.buckets):
        for y in range(bj * BUCKET, min(h, (bj + 1) * BUCKET)):
            row = h - 1 - y
            for x in range(bi * BUCKET, min(w, (bi + 1) * BUCKET)):
                i = row * w + x
                gap = street.gap[i]
                if gap > 0.5:
                    continue
                lane = street.lane[i]
                arc, branch = course.arc(i)
                deck = course.bridge(arc) if not street.plaza[i] else None
                if deck is not None:
                    offset = lane if course.side(i, x, y) == "left" else -lane
                    style = deck.get("deck")
                    r, g, b = deck_color(arc, offset, 31, style,
                                         city.get("deck_planks" if style == "planks" else "deck_stone"))
                elif street.plaza[i] and lane <= road - 1.0:
                    tile, shade = course.road(arc, branch)
                    r, g, b, _ = tiles.whole(tile, x, y, shade=shade)
                elif street.plaza[i] and lane <= road + 1.5:
                    r, g, b = city["gutter_color"]
                elif street.plaza[i]:
                    r, g, b, _ = tiles.whole(city["plaza_tile"], x, y, seed=5, shade=city.get("plaza_shade", 1.0))
                    k = 256
                    for cx, cy, radius, width in city.get("plaza_rings", ()):
                        d = abs(sqrt((x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2) - radius)
                        if d < width / 2:
                            k = 200 if d < width / 2 - 1 else 236
                    if -10.0 < gap <= -4.0:          # the square's darker border
                        k = min(k, 212)
                    r, g, b = r * k >> 8, g * k >> 8, b * k >> 8
                elif lane <= road - 1.0:
                    tile, shade = course.road(arc, branch)
                    r, g, b, _ = tiles.whole(tile, x, y, shade=shade)
                elif lane <= road + 1.0:
                    r, g, b = curb
                elif lane <= road + 2.5:
                    r, g, b = joint
                else:
                    r, g, b, _ = tiles.whole(city["sidewalk_tile"], x, y, seed=9,
                                             shade=city.get("sidewalk_shade", 1.0))
                # Shade under the walls between the street and the sun.
                facing = street.nx[i] * sun_x + street.ny[i] * sun_y
                if gap > -7.0 and facing > 0.2:
                    k = int(256 * (0.70 + 0.30 * (-gap) / 7.0))
                    r, g, b = r * k >> 8, g * k >> 8, b * k >> 8
                cover = 255 if gap <= -0.5 else int((0.5 - gap) * 255 + 0.5)
                pic.over(i, r, g, b, cover)
    finish = geometry["gates"][-1]
    paint_line(pic, street, finish, 8, ((28, 28, 28), (232, 232, 232)), 16)


def paint_alleys(pic, city, street, course, tiles, taken):
    """Side streets closed off for the race: paving out between the houses,
    kept clear of buildings."""
    w, h = pic.w, pic.h
    edge = street.wall + street.kart + city["wall"]["thickness"]
    for a in city.get("alleys", []):
        px, py, tx, ty = course_point(street, a["at"])
        nx, ny = (-ty, tx) if a["side"] == "left" else (ty, -tx)
        half = a["width"] / 2
        near, far = edge - 2, edge + a["length"]
        corners = [(px + tx * half + nx * near, py + ty * half + ny * near),
                   (px - tx * half + nx * near, py - ty * half + ny * near),
                   (px - tx * half + nx * far, py - ty * half + ny * far),
                   (px + tx * half + nx * far, py + ty * half + ny * far)]
        mask = bytearray(w * h)
        fill_polygon(mask, w, h, corners)
        tile, shade = course.road(a["at"], 0)
        for i in range(w * h):
            if not mask[i] or street.gap[i] <= city["wall"]["thickness"] + 0.5:
                continue
            row, x = divmod(i, w)
            y = h - 1 - row
            # Distance across the alley from its middle line: a kerb each side.
            across = abs((x + 0.5 - px) * tx + (y + 0.5 - py) * ty)
            if across > half - 8:
                r, g, b, _ = tiles.whole(city["sidewalk_tile"], x, y, seed=9, shade=city.get("sidewalk_shade", 1.0))
                if across <= half - 6:
                    r, g, b = city["curb_color"]
            else:
                r, g, b, _ = tiles.whole(tile, x, y, shade=shade)
            pic.r[i], pic.g[i], pic.b[i] = r, g, b
            taken[i] = 1


STEP_STONE = (232, 226, 212)      # treads in the sun
STEP_RISER = (176, 170, 158)      # risers face south, away from the sun
CARPET, CARPET_RISER, CARPET_EDGE = (36, 70, 156), (26, 50, 116), (214, 172, 72)


def paint_steps(pic, city, street, taken):
    """A grand stair from the street's edge up to a landmark's doors: pale
    treads and shaded risers across it, a carpet with gold edges up the
    middle, stone cheeks at both sides. The stair runs on under the
    landmark's front (`under` units), which hides its top. Returns the
    stair's texels: no wall is built in front of it and no model stands on
    its visible part."""
    w, h = pic.w, pic.h
    mask = bytearray(w * h)
    edge = street.wall + street.kart
    for spec in city.get("steps", []):
        px, py, tx, ty = course_point(street, spec["at"])
        nx, ny = (-ty, tx) if spec["side"] == "left" else (ty, -tx)
        half, depth, carpet = spec["width"] / 2, spec["depth"], spec["carpet"] / 2
        tread, under = spec.get("tread", 6), spec.get("under", 16)
        reach = int(edge + depth + under + half + 4)
        for y in range(int(py - reach), int(py + reach) + 1):
            for x in range(int(px - reach), int(px + reach) + 1):
                if not (0 <= x < w and 0 <= y < h):
                    continue
                dx, dy = x + 0.5 - px, y + 0.5 - py
                across = dx * tx + dy * ty
                out = dx * nx + dy * ny
                i = (h - 1 - y) * w + x
                gap = street.gap[i]
                if abs(across) > half or out < edge - 2 or gap > depth + under or gap <= -0.5:
                    continue
                mask[i] = 1
                if gap <= depth + 1.0:
                    taken[i] = 1
                rise = (gap if gap > 0.0 else 0.0) % tread
                riser = rise < 2.0
                if abs(across) > half - 5:                       # the cheeks
                    r, g, b = (206, 200, 186) if abs(across) <= half - 1 else (150, 144, 132)
                elif abs(across) <= carpet:
                    r, g, b = CARPET_RISER if riser else CARPET
                elif abs(across) <= carpet + 2:
                    r, g, b = CARPET_EDGE
                else:
                    r, g, b = STEP_RISER if riser else STEP_STONE
                    v = hash32(int(across // 9), int(gap // tread), 61) % 13 - 6
                    r, g, b = r + v, g + v, b + v
                cover = 255 if gap > 0.5 else int((gap + 0.5) * 255)
                pic.over(i, r, g, b, cover)
    return mask


def paint_squares(pic, city, street, tiles):
    """Open squares beside the street, outside its walls: marble paving, a
    darker border and inlaid rings. Returns their texels."""
    w, h = pic.w, pic.h
    mask = bytearray(w * h)
    for square in city.get("squares", []):
        own = bytearray(w * h)
        fill_polygon(own, w, h, square["shape"])
        outside = bytearray(1 if not v else 0 for v in own)
        border = dilate(outside, w, h, 6)
        for i in range(w * h):
            if not own[i] or street.gap[i] <= 0.5:
                continue
            mask[i] = 1
            row, x = divmod(i, w)
            y = h - 1 - row
            r, g, b, _ = tiles.whole(city["plaza_tile"], x, y, seed=5, shade=city.get("plaza_shade", 1.0))
            k = 256
            for cx, cy, radius, width in square.get("rings", ()):
                d = abs(sqrt((x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2) - radius)
                if d < width / 2:
                    k = 200 if d < width / 2 - 1 else 236
            if border[i]:
                k = min(k, 212)
            pic.r[i], pic.g[i], pic.b[i] = r * k >> 8, g * k >> 8, b * k >> 8
    return mask


def paint_line(pic, street, gate, cells, colors, thickness):
    """A chequered band across the road along an axis-aligned gate."""
    w, h = pic.w, pic.h
    horizontal = gate["ay"] == gate["by"]
    lo = int(min(gate["ax"], gate["bx"])) if horizontal else int(min(gate["ay"], gate["by"]))
    hi = int(max(gate["ax"], gate["bx"])) if horizontal else int(max(gate["ay"], gate["by"]))
    mid = gate["ay"] if horizontal else gate["ax"]
    for a in range(lo, hi + 1):
        for b in range(int(mid - thickness / 2), int(mid + thickness / 2)):
            x, y = (a, b) if horizontal else (b, a)
            if not (0 <= x < w and 0 <= y < h):
                continue
            i = street.index(x, y)
            if street.lane[i] > street.road - 3:
                continue
            dark = ((a // cells) + ((b - int(mid - thickness / 2)) // cells)) % 2
            pic.r[i], pic.g[i], pic.b[i] = colors[0] if dark else colors[1]


# ---------------------------------------------------------------------------
# Scenery with height: walls and models, painted north to south.


def wall_columns(city, street, course, water, steps=None, squares=None, rock=None, lava=None):
    """The street's edge walls, by what lies beyond them: a stone parapet
    over a canal or along an open square, a forge's dark iron wall over lava,
    crenellated parapets on a bridge, a hedge along the Park, a timber
    barrier across a closed alley, low house foundations elsewhere, nothing
    at the foot of a grand stair. Per world row, the texels of each wall's
    footprint just outside the karts' reach, with each column's height and
    style."""
    w, h = street.w, street.h
    thick = city["wall"]["thickness"]
    rows = {}
    for (bi, bj) in street.buckets:
        for y in range(bj * BUCKET, min(h, (bj + 1) * BUCKET)):
            row = h - 1 - y
            for x in range(bi * BUCKET, min(w, (bi + 1) * BUCKET)):
                i = row * w + x
                gap = street.gap[i]
                if not (0.5 < gap <= thick + 0.5):
                    continue
                if steps is not None and steps[i]:
                    continue
                if rock is not None and rock[i]:
                    continue                                 # the rock's face is the wall
                arc, branch = course.arc(i)
                along = street.along(i) if street.seg[i] >= 0 else 0.0
                px = int(x + street.nx[i] * 5)
                py = int(y + street.ny[i] * 5)
                wet = 0 <= px < w and 0 <= py < h and water[(h - 1 - py) * w + px]
                square = (squares is not None and 0 <= px < w and 0 <= py < h and
                          squares[(h - 1 - py) * w + px])
                side = course.side(i, x, y) if street.seg[i] >= 0 else "left"
                deck = course.bridge(arc)
                if deck is not None and deck.get("deck") == "planks":
                    style = "rail"                           # timber posts and a rail between
                    height = 14 if along % city.get("pile_every", 30) < 3 else 7
                elif deck is not None:
                    style = "bridge"
                    height = 15 if along % 14 < 8 else 10
                elif lava is not None and 0 <= px < w and 0 <= py < h and lava[(h - 1 - py) * w + px]:
                    style = "lava"
                    height = city["lava"].get("rim_height", 10)
                elif wet or square:
                    style = "parapet"
                    height = 13 if along % 48 < 6 else 9
                elif course.alley(arc, side) is not None:
                    style = "barrier"
                    height = 9
                elif district_at(city, x, y)["name"] in city.get("hedged", ()):
                    style = "hedge"
                    height = 9 + hash32(x // 3, y // 3, 41) % 4
                elif city.get("land_wall"):
                    # A city's own street wall (Orgrimmar's timber palisade),
                    # with a taller spike every `spike_every` units along it.
                    land = city["land_wall"]
                    style, height = land["style"], land["height"]
                    if land.get("spike_every") and along % land["spike_every"] < land.get("spike_width", 1.5):
                        style, height = "spike", land["spike_height"]
                else:
                    style = "land"
                    height = 5
                rows.setdefault(y, []).append((x, height, style))
    return rows


WALL_STYLES = {   # face, coping, foot
    "parapet": ((176, 170, 156), (228, 222, 208), (98, 94, 88)),
    "bridge": ((188, 180, 162), (234, 228, 212), (104, 98, 90)),
    "land": ((122, 114, 102), (156, 148, 134), (78, 74, 68)),
    "barrier": ((112, 78, 46), (150, 110, 70), (64, 46, 30)),
    "hedge": ((44, 92, 40), (70, 126, 58), (30, 60, 28)),
    "lava": ((52, 38, 32), (84, 62, 50), (28, 20, 18)),
    "palisade": ((112, 74, 46), (150, 106, 68), (58, 38, 24)),
    "spike": ((70, 60, 52), (196, 184, 160), (42, 36, 32)),
    "rail": ((96, 66, 40), (138, 100, 62), (52, 36, 22)),
}


def paint_wall_row(pic, city, y, columns):
    """One world row of wall columns: a face rising lean x height from the
    ground point, the coping lighter on top."""
    w, h = pic.w, pic.h
    lean = city["lean"]
    styles = city.get("wall_styles", {})
    for x, height, style in columns:
        face, cap, dark = styles.get(style) or WALL_STYLES[style]
        rise = int(lean * height + 0.5)
        base = h - 1 - y
        for k in range(rise + 1):
            row = base - k
            if row < 0:
                break
            if style == "rail" and height < 10 and 0 < k < rise - 1:
                continue                                      # the deck shows between a railing's rails
            i = row * w + x
            if k >= rise - 1:
                r, g, b = cap
            elif k == 0:
                r, g, b = dark
            else:
                r, g, b = face
                if style == "barrier" and x % 5 == 0:
                    r, g, b = dark
                elif style == "lava":
                    if x % 9 == 0 or k == rise // 2:              # the iron plates' seams
                        r, g, b = r * 3 // 4, g * 3 // 4, b * 3 // 4
                elif style == "hedge":
                    v = hash32(x, row, 43) % 24
                    r, g, b = r + v // 2, g + v, b + v // 3
                elif style == "palisade":
                    if x % 4 == 0:                                # the stakes' seams
                        r, g, b = r * 3 // 4, g * 3 // 4, b * 3 // 4
                elif style == "spike":
                    pass
                elif k == rise // 2 and (x // 6) % 2 == 0:
                    r, g, b = r * 7 // 8, g * 7 // 8, b * 7 // 8
            pic.r[i], pic.g[i], pic.b[i] = r, g, b


def sprite_for(wc3, city, item, cache):
    key = ("sprite-v3", item["model"], item["sequence"], item["yaw"], item["scale"], item.get("tint"),
           tuple(item.get("recolor") or ()), item.get("team"), city["lean"], city.get("supersample", 3),
           tuple(sorted((city.get("replaceables") or {}).items())), item.get("team") or city["team"])
    if item.get("stone"):
        key += (("stone", tuple(item["stone"])),)
    if item.get("cut") is not None:
        key += (("cut", item["cut"]),)
    if item.get("alpha_shadow"):
        key += (("alpha_shadow", True),)
    if key not in cache:
        mesh = item.get("mesh")
        sprite = None if mesh else _disk_cache(key)     # meshes are quick to draw: never cached on disk
        if sprite is None:
            if mesh:
                loaded, triangles = M.build(mesh, item["yaw"], item["scale"], wc3)
            else:
                loaded = R.load(wc3, item["model"], team=item.get("team") or city["team"],
                                replaceables=city.get("replaceables"))
                triangles = R.posed(loaded, item["sequence"], item["scale"], item["yaw"])
                if item.get("cut") is not None:
                    # Drop the ground patch some doodads carry (a Barrens rock's
                    # square of dirt): triangles lying wholly this low.
                    triangles = [t for t in triangles if max(p[2] for p in t[0]) > item["cut"]]
            files = loaded[0].get("texture_files", [])
            if not triangles:
                raise SystemExit(f"LAYOUT: {item['model']} has nothing this renderer can draw")
            sprite = R.render(loaded, triangles, ss=city.get("supersample", 3), lean=city["lean"],
                              tint=item.get("tint") or (1.0, 1.0, 1.0), recolor=item.get("recolor"),
                              stone=item.get("stone"), alpha_shadow=item.get("alpha_shadow", False))
            sprite["textures"] = sorted(set(files))
            # Samples for placement tests: body texels and plan texels.
            sprite["body_points"] = [(i, j) for j, line in enumerate(sprite["body"]) for i, a in enumerate(line)
                                     if a > 40]
            left, bottom, pw, ph, mask = sprite["plan"]
            sprite["plan_points"] = [(left + c, bottom + (ph - 1 - r)) for r in range(ph) for c in range(pw)
                                     if mask[r * pw + c]]
            if not mesh:
                _disk_cache(key, sprite)
        cache[key] = sprite
    return cache[key]


def _disk_cache(key, value=None):
    """Optional development cache of rendered sprites (CITY_SPRITE_CACHE=folder);
    rendering is deterministic, so cached and fresh sprites are identical."""
    import os
    import pickle
    folder = os.environ.get("CITY_SPRITE_CACHE")
    if not folder:
        return None
    path = Path(folder) / (hashlib.sha256(repr(key).encode()).hexdigest() + ".pickle")
    if value is None:
        return pickle.loads(path.read_bytes()) if path.is_file() else None
    path.parent.mkdir(parents=True, exist_ok=True)
    partial = path.with_name(path.name + ".part")     # an interrupted build leaves no torn entry
    partial.write_bytes(pickle.dumps(value, protocol=4))
    os.replace(partial, path)
    return value


def body_clear(street, sprite, X, Y, step=1):
    """True when no body texel of the sprite at world origin (X, Y) falls inside
    the street (gap <= 1)."""
    w, h = street.w, street.h
    col0, row0 = X - sprite["ox"], h - Y - sprite["oy"]
    points = sprite["body_points"]
    for k in range(0, len(points), step):
        i, j = points[k]
        c, r = col0 + i, row0 + j
        if 0 <= c < w and 0 <= r < h and street.gap[r * w + c] <= 1.0:
            return False
    return True


def plan_clear(street, water, taken, sprite, X, Y, margin, wet=False, step=1):
    """True when the model's plan at (X, Y) stays `margin` outside the street,
    off water (unless `wet`), off other models and inside the picture."""
    w, h = street.w, street.h
    points = sprite["plan_points"]
    for k in range(0, len(points), step):
        dx, dy = points[k]
        x, y = X + dx, Y + dy
        if not (0 <= x < w and 0 <= y < h):
            return False
        i = (h - 1 - y) * w + x
        if street.gap[i] <= margin or taken[i] or (water[i] and not wet):
            return False
    return True


def take(street, taken, sprite, X, Y, spacing):
    w, h = street.w, street.h
    for dx, dy in sprite["plan_points"]:
        for ex in range(-spacing, spacing + 1, max(1, spacing)):
            for ey in range(-spacing, spacing + 1, max(1, spacing)):
                x, y = X + dx + ex, Y + dy + ey
                if 0 <= x < w and 0 <= y < h:
                    taken[(h - 1 - y) * w + x] = 1


def paint_sprite(pic, sprite, X, Y):
    col0 = X - sprite["ox"]
    row0 = pic.h - Y - sprite["oy"]
    for j, line in enumerate(sprite["pixels"]):
        row = row0 + j
        if row < 0 or row >= pic.h:
            continue
        base = row * pic.w
        for i, (r, g, b, a) in enumerate(line):
            if a:
                c = col0 + i
                if 0 <= c < pic.w:
                    pic.over(base + c, r, g, b, a)


def front_of(street, water, taken, sprite, front):
    """Where a model stands facing the street at loop arc front["at"]: out
    from that course point on front["side"] (shifted front["across"] along
    the street) until its plan keeps front["gap"] clear of the street, or
    exactly front["out"] units out (on a stair, say)."""
    px, py, tx, ty = course_point(street, front["at"])
    nx, ny = (-ty, tx) if front["side"] == "left" else (ty, -tx)
    shift = front.get("across", 0.0)
    if "out" in front:
        return (int(floor(px + tx * shift + nx * front["out"] + 0.5)),
                int(floor(py + ty * shift + ny * front["out"] + 0.5)))
    for out in range(int(street.wall + street.kart), int(street.wall + street.kart) + 400):
        X = int(floor(px + tx * shift + nx * out + 0.5))
        Y = int(floor(py + ty * shift + ny * out + 0.5))
        if plan_clear(street, water, taken, sprite, X, Y, front["gap"]) and body_clear(street, sprite, X, Y):
            return X, Y
    raise SystemExit(f"LAYOUT: no room for a model facing the street at arc {front['at']}")


def place_landmarks(wc3, city, street, water, taken, cache):
    """The city's authored models; each must keep its body off the street."""
    placed, problems = [], []
    for item in city["props"]:
        sprite = sprite_for(wc3, city, item, cache)
        X, Y = int(floor(item["x"] + 0.5)), int(floor(item["y"] + 0.5))
        if item.get("front"):
            X, Y = front_of(street, water, taken, sprite, item["front"])
            item = dict(item, x=X, y=Y)
        if item.get("nudge") and not body_clear(street, sprite, X, Y):
            # Step away from the street until the model's body clears it.
            _, nx, ny = street.nearest(X + 0.5, Y + 0.5)
            for push in range(4, 120, 4):
                QX, QY = int(floor(X + nx * push + 0.5)), int(floor(Y + ny * push + 0.5))
                if body_clear(street, sprite, QX, QY):
                    X, Y = QX, QY
                    break
        if not item["solid"] and not body_clear(street, sprite, X, Y):
            problems.append(f"{item['name']} at ({X}, {Y}) covers the street")
            continue
        take(street, taken, sprite, X, Y, 2)
        placed.append((item, sprite, X, Y))
    if problems:
        raise SystemExit("LAYOUT: " + "; ".join(problems))
    return placed


def generate_buildings(wc3, city, street, water, taken, cache, fill=None, key="buildings"):
    """Fill each district's land near the course with its buildings: candidate
    points on a jittered grid, nearest the street first; each takes the first
    of its district's models (in a hashed order) that fits, turned to face the
    street. Deterministic: every choice is a hash of the candidate's cell."""
    fill = fill or city["fill"]
    step, reach, gap = fill["step"], fill["reach"], fill["gap"]
    w, h = street.w, street.h
    candidates = []
    for gy in range(step // 2, h, step):
        for gx in range(step // 2, w, step):
            jx = gx + hash32(gx, gy, 21) % (step // 2) - step // 4
            jy = gy + hash32(gx, gy, 22) % (step // 2) - step // 4
            if not (0 <= jx < w and 0 <= jy < h):
                continue
            i = street.index(jx, jy)
            if water[i] or taken[i]:
                continue
            g, nx, ny = street.nearest(jx + 0.5, jy + 0.5)
            if g <= gap or g > reach:
                continue
            candidates.append((g, hash32(jx, jy, 23), jx, jy, nx, ny))
    candidates.sort()
    placed = []
    counts = {}
    for g, salt, X, Y, nx, ny in candidates:
        if taken[street.index(X, Y)]:
            continue
        district = district_at(city, X, Y)
        palette = district.get(key) or []
        if not palette:
            continue
        density = district.get("density", {}).get(key)
        if density is not None and hash32(X, Y, 25) % 1000 >= density * 1000:
            continue                       # a sparser district leaves this spot open
        facing = atan2(-ny, -nx) * 180.0 / pi
        yaw = int(floor(facing / 45.0 + 0.5)) * 45 % 360
        order = sorted(range(len(palette)),
                       key=lambda k: hash32(salt, k, 24) / palette[k].get("weight", 1.0))
        for k in order:
            entry = palette[k]
            if g > entry.get("reach", reach):
                continue
            if entry.get("limit") is not None and counts.get((district["name"], key, k), 0) >= entry["limit"]:
                continue
            yaws = entry.get("yaws")
            turned = yaw if yaws is None else min(yaws, key=lambda a: min((a - yaw) % 360, (yaw - a) % 360))
            item = dict(entry["prop"], x=X, y=Y, yaw=turned)
            if district.get("tint") and not item.get("tint"):
                item["tint"] = district["tint"]
            if district.get("recolor") and not item.get("recolor"):
                item["recolor"] = district["recolor"]
            sprite = sprite_for(wc3, city, item, cache)
            if not plan_clear(street, water, taken, sprite, X, Y, gap, step=3):
                continue
            if not body_clear(street, sprite, X, Y, step=3):
                continue
            if not plan_clear(street, water, taken, sprite, X, Y, gap) or not body_clear(street, sprite, X, Y):
                continue
            take(street, taken, sprite, X, Y, fill.get("spacing", 3))
            placed.append((item, sprite, X, Y))
            counts[(district["name"], key, k)] = counts.get((district["name"], key, k), 0) + 1
            break
    return placed


def street_furniture(wc3, city, street, water, taken, cache):
    """Lamps and banners just outside the walls at regular intervals along
    the course, alternating sides; a spot whose model would cover the street
    or meet another model is skipped."""
    placed = []
    for spec in city.get("furniture", []):
        every, offset = spec["every"], spec["offset"]
        total = street.cum[-1] + 1.0
        s = spec.get("start", 0.0)
        side = 1
        while s < total:
            k = max(0, min(len(street.segs) - 1, _segment_at(street, s)))
            (ax, ay), (bx, by) = street.segs[k]
            length = sqrt((bx - ax) ** 2 + (by - ay) ** 2) or 1.0
            t = (s - street.cum[k]) / length
            px, py = ax + (bx - ax) * t, ay + (by - ay) * t
            nx, ny = -(by - ay) / length * side, (bx - ax) / length * side
            dist = street.wall + street.kart + offset
            X, Y = int(floor(px + nx * dist + 0.5)), int(floor(py + ny * dist + 0.5))
            side = -side if spec.get("alternate", True) else side
            s += every
            if not (0 <= X < street.w and 0 <= Y < street.h):
                continue
            i = street.index(X, Y)
            if street.gap[i] <= 0.5:
                continue
            outside_water = water[i]
            if spec.get("where") == "water" and not outside_water:
                continue
            if spec.get("where") == "land" and outside_water:
                continue
            item = dict(spec["prop"], x=X, y=Y)
            sprite = sprite_for(wc3, city, item, cache)
            if not body_clear(street, sprite, X, Y):
                continue
            if not plan_clear(street, water, taken, sprite, X, Y, 0.5, wet=True):
                continue
            take(street, taken, sprite, X, Y, 1)
            placed.append((item, sprite, X, Y))
    return placed


def bridge_furniture(wc3, city, street, water, taken, cache):
    """A lamp at each corner of every bridge, just outside its parapets (a
    bridge's own `posts` instead of the city's `bridge_posts`)."""
    placed = []
    for b in city.get("bridges", []):
        spec = b.get("posts", city.get("bridge_posts"))
        if not spec:
            continue
        edge = street.wall + street.kart + city["wall"]["thickness"] + spec["offset"]
        for end in (-1, 1):
            px, py, tx, ty = course_point(street, b["at"] + end * (b["length"] / 2 - spec["inset"]))
            for side in (-1, 1):
                X = int(floor(px - ty * side * edge + 0.5))
                Y = int(floor(py + tx * side * edge + 0.5))
                item = dict(spec["prop"], x=X, y=Y)
                sprite = sprite_for(wc3, city, item, cache)
                for push in range(0, 40, 3):          # out from the street until clear
                    QX = int(floor(X - ty * side * push + 0.5))
                    QY = int(floor(Y + tx * side * push + 0.5))
                    if body_clear(street, sprite, QX, QY):
                        take(street, taken, sprite, QX, QY, 1)
                        placed.append((dict(item, x=QX, y=QY), sprite, QX, QY))
                        break
    guard = city.get("bridge_guards")
    if guard:
        edge = street.wall + street.kart + city["wall"]["thickness"] + guard["offset"]
        for b in city.get("bridges", []):
            for end in (-1, 1):
                px, py, tx, ty = course_point(street, b["at"] + end * (b["length"] / 2 + guard["beyond"]))
                for side in (-1, 1):
                    nx, ny = -ty * side, tx * side
                    yaw = int(floor(atan2(-ny, -nx) * 180.0 / pi / 45.0 + 0.5)) * 45 % 360
                    item = dict(guard["prop"], yaw=yaw)
                    sprite = sprite_for(wc3, city, item, cache)
                    for push in range(0, 40, 3):
                        QX = int(floor(px + nx * (edge + push) + 0.5))
                        QY = int(floor(py + ny * (edge + push) + 0.5))
                        if body_clear(street, sprite, QX, QY) and plan_clear(street, water, taken, sprite, QX, QY,
                                                                              0.5):
                            take(street, taken, sprite, QX, QY, 2)
                            placed.append((dict(item, x=QX, y=QY), sprite, QX, QY))
                            break
    return placed


def _segment_at(street, s):
    lo, hi = 0, len(street.cum) - 1
    while lo < hi:
        mid = (lo + hi + 1) // 2
        if street.cum[mid] <= s:
            lo = mid
        else:
            hi = mid - 1
    return lo


def paint_scenery(pic, city, walls, models):
    """Walls and models in one north-to-south pass."""
    by_row = {}
    for item, sprite, X, Y in models:
        by_row.setdefault(Y, []).append((X, sprite))
    for y in range(pic.h - 1, -1, -1):
        if y in walls:
            paint_wall_row(pic, city, y, walls[y])
        for X, sprite in sorted(by_row.get(y, []), key=lambda e: e[0]):
            paint_sprite(pic, sprite, X, y)


# ---------------------------------------------------------------------------
# Build.


def build(wc3, city, geometry, check=False, preview=False, log=print):
    import time
    started = time.time()
    w, h = geometry["width"], geometry["height"]
    tiles = Tileset(wc3)
    kart = city["kart_clearance"]
    street = Street(geometry, kart, city["street_reach"], city["fill"]["reach"] + 40)
    if not city.get("shoulders"):
        # No shoulders on a city street (owner, 2026-10-23): the paving runs
        # out to a kerb at the foot of each wall, the karts' whole reach.
        street.road = street.wall + kart - 2.0
    log(f"  street field {time.time() - started:.0f}s")
    pic = Picture(w, h)
    paint_terrain(pic, city, tiles)
    water, bridge = water_masks(city, geometry, street)
    paint_water(pic, city, water, tiles, bridge)
    # Sunken ground under any lava in it (Ragefire Chasm in the Cleft of Shadow).
    pit = pit_mask(city, street)
    pit_keep = paint_pits(pic, city, pit, tiles) if pit is not None else None
    lava = lava_mask(city, street)
    if lava is not None:
        paint_lava(pic, city, lava, tiles)
    if city.get("rings"):
        paint_rings(pic, city, {"water": water, "lava": lava})
    if lava is not None:
        # Models keep off lava and the walls round it as off water.
        dry = city["wall"]["thickness"] + 0.5
        rimmed = dilate(lava, w, h, city["lava"].get("rim_width", 3))
        for i in range(w * h):
            if rimmed[i] and street.gap[i] <= dry:
                rimmed[i] = 0
        water = bytearray((int.from_bytes(water, "big") | int.from_bytes(rimmed, "big")).to_bytes(w * h, "big"))
    log(f"  ground and water {time.time() - started:.0f}s")
    course = Course(city, geometry, street)
    paint_street(pic, city, geometry, street, tiles, course)
    squares = paint_squares(pic, city, street, tiles)
    taken = bytearray(w * h)
    if pit_keep is not None:
        taken[:] = pit_keep          # no model on a chasm's wall or along its edges
    steps = paint_steps(pic, city, street, taken)
    paint_alleys(pic, city, street, course, tiles, taken)
    rock = rock_mask(city, street)
    if rock is not None:
        paint_rock(pic, city, rock, tiles)
        taken[:] = (int.from_bytes(taken, "big") | int.from_bytes(rock, "big")).to_bytes(w * h, "big")
    if city.get("elevation"):
        relief = Relief(city, geometry, street, course)
        walls_drawn = paint_relief(pic, city, street, course, relief, tiles, rock, water, pit)
        taken[:] = (int.from_bytes(taken, "big") | int.from_bytes(walls_drawn, "big")).to_bytes(w * h, "big")
        log(f"  elevation {time.time() - started:.0f}s")
    if lava is not None or city.get("lights"):
        paint_glow(pic, city, lava, rock)
    if city.get("water_glow"):
        paint_water_glow(pic, city, water)
    log(f"  street {time.time() - started:.0f}s")
    cache = {}
    models = place_landmarks(wc3, city, street, water, taken, cache)
    models += bridge_furniture(wc3, city, street, water, taken, cache)
    # Reserved ground (the Great Forge's floor round its anvil): no generated
    # furniture, buildings or trim; people may stand there.
    reserved = bytearray(w * h)
    for poly in city.get("reserved", []):
        fill_polygon(reserved, w, h, poly)
    held = bytes(taken)
    for i in range(w * h):
        if reserved[i]:
            taken[i] = 1
    models += street_furniture(wc3, city, street, water, taken, cache)
    log(f"  landmarks and furniture {time.time() - started:.0f}s ({len(cache)} sprites)")
    # Houses keep off the squares; benches and people may stand there.
    before = bytes(taken)
    for i in range(w * h):
        if squares[i]:
            taken[i] = 1
    models += generate_buildings(wc3, city, street, water, taken, cache)
    for i in range(w * h):
        if squares[i]:
            taken[i] = before[i]
    log(f"  buildings {time.time() - started:.0f}s ({len(models)} models, {len(cache)} sprites)")
    if city.get("trim"):
        models += generate_buildings(wc3, city, street, water, taken, cache, city["trim"], "trim")
        log(f"  trim {time.time() - started:.0f}s ({len(models)} models, {len(cache)} sprites)")
    for i in range(w * h):
        if reserved[i] and not held[i]:
            taken[i] = 0
    if city.get("people"):
        models += generate_buildings(wc3, city, street, water, taken, cache, city["people"], "people")
        log(f"  people {time.time() - started:.0f}s ({len(models)} models, {len(cache)} sprites)")
    lights = [(X + 0.5, Y + 0.5, item["light"][0], item["light"][1]) for item, sprite, X, Y in models
              if item.get("light")]
    if lights:
        paint_lights(pic, lights)
    walls = wall_columns(city, street, course, water, steps, squares, rock, lava)
    if lava is not None:
        for y, columns in lava_rims(city, lava, street, rock).items():
            walls.setdefault(y, []).extend(columns)
    paint_scenery(pic, city, walls, models)
    log(f"  painted {time.time() - started:.0f}s")
    image = pic.tga()
    preview_rows = pic.rows(4)
    outputs = [("Background.tga", image), ("Preview.tga", encode_tga(preview_rows))]
    folder = ROOT / "addon" / "AzerothKart" / "Assets" / "Tracks" / city["folder"]
    for name, data in outputs:
        output = folder / name
        relative = output.relative_to(ROOT).as_posix()
        if check:
            if not output.is_file() or output.read_bytes() != data:
                raise SystemExit(f"STALE: {relative}; run without --check")
        else:
            output.parent.mkdir(parents=True, exist_ok=True)
            output.write_bytes(data)
        log(f"{'CHECK PASS' if check else 'WROTE'}: {relative}; opaque BGRA32; {len(data)} bytes; "
            f"sha256={hashlib.sha256(data).hexdigest()}")
    if preview:
        docs = ROOT / "docs" / "art" / "tracks"
        docs.mkdir(parents=True, exist_ok=True)
        (docs / f"{city['id']}-overview.png").write_bytes(encode_png(preview_rows))
        (docs / f"{city['id']}-sources.txt").write_text(sources(wc3, city, tiles, models), encoding="utf-8",
                                                         newline="\n")
    return pic, models


def sources(wc3, city, tiles, models):
    """Every Warcraft III file the picture draws on: models with their use
    counts, then the textures they and the ground read."""
    counts, meshes = {}, {}
    for item, sprite, X, Y in models:
        if item.get("mesh"):
            meshes[item["mesh"]] = meshes.get(item["mesh"], 0) + 1
        else:
            counts[item["model"]] = counts.get(item["model"], 0) + 1
    textures = set()
    for item, sprite, X, Y in models:
        for path in sprite["textures"]:
            textures.add(path.replace("war3.w3mod/", "war3.w3mod:", 1))
    for path, _ in tiles.cache:
        textures.add(path)
    for path, _, _ in tiles.strata:
        textures.add(path)
    if not city.get("water_tile"):
        textures.add(city["water_texture"])
    lines = [f"# {city['name']}: Warcraft III Reforged files used by {city['folder']}/Background.tga",
             "# Generated by scripts/build_city_tracks.py --preview. Archive paths as the client stores them.",
             "", "## Models (placements)"]
    lines += [f"{counts[m]:4d}  {m}" for m in sorted(counts)]
    if meshes:
        lines += ["", "## Drawn by scripts/city_meshes.py (no Warcraft III file)"]
        lines += [f"{meshes[m]:4d}  {m}" for m in sorted(meshes)]
    lines += ["", "## Textures"] + sorted(textures)
    return "\n".join(lines) + "\n"
