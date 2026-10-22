"""Procedural scenery models for city tracks: what Warcraft III has no model
for (the Great Forge's Great Anvil and its pumps), built from simple solids
(boxes, prisms, cylinders) and painted with Warcraft III textures.

A mesh is posed like a Warcraft III model for wc3render.render: world-unit
triangles round its origin on the ground, a stand-in model whose materials
are texture regions (or flat colours), so it takes the scenery's north-west
sun, height lean and soft shadow exactly as the models round it do. A
texture paint names a rectangle of a Warcraft III texture, a tint and how it
covers a face: stretched once, repeated a fixed number of times, or every
so many world units. Standard library only; the same IEEE arithmetic as the
renderer (no library cos or sin), so the pictures stay reproducible.

build(name, yaw, scale, wc3) -> (loaded, triangles); MESHES lists the names.
"""
from math import floor, pi, sqrt

import wc3render as R


def _cos_sin(a):
    """cos and sin of `a` radians by + - * / alone (a quadrant and a Taylor
    series), so every platform's float arithmetic gives the same bits;
    a library's cos and sin may differ in the last place."""
    q = int(floor(a / (pi / 2) + 0.5))
    r = a - q * (pi / 2)
    r2 = r * r
    c, s, term_c, term_s = 1.0, r, 1.0, r
    for k in range(1, 12):
        term_c = -term_c * r2 / ((2 * k - 1) * (2 * k))
        term_s = -term_s * r2 / ((2 * k) * (2 * k + 1))
        c += term_c
        s += term_s
    return ((c, s), (-s, c), (-c, -s), (s, -c))[q % 4]


# ---------------------------------------------------------------------------
# Paints: a colour (r, g, b) 0-255; a texture region, tex(); or a pattern
# ("bands" | "emblem", paint, paint) choosing between two paints over a face.


def tex(path, region, tint=(1.0, 1.0, 1.0), period=(None, None), repeat=(1, 1)):
    """A rectangle (x0, y0, x1, y1 texels, y down) of a Warcraft III texture,
    multiplied by `tint`. Across a face it repeats every `period` world units
    on that axis (None: `repeat` times, by default once, stretched). Round a
    prism the repeat is rounded to whole times so the seam matches."""
    return ("tex", path, tuple(region), tuple(tint), tuple(period), tuple(repeat))


def _texture(paint):
    return isinstance(paint, tuple) and paint[0] == "tex"


def _bands(u, v):
    """Paint 1 on bands at the top and foot of a face, paint 0 between."""
    return 1 if v < 0.14 or v > 0.86 else 0


def _emblem(u, v):
    """Paint 1 on a lozenge in the middle of a face (the anvil's top)."""
    return 1 if abs(u - 0.45) * 2.6 + abs(v - 0.5) < 0.30 else 0


PATTERNS = {"bands": _bands, "emblem": _emblem}


class Mesh:
    """Triangles in wc3render's posed form: ((p0, p1, p2), (n0, n1, n2),
    (uv0, uv1, uv2), material), with one material per paint. Face UVs run
    0..1 across each face; a texture paint with a period scales them by the
    face's size in world units."""

    def __init__(self):
        self.paints = []
        self.triangles = []

    def material(self, paint):
        if paint not in self.paints:
            self.paints.append(paint)
        return self.paints.index(paint)

    def face(self, points, paint, normals=None, uvs=None, extent=None, whole=(False, False)):
        """A convex planar polygon, its outward side counter-clockwise, as a
        fan. `extent`: the face's width and height in world units (for a
        paint's period); `whole`: round the repeat to whole times per axis."""
        m = self.material(paint)
        if normals is None:
            normal = _normal(points)
            normals = [normal] * len(points)
        uvs = uvs or [(0.0, 0.0)] * len(points)
        if _texture(paint) and extent is not None:
            scale = []
            for axis in (0, 1):
                period = paint[4][axis]
                if period is None:
                    scale.append(1.0)
                else:
                    times = extent[axis] / period
                    scale.append(max(1.0, float(floor(times + 0.5))) if whole[axis] else times)
            uvs = [(u * scale[0], v * scale[1]) for u, v in uvs]
        for k in range(1, len(points) - 1):
            self.triangles.append(((points[0], points[k], points[k + 1]),
                                   (normals[0], normals[k], normals[k + 1]),
                                   (uvs[0], uvs[k], uvs[k + 1]), m))

    def prism(self, cx, cy, z0, z1, r0, r1, sides, side, top=None, smooth=True, turn=0.0):
        """An upright frustum of `sides` sides (radius r0 at z0, r1 at z1),
        its top capped. Smooth sides shade as a cylinder; u runs round it
        (whole repeats), v up it; the cap's texture is laid across it."""
        top = top or side
        ring0, ring1, normals = [], [], []
        slope = (r0 - r1) / (z1 - z0) if z1 != z0 else 0.0
        for k in range(sides + 1):
            c, s = _cos_sin(turn + 2.0 * pi * k / sides)
            ring0.append((cx + r0 * c, cy + r0 * s, z0))
            ring1.append((cx + r1 * c, cy + r1 * s, z1))
            length = sqrt(1.0 + slope * slope)
            normals.append((c / length, s / length, slope / length))
        extent = (pi * (r0 + r1), sqrt((z1 - z0) ** 2 + (r0 - r1) ** 2))
        for k in range(sides):
            quad = [ring0[k], ring0[k + 1], ring1[k + 1], ring1[k]]
            uvs = [(k / sides, 0.0), ((k + 1) / sides, 0.0), ((k + 1) / sides, 1.0), (k / sides, 1.0)]
            if smooth:
                self.face(quad, side, [normals[k], normals[k + 1], normals[k + 1], normals[k]], uvs,
                          extent, (True, False))
            else:
                self.face(quad, side, None, uvs, extent, (True, False))
        if r1 > 0:
            cap = ring1[:-1]
            self.face(cap, top, [(0.0, 0.0, 1.0)] * len(cap),
                      [(0.5 + 0.5 * (p[0] - cx) / r1, 0.5 + 0.5 * (p[1] - cy) / r1) for p in cap],
                      (2 * r1, 2 * r1))

    def block(self, x0, y0, x1, y1, z0, z1, side, top=None, inset=0.0, top_box=None):
        """An axis-aligned block, its top `inset` smaller all round or the
        rectangle `top_box` (x0, y0, x1, y1): a frustum."""
        top = top or side
        tx0, ty0, tx1, ty1 = top_box or (x0 + inset, y0 + inset, x1 - inset, y1 - inset)
        b = [(x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0)]
        t = [(tx0, ty0, z1), (tx1, ty0, z1), (tx1, ty1, z1), (tx0, ty1, z1)]
        square = [(0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0)]
        for k in range(4):
            (ax, ay, _), (bx, by, _) = b[k], b[(k + 1) % 4]
            self.face([b[k], b[(k + 1) % 4], t[(k + 1) % 4], t[k]], side, uvs=square,
                      extent=(sqrt((bx - ax) ** 2 + (by - ay) ** 2), z1 - z0))
        self.face(t, top, uvs=square, extent=(tx1 - tx0, ty1 - ty0))

    def horn(self, x0, x1, half_width, z0, z1, tip_z, paint, top=None):
        """An anvil's horn: from the rectangle x = x0 (y +-half_width, z0..z1)
        to a point at (x1, 0, tip_z), pointing +x."""
        top = top or paint
        a, b = (x0, -half_width, z0), (x0, half_width, z0)
        c, d = (x0, half_width, z1), (x0, -half_width, z1)
        tip = (x1, 0.0, tip_z)
        side = (x1 - x0, z1 - z0)
        self.face([a, tip, d], paint, uvs=[(0.0, 0.0), (1.0, 0.5), (0.0, 1.0)], extent=side)   # south
        self.face([b, c, tip], paint, uvs=[(0.0, 0.0), (0.0, 1.0), (1.0, 0.5)], extent=side)   # north
        self.face([d, tip, c], top, uvs=[(0.0, 0.0), (1.0, 0.5), (0.0, 1.0)],
                  extent=(x1 - x0, 2 * half_width))                                           # top
        self.face([a, b, tip], paint, uvs=[(0.0, 0.0), (0.0, 1.0), (1.0, 0.5)], extent=side)   # underside


def _normal(points):
    (ax, ay, az), (bx, by, bz), (cx, cy, cz) = points[0], points[1], points[2]
    ux, uy, uz = bx - ax, by - ay, bz - az
    vx, vy, vz = cx - ax, cy - ay, cz - az
    nx, ny, nz = uy * vz - uz * vy, uz * vx - ux * vz, ux * vy - uy * vx
    length = sqrt(nx * nx + ny * ny + nz * nz) or 1.0
    return nx / length, ny / length, nz / length


# ---------------------------------------------------------------------------
# Samplers.


def _region_sampler(texture, paint):
    """Bilinear samples of a texture rectangle, repeating inside it (never
    reading its neighbours), times the paint's tint and repeat."""
    _, _, (x0, y0, x1, y1), tint, _, (ru, rv) = paint
    width, _, texels = texture
    span_x, span_y = x1 - x0, y1 - y0

    def fetch(x, y):
        x = x0 + (x - x0) % span_x
        y = y0 + (y - y0) % span_y
        return texels[y * width + x]

    def sample(u, v):
        u, v = u * ru, v * rv
        fu, fv = u - floor(u), v - floor(v)
        fx = x0 + fu * span_x - 0.5
        fy = y0 + (1.0 - fv) * span_y - 0.5        # v runs up a face; texture rows run down
        ix, iy = int(floor(fx)), int(floor(fy))
        tx, ty = fx - ix, fy - iy
        out = [0.0, 0.0, 0.0]
        for dy, wy in ((0, 1.0 - ty), (1, ty)):
            for dx, wx in ((0, 1.0 - tx), (1, tx)):
                texel, w = fetch(ix + dx, iy + dy), wx * wy
                out[0] += texel[0] * w
                out[1] += texel[1] * w
                out[2] += texel[2] * w
        return [min(1.0, out[0] * tint[0]), min(1.0, out[1] * tint[1]), min(1.0, out[2] * tint[2]), 1.0]
    return sample


def _sampler(paint, textures):
    if _texture(paint):
        return _region_sampler(textures[paint[1]], paint)
    if isinstance(paint[0], str):
        choose = PATTERNS[paint[0]]
        pair = (_sampler(paint[1], textures), _sampler(paint[2], textures))

        def sample(u, v):
            return pair[choose(u - floor(u), v - floor(v))](u, v)
        return sample
    color = [paint[0] / 255.0, paint[1] / 255.0, paint[2] / 255.0, 1.0]
    return lambda u, v: color


def _paths(paint):
    if _texture(paint):
        return [paint[1]]
    if isinstance(paint[0], str):
        return _paths(paint[1]) + _paths(paint[2])
    return []


def _loaded(mesh, wc3):
    """A stand-in for wc3render.load's (model, samplers, team): the textures
    read from the extracted files as wc3render reads a model's."""
    paths = sorted({p for paint in mesh.paints for p in _paths(paint)})
    textures, files = {}, []
    for path in paths:
        found = R.archive_file(wc3, path)
        textures[path] = R.read_dds(found.read_bytes())
        files.append(found.relative_to(wc3).as_posix())
    model = {"textures": [{"replaceable": 0, "file": "", "flags": 0} for _ in mesh.paints],
             "materials": [[{"texture": k, "filter": 0}] for k in range(len(mesh.paints))],
             "sequences": {"Stand": (0, 0)}, "texture_files": files}
    return model, {k: _sampler(p, textures) for k, p in enumerate(mesh.paints)}, (0.0, 0.0, 0.0)


# ---------------------------------------------------------------------------
# The Great Forge, in Warcraft III's dwarven metals: the steam tank's riveted
# plates and brass straps, the power generator's copper coils, brass rail,
# rune-cut iron, pipe and round hatch, the mine cart's dark iron.

STEAM = "war3.w3mod:textures/steamtank.dds"
POWER = "war3.w3mod:buildings/other/powergenerator/powergenerator.dds"
CART = "war3.w3mod:textures/minecart.dds"

DARK_IRON = tex(CART, (0, 0, 60, 31), period=(30, 15))
RIVETED_DARK = tex(STEAM, (2, 184, 62, 254), tint=(0.85, 0.82, 0.80), period=(26, 26))
RUNES = tex(POWER, (0, 147, 106, 191), period=(36, None))
BRASS = tex(POWER, (0, 131, 106, 145), period=(30, None))
BRASS_STRAP = tex(STEAM, (154, 100, 174, 178), period=(None, None))
PLATES = tex(STEAM, (82, 98, 240, 180), tint=(0.62, 0.58, 0.56), period=(76, None))
COILS = tex(POWER, (0, 0, 50, 80), tint=(0.95, 0.85, 0.80), period=(16, 14))
PIPE = tex(POWER, (55, 0, 88, 128))
HATCH = tex(POWER, (93, 2, 201, 110))
RED_PLATE = tex(STEAM, (96, 100, 150, 178), tint=(1.05, 0.36, 0.28), period=(26, None))
RED_TOP = tex(STEAM, (96, 100, 150, 178), tint=(0.98, 0.34, 0.27), repeat=(2, 1))
GOLD = tex(STEAM, (154, 100, 174, 178), repeat=(3, 1))


def great_anvil(mesh):
    """The Great Anvil: a red and gold anvil on a low base of rune-cut dark
    iron. Its long side faces the camera with the classic profile: the
    flared foot, the narrow waist, the tall face with the horn to the east
    and the heel to the west; a gold lozenge on its face."""
    mesh.block(-36, -20, 36, 20, 0, 6, RUNES, RIVETED_DARK, inset=1)
    mesh.block(-26, -11, 26, 11, 6, 14, DARK_IRON, DARK_IRON, top_box=(-13, -8, 13, 8))   # the flared foot
    mesh.block(-11, -7, 11, 7, 14, 34, ("bands", RED_PLATE, BRASS), RED_PLATE)            # the waist
    mesh.block(-40, -9, 24, 9, 34, 48, ("bands", RED_PLATE, BRASS), ("emblem", RED_TOP, GOLD))
    mesh.block(-50, -7, -40, 7, 39, 48, RED_PLATE, RED_TOP)                                # the heel
    mesh.horn(24, 64, 9, 35, 48, 44, RED_PLATE, RED_TOP)


def great_pump(mesh):
    """One of the forge's great pumps: a vat of riveted plates and brass
    straps on a brass ring, a brass shoulder, a round hatch and a pipe."""
    mesh.prism(0, 0, 0, 7, 27, 26, 24, BRASS, DARK_IRON)
    mesh.prism(0, 0, 7, 46, 25, 22, 24, PLATES, DARK_IRON)
    mesh.prism(0, 0, 46, 52, 23, 16, 24, BRASS, DARK_IRON)
    mesh.prism(0, 0, 52, 55, 16, 15, 24, DARK_IRON, HATCH)
    mesh.prism(0, 0, 55, 74, 6, 5.5, 16, PIPE, DARK_IRON)
    mesh.prism(0, 0, 74, 77, 7.5, 7, 16, DARK_IRON, DARK_IRON)


def pump(mesh):
    """A small pump: an octagonal drum of copper coils with a brass band on
    a dark iron base, a round hatch, a steel piston and its rocking beam."""
    mesh.prism(0, 0, 0, 3, 12, 12, 8, DARK_IRON, DARK_IRON, smooth=False, turn=pi / 8)
    mesh.prism(0, 0, 3, 7, 10, 10, 8, COILS, COILS, smooth=False, turn=pi / 8)
    mesh.prism(0, 0, 7, 9, 10.6, 10.6, 8, BRASS, BRASS, smooth=False, turn=pi / 8)
    mesh.prism(0, 0, 9, 15, 10, 10, 8, COILS, COILS, smooth=False, turn=pi / 8)
    mesh.prism(0, 0, 15, 17, 11, 9, 8, DARK_IRON, HATCH, smooth=False, turn=pi / 8)
    mesh.prism(0, 0, 17, 28, 1.8, 1.8, 10, PIPE)
    mesh.block(-3, -3, 3, 3, 26, 30, DARK_IRON)
    mesh.block(-14, -1.5, 14, 1.5, 28, 31, DARK_IRON)
    mesh.prism(-12, 0, 17, 29, 1.4, 1.4, 8, DARK_IRON)                # the beam's far post


MESHES = {"great_anvil": great_anvil, "great_pump": great_pump, "pump": pump}


def build(name, yaw=270, scale=1.0, wc3=None):
    """(loaded, triangles) for wc3render.render: the named mesh at `scale`
    world units per mesh unit, turned `yaw` degrees counter-clockwise from
    its authored facing (270, as a model's default, leaves it unturned);
    its textures read from the extracted Warcraft III files under `wc3`."""
    mesh = Mesh()
    MESHES[name](mesh)
    c, s = R.YAWS[(yaw - 270) % 360]
    triangles = []
    for pts, normals, uvs, m in mesh.triangles:
        posed = tuple((scale * (x * c - y * s), scale * (x * s + y * c), scale * z) for x, y, z in pts)
        turned = tuple((nx * c - ny * s, nx * s + ny * c, nz) for nx, ny, nz in normals)
        triangles.append((posed, turned, uvs, m))
    return _loaded(mesh, wc3), triangles
