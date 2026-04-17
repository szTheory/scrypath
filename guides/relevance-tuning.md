# Relevance tuning (Meilisearch settings)

This guide covers the declarative settings surface Scrypath exposes for Meilisearch relevance and index configuration in v1.3, how those declarations are translated to Meilisearch wire payloads, and how operators can verify that the live index matches what the schema declares.

## The five declarative settings knobs

Scrypath recognizes these snake_case settings keys on `use Scrypath` (each maps to a Meilisearch-native field when translated):

- `synonyms` — map form is passed through; list-of-groups sugar expands bidirectionally unless `one_way: true` is set on the synonym declaration.
- `typo_tolerance` — keyword list or map; becomes `typoTolerance` on the wire.
- `ranking_rules` — list of atoms or strings; becomes `rankingRules`. Meilisearch ships six default rules in a fixed order; see the safety rail below.
- `distinct_attribute` — atom, string, or `nil`; becomes `distinctAttribute`.
- `stop_words` — list of strings; becomes `stopWords`.

Attribute projections (`searchable_attributes`, `sortable_attributes`, `filterable_attributes`, `displayed_attributes`) are also translated to Meilisearch camelCase keys.

## Ranking rules safety rail (TUNE-04)

If a schema declares `ranking_rules:` as a list, Scrypath expects the list to include **all six** Meilisearch defaults unless the schema opts out:

`[:words, :typo, :proximity, :attribute, :sort, :exactness]`

At **compile time**, incomplete lists emit a stderr warning. At **managed reindex** (`Scrypath.reindex/2`), the same condition raises `ArgumentError` before any Meilisearch work begins, unless `ranking_rules_strict?: false` appears in the schema `settings` map (including under `__unrecognized__` when declared that way).

## Verify and drift semantics (TUNE-05)

After settings are applied and the Meilisearch task is waited on, managed reindex performs a **read-back drift check** using the internal settings verification helper (verify applied vs declared).

- Declared settings are `resolve/2` + `translate_settings/1` (wire-shaped map).
- Applied settings are read with the Meilisearch client’s settings GET helper.
- Comparison is **declared-subset-of-applied**: only keys Scrypath declared are compared. Extra keys returned by Meilisearch (for example default `rankingRules` when you did not declare ranking rules) are not treated as drift.
- Drift returns `{:error, {:settings_drift, [{key, declared, actual}]}}` with wire-style keys (typically binary camelCase).
- A missing index maps to `{:error, :index_not_found}` (404 bodies are not propagated).

### Skipping verification (escape hatch)

`:skip_settings_verification?: true` on the reindex opts skips the drift check. This logs a warning and emits `[:scrypath, :reindex, :verify_skipped]` telemetry with `reason: :user_opt_out`. Successful verification is wrapped in a Telemetry span as `[:scrypath, :reindex, :settings_verified]`.

## Per-repo configuration cascade (TUNE-06)

`Scrypath.Config.resolve!/1` merges, in order:

1. `Application.get_env(:scrypath, :defaults, [])` (library-global)
2. Per-repo `Application.get_env(otp_app, repo)[:scrypath]` when `:repo` is present
3. Explicit per-call keyword opts (right wins)

`otp_app` is taken from `Application.get_application(repo)` when not set explicitly. In tests (or other hosts where the repo module is not registered under an application), pass `otp_app: :my_app` alongside `repo:` so the per-repo lookup succeeds.

`settings_merge: :deep` in per-repo config is the common **test-env recipe** for recursive overrides.

## Operator mix tasks

- `mix scrypath.settings.diff MyApp.Post` — compares declared vs applied settings; exit `0` parity, `2` drift, `1` runtime error. Supports `--json`, `--repo`, `--index-prefix`, and other shared runtime switches parsed by the shared operator CLI layer.
- `mix scrypath.settings.read MyApp.Post` — prints the raw applied settings map (pretty `inspect`) for debugging.

See `guides/operator-mix-tasks.md` for the broader operator task catalog.

## `hot_apply` deferral (v1.4)

The `hot_apply` path on the settings module (arity 3) is intentionally stubbed: it always returns `{:error, :hot_apply_disabled}`. Managed reindex is the supported apply path in v1.3; a guarded hot-apply design is deferred to v1.4.
