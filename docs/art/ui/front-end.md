# Front end: menus, race HUD and results

**Status (2026-10-22):** reviewed Claude UI `1b2d3d5` is integrated with Codex backend `192c6de` by merge `6cd611a` on `codex/ui-backend-integration`. Claude's isolated preference fix `4ffe184` is retained as `9b22f12`; city merge f9f2af0 now includes reviewed Stormwind from78d97a1, followed by the protected background-load transaction. The implemented interfaces are in [API_CONTRACTS](../../API_CONTRACTS.md#implemented-front-end-menus-race-hud-and-results). Its appearance and behaviour in WoW Forever are **NOT RUN**; see [the client check](#client-check-not-run).

The owner asked for "the ready to ship UI": clear Single Player and Multiplayer choices, and selecting maps and karts. He chose:

- the client's own **Classic WoW dialogs** style;
- a **coming-soon** multiplayer lobby until two-player racing works;
- **remembered** track, kart and settings.

![Layout preview of every screen](front-end-review.png)

`scripts/preview_ui.py` made this review picture. It runs the addon's own Lua against a recording mock, solves every anchor as the client does, and draws the addon's TGAs. The client's dialog art, button art and fonts are drawn as stand-ins (Bitstream Charter and FreeSerif), so it is a layout picture, not a screenshot.

## Flow

```
open window ─► Main menu ─► Single Player ─► Choose a Track ─► Choose Your Kart ─► Race! ─► 3-2-1-GO ─► race ─► Results
                 │                                                                                                 │
                 ├─ Multiplayer: lobby preview, coming soon         Restart · Close results · Change Kart · Change Track · Main Menu
                 ├─ Garage: choose a kart                                                                          │
                 ├─ How to Play                                       track view: Start Race · Track · Kart · Main Menu
                 └─ Settings
```

- Opening the window shows the main menu. If a run's results are still up, it shows them instead, as before.
- A menu never covers a live run, and no screen starts a race by itself. Only **Race!**, **Start Race** and **Restart** call `UI.Start`.
- Combat, Stop, Escape, Enter, Close and focus loss keep Codex's behaviour. Escape still ends a run and, as recorded in [the client evidence](../../evidence/2026-10-20-menu-integration-client.md), may also open the Game Menu, so the window is deliberately not an Escape-closable dialog.

## Screens

| Screen | Offers |
|---|---|
| Main menu | The "Azeroth Kart" title, then **Single Player**, **Multiplayer (soon)**, **Garage**, **How to Play** and **Settings**, with the current track and kart named underneath |
| Choose a Track | Mirage Raceway and Test Oval, each with a preview picture, a short description and its facts (3 laps, 4 gates, direction, off-road). Choosing one applies it at once; **Next: Choose Kart** continues |
| Choose Your Kart | A turntable that spins the chosen kart's own 64-heading sheet, arrows and a grid of all six karts, the kart's description and model credit, and a note that every kart handles the same. **Race!** starts the countdown |
| Garage | The same kart choice from the main menu, with **Done** instead of Race! |
| Multiplayer | **COMING SOON**. Disabled **Host a Race** and **Join a Race**, a disabled lobby preview (you, an open slot, track, Ready/Start/Leave), and how to help with today's connection test (`/akart net help`) |
| How to Play | The controls and the racing rules, plus the model credits |
| Settings | Window size (80–125%; sizes that would not fit the screen are disabled), drift and boost effects, sound effects, developer info (the timing line and Print Probe), and reset window position. The window can be dragged by its title bar |
| Race | Big **LAP x/3** and the next gate at top left. The clock in tenths and the best lap at top right. "Controls active - Esc to release" at the bottom. A large gold 3-2-1-GO. **Stop** sits away from where Start was, so a double click cannot start and stop |
| Results | A dark dialog with the result title, track and kart, total/last/best times and every lap time, the fastest in green. **Restart**, **Close results**, **Change Kart**, **Change Track** and **Main Menu** |
| Track view (after Close results) | The frozen run and its HUD, with **Start Race**, **Track**, **Kart** and **Main Menu** on the bar |

The UI's own HUD lines keep their rows and text: laps, checkpoints, status, drift feedback and the meter. They gain colours: white detail, gold status. The timing line shows only with developer info.

## Look: the client's own dialogs

Every element below is defined in the build-70450 interface source (the [pinned mirror](https://github.com/Gethe/wow-ui-source/tree/172a387e3ab85b26e6640d3058d5ec1e6ccd4c63), Camelot loads the Mainline family). The addon references these by name or path and ships none of them. Each has a fallback: a missing template becomes a plain panel button or frame, and a missing font object becomes `GameFontNormal`.

| Element | Client source |
|---|---|
| Window, results | `BACKDROP_DARK_DIALOG_32_32`: `UI-DialogBox-Background-Dark` with the classic `UI-DialogBox-Border` (`Blizzard_SharedXML/Backdrop.lua`) |
| Menu dialogs | `BACKDROP_DIALOG_32_32`, as used by the shared `DialogBoxFrame` |
| Title banner | `DialogHeaderTemplate` (`Shared/Dialog/DialogTemplates.xml`) |
| Main menu buttons, Race!, Next | `MainMenuFrameButtonTemplate`, the Game Menu's red button (`Mainline/Frame/MainMenuFrameTemplates.xml`) |
| Other buttons, check boxes | `UIPanelButtonTemplate`, `UICheckButtonTemplate` |
| Cards (previews, lobby) | The tooltip border already used by the window, on a flat colour |
| Fonts | `Fancy48Font` and `Fancy32Font` (Morpheus) for the title and headings, `Game72Font` for the countdown, `GameFont*` for everything else (`Blizzard_Fonts_Shared`) |
| Sounds | `SOUNDKIT` `IG_MAINMENU_OPEN`/`OPTION`/`CHECKBOX_*` for menus, `UI_BATTLEGROUND_COUNTDOWN_TIMER`/`FINISHED` for 3-2-1-GO, and `LFG_REWARDS` once per finished run |

## New art: track previews

`addon/AzerothKart/Assets/UI/TrackPreviews.tga` is a 1024×512 opaque BGRA32 atlas (2 MiB raw), loaded on the first visit to the track screen. `scripts/build_ui_art.py` builds it:

- **Mirage cell:** scenery v1's own `Background.tga`, halved by an exact 2×2 box filter.
- **Test Oval cell:** a 500×300 painting of the oval from `Track.lua`'s geometry in the race's own colours, with a chequered start line and four counterclockwise arrows.

Both cells are original project art derived from the repository's own scenery and geometry; no external image is an input. The output is byte-identical on every platform.

![The two preview cells](track-previews.png)

```
python scripts/build_ui_art.py            # write the TGA
python scripts/build_ui_art.py --check    # verify the bytes
python scripts/build_ui_art.py --preview  # also docs/art/ui/track-previews.png
python scripts/preview_ui.py              # this page's layout picture (needs pinned Lupa and Pillow)
```

## Saved preferences

`AzerothKartDB.preferences` (account-wide) is a version-1 record, read defensively and written on deliberate successful choices or settings changes, never per tick:

| Field | Values | Default |
|---|---|---|
| `track` | `"test_oval"` or `"mirage_raceway"` | none: Test Oval |
| `kart` | a `Presentation.KART_SPRITES` id | none: the trike |
| `effects`, `sound` | booleans | true |
| `devInfo` | boolean | false |
| `scale` | 0.8, 0.9, 1, 1.1 or 1.25 | 1 |

Rules:

- Unknown values fall back to defaults, and other AzerothKartDB fields are never touched.
- A save keeps fields this version does not know. A record with a newer `version` is read but never overwritten.
- The saved kart is applied when the window is created. The saved track is applied the first time the window opens out of combat, because the Mirage loader needs a shown window and selection is refused in combat. Codex approved this first-open restoration through the existing guarded selector; it never starts a race.
- An untouched saved choice that fails to load keeps the default for the session and is not forgotten. A successful deliberate choice, including clicking the already-current fallback, replaces that preference through `Menu.Chose`; a deliberate track choice also supersedes any deferred restore. UI's selection transactions are unchanged. A newer-version saved record remains untouched even when the current in-memory choice changes.
- Choices made with the bar's quick **Track** and **Kart** buttons are remembered too, including track changes before any deferred restore has run.
- A saved size that no longer fits the screen shows at the largest size that does.

## Boundaries

`Menu.lua` is presentation only. It calls `UI.Start`, `UI.SelectTrack`, `UI.SelectKart`, `UI.DismissSummary` and the new `UI.SetEffectsEnabled`, and reads the state it shows. `UI.lua` gained only notifications:

- `refreshHud` → `Menu.Sync`;
- `render` → `Menu.RefreshRaceHud`;
- `refreshCountdown` → `Menu.OnCue`;
- `UI.SelectKart` → `Menu.OnKartChanged`;
- the window's `OnShow` → `Menu.OnWindowShown`;
- `UI.Create` ends with `pcall(Menu.Create)`.

If the front end fails to build, it reports once in chat and the window keeps its basic bar (Start, Stop, Track, Kart, Print Probe).

The multiplayer screen maps a copied PeerSession view to copy and enabled controls (`Menu.lobbyPresentation`). With no session bridge registered (`Menu.SetSessionBridge`), everything stays disabled and marked Coming soon. No session command is wired. The combined source contains Codex's adapter and start-clock contracts, but connecting the menu to them and the future live-race controller remains pending ([UI_FLOW_OWNERSHIP](../../UI_FLOW_OWNERSHIP.md)).

## Budget

Explicit UI counts were65/160/79 for the original Menu. Current integrated city screen/gates plus one staging background use **71 frames, 165 textures and 80 font strings**:

- **Frames:** the menu screens and their buttons, the header, the drag handle, a close watcher, the race overlay and the results buttons.
- **Font strings:** the old title line is replaced.
- **Creation:** everything is created once with the window; nothing is created per tick or frame.
- **Per frame:** the race HUD compares numbers and rewrites its text only when it can change, about ten times a second while the clock runs. The shown kart/garage turntable has its own visual spin callback while the race simulation is inactive; it never advances physics or the race clock.
- **Texture memory:** the preview atlas adds 2 MiB when the track screen is first opened. The turntable reuses the kart sheets the race already loads. The two scenery slots can retain Mirage and Stormwind simultaneously; the latter adds16MiB raw pixels. Native memory/performance remains unmeasured.

## Tests (offline)

`tests/test_menu.lua` runs the addon against a widget mock that, like the client, passes Show/Hide on to child frames. It covers:

- the main menu, one dialog at a time, and an unchanged run/track/kart while browsing;
- the full Single Player flow, including a refused start;
- every results path, the track view and the lap list;
- the garage and the turntable;
- settings and their effects, including no effects while switched off;
- saving, restoring and failed restores; explicit already-current fallback choices after a deferred or failed restore; quick-bar precedence before restoration; unknown and newer records; sizes that do not fit;
- a newer-version failed-load fixture: explicit fallback choices update in-memory preferences but preserve the original saved table/unknown field, stopped vehicle/race/clock/lap/checkpoint references, held input and inactive state;
- the coming-soon lobby and a mapped session view;
- sounds, and Alt+Z versus a real close;
- the combat track restore;
- the fallback when the front end cannot build, and missing templates.

`tests/test_ui.lua` retains Codex's lifecycle/capture/race assertions while combining both sides' module lists, counts, results-panel size and the Lua 5.4 `unpack` compatibility change. Both TOCs load 24 modules. The added preference/protected-state fixture passed `python scripts/test_lua.py --runtime lua51 --tests menu`; the shared [progress ledger](../../PROGRESS.md) records the integration checkpoint's complete executed checks. Offline results do not establish native templates, layout, input or persistence behavior.

## Client check (NOT RUN)

Fully restart the client after installing: `Menu.lua` and `TrackPreviews.tga` are new files. Then:

1. `/akart` shows the main menu over the dimmed track: the title banner, the "Azeroth Kart" title in Morpheus, and five red Game Menu buttons. Nothing reads "Lua error".
2. **Single Player**: all three ready tracks show their preview pictures; choosing one changes the track behind the dialog. **Next**: the kart spins on the turntable, the arrows and grid change it, and each kart shows its credit.
3. **Race!**: the menu disappears, a big gold 3-2-1-GO plays with beeps, and the top corners show LAP 1/3 and the clock. Only **Stop** shows on the bar.
4. Finish three laps: the results dialog lists each lap with the fastest in green, and a fanfare plays once. Try **Change Kart**, **Change Track**, **Main Menu**, **Restart** and **Close results**.
5. **Multiplayer** shows Coming soon with every control disabled. **How to Play** and **Settings** are readable. Settings sizes apply at once, and sizes too big for the screen are greyed out.
6. Drag the window by its title, `/reload`, and reopen. The track, kart and settings are remembered; the position may reset.
7. Press Alt+Z twice while in Settings: the window comes back on Settings. Escape during a race still ends the run (and may open the Game Menu).
8. Turn on developer info, then type `/akart probe` or click Print Probe: the counts are71/165/80.

Open questions for the client:

- whether `MainMenuFrameButtonTemplate` widens itself to fit "Multiplayer (soon)";
- whether the classic dialog border's corners meet the Close button cleanly;
- whether `Fancy48Font` is loaded in-game on Forever.
