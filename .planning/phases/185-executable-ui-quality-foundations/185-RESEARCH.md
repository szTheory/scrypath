# Phase 185: Executable UI Quality Foundations - Research

**Researched:** 2026-10-30  
**Domain:** UI source policy, CSS tokens, static contrast, Phoenix builds and repository CI contracts  
**Confidence:** HIGH for repository seams and locked constraints; MEDIUM for standards-specific details

<user_constraints>
## User Constraints (from CONTEXT.md)

> [VERIFIED: .planning/phases/185-executable-ui-quality-foundations/185-CONTEXT.md:20-64,139-144] The following decisions, discretion area and deferred ideas are copied verbatim from the phase context.

### Locked Decisions

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

### Deferred Ideas (OUT OF SCOPE)

Storybook, shared fixtures/adopter twins, LiveView extraction, the generic browser sweep, copy lint and decisions log remain v1.46. New visual baselines, calibrated agent-run pairwise review, surface polish and visible design changes remain v1.47. Adopter APIs remain v1.48. No pending todos matched this phase.

Do not add a replacement judge, broaden to marketing/brand redesign, pursue zero legacy findings, introduce a new required lane, remediate unrelated security debt, refresh/reseed the retained preview without its source protocol, or merge/publish prior work as part of this discussion. Unaccepted Cloak/Cloak Ecto findings and historical debt remain visible in their existing records.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| UIF-01 | A contributor gets a deterministic required L1 failure for newly introduced raw hex values, arbitrary-value utilities, inline `style=` or literal `z-` utilities outside explicit token authorities; the inventoried legacy baseline can only shrink and a replacement violation cannot hide behind an unchanged count. | Exact multiset scanner, trusted first-parent baseline and Git fixture matrix. [VERIFIED: .planning/REQUIREMENTS.md:53] |
| UIF-02 | An operator sees the same supported light/dark UI after Tailwind's default colour namespace is reset and required black/white entries for daisyUI are restored; spacing and typography defaults remain available, with rendered/build proof of the preserved appearance. | Independent builds and matched disposable rendered evidence. [VERIFIED: .planning/REQUIREMENTS.md:54] |
| UIF-03 | A contributor no longer carries the generator-default `home.html.heex`, with its route/reference disposition documented and supported mounted/standalone operator routes verified. | Standalone redirect and route tests; host storefront and mounted routes remain separate. [VERIFIED: .planning/REQUIREMENTS.md:55] |
| UIF-04 | A contributor's existing required `repository-contracts` command runs the static contrast checker in light and dark themes and fails AA contrast violations, including relevant focus-ring/adjacent-background pairs below 3:1. | Root Mix contract invokes existing checker; focus binding and negative cases. [VERIFIED: .planning/REQUIREMENTS.md:56] |
| UIF-05 | A contributor can inspect valid DTCG-format light/dark `ops` tokens in `brandbook/tokens/tokens.json`, and an executable drift test fails when those values diverge from the live CSS theme tokens. | Published DTCG structures and bounded root ExUnit mirror check. [VERIFIED: .planning/REQUIREMENTS.md:57] |
| UIF-06 | A contributor's browser/review workflows contain no paid OpenAI visual-judge request path or mock-generated assumed pass; remaining entrypoints, environment wiring and documentation truthfully describe deterministic checks and the deferred agent-run review. | Remove current judge producers and consumers; preserve deterministic evidence and immutable receipts. [VERIFIED: .planning/REQUIREMENTS.md:58] |
</phase_requirements>

## Summary

Phase 185 is maintainer tooling and preservation work. Put enforcement behind the existing <code>mix verify.repository_contracts</code> entrypoint, use small helpers without package installs, and keep application edits to the approved CSS reset and standalone redirect. The root command delegates to focused ExUnit tests, which is the natural integration seam. [VERIFIED: dev/mix/tasks/verify/capability.ex:10-11; dev/mix/tasks/verify.phase99.ex:7-15; .planning/phases/185-executable-ui-quality-foundations/185-CONTEXT.md:22-23]

The hard planning problem is baseline trust: a candidate cannot bless its own ledger. Seed from the immutable pre-phase tree, then verify exact scanner output and a shrink-only chain against trusted target first-parent history. Route static contrast and token drift through the same required command. [VERIFIED: .planning/phases/185-executable-ui-quality-foundations/185-CONTEXT.md:30-49]

Current source confirms the standalone generator page is active, the host and standalone build separate Tailwind outputs, and current judge fields still have active producers and test consumers. Remove active judge wiring together and leave archived receipts untouched. Use disposable stacks for matched browser evidence; this research did not operate the retained preview or run implementation checks. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/controllers/page_controller.ex:4-8; scrypath_ops/config/config.ex:51-60; examples/scrypath_ecommerce/config/config.ex:61-70; scripts/ci/ecommerce_evidence.cjs:878-882,912-957; test/mix/tasks/workflow_wiring_test.exs:947-999]

**Primary recommendation:** Add a bounded source-literal scanner and trust-aware ledger to root contract tests; extend the existing contrast checker with correct text/focus roles; add bounded DTCG mirror verification; then make the minimal CSS/route changes and remove active judge wiring. Keep the five required jobs and collect matched evidence only in disposable environments. [VERIFIED: .planning/phases/185-executable-ui-quality-foundations/185-CONTEXT.md:22-23,36-60; CONTRIBUTING.md:225-241]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Literal policy and shrink-only ledger | Repository/CI contract | Node maintainer helper | Required repository-contract capability delegates to focused root tests; not runtime app behavior. [VERIFIED: dev/mix/tasks/verify/capability.ex:10-11; dev/mix/tasks/verify.phase99.ex:7-15] |
| Contrast and token drift | Repository/CI contract | CSS source authority | CSS defines runtime values; root tests verify them and invoke existing Node color math. [VERIFIED: scrypath_ops/assets/css/app.css:23-109; scrypath_ops/assets/css/contrast-pairs.mjs:1-19; .planning/phases/185-executable-ui-quality-foundations/185-CONTEXT.md:22-23,47-49] |
| Tailwind palette reset | Browser/client assets | Standalone and host asset builders | Each app profile builds an independent CSS bundle. [VERIFIED: scrypath_ops/config/config.ex:51-60; examples/scrypath_ecommerce/config/config.ex:61-70; scrypath_ops/mix.exs:95-100; examples/scrypath_ecommerce/mix.exs:64-71] |
| Standalone generator route | Frontend server (Phoenix) | Route tests | The controller renders an embedded page today; route behavior belongs in its controller/router and ConnCase proof. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/controllers/page_controller.ex:4-8; scrypath_ops/lib/scrypath_ops_web/controllers/page_html.ex:7-9; scrypath_ops/test/scrypath_ops_web/controllers/page_controller_test.exs:1-7] |
| Rendered preservation evidence | Browser/test | Disposable containers | Playwright observes built surfaces; capture completeness is not design approval. [VERIFIED: .planning/phases/185-executable-ui-quality-foundations/185-UI-SPEC.md:164-170; examples/scrypath_ecommerce/e2e/ui-review.mjs:12-27,68-89] |
| Judge retirement | Repository/test evidence | Browser developer tooling | Current script, Makefile, package entry, evidence writer and wiring tests mention judge concepts; remove live producer/consumer wiring together. [VERIFIED: examples/scrypath_ecommerce/Makefile:184-219; examples/scrypath_ecommerce/package.json:18-25; scripts/ci/ecommerce_evidence.cjs:878-882,912-957; test/mix/tasks/workflow_wiring_test.exs:947-999] |

## Project Constraints (from AGENTS.md)

- Use plain, direct communication and concise progress updates. Ask only when a decision changes scope, authority, risk, cost or a phase boundary; preserve unresolved safety stops and provide a concrete blocker/next step at handoff. [VERIFIED: AGENTS.md:5-15]
- Preserve the Elixir/Ecto/Phoenix stack, minimal setup, Ecto-first product scope and release-quality posture; this UI phase should not introduce product/backend changes. [VERIFIED: AGENTS.md:24-37]
- Keep changes focused and run CONTRIBUTING's named checks; update .planning/PROJECT.md only for intentional scope or shipped-claim changes. [VERIFIED: AGENTS.md:105-110]
- Keep required CI lean and PR-first for feature-depth work. Use executable or exact-SHA evidence; do not simulate a reviewer or auto-approve trust gates. [VERIFIED: AGENTS.md:114-121]
- Consult relevant local prompt references when planning Phoenix/Elixir changes; keep controllers transport-focused and router declarative. Generic version suggestions in prompts are not upgrade instructions. [VERIFIED: AGENTS.md:28; CITED: prompts/phoenix-best-practices-deep-research.md:39-46,124-133; prompts/phoenix-live-view-best-practices-deep-research.md:3-21]
- Preserve unrelated checkout work and use an explicit absolute working directory. [VERIFIED: AGENTS.md:126-128]
- Follow the named preview checkout and preflight protocol; keep evidence under ui-review-artifacts/, outside Playwright cleanup. Inspect captures/copy and full screen/journey inventory. Captures and passing tests are not a design pass. [VERIFIED: AGENTS.md:130-136]
- Preserve Phoenix 1.8 and Tailwind v4 import/source conventions, existing app.js/app.css bundles and no inline scripts. Reuse imported local components; do not use @apply or add dependencies unless asked. Use HEEx, unique DOM IDs and verified routes; keep the router declarative. [VERIFIED: scrypath_ops/AGENTS.md:8-37,107-143]
- For Elixir test/helper code, avoid list-index and struct-bracket access, bind block-expression results, do not nest modules, do not atomize user input, and use question-mark predicate names. Read Mix task help, avoid deps.clean --all, start test processes with start_supervised! and avoid sleeps/alive polling. No Ecto schema/query or process-supervision change is planned. [VERIFIED: scrypath_ops/AGENTS.md:52-103]
- App edits use the local <code>mix precommit</code> instruction; root contract changes also run the required repository-contract command and changed-scope CONTRIBUTING checks. [VERIFIED: scrypath_ops/AGENTS.md:5; CONTRIBUTING.md:157-162,225-241]

## Standard Stack

### Core

| Tool / library | Version | Purpose | Why standard |
|----------------|---------|---------|--------------|
| Root Elixir/Mix | Project constraint <code>~> 1.17</code>; required CI uses Elixir <code>1.19.0</code>, OTP <code>28.1</code> | Invoke root contract tests and propagate checker failures | Existing Phase99 test spine and required lane. Source values: <code>elixir: "~> 1.17"</code> and <code>with: {elixir-version: "1.19.0", otp-version: "28.1"}</code>. [VERIFIED: mix.exs:10-16; .github/workflows/ci.yml:160-170] |
| Node.js CLI | Existing scripts; local runtime observed <code>v26.10.0</code> | Run scanner, current contrast checker and fixtures | Node tests already run in repository-contracts; no npm package is needed. [VERIFIED: .github/workflows/ci.yml:184-193; local node version output] |
| Tailwind CSS | Both app profiles pin <code>4.1.12</code> | Build standalone and mounted host bundles | Separate configs write to independent app outputs. Source value in each is <code>version: "4.1.12"</code>. [VERIFIED: scrypath_ops/config/config.ex:51-60; examples/scrypath_ecommerce/config/config.ex:61-70] |
| Phoenix / HEEx | Existing ScrypathOps app | Redirect standalone root and prove routes | Current generator view is embedded through PageHTML; its ConnCase test is the route seam. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/controllers/page_html.ex:7-9; scrypath_ops/test/scrypath_ops_web/controllers/page_controller_test.exs:1-7] |
| DTCG token format | Published 2025.10 Format and Color reports | Typed JSON documentation and Ops mirror | Use published reports without runtime resolver/generator. [CITED: https://www.w3.org/community/reports/design-tokens/CG-FINAL-format-20251028/; https://www.w3.org/community/reports/design-tokens/CG-FINAL-color-20251028/] |

### Supporting

| Tool | Purpose | Use |
|------|---------|-----|
| Existing contrast checker | Dependency-free WCAG color math and muted-alpha validation | Extend role/pair coverage and invoke through root contract. [VERIFIED: examples/scrypath_ecommerce/Makefile:148-155; scrypath_ops/assets/css/contrast-pairs.mjs:1-19] |
| Git CLI | Resolve full object IDs and first-parent sequences | Use argv-based process calls and fail if needed history is missing. [CITED: https://git-scm.com/docs/gitrevisions; https://git-scm.com/docs/git-log] |
| Existing Docker/Playwright verification | Build and exercise host/mounted app | Use unique disposable project and artifact roots for matched proof. [VERIFIED: CONTRIBUTING.md:227-241; examples/scrypath_ecommerce/Makefile:157-161] |

### Alternatives Considered

| Instead of | Use | Tradeoff |
|------------|-----|----------|
| CSS parser framework, token build system or package | Bounded readers and fixtures | Keeps syntax explicit; unknown forms fail rather than guessed. [VERIFIED: .planning/phases/185-executable-ui-quality-foundations/185-CONTEXT.md:22,27-32,47-49] |
| CI-only check or optional app lane | Root repository-contract command | Same enforcement locally and in required lane. [VERIFIED: .planning/phases/185-executable-ui-quality-foundations/185-CONTEXT.md:23] |
| New baseline or visual judge | Existing deterministic browser evidence and pending review artifact | No paid call, mock report, visible change or implied approval. [VERIFIED: .planning/phases/185-executable-ui-quality-foundations/185-CONTEXT.md:53-60,139-144] |

**Installation:** None; D-01 prohibits new runtime dependencies and parser frameworks. [VERIFIED: .planning/phases/185-executable-ui-quality-foundations/185-CONTEXT.md:22]

## Package Legitimacy Audit

Not applicable: no external package or package installation is proposed. [VERIFIED: .planning/phases/185-executable-ui-quality-foundations/185-CONTEXT.md:22-23]

## Architecture Patterns

### System Architecture Diagram

~~~mermaid
flowchart LR
  A[Authored HEEx, classes, CSS] --> B[Bounded source discovery]
  B --> C[Stable finding multiset]
  C --> D[Candidate ledger equality]
  D --> E[Trusted first-parent baseline and shrink checks]
  E --> F[Root repository-contract test]
  G[Live CSS themes] --> H[Contrast and bounded token readers]
  I[DTCG JSON] --> H
  H --> F
  F --> J[mix verify.repository_contracts result]
  K[Standalone and host CSS] --> L[Independent Tailwind builds]
  L --> M[Generated bundle assertions]
  M --> F
  L --> N[Disposable matched browser evidence]
~~~

### Recommended Project Structure

Keep maintenance logic outside packaged lib. Capability dispatches to Phase99, which owns the focused ExUnit list. [VERIFIED: dev/mix/tasks/verify/capability.ex:10-11; dev/mix/tasks/verify.phase99.ex:7-15; mix.exs:110-113]

- Root integration: extend dev/mix/tasks/verify.phase99.ex; add root contract tests under test/mix/tasks/; place small Node helpers/fixtures under scripts/ci/. [VERIFIED: dev/mix/tasks/verify.phase99.ex:7-15]
- Literal scanner/ledger: keep them under maintainer tooling; fixtures must be outside discovery. Use D-06 identities, not source lines. [VERIFIED: .planning/phases/185-executable-ui-quality-foundations/185-CONTEXT.md:27-32]
- Contrast: extend examples/scrypath_ecommerce/contrast-checker.mjs and scrypath_ops/assets/css/contrast-pairs.mjs; invoke via root ExUnit. [VERIFIED: examples/scrypath_ecommerce/Makefile:148-155; scrypath_ops/assets/css/contrast-pairs.mjs:15-36]
- Token drift: root ExUnit reads the full DTCG document and only named CSS theme blocks. Do not add runtime resolution. [VERIFIED: .planning/phases/185-executable-ui-quality-foundations/185-CONTEXT.md:47-49]
- App/evidence owners: two source CSS files; PageController/view/template and route test; current evidence writer/tests; judge entrypoint files named in context. [VERIFIED: .planning/phases/185-executable-ui-quality-foundations/185-CONTEXT.md:36-37,53-54]

### Pattern 1: Trusted shrink-only source-literal ratchet

Discover authored files only under approved UI roots. Emit a multiset keyed by rule, repo-relative path, stable source context and exact offending value. Require scanner output to equal candidate ledger; each candidate first-parent ledger must be a subset of its parent; candidate must be a subset of trusted target ledger. Preserve duplicates. [VERIFIED: .planning/phases/185-executable-ui-quality-foundations/185-CONTEXT.md:27-32]

For first introduction, scan the immutable pre-phase tree and require the first committed ledger to equal that output. The source commit is <code>767f368473f17fba43d7be4675c53ab65a87530c</code>. [VERIFIED: .planning/phases/185-executable-ui-quality-foundations/185-CONTEXT.md:31; git cat-file verified the object exists]

| Invocation | Candidate | Trusted comparison source |
|------------|-----------|---------------------------|
| Pull request | Exact event PR head SHA for source scan and candidate first-parent walk; not synthetic merge SHA for PR-head history. | Fetch current target branch from event, resolve full commit ID, record it, then read target first-parent ledger. This catches cleanup merged after stale PR base. |
| Push | Pushed commit; prior is event before-SHA. | Treat absent/all-zero prior as bootstrap or failure, never empty allowlist; verify object and full history. |
| Schedule/manual | Selected workflow commit. | Resolve selected ref and compare prior first-parent commit; schedule uses default branch, dispatch may select another. |
| Local | HEAD. | Require explicit trusted ref or resolvable upstream; missing object/history fails with fetch remedy. |

Git defines revision operators and first-parent traversal. GitHub documents that pull-request GITHUB_SHA normally identifies a merge commit and event payload exposes head/base fields. Resolve trusted ref independently from candidate files, record full OID and fail closed for missing history. [CITED: https://git-scm.com/docs/gitrevisions; https://git-scm.com/docs/git-log; https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows; https://docs.github.com/en/actions/reference/workflows-and-actions/contexts]

**Executable Git fixtures:** Create temporary repositories with System.cmd and argv, never a shell command assembled from refs. Test valid bootstrap; absent/modified bootstrap ledger; added/changed/moved violation; same-count swap; duplicate; edited ledger; comment/line movement preserving identity; stale PR base after target cleanup; candidate later commit that reverses cleanup; side-branch merge; missing ref/object; shallow history. Assert nonzero child status propagates through root required command. [VERIFIED: .planning/phases/185-executable-ui-quality-foundations/185-CONTEXT.md:30-32; CITED: https://owasp.org/www-project-application-security-verification-standard/]

**Scanner boundary:** Explicitly discover HEEx/templates/CSS and static class literals under approved roots, including new files. Exclude generated, vendor, docs and fixture roots. Handle comments, prose, URL fragments, CSS IDs and Elixir syntax as syntax boundaries. Exempt only explicit token declaration sections. Report path/current location/rule/value/repair. No update-to-pass command. Tailwind scans source as text and cannot infer dynamic class construction; document this limit. [VERIFIED: .planning/phases/185-executable-ui-quality-foundations/185-CONTEXT.md:27-32; CITED: https://tailwindcss.com/docs/detecting-classes-in-source-files]

### Pattern 2: Required root command owns checks and failures

The repository-contract capability calls Phase99.run_without_docs, which runs focused ExUnit files. Add UI contract tests there and have them invoke Node checkers with argv arrays, captured output and explicit status checks. CI already runs some Node tests before the Mix command, but that alone does not satisfy the same-local-enforcement decision. [VERIFIED: dev/mix/tasks/verify/capability.ex:10-11; dev/mix/tasks/verify.phase99.ex:7-15; .github/workflows/ci.yml:184-193; .planning/phases/185-executable-ui-quality-foundations/185-CONTEXT.md:23]

Test subprocess propagation with a failing child or mutated disposable fixture through the same contract runner. Fixture-path selection is test-only; production mode checks actual checkout, and candidate files cannot select trusted refs. [VERIFIED: .planning/phases/185-executable-ui-quality-foundations/185-CONTEXT.md:23,31-32]

### Pattern 3: Bounded DTCG mirror and contrast roles

CSS is implementation authority; convert the whole brandbook JSON to typed DTCG and an Ops mirror. Published DTCG 2025.10 defines nested groups, explicit/inherited types, sRGB color objects, dimensions and numbers. Add nested ops/light and ops/dark modes as local convention. Parse supported CSS forms only; reject unknown, duplicate or missing data. Preserve muted-alpha source expression/reference and resolved sRGB value. [VERIFIED: .planning/phases/185-executable-ui-quality-foundations/185-CONTEXT.md:47-49; CITED: https://www.w3.org/community/reports/design-tokens/CG-FINAL-format-20251028/; https://www.w3.org/community/reports/design-tokens/CG-FINAL-color-20251028/]

DTCG defines shadow values as shadow objects or arrays of shadow objects/references and permits a string token type. Preserve CSS “none” as a string token rather than inventing a pseudo-shadow object; assert the mapping in the local validator. [CITED: https://www.w3.org/community/reports/design-tokens/CG-FINAL-format-20251028/]

Attach contrast role to actual content: button/status labels are text; ordinary text raw ratio ≥4.5; demonstrably large text ≥3; meaningful UI/focus cues ≥3 against adjacent surfaces. Cover both themes, warning/error labels, selected/menu surfaces and live outside/inset focus declarations. A changed focus declaration/background must invalidate or recompute its pair. WCAG specifies text and non-text/focus criteria separately; do not round before comparison. [VERIFIED: .planning/phases/185-executable-ui-quality-foundations/185-CONTEXT.md:41-43; CITED: https://www.w3.org/TR/WCAG22/#contrast-minimum; https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast]

### Pattern 4: Matched disposable UI evidence

Use two disposable stacks with unique Compose project names and artifact roots outside Playwright cleanup. Build before/after sources with the same browser/platform, seed, route, state, theme and viewport. The UI spec requires 8 screens × 3 themes × 3 widths (72 observations), plus full-page, hover, focus and compact-navigation evidence. Inspect captures and copy. Test standalone root redirect and host/mounted routes separately. [VERIFIED: .planning/phases/185-executable-ui-quality-foundations/185-UI-SPEC.md:115-124,164-170; examples/scrypath_ecommerce/e2e/ui-review.mjs:12-27,68-89]

Use existing bash verification script or mix verify.ecommerce_mounted against disposable stacks, with separate project/artifact names per source. Keep evidence under ui-review-artifacts/, outside test-results. Playwright screenshots vary with browser/platform/settings; compare in the same environment. The retained preview stop remains intact; disposable captures do not prove its preflight succeeded. [VERIFIED: examples/scrypath_ecommerce/Makefile:157-161; examples/scrypath_ecommerce/e2e/ui-review.mjs:53-66; .planning/phases/185-executable-ui-quality-foundations/185-CONTEXT.md:58-60; CITED: https://playwright.dev/docs/test-snapshots]

### Pattern 5: Retire judge producers and consumers together

Delete the judge script, npm entry, Makefile selector/invocation/status path, active docs and synthetic mock/report path. Update the evidence writer, its tests and wiring tests. Current code emits visual_judge_status/findings/claims/required/skipped_reason and an “Advisory Visual Judge” section. Preserve deterministic case inventory, execution, screenshots/contrast, source and artifact evidence. Keep archived receipts unchanged and do not make old fields fail current validation. [VERIFIED: examples/scrypath_ecommerce/e2e/ops-ui-visual-judge.mjs:138-166,187-215,245-268; examples/scrypath_ecommerce/package.json:18-25; examples/scrypath_ecommerce/Makefile:184-219; scripts/ci/ecommerce_evidence.cjs:878-882,912-957; scripts/ci/ecommerce_evidence.test.cjs:625-641; test/mix/tasks/workflow_wiring_test.exs:947-999; .planning/phases/185-executable-ui-quality-foundations/185-CONTEXT.md:53-54]

## Integration Targets

| Requirement | Existing seam | Planner implication |
|-------------|---------------|---------------------|
| Root gate | Capability dispatches to Phase99; Phase99 owns focused tests. [VERIFIED: dev/mix/tasks/verify/capability.ex:10-11; dev/mix/tasks/verify.phase99.ex:7-15] | Add root ExUnit contract test to that suite; no new CI job. |
| Two CSS outputs | Both apps pin Tailwind and write independent CSS outputs. [VERIFIED: scrypath_ops/config/config.ex:51-60; examples/scrypath_ecommerce/config/config.ex:61-70; scrypath_ops/mix.exs:95-100; examples/scrypath_ecommerce/mix.exs:64-71] | Edit both sources; assert palette removal and retained black/white, semantic, spacing and type utilities in both generated bundles. |
| Root route | PageController renders :home; PageHTML embeds templates; test checks Phoenix tagline. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/controllers/page_controller.ex:4-8; scrypath_ops/lib/scrypath_ops_web/controllers/page_html.ex:7-9; scrypath_ops/test/scrypath_ops_web/controllers/page_controller_test.exs:1-7] | Replace with same-host 302 test; remove template/view; preserve standalone /ops, mounted /admin/search and host /. |
| Judge/evidence | Current Makefile/package entry, evidence fields and wiring assertions refer to judge. [VERIFIED: examples/scrypath_ecommerce/Makefile:184-219; examples/scrypath_ecommerce/package.json:18-25; scripts/ci/ecommerce_evidence.cjs:878-957; test/mix/tasks/workflow_wiring_test.exs:947-999] | Update producer, consumers, tests and active docs together. |
| UI evidence | Capture harness records surfaces/themes/viewports, source identity and pending review, and verifies named container mount. [VERIFIED: examples/scrypath_ecommerce/e2e/ui-review.mjs:12-27,31-66,68-89] | Disposable matched stacks only; no retained-preview operation or baseline update. |

## Don't Hand-Roll

| Problem | Don't build | Use instead | Why |
|---------|------------|-------------|-----|
| WCAG math and muted alpha | Second color engine | Existing checker and pair manifest | They already implement sRGB compositing and alpha lockstep; extend role/focus bindings. [VERIFIED: scrypath_ops/assets/css/contrast-pairs.mjs:1-19; .planning/phases/185-executable-ui-quality-foundations/185-CONTEXT.md:41-43] |
| General CSS/DTCG parser | Full standards implementation | Small bounded reader | Unknown forms should fail; no general parser dependency. [VERIFIED: .planning/phases/185-executable-ui-quality-foundations/185-CONTEXT.md:22,47-49] |
| Tailwind palette removal | Hard-coded utility list | Color namespace reset plus build assertions | Tailwind documents reset and explicit redefinition. [CITED: https://tailwindcss.com/docs/theme] |
| Trusted history | Candidate-selected baseline or count check | Independently resolved Git ref and first-parent multiset comparison | Counts permit swaps and candidate data cannot define authority. [VERIFIED: .planning/phases/185-executable-ui-quality-foundations/185-CONTEXT.md:30-32] |
| Visual judgment | Replacement model or mock reviewer | Deterministic evidence and pending review artifact | Replacement judge is out of scope. [VERIFIED: .planning/phases/185-executable-ui-quality-foundations/185-CONTEXT.md:53-60,139-144] |

**Key insight:** Guarantee findings only decrease under a baseline the branch cannot edit, and that failures reach the local required command. A scanner or report alone does not provide this guarantee. [VERIFIED: .planning/phases/185-executable-ui-quality-foundations/185-CONTEXT.md:23,30-32]

## Common Pitfalls

### Pitfall 1: Candidate-controlled or stale ledger

**What goes wrong:** Same-count replacements or stale PR bases reintroduce old findings.  
**Why:** Comparing scan only with candidate ledger lets the candidate choose authority.  
**How to avoid:** Verify scan equals ledger, compare trusted target and every candidate first-parent snapshot, bootstrap from immutable source, and fail when history is missing.  
**Warning signs:** Empty ledger passes; count-only comparison; candidate file chooses ref; later commit grows ledger. [VERIFIED: .planning/phases/185-executable-ui-quality-foundations/185-CONTEXT.md:30-32]

### Pitfall 2: Scanner false positives and blind spots

**What goes wrong:** IDs/prose/comments/dynamic Elixir match, or new files/dynamic styles escape.  
**How to avoid:** Explicit source discovery, syntax-aware boundaries, explicit authority sections and fixtures for comments, IDs, URL fragments, variants, new files and dynamic attrs. Document runtime-class limits. [VERIFIED: .planning/phases/185-executable-ui-quality-foundations/185-CONTEXT.md:27-32; CITED: https://tailwindcss.com/docs/detecting-classes-in-source-files]

### Pitfall 3: Checks run only in CI or optional app lane

**What goes wrong:** Local root command passes while separate CI-only checks fail.  
**How to avoid:** Put checks in Phase99 focused tests and verify subprocess failure propagation. [VERIFIED: dev/mix/tasks/verify.phase99.ex:7-15; .planning/phases/185-executable-ui-quality-foundations/185-CONTEXT.md:23]

### Pitfall 4: Wrong contrast role or stale adjacency

**What goes wrong:** content labels get a 3:1 UI floor or a changed outline/surface stays paired with stale background.  
**How to avoid:** Bind live focus declarations and tokens to pairs; cover both themes; compare raw ratios; fail on missing/duplicate themes and unknown expressions. Add dark-only and boundary fixtures. [VERIFIED: .planning/phases/185-executable-ui-quality-foundations/185-CONTEXT.md:41-43; CITED: https://www.w3.org/TR/WCAG22/#contrast-minimum; https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast]

### Pitfall 5: Color reset changes one build or other namespaces

**What goes wrong:** Host/standalone bundles diverge, black/white disappears, or spacing/type defaults are lost.  
**How to avoid:** Reset only the color namespace in both source stylesheets; verify generated outputs. [VERIFIED: .planning/phases/185-executable-ui-quality-foundations/185-CONTEXT.md:36; scrypath_ops/config/config.ex:51-60; examples/scrypath_ecommerce/config/config.ex:61-70; CITED: https://tailwindcss.com/docs/theme]

### Pitfall 6: Partially valid DTCG or palettes conflated

**What goes wrong:** Adding Ops leaves legacy JSON invalid or warm brand palette is recolored.  
**How to avoid:** Convert the full document, preserve brand values, map both Ops themes and test exact keys/values in both directions. [VERIFIED: .planning/phases/185-executable-ui-quality-foundations/185-CONTEXT.md:47-49]

### Pitfall 7: Judge removal breaks active or historical evidence

**What goes wrong:** Current validators expect removed fields, or archived receipts fail after cleanup.  
**How to avoid:** Update active writer, consumers, tests and docs together; preserve old receipts and deterministic evidence; leave review pending. [VERIFIED: .planning/phases/185-executable-ui-quality-foundations/185-CONTEXT.md:53-54]

### Pitfall 8: Disposable captures treated as preview approval

**What goes wrong:** Capture completeness is reported as parity or proof the stopped preview is current.  
**How to avoid:** Bind source/state/browser/route/theme/viewport, keep stacks/artifacts separate, and preserve pending status plus D-19 stop. [VERIFIED: .planning/phases/185-executable-ui-quality-foundations/185-CONTEXT.md:58-60; .planning/phases/185-executable-ui-quality-foundations/185-UI-SPEC.md:164-170; CITED: https://playwright.dev/docs/test-snapshots]

## Code Examples

### Git trust primitives

Validate trusted refs as commits and traverse first-parent history. Call Git with an argv array, not a shell string assembled from refs.

~~~sh
git rev-parse --verify --quiet "$TRUSTED_REF^{commit}"
git rev-list --first-parent "$CANDIDATE_OID"
git show "$COMMIT_OID:path/to/ledger.json"
~~~

Git documents these revisions and traversal. ASVS v5.0.0-1.2.5 recommends parameterized OS queries or contextual command-line encoding. [CITED: https://git-scm.com/docs/gitrevisions; https://git-scm.com/docs/git-log; https://asvs.owasp.org/]

### Typed DTCG example

~~~json
{
  "$description": "Illustrative only; not a Scrypath palette change.",
  "ops": {
    "light": {
      "primary": {
        "$type": "color",
        "$value": {
          "colorSpace": "srgb",
          "components": [0.1, 0.2, 0.3],
          "hex": "#1a334d"
        }
      },
      "depth": { "$type": "number", "$value": 1 }
    }
  }
}
~~~

This shows typed DTCG fields and nested modes; values are illustrative only. [CITED: https://www.w3.org/community/reports/design-tokens/CG-FINAL-format-20251028/; https://www.w3.org/community/reports/design-tokens/CG-FINAL-color-20251028/]

### Negative contrast fixture

Copy CSS/token inputs to a temp fixture, mutate one theme token or focus declaration, invoke the same checker as the root contract and assert nonzero status. Include below-threshold ordinary text/focus, dark-only failure, missing theme/token and malformed expression. Compare exact boundaries without rounding. Never mutate app CSS in place. [VERIFIED: .planning/phases/185-executable-ui-quality-foundations/185-CONTEXT.md:42-43]

## State of the Art

| Previous approach | Current approach | Impact |
|-------------------|------------------|--------|
| Assume Tailwind defaults remain available | Reset only color namespace and explicitly retain needed colors | Keep spacing/type independent and assert compiled output. [CITED: https://tailwindcss.com/docs/theme] |
| Treat brandbook bare strings as token interchange | Typed DTCG groups/values while CSS remains authoritative | Convert the full document and validate bounded CSS forms. [CITED: https://www.w3.org/community/reports/design-tokens/CG-FINAL-format-20251028/; https://www.w3.org/community/reports/design-tokens/CG-FINAL-color-20251028/] |
| Keep model judge fields in browser receipt | Remove active fields and describe deterministic scope truthfully | Preserve source/screenshots/evidence without machine-generated approval. [VERIFIED: .planning/phases/185-executable-ui-quality-foundations/185-CONTEXT.md:53-54] |

## Environment Availability

| Dependency | Required by | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Node.js | Existing checker and fixtures | Yes | v26.10.0 | — |
| npm | Demo tooling only; no install planned | Yes | 11.19.1 | No package install |
| Git | Trusted history and source identity | Yes | 2.41.0 | — |
| Docker CLI | Disposable mounted/browser proof | CLI available, daemon not checked | 29.5.2 CLI | Hosted required lane if daemon unavailable |
| Elixir/Mix | Root contract and app builds/tests | asdf shims present; no version selected | CI uses Elixir 1.19.0, OTP 28.1 | Select project toolchain before local Mix verification |
| Browser binary | Playwright captures | Not probed | — | Existing Docker Playwright image |

**Missing dependencies with no fallback:** None for planning. Local Mix execution needs a selected Elixir/OTP toolchain; it was not selected during research. [VERIFIED: local Elixir/Mix version commands returned asdf “No version is set”; .github/workflows/ci.yml:160-170]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Root ExUnit; Node built-in test runner for JavaScript contracts |
| Config file | Root Mix project; focused list in dev/mix/tasks/verify.phase99.ex |
| Quick required command | <code>mix verify.repository_contracts</code> |
| Core local suite | <code>MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors --exclude integration --exclude docs_contract</code> |
| Full mounted proof | <code>mix verify.ecommerce_mounted</code> (Docker-backed required lane) |
| Full browser proof | <code>mix verify.ecommerce_e2e</code> (Docker/browser advisory lane) |

Commands and lane status are in CONTRIBUTING; Phase99 runs focused tests before success. [VERIFIED: CONTRIBUTING.md:157-162,225-241; dev/mix/tasks/verify.phase99.ex:7-48]

### Phase Requirements → Test Map

| Req ID | Behavior | Test type | Automated command | Placement |
|--------|----------|-----------|-------------------|-----------|
| UIF-01 | Rules, exact ledger, bootstrap, target/candidate first-parent shrink-only chain | Root ExUnit with temporary Git/Node fixtures | <code>mix verify.repository_contracts</code> | Root contract plus fixtures under test/mix/tasks and scripts/ci |
| UIF-02 | Both bundles remove palette defaults and retain black/white, semantic, spacing/type | Build-output contract and matched rendered evidence | <code>mix assets.build</code> in both apps; mounted proof | Build assertions plus existing mounted lane |
| UIF-03 | Standalone redirect and supported routes | ConnCase plus mounted route proof | App route test; <code>mix verify.ecommerce_mounted</code> | Replace tagline assertion |
| UIF-04 | Text/focus roles and themes fail raw AA/malformed cases | Root ExUnit invoking Node checker | <code>mix verify.repository_contracts</code> | Checker/pair manifest plus negative fixtures |
| UIF-05 | DTCG validity and exact bidirectional CSS/JSON mirror | Root ExUnit with separate CSS/JSON mutations | <code>mix verify.repository_contracts</code> | Root token drift contract |
| UIF-06 | No active paid/mock judge path or stale consumer | Root wiring tests and Node evidence tests | <code>mix verify.repository_contracts</code>; <code>node --test scripts/ci/ecommerce_evidence.test.cjs</code> | Update writer, package/Makefile/wiring tests and active docs |

### Sampling Rate

- **Per task commit:** focused root/Node contracts and affected route/CSS tests.
- **Per wave merge:** <code>mix verify.repository_contracts</code> and changed-scope <code>mix verify.ecommerce_mounted</code>.
- **Phase gate:** CONTRIBUTING exact-source closeout plus required lanes; rendered records remain pending until genuinely reviewed.

### Wave 0 Gaps

- Add root contracts for scanner/trusted-ledger behavior and subprocess failure propagation.
- Add tests for CSS-only and JSON-only drift plus contrast negative fixtures.
- Add generated-output assertions for both Tailwind builds.
- No new test framework or package install; current focused Phase99 list does not include Phase 185 contracts. [VERIFIED: dev/mix/tasks/verify.phase99.ex:7-15; .planning/phases/185-executable-ui-quality-foundations/185-CONTEXT.md:22-23]

## Security Domain

The Security Domain is included under the research contract's default-enabled rule. This phase changes repository tooling, CSS and a local redirect, not authentication/session/crypto behavior.

| ASVS area | Applies | Standard control |
|-----------|---------|------------------|
| V1 Encoding and Sanitization | Yes: Git/Node subprocess invocation | Fixed executable and argv arrays; no shell interpolation. ASVS v5.0.0-1.2.5 calls for parameterized OS calls or contextual command-line encoding. [CITED: https://asvs.owasp.org/] |
| V2 Validation and Business Logic | Yes: refs, paths, ledger JSON, CSS/token readers | Verify commit objects; constrain paths to repo; reject malformed input and missing history. [CITED: https://github.com/OWASP/ASVS/blob/master/5.0/en/0x11-V2-Validation-and-Business-Logic.md] |
| V3 Web Frontend Security | Limited | Preserve HEEx escaping; same-host fixed redirect with no user-controlled destination; add no inline scripts. [CITED: https://github.com/OWASP/ASVS/blob/master/5.0/en/0x12-V3-Web-Frontend-Security.md] |
| V8 Authorization | Route preservation only | Preserve host auth/mount behavior; do not move mounted routes. [VERIFIED: .planning/phases/185-executable-ui-quality-foundations/185-CONTEXT.md:37,58-60; CITED: https://github.com/OWASP/ASVS/blob/master/5.0/docs_en/OWASP_Application_Security_Verification_Standard_5.0.0_en.json] |
| V6 Authentication / V7 Session / V11 Cryptography | No new behavior | Out of scope for scanner, token mirror and redirect. [VERIFIED: .planning/phases/185-executable-ui-quality-foundations/185-CONTEXT.md:36-49; CITED: https://github.com/OWASP/ASVS/blob/master/5.0/docs_en/OWASP_Application_Security_Verification_Standard_5.0.0_en.json] |

Threat pattern: malicious path/ref or malformed input must not become shell code or select trusted ledger. Use fixed repo root, argv calls, boundary validation and traversal/invalid-ref fixtures. [CITED: https://asvs.owasp.org/]

## Assumptions Log

| # | Claim | Section | Risk if wrong |
|---|-------|---------|---------------|
| A1 | New helper and fixture placement under root test/scripts/ci is the least disruptive layout. | Recommended Project Structure | Low; placement can change within delegated discretion without changing behavior/scope. [ASSUMED] |

## Open Questions

1. No blocking product/maintainer choice remains for planning. Use root contract spine, trusted first-parent refs, bounded readers and disposable matched evidence. [VERIFIED: .planning/phases/185-executable-ui-quality-foundations/185-CONTEXT.md:22-64]
2. The retained preview source/preflight stop is unresolved. Plan disposable stacks separately and do not operate the retained preview; do not proceed with retained-preview work if the stop still applies. [VERIFIED: .planning/phases/185-executable-ui-quality-foundations/185-CONTEXT.md:58-60; .planning/phases/185-executable-ui-quality-foundations/185-UI-SPEC.md:164-170]

## Sources

### Primary repository sources (HIGH confidence)

- .planning/phases/185-executable-ui-quality-foundations/185-CONTEXT.md — locked scope, enforcement, ratchet and evidence decisions.
- .planning/phases/185-executable-ui-quality-foundations/185-UI-SPEC.md — preservation contract, rendered matrix, routes and preview limits.
- .planning/REQUIREMENTS.md:53-58 and .planning/ROADMAP.md:181-210 — requirements, phase goal and delivery limits.
- AGENTS.md, scrypath_ops/AGENTS.md, CONTRIBUTING.md — project conventions, app constraints, checks and CI lanes.
- dev/mix/tasks/verify/capability.ex, dev/mix/tasks/verify.phase99.ex, .github/workflows/ci.yml — required root command and test integration.
- scrypath_ops/assets/css/app.css, scrypath_ops/assets/css/contrast-pairs.mjs, examples/scrypath_ecommerce/contrast-checker.mjs — themes, focus, muted alpha and color math.
- scripts/ci/ecommerce_evidence.cjs, scripts/ci/ecommerce_evidence.test.cjs, test/mix/tasks/workflow_wiring_test.exs, examples/scrypath_ecommerce/e2e/ui-review.mjs — current judge consumers and deterministic evidence.

### Official external sources (MEDIUM confidence via websearch)

- [Tailwind theme namespaces](https://tailwindcss.com/docs/theme) and [source detection](https://tailwindcss.com/docs/detecting-classes-in-source-files) — color reset and literal scanning limits.
- [DTCG Format 2025.10](https://www.w3.org/community/reports/design-tokens/CG-FINAL-format-20251028/) and [DTCG Color 2025.10](https://www.w3.org/community/reports/design-tokens/CG-FINAL-color-20251028/) — typed token structure.
- [WCAG 2.2 contrast minimum](https://www.w3.org/TR/WCAG22/#contrast-minimum) and [non-text contrast](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast) — text and non-text/focus thresholds.
- [Git revisions](https://git-scm.com/docs/gitrevisions) and [Git log](https://git-scm.com/docs/git-log) — revision syntax and first-parent history.
- [GitHub Actions events](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows) and [contexts](https://docs.github.com/en/actions/reference/workflows-and-actions/contexts) — event SHA and PR head/base behavior.
- [Playwright screenshot comparisons](https://playwright.dev/docs/test-snapshots) — comparison environment consistency.
- [OWASP ASVS 5.0.0](https://asvs.owasp.org/) and official [V2 Validation and Business Logic](https://github.com/OWASP/ASVS/blob/master/5.0/en/0x11-V2-Validation-and-Business-Logic.md) / [V3 Web Frontend Security](https://github.com/OWASP/ASVS/blob/master/5.0/en/0x12-V3-Web-Frontend-Security.md) — command, input and frontend controls.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — versions and root CI ownership were read from repository sources; no new package is proposed.
- Architecture: HIGH — task dispatch, app build aliases, route/view and evidence consumers were inspected.
- Pitfalls: HIGH for locked decisions/current source; MEDIUM for event-specific GitHub fetch mechanics, which need fixture-backed validation during planning.

**Research date:** 2026-10-30  
**Valid until:** 2026-11-29 for repository architecture; re-check current target ref and browser/runtime versions at execution.

