# Mirage runtime blockout background

`addon/AzerothKart/Assets/Tracks/SaltFlats/Background.tga` is original,
code-generated placeholder art for the Mirage geometry slice. Its inputs are
`Track.lua`, `MirageRaceway.lua` and the palette/detail code in
`scripts/build_mirage_background.py`. No screenshot, concept-board crop,
third-party model or third-party texture is included.

The exporter samples the actual Lua `isDrivable` predicate at every world pixel
center. One pixel represents one world unit. Warm tan marks road; pale cracked
salt is the existing traversable rough-ground surface. It includes no baked
gates, kart, scenery collider or authoring labels. Interactive gate indicators
and the kart remain separate pooled UI textures.

Format: 1024×1024, uncompressed true-color TGA (type 2), 32-bit BGRA, eight alpha
bits, fully opaque, bottom-left origin. This matches the world's bottom-left,
+Y-up coordinates. Positions and dimensions use the shared uniform viewport
projection; the background occupies 480×480 within the 800×480 canvas.

Regenerate with `python scripts/build_mirage_background.py`; verify exact bytes
with `python scripts/build_mirage_background.py --check`. The check also asserts
the header, payload size, opaque alpha and eight asymmetric road/orientation
landmarks, including pixel centers immediately inside/outside the road edge.
This offline evidence does not establish actual client texture loading or
orientation; the focused client check remains separate.

The blockout establishes alignment and readability. Painterly scenery and the
first Warcraft-inspired vehicle sprite follow in later slices.
