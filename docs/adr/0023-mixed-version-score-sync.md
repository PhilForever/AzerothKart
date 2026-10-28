# ADR 0023 — bounded mixed-version community score protocol

**2026-10-28 Arathi update:** the implemented catalogue has thirteen active
boards and fourteen digest slots. Fixed-width HELLO is145 bytes including
prefix; all existing bounds and pacing stay unchanged. The previous
thirteen-slot HELLO cannot reconcile with the new shape; both peers update.
Historical data is retained. Exact-context direct NEW still follows the
existing pre-handshake rule.

- Status: Accepted for the installed candidate; native delivery still pending.
- Date: 2026-10-27
- Scope: owner-authorized Warsong registration and mixed-version score support.

## Context

The eleven existing maps retain Physics12; Warsong uses opt-in Physics13.
The previous single-physics catalogue rejects this combination. Appending an
unbounded decimal digest would exceed the existing158-byte native ceiling at
legal maximum values. Saved historical scores must not be reset or migrated.

## Decision

Use AZKSCR2/schema2 and twelve exact per-course contexts. Remove the global
physics equality requirement. The catalogue hash includes all six fields of
each context, including its physics version. HELLO has13 fixed8-character
uppercase hexadecimal digests (retired O must remain zero) plus the catalogue
hash:136bytes including prefix. Existing code meanings stay stable; W adds
Warsong. Hashes are change detectors, never proof of identity or integrity.

NEW/ROW preserve context fields and existing name/tick/date validation.
Wire versions are1..1295, lap count1..9, tickRate60. A maximal legal row with
96-byte name costs150 counted bytes. Every family caps payload151, leaving
7bytes for prefix; native158 ceiling,1scoreattempt/s and lease/idle guards
stay unchanged. REQUEST/END bind their code to a completed catalogue handshake;
direct NEW requires native sender identity and exact local context.

AZKSCR1/schema1 clients cannot share scores with this protocol. Both peers
must update; old cached records remain visible, including retired/historical
contexts. Unsupported current rows safely disable sharing initialization;
no saved-store mutation or schema change. No dual-prefix traffic/fallback.

## Evidence and limits

Focused Lua51 regressions cover maximum legal families, twelve-board two-peer
convergence, mixed12/13 contexts, mismatches, historical retention, automatic
native-adapter doubles and prompt PB notification. Combined client/gameplay
checks and exact executed commands are recorded in PROGRESS. These are offline
checks, not native roster, latency, rendering or community-scale acceptance.
