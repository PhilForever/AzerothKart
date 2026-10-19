"""Export the original runtime Mirage blockout directly from its Lua road mask.

python scripts/build_mirage_background.py
python scripts/build_mirage_background.py --check

Only the standard library and the project's pinned Lua 5.1 runtime are needed.
The result is a fully opaque, uncompressed 32-bit TGA with bottom-left origin.
No concept board, screenshot, third-party texture or model is an input.
"""
import argparse
import hashlib
import importlib
from pathlib import Path
import struct
import sys

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "addon" / "AzerothKart" / "Assets" / "Tracks" / "SaltFlats" / "Background.tga"


def load_track():
    local_deps = ROOT / "local-artifacts" / "python-deps"
    if local_deps.is_dir():
        sys.path.insert(0, str(local_deps))
    try:
        runtime = importlib.import_module("lupa.lua51").LuaRuntime
    except ImportError as exc:
        raise SystemExit("Install requirements-dev.txt as described in scripts/test_lua.py") from exc
    lua = runtime(unpack_returned_tuples=True)
    addon = ROOT / "addon" / "AzerothKart"
    oval = lua.execute((addon / "Track.lua").read_text(encoding="utf-8-sig"))
    factory = lua.execute((addon / "MirageRaceway.lua").read_text(encoding="utf-8-sig"))
    return lua, factory.new(oval.crossesGate)


def road_mask(lua, track):
    # Sample actual pixel centers using the actual Lua predicate. Batch the loop
    # inside Lua rather than paying one Python/Lua crossing per pixel.
    scan = lua.eval("""function(track)
        local rows = {}
        for y=0,track.height-1 do
            local row = {}
            for x=0,track.width-1 do
                row[x+1] = track.isDrivable(x+0.5,y+0.5) and "R" or "."
            end
            rows[y+1] = table.concat(row)
        end
        return table.concat(rows)
    end""")
    return scan(track).encode("ascii")


def noise(x, y):
    """Stable integer mixing; independent of platform PRNG or Python hash salt."""
    value = (x * 374761393 + y * 668265263 + 1729) & 0xffffffff
    value = ((value ^ (value >> 13)) * 1274126177) & 0xffffffff
    return value ^ (value >> 16)


def shade(x, y, road):
    grain = noise(x, y) % 5 - 2
    broad = noise(x // 24, y // 24) % 3 - 1
    if road:
        # A plain warm worn road keeps its exact hard boundary readable. There
        # are no fake lanes, collider props or baked checkpoint highlights.
        delta = grain + broad
        return 164 + delta, 137 + delta, 94 + delta, 255
    # Low-contrast salt cracks are original deterministic cell boundaries.
    # Jitter each horizontal/vertical boundary to avoid a regular tiled grid.
    crack_x = (x + noise(y // 9, 11) % 9) % 67 == 0
    crack_y = (y + noise(x // 11, 29) % 11) % 79 == 0
    delta = grain + broad - (9 if crack_x or crack_y else 0)
    return 231 + delta, 221 + delta, 190 + delta, 255


def build_image(lua, track):
    width, height = int(track.width), int(track.height)
    assert width == height == 1024, "Review runtime texture format if world dimensions change"
    mask = road_mask(lua, track)
    pixels = bytearray(width * height * 4)
    for y in range(height):
        for x in range(width):
            pixel = y * width + x
            red, green, blue, alpha = shade(x, y, mask[pixel] == ord("R"))
            offset = pixel * 4
            pixels[offset:offset+4] = bytes((blue, green, red, alpha))
    # Image type 2=true-color, BGR(A), eight alpha bits, bottom-left origin.
    # Origin and sampling agree with the game's bottom-left, +Y-up world.
    header = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, width, height, 32, 8)
    return header + pixels


def validate_image(image, track):
    """Check the packaging contract and asymmetric world-to-pixel landmarks."""
    header = struct.unpack("<BBBHHBHHHHBB", image[:18])
    width, height = int(track.width), int(track.height)
    assert header == (0, 0, 2, 0, 0, 0, 0, 0, width, height, 32, 8), "Unexpected TGA header"
    assert len(image) == 18 + width * height * 4, "Unexpected TGA payload size"
    assert image[21::4] == b"\xff" * (width * height), "Background must be fully opaque"

    def pixel(x, y):
        offset = 18 + (y * width + x) * 4
        blue, green, red, alpha = image[offset:offset+4]
        return red, green, blue, alpha

    # These asymmetric landmarks detect a top/bottom flip as well as a road
    # offset. Samples on either side of the eastern road check its hard edge.
    samples = ((340, 780, True), (340, 243, False), (700, 360, True),
               (643, 500, False), (644, 500, True), (755, 500, True),
               (756, 500, False), (100, 100, False))
    for x, y, expected_road in samples:
        actual_road = bool(track.isDrivable(x+0.5, y+0.5))
        assert actual_road == expected_road, f"Review geometry landmark {(x,y)}"
        red, green, blue, alpha = pixel(x, y)
        assert (red < 200) == actual_road, f"Road/world mismatch at {(x,y)}"
        assert (red, green, blue, alpha) == shade(x, y, actual_road), f"Wrong orientation at {(x,y)}"
    return len(samples)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Check exact reproducibility without writing")
    args = parser.parse_args()
    lua, track = load_track()
    image = build_image(lua, track)
    samples = validate_image(image, track)
    if args.check:
        if not OUTPUT.is_file() or OUTPUT.read_bytes() != image:
            raise SystemExit(f"STALE: {OUTPUT.relative_to(ROOT)}; run this script without --check")
    else:
        OUTPUT.parent.mkdir(parents=True, exist_ok=True)
        OUTPUT.write_bytes(image)
    digest = hashlib.sha256(image).hexdigest()
    print(f'{"CHECK PASS" if args.check else "GENERATED"}: {OUTPUT.relative_to(ROOT)}; '
          f'1024x1024 BGRA32 bottom-left; {len(image)} bytes; {samples} world/orientation samples; '
          f'sha256={digest}')


if __name__ == "__main__":
    main()
