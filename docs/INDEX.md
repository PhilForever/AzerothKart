# Documentation index / reading order

**Latest multiplayer flow:** [postrace local placements and same-player rematch](MULTIPLAYER_POSTRACE.md),
[ADR0021](adr/0021-multiplayer-postrace-room.md). Play Again/Change Map reuse
the selected peer with fresh round sessions; solo actions stay blocked until
explicit Leave. Native verification remains pending.

**Latest score fix:** [automatic native-group and confirmed-racer discovery](AUTOMATIC_SCORES.md) works independently of the still-pending channel cache in source; actual native receipt remains to check. Existing scores are preserved.

**Multiplayer follow-up:** bounded transit-aware opponent forecasts and [the finite group-delivery check](GROUP_DELIVERY.md). Existing ungrouped two-player mode stays available. Eight-racer multicast capacity remains unverified.

**Current courses and multiplayer scope (2026-10-25):** [eight production maps, retired Oval and eight-player transport decision](PRODUCTION_MAPS.md). Seven lap maps are enabled for the existing two-player flow; the new Graveyard sprint is solo. A raid requirement is undecided; native eight-player capacity remains unverified.

**Kart handling:** [three modest profiles and shared leaderboard, ADR 0019](adr/0019-balanced-kart-handling.md),
[current stronger drift payoff, Physics12](PHYSICS.md#current-drift-payoff--physics12),
[actual parameters and offline metrics](PHYSICS.md#implemented-kart-profiles--physics11),
[run-latching API](API_CONTRACTS.md#implemented-kart-handling--physics11).
Native balance/feel remains pending; no collision mass is claimed.

**Current leaderboard work:** [automatic addon-only community scores, ADR 0018](adr/0018-automatic-community-scores.md),
with [implemented discovery, delivery and notifications](AUTOMATIC_SCORES.md).
Actual native roster/delivery verification is still pending. The [server-side store](../services/leaderboard/README.md)
from [ADR 0017](adr/0017-central-score-store.md) is retained but deferred.

**Current single-player work:** [saved solo totals and Highscores](HIGHSCORES.md),
[updated priority/global publication gate, ADR 0016](adr/0016-solo-records-and-global-score-gate.md).
Local records are implemented/offline-tested; actual-client persistence and a
supported global distribution/persistence route remain open.

**Shared score route:** [dedicated channel evidence and simple next check](SCORE_CHANNEL.md).
Build70532 on the owner's private server accepts the native send; delivery is
still unverified. No production score broadcasting is enabled.

**Latest multiplayer follow-up:** [first owner race evidence](evidence/2026-10-23-first-live-race.md), [updated two-player steps](MULTIPLAYER_PLAYTEST.md), and [grid/profile/display contract](API_CONTRACTS.md). Revised native behavior remains pending; current source/deployment is in PROGRESS.

**First:** `VISION.md` → `GAME_DESIGN.md` → `FEASIBILITY.md` → `ARCHITECTURE.md` → `ROADMAP.md` → `PROGRESS.md`.

**Engineering:** `CLIENT_API.md`, `PHYSICS.md`, `TRACKS.md`, `MULTIPLAYER.md`, `PROTOCOL.md`, `TEST_PLAN.md`, `SECURITY.md`.

**Current two-player checkpoint:** [accepted experiment scope, ADR 0013](adr/0013-two-player-experiment-scope.md), [reload/fresh-session evidence](evidence/2026-10-21-akt724-akt725-recovery.md) and [implemented control codec](API_CONTRACTS.md#implemented-pure-race-control-codec). No new manual probe is requested; the pure controller and guarded SessionTransport bridge are implemented; the opt-in [start-clock and backend initializer](START_CLOCK.md) are now implemented on the Codex candidate branch. The reviewed solo Menu is integrated on `codex/ui-backend-integration`; multiplayer menu wiring and live-race movement/finish integration follow.

**Live-race backend:** [implemented lifecycle and pose contract](LIVE_RACE.md). Native ownership/telemetry and deliberate multiplayer menu/canvas activation are wired on the candidate; [simple friend-test steps](MULTIPLAYER_PLAYTEST.md). Native Forever gameplay remains NOT RUN.

**Session menu bridge:** [public actions and copied view](SESSION_MENU_API.md). Logged two-peer control only; live race follows separately.

**UI/flow:** [ownership assignment](UI_FLOW_OWNERSHIP.md), [Claude roster review](reviews/2026-10-21-claude-roster.md) and the implemented [front-end menus, race HUD and results](art/ui/front-end.md), combined on `codex/ui-backend-integration` (`6cd611a` plus preference fix `9b22f12`; offline-tested, client NOT RUN; [contract](API_CONTRACTS.md#implemented-front-end-menus-race-hud-and-results)). Claude owns presentation/visual flow; Codex owns session semantics and lifecycle.

**Capital Cities Cup:** the integrated [Stormwind City Circuit](art/tracks/stormwind.md) and [Ironforge Grand Prix](art/tracks/ironforge.md) from `claude/capital-cup`, reviewed on `codex/ironforge-integration` (offline-tested; client NOT RUN; [contract](API_CONTRACTS.md#proposed-capital-cities-cup-city-circuits-and-the-course-catalog), [track notes](TRACKS.md#capital-cities-cup-city-street-circuits-proposed-claudecapital-cup)). [Orgrimmar Canyon Rush](art/tracks/orgrimmar.md) is Codex-approved and integrated ([review](reviews/2026-10-22-orgrimmar.md)). [Darnassus Canopy Run](art/tracks/darnassus.md) and [Undercity Slime Circuit](art/tracks/undercity.md) are reviewed and integrated from `claude/darnassus-undercity`9143949 (offline-tested; client NOT RUN), with accepted art-only elevation/inert heights and the still-proposed slopes-and-bridges contract ([ADR 0015](adr/0015-track-elevation.md)). [Thunder Bluff Skyway](art/tracks/thunder-bluff.md), the sixth, is proposed on `claude/thunder-bluff` (offline-tested; client NOT RUN), with its painted drop and rope bridges. Stormwind's reported corner has owner confirmation; the other cities' native checks remain pending. [Integration review](reviews/2026-10-22-ironforge-integration.md).

**Scarlet Crusade Cup:** dungeon sprints, proposed on `claude/scarlet-graveyard` for Codex's review: one run from a Scarlet Monastery wing's start to its end, with no road to follow. See [ADR 0020](adr/0020-dungeon-sprints.md), the [contract](API_CONTRACTS.md#proposed-dungeon-sprints-the-scarlet-crusade-cup) and the [track notes](TRACKS.md#scarlet-crusade-cup-dungeon-sprints-proposed-claudescarlet-graveyard). [Scarlet Graveyard](art/tracks/scarlet-graveyard.md) is the first, [Scarlet Library](art/tracks/scarlet-library.md) (on `claude/scarlet-library`) the second [Scarlet Armory](art/tracks/scarlet-armory.md) (on `claude/scarlet-armory`) the third and [Scarlet Cathedral](art/tracks/scarlet-cathedral.md) (on `claude/scarlet-cathedral`) the last. Offline-tested; client NOT RUN.

**Battlegrounds Cup (registered):** [Warsong Gulch](art/tracks/warsong-gulch.md), a three-lap flag run through both bases on two floors, with roofs that fade over the karts and a guiding arrow. Built on `claude/warsong-layout` against Codex's floors/pads foundation ([ADR0022](adr/0022-floors-and-boost-pads.md), [authoring contract](LAYERED_TRACKS.md)); its [presentation contract](API_CONTRACTS.md#two-floor-presentation-warsong-gulch) is integrated from reviewed Claude79792cd. Warsong geometry1/inviteC/scoreW uses Physics13 beside the eleven Physics12 boards, with bounded AZKSCR2 sharing. Native checks remain pending; [current installation](INTEGRATION_STATUS.md). Version 2, laid on the real gulch measured from the owner's client, with a route-following arrow and fading tunnel covers, is proposed on `claude/warsong-v2` ([its contract](API_CONTRACTS.md#warsong-gulch-version-2)).

**Integration/deployment checkpoint:** [current combined source and synchronization rules](INTEGRATION_STATUS.md). Read this before following an older branch handoff or preparing an install.

**Parallel development:** [shared instructions](../AGENTS.md), [implemented API contracts](API_CONTRACTS.md), [Codex handoff](handoffs/codex-latest.md) and the Claude-specific `CLAUDE.md` entry point. Agent handoffs are canonical under `docs/handoffs/`; read Claude's latest handoff there when it exists.

**Product delivery:** `UI_UX.md`, `ASSETS.md`, `RELEASE.md`, `AUTOMATION.md`, `DECISIONS.md`, `adr/`.

**Current delivery priority:** [accepted multiplayer/release direction, ADR 0010](adr/0010-multiplayer-release-priority.md) and the [pending release target](RELEASE.md#current-release-target-pending). Multiplayer precedes dedicated time trials/ghosts; three maps and eight karts are content targets, not a verified multiplayer participant count.

**Mirage Raceway art planning:** [map and vehicle brief](art/MIRAGE_RACEWAY.md), [asset-source ledger](art/ASSET_SOURCES.md), [accepted direction, ADR 0008](adr/0008-mirage-raceway-art-direction.md), [accepted Warcraft III source direction, ADR 0009](adr/0009-warcraft-iii-asset-reuse.md), [Goblin Mortar Trike kart sheet](art/karts/goblin-mortar-trike.md), [kart roster and Kart button](art/karts/roster.md), [drift and boost effects sheet](art/effects/drift-boost.md), [Goblin Drag Car sprite sheet](art/karts/goblin-drag-car.md), [Mirage scenery-v1 background sheet](art/mirage-background.md) and the [Claude handoff](handoffs/claude-latest.md). The sprite is implemented on the reviewed feature branch; scenery v1, its shadow pass and the trike are reviewed and integrated on `codex/menu-integration`. The owner's [in-game screenshot](evidence/2026-10-20-mirage-scenery-owner-check.md) shows both at spawn. The trike kart follows on `claude/track-ui`, and the owner [approved the trike and the shadow pass](evidence/2026-10-20-trike-and-shadows-owner-approval.md); itemized moving checks are pending. Source candidates are not automatically rights-cleared runtime assets. The Codex handoff records the disposition of Claude's earlier proposals.

Docs define planned behavior unless explicitly identified as client-tested. Keep `PROGRESS.md` authoritative for observed implementation status and `FEASIBILITY.md` for reproduced client probes.
