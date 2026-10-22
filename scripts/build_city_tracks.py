"""Build the Capital Cities Cup tracks: city scenery, preview cells and geometry data.

python scripts/build_city_tracks.py --wc3 ROOT             # write every output
python scripts/build_city_tracks.py --wc3 ROOT --check     # verify exact bytes, write nothing
python scripts/build_city_tracks.py --wc3 ROOT --preview   # also write review PNGs under docs/art/tracks/
python scripts/build_city_tracks.py --wc3 ROOT --city stormwind_city

ROOT holds Warcraft III Reforged files extracted from the owner's own install
by scripts/wc3casc.py (paths as the archive names them, e.g.
ROOT/war3.w3mod/doodads/...). They are not stored in this repository; only
the finished pictures are.

Outputs, per city in city_layouts.CITIES:

- addon/AzerothKart/CapitalCities.lua: the circuit geometry (centerline,
  branches, street wall radius, plazas, gates, spawn, solid boxes), generated
  from city_layouts.py. Solid boxes of scenery models come from the models'
  own footprints.
- addon/AzerothKart/Assets/Tracks/<Folder>/Background.tga: the scenery, one
  texel per world unit, opaque BGRA32, bottom-left origin, painted by
  city_paint.py from the same capsules Circuit.lua collides with: the road
  edge is the paving edge and the street's walls stand a kart's half-length
  beyond the karts' reach.

Standard library only; integer compositing over IEEE-exact model rendering,
so the bytes are reproducible.
"""
import argparse
import hashlib
import importlib
import struct
import sys
from math import floor, pi, sqrt
from pathlib import Path

import city_layouts as L
import wc3render as R
from circuit_boundary import boundary_vertices

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "addon" / "AzerothKart"
LUA_OUTPUT = ADDON / "CapitalCities.lua"
DOCS = ROOT / "docs" / "art" / "tracks"
HEADINGS = {"north": "math.pi/2", "south": "-math.pi/2", "east": "0", "west": "math.pi"}
HEADING_VALUES = {"north": pi / 2, "south": -pi / 2, "east": 0.0, "west": pi}


# ---------------------------------------------------------------------------
# Geometry: centerline, gates, spawn and solids, then the Lua data file.


def prop_box(wc3, city, item):
    """The collision box of a solid scenery model, or None."""
    solid = item["solid"]
    if not solid:
        return None
    if solid is not True:
        x0, y0, x1, y1 = solid
        return L.box(item["name"], x0, y0, x1, y1)
    loaded = R.load(wc3, item["model"], team=city["team"], replaceables=city.get("replaceables"))
    triangles = R.posed(loaded, item["sequence"], item["scale"], item["yaw"])
    fx0, fx1, fy0, fy1, _, _ = R.bounds(triangles)     # the model's ground extent
    m = item["margin"]
    x0, y0 = int(floor(item["x"] + fx0 + m + 0.5)), int(floor(item["y"] + fy0 + m + 0.5))
    x1, y1 = int(floor(item["x"] + fx1 - m + 0.5)), int(floor(item["y"] + fy1 - m + 0.5))
    return L.box(item["name"], x0, y0, x1, y1)


def geometry(wc3, city):
    width, height = city["size"]
    solids = [dict(s) for s in city["solids"]]
    for item in city["props"]:
        found = prop_box(wc3, city, item)
        if found:
            solids.append(found)
    seen = {}
    for s in solids:     # unique ids: a repeated model gets a numbered suffix
        seen[s["id"]] = seen.get(s["id"], 0) + 1
        if seen[s["id"]] > 1:
            s["id"] = "%s_%d" % (s["id"], seen[s["id"]])
    for s in solids:     # clip to the world; a box may run off the map edge
        x0, y0 = max(0, s["x"]), max(0, s["y"])
        x1, y1 = min(width, s["x"] + s["width"]), min(height, s["y"] + s["height"])
        s.update(x=x0, y=y0, width=x1 - x0, height=y1 - y0)
    sx, sy, _ = city["spawn"]
    heading = spawn_heading(city)
    centerline = city["centerline"] if "centerline" in city else L.fillet(city["corners"])
    plazas = [{k: round(p[k], 1) for k in ("ax", "ay", "bx", "by", "radius")} for p in city.get("plazas", [])]
    result = {"id": city["id"], "name": city["name"], "version": city.get("version", 1),
            "width": width, "height": height, "wallInset": L.WALL_INSET, "roadRadius": L.ROAD_RADIUS,
            "wallRadius": L.WALL_RADIUS, "fullSpeedToWalls": city.get("full_speed_to_walls", False),
            "kart": L.KART, "centerline": centerline,
            "branches": city.get("branches", []), "plazas": plazas, "gates": city["gates"],
            "solids": solids, "spawn": (sx, sy, heading)}
    clearance = city.get("wall_clearance")
    if clearance is not None:
        # The runtime data rounds authored coordinates to tenths. Generate
        # junctions against exactly those capsules, without changing art data.
        canonical = dict(result)
        point = lambda p: (float(number(p[0])), float(number(p[1])))
        canonical["centerline"] = [point(p) for p in centerline]
        canonical["branches"] = [[point(p) for p in branch] for branch in result["branches"]]
        canonical["plazas"] = [{key: float(number(value)) for key,value in p.items()} for p in plazas]
        result["wallClearance"] = clearance
        result["wallVertices"] = boundary_vertices(canonical, clearance)
    return result


def q(text):
    """A Lua string literal (ASCII names only)."""
    assert all(32 <= ord(c) < 127 for c in text), text
    return '"' + text.replace("\\", "\\\\").replace('"', '\\"') + '"'


def number(value):
    text = ("%.1f" % value).rstrip("0").rstrip(".")
    return "0" if text == "-0" else text


def lua_data(tracks):
    lines = [
        "-- Capital Cities Cup circuit geometry. GENERATED by scripts/build_city_tracks.py",
        "-- from scripts/city_layouts.py; edit the layouts there, not this file.",
        "-- Pure data: Circuit.new builds each track from its entry.",
        "local _, namespace = ...",
        "local CapitalCities = {}",
        "",
    ]
    for g in tracks:
        lines.append("CapitalCities[%s] = {" % q(g["id"]))
        lines.append("    id=%s, version=%d, name=%s," % (q(g["id"]), g["version"], q(g["name"])))
        lines.append("    width=%d, height=%d, wallInset=%d, roadRadius=%d, wallRadius=%d, checkpointMaxStep=5," %
                     (g["width"], g["height"], g["wallInset"], g["roadRadius"], g["wallRadius"]))
        if g.get("fullSpeedToWalls"):
            lines.append("    fullSpeedToWalls=true,")
        if "wallClearance" in g:
            lines.append("    wallClearance=%s," % number(g["wallClearance"]))
            lines.append("    wallVertices={")
            for x,y in g["wallVertices"]:
                lines.append("        {x=%.8f,y=%.8f}," % (x,y))
            lines.append("    },")
        sx, sy, heading = g["spawn"]
        lines.append("    spawn={x=%s, y=%s, heading=%s}," % (number(sx), number(sy), heading_text(heading)))

        def points(name, line, indent):
            lines.append(indent + name + "{")
            row = []
            for x, y in line:
                row.append("{x=%s,y=%s}," % (number(x), number(y)))
                if len(row) == 5:
                    lines.append(indent + "    " + " ".join(row))
                    row = []
            if row:
                lines.append(indent + "    " + " ".join(row))
            lines.append(indent + "},")
        points("centerline=", g["centerline"], "    ")
        lines.append("    branches={")
        for branch in g["branches"]:
            points("", branch, "        ")
        lines.append("    },")
        lines.append("    plazas={")
        for p in g["plazas"]:
            lines.append("        {ax=%s, ay=%s, bx=%s, by=%s, radius=%s}," % (
                number(p["ax"]), number(p["ay"]), number(p["bx"]), number(p["by"]), number(p["radius"])))
        lines.append("    },")
        lines.append("    gates={")
        for gate in g["gates"]:
            lines.append("        {name=%s, ax=%s, ay=%s, bx=%s, by=%s, nx=%d, ny=%d}," % (
                q(gate["name"]), number(gate["ax"]), number(gate["ay"]), number(gate["bx"]), number(gate["by"]),
                gate["nx"], gate["ny"]))
        lines.append("    },")
        lines.append("    solids={")
        for s in g["solids"]:
            lines.append("        {id=%s, x=%d, y=%d, width=%d, height=%d}," % (
                q(s["id"]), s["x"], s["y"], s["width"], s["height"]))
        lines.append("    },")
        lines.append("}")
        lines.append("")
    lines.append("if type(namespace) == \"table\" then namespace.CapitalCities = CapitalCities end")
    lines.append("return CapitalCities")
    return "\n".join(lines) + "\n"


def heading_text(heading):
    """A compass word, or a number of radians for a diagonal start."""
    if heading in HEADINGS:
        return HEADINGS[heading]
    return "%.6f" % heading


def spawn_heading(city):
    """The spawn's heading: a compass word, or along the start branch."""
    from math import atan2
    sx, sy, heading = city["spawn"]
    if isinstance(heading, (int, float)):
        return heading
    if heading in HEADINGS:
        return heading
    branch = city["branches"][0]
    (ax, ay), (bx, by) = branch[0], branch[1]
    return atan2(by - ay, bx - ax)


def segment_distance(x, y, ax, ay, bx, by):
    dx, dy = bx - ax, by - ay
    t = ((x - ax) * dx + (y - ay) * dy) / (dx * dx + dy * dy)
    t = max(0.0, min(1.0, t))
    ex, ey = x - (ax + t * dx), y - (ay + t * dy)
    return sqrt(ex * ex + ey * ey)


def road_segments(g):
    line = g["centerline"]
    out = [(line[i - 1], line[i]) for i in range(len(line))]
    for branch in g.get("branches", []):
        out += [(branch[i - 1], branch[i]) for i in range(1, len(branch))]
    return out


def road_distance(g, x, y):
    return min(segment_distance(x, y, *a, *b) for a, b in road_segments(g))


def reach_gap(g, x, y):
    """Distance beyond the karts' reach (<= 0: drivable): street or plaza."""
    best = road_distance(g, x, y) - g["wallRadius"]
    for p in g["plazas"]:
        best = min(best, segment_distance(x, y, p["ax"], p["ay"], p["bx"], p["by"]) - p["radius"])
    return best


def course_samples(g, step=8.0):
    """(x, y, part, arc) along the loop (part 0) and each branch (part 1+)."""
    out = []
    parts = [(g["centerline"] + g["centerline"][:1], 0)] + [(b, k + 1) for k, b in enumerate(g["branches"])]
    for line, part in parts:
        arc = 0.0
        for i in range(1, len(line)):
            (ax, ay), (bx, by) = line[i - 1], line[i]
            length = sqrt((bx - ax) ** 2 + (by - ay) ** 2)
            n = max(1, int(length / step))
            for k in range(n):
                out.append((ax + (bx - ax) * k / n, ay + (by - ay) * k / n, part, arc + length * k / n))
            arc += length
    return out


def validate_geometry(g):
    """Authoring rules: gates span the street wall to wall and guard one
    stretch; the spawn is on the road; separate stretches keep a wall between
    them; solids stand inside the street, clear of the paving; the street
    stays inside the world."""
    width, height, r, inset = g["width"], g["height"], g["roadRadius"], g["wallInset"]
    reach, kart = g["wallRadius"], g["kart"]
    line = g["centerline"]
    assert len(line) >= 3
    segments = road_segments(g)
    for gate in g["gates"]:
        span = max(abs(gate["bx"] - gate["ax"]), abs(gate["by"] - gate["ay"]))
        samples = [(gate["ax"] + (gate["bx"] - gate["ax"]) * k / span, gate["ay"] + (gate["by"] - gate["ay"]) * k / span)
                   for k in range(int(span) + 1)]
        cx, cy = min(samples, key=lambda q: road_distance(g, *q))
        assert road_distance(g, cx, cy) < 1.0, f"gate {gate['name']} does not cross the centerline"
        assert gate["ax"] == gate["bx"] or gate["ay"] == gate["by"], f"gate {gate['name']} is not axis-aligned"
        # Both ends lie beyond the karts' reach, so no kart can pass round
        # them, and every drivable point the gate crosses belongs to the
        # stretch it guards (segments near its centre), not another part.
        local = [(a, b) for a, b in segments if segment_distance(cx, cy, *a, *b) < 3 * reach]
        for t in (0.0, 1.0):
            px = gate["ax"] + (gate["bx"] - gate["ax"]) * t
            py = gate["ay"] + (gate["by"] - gate["ay"]) * t
            assert 0.0 <= reach_gap(g, px, py) <= 40.0, f"gate {gate['name']} does not span the street"
        for k in range(65):
            px = gate["ax"] + (gate["bx"] - gate["ax"]) * k / 64
            py = gate["ay"] + (gate["by"] - gate["ay"]) * k / 64
            if reach_gap(g, px, py) < 0:
                assert min(segment_distance(px, py, *a, *b) for a, b in local) < reach, \
                    f"gate {gate['name']} reaches another part of the course"
    sx, sy, _ = g["spawn"]
    assert road_distance(g, sx, sy) < r - 20, "spawn sits on the road"
    # Separate stretches: a wall (both streets' kart clearance) between them.
    samples = course_samples(g)
    loop_length = max(s[3] for s in samples if s[2] == 0)
    branch_length = {p: max(s[3] for s in samples if s[2] == p) for p in {s[2] for s in samples}}
    apart = 2 * (reach + kart) + 8
    for i, (ax, ay, pa, sa) in enumerate(samples):
        for bx, by, pb, sb in samples[i + 1:]:
            if pa == pb == 0:
                along = min(abs(sa - sb), loop_length - abs(sa - sb))
                if along < 3 * apart:
                    continue
            elif pa == pb:
                if abs(sa - sb) < 3 * apart:
                    continue
            else:
                # A branch meets the loop at its far end (the junction).
                if pb != 0 and pa == 0:
                    ax, ay, pa, sa, bx, by, pb, sb = bx, by, pb, sb, ax, ay, pa, sa
                if branch_length[pa] - sa < 3 * apart:
                    continue
            d = sqrt((ax - bx) ** 2 + (ay - by) ** 2)
            assert d >= apart, f"course stretches merge near ({ax:.0f}, {ay:.0f}) and ({bx:.0f}, {by:.0f})"
    for x, y, _, _ in samples:
        assert reach + kart + inset <= x <= width - reach - kart - inset and \
            reach + kart + inset <= y <= height - reach - kart - inset, f"street leaves the world at ({x:.0f}, {y:.0f})"
    for s in g["solids"]:
        assert s["width"] > 0 and s["height"] > 0, f"solid {s['id']} is empty"
        x0, y0, x1, y1 = s["x"] - inset, s["y"] - inset, s["x"] + s["width"] + inset, s["y"] + s["height"] + inset
        # Inside the street: every point of the expanded box is drivable.
        for k in range(41):
            for px, py in ((x0 + (x1 - x0) * k / 40, y0), (x0 + (x1 - x0) * k / 40, y1),
                           (x0, y0 + (y1 - y0) * k / 40), (x1, y0 + (y1 - y0) * k / 40)):
                assert reach_gap(g, px, py) < -2.0, f"solid {s['id']} meets the street's wall"
        # Clear of the paving (no road point inside the expanded solid),
        # unless it stands on a plaza: open paving the karts drive round it.
        on_plaza = any(all(segment_distance(px, py, p["ax"], p["ay"], p["bx"], p["by"]) < p["radius"] - 2.0
                           for px, py in ((x0, y0), (x0, y1), (x1, y0), (x1, y1))) for p in g["plazas"])
        for (ax, ay), (bx, by) in ([] if on_plaza else road_segments(g)):
            steps = max(1, int(sqrt((bx - ax) ** 2 + (by - ay) ** 2) / 4))
            for k in range(steps + 1):
                px, py = ax + (bx - ax) * k / steps, ay + (by - ay) * k / steps
                qx, qy = min(max(px, x0), x1), min(max(py, y0), y1)
                assert (px - qx) ** 2 + (py - qy) ** 2 >= r * r - 1e-6, \
                    f"solid {s['id']} reaches the road near ({px:.0f}, {py:.0f})"
    return True


# ---------------------------------------------------------------------------
# Command line.


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--wc3", type=Path, required=True, help="folder of extracted Warcraft III files")
    parser.add_argument("--check", action="store_true", help="verify outputs without writing")
    parser.add_argument("--preview", action="store_true", help="also write review PNGs")
    parser.add_argument("--city", help="build only this city id (geometry is always complete)")
    parser.add_argument("--geometry-only", action="store_true", help="only the Lua circuit data")
    args = parser.parse_args()
    tracks = [geometry(args.wc3, city) for city in L.CITIES]
    for g in tracks:
        validate_geometry(g)
    text = lua_data(tracks)
    relative = LUA_OUTPUT.relative_to(ROOT).as_posix()
    if args.check:
        if not LUA_OUTPUT.is_file() or LUA_OUTPUT.read_text(encoding="utf-8") != text:
            raise SystemExit(f"STALE: {relative}; run without --check")
        print(f"CHECK PASS: {relative}")
    else:
        LUA_OUTPUT.write_text(text, encoding="utf-8", newline="\n")
        print(f"WROTE: {relative}")
    if args.geometry_only:
        return
    import city_paint
    for city, g in zip(L.CITIES, tracks):
        if args.city and city["id"] != args.city:
            continue
        city_paint.build(args.wc3, city, g, check=args.check, preview=args.preview)


if __name__ == "__main__":
    main()
