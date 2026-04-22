# Phase 59: Playbook schema and persistence MVP - Context

**Gathered:** 2026-04-22  
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver **OPS-PB-01** (versioned **`playbook_format` / schema v1**, caps aligned with **`ScrypathOps.SearchPlayground`**, federation-safe **dispatch input** only) and **OPS-PB-03** (single persistence story for the MVP: **portable export/import** of that format, with documented limits and **no secrets** in artifacts). Unit tests cover normalize/validate (and optional stub dispatch) **without** live Meilisearch.

**Explicitly not this phase:** Save/list/load/run **LiveView** (**OPS-PB-02**, Phase 60), nav/IA (**OPS-PB-04**), full stub lifecycle tests + verify matrix closure (**OPS-PB-05**, Phase 61).

</domain>

<decisions>
## Implementation Decisions

### OPS-PB-03 — Persistence MVP

- **D-01:** Ship **portable export/import** as the sole persistence story for v1.14 Phase 59 — **JSON files** on disk (UTF-8), **no** new Ecto repo / Postgres / SQLite **in this phase**. Team-visible “catalog” is **git + tickets + Slack/docs** with attached `.json`, not a live shared DB.
- **D-02:** **Defer** durable server-side storage (Ecto + Postgres/SQLite) until there is an intentional **shared OPSUI deployment** story with **authz** and justified CI/migration/backup cost (**OPSUI-FUT-01** “shared across team members” stays future-facing; v1.14 uses **artifacts**, not multi-tenant rows).
- **D-03:** **List without DB (Phase 60 hint):** optional **`SCRYPATH_OPS_PLAYBOOK_DIR`** (or equivalent) read-only directory listing + **`priv/`** example playbooks are **compatible** with D-01 and do **not** require revisiting OPS-PB-03 as “DB” — still file-backed.
- **D-04 (Secrets / redaction):** Serializer and validator are **allowlist-oriented**. **Reject** (or strip with logged warning only where explicitly specified) keys/patterns associated with transport and host secrets: e.g. **`meilisearch_api_key`**, raw **`Req`** / HTTP client option bags, connection URLs, bearer tokens. Playbooks store **schema module strings**, **index identity** as the app already names them, and **Scrypath-accepted search options** only.
- **D-05 (Path safety):** Never **`Path.expand/1`** on raw user paths for LFI. Import via **upload → temp → parse** or **env-allowlisted** directory only.

### OPS-PB-01 — Envelope, wire format, versioning

- **D-06:** **Wire format:** single JSON object per file/revision; **string keys** at JSON layer; **`playbook_format`** required, **positive integer** (**`1`** for first frozen schema). **Breaking** wire or validation rule changes → increment integer (v2), not semver strings on the document.
- **D-07:** **`mode`:** **`"search"`** \| **`"search_many"`** — determines which dispatch path applies after validation.
- **D-08 — Shape by mode:**
  - **`"search"`:** `schema` (string), `q` (string), `opts` (object) — maps to **`dispatch_search/3`** after atomization + module resolution per existing playground patterns.
  - **`"search_many"`:** `entries` (JSON array of **exactly** triples `[schema, q, opts]` where `schema` is a string (module name) or the string **`":all"`**), plus top-level **`opts`** (object) for **shared** `search_many/2` options — maps to **`dispatch_search_many/2`**. Mirror **public Scrypath option key names** (snake_case strings in JSON → atoms at boundary); **do not** invent parallel camelCase vocabulary.
- **D-09 (Validation policy):** **Strict** at the playbook boundary: **reject** unknown top-level keys, unknown keys inside fixed objects, wrong types, and out-of-range values. **Do not silently clamp** `page.size` or entry counts — surface **`{:error, reason}`** so operators and tests see intent vs **`SearchPlayground`** / library limits.
- **D-10 (Numeric caps):** Align with **`ScrypathOps.SearchPlayground`**: `page.size` **1..50** (library ceiling **50**); multi-search **at most 10** entries / schema breadth per configured **`max_schemas_allowed/0`** semantics. Reuse or call into the same sources of truth as the playground so caps do not drift.
- **D-11 (Decode safety):** **Never** `Jason.decode(..., keys: :atoms!)` on untrusted input. Decode to string-keyed maps; convert to atoms only **after** whitelist validation or via **explicit** small key sets.
- **D-12 (Implementation stack):** One module namespace (exact name at planner discretion, e.g. **`ScrypathOps.Playbook.V1`**) exposing **`decode/1`**, **`encode/1`** (or `to_map/1`), and **`validate/1`** as needed. Prefer **`Jason` + explicit validation** and/or **`Ecto.Changeset` on embedded schemas** for `entries` / `opts` — planner picks smallest diff that yields stable **`{:ok, _} | {:error, _}`** and good errors for Phase 60.

### OPS-PB-01 — Federation / multi-search scope in v1

- **D-13 (IN v1):** Payload is **pure dispatch input** only — sufficient to call **`SearchPlayground.dispatch_search`** / **`dispatch_search_many`** after validation and resolvers. Include **`federation_weight`** on entries when needed; include **`:all`** rows with **`global_schemas`** / **`otp_app`** / **`max_schemas`** / shared **`federation_*`** / **`hydration_timeout`** where **`Scrypath`** already accepts them on the **shared** opts or entries per library rules.
- **D-14 (OUT until v2+):** No stored **response** artifacts as authoritative state: no **`merge_hit_order`**, hit bodies, raw federation blobs, or “last run” snapshots. No **multi-step** workflows, assertions, or runner pipelines. No arbitrary **`req_options`** / full HTTP client overrides. **Byte caps** on `q` and nested option trees: **defer** to a later format unless a concrete footgun appears in dogfood — prefer **strict entry count + strict depth** checks in v1 first.
- **D-15 (Stub / native honesty):** Document that playbooks with **`federation_weight`** require **native** `search_many` behavior — stub adapter paths may raise **`federation_merge_requires_native_search_many`**; CI should use **non-weighted** fixtures or expect that error where testing stub-only paths.

### Documentation (normative spec home)

- **D-16:** Add **`scrypath_ops/docs/playbook-schema-v1.md`** as the **human** normative spec (fields, caps, examples, security). Link it from **`scrypath_ops/docs/operator-ia.md`**.
- **D-17:** Pair with **deep `@moduledoc` + doctests** on the Elixir validator/codec module — executable truth beside prose.
- **D-18:** **Do not** place the normative playbook JSON schema **only** in root **`guides/`** as an ExDoc extra — avoids implying unsupported Hex-level promises for an **ops-only** interchange. README/CONTRIBUTING may add a **short pointer** to the ops doc if needed for discoverability; avoid bulk **`docs_contract_test`** locking of playbook **UI** strings here (**Phase 58** **D-16**).

### Claude's Discretion

- Exact module naming (`Playbook` vs `SavedQuery` etc.), choice between **manual validators** vs **Ecto embeds** for v1, fixture file layout under **`test/`**, and whether Phase 60 uses **download** vs **clipboard** first for export UX.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and planning

- `.planning/REQUIREMENTS.md` — **OPS-PB-01**, **OPS-PB-03** normative text and traceability.
- `.planning/ROADMAP.md` — Phase **59** success criteria.
- `.planning/PROJECT.md` — B2 operator playbooks vision, bounded OPSUI posture.
- `.planning/research/ARCHITECTURE.md` — Playbook data flow, value-object-before-persistence, anti-patterns (no secrets, no hidden Mix).
- `.planning/milestones/v1.10-REQUIREMENTS.md` — **OPSUI-FUT-01** original framing (team-shared saved queries — future-facing for persistence).

### Prior phase context

- `.planning/phases/58-core-library-and-doc-qol-b1/58-CONTEXT.md` — **D-16** doc-contract boundary for playbook UI vs schema doc.
- `.planning/phases/57-evidence-triage-and-b1-scope-lock/57-CONTEXT.md` — Milestone governance / evidence discipline.

### Code (integration and caps)

- `scrypath_ops/lib/scrypath_ops/search_playground.ex` — Page and schema ceilings; **`dispatch_search` / `dispatch_search_many`** seam.
- `scrypath_ops/lib/scrypath_ops/search_playground/adapter.ex` — Adapter contract for stub vs Scrypath.
- `lib/scrypath/multi_search/entries.ex` — Entry normalization, shared vs per-entry keys, federation weight stripping (**read before encoding rules**).
- `guides/multi-index-search.md` — Federation, **`:all`**, **`global_schemas`**, ordering semantics (**authority** for playbook examples).

### Operator IA (Phase 60 will extend)

- `scrypath_ops/docs/operator-ia.md` — Link target for new playbook schema doc.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`ScrypathOps.SearchPlayground`** — Central **`max_page_size_allowed/0`**, **`max_schemas_allowed/0`**, **`validate_page_size/1`**, and adapter **`dispatch_*`**; playbook validation should reuse these constants/functions so limits stay aligned.
- **Stub adapter** (`scrypath_ops/test/support/search_playground_stub_adapter.ex` per requirements evidence) — deterministic tests without Meilisearch.

### Established Patterns

- **Adapter seam** — Playbook “run” in later phases must hit the same adapter path as the playground; Phase 59 focuses on **codec + validation** that feeds those entrypoints.
- **Strict operator bounds** — Playground already fails fast on bad `page.size`; playbooks should match that philosophy (**no silent clamp** on import).

### Integration Points

- Phase **60** **`SearchLive`** / future **`playbook_live`** — consumes validated **`decode`** output to populate assigns and call **`SearchPlayground`**.
- Optional **`mix scrypath_ops.*`** tasks later — import/export can piggyback without pulling DB deps into Hex **`scrypath`**.

</code_context>

<specifics>
## Specific Ideas

- User requested **all four** discuss areas with **parallel subagent research**; decisions above **lock** the synthesized recommendations (export-first persistence, strict JSON **`playbook_format: 1`**, tuple-shaped **`entries`** for multi-search, ops-local **`playbook-schema-v1.md`** + **`@moduledoc`**).
- Analogues explicitly weighed: **Postman** (portable versioned JSON, export-first team bus), **Grafana/Kibana** (DB-backed saved objects drift + coupling — avoided for MVP), **Stripe-style** reference doc next to the product surface that consumes the format.

</specifics>

<deferred>
## Deferred Ideas

- **Durable Ecto persistence** (Postgres or SQLite) and **live multi-user catalog** — when OPSUI is deployed as a shared control plane with authz; not Phase 59.
- **YAML** wire encoding — no dependency today; JSON-only v1 keeps deps and parsers minimal.
- **JSON Schema** file or OpenAPI-style export — optional if playbooks grow; not required for v1 if tests + markdown spec are strong.
- **Response capture / diff tooling** — useful for regression stories; explicitly out of **`playbook_format` 1** payload (**D-14**).

### Reviewed Todos (not folded)

- None — `todo.match-phase` returned no matches.

</deferred>

---

*Phase: 59-playbook-schema-and-persistence-mvp*  
*Context gathered: 2026-04-22*
