# Azeroth Kart — top-down arcade racing inside WoW Forever

**Status:** M0 starter scaffold / playable *local tech prototype*, not a released multiplayer game.
**Vision:** A polished, responsive top-down 2D kart racer wholly inside a movable World of Warcraft addon window, inspired by approachable arcade racing, with original presentation and Warcraft-flavored humor.

## Start here (for a human)
1. Read `docs/VISION.md`, `docs/FEASIBILITY.md` and `docs/ROADMAP.md`.
2. Open this folder as the Codex workspace. Paste `PROMPT_01_MASTER.md` into Codex. Keep `AGENTS.md` in the repository root.
3. `addon/AzerothKart/` is the addon folder to copy into the Forever `Interface/AddOns/` folder. Verify client flavor and TOC in `docs/CLIENT_API.md` first.
4. Enable addon in the game; type `/akart` or `/azerothkart`. Start the local prototype with `Start Test Drive`. Press W/Up for throttle, S/Down for brake/reverse, A/D or Left/Right for steering; Escape or Close to stop input capture. **Do not race while in combat.**
5. Record *actual* results of keyboard focus, rendering, frametimes, and combat interrupts in `docs/PROGRESS.md`. An addon loaded successfully does not establish multiplayer feasibility.
6. When Lua is available, run `lua tests/run.lua`. Python QA: `python scripts/validate_project.py` (does not execute Lua); on Linux with liblua5.4, `python scripts/test_with_lua54.py` (parses Lua and runs pure tests).
7. Copy `PROMPT_02_SCHEDULED_CONTINUE.md` to Codex automation scheduled every 5 hours. See `docs/AUTOMATION.md` for preconditions.

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
The included Lua is a **small local driving demonstration** intended to validate the client API and feel of keyboard control. It is not yet a complete racer: no finished lap system, weapons, assets, AI, or multiplayer. Pure Lua starter tests passed in the authoring environment using a Lua 5.4 shared-library harness, but the actual WoW Forever Lua runtime has not been tested. Client integration cannot be verified without the game.

## References
See `docs/CLIENT_API.md` for links and confidence levels. Updated documentation reflects Oct 2026-era WoW Forever but must be validated against the installed build.
