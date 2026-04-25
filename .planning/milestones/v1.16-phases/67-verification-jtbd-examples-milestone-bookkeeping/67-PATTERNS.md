# Phase 67: verification-jtbd-examples-milestone-bookkeeping - Pattern Map

**Mapped:** 2026-04-22
**Files analyzed:** 9
**Analogs found:** 9 / 9

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-01-PLAN.md` | plan | request-response | `.planning/phases/66-runner-library-contract/66-01-PLAN.md` | role-match |
| `.planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-02-PLAN.md` | plan | transform | `.planning/phases/66-runner-library-contract/66-02-PLAN.md` | role-match |
| `.planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-03-PLAN.md` | plan | batch | inferred from Phase 64 close plan via `.planning/milestones/v1.15-ROADMAP.md` and `.planning/milestones/v1.15-REQUIREMENTS.md` | partial |
| `.planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-01-SUMMARY.md` | summary | request-response | `.planning/phases/66-runner-library-contract/66-02-SUMMARY.md` | role-match |
| `scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs` | test | request-response | `.planning/phases/65-playbook-run-lifecycle-opsui/65-04-PLAN.md` | exact-domain |
| `scrypath_ops/test/scrypath_ops/playbook/doc_resolver_test.exs` or equivalent | test | transform | `.planning/phases/66-runner-library-contract/66-01-PLAN.md` | role-match |
| `scrypath_ops/examples/playbooks/*.json` plus related docs references | fixture/docs | file-I/O | `.planning/milestones/v1.15-ROADMAP.md` | partial |
| `.planning/milestones/v1.16-ROADMAP.md`, `.planning/milestones/v1.16-REQUIREMENTS.md`, `.planning/milestones/v1.16-MILESTONE-AUDIT.md` | archive | batch | `.planning/milestones/v1.15-ROADMAP.md`, `.planning/milestones/v1.15-REQUIREMENTS.md`, `.planning/milestones/v1.15-MILESTONE-AUDIT.md` | exact |
| rolling `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/PROJECT.md`, `.planning/STATE.md` updates | bookkeeping | batch | Phase 64 evidence described in `.planning/milestones/v1.15-ROADMAP.md` and `.planning/milestones/v1.15-REQUIREMENTS.md` | partial |

## Pattern Assignments

### `.planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-01-PLAN.md` (plan, request-response)

**Primary analog:** `.planning/phases/66-runner-library-contract/66-01-PLAN.md`

**Frontmatter pattern** (`.planning/phases/66-runner-library-contract/66-01-PLAN.md:1-32`):
```md
---
phase: 66
plan: "01"
type: execute
wave: 1
depends_on: []
files_modified:
  - ...
autonomous: true
requirements:
  - OPS3-03
must_haves:
  truths:
    - "..."
  artifacts:
    - path: "..."
      provides: "..."
  key_links:
    - from: "..."
      to: "..."
      via: "..."
      pattern: "..."
---
```

**Objective/context/source-audit pattern** (`.planning/phases/66-runner-library-contract/66-01-PLAN.md:34-92`):
```md
# Plan 01 — Canonical contract and boundary freeze

<objective>
...
Purpose: ...
Output: ...
</objective>

<execution_context>
@.../execute-plan.md
@.../summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
...
</context>

<source_audit>
- GOAL: ...
- REQ: ...
- RESEARCH: ...
- CONTEXT: ...
</source_audit>
```

**Task block pattern** (`.planning/phases/66-runner-library-contract/66-01-PLAN.md:94-148`):
```md
<task id="66-01-01" type="auto">
<name>Task 1: ...</name>
<files>...</files>
<read_first>
- ...
</read_first>
<action>
...
</action>
<acceptance_criteria>
- `grep ...`
- `mix test ...`
</acceptance_criteria>
<verify>
  <automated>mix test ...</automated>
</verify>
<done>...</done>
</task>
```

**Planner guidance:** use this for the bounded verification surface plan. Keep it focused on `scrypath_ops/test/` plus narrow contributor/docs contract assertions. Follow Phase 66’s pattern of explicit `must_haves.truths`, concrete `artifacts`, and grep-able acceptance criteria.

**Recommended Phase 67 mapping:** `67-01` should own the operator-surface verification slice from `67-CONTEXT.md` D-01 through D-07: LiveView execution selectors/phrases, `RunFailure`/`DocResolver` contract checks, fixture-contract tests, and the root `docs_contract_test.exs` additions that freeze commands and shipped filenames.

---

### `.planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-02-PLAN.md` (plan, transform)

**Primary analog:** `.planning/phases/66-runner-library-contract/66-02-PLAN.md`

**Dependent-wave pattern** (`.planning/phases/66-runner-library-contract/66-02-PLAN.md:1-33`):
```md
---
phase: 66
plan: "02"
type: execute
wave: 2
depends_on:
  - "01"
files_modified:
  - ...
autonomous: true
requirements:
  - OPS3-03
must_haves:
  truths:
    - "..."
---
```

**Explicit, bounded matrix pattern** (`.planning/phases/66-runner-library-contract/66-02-PLAN.md:121-131`):
```md
Cover exactly this matrix unless an equivalent fixture is clearer:
1. ...
2. ...
3. ...

Assert structural parity only ...
Do not assert UI copy, docs links, or a generalized meta-harness.
```

**Verification stanza pattern** (`.planning/phases/66-runner-library-contract/66-02-PLAN.md:186-200`):
```md
<verification>
Run:
- `mix test ...`
- `mix test ...`
- `mix verify.opsui`
</verification>

<output>
After completion, create `.planning/phases/66-runner-library-contract/66-02-SUMMARY.md`
</output>
```

**Planner guidance:** use this for the JTBD examples plus examples-adjacent docs/tests plan. The repo prefers a bounded matrix over an open-ended fixture catalog; for Phase 67 that means exactly two canonical `examples/playbooks/` fixtures, targeted validation coverage, and direct doc references to those filenames.

**Recommended Phase 67 mapping:** `67-02` should own the examples/docs slice from D-08 through D-15: create or replace the two canonical JTBD fixtures, update operator/contributor docs to name them directly, keep `playbook-schema-v1.md` as wire-format authority, and add fixture-contract assertions around filenames and docs references.

---

### `.planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-03-PLAN.md` (plan, batch)

**Primary analogs:** inferred Phase 64 close plan from `.planning/milestones/v1.15-ROADMAP.md` and `.planning/milestones/v1.15-REQUIREMENTS.md`

**Evidence that milestone close is split into its own plan** (`.planning/milestones/v1.15-REQUIREMENTS.md:30-38`):
```md
- [x] **OPS2-05** ... **Evidence:** Phase **64** plan **64-01** ...
- [x] **OPS2-06** ... **Evidence:** Phase **64** plan **64-02** ...
- [x] **OPS2-08** ... **Evidence:** Phase **64** plan **64-03** — **`64-03-milestone-v1-15-close-SUMMARY.md`**, this archive trio.
```

**Archive outcome pattern** (`.planning/milestones/v1.15-ROADMAP.md:22-25`):
```md
### Phase 64: IA, verification, and milestone bookkeeping

- [x] **Phase 64: IA, verification, and milestone bookkeeping** ... **`mix verify.opsui`** green; ... frozen **`v1.15-*`** trio + rolling traceability.
```

**Manual-close wording pattern** (`.planning/milestones/v1.15-ROADMAP.md:43-45`, `.planning/milestones/v1.15-MILESTONE-AUDIT.md:43-44`):
```md
- **`gsd-sdk query milestone.complete`** still fails ...
- **Hex:** No version change in **`mix.exs`** ... publish story remains **in-repo milestone; Hex publish tracked separately**.
```

**Planner guidance:** keep milestone freeze/archive/bookkeeping in a dedicated final plan, not mixed into verification implementation tasks. This repo’s close pattern separates:
- plan `01` / `02`: verification or product-facing work
- plan `03`: archive trio + rolling truth + honest status language

**Recommended Phase 67 mapping:** `67-03` should own D-16 through D-21 only: update rolling traceability, prepare `v1.16-*` frozen files, and touch `.planning/MILESTONES.md` only if Phase 67 truly closes v1.16. Keep `mix.exs` and `CHANGELOG.md` explicitly out of scope unless a real release happens in the same change.

---

### `.planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-0X-SUMMARY.md` (summary, request-response)

**Primary analog:** `.planning/phases/66-runner-library-contract/66-02-SUMMARY.md`

**Summary frontmatter pattern** (`.planning/phases/66-runner-library-contract/66-02-SUMMARY.md:1-24`):
```md
---
phase: 66-runner-library-contract
plan: "02"
subsystem: testing
tags: [...]
requires:
  - phase: 66-01
    provides: ...
provides:
  - ...
affects: [...]
tech-stack:
  added: []
  patterns: [...]
key-files:
  created: [...]
  modified:
    - ...
key-decisions:
  - "..."
patterns-established:
  - "..."
requirements-completed: [OPS3-03]
duration: 16 min
completed: 2026-04-22
---
```

**Execution report structure** (`.planning/phases/66-runner-library-contract/66-02-SUMMARY.md:26-118`):
```md
# Phase 66 Plan 02: ... Summary

## Accomplishments
...

## Task Commits
...

## Files Created/Modified
...

## Decisions Made
...

## Deviations from Plan
...

## Verification
...
```

**Planner guidance:** keep one summary per plan. For Phase 67, expect the final bookkeeping summary to explain whether `v1.16` actually closed or was only prepared; the repo’s summaries preserve that distinction rather than hiding it.

---

### `scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs` (test, request-response)

**Primary analog:** `.planning/phases/65-playbook-run-lifecycle-opsui/65-04-PLAN.md`

**Execution-surface test pattern** (`.planning/phases/65-playbook-run-lifecycle-opsui/65-04-PLAN.md:18-48`):
```md
<objective>
Extend `PlaybookLiveTest` to cover async run completion with `render_async`, ...
</objective>

<task id="65-04-01" type="execute">
<read_first>
- scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs
...
</read_first>
<action>
Update existing ... to call `render_click` then **`render_async(view)`** ...
...
Attach telemetry handler in test ...
</action>
```

**Planner guidance:** Phase 67 verification should continue this style: behavioral LiveView tests with stable selectors/phrases only. Freeze the contract items listed in `67-CONTEXT.md` D-04, not full page copy.

---

### Root docs-contract updates (`test/scrypath/docs_contract_test.exs`, contributor docs) (test/docs, transform)

**Primary analogs:** `.planning/phases/66-runner-library-contract/66-01-PLAN.md`, Phase 64 evidence in `.planning/milestones/v1.15-ROADMAP.md`

**Plan pattern for narrow root-doc checks** (`.planning/phases/66-runner-library-contract/66-01-PLAN.md:127-146`):
```md
<task ...>
<files>scrypath_ops/docs/playbook-schema-v1.md</files>
...
<acceptance_criteria>
- `grep -n ...`
- `mix test test/scrypath/docs_contract_test.exs`
</acceptance_criteria>
```

**Evidence that verification docs and contracts were grouped together in Phase 64** (`.planning/milestones/v1.15-ROADMAP.md:22-24`):
```md
- [x] **Phase 64: IA, verification, and milestone bookkeeping** ... **CONTRIBUTING** / **`guides/operator-mix-tasks.md`** / **`docs_contract_test`** for **`mix scrypath_ops.playbooks.validate`**; **`mix verify.opsui`** green; ...
```

**Planner guidance:** root `docs_contract_test.exs`, `README.md`, and `CONTRIBUTING.md` belong with verification work, not with the milestone close plan. Phase 64 grouped command-truth docs and docs-contract assertions together under the verification slice.

---

### Milestone archive trio (`.planning/milestones/v1.16-*`) (archive, batch)

**Primary analogs:**
- `.planning/milestones/v1.15-ROADMAP.md`
- `.planning/milestones/v1.15-REQUIREMENTS.md`
- `.planning/milestones/v1.15-MILESTONE-AUDIT.md`

**Roadmap archive header pattern** (`.planning/milestones/v1.15-ROADMAP.md:1-8`):
```md
# Milestone archive: v1.15 — OPSUI second slice

**Archived:** 2026-04-22
**Shipped (in-repo):** 2026-04-22
**Hex:** **`scrypath 0.3.4`** ... **in-repo milestone; Hex publish tracked separately**
**Phases:** 62–64 ...
**Audit:** [`milestones/v1.15-MILESTONE-AUDIT.md`](v1.15-MILESTONE-AUDIT.md) ...
**Canonical snapshot:** Captured from `.planning/ROADMAP.md` at milestone close.
```

**Requirements archive pattern** (`.planning/milestones/v1.15-REQUIREMENTS.md:1-5`, `.planning/milestones/v1.15-REQUIREMENTS.md:50-67`):
```md
# Requirements archive: Scrypath v1.15 — OPSUI second slice

**Archived:** 2026-04-22
**Milestone:** v1.15 ...
**Outcomes:** ... Residual audit: **`milestones/v1.15-MILESTONE-AUDIT.md`**.

## Traceability (frozen)
| Requirement | Phase | Status |
|-------------|-------|--------|
...
```

**Audit frontmatter and verdict pattern** (`.planning/milestones/v1.15-MILESTONE-AUDIT.md:1-29`, `.planning/milestones/v1.15-MILESTONE-AUDIT.md:32-44`):
```md
---
milestone: v1.15
milestone_name: OPSUI second slice
audited: 2026-04-22T18:00:00Z
status: passed
scores:
  requirements: 8/8
...
gaps:
  integration:
    - from: gsd-sdk automation
      to: milestone.complete CLI
      issue: >-
        ...
---

# Milestone audit: v1.15 — OPSUI second slice

**Verdict:** **`passed`** ...
```

**Planner guidance:** copy the trio almost verbatim for structure. Adjust only milestone number, phase range, requirement IDs, and status honesty. If the audit is not actually complete, do not write `status: passed`.

## Shared Patterns

### Plan frontmatter is dense and evidence-oriented

**Sources:**
- `.planning/phases/66-runner-library-contract/66-01-PLAN.md:1-32`
- `.planning/phases/66-runner-library-contract/66-02-PLAN.md:1-33`

Use `must_haves.truths`, `artifacts`, and `key_links` in plan frontmatter. Nearby plans are not lightweight prose briefs; they define concrete evidence the summary and verification later refer back to.

### Verification plans own docs-contract work

**Sources:**
- `.planning/milestones/v1.15-ROADMAP.md:22-24`
- `.planning/phases/66-runner-library-contract/66-01-PLAN.md:139-146`

When contributor docs, command truth, and root `docs_contract_test.exs` move together, they live in the verification plan, not the milestone-close plan.

### Example fixtures and example docs are grouped together

**Sources:**
- `.planning/milestones/v1.15-ROADMAP.md:20-24`
- `.planning/milestones/v1.15-REQUIREMENTS.md:24-38`
- `.planning/phases/67-verification-jtbd-examples-milestone-bookkeeping/67-CONTEXT.md`

The repo groups `examples/playbooks/`, validation command coverage, and docs references as one operator-story slice. For Phase 67, keep the two JTBD fixtures and the docs that name them in the same plan.

### Milestone close is a separate final plan

**Sources:**
- `.planning/milestones/v1.15-REQUIREMENTS.md:30-38`
- `.planning/milestones/v1.15-MILESTONE-AUDIT.md:38-44`

Phase 64 was split into at least three plans by evidence: `64-01` IA, `64-02` verification/doc contracts, `64-03` milestone close. Repeat that pattern for Phase 67: verification/examples first, freeze/archive last.

### Milestone language stays honest about Hex vs in-repo close

**Sources:**
- `.planning/milestones/v1.15-ROADMAP.md:3-8`
- `.planning/milestones/v1.15-MILESTONE-AUDIT.md:41-44`

Archive files explicitly separate:
- in-repo milestone shipped/archived
- Hex package release truth
- manual milestone close automation gaps

Phase 67 should preserve that wording discipline exactly.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `.planning/phases/61-verification-and-milestone-bookkeeping/*` | plan | unknown | Requested analog files are not present anywhere under `.planning/` in this workspace. |
| `.planning/phases/64-ia-verification-and-milestone-bookkeeping/*` | plan | unknown | Direct phase files are absent locally; only their effects survive via `v1.15-*` milestone archives and requirement evidence lines. |

## Concrete Recommendations

1. Plan Phase 67 as three execute plans: `67-01` bounded verification contracts, `67-02` JTBD examples plus examples-adjacent docs/tests, `67-03` milestone freeze and rolling bookkeeping.
2. Put `README.md`/`CONTRIBUTING.md`/`docs_contract_test.exs` in the verification plan, not the milestone-close plan. That matches the surviving Phase 64 evidence.
3. Keep the `v1.16-*` trio and rolling `.planning/*` truth updates together in the final plan, and gate any `.planning/MILESTONES.md` edit on whether v1.16 is actually closed.
4. Reuse the Phase 66 frontmatter shape with `must_haves.truths`, `artifacts`, and `key_links`; nearby plans are explicit about evidence, not just tasks.

## Metadata

**Analog search scope:** `.planning/phases/65-*`, `.planning/phases/66-*`, `.planning/milestones/v1.15-*`, `.planning/phases/67-*/67-CONTEXT.md`
**Files scanned:** 12
**Pattern extraction date:** 2026-04-22
