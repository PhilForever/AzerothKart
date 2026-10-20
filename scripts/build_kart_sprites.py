"""Paint the original top-down kart sprites from deterministic procedural code.

python scripts/build_kart_sprites.py             # write the runtime TGA(s)
python scripts/build_kart_sprites.py --check     # verify exact bytes/invariants, write nothing
python scripts/build_kart_sprites.py --preview   # also write review PNGs under docs/art/karts/

Standard library only. Every vehicle is authored as layered signed-distance
shapes in world units (strict overhead view, front = north/up, origin = the
kart's physical center), supersampled, then box-filtered to the runtime size
with exact integer arithmetic. Only IEEE-exact operations (+ - * / sqrt) feed
pixel values, so the bytes are reproducible on any platform; no PRNG, clock,
concept board, screenshot, model or third-party texture is an input.

Runtime format: uncompressed true-color TGA (type 2), 32-bit BGRA with eight
straight (non-premultiplied) alpha bits, bottom-left origin -- the same header
convention as the client-observed Mirage background. Fully transparent texels
carry color bled from their opaque neighbors so bilinear filtering cannot
pull dark or light fringes into the silhouette edge.
"""
import argparse
import array
import hashlib
from math import floor, sqrt  # both exact/correctly rounded under IEEE 754
from pathlib import Path
import struct
import zlib

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "addon" / "AzerothKart" / "Assets" / "Karts"
DOCS = ROOT / "docs" / "art" / "karts"
BACKGROUND = ROOT / "addon" / "AzerothKart" / "Assets" / "Tracks" / "SaltFlats" / "Background.tga"

# Must agree with Presentation.KART_SPRITES (tests cross-check the TGA header
# and footprint against the Lua metadata).
TEXTURE_WIDTH, TEXTURE_HEIGHT = 64, 128      # texels, power-of-two
QUAD_WIDTH, QUAD_HEIGHT = 20.0, 40.0         # world units drawn by the UI quad
FOOTPRINT_WIDTH, FOOTPRINT_HEIGHT = 17.0, 31.0  # opaque body limit, world units
TEXELS_PER_UNIT = TEXTURE_WIDTH / QUAD_WIDTH  # 3.2, uniform in both axes
SUPERSAMPLE = 4                              # 4x4 samples per runtime texel

# ---------------------------------------------------------------------------
# Deterministic math helpers (no transcendental libm calls).


def clamp(value, low=0.0, high=1.0):
    return low if value < low else high if value > high else value


def mix(a, b, t):
    return a + (b - a) * t


def mix3(a, b, t):
    return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t)


def smooth(t):
    t = clamp(t)
    return t * t * (3.0 - 2.0 * t)


def hash2(ix, iy, seed):
    value = (ix * 374761393 + iy * 668265263 + seed * 2246822519 + 1729) & 0xffffffff
    value = ((value ^ (value >> 13)) * 1274126177) & 0xffffffff
    return (value ^ (value >> 16)) & 0xffff


def value_noise(x, y, scale, seed):
    """Smooth lattice noise in [0, 1]; integer hashing + polynomial weights."""
    fx, fy = x / scale, y / scale
    ix, iy = int(fx // 1), int(fy // 1)
    tx, ty = smooth(fx - ix), smooth(fy - iy)
    a = hash2(ix, iy, seed) / 65535.0
    b = hash2(ix + 1, iy, seed) / 65535.0
    c = hash2(ix, iy + 1, seed) / 65535.0
    d = hash2(ix + 1, iy + 1, seed) / 65535.0
    return mix(mix(a, b, tx), mix(c, d, tx), ty)


# ---------------------------------------------------------------------------
# Signed distance functions in world units (negative inside).


def sd_box(px, py, cx, cy, hx, hy, radius=0.0):
    qx = abs(px - cx) - hx + radius
    qy = abs(py - cy) - hy + radius
    ox, oy = max(qx, 0.0), max(qy, 0.0)
    return sqrt(ox * ox + oy * oy) + min(max(qx, qy), 0.0) - radius


def sd_circle(px, py, cx, cy, radius):
    dx, dy = px - cx, py - cy
    return sqrt(dx * dx + dy * dy) - radius


def sd_ellipse(px, py, cx, cy, rx, ry):
    # Scaled-circle approximation; exact on the axes, adequate for small parts.
    dx, dy = (px - cx) / rx, (py - cy) / ry
    return (sqrt(dx * dx + dy * dy) - 1.0) * (rx if rx < ry else ry)


def sd_segment(px, py, ax, ay, bx, by, radius):
    pax, pay, bax, bay = px - ax, py - ay, bx - ax, by - ay
    h = clamp((pax * bax + pay * bay) / (bax * bax + bay * bay))
    dx, dy = pax - bax * h, pay - bay * h
    return sqrt(dx * dx + dy * dy) - radius


def sd_polygon(px, py, points):
    """Exact distance to a simple polygon (sign from the even-odd rule)."""
    first = points[0]
    dx, dy = px - first[0], py - first[1]
    best = dx * dx + dy * dy
    sign = 1.0
    count = len(points)
    j = count - 1
    for i in range(count):
        vix, viy = points[i]
        vjx, vjy = points[j]
        ex, ey = vjx - vix, vjy - viy
        wx, wy = px - vix, py - viy
        h = clamp((wx * ex + wy * ey) / (ex * ex + ey * ey))
        bx, by = wx - ex * h, wy - ey * h
        dist = bx * bx + by * by
        if dist < best:
            best = dist
        c1 = py >= viy
        c2 = py < vjy
        c3 = ex * wy > ey * wx
        if (c1 and c2 and c3) or (not c1 and not c2 and not c3):
            sign = -sign
        j = i
    return sign * sqrt(best)


# ---------------------------------------------------------------------------
# Layered painter.

INK = (0.07, 0.045, 0.035)  # warm near-black contour shared by every part


class Shape:
    """One painted part: geometry, material and an inner contour stroke."""

    def __init__(self, sdf, bbox, paint, outline=0.0, ink=INK, opacity=1.0):
        self.sdf, self.bbox, self.paint = sdf, bbox, paint
        self.outline, self.ink, self.opacity = outline, ink, opacity


class Canvas:
    """Premultiplied supersampled RGBA accumulation over the sprite quad.

    `width`/`height` are output texels covering QUAD_WIDTH x QUAD_HEIGHT world
    units; each texel receives SUPERSAMPLE x SUPERSAMPLE samples.
    """

    def __init__(self, width=TEXTURE_WIDTH, height=TEXTURE_HEIGHT, supersample=SUPERSAMPLE):
        assert width * QUAD_HEIGHT == height * QUAD_WIDTH, "texels must stay square in world units"
        self.width, self.height, self.supersample = width, height, supersample
        self.columns = width * supersample
        self.rows = height * supersample
        size = self.columns * self.rows
        self.red = array.array("d", bytes(8 * size))
        self.green = array.array("d", bytes(8 * size))
        self.blue = array.array("d", bytes(8 * size))
        self.alpha = array.array("d", bytes(8 * size))
        self.step = QUAD_WIDTH / self.columns  # world units per sample
        # Sample centers: column 0 is the left edge, row 0 is the top (front).
        self.xs = [(c + 0.5) * self.step - QUAD_WIDTH / 2 for c in range(self.columns)]
        self.ys = [QUAD_HEIGHT / 2 - (r + 0.5) * self.step for r in range(self.rows)]

    def draw(self, shape):
        xmin, xmax, ymin, ymax = shape.bbox
        step = self.step
        pad = 2 * step + shape.outline
        c0 = max(0, int((xmin - pad + QUAD_WIDTH / 2) / step))
        c1 = min(self.columns, int((xmax + pad + QUAD_WIDTH / 2) / step) + 1)
        r0 = max(0, int((QUAD_HEIGHT / 2 - ymax - pad) / step))
        r1 = min(self.rows, int((QUAD_HEIGHT / 2 - ymin + pad) / step) + 1)
        sdf, paint = shape.sdf, shape.paint
        outline, ink, opacity = shape.outline, shape.ink, shape.opacity
        red, green, blue, alpha = self.red, self.green, self.blue, self.alpha
        xs, ys, columns = self.xs, self.ys, self.columns
        # Coverage ramps across one sample; the box filter in resolve() then
        # anti-aliases each output texel. Contour widths stay in world units.
        inv = 1.0 / step
        for r in range(r0, r1):
            y = ys[r]
            base = r * columns
            for c in range(c0, c1):
                x = xs[c]
                d = sdf(x, y)
                coverage = 0.5 - d * inv
                if coverage <= 0.0:
                    continue
                if coverage > 1.0:
                    coverage = 1.0
                cr, cg, cb = paint(x, y, d)
                if outline > 0.0:
                    k = (d + outline) * inv + 0.5
                    if k > 0.0:
                        if k > 1.0:
                            k = 1.0
                        cr += (ink[0] - cr) * k
                        cg += (ink[1] - cg) * k
                        cb += (ink[2] - cb) * k
                a = coverage * opacity
                keep = 1.0 - a
                i = base + c
                red[i] = clamp(cr) * a + red[i] * keep
                green[i] = clamp(cg) * a + green[i] * keep
                blue[i] = clamp(cb) * a + blue[i] * keep
                alpha[i] = a + alpha[i] * keep

    def resolve(self):
        """Exact box filter to output texels; returns top-down [r, g, b, a] rows.

        Samples are quantized to integers before summing, so the result does
        not depend on floating-point summation order.
        """
        scale = 65535
        ss = self.supersample
        samples = ss * ss
        pixels = []
        for j in range(self.height):
            row = []
            for i in range(self.width):
                sr = sg = sb = sa = 0
                for b in range(ss):
                    base = (j * ss + b) * self.columns + i * ss
                    for a in range(ss):
                        k = base + a
                        sr += int(self.red[k] * scale + 0.5)
                        sg += int(self.green[k] * scale + 0.5)
                        sb += int(self.blue[k] * scale + 0.5)
                        sa += int(self.alpha[k] * scale + 0.5)
                alpha8 = (sa * 255 + samples * scale // 2) // (samples * scale)
                if alpha8 == 0:
                    row.append([0, 0, 0, 0])
                    continue
                row.append([min(255, (sr * 255 + sa // 2) // sa),
                            min(255, (sg * 255 + sa // 2) // sa),
                            min(255, (sb * 255 + sa // 2) // sa), alpha8])
            pixels.append(row)
        return pixels


def bleed(pixels):
    """Give transparent texels the mean color of already-colored neighbors.

    Straight-alpha bilinear filtering blends RGB independently of alpha, so a
    black transparent surround would darken the anti-aliased edge (and an
    unrelated color would tint it). Alpha stays exactly zero.
    """
    height, width = len(pixels), len(pixels[0])
    known = [[pixels[j][i][3] > 0 for i in range(width)] for j in range(height)]
    frontier = True
    while frontier:
        frontier = []
        for j in range(height):
            for i in range(width):
                if known[j][i]:
                    continue
                total = [0, 0, 0]
                count = 0
                for dj in (-1, 0, 1):
                    for di in (-1, 0, 1):
                        y, x = j + dj, i + di
                        if 0 <= y < height and 0 <= x < width and known[y][x]:
                            pixel = pixels[y][x]
                            total[0] += pixel[0]
                            total[1] += pixel[1]
                            total[2] += pixel[2]
                            count += 1
                if count:
                    frontier.append((j, i, [(total[0] + count // 2) // count,
                                            (total[1] + count // 2) // count,
                                            (total[2] + count // 2) // count, 0]))
        for j, i, value in frontier:
            pixels[j][i] = value
            known[j][i] = True
    return pixels


# ---------------------------------------------------------------------------
# Materials.


def shaded(base, form, light=0.55, dark=0.45, spec=0.0, spec_width=0.25, grime=0.0, seed=1,
           grime_scale=1.2, rim=0.0, rim_depth=(0.25, 0.6), rust=None, shadow=None,
           mottle=0.10, sheen=(1.0, 0.97, 0.88)):
    """Overhead material: diffuse form factor, centered highlight, painted wear.

    Lighting is neutral and straight down, so a rotated sprite never shows a
    light direction that disagrees with the scene. `shadow` is the hue the
    form falls off toward (warm for paint, cool for chrome), `mottle` a broad
    brush-like value variation, `grime` a fine one. `rim` brightens a thin
    band just inside the contour (a painted bevel catch-light) and
    `rust=(color, amount, scale, seed)` mixes worn patches into the paint.
    """
    br, bg, bb = base
    rim0, rim1 = rim_depth
    sr, sg, sb = shadow if shadow is not None else (br * 0.25, bg * 0.2, bb * 0.2)
    hr, hg, hb = sheen

    def paint(x, y, d):
        f, n = form(x, y, d)
        k = dark + light * f
        r, g, b = br * k, bg * k, bb * k
        fall = (1.0 - f) * 0.6
        r, g, b = r + (sr - r) * fall, g + (sg - g) * fall, b + (sb - b) * fall
        if rust is not None:
            color, amount, scale, rust_seed = rust
            t = smooth((value_noise(x, y, scale, rust_seed) - (1.0 - amount)) / 0.12)
            if t > 0.0:
                r, g, b = mix(r, color[0] * k, t), mix(g, color[1] * k, t), mix(b, color[2] * k, t)
        if spec > 0.0:
            s = 1.0 - abs(n) / spec_width
            if s > 0.0:
                s = s * s * spec
                r, g, b = r + (hr - r) * s, g + (hg - g) * s, b + (hb - b) * s
        if rim > 0.0:
            depth = -d
            if rim0 < depth < rim1:
                t = 1.0 - abs((depth - rim0) / (rim1 - rim0) * 2.0 - 1.0)
                t = smooth(t) * rim
                r, g, b = r + (hr - r) * t, g + (hg - g) * t, b + (hb - b) * t
        v = 1.0
        if mottle > 0.0:
            v += mottle * (value_noise(x, y, 2.6, seed + 101) - 0.5) * 2.0
        if grime > 0.0:
            v += grime * (value_noise(x, y, grime_scale, seed) - 0.5)
        return r * v, g * v, b * v
    return paint


def cyl_x(cx, rx):
    """Cylinder whose axis runs north-south: shading varies across x."""
    def form(x, y, d):
        n = (x - cx) / rx
        return sqrt(max(0.0, 1.0 - n * n)), n
    return form


def cyl_y(cy, ry):
    """Cylinder whose axis runs east-west: shading varies across y."""
    def form(x, y, d):
        n = (y - cy) / ry
        return sqrt(max(0.0, 1.0 - n * n)), n
    return form


def dome(cx, cy, rx, ry):
    def form(x, y, d):
        dx, dy = (x - cx) / rx, (y - cy) / ry
        n2 = dx * dx + dy * dy
        return sqrt(max(0.0, 1.0 - n2)), sqrt(n2)
    return form


def bevel(width):
    """Flat plate whose edges fall away: bright interior, darker rim."""
    def form(x, y, d):
        t = clamp(-d / width)
        return smooth(t), 1.0 - t
    return form


def fins(pitch, depth, width=0.28, axis="y", origin=0.0):
    """Triangle-wave grooves (cooling fins, tread) multiplied into a material."""
    def factor(x, y):
        t = ((y if axis == "y" else x) - origin) / pitch
        t = abs(t - floor(t + 0.5)) * 2.0          # 0 mid-block, 1 at a groove
        return 1.0 - depth * smooth((t - (1.0 - 2.0 * width)) / (2.0 * width))
    return factor


def patterned(paint, factor):
    def wrapped(x, y, d):
        r, g, b = paint(x, y, d)
        k = factor(x, y)
        return r * k, g * k, b * k
    return wrapped


def glow(dark, hot, cx, cy, radius, ember=(0.95, 0.38, 0.06)):
    """Dark opening with an ember ring and a white-hot center (stacks, nozzle)."""
    def paint(x, y, d):
        dx, dy = x - cx, y - cy
        t = 1.0 - sqrt(dx * dx + dy * dy) / radius
        if t <= 0.0:
            return dark
        warm = mix3(dark, ember, smooth(t / 0.45))
        return mix3(warm, hot, smooth((t - 0.45) / 0.45))
    return paint


def flat(color):
    return lambda x, y, d: color


# ---------------------------------------------------------------------------
# Shape constructors (world units; +y is the vehicle front / north).


def box(cx, cy, hx, hy, radius, paint, outline=0.3, **kw):
    return Shape(lambda x, y: sd_box(x, y, cx, cy, hx, hy, radius),
                 (cx - hx, cx + hx, cy - hy, cy + hy), paint, outline, **kw)


def circle(cx, cy, radius, paint, outline=0.2, **kw):
    return Shape(lambda x, y: sd_circle(x, y, cx, cy, radius),
                 (cx - radius, cx + radius, cy - radius, cy + radius), paint, outline, **kw)


def ellipse(cx, cy, rx, ry, paint, outline=0.2, **kw):
    return Shape(lambda x, y: sd_ellipse(x, y, cx, cy, rx, ry),
                 (cx - rx, cx + rx, cy - ry, cy + ry), paint, outline, **kw)


def segment(ax, ay, bx, by, radius, paint, outline=0.2, **kw):
    return Shape(lambda x, y: sd_segment(x, y, ax, ay, bx, by, radius),
                 (min(ax, bx) - radius, max(ax, bx) + radius,
                  min(ay, by) - radius, max(ay, by) + radius), paint, outline, **kw)


def polygon(points, paint, outline=0.3, rounding=0.0, **kw):
    xs, ys = [p[0] for p in points], [p[1] for p in points]
    return Shape(lambda x, y: sd_polygon(x, y, points) - rounding,
                 (min(xs) - rounding, max(xs) + rounding, min(ys) - rounding, max(ys) + rounding),
                 paint, outline, **kw)


def clipped(shape, clip):
    """Intersect a shape with another signed-distance region (max of SDFs)."""
    sdf = shape.sdf
    return Shape(lambda x, y: max(sdf(x, y), clip(x, y)), shape.bbox, shape.paint,
                 shape.outline, shape.ink, shape.opacity)


def mirrored(make):
    """Build a symmetric pair from a constructor taking a side sign (-1, +1)."""
    return [make(-1.0), make(1.0)]


# ---------------------------------------------------------------------------
# Palette: Warcraft III-flavored goblin workshop colors.

GOBLIN_RED = (0.76, 0.15, 0.09)
RUST = (0.42, 0.20, 0.10)
HAZARD = (0.98, 0.77, 0.15)
BRASS = (0.88, 0.64, 0.25)
CHROME = (0.76, 0.78, 0.82)
GUNMETAL = (0.33, 0.32, 0.34)
IRON = (0.24, 0.23, 0.24)
RUBBER = (0.14, 0.13, 0.125)
SKIN = (0.47, 0.78, 0.20)
EAR = (0.62, 0.48, 0.30)
LEATHER = (0.58, 0.35, 0.16)
LENS = (0.55, 0.92, 0.90)
SOOT = (0.06, 0.045, 0.04)
EMBER = (1.00, 0.62, 0.14)
EMBER_CORE = (1.00, 0.90, 0.55)


def goblin_drag_car():
    """Original overhead goblin dragster: giant blown engine, rocket, tiny pilot.

    Silhouette, front to back: iron ram and long red nose on a narrow front
    axle; open cockpit with a big-eared goblin between two explosive fuel
    canisters; an oversized supercharged engine flanked by huge slicks; a
    rocket bell glowing at the rear. The narrow front versus wide, heavy rear
    keeps the heading readable at small sizes and under rotation.
    """
    s = []
    paint_rust = (RUST, 0.22, 0.9, 41)

    # Axles first: everything else sits on them.
    s.append(segment(-6.0, -9.6, 6.0, -9.6, 0.38, shaded(IRON, cyl_y(-9.6, 0.38), spec=0.3)))
    s.append(segment(-5.2, 10.9, 5.2, 10.9, 0.3, shaded(IRON, cyl_y(10.9, 0.3), spec=0.3)))

    # Huge rear slicks and small front wheels (tread seen from directly above).
    def tyre(side, cx, cy, hx, hy, radius, pitch, outline):
        x0 = side * cx
        paint = patterned(shaded(RUBBER, cyl_x(x0, hx), light=0.95, dark=0.25, spec=0.16,
                                 spec_width=0.28, grime=0.25, seed=11, rim=0.1,
                                 shadow=(0.02, 0.02, 0.025), sheen=(0.55, 0.55, 0.6)),
                          fins(pitch, 0.5, 0.22, "y", cy))
        return box(x0, cy, hx, hy, radius, paint, outline)
    s += mirrored(lambda side: tyre(side, 6.6, -9.6, 1.75, 4.9, 1.0, 0.95, 0.4))
    s += mirrored(lambda side: tyre(side, 5.55, 10.9, 0.95, 1.75, 0.6, 0.9, 0.32))

    # Rocket booster bell behind the engine, its hot lip facing rearward.
    bell = [(-1.9, -12.4), (1.9, -12.4), (2.85, -15.3), (-2.85, -15.3)]
    s.append(polygon(bell, shaded(IRON, cyl_x(0.0, 2.9), light=0.75, dark=0.35, spec=0.35,
                                  spec_width=0.3, grime=0.3, seed=5, rim=0.18), outline=0.34))
    for hx, cy in ((2.15, -12.95), (2.6, -14.25)):
        band = shaded(BRASS, cyl_x(0.0, hx), light=0.7, dark=0.35, spec=0.5)
        s.append(box(0.0, cy, hx, 0.24, 0.12, band, outline=0.1))
    s.append(box(0.0, -15.0, 2.55, 0.26, 0.2, glow(SOOT, EMBER_CORE, 0.0, -15.0, 2.5), outline=0.0))

    # Oversized engine block with rows of open, glowing exhaust stacks.
    s.append(box(0.0, -7.1, 4.35, 5.6, 1.0,
                 shaded(GUNMETAL, bevel(1.4), light=0.65, dark=0.45, grime=0.3, seed=3, rim=0.25,
                        rim_depth=(0.45, 0.85)), outline=0.42))
    for side in (-1.0, 1.0):
        s.append(box(side * 3.45, -6.55, 0.95, 4.25, 0.45,
                     shaded(GUNMETAL, cyl_x(side * 3.45, 1.0), light=0.8, dark=0.4, spec=0.25,
                            spec_width=0.3, grime=0.25, seed=29), outline=0.2))
        for cy in (-3.25, -5.45, -7.65, -9.85):
            cx = side * 3.45
            s.append(segment(cx, cy, cx, cy - 1.1, 0.62, flat(SOOT), outline=0.0, opacity=0.45))
            s.append(circle(cx, cy, 0.64, glow(SOOT, EMBER_CORE, cx, cy, 0.62), outline=0.22,
                            ink=BRASS))
    for cx, cy in ((-3.4, -12.0), (3.4, -12.0), (-3.4, -2.0), (3.4, -2.0)):
        s.append(circle(cx, cy, 0.24, shaded(BRASS, dome(cx, cy, 0.24, 0.24), spec=0.6),
                        outline=0.08))

    # Chrome supercharger with cooling fins, red scoop facing forward.
    s.append(box(0.0, -6.3, 2.25, 4.05, 0.55,
                 patterned(shaded(CHROME, cyl_x(0.0, 2.3), light=0.7, dark=0.35, spec=0.6,
                                  spec_width=0.3, grime=0.15, seed=7),
                           fins(0.72, 0.42, 0.25, "y", -6.3)), outline=0.32))
    s.append(box(0.0, -2.05, 1.95, 1.0, 0.45,
                 shaded(GOBLIN_RED, bevel(0.6), light=0.6, dark=0.5, grime=0.25, seed=9, rim=0.3,
                        rim_depth=(0.25, 0.55)), outline=0.3))
    s.append(box(0.0, -1.32, 1.45, 0.24, 0.12, flat(SOOT), outline=0.0))

    # Long nose with a hazard racing stripe, rivets and an iron ram tip.
    nose = [(-2.2, 5.4), (2.2, 5.4), (1.6, 11.6), (0.8, 13.5), (-0.8, 13.5), (-1.6, 11.6)]
    s.append(polygon(nose, shaded(GOBLIN_RED, cyl_x(0.0, 2.3), light=0.65, dark=0.42,
                                  spec=0.3, spec_width=0.22, grime=0.3, seed=13,
                                  rust=paint_rust), outline=0.36))
    s.append(clipped(box(0.0, 9.6, 0.55, 4.2, 0.0,
                         shaded(HAZARD, cyl_x(0.0, 2.3), light=0.55, dark=0.5, grime=0.2,
                                seed=17), outline=0.0),
                     lambda x, y: sd_polygon(x, y, nose) + 0.34))
    for side in (-1.0, 1.0):
        for cy, cx in ((6.6, 1.55), (8.4, 1.4), (10.2, 1.25)):
            s.append(circle(side * cx, cy, 0.2, shaded(BRASS, dome(side * cx, cy, 0.2, 0.2),
                                                       spec=0.6), outline=0.07))
    s.append(polygon([(-0.85, 13.2), (0.85, 13.2), (0.0, 15.35)],
                     shaded(IRON, cyl_x(0.0, 0.9), light=0.85, dark=0.35, spec=0.6), outline=0.28))

    # Cockpit tub and the strapped-on explosive fuel canisters.
    tub = [(-2.75, -0.3), (2.75, -0.3), (2.15, 5.8), (-2.15, 5.8)]
    s.append(polygon(tub, shaded(GOBLIN_RED, bevel(1.0), light=0.6, dark=0.5, grime=0.3,
                                 seed=19, rim=0.25, rim_depth=(0.35, 0.7), rust=paint_rust),
                     outline=0.4, rounding=0.5))

    def canister(side):
        cx = side * 3.95
        body = shaded(GOBLIN_RED, cyl_x(cx, 0.8), light=0.7, dark=0.38, spec=0.4,
                      spec_width=0.3, grime=0.2, seed=23)
        band = shaded(HAZARD, cyl_x(cx, 0.8), light=0.7, dark=0.38, spec=0.3)
        cap = shaded(BRASS, cyl_x(cx, 0.8), light=0.75, dark=0.32, spec=0.5)

        def paint(x, y, d):
            if 2.3 < y < 3.1:
                return band(x, y, d)
            if y > 4.8 or y < 0.1:
                return cap(x, y, d)
            return body(x, y, d)
        return segment(cx, 0.75, cx, 4.95, 0.8, paint, outline=0.32)
    s += mirrored(canister)

    # Roll bar between the cockpit and the engine.
    s.append(segment(-3.1, -0.55, 3.1, -0.55, 0.42, shaded(IRON, cyl_y(-0.55, 0.42), spec=0.5),
                     outline=0.18))

    # Seat well and the goblin pilot: bald green head, brass goggles pushed up,
    # long nose and the oversized ears that make the silhouette a goblin.
    s.append(ellipse(0.0, 2.45, 1.85, 2.5, shaded((0.22, 0.13, 0.08), bevel(0.8), light=0.45,
                                                  dark=0.35), outline=0.18))
    s.append(ellipse(0.0, 1.0, 1.85, 1.0, shaded(LEATHER, dome(0.0, 1.0, 1.85, 1.0), light=0.6,
                                                 dark=0.45, spec=0.15), outline=0.2))

    def ear(side):
        pts = [(side * 0.85, 3.3), (side * 4.05, 1.95), (side * 1.0, 1.6)]
        return polygon(pts, shaded(SKIN, bevel(0.45), light=0.5, dark=0.6, rim=0.2,
                                   rim_depth=(0.12, 0.3)), outline=0.18)

    def inner_ear(side):
        pts = [(side * 1.15, 2.85), (side * 3.2, 2.02), (side * 1.2, 2.0)]
        return polygon(pts, flat(mix3(SKIN, EAR, 0.65)), outline=0.0)
    # Leather sleeves reach a small iron steering wheel.
    s += mirrored(lambda side: segment(side * 1.35, 1.25, side * 0.95, 3.85, 0.38,
                                       shaded(LEATHER, cyl_x(side * 1.15, 0.5), light=0.6,
                                              dark=0.45), outline=0.16))
    s.append(Shape(lambda x, y: abs(sd_circle(x, y, 0.0, 4.35, 0.78)) - 0.16,
                   (-0.95, 0.95, 3.4, 5.3), shaded(IRON, bevel(0.15), light=0.6, dark=0.5),
                   outline=0.0))
    s += mirrored(lambda side: circle(side * 0.78, 4.12, 0.3,
                                      shaded(SKIN, dome(side * 0.78, 4.12, 0.3, 0.3)),
                                      outline=0.12))
    s += mirrored(ear)
    s += mirrored(inner_ear)
    # Head last: goggle strap, glassy lenses and the pointed goblin nose on top.
    head = shaded(SKIN, dome(0.0, 2.4, 1.3, 1.3), light=0.6, dark=0.45, spec=0.3, spec_width=0.45)
    s.append(circle(0.0, 2.4, 1.3, head, outline=0.22))
    s.append(box(0.0, 2.95, 1.25, 0.16, 0.08, flat((0.20, 0.12, 0.07)), outline=0.0))
    s += mirrored(lambda side: circle(side * 0.52, 2.98, 0.44,
                                      shaded(LENS, dome(side * 0.52, 2.98, 0.44, 0.44), light=0.5,
                                             dark=0.55, spec=0.9, spec_width=0.55),
                                      outline=0.15, ink=BRASS))
    s.append(polygon([(-0.3, 3.55), (0.3, 3.55), (0.0, 4.45)],
                     shaded(SKIN, bevel(0.25), light=0.5, dark=0.6), outline=0.13))
    return s


# ---------------------------------------------------------------------------
# Roster: runtime file name -> painter. Add new karts here and register the
# same file in Presentation.KART_SPRITES.

KARTS = {
    "goblin_drag_car": ("GoblinDragCar.tga", "goblin-drag-car", goblin_drag_car),
}


def render(painter, width=TEXTURE_WIDTH, height=TEXTURE_HEIGHT):
    canvas = Canvas(width, height)
    for shape in painter():
        canvas.draw(shape)
    return bleed(canvas.resolve())


def encode_tga(pixels):
    """Type-2 BGRA32, eight alpha bits, bottom-left origin (descriptor 0x08)."""
    height, width = len(pixels), len(pixels[0])
    header = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, width, height, 32, 8)
    body = bytearray()
    for row in reversed(pixels):  # file rows run bottom to top
        for red, green, blue, alpha in row:
            body += bytes((blue, green, red, alpha))
    return header + bytes(body)


def decode_tga(image):
    """Inverse of encode_tga for validation; returns top-down [r, g, b, a] rows."""
    fields = struct.unpack("<BBBHHBHHHHBB", image[:18])
    width, height = fields[8], fields[9]
    pixels = []
    for row in range(height - 1, -1, -1):
        offset = 18 + row * width * 4
        line = []
        for i in range(width):
            blue, green, red, alpha = image[offset + 4 * i:offset + 4 * i + 4]
            line.append([red, green, blue, alpha])
        pixels.append(line)
    return fields, pixels


def validate(image):
    """Packaging, footprint, pivot, orientation and edge-color invariants."""
    fields, px = decode_tga(image)
    assert fields == (0, 0, 2, 0, 0, 0, 0, 0, TEXTURE_WIDTH, TEXTURE_HEIGHT, 32, 8), \
        "Unexpected TGA header"
    assert len(image) == 18 + TEXTURE_WIDTH * TEXTURE_HEIGHT * 4, "Unexpected TGA payload size"
    w, h = TEXTURE_WIDTH, TEXTURE_HEIGHT
    half_w = FOOTPRINT_WIDTH * TEXELS_PER_UNIT / 2
    half_h = FOOTPRINT_HEIGHT * TEXELS_PER_UNIT / 2
    opaque = solid = 0
    left, right, top, bottom = w, -1, h, -1
    for j in range(h):
        for i in range(w):
            a = px[j][i][3]
            if a == 0:
                continue
            # Nothing may be drawn outside the 17x31 body: the art cannot
            # visually exceed the clearance the perimeter collision assumes.
            assert abs(i + 0.5 - w / 2) <= half_w and abs(j + 0.5 - h / 2) <= half_h, \
                f"texel {(i, j)} is outside the kart footprint"
            assert 0 < i < w - 1 and 0 < j < h - 1, "border texels must stay transparent"
            opaque += 1
            solid += a == 255
            left, right = min(left, i), max(right, i)
            top, bottom = min(top, j), max(bottom, j)
    footprint_texels = 4 * half_w * half_h
    assert solid > 0.4 * footprint_texels, "silhouette unexpectedly sparse"
    # Pivot: the visible body is centered on the texture (and kart) center.
    assert abs((left + right + 1) / 2 - w / 2) <= 0.5, "silhouette not centered horizontally"
    assert abs((top + bottom + 1) / 2 - h / 2) <= 1.0, "silhouette not centered vertically"
    for j in range(h):
        for i in range(w // 2):
            assert abs(px[j][i][3] - px[j][w - 1 - i][3]) <= 2, "alpha must be mirror-symmetric"
    # North-facing landmarks: a narrow pointed nose at the top, wide rear
    # slicks at the bottom. A flipped or rotated export fails here.
    center = w // 2
    assert px[16][center][3] > 0 and px[16][center - 1][3] > 0, "nose tip must point north"
    assert all(px[j][i][3] == 0 for j in range(15, 22) for i in range(5, 22)), \
        "front corners must stay open (narrow nose)"
    assert px[96][8][3] == 255 and px[96][w - 9][3] == 255, "wide rear slicks must sit south"
    # Straight-alpha edge color: each transparent texel bordering the body
    # carries color within the range of its visible neighbors.
    for j in range(h):
        for i in range(w):
            if px[j][i][3]:
                continue
            near = [px[y][x] for y in range(max(0, j - 1), min(h, j + 2))
                    for x in range(max(0, i - 1), min(w, i + 2)) if px[y][x][3]]
            if near:
                for c in range(3):
                    values = [n[c] for n in near]
                    assert min(values) <= px[j][i][c] <= max(values), "edge color not bled"
    return opaque, solid, (left, top, right, bottom)


# ---------------------------------------------------------------------------
# Review artifacts (not runtime files; PNG bytes depend on the local zlib).


def encode_png(pixels):
    height, width = len(pixels), len(pixels[0])
    raw = bytearray()
    for row in pixels:
        raw.append(0)
        for value in row:
            raw += bytes(value[:4])

    def chunk(kind, data):
        return (struct.pack(">I", len(data)) + kind + data +
                struct.pack(">I", zlib.crc32(kind + data) & 0xffffffff))
    return (b"\x89PNG\r\n\x1a\n" +
            chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)) +
            chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + chunk(b"IEND", b""))


def sample_bilinear(px, u, v):
    """Straight-alpha bilinear fetch with transparent clamp-to-border.

    RGB and alpha are filtered independently, as the client's fixed-function
    texture units do, so the preview exposes any unbled edge fringe.
    """
    h, w = len(px), len(px[0])
    x0, y0 = int(floor(u - 0.5)), int(floor(v - 0.5))
    fx, fy = u - 0.5 - x0, v - 0.5 - y0
    out = [0.0, 0.0, 0.0, 0.0]
    for dy, wy in ((0, 1.0 - fy), (1, fy)):
        for dx, wx in ((0, 1.0 - fx), (1, fx)):
            x, y = min(max(x0 + dx, 0), w - 1), min(max(y0 + dy, 0), h - 1)
            texel = px[y][x]
            weight = wx * wy
            for c in range(4):
                out[c] += texel[c] * weight
    return out


def load_background():
    image = BACKGROUND.read_bytes()
    fields = struct.unpack("<BBBHHBHHHHBB", image[:18])
    assert fields[2] == 2 and fields[10] == 32 and fields[11] == 8, "unexpected background format"
    return fields[8], fields[9], image


def background_color(bg, wx, wy):
    """Bilinear world-space fetch from the bottom-left-origin Mirage TGA."""
    width, height, image = bg
    u, v = wx - 0.5, wy - 0.5
    x0, y0 = int(floor(u)), int(floor(v))
    fx, fy = u - x0, v - y0
    out = [0.0, 0.0, 0.0]
    for dy, wy_ in ((0, 1.0 - fy), (1, fy)):
        for dx, wx_ in ((0, 1.0 - fx), (1, fx)):
            x, y = min(max(x0 + dx, 0), width - 1), min(max(y0 + dy, 0), height - 1)
            offset = 18 + (y * width + x) * 4
            blue, green, red = image[offset], image[offset + 1], image[offset + 2]
            weight = wx_ * wy_
            out[0] += red * weight
            out[1] += green * weight
            out[2] += blue * weight
    return out


def scene_tile(px, size, pixels_per_unit, heading, ground, tint=(1.0, 1.0, 1.0)):
    """One kart composited like the client draws it: rotated quad, vertex tint."""
    from math import cos, pi, sin  # preview-only; not part of the asset bytes
    angle = heading - pi / 2
    ca, sa = cos(angle), sin(angle)
    tile = []
    for ty in range(size):
        row = []
        for tx in range(size):
            dx = (tx + 0.5 - size / 2) / pixels_per_unit
            dy = (size / 2 - ty - 0.5) / pixels_per_unit
            base = ground(dx, dy)
            lx, ly = dx * ca + dy * sa, -dx * sa + dy * ca
            u = (lx + QUAD_WIDTH / 2) * TEXELS_PER_UNIT
            v = (QUAD_HEIGHT / 2 - ly) * TEXELS_PER_UNIT
            if -1.0 < u < TEXTURE_WIDTH + 1 and -1.0 < v < TEXTURE_HEIGHT + 1:
                r, g, b, a = sample_bilinear(px, u, v)
                a /= 255.0
                base = [r * tint[0] * a + base[0] * (1.0 - a),
                        g * tint[1] * a + base[1] * (1.0 - a),
                        b * tint[2] * a + base[2] * (1.0 - a)]
            row.append([int(min(255.0, c) + 0.5) for c in base] + [255])
        tile.append(row)
    return tile


def review_sheet(px):
    """Runtime texture on a checkerboard plus in-context, rotated, tinted kart views."""
    from math import pi
    bg = load_background()

    def mirage(kx, ky):
        return lambda dx, dy: background_color(bg, kx + dx, ky + dy)

    def oval_road(dx, dy):
        return [66.0, 64.0, 59.0]   # Test Oval primitive road color
    poses = [(700, 360, pi / 2), (676, 610, pi * 0.62), (560, 900, pi), (300, 700, pi * 1.25),
             (420, 520, -pi / 2), (470, 160, -pi * 0.2), (540, 140, 0.0), (680, 250, pi * 0.3)]
    rows = []
    for ui in (1.0, 1.36):   # pixels per UI unit: about 1080p and 1440p at 0.72 UI scale
        rows.append([scene_tile(px, 72, 1.5 * ui, h, mirage(kx, ky)) for kx, ky, h in poses])
    # Drift/boost feedback uses the same vertex tints as UI.lua.
    tints = [(1.0, 1.0, 1.0), (0.70, 0.84, 1.0), (1.0, 0.86, 0.40), (1.0, 0.62, 0.90),
             (0.56, 1.0, 0.94)]
    rows.append([scene_tile(px, 72, 1.5 * 1.36, pi / 2, mirage(700, 600), t) for t in tints] +
                [scene_tile(px, 72, 1.0, pi / 2, oval_road),
                 scene_tile(px, 72, 1.0, pi * 0.75, oval_road),
                 scene_tile(px, 72, 1.0, pi * 1.5, mirage(250, 250))])
    zoom, gap = 2, 4
    tile_px = 72 * zoom
    grid_w = 8 * tile_px + 7 * gap
    tex_w, tex_h = TEXTURE_WIDTH * 4, TEXTURE_HEIGHT * 4
    width = tex_w + gap * 3 + grid_w
    height = max(tex_h, 3 * tile_px + 2 * gap) + 2 * gap
    sheet = [[[28, 28, 32, 255] for _ in range(width)] for _ in range(height)]
    for y in range(tex_h):
        for x in range(tex_w):
            r, g, b, a = px[y // 4][x // 4]
            check = 170 if ((x // 16) + (y // 16)) % 2 else 120
            sheet[gap + y][gap + x] = [(r * a + check * (255 - a) + 127) // 255,
                                       (g * a + check * (255 - a) + 127) // 255,
                                       (b * a + check * (255 - a) + 127) // 255, 255]
    for r_index, row in enumerate(rows):
        for c_index, tile in enumerate(row):
            ox = tex_w + 2 * gap + c_index * (tile_px + gap)
            oy = gap + r_index * (tile_px + gap)
            for y in range(tile_px):
                for x in range(tile_px):
                    sheet[oy + y][ox + x] = tile[y // zoom][x // zoom]
    return sheet


def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--check", action="store_true",
                        help="verify exact runtime bytes and invariants without writing")
    parser.add_argument("--preview", action="store_true",
                        help="also write the PNG master and review sheet under docs/art/karts/")
    args = parser.parse_args()
    for kart_id, (filename, slug, painter) in KARTS.items():
        image = encode_tga(render(painter))
        opaque, solid, bounds = validate(image)
        output = ASSETS / filename
        if args.check:
            if not output.is_file() or output.read_bytes() != image:
                raise SystemExit(f"STALE: {output.relative_to(ROOT)}; run without --check")
        else:
            output.parent.mkdir(parents=True, exist_ok=True)
            output.write_bytes(image)
        digest = hashlib.sha256(image).hexdigest()
        print(f'{"CHECK PASS" if args.check else "GENERATED"}: {output.relative_to(ROOT).as_posix()}; '
              f"{kart_id} {TEXTURE_WIDTH}x{TEXTURE_HEIGHT} BGRA32 straight alpha bottom-left; "
              f"{len(image)} bytes; {opaque} visible/{solid} opaque texels in "
              f"{FOOTPRINT_WIDTH:g}x{FOOTPRINT_HEIGHT:g} footprint, bounds {bounds}; sha256={digest}")
        if args.preview and not args.check:
            DOCS.mkdir(parents=True, exist_ok=True)
            master = render(painter, TEXTURE_WIDTH * 4, TEXTURE_HEIGHT * 4)
            (DOCS / f"{slug}-master.png").write_bytes(encode_png(master))
            (DOCS / f"{slug}-review.png").write_bytes(encode_png(review_sheet(decode_tga(image)[1])))
            print(f"PREVIEW: docs/art/karts/{slug}-master.png, docs/art/karts/{slug}-review.png")


if __name__ == "__main__":
    main()
