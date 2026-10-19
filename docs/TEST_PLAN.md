# Verification and QA plan

## Current build-first cadence

The owner requested about 80% less testing on 2026-10-19 ([ADR 0007](adr/0007-build-first-development.md)). Build local M1 slices with one targeted Lua 5.1 check and cheap relevant structural validation. For the countdown slice, `python scripts/test_lua.py --runtime lua51 --tests race ui` parses all Lua but executes only those modules. Broad dual-runtime, long manual scale/profiling and stress matrices below are deferred until a concrete failure/risk or integration checkpoint. M0/M1/M3 acceptance remains open; deferred checks are NOT RUN, not waived passes.

The v3 drift slice passed focused Lua 5.1 physics/input/UI checks (17 files parsed) and a separate drift run covering charge thresholds, signed slip, cancellation, boost bounds/duration and a 720-tick tape at 30/60/144 schedules. The v4 surface slice added road/grass classification, gradual forward/reverse slowdown, road recovery, cancellation on entry and tangent wall/corner response. Version 5 adds progressive steering; its focused checks target bounded buildup, faster release centering, center-first reversal, opposing-key cancellation, reverse yaw, wall reset, grass retention and immediate raw-input drift cancellation. Current presentation coverage targets clamped scalar positions, shortest-arc heading, exact endpoints, unchanged simulation states and namespace purity, plus meter readiness at charge ticks 53/54/108 and boost fractions on one 48-tick capacity. UI coverage includes zero-step/catch-up interpolation, exact stopped/fresh-Start poses, meter fill/phase caching, empty-fill hiding, retained stopped feedback and stable current 8/110/13 explicit object counts. See PROGRESS for exact executed commands/results and the next build task. Human steering/handling/layout/interpolation/meter/countdown/finish appearance, Lua 5.4 and the complete suite are **NOT RUN this slice**.

Checkpoint coverage targets strict directional finite-segment crossings, endpoints, rejection of backward/parallel/zero movement and departures from the line, ordered four-gate terminal progress, duplicate/stale/gapped ticks, finite movement bounds, reset/retention and same-input fixed-step replay. Laps coverage targets repeated circuits, exactly one award per accepted finish, immediate rearming, exact integer current/last durations, clock advancement without malformed-movement awards, duplicate/gap rejection, immutable state and render-cadence equivalence. Race coverage targets exact 180-tick countdown and 3/2/1/GO boundaries, GO timing-origin reset, the fixed three-lap finish, exact total/finish ticks, retained terminal object identity and partial stopped/interrupted results with explicit module dependencies. Loop coverage targets callback cancellation after a counted step, fractional-remainder/drop accounting and no false hitch on ordinary finishes. UI integration targets sampled held input with neutral countdown physics, spawn retention until GO, first driving input at tick 181, GO visibility for racing ticks 0–59, phase-cached cue writes, hitch/drop behavior without skipped countdown, zero elapsed stopped/interrupted countdown results, fresh-countdown restart, actual physics coordinates rather than interpolation, next/passed gate feedback, completed/current/last lap HUD values, exact finish pose, release of capture, no extra catch-up physics steps, stopped/combat/reopen result retention, rejected/successful restart and pooled setters/allocations. A rejected consecutive oversized movement consumes its tick to allow recovery; these guards do not prove an entire valid road route or establish anti-cheat. No best record, save, ghost or remote winner comparison is under test. Record only commands actually executed in PROGRESS.

## Testing layers
1. **Static pack validation:** expected files, synchronized TOC module order, discovery markers and protocol documentation via `python scripts/validate_project.py`. It does not execute Lua or establish API limits.
2. **Offline suite, integration checkpoint:** `python scripts/test_lua.py` parses all addon/test Lua and executes the complete suite in Lua 5.1 and 5.4 via pinned Lupa; `--tests` selects focused modules for normal slices. Includes analytical track checks, handling/drift, alias-safe input, bounded hitch/elapsed accounting, pure profiling aggregates, synthetic 60-second schedules, 10k-tick replay equivalence and mocked UI/Core lifecycle/allocations/combat guards. Timing regressions check frozen stopped samples, fresh Start resets, immediate Start/Stop HUD updates and explicit probe values. Synthetic durations/cadences are not observed client FPS or performance. Record each executed command and result in `PROGRESS.md`; native `lua tests/run.lua` and optional Linux `python scripts/test_with_lua54.py` support the complete suite when needed.
3. **Simulation property tests (later):** multiple seeded driving scenarios, lap gate order, no teleport-finish, hazard events and track/physics compatibility. The current seeded input tape proves same-runtime replay equivalence for its one tested seed, not cross-client floating-point identity or handling quality.
4. **Protocol/unit test doubles (to build after M2):** fake transport reorder, duplicate, loss, throttle, sender spoof, malformed/saturated packets, session mismatch and bounded retry.
5. **Manual Forever client tests:** visible load, UI, focus, keyboard controls, combat, reload, zoning, high UI scale, 20-minute continuous play, and 2-client network probe.
6. **Performance regression:** FPS and Lua memory before/during/after 8 visual karts; total UI objects stable after 30 minutes.

The mocked combat lifecycle also covers repeated Close/toggle/reopen and rejected Start attempts: the interruption note and terminal result stay retained, refusal text remains visible, and only a successful fresh Start clears them. Those assertions are separate from actual-client acceptance.

Road rendering regressions inspect the textures actually produced by `UI.Create`: 64 outer bands, 32 island bands, explicit grass sublevel below the road and canvas bounds. A dense grid compares the painted footprint with `Track.isDrivable` outside the documented 3.5-unit vertical raster margin and checks the former mismatch at `(400,440)`. Checks require creation-only band snapping, unchanged grass snapping and no reconfiguration during updates/reopening; missing/throwing optional setters cannot stop driving. Existing allocation and deterministic replay tests still apply. Mock configuration checks do not establish display correctness; actual source-only reload acceptance is recorded separately.

The Performance unit test covers phase totals/maxima, zero-resolution samples, missing/malformed/nonfinite/negative/backwards readings, finite sum overflow, namespace purity and the 600-attempt cap including invalid samples. UI integration verifies no profiler reads by default, reachable slash commands, active-change refusal, guarded arming, three reads per sampled update with no calls after the cap, frozen stopped/reopened aggregates, fresh Start reset and stable current 8/110/13 UI counts. An identical 650-update driving tape produces identical state with profiling on/off. Reader errors and validation/arithmetic refusal stay bounded and cannot stop simulation. Mock timings prove accounting only, not actual client costs.

## Deferred manual acceptance suite
- A. Addon shows up with correct TOC and `/akart`; no Lua error.
- B. Press Start Test Drive out of combat, test W then Up, S then Down, A/D then Left/Right; car moves and rotates, stays near oval. Simultaneous W/Up is SKIPPED at the owner's request for this keyboard; offline alias coverage remains.
- C. Release keys and move chat focus: no character movement blocked after closing racing UI.
- D. ESC and close button both release game, toggling with `/akart` works; Alt-Tab and `/reload` safe.
- E. Attempt while in combat -> no keyboard capture; if combat begins mid-race no restricted API calls/taint.
- F. Run 15 min, resize UI scale, record FPS and memory. Confirm no per-tick widget creation.
- G. M0 SavedVariables: isolated sentinel across reload/logout/restart and inactive capture after load. Corrupt-save handling/migrations for actual settings/records remain later milestones.

Build 70450 has scoped [stationary profiling](evidence/2026-10-19-m0-stationary-profile.md), [road-layer startup](evidence/2026-10-19-m0-road-layer.md) and [917.598-second stopped/open idle](evidence/2026-10-19-m0-idle.md) evidence. The later [normal-scale attempt](evidence/2026-10-19-m0-scale.md) is INCOMPLETE: timed acceptance expired, original preferences returned but effective scale differed. No accepted alternative renderer or exact effective-scale restoration pass exists. Further setting changes stopped for review. The prepared read-only geometry snapshot in client-checklist section 3d is deferred under ADR 0007; it does not block local M1 work. Current dimensions cannot establish unmeasured baseline dimensions. The ten-minute drive, three-drive timing protocol, fresh unprofiled Start, supported-scale/stress matrix, sustained FPS, memory/CPU and full focus/taint/performance acceptance remain **PENDING**. No extra combat or skipped simultaneous W/Up test is requested.

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
