# ADR 0014 — Experimental start clock before live racing

Status: Implemented candidate on `codex/start-clock`, 2026-10-21; shared integration and actual-client acceptance pending. Extends the bounded scope of [ADR 0013](0013-two-player-experiment-scope.md); no production replication architecture or release approval.

## Context

Control START carries parameters, with no time epoch. Starting the existing solo countdown independently on packet arrival would inherit network delay and dropped simulation time. Recorded RTT near 700 ms makes that an unsuitable implicit synchronization method. Existing control deadlines and the single native output budget must remain explicit.

## Candidate decision

Keep legacy APIs unchanged and add explicit coordinated arming/start actions. Use a separate versioned clock prefix through the same native lease, output spacing and byte/call accounting. Three four-timestamp samples remove guest queue time and produce an offset interval; they do not prove symmetric latency or a shared trusted clock. Negotiate a future epoch with PREPARE/COMMIT ACKs, bound deadlines and allowable callback lateness, and yield an exactly-once backend Physics/Race initializer at GO. Menu navigation and rendering do not consume that initializer.

Do not claim atomic start: a lost final ACK/cancellation can leave one endpoint armed. Conservative calibration refusal, ambiguous peer status and callback lateness remain visible. Clock offset is assumed approximately constant during the bounded exchange; actual drift and race feel require client evidence. Existing local input, geometry, solo countdown, visuals and installed build remain unchanged.

## Consequences

This provides a testable start boundary, not live multiplayer. The next controller must establish race transport ownership while preserving persistent budgets, local fixed-step behavior and read-only remote presentation. Movement replication, authority/correction, shared results and full reconnect remain open. [START_CLOCK](../START_CLOCK.md) records exact implemented APIs, bounds, failure behavior and pending evidence. No milestone acceptance follows from source/mock tests.
