# Scarlet queue review — 2026-10-26

**Follow-up:** the owner subsequently authorized both fixes and integration.
The [combined integration review](2026-10-26-scarlet-integration.md) records the
swept-circle correction, bounded L/A/C score support and executed combined
validation. The findings below describe the original queued source.

## Disposition

Reviewed Claude's queued Library, drive fixes, Armory and Cathedral through
`ea4425d` against Codex `0edaf2c` (installed runtime `01bd880`). Visual/menu
and earlier drive changes have no blocking finding. The combined candidate is
**not approved for installation yet**: resolve the round-solid sweep finding
and adapt score synchronization to the current production catalogue first.
This is a review checkpoint, not an integration or publication. No source
branch was merged, installed or pushed, and Claude's worktree was not modified.

Reviewed branch tips:

| Branch | Tip |
|---|---|
| `claude/scarlet-library` | `8b09309` |
| `claude/drive-fixes` | `fb8b296` |
| `claude/scarlet-armory` | `559cc4f` |
| `claude/scarlet-cathedral` | `ea4425d` |

The Cathedral branch contains all13 commits after the shared `1bc3ac8` base.
Current Codex retains Physics12, retired Oval, score discovery/group leases and
the installed opponent-turn smoothing. Claude's queued runtime changes do not
touch UI.lua, Presentation.lua, Physics, input or networking; preserve those
newer Codex implementations during eventual integration.

## Finding 1 — sweep round obstacles, not only movement endpoints

**P2, fix before accepting Cathedral's new collision primitive.** At Claude
`ea4425d: addon/AzerothKart/Dungeon.lua:412–424`, round solids skip the swept
collision pass. Only an endpoint inside the disc triggers correction. A segment
whose endpoints are outside can cross the obstacle without a hit; this also
misses the existing wall penalty on that contact.

Executed actual Lua5.1 using production Cathedral data:

```lua
local ns = {}
for _, name in ipairs({"Track", "Dungeon", "ScarletCrusade"}) do
    assert(loadfile("addon/AzerothKart/" .. name .. ".lua"))("AzerothKart", ns)
end
local track = ns.Dungeon.new(ns.ScarletCrusade.scarlet_cathedral, ns.Track.crossesGate)
print(track.resolveMovement(509.85, 987.99, 514.15, 987.99))
-- 514.15, 987.99, false
```

The pool centre is `(512,830)`, radius140 plus wallInset18 gives clearance158.
Both endpoints have radius158.004628; the midpoint radius157.99 violates that
clearance. The4.3-unit movement is below the real maximum260/60 units per step.
The normal-step violation is shallow, not a whole-pool shortcut; longer public
resolver calls can cross the whole disc. An endpoint-only random test misses
both kinds because the returned endpoint remains legal.

Required correction: find first swept-circle contact, keep remaining tangential
movement without sticking, and test the complete segment/slide legs. Preserve
rectangle behavior, room/solid inset, finite guards, fixed-step displacement
bounds and the existing wall-hit penalty. Add both this production repro and a
long segment with endpoints outside. Do not fix it by replacing the round pool
with a box or growing an invisible rectangular wall.

## Finding 2 — adapt the score patch to the current bounded protocol

**Required integration dependency, with a P2 upper-bound bug in a naive append.**
Claude already flags that its standalone branch cannot initialize sharing with
its expanded catalogue. Its supplied patch is based on the older seven-course
codec and still includes Test Oval. Do not apply it verbatim to Codex.

Current production has8 active courses; L/A/C add3, giving **11 active courses
and12 HELLO slots**, including the retained zero digest for retired `O`.
Keep existing M/S/I/D/R/U/T/G meanings; append L/A/C and reject retired records
as before. Do not restore Oval in defaults, menus, live admission or boards.

Executed actual Lua5.1 codec checks against an in-memory expanded copy of the
current implementation, without editing tracked source:

| Expanded HELLO | Payload +7-byte prefix |
|---|---:|
| Maximum physics/hash fields, including a nonzero retired hash | 164bytes |
| Maximum physics/active hashes, retired `O=0` | 155bytes |
| Physics12/maximum active hashes, retired `O=0` | 147bytes |

The native sender ceiling is158bytes. Requiring the retired slot to equal zero
in both encode/decode enforces its existing intended invariant and keeps every
legal full-bound HELLO within155bytes. Add regressions for rejection of a
nonzero retired slot, maximum legal size, all11 mappings, and catch-up on the
new courses; do not raise the send budget or weaken the old maximum-size test.
No field-layout/prefix/version change is needed for that adaptation.

Old9-slot and expanded12-slot HELLOs reject each other with `nil,"hello"`.
Both users need the matching combined build for catch-up. Preserve deliberate
exact-context direct NEW admission before HELLO; do not claim every packet
from an older build is rejected. No automatic migration/score deletion.

## Earlier changes and visual review

- Library and Armory add their original route/data, pictures and menu metadata.
  Cathedral's overview and nine follow-camera samples were visually inspected;
  no new visual blocker was identified. This does not establish native loading,
  camera feel or collision/art alignment.
- `ad868c2` addresses the owner's disconnected-floor/invisible-wall appearance,
  props beneath the kart, and Thunder Bluff's misplaced grid. Runtime changes
  outside Dungeon are data/Menu metadata. Menu command/lifecycle handlers stay
  unchanged; new courses replace existing disabled rows without adding rows.
- Thunder Bluff and Graveyard become geometry version2. Historical version1
  score records must remain saved; they are separate compatibility contexts.
- Source/provenance records name Warcraft III Reforged3.0.1.24371 and the
  modifications. Rights status remains recorded under ADR0009 for release;
  the review does not invent distribution permission.
- Claude reports deleting its own temporary `local-artifacts/scc-wc3.tgz` in
  exception to its deletion rule. The path is absent and is not Git-tracked;
  this review performs no deletion or recovery and cannot reconstruct its
  former contents or independently certify every prior filesystem action.

## Executed checks and limits

- In Claude's checkout, actual
  `scripts/test_lua.py --runtime lua51 --tests dungeon` **PASS**;
  `scripts/test_lua.py --runtime lua51 --tests menu circuit` **PASS**.
  Both parsed78Lua source/test files. The new collision repro above fails the
  required swept-contact expectation despite those passes.
- Independent geometry review ran2,880 diagonal/tangent4.3-unit samples with
  no stalls; this does not cover the crossing defect. Existing route tests
  exercise all four sprint gate sequences. Invalid-centre recovery falls back
  to spawn consistently with the documented fallback.
- `scripts/export_score_catalog.py --check` in Claude **PASS**,12 boards;
  that count includes its older Oval. The eventual combined catalogue must be
  regenerated from the retired-Oval source and contain11 active boards.
- Six new runtime TGAs: actual headers, exact raw lengths,32-bit uncompressed
  format and SHA256 match the handoff. Library/Armory backgrounds2048² with
 512² previews; Cathedral1024×2048 with256×512 preview.
- `git merge-tree --write-tree --messages HEAD claude/scarlet-cathedral` is a
  **conflict preview**, not a merge. It reports four conflicting files:
  API_CONTRACTS and test_circuit/test_dungeon/test_menu. Returned preview tree
  `4f9c65513ff98e32c874a5648fbea5b5d45c5e86`; no branch/index/worktree moved.
- Full combined suite, current asset regeneration, Lua54, installed/native
  checks and multiplayer on these new maps: **NOT RUN**. Claude's reported
 42-module/cloud/rebuild passes remain Claude's evidence, not new Codex passes.

## Next exact task and integration rules

Fix swept-disc contact with regressions and adapt the bounded ScoreSync codec
as above. Then prepare a reviewed combination on a new Codex integration branch,
resolve the four preview conflicts preserving both sides' assertions, regenerate
the11-board catalogue and run affected integration checks. Dungeon sprints stay
solo until their live lifecycle is separately reviewed; no new race-wire codes
or eight-player claim is part of this content integration.

Preserve both original feature histories/worktrees. Do not install Claude's
standalone tree over runtime01bd880. Publishing the four original branches is
separate from approving/merging the combined build; this review publishes none.
Any later install must back up the shared addon, verify source/installed hashes
and create a matching friend ZIP. New asset paths require a full client restart.
