# Packaging, deployment and release policy

## Current release target (PENDING)

The owner confirmed [ADR 0010](adr/0010-multiplayer-release-priority.md) on 2026-10-20: release follows Codex's mechanical/race/network responsibilities through verified multiplayer and Claude's three ready maps and eight ready karts. Dedicated time trials and ghosts have lower priority and are not prerequisites. This is a scope target, not a release, push, tag, upload or merge authorization. None of the criteria below is marked passed by this planning update.

- [ ] Codex: required deterministic handling, collision, checkpoints/race lifecycle and result reconciliation complete and validated in the integrated release candidate. New solid-obstacle fixtures remain on Test Oval; Mirage Raceway gets none.
- [ ] Codex: actual Forever `C_ChatInfo` transport evidence records sends/receives, loss, throttling, message ordering, latency and a two-client disconnect/reconnect trial. Choose a bounded replication architecture only after the measured gate; no per-frame broadcast assumption.
- [ ] Codex: genuine multiplayer host/join/start/racing/finish behavior and failure handling verified with real clients at the advertised participant count. Test higher counts before advertising them; eight kart assets do not establish eight-player support.
- [ ] Claude: three maps ready, registered to the agreed deterministic track geometry and verified in the target client. The owner-requested three-map count is not fulfilled by an assumed count of current blockouts; record which maps are accepted.
- [ ] Claude: eight selectable karts ready, with correct facing, alpha, animation/tints as applicable and preserved agreed collision footprint. Record the accepted roster; do not infer readiness from files existing.
- [ ] Shared: reviewed integration, required client acceptance, UI/performance budget, compatibility and per-file asset-source/credit review complete; remaining risks stated in the release notes.
- [ ] Shared: clean package/install checks, matching version/TOCs/changelog and explicit owner authorization to publish the reviewed release candidate.

If the real transport gate fails, report the evidence and stop for owner review of the release scope. Ghost challenges are a possible contingency, not completion of this multiplayer release target. The existing [roadmap](ROADMAP.md) retains open acceptance criteria; this checklist does not waive them.

## Developer install

`scripts/install_local.ps1` copies the tested `addon/AzerothKart/` files beneath an explicit, existing **Forever flavor** `Interface/AddOns/` directory. Its target is the `AzerothKart/` child. Supply the parent `AddOns` folder, not the addon folder. The observed developer setup uses `_classic_beta_`; discover the intended installation on the user's machine rather than assuming this path. The helper creates no game path by default and refuses an existing AzerothKart target unless `-Overwrite` is supplied.

From the repository root, preview the operation with the actual authorized AddOns path:

```powershell
.\scripts\install_local.ps1 -AddOnsDirectory 'C:\...\Interface\AddOns' -Overwrite -WhatIf
```

`-WhatIf` performs preflight reads and writes no target, backup or manifest files. The standard `-Confirm` option can prompt before a real operation:

```powershell
.\scripts\install_local.ps1 -AddOnsDirectory 'C:\...\Interface\AddOns' -Overwrite -Confirm
```

Running the helper is a deployment action that requires the session's authorization and any filesystem approval. These examples do not authorize installation, push, publishing or release. Validate source before an authorized install, then reload and confirm TOC loading and `/akart` behavior in the actual client. The fixture suite below does not perform this client verification.

Each real operation gets a unique timestamp/GUID directory under ignored `local-artifacts/install-backups/`. An optional `-BackupDirectory` changes that root; it must remain separate from the source and AddOns trees. The record contains:

- `source.csv`: relative source paths and SHA-256 values.
- `before/` and `before.csv`: the complete prior addon tree and its file hashes, when the target already existed. The backup is hash-verified before the target copy starts.
- `install.json`: source, target, backup path and operation status. `Verified` means every source file matched its copied target hash. `Failed` records a caught error; `Prepared` after interruption means verification did not complete. `Stage`, `BackupVerified` and `TargetCopyStarted` distinguish backup failure from a potentially partial target copy; do not assume every backup path represents a verified backup.

Files are copied by relative path into the target itself, so repeated installs do not create `AzerothKart/AzerothKart/`. Extra target files absent from the source are preserved and reported; inspect the prior-file manifest before any manual cleanup. The helper does not delete files, edit SavedVariables, modify another addon, or automatically roll back. Source/target collisions, overlapping paths and reparse paths are rejected during preflight.

A failure after copying starts can leave a partially updated target. Retain the backup and manifests, inspect the recorded error and compare the relevant files before launching the client. For manual recovery, preserve the current failed target separately, verify the `before/` files against `before.csv`, and copy the saved relative files back into the same addon target. Verify the restored file hashes afterward. Restoring those files does not remove newly added files; review any extras separately rather than deleting the target wholesale. A fresh install has no prior `before/` tree to restore. Recovery remains a deliberate filesystem operation, not a helper guarantee.

The local fixture suite exercises install behavior without using an installed game directory:

```powershell
powershell.exe -NoProfile -File tests/test_install_local.ps1
pwsh -NoProfile -File tests/test_install_local.ps1
```

Use each available PowerShell runtime and record its actual result in `PROGRESS.md`; an unavailable runtime is `NOT RUN`.

## TOC
`AzerothKart_Camelot.toc` and `AzerothKart.toc` are both provided while the live flavor selection is probed. The in-game test must establish actual discovered flavor and TOC priority. Keep duplicate entries synchronized and do not load both in one addon execution.

## Versioning
SemVer for releases and protocol version separately. Pre-alpha `0.0.1` is only a dev scaffold. Preserve migration from schema v1, track hash and physics version for ghost compatibility.

## CurseForge
- Game/version metadata must be correct for WoW Forever; verify CurseForge target support before uploading.
- Do not publish untested multiplayer functionality; tag pre-alpha dev builds accurately.
- Store API token in CI secret (not repo). Project ID is separate from API token.
- Include public screenshots that show the **actual** running addon, not generated mockups presented as game screenshots.
- Package only the final AddOns/AzerothKart folder, not docs/tests/API secrets.

## Deployment safety
No automatic push/upload/release in timed continuation runs unless explicitly configured and authorized. Keep changelog, manual smoke checklist, and rollback instructions.

## IP/trademarks
Original art and Warcraft III game/community material are accepted project sources under [ADR 0009](adr/0009-warcraft-iii-asset-reuse.md). Follow the per-file provenance, source terms, credit and permission-status ledger; owner direction or another addon's precedent is not a general redistribution grant. Keep unresolved status explicit in the release review. "Azeroth" is Warcraft-related IP; the name is a fan-addon working title and should be checked for compatibility with platform policies prior to promotion. State not affiliated with Blizzard.
