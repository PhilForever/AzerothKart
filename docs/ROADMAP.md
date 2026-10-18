# Roadmap — executable milestones and gates

**Not a schedule promise.** Milestones are completed only after measurable acceptance criteria. Codex should complete one small vertical slice per run and update `PROGRESS.md`.

## Phase 0 — prove the client + game loop

### M0. Repository and API proof (CURRENT)
- [x] Run Python project validation + Lua syntax/runtime tests; address failures. (2026-10-18: structural validator and complete offline suite in Lua 5.1/5.4; client checks remain open.)
- [ ] Confirm actual TOC/interface/flavor and addon load; record build.
- [ ] Render test window and drive prototype with keys in actual Forever.
- [ ] Verify focus, escape, click-away, chat, combat start, /reload and normal WoW controls restored.
- [ ] Measure frame performance and verify bounded UI allocations.
**Exit:** all results recorded in F1/F2/F5, no taint and no stuck keyboard; offline tests passing in real Lua runtime.

### M1. Deterministic driving model
- [ ] Decouple physics from UI fully; 60Hz fixed-step baseline and bounded catch-up.
- [ ] Road/wall/grass response and stable collisions across varying FPS.
- [ ] Handling tuning suite: accel, brake, reverse, steering/traction, low-speed assist.
- [ ] Implement drift charge/boost/release with deterministic tests and visible feedback.
- [ ] Wire input loss, combat pause/release, gamepad only if client-proven.
**Exit:** 10k-tick replay equivalence, manual game-feel trials, no unintended inputs.

### M2. Network feasibility and social handshake
- [ ] `AZKART1` channel capability probe with two real clients.
- [ ] Test 2, 4 and 8 participant budgets when testers are available; record p95 RTT/loss/throttle.
- [ ] Reliable low-rate `INVITE/JOIN/READY/START` control-plane with duplicates/disconnect tests.
- [ ] Document live-race go/no-go and an ADR; if not feasible, switch to Ghost Challenge branch.
**Exit:** evidence-based transport decision, not mere addon-message compatibility.

## Phase 1 — full solo racer

### M3. Playable race, checkpoints and first production track
- [ ] Complete race FSM: menu/countdown/running/paused/finished/aborted.
- [ ] `Tinker Speedway`: original 2D course, walls/surfaces, directional checkpoints.
- [ ] Three-lap run + race time + best lap + anti-shortcut/checkpoint validation.
- [ ] Race HUD, position/time display, results, restart, short intro tutorial.
- [ ] Safe persistence v1 + schema/migrations and corrupted-save tests.
**Exit:** 20-minute solo session without errors; race cannot be completed by skipping gates.

### M4. Time Trial, ghosts, replay
- [ ] Input tape recording with deterministic seed and physics/track version.
- [ ] Record personal best, show translucent prior run, lap/time differences.
- [ ] Cap save size; import/export with strong validation and user consent.
- [ ] Replay determinism across simulated FPS and queued loading.
**Exit:** repeated ghost replay reproduces checkpoints/times within defined tolerance.

### M5. AI rivals, rubber-band policy, balanced handling
- [ ] Waypoint/spline racing AI; easy/medium/hard skill not cheating through walls.
- [ ] Local races with 2–7 AI controlled karts, avoidance and collisions.
- [ ] UI/performance budget at 8 total karts + varied terrain; fail-safe fallback quality.
- [ ] AI fairness and difficulty user testing.
**Exit:** fun solo race with 4 AI, acceptable FPS; AI laps obey same rules.

## Phase 2 — social racing if M2 GO

### M6. Experimental two-player live race
- [ ] Host/join, state sync, prediction/interpolation, guarded snapshot cadence.
- [ ] Disconnect, resume/rehost policy, desync reporting, finish reconciliation.
- [ ] Test under real in-game transport in several scenarios.
**Exit:** peer-tested lap agreement and acceptable corrections; otherwise remain experimental and pivot to ghosts.

### M7. Private rooms and four-player beta
- [ ] Private room UX, friend invite, ready checks and race configuration.
- [ ] Add one original track and support different surfaces/shortcuts.
- [ ] Controlled 4-player sessions; record host fan-out and rate limits.
**Exit:** 4-player measured go; 8-player only after dedicated performance research.

## Phase 3 — content and core arcade loop

### M8. Items and power-ups
- [ ] Typed deterministic item engine + pickup spawn schedule.
- [ ] Turbo, oil, shield, wrench + fair caps and counterplay.
- [ ] Visual/audio effects; balance/replay tests; disabled for strict time trials.
**Exit:** identical seeded item test results and no infinite stun chains.

### M9. Garage, unlocks, visuals and polish
- [ ] Original kart sprites, cosmetics, particle pooling, animations, UI scaling.
- [ ] Garage, selection previews, accessibility options, sounds.
- [ ] No gambling/transferable coin system.
**Exit:** consistently readable and performant UI, assets provenance documented.

### M10. Grand Prix and progression
- [ ] Multi-race cup scheduling, points/tie break, track playlists.
- [ ] Results and achievements/local stats; unverified multiplayer results flagged.
**Exit:** complete tournament survives expected state transitions; no duplicate awards.

### M11. Ghost challenge social mode (independent of live GO)
- [ ] Share bounded ghost challenges by approved messaging or manual codes.
- [ ] Remote version compatibility, validation and player privacy.
- [ ] Asynchronous leaderboard and result comparison without false trust claims.
**Exit:** friend can race a legitimate peer tape safely on separate session.

### M12. Performance, QA, localization, accessibility
- [ ] Automated simulation test suite, parser fuzz, save migrations, asset lint.
- [ ] Profiling at 30/60/144fps, different resolutions, 20-minute stress tests.
- [ ] Norwegian/English UI strings, control remap, colorblind/readability.
**Exit:** test matrix passed on target client builds and devices; known limitations stated.

### M13. Release engineering and post-launch maintenance
- [ ] CurseForge package with correct flavor/TOC/version, changelog, screenshots.
- [ ] Opt-in CI with Lua static checks, tests, zip validator; publish manually first.
- [ ] Crash/error triage, issue templates and versioned API compatibility checks.
**Exit:** public package verifies clean install, reload, uninstall; no leaked credentials.

## Prioritization policy
- M0 + M1 gate all physics investments; M2 gates live multiplayer investment. M3 is required for any public 'racer' claim.
- If real-time racing is technically infeasible, choose M3/M4/M5/M11, not fabricated netcode.
- Do not claim milestones completed because code exists; require actual tests and product-owner acceptance where relevant.
