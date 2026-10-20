# Integration preservation follow-up (2026-10-21 00:22 CEST)

Claude installed effects `c6e1b5e` at22:18:43UTC after our prior-build hash check and before the00:19 CEST menu install. Our installer preserved the two extra atlases and full prior files, but replaced its UI/Presentation/README. Stop deploying standalone branches: this is a shared-target overlap, not an API failure. Reviewed `7fcdd89..c6e1b5e` with no authoritative-state/input/lifecycle changes; preserve the already-installed effects by merging Claude handoff `1004e73` into this same feature branch before the final serialized installation. Scope now also includes review/merge reconciliation of Claude's immutable runtime, additive Presentation effect contract and shared counts/tests. Do not modify either other worktree, raw art or gameplay. Combined expected pool10/151/13; first actual connection test remains NOT RUN.

# Codex active task — dismiss results and explain connection testing

Reserved 2026-10-21, Europe/Oslo. Base `bdb44d1`; branch `codex/results-dismiss` in the existing Codex Review worktree. Owner explicitly assigned the results-panel close control and plain connection-test instructions. No new networking engine or experiment run.

Scope also includes the Codex-owned TransportProbe explicit chat-help output and focused no-side-effect adapter test; no send/accounting behavior changes.

Scope: `UI.lua` summary presentation/dismiss callback, successful Start/SelectTrack dismissal reset; shared `test_ui.lua` dismissal behavior/count assertions; API/pool documentation, short network quick-start, README links, PROGRESS and this handoff. Claude's active reservation around VFX pool after the kart, sprite loading/layout/rendering, Presentation and assets remains untouched. The new control is in the separate results-panel construction block. No edits to Claude's worktree or named handoff.

Previous completed integration/evidence follows for context.

# Codex handoff — explicit run exits and reviewed Claude integration

Prepared 2026-10-20 18:22 UTC. M1 input/menu correction and M2 integration checkpoint; M0/M1/M3 and all actual transport gates remain open.

## Branch and scope

- Canonical remote: `https://github.com/PhilForever/AzerothKart.git`.
- Worktree: existing `../AzerothKart-Codex-Review`, feature `codex/menu-integration`.
- Parents: Codex `de7a63e9f77b6df43b6ba42a4f8513977ed9bd8f` and reviewed Claude `812d132` (runtime `cf71394`). Implementation result: `7fcdd8919831c6e453bb81a21debc8a190f8b9df`; a later documentation commit records live evidence.
- Owner now explicitly authorized this reviewed merge and menu fix. Scope: UI/Core capture and Stop callbacks/shared tests, merge conflict reconciliation, implemented contracts and policy/handoff docs. No new gameplay/network architecture.
- Main/local origin/main remain `f923d15`; canonical checkout remains `5570968`. Claude worktree/branch and its untracked `Claude outputs/`, canonical empty untracked handoff placeholders and unrelated content are preserved. No reset/rebase/prune/GC/push/release.
- Current shared installation before this checkpoint is Claude `cf71394`, manifest `../AzerothKart-Claude/local-artifacts/installs/20261020-173759/install.json`. Combined deployment must preserve the same trike/background bytes and record its own backup/hash manifest.

## Implemented and reviewed

Incidental mouse clicks/unassigned keys keep drive/capture/held input active. Stop's mouse-down no longer ends/disables it before OnClick. Stop/Escape ends/fixes partial progress; Close also hides; Enter/numpad Enter deliberately opens chat. Actual text focus/available appfocus/hide/world/logout/combat guards remain. No new pause/resume state; Start/Restart is a fresh run. Result text offers concrete next actions; active track changes stay refused. Global mouse subscription and capture dependency removed. [ADR 0011](../adr/0011-explicit-drive-exits.md) records the owner direction.

Claude scenery, attached shadows and 64-heading Goblin Mortar Trike are reviewed and integrated. Presentation sheet fields/helpers/anchoring and guarded crop behavior are implemented contracts in [API_CONTRACTS](../API_CONTRACTS.md), distinct from centered/rotated single images. Physics v7 / 15 fields, Oval v2 solids only, Mirage geometry, race rules/timing and bounded transport are retained. Explicit pooled UI count 9/113/13. Read Claude's preserved handoff and per-asset provenance; its historical 9/111/13 counts describe that earlier source.

## Tests actually executed

- Windows Python 3.14 + pinned Lupa 2.8 from canonical ignored dependency directory; `scripts/test_lua.py --runtime lua51 --tests input presentation ui network_probe transport_probe`: final PASS: 34 parsed / five modules. First attempt uncovered a hidden test window after combat; corrected fixture to show it before positive Start assertion.
- `scripts/test_lua.py --runtime lua51`: PASS: all 19 modules at this integration checkpoint, including 10k-tick deterministic replay, obstacle/race/input/visual/probe checks.
- `scripts/validate_project.py`: STATIC PASS: 56 paths before final docs; no Lua executed by it.
- `tests/test_install_local.ps1`: PASS: 18 / SKIP: 3 (junction creation denied), workspace fixtures retained.
- Independent read-only Claude review found no blocking source issue; sheet/background hashes match handoff. Asset generators and live installation/menu check recorded below when executed.
- Lua5.4/nativeLua, broad performance, held-key Alt-Tab, all two-client measurements/reconnect: NOT RUN. Old policy's click/Alt observations do not validate revised behavior.

## Limits and next task

Build 70450 lacks observed application-focus getters, so held-input Alt-Tab stays pending after removing generic Alt/unknown-key stops. Trike overhang / 4 MiB raw sheet and runtime load/FPS cost remain explicit. Imported WC3 author terms/redistribution remain release-review debt, not an asserted clearance.

Owner confirmed no second client is available in this run. No probe is armed/sends issued, no capacity inferred, ledger remains header-only. **Next single task:** first consenting two-client 0.5 DATA/s, 16-byte, 120-second WHISPER window using [the checklist](../../tests/MANUAL_NETWORK_CHECKLIST.md), fresh ID / exact peer names, both reports and all four evidence maps. Keep multiplayer above ghosts; don't choose broad replication or escalate rate before that evidence.

Claude should continue visuals from its own branch; review integration diffs before synchronizing. Do not overwrite this combined installation with the older standalone visual runtime. No request for another combat matrix.


## Asset reproducibility checks (18:21:46–18:23:52 UTC)

All check-only commands passed with Windows Python3.14: `scripts/build_kart_sprites.py --check`, `scripts/build_mirage_background.py --check`, and `scripts/build_wc3_kart.py --source ../AzerothKart-Claude/local-artifacts/third-party/goblin-mortar-trike --check`. Drag car SHA `cc7c1c69…126a`, scenery `cd5aecb9…c567e`, trike `a723b067…3208`. Background's first invocation lacked the pinned Lupa path; retry with canonical PYTHONPATH passed. No generated file changed. Trike private sources remain ignored in Claude's worktree; no new download or source redistribution.


## Deployment and live evidence completed

Installed `7fcdd89` at 18:25 UTC with a verified full prior backup and 20/20 hashes; independent resumed comparison also matched 20/20. Manifest under ignored `local-artifacts/install-backups/20261020-202526-131-567cfd9612074e2d957df74433a02f53/install.json`. No other addons or WTF data were changed by deployment.

[Exact live menu evidence](../evidence/2026-10-20-menu-integration-client.md): reload/load, Oval/trike, Mirage switch, stationary M/left/right clicks retaining the run, actual Stop reason/frozen sample, fresh Restart, explicit Escape and Close observed. Counts 9/113/13, no registration failures; first Stop at 2715 ticks / 42.25 s race time. Escape also opens the normal WoW menu on release; a second Escape dismissed it. No held-driving-input, motion/edge/handling/performance acceptance inferred.

No-send API types/five selected constants matched `function function 0 1 0 3 8`. Actual registration/send results and delivery remain untested. At 21:59 UTC, after work resumed, `/akart net report` confirmed `Idle: no experiment run`. No experiment or capacity result; second client unavailable. Final observed addon hidden, chat closed.

On resumed inspection Claude had adopted `7fcdd89` and advanced to docs-only `f675610`, reserving effects/vehicles. Read its latest handoff before the next shared edit/deployment. This documentation checkpoint does not merge that reservation or modify its checkout. No continuous work is claimed across the interruption.

**Next live task:** first consenting two-client 0.5 DATA/s, 16-byte, 120-second WHISPER window with complete reports/four maps. **If still one client:** build the offline reconciliation helper against existing report/evidence formats; keep actual transport pending and do not begin broad replication or ghosts.
