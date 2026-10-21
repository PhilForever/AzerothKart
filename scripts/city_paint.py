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
   radius plus a kart's half-length) is paved: the road (cobbles, kerbs
   striped round corners, the chequered finish line), the rough kerb-side
   strip (sidewalk flags) and plazas (marble), with the walls' shadows.
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

import wc3render as R
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

    def cells(self, path, shade=1.0):
        if (path, shade) in self.cache:
            return self.cache[(path, shade)]
        w, h, tex = R.read_dds(R.archive_file(self.wc3, path).read_bytes())
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
            caps.append((ax, ay, bx, by, self.wall + kart, k))
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
    traced basins never leave slivers by the street. `crossings` carry a
    canal under the course: a strip across the street at a loop arc, the
    street passing over it on a bridge. The street and its walls are dry."""
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
    for c in city.get("crossings", []):
        px, py, tx, ty = course_point(street, c["at"])
        nx, ny = -ty, tx                       # left of travel
        half = c["width"] / 2
        left = street.wall + street.kart + thick + c.get("left", 0)
        right = street.wall + street.kart + thick + c.get("right", 0)
        corners = [(px + tx * half + nx * left, py + ty * half + ny * left),
                   (px - tx * half + nx * left, py - ty * half + ny * left),
                   (px - tx * half - nx * right, py - ty * half - ny * right),
                   (px + tx * half - nx * right, py + ty * half - ny * right)]
        fill_polygon(bridge, w, h, corners)
    for i in range(w * h):
        if bridge[i]:
            if street.gap[i] > thick + 0.5:
                water[i] = 1
    return water, bridge


def paint_water(pic, city, water, tiles, bridge):
    """Water texels get the tinted water texture, darker near the banks. Below
    a bank that faces the camera (land or street just north) the stone quay
    face shows, then the bank's shadow on the water; every bank has a rim.
    Below a bridge the face is deeper and pierced by arches."""
    w, h = pic.w, pic.h
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
    for i in range(w * h):
        if not water[i]:
            continue
        row, c = divmod(i, w)
        k = up[i]
        if bridge[i] and k < span and row - k - 1 >= 0:
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
        if k < depth and row - k - 1 >= 0:
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
        tx, ty = (c * 2) % tex_w, (row * 2) % tex_h
        acc0 = acc1 = acc2 = 0.0
        for dy in (0, 1):
            for dx in (0, 1):
                t = tex[((ty + dy) % tex_h) * tex_w + (tx + dx) % tex_w]
                acc0 += t[0]
                acc1 += t[1]
                acc2 += t[2]
        light = (acc0 + acc1 + acc2) / 12.0
        shade = 0.70 + 0.30 * near[i] / 12.0              # darker along the banks
        if k < depth + 7 and row - k - 1 >= 0:
            shade *= 0.62                                  # the bank's shadow
        pic.r[i] = min(255, int((tint[0] * 0.75 + light * 0.225) * shade * 255 + 0.5))
        pic.g[i] = min(255, int((tint[1] * 0.75 + light * 0.25) * shade * 255 + 0.5))
        pic.b[i] = min(255, int((tint[2] * 0.75 + light * 0.275) * shade * 255 + 0.5))
    # The rim: dry texels within two of the water, light stone.
    edge = dilate(water, w, h, 2)
    for i in range(w * h):
        if edge[i] and not water[i]:
            pic.r[i], pic.g[i], pic.b[i] = rim


# ---------------------------------------------------------------------------
# The street surface.


def paint_street(pic, city, geometry, street, tiles):
    """Pave every texel inside the street: road, kerbs, sidewalks, plazas, the
    walls' shadows and the finish line."""
    w, h = pic.w, pic.h
    road = street.road
    kerb_a, kerb_b, edge = city["kerb_colors"]
    gutter = city["gutter_color"]
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
                if lane <= road + 0.5:
                    r, g, b, _ = tiles.whole(city["road_tile"], x, y, shade=city.get("road_shade", 1.0))
                    if road - lane < 4.5:
                        k_seg = street.seg[i]
                        if abs(street.turn[k_seg]) > 0.10:
                            r, g, b = kerb_a if int(street.along(i) // 14) % 2 else kerb_b
                        else:
                            r, g, b = edge
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
                else:
                    r, g, b, _ = tiles.whole(city["sidewalk_tile"], x, y, seed=9,
                                             shade=city.get("sidewalk_shade", 1.0))
                    if lane <= road + 2.5:
                        r, g, b = gutter
                # Shade under the walls between the street and the sun.
                facing = street.nx[i] * sun_x + street.ny[i] * sun_y
                if gap > -7.0 and facing > 0.2:
                    k = int(256 * (0.70 + 0.30 * (-gap) / 7.0))
                    r, g, b = r * k >> 8, g * k >> 8, b * k >> 8
                cover = 255 if gap <= -0.5 else int((0.5 - gap) * 255 + 0.5)
                pic.over(i, r, g, b, cover)
    finish = geometry["gates"][-1]
    paint_line(pic, street, finish, 8, ((28, 28, 28), (232, 232, 232)), 16)


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


def wall_columns(city, street):
    """The balustrade along both street edges: per world row, the texels of
    its footprint (just outside the karts' reach) with each column's height."""
    w, h = street.w, street.h
    thick = city["wall"]["thickness"]
    low, high, every = city["wall"]["height"], city["wall"]["pillar_height"], city["wall"]["pillar_every"]
    rows = {}
    for (bi, bj) in street.buckets:
        for y in range(bj * BUCKET, min(h, (bj + 1) * BUCKET)):
            row = h - 1 - y
            for x in range(bi * BUCKET, min(w, (bi + 1) * BUCKET)):
                i = row * w + x
                gap = street.gap[i]
                if not (0.5 < gap <= thick + 0.5):
                    continue
                pillar = street.seg[i] >= 0 and street.along(i) % every < 6.0
                rows.setdefault(y, []).append((x, high if pillar else low, pillar))
    return rows


def paint_wall_row(pic, city, y, columns):
    """One world row of balustrade columns: a stone face rising lean x height
    from the ground point, the coping lighter on top."""
    w, h = pic.w, pic.h
    lean = city["lean"]
    face, cap, dark = city["wall"]["face"], city["wall"]["cap"], city["wall"]["shadow"]
    for x, height, pillar in columns:
        rise = int(lean * height + 0.5)
        base = h - 1 - y
        for k in range(rise + 1):
            row = base - k
            if row < 0:
                break
            i = row * w + x
            if k >= rise - 1:
                r, g, b = cap
            elif k == 0:
                r, g, b = dark
            else:
                r, g, b = face
                if pillar:
                    r, g, b = min(255, r + 14), min(255, g + 14), min(255, b + 12)
                elif (k == rise // 2 and (x // 6) % 2 == 0):
                    r, g, b = r * 7 // 8, g * 7 // 8, b * 7 // 8
            pic.r[i], pic.g[i], pic.b[i] = r, g, b


def sprite_for(wc3, city, item, cache):
    key = ("sprite-v2", item["model"], item["sequence"], item["yaw"], item["scale"], item.get("tint"),
           tuple(item.get("recolor") or ()), item.get("team"), city["lean"], city.get("supersample", 3),
           tuple(sorted((city.get("replaceables") or {}).items())), item.get("team") or city["team"])
    if key not in cache:
        sprite = _disk_cache(key)
        if sprite is None:
            loaded = R.load(wc3, item["model"], team=item.get("team") or city["team"],
                            replaceables=city.get("replaceables"))
            triangles = R.posed(loaded, item["sequence"], item["scale"], item["yaw"])
            files = loaded[0].get("texture_files", [])
            if not triangles:
                raise SystemExit(f"LAYOUT: {item['model']} has nothing this renderer can draw")
            sprite = R.render(loaded, triangles, ss=city.get("supersample", 3), lean=city["lean"],
                              tint=item.get("tint") or (1.0, 1.0, 1.0), recolor=item.get("recolor"))
            sprite["textures"] = sorted(set(files))
            # Samples for placement tests: body texels and plan texels.
            sprite["body_points"] = [(i, j) for j, line in enumerate(sprite["body"]) for i, a in enumerate(line)
                                     if a > 40]
            left, bottom, pw, ph, mask = sprite["plan"]
            sprite["plan_points"] = [(left + c, bottom + (ph - 1 - r)) for r in range(ph) for c in range(pw)
                                     if mask[r * pw + c]]
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


def place_landmarks(wc3, city, street, water, taken, cache):
    """The city's authored models; each must keep its body off the street."""
    placed, problems = [], []
    for item in city["props"]:
        sprite = sprite_for(wc3, city, item, cache)
        X, Y = int(floor(item["x"] + 0.5)), int(floor(item["y"] + 0.5))
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
    for g, salt, X, Y, nx, ny in candidates:
        if taken[street.index(X, Y)]:
            continue
        district = district_at(city, X, Y)
        palette = district.get(key) or []
        if not palette:
            continue
        facing = atan2(-ny, -nx) * 180.0 / pi
        yaw = int(floor(facing / 45.0 + 0.5)) * 45 % 360
        order = sorted(range(len(palette)),
                       key=lambda k: hash32(salt, k, 24) / palette[k].get("weight", 1.0))
        for k in order:
            entry = palette[k]
            if g > entry.get("reach", reach):
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
    log(f"  street field {time.time() - started:.0f}s")
    pic = Picture(w, h)
    paint_terrain(pic, city, tiles)
    water, bridge = water_masks(city, geometry, street)
    paint_water(pic, city, water, tiles, bridge)
    log(f"  ground and water {time.time() - started:.0f}s")
    paint_street(pic, city, geometry, street, tiles)
    log(f"  street {time.time() - started:.0f}s")
    cache = {}
    taken = bytearray(w * h)
    models = place_landmarks(wc3, city, street, water, taken, cache)
    models += street_furniture(wc3, city, street, water, taken, cache)
    log(f"  landmarks and furniture {time.time() - started:.0f}s ({len(cache)} sprites)")
    models += generate_buildings(wc3, city, street, water, taken, cache)
    log(f"  buildings {time.time() - started:.0f}s ({len(models)} models, {len(cache)} sprites)")
    if city.get("trim"):
        models += generate_buildings(wc3, city, street, water, taken, cache, city["trim"], "trim")
        log(f"  trim {time.time() - started:.0f}s ({len(models)} models, {len(cache)} sprites)")
    walls = wall_columns(city, street)
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
    counts = {}
    for item, sprite, X, Y in models:
        counts[item["model"]] = counts.get(item["model"], 0) + 1
    textures = set()
    for item, sprite, X, Y in models:
        for path in sprite["textures"]:
            textures.add(path.replace("war3.w3mod/", "war3.w3mod:", 1))
    for path, _ in tiles.cache:
        textures.add(path)
    textures.add(city["water_texture"])
    lines = [f"# {city['name']}: Warcraft III Reforged files used by {city['folder']}/Background.tga",
             "# Generated by scripts/build_city_tracks.py --preview. Archive paths as the client stores them.",
             "", "## Models (placements)"]
    lines += [f"{counts[m]:4d}  {m}" for m in sorted(counts)]
    lines += ["", "## Textures"] + sorted(textures)
    return "\n".join(lines) + "\n"
