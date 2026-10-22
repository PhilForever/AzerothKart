# Orgrimmar and stacked kart publication review

2026-10-22 22:56 +02:00, Europe/Oslo. Reviewer: Codex. **APPROVED for feature-branch publication** at exact source `72b362fc4a7926624c5ceaf648056595c8b0e080` (`claude/orgrimmar`). Own documentation branch: `codex/orgrimmar-review`, reservation505ec2e. No production edits or integration merge.

## Scope and findings

Read Claude's complete current handoff and the preceding `claude/kart-roster-wc3` handoff. Reviewed the stacked dependency5c317ea/8cc2031 first, then Orgrimmar7c97c41/5f096dd/72b362f against previous approved1a70d6e. No runtime blocker found.

Four Warcraft III karts use the existing cosmetic sprite/effect contract and unchanged17x31 physics body: Dwarf Car, Orc Demolisher, Meat Wagon and Glaive Thrower. Ten kart choices are pooled at creation. The four additional menu buttons change mock resources to75frames/165textures/80fonts; this is a reviewed creation-time increase, not a per-tick allocation. Asset provenance and unresolved redistribution status remain recorded; publication is not release clearance.

Orgrimmar Canyon Rush uses existing Circuit contracts:2048-square world,4769-unit loop,734-unit approach, four ordered gates, radius56 road/radius76 wall,14-unit exposed-wall clearance and1222wall vertices. Existing fullSpeedToWalls is enabled only for this city. No new global handling or collision algorithm. Claude records owner approval of the alternative blue loop; no additional route decision inferred. Reviewed overview/camera illustrations and all four kart heading sheets. Native readability/handling/performance remain unverified.

Twenty-two critical Lua/TOC files are unchanged, including Physics, Circuit, UI, input, race and session/start-clock/transport modules. Prior Stormwind/Ironforge definitions and all14 pre-existing runtime assets are byte-identical. Staged background loading, preference/Stop/results fixes and narrow-tunnel/corner handling are retained. Optional new painter/renderer features are offline only. Existing default shadow rendering matches the previous implementation in the focused synthetic regression.

## Executed checks

- `scripts/test_lua.py --runtime lua51 --tests presentation circuit menu ui`: PASS,52source/test files parsed and all four modules executed with actual Lua5.1 via pinned Lupa2.8. Ten kart cycles, lifecycle/selection regressions, Orgrimmar gates/approach and mock pool counts pass.
- `scripts/build_city_tracks.py --wc3 . --geometry-only --check`: PASS, exact generated data for all three cities.
- `tests/test_circuit_boundary.py -q`: PASS,11tests.
- Five changed Python files parse. Twenty runtime TGA files pass uncompressed32-bit header, dimensions and exact byte-length checks. Package audit PASS; candidate47runtime files, previous installation41.
- Ignored `local-artifacts/orgrimmar-review-20261022/pipeline_smoke.py`: PASS, six synthetic comparisons covering default-render equivalence and opt-in alpha-shadow cutouts/empty alpha. Receipts: pipeline-smoke.json and package-audit.json in that directory.
- `scripts/validate_project.py`: FAIL on exactly two pre-existing PROGRESS links to an expired local computer-use SKILL.md version. PROGRESS was unchanged in the incoming branch. Documentation portability issue; no runtime/load-order finding. Not reported as a passing validator.
- `git diff 1a70d6e 72b362f --check`: FAIL, one trailing space in docs/art/tracks/orgrimmar.md:21. Nonblocking formatting nit retained in the author's exact branch.

Lua5.4/full broad suites, full art regeneration and actual game-client checks: **NOT RUN by Codex** for this review. Claude's reported two-machine full suites and byte-exact art rebuilds are author evidence only. No new networking experiment or multiplayer acceptance claim. No milestone completed.

## Publication and coordination

Normal non-force push of exact72b362f created origin/claude/orgrimmar; live remote SHA verified. Main remainsf923d15f5cc8f306a0b47ad082587474abd1af8d. No foreign checkout changes, author rewrites, release or installation. Coordination uses branch ancestry and shared handoffs; no direct Claude conversation claimed. Claude can continue on its own branch without synchronizing an integration merge from this review.

The installed addon remains the prior41-file Ironforge-polish source2e75a3d. Orgrimmar and four karts are published source, not installed or game-verified. A future coordinated install must back up and verify the combined47-file source and requires a full client restart for new files. Native menu/art/camera/handling/memory checks remain pending.

Next independent Codex task: bounded live-race lifecycle around RaceStart, preserving the existing transport lease, start-clock and teardown contracts; no repeated low-rate probe prerequisite. Visual follow-up remains Claude-owned.
