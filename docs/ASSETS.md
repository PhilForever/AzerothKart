# Art, sound, track tools, and license provenance

- Placeholder render uses colored frames/textures so client tests work before assets exist.
- Future original atlas: karts viewed top-down at 0 degrees, steering neutral; UI texture rotation to orient. Test orientation math. Sprites preferably power-of-two texture dimensions where required by client.
- Track tiles original: road, dirt, ice, oil, grass, boost pads, walls, shadows, checkpoint banner. Decorative visuals must not affect collision geometry.
- VFX: sparks from drifts, exhaust, small collisions, gold-free win confetti; pool all particle widgets.
- Sound: engine pitch, item pickup, checkpoint, drift charge, impact, fanfare. Verify supported audio API, use own licensed audio, honor mute.
- Record `asset path | author/source | license | permission | date` for every distributed asset; no copied WoW game files, Mario Kart or CTR music.
- Preflight: validate dimensions, transparent backgrounds, paths/casing and memory budget; include a generated manifest.
- No media produced in this zip; professional art pass is a later milestone after game feel verification.
