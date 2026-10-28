"""Survey a World of Warcraft battleground for a Battlegrounds Cup course.

python scripts/wow_map_survey.py MAPDIR LISTFILE OUT.json [--map pvpzone03] [--origin 15430 16182]

MAPDIR holds the map's files as the owner's client stores them, extracted
read-only by scripts/wowcasc.py (MAPDIR/world/maps/<map>/: the WDT and each
tile's root, _obj0 and _tex0 ADT). LISTFILE is the community listfile
("FileDataID;path" lines) that names the ground textures and the models
placed. Nothing is read from anywhere else and no client file is copied:
the output is numbers about the map.

The course's world is the battleground's ground at three units to the yard:
a point at (px, pz) in the ADTs' placement space (yards; px east, pz south)
stands at X = (px - ox) * 3, Y = (oz - pz) * 3 (--origin ox oz). OUT.json
holds, over the world in GRID-unit texels (row 0 north):

- "ground": per texel, the blend weight (0-15) of each ground texture of the
  map (each tile's _tex0 layers, their alpha maps composed in order as the
  client composes them), one plane per texture, zlib then base64;
- "relief": per texel, the terrain's height (the root ADTs' MCVT vertices,
  interpolated over each cell's four triangles) in RELIEF_STEP-yard steps
  above RELIEF_BASE, 255 where the terrain has a hole or none; zlib, base64;
- "placements": every doodad (MDDF) and building (MODF) inside the world
  (with a margin): its model file's name, X, Y, height (yards), yaw (degrees
  counter-clockwise from east: the placement's turn less 90, as the props'
  yaw) and scale.

Standard library only.
"""
import argparse
import base64
import json
import os
import struct
import zlib
from pathlib import Path

TILE = 1600.0 / 3.0                 # yards per ADT tile
CHUNK = TILE / 16                   # per map chunk (16 x 16 a tile)
UNIT = CHUNK / 8                    # per terrain cell (8 x 8 a chunk)
SCALE = 3                           # world units per yard
WIDTH, HEIGHT, GRID = 1024, 2048, 4
RELIEF_BASE, RELIEF_STEP = 290.0, 0.6
MARGIN = 120                        # placements kept this far outside the world


def chunks(data, start=0, end=None):
    """(tag, offset, size) of each chunk; tags read as stored, reversed."""
    end = len(data) if end is None else end
    p = start
    while p + 8 <= end:
        tag = data[p:p + 4][::-1].decode("latin-1")
        size = struct.unpack_from("<I", data, p + 4)[0]
        yield tag, p + 8, size
        p += 8 + size


def tiles(mapdir, name):
    folder = Path(mapdir) / "world" / "maps" / name
    for path in sorted(folder.glob(name + "_??_??.adt")):
        tx, ty = (int(v) for v in path.stem[len(name) + 1:].split("_"))
        yield tx, ty, path


def mphd_flags(mapdir, name):
    data = (Path(mapdir) / "world" / "maps" / name / (name + ".wdt")).read_bytes()
    for tag, off, size in chunks(data):
        if tag == "MPHD":
            return struct.unpack_from("<I", data, off)[0]
    return 0


# ---------------------------------------------------------------------------
# The terrain: each chunk's heights and holes (root ADT).


def terrain(mapdir, name):
    """{(chunk column, chunk row): (flags, holes 8x8 bits, 9x9 outer, 8x8 inner heights)},
    columns along px, rows along pz, over the whole map."""
    out = {}
    for tx, ty, path in tiles(mapdir, name):
        data = path.read_bytes()
        for tag, off, size in chunks(data):
            if tag != "MCNK":
                continue
            flags, ix, iy = struct.unpack_from("<III", data, off)
            if flags & 0x10000:                       # high-resolution holes: 8 x 8 bits
                holes = struct.unpack_from("<Q", data, off + 0x14)[0]
            else:                                     # 4 x 4 bits, each a 2 x 2 block
                low = struct.unpack_from("<H", data, off + 0x3C)[0]
                holes = 0
                for b in range(16):
                    if low & (1 << b):
                        r, c = divmod(b, 4)
                        for rr in (2 * r, 2 * r + 1):
                            for cc in (2 * c, 2 * c + 1):
                                holes |= 1 << (rr * 8 + cc)
            base = struct.unpack_from("<3f", data, off + 0x68)[2]
            heights = None
            for t2, o2, s2 in chunks(data, off + 128, off + size):
                if t2 == "MCVT":
                    heights = struct.unpack_from("<145f", data, o2)
            if heights is None:
                continue
            outer, inner, k = [], [], 0
            for r in range(17):
                if r % 2 == 0:
                    outer.append([base + h for h in heights[k:k + 9]])
                    k += 9
                else:
                    inner.append([base + h for h in heights[k:k + 8]])
                    k += 8
            out[(tx * 16 + ix, ty * 16 + iy)] = (flags, holes, outer, inner)
    return out


def height_at(land, px, pz):
    """The terrain's height at (px, pz), or None (a hole, or no terrain)."""
    ci, cj = int(px // CHUNK), int(pz // CHUNK)
    found = land.get((ci, cj))
    if found is None:
        return None
    flags, holes, outer, inner = found
    u, v = (px - ci * CHUNK) / UNIT, (pz - cj * CHUNK) / UNIT
    c, r = min(7, int(u)), min(7, int(v))
    if holes >> (r * 8 + c) & 1:
        return None
    fu, fv = u - c, v - r
    a, b = outer[r][c], outer[r][c + 1]
    cc, d = outer[r + 1][c], outer[r + 1][c + 1]
    m = inner[r][c]
    # The cell's four triangles meet at its centre vertex.
    if fv <= fu and fv <= 1 - fu:                    # north
        p0, p1, q = (a, 0, 0), (b, 1, 0), (fu, fv)
    elif fv >= fu and fv >= 1 - fu:                  # south
        p0, p1, q = (cc, 0, 1), (d, 1, 1), (fu, fv)
    elif fu < fv:                                    # west
        p0, p1, q = (a, 0, 0), (cc, 0, 1), (fu, fv)
    else:                                            # east
        p0, p1, q = (b, 1, 0), (d, 1, 1), (fu, fv)
    (h0, x0, y0), (h1, x1, y1), (x, y) = p0, p1, q
    x2, y2, h2 = 0.5, 0.5, m
    det = (y1 - y2) * (x0 - x2) + (x2 - x1) * (y0 - y2)
    l0 = ((y1 - y2) * (x - x2) + (x2 - x1) * (y - y2)) / det
    l1 = ((y2 - y0) * (x - x2) + (x0 - x2) * (y - y2)) / det
    return l0 * h0 + l1 * h1 + (1 - l0 - l1) * h2


# ---------------------------------------------------------------------------
# The ground's textures: each chunk's layers and alpha maps (_tex0 ADT).


def alpha_map(mcal, offset, flags, big, fix):
    """A layer's 64 x 64 alpha (0-255), rows along pz."""
    if flags & 0x200:                                # compressed (8-bit, run-length)
        out, p = [], offset
        while len(out) < 4096:
            control = mcal[p]
            p += 1
            count = control & 0x7F
            if control & 0x80:
                out += [mcal[p]] * count
                p += 1
            else:
                out += list(mcal[p:p + count])
                p += count
        values = out[:4096]
    elif big:                                        # 8-bit, 4096 bytes
        values = list(mcal[offset:offset + 4096])
    else:                                            # 4-bit, 2048 bytes, low nibble first
        values = []
        for byte in mcal[offset:offset + 2048]:
            values += [(byte & 15) * 17, (byte >> 4) * 17]
    rows = [values[r * 64:(r + 1) * 64] for r in range(64)]
    if fix:                                          # the 64th row and column repeat the 63rd
        for row in rows:
            row[63] = row[62]
        rows[63] = list(rows[62])
    return rows


def ground(mapdir, name, land, names):
    """({(chunk column, chunk row): {texture: 64 x 64 weights 0-1}}, texture names)."""
    big = bool(mphd_flags(mapdir, name) & 0x84)
    out, textures = {}, set()
    for tx, ty, path in tiles(mapdir, name):
        tex = path.with_name(path.stem + "_tex0.adt")
        if not tex.is_file():
            continue
        data = tex.read_bytes()
        ids, k = [], 0
        for tag, off, size in chunks(data):
            if tag == "MDID":
                ids = list(struct.unpack_from("<%dI" % (size // 4), data, off))
            if tag != "MCNK":
                continue
            iy, ix = divmod(k, 16)
            k += 1
            layers, mcal = [], b""
            for t2, o2, s2 in chunks(data, off, off + size):
                if t2 == "MCLY":
                    layers = [struct.unpack_from("<IIIi", data, o2 + 16 * j) for j in range(s2 // 16)]
                elif t2 == "MCAL":
                    mcal = data[o2:o2 + s2]
            if not layers:
                continue
            key = (tx * 16 + ix, ty * 16 + iy)
            fix = not (land.get(key, (0,))[0] & 0x8000)
            weights = {}
            for index, (tid, flags, offset, _) in enumerate(layers):
                texture = names.get(ids[tid], str(ids[tid])).rsplit("/", 1)[-1].rsplit(".", 1)[0]
                textures.add(texture)
                if index == 0:
                    weights = {texture: [[1.0] * 64 for _ in range(64)]}
                    continue
                a = alpha_map(mcal, offset, flags, big, fix)
                for plane in weights.values():
                    for r in range(64):
                        row, ar = plane[r], a[r]
                        for c in range(64):
                            row[c] *= 1 - ar[c] / 255
                plane = weights.setdefault(texture, [[0.0] * 64 for _ in range(64)])
                for r in range(64):
                    for c in range(64):
                        plane[r][c] += a[r][c] / 255
            out[key] = weights
    return out, sorted(textures)


# ---------------------------------------------------------------------------
# Placements (_obj0 ADT).


def placements(mapdir, name, names, ox, oz):
    out, seen = [], set()
    for tx, ty, path in tiles(mapdir, name):
        obj = path.with_name(path.stem + "_obj0.adt")
        if not obj.is_file():
            continue
        data = obj.read_bytes()
        for tag, off, size in chunks(data):
            if tag == "MDDF":
                for k in range(size // 36):
                    fid, uid, px, py, pz, rx, ry, rz, scale, flags = struct.unpack_from("<II3f3fHH", data, off + 36 * k)
                    if ("m", uid) not in seen:
                        seen.add(("m", uid))
                        out.append(("doodad", fid, px, py, pz, ry, scale / 1024))
            elif tag == "MODF":
                for k in range(size // 64):
                    fid, uid, px, py, pz, rx, ry, rz = struct.unpack_from("<II3f3f", data, off + 64 * k)
                    if ("w", uid) not in seen:
                        seen.add(("w", uid))
                        out.append(("building", fid, px, py, pz, ry, 1.0))
    rows = []
    for kind, fid, px, py, pz, ry, scale in out:
        x, y = (px - ox) * SCALE, (oz - pz) * SCALE
        if -MARGIN <= x <= WIDTH + MARGIN and -MARGIN <= y <= HEIGHT + MARGIN:
            model = names.get(fid, str(fid)).rsplit("/", 1)[-1].rsplit(".", 1)[0]
            rows.append([kind, model, round(x, 1), round(y, 1), round(py, 1), round((ry - 90) % 360, 1),
                         round(scale, 3)])
    rows.sort(key=lambda r: (r[0], r[1], r[2], r[3]))
    return rows


# ---------------------------------------------------------------------------
# The world's texels.


def pack(values):
    return base64.b64encode(zlib.compress(bytes(values), 9)).decode("ascii")


def survey(mapdir, listfile, name, ox, oz):
    names = {}
    for line in open(listfile, encoding="utf-8", errors="replace"):
        fid, _, path = line.rstrip("\r\n").partition(";")
        if fid.isdigit():
            names[int(fid)] = path
    land = terrain(mapdir, name)
    blend, textures = ground(mapdir, name, land, names)
    cols, rows = WIDTH // GRID, HEIGHT // GRID
    relief = bytearray(cols * rows)
    planes = {t: bytearray(cols * rows) for t in textures}
    for row in range(rows):
        y = HEIGHT - (row + 0.5) * GRID
        pz = oz - y / SCALE
        for col in range(cols):
            x = (col + 0.5) * GRID
            px = ox + x / SCALE
            i = row * cols + col
            h = height_at(land, px, pz)
            relief[i] = 255 if h is None else max(0, min(254, int(round((h - RELIEF_BASE) / RELIEF_STEP))))
            ci, cj = int(px // CHUNK), int(pz // CHUNK)
            weights = blend.get((ci, cj))
            if weights is None:
                continue
            c = min(63, int((px - ci * CHUNK) / CHUNK * 64))
            r = min(63, int((pz - cj * CHUNK) / CHUNK * 64))
            for texture, plane in weights.items():
                planes[texture][i] = max(0, min(15, int(round(plane[r][c] * 15))))
    return {
        "map": name, "origin": [ox, oz], "scale": SCALE, "grid": GRID, "columns": cols, "rows": rows,
        "relief": {"base": RELIEF_BASE, "step": RELIEF_STEP, "texels": pack(relief)},
        "ground": {t: pack(planes[t]) for t in textures},
        "placements": placements(mapdir, name, names, ox, oz),
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("mapdir")
    parser.add_argument("listfile")
    parser.add_argument("out", type=Path)
    parser.add_argument("--map", default="pvpzone03")
    parser.add_argument("--origin", type=float, nargs=2, default=(15430.0, 16182.0))
    args = parser.parse_args()
    data = survey(args.mapdir, args.listfile, args.map, *args.origin)
    text = json.dumps(data, indent=0, separators=(",", ":")) + "\n"
    args.out.write_text(text, encoding="utf-8", newline="\n")
    print("WROTE: %s; %d placements; ground %s; %d bytes" % (args.out, len(data["placements"]),
                                                            ",".join(sorted(data["ground"])), len(text)))


if __name__ == "__main__":
    main()
