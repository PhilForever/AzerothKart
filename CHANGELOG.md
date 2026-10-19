# Changelog

## Unreleased — closer Mirage follow camera (2026-10-20)
- Replace Mirage's distant whole-map presentation with a north-up follow camera at scale 1.5. A cropped background fills the existing 800×480 canvas, with 60 world units of heading look-ahead and a view clamped to map bounds. The placeholder kart grows from about 8×14.5 to 25.5×46.5 canvas units; the road grows from 52.5 to 168 wide.
- Keep art, kart, gates and walls in one uniform transform, clipping pooled gate/wall strips to the visible canvas. The camera follows the interpolated pose and freezes at the exact stopped pose; no simulation, geometry or Physics v6 change is introduced.
- Preserve Test Oval's fixed overview and the existing 9 frames/111 textures/13 font strings. Painterly scenery and the first drag-car sprite remain subsequent work.
- Record the owner's screenshot as evidence of the earlier opaque Mirage TGA loading and whole-map orientation. A separate stopped build-70450 check confirmed the close crop, larger kart, Start alignment and West-strip clipping, with 9/111/13 counts and zero drive ticks. Camera motion/edges, handling and sustained performance remain NOT RUN; exact focused checks and installation belong in PROGRESS.

## Unreleased — gentler drift and retained steering corrections (2026-10-20)
- Tune Physics v6 for the owner's Test Oval feedback: drift yaw is 0.75 of normal yaw instead of 1.15; charge tiers take 30/60 valid ticks (0.5/1 second), while ordinary steering and boost duration stay unchanged.
- Hold Space through up to twelve steering-correction ticks (0.2 seconds) to retain charge without adding more. Matching steering resumes charging in either direction; the thirteenth unqualified tick clears it. A valid road/speed release can spend a retained tier during that pause; brake, low speed, rough ground and walls still cancel immediately.
- Add a correction-pause text cue using the existing meter/HUD. The deterministic state adds `driftGraceTicks`; no input binding, UI allocation, track geometry, countdown or race-result change is introduced.
- Focused regression coverage accompanies the change; exact executed results and installation belong in PROGRESS. Version-6 client feel remains NOT RUN and M1 acceptance stays open.

## Unreleased — selectable playable Mirage blockout (2026-10-20)
- Add one original 1024×1024 salt-flat TGA sampled from actual Lua road geometry, plus a deterministic exporter and format/alignment check. No third-party imagery or model is imported.
- Add a stopped-state Track button for Test Oval/Mirage Raceway. Load the background once on deliberate selection, retain the working oval and stopped result if loading fails, and reuse all textures on later switches. A click releasing driving controls cannot also change the track.
- Project background, kart, gates and perimeter dimensions uniformly into the existing canvas. Mirage labels rough ground as salt; physics v5, countdown, drift and three-lap results are preserved. Successful map changes start a fresh ready state; selection is not persisted.
- Explicit UI allocations become 9 frames/111 textures/13 font strings. Focused Lua 5.1 mapping/lifecycle checks and exporter checks passed; actual client texture appearance/handling remain NOT RUN. M0/M1/M3 acceptance remains open.

## Unreleased — Mirage geometry blockout and layout guide (2026-10-20)
- Add a pure MirageRaceway factory with explicit crossing dependency, 1024-square bounds, a closed 16-vertex centerline and 112-wide capsule-union road, perimeter walls, spawn and four directional gates. Rough salt reuses grass behavior; physics stays v5.
- Add uniform Presentation viewport projection/unprojection. The 1024-square world fits 800×480 at scale 0.46875, offset (160,0); future rendering must scale both positions and dimensions.
- Generate JSON/SVG authoring guides from the actual Lua factory and viewport helpers, with the same unsmoothed round road stroke and one Y inversion. This is a blockout/guide, not playable Mirage or a loaded background.
- Bundle the factory after Track (12 Lua modules/15 addon source files); UI remains Test Oval with unchanged 8/110/13 allocations, countdown and finish flow. No selector, TGA, new vehicle art or client API is added. Focused geometry/presentation/UI checks accompany the slice; exact executed results and installation belong in PROGRESS. Client custom-texture/viewport checks remain NOT RUN, with M0/M1/M3 acceptance open.

## Unreleased — Mirage Raceway asset research and art direction (2026-10-20)
- Set Mirage Raceway on the dry Shimmering Flats as the first production-map target, replacing the proposed Tinker Speedway, with recognizable fantasy siege/steam tanks, trike, aircraft, gryphon rider and Mirage drag cars.
- Record concrete WC3Vault candidates, author/permission gaps, OpenRealm/viewer tooling and explicitly licensed fallback art. No third-party archives were imported; tool licenses are distinguished from model/texture rights.
- Add a generated concept board, exact prompts and PNG hash/provenance manifest outside the addon. Document precomposed track layers, separate simulation geometry, bounded sprite pools, camera/facing requirements and export/viewport checks still pending.
- Planning/artifacts only: Test Oval runtime, installed files and milestone acceptance are unchanged. No runtime TGA, asset loader, geometry migration or new selectable roster is claimed.

## Unreleased — best completed lap within a run (2026-10-20)
- Track the fastest accepted completed lap and its lap number in pure Laps. Fields start empty; strictly shorter integer durations replace the best, while ties retain the earliest lap. Incomplete/current laps never become the best.
- Append best time/lap number to the existing lap HUD and all terminal summaries. Retain it through Stop/combat/reopen/rejected Start; successful fresh Start/Restart and GO reset it. This is in-memory per run, with no saved personal record, schema change or migration.
- Grow the existing summary to 380×190 for its third text line. Counts remain 8/110/13 in the same 856×762 window, with unchanged physics v5, countdown and three-lap finish; no new UI objects, APIs, settings or networking.
- Focused Laps/Race/UI coverage accompanies the slice; exact executed results belong in PROGRESS. Current client layout/handling remains NOT RUN, and M0/M1/M3 acceptance stays open.

## Unreleased — fixed-tick start countdown (2026-10-20)
- Start each three-lap solo run with 180 fixed ticks of 3–2–1 and a GO cue. The kart stays at spawn with neutral physics input while actual held controls are sampled; GO resets the Race/Laps timing origin, and driving begins on the following tick.
- Race/lap time excludes countdown, dropped time and stopped time; physics/loop/probe ticks include countdown. Dropped hitch ticks can extend countdown wall time without skipping it. GO remains visible for the first 60 racing ticks.
- Stop/focus loss/combat cancels countdown with zero race elapsed time and retains the frozen result; a deliberate successful Restart begins a fresh countdown. One pooled center font string brings explicit allocations to 8/110/13 in the unchanged 856×762 window; physics stays v5 and exact three-lap finishing is unchanged.
- Focused Race/UI coverage accompanies the slice; exact executed results belong in PROGRESS. Countdown appearance/handling and other client checks remain NOT RUN; M0/M1/M3 acceptance stays open. No persistence, best record, ghosts or networking is added.

## Unreleased — three-lap solo finish (2026-10-20)
- Add a pure Race wrapper around Laps with running, finished, stopped and interrupted outcomes, fixed three-lap completion and integer total ticks. Terminal state is retained unchanged; no repeated finish or post-finish simulation is accepted.
- Stop catch-up after the counted finish step, account for unexecuted whole ticks as dropped time and retain the fractional clock remainder. An ordinary early finish does not manufacture a hitch frame.
- Add a pooled result summary and deliberate Restart flow. Successful completion shows total/last-lap times; early Stop or combat retains actual partial progress. Stop/reopen preserves the result, while a successful fresh Start clears it. Current explicit allocations are 8 frames/110 textures/12 font strings in the same 856×762 window; physics remains v5.
- No countdown, persistence, best record, ghosts, remote standings or multiplayer is added. Focused Race/Loop/UI coverage accompanies the slice; exact executed results and installation status belong in PROGRESS. Client finish/restart driving and appearance remain NOT RUN; M0/M1/M3 acceptance stays open.

## Unreleased — repeatable practice laps (2026-10-19)
- Add a pure Laps module around ordered checkpoints. Each accepted North → West → South → Start circuit increments completed laps once and rearms the next circuit at the finish tick. Duplicate, older and gapped tick reports cannot award or advance time; consecutive malformed or oversized movements advance practice time without a gate award.
- Show completed laps, current lap time and the last completed time from integer 60 Hz simulation ticks. The first lap includes acceleration from Start Test Drive; Stop, combat interruption and normal reopen freeze the sample, while a fresh Start resets it. One pooled lap font string brings explicit objects to 6 frames/110 textures/9 font strings in an 856×762 window; physics remains version 5.
- No countdown, fixed race length, winner, best record, persistence or multiplayer is added. These local consistency checks do not prove competitive route validity. Focused checkpoint/lap/UI coverage accompanies the slice; exact executed results and installation status belong in PROGRESS. Client lap driving/layout and broader checks remain NOT RUN unless recorded there.

## Unreleased — ordered directional checkpoints (2026-10-19)
- Add four finite directional gates on the test oval and a pure fixed-tick checkpoint module. Only the next gate can advance; backwards crossings, departures from the gate line, stale/duplicate ticks, missing steps and oversized movements do not award progress. A completed 4/4 sequence stays terminal until a fresh Start.
- Integrate actual simulation positions after physics, with pooled next/passed gate strips and a named checkpoint HUD. Correct the right-hand start stripe to cross the road horizontally. Stop/reopen freezes progress; Start resets it. Explicit objects are now 6 frames/110 textures/8 font strings in an 856×734 window; physics stays version 5.
- This is solo checkpoint groundwork, with no lap count, timer, win result or security guarantee. Focused track/checkpoint/UI coverage accompanies it; exact executed results and installation status belong in PROGRESS. Client appearance and driving remain NOT RUN; broader checks stay deferred under ADR 0007.

## Unreleased — progressive keyboard steering (2026-10-19)
- Physics version 5 adds bounded steering buildup, faster centering on release and a center-first direction reversal. Both directions cancel immediately; reverse yaw still flips, wall contact clears steering and grass preserves it for recovery.
- Keep drift cancellation tied to raw turn input; a new drift waits until progressive steering agrees with that turn. Input capture, bindings, meter/interpolation and the 6/107/7 UI budget are unchanged.
- Focused steering, drift, surface and UI coverage accompanies this slice; exact executed results and installation status belong in PROGRESS. Client handling is NOT RUN; broader checks remain deferred under ADR 0007.

## Unreleased — drift charge and boost meter (2026-10-19)
- Add a 300×12 pooled meter with Tier 1/Tier 2 markers, named charge/ready phases and remaining-boost feedback on one shared 0.8-second scale. Pure Presentation mapping reads actual charge/boost ticks without changing physics version 4.
- Cache phase and fill setters; empty fill is hidden, Stop freezes the last drive and Start clears it. Four textures and three font strings bring explicit allocations to 6 frames/107 textures/7 font strings in an 856×706 window.
- Focused presentation/UI coverage accompanies this slice; exact executed results and install status belong in PROGRESS. Client reload and meter appearance are NOT RUN; broader checks remain deferred under ADR 0007.

## Unreleased — interpolated kart presentation (2026-10-19)
- Blend previous/current simulation positions and shortest-arc heading using the fixed-step clock remainder, including render frames with no simulation step. A pure Presentation module returns scalar coordinates; displayed poses never feed back into physics, which remains version 4.
- Start/Create and Stop show the exact current pose; stopped updates and reopening retain it. Active interpolation adds at most one fixed step of visual delay. The 6 frames/103 textures/4 font strings budget is unchanged.
- Focused presentation/UI coverage accompanies this slice; exact executed results and installation status belong in PROGRESS. In-game appearance and handling are NOT RUN; broader checks remain deferred under ADR 0007.

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
