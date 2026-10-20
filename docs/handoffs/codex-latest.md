# Codex handoff — close results and plain connection-test help

Completed 2026-10-21, Europe/Oslo (live check around 00:24–00:28 CEST).

## Branch, source and ownership

- Existing `../AzerothKart-Codex-Review`, branch `codex/results-dismiss`.
- Base `bdb44d1`; button/help implementation `5f03716`; reviewed effects-preservation merge **`8195da9`**, parents `5f03716` and Claude `1004e73` (effects runtime `c6e1b5e`). Final docs follow in a separate commit.
- Main/local origin/main remain `f923d15`; canonical checkout `5570968` and all untracked placeholders/output folders preserved. Claude owns its unchanged worktree and next-vehicles reservation. No push, tag, release, reset or other-checkout merge.
- Scope: UI summary/dismiss callback and successful run/map reset; shared UI regression/count assertions; Codex TransportProbe local help/test; contracts and human-facing instructions. No Physics/Race/Input/Loop/geometry or packet/accounting changes. The result-panel UI.Create block is separate from Claude's effect pool/render/loading work.

## Implemented

**Close results** beside Restart hides only the result panel. It retains race/lap/result/pose/clock/HUD data, does not recapture input, and stays dismissed across Stop, idle updates, rejected Starts and window close/reopen. Successful Start/map selection clears the presentation-only marker so the next ended run shows results. Outer Close still hides the addon.

`/akart net help` prints six bounded local lines: you+friend, full names/new uppercase code, listener first, sender within 20 seconds, wait about 2m15 until BOTH say Stopped, reports/evidence/cancel. It never arms/registers/sends or resets an existing experiment. No network GUI exists. [The plain guide](../NETWORK_QUICK_START.md) separates human steps from first-run compatibility review and the developer procedure. Print Probe remains driving statistics.

Claude's already-installed effects are preserved through reviewed integration: additive Presentation helpers and 38 fixed effect textures, read-only simulation access, guarded atlas fallback. Explicit combined pool **10 frames / 151 textures / 13 font strings**. Effects repeatability means identical sampled-state/effect-update sequences, not invariant particles across rendering cadences. Client drift/boost appearance and cost remain unverified.

## Shared deployment overlap and recovery

Our old-build 20-file preflight matched before Claude's 22:18:43UTC effects deployment. The 00:19 CEST install then backed up all prior files/preserved both atlases but replaced Claude's UI/Presentation/README. Detected on the next handoff read, before any reload, and restored it by reviewing/merging immutable `1004e73`. No prior files lost; both full backups retained.

Final combined install **`8195da9`**,00:24 CEST: `install_local.ps1 -Overwrite` backed up all prior files and verified **22/22** source hashes, no extras. Manifest:
`local-artifacts/install-backups/20261021-002417-215-569e7e1336304203b52dae42c3cc8849/install.json`.
Earlier overlap backup:
`local-artifacts/install-backups/20261021-001921-521-8d0ecbd65dd043d9a5cd8b2728077aab/install.json`.
Both are ignored local artifacts. No other addon or WTF/SavedVariables was modified by deployment. Before another install, read BOTH handoffs and compare the actual target immediately; standalone branch deployment can overwrite the other agent's newer runtime. Coordinate one deployment window.

## Tests actually executed

- Windows Python3.14 / pinned Lupa2.8, canonical ignored dependency path.
- `scripts/test_lua.py --runtime lua51 --tests ui transport_probe`: PASS: 34 parsed, both modules before effects integration; earlier UI-only run also PASS.
- Adapter-only rerun after uppercase/finish-wait wording: PASS.
- **Combined:** `scripts/test_lua.py --runtime lua51 --tests presentation ui transport_probe`: PASS: 34 parsed, three modules. Result dismissal snapshots/retention/new-run reset, bounded idle/active help with no side effects, original lifecycle/race tests, sprite/effects on/off simulation equivalence, pooled 10/ 151/ 13 through 1,001 updates.
- `scripts/build_effect_sprites.py --check`: PASS Particles SHA 15bf541f…2341 and Flame 98254d4b…f98f, matching Claude's files.
- `scripts/validate_project.py`: STATIC PASS: 61 paths after merge; `git diff --check`/staged equivalent PASS.
- No repeated full/Lua5.4 suite or installer matrix. Earlier source-install fixture checks remain historical.

## Actual-client check

Reload completed, `/akart` opened the combined build. Started a stationary Oval run, clicked Stop: tick 812, lap/current 10.53s, stopped sample 13.5s displayed. New button and hint fit. Clicking **Close results** hid the panel while the main window, track, kart, HUD values and idle Start/Track controls remained visible; tick 812/time 10.53s stayed unchanged through later help entry. `/akart net help` printed the six expected lines. Final observed state: addon open/inactive, result panel hidden, chat closed. No character movement/combat, state injection or network arm/send.

Live close/reopen dismissal, full finished/combat variants, moving effects/edge/handling acceptance and performance are NOT RUN in this short check (retention paths covered offline). First two-client traffic, prefix/send returns, RTT/loss/throttle/reconnect and all multiplayer capacity gates remain **NOT RUN**. Network CSV stays header-only; no milestone boxes completed.

## Next single task

When a consenting friend/second client is available, confirm both builds/API setup and exact full names, give personalized commands, then perform the first lowest-rate directed WHISPER window using [the plain guide](../NETWORK_QUICK_START.md) and [developer checklist](../../tests/MANUAL_NETWORK_CHECKLIST.md). No immediate manual test is requested while only one client is available. Multiplayer remains above ghosts; do not select broad replication architecture from offline tests.
