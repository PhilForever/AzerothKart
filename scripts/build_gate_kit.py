"""Build the gates' kit: GateKit.tga, the posts and lines that mark each gate.

python scripts/build_gate_kit.py --wc3 WC3           # write Assets/UI/GateKit.tga
python scripts/build_gate_kit.py --wc3 WC3 --check   # verify its exact bytes and Presentation.GATE_KIT
python scripts/build_gate_kit.py --wc3 WC3 --preview OUT.png   # also a PNG to review

WC3 is the folder of the owner's Warcraft III: Reforged files extracted by
scripts/wc3casc.py (the city tracks' --wc3). GateKit.tga is 512 x 512 BGRA32:

- six posts, one per kit, each in a 128 x 128 cell (four a row): a standing
  model from Warcraft III drawn with the scenery's own renderer (wc3render:
  the karts' camera, height leaning north at 0.6, a shadow to the south-east,
  one texel a world unit), so a post stands in the track's picture like its
  scenery: `alliance` (the Alliance's banner, blue), `horde` (the Horde's,
  red), `scarlet` (the Scarlet Crusade's standing banners), `goblin` (the
  goblin racing arrow post), `brazier` (a Lordaeron brazier) and `dwarven`
  (a carved stone obelisk banded in bronze, Reforged's Northrend obelisk:
  Dun Baldar's dwarves on Alterac Valley);
- `pool`, a soft round glow (white; the game tints it) at (0, 384), 128 x 128;
- `lineH` and `lineV`, a soft line across 16 texels (bright middle, faded
  edges) 256 long, horizontal at (128, 384) and vertical at (384, 256);
- `checkH` and `checkV`, a checkered band two squares of 8 texels across and
  32 along, at (128, 400) and (400, 256).

Each post's entry in Presentation.GATE_KIT gives its rectangle in the atlas,
the texel of the model's foot (`ox`, `oy` from the rectangle's top-left) and
its height in world units (`zmax`). --check compares that table with these
numbers as well as the picture's bytes. The posts' pixels are Blizzard
Entertainment's Warcraft III art (ADR 0009); the glow, lines and checks are
drawn here from polynomials alone, so every machine writes the same bytes.
"""
import argparse
import hashlib
import importlib
import sys
from math import sqrt
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "addon" / "AzerothKart"
OUTPUT = ADDON / "Assets" / "UI" / "GateKit.tga"
SIZE, CELL = 512, 128
LEAN = 0.6

sys.path.insert(0, str(ROOT / "scripts"))

# The kits: archive path, scale (world units per model unit), team colour.
KITS = [
    ("alliance", "war3.w3mod:doodads/lordaeronsummer/props/bannerhuman/bannerhuman0.mdx", 0.34, (0.0, 0.26, 1.0)),
    ("horde", "war3.w3mod:doodads/lordaeronsummer/props/bannerorc/bannerorc0.mdx", 0.32, (0.86, 0.08, 0.06)),
    ("scarlet", "war3.w3mod:_de.w3mod:doodads/cityscape/props/scarletcrusadestandingbanners/"
                "scarletcrusadestandingbanners0.mdx", 0.32, (0.72, 0.04, 0.04)),
    ("goblin", "war3.w3mod:_de.w3mod:doodads/lordaeronsummer/props/goblinracingarrowpost/"
               "goblinracingarrowpost0.mdx", 0.5, (1.0, 0.8, 0.0)),
    ("brazier", "war3.w3mod:doodads/lordaeronsummer/props/brazier/brazier.mdx", 0.5, (1.0, 1.0, 1.0)),
    ("dwarven", "war3.w3mod:_de.w3mod:doodads/northrend/props/northrendobilisk/northrendobilisk.mdx", 0.24,
     (1.0, 1.0, 1.0)),
]
UTILITY = {"pool": (0, 384, 128, 128), "lineH": (128, 384, 256, 16), "checkH": (128, 400, 256, 16),
           "lineV": (384, 256, 16, 256), "checkV": (400, 256, 16, 256)}


def post(wc3, path, scale, team):
    R = importlib.import_module("wc3render")
    loaded = R.load(wc3, path, team=team)
    triangles = R.posed(loaded, "Stand", scale, 270)
    sprite = R.render(loaded, triangles, lean=LEAN)
    sprite["zmax"] = R.bounds(triangles)[5]
    return sprite


def soft(d):
    """1 at the middle of a soft line, 0 at and past |d| = 1 (polynomial)."""
    d = abs(d)
    return 0.0 if d >= 1 else (1 - d * d) ** 2


def atlas(wc3):
    pixels = [[[0, 0, 0, 0] for _ in range(SIZE)] for _ in range(SIZE)]
    kits = {}
    for index, (name, path, scale, team) in enumerate(KITS):
        sprite = post(wc3, path, scale, team)
        w, h = sprite["width"], sprite["height"]
        assert w <= CELL and h <= CELL, f"{name}: {w} x {h} does not fit a {CELL} cell"
        cx, cy = (index % 4) * CELL, (index // 4) * CELL
        x, y = cx + (CELL - w) // 2, cy + (CELL - h) // 2
        for row in range(h):
            for col in range(w):
                pixels[y + row][x + col] = list(sprite["pixels"][row][col])
        kits[name] = {"x": x, "y": y, "w": w, "h": h, "ox": sprite["ox"], "oy": sprite["oy"],
                      "zmax": round(sprite["zmax"], 1)}
    # The glow: a soft disc, brightest in the middle.
    x0, y0, w, h = UTILITY["pool"]
    for row in range(h):
        for col in range(w):
            dx, dy = (col + 0.5 - w / 2) / (w / 2), (row + 0.5 - h / 2) / (h / 2)
            a = soft(sqrt(dx * dx + dy * dy))
            pixels[y0 + row][x0 + col] = [255, 255, 255, int(255 * a + 0.5)]
    # The lines: a bright core and a fainter halo across their width.
    for key, across in (("lineH", "y"), ("lineV", "x")):
        x0, y0, w, h = UTILITY[key]
        for row in range(h):
            for col in range(w):
                t = (row if across == "y" else col) + 0.5
                d = (t - 8) / 8
                a = max(soft(d * 2.2), 0.35 * soft(d))
                pixels[y0 + row][x0 + col] = [255, 255, 255, int(255 * a + 0.5)]
    # The checks: squares of 8, two across.
    for key, horizontal in (("checkH", True), ("checkV", False)):
        x0, y0, w, h = UTILITY[key]
        for row in range(h):
            for col in range(w):
                along, across = (col, row) if horizontal else (row, col)
                light = (along // 8 + across // 8) % 2 == 0
                pixels[y0 + row][x0 + col] = [244, 242, 236, 255] if light else [22, 20, 18, 255]
    return pixels, kits


def presentation_kit():
    """Presentation.GATE_KIT's posts, read through pinned Lupa."""
    lua = importlib.import_module("lupa.lua51").LuaRuntime(unpack_returned_tuples=True)
    namespace = lua.table()
    source = (ADDON / "Presentation.lua").read_text(encoding="utf-8")
    presentation = lua.execute("local chunk = ...; return assert(loadstring(chunk))('AzerothKart', ...)",
                               source, namespace)
    if presentation is None:
        presentation = namespace.Presentation
    table = presentation.GATE_KIT
    out = {}
    for name, *_ in KITS:
        entry = table.posts[name]
        out[name] = {key: entry[key] for key in ("x", "y", "w", "h", "ox", "oy", "zmax")}
    utility = {key: tuple(table[key][k] for k in (1, 2, 3, 4)) for key in UTILITY}
    return out, utility


def main():
    from paintkit import encode_png, encode_tga
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--wc3", required=True, help="the extracted Warcraft III: Reforged files")
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--preview")
    args = parser.parse_args()
    pixels, kits = atlas(Path(args.wc3))
    data = encode_tga(pixels)
    relative = OUTPUT.relative_to(ROOT).as_posix()
    for name, entry in kits.items():
        print(f'    {name}={{x={entry["x"]}, y={entry["y"]}, w={entry["w"]}, h={entry["h"]}, '
              f'ox={entry["ox"]}, oy={entry["oy"]}, zmax={entry["zmax"]}}},')
    if args.check:
        if not OUTPUT.is_file() or OUTPUT.read_bytes() != data:
            raise SystemExit(f"STALE: {relative}; run without --check")
        posts, utility = presentation_kit()
        if posts != kits or utility != UTILITY:
            raise SystemExit("STALE: Presentation.GATE_KIT differs from the atlas")
        print(f"CHECK PASS: {relative} and Presentation.GATE_KIT")
    else:
        OUTPUT.write_bytes(data)
        print(f"WROTE: {relative}")
    print(f"{len(kits)} posts; {len(data)} bytes; sha256={hashlib.sha256(data).hexdigest()}")
    if args.preview:
        Path(args.preview).write_bytes(encode_png(pixels))
        print(f"preview: {args.preview}")


if __name__ == "__main__":
    main()
