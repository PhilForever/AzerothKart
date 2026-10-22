# Ironforge integration review — 2026-10-22

Reviewed Claude's complete `docs/handoffs/claude-latest.md` at
`de2fa5f9fdbab885ccc67c20904ec6e6862124c4` and the three new commits after
`78d97a1`. Integration starts from clean Codex `899d04d`, reserved by `7fe251e`
on `codex/ironforge-integration`. The owner confirms the previously reported
Stormwind corner now works in game. That confirmation is scoped to the corner;
no milestone or comprehensive performance check is marked complete.

## Source and merge decisions

- Keep both histories with a normal merge. Resolve shared catalog/menu/docs
  hunks individually, preserving Stormwind version3, full-speed handling,
  exposed-wall geometry, the staged background transaction, preference fixes,
  Stop/results and all session/start-clock behavior. Claude's checkout and
  authored handoff are not rewritten.
- Add Ironforge's original route, seven gates, preview and background. The lap
  remains7,077 units, with a369-unit approach; the two Forge passes remain
  separated. Authored geometry validation passes. No plazas or solid boxes;
  the street walls exclude scenery/lava. All fourteen runtime artwork files
  match Claude's source, including twelve pre-existing files.
- Correct one integration finding using the existing collision feature:
  Ironforge's gate-hall junction has the same separately-shrunk capsule wedge
  previously fixed in Stormwind. For example `(232,641)` was rejected by the
  legacy definition while inside the painted street. Ironforge version2 opts
  into14-unit exposed-wall clearance with1,745 generated junctions. A step from
  `(234,641)` to `(232,641)` now succeeds without contact. Route, art, gates,
  spawn and straight-wall clearance remain unchanged. Ironforge retains rough
  shoulders; Stormwind's full-speed policy is not generalized to it.
- No global Physics/Circuit/UI/Input/Loop/Race/networking changes. No live race
  or city multiplayer compatibility is enabled. Existing eight gate strips
  suffice; explicit mocked allocations stay71 frames/165 textures/80 fonts.

## Executed validation

| Command/check | Result |
|---|---|
| `python scripts/test_lua.py --runtime both` | PASS:27 test modules and52 parsed files in each actual Lua5.1/5.4 runtime |
| Focused `--runtime lua51 --tests ui menu` and `--tests circuit` | PASS: new restore/preview/selection, destructive refusal, seven→six→four gate visibility, both city gate walks and corner/rough-shoulder regressions |
| `python tests/test_circuit_boundary.py -q` | PASS:9 analytic geometry tests |
| `python scripts/build_city_tracks.py --wc3 . --geometry-only --check` | PASS: both cities exactly match generated geometry, with no extracted model files needed |
| `python scripts/validate_project.py` | PASS:103 required paths,24-module TOCs, local links and experiment ledger |
| `git diff --check` | PASS |

The Python runner uses the existing pinned Lupa2.8 dependency. Tests use native
API doubles, not a client connection. The full suite was run once at this
integration checkpoint, following focused checks. Full Warcraft III art
regeneration is NOT RUN by Codex; Claude's separately attributed reproducibility
report and exact imported hashes remain in its handoff/asset ledger.

Ironforge background SHA256:
`db7b382943a6022f80ad5b4e98b138a575abe10a6870617027096c02720a74ab`.
Preview SHA256:
`239ac12253f7061cfcf4ed0820537cf8ca6fa8ec1396ce3e610f83be210f96db`.
Provenance is Blizzard Warcraft III: Reforged3.0.1.24371 from the owner's
installation, documented in the asset ledger/source list. Existing unresolved
redistribution status is unchanged; this integration is local development.

## Resources, preservation and remaining checks

Claude's standalone handoff reports164 textures and one scenery image. The
combined staging-loader contract supersedes those descriptions:165 textures,
two background slots potentially retaining32MiB raw city pixels, plus preview
textures/native overhead. Native memory and switching hitches are unmeasured.

Ignored preservation artifacts live under
`local-artifacts/ironforge-integration-20261022/20261022-111735-utc/`:
verified all-ref bundle, canonical/Claude tracked and untracked file hashes,
statuses, HEADs, and the exact39-file installed baseline at81cc0ed. The final
deployment record must name the committed source and verified backup before
claiming installation. No foreign branch/checkout reset, deletion or automatic
publication is authorized by this checkpoint.

**NOT RUN:** Ironforge loading/appearance, actual driving/wall feel, preview,
camera, persistence, sound/scaling and performance in WoW; new-prefix transport,
start clock and live race acceptance. Fully exit and restart the client after
installation because Ironforge's texture files are new. Then `/akart` → Single
Player → Ironforge Grand Prix → kart → Race!. No additional network probe or
long manual matrix is requested.

Codex's next development slice remains the bounded live-race lifecycle around
the one-shot RaceStart output; Claude may continue visual work from a separate
branch after reviewing this integrated baseline. Neither city count nor code
presence completes the release/content or multiplayer gates.
