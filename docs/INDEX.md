# Documentation index / reading order

**First:** `VISION.md` → `GAME_DESIGN.md` → `FEASIBILITY.md` → `ARCHITECTURE.md` → `ROADMAP.md` → `PROGRESS.md`.

**Engineering:** `CLIENT_API.md`, `PHYSICS.md`, `TRACKS.md`, `MULTIPLAYER.md`, `PROTOCOL.md`, `TEST_PLAN.md`, `SECURITY.md`.

**Parallel development:** [shared instructions](../AGENTS.md), [implemented API contracts](API_CONTRACTS.md), [Codex handoff](handoffs/codex-latest.md) and the Claude-specific `CLAUDE.md` entry point. Agent handoffs are canonical under `docs/handoffs/`; read Claude's latest handoff there when it exists.

**Product delivery:** `UI_UX.md`, `ASSETS.md`, `RELEASE.md`, `AUTOMATION.md`, `DECISIONS.md`, `adr/`.

**Mirage Raceway art planning:** [map and vehicle brief](art/MIRAGE_RACEWAY.md), [asset-source ledger](art/ASSET_SOURCES.md), [accepted direction, ADR 0008](adr/0008-mirage-raceway-art-direction.md), and the [Goblin Drag Car sprite sheet](art/karts/goblin-drag-car.md). These describe planned work; source candidates are not automatically rights-cleared runtime assets.

Docs define planned behavior unless explicitly identified as client-tested. Keep `PROGRESS.md` authoritative for observed implementation status and `FEASIBILITY.md` for reproduced client probes.
