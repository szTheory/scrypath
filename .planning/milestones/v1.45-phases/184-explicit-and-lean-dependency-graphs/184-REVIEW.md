---
phase: 184-explicit-and-lean-dependency-graphs
reviewed: 2026-10-31T00:59:20Z
depth: standard
files_reviewed: 3
files_reviewed_list:
  - .github/workflows/ci.yml
  - scrypath_ops/mix.lock
  - examples/scrypath_ecommerce/mix.lock
findings:
  critical: 0
  warning: 0
  info: 0
  total: 0
status: clean
---

# Phase 184: Code Review Report

**Reviewed:** 2026-10-31T00:59:20Z
**Depth:** standard (configured depth)
**Files Reviewed:** 3 in the latest bounded follow-up; the earlier eleven-file repair review is preserved below
**Status:** clean within this working-tree diff scope

## Summary

No new BLOCKER or WARNING finding was established in the mounted-job timeout increase or the two Phoenix HTML lockfile repairs. The timeout change retains the existing verification and attestation checks. Both lockfiles select the compatible fixed release for the newly published attribute-injection advisory.

The earlier eleven-file repair review remains clean, with all five initial findings fixed as recorded below and in [184-REVIEW-FIX.md](184-REVIEW-FIX.md). This report does not grant terminal acceptance or human approval. A successful new-source hosted run and final exact-source attestation remain required.

## Narrative Findings (AI reviewer)

No new or remaining finding was established in the three-file follow-up. Historical resolved findings retain their original IDs and classifications in the preserved review below; they are excluded from the current zero finding counts.

## Bounded dirty-source follow-up

The reviewed baseline is HEAD `501dd05a47795096c0c8beaa658763610a36560c`. The three reviewed files have uncommitted changes; HEAD alone does not identify their reviewed content. Each diff changes exactly one existing line. The unrelated dirty `.planning/config.json` is outside this review and was preserved. The two lockfiles are explicitly included for this requested advisory repair.

| Reviewed file | Current content SHA-256 |
| --- | --- |
| `.github/workflows/ci.yml` | `db13b79a2a6038668659e5b3dcc2e2c0da395bc6146a1fe89be1b87ec1be2b59` |
| `scrypath_ops/mix.lock` | `f1771d6219216b5b144f1cf3d220ee487de39da7df071c8bbdaba1b2b3a44fdf` |
| `examples/scrypath_ecommerce/mix.lock` | `19024cdcc5be4d78f43ba990ec6b6113b8f9f58004031591d573834ba4c8817e` |

This is a separately requested bounded diff review, not a new canonical evaluation-scope resolution. The earlier eleven-file resolver's degraded `phase-range` / `no-task-commits-since` limitation remains recorded below; the repair bullet records have not been reclassified as recognized task commits.

### Timeout assessment

At `.github/workflows/ci.yml:402`, the mounted job's outer limit increases from 20 to 30 minutes. Required-job naming, step conditions, source/image verification, artifact handling, cleanup checks, and closeout input checks are unchanged. The verifier's own operation and finalization deadlines are unchanged.

The [raw mounted log](/private/tmp/scrypath-phase184-execution/candidate-root-mounted.log) starts the job at 00:32:52 UTC and reports completed test/production boundary checks, focused browser checks, runtime image verification, and clean owned-resource removal at approximately 00:52:55 UTC (lines 5781–5858). The [failed-run log](/private/tmp/scrypath-phase184-execution/candidate-root-failed.log:583) passes `ECOMMERCE_MOUNTED_RESULT: cancelled` into closeout, which exits nonzero. Those observations support additional outer-job headroom; they do not establish that the cancelled candidate passed or that 30 minutes has already been proven sufficient. The Buildx post-step's build-record upload is not a successful closeout attestation.

### Dependency repair assessment

At `scrypath_ops/mix.lock:36` and `examples/scrypath_ecommerce/mix.lock:28`, only Phoenix HTML changes, from 4.3.0 to 4.4.0, with matching package checksums and no added transitive dependencies. Both direct manifests permit `~> 4.1`, and the locked Phoenix LiveView, Phoenix Ecto, Phoenix Template, and Ops Flop Phoenix constraints permit 4.4.0.

The [CNA advisory record](https://cna.erlef.org/osv/EEF-CVE-2026-117645.json), independently fetched during this follow-up, identifies Phoenix HTML 4.4.0 as the fixed 4.x version for CVE-2026-117645. The independently fetched [Hex release metadata](https://hex.pm/api/packages/phoenix_html/releases/4.4.0) matches both lockfiles' outer checksum, declares Elixir `~> 1.7`, declares no dependencies, and reports no retirement. This repair therefore does not raise the project's declared Elixir floor. The captured [release changelog](/private/tmp/scrypath-phase184-execution/phoenix-html-changelog.txt) describes attribute-name validation and an additional escaping helper; no incompatible API removal was identified.

The captured [lock-resolution receipt](/private/tmp/scrypath-phase184-execution/phoenix-html-lock-resolution.json) reports successful updates and unchanged second dependency resolution for both graphs. Its after-hashes match the actual reviewed lockfiles. The [failed-run log](/private/tmp/scrypath-phase184-execution/candidate-root-failed.log) independently shows the original Phoenix HTML advisory in both affected graphs and retains nonzero audit behavior.

### Evidence and remaining gate

Read the actual three-file diff and surrounding workflow/dependency constraints, and examined all six requested raw evidence inputs: `candidate-root-mounted.log`, `candidate-root-failed.log`, `phoenix-html-advisory.json`, `phoenix-html-440.txt`, `phoenix-html-changelog.txt`, and `phoenix-html-lock-resolution.json` under `/private/tmp/scrypath-phase184-execution/`. Independently verified current source hashes, receipt identity, and official advisory/release metadata. The supplied actionlint result is supporting parent-owned evidence; this reviewer did not rerun or duplicate the already-started full Node and canonical Ops checks.

The parent must reconcile those running checks, commit the reviewed source, and obtain a successful hosted candidate and final attestation for that exact source. The cancelled run remains failed evidence. Known Cloak/Cloak Ecto advisories remain affected and unaccepted; this targeted package repair is not universal audit clearance or risk acceptance. No live or retained service was operated, no retained preview was changed, and no approval was simulated.

The historical section below records the earlier review at its own source cutoff and time. Its then-pending verification statements are historical, not claims about completion of the current hosted gate.

---

## Historical eleven-file repair review

**Reviewed:** 2026-10-31T00:24:51Z
**Depth:** standard (configured depth)
**Files Reviewed:** 11
**Status:** clean within the bounded repair scope

### Summary

No remaining findings were found in the eleven changed source, documentation, and test files. The five initial counterexamples are addressed by the current repairs, and no additional defect was established in those repairs.

The initial full review is preserved at Git revision `99dd2a62:.planning/phases/184-explicit-and-lean-dependency-graphs/184-REVIEW.md`. [184-REVIEW-FIX.md](184-REVIEW-FIX.md) remains the canonical disposition and evidence ledger for its five findings. [184-UI-REVIEW-DISPOSITION.md](184-UI-REVIEW-DISPOSITION.md) separately records the nil-sudo recovery and feedback repairs and the current rendered-review limitation.

### Historical files reviewed

- examples/scrypath_ecommerce/scripts/verify-dependency-boundaries.sh
- scripts/ci/ecommerce_lifecycle.test.cjs
- scrypath_ops/README.md
- scrypath_ops/lib/scrypath_ops/integrations/sigra/gating.ex
- scrypath_ops/lib/scrypath_ops/security.ex
- scrypath_ops/lib/scrypath_ops_web/telemetry.ex
- scrypath_ops/test/scrypath_ops/integrations/sigra/gating_test.exs
- scrypath_ops/test/scrypath_ops/integrations/sigra/on_mount_test.exs
- scrypath_ops/test/scrypath_ops/security_validation_test.exs
- test/mix/tasks/dependency_boundary_contract_test.exs
- test/release/ops_dependency_boundary_test.exs

### Scope and provenance

Reviewed current source at `e493e19a94310ce823f4628ebaabd6b2e08aedc0`. All eleven reviewed files match implementation cutoff `1b98eb1a9522c1e80c4cedff10409b681dad0dde`; the later commit contains tracking changes.

The canonical incremental scope at `/private/tmp/scrypath-phase184-execution/re-review-scope.json` is explicitly **degraded**, with source `phase-range`, reason `no-task-commits-since`, and range base `99dd2a62`. The resolver did not recognize the repair bullet records as task commits. Its eleven-file range matches the actual Git source-file changes, with no reported missing files, outside-union paths, or unreachable commits. This is a bounded range-based re-review, not a resolved task-commit scope or a fresh review of all 59 historical source files.

### Historical narrative result

No remaining BLOCKER or WARNING findings were established in the reviewed repairs.

### Rechecked initial findings

The following rows record resolved historical findings; they are not new or standing findings.

| Initial finding | Initial classification | Current source and regression assessment |
| --- | --- | --- |
| CR-01 — partial diagnostics graph failed startup | BLOCKER | `scrypath_ops/lib/scrypath_ops_web/telemetry.ex:1` requires both real Metrics and poller capabilities. A fresh VM with Metrics present and the poller absent no longer defines the incomplete Ops supervisor. The cold mounted metrics-only consumer explicitly loads real Metrics before rechecking the actual source, preventing compiler ordering from hiding the counterexample. |
| CR-02 — malformed identity terms authorized actions | BLOCKER | `scrypath_ops/lib/scrypath_ops/integrations/sigra/gating.ex:119-123` accepts nonblank valid UTF-8 strings and positive integers and rejects other representations. Fresh current-source probes denied malformed values in both identity fields across every protected action while retaining supported string/integer positive cases. |
| WR-01 — failed extraction container escaped cleanup | WARNING | `examples/scrypath_ecommerce/scripts/verify-dependency-boundaries.sh:210`, `:289-290`, and `:398-414` share the target extraction container registration with EXIT cleanup, attach run ownership, and clear registration only after successful removal. The four actual-script Docker-double tests pass for both runtime targets with successful and failed removal, preserve original copy exit 42, and distinguish cleanup success from failure. |
| WR-02 — invalid confirmation path passed startup validation | WARNING | `scrypath_ops/lib/scrypath_ops/security.ex:7` and `:49-61` reject the installed LiveView API's unsafe local-navigation forms. Fresh current-source checks reject the original backslash/control-character counterexamples; accepted configured paths reach actual LiveView confirmation for every protected action without invoking the callback. |
| WR-03 — direct Ops quickstart advertised an incompatible minimum | WARNING | `scrypath_ops/README.md:7-11` states the default standalone Sigra-compatible Elixir 1.18+ prerequisite while retaining the root/no-Sigra 1.17 floor and linking to the canonical tuple authority. The focused source contract checks those distinctions. |

The nil-sudo confirmation journey remains intact in the current gate. The additional denial messages explain signing in again or contacting an administrator. The updated OnMount test still asserts that the protected callback cannot execute; its copy assertion now follows the recovery instruction.

### Verification and limits

Checks performed during this re-review:

- Read all eleven current files and traced the repaired guards, action decisions, navigation calls, and extraction-container cleanup paths.
- Ran a fresh Elixir 1.19/OTP 28 Metrics-only probe against the actual telemetry source and real Metrics dependency beam. It confirmed the poller and incomplete Ops supervisor are absent.
- Loaded the actual current OperatorContext, capability, Security, and Gating source with real dependency beams in a fresh, service-free VM. Malformed identities were denied in both fields across all protected actions; supported IDs still executed a fresh-confirmed callback; unsafe paths failed validation; accepted paths preserved nil-sudo navigation for every action.
- Ran `node --test --test-name-pattern='runtime boundary target extraction' --test-reporter=tap scripts/ci/ecommerce_lifecycle.test.cjs`: all four fault cases passed. These use external-I/O doubles and operate no real Docker stack.
- Re-read the supplied cold Metrics-only, cleanup, authentication/OnMount/navigation, and quickstart-contract evidence. Their observed results support the repair scopes recorded above; they are not substituted for final hosted evidence.
- Verified the reviewed source files match the implementation cutoff and the supplied eleven-file range.

This clean code re-review does **not** grant terminal phase acceptance. The already-running canonical Ops verification remains parent-owned and was not duplicated or operated here. New-source hosted candidate verification and final exact-source attestation remain pending parent reconciliation. Known Cloak/Cloak Ecto advisories remain affected and unaccepted. The source-stale retained preview was untouched; no rendered design approval or human approval is claimed.

Only this REVIEW.md was changed by the reviewer. Source files, other reports, and the unrelated dirty `.planning/config.json` were preserved. No commit was made.

---

_Reviewer: gsd-code-reviewer_
_Depth: standard_
