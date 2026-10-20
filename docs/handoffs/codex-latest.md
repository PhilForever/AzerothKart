# Codex handoff — Claude sprite review and Warcraft III source direction

Prepared 2026-10-20, Europe/Oslo. Scope: review Claude's committed sprite/shared changes and reconcile the owner's Warcraft III asset direction. This review adds documentation only; no gameplay change, imported asset, install, client input, merge or push.

## Branches, scope and integration state

| Item | Verified value |
|---|---|
| Canonical repository | `https://github.com/PhilForever/AzerothKart.git` |
| Main / local origin/main | `f923d15f5cc8f306a0b47ad082587474abd1af8d`; last published runtime `7acab18` |
| Codex prior checkpoint | `55709687f39103c5dad0acbbfe4bba147a47356f` on `codex/handoff-contracts` in `../AzerothKart` |
| Claude reviewed implementation | `520275e07990a626ac25818402eeee55ab956d0d` |
| Claude reviewed tip | `46931e16de940e0ab0dc59057b0484c93f78670e` on `claude/track-ui`, inspected clean in `../AzerothKart-Claude` |
| Isolated review worktree | `../AzerothKart-Codex-Review`, branch `codex/claude-assets-review`, created from immutable `46931e1` |
| Review result commit | Resolve with `git log -1 --format="%H %s" codex/claude-assets-review`; use the completed reviewed hash, not a later moving tip |

Reserved review edits: AGENTS, README, API_CONTRACTS, DECISIONS, ASSETS, INDEX, asset-source ledger, ADRs 0005/0009, PROGRESS and this Codex handoff. No runtime/test edits were needed. Claude's own handoff is retained as received; its pending-policy and older branch descriptions are historical and superseded by the review here.

The canonical checkout's three zero-byte untracked placeholders remain preserved: root `codex-latest.md`, root `claude-latest.md` and `docs/handoffs/claude-latest.md`. Do not stage/delete them blindly. The last collides with Claude's new tracked handoff if an integrator later updates that checkout; inspect and preserve it before changing branches. Neither the canonical checkout nor Claude's checkout was switched, reset or edited here. No milestone is promoted.

## Review disposition

**Approved, no blocking regression found in the reviewed diff:**

- Shared `tests/test_ui.lua`: texture-load assertions now count per path; sprite padding changes the drawn quad while body footprint assertions remain; tint-cache assertions watch vertex-color writes. Capture, lifecycle, clock and race assertions were not relaxed. New cases cover creation-time sprite refusals and scripted sprite/primitive equivalence.
- Mixed `UI.Create`: one `loadKartSprite()` call after the existing pooled kart Texture is created and before sizing/initial render. Event scripts, controls, capture and initial-state transaction are unchanged.
- `Presentation.KART_SPRITES`, `DEFAULT_KART` and footprint metadata are additive presentation data, now documented as implemented/review-approved in [API_CONTRACTS](../API_CONTRACTS.md). No Physics/Race field or existing function signature changed.
- The sprite, reproducible generator, source sheet/preview and structural manifest changes align. Protected Physics, collision geometry, Race/Laps/Checkpoints, Input/Loop/Core and TOC loading remain unchanged from `5570968`.

The fallback covers creation-time failure/refusal, including initial vertex-tint failure. Later phase `SetVertexColor` calls are direct calls; do not describe this as recovery from any future API failure. The 900-frame equivalence check compares all returned Physics fields and selected race/checkpoint fields (status, totalTicks, nextGate, completedLaps), not every nested UI/race field.

## Accepted asset policy

[ADR 0009](../adr/0009-warcraft-iii-asset-reuse.md) is **accepted project direction**, following the owner's confirmation to Claude and Codex. Original art and Warcraft III game/community material are allowed sources. AGENTS, ADR 0005, README, decisions and the source ledger now agree. Claude need not ask again whether WC3 is an allowed source.

Keep Mirage's established overhead style, geometry registration, footprint, pooling and performance budget. Prefer suitable textures already in the WoW client. Each imported file needs source/author, applicable terms and permission status, date, modifications, use and credits; honor community author conditions. Owner authorization and WIIIUI's precedent do not establish a general third-party redistribution grant. Keep unresolved status explicit for release review. No third-party WC3 file was imported in this review, and no suitable drag-car source being found is not proof that none exists.

WIIIUI's README/implementation demonstrates faction-themed UI and bundled texture paths. No applicable general asset license or Blizzard grant was established in the inspected root/README. Avoid the earlier categorical statement that the entire repository has no license. The ADR links the inspected primary sources and WoW addon policy.

## Current implementation and evidence limits

| Area | Implementation / evidence | Still pending |
|---|---|---|
| Simulation | Physics v6, fifteen fields; 60 Hz, bounded five-step catch-up; steering, drift tiers/correction grace, boosts, rough-ground slowdown and point-center perimeter clamp | v6 human handling acceptance; arbitrary swept/prop/kart collisions absent |
| Race | Ordered directional checkpoints/laps, 180-tick countdown, three-lap finish and retained partial/interrupted results; offline regressions | Current full race UI/finish/restart play; persisted records absent |
| Tracks/camera | Oval default; selectable 1024-square Mirage blockout, separate geometry, scale-1.5 north-up follow camera with 60-world look-ahead and cropped UVs | Moving camera/edge/scale/performance acceptance; scenery remains blockout |
| Kart | Original 64×128 BGRA32 straight-alpha Goblin Drag Car; 20×40 padded world quad, visible body inside 17×31. Mirage quad 30×60, body 25.5×46.5. One load at creation; cached multiplicative phase tints; primitive fallback | Actual client alpha/filtering/facing/rotation/tints/new-file loading; roster, shadow and VFX absent |
| UI budget | Same explicit 9 frames / 111 textures / 13 font strings; no per-tick UI creation, asset loading or chat | Client CPU/GPU/FPS/memory limits not measured |
| Networking | No transport/lobby/sync, ghosts, AI or items | Two-client throughput/loss/throttle/order/latency/reconnect gate entirely unmeasured |

Existing build-70450 evidence confirms opaque background load, stopped camera crop, larger primitive kart, aligned Start strip and clipped West strip. Earlier owner combat smoke confirmed closure/message/normal controls; it does not prove every held-input/taint case. On 1.60.1/70450, interface16001/project18/Camelot, public `IsGameWindowFocused` and `IsWindowFocused` are absent. Do not invent a getter, automate WoW character movement or change UI scale/CVars for this visual task.

UI still mixes presentation and controller. State/previous-state/race/track tables are borrowed read-only by convention, not protected snapshots. Physics speed is signed, heading radians with +X east/+Y north; no stored vx/vy or collision-normal stream exists. Preserve integer race timing, finishing callback, capture/release behavior, stopped map-selection transaction and failure retention. Camera/art never feeds geometry or authoritative state. See [contracts](../API_CONTRACTS.md), [AGENTS](../../AGENTS.md), [FEASIBILITY](../FEASIBILITY.md) and [prior static evidence](../evidence/2026-10-20-mirage-camera-static.md).

## Tests actually executed by Codex in this review

Windows Python `C:/Python314/python.exe`; Lua 5.1 through pinned Lupa 2.8. The existing ignored dependency directory from the canonical checkout was supplied via this shell's PYTHONPATH; no global runtime was installed.

| Command / check | Result |
|---|---|
| `scripts/test_lua.py --runtime lua51 --tests presentation ui` | PASS — 29 Lua files parsed, both selected modules executed. Once-only sprite load, cached tints, six creation-time refusal cases; 900-frame Mirage sprite/primitive check identical on all Physics and selected race fields through tick1275. Existing camera/lifecycle/countdown/race/capture/pooling assertions remain passing. |
| `scripts/build_kart_sprites.py --check` | CHECK PASS — 32,786 bytes, 64×128, 3,190 visible / 2,562 opaque pixels; SHA-256 `cc7c1c6928501bcb9943040c13c478efb7ac08ddab47e7fa527e11f7d3bb126a`. |
| `scripts/validate_project.py` | STATIC PASS — 48 expected paths, TOCs, links, protocol and header-only network ledger. Windows executes the links that failed under Claude's Linux shell. |
| Review PNG inspection / protected-source diff | Original overhead sprite/review board inspected; no blocking source/interface issue found. This is not a client appearance pass. |
| `git diff --check` / staged equivalent | Whitespace checks recorded with the review commit. |
| Actual Forever sprite check, deployment/reload/restart, full current suite / Lua5.4, broad performance/scale and multiplayer | NOT RUN by Codex this review. No client availability claim or milestone pass inferred. |

Claude separately reports a full 29-file/16-module Lua5.1+5.4 pass, sprite/background/layout reproduction and clean whitespace in its Linux environment; its static validator had two pre-existing Windows-path link failures. These are attributed reports in [Claude's handoff](claude-latest.md), not reruns by Codex. The prior Codex checkpoint independently passed all sixteen Lua5.1 modules including 10k-tick replay, on the pre-sprite state.

## Integration and next task

This branch is review-approved but **not merged to main or Claude's branch**. AGENTS requires explicit integration authorization after review. No push/release/install is implied by this review.

After the owner authorizes synchronization, first verify Claude's branch and clean status, resolve the immutable completed review hash, then apply it in Claude's worktree only if it is still based on the reviewed tip:

```powershell
git -C ../AzerothKart-Claude status --short
git -C ../AzerothKart-Claude branch --show-current
git log -1 --format="%H %s" codex/claude-assets-review
# After inspecting those results, substitute the reviewed hash:
git -C ../AzerothKart-Claude merge --ff-only <reviewed-commit-hash>
```

These are instructions, not executed synchronization. If Claude has diverged or has uncommitted work, stop and coordinate; do not force, reset, rebase or auto-merge. Do not run `git worktree prune` or `git gc` from the Linux mount environment (see Claude's reported metadata caveat). Main integration is separately coordinated and must preserve the canonical untracked handoff placeholder.

**Next single task:** coordinated short client check of this sprite's load/alpha/facing/rotation and phase tints, using [Claude's precise procedure](claude-latest.md). No repeated combat/long profiling matrix. While awaiting a client slot, Claude may build Mirage scenery v1 under accepted ADR0009 against unchanged geometry, with per-file provenance; no new source-policy approval is required. Codex continues simulation ownership. M0/M1/M3 acceptance and the multiplayer gate remain open.
