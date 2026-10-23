# First two-player race test

This developer candidate connects the lobby, coordinated start and live pose
display. The [first real race](evidence/2026-10-23-first-live-race.md) completed
locally on both clients and exposed countdown/sprite/delay problems. This updated
candidate addresses those problems in source; **its client checks are NOT RUN**. Both players need
the exact same candidate. Grouping and being in the same world zone were not
required by the recorded logged-whisper connection tests.

1. Install the same candidate on both computers, then fully exit and restart
   WoW. This build adds files; `/reload` alone is insufficient. Choose your
   kart in Garage before starting the lobby.
2. Both open `/akart` → **Multiplayer**. Each enters the **other person's full
   Forever character name**, including the surname and spaces. No realm suffix.
   Both enter the same fresh six-character uppercase/digit code, e.g. `CUP101`.
   Use a new code after every ended attempt. It is a public label, not a password.
3. Decide who hosts. **Guest first:** click **Listen for Host**.
4. **Host:** choose Mirage Raceway or Test Oval, then **Host / Send Invite**.
   **Guest:** once the invitation appears, click **Join Received Invite**.
5. Wait for **Ready** to enable while kart choices are exchanged, then both
   click **Ready**. This loads the agreed track and authorizes grid input capture.
   Close chat and keep the kart window open and WoW focused.
6. **Host:** click **Start** when enabled. Wait for the timing/confirmation
   status to finish. Both chosen karts appear side by side on the start line,
   first with **GET READY**, then **3–2–1–GO**. You may hold throttle during the
   countdown; driving starts at GO. Drive with W/A/S/D or arrows; Space drifts.
   Your friend’s selected kart should be visible (a square is the art fallback).
7. Drive a lap together. **Stop**, Escape, Enter/chat or closing the window
   ends your run and releases controls. Stop/Leave sends a bounded best-effort
   cancellation; disappearance without a message is detected after five seconds.
   A fresh attempt requires a new code and deliberate Join/Ready again.

Please report whether both saw the grid/countdown and correct friend kart,
whether nearby driving felt less delayed, and any exact on-screen failure text. No separate
`/akart net` experiment is needed for this first candidate.

The display estimates the opponent’s current position from timestamped observations,
with at most half a second of forecast constrained by track walls/obstacles.
Unknown braking/steering and clock uncertainty can still cause corrections.
An off-screen label gives direction/distance, not race position; stale data fades.
This is the behavior to judge in the real client, not a verified responsiveness
claim. Karts currently do not collide with each other. Local three-lap times
are shown, but there is **no agreed winner or trusted shared finishing order**.
The session closes after both finished observations, or an exit/timeout.
Combat/world changes end it; there is no automatic reconnect or resume.

Only the two listed tracks are negotiated in this candidate. Stormwind,
Ironforge and Orgrimmar remain available for solo driving. New art and rights
status are unchanged; this is a private developer test package, not a release.

**Handling update:** this candidate uses Physics8 for wall sliding and faster
parking turns. Both players must update; older Physics7 peers are rejected as
incompatible before countdown. City art updates also need a full restart.

The latest light wall-penalty tuning is Physics9; both racers must update. A `/reload` is enough for this Lua-only follow-up.

Latest build: Physics10 uses10% initial wall loss and80% contact top speed; both friends must update. The new Undercity lighting also requires a full restart.
