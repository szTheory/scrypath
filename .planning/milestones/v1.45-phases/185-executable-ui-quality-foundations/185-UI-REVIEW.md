# Phase 185 — UI Review

**Audited:** 2026-11-01
**Baseline:** UI-SPEC, DESIGN.md, PRODUCT.md, and the maintained roles, jobs and language map.
**Screenshots:** The original global 135-entry matrix / 546 candidate images and the held-out before/candidate images were actually inspected. The held-out source pair has since been refreshed to R15/R4; all 426 current held-out images, body text and selected raw states were verified byte-identical to the already inspected content. Qualified before images were inspected separately.
**Interactions:** Actual hover, keyboard focus, compact navigation, pending and failed transport, and protected deletion states.
**Observers:** Codex root and named native in-thread reviewers. No independent, human or maintainer approval.
**Disposition:** Broader UI needs work. Subjective critique is nonblocking for this preservation phase; exact comparisons establish unchanged rendering within the supported scope.

## Pillar Scores

| Pillar | Score | Key finding |
|---|---|---|
| Copywriting | 2/4 | Operational distinctions survive, but clipped descriptions hide guidance and a no-schema state suggests a disabled Refresh action. |
| Visuals | 3/4 | Neutral hierarchy and local accents are preserved; duplicate reconnect notices compete for attention. |
| Color | 3/4 | Light/dark AA and focus adjacency contracts pass. Requested storefront themes do not establish three distinct palettes. |
| Typography | 3/4 | Named sans and technical monospace roles remain readable; long saved-search warnings and inputs clip. |
| Spacing | 2/4 | Normal responsive rhythm is preserved; the long-name destructive sheet exceeds its narrow content boundary. |
| Experience Design | 2/4 | Real pending, recovery and deletion semantics remain, alongside inherited busy-feedback and setup-guidance defects. |

**Overall: 15/24.** These are bounded observer judgments, not an approval threshold or new UAT gate.

## Top Three Follow-ups

1. Keep complete saved-search names, warnings and controls inside the narrow destructive sheet, and make clipped catalog guidance accessible. Users must identify exactly what will be deleted or run.
2. Give the no-schema Sync and index state an available configuration step. Suggest Refresh when it can be used.
3. Make a pending storefront search perceptible and consolidate reconnect feedback into one clear state.

These findings are inherited and preserved exactly. No demonstrated Phase 185 rendering regression remains. Repairs belong to a separately approved product polish scope.

## Detailed Findings

### Copywriting (2/4)

Health explicitly says that no failures does not confirm document visibility. Help distinguishes request acceptance, task completion, matching settings and actual searchability; saved inputs remain distinct from results. Complete raw body text retains both reconnect notices, even when a curated copy array lists one.

Saved catalog descriptions are clamped to two lines (`scrypath_ops/assets/css/app.css:2660`; rendered at `search_live.ex:1819`). This hides a federation ranking caveat and mobile probe guidance. The standalone no-schema Sync and index frame tells users to check Meilisearch and then Refresh while Refresh is disabled (`sync_drift_live.ex:1942`, `:2209`). Storefront “Laptops 1 products” grammar is also visible. These are inherited findings.

### Visuals (3/4)

Full-page and viewport matrices preserve page, section and control hierarchy, restrained neutral panels, and selected navigation. Error frames for E2, E4, E5, E6, E8 and E9 retain stacked reconnect notices.

E8 full-page captures at a retained scroll position can project sticky chrome into the long document. The separately proved native viewport hover shows normal top chrome in the actual scroll context. This is a capture limitation, not an inferred product overlap. Unavailable storefront results and empty standalone configuration limit the entry matrix; separate held-out fixtures cover usable task states.

### Color (3/4)

Live semantic light/dark Ops tokens, local violet interaction accents and labeled status distinctions remain unchanged under exact RGBA comparison. Both actual built profiles retain black, white, spacing and type utilities while rejecting default palette utilities. Required contrast mutations, ordinary text AA and focus/background 3:1 witnesses pass.

This is bounded contrast coverage, not complete WCAG conformance. The storefront remains visually light across some requested themes; its intended theme behavior is unresolved. No silent recoloring, exception or three-distinct-palette claim was introduced.

### Typography (3/4)

The existing 24px page, 18px section, 16px record and 14px body hierarchy and technical identifier roles are preserved. E7 long schema and index text wraps within narrow cards. E9 long queries stay inside the input's own scroll area.

E10's long saved name, warning and 607.625px confirmation input extend past the content boundary at a 390px viewport. The original PNG and measured rectangle confirm this. Full body text retains the name, but that does not make the clipped warning acceptable (`search_live.ex:1913`, `:1917`).

### Spacing (2/4)

Normal panels and controls retain the shell rhythm across 1440px, 768px and 390px widths with unchanged geometry. Local mobile result scrolling is explicit. A page-wide overflow check cannot detect every clipped child.

The E10 long-name case exceeds the sheet boundary; the ordinary overflow case fits its 350px input. The inherited defect warrants a later coherent narrow-overlay repair. Passing preservation does not mean every layout is flawless.

### Experience Design (2/4)

Canonical browser cases trace setup to searchable data, health to failed work and eligible recovery with a correlated document check, settings to evidence, attributed queries to saved replay, and Help. A test-only caller pipeline denies missing or invalid identity and admits valid identity into the real mount. Layout-requested CSS and JavaScript are actually observed, while forwarded direct-script 403 protection remains intact.

Protected deletion retains exact-name confirmation, wrong-name feedback and disabled pending actions. Pending states bind real transport and busy markers, although storefront search can still look settled. The entry matrix alone cannot prove successful backend recovery; fixture execution and semantic assertions supply that separate evidence.

## Evidence and Limits

All 61 obligations have actual receipt references in `185-UI-PRESERVATION.md`. The original global comparison covers 546 images; the refreshed held-out R15/R4 comparison covers 426 images with copy, geometry, state and semantic checks. The original global repeat and current held-out exact repeat both passed. The held-out inspection-reconciliation records establish byte identity with the sets already actually inspected; the reuse does not imply independent approval.

Observer reports and every raw image ID/hash are reconciled in `/private/tmp/scrypath-phase185-execution/global-candidate-inspection-combined.json` and `heldout-candidate-inspection-combined-r3.json`. Every original global selected image was actually inspected. The refreshed R15/R4 held-out selected images are exact-byte matches to previously inspected content per `heldout-before-r15-inspection-reconciliation.json` and `heldout-candidate-r4-inspection-reconciliation.json`. Raw `review.json` remains pending; neither captures nor passing tests populate design acceptance.

E5 partial-field evidence is the declared shared ResultUi component boundary. E4 and E6 zero/one/many selected frames have explicit limits: intermediate count assertions are not claimed as screenshots. E2 uses its authored 33-character identifier rather than an unspecified extreme-length stress case. E4 future retry dates deliberately park fixture jobs. Browser, font, timer, clock, source and data provenance and stationary sampling are bound. No masks, tolerances, automatic baselines, registry or dependency were added.

Four unclassified source assumptions and three descriptorless judgment prohibitions remain flagged and unverified. Broader design readiness and the retained-preview stop remain independent. Retained source and data were untouched, and inherited security advisories remain unaccepted. Hosted run `41295225239` failed the repository job on a missing installation of the already-locked `pngjs` test prerequisite and a run-owned handoff mismatch. The CI-only repair keeps the dependency version/lockfile unchanged; fresh hosted acceptance and terminal exact-SHA verification remain pending.

## Files Audited

DESIGN.md, PRODUCT.md, the operator quality reference, UI-SPEC, live CSS/token/focus/component authorities, the supported route/search/health/failed-work/settings/Help surfaces, and actual canonical images, copy and state artifacts. Source review is recorded separately in `185-REVIEW.md`.

## Current-source input boundary

`candidate-input-reconciliation-fa42d99e.json` verifies that the product tree, 22 of28 shared capture files and all product/runtime recipes remain byte-identical; two build-helper/test files change outer prebuilt metadata handling and four runner/evidence files add the permitted serial full-suite execution/union validation. The actual capture producers, browser/page configuration and qualified before-only path are unchanged. Four accessibility consumers and their isolated frame-safe Axe helper changed outside those producers; their current canonical full hosted proof is separately validated in `candidate-r10-full-acceptance.json`. Original image/inspection receipts retain their identities. This adds no new rendered inspection, independent review, aesthetic approval or retained-preview authority.

## Prebuilt handoff and original-proof boundary

The first optimized hosted browser run passed all254cases in736seconds but its final prebuilt check rejected six newly measured fields, so its whole receipt remains failed. The successor normalizes only those browser metadata values in the prebuild model and independently verifies all supplied values against actual loaded/container images and fresh runtime inspection. Missing/forged partial metadata, source/recipe/cache changes and browser-tag substitution fail. Existing image-only global callers retain their original container-image checks when no measured field is supplied. The initial overstrict caller assumption was caught and reproduced before acceptance; candidate7 was explicitly superseded through existing workflow concurrency. Focused regression and actual read-only model/Bake evidence are in `runtime-handoff-image-only-caller-fix.json` and `runtime-handoff-model-diagnosis-r2.json`. Original R15/R4 runtime identity objects are exactly unchanged, and `state-pair-current-helper-revalidation.json` recomputes the original61-case comparison with byte-identical output. The two metadata helper/test changes are a subset of the six current overlay changes from the original8756 pair; no source or overlay is relabeled. Current canonical full hosted acceptance is separate.

## Serial full-suite source and proof boundary

The current source passed the complete serial full lane, immutable archive verification and independent canonical receipt recomputation. The batches preserve one worker, zero retries, original traces, the exact discovered union and clean owned teardown within the existing limits. The cold local path explicitly acquires only the existing service images before startup; failed acquisition prevents execution.

[Source reconciliation](185-SOURCE-AUDIT.md#serial-full-suite-source-and-proof-boundary) records the six changed outer overlay files, unchanged product/capture inputs, preserved original pair/global identities, discarded trace experiment and excluded failed/superseded runs. The actual current receipt is `candidate-r10-full-acceptance.json`. Final tracking-source terminal acceptance remains a separate mandatory external gate; no independent/design/risk approval or retained-preview action is inferred.
