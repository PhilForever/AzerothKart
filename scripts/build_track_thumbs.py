"""Build the track list's thumbnail atlas from the tracks' own previews.

python scripts/build_track_thumbs.py           # write Assets/UI/TrackThumbs.tga
python scripts/build_track_thumbs.py --check   # verify its exact bytes, write nothing
python scripts/build_track_thumbs.py --preview OUT.png   # also a PNG to review

Each track in Menu.TRACKS gets one 64 x 64 cell, in that order, eight to a
row (TrackThumbs.tga is 512 x 512: room for 64 tracks): the middle square of
the picture its details card shows (Menu.PREVIEW_CELLS: its own Preview.tga,
or its cell of TrackPreviews.tga), averaged down in whole blocks (8 x 8
texels for a 512-texel square, 4 x 4 for 256) over premultiplied alpha, in
integer arithmetic: every machine writes the same bytes. No new art: the
pixels are the previews'. Reads Menu.lua's tables through pinned Lupa (the
module only defines them at load) and the previews' TGAs (Type 2, BGRA32,
bottom-left origin, as every preview is written); standard library otherwise.
"""
import argparse
import hashlib
import importlib
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "addon" / "AzerothKart"
OUTPUT = ADDON / "Assets" / "UI" / "TrackThumbs.tga"
CELL, COLUMNS, ROWS = 64, 8, 8
PREFIX = "Interface\\AddOns\\AzerothKart\\"

sys.path.insert(0, str(ROOT / "scripts"))
from build_kart_icons import read_tga  # noqa: E402  (the same TGA reader)


def tracks():
    """[(id, path, left, right, top, bottom)] in Menu.TRACKS order."""
    lua = importlib.import_module("lupa.lua51").LuaRuntime(unpack_returned_tuples=True)
    namespace = lua.eval("{Presentation = {}, Physics = {}, Courses = {}}")
    source = (ADDON / "Menu.lua").read_text(encoding="utf-8")
    lua.execute("local chunk, ns = ...; assert(loadstring(chunk))('AzerothKart', ns)", source, namespace)
    menu = namespace.Menu
    out = []
    for i in range(1, len(menu.TRACKS) + 1):
        track = menu.TRACKS[i]
        cell = menu.PREVIEW_CELLS[track.cell]
        out.append((track.id, cell.path or menu.PREVIEW_PATH, cell.left, cell.right, cell.top, cell.bottom))
    return out


def thumb(sheet, left, right, top, bottom):
    """The middle square of a preview cell, averaged down to CELL x CELL, as
    top-down [r, g, b, a] rows."""
    width, height, data = sheet
    x0, x1 = round(left * width), round(right * width)
    y0, y1 = round(top * height), round(bottom * height)        # from the top
    side = min(x1 - x0, y1 - y0)
    assert side % CELL == 0, f"a {side}-texel square does not average to {CELL}"
    x0 += (x1 - x0 - side) // 2
    y0 += (y1 - y0 - side) // 2
    block = side // CELL
    rows = []
    for ty in range(CELL):
        line = []
        for tx in range(CELL):
            r = g = b = a = 0
            for y in range(y0 + ty * block, y0 + (ty + 1) * block):
                offset = 18 + ((height - 1 - y) * width + x0 + tx * block) * 4
                for x in range(block):
                    pb, pg, pr, pa = data[offset + 4 * x:offset + 4 * x + 4]
                    r += pr * pa
                    g += pg * pa
                    b += pb * pa
                    a += pa
            n = block * block
            if a == 0:
                line.append([0, 0, 0, 0])
            else:
                line.append([(r + a // 2) // a, (g + a // 2) // a, (b + a // 2) // a, (a + n // 2) // n])
        rows.append(line)
    return rows


def atlas():
    pixels = [[[0, 0, 0, 0] for _ in range(COLUMNS * CELL)] for _ in range(ROWS * CELL)]
    listed = tracks()
    assert len(listed) <= COLUMNS * ROWS, "more tracks than the atlas holds"
    sheets = {}
    for index, (tid, path, left, right, top, bottom) in enumerate(listed):
        assert path.startswith(PREFIX), f"{tid}: {path}"
        file = ADDON / path[len(PREFIX):].replace("\\", "/")
        if file not in sheets:
            sheets[file] = read_tga(file)
        cell = thumb(sheets[file], left, right, top, bottom)
        cx, cy = (index % COLUMNS) * CELL, (index // COLUMNS) * CELL
        for y in range(CELL):
            pixels[cy + y][cx:cx + CELL] = cell[y]
    return pixels, listed


def main():
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
    print(f"{len(listed)} tracks; {len(data)} bytes; sha256={hashlib.sha256(data).hexdigest()}")
    if args.preview:
        Path(args.preview).write_bytes(encode_png(pixels))
        print(f"preview: {args.preview}")


if __name__ == "__main__":
    main()
