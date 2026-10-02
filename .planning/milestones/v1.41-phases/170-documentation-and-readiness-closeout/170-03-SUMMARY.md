---
phase: 170-documentation-and-readiness-closeout
plan: "03"
subsystem: readiness
tags: [evidence-ledger, readiness, github-issue, closeout]

requires:
  - phase: 170-documentation-and-readiness-closeout
    provides: Exact-source readiness validator and Plan 02 delivery tooling
provides:
  - Finite factual input ledger for the seven-dimension, 24-claim Phase 162 baseline
  - Dedicated append-only public terminal decision location linked from the live authority
  - Current progress/navigation updates that preserve historical assessments
affects: [phase-170-delivery, readiness-closeout, terminal-decision]

tech-stack:
  added: []
  patterns:
    - Keep factual input validation separate from semantic six-condition judgments
    - Preserve historical assessment bytes and use a public issue only as the decision location

key-files:
  created:
    - .planning/phases/170-documentation-and-readiness-closeout/170-READINESS-INPUTS.json
    - .planning/phases/170-documentation-and-readiness-closeout/170-03-SUMMARY.md
  modified:
    - .planning/reference/PRE-OPERATOR-UI-READINESS.md

key-decisions:
  - "Issue #86 is the durable location for future dated maintainer decisions; its body makes no readiness judgment and authorizes no UI work."
  - "Phase 167 remains the latest NOT READY judgment until a later dated terminal comment exists."
  - "The finite ledger records evidence and invalidators without assigning new condition statuses."
  - "Allow explicitly pending delivery inputs at the inputs-validation stage; require an actual disposition only for terminal records."

commits:
  - "0a91f29 — docs(170-03): record bounded readiness inputs"
  - "e6e8a85 — docs(170-03): establish readiness issue authority"
  - "cecf6a0 — fix(170-03): keep pending delivery inputs valid (delivery branch validator alignment)"
duration: unmeasured
completed: 2026-09-30
status: complete
---

# Phase 170 Plan 03: Bounded Readiness Inputs and Decision Location

**The readiness input ledger now bounds the current evidence, and issue #86 provides a discoverable location for future dated maintainer decisions without changing the latest NOT READY assessment.**

## Accomplishments

- Recorded all seven baseline dimensions and 24 claims, the finite important-workflow list, named source invalidators, source comparisons, evidence limits, ownership inventory, and supplied unresolved probes. The ledger pins historical files and the Phase 164 suffix and preserves Phase 167's NOT READY result without assigning new six-condition judgments.
- Refreshed the current security, delivery, CI, release, and source evidence, including Phase 168 four-graph advisory status and Phase 169 tenant/facet and bounded repair receipts. Current facts remain scoped to their recorded sources and workflows.
- Searched existing issues and inspected the unrelated candidate #37. After the user's explicit `authorize` response to the exact repository, title, and body, created [issue #86](https://github.com/szTheory/scrypath/issues/86) under `szTheory` and read back the exact title, URL, author, and body. The published body SHA-256 is `d3d77cdb4a0f171af9ceef8c653315e04c920dbbe97abc38eed2c5d6d157f141`.
- Linked issue #86 from the live readiness authority above the unchanged historical suffix. The pointer says later dated comments are authoritative, corrections append and identify superseded decisions, and the issue itself does not decide readiness or authorize UI work.
- Updated current progress language and left delivery explicitly pending for Plans 04–06.

## Task Commits

1. **Task 1: Assemble bounded evidence inputs and issue proposal** — `0a91f29`.
2. **Task 2: Authorize the concrete issue action** — user replied `authorize` after review of the exact title/body; public issue created as #86 by `szTheory`.
3. **Task 3: Establish the issue pointer and progress navigation** — `e6e8a85`.

Plan 03 exposed a mismatch in the Plan 02 validator: it rejected `delivery.disposition: pending` at the `inputs` stage, although Plan 03 requires delivery to remain pending through Plans 04–05. The validator now allows pending delivery for draft and inputs stages while terminal validation still requires an actual disposition. The focused regression and documentation are committed on the owned delivery branch as `cecf6a0`.

## Verification

- `node scripts/ci_monitor.cjs validate-readiness --stage inputs ...` — **FACTUAL_ONLY_VALID**, `semantic_decision: null`; historical pins and required input structure passed.
- `gh issue view 86 --repo szTheory/scrypath --json number,url,title,body,author` — readback matched the authorized repository, title, body, URL, and author.
- `mix test test/scripts/ci_monitor_test.exs` on the delivery branch with isolated external Mix/Hex caches — **15 tests, 0 failures**. The local cache paths are omitted.
- `node --check scripts/ci_monitor.cjs` and `git diff --check` — passed.

## Boundaries and Remaining Work

- The seven-dimension ledger and successful structural validation do not decide any of the six readiness conditions. Phase 167 remains the latest judgment until a separate dated maintainer comment exists.
- The issue is a public decision location only. This authorization does not cover a Phase 170 PR, merge, release, or operator UI work.
- Plan 04 still must review and prove the joined candidate. Its blocking checkpoint requires separate scoped authorization before any Phase 170 PR is opened or merged.

## Deviations

- Aligned the owned validator with Plan 03's required pending-delivery input state and added a regression test. This is within Plan 04's listed code/tool paths and does not change how terminal records are validated.
- The issue action was completed under the explicit user authorization received at the Plan 03 decision checkpoint.

---
*Phase: 170-documentation-and-readiness-closeout*
*Completed: 2026-09-30*
