# Review — Undercity river and city paving

2026-10-23, Europe/Oslo. Owner asks to review/push Claude's latest, then fix
wall sticking and slow parking turns. Target **ee144b5d26fd8522ffdd3b1f7826151a049af074**,
`claude/undercity-river` from505f054; implementation48f571a plus5cccb36/ee144b5
evidence/handoff docs. Own codex/wall-slide starts505f054/reservation04db93e.

**APPROVED** for the combined developer source and requested branch publication.
The source merge preserves both parents. No main merge, release or author rewrite.

## Scope and findings

Read complete Claude handoff and36-file diff. Independent geometry, art/pipeline
and provenance reviews found no blocking defect. Undercityv2 now has a5,797-unit
loop, six gates and1,340wall junctions. Six alternating timber/stone bridges
cross the slime canal, with sharp approaches/exits. They are flat water crossings,
not track-over-track bridges; humps remain painted and no layered physics exists.

Ironforgev4 changes only version and fullSpeedToWalls. Deep comparison retains
all1,682wall vertices, two narrows, routes, gates and spawn. Stormwind, Orgrimmar
and Darnassus geometry are identical. Removing shoulders changes all five city
background/preview images; other model placement/source lists remain except the
documented Undercity redesign and unused Darnassus shoulder texture. Ironforge's
rough strip becomes road, using the existing flag rather than a Physics change.
AGENTS' former v3/rough-policy instruction is updated to record this reviewed
city policy and retain its collision metadata/default rough-mode regression.

Runtime diff is generated CapitalCities data and one Undercity Menu catalog
entry; UI/Presentation/Physics/transport/grid are unchanged. Multiplayer still
negotiates only Mirage/TestOval. The harmless unreachable Ironforge rough label
remains catalog metadata, not a setting promised to players.

## Executed review evidence

- Isolated actual Lua5.1 `circuit race_grid` **PASS**,59parsedfiles, on exact
  Claude source. Both grid slots are on road36units apart on all five cities;
  this is not city multiplayer activation.
- Geometry comparison: otherthree cities identical, Ironforge onlyversion/flag;
  Undercity changes only centerline/elevation/gates/spawn/version/wallVertices.
  Ordered traversal of six gates and wall-free centerline pass offline.
- Two changed Python pipeline AST parses **PASS**. No new risky I/O/network or
  dependency beyond standard-library asin. Painter's wall-to-wall paving uses
  existing Street boundary masks, including tunnel radii.
- All10 changed TGAs: exact type2/uncompressedBGRA32/opaque255/bottom-left,
  2048-square backgrounds and512-square previews, expected lengths. Background
  SHA prefixes match8f48089c/c98c1a54/6ba18ce8/0e1267f7/7868cc3e.
- Undercity overview/nine-camera sheet and paving before/after inspected. Roads
  and water-crossing bridges are legible; no native appearance/performance claim.
- Provenance match:46models/318placements/76textures. Blizzard source/credits,
  modifications and unresolved redistribution rights retained for release review.

Claude reports full dual-runtime suites, exact-picture rebuilds on two machines
and33,720wall-classification probe points. Those remain attributed author evidence;
Codex full art rebuild/new native checks **NOT RUN**. Source review does not prove
the tight bridge turns feel good. Existing structural warnings are the two
historical local skill links, not a passing validator result.

## Requested publication

Windows Git normal non-force dry-run then actual push of **exactee144b5** to
`origin/claude/undercity-river` succeeded. Live remote SHA matches; main remains
f923d15f5cc8f306a0b47ad082587474abd1af8d. Before this push the queried river,
two-city-integration and darnassus-undercity refs were absent; do not repeat the
handoff's unverified claim that Codex previously pushed the combined candidate.
The authored Claude handoff is imported unchanged as historical author prose.
Ignored push logs/live-ref receipt: `local-artifacts/wall-slide-20261023/`.

## Next requested work

Integrate this exact reviewed branch, then one Physics compatibility8 slice for
wall sliding and faster low-speed turning. Preserve geometry/wall clearance,
fixed-step determinism and current multiplayer grid/pacing. Report real handling
as pending until driven. No automatic publication of later physics commits is
inferred from authorization to publish this Claude branch.
