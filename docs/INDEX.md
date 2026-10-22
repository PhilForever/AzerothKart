# Documentation index / reading order

**First:** `VISION.md` → `GAME_DESIGN.md` → `FEASIBILITY.md` → `ARCHITECTURE.md` → `ROADMAP.md` → `PROGRESS.md`.

**Engineering:** `CLIENT_API.md`, `PHYSICS.md`, `TRACKS.md`, `MULTIPLAYER.md`, `PROTOCOL.md`, `TEST_PLAN.md`, `SECURITY.md`.

**Current two-player checkpoint:** [accepted experiment scope, ADR 0013](adr/0013-two-player-experiment-scope.md), [reload/fresh-session evidence](evidence/2026-10-21-akt724-akt725-recovery.md) and [implemented control codec](API_CONTRACTS.md#implemented-pure-race-control-codec). No new manual probe is requested; the pure controller and guarded SessionTransport bridge are implemented; the opt-in [start-clock and backend initializer](START_CLOCK.md) are now implemented on the Codex candidate branch. The reviewed solo Menu is integrated on `codex/ui-backend-integration`; multiplayer menu wiring and live-race movement/finish integration follow.

**Session menu bridge:** [public actions and copied view](SESSION_MENU_API.md). Logged two-peer control only; live race follows separately.

**UI/flow:** [ownership assignment](UI_FLOW_OWNERSHIP.md), [Claude roster review](reviews/2026-10-21-claude-roster.md) and the implemented [front-end menus, race HUD and results](art/ui/front-end.md), combined on `codex/ui-backend-integration` (`6cd611a` plus preference fix `9b22f12`; offline-tested, client NOT RUN; [contract](API_CONTRACTS.md#implemented-front-end-menus-race-hud-and-results)). Claude owns presentation/visual flow; Codex owns session semantics and lifecycle.

**Capital Cities Cup:** the integrated [Stormwind City Circuit](art/tracks/stormwind.md) and [Ironforge Grand Prix](art/tracks/ironforge.md) from `claude/capital-cup`, reviewed on `codex/ironforge-integration` (offline-tested; client NOT RUN; [contract](API_CONTRACTS.md#proposed-capital-cities-cup-city-circuits-and-the-course-catalog), [track notes](TRACKS.md#capital-cities-cup-city-street-circuits-proposed-claudecapital-cup)). Four more capitals follow on the same pipeline. Stormwind's reported corner has owner confirmation; Ironforge's native checks remain pending. [Integration review](reviews/2026-10-22-ironforge-integration.md).

**Integration/deployment checkpoint:** [current combined source and synchronization rules](INTEGRATION_STATUS.md). Read this before following an older branch handoff or preparing an install.

**Parallel development:** [shared instructions](../AGENTS.md), [implemented API contracts](API_CONTRACTS.md), [Codex handoff](handoffs/codex-latest.md) and the Claude-specific `CLAUDE.md` entry point. Agent handoffs are canonical under `docs/handoffs/`; read Claude's latest handoff there when it exists.

**Product delivery:** `UI_UX.md`, `ASSETS.md`, `RELEASE.md`, `AUTOMATION.md`, `DECISIONS.md`, `adr/`.

**Current delivery priority:** [accepted multiplayer/release direction, ADR 0010](adr/0010-multiplayer-release-priority.md) and the [pending release target](RELEASE.md#current-release-target-pending). Multiplayer precedes dedicated time trials/ghosts; three maps and eight karts are content targets, not a verified multiplayer participant count.

**Mirage Raceway art planning:** [map and vehicle brief](art/MIRAGE_RACEWAY.md), [asset-source ledger](art/ASSET_SOURCES.md), [accepted direction, ADR 0008](adr/0008-mirage-raceway-art-direction.md), [accepted Warcraft III source direction, ADR 0009](adr/0009-warcraft-iii-asset-reuse.md), [Goblin Mortar Trike kart sheet](art/karts/goblin-mortar-trike.md), [kart roster and Kart button](art/karts/roster.md), [drift and boost effects sheet](art/effects/drift-boost.md), [Goblin Drag Car sprite sheet](art/karts/goblin-drag-car.md), [Mirage scenery-v1 background sheet](art/mirage-background.md) and the [Claude handoff](handoffs/claude-latest.md). The sprite is implemented on the reviewed feature branch; scenery v1, its shadow pass and the trike are reviewed and integrated on `codex/menu-integration`. The owner's [in-game screenshot](evidence/2026-10-20-mirage-scenery-owner-check.md) shows both at spawn. The trike kart follows on `claude/track-ui`, and the owner [approved the trike and the shadow pass](evidence/2026-10-20-trike-and-shadows-owner-approval.md); itemized moving checks are pending. Source candidates are not automatically rights-cleared runtime assets. The Codex handoff records the disposition of Claude's earlier proposals.

Docs define planned behavior unless explicitly identified as client-tested. Keep `PROGRESS.md` authoritative for observed implementation status and `FEASIBILITY.md` for reproduced client probes.
