# Phase 184: Explicit and lean dependency graphs - Discussion Log

> Audit trail only. Downstream agents use `184-CONTEXT.md`; this log does not substitute for that contract.

**Date:** 2026-10-29
**Phase:** 184-explicit-and-lean-dependency-graphs
**Areas:** core dependency ownership/compatibility; Ops diagnostics/lifecycle; asset delivery; optional Sigra/auth; security/runtime truth; coordinated locks/tooling/Actions; executable proof and scope.

## Interaction and decision authority

The maintainer initially invoked `$gsd-plan-phase 184`. No context existed, and the maintainer chose option 2, discuss first. They then explicitly invoked `$gsd-discuss-phase 184`.

Before an area-selection menu, the maintainer requested that all relevant areas be considered using subagents, reputable primary sources, pros/cons/tradeoffs, ecosystem precedent, stakeholder perspectives and an adversarial pass, with diminishing returns as the stopping condition. They asked for one cohesive recommendation set and said to “auto follow those.” They separately emphasized small, flat dependency trees and preferring a little copied helper code over another dependency.

This explicit delegation replaced the normal area-selection and per-question interactive loops. No fictitious questionnaire responses, individual option approvals, independent-review identity or security-risk approval are recorded. Recommendations selected by the agent remain attributed to delegated engineering judgment. No automatic plan/execute chain was requested or activated.

## Core dependency declarations and Req witnesses

| Alternative considered | Tradeoff | Disposition |
| --- | --- | --- |
| Rely on transitive/optional Telemetry | Smaller-looking manifest, hidden ownership of a called API | Rejected |
| Mandatory direct Telemetry/Req declarations | Explicit installed contract, ordinary ecosystem shape | Selected; D-01/D-02 |
| One locked root build | Fast, only proves one selected Req | Insufficient for two-line compatibility |
| Two root builds | Useful source coverage, still misses delivered package metadata | Supplemental only |
| Two independent consumers of one built archive | Extra bounded compile/resolve time, proves actual delivered resolutions and behavior | Selected; D-03/D-04 |

Retain the approved union bound; use a narrower 0.7.x constraint only as a test witness. Future stable Req minor versions trigger renewed compatibility evidence. Do not add runtime fixture dependencies or an overriding resolver escape hatch.

## Ops diagnostics, mail and application ownership

| Alternative considered | Tradeoff | Disposition |
| --- | --- | --- |
| Runtime-only switches around always-installed diagnostics | Easy startup control, leaves dependency/compile overhead | Rejected |
| Optional host-managed diagnostics | Flexible but adds setup/API/configuration burden for unused functionality | Unnecessary for this phase |
| Direct-source-dev diagnostics with compile/start boundaries | Lean mounted dependency, retained standalone dev dashboard | Selected; D-05–D-07 |
| Remove Swoosh manifest only | Leaves dead config/tests/duplicate host dependencies | Rejected |
| Remove the complete unused mail slice and obsolete locks | More coherent cleanup, preserves packages genuinely needed transitively | Selected; D-05 |

Core telemetry and operator/recovery behavior stay separate from the development metric poller. Host-owned Endpoint/Repo and independently chosen host tooling remain intact.

## Asset build lifecycle

| Alternative considered | Tradeoff | Disposition |
| --- | --- | --- |
| Keep wrappers everywhere with `runtime: false` | Familiar production command, fails strict test/prod dependency exclusion | Rejected |
| New npm/CLI builder | Can omit Mix wrappers universally, duplicates tool/version authority and watcher work | Rejected as unnecessary |
| Existing dev-only Mix wrappers and isolated asset-builder stage | Smallest coherent graph change; requires Docker/entrypoint/docs repair | Selected; D-08/D-09 |

The adversarial pass identified test-runtime asset build calls in the existing entrypoint. Those must be removed after adding a real builder. Copy static output only. Host dev may legitimately retain its own esbuild/Tailwind; do not claim all host-dev tools are absent.

## Sigra compatibility and authentication

| Alternative considered | Tradeoff | Disposition |
| --- | --- | --- |
| Keep patch-only pin | Avoids integration update but does not meet the approved relaxed-range requirement or remove debt | Rejected as default |
| Compatible optional 1.x range | Requires current-release auth verification and explicit integration toolchain | Selected; D-10 |
| Remove/rewrite auth integration | Removes a graph but expands scope and changes supported integration | Deferred |
| Allow requested Sigra mode to use missing-dependency/context fallbacks | Configuration can appear valid while a sensitive callback is permitted | Rejected; D-11/D-12 |

The research established Sigra's Elixir 1.18 floor, not an OTP-27 consumer floor. The latter was an interim over-inference from an upstream developer toolchain and was corrected before writing canonical decisions. Preserve core compatibility policy and use verified tuples. The permissive fallback was source-inspected; no remote exploit was demonstrated.

## Upgrade set, advisories and runtime support

| Alternative considered | Tradeoff | Disposition |
| --- | --- | --- |
| Sequential stale bot merges/global unlock | Convenient but conflicting root-only locks and broad unrelated churn | Rejected |
| Four-graph scoped refresh with per-PR dispositions | More bookkeeping, coherent delivered/source graphs | Selected; D-13–D-16 |
| Suppress remaining Cloak findings | Artificial clean result without removing the affected package | Rejected |
| Report residual findings within approved optional scope | Honest graph/exposure/verification boundaries, no implied risk acceptance | Selected; D-17/D-18 |
| Silently raise the core floor to match a tool/integration | Simplifies one build but changes the approved public contract | Rejected |

All ten specified bot PRs were read through the GitHub connector and were open/unmerged at that snapshot. No comments, closures, merges or other remote mutations were made. Their proposals and recommended dispositions appear in `184-RECOMMENDATIONS.md`.

The security specialist ran the existing four-graph audit on the inspected source using pinned Hex 2.5.1 and temporary homes. Root was clean; the other graphs had affected Bandit, and Ops also had Cloak/Cloak Ecto findings. An initial failed audit setup was excluded from results. The initial Bandit count of eleven was corrected to twelve; no acceptance predicate relies on a mutable advisory count. Fixed-version selection and post-change audits remain future work.

## Verification and product boundaries

Reuse existing required/advisory lanes and verifier seams, exact-source closeout, supported UI/data-preservation rules and the Phase 183 package boundary (D-19–D-21). Existing passing historical evidence does not certify unimplemented dependency changes. No code, lockfile, workflow or visible UI implementation was made during this discussion.

## Research rounds and stopping condition

1. Core consumer specialist: direct declarations, two package consumers, Req range semantics, toolchain/release observations and relevant Ecto/Telemetry/Req precedent.
2. Ops lifecycle specialist: env versus runtime dependency semantics, compile-time references, mail removal, mode matrix and asset alternatives.
3. Security/upgrade specialist: current Sigra metadata, optional auth source paths, all four audit results, upstream fix availability and ten live PRs.
4. Cross-area adversarial pass: reconciled assets/E2E, host-dev ownership, compiler/startup boundaries, metadata versus raw-BEAM assertions, optional auth and support claims.
5. Final synthesis: corrected the unproven OTP inference, preserved advisory/compatibility separation, and selected one consistent recommendation set. Further generic cross-language/design surveys would not change these dependency decisions, so they were stopped.

The specialist scratch reports/audit setup stayed under `/private/tmp/scrypath-phase184-discuss`; canonical decisions, source links, comparisons, findings and limits are preserved in this phase's context and discussion research companion. The scratch directory is not a downstream required reference.

## the agent's Discretion

The maintainer delegated technical selection. Helper names, exact compile directory placement, isolated fixture implementation, scoped update order and revalidated compatible stable versions remain flexible. This does not authorize new product scope, security-risk acceptance, a new support floor, automatic execution/publication or remote PR cleanup.

## Deferred Ideas

Phase 185 and later UI/adopter work, auth replacement, custom crypto, support-floor policy changes, security-risk judgments and release/merge/PR closure actions remain separate. No pending todo matched this phase.
