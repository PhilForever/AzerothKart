# Verification and QA plan

## Testing layers
1. **Static pack validation:** expected files, synchronized TOC module order, discovery markers and protocol documentation via `python scripts/validate_project.py`. It does not execute Lua or establish API limits.
2. **Offline suite:** `python scripts/test_lua.py` parses all addon/test Lua and executes eight tests in Lua 5.1 and 5.4 via pinned Lupa. Includes analytical track checks, steering/brake/reverse and measured handling baseline, alias-safe input, bounded hitch/elapsed accounting, pure profiling aggregates, synthetic 60-second schedules at 30/60/144 Hz, every-field replay equivalence over 10k ticks at 30/60/144 simulated FPS, and mocked UI/Core lifecycle/allocations/combat guard. Timing regressions check frozen stopped samples, retained fractional time, fresh Start resets, immediate Start/Stop HUD updates and explicit probe values. Synthetic durations/cadences are not observed client FPS or performance. Record each executed command and result in `PROGRESS.md`; native `lua tests/run.lua` and the optional Linux `python scripts/test_with_lua54.py` run the same suite when available.
3. **Simulation property tests (later):** multiple seeded driving scenarios, lap gate order, no teleport-finish, hazard events and track/physics compatibility. The current seeded input tape proves same-runtime replay equivalence for its one tested seed, not cross-client floating-point identity or handling quality.
4. **Protocol/unit test doubles (to build after M2):** fake transport reorder, duplicate, loss, throttle, sender spoof, malformed/saturated packets, session mismatch and bounded retry.
5. **Manual Forever client tests:** visible load, UI, focus, keyboard controls, combat, reload, zoning, high UI scale, 20-minute continuous play, and 2-client network probe.
6. **Performance regression:** FPS and Lua memory before/during/after 8 visual karts; total UI objects stable after 30 minutes.

The mocked combat lifecycle also covers repeated Close/toggle/reopen and rejected Start attempts: the interruption note and terminal result stay retained, refusal text remains visible, and only a successful fresh Start clears them. Those assertions are separate from actual-client acceptance.

Road rendering regressions inspect the textures actually produced by `UI.Create`: 64 outer bands, 32 island bands, explicit draw order and canvas bounds. A dense grid compares the painted footprint with `Track.isDrivable` outside the documented 3.5-unit vertical raster margin and checks the former mismatch at `(400,440)`. Existing update/reopen allocation and deterministic replay tests still apply. These checks establish geometry consistency in the mock; actual display/scaling and sustained performance remain client checks.

The Performance unit test covers phase totals/maxima, zero-resolution samples, missing/malformed/nonfinite/negative/backwards readings, finite sum overflow, namespace purity and the 600-attempt cap including invalid samples. UI integration verifies no profiler reads by default, reachable slash commands, active-change refusal, guarded arming, three reads per sampled update with no calls after the cap, frozen stopped/reopened aggregates, fresh Start reset and unchanged 6/99/3 UI counts. An identical 650-update driving tape produces identical state with profiling on/off. Reader errors and validation/arithmetic refusal stay bounded and cannot stop simulation. Mock timings prove accounting only, not actual client costs.

## Priority manual smoke suite
- A. Addon shows up with correct TOC and `/akart`; no Lua error.
- B. Press Start Test Drive out of combat, test W then Up, S then Down, A/D then Left/Right; car moves and rotates, stays near oval. Simultaneous W/Up is SKIPPED at the owner's request for this keyboard; offline alias coverage remains.
- C. Release keys and move chat focus: no character movement blocked after closing racing UI.
- D. ESC and close button both release game, toggling with `/akart` works; Alt-Tab and `/reload` safe.
- E. Attempt while in combat -> no keyboard capture; if combat begins mid-race no restricted API calls/taint.
- F. Run 15 min, resize UI scale, record FPS and memory. Confirm no per-tick widget creation.
- G. M0 SavedVariables: isolated sentinel across reload/logout/restart and inactive capture after load. Corrupt-save handling/migrations for actual settings/records remain later milestones.

Startup/load and one optional stationary profiler window were observed on build 70450: 600 valid readings, stopped/reopen/disarm retention and explicit counts 6/99/3. [Exact evidence](evidence/2026-10-19-m0-stationary-profile.md). Mock tests passed for a snapping experiment that hid the road after reload; the experiment and its fixtures were removed, demonstrating why actual-client acceptance is required. The next task is review of that startup-versus-live rendering discrepancy before another rendering change. Two older near-minute drives are recorded; the complete three-drive independent-timer protocol, fresh unprofiled Start, scaling/stress and full performance acceptance remain **PENDING**. Record scoped elapsed milliseconds separately from frame intervals and whole-client FPS. No extra combat test is requested during the owner's redirected work.

## Developer install helper fixtures

Run from the repository root in each available runtime:

```powershell
powershell.exe -NoProfile -File tests/test_install_local.ps1
pwsh -NoProfile -File tests/test_install_local.ps1
```

The suite uses temporary workspace AddOns fixtures, not the installed game or SavedVariables. Cover fresh installation and repeated installation into the same addon target; refusal of existing targets without `-Overwrite`; zero writes for `-WhatIf` and declined confirmation; prior-tree backup and SHA-256 manifests; copied-file verification; and preservation/reporting of unknown target files. Exercise preflight rejection and a controlled copy failure, checking that the retained backup is usable and the failure record does not imply a verified target. A manual restore rehearsal must verify recovered fixture-file hashes and acknowledge any additional files left by an interrupted overlay.

The helper is a file overlay, not an atomic update or automatic rollback. No source Lua, race, UI, migration or multiplayer acceptance follows from passing these fixtures. Record the executed commands, runtime versions and exact outcomes in `PROGRESS.md`; do not infer a second runtime pass or a game install from one run. See [developer install and recovery](RELEASE.md#developer-install) for the intended operator workflow.

## Network testing (M2, when implemented)
- Distinguish sender enqueue success vs receiver ACK. Send small packets 0.5–4/sec during consented test only.
- Validate 2 players first; then 4; then 8 if realistic. Measure p50/p95 RTT, ACK timeouts, reorder/duplicates, arrival gaps, throttle returns, message counts and recovery. Missing ACKs do not uniquely prove packet loss.
- Repeat instanced and non-instanced; record client build, connection, channel, payload bytes and conditions.
- Fail behavior: leave button still responsive, no stale winning result, no infinite retransmits.

## Release blocking bugs
Key capture not released; combat taint; corrupt SavedVariables crashes; lap skips; irreversible stuck state; cheating other players via spoofed packets; unbounded memory/packet sends; accidental prohibited automation.

## Record actual evidence
Never mark tests passed without running them. Include command logs, screenshots if user supplies them, exact client build and reproducible steps in `PROGRESS.md`.
