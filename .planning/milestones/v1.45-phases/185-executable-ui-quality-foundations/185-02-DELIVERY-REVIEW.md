# Plan 02 delivery review

Status: resolved after explicit maintainer approval. PR #124 squash-merged to main as `c1be269ec202deed8602c74683c1b9ce5e42eaa9`; exact inventory parity and production enforcement passed, then GSD integrated and removed the clean Plan 02 worktree. Root build/Node/canonical checks passed. Plans 01/02/04 are integrated; Phase 185 remains incomplete. The decision and pre-approval evidence below are historical. [Merge/integration receipt](185-02-MERGE-INTEGRATION.json) records the resolution.

## Decision and consequence

Recommend squash-merging only [bootstrap PR #124](https://github.com/szTheory/scrypath/pull/124) before proceeding with implementation and cleanup. It adds one data file and changes no runtime, dependency, workflow or UI source. It does not accept dependency advisories or clear the retained-preview stop.

The repository requires squash merges. The policy requires the first committed ledger to exactly match the immutable bootstrap and later ledgers to shrink. A final squash containing both introduction and a valid cleanup makes its first ledger smaller than the bootstrap and therefore fails. A separate inventory introduction preserves both rules. The actual production checker rejects the combined synthetic squash and accepts the separate-introduction equivalent; [machine receipts](185-02-DELIVERY-PROOF.json) preserve both disposable real-Git runs. These are delivery-shape proofs, not hosted source acceptance.

The final bootstrap inventory contains 45 occurrences across 45 identities. It was independently scanned from immutable commit `767f368473f17fba43d7be4675c53ab65a87530c`; fresh canonical main `6b65f8a019ab467c11357ab59942ce67feb62735` has exactly the same multiset. The proposed PR head is `d31e4fc422edb8ac3413556bb7c65fe8b6b01fda` and changes only `scripts/ci/ui-literal-baseline.json`.

## Parent review repairs

- Inline-style identities originally retained only the word `style`, allowing a same-count source-value swap. They now retain normalized source tokens with meaningful quoted contents. A real failing regression preceded the repair.
- The original inventory omitted the generator SVG's eight literal fill colors and the topbar configuration's one JavaScript styling hex. Presentation attributes, arbitrary color utilities and bounded static JavaScript styling contexts now include these values while excluding prose, selectors and URL fragments.
- Commented or quoted `@theme` text could falsely authorize ordinary CSS. Authorities now require actual top-level blocks in the two named stylesheets; named daisyUI authority requires a real name declaration. A real failing regression preceded these repairs.
- Static JavaScript class readers preserve multiple arguments and comment-like text inside strings, distinguish enclosing named functions, and avoid double-counting overlapping JSX/style readers. Root markup siblings receive distinct structural positions.
- The malicious-ledger witness now invokes the actual `mix verify.repository_contracts` public command in a disposable repository, with only its recursive negative child excluded.

These repairs reconcile the owned unpublished introduction with the final immutable-source scan. They do not enlarge an inventory already merged to main. Original private histories remain reachable through recovery refs.

## Verification and limits

The final Node suite passed 14 tests with zero failures (`/private/tmp/phase185-02-final-node.log`). Canonical `mix verify.repository_contracts` passed 131 tests with zero failures, including actual negative public-command subprocess witnesses (`/private/tmp/phase185-02-final-canonical.log`). Production CLI passed on repaired source `f62e8a9090417758a2608e436574fdb90eb61db7`, with exact 45-occurrence scan/history equality against fresh main (`/private/tmp/phase185-02-final-policy.log`). Summary-only tracking commits preserve that implementation tree; no hosted scanner acceptance is inferred.

[All five required PR jobs passed on the proposed head](https://github.com/szTheory/scrypath/actions/runs/41213404257): core, package, backend, repository-contracts and ecommerce-mounted. Website, four compatibility tuples and Phoenix example also passed. Full E2E, coverage and Ops UI were selector-skipped as expected for this data-only PR; no executed coverage is claimed for those jobs. The advisory deep-quality job failed the dependency audit before its remaining checks. Bandit, Phoenix.HTML, Cloak and Cloak Ecto findings occur in unchanged lockfiles and remain unaccepted. Details and exact-source check identities are in [the check receipt](185-02-BOOTSTRAP-CHECKS.json); the raw audit is `/private/tmp/phase185-bootstrap-final-advisory-audit.log`. This is not a claim that every CI job passed, nor permission to release or run the stale retained preview.

The scanner is a bounded static reader, not a general Elixir/JavaScript/CSS evaluator. It evaluates authored source shapes and never executes bootstrap code. Unknown runtime-generated styles are not claimed to be resolved. No hosted implementation acceptance, independent visual review, phase completion or dependency-risk acceptance is claimed.

The executor's initial Task 1 failure was an ordering assertion against an already-present uncommitted implementation, not valid behavioral RED evidence. Do not use it as accepted TDD proof. Its Task 2 historical failure lacks a machine RED receipt. Parent review's actual inline-style and source-context failures are preserved in the private worktree as `185-02-inline-style-RED.json` and `185-02-source-context-RED.json`. The plan's historical test-first discipline is therefore limited, even though current behavioral verification is required to pass.

## Retained work and resume

- Root: `/Users/jon/projects/scrypath`, branch `planning/v1.45-foundation-ci`; unrelated `.planning/config.json` remains dirty and excluded from owned commits.
- Plan 02: `/Users/jon/projects/scrypath/.claude/worktrees/agent-p185-02-13xypspp`, branch `worktree-agent-p185-02-13xypspp`, fork base `0d39fa8b40e3a666d36256ac9cf95b6313f9e732`; repaired source head `f62e8a9090417758a2608e436574fdb90eb61db7`.
- GSD isolation manifest: `/private/tmp/phase185-wave2-13xypspp/worktrees.json`. Executor process completed, but parent has not merged or cleaned the worktree.
- Recovery refs: `recovery/185-02-before-parent-review-20261031`, `recovery/185-02-inline-fix-before-ledger-20261031`, `recovery/185-02-before-final-inventory-20261031`.
- Do not redispatch Plan 02 or treat its private summary as integrated completion. After explicit merge authorization, merge only the data PR, fetch and verify actual main's first introduction and file parity, reconcile the owned worktree, integrate it through the GSD adapter, then continue Plans 03/05 and later waves.
- Preserve the stale retained-preview safety stop and data. Any later disposable browser evidence must follow the phase's capture guards; no retained preview repair was authorized by this checkpoint.
