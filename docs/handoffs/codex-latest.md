# Codex handoff — safe combined source; no install

2026-10-21 07:39+02:00 Europe/Oslo. `codex/roster-integration`, from preserved Codex3644084 and Claude b0b1f2e, reservation commit1fd6275. This handoff is part of the reviewed two-parent integration commit; resolve result with `git log -1 codex/roster-integration`. See [INTEGRATION_STATUS](../INTEGRATION_STATUS.md) before following any older branch/deployment instruction.

## Owner request and preserved baseline

Owner asked Codex to handle the older Claude reply without mixing code or losing work. Codex is designated integrator/deployer for this checkpoint. Normal merge of b0b1f2e onto latest Codex; no new gameplay/session transport code. Original codex/peer-session3644084, claude/track-ui b0b1f2e, main/local origin/main f923d15 and canonical5570968 preserved. All original authors/hashes retained under configured PhilForever identity. Both other worktrees, including untracked Claude outputs, are SHA-checked unchanged. No author rewrite, reset/rebase/force push, pruning/gc, cleanup or automatic main integration.

Pre-merge complete-history bundle verified; branch/worktree inventories plus source/installed preservation evidence in ignored `local-artifacts/integration/20261021-0732-preservation/`. Do not publish private recovery artifacts. Installed22files still match existing verified8f66c5a installmanifest; README_ADDON's CRLF differs from Git only by line endings. No install/clientinput/newpackage/download/push/tag/release this turn.

## What the combined source includes

- Claude trike/Mirage/effects plus four more64-heading WC3karts, six-kart stopped picker, neutral loaded artwork, art/source/credit records and JPEG tooling.21art binary hashes exactly matchClaude.
- Codex Close results and explicit drive exits, Forever full-name logged transport, standalone AZKART1 measurements/evidence including completed AKT722–725, RaceProtocol and pure PeerSession.36mechanical/transport/test/TOC files unchanged from3644084 and all147baseline paths remain. Both TOCs16modules.
- Shared conflicts manually combine both sides' intended changes, with11/151/13 pool counts. Stronger effect repeatability caveat preserved. No whole-file ours/theirs replacement.
- Two reviewed fixes completed narrowly by integrator: full visual rollback on late sprite load/setter refusal, consistent Basic fallback if rollback fails; per-kart opaque coverage12%ground/8%gryphon/6%gyro. [Review follow-up](../reviews/2026-10-21-claude-roster.md). No changes to authoritative run/result/track/physics or extra UI objects.

Claude's latest handoff is imported verbatim from its original branch as evidence. Its AKT723-next/scratch400590e merge/install directions are historical. Do not follow them; they omit latest backend work. Its source branch is not modified to backport our integration fixes.

## Tests / evidence actually executed

- Real Lua5.1 via pinned Lupa2.8: `scripts/test_lua.py --runtime lua51` PASS,38files parsed,all21test modules. Covers whole existing deterministic/collision/race/input/probe/codec/session behavior and combined roster/UI, new late-failure/rollback-failure/recovery checks. Counts11frames/151textures/13fonts. Earlier focused presentation/ui checks also passed. No repeat broad dual-runtime matrix.
- `scripts/validate_project.py` STATIC PASS71paths/TOCs/links/ledger; whitespace checks PASS.
- Preservation PASS:36backend/test/TOC paths retain3644084;21art binaries retainClaude;all147baseline files present. Both other worktrees' full tracked/untracked bytes/path sets/HEADs and preserved refs unchanged. Installed22file hashes/tree unchanged, no missing/extras.
- NOT RUN: current combinedLua5.4, new roster native appearance/loading/selection/fallback/resource cost, actual session native traffic or live racing. No milestone/client/release pass inferred. Rights/provenance unresolved where documented.

## Single current path / next task

Claude owns visual layout/navigation/copy/polish; Codex owns backend session semantics and the next guarded native transport adapter. Shared contracts unchanged except documented additive roster diagnostics/rollback behavior and reviewed counts. [UI_FLOW_OWNERSHIP](../UI_FLOW_OWNERSHIP.md) applies. Both agents create their next separate feature branches from the exact combined commit in their own worktree. Preserve old branches; never merge/update another agent's worktree automatically. Codex alone prepares the next coordinated install from reviewed combined source with backup/hash verification; no independent older-feature-branch installs.

**Next single task:** Codex branch from combined baseline, guarded native PeerSession adapter/global rate+byte accounting/lifecycle cancellation/copied view-action bridge for Claude's Host/Join/Ready screen. START remains a one-shot parameter proposal, not clock agreement/atomic GO/race activation. Live-race integration follows separately. No new download/manual test requested now; completed AKT723 need not be repeated. Four paircalls/s and316payload+prefixB/s remain working ceilings, not measured maxima; approximately700ms RTT and actual candidate gameplay/socket/scale/finish acceptance remain open.
