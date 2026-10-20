"""Paint the Mirage Raceway background (scenery v1) registered to the Lua geometry.

python scripts/build_mirage_background.py            # write the runtime TGA
python scripts/build_mirage_background.py --check    # verify exact bytes/invariants, write nothing
python scripts/build_mirage_background.py --preview  # also write review PNGs under docs/art/

Needs the project's pinned Lua 5.1 runtime (Lupa, see requirements-dev.txt)
plus the standard library; shared painting lives in scripts/paintkit.py.
Every pixel's road/rough class comes from the actual MirageRaceway
`isDrivable` predicate at the pixel center, so painted road edges match
collision exactly. Scenery is painted around the road, never on it, and stays
outside a clearance band. Only IEEE-exact operations and integer hashing feed
pixel values, so the bytes are platform-independent. No concept board,
screenshot, third-party texture or model is an input.

Output: 1024x1024 uncompressed true-color TGA (type 2), 32-bit BGRA, eight
alpha bits, fully opaque, bottom-left origin; one texel per world unit.
"""
import argparse
import hashlib
import importlib
from math import floor, sqrt
from pathlib import Path
import struct
import sys

from paintkit import (Shape, Canvas, clamp, flat, hash2, hash32, mix3, sd_box, sd_circle,
                      sd_ellipse, sd_polygon, sd_segment, smooth, value_noise)

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "addon" / "AzerothKart" / "Assets" / "Tracks" / "SaltFlats" / "Background.tga"
SIZE = 1024
ROAD_RADIUS = 56.0


# ---------------------------------------------------------------------------
# Geometry from the actual Lua track (authoritative), scanned once.


def load_track():
    local_deps = ROOT / "local-artifacts" / "python-deps"
    if local_deps.is_dir():
        sys.path.insert(0, str(local_deps))
    try:
        runtime = importlib.import_module("lupa.lua51").LuaRuntime
    except ImportError as exc:
        raise SystemExit("Install requirements-dev.txt as described in scripts/test_lua.py") from exc
    # encoding=None keeps Lua strings as raw bytes (the geometry scan is binary).
    lua = runtime(unpack_returned_tuples=True, encoding=None)
    addon = ROOT / "addon" / "AzerothKart"
    oval = lua.execute((addon / "Track.lua").read_text(encoding="utf-8-sig").encode("utf-8"))
    factory = lua.execute((addon / "MirageRaceway.lua").read_text(encoding="utf-8-sig").encode("utf-8"))
    return lua, factory.new(oval.crossesGate)


SCAN = """function(track, size)
    -- Per pixel center: isDrivable (authoritative), then the nearest centerline
    -- segment's signed lateral offset (+ = left of travel) and arc position.
    local cl, n = track.centerline, #track.centerline
    local sx, sy, ex, ey, len, cum, total = {}, {}, {}, {}, {}, {}, 0
    for i = 1, n do
        local a, b = cl[i], cl[i % n + 1]
        sx[i], sy[i], ex[i], ey[i] = a.x, a.y, b.x - a.x, b.y - a.y
        len[i] = math.sqrt(ex[i] * ex[i] + ey[i] * ey[i])
        cum[i] = total
        total = total + len[i]
    end
    local char, floor, rows = string.char, math.floor, {}
    for y = 0, size - 1 do
        local row, py = {}, y + 0.5
        for x = 0, size - 1 do
            local px = x + 0.5
            local best, side, along = math.huge, 1, 0
            for i = 1, n do
                local dx, dy = ex[i], ey[i]
                local t = ((px - sx[i]) * dx + (py - sy[i]) * dy) / (dx * dx + dy * dy)
                if t < 0 then t = 0 elseif t > 1 then t = 1 end
                local ox, oy = px - (sx[i] + t * dx), py - (sy[i] + t * dy)
                local d2 = ox * ox + oy * oy
                if d2 < best then
                    best = d2
                    side = (dx * oy - dy * ox) >= 0 and 1 or -1
                    along = cum[i] + t * len[i]
                end
            end
            local lateral = floor(side * math.sqrt(best) * 4 + 0.5) + 32768
            if lateral < 0 then lateral = 0 elseif lateral > 65535 then lateral = 65535 end
            local s = floor(along * 16 + 0.5)
            row[x + 1] = char(track.isDrivable(px, py) and 1 or 0, floor(lateral / 256),
                lateral % 256, floor(s / 256), s % 256)
        end
        rows[y + 1] = table.concat(row)
    end
    return table.concat(rows), total
end"""


class Geometry:
    """Per-pixel road class (exact), signed lateral offset and arc position.

    Arrays are indexed bottom-up like the world: index = y * SIZE + x.
    """

    def __init__(self, lua, track):
        data, total = lua.eval(SCAN.encode("ascii"))(track, SIZE)
        data = bytes(data)
        assert len(data) == SIZE * SIZE * 5, "unexpected geometry scan size"
        self.road = data[0::5]
        hi, lo, shi, slo = data[1::5], data[2::5], data[3::5], data[4::5]
        self.lateral = [((hi[i] << 8 | lo[i]) - 32768) / 4.0 for i in range(SIZE * SIZE)]
        self.along = [(shi[i] << 8 | slo[i]) / 16.0 for i in range(SIZE * SIZE)]
        self.length = float(total)
        self.track = track
        self.centerline = [(float(track.centerline[i].x), float(track.centerline[i].y))
                           for i in range(1, len(track.centerline) + 1)]

    def road_distance(self, x, y):
        """Distance from (x, y) to the road surface (0 inside), exact capsule math."""
        best = None
        pts = self.centerline
        for i in range(len(pts)):
            ax, ay = pts[i]
            bx, by = pts[(i + 1) % len(pts)]
            dx, dy = bx - ax, by - ay
            t = clamp(((x - ax) * dx + (y - ay) * dy) / (dx * dx + dy * dy))
            ox, oy = x - (ax + t * dx), y - (ay + t * dy)
            d = sqrt(ox * ox + oy * oy)
            if best is None or d < best:
                best = d
        return max(0.0, best - ROAD_RADIUS)

    def bends(self):
        """Arc windows and kerb side (+1 left, -1 right) around each sharp vertex."""
        pts, out, total = self.centerline, [], 0.0
        lengths = []
        for i in range(len(pts)):
            ax, ay = pts[i]
            bx, by = pts[(i + 1) % len(pts)]
            lengths.append(sqrt((bx - ax) * (bx - ax) + (by - ay) * (by - ay)))
        starts = []
        for length in lengths:
            starts.append(total)
            total += length
        for i in range(len(pts)):
            px, py = pts[i - 1]
            cx, cy = pts[i]
            nx, ny = pts[(i + 1) % len(pts)]
            ax, ay, bx, by = cx - px, cy - py, nx - cx, ny - cy
            cross = ax * by - ay * bx
            dot = ax * bx + ay * by
            # Sharpness without trigonometry: 1 - cos(turn).
            sharp = 1.0 - dot / sqrt((ax * ax + ay * ay) * (bx * bx + by * by))
            if sharp > 0.12:
                half = 26.0 + 120.0 * sharp
                out.append((starts[i] - half, starts[i] + half, 1 if cross > 0 else -1))
        return out, total


# ---------------------------------------------------------------------------
# Palette: dry Shimmering Flats in a hand-painted Warcraft III key.

SALT = (0.906, 0.874, 0.764)
SALT_WARM = (0.935, 0.862, 0.722)
SALT_COOL = (0.868, 0.866, 0.808)
SALT_RIDGE = (0.968, 0.950, 0.884)
CRACK = (0.640, 0.560, 0.450)
DUST = (0.790, 0.690, 0.520)
DIRT = (0.643, 0.537, 0.369)
DIRT_RED = (0.655, 0.505, 0.335)
DIRT_PALE = (0.716, 0.616, 0.446)
BERM = (0.520, 0.380, 0.250)
KERB_RED = (0.660, 0.200, 0.120)
KERB_PALE = (0.905, 0.860, 0.740)
CHECK_LIGHT = (0.930, 0.910, 0.850)
CHECK_DARK = (0.130, 0.115, 0.100)

CELL = 46.0          # salt polygon size, world units
START_X0, START_X1 = 644, 756  # checkered start/finish band across the Start gate
START_Y0, START_Y1 = 352, 368


def salt_sites():
    """Jittered Voronoi sites, one per CELL square (deterministic)."""
    count = int(SIZE / CELL) + 3
    sites = {}
    for gy in range(-2, count):
        for gx in range(-2, count):
            jx = 0.15 + 0.7 * hash2(gx, gy, 71) / 65535.0
            jy = 0.15 + 0.7 * hash2(gx, gy, 72) / 65535.0
            sites[(gx, gy)] = ((gx + jx) * CELL, (gy + jy) * CELL)
    return sites


def salt_color(x, y, edge, sites):
    """Calm salt crust: soft mottling, faint wavy pressure ridges with fine cracks."""
    t = value_noise(x, y, 150.0, 3)
    base = mix3(SALT, SALT_WARM, smooth((t - 0.5) * 2.0)) if t > 0.5 else \
        mix3(SALT, SALT_COOL, smooth((0.5 - t) * 2.0))
    # Domain-warped Voronoi so polygon edges wander instead of running straight.
    qx = x + 18.0 * (value_noise(x, y, 61.0, 21) - 0.5)
    qy = y + 18.0 * (value_noise(x, y, 61.0, 22) - 0.5)
    gx, gy = int(qx // CELL), int(qy // CELL)
    f1 = f2 = 1e9
    for oy in (-1, 0, 1):
        for ox in (-1, 0, 1):
            sx, sy = sites[(gx + ox, gy + oy)]
            d = (qx - sx) * (qx - sx) + (qy - sy) * (qy - sy)
            if d < f1:
                f2, f1 = f1, d
            elif d < f2:
                f2 = d
    gap = sqrt(f2) - sqrt(f1)               # ~2x distance to the polygon edge
    v = 1.0 + 0.06 * (value_noise(x, y, 47.0, 4) - 0.5) + 0.04 * (value_noise(x, y, 13.0, 5) - 0.5)
    v += 0.03 * (hash2(int(x), int(y), 7) / 65535.0 - 0.5)
    r, g, b = base[0] * v, base[1] * v, base[2] * v
    visible = smooth((value_noise(x, y, 38.0, 23) - 0.25) / 0.45)
    ridge = smooth(1.0 - gap / 3.0) * visible
    if ridge > 0.0:
        r, g, b = mix3((r, g, b), SALT_RIDGE, ridge * 0.42)
        crack = smooth(1.0 - gap / 0.8) * (0.4 + 0.6 * value_noise(x, y, 7.0, 6)) * visible
        r, g, b = mix3((r, g, b), CRACK, crack * 0.32)
    if edge is not None:
        if edge < 3.0:                       # bright crust right at the road edge
            r, g, b = mix3((r, g, b), SALT_RIDGE, 0.35 * smooth(1.0 - edge / 3.0))
        elif edge < 22.0:                    # dust thrown off the road
            dust = (1.0 - smooth((edge - 3.0) / 19.0)) * (0.25 + 0.5 * value_noise(x, y, 11.0, 8))
            r, g, b = mix3((r, g, b), DUST, dust * 0.45)
    return r, g, b


def road_color(x, y, lateral, along, kerbs):
    """Packed dirt: worn groove, loose margin, dark berm, intermittent tire streaks."""
    side = abs(lateral)
    t = value_noise(x, y, 90.0, 11)
    base = mix3(DIRT, DIRT_RED, smooth((t - 0.5) * 1.6)) if t > 0.5 else \
        mix3(DIRT, DIRT_PALE, smooth((0.5 - t) * 1.6))
    v = 1.0 + 0.06 * (value_noise(x, y, 14.0, 12) - 0.5) + 0.05 * (hash2(int(x), int(y), 13) / 65535.0 - 0.5)
    v -= 0.05 * (1.0 - smooth((side - 26.0) / 14.0))          # traffic-packed center
    v += 0.04 * smooth((side - 40.0) / 4.0) * (1.0 - smooth((side - 48.0) / 2.0))  # loose margin
    r, g, b = base[0] * v, base[1] * v, base[2] * v
    for lane, offset in enumerate((-13.0, 15.0)):
        wobble = offset + 7.0 * (value_noise(along, lane * 31.0, 80.0, 18 + lane) - 0.5)
        for wheel in (-6.6, 6.6):
            w = abs(lateral - wobble - wheel)
            if w < 1.8:
                run = smooth((value_noise(along, lane * 31.0, 70.0, 14 + lane) - 0.56) / 0.18)
                k = (1.0 - smooth(w / 1.8)) * run * 0.12
                r, g, b = r * (1.0 - k), g * (1.0 - k), b * (1.0 - k)
    berm = smooth((side - 49.5) / 4.0)
    if berm > 0.0:
        r, g, b = mix3((r, g, b), BERM, berm * 0.7)
    for start, end, sign in kerbs:
        if start <= along <= end and lateral * sign > 46.5:
            block = int(floor(along / 7.0)) % 2
            kerb = KERB_RED if block else KERB_PALE
            fade = smooth((min(along - start, end - along)) / 6.0)
            wear = 0.15 + 0.2 * value_noise(x, y, 6.0, 15)
            r, g, b = mix3((r, g, b), kerb, fade * (1.0 - wear))
    if hash2(int(x), int(y), 16) < 260:          # sparse pebbles
        r, g, b = r * 0.72, g * 0.72, b * 0.72
    return r, g, b


def start_line(x, y, color):
    """Two rows of worn 8-unit checkers across the road at the Start gate."""
    ix, iy = int(x) // 8, (int(y) - START_Y0) // 8
    paint = CHECK_LIGHT if (ix + iy) % 2 == 0 else CHECK_DARK
    wear = smooth((value_noise(x, y, 5.0, 17) - 0.62) / 0.2) * 0.85 + 0.08
    return mix3(paint, color, wear)


def paint_ground(canvas, geo):
    sites = salt_sites()
    kerbs, _ = geo.bends()
    red, green, blue, alpha = canvas.red, canvas.green, canvas.blue, canvas.alpha
    road, lateral, along = geo.road, geo.lateral, geo.along
    for y in range(SIZE):
        wy = y + 0.5
        row = (SIZE - 1 - y) * SIZE
        for x in range(SIZE):
            wx = x + 0.5
            p = y * SIZE + x
            if road[p]:
                c = road_color(wx, wy, lateral[p], along[p], kerbs)
                if START_Y0 <= y < START_Y1 and START_X0 <= x < START_X1:
                    c = start_line(wx, wy, c)
            else:
                edge = abs(lateral[p]) - ROAD_RADIUS
                c = salt_color(wx, wy, edge if edge < 22.0 else None, sites)
            i = row + x
            red[i], green[i], blue[i], alpha[i] = clamp(c[0]), clamp(c[1]), clamp(c[2]), 1.0


# ---------------------------------------------------------------------------
# Scenery: static, lit from the north-west (the map never rotates), with soft
# south-east cast shadows. Every object keeps CLEARANCE units off the road.

CLEARANCE = 20.0
_L = (-0.45, 0.56, 0.70)
_N = sqrt(_L[0] * _L[0] + _L[1] * _L[1] + _L[2] * _L[2])
LX, LY, LZ = _L[0] / _N, _L[1] / _N, _L[2] / _N
SHADOW = (0.26, 0.19, 0.14)
OUTLINE = (0.17, 0.11, 0.08)
SQ3 = sqrt(3.0) / 2.0          # cos 30 degrees, exact under IEEE sqrt
ROT = (24.0 / 25.0, 7.0 / 25.0)  # exact ~16 degree rotation for crooked goblin carpentry

SANDSTONE = (0.760, 0.520, 0.300)
SANDSTONE_DARK = (0.560, 0.360, 0.210)
OCHRE_GROUND = (0.800, 0.640, 0.450)
BONE = (0.900, 0.865, 0.770)
IRON = (0.300, 0.290, 0.300)
RUST = (0.520, 0.300, 0.160)
WOOD = (0.560, 0.380, 0.220)
WOOD_DARK = (0.400, 0.260, 0.150)
CANVAS = (0.880, 0.820, 0.680)
GOB_RED = (0.740, 0.170, 0.110)
GOB_GREEN = (0.330, 0.480, 0.200)
GOB_LIME = (0.500, 0.640, 0.240)
GOB_TEAL = (0.240, 0.520, 0.470)
HAZARD = (0.960, 0.760, 0.150)
GNOME_BLUE = (0.260, 0.430, 0.780)
COPPER = (0.740, 0.430, 0.220)
BRASS = (0.850, 0.640, 0.270)
GLASS = (0.560, 0.840, 0.900)
SHRUB = (0.420, 0.420, 0.220)


def lit(base, normal, ambient=0.52, gain=0.62, cool=(0.36, 0.30, 0.34), spec=0.0, grain=0.06,
        seed=0, pattern=None):
    """Lambert-lit material for static scenery with a cool shadow side."""
    br, bg_, bb = base

    def paint(x, y, d):
        nx, ny, nz = normal(x, y, d)
        k = nx * LX + ny * LY + nz * LZ
        if k < 0.0:
            k = 0.0
        light = ambient + gain * k
        r, g, b = br * light, bg_ * light, bb * light
        fall = (1.0 - k) * 0.22
        r, g, b = r + (cool[0] * br - r) * fall, g + (cool[1] * bg_ - g) * fall, b + (cool[2] * bb - b) * fall
        if spec > 0.0 and k > 0.86:
            s = (k - 0.86) / 0.14
            s = s * s * spec
            r, g, b = r + (1.0 - r) * s, g + (1.0 - g) * s, b + (1.0 - b) * s
        if pattern is not None:
            m = pattern(x, y)
            r, g, b = r * m, g * m, b * m
        if grain > 0.0:
            v = 1.0 + grain * (value_noise(x, y, 3.0, seed) - 0.5) * 2.0
            r, g, b = r * v, g * v, b * v
        return r, g, b
    return paint


def unit(x, y, z):
    n = sqrt(x * x + y * y + z * z)
    return x / n, y / n, z / n


def n_flat(x, y, d):
    return 0.0, 0.0, 1.0


def n_dome(cx, cy, rx, ry, bump=0.0, seed=0, top=0.0):
    """Sphere-ish normal; `top` flattens a mesa crown, `bump` adds facets."""
    def normal(x, y, d):
        nx, ny = (x - cx) / rx, (y - cy) / ry
        r2 = nx * nx + ny * ny
        if r2 < top * top:
            nx = ny = 0.0
            r2 = 0.0
        elif top > 0.0:
            s = (sqrt(r2) - top) / (1.0 - top) / sqrt(r2)
            nx, ny = nx * s, ny * s
            r2 = nx * nx + ny * ny
        if r2 > 0.96:
            r2 = 0.96
        nz = sqrt(1.0 - r2)
        if bump > 0.0:
            nx += bump * (value_noise(x, y, 5.0, seed) - 0.5)
            ny += bump * (value_noise(x, y, 5.0, seed + 1) - 0.5)
        return unit(nx, ny, nz)
    return normal


def n_gable(cx, cy, ax, ay, slope=0.6):
    """Two roof planes falling away from a ridge along unit axis (ax, ay)."""
    px, py = -ay, ax
    plus = unit(px * slope, py * slope, 1.0)
    minus = unit(-px * slope, -py * slope, 1.0)

    def normal(x, y, d):
        return plus if (x - cx) * px + (y - cy) * py > 0.0 else minus
    return normal


def n_cyl(cx, cy, ax, ay, radius):
    """Cylinder lying along unit axis (ax, ay)."""
    px, py = -ay, ax

    def normal(x, y, d):
        q = ((x - cx) * px + (y - cy) * py) / radius
        q = max(-0.98, min(0.98, q))
        return unit(px * q, py * q, sqrt(1.0 - q * q))
    return normal


def rotated(cx, cy, rot=ROT):
    c, s = rot

    def local(x, y):
        dx, dy = x - cx, y - cy
        return dx * c + dy * s, -dx * s + dy * c
    return local


class Scene:
    """Collects shapes in painter order with clearance and shadow helpers."""

    def __init__(self, geo):
        self.geo, self.shapes = geo, []

    def need(self, x, y, radius, clearance=CLEARANCE):
        gap = self.geo.road_distance(x, y) - radius
        assert gap >= clearance, f"scenery at {(x, y)} r={radius} is {gap:.1f} from the road"

    def add(self, sdf, bbox, paint, outline=0.8, shadow=0.0, soft=None, opacity=1.0,
            shadow_soft=3.0, shadow_alpha=0.30, ink=OUTLINE):
        if shadow > 0.0:
            x0, x1, y0, y1 = bbox
            self.shapes.append(Shape(lambda x, y: sdf(x - shadow, y + shadow),
                                     (x0 + shadow, x1 + shadow, y0 - shadow, y1 - shadow),
                                     flat(SHADOW), 0.0, opacity=shadow_alpha, soft=shadow_soft))
        self.shapes.append(Shape(sdf, bbox, paint, outline, ink, opacity, soft))

    def ground(self, sdf, bbox, color, opacity, soft=6.0):
        self.shapes.append(Shape(sdf, bbox, flat(color), 0.0, opacity=opacity, soft=soft))

    def rock(self, cx, cy, rx, ry, seed, color=SANDSTONE, top=0.35, height=None):
        """Chiseled sandstone: jagged outline, flat lit facets, crevices, bleached top."""
        small = min(rx, ry)
        jag = 0.3 * small

        def sdf(x, y):
            n = 0.65 * value_noise(x, y, 0.6 * small, seed) + 0.35 * value_noise(x, y, 0.25 * small, seed + 5)
            return sd_ellipse(x, y, cx, cy, rx, ry) + jag * (n - 0.5) * 1.7
        facet = max(1.8, 0.34 * small)
        pale = mix3(color, (0.90, 0.76, 0.56), 0.55)
        dark = mix3(color, (0.42, 0.24, 0.15), 0.35)

        def paint(x, y, d):
            gx, gy = int(floor(x / facet)), int(floor(y / facet))
            f1 = f2 = 1e18
            fx = fy = 0.0
            fh = 0
            for oy in (-1, 0, 1):
                for ox in (-1, 0, 1):
                    h = hash32(gx + ox, gy + oy, seed)
                    sx = (gx + ox + 0.15 + 0.7 * (h & 255) / 255.0) * facet
                    sy = (gy + oy + 0.15 + 0.7 * ((h >> 8) & 255) / 255.0) * facet
                    dd = (x - sx) * (x - sx) + (y - sy) * (y - sy)
                    if dd < f1:
                        f2, f1, fx, fy, fh = f1, dd, sx, sy, h
                    elif dd < f2:
                        f2 = dd
            nx, ny = (fx - cx) / (rx * 1.1), (fy - cy) / (ry * 1.1)
            r2 = nx * nx + ny * ny
            crown = r2 < top * top
            if crown:
                nx, ny = nx * 0.25, ny * 0.25
                r2 = nx * nx + ny * ny
            if r2 > 0.9:
                nx, ny, r2 = nx * 0.95 / sqrt(r2), ny * 0.95 / sqrt(r2), 0.9025
            tx = 0.5 * (((fh >> 16) & 255) / 255.0 - 0.5)
            ty = 0.5 * (((fh >> 24) & 255) / 255.0 - 0.5)
            n = unit(nx + tx, ny + ty, sqrt(1.0 - r2))
            k = max(0.0, n[0] * LX + n[1] * LY + n[2] * LZ)
            base = pale if crown else (dark if k < 0.45 else color)
            light = 0.5 + 0.62 * k
            r, g, b = base[0] * light, base[1] * light, base[2] * light
            strata = 1.0 - 0.07 * smooth((value_noise(x * 0.4, y * 3.0, 2.0, seed + 9) - 0.55) / 0.2)
            gap = sqrt(f2) - sqrt(f1)
            if gap < 0.55:
                strata *= 0.78 + 0.22 * gap / 0.55
            v = strata * (1.0 + 0.06 * (value_noise(x, y, 2.5, seed + 3) - 0.5))
            return r * v, g * v, b * v
        h = 0.35 * small if height is None else height
        pad = jag
        self.add(sdf, (cx - rx - pad, cx + rx + pad, cy - ry - pad, cy + ry + pad), paint,
                 outline=0.8, shadow=h, shadow_soft=2.0 + 0.15 * h, shadow_alpha=0.36)

    def barrel(self, cx, cy, r, body=GOB_RED, band=HAZARD):
        def paint(x, y, d):
            rr = sqrt((x - cx) * (x - cx) + (y - cy) * (y - cy)) / r
            c = band if 0.62 < rr < 0.78 else body
            if rr < 0.3:
                c = mix3(c, IRON, 0.6)
            return lit(c, n_dome(cx, cy, r * 1.4, r * 1.4), grain=0.04)(x, y, d)
        self.add(lambda x, y: sd_circle(x, y, cx, cy, r), (cx - r, cx + r, cy - r, cy + r), paint,
                 outline=0.7, shadow=r * 0.8, shadow_soft=2.0)

    def crate(self, cx, cy, h, rot=(1.0, 0.0)):
        local = rotated(cx, cy, rot)

        def sdf(x, y):
            lx, ly = local(x, y)
            return sd_box(lx, ly, 0.0, 0.0, h, h, 0.6)

        def pattern(x, y):
            lx, ly = local(x, y)
            k = 1.0 - 0.25 * smooth(1.0 - abs(abs(lx) - h * 0.55) / 0.7)
            k *= 1.0 - 0.18 * smooth(1.0 - abs(ly) / 0.6)
            return k
        self.add(sdf, (cx - h * 1.5, cx + h * 1.5, cy - h * 1.5, cy + h * 1.5),
                 lit(WOOD, n_flat, pattern=pattern, seed=int(cx) + 7), outline=0.7,
                 shadow=h * 0.9, shadow_soft=1.8)

    def shrub(self, cx, cy, r, seed):
        def sdf(x, y):
            return sd_circle(x, y, cx, cy, r) + 0.45 * r * (value_noise(x, y, 0.35 * r + 0.5, seed) - 0.5)

        def paint(x, y, d):
            k = 0.75 + 0.5 * value_noise(x, y, 1.2, seed + 1)
            return SHRUB[0] * k, SHRUB[1] * k, SHRUB[2] * k
        self.add(sdf, (cx - r * 1.3, cx + r * 1.3, cy - r * 1.3, cy + r * 1.3), paint, outline=0.5,
                 shadow=r * 0.6, shadow_soft=1.5, shadow_alpha=0.25)


def perimeter(scene):
    """Ochre cliff band of large, overlapping chiseled boulders on all four edges."""
    def band(x, y):
        edge = min(x, y, SIZE - x, SIZE - y)
        return edge - 16.0 - 16.0 * value_noise(x, y, 46.0, 401)
    scene.ground(band, (0.0, SIZE, 0.0, SIZE), OCHRE_GROUND, 0.62, soft=9.0)
    for side in range(4):
        pos, k = 0.0, 0
        while pos < SIZE:
            h = hash32(side, k, 301)
            r = 11.0 + 21.0 * (h & 255) * (h & 255) / 65025.0
            off = -4.0 + 12.0 * ((h >> 8) & 255) / 255.0
            jitter = 6.0 * (((h >> 28) & 7) / 7.0 - 0.5)
            if side == 0:
                cx, cy = pos + jitter, off
            elif side == 1:
                cx, cy = SIZE - off, pos + jitter
            elif side == 2:
                cx, cy = SIZE - pos - jitter, SIZE - off
            else:
                cx, cy = off, SIZE - pos - jitter
            rx = r * (0.8 + 0.45 * ((h >> 16) & 15) / 15.0)
            ry = r * (0.75 + 0.45 * ((h >> 20) & 15) / 15.0)
            color = mix3(SANDSTONE, SANDSTONE_DARK, 0.1 + 0.4 * ((h >> 24) & 3) / 3.0)
            if scene.geo.road_distance(cx, cy) - r >= CLEARANCE:
                scene.rock(cx, cy, rx, ry, seed=side * 1000 + k, color=color)
            if (h >> 12) & 3 == 0:              # occasional smaller rock in front
                fx, fy = [(cx + 4, cy + r + 4), (cx - r - 4, cy + 3), (cx - 4, cy - r - 4), (cx + r + 4, cy - 3)][side]
                if scene.geo.road_distance(fx, fy) - 9.0 >= CLEARANCE:
                    scene.rock(fx, fy, 7.0, 5.5, seed=side * 1000 + k + 500, color=color)
            pos += r * 1.05
            k += 1
    for i, (cx, cy) in enumerate(((10.0, 10.0), (SIZE - 12.0, 14.0), (SIZE - 10.0, SIZE - 12.0), (14.0, SIZE - 10.0))):
        scene.rock(cx, cy, 44.0, 38.0, seed=4100 + i, top=0.5, height=14.0)
        scene.rock(cx + (18.0 if cx < 100 else -18.0), cy + (16.0 if cy < 100 else -16.0), 20.0, 16.0,
                   seed=4110 + i, top=0.4)


def rock_mound(scene):
    """The rocky mound inside the north-western bend (brief landmark)."""
    cx, cy = 530.0, 726.0
    scene.need(cx, cy, 70.0)
    scene.ground(lambda x, y: sd_ellipse(x, y, cx, cy, 78.0, 62.0) + 14.0 * value_noise(x, y, 22.0, 610),
                 (cx - 100, cx + 100, cy - 85, cy + 85), OCHRE_GROUND, 0.55, soft=12.0)
    rubble = ((-58, 30, 9, 7), (52, -38, 8, 7), (60, 26, 7, 6), (-44, -44, 8, 6), (10, 52, 7, 6),
              (-64, -8, 6, 5), (30, -52, 6, 5), (-20, 50, 5, 4))
    for i, (dx, dy, rx, ry) in enumerate(rubble):
        scene.rock(cx + dx, cy + dy, rx, ry, seed=630 + i, top=0.2)
    ring = ((-38, 24, 20, 16), (36, -26, 19, 15), (40, 20, 15, 12), (-30, -30, 16, 13), (0, 36, 15, 12),
            (-46, -2, 13, 11))
    for i, (dx, dy, rx, ry) in enumerate(ring):
        scene.rock(cx + dx, cy + dy, rx, ry, seed=620 + i, top=0.3)
    scene.rock(cx - 4, cy - 2, 44.0, 34.0, seed=611, top=0.6, height=16.0)
    scene.rock(cx + 12, cy + 8, 22.0, 16.0, seed=612, top=0.5, height=11.0,
               color=mix3(SANDSTONE, (0.82, 0.62, 0.40), 0.45))
    scene.rock(cx - 18, cy - 10, 12.0, 9.0, seed=613, top=0.4, height=7.0,
               color=mix3(SANDSTONE, (0.84, 0.66, 0.44), 0.55))
    for i in range(16):
        h = hash32(i, 3, 640)
        u = 2.0 * (h & 255) / 255.0 - 1.0
        rad = 0.9 + 0.25 * ((h >> 8) & 255) / 255.0
        px = cx + 74.0 * rad * u
        py = cy + 58.0 * rad * (1.0 if (h >> 24) & 1 else -1.0) * sqrt(max(0.0, 1.0 - u * u))
        if (h >> 25) & 1:
            scene.shrub(px, py, 3.0 + 2.5 * ((h >> 26) & 3) / 3.0, seed=650 + i)
        else:
            scene.rock(px, py, 2.5 + 2.0 * ((h >> 26) & 3) / 3.0, 2.2, seed=660 + i, top=0.0)


def goblin_workshop(scene, cx, cy, hx=54.0, hy=40.0):
    """Crooked workshop with a green patchwork gable roof and rusty ridge cap."""
    c, s = ROT
    local = rotated(cx, cy)
    plus = unit(-s * 0.55, c * 0.55, 1.0)     # roof plane facing local +y
    minus = unit(s * 0.55, -c * 0.55, 1.0)
    patches = (GOB_GREEN, GOB_LIME, GOB_TEAL, mix3(GOB_GREEN, RUST, 0.55), GOB_GREEN, GOB_LIME)

    def sdf(x, y):
        lx, ly = local(x, y)
        return sd_box(lx, ly, 0.0, 0.0, hx, hy, 2.0)

    def paint(x, y, d):
        lx, ly = local(x, y)
        tx, ty = int(floor((lx + hx) / 14.0)), int(floor((ly + hy) / 10.0))
        h = hash2(tx, ty, 801)
        base = patches[h % len(patches)]
        n = plus if ly > 0.0 else minus
        k = n[0] * LX + n[1] * LY + n[2] * LZ
        light = 0.5 + 0.62 * max(0.0, k)
        r, g, b = base[0] * light, base[1] * light, base[2] * light
        fx = (lx + hx) / 14.0 - tx
        fy = (ly + hy) / 10.0 - ty
        seam = min(fx, 1.0 - fx, fy, 1.0 - fy)
        if seam < 0.1:
            r, g, b = r * 0.72, g * 0.72, b * 0.72
        if abs(ly) < 2.6:                      # rusty ridge cap
            rr = lit(RUST, n_cyl(cx, cy, c, s, 2.6), spec=0.3)(x, y, d)
            r, g, b = rr
        corrugation = 1.0 + 0.07 * (1.0 if int(floor((ly + hy) / 1.6)) % 2 else -1.0)
        r, g, b = r * corrugation, g * corrugation, b * corrugation
        if (h >> 8) & 3 == 0 and min(fx, 1.0 - fx) < 0.09 and min(fy, 1.0 - fy) < 0.12:   # rivets
            r, g, b = mix3((r, g, b), BRASS, 0.6)
        v = 1.0 + 0.08 * (value_noise(x, y, 4.0, 802) - 0.5)
        streak = smooth((value_noise(lx * 0.3, ly * 3.0, 5.0, 803) - 0.7) / 0.2)
        return mix3((r * v, g * v, b * v), (r * 0.6, g * 0.55, b * 0.45), streak * 0.5)
    reach = hx * c + hy * s + 3.0
    scene.need(cx, cy, reach + 10.0)
    scene.add(sdf, (cx - reach, cx + reach, cy - reach, cy + reach), paint, outline=1.1, shadow=9.0,
              shadow_soft=3.0, shadow_alpha=0.38)
    # Chimney pipe with soot.
    px, py = cx + 0.55 * hx * c - 0.45 * hy * s, cy + 0.55 * hx * s + 0.45 * hy * c
    scene.ground(lambda x, y: sd_circle(x, y, px + 4.0, py + 3.0, 9.0), (px - 12, px + 16, py - 10, py + 16),
                 (0.10, 0.09, 0.08), 0.45, soft=5.0)
    scene.add(lambda x, y: sd_circle(x, y, px, py, 5.5), (px - 6, px + 6, py - 6, py + 6),
              lit(IRON, n_dome(px, py, 7.0, 7.0), spec=0.4), outline=0.8, shadow=12.0, shadow_soft=2.5)
    scene.add(lambda x, y: sd_circle(x, y, px, py, 3.2), (px - 4, px + 4, py - 4, py + 4),
              flat((0.06, 0.05, 0.05)), outline=0.0)


def striped_canopy(scene, cx, cy, hx, hy, colors, rot=(1.0, 0.0), stripe=6.0, shadow=7.0):
    """Market-style awning: stripes across a shallow gable, seen from above."""
    c, s = rot
    local = rotated(cx, cy, rot)
    plus = unit(-s * 0.45, c * 0.45, 1.0)
    minus = unit(s * 0.45, -c * 0.45, 1.0)

    def sdf(x, y):
        lx, ly = local(x, y)
        return sd_box(lx, ly, 0.0, 0.0, hx, hy, 1.2)

    def paint(x, y, d):
        lx, ly = local(x, y)
        band = int(floor((lx + hx) / stripe)) % len(colors)
        base = colors[band]
        n = plus if ly > 0.0 else minus
        k = n[0] * LX + n[1] * LY + n[2] * LZ
        light = 0.55 + 0.55 * max(0.0, k)
        v = light * (1.0 + 0.06 * (value_noise(x, y, 3.0, 811) - 0.5))
        scallop = 1.0 - 0.18 * smooth(1.0 - (hy - abs(ly)) / 2.0)
        return base[0] * v * scallop, base[1] * v * scallop, base[2] * v * scallop
    reach = abs(hx * c) + abs(hy * s) + 2.0
    reach_y = abs(hx * s) + abs(hy * c) + 2.0
    scene.need(cx, cy, max(reach, reach_y) + 6.0)
    scene.add(sdf, (cx - reach, cx + reach, cy - reach_y, cy + reach_y), paint, outline=0.9, shadow=shadow,
              shadow_soft=2.5, shadow_alpha=0.32)


def scrap_heap(scene, cx, cy, r, seed):
    def sdf(x, y):
        return sd_circle(x, y, cx, cy, r) + 0.35 * r * (value_noise(x, y, 0.4 * r, seed) - 0.5)

    def paint(x, y, d):
        n = value_noise(x, y, 3.5, seed + 1)
        base = RUST if n < 0.4 else (IRON if n < 0.7 else (0.55, 0.53, 0.50))
        if hash2(int(x * 0.5), int(y * 0.5), seed + 2) < 3000:
            base = BRASS
        return lit(base, n_dome(cx, cy, r * 1.15, r * 1.15, bump=1.4, seed=seed + 3), grain=0.12,
                   seed=seed + 4)(x, y, d)
    scene.need(cx, cy, r * 1.3)
    scene.add(sdf, (cx - r * 1.3, cx + r * 1.3, cy - r * 1.3, cy + r * 1.3), paint, outline=0.9,
              shadow=r * 0.35, shadow_soft=3.0)


def wheel(scene, cx, cy, r, seed):
    scene.add(lambda x, y: abs(sd_circle(x, y, cx, cy, r * 0.72)) - r * 0.28,
              (cx - r, cx + r, cy - r, cy + r),
              lit((0.13, 0.12, 0.12), n_dome(cx, cy, r * 1.2, r * 1.2), seed=seed), outline=0.6,
              shadow=r * 0.5, shadow_soft=1.5)


def rocket_on_rack(scene, ax, ay, bx, by, r):
    """A spare goblin rocket lying on wooden cradles (axis along a->b)."""
    length = sqrt((bx - ax) * (bx - ax) + (by - ay) * (by - ay))
    ux, uy = (bx - ax) / length, (by - ay) / length
    for f in (0.25, 0.75):
        mx, my = ax + (bx - ax) * f, ay + (by - ay) * f
        scene.add(lambda x, y, mx=mx, my=my: sd_segment(x, y, mx - uy * r * 1.6, my + ux * r * 1.6,
                                                        mx + uy * r * 1.6, my - ux * r * 1.6, 1.8),
                  (mx - r * 2, mx + r * 2, my - r * 2, my + r * 2), lit(WOOD, n_flat), outline=0.6,
                  shadow=2.0, shadow_soft=1.5)

    def paint(x, y, d):
        along = ((x - ax) * ux + (y - ay) * uy) / length
        base = HAZARD if along > 0.86 else (GOB_RED if along > 0.12 else IRON)
        if 0.48 < along < 0.53:
            base = HAZARD
        return lit(base, n_cyl(ax, ay, ux, uy, r), spec=0.5)(x, y, d)
    scene.need((ax + bx) / 2, (ay + by) / 2, length / 2 + r)
    scene.add(lambda x, y: sd_segment(x, y, ax, ay, bx, by, r), (min(ax, bx) - r, max(ax, bx) + r,
              min(ay, by) - r, max(ay, by) + r), paint, outline=0.9, shadow=6.0, shadow_soft=2.5)
    for side in (-1.0, 1.0):                    # tail fins
        tx, ty = ax + ux * 3.0, ay + uy * 3.0
        scene.add(lambda x, y, side=side, tx=tx, ty=ty: sd_segment(x, y, tx, ty, tx - uy * side * r * 1.9 - ux * 4,
                                                                   ty + ux * side * r * 1.9 - uy * 4, 1.4),
                  (tx - r * 3, tx + r * 3, ty - r * 3, ty + r * 3), lit(IRON, n_flat), outline=0.5, shadow=4.0)


def crane(scene, bx, by, ex, ey):
    """Yellow lattice crane boom from a squat base tower; tall, so a long shadow."""
    length = sqrt((ex - bx) * (ex - bx) + (ey - by) * (ey - by))
    ux, uy = (ex - bx) / length, (ey - by) / length

    def paint(x, y, d):
        along = (x - bx) * ux + (y - by) * uy
        lateral = -(x - bx) * uy + (y - by) * ux
        brace = abs(((along + lateral * 1.0) / 6.0) % 1.0 - 0.5) < 0.12 or \
            abs(((along - lateral * 1.0) / 6.0) % 1.0 - 0.5) < 0.12
        base = (0.35, 0.28, 0.12) if brace and abs(lateral) < 2.0 else HAZARD
        return lit(base, n_cyl(bx, by, ux, uy, 3.0))(x, y, d)
    scene.need((bx + ex) / 2, (by + ey) / 2, length / 2 + 6.0)
    scene.add(lambda x, y: sd_box(x, y, bx, by, 8.0, 8.0, 1.0), (bx - 9, bx + 9, by - 9, by + 9),
              lit(IRON, n_dome(bx, by, 14.0, 14.0)), outline=0.9, shadow=14.0, shadow_soft=3.0)
    scene.add(lambda x, y: sd_segment(x, y, bx, by, ex, ey, 3.0), (min(bx, ex) - 4, max(bx, ex) + 4,
              min(by, ey) - 4, max(by, ey) + 4), paint, outline=0.8, shadow=18.0, shadow_soft=3.5,
              shadow_alpha=0.28)
    scene.add(lambda x, y: sd_box(x, y, ex, ey - 6.0, 3.0, 3.0, 0.6), (ex - 4, ex + 4, ey - 10, ey - 2),
              lit(IRON, n_flat), outline=0.6, shadow=10.0)


def hazard_pad(scene, x0, y0, x1, y1):
    """Flat pit box painted on the salt: hazard-striped frame, oily center."""
    cx, cy, hx, hy = (x0 + x1) / 2, (y0 + y1) / 2, (x1 - x0) / 2, (y1 - y0) / 2
    scene.need(cx, cy, sqrt(hx * hx + hy * hy))
    scene.ground(lambda x, y: sd_ellipse(x, y, cx + 4, cy - 2, hx * 0.7, hy * 0.6) +
                 6.0 * value_noise(x, y, 7.0, 820), (x0, x1, y0, y1), (0.16, 0.13, 0.11), 0.35, soft=5.0)

    def frame(x, y):
        return max(sd_box(x, y, cx, cy, hx, hy), -sd_box(x, y, cx, cy, hx - 3.5, hy - 3.5))

    def paint(x, y, d):
        stripe = int(floor((x + y) / 5.0)) % 2
        base = HAZARD if stripe else (0.12, 0.11, 0.10)
        wear = 0.25 + 0.4 * value_noise(x, y, 4.0, 821)
        return mix3(base, (0.80, 0.74, 0.62), wear * 0.5)
    scene.add(frame, (x0 - 1, x1 + 1, y0 - 1, y1 + 1), paint, outline=0.0, opacity=0.9)


def banner_pole(scene, x, y, color, wind=(1.0, 0.0), length=16.0, clearance=CLEARANCE):
    """Pole (seen end-on) with a cloth banner streaming in the wind."""
    scene.need(x, y, length + 4.0, clearance)
    wx, wy = wind
    ex, ey = x + wx * length, y + wy * length
    scene.add(lambda px, py: sd_segment(px, py, x + wx * 2, y + wy * 2, ex, ey, 2.6),
              (min(x, ex) - 4, max(x, ex) + 4, min(y, ey) - 4, max(y, ey) + 4),
              lit(color, n_cyl(x, y, wx, wy, 2.6),
                  pattern=lambda px, py: 1.0 - 0.15 * smooth((value_noise(px, py, 3.0, 830) - 0.5) / 0.3)),
              outline=0.6, shadow=13.0, shadow_soft=2.5, shadow_alpha=0.26)
    scene.add(lambda px, py: sd_circle(px, py, x, y, 1.8), (x - 2, x + 2, y - 2, y + 2),
              lit(WOOD_DARK, n_dome(x, y, 2.5, 2.5)), outline=0.4, shadow=15.0, shadow_soft=2.0)


def tire_stack(scene, x, y, seed):
    scene.need(x, y, 7.0, clearance=24.0)
    wheel(scene, x, y, 5.6, seed)


def goblin_camp(scene):
    """East pit camp: crooked workshop, crane, fuel, scrap, rocket, tent, pit box."""
    scene.ground(lambda x, y: sd_ellipse(x, y, 892.0, 400.0, 96.0, 138.0) + 22.0 * value_noise(x, y, 30.0, 840),
                 (780.0, 1000.0, 250.0, 550.0), (0.82, 0.74, 0.58), 0.35, soft=14.0)
    for i, (sx, sy, r) in enumerate(((850, 320, 10), (905, 360, 8), (870, 470, 9), (940, 300, 7))):
        scene.ground(lambda x, y, sx=sx, sy=sy, r=r: sd_circle(x, y, sx, sy, r) + 4.0 * value_noise(x, y, 5.0, 850 + i),
                     (sx - r - 6, sx + r + 6, sy - r - 6, sy + r + 6), (0.12, 0.10, 0.09), 0.40, soft=4.0)
    hazard_pad(scene, 792.0, 300.0, 846.0, 342.0)
    goblin_workshop(scene, 905.0, 428.0)
    striped_canopy(scene, 836.0, 470.0, 18.0, 12.0, (GOB_LIME, GOB_TEAL), rot=ROT)
    for i, (bx, by) in enumerate(((830, 368), (844, 362), (834, 354), (848, 376), (822, 382))):
        scene.barrel(float(bx), float(by), 5.8)
    for i, (bx, by, h) in enumerate(((878, 370, 6.0), (889, 364, 5.0), (884, 352, 4.5))):
        scene.crate(float(bx), float(by), h, rot=ROT if i % 2 else (1.0, 0.0))
    scrap_heap(scene, 952.0, 330.0, 21.0, 860)
    wheel(scene, 924.0, 312.0, 6.5, 861)
    wheel(scene, 966.0, 362.0, 5.5, 862)
    rocket_on_rack(scene, 930.0, 492.0, 982.0, 506.0, 6.0)
    crane(scene, 848.0, 520.0, 930.0, 548.0)
    banner_pole(scene, 796.0, 448.0, GOB_RED, wind=(0.8, 0.6))
    banner_pole(scene, 796.0, 392.0, GOB_GREEN, wind=(0.8, 0.6))


def gnome_dome(scene, cx, cy, r):
    """Riveted copper/brass dome workshop: twelve panels, rivet rings, glass cap."""
    bounds = []
    for k in range(12):                         # exact 30-degree directions via sqrt(3)/2
        dirs = ((1.0, 0.0), (SQ3, 0.5), (0.5, SQ3), (0.0, 1.0), (-0.5, SQ3), (-SQ3, 0.5),
                (-1.0, 0.0), (-SQ3, -0.5), (-0.5, -SQ3), (0.0, -1.0), (0.5, -SQ3), (SQ3, -0.5))
        bounds.append(diamond(*dirs[k]))
    normal = n_dome(cx, cy, r * 1.04, r * 1.04)

    def paint(x, y, d):
        dx, dy = x - cx, y - cy
        rr = sqrt(dx * dx + dy * dy) / r
        if rr < 0.22:
            return lit(GLASS, n_dome(cx, cy, r * 0.25, r * 0.25), spec=0.9)(x, y, d)
        a = diamond(dx, dy)
        sector = sum(1 for b in bounds if a >= b) % 12
        base = COPPER if sector % 2 else BRASS
        r_, g, b = lit(base, normal, spec=0.35, grain=0.05, seed=870)(x, y, d)
        if rr < 0.3:
            return mix3((r_, g, b), BRASS, 0.5)
        for ring in (0.45, 0.72, 0.93):
            if abs(rr - ring) < 0.035:
                r_, g, b = r_ * 0.7, g * 0.7, b * 0.7
            elif abs(rr - ring - 0.05) < 0.016 and hash2(int(x), int(y), 871) < 30000:
                r_, g, b = mix3((r_, g, b), (1.0, 0.93, 0.70), 0.6)
        return r_, g, b
    scene.need(cx, cy, r + 8.0)
    scene.add(lambda x, y: sd_circle(x, y, cx, cy, r), (cx - r, cx + r, cy - r, cy + r), paint,
              outline=1.1, shadow=r * 0.28, shadow_soft=5.0, shadow_alpha=0.40)


def diamond(x, y):
    """Monotonic pseudo-angle in [0, 4) without trigonometry (exact arithmetic)."""
    if y >= 0.0:
        return 1.0 - x / (x + y) if x >= 0.0 else 1.0 - x / (y - x) if y - x != 0 else 2.0
    return 3.0 - x / (-x - y) if x < 0.0 else 3.0 + x / (x - y)


def gear(scene, cx, cy, r, seed):
    dirs = ((1.0, 0.0), (SQ3, 0.5), (0.5, SQ3), (0.0, 1.0), (-0.5, SQ3), (-SQ3, 0.5),
            (-1.0, 0.0), (-SQ3, -0.5), (-0.5, -SQ3), (0.0, -1.0), (0.5, -SQ3), (SQ3, -0.5))

    def sdf(x, y):
        d = sd_circle(x, y, cx, cy, r * 0.8)
        for ux, uy in dirs:
            d = min(d, sd_segment(x, y, cx + ux * r * 0.7, cy + uy * r * 0.7, cx + ux * r, cy + uy * r,
                                  r * 0.13))
        return max(d, -sd_circle(x, y, cx, cy, r * 0.22))
    scene.need(cx, cy, r + 2.0)
    scene.add(sdf, (cx - r - 2, cx + r + 2, cy - r - 2, cy + r + 2),
              lit(BRASS, n_flat, spec=0.3, grain=0.08, seed=seed), outline=0.8, shadow=2.5, shadow_soft=1.5)


def gnome_camp(scene):
    """West pit camp: dome workshop, chimney, boiler and pipes, benches, gear, awning."""
    scene.ground(lambda x, y: sd_ellipse(x, y, 205.0, 400.0, 118.0, 128.0) + 22.0 * value_noise(x, y, 30.0, 880),
                 (70.0, 340.0, 260.0, 540.0), (0.80, 0.74, 0.60), 0.32, soft=14.0)
    for i, (px0, py0, px1, py1) in enumerate(((168, 470, 205, 452), (240, 430, 262, 470), (262, 470, 262, 470))):
        if (px0, py0) != (px1, py1):
            scene.add(lambda x, y, a=(px0, py0, px1, py1): sd_segment(x, y, a[0], a[1], a[2], a[3], 2.4),
                      (min(px0, px1) - 3, max(px0, px1) + 3, min(py0, py1) - 3, max(py0, py1) + 3),
                      lit(BRASS, n_flat, spec=0.4), outline=0.5, shadow=3.0, shadow_soft=1.5)
    gnome_dome(scene, 205.0, 405.0, 54.0)
    # Boiler tank and chimney.
    scene.add(lambda x, y: sd_segment(x, y, 128.0, 470.0, 168.0, 470.0, 11.0), (115, 181, 457, 483),
              lit(COPPER, n_cyl(128.0, 470.0, 1.0, 0.0, 11.0), spec=0.5,
                  pattern=lambda x, y: 0.72 if abs((x - 128.0) % 10.0 - 5.0) < 0.9 else 1.0),
              outline=0.9, shadow=8.0, shadow_soft=2.5)
    scene.ground(lambda x, y: sd_circle(x, y, 268.0, 477.0, 12.0), (250, 286, 460, 496), (0.08, 0.07, 0.06),
                 0.40, soft=7.0)
    scene.add(lambda x, y: sd_circle(x, y, 262.0, 470.0, 8.0), (253, 271, 461, 479),
              lit(IRON, n_dome(262.0, 470.0, 10.0, 10.0), spec=0.5), outline=0.9, shadow=18.0, shadow_soft=3.0)
    scene.add(lambda x, y: sd_circle(x, y, 262.0, 470.0, 4.8), (256, 268, 464, 476), flat((0.05, 0.05, 0.05)),
              outline=0.0)
    striped_canopy(scene, 300.0, 330.0, 20.0, 14.0, (GNOME_BLUE, (0.90, 0.88, 0.80)), stripe=5.0)
    for bx, by, hx, hy in ((132.0, 330.0, 17.0, 6.0), (112.0, 360.0, 6.0, 14.0)):
        scene.add(lambda x, y, bx=bx, by=by, hx=hx, hy=hy: sd_box(x, y, bx, by, hx, hy, 1.0),
                  (bx - hx - 1, bx + hx + 1, by - hy - 1, by + hy + 1),
                  lit(WOOD, n_flat, pattern=lambda x, y: 1.0 - 0.15 * smooth(1.0 - abs((y % 3.0) - 1.5) / 0.4)),
                  outline=0.8, shadow=4.0, shadow_soft=1.5)
    for tx, ty, tr in ((126.0, 331.0, 2.5), (140.0, 328.0, 2.0), (112.0, 366.0, 2.2)):
        scene.add(lambda x, y, tx=tx, ty=ty, tr=tr: sd_circle(x, y, tx, ty, tr), (tx - 3, tx + 3, ty - 3, ty + 3),
                  lit(IRON, n_dome(tx, ty, tr * 1.3, tr * 1.3), spec=0.6), outline=0.4, shadow=1.0)
    gear(scene, 112.0, 432.0, 15.0, 890)
    gear(scene, 136.0, 444.0, 8.0, 891)
    for i, (bx, by) in enumerate(((278.0, 286.0), (290.0, 296.0), (282.0, 300.0))):
        scene.crate(bx, by, 5.0 + i, rot=(SQ3, 0.5) if i % 2 else (1.0, 0.0))
    banner_pole(scene, 292.0, 448.0, GNOME_BLUE, wind=(0.8, 0.6))
    banner_pole(scene, 292.0, 392.0, BRASS, wind=(0.8, 0.6))


def kodo_skeleton(scene, cx, cy):
    """Bleached kodo bones: curved spine, rib pairs, skull with tusks."""
    scene.need(cx, cy, 70.0)
    spine = [(cx - 52.0 + 8.0 * i, cy - 10.0 + 0.9 * i * i - 0.0) for i in range(13)]
    for i, (sx, sy) in enumerate(spine):
        r = 3.2 if 2 < i < 10 else 2.4
        scene.add(lambda x, y, sx=sx, sy=sy, r=r: sd_ellipse(x, y, sx, sy, r * 1.2, r),
                  (sx - r * 1.3, sx + r * 1.3, sy - r, sy + r), lit(BONE, n_dome(sx, sy, r * 1.6, r * 1.4)),
                  outline=0.5, shadow=2.0, shadow_soft=1.5, shadow_alpha=0.26)
    for i in range(3, 10):
        sx, sy = spine[i]
        for side in (-1.0, 1.0):
            reach = 17.0 - abs(i - 6) * 1.6
            ex, ey = sx + 4.0, sy + side * reach
            mx, my = sx + 1.5, sy + side * reach * 0.55
            for (ax, ay, bx, by) in ((sx, sy, mx, my), (mx, my, ex, ey)):
                scene.add(lambda x, y, a=(ax, ay, bx, by): sd_segment(x, y, a[0], a[1], a[2], a[3], 1.3),
                          (min(ax, bx) - 2, max(ax, bx) + 2, min(ay, by) - 2, max(ay, by) + 2),
                          lit(BONE, n_flat), outline=0.45, shadow=2.5, shadow_soft=1.5, shadow_alpha=0.24)
    hx, hy = spine[-1][0] + 10.0, spine[-1][1] + 2.0
    skull = [(hx - 9, hy - 6), (hx + 6, hy - 7), (hx + 12, hy - 2), (hx + 12, hy + 3), (hx + 6, hy + 7),
             (hx - 9, hy + 6)]
    scene.add(lambda x, y: sd_polygon(x, y, skull) - 1.0, (hx - 11, hx + 14, hy - 9, hy + 9),
              lit(BONE, n_dome(hx, hy, 14.0, 10.0), spec=0.2), outline=0.6, shadow=3.0, shadow_soft=1.5)
    for side in (-1.0, 1.0):
        scene.add(lambda x, y, side=side: sd_segment(x, y, hx + 8, hy + side * 5, hx + 20, hy + side * 12, 1.4),
                  (hx + 6, hx + 22, hy - 14, hy + 14), lit(BONE, n_flat), outline=0.4, shadow=3.0)
        scene.add(lambda x, y, side=side: sd_circle(x, y, hx + 1, hy + side * 2.8, 1.6),
                  (hx - 1, hx + 3, hy - 5, hy + 5), flat((0.25, 0.20, 0.16)), outline=0.0)
    for i, (bx, by) in enumerate(((cx - 70, cy - 18), (cx - 64, cy + 20), (cx + 40, cy - 30))):
        scene.add(lambda x, y, bx=bx, by=by: sd_segment(x, y, bx, by, bx + 9, by + 3, 1.6),
                  (bx - 2, bx + 11, by - 2, by + 5), lit(BONE, n_flat), outline=0.45, shadow=2.0)


def wreck(scene, cx, cy):
    """Burnt-out racer: scorch mark, twisted chassis, lost wheel and debris."""
    scene.need(cx, cy, 60.0)
    scene.ground(lambda x, y: sd_ellipse(x, y, cx + 6, cy - 4, 46.0, 30.0) + 16.0 * value_noise(x, y, 9.0, 900),
                 (cx - 70, cx + 70, cy - 50, cy + 50), (0.10, 0.08, 0.07), 0.55, soft=12.0)
    rot = (0.8, 0.6)
    local = rotated(cx, cy, rot)

    def chassis(x, y):
        lx, ly = local(x, y)
        return min(sd_box(lx, ly, 0.0, 0.0, 22.0, 9.0, 2.0), sd_box(lx, ly, -16.0, 0.0, 6.0, 15.0, 2.0))

    def paint(x, y, d):
        n = value_noise(x, y, 4.0, 901)
        base = (0.16, 0.14, 0.13) if n < 0.55 else (mix3(GOB_RED, (0.2, 0.1, 0.08), 0.5) if n < 0.8 else RUST)
        return lit(base, n_dome(cx, cy, 30.0, 30.0, bump=1.2, seed=902), grain=0.12, seed=903)(x, y, d)
    scene.add(chassis, (cx - 30, cx + 30, cy - 30, cy + 30), paint, outline=1.0, shadow=5.0, shadow_soft=2.5)
    wheel(scene, cx + 38.0, cy + 18.0, 6.5, 904)
    wheel(scene, cx - 34.0, cy - 26.0, 5.5, 905)
    for i in range(9):
        h = hash32(i, 5, 906)
        px = cx - 50.0 + 100.0 * (h & 255) / 255.0
        py = cy - 34.0 + 68.0 * ((h >> 8) & 255) / 255.0
        r = 1.5 + 2.5 * ((h >> 16) & 15) / 15.0
        scene.add(lambda x, y, px=px, py=py, r=r: sd_box(x, y, px, py, r, r * 0.6, 0.4),
                  (px - r - 1, px + r + 1, py - r, py + r), lit(IRON if i % 2 else RUST, n_flat), outline=0.4,
                  shadow=1.5, shadow_soft=1.0)


def bleachers(scene, cx, cy, hx, hy, rot):
    """Wooden spectator stands: stepped plank rows, a two-faction banner rail."""
    local = rotated(cx, cy, rot)

    def sdf(x, y):
        lx, ly = local(x, y)
        return sd_box(lx, ly, 0.0, 0.0, hx, hy, 1.0)

    def paint(x, y, d):
        lx, ly = local(x, y)
        row = int(floor((ly + hy) / (2.0 * hy / 6.0)))
        f = (ly + hy) / (2.0 * hy / 6.0) - row
        base = WOOD if row % 2 == 0 else mix3(WOOD, WOOD_DARK, 0.35)
        k = 0.62 + 0.08 * row - 0.25 * smooth((f - 0.75) / 0.25)
        if ly > hy - 3.0:
            base = GOB_RED if lx > 0.0 else GNOME_BLUE
            k = 0.95
        grain = 1.0 + 0.08 * (value_noise(lx * 0.5, ly * 4.0, 2.0, 931) - 0.5)
        return base[0] * k * grain, base[1] * k * grain, base[2] * k * grain
    reach = sqrt(hx * hx + hy * hy) + 2.0
    scene.need(cx, cy, reach)
    scene.add(sdf, (cx - reach, cx + reach, cy - reach, cy + reach), paint, outline=1.0, shadow=10.0,
              shadow_soft=3.0, shadow_alpha=0.36)


def timing_tower(scene, cx, cy, half):
    """Square goblin timing tower: four-plane pyramid roof, pennant, long shadow."""
    planes = {0: unit(0.0, 0.7, 1.0), 1: unit(0.7, 0.0, 1.0), 2: unit(0.0, -0.7, 1.0), 3: unit(-0.7, 0.0, 1.0)}

    def paint(x, y, d):
        dx, dy = x - cx, y - cy
        q = (0 if dy >= abs(dx) else 2 if -dy >= abs(dx) else 1 if dx > 0 else 3)
        n = planes[q]
        k = max(0.0, n[0] * LX + n[1] * LY + n[2] * LZ)
        ring = max(abs(dx), abs(dy))
        tile = 1.0 - 0.14 * smooth(1.0 - abs((ring % 3.0) - 1.5) / 0.45)
        base = RUST if ring > half - 2.2 else GOB_RED
        light = (0.5 + 0.62 * k) * tile
        hip = smooth(1.0 - abs(abs(dx) - abs(dy)) / 0.9)
        light *= 1.0 - 0.35 * hip
        return base[0] * light, base[1] * light, base[2] * light
    scene.need(cx, cy, half * 1.5)
    scene.add(lambda x, y: sd_box(x, y, cx, cy, half, half, 0.8), (cx - half, cx + half, cy - half, cy + half),
              paint, outline=1.0, shadow=22.0, shadow_soft=3.5, shadow_alpha=0.34)
    banner_pole(scene, cx, cy, HAZARD, wind=(0.8, 0.6), length=12.0, clearance=0.0)


def campfire(scene, cx, cy):
    scene.need(cx, cy, 14.0)
    scene.ground(lambda x, y: sd_circle(x, y, cx, cy, 11.0) + 3.0 * value_noise(x, y, 4.0, 941),
                 (cx - 16, cx + 16, cy - 16, cy + 16), (0.12, 0.10, 0.09), 0.45, soft=4.0)
    for i in range(8):
        ux, uy = ((1.0, 0.0), (0.7071, 0.7071), (0.0, 1.0), (-0.7071, 0.7071), (-1.0, 0.0), (-0.7071, -0.7071),
                  (0.0, -1.0), (0.7071, -0.7071))[i]
        scene.rock(cx + ux * 9.0, cy + uy * 9.0, 2.6, 2.2, seed=942 + i, top=0.0)
    scene.add(lambda x, y: sd_circle(x, y, cx, cy, 5.0),
              (cx - 6, cx + 6, cy - 6, cy + 6),
              lambda x, y, d: mix3((0.95, 0.45, 0.10), (1.0, 0.86, 0.45),
                                   smooth(1.0 - sqrt((x - cx) * (x - cx) + (y - cy) * (y - cy)) / 5.0)),
              outline=0.0, soft=2.5)


def fuel_tower(scene, cx, cy, r):
    """Goblin fuel tank on stilts: banded drum, legs, hose, very long shadow."""
    scene.need(cx, cy, r + 30.0)
    for ux, uy in ((0.7071, 0.7071), (-0.7071, 0.7071), (-0.7071, -0.7071), (0.7071, -0.7071)):
        lx, ly = cx + ux * (r + 3.0), cy + uy * (r + 3.0)
        scene.add(lambda x, y, lx=lx, ly=ly: sd_circle(x, y, lx, ly, 2.2), (lx - 3, lx + 3, ly - 3, ly + 3),
                  lit(IRON, n_dome(lx, ly, 3.0, 3.0)), outline=0.4, shadow=26.0, shadow_soft=2.0,
                  shadow_alpha=0.22)

    def paint(x, y, d):
        rr = sqrt((x - cx) * (x - cx) + (y - cy) * (y - cy)) / r
        base = GOB_RED if rr < 0.86 else HAZARD
        if abs(rr - 0.55) < 0.04:
            base = IRON
        if rr < 0.18:
            base = BRASS
        return lit(base, n_dome(cx, cy, r * 1.25, r * 1.25), spec=0.35, grain=0.05, seed=951)(x, y, d)
    scene.add(lambda x, y: sd_circle(x, y, cx, cy, r), (cx - r, cx + r, cy - r, cy + r), paint, outline=1.0,
              shadow=24.0, shadow_soft=4.0, shadow_alpha=0.32)
    scene.add(lambda x, y: sd_segment(x, y, cx - r * 0.7, cy - r * 0.7, cx - r - 14.0, cy - r - 10.0, 1.6),
              (cx - r - 16, cx, cy - r - 12, cy), lit((0.12, 0.12, 0.12), n_flat), outline=0.3, shadow=3.0)


def gyrocopter_crash(scene, cx, cy):
    """Crashed gnomish gyrocopter: blue cockpit, crossed rotor planks, tail boom, scorch."""
    scene.need(cx, cy, 52.0)
    scene.ground(lambda x, y: sd_ellipse(x, y, cx + 4, cy - 6, 30.0, 22.0) + 10.0 * value_noise(x, y, 8.0, 960),
                 (cx - 40, cx + 40, cy - 34, cy + 34), (0.12, 0.10, 0.08), 0.42, soft=9.0)
    scene.add(lambda x, y: sd_segment(x, y, cx, cy, cx + 30.0, cy - 22.0, 2.4),
              (cx - 3, cx + 33, cy - 25, cy + 3), lit(IRON, n_cyl(cx, cy, 0.8, -0.6, 2.4)), outline=0.6,
              shadow=4.0)
    scene.add(lambda x, y: sd_ellipse(x, y, cx, cy, 10.0, 8.0), (cx - 11, cx + 11, cy - 9, cy + 9),
              lit(GNOME_BLUE, n_dome(cx, cy, 11.0, 9.0), spec=0.4), outline=0.9, shadow=5.0)
    scene.add(lambda x, y: sd_circle(x, y, cx + 2.0, cy + 2.0, 3.6), (cx - 2, cx + 6, cy - 2, cy + 6),
              lit(GLASS, n_dome(cx + 2, cy + 2, 4.0, 4.0), spec=0.9), outline=0.4)
    for ax, ay, bx, by in ((-30.0, 8.0, 24.0, -6.0), (-6.0, -26.0, 8.0, 30.0)):
        scene.add(lambda x, y, a=(ax, ay, bx, by): sd_segment(x, y, cx + a[0], cy + a[1], cx + a[2], cy + a[3], 2.6),
                  (cx - 34, cx + 34, cy - 30, cy + 34),
                  lit(WOOD, n_flat,
                      pattern=lambda x, y: 1.0 - 0.12 * smooth((value_noise(x, y, 2.0, 961) - 0.6) / 0.2)),
                  outline=0.7, shadow=4.0, shadow_soft=1.8)
    scene.add(lambda x, y: sd_circle(x, y, cx, cy, 3.0), (cx - 4, cx + 4, cy - 4, cy + 4),
              lit(BRASS, n_dome(cx, cy, 3.5, 3.5), spec=0.6), outline=0.4)


def scatter(scene):
    """Sparse rocks, shrubs and bones across the open flats (away from set pieces)."""
    keep_out = ((892.0, 400.0, 150.0), (205.0, 400.0, 150.0), (530.0, 726.0, 95.0),
                (870.0, 790.0, 85.0), (150.0, 160.0, 80.0), (175.0, 700.0, 80.0), (556.0, 330.0, 50.0),
                (875.0, 150.0, 70.0), (880.0, 620.0, 60.0), (140.0, 880.0, 70.0))
    placed = 0
    for k in range(400):
        h = hash32(k, 11, 950)
        x = 30.0 + 964.0 * (h & 1023) / 1023.0
        y = 30.0 + 964.0 * ((h >> 10) & 1023) / 1023.0
        if min(x, y, SIZE - x, SIZE - y) < 110.0:     # leave the narrow cliff-foot strips clean
            continue
        if any((x - ox) * (x - ox) + (y - oy) * (y - oy) < orr * orr for ox, oy, orr in keep_out):
            continue
        kind = (h >> 20) & 7
        r = 3.5 + 4.0 * ((h >> 23) & 15) / 15.0
        if scene.geo.road_distance(x, y) - r < CLEARANCE + 12.0:
            continue
        if kind < 3:
            scene.rock(x, y, r, r * 0.8, seed=960 + k, top=0.25)
        elif kind < 6:
            scene.shrub(x, y, r * 0.8, seed=960 + k)
        else:
            scene.add(lambda px, py, x=x, y=y, r=r: sd_segment(px, py, x - r, y, x + r, y + r * 0.3, 1.2),
                      (x - r - 2, x + r + 2, y - 2, y + r + 2), lit(BONE, n_flat), outline=0.4, shadow=1.5)
        placed += 1
        if placed >= 30:
            break


def paint_scenery(canvas, geo):
    scene = Scene(geo)
    perimeter(scene)
    scatter(scene)
    wreck(scene, 150.0, 160.0)
    kodo_skeleton(scene, 870.0, 790.0)
    rock_mound(scene)
    gyrocopter_crash(scene, 140.0, 880.0)
    bleachers(scene, 178.0, 700.0, 46.0, 22.0, rot=(0.0, 1.0))
    timing_tower(scene, 556.0, 330.0, 15.0)
    for i, (tx, ty) in enumerate(((850.0, 170.0), (902.0, 132.0), (858.0, 118.0))):
        striped_canopy(scene, tx, ty, 12.0, 9.0, ((0.86, 0.80, 0.66), GOB_RED if i % 2 else GNOME_BLUE),
                       rot=ROT if i % 2 else (1.0, 0.0), stripe=4.0, shadow=6.0)
    campfire(scene, 884.0, 160.0)
    fuel_tower(scene, 880.0, 628.0, 20.0)
    gnome_camp(scene)
    goblin_camp(scene)
    # Start-line poles flank the checkers on purpose: a smaller, explicit clearance.
    banner_pole(scene, 618.0, 360.0, GNOME_BLUE, wind=(0.0, 1.0), length=14.0, clearance=6.0)
    banner_pole(scene, 782.0, 360.0, GOB_RED, wind=(0.0, 1.0), length=14.0, clearance=6.0)
    for i, (x, y) in enumerate(((792.0, 214.0), (800.0, 228.0), (786.0, 228.0), (790.0, 880.0),
                                (802.0, 868.0), (296.0, 214.0), (306.0, 202.0))):
        tire_stack(scene, x, y, 970 + i)
    canvas.touched = bytearray(canvas.columns * canvas.rows)
    for shape in scene.shapes:
        canvas.draw(shape)
    touched, road = canvas.touched, geo.road
    for y in range(SIZE):
        row = (SIZE - 1 - y) * SIZE
        for x in range(SIZE):
            assert not (touched[row + x] and road[y * SIZE + x]), f"scenery painted on road at {(x, y)}"
    return scene


def build(lua, track):
    geo = Geometry(lua, track)
    canvas = Canvas(SIZE, SIZE, 1, 0.0, 0.0, float(SIZE), float(SIZE))
    paint_ground(canvas, geo)
    paint_scenery(canvas, geo)
    return canvas, geo


def encode(canvas):
    pixels = canvas.resolve()
    header = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, SIZE, SIZE, 32, 8)
    body = bytearray()
    for row in reversed(pixels):
        for r, g, b, a in row:
            body += bytes((b, g, r, a))
    return header + bytes(body)


# ---------------------------------------------------------------------------
# Validation: packaging, exact geometry registration and readability.

# Asymmetric world landmarks (x, y, road?) away from markings and scenery.
LANDMARKS = ((340, 780, True), (700, 300, True), (644, 500, True), (755, 500, True), (540, 140, True),
             (340, 243, False), (643, 500, False), (756, 500, False), (100, 100, False), (560, 560, False))
ROAD_MAX_LUMA, RIM_MIN_LUMA = 180.0, 190.0   # interior road vs. 0.5-3 units of salt rim


def quantize(value):
    """Mirror Canvas.resolve() for an opaque single-sample texel."""
    return (int(clamp(value) * 65535 + 0.5) * 255 + 32767) // 65535


def validate(image, canvas, geo):
    fields = struct.unpack("<BBBHHBHHHHBB", image[:18])
    assert fields == (0, 0, 2, 0, 0, 0, 0, 0, SIZE, SIZE, 32, 8), "Unexpected TGA header"
    assert len(image) == 18 + SIZE * SIZE * 4, "Unexpected TGA payload size"
    assert image[21::4] == b"\xff" * (SIZE * SIZE), "Background must be fully opaque"

    def pixel(x, y):
        offset = 18 + (y * SIZE + x) * 4
        b, g, r = image[offset], image[offset + 1], image[offset + 2]
        return r, g, b

    kerbs, _ = geo.bends()
    sites = salt_sites()
    for x, y, expected_road in LANDMARKS:
        p = y * SIZE + x
        assert bool(geo.road[p]) == expected_road == bool(geo.track.isDrivable(x + 0.5, y + 0.5)), \
            f"Review geometry landmark {(x, y)}"
        assert not canvas.touched[(SIZE - 1 - y) * SIZE + x], f"Scenery covers landmark {(x, y)}"
        if expected_road:
            color = road_color(x + 0.5, y + 0.5, geo.lateral[p], geo.along[p], kerbs)
        else:
            edge = abs(geo.lateral[p]) - ROAD_RADIUS
            color = salt_color(x + 0.5, y + 0.5, edge if edge < 22.0 else None, sites)
        assert pixel(x, y) == tuple(quantize(c) for c in color), f"Wrong orientation/registration at {(x, y)}"
    road_max, rim_min, road_n, rim_n = 0.0, 255.0, 0, 0
    for y in range(SIZE):
        for x in range(SIZE):
            p = y * SIZE + x
            lateral = abs(geo.lateral[p])
            if geo.road[p]:
                if lateral > 44.0 or (START_Y0 - 1 <= y <= START_Y1 and START_X0 - 1 <= x <= START_X1):
                    continue
            elif not 0.5 <= lateral - ROAD_RADIUS <= 3.0:
                continue
            r, g, b = pixel(x, y)
            luma = 0.299 * r + 0.587 * g + 0.114 * b
            if geo.road[p]:
                road_max, road_n = max(road_max, luma), road_n + 1
            else:
                rim_min, rim_n = min(rim_min, luma), rim_n + 1
    assert road_max <= ROAD_MAX_LUMA and rim_min >= RIM_MIN_LUMA, \
        f"Road edge contrast too low: road max {road_max:.0f}, rim min {rim_min:.0f}"
    return len(LANDMARKS), road_n, rim_n, road_max, rim_min


# ---------------------------------------------------------------------------
# Review images (not runtime files; PNG bytes depend on the local zlib).

KART = ROOT / "addon" / "AzerothKart" / "Assets" / "Karts" / "GoblinDragCar.tga"
GATES = ((550, 844, 550, 956), (354, 520, 466, 520), (540, 84, 540, 196), (644, 360, 756, 360))


def overview(canvas, factor=2):
    size = SIZE // factor
    rows = []
    for j in range(size):
        row = []
        for i in range(size):
            acc = [0.0, 0.0, 0.0]
            for b in range(factor):
                base = (j * factor + b) * SIZE + i * factor
                for a in range(factor):
                    k = base + a
                    acc[0] += canvas.red[k]
                    acc[1] += canvas.green[k]
                    acc[2] += canvas.blue[k]
            n = factor * factor
            row.append([int(acc[0] / n * 255 + 0.5), int(acc[1] / n * 255 + 0.5), int(acc[2] / n * 255 + 0.5), 255])
        rows.append(row)
    return rows


def play_view(canvas, kart_px, kx, ky, heading, next_gate, width=600, height=360, ui_per_px=4.0 / 3.0):
    """Emulate the scale-1.5 north-up follow camera (60-unit look-ahead) with markers and kart."""
    from math import cos, sin, pi                # preview-only; not part of the asset bytes
    from paintkit import sample_bilinear
    scale = 1.5
    world_per_px = ui_per_px / scale
    view_w, view_h = 800.0 / scale, 480.0 / scale
    cx, cy = kx + 60.0 * cos(heading), ky + 60.0 * sin(heading)
    left = max(0.0, min(SIZE - view_w, cx - view_w / 2))
    bottom = max(0.0, min(SIZE - view_h, cy - view_h / 2))
    top = bottom + view_h
    angle = heading - pi / 2
    ca, sa = cos(angle), sin(angle)
    red, green, blue = canvas.red, canvas.green, canvas.blue
    rows = []
    for oy in range(height):
        wy = top - (oy + 0.5) * world_per_px
        row = []
        for ox in range(width):
            wx = left + (ox + 0.5) * world_per_px
            u, v = wx - 0.5, (SIZE - wy) - 0.5
            x0, y0 = int(floor(u)), int(floor(v))
            fx, fy = u - x0, v - y0
            col = [0.0, 0.0, 0.0]
            for dy, wgt_y in ((0, 1.0 - fy), (1, fy)):
                for dx, wgt_x in ((0, 1.0 - fx), (1, fx)):
                    k = min(max(y0 + dy, 0), SIZE - 1) * SIZE + min(max(x0 + dx, 0), SIZE - 1)
                    w = wgt_x * wgt_y
                    col[0] += red[k] * w * 255.0
                    col[1] += green[k] * w * 255.0
                    col[2] += blue[k] * w * 255.0
            for index, (ax, ay, bx, by) in enumerate(GATES):
                gw = 5.0 if ax == bx else abs(bx - ax)
                gh = 5.0 if ay == by else abs(by - ay)
                gx0, gy0 = (ax + bx - gw) / 2, (ay + by - gh) / 2
                if gx0 <= wx <= gx0 + gw and gy0 <= wy <= gy0 + gh:
                    tint, a = ((250, 237, 115), 0.9) if index == next_gate else ((140, 148, 158), 0.65)
                    col = [col[c] * (1.0 - a) + tint[c] * a for c in range(3)]
            if min(wx, wy, SIZE - wx, SIZE - wy) < 4.0:
                col = [107.0, 112.0, 122.0]
            dx, dy = wx - kx, wy - ky
            lx, ly = dx * ca + dy * sa, -dx * sa + dy * ca
            ku, kv = (lx + 10.0) * 3.2, (20.0 - ly) * 3.2
            if -1.0 < ku < 65.0 and -1.0 < kv < 129.0:
                r, g, b, a = sample_bilinear(kart_px, ku, kv)
                a /= 255.0
                col = [r * a + col[0] * (1.0 - a), g * a + col[1] * (1.0 - a), b * a + col[2] * (1.0 - a)]
            row.append([int(min(255.0, c) + 0.5) for c in col] + [255])
        rows.append(row)
    return rows


def write_previews(canvas):
    from math import pi
    from paintkit import decode_tga, encode_png
    kart_px = decode_tga(KART.read_bytes())[1]
    docs = ROOT / "docs" / "art"
    (docs / "mirage-background-overview.png").write_bytes(encode_png(overview(canvas)))
    shots = ((700.0, 360.0, pi / 2, 3), (380.0, 700.0, -pi / 2, 1), (410.0, 470.0, -pi / 2, 1),
             (470.0, 160.0, -0.2 * pi, 2))
    views = [play_view(canvas, kart_px, *shot) for shot in shots]
    gap = 6
    sheet = []
    for index, pair in enumerate((views[:2], views[2:])):
        if index:
            sheet.extend([[[24, 24, 28, 255]] * (2 * len(views[0][0]) + gap) for _ in range(gap)])
        for y in range(len(pair[0])):
            sheet.append(pair[0][y] + [[24, 24, 28, 255]] * gap + pair[1][y])
    (docs / "mirage-background-views.png").write_bytes(encode_png(sheet))
    return ["docs/art/mirage-background-overview.png", "docs/art/mirage-background-views.png"]


def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--check", action="store_true", help="verify exact bytes without writing")
    parser.add_argument("--preview", action="store_true", help="also write review PNGs under docs/art/")
    args = parser.parse_args()
    lua, track = load_track()
    canvas, geo = build(lua, track)
    image = encode(canvas)
    landmarks, road_n, rim_n, road_max, rim_min = validate(image, canvas, geo)
    if args.check:
        if not OUTPUT.is_file() or OUTPUT.read_bytes() != image:
            raise SystemExit(f"STALE: {OUTPUT.relative_to(ROOT)}; run this script without --check")
    else:
        OUTPUT.parent.mkdir(parents=True, exist_ok=True)
        OUTPUT.write_bytes(image)
    digest = hashlib.sha256(image).hexdigest()
    print(f'{"CHECK PASS" if args.check else "GENERATED"}: {OUTPUT.relative_to(ROOT).as_posix()}; '
          f"{SIZE}x{SIZE} BGRA32 bottom-left; {len(image)} bytes; {landmarks} registration landmarks; "
          f"road interior luma <= {road_max:.0f} ({road_n} px) vs salt rim >= {rim_min:.0f} ({rim_n} px); "
          f"no scenery on road; sha256={digest}")
    if args.preview and not args.check:
        print("PREVIEW:", ", ".join(write_previews(canvas)))


if __name__ == "__main__":
    main()
