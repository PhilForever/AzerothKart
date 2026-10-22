# Claude handoff — Ironforge Grand Prix version 3 (the owner's design changes)

Prepared 2026-10-22 about 17:30 CEST (Europe/Oslo) by Claude (rendering/UI/sprites owner). Supersedes the Capital Cities Cup handoff at `de2fa5f` (Stormwind and Ironforge version 2), which Codex imported verbatim into `codex/ironforge-integration`; it remains in history.

**Base:** `codex/ironforge-integration` at `d5817a8` (Codex's reviewed, installed integration of Claude `de2fa5f`, Stormwind version 3 full speed and exposed-wall clearance, Ironforge version 2). New branch **`claude/ironforge-design`**:

1. `5a56e90` — Ironforge version 3: narrows, lava, the Great Forge; tests;
2. this handoff with the shared docs and the contract proposal.

`claude/capital-cup` stays at `de2fa5f`. No milestone or multiplayer gate changed.

## Owner instructions

- After Codex's install of version 2: "I've tested it, but would like some design changes. I want clearer change on the entrance and exit of Forlorn Cavern - should be tighter, as per ingame, so - my proposed fix, remove the shoulder on the track when you enter and exit forlorn cavern, and put the wall where the shoulder originally started. Also: The lava doesn't need drop shadow, and I'd like the wall around it to be darker and remove the stripes inside the lava. I like the glow though. Also sending you an image of the great forge from the game, there are no buildings between the lava, only a big anvil and some pumps, so please try to emulate that." Screenshots: three in-addon views of the forge (grey wedges beside the pools, ridged lava, smithies between the pools) and the in-game Great Forge (a red and gold anvil, big smelter cylinders with pipes, small pumps, a hex-tiled floor).
- On the hypothetical of rebuilding the cities from WoW's own assets: "Let's leave it alone for now."
- Standing: no merge into `main`; no claim of in-game verification without the actual client; leave the simulation-control functions in `UI.lua` alone. The owner pushes and runs the client checks; Codex prepares coordinated installs ("Wait for Codex").

## Delivered

[The Ironforge sheet](../art/tracks/ironforge.md#revision-after-the-owners-drive-2026-10-22) has the revision; [the before/after picture](../art/tracks/ironforge_gp-v3-review.png) was sent to the owner.

- **Forlorn Cavern narrows.** Two tunnels through the rock, in from the Mystic Ward (loop arcs 1,176–1,362) and out by the cavern's north-east stair towards the Hall of Explorers (1,896–2,074). The wall stands at the paving's edge (painted 56 from the centerline, the shoulder's old start); the kart centre stops 42 out and is always on road there. The street flares back to its normal width round each end along the wide street's end circles. The rock is cut square 140 units either side (`rock.tunnel`), so the tunnels read as passages between halls. Route, gates, spawn and the rest of the street (its rough shoulder and 76-unit reach) are unchanged.
- **Lava.** The grey wedges the owner called a drop shadow were the street's pavement over the pools' polygons, left unlit because the glow skips lava: the pools now stop at the street's wall as water does. The bank face along their north shores is gone, and so are the forge's concentric ridges. A dark iron wall (`"lava"` style, plate seams) stands all round every pool: the street's own wall where they meet, a rim elsewhere. The glow is unchanged.
- **The Great Forge.** `reserved` ground between the two forges takes no generated buildings, trim or braziers (people may stand there); the smithy that stood in for an anvil is gone. Instead: the Great Anvil (red and gold, its long side the classic profile towards the camera), two great pumps (riveted iron vats on bronze rings, pale pipes) and two small pumps with rocking beams. Warcraft III has no such models (a search of all 15,090 model paths of the owner's install found none), so `scripts/city_meshes.py` builds them from boxes, prisms and cylinders and `wc3render.render` draws them like any model, with the scenery's light, lean and shadow. Its cos and sin are a Taylor series in plain arithmetic, so the bytes do not depend on a platform's maths library. The smithies round the hall's outer floor remain.
- **Track screen:** Ironforge's facts now read "Tight tunnels in and out of the Forlorn Cavern" and "Mind the lava: the forges' walls are solid".

## Changes Codex must review

The proposal is in [API_CONTRACTS](../API_CONTRACTS.md#proposed-capital-cities-cup-city-circuits-and-the-course-catalog).

1. **`Circuit.new`: optional `narrows={{name?, first, last, wallRadius}...}`** (needs `wallRadius`). Loop segments `first..last` (segment k joins `centerline[k]` to `centerline[k%n+1]`) are drivable to the narrows' radius (`0 < r <= wallRadius`) and paved to `min(roadRadius, r)`; overlapping entries take the smaller radius; invalid entries are refused at construction; `track.narrows` is a copy. The change is about 20 lines in the definition parsing and the centerline loop: everything after (ground, streetGround, boundaryPoint, exposed, nearestDrivable, the grid) already works per capsule. Without `narrows` the track is built exactly as before.
2. **`scripts/circuit_boundary.py`:** new `loop_radii(geometry)`; `boundary_vertices` gives each loop capsule its own radius. Codex's existing tests pass unchanged; one test added.
3. **`scripts/build_city_tracks.py`:** `narrow_segments` turns the layout's arc ranges into segment runs; the validator's `reach_gap` uses per-segment radii; the Lua data gains a `narrows` block for Ironforge only. Ironforge version 3; its `wallVertices` change only round the tunnels (97 removed, 34 added). Stormwind's generated entry is byte-identical.
4. **`tests/test_circuit.lua`:** a narrowed side of the square fixture (road to 15 then wall, shoulders elsewhere, exact free movement, wall contact, six invalid definitions); Ironforge `version == 3` (was 2), both narrows' road and wall either side, shoulders kept before them, and a drive steering into the entrance tunnel's wall (impacts, never a step ending in it). No existing assertion was relaxed.
5. **Gameplay:** the tunnels give the kart centre 84 units of width (152 elsewhere). Whether that is too tight with several karts is the owner's client check; widening is one number in the layout (`wall_radius`).

## Tests performed

| Command / check | Result |
|---|---|
| `python scripts/test_lua.py --runtime both` | **PASS** in the cloud (Python 3.13, Lupa 2.8) and on the developer machine's Linux shell (Python 3.10.12, Lupa 2.8) at `289ad3d`: both runtimes, full suite |
| `python tests/test_circuit_boundary.py` | **PASS** on both machines, 10 tests (Codex's nine plus the narrows join test) |
| `python scripts/build_city_tracks.py --wc3 … --check` | **CHECK PASS** for `CapitalCities.lua` and both cities in the cloud, and on the developer machine at `289ad3d` from its own extraction and sprite cache (it rendered the new sprites and the meshes itself; two calls for Stormwind, whose cache there was incomplete). Stormwind `Background.tga` sha256 `078a7805bccdadd8b88a909d5c37b013aa51e9d0d7981134c04f7a9db12f4ebb` (unchanged); Ironforge `Background.tga` `c531ceee694b59f142bdbe522d5d86da9f23fe07b6486b6d4dc0c76a3e64ac05`, `Preview.tga` `8bae79810b4751284e4fd908a56b6301bedf5bc78645e67d3f283fa7e95b8e8d` |
| Collision probe (scratch, not committed) | `surfaceAt` against an independent test (the 14-unit disc round a point inside the union of visual capsules) at 21,761 points round the four tunnel ends: **0 mismatches** |
| `python scripts/validate_project.py` | Only the 2 pre-existing Windows-path links in PROGRESS.md fail, on both machines |
| Review | Crops of the forge, both tunnels, the Military Ward's pit and the whole city inspected; before/after sheet sent to the owner |

**NOT RUN:** anything in WoW Forever (the tunnels' feel and width, the lava walls, the anvil's look, frame rate); any install; multiplayer.

## Client check (owner; NOT RUN; after Codex's coordinated install)

[The checklist](../../tests/MANUAL_CLIENT_CHECKLIST.md#deferred-ironforge-grand-prix-check-proposed-claudecapital-cup), items 6 and 7: drive both tunnels (no "Off-road", the kart's body meets the rock edge, the street flares back after), record whether two karts fit; every lava pool walled dark with no ridges and no grey band, the glow kept; only the anvil and pumps between the forges. The changed files replace existing ones; a full client restart is still the safe choice.

## Deployment

Claude installed nothing and did not touch the live AddOns folder. Codex installs reviewed, integrated source; the owner decides.

## Pending PROGRESS ledger entry (integrator to append; PROGRESS.md was not edited)

> ### 2026-10-22 ~17:30 CEST — Claude / `claude/ironforge-design`, Ironforge version 3
>
> - The owner's design changes after driving version 2 (`5a56e90`): the Forlorn Cavern's entrance and exit as narrows (no shoulder, the wall at the paving's edge, cut through the rock) via an additive `narrows` circuit field proposed for Codex's review; lava without its bank face, ridges or grey unlit corners, inside dark iron walls, glow kept; the Great Forge's floor between its forges reserved for a procedural Great Anvil and pumps. `Background.tga` sha256 `c531ceee…3e64ac05`, `Preview.tga` `8bae7981…95b8e8d`; Stormwind unchanged.
> - `test_lua.py --runtime both` PASS and boundary tests PASS in the cloud and on the developer machine; `build_city_tracks.py --check` PASS for both cities on both (the machine from its own extraction and sprites); collision probe 0 of 21,761 mismatches; validator: only the 2 pre-existing PROGRESS links.
> - **NOT RUN:** the client; install.

## Branch, commits and workspace

| Item | Value |
|---|---|
| Worktree / branch | `AzerothKart-Claude` / `claude/ironforge-design` at this commit (the worktree previously held `claude/capital-cup` `de2fa5f`, which is unchanged) |
| Push | Owner only: this session's git proxy refuses the repository. `git -C "C:\Users\bakke\Downloads\Forever_Addons\AzerothKart_Codex_Project_Pack\AzerothKart-Claude" push -u origin claude/ironforge-design` |
| Not done | No merge into `main` or any Codex branch; no tag, release, install or client input. Codex's branches and worktrees were only read |

**Workspace notes:** commits are made in a cloud clone with this repository's local identity, moved as git bundles (`local-artifacts/bundles/`) and fast-forwarded, so the hashes are identical. Git runs from a Linux shell on the developer machine with `--git-dir=.git/worktrees/AzerothKart-Claude`, `core.createObject=rename`, `gc.auto=0`, `maintenance.auto=false` and `gc.worktreePruneExpire=never`. **Never run `git worktree prune` or `git gc` there**: the recorded gitdirs are Windows paths, and that shell lists them as prunable. The untracked `Claude outputs/` folder is still left for the owner.

## Next

1. Codex: review the `narrows` proposal and the Ironforge version 3 data; integrate and install when approved.
2. The owner's drive of version 3; adjust the tunnels' width or the forge on his notes.
3. Then Darnassus Canopy Run, Orgrimmar Canyon Rush, Thunder Bluff Skyway and Undercity Slime Circuit on the same pipeline, each traced on the owner's map of that city.
