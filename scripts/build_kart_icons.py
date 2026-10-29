"""Build the kart screen's icon atlas from the karts' own sprite sheets.

python scripts/build_kart_icons.py           # write Assets/UI/KartIcons.tga
python scripts/build_kart_icons.py --check   # verify its exact bytes, write nothing
python scripts/build_kart_icons.py --preview OUT.png   # also a PNG to review

Each kart in Presentation.KART_ORDER gets one 128 x 128 cell, in that order,
eight to a row (KartIcons.tga is 1024 x 512: room for 32 karts): its own
sheet's frame for a heading of 315 degrees (facing the viewer's lower right,
the garage turntable's starting pose), rest pose, moved so the kart and its
shadow sit in the middle of the cell and, when their extent is far from
FILL texels across (a winged kart's frame leaves room for its wings), scaled
to it (bilinear, premultiplied alpha, in plain arithmetic: every machine
agrees). No new art: the pixels are the sheet's. Reads the sheets' TGAs (Type 2, BGRA32,
bottom-left origin, as every kart sheet is written) and Presentation.lua
through pinned Lupa; standard library otherwise.
"""
import argparse
import hashlib
import importlib
import math
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "addon" / "AzerothKart"
OUTPUT = ADDON / "Assets" / "UI" / "KartIcons.tga"
CELL, COLUMNS, ROWS = 128, 8, 4
HEADING = math.radians(315)
ALPHA = 32          # a texel counts toward the kart's extent from this alpha
FILL = 104          # the extent's longer side, in texels, when it is scaled


def karts():
    """(id, sheet entry) in KART_ORDER, read from Presentation.lua itself."""
    lua = importlib.import_module("lupa.lua51").LuaRuntime(unpack_returned_tuples=True)
    namespace = lua.table()
    source = (ADDON / "Presentation.lua").read_text(encoding="utf-8")
    presentation = lua.execute("local chunk = ...; return assert(loadstring(chunk))('AzerothKart', ...)",
                               source, namespace)
    if presentation is None:
        presentation = namespace.Presentation
    order = presentation.KART_ORDER
    out = []
    for i in range(1, len(order) + 1):
        kid = order[i]
        entry = presentation.KART_SPRITES[kid]
        out.append((kid, {key: entry[key] for key in ("name", "path", "textureWidth", "textureHeight",
                                                      "frames", "columns")}))
    return out


def read_tga(path):
    data = path.read_bytes()
    fields = struct.unpack("<BBBHHBHHHHBB", data[:18])
    kind, width, height, depth, descriptor = fields[2], fields[8], fields[9], fields[10], fields[11]
    assert kind == 2 and depth == 32 and not (descriptor & 0x20), f"{path.name}: not a bottom-left BGRA32 TGA"
    return width, height, data


def frame_cell(sheet, entry):
    """The frame's 128 x 128 texels as top-down [r, g, b, a] rows."""
    width, height, data = sheet
    frames, columns = int(entry["frames"]), int(entry["columns"])
    frame = int(math.floor((HEADING % (2 * math.pi)) / (2 * math.pi) * frames + 0.5)) % frames
    size = width // columns
    assert size == CELL, f"{entry['name']}: {size}-texel frames, not {CELL}"
    x0, y0 = (frame % columns) * size, (frame // columns) * size      # y0 from the top
    rows = []
    for y in range(y0, y0 + size):
        offset = 18 + ((height - 1 - y) * width + x0) * 4
        line = []
        for x in range(size):
            b, g, r, a = data[offset + 4 * x:offset + 4 * x + 4]
            line.append([r, g, b, a])
        rows.append(line)
    return rows


def scaled(rows, factor):
    """The cell scaled by `factor` about its middle: bilinear over
    premultiplied alpha, transparent beyond its edge."""
    size = len(rows)

    def fetch(x, y):
        if 0 <= x < size and 0 <= y < size:
            r, g, b, a = rows[y][x]
            return r * a, g * a, b * a, a
        return 0, 0, 0, 0
    out = []
    centre = (size - 1) / 2.0
    for y in range(size):
        line = []
        sy = (y - centre) / factor + centre
        y0 = math.floor(sy)
        fy = sy - y0
        for x in range(size):
            sx = (x - centre) / factor + centre
            x0 = math.floor(sx)
            fx = sx - x0
            acc = [0.0, 0.0, 0.0, 0.0]
            for (px, py, w) in ((x0, y0, (1 - fx) * (1 - fy)), (x0 + 1, y0, fx * (1 - fy)),
                                (x0, y0 + 1, (1 - fx) * fy), (x0 + 1, y0 + 1, fx * fy)):
                if w:
                    v = fetch(px, py)
                    for k in range(4):
                        acc[k] += v[k] * w
            a = acc[3]
            if a < 0.5:
                line.append([0, 0, 0, 0])
            else:
                line.append([min(255, int(acc[0] / a + 0.5)), min(255, int(acc[1] / a + 0.5)),
                             min(255, int(acc[2] / a + 0.5)), min(255, int(a + 0.5))])
        out.append(line)
    return out


def extent(rows):
    xs = [x for row in rows for x, p in enumerate(row) if p[3] >= ALPHA]
    ys = [y for y, row in enumerate(rows) for p in row if p[3] >= ALPHA]
    return (min(xs), min(ys), max(xs), max(ys)) if xs else None


def centred(rows):
    """The cell moved so the extent of its texels (alpha ALPHA and over)
    sits in the middle; first scaled to FILL when that extent is more than a
    tenth off it."""
    box = extent(rows)
    if box is None:
        return rows
    dx = (CELL - 1 - box[2] - box[0]) // 2
    dy = (CELL - 1 - box[3] - box[1]) // 2
    out = [[[0, 0, 0, 0] for _ in range(CELL)] for _ in range(CELL)]
    for y, row in enumerate(rows):
        for x, p in enumerate(row):
            tx, ty = x + dx, y + dy
            if 0 <= tx < CELL and 0 <= ty < CELL:
                out[ty][tx] = p
    longest = max(box[2] - box[0], box[3] - box[1]) + 1
    factor = FILL / longest
    if abs(factor - 1) > 0.1:
        out = scaled(out, min(factor, 1.6))
    return out


def atlas():
    pixels = [[[0, 0, 0, 0] for _ in range(COLUMNS * CELL)] for _ in range(ROWS * CELL)]
    listed = karts()
    assert len(listed) <= COLUMNS * ROWS, "more karts than the atlas holds"
    sheets = {}
    for index, (kid, entry) in enumerate(listed):
        file = ADDON / entry["path"].replace("Interface\\AddOns\\AzerothKart\\", "").replace("\\", "/")
        if file not in sheets:
            sheets[file] = read_tga(file)
        cell = centred(frame_cell(sheets[file], entry))
        cx, cy = (index % COLUMNS) * CELL, (index // COLUMNS) * CELL
        for y in range(CELL):
            pixels[cy + y][cx:cx + CELL] = cell[y]
    return pixels, listed


def main():
    sys.path.insert(0, str(ROOT / "scripts"))
    from paintkit import encode_png, encode_tga
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--preview")
    args = parser.parse_args()
    pixels, listed = atlas()
    data = encode_tga(pixels)
    relative = OUTPUT.relative_to(ROOT).as_posix()
    if args.check:
        if not OUTPUT.is_file() or OUTPUT.read_bytes() != data:
            raise SystemExit(f"STALE: {relative}; run without --check")
        print(f"CHECK PASS: {relative}")
    else:
        OUTPUT.write_bytes(data)
        print(f"WROTE: {relative}")
    print(f"{len(listed)} karts; {len(data)} bytes; sha256={hashlib.sha256(data).hexdigest()}")
    if args.preview:
        Path(args.preview).write_bytes(encode_png(pixels))
        print(f"preview: {args.preview}")


if __name__ == "__main__":
    main()
