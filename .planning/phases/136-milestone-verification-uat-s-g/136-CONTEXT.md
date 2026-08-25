# Phase 136: Milestone verification & UAT `[S] [G]` - Context

**Gathered:** 2026-06-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 136 delivers the final DUALVERIFY-01 proof for v1.34 Both-Themes Perfection:
the existing ScrypathOps admin UI must be proven end-to-end against the milestone
intent with automated gates, final evidence artifacts, a v1.33 -> v1.34 before/after
gallery, milestone audit, and bounded human UAT.

This is a verification and closeout phase, not another broad polish phase. It may fix
defects discovered by proof only when the defect threatens trust, accessibility, theme
parity, reduced-motion safety, or the stated v1.34 success criteria. Any fix must rerun
the affected proof and recapture the affected evidence. It must not add runtime/library
capabilities, new operator workflows, new navigation IA, new brand-token direction, or
permanent CI topology changes unless required to make the final proof honest.

Primary user/JTBD: a Phoenix/Ecto maintainer or operator asks, "Can I trust search right
now, and where do I go next?" Phase 136 must prove the admin UI supports that job across
Control Room, Posture, Failed Sync, Sync/Drift, Search, and Playbooks in light, dark, and
system-dark contexts without hiding operational truth behind decorative polish.

</domain>

<decisions>
## Implementation Decisions

### 1. Overall closeout strategy
- **D-01:** Use an **evidence-first layered closeout**. The binding shape is Mix/ExUnit
  + LiveView behavior proof for Phoenix-owned behavior, Playwright/axe/computed-style
  proof for browser-owned theme/accessibility/JS behavior, screenshot artifacts for
  visual review, and bounded human UAT for perceptual claims automation cannot judge.
- **D-02:** Do not use automation-only closeout. It would miss the roadmap's before/after
  gallery and human UAT requirements and would under-prove "both themes are perfect"
  as a design-system milestone.
- **D-03:** Do not promote the full Phase 136 browser bundle into permanent required CI
  during this phase. The optional operator UI remains important proof, but the repo's
  release-train posture still treats expensive browser lanes as advisory unless concrete
  adopter evidence or a maintainer decision changes that policy.
- **D-04:** If a must-fix defect is found, Phase 136 may become a fix-and-rerun loop, but
  only for defects that block the closeout thresholds below. Aesthetic nits or future
  evidence improvements are documented as follow-ups.

### 2. Binding proof gates
- **D-05:** Required Elixir/Phoenix gate bundle:
  - root `mix verify.opsui` for the repository contributor/CI parity contract;
  - ScrypathOps app-level `cd scrypath_ops && mix verify.opsui` when the local alias is
    needed to include `opsui.test_a11y`;
  - `cd scrypath_ops && mix precommit` if source changed during Phase 136 or if the planner
    needs final app-level compile/format/test confidence.
- **D-06:** Required browser/token gate bundle:
  - rebuild ScrypathOps assets before browser proof so the mounted ecommerce app uses
    current source, not stale compiled CSS/JS;
  - run `cd examples/scrypath_ecommerce && make contrast`;
  - run Playwright `admin_contrast_matrix`, `admin_surface_depth`, `admin_path_motion`,
    `admin_shell_chrome`, and `admin_screenshot_matrix`;
  - run the mounted ecommerce admin smoke, preferably `npm run test:e2e -- e2e/operator.spec.ts`
    or the existing full smoke if stable.
- **D-07:** Browser proof must run against a source-backed ecommerce server on a known
  `PLAYWRIGHT_BASE_URL`, not an old baked image. Record the boot method, port, seed
  method, asset-build command, and any retries in the report.
- **D-08:** AA failures are hard blockers in light, dark, and system-dark. AAA body findings
  remain advisory/report-only unless they reveal a new trust/readability regression that
  contradicts the Phase 132 baseline.
- **D-09:** Reduced-motion proof is binding. Path-motion and shell-interaction claims must
  still snap to usable end states under `prefers-reduced-motion: reduce`; no decorative
  loops, re-firing LiveView patch keyframes, or hidden motion regressions.
- **D-10:** System-dark is not optional. Even if the screenshot gallery preserves the
  historical 40-shot light/dark shape, system-dark must be proven by the contrast matrix,
  shell/depth/browser checks, and explicit report language that the media-query path was
  exercised without forcing `localStorage["phx:theme"]`.

### 3. Artifact architecture and repository hygiene
- **D-11:** Commit reports and manifests, not generated binary screenshots. Generated PNGs,
  Playwright traces, test-results, `.tmp`, built `scrypath_ops/priv/static/**`, and raw
  browser JSON outputs stay ignored/untracked unless an existing tracked artifact contract
  says otherwise.
- **D-12:** Produce these Phase 136 closeout artifacts:
  - `136-DUALVERIFY-REPORT.md` — exact command transcript summary, environment, gate
    results, AA/AAA summary, reduced-motion status, smoke status, artifact locations,
    and defect/follow-up decisions.
  - `136-ARTIFACT-MANIFEST.json` — generated artifact index with counts, paths, checksums,
    source commit, command provenance, and whether each artifact is committed or generated.
  - `136-BEFORE-AFTER.md` — dark-weighted v1.33 -> v1.34 gallery narrative with paired
    screenshot references and claim-based captions.
  - `136-MILESTONE-AUDIT.md` — requirement-by-requirement audit of v1.34 intent vs. delivery,
    including phases 128-136 and any evidence gaps.
  - `136-UAT.md` — human UAT checklist, findings, sign-off status, and accepted follow-ups.
- **D-13:** The artifact manifest should record the expected historical 40-shot matrix count
  from `admin_screenshot_matrix.spec.ts`: 10 screen-state captures x 2 themes x 2 viewports.
  If the shared theme grid's newer 13-state set is used for other gates, document that it is
  a broader proof substrate, not a silent replacement for the historical gallery count.
- **D-14:** Preserve the historical 40-shot light/dark gallery by default for comparability
  with v1.33. Do **not** promote full system-dark screenshots into the main gallery unless
  a concrete visual drift concern appears. If needed, add a small system-dark contact sheet
  or targeted spot shots as supplemental evidence.
- **D-15:** The before/after gallery is claim-based, not a raw image dump. Each row should
  name the JTBD claim being proven: route orientation, posture trust, failed-sync recovery,
  drift clarity, search exploration, playbook workspace clarity, shell restraint, focus,
  and theme parity.

### 4. Human UAT and closeout thresholds
- **D-16:** Human UAT is bounded and job-based. The reviewer inspects the six operator
  surfaces in dark first, then light parity, then system-dark evidence, asking:
  "Can I tell search posture, the next recovery/explore action, and whether the UI is calm,
  accessible, and trustworthy?"
- **D-17:** UAT must exercise the domain nouns/events/verbs:
  - nouns: Control Room, Posture, Failed Sync, Sync/Drift, Search, Playbooks, command palette,
    theme toggle, flash, focus ring, result row, drift chip, playbook card;
  - events: seed incident/all_green/empty states, navigate, refresh posture, load drift, run
    search, save a playbook, open/close palette and shortcut sheet, toggle system/light/dark;
  - verbs: inspect, recover, explore, refresh, search, compare, close, switch, trust.
- **D-18:** Must-fix before milestone close:
  - any failing required command or browser gate;
  - any AA contrast failure or disabled/suppressed color-contrast rule;
  - focus not visible, obscured, trapped incorrectly, or not returned after modal/palette close;
  - reduced-motion regression or LiveView patch re-firing motion;
  - stale asset proof, wrong server lane, missing seed proof, or screenshot count/checksum mismatch;
  - visual defect that blocks trust, scanability, task orientation, or light/dark/system parity.
- **D-19:** Acceptable follow-ups:
  - small aesthetic nits that do not affect trust, accessibility, scanability, or theme parity;
  - full system-dark screenshot matrix expansion;
  - permanent CI promotion of browser proof;
  - extra gallery automation or artifact upload workflow;
  - broader brand/docs/HexDocs adoption polish unrelated to v1.34's operator UI proof.
- **D-20:** If Phase 136 edits product source to fix a must-fix issue, the report must name
  the defect, source files changed, gates rerun, screenshots recaptured, and whether the
  before/after gallery was regenerated after the fix. No silent proof reuse after source edits.

### 5. Expert-lens recommendations captured from research
- **D-21:** Elixir/Phoenix idiom: keep framework-owned behavior in Mix/ExUnit/LiveView tests;
  use Playwright only for real browser state such as theme cascade, CSS computed values,
  focus behavior, localStorage/theme selection, screenshots, and axe accessibility scans.
- **D-22:** OSS DX idiom: keep required contributor gates lean and deterministic; store generated
  evidence as artifacts/manifests, not committed binary bloat; avoid making optional admin-browser
  proof a branch-protection blocker without explicit release policy.
- **D-23:** Design-system idiom: final visual review should validate accessibility, clarity,
  consistency, performance, resilience, maintainability, restraint, developer ergonomics, and
  brand fit. It should not reopen palette/type/logo choices; v1.35 kept tokens stable and v1.34
  is verifying inherited brand expression.
- **D-24:** User psychology/JTBD: operational UI should reduce uncertainty. The final proof should
  prioritize calm hierarchy, visible next action, evidence readability, and trust-building states
  over decorative "wow" moments.

### Claude's Discretion
- The planner may choose whether `136-DUALVERIFY-REPORT.md` contains a contrast subsection or
  whether a separate `136-CONTRAST-REPORT.md` is worth creating. The required outcome is one
  clear final AA/AAA summary with generated report paths.
- Exact artifact-manifest schema is left to the planner, but it must be machine-readable JSON,
  include checksums/counts, and distinguish generated artifacts from committed reports.
- If existing server boot scripts are already reliable, use them rather than adding a new harness.
  Add a thin Phase 136 proof harness only if it materially reduces missed commands or stale-server risk.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and milestone truth
- `.planning/ROADMAP.md` — Phase 136 goal, DUALVERIFY-01 success criteria, v1.34 ordering rationale.
- `.planning/REQUIREMENTS.md` — v1.34 appendix requirement DUALVERIFY-01 and phase traceability.
- `.planning/STATE.md` — accumulated v1.34 context, Phase 135 completion state, v1.35 token-stability note.
- `.planning/phases/135-shell-chrome-polish-dual-theme-s/135-CONTEXT.md` — Phase 135 boundary and explicit handoff of full gallery/audit/UAT to Phase 136.
- `.planning/phases/135-shell-chrome-polish-dual-theme-s/135-SHELL-CHROME-REPORT.md` — latest shell evidence and report pattern to extend for final closeout.
- `.planning/phases/135-shell-chrome-polish-dual-theme-s/135-04-SUMMARY.md` — Phase 135 final gate results and handoff decisions.
- `.planning/phases/134-under-iterated-surface-polish-dual-theme-s/134-CONTEXT.md` — surface-depth decisions, light parity, system-dark proof, and Phase 136 deferrals.
- `.planning/phases/133-dark-path-motion-expression-r-g/133-CONTEXT.md` — motion boundaries, reduced-motion rules, and Phase 136 gallery/UAT deferral.
- `.planning/phases/132-a11y-contrast-remediation-both-themes-hard-gate-g/132-CONTRAST-REPORT.md` — AA/AAA reporting precedent and Phase 132 contrast baseline.

### Verification code and scripts
- `lib/mix/tasks/verify.opsui.ex` — repository-root ops UI verification task and contributor parity contract.
- `scrypath_ops/mix.exs` — ScrypathOps app aliases: `verify.opsui`, `opsui.test_a11y`, `precommit`, and assets build/deploy tasks.
- `examples/scrypath_ecommerce/Makefile` — ecommerce demo server, contrast, screenshot, and path-motion proof commands.
- `examples/scrypath_ecommerce/package.json` — Playwright scripts for shell, depth, path motion, matrix, contrast, and full e2e.
- `examples/scrypath_ecommerce/e2e/helpers/theme-grid.ts` — explicit light/dark/system-dark theme modes and shared scenario captures.
- `examples/scrypath_ecommerce/e2e/admin_contrast_matrix.spec.ts` — AA hard gate, AAA advisory schema, and report-output pattern.
- `examples/scrypath_ecommerce/e2e/admin_screenshot_matrix.spec.ts` — historical 40-shot matrix and screenshot naming convention.
- `examples/scrypath_ecommerce/e2e/admin_surface_depth.spec.ts` — computed-style surface-depth proof.
- `examples/scrypath_ecommerce/e2e/admin_path_motion.spec.ts` — reduced-motion, shimmer, and patch-refire proof.
- `examples/scrypath_ecommerce/e2e/admin_shell_chrome.spec.ts` — shell chrome, focus, theme-toggle, flash, and command-palette browser proof.
- `examples/scrypath_ecommerce/e2e/operator.spec.ts` — mounted ecommerce admin smoke surface.
- `examples/scrypath_ecommerce/e2e/light-pixel-diff.mjs` — light-baseline diff gate for explicit light-change exceptions.
- `examples/scrypath_ecommerce/contrast-checker.mjs` — fast token-pair contrast checker.
- `scrypath_ops/assets/css/contrast-pairs.mjs` — static contrast manifest and muted-token lockstep gate.

### Design-system and brand authority
- `scrypath_ops/assets/css/DESIGN-TOKENS.md` — live token authority for surface ramp, shadows, glow, motion, focus, copper, and AA rules.
- `brandbook/notes/accessibility-checks.md` — v1.35 contrast and focus rules; newer than `prompts/scrypath-brand-book.md`.
- `brandbook/notes/decision-log.md` — v1.35 decisions to keep palette/type stable and avoid token thrash.
- `brandbook/notes/pressure-test.md` — brand pressure-test: quiet wayfinding, copper/violet role, and no gratuitous product thrash.
- `brandbook/tokens/tokens.json`, `brandbook/tokens/tokens.css`, `brandbook/tokens/daisyui-theme.example.js` — newer brand token package; consult before older prompt when conflicts appear.
- `prompts/scrypath-brand-book.md` — older brand strategy; use only where not superseded by `brandbook/`.

### Local best-practice research prompts
- `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md` — OSS gate, artifact, and release-train guidance.
- `prompts/phoenix-best-practices-deep-research.md` — Phoenix testing and architecture boundaries.
- `prompts/phoenix-live-view-best-practices-deep-research.md` — LiveView behavior testing, JS hooks, focus, async, and component guidance.
- `prompts/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` — system-design, observability, and Phoenix/OTP operational guidance.
- `prompts/elixir-opensource-libs-best-practices-deep-research.md` — public-library DX and least-surprise guidance.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `mix verify.opsui` and `cd scrypath_ops && mix verify.opsui` provide existing ExUnit/LiveView
  verification paths. Use them; do not invent a parallel Elixir gate unless a gap is found.
- `examples/scrypath_ecommerce/e2e/helpers/theme-grid.ts` already models explicit light,
  explicit dark, and system-dark. Reuse it for any new focused browser checks.
- `admin_contrast_matrix.spec.ts` already writes scenario-scoped JSON/Markdown reports and
  separates AA failures from AAA advisory findings.
- `admin_screenshot_matrix.spec.ts` already produces the 40-shot gallery source: 10 screen-states
  x 2 themes x 2 viewports.
- `admin_shell_chrome.spec.ts`, `admin_surface_depth.spec.ts`, and `admin_path_motion.spec.ts`
  already cover the browser-owned claims Phase 136 needs to aggregate.
- `135-SHELL-CHROME-REPORT.md` is the closest report-shape precedent: command table, coverage,
  decision trace, generated-artifact hygiene, and Phase boundary handoff.

### Established Patterns
- Keep custom UI contracts in `.ops-*` selectors and token docs; avoid utility-only proof targets
  for durable chrome/design-system rules.
- Rebuild assets before browser proof. Prior phases found that the ecommerce server can otherwise
  serve stale path-dependency CSS/JS.
- Generated `test-results/`, `.tmp/`, Playwright screenshots, and built static assets are evidence
  artifacts, not source. Commit summaries/manifests instead of binaries.
- AA is hard; AAA body/long-form is advisory/report-only.
- System-dark must be exercised as an OS-color-scheme path with no forced `data-theme="dark"`.
- If any source changes after screenshot/contrast proof, rerun relevant gates and regenerate affected
  artifacts.

### Integration Points
- Phase 136 reports live under `.planning/phases/136-milestone-verification-uat-s-g/`.
- Final milestone archive may later promote or summarize `136-MILESTONE-AUDIT.md` into
  `.planning/milestones/v1.34-MILESTONE-AUDIT.md`; do that through the milestone-completion workflow,
  not prematurely in this phase discussion.
- Browser gates connect through the running ecommerce demo and its `/dev/e2e/seed` scenario API.
- Human UAT connects to generated screenshot/gallery artifacts plus a live click-through of the six
  operator surfaces.

</code_context>

<specifics>
## Specific Ideas

- Subagent research converged on the same recommendation: use a layered, evidence-first closeout;
  do not substitute screenshots for green gates, do not skip human UAT, and do not promote the full
  browser bundle to permanent required CI in this phase.
- The best artifact shape is small and auditable: committed Markdown/JSON summaries plus ignored
  generated evidence. This mirrors GitHub Actions' distinction between artifacts for inspectable
  outputs and caches for reusable dependencies.
- External primary standards consulted by research:
  - Playwright visual comparison and screenshot docs support browser screenshot artifacts and
    stable snapshot naming for visual evidence.
  - Playwright accessibility guidance with `@axe-core/playwright` supports automated scans while
    still requiring manual assessment for issues automation cannot judge.
  - Phoenix/LiveView testing docs support behavior-level LiveView tests for connected UI lifecycle,
    leaving real browser theme/focus/localStorage proof to Playwright.
  - WCAG 2.2 contrast, non-text contrast, focus appearance, and animation/reduced-motion guidance
    support AA/focus/reduced-motion as hard trust gates.
- Gallery guidance: make it dark-weighted because v1.34's thesis is "dark signature + light parity,"
  but always pair dark improvements with light parity and system-dark evidence.
- Microcopy review should verify task nouns and next-action verbs, not rewrite brand voice. The
  operational language should stay concrete and user-facing: inspect, recover, explore, refresh,
  search, compare, close, switch, trust.

</specifics>

<deferred>
## Deferred Ideas

- Full system-dark screenshot matrix promotion — defer unless Phase 136 finds a concrete visual drift
  risk not covered by contrast/shell/depth proof.
- Permanent CI/branch-protection promotion of all browser proof — defer until maintainer policy or
  adopter evidence justifies the cost and flake risk.
- Gallery automation beyond a clear Markdown report + manifest — defer unless manual artifact assembly
  becomes repeatably error-prone.
- Additional brand/HexDocs/website adoption polish — out of scope for v1.34 verification; v1.35 already
  handled brand adoption and token stability.
- New operator workflows, nav IA, runtime search capability, or productized admin expansion — out of
  scope under the Phase 97 scope guard and the v1.34 UI-polish boundary.

</deferred>

---

*Phase: 136-milestone-verification-uat-s-g*
*Context gathered: 2026-06-28*
