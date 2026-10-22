# Session actions for Claude's menu

**Latest integration:** the owner-assigned native/player flow is now wired on `codex/live-multiplayer-integration`: Core registers `{view=GetView, action=UI.MultiplayerAction}` after menu creation. New live host/listen actions, matching-session GO and copied race views are described in [LIVE_RACE](LIVE_RACE.md#implemented-native-and-player-flow-integration); [friend-test steps](MULTIPLAYER_PLAYTEST.md) are available. Actual Forever racing is NOT RUN. Older unwired notes below retain the previous API checkpoint scope.

Codex owns the behavior and native transport; Claude owns screen layout, navigation, copy and polish. This is the experimental two-peer control layer on the combined83c611c baseline. No multiplayer menu or live race is implemented by loading it. Use dot calls on `AzerothKart.SessionTransport`; never read/write a private controller or drive Physics/Race from screen transitions.

## Public actions

| Call | Purpose |
|---|---|
| `Host(completePeerName, freshCode, trackId)` | Explicitly select one peer, supported track and fresh6-uppercase-alphanumeric code; queue an offer. Fixed3laps and actual source compatibility versions are supplied by the backend. |
| `Listen(completeHostName, freshCode)` | Explicitly opt in to that host/code. No discovery or unsolicited-peer negotiation. |
| `Join()` | Accept the compatible received offer. Listening alone does not consent to join. |
| `Ready(true/false)` | Declare local readiness in the lobby, one pending operation at a time. |
| `Start(startTick, seed)` | Host proposes backend-supplied parameters only after both ready and local readiness acknowledged. This sends control data; it does not start a race or agree clocks. |
| `Leave()` | Close locally and schedule at most one bounded paced best-effort peer notification. |
| `GetView()` | Fresh copied snapshot for display; no registration, sends or UI objects. |

Actions return `true` or `false, fixedReason`. Revalidate on every action; a displayed capability is not a guarantee that the native API/combat/chat state still permits it. Show local pending/error feedback rather than inventing peer acceptance. Preserve full first name/surname, punctuation and UTF-8; no realm suffix or first-name-only matching. Invalid input never registers or sends.

A Join screen first arms `Listen`, then displays the compatible offer and invokes `Join` only on deliberate acceptance. For this bounded experiment the guest should listen before the host sends; invitation retries are finite. Code reuse is refused within the addon lifetime (64accepted sessions max), and reload does not make an old code safe. The code is a public correlation token, not a password. No new user command/probe/download is requested by this API checkpoint.

Start's tick/seed belong to a future backend race coordinator. Do not add technical tick/seed settings to the player UI or present this phase as a playable shared race. Native session control is a foundation for the next live integration. `TakeStartProposal()` is reserved for that backend coordinator, yields a copied proposal once and must never be consumed by rendering.

## Copied view and flow

Read `phase`, `role`, `peer`, `session`, `offer`, readiness/confirmation, pending operation/attempts, reason/startStatus and action capabilities from the snapshot. Use `canHost/canListen`, `canJoin`, `canSetReady`, `canStart`, `canLeave`; `transportBusy` covers final notification draining as well as active control. The pure controller's phases are idle/listening/inviting/invited/joining/lobby/starting/closed. A fresh host becomes inviting directly through Host. Starting means received/awaiting_ack/acknowledged parameters, never atomic GO. Closed keeps diagnostics and needs deliberate fresh arming.

The view also includes routeWHISPER_LOGGED, fixed lastError and copied traffic counters; counters are local attempted/accepted API accounting, not measured delivery or capacity. Read views on actions and at a modest menu refresh cadence (e.g.5Hz), outside simulation ticks. Do not mutate or retain a snapshot as a live object. No textures, widgets, chat output or per-packet notifications are created by this adapter.

## Runtime ownership and cleanup

Core routes native CHAT_MSG_ADDON_LOGGED and lifecycle events to both adapters. An exclusive frame lease permits only the measurement probe or session transport at once; neither's inactive Stop may detach the other. The standalone AZKART1 probe retains its experimental schedule and never becomes a race channel. Session traffic uses AZKART2 with strict existing logged API/enums and no unlogged/ordinary-whisper fallback.

All session control, ACK, retry and cancellation attempts share a persistent local0.5second spacing,2calls/158payload-plus-prefixB rolling1second limits. Both compliant endpoints therefore stay within pair4calls/316B working ceilings before unmeasured overhead. The current packets are11–23bytes plus7prefixbytes. Budgets persist across new controllers. This is an addon-owned candidate budget, not a limit on other addons or measured network capacity; the standalone probe is an exclusive separate experiment.

Combat/world/logout, accepted solo Start, blocked/unreadable APIs/clocks and send refusal stop control, discard pending output/proposals and release only its own lease. No automatic resume/rejoin. Leave/remote cancel may retain the lease for a final bounded best-effort packet; new Host/Listen waits until that drain is done. GUI Close/Leave in the future multiplayer flow should deliberately call Leave; existing local canvas navigation is not a session state write.

Native AZKART2 registration/delivery, both-client menu flow, clocks/authority/start/finish/race feel and full socket recovery remain NOT RUN at this checkpoint. Source tests with mocks do not replace those checks. [API_CONTRACTS](API_CONTRACTS.md), [UI ownership](UI_FLOW_OWNERSHIP.md) and [PROGRESS](PROGRESS.md) remain authoritative.

## Additive coordinated-start candidate

The original actions above remain compatible. [START_CLOCK](START_CLOCK.md) adds explicit `HostCoordinated/ListenCoordinated`, the existing deliberate `Join/Ready`, and host `PrepareStart(seed?)`, with copied `coordinated/clock/canPrepareStart` fields. `canStart` is false in coordinated mode; do not invoke legacy Start there or add raw tick/seed settings. The clock phase reports calibration/prepare/commit/armed or a fixed failure. A lost final ACK does not prove both peers are armed.

`TakeRaceStart()` is reserved for the future backend live controller, never rendering or screen navigation. It yields actual tick-zero state once at mapped GO; it does not open the racing UI or display an opponent. Existing solo UI.Start must not be used to activate it. The backend source is installed in the combined developer build (see INTEGRATION_STATUS); it remains unwired to multiplayer menus and has no live-race activation. Claude's menu work must preserve its shared TOC/loader/docs additions. Actual clock/menu/racing checks are NOT RUN. No additional manual probe/download is requested.

## Live bridge action names

`bridge.action(name,...)` delegates to UI.MultiplayerAction with names host(peer,code,trackId), listen(peer,code), join(), ready(bool), start() and leave(). It returns true or false/fixedReason; call with dot syntax. Display capabilities are refreshed/revalidated on every click, and EditBox focus is cleared first. A view-only bridge remains supported and disables all commands. Ready loads the offered supported map and arms eligibility; start invokes PrepareStart, never UI.Start. The native API uses HostLive/ListenLive; UI.OnUpdate alone calls AdvanceLive. Menu/canvas rendering consumes copied views only. Opening/back navigation never readies or starts; deliberately leaving the lobby calls Leave. Finishing is local and unverified, with no winner assertion.
