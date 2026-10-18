# RECURRING CODEX AUTOMATION PROMPT — every 5 hours

Continue development of the **existing Azeroth Kart Git workspace**. Do not create a new project. Treat `AGENTS.md`, `docs/PROGRESS.md`, `docs/ROADMAP.md`, `docs/FEASIBILITY.md`, `docs/ARCHITECTURE.md` and accepted ADRs as the memory of all previous runs.

Every scheduled run:
1. Confirm this is the correct repository, inspect branch and `git status`. Preserve any existing/uncommitted changes; avoid conflicting edits and do not reset other people's work.
2. Read the most recent `docs/PROGRESS.md` handoff and current milestone acceptance criteria. Identify the **next single concrete task** you can complete without user interaction. If a milestone is blocked on an in-game test, prepare a precise probe/test harness and perform independent work on the next permissible task; do not claim the test passed.
3. Make a short implementation plan, implement one coherent vertical slice with supporting tests, and keep modules and documentation aligned.
4. Execute the actual available validators and tests. If the WoW Forever client or Lua runtime is unavailable, explicitly mark those checks `NOT RUN` rather than guessing.
5. Update `docs/PROGRESS.md` with timestamp (if accessible), milestone, changes, exact tests + results, unresolved risks, and next executable task. Update `docs/ROADMAP.md` only when acceptance criteria are met.
6. Make a focused commit only if repo state and permissions allow; do not push/release without configured authorization.
7. Finish with a compact change report and next-step instruction.

Stop and flag for user review if you encounter: an API contradiction, multiplayer transport performance below the gate, significant product-vision decision, security/privacy issue, broken migration, or destructive repository operation. Do not silently proceed with assumptions.

If execution is prevented by quota, environment not running, or scheduling constraints, do not pretend work happened. On the next valid run simply resume from the persistent repo files. No external accounts, purchases, gambling with gold/real money, or attempts to circumvent Blizzard protections.
