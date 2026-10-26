"""Build the results window's celebration art: Celebration.tga.

python scripts/build_celebration_art.py            # write the runtime TGA
python scripts/build_celebration_art.py --check    # verify exact bytes, write nothing
python scripts/build_celebration_art.py --preview  # also write docs/art/ui/celebration.png

Celebration.tga is a 512x256 BGRA32 atlas with alpha, five cells:

- (0, 0) to (256, 256), the rays: a gold sunburst of sixteen soft rays round
  a glow, which the menu turns slowly behind a medal;
- (256, 0) to (384, 128), the gold medal: a gold disc with a bevelled rim
  and a faceted star, hung on two crimson ribbon tails edged in gold;
- (384, 0) to (512, 128), the silver medal, the same in silver;
- (256, 128) to (384, 256), the bronze medal, the same in bronze;
- (384, 128) to (512, 256), the top-ten wreath: a golden laurel wreath round
  a dark disc, tied with a crimson bow, for the menu to write the rank in.

Menu.lua shows them in the results window when a run's personal best lands
on a shared board's top ten (the wreath), top three (a medal) or at #1, and
for a two-player race's first and second places (a gold and a silver medal).
Original art in the style of the client's gold trim; nothing from another
game is used.

Only exact arithmetic (+ - * /, sqrt), decimal constants and integer averaging
feed texel values, so the bytes are the same on every platform: the rays',
star's and leaves' directions come from the table of cosines below, not from
a trigonometric function.
"""
import argparse
import hashlib
from math import sqrt
from pathlib import Path

from paintkit import clamp, decode_tga, encode_png, encode_tga, sd_circle, sd_ellipse, sd_polygon

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "addon" / "AzerothKart" / "Assets" / "UI" / "Celebration.tga"
PREVIEW = ROOT / "docs" / "art" / "ui" / "celebration.png"

WIDTH, HEIGHT = 512, 256
SUPERSAMPLE = 4

# Cells, as Menu.CELEBRATION_COORDS reads them: (x0, y0, size).
RAYS = (0, 0, 256)
GOLD = (256, 0, 128)
SILVER = (384, 0, 128)
BRONZE = (256, 128, 128)
WREATH = (384, 128, 128)

# Cosine and sine of every multiple of 15 degrees up to 90, and of the star's
# 18 and 54 and the rays' 22.5: decimal constants, the same everywhere.
C15, S15 = 0.9659258262890683, 0.25881904510252074
C30, S30 = 0.8660254037844386, 0.5
C45 = 0.7071067811865476
C18, S18 = 0.9510565162951535, 0.3090169943749474
C54, S54 = 0.5877852522924731, 0.8090169943749475
C22, S22 = 0.9238795325112867, 0.3826834323650898
BASE15 = {0: (1.0, 0.0), 15: (C15, S15), 30: (C30, S30), 45: (C45, C45), 60: (S30, C30), 75: (S15, C15)}


def direction15(degrees):
    """(cos, sin) of a multiple of 15 degrees, from the table."""
    degrees %= 360
    quarter, rest = divmod(degrees, 90)
    c, s = BASE15[rest]
    for _ in range(quarter):
        c, s = -s, c
    return c, s


def mix(a, b, t):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def scale(color, k):
    return tuple(c * k for c in color)


# ---------------------------------------------------------------------------
# The rays: sixteen directions, every 22.5 degrees.

RAY_DIRECTIONS = []
for c, s in ((1.0, 0.0), (C22, S22), (C45, C45), (S22, C22)):
    for q in range(4):
        x, y = c, s
        for _ in range(q):
            x, y = -y, x
        RAY_DIRECTIONS.append((x, y))
RAY_EDGE = 0.9950               # a ray's half width: under 6 degrees
RAY_GOLD, RAY_HOT = (255.0, 206.0, 96.0), (255.0, 244.0, 200.0)


def rays(px, py):
    dx, dy = px - 128.0, py - 128.0
    r = sqrt(dx * dx + dy * dy)
    if r >= 126.0:
        return None
    t = r / 126.0
    fade = (1.0 - t) * (1.0 - t)
    ray = 0.0
    if r > 0.0:
        ux, uy = dx / r, dy / r
        best = max(ux * x + uy * y for x, y in RAY_DIRECTIONS)
        ray = clamp((best - RAY_EDGE) / (1.0 - RAY_EDGE))
        ray = ray * ray * (3.0 - 2.0 * ray)
    glow = clamp(1.0 - r / 64.0)
    glow = glow * glow
    alpha = clamp(0.95 * ray * (1.0 - t) + 0.62 * glow)
    if alpha <= 0.0:
        return None
    color = mix(RAY_GOLD, RAY_HOT, clamp(glow * 1.4))
    return color + (alpha,)


# ---------------------------------------------------------------------------
# The medals: a disc, its rim, a faceted star, two ribbon tails.

METALS = {
    "gold": ((255.0, 236.0, 150.0), (224.0, 170.0, 58.0), (128.0, 82.0, 22.0)),
    "silver": ((250.0, 252.0, 255.0), (184.0, 190.0, 202.0), (92.0, 98.0, 112.0)),
    "bronze": ((250.0, 196.0, 140.0), (190.0, 112.0, 56.0), (98.0, 52.0, 22.0)),
}
CX, CY, RADIUS, RIM = 64.0, 50.0, 40.0, 7.0
OUTLINE = (24.0, 14.0, 6.0)
RIBBON, RIBBON_DARK, TRIM = (184.0, 26.0, 32.0), (110.0, 12.0, 18.0), (246.0, 204.0, 96.0)
LIGHT_X, LIGHT_Y = -0.6, -0.8   # toward the light, at the top left (y runs down)

LEFT_TAIL = [(42.0, 66.0), (64.0, 74.0), (52.0, 124.0), (40.0, 112.0), (28.0, 122.0)]
RIGHT_TAIL = [(128.0 - x, y) for x, y in LEFT_TAIL]

# The star: five points up, outer radius 21, inner 8.6.
STAR_OUTER = [(0.0, -1.0), (C18, -S18), (C54, S54), (-C54, S54), (-C18, -S18)]
STAR_INNER = [(C54, -S54), (C18, S18), (0.0, 1.0), (-C18, S18), (-C54, -S54)]
STAR = []
for (ox, oy), (ix, iy) in zip(STAR_OUTER, STAR_INNER):
    STAR.append((CX + ox * 21.0, CY + oy * 21.0))
    STAR.append((CX + ix * 8.6, CY + iy * 8.6))


def tail(px, py, points):
    d = sd_polygon(px, py, points)
    if d > 0.0:
        return None
    if d > -0.9:
        return OUTLINE
    if d > -2.6:
        return TRIM
    # Darker toward the notched end, a fold line down the middle.
    t = clamp((py - 70.0) / 54.0)
    return mix(RIBBON, RIBBON_DARK, t * 0.7)


def medal(px, py, metal):
    light, mid, dark = METALS[metal]
    d = sd_circle(px, py, CX, CY, RADIUS)
    if d > 0.0:
        for points in (LEFT_TAIL, RIGHT_TAIL):
            color = tail(px, py, points)
            if color:
                return color + (1.0,)
        return None
    if d > -1.4:
        return OUTLINE + (1.0,)
    dx, dy = px - CX, py - CY
    r = sqrt(dx * dx + dy * dy)
    nx, ny = (dx / r, dy / r) if r > 0.0 else (0.0, 0.0)
    facing = nx * LIGHT_X + ny * LIGHT_Y           # 1 where it faces the light
    if d > -RIM:
        # The rim: bevelled, bright where it faces the light, a glint.
        shade = 0.5 + 0.5 * facing
        color = mix(dark, light, shade)
        if facing > 0.86:
            color = mix(color, (255.0, 255.0, 255.0), (facing - 0.86) / 0.14 * 0.6)
        return color + (1.0,)
    if d > -RIM - 1.2:
        return scale(dark, 0.8) + (1.0,)               # the rim's inner edge
    s = sd_polygon(px, py, STAR)
    if s <= 0.0:
        if s > -1.1:
            return scale(dark, 0.7) + (1.0,)
        # Facets: which arm (nearest outer point), then its lit or shaded half.
        best, arm = -2.0, 0
        for k, (ox, oy) in enumerate(STAR_OUTER):
            dot = dx * ox + dy * oy
            if dot > best:
                best, arm = dot, k
        ox, oy = STAR_OUTER[arm]
        # Each arm's two facets slope away from its ridge: the one whose
        # slope faces the light is lit.
        fx, fy = (-oy, ox) if ox * dy - oy * dx >= 0.0 else (oy, -ox)
        lit = fx * LIGHT_X + fy * LIGHT_Y
        return mix(mid, light, 0.5 + 0.5 * lit) + (1.0,)
    # The face: a soft dome, lighter toward the light, a fine ring near the rim.
    t = r / (RADIUS - RIM)
    color = mix(mix(mid, light, 0.35), mid, t * t)
    color = mix(color, light, clamp(facing) * 0.25 * t)
    if 28.4 < r < 29.6:
        color = scale(color, 0.82)
    return color + (1.0,)


# ---------------------------------------------------------------------------
# The top-ten wreath: two laurel branches round a dark disc, a bow below.

WX, WY, WR = 64.0, 60.0, 40.0
LEAF_LIGHT, LEAF_MID, LEAF_DARK = (255.0, 232.0, 140.0), (214.0, 160.0, 52.0), (110.0, 70.0, 18.0)
BACKDROP = (22.0, 16.0, 12.0)
# Leaves every 15 degrees (y runs down: 90 is straight down), from the bow up
# each side; each pair one outside the stem, one inside.
LEFT_ANGLES = [105, 120, 135, 150, 165, 180, 195, 210, 225, 240, 255]
RIGHT_ANGLES = [180 - a for a in LEFT_ANGLES]
LEAVES = []
for angle in LEFT_ANGLES + RIGHT_ANGLES:
    c, s = direction15(angle)
    tx, ty = -s, c                                     # along the stem
    for out in (6.6, -5.8):
        LEAVES.append((WX + c * (WR + out), WY + s * (WR + out), tx, ty))


def wreath(px, py):
    dx, dy = px - WX, py - WY
    r = sqrt(dx * dx + dy * dy)
    # The bow: two loops and a knot at the bottom.
    for bx in (54.0, 74.0):
        d = sd_ellipse(px, py, bx, 104.0, 9.0, 5.5)
        if d <= 0.0:
            return (OUTLINE if d > -1.0 else RIBBON) + (1.0,)
    if sd_circle(px, py, 64.0, 104.0, 4.6) <= 0.0:
        return RIBBON_DARK + (1.0,)
    # The leaves, the stem under them.
    for lx, ly, tx, ty in LEAVES:
        ux, uy = px - lx, py - ly
        a, b = ux * tx + uy * ty, -ux * ty + uy * tx       # along and across the leaf
        d = sd_ellipse(a, b, 0.0, 0.0, 10.0, 4.6)
        if d <= 0.0:
            if d > -0.9:
                return OUTLINE + (1.0,)
            shade = clamp(0.55 - 0.45 * (b / 4.6) * (1.0 if ty > 0 else -1.0))
            return mix(LEAF_DARK, LEAF_LIGHT, 0.25 + 0.6 * shade) + (1.0,)
    # The stem: the arc, open at the top.
    if abs(r - WR) < 1.4 and dy > -30.0:
        return LEAF_DARK + (1.0,)
    if r < 31.0:
        return BACKDROP + (0.78 if r < 30.0 else 0.4,)
    return None


# ---------------------------------------------------------------------------


def paint(cell, fn):
    """One cell's texels, supersampled; colour averaged by coverage (straight
    alpha), coverage by count."""
    x0, y0, size = cell
    n = SUPERSAMPLE
    out = {}
    for y in range(size):
        for x in range(size):
            sr = sg = sb = sa = 0.0
            for j in range(n):
                for i in range(n):
                    sample = fn(x + (i + 0.5) / n, y + (j + 0.5) / n)
                    if sample is None:
                        continue
                    r, g, b, a = sample
                    sr, sg, sb, sa = sr + r * a, sg + g * a, sb + b * a, sa + a
            if sa == 0.0:
                continue
            out[(x0 + x, y0 + y)] = (int(sr / sa + 0.5), int(sg / sa + 0.5), int(sb / sa + 0.5),
                                     int(sa * 255 / (n * n) + 0.5))
    return out


def build():
    pixels = [[(0, 0, 0, 0)] * WIDTH for _ in range(HEIGHT)]
    cells = [(RAYS, rays), (GOLD, lambda x, y: medal(x, y, "gold")),
             (SILVER, lambda x, y: medal(x, y, "silver")), (BRONZE, lambda x, y: medal(x, y, "bronze")),
             (WREATH, wreath)]
    for cell, fn in cells:
        for (x, y), value in paint(cell, fn).items():
            pixels[y][x] = value
    return pixels


def validate(pixels):
    assert len(pixels) == HEIGHT and all(len(row) == WIDTH for row in pixels), "512x256 atlas"
    # Each cell keeps a clear border, so bilinear sampling never bleeds a neighbour in.
    for x0, y0, size in (RAYS, GOLD, SILVER, BRONZE, WREATH):
        for k in range(size):
            for x, y in ((x0 + k, y0), (x0 + k, y0 + size - 1), (x0, y0 + k), (x0 + size - 1, y0 + k)):
                assert pixels[y][x][3] == 0, f"cell edge at ({x}, {y}) is clear"
    assert pixels[50][256 + 64][3] == 255 and pixels[50 + 128][256 + 64][3] == 255, "medal discs opaque"
    assert pixels[128][128][3] > 150, "the rays' glow at the centre"


def preview(pixels):
    """The atlas on the results window's dark background, at full size."""
    bg = (20, 18, 16)
    out = []
    for row in pixels:
        line = []
        for r, g, b, a in row:
            line.append(tuple((c * a + bg[i] * (255 - a) + 127) // 255 for i, c in enumerate((r, g, b))) + (255,))
        out.append(line)
    return out


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--check", action="store_true", help="verify the TGA without writing")
    parser.add_argument("--preview", action="store_true", help="also write the review PNG")
    args = parser.parse_args()
    pixels = build()
    validate(pixels)
    data = encode_tga(pixels)
    _, decoded = decode_tga(data)
    assert [tuple(p) for row in decoded for p in row] == [p for row in pixels for p in row], "round trip"
    relative = OUTPUT.relative_to(ROOT).as_posix()
    if args.check:
        if not OUTPUT.is_file() or OUTPUT.read_bytes() != data:
            raise SystemExit(f"STALE: {relative}; run without --check")
        print(f"CHECK PASS: {relative}; {len(data)} bytes; sha256={hashlib.sha256(data).hexdigest()}")
    else:
        OUTPUT.parent.mkdir(parents=True, exist_ok=True)
        OUTPUT.write_bytes(data)
        print(f"WROTE: {relative}; {len(data)} bytes; sha256={hashlib.sha256(data).hexdigest()}")
    if args.preview:
        PREVIEW.parent.mkdir(parents=True, exist_ok=True)
        PREVIEW.write_bytes(encode_png(preview(pixels)))
        print(f"WROTE: {PREVIEW.relative_to(ROOT).as_posix()}")


if __name__ == "__main__":
    main()
