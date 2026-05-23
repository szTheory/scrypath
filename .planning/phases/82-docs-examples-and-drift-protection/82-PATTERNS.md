# Phase 82: Docs, examples, and drift protection - Pattern Map

**Mapped:** 2026-05-23  
**Files analyzed:** root docs, guide cluster, example README, CI workflow, docs-contract suite, and docs fixtures  
**Analogs found:** 12 / 12 likely Phase 82 touchpoints

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `guides/request-edge-search.md` or similar new guide | config | request-response | `guides/per-query-tuning-pipeline.md` for narrow canonical-guide posture + `guides/phoenix-liveview.md` for request-edge examples | role-match |
| `README.md` | config | request-response | `README.md` | exact |
| `lib/scrypath.ex` | config | request-response | `lib/scrypath.ex` | exact |
| `guides/overview.md` | config | request-response | `guides/overview.md` | exact |
| `guides/getting-started.md` | config | request-response | `guides/getting-started.md` | exact |
| `guides/golden-path.md` | config | request-response | `guides/golden-path.md` | exact |
| `guides/phoenix-contexts.md` | config | request-response | `guides/phoenix-contexts.md` | exact |
| `guides/phoenix-controllers-and-json.md` | config | request-response | `guides/phoenix-controllers-and-json.md` | exact |
| `guides/phoenix-liveview.md` | config | request-response | `guides/phoenix-liveview.md` | exact |
| `guides/faceted-search-with-phoenix-liveview.md` | config | request-response | `guides/faceted-search-with-phoenix-liveview.md` | exact |
| `examples/phoenix_meilisearch/README.md` | config | request-response | `examples/phoenix_meilisearch/README.md` | exact |
| `test/scrypath/docs_contract_test.exs` | test | request-response | `test/scrypath/docs_contract_test.exs` | exact |

## Pattern Assignments

### `README.md` (root wayfinding, request-response)

**Analog:** `README.md`

**Pattern to preserve:** root docs summarize the product surface, name one canonical next step, and avoid duplicating entire guides inline. Keep new request-edge wording compact and route readers to the canonical guide instead of embedding a mini Phoenix subsystem guide.

**Planner guidance:** update the Phoenix wayfinding and public-surface sections with one explicit request-edge lane. Keep core-first ordering and avoid giving `Scrypath.Phoenix` equal visual weight with `Scrypath.search/3`.

---

### `lib/scrypath.ex` (root moduledoc, request-response)

**Analog:** `lib/scrypath.ex`

**Pattern to preserve:** the moduledoc serves as the ExDoc lobby and points to canonical guides through short “read next” bullets.

**Known drift to remove:** current wording still says `QueryParams` normalizes only the top-level request envelope and that nested values must already match runtime shapes.

**Planner guidance:** replace stale phase-80 language with current request-edge contract wording, then point to the new canonical guide instead of restating detailed browser grammar in the moduledoc.

---

### `guides/overview.md` (guide index, request-response)

**Analog:** `guides/overview.md`

**Pattern to preserve:** one-row-per-guide table with a short role statement. This is the cleanest place to insert a new canonical request-edge guide without reorganizing the entire docs corpus.

**Planner guidance:** add the new guide near `getting-started` / Phoenix onboarding so the route from “what is this?” to “how params flow to contexts” is obvious.

---

### `guides/request-edge-search.md` or similar (new canonical guide, request-response)

**Closest analogs:** `guides/per-query-tuning-pipeline.md`, `guides/phoenix-liveview.md`, `guides/phoenix-controllers-and-json.md`

**Why this is a role match, not an exact analog:** no current guide owns the whole v1.21 request-edge story. The closest pattern is a narrow canonical guide that defines one contract and lets other guides point back to it.

**Planner guidance:** keep the guide short, explicit, and product-shaped:
- browser params normalize once
- `Scrypath.QueryParams` owns plain-data preparation
- `Scrypath.Phoenix` is optional glue
- contexts still call `Scrypath.search/3`
- `%Scrypath.Query{}` is not public API

Use controller and LiveView snippets as small examples, not as separate architecture lanes.

---

### Phoenix guide cluster (role-specific docs, request-response)

**Analogs:** `guides/phoenix-contexts.md`, `guides/phoenix-controllers-and-json.md`, `guides/phoenix-liveview.md`, `guides/faceted-search-with-phoenix-liveview.md`

**Pattern to preserve:** each guide owns one Phoenix role and already uses compile-checked fixture shapes. Keep that structure; only trim shared request-edge explanation and link back to the new guide.

**Planner guidance:** add one concise repeated reminder that helpers stop at params/forms/URLs and contexts remain canonical. Do not let these guides become separate competing descriptions of the public contract.

---

### `examples/phoenix_meilisearch/README.md` + `.github/workflows/ci.yml` (proof/runbook parity, request-response)

**Analogs:** current example README and CI workflow

**Pattern to preserve:** the example README names exact services, env vars, and commands; the CI workflow names the actual jobs and service setup.

**Planner guidance:** add or refine wording that the example is the proof/runbook surface for real services. Keep assertions focused on job name, env vars, and command order parity rather than huge text snapshots.

---

### `test/scrypath/docs_contract_test.exs` (bounded docs contracts, request-response)

**Analog:** `test/scrypath/docs_contract_test.exs`

**Pattern to preserve:** bounded `String.contains?` and ordering assertions over specific public claims.

**Planner guidance:** add narrow assertions for:
- canonical request-edge guide discoverability
- root docs and root moduledoc no longer using stale phase-80 wording
- helpers remaining optional and non-executing
- `%Scrypath.Query{}` staying non-public
- example README / CI / smoke parity

Avoid line-by-line snapshots or enormous anchor counts.

---

### Docs fixtures and helper tests (executable examples, request-response)

**Analogs:** `test/support/docs/phoenix_example_case.ex`, `test/support/docs/phoenix_examples_test.exs`, `test/support/docs/phoenix_request_shape_smoke_test.exs`, `test/scrypath/phoenix_test.exs`

**Pattern to preserve:** executable proof of controller/LiveView helper usage and request-shape semantics.

**Planner guidance:** prefer reusing these files as verification surfaces rather than creating brand-new example frameworks. Only touch them if the docs need a compile-checked snippet or if new contract assertions need one more stable seam.
