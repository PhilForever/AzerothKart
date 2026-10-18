# Manual network experiment — F4 (future probe, NOT RUN)

**No transport probe or automatic traffic is implemented.** This plan and [the header-only CSV ledger](../docs/experiments/network-ledger.csv) prepare measurement. They do not establish multiplayer support. Complete M0 client safety first, then implement a small opt-in probe as a separate task before sending anything.

## Preconditions and bounded experiment

- [ ] Two real clients, both testers consenting to explicit start/stop; record build/interface/TOC, date, location, channel and connection context on each.
- [ ] Read API availability with `CLIENT_API.md`; inspect actual prefix-registration return and send return/enum values when the probe exists. Preserve raw codes, including nil/false/error, rather than guessing which means success.
- [ ] Private `WHISPER` between expected event senders first; test `PARTY` separately in a real group. No public chat, room discovery, unsolicited invites, continuous background traffic or live kart replication.
- [ ] Use `AZKART1`, a fresh non-secret session ID and bounded sequence IDs; validate prefix, version, channel, session, event sender and total payload size. Old-session/malformed/unknown-sender traffic is rejected and counted.
- [ ] Exactly 16/64/128/220 bytes **including the probe envelope**, measured from the actual encoded Lua string. The future codec must fit its envelope in 16 bytes before this matrix is feasible; do not report a 16-byte body as a 16-byte message.

One possible **experiment-only draft** is a compact printable envelope with version, six-character collision-checked session ID, two base-36 sequence characters and packet type, padded to exact length. A session window at 4 data packets/s for 120 seconds needs 480 sequences, within two base-36 digits. This is not a selected production protocol, authentication or a committed codec. Session collisions/stale packets still need validation.

Test every payload at 0.5, 1, 2 and 4 **data packets/s** for **120 seconds per window**, starting with 0.5. Start each rate/payload/direction window with a fresh session. Run A→B, then B→A; only then run bidirectional windows. A 120-second window schedules 60/120/240/480 data attempts respectively. Do not retry baseline data packets: retries would obscure natural timeout/order observations.

Use one bounded ACK per valid data packet, no ACK-of-ACK, no per-packet chat prints and no automatic rerun. ACKs, control messages and all participants count toward aggregate sends/bytes. With one ACK per data packet, a unidirectional data rate r implies up to 2r total messages/s across both clients; bidirectional data rate r **per client** implies up to 4r total. Record actual ACK sizes, channel/target, attempts and returned results. Delayed ACK work must remain bounded and stop on cancel/reload; no infinite retry queue.

Use a recorded ACK deadline (initial experiment: 5 seconds), then stop DATA and allow a 10-second ACK drain. Record late ACKs and final outstanding sequences separately. Stop escalation if throttle/errors, sustained backlog, client hitching or unrelated game disruption occurs; record the partial window/duration and do not claim the planned rate was sustained. A result at 0.5 does not authorize assuming 4 works.

## Counter definitions

| Field | Meaning |
|---|---|
| data_attempts / ack_attempts | Actual send API calls by packet class, including failed/throwing calls; scheduled-but-not-called attempts are separate |
| enqueue results / throttle | Raw return code counts and thrown errors per class; success means local acceptance only after actual semantics are verified |
| rx_total / rx_unique | Receiver's observed matching-prefix events / valid first receipt for expected session+event sender+sequence |
| rx_rejected | Wrong session/version/sender/channel/size/syntax; retain bounded reason counters |
| duplicates | Additional valid receipt of an already seen sender/session/sequence; does not increase unique count |
| reordered_unique | First valid receipt whose sequence is below the previously received highest sequence for that sender/session |
| ack_matched_unique | Sender receives first valid ACK matching its original outstanding data sequence from expected event sender |
| ack_timeouts / late_acks | Accepted sends still without matched ACK at recorded deadline / first matching ACK after deadline; preserve deadline-time count after late arrivals |
| outstanding_after_drain | Accepted sends still without ACK after DATA stop plus drain; not proven data loss |
| RTT | Sender-local monotonic receive-ACK time minus that same sender's original send-call time; includes local queue/peer ACK processing |
| arrival gaps | Receiver-local monotonic interval between valid unique data receipts; report p50/p95/p99/max and sample count |

Keep accepted, failed and unknown-semantics sends separate. Receiver reconciliation (what unique sequences B saw versus A's accepted sends) is required to estimate missing data. ACK timeout alone conflates forward loss, reverse ACK loss, late delivery, local queue/throttle, cancellation and peer interruption. Do not label it packet loss without this reconciliation and a declared observation window. Never subtract timestamps from different clients' clocks. RTT is not one-way latency.

For RTT/gap percentiles record sample count and method (initial plan: nearest-rank sorted samples). No sample means blank/NA, not zero milliseconds. A repeated sequence receipt is not a new timing sample. Store bounded raw evidence locally with event sender identities redacted before any approved publication.

## Recovery and order experiments

- [ ] Record regular steady-state windows before any interruption; distinguish channels and cities/instances.
- [ ] During a separate 1-data-packet/s, 64-byte window, reload B after 30 seconds. A stops the interrupted session after its timeout; no unbounded ACK/retry backlog. B returns inactive. Start a fresh explicit session and sequence space; late old-session packets must be rejected.
- [ ] Repeat with B disconnecting/logging out for 20 seconds, then reconnecting; repeat with A interrupted. Record actual interruption times locally, drain policy, timeout counts, stale rejections and fresh-session recovery time.
- [ ] Test normal world/instance transition and opening chat without kart focus; probe controls must remain responsive, with no interference with character movement or protected APIs.
- [ ] Compare data/ACK sequence evidence for duplicates/reorder. Natural non-occurrence is a measured zero only for that completed window; it is not proof ordering is guaranteed. Synthetic reorder/duplicate unit tests belong in a separate future test suite.
- [ ] Four/eight-client trials require actual consenting clients and a separate aggregate budget including every sender/ACK/fan-out. Do not multiply two-client results to claim capacity.

## CSV and decision record

Create **one result row per session/window/direction**, correlating both clients' evidence by run ID. The CSV is intentionally header-only until measurements exist. Raw return-code maps can be JSON text inside a quoted CSV field. Planned-but-unrun tests remain in this checklist; do not insert fake zero rows. Record actual duration and stop reason when a window ends early.

Reconcile sender/receiver logs, document a sustainable aggregate budget and record an ADR before choosing replication architecture. No transport result alone establishes playable racing. Later live-race trials require both players' handling/correction ratings, correction/teleport/collision/finish disagreements and repeated structured play under the measured budget. If capacity or recovery is inadequate, choose ghost/time-trial exchange explicitly; do not market local simulated rivals as live players.
