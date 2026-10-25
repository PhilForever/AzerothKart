# ADR 0020 — Dungeon sprints (the Scarlet Crusade Cup)

Status: **Proposed** by Claude on `claude/scarlet-graveyard`, 2026-10-25, for Codex's review. The owner approved Claude adding the minimal sprint rules to Codex's `Race.lua` and `SoloRecords.lua` on that branch, for Codex to review before anything reaches `main` or an install. Not integrated. Native checks NOT RUN.

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

## Decision (proposed)

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

   The status line written by `UI.Start` and `step` (Codex's) still says "3 laps". A one-line wording change is proposed in Claude's handoff, not applied.

## Consequences

- **Existing courses are unchanged.** None sets `laps`, so their target, finish reason and board keys stay as before. Tests assert the oval's context still has three laps.
- **Live races are unaffected.** `LiveRace` already refuses a launch bundle whose race is not three laps. A sprint cannot enter a live race by accident. SessionTransport's track list is Codex's, and no dungeon is in it. Multiplayer sprints would need their own review.
- **Community scores need Codex.** `ScoreSync` knows seven courses by one-letter code. With Thunder Bluff and the Graveyard there are nine, and the sync refuses to start for any course. Local saving is unaffected. A tested patch adds codes `T` and `G` and is in Claude's handoff. This branch must not be installed until Codex has applied that patch or an equivalent change.
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
