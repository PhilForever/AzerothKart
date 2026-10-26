# ADR 0021 — Retain selected players after multiplayer races

Status: **Accepted for source implementation**,2026-10-26, under the owner's
request for local placements and same-player Play Again/Change Map. Native
acceptance remains pending.

The previous adapter cancelled its controller at completion, and result actions
opened solo paths. Retain the existing two-peer controller/Core lease for a
bounded300-second postrace interval instead. Expose detached local-observed
results and explicit commands. Reuse INVITE/JOIN/READY/grid/clock with a fresh
next session, preserving peer/roles/kart. Host may offer another supported lap
map. Reject wrap, collisions, exhaustion and old-round packets. No new wire
type, prefix, version or traffic budget.

Local finish releases input immediately. Deliberate Ready/grid/GO capture the
next race. Close results preserves the room; Leave restores solo navigation.
Errors/expiry/combat/world exits close context. This does not resume an aborted
race or automatically capture controls.

Compare exact local finish ticks with the selected peer's validated terminal
tick claim for unverified local placements. Ties share rank, missing finish
stays pending, and multiplayer never enters solo Highscores. No trusted
authority or extra-player support is claimed. The Core lease pauses background
score sends during the bounded room interval. Both players need the update.

Use the [implemented view/actions and short check](../MULTIPLAYER_POSTRACE.md)
for later presentation polish. Preserve duplicate/loss/reentry/exit coverage
and persistent native pacing across rounds.
