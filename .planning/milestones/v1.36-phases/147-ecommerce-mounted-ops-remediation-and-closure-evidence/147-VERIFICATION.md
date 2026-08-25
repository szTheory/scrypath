---
phase: 147-ecommerce-mounted-ops-remediation-and-closure-evidence
verified: 2026-08-25T19:09:36Z
status: passed
score: 15/15 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 147: Ecommerce Mounted-Ops Remediation and Closure Evidence Verification Report

**Phase Goal:** Maintainers can run the ecommerce mounted integration on its own remediated graph and can audit complete, ordered closure evidence for all four graphs.
**Verified:** 2026-08-25T19:09:36Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Fresh ecommerce resolution selects the approved fixed-compatible set, is audit-clean, and uses canonical mounted root/Ops sources. | ✓ VERIFIED | `mix.exs` has the six approved bounds; current ecommerce `mix deps.get --check-locked` and unsuppressed `mix hex.audit` exit 0; `Mix.Project.deps_paths/0` resolves physically to the repository root and `scrypath_ops/`. |
| 2 | A later remediation batch begins only after the preceding batch’s required gates pass. | ✓ VERIFIED | Ledger records ordered batches; actual ancestry confirms `f711521 → e50fbd5/4e2abed → 59d2e6a/ff1531c → fca4c82`, and each matrix row records checked-lock/audit exit 0. |
| 3 | Missing services, empty receipts, or unavailable prerequisites cannot be accepted as success. | ✓ VERIFIED | `docker-e2e-entrypoint.sh` waits for PostgreSQL and Meilisearch with `set -eu`; browser readiness exits 70 after 60 failed checks; `verify-e2e.sh` propagates browser/cleanup failure. Ledger separately records `state: passed` with healthy prerequisites rather than treating absence as pass. |
| 4 | Ecommerce gates follow the locked diagnostic order and stop on unexplained drift/failure. | ✓ VERIFIED | `verify-e2e.sh` uses `set -Eeuo pipefail`, validates the Compose model before `up`, propagates browser status, and exits nonzero before success; current contract tests cover its required ordering/wiring. |
| 5 | Mounted integration and focused browser proof run from one Docker-only local/CI command without human UAT. | ✓ VERIFIED | Make targets call one runner in focused/full modes; the combined Compose model has no verifier host ports, browser targets `http://web:4002`, and CI invokes `make -C examples/scrypath_ecommerce verify-mounted`. The exact-SHA receipt records an automated 4/4 focused run. |
| 6 | The Docker-only lifecycle owns readiness, `mix e2e.prepare`, both asset builds, focused browser proof, diagnostics, and cleanup. | ✓ VERIFIED | Entrypoint waits for both services, runs `mix e2e.prepare`, ecommerce and Ops asset builds, then seeds and starts Phoenix. The runner captures logs/reports, uses `--exit-code-from browser`, removes volumes/orphans, and fails if labelled containers remain. |
| 7 | Focused CI is required while complete `phase105-e2e` remains advisory. | ✓ VERIFIED | `.github/workflows/ci.yml` defines an unconditional, 20-minute `ecommerce-mounted-smoke` job with failure artifacts and the focused Make target. `CONTRIBUTING.md` labels it a required merge gate and explicitly labels `phase105-e2e` advisory. |
| 8 | Browser evidence is independently and honestly classified; retry-only success cannot replace deterministic/service proof. | ✓ VERIFIED | Closure ledger has exactly one `state: passed`, records healthy prerequisites, first-attempt 4/4, `flake: false`, and says the optional full lane does not replace exact-candidate focused proof. Browser runner and contract test retain retry visibility. |
| 9 | Each graph has its own nonempty checked-lock/audit evidence; an empty or failing row blocks closure. | ✓ VERIFIED | The same-window matrix has separate root, legacy, ScrypathOps, and ecommerce rows, all with lock hash plus `exit 0` checked-lock/audit. Independent current checks also passed for all four directories. |
| 10 | The final matrix is root → legacy Phoenix → ScrypathOps → ecommerce within one UTC window. | ✓ VERIFIED | `147-CLOSURE-EVIDENCE.md` records `2026-08-25T19:00:59Z`–`19:01:13Z` and exactly that numbered row order; the plan’s Ruby ordering assertion passed. |
| 11 | History is truthfully represented as four remediation batches, not four literal graph-local commits. | ✓ VERIFIED | Ledger and requirements state “four ordered remediation batches”; `git diff-tree` confirms shared handoff `f711521`, legacy primary/recovery, Ops primary/test closure, and ecommerce-only `fca4c82` path sets. |
| 12 | Roadmap: the fresh ecommerce directory has no recorded advisories while mounted root/Ops sources remain green. | ✓ VERIFIED | Current ecommerce checked-lock/audit and canonical source-path assertion pass; exact-SHA receipt also records the nine selected fixed versions and no advisory. |
| 13 | Roadmap: documented deterministic checks pass before the ecommerce batch commit. | ✓ VERIFIED | Exact-SHA ledger records checked lock, compile, controller/precommit, service preparation, root gates, and audit as PASS before candidate `fca4c82`; the candidate’s actual diff is only ecommerce `mix.exs` and `mix.lock`. |
| 14 | Roadmap: dated evidence covers all four directory resolutions with no 2026-08-16 advisories. | ✓ VERIFIED | The dated same-window ledger contains all four rows and references prior exact-candidate fresh proofs; current checked-lock/audit checks independently pass in all four directories. |
| 15 | Roadmap: every constituent role in the four ordered batches is auditable. | ✓ VERIFIED | Actual commit existence, ancestry, and `git diff-tree` path sets match the ledger’s roles for `f711521`, `e50fbd5`, `4e2abed`, `59d2e6a`, `ff1531c`, and `fca4c82`. |

**Score:** 15/15 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `examples/scrypath_ecommerce/mix.exs` | Approved ecommerce bounds and mounted deps | ✓ VERIFIED | Six required direct bounds and both path dependencies are present. |
| `examples/scrypath_ecommerce/mix.lock` | Causal fixed resolution | ✓ VERIFIED | Contains Postgrex 0.22.4 and selected fixed-compatible cohort; checked-lock/audit pass. |
| `examples/scrypath_ecommerce/scripts/verify-e2e.sh` | Collision-free focused/full lifecycle | ✓ VERIFIED | Substantive fail-fast Bash implementation, invoked by both Make targets, with artifact capture and fail-closed cleanup. |
| `.github/workflows/ci.yml` | Focused required smoke lane | ✓ VERIFIED | Distinct, unconditional `ecommerce-mounted-smoke` job runs the same focused target. |
| `147-CLOSURE-EVIDENCE.md` | Exact-SHA, browser, matrix, cleanup, and topology receipt | ✓ VERIFIED | Contains each required section and is linked to exact implementation/history evidence. |
| `.planning/REQUIREMENTS.md` | EVID-02 ordered-batch wording | ✓ VERIFIED | Requirement wording and all five Phase 147 checkboxes match closure truth. |
| `.planning/todos/completed/2026-08-16-remediate-dependency-security-advisories.md` | Closed advisory intake | ✓ VERIFIED | Exists only under `completed/`, has `status: completed`, date, and closure-ledger pointer. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- |
| Ecommerce manifest | Ecommerce lock | Resolver/checked-lock proof | ✓ WIRED | Current `mix deps.get --check-locked` succeeds and lock selects compatible Phoenix 1.8.13. |
| Ecommerce manifest | Root and ScrypathOps paths | `Mix.Project.deps_paths/0` + physical canonicalization | ✓ WIRED | Runtime dependency paths equal `/Users/jon/projects/scrypath` and `/Users/jon/projects/scrypath/scrypath_ops`. |
| Make targets | Compose verifier | `verify-e2e.sh focused/full` | ✓ WIRED | Both targets invoke the same script; contract test passes. |
| CI smoke job | Focused Make target | GitHub Actions run step | ✓ WIRED | Job block calls `make -C examples/scrypath_ecommerce verify-mounted`. |
| Plan 147-01 receipt | Closure ledger | Exact candidate SHA | ✓ WIRED | Both identify `fca4c827a59596e2a66bc2d1ac3516b4c0c5681e`. |
| Historical phase receipts | Closure matrix/topology | Referenced candidates and commit roles | ✓ WIRED | Prior summaries contain the cited 144/145/146 candidates; current history confirms their roles. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Docker verifier | Compose browser exit status | `docker compose up --exit-code-from browser` | Browser service result is propagated and artifacts are collected | ✓ FLOWING |
| Docker web entrypoint | Prepared app/search state | Compose-health-gated Postgres/Meilisearch, `mix e2e.prepare`, asset builds, deterministic seed | Real services and build commands, not static fixture output | ✓ FLOWING |
| Closure ledger | Four graph rows and batch topology | Current checked-lock/audit commands plus actual Git ancestry/path sets | Each graph/commit is independently present and auditable | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Contract wiring for Docker lifecycle, Playwright version, CI posture | `mix test test/scrypath/phase147_e2e_contract_test.exs test/mix/tasks/workflow_wiring_test.exs test/scrypath/phase111_contract_test.exs` | 47 tests, 0 failures | ✓ PASS |
| Combined verifier model is valid | `docker compose -f .../compose.yaml -f .../compose.e2e.yaml config --quiet` | Exit 0; resolved model has browser-to-web networking and no verifier port mapping | ✓ PASS |
| All four current dependency graphs remain clean | `mix deps.get --check-locked && mix hex.audit` in root, legacy, Ops, ecommerce | Four pairs exit 0 | ✓ PASS |
| Mounted path identity | Ecommerce `Mix.Project.deps_paths/0` followed by physical shell canonicalization | Root and Ops paths equal intended mounted directories | ✓ PASS |
| Matrix order/topology contract | Plan Ruby matrix assertion | Exit 0 | ✓ PASS |

### Probe Execution

No phase-specific `scripts/*/tests/probe-*.sh` probe was declared or found. The phase’s runnable evidence is the focused Docker target and its contract coverage. Per verification constraints, this audit did not start a new service stack; the exact-SHA automated focused/full browser and service results are preserved in the closure receipt and their orchestration is covered by the passing contract tests above.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| SEC-04 | 147-01, 147-02 | Independently remediate ecommerce on green mounted sources | ✓ SATISFIED | Fixed bounds/lock, current clean audit, canonical paths, exact-SHA evidence. |
| COMPAT-01 | 147-01, 147-03 | Required gates before each next batch | ✓ SATISFIED | Ordered matrix, batch ancestry, gate receipts, and fail-closed scripts. |
| COMPAT-03 | 147-01, 147-02 | Separate, honest browser evidence | ✓ SATISFIED | Required focused CI, distinct advisory full lane, classified exact-candidate result. |
| EVID-01 | 147-03 | Dated all-four-graph advisory-free evidence | ✓ SATISFIED | Same-window four-row receipt plus current four-directory audits. |
| EVID-02 | 147-03 | Four ordered remediation batches with constituent roles | ✓ SATISFIED | Ledger, requirements, completed todo, actual commit paths and ancestry. |

No Phase 147 requirement is orphaned from its plans.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| None | — | No unresolved `TBD`/`FIXME`/`XXX`, placeholder implementation, or hollow static data path found in Phase 147 implementation/evidence files. | ℹ️ Info | No blocker. |

### Disconfirmation Pass

- **Partial-requirement check:** The verifier uses physical shell canonicalization rather than the Plan’s unavailable `File.realpath!/1`; current path assertion passes, so this is a supported implementation deviation, not missing mounted-path proof.
- **Misleading-test check:** Contract tests could only prove script/CI wiring, so they were not treated alone as browser evidence. The report additionally checked the exact-SHA classified receipt, Compose model, service entrypoint, and current all-graph dependency gates.
- **Error-path check:** Browser and cleanup failures propagate nonzero through `verify-e2e.sh`; unavailable services/readiness fail explicitly rather than being classified as passed.

### Human Verification Required

None. The phase’s service and browser claims are covered by exact-SHA automated evidence and the required focused CI lifecycle; no visual/manual-UAT truth is a completion condition.

---

_Verified: 2026-08-25T19:09:36Z_
_Verifier: the agent (gsd-verifier)_
