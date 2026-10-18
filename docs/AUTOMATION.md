# Scheduling Codex continuation safely

## Use
Open Codex with **this exact working repository** and configure an Automation with the full text from `PROMPT_02_SCHEDULED_CONTINUE.md`. Select an every-five-hour cadence in the Codex scheduling UI if supported, or supply recurrence `RRULE:FREQ=HOURLY;INTERVAL=5` where RRULE is accepted. The scheduling UI's actual capabilities and chosen repository/worktree override this document.

## Why documentation matters
Automation instances can start without prior conversational context. `AGENTS.md`, `PROGRESS.md` and `ROADMAP.md` are persistent state and must be updated by each successful run. A new instance must inspect uncommitted changes and branch state.

## Preconditions and limitations
- An Automation **does not guarantee** that Codex's rate or token quota will replenish exactly after five hours.
- It **does not** create perpetual uninterrupted work, keep your home PC online, bypass a quota, or automatically access a live WoW client if environment lacks it.
- If scheduler only supports presets/custom unsupported, choose nearest supported time and note difference. Don't claim a task exists unless actually created in Codex.
- Automations running in isolated Git worktrees may not immediately modify your primary branch. Establish merge/review workflow first.
- Never put API keys or credentials in prompt or markdown. No unattended publish or destructive Git actions.

## End-of-run contract
The continuation must leave actionable progress in `docs/PROGRESS.md` including tests and next task. If blocked by an in-game test, it can prepare a probe but not falsify results.
