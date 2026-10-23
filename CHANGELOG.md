# Changelog

## Unreleased — Undercity's slime river and no shoulders on city streets (2026-10-23, `claude/undercity-river`)
- **Undercity Slime Circuit version 2**, the owner's revamp: "a river of slime with bridges at every section", the karts "crossing the bridges (sharp turns)". The slime is the canal ring round the Trade Quarter; from his arrow below the Apothecarium the course runs counter-clockwise along its walkways and changes walkway on a bridge at every section: six bridges, timber and stone by turns as in his screenshots, each a sharp turn on (radius 70), a 197-unit straight across the slime and a sharp turn off. Six gates (Rogues' Quarter, Magic Quarter, Ruins of Lordaeron, War Quarter, Apothecarium, The Canals); a 5,797-unit lap (7,327 before). The Trade Quarter stays sunk beside the course; the stone bridges rise in painted humps.
- The painter's bridges gain timber decks on piles with a timber railing (`deck: "planks"`), coloured stone decks, their own corner lamps (`posts`) and bridges over water drawn whole (`force: false`, hanging their side only below the deck). Each quarter draws its buildings on both sides of the slime.
- **No shoulders on a city map** (the owner): every city's street is paved from wall to wall, to a kerb at the walls' foot; Stormwind, Orgrimmar, Darnassus and Undercity already had full grip to their walls. Ironforge version 4 gets it too (`fullSpeedToWalls=true`; its edge strip used to slow karts): proposed for Codex review; route, gates, spawn, narrows and walls unchanged. All five pictures are rebuilt; the circuit data change only in Undercity's definition and Ironforge's version and flag.
- `tests/test_circuit.lua` walks Undercity's six gates in order from the loop and checks Ironforge's road to its walls (the default rough policy is still checked on a copy). Menu: Undercity's blurb and facts. The drive, the turns and the pictures in the client are NOT RUN.

## Unreleased — Darnassus, Undercity and painted elevation (2026-10-23, `claude/darnassus-undercity`)
- **Darnassus Canopy Run** and **Undercity Slime Circuit** join the Capital Cities Cup and are selectable; only Thunder Bluff Skyway remains coming soon. Both follow the owner's red lines on his in-game maps. Darnassus: the start road in from the Warrior's Terrace at his red marks, then north at the central terrace as his blue arrow points and counter-clockwise past the Craftsmen's Terrace, the Cenarion Enclave, the Temple Gardens' lake, the Temple of the Moon and the Tradesmen's Terrace (six gates, a 3,895-unit lap, a 206-unit approach). Undercity: "start at blue line in apothecarium": the grid on the loop below the Apothecarium heading east, round the Rogues', Magic and War Quarters, a hairpin into the inner city, clockwise round the Trade Quarter and out over the southern canal (five gates, a 7,327-unit lap, no approach road: the spawn is on the loop, as on Mirage Raceway). Full grip to the walls in both; existing definition fields only, no Circuit change.
- **Elevation, looks first** (the owner chose looks, then slopes, then bridges): a city may stand on several levels. The painter draws retaining walls where higher ground lies north, a raised street's wall hanging below it, lit brinks over drops, the sun's shadows from every rise, height's light and ramps lit by their slope with joints across them. Darnassus has three terraces (44, 22, 0); Undercity's Trade Quarter is sunk 30 below its rings. Karts still drive flat. The generated `CapitalCities.lua` carries each new city's street heights, inert until Codex accepts the proposed slopes and bridges contract ([ADR 0015](docs/adr/0015-track-elevation.md), proposed; [API_CONTRACTS](docs/API_CONTRACTS.md#proposed-track-elevation-claude-2026-10-23-for-codex-review)).
- Undercity's look: each quarter in its own stone, the Scourge's buildings with their fires made Forsaken green, glowing green slime canals (`water_tile`, `water_glow`), Sylvanas before Lordaeron's throne at the stair to the Ruins, a slime well at the Trade Quarter's heart. Darnassus: Silvermoon's houses in Darnassus violet, ancients and moon wells, Ashenvale trees, the World Tree's bark round the city.
- The Track button cycles Stormwind, Ironforge, Darnassus, Orgrimmar, Undercity. `tests/test_circuit.lua` walks both new cities' gates in order with wall-free centerlines (Undercity's walk starts on the loop), drives from both grids and checks the heights; `tests/test_menu.lua` follows the longer cycle and uses Thunder Bluff as its coming-soon example. Explicit counts unchanged (79/166/81). The fourth and fifth 2048-square pictures, the drives and the menus in the client are NOT RUN. Also: the trailing space in the Orgrimmar sheet that Codex's review noted.

## Unreleased — Orgrimmar Canyon Rush (2026-10-22, `claude/orgrimmar`)
- **Orgrimmar Canyon Rush** joins the Capital Cities Cup and is selectable (three cities remain coming soon). The owner drew a route from the West Gate out and back along the canyon road and offered a blue loop round the Cleft of Shadow if that stretch could not be lapped; it could not (two one-way roads, a hairpin and a second bridge, at half scale), so the course is the blue loop, counter-clockwise, with the start on the canyon road behind a gate of the city wall: the Valley of Strength, the Drag, under the north wall past the Valley of Wisdom and Grommash Hold, down the Cleft's rim. Four gates; a 4,769-unit lap; full speed to the walls as in Stormwind. See `docs/art/tracks/orgrimmar.md`.
- An open-air canyon city from Warcraft III's Barrens: red rock with cliff faces in the Barrens cliff's strata (`rock.face_texture`), the Cleft of Shadow sunk below the city (`pits`) with Ragefire's lava fissure, a spiked timber palisade along the streets (`land_wall`), orc buildings, banners and the Horde's people, Orgrimmar's own gate from Warcraft III behind the grid. Doodads can drop their ground patch (`cut`) and cast cut-out shadows (`alpha_shadow`). All optional; Stormwind's and Ironforge's bytes are unchanged.
- The Track button cycles on to Orgrimmar. `tests/test_circuit.lua` walks its gates in order with a wall-free centerline and drives from the grid; `tests/test_menu.lua` follows the longer cycle; the gate-pool test includes its four gates. Explicit counts unchanged. The third 2048-square picture, the drive and the menus in the client are NOT RUN.

## Unreleased — four Warcraft III karts (2026-10-22, `claude/kart-roster-wc3`)
- Asked what next, the owner chose more karts and all four vehicles offered from Warcraft III itself: the **Dwarf Car**, **Orc Demolisher**, **Meat Wagon** and **Glaive Thrower**, rendered from Blizzard's own Reforged models in his install into 64-heading sheets like the other karts. Ten karts in all (the release target is eight); all drive the same.
- `build_wc3_kart.py` reads Warcraft III's own vehicles (`--wc3`: MDX 1800 and DDS through `wc3render.py`, verified by SHA-256). Effects: the Dwarf Car's steam pipe and the Demolisher's fire pots flame when boosting; the Meat Wagon and Glaive Thrower trail wind. The kart screens list ten buttons: explicit counts 75/165/80 (+4 frames, created once). Client appearance NOT RUN.

## Unreleased — the Great Forge in Warcraft III textures (2026-10-22, `claude/ironforge-polish`)
- After the owner's drive of Ironforge version 3 ("Forlorn Cavern is good. The lava is good."): the Great Anvil is half its size, and the anvil and pumps wear Warcraft III textures: the steam tank's riveted plates and brass straps, the power generator's brass rail, copper coils, rune-cut iron, pipe and hatch, the mine cart's dark iron. `city_meshes.py` gains texture paints (a texture rectangle, tint and repeat by world size). Art only: route, collision and `CapitalCities.lua` unchanged; Stormwind byte-identical.

## Unreleased — Ironforge version 3 after the owner's drive (2026-10-22, `claude/ironforge-design`)
- Codex review: accept the additive narrows contract, add overlap/closing-segment/copy/branch regressions and fix a tiny rough pocket in fully paved tunnel corners; default shoulders and wall geometry stay unchanged. Coordinated local install verified41files with41-file backup; v3 client checks remain pending.
- **Forlorn Cavern tunnels.** The way in from the Mystic Ward and the way out towards the Hall of Explorers are narrow tunnels through the rock: no shoulder, the wall at the paving's edge (the kart centre stops 42 from the centerline, the painted wall at 56), flaring back to the usual street after each. New optional circuit field `narrows` (per-segment wall radius, paved no further), proposed in API_CONTRACTS for Codex's collision review; additive, Stormwind's data and picture byte-identical.
- **Lava.** Pools stop at the street's wall like water (no grey unlit paving across their corners), no bank face, no ridges; a dark iron wall stands all round each pool; the glow is kept.
- **The Great Forge.** No buildings, trim or braziers between the two forges: the Great Anvil and four pumps, procedural models (`scripts/city_meshes.py`) drawn with the scenery's light and shadow. Track facts mention the tunnels. Offline: both Lua suites, the boundary tests and `--check` pass; the drive and look in the client are NOT RUN.

## Unreleased — Ironforge integration correction (2026-10-22)
- Preserve Stormwind full-speed/version3 corner handling and staged background loading while integrating Claude de2fa5f. Ironforge version2 reuses the existing exposed-wall clearance to avoid an invisible gate-hall corner; art and route stay unchanged, rough shoulders remain.
- Add Ironforge restore/selection, destructive image refusal and seven-to-six-to-four gate visibility regressions. No global Physics, multiplayer or other-agent checkout changes.

## Unreleased — Ironforge Grand Prix (2026-10-22, `claude/capital-cup`)
- **Ironforge Grand Prix** joins Stormwind in the Capital Cities Cup and is selectable (four cities remain coming soon). The course follows the owner's line on the in-game Ironforge map, clockwise: from the Gates (Dun Morogh's snow behind them) up the Commons' ring, round the Mystic Ward, the Forlorn Cavern's lake and the Hall of Explorers, through the Great Forge between its two molten forges and round the southern one, out past Tinker Town, through the Military Ward and back to the Commons. Seven gates named for the districts; a long lap (7,077 units, about 1.8 × Stormwind's). See `docs/art/tracks/ironforge.md`.
- An underground city: the halls are open floor, the rest the mountain's rock with dressed-stone faces; lava pools with stone ridges and glow, a lake and a pool with spiral rings, pools of light from braziers, torches and crystal lamps; district palettes kept sparse with per-model limits. All optional city data in `city_paint.py`; Stormwind's bytes are unchanged.
- The Track button cycles Test Oval, Mirage Raceway, Stormwind City and Ironforge. `tests/test_circuit.lua` walks Ironforge's gates in order with a wall-free centerline; `tests/test_menu.lua` follows the longer cycle. Explicit counts stay 71/165/80. The second 2048-square picture, the drive and the menus in the client are NOT RUN.

## Unreleased — Stormwind painted-wall collision alignment (2026-10-22)
- Remove the invisible collision wedge at the Park/Mage corner: compute clearance from the exposed painted wall union, retaining normal straight-wall padding and full-speed street handling. Stormwind trackversion3; artwork/othertracks/globalPhysics unchanged.
- Keep reachable corner slides within the requested movement bound, and add reported-corner, real-wall and pure analytic geometry regressions.

## Unreleased — Stormwind full speed to the walls (2026-10-22)
- Remove Stormwind's kerbside slowdown; drift and boost now continue across the whole street until wall contact. Wall geometry/collision, artwork and other tracks are unchanged.
- Add opt-in Circuit fullSpeedToWalls surface policy, emitted by the layout generator for Stormwind track version2; global Physics remains7. Update menu/help and focused speed/drift/boost/wall regressions.

## Unreleased — latest city integration installed for owner testing (2026-10-22)
- Review/integrate Claude capital-cup78d97a1 with all existing UI/backend work; Stormwind joins Test Oval/Mirage, with six cosmetic karts. Multiplayer remains Coming soon.
- Protect the current map/results when a new background refuses to load: one hidden preallocated staging texture, swapped only on success. Pool71/165/80; no per-tick loads/creation.
- Full offline integration passes. Install39files with verified22-file backup; publish the combined feature branch. Native owner testing follows a full client restart. No main merge or release.

## Unreleased — reviewed UI/backend integration and preference fix (2026-10-22)
- Combine Claude's reviewed solo menus, HUD/results/garage/settings and Codex's session/start-clock backend on `codex/ui-backend-integration`, preserving both histories. No multiplayer commands or live-race activation added.
- Adopt Claude4ffe184: an explicit successful choice of the current fallback track/kart is now saved; it supersedes deferred restoration without erasing an untouched failed-load preference.
- Add regressions for deferred/failed restoration, quick track cycling, newer preference records and unchanged stopped state/input. Existing selectors, simulation and assets are preserved. Full offline integration passes; client checks, deployment and publication remain pending.

## Unreleased — logged session transport/menu actions (2026-10-21)
- Wire PeerSession to the existing Forever logged-whisper route with explicit Host/Listen/Join/Ready/Start-proposal/Leave actions and copied menu views. Startup stays idle and no action starts Race.
- Add strict native result/lifecycle handling, fresh-code limits and persistent paced call/byte accounting. Exclusive frame/native-call ownership prevents probing and session control from detaching or overlapping each other; solo Start closes control first.
- Add focused native doubles and menu integration guide. No install, actual AZKART2 traffic or new manual test; live start clocks and race integration remain pending.

## Unreleased — Stormwind through its streets (2026-10-22, `claude/capital-cup`)
- Rework Stormwind's look from the owner's review so the course reads as Stormwind's own streets: three straight stone bridges where the course crosses from one district to the next (slab decks, crenellated parapets with arches, corner lanterns, the city guard at the ends); each district paves its own street, with kerbs and pavement out to the walls; walls by what lies beyond them (canal parapets, house fronts, the Park's hedge, timber barriers across five closed side streets); people watching from each district.
- **Cathedral Square:** the street runs right along the foot of the Cathedral of Light's steps, as on the owner's screenshot. The Cathedral is larger, white-stoned and gold-roofed, with the blue carpet up its painted steps and two priests; the square and its fountain stand across the street behind a balustrade. The open plaza and the solid fountain are gone: Stormwind has no plazas or solids, and the course's centerline never meets a wall.
- The Mage Quarter's road is grey cobbles; its violet stays in the district beside it.
- Determinism: the model renderers (`build_wc3_kart.py`, `wc3render.py`) add float sums left to right instead of with `sum()`, whose compensated summation since Python 3.12 moved a few texels of skinned models between Python 3.10 and 3.13 (found by the developer machine's `--check`). The kart sheets are unchanged: all five check-pass on Python 3.10, where both ways add alike. The city sprite cache key becomes `sprite-v3`.
- Generator: `wc3render.render` gains `stone` levels and recolor saturation/value scales; `city_paint` paints steps, squares and per-stretch wall styles and can stand a landmark facing the course (`front`). Lap 3,831 units (was 3,766). `tests/test_circuit.lua` now asserts no solids or plazas and a wall-free centerline. Client appearance and the drive are NOT RUN.

## Unreleased — Capital Cities Cup: Stormwind City Circuit (2026-10-21, `claude/capital-cup`)
- Add the **Capital Cities Cup** to the track screen, under the **Proving Grounds** (Mirage Raceway, Test Oval): **Stormwind City Circuit** is ready; Ironforge Grand Prix, Darnassus Canopy Run, Orgrimmar Canyon Rush, Thunder Bluff Skyway and Undercity Slime Circuit are listed as coming soon. See `docs/art/tracks/stormwind.md`.
- Stormwind follows the owner's line on the in-game map: start in the Valley of Heroes, through the gate into the Trade District, over the canal along Old Town, round the canal's head in the Dwarven District, through Cathedral Square, along the Park and the Mage Quarter and back over the canal to the finish. Six gates named for the districts; the HUD names the next. A street circuit: a 112-wide road, a rough kerbside strip, then the city's walls (the first build's solid fountain on an open plaza was removed on 2026-10-22, above).
- New pure modules, loaded after `MirageRaceway` in both TOCs: `Circuit.lua` (street circuits from data: capsule road and walls, plazas, solid boxes, the track interface Physics already uses), generated `CapitalCities.lua`, and `Courses.lua` (cups, display order, coming-soon entries, building each course). **Codex reviews the collision** (solid scenery beyond the Test Oval, at the owner's choice) and the `UI.SelectTrack` generalisation.
- Scenery from Warcraft III Reforged (the owner's install, read by the new read-only `scripts/wc3casc.py`): `Assets/Tracks/Stormwind/Background.tga` (2048×2048, 16 MiB) and `Preview.tga` (512×512), built by `scripts/build_city_tracks.py` with `scripts/city_layouts.py`, `city_paint.py` and the model renderer `wc3render.py`. Terrain tiles, canals with quays and arched bridges, a stone balustrade along the street, the Cathedral, statues, the gate towers, canal-island towers, district buildings with Stormwind-blue roofs and the Mage Quarter's violet. Redistribution of the Blizzard files is unresolved for release review.
- `UI.SelectTrack` accepts any available course and loads its picture with the same guards; the Track button steps through the ready tracks. Eight pooled gate strips. The saved track accepts any ready course. Explicit counts become 71 frames/164 textures/80 font strings.
- New `tests/test_circuit.lua`; `tests/test_ui.lua` and `tests/test_menu.lua` get the new counts, gate pool and Track button cycle. The 2048-square texture, the drive and the menus in the client are NOT RUN.
- Fix (Codex's review of `claude/ui-flow`, P2): choosing the already-current track or kart on a menu screen is now remembered, and a track choice cancels a saved-track restore still waiting for an open out of combat. Regressions cover the review's three paths.

## Unreleased — front-end menus, race HUD and results (2026-10-21, `claude/ui-flow`)
- Add `Menu.lua` (presentation only), loaded after `UI` in both TOCs. Opening the window shows a main menu in the client's own dialog style: **Single Player**, **Multiplayer** (a disabled coming-soon lobby preview), **Garage**, **How to Play** and **Settings**. See `docs/art/ui/front-end.md`.
- Single Player goes Choose a Track (preview pictures and facts) → Choose Your Kart (a turntable of the kart's own heading sheet, the six-kart grid and model credits) → **Race!**. Only **Race!**, **Start Race** and **Restart** call `UI.Start`; menus refuse to open over a live run and never write run, race, physics, input or session state.
- The race view gets a large LAP/gate HUD, the clock and best lap, and a big gold 3-2-1-GO. The bar's Start reads **Start Race**, and Stop moves away from it. The results panel becomes a 460×312 dark dialog listing every lap, the fastest in green, with **Change Kart**, **Change Track** and **Main Menu** added to Restart and Close results.
- Save the track, kart and settings in `AzerothKartDB.preferences` (version 1, validated on read; unknown fields kept; a newer record is never overwritten). Settings: window size 80–125% (sizes that do not fit are disabled), drift/boost effects (`UI.SetEffectsEnabled`), sound effects and developer info (the timing line and Print Probe). The window can be dragged by its title.
- Client sounds through `SOUNDKIT`: menu open/click/check, 3-2-1-GO beeps and one fanfare per finished run.
- Add one original atlas, `Assets/UI/TrackPreviews.tga` (1024×512, 2 MiB, loaded on the first track-screen visit), built by `scripts/build_ui_art.py` from scenery v1 and `Track.lua` geometry. `scripts/preview_ui.py` draws a layout review of every screen.
- Explicit UI counts become 65 frames/160 textures/79 font strings, all created with the window. If the front end fails to build, it reports once in chat and the basic bar remains. New `tests/test_menu.lua`; `tests/test_ui.lua` keeps Codex's assertions, with updated counts and summary size and a Lua 5.4 `unpack` fix. Client appearance, sounds and fonts were NOT RUN. Codex accepted first-open saved-track restoration in the subsequent review, and the2026-10-22 entry records the explicit-choice correction/integration.

## Unreleased — preserved-history roster integration (2026-10-21)
- Combine Claude's six-kart selector/neutral artwork with Codex's Close results, Forever transport, measured evidence and pure PeerSession foundation. No installation or new live-race feature.
- Fix late kart-load rollback to restore the entire previous visual; failed restoration uses Basic without altering the stopped run. Retain per-kart opacity floors rather than weakening all existing art for flyers.
- Record one integration/deployment owner and a combined source baseline. Explicit allocations11frames/151textures/13fonts; older entries below retain their historical branch counts.

## Unreleased — four more karts and a Kart button (2026-10-21, `claude/track-ui`)
- Add the Steam Tank, Dwarven Biker, Gryphon Rider and Gyrocopter: 1024×1024 sheets of 64 three-quarter headings under `Assets/Karts/`, rendered by `scripts/build_wc3_kart.py` from Warcraft III models of the wc3c ITE project archived on WC3Vault (authors unknown; redistribution unresolved). Flyers hover with detached shadows; the Gyrocopter's rotor is an original translucent disc. See `docs/art/karts/roster.md`.
- Add `scripts/wc3jpeg.py`, a pure-Python baseline JPEG decoder for JPEG BLP1 textures with libjpeg's integer inverse DCT; its samples matched libjpeg's (through Pillow) exactly on all five shipped textures. `build_wc3_kart.py` now builds every registered vehicle (`--all ROOT`) with byte-identical output on any platform; the trike's sheet is unchanged.
- A stopped-only **Kart** button cycles six cosmetic karts (`Presentation.KART_ORDER`, `nextKart`, `UI.SelectKart`). A choice loads with the creation-time guards, a refusal keeps the current kart, and it never touches the run, result, track or simulation; every kart drives the same 17×31 body. It is disabled during a run and not saved. Explicit counts become 10 frames/151 textures/13 font strings.
- Per-kart effect anchors from each model's own emitters. The Gryphon Rider has no exhaust: it trails wingtip wind puffs while boosting.
- Loaded kart art is no longer tinted per drift/boost phase (owner direction): the effects carry that feedback. The primitive fallback keeps its phase colours. Client appearance is NOT RUN.

## Unreleased — recovery evidence and race-control codec (2026-10-21)
- Record listener addon reload to Idle, the sender's bounded ACK-deadline stop and successful fresh-session recovery (19/19 DATA and replies). Unknown reload timing and lost receiver counters remain explicit.
- Add pure RaceProtocol encoding/decoding for INVITE/JOIN/READY/START/CANCEL/ACK. Exact bounded messages, compatibility metadata, sequence/session fields, malformed-input refusal and ACK-of-ACK rejection; both TOCs load it without any API calls or traffic.
- Begin the bounded experimental two-peer control implementation under ADR 0013. Session policy, retries, clock alignment, menu integration and live race synchronization are not implemented by the codec. No client update or new manual probe is requested yet.

## Unreleased — Forever full names and IOU transport reuse (2026-10-21)
- Fix `net listen/start First Surname CODE`: the surname/code no longer become session/numeric options. Prefer quoted full names; unquoted names and six-digit codes also work. Reject ambiguous commands with a quoting hint.
- Replace the erroneous realm requirement with complete Forever-name matching; preserve surnames, punctuation and UTF-8, normalize only ASCII spaces/case.
- Reuse IOU's previously tested `SendAddonMessageLogged` / `CHAT_MSG_ADDON_LOGGED` route with no fallback. Report `WHISPER_LOGGED`, respect actual chat lockdown, and preserve pacing/accounting/abort bounds. No sustained transport result or multiplayer capacity is inferred from IOU's four round trips.
- Correct the in-game help and two-player guide. Both testers need this updated build and a fresh code. No visual, physics or race changes.

## Unreleased — close results and plain connection-test help (2026-10-21)
- Add a separate Close results button to stopped/finished summaries. Dismissal retains the track, lap times and stopped sample, and survives window close/reopen until a fresh run or map change.
- Add `/akart net help` and a plain guide for a test with a friend. No connection-test GUI or automatic traffic is added; the existing first-window defaults and transport gates remain unchanged.
- One pooled button plus the reviewed effect integration gives 10 frames/151 textures/13 font strings. No new per-frame UI objects or authoritative simulation fields.

## Unreleased — drift and boost effects (2026-10-21, `claude/track-ui`)
- Drifting throws pale tyre dust and a spark spray from the rear wheels in the drift meter's colours: blue while charging, gold at tier 1 and magenta at tier 2. The spray thickens as the charge grows and thins while a correction holds it. Boosting lights a flickering two-layer flame at every exhaust and trails goblin soot, with a burst on the tick the boost fires; the flame shrinks as the boost runs out.
- Add two original atlases under `Assets/Effects/` (Particles 256×128, Flame 512×256), painted by the new `scripts/build_effect_sprites.py` with byte-identical output on any platform. Directions are pre-rendered cells, so drawing never uses `SetRotation` or `SetBlendMode`.
- `Presentation` gains pure effect helpers (`EFFECTS`, `newEffects`, `clearEffects`, `advanceEffects`, `particleAt`, `effectCoords`) and per-kart effect anchors. The trike's anchors are its model's own wheel-dust and exhaust emitters (`build_wc3_kart.py --emitters`). Effect time is the interpolated tick, and identical sampled-state and effect-update sequences give identical particles.
- UI pools 38 textures created once and hidden while idle: explicit counts become 9 frames/151 textures/13 font strings. A refused atlas disables effects only. Offline drives keep the simulation identical with effects on, refused or under the primitive kart. Client appearance and cost are NOT RUN; see `docs/art/effects/drift-boost.md`.
- Add `scripts/preview_effects.py`, which runs the addon Lua against a recording widget mock and composites a review image of a scripted Mirage drive.

## Unreleased — explicit run exits and reviewed visual integration (2026-10-20)
- Keep driving through incidental mouse clicks and unassigned keys without clearing held input or drift. Remove the global mouse-down exit that disabled Stop before its OnClick. Explicit Stop/Escape ends the run; Close and chat/focus/lifecycle handling remain deliberate exits.
- Keep partial results frozen and replace "Controls released" with concrete next actions. Start/Restart creates a new countdown; no pause/resume state is added.
- Integrate reviewed Claude scenery, attached shadows and the Goblin Mortar Trike with Physics v7, Test Oval-only solids and the opt-in transport probe. Directional sprite helpers are implemented contracts; the combined explicit pool is 9/113/13. Neither Mirage geometry nor vehicle handling changes.

## Unreleased — bounded two-client transport experiment (2026-10-20)
- Add pure NetworkProbe accounting/codec and a guarded WHISPER adapter, explicitly armed with `/akart net start|listen`; no registration or traffic on load and no gameplay replication.
- Cap DATA at 4/s, 120 seconds / 480 sequences, exact 16/64/128/220-byte payloads; ACK-once16bytes with 4-token/4-per-second burst guard, no retries or catch-up bursts. Anchor deadlines/drains across client hitches and stop on unknown/failed/throttled sends, malformed floods and lifecycle/clock errors.
- Add explicit counters/nearest-rank timing summaries and four bounded DATA/ACK sequence maps for reconciliation. Local enqueue acceptance and missing ACKs do not establish delivery/loss. No SavedVariables/CSV export or peer identities in output.
- Reuse the existing bootstrap event frame and preserve the 9/113/13 UI pool and all vehicle/race/render behavior. Real API calls, two-client measurements, PARTY/bidirectional/scale/reconnect gates and replication architecture remain NOT RUN.

## Unreleased — Test Oval swept solids and multiplayer priority (2026-10-20)
- Add two geometry-backed red solid-barrier fixtures to Test Oval only; Mirage gains no obstacles. Sweep whole movement segments with conservative 18-unit clearance, bounded recovery and sliding; retain the existing once-per-step wall scrub/cancel response.
- Physics compatibility v7 and Oval geometry v2; fifteen state fields, handling constants, input/race/clock logic and Mirage geometry remain unchanged.
- Pool two additional Texture regions at creation, hidden on Mirage: current explicit counts 9 frames/113 textures/13 font strings. No per-tick UI creation or asset loads. Client appearance/feel remains NOT RUN.
- Record multiplayer ahead of dedicated ghosts/time trials and the owner's release target of verified multiplayer, three ready maps and eight ready karts. Keep actual-client transport gates and explicit release authorization.

## Unreleased — Goblin Mortar Trike kart (2026-10-20, `claude/track-ui`)
- Make the Warcraft III Goblin Mortar Trike (erwtenpeller and Chriz, Vast Graphics) the default kart, at the owner's request. The new `scripts/build_wc3_kart.py` reads the published MDX model and paletted BLP texture with the standard library. It poses the Stand frame and renders 64 three-quarter-view headings into a 1024×1024 sheet, lit and shadowed like the Mirage scenery. The mesh and texture are not edited, and output bytes are identical on Python 3.10 and 3.13.
- `Presentation.KART_SPRITES` gains optional directional-sheet fields (`frames`, `columns`, `pivotX`, `pivotY`) plus `Presentation.kartFrame` and `Presentation.kartFrameCoords`.
- UI shows the nearest heading unrotated, rewrites the crop only when the frame changes, anchors by the pivot, and keeps the primitive if `SetTexture`, `SetTexCoord` or `SetVertexColor` refuse at load. The Goblin Drag Car stays registered as a single-image kart with the rotated path.
- Physics, race, input, capture and UI object counts (9/111/13) are unchanged; the kart texture grows to 4 MiB of raw pixels. Lua tests cover the sheet layout, nearest-frame lookup, refused crops, pivot anchoring and simulation equivalence.
- Credits are in the addon README and `docs/art/karts/goblin-mortar-trike.md`. The archive's Read Me asks for permission before modification, and the owner says it is outdated; redistribution stays unresolved for release review. The owner approved the trike as installed; no Print Probe or timing figures were recorded (`docs/evidence/2026-10-20-trike-and-shadows-owner-approval.md`).

## Unreleased — Mirage scenery shadows (2026-10-20, `claude/track-ui`)
- Replace the scenery's offset-copy shadows, which the owner's in-game screenshot showed as detached gray shapes, with attached soft shadows. Objects are described by convex volumes with real heights. Each shadow is their convex hull projected away from the north-west light, so it touches the object's base. Raised parts (banner cloth, crane boom, fuel drum, rotor) cast lifted shadows joined to the ground by their poles, legs or cable.
- Shadows multiply the painted color toward a cool tint, with a contact rim and a widening, fading penumbra; overlaps combine by maximum instead of stacking. `paintkit.Shadow` and `Canvas.cast` implement this, and the kart output stays byte-identical.
- Banners become swallowtail flags with trim stripes, and oil stains become crisp lobed splats instead of gray blobs. The build still fails if scenery or shadow touches a road texel; registration, contrast and landmark checks are unchanged.
- Same path, size and format; UI code and counts unchanged. The owner's screenshot of the previous build is recorded in `docs/evidence/2026-10-20-mirage-scenery-owner-check.md`, and his approval of the shadow pass in `docs/evidence/2026-10-20-trike-and-shadows-owner-approval.md`.

## Unreleased — Mirage scenery v1 (2026-10-20, `claude/track-ui`)
- Repaint `Assets/Tracks/SaltFlats/Background.tga` from flat blockout art into original procedural scenery at the same path, size and format. It shows crusted salt flats and a packed-dirt lane with tire streaks, berms, red/cream apex kerbs and start/finish checkers. Set pieces include the goblin pit and gnome camp, a timing tower, bleachers, tents, wrecks, a kodo skeleton and a boulder rim.
- Road and salt still come from the Lua `isDrivable` predicate at each pixel center. The build fails if scenery touches a road texel, and objects keep 20 units off the road. A contrast check requires a light salt rim around the darker lane, and ten landmarks verify orientation.
- Add `scripts/paintkit.py`, shared by both generators; the kart generator now uses it with byte-identical output. Add review PNGs under `docs/art/` and an independent background check in `tests/test_presentation.lua`.
- Geometry, physics, UI code, TOCs and simulation tests are unchanged. Explicit UI counts stay 9/111/13 and the raw texture payload stays 4 MiB. Client appearance is NOT RUN; see `docs/art/mirage-background.md`.

## Unreleased — first Goblin Drag Car sprite (2026-10-20, `claude/track-ui`)
- Add an original strict-overhead, north-facing goblin dragster. The runtime file `Assets/Karts/GoblinDragCar.tga` is a 64×128 straight-alpha TGA, 32,786 bytes, bottom-left origin. It shows a long red nose, a big-eared goblin pilot, explosive canisters, an oversized supercharged engine, huge slicks and a rocket bell.
- The sprite is drawn as a 20×40 world-unit quad whose visible body stays inside the existing 17×31 footprint. Transparent padding has bled edge colors.
- The new standard-library `scripts/build_kart_sprites.py` paints the sprite deterministically. `--check` verifies exact bytes, footprint, pivot, facing and edge invariants; `--preview` writes a PNG master and an in-context review sheet under `docs/art/karts/`.
- Register sprite metadata in `Presentation.KART_SPRITES`. UI loads the sprite once at creation behind a guarded `SetTexture`, then tints drift/boost phases with `SetVertexColor` instead of `SetColorTexture`, which would have replaced the image. Any refused load keeps the original primitive and its colors.
- Physics, input, race, camera and capture code are unchanged, and explicit UI counts stay 9/111/13. Offline tests cover the asset bytes, sprite/fallback rendering, and identical simulation state across a scripted Mirage drive in both modes. Client appearance is NOT RUN; see `docs/handoffs/claude-latest.md`.

## Unreleased — closer Mirage follow camera (2026-10-20)
- Replace Mirage's distant whole-map presentation with a north-up follow camera at scale 1.5. A cropped background fills the existing 800×480 canvas, with 60 world units of heading look-ahead and a view clamped to map bounds. The placeholder kart grows from about 8×14.5 to 25.5×46.5 canvas units; the road grows from 52.5 to 168 wide.
- Keep art, kart, gates and walls in one uniform transform, clipping pooled gate/wall strips to the visible canvas. The camera follows the interpolated pose and freezes at the exact stopped pose; no simulation, geometry or Physics v6 change is introduced.
- Preserve Test Oval's fixed overview and the existing 9 frames/111 textures/13 font strings. Painterly scenery and the first drag-car sprite remain subsequent work.
- Record the owner's screenshot as evidence of the earlier opaque Mirage TGA loading and whole-map orientation. A separate stopped build-70450 check confirmed the close crop, larger kart, Start alignment and West-strip clipping, with 9/111/13 counts and zero drive ticks. Camera motion/edges, handling and sustained performance remain NOT RUN; exact focused checks and installation belong in PROGRESS.

## Unreleased — gentler drift and retained steering corrections (2026-10-20)
- Tune Physics v6 for the owner's Test Oval feedback: drift yaw is 0.75 of normal yaw instead of 1.15; charge tiers take 30/60 valid ticks (0.5/1 second), while ordinary steering and boost duration stay unchanged.
- Hold Space through up to twelve steering-correction ticks (0.2 seconds) to retain charge without adding more. Matching steering resumes charging in either direction; the thirteenth unqualified tick clears it. A valid road/speed release can spend a retained tier during that pause; brake, low speed, rough ground and walls still cancel immediately.
- Add a correction-pause text cue using the existing meter/HUD. The deterministic state adds `driftGraceTicks`; no input binding, UI allocation, track geometry, countdown or race-result change is introduced.
- Focused regression coverage accompanies the change; exact executed results and installation belong in PROGRESS. Version-6 client feel remains NOT RUN and M1 acceptance stays open.

## Unreleased — selectable playable Mirage blockout (2026-10-20)
- Add one original 1024×1024 salt-flat TGA sampled from actual Lua road geometry, plus a deterministic exporter and format/alignment check. No third-party imagery or model is imported.
- Add a stopped-state Track button for Test Oval/Mirage Raceway. Load the background once on deliberate selection, retain the working oval and stopped result if loading fails, and reuse all textures on later switches. A click releasing driving controls cannot also change the track.
- Project background, kart, gates and perimeter dimensions uniformly into the existing canvas. Mirage labels rough ground as salt; physics v5, countdown, drift and three-lap results are preserved. Successful map changes start a fresh ready state; selection is not persisted.
- Explicit UI allocations become 9 frames/111 textures/13 font strings. Focused Lua 5.1 mapping/lifecycle checks and exporter checks passed; actual client texture appearance/handling remain NOT RUN. M0/M1/M3 acceptance remains open.

## Unreleased — Mirage geometry blockout and layout guide (2026-10-20)
- Add a pure MirageRaceway factory with explicit crossing dependency, 1024-square bounds, a closed 16-vertex centerline and 112-wide capsule-union road, perimeter walls, spawn and four directional gates. Rough salt reuses grass behavior; physics stays v5.
- Add uniform Presentation viewport projection/unprojection. The 1024-square world fits 800×480 at scale 0.46875, offset (160,0); future rendering must scale both positions and dimensions.
- Generate JSON/SVG authoring guides from the actual Lua factory and viewport helpers, with the same unsmoothed round road stroke and one Y inversion. This is a blockout/guide, not playable Mirage or a loaded background.
- Bundle the factory after Track (12 Lua modules/15 addon source files); UI remains Test Oval with unchanged 8/110/13 allocations, countdown and finish flow. No selector, TGA, new vehicle art or client API is added. Focused geometry/presentation/UI checks accompany the slice; exact executed results and installation belong in PROGRESS. Client custom-texture/viewport checks remain NOT RUN, with M0/M1/M3 acceptance open.

## Unreleased — Mirage Raceway asset research and art direction (2026-10-20)
- Set Mirage Raceway on the dry Shimmering Flats as the first production-map target, replacing the proposed Tinker Speedway, with recognizable fantasy siege/steam tanks, trike, aircraft, gryphon rider and Mirage drag cars.
- Record concrete WC3Vault candidates, author/permission gaps, OpenRealm/viewer tooling and explicitly licensed fallback art. No third-party archives were imported; tool licenses are distinguished from model/texture rights.
- Add a generated concept board, exact prompts and PNG hash/provenance manifest outside the addon. Document precomposed track layers, separate simulation geometry, bounded sprite pools, camera/facing requirements and export/viewport checks still pending.
- Planning/artifacts only: Test Oval runtime, installed files and milestone acceptance are unchanged. No runtime TGA, asset loader, geometry migration or new selectable roster is claimed.

## Unreleased — best completed lap within a run (2026-10-20)
- Track the fastest accepted completed lap and its lap number in pure Laps. Fields start empty; strictly shorter integer durations replace the best, while ties retain the earliest lap. Incomplete/current laps never become the best.
- Append best time/lap number to the existing lap HUD and all terminal summaries. Retain it through Stop/combat/reopen/rejected Start; successful fresh Start/Restart and GO reset it. This is in-memory per run, with no saved personal record, schema change or migration.
- Grow the existing summary to 380×190 for its third text line. Counts remain 8/110/13 in the same 856×762 window, with unchanged physics v5, countdown and three-lap finish; no new UI objects, APIs, settings or networking.
- Focused Laps/Race/UI coverage accompanies the slice; exact executed results belong in PROGRESS. Current client layout/handling remains NOT RUN, and M0/M1/M3 acceptance stays open.

## Unreleased — fixed-tick start countdown (2026-10-20)
- Start each three-lap solo run with 180 fixed ticks of 3–2–1 and a GO cue. The kart stays at spawn with neutral physics input while actual held controls are sampled; GO resets the Race/Laps timing origin, and driving begins on the following tick.
- Race/lap time excludes countdown, dropped time and stopped time; physics/loop/probe ticks include countdown. Dropped hitch ticks can extend countdown wall time without skipping it. GO remains visible for the first 60 racing ticks.
- Stop/focus loss/combat cancels countdown with zero race elapsed time and retains the frozen result; a deliberate successful Restart begins a fresh countdown. One pooled center font string brings explicit allocations to 8/110/13 in the unchanged 856×762 window; physics stays v5 and exact three-lap finishing is unchanged.
- Focused Race/UI coverage accompanies the slice; exact executed results belong in PROGRESS. Countdown appearance/handling and other client checks remain NOT RUN; M0/M1/M3 acceptance stays open. No persistence, best record, ghosts or networking is added.

## Unreleased — three-lap solo finish (2026-10-20)
- Add a pure Race wrapper around Laps with running, finished, stopped and interrupted outcomes, fixed three-lap completion and integer total ticks. Terminal state is retained unchanged; no repeated finish or post-finish simulation is accepted.
- Stop catch-up after the counted finish step, account for unexecuted whole ticks as dropped time and retain the fractional clock remainder. An ordinary early finish does not manufacture a hitch frame.
- Add a pooled result summary and deliberate Restart flow. Successful completion shows total/last-lap times; early Stop or combat retains actual partial progress. Stop/reopen preserves the result, while a successful fresh Start clears it. Current explicit allocations are 8 frames/110 textures/12 font strings in the same 856×762 window; physics remains v5.
- No countdown, persistence, best record, ghosts, remote standings or multiplayer is added. Focused Race/Loop/UI coverage accompanies the slice; exact executed results and installation status belong in PROGRESS. Client finish/restart driving and appearance remain NOT RUN; M0/M1/M3 acceptance stays open.

## Unreleased — repeatable practice laps (2026-10-19)
- Add a pure Laps module around ordered checkpoints. Each accepted North → West → South → Start circuit increments completed laps once and rearms the next circuit at the finish tick. Duplicate, older and gapped tick reports cannot award or advance time; consecutive malformed or oversized movements advance practice time without a gate award.
- Show completed laps, current lap time and the last completed time from integer 60 Hz simulation ticks. The first lap includes acceleration from Start Test Drive; Stop, combat interruption and normal reopen freeze the sample, while a fresh Start resets it. One pooled lap font string brings explicit objects to 6 frames/110 textures/9 font strings in an 856×762 window; physics remains version 5.
- No countdown, fixed race length, winner, best record, persistence or multiplayer is added. These local consistency checks do not prove competitive route validity. Focused checkpoint/lap/UI coverage accompanies the slice; exact executed results and installation status belong in PROGRESS. Client lap driving/layout and broader checks remain NOT RUN unless recorded there.

## Unreleased — ordered directional checkpoints (2026-10-19)
- Add four finite directional gates on the test oval and a pure fixed-tick checkpoint module. Only the next gate can advance; backwards crossings, departures from the gate line, stale/duplicate ticks, missing steps and oversized movements do not award progress. A completed 4/4 sequence stays terminal until a fresh Start.
- Integrate actual simulation positions after physics, with pooled next/passed gate strips and a named checkpoint HUD. Correct the right-hand start stripe to cross the road horizontally. Stop/reopen freezes progress; Start resets it. Explicit objects are now 6 frames/110 textures/8 font strings in an 856×734 window; physics stays version 5.
- This is solo checkpoint groundwork, with no lap count, timer, win result or security guarantee. Focused track/checkpoint/UI coverage accompanies it; exact executed results and installation status belong in PROGRESS. Client appearance and driving remain NOT RUN; broader checks stay deferred under ADR 0007.

## Unreleased — progressive keyboard steering (2026-10-19)
- Physics version 5 adds bounded steering buildup, faster centering on release and a center-first direction reversal. Both directions cancel immediately; reverse yaw still flips, wall contact clears steering and grass preserves it for recovery.
- Keep drift cancellation tied to raw turn input; a new drift waits until progressive steering agrees with that turn. Input capture, bindings, meter/interpolation and the 6/107/7 UI budget are unchanged.
- Focused steering, drift, surface and UI coverage accompanies this slice; exact executed results and installation status belong in PROGRESS. Client handling is NOT RUN; broader checks remain deferred under ADR 0007.

## Unreleased — drift charge and boost meter (2026-10-19)
- Add a 300×12 pooled meter with Tier 1/Tier 2 markers, named charge/ready phases and remaining-boost feedback on one shared 0.8-second scale. Pure Presentation mapping reads actual charge/boost ticks without changing physics version 4.
- Cache phase and fill setters; empty fill is hidden, Stop freezes the last drive and Start clears it. Four textures and three font strings bring explicit allocations to 6 frames/107 textures/7 font strings in an 856×706 window.
- Focused presentation/UI coverage accompanies this slice; exact executed results and install status belong in PROGRESS. Client reload and meter appearance are NOT RUN; broader checks remain deferred under ADR 0007.

## Unreleased — interpolated kart presentation (2026-10-19)
- Blend previous/current simulation positions and shortest-arc heading using the fixed-step clock remainder, including render frames with no simulation step. A pure Presentation module returns scalar coordinates; displayed poses never feed back into physics, which remains version 4.
- Start/Create and Stop show the exact current pose; stopped updates and reopening retain it. Active interpolation adds at most one fixed step of visual delay. The 6 frames/103 textures/4 font strings budget is unchanged.
- Focused presentation/UI coverage accompanies this slice; exact executed results and installation status belong in PROGRESS. In-game appearance and handling are NOT RUN; broader checks remain deferred under ADR 0007.

## Unreleased — grass slowdown and perimeter walls (2026-10-19)
- Physics version 4 separates the road mask from traversable grass and solid perimeter bounds. Grass gradually reduces excess speed toward 70 forward/30 reverse and clears drift, boost and slip; road re-entry restores normal handling.
- Clamp attempted movement at an 18-unit canvas inset, preserving tangent motion and scrubbing speed once per contact step, including corners. Add four pooled perimeter textures and reuse the drift HUD for Road/Grass/Wall feedback; explicit counts are now 6 frames/103 textures/4 font strings.
- Focused coverage accompanies surface/collision and UI changes; exact executed results and install status are recorded in PROGRESS. Client reload, layout and handling are NOT RUN. Broader checks remain deferred under ADR 0007; M0/M1 acceptance remains open.

## Unreleased — local drift charge and boost (2026-10-19)
- Physics version 3 adds Space-held drift with bounded signed slip, two fixed-tick charge tiers and a release boost. Brake, steering loss/opposition, low speed and collision cancel the charge; brake/collision cancel an active boost.
- Add a separate pooled drift HUD and phase-cached kart colors for charge, ready tiers and boost. The window is 856×670; the explicit budget is now 6 frames/99 textures/4 font strings. Stop retains `Last drive` feedback; a fresh Start resets it.
- Focused Lua 5.1 physics/input/UI and separate drift checks passed. Installed Input/Physics/UI with a verified prior-addon backup and ten matching source hashes; no client reload or handling check performed.
- Adopt the owner's build-first priority: focused checks for changed mechanics, with long client/scale/profile matrices deferred. M0 stays open; human drift handling, new-layout client verification and this slice's full dual-runtime suite are NOT RUN. Exact commands/results are in PROGRESS.

## Unreleased — explicit road draw order and seam fix (2026-10-19)
- Put the canvas grass below the outer road bands and disable sharpening/pixel snapping only for the 96 bands during creation. Geometry, physics, input and the 6/99/3 object budget are unchanged.
- Isolated live checks showed grass occlusion; a clean reload then verified the permanent fix, all 96 band settings and unchanged grass snapping at effective scale 0.72452831268311. Other-scale and sustained-performance acceptance remain pending.
- Lua 5.1/5.4 regression coverage includes draw priority, creation-only settings, missing/throwing optional APIs and no reconfiguration on update/reopen. Installed UI.lua with verified prior backup and ten matching source hashes.

## Unreleased — stationary client evidence and renderer review (2026-10-19)
- Recorded 600 valid stationary profiler samples on build 70450: scoped total average 0.0264 ms, maximum 0.2111 ms, including probe overhead; stopped/reopened/disarmed results retained. This is partial M0 evidence, not sustained driving or exclusive CPU cost.
- Observed road-band seams. Both creation-time snapping experiments hid the road after reload despite passing mock tests; removed the experiments and restored/verified the prior source and visible road. Rendering API behavior is flagged for review; no snapping change is retained.

## Unreleased — optional bounded performance probe (2026-10-19)
- `/akart perf on` arms up to 600 active updates on the next Start; `/akart perf` prints simulation/render-HUD averages and maxima in scoped elapsed milliseconds; `/akart perf off` disables collection. Default off, aggregate-only, no extra UI objects or per-frame chat.
- Missing/invalid/reset/erroring clock readings consume the cap without changing driving. Never reset the shared profiler timer; output includes probe overhead and is not exclusive CPU/GPU attribution.
- Pure aggregation and UI integration checks pass in Lua 5.1/5.4; synchronized TOCs load Performance before UI. Installed with verified backup/ten hashes; the later stationary client result is recorded above.

## Unreleased — align the primitive road with collision (2026-10-19)
- Draw the outer road and inner island from the analytical Track bounds, replacing the mismatched centerline tiles. Physics and steering are unchanged.
- Reuse the 96-road-texture budget with static ellipse bands; regression checks compare the painted footprint with collision geometry and retain allocation/determinism coverage.

## Unreleased — stopped-window combat closure (2026-10-19)
- Handle combat onset even after a test drive has stopped; hide the open window without changing its completed timing/result or announcing another interruption.
- Lua 5.1/5.4 regressions cover pre-Start/stopped/interrupted windows, duplicate events, preserved samples and no automatic resume. Installed with a verified backup and loaded; actual combat verification remains deferred.
- Record two human near-minute driving samples with matching stopped HUD, no dropped simulation time and stable explicit UI counts; full M0 acceptance remains open.

## Unreleased — retained interruption note (2026-10-19)
- Keep the combat interruption note through repeated closes/reopens and rejected Start attempts; display the refusal alongside the note.
- Regression coverage checks frozen results/timing, no duplicate notification or resume, and clean reset on a successful fresh Start. Source-only; extended client check remains pending.

## Unreleased — repeatable developer installs (2026-10-19)
- Local install helper copies files directly into the addon target, requires explicit overwrite, and supports `-WhatIf` previews.
- Verifies prior-file backups and installed SHA-256 values, preserves unknown extra files, and records copy/verification failures without automatic rollback.
- Workspace fixture suite covers install, cancellation and failure paths; no installed addon changed by this tooling work.

## Unreleased — M0 timing sample evidence (2026-10-19)
- Probe reports cumulative active frame time, executed simulation time and callback cadence; stopped samples retain their timing remainder.
- Start and Stop immediately refresh the HUD, fixing the observed stale stopped tick display.
- Offline 60-second schedule, hitch accounting and frozen-sample regressions; manual client samples remain pending. Source-only update, not installed or released.

## Unreleased — M0 probe hardening (2026-10-18)
- Combat now closes the window and records one retained interruption result/note; future races will freeze actual standings when implemented.
- Local developer install verified by SHA-256; live build/interface/Camelot discovery, basic rendering and idle release checks observed. Full manual acceptance remains pending.
- Corrected left/right steering; physics compatibility version 2.
- Pure input sampling and bounded fixed-step clock with measured dropped time.
- Focus/lifecycle stops, guarded combat propagation and explicit probe diagnostics.
- Lua 5.1/5.4 tests, deterministic replay, analytical handling and mocked UI lifecycle checks.
- Installed-client probe matrix and unmeasured network experiment ledger; M0 client acceptance remains pending.

## 0.0.1 — project starter (2026-10-18)
- Technical plan, agent prompts and acceptance-gated roadmap.
- Small local top-down driving probe; pending actual Lua + WoW validation.
- Offline verification scripts and manual test checklists.
- No public multiplayer or finished racing claimed.
