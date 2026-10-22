# Review: claude/ironforge-polish

2026-10-22, Europe/Oslo. User requests review and publication if approved.
Reviewed pinned Claude `2e75a3d`, commits `b34a225` and `2e75a3d`, based on the
published combined `bc93753`. Own documentation branch
`codex/ironforge-polish-review` starts at that source, reservation `1db81dd`.
No merge, reset, edit or branch switch in Claude's checkout.

**Decision: approve the art change for feature-branch publication.** No blocking
code/interface finding. The new image shows the requested half-size anvil and
metal textures on its original procedural geometry and the four pumps.

## Scope and source findings

- Only two runtime files change: Ironforge Background.tga and Preview.tga.
  All Lua, TOCs, tests, generated geometry and twelve other artwork files are
  unchanged. Stormwind, the narrows contract and all-road tunnel-corner fix are
  preserved; this does not alter simulation, input, menu actions or transport.
- Authoring changes are confined to city_meshes.py's region texture samplers,
  the extraction-root argument at its single city_paint.py callsite, and
  anvil scale1.15→0.575 in city_layouts.py. There are no new runtime objects,
  dependencies or per-tick texture loads. Region sampling wraps within the
  chosen rectangle, including negative UVs, then bilinearly filters/tints.
- Existing Warcraft III steam-tank, power-generator and mine-cart texture
  sources are recorded. Original mesh geometry and the existing unresolved
  redistribution status are retained. Source publication is user-authorized;
  no release or general third-party permission claim is made.
- Minor authoring limitation: direct texture paints apply world-unit period
  scaling; paints nested under bands/emblem use normalized UVs. This does not
  block the delivered image. No change is made to Claude's authored source.

## Executed checks and evidence limits

- `python scripts/validate_project.py`: PASS104 paths/TOCs/links/ledger.
- `python scripts/build_city_tracks.py --wc3 . --geometry-only --check`: PASS.
- Three changed Python files parsed with ast.parse: PASS.
- `git diff bc93753 2e75a3d --check`: PASS.
- Independent read-only sampler checks: PASS130 wrapped/negative UV cases,
  exact texel centres and bilinear midpoints; three meshes at eight headings
  retain the prior geometry/normals. Review image inspected at supplied scale.
- No Lua suite rerun: all Lua/geometry/tests are byte-identical to the reviewed
  baseline. The handoff's sentence about a last full run on82d57eb is inaccurate:
  that source received six selected modules in both runtimes, then three after
  the corner fix. A full suite was explicitly NOT RUN at that checkpoint.
  Claude's handoff remains unchanged; this report corrects the attribution.
- Full art regeneration NOT RUN by Codex; Claude separately reports byte-exact
  rebuilds from its extraction on both machines. Native textured-forge
  appearance/performance NOT RUN. Its quoted owner approval covers the prior
  tunnels/lava, not the new textures or comprehensive track acceptance.

Ironforge Background SHA256:
`258bc9be54e6eb6389fff867379c32c4e92c3272f8d05dd354a4dd74a3b918e6`;
Preview `3a46a8f80d46bb19ac459c4511b774bc55bcf2691e43cc851061dd6919dc2143`.

## Publication and continuation

Publish the exact approved `2e75a3d` to `refs/heads/claude/ironforge-polish`
with a normal push and live-ref verification. No force push, main merge, tag
or release. Record the final remote hash in PROGRESS and the ignored receipt.
Preserve Claude's checkout/history/untracked outputs and the installed source
until any coordinated backup/install is independently verified.

Next Codex development remains the bounded live-race lifecycle controller.
Any normal client look after installation should check the half-size anvil
and textured pumps; no new manual network probe or repeated gameplay matrix.

## Verified result

Normal push published exact **2e75a3dc461fd76859b766c95eaab692bfd75282** to
`origin/claude/ironforge-polish`; live remote matches, main remainsf923d15.
Following the user's existing review/push/install workflow, approved artwork is
installed:41 committed/source/target/manifest files exact,41 previous files
backed up and independently exactbefore.csv/baseline/82d57eb, no extras.
Manifest Status/Stage=Verified, BackupVerified=true. Ignored task root holds
published-refs.txt, deployment-receipt.json and the exact backup operation
`install-backups/20261022-174831-565-c80be06d79a847959274bb136099ff6d/`.
Foreign329 files/statuses/HEADs and all prior refs preserved. Only own local
review documentation commits differ from the installed/published source.
Native textured-forge appearance/performance remains NOT RUN; full restart
recommended. No main merge, history rewrite, release or client automation.
