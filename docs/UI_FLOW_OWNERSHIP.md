# UI and multiplayer-flow ownership

Decision recorded 2026-10-21, following the owner's request to review Claude's commits and assign the next work. This refines the existing split; it does not transfer simulation ownership.

| Area | Responsible agent | Boundary |
|---|---|---|
| Screen layout, navigation, labels, status messages, HUD, animations and visual polish | Claude | Design the menu/invite/lobby/ready/starting/results presentation. Consume the shared session view and invoke public commands; do not invent session phases or write authoritative state. |
| Session state, allowed transitions, ready/start rules, button command semantics, retries/timeouts, transport and teardown | Codex | Implement and expose valid commands/capabilities. Preserve explicit Stop/Leave/Close, input release and combat/world/logout behavior. A screen transition cannot start a race by itself. |
| Public view/command contract, integration, allocation/latency budgets and final flow review | Shared | Agree on the interface before wiring the menu. Review enabled/disabled controls, error/cancel paths and preservation of local results. |

Claude owns the roster review fixes in [the review record](reviews/2026-10-21-claude-roster.md). Its branch is held for those fixes and later reviewed integration; no automatic merge or installation occurs here. Codex proceeds independently with PeerSession.

The controller's `view` must return copies for presentation, including role/phase, readiness, pending operation, start-proposal status and action capabilities. Claude maps these to screens; Codex determines whether commands are permitted. The implemented signatures and fields are recorded in [API_CONTRACTS](API_CONTRACTS.md). No separate multiplayer menu exists yet, and existing `UI.lua` function reservations in AGENTS still apply.

The first presentation task after the controller/adapter contract is ready is an explicit Host / Join flow with peer identity, selected track, ready state, pending/timeout feedback and Leave. Show only actions the backend supports. Usable multiplayer settings and live race activation follow reviewed integration; placeholder lobby activity is not evidence of another player.
