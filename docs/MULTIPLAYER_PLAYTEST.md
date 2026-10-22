# First two-player race test

This developer candidate connects the lobby, coordinated start and live pose
display. **Actual Forever racing has not been verified yet.** Both players need
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
5. Both click **Ready**. This loads the agreed track and authorizes keyboard
   capture at GO. Close chat and keep the kart window open and WoW focused.
6. **Host:** click **Start** when enabled. Wait for the timing/confirmation
   status to finish. The race opens at GO; it does not run a second solo
   countdown. Drive with W/A/S/D or arrows; Space drifts. Your friend is a cyan
   marker labelled with their name. Their selected kart art is not exchanged.
7. Drive a lap together. **Stop**, Escape, Enter/chat or closing the window
   ends your run and releases controls. Stop/Leave sends a bounded best-effort
   cancellation; disappearance without a message is detected after five seconds.
   A fresh attempt requires a new code and deliberate Join/Ready again.

Please report whether both reached GO and saw moving friend markers, whether
the delay felt usable, and any exact on-screen failure text. No separate
`/akart net` experiment is needed for this first candidate.

The marker shows delayed received observations and never predicts through
walls. It can leave the follow camera's view at speed; stale data is faded.
This is the behavior to judge in the real client, not a verified responsiveness
claim. Karts currently do not collide with each other. Local three-lap times
are shown, but there is **no agreed winner or trusted shared finishing order**.
The session closes after both finished observations, or an exit/timeout.
Combat/world changes end it; there is no automatic reconnect or resume.

Only the two listed tracks are negotiated in this candidate. Stormwind,
Ironforge and Orgrimmar remain available for solo driving. New art and rights
status are unchanged; this is a private developer test package, not a release.
