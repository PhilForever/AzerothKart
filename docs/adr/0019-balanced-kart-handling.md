# ADR 0019 — Modest kart handling profiles; one shared leaderboard

Status: Accepted from the owner's 2026-10-25 direction to implement balanced
kart attributes and keep the leaderboard shared without kart columns/filters.

Start with three profiles, not ten independent tuning sets. Balanced retains
the existing driving parameters. Heavy trades launch and cornering response
for a small cruising-speed advantage and stronger brakes. Agile trades cruising
speed and braking strength for quicker launch and tighter, faster steering.
Keep differences modest; measured tradeoffs are not proof of equal lap times.

Normal speed is 200/204/196 units/s for balanced/heavy/agile. Acceleration is
155/148.8/161.2 and braking 260/273/247 units/s squared. Yaw, steering build and
slip differ slightly; full numbers and measurements are in [PHYSICS](../PHYSICS.md).
All profiles share the same collision body, wall-hit retention/scraping policy,
reverse and rough-surface caps, drift thresholds, boost durations and boost cap.
Heavy is a handling label. There is no health, damage, collision mass or ability
to push another kart in this slice, so no functional tankyness stat is exposed.

Mapping:

- Balanced: Goblin Mortar Trike, Dwarf Car, Glaive Thrower, Goblin Pod Racer.
- Heavy: Steam Tank, Orc Demolisher, Meat Wagon.
- Agile: Dwarven Biker, Gryphon Rider, Gyrocopter.

The Pod Racer stays balanced in this first pass; no extra fourth profile or
unsupported stronger-launch/higher-speed combination is implied by its art.
Flying vehicles obey identical ground collision and checkpoint rules.

Private pure physics tables own all parameters. Public handling queries return
copies. Each accepted solo Start captures a kart-ID string; a live start uses
the ID already agreed by RaceGrid. Each fixed step receives that captured ID,
never the current sprite choice or a mutable parameter table. Vehicle state
retains its existing 15 fields. Unknown IDs refuse starting or fail a backend
initializer; nil/basic remain balanced for older internal callers.

Physics compatibility becomes 11, covering the mapping and parameters. Peers
with older handling cannot negotiate a race together. Existing RaceGrid and
live packet formats remain unchanged: reverse stays at -55 and boost at 260,
inside the current live codec's speed range. A future parameter/mapping change
requires another compatibility review/version change.

Keep one best per player on each compatible map board, regardless of kart.
Do not add a kart column, filter, class board or per-kart personal-best store.
Existing internal kartId metadata remains for data-contract compatibility.
Physics10 saved results are retained as historical data; Physics11 uses fresh
compatible board keys. There is no destructive migration or global-sharing gate
waiver. Automatic community transport remains the independent open task.

The picker reuses its existing description text to explain the selected profile.
No new settings, stat bars, UI objects or asset changes are needed for this slice.
Native feel and per-track balance await an actual drive; offline deterministic
replays and bounded handling metrics do not mark those checks passed.
