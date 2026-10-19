"""Parse all addon/tests and run the suite with real Lua via pinned Lupa.

python -m pip install --target local-artifacts/python-deps -r requirements-dev.txt
python scripts/test_lua.py --runtime both
python scripts/test_lua.py --runtime lua51 --tests physics input drift ui
Mocks cannot establish WoW rendering, taint, focus or persistence behavior.
"""
import argparse
import importlib
import os
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--runtime", choices=("lua51", "lua54", "both"), default="both")
    test_names = sorted(path.stem.removeprefix("test_") for path in (ROOT / "tests").glob("test_*.lua"))
    parser.add_argument("--tests", nargs="+", choices=test_names,
                        help="Run only these modules; still parse all Lua sources")
    args = parser.parse_args()
    local_deps = ROOT / "local-artifacts" / "python-deps"
    if local_deps.is_dir():
        sys.path.insert(0, str(local_deps))
    os.chdir(ROOT)
    runtimes = ("lua51", "lua54") if args.runtime == "both" else (args.runtime,)
    files = sorted((ROOT / "addon").rglob("*.lua")) + sorted((ROOT / "tests").glob("*.lua"))
    for name in runtimes:
        try:
            runtime = importlib.import_module("lupa." + name).LuaRuntime
        except ImportError as exc:
            raise SystemExit("Missing pinned Lupa runtime. See requirements-dev.txt / this script's help.") from exc
        lua = runtime(unpack_returned_tuples=True)
        compile_only = lua.eval("function(source, name) local fn, err = (loadstring or load)(source, name); "
                                "if not fn then error(err) end end")
        for path in files:
            compile_only(path.read_text(encoding="utf-8-sig"), "@" + path.relative_to(ROOT).as_posix())
        print(f"{name}: {len(files)} Lua source/test files parsed", flush=True)
        if args.tests:
            for test in args.tests:
                lua.execute(f'dofile("tests/test_{test}.lua")')
                print(f"{name}: {test} PASS", flush=True)
            print(f"{name}: focused checks PASS (offline; client checks still pending)", flush=True)
        else:
            lua.execute('dofile("tests/run.lua")')
            print(f"{name}: suite PASS (offline; client checks still pending)", flush=True)


if __name__ == "__main__":
    main()
