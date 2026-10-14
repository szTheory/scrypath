# Scrypath UI review loop

Review the product experience across its current inventory. Maintainer feedback is a set of regression checks, not an exhaustive defect list or a request to optimize isolated screenshots. The pilot includes the storefront, all six operator surfaces, and the operator-guide handoff.

## Run against the retained preview

From the checkout actually mounted by the preview container:

```sh
cd examples/scrypath_ecommerce
PLAYWRIGHT_BASE_URL=http://127.0.0.1:4002 npm run ui:review
```

This uses the existing Playwright and axe dependencies. It captures seven screens in light, dark, and system-dark at 1440px, 768px, and 390px: 63 entry-state observations, plus full-page, hover, focus, and compact navigation evidence. Each run writes a separate ignored directory under `test-results/ui-review/` with an HTML gallery, visible copy, headings/controls, accessibility findings, browser errors, a source fingerprint, and a pending `review.json`.

The command navigates and opens compact navigation, but does not seed data, submit searches, save files, retry work, or promote indexes. Loading a LiveView can perform its ordinary observations. It leaves the maintainer's browser, theme preference, and data untouched. It does not install dependencies, call a model API, or promote a baseline.

The runner verifies that the preview container's `/app` bind mount resolves to the checkout running the command, the URL matches its published loopback port, and HEAD includes locally known `origin/main`. A mismatch stops capture before launching a browser. `UI_REVIEW_CONTAINER` selects a different Docker preview container when needed. Keep `origin/main` current before calling the preview latest; the guard records the locally known main ref and does not fetch or certify remote freshness. Record container mount/URL, HEAD plus working-tree fingerprint, browser/platform, and observed data state in the review. Store local artifacts locally; don't upload tenant or operational data as a side effect.

## Review before repairing

1. Read `DESIGN.md`, the maintained role/job and language model in `.planning/reference/OPERATOR-UI-QUALITY.md`, and the screen's current behavior. Resolve contradictory instructions against current authority and dated maintainer evidence. Historical fixtures and old scores do not decide today's design.
2. Inspect the full inventory and visible copy **before** using `.planning/UI-FEEDBACK.md` as a checklist. Review each screen at all captured themes/widths and trace these journeys: setup → searchable record; health → affected work → eligible recovery → document check; settings/change → evidence; query → attributed results → saved check → replay; help link → readable, appropriate docs. Entry screenshots alone do not prove these journeys.
3. Assess task fit, hierarchy, language/domain accuracy, composition/typography/color, interaction/accessibility, responsive behavior, and cross-screen consistency. Perform a separate adversarial pass for **unreported** problems, misleading outcomes, excess explanation, absent states, long content, and competing actions. State what should stay because it helps the task; a critic should not invent a replacement visual identity every pass.
4. Inventory populated, empty, setup-missing, loading, failed, partial, stale, disabled, long-content, and zero/one/many states where applicable. Use existing LiveView/browser proofs and isolated deterministic scenarios for missing states. Record proof source and scope; never label an unavailable backend as a successful zero-result check or a default Playbooks screen as a populated/run state.
5. Rank concrete findings by task impact and evidence. Each finding names the affected surface/state, screenshot or test, user consequence, smallest coherent repair, and behavior to preserve. Deduplicate shared causes and fix those once across affected screens. Your own preference, a model score, or several agents agreeing is not adopter evidence.

The implementation pass and critic pass have different responsibilities. When the active GSD workflow permits a separate reviewer, give it the current evidence and contract without the implementer's rationale. Otherwise do a distinct in-thread critique and label it honestly; don't claim independent review. The critic must cover the complete inventory rather than only the implementer's diff or known feedback.

## Bounded repair and protection

Fix the highest-impact findings together in one coherent batch. Keep task semantics and scope stable, use shared components/tokens, and avoid adding a dependency for a pattern already supported. Confirm in one further batched rendering pass across affected screens plus adjacent shared surfaces. Stop after that confirmation; leave remaining concrete issues recorded for a subsequent scoped batch instead of making endless cosmetic edits.

Convert recurring **observable** defects into focused checks: meaningful states, real form wiring, focus/selection, horizontal overflow, accessible labels/contrast, navigation/guide contracts, and exact result/task provenance. Visual snapshots protect a previously reviewed direction; they don't establish that the direction is good. Do not freeze today's disputed palette as an approved golden or automatically update snapshots to clear a failure. Compare matching browser/OS/viewport/state captures and document intentional changes. Keep timestamps/operational evidence truthful; don't mask whole status cards or data regions to make diffs green.

Use the existing deterministic browser and state fixtures in a disposable verification stack:

```sh
# From the repository root; this command owns its test stack, not the feedback preview.
mix verify.ecommerce_e2e
```

Use `mix verify.ops_ui` and focused demo/LiveView proofs when their scope is affected. The full browser lane remains advisory; this pilot adds no required CI job or beauty score. `admin-light-baseline-check.mjs` checks file inventory and widths, **not pixel parity**. The legacy optional paid judge is supplemental only and cannot establish journey or whole-app coverage.

## Record the result

Populate `review.json` with per-surface and per-dimension verdicts, reviewed capture IDs, concrete rationale, findings, and journey/state coverage receipts. Preserve unknown/uncovered states. A new capture starts pending and cannot silently become accepted just because checks pass. Validate the review record with:

```sh
npm run ui:review:check -- test-results/ui-review/REPLACE_WITH_RUN_DIRECTORY
```

The checker refuses missing surfaces/themes/widths, missing review dimensions, stale source/capture bindings, missing or changed artifacts, mechanical failures, unfinished coverage, and open findings. It checks completeness/provenance; it cannot verify a reviewer looked at an image or certify good taste. An advisory must name its evidence and reason; don't downgrade a demonstrated task blocker to make the record pass. The pilot remains `needs-work` until its known and newly discovered blockers are addressed.

Keep the enduring summary and open issues in `.planning/`, with source identity and artifact paths. Update only role/job/language assumptions invalidated by a workflow change or new evidence. Track recurring confusion and regressions across successive batches; fewer repeated defects and clearer completed tasks are the pilot's success signals. Do not copy screenshots, personas, and vocabulary into competing authorities.

For GSD work, run this loop during UI planning to establish the current problems, after implementation to assess rendered results, and before a completion claim. Carry unresolved findings forward explicitly; this user-requested pilot does not reopen completed Phases 173–177 or extend their exact-source receipts.

## Basis

- [Playwright visual comparisons](https://playwright.dev/docs/test-snapshots): reviewed references and matching render environments matter.
- [Playwright accessibility testing](https://playwright.dev/docs/accessibility-testing) and [W3C evaluation guidance](https://www.w3.org/WAI/test-evaluate/): automated checks need complementary evaluation.
- [UX Writing Skill](https://github.com/content-designer/ux-writing-skill): purposeful, concise, conversational, accurate task copy; generic length/readability figures are editorial heuristics here.
