---
phase: 168-dependency-security-and-reliable-verification
plan: "05"
subsystem: infra
tags: [hex, mix, dependency-audit, phoenix, github-actions, release]
delivery-record-commit: 81a5a7b

# Dependency graph
requires:
  - phase: 168-dependency-security-and-reliable-verification
    provides: four corrected Mix graphs, Phoenix graph proof, and strict recurring audit
provides:
  - Protected security PR merged with exact candidate, merge-ref, and main identities
  - Cold/reused audit costs for the four-graph inventory and all Phoenix package identities
  - Source-specific green candidate closeout and integrated-main evidence
affects: [phase-168, dependency-security, release-readiness]

# Actuals (#2632)
actuals:
  tokens: 2485
  tasks: 2
  commits: 1

# Tech tracking
tech-stack:
  added: []
  patterns: ["Keep delivery receipts in maintainer planning checkout, outside tested source tree"]

key-files:
  created:
    - .planning/phases/168-dependency-security-and-reliable-verification/168-DELIVERY.md
  modified: []

key-decisions:
  - "Use protected, head-matched squash delivery and retain candidate, PR merge-ref, and integrated-main identities separately."
  - "The measured incremental audit cost did not warrant another GitHub cache."
  - "Treat the locally built v0.3.13 package artifact as proof input only; make no Hex publication claim."

patterns-established:
  - "Delivery evidence names source SHA, graph hashes, selected job outputs, and package artifact identities."

requirements-completed: [MINT-01, MINT-02, MINT-03, DELIV-01]
coverage:
  - id: D1
    description: "The four maintained dependency graphs and Phoenix path/package modes were proved clean at the combined candidate."
    requirement: MINT-02
    verification:
      - kind: integration
        ref: "candidate c2072c1 local four-graph audit and both mix verify.phoenix_example modes; PR run 36502225556"
        status: pass
    human_judgment: false
  - id: D2
    description: "The recurring audit measured cold and reused costs, recorded complete graph/ignore state, and passed in CI."
    requirement: MINT-03
    verification:
      - kind: integration
        ref: "candidate c2072c1 cold/reused four-graph audit; closeout run 36502764736; main run 36503602888"
        status: pass
    human_judgment: false
  - id: D3
    description: "The security candidate passed protected checks, merged to public main, and its integrated source passed required and named proof jobs."
    requirement: MINT-01
    verification:
      - kind: other
        ref: "PR #84; PR run 36502225556; exact-candidate closeout run 36502764736; push-to-main run 36503602888"
        status: pass
    human_judgment: false
  - id: D4
    description: "The earlier readiness correction remains delivered, and this phase makes no Hex publication claim."
    requirement: DELIV-01
    verification:
      - kind: other
        ref: "168-01-DELIVERY.md PR #82/main SHA ad73b92; 168-DELIVERY.md published artifact identity is none"
        status: pass
    human_judgment: false

duration: "not measured across continued execution"
completed: 2026-09-29
status: complete
---

# Phase 168 Plan 05 Summary

**Four clean Mix graphs and both Phoenix resolution modes delivered on public main with source-specific protected checks and measured audit cost**

## Performance

- **Duration:** Not measured across continued execution.
- **Completed:** 2026-09-29.
- **Tasks:** 2 completed.
- **Source paths changed in this plan:** None; this plan records delivery evidence only.

## Accomplishments

- Refreshed the security branch from the delivered Plan 01 main SHA, reviewed and corrected the combined candidate, and ordinarily squash-merged PR #84 with an exact head match.
- Passed all five protected PR and main checks, exact-candidate closeout, deep-quality, Phoenix path/package, and path-selected Ops evidence.
- Recorded clean four-graph lock identities, empty Hex ignore state, complete cold/reused per-project costs, actual local and hosted package identities, and the explicit absence of a published candidate package.

## Task Commits

The source delivery is recorded in PR #84 and its integrated-main receipt; its source checkout was isolated from this planning branch. The phase receipt and summaries were committed locally as:

**Plan metadata:** `81a5a7b` (docs: record final delivery evidence).

## Verification

All named source-specific proofs passed. The joined source and delivery receipt is [168-DELIVERY.md](168-DELIVERY.md). Key source identities:

- Refreshed public-main base: `ad73b92d5883b4136fa961e134c987a95939fac2`.
- Tested candidate: `c2072c15e48993d09b9ea97204b248ab6c0e99e5`.
- PR merge ref: `a0b22c6fb35d7bdd7a9031b17b06800be991fec2`.
- Squash-integrated main: `2832e91d725d70eff9ba11d08052260ba17e2747`.
- PR: [#84](https://github.com/szTheory/scrypath/pull/84).
- PR CI: [36502225556](https://github.com/szTheory/scrypath/actions/runs/36502225556); exact candidate closeout: [36502764736](https://github.com/szTheory/scrypath/actions/runs/36502764736); main push: [36503602888](https://github.com/szTheory/scrypath/actions/runs/36503602888). Each completed successfully for its named checks.

## Decisions and limits

- Keep Hex 2.5.1's strict four-graph audit and do not add more caching: measured reused consumer fetch plus audit cost was 8.397 seconds in the local sample.
- The locally built `v0.3.13` artifact and its digest are test identities only. No package for candidate `c2072c1` was published to Hex; Phase 170 retains publication/readiness scope.
- PR #82's startup correction remains the preceding delivered dependency/base, documented in [168-01-DELIVERY.md](168-01-DELIVERY.md).

## Issues encountered

Two internal review findings and two hosted toolchain/workflow issues were corrected before final delivery evidence: exact-row binding and per-graph exception isolation; actionlint-compatible environment wiring; and active-toolchain Erlang discovery. The candidate and all subsequent source-specific checks were refreshed after those changes. The Ops task printed pre-existing nonfatal Dialyzer warnings while passing.

## Next phase readiness

All Phase 168 requirements are delivered with source-specific evidence. No delivery resume action remains. Continue to the approved Phase 169/170 roadmap work; this summary does not make a release publication or terminal readiness claim.

## Self-Check

- Pass: all four requirement IDs from Plan 05 are represented in this summary and linked to passing evidence.
- Pass: the plan receipt distinguishes candidate, PR merge ref, integrated main, and unpublished package identity.
- Pass: only phase-owned planning files were included in the documentation commit; unrelated workspace changes remain unstaged.

---
*Phase: 168 — Dependency Security and Reliable Verification*
*Plan: 05 — protected security delivery*
