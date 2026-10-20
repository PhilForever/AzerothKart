# Manual network experiment — F4 (probe prepared; transport windows NOT RUN)

For the human-facing explanation and command order, start with [Connection test — you and a friend](../docs/NETWORK_QUICK_START.md), also summarized by `/akart net help` in-game. There is no GUI connection-test button. Print Probe is the separate driving-statistics report. The compatibility readbacks below still precede the first actual arm on both clients.

The branch implements a bounded opt-in `WHISPER` probe, not a multiplayer engine. **No actual transport measurements are recorded.** Claude's scenery/trike and Codex's probe are reviewed together on `codex/menu-integration`. Install that combined source on both clients; serialize deployment and retain backups. The owner confirmed only one client is available on 2026-10-20, so the first window remains NOT RUN. The [60-column CSV](../docs/experiments/network-ledger.csv) stays header-only until real measurements exist. M0's deferred long manual matrix does not prohibit this focused experiment under ADR 0007; observe the probe's own stop guards.

## Two consenting testers: first window

1. Use two real clients with consenting testers A and B. Stop any kart drive, remain out of combat, and record UTC time, exact full character names/realms, location/instance, connection context, addon commit and each client's `/dump GetBuildInfo()` / `/dump WOW_PROJECT_ID` / selected TOC. Protect player identities in any approved published evidence. No public channel or unsolicited target.
2. On both clients, read the [capability and enum checks](../docs/CLIENT_API.md#transport-probe-api-contract-source-evidence-not-a-live-pass). These readbacks send nothing. Preserve absent/throwing/secret/unknown results and stop for review if the installed API contradicts the source-backed contract. Never coerce a result or guess that `true`/`nil` means success.
3. Choose a **fresh** six-character uppercase alphanumeric ID, for example `Q7M2K9` only if it has never been used for this experiment. Names below are placeholders. On B, explicitly arm the listener for A's exact full event identity:

   ```text
   /akart net listen TesterA-Realm Q7M2K9 0.5 16 120
   ```

4. Within **20 seconds** after B arms, on A start DATA to B with matching ID/rate/size/duration. This leaves time for the first scheduled DATA at the default two-second interval before B's 30-second wait expires:

   ```text
   /akart net start TesterB-Realm Q7M2K9 0.5 16 120
   ```

   Optional arguments default to `0.5 16 120`; spelling all three makes evidence reproducible. B automatically ACKs each valid unique DATA once. It does not need to run `start` for a one-direction window. If either arm is refused, capture its reason and both reports; do not improvise different API semantics. Both peers must be armed before first DATA. There is no handshake proving the other peer's configuration, consent or identity.

5. Let the scheduled window and ten-second drain finish. No character movement automation, kart input or per-packet print command is needed. Any tester can cancel immediately with `/akart net stop`. Stop on client hitching or unrelated disruption. A sender's five-second missing-ACK deadline stops new DATA and allows the bounded drain; a failed/unknown/throwing/throttled API send stops immediately. Five seconds without unique valid DATA stops an active listener, but does not truncate normal drain. Senders use ACK deadlines rather than a generic traffic-idle rule. Sender drain expiry is anchored to the logical deadline/window end; a delayed callback does not grant another ten seconds. Record partial duration and reason; a stopped window is not a completed sustained-rate pass.
6. On **both** clients, print and copy the bounded report and sequence evidence, before arming anything else or reloading:

   ```text
   /akart net report
   /akart net evidence
   ```

   Preserve the full output from each client, session/configuration and stop reason. The seven-line report includes configuration/raw prefix result; DATA/ACK calls and accepted/failed/unknown results plus planned/missed slots; receive/ACK/deadline counts; throttle/error, `attemptedPayloadBytes`, `prefixBytes`, raw-code maps and `rejects={reason=count}`; RTT; arrival gaps; and an interpretation reminder. Rejection counters include wrong sender/session without printing identities. Evidence has at most twelve 160-character chunks plus its legend: `sent`, `received`, `acks_sent`, `acks_received`, each labelled `session=... seq=1..160` or the relevant range. Compare each direction separately. Do not turn an ACK timeout into a packet-loss claim.
7. Enter one reconciled result row per session/window/direction in the ledger only after both logs are available. Run the reverse direction as a **new ID and new window**, with A listening and B starting. No automatic rerun or escalation.

The default schedule has 60 DATA opportunities in 120 seconds; 1/2/4 packets/s have 120/240/480 respectively. Hitches/cancel/failure can reduce actual calls. The implementation does not send catch-up bursts to manufacture the planned count. Exact DATA bytes include the envelope; ACK is always 16 bytes. `attemptedPayloadBytes` sums DATA+ACK payload bytes; `prefixBytes` is `7 * (DATA calls + ACK calls)`. Neither includes unmeasured transport overhead or measures actual network bandwidth. Preserve the CSV `aggregate_attempted_bytes` **payload-only** definition and declare the prefix estimate separately in reconciliation notes.

## Counter definitions and reconciliation

`seconds` is the configured DATA schedule. `elapsedSeconds` is the local arm-to-last-accounting interval, frozen at stop and including listener waiting/drain where applicable; it is not a substitute for the DATA schedule's actual start/stop observations or an independent timer. Record both and the stop reason, especially for partial or hitched windows.

| Evidence | Meaning |
|---|---|
| DATA/ACK attempts | Actual send API calls by class, including failed/unknown/throwing calls; not the number of schedule opportunities. |
| Local accepted/failed/unknown results | Source-matched enum classification plus raw code counts; accepted means local API acceptance, not receipt by the peer. Throws are retained as send errors. |
| Throttle events | Source-matched `AddonMessageThrottle` or `ChannelThrottle`; stop rather than silently retry. |
| ACK burst guard | Four-token capacity replenished at four ACK/s. `ack_rate_limit` stops before an excess ACK call; this local guard is not evidence that the API's throughput gate failed. |
| Receive total/rejections | Matching-prefix events and bounded rejection reasons such as sender/channel/session/version/type/size/padding/sequence. Unrelated prefixes are outside this count. |
| Unique DATA / duplicates | First valid receipt per sequence / additional valid receipt of the same sequence; duplicates get no further ACK. |
| Reordered unique DATA | First receipt below the previously highest unique sequence; distinct from duplicates. |
| Matched unique ACK | First valid ACK for an accepted original DATA send from the scoped event sender. |
| Deadline timeout / late ACK | Still outstanding at the five-second deadline / first match arriving after that deadline. A late ACK does not erase the recorded timeout. |
| Outstanding after drain | Accepted DATA still missing a matched ACK at the final observed stop; not proven DATA loss. |
| RTT | ACK receive time minus that same client's original DATA send-call time; local monotonic clock only. Includes queue/peer handling; not one-way latency. |
| Arrival gap | Same receiver's interval between valid unique DATA receipts; duplicates do not add a sample. |

The sequence bitmaps cover at most 480 positions. In `sent`/`acks_sent`, `1` means locally accepted, `f` failed, `u` unknown and `.` unattempted. In `received`, `1` means valid DATA seen; in `acks_received`, `1` means matching ACK received; `.` means absent in each receipt map. These are sequence-indexed strings, not binary integers. Copy every labelled range in order, retaining gaps.

Reconcile A's accepted `sent` set with B's `received` set for A→B; compare B's accepted `acks_sent` with A's `acks_received` for the return path. Repeat the opposite direction in its own fresh window. A set difference is **not observed at the receiver within this recorded window**, subject to complete logs, source/return semantics and cancellation. B's DATA receipt without A's matched ACK points to the reverse path/ACK processing, not forward DATA loss. Preserve late/stale receipts and window endpoints. Do not combine both directions into a single unexplained loss percentage.

RTT and arrival-gap percentiles use sorted samples and **nearest rank**, rank `ceil(p * n)`, with sample count and maximum. No samples means `NA`/blank, never a measured 0 ms. Subtract no timestamps from separate clients. Redact names only after correlating the two local logs; keep non-secret session/sequence evidence usable.

## Rate/size matrix — future measured windows, all NOT RUN

Run each 16/64/128/220-byte DATA size at 0.5, 1, 2 and 4 DATA packets/s for 120 seconds, beginning at 0.5. Use a new ID per size/rate/direction. Complete A→B then B→A. Simultaneous bidirectional DATA requires a later harness extension; two `start` peers are not a supported setup. A result at 0.5 does not establish 4 packets/s. Do not proceed to a higher rate if the earlier window throttles, errors, backlogs or disrupts the client; preserve evidence and flag the failed gate for owner review.

One ACK per unique DATA means a nominal one-direction rate `r` can produce `2r` messages/s across the pair. A future simultaneous bidirectional rate `r` per peer could produce `4r` total, before any later control-plane overhead; the current sender/listener modes do not implement that trial. Record actual calls, bytes, sizes and every participant. This probe has no PARTY mode, public room scan, multi-peer fan-out, retries or race-state stream.

## Recovery, scoping and lifecycle — all client checks NOT RUN

- Start a fresh 1-DATA/s, 64-byte window. After approximately 30 seconds, reload B. B returns inactive; A must stop new DATA at its deadline, retain a bounded drain/report and never retry or auto-restart. Copy A's report/evidence before its reload. Record that B's unsaved pre-reload counters were lost rather than inventing receiver totals. Explicitly arm both peers with a fresh ID after reload and record recovery time/context.
- Repeat as separate windows with B logging out/disconnecting for about 20 seconds, then A interrupted. Record actual interruption times, partial schedule, stop/drain reasons and fresh-session recovery. An observation of no old-session packet is not proof stale traffic can never arrive; offline rejection coverage is separate evidence.
- Check `/akart net stop`, entering combat, leaving world/instance, logout/reload and starting a kart drive. The probe must stop and never resume automatically. Copy available reports before counters are replaced. No new UI focus/capture API is part of transport testing.
- Coordinate a mismatched sender/session/parameter test only between the same consenting peers at the lowest rate; malformed, stale, out-of-range or wrong-length messages must not become ACK amplification or race commands. There is no security/authentication guarantee. A mismatch should stop under the normal timeout/idle cap, not retry forever.
- Observe duplicates/reorder if they occur; measured zero in one completed window does not guarantee delivery ordering. Mocked duplicate/reorder/accounting checks cannot establish actual client transport behavior.

## Remaining F4 gate and decision record

The full gate additionally needs actual PARTY behavior/fan-out, sustained realistic connection contexts, structured gameplay latency/correction acceptance and later four/eight-client trials only with consenting testers and a separate aggregate budget. Those are **not implemented or passed by this two-peer WHISPER harness**. Do not multiply two-client results to claim eight-player capacity.

Keep planned tests in this checklist rather than fake zero ledger rows. Raw return maps can be JSON text in quoted CSV fields; correlate sender/receiver evidence by ID and direction. Document the sustainable measured budget, uncertainties and an ADR **before** selecting production replication. Later real-race trials must record correction/teleport/collision/finish disagreements and handling ratings. Under [ADR 0010](../docs/adr/0010-multiplayer-release-priority.md), inadequate transport requires owner review; ghosts/time trials are deferred alternatives, not the accepted release target.
