# Phase 28: Operator CLI, docs, and verify gate - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in **028-CONTEXT.md** — this log preserves the alternatives considered.

**Date:** 2026-04-17
**Phase:** 28 — Operator CLI, docs, and verify gate
**Areas discussed:** Mix task naming and surface; Exit codes and JSON; Default human output; Verify gate naming; Doc split (OPS15-03)

---

## Mix task naming and surface

| Option | Description | Selected |
|--------|-------------|----------|
| A — API-literal flat | `mix scrypath.index_contract_drift` | |
| B — Dotted group (recommended) | `mix scrypath.index.contract_drift` → `Mix.Tasks.Scrypath.Index.ContractDrift` | ✓ |
| C — Short ambiguous | `mix scrypath.contract_drift` | |
| D — Extend reconcile | Flags on `mix scrypath.reconcile` | |

**User's choice:** Research-synthesized **B** — dedicated task, grouped naming aligned with **`scrypath.settings.*`**, delegate to **`index_contract_drift/2`**; document API name in moduledoc.
**Notes:** Avoids reconcile overload and generic “drift” collisions with settings vs operational drift.

---

## Exit codes and `--json`

| Option | Description | Selected |
|--------|-------------|----------|
| Mirror settings.diff | `0` / `2` / `1` for parity / drift / error; same with `--json` | ✓ |
| git-style two-bucket | Drift and error both non-zero without stable split | |
| Per-dimension exit codes | Fine-grained but diverges from rest of operator CLI | |

**User's choice:** Mirror **`scrypath.settings.diff`** for all modes; multi-dimensional drift aggregates to **`2`** if any slice mismatches.
**Notes:** CI separates “wrong contract” from “broken run”; document shell **`set +e`** pattern.

---

## Default human output

| Option | Description | Selected |
|--------|-------------|----------|
| Sparse + explicit OK | Header → mismatches only → footer; parity prints OK line | ✓ |
| Verbose tables | Full declared vs live in terminal by default | |
| Pager by default | `less`-style for large output | |

**User's choice:** Sparse triage, mandatory parity line, footer points to **`--json`**; no pager; TTY-gated ANSI; **`NO_COLOR`** respected.
**Notes:** Matches Phase 27 human/JSON density split.

---

## Verify gate naming

| Option | Description | Selected |
|--------|-------------|----------|
| `mix verify.phase28` | Gate name matches roadmap phase 28 | ✓ |
| `mix verify.phase27` | REQ literal tied to drift-report slice | |
| Dual tasks | phase27 + phase28 | |

**User's choice:** **`verify.phase28`** only; update **OPS15-04** / roadmap / operator docs for coherence.
**Notes:** OPS15-04 explicitly allows renumbering; avoids “phase 28 ships phase27 gate” confusion.

---

## Operator docs split (OPS15-03)

| Option | Description | Selected |
|--------|-------------|----------|
| Runbook vs support matrix | `drift-recovery.md` symptom paths; `operator-support.md` first-response ordering; cross-link | ✓ |
| Duplicate full matrices in both | | |

**User's choice:** Split concerns with cross-links; update **`operator-support`** verify bullet for **`verify.phase28`**.

---

## Claude's Discretion

Exact human rendering style for mismatch blocks; optional future **`--verbose`**; exact test list inside **`verify.phase28`** beyond minimum bar.

## Deferred Ideas

- Optional optimization: shared Meilisearch snapshot for **`settings.diff`** drift path — backlog unless trivial.
