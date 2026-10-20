# ADR 0009 — Warcraft III asset reuse

**Status:** Accepted project direction, confirmed by the owner on 2026-10-20 and reviewed by Codex. Supersedes the original-art-only preference in [ADR 0005](0005-asset-and-economy.md) for Warcraft III material. AGENTS and the asset-source ledger are reconciled in `codex/claude-assets-review`; that branch is pending explicit integration into main. This is an art-source decision, not a finding that all redistribution rights are cleared.

## Context

ADR 0005 and AGENTS.md ask for original or owned/authorized art. The [source ledger](../art/ASSET_SOURCES.md) kept WC3Vault models and OpenRealm tooling as references only. On 2026-10-20 the owner told Claude: "Don't be afraid to use wc3 assets like this project has done", citing [WIIIUI](https://github.com/Fiurs-Hearth/WIIIUI). The owner added: "Of course, maintain the agreed upon design guidelines for Azeroth Kart - but we don't necessarily have to reinvent the wheel with everything we do." Suggested sources: [WC3Vault](https://wc3vault.com/assets), [OpenRealm](https://github.com/corepunch/open-realm) and the [warcraft-iii](https://github.com/warcraft-iii) organisation.

## Decision

- Warcraft III material may be used when it fits the agreed guidelines. This covers both game-derived textures, models and UI art and community Warcraft III assets such as WC3Vault uploads. The guidelines are [ADR 0008](0008-mirage-raceway-art-direction.md)'s Mirage direction, strict-overhead rotating sprites (or directional frames), readability at play size, pooled sprites, the 17×31 kart body and existing UI budgets.
- Reuse where it saves real work: terrain, doodads/props, VFX textures, HUD/menu chrome and icons. Original art remains useful where no suitable asset has been found. The [Goblin Drag Car](../art/karts/goblin-drag-car.md) is original; the checked searches did not locate a suitable source, which is not a claim that none exists.
- When a texture already inside the WoW Forever client fits, reference it by path instead of bundling a copy.
- Every bundled file gets a ledger row: path, author/source URL, license or stated terms, permission status, date, use and modifications. Community authors' stated terms and credit requests are honoured.
- Ordinary local research/conversion and visual development may proceed under this accepted direction without asking again whether Warcraft III is an allowed source. Record unresolved rights honestly; a file with explicit incompatible author conditions must not be presented as approved. Public distribution still requires the existing explicit release authorization and a review of bundled files and their status.
- Unchanged: no Mario Kart/Crash Team Racing or other non-Warcraft commercial assets, no betting and no paid advantage. Painted pixels never become collision or checkpoint data.

## Consequences

The [WIIIUI README](https://github.com/Fiurs-Hearth/WIIIUI) and its [texture-path implementation](https://github.com/Fiurs-Hearth/WIIIUI/blob/master/WIIIUI.lua) demonstrate Warcraft III faction-themed art in a WoW addon. No applicable general asset license or Blizzard redistribution grant was established in the inspected root/README. The review did not establish a blanket Warcraft III-to-WoW redistribution permission; WIIIUI is useful technical/community precedent. Blizzard's [WoW Add-On Development Policy](https://eu.forums.blizzard.com/en/wow/t/wow-user-interface-add-on-development-policy/1642) requires compliance with the applicable terms. Attribution and owner project approval must not be mislabeled as a third-party permission grant.

No third-party Warcraft III asset was imported by this policy review; the current drag-car sprite and salt-flat blockout remain original. BLP/MDX conversion and top-down model capture remain unverified pipelines: OpenRealm frame capture and mdx-m3-viewer are leads, not tested tools. Use one small export/client-alpha/facing check for a new pipeline before scaling it to a full roster. Art remains registered to unchanged simulation geometry and pooled performance budgets.
