# ADR 0009 — Warcraft III asset reuse

**Status:** Proposed. The owner gave this direction to Claude on 2026-10-20. Formal acceptance, and reconciliation with [ADR 0005](0005-asset-and-economy.md) and the AGENTS.md asset rule, await owner and Codex review. Until then, existing imports still need their own ledger rows.

## Context

ADR 0005 and AGENTS.md ask for original or owned/authorized art. The [source ledger](../art/ASSET_SOURCES.md) kept WC3Vault models and OpenRealm tooling as references only. On 2026-10-20 the owner told Claude: "Don't be afraid to use wc3 assets like this project has done", citing [WIIIUI](https://github.com/Fiurs-Hearth/WIIIUI). The owner added: "Of course, maintain the agreed upon design guidelines for Azeroth Kart - but we don't necessarily have to reinvent the wheel with everything we do." Suggested sources: [WC3Vault](https://wc3vault.com/assets), [OpenRealm](https://github.com/corepunch/open-realm) and the [warcraft-iii](https://github.com/warcraft-iii) organisation.

## Proposed decision

- Warcraft III material may be used when it fits the agreed guidelines. This covers both game-derived textures, models and UI art and community Warcraft III assets such as WC3Vault uploads. The guidelines are [ADR 0008](0008-mirage-raceway-art-direction.md)'s Mirage direction, strict-overhead rotating sprites (or directional frames), readability at play size, pooled sprites, the 17×31 kart body and existing UI budgets.
- Reuse where it saves real work: terrain, doodads/props, VFX textures, HUD/menu chrome and icons. Original art stays the answer where nothing suitable exists. For example, no Warcraft III drag-car model was found, so the [Goblin Drag Car](../art/karts/goblin-drag-car.md) is original.
- When a texture already inside the WoW Forever client fits, reference it by path instead of bundling a copy.
- Every bundled file gets a ledger row: path, author/source URL, license or stated terms, permission status, date, use and modifications. Community authors' stated terms and credit requests are honoured.
- Unchanged: no Mario Kart/Crash Team Racing or other non-Warcraft commercial assets, no betting and no paid advantage. Painted pixels never become collision or checkpoint data.

## Consequences

Blizzard-owned Warcraft III files carry no explicit redistribution license. WIIIUI ships no license file or Blizzard-asset statement, so it is community precedent, not a grant. Public release scope (for example CurseForge) stays an explicit owner decision, and a release review should list bundled third-party files. BLP/MDX conversion and top-down model capture remain unverified pipelines: OpenRealm frame capture and mdx-m3-viewer are leads, not tested tools. Each new format or source needs a small export spike and a client alpha/facing check before broad use.
