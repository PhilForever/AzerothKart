# Claude UI and Codex backend integration review

2026-10-21. Reviewed published Claude `1b2d3d5` and Codex `192c6de`, common base `83c611c`. **Verdict: changes requested for one P2 preference bug.** No source branch was merged or changed; the combined build exists only in an ignored scratch repository.

## P2 — Explicit fallback selections are not remembered

Claude `addon/AzerothKart/Menu.lua:435` and `:578` treat successful selection as a notification-only operation. Selecting an already-current ID returns early from UI.SelectTrack/SelectKart, so no change notification saves that explicit choice. Menu's inferred-change bookkeeping at `:940–949` also ignores initial/deferred baselines. Deferred track restoration at `:1012–1016` can then override the player's choice.

Reproduced on both Claude's exact source and the trial combined build, in real Lua 5.1 and 5.4 using the existing widget mock:

1. Saved Mirage; first open is in combat and defers restoration; leave combat and deliberately select current Test Oval. Close/reopen restores Mirage over that explicit choice.
2. Saved Mirage; initial background loading fails, leaving Test Oval. Deliberately click Test Oval: `preferences.track` incorrectly remains Mirage.
3. Saved Gyrocopter; initial sprite loading fails, leaving the Mortar Trike. Deliberately select that current trike: `preferences.kart` incorrectly remains Gyrocopter.

Required correction belongs in **Menu's explicit successful-choice bookkeeping**: persist the chosen ID even when the underlying current ID does not change, and let a deliberate track choice supersede deferred restoration. Keep UI's guarded selection transactions and failed-restore retention unchanged. Preserve future preference-version protection. Add regressions for these three paths; an untouched failed restore must still retain its original preference until the player chooses otherwise.

The isolated reproducer asserts the observed wrong outcomes, so its result is **REPRODUCED**, not a passing behavior test. File: ignored `local-artifacts/review-20261021/claude-menu-preferences-repro.py`; it accepts an optional source-root argument. No runtime repair was applied during review.

## Other conclusions

- Claude's handoff accurately describes its implemented menu, visual hooks, explicit Start discipline, pooled resources, future-version/unknown-field preservation and pending client checks. Its existing saved-choice coverage misses the regression above.
- Codex accepts first-open saved-track restoration through the existing inactive/out-of-combat transaction, subject to explicit-choice precedence being fixed. No automatic race start was found.
- Physics/input/race/checkpoint/timing/transport/Core ownership is preserved. The trial retains all Codex-owned modules byte-for-byte from `192c6de`. Menu/Presentation/assets match Claude exactly; UI differs from Claude only by Codex's solo-start transport cancellation line.
- Keep multiplayer coming soon. Current Menu's legacy lobby mapper does not handle the coordinated adapter's newer capabilities/clock phases; Claude already identifies this as future work. No current menu/network binding or live-race authority is inferred.
- Preview layout was inspected. Its stand-in fonts/art are not native-client evidence. Dialog templates, sounds, dragging/scales, persistence and game behavior remain client checks.

## Trial merge and executed checks

An independent local scratch Git repository imported a verified two-tip bundle. A no-commit test merge reproduced exactly Claude's six reported conflict files: CHANGELOG, API_CONTRACTS, ARCHITECTURE, validator, test runner and UI-test loader. Unions retain both sides, including Menu after UI and all clock/backend modules. Both TOCs load 21 modules. No whole runtime file was replaced.

- `C:/Python314/python.exe scripts/test_lua.py --runtime both` — PASS: 48 Lua files parsed and all 26 existing test modules executed in each runtime; mocked UI pool 65 frames/160 textures/79 fonts.
- `scripts/validate_project.py` — PASS: 88 expected paths, TOC order, links and ledger on Windows.
- `scripts/build_ui_art.py --check` — PASS: exact 2,097,170-byte preview atlas, SHA-256 `43afd042ade6b2ab628b860153bcfd91417ed3948bc7526260b91caff999863d`.
- Scratch staged whitespace check — PASS. Targeted preference reproduction — all three wrong outcomes reproduced in both runtimes on both source configurations.

Scratch directory: ignored `local-artifacts/review-20261021/combined-3de95b9c090c40a99eb83195c0757150`. Uncommitted trial tree: `542e8ecd2eb8ab7a6d63275659f85e8a93986323`. Its local-artifacts folder retains the commands/logs/summary and exact conflict-resolution patch. Initial local-clone attempts hit the Windows shell sandbox; the successful bundle-import route required no network or source mutation.

No actual-client tests, installation, main update, publication, migration or new gameplay occurred in this review. The two reviewed source tips are unchanged. During final preservation checks, Claude independently advanced its worktree to `claude/capital-cup` at `50d8bf6` (14:47 local): only its own handoff changed at that checkpoint. Its active reservation now includes Menu and city-track presentation; that future work is outside this review. Codex did not modify it. Next: coordinate Menu's explicit-choice fix/regressions with that reservation, then review integration; this review does not approve merging the current preference bug into main.
