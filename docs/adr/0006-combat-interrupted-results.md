# ADR 0006 — Combat ends the game with interrupted results

**Status:** Accepted product rule, confirmed by the owner on 2026-10-18. Actual-client behavior remains subject to [the M0 checklist](../../tests/MANUAL_CLIENT_CHECKLIST.md).

## Decision

When combat interrupts an active game, close the racing window, stop simulation and release addon input. For a race with standings, freeze its actual current placements at the first handled combat interruption and finalize those placements once. Label the outcome **"Game interrupted by combat"**. Repeated combat notifications must not replace the snapshot, duplicate results or award anything twice.

Combat ending must not reopen the window or resume the interrupted game. A deliberate reopen must retain the interruption note; any later game requires a fresh explicit start. Continue to reject starting while already in combat.

This resolves earlier generic references to pausing/resigning on combat. [ADR 0003](0003-input-combat-safety.md) still governs deliberate input capture and respecting restricted API behavior. The rule changes the game outcome; it does not authorize bypassing combat restrictions or controlling the WoW character.

## M0 scope

The current one-kart test drive has no race state, lap adjudication or placements. Its implementation should close the window and record the interruption once for the active drive, retaining the note through hide/reopen in the current addon session. It must not synthesize a first-place result. Real standings and terminal result records belong to the later race milestone.

Offline lifecycle tests can check closure, stopped ticks, cleared held input, retained reason and duplicate handling. Live acceptance must additionally establish that ordinary WoW controls work during and after combat, no restricted-action errors or taint occur, and ending combat does not resume capture. Only executed checks may be marked passed.

## Multiplayer boundary

The intended race rule applies when a participating player's combat interruption becomes known to the race. Current code detects only local combat and has no transport. Detecting another player's combat and reconciling interrupted standings across clients require a verified transport and a later protocol decision. Do not promise instant cross-client detection or invent synchronized placements before those capabilities exist.
