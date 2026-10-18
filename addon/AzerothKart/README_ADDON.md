# Temporary development addon folder

This directory is what WoW receives when installed. It currently contains one **local Test Drive** prototype, not a full racer. Copy this folder into the correct `Interface/AddOns` directory for WoW Forever.

The included `_Camelot.toc` is for the documented Forever flavor and the `.toc` serves fallback. Confirm actual runtime flavor/TOC selection in game. Never ship without manual client test, especially restricted keyboard/focus behavior.

`/akart` toggles the window; Start Test Drive deliberately captures keyboard out of combat. Stop/Esc/Close, another key, chat focus, click-away and lifecycle events stop the drive; capture never resumes automatically. These release paths still require actual client tests. `/akart probe` or Print Probe reports frame/tick/drop counters, capabilities and explicit UI allocation counts only on request. No multiplayer traffic, laps, drifting or power-ups are implemented yet.
