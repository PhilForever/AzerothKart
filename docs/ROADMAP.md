# Roadmap — executable milestones and gates

**Not a schedule promise.** Milestones are completed only after measurable acceptance criteria. Codex should complete one small vertical slice per run and update `PROGRESS.md`.

**Owner priority, 2026-10-19:** build playable local mechanics with roughly 80% implementation / 20% focused validation. M0's remaining manual checks are deferred and stay open; they no longer block M1 development. Long probe sessions and repeated broad test matrices wait for a concrete blocker or integration checkpoint. [ADR 0007](adr/0007-build-first-development.md) records this change; multiplayer still requires measured feasibility.

## Phase 0 — prove the client + game loop

### M0. Repository and API proof (OPEN — remaining validation deferred)
- [x] Run Python project validation + Lua syntax/runtime tests; address failures. (2026-10-18: structural validator and complete offline suite in Lua 5.1/5.4; client checks remain open.)
- [x] Confirm actual TOC/interface/flavor and addon load; record build. (2026-10-18 live: 1.60.1/70450, interface 16001, project ID 18, Camelot TOC.)
- [x] Render test window and drive prototype with keys in actual Forever. (2026-10-19: owner completed a near-minute drive; stopped tick 3492, displaced/rotated kart and matching HUD/probe observed. [Evidence](evidence/2026-10-19-m0-client.md); full timing/focus gates remain open.)
- [ ] Verify focus, escape, click-away, chat, combat start, /reload and normal WoW controls restored.
- [ ] Measure frame performance and verify bounded UI allocations.
**Exit:** all results recorded in F1/F2/F5, no taint and no stuck keyboard; offline tests passing in real Lua runtime.

### M1. Deterministic driving model (CURRENT DEVELOPMENT)
- [ ] Decouple physics from UI fully; 60Hz fixed-step baseline and bounded catch-up.
- [ ] Road/wall/grass response and stable collisions across varying FPS.
- [ ] Handling tuning suite: accel, brake, reverse, steering/traction, low-speed assist.
- [ ] Implement drift charge/boost/release with deterministic tests and visible feedback.
- [ ] Wire input loss and combat-interrupted final results/release (ADR 0006); gamepad only if client-proven.
**Exit:** 10k-tick replay equivalence, manual game-feel trials, no unintended inputs.

Current slice: Space-held drift charge, release boost and visible feedback. Implementation progress does not mark the manual game-feel or remaining M0 criteria passed.

### M2. Network feasibility and social handshake
- [ ] `AZKART1` channel capability probe with two real clients.
- [ ] Test 2, 4 and 8 participant budgets when testers are available; record p95 RTT/loss/throttle.
- [ ] Reliable low-rate `INVITE/JOIN/READY/START` control-plane with duplicates/disconnect tests.
- [ ] Document live-race go/no-go and an ADR; if not feasible, switch to Ghost Challenge branch.
**Exit:** evidence-based transport decision, not mere addon-message compatibility.

## Phase 1 — full solo racer

### M3. Playable race, checkpoints and first production track
- [ ] Complete race FSM: menu/countdown/running/paused/finished/aborted.
- [ ] `Mirage Raceway`: dry, pre-flood Shimmering Flats course, walls/surfaces and directional checkpoints; precomposed art with independent geometry ([ADR 0008](adr/0008-mirage-raceway-art-direction.md)).
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
- Remaining M0 manual validation does not block local M1 mechanics development (ADR 0007). M0/M1 acceptance stays open until supported by executed checks; M2 gates live multiplayer investment. M3 is required for any public 'racer' claim.
- If real-time racing is technically infeasible, choose M3/M4/M5/M11, not fabricated netcode.
- Do not claim milestones completed because code exists; require actual tests and product-owner acceptance where relevant.
