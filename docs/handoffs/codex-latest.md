# Codex handoff — recovery verified; race-control codec implemented

2026-10-21 07:00+02:00 (Europe/Oslo). Existing Codex Review worktree, branch `codex/two-player-control`, base `47f43bd`. Resolve final implementation commit with `git log -1 codex/two-player-control`.

## Scope and coordination

New pure RaceProtocol + focused tests; both TOCs, runner and validator; recovery captures/ledger/evidence; network contracts/status/ADR0013 and this handoff. No Physics/Input/Race/UI/Presentation/art or TransportProbe/Core behavior changes. No installation, client automation, push or release. Main/local origin/main `f923d15`; canonical checkout `5570968`. Claude `b0b1f2e`/roster `abe98f6` remains unintegrated with its installation held, reservation released and untracked outputs preserved. Read its actual handoff before later review/integration; no automatic merge authorized by this checkpoint.

## Verified recovery

[AKT724/725 report](../evidence/2026-10-21-akt724-akt725-recovery.md). AKT724:33accepted DATA,22matched ACKs,11timeout/outstanding; stopped ack_deadline after listener reload, elapsed26.522s. Friend screenshot post-reload Idle. Exact reload time and pre-reload listener counters unavailable. Seven later planned opportunities unattempted after abort, reported missedSlots0; no forward-loss inference. AKT725 fresh explicit session:19accepted DATA/unique receipts/accepted ACKs/matches, normal completion and no failures; one local unattempted opportunity, sequence IDs unknown. Owner RTT median700/p95/max738ms; listener gaps median491/p95/max660ms. Full socket disconnect, automatic rejoin and recovery seconds are not verified.

Two sanitized JSON captures and three new endpoint rows bring ledger to seven rows/four windows. Metadata gaps retained, no screenshots/names/chat committed. Attachment SHA hashes correlate private originals. Earlier cross-zone/ungrouped/US context is owner-reported, not a measured latency cause.

## Implemented now

`AK.RaceProtocol`: VERSION=2, PREFIX=AZKART2, MAX_BYTES=128, MAX_SEQUENCE=46655. `encode(message)` / `decode(payload)` return a packet/table or nil plus a fixed error code. Common fields kind/session/sequence; six control kinds INVITE/JOIN/READY/START/CANCEL/ACK, exact 11–23-byte packets and strict integer/type/track/reason/alphabet/length checks. Borrowed inputs never mutated; unknown fields/metatables rejected, future numeric compatibility versions preserved for later refusal, ACK-of-ACK rejected. [Full contract](../API_CONTRACTS.md#implemented-pure-race-control-codec).

Both TOCs load the pure codec before the unchanged measurement probe (15 modules total). No prefix registration, event subscription, network calls, controller, retry scheduler, clock mapping, multiplayer menu or playable peer race exists in this codec. UI pool remains 10/151/13 on our unchanged rendering base. No new user download requested for a codec-only slice.

## Executed checks

- Before interruption: Lua5.1+5.4 codec tests PASS,36files parsed each (`--runtime both --tests race_protocol`); Lua5.1 probe/UI regressions PASS (`--tests transport_probe ui`). Runtime source unchanged since those checks; no broad repeated matrix on resume.
- Independent codec review found no actionable defect. Recovery evidence consistency assertions PASS, including unknown timing/counters and seven60-column rows.
- Final structural validator PASS63paths, TOC order, links and ledger; whitespace check PASS. Initial missing unfinished-ADR references were resolved before final validation.
- AZKART2 actual registration/traffic, reliable session behavior, full disconnect, simultaneous streams, race corrections/feel and expanded scale NOT RUN.

## Next single task

Under [ADR0013](../adr/0013-two-player-experiment-scope.md), implement pure PeerSession invite/join/ready/start state machine with injected time, idempotent duplicates, scoped sequences/session/compatibility, bounded queues/retries/timeouts. Keep the working pair ceilings4 API calls/s and316payload+prefixB/s distinct and count all ACK/retry/control traffic. They are exercised schedule ceilings, not measured maxima. No further manual probe requested now; transport/menu and renderer integration follow as separately reviewed slices.

Production replication/authority/clocks remain proposed, not approved; no codec-only completion of M2's reliable control-plane criterion. Existing installed runtime remains the previously verified 8f66c5a, not this new source. Before any future combined install, compare both handoffs/live hashes and preserve all roster/effects/results changes.
