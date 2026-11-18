# Phase 185: Executable UI quality foundations - Context

**Gathered:** 2026-10-30
**Status:** Ready for UI contract and planning

<domain>
## Phase Boundary

Deliver UIF-01–UIF-06: a required shrink-only source-literal ratchet, a color-only Tailwind namespace reset, removal of the standalone generator page, required static light/dark contrast and focus checks, a valid DTCG Ops token mirror with drift proof, and retirement of paid/synthetic visual-judge entrypoints. Preserve the supported operator/storefront experience and the existing five required CI jobs.

The maintainer explicitly requested specialist subagent research across all relevant areas, primary sources, alternatives and an adversarial pass, and delegated adoption of a coherent recommendation set. These are selections under that delegation, not individual questionnaire answers, visual approval or security-risk acceptance. This invocation captures discussion only; it does not advance into implementation or another phase.

Phase 184's external terminal receipt succeeded at the unchanged discussion-base source. Its evidence remains bounded to that source. The unrelated `.planning/config.json` edit, historical receipts, retained-preview data and inherited unaccepted advisories remain preserved.

</domain>

<decisions>
## Implementation Decisions

### One required contributor workflow

- **D-01:** Use the existing stack and small local helpers. Add no runtime dependency, parser framework, token build system, review service or required CI job. Preserve Phase 183's `dev/mix/tasks`/Hex boundary and Phase 184's dev asset-builder versus test/production runtime boundary. Prefer reuse/copying a small helper over adding a dependency; retain maintained infrastructure where it is actually needed.
- **D-02:** The canonical `mix verify.repository_contracts` command must itself execute L1, static contrast and token-drift enforcement. Extend its root contract/test spine, with executable negative cases and propagated subprocess failures. A separate CI-only step or the path-scoped optional `ops-ui` job is insufficient. The existing dependency-free Node contrast checker remains the color-math implementation; root contracts may invoke it without installing npm packages or compiling Phoenix. Standalone/local invocation must have the same enforcement as CI.

### L1 scope, authority and a real shrink-only baseline

- **D-03:** Govern first-party authored UI source in `scrypath_ops` and its ecommerce host, including their HEEx/embedded templates, relevant static class literals and authored CSS. Keep source discovery explicit and cover new files under those roots automatically. Exclude generated `priv/static`, dependencies/vendor code, test/negative fixtures, documentation, the separate marketing website and brandbook presentation assets. The Phoenix Meilisearch example is API-only, so do not invent a UI migration for it.
- **D-04:** Enforce the four approved rules: raw hex color literals in styling contexts, arbitrary-value utilities (including token-backed square/parenthesis value forms), inline `style` attributes including dynamic forms, and literal stacking utilities. Named `z-ops-*` roles remain valid; un-tokenized forms, including `z-auto`, receive no new exception to UIF-01. Arbitrary selector/state variants are distinct from arbitrary utility values. Do not mistake CSS ID selectors, URL fragments, Elixir syntax, prose or comments for colors/classes. Do not silently extend this phase to all RGB/OKLCH literals, all numeric CSS `z-index` declarations or a general CSS-value ban.
- **D-05:** Token authorities are explicit declaration sections in the named source token stylesheets, not blanket stylesheet exemptions or a rule that permits any `--custom-property` anywhere. Existing ordinary literals in the ecommerce stylesheet are inventoried legacy findings unless already inside an approved theme/token section. Keep the two legacy inline-style uses and token-backed arbitrary utilities in the shrinking inventory if removing them adds needless implementation work. There is no zero-baseline cleanup target and no CSS-variable-only exception to the inline-style rule. Generator-page removal naturally deletes its findings.
- **D-06:** Model findings as a multiset keyed by rule, repository-relative file, stable source context and exact offending value. Preserve duplicate multiplicity. Use line/column for diagnostics, not identity. Actual findings must equal the candidate ledger; the ledger must only lose entries against trusted committed history. A same-count replacement, changed value, moved violation into a different file, added duplicate, edited baseline or reintroduced previously removed finding must fail. Formatting/comment/line movement alone should not churn identities.
- **D-07:** Resolve a trusted comparison source independently of candidate ledger contents. Use the trusted target branch's first-parent ledger at the recorded comparison ref as authority, rather than an arbitrary candidate-selected ref or merge-base alone; reconcile newer target-branch reductions before merge. Also enforce monotonicity across committed reductions in the candidate's first-parent range so a cleanup cannot be reversed inside one PR. Cover PR, push, scheduled/manual and local execution explicitly; missing/unavailable comparison history must fail with a useful remedy. The first introduction has no older ledger: derive and verify its starting inventory against the immutable pre-phase source `767f368473f17fba43d7be4675c53ab65a87530c`, then lock in reductions through committed history. Do not accept an empty/missing prior ledger as permission to bless arbitrary current findings, silently reset on a version change, or let a stale PR base resurrect a cleanup already committed on the working branch. Exact ref selection and bootstrap mechanics belong in planning, with executable cases before relying on them.
- **D-08:** Keep scanning bounded to author-controlled literal source. Handle static HEEx/class syntax and CSS declaration contexts deliberately; document runtime/injected-attribute limits rather than claim evaluation of arbitrary Elixir. Diagnostics name path, current location, rule, offending value and the token/utility repair. Prove discovery, token-authority boundaries, variant forms, duplicates, same-count swaps, baseline edits, bootstrap/history failures, stale entries and harmless source movement with focused fixtures. No automatic baseline enlargement or update-to-pass command.

### Preserve appearance while removing generator defaults

- **D-09:** Reset only Tailwind's default color namespace with `--color-*: initial` in the stylesheets that actually build standalone and mounted UI. Restore required black/white entries and preserve semantic daisyUI colors, current theme values, spacing and typography defaults. Check the two actual generated bundles; do not assume a reset in standalone CSS changes the host bundle. Prove removed default palette utilities and retained black/white, semantic, spacing and type utilities using representative build fixtures. Do not introduce unrelated framework/vendor upgrades.
- **D-10:** The generator home is currently an active standalone `/` route, not unused at runtime. Delete `home.html.heex` and its now-unused `PageHTML` view, and repurpose the small existing controller action into a local redirect from standalone `/` to `/ops`. Replace its Phoenix-tagline test with redirect/route proof. Preserve all supported `/ops/*` routes, mounted `/admin/search/*` routes, assets, host authentication/mount behavior and the ecommerce storefront `/`. This is removal of generator scaffolding, not a new landing-page design.

### Contrast checks reflect actual text and focus roles

- **D-11:** Preserve the current palette. Enforce unrounded WCAG AA ratios: ordinary text, including button/status labels, at 4.5:1; demonstrably large text at 3:1; meaningful non-text controls/state cues and authored focus indicators against relevant adjacent backgrounds at 3:1. Correct the existing `*-content` label pairs currently classified as non-text `ui`. Keep genuine inactive/decorative exceptions narrow; do not make decorative borders a new contrast requirement or reclassify real text to clear a failure. AAA results remain advisory.
- **D-12:** Extend the existing semantic/muted pair inventory to relevant custom shell surfaces and warning/error text. Cover actual global outside-outline and component inset-focus backgrounds in both themes, including selected/menu surfaces where used. Tie focus-pair definitions to live focus declarations and token references so a changed focus color/background cannot leave a stale passing list. Preserve muted-alpha selector/percentage lockstep, proper sRGB compositing and raw-threshold comparisons. Missing/duplicate themes, missing required tokens, unresolved/unsupported color expressions, empty required pair sets or failed checker execution are errors, not skipped passes.
- **D-13:** Negative cases must prove below-4.5 ordinary text and below-3 focus fail through the canonical required command, including dark-only failures, changed focus/background input and missing/malformed data. Test threshold boundaries without rounding them into a pass. A static token-pair pass is evidence for those pairs; it does not certify every rendered state, keyboard focus visibility, complete accessibility or AAA focus appearance. If implementation finds a genuine current contrast/appearance conflict, preserve the failure and bring the smallest concrete choice to the maintainer; do not weaken a threshold, silently recolor or grow an exception.

### Valid DTCG, with CSS remaining authoritative

- **D-14:** Keep `scrypath_ops/assets/css/app.css` as implementation authority. Convert the entire existing `brandbook/tokens/tokens.json` to typed DTCG token/group structures while preserving the meaning and values of the separate brand palette. Move metadata into appropriate `$description`/`$extensions` fields and remove the stale non-schema `$schema` pointer. Use the published DTCG 2025.10 Format/Color reports, not the redirecting draft. Add `ops.light`/`ops.dark` groups; these names are project mode conventions, not a claim of standardized resolver semantics. No runtime generation, new resolver document or new token platform.
- **D-15:** Mirror every custom-property token in the two live theme blocks, including semantic colors, custom shell/status colors, muted color, radii/sizes/border and numeric depth/noise. Use typed color/dimension/number representations with explicit source-name mapping; exclude plugin configuration such as theme name/default flags. For the existing hex colors, use sRGB components and consistent hex fallback; represent muted base-content with its actual alpha and check the CSS expression/reference as well as the resolved value. Do not flatten it to an opaque color over one background. The global `@theme` spacing/type catalog remains separate unless needed for an already-scoped invariant.
- **D-16:** Root ExUnit drift proof must compare exact per-theme token key sets and normalized typed values, resolving the bounded CSS forms actually present and failing on unknown forms, missing/extra tokens, duplicate definitions, inconsistent component/hex values or invalid DTCG structures. Mutate CSS-only and JSON-only fixtures independently so either divergence fails. Keep this a small validator for this document's supported types, not a purported general DTCG implementation. Reconcile brandbook/readme/example claims that the unrelated warm `--sp-*` palette mirrors Ops; preserve its presentation and values instead of copying Ops colors over it.

### Retire judge execution, preserve truthful evidence

- **D-17:** Delete the obsolete judge script and npm entrypoint, remove the Makefile invocation/selector/exit-status path and all judge-specific model/key/report/mock wiring and active documentation. Prefer deletion over a tombstone or replacement review engine. Audit executable references rather than invent a CI secret cleanup: research found no paid judge invocation or OpenAI key injection in CI/Compose. Remove synthetic judge report generation too. The current mock reports `mock`/`needs_review`, not a literal passing verdict; correct stale current descriptions without rewriting historical evidence.
- **D-18:** Reconcile active evidence producers, consumers and tests together when removing judge fields/summary sections. Preserve required deterministic inventory, execution, screenshot/contrast, source and artifact evidence. Existing immutable receipts and archived phase records retain their original bytes/meaning; do not relabel them as current or make old receipts newly fail solely because their schema contained retired fields. Current docs must state the deterministic checks' real scope and that calibrated agent-run review is deferred. Preserve the source-aware capture/review harness and its pending state; it must not become an assumed design approval.

### Verification and execution boundaries

- **D-19:** The retained preview remains source-stale and untouched by this discussion. Before UI source edits/restarts or rendered evidence, follow the named checkout in `.planning/UI-PREVIEW.json`, its read-only preflight, source/mount/URL/branch/current-main reconciliation and data-preservation rules. A failed preflight remains a stop until its cause is actually resolved; this research does not override it. Separate disposable verification stacks from the retained preview and keep review evidence outside Playwright cleanup.
- **D-20:** Establish same-source, same-state before/after rendered evidence for the namespace/generator changes in standalone and mounted builds, light/dark and system appearance where affected. Follow the full maintained screen/journey inventory and inspect actual captures/copy; scope the final repair batch to these changes. Reuse established route, theme, keyboard and asset proofs. A manifest/viewport check, passing screenshot capture or agreement among research agents is not pixel parity or independent design approval. Do not auto-update a disputed baseline.
- **D-21:** Reuse the five required jobs and existing advisory/path-scoped posture. Run changed-scope executable contracts plus real built/rendered proofs and CONTRIBUTING's exact-source closeout at implementation. Finish tracking before terminal attestation and keep its receipt outside frozen source. No manual UAT, paid calls, simulated reviewer acceptance, merge, release, new risk acceptance or replay of completed phases follows from discussion. The next step is `$gsd-ui-phase 185` to record preservation constraints, then `$gsd-plan-phase 185`; implementation is not started here.

### Agent's Discretion

Choose small helper names, file layout, parser/test fixtures, semantic finding anchors, trusted-ref transport and precise mutation cases within these contracts. Resolve engineering details through phase research/planning rather than another generic questionnaire. Stop fan-out when additional research would not change a recommendation. Do not use that discretion to expand scope, accept risk, weaken required failures, reset the ledger or change visible product design.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read relevant sections before planning or implementing.** Repository paths below are full repository-relative paths.

### Scope, previous foundations and delivery

- `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/PROJECT.md` — Phase 185 goal, UIF-01–06 and inherited boundaries.
- `.planning/reference/ROLLING-ROADMAP.md` §3 and `.planning/research/ui-quality-engine/RECOMMENDATIONS.md` D4/D6/build order — approved prerequisites; later engine scope stays deferred.
- `.planning/research/ui-quality-engine/OWNER-INTENT.md`, `.planning/research/ui-quality-engine/INVENTORY.md`, `.planning/research/ui-quality-engine/RESEARCH-AUTOMATION-CI.md` — relevant intent/inventory; historical counts and mock descriptions need current-source reconciliation.
- `.planning/phases/182-reliable-full-browser-verification-and-ci-caches/182-CONTEXT.md`, `.planning/phases/183-maintainer-tooling-outside-the-hex-package/183-CONTEXT.md`, `.planning/phases/184-explicit-and-lean-dependency-graphs/184-CONTEXT.md` — browser provenance, repository-only tooling and asset/runtime boundaries.
- `AGENTS.md`, `scrypath_ops/AGENTS.md`, `CONTRIBUTING.md`, `.github/workflows/ci.yml` — maintained workflow, actual gates and changed-scope/exact-source verification.
- `dev/mix/tasks/verify/capability.ex`, `dev/mix/tasks/verify.phase99.ex`, `test/mix/tasks/verify.phase99_test.exs`, `test/mix/tasks/workflow_wiring_test.exs` — required repository-contract spine and wiring.

### UI authority, roles and preview

- `DESIGN.md`, `PRODUCT.md`, `.planning/reference/OPERATOR-UI-QUALITY.md`, `GLOSSARY.md` — current design authority and maintained roles/jobs/language; newer decisions supersede the old prompt brand book.
- `.planning/UI-PREVIEW.json`, `.planning/reference/UI-WORKTREE-LEARNINGS.md`, `examples/scrypath_ecommerce/e2e/UI-REVIEW.md` — named checkout, preflight, preserved data/artifacts, complete rendered-review inventory.
- `scrypath_ops/assets/css/app.css`, `scrypath_ops/assets/css/DESIGN-TOKENS.md`, `scrypath_ops/assets/css/contrast-pairs.mjs`, `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` — live theme/token/focus/component authorities.
- `examples/scrypath_ecommerce/assets/css/app.css`, `scrypath_ops/config/config.exs`, `examples/scrypath_ecommerce/config/config.exs` — independent source scanning and asset profiles.
- `scrypath_ops/test/scrypath_ops_web/design_tokens_contract_test.exs` — existing token-reference/utility/export contracts; reuse without relying on the optional lane for new required rules.
- `scrypath_ops/lib/scrypath_ops_web/dev_router.ex`, `scrypath_ops/lib/scrypath_ops_web/router.ex`, `scrypath_ops/lib/scrypath_ops_web/controllers/page_controller.ex`, `scrypath_ops/lib/scrypath_ops_web/controllers/page_html.ex`, `scrypath_ops/lib/scrypath_ops_web/controllers/page_html/home.html.heex`, `scrypath_ops/test/scrypath_ops_web/controllers/page_controller_test.exs` — generator/root disposition and supported operator routes.
- `brandbook/README.md`, `brandbook/tokens/tokens.json`, `brandbook/tokens/tokens.css`, `brandbook/tokens/daisyui-theme.example.js` — distinct brand palette, false mirror claims and DTCG destination.

### Checker and retired judge integration

- `examples/scrypath_ecommerce/contrast-checker.mjs`, `examples/scrypath_ecommerce/Makefile`, `examples/scrypath_ecommerce/package.json`, `examples/scrypath_ecommerce/docker-playwright.sh` — current dependency-free contrast and browser entrypoints.
- `examples/scrypath_ecommerce/e2e/ops-ui-visual-judge.mjs`, `examples/scrypath_ecommerce/e2e/ops-ui-visual-rubric.md`, `examples/scrypath_ecommerce/e2e/ui-review.mjs` — retire executable paid/mock review, preserve truthful capture/review state and label deferred rubric appropriately.
- `scripts/ci/ecommerce_evidence.cjs`, `scripts/ci/ecommerce_evidence.test.cjs`, `scripts/ci/ecommerce_target.test.cjs`, `examples/scrypath_ecommerce/e2e/helpers/verification-target.mjs` — current evidence/target contracts; verify actual consumers before changing fields.
- `prompts/elixir-opensource-libs-best-practices-deep-research.md`, `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md`, `prompts/phoenix-best-practices-deep-research.md`, `prompts/phoenix-live-view-best-practices-deep-research.md` — applicable minimal-dependency, consumer-DX, HEEx/component and executable-verification guidance; generic old version/tool suggestions are not upgrade instructions.

### Primary sources checked by the research fan-out

- [Tailwind theme namespaces](https://tailwindcss.com/docs/theme), [source detection](https://tailwindcss.com/docs/detecting-classes-in-source-files), [custom styles](https://tailwindcss.com/docs/adding-custom-styles), [z-index](https://tailwindcss.com/docs/z-index) — color-only reset, literal detection limits and utility syntax.
- [daisyUI themes](https://daisyui.com/docs/themes/) and [Phoenix HEEx/components](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html) — current theme/attribute conventions; validate against the repo's vendored/pinned versions.
- [Phoenix routing](https://phoenix.hexdocs.pm/Phoenix.Router.html), [Playwright screenshot comparisons](https://playwright.dev/docs/test-snapshots) — route disposition and matching rendering environments.
- [WCAG 2.2 contrast minimum](https://www.w3.org/TR/WCAG22/#contrast-minimum), [non-text contrast and focus adjacency](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast) — text versus non-text thresholds and bounded exemptions.
- [DTCG Format 2025.10](https://www.w3.org/community/reports/design-tokens/CG-FINAL-format-20251028/), [DTCG Color 2025.10](https://www.w3.org/community/reports/design-tokens/CG-FINAL-color-20251028/) — published typed-token/color structures; no external JSON-schema URL or resolver machinery is assumed.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets and Established Patterns

- No current codebase maps were found. Scoped source reads and the maintained UI-engine inventory grounded the scout; fresh source wins over historical counts.
- Root repository contracts delegate through `Capability` to `Verify.Phase99.run_without_docs/0` and its focused tests. Node is already used in that required job; new maintainer logic belongs outside packaged `lib`.
- The existing checker has dependency-free WCAG math, muted-alpha lockstep and self-tests. Research ran it with reports under `/private/tmp/scrypath-phase185-contrast`: zero AA failures, AAA advisories present, and passing self-test. These are observations of the discussion source, not execution acceptance for Phase 185.
- Additional read-only calculations found current ordinary semantic labels, custom warning/error text and the examined focus-adjacent pairs pass their correct floors. The necessary work is coverage/classification/fail-closed enforcement, not a proposed palette change.
- Ops has a named stacking/token catalog and dynamic utility-reference contracts. Legacy findings include generator markup, token-backed arbitrary values and two inline-style attributes; exact inventory is an implementation input, not an approximate numerical acceptance target.
- Current JSON contains bare values and a separate warm brand palette. Adding a valid Ops subtree alone would leave the whole document invalid. Live CSS already separates light/dark daisyUI blocks and shared `@theme` roles.

### Integration Points and Evidence Limits

- Standalone and host-mounted builds scan different source lists. Both need built/output proof; source-string assertions alone cannot demonstrate unchanged rendering.
- Standalone `/` currently renders the generated template, `/ops` is the real operator entry, and host `/` is the storefront. The selected redirect applies only to standalone routing.
- The paid judge is a local npm/Makefile path, and current aggregation still exposes judge fields despite not invoking it. Remove active wiring coherently while preserving old receipt semantics.
- The retained preview has a pre-existing current-source preflight failure. No preflight, restart, seed, browser capture, implementation test, new hosted run or independent design review was performed by this discussion.

</code_context>

<specifics>
## Specific Ideas

Optimize for the contributor who changes a template and needs one actionable failure, the host integrator who should inherit no new runtime tooling, and operators who rely on stable search/diagnosis/recovery flows. Reuse the existing role/job model (especially inspection/recovery/query jobs); do not conduct another persona workshop or expose checker/token internals in the product UI.

The fan-out considered contributor DX, Phoenix/HEEx conventions, accessibility, source/parser trust, design-system consistency, host boundaries, CI cost, release/evidence provenance and review honesty. Tailwind's explicit token namespaces, DTCG's typed interchange and Playwright's matched rendering environments provide relevant precedents; unrelated cross-language API surveys would not change this phase's decisions.

</specifics>

<deferred>
## Deferred Ideas

Storybook, shared fixtures/adopter twins, LiveView extraction, the generic browser sweep, copy lint and decisions log remain v1.46. New visual baselines, calibrated agent-run pairwise review, surface polish and visible design changes remain v1.47. Adopter APIs remain v1.48. No pending todos matched this phase.

Do not add a replacement judge, broaden to marketing/brand redesign, pursue zero legacy findings, introduce a new required lane, remediate unrelated security debt, refresh/reseed the retained preview without its source protocol, or merge/publish prior work as part of this discussion. Unaccepted Cloak/Cloak Ecto findings and historical debt remain visible in their existing records.

</deferred>

---

*Phase: 185-executable-ui-quality-foundations*
*Discussion complete; implementation and requirement verification remain pending.*
*Next: `$gsd-ui-phase 185`, then `$gsd-plan-phase 185` from `/Users/jon/projects/scrypath`.*
