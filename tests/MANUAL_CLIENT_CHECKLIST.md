# Manual client acceptance — F0/F1/F2/F5

## Deferred Warsong Gulch version 2 check (proposed, `claude/warsong-v2`)

**NOT RUN.** Run it after Codex's review and a coordinated install. **Fully restart the client:** `Battlegrounds.lua` and the three pictures in `Assets/Tracks/WarsongGulch/` change (same paths). Version 2 has its own board: version 1 times stay on theirs. The owner runs these checks; Claude does not control the client.

1. **Track screen:** Warsong's new preview (the gulch from above) and copy ("The real gulch: ..."). Note any hitch loading the two 8 MiB pictures.
2. **Does it look like Warsong Gulch?** The field with its two night elf and two orc huts, the Alliance's arch in the north cliff, Silverwing Hold with its towers and the forest round it, the Horde's tunnel mouth and the Lumber Mill among its fences, braziers and catapults, the dirt paths where the game has them. A screenshot of anything that reads wrong.
3. **The grid** at mid facing north; at GO the arrow points up the field at the Alliance tunnel, whose threshold glows (wide, pulsing).
4. **Into the tunnel:** the cover starts to fade before the arch, so the kart never vanishes; the Boots under the plateau boost once; up the climb into the hold, the kart draws over everything.
5. **Round the flag:** the flag on its dais at the end of the wall; nothing passes between them; rounding it west takes the gate. Down the lobby, out of the front door (its gate), through the front yard's turn (**the arrow points down the yard, then round toward the plateau, never into the yard's corner**; Codex's review of `d5fabbf` found it did), east across the plateau over the tunnel: **the arrow points east along the plateau, never through the hill**; down the east path.
6. **The field's east side** to the Horde tunnel (west of the east hut); its cover fades as the kart drives in; round the Horde flag; up the west passage; out of the side door; up the slope; across the field to mid. Three laps, the arrow always along the way.
7. **Checkpoints:** every gate's threshold is easy to see and the next one glows; the HUD names it ("Next: Alliance front door"). Any gate missed while driving the obvious way: where.
8. **Seams:** any misalignment where a cover meets the ground, an edge where it ends, or a place where the kart stops at nothing it can see (or passes something that looks solid): a screenshot of each.
9. **Two players:** a friend in a tunnel the player is not in is hidden by its cover; on the plateau or a ramp they draw over it.

## Deferred Warsong Gulch check (integrated, `codex/warsong-registration`)

Superseded by version 2 once it is installed; kept for version 1.

**NOT RUN.** The owner runs these checks; Claude does not control the client. Two stages. **Fully restart the client** after each install: `Battlegrounds.lua`, `Assets/Tracks/WarsongGulch/` and `Assets/UI/GuideArrow.tga` are new.

Warsong is now registered; earlier coming-soon checks are superseded. Both
players install the same build and fully restart WoW; no old-prefix fallback.

1. **Track screen.** Warsong Gulch is selectable under Battlegrounds Cup; no
   overlap with Back. Highscores cycles all12 current courses.
2. **Existing courses.** No roof or arrow elsewhere; current personal records
   remain visible in their original boards. No Test Oval entry.

3. **Choose Warsong Gulch:**3. **Choose Warsong Gulch:** its tall preview and three facts. Note any hitch: it loads two 8 MiB pictures (the ground and the roofs) and the arrow.
4. **The grid** at mid, facing north. No arrow until GO; then it points at the Alliance tunnel.
5. **The Alliance tunnel:** entering, the hill's picture fades to show the kart below; the Boots near the end boost once; the hill stands whole again outside.
6. **Silverwing Hold:** the roof fades over the halls and the flag room. The flag blocks where it is drawn; crossing the room west takes the gate.
7. **Up the front ramp** onto the plateau: from the ramp on, the kart draws over the hill and the roof, with no flicker at either end of the ramp. Along the plateau and down the ramp to the gully, then the gate.
8. **The optional way in:** the tunnel's side door, up the banana to the terrace, down the connector into the hall. The roof walk ends where drawn.
9. **The Lumber Mill:** the same, its roof and hill fading; the finish at mid; three laps, the arrow always pointing at the next gate.
10. **Seams:** any misalignment between the roofs and the ground, a visible edge where a roof's box ends, or a place where the kart stops at nothing it can see: a screenshot of each.
11. **Two players:** a friend below a roof the player is not under is hidden by it; on the plateau or a ramp they draw over it. After the race, choose a flat course together: where the two karts meet, the friend's kart draws as before Warsong, not over your kart, its outline or its flames.
12. **Dust:** drift on the plateau or the terrace: the dust shows over the hill and the roof, under the kart.

## Deferred Gryphon Rider wingbeat check (proposed, `claude/gryphon-wings`)

**NOT RUN.** Run it after Codex's review and a coordinated install. **Fully restart the client:** `GryphonRider.tga` and its outline keep their paths but are larger. The owner runs these checks; Claude does not control the client.

1. **The garage:** choose the Gryphon Rider. On the turntable its wings beat (raised, level, swept down) for four seconds, then it glides with its wings spread for two. Nothing reads "Lua error".
2. **A run:** the wings beat from the countdown on, about one and a half beats a second. Fire a boost: it glides, wings spread, the wind trails leaving its wingtips; when the boost ends, the beat resumes. Record whether the beat reads as flapping at race size or as flicker, whether it is too fast or too slow, and whether the glide is clear enough.
3. **Turning:** at every heading the gryphon faces its travel and its shadow moves with the wings; no neighbouring frame shows at a frame's edge.
4. **Outline on** (Settings): the line follows the wings.
5. **No run:** stop or finish: the gryphon rests with its wings level, as before.
6. **Two players:** a friend on the gryphon beats its wings too and glides while they boost.
7. **Memory:** choosing the gryphon loads a 16 MiB sheet: note any hitch when choosing it or starting a race with it.

## Deferred race screens and celebrations check (proposed, `claude/race-screens`)

**NOT RUN.** Run it after Codex's review and a coordinated install. **Fully restart the client:** `Assets/UI/Celebration.tga` is a new file. The owner runs these checks; Claude does not control the client.

1. **A top-ten celebration.** With shared scores running (the board reads "Shared community scores"), set a new personal best that ranks in the top ten; a fresh version-3 board (the Library or the Cathedral) puts the first run at #1. The results grow: the banner (**FIRST ON THE BOARD!**, **NEW #1!**, **TOP 3!** or **TOP 10!**) and "#N of M on the shared board" under it, the medal or the wreath with the rank popping in over the dialog's top edge on a slowly turning sunburst, confetti falling for under three seconds, and the epic-loot toast (top three) or the quest-complete chime (top ten) instead of the finish fanfare. Record whether it reads as big enough and not too much, whether the medal clears the window's header, and whether `Game42Font` (the banner) and the sounds exist on Forever.
2. **The flow.** The middle row reads **Restart · Highscores · Close results**; after a celebration Highscores is lit. Click it: the run's own board opens at the page with your row, your row in gold. **Close results**, then reopen the results from the track view: the celebration shows still, with no sound or confetti.
3. **A plain finish.** A best off the top ten, or with shared scores off, keeps the plain window with its notice in gold; no best keeps it grey; the fanfare plays once.
4. **A two-player race** (with Codex's live flow): the place ("1st"/"2nd", "of 2") at bottom right changes as you pass; the friend's name rides over their kart, or waits at the canvas edge toward it with the distance, and fades when the signal goes stale. At the finish both racers are listed in their places with their karts and times or state; **FINISHED!** waits for the friend, then turns into **1st PLACE!** (the gold medal, the toast) or **2nd PLACE** with the gap. UI's "No agreed winner or standings" hint and the note about reported times stay.
5. **Print Probe** (developer info): 90 frames, 91 textures and 150 font strings.

## Deferred Scarlet v3 check (proposed, `claude/scarlet-v3`)

**NOT RUN.** Run it after Codex's review and a coordinated install. **Fully restart the client:** the Library's and the Cathedral's pictures keep their paths but changed. The owner runs these checks; Claude does not control the client.

1. **Scarlet Library, the courtyard.** Drive into the courtyard from each side of the arcade and round the fountain both ways, near and wide: the kart fits everywhere between the fountain and the trees (the place in his screenshot, south-east of the fountain, included). The HUD shows "Road" on the lawn: nothing slows. Record whether the corners' trees, the bush and the hounds look right, and whether the courtyard now feels too empty.
2. **Scarlet Graveyard.** The cloister's lawn shows "Road" and does not slow; the graves still block. The board keeps its version-2 times.
3. **Scarlet Cathedral, the stairs.** Up either long flight beside the falls to its landing: driving on north, the parapet stops the kart where it is drawn; turn outward (west on the west stairs, east on the east) down the short flight onto the lawn, then up past the round pool to the terrace. Record whether the two turns feel like a fair bit more difficulty, or too tight.
4. **Scarlet Cathedral, the upper garden.** The round pool is smaller and farther north: the kart stops where its rim is drawn and slides round it. The trees behind the parapets block where their crowns are drawn.
5. **Scores.** The Library and the Cathedral show fresh boards (version 3); older times stay saved under their versions.

## Deferred kart stat bars check (proposed, `claude/kart-stat-bars`)

**NOT RUN.** Run it after Codex's review and a coordinated install. **Fully restart the client:** `Assets/UI/StatBars.tga` is a new file. The owner runs these checks; Claude does not control the client.

1. **Single Player, then the kart choice** (and the Garage from the main menu): under the kart's credit, "Handling: Balanced" (or Heavy, or Agile) in gold, then four gold-framed bars labelled Speed, Acceleration, Turning and Braking, nothing reading "Lua error".
2. **The fills:** the Goblin Mortar Trike four windows of six on every bar; the Steam Tank 5, 2, 2 and 6; the Dwarven Biker 3, 6, 6 and 2. Each window is green or dark, with no seam where a bar's green ends.
3. **The look:** whether the bars read as part of the window (gold trim, green like a health bar), and whether the kart buttons below them still sit clear of the Race!/Done button.
4. **Print Probe** (developer info): 89 frames, 77 textures and 140 font strings.

## Deferred Scarlet fixes check (proposed, `claude/scarlet-fixes`)

**NOT RUN.** Run it after Codex's review and a coordinated install. **Fully restart the client:** the three pictures keep their paths but changed, and the client may keep the old ones until a restart. The owner runs these checks; Claude does not control the client.

1. **Scarlet Library.** The HUD counts four gates (n/4): *Huntsman's Cloister*, *Gallery of Treasures*, *Athenaeum*, *Arcanist Doan*. Nobody stands on the courtyard's cross path. Loksey's kennel is still there off the south walk, and driving into it counts nothing. Record whether the courtyard's lawns slowing (their paths kerbed) feels fair.
2. **Scarlet Armory, the Training Grounds.** Record whether the yard reads like his screenshot: pale octagonal flags in the grass, wooden dummies with arms and padded ones, targets before plank backstops with hay, flowers and bushes in two corners. The HUD shows "Road" anywhere in the yard: nothing slows. A kart stops at a dummy or a target where it is drawn, never short of it on open flags.
3. **Scarlet Cathedral, the way up.** From the lower garden only the stairs beside the falls lead up: the plinths either side, with the statues, stop the kart at their faces. The lawns show "Road" and do not slow.
4. **Scarlet Cathedral, invisible walls.** Drive at the trees and bushes in both gardens and at the nave's pillars from every side: the kart stops where the crown or the pillar is drawn, never on open grass or floor short of it, and never runs over leaves. Record any place the kart still stops at nothing it can see, with a screenshot.
5. **Scores.** Each of the three courses shows a fresh board (version 2); version 1's times stay saved under the old version.

## Deferred Scarlet Cathedral check (proposed, `claude/scarlet-cathedral`)

**NOT RUN.** Run it after Codex's review (round solids in ADR 0020's addendum, and the score-sync change with the Cathedral's code `C`) and a coordinated install. **Fully restart the client:** `Assets/Tracks/ScarletCathedral/` is new. The owner runs these checks; Claude does not control the client.

1. **Track screen.** The *Scarlet Crusade Cup* lists Scarlet Graveyard, Scarlet Library, Scarlet Armory and Scarlet Cathedral, and nothing is marked "(soon)". Choose the Cathedral: its tall preview and three facts appear. The bar's Track button steps from the Armory to the Cathedral, then Test Oval.
2. **Load.** The 1024×2048 TGA. Record any refusal and any hitch when switching to it.
3. **The drive.** The kart starts at the portal facing west between two guards. The HUD reads "Sprint" with the gates passed (n/4). Find the way:
   - west along the entrance hall, north through the garden gate (the first gate);
   - round the lower pool, then up the stairs beside the falls or across a platform (the second gate spans them all);
   - round the round pool to the terrace and the cathedral's door (the third gate);
   - up the nave, across the transept and up the chancel's steps to the chequered line before the altar, the finish.
4. **The pools.** Record whether the karts stop where the water's rim is drawn, and whether sliding round the round pool feels smooth, not sticky.
5. **Solids and walls.** Record whether the pillars, trees, bushes, statues, the Crusade, Mograine, Whitemane, the altar and the candles block where they are drawn, and whether anything else stands where the kart drives.
6. **The gardens and the chancel.** Record whether the gardens read as the open sky, the falls and stairs as the way up, and the finish as before the altar. Fairbanks' chamber behind it should be drivable after the finish.
7. **Results and scores.** "RUN COMPLETE" with "Sprint | Total: …" and "All 4 gates". Highscores shows the Cathedral's own board as sprints. Community sharing needs Codex's score-sync change.
8. **Camera and performance.** Record the frame rate while driving. Print Probe still shows 90 frames, 167 textures and 136 font strings.
9. **Scarlet Armory's Herod** now has a model of his own (a hulking champion in crimson with a great blade). Record whether he reads as Herod.

## Deferred Scarlet Armory check (proposed, `claude/scarlet-armory`)

**NOT RUN.** Run it after Codex's review (the score-sync change with the Armory's code `A`) and a coordinated install. **Fully restart the client:** `Assets/Tracks/ScarletArmory/` is new. The owner runs these checks; Claude does not control the client.

1. **Track screen.** The *Scarlet Crusade Cup* lists Scarlet Graveyard, Scarlet Library and Scarlet Armory, then the Monastery marked "(soon)". Choose the Armory: its square preview and three facts appear. The bar's Track button steps from the Library to the Armory, then Test Oval.
2. **Load.** The 2048×2048 TGA. Record any refusal and any hitch when switching to it.
3. **The drive.** The kart starts at the portal facing east between two guards. The HUD reads "Sprint" with the gates passed (n/5). Find the way:
   - east along the entrance hall, north through the door into the Training Grounds (the first gate);
   - round the walks or across the yard, then up the stairs from the north walk (the second gate) into the Footman's Armory;
   - round its pillars to its east side room, up the stairs (the third gate) and west through the Crusader's Armory;
   - out of its north-west corner, north, then east along the long hall to the Hall of Champions' door (the fourth gate);
   - down the round hall's stairs to the chequered line across its middle, either side of Herod: the finish.
4. **The Training Grounds.** The yard slows the kart; the walks are stone. Record whether the stepping stones read as paint on grass or invite the karts to expect stone, and whether the yard reads as the only open sky.
5. **Solids and walls.** Record whether the columns, targets, dummies, hay, footmen, forge, anvil, table, cart, junk, candles and Herod block where they are drawn, and whether anything else stands where the kart drives.
6. **The Hall of Champions.** Record whether the ring of stairs and Herod read clearly in the follow camera, whether the north wall and statues show whole at the top of the world, and whether the round wall slides the kart round smoothly.
7. **Results and scores.** "RUN COMPLETE" with "Sprint | Total: …" and "All 5 gates". Highscores shows the Armory's own board as sprints. Community sharing needs Codex's score-sync change.
8. **Camera and performance.** Record the frame rate while driving. Print Probe still shows 90 frames, 167 textures and 136 font strings.

## Deferred drive-fixes check (proposed, `claude/drive-fixes`)

**NOT RUN.** Run it after Codex's review and a coordinated install. The owner runs these checks; Claude does not control the client. No new files: a `/reload` is enough unless the install also brings the Library, whose folder is new (then fully restart).

1. **Scarlet Graveyard, the chamber's west side** (his images 1 and 2). A wall stands either side of the Chamber of Atonement's west door, and the kart stops at it where it is drawn. The way west is through the door, into the west hall.
2. **Nothing under the kart** (his images 3 and 4). The armour rack stands in the corner at the head of the stairs, off the steps, and there is no ghost on the cloister's path. The ghosts on the lawns, the sitting corpse and the stone benches block. Record anything else the kart drives over.
3. **Thunder Bluff's start** (his image 5). At GO the kart stands at the foot of the Lower Rise's west side facing up it, the finish line ahead and the start sign on the right. Straight on is the way. Record the lap count after the first full loop: crossing the finish line just after GO counts nothing, as before.
4. **Each lap's end at Thunder Bluff.** Coming west along the south side, the way on is right at the junction, up the west side; the road from the lift goes on west to the lift.
5. **Scores.** Both courses are version 2: their Highscores boards start empty, and version 1 times stay saved under version 1.
6. **The Library** (when installed): the courtyard's bushes, the kennel's cages, rib cage and hay, and the candles round Doan block; nothing else stands on the floor.

## Deferred Scarlet Library check (proposed, `claude/scarlet-library`)

**NOT RUN.** Run it after Codex's review (round rooms in ADR 0020's addendum, and the score-sync change with the Library's code) and a coordinated install. **Fully restart the client:** `Assets/Tracks/ScarletLibrary/` is new. The owner runs these checks; Claude does not control the client.

1. **Track screen.** The *Scarlet Crusade Cup* lists Scarlet Graveyard and Scarlet Library, then the Armory and the Monastery marked "(soon)". Choose the Library: its square preview and three facts appear. The bar's Track button steps from the Graveyard to the Library, then Test Oval.
2. **Load.** The 2048×2048 TGA. Record any refusal and any hitch when switching to it.
3. **The drive.** The kart starts at the portal facing north between two guards. The HUD reads "Sprint" with the gates passed (n/5). Find the way:
   - north, east, then south down the long hall (the first gate is just past the turn);
   - round the cloister's walks, or across the open courtyard;
   - into Loksey's kennel across his line (the second gate), turn round, and back out;
   - north up the east hall into the Gallery of Treasures (the third gate in its door);
   - east through the two columned halls (the fourth gate in the Athenaeum's door) and south down the Athenaeum;
   - through the last hall to the chequered line in the round library's door, the finish.
4. **The kennel's hairpin.** Record whether the turn round in the kennel is fair at speed. The houndmaster, his hounds, the cages, the rib cage and the hay block; the straw piles and the skull pile by the walls stand off the floor.
5. **Walls, columns and the round wall.** Record:
   - whether the arcade's columns and the courtyard's trees block where they are drawn;
   - whether the pillars in the halls leave enough room;
   - whether the round library's wall slides the kart round smoothly.
6. **The courtyard.** The lawn slows the kart; the paths and the fountain's court are stone. Record whether the courtyard reads as the only open sky.
7. **Results and scores.** "RUN COMPLETE" with "Sprint | Total: …" and "All 5 gates". Highscores shows the Library's own board as sprints. Community sharing needs Codex's score-sync change.
8. **Camera and performance.** Record the frame rate while driving, and whether the long halls and the round library read clearly in the follow camera. Print Probe still shows 90 frames, 167 textures and 136 font strings.

## Deferred Scarlet Graveyard check (proposed, `claude/scarlet-graveyard`)

**NOT RUN.** Run it only after Codex's review and a coordinated install. Codex's review includes the sprint rules (ADR 0020) and the score-sync change in Claude's handoff.

**Fully restart the client:** `Dungeon.lua`, `ScarletCrusade.lua` and `Assets/Tracks/ScarletGraveyard/` are new. The owner runs these checks; Claude does not control the client.

1. **Track screen.**
   - A third cup, *Scarlet Crusade Cup*, lists Scarlet Graveyard, then Scarlet Library, Scarlet Armory and Scarlet Monastery marked "(soon)".
   - Choose the Graveyard: its 2:1 preview and three facts appear.
   - The bar's Track button steps from Undercity to Scarlet Graveyard, then Test Oval.
2. **Load.** The 2048×1024 TGA, the first that is not square. Record any refusal ("... background unavailable | Test Oval remains available") and any hitch when switching to it.
3. **The drive.** The kart starts in the entrance hall facing west, by the blue portal swirl between two Scarlet guards. Find the way, as the owner intended:
   - north up the long hall;
   - through the east door of the Chamber of Atonement, the first gate, past the torture table;
   - out of its west door and down the stairs, the second gate;
   - across the Forlorn Cloister's graveyard, to the chequered line in Honor's Tomb's door, the finish.

   The HUD reads "Sprint" with the run time and the gates passed (n/3). The race ends at the third gate.
4. **Walls and graves.**
   - Walls slide the kart along them.
   - Doorways are wide enough at speed.
   - Graves, crypts, trees, the fountain and the torture table block the kart.
   - Record anything that blocks where nothing is drawn, or lets the kart through something drawn.
5. **The lawn.** The cloister's grass slows the kart, as Mirage's rough ground does; the stone path is the fast way. Record whether that feels right.
6. **Results and scores.**
   - Results read "RUN COMPLETE" with "Sprint | Total: …" and "All 3 gates", and list one "Run" time instead of lap times.
   - Highscores keeps the Graveyard's board apart from the lapped courses, under "Fastest completed sprints, one run each".
   - Community sharing needs Codex's score-sync change. Without it, record what the Highscores screen says.
7. **The look.** Record whether:
   - the halls read as a monastery at night;
   - the cloister reads as an open graveyard under the moon;
   - the north walls' faces, carpets, torches and braziers read clearly in the follow camera.
8. **Camera and performance.**
   - The camera stops at the picture's edges: it is 1024 units tall, not 2048.
   - Record the frame rate while driving. Print Probe shows 90 frames, 167 textures and 136 font strings.

## Deferred Thunder Bluff Skyway check (proposed, `claude/thunder-bluff`)

**NOT RUN.** After Codex's review (including the score-sync change in Claude's handoff) and a coordinated install, **fully restart the client**: `Assets/Tracks/ThunderBluff/` is new. The owner runs these; Claude does not control the client.

1. **Track screen.** *Capital Cities Cup* lists all six cities, Thunder Bluff Skyway between Orgrimmar Canyon Rush and Undercity Slime Circuit, with no "(soon)" entry left. Choose it: its preview and three facts appear. The bar's Track button steps Stormwind, Ironforge, Darnassus, Orgrimmar, Thunder Bluff, Undercity, then Test Oval.
2. **Load.** The sixth 2048×2048 TGA. Record a refusal ("... background unavailable | Test Oval remains available") and any hitch when switching to it.
3. **The drive.** The kart starts on the road in from the lift facing east-north-east. A start sign ahead points north-west: bear left, up the west side, over the finish line. Then clockwise:
   - over the west bridge and round the Spirit Rise, back over the north bridge;
   - east along the north side, along the long bridge and round the Elder Rise, past Cairne's lodge, back over the lower bridge;
   - down the east side past the wind riders' roost, over the east bridge, across the Hunter Rise, back over the south-west bridge.
   The HUD names each next gate (six).
4. **The bridges.** Each deck is narrower than the street: the rope rails stop the kart as the other walls do, and the step where a deck begins catches only a kart well off the line. Record whether that step feels fair, and whether the bridges are too narrow at speed.
5. **The look.** Record whether:
   - the drop reads as a long way down (the cliff faces, the hazy plain, the trees and river far below);
   - the white stone streets and the posts-and-rope edges read as the owner's screenshots;
   - the drop between the planks and the rope under each bridge are visible at speed.
6. **Scores.** A finished race saves to Thunder Bluff's own board. Community sharing needs Codex's score-sync change; without it, record what the Highscores screen says.
7. **Camera and performance.** Frame rate while driving. The city art adds no frames.

## Deferred Goblin Pod Racer, start signs and kart outline check (proposed, `claude/podracer-arrows-outline`)

**NOT RUN.** After a coordinated install, **fully restart the client**: `Assets/Karts/GoblinPodRacer.tga` and the ten `Assets/Karts/Outlines/` sheets are new files, and four city pictures are replaced. The owner runs these; Claude does not control the client.

1. **Pod racer.** Garage: the last kart reads **Goblin Pod Racer**, credited to Blizzard Entertainment (World of Warcraft), and spins on the turntable. Drive a lap:
   - the pods lead at every heading, with no mirroring or neighbouring-frame sliver;
   - drift dust starts at the cart's wheels and boost flames at the pods' tails.
   A saved choice of the old drag car comes back as the pod racer.
2. **Start signs.** On Stormwind, Ironforge, Orgrimmar and Darnassus, leave the grid. Where the start road meets the loop, a wooden goblin racing sign beyond the far wall shows a bright red arrow pointing the race's way:
   - north-east in Stormwind and Orgrimmar;
   - north-west in Ironforge and Darnassus.
   Record whether the arrow reads at a glance and whether it is in view in time to choose the turn.
3. **Outline.** Settings: **Outline my kart** starts unchecked. Check it and race:
   - a bright yellow line hugs your kart at every heading, over its shadow and never over the kart;
   - there is no box or sliver, and no hitch;
   - changing karts, the line follows each one's shape.
   `/reload` keeps the setting. Unchecking hides the line. Print Probe: 80 frames, 167 textures, 83 font strings (more with any newer integrated front-end work).

## Deferred Stormwind City Circuit check (proposed, `claude/capital-cup`)

**NOT RUN.** After a coordinated install, **fully restart the client** (`Circuit.lua`, `CapitalCities.lua`, `Courses.lua` and the `Assets/Tracks/Stormwind/` pictures are new files). The owner runs these; Claude does not control the client.

1. **Single Player → Choose a Track.** The list shows *Proving Grounds* (Mirage Raceway, Test Oval) and *Capital Cities Cup* (Stormwind City Circuit, Ironforge Grand Prix, then four disabled cities marked "(soon)"). Choose Stormwind: its preview (the city from above) and three facts appear. Record any overlap, clipping or missing preview ("Preview unavailable").
2. **Load.** Selecting Stormwind loads a 2048×2048 TGA, the first texture this large in the addon. If the status reads "Stormwind City Circuit background unavailable | Test Oval remains available", record it: the client refused the size (a smaller or compressed picture is the fallback plan).
3. **Race!** The kart starts on the Valley of Heroes approach between the statues, facing the city gate. Drive the lap: Trade District (finish line), over the canal to Old Town, the Dwarven District, Cathedral Square, the Park, the Mage Quarter, back to the Trade District. The HUD names each next gate. Record whether each district is recognisable, and anything drawn wrongly (roofs over the street, kart under scenery, seams, misaligned walls).
4. **Walls.** Drive into the balustrade at an angle and head-on: the kart stops at it (not visibly inside it), slides along it, and loses speed; the kerbside strip before it keeps full road speed, drift and boost; only actual wall contact scrubs speed. In Cathedral Square, steer into the foot of the Cathedral's steps: the street ends there at the same line as elsewhere, though no wall is drawn (does that read right?).
5. **Camera and performance.** The follow camera stays on the kart up to the map's edges; record frame rate and any hitch when the track is selected and while driving, and Print Probe's counts (source expects 71 frames/164 textures/80 font strings).
6. **Switching.** The bar's Track button cycles Test Oval → Mirage Raceway → Stormwind City; switching back and forth keeps working, and the saved track returns after `/reload`.

## Deferred Ironforge Grand Prix check (proposed, `claude/capital-cup`)

**NOT RUN.** After the coordinated install and a full client restart (the `Assets/Tracks/Ironforge/` pictures are new files):

1. **Track screen.** *Capital Cities Cup* lists Stormwind City Circuit and Ironforge Grand Prix, then four cities "(soon)". Choose Ironforge: its preview and three facts appear.
2. **Load.** A second 2048×2048 TGA. The safe staging loader may retain two scenery images (up to32MiB raw city pixels, excluding previews/native overhead). Record a refusal ("Ironforge Grand Prix background unavailable | Test Oval remains available") and any hitch when switching between the two cities.
3. **Race!** The kart starts in the gate hall facing the Commons, the Gates behind. Drive the lap: the Commons (finish), Mystic Ward, Forlorn Cavern, Hall of Explorers, into the Great Forge and round its southern forge, Tinker Town, Military Ward, back to the Commons; the HUD names each next gate (seven). Record whether each district is recognisable and whether the long lap feels right.
4. **Walls.** The rock faces, the halls' foundations and the dark railings along the lava stop the kart as Stormwind's walls do.
5. **Camera and performance.** Frame rate while driving past the lava and through the darker halls; Print Probe still 71/165/80 (75/165/80 with the ten karts).

**Version3 (reviewed on `codex/ironforge-narrows`, after the owner's version2 drive quoted in Claude's handoff): NOT RUN.**

6. **Forlorn Cavern tunnels.** In from the Mystic Ward and out by the north-east stair the street narrows through the rock: no shoulder, the wall at the paving's edge. Driving along a tunnel wall the kart's body meets the drawn rock edge, with no "Off-road" message; the street flares back to its usual width after each tunnel. Record whether the transition reads clearly and the tunnel feels usable in a solo drive. Actual multi-kart spacing awaits live-race integration; no two-kart test is available in this build.
7. **Lava and the Great Forge.** Every lava pool has a dark wall all round, no ridges across it and no grey band at its edge; the glow remains. Between the two forges stand only the Great Anvil (red and gold) and the pumps; record whether the anvil reads as an anvil.

## Deferred Orgrimmar Canyon Rush check (proposed, `claude/orgrimmar`)

**NOT RUN.** After Codex's review and coordinated install, fully restart the client (the `Assets/Tracks/Orgrimmar/` pictures are new files). The owner runs these.

1. **Track screen.** *Capital Cities Cup* lists Stormwind City Circuit, Ironforge Grand Prix and Orgrimmar Canyon Rush, then three cities "(soon)". Choose Orgrimmar: its preview and three facts appear.
2. **Load.** A third 2048×2048 TGA (the staging loader still holds at most two). Record a refusal ("Orgrimmar Canyon Rush background unavailable | Test Oval remains available") and any hitch when switching between the cities.
3. **Race!** The kart starts on the canyon road facing east, the city gate behind it. It joins the loop in the Valley of Strength (finish line just round the corner), then counter-clockwise: the Drag, under the north wall past Grommash Hold, down the Cleft of Shadow's rim, back to the Valley of Strength; the HUD names each next gate (four). Record whether the districts read as Orgrimmar and whether the lap length feels right.
4. **Walls.** The palisade and the canyon's cliffs stop the kart as Stormwind's walls do; the gravel strip before them keeps full road speed, drift and boost (no "Off-road" message), as in Stormwind.
5. **Camera and performance.** Frame rate while driving; Print Probe 75/165/80 with the ten karts (71/165/80 without them): Orgrimmar adds no frames.

## Deferred Darnassus and Undercity check (proposed, `claude/darnassus-undercity`)

**NOT RUN.** After Codex's review and coordinated install, fully restart the client (the `Assets/Tracks/Darnassus/` and `Assets/Tracks/Undercity/` pictures are new files). The owner runs these.

1. **Track screen.** *Capital Cities Cup* lists Stormwind City Circuit, Ironforge Grand Prix, Darnassus Canopy Run, Orgrimmar Canyon Rush and Undercity Slime Circuit, then Thunder Bluff Skyway "(soon)". Choose each new city: its preview and three facts appear. The bar's Track button steps Stormwind, Ironforge, Darnassus, Orgrimmar, Undercity, then Test Oval.
2. **Load.** The fourth and fifth 2048×2048 TGAs (the staging loader still holds at most two). Record a refusal ("... background unavailable | Test Oval remains available") and any hitch when switching between the cities.
3. **Darnassus.** The kart starts on the road in from the Warrior's Terrace facing west; at the central terrace the course turns north (the finish line is there), then counter-clockwise: past the Craftsmen's Terrace, along the top, down past the Cenarion Enclave, the causeway by the lake, round the Temple of the Moon, up past the Tradesmen's Terrace. The HUD names each next gate (six). Record whether the terraces read as higher and lower ground (stone walls along the tiers, the gardens darker below them) and whether the ramps read as ramps.
4. **Undercity (version 1; version 2 below replaces it).** The kart starts on the loop below the Apothecarium facing east, just past the finish line, the green canal on its left. Counter-clockwise round the Rogues', Magic and War Quarters, the hairpin, down the ramp into the Trade Quarter, clockwise round its slime well, up the ramp and round the southern canal's end to the line; five gates. Record whether the Trade Quarter reads as sunk below the rings, whether the green slime is too bright, and whether the lap (the longest city, 7,327 units) feels too long.
5. **Walls.** The railings, parapets and terrace walls stop the kart as Stormwind's walls do; the strip before them keeps full road speed, drift and boost. The ramps drive flat (no slope physics yet): note whether that feels wrong.
6. **Camera and performance.** Frame rate while driving each city; city art adds no frames. Print Probe was 79/166/81 before the separate Highscores screen; on `codex/solo-highscores` it is 85/166/133. Native cost of the added pooled score UI remains unmeasured. See [Highscores checks](../docs/HIGHSCORES.md#verification-and-deferred-native-check).

## Deferred Undercity version 2 and wall-to-wall paving check (proposed, `claude/undercity-river`)

**NOT RUN.** After Codex's review and coordinated install, fully restart the client (all five city pictures change). The owner runs these.

1. **Undercity.** The kart starts on the outer walkway below the Apothecarium facing east, just past the finish line (*The Canals*), the slime on its left. Counter-clockwise round the canal ring it changes walkway on a bridge at every section: six bridges, timber and stone by turns, each a sharp turn on, a straight across the slime and a sharp turn off. The HUD names each next gate: Rogues' Quarter, Magic Quarter, Ruins of Lordaeron, War Quarter, Apothecarium, The Canals. Record whether the turns are too sharp or too gentle at speed and when drifting, whether a kart catches on a bridge's corner walls, whether the timber and stone bridges read as bridges over the slime (the stone ones humped), whether the grimmer light is too dark anywhere on the course, and whether the 5,797-unit lap feels right.
2. **No shoulders.** On every city the street is paved from wall to wall, with a kerb at the walls' foot and no pavement, gravel or moss strips beside the road. Along the walls the kart keeps full speed, drift and boost on every city.
3. **Ironforge version 4.** Its edge strip, which used to slow the kart and show "Off-road", is road now; the Forlorn Cavern's tunnels and every wall are unchanged. Record whether that changes the lap's feel.
4. **Camera and performance.** Frame rate while driving each city; Print Probe unchanged: the pictures stay five 2048×2048 TGAs.

## Deferred front-end check (proposed, `claude/ui-flow`)

**NOT RUN.** Follow [the front-end client check](../docs/art/ui/front-end.md#client-check-not-run) after a coordinated install and a full client restart (`Menu.lua` and `Assets/UI/TrackPreviews.tga` are new files). With the front end, the window opens on the main menu; the first run starts from **Single Player → Race!**, and the bar's Start reads **Start Race**. Print Probe shows only with Settings → **Show developer info**; `/akart probe` always works. The checks below that start a drive use **Start Race** or **Race!**, and explicit counts become 71 frames/164 textures/80 font strings with the Capital Cities Cup (65/160/79 before it).

## Deferred short Test Oval obstacle check (Physics v7)

**NOT RUN.** Coordinate installation with Claude's current art first; this branch is based on the shared sprite review, not the latest scenery deployment. Do not overwrite that deployment from this checkout without reviewed integration.

1. After a coordinated verified update/reload, open `/akart` out of combat. On Test Oval, confirm two red 32×24 barriers near the upper-left and lower-right road edges. Start, wait for GO, approach one deliberately and confirm a head-on hit slows the kart and clears drift/boost. At an angle the kart should slide along its edge; steer away to recover. Clearance uses a conservative 18-unit square margin, not the exact chassis outline.
2. Stop, select Mirage Raceway, and confirm neither barrier appears. Drive only if a human is available; no obstacle should affect the map. Stop and switch back to Oval: both same markers return. Do not move the WoW character to perform this test.
3. Print Probe once while stopped. Source expects 71 frames/164 textures/80 font strings with the front end and the Capital Cities Cup (65/160/79 before the cup; 11/151/13 without the front end; 113 textures before the 38 pooled drift/boost effect textures), with stable counts through switches/reopen. Record actual build, appearance/handling issues and the observations executed; leave other cases pending. No repeat combat or long profiling matrix is required for this slice.

**Live checks PARTIAL, 2026-10-18.** Identity, basic rendering/Start and several idle release paths were observed in the installed client; the owner also confirmed real combat closes the window, displays the interruption note and leaves WoW controls working. See [the actual-client evidence](../docs/evidence/2026-10-18-m0-client.md). Sustained driving, held-key release and remaining rows are pending unless separately reported; simultaneous W/Up is SKIPPED at the owner's request. Do not turn an idle UI smoke or test-double result into a full acceptance pass.

**2026-10-19 continuation:** two human near-minute drives are recorded below. An unplanned combat/death sequence left the stopped window visible. That inactive-event source gap is fixed/tested offline, installed and loaded; actual combat verification remains deferred. Further drives were put on hold at that point; the owner's subsequent direction is recorded below. [Driving evidence](../docs/evidence/2026-10-19-m0-client.md).

**Owner steering afterward:** continue development elsewhere; no further combat test is requested now. On 2026-10-19 the owner requested about 80% less testing and build-first work ([ADR 0007](../docs/adr/0007-build-first-development.md)). Unrun rows stay pending while local M1 mechanics progress; long manual/scale/profile matrices and the geometry review below are deferred.

**2026-10-19 profiler continuation, 07:32 CEST:** desktop app/window inventory returned no WoW client. The optional bounded profiler is installed on disk with all ten addon files matching tested source. Live profiler type/readback/cost, new-renderer load and appearance remain **NOT RUN**. The separate `/akart perf` protocol below is prepared; no new human drive or combat check is requested during this development slice.

**Stationary continuation, ~08:37–08:58 CEST:** the owner authorized unattended checks while unavailable. WoW was accessible. One stationary diagnostic supplied 600 valid scoped samples; counters/timings stayed frozen after stop, close/reopen and disarm. The analytical road loaded with horizontal seams. Two creation-time snapping experiments hid the road after reload and were removed; the prior renderer was restored and observed after another reload. [Historical results and review blocker](../docs/evidence/2026-10-19-m0-stationary-profile.md). This does not replace a human drive, fresh unprofiled Start, scale matrix or full M0 acceptance.

**Latest rendering continuation, 09:08–09:20 and 13:54–14:02 CEST:** isolated grass hide/show and settings checks identified occlusion under mixed snapping states. The permanent fix sets explicit grass priority and configures only the 96 bands during creation. A clean normal reload showed the complete renderer without seams at effective scale 0.72452831268311; readbacks verified all 96 band settings and grass `BACKGROUND,-1` with unchanged grass snapping. Reopen stayed inactive with counts 6/99/3; final state stopped, hidden, profiling off. [Exact evidence, including the quota interruption](../docs/evidence/2026-10-19-m0-road-layer.md). Supported-scale/stress and full M0 acceptance remain open.

Observed date/time: 2026-10-18 ~17:10–17:16 CEST (Europe/Oslo); tester: Codex computer-use, manual gameplay pending.
Build/interface: 1.60.1 / 70450 / 16001; runtime project ID: 18; selected TOC: Camelot; addon version: 0.0.1.
Captured resolution: 1920×1080; uiScale: 1.000000 / useUiScale: 0; Windows; hardware not recorded.
Other addons remained enabled/unchanged; baseline whole-client FPS sample: 207.6124420166. Evidence: linked above; no public screenshots.

## Optional M1 drift smoke — NOT RUN

Use at a later handling checkpoint, when a person can drive; this is not a prerequisite to the next local build slice.

1. Outside combat, open `/akart` and click Start. Wait for 3–2–1/GO, then accelerate to 90+ with W or Up, then hold Space with one turn direction. Observe bounded slide, blue charge and the named drift HUD.
2. Keep the turn for about 0.5 seconds to reach gold/tier 1; continuing about 1.0 second total reaches pink/tier 2. Release Space to spend the charge: observe cyan/BOOST, then return to normal. Judge responsiveness rather than timing these short intervals by eye as proof of exact ticks.
3. Keep Space held and briefly release steering or change direction. Charge should pause with `CHARGE HELD`, then resume when steering settles; a pause longer than 0.2 seconds clears it. Releasing Space during the brief pause can still boost an earned tier. Braking or leaving the road clears charge without reward. Avoid intentionally triggering combat. Escape must stop capture; the HUD retains `Last drive`, and a deliberate new Start clears it.
4. Record subjective handling, any Lua/layout error and stopped probe. Current source expects 71 frames/164 textures/80 font strings with the front end and the Capital Cities Cup (65/160/79 before the cup; 11/151/13 without the front end; 113 textures before the drift/boost effects); prior live 6/99/3 evidence belongs to the earlier source. Do not repeat the skipped simultaneous W/Up test.

Optional surface check at that same later checkpoint (**NOT RUN**): leave the road into island/exterior grass, observe slowdown and Grass feedback with cancelled drift/boost, then return to road. Approach a gray perimeter wall at an angle: the kart stays visible and slides along it with a speed scrub. Stop retains the surface under `Last drive`; Start resets it. Do not expand this into another long scale/combat matrix.

Optional interpolation check at that checkpoint (**NOT RUN**): drive and turn at a callback cadence above 60 Hz when available, observing motion between simulation steps and continuous heading across a full turn. Press Escape, note the final kart pose, then close/reopen; it must stay still until a deliberate Start resets it. Exact final-pose snapping can move the kart by up to the last fixed step; active interpolation adds at most one fixed step of visual delay. Record perceived smoothness and any visible jump or Lua error; no new scale/profile matrix is requested.

Optional meter check at that checkpoint (**NOT RUN**): during the same drift attempt, observe half-fill at Tier 1 and full fill at Tier 2 with a named ready caption. Release Space and observe the cyan remaining-boost meter drain on its 0.4s/0.8s scale; a Tier 1 boost starts shorter than Tier 2 on the shared scale. Cancelling or entering grass clears it. Escape freezes the meter with `Last drive`; close/reopen retains it, and a deliberate Start empties it. Record readability/layout issues in the current 856×762 window; exact tick thresholds remain an offline check.

Optional steering check at that checkpoint (**NOT RUN**): tap and hold a turn, release it, then reverse direction during the same drive. Judge whether buildup and faster centering feel controllable at road speed; reversal centers before turning the other way. With Space held, charge pauses through brief corrections and expires after the 12-tick grace; grass still cancels it and permits recovery. Exact 8/4/12-tick full-turn/release/reversal timings are offline checks, not intervals to prove by eye. No additional capture, combat or scale matrix is requested.

Optional countdown/three-lap finish check during the same later drive (**NOT RUN**): hold throttle after Start and observe the kart remain at spawn through 3–2–1, then begin moving after GO. GO clears shortly afterward; lap/race time excludes countdown while probe ticks include it. A hitch can extend countdown wall time, so do not prove exact ticks by eye. In one short attempt, Escape during countdown must retain zero race elapsed time and reopening must not resume; Restart begins a fresh countdown. Then follow North, West, South and Start counterclockwise for three circuits. Each ordered circuit awards one lap; crossing Start before the other gates must not award another. Best must show -- before the first completed lap, then that lap time/number. A faster later completed lap replaces it; an incomplete lap does not. Exact equal-time/earliest-lap handling remains an offline check. At lap three, capture must release and RUN COMPLETE must show total/last-lap times and the best completed lap with the kart frozen. Check the taller 380×190 summary for clipping. Close/reopen must retain that summary; click Restart deliberately and confirm a fresh countdown with empty best and no automatic driving on reopen. In a separate short attempt, Escape must show RUN STOPPED with actual partial progress and any best from already completed laps. Reopen must retain it. Best is per run and does not survive a fresh run as a personal record. Do not arrange combat for this slice; retain the existing deferred combat checks. Timing uses simulation ticks, excludes dropped callback time and is not an independent wall-clock measurement. Record any readability/error without starting a long matrix.

## 1. Identity and startup

- [x] AddOns-list enabled state observed, addon version read from runtime metadata, no incompatible/out-of-date notice visible. Screenshot observed in this chat; personal capture not committed.
- [x] Runtime identity and required capabilities read through `/akart probe`, `/dump` and equivalent grouped local readbacks; outputs transcribed in evidence. Interface `16001`, project ID `18`, Camelot selection confirmed; `IsGameWindowFocused`/`IsWindowFocused` absent. Extra standalone command forms remain available for reproduction in [CLIENT_API.md](../docs/CLIENT_API.md).
- [x] Out of combat, `/akart` opened the primitive oval inactive; probe output observed. Start worked only after clicking its button.
- [ ] Exact slash-toggle close plus manual ordinary movement check. Close-button hide and stopped reopen/chat were observed; ordinary character movement remains manual/pending.

## 2. Controls and stop matrix

**Current owner policy, 2026-10-20:** incidental mouse clicks and unassigned keys must leave the run active. Unsupported keys are consumed during capture. Escape/Stop/Close are explicit terminal exits; Enter/`NUMPADENTER` is an intentional chat exit. The earlier all-click/unknown-key stop observations below are historical and do not verify this changed policy. The new flow is **NOT RUN** in the client until a scoped result is recorded.

For **each row**, start a fresh drive with a deliberate **Start Race** (or menu **Race!**) click outside combat. Hold W for movement, perform the action, then release all keys. For continue-driving rows, confirm the run remains active and ticks continue before deliberately stopping. For stop rows, record the actual stop reason from `/akart probe`, confirm ticks remain unchanged across two probe calls several seconds apart, test ordinary WoW movement keys and type into chat, and confirm no automatic resume. Do not type the probe during the active timing sample: entering chat is itself a stop test.

Perform character movement and combat setup manually through normal WoW controls; these steps do not authorize automation of the WoW character. Kart input controls only the addon's test drive.

| Check | Reproducible action | Required observation | Result/evidence |
|---|---|---|---|
| Basic movement | W then Up; S then Down; A/D then Left/Right | Acceleration, braking/reverse and both steering aliases work; visible rotation matches motion | First human near-minute drive OBSERVED 2026-10-19: displaced/rotated kart, 3492 ticks. Individual alias/braking/reverse checks remain PENDING |
| Overlapping aliases | Hardware-dependent simultaneous alias hold/release | Alias bookkeeping has offline regression coverage; this live combination is not an acceptance gate for this keyboard | SKIPPED at owner's request, 2026-10-18: keyboard cannot hold W+Up together. Not a pass/failure; do not request this combination again |
| Escape | Press Escape while moving | Capture stops; ordinary bindings/chat recover | IDLE OBSERVED again on combined 7fcdd89, 2026-10-20: stopped, normal Game Menu opened and a second Escape dismissed it. Held movement still PENDING |
| Stop | Click Stop while holding throttle | Button remains enabled during countdown/driving; its own callback stops and clears held input; ordinary controls recover | Historical IDLE OBSERVED: global mouse-down stopped before button OnClick. Corrected own callback OBSERVED stationary on 2026-10-20, reason Stopped/tick 2715; held-throttle flow NOT RUN |
| Close/toggle | Click Close; separately use `/akart` to close | Hidden window cannot retain capture; reopening is stopped | Close-button and slash-close/reopen OBSERVED inactive, including frozen sample 1 timing on Oct19. Held-input/ordinary movement variant PENDING |
| Close results | Stop a run, click Close results; separately close/reopen the addon | Only the panel hides; times/sample remain and the same panel stays dismissed | Stationary dismissal OBSERVED 2026-10-21 at tick 812/time 10.53s; actual close/reopen and finished/interrupted variants NOT RUN (covered offline) |
| Enter/chat | Press Enter during capture, then type a harmless chat draft and cancel it; separately check Numpad Enter when available | Driving stops; chat receives text normally; record whether first Enter opens chat | Historical IDLE OBSERVED: first Enter stopped/opened chat; local command typed/executed; no peer message. Explicit-key implementation and held throttle NOT RUN |
| Unassigned key | Press M, F, Tab or another unassigned key while driving | Run/held driving inputs continue; unsupported key is consumed and does not open its ordinary WoW binding during capture | Historical OBSERVED: M stopped capture and opened map under superseded policy. Current stationary M OBSERVED 2026-10-20: continued, no world map; held input/other keys still pending |
| Click outside | Click outside the race window while throttle is held | Incidental click leaves the run active; releasing throttle still clears throttle | NOT RUN under current policy |
| Incidental mouse click | Click the race canvas; separately click a non-text UI panel overlapping the race window | Run continues; no stopped summary or reset of held driving inputs | Historical canvas click stopped under superseded policy. Current left/right canvas clicks OBSERVED stationary 2026-10-20: continued; overlapping/held-input cases NOT RUN |
| Text/other UI focus | Click a normal chat/edit box; separately click a non-text bag/UI panel | Actual text focus stops capture and permits typing; a non-text click alone leaves driving active | NOT RUN under current policy |
| Application focus | Alt-Tab away for 5 seconds, release W outside the game, return | If an application-focus getter is available, stops without auto-resume. On build 70450 record actual held-key behavior; do not assume a stop or claim a fallback | Historical idle Alt-Tab stopped through the now-removed unknown/Alt-key route; both observed focus getters absent. Current held W/release-outside case NOT RUN |
| Hide/show UI | If the client hides the racing window during capture, show it again normally; do not require an unassigned key to propagate | No capture through a hidden window; stopped after show | Historical OBSERVED: Alt-Z hid/restored UI with racing stopped under the old key policy. Current hide/show route NOT RUN |
| World transition | Have a normal manually initiated loading transition occur during capture when practical (for example a consented portal/instance entry) | Stops on leaving world; no auto-resume after arrival | PENDING / unavailable |
| Reload | While driving, enter `/reload` normally, then log result after load | Clean reload, inactive controls and ordinary movement/chat | OBSERVED: normal Enter released capture; reload completed with window hidden; post-reload probe active=false/Not started, ticks=0, counts=6/99/3. Local chat command worked; no movement automation used |
| Logout/login | Log out normally after a drive, then log in | Clean load; inactive controls, ordinary movement/chat | PENDING |
| Combat before Start | Enter combat through ordinary manual game play, open `/akart`, attempt Start | Start rejected; no capture, restricted-action error or taint | PENDING |
| Combat during capture | Outside combat Start, then have combat begin through ordinary manual game play or a consenting duel partner; after combat deliberately reopen `/akart` without Start | Window closes; ticks stop; held input clears; `Game interrupted by combat` is retained on reopen; ordinary movement/chat work during and after combat; no taint or auto-resume | OWNER CONFIRMED: window closed, message appeared, WoW controls work. Exact stopped tick, reopen/retention, repeat/no-auto-resume and full taint audit still PENDING live |
| Combat after Stop | After loading the fix, open an inactive window; separately stop a short drive and record its probe. Have combat begin only through normal owner-controlled play when practical | Window hides on combat onset; completed sample/reason or prior interrupted result unchanged; no new interrupted-drive announcement or automatic resume. Explicit reopen may inspect the note/Start refusal | FAILURE OBSERVED Oct19: stopped window remained visible during attack/death. Source regression/fix PASS offline; installed and loaded, actual combat verification NOT RUN. Do not automate combat or character recovery |
| Repeated combat notification | During the same interruption, observe subsequent combat notifications if they occur; otherwise leave the live duplicate case pending and use the offline lifecycle check as separate evidence | One interruption note/result for that drive, no change to its stopped tick; no repeated close/reopen loop | PENDING / unavailable |

Exercise normal mouse-down followed by button release: Start must start, Stop must reach its own callback, and incidental clicks must leave driving active. `GLOBAL_MOUSE_DOWN` is no longer required to capture input. Track selection stays disabled while active; clicking it must neither stop the run nor discard progress. Record actual output and behavior. Chat commands can stop capture before reload/logout events; the loading-transition row tests a separate non-chat route. If a scenario cannot be arranged, leave it pending and explain why.

Any stuck input or combat taint is an M0 blocker. Record the exact failing action, event/status output and client error. End that driving test; do not bypass protected restrictions to produce a pass. Confirm that after combat the input propagation restoration does not restart the drive.

The confirmed [combat rule](../docs/adr/0006-combat-interrupted-results.md) ends a race with its actual current placements, finalized once and labeled interrupted. This M0 probe has no standings: accept closure and the retained interruption note only, and do not record a fabricated placement. Network propagation of another player's combat is outside this local test. Do not generate fake combat events or deliberately enter a duplicate result merely to fill a checklist row.

**Retained interruption note follow-up — NOT RUN for the 2026-10-19 source fix:**

1. After the ordinary manual combat-interruption check above, reopen `/akart` without Start. Record the visible interruption note, stopped tick and timing probe.
2. Close/reopen with `/akart` twice, then separately use Close and reopen. The interruption note and stopped probe values must remain, with no automatic resume or new unsolicited interruption message. Explicit probe reports may repeat the retained stop reason; those are requested diagnostics.
3. If combat is still ongoing, attempt Start normally: the refusal and retained interruption note must both be visible, with ticks unchanged. After combat ends, a successful deliberate Start must clear the old note and reset the drive. A later normal Stop/Close must show its own reason. Leave unavailable cases pending; do not automate combat or remove APIs to fill a row.

## 3. F1 timing and allocation sample

**2026-10-19 two drives observed:** 58.2120/62.6020 active seconds and 3492/3756 ticks; no dropped time, counts 6/99/3, matching stopped HUD and frozen delayed readbacks. First-sample close/reopen also retained numeric fields. See [the live evidence](../docs/evidence/2026-10-19-m0-client.md). Third sample remains PENDING at owner direction while independent M0 development continues. Independent duration/handling details, scaling/stress and full acceptance remain pending. The 2026-10-18 short probe remains historical smoke evidence only.

Perform each drive manually, outside combat, with an independent timer. Use the normal client FPS display if desired. Keep chat/probe output out of the active timing sample: chat deliberately stops capture, while clicking Print Probe no longer stops the run and would report a moving sample. This is a measurement aid, not an automatic driver or timed race mode.

1. While stopped, copy `/akart probe`, `/dump GetFramerate()` and normal UI-scale readbacks. Record the client build, resolution, scale and other relevant conditions. Close chat before starting.
2. Click **Start Race** (or the menu's **Race!**) and start the independent timer. The HUD must reset from the previous sample to tick 0 / `Sample: 0.0s` immediately on Start, then advance normally. Drive and steer for approximately 60 seconds; sequential W then Up is sufficient for the throttle aliases. Do not attempt the owner's skipped simultaneous W/Up combination.
3. Press Escape at the target duration and stop the independent timer. If Escape opens the normal game menu, dismiss it normally. The HUD must immediately reflect the final stopped tick, rather than retaining the last quarter-second update. Copy `/akart probe` while stopped and confirm its tick equals the HUD tick.
4. Wait several seconds, run `/akart probe` again, then close/reopen `/akart` without Start and repeat the probe. Ticks, timing/cadence values and allocation counts must remain unchanged while inactive; the status/stop reason can reflect closing. Reopen must not resume driving. Confirm ordinary WoW controls work manually.
5. Repeat steps 2–4 for three fresh drives. Only a deliberate Start resets the timing sample. Keep failed/interrupted or shorter runs as separate evidence rather than calling them 60-second passes.

- [ ] Three samples recorded with independent timer duration, `activeFrameSeconds`, `simulatedSeconds`, `callbackHz`, frames, ticks, maxElapsed, hitchFrames, droppedSeconds, accumulator, stop reason, explicit addon frame/texture/font-string counts and visible symptoms.
- [ ] For each sample, verify `activeFrameSeconds ≈ simulatedSeconds + droppedSeconds + accumulator` within 0.0002 seconds at the current printed precision; record actual values and investigate an unexplained discrepancy.
- [ ] Immediate stopped HUD/probe tick agreement, frozen values across delayed probe/close/reopen, and fresh Start reset verified.
- [ ] Counts stable across repeated drives/open/close cycles and no chat output each tick. These UI module counts exclude the bootstrap event frame and internal template allocations; do not claim whole-client allocation measurements.
- [ ] Repeat readable/usable layout checks at available normal client scales near 0.75/1/1.25. Record actual values if the normal UI range differs.
- [x] Basic analytical-band appearance after normal reload: full gray outer road, masked island, marker/kart at spawn, window controls and counts 6/99/3 observed without horizontal seams on 2026-10-19 at effective scale 0.72452831268311. Read-only getters verified all 96 band settings and explicit grass priority. This accepts the recorded appearance only; the separate supported-scale matrix remains pending.
- [ ] After safety passes, leave open/idle for 15 minutes, then drive for 10 minutes. Record before/after FPS, metrics/errors and visible hitches. Return from a long Alt-Tab without catch-up burst or automatic resume.

`activeFrameSeconds` sums valid elapsed values delivered to active `OnUpdate` callbacks; it is not an independent wall clock and need not equal the timer exactly. `simulatedSeconds` is `ticks × 1/60`, excluding dropped time. `callbackHz` is `frames / activeFrameSeconds` (zero before elapsed time), the cadence of accepted active callbacks; record separately sampled whole-client FPS independently. `maxElapsed` is whole-frame elapsed time, not measured addon CPU overhead. Stop preserves the residual accumulator for readback, and the inactive clock cannot advance. This one-kart experiment does not validate 32 sprites, multiplayer, production tracks or a lap engine.

## 3a. Optional bounded update-render timing

**Status: PARTIAL client evidence, 2026-10-19.** A stationary guarded diagnostic recorded 600 attempts/samples, zero invalid, total average 0.0264 ms / maximum 0.2111 ms including probe overhead. Ticks continued past the collection cap; stopped/reopen/disarm output retained values. Automated Start clicks were unsuccessful, so an existing guarded Start was called once after chat closed; this does not accept the mouse-click sequence below. Fresh unprofiled Start and full errors/handling/performance checks remain pending. [Exact conditions and output](../docs/evidence/2026-10-19-m0-stationary-profile.md).

Profiling is off by default. This sequence measures one short diagnostic window of up to 600 active updates, independent of the three approximately 60-second F1 drives. It neither automates driving nor requires another combat test. Run when the client is available, outside combat and after loading the installed source through normal startup or `/reload`; record actual runtime identity and any errors.

1. With driving stopped, open `/akart` if needed. Copy the unchanged six-line `/akart probe`, normal FPS/scale readbacks, and then run these commands separately:

```text
/dump type(debugprofilestop)
/akart perf
/akart perf on
```

2. Record the exact type and arming result. `perf on` checks one guarded finite, nonnegative clock read. If unavailable/invalid, record that result and leave profiling acceptance pending; do not replace the reader, call `debugprofilestart` or change client restrictions. Ordinary driving must remain usable. If armed, close chat and deliberately click **Start Race**. Drive/steer normally for several seconds. Collection caps at 600 active updates, with three clock reads per attempted update (at most 1,800 plus the arming read); its elapsed duration varies with actual callback cadence. Completion must not print chat or stop the kart.
3. Stop normally with Escape or Stop, recording the actual stop reason. Only then run:

```text
/akart probe
/akart perf
```

4. Copy all three performance lines: armed/API/collection state, attempts/samples/invalid/limit, simulation/render/total averages/maxima in elapsed milliseconds, and scope. The output is three lines total: status/counters, timing aggregates, scope. If stopped before the cap, retain the partial sample as partial evidence. Invalid, backwards or throwing reads/validation consume attempts without inventing valid samples or stopping driving; `samples + invalid` should equal `attempts`, never exceeding 600. Zero means/maxima with no valid samples do not demonstrate zero cost.
5. Wait several seconds and repeat `/akart perf`. Close and reopen with `/akart` twice without Start; repeat `/akart perf`. The same aggregates/counters must remain frozen, and the window must reopen stopped. Then run:

```text
/akart perf off
/akart perf
```

6. Verify `armed=false` and the same retained stopped aggregates. Click Start deliberately for a fresh unprofiled drive, then stop and query `/akart perf`: the old diagnostic window must be cleared. Optionally arm a fresh window again, Start, stop early, and verify only that new window is reported. Record visible handling problems and explicit UI counts; do not infer responsiveness or unchanged allocation from a timing number alone.

- [x] Live function type and successful guarded arming recorded on build 70450. Missing/erroring-reader behavior is offline evidence only.
- [x] Three-line report captured with actual counters/elapsed means/maxima and unchanged six-line ordinary probe/counts.
- [x] Attempt budget/counters bounded at 600; no unsolicited collection/completion output observed; stationary simulation continued to tick 1959 across 7334 callbacks.
- [ ] Stopped/delayed/close-reopen output and disarm retention OBSERVED; fresh unprofiled Start/reset remains NOT RUN. Reload clearing the sample does not establish this Start behavior.
- [ ] Client errors, visible handling/hitch symptoms, build, FPS/scale and test conditions recorded; real live cost acceptance remains pending until measured.

These scoped elapsed milliseconds include clock/protection instrumentation overhead around `Loop.advance` and render/HUD work. They exclude preceding input/focus/combat guards, aggregate/report work and native GPU rendering; they are not exclusive addon CPU cost. The addon never resets the shared profiler timer with `debugprofilestart`. Backwards timestamps reject, but another addon's reset can leave plausible positive spans and evade detection. [CLIENT_API.md](../docs/CLIENT_API.md#optional-bounded-updaterender-timing) records the pinned build-70450 primary source and remaining runtime uncertainty. Offline tests cover invalid/throwing reads, cap behavior and unchanged deterministic driving; those do not constitute live profiler verification.

## 3b. Stopped/open idle stability

**Status: PASS for this scoped idle check, 2026-10-19 15:29:48.901–15:45:06.499 CEST.** Completed 917.598 wall-clock seconds (917.608 monotonic) without agent input. Endpoint probe retained all counters/tick 852, counts 6/99/3, inactivity and profiling off; effective scale stayed 0.72452831268311. Before/after FPS points were 206.00857543945 / 198.3470916748. Sampled road/controls stayed readable without an observed error dialog; no continuous hitch/taint measurement was made. Normal close/reopen retained the sample; final hidden/inactive/profiling-off readback passed. The earlier attempt was interrupted by confirmed owner use and remains an interruption, not a failure. [Exact evidence](../docs/evidence/2026-10-19-m0-idle.md). This does not replace the ten-minute human drive, full focus matrix, supported-scale matrix or memory/CPU measurement; the combined section 3 checkbox stays pending.

1. Confirm the returned WoW window, current installed source/build and an inactive kart. Open `/akart` without Start; keep profiling off. Record an independent start timestamp, `/akart probe`, `/dump GetFramerate()` and `/dump UIParent:GetEffectiveScale()`. Keep other addons/settings unchanged.
2. Leave the kart stopped/open for 15 measured minutes. Do not arm input, drive, change scale, generate combat, or add any per-update diagnostic. If input occurs or the client closes/hides/disconnects, record the actual interval and interruption rather than claiming a completed run.
3. Record the end timestamp, the same probe/FPS/scale readbacks and visible errors/hitches. Counts, stopped tick and timing must remain frozen; the road/controls must remain readable. A start/end FPS pair consists of two whole-client observations, not sustained FPS or exclusive addon cost. Leave memory/CPU checks NOT RUN unless separately measured.
4. Close/reopen normally, repeat the stopped probe, then leave the window hidden and controls inactive. Record exact elapsed duration, conditions and results in PROGRESS. Keep unsupported/unavailable checks pending.

## 3c. One supported-scale comparison — prepared independent M0 task

**Status: INCOMPLETE / REVIEW NEEDED, 2026-10-19 16:19–16:27 CEST.** The normal Use UI Scale control was found unchecked at stored 100%. Apply confirmations expired before acceptance; the changed-scale renderer/probe was not verified. Original preferences/CVars returned, but effective scale changed from 0.72452831268311 to 0.71111112833023. All clock counters and counts 6/99/3 stayed frozen, final hidden/inactive/profiling off. Further scale changes stopped for review under step 4. [Exact evidence](../docs/evidence/2026-10-19-m0-scale.md). This is not a scale-matrix or M0 pass.

1. Inspect the normal client Options for an available UI-scale control. Record its actual label, enabled/automatic state, current displayed value and supported range/steps. Do not assume a menu path or that 0.75/1.0/1.25 are supported. If no normal control is available, record UNAVAILABLE and make no scale change.
2. Open `/akart` without Start. Record a timestamp, build/source identity, road/controls appearance, `/akart probe` and these read-only values:

```text
/dump GetCVar("uiScale"), GetCVar("useUiScale")
/dump UIParent:GetEffectiveScale()
```

3. Choose one different supported setting through that normal control, apply it normally and record the actual displayed setting, the same readbacks/probe and appearance. If the client presents a timed acceptance dialog, verify acceptance before collecting the changed-setting sample; automatic reversion is not a completed comparison. Do not repeat setting changes when the tool roundtrip cannot meet that deadline; leave the probe pending. Check full road/island/marker/kart visibility, horizontal seams, clipping, text and access to Start/Stop/Close/Print Probe. Keep capture inactive; the existing clock/state and explicit counts must stay unchanged. Effective scale is a measured value, not the nominal slider value. If a normal reload is required to apply, record it and collect a fresh inactive baseline; do not claim the old clock survived reload.
4. Restore the exact original control value and automatic/enabled state through the normal UI, apply normally and verify the original CVar values and effective scale return. Do not use arbitrary `SetCVar` writes to reach unsupported values. If restoration fails, record it and stop for review. Close/reopen once to check readability/inactivity/counts, then finish hidden/inactive with profiling off.
5. Transcribe sanitized results into the table and PROGRESS, including both changed and restored readbacks and any interruption. An unavailable setting remains pending, not a failure or a pass. Whole-client FPS, if sampled separately, is only a point observation.

| Point | Normal control value/state | uiScale / useUiScale | Effective scale | Probe/canvas/readability | Status |
|---|---|---|---|---|---|
| Original baseline | Unchecked; stored 100% | 1.000000 / 0 | 0.72452831268311 | Tick 852, counts 6/99/3, full canvas/controls readable | OBSERVED |
| One supported alternative | Checked; 100%, Apply then timed reversion | NOT READ during temporary state | NOT READ | Kart hidden; changed-scale renderer NOT RUN | INCOMPLETE |
| Restored original | Unchecked; stored 100% | 1.000000 / 0 | 0.71111112833023 | All counters/counts frozen; hidden/inactive/profiling off | Preferences restored; effective-scale criterion unmet, REVIEW NEEDED |

## 3d. Read-only geometry review — deferred M0 check

**Status: PREPARED, NOT RUN; deferred under ADR 0007.** This review does not block local M1 work. Review the scale mismatch before further setting changes. At unchanged settings, record timestamp and actual build, then run these lines individually. Each optional call is type-checked and protected; its returned table begins with the `pcall` success boolean. Record unavailable/error results; if reporting encounters restricted or secret values, stop that read without coercion or a fallback access path.

```text
/dump GetCVar("uiScale"), GetCVar("useUiScale")
/dump type(GetPhysicalScreenSize)=="function" and {pcall(GetPhysicalScreenSize)} or "unavailable"
/dump type(GetDefaultScale)=="function" and {pcall(GetDefaultScale)} or "unavailable"
/dump UIParent and type(UIParent.GetWidth)=="function" and {pcall(UIParent.GetWidth,UIParent)} or "unavailable", UIParent and type(UIParent.GetHeight)=="function" and {pcall(UIParent.GetHeight,UIParent)} or "unavailable"
/dump UIParent and type(UIParent.GetScale)=="function" and {pcall(UIParent.GetScale,UIParent)} or "unavailable", UIParent and type(UIParent.GetEffectiveScale)=="function" and {pcall(UIParent.GetEffectiveScale,UIParent)} or "unavailable"
```

Keep the kart hidden/inactive and profiling off; do not change settings, reload, Start or supply character input. Compare only observed current dimensions with the pinned source described in [CLIENT_API.md](../docs/CLIENT_API.md). The former physical/window dimensions were not measured, so a numerical 1060/1080-height relationship cannot establish their history or explain the earlier scale. Record the review outcome and one next task; keep the accepted-alternative comparison pending.

## 4. F5 minimal SavedVariables persistence

Only schema initialization exists. A schema value recreated at load does not prove persistence. The optional sentinel below adds and removes **one unused field in AzerothKartDB only**; it must not replace the table, touch another addon's data or overwrite an existing field.

1. Stop the drive. Check that the field is unused:

```text
/dump AzerothKartDB and AzerothKartDB._m0Probe
```

2. If the field is nil and the DB is a table, run this guarded setup, replacing the sample token with this test's unique date/time token. If it says `sentinel not set`, stop this subtest and record why; do not clear an existing field.

```text
/run if type(AzerothKartDB)=="table" and AzerothKartDB._m0Probe==nil then AzerothKartDB._m0Probe="M0-20261018-A" print("sentinel set",AzerothKartDB._m0Probe) else print("sentinel not set") end
```

3. `/reload`; then run the two readbacks below. Repeat after normal logout/login and a full game exit/restart. Verify the exact token survives each boundary, no Lua errors occur and the race stays inactive until deliberate Start.

```text
/dump AzerothKartDB and AzerothKartDB.schemaVersion, AzerothKartDB and AzerothKartDB._m0Probe
/akart probe
```

4. After all three boundaries, remove **only the sentinel you created** using its exact token; reload and verify nil.

```text
/run if type(AzerothKartDB)=="table" and AzerothKartDB._m0Probe=="M0-20261018-A" then AzerothKartDB._m0Probe=nil print("sentinel removed") else print("sentinel unchanged") end
/reload
/dump AzerothKartDB and AzerothKartDB._m0Probe
```

- [ ] Sentinel survives reload; evidence: ______
- [ ] Sentinel survives logout/login; evidence: ______
- [ ] Sentinel survives full exit/restart; evidence: ______
- [ ] Test sentinel removed; inactive post-load controls verified; evidence: ______

Do not mark settings/ghost saves, migrations or corrupt-save recovery passed: those features are not implemented. Persist observed outcomes, exact errors and evidence links in `docs/FEASIBILITY.md` and `docs/PROGRESS.md`, keeping any unexecuted row pending.

## Deferred wall-slide Physics8 check — NOT RUN

After a full client restart for the revised city pictures, drive a shallow and
a45degree approach into a city wall with throttle held: slide along it while
steering away, without needing reverse. Try a frontal hit then hold throttle
and turn; it should release promptly, while a straight blocked hit still stops.
Check stationary turning is quicker and drift/boost cancels at contact. Do not
claim every corner/FPS/performance case passed from one drive. Both friends
need Physics8 before the next Multiplayer race; the usual menu flow applies.
