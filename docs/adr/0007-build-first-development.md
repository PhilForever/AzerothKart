# ADR 0007 — Build-first local development

**Status:** Accepted owner direction, 2026-10-19.

## Decision

The owner requested: "reduce the amount of testing by 80%, lets build, and test later."

Prioritize playable local implementation, aiming for roughly 80% building and 20% focused validation rather than a strict per-session quota. Remaining M0 manual checks no longer block local M1 mechanics work. The immediate slice is Space-held drift charge, a release boost and visible feedback.

For changed mechanics, use one quick targeted Lua 5.1 pass with relevant regression coverage. Use cheap structural/load/packaging checks when the change needs them. Defer long manual scale/profiling sessions, repeated dual-runtime runs and broad stress matrices until a concrete failure or material risk calls for them, or a periodic integration checkpoint. Avoid probe-only sessions without a concrete implementation blocker or an explicit owner request.

## Boundaries

M0 remains open. Deferred or unavailable checks are **NOT RUN**, never passed by waiver; milestone completion still requires its acceptance evidence. Preserve deliberate addon input capture, Escape/close release, combat interruption behavior and data integrity.

The actual multiplayer measurement gate remains mandatory before live-race architecture or gameplay. This direction does not authorize speculative networking, lobby/AI scope expansion, fake multiplayer claims, or bypassing client restrictions.

This changes the prior requirement to complete every M0 manual gate before investing in local M1 mechanics. It does not erase earlier results or unresolved scale findings; those remain recorded for later validation.
