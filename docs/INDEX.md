# Documentation index / reading order

**First:** `VISION.md` → `GAME_DESIGN.md` → `FEASIBILITY.md` → `ARCHITECTURE.md` → `ROADMAP.md` → `PROGRESS.md`.

**Engineering:** `CLIENT_API.md`, `PHYSICS.md`, `TRACKS.md`, `MULTIPLAYER.md`, `PROTOCOL.md`, `TEST_PLAN.md`, `SECURITY.md`.

**Parallel development:** [shared instructions](../AGENTS.md), [implemented API contracts](API_CONTRACTS.md), [Codex handoff](handoffs/codex-latest.md) and the Claude-specific `CLAUDE.md` entry point. Agent handoffs are canonical under `docs/handoffs/`; read Claude's latest handoff there when it exists.

**Product delivery:** `UI_UX.md`, `ASSETS.md`, `RELEASE.md`, `AUTOMATION.md`, `DECISIONS.md`, `adr/`.

**Mirage Raceway art planning:** [map and vehicle brief](art/MIRAGE_RACEWAY.md), [asset-source ledger](art/ASSET_SOURCES.md), [accepted direction, ADR 0008](adr/0008-mirage-raceway-art-direction.md), [accepted Warcraft III source direction, ADR 0009](adr/0009-warcraft-iii-asset-reuse.md), [Goblin Drag Car sprite sheet](art/karts/goblin-drag-car.md), [Mirage scenery-v1 background sheet](art/mirage-background.md) and the [Claude handoff](handoffs/claude-latest.md). The sprite is implemented on the reviewed feature branch; scenery v1 and its shadow pass follow on `claude/track-ui`, awaiting review. The owner's [in-game screenshot](evidence/2026-10-20-mirage-scenery-owner-check.md) shows both at spawn; moving checks and the shadow pass are pending. Source candidates are not automatically rights-cleared runtime assets. The Codex handoff records the disposition of Claude's earlier proposals.

Docs define planned behavior unless explicitly identified as client-tested. Keep `PROGRESS.md` authoritative for observed implementation status and `FEASIBILITY.md` for reproduced client probes.
