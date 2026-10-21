# ADR 0013 — Proceed with a bounded two-player experiment

Status: Accepted implementation scope, 2026-10-21. This approves the control-protocol foundation and a later two-peer candidate; it does not select production replication or approve a release.

## Evidence

- [AKT722](../evidence/2026-10-21-akt722-network-window.md): 59 attempted DATA/ACK round trips completed at 0.5 DATA/s with 16-byte messages. One terminal schedule opportunity was not attempted locally.
- [AKT723](../evidence/2026-10-21-akt723-network-window.md): 240 attempted DATA/ACK round trips completed at 2 DATA/s,128-byte DATA and16-byte ACK over120 seconds, without reported errors/throttles/timeouts. RTT median701ms,p95771ms,max1012ms. The owner reports different zones, no group and US beta hosting; those observations do not isolate latency causes.
- [AKT724/AKT725](../evidence/2026-10-21-akt724-akt725-recovery.md): listener addon reload returned Idle; the remaining sender stopped at its ACK deadline with33 accepted sends,22 matched ACKs and11 outstanding/timeouts. A fresh explicit session completed19 attempted round trips. Exact reload timing and the listener's pre-reload counters were not captured.

This is sufficient to build the next small experimental control unit. It is not evidence of full socket-disconnect recovery, automatic rejoin, simultaneous bidirectional DATA, playable race synchronization or four/eight-player capacity. No further standalone manual probe is requested at this checkpoint.

## Accepted scope and constraints

1. Begin with exactly two explicitly selected peers using the verified `SendAddonMessageLogged` / `CHAT_MSG_ADDON_LOGGED` route. Preserve full native first-name/surname scoping; grouping or co-location is not required by the observed route. Do not discover/spam other players.
2. Treat **four aggregate API calls/s and316 payload-plus-prefix bytes/s** as separate working ceilings for a future candidate, including control, ACKs and retries. This is an exercised schedule, not measured maximum capacity. Per-peer distribution and simultaneous traffic must still be checked in the candidate. Count the7-byte prefix per call and keep unmeasured overhead explicit; no per-frame broadcasts or catch-up bursts.
3. Keep local fixed-step driving independent of network waits. Any later remote presentation consumes borrowed state; it must not write authoritative local physics/race fields. Approximately700ms median RTT is a material correction/start/finish risk, not an accepted game-feel result.
4. Use fresh session IDs, bounded sequence numbers and explicit compatibility metadata. The pure controller validates native peer identity, session, physics/track versions, phase and duplicate/stale messages before accepting control state; the native adapter must preserve those checks before live integration. An ACK is never acknowledged. Stop and retain diagnostics on uncertainty; no automatic interrupted-race resume.
5. Continue build-first work with focused tests. Keep the exhaustive size/rate and PARTY/4/8 matrices as expansion work. Full disconnect, actual race corrections/feel, start/finish agreement and release acceptance remain open.

## Implemented now: pure control encoding

`RaceProtocol.lua` supplies `encode(message)` and `decode(payload)`, optional explicit namespace registration and no WoW API/clock/state-controller calls. Version2 uses separate prefix `AZKART2`; the existing version1 `AZKART1` measurement probe is unchanged. No prefix is registered and no packet sent by loading the codec.

The fixed uppercase-base36 header is version1 character, kind1 character, session6 characters and sequence3 characters (11 bytes total). Sequence range1–46655; there is no wrap. Session IDs are public correlation tokens, not credentials. Payload ceiling128 bytes; current control messages are11–23 bytes, with prefix bytes additional.

| Kind | Body fields | Total bytes |
|---|---|---:|
| INVITE | physicsVersion2, trackCode1, trackVersion2, laps1 | 17 |
| JOIN | none | 11 |
| READY | ready flag1 | 12 |
| START | startTick6, seed6 | 23 |
| CANCEL | closed reason code1 | 12 |
| ACK | acknowledged kind1, acknowledged sequence3 | 15 |

Exact lengths, field types, integer bounds and alphabet are checked. Unknown fields, track IDs, reason codes and ACK-of-ACK are refused. Syntactically valid future physics/track version numbers remain decodable so PeerSession can report incompatibility explicitly. `START.startTick` is only encoded data: this module does not align client clocks, authorize a start or initialize a race. No reliable-handshake milestone is completed by a codec.

## Implemented next: pure session control

`PeerSession.lua` now implements explicit host/invite/join/readiness/start-proposal phases with injected time/output, copied presentation views, scoped compatibility, idempotent duplicates, bounded sequence/ACK storage, retries and deadlines. All outputs share a0.5-second cadence, at most one callback per update; commands retry at2 seconds up to3 attempts. No native adapter, UI navigation or live start occurs. The host confirms its START ACK while the guest records receipt; this is not atomic GO or clock agreement. [API_CONTRACTS](../API_CONTRACTS.md#implemented-pure-peer-session-controller) records the actual interface. UI/visual flow belongs to Claude and session semantics to Codex under the [ownership assignment](../UI_FLOW_OWNERSHIP.md).

## Still proposed

The movement-replication/authority model, prediction/reconciliation details, clock mapping and remote-render contract remain proposals until candidate implementation review. A possible symmetric snapshot/ACK schedule would redistribute the measured aggregate load and therefore needs real candidate validation; it is not silently assumed equivalent to the measured sender/listener schedule. Host/peer trust is not authentication or anti-cheat.

**Next single task:** integrate a guarded native two-peer transport adapter over PeerSession and publish its copied view/action bridge for Claude's explicit peer flow. Keep global output accounting/lifecycle cleanup and the AZKART1 experiment independent. Live-race integration follows separately. No new multiplayer controls or playable shared race are claimed by this checkpoint.
