# Codex handoff — Forever full names and IOU logged transport

2026-10-21, Europe/Oslo. Existing Codex Review worktree, branch `codex/forever-probe`, base `8e34e75` (combined runtime `8195da9`, Claude `1004e73`/effects `c6e1b5e`). Implementation **`8f66c5a`**; final deployment documentation follows. Resolve the tip with `git log -1 codex/forever-probe`.

## Reservation and coordination

Complete source correction: NetworkProbe name validation/matching; TransportProbe command/API/event/report/help; Core forwarding; focused network/adapter/UI integration tests; affected contracts/guides/ADR0012/progress. No UI.lua, Presentation, assets, track, physics or race edits. IOU is read-only compatibility evidence. Claude's next vehicles reservation remains intact. Main/local origin/main `f923d15`, canonical checkout `5570968`; no other checkout changed, no push/tag/release or automatic integration.

## What changed

The user's actual unquoted first-name/surname command failed in the old parser before any network call; pure validation also wrongly demanded a realm. Forever has no realms. Full names now retain surname, punctuation/hyphen/UTF-8, canonicalizing ASCII spaces and ASCII case for matching only (96rawbyte cap; controls/DEL/pipe refused). Prefer quotes; unquoted names and all-numeric six-character sessions work; ambiguous commands require quotes.

Use only `C_ChatInfo.SendAddonMessageLogged` / `CHAT_MSG_ADDON_LOGGED`, native `WHISPER`, explicit report/CSV route `WHISPER_LOGGED`. No unlogged or ordinary-whisper fallback. Actual chat lockdown is respected if present. Pacing, wire format, DATA/ACK budgets, result classification, lifecycle cleanup and UI pool remain unchanged. No load-time registration/send. Reuse IOU's 16October/build70425 four successful round trips, including UTF-8 and239/240byte packets; do not redo basic connection research or count it as sustained racing capacity. See [ADR0012](../adr/0012-forever-logged-transport.md).

## Executed checks

- Python3.14/pinned Lupa2.8 Lua5.1: `scripts/test_lua.py --runtime lua51 --tests network_probe transport_probe ui` PASS34parsed/three modules, including parsing/identity/logged-only routing/chatlockdown and original pacing/accounting/UI invariants. UI remains10frames/151textures/13fonts.
- `scripts/validate_project.py`: STATIC PASS61 paths. `git diff --check`: PASS. Independent read-only runtime review found no actionable defect.
- One intermediate docs encoding check failed; corrected UTF-8 and final structural check PASS. Full/both-runtime matrix NOT RUN; no reason to repeat it for this adapter correction. No actual two-client sends, return codes, sustained RTT/loss/throttle/reconnect or capacity result; CSV header-only.

## Deployment and client window

Preflight: all22files match combined8195da9 via prior manifest `local-artifacts/install-backups/20261021-002417-215-569e7e1336304203b52dae42c3cc8849/install.json`; no extra target files. Claude still1004e73, handoff read, untracked outputs preserved. Installed source **8f66c5a** with verified backup and22/22 matching hashes at00:53 CEST. Manifest `local-artifacts/install-backups/20261021-005314-298-f5ce5642e61b4729a8ed4e8b3d553eb0/install.json`. Local friend ZIP `local-artifacts/bundles/AzerothKart-forever-fix-8f66c5a.zip`:22 source-matching files,2,975,544bytes; SHA256 `8bfc6a11d462b65190352fa9fe4e03531b605acb43461d9845a1183d19745a99`. No publication or sending. Owner requested less computer use: only inventory was read, no activation/input/reload/help/readback/arm/send. Client loading and two-client traffic remain NOT RUN. Both testers need this update and reload. Never deploy an older standalone rendering/runtime branch over this combined build; recheck both handoffs and live target immediately before installation.

## Next single task

Both testers install the same corrected build/reload, use fresh code and exact opposite full names, listener first then sender within20seconds. See [the plain guide](../NETWORK_QUICK_START.md). Execute first0.5DATA/s16byte120second `WHISPER_LOGGED` window and reconcile both reports/evidence. No replication architecture selected. Original M0/M1/M3 acceptance and measured multiplayer gate remain open. Close-results behavior/combined-effect installation evidence remains in PROGRESS and previous handoff commit8e34e75; this task does not change visuals.
