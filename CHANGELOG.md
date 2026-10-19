# Changelog

## Unreleased — grass slowdown and perimeter walls (2026-10-19)
- Physics version 4 separates the road mask from traversable grass and solid perimeter bounds. Grass gradually reduces excess speed toward 70 forward/30 reverse and clears drift, boost and slip; road re-entry restores normal handling.
- Clamp attempted movement at an 18-unit canvas inset, preserving tangent motion and scrubbing speed once per contact step, including corners. Add four pooled perimeter textures and reuse the drift HUD for Road/Grass/Wall feedback; explicit counts are now 6 frames/103 textures/4 font strings.
- Focused coverage accompanies surface/collision and UI changes; exact executed results and install status are recorded in PROGRESS. Client reload, layout and handling are NOT RUN. Broader checks remain deferred under ADR 0007; M0/M1 acceptance remains open.

## Unreleased — local drift charge and boost (2026-10-19)
- Physics version 3 adds Space-held drift with bounded signed slip, two fixed-tick charge tiers and a release boost. Brake, steering loss/opposition, low speed and collision cancel the charge; brake/collision cancel an active boost.
- Add a separate pooled drift HUD and phase-cached kart colors for charge, ready tiers and boost. The window is 856×670; the explicit budget is now 6 frames/99 textures/4 font strings. Stop retains `Last drive` feedback; a fresh Start resets it.
- Focused Lua 5.1 physics/input/UI and separate drift checks passed. Installed Input/Physics/UI with a verified prior-addon backup and ten matching source hashes; no client reload or handling check performed.
- Adopt the owner's build-first priority: focused checks for changed mechanics, with long client/scale/profile matrices deferred. M0 stays open; human drift handling, new-layout client verification and this slice's full dual-runtime suite are NOT RUN. Exact commands/results are in PROGRESS.

## Unreleased — explicit road draw order and seam fix (2026-10-19)
- Put the canvas grass below the outer road bands and disable sharpening/pixel snapping only for the 96 bands during creation. Geometry, physics, input and the 6/99/3 object budget are unchanged.
- Isolated live checks showed grass occlusion; a clean reload then verified the permanent fix, all 96 band settings and unchanged grass snapping at effective scale 0.72452831268311. Other-scale and sustained-performance acceptance remain pending.
- Lua 5.1/5.4 regression coverage includes draw priority, creation-only settings, missing/throwing optional APIs and no reconfiguration on update/reopen. Installed UI.lua with verified prior backup and ten matching source hashes.

## Unreleased — stationary client evidence and renderer review (2026-10-19)
- Recorded 600 valid stationary profiler samples on build 70450: scoped total average 0.0264 ms, maximum 0.2111 ms, including probe overhead; stopped/reopened/disarmed results retained. This is partial M0 evidence, not sustained driving or exclusive CPU cost.
- Observed road-band seams. Both creation-time snapping experiments hid the road after reload despite passing mock tests; removed the experiments and restored/verified the prior source and visible road. Rendering API behavior is flagged for review; no snapping change is retained.

## Unreleased — optional bounded performance probe (2026-10-19)
- `/akart perf on` arms up to 600 active updates on the next Start; `/akart perf` prints simulation/render-HUD averages and maxima in scoped elapsed milliseconds; `/akart perf off` disables collection. Default off, aggregate-only, no extra UI objects or per-frame chat.
- Missing/invalid/reset/erroring clock readings consume the cap without changing driving. Never reset the shared profiler timer; output includes probe overhead and is not exclusive CPU/GPU attribution.
- Pure aggregation and UI integration checks pass in Lua 5.1/5.4; synchronized TOCs load Performance before UI. Installed with verified backup/ten hashes; the later stationary client result is recorded above.

## Unreleased — align the primitive road with collision (2026-10-19)
- Draw the outer road and inner island from the analytical Track bounds, replacing the mismatched centerline tiles. Physics and steering are unchanged.
- Reuse the 96-road-texture budget with static ellipse bands; regression checks compare the painted footprint with collision geometry and retain allocation/determinism coverage.

## Unreleased — stopped-window combat closure (2026-10-19)
- Handle combat onset even after a test drive has stopped; hide the open window without changing its completed timing/result or announcing another interruption.
- Lua 5.1/5.4 regressions cover pre-Start/stopped/interrupted windows, duplicate events, preserved samples and no automatic resume. Installed with a verified backup and loaded; actual combat verification remains deferred.
- Record two human near-minute driving samples with matching stopped HUD, no dropped simulation time and stable explicit UI counts; full M0 acceptance remains open.

## Unreleased — retained interruption note (2026-10-19)
- Keep the combat interruption note through repeated closes/reopens and rejected Start attempts; display the refusal alongside the note.
- Regression coverage checks frozen results/timing, no duplicate notification or resume, and clean reset on a successful fresh Start. Source-only; extended client check remains pending.

## Unreleased — repeatable developer installs (2026-10-19)
- Local install helper copies files directly into the addon target, requires explicit overwrite, and supports `-WhatIf` previews.
- Verifies prior-file backups and installed SHA-256 values, preserves unknown extra files, and records copy/verification failures without automatic rollback.
- Workspace fixture suite covers install, cancellation and failure paths; no installed addon changed by this tooling work.

## Unreleased — M0 timing sample evidence (2026-10-19)
- Probe reports cumulative active frame time, executed simulation time and callback cadence; stopped samples retain their timing remainder.
- Start and Stop immediately refresh the HUD, fixing the observed stale stopped tick display.
- Offline 60-second schedule, hitch accounting and frozen-sample regressions; manual client samples remain pending. Source-only update, not installed or released.

## Unreleased — M0 probe hardening (2026-10-18)
- Combat now closes the window and records one retained interruption result/note; future races will freeze actual standings when implemented.
- Local developer install verified by SHA-256; live build/interface/Camelot discovery, basic rendering and idle release checks observed. Full manual acceptance remains pending.
- Corrected left/right steering; physics compatibility version 2.
- Pure input sampling and bounded fixed-step clock with measured dropped time.
- Focus/lifecycle stops, guarded combat propagation and explicit probe diagnostics.
- Lua 5.1/5.4 tests, deterministic replay, analytical handling and mocked UI lifecycle checks.
- Installed-client probe matrix and unmeasured network experiment ledger; M0 client acceptance remains pending.

## 0.0.1 — project starter (2026-10-18)
- Technical plan, agent prompts and acceptance-gated roadmap.
- Small local top-down driving probe; pending actual Lua + WoW validation.
- Offline verification scripts and manual test checklists.
- No public multiplayer or finished racing claimed.
