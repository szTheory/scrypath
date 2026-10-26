# Phase 182: Reliable full browser verification and CI caches - Discussion Log

> **Audit trail only.** Do not use as input to planning, research or execution agents.
> Decisions are captured in CONTEXT.md; this log preserves alternatives and selection provenance.

**Date:** 2026-10-26
**Phase:** 182-reliable-full-browser-verification-and-ci-caches
**Areas considered:** full/focused orchestration; preview safety; inventory and evidence; stale assertions; hosted runtime; Docker caches; BEAM caches; negative proof and phase boundaries.

## Authority and method

The maintainer invoked `$gsd-discuss-phase 182`, then explicitly requested research using subagents across all relevant decision points, consideration of pros/cons/footguns and adversarial views, and automatic adoption of coherent recommendations. The maintainer emphasized contributor/adopter DX, idiomatic ecosystem patterns, primary sources, applicable `prompts/` research, current brand authority and a preference for small flat dependency trees.

This direction replaces the skill's ordinary per-option interview for this discussion. No individual choice below is attributed to a maintainer vote. The agent synthesized the selections under that delegation; no approval was simulated. Planning and execution were not automatically chained.

Three `gsd-advisor-researcher` agents investigated browser orchestration, cache safety and evidence integrity. Follow-up critique challenged evidence completeness and cache/model parity. Local repository evidence was combined with current official Docker, Playwright, GitHub, Mix and setup-beam sources, linked in CONTEXT.md. This is research and an adversarial synthesis, not a formal independent code/design review, test pass or release assessment.

## Full versus focused service ownership

| Option | Pros and tradeoffs | Selected |
|--------|--------------------|----------|
| Full-only existing Phase173 Compose overlay | Reuses current fixtures, service health and one disposable project; needs merged-model/readiness proof | Yes |
| Separate standalone command | Useful for focused debugging, but cannot substitute for one complete canonical full proof | No |
| New fixture/test platform | Adds a second architecture before the approved v1.46 migration | Deferred |

**Selection:** Keep focused unchanged; full includes both fixture routes and checks readiness before browser execution. Preserve Docker-only local Make commands and project-owned cleanup.

## Guards and case inventory

| Option | Pros and tradeoffs | Selected |
|--------|--------------------|----------|
| Consistent hostname-aware guard plus collected/runtime reconciliation | Docker port 4002 executes while the retained loopback preview is refused; requires outcome-level checking because runtime skips are not visible in listing | Yes |
| Remove guards | Fewer skipped tests, but could mutate retained preview data | No |
| Keep port-only guard or freeze historical counts | Simple, but skips Docker cases and preserves contradictory counts | No |

**Selection:** Follow the existing `ui_baseline` rule, check Docker/preview cases, collect identities and reconcile actual outcomes.

**Observed evidence:** The evidence researcher ran `npm run test:e2e:list` in `/Users/jon/projects/scrypath/examples/scrypath_ecommerce` using installed local Playwright, with success: 189 tests in 20 files. The current targeted suites expand to 7 and 6 cases, not the old 8+6 breakdown; the four Phase173 files expand to 38 mounted/standalone cases. Listing runs no browser tests and establishes no runtime coverage. Recollect from the changed implementation source.

## Full invocation, evidence and artifacts

| Option | Pros and tradeoffs | Selected |
|--------|--------------------|----------|
| One serial full invocation and one strict aggregate | Smallest surface; preserves existing fixture ordering; ties every collected identity to actual results and source/run metadata | Yes |
| Serial partitions with disjoint outputs and strict union | May help measured diagnostics/runtime, but adds report/selection/duplicate hazards | Only if measurement requires it |
| Parallel shards or pass-after-retry | Faster apparent throughput, but shared state and retries can hide failures | No |
| Exit code plus an uploaded directory | Cheap, but does not prove complete tests, reports or provenance | No |

**Selection:** Zero retries; reject unexplained coverage gaps, duplicate/missing outcomes and success with required evidence missing. Wire/correct or coherently replace the unwired legacy aggregator. Copy current-run screenshots, JSON/HTML/traces and Compose diagnostics before teardown; preserve the first failure and report finalization failures.

**Correction during research:** Initial speculation that the later light check invokes Playwright and overwrites the full report was disproved by `package.json` and `admin-light-baseline-check.mjs`. It is Node-only and reads the PNG manifest/dimensions. The current full path has one Playwright invocation. Output-directory clobbering is a hazard only if execution is later partitioned. No current defect or repair is claimed on that false premise.

## Runtime and UI assertion reconciliation

| Option | Pros and tradeoffs | Selected |
|--------|--------------------|----------|
| 30-minute advisory job with inner deadline and measured finalization margin | Honors the approved budget and retains failure artifacts; requires hosted exact-source proof | Yes |
| Raise time beyond 30 minutes, omit cases or retry to green | Avoids addressing the actual budget/coverage problem | No |
| Reconcile stale expected text with current fixture semantics | Preserves supported behavior while fixing obsolete `unknown_module` assertions | Yes |
| Auto-update a visual baseline or revise UI to satisfy old tests | Can hide behavior/design regressions and exceeds this phase | No |

**Selection:** Full hosted success includes finalization within 30 minutes. Cache proofs can be separate; the successful full run need not itself be cold-cache. No new required job, paid judge, aesthetic approval or manually pending UAT.

## Docker cache transport

| Option | Pros and tradeoffs | Selected |
|--------|--------------------|----------|
| Official Buildx/Bake action, same resolved Compose graph/local context, exact loaded-image handoff | Action manages cache credentials; no registry publication or third-party runtime-token helper; must reconcile project/image tags and avoid duplicate builds | Yes |
| Compose-native GHA cache overlay in the verifier shell | Keeps build invocation close to today, but needs runtime credential exposure/helper and proof that cache directives were honored | Not preferred |
| Separate custom build graph or shared default scope | Simple initial wiring but can drift from runtime or overwrite other image caches | No |

**Selection:** Keep local ordinary Compose builds valid without GHA. CI consumes the verified prebuilt images without rebuilding. Use v2, bounded cache operations, distinct recipe scopes and a controlled full-lane writer; mounted imports. Identical application recipes share output only when built once. Preserve source/lock layer boundaries. Cache-export outages remain visible performance warnings; test/build failures remain failures.

## BEAM caches and cold proof

| Option | Pros and tradeoffs | Selected |
|--------|--------------------|----------|
| Broad fallback for combined `deps`/`_build` | Least YAML but permits cross-lock compiled/NIF/removed-app leftovers | No |
| Download-only fallback; strict graph/toolchain/environment/lock resolved-dependency and compiled cache | More explicit keys, but safely reuses package archives across lock changes and rebuilds incompatible output | Yes |
| No cache | Simplest correctness model but discards the approved reuse benefit | Cold-proof mode only |

**Selection:** Cache known Hex package archives without credentials; verify any Rebar download paths. Key resolved dependencies/compiled output strictly, optionally appending source fingerprint and restoring older sources only under the same compatibility prefix. Preserve source timestamps with corresponding compiled manifests when using a combined strictly keyed archive. Always resolve dependencies and run the normal commands. Isolate no-optional builds, fresh package consumers and PLTs.

**Adversarial refinements:** `deps/` is not automatically pure source: native/generated outputs can live there. A new cache namespace does not prove a cold build if local BuildKit layers survive. A correct builder configuration does not prove GHA export/restore. A cached compilation must not bypass ordinary verification. Use fresh builders/runners or explicit cache-import bypass; do not delete shared caches.

## Agent's Discretion

Names, strict aggregate representation, compatible legacy report paths, source-fingerprint granularity, exact inner timeout margin and current full-SHA official action pins remain implementation choices. Architecture and acceptance invariants are captured in CONTEXT.md. No new application dependency is recommended.

## Deferred Ideas and Handoff

- Maintainer task relocation: Phase 183.
- Dependency pruning/range upgrades/advisories: Phase 184.
- Token/contrast/drift foundation and dormant paid-judge removal: Phase 185.
- Storybook/new fixture engine, surface extraction, visual baselines and polish: later approved milestones.
- Unrelated inherited audit debt, broader matrices, new required gates and product APIs are outside Phase 182.

All five phase requirements remain pending implementation and executable/source-bound verification. No Docker build, browser execution, cache reuse proof or hosted run was performed in this discussion. The only browser-tool command collected cases without executing them. The retained preview and unrelated config edit remain untouched.

Next: `$gsd-plan-phase 182` from `/Users/jon/projects/scrypath` on `planning/v1.45-foundation-ci`. Context may be cleared after the planning records/session pointer are persisted.
