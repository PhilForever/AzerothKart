# Azeroth Kart — top-down arcade racing inside WoW Forever

**Status:** M0 local driving probe. Offline Lua 5.1/5.4 checks pass; actual-client acceptance is pending.
**Vision:** A polished, responsive top-down 2D kart racer wholly inside a movable World of Warcraft addon window, inspired by approachable arcade racing, with original presentation and Warcraft-flavored humor.

## Start here (for a human)
1. Read `docs/VISION.md`, `docs/FEASIBILITY.md` and `docs/ROADMAP.md`.
2. Open this folder as the Codex workspace. Paste `PROMPT_01_MASTER.md` into Codex. Keep `AGENTS.md` in the repository root.
3. `addon/AzerothKart/` is the addon folder to copy into the Forever `Interface/AddOns/` folder. Verify client flavor and TOC in `docs/CLIENT_API.md` first. The [developer install helper](docs/RELEASE.md#developer-install) supports a no-write preview, verified backups and repeat installs; use it only for an authorized deployment.
4. Enable addon in the game; type `/akart` or `/azerothkart`. Click `Start Test Drive` deliberately. W/Up throttle, S/Down brake/reverse, A/D or Left/Right steer. Escape, another key, any mouse click, Stop, Close or losing focus stops capture; click Start to restart. **Do not race while in combat.** Actual release behavior must pass the client checklist.
5. Record *actual* results of keyboard focus, rendering, frametimes, and combat interrupts in `docs/PROGRESS.md`. An addon loaded successfully does not establish multiplayer feasibility.
6. Run `python scripts/validate_project.py` for structure, then `python scripts/test_lua.py` for syntax and the complete suite in Lua 5.1 and 5.4. Install its pinned test dependency with `python -m pip install --target local-artifacts/python-deps -r requirements-dev.txt`. Native `lua tests/run.lua` is also supported; the Linux shared-library fallback is `python scripts/test_with_lua54.py`.
7. After a stopped drive, run `/akart probe` or click **Print Probe** to report frame/tick/drop counts, active frame duration, executed simulation duration, callback cadence and explicit UI object counts. Start/Stop refresh the HUD immediately; stopped timing metrics stay frozen until a new Start. Follow [the client checklist](tests/MANUAL_CLIENT_CHECKLIST.md); live tests and network measurements remain pending.
8. Optional profiling: while stopped, `/akart perf on` arms the next Start for up to 600 active updates. After stopping, `/akart perf` prints averages/maxima for simulation and render/HUD elapsed milliseconds; `/akart perf off` disables collection. It defaults off. These instrumented timer spans include probe overhead and are not exclusive CPU or GPU measurements; see [scope and manual checks](tests/MANUAL_CLIENT_CHECKLIST.md).

## Core commitments
- Multiplayer is part of the product vision but **must pass real-client network feasibility gates** before we claim a simultaneous eight-player racer is achievable.
- Pure Lua math and simulation are independent of WoW UI and network code.
- No protected-action automation, combat advantage, bypass of secret values, external control software, or in-game money/stakes.
- Local solo/time-trial remains valuable and shippable even if realtime networking is not.
- The original project's UI, assets, and code must not copy Nintendo/Activision/Blizzard art, branding, music or tracks. Warcraft setting is fan-addon context, not affiliation.
- No misleading "tested" claims. Tests must be recorded with evidence, client build, and environment.

## Repo layout

```
AzerothKart/
  AGENTS.md                       permanent Codex guardrails
  PROMPT_01_MASTER.md             initial master agent prompt
  PROMPT_02_SCHEDULED_CONTINUE.md automation resume prompt
  addon/AzerothKart/              actual WoW addon project
  docs/                           vision, feasibility, architecture, roadmaps, ADRs
  tests/                          pure-Lua tests and manual client checklists
  scripts/                        offline validation and installation scripts
```

## Important limitations of this starting package
The included Lua is a **small local driving demonstration** intended to validate the client API and feel of keyboard control. It has no finished lap system, weapons, production assets, AI or multiplayer. Eight offline tests pass in Lua 5.1 and 5.4, including a 10,000-tick seeded input replay at 30/60/144 simulated FPS, bounded profiling and mocked input/combat lifecycle checks. Live checks confirmed build `1.60.1.70450`, interface `16001`, project ID `18`, `Camelot` TOC, basic rendering/Start and several idle control-release paths. The owner confirmed actual combat closure, the interruption message and working WoW controls. Simultaneous W/Up testing is skipped at the owner's request due to the keyboard's limitation; alias behavior remains tested offline. Remaining driving/lifecycle/performance acceptance stays documented. Combat closes the window and records "Game interrupted by combat"; future races will retain actual current placements as final (ADR 0006).

This directory is the Git checkout linked to [PhilForever/AzerothKart](https://github.com/PhilForever/AzerothKart). Local commits preserve the original pack and focused M0 changes. Two human near-minute drives are recorded in the [client evidence](docs/evidence/2026-10-19-m0-client.md), followed by [600 valid stationary timing samples](docs/evidence/2026-10-19-m0-stationary-profile.md). A later isolated rendering test identified grass covering the road when snapping states differed. Explicit grass priority and creation-only band settings now remove the seams; normal reload and read-only checks verified the installed fix with counts 6/99/3. [Rendering evidence](docs/evidence/2026-10-19-m0-road-layer.md). M0 remains open, including scaling, sustained performance and remaining input checks; further combat testing stays deferred. No push, release or scheduled automation was performed. See `docs/PROGRESS.md` for the current task and `docs/AUTOMATION.md` for the optional continuation workflow.

## References
See `docs/CLIENT_API.md` for links and confidence levels. Updated documentation reflects Oct 2026-era WoW Forever but must be validated against the installed build.
