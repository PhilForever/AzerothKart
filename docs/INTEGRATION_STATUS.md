# Shared integration and deployment status

Updated2026-10-22 16:33 +0200, Europe/Oslo. Codex is the designated integrator for the owner's request to combine the agents' work without losing either side. The reviewed combined developer source is installed for owner testing; no release is authorized. See [PROGRESS](PROGRESS.md), [ownership](UI_FLOW_OWNERSHIP.md), [API contracts](API_CONTRACTS.md) and both agent handoffs.




## Multiplayer grid/display follow-up — 2026-10-23

`codex/multiplayer-grid` builds on6ad66d1/c581a52 with immutable kart-profile
agreement, two role-specific grid slots, full3–2–1–GO and timestamp-aware bounded
opponent display. First owner race feedback is [recorded](evidence/2026-10-23-first-live-race.md);
revised native behavior remains NOT RUN. The final source commit/install/package
receipt is recorded in PROGRESS and the Codex handoff. No asset/track/Physics
change, kart contact, agreed winner, main merge or publication is included.

Claude independently advanced to e96044b on `claude/darnassus-undercity`, from
the same6ad66d1 baseline. Its handoff explicitly preserves the multiplayer
reservation, with catalog-only Menu/test additions. That worktree, its untracked
outputs and existing Orgrimmar ref remain untouched; no new city integration is
included here. Future integration must combine catalog rows with these newer
session/capture/render changes rather than installing the older branch alone.
All older entries below are historical checkpoints.

## Authorized publication and shared baseline

2026-10-22 16:38 +0200: `codex/ironforge-narrows` is published at `c6bb0e5699b5f30d9f684d50283c76b5fd4d4a8b` (normal push/live remote exact); following publication documentation goes on that same branch. All current Claude9461f9c history is included; its checkout is tracked-clean and unchanged. Main remainsf923d15. [Open the combined GitHub branch](https://github.com/PhilForever/AzerothKart/tree/codex/ironforge-narrows), rather than expecting the main landing page to contain it. Installed runtime remains tested82d57eb:41 exact files,41 verified prior-file backup. Native v3 acceptance pending. Codex's [handoff](handoffs/codex-latest.md#authorized-publication-and-claude-alignment) gives Claude safe fetch/new-branch commands; no foreign checkout was switched and no direct Claude acknowledgment is claimed. No release or automatic future publication.

## Current Ironforge v3 integration — installed for owner testing

2026-10-22 16:24 +0200. `codex/ironforge-narrows`, base d5817a8/reservation69dc2dd, integrates reviewed Claude9461f9c. The additive narrows contract is accepted: two radius42 tunnels, matching visual/generator/collision geometry, unchanged route/gates and Stormwind. Lava/anvil/pump art imported; all other runtime images and backend/UI/global Physics unchanged. Focused dual-runtime circuit/physics/surface/ui/menu/determinism,11 analytic tests, geometry check and104-path validator PASS. [Review](reviews/2026-10-22-ironforge-narrows.md). Implementation **82d57eb11e23eb2417a323ba0c714c23514a50af** is installed after verified41-file backup; all41 committed/source/installed/manifest hashes match, and the backup exactly matchesac4ae23 with no extras. Independent receipt `local-artifacts/ironforge-v3-integration-20261022/deployment-receipt.json`; manifest `local-artifacts/ironforge-v3-integration-20261022/install-backups/20261022-163127-637-2915c11e90644cd9ae1a21f6037226c3/install.json`. Both other worktrees'326 files/statuses/HEADs and all previous refs remain intact. The reviewed rough-pocket correction keeps fully paved tunnel corners on road without changing clearance or broad shoulders. Following documentation changes no addon files. Native v3 acceptance remains NOT RUN; no GitHub push or main merge.

## Current Ironforge integration — installed for owner testing

2026-10-22 13:27 +02:00. `codex/ironforge-integration` combines clean899d04d with reviewed Claude `de2fa5f`. Stormwind's owner-confirmed corner/full-speed fixes and the staged background loader remain; Ironforge adds its original route/art and reuses the exposed-wall correction in version2, with rough shoulders retained. Four solo tracks and six karts; no multiplayer activation. Full dual-runtime offline suite, focused regressions,9 analytic tests, generated geometry and103-path structural validation PASS. [Review](reviews/2026-10-22-ironforge-integration.md) and [Codex handoff](handoffs/codex-latest.md) specify scope, resources and native checks. Implementation merge **ac4ae23** (parents7fe251e/de2fa5f) is installed:41/41 committed source/target/manifest hashes exact;39/39 prior files independently verified in backup against before.csv and81cc0ed, no extras. Ignored manifest `local-artifacts/ironforge-integration-20261022/install-backups/20261022-132604-865-804f0c60ebb042a7bc3e340f5eb40463/install.json`; independent deployment receipt in the same task-artifacts root. Both other worktrees'305files/statuses/HEADs are preserved. Full exit/restart is required for new textures; Ironforge native checks remain NOT RUN. Following deployment docs do not change addon files. This feature branch is local; main/published branches and both other checkouts remain unchanged.

## Latest installed collision correction — painted Stormwind wall

2026-10-22 10:46 +02:00: **81cc0ed**, `codex/stormwind-wall-alignment` fromf62e708. Corrects invisibleconcavecollisionwedge atPark/Mage by retaining14-unitcentreclearance to exposedpaintedunion; keepsfullspeed andstraightwallpadding, no art/othertrack/Physicschanges. Reachableprojection/arcslides obeytheoriginalstepbound. Stormwindv3/generatedjunctionmetadata; focusedPython9/Lua5.1checks and98pathvalidator PASS.39installedfiles/source/hash exact,39priorfiles backedup/verified. Native `/reload` retest NOT RUN. Localonly; publishedcombinedc59a607 andotheragentworktree/history remainunchanged. Details inPROGRESS/Codexhandoff.

## Prior installed handling correction — Stormwind full speed

2026-10-22 10:11 +02:00: owner-directed correction **c4b430d**, `codex/stormwind-full-speed` from the published integratedc59a607 baseline. Stormwind version2 has full road grip/speed/drift/boost throughout the existing corridor until wall contact; no slowdown on its painted shoulder. Other tracks/walls/art/globalPhysics7 unchanged. Focused Lua5.1 tests/generator/validator PASS;39files installed/hash-verified,39priorfiles backed up/verified. Owner `/reload` check NOT RUN. This local correction has not been pushed; the combined published branch below remains unchanged. See PROGRESS and the Codex handoff.

## Published combined baseline — pushed and installed before handling correction

2026-10-22 08:37 +02:00, Europe/Oslo. User explicitly authorized latest-handoff review, push and installation, then his client test. Codex read Claude's complete current handoff **78d97a1**, reviewed the city collision/selection changes and integrated that source, beyond the previously reviewed two-track UI. See [city review](reviews/2026-10-22-city-integration.md).

- Original UI/backend merge **6cd611a**, authored preference fix **9b22f12** and future-schema/stopped-state regression **0eb6c63** remain preserved.
- Deployment reservation **e976f55** preceded new changes. Two-parent merge **f9f2af0** adds Claude's **78d97a1** city/runtime/art/pipeline, with per-hunk shared-list/docs/test unions retaining all Codex modules and regressions. Both agent histories and original tips remain intact.
- Tested/installed code **e748b60** repairs a reviewed P2: load/validate a new scenery image on a hidden pooled texture, swapping it into view only on success. No destructive rollback load of the visible image. Final explicit pool **71 frames/165 textures/80 font strings**,24 modules in each TOC. No new multiplayer action/replication.
- Full offline suite **27 modules/52 parsed files in each Lua5.1/5.4** PASS; focused Lua5.1 UI/menu/circuit PASS; validator **96 paths**, TOCs/links/ledger PASS; all18 old Codex modules and12 authored art files preserved. Source39files.
- Normal non-force push created `origin/codex/ui-backend-integration` at codee748b60; the following documentation commit records this deployment and advances the same branch. Resolve its final tip with `git log -1 codex/ui-backend-integration`; final remote-ref verification is retained in the ignored publication receipt. No main/Claude branch push, tag, release or history rewrite.
- **Installed and independently verified:** all39 files in `C:/Program Files (x86)/World of Warcraft/_classic_beta_/Interface/AddOns/AzerothKart` exactly match this tested source and manifest. Prior22 files are backed up and independently SHA256-checked against preflight/before.csv. Manifest Status/Stage=Verified, BackupVerified=true. No extras, deletion, other addon or WTF/SavedVariables writes.

Evidence/backup root: ignored `local-artifacts/deploy-20261022/20261022-082336-b891c186/`; exact operation `local-artifacts/deploy-20261022/20261022-082336-b891c186/install-backups/20261022-083240-447-60ddc86aae344da38fa31ae61459972d/`. Both other worktrees'297 tracked/untracked files, HEADs, branches and statuses remain unchanged. The combined checkout now contains Claude's actual latest authored handoff; Codex has not rewritten it or switched Claude's active city worktree.

**Owner test next:** fully exit/restart WoW (new files), `/akart` → Single Player → Capital Cities Cup → Stormwind City Circuit → kart → Race!. Check the city scenery/bridges/Cathedral, driving and Stop/Restart/Close results. Actual native texture loading, menus/fonts/sound/scales/persistence/handling/performance remain **NOT RUN** until the owner reports. Multiplayer remains Coming soon and actual new-prefix/start/live-race/reconnect gates remain open.

## Previous review (2026-10-21)

The trial merge and three wrong preference outcomes remain documented in the [original review](reviews/2026-10-21-ui-backend-integration.md). At that time there was no real branch merge and the P2 finding blocked integration. Today's authored fix, regressions and source merge close that finding without changing historical evidence.

## GitHub and worktree safety checkpoint

2026-10-21: [audit](reviews/2026-10-21-github-safety.md) verified Claude1b2d3d5 and Codexe10d3ef independently descend from83c611c; both histories, other worktrees and untracked outputs are preserved. A verified ignored all-ref recovery bundle exists. Native Windows Git live refs and explicit dry-run push succeed; no actual push/merge/install occurred. Claude's session allowlist and Linux-shell credential errors are separate from this working Windows path. The owner subsequently authorized the two explicit feature-branch publications; the14:07 receipt verifies them. Reviewed source integration remains a separate action.

Codex's review accepts Claude's guarded first-open saved-track restoration for integration. Menu/UI Lua5.1, Windows structural validation and exact preview-art check pass on Claude's source. The combined integration check now passes as recorded above; actual client checks remain pending. Do not install either standalone branch over the shared target.

## Preserved backend history

`codex/start-clock` descends from SessionTransport commit `4f9246a` and adds the opt-in [clock/epoch and one-shot backend race initializer](START_CLOCK.md). Resolve its resulting commit from the Codex handoff/Git. The source is now included in the reviewed combined branch and39-file installation above. Claude's completed `claude/ui-flow` at `1b2d3d5` and its untracked outputs remain untouched. Integration must preserve both branches' shared loader/docs edits; ordinary solo UI.Start remains unchanged. Live movement/finish and actual client validation follow separately.

Previous backend boundary:

`codex/session-transport` starts from the preserved combined83c611c and adds the guarded SessionTransport bridge, copied menu API and focused tests. Its resulting commit is recorded in the Codex handoff/Git; it is retained in the current combined source/installation; that historical feature branch remains unchanged. Claude can inspect [SESSION_MENU_API](SESSION_MENU_API.md) via `git show codex/session-transport:docs/SESSION_MENU_API.md`; coordinate that exact backend commit when wiring the menu. Preserve any active visual branch/changes before creating a new branch or reviewed integration. The roster baseline/history below remains intact; do not install an older standalone branch.

## One integration path

| Role | Branch / state |
|---|---|
| Current reviewed combined source | `codex/ui-backend-integration`, tested/installed codee748b60; city mergef9f2af0 preserves Claude78d97a1 and prior UI/backend fixes. The following documentation commit records deployment. |
| Preserved roster baseline | `codex/roster-integration`83c611c, preserving Codex3644084 and Claude b0b1f2e. The following roster details are historical. |
| Preserved Codex baseline | `codex/peer-session` at3644084; protocol/session/results/Forever transport remain in the combined history. |
| Preserved Claude source | `claude/track-ui` atb0b1f2e, including runtime abe98f6. Its original five commits/authors/hashes are retained. Its worktree and untracked outputs are not changed. |
| Current installed addon |39 files, tested sourcee748b60, verified exactSHA256 with prior22-file backup. Native client test pending full restart. |
| Publication | Combined feature branch published normally; main/local origin/mainf923d15 preserved. No tag or release. |

Do not merge Codex into the old Claude branch and separately install it. All deployment preparation for this checkpoint is from the reviewed combined branch, by Codex, after backup and installed-hash comparison. Claude continues visual work from the combined commit on a new Claude feature branch, preserving `claude/track-ui`. Codex continues backend work on its own branch from the same combined commit. Neither agent installs independently or merges the other's branch automatically. Future changes require a new reservation and reviewed integration.

The quoted Claude reply and its retained handoff are historical: AKT723 was completed, and AKT724/725 recovery plus PeerSession3644084 now exist. Do not execute the older trial-merge command from400590e or install standaloneabe98f6; both omit newer work. The source handoff remains unchanged as evidence of Claude's original branch, rather than being silently rewritten by Codex. In a stale checkout, inspect the current integration ledger from shared Git with `git show codex/ui-backend-integration:docs/INTEGRATION_STATUS.md`.

## Previous roster integration — preserved and resolved

- Normal merge, no squash/rebase/reset/force push or author rewrite. Earlier Claude commits f675610/c6e1b5e/1004e73 were already shared; only abe98f6/b0b1f2e were unique. New integrator commits use the configured PhilForever identity; no request to rename past or future authors was made.
- Four new64-heading WC3 sheets, the six-kart selector and neutral loaded-art colour, plus existing trike/drag car/effects/Mirage assets. Imported binary art stays byte-identical to Claude's committed files. Source/credit/permission records are preserved; this does not clear redistribution.
- Codex's explicit drive-exit policy, Stop/Close results, Forever full-name logged route, opt-in AZKART1 experiment, measured evidence, RaceProtocol and pure PeerSession. Authoritative mechanics/transport modules and their tests are checked against3644084.
- Shared count/docs/test conflicts combine both buttons:11frames/151textures/13fonts. The stronger effect repeatability limitation is retained. Historical evidence/counts are not converted into new client passes.
- Narrow reviewed fixes: a failed kart load restores full previous crop/rotation/metadata; rollback failure falls back consistently to the primitive. Per-kart coverage floors remain12% for ground sheets,8% gryphon and6% gyro. No new gameplay or transport feature is added here.

## Local recovery and future synchronization

Current deployment all-ref recovery bundle and other-worktree file/ref snapshots are under ignored `local-artifacts/deploy-20261022/20261022-082336-b891c186/`. The earlier Menu integration recovery remains under `local-artifacts/integration-20261022/20261022-080331-b5d03e9a/`. The earlier roster recovery remains under `local-artifacts/integration/20261021-0732-preservation/`. They contain local recovery data only; do not publish the folder. Canonical and Claude tracked/untracked file hashes are compared after integration; no cleanup, pruning or deletion is performed. In the cloud environment, never run Git worktree prune/gc against stored Windows worktree paths.

Claude remains on its active city branch. Do not switch or reset it: its78d97a1 history is now in the combined source, with Codex's reviewed staging-load repair above. Future city work must preserve that transaction, both agents' subsequent changes and their reservations. After that reservation is complete, its owner may create a new feature branch from the exact combined commit. Check status first; preserve new work and stop if a switch would overwrite it. Example for that future clean start, run only by the checkout's owner:

```powershell
git -C "C:\Users\bakke\Downloads\Forever_Addons\AzerothKart_Codex_Project_Pack\AzerothKart-Claude" status --short
git -C "C:\Users\bakke\Downloads\Forever_Addons\AzerothKart_Codex_Project_Pack\AzerothKart-Claude" switch -c claude/next-visual codex/ui-backend-integration
```

These commands were not executed in Claude's worktree. The owner now performs the client test against the coordinated installation above. Next Codex task: bounded live-race controller and paced two-peer remote snapshots consuming the existing backend GO handoff. Native menu appearance, selection/fallback/saving, resource costs and coordinated live-race behavior remain NOT RUN. Multiplayer retains priority; no roadmap acceptance was marked complete.

Final packaging note: the following deployment-documentation commit also corrects the addon readme's staging-texture count. Runtime code remains e748b60. The authorized installer is rerun against that final source tip; its exact final manifest/hash and remote branch tip are recorded in ignored `local-artifacts/deploy-20261022/20261022-082336-b891c186/final-publication-install-receipt.json`. The original22-file backup remains intact.
