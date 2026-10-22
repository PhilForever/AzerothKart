# Codex handoff — Ironforge v3 narrows reviewed

2026-10-22 16:24 +0200, Europe/Oslo. Branch `codex/ironforge-narrows`; base d5817a8,
reservation69dc2dd, incoming Claude9461f9c. Normal two-parent source merge is
prepared; commit/installation evidence will follow. No push, main merge,
release or milestone completion.

## Scope and contract

Reviewed the complete current Claude handoff and all three commits. Accept
optional `narrows={name?,first,last,wallRadius}`: 1-based closed-loop segments,
minimum radius on overlap, independent copied metadata; branches/plazas remain
unchanged. Shared per-segment radii drive runtime capsules, exposed vertices and
painted walls. Generic radii above roadRadius retain shoulders; Ironforge's42
has none. Circuit's existing endpoint/radial movement model remains; no new
continuous curved-wall sweep or kart collisions. API_CONTRACTS is authoritative.

Ironforgev3: segments75–86 and120–131 reach42 / painted56; 1,682 junctions.
Existing wider street reach76/rough shoulders, gate-hall correction, route,
seven gates and spawn preserved. Lava ridges/grey wedges removed, dark walls
and glow retained; anvil/pumps composited offline by new city_meshes.py. Menu
facts change only; no UI/global Physics/controller/network behavior change.
Stormwindv3/full-speed definition and twelve other images stay byte-identical.
Claude9461f9c handoff imported verbatim; its quoted owner's v2 drive is not a
v3 client pass. Code scope was factory/helper/generator/data/art and focused
regressions/shared docs. Other-agent checkout/source/reservations untouched.

Codex additions: overlap, closing-segment, copied metadata and unaffected-branch
regressions; private all-road-narrows surface flag fixes a confirmed tiny rough
pocket in valid exposed-corner space without changing wall geometry or wide
shoulders; exact actual coordinate/default-rough/wall negative regressions;
Python boolean index/radius refusal; accurate generic shoulder
comment; city_meshes.py required by validator. No new feature beyond reviewed
Claude geometry/art integration. UI pool71/165/80; two scenery slots still may
retain32MiB raw city pixels plus previews/native overhead (unmeasured).

## Executed validation

- `python scripts/test_lua.py --runtime both --tests circuit physics surface ui menu determinism`:
  PASS six modules/52 parsed files each in actual Lua5.1/5.4 via pinned Lupa2.8.
- Final `--runtime both --tests circuit physics surface` after the rough-pocket
  fix: PASS three modules/52 parsed files each.
- `python tests/test_circuit_boundary.py -q`: PASS11.
- `python scripts/build_city_tracks.py --wc3 . --geometry-only --check`: PASS.
- `python scripts/validate_project.py`: PASS104 paths,24-module TOCs/links/ledger;
  six Python authoring files parse, whitespace PASS.
- Independent diagnostics PASS5,960 bounded join steps and279 outside-start
  recoveries. Claude's full tests/art rebuild and21,761-point probe are
  separately attributed; Codex did not repeat the full suite or art rebuild.
- Verified all-ref bundle45,610,694bytes; foreign snapshot103canonical/223Claude
  tracked/untracked files and statuses/HEADs unchanged. Baseline41 installed
  files exactac4ae23. Ignored task root:
  `local-artifacts/ironforge-v3-integration-20261022/`.

## Deployment and remaining work

Installation pending committed combined source,41-file backup and independent
source/target/manifest verification. No other-addon/SavedVariables changes or
client input. Full exit/restart recommended for replaced textures. V3 tunnels'
width/handling, Forge/lava appearance, camera and performance NOT RUN in WoW.
Actual multi-kart spacing must wait for live racing; current build is solo.
Multiplayer UI remains Coming soon and both city compatibility IDs remain
unsupported by SessionTransport. No manual network test requested.

Claude should start future visuals from the completed integrated branch using
a separate feature branch after checking its worktree; Codex has not switched
or synchronized that checkout. Preserve narrows/clearance metadata and generate
CapitalCities with this pipeline, retaining Stormwind's full-speed policy.

Next Codex executable task: pure bounded live-race lifecycle around RaceStart's
one-shot output. Owner may try a normal Ironforge drive after installation and
restart, focusing on the two tunnels and Forge. Detailed source review:
[Ironforge narrows](../reviews/2026-10-22-ironforge-narrows.md).
