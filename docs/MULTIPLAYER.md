# Multiplayer experience & uncertainty

**Current priority:** genuine multiplayer precedes dedicated ghosts/time trials under [ADR 0010](adr/0010-multiplayer-release-priority.md). Release targets Codex's required work through verified multiplayer plus Claude's three ready maps/eight ready karts; roster size does not promise eight simultaneous racers. All live transport gates remain open.

**Current implementation:** an explicitly armed, bounded two-peer **WHISPER_LOGGED** probe, using `C_ChatInfo.SendAddonMessageLogged` and `CHAT_MSG_ADDON_LOGGED` with native channel `WHISPER`, strict codec/accounting, one ACK per unique DATA, no retry/catch-up burst and explicit report/sequence evidence commands. The CSV channel label is `WHISPER_LOGGED`; no ordinary-whisper or unlogged fallback is provided. This is an experiment harness, not a lobby or live kart replication. Azeroth Kart's actual prefix/send returns, sustained traffic, latency, loss reconciliation and reconnect on build 70450 remain **NOT RUN**. See [ADR 0012](adr/0012-forever-logged-transport.md), [wire format and bounds](PROTOCOL.md), [source-backed API expectations](CLIENT_API.md#transport-probe-api-contract-source-evidence-not-a-live-pass) and [the exact two-client checklist](../tests/MANUAL_NETWORK_CHECKLIST.md). The experiment ledger stays header-only until measured Azeroth Kart data exists.

**Existing Forever evidence:** the sibling IOU repository records four exact logged-whisper round trips between two clients on 16 October 2026, build 70425, including ASCII, Norwegian UTF-8 and 239/240-byte packets (`IOU-GitHub/docs/connection-test.md`; identity/transport implementation in `IOU-GitHub/transport.lua`). We reuse that basic compatibility evidence. Forever character identities are full first names and surnames, without realms. Azeroth Kart accepts at most 96 raw name bytes before trimming/collapsing ASCII spaces; matching folds only ASCII case and preserves exact non-ASCII spelling, punctuation and hyphens across the complete native sender name. It never substitutes just a first name or invents a realm suffix.

## Realistic risk model
A smooth eight-racer kart game is a high-frequency interactive simulation. WoW addon messaging is a throttled control/message bus, not a dedicated UDP game-state networking API. A host with eight players can easily exceed aggregate message budget if naïvely sending one message per racer per render frame. Never build multiplayer architecture from imaginary 60Hz packet service.

## Implementation path
1. **Network transport gate:** measure Azeroth Kart's lowest-rate WHISPER_LOGGED window with two consenting clients, reconcile per-direction sequence evidence and raw API results, then expand to PARTY/fan-out and required connection/reconnect contexts. IOU already established basic compatibility; this gate measures sustained traffic, pacing, latency, throttling, ordering, loss reconciliation and recovery for racing. Logged payloads may be recorded or exposed by the client/server. Extend to 4 and 8 only when testers and earlier evidence support it. The current harness does not implement the full gate. Select replication from measured capacity.
2. **Low-rate social features**: presence, invites, rooms, track choice, ready checks, countdown and results, using the measured budget and tested `WHISPER`/`PARTY` behavior.
3. **Experimental 2-player race** with predicted local car, remote interpolation, host adjudication and debug overlay. Cap traffic, log corrections and finish disagreements.
4. 4-player beta only after repeated usable two-player sessions, 8-player beta only after measured successful 4-player tests.
5. **Deferred contingency**: bounded asynchronous ghost challenges may be discussed if live racing fails its gate; they are not scheduled ahead of multiplayer and do not silently satisfy the agreed release target.

## Proposed lobby UX
Private room invite (one-time, no scan/spam), host selection, player list, client compatibility warning, track/seed voting, synchronized race start; explicit Leave, Kick, Reconnect, Rematch. No public channel flood; respect user blocks/ignore where observable.

## Trust and result transparency
Host can edit their addon, so results are host-observed, not cryptographically provable; don't claim anti-cheat. Keep per-client diagnostic logs and "Unverified / Sync issue" on disagreement. A client must never be able to change another client's character or in-world motion.

## Eventual fallback decision
If synchronous play fails F4, stop and present measurements for owner review before changing the release scope. Ghost challenges/records/replays remain possible alternatives, not automatic substitutes. Revisit live racing on documented API/capacity improvement rather than repeated speculative rewrites.
