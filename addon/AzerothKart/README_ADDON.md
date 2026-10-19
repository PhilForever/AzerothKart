# Azeroth Kart — developer installation

This folder is the WoW addon source for a local three-lap Test Oval prototype. Install it as `Interface/AddOns/AzerothKart` for the verified Forever client. The `_Camelot.toc` is the documented flavor; the base `.toc` is the fallback. Confirm runtime TOC selection after client changes.

Open `/akart` and deliberately click **Start Test Drive** outside combat. W/Up accelerates, S/Down brakes/reverses, and A/D or Left/Right steers. Hold Space while turning on the road at speed 90+ to charge a drift; release Space while keeping the turn to boost. Grass slows the kart and cancels drift/boost; perimeter walls scrub speed while allowing sliding.

Drive counterclockwise through North, West, South and Start. The third ordered lap ends the run at its exact simulation tick, releases controls and shows total/last-lap times. Stop/Escape, Close, another key, chat focus, any mouse click, hiding or focus loss releases capture. Combat closes the window and retains an interrupted partial result. Reopening retains the frozen summary; deliberately click **Restart** or Start for a fresh run. Capture never resumes automatically.

`/akart probe` or **Print Probe** reports timing, capabilities and explicit UI counts only on request. There is no networking, countdown, saved race progress, best record or persistence of results. M0/M1/M3 acceptance remains open; current client handling, finish/restart appearance and outstanding input checks are pending. See the canonical [progress handoff](../../docs/PROGRESS.md) for executed checks and [client checklist](../../tests/MANUAL_CLIENT_CHECKLIST.md) for deferred manual steps. Those links resolve in the source checkout.
