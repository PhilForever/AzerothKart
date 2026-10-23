# Review — latest Undercity lighting

2026-10-23, Europe/Oslo. Owner explicitly asks to push Claude's latest update.
Reviewed **e83c8895c3d8032a7cdf941915e5ff99971d5f52**, comprisingf0810ca and
e83c889 after already-reviewedee144b5 on `claude/undercity-river`.

**APPROVED.** Runtime delta is exactly Undercity Background/Preview. No Lua,
track geometry, collision, input or multiplayer implementation changes. The
optional offline painter grade dims/cools distant scenery, adds light pools
and preserves the course's readability. No new imported assets. Existing
Blizzard source/provenance and unresolved release rights remain documented.

Read full canonical handoff and eleven-file diff. Independent read-only review
inspected before/after nine-camera sheets, parsed both changed Python scripts
and verified exact TGA dimensions/formats/lengths. Both remain uncompressed
32-bit type2,2048-square background and512-square preview. Background SHA256
`caedb2c95289df2250faa2d72b08417bfe7c0892701c881e249ea5094be2de8e`,
preview `70eb25c5edf42dfaed2baa3fd7e672ec5ae8e208281193ae444942f22bdea107`.
Road/bridge detail remains visible in the offline sheets; client look/load/FPS
and full image rebuild are NOT RUN by Codex. Claude's reported two-machine
exact rebuild remains attributed author evidence, not our execution.

Windows Git normal fast-forward dry-run then actual push updated the existing
`origin/claude/undercity-river` fromee144b5 to exacte83c889. Live SHA verified;
main remainsf923d15f5cc8f306a0b47ad082587474abd1af8d. No force/main push/release.
Ignored logs and before/after live refs: `local-artifacts/wall-penalty-10-20261023/`.

The clean two-parent source integration retains current Physics10 tuning and
every current native/UI/geometry module. Canonical Claude handoff is imported
unchanged; its older publication prose is not used as Git evidence. The foreign
checkout is never switched or edited. Latest install/package is recorded in
PROGRESS and the Codex handoff. Fullrestart is required for the changed textures.
