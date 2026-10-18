# Multiplayer experience & uncertainty

## Realistic risk model
A smooth eight-racer kart game is a high-frequency interactive simulation. WoW addon messaging is a throttled control/message bus, not a dedicated UDP game-state networking API. A host with eight players can easily exceed aggregate message budget if naïvely sending one message per racer per render frame. Never build multiplayer architecture from imaginary 60Hz packet service.

## Implementation path
1. **Low-rate social features**: presence, invites, rooms, track choice, ready checks, countdown and results; deliberately test `WHISPER`/`PARTY` and disconnects.
2. **Network transport probe** with real 2-player measurement, extend to 4 and 8. Compare sustainable rates and jitter against observed game feel.
3. **Experimental 2-player race** with predicted local car, remote interpolation, host adjudication and debug overlay. Cap traffic, log corrections and finish disagreements.
4. 4-player beta only after repeated usable two-player sessions, 8-player beta only after measured successful 4-player tests.
5. **Fallback social mode**: challenge friends' ghost tapes, racing against previous lap input traces, upload small bounded ghost via in-game addon messaging or manually share import strings; legitimate mode with clear labels.

## Proposed lobby UX
Private room invite (one-time, no scan/spam), host selection, player list, client compatibility warning, track/seed voting, synchronized race start; explicit Leave, Kick, Reconnect, Rematch. No public channel flood; respect user blocks/ignore where observable.

## Trust and result transparency
Host can edit their addon, so results are host-observed, not cryptographically provable; don't claim anti-cheat. Keep per-client diagnostic logs and "Unverified / Sync issue" on disagreement. A client must never be able to change another client's character or in-world motion.

## Eventual fallback decision
If synchronous play fails F4: invest in asynchronous live-feeling ghost challenge, lap records and replays. Revisit real-time only on documented API improvement, not repeated speculative rewrites.
