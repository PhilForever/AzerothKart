# Mirage opaque background — owner screenshot

Received 2026-10-20 in the project conversation. This note records the supplied image's narrow evidence without copying a personal gameplay screenshot into the repository.

The image shows the Azeroth Kart window with **Track: Mirage Raceway**, its original opaque salt-flat TGA, a north-up elongated circuit, the long straight at the right and the small starting kart on that straight's lower portion. The map occupies a centered square with dark side margins in the landscape canvas. HUD counters show a stopped, zero-tick view. The owner reports that this distant presentation loses intensity and asks for continued work.

This establishes that the earlier whole-map background displayed with the expected broad route orientation. It does not establish a fresh client version, transparent-sprite alpha, cropped camera UVs, movement/control behavior, frame timing or object-count stability. No API readback or unattended driving was performed for this evidence.

The response is a closer scale-1.5 north-up follow camera, with 60 world units of heading look-ahead, bounded background cropping and matching gate/wall projection. At this screenshot's evidence point, the closer client view and motion were **NOT RUN**. A [separate later stopped-client check](2026-10-20-mirage-camera-static.md) now establishes the close UV crop and Start/West strip alignment/clipping; camera motion/edges remain **NOT RUN**. Physics v6, world geometry and the Test Oval overview are unchanged. Follow the short [camera probe](../FEASIBILITY.md#mirage-blockout-first-load-probe) for actual-client verification; acceptance remains open.
