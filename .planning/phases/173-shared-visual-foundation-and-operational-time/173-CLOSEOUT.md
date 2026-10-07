# Phase 173 execution closeout

Phase 173 completes four plans and OPUX-09–OPUX-15 within v1.43. Independent verification passed 58/58 must-haves with no human-verification items. The clean independent code re-review, authored threat coverage, Nyquist record, UI audit/disposition, native browser XML, and evidence index retain their source boundaries.

## Executable evidence and hosted candidate

- Native production-browser proof at `d3af57fd1f156df2d6e1deec18200ae3b1eef119`: 34 cases, zero failures/errors/skips, both mounted and standalone entrypoints. `173-FINAL-BROWSER.xml` is the verbatim native report; `173-FINAL-EVIDENCE.json` identifies its digest and retained logs/captures.
- Core after the final core change: 661 tests and four properties, zero failures. Final Ops precommit: 247 tests and two doctests, zero failures. Contrast: zero AA failures; 35 AAA findings are advisory.
- Accepted candidate [run 37558615968](https://github.com/szTheory/scrypath/actions/runs/37558615968) completed successfully at the browser source above. All five required jobs, coverage and closeout attestation passed. The collector-validated `173-CANDIDATE-RECEIPT.json` preserves explicit repository/run/attempt identity, immutable artifact digests, verified archive bytes and member checksum.
- Final tracking/verification artifacts precede a separate exact-final-SHA hosted run. Its validated receipt is written outside the source checkout to `/private/tmp/scrypath-phase173-20261006-155750/final-receipt.json` after the run succeeds. Tracked files must remain unchanged afterward. This pre-attestation record does not claim that later run's outcome.

The candidate's advisory deep-quality lane reports newly published Cloak advisories in the unchanged Ops lock graph. `173-SECURITY.md` records their identities and scope. Phase completion does not grant a dependency exception, deployment risk acceptance, release approval, or evidence for a dependency remediation. No lockfile or dependency changed in this phase.

## Tracking warning reconciliation

`phase.complete 173` emitted four summary-path warning groups. They do not identify absent implementation or acceptance evidence:

| Summary | Reported reference | Resolution |
| --- | --- | --- |
| 173-01 | `layouts/root.html.heex`, `scripts/verify-phase173.sh` | App-relative paths exist at `scrypath_ops/lib/scrypath_ops_web/components/layouts/root.html.heex` and `examples/scrypath_ecommerce/scripts/verify-phase173.sh`. |
| 173-01 | Two `cd scrypath_ops && mix test ...` strings | Shell verification commands, not repository paths. |
| 173-01 | Eight historical shell capture paths under disposable `test-results/phase173-shell-9bd2141eba/` | All eight original image names are retained under `/private/tmp/scrypath-phase173-20261006-155750/evidence/173-01/shell/test-results/phase173-captures/`. The disposable in-checkout output was cleaned. |
| 173-02 | `mix test test/scrypath/operator/status_test.exs` | Shell verification command; its test file exists. |
| 173-03 | `mix test ...`, `assets/js/ops_hooks.js`, `after/gates/contrast-report.token.json` | Command; app-relative `scrypath_ops/assets/js/ops_hooks.js`; retained `/private/tmp/scrypath-phase173-20261006-155750/evidence/173-03/after/gates/contrast-report.token.json`. |
| 173-04 | Two `mix test ...` strings | Shell verification commands; both test files exist. |

The verified summaries remain unchanged so their fingerprint stays valid. Missing intentional RED history and original standalone before-images for 173-01 remain disclosed historical limits. The UI audit retains its original 17/24 score: two findings were fixed and the readable uneven open-disclosure polish item is explicitly nonblocking. No reviewer identity or approval is simulated.

## Preservation and next action

Execution and committed tracking live in `/private/tmp/scrypath-phase173-20261006-155750/execution`, branch `gsd/phase-173-shared-visual-foundation`. The original `/Users/jon/projects/scrypath` branch, HEAD, fifteen modified source/design files and preview `:4012` are preserved. The isolation baseline is `180992439563fe788c8794cbba1a9f6cedc081cc`; it carries the approved planning and existing local follow-ups. This work does not replay Phases 172 or 170 or extend their receipts. All task-owned executor and disposable fixture resources were cleaned.

Next: run `$gsd-discuss-phase 174` in the execution checkout. Recovery Entry and Diagnosis refines Control Room, Search health and Failed sync work within the delivered foundation. Automatic chaining is disabled. Context can be cleared after final closeout and PR handoff; STATE and the phase records preserve the working directory, branch, scope, decisions, evidence limits and exact next action.
