# ADR 0020 — Dungeon sprints (the Scarlet Crusade Cup)

Codex integration update,2026-10-26: the Library, Armory and Cathedral source
from Claude ea4425d is accepted with the swept-circle correction below and
eleven-course bounded score sync. All four sprints remain solo. Old geometry
score contexts and retired-Oval history are preserved; native verification is
pending. This supersedes the original endpoint-only round-solid proposal.

Codex source review,2026-10-25: accepted for the combined course integration,
with production-only score contexts, corrected sprint status and bounded
eight-course score sync. Seven lap maps have two-peer eligibility; Graveyard
is solo-only. Native checks remain NOT RUN. This supersedes proposed/unfixed
notes below, which describe the original Claude branch.


Status: **Accepted for source integration** by Codex,2026-10-25. Native verification remains pending; this is not multiplayer-sprint or release approval.

## Context

Every course so far is a closed loop run three times. `Race.new` fixed `targetLaps=3`, and `SoloRecords.Context` fixed `lapCount=3`. Each city is a `Circuit`: a street of capsules round a closed centerline.

The owner asked for a new cup of a different kind: "This will be A-B sprint type maps. Scarlet Crusade Cup Scarlet Graveyard, Scarlet Library, Scarlet Armory, Scarlet Monestary. Start of dungeon to end of dungeon. Let's start with Scarlet Graveyard. It starts in a closed space and enters into an open graveyard. You don't need to put a traditional track here, just recreate the dungeon and let players find their way to the end."

A dungeon is a set of rooms with floor wall to wall, not a street. It runs from an entrance to its last room, and is not a loop.

Asked who should add the sprint rules (Race and SoloRecords are Codex's), the owner chose **"I add it, Codex reviews"**:

- minimal changes on Claude's branch;
- every existing course keeps three laps;
- documented as a proposal;
- nothing reaches `main` or an install without Codex's review.

Asked about the graveyard's lawn, he chose **"Grass slows, graves block"**.

## Decision (accepted for solo)

1. **A course sets its run's length.** A track may carry `laps`, an integer from 1 to 9.
   - `Race.new` reads it, defaulting to 3, and refuses anything else outside that range.
   - The finish reason is "Sprint complete" for one run and "Three-lap run complete" for three, as now; any other count gives "N-lap run complete".
   - Checkpoints and Laps are unchanged. A "lap" is still every gate in order, so a sprint finishes on its first completed lap: at its last gate.
2. **A sprint has its own boards.** `SoloRecords.Context` uses `lapCount=track.laps or 3`.
   - The board key already includes the lap count, and Highscores accepts any lap count from 1.
   - A sprint's best is a one-run total, never mixed with three-lap boards.
3. **Dungeon geometry.** A new pure module, `Dungeon.new(definition, crossesGate)`, returns the standard track interface:
   - The floor is a set of axis-aligned rooms, each "road" (stone) or "rough" (a lawn, which Physics treats as its existing `"grass"` surface).
   - The kart centre stays `wallInset` inside the rooms. Rooms that meet overlap by at least two insets, so their floors join through the doorway.
   - Solids are boxes grown by the inset with Track.lua's swept-box sliding, as on the test oval's crates.
   - A step ending off the floor moves to the nearest floor point no further from its start than the step was long, and counts as a wall hit.
   - Lookups use a 64-unit grid built once.
   - `Circuit` is unchanged. Its capsules suit streets; a room-shaped floor, such as a 780 × 640 cloister, is exact as rectangles.
4. **Generated, validated data.** `scripts/build_dungeon_tracks.py` writes `ScarletCrusade.lua` from `scripts/dungeon_layouts.py`. It refuses a layout unless:
   - the rooms are inside the world;
   - the spawn stands on stone;
   - every solid stands on the floor;
   - a reviewed route clears every wall and solid and crosses the gates in order;
   - each gate spans its doorway from wall to wall. A flood fill of the floor, with the gate as a barrier, proves it cannot be driven round.
5. **Catalogue.** `Courses` gains the cup `scarlet` and the geometry `"dungeon"`. Scarlet Graveyard is selectable. Scarlet Library, Scarlet Armory and Scarlet Monastery are listed as coming soon.
6. **Presentation (Claude).** These regions show "Sprint" and a run time, with no lap count:
   - the HUD, results and checkpoint captions;
   - the menus' race lines.

   The status line written by `UI.Start` and `step` now says "Sprint" for one-run courses, with countdown/running regressions.

## Consequences

- **Existing courses are unchanged.** None sets `laps`, so their target, finish reason and board keys stay as before. Tests assert Mirage's context still has three laps; developer/Oval contexts are retired from production capture.
- **Live races are unaffected.** `LiveRace` already refuses a launch bundle whose race is not three laps. A sprint cannot enter a live race by accident. SessionTransport's track list is Codex's, and no dungeon is in it. Multiplayer sprints would need their own review.
- **Community scores:** the combined ScoreSync admits eight production contexts withT/G, retaining retiredO as a zero digest in a nine-slot HELLO. The original Claude branches retain their documented dependency and must not be installed alone.
- **Geometry cost.** `Dungeon.new` builds its grid once. A step checks the rooms and solids in one cell, plus a projection when it ends off the floor; no per-frame allocation is added.
- **Future dungeons.** The Library, Armory and Monastery need no new runtime code: only layouts and pictures, unless a room needs a shape that rectangles cannot give.

## Evidence and limits

Offline only:

- `tests/test_dungeon.lua` on Lua 5.1 and 5.4. It builds a synthetic crypt and checks surfaces, walls, a door, a grave's block and slide, recovery, 4,000 random steps that never leave the floor, and refused definitions. It then runs a sprint race, checks the score context, walks the Graveyard's route through its gates in order and launches a run.
- The UI and menu suites, including a full sprint through the UI to a saved one-run score.
- `scripts/build_dungeon_tracks.py --check`, which runs every geometry check and requires byte-exact outputs.

**NOT RUN in the client:** the drive, the feel of the walls and lawn, the HUD, the 2048 × 1024 picture's load and performance.

## Addendum: round rooms and Scarlet Library (proposed, `claude/scarlet-library`, 2026-10-25)

The Library's last room, "the iconic round library" in the owner's words, is a circle. Rectangles cannot give it, as foreseen above, so `Dungeon.new` gains one room shape.

- **`shape="disc"`:** the disc inscribed in the room's square; width and height must match.
  - The kart centre stays `wallInset` inside its round wall.
  - A step that ends beyond the wall moves along the radius to the nearest point inside it, within the step's length, and counts as a hit, so a kart slides round the wall.
  - Rectangle rooms, and the Graveyard's data and picture, are unchanged.
- **Gates crossed by a route elsewhere:** the generator now counts a route crossing only across a gate's own segment, as `Track.crossesGate` does. The Library's route passes beyond the ends of earlier gates; the runtime never counted those.
- **A dead-end gate:** Houndmaster Loksey's kennel is a dead end on the owner's route. Its gate spans the kennel, so the karts drive in across it, turn and drive back out. Checkpoints count only the inward crossing. The flood-fill check still proves it unavoidable.

Evidence, offline only:

- `tests/test_dungeon.lua` adds a rotunda: surfaces to the round wall, a doorway into it, a slide round the wall, and 2,000 random steps that never end off the round floor. Invalid shapes are refused.
- It walks the Library's route through its five gates in order: once back across Loksey's line, never meeting a wall or a solid. It also checks a clean launch.
- `build_dungeon_tracks.py --check` passes for both dungeons, byte for byte.

**NOT RUN in the client:** the Library's drive (the kennel's hairpin above all), its walls and round wall, the 2048 × 2048 picture's load and performance.

## Addendum: what you see is what you drive (proposed, `claude/drive-fixes`, 2026-10-26)

The owner drove the installed Graveyard (version 1) and found two kinds of fault: "fix invisible wall at infront of kart on image 1 and 2. remove object under kart on image 3 and 4." Both are authoring faults; the runtime contract does not change. The generator now refuses them:

- **No invisible wall.** Where two rooms abut without a doorway, the picture paints one floor but the karts' floors stop two insets apart. `build_dungeon_tracks.hidden_walls` walks every edge of the kart centre's floor where no other room's floor runs on, and requires the picture's masonry within the inset plus 3 units, measured square, as the kart's clearance is. The Graveyard's Chamber of Atonement abutted the west hall; version 2 moves its west wing 20 units east, so a wall stands either side of the west door.
- **Nothing to drive over.** `dungeon_paint.check_props` refuses a model that is not solid with its drawn body (not its shadow) more than 3 units onto the kart centre's floor, where a solid's grown box also counts as off the floor. Scenery out on the floor is solid, or stands against a wall, in a corner or behind a solid. Version 2 of the Graveyard and the not-yet-installed Library are laid out so.

Solids' leaned tops (a column drawn north of its base) are not checked: a kart can still pass over the drawn top of a tall solid it cannot drive into. Graveyard version 2 has its own score boards; the Library stays version 1, since it has not been installed.

## Addendum: a solid on a gate, and Scarlet Armory (proposed, `claude/scarlet-armory`, 2026-10-26)

The Armory's finish is the owner's choice, "Down at Herod": a line across the middle of the round Hall of Champions, with Herod standing in the arena. Herod is solid, so the line runs through his box and the karts cross it either side of him. The runtime contract does not change: `Track.crossesGate` counts any crossing of the gate's segment, and a kart cannot reach the part inside a solid.

- **The generator's gate check** needed one change. It looked for open floor just past a gate at the gate's middle only, which Herod covers, so it stopped the build ("past gate Herod cannot be reached"). It now samples the floor just past the gate every 4 units all along it. A gate passes if some of that floor is reachable from the spawn, and if none of it is reachable round the gate (the flood fill with the gate as a barrier, as before). The Graveyard's and the Library's data and pictures are byte for byte unchanged.
- **No elevation.** The round hall's ring of stairs and the armories' stairs are painted on a flat floor, as the Graveyard's stairs are. Heights stay art only, as in [ADR 0015](0015-track-elevation.md), where physical slopes remain a proposal.

Evidence, offline only:

- `tests/test_dungeon.lua` walks the Armory's route through its five gates in order, never meeting a wall or a solid, and checks a clean launch, its grass yard inside stone walks, its round hall, every solid, and Herod blocking on the finish with stone either side.
- `build_dungeon_tracks.py --check` passes for all three dungeons, byte for byte.

**NOT RUN in the client:** the Armory's drive, the finish beside Herod, the 2048 × 2048 picture's load and performance.

## Addendum: round solids and Scarlet Cathedral (reviewed source integration, 2026-10-26)

The Cathedral's Chapel Gardens have pools, and the owner chose "Water you drive round": the pools and the falls block, so the karts pick a side. Two are rectangles, which solid boxes already give. The round pool is a circle, and boxes cannot give that without the karts stopping short of the painted water or running onto it. So `Dungeon.new` gains one solid shape, as it gained round rooms for the Library.

- **`shape="disc"` on a solid:** the disc inscribed in the solid's square; width and height must match.
  - The kart centre keeps the inset outside the disc's rim, as it keeps the inset off a box's faces.
  - The first swept-circle contact counts as a hit even when both movement endpoints lie outside the reach. Remaining inward normal movement is removed and tangential movement retained. The bounded contact loop preserves the step budget and existing wall penalty.
  - `surfaceAt` is `"wall"` on the disc itself.
  - Swept boxes and discs participate in the same earliest-contact selection. The endpoint floor/round-solid projection remains a recovery guard; it no longer supplies the only round-solid contact check. Rectangle-only behavior is retained.
  - An unknown solid shape, or a round solid that is not square, is refused.
- **Pools in the generator:** a layout's `pools` become solids of their own shape, and the painter fills exactly their footprints with water and a stone rim. The invisible-wall rule counts a pool's water as a visible edge, as it counts a wall.
- **The catalogue is complete:** the Cathedral takes the place of the coming-soon "Scarlet Monastery" (`scarlet_cathedral`, as the wing is named), and nothing is coming soon. No score was ever saved under the old id.

Evidence, offline only:

- `tests/test_dungeon.lua` adds a pond: the pool is wall to its rim; a kart driving at it head on stops at its reach; one passing clear never meets it; one pushing past it slides round it and on; a centre inside it leaves along the radius; 2,000 random steps never end within its reach. Invalid solid shapes are refused.
- It walks the Cathedral's route through its four gates in order, never meeting a wall or a solid, and checks a clean launch, the pools, the finish and a slide round the round pool.
- `build_dungeon_tracks.py --check` passes for all four dungeons; the Graveyard's and the Library's outputs are byte for byte unchanged.

**NOT RUN in the client:** the Cathedral's drive, the pools' feel, the 1024 × 2048 picture's load and performance.

## Addendum: grass with a clear edge, models that block as drawn, plinths (proposed, `claude/scarlet-fixes`, 2026-10-26)

After his first drive of the installed Scarlet Cup the owner wrote: "Grass needs to be drivable if it doesnt have a clear edge/fence", asked that the Armory's Training Grounds be driven "without being slowed" and that the Cathedral's grass no longer slow, reported "seemingly some invisible walls" there, and pointed out that "the stairs are the only path up to the cathedral". He also asked for the huntsman standing on the Library courtyard's path to go, and for Loksey's kennel gate to go: "the room is nice but not part of the checkpoints".

Decisions, all data and generator; `Dungeon.lua` and every other runtime file are unchanged:

1. **Grass slows only where a clear edge marks it.** A lawn stays `rough` where kerbed paths or walls edge it (the Graveyard's cloister, the Library's courtyard); otherwise its room is `road` and the grass is paint (the Armory's yard, the Cathedral's gardens).
2. **A model may block where it is drawn** (`blocks` on a solid prop, measured by `build_dungeon_tracks.blocking` from the rendered sprite): `"drawn"` grows its box to its drawn body's, less a 2-unit margin; `"round"` makes it the disc in that box, a round solid (the integrated `shape="disc"`). The picture leans tall models north of their feet, so a box at a tree's trunk left a kart stopping on the drawn leaves, short of anything it could see. Trees, bushes, the Cathedral's great pillars and the Armory yard's dummies, targets and backstops now block as drawn. Slender models (columns, soldiers) keep a box at their feet, and a kart passing behind one is drawn over its top.
3. **Plinths:** a layout's `plinths` are raised blocks that are not floor, so they stop the karts as walls do; the painter paves their tops in a floor style inside a dressed rim and raises their south faces `height` units in the walls' stones. The Cathedral's statue platforms are plinths, so the stairs beside the falls are the only way between its gardens; its *Upper Gardens* gate spans the band.
4. **Versions:** the Library, the Armory and the Cathedral become geometry version 2; their score boards start fresh, version 1's records stay saved. The Library has four gates. The Graveyard is unchanged, byte for byte.

Evidence, offline only:

- `build_dungeon_tracks.py` validates all four dungeons (the invisible-wall rule, gates that cannot be passed round, the routes, nothing that is not solid on the floor); a solid's middle, or one side's, must be on the floor (a tree's crown may reach over a wall).
- `tests/test_dungeon.lua`: the Library's four gates in order and its clear cross path; the Armory's and the Cathedral's rooms all `road`; a plinth's face stops a kart, the stairs run clean up; a kart stops at a tree's crown, not at its trunk; the routes never meet a wall or a solid.

**NOT RUN in the client:** the three courses' version 2 drive, look and picture load.
