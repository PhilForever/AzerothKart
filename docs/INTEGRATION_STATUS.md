# Shared integration and deployment status

Updated2026-10-22 08:12+02:00, Europe/Oslo. Codex is the designated integrator for the owner's request to combine the agents' work without losing either side. This is a source-integration checkpoint, not a release or installation. See [PROGRESS](PROGRESS.md), [ownership](UI_FLOW_OWNERSHIP.md), [API contracts](API_CONTRACTS.md) and both agent handoffs.

## Current combined source — preference finding resolved

User-authorized integration is complete on `codex/ui-backend-integration`:

- Reservation 5b69834 from review a77fe73, before source edits.
- Normal two-parent merge **6cd611a** combines published Claude **1b2d3d5** and reviewed Codex backend **192c6de**. Six shared doc/loader/test-list conflicts use the reviewed unions; no whole runtime file was replaced.
- **9b22f12** adopts Claude's isolated **4ffe184** preference fix using `cherry-pick -x`, retaining its author/coauthor and source hash. The city-branch-only preceding test was excluded, and the bar-cycle regression uses the reviewed two-track order. No city runtime is needed for this fix.
- **0eb6c63** adds future-schema and stopped-state protection coverage. This is the tested code baseline; the following documentation commit records the handoff (`git log -1 codex/ui-backend-integration`).

The [P2 review finding](reviews/2026-10-21-ui-backend-integration.md) is resolved: explicit successful current-ID choices are remembered, deferred restore yields to deliberate choice, untouched failed restores retain their preferences, and newer preference records remain unmodified. UI selection transactions/authoritative state remain unchanged.

Claude's current handoff at **claude/capital-cup78d97a1** explicitly supplies 4ffe184 in response to that review. Coordination uses that authored commit/handoff, not simultaneous edits in Claude's checkout. Its active Menu/city reservation, untracked outputs and all newer city collision/loading/pipeline work remain separate; this checkpoint does not review or integrate them. Claude's handoff file is not rewritten by Codex.

Executed: the new regression fails against old Menu1b2d3d5 in both Lua versions (expected failure, in-memory override); fixed Lua5.1 menu/ui pass; the full integration suite passes **26 test modules /48 parsed files in each of Lua5.1/5.4**. Mock pool **65 frames/160 textures/79 fonts**. Structural/art/preservation evidence is recorded in [PROGRESS](PROGRESS.md) and the Codex handoff. All18 Codex-owned runtime modules match 192c6de; all 10 runtime art files match Claude 1b2d3d5; UI differs from Claude only by the retained solo-start transport stop.

**Deployment/publication:** main/origin-main remain f923d15. Installed source is unchanged; no new client check, install, push, tag or release. Actual menu/fonts/sound/persistence/native coordinated traffic and multiplayer acceptance remain NOT RUN. The two earlier approved branch publications remain as previously verified; this local integration is not a third publication authorization. Multiplayer UI commands remain Coming soon.

## Previous review (2026-10-21)

The trial merge and three wrong preference outcomes remain documented in the [original review](reviews/2026-10-21-ui-backend-integration.md). At that time there was no real branch merge and the P2 finding blocked integration. Today's authored fix, regressions and source merge close that finding without changing historical evidence.

## GitHub and worktree safety checkpoint

2026-10-21: [audit](reviews/2026-10-21-github-safety.md) verified Claude1b2d3d5 and Codexe10d3ef independently descend from83c611c; both histories, other worktrees and untracked outputs are preserved. A verified ignored all-ref recovery bundle exists. Native Windows Git live refs and explicit dry-run push succeed; no actual push/merge/install occurred. Claude's session allowlist and Linux-shell credential errors are separate from this working Windows path. The owner subsequently authorized the two explicit feature-branch publications; the14:07 receipt verifies them. Reviewed source integration remains a separate action.

Codex's review accepts Claude's guarded first-open saved-track restoration for integration. Menu/UI Lua5.1, Windows structural validation and exact preview-art check pass on Claude's source. The combined integration check now passes as recorded above; actual client checks remain pending. Do not install either standalone branch over the shared target.

## Preserved backend history

`codex/start-clock` descends from SessionTransport commit `4f9246a` and adds the opt-in [clock/epoch and one-shot backend race initializer](START_CLOCK.md). Resolve its resulting commit from the Codex handoff/Git. The source is now included in the reviewed combined branch above, and is not installed. Claude's completed `claude/ui-flow` at `1b2d3d5` and its untracked outputs remain untouched. Integration must preserve both branches' shared loader/docs edits; ordinary solo UI.Start remains unchanged. Live movement/finish and actual client validation follow separately.

Previous backend boundary:

`codex/session-transport` starts from the preserved combined83c611c and adds the guarded SessionTransport bridge, copied menu API and focused tests. Its resulting commit is recorded in the Codex handoff/Git; it is not installed or automatically merged into the protected combined branch. Claude can inspect [SESSION_MENU_API](SESSION_MENU_API.md) via `git show codex/session-transport:docs/SESSION_MENU_API.md`; coordinate that exact backend commit when wiring the menu. Preserve any active visual branch/changes before creating a new branch or reviewed integration. The roster baseline/history below remains intact; do not install an older standalone branch.

## One integration path

| Role | Branch / state |
|---|---|
| Current reviewed combined source | `codex/ui-backend-integration`, tested code 0eb6c63; merge 6cd611a plus preference fix 9b22f12. Resolve the following documentation commit with `git log -1 codex/ui-backend-integration`. |
| Preserved roster baseline | `codex/roster-integration`83c611c, preserving Codex3644084 and Claude b0b1f2e. The following roster details are historical. |
| Preserved Codex baseline | `codex/peer-session` at3644084; protocol/session/results/Forever transport remain in the combined history. |
| Preserved Claude source | `claude/track-ui` atb0b1f2e, including runtime abe98f6. Its original five commits/authors/hashes are retained. Its worktree and untracked outputs are not changed. |
| Current installed addon | Existing22-file verified8f66c5a build, including effects/Close results/Forever fix. README_ADDON differs from the Git blob only by CRLF line endings. Combined roster/session source is not installed. |
| Publication | main/local origin/main f923d15 is historical publication; no push/release in this checkpoint. |

Do not merge Codex into the old Claude branch and separately install it. All deployment preparation for this checkpoint is from the reviewed combined branch, by Codex, after backup and installed-hash comparison. Claude continues visual work from the combined commit on a new Claude feature branch, preserving `claude/track-ui`. Codex continues backend work on its own branch from the same combined commit. Neither agent installs independently or merges the other's branch automatically. Future changes require a new reservation and reviewed integration.

The quoted Claude reply and its retained handoff are historical: AKT723 was completed, and AKT724/725 recovery plus PeerSession3644084 now exist. Do not execute the older trial-merge command from400590e or install standaloneabe98f6; both omit newer work. The source handoff remains unchanged as evidence of Claude's original branch, rather than being silently rewritten by Codex. In a stale checkout, inspect the current integration ledger from shared Git with `git show codex/ui-backend-integration:docs/INTEGRATION_STATUS.md`.

## Previous roster integration — preserved and resolved

- Normal merge, no squash/rebase/reset/force push or author rewrite. Earlier Claude commits f675610/c6e1b5e/1004e73 were already shared; only abe98f6/b0b1f2e were unique. New integrator commits use the configured PhilForever identity; no request to rename past or future authors was made.
- Four new64-heading WC3 sheets, the six-kart selector and neutral loaded-art colour, plus existing trike/drag car/effects/Mirage assets. Imported binary art stays byte-identical to Claude's committed files. Source/credit/permission records are preserved; this does not clear redistribution.
- Codex's explicit drive-exit policy, Stop/Close results, Forever full-name logged route, opt-in AZKART1 experiment, measured evidence, RaceProtocol and pure PeerSession. Authoritative mechanics/transport modules and their tests are checked against3644084.
- Shared count/docs/test conflicts combine both buttons:11frames/151textures/13fonts. The stronger effect repeatability limitation is retained. Historical evidence/counts are not converted into new client passes.
- Narrow reviewed fixes: a failed kart load restores full previous crop/rotation/metadata; rollback failure falls back consistently to the primitive. Per-kart coverage floors remain12% for ground sheets,8% gryphon and6% gyro. No new gameplay or transport feature is added here.

## Local recovery and future synchronization

Current verified all-ref recovery bundle and other-worktree file/ref snapshots are under ignored `local-artifacts/integration-20261022/20261022-080331-b5d03e9a/`. The earlier roster recovery remains under `local-artifacts/integration/20261021-0732-preservation/`. They contain local recovery data only; do not publish the folder. Canonical and Claude tracked/untracked file hashes are compared after integration; no cleanup, pruning or deletion is performed. In the cloud environment, never run Git worktree prune/gc against stored Windows worktree paths.

Claude remains on its active city branch. Do not switch or reset it now to synchronize this menu fix; that fix is already shared as the original4ffe184 and reviewed cherry-pick9b22f12. A later city integration must review its collision/track-loading changes and preserve both sides' subsequent work. After that reservation is complete, its owner may create a new feature branch from the exact combined commit. Check status first; preserve new work and stop if a switch would overwrite it. Example for that future clean start, run only by the checkout's owner:

```powershell
git -C "C:\Users\bakke\Downloads\Forever_Addons\AzerothKart_Codex_Project_Pack\AzerothKart-Claude" status --short
git -C "C:\Users\bakke\Downloads\Forever_Addons\AzerothKart_Codex_Project_Pack\AzerothKart-Claude" switch -c claude/next-visual codex/ui-backend-integration
```

These commands were not executed in Claude's worktree. No new download/manual test is requested. Next Codex task: bounded live-race controller and paced two-peer remote snapshots consuming the existing backend GO handoff. Native menu appearance, selection/fallback/saving, resource costs and coordinated live-race behavior remain NOT RUN. Multiplayer retains priority; no roadmap acceptance was marked complete.
