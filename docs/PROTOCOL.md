# Wire protocol v1 (design draft, NOT in current code)

## Critical constraint
`C_ChatInfo.SendAddonMessage` accepts at most 255 bytes, a 16-character prefix and can throttle. Enqueue success **does not** mean delivery. Room negotiation can use low-rate reliable ACKs; real-time movement may be impossible at desired player counts. Never broadcast frame-by-frame raw positions.

## Prefix
`AZKART1` (7 bytes), protocol `1`, mode `T` test / `L` lobby / `R` racing; version must be explicit inside payload. Distinguish and reject unknown versions.

## Proposed packet envelope
```text
1|L|roomId|senderSeq|type|payload
1|R|roomId|senderSeq|simTick|type|payload
```
- `roomId` = random/collision-checked short session token (not a secret credential).
- `senderSeq` per-sender monotonic for idempotence; wrap logic defined. Never trust payload `sender` over game event `sender`.
- `simTick` fixed 60Hz integer tick, with limited future/past window.
- `type`: `HELLO`, `INVITE`, `JOIN`, `WELCOME`, `READY`, `START`, `INPUT`, `SNAP`, `ACK`, `FINISH`, `LEAVE`, `ERROR`, `RESYNC`.
- For user-entered text, use `SendAddonMessageLogged` separately with readable content; never mix free text into raw binary.

## Protocol validation
1. `prefix` matches, event channel allowed, expected sender in party/room, length <=255 bytes, printable safe ASCII for initial version.
2. Decode bounded field lengths/integers, reject controls, oversized arrays, negative tick and NaN-like input.
3. Match known `roomId`, `trackHash`, `physicsVersion`, `kartClass`, `seed` before START.
4. Deduplicate by sender+seq+room; guard too-future/too-old ticks and unsolicited state.
5. Transport ack/resend only for control-plane (`INVITE`, `JOIN`, `READY`, `START`, `RESULT`), not spammy per-tick data.
6. Use ChatThrottleLib if compatible and necessary, or a tested bounded queue. Never implement uncontrolled resend loops.

## Candidate live sync (only after go/no-go)
- Lobby/counter/synced countdown are easy low-rate tasks.
- At room start, host selects seed, physics/track version, start tick and racer slots.
- Host receives compressed bounded input batches; applies reference physics; publishes aggregate low-rate snapshots to permitted group channel; clients predict locally and interpolate remote visuals.
- Each sender's packet budget and fan-out cost must be measured and enforced.
- For collisions/power-ups, authoritative host decisions are unavoidably trust-based; no anti-cheat guarantees. Reject implausible controls/positions, show unverified results if peers desync.
- Host leave: pause/abort/rehost via explicit fresh session, never silently appoint a different host to claim same results.
- If measured capacity poor: switch to asynchronous ghosts/time trial scores; do not pretend position snapshots create genuine fair multiplayer.

## Probe packet examples
```text
1|T|probe-a1|1|PING|n0001
1|T|probe-a1|2|PONG|n0001
1|L|room-b2|3|READY|1
```
Use game event sender identity, not a typed character name inside payload. All user-controlled data must be sanitized.
