# First owner-reported two-client race

Recorded 2026-10-23, Europe/Oslo, from the owner's two screenshots and feedback.
The preceding verified installation/package was c581a52; no fresh version,
build/interface, packet counters or exact test timestamp were supplied.
Screenshots and character names remain private; peers are A and B here.

Both screenshots show Mirage Raceway with three completed local laps and
explicit **LOCAL FINISH — UNVERIFIED** results: A 36.42 seconds, B 35.42 seconds.
These are independent local simulation times, not agreed placements or measured
start skew. Both display their own selected kart, while the owner reports
seeing the other player only as a square. The owner reports only GO appeared,
without the countdown. They want both karts visible on the starting grid before
3–2–1 begins. They describe the feel as “ok”, with lag/clipping and an opponent
often apparently far behind/out of view despite being nearby. No kart contact
was confirmed; inter-kart collision was not implemented in this candidate.

This establishes owner-reported completed local racing and observed peer
presentation, with specific usability failures. It does not establish all-packet
delivery, quantitative latency/FPS, synchronized starts, trusted winners,
production capacity, reconnect, or multiplayer milestone completion.

The follow-up on codex/multiplayer-grid adds bounded kart-profile agreement,
role-specific start slots, full visible countdown and timestamp-aware bounded
remote presentation. Offline checks and deployment are recorded in PROGRESS;
the revised behavior in the actual client remains **NOT RUN** until reported.
