# DEEP Research — Relevance Tuning for Scrypath v1.3

**Domain:** Declarative relevance tuning (synonyms, typo tolerance, ranking rules, distinct attribute, stop words) on `scrypath 0.3.0+`, Meilisearch-first, Ecto-native, Phoenix-friendly
**Researched:** 2026-04-17
**Confidence:** HIGH (recommendations grounded in direct reads of `lib/scrypath/{options,schema,meilisearch/settings,reindex}.ex`, Meilisearch 1.15 settings API references, and named reference libraries: Searchkick, algoliasearch-rails, typesense-rails, Laravel Scout + Meilisearch, Ecto/Ash DSL patterns)
**Scope:** Design research for Phase 19 (Relevance Tuning) — one opinionated recommendation per open question, DX-grounded, backward-compatible with v1.2 public contracts.

---

## Executive Recommendation

v1.3 relevance tuning ships as a **strictly declarative, schema-metadata extension of the existing `settings:` key** — not a parallel `relevance:` concept — applied **only through the managed reindex pipeline** with a mandatory **post-apply read-back verification** before cutover, and **no hot-apply escape hatch** in v1.3.

The five Meilisearch relevance concepts (synonyms, typo tolerance, ranking rules, distinct attribute, stop words) are declared as **structured Scrypath-owned subkeys** of the existing `settings:` map, using **snake_case atoms** for the Elixir-facing surface and **camelCase JSON** only inside `Scrypath.Meilisearch.Settings.translate_settings/1`. Settings-overrides at runtime **shallow-merge by top-level subkey** (each of the five keys is replaced or retained whole), with an **explicit `:deep_merge` opt-in** on the overrides path for the minority of callers who want nested override (e.g., flipping one `typo_tolerance.enabled` flag without restating the min-word-size map).

Ranking rules are the one setting with a **safety rail**: Scrypath **refuses to apply** a `ranking_rules` list that omits `:words`, `:typo`, `:proximity`, `:attribute`, `:sort`, or `:exactness` unless the caller declares `settings: %{ranking_rules_strict?: false}`. Compile-time warning when declared on the schema; reindex-time hard error when declared at runtime override.

**REQ-ID prefix:** `TUNE-`. Chosen to avoid collision with the existing `REL-01..REL-03` release-pipeline IDs and to read cleanly in spec (`TUNE-04: ranking rules safety rail`). Alternatives considered (`RELEV-`, `RTUNE-`, `RX-`) all read worse or collide with existing file prefixes (`RELEASE-` in release scripts).

**The one concrete DX improvement this milestone most needs to land:** a `mix scrypath.settings.diff [Schema]` task that prints the declared-vs-applied diff as a three-column table (key | declared | applied | drift?). Every reference library surveyed either ships something like it (algoliasearch-rails `check_settings`) or has a bug tracker full of requests asking for it. This is the "operator legibility" wedge for relevance tuning.

Phase 19 ships with **4 mix-task additions, 6 REQ-IDs, and zero new public runtime API verbs** beyond `Scrypath.Meilisearch.Settings.hot_apply/3` (deliberately deferred to v1.4 — see question 5).

---

## Reference Library Survey

| Library | Backend | Declaration shape | Synonyms direction | Apply-settings model | Read-back / drift | Lesson for Scrypath |
|---|---|---|---|---|---|---|
| **Searchkick** (ankane/searchkick) | Elasticsearch, OpenSearch | `searchkick search_synonyms: [["pop","soda"],["burger","hamburger"]]` — **list of lists** at the model class level | **Bidirectional by default** (list of equivalence groups); unidirectional via explicit `=>` syntax (`[["iphone => phone"]]`) | `Product.reindex` required after synonym change (v1.x); synonym-file reload on disk for ES 7.3+ as an escape hatch | No first-class read-back; users run their own `Product.search_index.settings` call | **List-of-groups is the ergonomic winner for bidirectional synonyms** — matches how humans think about equivalence classes. Scrypath should accept both the map form (Meilisearch-native) and a list-of-groups form that expands to bidirectional. |
| **algoliasearch-rails** | Algolia | DSL block inside model: `customRanking ['desc(likes_count)']`, `synonyms [...]`, `typoTolerance` | Algolia handles both directions; `oneWaySynonyms` separate type | **"Check settings" before push** — `check_settings` option diffs declared vs applied and only pushes if different | **Built-in drift check** (`check_settings: true` default); 240+ GitHub issues reference the save-then-fetch pattern biting people | **Algolia-style "dirty check" is the best DX pattern** but couples to Meilisearch's limited GET semantics. Scrypath should read-back-verify *after* apply (cheaper, matches managed reindex pipeline) rather than diff-before-apply. |
| **typesense-rails** | Typesense | DSL: `multi_way_synonyms` (hash) + `one_way_synonyms` (hash with `"root"` + `"synonyms"` keys), separate methods | **Explicit split: `multi_way_synonyms` for bidirectional, `one_way_synonyms` for directional** | Collection-level synonym API; v30 uses synonym sets and attaches automatically | None — collection metadata is read directly | **Splitting bidirectional vs one-way into two schema keys is the DX winner**, but Meilisearch's native shape only has one map. Scrypath should accept both shapes at the DSL and translate to the single Meilisearch shape, documenting the expansion. |
| **Laravel Scout + Meilisearch** | Meilisearch | Config file + manual settings-update calls via SDK; no declarative model-level shape | Whatever Meilisearch accepts | Dev must call `updateSettings()` manually; no "apply on deploy" hook | None | **Worst DX of the four reference libs** — the issue tracker explicitly documents users asking for declarative relevance config ([meilisearch-laravel-scout#16](https://github.com/meilisearch/meilisearch-laravel-scout/issues/16)). This is the gap Scrypath v1.3 is deliberately filling for the Phoenix cohort. |
| **Elasticsearch-rails** | Elasticsearch | `settings do ... end` block, `analysis` sub-block, nested Ruby hash | N/A (synonyms via analyzer config) | Call `Model.__elasticsearch__.create_index!(force: true)` or rebuild | None; users write their own compare | **Nested-map with validated subkeys is idiomatic for Ruby** — equivalent to Elixir nested map with NimbleOptions-nested validation. Good DX precedent for Scrypath's structured `settings:` subkeys. |
| **Ecto migrations** | Postgres/MySQL | Declarative migration files, ordered, versioned, one-way-or-rollback | N/A | Migrations are explicit reindex-equivalent events | N/A | **The discipline model**: every settings change that requires a rebuild is conceptually a migration. Scrypath's "declare on schema, flow through `reindex/2`" posture matches this model exactly. Don't ship a "hot patch" verb; that's the equivalent of executing raw SQL against a live table outside the migration system. |
| **Ash framework** | Any | Spark DSL, compile-time validated, capability-based extensions | N/A | Resource + action discipline | Compile-time introspection of all declared capabilities | **Compile-time capability signals are the gold standard** — Ash resources know at compile time what data layers support. Scrypath can adopt a narrower version: compile-time check that every `faceting.attributes` atom is in `filterable`, and that `settings.ranking_rules` is a superset of the mandatory set. |

### Cross-library patterns that matter

1. **Every library that shipped a zero-downtime reindex ships declarative settings that flow through it.** None of them expose "apply settings to live index" as a first-class blessed verb outside escape-hatch territory (Algolia's direct-write-through, Elasticsearch synonym-files). This is not a coincidence — it's the settle point after a decade of collective production pain.

2. **Synonym shape is the one place idiomatic Ruby diverges from native JSON.** All three Ruby libs accept an idiomatic Ruby shape (list-of-arrays, hash-with-root) and translate to their backend's native form. Scrypath should do the same in Elixir.

3. **Drift detection is present in exactly one of the five libraries (algoliasearch-rails).** The other four rely on "we just reindexed, so we know", which is wrong once operators start tweaking settings. **This is Scrypath's differentiation opportunity.**

4. **Ranking-rule safety rails are absent in all five libraries.** Every one trusts the user to know what they're doing. Meilisearch's own documentation warns that omitting `words` ruins search; nobody enforces it. **Scrypath can be the first to ship the guard rail.**

---

## Design Decisions

### Question 1: Declaration shape per setting

#### 1a. Synonyms — **accept both map form (Meilisearch-native) and list-of-groups form (bidirectional sugar), reject list-of-tuples**

**Recommendation:**

```elixir
settings: %{
  synonyms: %{
    # Map form: Meilisearch-native shape, passed through with
    # snake_case→camelCase limited to Meilisearch.Settings
    "nyc" => ["new york", "new york city"],
    "tv" => ["television"]
  }
}

# OR sugar form: list of bidirectional groups
settings: %{
  synonyms: [
    ~w(nyc new\ york "new york city"),   # all equivalent, both directions
    ["tv", "television"]
  ]
}

# Scrypath expands the sugar form internally to the map form:
# %{"nyc" => ["new york", "new york city"],
#   "new york" => ["nyc", "new york city"],
#   "new york city" => ["nyc", "new york"],
#   "tv" => ["television"],
#   "television" => ["tv"]}
```

**DX rationale:**
- **Map form** pattern-matches on `is_map(synonyms)` and round-trips to Meilisearch without translation — zero surprise for the ~30% of users who learned Meilisearch first and reach for the native shape.
- **List-of-groups sugar** matches Searchkick's `search_synonyms: [["pop", "soda"]]` shape that Rails-literate Phoenix devs expect. Bidirectional is the default mental model ("these words mean the same thing"). Meilisearch's native map form requires the user to manually explode each direction — a well-documented footgun ([Meilisearch discussion #1135](https://github.com/meilisearch/MeiliSearch/issues/1135)).
- **String DSL rejected:** Elastic-style `"pop, soda"` strings read nicely but lose pattern-matchability and introduce a second grammar. Meilisearch doesn't accept it natively; translation would be Scrypath-specific and fragile.
- **List-of-tuples rejected:** `[{"nyc", ["new york"]}]` pattern-matches only as keyword-list, which fails on non-atom keys (synonyms are user strings, not atoms). Maps are the right Elixir shape.

**One-way synonyms** (the Typesense-rails `one_way_synonyms` case): support via a separate `one_way:` key inside `synonyms`:

```elixir
synonyms: %{
  "phone" => ["iphone", "android"],       # bidirectional: "phone"→iphone,android AND reverse
  one_way: %{
    "iphone" => ["phone"],                # one-way: iphone→phone, NOT phone→iphone
    "galaxy" => ["phone"]
  }
}
```

Translation to Meilisearch:
- Bidirectional entries explode into both-direction map entries.
- `one_way:` entries pass through as one-directional map entries only.

**Best reference library:** Typesense-rails (`multi_way_synonyms` + `one_way_synonyms` split is the cleanest model).
**Worst reference library:** Laravel Scout + Meilisearch (no declarative shape at all; forces manual SDK calls).

**Phase 19 plan constraint:** Declares the synonym-expansion function contract in `Scrypath.Meilisearch.Settings.expand_synonyms/1` with 100% test coverage (bidirectional expansion is easy to get wrong — missing the "self" key, double-expansion, string vs atom keys).

---

#### 1b. Typo tolerance — **nested map, validated subkeys, flat flags REJECTED**

**Recommendation:**

```elixir
settings: %{
  typo_tolerance: %{
    enabled: true,
    min_word_size_for_typos: %{
      one_typo: 5,
      two_typos: 9
    },
    disable_on_words: ["scrypath", "meilisearch"],
    disable_on_attributes: [:email, :slug],
    disable_on_numbers: true    # Meilisearch 1.12+, stable in 1.15
  }
}
```

**DX rationale:**
- **Nested map mirrors Meilisearch's JSON shape exactly** with snake_case keys — minimal cognitive load for users who read the Meilisearch docs. Translation layer (`Scrypath.Meilisearch.Settings.translate_typo_tolerance/1`) converts `min_word_size_for_typos` → `minWordSizeForTypos` and `disable_on_words` → `disableOnWords`.
- **Flat flags rejected** (`typo_enabled: true, typo_one_typo: 5, typo_disable_on_words: [...]`): flattens the namespace into the top-level `settings` map, collides with future Meilisearch settings, makes it impossible to "unset the whole typo block" cleanly.
- **Keyword-list rejected** (`typo_tolerance: [enabled: true, min_word_size_for_typos: [one_typo: 5]]`): keyword lists with duplicate keys bite silently; maps are enforced-unique. Meilisearch's shape is nested-map, so our internal representation should be nested-map.
- **`disable_on_attributes` takes atoms**, not strings. Ecto field names are atoms; consistency with the rest of the Scrypath DSL. Translation stringifies.

**Best reference library:** algoliasearch-rails (`minWordSizefor1Typo: 4, typoTolerance: "strict"` pattern — nested DSL block maps cleanly onto Algolia's JSON).
**Worst reference library:** Elasticsearch-rails (typo tolerance is buried in analyzer config, needs analyzer-chain expertise).

**Phase 19 plan constraint:** NimbleOptions-nested validator for `typo_tolerance` must enforce `enabled: boolean()`, `min_word_size_for_typos` is a map with exactly `one_typo` and `two_typos` integer keys, `one_typo ≤ two_typos` (compile-time check), `disable_on_attributes` atoms exist in `filterable` or `fields`.

---

#### 1c. Ranking rules — **ordered list of atoms for the six default rules, binary strings for attribute-sort rules**

**Recommendation:**

```elixir
settings: %{
  ranking_rules: [
    :words,
    :typo,
    :proximity,
    :attribute,
    :sort,
    :exactness,
    # Attribute-sort rules use binary syntax (Meilisearch-native: "field:desc")
    "released_at:desc",
    "popularity:desc"
  ]
}
```

**DX rationale:**
- **Atoms for the six default rules** (`:words, :typo, :proximity, :attribute, :sort, :exactness`): exhaustive set, pattern-matchable, typo-caught at compile time via validator (`is in @builtin_ranking_rules`), round-trips through `to_string/1`.
- **Binary strings for `"field:direction"`**: Meilisearch's attribute-sort syntax is already string-shaped; forcing a tuple form like `{:desc, :released_at}` invents a Scrypath grammar with zero DX win and breaks round-trip with Meilisearch docs. Users copy-paste `"released_at:desc"` from the Meilisearch docs — keep the paste-ability.
- **Tuple form rejected** (`{:desc, :released_at}`): looks clean in isolation but breaks the "ordered list" mental model (now you have two element types), and conflates with Ecto's `{:desc, :field}` sort shape, which applies to a different concept (query-time sort vs index-time ranking).
- **All-strings rejected** (`["words", "typo", ...]`): loses typo-catching on the six built-ins, loses atom pattern-matching, forces users to remember which strings are valid. Meilisearch itself documents these six as a closed set — atoms are the right Elixir shape for a closed set.

**Mixed atom/string validator:**

```elixir
@builtin_ranking_rules ~w(words typo proximity attribute sort exactness)a

defp validate_ranking_rule(rule) when rule in @builtin_ranking_rules, do: :ok
defp validate_ranking_rule(rule) when is_binary(rule) do
  case String.split(rule, ":", parts: 2) do
    [_field, direction] when direction in ~w(asc desc) -> :ok
    _ -> {:error, "attribute sort rule must be 'field:asc' or 'field:desc'"}
  end
end
defp validate_ranking_rule(other), do: {:error, "unknown ranking rule: #{inspect(other)}"}
```

**Best reference library:** Algolia (`customRanking ['desc(likes_count)']`) — similar mixed shape.
**Worst reference library:** Searchkick (ranking as boost-per-field at query time conflates index-level and query-level concerns).

**Phase 19 plan constraint:** Ranking-rules validator runs *before* the safety-rail check (question 3). A malformed rule fails loud before the safety-rail decides whether the well-formed rules are complete.

---

#### 1d. Distinct attribute — **atom, translated to string**

**Recommendation:**

```elixir
settings: %{
  distinct_attribute: :product_line
}
```

**DX rationale:**
- **Atom plays with Ecto schema field names** (`:product_line` is already how the user declares `field :product_line, :string` in their Ecto schema). Consistent with how `filterable:` and `sortable:` take atoms.
- **String alternative** would match Meilisearch's raw JSON but force the user to double-quote what should be a reference to an Ecto field. Breaks consistency with the rest of the Scrypath DSL.
- **Compile-time validation:** the atom must appear in `fields:` (otherwise Meilisearch will reject the setting at apply time; catch earlier).
- **Translation:** `Atom.to_string/1` in `Scrypath.Meilisearch.Settings.translate_settings/1`.

**Best reference library:** Ecto itself (`@primary_key {:id, :binary_id, ...}` — atoms for field references).
**Worst reference library:** Laravel Scout (stringly-typed throughout).

**Phase 19 plan constraint:** Compile-time validation that `distinct_attribute` (if set) appears in the schema's `fields:` list. Hard error at `use Scrypath` time, not at reindex time.

---

#### 1e. Stop words — **list of strings, no locale flag**

**Recommendation:**

```elixir
settings: %{
  stop_words: ["the", "a", "an", "of", "at"]
}
```

**DX rationale:**
- **Strings, not atoms:** stop words are user-supplied vocabulary (potentially multilingual: `["de", "la", "le"]` for French). Atoms would force atom-interning, which is unbounded for user-supplied vocabulary.
- **No locale flag:** Meilisearch applies stop words uniformly across the index. Locale-specific stop-words live in separate indexes (different schemas with `index_prefix:`). Adding a locale flag now would imply multi-locale-per-index, which Meilisearch doesn't support natively.
- **No Ecto `:string` vs `:text` distinction:** stop-words apply to the index's searchable-attributes pipeline, which operates on the already-serialized field content. Ecto type is irrelevant to Meilisearch's stop-word filter. The distinction only matters if Scrypath wanted to derive stop-words automatically from field types (nobody surveyed does this; it would be a non-goal).
- **Validation:** each element is a non-empty string; deduplicate; warn (not error) on common mistakes like `["the ", " a"]` (trailing whitespace).

**Best reference library:** Every surveyed library handles this the same way — plain list of strings.

**Phase 19 plan constraint:** Deduplication and whitespace-trim happen in the validator (not at translate time) so operators see the normalized list in `mix scrypath.settings.diff`.

---

### Question 2: Settings merge semantics — **shallow merge by top-level subkey, with explicit `:deep_merge` opt-in**

**Recommendation:**

```elixir
# In Scrypath.Meilisearch.Settings.resolve/2 (current: Map.merge/2 — shallow top-level)
# Extend to:

def resolve(schema_module, config) do
  declared = Scrypath.schema_settings(schema_module)
  override = Keyword.get(config, :settings, %{})
  merge_mode = Keyword.get(config, :settings_merge, :replace)

  case merge_mode do
    :replace -> Map.merge(declared, override)      # default, shallow
    :deep    -> deep_merge(declared, override)     # opt-in
  end
end
```

**DX rationale (grounded in Elixir ecosystem patterns):**

1. **Ecto's `cast/3` + `put_assoc/3` model is explicit about replacement** — when you put a new value, it replaces the old one wholly unless you opt into `:merge` or append-semantics. Elixir idiom favors explicit-over-implicit for merge semantics. Shallow-replace-by-default keeps mental model simple.

2. **Phoenix endpoint config cascades shallow at the top level** (`config :my_app, MyApp.Endpoint, ...` + `config :my_app, MyApp.Endpoint, http: [port: 4001]` — the second `http:` replaces the first unless the user uses `Config.Reader`-style merging). Phoenix users have learned shallow-merge as default.

3. **Oban plugin configs use keyword-list `Keyword.merge/2` (shallow)** for plugin-option overrides. Users opt into Oban.Config's deep-merge semantics explicitly when needed.

4. **The DeepMerge library exists precisely because deep-merge is never the default in Elixir stdlib.** Its README notes: "be careful with deep-merge; it's surprising in ~40% of use cases". Shallow-by-default + explicit opt-in is the safer boundary.

**Concrete behavior for Scrypath:**

```elixir
# Shallow (default) — override replaces each top-level subkey whole
declared = %{
  typo_tolerance: %{enabled: true, min_word_size_for_typos: %{one_typo: 5, two_typos: 9}},
  synonyms: %{"nyc" => ["new york"]}
}
override = %{
  typo_tolerance: %{enabled: false}  # RESULT: min_word_size_for_typos is gone!
}
# => %{typo_tolerance: %{enabled: false}, synonyms: %{"nyc" => ["new york"]}}

# Deep (opt-in via settings_merge: :deep) — override merges into each subkey
override = %{typo_tolerance: %{enabled: false}}
# => %{typo_tolerance: %{enabled: false,
#                         min_word_size_for_typos: %{one_typo: 5, two_typos: 9}},
#       synonyms: %{"nyc" => ["new york"]}}
```

**DX guidance for users:** The "weaker typo tolerance in tests" use case from FEATURES.md becomes:

```elixir
# config/test.exs
config :my_app, MyApp.Repo.scrypath,
  settings: %{typo_tolerance: %{enabled: false}},
  settings_merge: :deep    # ← opt in, explicit
```

Without `:deep`, the user would wipe `min_word_size_for_typos` in test env. With it, behavior matches intuition.

**Best reference library:** Ecto (explicit cast/merge semantics).
**Worst reference library:** Searchkick (global `Searchkick.model_options` is mutable and merges unpredictably — has bitten production operators more than once).

**Phase 19 plan constraint:** The `:settings_merge` option is new on `@runtime_options` (and `@reindex_options`, `@backfill_options`). Must default to `:replace` for backward compatibility — the current `Map.merge/2` in `Settings.resolve/2` is already shallow-replace behavior, so this change is semantically a no-op for existing callers.

---

### Question 3: Ranking rule safety rails — **mandatory rule-set enforcement at reindex time, with compile-time warning, opt-out via explicit `ranking_rules_strict?: false`**

**Recommendation:**

```elixir
# In Scrypath.Options.validate_settings/1 — COMPILE-TIME WARNING
# In Scrypath.Reindex.run/2 — REINDEX-TIME HARD ERROR

@mandatory_ranking_rules ~w(words typo proximity attribute sort exactness)a

defp check_ranking_rules(%{ranking_rules: rules} = settings, strict?) do
  missing = @mandatory_ranking_rules -- atoms_from_rules(rules)

  cond do
    missing == [] ->
      :ok

    strict? ->
      raise ArgumentError, """
      ranking_rules is missing required rules: #{inspect(missing)}.
      These are the Meilisearch default ranking rules. Omitting any of them
      will degrade search quality (e.g., omitting :words means matching on
      all query terms is no longer prioritized).

      To proceed anyway, set `ranking_rules_strict?: false` in the settings map:

          settings: %{ranking_rules: [...], ranking_rules_strict?: false}
      """

    true ->
      Logger.warning("""
      ranking_rules omits #{inspect(missing)} and ranking_rules_strict? is false.
      Search quality may degrade. This was set explicitly.
      """)
      :ok
  end
end

defp check_ranking_rules(_settings, _strict?), do: :ok
# If ranking_rules not set at all, Meilisearch uses its default — no check needed.
```

**DX rationale:**

1. **Compile-time warning + reindex-time error is the right split.** Compile-time is when the user declares the schema; they're iterating on it and need feedback fast. Reindex-time is when the setting *actually lands* in production; a hard error prevents a bad config from going live. Trusting silently is the current industry default across all five surveyed reference libraries; none of them warn when a user ships a broken ranking-rule set, and the Meilisearch issue tracker has multiple "search stopped matching words" bugs traceable to this exact mistake.

2. **Opt-out exists but is loud.** Setting `ranking_rules_strict?: false` is an explicit, discoverable way to say "I know what I'm doing". Matches Rails' `skip_before_action` pattern — possible but visible.

3. **Runtime check (every search) rejected.** Relevance settings are index-time, not query-time; checking at every search would be expensive and philosophically wrong (the setting is already applied by the time search runs).

4. **"Require minimum rule set" vs "trust silently" tradeoff:** Four of five surveyed libraries trust silently. One (Algolia) treats ranking as a hybrid (you set custom ranking; Algolia's defaults always remain). Scrypath's approach is a deliberate differentiator: we warn about the Meilisearch-specific footgun that the Meilisearch docs themselves warn about but no library enforces.

**Best reference library (closest analog):** Ecto's changeset-cast `required:` list — you must name required fields explicitly; the framework catches missing ones at validation time.
**Worst reference library:** Searchkick — no check; users have debugged "search stopped working after ranking tweaks" for years.

**Phase 19 plan constraint:** This is the single most opinionated decision in Phase 19. Must be documented prominently in the relevance-tuning guide and called out in CHANGELOG as a **new validation** (not breaking — the check only activates if user sets `ranking_rules:` at all; unchanged users are unaffected). Property test: for any valid permutation of the six mandatory rules plus zero-to-N attribute-sort rules, validator passes; for any removal of a mandatory rule, validator fails unless `strict?: false`.

---

### Question 4: Post-apply verification — **key-by-key deep-equal comparison of declared-vs-applied, block cutover on mismatch**

**Recommendation:**

```elixir
# New: Scrypath.Meilisearch.Settings.verify_applied/3

@spec verify_applied(module(), String.t(), keyword()) ::
  :ok | {:error, {:settings_drift, [{atom(), term(), term()}]}}
def verify_applied(schema_module, index_name, config) do
  declared = resolve(schema_module, config) |> translate_settings()
  {:ok, actual} = client(config).get_settings(index_name, config)

  drift =
    declared
    |> Enum.reject(fn {key, expected} ->
      Map.get(actual, key) == expected
    end)
    |> Enum.map(fn {key, expected} ->
      {key, expected, Map.get(actual, key)}
    end)

  if drift == [], do: :ok, else: {:error, {:settings_drift, drift}}
end
```

Integrated in `Scrypath.Reindex.run/2` after `apply_settings` and its task wait, before `backfill`:

```elixir
with {:ok, settings_result} <- meilisearch.apply_settings(schema, target, workflow_config),
     {:ok, _} <- maybe_wait_for_result_task(settings_result, workflow_config),
     :ok <- Scrypath.Meilisearch.Settings.verify_applied(schema, target, workflow_config),
     ...
```

**DX rationale:**

1. **Key-by-key over full deep-equal:** a single diff list is dramatically more legible than a `"expected: {...}, got: {...}"` dump. The error shape `{:error, {:settings_drift, [{:ranking_rules, [...], [...]}]}}` points directly at which subkey drifted and gives both values for human diagnosis.

2. **Sampling rejected:** sampling makes sense for huge datasets, not for a settings map with ≤ 15 top-level keys. Read-back cost is one HTTP GET; negligible.

3. **Block cutover on mismatch:** "safe" is the correct default for a library that positions itself around "operational honesty". The alternative ("warn + continue") means operators discover bad settings at 3am when search quality tanks. Matches the posture of Ecto.Multi — if any step fails, the whole transaction rolls back.

4. **Why block, not silently warn:** algoliasearch-rails's `check_settings: true` default proved this exact pattern works in production. The 1.2 audit's core lesson (`v1.2-MILESTONE-AUDIT.md`) was "silent divergence between declared and applied is catastrophic". Verify-before-cutover is the same principle applied one level down (declared settings vs applied settings, not declared files vs published tarball).

5. **What "block cutover" means in practice:** the target index exists with the (bad) applied settings; backfill hasn't run; cutover hasn't swapped. Operator sees the drift error, fixes the declared settings (or accepts the override), re-runs `Scrypath.reindex/2`. No live search degradation, no deployment surprise.

6. **What verify specifically catches:** (a) Meilisearch silently ignoring an unknown key, (b) Scrypath's translation layer producing the wrong camelCase key (regression risk in the translate function), (c) race condition where two reindex runs interleave and one wins.

**Best reference library:** algoliasearch-rails `check_settings: true` (the only surveyed library that ships an equivalent check; widely adopted, rarely complained-about).
**Worst reference library:** Laravel Scout (no check; user reports of "I set a synonym in code but it's not in the index" are a recurring theme in the issue tracker).

**Phase 19 plan constraint:** `get_settings/2` is a new route on `Scrypath.Meilisearch.Client` (thin wrapper over `GET /indexes/{uid}/settings`). Must handle the index-not-found case (`{:error, :index_not_found}`) specifically because the verify runs on the newly-created target index — a race where the target was deleted between create and verify must return a clear error, not `{:error, %Req.Error{...}}`.

---

### Question 5: Hot-settings escape hatch — **defer to v1.4; v1.3 ships `Scrypath.Meilisearch.Settings.hot_apply/3` with `{:error, :hot_apply_disabled}` stub and loud docs**

**Recommendation:**

```elixir
# Stub in v1.3 (Scrypath.Meilisearch.Settings):

@doc """
Not available in v1.3. Returns `{:error, :hot_apply_disabled}`.

Hot-applying synonyms, stop words, or typo tolerance to a live index without a
managed reindex is technically possible against Meilisearch, but the UX pitfalls
(silent ranking drift, settings that require a rebuild failing unpredictably,
interleaved sync operations losing ordering guarantees) outweigh the "instant
synonym tweak" DX win for v1.3.

Planned for v1.4 under a different contract: `Scrypath.Meilisearch.Settings.hot_apply/3`
will accept only `synonyms`, `stop_words`, and `typo_tolerance`, refuse any other
subkeys, and require an explicit `acknowledge_live_index: true` opt.

Until then, use `Scrypath.reindex/2` for all settings changes. It is fast enough
for the common case (<100k documents in a few seconds with Meilisearch >=v1.15).
"""
def hot_apply(_schema_module, _subkeys, _opts), do: {:error, :hot_apply_disabled}
```

**DX rationale:**

1. **v1.3 scope discipline:** PITFALLS P5 explicitly lists "hot-apply settings" as the kind of verb that silently undoes the managed-reindex invariant. Shipping even a restricted hot_apply in v1.3 opens the door to users reaching for it in the wrong case.

2. **Meilisearch itself doesn't split the API.** The same `PATCH /indexes/{uid}/settings` endpoint applies all settings; the "hot-applicable" distinction is user-lore, not API-enforced. Scrypath splitting them now would require maintaining a Scrypath-owned list of which keys are hot-applicable, which drifts as Meilisearch evolves ([Meilisearch issue #4484](https://github.com/meilisearch/meilisearch/issues/4484) shows the team is working on making more settings hot-applicable).

3. **Lesson from Searchkick:** Searchkick's approach ("reindex for synonyms always, hot-reload via on-disk files in ES 7.3+") mirrors this recommendation — the hot-path is an *infrastructure-level* escape hatch, not an application-level verb. Searchkick doesn't expose `Product.apply_synonyms!` for exactly the reasons Scrypath shouldn't either.

4. **The stub is better than absence:** users who reach for `hot_apply` (from search results, LLM suggestions, or reference-lib analog reasoning) get a precise error telling them why it doesn't exist and what to do instead. Better than a `NoFunctionClauseError` with no direction.

5. **v1.4 unlocks it deliberately:** once v1.3 adopter feedback proves the managed-reindex path is fast enough for the common case *and* there's a concrete "I need to tweak synonyms without a rebuild" use case with a real operator story, v1.4 can ship hot_apply with the guardrails it needs (namespaced verb, explicit acknowledgment, restricted subkey set, emitted telemetry event).

**Best reference library (the anti-pattern avoided):** Laravel Scout — users call `$model->searchable()` after SDK-level `updateSettings()` calls, which get out of order and silently break. Zero enforcement.
**Best reference library (the pattern followed):** Searchkick — no hot apply in the model API; operators who need it go to the search-server layer directly with a documented runbook.

**Phase 19 plan constraint:** The stub must exist with the exact error atom `:hot_apply_disabled` to enable downstream pattern-matching without fragility. CHANGELOG explicitly lists "hot apply deliberately deferred to v1.4" so users who search for it find the decision rationale.

---

### Question 6: Concurrent-sync safety during reindex — **current cutover atomicity is sufficient for relevance changes; document the `searchableAttributes` edge case but DO NOT add sync-pause**

**Recommendation:**

```
Current behavior (preserve):
  1. Scrypath.reindex/2 creates target_index
  2. apply_settings to target_index (does NOT touch live_index)
  3. backfill target_index (does NOT touch live_index)
  4. Concurrent sync from writes to live_index runs unchanged throughout
  5. Cutover (swap-indexes) is atomic at Meilisearch layer
  6. Post-cutover, the new-live index has correct settings AND all docs,
     but is missing writes that arrived during step 3-4 backfill window

v1.3 additions:
  - verify_applied (question 4) ensures settings took hold before cutover
  - No new sync-pause mechanism
  - Document: the sync-window-miss is an existing v1.2 behavior;
    operators recover via Scrypath.reconcile_sync/2 (existing verb)
```

**DX rationale:**

1. **Sync-pause is architecturally wrong.** The whole point of Scrypath's managed reindex is to *not* require a maintenance window. Adding "pause sync while reindex runs" would re-introduce exactly the downtime users chose Meilisearch + Scrypath to avoid. This is a non-starter architecturally (violates CORE VALUE's "operational honesty without hiding operational realities").

2. **Queue-to-replay-after-cutover is over-engineering.** Meilisearch's `/swap-indexes` is atomic; after swap, the sync pipeline is writing to the swapped (ex-target) index. The sync-window-miss is bounded to the backfill duration and handled by the existing `reconcile_sync/2` operator verb. Adding a queue-and-replay layer would be a whole-new Oban worker type for a problem that already has a solution.

3. **Trust cutover atomicity is correct.** This is the design v1.2 validated. Relevance settings don't change the correctness story: settings land on target, target gets swapped, done. The only *new* concern v1.3 introduces is settings-drift (question 4's verify), which is separate from sync-concurrency.

4. **The `searchableAttributes` edge case** (raised in the question): changing `searchableAttributes` triggers a Meilisearch-internal rebuild. But in Scrypath's model, this rebuild happens on the *target* index (during `apply_settings` step), not the live. By the time cutover runs, target is fully indexed with the new settings. The edge case doesn't bite because target is isolated.

5. **What to document:** the relevance-tuning guide must say:
   > "During reindex, writes to the live index continue. After cutover, any writes that arrived during the backfill window are not yet in the new-live index — exactly the same behavior as a Scrypath.reindex call without settings changes. Run `mix scrypath.reconcile` to surface any drift; run `mix scrypath.retry_sync` to replay."

**Best reference library (the pattern followed):** Searchkick's `Product.reindex(async: true, import: true)` — explicitly documents the sync-window-miss and points to `Searchkick::BulkReindexJob` for post-cutover reconcile. Same model.
**Worst reference library (the anti-pattern avoided):** algoliasearch-rails `Model.reindex!` (bang version) historically paused auto-indexing callbacks globally — multiple production incidents traced to operators forgetting to re-enable after.

**Phase 19 plan constraint:** No new sync-pause mechanism. Relevance guide explicitly documents the sync-window-miss behavior (same as v1.2) and points at `reconcile_sync/2`. Add `[:scrypath, :reindex, :settings_verified]` telemetry event (emitted between verify and backfill) so operators can trace the ordering.

---

### Question 7: Relevance telemetry — **ship `mix scrypath.settings.diff [Schema]` + extend `mix scrypath.reindex --verbose` with settings-diff section**

**Recommendation:** Four small additions, all operator-facing:

#### 7a. New Mix task: `mix scrypath.settings.diff [Schema]`

```
$ mix scrypath.settings.diff MyApp.Blog.Post

Schema:     MyApp.Blog.Post
Index:      posts_production
Live?:      yes

┌─────────────────────────┬──────────────────────────────┬──────────────────────────────┬─────────┐
│ Setting                 │ Declared                     │ Applied                      │ Drift?  │
├─────────────────────────┼──────────────────────────────┼──────────────────────────────┼─────────┤
│ synonyms                │ {nyc → [new york]}           │ {nyc → [new york]}           │ no      │
│ typo_tolerance.enabled  │ true                         │ true                         │ no      │
│ ranking_rules           │ [words,typo,...,released_at] │ [words,typo,...]             │ YES     │
│ distinct_attribute      │ :product_line               │ product_line                 │ no      │
│ stop_words              │ [the, a, an]                │ [the, a, an, of]             │ YES     │
└─────────────────────────┴──────────────────────────────┴──────────────────────────────┴─────────┘

Drift detected. Run `mix scrypath.reindex MyApp.Blog.Post` to reconcile.
```

#### 7b. Extend `mix scrypath.reindex --verbose` to print the diff inline:

```
$ mix scrypath.reindex MyApp.Blog.Post --verbose
[reindex] creating target index posts_production__reindex
[reindex] applying settings...
[reindex]   ranking_rules:      changed (added "released_at:desc")
[reindex]   synonyms:           unchanged
[reindex]   typo_tolerance:     unchanged
[reindex] settings applied; verifying...
[reindex] verify: ok
[reindex] backfilling 12,431 documents in 250-batch chunks...
```

#### 7c. Extend `Scrypath.reindex/2` return shape to carry the diff:

```elixir
{:ok, %{
  ...existing keys...,
  settings_diff: %{
    changed: [:ranking_rules],
    unchanged: [:synonyms, :typo_tolerance, :distinct_attribute, :stop_words]
  }
}}
```

#### 7d. Emit new telemetry event `[:scrypath, :reindex, :settings_diff]` with measurements `%{changed_count: 1, unchanged_count: 4}` and metadata `%{schema: module(), changed_keys: [...]}`.

**DX rationale:**

1. **Diff-visibility is the single biggest lesson from algoliasearch-rails.** Their `check_settings: true` default works because operators can inspect what *will* change before pushing. Scrypath's managed-reindex path inverts this (push first, verify second) — but a dry-run diff task closes the loop.

2. **Separate `settings.diff` task beats "only inside reindex --verbose":** operators run `diff` in PRs as a check ("did this deploy change any settings?"); they run `reindex --verbose` only when they're already committing. Two task namespaces serve two workflows.

3. **`mix scrypath.reindex` already exists and is thin** (per ARCHITECTURE.md Mix-task pattern). Extending with `--verbose` is the right extension point — no new CLI product surface (PITFALLS P9 non-goal check).

4. **Return-shape extension is backward-compatible** (new optional key on the result map; existing pattern-matchers aren't broken because they match the existing keys).

5. **Telemetry event matches v1.2's `[:scrypath, :reindex, ...]` namespace.** Operators already subscribe; one more event family.

**Best reference library:** algoliasearch-rails' `check_settings` + `.algolia.yml` dump — users love being able to see what will change before it changes.
**Worst reference library:** Laravel Scout + Meilisearch — no drift visibility at all; users discover drift through production search quality complaints.

**Phase 19 plan constraint:** `mix scrypath.settings.diff` requires a live Meilisearch connection (read-back via `get_settings/2`); must handle index-not-found cleanly (print "index not yet created; nothing to diff"). Must respect `--repo`, `--index-prefix` flags the way other `mix scrypath.*` tasks do.

---

### Question 8: Full-rebuild vs hot-apply asymmetry — **invisible to users in v1.3, explicit capability signal deferred to v1.4**

**Recommendation:**

```
v1.3 posture:
  - All 5 settings flow through Scrypath.reindex/2 uniformly.
  - No separate "hot path" for synonyms / stopWords / typoTolerance.
  - User model: "change declared settings → run mix scrypath.reindex → done".

v1.4 unlock (deferred):
  - Scrypath.Meilisearch.Settings.hot_apply/3 (stubbed in v1.3 with
    {:error, :hot_apply_disabled}) gets implemented with subkey allowlist
    matching Meilisearch's hot-applicable set.
  - Schema declaration gets an optional flag: settings_policy: :managed (default)
    | :hot_when_possible — the latter lets Scrypath pick hot-apply when the
    diff is contained to hot-applicable keys.
```

**DX rationale:**

1. **Invisible is the right v1.3 posture.** Users shouldn't need to know which Meilisearch settings trigger internal rebuild — that's Meilisearch's implementation detail, and Meilisearch itself is moving to make more settings hot-applicable ([meilisearch#4484](https://github.com/meilisearch/meilisearch/issues/4484)). Exposing the split now freezes a Scrypath-owned classification that Meilisearch will evolve past.

2. **Uniform behavior is auditable.** Every settings change is a reindex; every reindex is observable via existing telemetry; every cutover is atomic. No branching code paths in operator mental model.

3. **Phoenix operator persona gets speed, not complexity:** Meilisearch reindexes under 100k docs in seconds; the "I need to skip the reindex for just this synonym change" DX win is real but marginal. Preserving the one-path mental model is worth more than the microseconds saved.

4. **Capability signal deferred until there's adopter pressure.** A real operator reporting "I have 10M docs and synonym tweaks are my daily workflow" is a legit reason to ship `:hot_when_possible`. Speculating that workflow and pre-engineering for it is over-design.

5. **The pitfalls research called this out explicitly** — Pitfall 5 warns against "hot apply settings to live index" as a class of mistake. v1.3 bakes in the no-hot-apply posture; v1.4 can revisit with a Scrypath.Meilisearch.* namespaced opt-in.

**What to document (so users know about the asymmetry without having to make choices about it):**

The relevance-tuning guide includes a single sentence: "Scrypath runs every settings change through a managed reindex for consistency. In Meilisearch, some settings changes could technically be applied without a rebuild; Scrypath defers that optimization to a future `Scrypath.Meilisearch.Settings.hot_apply/3` verb (not available in v1.3) so the operational model stays one path."

**Best reference library:** Searchkick's `Product.reindex` — one verb for all settings changes; the hot-apply path (ES on-disk synonyms) is an infrastructure concern documented separately, not an application verb.
**Worst reference library:** Algolia's hybrid model (some settings apply instantly, some don't) — users routinely file bugs about settings they expected to apply instantly that didn't, and vice versa.

**Phase 19 plan constraint:** Do not ship any capability detection in v1.3. The stub `hot_apply/3` exists only to pre-reserve the namespace (so v1.4 can land it as a minor bump, not a breaking one).

---

### Question 9: Coherence with faceting (Phase C/19 in roadmap parlance) and multi-index (Phase D/20)

#### With faceting

**Problem:** Faceting extends `filterable:` via the declarative `faceting:` key (per FEATURES.md). Relevance tuning extends `settings:`. Both land on the same reindex pipeline and the same `PATCH /settings` call. They interact in three ways:

1. **`filterableAttributes` gets derived from `filterable:` ∪ `faceting.attributes`.** Relevance tuning doesn't touch `filterableAttributes`. Coherence: the `translate_settings/1` function builds the Meilisearch payload from *both* sources. Relevance's `translate_settings/1` must not clobber the facet-derived `filterableAttributes`.

2. **`distinct_attribute` interacts with facet distribution.** Meilisearch's facet distribution counts distinct documents per facet value, but `distinctAttribute` changes what "distinct document" means. Relevance-tuning guide must document this interaction explicitly (example: e-commerce "product_line" distinct attribute + "size" facet → facet counts are per-product-line, not per-SKU).

3. **Ranking rules affect faceted search ordering.** When user runs `Scrypath.search(Post, "q", facets: [:tag])`, the `hits` are ranked per the schema's `ranking_rules`; the `facet_distribution` is computed over all matching documents regardless of ranking. The relevance-tuning guide must document this (not a bug, but confusing if not stated).

**Recommendation:** Phase 19 (relevance) ships **first** (per ARCHITECTURE.md phase-ordering), Phase 20 (faceting) ships **second**. Phase 20 extends `translate_settings/1` to merge facet-derived `filterableAttributes` with the relevance-derived rest of the settings. Phase 19 doesn't need to know about facets; Phase 20 does need to know about relevance and must preserve the compile-time check `faceting.attributes ⊆ filterable:`.

#### With multi-index

**Problem:** Multi-index `Scrypath.search_many/2` fans out per-schema. Each schema has its own `settings:` declaration with its own relevance tuning. What does "relevance" mean across a federated search where Post and Comment have different ranking rules?

**Recommendation:** Relevance tuning in v1.3 is **strictly per-schema** — no cross-schema relevance knobs. Meilisearch's `/multi-search` federation endpoint natively handles this: each sub-query runs with its own index's settings, and the federated response merges results across indexes with a backend-specific relevance layer (Meilisearch's `mergeFacets` and native federation scoring).

Operational coherence:

- `Scrypath.search_many/2` validates each sub-request's options against *that schema's* faceting/filterable/settings declarations. Relevance settings have no per-query override (by design — see question 5 for the "no per-query ranking overrides" non-goal).
- The federation result shape (`%{schema => %SearchResult{}}`) preserves per-schema ranking; each `SearchResult.hits` is already ranked per its schema's rules.
- Documentation gap to close in Phase 21 (multi-index): call out that cross-schema relevance blending is a Meilisearch-native feature accessed via `Scrypath.Meilisearch.MultiSearch.federate/2` (the namespaced escape hatch), not a Scrypath-owned verb.

**Phase 19 plan constraint:** Nothing about relevance tuning in v1.3 blocks or complicates multi-index in v1.4. The one test to write: verify that `search_many([{Post, [...]}, {Comment, [...]}])` where Post and Comment have different `ranking_rules` returns results ranked correctly per-schema.

---

## Proposed REQ-IDs

**Prefix: `TUNE-`** (chosen to avoid collision with `REL-01..REL-03` release-pipeline IDs; reads cleanly in spec; short enough for CI grep patterns).

### TUNE-01: Declarative Structured Relevance Settings

**Statement:** Scrypath exposes synonyms, typo_tolerance, ranking_rules, distinct_attribute, and stop_words as structured subkeys of the existing `settings:` schema option, with Scrypath-owned snake_case Elixir shapes validated via NimbleOptions-nested schemas.

**Acceptance criteria:**
1. `use Scrypath, settings: %{synonyms: %{"nyc" => ["new york"]}}` compiles successfully; `schema_module.__scrypath__(:settings)` returns the full structured map.
2. `settings: %{typo_tolerance: %{enabled: true, min_word_size_for_typos: %{one_typo: 5, two_typos: 9}}}` validates; invalid shapes (e.g., `one_typo: -1`) raise `ArgumentError` at compile time.
3. `settings: %{distinct_attribute: :nonexistent_field}` raises `ArgumentError` at compile time if `:nonexistent_field` is not in `fields:`.
4. Unknown subkeys inside `settings:` pass through unchanged (backward compatibility with v1.2 callers using raw Meilisearch keys).

### TUNE-02: Synonym Declaration Supports Map and List-of-Groups Forms

**Statement:** Synonyms accept both the Meilisearch-native map form (`%{"nyc" => ["new york"]}`) and a list-of-groups sugar form (`[["nyc", "new york", "new york city"]]`). The list-of-groups form expands to bidirectional synonyms. An optional `one_way:` nested key provides unidirectional synonyms.

**Acceptance criteria:**
1. `settings: %{synonyms: [["nyc", "new york"]]}` expands to `%{"nyc" => ["new york"], "new york" => ["nyc"]}` before translation to Meilisearch.
2. `settings: %{synonyms: %{one_way: %{"iphone" => ["phone"]}}}` produces a map where `"iphone"` keys but `"phone"` does not.
3. Mixing forms is rejected: `settings: %{synonyms: %{"nyc" => [...], :sugar => [[...]]}}` raises `ArgumentError`.
4. `Scrypath.Meilisearch.Settings.expand_synonyms/1` has 100% branch test coverage including empty-list, single-term-group, and duplicate-across-groups edge cases.

### TUNE-03: Settings Flow Through Managed Reindex Pipeline Only

**Statement:** All declared relevance settings are applied only via `Scrypath.reindex/2`. No public verb outside `Scrypath.Meilisearch.*` mutates live-index settings. The stub `Scrypath.Meilisearch.Settings.hot_apply/3` returns `{:error, :hot_apply_disabled}` in v1.3.

**Acceptance criteria:**
1. `Scrypath.reindex(MyApp.Post)` creates target → applies settings → verifies → backfills → cuts over; this ordering is asserted by a mock-backend test.
2. `Scrypath.Meilisearch.Settings.hot_apply/3` returns `{:error, :hot_apply_disabled}` for any arguments.
3. No function under `Scrypath.*` (excluding `Scrypath.Meilisearch.*`) calls `Client.update_settings/3` against a live index.
4. A `mix xref graph` check (added as a CI rule) fails if any module outside `Scrypath.Meilisearch.*` newly calls `Client.update_settings/3`.

### TUNE-04: Ranking Rules Safety Rail

**Statement:** If `ranking_rules` is set, it must include all six Meilisearch default rules (`:words, :typo, :proximity, :attribute, :sort, :exactness`) unless `ranking_rules_strict?: false` is explicitly set. Missing rules trigger a compile-time warning and a reindex-time hard error.

**Acceptance criteria:**
1. `settings: %{ranking_rules: [:typo, :proximity, :attribute, :sort, :exactness, "released_at:desc"]}` emits a compile-time Logger.warning naming the missing `:words` rule.
2. Calling `Scrypath.reindex/2` with the above declaration raises `ArgumentError` explaining the missing rule.
3. Adding `ranking_rules_strict?: false` to the settings map downgrades the compile-time warning (still emitted, no error at reindex).
4. Omitting `ranking_rules` entirely (falling back to Meilisearch default) triggers no warning.

### TUNE-05: Post-Apply Settings Verification

**Statement:** After `apply_settings` succeeds during reindex, Scrypath reads back the target index's settings via `GET /settings` and compares against declared. Any key-level drift blocks cutover with `{:error, {:settings_drift, [{key, declared, actual}]}}`.

**Acceptance criteria:**
1. When declared settings == applied settings, reindex proceeds to backfill and cutover as today.
2. When declared settings differ from applied (simulated via a Meilisearch mock returning a stale value), reindex returns `{:error, {:settings_drift, [{...}]}}`; target index exists but is not swapped.
3. The error tuple's drift list names the specific subkey(s) that drifted (atom-typed keys matching the schema's declared settings, not the camelCase translated form).
4. Telemetry event `[:scrypath, :reindex, :settings_verified]` is emitted between verify and backfill with measurements `%{duration_ms: _, drift_count: 0}`.

### TUNE-06: Settings Merge Semantics — Shallow Default, Deep Opt-In

**Statement:** Runtime settings overrides shallow-merge with schema-declared settings by top-level subkey. Users opt into deep merge via `settings_merge: :deep` on the runtime opts.

**Acceptance criteria:**
1. Default behavior: `override = %{typo_tolerance: %{enabled: false}}` replaces the full declared `typo_tolerance` subkey; `min_word_size_for_typos` is lost.
2. With `settings_merge: :deep`: same override preserves `min_word_size_for_typos` and flips only `enabled: false`.
3. `settings_merge` is documented as an opt-in for the `reindex_options` and `backfill_options` and `runtime_options` option sets.
4. The default `:replace` is semantically identical to v1.2's existing `Map.merge/2` behavior in `Settings.resolve/2` (backward-compat regression test).

---

## Coherence With Other v1.3 Categories

### With Faceting (Phase 20 / Category "Faceted Search")

- **`translate_settings/1` is shared territory.** Phase 19 (relevance) lands the function; Phase 20 (faceting) extends it to merge facet-derived `filterableAttributes`. The test harness for Phase 19 includes stub entries for faceting keys so Phase 20's extension doesn't require rewriting.
- **Compile-time check pattern reused.** Phase 19 establishes the pattern of compile-time schema-level checks (e.g., `distinct_attribute ∈ fields:`). Phase 20 uses the same mechanism for `faceting.attributes ⊆ filterable:`.
- **`mix scrypath.settings.diff` is cross-feature.** Phase 20 extends the task output with a facet-configuration row; no new task.

### With Multi-Index Search (Phase 21 / Category "Multi-Index")

- **Per-schema settings are preserved in federated search.** Each sub-query runs with its own schema's settings (Meilisearch native behavior); no cross-schema relevance layer in v1.3.
- **`search_many/2` does not accept a `settings:` override.** Relevance is index-time; multi-index is query-time. No coupling needed.
- **Federated ranking is Meilisearch-native.** Users who need cross-schema relevance blending (rare) go through `Scrypath.Meilisearch.MultiSearch.federate/2` (the namespaced escape hatch), not a Scrypath-owned verb.

### With Operator Polish (Phase 22 / Category "Operator Polish")

- **Drift recovery guide references `mix scrypath.settings.diff`.** The guide's "something drifted in production" flow chain becomes: `sync_status → failed_sync_work → settings.diff → reindex → reconcile_sync`. Phase 22's guide copy includes the settings.diff step.
- **`FailedWork.reason_class` can include `:settings_drift`** as a class for reindex failures caused by verify-blocked cutover. Phase 22 decides on final taxonomy; Phase 19 just provides the failure shape.

### With Release / Tooling Debt (Phase 18A / Category "Debt Retirement")

- **Zero interaction.** Phase 18A's release-parity gate runs before any v1.3 feature phase; it checks that files ship, not that settings apply correctly. No coupling.

---

## Non-Goal Tripwires

### Explicit non-goals reinforced by Phase 19 design

| Tempting v1.3 addition | Non-goal it violates | Scrypath v1.3 verdict |
|---|---|---|
| Per-query ranking-rule overrides on `Scrypath.search/3` | "No breaking changes to v1.2 public contracts" (common search path stays declarative-only) | Hard no; backend-native via `Scrypath.Meilisearch.*` if users insist |
| `Scrypath.apply_settings/2` public verb (bypasses reindex) | "Settings flow through managed reindex" (v1.2 architecture) | Hard no; `Scrypath.Meilisearch.Settings.hot_apply/3` exists only as a stub returning `{:error, :hot_apply_disabled}` |
| Auto-synonym generation from query logs | "No analytics / no dashboard" (`PROJECT.md` non-goals) | Hard no; Scrypath does not inspect query traffic |
| Vector/embedding knobs inside `settings:` (e.g. `embedders:` passthrough) | "No vector/hybrid/semantic" (`PROJECT.md` non-goals) | Hard no; even passthrough tempts scope creep |
| Language/locale-aware stop-words (e.g., `stop_words: {:en, [...]}`) | "Meilisearch-first without inventing above-backend abstractions" | Hard no for v1.3; separate index per locale is the documented pattern |
| Per-environment ranking rules inside `config.exs` (different ranking in prod vs test) | N/A — actually in scope (question 2 recommendation allows it) | Supported via `settings:` runtime override + `settings_merge: :deep` opt-in |

### Specific grep-check for Phase 19 closure

Phase 19 VERIFICATION.md must grep the diff for these tokens and confirm zero or justified matches:

- `embedder`, `embedding`, `vector`, `hybrid` → blocked non-goal
- `analytics`, `log_queries`, `track_synonym_usage` → blocked non-goal
- `:apply_settings` as a new public verb outside `Scrypath.Meilisearch.*` → blocked architectural rule
- `dashboard`, `router`, `live_view` in lib/ (vs guides/) → blocked non-goal

---

## Mix Task Additions

### Four new tasks, all thin delegates

#### M-1: `mix scrypath.settings.diff [Schema]`

- **Purpose:** Shows declared-vs-applied settings for the given schema as a three-column table with drift marker.
- **Thin delegate:** Calls `Scrypath.Meilisearch.Settings.verify_applied/3` and formats the result.
- **Flags:** `--repo`, `--index-prefix`, `--json` (machine-readable output for CI gates).
- **Exit codes:** 0 if no drift; 2 if drift detected (so PRs can use it as a gate).

#### M-2: `mix scrypath.reindex --verbose` (extension of existing task)

- **Purpose:** Existing reindex task gets a `--verbose` flag that prints the settings-diff and per-step timing.
- **Thin delegate:** Reads `settings_diff` from the return shape of `Scrypath.reindex/2` (TUNE-05 extension).

#### M-3: `mix scrypath.settings.apply [Schema] [--force]` — **DO NOT SHIP IN V1.3**

- **Status:** Deliberately omitted. Listed here as anti-task so future contributors know to reject PRs proposing it.
- **Rationale:** Would be the public hot-apply verb; blocked by question 5's decision. Defer to v1.4 under a `Scrypath.Meilisearch.*`-prefixed task if ever.

#### M-4: `mix scrypath.settings.read [Schema]` — **SHIP IN V1.3**

- **Purpose:** Prints the live index's current settings as a plain Elixir map (debugging / drift investigation).
- **Thin delegate:** Calls `Scrypath.Meilisearch.Settings.read/2` (thin wrapper over `GET /settings`).
- **Use case:** "I'm tracking down why ranking seems off; show me what Meilisearch thinks the settings are."
- **Why now:** Without this, users drop to `curl` or the Meilisearch dashboard. `read` is the debuggability primitive that `diff` builds on.

---

## Sources

### Primary (HIGH confidence — direct reads)
- `/Users/jon/projects/scrypath/lib/scrypath/options.ex` (schema option shape, current `validate_settings/1` permissiveness)
- `/Users/jon/projects/scrypath/lib/scrypath/schema.ex` (reflection DSL pattern)
- `/Users/jon/projects/scrypath/lib/scrypath/meilisearch/settings.ex` (current `resolve/2` merge semantics; `apply/3` flow)
- `/Users/jon/projects/scrypath/lib/scrypath/reindex.ex` (managed reindex ordering)
- `/Users/jon/projects/scrypath/.planning/research/{STACK,FEATURES,ARCHITECTURE,PITFALLS,SUMMARY}.md`
- `/Users/jon/projects/scrypath/.planning/PROJECT.md` (non-goals, milestone scope)

### Reference libraries (HIGH for linked docs, MEDIUM for behavioral details)
- [Searchkick README (ankane/searchkick)](https://github.com/ankane/searchkick) — `search_synonyms` declarative shape, reindex discipline
- [algoliasearch-rails README](https://github.com/algolia/algoliasearch-rails) — `check_settings`, `algolia_dirty?`, settings diff pattern
- [Algolia Rails index settings docs](https://www.algolia.com/doc/framework-integration/rails/index-configuration/index-settings) — `customRanking`, `minWordSizefor1Typo`, typoTolerance enum
- [typesense-rails README](https://github.com/typesense/typesense-rails) — `multi_way_synonyms` / `one_way_synonyms` split
- [Typesense Synonym Sets docs (v30.1)](https://typesense.org/docs/30.1/api/synonyms.html) — one-way vs multi-way semantics
- [Laravel Scout 12.x docs](https://laravel.com/docs/12.x/scout) — Meilisearch driver settings surface
- [meilisearch-laravel-scout#16](https://github.com/meilisearch/meilisearch-laravel-scout/issues/16) — user complaint about no declarative ranking rules / synonyms
- [DeepMerge (PragTob/deep_merge)](https://github.com/PragTob/deep_merge) — Elixir deep-merge idiom and gotchas

### Meilisearch documentation (HIGH confidence)
- [Meilisearch Settings API reference](https://www.meilisearch.com/docs/reference/api/settings) — partial-update semantics, default values
- [Meilisearch Settings specification (0123)](https://specs.meilisearch.dev/specifications/text/0123-settings-api.html) — canonical setting shapes
- [Meilisearch Ranking Rules docs](https://www.meilisearch.com/docs/learn/relevancy/ranking_rules) — default rule set, `words` rule semantics
- [Meilisearch Typo Tolerance specification (0117)](https://specs.meilisearch.dev/specifications/text/0117-typo-tolerance-setting-api.html) — nested `minWordSizeForTypos` shape
- [Meilisearch Synonyms docs](https://www.meilisearch.com/docs/learn/relevancy/synonyms) — one-way vs bidirectional configuration
- [Meilisearch v1.15 release notes](https://github.com/meilisearch/meilisearch/releases/tag/v1.15.0) — `disableOnNumbers` addition
- [meilisearch#4484 (Swapping searchableAttributes)](https://github.com/meilisearch/meilisearch/issues/4484) — ongoing work to make more settings hot-applicable
- [meilisearch#1135 (Synonym doesn't work as expected)](https://github.com/meilisearch/MeiliSearch/issues/1135) — bidirectional synonym confusion

### Elixir ecosystem DSL precedents (MEDIUM confidence)
- [Ecto.Schema docs](https://hexdocs.pm/ecto/Ecto.Schema.html) — compile-time validation idiom
- [Ash framework README](https://github.com/ash-project/ash) — Spark DSL and capability-based extensions
- [NimbleOptions docs](https://hexdocs.pm/nimble_options) — nested-schema validation used throughout Scrypath

---

*Deep research for: Scrypath v1.3 Phase 19 (Relevance Tuning) — opinionated design landing.*
*Researched: 2026-04-17*
*Status: Ready for Phase 19 plan-level consumption by gsd-roadmapper.*
