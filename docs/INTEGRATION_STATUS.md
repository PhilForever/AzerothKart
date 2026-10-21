# Shared integration and deployment status

Updated2026-10-21, Europe/Oslo. Codex is the designated integrator for the owner's request to combine the agents' work without losing either side. This is a source-integration checkpoint, not a release or installation. See [PROGRESS](PROGRESS.md), [ownership](UI_FLOW_OWNERSHIP.md), [API contracts](API_CONTRACTS.md) and both agent handoffs.

## GitHub and worktree safety checkpoint

2026-10-21: [audit](reviews/2026-10-21-github-safety.md) verified Claude1b2d3d5 and Codexe10d3ef independently descend from83c611c; both histories, other worktrees and untracked outputs are preserved. A verified ignored all-ref recovery bundle exists. Native Windows Git live refs and explicit dry-run push succeed; no actual push/merge/install occurred. Claude's session allowlist and Linux-shell credential errors are separate from this working Windows path. Publication requires explicit owner authorization; reviewed source integration remains a separate action.

Codex's review accepts Claude's guarded first-open saved-track restoration for integration. Menu/UI Lua5.1, Windows structural validation and exact preview-art check pass on Claude's source. Actual client and a Codex-run combined integration check remain pending. Do not install either standalone branch over the shared target.

## Latest backend candidate

`codex/start-clock` descends from SessionTransport commit `4f9246a` and adds the opt-in [clock/epoch and one-shot backend race initializer](START_CLOCK.md). Resolve its resulting commit from the Codex handoff/Git. The source is not installed or automatically merged. Claude's completed `claude/ui-flow` at `1b2d3d5` and its untracked outputs remain untouched. Integration must preserve both branches' shared loader/docs edits; ordinary solo UI.Start remains unchanged. Live movement/finish and actual client validation follow separately.

Previous backend boundary:

`codex/session-transport` starts from the preserved combined83c611c and adds the guarded SessionTransport bridge, copied menu API and focused tests. Its resulting commit is recorded in the Codex handoff/Git; it is not installed or automatically merged into the protected combined branch. Claude can inspect [SESSION_MENU_API](SESSION_MENU_API.md) via `git show codex/session-transport:docs/SESSION_MENU_API.md`; coordinate that exact backend commit when wiring the menu. Preserve any active visual branch/changes before creating a new branch or reviewed integration. The roster baseline/history below remains intact; do not install an older standalone branch.

## One integration path

| Role | Branch / state |
|---|---|
| Reviewed combined source | `codex/roster-integration`, from Codex3644084 plus a normal two-parent merge of Claude b0b1f2e. The merge and exact resulting commit are recorded in Git and the Codex handoff. |
| Preserved Codex baseline | `codex/peer-session` at3644084; protocol/session/results/Forever transport remain in the combined history. |
| Preserved Claude source | `claude/track-ui` atb0b1f2e, including runtime abe98f6. Its original five commits/authors/hashes are retained. Its worktree and untracked outputs are not changed. |
| Current installed addon | Existing22-file verified8f66c5a build, including effects/Close results/Forever fix. README_ADDON differs from the Git blob only by CRLF line endings. Combined roster/session source is not installed. |
| Publication | main/local origin/main f923d15 is historical publication; no push/release in this checkpoint. |

Do not merge Codex into the old Claude branch and separately install it. All deployment preparation for this checkpoint is from the reviewed combined branch, by Codex, after backup and installed-hash comparison. Claude continues visual work from the combined commit on a new Claude feature branch, preserving `claude/track-ui`. Codex continues backend work on its own branch from the same combined commit. Neither agent installs independently or merges the other's branch automatically. Future changes require a new reservation and reviewed integration.

The quoted Claude reply and its retained handoff are historical: AKT723 was completed, and AKT724/725 recovery plus PeerSession3644084 now exist. Do not execute the older trial-merge command from400590e or install standaloneabe98f6; both omit newer work. The source handoff remains unchanged as evidence of Claude's original branch, rather than being silently rewritten by Codex. In a stale checkout, inspect this integration ledger from shared Git with `git show codex/roster-integration:docs/INTEGRATION_STATUS.md`.

## What is preserved and resolved

- Normal merge, no squash/rebase/reset/force push or author rewrite. Earlier Claude commits f675610/c6e1b5e/1004e73 were already shared; only abe98f6/b0b1f2e were unique. New integrator commits use the configured PhilForever identity; no request to rename past or future authors was made.
- Four new64-heading WC3 sheets, the six-kart selector and neutral loaded-art colour, plus existing trike/drag car/effects/Mirage assets. Imported binary art stays byte-identical to Claude's committed files. Source/credit/permission records are preserved; this does not clear redistribution.
- Codex's explicit drive-exit policy, Stop/Close results, Forever full-name logged route, opt-in AZKART1 experiment, measured evidence, RaceProtocol and pure PeerSession. Authoritative mechanics/transport modules and their tests are checked against3644084.
- Shared count/docs/test conflicts combine both buttons:11frames/151textures/13fonts. The stronger effect repeatability limitation is retained. Historical evidence/counts are not converted into new client passes.
- Narrow reviewed fixes: a failed kart load restores full previous crop/rotation/metadata; rollback failure falls back consistently to the primitive. Per-kart coverage floors remain12% for ground sheets,8% gryphon and6% gyro. No new gameplay or transport feature is added here.

## Local recovery and future synchronization

A verified complete-history bundle and pre-integration branch/worktree hashes are under ignored `local-artifacts/integration/20261021-0732-preservation/`. They contain local recovery data only; do not publish the folder. Canonical and Claude tracked/untracked file hashes are compared after integration; no cleanup, pruning or deletion is performed. In the cloud environment, never run Git worktree prune/gc against stored Windows worktree paths.

After the integrator records the final combined hash, each agent creates a new feature branch from that exact commit in its own existing worktree. Check status first, preserve any new uncommitted work, and stop if switching would overwrite it. Do not switch the other agent's checkout. Example for Claude (replace COMBINED_COMMIT with the recorded hash):

```powershell
git -C "C:\Users\bakke\Downloads\Forever_Addons\AzerothKart_Codex_Project_Pack\AzerothKart-Claude" status --short
git -C "C:\Users\bakke\Downloads\Forever_Addons\AzerothKart_Codex_Project_Pack\AzerothKart-Claude" switch -c claude/ui-flow COMBINED_COMMIT
```

No synchronization command above has been executed in Claude's worktree. No new download or manual test is requested. Native roster appearance, actual selection/fallback behavior, resource costs and all new live-session/race behavior remain NOT RUN; source validation is recorded in the Codex handoff/PROGRESS. Multiplayer still has priority. The guarded adapter is implemented on the backend candidate above; start-clock/live coordinator work follows. No new download or manual test is requested now.
