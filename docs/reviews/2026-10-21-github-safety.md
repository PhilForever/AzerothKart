# GitHub access and parallel-work safety audit

2026-10-21, Windows. Source refs audited: Codex `e10d3ef`, Claude `1b2d3d5`; shared baseline `83c611c`. Scope: verify the owner's reported GitHub errors and preserve both agents' work. No integration or installation performed.

## Results

- Claude's exact tip is locally present: `1b2d3d579157ced3e8020896bb18f4593b1773dd`, `claude/ui-flow`. It contains the shared baseline plus five UI commits. Codex's backend/review chain diverges from the same baseline by three commits. Neither branch replaced the other.
- `git fsck --connectivity-only --no-reflogs` passed with no missing objects. Worktree pointers are valid Windows paths. Unreachable/dangling objects were left alone; no prune/gc/reset/rebase/force operation occurred.
- Canonical, Claude and Codex file snapshots matched after all read-only checks: respectively 103, 173 and 170 tracked/untracked file hashes, plus identical HEAD/status. Existing canonical untracked handoffs and Claude's untracked outputs remain untouched.
- A complete-history `git bundle create ... --all` recovery bundle was created and verified in ignored `local-artifacts/git-safety/20261021-134824/`. SHA-256: `794879814981707a03dfb77ca99a819f1f76b4d9ad51adecd99ebaf29638c505`. Local recovery data is not staged or published.
- Live `git ls-remote --heads origin ...` returned main `f923d15` and old `claude/track-ui` `812d132`; `claude/ui-flow` and the requested newer Codex branches were absent. Claude's 37 commits ahead of main include shared history, not 37 Claude-only UI commits.
- Native Windows Git passed `git -c push.followTags=false push --dry-run --porcelain origin refs/heads/claude/ui-flow:refs/heads/claude/ui-flow`, reporting a new branch. **No actual push happened.** No persistent credentials or Git configuration were changed. The unavailable `gh` CLI is unnecessary for this path.

Claude's reported cloud repository allowlist rejection and separate Linux-shell sign-in failure do not establish a broken repository. This Windows Git path passed its access test. Configure the permitted repository in Claude's session if direct cloud publication is desired; use explicit feature-branch refspecs for local publication. A push publishes commits; it does not merge the agents' file changes. Actual publication still needs the owner's explicit authorization under AGENTS.

## UI review and executed checks

Claude changed Menu, art, visual UI hooks and shared lists/docs. Core, physics/input/loop/race/checkpoint/protocol/transport source remain unchanged from `83c611c`; shared mechanical assertions were preserved. Codex accepts the proposed first-open saved-track restoration for later integration: it runs once, outside combat and while inactive, through the existing SelectTrack transaction; failed restoration preserves the saved preference. Client behavior is still pending.

Executed directly against Claude `1b2d3d5`, with Windows Python 3.14 and pinned Lupa:

- `scripts/test_lua.py --runtime lua51 --tests menu ui` — PASS, 40 Lua files parsed; explicit pool 65 frames/160 textures/79 fonts.
- `scripts/validate_project.py` — PASS, 77 expected paths, both TOCs, links and ledger. The reported Linux Windows-path link errors did not reproduce on Windows.
- `scripts/build_ui_art.py --check` — PASS, exact committed 2,097,170-byte preview atlas, SHA-256 `43afd042ade6b2ab628b860153bcfd91417ed3948bc7526260b91caff999863d`.

Codex did not rerun Lua 5.4/full broad suite or Claude's scratch-merge tests; those remain Claude's recorded evidence. No client checks or installs occurred. Multiplayer stays unwired/coming soon: the current Menu mapping does not yet implement coordinated clock/start capabilities. Shared UI/TOCs/tests/docs require a later reviewed integration preserving both sides; do not install Claude's standalone branch over newer Codex work.

## Next

Owner-authorized explicit feature-branch publication can use the working Windows Git path without touching main. Reviewed UI/backend integration remains separate. Development then returns to the live-race controller and paced remote snapshots; no code refactor or gameplay feature was started by this audit.
