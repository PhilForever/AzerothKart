# ADR 0016 — Solo records first; global scores require a supported route

Status: Accepted local-record scope and current single-player priority from the
owner's 2026-10-23 direction. Global transport/service architecture remains OPEN.

The owner is happy with the current handling and asks to finish single player
before testing multiplayer again, including total finish time/name/date on a
global highscore board. Offered community synchronization or central hosting,
the owner delegates the choice to whichever is efficient and less error-prone.

Implement a small independent, bounded, schema-versioned local record store and
visible Highscores menu now. Record only complete solo three-lap totals, once,
with full Forever name and guarded finish timestamp. Partition boards by course
and handling/rules compatibility; do not gate this on ghosts or replays. Keep
malformed/future saves and unrelated data intact. Scores are client-reported.

Do not infer global delivery from the verified two-peer logged-WHISPER route.
A persistent common destination is needed for a complete offline-available
global board; none is available/verified in the project. Public-channel addon
messaging needs its own capability evidence, and a community cache still cannot
promise completeness. Central ingestion/querying needs a supported Forever
integration, not a hidden companion uploader. Flag this dependency for owner
review; do not claim local persistence fulfills global publication.

This changes the immediate priority in ADR0010, not its remaining multiplayer
release gates. No milestone is completed, public network traffic enabled,
release/push/install authorized, or art/geometry/Physics10 behavior changed by
this decision. See [HIGHSCORES](../HIGHSCORES.md) for implemented contracts and
the exact remaining publication dependency.
