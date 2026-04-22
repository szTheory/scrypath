# Playbook interchange — `playbook_format` 1

Normative reference for **version 1** saved-search playbooks consumed by **ScrypathOps** (bounded `/ops/search` and future tooling). Executable validation lives in **`ScrypathOps.Playbook.V1`**.

## Versioning

- Each document is a single JSON **object** with **string keys** (UTF-8 on the wire).
- **`playbook_format`** (integer, required): **`1`** for this frozen shape. Breaking validation or wire rules → bump to **`2`**; do not overload semver on the envelope.
- **`mode`** (string, required): **`"search"`** or **`"search_many"`**.

## Modes

### `search` — single schema + query

| Field | Type | Notes |
| ----- | ---- | ----- |
| `playbook_format` | integer | Must be **`1`**. |
| `mode` | string | **`"search"`**. |
| `schema` | string | Ecto schema module name as printed (e.g. **`"MyApp.Post"`**). |
| `q` | string | Search text. |
| `opts` | object | Per-query options only (see **Allowed `opts` keys**). No extra top-level keys. |

### `search_many` — multiple `[schema, q, opts]` entries

| Field | Type | Notes |
| ----- | ---- | ----- |
| `playbook_format` | integer | Must be **`1`**. |
| `mode` | string | **`"search_many"`**. |
| `entries` | array | Each element is a **3**-element JSON array: **`[schema_string, q_string, opts_object]`**. Schema may be **`":all"`** when supported by **`Scrypath.search_many/2`** (see [multi-index-search.md](../../guides/multi-index-search.md)). |
| `opts` | object | **Shared** runtime + search options merged per library rules before each entry’s third-element `opts` is applied (right-biased per key). |

Unknown keys at any fixed level (top-level, inside `opts`, inside `page`, etc.) are **rejected** by the validator — there is **no** silent clamping of `page.size` or entry counts.

## Allowed `opts` keys

### Per-query keys (both modes, and on each `search_many` entry’s third element)

Aligned with **`Scrypath.Options`** `@search_options` — JSON uses **snake_case strings**:

- `facets`, `facet_filter`, `filter`, `sort`, `page`, `per_query`

### Shared-only keys (`search_many` top-level `opts` only)

Also allowed on the **outer** `opts` for **`search_many`** (not inside each entry’s third element):

- `federation_limit`, `federation_offset`, `federation_timeout`, `hydration_timeout`, `max_schemas`, `global_schemas`, `otp_app`

### Per-entry extra (`search_many` entry `opts` only)

- `federation_weight` — JSON number (integer or finite float), when federation merge weights are required.

## Operator metadata (optional)

Optional top-level fields (both **`search`** and **`search_many`**) for catalog display and handoff. Omitted keys are valid; listings treat a missing **`title`** as **Untitled playbook** (UI default, not encoded into JSON).

| Field | Type | Rules |
| ----- | ---- | ----- |
| `title` | string | When present: UTF-8 **byte** length **≤ 200**. |
| `description` | string | When present: UTF-8 **byte** length **≤ 2000**. |
| `tags` | array of strings | When present: **≤ 20** entries; each tag is a non-empty binary with **≤ 64** bytes. |

Unknown top-level keys remain **rejected** — only the keys listed for each mode (including these three) are allowed.

## Caps

Sources of truth in code (defaults align with **`Scrypath.MultiSearch.Entries`**):

- **`page.size`**: validated with **`ScrypathOps.SearchPlayground.validate_page_size/1`** — typically **1** through **`ScrypathOps.SearchPlayground.max_page_size_allowed/0`** (library ceiling **50**, host config may lower it).
- **Entry count** (`search_many`): **`length(entries) ≤ ScrypathOps.SearchPlayground.max_schemas_allowed/0`** (default **10**, host config may lower to **1..10**).

## Federation notes

- **Dispatch-only:** v1 playbooks carry **inputs** to **`dispatch_search`** / **`dispatch_search_many`** after validation — not response bodies, merge traces, or “last run” snapshots.
- **Native vs stub:** entries that set **`federation_weight`** assume **native** `search_many` behaviour; stub adapter paths may raise **`federation_merge_requires_native_search_many`**. Prefer **non-weighted** fixtures in stub-only CI unless you assert that error on purpose. See phase context **D-15** honesty rule.

## Banned / secret keys (D-04)

Do **not** place transport secrets or raw HTTP client bags in playbook JSON. The codec rejects these keys **anywhere** under `opts` (including nested objects), including:

- `meilisearch_api_key`
- `req_options`
- `meilisearch_url`
- `meilisearch_client`

Also reject other **`Scrypath.Options`** runtime keys not explicitly allowlisted above (e.g. `backend`, `repo`, `sync_mode`, `oban*`, …). Playbooks should reference **schema module strings** and **Scrypath-accepted search options** only.

## Security posture (threat model)

- **Unstructured secrets:** **`q`**, **`title`**, **`description`**, and **`tags`** are plain strings; reviewers should treat pasted tokens like any other committed prose. **`validate/1`** does **not** silently redact or rewrite them.
- **Git history:** JSON in repos is durable; never rely on “remove the key later” for secrets.
- **`/ops` exposure:** Putting the operator UI on a network is a **host** concern (TLS, auth, network policy); see **`operator-ia.md`** (*Securing `/ops`*).
- **Validation vs sanitize:** **`V1.validate/1`** is **fail-closed** (reject). A hypothetical sanitize/import path must be a **separate** API that returns explicit warnings — it must **not** change **`validate/1`** semantics silently.

## Persistence

**v1.15** defines **one** authoritative persistence path for operator playbooks: **UTF-8 JSON
files** under a **single configured workspace directory** (see **`SCRYPATH_OPS_PLAYBOOK_DIR`**
in **`config/runtime.exs`** and **`docs/team-playbook-persistence.md`**). **`ScrypathOps`**
mutates that directory only via **`Playbook.Store`** basename APIs — there is **no**
second live writer (no union of “files + DB”, no read-through cache of another catalog).

- **Team workflow:** git + PR review for flat **`*.json`** files; mount or copy that directory
  in prod as documented in **`team-playbook-persistence.md`**.
- **Ecto / app DB catalog:** **explicitly out of scope for Phase 63** (and not part of the
  v1.15 slice this document tracks). If it is introduced later, it must be an **exclusive**
  mode with explicit import/export semantics — not an ambiguous dual authority.
- **Security:** treat playbooks as **non-secret** operator artifacts — **no API keys,
  bearer tokens, or `req` bags** in committed JSON (see *Banned / secret keys* above and
  git hygiene in **`team-playbook-persistence.md`**).

## Minimal examples

### `search`

```json
{
  "playbook_format": 1,
  "mode": "search",
  "schema": "MyApp.Post",
  "q": "hello",
  "opts": {}
}
```

### `search_many`

```json
{
  "playbook_format": 1,
  "mode": "search_many",
  "entries": [
    ["MyApp.Post", "one", {}],
    ["MyApp.Comment", "two", {}]
  ],
  "opts": {
    "federation_limit": 200
  }
}
```
