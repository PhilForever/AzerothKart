# Changelog

## Unreleased — M0 timing sample evidence (2026-10-19)
- Probe reports cumulative active frame time, executed simulation time and callback cadence; stopped samples retain their timing remainder.
- Start and Stop immediately refresh the HUD, fixing the observed stale stopped tick display.
- Offline 60-second schedule, hitch accounting and frozen-sample regressions; manual client samples remain pending. Source-only update, not installed or released.

## Unreleased — M0 probe hardening (2026-10-18)
- Combat now closes the window and records one retained interruption result/note; future races will freeze actual standings when implemented.
- Local developer install verified by SHA-256; live build/interface/Camelot discovery, basic rendering and idle release checks observed. Full manual acceptance remains pending.
- Corrected left/right steering; physics compatibility version 2.
- Pure input sampling and bounded fixed-step clock with measured dropped time.
- Focus/lifecycle stops, guarded combat propagation and explicit probe diagnostics.
- Lua 5.1/5.4 tests, deterministic replay, analytical handling and mocked UI lifecycle checks.
- Installed-client probe matrix and unmeasured network experiment ledger; M0 client acceptance remains pending.

## 0.0.1 — project starter (2026-10-18)
- Technical plan, agent prompts and acceptance-gated roadmap.
- Small local top-down driving probe; pending actual Lua + WoW validation.
- Offline verification scripts and manual test checklists.
- No public multiplayer or finished racing claimed.
