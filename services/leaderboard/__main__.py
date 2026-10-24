"""Local operator interface to the central store; not an authenticated HTTP API."""
import argparse
import json
from pathlib import Path
import sqlite3
import sys

from .store import LeaderboardStore, StoreError

FIELDS = ("trackId", "trackVersion", "physicsVersion", "lapCount", "tickRate", "rulesVersion")


def read_json(path, maximum):
    with Path(path).open("rb") as handle:
        data = handle.read(maximum + 1)
    if len(data) > maximum:
        raise ValueError("JSON input exceeds size limit")

    def unique(pairs):
        result = {}
        for key, value in pairs:
            if key in result:
                raise ValueError("Duplicate JSON field")
            result[key] = value
        return result

    def invalid_constant(_):
        raise ValueError("Nonfinite JSON number")

    return json.loads(data.decode("utf-8"), object_pairs_hook=unique, parse_constant=invalid_constant)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--db", required=True, type=Path, help="Explicit SQLite file; keep live data outside Git")
    parser.add_argument("--deployment", required=True, help="Operator-assigned server/environment identity")
    parser.add_argument("--catalog", type=Path, default=Path(__file__).with_name("catalog.json"))
    commands = parser.add_subparsers(dest="command", required=True)
    submit = commands.add_parser("submit", help="Operator/development call; --actor is not authentication")
    submit.add_argument("--actor", required=True, help="Full name supplied by the future trusted adapter")
    submit.add_argument("--record", required=True, type=Path, help="JSON record, never a SavedVariables Lua file")
    board = commands.add_parser("board")
    board.add_argument("--key", required=True, help="trackId:trackVersion:physicsVersion:lapCount:tickRate:rulesVersion")
    board.add_argument("--limit", type=int, default=10)
    board.add_argument("--offset", type=int, default=0)
    args = parser.parse_args(argv)
    try:
        catalog = read_json(args.catalog, 32768)
        if type(catalog) is not dict or set(catalog) != {"version", "boards"} or type(catalog["version"]) is not int or catalog["version"] != 1:
            raise ValueError("Unsupported catalogue schema")
        if args.command == "submit":
            record = read_json(args.record, 8192)
        else:
            pieces = args.key.split(":")
            if len(pieces) != len(FIELDS):
                raise ValueError("Invalid board key")
            record = dict(zip(FIELDS, [pieces[0]] + [int(value) for value in pieces[1:]]))
        # No network listeners, game files, credentials or game-server state are
        # accessed. The actual adapter must authenticate identity independently.
        with LeaderboardStore(args.db, deployment_id=args.deployment, allowed_boards=catalog["boards"]) as store:
            if args.command == "submit":
                result = store.submit(args.actor, record)
            else:
                result = store.query(record, limit=args.limit, offset=args.offset)
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return 0
    except (ValueError, StoreError, sqlite3.Error, OSError) as exc:
        print(json.dumps({"error": str(exc)}, ensure_ascii=True), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
