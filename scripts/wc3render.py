"""Render Warcraft III scenery models as sprites for Azeroth Kart's city tracks.

Library for build_city_tracks.py. It reads the Reforged client's classic
("SD") art as the owner's install stores it: MDX models of versions 800 to
1800 and their DXT-compressed .dds textures, extracted by scripts/wc3casc.py.
Nothing here ships: only the finished track pictures do.

A sprite shows its model from the karts' Warcraft III-style camera
(build_wc3_kart.py): tilted 36.87 degrees from vertical and looking north,
lit by the scenery's north-west sun, with a soft ground shadow to the
south-east. Unlike a kart frame, the ground is not foreshortened: a point at
ground position (x, y) and height h draws at (x, y + 0.75 h), the same height
lean as the karts' but with the ground plane kept 1:1. A model's footprint
therefore lands exactly on its collision box in the top-down world, and only
its height leans north.

Standard library only. Pixel values come from IEEE arithmetic (+ - * /,
sqrt, floor) and integer DXT decoding, so the bytes are reproducible.
"""
import struct
from math import floor, sqrt

import build_wc3_kart as kart
from paintkit import Canvas, bleed

LEAN = kart.TILT_SIN / kart.TILT_COS          # 0.75: screen rise per unit of height
SUPERSAMPLE = 3

# Exact (cos, sin) for the yaw angles scenery uses (degrees, counter-clockwise).
_H = sqrt(0.5)
YAWS = {0: (1.0, 0.0), 45: (_H, _H), 90: (0.0, 1.0), 135: (-_H, _H), 180: (-1.0, 0.0),
        225: (-_H, -_H), 270: (0.0, -1.0), 315: (_H, -_H)}


# ---------------------------------------------------------------------------
# DXT1/3/5 (BC1-3) textures, mip level 0.


def _rgb565(value):
    r, g, b = (value >> 11) & 31, (value >> 5) & 63, value & 31
    return (r * 255 + 15) // 31, (g * 255 + 31) // 63, (b * 255 + 15) // 31


def _color_block(block, offset, punch):
    c0, c1, bits = struct.unpack_from("<HHI", block, offset)
    p0, p1 = _rgb565(c0), _rgb565(c1)
    if c0 > c1 or not punch:
        p2 = tuple((2 * a + b + 1) // 3 for a, b in zip(p0, p1))
        p3 = tuple((a + 2 * b + 1) // 3 for a, b in zip(p0, p1))
        palette = (p0 + (255,), p1 + (255,), p2 + (255,), p3 + (255,))
    else:
        p2 = tuple((a + b) // 2 for a, b in zip(p0, p1))
        palette = (p0 + (255,), p1 + (255,), p2 + (255,), (0, 0, 0, 0))
    return [palette[(bits >> (2 * i)) & 3] for i in range(16)]


def _alpha_block(block, offset):
    a0, a1 = block[offset], block[offset + 1]
    bits = int.from_bytes(block[offset + 2:offset + 8], "little")
    if a0 > a1:
        table = [a0, a1] + [((7 - i) * a0 + i * a1 + 3) // 7 for i in range(1, 7)]
    else:
        table = [a0, a1] + [((5 - i) * a0 + i * a1 + 2) // 5 for i in range(1, 5)] + [0, 255]
    return [table[(bits >> (3 * i)) & 7] for i in range(16)]


def read_dds(data):
    """(width, height, texels) with texels as (r, g, b, a) floats, top row first."""
    assert data[:4] == b"DDS ", "not a DDS texture"
    height, width = struct.unpack_from("<II", data, 12)
    fourcc = data[84:88]
    step = {b"DXT1": 8, b"DXT3": 16, b"DXT5": 16}.get(fourcc)
    assert step, f"unsupported DDS format {fourcc!r}"
    texels = [None] * (width * height)
    offset = 128
    for by in range(0, height, 4):
        for bx in range(0, width, 4):
            if fourcc == b"DXT1":
                colors = _color_block(data, offset, True)
                alphas = None
            elif fourcc == b"DXT3":
                raw = int.from_bytes(data[offset:offset + 8], "little")
                alphas = [((raw >> (4 * i)) & 15) * 17 for i in range(16)]
                colors = _color_block(data, offset + 8, False)
            else:
                alphas = _alpha_block(data, offset)
                colors = _color_block(data, offset + 8, False)
            offset += step
            for i in range(16):
                x, y = bx + (i & 3), by + (i >> 2)
                if x < width and y < height:
                    r, g, b, a = colors[i]
                    if alphas is not None:
                        a = alphas[i]
                    texels[y * width + x] = (r / 255.0, g / 255.0, b / 255.0, a / 255.0)
    return width, height, texels


# ---------------------------------------------------------------------------
# MDX models, versions 800 (classic) to 1800 (Reforged SD).


def read_model(data):
    c = kart.chunks(data)
    version = struct.unpack_from("<I", c["VERS"])[0]
    assert 800 <= version <= 1800, f"unsupported MDX version {version}"
    model = {"version": version, "sequences": {}, "textures": [], "materials": [], "geosets": [],
             "geoset_anims": {}, "nodes": {}, "pivots": []}
    seqs = c.get("SEQS", b"")
    for i in range(len(seqs) // 132):
        o = i * 132
        start, end = struct.unpack_from("<2I", seqs, o + 80)
        model["sequences"][kart.cstring(seqs[o:o + 80])] = (start, end)
    texs = c.get("TEXS", b"")
    for i in range(len(texs) // 268):
        o = i * 268
        model["textures"].append({"replaceable": struct.unpack_from("<I", texs, o)[0],
                                  "file": kart.cstring(texs[o + 4:o + 264]),
                                  "flags": struct.unpack_from("<I", texs, o + 264)[0]})
    mtls, o = c.get("MTLS", b""), 0
    while o < len(mtls):
        size = struct.unpack_from("<I", mtls, o)[0]
        lays = mtls.find(b"LAYS", o + 12, o + size)
        assert lays >= 0, "material without layers"
        count, p, layers = struct.unpack_from("<I", mtls, lays + 4)[0], lays + 8, []
        for _ in range(count):
            lsize, filter_mode, shading, texture, _anim, coord, alpha = struct.unpack_from("<6If", mtls, p)
            if version > 1000:
                # Reforged layers list their textures (id, slot) after the
                # fresnel fields; slot 0 is the diffuse map.
                n = struct.unpack_from("<I", mtls, p + 56)[0]
                if n:
                    texture = struct.unpack_from("<I", mtls, p + 60)[0]
            layers.append({"filter": filter_mode, "shading": shading, "texture": texture,
                           "coord": coord, "alpha": alpha})
            p += lsize
        model["materials"].append(layers)
        o += size
    geos, o = c.get("GEOS", b""), 0
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
        types = take(b"PTYP", "I", 1)
        take(b"PCNT", "I", 1)
        faces, groups = take(b"PVTX", "H", 1), take(b"GNDX", "B", 1)
        group_sizes, matrices = take(b"MTGC", "I", 1), take(b"MATS", "I", 1)
        material = struct.unpack_from("<I", geos, p)[0]
        p += 12
        if version >= 900:
            p += 84                                   # level of detail and its name
        p += 28
        p += 4 + 28 * struct.unpack_from("<I", geos, p)[0]
        if geos[p:p + 4] == b"TANG":
            p += 8 + 16 * struct.unpack_from("<I", geos, p + 4)[0]
        if geos[p:p + 4] == b"SKIN":
            # Reforged skin weights; static scenery stays in its bind pose.
            p = geos.index(b"UVAS", p + 8)
        assert geos[p:p + 4] == b"UVAS", geos[p:p + 4]
        p += 8
        uvs = take(b"UVBS", "f", 2)
        if set(types) != {4}:
            model["geosets"].append(None)             # strips/fans: not used by scenery
            o += size
            continue
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
            tag, interpolation, global_seq, keys, p = kart.read_track(anims, p)
            tracks[tag] = (interpolation, global_seq, keys)
        model["geoset_anims"][geoset] = (alpha, tracks)
        o += size
    for tag, extra in (("BONE", 8), ("HELP", 0)):
        raw, o = c.get(tag, b""), 0
        while o < len(raw):
            node, o = kart.read_node(raw, o)
            o += extra
            model["nodes"][node["id"]] = node
    pivots = c.get("PIVT", b"")
    model["pivots"] = [struct.unpack_from("<3f", pivots, i * 12) for i in range(len(pivots) // 12)]
    return model


# ---------------------------------------------------------------------------
# Loading a model with its textures from an extraction folder.


def texture_path(root, mod, name):
    """The extracted file for a model's texture name (.blp names are stored as .dds)."""
    stem = name.replace("\\", "/").lower().rsplit(".", 1)[0]
    for base in (mod, "war3.w3mod"):
        for ext in (".dds",):
            path = root.joinpath(*base.split(":"), *stem.split("/")).with_suffix(ext)
            if path.is_file():
                return path
    return None


_TEXTURES = {}


def archive_file(root, path):
    return root.joinpath(*path.replace(":", "/").split("/"))


def load(root, path, team=(0.0, 0.26, 1.0), replaceables=None):
    """(model, samplers, team) for an extracted model; `path` is its archive path.

    `replaceables` maps Warcraft III replaceable texture ids to the archive
    path a tileset gives them (11: its cliff texture, which bridges wear;
    31: its tree texture). Team color (1) is the flat `team` color."""
    mod = path.rsplit(":", 1)[0] if ":" in path else "war3.w3mod"
    model = read_model(archive_file(root, path).read_bytes())
    samplers = {}
    # Only the textures the layers draw. A Reforged material also names its
    # normal, ORM and environment maps (BC5 and others, not decoded here),
    # which `wc3casc.py models` extracts with the model.
    drawn = {layer["texture"] for material in model["materials"] for layer in material}
    for index, entry in enumerate(model["textures"]):
        if index not in drawn:
            continue
        found = None
        if entry["replaceable"] and replaceables and entry["replaceable"] in replaceables:
            found = archive_file(root, replaceables[entry["replaceable"]])
            entry["replaceable"] = 0
        elif not entry["replaceable"] and entry["file"]:
            found = texture_path(root, mod, entry["file"])
        if found is None or not found.is_file():
            continue
        model.setdefault("texture_files", []).append(found.relative_to(root).as_posix())
        if found not in _TEXTURES:
            _TEXTURES[found] = read_dds(found.read_bytes())
        samplers[index] = kart.sampler(_TEXTURES[found], entry["flags"] & 1, entry["flags"] & 2)
    return model, samplers, team


def posed_triangles(model, sequence):
    """World-space triangles of the geosets visible at the sequence's first
    frame, as the kart renderer poses them. Reforged's skinned (group-less)
    geosets stay in their bind pose; static scenery does not move."""
    interval = model["sequences"][sequence]
    frame = interval[0]
    world = kart.world_matrices(model, frame, interval)
    triangles = []
    for index, geo in enumerate(model["geosets"]):
        if geo is None or not kart.geoset_visible(model, index, frame, interval):
            continue
        v, nrm, uv = geo["vertices"], geo["normals"], geo["uvs"]
        if geo["groups"]:
            blended = []
            for bones in geo["bones"]:
                mats = [world(b) for b in bones]
                blended.append([[kart.total(m[i][j] for m in mats) / len(mats) for j in range(4)] for i in range(4)])
        pos, nor = [], []
        for k in range(len(v) // 3):
            x, y, z = v[3 * k], v[3 * k + 1], v[3 * k + 2]
            nx, ny, nz = nrm[3 * k], nrm[3 * k + 1], nrm[3 * k + 2]
            if geo["groups"]:
                m = blended[geo["groups"][k]]
                x, y, z = (m[i][0] * x + m[i][1] * y + m[i][2] * z + m[i][3] for i in range(3))
                nx, ny, nz = (m[i][0] * nx + m[i][1] * ny + m[i][2] * nz for i in range(3))
            length = sqrt(nx * nx + ny * ny + nz * nz) or 1.0
            pos.append((x, y, z))
            nor.append((nx / length, ny / length, nz / length))
        f = geo["faces"]
        for t in range(0, len(f), 3):
            a, b, c = f[t], f[t + 1], f[t + 2]
            triangles.append(((pos[a], pos[b], pos[c]), (nor[a], nor[b], nor[c]),
                              ((uv[2 * a], uv[2 * a + 1]), (uv[2 * b], uv[2 * b + 1]), (uv[2 * c], uv[2 * c + 1])),
                              geo["material"]))
    return triangles


def layer_color(model, samplers, team, layers, u, v):
    """The kart renderer's layer compositing, with this scene's team color."""
    color = None
    for layer in layers:
        texture = model["textures"][layer["texture"]]
        if texture["replaceable"] == 1:
            r, g, b, a = team[0], team[1], team[2], 1.0
        elif texture["replaceable"] or layer["texture"] not in samplers:
            return None
        else:
            r, g, b, a = samplers[layer["texture"]](u, v)
        mode = layer["filter"]
        if mode == 0:
            color = [r, g, b]
        elif mode == 1:
            if a >= 0.75:
                color = [r, g, b]
        elif mode == 2 and color is not None:
            color = [r * a + color[0] * (1.0 - a), g * a + color[1] * (1.0 - a), b * a + color[2] * (1.0 - a)]
        elif mode == 2:
            color = [r, g, b] if a >= 0.5 else None
        else:
            return None
    return color


def renderable(model, samplers, layers):
    for layer in layers:
        replaceable = model["textures"][layer["texture"]]["replaceable"]
        if layer["filter"] > 2 or replaceable > 1 or (replaceable == 0 and layer["texture"] not in samplers):
            return False
    return True


# ---------------------------------------------------------------------------
# Sprites.


def posed(loaded, sequence="Stand", scale=0.25, yaw=270, lift=0.0):
    """World-space triangles: model origin at (0, 0), turned by `yaw` degrees,
    `scale` world units per model unit (0.25: one terrain cell is 32 units)."""
    model, samplers, team = loaded
    names = list(model["sequences"])
    if sequence not in model["sequences"]:
        sequence = next((n for n in names if n.lower().startswith(sequence.lower())), names[0] if names else None)
    if sequence is None:
        model["sequences"]["Stand"] = (0, 0)
        sequence = "Stand"
    c, s = YAWS[yaw] if yaw in YAWS else (None, None)
    assert c is not None, f"yaw {yaw} must be a multiple of 45 degrees"
    out = []
    for (p0, p1, p2), normals, uvs, material in posed_triangles(model, sequence):
        if not renderable(model, samplers, model["materials"][material]):
            continue
        pts = []
        for p in (p0, p1, p2):
            x, y, z = p[0] * scale, p[1] * scale, (p[2] + lift) * scale
            pts.append((x * c - y * s, x * s + y * c, z))
        nrm = [(n[0] * c - n[1] * s, n[0] * s + n[1] * c, n[2]) for n in normals]
        out.append((pts, nrm, uvs, material))
    return out


def bounds(triangles):
    xs = [p[0] for t in triangles for p in t[0]]
    ys = [p[1] for t in triangles for p in t[0]]
    zs = [p[2] for t in triangles for p in t[0]]
    return min(xs), max(xs), min(ys), max(ys), min(zs), max(zs)


def footprint(triangles, below=0.25):
    """Ground box of the geometry within the lowest quarter of the model's height."""
    x0, x1, y0, y1, z0, z1 = bounds(triangles)
    limit = z0 + (z1 - z0) * below
    low = [p for t in triangles for p in t[0] if p[2] <= limit]
    return (min(p[0] for p in low), max(p[0] for p in low), min(p[1] for p in low), max(p[1] for p in low))


def recolored(color, recolor):
    """`color` with its hue moved by the first matching (low, high, target,
    min_saturation[, saturation_scale, value_scale]) rule (degrees): green
    roofs made Stormwind blue, say, or a dark moss roof bright gold."""
    r, g, b = color
    hi, lo = max(r, g, b), min(r, g, b)
    if hi <= 0.0 or hi == lo:
        return color
    s = (hi - lo) / hi
    if hi == r:
        h = ((g - b) / (hi - lo)) % 6.0
    elif hi == g:
        h = (b - r) / (hi - lo) + 2.0
    else:
        h = (r - g) / (hi - lo) + 4.0
    h *= 60.0
    for rule in recolor:
        low, high, target, min_s = rule[:4]
        if low <= h < high and s >= min_s:
            if len(rule) > 4:
                s = min(1.0, s * rule[4])
                hi = min(1.0, hi * rule[5])
            h = (target % 360.0) / 60.0
            i = int(floor(h)) % 6
            f = h - floor(h)
            p, q, t = hi * (1.0 - s), hi * (1.0 - s * f), hi * (1.0 - s * (1.0 - f))
            return [(hi, q, p, p, t, hi)[i], (t, hi, hi, q, p, p)[i], (p, p, t, hi, hi, q)[i]]
    return color


def plan_mask(triangles):
    """The model's top-down silhouette: every triangle dropped to the ground,
    one sample per world unit. (left, bottom, width, height, rows) with rows a
    bytes object, row 0 at the north edge; left/bottom relative to the origin."""
    x0, x1, y0, y1, _, _ = bounds(triangles)
    left, bottom = int(floor(x0)) - 1, int(floor(y0)) - 1
    width, height = int(floor(x1)) - left + 2, int(floor(y1)) - bottom + 2
    mask = bytearray(width * height)
    top = bottom + height

    def mark(i, w0, w1, w2):
        mask[i] = 1
    for pts, normals, uvs, material in triangles:
        kart.rasterize([(p[0] - left, top - p[1]) for p in pts], width, height, mark)
    return left, bottom, width, height, bytes(mask)


def render(loaded, triangles, ss=SUPERSAMPLE, shadow=True, lean=LEAN, tint=(1.0, 1.0, 1.0), recolor=None,
           stone=None, alpha_shadow=False):
    """Sprite rows (top first, straight RGBA 0-255) plus the texel (ox, oy)
    where the model origin's ground point falls, counted from the top-left.

    `lean` is the screen rise per unit of height (the karts' camera: 0.75);
    city scenery uses less, so buildings beside a winding road keep clear of
    it. `tint` multiplies the lit color (a district's roof and stone hue);
    `recolor` moves texture hues (see recolored); `stone` = (gain, offset)
    brightens the lit greyish texels a recolor leaves alone, as gain * c +
    offset: a dark model's stone made pale, its detail kept, its recoloured
    roofs untouched. `alpha_shadow` casts the shadow only where the texture
    is drawn (a palm's leaf cards cut out, not their square planes). The
    result also carries
    `body`, the model's own coverage (0-255) per sprite texel without its
    shadow, and `plan`, its top-down silhouette (plan_mask)."""
    model, samplers, team = loaded
    x0, x1, y0, y1, z0, z1 = bounds(triangles)
    sx, sy = kart.SHADOW_VECTOR
    lo_x = min(x0, x0 + z1 * sx) - 2.0
    hi_x = max(x1, x1 + z1 * sx) + 2.0
    lo_y = min(y0 + z0 * lean, y0 + z1 * sy) - 2.0
    hi_y = y1 + z1 * lean + 2.0
    left, bottom = floor(lo_x), floor(lo_y)
    width, height = int(floor(hi_x)) - left + 1, int(floor(hi_y)) - bottom + 1
    canvas = Canvas(width, height, ss, left, bottom, width, height)
    columns, rows, step, top = canvas.columns, canvas.rows, canvas.step, canvas.top

    def to_samples(x, y):
        return (x - left) / step, (top - y) / step
    shade = bytearray(columns * rows)
    if shadow and alpha_shadow:
        for pts, normals, uvs, material in triangles:
            layers = model["materials"][material]

            def cut_mark(i, w0, w1, w2, uvs=uvs, layers=layers):
                u = w0 * uvs[0][0] + w1 * uvs[1][0] + w2 * uvs[2][0]
                v = w0 * uvs[0][1] + w1 * uvs[1][1] + w2 * uvs[2][1]
                if layer_color(model, samplers, team, layers, u, v) is not None:
                    shade[i] = 1
            kart.rasterize([to_samples(p[0] + p[2] * sx, p[1] + p[2] * sy) for p in pts], columns, rows, cut_mark)
    elif shadow:
        def mark(i, w0, w1, w2):
            shade[i] = 1
        for pts, normals, uvs, material in triangles:
            kart.rasterize([to_samples(p[0] + p[2] * sx, p[1] + p[2] * sy) for p in pts], columns, rows, mark)
    depth = [-1e30] * (columns * rows)
    red, green, blue, alpha = canvas.red, canvas.green, canvas.blue, canvas.alpha
    for pts, normals, uvs, material in triangles:
        layers = model["materials"][material]
        zs = [p[2] - p[1] * lean for p in pts]       # nearer the camera: higher and further south

        def fragment(i, w0, w1, w2):
            z = w0 * zs[0] + w1 * zs[1] + w2 * zs[2]
            if z <= depth[i]:
                return
            u = w0 * uvs[0][0] + w1 * uvs[1][0] + w2 * uvs[2][0]
            v = w0 * uvs[0][1] + w1 * uvs[1][1] + w2 * uvs[2][1]
            color = layer_color(model, samplers, team, layers, u, v)
            if color is None:
                return
            moved = False
            if recolor:
                before = color
                color = recolored(color, recolor)
                moved = color is not before
            nx = w0 * normals[0][0] + w1 * normals[1][0] + w2 * normals[2][0]
            ny = w0 * normals[0][1] + w1 * normals[1][1] + w2 * normals[2][1]
            nz = w0 * normals[0][2] + w1 * normals[1][2] + w2 * normals[2][2]
            length = sqrt(nx * nx + ny * ny + nz * nz) or 1.0
            k = (nx * kart.LX + ny * kart.LY + nz * kart.LZ) / length
            light = kart.AMBIENT + kart.DIFFUSE * (k if k > 0.0 else 0.0)
            depth[i] = z
            r = min(1.0, color[0] * light * tint[0])
            g = min(1.0, color[1] * light * tint[1])
            b = min(1.0, color[2] * light * tint[2])
            if stone and not moved:
                hi, lo = max(r, g, b), min(r, g, b)
                w = min(1.0, max(0.0, (0.55 - ((hi - lo) / hi if hi > 0.0 else 0.0)) / 0.25))
                gain, offset = stone
                r = r + w * (min(1.0, r * gain + offset) - r)
                g = g + w * (min(1.0, g * gain + offset) - g)
                b = b + w * (min(1.0, b * gain + offset) - b)
            red[i], green[i], blue[i] = r, g, b
            alpha[i] = 1.0
        kart.rasterize([to_samples(p[0], p[1] + p[2] * lean) for p in pts], columns, rows, fragment)
    body = canvas.resolve()
    cover = [[0] * width for _ in range(height)]
    for j in range(height):
        for i in range(width):
            count = 0
            for b in range(ss):
                base = (j * ss + b) * columns + i * ss
                for a in range(ss):
                    count += shade[base + a]
            cover[j][i] = count
    full = 16 * ss * ss
    pixels = []
    for j in range(height):
        row = []
        for i in range(width):
            total = 0
            for dj, wj in ((-1, 1), (0, 2), (1, 1)):
                for di, wi in ((-1, 1), (0, 2), (1, 1)):
                    y, x = j + dj, i + di
                    if 0 <= y < height and 0 <= x < width:
                        total += cover[y][x] * wj * wi
            r, g, b, a = body[j][i]
            va = a / 255.0
            sa = kart.SHADOW_ALPHA * total / full * (1.0 - va)
            out_a = va + sa
            if out_a <= 0.0:
                row.append([0, 0, 0, 0])
                continue
            rgb = [(body[j][i][k] / 255.0 * va + kart.SHADOW_COLOR[k] * sa) / out_a for k in range(3)]
            row.append([int(rgb[0] * 255.0 + 0.5), int(rgb[1] * 255.0 + 0.5), int(rgb[2] * 255.0 + 0.5),
                        int(out_a * 255.0 + 0.5)])
        pixels.append(row)
    # (ox, oy): the model origin in texel-edge units from the top-left corner.
    return {"pixels": pixels, "width": width, "height": height, "ox": -left, "oy": bottom + height,
            "bounds": (x0, x1, y0, y1, z0, z1), "footprint": footprint(triangles),
            "body": [[px[3] for px in row] for row in body], "plan": plan_mask(triangles)}
