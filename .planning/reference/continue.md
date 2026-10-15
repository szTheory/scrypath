# Continue — Scrypath UI iteration 3

## Last action

The maintainer finished the 2026-10-15 review and requested a compaction-safe handoff. All 25 new feedback entries are recorded; **none of this iteration is implemented**. Twelve original screenshots were preserved locally with matching hashes. Read-only preview preflight passed: canonical mount matches, current remote main is included, and product source remains the delivered PR #106 source.

## Next action

On the maintainer's next start instruction, read [UI-ITERATION-3.md](UI-ITERATION-3.md) and the **Next review round — 2026-10-15, after PR #106** section of [UI-FEEDBACK.md](../UI-FEEDBACK.md), including its clarification paragraphs. Run `npm --prefix examples/scrypath_ecommerce run ui:preflight` in the canonical checkout, then implement the brief's three batches and verify the rendered journeys. Review beyond the examples. Resolve routine design choices from the recorded recommendations; do not begin another planning-only cycle or ask the maintainer to repeat their feedback. This handoff itself does not request starting implementation before their next instruction.

## Where

Canonical checkout: `/Users/jon/projects/scrypath/.claude/worktrees/ui-experience-reconciliation`; current branch: `fix/ui-feedback-baseline`. Preview: `http://127.0.0.1:4002/admin/search`, container `scrypath_ecommerce-web-1`, seed-disabled. See [UI-PREVIEW.json](../UI-PREVIEW.json). New PR work should retain explicit checkout/data continuity; the root checkout is unrelated, dirty and historical.

## Important signal

The brief groups Search/forms/results, health/recovery/settings, and contextual Help/shared finishing. The ledger preserves exact feedback, source findings, suggested acceptance and uncertainty. Screenshots: `examples/scrypath_ecommerce/ui-review-artifacts/maintainer-feedback-2026-10-15/` (local ignored files, not approved baselines).

Do not lose these facts: admin max 50 differs from core combined default 200; a schema absent from limited combined hits may still have matches; federated source data is reconstructed; Save uses submitted inputs; title/summary roles are heuristics; document tasks and Oban jobs are distinct; header Refresh already includes settings; Missing tenant_id means absent from live filterable fields, and the table shows differences only. The reported help-fragment failure still needs rendered reproduction. Full details and evidence are in the brief/ledger.

## Preserve and avoid

Keep the existing brand, operational truth, preview records/indexes/volumes and the untracked `examples/scrypath_ecommerce/priv/playbooks/my-search.json` (hash in the brief). Never reseed the retained preview or mutate it with tests. Prior disposable test services on 4013/4014 were removed. Screenshots/reports belong outside Playwright cleanup.

The previous pass is delivered in PR #106 at main `29c287c8e732cddd13e435ccf601e06a39a65837`; [UI-FOLLOWUP-RESULTS.md](UI-FOLLOWUP-RESULTS.md) is historical evidence, not verification of new work. Local later commits are feedback checkpoints. Do not replay Phases 173–177. The separate [dependency advisory task](../todos/pending/2026-10-15-dependency-audit-followup.md) remains outside this UI pass. No numbered GSD phase or new planning command is needed to resume this scoped iteration.
