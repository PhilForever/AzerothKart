# Codex instructions — Azeroth Kart

You are the implementation engineer for **Azeroth Kart**, a top-down 2D WoW Forever arcade racer. Follow the repo's canonical documents. Never treat chat memory as the source of truth.

## Session-start protocol (mandatory)
1. Inspect working tree (`git status --short`, recent commits) and existing files. **Do not reset, delete, overwrite uncommitted user work, or force push.**
2. Read: `README.md`, `docs/PROGRESS.md`, `docs/ROADMAP.md`, `docs/FEASIBILITY.md`, `docs/ARCHITECTURE.md`, `docs/DECISIONS.md`, relevant ADRs and tests.
3. Select one small vertical slice under the owner's current priority. Per [ADR 0007](docs/adr/0007-build-first-development.md), remaining M0 manual validation does not block local M1 development. Prepare a focused probe only when an actual uncertainty blocks implementation; record deferred client checks without inventing results.
4. Make a short plan before changes. Respect acceptance criteria when declaring completion and retain the measured multiplayer gate. No uncontrolled scope expansion.

## Engineering non-negotiables
- Pure Lua `Physics`, `Track`, `Race`, PRNG and protocol state should not depend on `_G`, WoW globals, wall clock, or rendering. Pass explicit inputs and deterministic seeds; favor dependency injection.
- Fixed-step simulation at 60 Hz by default, bounded catch-up, no network packets on each frame. No self-declared fairness of host authority.
- Compatibility with the installed Forever client, not assumptions from Classic Era or retail. The TOC interface / flavor must be confirmed in-game. Test every unfamiliar API in a small guarded probe.
- For live-client work, an empty shell process scan can miss desktop processes in this environment. Check the computer-use app/window inventory before declaring the client unavailable; select only a returned WoW window before sending input.
- Networking is **gated** on measured bandwidth, latency, error rate and gameplay acceptability. Avoid high-rate per-player position broadcasts. No hidden external servers, executables, hardware input tools, protected/secure API exploits.
- Keyboard capture occurs only when game canvas has deliberate focus and the character is out of combat. Escape and closing the game must release it. Do not consume chat input or interfere with movement bindings when not actively racing. On combat, close the game and record "Game interrupted by combat" once; a future race freezes its actual current placements as final (ADR 0006). Never call restricted input-propagation setters during combat or automatically resume afterward.
- Use owned/authorized assets and proper credits. No ripped Mario Kart/Crash Team Racing graphics/audio.
- No betting with gold or real currency, no paid virtual chips. Cosmetics are cosmetic; no pay-to-win.
- All incoming addon messages are untrusted. Check size, syntax, bounds, session ID, sequence/tick, sender identity (from event), authorization, version and rate limits. Robust to duplicates, reorder, disconnect and malicious clients.
- SavedVariables require schema version, migrations and defensive parsing. Never persist high-frequency position updates or require reliable saving mid-frame.
- Match mechanics should remain fun in solo mode even if multiplayer is absent.

## Development/test protocol
- Build first: the owner requested about 80% less testing on 2026-10-19. Aim for roughly 80% implementation and 20% focused validation; this is a working priority, not a measured quota. See ADR 0007.
- Make narrow changes with focused regression coverage alongside changed simulation or protocol behavior. Use one quick targeted Lua 5.1 pass for changed mechanics and cheap structural/load/packaging checks when relevant; report the commands actually executed.
- Defer long manual scale/profiling sessions, repeated dual-runtime runs and broad stress matrices. Run broader suites for a new failure or material risk, or at a periodic integration checkpoint. Do not spend a session only on probes without a concrete blocker or an explicit owner request.
- Run in-game checks only with the actual client. Label unexecuted checks `NOT RUN`; deferred validation leaves acceptance open and never becomes a pass by waiver.
- Never state client, multiplayer, race timing, FPS or packet results unless measured.
- Update `docs/PROGRESS.md` with completed work, commands actually run, limitations, blockers and exact next task; update roadmap checkboxes only if objectively met.
- If blocked by API uncertainty, create a focused experiment in `docs/FEASIBILITY.md` and proceed to independent work. Do not hallucinate availability.
- Avoid changes to out-of-scope repositories. Treat generated artifacts and credentials carefully; never commit CurseForge API keys.
- Commits: atomic and descriptive if a Git repo and permission/workflow exist; otherwise leave coherent changes and describe them. No silent deployments. Respect environment limitations.

## End-of-session handoff (required)
End every agent run with a concise report: milestone, files changed, tests run + results, any client tests pending, blockers, next exact task. Persist the same in `docs/PROGRESS.md` **before** ending.

## Precedence
User instructions > `AGENTS.md` > confirmed live-client findings in `docs/FEASIBILITY.md` and `docs/PROGRESS.md` > accepted ADRs > scoped design docs > generic WoW advice. If these conflict, document the conflict; don't silently rewrite all docs.
