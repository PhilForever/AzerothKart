# Mirage scenery v1 and kart sprite — owner's in-game check

Reported by the owner on 2026-10-20, after the verified install of `claude/track-ui` at `76af4aa` (AddOns backup `local-artifacts/installs/20261020-122432/`). The evidence is one owner screenshot plus the owner's words. The screenshot also shows other players' names and is not copied into the repository. Claude sent no client input.

**Screenshot (Mirage selected, stopped at spawn):**

- The Azeroth Kart window shows scenery v1 at the start straight: the salt flats, the dirt lane with tire streaks, the checkered start line, the infield timing tower, a start banner and the goblin pit (workshop roof, awning, barrels, crates, crane, rocket, pit box, scrap heap and tires). The view matches the offline play-camera preview of the same spawn position.
- The kart is the Goblin Drag Car sprite, not the orange primitive: nose north, centered on the start checkers, with no visible box or halo around it.
- The HUD reads `Laps: 0 | Current: 0.00s | Last: -- | Best: --`, `Checkpoints: 0/4 | Next: North`, `Mirage Raceway blockout | Start for 3 laps | Off-road: rough salt` and `Speed: 0 | Ticks: 0 | Dropped: 0.000s | Sample: 0.0s`; the track button reads **Track: Mirage Raceway**.
- The scenery shadows were offset copies of their objects. The timing tower's shadow was a detached gray square, the banners' shadows were separate gray streaks, the crane, rocket and awning shadows floated beside their objects, and a gray oil blob in the pit box read as a shadow of nothing.

**Owner's words:** "Looks aight." Then: "Everything else looks and feels good, some issues with shadows on the assets around as you can see on the screenshot. Feel free to fix that next."

**What this establishes:** the replaced `Background.tga` and the new `GoblinDragCar.tga` load and render in the owner's WoW Forever client, with the expected orientation and crop at spawn, and the owner reports that everything apart from the shadows looks and feels good. It records no build or Print Probe numbers, frame rate, drift/boost tints or sprite rotation while driving; those stay unmeasured. The shadow issue is addressed by the shadow pass that follows on `claude/track-ui`, whose client appearance is **NOT RUN**.

**Update, 2026-10-20:** the owner later approved the shadow pass; see [the approval record](2026-10-20-trike-and-shadows-owner-approval.md).
