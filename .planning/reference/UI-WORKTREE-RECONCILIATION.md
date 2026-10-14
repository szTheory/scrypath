# UI worktree reconciliation — 2026-10-13

## What happened

The retained `:4002` preview mounted `phase-174-recovery-entry-diagnosis` on `agent-ui-review-pilot`. It was an active preview, but it did not include all local UI work or later merged-main fixes. The visible-radio picker existed only as an uncommitted edit in the older `planning/next-milestone-handoff` checkout. Its phase executions branched from committed source and did not carry that edit. The preview branch also diverged from later `main` changes. Treating that preview as latest was a bookkeeping error.

No source was deleted during reconciliation. The older checkouts, branches, and local edits remain preserved. Before reconciling, complete tracked patches and 23 root / 13 retained-preview files were backed up under `/tmp/scrypath-ui-worktree-reconciliation-20261013/`.

GitHub confirms PR #101 merged at `f0e05bc8857f56f2a030faa45d4da09a510ef625`; `git ls-remote` confirmed that ref as main during this audit. The new canonical checkout starts at that main commit, rather than replaying phase branches:

- Checkout: `/Users/jon/projects/scrypath/.claude/worktrees/ui-experience-reconciliation`
- Branch: `fix/ui-experience-reconciliation`
- Preview: `http://127.0.0.1:4002`
- Container: `scrypath_ecommerce-web-1`
- Handoff: `.planning/UI-PREVIEW.json`; the older root checkout's AGENTS.md directs future sessions here.

## Local-delta disposition

| Earlier local work | Disposition |
| --- | --- |
| Visible native schema radios, full module metadata, single-schema context | Recovered into the shared component and CSS. Selection follows actual checked inputs, including unsent Search drafts. The old first-option fallback was omitted so an invalid URL scope remains visibly unresolved and the first valid choice can be selected explicitly. |
| Search health diagnostic groups as plain subgroups | Recovered the grouping, divider, spacing, readable headings and values; retained newer phase logic for partial observations, timestamps, handoffs and scope. |
| Old PostureLive replacement and `next_checks` labels | Preserved in the older checkout/backup. The old template was superseded by Phase 174; wholesale copying it would remove newer safety/provenance behavior. Its non-nesting presentation intent is applied to the current template. |
| Storefront hover, unavailable/empty facet explanations, favicon | Reconciled current feedback work, carrying the storefront favicon follow-up while preserving main's mounted-route boundary fix. Populated facets and unavailable-count hierarchy remain separately open. |
| Operator-guide cleanup and nav-contract parser/tests | Preserved the newer combined cleanup. The public GitHub destination will reflect it only after delivery; local validation is not a publication claim. |
| Root PRODUCT.md / operator audience note | Recovered product context and `docs/jtbd-gap-map.md`; consolidated role/job and language tables into the existing maintained quality document. No adopter research is claimed. |
| Root fixed export-count / hook / flash tests | Current main already provides the later dynamic export and hook/flash contracts. Keep those newer checks instead of copying older tests wholesale. |
| Root generated CSS | Regenerated from reconciled source; did not copy old generated styles over main. Existing main JS bundle retained because JS source did not change. |
| Root GSD STATE/state.json/config, prior reviews, caches and Impeccable files | Preserved at the old checkout; its phase position is historical. Model/settings changes are not silently transferred as part of UI reconciliation. No completed phase or frozen receipt is reopened. |
| UI-review tooling and full feedback/model record | Committed pilot carried onto main with cherry-pick `e8afca0a`; later source/port/main guards now prevent mismatched evidence collection. |

## Current UI corrections

- Removed the generic “Operator workspace” eyebrow from the shared page header.
- Restored visible native radio rows in Search, Failed sync work, and Sync/drift; full module names wrap. One resolved schema is context; unresolved scope offers an explicit choice.
- Removed decorative panels from action groups and disclosures, schema forms and encompassing Search/Playbook/failed-sync groups. Retained actual button affordances, danger styling, confirmation, object identity and disclosure semantics.
- Shared structural surfaces use existing opaque neutral tokens to avoid the observed brown cast from translucent interpolation. Kept the documented palette rather than creating a new one.
- Corrected shared verdict-label contrast using the named muted-text role. No new hook suppression was added.

## Runtime preservation and verification

The preview was recreated with the same Compose project and existing database/dependency volumes, adding `compose.preview.yaml`. Its `DEMO_SEED_ON_START=0` bypasses startup seeding. Before/after hashes of tenant, product and category records and queue IDs matched exactly. Three runtime playbooks were preserved. Docker mount inspection confirms `/app` now points to the canonical checkout; HTTP returns 200.

- Ops `mix precommit`: 306 tests and 2 doctests, zero failures; current-source CSS build passed.
- Focused storefront/controller/favicon suite: 12 tests, zero failures.
- UI browser regression: 14 tests passed, covering all three picker consumers, light/dark/system at desktop/mobile, native keyboard and mouse selection, native draft form values, invalid-scope recovery, six page headers, and unframed Playbook actions/disclosures.
- UI-review guard self-tests: 6 passed. An actual run from the new checkout against the old mount failed before browser launch as intended.
- Token contrast: zero AA failures; AAA notes remain advisory.
- Manual Impeccable scan of the changed shared CSS, component, Playbooks and storefront template: zero deterministic findings. No finding was suppressed; broader aesthetic/content issues remain open.
- Confirmation matrix `test-results/ui-review/2026-10-14T02-01-19-406Z/`: 63/63 entry-state captures, zero mechanical findings; all operator contact sheets and representative full screens inspected. That matrix preceded the final invalid-scope helper correction; the current-source 14-test browser run verifies that correction and ordinary controls. The matrix is retained as source-bounded evidence, not silently relabelled as a newer source or approved golden.
- First failures were retained: stale saturated-nav contract; static `checked`-attribute expectation for an unsent Search form; verdict-label contrast; a unit runner with a live-server environment. Each was corrected rather than ignored. Unit checks unset PHX_SERVER and use separate test databases.

Broader product copy, query/preview hierarchy, warning treatment, failure-count cohorts, guide publication and full state/journey coverage remain open in UI-FEEDBACK.md. This scoped recovery does not certify the whole experience as excellent, constitute independent review, or extend archived phase receipts. The preserved legacy browser wash assertions still require reconciliation before that lane can serve as current visual authority.

## Continue

Use this checkout for UI work and its branch for delivery. Do not restart Phases 173–177 from the root checkout. Prepare the verified follow-up for PR review, then continue the broader task-language/hierarchy batch from the whole-app pilot. For a retained preview restart, use `compose.yaml`, `compose.dev.yaml`, and `compose.preview.yaml` with project `scrypath_ecommerce`; preserve volumes.
