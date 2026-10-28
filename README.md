# Azeroth Kart — top-down arcade racing inside WoW Forever

**Alterac Valley:** a long one-run sprint from Frostwolf to Dun Baldar,
available solo and in the existing two-player lobby. The Field of Strife’s
ice reduces steering, acceleration, braking and traction; normal grip returns
gradually after leaving it. Wide packed snow retains full grip, deeper snow
slows the kart. Both players need this build and a full client restart for
the new scenery. [Current status](docs/INTEGRATION_STATUS.md).

**Arathi Basin v3:** available in solo and the existing two-player lobby. Former
fence stretches open onto slow grass with natural boundaries; the
Stables grass shortcut slows unboosted karts; an active boost maintains up to
the kart’s normal road speed. It uses flat Physics14 and its own score context;
terrain relief is visual. Both players need this build and a full client restart.
[Current status](docs/INTEGRATION_STATUS.md).


**Warsong v3, 2026-10-28:** both bases run up the outside ramp, through the
lobby and flag room, then down the tunnel. Reviewed Claude5cee515 adds the
raised Horde base, descent-aware cover fades and clearance around the guiding
arrow. Solo and existing two-player races remain enabled. V3 has its own score
context; v1/v2 records remain saved. Fully restart both clients after updating.
Native checks remain pending; [current deployment](docs/INTEGRATION_STATUS.md).


**Warsong prerequisite,2026-10-27:** opt-in two-floor/ramp driving, floor-aware
collision/checkpoints and once-per-pass boost pads are implemented/offline-tested.
Current eleven maps and their Physics12 score contexts remain unchanged.
Claude's reviewed Warsong layout/art/roofs are integrated: a three-lap
two-floor course, available solo and in the two-peer lobby. Warsong uses
Physics13; existing boards remain Physics12. Automatic score sharing uses
AZKSCR2; both players must update. Full restart required for new files.
[Authoring contract](docs/LAYERED_TRACKS.md), [score compatibility](docs/AUTOMATIC_SCORES.md).

**Current multiplayer source,2026-10-27:** all twelve finished courses enter
the two-peer lobby, including four one-run Scarlet sprints. Invite/clock/live
finish/rematch validation preserves each course's actual target; Test Oval
stays retired. Remote x/y correction now reconciles packet changes using the
copied clock and geometry, preserving the existing network budget. Focused
offline checks pass; actual friend-kart smoothness/new sprint play remain
pending. This supersedes the dated solo-only Scarlet notes below.
[Current scope/versions](docs/PRODUCTION_MAPS.md), [short check](docs/MULTIPLAYER_PLAYTEST.md).

**Scarlet integration (2026-10-26):** `codex/scarlet-integration` combines the
reviewed Library, Armory, Cathedral and drive fixes with Codex's current build.
There are eleven solo courses and seven experimental two-player lap circuits;
the four Scarlet sprints stay solo. Swept round-pool collision and L/A/C score
sharing preserve Test Oval's retirement and existing traffic limits. Native
checks for the new courses remain pending. [Current catalogue](docs/PRODUCTION_MAPS.md).

Multiplayer source follow-up: bounded transit-aware opponent prediction removes a measured freeze between healthy updates and improves steady-turn direction. Existing two-player whispers keep the same traffic budget. [A finite group-delivery check](docs/GROUP_DELIVERY.md) prepares the eight-racer transport gate; native delivery/feel and eight-player support remain unverified.

Current handling (2026-10-25): [balanced, heavy and agile kart profiles](docs/adr/0019-balanced-kart-handling.md).
Physics12 widens cruising-speed differences to±4% and launch/turning to±8%.
Charged boosts last0.8/1.3seconds with stronger acceleration; a repeatable clean
oval fixture measures4.91% quicker three-lap driving with drift. Charging resumes
after a boost ends. This measured fixture is not universal competitive balance.
The kart picker explains the selected profile; the choice is fixed for each
solo/live run. Physics12 keeps one shared leaderboard across karts and retains
historical scores. Offline handling/replay/integration checks pass; native feel
and competitive lap balance remain pending. No collision mass is implemented.

Leaderboard development (2026-10-25): [automatic addon-only community sharing](docs/adr/0018-automatic-community-scores.md),
with prompt result updates, automatic catch-up and top-3/top-10 notices.
[Automatic discovery, whisper delivery, saved catch-up and visible notices](docs/AUTOMATIC_SCORES.md)
are integrated in source. Native roster/delivery verification is pending; the
board shows its connection status and best-known cached ranks. The disconnected
Python store is retained but deferred. Full restart is required after updating.


**Latest source (2026-10-25):** eight finished maps are available in solo; the seven lap circuits support the existing two-player mode; Test Oval is retired from the game. Mirage is the default. Physics12 handling is unchanged and the owner reports it feels good. Eight-player support remains in development; a raid-group requirement is undecided. [Map catalogue and transport scope](docs/PRODUCTION_MAPS.md). See PROGRESS for exact source/deployment and pending checks.
**Status:** M2 experimental two-player control foundation after measured traffic and addon reload recovery; M0/M1 and live-racing acceptance stay open. The owner requested build-first work with focused validation ([ADR 0007](docs/adr/0007-build-first-development.md)).

**Release priority:** verified multiplayer precedes dedicated ghosts/time trials. The release target combines Codex's mechanical/race/network work through multiplayer with Claude's three ready maps and eight ready karts. Transport feasibility remains required; eight karts does not specify simultaneous player count. See [ADR 0010](docs/adr/0010-multiplayer-release-priority.md).

**Current source checkpoint (2026-10-25):** the reviewed combined source includes ten karts and eight production tracks: Mirage Raceway, Stormwind, Ironforge, Darnassus, Orgrimmar, Thunder Bluff, Undercity and the Scarlet Graveyard sprint. City geometry, full-speed Stormwind shoulders and the owner-confirmed corner correction are retained. The existing two-peer multiplayer flow accepts all seven lap maps; city multiplayer is offline-tested, with native play pending. Reviewed Claude9143949 adds Darnassus and Undercity with painted elevation; handling remains flat and native city checks are pending. Exact deployment and pending native checks are in [PROGRESS](docs/PROGRESS.md).

**Transport evidence:** the connection test accepts Forever full first names and surnames using the logged-message route ([ADR 0012](docs/adr/0012-forever-logged-transport.md)). `/akart net help` and [the guide](docs/NETWORK_QUICK_START.md) describe the opt-in test; Print Probe is driving statistics. [AKT722](docs/evidence/2026-10-21-akt722-network-window.md) and reverse [AKT723](docs/evidence/2026-10-21-akt723-network-window.md) are actual two-client windows. AKT723 delivered/acknowledged 240 of 240 attempts at 2 DATA/s with 128-byte DATA, zero reported throttles/errors/timeouts and p95 RTT 771 ms, across owner-reported different zones without a group. Full socket recovery, live racing and production capacity remain unverified.

**Networking implementation:** recorded [transport/reload windows](docs/evidence/2026-10-21-akt724-akt725-recovery.md), bounded control/start-clock APIs and the live controller feed the explicit Multiplayer menu. The first owner-reported race completed local laps on both clients, with countdown/sprite/delay problems; the revision below addresses those in source. No standalone net probe is required for this test. Shared results authority, contact, full socket recovery and production acceptance remain open.

**Latest experimental multiplayer candidate (2026-10-23):** `codex/multiplayer-grid` follows the [first completed two-client local race](docs/evidence/2026-10-23-first-live-race.md). It adds both chosen karts on a shared starting grid, full3–2–1–GO and timestamp-aware bounded remote prediction/off-screen direction. [Simple two-player steps](docs/MULTIPLAYER_PLAYTEST.md). Both clients must update and fully restart (new module/protocol); revised behavior is offline-tested, native verification pending. All seven lap maps now negotiate through this two-player flow; no kart contact or agreed winner.

**Development handoff:** Codex owns simulation/race/networking; Claude owns rendering/UI/assets. Start from [shared ownership and workflow rules](AGENTS.md), [implemented API contracts](docs/API_CONTRACTS.md) and [the latest Codex handoff](docs/handoffs/codex-latest.md). `CLAUDE.md` imports the shared rules. Separate feature worktrees and reviewed integration are required. [Current integration status](docs/INTEGRATION_STATUS.md) identifies the combined source and deployment owner; do not install one agent's older branch over the shared client.
**Vision:** A polished, responsive top-down 2D kart racer wholly inside a movable World of Warcraft addon window, inspired by approachable arcade racing, with original presentation and Warcraft-flavored humor.

**Capital Cities Cup (integrated developer source):** [Stormwind City Circuit](docs/art/tracks/stormwind.md) races through Stormwind's real streets from the Valley of Heroes, along the canals past Old Town, the Dwarven District, Cathedral Square, the Park and the Mage Quarter, drawn from Warcraft III art; [Ironforge Grand Prix](docs/art/tracks/ironforge.md) runs from the Gates round the Commons, the Mystic Ward, the Forlorn Cavern and the Hall of Explorers, through the Great Forge, past Tinker Town and through the Military Ward; [Orgrimmar Canyon Rush](docs/art/tracks/orgrimmar.md) starts on the canyon road behind the city gate and laps the Cleft of Shadow through the Valley of Strength, the Drag and past Grommash Hold; [Darnassus Canopy Run](docs/art/tracks/darnassus.md) starts on the Warrior's Terrace and laps the terraces, the Temple Gardens' lake and the Temple of the Moon; [Undercity Slime Circuit](docs/art/tracks/undercity.md) starts by the slime below the Apothecarium and laps the canal ring, over a bridge at every section (version 2, proposed on `claude/undercity-river`). Darnassus and Undercity are the first maps painted on several levels ([ADR 0015](docs/adr/0015-track-elevation.md)). [Thunder Bluff Skyway](docs/art/tracks/thunder-bluff.md) starts at the foot of the Lower Rise's west side, where the road from the lift joins (version 2, proposed on `claude/drive-fixes`), and laps the Lower Rise, out to the Spirit, Elder and Hunter Rises over six narrow rope bridges high over Mulgore (proposed on `claude/thunder-bluff`). Their client checks are pending.

**Scarlet Crusade Cup (proposed on `claude/scarlet-graveyard`):** dungeon sprints, one run from the start of a Scarlet Monastery wing to its end, with no road to follow ([ADR 0020](docs/adr/0020-dungeon-sprints.md), for Codex's review). [Scarlet Graveyard](docs/art/tracks/scarlet-graveyard.md), the first, runs from the instance portal up the hall, through the Chamber of Atonement and down into the Forlorn Cloister's graveyard, to Honor's Tomb. Grass slows the karts and graves block them. [Scarlet Library](docs/art/tracks/scarlet-library.md) (proposed on `claude/scarlet-library`) runs from the portal down the long hall, round the Huntsman's Cloister and its open courtyard, in and back out of Houndmaster Loksey's kennel, up through the Gallery of Treasures and the Athenaeum to Arcanist Doan's round library. [Scarlet Armory](docs/art/tracks/scarlet-armory.md) (proposed on `claude/scarlet-armory`) runs from the portal across the Training Grounds, the wing's one open yard, up through the Footman's and the Crusader's Armories and along the long hall into the round Hall of Champions, down its stairs to Herod. [Scarlet Cathedral](docs/art/tracks/scarlet-cathedral.md) (proposed on `claude/scarlet-cathedral`), the last, runs from the portal through the Chapel Gardens, round their pools and up beside the falls, then up the cathedral's nave to the altar, where Mograine and Whitemane stand. Client checks are pending.

**First production map:** Mirage Raceway on the dry Shimmering Flats. Its selectable blockout uses one original precomposed salt-flat background, painted as [scenery v1](docs/art/mirage-background.md) with both engineering camps, and a closer north-up camera that follows the kart, drawn by default as the [Goblin Mortar Trike](docs/art/karts/goblin-mortar-trike.md) rendered from a Warcraft III model by erwtenpeller and Chriz. While stopped, a Kart button also offers a Steam Tank, Dwarven Biker, Gryphon Rider and Gyrocopter rendered from Warcraft III models of the wc3c ITE project, Warcraft III's own Dwarf Car, Orc Demolisher, Meat Wagon and Glaive Thrower, and the [Goblin Pod Racer](docs/art/karts/goblin-pod-racer.md), World of Warcraft's own Mirage Raceway rocket car, which replaced the original drag car on 2026-10-23 ([roster](docs/art/karts/roster.md)). Settings can draw a bright [outline](docs/art/karts/outlines.md) round your own kart. The [map/vehicle brief](docs/art/MIRAGE_RACEWAY.md), [asset-source shortlist](docs/art/ASSET_SOURCES.md) and [concept board](docs/art/concepts/mirage-raceway-direction-v1.png) record the intended Warcraft III-like machines and scenery. Props, further effects and the remaining karts follow separately; the [layout guide](docs/art/mirage-layout.svg) shows the whole road, gates and spawn for authoring.

**Current single-player slice:** completed solo races save the full three-lap
total, full Forever name and finish date in **Main Menu → Highscores**, keeping
each player's best compatible total. This is a local saved board; global
publication is pending a supported shared route. Source is offline-tested;
new native name/date/persistence and appearance checks are NOT RUN. See
[Highscores and the global dependency](docs/HIGHSCORES.md).

## Start here (for a human)
1. Read `docs/VISION.md`, `docs/FEASIBILITY.md` and `docs/ROADMAP.md`.
2. Open this folder as the Codex workspace. Paste `PROMPT_01_MASTER.md` into Codex. Keep `AGENTS.md` in the repository root.
3. `addon/AzerothKart/` is the addon folder to copy into the Forever `Interface/AddOns/` folder. Verify client flavor and TOC in `docs/CLIENT_API.md` first. The [developer install helper](docs/RELEASE.md#developer-install) supports a no-write preview, verified backups and repeat installs; use it only for an authorized deployment.
4. After an update, `/reload` (fully restart the client when the update adds files), then open `/akart` or `/azerothkart`. The main menu opens: choose **Single Player**, pick **Mirage Raceway** or the Capital Cities Cup's **Stormwind City Circuit**, **Ironforge Grand Prix** **Orgrimmar Canyon Rush**, **Darnassus Canopy Run** **Undercity Slime Circuit**, **Thunder Bluff Skyway** or the **Scarlet Graveyard** sprint, pick a kart, then deliberately click **Race!** ([front-end flow](docs/art/ui/front-end.md); its client appearance is NOT RUN). After **Close results**, the bar's **Track** button switches maps while stopped and **Start Race** begins again. The chosen track, kart and settings are remembered; Mirage is the default; retired saved Oval preferences fall back without deleting history. Changing maps clears the prior local run and timing sample; a failed texture load keeps the existing track and result. A 3–2–1 countdown holds the kart at spawn; held controls begin driving after GO. W/Up throttle, S/Down brake/reverse, A/D or Left/Right steer. Hold Space while turning on the road at speed 90+ to drift; Tier 1 takes 0.5 seconds of charging, Tier 2 takes 1 second. Drift steering turns more gently than ordinary steering. Brief steering corrections retain charge for up to 0.2 seconds without adding more; a valid opposite turn resumes it. Release Space on the road at speed 90+ without braking to spend a charged boost, including during that correction pause. The charge meter reaches Tier 1 halfway and Tier 2 when full, then shows remaining boost on a shared 1.3-second scale. Blue indicates charging, gold/pink a ready tier, cyan boosting; text labels name each phase and the surface. Grass (rough salt on Mirage) slows the kart and clears drift/boost; wall contact keeps useful sliding motion and held steering; blocked frontal impacts still stop, and parking turns are faster. Incidental mouse clicks and unassigned keys keep the run going; unassigned keys are consumed during capture. **Stop**, Escape or Close ends the run; Start/Restart begins a fresh one. Enter or Numpad Enter deliberately ends capture for chat. Actual text focus, an available application-focus loss check, hiding or leaving the world also stops capture. Combat closes the window and records an interruption. On build 70450, the observed application-focus getters are absent; held-key Alt-Tab behavior remains pending.
5. Record *actual* results of keyboard focus, rendering, frametimes, and combat interrupts in `docs/PROGRESS.md`. An addon loaded successfully does not establish multiplayer feasibility.
6. For the camera slice, use `python scripts/test_lua.py --runtime lua51 --tests presentation ui`; it parses all Lua and runs the selected checks. Use `python scripts/validate_project.py` for relevant structural changes. The full dual-runtime suite is reserved for a failure/risk or integration checkpoint. Install the pinned dependency with `python -m pip install --target local-artifacts/python-deps -r requirements-dev.txt`. See [the test plan](docs/TEST_PLAN.md) for broader checks.
7. After a stopped drive, run `/akart probe` (or click **Print Probe**, shown with Settings → **Show developer info**) to report frame/tick/drop counts, active frame duration, executed simulation duration, callback cadence and explicit UI object counts. Start/Stop refresh the HUD immediately; stopped timing metrics stay frozen until a new Start. Follow [the client checklist](tests/MANUAL_CLIENT_CHECKLIST.md); live tests and network measurements remain pending.
8. Optional profiling: while stopped, `/akart perf on` arms the next Start for up to 600 active updates. After stopping, `/akart perf` prints averages/maxima for simulation and render/HUD elapsed milliseconds; `/akart perf off` disables collection. It defaults off. These instrumented timer spans include probe overhead and are not exclusive CPU or GPU measurements; see [scope and manual checks](tests/MANUAL_CLIENT_CHECKLIST.md).

## Core commitments
- Multiplayer is part of the product vision but **must pass real-client network feasibility gates** before we claim a simultaneous eight-player racer is achievable.
- Pure Lua math and simulation are independent of WoW UI and network code.
- No protected-action automation, combat advantage, bypass of secret values, external control software, or in-game money/stakes.
- Solo mechanics support the multiplayer release target. If the real-client transport gate fails, review scope with the owner; ghosts/time trials are deferred, not an automatic release substitute.
- Original art and Warcraft III game/community assets are accepted sources under [ADR 0009](docs/adr/0009-warcraft-iii-asset-reuse.md), with per-file provenance, source terms and credits. Other commercial racing assets remain excluded. Warcraft fan-addon context does not imply affiliation or a general redistribution grant.
- No misleading "tested" claims. Tests must be recorded with evidence, client build, and environment.

## Repo layout

```
AzerothKart/
  AGENTS.md                       permanent Codex guardrails
  PROMPT_01_MASTER.md             initial master agent prompt
  PROMPT_02_SCHEDULED_CONTINUE.md automation resume prompt
  addon/AzerothKart/              actual WoW addon project
  docs/                           vision, feasibility, architecture, roadmaps, ADRs
  tests/                          pure-Lua tests and manual client checklists
  scripts/                        offline validation and installation scripts
```

## Important limitations of this starting package
The prototype includes fixed-step driving, three handling profiles, drift/boost, wall sliding, ordered three-lap races and automatic cached community highscores. Physics12 increases profile differences and charged boost payoff. A repeatable clean Test Oval fixture measures the reward; human balance still needs driving feedback. The owner reports the previous installed build tested well. Detailed native evidence, pending multiplayer/scale checks and historical results remain in `docs/PROGRESS.md` and `docs/FEASIBILITY.md`. No production multiplayer or release acceptance is implied.

The current candidate uses 86 explicit UI frames, 167 textures and 135 font strings in an 856×762 window, including the [front-end menus, race HUD and results dialog](docs/art/ui/front-end.md) and the Capital Cities Cup's track list and eight pooled gate strips (65/160/79 before the cup; 11/151/13 for the window without the menus). They include the stopped-only [Kart button](docs/art/karts/roster.md#kart-button) and 38 pooled [drift and boost effect](docs/art/effects/drift-boost.md) textures: tier-coloured sparks, tyre dust, and exhaust flames and soot (client appearance NOT RUN). Pooled gate strips (eight, one per gate of the current track) highlight the next gate and retain passed gates; the checkpoint text also names the next target. Drive counterclockwise from the right-hand start: North, West, South, then Start. Each accepted circuit awards one lap. The lap HUD shows `Best: --` until a completed lap, then the fastest completed duration and its lap number. Equal times keep the earlier lap; an incomplete lap never replaces it. On the third lap the run stops at the finish tick, releases controls and shows total, last-lap and current-run best completed-lap times in a summary with a Restart button. Stopping early retains actual partial progress; combat labels the interruption and closes the window. Reopening keeps the frozen summary and best lap; rejected Starts preserve them. A successful fresh Start or Restart clears both. The lap best is kept within this run; completed eligible solo race totals are also saved in the Highscores board, with name and UTC date. Times come from integer simulation ticks at 1/60 second, beginning at GO and including acceleration; the 180 countdown ticks, dropped callback time and stopped time are excluded. Physics/loop/probe counters include the countdown. The center cue shows GO for the first 60 racing ticks. A hitch can extend countdown wall time because dropped ticks never skip countdown steps. Stopping during countdown freezes zero race elapsed time; Restart begins a fresh countdown. These are local solo results, with no competitive route-validation guarantee. See [the gate and timing rules](docs/TRACKS.md).

Mirage Raceway version 1 is selectable while stopped. Its closed 16-vertex centerline has a 112-unit capsule-union road, perimeter walls, a north-facing start and four directional gates. The original `Assets/Tracks/SaltFlats/Background.tga` (scenery v1) is painted against that geometry, not cropped from the concept board; simulation never reads painted pixels. The layout generator exports matching [JSON](docs/art/mirage-layout.json) and [SVG](docs/art/mirage-layout.svg). In play, a north-up camera follows the interpolated kart pose at scale 1.5, with 60 world units of heading look-ahead and a view clamped to the map edges. It fills the 800×480 canvas with a cropped view of the map; the kart is 25.5×46.5 canvas units and the road is 168 wide. Positions, sprite dimensions and clipped gate/wall strips share that transform. The analytical Oval remains only as a developer test fixture. The background is loaded on first open or deliberate selection and reused; a selection failure retains the existing working map. If the initial default art cannot load, Start refuses until a valid map loads. The owner's screenshot confirmed the earlier whole-map TGA; a later [stopped client check](docs/evidence/2026-10-20-mirage-camera-static.md) confirmed the closer crop, larger kart, aligned Start strip and clipped West strip on build 70450, with counts 9/111/13. Camera motion, edge behavior and handling remain **NOT RUN**. The default kart is the Goblin Mortar Trike: a sheet of 64 three-quarter-view headings rendered from a Warcraft III model, shown unrotated at the nearest heading. It is loaded once at creation, with the primitive as automatic fallback. While stopped, the Kart button cycles ten karts with balanced, heavy or agile handling; a choice loads its art with the same guards, a refusal keeps the current kart, and track/kart choices persist in account preferences. The owner's [in-game screenshot](docs/evidence/2026-10-20-mirage-scenery-owner-check.md) showed the earlier Goblin Drag Car sprite and scenery v1 at the Mirage start, and he later [approved the trike and the scenery shadow pass](docs/evidence/2026-10-20-trike-and-shadows-owner-approval.md); itemized moving checks remain **NOT RUN**. See [the short probe](docs/FEASIBILITY.md#mirage-blockout-first-load-probe).

The meter updates from actual simulation ticks and needs no new frames. Its labels and the existing drift/surface text provide feedback beyond color. Active kart rendering blends the previous and current 60 Hz positions and turns through the shortest heading arc, including frames without a simulation step. This adds at most one fixed step of visual delay; checkpoint progress uses actual fixed-step coordinates. Stop shows the exact final pose and freezes the meter with `Last drive` feedback; Start resets it. See `docs/PROGRESS.md` for the next build task. Deferred scale, long profiling and repeated manual matrices do not block local development.

This directory is the Git checkout linked to [PhilForever/AzerothKart](https://github.com/PhilForever/AzerothKart). Local commits preserve the original pack and focused M0 changes. Two human near-minute drives are recorded in the [client evidence](docs/evidence/2026-10-19-m0-client.md), followed by [600 valid stationary timing samples](docs/evidence/2026-10-19-m0-stationary-profile.md). A later isolated rendering test identified grass covering the road when snapping states differed. Explicit grass priority and creation-only band settings now remove the seams; normal reload and read-only checks verified the installed fix with counts 6/99/3. [Rendering evidence](docs/evidence/2026-10-19-m0-road-layer.md). M0 remains open, including scaling, sustained performance and remaining input checks; further combat testing stays deferred. The source history was pushed to GitHub main on 2026-10-20 at the owner's request; no release or scheduled automation was created. See `docs/PROGRESS.md` for the current task and `docs/AUTOMATION.md` for the optional continuation workflow.

## References
See `docs/CLIENT_API.md` for links and confidence levels. Updated documentation reflects Oct 2026-era WoW Forever but must be validated against the installed build.
