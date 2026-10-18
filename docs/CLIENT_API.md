# Forever API reference and confidence

**These are external references, not proof that an untested client behaves identically. Confirm runtime behavior on the installed game build.**

## Verified *by documentation*, not tested by this package
- Forever uses a modern Mainline-family UI/API and interface `16001` in documented build 1.60.1. Prefer checking `/dump select(4, GetBuildInfo())` against installed build before modifying TOC. A Forever `Camelot` flavor TOC has been observed in developer tooling; test which TOC is discovered.
- `Frame:EnableKeyboard`, `OnKeyDown` / `OnKeyUp` exist; `SetPropagateKeyboardInput` is restricted in combat. Never call while in combat. Focus may be stolen by edit boxes and game UI.
- `TextureBase:SetRotation` exists and accepts radians; use texture pooling, not per-frame allocations.
- `OnUpdate` receives elapsed; fixed timestep needed to avoid framerate-dependent physics.
- `C_ChatInfo.RegisterAddonMessagePrefix` and `SendAddonMessage` support a 16-character prefix and up-to-255-byte payload. Return is enqueue result, not remote ACK; throttles can be dynamic. `WHISPER` and `PARTY` availability requires testing.
- `C_ChatInfo.SendAddonMessageLogged` is for user-generated text and `CHAT_MSG_ADDON_LOGGED` is its event. Prefer **non-logged** `SendAddonMessage` for machine-readable game-state messages and never send arbitrary free-text there. If users can send text, use logged API and constrain/moderate.
- Combat-based secret values cannot be inspected or used in arbitrary Lua logic. Our game does not depend on such data.

## Probe instructions
- Print `/dump select(4, GetBuildInfo())` and screenshot the addon list showing that TOC loaded.
- Open `/akart` while out of combat, start driving, test W/A/S/D arrows, ESC, click-away to chat, UI scale changes, `/reload` and fresh login.
- Enter combat **without addon focus** then open window; ensure no restricted API calls and racing stays disabled. Starting combat during test drive should safely end keyboard consumption only when legal, and no taint/script errors. If release is impossible in combat due restrictions, pre-design guard and fail-safe; do not assume.
- Test in instanced/group contexts separately from solo world.
- Measure frame update time, object counts, FPS if API permits or external game UI instrumentation manually.

## Public references
- https://warcraft.wiki.gg/wiki/API:Frame_EnableKeyboard
- https://warcraft.wiki.gg/wiki/API:Frame_SetPropagateKeyboardInput
- https://warcraft.wiki.gg/wiki/API:TextureBase_SetRotation
- https://warcraft.wiki.gg/wiki/OnUpdate
- https://warcraft.wiki.gg/wiki/API:C_ChatInfo.SendAddonMessage
- https://warcraft.wiki.gg/wiki/API:C_ChatInfo.RegisterAddonMessagePrefix
- https://warcraft.wiki.gg/wiki/API:C_ChatInfo.SendAddonMessageLogged
- https://warcraft.wiki.gg/wiki/CHAT_MSG_ADDON_LOGGED
- https://github.com/Atraeau/WoW-Addons (community Forever API dump / examples)

Last authoring review: 2026-10-18. Client tests: **NOT RUN** in this project pack.
