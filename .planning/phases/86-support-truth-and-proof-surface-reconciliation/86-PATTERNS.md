# Phase 86: Support Truth And Proof Surface Reconciliation - Pattern Map

**Mapped:** 2026-05-24
**Files analyzed:** support/proof docs, CI workflow, planning files, and focused task/test seams
**Analogs found:** 10 / 10 likely Phase 86 touchpoints

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `guides/support-and-compatibility.md` or equivalent restored guide | config | request-response | historical `guides/support-and-compatibility.md` contract described in Phase 68 artifacts | role-match |
| `README.md` | config | request-response | `README.md` | exact |
| `CONTRIBUTING.md` | config | request-response | `CONTRIBUTING.md` | exact |
| `examples/phoenix_meilisearch/README.md` | config | request-response | `examples/phoenix_meilisearch/README.md` | exact |
| `lib/mix/tasks/verify.adopter.ex` | utility | batch | `lib/mix/tasks/verify.adopter.ex` plus focused `verify.phase8x` tasks | exact |
| `test/mix/tasks/verify_adopter_test.exs` | test | batch | `test/mix/tasks/verify_adopter_test.exs` | exact |
| `test/scrypath/docs_contract_test.exs` | test | request-response | `test/scrypath/docs_contract_test.exs` | exact |
| `.github/workflows/ci.yml` | config | batch | `.github/workflows/ci.yml` | exact |
| `.planning/ROADMAP.md`, `.planning/STATE.md`, `.planning/MILESTONES.md` | docs | request-response | same files in prior truth-reconciliation phases 70, 80, and 85 | role-match |
| `.planning/milestones/v1.20-ROADMAP.md`, `.planning/milestones/v1.20-MILESTONE-AUDIT.md` | docs | request-response | historical archive files referenced but not rewritten as live branch-tip docs | exact |

## Pattern Assignments

### Restored support/readiness guide

**Closest analogs:** historical Phase 68 plan contract, `guides/sync-modes-and-visibility.md`, and current example README.

**Pattern to preserve:** one canonical guide owns one concern; shorter docs route into it instead of restating the whole contract.

**Planner guidance:** keep the guide narrow and contract-shaped:

- current Elixir/OTP posture
- defended Phoenix + Meilisearch path
- supported sync-mode posture
- proof command family
- repo-clone vs Hex boundary
- in-repo proof vs outside-adopter evidence

Do not absorb sync semantics already owned by `guides/sync-modes-and-visibility.md` or the detailed live runbook from the example README.

### `README.md`

**Analog:** `README.md`

**Pattern to preserve:** short adopter-facing wayfinding, high-signal support notes, and no accidental second support matrix.

**Planner guidance:** add or repair only the support/readiness hop and the maintainer-proof wording needed for Phase 86. Keep runtime and guide overview sections compact.

### `CONTRIBUTING.md`

**Analog:** `CONTRIBUTING.md`

**Pattern to preserve:** maintainer verify matrix, CI mapping, and contributor guidance that points truth questions to the canonical authority instead of re-specifying them.

**Planner guidance:** surface `mix verify.adopter` as the maintainer proof family and map fast/live to CI and the example README clearly.

### `examples/phoenix_meilisearch/README.md`

**Analog:** itself

**Pattern to preserve:** this file is the detailed live proof/runbook authority and already separates local smoke from CI truth.

**Planner guidance:** only tighten references back to the root command family or proof distinctions if needed. Do not move general support/readiness prose into this file.

### `lib/mix/tasks/verify.adopter.ex`

**Analog:** itself plus focused `verify.phase83.ex`, `verify.phase84.ex`, and `verify.phase85.ex`

**Pattern to preserve:** no-args default path, explicit opt-in live mode, strict arg validation, loud prerequisite failures, and a focused file/test list.

**Planner guidance:** repair the fast target list to use current files only. Keep live mode orchestration-only and do not hide Docker/service startup in the task.

### `test/mix/tasks/verify_adopter_test.exs`

**Analog:** itself

**Pattern to preserve:** direct `Mix.Task.run/2` assertions, `Mix.Error` checks, and minimal captured-output assertions.

**Planner guidance:** add one bounded regression around fast-mode target truth or help wording, but do not duplicate the broader docs-contract suite here.

### `test/scrypath/docs_contract_test.exs`

**Analog:** itself

**Pattern to preserve:** bounded `String.contains?/2` and ordering assertions over public claims, current guide routing, task help text, and workflow command strings.

**Planner guidance:** add narrow assertions for:

- canonical support authority discoverability
- `verify.adopter` fast/live wording parity
- example/CI/live-path parity
- active branch-tip truth around absent `SearchModule`

Avoid prose snapshots and giant planning inventories.

### `.github/workflows/ci.yml`

**Analog:** itself

**Pattern to preserve:** CI owns services/readiness; Mix tasks own semantic verification slices.

**Planner guidance:** if touched, keep `mix verify.adopter` on a service-free job and keep example-backed live proof on explicit service jobs rather than moving provisioning into Mix.

### Rolling planning files

**Closest analogs:** `.planning/STATE.md` drift notes and Phase 80's branch-tip-truth research posture.

**Pattern to preserve:** active planning tells the truth about current checkout reality while historical milestone archives remain historical evidence.

**Planner guidance:** update current-tense claims, not archived history itself, unless a minimal archive note is required to classify the mismatch. Use explicit wording like “the archive claims” versus “the current checkout exposes.”

### v1.20 archive files

**Analog:** themselves

**Pattern to preserve:** archives stay historical snapshots; if clarification is needed, it should be done with explicit framing rather than silently mutating every historical sentence as if the milestone never closed that way.

**Planner guidance:** prefer small classification notes in active planning over broad archive rewrites. Touch archive files only if a bounded clarification note materially reduces future confusion.

## Recommended Reuse Notes

- Reuse the repo's one-authority-per-concern docs pattern instead of inventing a new support/readiness system.
- Reuse the current `verify.adopter` live-mode branch rather than redesigning it.
- Reuse `docs_contract_test.exs` narrow string/order assertion style rather than building snapshots.
- Reuse the active-planning drift wording already present in `.planning/STATE.md` and `docs/jtbd-gap-map.md` as the branch-tip truth anchor for `SearchModule`.
- Reuse CI's explicit service ownership and job naming discipline when reconciling fast/live proof wording.

## PATTERN MAP COMPLETE
