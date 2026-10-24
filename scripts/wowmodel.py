"""World of Warcraft M2 models (MD21, version 264 and later) and BLP2 textures,
read for build_wc3_kart.py's renderer.

load(root, m2_path, skin_path, textures) -> (model, samplers, triangles)
effect_units(root, m2_path, skin_path) -> [(fdid, blending mode, corners)]

`root` is a folder of files extracted from the client (scripts/wowcasc.py),
`textures` maps the model's texture FileDataIDs (its TXID chunk) to files
under it. The triangles come from the skin's sections and texture units as
the game draws them, in the model's bind pose (vehicles and props are
modelled standing), each tagged with a material whose one layer reads its
texture: opaque, alpha-tested or blended. Additive and other effect units
(flames, glows) are left out, as build_wc3_kart.py leaves out a Warcraft
III model's effect layers; effect_units() lists them, so a kart can place
its own effects where the model's are. Coordinates are the model's: z up,
+x left of a model facing -y.

Standard library only; DXT blocks are decoded by wc3render's exact integer
block decoders.
"""
import struct
from math import sqrt


def _array(data, offset):
    """(count, offset) of an M2Array at `offset`."""
    return struct.unpack_from("<II", data, offset)


def chunks(data):
    out, p = {}, 0
    while p + 8 <= len(data):
        tag, size = data[p:p + 4], struct.unpack_from("<I", data, p + 4)[0]
        out[tag] = data[p + 8:p + 8 + size]
        p += 8 + size
    return out


def read_blp2(data, mip=0):
    """(width, height, texels) of one mip level of a BLP2 texture: texels as
    (r, g, b, a) floats, top row first. DXT1/3/5 and paletted encodings."""
    import wc3render as R
    assert data[:4] == b"BLP2", "not a BLP2 texture"
    _kind, encoding, alpha_depth, alpha_encoding, _mips, width, height = struct.unpack_from("<IBBBBII", data, 4)
    offsets = struct.unpack_from("<16I", data, 0x14)
    sizes = struct.unpack_from("<16I", data, 0x54)
    width, height = max(1, width >> mip), max(1, height >> mip)
    offset, size = offsets[mip], sizes[mip]
    texels = [None] * (width * height)
    if encoding == 2:
        kind = {0: "DXT1", 1: "DXT3", 7: "DXT5"}[alpha_encoding]
        step = 8 if kind == "DXT1" else 16
        p = offset
        for by in range(0, height, 4):
            for bx in range(0, width, 4):
                if kind == "DXT1":
                    colors, alphas = R._color_block(data, p, alpha_depth > 0), None
                elif kind == "DXT3":
                    raw = int.from_bytes(data[p:p + 8], "little")
                    alphas = [((raw >> (4 * i)) & 15) * 17 for i in range(16)]
                    colors = R._color_block(data, p + 8, False)
                else:
                    alphas = R._alpha_block(data, p)
                    colors = R._color_block(data, p + 8, False)
                p += step
                for i in range(16):
                    x, y = bx + (i & 3), by + (i >> 2)
                    if x < width and y < height:
                        r, g, b, a = colors[i]
                        if alphas is not None:
                            a = alphas[i]
                        elif alpha_depth == 0:
                            a = 255
                        texels[y * width + x] = (r / 255.0, g / 255.0, b / 255.0, a / 255.0)
    elif encoding == 1:
        palette = [struct.unpack_from("<4B", data, 0x94 + 4 * i) for i in range(256)]   # B, G, R, A
        index = data[offset:offset + width * height]
        alpha = data[offset + width * height:offset + size]
        for i in range(width * height):
            b, g, r, _ = palette[index[i]]
            if alpha_depth == 8:
                a = alpha[i]
            elif alpha_depth == 1:
                a = 255 if alpha[i >> 3] >> (i & 7) & 1 else 0
            elif alpha_depth == 4:
                a = ((alpha[i >> 1] >> (4 * (i & 1))) & 15) * 17
            else:
                a = 255
            texels[i] = (r / 255.0, g / 255.0, b / 255.0, a / 255.0)
    else:
        raise ValueError("unsupported BLP2 encoding %d" % encoding)
    return width, height, texels


# Blending modes the kart renderer composites (M2Material.blending_mode ->
# its layer filter): opaque, alpha key, alpha blend. Others are effects.
FILTERS = {0: 0, 1: 1, 2: 2}


def _units(root, m2_path, skin_path):
    """Every texture unit of the skin: (blending mode, texture FileDataID or
    None for a replaceable texture, triangles as ((p, n, uv) x 3))."""
    c = chunks((root / m2_path).read_bytes())
    md = c[b"MD21"]
    assert md[:4] == b"MD20", "not an M2 model"
    txid = struct.unpack("<%dI" % (len(c.get(b"TXID", b"")) // 4), c.get(b"TXID", b""))
    n_vert, o_vert = _array(md, 0x3C)
    n_tex, o_tex = _array(md, 0x50)
    n_mat, o_mat = _array(md, 0x70)
    n_combo, o_combo = _array(md, 0x80)
    vertices = []
    for k in range(n_vert):
        p = o_vert + 48 * k
        x, y, z = struct.unpack_from("<3f", md, p)
        nx, ny, nz = struct.unpack_from("<3f", md, p + 20)
        u, v = struct.unpack_from("<2f", md, p + 32)
        vertices.append(((x, y, z), (nx, ny, nz), (u, v)))
    tex_types = [struct.unpack_from("<II", md, o_tex + 16 * k) for k in range(n_tex)]
    materials = [struct.unpack_from("<HH", md, o_mat + 4 * k) for k in range(n_mat)]
    combos = struct.unpack_from("<%dH" % n_combo, md, o_combo)
    skin = (root / skin_path).read_bytes()
    assert skin[:4] == b"SKIN", "not a skin profile"
    n_sv, o_sv = _array(skin, 4)
    n_si, o_si = _array(skin, 12)
    n_sec, o_sec = _array(skin, 28)
    n_batch, o_batch = _array(skin, 36)
    lookup = struct.unpack_from("<%dH" % n_sv, skin, o_sv)
    indices = struct.unpack_from("<%dH" % n_si, skin, o_si)
    sections = []
    for k in range(n_sec):
        p = o_sec + 48 * k
        _sid, level, _vstart, _vcount, istart, icount = struct.unpack_from("<6H", skin, p)
        sections.append((istart + 65536 * level, icount))
    units = []
    for k in range(n_batch):
        p = o_batch + 24 * k
        _flags, _priority, _shader, section, _geoset, _color, material, _layer, count, combo = \
            struct.unpack_from("<BbHHHhHHHH", skin, p)
        if count < 1:
            continue
        texture = combos[combo]
        fdid = txid[texture] if tex_types[texture][0] == 0 and texture < len(txid) else None
        start, icount = sections[section]
        triangles = [tuple(vertices[lookup[indices[t + j]]] for j in range(3)) for t in range(start, start + icount, 3)]
        units.append((materials[material][1], fdid, triangles))
    return units


def load(root, m2_path, skin_path, textures, mip=1):
    import build_wc3_kart as kart
    model = {"textures": [], "materials": [], "texture_files": []}
    samplers, by_file = {}, {}
    triangles = []
    for mode, fdid, corners_list in _units(root, m2_path, skin_path):
        if mode not in FILTERS or fdid not in textures:
            continue                                     # effects; replaceable or unshipped textures: not drawn
        name = textures[fdid]
        if name not in by_file:
            by_file[name] = len(model["textures"])
            model["textures"].append({"file": name, "replaceable": 0, "flags": 3})
            model["texture_files"].append(name)
            samplers[by_file[name]] = kart.sampler(read_blp2((root / name).read_bytes(), mip), True, True)
        model["materials"].append([{"texture": by_file[name], "filter": FILTERS[mode]}])
        tag = len(model["materials"]) - 1
        for corners in corners_list:
            normals = []
            for _, n, _ in corners:
                length = sqrt(n[0] * n[0] + n[1] * n[1] + n[2] * n[2]) or 1.0
                normals.append((n[0] / length, n[1] / length, n[2] / length))
            triangles.append((tuple(p for p, _, _ in corners), tuple(normals), tuple(uv for _, _, uv in corners), tag))
    return model, samplers, triangles


def effect_units(root, m2_path, skin_path):
    """The units load() leaves out (additive glows, flames): (texture
    FileDataID, blending mode, corner positions)."""
    return [(fdid, mode, [p for corners in tris for p, _, _ in corners])
            for mode, fdid, tris in _units(root, m2_path, skin_path) if mode not in FILTERS]
