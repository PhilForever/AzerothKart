# PROGRESS — persistent memory for future Codex runs

**Current milestone:** M0 — Repo + client/API feasibility.
**Current package state (2026-10-18):** Documentation, starter addon and offline test harness created by ChatGPT. No WoW client run. The package passed Python structural validation and `unzip -t`; Lua 5.4 shared-library syntax checks on all four source modules and the three pure-Lua tests passed using `python scripts/test_with_lua54.py`. Target WoW-client behavior and Lua 5.1-family compatibility are NOT verified.
**Git state:** New package; no Git history bundled.

## Completed in starter package
- [x] Clear product vision and staged go/no-go criteria.
- [x] Modular project layout and initial local drivable UI prototype authored.
- [x] Pure Lua track and physics modules authored (pending Lua runtime tests).
- [x] Test requirements, API reference links, client probe matrix, network risk assessment.
- [x] Master prompt, AGENTS instructions, scheduled continuation prompt.

## Not yet verified / outstanding
- [ ] TOC recognized by target installed Forever client, correct interface version.
- [x] Lua source syntax parsed and pure Lua tests executed with local Lua 5.4 shared library.
- [ ] Lua tests repeated with the installed Forever Lua/runtime or compatible Lua 5.1 environment.
- [ ] WoW rendered prototype, keyboard focus/release/combat behavior.
- [ ] Deterministic replay tests and real physics tuning.
- [ ] Multiplayer rate/latency measurements with real clients.
- [ ] Complete lap/checkpoint engine or release-ready content.

## Next exact task for Codex
Inspect repository, re-run `python scripts/validate_project.py` and `python scripts/test_with_lua54.py` if available, run `lua tests/run.lua` using a Lua 5.1-compatible runtime if possible, then conduct M0 client/API smoke test if WoW is accessible. Update `docs/FEASIBILITY.md` with measured observations. Do not build networked kart replication before F4 measurements.

## Session handoff log — append new runs below
Use this format:
```
### YYYY-MM-DD HH:MM <timezone> — agent / branch
Milestone:
Files changed:
Implementation:
Tests actually run: (command, pass/fail/NOT RUN, relevant output)
WoW live client checks: (build / outcome / pending)
Constraints/blockers:
Next exact task:
Git commit (if any):
```
