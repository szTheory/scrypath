# Phase 85: Real-App Proof And Drift Gates - Research

**Researched:** 2026-05-23
**Domain:** Real-app composition docs, authority hierarchy, and focused drift protection for the v1.22 public story.
**Confidence:** HIGH. Based on the checked-out guides, root docs, example README, phase-local context, and the already-shipped Phase 83/84 runtime/doc surfaces.

<user_constraints>
## User Constraints

- Keep `Scrypath.search/3` and `Scrypath.search_many/2` as the only runtime entrypoints.
- Keep contexts canonical, Phoenix optional, and `%Scrypath.Query{}` internal.
- Teach composition as plain-data lowering, not as a second runtime, schema DSL, or generated UI system.
- Make non-goals explicit: no schema-generated verbs, no public `%Scrypath.Query{}`, no generated widgets, no tenant/authz or related-data promises.
- Keep verification phase-scoped and contributor-runnable rather than broad, noisy reruns of prior milestone work.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DOC-01 | Guides and examples show at least two distinct real-app adoption flows that reduce repeated query glue through the new composition seam while keeping contexts canonical and Phoenix optional. | Use one canonical composition/metadata guide plus two flagship proof flows already latent in the current guides: single-schema faceted Phoenix and multi-schema `search_many/2`. |
| DOC-02 | Docs make the non-goals explicit: no public `%Scrypath.Query{}`, no schema-generated runtime verbs, no generated UI widgets, and no claims that composition solves tenant-safe access or related-data fan-out. | Publish one authority page with a dedicated non-goals section, then add short inline reminders only where readers are likely to overgeneralize. |
| VRFY-01 | Verification fails on composition drift around merge precedence, metadata derivation, `search_many/2` parity, and guide/example contract alignment. | Add one focused `mix verify.phase85` lane that reuses the minimal Phase 83/84 runtime proofs plus tighter docs/example contracts and docs build. |
</phase_requirements>

## Summary

The checked-out repo already contains most of the raw ingredients for Phase 85, but the story is still spread across root docs, JTBD framing, and two guide surfaces that do not yet share one canonical composition authority page. `README.md`, `guides/overview.md`, and `lib/scrypath.ex` already mention `Scrypath.Composition`, `schema_capabilities/1`, and `reflect_search/2`, while `guides/faceted-search-with-phoenix-liveview.md` and `guides/multi-index-search.md` already contain the two proof flows the phase context selected. What is missing is the single guide that explains why these surfaces exist together, what they do in a real app, and what they deliberately do not do. [VERIFIED: `README.md`] [VERIFIED: `guides/overview.md`] [VERIFIED: `lib/scrypath.ex`] [VERIFIED: `guides/faceted-search-with-phoenix-liveview.md`] [VERIFIED: `guides/multi-index-search.md`]

The strongest Phase 85 move is therefore not another runtime addition. It is a docs and verification slice that turns the current pieces into one coherent public lane: request edge -> composition/metadata -> context-owned runtime -> honest UI or multi-search behavior. The new canonical guide should sit immediately after `guides/request-edge-search.md` in ExDoc ordering so users discover it as the next step once request params are normalized. That lets the existing Phoenix and multi-index guides stay role-specific proof surfaces instead of each re-explaining milestone semantics. [VERIFIED: `mix.exs`] [VERIFIED: `guides/request-edge-search.md`] [VERIFIED: `guides/overview.md`]

The two best real-app proofs are already implied by the code and current docs. First: a single-schema Phoenix catalog page that uses metadata-driven honest controls plus reusable presets/scopes while keeping `handle_params/3`, `QueryParams`, and the context boundary explicit. Second: a multi-schema/global search flow that uses `compose_many/2`, entry-scoped reflection, and partial-failure honesty without implying one merged capability graph or universally comparable ranking scale. Those match the locked context and keep the story closer to Flop-style metadata-first DX than to callback-magic search facades. [VERIFIED: `.planning/phases/85-real-app-proof-and-drift-gates/85-CONTEXT.md`] [VERIFIED: `guides/faceted-search-with-phoenix-liveview.md`] [VERIFIED: `guides/multi-index-search.md`]

Verification should stay narrow and phase-local. The repo already has focused `verify.phase83` and `verify.phase84` tasks plus bounded `docs_contract_test.exs` assertions. Phase 85 should add `mix verify.phase85` that runs the minimal prior runtime seams still needed for public-story truth (`composition_test.exs`, `metadata_test.exs`, `composition_many_test.exs`) together with the docs contracts and `mix docs --warnings-as-errors`. That protects precedence, metadata derivation, multi-search parity, and wayfinding/non-goal drift without rerunning unrelated example or live-service paths. [VERIFIED: `lib/mix/tasks/verify.phase83.ex`] [VERIFIED: `lib/mix/tasks/verify.phase84.ex`] [VERIFIED: `test/scrypath/docs_contract_test.exs`]

**Primary recommendation:** plan Phase 85 in three slices:
1. Freeze one canonical composition/metadata real-app guide and its authority hierarchy.
2. Add a focused `verify.phase85` plus bounded docs/example contracts.
3. Implement the guide, sharpen the two flagship proof guides, and make the focused gate green.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Canonical composition + metadata semantics | New guide under `guides/` | `README.md`, `guides/overview.md`, `lib/scrypath.ex` | One page should own the milestone story so root docs and role-specific guides do not drift. |
| Single-schema proof flow | `guides/faceted-search-with-phoenix-liveview.md` | `guides/request-edge-search.md` | The guide already has the right schema, UI, and request-edge posture; it needs sharpening, not replacement. |
| Multi-schema proof flow | `guides/multi-index-search.md` | `guides/jtbd-and-user-flows.md` | The guide already contains composition lowering, partial failures, and entry-scoped honesty. |
| Non-goal and host-owned boundary truth | Canonical new guide | Inline reminders in the two flagship proof guides | One authority section plus selective reminders is clearer than repeated warnings everywhere. |
| Drift protection | `test/scrypath/docs_contract_test.exs` | `mix verify.phase85` | The repo already prefers bounded string/order assertions and focused verify tasks. |

## Standard Stack

### Core

| Library / Module | Purpose | Why Standard |
|------------------|---------|--------------|
| `README.md` | Root wayfinding and public product story | First landing surface for GitHub and Hex readers. |
| `guides/overview.md` | ExDoc guide routing | Clean place to insert the new canonical composition guide in reading order. |
| `lib/scrypath.ex` | ExDoc lobby and bounded public surface summary | Must mirror the canonical guide without restating it in full. |
| `guides/faceted-search-with-phoenix-liveview.md` | Single-schema proof flow | Already contains metadata-driven honest controls and thin LiveView posture. |
| `guides/multi-index-search.md` | Multi-schema proof flow | Already contains `compose_many/2`, partial failures, and scope-honest multi-search semantics. |

### Supporting

| Library / Module | Purpose | When to Use |
|------------------|---------|-------------|
| `test/scrypath/docs_contract_test.exs` | Bounded public-story drift assertions | For wayfinding, non-goal, and canonical-guide authority checks. |
| `lib/mix/tasks/verify.phase83.ex` / `verify.phase84.ex` | Focused verify-task pattern | Copy the same no-args + focused-tests + docs-build posture. |
| `examples/phoenix_meilisearch/README.md` | Real-service proof/runbook surface | Mention as supporting proof only; do not turn it into the canonical composition tutorial. |
| `guides/request-edge-search.md` | Upstream authority for browser params and optional Phoenix glue | Link from the new guide instead of reopening request-edge semantics. |
| `guides/jtbd-and-user-flows.md` | Product framing and cross-guide mental model | Update only where needed to keep the flow map aligned with the new guide. |

## Architecture Patterns

### Pattern 1: One canonical “real-app composition” guide, many narrow consumers

Create one guide that explains:

- why composition exists after `QueryParams`
- presets vs scopes
- `defaults` vs `fixed`
- metadata as host-rendering support
- `compose_many/2` lowering
- milestone non-goals

Then let `README.md`, `guides/overview.md`, `lib/scrypath.ex`, and the two proof guides summarize or link rather than duplicate the whole explanation.

### Pattern 2: Proof flows stay anchored to the existing request-edge and runtime seams

The single-schema story should still show:

- request params / URL state at the web edge
- optional `Scrypath.Phoenix`
- context-owned `Scrypath.search/3`
- metadata for honest controls

The multi-schema story should still show:

- per-entry composition
- `to_search_many_args/1`
- `Scrypath.search_many/2`
- partial-failure and ranking honesty

That preserves one runtime path instead of inventing a docs-only “composition runtime.”

### Pattern 3: Non-goals centralized, then selectively echoed

The dedicated non-goals section should be authoritative. Inline reminders should appear only in the catalog and multi-search proof sections where users might otherwise assume generated UI, merged capabilities, or policy automation.

### Pattern 4: Focused verify task as story gate

`mix verify.phase85` should prove:

- composition precedence still behaves as documented
- metadata derivation still behaves as documented
- multi-search lowering still behaves as documented
- canonical-guide and proof-guide wording/links still behave as documented

It should not become a milestone-wide or service-backed umbrella command.

## Recommended Plan Slices

### Slice 1: Canonical guide and authority freeze

- Add one new canonical guide, likely `guides/composing-real-app-search.md`.
- Rewire `README.md`, `guides/overview.md`, `lib/scrypath.ex`, and possibly `guides/request-edge-search.md` to route readers into it.
- Freeze the exact non-goal language and proof-flow hierarchy.

### Slice 2: Focused verification and docs contracts

- Add `lib/mix/tasks/verify.phase85.ex`.
- Register `"verify.phase85": :test` in `mix.exs`.
- Extend `test/scrypath/docs_contract_test.exs` with narrow assertions for the new guide, non-goals, and guide order.

### Slice 3: Guide implementation and proof tightening

- Fill in the new guide with the canonical composition/metadata story.
- Sharpen `guides/faceted-search-with-phoenix-liveview.md` as the single-schema flagship proof.
- Sharpen `guides/multi-index-search.md` as the multi-schema flagship proof.
- Keep `examples/phoenix_meilisearch/README.md` as a supporting proof/runbook surface only if a small cross-link is needed.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Canonical phase story | A giant README section or repeated prose in every guide | One dedicated composition guide + short wayfinding links | Reduces drift and keeps ExDoc reading order obvious. |
| Real-app proof | A new example app or generated Phoenix helper layer | Existing faceted and multi-index guides | The repo already has the right proof surfaces. |
| Verification | A new sprawling integration suite | `verify.phase85` + bounded docs contracts + minimal prior runtime tests | Faster contributor loop and tighter scope control. |
| Boundary language | Repeating warnings on every page | One non-goals section + short inline reminders | Keeps the docs exact without becoming defensive or noisy. |

## Common Pitfalls

### Pitfall 1: Teaching composition as a second runtime

If the new guide makes it sound like apps “run” `Scrypath.Composition` instead of lowering into `search/3` or `search_many/2`, the phase will widen the public story incorrectly.

### Pitfall 2: Letting Phoenix become the only proof surface

The single-schema flagship flow can be Phoenix-shaped, but the canonical guide still needs to say the seam is framework-agnostic and context-owned.

### Pitfall 3: Implying one merged multi-search capability surface

The multi-search docs must keep entry-scoped metadata and per-schema ranking/facets visible; otherwise the docs will promise a fake global search form the runtime does not expose.

### Pitfall 4: Over-broad verify wiring

If `verify.phase85` shells out to all prior phase verify tasks or to the example integration path, maintainers will get a slow, noisy gate that is harder to trust and maintain.

## Validation Architecture

### Test Framework

- `ExUnit` via focused `mix test` commands
- bounded docs contracts in `test/scrypath/docs_contract_test.exs`
- `mix docs --warnings-as-errors`
- one focused phase task: `mix verify.phase85`

### Phase Requirements -> Test Map

| Requirement | Validation Strategy |
|-------------|---------------------|
| DOC-01 | Assert the new canonical guide exists, is linked from root docs and overview, and the two flagship proof guides keep their role-specific flow language. |
| DOC-02 | Assert non-goal strings and host-owned language stay present in the canonical guide and relevant proof guides. |
| VRFY-01 | Run the minimal prior runtime tests (`composition`, `metadata`, `composition_many`) plus docs contracts and docs build under `mix verify.phase85`. |

## Security Domain

### Applicable Concerns

- public docs overstating policy, authorization, or related-data guarantees
- docs implying generated UI or framework magic
- guide order and wayfinding drifting so users miss the canonical boundary page

### Mitigation Direction

- centralize non-goals and host-owned language
- pin wayfinding and boundary strings in docs-contract tests
- keep the focused verify lane small enough that maintainers actually run it

## Sources

### Primary

- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/PROJECT.md`
- `.planning/STATE.md`
- `.planning/phases/85-real-app-proof-and-drift-gates/85-CONTEXT.md`
- `.planning/phases/84-metadata-reflection-and-multi-search-parity/84-CONTEXT.md`
- `.planning/phases/83-composition-presets-and-scope-contract/83-CONTEXT.md`
- `.planning/milestones/v1.17-phases/68-example-proof-and-support-contract/68-CONTEXT.md`
- `.planning/milestones/v1.17-phases/69-adopter-verify-spine/69-CONTEXT.md`
- `README.md`
- `mix.exs`
- `lib/scrypath.ex`
- `lib/scrypath/composition.ex`
- `lib/scrypath/metadata.ex`
- `guides/overview.md`
- `guides/request-edge-search.md`
- `guides/jtbd-and-user-flows.md`
- `guides/faceted-search-with-phoenix-liveview.md`
- `guides/multi-index-search.md`
- `examples/phoenix_meilisearch/README.md`
- `test/scrypath/docs_contract_test.exs`
- `lib/mix/tasks/verify.phase83.ex`
- `lib/mix/tasks/verify.phase84.ex`

## RESEARCH COMPLETE
