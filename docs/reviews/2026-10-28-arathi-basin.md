# Review — Claude Arathi Basin, 2026-10-28

## Disposition

Reviewed Claude3b85407 (geometry ed9ad82 and catalogue01693e5). Owner requests
review and installation if acceptable. The layout is approved after the
registration and the guide correction below. The three-way merge preserves
Codex's installed Warsong v3 history; one index-document conflict was resolved
by keeping both current course descriptions. Claude's original checkout and
existing untracked outputs are untouched. No push/main/release.

## Geometry and presentation

Arathi is a flat Physics12 circuit: five directional gates, two narrowed
bridges, the Stables plaza and solid barn. Both starting positions are clear;
legal-step tapes verify both ways around the barn connect to the west bridge.
A 1,331-position route walk found no wall or guide-ray collisions in the
reviewed original. Heights and relief are visual only; no slope force exists.
The asset headers and SHA256 prefixes match Claude's handoff; source art was
not rebuilt by this review. Native look, handling and performance remain open.

The original guide could point through the barn from reachable (430,1700) with
nextGate3: `Circuit.isDrivable` answers road grip without considering the
expanded solid. This was confirmed with real <=2-unit resolver steps. Codex's
narrow additive `Circuit.isGuideDrivable` checks existing road, perimeter and
inset-expanded solids without changing isDrivable, physics or collision.
`Presentation.clearLine` uses it when available. If no original candidate is
clear, a bounded nearest-route/local-vertex fallback tries to guide around the
solid; the arrow hides if no checked candidate is clear. No UI objects or
per-frame tables are created; native frame cost is unmeasured.

`test_arathi_guide` verifies the original reachable pose, the accessible
southern alternative (335,1600), six other valid poses, target and visible
46-unit rays, unchanged road-grip semantics, no checkpoint mutation, and safe
no-clear fallback. An independent in-memory mutation replacing the new guide
predicate with old isDrivable fails the barn regression. A full 1,000+ step
route/gate walk also checks real target and visible rays. This does not replace
an in-game play or FPS check.

## Registration and compatibility

Arathi geometry1 is enabled for solo and the existing two-player lobby with
race inviteD and score codeB, Physics12 and three laps. Test Oval remains
retired. All prior race/score codes, twelve score contexts, historical saves,
Warsong Physics13, transport cadence and byte budgets are retained.

ScoreSync now handles thirteen active boards, fourteen fixed hexadecimal HELLO
slots including retired O=0: 145 bytes including prefix at the legal maximum,
under the unchanged158-byte ceiling. The former thirteen-slot HELLO cannot
complete catch-up with this build; both peers must update for full sharing.
Exact-context direct NEW admission remains available as before. No save schema
migration or score reset. Community scores remain player-reported copies.

## Executed verification

- Python314 / existing pinned Lupa / PYTHONDONTWRITEBYTECODE=1, candidate
  `scripts/test_lua.py --runtime lua51 --tests arathi warsong circuit ui menu peer_session score_sync score_sharing`: PASS8, 86 parsed before registration.
- Integrated focused pass `--tests arathi arathi_guide warsong circuit presentation ui menu race_protocol peer_session race_grid session_transport multiplayer_integration score_sync score_sharing`: first six modules through UI PASS; menu stopped on an outdated gating-order assertion. Corrected that test to reflect ready rows before gated rows.
- Rerun `--tests menu session_transport multiplayer_integration score_sync score_sharing`: PASS5, 87 parsed. Together with the focused registration and guide checks this covers all14 named modules. The added Arathi test starts two delayed mock clients through the real menu, peer/grid/countdown and flat AZKRUN2 telemetry under the unchanged budget. It is not a native test or proof of a completed multiplayer race.
- Registered full-route guide regression `--tests arathi_guide`: PASS;87 parsed. Registration agent also executed `--tests arathi race_protocol peer_session race_grid circuit warsong`: PASS6. Score agent executed `--tests score_sync score_sharing`: PASS2.
- `scripts/export_score_catalog.py --check`: PASS13 canonical boards. Prior twelve contexts and old saves remain separate. `git diff --check`: PASS.
- Initial install preflight: all91 previous source hashes match installed
  a51b60e;92 files include the retained legacy extra. `install_local.ps1
  -WhatIf`: PASS. Source commit and actual installation receipt follow in
  PROGRESS.

Native driving, guide usability, frame cost, scoreboard delivery and new-map
multiplayer remain NOT RUN. No full48-module or Lua54 repetition, and no art
rebuild by this integrator; Claude's reported passes are attributed to its
handoff. Structural validator's two historical expired links remain open.

## Next

Commit the tested integration, then perform the authorized backed-up,
hash-verified installation and matching friend ZIP. Both players fully restart
for the new textures. Owner tests both barn routes and the bridges; slopes are
visual under the current flat handling model.
