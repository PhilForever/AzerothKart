# Codex handoff — reviewed Ironforge integration

2026-10-22 13:25 +02:00, Europe/Oslo. Branch `codex/ironforge-integration`;
base clean `899d04d`, reservation `7fe251e`, incoming Claude `de2fa5f`.
Normal two-parent merge is prepared; installation follows the committed source.
The deployment-record commit will name that implementation hash and backup.
No publication, main merge, release or milestone completion in this task.

## What changed and what is preserved

Reviewed the complete current Claude handoff and all three Ironforge commits.
Four solo tracks now include Ironforge Grand Prix: original7,077-unit route,
369-unit approach, seven gates, background and preview. Claude's original
handoff is imported verbatim. Catalog/menu conflicts were resolved by retaining
Stormwind's full-speed descriptions and adding Ironforge's entries.

An integration finding reused the already-implemented wall correction:
Ironforge version2 enables14-unit exposed-union clearance with1,745 generated
junctions; `(234,641)` → `(232,641)` now succeeds without a phantom gate-hall
wall. Rough shoulders, route, gates, spawn and art remain unchanged. No new
collision algorithm or global Physics/Circuit/UI/input/race/network change.
Stormwind version3's complete definition is byte-identical to899d04d. The owner
reports "The corner works good now": mark that specific native correction
passed; wider city/performance/milestone acceptance remains open.

All14 art files match Claude de2fa5f (including12 existing assets). All21 Lua
modules outside CapitalCities/Courses/Menu match899d04d. Preserve the pooled
staging transaction, same-ID/future-schema preferences, Stop/results and backend
session/start-clock state. Neither city is in SessionTransport's supported
track list; multiplayer remains Coming soon.

## Executed checks

- `python scripts/test_lua.py --runtime both`: PASS27 modules/52 parsed files
  each, actual Lua5.1/5.4 through existing pinned Lupa2.8. One full integration
  run after focused `--runtime lua51 --tests ui menu` and `--tests circuit`.
- Ironforge saved restore, explicit preview/selection without auto-start,
  destructive image refusal, seven→six→four gate reuse, ordered checkpoint
  walk, approach throttle, rough shoulders, real gate-end walls and concave
  clearance covered. Stormwind regressions retained.
- `python tests/test_circuit_boundary.py -q`: PASS9.
- `python scripts/build_city_tracks.py --wc3 . --geometry-only --check`: PASS;
  no extracted archive needed (all scenery props nonsolid).
- `python scripts/validate_project.py`: PASS103 required paths,24-module TOCs,
  links, ledger; whitespace PASS.
- Preservation PASS: canonical103files/3untracked at5570968; Claude202files/
  17untracked atde2fa5f, statuses/HEADs unchanged. Verified44,315,707-byte all-ref
  bundle. Art/source and authored handoff checks independently passed.

Explicit mocked pool remains71 frames/165 textures/80 fonts. Claude's164/one-
image statements predate the staging fix: two background slots can retain
32MiB of raw city pixels, plus previews/native overhead. This is a resource
bound, not measured native memory or FPS.

**NOT RUN:** Ironforge client loading, driving, walls/railings, camera, preview,
persistence, audio/scaling/performance; Codex full art regeneration (Claude's
separate reproducibility evidence retained); actual new-prefix/start-clock/
live-race/socket reconnect. No native acceptance is inferred from offline tests.

## Installation, recovery and coordination

Pre-install39 files exactly match81cc0ed. Ignored recovery/audit root:
`local-artifacts/ironforge-integration-20261022/20261022-111735-utc/`.
Normal installer must back up all39 prior files, copy41 committed source files
and verify hashes before installation is marked done. No WTF/SavedVariables,
other addon, deletion or user-input automation. Full client exit/restart is
required because the Ironforge textures are new.

Reserved edited scope was the integration's catalog/data/pipeline/tests and
shared current docs, plus this named handoff; no other-agent checkout edits.
Claude should continue from the combined baseline, preserving Stormwindv3,
Ironforgev2 and the staging fix. A possible next branch command, for Claude
only after checking its own worktree status (not executed by Codex):

```powershell
git -C "C:/Users/bakke/Downloads/Forever_Addons/AzerothKart_Codex_Project_Pack/AzerothKart-Claude" status --short
git -C "C:/Users/bakke/Downloads/Forever_Addons/AzerothKart_Codex_Project_Pack/AzerothKart-Claude" switch -c claude/ironforge-polish codex/ironforge-integration
```

Owner check after install: fully restart → `/akart` → Single Player → Ironforge
Grand Prix → kart → Race!. No long matrix or additional network probe requested.
Next Codex executable task: the pure bounded live-race lifecycle controller
around RaceStart's one-shot output, before remote snapshot/UI activation.
Detailed review: [Ironforge integration](../reviews/2026-10-22-ironforge-integration.md).
