# Manual network experiment — F4 (first lowest-rate window complete; gate open)

For the human-facing explanation and command order, start with [Connection test — you and a friend](../docs/NETWORK_QUICK_START.md), also summarized by `/akart net help` in-game. There is no GUI connection-test button. Print Probe is the separate driving-statistics report. The initial-window procedure below remains a reference; the next requested measurement is the single reverse window described first.

The branch implements a bounded opt-in **logged addon whisper** probe, not a multiplayer engine. The send API is explicitly `C_ChatInfo.SendAddonMessageLogged`, the receive event is `CHAT_MSG_ADDON_LOGGED`, and the native channel argument remains `WHISPER`. Use the ledger label **`WHISPER_LOGGED`** to distinguish it from unlogged addon messages. There is no fallback to `SendAddonMessage`, `CHAT_MSG_ADDON` or ordinary chat whispers.

IOU already established the basic logged route: on 2026-10-16, two live IOU 0.3.2 clients on Forever 1.60.1/build 70425 completed four exact ASCII/Norwegian UTF-8/239-byte/240-byte round trips. Live Shared payment, correction and settlement were also demonstrated. See IOU's `docs/connection-test.md` and `docs/manual-testing.md` evidence records. Do not repeat the basic four-message compatibility test as a prerequisite. These results do not measure sustained racing throughput, latency, loss, ordering or reconnect behavior.

**First window complete:** [AKT722 evidence](../docs/evidence/2026-10-21-akt722-network-window.md) records 0.5 DATA/s, 16-byte DATA and 120 configured seconds; both peers stopped with `window_complete`. The counts reconcile: 59 accepted DATA sends, 59 unique listener receipts, 59 accepted ACK sends and 59 matched sender ACKs. Rejection/duplicate/reorder/timeout/late/outstanding/throttle/error counters were zero, with numeric `0` prefix/send returns on both sides. Sender RTT had 59 samples (p50 697, p95 779, p99/max 881 ms); listener gaps had 58 (p50 1995, p95 2094, p99/max 2124 ms). Sender/listener elapsed was 130/147.325 seconds including different waiting periods. Exact build/interface/location/test UTC were not supplied; do not copy historical build 70450 into this run. One of 60 scheduled opportunities was unattempted at the local end boundary, not lost. Listener receipt/ACK maps show 1–59 then absent 60; owner map portions are obscured, so retain the count-reconciliation limitation. No numeric RTT threshold is accepted and this sample is not approval for live racing. Recovery/replication/scale gates remain open.

Claude's scenery/trike and Codex's probe were reviewed together on `codex/menu-integration`; the corrected existing build is `177e8f4` from `codex/forever-probe`. The earlier `Invalid numeric net argument` report was a command-parse refusal, not transport evidence. Keep the same corrected build on both clients for the next window; no reinstall is required for this documentation checkpoint. The [60-column CSV](../docs/experiments/network-ledger.csv) records measured evidence only. M0's deferred long manual matrix does not prohibit this focused experiment under ADR 0007; observe the probe's own stop guards.

## Next single measurement — reverse direction, NOT RUN

Reverse the AKT722 roles: **owner listens, friend starts**. Use fresh `AKT723` only if unused. Substitute full actual character names for these generic names; in this example owner is Amber Stone and friend is Birch Vale.

1. Owner types first:

   ```text
   /akart net listen "Birch Vale" AKT723 2 128 120
   ```

2. Within 20 seconds, friend types:

   ```text
   /akart net start "Amber Stone" AKT723 2 128 120
   ```

3. Let both reach `Stopped`, then both retain `/akart net report` and every `/akart net evidence` range before reloading or starting another session. Cancel with `/akart net stop` if needed; stop immediately on throttle, error, deadline, hitching or other disruption and preserve the reason. A local terminal missed opportunity alone is not a reason to rerun or claim loss.

This is one combined direction/rate/size scenario: nominal **2 DATA + 2 ACK calls/s**, 288 payload bytes/s plus 28 prefix bytes/s, **316 bytes/s before overhead**. It does not isolate which changed variable explains a difference. The schedule has 240 opportunities; actual attempted calls can be lower, including the known local final-slot boundary. Do not change the existing stop guards or require the full matrix before a bounded two-person candidate. Disconnect/reload recovery and a measured architecture decision remain open.

## Reference: first lowest-rate window procedure (AKT722 completed)

1. Use two real clients with consenting testers A and B. Stop any kart drive, remain out of combat, and record UTC time, exact full first names and surnames, location/instance, connection context, addon commit and each client's `/dump GetBuildInfo()` / `/dump WOW_PROJECT_ID` / selected TOC. Forever names have no realm suffix; use the full name used for whispers. Protect player identities in any approved published evidence. No public channel or unsolicited target.
2. On both clients, read the [capability and enum checks](../docs/CLIENT_API.md#transport-probe-api-contract-source-evidence-not-a-live-pass). These readbacks send nothing. Preserve absent/throwing/secret/unknown results and stop for review if the installed API contradicts the source-backed contract. Never coerce a result or guess that `true`/`nil` means success.
3. Choose a **fresh** six-character uppercase alphanumeric ID, for example `Q7M2K9` only if it has never been used for this experiment. Names below are placeholders: A is Amber Stone and B is Birch Vale. Keep the quotes around full names. On B, explicitly arm the listener for A's exact full event identity:

   ```text
   /akart net listen "Amber Stone" Q7M2K9 0.5 16 120
   ```

4. Within **20 seconds** after B arms, on A start DATA to B with matching ID/rate/size/duration. This leaves time for the first scheduled DATA at the default two-second interval before B's 30-second wait expires:

   ```text
   /akart net start "Birch Vale" Q7M2K9 0.5 16 120
   ```

   Unquoted full names are supported too, for example `/akart net listen Amber Stone Q7M2K9 0.5 16 120`. Optional arguments default to `0.5 16 120`; spelling all three makes evidence reproducible. Supported rates are `0.5`, `1`, `2`, `4` DATA/s; sizes are `16`, `64`, `128`, `220` bytes; duration is an integer from `10` to `120` seconds. B automatically ACKs each valid unique DATA once. It does not need to run `start` for a one-direction window. If either arm is refused, capture its reason and both reports; do not improvise different API semantics. Both peers must be armed before first DATA. There is no handshake proving the other peer's configuration, consent or identity.

5. Let the scheduled window and ten-second drain finish. No character movement automation, kart input or per-packet print command is needed. Any tester can cancel immediately with `/akart net stop`. Stop on client hitching or unrelated disruption. A sender's five-second missing-ACK deadline stops new DATA and allows the bounded drain; a failed/unknown/throwing/throttled API send stops immediately. Five seconds without unique valid DATA stops an active listener, but does not truncate normal drain. Senders use ACK deadlines rather than a generic traffic-idle rule. Sender drain expiry is anchored to the logical deadline/window end; a delayed callback does not grant another ten seconds. Record partial duration and reason; a stopped window is not a completed sustained-rate pass.
6. On **both** clients, print and copy the bounded report and sequence evidence, before arming anything else or reloading:

   ```text
   /akart net report
   /akart net evidence
   ```

   Preserve the full output from each client, session/configuration and stop reason. The seven-line report includes configuration/raw prefix result; DATA/ACK calls and accepted/failed/unknown results plus planned/missed slots; receive/ACK/deadline counts; throttle/error, `attemptedPayloadBytes`, `prefixBytes`, raw-code maps and `rejects={reason=count}`; RTT; arrival gaps; and an interpretation reminder. Rejection counters include wrong sender/session without printing identities. Evidence has at most twelve 160-character chunks plus its legend: `sent`, `received`, `acks_sent`, `acks_received`, each labelled `session=... seq=1..160` or the relevant range. Compare each direction separately. Do not turn an ACK timeout into a packet-loss claim.
7. Enter one reconciled result row per session/window/direction in the ledger only after both logs are available, recording channel/path `WHISPER_LOGGED`. Run the reverse direction as a **new ID and new window**, with A listening and B starting. No automatic rerun or escalation.

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

## Rate/size matrix — deferred reference, remaining cells NOT RUN

The exhaustive 16/64/128/220-byte × 0.5/1/2/4-DATA/s × direction matrix is deferred. AKT722 covers one lowest-rate, 16-byte direction; the next requested scenario is the reverse 2-DATA/s, 128-byte window above. Run additional cells only when a concrete remaining budget/transport uncertainty needs them, using a fresh ID per size/rate/direction. Simultaneous bidirectional DATA requires a later harness extension; two `start` peers are not a supported setup. A result at 0.5 does not establish 4 packets/s. Do not proceed to a higher rate if the earlier window throttles, errors, backlogs or disrupts the client; preserve evidence and flag the failed gate for owner review.

One ACK per unique DATA means a nominal one-direction rate `r` can produce `2r` messages/s across the pair. A future simultaneous bidirectional rate `r` per peer could produce `4r` total, before any later control-plane overhead; the current sender/listener modes do not implement that trial. Record actual calls, bytes, sizes and every participant. This probe has no PARTY mode, public room scan, multi-peer fan-out, retries or race-state stream.

## Recovery, scoping and lifecycle — all client checks NOT RUN

- Start a fresh 1-DATA/s, 64-byte window. After approximately 30 seconds, reload B. B returns inactive; A must stop new DATA at its deadline, retain a bounded drain/report and never retry or auto-restart. Copy A's report/evidence before its reload. Record that B's unsaved pre-reload counters were lost rather than inventing receiver totals. Explicitly arm both peers with a fresh ID after reload and record recovery time/context.
- Repeat as separate windows with B logging out/disconnecting for about 20 seconds, then A interrupted. Record actual interruption times, partial schedule, stop/drain reasons and fresh-session recovery. An observation of no old-session packet is not proof stale traffic can never arrive; offline rejection coverage is separate evidence.
- Check `/akart net stop`, entering combat, leaving world/instance, logout/reload and starting a kart drive. The probe must stop and never resume automatically. Copy available reports before counters are replaced. No new UI focus/capture API is part of transport testing.
- Coordinate a mismatched sender/session/parameter test only between the same consenting peers at the lowest rate; malformed, stale, out-of-range or wrong-length messages must not become ACK amplification or race commands. There is no security/authentication guarantee. A mismatch should stop under the normal timeout/idle cap, not retry forever.
- Observe duplicates/reorder if they occur; measured zero in one completed window does not guarantee delivery ordering. Mocked duplicate/reorder/accounting checks cannot establish actual client transport behavior.

## Remaining F4 gate and decision record

The full scope additionally needs actual PARTY behavior/fan-out, sustained realistic connection contexts, structured gameplay latency/correction acceptance and later four/eight-client trials only with consenting testers and a separate aggregate budget. PARTY/4/8 and the exhaustive matrix are deferred expansion gates, not mandatory prerequisites to preparing a bounded two-person candidate. Recovery, a measured candidate budget and the architecture ADR remain open. Expanded capacity and live-race behavior are **not implemented or passed by this two-peer logged-WHISPER harness**. Do not multiply two-client results to claim eight-player capacity.

Keep planned tests in this checklist rather than fake zero ledger rows. Raw return maps can be JSON text in quoted CSV fields; correlate sender/receiver evidence by ID and direction. Document the sustainable measured budget, uncertainties and an ADR **before** selecting production replication. Later real-race trials must record correction/teleport/collision/finish disagreements and handling ratings. Under [ADR 0010](../docs/adr/0010-multiplayer-release-priority.md), inadequate transport requires owner review; ghosts/time trials are deferred alternatives, not the accepted release target.
