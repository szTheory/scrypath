# Phase 85: Real-App Proof And Drift Gates - Pattern Map

**Mapped:** 2026-05-23
**Files analyzed:** root docs, ExDoc config, guide cluster, example README, docs contracts, and focused verify tasks
**Analogs found:** 10 / 10 likely Phase 85 touchpoints

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `guides/composing-real-app-search.md` | config | request-response | `guides/request-edge-search.md` for narrow canonical-guide posture + `guides/per-query-tuning-pipeline.md` for bounded semantics authority | role-match |
| `README.md` | config | request-response | `README.md` | exact |
| `guides/overview.md` | config | request-response | `guides/overview.md` | exact |
| `lib/scrypath.ex` | config | request-response | `lib/scrypath.ex` | exact |
| `guides/request-edge-search.md` | config | request-response | `guides/request-edge-search.md` | exact |
| `guides/faceted-search-with-phoenix-liveview.md` | config | request-response | `guides/faceted-search-with-phoenix-liveview.md` | exact |
| `guides/multi-index-search.md` | config | request-response | `guides/multi-index-search.md` | exact |
| `guides/jtbd-and-user-flows.md` | config | request-response | `guides/jtbd-and-user-flows.md` | exact |
| `test/scrypath/docs_contract_test.exs` | test | request-response | `test/scrypath/docs_contract_test.exs` | exact |
| `lib/mix/tasks/verify.phase85.ex` | utility | batch | `lib/mix/tasks/verify.phase84.ex` | exact |

## Pattern Assignments

### `guides/composing-real-app-search.md` (new canonical guide, request-response)

**Closest analogs:** `guides/request-edge-search.md`, `guides/per-query-tuning-pipeline.md`

**Why this is a role match, not an exact analog:** no current guide owns the full v1.22 composition + metadata + multi-search real-app story. The closest repo pattern is one canonical guide that freezes a bounded contract and then lets narrower guides consume it.

**Planner guidance:** keep the guide narrow and product-shaped:

- why composition exists after request-edge normalization
- presets vs scopes
- `defaults` vs `fixed`
- metadata as host-rendering support, not generated UI
- `compose_many/2` lowering into existing runtime args
- explicit non-goals

Do not turn it into a second README or a Phoenix-only walkthrough.

### `README.md` (root wayfinding, request-response)

**Analog:** `README.md`

**Pattern to preserve:** root docs stay concise, name the canonical next-step guides, and do not inline a full tutorial for every public seam.

**Planner guidance:** add one short “composition / metadata real-app story” hop near the existing request-edge and JTBD links. Keep the runtime and sync sections compact.

### `guides/overview.md` (guide index, request-response)

**Analog:** `guides/overview.md`

**Pattern to preserve:** one-row-per-guide table plus a simple recommended reading order.

**Planner guidance:** insert the new guide immediately after `request-edge-search.md` in both the table and reading order so the flow from params -> composition is explicit.

### `lib/scrypath.ex` (ExDoc lobby, request-response)

**Analog:** `lib/scrypath.ex`

**Pattern to preserve:** short “Read next” bullets and bounded entrypoint descriptions, not full concept docs.

**Planner guidance:** point `Scrypath.Composition` and `Scrypath.Metadata` to the new guide instead of letting the moduledoc become the canonical authority.

### `guides/request-edge-search.md` (upstream authority handoff, request-response)

**Analog:** `guides/request-edge-search.md`

**Pattern to preserve:** this guide owns the browser params -> `QueryParams` -> context boundary and should not be reopened for milestone-85 semantics.

**Planner guidance:** add only a short “what to do next once request params are normalized” handoff to the new composition guide.

### `guides/faceted-search-with-phoenix-liveview.md` (single-schema proof guide, request-response)

**Analog:** `guides/faceted-search-with-phoenix-liveview.md`

**Pattern to preserve:** concrete Phoenix/LiveView examples, URL-state honesty, and metadata-driven controls without generated widgets.

**Planner guidance:** sharpen the existing metadata section into one flagship proof flow. Keep contexts canonical and use short inline non-goal reminders only where users could misread metadata as generated UI.

### `guides/multi-index-search.md` (multi-schema proof guide, request-response)

**Analog:** `guides/multi-index-search.md`

**Pattern to preserve:** explicit per-schema boundaries, partial failures, and no merged-capability illusion.

**Planner guidance:** sharpen the existing composition section into the second flagship proof flow. Keep per-entry capability differences, `:all` honesty, and ranking/facets non-comparability explicit.

### `guides/jtbd-and-user-flows.md` (mental model, request-response)

**Analog:** `guides/jtbd-and-user-flows.md`

**Pattern to preserve:** product/job framing rather than API-spec detail.

**Planner guidance:** only update the composition flow if needed to point to the new canonical guide; do not duplicate the semantics section there.

### `test/scrypath/docs_contract_test.exs` (bounded docs contracts, request-response)

**Analog:** `test/scrypath/docs_contract_test.exs`

**Pattern to preserve:** bounded `String.contains?/2` and ordering assertions over public claims and canonical links.

**Planner guidance:** add narrow assertions for:

- new guide discoverability
- guide ordering after request-edge
- non-goal strings and host-owned language
- `verify.phase85` wiring

Avoid prose snapshots or giant heading inventories.

### `lib/mix/tasks/verify.phase85.ex` (focused verify task, batch)

**Analog:** `lib/mix/tasks/verify.phase84.ex`

**Pattern to preserve:** no-arg focused test list, docs build, simple error on unexpected args.

**Planner guidance:** keep the task phase-local. Run the minimal prior runtime seams plus docs contracts and docs build. Do not shell out to the example app or call prior verify tasks as black boxes.
