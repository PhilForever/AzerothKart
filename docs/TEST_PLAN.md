# Verification and QA plan

## Testing layers
1. **Static pack validation:** check expected files, TOC file load order, byte limits, docs links and asset completeness via `python scripts/validate_project.py`.
2. **Pure Lua unit tests:** track drivable/undrivable points, steering/acceleration/braking, deterministic run with identical input sequence, bounds and alternate dt behaviors; `lua tests/run.lua`; an optional Linux harness is `python scripts/test_with_lua54.py` (Lua 5.4, not full WoW client).
3. **Simulation property tests (to build):** 10k seeded runs with random but bounded inputs, lap gate order, no teleport-finish, no invalid floats, stable collisions, deterministic hazard events.
4. **Protocol/unit test doubles (to build after M2):** fake transport reorder, duplicate, loss, throttle, sender spoof, malformed/saturated packets, session mismatch and bounded retry.
5. **Manual Forever client tests:** visible load, UI, focus, keyboard controls, combat, reload, zoning, high UI scale, 20-minute continuous play, and 2-client network probe.
6. **Performance regression:** FPS and Lua memory before/during/after 8 visual karts; total UI objects stable after 30 minutes.

## Priority manual smoke suite
- A. Addon shows up with correct TOC and `/akart`; no Lua error.
- B. Press Start Test Drive out of combat, test W/Up, S/Down, A/D and Left/Right; car moves and rotates, stays near oval.
- C. Release keys and move chat focus: no character movement blocked after closing racing UI.
- D. ESC and close button both release game, toggling with `/akart` works; Alt-Tab and `/reload` safe.
- E. Attempt while in combat -> no keyboard capture; if combat begins mid-race no restricted API calls/taint.
- F. Run 15 min, resize UI scale, record FPS and memory. Confirm no per-tick widget creation.
- G. SavedVariables, later milestones: reload/save, corrupt save, migration.

## Network testing (M2, when implemented)
- Distinguish sender enqueue success vs receiver ACK. Send small packets 0.5–4/sec during consented test only.
- Validate 2 players first; then 4; then 8 if realistic. Measure p50/p95 RTT, loss and jitter, throttle returns, message counts, recovery.
- Repeat instanced and non-instanced; record client build, connection, channel, payload bytes and conditions.
- Fail behavior: leave button still responsive, no stale winning result, no infinite retransmits.

## Release blocking bugs
Key capture not released; combat taint; corrupt SavedVariables crashes; lap skips; irreversible stuck state; cheating other players via spoofed packets; unbounded memory/packet sends; accidental prohibited automation.

## Record actual evidence
Never mark tests passed without running them. Include command logs, screenshots if user supplies them, exact client build and reproducible steps in `PROGRESS.md`.
