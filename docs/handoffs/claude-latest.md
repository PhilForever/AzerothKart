# Claude handoff — four more karts, a Kart button and untinted kart art

Prepared 2026-10-21 about 01:45 CEST (Europe/Oslo) by Claude (rendering/UI/sprites owner).

The base is `1004e73`: the effects handoff, on Codex's `7fcdd89`. This session's commits on `claude/track-ui`:

1. `f675610`, the scope reservation;
2. `c6e1b5e`, drift and boost effects;
3. `1004e73`, the effects handoff;
4. `abe98f6`, four more karts, the Kart button and untinted kart art;
5. this handoff.

M0/M1/M3 acceptance and the multiplayer gate are unchanged and remain open. Earlier handoffs are in Git: `812d132` (the trike) and `1004e73` (the effects).

## Owner instructions

- "Start with drift and boost effects, then implement more vehicles."
- The owner picked the vehicles: "Steam Tank, Dwarven Biker, Griphon Rider, Gyrocopter". These are the four WC3Vault listings in the [roster](../art/karts/roster.md), the third being the Gryphon Rider.
- Mid-task: "Little side note! There's no need to keep the color changing of the entire model during boost. That was just a placeholder until we made actual effects." Then: "By during boost, I mean during drift of course."
  - Applied to every whole-kart wash on loaded art, drift tiers and boost alike: all of them were placeholders for the effects that now exist.
  - The primitive fallback keeps its phase colours, since it has no other feedback.
- Standing: the owner pushes `claude/track-ui` from Windows, and runs in-game checks himself.

## Reservation

The vehicles task is complete in `abe98f6`, so the reservation from 2026-10-20 is released. Its regions in `UI.lua` were:

- the visual layout of `UI.Create`;
- the kart and effect helpers before `layoutTrack`;
- `layoutTrack`;
- the kart block of `render`;
- the button sync at the end of `refreshHud`.

No new reservation is held. Integration with Codex's latest is the next step (below).

## Deployment: install held

**Live folder.** Checked at about 23:30 UTC on 2026-10-20, the AddOns folder holds Codex's runtime `8f66c5a`:

- Core, NetworkProbe, TransportProbe and UI match `codex/forever-probe`;
- `README_ADDON.md` is `8f66c5a`'s with CRLF line endings;
- the assets and `Presentation.lua` are unchanged from Claude's `c6e1b5e` install.

Codex installed it after merging the effects (`8195da9`); Codex's handoff gives the backup and manifest path (`local-artifacts/install-backups/20261021-005314-298-…`).

**Why nothing was installed.** `abe98f6` does not contain Codex's Close results button (`5f03716`) or its Forever transport fix (`8f66c5a`), so installing it would roll both back. It would also change the owner's build in the middle of Codex's two-player series: Codex's next task is a reverse-roles AKT723 trial on the same build.

**What it needs.** The four karts reach the client only through a combined build, installed after that trial and with the deployment coordinated.

## Trial integration with Codex's latest (scratch clone; no branch changed)

`git merge --no-ff codex/network-window-akt723` (`400590e`) on top of `abe98f6`:

- **Code merges cleanly.** `UI.lua` combines Codex's `UI.DismissSummary`/Close results button with Claude's `UI.SelectKart`/Kart button without conflict. `Presentation.lua` changed on one side only.
- **Conflicts are count statements only:**
  - CHANGELOG, README_ADDON, API_CONTRACTS (two), ASSETS, TEST_PLAN and MANUAL_CLIENT_CHECKLIST (two);
  - five frame-count assertions in `tests/test_ui.lua`: Codex's literal `10`, Claude's `UI_FRAMES`.
- **Resolution:** keep `UI_FRAMES` and set it to 11, for the Close results and Kart buttons. The combined suite then passes on Lua 5.1 and 5.4, with mock counts frames=11, textures=151, fontStrings=13. Codex's result-dismissal and transport tests pass unchanged.
- **Combined docs** then state 11/151/13 in every current-count statement. These include Claude's `drift-boost.md`, `goblin-mortar-trike.md` and `roster.md`, which say 10/151/13 for this branch alone. Keep Codex's refinement of the effects contract: "Particle repeatability applies to identical sampled-state/effect-update sequences, not different rendering cadences."

**Exact commands (not executed).** Either path needs explicit authorization; nothing was run in another worktree.

- **Codex as integrator,** in `AzerothKart-Codex-Review`, after the AKT723 trial:
  1. on a fresh branch from `codex/network-window-akt723`, run `git merge --no-ff claude/track-ui`;
  2. resolve as above;
  3. run `python scripts/test_lua.py --runtime both` and `python scripts/validate_project.py`.
- **Claude, if the owner authorizes it:** the same merge into `claude/track-ui`, then a verified install of the combined build after the trial.

## Branch, commits and workspace

| Item | Value |
|---|---|
| Worktree / branch | `AzerothKart-Claude` / `claude/track-ui` at this commit (after `abe98f6`) |
| Push | Owner only: this session's git proxy refuses the repository. `git -C "C:\Users\bakke\Downloads\Forever_Addons\AzerothKart_Codex_Project_Pack\AzerothKart-Claude" push origin claude/track-ui` (origin has `812d132`) |
| Not done | No merge into `main` (still `f923d15`) or into any Codex branch; no tag, release, install or client input. Codex's branches and worktrees were only read |

**Workspace notes:**

- `local-artifacts/third-party/<slug>/` (git-ignored) holds each vehicle's archive and extracted files: `goblin-mortar-trike`, `steam-tank`, `dwarven-biker`, `gryphon-rider` and `gyrocopter`.
- `local-artifacts/bundles/` (git-ignored) holds the git bundles between Claude's cloud clone and this worktree. `codex-network-window-akt723-400590e.bundle` was exported read-only for the trial merge.
- The untracked `Claude outputs/` folder, created by the desktop app, is still left for the owner.

**Git environment note:**

- Commits are made in a cloud clone with this repository's local identity, then moved here as git bundles and fast-forwarded, so the hashes are identical.
- Git runs from a Linux shell on the developer machine with `--git-dir=.git/worktrees/AzerothKart-Claude`, `core.createObject=rename`, `gc.auto=0`, `maintenance.auto=false` and `gc.worktreePruneExpire=never`.
- **Never run `git worktree prune` or `git gc` there**: the recorded gitdirs are Windows paths.

## Completed: four more karts (`abe98f6`)

Details, sources and the client checklist are in [the roster](../art/karts/roster.md).

**Vehicles.** The Steam Tank, Dwarven Biker, Gryphon Rider and Gyrocopter are 1024×1024 sheets of 64 three-quarter headings, like the trike. Each is rendered from its WC3Vault archive's model and its own JPEG BLP texture.

- **Source:** the wc3c ITE project; authors unknown, no terms in any archive. Redistribution is unresolved for release review.
- **Flyers** hover 4 units up, with detached shadows.
- **Gyrocopter stand-ins:** its rotor blur texture is not shipped, so the blades are hidden behind an original translucent disc. Its pilot's body texture is also missing and gets a flat leather tone.

**Tooling:**

- `scripts/wc3jpeg.py`: a pure-Python baseline JPEG decoder using libjpeg's integer inverse DCT.
- `scripts/build_wc3_kart.py`:
  - a `VEHICLES` table, JPEG BLP1, hidden bones, substitute textures, hover lift and the rotor disc;
  - per-vehicle frame-window asserts;
  - `--all ROOT`.
  - The trike's bytes are unchanged.
- The review images' third row now shows in-between headings instead of the retired tints.

**`Presentation.lua`:**

- a `sheet()` constructor;
- a display `name` on every sprite;
- the four new sprites, with anchors from each model's `--emitters`;
- optional `trails` (the Gryphon Rider's wingtips) and an empty `exhausts` list;
- `EFFECTS.trailColor`;
- `KART_ORDER` and `nextKart`.

**`UI.lua`:**

- `sizeKart`, extracted from `layoutTrack`;
- `applyKartSprite`, the creation-time guarded checks as a reusable function;
- `loadKartSprite`, which now records `UI.kartId`;
- `kartLabel`;
- `tintKart`, which keeps loaded art at a neutral vertex colour, and the matching tint index in `render`;
- the new public `UI.SelectKart(id)`;
- the **Kart** button in `UI.Create`: 212×24 at BOTTOMLEFT (496, 12), between the Track and Print Probe buttons;
- an enable/disable sync at the end of `refreshHud`.

## Tests performed (`abe98f6`)

| Command / check | Result |
|---|---|
| `build_wc3_kart.py … --check`, all five vehicles | **CHECK PASS** on Python 3.13 (cloud, `--all`) and Python 3.10 (developer machine, one vehicle per run), with identical bytes: trike `a723b067…3208` (unchanged), Steam Tank `e5ff5c65…184c`, Dwarven Biker `564d5256…0e38`, Gryphon Rider `06d94738…e92b`, Gyrocopter `2f00ca98…f50d` |
| `wc3jpeg.py` against Pillow (libjpeg) | Samples identical on all five shipped JPEG textures (cloud) |
| `build_effect_sprites.py --check`, `build_kart_sprites.py --check` | PASS on both machines |
| `test_lua.py --runtime both` | **PASS** on both machines; 34 files parsed. Mock: six karts cycle while stopped, one guarded load per choice, refused while driving or when a load fails; frames=10, textures=151, fontStrings=13 |
| `validate_project.py` | Only the 2 pre-existing Windows-path links in PROGRESS.md fail, on both machines |
| Trial merge with `400590e` | Combined suite PASS on Lua 5.1 and 5.4 with `UI_FRAMES=11` (scratch clone) |
| Review images | The four new sheets checked at 64 headings and on the Mirage background; the effects review image regenerated untinted |

**NOT RUN:**

- the four karts, the Kart button and their effects in WoW Forever;
- any install of `abe98f6`;
- FPS or memory measurement: the four sheets add 16 MiB of raw texture data when all are loaded;
- `tests/test_install_local.ps1` and Windows `validate_project.py`;
- multiplayer.

## Client check (owner; NOT RUN; after a combined install)

Fully restart the client, because the sheets are new files. Then follow [the roster checklist](../art/karts/roster.md#client-check-not-run):

- the Kart button cycles six karts, with matching labels;
- correct facing at every heading, and detached flyer shadows;
- the Gyrocopter's rotor and pilot read well;
- effects start at sensible points, with no whole-kart colour change;
- the button is disabled during a run;
- Print Probe shows 11/151/13 on the combined build.

## Changes Codex must review

- **`UI.lua`:**
  - the Kart button's `OnClick` callback in `UI.Create` (a control callback);
  - the button sync in `refreshHud`;
  - `UI.SelectKart`: refused while active, for an unknown id or without the kart Texture; restores the previous art on a refusal; never writes run, result, track or simulation state.
  - Unchanged: `step`, Start/Stop, capture, events, and `SelectTrack`'s transaction.
- **`tests/test_ui.lua` (shared):**
  - the `UI_FRAMES` constant;
  - `NEUTRAL` replaces the per-phase sprite tints: the art stays untinted and unrewritten in every phase;
  - a new kart-picker block.
  - No capture, lifecycle, clock or race assertion was relaxed.
- **`tests/test_presentation.lua`:** the per-frame coverage floor drops from 12% to 6% of a frame window, for the flyers' thin wings and larger windows.
- **Shared budget:** +1 Frame (10/151/13 here, 11/151/13 combined with Close results), and +16 MiB of raw texture data when all four new sheets are loaded.
- **`docs/API_CONTRACTS.md`:** the roster/Kart button proposal and the tint retirement note.

## Pending PROGRESS ledger entry (integrator to append; PROGRESS.md was not edited)

> ### 2026-10-21 ~01:45 CEST — Claude / `claude/track-ui`, four more karts and a Kart button
>
> - Owner-picked Steam Tank, Dwarven Biker, Gryphon Rider and Gyrocopter: 64-heading sheets rendered from Warcraft III models (wc3c ITE project via WC3Vault; authors unknown, redistribution unresolved). New pure-Python JPEG BLP decoder.
> - Stopped-only Kart button cycling six cosmetic karts (`UI.SelectKart`, +1 Frame: 10/151/13 alone, 11/151/13 with Close results). Loaded kart art is no longer tinted per phase (owner direction); the primitive keeps its colours.
> - Sheets byte-identical on Python 3.10 and 3.13. `test_lua.py --runtime both` PASS on both machines. Trial merge with `400590e` PASS (scratch clone). Not installed: the live folder holds Codex's `8f66c5a` for the two-player series.
> - **NOT RUN:** client appearance.

## Next

1. **Integrate and install.** After the AKT723 trial, combine `claude/track-ui` with Codex's latest (Codex, or Claude on owner authorization). Then install the combined build with coordinated backup and verification, and the owner checks the karts.
2. **More karts.** The release target is eight ready karts (ADR 0010), and six are registered. The concept roster still lists the Siege Tank and Gnome Drag Car, with the Shredder optional. Find models that ship their own textures, check their terms, and let the owner pick.
3. **Maps.** Three ready maps are the other content target. Mirage is the only production map so far.
