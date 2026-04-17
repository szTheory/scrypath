# Phase 25: Settings hot apply (narrow) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `25-CONTEXT.md` — this log preserves the alternatives considered.

**Date:** 2026-04-17
**Phase:** 25 — Settings hot apply (narrow)
**Areas discussed:** Live-index safety gate, Error taxonomy, API vs Mix task, Post-PATCH verification

---

## Live-index safety gate

| Option | Description | Selected |
|--------|-------------|----------|
| Explicit `acknowledge_live_index: true` | Double signal: allow-listed payload + intent to patch live index; grep-able; matches “second-class relief path” framing | ✓ |
| Implicit (map alone) | Fewer tokens; higher risk of accidental live PATCH from shared settings helpers | |

**User's choice:** Research-synthesized recommendation accepted (“all” gray areas — one-shot cohesive design).
**Notes:** Aligns with Phase 19 stub doc hint and Elixir pattern of explicit opts when widening beyond the primary safe workflow (`reindex/2`).

---

## Error taxonomy

| Option | Description | Selected |
|--------|-------------|----------|
| Tagged tuples + collect all bad keys | `{:unsupported_hot_apply_keys, keys}` before HTTP; `{:hot_apply_failed, details}` for remote; matches `verify_applied` drift style | ✓ |
| Fail-fast first key | Simpler parser-style; worse DX for multi-key mistakes | |
| Bare atoms only | Hard for operators and Mix to show actionable detail | |
| `%Scrypath.Error{}` struct | Cross-cutting; deferred unless necessary | |

**User's choice:** Tagged tuples, validate-before-HTTP, collect all invalid keys.
**Notes:** Operational honesty — one honest snapshot per call.

---

## Operator entry points

| Option | Description | Selected |
|--------|-------------|----------|
| API-first + thin Mix task | `Settings.hot_apply/3` is source of truth; `mix scrypath.settings.hot_apply` delegates; `release eval` documented | ✓ |
| API-only | Consistent for releases; breaks symmetry with `settings.read` / `settings.diff` | |
| Mix-only | Bad for release nodes without Mix | |

**User's choice:** API-first + thin Mix task with explicit CLI ack flag (`--ack-live` or equivalent).
**Notes:** Searchkick-style “strong API + selective CLI” pattern.

---

## Post-PATCH verification

| Option | Description | Selected |
|--------|-------------|----------|
| Default: task success, no auto full verify | Avoids false drift when full `verify_applied` compares entire declared schema to partial live state | ✓ |
| Auto full `verify_applied` after hot apply | Stronger proof signal but wrong default for subset PATCH; confuses operators | |
| Optional subset verify | Same phase if small else follow-on; scoped GET/compare only on allow-listed keys | (optional / discretion) |

**User's choice:** Default trust PATCH + settings task completion; document `settings.diff` / managed reindex for proof; optional subset verify deferred to planner schedule.

---

## Claude's Discretion

- Exact error atoms, success return shape, telemetry event name/metadata, whether subset verify ships in Phase 25 or follow-on — see `25-CONTEXT.md` § Claude's Discretion.

## Deferred Ideas

- Library-wide `%Scrypath.Error{}` — out of scope for Phase 25 unless unavoidable.
- Subset verify as explicit follow-on if not shipped with Phase 25.

---

*Phase: 25-settings-hot-apply-narrow*
*Discussion logged: 2026-04-17*
