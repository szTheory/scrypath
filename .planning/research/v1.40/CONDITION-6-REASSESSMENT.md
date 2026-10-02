# Condition 6 reassessment research

**Project:** Scrypath; proposed v1.40 research only  
**Research cutoff:** 2026-09-26T18:25:17Z  
**Inspected HEAD:** `6e61380555361b6bb03c07a7f0f7c2a944ef960d`  
**Confidence:** MEDIUM; direct source observations are identified separately from interpretation and unknowns.  
**Disposition:** Research recommendation, not a new readiness decision or implementation authorization.

## Recommendation

Create a separate timestamped reassessment after its scope is approved. Preserve the entire historical Phase 164 assessment and its condition 6 `UNKNOWN`. The later v1.39 closeout receipt resolves the specific missing archived-milestone receipt; it does not attest subsequent commits, prove a new package release, erase accepted metadata debt, or make the whole readiness program pass.

The available evidence makes condition 6 a bounded reconciliation task. Reuse the successful hosted closeout, published-release monitor, and existing package proof. Record current release/support/planning facts, classify remaining debt, and address or explicitly disposition the concrete release-reference mismatch below. Do not declare current condition 6 PASS from the old receipt alone. Keep any prospective final-SHA closeout distinct from evidence reuse; the repository's required closeout protocol still applies to a new completed phase or milestone.

## Verified observations and boundaries

All observations below were collected read-only on 2026-09-26. No gates, tests, services, publish actions, or CI dispatches were run.

| Surface | Observed evidence | What it establishes / limit |
|---|---|---|
| Historical decision | [Readiness reference](../../reference/PRE-OPERATOR-UI-READINESS.md), Phase 164 dated assessment | Condition 6 was UNKNOWN because tracking and exact-final-SHA verification were outstanding at its cutoff. Conditions 3 and 6 made readiness NOT READY. Later evidence must not change this historical row. |
| Archived exact SHA | [Run 36257182675](https://github.com/szTheory/scrypath/actions/runs/36257182675) and GitHub run/jobs/artifacts API | `workflow_dispatch`, attempt 1, successful at `dc400b2b57aec0ca6b0ef16c9477d266fd41a433`; created 16:55:20Z, completed by 17:03:56Z. All five required jobs, coverage and closeout-attestation passed. This directly supports the archived commit. |
| Pushed milestone tag | `git ls-remote origin refs/tags/v1.39 'refs/tags/v1.39^{}'` | Annotated tag object `d7f9d9593e42fa3dc2a7537f8cef5bcbe1c9fd5c` peels to `dc400b2b57aec0ca6b0ef16c9477d266fd41a433`. The tag is a planning milestone tag, not the Hex release tag. |
| Current source | Local HEAD `6e61380555361b6bb03c07a7f0f7c2a944ef960d`; GitHub runs query by that head returned zero runs | HEAD is one commit after the archived closeout. Seven planning/strategy files changed. No current-HEAD hosted receipt was found in the API query. Do not label HEAD exact-SHA verified. |
| Main branch | Remote main `325197681c8dea96b8ddb5a46c62cb0d9f85a68f` | Remote main, research HEAD, milestone tag, and package release commit are four distinct source identities. Successful branch CI cannot silently substitute for another identity. |
| Published package | [Hex API](https://hex.pm/api/packages/scrypath), [GitHub release](https://github.com/szTheory/scrypath/releases/tag/scrypath-v0.3.13) | Hex reports latest and latest stable `0.3.13`, `has_docs: true`, inserted 2026-09-25T01:50:52.946366Z. GitHub release was published 01:49:22Z that day. The remote release tag resolves to `28d3877a05479f2cc104754fc24ab0c9d545c01b`. No v1.39 Hex publication is implied. |
| Publication and parity | [Phase 161 receipt](../../milestones/v1.38-phases/161-release-and-tidy-closeout/161-RELEASE-EVIDENCE.md); [today's scheduled monitor 36224458339](https://github.com/szTheory/scrypath/actions/runs/36224458339) | Phase 161 records successful publication, versioned HexDocs, fresh consumer compile and tarball/tag parity. Monitor created 2026-09-26T06:40:23Z at remote-main SHA passed both release-publication and release-parity steps. This is existing hosted proof, not a fresh local consumer or tarball check. |
| Support policy | [Support guide](../../../guides/support-and-compatibility.md), [mix.exs](../../../mix.exs), [CI workflow](../../../.github/workflows/ci.yml), [CONTRIBUTING](../../../CONTRIBUTING.md) | Elixir `~> 1.17`; explicit tuples 1.17.3/26.2.5, 1.18.4/27.3, 1.19.0/26.2.5, 1.19.0/28.1; Meilisearch v1.15; inline/manual/Oban; Ecto-first with Phoenix adoption proof. The inspected closeout passed all four compatibility jobs and Phoenix example advisory proof. No broader version or external-adopter certification follows. |
| Planning posture | [PROJECT](../../PROJECT.md), [STATE](../../STATE.md), archived audit and phase records | v1.39 is archived; no next milestone approved; readiness remains NOT READY. STATE's historical phase number and `state_head` do not override its explicit idle status or the observed Git HEAD. |
| Cleanup at research start | `git status --short` | No tracked changes observed. Untracked `.planning/research/.cache/`, `.planning/state.json`, and current `.planning/research/v1.40/` were visible; these must not be misclassified as abandoned Phase 164 output. Research creates the report and two cache digests; it starts no services or worktrees. |

### Exact-SHA artifact provenance

GitHub reported these artifacts as unexpired at inspection. Digests were read from hosted metadata; archive bytes were not downloaded or independently rehashed.

| Artifact | ID | SHA-256 digest | Expiry |
|---|---:|---|---|
| `closeout-attestation-dc400b2b57aec0ca6b0ef16c9477d266fd41a433` | 10911490745 | `b3f00c99504378ccc8454fa46a08d6392e14cba0a6d739c3cc709ec4e0b1d209` | 2026-10-03T16:59:14Z |
| `coverage-report-dc400b2b57aec0ca6b0ef16c9477d266fd41a433` | 10910932199 | `3ccf95e8ef62b11ceca12c41a5946606bf0ee5bc4d8d475921a21c7597a9a796` | 2026-10-03T16:56:08Z |

Provenance endpoints: [run](https://api.github.com/repos/szTheory/scrypath/actions/runs/36257182675), [jobs](https://api.github.com/repos/szTheory/scrypath/actions/runs/36257182675/jobs), [artifacts](https://api.github.com/repos/szTheory/scrypath/actions/runs/36257182675/artifacts). Preserve these identifiers, evidence times and digests in the eventual durable receipt. Artifact expiry does not negate the historical pass, but limits future inspection. If content-level attestation review is needed, retrieve existing artifacts before expiry instead of rerunning CI.

### Source freshness comparison

`git diff --name-status dc400b2 HEAD` identifies changes only in `.planning/MILESTONES.md`, `.planning/PROJECT.md`, `.planning/STATE.md`, `.planning/reference/MILESTONE-ARC.md`, `.planning/reference/PRE-OPERATOR-UI-READINESS.md`, `.planning/reference/milestone-candidates.md`, and `prompts/scrypath-milestone-ratchet-roadmap.txt`. The readiness reference changed its current posture and explanatory context; the historical assessment was preserved. No product, package, support or workflow invalidator appears in this interval.

Comparing release commit `28d3877` to current HEAD across `lib`, `test`, `examples`, `guides`, `.github`, `docs`, `mix.exs`, `mix.lock`, README, CONTRIBUTING and release manifest finds only `.github/pull_request_template.md`, `test/scrypath/docs_contract_test.exs`, and `test/scrypath/phase111_contract_test.exs`. This is a named-path drift inspection, not a new package rebuild or complete repository equivalence proof. Publication/parity truth remains supported by its own receipt and current monitor.

## Remaining debt and concrete inconsistency

| Item | Current source fact | Recommended treatment |
|---|---|---|
| Phase 164 summary cross-references | [164-01-SUMMARY](../../milestones/v1.39-phases/164-readiness-gate-and-reconciliation/164-01-SUMMARY.md) lacks `requirements-completed` for GATE-01/02/03. [Verification](../../milestones/v1.39-phases/164-readiness-gate-and-reconciliation/164-VERIFICATION.md) marks them satisfied; audit reports partial cross-references. | Keep accepted metadata debt explicit. If a scoped cleanup fixes it, refresh only affected verification metadata; do not silently rewrite the archived audit result or represent existing coverage as absent. |
| Phase 163 Nyquist | [163-VALIDATION](../../milestones/v1.39-phases/163-findings-and-bounded-follow-up/163-VALIDATION.md) uses legacy `status: complete`, with true flags and passed rows. | Record the accepted contract-normalization debt. Normalize only under approved maintenance scope with its evidence linked. |
| Phase 164 Nyquist | [164-VALIDATION](../../milestones/v1.39-phases/164-readiness-gate-and-reconciliation/164-VALIDATION.md) is a draft template with placeholder framework, commands, task rows and false flags. | This needs evidence mapping, not merely flipping a flag. Reconcile against the existing 36-fixture and 8/8 verification receipts; do not pretend the template already proves compliance. |
| Historical pending closeout wording | Archived summary, verification and [audit](../../milestones/v1.39-MILESTONE-AUDIT.md) predate final run 36257182675. | Retain their cutoff and link the later receipt from the new assessment. Treat this obligation as discharged for `dc400b2`, not for every later commit. |
| Current task completion | Current HEAD and research files have no matching final hosted receipt established here. | Show current task-owned verification separately. This research report is not a completed phase/milestone claim and does not dispatch CI. Follow CONTRIBUTING when closing any subsequently approved work. |
| Release-reference inconsistency | `docs/releasing.md` describes `vX.Y.Z`; `mix.exs` sets `@source_ref` to `v#{@version}` and uses it in a Changelog link. Actual remote package tag and parity task use `scrypath-v0.3.13`; `git ls-remote` found no `v0.3.13`. | Bounded observed inconsistency, not package publication failure. Verify the generated/public link and correct documentation/reference generation under an approved small task, or explicitly retain a reasoned limitation. Do not claim all release metadata agrees until dispositioned. No retagging or republishing is recommended. |

The accepted audit debt is already visible in PROJECT and STATE. Condition 6 prohibits hidden task-owned debt; it does not say every historical metadata item must be eliminated. **Inference:** transparent, specifically owned deferral can be compatible with a future PASS if the evidence and current-truth obligations are otherwise satisfied. Acceptance at v1.39 archive does not constitute new approval to fix it or a blanket waiver of future closeout. Record owner/responsibility and a concrete revisit trigger for each carried item; do not invent a human approval.

No full current container, temporary-directory or worktree inventory was taken in this research. Phase 164's recorded inventory says no phase-owned worktree/service or generated residue remained, while pre-existing services and a temporary build directory were preserved. A future reassessment must inspect its own owned resources before asserting current cleanup is complete; it need not audit or delete unrelated resources.

## Alternatives and tradeoffs

| Approach | Benefit | Cost / risk | Recommendation |
|---|---|---|---|
| Separate dated condition 6 reassessment using existing receipts and explicit debt table | Small, auditable, preserves chronology and source identity | Requires careful distinction between evidence date, assessment time and final task SHA | Preferred. Use a timestamp or unique assessment ID because both old and new reviews can occur on September 26. |
| Rewrite historical condition 6 as PASS | Superficially simpler | Erases the known evidence cutoff and changes a historical decision | Reject. |
| Rerun all package/service/compatibility proof now | Fresh executions | Duplicates current evidence; cannot fix metadata truth; consumes service/browser time | Reject absent a named invalidator. |
| Close all historical metadata and documentation debt first | Cleaner future maintenance | Expands scope; modifying archived inputs can require targeted verification refresh | Optional bounded cleanup, separately authorized and justified. Never make an unapproved implementation implicit in this research. |

Prefer a new assessment artifact linked from the canonical current posture over adding an unplanned second assessment table to the old Phase 164 checker input. That checker deliberately validates a unique structural record. If supporting a new multi-assessment format becomes approved scope, specify the format and update only the focused structural contract. Structural PASS still cannot certify package truth, semantic judgment or readiness.

## Minimal acceptance criteria for approved follow-up

1. The historical 2026-09-26 assessment, condition 6 UNKNOWN and overall NOT READY remain intact. The new record has its own ID, UTC cutoff, source HEAD and evidence dates.
2. The record binds archived v1.39, remote tag, hosted run/attempt, required jobs, coverage/attestation artifact IDs and digests to `dc400b2`; later commits are explicitly outside that receipt.
3. Release assertions identify Hex 0.3.13, its actual release tag and publication/parity receipt. Current support claims cite the guide and tested tuples without broadening Ecto/Phoenix/backend support.
4. Every named source invalidator is compared with current inputs. The observed tag-reference mismatch receives an explicit bounded disposition rather than an unqualified agreement claim.
5. A current ownership inventory covers branch/worktree, generated output, temporary files, services, verification and unrelated state. The two Nyquist items and three summary cross-references are fixed with evidence or remain clearly carried accepted debt with responsibility and revisit trigger.
6. Any current-task required closeout remains visibly pending until the existing exact-final-SHA protocol succeeds. Do not edit tracked files after that success; the final hosted receipt can be authoritative externally, avoiding an endless tracked receipt-update cycle.
7. Condition 6 gets a reasoned PASS/FAIL/UNKNOWN independent of condition 3. Overall readiness cannot pass unless all six conditions independently pass and no gate-rank finding remains. No operator UI implementation or simulated approval follows automatically.

## CI and runtime economics

This research used source reads and existing hosted metadata only. It added no recurring CI lane or dependency. The observed v1.39 run took approximately 8m36s wall-clock; required ecommerce-mounted ran about 3m47s, closeout-attestation completed about 3m57s after run creation, and advisory ecommerce E2E ran about 8m32s. These are one-run observations, not an average, SLA, flake rate or billing measurement.

Keep future deterministic record checks in the smallest focused layer. Reuse existing published-release monitoring and package parity. Keep compatibility, deep quality, Phoenix and full browser lanes in their existing advisory posture. Do not add an expensive required service lane for bookkeeping. A new phase/milestone still requires its normal final exact-SHA closeout; that verifies its final artifact, while the old run remains source evidence. The archived audit mentions an earlier service-readiness failure followed by a successful retry; one successful later run does not establish long-term flake-free stability.

## Provenance, confidence and unknowns

The research-plan seam selected `websearch`; `classify-confidence --provider websearch --verified` returned **MEDIUM**. External methodological claims and resulting recommendations use that tier. Source facts are expressly labeled observations with exact records; no source was promoted into a broader assurance claim. The generic `github` and `webfetch` labels returned LOW in the classifier, so they were not used to claim an unsupported high confidence tier. The two official-documentation digests were cached through the research-store seam.

Official documentation accessed 2026-09-26:

- [GitHub Actions artifacts API](https://docs.github.com/en/rest/actions/artifacts): run/SHA association, artifact IDs, digests and expiry metadata support the provenance fields used here.
- [GitHub workflow artifacts](https://docs.github.com/en/actions/concepts/workflows-and-actions/workflow-artifacts): artifact evidence is a distinct workflow output with retention limits.
- [Hex publishing](https://hex.pm/docs/publish): package and documentation publication are distinct operations; a repository milestone tag does not prove either.

Project sources additionally consulted: Phase 164 plan/summary/verification and archived audit; Phase 161 release evidence; current release, recovery, parity-monitor and CI workflow sources; CONTRIBUTING; `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md`. Local prompt advice was treated as context, not current product evidence. The tool runtime exposed no dedicated Read/Write tools; files were read through the available command tool and this report written with the file-edit tool. No implementation files or historical assessments were edited.

**Unknowns retained:** current-HEAD exact-SHA closeout; current generated/public changelog-link behavior; future artifact availability after expiry; full current owned-resource inventory; owner choice about metadata cleanup versus explicit carry-forward. Existing monitor success supports its recorded time and scope, not perpetual availability. These are precise boundaries for the approved follow-up, not reasons to repeat every product gate.
