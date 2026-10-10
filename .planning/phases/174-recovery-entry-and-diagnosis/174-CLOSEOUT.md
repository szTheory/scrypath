# Phase 174 closeout

Phase 174 delivers OPUX-16–OPUX-19 through eight plans. Independent verification passes 48/48 plan truths and four roadmap outcomes, with all 24 adopted decisions, 30 UI criteria, 25 artifacts, 22 links and four flagged source assumptions verified. Maintainer review of the working UI is optional feedback.

Native recovery browser evidence passes 11/11 at production/fixture e286962 with 48 AFTER frames. Ops precommit passes 275 tests + 2 doctests; core regression passes 661 tests + 4 properties (85 excluded). Prior Phase173 regression covers 34 unique cases with passing evidence across a truthful 32/34 full native run and the exact two failing cases passing a focused 2/2 rerun after updating obsolete queue-observed wording to all three actual zero metrics. The real mounted recovery verifies its exact replacement queue job, backend task and expected document. Reports remain unedited; no single green 34-case report is invented.

Code review CR-01 and WR-01 are fixed: source-qualified retry identity survives the status handoff and handle supersession, and shell/Control Room targets revalidate the current allowlist. The test-only shell allowlist lookup is pure so it cannot consume an observation. Native disposition records both findings fixed, zero open. ASVS L1 register: 14 closed threats. UI audit: 23/24; full-name word wrapping and AAA contrast findings remain nonblocking recommendations.

Native phase.complete accepted fresh verification and marked 8/8 plans and all four requirements complete, with Phase175 ready to plan; Phase175 has not started. Persistent auto_advance remains false and the per-run chain flag is cleared. Global learning extraction is disabled; graduation has insufficient current-milestone prior phases/items; no promotion or human trust approval is simulated. There are no Phase174 todos or stale handoffs to close.

Native tracking returned two warning messages concerning four supposed missing file references: one `cd scrypath_ops && mix test ...` command, two `mix test ...`/`node --test ...` commands and `assets/css/DESIGN-TOKENS.md` relative to the Ops directory. The commands were actually executed, the referenced test files exist, and the catalog is `scrypath_ops/assets/css/DESIGN-TOKENS.md`. These are heuristic reference warnings, not omitted source files or unverified behavior. They remain disclosed rather than changing fingerprinted historical summaries.

## Hosted authority

The candidate 85afb35703c4ea935633b30058b36968c5266afe passed canonical closeout in [run 37692220357](https://github.com/szTheory/scrypath/actions/runs/37692220357): all five required jobs, coverage and closeout attestation succeeded, with immutable artifact digests. Its receipt is also retained in `.planning/reference/v1.43-phase174-candidate-receipt.json`. The deep-quality and broad ecommerce E2E advisory jobs failed separately; these are not treated as a global green result. The broad candidate browser run reports 104 failed and 41 passed; all eight failing Phase174 cases fail because that broad harness does not resolve the standalone `ops:4003` service (`ERR_NAME_NOT_RESOLVED`). The separate phase harness includes that service and passes all 11 cases; no hosted Phase174 browser pass is inferred from the broad job. The dependency audit flags existing `cloak 1.1.4` (HIGH, EEF-CVE-2026-95105) and `cloak_ecto 1.3.0` (MEDIUM, EEF-CVE-2026-94206) in the Ops graph, with its lock digest unchanged. These are observed audit results, not remediation or risk acceptance. Candidate acceptance and the exact final SHA receipt are retained outside the frozen source checkout. Final tracking and verification artifacts precede the required final command:

```sh
node scripts/ci_monitor.cjs closeout --push \
  --branch gsd/phase-174-recovery-entry-and-diagnosis \
  --sha "$(git rev-parse HEAD)"
```

No tracked file is written after a successful final receipt. This record does not self-attest a future SHA; the source-bound external receipt is the authority. Deep quality / broad ecommerce E2E are advisory, separately assessed, and no global green, inherited Cloak advisory remediation, risk acceptance, merge or release claim is made.

## Review preview and preservation

Open http://127.0.0.1:4014/admin/search. The deliberately retained disposable review project is scrypath_phase174_d4395f2_review; its production views and fixtures were rebuilt at e286962. Backend/database ports remain unpublished. Browser test containers and parent validation PostgreSQL have been removed; the review stack remains available for feedback. Original localhost:4012 is untouched. Frozen Phase173 remains 13ea88a9c18a7515f4ec5ae7deea0cdde4c22531; all 15 original dirty files match their byte baseline. Evidence and receipts live under /private/tmp/scrypath-phase173-20261006-155750.

Historical limits remain explicit: BEFORE frames at 54c623e are within Phase174 before its 44px fix, not a complete pre174 matrix; 03-T1 has real RED/GREEN test evidence without separate RED-before-product Git commits; sudo return proves local interruption/canonical return/no replay, not host authentication or approval. Phase175 repair/promotion presentation and Phase176 Search/Playbooks remain outside this work.
