# Game design document (GDD) — target, not implemented

## Primary loop
Lobby → select mode/track/kart → pre-race countdown → race (laps, drift, item pickups, ranking) → results → rewards/statistics → rematch.

## Handling & joy
- Acceleration with top speed, progressive steering responsiveness, low-speed turn assist, braking/reverse, traction changes across surfaces, soft bump feedback.
- Intentional drift button; charge tiers based on maintaining a controlled slide, reward with brief boost on release; one-button accessibility drift option configurable.
- On impact, lose speed but retain control quickly; minimize dead time. No random loss of control lasting multiple seconds.
- Input feels immediate in local mode. Multiplayer should use local visual prediction while displaying other karts interpolated, subject to feasibility testing.

## Planned controls
- W/Up = accelerate; S/Down = brake/reverse; A/D or Left/Right = steer.
- Space = drift; E / configurable key = use power-up; Esc = close/pause and release keyboard capture.
- Keyboard capture only when the kart canvas is active/focused, always visibly indicated; fallback clickable buttons for key functions.
- Combat closes the racing window and ends the game with **"Game interrupted by combat"**; controls return to WoW. Combat ending never resumes that game. Zoning and UI focus loss require their own explicit stop/recovery transitions.

## Race rules
- Standard: three laps, last place start position for catch-up items if enabled, collisions, shortcuts with risk/reward.
- Race clock driven by deterministic simulation steps, not system clock deltas; countdown and result state changes host-governed in live races.
- Timing: fractional seconds for UI only; integer frame/tick authority to prevent inconsistent finish ordering.
- Anti-shortcut validation: ordered checkpoint gates, directional crossing, lap wraps only if all gates passed in sequence; teleport/resync does not award laps.
- Items: configurable off in competitive time trial; separate class for offensive/defensive and mobility items.
- Combat interruption finalizes the actual current placements once at the first handled interruption, with the interruption label retained when results are reopened. Repeated combat notifications cannot duplicate a result or change its frozen order. See [ADR 0006](adr/0006-combat-interrupted-results.md). M0 has no standings and records only a stopped, interrupted drive; remote-player notification remains gated on verified networking.

## First track content
- `Test Oval`: ugly but reliable probe, with surfaces and checkpoint points.
- `Mirage Raceway`: dry Shimmering Flats salt circuit, rival goblin/gnome pit camps and readable turns, with precomposed scenery and independent road/wall/checkpoint geometry. Replaces the proposed Tinker Speedway; see [ADR 0008](adr/0008-mirage-raceway-art-direction.md).
- `Murloc Marsh`, `Dusty Canyon`, `Frost Gearway`: illustrative future themes, not licensed Warcraft art.

## Power-ups (future)
- Turbo Cog: short speed boost; Slick Oil: deploy slowing puddle; Homing Wrench: target leading kart under line-of-sight/counterplay; Shield Bubble: blocks one hit; Blink Gate: forward burst without bypassing checkpoints; Repair Kit: recovers traction, not a monetary item.
- Items should have shared typed payload, cooldown, duration, explicit collision rules and deterministic seeded randomness.
- Avoid excessive screen effects or unavoidable chain stuns; use input responsiveness as invariant.

## Karts and cosmetics
- Recognizable Warcraft III-like Siege Tank, Steam Tank, Goblin Mortar Trike, Gyrocopter, Gryphon Rider and the two Mirage drag-car designs; optional Shredder follows the initial pair. Use the [vehicle brief](art/MIRAGE_RACEWAY.md) and recorded asset provenance.
- Initial karts share tuned balanced stats, visual skins only; variants are tightly balanced before PvP.
- Stats are bounded by validated classes (acceleration, handling, traction, top speed). Cosmetic unlocks do not require gold or cash.

## Modes by maturity
1. Test Drive (M0), Solo Time Trial (M3), Ghost Race (M4), AI (M5).
2. Multiplayer Experimental (after network gate), Multiplayer Stable (after in-game testing).
3. Power-up Battle Race, cups, tournaments, profiles, track variants and long-term replayability.

## Accessibility
- Colorblind-friendly HUD, configurable scale, reduced animations, sound toggle, high contrast, remappable keys when client API allows, camera centering preferences, full keyboard release on exit.
