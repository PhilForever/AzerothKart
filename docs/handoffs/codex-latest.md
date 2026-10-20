# Codex handoff — first live window; targeted next trial

2026-10-21 01:13 CEST (Europe/Oslo). Existing `AzerothKart-Codex-Review`, branch `codex/network-window-akt722`, base `177e8f4`. Resolve final checkpoint with `git log -1 codex/network-window-akt722`.

## Scope and coordination

Docs/evidence only: sanitized AKT722 capture, endpoint CSV rows, evidence report, current network contracts/status, plain guide/checklist, ROADMAP, PROGRESS and this handoff. No runtime/renderer/physics/input/race/art changes. Claude still `1004e73`, vehicles reservation/untracked outputs intact; main/local origin/main `f923d15`, canonical `5570968`. No other checkout modified, no push/release/install/client automation.

## Verified advance

One completed `WHISPER_LOGGED` window: `AKT722`, 0.5 DATA/s, 16-byte DATA/ACK, 120-second schedule. 59 DATA accepted ->59 listener unique receipts ->59 ACKs accepted ->59 sender matches. Prefix raw0 and all actual send returns0; no reported rejection/duplicate/reordered DATA/timeout/late/outstanding/throttle/error. RTT n=59: median 697,p95 779,p99/max 881 ms. Listener gaps n=58:1995/2094/2124/max2124ms. A elapsed130s,B147.325s include local wait/drain; do not infer one-way delay.

[Evidence](../evidence/2026-10-21-akt722-network-window.md), `docs/experiments/AKT722-capture.json` and two endpoint-local CSV rows (one window, not two trials). Owner is A, friend B. Sender maps partly obscured, listener complete1–59 then absent60; no full sender bitmap transcription invented. Exact test UTC/build/interface/location/commit attestation unknown. Names/chat/screenshots not committed; attachment SHA hashes preserve correlation.

Only M2's two-client capability checkbox completed; higher-budget/recovery/architecture/gameplay/scale gates open. No numeric RTT threshold previously accepted; roughly 0.7–0.9s is a material design risk, not production racing approval.

## Executed checks and debt

- Independent screenshot/source review and counter reconciliation.
- Real Lua5.1 in-memory boundary reproduction: exact120s final callback60/60,missed0; +1microsecond or regular60 Hz offset1ms gives59/59,missed1,terminal60unattempted. Normal stops/no failures. Local scheduler limitation, not network loss or a measured client hitch. No runtime fix now; avoid forcing a friend reinstall for an accounting edge.
- Python capture/ledger consistency assertions PASS: raw-code/local-byte totals, complete listener maps, timing sample semantics and unknown metadata.
- Structural validator PASS61 paths/TOCs/links/60-column ledger; `git diff --check` PASS. No broad repeated runtime/UI matrix for docs-only change.

## Existing installation

Runtime **`8f66c5a`**, previously backed up/hash-verified 22/22. Prior docs177e8f4. Manifest `local-artifacts/install-backups/20261021-005314-298-f5ce5642e61b4729a8ed4e8b3d553eb0/install.json`; friend ZIP `local-artifacts/bundles/AzerothKart-forever-fix-8f66c5a.zip` still valid. No reinstall/reload needed for next trial. Before any future install, recheck both handoffs and actual target; do not overwrite newer agent work.

## Next single task

Same build, **reverse roles**: owner listens, friend starts within 20 seconds, fresh `AKT723`,2 DATA/s,128-byte DATA, 120 seconds. [Plain guide](../NETWORK_QUICK_START.md) has generic commands; final user response supplies actual names. Wait BOTH stopped; preserve both report/evidence outputs. Existing stop guards remain; do not rerun merely for239 instead of 240 planned opportunities. Nominal aggregate 4 calls/s,316 payload+prefix bytes/s before unknown overhead.

One combined direction/rate/size scenario replaces the full exploratory matrix for this immediate two-player candidate. It is not an isolated-cause experiment or four/eight-player approval. After reconciliation, perform short explicit reload/fresh-session recovery, then review live-race synchronization architecture. No broad engine before that evidence; multiplayer stays above ghosts.
