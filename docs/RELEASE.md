# Packaging, deployment and release policy

## Developer install
Copy directory `addon/AzerothKart/` into the currently installed **Forever flavor** `Interface/AddOns/AzerothKart/`, confirm TOC loading and `/akart` toggle. An observed Forever developer setup uses `_classic_beta_`, but this is not a universal installation path; discover from user's machine. `scripts/install_local.ps1` accepts an explicit AddOns directory to avoid overwriting other flavors.

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
Use original art, music and track designs. "Azeroth" is Warcraft-related IP; name is a fan-addon working title and should be checked for compatibility with platform policies prior to promotion. State not affiliated with Blizzard.
