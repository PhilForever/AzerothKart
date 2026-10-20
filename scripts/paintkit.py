"""Deterministic procedural painting toolkit shared by Azeroth Kart art generators.

Used by scripts/build_kart_sprites.py and scripts/build_mirage_background.py.
Standard library only. Shapes are signed-distance functions in world units;
materials are closures over position and distance. Only IEEE-exact operations
(+ - * /, sqrt, floor) and integer hashing feed pixel values, so generated
bytes are identical on every platform. No PRNG, clock or external image is
an input; callers own palettes, layouts and validation.
"""
import array
from math import floor, sqrt  # both exact/correctly rounded under IEEE 754
import struct
import zlib

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


def hash32(ix, iy, seed):
    """Same mixing as hash2 but returning all 32 bits (hash2 keeps 16)."""
    value = (ix * 374761393 + iy * 668265263 + seed * 2246822519 + 1729) & 0xffffffff
    value = ((value ^ (value >> 13)) * 1274126177) & 0xffffffff
    return value ^ (value >> 16)


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
    """One painted part: geometry, material and an inner contour stroke.

    `soft` widens the coverage ramp to that many world units (soft shadows and
    glows); by default edges are anti-aliased over one sample.
    """

    def __init__(self, sdf, bbox, paint, outline=0.0, ink=INK, opacity=1.0, soft=None):
        self.sdf, self.bbox, self.paint = sdf, bbox, paint
        self.outline, self.ink, self.opacity, self.soft = outline, ink, opacity, soft


class Canvas:
    """Premultiplied supersampled RGBA accumulation over a world rectangle.

    `width` x `height` output texels cover `world_width` x `world_height` world
    units starting at (`left`, `bottom`); texels must be square. Each texel
    receives `supersample` x `supersample` samples. Row 0 is the top edge.
    """

    def __init__(self, width, height, supersample, left, bottom, world_width, world_height):
        assert width * world_height == height * world_width, "texels must stay square in world units"
        self.width, self.height, self.supersample = width, height, supersample
        self.left, self.top = left, bottom + world_height
        self.columns = width * supersample
        self.rows = height * supersample
        size = self.columns * self.rows
        self.red = array.array("d", bytes(8 * size))
        self.green = array.array("d", bytes(8 * size))
        self.blue = array.array("d", bytes(8 * size))
        self.alpha = array.array("d", bytes(8 * size))
        self.step = world_width / self.columns  # world units per sample
        self.touched = None  # optional bytearray marking samples any shape covered
        # Sample centers: column 0 is the left edge, row 0 is the top edge.
        self.xs = [left + (c + 0.5) * self.step for c in range(self.columns)]
        self.ys = [self.top - (r + 0.5) * self.step for r in range(self.rows)]

    def draw(self, shape):
        xmin, xmax, ymin, ymax = shape.bbox
        step = self.step
        pad = 2 * step + shape.outline + (shape.soft or 0.0)
        c0 = max(0, int((xmin - pad - self.left) / step))
        c1 = min(self.columns, int((xmax + pad - self.left) / step) + 1)
        r0 = max(0, int((self.top - ymax - pad) / step))
        r1 = min(self.rows, int((self.top - ymin + pad) / step) + 1)
        sdf, paint = shape.sdf, shape.paint
        outline, ink, opacity = shape.outline, shape.ink, shape.opacity
        red, green, blue, alpha = self.red, self.green, self.blue, self.alpha
        xs, ys, columns, touched = self.xs, self.ys, self.columns, self.touched
        # Coverage ramps across one sample (or `soft` units); the box filter
        # in resolve() then anti-aliases each texel. Contours stay in world units.
        inv = 1.0 / step
        cover = inv if not shape.soft else 1.0 / shape.soft
        for r in range(r0, r1):
            y = ys[r]
            base = r * columns
            for c in range(c0, c1):
                x = xs[c]
                d = sdf(x, y)
                coverage = 0.5 - d * cover
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
                if touched is not None:
                    touched[i] = 1
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
                 shape.outline, shape.ink, shape.opacity, shape.soft)


def mirrored(make):
    """Build a symmetric pair from a constructor taking a side sign (-1, +1)."""
    return [make(-1.0), make(1.0)]


# ---------------------------------------------------------------------------
# Image encoding and sampling.


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
