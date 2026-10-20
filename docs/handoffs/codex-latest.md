# Codex handoff — AKT723 complete; short reload recovery next

2026-10-21 01:32+02:00 (Europe/Oslo). Existing Codex Review worktree, branch `codex/network-window-akt723`, base `400590e`; resolve final checkpoint with `git log -1 codex/network-window-akt723`.

## Scope and coordination

Docs/evidence only: AKT723 sanitized capture/report and two endpoint ledger rows; network status/contracts/roadmap, quick guide/checklist, PROGRESS and this handoff. No runtime/rendering/physics/input/track/race/art edits, client automation, deployment, push or release. Main/local origin/main `f923d15`, canonical checkout `5570968`. Claude independently advanced to `abe98f6` (four karts/selector/untinted art); not reviewed or integrated here. Preserve that work and untracked outputs. Before any future installation, read both handoffs and compare the actual target; this turn did not reverify the installed tree.

## Verified result

[AKT723](../evidence/2026-10-21-akt723-network-window.md): owner A listens, friend B sends. 2 DATA/s,128-byte DATA,16-byte ACK,120 seconds. Both window_complete:240 DATA accepted/unique received,240 ACK accepted/matched, numeric prefix/send0; no reported failed/unknown/error/throttle/reject/duplicate/DATA reorder/timeout/late/outstanding/missed slots.

B RTT n240: median 701,p95 771,p99 913,max 1012 ms. A gaps n239:500/551/667/max767ms. A elapsed134.788s,B130s include local waits/drain. Payload A3840/B30720; prefix1680each;37920bytes/120s=316payload+prefixB/s before unknown overhead. No packet-per-frame or participant-capacity claim.

Owner reports different zones, ungrouped and US beta servers; do not turn that context into a measured latency-cause claim. Exact build/interface/test UTC/commit attestation unknown. Expected probe source8f66c5a, not independently attested by screenshots. Partial map occlusion retained; complete1–240 sets are inferred from bounded240unique counters, not raw-map transcription. See `docs/experiments/AKT723-capture.json` and four endpoint-local CSV rows across two windows. No player names/chat/screenshots committed; attachment SHA hashes retained.

Only demonstrated capability and two-client directed budget samples are checked. Reload/fresh-session recovery, architecture, live racing and scale remain open. Approximately 700 ms median RTT requires careful synchronization; no accepted numeric RTT threshold or production GO exists.

## Executed validation

- Independent screenshot/capture/guide review: no blocking issue.
- Python consistency assertions PASS: roles/counters, byte/prefix/raw-code totals, timing/NA semantics,316B/s arithmetic, unknown metadata, null obscured maps and four60-column ledger rows.
- Structural validator PASS61 paths/TOCs/links/ledger; git diff --check PASS. No runtime test matrix rerun for docs-only changes.
- No recovery experiment executed yet. No invented zero rows.

## Next single task

[Plain recovery guide](../NETWORK_QUICK_START.md). Existing probe; no new download. Last verified installation was8f66c5a with22files and backup manifest `local-artifacts/install-backups/20261021-005314-298-f5ce5642e61b4729a8ed4e8b3d553eb0/install.json`; friend ZIP `local-artifacts/bundles/AzerothKart-forever-fix-8f66c5a.zip` remains the prior probe package, not a package of Claude's new work.

1. Friend listens, owner starts within 20seconds: fresh AKT724,2 DATA/s,128 bytes,20seconds. Friend reloads5seconds after owner Arms. Friend returns Idle; owner naturally stops at ACK deadline/drain. Save OWNER report BEFORE any fresh arm. Preserve unexpected errors/reasons; no guessed success. Friend's unsaved pre-reload counters are lost.
2. Friend listens, owner starts: fresh AKT725,same2/128,10seconds. Let both stop normally, retain BOTH reports. Sequence evidence optional if counts disagree.

This is addon reload/fresh rearming, not a full socket-disconnect test. After evidence review, decide the bounded first two-player synchronization architecture; no broad engine before recovery evidence. PARTY/4/8/fullmatrix remain deferred expansion, not secretly passed. Multiplayer remains ahead of ghosts.
