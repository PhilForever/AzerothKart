# Multiplayer experience & uncertainty

**Current priority:** genuine multiplayer precedes dedicated ghosts/time trials under [ADR0010](adr/0010-multiplayer-release-priority.md). Release targets Codex's required work through verified multiplayer plus Claude's three ready maps/eight ready karts; roster size does not promise eight simultaneous racers. All live transport gates remain open.

## Realistic risk model
A smooth eight-racer kart game is a high-frequency interactive simulation. WoW addon messaging is a throttled control/message bus, not a dedicated UDP game-state networking API. A host with eight players can easily exceed aggregate message budget if naïvely sending one message per racer per render frame. Never build multiplayer architecture from imaginary 60Hz packet service.

## Implementation path
1. **Network transport probe** with real two-client sends/receives, loss, throughput/budget, throttling, ordering, latency and reconnect measurement; extend to 4 and 8 only when testers and earlier evidence support it. Select replication from measured capacity.
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
