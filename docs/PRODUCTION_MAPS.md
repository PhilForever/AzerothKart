# Production courses and multiplayer scope

Owner direction, 2026-10-25: retire Test Oval from the game, open all finished
maps to multiplayer, and work toward eight racers. The owner subsequently
reconsidered requiring a WoW raid group; that requirement is **undecided**.
This page supersedes older playable-Oval and Mirage-only catalogue statements.
Reviewed Claude ea4425d adds the complete four-course Scarlet sprint cup and
the Thunder Bluff/Graveyard version2 drive corrections. Codex integrates the
swept round-pool fix and bounded L/A/C score sharing on `codex/scarlet-integration`.
Reviewed Claude5cee515 supplies Warsong v3: both bases up the outside ramp,
through the lobby/flag and down the tunnel. Two covers fade on the descents;
the guide keeps a3-unit margin. Geometry3 gets a new Physics13 board; v1/v2
records remain saved. RaceC/scoreW and the other eleven contexts stay intact.
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
| Thunder Bluff Skyway (`thunder_bluff_skyway`) | 2 | 7 |
| Scarlet Graveyard (`scarlet_graveyard`) | 3 | 8 |
| Scarlet Library (`scarlet_library`) | 3 | 9 |
| Scarlet Armory (`scarlet_armory`) | 2 | A |
| Scarlet Cathedral (`scarlet_cathedral`) | 3 | B |
| Warsong Gulch (`warsong_gulch`) | 3 | C |

All twelve courses are available in solo, Highscores and the two-peer lobby
(owner direction,2026-10-27). Circuits use three laps; the four Scarlet dungeons
use one ordered run. Target count is validated at invite, clock handoff and live
terminal receipt; no sprint can advertise three laps or finish prematurely.
Full countdown/grid, observed results and same-player rematches use existing
APIs. Native sprint play/smoothness are NOT RUN; this is no eight-racer claim.
There are no coming-soon entries. Mirage is the actual default geometry and scenery.

Reviewed Scarlet v3 opens the Library courtyard and the ring around its pool,
makes all four Scarlet courses full grip, and gives the Cathedral staircases
their turning landings. Graveyard, Library and Cathedral now use version3;
Armory remains2. Graveyard's handling change requires a new board even though
its scenery is unchanged. All older version1/2 records remain saved in their
original contexts. Current score catalogue/export has twelve boards, still
within the unchanged packet limit. The integrated race screens bring the
explicit production pool to91frames/96textures/151fontStrings with Warsong, created once.
Native appearance/feel for these changes remains pending.

A failed scenery load refuses Start until a valid map loads;
there is no hidden Oval fallback. An obsolete saved Oval preference falls back
in memory without rewriting the save on initial load.

`Courses.get/available/build/next`, menu cards, lobby cycling and session offers
exclude Oval. Control wire code0 is retired; Mirage1 remains stable. Both racers
must update for new sprint offers. `Courses.multiplayer(id)` admits all current
available production courses; `Courses.next(id,true)` filters the lobby. The eleven flat courses retain Physics12; Warsong uses Physics13 and layered
AZKRUN3. Existing live packet sizes and logged-whisper budgets are unchanged.

`Track.lua` remains a developer-only analytical fixture and the shared gate
predicate provider. Existing deterministic collision/handling tests may load it
directly. Production UI does not allocate its road/obstacle textures. It cannot
be selected, started or negotiated through the player APIs. Old saved scores
are preserved but excluded from current boards/publication. No player data is
deleted or migrated.

ScoreSync admits twelve exact current contexts: eleven Physics12 boards and
Warsong Physics13. AZKSCR2/schema2 has thirteen fixed hexadecimal digest slots,
including retired O=0, and binds per-context physics in the catalogue hash.
Existing score codes stay stable; Warsong appends W. HELLO is136 native counted
bytes and maximum legal NEW/ROW150; native158-byte ceiling remains. Old-prefix
clients must update; stored historical boards are retained without migration.
[Exact bounds and compatibility](AUTOMATIC_SCORES.md#implementation). The
separate server-store example exports the same twelve contexts; no external
service is contacted by the addon.

## Why eight racers## Why eight racers need a transport decision

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
