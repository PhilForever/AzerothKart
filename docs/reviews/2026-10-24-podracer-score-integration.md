# Claude pod racer, start signs and outline — approved integration

Reviewed 2026-10-24 by Codex at the owner's request to review and push Claude's
latest work and provide simple second-client verification instructions.

Claude branch `claude/podracer-arrows-outline` at **0afeedf**, based on de4b291:
52be01f runtime/art/tools, 37a0cdb selective texture decode, 0afeedf handoff.
Codex base **98b3ce2**, reservation **de229b7**, reviewed combined runtime
**77a18912a028db249cc4e45be1df597e2ecad879** on
`codex/podracer-score-review`. Claude's authored commits remain unchanged.

## Findings and resolution

No blocking runtime/pipeline findings. Inspected the complete branch diff,
Claude's canonical handoff, generated pod-racer and junction preview images,
UI/Menu/Presentation changes, texture formats, local/CDN tool boundaries and
asset-source records. The car is recognizably Mirage's twin-pod rocket cart;
the signs are outside the painted roads and have no collision role. Optional
outline loading is guarded, off by default, saved, pooled and local-kart only.
Native visual readability, performance and refusal behavior remain NOT RUN.

Retained `goblin_drag_car` as the saved/wire identity for the new Pod Racer.
Physics10, Input/Loop/Race, authoritative track data, RaceGrid, all networking,
Core, score store/probe and both TOCs are unchanged from the Codex base.
Preserved Highscores and defensive preference root/future-version guards.
The sole merge conflict was the expected object-count assertion: both
additions now measure **86 frames / 167 textures / 135 font strings**.
No simulation assertions were relaxed. Updated current README/architecture
statements that incorrectly described totals as unsaved or used the old pool.

WoW-model source use is accepted for the requested kart under the owner art
direction; the ADR addendum is reviewed on the combined branch. Blizzard
redistribution rights remain explicitly unresolved for release. This review
does not create a third-party license or authorize a release. Native model
sources, extraction caches and personal screenshots are not bundled.

## Actual validation

- Lua5.1: `scripts/test_lua.py --runtime lua51 --tests presentation ui menu
  highscores solo_records score_channel_probe multiplayer_integration`:
  **PASS seven modules, 66 Lua files parsed**. Includes once-only records,
  saved/future preferences, outline lifecycle/pool/no simulation mutation,
  bounded probe and real Core/UI/Menu transport integration with mock peers.
- `scripts/build_kart_outlines.py --check`: **PASS all ten**, byte-identical
  to the source-derived outlines, including alpha/body/border invariants.
- Reviewer's read-only Python syntax and new kart/outline TGA header/size
  checks: PASS. Full source-model/city rebuilds, Lua5.4 and live client checks:
  **NOT RUN** in this review.
- `scripts/validate_project.py`: **FAIL only the same two historical expired
  skill links in PROGRESS**; no new structural/load-order errors.
- Both foreign worktrees' heads, branches, statuses and **400 file hashes**
  match the pre-review snapshot. Installed54files remain d3fd99d. No foreign
  file writes, resets, author rewrites, native input, install or main merge.

## Publication and test artifact

Owner-authorized atomic Git push succeeded, then remote readback confirmed
`claude/podracer-arrows-outline`0afeedf and
`codex/podracer-score-review`77a1891. Following documentation commits change no
runtime files; they are published to the same combined feature branch.

Test archive in the project-pack directory:
`AzerothKart-ScoreChannel-77a1891.zip` — **67 runtime files, 50,949,416 bytes**,
SHA256 `99145cdf76689f363a061afb36885496a286a932aa4c9c92d7277d907305543c`.
Verified every decompressed member against the tested source, CRC, exact paths
and both TOC module lists. It includes the new probe, score modules, Pod Racer
and ten outlines; excludes the retired drag sprite and all development data.
It has not been installed. Both testers must load this same runtime with a
full restart before following [the short check](../SCORE_CHANNEL.md).

Global publishing remains disabled. Existing native evidence is one accepted
CHANNEL send with no receive event on a private AnoCore server/client70532;
no peer proof or public Forever scope follows from that. The next task is the
30-second reciprocal receipt check, not a racing/throughput test.
