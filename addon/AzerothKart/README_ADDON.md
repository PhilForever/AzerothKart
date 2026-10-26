# Azeroth Kart — developer candidate

The combined course update adds files: fully exit and restart WoW after installation.
Both multiplayer racers need the same candidate. Nothing is installed by checking
out a Git branch; use Codex's reviewed combined build, not Claude's standalone
course branch (which still has its documented score-sync dependency).

Open `/akart` or `/azerothkart`. Single Player offers Mirage Raceway, Stormwind,
Ironforge, Darnassus, Orgrimmar, Thunder Bluff, Undercity and Scarlet Graveyard.
Choose a track and kart, then Race! Mirage is the default. Test Oval is retired.
The seven circuits run three laps; Graveyard is one run through three gates.
Library, Armory and Monastery remain coming soon.

W/Up accelerates; S/Down brakes/reverses; A/D or Left/Right steers. Hold Space
while turning on road at speed90+ to charge drift, then release for boost.
Physics12 offers balanced, heavy and agile profiles, with0.8/1.3second boost
rewards. Walls retain sliding movement, with10% initial loss and80% scrape cap.
Incidental clicks/unassigned keys do not stop a run. Stop, Escape, Enter/chat
or Close ends it and releases controls; Restart begins a new run. Combat closes
the window. Results can be dismissed with Close results.

Highscores saves compatible solo best totals, names and UTC dates. All karts
share a board. Community scores exchange automatically with discovered addon
users through logged whispers; no manual result copying or extra software.
The board displays connection status and best-known cached ranks. Records
are client-reported; native discovery/delivery/scale are still pending detailed
verification. Old score history and unrelated preferences are preserved.

Multiplayer currently supports two racers on the seven lap circuits. Graveyard
is solo until its live sprint lifecycle is reviewed. Enter the other player's
full Forever name, including surname/spaces, with no realm suffix. Both use the
same fresh six-character uppercase/digit code. Guest: Listen first. Host: choose
a lap map and Host/Invite. Guest: Join. Both: Ready. Host: Start. Keep chat closed
and the window focused for GET READY,3–2–1–GO. Grouping/nearby world positions
are not required for this two-peer whisper mode. Karts do not collide, and
results have no agreed shared winner. Eight-player capacity remains in development.

Current explicit production UI pool:89frames/69textures/136font strings,
plus the two fixed Core/score receiver frames. No per-tick UI creation or sends.
These are offline counts, not native FPS/memory measurements.

New course artwork, sprint feel, client performance and city multiplayer remain
NOT RUN in-game. Source evidence, contracts and pending release/asset-rights
checks live in the repository's docs/PROGRESS.md and docs/PRODUCTION_MAPS.md.
No release, verified global rank or eight-player support is claimed.

Multiplayer display now uses a bounded transit-aware forecast and current turn
direction, without increasing network traffic. Native smoothness remains pending.
`/akart net group help` describes the separate finite group-delivery check; it
does not start a race or require grouping for existing two-player racing. The
new GroupProbe file requires a full client restart after installing this build.

Score-discovery fix: current party/raid members and validated multiplayer peers
are now automatic recipients even when the public channel member list stays
pending. Both players update and `/reload`; while stopped, open the same board.
Existing saved times are reused. No new race or copied names/results is needed.
Public discovery for strangers remains pending; native delivery still needs a
check. `/akart scores` prints channel/group reasons if it does not connect.
