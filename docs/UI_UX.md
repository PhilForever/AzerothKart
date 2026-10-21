# UI / UX specification

## Visual direction
Original retro-fantasy goblin-engineering arcade, with a dark metal / parchment shell and bright readable kart accents. Keep our own identity. Original art and Warcraft III game/community sources follow the accepted [ADR 0009](adr/0009-warcraft-iii-asset-reuse.md), with per-file source, credit and permission status. Design for the WoW screen with a movable, scalable 950x620-ish panel and full-screen optional only if safe.

The accepted first-map direction is **Mirage Raceway** on the dry, pre-flood Shimmering Flats, with Warcraft III-like recognizable fantasy vehicles rather than modern go-karts. Preserve distinct Siege Tank and Steam Tank concepts alongside Goblin Mortar Trike, Gyrocopter, Gryphon Rider, Gnome/Goblin Drag Cars and optional Shredder. For freely rotated sprites, use strict overhead orthographic art facing north; an angled three-quarter treatment needs directional frames. Aircraft hover is cosmetic with shared ground collision and separate shadows. Use one precomposed background, optional foreground and pooled dynamic sprites, keeping track/vehicle silhouettes readable at play size. This is planned art direction, not an implemented skin or cleared asset collection; see [ADR 0008](adr/0008-mirage-raceway-art-direction.md) and [the map brief](art/MIRAGE_RACEWAY.md).

## Ownership and current scope

[UI/flow ownership](UI_FLOW_OWNERSHIP.md): Claude owns screen layout, navigation, labels and visual polish; Codex owns session transitions, capabilities, command semantics and cleanup. Use the copied PeerSession view and agreed commands in [API_CONTRACTS](API_CONTRACTS.md#implemented-pure-peer-session-controller). Host/Join/Ready/Start currently exists only as an offline controller, with no multiplayer menu or transport adapter. A starting status is a control proposal, not permission to begin simulation.

## Planned scenes

**Front end on `claude/ui-flow` (2026-10-21; proposed for Codex review; client NOT RUN):** [the front-end sheet](art/ui/front-end.md) implements a first version of most scenes below:

- `HOME`: Single Player, Multiplayer (coming soon), Garage, How to Play and Settings.
- `TRACK_SELECT`: preview, laps, gates, direction and off-road; no record holder or difficulty yet.
- `GARAGE`: a turntable preview; every kart handles the same.
- `RACE`: lap, gate and time at the top corners, the capture line and a large countdown.
- `RESULTS`: total, last and best times with every lap; Restart, Change Kart, Change Track and Main Menu. There is no ranking until multiplayer.
- `SETTINGS`: window size, effects, sound, developer info and reset position. Keybinds, reduced motion and volume are not offered yet.
- `ROOM` is a disabled coming-soon preview until Codex's session adapter and command contract land.

Quick Race and Time Trial are not separate entries: Single Player is the quick race, and time trials are deferred under ADR 0010.

These are design targets, not existing screens. Implement only supported actions; leave unavailable settings out of the current flow.

1. `HOME`: logo, Quick Race, Time Trial, Multiplayer (disabled until gate), Garage, Tracks, Settings, Help; explicit Coming Soon cards rather than fake active buttons.
2. `ROOM`: host, invites, track, slots, ready indicators, server compatibility, countdown and leave.
3. `TRACK_SELECT`: preview, length, number of corners, hazards, record holder, difficulty.
4. `GARAGE`: cosmetic chassis/colors, skill-neutral stats; preview sprite.
5. `RACE`: large unobstructed canvas, top bar lap/position/time, left minimap or progress, item HUD, clear input capture and pause indicator.
6. `RESULTS`: clear ranked times, differences, personal best, rematch/leave.
7. `SETTINGS`: keybinds, scale, graphics quality, reduced motion, audio, gameplay assist, restore defaults.

## Race canvas composition
Map is viewport-clipped; a strict overhead vehicle uses a separate rotating texture, while an angled vehicle needs directional frames. Track visuals layer below players, optional scenery occlusion above them, trails/particles above road and below HUD. Mirage uses a close north-up camera with heading look-ahead, cropping the background to fill 800×480 at scale 1.5. Kart/gate/wall dimensions and positions share that transform; off-screen markers clip to the canvas. The window stays 856×762. Test Oval keeps its fixed overview. The stopped **Track: Test Oval / Track: Mirage Raceway** button provides deliberate selection. Successful selection clears the previous local run/sample; load refusal preserves it. Test Oval is the default after reload. Pool sprites, cap particles, maintain readable contrast and accessible color cues. The integrated Drag Car and Mortar Trike presentation exists; the next roster is under review. The full scene navigation above remains future work.

## Focus and safe exit
- Display **"Controls active — Esc to release"** while key capture is enabled.
- Prevent racing during combat. Combat during a game closes the racing window and records "Game interrupted by combat" once. Future races finalize their actual current placements; M0 has no standings to fabricate. Do not use `SetPropagateKeyboardInput` inside combat or automatically resume. Determine actual release behavior in F2 tests (ADR 0006).
- Do not capture input during chat edit boxes. Show a visible pause/focus-lost overlay on losing focus.
- Add always-clickable close/pause control; ESC cannot be sole release route.
- Player should never have to `/reload` to recover movement.

## Performance & scaling
Test low resolution, UI scaling, ultrawide and high DPI. Use documented 2D sprites/atlases and control draw count. All visual screens must be usable without color coding alone.
