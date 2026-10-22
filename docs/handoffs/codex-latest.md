# Codex handoff — Stormwind full speed to the walls

2026-10-22 10:11 +02:00, Europe/Oslo. Owner asks: Stormwind must not slow the kart before the street edges. Implemented/installed **c4b430d** (`c4b430d105da03f9fb7dd48742984d86547f4b89`) on **codex/stormwind-full-speed**, from clean published/deployedc59a607. Following docs commit records the install; runtime source unchanged. Own reservation preceded edits. No other agent checkout/history rewritten, no main merge/push/release.

## Change / shared contract

Optionalboolean Circuit.fullSpeedToWalls defaultsfalse; when true, the full corridor inside existing wallRadius reportsroad through surfaceAt/isDrivable. Painted112-wide road and wallRadius76, dimensions/centerline/branch/spawn/gates/wall contact remain unchanged. Stormwind layout opts in and trackversion becomes2; build_city_tracks emits flag/version into generatedCapitalCities. Physicsversion7, Mirage/Oval surfaces and artwork unchanged. Drift/boost continue across Stormwind's shoulder; actualcollision still scrubs speed. No per-frame work/object budget change(71/165/80). Removed stale Stormwind slowdown copy in Courses/Menu/help; aligned contracts/track/physics/art/checklist docs.

Claude: keep the Stormwind version2/full_speed_to_walls authoring option and generator support when continuing city work; do not replace these with the old78d97a1 generated file. Your active worktree remains untouched at78d97a1; coordinate the next city merge with this branch and the prior staging-background fix in combinedc59a607. Other cities retain default surfaces unless the owner chooses otherwise. Current protocol does not offerStormwind for multiplayer.

## Executed checks

- Pinned actualLua5.1 `scripts/test_lua.py --runtime lua51 --tests circuit surface drift menu ui`: PASS,52files parsed/five modules. Default rough fixture, unchangedwall projection, center/shoulder all-field handling equivalence for throttle/boost/chargedrelease/drift and authoredStormwind shoulder points covered.
- Geometry-only generator and `--check`: PASS, only version/flag changed in runtime data; no archive/art rebuild.
- Structural validator: PASS96paths/24-module TOCs/links/ledger; whitespacePASS. Independent scoped review: no blocker.
- Installed39 source/target files exact;39prior files backed up/verified. BasePhysics/Track/Mirage/UI/Input/Race/SessionTransport and all art bytes unchanged; Claude/canonical HEAD unchanged.
- Lua5.4/fullbroad/client checks NOT RUN for this correction; no previous pass extended to a new manual claim.

## Install / next

Installed at `_classic_beta_/Interface/AddOns/AzerothKart` with existing PowerShell7 helper. Backup/manifest `local-artifacts/stormwind-full-speed-20261022/install-backups/20261022-100920-414-60b7f53b752c42f781bbb25af9f17193/`; receipt `local-artifacts/stormwind-full-speed-20261022/install-receipt.json` (ignored). No deletion, otheraddon orWTF/SavedVariables writes. No newfiles: owner only needs **`/reload`**, then test speed/drift/boost across the painted kerbside until wall contact. Gamefeel remains NOT RUN until feedback.

Nextsingle task: owner full-width Stormwind handling check, then Codex resumes bounded live-race controller/paced snapshots. Multiplayer remains ahead of ghosts/time trials; no roadmap acceptance markedcomplete. This correction is committedlocally, not published; original GitHubcombinedc59a607 and all protectedrefs remain unchanged.
