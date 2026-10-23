# Review — Claude's Darnassus and Undercity

2026-10-23, Europe/Oslo. Owner explicitly requested review and integration if
approved. Target **91439490703c67ff7e90efbfc74e6eff8b66bc72** on
`claude/darnassus-undercity`, comprising e96044b's implementation and9143949's
developer-machine evidence. Common base6ad66d1. Own integration starts from
1733eac, retaining tested/installed multiplayer runtime eb2055a; reservation381cb46.

## Decision

**Approved for the combined developer build**, with native city verification
pending. Preserve both parent histories in a normal two-parent merge, neither
switching nor modifying Claude's worktree. No main merge, push or release.

- Darnassus: six gates, 3,895-unit loop, 206-unit approach, painted terraces.
- Undercity: five gates, 7,327-unit loop, no approach branch; its spawn is on the
  loop, with the finish131units behind it. Ordered gates prevent an early lap.
- Both use existing Circuit wall/clearance/full-grip semantics. No collision,
  Physics, input, clock, transport or renderer implementation changes arrive.
- Four new TGA files and catalog/preview data expose seven solo tracks and ten
  cosmetic karts. Multiplayer still negotiates only Mirage/Test Oval.
- ADR0015 is accepted only for the painted levels and inert generated height
  arrays. Slopes, crests, bridges and kart-height rendering remain proposals.
  Circuit intentionally drops elevation from its runtime track copy. Physical
  slope handling needs Physics compatibility review; bridges also need route,
  layer membership, collision and replication contracts. No tuning selected.

## Review and integration details

Read Claude's complete canonical handoff, branch diff and source areas. Parallel
read-only reviews covered geometry/gates, asset/pipeline/provenance and menu
compatibility; root inspected both overview/follow-camera review sheets. Roads
are legible and the two palettes distinct; native appearance is not established.
No blocking defect found. Fixed the inaccurate Darnassus “shortest city” claim
(Stormwind is3,831units), stale widget count and the proposal's claim that only
bridges would affect multiplayer. Scoped acceptance does not approve the rest
of the elevation architecture by implication.

The ordinary merge has one README conflict: retain current multiplayer status
and add both new city choices. Menu's14catalog/preview lines, test-menu's narrow
catalog changes, required-file validator entries, API docs and INDEX auto-merge;
their combined diffs were checked against the newer grid build. No whole-file
replacement of Menu/UI/native modules. Claude's authored handoff is unchanged.

New menu regressions cover both cities' deferred saved-selection restoration,
correct preview UVs/sizes and inactive tick-zero state. A refused or throwing
new-city background preserves the existing track, visible image/crop, actual
interrupted result, state/race/clock/laps/checkpoint references, preferences and
widget counts. This retains the guarded selection transaction rather than
loosening it for new data.

## Executed evidence

Actual Windows C:/Python314/python.exe, pinnedLupa2.8/canonical local dependencies:

- `scripts/test_lua.py --runtime lua51 --tests circuit menu ui race_grid session_transport multiplayer_integration`
  **PASS**,59parsedLua files/sixmodules on the final combined source. Includes
  both new routes' gate/wall/full-grip checks plus current grid/profile/cues,
  peer sprites, held GO input, native budgets and complete mocked two-client
  Core/menu/UI/native flow. Pool remains79frames/166textures/81fonts.
- Agent's isolated Claude-source Lua5.1 circuit check **PASS**, plus both new
  maps' current36-unit grid slots on road and inert elevation omission. These
  checks do not add the maps to multiplayer's whitelist.
- Agent's focused combined Lua5.1 menu check **PASS** before root's final run.
- `scripts/build_city_tracks.py --wc3 . --geometry-only --check` **PASS** for
  complete generated CapitalCities. No art extraction/rebuild or file writes.
- `tests/test_circuit_boundary.py -q` **PASS11tests**.
- Read-only three changed pipeline Python AST parses **PASS**; four new TGAs
  have exact uncompressed32-bit BGRA/type2/bottom-left/opaque255 headers and
  lengths:2048-square backgrounds16,777,234bytes each and512-square previews
  1,048,594bytes each. Both city blocks regenerate identically in memory after
  geometry validation. Heights are finite and aligned: Darnassus241points,
  931wallvertices, heights0..44; Undercity456points,1721vertices, heights-30..0.
- Existing three cities' definitions and six runtime image blobs are unchanged.
  Provenance manifests match29models/311placements/58textures and45/325/73;
  WarcraftIII source/build/modifications/credits and unresolved release rights
  remain recorded. No new permission or redistribution guarantee is inferred.
- `git diff --check` **PASS**. `scripts/validate_project.py` **FAIL only two
  pre-existing expired local skill links in historical PROGRESS**, not a pass.
  Current27-module TOCs/requiredpaths/otherlinks/ledger introduce no extra error.
- Preservation audit **PASS**: both foreign worktrees'370files/HEADs/branches/
  statuses unchanged,46existing addon files byte-identicaleb2055a. Only city
  definitions/catalog/Menu catalog/readme differ, with four new art files.

Claude separately reports dual-runtime suites/full exact-picture rebuilds on
cloud and developer machine. Those are attributed author evidence; Codex did
not rerun the full image rebuild, Lua5.4 or broad full suite for this catalog
integration. No WoW automation/native city/latency/FPS result is claimed.

## Remaining limits and handoff

Native loading, look, driving near walls, camera/performance and preferences
remain **NOT RUN**. Undercity's1721boundary vertices and added textures have no
native frame/memory measurement; unchanged widget count is not that evidence.
Long laps remain as authored. The map previews are offline review artifacts.
No slope/bridge behavior, inter-kart contact, trusted result or production
multiplayer gate is completed. Rights review remains a release dependency.

The following Codex handoff/PROGRESS entry records the exact merge/source,
backup/hash-verified install and installed-folder ZIP. Both testers need that
identical combined build and a full restart for new textures. Keep the prior
multiplayer grid fixes intact in any subsequent Claude branch integration.
