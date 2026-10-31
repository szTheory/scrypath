# Scrypath UI review loop

Review the product experience across its current inventory. Maintainer feedback is a set of regression checks, not an exhaustive defect list or a request to optimize isolated screenshots. The pilot includes the storefront, all six task surfaces, and native Help.

## Run against the retained preview

From the checkout actually mounted by the preview container:

```sh
cd examples/scrypath_ecommerce
PLAYWRIGHT_BASE_URL=http://127.0.0.1:4002 npm run ui:preflight
PLAYWRIGHT_BASE_URL=http://127.0.0.1:4002 npm run ui:review
```

Start with the read-only preflight before editing, restarting or collecting screenshots. It prints the verified checkout, command working directory, branch, source fingerprint, Docker mount/main provenance and pending local files; it launches no browser and creates no artifacts. It also reads remote main and refuses stale local main refs; a remote lookup failure cannot establish latest-source status. Refresh and reconcile main when needed. Compare the branch with `.planning/UI-PREVIEW.json`, account for pending source edits before a worktree handoff, and anchor subsequent commands to the verified checkout. See the [incident lessons](../../../.planning/reference/UI-WORKTREE-LEARNINGS.md) for the causes and prevention rules.

This uses the existing Playwright and axe dependencies. It captures eight screens in light, dark, and system-dark at 1440px, 768px, and 390px: 72 entry-state observations, plus full-page, hover, focus, and compact navigation evidence. Each run writes a separate ignored directory under `ui-review-artifacts/` with an HTML gallery, visible copy, headings/controls, accessibility findings, browser errors, a source fingerprint, and a pending `review.json`.

Review artifacts live outside Playwright’s `test-results/` cleanup boundary and survive ordinary test runs. They remain local and ignored by Git; keep review records and captures together when archiving or deliberately removing a run.

The command navigates and opens compact navigation, but does not seed data, submit searches, save files, retry work, or promote indexes. Loading a LiveView can perform its ordinary observations. It leaves the maintainer's browser, theme preference, and data untouched. It does not install dependencies, call a model API, or promote a baseline.

The runner verifies that the preview container's `/app` bind mount resolves to the checkout running the command, the URL matches its published loopback port, and HEAD includes locally known `origin/main`. A mismatch stops capture before launching a browser. `UI_REVIEW_CONTAINER` selects a different Docker preview container when needed. Keep `origin/main` current before calling the preview latest; the guard records the locally known main ref and does not fetch or certify remote freshness. Record container mount/URL, HEAD plus working-tree fingerprint, browser/platform, and observed data state in the review. Store local artifacts locally; don't upload tenant or operational data as a side effect.

## Review before repairing

1. Read `DESIGN.md`, the maintained role/job and language model in `.planning/reference/OPERATOR-UI-QUALITY.md`, and the screen's current behavior. Resolve contradictory instructions against current authority and dated maintainer evidence. Historical fixtures and old scores do not decide today's design.
2. Inspect the full inventory and visible copy **before** using `.planning/UI-FEEDBACK.md` as a checklist. Review each screen at all captured themes/widths and trace these journeys: setup → searchable record; health → affected work → eligible recovery → document check; settings/change → evidence; query → attributed results → saved check → replay; help link → readable, appropriate docs. Entry screenshots alone do not prove these journeys.
3. Assess task fit, hierarchy, language/domain accuracy, composition/typography/color, interaction/accessibility, responsive behavior, and cross-screen consistency. Perform a separate adversarial pass for **unreported** problems, misleading outcomes, excess explanation, absent states, long content, and competing actions. State what should stay because it helps the task; a critic should not invent a replacement visual identity every pass.
4. Inventory populated, empty, setup-missing, loading, failed, partial, stale, disabled, long-content, and zero/one/many states where applicable. Use existing LiveView/browser proofs and isolated deterministic scenarios for missing states. Record proof source and scope; never label an unavailable backend as a successful zero-result check or a default Saved searches screen as a populated/run state.
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

Use `mix verify.ops_ui` and focused demo/LiveView proofs when their scope is affected. The full browser lane remains advisory; this pilot adds no required CI job or beauty score. `admin-light-baseline-check.mjs` checks file inventory and widths, **not pixel parity**.

## Frozen source-pinned preservation captures

The default `node e2e/ui-review.mjs` capture, `--preflight`, and `--check` commands remain attached to the named retained preview and keep their existing source, mount, main-inclusion, and loopback-port guards. Do not add an environment flag to bypass those checks.

Plan 185 uses a separate, bounded disposable path. From the repository root, run:

```sh
node scripts/ci/ui_preservation.cjs capture-before --session /private/tmp/scrypath-phase185-execution/ui-session.json
```

The helper builds the existing full Compose graph from the committed checkout using the repository's image handoff, then verifies image and container source labels, app mounts, project ownership, retained-project/port/volume separation, and mounted plus standalone routes before launching the browser. Its unique project binds only to allocated loopback ports and uses project-owned Postgres and Meilisearch volumes. Source snapshots must be clean and committed. The before capture records its historical main baseline; a later candidate must independently include the current remote main. The session file and its separate ownership record live under `/private/tmp/scrypath-phase185-execution/`; the session record is editable input and does not itself grant teardown authority. The helper compares session bytes and resources against that separately stored creation record, rechecks the retained preview's current container, checkout mount, loopback port and labeled volumes before starting or replacing apps, and verifies exact session labels and container names before deleting disposable resources. `capture_sha256` is SHA-256 of pretty-printed manifest JSON plus a trailing newline after excluding only the `capture_sha256` property. This guards against edited session input and accidental cross-project cleanup; it does not protect against a host user who can edit both records or control Docker.

The matrix includes eight host surfaces and seven standalone Ops surfaces at light, dark, and system-dark themes and 1440, 768, and 390 pixel widths. It saves full-page and viewport images, visible copy, hover and focus states, plus compact control-room navigation. It also checks that the host entry state still shows the seeded incident signals and that standalone Ops still reports its configured empty allowlist; the empty standalone view is not evidence of a populated operator fixture. The session binds every observation to the same source, browser, platform, and database/search-state digest. That digest includes bounded database dumps (excluding only the matched transport nonce), index metadata, settings, stats, documents and the complete Meilisearch task history within the existing 1000-task budget. Any truncated history fails; the limit is never raised to make a capture pass. New disposable evidence is written to `/private/tmp/scrypath-phase185-execution/ui-review-artifacts/phase185/`, outside the implementation worktree and Playwright cleanup. Earlier in-checkout manifests and archived raw evidence remain unchanged; do not move or rewrite them as part of a new capture.

Keep the physical implementation checkout that owns the session available through candidate capture and teardown: its registered Compose and bootstrap-bind paths are part of ownership. After a later source candidate is committed in that owner checkout, use the same session with `capture-after`, then `compare`, and finally `teardown`. Candidate image building happens while the captured stack remains up. Before replacing app containers, the helper checks that the database/search state still matches the before digest, then removes only the recorded web, standalone Ops and browser containers. It starts those app services without running the E2E prepare/seed or standalone migration entrypoints, leaving the owned Postgres and Meilisearch containers, volumes and network in place. It checks the same complete state digest after app startup and after browser capture. Any failure after the app replacement begins triggers teardown of resources that still match the independent project/session authority; a successful candidate remains running intentionally until comparison and explicit teardown. Pairing failures, source mismatches, missing artifacts, retained-resource reuse, or changed data/browser/platform identities are errors. Comparison and exact ownership-checked teardown use the recorded authority and do not require the retained preview to remain available. The comparison counts exact decoded RGBA changes (including alpha) and full-page geometry, uses no numerical tolerance or antialias exclusion, and records visible-copy differences. It commits output atomically after a complete comparison. A changed supported state retains its evidence and makes the command fail. Repeated comparison verification recomputes the pair and verifies existing output bytes without overwriting them; it remains pending and never grants design approval. Inspect the saved images and copy, record concrete findings and unknowns, and keep subjective critique separate from automated evidence.

Disposable viewport, hover, focus and navigation images use Playwright's document capture path clipped to the entire requested viewport. The helper checks exact viewport dimensions, DPR/scale1 and scroll origin before capture and unchanged actual viewport/document geometry afterward, returning raw screenshot bytes. This avoids the reproduced cross-context border-raster variation in the ordinary viewport path without changing styles or layout. Full-page images remain separate; all exact pixel/copy checks still apply.

The disposable Chromium launch additionally pins `--disable-partial-raster`, which eliminated the reproduced partial-paint border variance in targeted repeated-context diagnostics. The exact requested launch options are recorded in each environment, checked against the closed source recipe, and required equal for the pair. Normal Playwright defaults remain enabled. This is a controlled browser recipe, not a product style change or pixel tolerance; full-pair zero-difference proof remains mandatory.

Disposable entry images also require two consecutive byte-identical screenshot samples within six samples and ten seconds. Before the first anchor, preparation naturally waits for active finite animations, font readiness and two actual animation frames, then rescans; cancellation, continued motion or the existing shared ten-second deadline fails the image. This wait changes no styles or timers. The page also advances through two actual animation frames before each sample, and the anchor is never reset once sampling begins. Actual visible text, control values and state, focus, hover, shell geometry, viewport and theme must remain equal around every screenshot and across the sequence. Every raw sample and its state record remain in the capture directory, including rejected samples. Independent artifact validation checks their bounds, paths, hashes, image dimensions, final matching pair and exact selected bytes; the before/candidate comparison also requires equal selected DOM state. The hover/focus target is recorded from the actual selected control using the same semantic reader as the sidecars. Focus evidence must match that visible control, document focus and `:focus-visible`, with a positive solid computed outline and nontransparent color/opacity. These are scoped mechanical checks; they do not certify general accessibility. The initial viewport body text must exactly match the verified entry copy; later interaction images retain their own state text. Hover evidence names actual visible controls and excludes non-painting layout ancestors, which remain covered by the layout anchors. No baseline image guides sample selection. Screenshot, state, file or settlement failures remain failures. This establishes stationary entry-state evidence only: transient loading/error states require their own real barriers and assertions, and must not be allowed to settle into a different state merely to obtain matching pixels.

Beyond-viewport captures in the pinned headless browser can reset generic font settings, matching the [upstream Playwright font-reset report](https://github.com/microsoft/playwright/issues/42962). The disposable runner configures the already-installed native family `Liberation Mono` through a retained page CDP session before navigation. It keeps that connection until the page context closes. This is an explicit capture-environment font setting; it changes no product stylesheet or font stack and installs no fonts. The requested profile is recorded separately as `browser_font_profile`, required on every observation and in both source environments, and bound by the independent authority. A generic `Monospace` alias did not stabilize the measured glyph change; the explicit native family did in the targeted three-entry probe. A configuration acknowledgement does not itself attest the native font; the separate raw platform-font diagnostic does. Full-matrix calibration remains required.

The compact-navigation entry moves the real pointer to `(0,0)` after opening, so a newly uncovered logo does not first acquire hover during screenshot hit testing. Named hover/focus cases keep their intended target. An invalid `capture.error` aborts the matrix immediately after preserving its raw partial output and closing the context; successful runs still require every observation. Mechanical findings remain recorded without being silently accepted.

Disposable observation time is explicit test infrastructure. Both app services receive the existing phase185 E2E run ID and the same read-only external clock directory. A warmup timestamp permits startup probes; after seeded state settles, the helper publishes the final fixed-size timestamp through the same mounted inode, seals it read-only and records its exact bytes in the independent authority. A bounded check waits for those exact bytes through all three real mounts before actual app probes; every read is capped to the remaining total deadline, and unrelated failures propagate. Actual application-clock probes must match in both apps. Chromium fixes only `Date`, keeping timers running, and uses UTC and en-US. Each entry and copy record must match that clock. The same file, time and backend state survive candidate replacement. Production builds always use system time. No source-image masking, copy normalization or timer/VM override supplies parity.


## Current repeatability limit

The source-pinned before/candidate path has been exercised end to end, but no calibration is accepted yet. Earlier failures include advancing server timestamps, border raster variation and one unexplained Help focus frame with shifted content. Every failed pair remains unchanged in its separately named archive. The fixed app/browser clock, document screenshot path, full-raster recipe and bounded stationary-image sampling each address a recorded failure mode; their integrated source still requires a fresh full zero-difference calibration. Raw LiveView-generated Axe selector metadata remains retained and is not claimed byte-identical. Accessible names/keyboard/state semantics require their held-out tests; pixel success alone cannot certify them. Keep every actual image/body-text difference and raw accessibility finding visible.

## Record the result

Populate `review.json` with per-surface and per-dimension verdicts, reviewed capture IDs, concrete rationale, findings, and journey/state coverage receipts. Preserve unknown/uncovered states. A new capture starts pending and cannot silently become accepted just because checks pass. Validate the review record with:

```sh
npm run ui:review:check -- ui-review-artifacts/REPLACE_WITH_RUN_DIRECTORY
```

The checker refuses missing surfaces/themes/widths, missing review dimensions, stale source/capture bindings, missing or changed artifacts, mechanical failures, unfinished coverage, and open findings. It checks completeness/provenance; it cannot verify a reviewer looked at an image or certify good taste. An advisory must name its evidence and reason; don't downgrade a demonstrated task blocker to make the record pass. The pilot remains `needs-work` until its known and newly discovered blockers are addressed.

Keep the enduring summary and open issues in `.planning/`, with source identity and artifact paths. Update only role/job/language assumptions invalidated by a workflow change or new evidence. Track recurring confusion and regressions across successive batches; fewer repeated defects and clearer completed tasks are the pilot's success signals. Do not copy screenshots, personas, and vocabulary into competing authorities.

For GSD work, run this loop during UI planning to establish the current problems, after implementation to assess rendered results, and before a completion claim. Carry unresolved findings forward explicitly; this user-requested pilot does not reopen completed Phases 173–177 or extend their exact-source receipts.

## Basis

- [Playwright visual comparisons](https://playwright.dev/docs/test-snapshots): reviewed references and matching render environments matter.
- [Playwright accessibility testing](https://playwright.dev/docs/accessibility-testing) and [W3C evaluation guidance](https://www.w3.org/WAI/test-evaluate/): automated checks need complementary evaluation.
- [UX Writing Skill](https://github.com/content-designer/ux-writing-skill): purposeful, concise, conversational, accurate task copy; generic length/readability figures are editorial heuristics here.


## Follow-up state coverage

The test-only health scenarios `processing`, `backend-failed`, `retrying`, and `completed` expose the two stages separately with fixed task/job identities and observation times. These are labeled snapshots, not live recovery evidence. The existing UI fixture adds heterogeneous returned fields, including false, zero, null, custom IDs and nested values.

For an actual Meilisearch document failure, `mix scrypath.demo.seed --scenario indexing_failure` is opt-in and belongs only in a disposable demo stack. It submits an invalid document and waits for the real failed task; its history persists until that owned backend is reset. Run normal green/recovery/promotion checks first. Never reseed the retained feedback preview or raise history limits to clear accumulated test failures.

`ui_followup.spec.ts` checks stationary copy-feedback geometry, select spacing, native Help, source-specific health snapshots, readable/raw data fidelity, submitted-versus-draft save behavior, combined limits and compact themed rendering. The legacy time/copy suites retain actual browser-outcome and race checks. These mechanical proofs complement, rather than replace, a distinct rendered critique of the complete inventory.
