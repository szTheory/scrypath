# Phase 175 closeout — Repair and Verification

Recorded 2026-10-10 for v1.43 ScrypathOps UI refinement. All six plans and
OPUX-20, OPUX-21, OPUX-22 have independent local/candidate-stage verification.
This is draft-branch delivery; no merge, release, real host authorization or
advisory risk acceptance is claimed.

## Delivered behavior

Sync and drift separates ordinary sync, index configuration checks and advanced
promotion. Configuration matches do not establish document freshness. Failed or
missing observations stay unavailable, and independent results remain readable.

Recovery retains the exact source-qualified receipt and retry attempt. Promotion
retains the returned backend task UID and exact live/target index pair. Rechecks
observe that same work without submitting another mutation. Task reads and remote
states remain distinct; accepted, running, failed, canceled, succeeded and unknown
are represented truthfully. Completion requires matching authoritative task and
active-index document evidence.

Server-side host authorization and current eligibility still guard confirmation
and submission. Changed schema, allowlist, generation, endpoint, backend, Oban
instance, repo, prefix or node invalidate stale context. Authorization return does
not replay work. Advanced disclosure does not hide accepted task identity/status.
No dependency, core API, backend or authorization product was added.

## Verification and scope

- Independent goal verification: **29/29**, canonical status `passed`;
  `175-VERIFICATION.md` includes consumed-file fingerprints, bounded evidence,
  and the distinction between candidate acceptance and final immutable-source
  closeout.
- Final scoped Ops `mix precommit`: **334 tests + 2 doctests, zero failures**.
- Independent owned Phase 175 browser probe: **7/7**, no skipped cases or retries,
  source `7547a346f9e7db65e33ba3e6477e302e5465f80f`, cleanup status 0.
- Existing required mounted operator browser proof: **4/4**, including exact
  confirmation pair, returned task UID and active document; accepted status stays
  visible after closing Advanced.
- Prior Phase 173/174 browser regression: **113/113**, zero failures, skips or
  retries. Root regression: **735 tests + 4 properties**, zero failures;
  11 explicitly excluded tests and the existing unrelated Elixir warning remain
  recorded in their logs.
- All **six actual GSD prohibition producers** independently passed with an
  intended assertion failure on the in-memory bad subject and a passing clean
  current-source control. Setup/compilation errors cannot substitute for the
  required behavioral failure. Adapters reuse existing ExUnit assertions and
  introduce no dependency.
- Code review: original development fixture exposure fixed with a test-only
  route guard; independent fix/disposition and follow-up reviews have **zero
  open findings**. UI audit: **23/24**, with one nonblocking outline-polish item.
- Security: **zero high-threshold blockers**, 16/17 threats closed; medium host
  authorization advisory T-175-11 remains unaccepted. Host integration authority
  is not simulated by the fixture or by these checks.

The UI matrix maps 68 component/category pairs to source and grouped checks;
it does not claim 68 distinct browser cases or a full state × theme × viewport
cross-product. Captures cover 390/768/1440 Light/Dark, System Light/Dark,
reduced motion and dialog keyboard/focus behavior. Long-value geometry and
selectable UID/Ctrl+C evidence do not claim maximal-value modal captures or OS
clipboard readback. Historical intermediate failures remain retained.

The three raw edge-probe rows remain unclassified historical provenance. No
classification or approval was invented. Binding acceptance comes from the
approved requirements/CONTEXT and the independently exercised tests, including
all six safety prohibitions. Execution-time `requirements-completed: []` and
pending statements in individual plan summaries remain their original cutoff;
canonical REQUIREMENTS/ROADMAP and this whole-phase record supersede them.

## Candidate hosted acceptance

Accepted source: `fd216fb1b6ee31e535884bb74b40ae166e12df55`.
[CI run 38072905651](https://github.com/szTheory/scrypath/actions/runs/38072905651),
workflow_dispatch attempt 1, completed **success**. All five required jobs,
coverage and closeout-attestation passed. The validated immutable receipt is
retained externally at:

`/private/tmp/scrypath-phase173-20261006-155750/evidence/phase175/candidate-receipt-2.json`

Coverage artifact 11677209274:
`sha256:7483bf5ecce229312a3f5a0a27085ecff6c202e2a704b106fc3247bd66d476ea`.
Attestation artifact 11678010331:
`sha256:dd00dfbf28be7a95fb3760226d839b8a701af2ebefc5aae2441ab647c30b6487`.
The attestation member has its distinct verified digest in the receipt.

Existing deep-quality dependency advisories remain visible and unaccepted;
passing required closeout does not claim every advisory CI job is green. Broader
advisory browser results are not represented as a complete passing matrix.

## GSD transition and warnings

Canonical `phase.complete 175` returned 6/6 plans, next phase **176 Search and
Playbooks**, `is_last_phase: false`, no indeterminate staleness result and no
preservation warning. Requirements OPUX-20–22 and roadmap/state were advanced.
The tool also emitted three command-as-filename warnings:

1. `175-02-SUMMARY.md`: two literal `mix test ...` commands were interpreted as
   missing file paths.
2. `175-03-SUMMARY.md`: `cd scrypath_ops && mix test ...` was interpreted as a
   missing file path.
3. `175-04-SUMMARY.md`: two `cd scrypath_ops && mix test ...` commands were
   interpreted as missing file paths.

The actual referenced LiveView, recovery observation, document observation and
promotion eligibility test files exist and have passing proof. These are summary
scanner warnings, not missing executable evidence. Their original verified
summary bytes are preserved. The independent report remains fresh.

Global learnings copying is disabled. Graduation skips under its threshold:
only two completed prior phases exist in the current milestone when excluding
Phase 175. No matching pending todo or stale Phase 175 handoff remains. Flat
transition manifest excludes workstream collision checks. Automatic chaining is
disabled; Phase 176 is not started. Milestone progress is **3/5 phases (60%)**
and **14/20 requirements**; 18/18 currently planned plans is not milestone 100%.

## Final immutable-source procedure

Per CONTRIBUTING.md, commit this closeout, verification and all final tracking
before running `node scripts/ci_monitor.cjs closeout --push` at the exact final
HEAD. The final run must complete successfully with all five required jobs,
coverage, closeout-attestation and immutable SHA-bound artifacts. Collect its
validated receipt outside the checkout at:

`/private/tmp/scrypath-phase173-20261006-155750/evidence/phase175/final-receipt.json`

The receipt must match the final Git HEAD, run and attempt. Final run/SHA/digest
facts are also recorded in the draft PR body after acceptance. This committed
record cannot embed the hash of its own enclosing final commit. No tracked
writes follow successful final attestation; a later source edit requires a new
exact-SHA closeout. This procedure alone does not claim that future run passed.

After all checks, remove only the task-owned Phase 175 test PostgreSQL container
and record cleanup/preservation externally. Retain previews 4012/4014, the
original fifteen dirty files, frozen Phase 173 source and next-planning checkout.
No preview reseeding or unrelated service cleanup is authorized or needed.

## Handoff

Working checkout:
`/private/tmp/scrypath-phase173-20261006-155750/phase174-execution`.
Branch: `gsd/phase-174-recovery-entry-and-diagnosis`.
[Draft PR95](https://github.com/szTheory/scrypath/pull/95), based on the Phase 173
branch/PR94, carries Phase 174 and Phase 175 improvements.

Next: **`$gsd-discuss-phase 176`** to prepare Search and Playbooks using the
accepted UX audit/rubric and existing domain vocabulary. Then settle its UI
contract and plan before execution. Context may be compacted: decisions, scope,
evidence limits, checkout and next command are persisted. The agent selects this
checkout in the ongoing conversation; no manual directory setup is needed.
