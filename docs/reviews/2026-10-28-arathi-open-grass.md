# Arathi open grass review — 2026-10-28

Claude `445c322` provides the reviewed fewer-fence artwork on top of the
previous integrated track. Codex adds a 4-unit packed passability grid for
Arathi alone, generated from the surveyed terrain, open-edge authoring ranges,
bridge/fence approximations and protected road mouths. Road remains road;
admitted ground beyond it is slow grass with the existing boost-on-grass rule.
The swept resolver includes corner and thin-wall guards. Other tracks retain
the prior solver. The checked-in map rebuild is deterministic.

The actual-track samples cover each of the eight openings, one 100-unit grass
passage, bidirectional retained barriers, a blocked road mouth, bridge, water
and a cliff. They are representative, not exhaustive. A separate cardinal
search and real Lua replay completed two laps in checkpoint order. An
eight-neighbor geometric search found a route about 14% shorter than the
centerline; it does not model steering or grass speeds. Shortcut balance,
precise visual alignment and native performance remain NOT RUN. Off-road
decorative props are not all colliders. Geometry3 separates older records
and refuses old multiplayer offers; no leaderboard data is deleted.
