# Phase 115 Diff Hygiene

**Date:** 2026-06-01
**Status:** Active

## v1.31 Adoption-Evidence Changes

These files are part of the current v1.31 work and should be reviewed together:

- `.dockerignore`
- `.gitignore`
- `.planning/PROJECT.md`
- `.planning/REQUIREMENTS.md`
- `.planning/ROADMAP.md`
- `.planning/STATE.md`
- `.planning/MILESTONE-ARC.md`
- `.planning/MILESTONES.md`
- `.planning/phases/113-demo-journey-and-e2e-evidence-hardening/`
- `.planning/phases/114-demo-dx-docs-and-ops-ui-polish/`
- `.planning/phases/115-closeout-diff-hygiene-and-maintainer-uat/`
- `README.md`
- `CONTRIBUTING.md`
- `guides/overview.md`
- `scripts/ci/phase105_evidence.sh`
- `examples/scrypath_ecommerce/Dockerfile`
- `examples/scrypath_ecommerce/README.md`
- `examples/scrypath_ecommerce/assets/`
- `examples/scrypath_ecommerce/compose.dev.yaml`
- `examples/scrypath_ecommerce/compose.yaml`
- `examples/scrypath_ecommerce/docker-entrypoint.sh`
- `examples/scrypath_ecommerce/e2e/helpers/e2e.ts`
- `examples/scrypath_ecommerce/e2e/operator.spec.ts`
- `examples/scrypath_ecommerce/e2e/storefront.spec.ts`
- `examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/controllers/e2e_controller.ex`
- `examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/router.ex`
- `examples/scrypath_ecommerce/package.json`
- `examples/scrypath_ecommerce/test/scrypath_ecommerce_web/controllers/e2e_controller_test.exs`
- `scrypath_ops/lib/scrypath_ops_web/components/layouts.ex`
- `scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex`
- `scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex`
- `scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex`
- `scrypath_ops/lib/scrypath_ops_web/live/search_live.ex`
- `scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex`
- `scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs`
- `scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs`
- `scrypath_ops/test/scrypath_ops_web/ops_shell_contract_test.exs`

## Pre-Existing Or Separate Churn

These were already present or are not obviously part of the v1.31 demo hardening pass. Do not fold them into the v1.31 review without a separate decision:

- Mass deletions under `.planning/phases/92-*` through `.planning/phases/108-*`.
- Existing untracked Phase 110 summaries/review/verification files.
- Existing planning threads under `.planning/threads/`.
- Research drift under `.planning/research/`.
- `docs/search-backend-sre.md`, `guides/common-mistakes.md`, `guides/drift-recovery.md`, `guides/meilisearch-operations.md`, `guides/relevance-tuning.md`.
- `examples/phoenix_meilisearch/lib/scrypath_demo/blog/author.ex`.
- `examples/scrypath_ecommerce/config/dev.exs`, `config/test.exs`, fixture/test files outside the controller/browser proof path.
- `lib/scrypath.ex`, `lib/scrypath/schema.ex`, `lib/mix/tasks/verify.adopter.ex`, and related root tests.
- `guides/meilisearch-concepts.md`, prompt research files, `test_e2e_plan.md`, `update_plans.py`, and `update_plans2.py`.

## Generated Artifacts Now Ignored

- `examples/scrypath_ecommerce/node_modules/`
- `examples/scrypath_ecommerce/test-results/`
- `tmp_phx/`

## Recommendation

Review or commit v1.31 separately from the pre-existing archive/research churn. If a commit split is needed, stage by the v1.31 list above first, then handle unrelated planning cleanup in a separate maintenance commit or leave it untouched.
