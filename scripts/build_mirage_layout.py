"""Generate the Mirage authoring guide from actual Lua geometry and projection.

python scripts/build_mirage_layout.py
python scripts/build_mirage_layout.py --check
Uses the same pinned Lua 5.1 dependency as test_lua.py; never runs the client.
"""
import argparse
from html import escape
import importlib
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "docs" / "art"


def load_geometry():
    local_deps = ROOT / "local-artifacts" / "python-deps"
    if local_deps.is_dir():
        sys.path.insert(0, str(local_deps))
    try:
        runtime = importlib.import_module("lupa.lua51").LuaRuntime
    except ImportError as exc:
        raise SystemExit("Install requirements-dev.txt as described in scripts/test_lua.py") from exc
    lua = runtime(unpack_returned_tuples=True)

    def module(name):
        path = ROOT / "addon" / "AzerothKart" / (name + ".lua")
        return lua.execute(path.read_text(encoding="utf-8-sig"))

    oval, factory, presentation = (module(name) for name in ("Track", "MirageRaceway", "Presentation"))
    track = factory.new(oval.crossesGate)
    viewport = presentation.fitViewport(track.width, track.height, 800, 480)
    centerline = [{key: track.centerline[index][key] for key in ("x", "y")}
                  for index in range(1, len(track.centerline)+1)]
    gates = [{key: track.gates[index][key] for key in ("name", "ax", "ay", "bx", "by", "nx", "ny")}
             for index in range(1, len(track.gates)+1)]
    spawn = track.spawn()
    view = {key: viewport[key] for key in ("scale", "offsetX", "offsetY", "width", "height",
                                          "worldWidth", "worldHeight", "canvasWidth", "canvasHeight")}
    projected = [dict(zip(("x", "y"), presentation.project(viewport, node["x"], node["y"])))
                 for node in centerline]
    # Scenery notes are deliberately not collision geometry or simulated props.
    landmarks = [
        {"name": "Gnome pit reference", "x": 245, "y": 360},
        {"name": "Goblin pit reference", "x": 850, "y": 360},
        {"name": "Rock mound reference", "x": 455, "y": 785},
    ]
    assert all(not track.isDrivable(item["x"], item["y"]) for item in landmarks)
    return {
        "schema": 1, "purpose": "geometry blockout; not runtime art or a surveyed reconstruction",
        "source": "addon/AzerothKart/MirageRaceway.lua",
        "id": track.id, "version": track.version,
        "width": track.width, "height": track.height, "worldOrigin": "bottom-left, +Y up",
        "roadWidth": track.roadWidth, "roadRadius": track.roadRadius,
        "roadShape": "union of closed line-segment capsules", "closed": True,
        "length": round(track.length, 9), "wallInset": track.wallInset,
        "checkpointMaxStep": track.checkpointMaxStep,
        "centerline": centerline, "gates": gates,
        "spawn": {key: spawn[key] for key in ("x", "y", "heading")},
        "preview": view, "projectedCenterline": projected, "sceneryNotes": landmarks,
    }


def build_svg(layout):
    width, height = layout["width"], layout["height"]
    # Main geometry stays in world units. This is the one SVG downward-Y flip.
    def point(x, y):
        return f"{x:g},{height-y:g}"

    path = "M " + " L ".join(point(node["x"], node["y"]) for node in layout["centerline"]) + " Z"
    pieces = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1216" viewBox="0 0 {width} 1216">',
        '<title>Mirage Raceway geometry blockout v1</title>',
        '<desc>Generated from Lua road, gates and spawn. Diagram uses the same capsule road geometry; not production artwork.</desc>',
        '<defs><marker id="arrow" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="5" markerHeight="5" orient="auto-start-reverse"><path d="M 0 0 L 10 5 L 0 10 Z" fill="#17685f"/></marker></defs>',
        f'<rect width="{width}" height="1216" fill="#f1e7ce"/>',
        '<g font-family="Segoe UI, sans-serif" fill="#382b22">',
        '<text x="40" y="38" font-size="23" font-weight="700">MIRAGE RACEWAY / GEOMETRY BLOCKOUT</text>',
        f'<path d="{path}" fill="none" stroke="#c8b995" stroke-width="{layout["roadWidth"]}" stroke-linejoin="round" stroke-linecap="round"/>',
        f'<path d="{path}" fill="none" stroke="#83765e" stroke-width="2" stroke-dasharray="7 9"/>',
        f'<rect x="{layout["wallInset"]}" y="{layout["wallInset"]}" width="{width-2*layout["wallInset"]}" height="{height-2*layout["wallInset"]}" rx="0" fill="none" stroke="#b17241" stroke-width="2" stroke-dasharray="12 8"/>',
    ]
    label_offsets = {"North": (0, -82), "West": (-105, 0), "South": (0, -80), "Start": (120, 50)}
    for index, gate in enumerate(layout["gates"], 1):
        x, y = (gate["ax"]+gate["bx"])/2, (gate["ay"]+gate["by"])/2
        dx, dy = label_offsets[gate["name"]]
        pieces.extend([
            f'<line x1="{gate["ax"]}" y1="{height-gate["ay"]}" x2="{gate["bx"]}" y2="{height-gate["by"]}" stroke="#17685f" stroke-width="5"/>',
            f'<line x1="{x-24*gate["nx"]}" y1="{height-y+24*gate["ny"]}" x2="{x+24*gate["nx"]}" y2="{height-y-24*gate["ny"]}" stroke="#17685f" stroke-width="4" marker-end="url(#arrow)"/>',
            f'<text x="{x+dx}" y="{height-y-dy}" font-size="17" font-weight="700" text-anchor="middle">{index} {escape(gate["name"])}</text>',
        ])
    for note in layout["sceneryNotes"]:
        x, y = note["x"], height-note["y"]
        pieces.extend([
            f'<circle cx="{x}" cy="{y}" r="28" fill="#dcc49a" stroke="#a2835e" stroke-width="2" stroke-dasharray="5 4"/>',
            f'<text x="{x}" y="{y+49}" font-size="14" text-anchor="middle">{escape(note["name"])}</text>',
        ])
    spawn = layout["spawn"]
    pieces.append(f'<circle cx="{spawn["x"]}" cy="{height-spawn["y"]}" r="9" fill="#c65d22" stroke="#fff6db" stroke-width="3"/>')
    view = layout["preview"]
    lines = [
        f'World: {width} x {height} | Road: {layout["roadWidth"]} units | Centerline: {layout["length"]:.3f} units',
        'Counterclockwise: North > West > South > Start. Orange dot: spawn on Start, facing north.',
        f'800 x 480 preview: scale {view["scale"]:g}, offset ({view["offsetX"]:g}, {view["offsetY"]:g}); map is 480 x 480.',
        'Rough salt uses the existing grass mechanics token. Dashed perimeter is the collision wall.',
        'Scenery circles are authoring notes only. Test Oval remains the playable default.',
        'Generated from Lua data; round joins match capsule union. Not a custom-texture/client test.',
    ]
    pieces.append('<rect x="0" y="1024" width="1024" height="192" fill="#e6d8b9"/>')
    for index, line in enumerate(lines):
        pieces.append(f'<text x="28" y="{1054+index*27}" font-size="16">{escape(line)}</text>')
    pieces.append('</g></svg>')
    return "\n".join(pieces) + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Compare without writing generated files")
    args = parser.parse_args()
    layout = load_geometry()
    outputs = {
        OUTPUT / "mirage-layout.json": json.dumps(layout, indent=2, ensure_ascii=False) + "\n",
        OUTPUT / "mirage-layout.svg": build_svg(layout),
    }
    for path, content in outputs.items():
        if args.check:
            if not path.is_file() or path.read_text(encoding="utf-8") != content:
                raise SystemExit(f"STALE: {path.relative_to(ROOT)}; run this script without --check")
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content, encoding="utf-8", newline="\n")
    mode = "CHECK PASS" if args.check else "GENERATED"
    print(f'{mode}: Mirage {layout["length"]:.3f} units; {len(layout["centerline"])} vertices; '
          f'{len(layout["gates"])} gates; uniform scale {layout["preview"]["scale"]:g}')


if __name__ == "__main__":
    main()
