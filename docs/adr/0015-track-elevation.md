# ADR 0015 — Track elevation

Status: Art-only elevation and inert generated height metadata accepted for the reviewed9143949 integration, 2026-10-23. Physical slopes, crests, layered bridges and kart-height rendering remain proposals; this review does not approve their architecture or numerical tuning. Native city checks NOT RUN.

## Context

Azeroth Kart's tracks are flat: one painted picture under analytic 2D collision (`Circuit.lua`). Some capitals are not. With the Darnassus and Undercity routes the owner wrote: "What would be cool is if you could figure a way to add elevation to maps, as some of our maps clearly need it." Offered three steps, he chose all three: **looks only first**, **slopes you can feel** and **bridges over the track**.

The camera looks north at 36.87 degrees, scenery heights lean north (`lean`), and the scenery's sun is in the north-west. In that view only south-facing walls show; a drop away from the camera shows as its brink and the shadow beyond it; a north-south step shows only as a line and a shadow.

## Scoped decision and remaining proposals

1. **Looks (implemented, art only).** A city layout may declare `elevation`: a ground height, level polygons with heights (optionally with their own paving), the street's heights as loop-arc anchors joined by smoothstep ramps, and a height per branch. The painter keeps the street where it lies (the picture's reference) and draws what the heights make visible: retaining walls on the higher ground's southern rows, or hanging below a raised street's southern wall; lit brinks and shaded feet of drops; sun shadows cast south-east; a small brightness lift with height; ramps lit by their slope with paving joints across them. Models keep off every drawn wall. Cities without `elevation` paint byte for byte as before.
2. **Data (generated, inert).** `CapitalCities[id].elevation = {centerline={...}, branches={{...}}}`: the street's height at every centerline and branch point. `Circuit.new` ignores it until Codex accepts a consumer.
3. **Slopes you can feel (Codex).** Proposed: a deterministic grade term `-G * dh/ds` along the heading from the nearest capsule's endpoint heights, `G` tuned so the painted ramps (up to about 16%) stay playable. Optional crests with a short airborne state, opt-in per anchor.
4. **Bridges over the track (Codex, then UI/Presentation).** Proposed: a self-crossing street is valid when its passes differ by a clearance (40); a kart belongs to the capsule it last drove on and ignores capsules beyond a step height (12), so the lower pass runs under the deck. Gates stay on one pass. The deck needs an overlay drawn over lower-pass karts and under upper-pass karts, pooled at creation. The painter would draw the deck, its parapets and its shadow on the lower pass.
5. **Kart height (UI/Presentation).** Optionally scale a kart's sprite and offset its shadow by its height. Deferred while Codex's multiplayer-grid reservation holds those files.

## Consequences

- Darnassus (three tiers: 44, 22, 0) and Undercity (the Trade Quarter sunk 30) show their levels now; karts drive them flat. Undercity version 2 (proposed on `claude/undercity-river`, 2026-10-23) keeps the sunken Trade Quarter beside its new course and raises its three stone bridges in painted humps 6 units high, with ramps either side; the karts drive them flat too.
- The generated heights let Codex prototype slopes without a generator change. Unknown fields in `CapitalCities` are already ignored, so adding them changes no behaviour.
- Physical slopes would change deterministic handling and require a Physics compatibility/version review before any multiplayer use. Bridges additionally change collision membership, checkpoint/route validation, drawing order and the replicated layer. Neither is implemented or accepted by this art integration; the proposed gain, clearance and step numbers are not approved constants.
- No route needs a bridge over the track yet; neither Darnassus nor Undercity crosses itself (Undercity version 2's bridges span its slime, painted as part of the street). Thunder Bluff's mesas are the natural first use.

## Evidence and limits

Offline only: `scripts/build_city_tracks.py --check` (byte-exact pictures, including the unchanged cities), the Lua suites on Lua 5.1 and 5.4 (heights present, one per point, absent for flat cities) and the review pictures sent to the owner. **NOT RUN in the client.** No physics, collision or presentation code changed.
