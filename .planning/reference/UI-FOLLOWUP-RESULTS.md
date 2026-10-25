# Scrypath UI follow-up — 2026-10-15

Implementation on `fix/ui-feedback-baseline` follows the maintainer's 24-item second review round. The earlier feedback-only pause is superseded by their request for another meaningful implementation pass. This extends the delivered PR #105 baseline; it does not reopen numbered Phases 173–177 or refresh the brand.

## Resulting experience

| Area | Delivered behavior |
| --- | --- |
| Shared controls | Timestamp and payload copying report actual browser outcomes in the shared toast overlay, with persistent selectable fallback on denial. Page geometry and focus stay stable. The native Time select inherits shared chevron spacing. |
| Health | Exact Schema module and Meilisearch index identities align visually. The schema count names the configured sync method, rather than claiming observation counts describe setup. Nonzero retries/failures carry restrained semantic emphasis; source-specific task/job truth remains separate. The scoped action is quiet and attached to its schema header. |
| Search | Flat mode/schema/query/limit form, query privacy guidance beside the input, accurate combined result-limit units and no initial status clutter. Returned descriptions and typed fields lead; full exact Elixir data stays inspectable/copyable. Combined order shows positions, titles, sources and IDs without repeating whole payloads. |
| Save and reuse | Save search appears before hits, focuses its form and explains server-side Saved searches. Only submitted inputs are saved. A draft mismatch makes last-run context visible; matching controls keep it quiet. Successful saving offers a direct list handoff. JSON indentation and full copying are verified. |
| Help | A quiet navigation footer opens task-focused native Help with mount-aware return links. Optional developer references remain separate. Limits, ranking, sync modes, timestamps and server-file persistence are explained using actual behavior. |
| Demonstration breadth | Labeled snapshots cover processing, backend failure, retry and completion; a typed-hit fixture covers custom IDs, false, zero, null and nested values. The opt-in `indexing_failure` seed produces a real Meilisearch rejection in a disposable stack. |

## Verification

- Ops `mix precommit`: **313 tests + 2 doctests, zero failures**, after final product edits. `/tmp/scrypath-followup-precommit-final.log`.
- Demo `mix test` with isolated `MIX_TEST_PARTITION=_ui_followup`: **38 tests, zero failures**. `/tmp/scrypath-followup-demo-unit-isolated.log`.
- Browser inventory: **all 175 distinct cases covered**, with 164 passes in the full run, ten of its eleven failures cleared in the focused 21-case run, and the remaining save-collision case green in the final two-case run. The 21-case run also repeats all three contrast scenarios and seven follow-up proofs; its other failure was a new fixture-label typo, corrected in the final two-case run. Logs: `/tmp/scrypath-followup-browser-final.log`, `/tmp/scrypath-followup-browser-recheck.log`, `/tmp/scrypath-followup-final-two.log`. No retries or weakened recovery guards.
- Clipboard proofs retain exact source precision, rejection/manual fallback, repeated actions, keyboard/touch and stale-promise guards. New geometry checks cover mounted/standalone at desktop and mobile. Readable-result proofs retain arbitrary returned values and complete raw content beyond inspect defaults.
- Review-tool safeguards: **7 tests, zero failures**. `/tmp/scrypath-followup-review-selftest.log`.
- Real failure: owned task **691**, `ecommerce__product`, `documentAdditionOrUpdate`, `failed`, error **`invalid_document_id`**, received 1/indexed 0. Health displayed one failed Meilisearch task separately from background jobs; no completion or freshness was inferred. `/tmp/scrypath-followup-real-failure.log` and `ui-review-artifacts/followup-journeys/real-meilisearch-failure.png`.

The first broad run exposed a test-folder mismatch and obsolete assertions for removed UI. Host file-based browser fixtures now accept `PLAYBOOK_WORKSPACE_DIR`, matching the disposable server folder. The demo suite uses its own database partition. An unchanged controller test still expected fabricated global swap fields removed by the previous baseline; it now checks the real failed-work contract and explicitly refuses those fields. These are test corrections, not new endpoint behavior.

## Rendered review

The full eight-surface entry matrix and separate populated query/raw/draft/save/toast screenshots were reviewed in-thread across light/dark/system-dark and desktop/tablet/mobile. Review confirms the established brand, distinct task hierarchy, meaningful source/status distinctions, native controls, readable typed results and useful Help. This is a distinct in-thread critique, not an independent reviewer identity, adopter study or approved pixel golden.

Unreported problems caught and corrected include the hardcoded Oban heading in manual mode, readable-field template whitespace, an older dark-only fill overriding flat result rows, a lost filename-help association, mounted Help-link construction before mount resolution, and duplicate backend-failure narration. Mechanical checks complement this critique; screenshot counts alone do not establish visual quality.

Final capture: `examples/scrypath_ecommerce/ui-review-artifacts/2026-10-15T13-22-55-099Z`, **72/72 captures, zero mechanical findings**, with all nine theme/width views per surface reviewed in contact sheets and representative full-page/interaction images. Source fingerprint: `b46d12d5fa55d822eb59b2c023b1cc5fcb73a26bb570c40ba462bdb331803bee`. `review.json` records surface/dimension rationale and the scoped journey receipts; its checker validates completeness/provenance rather than taste. Populated screenshots live alongside it in `ui-review-artifacts/followup-journeys/`. Earlier partial/intermediate captures remain separate, never silently promoted.

## Boundaries preserved

No new dependency, public library API, Playbook format, result-limit behavior, pagination controls, per-user storage model or association hydration. Typed display uses modest heuristics over returned values; nested readable views are bounded and complete raw data remains available. The interface reports the shared host-configured sync mode, not undiscovered per-call overrides. Fixed fixture snapshots are never live recovery proof.

The retained `scrypath_ecommerce-web-1` preview remains on port 4002 with seeding disabled. Its intentional incident/index-settings state is preserved, including unavailable storefront facets; tests use the separate `scrypath_ui_followup` project on 4013/4014. User-created `priv/playbooks/my-search.json` remains untracked and unchanged, SHA256 `3c8de6b45b9b3bc6f5daff18ce71da1ee817b5270ddc57a8c064f59a1a42c0f7`.


## Delivery and remaining advisory

[PR #106](https://github.com/szTheory/scrypath/pull/106) was marked ready and squash merged on **2026-10-15 at 13:35:07 UTC**, under the maintainer's standing approval. Merged main: `29c287c8e732cddd13e435ccf601e06a39a65837`. Required `core`, `package`, `repository-contracts`, `backend`, and `ecommerce-mounted`, plus path-scoped Ops, all passed on PR source `54e4d334b9c13ef0231d460d7b3c188d549f93b8`: [CI run 38743007949](https://github.com/szTheory/scrypath/actions/runs/38743007949). Compatibility and Phoenix example checks also passed. No claim that every advisory lane is green.

The unsuppressed dependency-audit advisory remains red for unchanged locked Bandit 1.12.5, Cloak Ecto 1.3.0, Decimal 3.1.1 and Cloak 1.1.4. The Bandit finding is newly surfaced in this run. These are tracked in the dependency follow-up (since retired; the remaining Cloak items live under Known open items in [the rolling roadmap](ROLLING-ROADMAP.md)), without silently upgrading dependencies or accepting/suppressing their risks as part of this UI pass.

The canonical preview checkout was merged with current `origin/main` and has **zero product/source differences** from merged main. The final rendered-review source binding still passes. Only local closeout bookkeeping follows the delivered source; it does not contain unmerged product changes. The unrelated dirty root checkout was preserved; its preview-pointer metadata alone was refreshed.

All containers, network and seven named volumes of the owned `scrypath_ui_followup` project were removed after verification. The retained port-4002 preview remains healthy; the maintainer's saved file hash is unchanged. No task-owned UI implementation remains pending.
