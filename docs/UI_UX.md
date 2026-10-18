# UI / UX specification

## Visual direction
Original retro-fantasy goblin-engineering arcade, with a dark metal / parchment shell and bright readable kart accents. **Not** a clone of Mario Kart UI and not a reuse of proprietary art. Design for the WoW screen with a movable, scalable 950x620-ish panel and full-screen optional only if safe.

## Scenes
1. `HOME`: logo, Quick Race, Time Trial, Multiplayer (disabled until gate), Garage, Tracks, Settings, Help; explicit Coming Soon cards rather than fake active buttons.
2. `ROOM`: host, invites, track, slots, ready indicators, server compatibility, countdown and leave.
3. `TRACK_SELECT`: preview, length, number of corners, hazards, record holder, difficulty.
4. `GARAGE`: cosmetic chassis/colors, skill-neutral stats; preview sprite.
5. `RACE`: large unobstructed canvas, top bar lap/position/time, left minimap or progress, item HUD, clear input capture and pause indicator.
6. `RESULTS`: clear ranked times, differences, personal best, rematch/leave.
7. `SETTINGS`: keybinds, scale, graphics quality, reduced motion, audio, gameplay assist, restore defaults.

## Race canvas composition
Map is viewport-clipped; car drawn on separate rotating texture; track visuals layer below players, trails/particles above road and below HUD. Pool sprites, cap particles, maintain readable contrast and accessible color cues.

## Focus and safe exit
- Display **"Controls active — Esc to release"** while key capture is enabled.
- Prevent racing during combat. Combat during a game closes the racing window and records "Game interrupted by combat" once. Future races finalize their actual current placements; M0 has no standings to fabricate. Do not use `SetPropagateKeyboardInput` inside combat or automatically resume. Determine actual release behavior in F2 tests (ADR 0006).
- Do not capture input during chat edit boxes. Show a visible pause/focus-lost overlay on losing focus.
- Add always-clickable close/pause control; ESC cannot be sole release route.
- Player should never have to `/reload` to recover movement.

## Performance & scaling
Test low resolution, UI scaling, ultrawide and high DPI. Use original 2D sprites/atlases and control draw count. All visual screens must be usable without color coding alone.
