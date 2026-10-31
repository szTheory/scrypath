# Phase 184 Plan 10 — Candidate Acceptance Record

**Status: implementation and targeted review repairs verified; final merged-branch validation is in progress.** The historical candidate records below remain intact. Current integration status is recorded separately; no security-risk acceptance or human approval is implied.

## Source and graph evidence

The final four-graph audit and independent Dialyzer run used implementation source `6838085626174c8016e9cf57aa9af84dccab20df`, Elixir 1.19.5 / OTP 28.5, and Hex 2.5.1. The later audit-evidence and candidate fixes do not change dependency manifests, locks, or audit behavior. The complete per-graph source, manifest/lock fingerprints, selected versions, raw output paths, and exit codes are in [184-DEPENDENCY-EVIDENCE.md](./184-DEPENDENCY-EVIDENCE.md). The corrected local core and mounted checks used code source `a109ff27ae369e19f88691f99a0163479bbee3ff`.

| Graph | Fetch | Audit | Result |
| --- | ---: | ---: | --- |
| Root | 0 | 0 | Clean |
| Phoenix example | 0 | 0 | Clean |
| Ecommerce | 0 | 0 | Clean |
| ScrypathOps | 0 | 1 | Affected; two Cloak advisories remain unaccepted |

All four locks were unchanged by the final `deps.get --check-locked` and audit runs. Hex reported empty default ignore inputs. The aggregate audit exit was 1 because Ops remains affected by EEF-CVE-2026-95105 / CVE-2026-95105 (Cloak AES-CTR authentication) and EEF-CVE-2026-94206 / CVE-2026-94206 (Cloak Ecto PBKDF2 iteration count). No finding was ignored, waived, or accepted. Independent `mix dialyzer` completed with zero errors. Raw receipts are under `/private/tmp/scrypath-phase184-10-20261030T072352Z/`.

All ten proposals (#65 and #68–#76) have source, selected-version, evidence, rationale, status, and revisit-trigger entries in [184-ACTIONS-DISPOSITIONS.md](./184-ACTIONS-DISPOSITIONS.md). The referenced GitHub proposals remained open during inventory; this plan did not change them.

## Local candidate verification after scoped fixes

The expanded dependency audit/boundary/verifier contract tests passed: 45 tests, 0 failures, with warnings treated as errors. `mix verify.core --exclude integration --exclude docs_contract` now passes, including the no-Oban compile. The corrected cold `mix verify.ecommerce_mounted` run passed its independent runtime-boundary proof and all four focused browser checks; cleanup reported zero containers, networks, or volumes. Its run ID is `20261030T084825Z-88898-217393799`, source is `a109ff27ae369e19f88691f99a0163479bbee3ff`, and receipts are under `/private/tmp/scrypath-phase184-10-20261030T072352Z/ecommerce-mounted-artifacts/20261030T084825Z-88898-217393799/`. The retained `scrypath_ecommerce` containers remained up and separate. Repository contracts, package verification, backend verification, isolated Ops UI verification, and local compatibility verification also passed on Elixir 1.19.5 / OTP 28.5. `actionlint .github/workflows/ci.yml .github/workflows/workflow-security.yml` passed. Independent `mix dialyzer` passed with zero errors. Logs and exit receipts remain under `/private/tmp/scrypath-phase184-10-20261030T072352Z/`.

The first hosted candidate was `2d6987f5620b53f6f5bc4968f72f77983eaa3148`, run `41024777215` ([CI run](https://github.com/szTheory/scrypath/actions/runs/41024777215)), dispatched at `2026-10-30T08:11:21Z`. It failed because required `core` and `ecommerce-mounted` failed, and the dependent `closeout-attestation` job failed. Required `package`, `repository-contracts`, and `backend` passed. The core failure was Credo's known-argument `apply/3` warning at `test/mix/tasks/verify_capability_test.exs:140`; this plan fixed it by calling the verifier contract directly. The ecommerce failure was a reproducible concurrent Hex cache write/rename race across Docker targets; the Dockerfile cache mounts now use BuildKit `sharing=locked`. The full failed-job log and immutable job/artifact receipts are external at `/private/tmp/scrypath-phase184-10-20261030T072352Z/logs/candidate-failed-jobs.log`, `receipts/candidate-jobs.tsv`, and `receipts/candidate-artifacts.tsv`.

The first run's compatibility matrix passed all four hosted tuples (1.17.3/26.2.5, 1.18.4/27.3, 1.19.0/26.2.5, 1.19.0/28.1). The coverage artifact passed with digest `sha256:1d4a9aabe02c13d066eaee920788e6d79c89e2f026ad35be7b879bb6457c9215`; no closeout-attestation artifact exists for that failed run. The advisory deep-quality job remains failed because the two Ops Cloak findings below are deliberately unaccepted. The second canonical closeout is run immediately after this report and Summary commit. Its exact source, run, required job outcomes, coverage/attestation digests, and artifact paths are recorded outside the checkout in the same runtime directory; this pre-closeout document does not claim those pending results.

The available local tuple was Elixir 1.19.5 / OTP 28.5. Hosted compatibility evidence above is from the first candidate SHA; the second exact-source run must be inspected before carrying those results forward to the corrected candidate.

## UI and delivery limits

The named retained preview checkout is `/Users/jon/projects/scrypath/.claude/worktrees/ui-experience-reconciliation`, branch `ui/next`, at `http://127.0.0.1:4002`. Its required read-only `npm run ui:preflight` refused review because that checkout does not include `origin/main`. It also has pending tracked CSS work and an untracked playbooks directory, both preserved. No screenshot or current rendered UI evidence was collected, and no independent UI review is claimed. No preview data, service, or baseline was changed.

No publication, merge, PR closure, remote proposal modification, support-floor change, or security-risk acceptance is authorized by this candidate. The orchestrator owns the merged `planning/v1.45-foundation-ci` terminal closeout after phase integration and tracking writes. The retained preview checkout, services, volumes, and data remain untouched; no current rendered UI review is claimed.


## Merged-branch integration follow-up

The corrected isolated candidate passed [run 41029783634](https://github.com/szTheory/scrypath/actions/runs/41029783634): required jobs, coverage, attestation, all four compatibility tuples, Phoenix, full ecommerce E2E and Ops UI. Its immutable source/run/artifact identities remain external in `receipts/candidate-2-final.json` under the Plan 10 runtime directory. This resolves the candidate's pending-at-authoring status above; it is not terminal evidence for later source changes.

All twelve plans have since been integrated. Code/UI review found bounded counterexamples and the repairs in [184-REVIEW-FIX.md](184-REVIEW-FIX.md) now have passing targeted evidence; [UI dispositions](184-UI-REVIEW-DISPOSITION.md) preserve the remaining rendered-review limit. The first post-review canonical Ops/root runs exposed two test expectations described in the repair report; both were corrected and targeted checks passed. Full canonical verification is being rechecked with a fresh owned Postgres. Final phase verification and exact-source hosted closeout follow after these reports. The two Ops Cloak findings remain unaccepted.

The repaired root fast suite is green, including the namespace canary, archive dependency/public consumer checks, and repository contracts reached by that suite. New authentication/lifecycle/navigation checks pass. The remaining full Ops rerun and fresh hosted exact-source candidate remain machine work owned by the orchestrator; no human UAT is pending.
