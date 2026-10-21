# Active integration reservation — preserve both agent histories

2026-10-21 07:31+02:00, Europe/Oslo. User asks Codex to handle Claude/Codex coordination without overwriting or deleting work. Codex is the designated integrator for this checkpoint. Integration branch `codex/roster-integration` starts at latest Codex `3644084`, not stale AKT723. Preserve `codex/peer-session` at3644084 and `claude/track-ui` atb0b1f2e and all existing authors/hashes. No reset/rebase/force push, other-worktree edits, pruning/gc, install or client input.

Scope: reviewed merge of Claude b0b1f2e; resolve only shared count/docs/test conflicts while retaining Codex transport/results/protocol/PeerSession. Codex reserves the specific reviewed `UI.SelectKart`/sprite rollback and coverage regressions as integrator (no new visual design); Claude's source branch remains unchanged. Verify imported art bytes and untouched mechanical/transport modules. Document one integration/deployment path, progress/own handoff; preserve Claude's latest handoff verbatim as branch-history evidence. No new gameplay or live transport feature this checkpoint.

Plan: create and verify local recovery bundle plus pre-merge branch/worktree inventory; merge on this branch with no automatic commit; resolve source/contract conflicts manually; fix reviewed late-load rollback and per-kart coverage; run focused combined Lua5.1 checks and structural/provenance preservation checks; commit reviewed combined candidate. Native/manual client checks remain NOT RUN; deployment stays separate.

---
# Codex handoff — reviewed roster, UI ownership, pure PeerSession

2026-10-21 07:23+02:00 (Europe/Oslo). Branch `codex/peer-session`, base `d857ce2`, existing AzerothKart-Codex-Review checkout. Resulting focused implementation commit: resolve with `git log -1 codex/peer-session` (this handoff is part of that commit).

## Completed order and ownership

1. Reviewed Claude runtime `abe98f6`/handoff `b0b1f2e` against integrated `1004e73`. [Findings](../reviews/2026-10-21-claude-roster.md): P2 failed sheet switch can restore Drag Car with cropped UVs; P3 retain per-kart opaque coverage floors. Hold roster integration for Claude's rollback fix; no merge/install occurred. Claude's output folder/worktree/handoff untouched.
2. [UI/flow assignment](../UI_FLOW_OWNERSHIP.md): Claude owns layout/navigation/copy/visual polish; Codex owns session transitions, capability/button command semantics, transport, timing and cleanup. Shared interfaces and integration remain coordinated.
3. Implemented pure PeerSession and focused tests, both TOCs/runner/validator and matching contracts/status docs. No UI/Presentation/asset/physics/input/race/Core or AZKART1 probe behavior edits.

No installation, client input, downloads, push, tag or release. Main/local origin/main remains `f923d15`; canonical `5570968`; Claude `b0b1f2e`. Last installed verified runtime `8f66c5a`. Existing live evidence AKT722–725 unchanged. Installed and source are deliberately different here.

## Implemented API

[Full PeerSession contract](../API_CONTRACTS.md#implemented-pure-peer-session-controller). Optional namespace registration/return; injected RaceProtocol and finite monotonic time. `new`, `invite`, `join`, `setReady`, `start`, `cancel`, `update`, `receive`, `view`, `takeStartProposal`. Explicit two-peer phases/readiness, copied presentation view/action capabilities, full Forever native identity/session/version checks, host-selected supported track/laps. One pending command,2-second retries/max3attempts, shared0.5-second ACK/control/retry spacing, one output/update, bounded ACK8/seen64/scoped-receive256 and fixed deadlines. Failed/unknown/throttled/throwing sends and invalid clocks terminate/clear output. Cancel/final ACK is optional/bounded best effort.

Host Start requires both ready and local Ready ACK. START produces copied parameters once, guest on receipt/host after ACK. It neither calls Race/Physics/UI nor supplies atomic GO/clock agreement. Both stay starting until explicit cancellation or deadline; a separate live coordinator is required. No native session adapter or multiplayer menu exists yet. Both TOCs16modules; UI pool remains10/151/13 on unchanged Codex rendering. Future Claude roster integration must retain Close results and11/151/13 combined.

## Tests actually executed

- Lua5.1 via canonical pinned Lupa: `scripts/test_lua.py --runtime lua51 --tests peer_session race_protocol transport_probe ui` PASS,38files parsed/all4modules passed. Root review corrected clock-error arithmetic after actual sends; independent review corrected nested update moving clock before guard. Final relevant tests passed after fixes.
- Added lost START-ACK retry/proposal-once test, reran `--runtime lua51 --tests peer_session`:PASS38parsed. Two-peer tests also cover strict join/ready, copies, identity/compatibility, duplicate/conflict/stale/reorder, drops/retries/timeouts, native failure/reentry, no bursts and cancellation/ACK queue cap.
- Structural validator PASS65paths/TOCs/links/ledger; whitespace check PASS. No broad repeated matrix.
- Claude read-only review: Lua5.1 presentation/ui PASS34parsed;5WC3vehicle source SHA/TGA validation and5JPEG decodes PASS. Actual visual failure reproduced independently. Pillow comparison/regeneration/new-roster install/client checks NOT RUN.
- Current PeerSession Lua5.4 and all new native/client/two-player integration checks NOT RUN. No claim of full disconnect, simultaneous racing streams, atomic start or M2 acceptance.

## Next single task / coordination

Codex: guarded native two-peer session adapter over PeerSession, fresh-session lifetime and global rate/byte accounting, lifecycle cancellation and copied view/action bridge. Use only existing Forever logged WHISPER route with full first-name/surname, no realm/fallback. Preserve standalone AZKART1 experiment; coordinate subscriptions/update ownership and disallow concurrent traffic bypassing the shared budget. Pair working ceilings4calls/s and316payload+prefixB/s before overhead are exercised schedule ceilings, not measured maxima. PeerSession's local cadence alone does not enforce a global budget.

Claude: fix roster rollback/coverage first, then prepare explicit Host/Join/Ready screen flow against copied views/capabilities. No fake connection/ready activity, unreachable settings or UI-only race activation. Read both ownership/contract docs before editing shared functions. No automatic agent-branch merge. Live-race integration follows the guarded adapter/flow; this checkpoint requests no download or manual test.

Actual racing authority/model/clocks remain proposed, roughly700ms measured RTT material; full socket recovery/scale/finish/feel/release gates remain open. Public WC3 distribution permission remains per-file unresolved where documented; project art-source direction unchanged.
