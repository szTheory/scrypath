# Phase 184 Plan 10 — Candidate Acceptance Record

**Status: Partial; terminal hosted acceptance remains to be evaluated.** This record captures candidate evidence before the required final hosted closeout. It does not mark phase acceptance, advisory risk acceptance, or pending human review as complete.

## Source and graph evidence

The final four-graph audit and independent Dialyzer run used implementation source `6838085626174c8016e9cf57aa9af84dccab20df`, Elixir 1.19.5 / OTP 28.5, and Hex 2.5.1. The later `da64e0a7c051a8b983031fefd677802862d92f94` commit only corrected the checked-in evidence references; it did not change application code, manifests, locks, or audit behavior. The complete per-graph source, manifest/lock fingerprints, selected versions, raw output paths, and exit codes are in [184-DEPENDENCY-EVIDENCE.md](./184-DEPENDENCY-EVIDENCE.md).

| Graph | Fetch | Audit | Result |
| --- | ---: | ---: | --- |
| Root | 0 | 0 | Clean |
| Phoenix example | 0 | 0 | Clean |
| Ecommerce | 0 | 0 | Clean |
| ScrypathOps | 0 | 1 | Affected; two Cloak advisories remain unaccepted |

All four locks were unchanged by the final `deps.get --check-locked` and audit runs. Hex reported empty default ignore inputs. The aggregate audit exit was 1 because Ops remains affected by EEF-CVE-2026-95105 / CVE-2026-95105 (Cloak AES-CTR authentication) and EEF-CVE-2026-94206 / CVE-2026-94206 (Cloak Ecto PBKDF2 iteration count). No finding was ignored, waived, or accepted. Independent `mix dialyzer` completed with zero errors. Raw receipts are under `/private/tmp/scrypath-phase184-10-20261030T072352Z/`.

All ten proposals (#65 and #68–#76) have source, selected-version, evidence, rationale, status, and revisit-trigger entries in [184-ACTIONS-DISPOSITIONS.md](./184-ACTIONS-DISPOSITIONS.md). The referenced GitHub proposals remained open during inventory; this plan did not change them.

## Local candidate verification

The focused dependency audit/boundary contract tests passed: 34 tests, 0 failures, with warnings treated as errors. Repository contracts, package verification, backend verification, isolated Ops UI verification, isolated mounted-ecommerce verification, and the local compatibility verifier all passed on Elixir 1.19.5 / OTP 28.5. Workflow YAML syntax passed `actionlint .github/workflows/ci.yml .github/workflows/workflow-security.yml`. Their raw logs and exit receipts are in the external directory above.

`mix verify.core --exclude integration --exclude docs_contract` returned exit 8. Credo reported `Avoid apply/2 and apply/3 when the number of arguments is known` at `test/mix/tasks/verify_capability_test.exs:140`. The same file and line are present at the plan base `f1384a7323f1ac69cf813a463e479df68bc6a9bf`, and the file is unchanged by this plan. The failure is therefore recorded as an existing gate blocker; no unrelated source change was made.

The available local tuple was Elixir 1.19.5 / OTP 28.5. It does not prove the Elixir 1.17 / OTP 26 floor or the other matrix tuples. Hosted compatibility evidence is expected from the candidate CI workflow dispatch; until that receipt is inspected, those tuples remain unverified in this record.

## UI and delivery limits

The named retained preview checkout is `/Users/jon/projects/scrypath/.claude/worktrees/ui-experience-reconciliation`, branch `ui/next`, at `http://127.0.0.1:4002`. Its required read-only `npm run ui:preflight` refused review because that checkout does not include `origin/main`. It also has pending tracked CSS work and an untracked playbooks directory, both preserved. No screenshot or current rendered UI evidence was collected, and no independent UI review is claimed. No preview data, service, or baseline was changed.

No publication, merge, PR closure, remote proposal modification, support-floor change, or security-risk acceptance is authorized by this candidate. The exact final source/run/artifact result from canonical hosted closeout will be captured after the Summary commit under `/private/tmp/scrypath-phase184-10-20261030T072352Z/receipts/`; the closeout is not yet represented as passing here.

