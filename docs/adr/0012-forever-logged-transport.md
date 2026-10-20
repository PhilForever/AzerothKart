# ADR 0012 — Reuse Forever's verified logged transport and full names

Status: Accepted technical correction, 2026-10-21. No production replication architecture selected.

## Evidence

The owner reported `invalid numeric net argument` for `listen First Surname AKT721`. The original whitespace parser assigned the surname to session and the session to rate. Independent pure validation also wrongly required a realm suffix. Forever uses full first names and surnames; the owner confirms there are no realms.

The existing sibling `IOU-GitHub` repository already documents two IOU 0.3.2 clients on Forever 1.60.1/build 70425 completing four exact round trips on 16 October 2026: ASCII, Norwegian UTF-8 and 239/240-byte messages (`docs/connection-test.md`). Its `transport.lua` uses `C_ChatInfo.SendAddonMessageLogged` with `WHISPER` and receives `CHAT_MSG_ADDON_LOGGED`. This establishes basic compatibility of that route, not sustained racing capacity. No IOU source or player data is copied or modified by this correction.

## Decision

- Use that explicit logged API/event pair for the Azeroth Kart experiment. Native channel remains `WHISPER`; reports and the CSV `channel` field identify the route as `WHISPER_LOGGED`. Never fall back to unlogged addon messages or ordinary whispers.
- Accept a complete typed character name, preferably quoted. Also support unquoted first-name/surname commands. Locate the six-uppercase-alphanumeric session without treating six-digit codes as settings. Reject ambiguous unquoted commands with an instruction to quote the name.
- Canonicalize a name only by trimming/collapsing ASCII spaces, rejecting control/DEL/pipe characters and limiting the raw value to 96 bytes. Preserve punctuation, hyphens and UTF-8. Compare the entire native event sender with ASCII case folding only. No realm inference, surname removal, suffix guessing or Unicode case folding.
- Preserve existing pacing, DATA/ACK bounds, result classification, lifecycle cleanup and explicit opt-in. Respect actual `InChatMessagingLockdown` when available and fail closed on unreadable/locked state. IOU's historical broad outgoing-restriction diagnostic does not replace native send results or actual chat lockdown.
- Future identity discovery should reuse IOU's proven `NameUtil.GetUnmodifiedUnitFullName`, or `UnitNameUnmodified` plus the actual surname-separator constant. This task adds no discovery API and makes no assumption about a second `UnitFullName` return value.

## Limits

Build 70450's local API source declares the logged send/event and nullable send result. Availability readbacks are not delivery. A nil/unknown result still aborts rather than being counted as success. Actual Azeroth Kart prefix/send results, sustained delivery, RTT, ordering/loss reconciliation and reconnect remain unmeasured until recorded in PROGRESS. The first window remains 0.5 DATA/s, 16 bytes, 120 seconds; IOU's four-message diagnostic need not be repeated. No new milestones are marked complete and no multiplayer capacity is advertised.
