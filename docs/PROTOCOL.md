# Probe wire format and future race protocol

**Current branch:** a bounded, explicitly armed two-client `WHISPER` experiment. Actual Forever prefix registration, sends/receives, throughput, latency and reconnect checks are **NOT RUN**. This probe does not implement rooms, invites, kart replication or a selected production transport. See [the manual sequence](../tests/MANUAL_NETWORK_CHECKLIST.md) and [client API evidence](CLIENT_API.md#transport-probe-api-contract-source-evidence-not-a-live-pass).

## Implemented experiment envelope

Prefix: `AZKART1` (7 bytes). Each message is printable ASCII, with this exact 10-byte envelope followed by `.` padding:

```text
1DABC12301......
1AABC12301......
```

| Bytes | Meaning |
|---|---|
| 1 | Protocol version `1`. |
| 2 | `D` DATA or `A` ACK. No other packet types. |
| 3–8 | Fresh six-character uppercase alphanumeric experiment session ID, here `ABC123`. Not a password. |
| 9–10 | Two uppercase base-36 sequence characters, starting `01`; valid session range is 1 through the configured schedule, at most 480. No wrapping. |
| 11 onward | Literal `.` padding only. Exact DATA lengths are 16, 64, 128 or 220 bytes **including the envelope**; ACKs are always 16 bytes. Prefix bytes are additional. |

DATA is acknowledged once per unique valid sequence. Duplicates are counted without another ACK; an ACK is never acknowledged. An ACK token bucket replenishes at four tokens/s with capacity four; exhaustion stops the probe with `ack_rate_limit`, rather than queuing or flooding ACKs. This is a local burst guard, not a measured transport-capacity verdict. There are no retries, packet timestamps, arbitrary text, kart coordinates or identity claims inside the payload. RTT uses the sender's own stored send-call time, not a clock supplied by a peer.

Both testers explicitly arm the same session, packet rate, size and duration. A listener ACKs but sends no DATA. A starter sends DATA and accepts matching ACKs; it does not receive DATA. Test the reverse direction in a fresh, separate window. Simultaneous bidirectional DATA would need a later extension, not two starters with this implementation. Validate the event prefix, `WHISPER` channel, exact expected full `Name-Realm` event sender (ASCII case folding only), session, version/type, sequence range, length and padding before accepting a packet. Non-ASCII spelling must match exactly; no Unicode case folding or realm normalization is claimed. Text in a payload cannot override the event sender. This is peer scoping, **not authentication or anti-cheat**; a peer can modify its addon.

## Bounds and lifecycle

- Accepted DATA rates: 0.5, 1, 2 or 4 packets/s; payloads: 16, 64, 128 or 220 bytes; duration is an integer from 10 to 120 seconds. Defaults are 0.5 packets/s, 16 bytes and 120 seconds. At most 480 DATA sequences per participant/window.
- Send at most one due DATA packet per update; overdue schedule slots do not become a catch-up burst. Scheduled opportunities and actual API calls are distinct evidence.
- No ACK beyond the first valid DATA receipt per sequence. A nominal one-direction 4-DATA/s window can still generate 4 ACK/s in the opposite direction; the unique-sequence bound is not a claim that incoming delivery cannot bunch ACKs. A future bidirectional 4-DATA/s per participant experiment could total 16 DATA+ACK messages/s across both participants; prefix bytes and all participants count toward the budget.
- A missing ACK at its five-second deadline stops new DATA and starts a ten-second drain. Sender drain bounds are anchored to the logical ACK deadline or configured window end, not the time of a late/resumed callback. Record the deadline-time timeout even if an ACK arrives later; late matches do not erase it. Failed, unknown-result, throwing or throttled send attempts stop immediately. There is no automatic restart or rate escalation.
- A listener waits at most 30 seconds for first DATA; its bounded receive window then uses the configured duration plus normal drain. Five seconds without unique valid DATA stops an active listener; this idle rule does not apply during normal drain. Senders use ACK deadlines, not a generic peer-traffic idle check. Manual Stop, combat, leaving world, logout/reload, starting a drive and invalid/backwards clock observations stop the probe; no automatic resume.
- A fresh ID is required per window. Up to 64 locally used IDs reject reuse within the current addon lifetime; after the 64-session cap, reload is required. Reload clears that memory and does not make an old ID safe to reuse.
- Prefix registration occurs only on explicit arm, with guarded source-matched enum semantics. The probe reuses the existing Core frame and does not capture input, allocate UI objects per packet or print per-packet chat.

Missing ACKs are not proven DATA loss. Reconcile the two clients' unique DATA and ACK evidence after the observation/drain window. Preserve raw API return-code counts: local enqueue acceptance is not delivery. Reports/evidence are explicit commands and remain in memory until the next experiment/reload; no automatic CSV/SavedVariables export is implied. Evidence contains four sequence maps (`sent`, `received`, `acks_sent`, `acks_received`), each at most 480 positions, printed in chunks of at most 160. Output contains the public experiment ID but no configured peer identity.

Report `attemptedPayloadBytes` sums attempted DATA+ACK payload bytes only; `prefixBytes` is `7 * (DATA calls + ACK calls)`. Neither includes unmeasured transport overhead or establishes actual network bandwidth. The summary/CSV `aggregate_attempted_bytes` retains the payload-only definition; document prefix estimates separately. The fixed rejection-reason map includes counts for scoped failures such as sender/session without printing peer identities.

## Production protocol — design draft, not implemented

The following is a separate design space. Do not parse the compact probe envelope as lobby or race packets, and do not treat the probe's caps as measured production capacity. Actual payload limits and result semantics require the Forever checks; the experiment deliberately stays below the commonly documented 255-byte payload ceiling.

Possible future room/race envelopes include an explicit version/mode, session, monotonic sender sequence and bounded simulation tick:

```text
1|L|roomId|senderSeq|type|payload
1|R|roomId|senderSeq|simTick|type|payload
```

Future validation must include authorized room membership, event sender identity, channel, total length, bounded fields/integers, track/physics compatibility, seed, duplicate/stale handling and finite past/future tick windows. Reliable control-plane messages may need a measured bounded ACK/retry policy; movement must not create uncontrolled retries or per-frame broadcasts. User-entered text, if implemented, needs a separate appropriate logged/plain-text path and sanitization; the current probe sends no such text.

A candidate predicted-local/remote-interpolated race with low-rate aggregate host snapshots is **not selected**. Measure two-client capacity, ordering, latency, loss reconciliation and reconnect first, then record an architecture ADR. PARTY fan-out, four/eight-client capacity, race corrections and finish adjudication are separate gates. Host authority is trust-based and cannot provide counterfeit security guarantees. Under [ADR 0010](adr/0010-multiplayer-release-priority.md), inadequate live transport requires owner review; asynchronous ghosts are not an automatic substitute for the multiplayer release target.
