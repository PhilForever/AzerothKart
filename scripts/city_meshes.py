"""Procedural scenery models for city tracks: what Warcraft III has no model
for (the Great Forge's Great Anvil and its pumps), built from simple solids
(boxes, prisms, cylinders) with flat or patterned colours.

A mesh is posed like a Warcraft III model for wc3render.render: world-unit
triangles round its origin on the ground, a stand-in model whose materials
are colours, so it takes the scenery's north-west sun, height lean and soft
shadow exactly as the models round it do. Standard library only; the same
IEEE arithmetic as the renderer (no library cos or sin), so the pictures
stay reproducible.

build(name, yaw, scale) -> (loaded, triangles); MESHES lists the names.
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


class Mesh:
    """Triangles in wc3render's posed form: ((p0, p1, p2), (n0, n1, n2),
    (uv0, uv1, uv2), material), with one material per colour or pattern."""

    def __init__(self):
        self.paints = []
        self.triangles = []

    def material(self, paint):
        if paint not in self.paints:
            self.paints.append(paint)
        return self.paints.index(paint)

    def face(self, points, paint, normals=None, uvs=None):
        """A convex planar polygon, its outward side counter-clockwise, as a fan."""
        m = self.material(paint)
        if normals is None:
            normal = _normal(points)
            normals = [normal] * len(points)
        uvs = uvs or [(0.0, 0.0)] * len(points)
        for k in range(1, len(points) - 1):
            self.triangles.append(((points[0], points[k], points[k + 1]),
                                   (normals[0], normals[k], normals[k + 1]),
                                   (uvs[0], uvs[k], uvs[k + 1]), m))

    def prism(self, cx, cy, z0, z1, r0, r1, sides, side, top=None, smooth=True, turn=0.0):
        """An upright frustum of `sides` sides (radius r0 at z0, r1 at z1),
        its top capped. Smooth sides shade as a cylinder; pattern u runs round
        it, v up it."""
        top = top or side
        ring0, ring1, normals = [], [], []
        slope = (r0 - r1) / (z1 - z0) if z1 != z0 else 0.0
        for k in range(sides + 1):
            c, s = _cos_sin(turn + 2.0 * pi * k / sides)
            ring0.append((cx + r0 * c, cy + r0 * s, z0))
            ring1.append((cx + r1 * c, cy + r1 * s, z1))
            length = sqrt(1.0 + slope * slope)
            normals.append((c / length, s / length, slope / length))
        for k in range(sides):
            quad = [ring0[k], ring0[k + 1], ring1[k + 1], ring1[k]]
            uvs = [(k / sides, 0.0), ((k + 1) / sides, 0.0), ((k + 1) / sides, 1.0), (k / sides, 1.0)]
            if smooth:
                self.face(quad, side, [normals[k], normals[k + 1], normals[k + 1], normals[k]], uvs)
            else:
                self.face(quad, side, None, uvs)
        if r1 > 0:
            cap = ring1[:-1]
            self.face(cap, top, [(0.0, 0.0, 1.0)] * len(cap),
                      [(0.5 + 0.5 * (p[0] - cx) / r1, 0.5 + 0.5 * (p[1] - cy) / r1) for p in cap])

    def block(self, x0, y0, x1, y1, z0, z1, side, top=None, inset=0.0, top_box=None):
        """An axis-aligned block, its top `inset` smaller all round or the
        rectangle `top_box` (x0, y0, x1, y1): a frustum."""
        top = top or side
        tx0, ty0, tx1, ty1 = top_box or (x0 + inset, y0 + inset, x1 - inset, y1 - inset)
        b = [(x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0)]
        t = [(tx0, ty0, z1), (tx1, ty0, z1), (tx1, ty1, z1), (tx0, ty1, z1)]
        for k in range(4):
            self.face([b[k], b[(k + 1) % 4], t[(k + 1) % 4], t[k]], side,
                      uvs=[(0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0)])
        self.face(t, top, uvs=[(0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0)])

    def horn(self, x0, x1, half_width, z0, z1, tip_z, paint, top=None):
        """An anvil's horn: from the rectangle x = x0 (y +-half_width, z0..z1)
        to a point at (x1, 0, tip_z), pointing +x."""
        top = top or paint
        a, b = (x0, -half_width, z0), (x0, half_width, z0)
        c, d = (x0, half_width, z1), (x0, -half_width, z1)
        tip = (x1, 0.0, tip_z)
        self.face([a, tip, d], paint)          # south
        self.face([b, c, tip], paint)          # north
        self.face([d, tip, c], top)            # top
        self.face([a, b, tip], paint)          # underside


def _normal(points):
    (ax, ay, az), (bx, by, bz), (cx, cy, cz) = points[0], points[1], points[2]
    ux, uy, uz = bx - ax, by - ay, bz - az
    vx, vy, vz = cx - ax, cy - ay, cz - az
    nx, ny, nz = uy * vz - uz * vy, uz * vx - ux * vz, ux * vy - uy * vx
    length = sqrt(nx * nx + ny * ny + nz * nz) or 1.0
    return nx / length, ny / length, nz / length


# ---------------------------------------------------------------------------
# Paints: a colour (r, g, b) 0-255, or a pattern ("name", colour, colour).


def _plates(u, v, base, seam):
    """Riveted iron plates: seams every twelfth of the way round and at mid
    height, a rivet row under the top edge."""
    k = (u * 12.0) % 1.0
    if k < 0.06 or abs(v - 0.5) < 0.03:
        return seam
    if v > 0.86 and abs(((u * 48.0) % 1.0) - 0.5) < 0.18:
        return seam
    return base


def _emblem(u, v, base, gold):
    """A gold lozenge on a face (the anvil's top)."""
    if abs(u - 0.45) * 2.6 + abs(v - 0.5) < 0.30:
        return gold
    return base


def _bands(u, v, base, gold):
    """Gold bands round the top and foot of a face (the anvil's waist)."""
    return gold if v < 0.14 or v > 0.86 else base


PATTERNS = {"plates": _plates, "emblem": _emblem, "bands": _bands}


def _sampler(paint):
    if isinstance(paint[0], str):
        pattern, first, second = PATTERNS[paint[0]], paint[1], paint[2]

        def sample(u, v):
            r, g, b = pattern(u - floor(u), v - floor(v), first, second)
            return [r / 255.0, g / 255.0, b / 255.0, 1.0]
        return sample
    color = [paint[0] / 255.0, paint[1] / 255.0, paint[2] / 255.0, 1.0]
    return lambda u, v: color


def _loaded(mesh):
    """A stand-in for wc3render.load's (model, samplers, team)."""
    textures = [{"replaceable": 0, "file": "", "flags": 0} for _ in mesh.paints]
    materials = [[{"texture": k, "filter": 0}] for k in range(len(mesh.paints))]
    model = {"textures": textures, "materials": materials, "sequences": {"Stand": (0, 0)},
             "texture_files": []}
    return model, {k: _sampler(p) for k, p in enumerate(mesh.paints)}, (0.0, 0.0, 0.0)


# ---------------------------------------------------------------------------
# The Great Forge.

IRON, IRON_SEAM = (60, 56, 58), (36, 33, 34)
BRONZE, BRONZE_DARK = (132, 56, 36), (92, 38, 26)
STEEL = (168, 164, 158)
BASE, BASE_TOP = (56, 50, 50), (70, 62, 60)
ANVIL_RED, ANVIL_TOP, GOLD = (168, 44, 30), (150, 40, 28), (226, 174, 70)


def great_anvil(mesh):
    """The Great Anvil: a red and gold anvil on a low dark iron base. Its
    long side faces the camera with the classic profile: the flared foot,
    the narrow waist, the tall face with the horn to the east and the heel
    to the west; a gold lozenge on its face."""
    mesh.block(-36, -20, 36, 20, 0, 6, BASE, BASE_TOP, inset=1)
    mesh.block(-26, -11, 26, 11, 6, 14, IRON, IRON, top_box=(-13, -8, 13, 8))      # the flared foot
    mesh.block(-11, -7, 11, 7, 14, 34, ("bands", ANVIL_RED, GOLD), ANVIL_RED)      # the waist
    mesh.block(-40, -9, 24, 9, 34, 48, ("bands", ANVIL_RED, GOLD), ("emblem", ANVIL_TOP, GOLD))
    mesh.block(-50, -7, -40, 7, 39, 48, ANVIL_RED, ANVIL_TOP)                      # the heel
    mesh.horn(24, 64, 9, 35, 48, 44, ANVIL_RED, ANVIL_TOP)


def great_pump(mesh):
    """One of the forge's great pumps: a riveted iron vat on a bronze ring,
    a bronze shoulder, and a pale pipe rising from its top."""
    mesh.prism(0, 0, 0, 7, 27, 26, 24, BRONZE, BRONZE_DARK)
    mesh.prism(0, 0, 7, 46, 25, 22, 24, ("plates", IRON, IRON_SEAM), IRON)
    mesh.prism(0, 0, 46, 52, 23, 16, 24, BRONZE, BRONZE_DARK)
    mesh.prism(0, 0, 52, 55, 16, 15, 24, BRONZE_DARK, IRON)
    mesh.prism(0, 0, 55, 74, 6, 5.5, 16, STEEL, IRON)
    mesh.prism(0, 0, 74, 77, 7.5, 7, 16, IRON_SEAM, IRON)


def pump(mesh):
    """A small pump: an octagonal bronze drum with iron bands on an iron
    base, a steel piston and its rocking beam."""
    mesh.prism(0, 0, 0, 3, 12, 12, 8, IRON, IRON, smooth=False, turn=pi / 8)
    mesh.prism(0, 0, 3, 7, 10, 10, 8, BRONZE, BRONZE, smooth=False, turn=pi / 8)
    mesh.prism(0, 0, 7, 9, 10.6, 10.6, 8, IRON_SEAM, IRON, smooth=False, turn=pi / 8)
    mesh.prism(0, 0, 9, 15, 10, 10, 8, BRONZE, BRONZE, smooth=False, turn=pi / 8)
    mesh.prism(0, 0, 15, 17, 11, 9, 8, IRON, BRONZE_DARK, smooth=False, turn=pi / 8)
    mesh.prism(0, 0, 17, 28, 1.8, 1.8, 10, STEEL)
    mesh.block(-3, -3, 3, 3, 26, 30, IRON)
    mesh.block(-14, -1.5, 14, 1.5, 28, 31, IRON)
    mesh.prism(-12, 0, 17, 29, 1.4, 1.4, 8, IRON)                   # the beam's far post


MESHES = {"great_anvil": great_anvil, "great_pump": great_pump, "pump": pump}


def build(name, yaw=270, scale=1.0):
    """(loaded, triangles) for wc3render.render: the named mesh at `scale`
    world units per mesh unit, turned `yaw` degrees counter-clockwise from
    its authored facing (270, as a model's default, leaves it unturned)."""
    mesh = Mesh()
    MESHES[name](mesh)
    c, s = R.YAWS[(yaw - 270) % 360]
    triangles = []
    for pts, normals, uvs, m in mesh.triangles:
        posed = tuple((scale * (x * c - y * s), scale * (x * s + y * c), scale * z) for x, y, z in pts)
        turned = tuple((nx * c - ny * s, nx * s + ny * c, nz) for nx, ny, nz in normals)
        triangles.append((posed, turned, uvs, m))
    return _loaded(mesh), triangles
