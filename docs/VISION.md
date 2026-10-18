# Product vision and boundaries

## One-liner
Azeroth Kart is a self-contained top-down arcade racer played within World of Warcraft: Forever, offering rewarding controls, original fantasy karts, varied courses, local time trials and (after validation) social races.

## Player fantasy
While waiting for a dungeon or hanging out in a city, friends open `/akart`, race through an original whimsical fantasy circuit, master drifting, dodge hazards, and chase personal bests. It feels like a complete arcade game — not just dice rolls, chat prompts, or a UI gimmick.

## Product pillars
1. **Game feel first:** responsiveness, momentum, drift, boost, readable collisions and clear audio/visual feedback.
2. **World inside a window:** original pixel/illustrated fantasy presentation that looks native and performs well in UI frames.
3. **Replayability:** times, lap records, ghosts, short races, adaptive AI, different kart handling and track routes.
4. **Accessible by default:** keyboard and configurable bindings with deliberate focus, clear pause, legible UI, safe combat interruption.
5. **Honest multiplayer:** network constraints measured first; no fake synchrony or unsupported fairness claims.
6. **Modular content:** data-driven track definition, items, kart configs, localization and scenes.

## Modes in target product
- Solo Time Trial (first release priority); Practice; Local AI race; asynchronous Ghost Challenge.
- Live Friend Race: 2–4 players first, potential 5–8 only if tested networking can support it.
- Grand Prix: multi-track season/event with rank points; private rooms, host transfer/recovery where practicable.
- Future editor (developer tool) and curated track packs after track pipeline proven.

## Anti-goals / exclusions
- No modifying the world, controlling avatars or hidden combat automation.
- No external relay, account, anti-cheat service, launcher, kernel hooks, screen-reading or bot integration.
- No in-game gold stakes or real-money casino systems.
- No dependence on competitive-grade anti-cheat; an addon host is not a trusted game server.
- No ripped IP art/assets/audio/track layouts from commercial kart racers or Warcraft client resources without permitted use.

## Success criteria
- Solo handling is fun for 15-minute repeat play and stable during 20-minute stress run.
- Deterministic fixed-step reference simulation passes test vectors; replay is usable.
- User can always exit cleanly and resume normal WoW keyboard controls.
- Real multiplayer only ships if measured p95 interaction/play feel is acceptable under real group throttles; metrics and decision recorded.
