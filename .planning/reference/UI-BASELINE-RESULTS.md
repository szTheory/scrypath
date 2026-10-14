# Scrypath UI baseline — implementation and verification

**2026-10-14. Delivery:** [PR #105](https://github.com/szTheory/scrypath/pull/105), `fix/ui-task-baseline`. All three planned batches are implemented. The baseline passes its executable and rendered review; final hosted delivery is tracked by the PR checks and merge state. This is a distinct in-thread critique and executable verification, not an independent design attestation or adopter study.

## Delivered tasks

| Task / batch | Resulting experience | Executable evidence |
| --- | --- | --- |
| Try search / 1 | Search sits directly after Control Room in a flat navigation. “Go to…” opens navigation. Home states the actual cause and affected schema concisely, with one label per task link. Schema, query and bounded result controls form one task; submitted query/targets remain attributed after draft edits. | `ui_baseline.spec.ts` query/save/replay; `admin_surface_depth.spec.ts` submitted-versus-draft attribution and zero-hit capture; `ui_reconciliation.spec.ts` invalid scope and native radio interaction. |
| Understand and recover / 2 | Health distinguishes Meilisearch tasks, Oban jobs and failed observations. Failed work separates terminal failures from scheduled retries; operations and source IDs are readable, normal empty results compact. Retry queued does not mean completed. Sync/settings Refresh lives in the header; settings load automatically and show actual declared/live differences. Document/recovery/promotion content appears in its applicable context. | `operator.spec.ts` exact non-first Variant recovery and promotion; LiveView suites for partial/retained observations, current selection/generation/request, observer failures, missing replay input, confirmation/authorization and original/replacement identity. |
| Save and reuse / 3 | Navigation and heading consistently say Saved searches. Inputs, saved definition, edited draft and completed run stay distinct. Preview leads a flat catalog; file actions are secondary, storage configuration is optional context. Mobile actions sit below readable text. Import/save/run errors retain useful inputs and recovery guidance. | `admin_surface_depth.spec.ts` import, save collision, draft/run provenance and file-dialog focus; `ui_baseline.spec.ts` real rerun and clipboard outcome; Playbook LiveView suite. |

## Whole-inventory critique and confirmation

The initial capture was `ui-review-artifacts/2026-10-14T21-29-07-791Z` at the pre-implementation source. Entry states alone did not establish any journey. Subsequent review kept the existing brand and cool surface direction while removing repeated orientation, competing wrappers and internal task jargon. No dependency, public API, route or JSON-format change was added.

Review included storefront, all six operator destinations, their visible copy/controls and the rendered guide. The 1440/768/390 widths and light/dark/system-dark variants were compared in contact sheets and representative full-page/interaction images. The final capture is `/Users/jon/projects/scrypath/.claude/worktrees/ui-experience-reconciliation/examples/scrypath_ecommerce/ui-review-artifacts/2026-10-14T22-45-57-728Z` (63/63; zero mechanical findings); its reviewed source fingerprint is `d825eb7b3db82cc3e4271dbeff963dc9af72018f24f5fbaaa9db266cd4ef0104`. `review.json` contains the distinct in-thread surface/dimension review and local journey receipts. The checker validates completeness/provenance, not taste. No disputed screenshot was automatically promoted to a pixel golden.

Unreported defects found and repaired during the pass:

- The old diagnostics-copy action announced success before the browser clipboard operation. A gesture-based shared handler now reports the actual outcome and exposes selectable fallback text on failure.
- A settings comparison table could scroll horizontally without a keyboard focus target. Its named region is now focusable; comparison meaning and full settings remain available.
- Catalog actions squeezed mobile titles/filenames into a narrow column. They now follow full-width text at compact widths; a geometry regression checks the title width and action order.
- Long schema names could overflow at 320px. The shared short-name label now wraps at identifier boundaries without hiding the full module; the five-schema fixture exercises this.
- Storefront reported zero hits when the search request failed and placed results after all secondary filters on mobile. Unavailable results now have no successful zero count; query controls precede results, then secondary facets/demo context.
- A stationary pointer could take over keyboard command selection when the menu reopened or filtered. Selection now follows deliberate pointer movement; theme/width regression tests cover mixed input.
- Import notices still said “playbook”; an invalid result limit exposed an internal tuple. The notices use Saved search and the limit error states the supported range.

The import test deliberately dismisses a success notification before the next action at the bottom of a small viewport, using its actual accessible Close control. It does not force-click through overlays. Legacy tests were aligned with the accepted flat floor/native radios/neutral preference treatment, retaining computed contrast, geometry, focus, selection and scope assertions. No moving pill or glow was restored to satisfy obsolete test expectations.

## Evidence receipts

- Operator `mix precommit`: **309 tests + 2 doctests, zero failures** after the final product edit; includes navigation contract, compile/format and operational state tests. Local log `/tmp/scrypath-baseline-ops-tests.log`.
- Focused demo LiveView/controller tests: **12 tests, zero failures**, including populated/empty/unavailable facets and truthful unavailable-hit rendering. Local log `/tmp/scrypath-baseline-demo-tests.log`.
- Browser result: **all 168 distinct cases covered**: 167 passed in the clean full run; one first-frame transition assertion was corrected to poll rendered hover/press changes, then the complete mounted/standalone status suite passed **6/6** with no retries. No product edit followed the full run. Full receipt: `/tmp/scrypath-baseline-clean-browser.log` and `/tmp/scrypath-ui-baseline-clean-results/phase105-playwright.json`. The earlier promotion refusal came from accumulated disposable task history exceeding the 1000-task bound; a fresh owned Meilisearch instance restores deterministic setup without relaxing any guard.
- Guide: GitHub's GFM renderer returns a six-row destination table with machine JSON hidden; all eight relative help links resolve locally. Render inspected as `/tmp/scrypath-operator-guide-final.png`. Core HexDocs and the optional Ops repository guide are correctly distinguished.
- Required hosted CI passed at checkpoint `2cfe3bec` in run `38644630809`. Final delivered-source run is recorded by PR checks. The separate advisory dependency audit reports unchanged Cloak, CloakEcto and Decimal advisories; no dependency lockfile changed in this UI pass.

## Scope and retained evidence

The retained preview is `http://127.0.0.1:4002/admin/search`, container `scrypath_ecommerce-web-1`, mounting the canonical checkout in `../UI-PREVIEW.json` with startup seeding disabled. All seed/retry/save/promotion tests use the owned disposable `scrypath_ui_baseline` stack and separate files/volumes. Root-checkout changes and unrelated containers remain untouched.

The retained demo intentionally has incident data and missing filterable settings. Storefront unavailability is honest. The inspector now maps actual completion/schedule times: Product displays its real observed completion and Variant reports no completed job in available history. Neither result fabricates a last success. Test retries parked years ahead are a stabilization shortcut, not realistic scheduling guidance. No queue backlog, freshness or global health is inferred from a count or absence of failures.

Coverage combines browser task proof with unit/LiveView evidence for setup-missing, loading, errors, empty/zero/nonzero, partial/stale/retained, long-content and disabled/guarded states. Browser tests use Chromium; this is not a claim of manual screen-reader testing, every-browser certification, independent taste validation or adopter research. The existing roles/jobs remain maintained hypotheses with change-based revisit triggers. Future feedback should extend the same ledger rather than restart brand/persona discovery.

No design-rule suppression was added. The old attributed-unknown Phase 176 mockup finding was not treated as a shipped regression or used to broaden this follow-up. Current live controls and task paths were evaluated directly.
