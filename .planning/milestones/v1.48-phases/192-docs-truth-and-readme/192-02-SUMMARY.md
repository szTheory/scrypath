---
phase: 192-docs-truth-and-readme
plan: 02
subsystem: testing
tags: [exunit, contract-test, docs-truth, owner-map, pin-inventory]

requires:
  - phase: 192-docs-truth-and-readme
    provides: "Plan 01 ShippedDocs scanner (scan/2, units/1, unit_qualified?/1, mentions/2, allowlist/0, exempt/0, violations/0) and the qualified shipped docs"
provides:
  - "Real-file TRUTH-01 invariant: no Hex-shipped file names a repo-only task outside a qualified unit (test fails with path:line and the fix)"
  - "PROJECT.md Canonical Adopter Contract rewritten as one bullet, with an agreement test that fails if it disagrees with the invariant's constants or drops the qualifier"
  - "Table B pins rewritten stronger (mention exists and is qualified), README task demands retired, CONTRIBUTING halves untouched"
  - "Drift signals, backfill-versus-reindex, reconcile-does-not-heal, rebuild completion, managed reindex call and result keys now live in guides/drift-recovery.md; search call and result keys in guides/golden-path.md; every one pinned"
  - "192-PIN-INVENTORY.md Removed-claim inventory (39 rows) and a filled fate log"
  - ".planning/reference/CLAIM-OWNER-MAP.md (31 claims, one owner each) and Scrypath.ReadmeContractTest shape test with machine-checked Pinned-by tokens"
affects: [192-03, 192-04, 193-guards, 194-website-decision]

actuals:
  tokens: 13614
  tasks: 3
  commits: 3
plan_head_before: d1aa79978252b9805a58a25b8cb15f9738b19a1e
plan_head_after: dd8231fb59b1a17fc62ba513b849ddbce9b95ea3

tech-stack:
  added: []
  patterns:
    - "Contract text and enforcing check change in one commit, with an agreement test that reads the contract section"
    - "Owner map as a parsed markdown table: whole-cell single owner, Pinned-by entries checked against the named file"
    - "Pin rewrites keep the old claim and add a stronger qualified-mention assertion rather than deleting"

key-files:
  created:
    - .planning/reference/CLAIM-OWNER-MAP.md
    - test/scrypath/readme_contract_test.exs
  modified:
    - .planning/PROJECT.md
    - test/release/shipped_docs_contract_test.exs
    - test/scrypath/readiness_contract_test.exs
    - test/scrypath/phase98_contract_test.exs
    - test/scrypath/phase99_contract_test.exs
    - test/scrypath/docs_contract_test.exs
    - guides/drift-recovery.md
    - guides/golden-path.md
    - .planning/phases/192-docs-truth-and-readme/192-PIN-INVENTORY.md

key-decisions:
  - "The three C2 README pin blocks now read their owners (drift guide, concepts guide, ARCHITECTURE, sync guide); no README token remains in them, so the Plan 04 trim cannot turn them red"
  - "Owner map is checked by tests: one owner per required claim, whole-cell owner form, guide slugs must be docs extras, doc paths must exist, every Pinned-by token must be a substring of its named file"
  - "Website column says 'restates it (Phase 194 decides)' only where a website page plainly exists for the claim (home, evaluate, operators); everything else is 'links to owner'"

patterns-established:
  - "assert_qualified_adopter_mention/2: a doc must name the adopter proof task in at least one unit and every such unit must pass unit_qualified?/1"
  - "Mutation check by copy-aside with cmp restore, run before commit, recorded with the observed failure line"

requirements-completed: [TRUTH-01, TRUTH-02, README-03]

coverage:
  - id: D1
    description: "The shipped-docs invariant is enforced on the real shipped set; an unqualified repo-only task mention fails with path:line and a fix hint"
    requirement: TRUTH-01
    verification:
      - kind: unit
        ref: "test/release/shipped_docs_contract_test.exs#no Hex-shipped file names a repo-only task outside a qualified block"
        status: pass
      - kind: unit
        ref: "test/release/shipped_docs_contract_test.exs#owner docs name the adopter proof spine only with the source-checkout qualifier"
        status: pass
    human_judgment: false
  - id: D2
    description: "The PROJECT.md Canonical Adopter Contract states the same rule: one bullet naming the allowlist, both exemptions and the enforcing test, with the stale 0.3.17 claim gone; the agreement test fails if it drifts"
    requirement: TRUTH-02
    verification:
      - kind: unit
        ref: "test/release/shipped_docs_contract_test.exs#the Canonical Adopter Contract states the same rule the invariant enforces"
        status: pass
    human_judgment: false
  - id: D3
    description: "Every Table B pin has a recorded fate; guide pins on verify.adopter assert the mention exists and is qualified; README task demands retired in favor of the invariant; CONTRIBUTING halves unchanged"
    requirement: TRUTH-01
    verification:
      - kind: integration
        ref: "doc-pin set of 14 files plus phase108, phase111, readme and verify_adopter tests: 335 tests, 0 failures"
        status: pass
    human_judgment: false
  - id: D4
    description: "Every claim the README trim removes has an owner that carries it at this head, pinned; unowned claims moved into guides/drift-recovery.md and guides/golden-path.md with their pins"
    requirement: README-03
    verification:
      - kind: unit
        ref: "test/scrypath/docs_contract_test.exs#owners carry the README search, reindex and hydration claims the trim removes"
        status: pass
      - kind: unit
        ref: "test/scrypath/docs_contract_test.exs#owner guides preserve the operator contract for backfill and reindex"
        status: pass
    human_judgment: false
  - id: D5
    description: "CLAIM-OWNER-MAP.md names exactly one owning surface for each required claim, records the README budget as chosen numbers, and every Pinned-by token is present in its named file"
    requirement: README-03
    verification:
      - kind: unit
        ref: "test/scrypath/readme_contract_test.exs#the claim owner map names exactly one owning surface for each required claim"
        status: pass
      - kind: unit
        ref: "test/scrypath/readme_contract_test.exs#every owner-map Pinned-by token is present in its named file"
        status: pass
    human_judgment: false

duration: 19min
completed: 2026-11-21
status: complete
---

# Phase 192 Plan 02: Invariant switch-on, contract rewrite, claim moves and owner map Summary

**The shipped-docs invariant now runs on the real Hex-shipped files in the same commit that rewrites the PROJECT.md Canonical Adopter Contract and the Table B pins; the README claims the trim will remove already live, pinned, in their owner guides; and a 31-claim owner map is checked by tests that read each owner's file.**

## Performance

- **Duration:** about 19 min (the pre-push mirror took about 5 of them)
- **Started:** 2026-11-21T06:06:44Z
- **Completed:** 2026-11-21T06:25:19Z
- **Tasks:** 3 (Task 1 was a tracer; its end-to-end verify re-ran green before expansion)
- **Files modified:** 11 (2 created, 9 edited)

## Accomplishments

- **TRUTH-01 and TRUTH-02 in one commit.** `shipped_docs_contract_test.exs` gained the real-file zero assertion, an agreement test that reads the `## Canonical Adopter Contract` section (it must name every `ShippedDocs.allowlist/0` and `exempt/0` path and the enforcing test, mention `verify.adopter` only in qualified units, and not carry the old 0.3.17 claim), and an owner-docs test for the support guide, intake guide and `docs/operator-support.md`. `.planning/PROJECT.md` now has one bullet replacing the proof-spine and stale published-0.3.17 bullets.
- **Table B pins rewritten, none weakened.** B1, B5, B7, B8 now call `assert_qualified_adopter_mention/2` (mention exists and every mention unit is qualified). B2, B4 and the README half of B6 are removed because the README is no longer a home for the proof spine and the invariant forbids an unqualified README mention; the CONTRIBUTING halves are byte-identical. The emptied README block and `@readme` attribute in phase98 are gone.
- **Claims moved to owners.** `guides/drift-recovery.md` gained `## Detect drift, then choose backfill or reindex` with a `### Managed reindex result` subsection (README text copied: drift signals, rebuild-completion sentence, backfill-versus-reindex, reconcile does not heal, the reindex call with seven result keys, the `cutover?: false` and `result.omitted` sentences). `guides/golden-path.md` gained the search call and its four result keys. The three C2 blocks in `docs_contract_test.exs` now read their owners, and a new test pins every moved claim plus the ARCHITECTURE hydration claim.
- **Removed-claim inventory** (39 rows) written before any move, each row with owner surface and line, owner-map row id and action (owned in place, moved in Task 2, or retired).
- **Owner map** with 31 rows (30 owned, 1 retired: `version-source`), the README budget as chosen numbers (cap 800, range 600 to 800, floor 400 as a stub guard, 60 fenced lines, 3 onward links), and a Not proven section. `Scrypath.ReadmeContractTest` proves one owner per required claim and that every Pinned-by token is a substring of its named file.

## Task Commits

1. **Task 1: Tracer, contract text, enforcing tests and pin rewrites** - `4b45ccbc` (test)
2. **Task 2: Removed-claim inventory and claim moves with pins** - `10ac6a70` (docs)
3. **Task 3: Claim owner map and shape test** - `dd8231fb` (docs)

**Plan metadata:** committed with this SUMMARY (docs).

Tracer gate: auto mode is off and the task's `<verify>` is automated-only, so both Task 1 commands re-ran on the committed head and passed (26 tests, 0 failures) before Tasks 2 and 3.

## Files Created/Modified

- `test/release/shipped_docs_contract_test.exs` - real-file invariant, contract agreement, owner-docs tests (19 tests)
- `.planning/PROJECT.md` - one Canonical Adopter Contract bullet replaces two
- `test/scrypath/readiness_contract_test.exs`, `phase98_contract_test.exs`, `phase99_contract_test.exs` - Table B rewrites
- `guides/drift-recovery.md`, `guides/golden-path.md` - moved claims
- `test/scrypath/docs_contract_test.exs` - C2 blocks re-pointed to owners; new owner test
- `.planning/reference/CLAIM-OWNER-MAP.md`, `test/scrypath/readme_contract_test.exs` - owner map and its shape test
- `192-PIN-INVENTORY.md` - Removed-claim inventory, Table B and C2 fate rows with commit hashes

## Decisions Made

- C2 blocks keep their phrase in the test names ("operator contract for backfill and reindex", "operator recovery contract report-first", "drift detection and recovery guidance explicit") so the plan's gate greps still find them.
- The retired `version-source` claim (README:116) is recorded in both the inventory and the owner map with a reason.
- The owner map's Pinned-by tokens for `README.md` are limited to text Plan 04 keeps, so the shape test is the executable proof that the trim kept them.

## Mutation checks (each run before its commit, restored with cp and cmp, diff stat matched)

- Task 1, `guides/outside-adopter-intake.md` line 32 qualifier removed: failure `guides/outside-adopter-intake.md:32 verify.adopter` (invariant) and `guides/outside-adopter-intake.md:32 names mix verify.adopter without saying it runs from a source checkout and is not in the Hex package` (owner-docs test); 2 failures; rerun green.
- Task 1, `docs/operator-support.md` line 7 qualifier moved to a sibling sentence: failure `docs/operator-support.md:7 verify.adopter` and the owner-docs message at `:7`; 2 failures; rerun green.
- Task 1 (extra, not in the plan), `CHANGELOG.md` removed from the PROJECT.md contract bullet: failure `the contract does not name CHANGELOG.md, which the invariant allowlists or exempts`; restored.
- Task 2, `result.settings_applied` line deleted from the drift guide fence: `owners carry the README search, reindex and hydration claims the trim removes` failed with `expected docs to include "result.settings_applied"`; restored.
- Task 3 (a) `support-policy` row deleted: `required claim support-policy must appear exactly once in the owner map`.
- Task 3 (b) `proof-spine` Owner cell set to two owners: `claim proof-spine: owner cell ... must name exactly one owner` plus `no Pinned-by entry names the owner's own file`.
- Task 3 (c) CONTRIBUTING.md entry added to `operator-ui-status`: `claim operator-ui-status: CONTRIBUTING.md no longer contains "scrypath_ops/README.md"`.
- The unmutated owner map passes (2 tests, 0 failures) before staging.

## Deviations from Plan

None needed under Rules 1 to 4. These are discretion calls and small corrections, recorded because later plans read these files:

**1. [Plan discretion, stronger pin] `--live` substring pins kept in B5, B7, B8**
- The plan said to replace the task tokens with the qualified-mention assertion. Only the bare `mix verify.adopter` substring was replaced; `mix verify.adopter --live` stays asserted on the support and intake guides, because dropping it would let the live half of the fast/live split disappear unnoticed. Recorded in the inventory header.

**2. [Plan discretion] `assert_qualified_adopter_mention/2` is a private helper in each of the three pin files**
- The plan's file list has no change to `test/support/release/shipped_docs.ex`, so the helper (about 10 lines) is repeated rather than added to the support module. It uses the same `units/1`, `mentions/2` and `unit_qualified?/1`.

**3. [Plan discretion] README:152 "Use managed reindex when ..." also copied into the drift guide**
- Verbatim README text, so no new claim. A section titled "choose backfill or reindex" with only the backfill half would promise a choice it did not show. The pin for it stays on the concepts guide as planned and is also asserted on the drift guide.

**4. [Rule 1 avoidance] `alias MyApp.Repo` first line in the two new fences**
- The README fences read `repo: Repo`; an IEx session has no such alias, so the copied call would fail. The golden-path fence also drops `preload: [:author]` and the trailing comma, as the plan specified.

**5. [Plan discretion] Block 1 of the C2 pins re-asserts `cutover?: false` (ARCHITECTURE) and the sync-guide token**
- The plan left those to existing pins. Repeating them lets the renamed test still name the whole contract; the existing pins stay.

**6. [Correction] Line numbers**
- All plan citations in the pin files and README matched HEAD. Golden-path line numbers after `:126` shifted by 22 once the search fence landed; the inventory cites the post-edit numbers.

**Total deviations:** 0 auto-fixed; 6 discretion or correction notes. **Impact on plan:** none on scope.

## Issues Encountered

- `scripts/ci/pre_push.sh` took about 5 minutes (the UI token node tests dominated); it was moved to the background and finished with exit 0.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None. No placeholder, empty-value or TODO text was added.

## Threat Flags

None. The plan touches tests, planning notes and static docs only. T-192-04 (contract and check drift) is mitigated by the agreement test, T-192-05 (pin weakened) by the stronger rewrites plus the mutation checks, T-192-16 (claim lost in the trim) by the inventory, the moved claims and the Pinned-by test, T-192-06 (vacuous parse) by the non-empty section, at-least-30-rows and per-token file reads.

## What this does not prove

- That the owner assignments are the right ones, or that the website restatements marked in the owner map agree with their owners (judged from page headings only).
- That PROJECT.md prose reads well, or that each qualifier sentence is itself accurate.
- That the inventory is complete beyond what the greps found; it is reproducible from the commands in its header.
- That hosted lanes pass. Run locally: the 14-file doc-pin set plus phase108, phase111, readme and verify_adopter tests (335 tests, 0 failures), `mix docs --warnings-as-errors` (exit 0), `mix credo --strict` on the touched test files, and `scripts/ci/pre_push.sh` (11 passed, 0 skipped, exit 0). Not run: `core`, `package`, `repository-contracts`, `backend`, `ops-ui`, `ecommerce-mounted` (the orchestrator runs the full lane mirrors at the end of Plan 04).

## Next Phase Readiness

Ready for 192-03 and 192-04. Notes for the orchestrator:

- The README is untouched. Plan 04 must keep these README tokens, which the owner-map shape test now reads: `Scrypath, the Ecto-native search indexing library`, `sztheory.github.io/scrypath`, `Scrypath is a good fit when you want`, `Scrypath is not trying to be`, `Meilisearch-first in v1`, `not a promised public abstraction`, `{:scrypath, "~> 0.3"}`, `Scrypath owns its internal transport dependency`, `Add Oban only when you choose`, `semantic versioning`, `operator UI`, `not part of the Hex package`, `Quick Path`, `accepted work may not yet be visible in search`, `release-backed guidance`, `concrete production bug`. A trim that drops one turns the default test run red.
- Plan 04 still owns the README halves of C1, C2.4, C2.5 to C2.8 and B3, B9, B10. The drift guide now carries `result.omitted` for the C2.7 re-point.
- Plan 03 owns B13 and the golden-path config snippet fix. The invariant is on: any new shipped-doc mention of a repo-only task must be qualified in the same sentence or list item, and the agreement test reads PROJECT.md.
- The new drift-guide bullet keeps the word "hydrated" because a pin reads it; Phase 193's forbidden-phrase table may want it reworded with the pin (recorded in the inventory).
- The fate log has commit hashes for Tasks 1 and 2 rows; the owner-map row points at this summary for its hash (`dd8231fb`).

## Self-Check: PASSED

- Created files present: `.planning/reference/CLAIM-OWNER-MAP.md`, `test/scrypath/readme_contract_test.exs`; edited files present.
- Commits reachable from HEAD: `4b45ccbc`, `10ac6a70`, `dd8231fb`; measured count `git rev-list --count d1aa7997..HEAD` is 3.
- `.planning/config.json` and `.planning/state.json` were never staged; STATE.md and ROADMAP.md were not touched.

---
*Phase: 192-docs-truth-and-readme*
*Completed: 2026-11-21*
