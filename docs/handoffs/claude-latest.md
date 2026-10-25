# Claude handoff — Scarlet Library (in progress)

## Active reservation — Scarlet Crusade Cup: Scarlet Library (2026-10-25)

The owner sent his map of the Scarlet Monastery Library (MapsForTanks) with his route, a screenshot of the Huntsman's Cloister's courtyard and one of Arcanist Doan's round library. He wrote: "Scarlet Library. Everything is inside except the first courtyard with the fountain/statue in the middle, everything else is inside - ending in the iconic round library."

His route:

1. From the portal ("!") into the long hall south.
2. Round the Huntsman's Cloister.
3. In and back out of Houndmaster Loksey's room (1), across the red line he drew there.
4. North up the east hall into the Gallery of Treasures.
5. East through two columned halls, then south down the Athenaeum.
6. Through the last hall to the round library (2): "END!", at the red line across its door.

**Branch:** `claude/scarlet-library` from `claude/scarlet-graveyard` `1bc3ac8`. Thunder Bluff and Scarlet Graveyard are not integrated yet, so this branch carries both. Reserved, until this handoff says otherwise:

- **`addon/AzerothKart/Dungeon.lua`** (Claude's proposed module, not yet reviewed): round rooms (`shape="disc"`) for the round library. Rectangle rooms behave as before.
- **Generated:** `addon/AzerothKart/ScarletCrusade.lua` gains the Library's entry; the Graveyard's stays byte for byte. New `addon/AzerothKart/Assets/Tracks/ScarletLibrary/`.
- **Scripts:**
  - `scripts/dungeon_layouts.py`: a new Library section;
  - `scripts/dungeon_paint.py`: round rooms and the Library's new layers; the Graveyard's picture stays byte for byte;
  - `scripts/build_dungeon_tracks.py`: round rooms in the validator and the data.
- **Shared:**
  - `Courses.lua`: Scarlet Library becomes selectable;
  - `services/leaderboard/catalog.json` (generated);
  - `scripts/validate_project.py`.
- **`Menu.lua`:** the Library's track copy and preview cell.
- **Tests:** `tests/test_dungeon.lua`, `tests/test_circuit.lua` and `tests/test_menu.lua` (`test_ui.lua` only if a count moves).
- **Proposal only:** `ScoreSync.lua`, the patch extended by the Library's code.
- **Docs:** a track sheet, ADR 0020 (round rooms), and the shared lists that name the tracks.

No change to `Race`, `SoloRecords`, physics, input, timing, networking, `Circuit` or `UI.lua`.

# Previous: Scarlet Graveyard

Prepared 2026-10-25 at about 21:50 CET (Europe/Oslo) by Claude (rendering/UI/sprites owner).

**Base:** `claude/thunder-bluff` `a7aeb66`. Thunder Bluff is not integrated yet, so this branch carries it; its handoff follows [below](#previous-thunder-bluff-skyway).

**Branch:** `claude/scarlet-graveyard`, with these commits:

- `a54463e`: the reservation;
- `eaebffb`: Scarlet Graveyard;
- this handoff.

> **Do not install this branch on its own.** As with Thunder Bluff, `ScoreSync` expects exactly seven courses. With nine selectable it does not start, and community score sharing stops for every course; local saving is unaffected. The [extended patch below](#needs-codex-score-sync-learns-the-new-courses) covers both courses.

## Owner instructions

"Great. Codex is busy right now, so we'll push and test later. Your next task - more maps. This will be A-B sprint type maps. Scarlet Crusade Cup Scarlet Graveyard, Scarlet Library, Scarlet Armory, Scarlet Monestary. Start of dungeon to end of dungeon. Let's start with Scarlet Graveyard. It starts in a closed space and enters into an open graveyard. You don't need to put a traditional track here, just recreate the dungeon and let players find their way to the end."

He sent two images:

- the Scarlet Monastery Graveyard map (MapsForTanks), with his green route from the entrance ("!") to Honor's Tomb ("END!");
- a screenshot of the monastery's Grand Vestibule portal.

Asked on 2026-10-25, he chose:

- **Sprint rules:** "I add it, Codex reviews". Claude makes minimal changes in `Race` and `SoloRecords` on this branch. Every existing track keeps three laps. The change is documented as a proposal, and nothing reaches `main` or an install without Codex's review.
- **The cloister lawn:** "Grass slows, graves block".

The standing instructions still hold:

- no merge into `main`;
- no claim of in-game verification without the actual client;
- the simulation-control functions in `UI.lua` stay untouched;
- the owner pushes and runs the client checks, and Codex prepares coordinated installs.

## Scope (reserved and changed)

The reservation (`a54463e`) held. There is no physics, input, timing, networking or `Circuit` change. `ScoreSync` is changed only as a proposal.

- **New runtime files:**
  - `addon/AzerothKart/Dungeon.lua`: pure geometry for open dungeon floors. Claude wrote it; its geometry is for Codex's review.
  - `addon/AzerothKart/ScarletCrusade.lua`: generated data.
  - `addon/AzerothKart/Assets/Tracks/ScarletGraveyard/Background.tga` (2048×1024, 8,388,626 bytes) and `Preview.tga` (512×256, 524,306 bytes).
- **Codex's files, owner-approved minimal changes for review:**
  - `Race.lua`: new `courseLaps(track)` and `finishReason(targetLaps)`. `Race.new` takes `targetLaps` from `track.laps`, default 3, and `Race.step`'s finish reason comes from the target.
  - `SoloRecords.lua`: `Context` uses `lapCount=track.laps or 3`.
- **Shared:**
  - `Courses.lua`: the `scarlet` cup, its four entries (three `soon`) and the `dungeon` build branch;
  - both TOCs: `Dungeon.lua` and `ScarletCrusade.lua`, after `CapitalCities.lua`;
  - `tests/run.lua`: `test_dungeon.lua`, after `test_circuit.lua`;
  - `scripts/export_score_catalog.py` loads the two modules. `services/leaderboard/catalog.json` is regenerated: nine boards, the Graveyard's with lap count 1.
  - `scripts/validate_project.py`: the load order and the new required files.
- **`Menu.lua`:**
  - the Graveyard's track copy and preview cell (320×160);
  - How to Play's rules line;
  - `raceLines`: SPRINT, the time and GATES n/N;
  - the results list one "Run" time;
  - the Highscores rule line names a sprint board, reusing its label.

  The track screen gains one heading and four buttons, for 90/167/136 frames, textures and font strings.
- **`UI.lua`, visual regions only:** `refreshCheckpoints`, `refreshSummary` and `refreshHud`. `UI.Start`, `step` and every other Codex function are untouched.
- **New scripts:**
  - `scripts/dungeon_layouts.py`;
  - `scripts/build_dungeon_tracks.py`;
  - `scripts/dungeon_paint.py`, which imports the unchanged `city_paint.py`. The cities' pictures are untouched.
- **Tests:**
  - `tests/test_dungeon.lua` (new);
  - `tests/test_ui.lua`: counts, the module list, and a whole sprint;
  - `tests/test_menu.lua`: counts, the Track cycle, and the Scarlet cup block;
  - `tests/test_circuit.lua`: three cups, the coming-soon count and the cycle.
- **Docs:**
  - new: [ADR 0020](../adr/0020-dungeon-sprints.md) and the [track sheet](../art/tracks/scarlet-graveyard.md), with its overview, review image and sources list;
  - updated: `API_CONTRACTS.md` (a new proposed section), `TRACKS.md`, `README.md`, `ASSETS.md`, `INDEX.md`, `ASSET_SOURCES.md`, `CHANGELOG.md`, `TEST_PLAN.md` and `tests/MANUAL_CLIENT_CHECKLIST.md`.

`docs/PROGRESS.md` was not edited; the entry is [below](#progress-ledger-entry-for-the-integrator-scarlet-graveyard).

## Delivered

![The way through and nine follow-camera views](../art/tracks/scarlet_graveyard-review.png)

Scarlet Graveyard, the first Scarlet Crusade Cup course and the first dungeon sprint. The [track sheet](../art/tracks/scarlet-graveyard.md) has the full record.

- **The way through**, from his green route:
  1. The grid stands at the instance portal, a blue swirl at the entrance hall's east end between two Scarlet guards, facing west.
  2. Turn right up the long north hall, on its red runner.
  3. Through the east door of the Chamber of Atonement, the first gate. Past the torture table, Interrogator Vishas and his torturer.
  4. Out of the west door and down the stairs: the second gate, *Forlorn Cloister*.
  5. Across the open cloister: a stone path round the ruined fountain, with lawns of graves, crypts and dead trees either side, and ghosts and the walking dead.
  6. The finish: the chequered line in the door of Honor's Tomb, where Bloodmage Thalnos waits.
- **No road:** the floor is open from wall to wall, and the karts find their own line. Stone has full grip, the lawn slows them, and the graves block.
- **Size:**
  - 2048 × 1024 world units;
  - 18 rooms and 52 solids;
  - about 2,200 units from the portal to the finish along the reviewed route.
- **Sprint:** one run through three gates. The HUD reads "Sprint" with the run time and gates. The results show the run's total and "All 3 gates", and the Graveyard has its own one-run board.
- **The look:** the monastery at night in Warcraft III art.
  - Dark coursed masonry, and north walls built from the city wall cliff's stones.
  - Beige halls, a red-brown torture chamber, pale stairs and a grey marble tomb.
  - Red runners with gold edges.
  - Torches, braziers and lanterns in warm pools, and green fire in the tomb.
  - The open cloister graded to cool moonlight, with mist.
  - The Scarlet Crusade's own banners and soldiers, from Reforged's art.
- **The cup:** a third heading on the track screen. The Graveyard is ready; the Library, Armory and Monastery are coming soon.

## Decisions for review

1. **Karting scale.** The rooms keep his map's plan and proportions, but halls and doors are 120 to 160 units wide so karts can drive them (the kart body is 17×31, `wallInset` 18). The world is 2048 × 1024, the first picture that is not square.
2. **Start and finish.** The grid is at his "!", the instance portal. The finish is the door of Honor's Tomb, his "END!", with Thalnos inside beyond the line.
3. **Three gates, all in doorways:** the chamber's east door, the stairs, and the tomb's door. None can be driven round. Between them the karts choose their line: either side of the torture table, the path or the lawn.
4. **The lawn** is Physics' existing rough ground, at most 70 units a second, so the stone path across the cloister is the fast way. The carpets are only paint, so all the stone has the same grip.
5. **Solids:** 52 boxes, all using Track's sliding. The graves stand in rows on the lawns, kept clear of the path, the fountain's court and the walks. The rest are the fountain, the crypts and trees, the chamber's table and cage, the guards and the dead.
6. **Minimal sprint rules** ([ADR 0020](../adr/0020-dungeon-sprints.md)): one optional track field; Checkpoints and Laps are unchanged. `LiveRace` already refuses a bundle that is not three laps, so a sprint cannot go live.

## Needs Codex: score sync learns the new courses

**Problem.** It is the Thunder Bluff problem, now with nine courses. `ScoreSync` knows seven courses by one-letter code, and `Sync.new` requires exactly seven contexts. `ScoreSharing` builds one context per selectable course: nine on this branch. `Sync.new` returns `nil,"options"`, and the status becomes "Score synchronization unavailable" for every course. `test_score_sharing` fails ("automatic native flow did not converge before the bounded deadline"). Local saving is unaffected, and so are `test_highscores` and `test_solo_records`.

**Proposed patch** (Codex's decision; not applied; these are Codex's files). It supersedes [Thunder Bluff's](#needs-codex-score-sync-learns-thunder-bluff):

- codes `T` for `thunder_bluff_skyway` and `G` for `scarlet_graveyard`;
- `BOARDS = #courseIds` in place of the literal 7;
- a HELLO with one board hash per course: eleven fields, still far under the 240-byte limit;
- `test_score_sync`'s ids gain both courses;
- `test_score_sharing`'s module list gains `Dungeon` and `ScarletCrusade`, which the course catalogue now needs.

A sprint's context has lap count 1. ScoreSync's record codec already accepts any lap count from 1.

**Tested:** `git apply --check` passes on `eaebffb`. With the patch, the whole Lua 5.1 suite passes on an archive of `eaebffb` in the cloud: 42 modules, `test_score_sync` and `test_score_sharing` included.

```diff
--- a/addon/AzerothKart/ScoreSync.lua
+++ b/addon/AzerothKart/ScoreSync.lua
@@ -6,8 +6,9 @@
     HELLO_INTERVAL=60, REQUEST_TIMEOUT=120, MAX_ROWS=50}
 AK.ScoreSync = Sync
 local courseIds={"test_oval","mirage_raceway","stormwind_city","ironforge_gp",
-    "darnassus_canopy","orgrimmar_canyon","undercity_slime"}
-local courseCodes={"O","M","S","I","D","R","U"}
+    "darnassus_canopy","orgrimmar_canyon","undercity_slime","thunder_bluff_skyway","scarlet_graveyard"}
+local courseCodes={"O","M","S","I","D","R","U","T","G"}
+local BOARDS=#courseIds
 local courseToCode,codeToCourse={},{}
 for i,id in ipairs(courseIds) do courseToCode[id],codeToCourse[courseCodes[i]]=courseCodes[i],id end
 local kartIds={"goblin_mortar_trike","steam_tank","dwarven_biker","dwarf_car",
@@ -59,7 +60,7 @@
         and integer(message.hash,0,4294967295) and integer(message.count,0,Sync.MAX_ROWS) then
         text=table.concat({"1 E",message.code,decimal(message.hash),decimal(message.count)}," ")
     elseif message.kind=="HELLO" and integer(message.physicsVersion,1,2147483647)
-        and integer(message.catalogHash,0,4294967295) and dense(message.hashes,7)==7 then
+        and integer(message.catalogHash,0,4294967295) and dense(message.hashes,BOARDS)==BOARDS then
         local parts={"1 H",decimal(message.physicsVersion),decimal(message.catalogHash)}
         for _,value in ipairs(message.hashes) do
             if not integer(value,0,4294967295) then return nil,"hash" end
@@ -106,10 +107,10 @@
         if codeToCourse[code] and stamp and n then return {kind="END",code=code,hash=stamp,count=n} end
     elseif tag=="H" then
         local p={};for field in rest:gmatch("[^ ]+") do p[#p+1]=field end
-        if #p~=9 or table.concat(p," ")~=rest then return nil,"hello" end
+        if #p~=BOARDS+2 or table.concat(p," ")~=rest then return nil,"hello" end
         local physics,catalog=number(p[1],1,2147483647),number(p[2],0,4294967295)
         local hashes={}
-        for i=1,7 do hashes[i]=number(p[i+2],0,4294967295);if not hashes[i] then return nil,"hello" end end
+        for i=1,BOARDS do hashes[i]=number(p[i+2],0,4294967295);if not hashes[i] then return nil,"hello" end end
         if physics and catalog then return {kind="HELLO",physicsVersion=physics,catalogHash=catalog,hashes=hashes} end
     end
     return nil,"message"
@@ -129,7 +130,7 @@
     s.now=now;return true
 end
 function Sync.new(options,now)
-    if not plain(options) or not H.NormalizeName(options.name) or dense(options.contexts,7)~=7 then return nil,"options" end
+    if not plain(options) or not H.NormalizeName(options.name) or dense(options.contexts,BOARDS)~=BOARDS then return nil,"options" end
     local store,writable=H.Load(options.store)
     if not writable then return nil,"store" end
     local s={name=H.NormalizeName(options.name),key=identity(options.name),contexts={},store=store,
--- a/tests/test_score_sync.lua
+++ b/tests/test_score_sync.lua
@@ -3,7 +3,7 @@
 local H=assert(loadfile("addon/AzerothKart/Highscores.lua"))("AzerothKart",AK)
 local S=assert(loadfile("addon/AzerothKart/ScoreSync.lua"))("AzerothKart",AK)
 local ids={"test_oval","mirage_raceway","stormwind_city","ironforge_gp",
-    "darnassus_canopy","orgrimmar_canyon","undercity_slime"}
+    "darnassus_canopy","orgrimmar_canyon","undercity_slime","thunder_bluff_skyway","scarlet_graveyard"}
 local contexts={}
 for i,id in ipairs(ids) do contexts[i]={trackId=id,trackVersion=1,physicsVersion=11,
     lapCount=3,tickRate=60,rulesVersion=1} end
--- a/tests/test_score_sharing.lua
+++ b/tests/test_score_sharing.lua
@@ -102,7 +102,7 @@
             return frame
         end
         using(client,function()
-            for _,module in ipairs({"Track","MirageRaceway","Circuit","CapitalCities","Courses",
+            for _,module in ipairs({"Track","MirageRaceway","Circuit","CapitalCities","Dungeon","ScarletCrusade","Courses",
                 "Physics","Highscores","SoloRecords","ScoreSync","ScoreDiscovery","ScoreSharing"}) do
                 assert(loadfile("addon/AzerothKart/"..module..".lua"))("AzerothKart",client.namespace)
             end
```

## Needs Codex: review of the sprint rules and the dungeon geometry

1. **`Race.lua` and `SoloRecords.lua`**, the owner-approved changes. Nothing else in Codex's modules changed.

   ```diff
   diff --git a/addon/AzerothKart/Race.lua b/addon/AzerothKart/Race.lua
   index c8f97fd..8eb58cf 100644
   --- a/addon/AzerothKart/Race.lua
   +++ b/addon/AzerothKart/Race.lua
   @@ -14,11 +14,26 @@ local function requireLaps(laps)
            and type(laps.step) == "function", "lap module required")
    end

   +-- A course may set its run's length (`track.laps`, 1-9): a sprint is one run
   +-- from the spawn to its last gate. Every other course runs three laps.
   +local function courseLaps(track)
   +    local count = type(track) == "table" and track.laps or nil
   +    if count == nil then return 3 end
   +    assert(validTick(count) and count >= 1 and count <= 9, "course lap count must be an integer from 1 to 9")
   +    return count
   +end
   +
   +local function finishReason(targetLaps)
   +    if targetLaps == 1 then return "Sprint complete" end
   +    if targetLaps == 3 then return "Three-lap run complete" end
   +    return ("%d-lap run complete"):format(targetLaps)
   +end
   +
    function Race.new(track, checkpoints, laps, tick)
        requireLaps(laps)
        if tick == nil then tick = 0 end
        return {
   -        status="countdown", laps=laps.new(track,checkpoints,tick), targetLaps=3,
   +        status="countdown", laps=laps.new(track,checkpoints,tick), targetLaps=courseLaps(track),
            countdownTicks=Race.COUNTDOWN_TICKS, startTick=nil,
            lastTick=tick, totalTicks=0, finishTick=nil, reason=nil,
        }
   @@ -61,7 +76,7 @@ function Race.step(race, previous, current, track, checkpoints, laps)
            targetLaps=race.targetLaps, countdownTicks=race.countdownTicks, startTick=race.startTick,
            lastTick=current.tick, totalTicks=current.tick-race.startTick,
            finishTick=finished and current.tick or nil,
   -        reason=finished and "Three-lap run complete" or nil,
   +        reason=finished and finishReason(race.targetLaps) or nil,
        }
    end

   diff --git a/addon/AzerothKart/SoloRecords.lua b/addon/AzerothKart/SoloRecords.lua
   index 4567799..05c4b41 100644
   --- a/addon/AzerothKart/SoloRecords.lua
   +++ b/addon/AzerothKart/SoloRecords.lua
   @@ -56,8 +56,9 @@ end

    function Records.Context(track)
        if type(track) ~= "table" then return nil end
   +    -- A sprint course (track.laps 1) keeps its own one-run boards.
        local context = {trackId=track.id, trackVersion=track.version,
   -        physicsVersion=Physics.VERSION, lapCount=3, tickRate=60, rulesVersion=Scores.RULES_VERSION}
   +        physicsVersion=Physics.VERSION, lapCount=track.laps or 3, tickRate=60, rulesVersion=Scores.RULES_VERSION}
        if Scores.BoardKey(context) then return context end
    end

   ```

2. **`Dungeon.lua`**: the contract is in [API_CONTRACTS](../API_CONTRACTS.md#proposed-dungeon-sprints-the-scarlet-crusade-cup).
   - It is the standard track interface over rooms and solid boxes.
   - Solids use Track's swept-box sliding.
   - Walls project to the nearest floor point within the step's length, so `checkpointMaxStep` holds.
   - It is covered by `test_dungeon`, including 4,000 random steps that never end off the floor or move further than asked.
3. **Proposed status line** (`UI.Start` and `step` are Codex's; not applied). Both still say "3 laps" on a sprint. Tested with the score-sync patch: the whole suite passes.

   ```diff
   --- a/addon/AzerothKart/UI.lua
   +++ b/addon/AzerothKart/UI.lua
   @@ -1440,7 +1440,8 @@
        UI.active = true
        render()
        refreshHud()
   -    UI.status:SetText("3 laps | Hold W/Up for GO | A/D or arrows: steer | Stop / Esc: end run")
   +    UI.status:SetText((UI.race.targetLaps == 1 and "Sprint" or "3 laps")
   +        .. " | Hold W/Up for GO | A/D or arrows: steer | Stop / Esc: end run")
        UI.startButton:Disable()
        UI.stopButton:Enable()
        UI.trackButton:Disable()
   @@ -1459,7 +1460,8 @@
        UI.checkpoints = UI.laps.checkpoints
        if countdown and UI.race.status == "running" then
            UI.stopReason = "Driving"
   -        UI.status:SetText("3 laps | W/A/S/D or arrows | Space + turn: drift | Stop / Esc: end run")
   +        UI.status:SetText((UI.race.targetLaps == 1 and "Sprint" or "3 laps")
   +            .. " | W/A/S/D or arrows | Space + turn: drift | Stop / Esc: end run")
        end
        return UI.race.status ~= "finished"
    end
   ```

4. **Install:**
   - New files, which need a full client restart: `Dungeon.lua`, `ScarletCrusade.lua`, and `Assets/Tracks/ScarletGraveyard/Background.tga` and `Preview.tga`.
   - Changed: `Race.lua`, `SoloRecords.lua`, `Courses.lua`, `Menu.lua`, `UI.lua`, both TOCs, plus `ScoreSync.lua` with Codex's change.
   - The 8 MiB picture loads only when the Graveyard is selected.
5. **Multiplayer is unchanged.** No dungeon is in `RaceProtocol`'s track codes, city and dungeon multiplayer stay unwired, and `LiveRace` refuses a sprint's bundle.

## Tests performed

The cloud ran Python 3.13 and Lupa 2.8. The developer machine's Linux shell ran Python 3.10.12 and Lupa 2.8, with its own Warcraft III extraction and sprite cache.

| Command / check | Result |
|---|---|
| `python scripts/build_dungeon_tracks.py --wc3 … --check` at `eaebffb` | **CHECK PASS** for `ScarletCrusade.lua` and both pictures, byte-identical on both machines: Background `162029c4…26d9e4`, Preview `b177650d…fed585`. |
| The same, from the sheet's own rebuild commands | **CHECK PASS** on the developer machine. The extraction was made fresh with exactly the sheet's two `wc3casc.py` commands, read from the sheet, against the owner's Warcraft III install, into an empty folder. The sprite cache was empty too, so all 50 sprites were rendered there. |
| `python scripts/test_lua.py --runtime lua51 --tests <the 41 other modules>` | **PASS** on both machines (`dungeon`, `ui` and `menu` included; mock pool 90/167/136). |
| `… --tests score_sharing` | **FAIL** on both machines, as expected: the score-sync blocker above. |
| The whole Lua 5.1 suite with the score-sync patch | **PASS**, 42 modules, on an archive of `eaebffb` (cloud). Also PASS with the status-line proposal added. |
| `… --runtime lua54 --tests dungeon circuit menu ui race solo_records highscores` | **PASS** on both machines. |
| `python -m pytest tests/test_circuit_boundary.py tests/test_leaderboard_store.py` | **24 passed** in the cloud. The developer machine has no pytest, so this was NOT RUN there. |
| `python scripts/export_score_catalog.py --check` | **CHECK PASS**, nine canonical boards, on both machines. |
| `python scripts/validate_project.py` | Only the 2 pre-existing Windows-path links in `PROGRESS.md` fail, on both machines. |
| `git diff --check` | Clean. |
| Review | The whole floor with the way through, plus nine follow-camera views (533 × 320 world units, the play camera's area): the portal, the north hall, the chamber's door, the torture table, the stairs, the cloister, the fountain, the graves and the finish ([image](../art/tracks/scarlet_graveyard-review.png)). |

**NOT RUN:**

- the client: the drive, the walls, the lawn, the HUD, the look in the follow camera, loading the 2048 × 1024 picture, performance;
- any install;
- multiplayer;
- score sync with real peers.

## Client check (owner; NOT RUN; after Codex's review and a coordinated install)

[The client checklist's new section](../../tests/MANUAL_CLIENT_CHECKLIST.md#deferred-scarlet-graveyard-check-proposed-claudescarlet-graveyard) covers:

- the third cup on the track screen and the Track button's cycle;
- loading the first non-square picture;
- finding the way past the three gates;
- the walls, doorways and graves;
- the lawn's slowdown;
- the sprint HUD, results and board;
- the look;
- the camera at the picture's edges, and the frame rate.

**A full client restart is needed**, because the files are new.

## PROGRESS ledger entry for the integrator (Scarlet Graveyard)

> ### 2026-10-25 ~21:50 CET — Claude / `claude/scarlet-graveyard`, Scarlet Graveyard
>
> - The Scarlet Crusade Cup's first dungeon sprint, Scarlet Graveyard, is selectable. It follows the owner's route from the portal through the Chamber of Atonement and the Forlorn Cloister to Honor's Tomb: one run, three doorway gates, 18 rooms, 52 solids, grass slows and graves block. The Library, Armory and Monastery are coming soon.
> - Proposed for Codex's review (ADR 0020):
>   - owner-approved sprint rules: `track.laps` sets `Race`'s target, and `SoloRecords` keeps one-run boards;
>   - new pure `Dungeon.lua` geometry.
> - `build_dungeon_tracks.py --check` PASS, byte-identical in the cloud and on the developer machine, including from a fresh extraction by the sheet's commands.
> - The Lua 5.1 suite PASS except `test_score_sharing`: `ScoreSync` expects seven courses. Codex's extended patch is in the handoff, and the whole suite passes with it.
> - Lua 5.4 sprint modules PASS; catalogue check PASS (nine boards); validator: only the 2 pre-existing `PROGRESS.md` links fail.
> - **Blocker:** not installable until Codex's score-sync change lands. **NOT RUN:** the client; install.

## Commits, push and workspace

| Item | Value |
|---|---|
| Worktree / branch | `AzerothKart-Claude` / `claude/scarlet-graveyard`, from `claude/thunder-bluff` `a7aeb66`. |
| Commits | `a54463e` (the reservation), `eaebffb` (Scarlet Graveyard: course, geometry, sprint rules, pictures, painter, catalogue, menus, tests, docs), then this handoff. |
| Push | Owner only, because this session's git proxy refuses the repository. Push both branches, since the Graveyard's contains Thunder Bluff's commits: `git -C "C:\Users\bakke\Downloads\Forever_Addons\AzerothKart_Codex_Project_Pack\AzerothKart-Claude" push -u origin claude/thunder-bluff claude/scarlet-graveyard` |
| Not done | No merge into `main` or any Codex branch; no tag, release, install or client input. Codex's files and worktrees were only read. |

**Workspace notes:**

- As for Thunder Bluff, commits are made in a cloud clone with this repository's local identity, then moved as git bundles (`local-artifacts/bundles/`), so the hashes are identical on the developer machine.
- Git runs from a Linux shell on the developer machine with automatic maintenance off. It never prunes or garbage-collects.
- With the delete access the owner granted for this session, the fast-forward ran normally.
- The one temporary ref the fetch used was deleted, and no lock or temporary files were left.
- The worktree is clean apart from the untracked `Claude outputs/` folder, where the review image is.

## Next

1. **The owner:**
   - look at the review image;
   - say whether the rooms, the way through and the lawn feel right;
   - push both branches.
2. **Codex:**
   - review ADR 0020 (`Race`, `SoloRecords`, `Dungeon`);
   - apply the score-sync change, or its own version of it;
   - decide on the status line;
   - integrate Thunder Bluff and the Graveyard, then make a coordinated install with a full client restart.
3. **The owner:** the client checks above, especially the doorways at speed, the lawn and whether the halls read.
4. **Claude:** Scarlet Library next, then the Armory and the Monastery. Each needs the owner's map of that wing with his route, as for the Graveyard. They should need no new runtime code: only their layouts and pictures, on `Dungeon` and the same painter.

# Previous: Thunder Bluff Skyway

Prepared 2026-10-25 at about 19:45 CET (Europe/Oslo) by Claude (rendering/UI/sprites owner).

This supersedes the pod racer handoff (`claude/podracer-arrows-outline` `0afeedf`). Codex reviewed and integrated that work (`77a1891` on `codex/podracer-score-review`); the installed runtime is now Codex's `bb085ac` (Physics12).

**Base:** `aac1bdd`, Codex's docs commit on `bb085ac`. **Branch:** `claude/thunder-bluff`; its commits are listed under [Branch, commits and workspace](#branch-commits-and-workspace).

> **Do not install this branch on its own.** With Thunder Bluff selectable, `ScoreSync` does not start, because it expects exactly seven courses. Community score sharing would then stop for every course; local saving is unaffected. Codex's change is described [below](#needs-codex-score-sync-learns-thunder-bluff), with a tested patch.

## Owner instructions

"Alright. Let's get to work. Thunderbluff - the final map in the capital cities cup. As you can see - plank roped bridges, long way down, white stone paths, if you can - make the road edges like these poles with ropes."

He sent four images:

- his blue line on the in-game Thunder Bluff map, with an X where it starts;
- the mesas' rope bridges over the drop;
- a mesa top with tents and a white stone path;
- a stone path edged with wooden posts and sagging rope.

The standing instructions still hold:

- no merge into `main`;
- no claim of in-game verification without the actual client;
- the simulation-control functions in `UI.lua` stay untouched;
- the owner pushes and runs the client checks, and Codex prepares coordinated installs.

## Scope (reserved and changed)

The reservation (`00d0d2a`) held. No physics, input, timing, networking, `UI.lua`, `Circuit.lua` or score-module change was made.

- **`scripts/city_layouts.py`:** a new Thunder Bluff section (`TB_*`, `THUNDER_BLUFF`), its start sign and its `CITIES` entry. The other cities are unchanged.
- **`scripts/city_paint.py`:** new painting that a city opts into. A city without `chasm` or `rope_fence` paints byte for byte as before:
  - the drop off the mesas: `chasm_land`, `paint_chasm` and their helpers (`_byte_rows`, `_shift_rows`, `_smear_rows`, `SOFT_TAPS`, `_Noise`);
  - the rope-plank deck: `OVER_DROP`, `rope_plank` and the deck branch of `paint_street`;
  - the rope fence: the rope branch of `wall_columns`, and `_rope_column` in `paint_wall_row`;
  - a `land` argument to `paint_sprite`/`paint_scenery` that keeps models' ground shadows off the drop;
  - the chasm step in `build()`.
- **`addon/AzerothKart/CapitalCities.lua`** (generated): one new entry, which uses only existing definition fields. The other entries are unchanged.
- **`addon/AzerothKart/Assets/Tracks/ThunderBluff/`** (new): `Background.tga` and `Preview.tga`.
- **`addon/AzerothKart/Courses.lua`:** the `thunder_bluff_skyway` entry, which was coming soon and is now selectable. No course is listed `soon` now; the mechanism stays for future courses.
- **`addon/AzerothKart/Menu.lua`:** Thunder Bluff's track copy (`Menu.TRACKS`) and its preview cell (`PREVIEW_CELLS.thunderbluff`).
- **Tests:**
  - `tests/test_circuit.lua`: the catalogue now has no coming-soon course, and its coming-soon check marks Thunder Bluff soon for one assertion. Thunder Bluff gets its own checks.
  - `tests/test_menu.lua`: the longer Track-button cycle, and a fixture for the coming-soon row.
- **`services/leaderboard/catalog.json`** (generated by `export_score_catalog.py`): Thunder Bluff's board, eight in all. Codex should review it.
- **`scripts/validate_project.py`:** requires Thunder Bluff's sheet, sources list and two pictures.
- **Docs:**
  - new: [track sheet](../art/tracks/thunder-bluff.md), with its overview, review image and sources list;
  - updated: `ASSET_SOURCES.md`, `TRACKS.md`, `README.md`, `ASSETS.md`, `INDEX.md`, `API_CONTRACTS.md`, `TEST_PLAN.md`, ADR 0015 (one line), `CHANGELOG.md` and `tests/MANUAL_CLIENT_CHECKLIST.md`.

`docs/PROGRESS.md` was not edited; the entry is [below](#pending-progress-ledger-entry-integrator-to-append-progressmd-was-not-edited).

## Delivered

![The loop, its direction and nine follow-camera views](../art/tracks/thunder_bluff_skyway-review.png)

Thunder Bluff Skyway, the sixth and last Capital Cities Cup city. The [track sheet](../art/tracks/thunder-bluff.md) has the full record.

- **The route** is traced from his line. The grid is on the road in from the lift, at his X. At the junction the course bears left (a start sign points north-west) and crosses the finish line. It then runs clockwise:
  - out over the west bridge, round the Spirit Rise and back over the north bridge;
  - east along the Lower Rise's north side;
  - along the long bridge, round the Elder Rise past Cairne's lodge and back over the lower bridge;
  - down the east side past the wind riders' roost;
  - over the east bridge, across the Hunter Rise and back over the south-west bridge;
  - west along the south side to the junction.
- **Gates (six):** Spirit Rise, Lower Rise, Elder Rise, Wind Rider Roost, Hunter Rise, and The Lift (the finish).
- **Size:** a 5,616-unit lap and a 285-unit approach.
- **Bridges:** six, with 2,080 units of deck, 1,888 of them over the drop.
- **Driving:** the shared street circuit, with full grip to the walls, `wallClearance` 14 (1,120 junctions), and no plazas, solids or heights. Collision comes from the analytic data, never from a pixel. A kart cannot fall: the drop is only painted.
- **Plank rope bridges:**
  - single boards laid square to each bridge, with the drop showing between them;
  - the planks' ends and a beam under the deck's southern edge;
  - a rope hanging under each deck, with the deck tied to it;
  - a totem at the bridges' corners.
- **A long way down:** everything off the mesas drops 400 units.
  - From the camera that is 240 rows, so each mesa's southern edge hangs a pale sandstone face that tall.
  - Below lies Mulgore's plain: hazy, with the mesas' soft shadows, small pines and a river.
- **White stone paths:** the village cobbles, whitened, from wall to wall.
- **Poles with ropes:** every street edge is a rope fence.
  - On the rock: posts every 34 units with one sagging rope.
  - On the bridges: posts every 30 units with a hand rope and a lower rope.
- **The city:** tauren tents, totems, fire pits and pines, with tauren, spirit walkers and kodos. The landmarks are:
  - the great totem and the pool on the Lower Rise;
  - the lift tower;
  - the wind riders' roost;
  - the spirit lodge;
  - Cairne before his lodge;
  - the hunters' hall.

## Decisions for review

1. **Clockwise.** The owner marked no direction. His stroke runs from the start road straight on up the west side, and it closes at the X, so the course runs clockwise. Reversing it is a small layout change and a rebuild:
   - the loop's order;
   - the gates' order;
   - the finish line's place (it stands just past the junction);
   - the start sign's arrow.
2. **Wider turns.** The rises' turns are widened from the map (a 132-unit radius on the centerline) so that a kart can take them.
3. **Narrow bridges.** Each deck is one reviewed `narrows` with a wall radius of 54 (the street's is 76). That makes the deck 136 units between its ropes, against the street's 180.
   - The narrows cover the whole deck, which runs 16 units onto the rock at either end.
   - The step where a deck begins catches only a kart well off the line.
   - The width at speed is an open client question.
4. **No heights.** The course is on the mesas' one level. The drop is an art layer (`chasm`), with no `elevation` table (ADR 0015 notes this).

## Needs Codex: score sync learns Thunder Bluff

**Superseded:** apply the [extended patch above](#needs-codex-score-sync-learns-the-new-courses), which adds the Graveyard's code as well. This section stays as the record of the Thunder Bluff change.

**Problem.** `ScoreSync` knows seven courses by one-letter code, and `Sync.new` requires exactly seven contexts. `ScoreSharing` builds one context per selectable course, so with Thunder Bluff it offers eight. `Sync.new` then returns `nil,"options"`, and `ScoreSharing`'s status becomes "Score synchronization unavailable", for every course. `test_score_sharing` fails ("automatic native flow did not converge before the bounded deadline"). Local saving is unaffected, and so are `test_highscores` and `test_solo_records`.

**Proposed patch (Codex's decision; not applied; these are Codex's files):**

- an eighth code, `T`, for `thunder_bluff_skyway`;
- `BOARDS = #courseIds` in place of the literal 7;
- a HELLO with one board hash per course (ten fields).

Peers on an older build would refuse the longer HELLO, much as they already refuse a different catalogue hash, which Thunder Bluff's board changes anyway. Whether to also bump the prefix or version is Codex's call. The HELLO stays far under the 240-byte message limit.

Tested on a scratch checkout of `ea2238c` with the patch applied: the whole Lua 5.1 suite passes (`python scripts/test_lua.py --runtime lua51`), `test_score_sync` and `test_score_sharing` included. `git apply --check` passes on `ea2238c`.

```diff
diff --git a/addon/AzerothKart/ScoreSync.lua b/addon/AzerothKart/ScoreSync.lua
--- a/addon/AzerothKart/ScoreSync.lua
+++ b/addon/AzerothKart/ScoreSync.lua
@@ -6,8 +6,9 @@ local Sync = {PREFIX="AZKSCR1", MAX_BYTES=240, MAX_PEERS=32, SEND_INTERVAL=1,
     HELLO_INTERVAL=60, REQUEST_TIMEOUT=120, MAX_ROWS=50}
 AK.ScoreSync = Sync
 local courseIds={"test_oval","mirage_raceway","stormwind_city","ironforge_gp",
-    "darnassus_canopy","orgrimmar_canyon","undercity_slime"}
-local courseCodes={"O","M","S","I","D","R","U"}
+    "darnassus_canopy","orgrimmar_canyon","undercity_slime","thunder_bluff_skyway"}
+local courseCodes={"O","M","S","I","D","R","U","T"}
+local BOARDS=#courseIds
 local courseToCode,codeToCourse={},{}
 for i,id in ipairs(courseIds) do courseToCode[id],codeToCourse[courseCodes[i]]=courseCodes[i],id end
 local kartIds={"goblin_mortar_trike","steam_tank","dwarven_biker","dwarf_car",
@@ -59,7 +60,7 @@ function Sync.encode(message)
         and integer(message.hash,0,4294967295) and integer(message.count,0,Sync.MAX_ROWS) then
         text=table.concat({"1 E",message.code,decimal(message.hash),decimal(message.count)}," ")
     elseif message.kind=="HELLO" and integer(message.physicsVersion,1,2147483647)
-        and integer(message.catalogHash,0,4294967295) and dense(message.hashes,7)==7 then
+        and integer(message.catalogHash,0,4294967295) and dense(message.hashes,BOARDS)==BOARDS then
         local parts={"1 H",decimal(message.physicsVersion),decimal(message.catalogHash)}
         for _,value in ipairs(message.hashes) do
             if not integer(value,0,4294967295) then return nil,"hash" end
@@ -106,10 +107,10 @@ function Sync.decode(payload)
         if codeToCourse[code] and stamp and n then return {kind="END",code=code,hash=stamp,count=n} end
     elseif tag=="H" then
         local p={};for field in rest:gmatch("[^ ]+") do p[#p+1]=field end
-        if #p~=9 or table.concat(p," ")~=rest then return nil,"hello" end
+        if #p~=BOARDS+2 or table.concat(p," ")~=rest then return nil,"hello" end
         local physics,catalog=number(p[1],1,2147483647),number(p[2],0,4294967295)
         local hashes={}
-        for i=1,7 do hashes[i]=number(p[i+2],0,4294967295);if not hashes[i] then return nil,"hello" end end
+        for i=1,BOARDS do hashes[i]=number(p[i+2],0,4294967295);if not hashes[i] then return nil,"hello" end end
         if physics and catalog then return {kind="HELLO",physicsVersion=physics,catalogHash=catalog,hashes=hashes} end
     end
     return nil,"message"
@@ -129,7 +130,7 @@ local function clock(s,now)
     s.now=now;return true
 end
 function Sync.new(options,now)
-    if not plain(options) or not H.NormalizeName(options.name) or dense(options.contexts,7)~=7 then return nil,"options" end
+    if not plain(options) or not H.NormalizeName(options.name) or dense(options.contexts,BOARDS)~=BOARDS then return nil,"options" end
     local store,writable=H.Load(options.store)
     if not writable then return nil,"store" end
     local s={name=H.NormalizeName(options.name),key=identity(options.name),contexts={},store=store,
diff --git a/tests/test_score_sync.lua b/tests/test_score_sync.lua
--- a/tests/test_score_sync.lua
+++ b/tests/test_score_sync.lua
@@ -3,7 +3,7 @@ local AK={}
 local H=assert(loadfile("addon/AzerothKart/Highscores.lua"))("AzerothKart",AK)
 local S=assert(loadfile("addon/AzerothKart/ScoreSync.lua"))("AzerothKart",AK)
 local ids={"test_oval","mirage_raceway","stormwind_city","ironforge_gp",
-    "darnassus_canopy","orgrimmar_canyon","undercity_slime"}
+    "darnassus_canopy","orgrimmar_canyon","undercity_slime","thunder_bluff_skyway"}
 local contexts={}
 for i,id in ipairs(ids) do contexts[i]={trackId=id,trackVersion=1,physicsVersion=11,
     lapCount=3,tickRate=60,rulesVersion=1} end
```

`ScoreSync` is the only module outside `Courses`/`Menu` that lists course ids. Multiplayer is unchanged: as for the other cities, Thunder Bluff is not in `RaceProtocol`'s track codes, and city multiplayer stays unwired.

## Other changes Codex must review

1. **`Courses.lua` and `CapitalCities.lua`:** Thunder Bluff is selectable. Its definition (version 1) has six `narrows`, one per bridge, at wall radius 54. It uses only existing fields, with no `Circuit` change.
2. **Tests:**
   - `test_circuit.lua` expects no coming-soon course and marks Thunder Bluff soon for one assertion.
   - It walks the six gates in order with a wall-free centerline, finds every bridge road up to its own wall (road at 52, wall at 56), and runs the gate-end and throttle loops. Thunder Bluff has no `elevation`, so the elevation check skips it.
   - `test_menu.lua` adds a soon fixture through its prepare hook.
3. **UI object counts are unchanged.** The eight pooled track buttons now show eight ready tracks, and the existing count assertions pass as they were.
4. **Install:**
   - New files, which need a full client restart: `Assets/Tracks/ThunderBluff/Background.tga` (16,777,234 bytes) and `Preview.tga` (1,048,594 bytes).
   - Changed: `CapitalCities.lua`, `Courses.lua` and `Menu.lua`, plus `ScoreSync.lua` with Codex's change.
   - One more 2048-square picture loads only when Thunder Bluff is selected; the staging/visible bound is unchanged.

## Tests performed

The cloud ran Python 3.13 and Lupa 2.8. The developer machine's Linux shell ran Python 3.10.12, Lupa 2.8 and its own Warcraft III extraction and sprite cache.

| Command / check | Result |
|---|---|
| `python scripts/build_city_tracks.py --wc3 … --check --city <each>` at `ea2238c` | **CHECK PASS** for `CapitalCities.lua` and all twelve pictures, on both machines, byte-identical. Thunder Bluff Background is `9ff1c444…d71781` and Preview `9c1ba186…eb8d9c8`. The other five cities are unchanged: Stormwind `ec016e7e…`, Ironforge `5cf1e688…`, Orgrimmar `3abf44b2…`, Darnassus `80a6715e…`, Undercity `caedb2c9…`. The developer machine rendered Thunder Bluff's 165 new sprites itself (90 s). |
| `python scripts/test_lua.py --runtime lua51` | **FAIL at `test_score_sharing` only** (the score-sync blocker above), on both machines. The suite stops there; the other 40 modules pass on both machines (before the stop or run with `--tests`), `circuit` and `menu` included. |
| The same with the score-sync patch, on a scratch checkout | **PASS**: the whole Lua 5.1 suite, in the cloud. |
| `python scripts/test_lua.py --runtime lua54 --tests <all but score_sharing>` | **PASS** on the developer machine (40 modules). `test_score_sharing` fails under Lua 5.4 at line 16 (`unpack` is nil). That failure already occurs at `aac1bdd` and is not from this branch. |
| `python -m pytest tests/test_circuit_boundary.py tests/test_leaderboard_store.py` | **24 passed** in the cloud. The developer machine has no pytest, so this was NOT RUN there. |
| `python scripts/export_score_catalog.py --check` | **CHECK PASS**, eight canonical boards, on both machines. |
| `python scripts/validate_project.py` | Only the 2 pre-existing Windows-path links in `PROGRESS.md` fail, on both machines. |
| `wc3casc.py list` with the sheet's rebuild patterns, against the owner's Warcraft III install | Every model and texture the picture uses matches (23 Thunder Bluff models, 6 textures). |
| `git diff --check` | Clean. |
| Review | The loop with its direction, plus follow-camera views of the junction, the lift, each bridge, the Elder and Hunter Rises, the faces and the rope fences ([image](../art/tracks/thunder_bluff_skyway-review.png)). |

**NOT RUN:** the client (the drive, the bridges' width, the look in the follow camera, loading, performance), any install, multiplayer, and the score sync with real peers.

## Client check (owner; NOT RUN; after Codex's review and a coordinated install)

[The client checklist's new section](../../tests/MANUAL_CLIENT_CHECKLIST.md#deferred-thunder-bluff-skyway-check-proposed-claudethunder-bluff) covers:

- the track screen and the Track button's cycle;
- loading the sixth city picture;
- the drive in order past the six gates;
- the bridges' width and the step onto each deck;
- whether the drop, the white streets and the rope edges read as his screenshots;
- the scores;
- the frame rate.

**A full client restart is needed**, because the files are new.

## Pending PROGRESS ledger entry (integrator to append; PROGRESS.md was not edited)

> ### 2026-10-25 ~19:45 CET — Claude / `claude/thunder-bluff`, Thunder Bluff Skyway
>
> - Thunder Bluff Skyway, the sixth and final Capital Cities Cup city, is selectable.
>   - It follows the owner's blue line, clockwise, from the lift round the Lower Rise and out to the Spirit, Elder and Hunter Rises over six rope bridges.
>   - Six gates, a 5,616-unit lap, full grip to the walls, and one `narrows` per bridge (wall radius 54).
> - New opt-in painter layers (the other five cities are byte for byte unchanged):
>   - `chasm`: the 400-unit drop off the mesas, with faces and Mulgore's plain;
>   - rope-plank decks;
>   - `rope_fence` posts and ropes along every street edge;
>   - whitened cobbles.
> - `build_city_tracks.py --check` PASS for all six cities, byte-identical in the cloud and on the developer machine.
> - The Lua 5.1 suite PASS except `test_score_sharing`: `ScoreSync` expects seven courses. Codex's patch is in the handoff, and the whole suite passes with it.
> - Catalogue check PASS; validator: only the 2 pre-existing `PROGRESS.md` links fail.
> - **Blocker:** not installable until Codex's score-sync change lands. **NOT RUN:** the client; install.

## Branch, commits and workspace

| Item | Value |
|---|---|
| Worktree / branch | `AzerothKart-Claude` / `claude/thunder-bluff`. The worktree previously held `claude/podracer-arrows-outline` `0afeedf`, unchanged. |
| Commits | On `aac1bdd`: `00d0d2a` (the reservation), `ea2238c` (Thunder Bluff Skyway: course, pictures, painter, catalogue, menu, tests, docs), `ed42c0b` (this handoff, with three doc clarifications: not installing alone; reversing the direction), then a workspace note. |
| Push | Owner only, because this session's git proxy refuses the repository: `git -C "C:\Users\bakke\Downloads\Forever_Addons\AzerothKart_Codex_Project_Pack\AzerothKart-Claude" push -u origin claude/thunder-bluff` |
| Not done | No merge into `main` or any Codex branch; no tag, release, install or client input. Codex's files and worktrees were only read. |

**Workspace notes:**

- Commits are made in a cloud clone with this repository's local identity, then moved as git bundles (`local-artifacts/bundles/`), so the hashes are identical on the developer machine.
- Git runs from a Linux shell on the developer machine with `--git-dir=.git/worktrees/AzerothKart-Claude`, automatic maintenance off. It never prunes or garbage-collects.
- **Git's leftover files, removed.** Without delete access, this session's git commands could not clean up after themselves. They left:
  - six `tmp_*` hard links to finished packs in `AzerothKart\.git\objects\pack`;
  - an empty `objects\maintenance.lock`, from one automatic maintenance run;
  - an `index.lock` in `worktrees\AzerothKart-Claude`, from an aborted fast-forward.

  The owner approved deletes in the worktree and in `AzerothKart\.git`. Only those eight files were deleted, after checking that each `tmp_*` file shares its inode with a pack. The fast-forward then completed normally.
- **Updating the worktree.** It was first updated to `ea2238c` without deleting files: each file git could not replace was rewritten in place from `HEAD`. It was then fast-forwarded to the handoff. It is clean apart from the untracked `Claude outputs/` folder, where review images are left for the owner.
- **Warcraft III files:** Thunder Bluff's models and textures come from the same Reforged install. The sheet's rebuild patterns were checked against it.

## Next

1. **The owner:**
   - look at the review image;
   - say whether clockwise is right and whether the bridges look wide enough;
   - push the branch.
2. **Codex:**
   - review;
   - apply the score-sync change, or its own version of it;
   - integrate, then make a coordinated install with a full client restart.
3. **The owner:** the client checks above, especially the bridges' width at speed and whether the drop reads.
4. **Possible follow-ups:**
   - reverse the direction;
   - widen or narrow the decks (`TB_BRIDGE_RADIUS`, the test's road and wall points, a rebuild);
   - tune the faces' or the plain's colour after the client look.
