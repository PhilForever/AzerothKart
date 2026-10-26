# Scarlet integration — collision, scores and reviewed content

## Source and scope

Owner authorized both fixes and the ensuing GitHub publication on2026-10-26.
`codex/scarlet-integration` combines Codex `2f04f3a` (reservation `1ae33e6`)
with reviewed Claude `ea4425d`, preserving both histories. It includes Library,
the drive fixes, Armory and Cathedral. Claude's four branch tips stay unchanged.
The four conflicts in API_CONTRACTS and catalogue/menu/dungeon tests were
resolved without restoring Test Oval or dropping either side's assertions.

There are eleven active solo/score courses and seven existing two-peer lap
circuits. All four Scarlet sprints remain solo. Thunder Bluff and Graveyard
use geometry version2; old saved contexts remain intact. The current opponent
turning, group/known-peer discovery, Physics12, wall penalty and native traffic
runtime files are byte-unchanged from the Codex integration base.

## Closed review findings

### Swept round-pool collision

Dungeon now finds the first entry into an expanded disc using a stable
quadratic root. It participates in earliest contact with boxes/perimeter.
Remaining inward normal movement is removed while tangent movement remains.
A tiny backoff follows the clear incoming segment; a radial nudge was rejected
because it could enter a neighboring box. Exact tangencies and outward rim
movement remain free. Rectangle-only tracks retain three contact iterations;
tracks with discs allow eight, dropping unused remainder safely at that bound.
No new per-step tables, UI objects, callbacks or Physics changes.

The former Cathedral4.3-unit reproduction now reports `hit=true`; its resolved
straight-segment minimum clearance is158.003751800 against required158.
Tests cover360 rotated shallow grazes, long crossings with clear endpoints,
both directions, inward/outward rim movement, exact tangency, randomized
segment clearance, circle/box corners, escape and equal-time contacts in both
solid-list orders. The original route/room/rectangle checks remain.

### Bounded L/A/C score sharing

ScoreSync appends L/A/C to stable M/S/I/D/R/U/T/G meanings. It admits eleven
active contexts and twelve digest slots. Retired O is required to be zero by
both encoder and decoder, so the maximum legal HELLO including prefix is155
bytes, within the unchanged158-byte native ceiling; Physics12 max is147.
Malformed/nonzero retired hashes and older nine-slot HELLOs are rejected.
Existing exact-context direct NEW-before-HELLO behavior and saved retired
history remain supported. No protocol prefix/version, cadence or budget rise.

Pure controller tests catch up every board. Native-adapter mocks now catch
up all eleven actual production contexts and publish new L/A/C finishes at
the existing pace. All four sprint contexts have lapCount1. The generated
service catalogue contains eleven boards, excluding retired Oval.

## Executed validation

- Actual `scripts/test_lua.py --runtime lua51`: **PASS**, all43 modules and
  80 parsed Lua source/test files. An initial run exposed a stale fixture
  expecting Library to be unavailable; it now tests an unknown course and
  positively verifies the three newly available sprint contexts. No production
  guard was relaxed. The corrected full suite passes.
- Focused geometry/score-sync checks and combined score-sharing/UI/menu/circuit/
  multiplayer integration: **PASS**. Independent read-only review found no
  remaining blocker in either fix, conflict resolution or preserved systems.
- `python -m unittest discover -s tests -p "test_*.py"`: **24 PASS**.
- `scripts/export_score_catalog.py --check`: **PASS**, eleven boards.
- Both TOCs: identical36-module lists, all files present. Six new runtime TGA
  files: expected dimensions, raw lengths,32-bit uncompressed format and SHA256
  equal to the reviewed Claude files. Source runtime has83 files.
- `git diff --check` and staged diff check: **PASS**. The structural validator
  still reports only the two historical expired computer-use skill links in
  PROGRESS; it is **not** reported as a full pass.
- Production mock pool unchanged:89frames/69textures/136fontStrings. The old
  analytical Oval fixture retains167textures in its separate test harness.

**NOT RUN:** current native loading/driving, pool feel, matched-build score
delivery, asset regeneration and Lua54. No multiplayer-sprint, eight-player,
global completeness, native performance or release acceptance is inferred.

## Publication and deployment boundaries

Authorized publication targets are the combined `codex/scarlet-integration`
branch and original `claude/scarlet-library`, `claude/drive-fixes`,
`claude/scarlet-armory`, `claude/scarlet-cathedral`. Verify exact remote refs
after normal create/fast-forward pushes. Main remains unchanged; no force push,
author rewrite, release or change to another checkout is permitted.

Installed runtime remains01bd880. This task prepares/publishes source; it does
not install the standalone Claude tree. A later coordinated install must back
up/verify the shared addon and prepare a matching friend ZIP. New image paths
require a full client restart. Both peers need the same build for score catch-up.

Claude can start its next visual task from the published combined branch without
rewriting its existing feature history:

```powershell
git -C "C:\Users\bakke\Downloads\Forever_Addons\AzerothKart_Codex_Project_Pack\AzerothKart-Claude" fetch origin
git -C "C:\Users\bakke\Downloads\Forever_Addons\AzerothKart_Codex_Project_Pack\AzerothKart-Claude" switch -c claude/next-visual origin/codex/scarlet-integration
```

These are handoff commands, not commands run in Claude's checkout by Codex.
Its existing untracked outputs and canonical-worktree handoffs are preserved.
