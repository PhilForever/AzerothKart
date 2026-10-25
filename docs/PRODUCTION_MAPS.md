# Production courses and multiplayer scope

Owner direction, 2026-10-25: retire Test Oval from the game, open all finished
maps to multiplayer, and work toward eight racers. The owner subsequently
reconsidered requiring a WoW raid group; that requirement is **undecided**.
This page supersedes older playable-Oval and Mirage-only catalogue statements.
No eight-player implementation or capacity acceptance is claimed.

## Implemented map catalogue

| Course | Geometry version | Race wire code |
|---|---:|---:|
| Mirage Raceway (`mirage_raceway`) | 1 | 1 |
| Stormwind City Circuit (`stormwind_city`) | 3 | 2 |
| Ironforge Grand Prix (`ironforge_gp`) | 4 | 3 |
| Darnassus Canopy Run (`darnassus_canopy`) | 1 | 4 |
| Orgrimmar Canyon Rush (`orgrimmar_canyon`) | 1 | 5 |
| Undercity Slime Circuit (`undercity_slime`) | 2 | 6 |

These six courses are available in solo, Highscores and the existing two-peer
lobby. Thunder Bluff remains coming soon. Mirage is the actual default geometry
and scenery. A failed scenery load refuses Start until a valid map loads;
there is no hidden Oval fallback. An obsolete saved Oval preference falls back
in memory without rewriting the save on initial load.

`Courses.get/available/build/next`, menu cards, lobby cycling and session offers
exclude Oval. Control wire code0 is retired; Mirage1 remains stable. Both racers
must update for city offers. Packet sizes, Physics12, race timing, handling,
geometry and the existing logged-whisper budgets are unchanged.

`Track.lua` remains a developer-only analytical fixture and the shared gate
predicate provider. Existing deterministic collision/handling tests may load it
directly. Production UI does not allocate its road/obstacle textures. It cannot
be selected, started or negotiated through the player APIs. Old saved scores
are preserved but excluded from current boards/publication. No player data is
deleted or migrated.

ScoreSync admits six current contexts. Its seven-slot HELLO keeps the retired
`O` slot as a zero digest; active `M/S/I/D/R/U` codes do not move. A `retired:O`
catalogue marker separates old/new sync peers; old caches stay saved, while
updated players exchange only current production boards. The disconnected
server-store example/catalogue also uses production maps only.

## Why eight racers need a transport decision

There is no WoW party/raid requirement for the current two-peer whisper flow;
the recorded AKT723 window worked across different zones while ungrouped.
Grouping does not itself reduce server ping or kart-rendering work. The relevant
difference is the number of native sends needed to reach every racer.

At the current two-updates/s telemetry cadence, a pose is40payload+7prefix bytes:

| Candidate route | Native sends per racer/s | Counted bytes per racer/s |
|---|---:|---:|
| Current two-peer whisper | 2 | 94 |
| Eight-peer whisper mesh, seven recipients | 14 | 658 |
| Native raid multicast, if supported | 2 | 94 |

Control/clock traffic and unknown native overhead are additional. The existing
adapter deliberately admits at most2calls/158prefix+payload bytes per rolling
second. That is a tested working envelope, **not a discovered Forever API
maximum**. Seven whisper copies cannot fit it. Keeping that cadence budget
would yield about one sample per opponent every3.5seconds, beyond the current
1.5second stale window and0.5second forecast.

Host forwarding does not solve this under the same whisper budget. A custom
channel broadcast is not an established alternative: the private-server logged
CHANNEL test had no peer receipts. Native logged RAID is a candidate only; its
delivery, throttling, ordering and four/eight-person aggregate load are NOT RUN.
Do not silently change to ordinary/unlogged chat or raise the working budget.

Eight racers also need one bounded room roster, per-member readiness/profile/
timeouts, a single common GO epoch and seven observational opponent views.
Seven independent copies of the two-peer controller would create independent
start epochs and cleanup policies. No such engine is enabled by this map change.

Next networking task: settle a supported fan-out route and grouping policy
before the eight-member controller. Keep the present ungrouped two-player mode
available. Native capacity and agreed shared results remain release gates.
