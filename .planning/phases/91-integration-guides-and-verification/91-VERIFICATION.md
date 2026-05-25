---
phase: 91-integration-guides-and-verification
verified: 2026-05-25T08:00:00Z
status: human_needed
score: 11/11 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 9/11
  gaps_closed:
    - "An adopter can read one worked Author-rename example showing the schema-side fan_outs: declaration AND the context-side call for both sync_mode: :inline and sync_mode: :oban. (CR-01 — guide now teaches def __scrypath__(:fan_outs) hand-written accessor, prose note explains macro limitation, docs-contract asserts both strings.)"
    - "The guide's update_author/3 worked example returns {:ok, result, updated} matching the canonical blog.ex implementation and smoke-test assertions. (WR-02 — 2-tuple {:ok, updated} replaced with 3-tuple {:ok, result, updated}.)"
  gaps_remaining: []
  regressions: []
human_verification:
  - test: "Run SCRYPATH_EXAMPLE_INTEGRATION=1 mix test test/smoke/ inside examples/phoenix_meilisearch against a live Postgres + Meilisearch instance."
    expected: "Both meilisearch_related_inline_stack_test.exs and meilisearch_related_oban_stack_test.exs pass. The inline test asserts {:ok, %{mode: :inline, status: :completed}, _} and the oban test asserts {:ok, %{mode: :oban, status: :accepted}, _}, with the renamed author_name appearing in Post search results on both fan-out paths."
    why_human: "Requires a live Meilisearch instance and Postgres database. Cannot be verified programmatically in this environment."
---

# Phase 91: Integration, Guides, and Verification — Re-Verification Report

**Phase Goal:** Integration guides polished and verified — `sync_related/3` fan-out guide corrected, Phoenix example app exercising shipped fan-out APIs, hermetic verify task passing, docs-contract regression gates in place
**Verified:** 2026-05-25T08:00:00Z
**Status:** human_needed
**Re-verification:** Yes — after gap closure (plans 91-04 closed CR-01 and WR-02)

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Guide presents `Scrypath.sync_related/3` + built-in Oban path as canonical (no temporary-workaround / first-class-feature framing) | VERIFIED | `grep -c -i 'temporary workaround'` → 0; `grep -c -i 'first-class feature'` → 0; canonical section "Fan-out with `Scrypath.sync_related/3`" present. `SyncAuthorPostsWorker` and `Oban.insert!` absent. |
| 2 | An adopter can read one worked Author-rename example showing the schema-side fan_outs: declaration AND the context-side call for both sync_mode: :inline and sync_mode: :oban | VERIFIED | Guide line 113: `def __scrypath__(:fan_outs)` with `target: MyApp.Blog.Post` and `resolver:` MFA. Lines 152-166: both inline and oban call snippets with correct return shapes. Prose note at line 133 explains `use Scrypath` does not generate `__scrypath__(:fan_outs)`. Docs-contract asserts both strings. CR-01 closed. |
| 3 | The guide's worked resolver handles BOTH owning-schema records (inline) AND owning-schema document IDs (oban) — the resolver-arity duality | VERIFIED | Guide lines 210-217 show `[%Author{} | _]`, `[_id | _]`, and `[]` clauses; both non-empty clauses funnel to `reload_posts/1`. Arity-duality callout at lines 177-183. |
| 4 | The "Picking the right follow-up path" section maps inline-vs-oban to blast radius + request latency and states RelatedWorker retry/cancel outcomes (D-04) and honesty boundary | VERIFIED | "blast radius" at lines 18 and 266-285; "durably queued" and "searchable now" at lines 159-162 and 303/307; retry/cancel outcome table with `max_attempts: 8` at line 319; authz warning (`index prefixes alone are`) at line 375. |
| 5 | The no-callback-magic / context-owns-orchestration / library-owns-execution invariant is stated in literal prose the docs-contract test will assert | VERIFIED | `callback magic` (2 occurrences), `contexts own orchestration` (2 occurrences), `library owns execution` (2 occurrences) all confirmed present in guide. All 9 canonical strings verified via `assert_contains_all` in docs-contract test. |
| 6 | `mix verify.phase91` exists, runs three hermetic related-data tests (no live Meilisearch), then builds docs with warnings-as-errors, and exits 0 | VERIFIED | `mix verify.phase91` executed: 73 tests, 0 failures; `mix docs --warnings-as-errors` exited 0 with no warnings. `lib/mix/tasks/verify.phase91.ex` contains exactly the 3 hermetic focused paths, no `examples/` paths (`grep -c 'examples/'` → 0). |
| 7 | The docs-contract test asserts the canonical sync_related/3 story and forbids temporary-workaround / first-class-feature strings (plus regression-guards accessor pattern and prose note) | VERIFIED | Test "related-data guide adopts sync_related/3 as the canonical fan-out story" (line 1137) `refute`s both banned strings and `assert_contains_all` over 9 canonical strings including `"def __scrypath__(:fan_outs)"` and `"does not generate a \`__scrypath__(:fan_outs)\` accessor"`. Old test at line ~1128 replaced (`grep -c 'related-data guide explicitly mentions temporary Oban workaround'` → 0). |
| 8 | The new verify.phase91 task is discoverable: `@verify_phase91`, "stays wired" test, and `mix.exs` preferred_envs | VERIFIED | `@verify_phase91 File.read!("lib/mix/tasks/verify.phase91.ex")` at line 30; "verify.phase91 stays wired into the focused maintainer flow" test at line 343; `"verify.phase91": :test` at line 59 in mix.exs preferred_envs. |
| 9 | verify.phase91's focused test list contains ONLY hermetic library tests — no example smoke paths | VERIFIED | `@focused_tests` in `verify.phase91.ex` contains exactly: `related_test.exs`, `related_worker_test.exs`, `docs_contract_test.exs`. `grep -c 'examples/'` → 0. |
| 10 | Author schema declares a fan_outs: entry targeting Post via Blog context resolver; Blog context handles both resolver arities; blog.ex update_author/3 wired correctly | VERIFIED | `author.ex` hand-written `def __scrypath__(:fan_outs)` with `target: ScrypathDemo.Blog.Post` and `resolver: {ScrypathDemo.Blog, :resolve_posts_for_authors, []}`. `blog.ex` has 3 resolver clauses: `[%Author{} | _]`, `[_id | _]`, `[]`. `update_author/3` calls `Scrypath.sync_related/3` and returns `{:ok, result, updated}` (3-tuple). |
| 11 | The guide's update_author/3 worked example return value matches the canonical implementation | VERIFIED | Guide line 205: `{:ok, result, updated}` (3-tuple). `grep -c '{:ok, updated}$'` → 0. Matches `blog.ex` line 48 and both smoke test assertions. WR-02 closed. |

**Score:** 11/11 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `guides/related-data-and-reindexing.md` | Canonical sync_related/3 fan-out guide | VERIFIED | Working `def __scrypath__(:fan_outs)` accessor (line 113), prose note (line 133), correct 3-tuple return (line 205), all 9 canonical strings present, both banned strings absent |
| `lib/mix/tasks/verify.phase91.ex` | Mix.Tasks.Verify.Phase91 hermetic gate | VERIFIED | Exists (37 lines), defines module, 3 hermetic test paths, `reenable("test")` + `reenable("docs")`, `--warnings-as-errors` docs step |
| `test/scrypath/docs_contract_test.exs` | Inverted assertion + @verify_phase91 + stays-wired test + 9-string assert_contains_all | VERIFIED | All 4 edits present (A: `@verify_phase91`; B: stays-wired test; C: inverted test with 9 strings); old test replaced |
| `mix.exs` | `"verify.phase91": :test` in preferred_envs | VERIFIED | Confirmed at line 59 |
| `examples/.../blog/author.ex` | Author schema with hand-written __scrypath__(:fan_outs) + __scrypath__(:document_id) | VERIFIED | Both accessors present (lines 33-43); `use Ecto.Schema` only (not `use Scrypath`) |
| `examples/.../blog.ex` | Blog context: update_author/3 (3-tuple return) + arity-safe resolve_posts_for_authors/1 | VERIFIED | 3 resolver clauses; `update_author/3` returns `{:ok, result, updated}`; `Repo.update_all(author_name)` before `sync_related/3` |
| `examples/.../migrations/20250420000000_...exs` | authors table + posts.author_id + posts.author_name | VERIFIED | `create table(:authors)`, `add(:author_id, references(:authors))`, `add(:author_name, :string)` |
| `examples/.../blog/post.ex` (modified) | author_name in fields:, belongs_to Author | VERIFIED | `fields: [:title, :body, :author_name]`; `belongs_to(:author, ScrypathDemo.Blog.Author)`; `author_id`/`author_name` in changeset cast |
| `examples/.../meilisearch_related_inline_stack_test.exs` | Inline fan-out smoke | VERIFIED | `@moduletag :integration`; drives `Blog.update_author/3` with `sync_mode: :inline`; asserts 3-tuple `{:ok, %{mode: :inline, status: :completed}, _updated_author}` and `author_name: "Renamed Author"` in search result |
| `examples/.../meilisearch_related_oban_stack_test.exs` | Oban fan-out smoke (no UpsertWorker) | VERIFIED | `sync_mode: :oban`; asserts 3-tuple `{:ok, %{mode: :oban, status: :accepted}, _updated_author}`; `grep -c 'Scrypath.Oban.UpsertWorker'` → 0; `await_search` verifies renamed `author_name` |
| `examples/.../README.md` | Mentions sync_related/3 + fan-out smoke coverage | VERIFIED | Line 3: `Scrypath.sync_related/3` in intro; lines 71-72: inline + oban fan-out smokes documented in integration coverage |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `guides/related-data-and-reindexing.md` | `lib/scrypath.ex sync_related/3` | documented public API signature | VERIFIED | Guide contains `Scrypath.sync_related/3` 3 times; call signatures match shipped API |
| `guides/related-data-and-reindexing.md` (9 canonical strings) | `test/scrypath/docs_contract_test.exs` (inverted assertion) | literal substring contract | VERIFIED | All 9 strings in `assert_contains_all` match strings confirmed present in guide; `mix test docs_contract_test.exs` → 0 failures |
| `lib/mix/tasks/verify.phase91.ex` | `related_test.exs + related_worker_test.exs + docs_contract_test.exs` | @focused_tests list run in-process | VERIFIED | All 3 paths in `@focused_tests`; `Mix.Task.reenable("test")` present; no `examples/` paths |
| `test/scrypath/docs_contract_test.exs @verify_phase91` | `lib/mix/tasks/verify.phase91.ex` | File.read! at compile time | VERIFIED | `@verify_phase91 File.read!("lib/mix/tasks/verify.phase91.ex")` at line 30; stays-wired test asserts all 3 focused paths and `--warnings-as-errors` |
| `examples/.../author.ex (__scrypath__(:fan_outs))` | `examples/.../blog.ex resolve_posts_for_authors/1` | resolver MFA `{ScrypathDemo.Blog, :resolve_posts_for_authors, []}` | VERIFIED | MFA in `author.ex` points to `blog.ex`; function defined with correct name and 3 clauses |
| `examples/.../blog.ex update_author/3` | `Scrypath.sync_related/3` | explicit context-invoked fan-out (fan_out: :posts) | VERIFIED | `Scrypath.sync_related(Author, updated, Keyword.put(sync_opts, :fan_out, :posts))` at line 46 |
| `examples/.../smoke tests` | `ScrypathDemo.Blog.update_author/3` | smoke tests drive author rename | VERIFIED | Both smoke files call `Blog.update_author(author, %{name: ...}, sync_opts)` with matching 3-tuple pattern match |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `examples/.../blog.ex update_author/3` | `updated` author struct | `Repo.update()` (Ecto write) | Yes — real DB write | FLOWING |
| `examples/.../blog.ex` denormalized sync | `author_name` on posts | `Repo.update_all(set: [author_name: updated.name])` | Yes — real DB write ordered before fan-out | FLOWING |
| `examples/.../blog.ex resolve_posts_for_authors/1` | `[%Post{} | _]` | `Repo.all(from p in Post, where: p.author_id in ^author_ids)` | Yes — real DB query | FLOWING |
| `test/scrypath/docs_contract_test.exs` related-data test | `guide` string | `@guides["guides/related-data-and-reindexing.md"]` materialized via `File.read!` at compile time | Yes — file read at compile time | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| `mix verify.phase91` exits 0 | `mix verify.phase91` | 73 tests, 0 failures; docs build clean | PASS |
| `mix test test/scrypath/docs_contract_test.exs` exits 0 | `mix test test/scrypath/docs_contract_test.exs` | 63 tests, 0 failures | PASS |
| Banned strings absent from guide | `grep -c -i 'temporary workaround'` | 0 | PASS |
| Banned strings absent from guide | `grep -c -i 'first-class feature'` | 0 | PASS |
| 9 canonical strings present in guide | `grep -c` for each | All 9 found | PASS |
| Gap CR-01 closed — hand-written accessor in guide | `grep -n 'def __scrypath__(:fan_outs)'` | line 113 match | PASS |
| Gap CR-01 closed — prose note in guide | `grep -n 'does not generate a'` | line 133 match | PASS |
| Gap WR-02 closed — 3-tuple return in guide | `grep -n '{:ok, result, updated}'` | line 205 match | PASS |
| Gap WR-02 closed — no bare 2-tuple | `grep -c '{:ok, updated}$'` | 0 | PASS |
| Docs-contract asserts accessor and prose note | `grep -n 'def __scrypath__(:fan_outs)' docs_contract_test.exs` | line 1154 | PASS |
| No examples/ paths in verify.phase91 | `grep -c 'examples/' lib/mix/tasks/verify.phase91.ex` | 0 | PASS |
| No UpsertWorker in oban smoke | `grep -c 'Scrypath.Oban.UpsertWorker' meilisearch_related_oban_stack_test.exs` | 0 | PASS |
| Example app compiles | `cd examples/phoenix_meilisearch && mix compile --warnings-as-errors` | exit 0 (no output) | PASS |
| Old test gone from docs_contract_test | `grep -c 'related-data guide explicitly mentions temporary Oban workaround'` | 0 | PASS |
| Exactly one related-data guide test | `grep -c '"related-data guide'` in docs_contract_test | 1 | PASS |

### Probe Execution

No probe scripts declared for this phase.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| EXEC-02 | 91-01, 91-03, 91-04 | Developer docs clearly define when to use inline fan-out versus durable (Oban) queueing based on blast radius and request latency | SATISFIED | Guide maps inline/oban to blast radius + latency; D-04 retry/cancel outcomes stated; honesty boundary present; working schema pattern teaches correct API; `mix verify.phase91` passes. v1.24-REQUIREMENTS.md traceability row shows "Complete". |
| TEST-01 | 91-02 | Maintainers can test related-data propagation in hermetic unit tests without a live Meilisearch backend | SATISFIED | `mix verify.phase91` runs `related_test.exs`, `related_worker_test.exs`, `docs_contract_test.exs` (all hermetic); 73 tests, 0 failures; no `examples/` smoke paths. Note: v1.24-REQUIREMENTS.md traceability row still shows "Pending" (documentation not updated) but functional implementation is confirmed. |
| TEST-02 | 91-02 | The verify.phaseNN pattern ensures docs contracts correctly articulate context-owned orchestration vs library-owned execution boundary | SATISFIED | Inverted docs-contract test asserts `contexts own orchestration` and `library owns execution` literally; "stays wired" test locks task discoverability; `mix verify.phase91` passes. Note: v1.24-REQUIREMENTS.md traceability row still shows "Pending" (documentation not updated) but functional implementation is confirmed. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `examples/.../blog.ex` | 38 | `{:ok, updated} = author |> ... |> Repo.update()` — bare match raises MatchError on error path; @doc claims "Propagates errors" | WARNING | Documentation contract violation — an adopter expecting `{:error, changeset}` propagation gets a MatchError instead. Pre-existing issue, not introduced by 91-04. Not blocking: smoke tests work, hermetic tests pass. |
| `examples/.../blog.ex` | 41-42 | `Repo.update_all(...)` return value silently discarded | INFO | Inconsistent with guide's own example which shows `{_count, _} =` binding. Not user-visible. Pre-existing from 91-03. |
| `test/scrypath/docs_contract_test.exs` | ~1176-1186 | `ordered?/3` crashes with `ArgumentError` when needle absent (`elem(:nomatch, 0)` raises) | WARNING | Latent — does not affect any currently-passing tests but would mask real doc regressions with an opaque crash instead of a useful failure message. Pre-existing issue, not introduced by this phase. |
| `v1.24-REQUIREMENTS.md` | traceability table | TEST-01 and TEST-02 show "Pending" despite functional implementation being complete | INFO | Documentation inconsistency. Not blocking — functional proof exists in codebase and passes CI. |

No `TBD`, `FIXME`, or `XXX` debt markers found in files modified by this phase.

### Human Verification Required

### 1. Live Example Smoke Tests

**Test:** Inside `examples/phoenix_meilisearch`, set `SCRYPATH_MEILISEARCH_URL` to a running Meilisearch URL and run `SCRYPATH_EXAMPLE_INTEGRATION=1 mix test test/smoke/` against live Postgres + Meilisearch.
**Expected:** Both `meilisearch_related_inline_stack_test.exs` and `meilisearch_related_oban_stack_test.exs` pass. The inline test asserts `{:ok, %{mode: :inline, status: :completed}, _updated_author}` and finds the Post with `author_name: "Renamed Author"` in search results. The oban test asserts `{:ok, %{mode: :oban, status: :accepted}, _updated_author}` and `await_search` finds the Post with `author_name: "Oban Renamed Author"`. Both tests exercise different resolver arities (inline: Author structs, oban: Author IDs) proving the arity-safe `resolve_posts_for_authors/1` in `blog.ex` handles both shapes correctly end-to-end.
**Why human:** Requires a live Meilisearch instance and Postgres database. Cannot be verified programmatically without real services. The example app compiles and the test structure is correct, but live service confirmation is needed for the EXEC-02 "demonstrable end-to-end" claim.

---

## Gaps Summary

**No blocking gaps.** Both previous blockers (CR-01 and WR-02) are closed by Plan 91-04:

- **CR-01 (CLOSED):** Guide section (a) now teaches the working `def __scrypath__(:fan_outs)` hand-written accessor pattern (line 113), `def __scrypath__(:document_id)` (line 123), and a prose note explaining the macro limitation (line 133). The docs-contract test asserts both the accessor definition and the prose note string, so the broken pattern cannot silently return.

- **WR-02 (CLOSED):** Guide `update_author/3` return is now `{:ok, result, updated}` (3-tuple, line 205), matching `blog.ex` and both smoke test assertions. No bare `{:ok, updated}` 2-tuple remains.

**Remaining informational items (not blocking):**
- `update_author/3` @doc claims error propagation but uses bare match (WARNING, pre-existing from 91-03, not introduced by 91-04)
- `ordered?/3` crash-on-absent in docs_contract_test.exs (WARNING, pre-existing)
- TEST-01 and TEST-02 traceability rows still show "Pending" in v1.24-REQUIREMENTS.md (INFO, functional implementation confirmed)

**One human verification item remains:** Live smoke test confirmation of both fan-out paths against real Postgres + Meilisearch.

---

_Verified: 2026-05-25T08:00:00Z_
_Verifier: Claude (gsd-verifier)_
