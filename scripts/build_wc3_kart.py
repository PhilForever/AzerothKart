"""Render published Warcraft III models into Azeroth Kart's directional kart sprite sheets.

python scripts/build_wc3_kart.py --source DIR [--vehicle ID]   # write one runtime TGA (default: the trike)
python scripts/build_wc3_kart.py --all ROOT                    # every vehicle, sources in ROOT/<slug>/
    --check     verify exact bytes/invariants, write nothing
    --preview   also write a review sheet under docs/art/karts/
    --emitters  list a model's effect emitters and rear ground contacts (kart frame)

Each source folder holds one vehicle's extracted archive from WC3Vault, laid
out as published (see VEHICLES and docs/art/karts/). Models and textures are
verified by SHA-256 and are not stored in this repository.

The models' meshes, UVs and textures are used as published. The script does
what a game engine does when it shows the unit, from a fixed Warcraft
III-style camera:

- pose the skeleton at the first frame of the vehicle's sequence and keep the
  geosets visible there; flyers are lifted to a hover height;
- show the player team color (red) through the texture's alpha;
- turn the vehicle to 64 headings, 5.625 degrees apart;
- view each heading with an orthographic camera tilted 36.87 degrees from
  vertical, looking north, so the map's north-up camera sees the driver
  and the machine's sides;
- light it from the scenery's north-west sun and cast a soft ground shadow
  south-east, matching the background's shadow vector.

The frames fill an 8x8 sheet (frame k faces heading k * 2pi/64, counter-
clockwise from east). The UI picks the nearest frame by heading and never
rotates the image. Each frame takes 4x4 samples per texel, resolved by
paintkit's exact integer box filter, and transparent texels get bled edge
color.

Standard library only: MDX v800 and BLP1 (paletted, or JPEG through
wc3jpeg.py's libjpeg-exact integer decoder) are read here directly.
Only IEEE arithmetic (+ - * /, sqrt, floor) feeds pixel values (headings
come from half-angle square roots, not libm trigonometry), so the bytes are
reproducible on any platform.
"""
import argparse
import hashlib
from math import floor, sqrt
from pathlib import Path
import struct

from paintkit import Canvas, bleed, decode_tga, encode_png, encode_tga
from wc3jpeg import blp1_jpeg_texels

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "addon" / "AzerothKart" / "Assets" / "Karts"
DOCS = ROOT / "docs" / "art" / "karts"

# Must agree with Presentation.KART_SPRITES (tests re-read every sheet).
FRAMES, COLUMNS, FRAME = 64, 8, 128           # headings, sheet columns, texels per frame side
ATLAS = COLUMNS * FRAME                       # 1024 x 1024 texels
SUPERSAMPLE = 4

TEAM_RED = (255.0 / 255.0, 3.0 / 255.0, 3.0 / 255.0)   # Warcraft III player 1 team color
TILT_COS, TILT_SIN = 0.8, 0.6                 # camera 36.87 degrees from vertical, looking north
_L = (-0.45, 0.56, 0.70)                      # the scenery's north-west sun (build_mirage_background)
_N = sqrt(_L[0] * _L[0] + _L[1] * _L[1] + _L[2] * _L[2])
LX, LY, LZ = _L[0] / _N, _L[1] / _N, _L[2] / _N
AMBIENT, DIFFUSE = 0.66, 0.72
SHADOW_VECTOR = (0.57, -0.76)                 # ground offset per unit of height, as in the scenery
SHADOW_COLOR, SHADOW_ALPHA = (0.10, 0.08, 0.09), 0.42

# One entry per vehicle. "fit" scales the posed model so its width (model Y)
# or length (model X) spans that many world units; the physics body stays
# 17x31 whatever the art. "hover" lifts a flyer's lowest point to that height.
# "quad" and "pivot" are the frame window in world units (Presentation's
# quadWidth/pivotX/pivotY); build() checks that vehicle and shadow fit inside.
VEHICLES = {
    "goblin_mortar_trike": {
        "name": "Goblin Mortar Trike", "output": "GoblinMortarTrike.tga", "slug": "goblin-mortar-trike",
        "archive": "GoblinMortarTrike_Updated_.rar", "model": "GoblinMortarTrike[unit].MDX", "sequence": "Stand",
        "fit": ("width", 21.0), "hover": None, "quad": 41.0, "pivot": (3.0, 0.0), "min_solid": 0.12,
        "sha256": {
            "GoblinMortarTrike[unit].MDX": "5880a72800251d2b48871ba3230ec4ffe97dad4e9c685b8afa860287cf155764",
            "GoblinMortarTrike.blp": "5030e2ca3a16e88c1e3eedeff6d09b5e42d66ac6afae43e060a4e29f7c208168",
        },
    },
    "steam_tank": {
        "name": "Steam Tank", "output": "SteamTank.tga", "slug": "steam-tank",
        "archive": "SteamTank.zip", "model": "SteamTank.mdx", "sequence": "Stand",
        "fit": ("width", 22.0), "hover": None, "quad": 45.0, "pivot": (3.7, 0.0), "min_solid": 0.12,
        "sha256": {
            "SteamTank.mdx": "bc48eb0a555913acd4298678b4b8bb7125dd288c1c527b1840ca405a4f9c3a95",
            "Textures/Steamtank.blp": "3bcbf46b53e1e156fe34651db39d94c3a46b1adf96f6511da81ff372214d1988",
            "Textures/wc1knight_mace.blp": "1086df699add304394c4994951228c1bbb6ce090cb9aa36af6ff9c06ca65274b",
        },
    },
    "dwarven_biker": {
        "name": "Dwarven Biker", "output": "DwarvenBiker.tga", "slug": "dwarven-biker",
        "archive": "DwarvenBiker.zip", "model": "DwarvenBiker.mdx", "sequence": "Walk",
        "fit": ("width", 21.0), "hover": None, "quad": 41.0, "pivot": (3.0, 0.0), "min_solid": 0.12,
        "sha256": {
            "DwarvenBiker.mdx": "21a5c917f64ea266479c7cd60d5a69133699e77bdaeaf732a93adf5cfc012d95",
            "Textures/dwarfbike.BLP": "5ff96109aa481b1fbe4ed383bc24d5ab7a86563e921048c5a86a1c97dd395ba4",
        },
    },
    "gryphon_rider": {
        "name": "Gryphon Rider", "output": "GryphonRider.tga", "slug": "gryphon-rider",
        "archive": "GryphonRider.zip", "model": "gryphonrider.mdx", "sequence": "Stand",
        "fit": ("width", 32.0), "hover": 4.0, "quad": 41.0, "pivot": (2.6, 0.0), "min_solid": 0.08,
        "sha256": {
            "gryphonrider.mdx": "ff20667a4b7eba1e7a193993eff0c49ae3b2b096701dee585c4c5598103d7a0a",
            "Units/Human/GryphonRider/gryphonrider.blp":
                "617d2ea885da04e00fa1ed767bdbc52bb2e8d5c956e2fe4cd44882c5aa8fb156",
        },
    },
}
VEHICLES["gyrocopter"] = {
    "name": "Gyrocopter", "output": "Gyrocopter.tga", "slug": "gyrocopter",
    "archive": "Gyrocopter.zip", "model": "GyroCopter.mdx", "sequence": "Stand",
    "fit": ("length", 28.0), "hover": 4.0, "quad": 58.0, "pivot": (4.0, 0.0), "min_solid": 0.06,
    # The main rotor's blades (bones Mesh05/Mesh02) become a blur disc, as in
    # the game, whose own blur texture is not shipped. The pilot's body uses
    # Warcraft III's Mortar Team texture, also not shipped: a flat leather tone.
    "hide_bones": (15, 16),
    "rotor": {"hub": (1.0, 0.2, 63.1), "radius": 52.0, "color": (0.80, 0.78, 0.70), "alpha": 0.20},
    "substitute": {"textures/mortarteam.blp": (0.45, 0.32, 0.22)},
    "sha256": {
        "GyroCopter.mdx": "630c9f03698ea35dc6d1df7f5b40d033f2d41fab1e91ec4579b7fa573d4e4490",
        "Textures/FlyingMachine.blp": "53e35e011b00579fa86e9c6af98fd6c13aae7b6c1d82e5a6f7e1d512fb598287",
    },
}
TRIKE = VEHICLES["goblin_mortar_trike"]

# ---------------------------------------------------------------------------
# MDX v800 reader (only what a static, posed render needs).


def chunks(data):
    assert data[:4] == b"MDLX", "not an MDX model"
    found, pos = {}, 4
    while pos < len(data):
        tag, size = data[pos:pos + 4].decode("latin1"), struct.unpack_from("<I", data, pos + 4)[0]
        found[tag] = data[pos + 8:pos + 8 + size]
        pos += 8 + size
    return found


def cstring(raw):
    return raw.split(b"\0", 1)[0].decode("latin1")


TRACK_WIDTH = {"KGTR": 3, "KGRT": 4, "KGSC": 3, "KGAO": 1, "KGAC": 3, "KMTA": 1, "KMTF": 1, "KATV": 1}


def read_track(raw, pos):
    """One keyframe track: returns (tag, interpolation, global sequence, keys, next position)."""
    tag = raw[pos:pos + 4].decode("latin1")
    count, interpolation, global_seq = struct.unpack_from("<IIi", raw, pos + 4)
    width = TRACK_WIDTH[tag]
    pos += 16
    keys = []
    for _ in range(count):
        frame = struct.unpack_from("<i", raw, pos)[0]
        value = struct.unpack_from("<" + ("I" if tag == "KMTF" else "f" * width), raw, pos + 4)
        pos += 4 + 4 * width * (3 if interpolation > 1 else 1)
        keys.append((frame, value))
    return tag, interpolation, global_seq, keys, pos


def read_node(raw, pos):
    """Node header plus its transform tracks; returns (node, end of node)."""
    size = struct.unpack_from("<I", raw, pos)[0]
    name = cstring(raw[pos + 4:pos + 84])
    object_id, parent, flags = struct.unpack_from("<IIi", raw, pos + 84)
    node = {"name": name, "id": object_id, "parent": None if parent == 0xFFFFFFFF else parent,
            "flags": flags, "tracks": {}}
    p, end = pos + 96, pos + size
    while p < end:
        tag, interpolation, global_seq, keys, p = read_track(raw, p)
        node["tracks"][tag] = (interpolation, global_seq, keys)
    return node, end


def read_model(data):
    c = chunks(data)
    assert struct.unpack_from("<I", c["VERS"])[0] == 800, "expected MDX version 800"
    model = {"sequences": {}, "textures": [], "materials": [], "geosets": [], "geoset_anims": {},
             "nodes": {}, "pivots": []}
    seqs = c["SEQS"]
    for i in range(len(seqs) // 132):
        o = i * 132
        start, end = struct.unpack_from("<2I", seqs, o + 80)
        model["sequences"][cstring(seqs[o:o + 80])] = (start, end)
    texs = c["TEXS"]
    for i in range(len(texs) // 268):
        o = i * 268
        model["textures"].append({"replaceable": struct.unpack_from("<I", texs, o)[0],
                                  "file": cstring(texs[o + 4:o + 264]),
                                  "flags": struct.unpack_from("<I", texs, o + 264)[0]})
    mtls, o = c["MTLS"], 0
    while o < len(mtls):
        size = struct.unpack_from("<I", mtls, o)[0]
        assert mtls[o + 12:o + 16] == b"LAYS"
        count, p, layers = struct.unpack_from("<I", mtls, o + 16)[0], o + 20, []
        for _ in range(count):
            lsize, filter_mode, shading, texture, _anim, coord, alpha = struct.unpack_from("<6If", mtls, p)
            layers.append({"filter": filter_mode, "shading": shading, "texture": texture,
                           "coord": coord, "alpha": alpha})
            p += lsize
        model["materials"].append(layers)
        o += size
    geos, o = c["GEOS"], 0
    while o < len(geos):
        size = struct.unpack_from("<I", geos, o)[0]
        p = o + 4

        def take(tag, fmt, width):
            nonlocal p
            assert geos[p:p + 4] == tag, (tag, geos[p:p + 4])
            n = struct.unpack_from("<I", geos, p + 4)[0]
            p += 8
            values = struct.unpack_from("<" + fmt * (n * width), geos, p) if n else ()
            p += struct.calcsize("<" + fmt) * n * width
            return values
        vertices, normals = take(b"VRTX", "f", 3), take(b"NRMS", "f", 3)
        assert set(take(b"PTYP", "I", 1)) == {4}, "only triangle lists are supported"
        take(b"PCNT", "I", 1)
        faces, groups = take(b"PVTX", "H", 1), take(b"GNDX", "B", 1)
        group_sizes, matrices = take(b"MTGC", "I", 1), take(b"MATS", "I", 1)
        material = struct.unpack_from("<I", geos, p)[0]
        p += 12 + 28
        p += 4 + 28 * struct.unpack_from("<I", geos, p)[0]
        assert geos[p:p + 4] == b"UVAS"
        p += 8
        uvs = take(b"UVBS", "f", 2)
        bones, at = [], 0
        for n in group_sizes:
            bones.append(matrices[at:at + n])
            at += n
        model["geosets"].append({"vertices": vertices, "normals": normals, "faces": faces,
                                 "groups": groups, "bones": bones, "material": material, "uvs": uvs})
        o += size
    anims, o = c.get("GEOA", b""), 0
    while o < len(anims):
        size = struct.unpack_from("<I", anims, o)[0]
        alpha, _flags, _r, _g, _b, geoset = struct.unpack_from("<fI3fI", anims, o + 4)
        p, tracks = o + 28, {}
        while p < o + size:
            tag, interpolation, global_seq, keys, p = read_track(anims, p)
            tracks[tag] = (interpolation, global_seq, keys)
        model["geoset_anims"][geoset] = (alpha, tracks)
        o += size
    for tag, extra in (("BONE", 8), ("HELP", 0)):
        raw, o = c.get(tag, b""), 0
        while o < len(raw):
            node, o = read_node(raw, o)
            o += extra
            model["nodes"][node["id"]] = node
    pivots = c.get("PIVT", b"")
    model["pivots"] = [struct.unpack_from("<3f", pivots, i * 12) for i in range(len(pivots) // 12)]
    return model


# ---------------------------------------------------------------------------
# Posing at one frame (keys of the chosen sequence; linear/normalized-linear
# interpolation between keys, defaults outside them).


def track_value(track, frame, interval, default):
    if track is None:
        return default
    interpolation, global_seq, keys = track
    start, end = interval
    if global_seq >= 0:
        return keys[0][1] if keys else default   # global sequences are sampled at their start
    inside = [(f, v) for f, v in keys if start <= f <= end]
    if not inside:
        return default
    before = [k for k in inside if k[0] <= frame]
    after = [k for k in inside if k[0] >= frame]
    if not before:
        return after[0][1]
    if not after or before[-1][0] == frame or interpolation == 0:
        return before[-1][1]
    (f0, v0), (f1, v1) = before[-1], after[0]
    t = (frame - f0) / (f1 - f0)
    mixed = [a + (b - a) * t for a, b in zip(v0, v1)]
    if len(mixed) == 4:                                  # quaternion: renormalize
        n = sqrt(sum(m * m for m in mixed))
        mixed = [m / n for m in mixed]
    return tuple(mixed)


def matmul(a, b):
    return [[sum(a[i][k] * b[k][j] for k in range(4)) for j in range(4)] for i in range(4)]


def local_matrix(translation, rotation, scale, pivot):
    """T(pivot + translation) * R(rotation) * S(scale) * T(-pivot), quaternion (x, y, z, w)."""
    x, y, z, w = rotation
    sx, sy, sz = scale
    r = [[1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)],
         [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)],
         [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)]]
    m = [[r[i][0] * sx, r[i][1] * sy, r[i][2] * sz, 0.0] for i in range(3)] + [[0.0, 0.0, 0.0, 1.0]]
    for i in range(3):
        m[i][3] = pivot[i] + translation[i] - (m[i][0] * pivot[0] + m[i][1] * pivot[1] + m[i][2] * pivot[2])
    return m


def world_matrices(model, frame, interval):
    nodes, pivots, cache = model["nodes"], model["pivots"], {}

    def world(node_id):
        if node_id in cache:
            return cache[node_id]
        node = nodes[node_id]
        tracks = node["tracks"]
        local = local_matrix(track_value(tracks.get("KGTR"), frame, interval, (0.0, 0.0, 0.0)),
                             track_value(tracks.get("KGRT"), frame, interval, (0.0, 0.0, 0.0, 1.0)),
                             track_value(tracks.get("KGSC"), frame, interval, (1.0, 1.0, 1.0)),
                             pivots[node_id] if node_id < len(pivots) else (0.0, 0.0, 0.0))
        parent = node["parent"]
        cache[node_id] = matmul(world(parent), local) if parent is not None and parent in nodes else local
        return cache[node_id]
    return world


def geoset_visible(model, index, frame, interval):
    if index not in model["geoset_anims"]:
        return True
    alpha, tracks = model["geoset_anims"][index]
    return track_value(tracks.get("KGAO"), frame, interval, (alpha,))[0] > 0.0


def posed_triangles(model, sequence, hidden_bones=()):
    """World-space triangles (positions, normals, uvs, material) of geosets visible at the frame.

    Faces with a vertex bound to one of `hidden_bones` are left out (a
    spinning rotor's blades, which the game blurs)."""
    interval = model["sequences"][sequence]
    frame = interval[0]
    world = world_matrices(model, frame, interval)
    triangles = []
    for index, geo in enumerate(model["geosets"]):
        if not geoset_visible(model, index, frame, interval):
            continue
        blended = []
        for bones in geo["bones"]:
            mats = [world(b) for b in bones]
            blended.append([[sum(m[i][j] for m in mats) / len(mats) for j in range(4)] for i in range(4)])
        v, nrm, uv = geo["vertices"], geo["normals"], geo["uvs"]
        pos, nor = [], []
        for k in range(len(v) // 3):
            m = blended[geo["groups"][k]]
            x, y, z = v[3 * k], v[3 * k + 1], v[3 * k + 2]
            pos.append(tuple(m[i][0] * x + m[i][1] * y + m[i][2] * z + m[i][3] for i in range(3)))
            nx, ny, nz = nrm[3 * k], nrm[3 * k + 1], nrm[3 * k + 2]
            n = [m[i][0] * nx + m[i][1] * ny + m[i][2] * nz for i in range(3)]
            length = sqrt(n[0] * n[0] + n[1] * n[1] + n[2] * n[2]) or 1.0
            nor.append((n[0] / length, n[1] / length, n[2] / length))
        f = geo["faces"]
        hidden = {k for k in range(len(v) // 3) if set(geo["bones"][geo["groups"][k]]) & set(hidden_bones)}
        for t in range(0, len(f), 3):
            a, b, c = f[t], f[t + 1], f[t + 2]
            if a in hidden or b in hidden or c in hidden:
                continue
            triangles.append(((pos[a], pos[b], pos[c]), (nor[a], nor[b], nor[c]),
                              ((uv[2 * a], uv[2 * a + 1]), (uv[2 * b], uv[2 * b + 1]), (uv[2 * c], uv[2 * c + 1])),
                              geo["material"]))
    return triangles


# ---------------------------------------------------------------------------
# Paletted BLP1 texture (mip 0) with its eight-bit alpha plane.


def read_blp1(data):
    assert data[:4] == b"BLP1", "not a BLP1 texture"
    compression, alpha_bits, width, height = struct.unpack_from("<4I", data, 4)
    if compression == 0:
        return blp1_jpeg_texels(data)
    assert compression == 1 and alpha_bits == 8, "only JPEG or paletted BLP1 with 8-bit alpha is supported"
    offset = struct.unpack_from("<I", data, 28)[0]
    palette = [struct.unpack_from("<4B", data, 156 + 4 * i) for i in range(256)]   # B, G, R, unused
    index = data[offset:offset + width * height]
    alpha = data[offset + width * height:offset + 2 * width * height]
    texels = [(palette[index[i]][2] / 255.0, palette[index[i]][1] / 255.0, palette[index[i]][0] / 255.0,
               alpha[i] / 255.0) for i in range(width * height)]
    return width, height, texels


def sampler(texture, wrap_u, wrap_v):
    width, height, texels = texture

    def fetch(x, y):
        x = x % width if wrap_u else min(max(x, 0), width - 1)
        y = y % height if wrap_v else min(max(y, 0), height - 1)
        return texels[y * width + x]

    def sample(u, v):
        fx, fy = u * width - 0.5, v * height - 0.5
        x0, y0 = int(floor(fx)), int(floor(fy))
        tx, ty = fx - x0, fy - y0
        out = [0.0, 0.0, 0.0, 0.0]
        for dy, wy in ((0, 1.0 - ty), (1, ty)):
            for dx, wx in ((0, 1.0 - tx), (1, tx)):
                texel, weight = fetch(x0 + dx, y0 + dy), wx * wy
                for i in range(4):
                    out[i] += texel[i] * weight
        return out
    return sample


# ---------------------------------------------------------------------------
# Material layers.


def layer_color(model, samplers, layers, u, v):
    """Composite a material's layers as the game does; additive effect layers are skipped."""
    color = None
    for layer in layers:
        texture = model["textures"][layer["texture"]]
        if texture["replaceable"] == 1:
            r, g, b, a = TEAM_RED[0], TEAM_RED[1], TEAM_RED[2], 1.0
        elif texture["replaceable"] or layer["texture"] not in samplers:
            return None                                   # glows/effects without shipped textures
        else:
            r, g, b, a = samplers[layer["texture"]](u, v)
        mode = layer["filter"]
        if mode == 0:                                     # none: opaque
            color = [r, g, b]
        elif mode == 1:                                   # transparent: alpha test
            if a >= 0.75:
                color = [r, g, b]
        elif mode == 2 and color is not None:             # blend over the layers below
            color = [r * a + color[0] * (1.0 - a), g * a + color[1] * (1.0 - a), b * a + color[2] * (1.0 - a)]
        elif mode == 2:
            color = [r, g, b] if a >= 0.5 else None
        else:                                             # additive/modulate effect layers
            return None
    return color


def renderable(model, samplers, layers):
    """Opaque, transparent and blended layers with shipped textures or team color; no effects."""
    for layer in layers:
        replaceable = model["textures"][layer["texture"]]["replaceable"]
        if layer["filter"] > 2 or replaceable > 1 or (replaceable == 0 and layer["texture"] not in samplers):
            return False
    return True


# ---------------------------------------------------------------------------
# Headings without libm trigonometry: half-angle square roots plus symmetry.


def directions():
    """(cos, sin) of k * 2pi/64 for k = 0..63, counter-clockwise from east."""
    h = sqrt(0.5)

    def half(c):
        return sqrt((1.0 + c) / 2.0), sqrt((1.0 - c) / 2.0)

    def add(a, b):
        return a[0] * b[0] - a[1] * b[1], a[1] * b[0] + a[0] * b[1]

    def sub(a, b):
        return a[0] * b[0] + a[1] * b[1], a[1] * b[0] - a[0] * b[1]
    e8 = half(h)               # pi/8
    e16 = half(e8[0])          # pi/16
    e32 = half(e16[0])         # pi/32
    q = (h, h)
    octant = [(1.0, 0.0), e32, e16, add(e16, e32), e8, add(e8, e32), sub(q, e16), sub(q, e32), q]
    first = octant + [(s, c) for c, s in reversed(octant[:-1])]      # 0 .. pi/2 inclusive
    table = []
    for k in range(FRAMES):
        quadrant, j = divmod(k, 16)
        c, s = first[j]
        for _ in range(quadrant):
            c, s = -s, c
        table.append((c, s))
    return table


# ---------------------------------------------------------------------------
# Three-quarter frames: model +X (front) turned to the heading; camera tilted
# toward north. Screen x = east, screen y = north * cos + height * sin.


def placed(triangles, fit, cx, cy, c, s):
    """World-space (east, north, up) vertices for one heading, plus turned normals."""
    out = []
    for (p0, p1, p2), normals, uvs, material in triangles:
        pts = []
        for p in (p0, p1, p2):
            mx, my, mz = (p[0] - cx) * fit, (p[1] - cy) * fit, p[2] * fit
            pts.append((mx * c - my * s, mx * s + my * c, mz))
        nrm = [(n[0] * c - n[1] * s, n[0] * s + n[1] * c, n[2]) for n in normals]
        out.append((pts, nrm, uvs, material))
    return out


def screen(p):
    return p[0], p[1] * TILT_COS + p[2] * TILT_SIN, p[2] * TILT_COS - p[1] * TILT_SIN


def ground_shadow(p):
    return p[0] + p[2] * SHADOW_VECTOR[0], (p[1] + p[2] * SHADOW_VECTOR[1]) * TILT_COS


def rasterize(points, columns, rows, visit):
    """Call visit(index, w0, w1, w2) for every sample center inside the triangle."""
    (x0, y0), (x1, y1), (x2, y2) = points
    area = (x1 - x0) * (y2 - y0) - (x2 - x0) * (y1 - y0)
    if area == 0.0:
        return
    c0, c1 = max(0, int(floor(min(x0, x1, x2)))), min(columns - 1, int(floor(max(x0, x1, x2))))
    r0, r1 = max(0, int(floor(min(y0, y1, y2)))), min(rows - 1, int(floor(max(y0, y1, y2))))
    for r in range(r0, r1 + 1):
        py = r + 0.5
        for c in range(c0, c1 + 1):
            px = c + 0.5
            w1 = ((px - x0) * (y2 - y0) - (x2 - x0) * (py - y0)) / area
            w2 = ((x1 - x0) * (py - y0) - (px - x0) * (y1 - y0)) / area
            w0 = 1.0 - w1 - w2
            if w0 >= 0.0 and w1 >= 0.0 and w2 >= 0.0:
                visit(r * columns + c, w0, w1, w2)


def render_frame(model, samplers, world, quad, pivot, ss=SUPERSAMPLE, size=FRAME, disc=None):
    """One heading's frame. `disc` = (x, y, radius, color, alpha) is a spinning
    rotor's blur: a horizontal disc at screen point (x, y), drawn over the body."""
    left, top = pivot[0] - quad / 2, pivot[1] + quad / 2
    canvas = Canvas(size, size, ss, left, pivot[1] - quad / 2, quad, quad)
    columns, rows, step = canvas.columns, canvas.rows, canvas.step

    def to_samples(x, y):
        return (x - left) / step, (top - y) / step
    # Ground shadow: coverage of every triangle flattened along the sun, at sample resolution.
    shade = bytearray(columns * rows)

    def mark(i, w0, w1, w2):
        shade[i] = 1
    for pts, normals, uvs, material in world:
        rasterize([to_samples(*ground_shadow(p)) for p in pts], columns, rows, mark)
    depth = [-1e30] * (columns * rows)
    red, green, blue, alpha = canvas.red, canvas.green, canvas.blue, canvas.alpha
    for pts, normals, uvs, material in world:
        layers = model["materials"][material]
        proj = [screen(p) for p in pts]
        zs = [p[2] for p in proj]

        def shade_fragment(i, w0, w1, w2):
            z = w0 * zs[0] + w1 * zs[1] + w2 * zs[2]
            if z <= depth[i]:
                return
            u = w0 * uvs[0][0] + w1 * uvs[1][0] + w2 * uvs[2][0]
            v = w0 * uvs[0][1] + w1 * uvs[1][1] + w2 * uvs[2][1]
            color = layer_color(model, samplers, layers, u, v)
            if color is None:
                return
            nx = w0 * normals[0][0] + w1 * normals[1][0] + w2 * normals[2][0]
            ny = w0 * normals[0][1] + w1 * normals[1][1] + w2 * normals[2][1]
            nz = w0 * normals[0][2] + w1 * normals[1][2] + w2 * normals[2][2]
            length = sqrt(nx * nx + ny * ny + nz * nz) or 1.0
            k = (nx * LX + ny * LY + nz * LZ) / length
            light = AMBIENT + DIFFUSE * (k if k > 0.0 else 0.0)
            depth[i] = z
            red[i] = min(1.0, color[0] * light)
            green[i] = min(1.0, color[1] * light)
            blue[i] = min(1.0, color[2] * light)
            alpha[i] = 1.0
        rasterize([to_samples(p[0], p[1]) for p in proj], columns, rows, shade_fragment)
    if disc is not None:
        # The game draws a spinning rotor as a translucent blur disc; this is
        # an original stand-in (the model's own blur texture is not shipped):
        # a faint disc with a brighter rim, seen at the camera's tilt.
        dx0, dy0, radius, color, opacity = disc
        for r in range(rows):
            y = (top - (r + 0.5) * step - dy0) / TILT_COS
            for c in range(columns):
                x = left + (c + 0.5) * step - dx0
                d2 = (x * x + y * y) / (radius * radius)
                if d2 >= 1.0:
                    continue
                a = opacity * (0.55 + 0.45 * d2 * d2)              # brighter toward the blade tips
                i = r * columns + c
                if alpha[i] > 0.0:
                    red[i] = red[i] * (1.0 - a) + color[0] * a
                    green[i] = green[i] * (1.0 - a) + color[1] * a
                    blue[i] = blue[i] * (1.0 - a) + color[2] * a
                else:
                    red[i], green[i], blue[i], alpha[i] = color[0], color[1], color[2], a
    body = canvas.resolve()
    # Shadow coverage per texel (exact integer count), softened by a 1-2-1 blur.
    cover = [[0] * size for _ in range(size)]
    for j in range(size):
        for i in range(size):
            count = 0
            for b in range(ss):
                base = (j * ss + b) * columns + i * ss
                for a in range(ss):
                    count += shade[base + a]
            cover[j][i] = count
    blurred = [[0] * size for _ in range(size)]
    weights = ((-1, 1), (0, 2), (1, 1))
    for j in range(size):
        for i in range(size):
            total = 0
            for dj, wj in weights:
                for di, wi in weights:
                    y, x = j + dj, i + di
                    if 0 <= y < size and 0 <= x < size:
                        total += cover[y][x] * wj * wi
            blurred[j][i] = total            # out of 16 * ss * ss
    full = 16 * ss * ss
    frame = []
    for j in range(size):
        row = []
        for i in range(size):
            r, g, b, a = body[j][i]
            va = a / 255.0
            sa = SHADOW_ALPHA * blurred[j][i] / full * (1.0 - va)
            out_a = va + sa
            if out_a <= 0.0:
                row.append([0, 0, 0, 0])
                continue
            rgb = [(body[j][i][k] / 255.0 * va + SHADOW_COLOR[k] * sa) / out_a for k in range(3)]
            row.append([int(rgb[0] * 255.0 + 0.5), int(rgb[1] * 255.0 + 0.5), int(rgb[2] * 255.0 + 0.5),
                        int(out_a * 255.0 + 0.5)])
        frame.append(row)
    # Keep a transparent one-texel border so neighboring frames never filter in.
    for j in range(size):
        for i in range(size):
            if j in (0, size - 1) or i in (0, size - 1):
                frame[j][i] = [0, 0, 0, 0]
    return bleed(frame)


def pose(source, vehicle=TRIKE):
    model = read_model((source / vehicle["model"]).read_bytes())
    # Textures shipped with the vehicle, matched by the model's own paths
    # (case-insensitively; a bare file name may also match). Layers whose
    # texture is not shipped (particle and glow effects) are not drawn.
    shipped = {name.lower(): name for name in vehicle["sha256"] if name != vehicle["model"]}
    by_name = {name.rsplit("/", 1)[-1]: name for name in shipped}
    samplers, decoded = {}, {}
    for index, entry in enumerate(model["textures"]):
        wanted = entry["file"].replace("\\", "/").lower()
        name = shipped.get(wanted) or shipped.get(by_name.get(wanted.rsplit("/", 1)[-1], ""))
        if entry["replaceable"] == 0 and name:
            if name not in decoded:
                decoded[name] = read_blp1((source / name).read_bytes())
            samplers[index] = sampler(decoded[name], entry["flags"] & 1, entry["flags"] & 2)
        elif entry["replaceable"] == 0 and wanted in vehicle.get("substitute", {}):
            # A texture the archive does not ship: an original flat stand-in.
            r, g, b = vehicle["substitute"][wanted]
            samplers[index] = (lambda r, g, b: lambda u, v: [r, g, b, 1.0])(r, g, b)
    triangles = [t for t in posed_triangles(model, vehicle["sequence"], vehicle.get("hide_bones", ()))
                 if renderable(model, samplers, model["materials"][t[3]])]
    xs = [p[0] for t in triangles for p in t[0]]
    ys = [p[1] for t in triangles for p in t[0]]
    axis, span = vehicle["fit"]
    fit = span / ((max(ys) - min(ys)) if axis == "width" else (max(xs) - min(xs)))   # model Y is the width
    cx, cy = (max(xs) + min(xs)) / 2, (max(ys) + min(ys)) / 2
    model["lift"] = 0.0
    if vehicle.get("hover") is not None:                # a flyer: lift its lowest point to the hover height
        model["lift"] = vehicle["hover"] / fit - min(p[2] for t in triangles for p in t[0])
        triangles = [(tuple((p[0], p[1], p[2] + model["lift"]) for p in pts), normals, uvs, material)
                     for pts, normals, uvs, material in triangles]
    return model, samplers, triangles, fit, cx, cy


def emitters(source, posed, vehicle=TRIKE):
    """The model's particle emitters in the kart's frame (+x forward, +y left, z up), world units.

    Presentation.KART_SPRITES places drift and boost effects at these points:
    the rear-wheel dust emitters set where tire effects start and the exhaust
    emitters are the boost flames' pipes. Not part of the sheet's bytes."""
    model, samplers, triangles, fit, cx, cy = posed
    interval = model["sequences"][vehicle["sequence"]]
    world = world_matrices(model, interval[0], interval)
    raw, o, found = chunks((source / vehicle["model"]).read_bytes()).get("PRE2", b""), 0, []
    while o < len(raw):
        inclusive = struct.unpack_from("<I", raw, o)[0]
        name = cstring(raw[o + 8:o + 88])
        object_id, parent = struct.unpack_from("<II", raw, o + 88)
        p = model["pivots"][object_id]
        if parent != 0xFFFFFFFF and parent in model["nodes"]:
            m = world(parent)
            p = [m[i][0] * p[0] + m[i][1] * p[1] + m[i][2] * p[2] + m[i][3] for i in range(3)]
        found.append((name, (p[0] - cx) * fit, (p[1] - cy) * fit, (p[2] + model["lift"]) * fit))
        o += inclusive
    return found


def rear_contacts(posed):
    """Trailing edge and mean side offset of the lowest geometry on each side (kart frame)."""
    model, samplers, triangles, fit, cx, cy = posed
    points = [((p[0] - cx) * fit, (p[1] - cy) * fit, p[2] * fit) for t in triangles for p in t[0]]
    floor_z = min(p[2] for p in points)
    low = [p for p in points if p[2] < floor_z + 1.0 and p[0] < 0.0]
    sides = []
    for sign in (1, -1):
        side = [p for p in low if p[1] * sign > 1.0]
        if side:
            sides.append((min(p[0] for p in side), sum(p[1] for p in side) / len(side)))
    return floor_z, sides


def window_bounds(posed):
    """Screen-space extent of trike plus shadow over all headings, in world units."""
    model, samplers, triangles, fit, cx, cy = posed
    xmin = ymin = 1e30
    xmax = ymax = -1e30
    for c, s in directions():
        for pts, normals, uvs, material in placed(triangles, fit, cx, cy, c, s):
            for p in pts:
                for x, y in (screen(p)[:2], ground_shadow(p)):
                    xmin, xmax, ymin, ymax = min(xmin, x), max(xmax, x), min(ymin, y), max(ymax, y)
    return xmin, xmax, ymin, ymax


def build(source, vehicle=TRIKE):
    posed = pose(source, vehicle)
    model, samplers, triangles, fit, cx, cy = posed
    xmin, xmax, ymin, ymax = window_bounds(posed)
    quad, (px, py) = vehicle["quad"], vehicle["pivot"]
    inner = quad / 2 * (FRAME - 4) / FRAME              # keep two texels clear of each frame edge
    assert px - inner <= xmin and xmax <= px + inner and py - inner <= ymin and ymax <= py + inner, \
        f"{vehicle['name']} and shadow ({xmin:.2f}..{xmax:.2f}, {ymin:.2f}..{ymax:.2f}) exceed the frame window"
    rotor = vehicle.get("rotor")
    frames = []
    for c, s in directions():
        disc = None
        if rotor:
            hx, hy, hz = rotor["hub"]
            mx, my = (hx - cx) * fit, (hy - cy) * fit
            wx, wy = mx * c - my * s, mx * s + my * c
            radius = rotor["radius"] * fit
            disc = (wx, wy * TILT_COS + (hz + model["lift"]) * fit * TILT_SIN, radius, rotor["color"], rotor["alpha"])
            assert px - inner <= wx - radius and wx + radius <= px + inner and \
                py - inner <= disc[1] - radius * TILT_COS and disc[1] + radius * TILT_COS <= py + inner, \
                f"{vehicle['name']}'s rotor disc exceeds the frame window"
        frames.append(render_frame(model, samplers, placed(triangles, fit, cx, cy, c, s), quad, vehicle["pivot"],
                                   disc=disc))
    sheet = [[None] * ATLAS for _ in range(ATLAS)]
    for k, frame in enumerate(frames):
        ox, oy = (k % COLUMNS) * FRAME, (k // COLUMNS) * FRAME
        for j in range(FRAME):
            sheet[oy + j][ox:ox + FRAME] = frame[j]
    return sheet, frames, fit, (xmin, xmax, ymin, ymax)


# ---------------------------------------------------------------------------
# Validation: packaging, frame borders and coverage, heading order.


def validate(image, vehicle=TRIKE):
    fields, px = decode_tga(image)
    assert fields == (0, 0, 2, 0, 0, 0, 0, 0, ATLAS, ATLAS, 32, 8), "Unexpected TGA header"
    assert len(image) == 18 + ATLAS * ATLAS * 4, "Unexpected TGA payload size"
    counts = []
    for k in range(FRAMES):
        ox, oy = (k % COLUMNS) * FRAME, (k // COLUMNS) * FRAME
        solid = 0
        for j in range(FRAME):
            for i in range(FRAME):
                a = px[oy + j][ox + i][3]
                if j in (0, FRAME - 1) or i in (0, FRAME - 1):
                    assert a == 0, f"frame {k}: border texel must stay transparent"
                solid += a == 255
        assert solid > vehicle["min_solid"] * FRAME * FRAME, f"frame {k}: {vehicle['name']} unexpectedly small"
        counts.append(solid)
    # A vehicle turned by 180 degrees is a different picture: frames must not repeat.
    for k in range(FRAMES // 2):
        ox, oy = (k % COLUMNS) * FRAME, (k // COLUMNS) * FRAME
        k2 = k + FRAMES // 2
        ox2, oy2 = (k2 % COLUMNS) * FRAME, (k2 // COLUMNS) * FRAME
        assert any(px[oy + j][ox + i] != px[oy2 + j][ox2 + i] for j in range(FRAME) for i in range(FRAME)), \
            f"frames {k} and {k2} are identical"
    return min(counts), max(counts)


def verify_sources(source, vehicle=TRIKE):
    for name, digest in vehicle["sha256"].items():
        path = source / name
        if not path.is_file():
            raise SystemExit(f"Missing {path}; extract {vehicle['archive']} there (see docs/art/karts/)")
        actual = hashlib.sha256(path.read_bytes()).hexdigest()
        if actual != digest:
            raise SystemExit(f"{name} sha256 {actual} differs from the documented {digest}")


# ---------------------------------------------------------------------------
# Review sheet (not a runtime file; PNG bytes depend on the local zlib).


def review_sheet(frames, vehicle=TRIKE):
    from math import pi                   # preview-only; not part of the asset bytes
    from build_kart_sprites import background_color, load_background
    from paintkit import sample_bilinear
    bg = load_background()

    def tile(heading, kx, ky, pixels_per_unit, size=96, tint=(1.0, 1.0, 1.0)):
        k = int(floor(heading / (2 * pi / FRAMES) + 0.5)) % FRAMES
        frame = frames[k]
        rows = []
        for j in range(size):
            row = []
            for i in range(size):
                dx, dy = (i + 0.5 - size / 2) / pixels_per_unit, (size / 2 - j - 0.5) / pixels_per_unit
                base = background_color(bg, kx + dx, ky + dy)
                quad, (px, py) = vehicle["quad"], vehicle["pivot"]
                u = (dx - px + quad / 2) / quad * FRAME
                v = (py + quad / 2 - dy) / quad * FRAME
                r, g, b, a = sample_bilinear(frame, u, v) if 0 <= u < FRAME and 0 <= v < FRAME else (0, 0, 0, 0)
                a /= 255.0
                row.append([int(min(255.0, r * tint[0]) * a + base[0] * (1 - a) + 0.5),
                            int(min(255.0, g * tint[1]) * a + base[1] * (1 - a) + 0.5),
                            int(min(255.0, b * tint[2]) * a + base[2] * (1 - a) + 0.5), 255])
            rows.append(row)
        return rows
    spots = [(700, 360), (676, 610), (560, 900), (300, 700), (420, 520), (470, 160), (540, 140), (680, 250)]
    rows = []
    for ppu in (1.08, 1.47):              # about 1080p and 1440p at 0.72 UI scale, camera scale 1.5
        rows.append([tile(pi / 2 - n * pi / 4, x, y, ppu) for n, (x, y) in enumerate(spots)])
    # The in-between headings at the larger size; the UI draws loaded art untinted.
    rows.append([tile(pi / 2 - n * pi / 4 + pi / 8, 700, 600, 1.47) for n in range(8)])
    zoom, gap, size = 2, 4, 96
    atlas_px = ATLAS // 2                  # the sheet itself at half size
    width = atlas_px + gap * 3 + 8 * size * zoom // 2 + 7 * gap
    tile_px = size * zoom // 2
    height = max(atlas_px, 3 * tile_px + 2 * gap) + 2 * gap
    sheet = [[[28, 28, 32, 255] for _ in range(width)] for _ in range(height)]
    for y in range(atlas_px):
        for x in range(atlas_px):
            k = (y * 2 // FRAME) * COLUMNS + x * 2 // FRAME
            r, g, b, a = frames[k][(y * 2) % FRAME][(x * 2) % FRAME]
            check = 170 if ((x // 8) + (y // 8)) % 2 else 120
            sheet[gap + y][gap + x] = [(r * a + check * (255 - a) + 127) // 255,
                                       (g * a + check * (255 - a) + 127) // 255,
                                       (b * a + check * (255 - a) + 127) // 255, 255]
    for r_index, row in enumerate(rows):
        for c_index, t in enumerate(row):
            ox = atlas_px + 2 * gap + c_index * (tile_px + gap)
            oy = gap + r_index * (tile_px + gap)
            for y in range(tile_px):
                for x in range(tile_px):
                    sheet[oy + y][ox + x] = t[y * size // tile_px][x * size // tile_px]
    return sheet


def run(vehicle, source, check, preview):
    verify_sources(source, vehicle)
    sheet, frames, fit, bounds = build(source, vehicle)
    image = encode_tga(sheet)
    fewest, most = validate(image, vehicle)
    output = ASSETS / vehicle["output"]
    if check:
        if not output.is_file() or output.read_bytes() != image:
            raise SystemExit(f"STALE: {output.relative_to(ROOT).as_posix()}; run without --check")
    else:
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_bytes(image)
    xmin, xmax, ymin, ymax = bounds
    quad, (px, py) = vehicle["quad"], vehicle["pivot"]
    print(f'{"CHECK PASS" if check else "GENERATED"}: {output.relative_to(ROOT).as_posix()}; '
          f"{vehicle_id(vehicle)} {ATLAS}x{ATLAS} BGRA32 straight alpha bottom-left; {len(image)} bytes; "
          f"{FRAMES} frames of {FRAME}x{FRAME} texels over {quad:g} world units (center {px:g} east, "
          f"{py:g} north); "
          f"{fewest}-{most} opaque texels per frame; extent x {xmin:.2f}..{xmax:.2f}, y {ymin:.2f}..{ymax:.2f}; "
          f"model scale {fit:.5f}; sha256={hashlib.sha256(image).hexdigest()}")
    if preview and not check:
        DOCS.mkdir(parents=True, exist_ok=True)
        (DOCS / f"{vehicle['slug']}-review.png").write_bytes(encode_png(review_sheet(frames, vehicle)))
        print(f"PREVIEW: docs/art/karts/{vehicle['slug']}-review.png")


def vehicle_id(vehicle):
    return next(key for key, value in VEHICLES.items() if value is vehicle)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    where = parser.add_mutually_exclusive_group(required=True)
    where.add_argument("--source", type=Path, help="one vehicle's extracted files")
    where.add_argument("--all", type=Path, metavar="ROOT", help="build every vehicle from ROOT/<slug>/")
    parser.add_argument("--vehicle", choices=sorted(VEHICLES), default="goblin_mortar_trike",
                        help="the vehicle in --source (default: the Goblin Mortar Trike)")
    parser.add_argument("--check", action="store_true", help="verify exact runtime bytes without writing")
    parser.add_argument("--preview", action="store_true", help="also write review PNGs under docs/art/karts/")
    parser.add_argument("--emitters", action="store_true",
                        help="list each model's particle emitters and rear ground contacts in the kart's frame")
    args = parser.parse_args()
    jobs = ([(VEHICLES[args.vehicle], args.source)] if args.source else
            [(vehicle, args.all / vehicle["slug"]) for vehicle in VEHICLES.values()])
    for vehicle, source in jobs:
        if args.emitters:
            verify_sources(source, vehicle)
            posed = pose(source, vehicle)
            print(f"{vehicle['name']}:")
            for name, x, y, z in emitters(source, posed, vehicle):
                print(f"  {name}: forward {x:.2f}, left {y:.2f}, up {z:.2f}")
            floor_z, sides = rear_contacts(posed)
            for x, y in sides:
                print(f"  rear ground contact: trailing edge forward {x:.2f}, left {y:.2f} (floor {floor_z:.2f})")
            continue
        run(vehicle, source, args.check, args.preview)


if __name__ == "__main__":
    main()
