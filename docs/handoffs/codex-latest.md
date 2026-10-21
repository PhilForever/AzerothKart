# Codex handoff — combined review requests preference fix

2026-10-21 14:50+02:00, Europe/Oslo. `codex/combined-review` from published `192c6de`; result is this documentation commit (`git log -1 codex/combined-review`). Reviewed Claude `1b2d3d5`, common baseline `83c611c`. [Full review](../reviews/2026-10-21-ui-backend-integration.md); exact runtime handoff remains [START_CLOCK](../START_CLOCK.md), source2232f82. Prior implementation handoffs remain in Git.

## Outcome

**Changes requested: one P2 Menu preference bug.** Explicitly choosing the currently active fallback track/kart is ignored by persistence; deferred saved-track restoration can replace the player's deliberate choice. Reproduced all three track/kart paths in actualLua5.1 and5.4 against Claude source and the trial combined build. Fix Menu's explicit successful-choice bookkeeping, preserve existing UI transactions/future-version protection and retain a failed preference only until the player chooses otherwise. Add focused regressions. No source fix was silently applied to Claude's branch.

Other reviewed boundaries are compatible: physics/input/race/checkpoints/timing/transport/Core unchanged, only additive visual hooks/settings in UI, explicit Start discipline, sensible partial-creation fallback, results dismissal and Alt+Z behavior. First-open saved-track restoration remains approved subject to choice precedence. Multiplayer remains coming soon; the legacy lobby mapper needs the coordinated view/actions before it can be wired. No native-client behavior is inferred from previews/tests.

## Executed combined validation

Independent scratch Git repository, no-commit trial192c6de+1b2d3d5, six reported shared list/docs conflicts union-resolved. All21TOCmodules retained. Codex-owned runtime modules byte-identical to192c6de; Menu/Presentation/assets matchClaude; UI differs fromClaude only by retained solo-start SessionTransport.Stop line.

- `C:/Python314/python.exe scripts/test_lua.py --runtime both` PASS:48files parsed/26existingtestmodules perruntime; UI65/160/79.
- `scripts/validate_project.py` PASS88paths/TOC/links/ledger. `scripts/build_ui_art.py --check` PASS2097170bytes/hash43afd042…863d. Scratch staged whitespace PASS.
- New targeted preference repro: **REPRODUCED** three wrong outcomes in both runtimes on both configurations; existing-suite pass does not cover those paths.
- Scratch retained under ignored `local-artifacts/review-20261021/combined-3de95b9c090c40a99eb83195c0757150`; staged/uncommitted tree542e8ecd2eb8ab7a6d63275659f85e8a93986323. Logs/summary/resolutionpatch in itslocal-artifacts. Reproducer beside it `claude-menu-preferences-repro.py` accepts an optional source-root argument. No native tests/install or new broad matrix beyond this integration checkpoint.

## Preservation and next task

Only review/PROGRESS/INTEGRATION_STATUS/this handoff changed in the own review branch. Both reviewed refs and mainf923d15 remain unchanged. Canonical files are unchanged; Claude independently started claude/capital-cup50d8bf6 during review (only its handoff changed at14:47). Codex did not modify that worktree or its untracked outputs; no merge/reset/force/GC/prune/install/client input/push performed. Previous user-authorized two-branch publication is verified in the ignored14:07receipt and now recorded in PROGRESS. Shared integration remains separate; scratch source is not installed.

**Next single task:** correct Menu's explicit track/kart choice persistence and add the three regressions before reviewed integration. Claude now actively reserves Menu for city-track work, so coordinate that correction against its latest branch; do not replace either runtime wholesale or merge the known bug into main. Then return to the live-race controller/paced remote snapshots. No roadmap acceptance changed and no manual test/download requested by this review.
