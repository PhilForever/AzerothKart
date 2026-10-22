# Ironforge v3: narrows contract and integration review

2026-10-22, Europe/Oslo. Base clean `d5817a8`, reservation `69dc2dd`,
incoming Claude `9461f9c44b93dd959707cc5a728480c0d020b933` on
`claude/ironforge-design`. Read its complete authored handoff and all three
commits. Claude branched from the installed combined baseline, retaining
Stormwind's fixes, staged scenery loading, preferences and backend work.

## Decision and implementation

Accept the additive `Circuit.new` **narrows** field after collision/authoring
review. Lua segment k joins point k to k%n+1; the Python helper/painter's
incoming-edge ordering maps it to k%n. Overlap takes the minimum radius.
Branches/plazas are unaffected. Radius is the kart centre's reach, not the
painted wall distance; visual capsules add the existing14-unit clearance.
Paving is min(roadRadius, narrowed radius), so a radius above roadRadius still
has a rough shoulder. Definitions without narrows preserve their behavior.

Ironforge version3 narrows segments75–86 and120–131 to42-unit centre reach,
with the painted edge at56. Those tunnels have84 units of drivable centre
width; they flare into the existing76-unit reach at each end. All other
Ironforge street surfaces, route, seven gates and spawn are retained. Boundary
data now has1,682 vertices. No new shortcut is added by reducing the legal
capsule union. Existing endpoint-based street collision is retained; this is
not a new continuous curved-wall sweep or vehicle-to-vehicle collision system.

Import Claude's revised lava, anvil/pumps and facts. Anvil/pump meshes are
offline authoring code, composited into the existing background. Runtime
changes are confined to Circuit's factory, generated Ironforge data and menu
facts, plus its two textures. No UI/controller/global Physics/input/loop/race/
network change. Explicit mocked pool remains71 frames/165 textures/80 fonts.

Codex additions: closing-segment/overlap/copy/branch regressions; reject Python
boolean segment indexes/radii like Lua; clarify the generic shoulder comment;
require `scripts/city_meshes.py` in the structural validator. Accept the public
contract in API_CONTRACTS and correct current v3/manual status, retaining
Claude's committed handoff verbatim. Actual multi-kart spacing cannot be tested
in the current solo build and is deferred to live integration.

## Integration finding: rough pocket inside a paved tunnel

Before installation, Codex found that added exposed-corner clearance space
still inherited the default rough surface. Actual Ironforge v3 coordinate
`(790.1041330568827,1652.2604655230214)` returned grass despite lying inside
the entrance tunnel, clear of all wide-shoulder capsules. The closest narrowed
axis distance is42.0047488, just beyond its individual42-unit capsule but
inside the legal exposed union. This violates the requested all-road tunnel.

The correction tags only explicit all-road narrowed capsules and classifies
valid added-clearance space they cover as road after all boundary checks.
Existing ground fast paths, broad shoulders, plaza/default corners, collision
shape, movement bounds and generated/art data remain unchanged. The exact
actual coordinate and negative shoulder/plaza cases become regressions. This
is a local surface correction, not a new collision or handling system.

## Executed checks

| Command/check | Result |
|---|---|
| `python scripts/test_lua.py --runtime both --tests circuit physics surface ui menu determinism` | PASS: six selected modules in each actual Lua5.1/5.4 runtime;52 files parsed each |
| Final `python scripts/test_lua.py --runtime both --tests circuit physics surface` after the tunnel-corner surface fix | PASS:three modules/52 parsed files per runtime |
| `python tests/test_circuit_boundary.py -q` | PASS:11 analytic tests |
| `python scripts/build_city_tracks.py --wc3 . --geometry-only --check` | PASS: exact generated data for both cities; no extracted archive needed |
| `python scripts/validate_project.py` | PASS:104 paths,24-module TOCs, links and experiment ledger |
| Six changed authoring/validation Python files parsed with `ast.parse` | PASS |
| `git diff --check` | PASS |
| Independent read-only collision diagnostics | PASS:5,960 bounded steps at tunnel joins;279 outside-start recoveries; incoming Lua5.1 circuit and Python10-test suite before the added regressions |

Focused regressions include real tunnel walls/shoulders, ordered city gates,
bounded wall movement, overlapping ranges in either order, last-to-first loop
numbering, copied metadata and unaffected branches. Full suite and full art
regeneration are **NOT RUN by Codex this task**. Claude's full dual-runtime and
byte-rebuild results remain separately attributed in its handoff. Its21,761-
point independent clearance probe is also an author-reported result.

## Preservation, installation and native acceptance

Ignored task root: `local-artifacts/ironforge-v3-integration-20261022/`.
Initial preservation: canonical103 and Claude223 tracked/untracked files,
statuses/HEADs; verified45,610,694-byte all-ref bundle; existing41 installed
files exactlyac4ae23. Only Ironforge's two runtime images change; twelve other
assets and the complete Stormwind definition stay byte-identical.

Ironforge background SHA256:
`c531ceee694b59f142bdbe522d5d86da9f23fe07b6486b6d4dc0c76a3e64ac05`;
preview `8bae79810b4751284e4fd908a56b6301bedf5bc78645e67d3f283fa7e95b8e8d`.
Existing Warcraft III provenance/unresolved redistribution status is retained;
the original procedural meshes are recorded separately. No release/publication
or main merge is part of this integration.

Deployment verified 2026-10-22 16:33 +0200: normal two-parent merge
**82d57eb11e23eb2417a323ba0c714c23514a50af** is installed,41 committed/source/target/
manifest files exact and41 prior files backed up, independently exactagainst
before.csv, preinstall snapshot andac4ae23, no extras. Manifest
`local-artifacts/ironforge-v3-integration-20261022/install-backups/20261022-163127-637-2915c11e90644cd9ae1a21f6037226c3/install.json`; independent
`local-artifacts/ironforge-v3-integration-20261022/deployment-receipt.json`.
Both foreign worktrees'326 files/statuses/HEADs and all prior refs are preserved.
Following deployment documentation changes no addon files. No other-addon or SavedVariables changes. A full
client exit/restart is recommended for the changed textures.

The current Claude handoff quotes the owner's version2 drive and design
requests. **V3 native tests NOT RUN:** both tunnel transitions/width/handling,
lava walls/glow, anvil/pumps, camera and performance. Multiplayer remains
Coming soon. No milestone or content/performance acceptance is inferred.

Next Codex feature: the bounded live-race lifecycle around RaceStart's one-shot
output. The owner may meanwhile try a normal Ironforge drive and report tunnel
or Forge problems; no long probe or new network test is requested.
