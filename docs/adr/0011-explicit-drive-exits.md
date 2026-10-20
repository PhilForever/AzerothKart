# ADR 0011 — Explicit drive exits

Status: Accepted, owner-directed, 2026-10-20.

## Context

The owner reported accidental stops from stray mouse clicks and unassigned keys, and an unusable Stop button. The global mouse-down handler ended the run and disabled Stop before the button's own OnClick. These were terminal stops, despite the ambiguous "Controls released" result text.

## Decision

- Incidental mouse clicks and unassigned key presses/releases do not stop or pause a drive, clear held controls, or reset drift/race state. Unassigned keys are consumed while keyboard capture is active.
- Stop and Escape deliberately end the run and freeze its partial result. Close ends it and hides the window. Start/Restart begins a fresh countdown; this task adds no pause/resume state.
- Enter/numpad Enter deliberately releases capture for chat. Actual text focus, available application-focus readback, hiding, world leave/logout and combat retain their existing stop behavior. Combat keeps ADR 0006's terminal interruption.
- Global mouse-down registration is no longer needed for capture. Stop stays enabled during countdown/driving; track switching stays disabled until the run ends.
- Results offer Restart, track selection or Close rather than describing a pause as "Controls released".
- Owner follow-up, 2026-10-21: the result panel has its own **Close results** button. Dismissal changes presentation only and survives ordinary Stop/Close/reopen or refused Start; a successful new run or map selection clears it. The outer Close button continues to hide the entire addon.

## Evidence and limits

Offline regressions exercise mouse-down before Stop's OnClick, incidental keys/buttons preserving held input and state, continued simulation, explicit terminal exits, frozen stopped samples and pooled resources. Actual-client evidence belongs in PROGRESS/FEASIBILITY; mocks cannot verify WoW event ordering.

Build 70450 lacks the previously probed application-focus getters. The old Alt/unknown-key stop is removed by this owner direction, so historical idle Alt-Tab observations do not establish held-input focus-loss behavior in this build. Keep that check pending; do not invent a replacement API or automate character movement.

This supersedes the prototype's all-click/unknown-key exit policy. It does not change physics, race timing, track geometry, input aliases or transport gates.
