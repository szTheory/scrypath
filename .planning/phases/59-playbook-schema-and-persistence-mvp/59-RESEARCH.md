# Phase 59 — Technical research

**Phase:** Playbook schema and persistence MVP  
**Question:** What do we need to know to plan OPS-PB-01 / OPS-PB-03 well?

## Findings

### Caps and single source of truth

- **`ScrypathOps.SearchPlayground`** exposes **`max_page_size_allowed/0`**, **`max_schemas_allowed/0`**, and **`validate_page_size/1`** — playbook validation must call these (or duplicate their bounds only if unavoidable) so **`page.size`** and schema breadth never drift from the playground (**RESEARCH evidence:** `search_playground.ex` lines 12–71).
- **`Scrypath.MultiSearch.Entries.normalize/2`** defines **`@default_rails`** shared opts, **`@shared_only_federation_keys`**, entry shape **`{schema, text}`** / **`{schema, text, entry_opts}`**, and rejects shared-only keys on entries — decoded playbook **`search_many`** payloads should converge to shapes this function accepts after atomization (**`lib/scrypath/multi_search/entries.ex`**).

### Decode and atom safety

- **Never** `Jason.decode(..., keys: :atoms!)` on operator-supplied JSON — use string keys through validation, then whitelist keys to atoms at the boundary (**59-CONTEXT D-11**).
- Strict unknown-key rejection applies at the playbook envelope and inside fixed objects (**D-09**).

### Wire shape (v1)

- **`playbook_format`:** positive integer, **`1`** for frozen v1 (**D-06**).
- **`mode`:** **`"search"`** or **`"search_many"`** (**D-07**).
- **`search`:** `schema` (string module name), `q` (string), `opts` (object with snake_case string keys mirroring Scrypath opts).
- **`search_many`:** `entries` as JSON array of length-3 arrays **`[schema_string, q_string, opts_object]`**, plus top-level **`opts`** for shared **`search_many/2`** options (**D-08**).

### Security and abuse

- Allowlist opts; reject keys matching secret transport patterns (**D-04**): e.g. **`meilisearch_api_key`**, raw HTTP client bags, bearer tokens, connection URLs.
- Path safety: import only from controlled temp/upload or env-allowlisted dirs — Phase 59 codec can document; file IO may be minimal in this phase if persistence is “format + tests” only (**D-05**).

### Testing without Meilisearch

- **`ScrypathOps.Test.SearchPlaygroundStubAdapter`** implements **`ScrypathOps.SearchPlayground.Adapter`** — optional integration tests can dispatch validated output through the stub (**`test/support/search_playground_stub_adapter.ex`**).
- Primary Phase 59 tests should exercise **`decode` → `validate`** (and **`encode`** round-trip) without live network, per roadmap success criterion (3).

### Documentation home

- Human normative spec: **`scrypath_ops/docs/playbook-schema-v1.md`**; link from **`scrypath_ops/docs/operator-ia.md`** (**D-16**). Avoid root **`guides/`** as sole home for ops-only interchange (**D-18**).

### Persistence choice (locked)

- **Portable JSON files** only for v1.14 Phase 59 — no new Ecto migrations in this phase (**59-CONTEXT D-01**, **D-02**). Record in **REQUIREMENTS** / ops doc with limits and “no secrets in exports.”

## Risks / pitfalls

- **Opts explosion:** Without a tight allowlist, arbitrary nested maps reintroduce secret channels — prefer explicit key sets aligned with **`Scrypath`** public options and federation docs.
- **Silent clamp:** Playbook import must **not** silently adjust **`page.size`** or entry counts — return **`{:error, _}`** like the playground (**D-09**, **D-10**).
- **Federation + stub:** Document **`federation_merge_requires_native_search_many`** behavior for weighted entries under stub (**D-15**).

## Validation Architecture

**Nyquist dimension 8 (feedback sampling):** Execution must keep **`mix test`** green inside **`scrypath_ops`** after each material commit touching playbook code.

| Dimension | Strategy |
|-----------|----------|
| Automated unit | **`cd scrypath_ops && mix test test/scrypath_ops/playbook/`** (or consolidated test path created by Plan 01) — fast ExUnit, no Meilisearch. |
| Regression | Golden JSON fixtures (valid + invalid) checked into **`scrypath_ops/test/support/fixtures/playbooks/`** (or inline **`@moduletag`** data) with assertive error tags. |
| Integration (optional) | One test passing validated tuples through **`SearchPlayground.dispatch_search`** / **`dispatch_search_many`** with **`SearchPlaygroundStubAdapter`** — proves codec output matches adapter seam. |
| Docs | **`mix docs`** not required every task; spot-check **`playbook-schema-v1.md`** examples against **`doctest`** blocks on the codec module. |

**Sampling rule:** After each playbook-module task commit, run **`cd scrypath_ops && mix test`** (full ops suite acceptable; target **&lt; 60s** typical).

## RESEARCH COMPLETE
