# Codex handoff — Orgrimmar and stacked kart review reserved

2026-10-22 22:47 +02:00, Europe/Oslo. User asks review/push of `claude/orgrimmar`.
Own `codex/orgrimmar-review` starts at pinned72b362f. Review dependency
8cc2031 (four karts) first, then Orgrimmar's three commits. Base1a70d6e is the
previous approved integration. Reserve this named handoff, PROGRESS and a new
review report only; no production changes, foreign-checkout mutations or merge.
Review source/geometry/pipeline/tests, execute focused checks and publish exact
Claude tip only if approved. No main update/release, client test or install is
part of this push checkpoint. Installed41-file build remains separate.

## Previous handoff

# Codex handoff — approved/published Ironforge polish

2026-10-22 17:50 +02:00, Europe/Oslo. User authorized review/push of `claude/ironforge-polish`.
Exact reviewed/published source **2e75a3dc461fd76859b766c95eaab692bfd75282**, from combined bc93753.
Own `codex/ironforge-polish-review` starts at that source; reservation1db81dd.
Only this named handoff, PROGRESS and the review report are edited. No source
changes, foreign checkout edits, merge, reset, force push, main update or release.

## Review and checks

APPROVED: anvil scale1.15→0.575; Warcraft III texture regions on the original
procedural meshes. Only two runtime TGAs change. All39 other addon files,
all Lua/TOCs/tests/generated collision geometry and12 other images remain
byte-identical tobc93753. Stormwind/narrows/private all-road corner fix retained.
Authored helper API adds extraction-root argument at its one updated callsite;
no runtime interface or resource-pool change (71/165/80 remains prior scope).

Executed: `scripts/validate_project.py` PASS104paths; geometry-only generator
`--check` PASS; three Python files parse; whitespace PASS. Independent in-memory
sampler checks PASS130 wrapped/negative UV cases and exact texel/bilinear points;
three meshes/eight headings retain geometry/normals. No Lua suite rerun or full
art rebuild by Codex. Claude's two-machine byte-rebuild evidence is attributed
separately; its full-suite-on82d57eb sentence is inaccurate (we ran six selected
modules perruntime, then three). Keep its authored handoff unchanged and use
[the review](../reviews/2026-10-22-ironforge-polish.md) for this correction.

Minor offline limitation: period scaling on nested bands/emblem textures uses
normalized UVs; delivered art reviewed, no publication blocker. Source/credits
and existing unresolved redistribution status remain explicit; no new release
or broad third-party permission claim. Owner's previous tunnel/lava approval is
quoted by Claude; new textured Forge appearance/performance in WoW NOT RUN.

## Publication, preservation and installation

Normal push published exact2e75a3d to `refs/heads/claude/ironforge-polish` and
live remote verified; main remainsf923d15. Claude's tracked checkout stays on
2e75a3d with its pre-existing untracked outputs. Snapshot329foreignfiles/status/
HEAD and complete46,241,669-byte recovery bundle verified. No direct Claude
conversation is claimed; branch ancestry and shared handoff are the coordination
record. Current Claude work retains our code and can continue from its own
published tip; Codex's local review branch contains the same source plus docs.

Installer PASS41 files from approved source, with prior41-file backup at
`local-artifacts/ironforge-polish-review-20261022/install-backups/20261022-174831-565-c80be06d79a847959274bb136099ff6d/install.json`.
Independent verification PASS: all41 committed/source/target/manifest files
exact2e75a3d;41 backup files exactbefore.csv, baseline and82d57eb, no extras.
Manifest Verified/BackupVerified=true; foreign329 files/statuses/HEADs and all
prior refs preserved. Receipt `local-artifacts/ironforge-polish-review-20261022/deployment-receipt.json`.
Installation is complete; no addon file changes occur in the following
review-documentation commit. No SavedVariables/otheraddon
writes or client input. Full exit/restart recommended for the changed textures.
Ignored evidence root: `local-artifacts/ironforge-polish-review-20261022/`.

Next executable Codex task: pure bounded live-race lifecycle around RaceStart.
Owner may inspect the half-size anvil/textured pumps after restarting WoW; no
additional network probe or broad manual matrix.
