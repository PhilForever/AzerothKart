# Active deployment reservation — latest Claude city handoff

2026-10-22 08:24 +02:00, Europe/Oslo. User authorizes review of the latest Claude handoff, followed by push/install if good, then owner testing. From combined77581b9 on codex/ui-backend-integration, review claude/capital-cup78d97a1, preserving Claude's active checkout and authored history. Read-only reviewers cover collision and track/menu loading; integrator owns any required shared transaction regressions and final merge/test/deployment. No new gameplay scope. Existing city handoff was read completely; do not install the older two-track build as if it contained Stormwind.

Reserved: normal reviewed city merge, shared TOC/test/validator/docs conflict unions, UI.SelectTrack failure transaction if review confirms an issue, supporting regressions/count docs; own progress/handoff and coordinated source publication/verified backup/install. No other agent checkout edits, main merge/force push/release, other addon or WTF/SavedVariables writes, or client automation. Owner performs the game test after full restart.

---

# Codex handoff — reviewed UI/backend integration complete

2026-10-22 08:12+02:00, Europe/Oslo. User asked: coordinate the Menu fix with Claude, add regressions, then integrate. Source integration complete; no installation, publication or new client test.

## Branch and exact baseline

Existing checkout: `C:/Users/bakke/Downloads/Forever_Addons/AzerothKart_Codex_Project_Pack/AzerothKart-Codex-Review`.
Branch: **codex/ui-backend-integration**. Tested code baseline **0eb6c63**; the following documentation commit records this handoff (`git log -1 codex/ui-backend-integration`).

- Reservation 5b69834 from review a77fe73, before edits.
- **6cd611a**: normal two-parent merge of reviewed Claude UI **1b2d3d5** and Codex backend **192c6de**. Six shared conflicts resolved as reviewed unions, no whole runtime replacement.
- **9b22f12**: authored Claude preference fix **4ffe184**, adopted with `cherry-pick -x` retaining author/coauthor/source hash. City-only test context excluded/adapted to the reviewed two-track cycle.
- **0eb6c63**: extra regression for future-schema/unknown-field identity and stopped state/input preservation.

Claude's latest handoff on **claude/capital-cup78d97a1** explicitly supplies 4ffe184 in response to our P2 review. That commit/handoff coordinates this repair without overwriting its active Menu/city work. Its newer Circuit/Courses/CapitalCities/Stormwind geometry, generalized selection and asset pipeline remain **separate, unreviewed and unintegrated**. Do not cherry-pick its entire branch to obtain this fix. Codex did not rewrite Claude's handoff.

## Fixed and preserved

Explicit successful current-ID track/kart selections now persist. A deliberate track choice takes precedence over deferred restoration; untouched failed restores retain saved preferences. Future-version preference records are never modified. The added fixture checks exact saved-record and unknown-field identity/content, in-memory choice, and unchanged stopped vehicle/race/clock/laps/checkpoints/held keys/semantic input/inactive state.

This combines the reviewed solo main menu/track selection/six-kart garage/settings/HUD/results with the existing logged transport/session/start-clock/backend initializer. First-open restoration through guarded UI.SelectTrack is accepted. UI selectors, fixed-step input/physics/race/clock semantics stay unchanged. Rendering consumes borrowed authoritative state; it does not write it. Multiplayer preview stays Coming soon: command wiring/live race are pending, and the old lobby mapper is not the coordinated view contract.

At the preservation checkpoint: all 18 Codex-owned runtime modules match 192c6de; all 10 art files match Claude 1b2d3d5; UI differs from Claude only by the retained solo-start transport stop. All103 canonical and194 Claude tracked/untracked files, their HEAD/branch/status and unrelated refs unchanged. Existing main/origin-mainf923d15 and both published source tips preserved. Only our integration branch advances. No install or WTF/SavedVariables access.

## Validation actually executed

Pinned Lupa2.8 via canonical local dependencies; C:/Python314/python.exe:

- `menu_before_fix.py` (ignored integration evidence): original Menu injected in memory produces EXPECTED FAIL on the new current-track-save assertion in both Lua5.1/5.4. No source file swapping.
- `scripts/test_lua.py --runtime lua51 --tests menu ui`: PASS,48 files parsed.
- `scripts/test_lua.py --runtime both`: PASS,26 test modules/48 parsed files per runtime, once for this final combined code. Mock pool **65 frames/160 textures/79 font strings**; no native performance claim.
- `scripts/build_ui_art.py --check`: PASS,2,097,170bytes; SHA25643afd042ade6b2ab628b860153bcfd91417ed3948bc7526260b91caff999863d.
- `scripts/validate_project.py`: PASS,88 expected paths, synchronized 21-module TOCs, protocol/local links/ledger. `git diff --check`: PASS. Contract/art/index path/heading checks passed; the previous API heading ID is retained for historical handoff links.
- Other-worktree/ref snapshots and source/art comparison: PASS as scoped above. Verified complete all-ref recovery bundle saved before integration.

Final preservation recheck08:19+02:00 at0eb6c63: both other worktrees/all297 tracked+untracked files and unrelated refs still unchanged; only this authorized integration branch advanced.

Ignored evidence/recovery: `local-artifacts/integration-20261022/20261022-080331-b5d03e9a/` (before/after snapshots, source-preservation JSON, all-ref bundle and command logs). PhilForever repository-local commit identity verified; global identity unchanged.

## Ownership and pending work

Claude retains visual Menu/Presentation/UI-region/assets ownership. Codex owns input/physics/race/network/start semantics; shared file/contract changes require coordinated reservations. See AGENTS, API_CONTRACTS, UI_FLOW_OWNERSHIP, INTEGRATION_STATUS and the review closure. `CLAUDE.md` still imports `@AGENTS.md`. No milestone criteria were waived/completed.

Native UI templates/fonts/sounds/drag/scale/settings persistence and combined-client behavior: **NOT RUN**. Actual new-prefix traffic, coordinated race start/feel, opponent state/finish and full socket reconnect: **NOT RUN**. Existing AKT722–725 measurements remain scoped historical evidence, not playable racing. Art redistribution remains unresolved for release. New city collision/track-loading work needs separate review before integration.

Next single Codex task: implement the bounded live-race controller and paced two-peer remote snapshots consuming the existing backend GO handoff, retaining the persistent output budget/lease/lifecycle cleanup and exposing read-only remote presentation for Claude. No new download or manual test requested now. Multiplayer stays ahead of ghosts/time trials.

## Synchronization

Leave Claude's active city checkout as it is. Its fix4ffe184 is already represented here by9b22f12. A later city review/integration must account for both agents' subsequent commits; do not reset or switch its worktree to force synchronization. After its reservation is finished, the checkout's owner can create a fresh visual feature branch from this exact combined tip, with status/preservation checks. INTEGRATION_STATUS records the future commands; Codex has not run them. This branch is local and not automatically merged to main or authorized for publication/deployment by this task.
