# Requirements: Scrypath v1.45 Foundation and CI

**Defined:** 2026-10-26
**Status:** All 21 requirements confirmed by the maintainer on 2026-10-26; four-phase roadmap approved by the maintainer on 2026-10-26; implementation has not started.
**Core Value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

## Scope and provenance

The maintainer confirmed the complete v1.45 scope from section 3 of
`reference/ROLLING-ROADMAP.md` and selected reuse of existing research on
2026-10-26. Inputs are that roadmap, `research/ui-quality-engine/RECOMMENDATIONS.md`
(D4, D6 and the prerequisite build order), its inventory/automation research,
the current repository, CONTRIBUTING.md and the relevant OSS library/release
references under `prompts/`. Existing research is contextual evidence, not a
new ecosystem/version audit. Verify current dependency releases and referenced
Dependabot dispositions during phase planning/execution.

All categories below are within the already confirmed milestone scope. No
unshipped seed adds scope: SEED-001/002 are marked shipped and SEED-003 is
promoted with its storage decision already recorded in PROJECT.md.

## v1.45 Requirements

### Browser coverage and reliable full verification

- [ ] **BROW-01**: A contributor can run the canonical full Docker E2E command and exercise mounted and standalone Ops scenarios in the same isolated, health-checked stack; full scope includes `compose.phase173.yaml`, while focused verification retains its existing service scope and teardown contract.
- [ ] **BROW-02**: A contributor can execute every intended `ui_followup.spec.ts` and `ui_iteration3.spec.ts` case against Docker's `web:4002`; their guards continue to reject the retained local preview, and the collected case inventory explains counts and any intentional skips.
- [ ] **BROW-03**: A maintainer can obtain a successful full scheduled/manual `ecommerce-e2e` run at the changed source SHA within a 30-minute job budget, with complete bounded artifacts and no unexplained skips or retries counted as clean passes; stale expectations are reconciled with current behavior using executable assertions.

### Maintainer tooling and Hex package boundaries

- [ ] **PKGH-01**: An adopter receives no repository-only `verify.*` task source or verification support modules in the Hex archive or compiled dependency; the complete inventoried maintainer task tree lives under `dev/mix/tasks` outside the package allowlist.
- [ ] **PKGH-02**: A contributor can invoke the documented canonical and historical verification commands from the source checkout in their intended environments after the move, while an unpacked package compiles without requiring the absent development tree.
- [ ] **PKGH-03**: A maintainer can run the package/parity gate and prove the actual unpacked archive excludes maintainer tooling while retaining supported public operator tasks and consumer behavior; adding a repository-only task to packaged source fails the gate.

### Explicit and lean dependency graphs

- [ ] **DEP-01**: An adopter receives an explicit root dependency on `telemetry ~> 1.0`, and the existing instrumentation remains available without relying on another dependency to supply it.
- [ ] **DEP-02**: An adopter can resolve and use Scrypath with Req matching `~> 0.6.1 or ~> 0.7`, with focused HTTP/consumer verification for both admitted version lines.
- [ ] **DEP-03**: An operator can run ScrypathOps without Swoosh or the unused Mailer, with their configuration, references and obsolete lock entries removed.
- [ ] **DEP-04**: An adopter can mount ScrypathOps without loading its standalone/development dashboard and telemetry polling/metrics dependencies; the supported standalone/development diagnostics and core Scrypath telemetry still work in their intended modes.
- [ ] **DEP-05**: An adopter can compile/run ScrypathOps in test and production without installing esbuild or Tailwind as Mix dependencies; development asset build commands remain usable.
- [ ] **DEP-06**: An adopter can use the approved compatible Sigra version range without the current patch-series restriction, with the optional integration and relevant auth behavior verified; dependency-audit results remain explicit and are not silenced to obtain a pass.
- [ ] **DEP-07**: A maintainer receives one reconciled dependency update set across affected manifests and lockfiles, with a recorded disposition for the roadmap's referenced Dependabot changes (#65 and #68–#76), supported-stack verification and an explicit account of remaining advisories.

### CI cache reuse

- [ ] **CACHE-01**: A contributor's Docker verification builds can reuse GitHub Actions buildx caches on subsequent runs and still build successfully when the cache is missing.
- [ ] **CACHE-02**: A contributor's BEAM dependency/build jobs can use safe `restore-keys` fallbacks with environment/version-aware keys, while lockfile changes invalidate the appropriate cache and cold-cache runs remain valid.

### UI quality foundations for v1.46

- [ ] **UIF-01**: A contributor gets a deterministic required L1 failure for newly introduced raw hex values, arbitrary-value utilities, inline `style=` or literal `z-` utilities outside explicit token authorities; the inventoried legacy baseline can only shrink and a replacement violation cannot hide behind an unchanged count.
- [ ] **UIF-02**: An operator sees the same supported light/dark UI after Tailwind's default colour namespace is reset and required black/white entries for daisyUI are restored; spacing and typography defaults remain available, with rendered/build proof of the preserved appearance.
- [ ] **UIF-03**: A contributor no longer carries the generator-default `home.html.heex`, with its route/reference disposition documented and supported mounted/standalone operator routes verified.
- [ ] **UIF-04**: A contributor's existing required `repository-contracts` command runs the static contrast checker in light and dark themes and fails AA contrast violations, including relevant focus-ring/adjacent-background pairs below 3:1.
- [ ] **UIF-05**: A contributor can inspect valid DTCG-format light/dark `ops` tokens in `brandbook/tokens/tokens.json`, and an executable drift test fails when those values diverge from the live CSS theme tokens.
- [ ] **UIF-06**: A contributor's browser/review workflows contain no paid OpenAI visual-judge request path or mock-generated assumed pass; remaining entrypoints, environment wiring and documentation truthfully describe deterministic checks and the deferred agent-run review.

## Verification and scope constraints

- Keep the five required jobs (`core`, `package`, `repository-contracts`,
  `backend`, `ecommerce-mounted`) and existing advisory/path-scoped posture.
  Put new deterministic checks in existing lanes. Full browser verification
  remains advisory, but its successful source-bound proof is a milestone
  requirement, not an optional substitute for fixing BROW-01/02.
- Completion uses executable checks or exact-SHA hosted evidence, never pending
  UAT, a simulated reviewer, an auto-updated visual baseline or a paid judge.
  These are future acceptance criteria, not claims that checks have passed.
- Preserve current supported visible UI and retained-preview data. Source/UI
  work must follow AGENTS.md's named-checkout, preflight and review rules.
  Use disposable stacks for test execution; do not seed the retained preview.
- Browser inventory must be collected from actual cases. The rolling roadmap's
  “13 skipped” conflicts with its 8+6 subtotals. Task inventory must include
  nested verification support modules; neither historical approximate count
  is an acceptance target.
- BROW-03 includes reconciling the archived `unknown_module`/`unknown_backend`
  assertion drift where applicable. Preserve historical evidence and verify
  current semantics rather than replacing an unreviewed visual baseline.
- Dependency advisories inherited from v1.44 stay visible. This milestone does
  not pre-accept risk or promise an upstream advisory fix that does not exist.
- Preserve `.planning/config.json` local edits, `my-search.json`, v1.44 archives
  and source-bound receipts. PR #122 merge/publication handling remains separate.
- Serious implementation remains PR-first with full discuss → plan → execute
  → verify lifecycle per phase. Phase numbering starts at 182. Milestone setup
  does not implement or reopen completed phases.

## Future Requirements

Deferred scope remains in the approved rolling roadmap rather than being
silently included in these requirements:

- **v1.46:** Personas/adopter twins, shared fixtures, Storybook, Search health
  and Control room extraction, L2 story sweep, copy lint and decisions log.
- **v1.47:** Remaining UI surfaces, pinned Linux element screenshots, calibrated
  agent-run pairwise review and maintainer-approved visible polish.
- **v1.48:** Testing kit, indexability predicate, highlighting/cropping,
  pagination/facet settings and backfill/reindex public tasks, after API grilling.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Storybook, shared fixture project and composable LiveView extraction | Approved v1.46 work; this milestone supplies prerequisites. |
| New screenshot baselines, review judge replacement or visible redesign | Approved v1.47 work or a separate maintainer design decision. |
| New adopter features or public multi-backend abstraction | Reserved for later approved work; v1.45 is foundation and CI. |
| New required CI jobs, paid AI review or post-implementation manual UAT | Conflicts with the lean verification and no-paid-judge posture. |
| Broad v1.44 debt cleanup or historical phase replay | Only directly overlapping foundation/CI issues belong to this scope. |
| Hex publication or automatic merger of prior milestone work | Separate delivery actions; not implied by milestone initialization. |

## Traceability

The maintainer explicitly approved all requirements and the following roadmap
assignments on 2026-10-26. Implementation has not started.

| Requirement | Phase | Status |
|-------------|-------|--------|
| BROW-01 | Phase 182 | Pending |
| BROW-02 | Phase 182 | Pending |
| BROW-03 | Phase 182 | Pending |
| CACHE-01 | Phase 182 | Pending |
| CACHE-02 | Phase 182 | Pending |
| PKGH-01 | Phase 183 | Pending |
| PKGH-02 | Phase 183 | Pending |
| PKGH-03 | Phase 183 | Pending |
| DEP-01 | Phase 184 | Pending |
| DEP-02 | Phase 184 | Pending |
| DEP-03 | Phase 184 | Pending |
| DEP-04 | Phase 184 | Pending |
| DEP-05 | Phase 184 | Pending |
| DEP-06 | Phase 184 | Pending |
| DEP-07 | Phase 184 | Pending |
| UIF-01 | Phase 185 | Pending |
| UIF-02 | Phase 185 | Pending |
| UIF-03 | Phase 185 | Pending |
| UIF-04 | Phase 185 | Pending |
| UIF-05 | Phase 185 | Pending |
| UIF-06 | Phase 185 | Pending |

**Coverage:** 21 milestone requirements; 21 mapped; 0 unmapped; 0 complete.

---
*Last updated: 2026-10-26 after explicit maintainer confirmation of all 21 requirements; four-phase roadmap approved; 21/21 requirements mapped exactly once.*
