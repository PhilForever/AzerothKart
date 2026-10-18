# Temporary development addon folder

This directory is what WoW receives when installed. It currently contains one **local Test Drive** prototype, not a full racer. Copy this folder into the correct `Interface/AddOns` directory for WoW Forever.

The included `_Camelot.toc` is for the documented Forever flavor and the `.toc` serves fallback. Confirm actual runtime flavor/TOC selection in game. Never ship without manual client test, especially restricted keyboard/focus behavior.

`/akart` toggles window; Start Test Drive captures keyboard, Stop/Esc/Close releases. No multiplayer transport, laps, drifting or power-ups are implemented yet.
