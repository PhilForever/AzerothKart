# Codex handoff — latest Claude source pushed and installed

2026-10-22 08:37 +02:00, Europe/Oslo. Owner authorized latest Claude handoff review, push/install if good, then his client test. **Completed.** No main merge, release or client automation.

## Exact source

Checkout `C:/Users/bakke/Downloads/Forever_Addons/AzerothKart_Codex_Project_Pack/AzerothKart-Codex-Review`, branch **codex/ui-backend-integration**. Tested/installed code **e748b60c9113a09d6455fb5a39788aa23f3d7084**; following documentation commit records this deployment on the same branch (`git log -1 codex/ui-backend-integration`). Normal non-force publication of codee748b60 succeeded; final same-branch docs tip/remote verification is in the ignored receipt.

UI/backend merge6cd611a, Claude preference fix9b22f12 and regression0eb6c63 remain. Reservatione976f55 preceded city work. **f9f2af0** is the normal two-parent merge of current Claude **78d97a1** with combined77581b9/history; per-hunk unions keep all backend modules/loaders/tests and future-schema/state assertions. **e748b60** is the reviewed track-background transaction repair and regressions. Both TOCs load24modules.

Read Claude's complete current handoff (not just UI1b2d3d5): its city rework/reservation/contract proposals/tests/pendingledger and installed-build note. Combined source now includes that authored handoff unchanged, Stormwind city geometry and its scenery/pipeline. Claude's checkout stays on78d97a1 with all untracked files preserved; no switch/reset or competing edit there. Canonical checkout remains5570968. Main/origin-main remainf923d15; original Claude/backend refs retained.

## Reviewed fix and boundaries

Collision review of Circuit/CapitalCities/Courses with Physics/Track/Checkpoints found no blocker for currentStormwind (sixgates, no solids/plazas). Existing contact speed scrub needs owner feel feedback. UI review reproduced destructive failed-image plus failed-rollback loading over a retained Mirage run. Fixed by one hidden pooled staging texture, validated/cropped/loaded before a success-only front swap. A failure cannot alter oldvisibleimage/UV/path or state/race/clock/input/results; no rollback load is required. Texture count +1: **71frames/165textures/80fonts**. Both scenery images can stay resident; native memory/cost not measured. No tick/frame allocations or background loads.

All18 old Codex runtime modules match77581b9; all12 runtime art files matchClaude78d97a1. No physics/handling/network behavior changes, no multiplayer binding. Three solo tracks/six cosmetic karts; Coming soon cities remain disabled. Stormwind is not added to SessionTransport's supported compatibility list. Authoritative geometry and runtime collision invariants remain Codex-owned/shared; Claude retains visual/data/pipeline scope. Follow AGENTS/API_CONTRACTS; future city work must preserve the staging transaction.

## Executed checks

- Actual Lua5.1 focused UI/menu/circuit PASS (agent),52files parsed.
- `C:/Python314/python.exe scripts/test_lua.py --runtime both`: PASS,27modules/52parsed files per actual Lua5.1/5.4 runtime (one final integration suite).
- `scripts/validate_project.py`: PASS,96paths,24-module TOCs/links/ledger; whitespacePASS. Six authoringPython scripts parse.
- Target city collision tests passed in bothruntimes plus29,160 bounded boundary moves/runtime and duplicated10k-tick deterministic replays. No client/cross-machine racing inference.
- Allruntimeart/header/hash/source-ledger comparisons PASS; full city art regeneration NOT RUN here (Claude's own build checks are recorded separately).
- Independent installed39/source39/manifest39 exactSHA256+pathsets PASS. Backup22/before.csv22/predeploy22 exacthashes PASS. Otherworktree297files/HEAD/branch/status and unrelated refs unchanged.

## Installation/publication evidence

Installed08:32+02 to **C:/Program Files (x86)/World of Warcraft/_classic_beta_/Interface/AddOns/AzerothKart** using existing PowerShell7 installhelper. Status/StageVerified, BackupVerified=true; all39files match tested commit e748b60. Prior22files preserved under `local-artifacts/deploy-20261022/20261022-082336-b891c186/install-backups/20261022-083240-447-60ddc86aae344da38fa31ae61459972d/before`; manifest `install.json`. Noextras/deletion/other-addon orWTF/SavedVariables writes.

Evidence root ignored `local-artifacts/deploy-20261022/20261022-082336-b891c186/`: complete verified all-ref bundle, snapshots, source-final.json, final-install-independent-audit.json, actual test/install logs and final publication receipt. Source feature-branch push succeeded normally; main/Claude refs unchanged. No tagged/distributed release. WindowsPowerShell5.1 WhatIf fails beforewrites due Get-FileHash inheritingWhatIf; PowerShell7 preflight/install worked, helper unmodified. No personal exports/extracted archives/backups staged.

## Owner test / next task

**Fully exit/restart WoW**, since there are new modules/textures. `/akart` → SinglePlayer → CapitalCitiesCup → StormwindCityCircuit → choosekart → Race!. Inspect bridges/Cathedral/street/wall feel; try Stop, Restart and Close results. PrintProbe if desired should show71/165/80 (Settings developerinfo).

Actualclient2048texture/loading/layout/fonts/sounds/scales/settingspersistence/drive/performance remain **NOT RUN**; owner reports next. M0/M1/M2/M3/content acceptance not completed by source checks. Asset redistribution unresolved for release underexistingADR0009. Allnewprefix/coordinatedstart/opponent/finish/socketreconnect multiplayer checks remainopen; screencommands unwired/Comingsoon.

NextCodex implementation after this handoff: bounded live-race controller and paced two-peer remote snapshots consuming existing backendGO, retaining persistent budget/exclusivelease/teardown and read-only remote presentation. Multiplayer ahead of ghosts/time trials. No need to repeatAKT723.

Final packaging note: the following deployment-documentation commit also corrects the addon readme's staging-texture count. Runtime code remains e748b60. The authorized installer is rerun against that final source tip; its exact final manifest/hash and remote branch tip are recorded in ignored `local-artifacts/deploy-20261022/20261022-082336-b891c186/final-publication-install-receipt.json`. The original22-file backup remains intact.
