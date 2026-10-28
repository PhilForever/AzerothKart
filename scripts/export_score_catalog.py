"""Export allowed score boards from the canonical Lua course/record context.

python scripts/export_score_catalog.py          # update the checked-in catalogue
python scripts/export_score_catalog.py --check  # compare without writing
Uses pinned development Lupa, never reads live SavedVariables or game files.
The central store consumes only the resulting JSON and needs no Lua runtime.
"""
import argparse
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "services" / "leaderboard" / "catalog.json"
FIELDS = ("trackId", "trackVersion", "physicsVersion", "lapCount", "tickRate", "rulesVersion")


def export():
    deps = ROOT / "local-artifacts" / "python-deps"
    if deps.is_dir():
        sys.path.insert(0, str(deps))
    try:
        from lupa.lua51 import LuaRuntime
    except ImportError as exc:
        raise SystemExit("Install requirements-dev.txt for the catalogue check (Lupa 2.8).") from exc
    lua = LuaRuntime(unpack_returned_tuples=True)
    namespace = lua.table()
    loader = lua.eval("function(source, label, ns) assert(loadstring(source, label))('AzerothKart', ns) end")
    for name in ("Track", "MirageRaceway", "Circuit", "CapitalCities", "Dungeon", "LayeredTrack", "ScarletCrusade", "Battlegrounds", "ArathiGrass", "Courses",
                 "Physics", "Highscores", "SoloRecords"):
        path = ROOT / "addon" / "AzerothKart" / (name + ".lua")
        loader(path.read_text(encoding="utf-8-sig"), "@" + name + ".lua", namespace)
    boards = []
    for index in sorted(namespace.Courses.LIST.keys()):
        course = namespace.Courses.LIST[index]
        if not namespace.Courses.available(course.id):
            continue
        track = namespace.Courses.build(course.id, namespace.Track.crossesGate)
        context = namespace.SoloRecords.Context(track)
        if context is None or namespace.Highscores.BoardKey(context) is None:
            raise ValueError("Invalid score context for " + course.id)
        board = {key: context[key] for key in FIELDS}
        for key in FIELDS[1:]:
            value = board[key]
            if int(value) != value:
                raise ValueError("Noninteger context field " + key)
            board[key] = int(value)
        boards.append(board)
    if not boards:
        raise ValueError("No selectable score boards")
    return (json.dumps({"version": 1, "boards": boards}, indent=2, ensure_ascii=False) + "\n").encode("utf-8")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    data = export()
    if args.check:
        if not DEST.is_file() or DEST.read_bytes() != data:
            raise SystemExit("STALE score catalogue; run scripts/export_score_catalog.py")
    else:
        DEST.parent.mkdir(parents=True, exist_ok=True)
        DEST.write_bytes(data)
    print(("CHECK PASS" if args.check else "EXPORTED") + ": " + str(len(json.loads(data)["boards"])) + " canonical score boards")


if __name__ == "__main__":
    main()
