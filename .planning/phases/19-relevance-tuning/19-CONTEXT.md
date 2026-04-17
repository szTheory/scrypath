# Phase 19: Relevance Tuning - Context

**Gathered:** 2026-04-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship declarative per-schema relevance tuning (synonyms, typo tolerance, ranking rules, distinct attribute, stop words) as structured nested subkeys of the existing `settings:` schema option, applied only through the managed `Scrypath.reindex/2` pipeline. Adds a post-apply read-back verification step that blocks cutover on drift, a ranking-rules safety rail (compile-time warning + reindex-time hard error when the six Meilisearch defaults are not all present), shallow-by-default settings-override merge with explicit `settings_merge: :deep` opt-in, two new mix tasks (`scrypath.settings.diff`, `scrypath.settings.read`), and a stub `Scrypath.Meilisearch.Settings.hot_apply/3` returning `{:error, :hot_apply_disabled}` (real implementation deferred to v1.4). Strictly additive over `scrypath 0.3.0`: no breaking changes to v1.2 public contracts, no second public backend, no vector/hybrid/semantic search, no per-query ranking overrides, no dashboard surface.

</domain>

<decisions>
## Implementation Decisions

### Opt-out flag surface (split placement, one coherent rule)

- **D-01:** **Coherent placement rule:** safety rails declared at the boundary they protect; emergency bypasses at the call site of the action they bypass. Mirrors `Ecto.Schema`'s `has_many :posts, on_replace: :delete` (modifier co-located with the declaration) and Ash's `Ash.read(authorize?: false)` (operational bypass at the call site). Operators learn ONE mental model that scales to every future opt-out.
- **D-02:** **`ranking_rules_strict?` lives INSIDE the `settings:` map** (`settings: %{ranking_rules: [...], ranking_rules_strict?: false}`). Co-located with the rule it modifies; PR review sees both in one screen; grep returns the same file. Compile-time check fires in the same validator that checks the rules themselves.
- **D-03:** **`skip_settings_verification?` lives as a runtime opt on `Scrypath.reindex/2`** (`Scrypath.reindex(MyApp.Post, skip_settings_verification?: true)`). Bounded blast radius: one reindex call. Next invocation picks up the default (verify on). Disappears after the run; impossible to set-and-forget. Logger.warning + `[:scrypath, :reindex, :verify_skipped]` telemetry emit when used so post-mortems find it.
- **D-04:** **Reserve suffix `*_strict?` as Scrypath-internal namespace.** `Scrypath.Meilisearch.Settings.translate_settings/1` strips any key whose name ends in `_strict?` (and an explicit allowlist of other Scrypath meta keys) before sending JSON to Meilisearch. Lets TUNE-01 #4 unknown-subkey passthrough remain forward-compatible (unknown non-`?`-suffixed keys pass through; `?`-suffixed keys are Scrypath-internal).
- **D-05:** **Resolves the apparent TUNE-04/TUNE-05 contradiction.** TUNE-04's "on the schema" means "in the `settings:` map, which is declared on the schema" (placement D-02). TUNE-05's "runtime" means runtime opt (placement D-03). They are not contradictory; they are different placements for two different *classes* of flag.
- **D-06:** **Setting `skip_settings_verification?` inside the `settings:` map raises a clear error**: `"skip_settings_verification? is a runtime opt for Scrypath.reindex/2, not a settings value. Move it out of the settings map."` — explicit-fail rather than silent-misplace.

### Settings-merge scope and per-repo cascade

- **D-07:** **`settings_merge` added to `@reindex_options` and `@runtime_options` only.** NimbleOptions schema entry: `type: {:in, [:replace, :deep]}, default: :replace`. Auto-generated error on invalid value: `expected :settings_merge to be one of [:replace, :deep], got: :fooey`.
- **D-08:** **NOT added to `@backfill_options`.** Same plan removes the existing inert `:settings` opt from `@backfill_options` (it was never consumed — `Scrypath.backfill/2` does not call `Settings.apply/3` per TUNE-03; the opt was plumbing-that-looks-like-it-does-something-but-doesn't). CHANGELOG flags this as removal of an inert opt, not a behavior change.
- **D-09:** **Default `:replace` is semantically identical to v1.2's `Map.merge/2`** in `Settings.resolve/2`. Backward-compat regression test asserts `resolve(schema, [])` returns the same map as v1.2 for the existing test fixtures. TUNE-06 acceptance criterion 4 satisfied.
- **D-10:** **NEW per-repo cascade source in `Scrypath.Config.resolve!/1`.** Discovered during research: today `Config.resolve!/1` only reads `Application.get_env(:scrypath, :defaults, [])`. The RELEVANCE.md test-env recipe (`config :my_app, MyApp.Repo.scrypath, settings: %{...}, settings_merge: :deep`) DOES NOT WORK against shipped 0.3.0 — it relies on a per-repo cascade that doesn't exist. Phase 19 adds that cascade as a NEW source between `:scrypath, :defaults` and per-call opts. Right-biased: per-call wins over per-repo wins over library-global.
- **D-11:** **Right-biased precedence everywhere** when `settings_merge` is set in multiple layers (config + per-call): per-call wins. Documented explicitly in the relevance-tuning guide; matches Ecto/Phoenix/Oban precedent (later source wins).
- **D-12:** **Hand-roll deep-merge** (~12 LOC, maps-only, no protocol overhead, no list-semantics ambiguity) in `Scrypath.Meilisearch.Settings`. Avoids taking `{:deep_merge, ...}` as a runtime dep for one merge primitive.
- **D-13:** **Single validator entry point.** `validate_settings/1` validates whatever keys are present (partial maps allowed) and enforces nested subkey shape only WHEN PRESENT. NimbleOptions nested schemas use `required: false` for all nested keys. Cross-field constraints (`distinct_attribute ∈ fields`) are compile-time schema checks in the `Scrypath.__using__` macro, not runtime settings-validator checks. This simpler-than-two-validators design also means runtime overrides like `settings: %{typo_tolerance: %{enabled: false}}` validate cleanly even though they omit `min_word_size_for_typos`.
- **D-14:** **Correction to RELEVANCE.md:** the "DeepMerge ~40% surprise rate" citation in RELEVANCE.md §2 is unsubstantiated — verified directly against the README. Real load-bearing arguments for shallow-default are [phoenix#5758](https://github.com/phoenixframework/phoenix/issues/5758) (deep-merge clobbering `socket_opts` defaults) and Oban's `queues: []` non-reset gotcha. Phase 19 planning must NOT cite the ~40% figure.

### Backward-compat cutover (Posture D — normalize-on-entry)

- **D-15:** **Critical discovery:** the v0.3.0 in-the-wild `settings:` shape surface is THREE shapes, not two. Shipped test fixtures (`test/support/searchable_post.ex:20-26`, `test/scrypath/options_test.exs:96,125`, `test/scrypath/reindex_test.exs:266`) use **atom-keyed camelCase** (`%{searchableAttributes: ["title"], typoTolerance: "min"}`). Real users could also be on string-keyed camelCase. After Phase 19 a third canonical shape (atom-snake-case `%{ranking_rules: [...]}`) joins. The original A/B/C postures (deprecate / dual-support / mixed-form-rejected) didn't account for shape #1.
- **D-16:** **Adopt Posture D — normalize-on-entry to one canonical internal form.** `validate_settings/1` routes through a new `normalize_settings/1` private function that accepts all three input shapes and produces a canonical form: `%{recognized_atom_snake_key: value, :__unrecognized__ => %{raw_key => raw_value, ...}}`. Recognized keys (synonyms, typo_tolerance, ranking_rules, distinct_attribute, stop_words, plus the existing camelCase Meilisearch keys we already use in tests like searchableAttributes) all canonicalize to atom-snake-case via `canonicalize_key/1` (`Macro.underscore/1` + `String.to_existing_atom/1` against the recognized allowlist).
- **D-17:** **Doubled-key footgun impossible by construction.** `Settings.resolve/2` normalizes BOTH the schema-declared settings (already canonical from compile-time validation) AND the runtime override BEFORE calling `Map.merge/2` or `deep_merge/2`. Both sides have identical key types (atoms only); both have a `:__unrecognized__` bucket that merges as a map. After merge, a single `translate_settings/1` pass converts canonical → Meilisearch-native camelCase string keys, with `:__unrecognized__` bucket entries passed through last (TUNE-01 #4 satisfied).
- **D-18:** **Zero deprecation warnings in v1.3.** All three input shapes continue to work permanently. Strictly additive over 0.3.0; honors the v1.3 non-goal "no breaking changes to v1.2 public contracts" absolutely. No v2.0 plan needed for this gray area — three accepted shapes collapsing to one canonical form is stable steady state.
- **D-19:** **Optional informational compile-time hint** (`IO.puts :stderr`, once per module, NOT `Logger.warning`) when the validator detects camelCase keys: `"[scrypath] MyApp.Blog.Post declared settings using camelCase keys. Canonical form is snake_case atom keys for recognized settings. Both forms work; no action required."` Explicitly non-nagging — informational only.
- **D-20:** **No `mix scrypath.upgrade.0.4` task in v1.3.** Listed in the deferred-ideas section as a possible v1.4 nice-to-have if adopter feedback indicates the camelCase → snake-case migration is wanted. Not load-bearing for Phase 19.
- **D-21:** **Operational-honesty alignment:** Posture D is the only posture surveyed where typos in recognized-key names land somewhere observable (the `:__unrecognized__` bucket, surfaced in `mix scrypath.settings.diff` output) instead of being silently ignored by Meilisearch. This is the strongest match to Scrypath's core value among the postures considered.

### Plan splitting (7 plans in 6 waves)

- **D-22:** **Adopt 7-plan / 6-wave split** matching Phase 18's empirical precedent (granular per-concern plans, file-disjoint waves, single closing `feat(NN):` commit for release-please). Each plan 80–450 LOC; under Google's 200-LOC review-effectiveness inflection point per logical unit. Atomic commit per plan. Plan-to-TUNE-ID mapping tight enough that the verifier can check each acceptance criterion against a specific plan.
- **D-23:** **Plan roster:**
  - **19-01 (Wave 1)** — NimbleOptions nested schema + `validate_settings/1` + `normalize_settings/1` + `canonicalize_key/1` + `:settings_merge` opt added to `@reindex_options`+`@runtime_options` (NOT backfill) + `:settings` opt removed from `@backfill_options` + `hot_apply/3` stub. **TUNE IDs:** 01a, 02 validation half, 04a (compile-time warning), 06a, 03 stub. **Files:** `lib/scrypath/options.ex`, `lib/scrypath/meilisearch/settings.ex` (stub only). **Depends on:** none.
  - **19-02 (Wave 2)** — `expand_synonyms/1` (with bidirectional + one_way nested key) + `translate_settings/1` (canonical atom-snake → Meilisearch camelCase + `__unrecognized__` passthrough + strip Scrypath meta keys) + `Settings.resolve/2` extension to honor `:settings_merge` mode (normalize both sides before merge) + hand-rolled `deep_merge/2`. **TUNE IDs:** 02 expansion half, 01b translate, 06b merge modes. **Files:** `lib/scrypath/meilisearch/settings.ex`. **Depends on:** 19-01.
  - **19-03 (Wave 3)** — `Scrypath.Meilisearch.Client.get_settings/2` + `Scrypath.Meilisearch.Settings.verify_applied/3` (key-by-key drift detection; returns `:ok` or `{:error, {:settings_drift, [{key, declared, actual}, ...]}}`; index-not-found case). **TUNE IDs:** 05a. **Files:** `lib/scrypath/meilisearch/client.ex`, `lib/scrypath/meilisearch/settings.ex` (additive append). **Depends on:** 19-01.
  - **19-04 (Wave 4)** — Reindex flow integration (insert verify step in `Scrypath.Reindex.run/2` between `apply_settings`+wait and `backfill`) + ranking-rules reindex-time hard error (when `ranking_rules_strict?` is true and rules are missing) + `skip_settings_verification?` runtime opt honoring + Logger.warning + `[:scrypath, :reindex, :verify_skipped]` telemetry + per-repo cascade source added to `Scrypath.Config.resolve!/1`. **TUNE IDs:** 03 full, 04b reindex-time error, 05b wiring, 06b cascade. **Files:** `lib/scrypath/reindex.ex`, `lib/scrypath/config.ex`. **Depends on:** 19-02, 19-03.
  - **19-05 (Wave 5)** — `mix scrypath.settings.diff` (thin delegate over `verify_applied/3`; flags `--repo`, `--index-prefix`, `--json`; exit code 2 on drift, 0 on parity, 1 on runtime error — same exit-code discipline as Phase 18's `verify.release_parity`). **TUNE ID:** 07. **Files:** `lib/mix/tasks/scrypath.settings.diff.ex`. **Depends on:** 19-03, 19-04. **Parallel with 19-06.**
  - **19-06 (Wave 5)** — `mix scrypath.settings.read` (thin delegate over `client.get_settings/2`; flags `--repo`, `--index-prefix`; pretty-prints applied settings as Elixir map). **TUNE ID:** 08. **Files:** `lib/mix/tasks/scrypath.settings.read.ex`. **Depends on:** 19-03. **Parallel with 19-05.**
  - **19-07 (Wave 6)** — `guides/relevance-tuning.md` (covers the 5 settings + ranking safety rail + verify/drift section + mix task usage + `one_way:` synonym sugar + `:settings_merge` example with three-source cascade diagram + footnoted hot_apply v1.4 deferral) + `CHANGELOG.md` Unreleased entry naming all 8 TUNE-IDs and `:hot_apply_disabled` deliberate-deferral bullet + closing `feat(19): add declarative relevance tuning ...` commit per Phase 18 precedent. **TUNE IDs:** none directly; documents 01-08. **Files:** `guides/relevance-tuning.md`, `CHANGELOG.md`, `mix.exs` (new `cli.preferred_envs` entries for the two new mix tasks). **Depends on:** 19-01..06.
- **D-24:** **Closing commit triggers release-please.** Phase 19's `feat(19):` Conventional Commit lands on `main`; release-please opens a release PR cutting `0.4.0 → 0.5.0`; merging promotes `mix.exs` `@version`, cuts tag `scrypath-v0.5.0`, triggers `publish-hex` job (gated by Phase 18's `verify.workspace_clean` + `verify.release_parity`), publishes to Hex. Same ritual as Phase 18 → 0.4.0; same automation; no separate milestone-close action needed for v1.3 phase 19.
- **D-25:** **Plan-numbering follows Phase 18 convention** (`19-01-PLAN.md` … `19-07-PLAN.md`); each plan's frontmatter declares `wave`, `depends_on`, `files_modified`, `autonomous: true` for 19-01..06 and `autonomous: false` for 19-07 (maintainer confirms CHANGELOG wording before commit).
- **D-26:** **Test-location convention** (mirrors Phase 18): `test/scrypath/options_test.exs`, `test/scrypath/meilisearch/settings_test.exs`, `test/scrypath/meilisearch/client_test.exs`, `test/scrypath/reindex_test.exs` for unit tests; `test/mix/tasks/scrypath_settings_diff_test.exs`, `test/mix/tasks/scrypath_settings_read_test.exs` for the new mix tasks.

### Claude's Discretion

- Exact telemetry measurements/metadata shape for `[:scrypath, :reindex, :settings_verified]` and `[:scrypath, :reindex, :verify_skipped]` (match the existing `[:scrypath, :reindex, ...]` envelope from `Scrypath.Telemetry.span/3`).
- Exact text of the optional informational compile-time hint for camelCase usage (D-19) — match existing Scrypath copy tone from `lib/scrypath/options.ex` and Phase 18 error messages.
- JSON field ordering in `mix scrypath.settings.diff --json` output (stable ordering per the field shape in RELEVANCE.md §M-1 7a).
- Hand-rolled `deep_merge/2` implementation details (no recursion limit needed for the bounded settings tree depth; map-only semantics; treat all non-map values as terminal).
- Whether to run `Macro.underscore/1` on string keys at canonicalize time (recommended) or keep them in the `:__unrecognized__` bucket as-is — depends on the recognized-key allowlist's coverage.
- The exact CHANGELOG entry copy for D-08 (removal of inert `:settings` opt from `@backfill_options`) — phrase as removal of inert plumbing, not behavior change.

### Folded Todos

None. `gsd-tools todo match-phase 19` returned zero matches; nothing in the project todo backlog intersects Phase 19 scope.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 19 requirements and roadmap

- `.planning/ROADMAP.md` §"Phase 19: Relevance Tuning" — goal statement, 5 success criteria, dependency on Phase 18 (release-parity gate inheritance)
- `.planning/REQUIREMENTS.md` §"Relevance Tuning (prefix: TUNE)" — TUNE-01 through TUNE-08 canonical acceptance criteria; note D-05 resolves the apparent TUNE-04/TUNE-05 placement contradiction
- `.planning/PROJECT.md` §"Constraints" — operational-honesty core value; Meilisearch-first; Ecto-first/Phoenix-friendly; no breaking changes to v1.2 public contracts
- `.planning/STATE.md` — current milestone position, prior-phase decisions log

### Deep research synthesis

- `.planning/research/deep/RELEVANCE.md` — full design landing for declarative relevance tuning. **Phase 19 implements this with five corrections/clarifications captured in CONTEXT.md decisions:**
  - D-05 resolves TUNE-04 vs TUNE-05 placement (split rule per D-01..03)
  - D-10 fixes the test-env recipe assumption (per-repo cascade source must be added; doesn't exist today)
  - D-14 corrects the unsubstantiated DeepMerge "~40% footgun" citation
  - D-15..21 supersede RELEVANCE.md's implicit two-shape BC model with Posture D (three-shape normalize-on-entry)
  - D-22..26 set the 7-plan/6-wave shape that RELEVANCE.md left to the planner
- `.planning/research/SUMMARY.md` §"Phase 1 (B/relevance) and milestone ordering" — phase-ordering rationale (relevance is the narrowest translation pattern; faceting reuses it; multi-index depends on facet parity)

### Existing code prior art (reuse, do not recreate)

- `lib/scrypath/options.ex` — `validate_settings/1` at line 327 is the entry point that gets routed through `normalize_settings/1` (D-16). The three `@runtime_options`/`@reindex_options`/`@backfill_options` schemas at lines 42-203, 206-277, 133-203 are the surface that gets `:settings_merge` added (D-07) and `:settings` removed from backfill (D-08).
- `lib/scrypath/meilisearch/settings.ex` (32 LOC today) — `resolve/2` at line 8 gets the normalize-before-merge change (D-17) and `:settings_merge` mode honoring (D-12). `apply/3` at line 14 gets `translate_settings/1` wired in front of `Client.update_settings/3`. New functions added: `normalize_settings/1`, `canonicalize_key/1`, `expand_synonyms/1`, `translate_settings/1`, `verify_applied/3`, `hot_apply/3` stub.
- `lib/scrypath/reindex.ex` — `run/2` at line 11 is the `with` chain that gets the verify step inserted between apply_settings-wait (line 25) and backfill (line 27). `skip_settings_verification?` is read from `workflow_config` (D-03).
- `lib/scrypath/meilisearch/client.ex` — `update_settings/3` at line 21 is the existing PATCH; `get_settings/2` is the new GET added in plan 19-03 alongside it (D-23).
- `lib/scrypath/config.ex` — `Scrypath.Config.resolve!/1` is the cascade entry point that gets the new per-repo source added (D-10). Currently reads only `Application.get_env(:scrypath, :defaults, [])`.
- `lib/scrypath/schema.ex` — `__scrypath__(:settings)` reflection at line 35; the canonical form from D-16 is what gets stored here. Compile-time validation in the `Scrypath.__using__` macro is where the cross-field check `distinct_attribute ∈ fields` lives (D-13).
- `lib/scrypath.ex` — `schema_settings/1` at line 40 is the read-side helper; it returns the canonical form.

### Mix task prior art (copy patterns)

- `lib/mix/tasks/verify.release_parity.ex` (Phase 18) — exit-code discipline (0 parity, 2 drift, 1 runtime error) that `mix scrypath.settings.diff` reuses (D-23 plan 19-05). `--json` flag pattern, `Mix.shell().info/1` for human output, `System.cmd/3` shell-out idiom.
- `lib/mix/tasks/scrypath.status.ex`, `scrypath.failed.ex`, `scrypath.reconcile.ex`, `scrypath.retry.ex` (Phase 14) — thin-delegate Mix task convention; `--repo`, `--index-prefix` flag handling; module naming `Mix.Tasks.Scrypath.<Verb>` under `lib/mix/tasks/scrypath.<verb>.ex`.

### Phase 18 inheritance (release-parity gate)

- `.planning/phases/18-release-parity-gate-node-20-ci-cleanup/18-CONTEXT.md` — D-22 closing-commit ritual (`feat(NN):` triggers release-please) directly inherited; D-26 test-location convention reused; the workspace_clean + release_parity gate now protects every Phase 19 commit.
- `.github/workflows/ci.yml`, `release-please.yml`, `publish-hex.yml`, `verify-published-release.yml` — already gated; Phase 19 inherits without workflow edits.

### External references (idiom calibration)

- **Ecto.Schema** ([hexdocs](https://hexdocs.pm/ecto/Ecto.Schema.html)) — `has_many :posts, on_replace: :delete` is the canonical "modifier co-located with declaration" pattern that justifies D-02.
- **Ash framework Policies** ([hexdocs](https://hexdocs.pm/ash/policies.html)) — `Ash.read(actor: user, authorize?: false)` is the canonical "operational bypass at the call site" pattern that justifies D-03.
- **NimbleOptions** ([hexdocs](https://hexdocs.pm/nimble_options)) — nested-schema validation; `{:in, [:replace, :deep]}` validator type with auto-generated error message (D-07).
- **Meilisearch Settings API** ([reference](https://www.meilisearch.com/docs/reference/api/settings)) — camelCase-only on the wire; silently ignores unknown keys (the failure mode Posture D is designed to surface).
- **Searchkick `search_synonyms`** ([README](https://github.com/ankane/searchkick)) — list-of-arrays bidirectional synonym pattern that TUNE-02 mirrors with the `[["nyc", "new york"]]` sugar form.
- **algoliasearch-rails `check_settings`** ([README](https://github.com/algolia/algoliasearch-rails)) — closest analog to Scrypath's verify-applied; documented set-and-forget failure mode of class-level placement is why D-03 chose runtime placement for `skip_settings_verification?`.
- **DeepMerge (PragTob/deep_merge)** ([README](https://github.com/PragTob/deep_merge)) + [elixir-lang#5339 rejected stdlib PR](https://github.com/elixir-lang/elixir/pull/5339) — community evidence that shallow-merge is the Elixir default; D-12 hand-rolls instead of taking the dep.
- **phoenix#5758** ([issue](https://github.com/phoenixframework/phoenix/issues/5758)) — real-world deep-merge surprise that justifies D-09 shallow-default; supersedes the unsubstantiated "DeepMerge ~40%" citation in RELEVANCE.md (D-14).
- **Google eng-practices "Small CLs"** ([guide](https://google.github.io/eng-practices/review/developer/small-cls.html)) — review-effectiveness inflection at ~200 LOC justifies D-22 granular split.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`Scrypath.Telemetry.span/3` envelope** (used throughout `lib/scrypath/meilisearch/client.ex`) — new `[:scrypath, :reindex, :settings_verified]` and `[:scrypath, :reindex, :verify_skipped]` events use this envelope for consistency with the existing `[:scrypath, :reindex, ...]` namespace.
- **`Scrypath.Meilisearch.Tasks.wait_for_task/2`** (`lib/scrypath/meilisearch/tasks.ex`) — already used in `Reindex.maybe_wait_for_result_task/2` for the apply_settings step. The new verify step runs AFTER this wait completes, so no new task-following primitive is needed.
- **`Scrypath.Meilisearch.Client.run_request/5` + Req scaffolding** (`lib/scrypath/meilisearch/client.ex:91`) — `get_settings/2` is a 5-line addition matching the existing `update_settings/3` shape (just method=:get, no body).
- **`mix.exs cli.preferred_envs`** (lines 38-48) — two new entries slot in cleanly for `scrypath.settings.diff` and `scrypath.settings.read` (both `:test` if they have integration tests; otherwise `:dev`).
- **NimbleOptions nested-schema pattern** — already used throughout `lib/scrypath/options.ex` for the four `@*_options` schemas. The new nested settings validator extends this idiom; no new framework needed.
- **`Macro.underscore/1` + `Macro.camelize/1`** — Elixir stdlib primitives for the canonicalize/translate functions; already used in `client.ex:158-163` (`camelize_filter/1`).

### Established Patterns

- **Atom-keyed-camelCase settings shape** is the v0.3.0 in-the-wild norm — used by `test/support/searchable_post.ex:20-26`, `test/scrypath/options_test.exs:96,125`, `test/scrypath/reindex_test.exs:266`. Posture D (D-16) accommodates this without breakage; this discovery was the key insight from the BC research (D-15).
- **Mix task naming:** `Mix.Tasks.Scrypath.<Verb>` under `lib/mix/tasks/scrypath.<verb>.ex` (established by Phase 14's `scrypath.status`, `.failed`, `.reconcile`, `.retry`). Phase 19 follows directly: `Mix.Tasks.Scrypath.Settings.Diff`, `Mix.Tasks.Scrypath.Settings.Read` under `lib/mix/tasks/scrypath.settings.diff.ex`, `scrypath.settings.read.ex`.
- **Mix verify task naming** (`Mix.Tasks.Verify.*`) is the OTHER namespace (Phase 18's `verify.workspace_clean`, `verify.release_parity` etc.) — relevance-tuning tasks belong to the `Scrypath.*` namespace because they query/inspect schema state, not parity verify.
- **Exit code discipline:** Phase 18's `verify.release_parity` uses `0`/`2`/`1` (parity/drift/runtime-error). `mix scrypath.settings.diff` reuses this exactly (D-23 plan 19-05).
- **`with`-chain reindex flow** (`reindex.ex:20-35`) — verify step inserts cleanly as one new line in the chain; same `{:ok, _} | {:error, term()}` shape as adjacent steps. No restructuring needed.
- **Scrypath-owned vs Meilisearch-native split** — Scrypath-native lives at `Scrypath.Meilisearch.Settings` (canonical atom-snake form, normalize/expand/translate); Meilisearch-native is what crosses the wire (camelCase string keys after `translate_settings/1`). Phase 12's seam pattern.
- **`Scrypath.Config.resolve!/1` cascade** (`lib/scrypath/config.ex`) — currently single-source from `:scrypath, :defaults`. D-10 adds a per-repo source; the cascade pattern itself is a simple `Keyword.merge/2` chain, no new cascade framework needed.

### Integration Points

- `lib/scrypath/options.ex` L327 — `validate_settings/1` gets routed through `normalize_settings/1` (NEW private fn) + `validate_recognized_subkeys/1` (NEW). Three `@*_options` schemas get `:settings_merge` added (D-07) and `@backfill_options` loses `:settings` (D-08).
- `lib/scrypath/meilisearch/settings.ex` — `resolve/2` extension (D-17 normalize-before-merge), `apply/3` extension (translate before update_settings call). NEW functions: `normalize_settings/1`, `canonicalize_key/1`, `expand_synonyms/1`, `translate_settings/1`, `verify_applied/3`, `hot_apply/3` stub, `deep_merge/2` private helper, `strip_scrypath_meta_keys/1` private helper.
- `lib/scrypath/meilisearch/client.ex` — NEW `get_settings/2` (5-line GET via `run_request/5`).
- `lib/scrypath/reindex.ex` L20-35 — insert verify step in `with` chain between L25 (settings-wait) and L27 (backfill); read `skip_settings_verification?` from `workflow_config`; emit `[:scrypath, :reindex, :verify_skipped]` telemetry when bypassed; emit `[:scrypath, :reindex, :settings_verified]` when not. Insert ranking-rules reindex-time guard before the `with` chain (compile-time guard already in `validate_settings/1`).
- `lib/scrypath/config.ex` — `resolve!/1` extended to read `Application.get_env(otp_app, repo_module, [])[:scrypath]` as a NEW middle cascade source between `:scrypath, :defaults` and per-call opts (D-10).
- `lib/scrypath/schema.ex` — `__scrypath__(:settings)` reflects the canonical form (no code change; just contractual update — what's stored is now post-normalize).
- `lib/mix/tasks/scrypath.settings.diff.ex` NEW — thin delegate over `verify_applied/3`; `--repo`, `--index-prefix`, `--json` flags; exit `0`/`2`/`1`.
- `lib/mix/tasks/scrypath.settings.read.ex` NEW — thin delegate over `client.get_settings/2`; `--repo`, `--index-prefix` flags.
- `mix.exs` `cli.preferred_envs` — two new entries: `"scrypath.settings.diff": :test`, `"scrypath.settings.read": :test`.
- `guides/relevance-tuning.md` NEW — covers all 5 settings + safety rail + verify/drift + mix tasks + `:settings_merge` cascade + hot_apply v1.4 deferral note.
- `CHANGELOG.md` Unreleased — names all 8 TUNE-IDs, the `:hot_apply_disabled` deliberate-deferral, the `:settings`-from-backfill removal-of-inert-opt, and Posture D normalization.
- `test/scrypath/options_test.exs` — extend with: nested settings validation tests (TUNE-01); `normalize_settings` 3-shape tests (D-15..16); `canonicalize_key` allowlist tests (D-16); `:settings_merge` value validation (D-07); ranking-rules compile-time warning emission (D-23 plan 19-01).
- `test/scrypath/meilisearch/settings_test.exs` — extend with: `expand_synonyms` property/edge tests (TUNE-02); `translate_settings` snake→camel + `__unrecognized__` passthrough + meta-key stripping (D-04, D-17); `verify_applied` happy path + drift + index-not-found (TUNE-05); `hot_apply` stub (D-23 plan 19-01); `:settings_merge` `:replace` vs `:deep` (D-09, D-12); doubled-key impossibility regression (D-17).
- `test/scrypath/meilisearch/client_test.exs` — extend with: `get_settings` happy path + index-not-found (D-23 plan 19-03).
- `test/scrypath/reindex_test.exs` — extend with: ordering assertion (create → apply → verify → backfill → cutover) (TUNE-03); verify-drift blocks cutover (TUNE-05); ranking-rules missing-rule reindex-time error (TUNE-04); `skip_settings_verification?` opt-out path with telemetry emission (D-03).
- `test/mix/tasks/scrypath_settings_diff_test.exs` NEW — TUNE-07.
- `test/mix/tasks/scrypath_settings_read_test.exs` NEW — TUNE-08.

</code_context>

<specifics>
## Specific Ideas

- **"One-shot perfect recommendations" posture from the user:** every gray area resolved with a single coherent pick across the four decisions; no options held in limbo for "we'll decide at planning time." All four areas were researched in parallel by subagents and synthesized into a coherent set; the user locked all four together rather than revisiting individually.
- **Coherence as the explicit success criterion:** Gray Area 1's `skip_settings_verification?` placement (runtime opt) matches Gray Area 2's "hoist out of settings map." Gray Area 1's `ranking_rules_strict?` placement (in settings map) cleanly works with Gray Area 4's normalizer (treats `*_strict?` as a recognized meta-key). Gray Area 4's normalize-on-entry eliminates the doubled-key footgun Gray Area 2 surfaced in `Map.merge/2`. Gray Area 3's plan structure absorbs all of these without boundary moves.
- **Two material discoveries from the research that override RELEVANCE.md:**
  1. **The test-env recipe assumes a per-repo cascade that doesn't exist today** (D-10) — RELEVANCE.md's `config :my_app, MyApp.Repo.scrypath, ...` example would silently no-op against shipped 0.3.0. Phase 19 must add the cascade.
  2. **The in-the-wild settings shape is atom-keyed camelCase, not string-keyed** (D-15) — our own shipped test fixtures use this shape; original A/B/C postures didn't account for it. Posture D is the only posture that handles all three actual-shapes-in-the-wild without breakage.
- **One correction to RELEVANCE.md** (D-14): the "DeepMerge ~40% surprise rate" citation is unsubstantiated. Don't propagate. Real arguments for shallow-default are phoenix#5758 and Oban's `queues: []` gotcha.
- **Operational-honesty consistency:** Posture D's `:__unrecognized__` bucket surfaces typos and unknown keys instead of letting Meilisearch silently ignore them. Matches Phase 12's seam philosophy (Scrypath-owned at the boundary; backend-native namespaced).
- **Phase 18 inheritance is load-bearing:** the closing `feat(19):` commit + release-please cut + workspace_clean/release_parity gates means Phase 19 ships to Hex 0.5.0 with the same divergence-prevention guarantees Phase 18 mechanized. No Phase 19 plan needs to think about release safety.

</specifics>

<deferred>
## Deferred Ideas

- **Real `Scrypath.Meilisearch.Settings.hot_apply/3` implementation** — v1.3 ships only the stub returning `{:error, :hot_apply_disabled}` (D-23 plan 19-01). v1.4 may unlock under a guarded contract per RELEVANCE.md Q5: restricted subkey allowlist (synonyms / stop_words / typo_tolerance only), explicit `acknowledge_live_index: true` opt, telemetry event. Defer until adopter feedback proves the managed-reindex path is too slow for a real common case.
- **`mix scrypath.upgrade.0.4` migration task** — D-20: optional task that rewrites schemas from camelCase to canonical snake-case form. Posture D's normalize-on-entry makes both shapes work permanently, so this task is purely an ergonomic nice-to-have. Defer to v1.4 if adopter feedback indicates the conversion is wanted.
- **Ranking-rules-strict warning telemetry** — when `ranking_rules_strict?: false` is set and the safety rail is bypassed, RELEVANCE.md Q3 mentions `Logger.warning` only. Adding a `[:scrypath, :schema, :ranking_rules_relaxed]` telemetry event for ops dashboards is a v1.4 nice-to-have. Not load-bearing for Phase 19.
- **Per-query ranking overrides on `Scrypath.search/3`** — Hard non-goal locked in PROJECT.md and reinforced by RELEVANCE.md non-goal table. Search stays declarative; relevance is index-time. v2.0 conversation, not v1.4.
- **`Scrypath.apply_settings/2` public verb (bypasses reindex)** — Hard architectural rule from RELEVANCE.md Q5. Settings only flow through `Scrypath.reindex/2`. The stub `Scrypath.Meilisearch.Settings.hot_apply/3` is the placeholder; v1.4 would gate it under `Scrypath.Meilisearch.*` namespace, never lift to top-level `Scrypath.*`.
- **Auto-synonym generation from query logs / vector knobs / locale-aware stop words / per-environment ranking via mix opts** — All hard non-goals in RELEVANCE.md non-goal tripwire table. Test-env-different-settings IS in scope (supported via D-10 per-repo cascade + D-09 shallow-default merge); the OTHER use cases stay deferred.
- **Hot-applicable settings detection / capability signal** — RELEVANCE.md Q8 settles this as "invisible to users in v1.3." All settings flow through reindex uniformly; no `settings_policy: :hot_when_possible` schema flag in v1.3. v1.4 conversation.
- **SHA-256 hash comparison in `mix scrypath.settings.diff`** — diff is path-set + value equality only (matches `verify.release_parity` D-08 from Phase 18 — path-only, byte-equal would be ~20-LOC additive change if ever needed).
- **Cross-schema relevance blending in `search_many/2` (Phase 21)** — RELEVANCE.md §"With multi-index" — strictly per-schema in v1.3; cross-schema relevance is v1.4 namespaced under `Scrypath.Meilisearch.MultiSearch.federate/2`.

### Reviewed Todos (not folded)

None. `gsd-tools todo match-phase 19` returned zero matches.

</deferred>

---

*Phase: 19-relevance-tuning*
*Context gathered: 2026-04-17*
