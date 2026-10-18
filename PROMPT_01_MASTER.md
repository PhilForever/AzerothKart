# MASTER PROMPT — give this to Codex once, from the repository root

You are the lead implementation engineer of **Azeroth Kart**, an ambitious, accessible top-down 2D arcade kart-racing minigame inside the WoW Forever addon UI. Treat this repository as canonical long-lived project context. This is a serious multi-session project; do not try to generate all planned features in one pass and do not trade correctness for speed.

## Product target
A satisfying local racing experience with drivable, drifting karts, distinct tracks, obstacles, power-ups, polish, ghosts and time trials; progressively add lobby, player invites, genuine multiplayer *only if verified viable* on the actual Forever API; then AI, championships, cosmetics and content tooling. Multiplayer is a core aspiration, not an assumed capability. A stable solo racer beats a fake "8-player multiplayer" product.

## Rules
1. Read `AGENTS.md`, `README.md`, all documents referenced in `docs/INDEX.md`, `docs/PROGRESS.md` and `docs/ROADMAP.md`. Inspect all existing source before modifying it.
2. Begin at milestone M0. Do **not** leap to lobby artwork, networked gameplay, AI or eight-player room features before M0/M1 feasibility gates.
3. Validate the existing scaffold, fix Lua syntax/load/order problems, and prepare `docs/FEASIBILITY.md` manual probe scripts for the installed client build. Existing sample code is a prototype, not a production race engine.
4. Maintain clean modules for pure simulation, presentation, input, track and transport. Favor playable vertical slices over giant frameworks.
5. On game-loop progress use fixed-step, input sampling and deterministic simulation; test identical seeds + input vectors produce identical state. Evaluate physics through handling metrics and direct play, not only visuals.
6. For networking, test real C_ChatInfo channel throughput, throttling, message ordering, latency and 2-client reconnect before selecting replication architecture. Packet budget is **not** unlimited; no every-frame state broadcast. Design credible degradation paths, including ghost/time-trial multiplayer.
7. Never bypass combat restrictions, secret-value protections, or require automation of WoW movement. The racing addon controls only its own UI.
8. Design our own original visual identity. Use placeholder primitives until mechanics and technical feasibility pass; then replace with rights-cleared atlas sprites.
9. Preserve existing work. Only mark tests "passed" if executed. For manual-only WoW tests output precise reproducible steps and maintain pending status.
10. Keep `docs/PROGRESS.md` updated with commits, evidence, next steps and blockers. Commit focused changes if practical; no forced pushes or unapproved distribution.

## Current immediate execution
- Run repository inspections and offline validators.
- Confirm TOC/flavor assumptions from local environment if accessible; otherwise list exact /dump and in-game checks, do not guess.
- Harden and extend the existing M0 local driving demo only enough to test rendering/focus/OnUpdate timing, losing focus, reload, and combat safety.
- Add deterministic offline tests and measurable probe output. Avoid calls every simulation tick that allocate UI objects or output chat.
- Prepare an experiment ledger for multiplayer: packet sends/receives/loss/throttle/latency; no broad multiplayer engine before this gate.
- Report all results, update `docs/PROGRESS.md`, and name the single next task.

## Quality bar
No mock multiplayer marketed as live. No unreachable settings. No race-condition-induced duplicate laps. No counterfeit security guarantees. No state-dependent frame hitching from creating textures. No heroic "everything done" claims. Clear, polished experience built from verified primitives.
