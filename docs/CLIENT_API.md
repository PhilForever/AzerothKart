# Forever client identity and API probes

**Live-client status: NOT RUN.** On 2026-10-18, local file inspection found `_classic_beta_\WowB.exe` version `1.60.1.70450` and `.flavor.info` value `wow_classic_beta`; no running `Wow*` process was found. These files do not prove interface `16001`, runtime flavor, selected TOC or API behavior. Both TOCs retain candidate interface `16001` pending the following checks.

## Exact runtime identity checks

Enter each line separately in chat on the installed Forever client. Copy output verbatim; do not substitute a build inferred from a folder name. These `/dump` commands read data and do not start a drive or send network traffic.

```text
/dump GetBuildInfo()
/dump select(4, GetBuildInfo())
/dump WOW_PROJECT_ID, WOW_PROJECT_MAINLINE, WOW_PROJECT_CLASSIC
/dump type(C_AddOns), type(C_AddOns and C_AddOns.GetAddOnMetadata)
/dump C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata("AzerothKart", "Interface")
/dump C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata("AzerothKart", "Version")
/dump C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata("AzerothKart", "X-AzerothKart-TOC")
```

The final value should identify loaded metadata as `base` or `Camelot`; record what is returned, including nil. If the modern metadata API is absent, record that absence and inspect the AddOns list; do not guess TOC selection. Record whether the addon is enabled, any incompatibility reason and displayed version. Successful load does not establish keyboard safety.

## Exact capability checks

Run before driving, out of combat. `/akart` must have created its window for method checks. Each `type` check may legitimately return `nil`.

```text
/dump type(CreateFrame), type(InCombatLockdown), type(GetTime), type(GetFramerate)
/dump type(GetCurrentKeyBoardFocus), type(ChatEdit_GetActiveWindow), type(IsGameWindowFocused)
/dump type(AzerothKartMainWindow and AzerothKartMainWindow.EnableKeyboard)
/dump type(AzerothKartMainWindow and AzerothKartMainWindow.SetPropagateKeyboardInput)
/dump type(AzerothKart and AzerothKart.UI and AzerothKart.UI.kart and AzerothKart.UI.kart.SetRotation)
/dump type(C_ChatInfo), type(C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix)
/dump type(C_ChatInfo and C_ChatInfo.SendAddonMessage), type(C_ChatInfo and C_ChatInfo.SendAddonMessageLogged)
/dump type(Enum and Enum.SendAddonMessageResult)
/akart probe
```

The prototype reports build/interface/selected TOC, input capabilities and unavailable registered events. Capture must remain disabled if a required input capability is missing. Every mouse-down while driving releases capture, including clicks inside the canvas and on overlapping UI; this does not depend on a guessed mouse-over focus owner. The Start click's actual event order requires a live check. `IsGameWindowFocused` is optional; its presence and actual Alt-Tab behavior must be recorded separately. An API returning `function` is availability evidence only: semantics, restrictions and safe event ordering still require the manual matrix.

Do not use `/dump` to call `SetPropagateKeyboardInput` or other mutating input methods. The addon guards its own propagation setter out of combat; test through deliberate Start/Stop and combat transitions. Never bypass these guards.

## Timing and persistence readback

```text
/dump GetFramerate()
/dump GetCVar("uiScale"), GetCVar("useUiScale")
/dump AzerothKartDB and AzerothKartDB.schemaVersion
/akart probe
```

Record baseline and stopped-run output as described in [FEASIBILITY.md](FEASIBILITY.md). Starting chat while driving is a focus-loss test and stops capture, so collect metrics after Escape. `maxElapsed` is a frame interval, not addon CPU time. Object counts cover the UI module's explicit allocations, excluding the bootstrap event frame and template internals. Follow [the client checklist](../tests/MANUAL_CLIENT_CHECKLIST.md) for the temporary persistence sentinel; schema readback alone cannot prove a save occurred.

## API confidence ledger

| Capability | Current evidence | Remaining verification |
|---|---|---|
| Installed executable/flavor file | Read locally, 2026-10-18 | Runtime build/interface/project ID |
| Interface 16001 / Camelot selection | Candidate TOCs only | Runtime metadata and successful addon load |
| Keyboard events/propagation | Guarded prototype and offline checks | Focus, chat, click-away, combat/taint on actual client |
| Rotation/rendering/OnUpdate | Prototype authored | Correct rotation, elapsed timing, scaling/performance |
| `C_ChatInfo` availability | Probe commands prepared | Actual function types and prefix registration result |
| Message payload/rate behavior | Proposed experiment only | Measured private-channel send/receive, throttle, RTT/recovery |
| SavedVariables | Minimal schema authored | Isolated sentinel across reload/logout/full restart |

## Reference material to verify against the client

These are reference starting points retained from the scaffold, not observed results for this build. Their current contents were not used to mark any test passed. Keep packet size, prefix limits and return semantics provisional until actual API probes and F4 measurements confirm them.

- [Frame:EnableKeyboard](https://warcraft.wiki.gg/wiki/API:Frame_EnableKeyboard)
- [Frame:SetPropagateKeyboardInput](https://warcraft.wiki.gg/wiki/API:Frame_SetPropagateKeyboardInput)
- [TextureBase:SetRotation](https://warcraft.wiki.gg/wiki/API:TextureBase_SetRotation)
- [OnUpdate](https://warcraft.wiki.gg/wiki/OnUpdate)
- [C_ChatInfo.SendAddonMessage](https://warcraft.wiki.gg/wiki/API:C_ChatInfo.SendAddonMessage)
- [C_ChatInfo.RegisterAddonMessagePrefix](https://warcraft.wiki.gg/wiki/API:C_ChatInfo.RegisterAddonMessagePrefix)
- [C_ChatInfo.SendAddonMessageLogged](https://warcraft.wiki.gg/wiki/API:C_ChatInfo.SendAddonMessageLogged)
- [CHAT_MSG_ADDON_LOGGED](https://warcraft.wiki.gg/wiki/CHAT_MSG_ADDON_LOGGED)
- [Community Forever API dump/examples](https://github.com/Atraeau/WoW-Addons)

Last local inspection: 2026-10-18. Actual-client tests: **PENDING**.
