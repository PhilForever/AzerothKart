# Stormwind handoff review and coordinated deployment

2026-10-22 08:30 +02:00, Europe/Oslo. The owner asks to read the latest Claude handoff, push and install if good, then he tests. Target reviewed: Claude `claude/capital-cup` **78d97a1**, not only the earlier UI1b2d3d5 handoff. Existing combined base77581b9; reservatione976f55; normal two-parent city merge **f9f2af0**. No other agent checkout is synchronized or reset.

## Collision and geometry review

Reviewed Circuit, CapitalCities, Courses, Physics/Track/Checkpoints interactions and test_circuit. The shipped definition has a2048-square world, six ordered gates,112-wide road,20-unit rough strip, smooth street walls and an approach branch. It has **no solids or plazas**; Mirage and Test Oval definitions/Physics remain unchanged. The factory's optional future solids do not silently add them to current city content.

Executed read-only from exact target source loaded in memory: test_circuit PASS in actual Lua5.1/5.4;29,160 authored near-boundary movements per runtime stayed drivable and never exceeded the requested distance (max4.332952794units, below checkpoint bound5); duplicated identical-input10,000-tick replays matched in each runtime. This is offline geometry evidence, not game feel or cross-client proof. Existing ×0.25 contact speed scrub remains a disclosed owner play-test item. Corrected catalog wording to describe street walls rather than nonexistent solid landmarks.

## P2 — destructive failed background load

Reproduced with actual Lua5.1 target source in a widget mock. LoadMirage, start/stop a run, then have Stormwind's SetTexture clear the texture and fail; also have the old-picture reload fail. Selection returnsfalse and retains old track/run metadata but the current picture is blank. SelectingMirage again returns true through its same-ID guard and does not repair the image.

Correction: one hidden staging background texture, pooled at creation. Validate the staging object's UV operation and load the new picture there. Only success swaps it into the front slot; failure leaves the original texture/crop/path and stopped run untouched and requires no rollback texture load. This is a bounded +1texture shared-budget change: final pool **71 frames/165 textures/80 font strings**. No race/input/physics change and no per-frame creation. Focused tests cover destructivefalse/throw and UV failures; final executed commands/results are in PROGRESS and the Codex handoff.

## Integration and provenance

Eight conflict files were resolved as per-hunk unions: preserve all session/clock/backend modules/test lists, retain the newer future-schema/stopped-state regression, adopt Claude's city screen and three-track cycle. Both TOCs load24modules. Claude's original78d97a1 and its worktree/handoff are retained; no source history rewriting. The combined checkout's Claude handoff is the actual latest authored version.

Read-only art checks: Stormwind Background is2048×2048 BGRA32,16,777,234bytes, SHA256078a7805bccdadd8b88a909d5c37b013aa51e9d0d7981134c04f7a9db12f4ebb; Preview is512×512,1,048,594bytes, SHA25663f85210560f666f2f8cb5f9a930a681a748ac90a4c4e8a7f523fa8348bedf24. Both match the handoff; source ledger lists62models/594placements/81textures. The overview was inspected. No art was regenerated and no archive was changed. Third-party redistribution remains unresolved for release review under existing ADR0009; this is the owner-authorized source push/developer install, not a tagged addon release.

Full city art regeneration from WarcraftIII archives is NOT RUN in this integration; Claude's recorded deterministic builds remain separately attributed evidence. Native2048texture loading, menus/fonts/sounds/scales/settings persistence, driving/wall feel/performance and all coordinated multiplayer checks are NOT RUN. The owner performs the client test after a full restart; no computer-use automation is required.

## Deployment procedure

Fresh other-worktree/ref hashes and a verified complete all-ref recovery bundle are in ignored `local-artifacts/deploy-20261022/20261022-082336-b891c186/`. The previous installed22-file build matches its prior verified manifest. The39-file combined source is installed with the existing backup/hash-verifying helper after tests and source commit. Main is not merged or pushed; publish the reviewed combined feature branch using a normal non-force push and verify its remote hash. Never copy Claude's standalone branch over the shared client.

Use cached PowerShell7 for the installer. Its WhatIf preflight passes; WindowsPowerShell5.1 WhatIf fails before writes because Get-FileHash inherits WhatIf. No helper change is included in this feature integration. Actual installation evidence/status belongs in PROGRESS; do not infer successful deployment from this procedure or a preflight.

## Result

P2 resolved by **e748b60**, with focused and full integration regressions passing. All27test modules/52parsed files pass in both Lua versions; structural validator96paths/24-module TOCs passes. Coordinated39-file installation and22-file backup independently hash-verified; normal feature-branch publication succeeded. Exact deployment/commit/receipt links are in PROGRESS and the Codex handoff. Native client checks remain NOT RUN for the owner.
