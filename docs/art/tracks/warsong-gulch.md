# Warsong Gulch (planned: the Battlegrounds Cup)

**Status (2026-10-27): planned, waiting for floors.** Nothing is built. The owner chose to have Codex add two-level driving first ([ADR 0022](../../adr/0022-floors-and-boost-pads.md), proposed), then build Warsong with the banana and the roof drivable.

## The owner's request

"Battlegrounds Cup - let's try Warsong Gulch first. It's going to be groundbreaking if we can make it work. The challenge is the two tunnels, and possibly floors. I'm not sure how the route/track should go or if it should be open. If open we would need clearer checkpoints and possibly a guiding arrow to the next checkpoint."

He sent the in-game world map with his callouts and eleven screenshots naming the places Warsong players use, for both bases:

- **The field:** mid, east, west, each side's zerker hut and leaf hut.
- **Outside each base:** the tunnel and its hut, the ramp, the fence and the graveyard on the plateau above the tunnel, the top of the tunnel.
- **Inside each base:** the lobby, the flag room, and the connector, a ramp from the lobby up.
- **Behind each base:** the tunnel exit, a side door of the tunnel; the banana, a path that climbs from it to the roof; the roof.
- **In each tunnel:** the banana entrance and the Boots.

## Decisions (the owner, 2026-10-27)

| Question | His choice |
|---|---|
| The race | **A fixed loop, three laps:** at each base, in by the tunnel, round the flag, out by the ramp. Each lap runs both flags: three laps, three captures. |
| Floors | **Wait for floors:** Codex adds two-level driving first; then the banana and the roof are drivable. |
| Guiding arrow | **On Warsong only:** a small arrow by your kart points at the next checkpoint. |
| The Boots | **A boost pad in each tunnel**, proposed to Codex. |

## The route

![The proposed loop over his world map: tunnels dashed, six checkpoints](warsong_gulch-route-sketch.png)

*A design sketch drawn over the owner's screenshot of the in-game world map, his callouts included; a reference, not shipped.*

1. **Alliance flag**, in Silverwing Hold's flag room, reached from the field through the Alliance tunnel.
2. **Alliance ramp**, out of the base and down to the field's east side.
3. **Horde tunnel**, at its hut.
4. **Horde flag**, in the Warsong Lumber Mill's flag room.
5. **Horde ramp**, out of the base and down to the field's west side.
6. **The finish**, at the Alliance tunnel's hut.

The map is point-symmetric, with the Alliance ramp on the east and the Horde ramp on the west. So the two runs across the field pass mid on opposite sides and never cross: one clean loop. Between checkpoints the ground is open, and a kart may take any line across the field. With floors, the banana and the roof become other ways through each base between the same checkpoints. A rough estimate is about 4,000 world units and 30 seconds a lap.

## What needs floors

| Overlap | Below | Above | Joined by |
|---|---|---|---|
| Each tunnel | the tunnel, from its hut on the field into the base (with the banana entrance) | the plateau: the fence, the graveyard, the top of the tunnel | the outdoor ramp, from the field up to the plateau |
| Each base | the lobby and the flag room | the roof | the connector inside; the banana outside, from the tunnel exit up to the roof |

Until floors exist, a tunnel could already be drawn under a fading roof if no kart drove on top of it. But the owner wants the roof and the banana drivable, so Warsong waits.

## Rendering plan (Claude)

- **Two kinds of picture:** the ground (the field, the tunnels' and the bases' insides) and roof overlays (the plateau over each tunnel, each base's roof), drawn over karts below them and under karts on them. An overlay fades while the player's kart is under it.
- **Checkpoints you can see:** the two flags as glowing markers in their rooms; the ramps' and tunnels' gates as banners or arches.
- **The guiding arrow** by the player's kart, pointing at the next checkpoint.
- **The Boots pads:** a glowing boots mark in each tunnel.
- **Art:** Warcraft III has both halves of the gulch: Ashenvale for the night elf north (its grass, purple-leaved trees, moonwells, night elf huts) and the Barrens for the orc south (its dirt, orc burrows and huts, spiked barricades, the war mill). The two fortresses are built from walls and buildings, as the Scarlet rooms were, and every pick is recorded with its source.

## To settle when building

- **The flag rooms:** if a flag room has one door, its checkpoint sits at the flag and the lap turns there; with two doors, the lap passes through.
- **The roof's edges:** whether a kart can drop from a roof or a plateau to the ground below (a one-way drop-down), as players jump in Warsong.
- **The start:** both racers on one grid (works today) or each in their own base, Alliance against Horde (needs Codex's starting positions).
