# Claude handoff — front-end menus, race HUD and results (`claude/ui-flow`)

Prepared 2026-10-21 about 12:45 CEST (Europe/Oslo) by Claude (rendering/UI/sprites owner).

**Base:** `83c611c`, Codex's reviewed combined commit on `codex/roster-integration`, as [INTEGRATION_STATUS](../INTEGRATION_STATUS.md) asks. This session's commits on the new branch `claude/ui-flow`:

1. `dfbd83e`, the scope reservation;
2. `e279563`, the front end: menus, race HUD, results dialog, saved preferences, preview art and tests;
3. `3465435`, the documentation, the contract proposal and the client checks;
4. `245d71b`, the menu test and both preview scripts load the addon's files in TOC order;
5. this handoff.

`claude/track-ui` is preserved at `b0b1f2e`. Earlier handoffs are in Git: `b0b1f2e` (the kart roster), `1004e73` (the effects) and `812d132` (the trike). M0/M1/M3 acceptance and the multiplayer gate are unchanged and remain open.

## Owner instructions

- "You've been assigned the UI task. Please create the ready to ship UI for the game/addon \"Azeroth Kart\". Take inspiration from other racing games like Mario Kart, Team Crash Racing if necessary. Clear menu choices single player and multiplayer, selecting maps, selecting karts, etc. Start working on this."
- Answers to Claude's questions:
  - base: "Merge Codex's latest first (Recommended)". Applied as a new branch from Codex's combined commit, following INTEGRATION_STATUS; no agent branch was merged.
  - multiplayer: "Coming-soon lobby (Recommended)";
  - style: "Classic WoW dialogs";
  - saving: "Yes, remember them (Recommended)".
- Standing: no merge into `main`; no claim of in-game verification without the actual client; leave the simulation-control functions in `UI.lua` alone. The owner pushes from Windows and runs the client checks himself.

## Delivered

[The front-end sheet](../art/ui/front-end.md) has the flow, every screen, the client elements used, the preview art, the saved preferences, the budget and the client check. In short:

- **Main menu** on opening the window: **Single Player**, **Multiplayer (soon)**, **Garage**, **How to Play** and **Settings**, with the current track and kart named underneath.
- **Single Player:** Choose a Track (preview pictures and facts) → Choose Your Kart (a turntable spinning the kart's own 64-heading sheet, a six-kart grid, the model credit) → **Race!**
- **Race view:** large LAP and next-gate text, the clock and best lap, the capture line, a big gold 3-2-1-GO with client beeps. The bar shows only **Stop** during a run.
- **Results:** a dark dialog with the total, last and best times and every lap, the fastest in green. **Restart**, **Close results**, **Change Kart**, **Change Track** and **Main Menu**.
- **Track view** after Close results: **Start Race**, **Track**, **Kart** and **Main Menu** on the bar.
- **Multiplayer:** a disabled coming-soon lobby preview, with how to help with today's connection test (`/akart net help`).
- **Settings:** window size (80–125%, too-large sizes disabled), drift and boost effects, sound effects, developer info (the timing line and Print Probe), reset window position. The window drags by its title.
- **Saved** in `AzerothKartDB.preferences`: the track, the kart and the settings.
- The client's own dialog backdrops, header, Game Menu buttons, panel buttons, check boxes, fonts and sounds, each with a fallback. The only new art is the original `Assets/UI/TrackPreviews.tga`.

## Reservation

Released. The edits in `UI.lua` are notification hooks and visual layout only:

- the end of `refreshCountdown` → `Menu.OnCue(cue)`;
- the end of `refreshHud` → `Menu.Sync()`;
- the new `UI.SetEffectsEnabled` before `renderEffects`, which returns early while effects are off;
- the end of `UI.SelectKart` → `Menu.OnKartChanged()`;
- the end of `render` → `Menu.RefreshRaceHud()`;
- `UI.Create`:
  - the old "AZEROTH KART [SOLO DRIVE]" title line removed;
  - a window `OnShow` script → `Menu.OnWindowShown()`;
  - Close moved to TOPRIGHT −18,−16, inside the dialog border;
  - the status text and Start label now read "Start Race";
  - it ends with `pcall(AK.Menu.Create, UI)`, and `Menu.Disable(err)` on failure.

`Menu.lua` also re-places and restyles objects `UI.Create` made: the bar, the probe button, HUD colours, the countdown font and the results panel. Their callbacks stay in `UI.lua`.

**Not touched:** `step`, `UI.Start/Stop/InterruptCombat/ReleaseInput/OnUpdate/HandleEvent/OnCombatEnded`, `keyEvent`, Start refusals, clock and profiling wiring, `UI.SelectTrack`'s transaction, `UI.DismissSummary`'s semantics, and all RaceProtocol, PeerSession and transport code.

## Changes Codex must review

The proposal is in [API_CONTRACTS](../API_CONTRACTS.md#proposed-front-end-menus-race-hud-and-results).

1. **Saved-track restore without a click (needs sign-off).** The first time the window opens out of combat, `Menu.OnWindowShown` calls `UI.SelectTrack(saved)` when the saved track differs and no run is active. This runs Codex's selection transaction, including its sample reset. A failed load keeps the default for the session, and the saved choice is not forgotten. If this is refused, the alternative is to preselect the saved track on the track screen and apply it on **Next**.
2. **Window `OnShow` script** (a new event script in `UI.Create`). `Menu.lua` adds a child watcher frame whose `OnHide` marks a real close only when the window itself is hidden, so Alt+Z returns to the same screen.
3. **Bar:**
   - Start reads **Start Race**, and Stop moves to x=618, away from it.
   - Track, Kart and the new Main Menu show only in the track view.
   - Print Probe and the timing line show only with developer info (default off); `/akart probe` is unchanged.
   - Codex's enabling and disabling of these buttons, and their callbacks, are unchanged.
4. **Results:**
   - `UI.summary` becomes 460×312 at canvas level +8, with Restart and Close results one level above it.
   - The three new buttons each call `UI.DismissSummary()` and then open a menu.
   - Title, detail and hint text are unchanged.
5. **SavedVariables:** `AzerothKartDB.preferences` = `{version=1, track, kart, effects, devInfo, scale, sound}`.
   - Values are validated on read, and unknown fields are kept on save.
   - A newer `version` is read but never overwritten.
   - Saves happen only on a change; Core's `schemaVersion` and other fields are never touched.
6. **`UI.SetEffectsEnabled(enabled)`**, a new public visual switch. The simulation never reads it.
7. **Start discipline:** only **Race!**, **Start Race** and **Restart** call `UI.Start`. `Menu.Show` refuses while a run is active.
8. **Escape:** the window is not added to `UISpecialFrames`, because the Escape that stops a run can also reach the game's Escape binding ([evidence](../evidence/2026-10-20-menu-integration-client.md)).
9. **`tests/test_ui.lua` (shared):**
   - `Menu` added to the loader list;
   - the counts as named constants: `MENU_FRAMES, MENU_TEXTURES, MENU_FONTS = 54, 9, 67`, giving 65/160/79, with the five font-string checks using `UI_FONTS`;
   - the summary size 460×312;
   - `(table.unpack or unpack)`, which fixes a pre-existing Lua 5.4 failure in one assertion block.
   - No capture, lifecycle, clock or race assertion was relaxed.
10. **Budget:** 65 frames, 160 textures and 79 font strings, all created with the window, none per tick or frame.
    - The preview atlas adds 2 MiB on the first track-screen visit.
    - The race HUD rewrites its text only when a shown number changes, about ten times a second while the clock runs.
11. **Multiplayer:** `Menu.lobbyPresentation(view)` maps a copied session view, and `Menu.SetSessionBridge` is a proposed registration point. Nothing is wired; see the next section for Codex's new API.

## Integration with Codex's latest (trial in a scratch clone; no branch changed)

Since `83c611c`, Codex has added `codex/session-transport` (`4f9246a`), `codex/start-clock` (`2232f82`) and `codex/gemini-feedback` (`e10d3ef`), each on top of the previous one. They bring SessionTransport, ClockProtocol, StartClock and RaceStart, plus their guides `docs/SESSION_MENU_API.md` and `docs/START_CLOCK.md`. Those guides exist only on Codex's branches; read them with `git show codex/gemini-feedback:docs/START_CLOCK.md`. None changes `Menu.lua`'s files. The only `UI.lua` change is one line in `UI.Start` (solo Start stops session control).

Trial: `git merge --no-ff codex/gemini-feedback` (`e10d3ef`) onto `claude/ui-flow` (`245d71b`).

- **Code merges cleanly:** `UI.lua`, `Core.lua` and both TOCs.
- **Six conflicts, each resolved as the union of both sides:**
  - `tests/run.lua`: keep Codex's list, then add `"tests/test_menu.lua"` after `"tests/test_ui.lua"`;
  - `tests/test_ui.lua` loader: Codex's list with `"Menu"` after `"UI"`;
  - `scripts/validate_project.py` load order: Codex's list with `'Menu.lua'` after `'UI.lua'`;
  - `docs/API_CONTRACTS.md` module list: Codex's sentence, then Claude's Menu sentence;
  - `docs/ARCHITECTURE.md`: Codex's "for twenty modules." then "The proposed `Menu.lua` front end loads directly after `UI.lua`, making twenty-one; `UI.Create` builds it under `pcall` and keeps the basic bar if it fails.";
  - `CHANGELOG.md`: keep both entries.
- **No other edit is needed:** since `245d71b`, the menu test and both preview scripts read the TOC.
- **Combined result:**
  - `test_lua.py --runtime both` PASS (48 files parsed; mock counts 65/160/79);
  - the validator fails only on the two pre-existing PROGRESS links;
  - `build_ui_art.py --check` PASS;
  - both preview images byte-identical.
  - The same trial against `4f9246a` alone gave the same six conflicts and also passed.

**Exact commands for the integrator (not executed).** In Codex's own worktree, on a fresh branch from `codex/gemini-feedback` or its successor:

1. `git merge --no-ff claude/ui-flow` (ours and theirs are swapped relative to the trial; the unions are the same);
2. resolve as above;
3. run `python scripts/test_lua.py --runtime both`, `python scripts/validate_project.py` and `python scripts/build_ui_art.py --check`.

**Wiring the lobby later.** Multiplayer stays **coming soon** on this branch:

- The owner chose that.
- Codex's guides say this phase must not be shown as a playable shared race.
- `TakeRaceStart()` is backend-only, and the live-race controller comes first.

When it is wired, after integration and the owner's go-ahead:

- Host and Join screens call `HostCoordinated(peer, code, trackId)`, or `ListenCoordinated(host, code)` followed by a deliberate `Join()`.
- Then `Ready(bool)`, host `PrepareStart()`, and `Leave()` from Close or Leave.
- The view is polled at about 5 Hz from the menu's own refresh, outside simulation ticks.
- There is no tick or seed setting.
- `Menu.lobbyPresentation` must read SessionTransport's `canHost`/`canListen`, `canPrepareStart`, `coordinated`, `clock`, `transportBusy` and `lastError` (PeerSession's own view names the host capability `canInvite`).
- Direct dot calls on `AK.SessionTransport` can replace the proposed `SetSessionBridge`.

## Tests performed

| Command / check | Result |
|---|---|
| `python scripts/test_lua.py --runtime both` at `245d71b` | **PASS** in the cloud (Python 3.13.16, Lupa 2.8) and on the developer machine's Linux shell (Python 3.10.12, Lupa 2.8). 40 files parsed. Mock counts frames=65, textures=160, fontStrings=79. `test_menu`: seven screens, the Single Player flow, results paths, garage, settings, saved choices, the coming-soon lobby and the fallbacks |
| `python scripts/validate_project.py` | Only the 2 pre-existing Windows-path links in PROGRESS.md fail, on both machines |
| `python scripts/build_ui_art.py --check` | **CHECK PASS** on both machines: 2097170 bytes, sha256 `43afd042…863d` |
| `preview_ui.py`, `preview_effects.py` | Both regenerated in the cloud; byte-identical to the committed review images after `245d71b` |
| Trial merges with `4f9246a` and `e10d3ef` | Combined suite **PASS** on Lua 5.1 and 5.4 (42 and 48 files), validator and art check as above; cloud scratch clones |
| Review | An independent review pass before committing found these issues, all fixed: Escape and `UISpecialFrames`; `Disable` hiding Main Menu; Alt+Z re-show; fanfare once per run; a combat-safe track restore; preference versioning; sizes that do not fit the screen |

**NOT RUN:**

- the whole front end in WoW Forever: dialog art, the title banner, red buttons, fonts (`Fancy48Font`), sounds, dragging, window sizes, Alt+Z, Escape, the turntable and the preview pictures;
- any install of `claude/ui-flow`, and the combined state in the client;
- FPS or memory measurement;
- `tests/test_install_local.ps1` and Windows-native Python;
- multiplayer.

The review pictures come from a recording mock with stand-in fonts; they show layout, not the client.

## Client check (owner; NOT RUN; after a coordinated install)

Fully restart the client: `Menu.lua` and `Assets/UI/TrackPreviews.tga` are new files. Then follow [the front-end client check](../art/ui/front-end.md#client-check-not-run):

1. the main menu over the dimmed track;
2. both track previews, the turntable and the credits;
3. Race! and the gold countdown with beeps;
4. the results dialog's lap list and its five ways out;
5. the Multiplayer, How to Play and Settings screens;
6. dragging and `/reload` remembering the choices;
7. Alt+Z returning to the same screen, and Escape during a race;
8. the counts 65/160/79 with developer info on.

Open questions for the client:

- whether `MainMenuFrameButtonTemplate` widens to fit "Multiplayer (soon)";
- whether the dialog border's corners meet the Close button cleanly;
- whether `Fancy48Font` is loaded on Forever.

## Deployment

Claude installed nothing and did not read or change the live AddOns folder this session. Per INTEGRATION_STATUS, Codex prepares the next coordinated install from the reviewed combined source, and the owner decides.

## Pending PROGRESS ledger entry (integrator to append; PROGRESS.md was not edited)

> ### 2026-10-21 ~12:45 CEST — Claude / `claude/ui-flow`, front-end menus, race HUD and results
>
> - From combined `83c611c`: `Menu.lua` front end in the client's dialog style. Main menu (Single Player, Multiplayer coming soon, Garage, How to Play, Settings); track select with an original preview atlas; kart select with a turntable; race HUD and big countdown; a results dialog with every lap and five ways out.
> - Saved track, kart and settings in `AzerothKartDB.preferences` v1. Explicit counts 65/160/79. `UI.lua` gained notification hooks, `SetEffectsEnabled` and the Start Race label only.
> - `test_lua.py --runtime both` PASS on both machines; art check PASS. Trial merge with Codex's `e10d3ef` PASS: six union conflicts (scratch clone).
> - **NOT RUN:** client appearance, sounds and fonts; any install. The track restore without a click awaits Codex's review.

## Branch, commits and workspace

| Item | Value |
|---|---|
| Worktree / branch | `AzerothKart-Claude` / `claude/ui-flow` at this commit |
| Push | Owner only: this session's git proxy refuses the repository. `git -C "C:\Users\bakke\Downloads\Forever_Addons\AzerothKart_Codex_Project_Pack\AzerothKart-Claude" push -u origin claude/ui-flow` (the branch is not on origin yet) |
| Not done | No merge into `main` (`f923d15`) or into any Codex branch; no tag, release, install or client input. Codex's branches and worktrees were only read |

**Workspace notes:**

- `local-artifacts/bundles/` (git-ignored) holds the transfer bundles. These include the read-only exports `codex-session-transport-4f9246a.bundle` and `codex-gemini-feedback-e10d3ef.bundle` used for the trials.
- The untracked `Claude outputs/` folder, created by the desktop app, is still left for the owner.

**Git environment note:**

- Commits are made in a cloud clone with this repository's local identity, then moved here as git bundles and fast-forwarded, so the hashes are identical.
- Git runs from a Linux shell on the developer machine with `--git-dir=.git/worktrees/AzerothKart-Claude`, `core.createObject=rename`, `gc.auto=0`, `maintenance.auto=false` and `gc.worktreePruneExpire=never`.
- **Never run `git worktree prune` or `git gc` there**: the recorded gitdirs are Windows paths, and that shell lists them as prunable.

## Next

1. **Codex:** review the items above, and integrate `claude/ui-flow` with the backend chain using the resolution above. Then prepare the coordinated install. **Owner:** the client check.
2. **Claude, on the owner's go-ahead:** after Codex's live-race controller, wire the Multiplayer screen to SessionTransport's coordinated actions: Host/Join, Ready, PrepareStart and Leave, with clock and pending feedback.
3. **Content targets (ADR 0010):** eight ready karts (six registered) and three ready maps (Mirage is the only production map).
