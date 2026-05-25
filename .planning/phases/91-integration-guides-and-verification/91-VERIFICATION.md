---
phase: 91-integration-guides-and-verification
verified: 2026-05-25T00:00:00Z
status: gaps_found
score: 9/11 must-haves verified
overrides_applied: 0
gaps:
  - truth: "An adopter can read one worked Author-rename example showing the schema-side fan_outs: declaration AND the context-side call for both sync_mode: :inline and sync_mode: :oban."
    status: failed
    reason: "The guide shows `use Scrypath, fan_outs: [...]` at lines 101-125 as the canonical schema-side declaration. The shipped `use Scrypath` macro (lib/scrypath/schema.ex) does NOT generate a `__scrypath__(:fan_outs)` accessor — only hand-written `def __scrypath__(:fan_outs)` works, as used by the example app (author.ex) and hermetic tests. An adopter following the guide will call `Scrypath.sync_related/3`, which immediately calls `schema_module.__scrypath__(:fan_outs)` (sync.ex:44), triggering `ArgumentError: unknown Scrypath metadata key: :fan_outs`. The guide never shows the working hand-written accessor pattern, never mentions the macro limitation, and the docs-contract test only validates parse-level syntax (Code.string_to_quoted) so this broken snippet passes CI undetected. (CR-01 from 91-REVIEW.md confirmed by source inspection.)"
    artifacts:
      - path: "guides/related-data-and-reindexing.md"
        issue: "Lines 101-125 teach `use Scrypath, fan_outs: [...]` which raises ArgumentError at runtime. The working pattern (`def __scrypath__(:fan_outs)` hand-written, as in examples/phoenix_meilisearch/lib/scrypath_demo/blog/author.ex) is absent from the guide."
      - path: "lib/scrypath/schema.ex"
        issue: "The __using__ macro generates __scrypath__ for :config, :fields, :filterable, :faceting, :sortable, :settings, :document_id, :document_source, :backend — but NOT :fan_outs. Any schema using `use Scrypath, fan_outs:` falls through to the catch-all clause that raises ArgumentError."
    missing:
      - "Replace the `use Scrypath, fan_outs: [...]` snippet in guide section (a) with the working `def __scrypath__(:fan_outs)` hand-written accessor pattern (matching examples/phoenix_meilisearch/lib/scrypath_demo/blog/author.ex lines 33-40)."
      - "Add a prose note in the guide that `use Scrypath` does not yet support `fan_outs:` at macro-expansion time and that hand-written reflection accessors are required."
      - "Add a docs-contract assertion that the guide contains `def __scrypath__(:fan_outs)` so this does not regress silently (suggested in 91-REVIEW.md CR-01)."

  - truth: "The 'Picking the right follow-up path' section maps the inline-vs-oban choice to blast radius + request latency and states the RelatedWorker retry/cancel outcomes (D-04) and the honesty boundary."
    status: failed
    reason: "The guide section (c) and the update_author/3 worked example at line 193 return `{:ok, updated}` (a 2-tuple). The actual example implementation in blog.ex returns `{:ok, result, updated}` (a 3-tuple), and both smoke tests assert the 3-tuple shape. The 2-tuple shown in the guide is wrong and an adopter copying the guide's context module will pattern-match incorrectly. (WR-02 from 91-REVIEW.md confirmed by source inspection.)"
    artifacts:
      - path: "guides/related-data-and-reindexing.md"
        issue: "Line 193 shows `{:ok, updated}` as the update_author/3 return value. The canonical example returns `{:ok, result, updated}`."
    missing:
      - "Update the guide's update_author/3 return value from `{:ok, updated}` to `{:ok, result, updated}` to match the canonical example and smoke test assertions."
human_verification:
  - test: "Run SCRYPATH_EXAMPLE_INTEGRATION=1 mix test test/smoke/ inside examples/phoenix_meilisearch against a live Postgres + Meilisearch"
    expected: "Both meilisearch_related_inline_stack_test.exs and meilisearch_related_oban_stack_test.exs pass, confirming the Author rename propagates the new author_name to the Post search document on both the inline and oban fan-out paths."
    why_human: "Requires a live Meilisearch instance and Postgres database. Cannot be verified without real services. The executor session confirmed these tests were not run due to no live services being available."
---

# Phase 91: Integration, Guides, and Verification — Verification Report

**Phase Goal:** Ship canonical fan-out documentation (`sync_related/3` as the primary story), a hermetic `mix verify.phase91` gate for the related-data tests + docs-contract, and a working Phoenix example app exercising both inline and Oban fan-out paths end-to-end.
**Verified:** 2026-05-25T00:00:00Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Guide presents `Scrypath.sync_related/3` + built-in Oban path as canonical (no temporary-workaround / first-class-feature framing) | VERIFIED | `grep -c -i 'temporary workaround'` → 0; `grep -c -i 'first-class feature'` → 0; guide contains the canonical section "Fan-out with `Scrypath.sync_related/3`" |
| 2 | An adopter can read one worked Author-rename example showing the schema-side fan_outs: declaration AND context-side calls for both sync modes | FAILED | Guide lines 101-125 show `use Scrypath, fan_outs: [...]` which raises `ArgumentError: unknown Scrypath metadata key: :fan_outs` at runtime. The shipped macro (lib/scrypath/schema.ex) never generates `__scrypath__(:fan_outs)`. The working hand-written pattern used by the example app and tests is absent from the guide. |
| 3 | The guide's worked resolver handles BOTH owning-schema records (inline) AND owning-schema document IDs (oban) — the resolver-arity duality | VERIFIED | Guide lines 198-202 show both `[%Author{} | _] = authors` and `[_id | _] = author_ids` clauses funneling to `reload_posts/1`. Lines 165-170 explicitly call out the duality as the #1 footgun. |
| 4 | The "Picking the right follow-up path" section maps inline-vs-oban to blast radius + request latency and states RelatedWorker retry/cancel outcomes (D-04) and honesty boundary | VERIFIED | `grep -q 'blast radius'` passes; `grep -q 'durably queued'` and `grep -q 'searchable now'` pass; retry/cancel outcomes table present; `grep -q 'retr'` and `grep -q 'cancel'` pass |
| 5 | The no-callback-magic / context-owns-orchestration / library-owns-execution invariant is stated in literal prose the docs-contract test will assert | VERIFIED | Guide contains `callback magic`, `contexts own orchestration`, and `library owns execution` verbatim. All 7 canonical strings verified present. |
| 6 | `mix verify.phase91` exists, runs three hermetic related-data tests (no live Meilisearch), then builds docs with warnings-as-errors, and exits 0 | VERIFIED | `mix verify.phase91` executed: 73 tests, 0 failures; docs build clean. `lib/mix/tasks/verify.phase91.ex` contains exactly the 3 hermetic focused paths, no `examples/` paths. |
| 7 | The docs-contract test asserts the canonical sync_related/3 story and forbids temporary-workaround / first-class-feature strings | VERIFIED | `docs_contract_test.exs` line 1137: test "related-data guide adopts sync_related/3 as the canonical fan-out story" — `refute`s both banned strings and `assert_contains_all` over all 7 canonical strings. Old test at line ~1128 replaced. |
| 8 | The new verify.phase91 task is discoverable: `@verify_phase91`, "stays wired" test, and `mix.exs` preferred_envs | VERIFIED | `@verify_phase91` at line 30; "verify.phase91 stays wired" test at line 343; `"verify.phase91": :test` in mix.exs preferred_envs. |
| 9 | verify.phase91's focused test list contains ONLY hermetic library tests — no example smoke paths | VERIFIED | `grep -c 'examples/' lib/mix/tasks/verify.phase91.ex` → 0. Focused tests: related_test.exs, related_worker_test.exs, docs_contract_test.exs only. |
| 10 | Author schema declares a fan_outs: entry targeting Post via Blog context resolver; Blog context handles both resolver arities | VERIFIED | `author.ex` uses hand-written `__scrypath__(:fan_outs)` with `target: ScrypathDemo.Blog.Post` and `resolver: {ScrypathDemo.Blog, :resolve_posts_for_authors, []}`. `blog.ex` has 3 resolver clauses: `[%Author{} | _]`, `[_id | _]`, `[]`. Both funnel to `reload_posts(author_ids)`. |
| 11 | The guide's update_author/3 worked example return value matches the canonical implementation | FAILED | Guide line 193 shows `{:ok, updated}` (2-tuple); `blog.ex` returns `{:ok, result, updated}` (3-tuple); smoke tests assert `{:ok, %{mode: :inline, status: :completed}, _updated_author}`. The guide and implementation diverge on a public API shape. |

**Score:** 9/11 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `guides/related-data-and-reindexing.md` | Canonical sync_related/3 fan-out guide | STUB (PARTIAL) | Exists and contains most canonical content, but teaches `use Scrypath, fan_outs:` (broken pattern — see Gap 1) and shows wrong return shape (Gap 2) |
| `lib/mix/tasks/verify.phase91.ex` | Mix.Tasks.Verify.Phase91 hermetic gate | VERIFIED | Exists, defines module, 3 hermetic test paths, reenable calls, --warnings-as-errors docs step |
| `test/scrypath/docs_contract_test.exs` | Inverted assertion + @verify_phase91 + stays-wired test | VERIFIED | All three edits (A/B/C) present; old test replaced; new test passes |
| `mix.exs` | `"verify.phase91": :test` in preferred_envs | VERIFIED | Literal string confirmed present |
| `examples/.../blog/author.ex` | Author schema with fan_outs: entry via __scrypath__ | VERIFIED | Hand-written `__scrypath__(:fan_outs)` present (Option A deviation from plan, but functionally correct) |
| `examples/.../blog.ex` | Blog context: update_author/3 + arity-safe resolve_posts_for_authors/1 | VERIFIED | Both functions present; 3 resolver clauses confirmed |
| `examples/.../migrations/20250420000000_...exs` | authors table + posts.author_id + posts.author_name | VERIFIED | All three DDL operations present |
| `examples/.../meilisearch_related_inline_stack_test.exs` | Inline fan-out smoke | VERIFIED (static) | Exists, @moduletag :integration, drives update_author/3 with sync_mode: :inline, asserts 3-tuple + mode/status + renamed author_name |
| `examples/.../meilisearch_related_oban_stack_test.exs` | Oban fan-out smoke (no UpsertWorker) | VERIFIED (static) | Exists, sync_mode: :oban, asserts 3-tuple + mode/status, `grep -c 'Scrypath.Oban.UpsertWorker'` → 0 |
| `examples/.../README.md` | Mentions sync_related/3 + fan-out smoke coverage | VERIFIED | sync_related/3 in line 3 intro; fan-out smoke coverage documented |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `guides/related-data-and-reindexing.md` | `lib/scrypath.ex sync_related/3` | documented public API signature | VERIFIED | Guide contains `Scrypath.sync_related/3` references with call signatures matching lib/scrypath.ex |
| `guides/related-data-and-reindexing.md` (canonical strings) | `test/scrypath/docs_contract_test.exs` (inverted assertion) | literal substring contract | VERIFIED | All 7 strings asserted in test match strings confirmed present in guide |
| `lib/mix/tasks/verify.phase91.ex` | `related_test.exs + related_worker_test.exs + docs_contract_test.exs` | @focused_tests list | VERIFIED | All 3 paths in @focused_tests; reenable("test") present; runs in-process |
| `test/scrypath/docs_contract_test.exs @verify_phase91` | `lib/mix/tasks/verify.phase91.ex` | File.read! of task source | VERIFIED | `@verify_phase91 File.read!("lib/mix/tasks/verify.phase91.ex")` at line 30 |
| `examples/.../author.ex (__scrypath__(:fan_outs))` | `examples/.../blog.ex resolve_posts_for_authors/1` | resolver MFA `{ScrypathDemo.Blog, :resolve_posts_for_authors, []}` | VERIFIED | MFA in author.ex points to blog.ex; function exists with correct name |
| `examples/.../blog.ex update_author/3` | `Scrypath.sync_related/3` | explicit context-invoked fan-out (fan_out: :posts) | VERIFIED | `Scrypath.sync_related(Author, updated, Keyword.put(sync_opts, :fan_out, :posts))` present in blog.ex |
| `examples/.../smoke tests` | `ScrypathDemo.Blog.update_author/3` | smoke test drives author rename | VERIFIED | Both smoke files call `Blog.update_author(author, %{name: ...}, sync_opts)` |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `examples/.../blog.ex update_author/3` | `updated` author struct | `Repo.update()` | Yes — real Ecto DB write | FLOWING |
| `examples/.../blog.ex` denormalized sync | `author_name` on posts | `Repo.update_all(set: [author_name: updated.name])` | Yes — real Ecto DB write | FLOWING |
| `examples/.../blog.ex resolve_posts_for_authors/1` | `[%Post{} | _]` | `Repo.all(from p in Post, where: p.author_id in ^author_ids)` | Yes — real DB query | FLOWING |
| `test/scrypath/docs_contract_test.exs` related-data test | `guide` string | `@guides["guides/related-data-and-reindexing.md"]` materialized as module attr | Yes — File.read! at compile time | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| `mix verify.phase91` exits 0 | `mix verify.phase91` | 73 tests, 0 failures; docs build clean | PASS |
| Banned strings absent from guide | `grep -c -i 'temporary workaround' guides/related-data-and-reindexing.md` | 0 | PASS |
| Banned strings absent from guide | `grep -c -i 'first-class feature' guides/related-data-and-reindexing.md` | 0 | PASS |
| 7 canonical strings present in guide | `grep -F` for each | All 7 found | PASS |
| No examples/ paths in verify.phase91 | `grep -c 'examples/' lib/mix/tasks/verify.phase91.ex` | 0 | PASS |
| No UpsertWorker in oban smoke | `grep -c 'Scrypath.Oban.UpsertWorker' .../meilisearch_related_oban_stack_test.exs` | 0 | PASS |
| Example app compiles | `cd examples/phoenix_meilisearch && mix compile --warnings-as-errors` | exit 0 | PASS |
| Guide teaches working fan_outs: pattern | `grep -n '__scrypath__' guides/related-data-and-reindexing.md` | 0 matches — hand-written accessor absent | FAIL |
| Guide return shape matches example | guide line 193 vs blog.ex return | `{:ok, updated}` vs `{:ok, result, updated}` | FAIL |

### Probe Execution

No probe scripts declared for this phase.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| EXEC-02 | 91-01, 91-03 | Developer docs clearly define when to use inline vs oban fan-out based on blast radius and request latency | PARTIAL | Guide correctly maps inline/oban to blast radius + latency and states D-04 outcomes + honesty boundary. However, the guide's schema-side declaration example (`use Scrypath, fan_outs:`) is broken at runtime — an adopter following the guide cannot successfully use the API being documented. |
| TEST-01 | 91-02 | Maintainers can test related-data propagation in hermetic unit tests without a live Meilisearch backend | SATISFIED | `mix verify.phase91` runs related_test.exs, related_worker_test.exs, docs_contract_test.exs (all hermetic). 73 tests, 0 failures. No `examples/` smoke paths included. |
| TEST-02 | 91-02 | The verify.phaseNN pattern ensures docs contracts correctly articulate context-owned orchestration vs library-owned execution boundary | SATISFIED | Inverted test at line 1137 asserts `contexts own orchestration` and `library owns execution` literally in the guide; `mix verify.phase91` passes this test. |

Note: The v1.24-REQUIREMENTS.md traceability table still shows TEST-01 and TEST-02 as "Pending" (unchecked). The 91-02-SUMMARY.md declares `requirements-completed: [TEST-01, TEST-02]`. The functional verification confirms TEST-01 and TEST-02 are satisfied in code, though the requirements file was not updated.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `guides/related-data-and-reindexing.md` | 105-112 | `use Scrypath, fan_outs: [...]` — teaches API pattern that raises ArgumentError at runtime | BLOCKER | Adopter following the guide will write a schema that crashes `sync_related/3` at the `schema_module.__scrypath__(:fan_outs)` call (sync.ex:44). The macro never generates that accessor. |
| `guides/related-data-and-reindexing.md` | 193 | `{:ok, updated}` — 2-tuple return shape diverges from canonical implementation's 3-tuple | WARNING | Adopter copying the guide's update_author/3 will have a function that breaks pattern matches structured around the 3-tuple `{:ok, result, updated}` shape. |
| `examples/.../blog.ex` | 38 | `{:ok, updated} = author |> ... |> Repo.update()` — bare match raises MatchError on error, but @doc claims "Propagates errors" | WARNING | Documentation contract violation. An adopter expecting `{:error, reason}` returns will get a MatchError crash instead. |
| `examples/.../blog.ex` | 41-42 | `Repo.update_all(...)` return value silently discarded | INFO | Inconsistent with guide's own example (lines 185-187 show `{_count, _} =` binding). Not user-visible but misleads adopters. |
| `test/scrypath/docs_contract_test.exs` | 1176-1186 | `ordered?/3` crashes with `ArgumentError` when needle absent (`:binary.match` returns `:nomatch` atom; `elem(:nomatch, 0)` raises) | WARNING | Latent: 21 call sites. Currently no tests are affected (all strings are present). If any asserted string is accidentally removed from a guide/README, the test crashes opaquely instead of failing with a useful message. Masks real doc regressions. |

### Human Verification Required

### 1. Live Example Smoke Tests

**Test:** Inside `examples/phoenix_meilisearch`, set `SCRYPATH_MEILISEARCH_URL` and run `SCRYPATH_EXAMPLE_INTEGRATION=1 mix test test/smoke/` against a running Postgres + Meilisearch instance.
**Expected:** Both `meilisearch_related_inline_stack_test.exs` and `meilisearch_related_oban_stack_test.exs` pass. The inline test asserts `{:ok, %{mode: :inline, status: :completed}, _}` and the oban test asserts `{:ok, %{mode: :oban, status: :accepted}, _}`, with the renamed `author_name` appearing in Post search results after each fan-out path.
**Why human:** Requires live Meilisearch and Postgres. Cannot be verified programmatically in this environment.

---

## Gaps Summary

**Two blockers prevent clean goal achievement:**

**Gap 1 (BLOCKER — CR-01): Guide teaches a broken schema declaration pattern.**
The guide's section (a) "Declare the fan-out on the owning schema" shows `use Scrypath, fan_outs: [...]` as the canonical pattern. This pattern does not work: `lib/scrypath/schema.ex` generates `__scrypath__` accessors for fields, settings, document_id, etc. — but NOT for `:fan_outs`. When `Scrypath.sync_related/3` is called (sync.ex:44: `schema_module.__scrypath__(:fan_outs)`), it raises `ArgumentError: unknown Scrypath metadata key: :fan_outs`. The working pattern — hand-written `def __scrypath__(:fan_outs)` + `def __scrypath__(:document_id)` — is used by the companion example app (`author.ex`) and the library's own hermetic tests, but is never shown in the guide. An adopter following the guide verbatim cannot successfully use `sync_related/3`. The docs-contract test does not catch this because it only validates parse-level syntax.

**Gap 2 (WARNING — WR-02): Guide update_author/3 return value diverges from canonical implementation.**
Guide line 193 shows `{:ok, updated}` (2-tuple). The canonical example (`blog.ex:48`) returns `{:ok, result, updated}` (3-tuple), and both smoke tests assert the 3-tuple shape. An adopter copying the guide's worked example will get a function whose callers pattern-match incorrectly.

**Additional latent issues (not blocking current gate, worth tracking):**
- CR-02: `ordered?/3` in docs_contract_test.exs crashes with ArgumentError instead of failing usefully when a needle is absent. Does not currently affect any passing test but will mask real regressions.
- WR-01: `update_author/3` @doc claims error propagation but implementation uses bare pattern matches that raise MatchError.
- WR-03: `Repo.update_all` return value silently discarded in blog.ex, inconsistent with guide's own example.

---

_Verified: 2026-05-25T00:00:00Z_
_Verifier: Claude (gsd-verifier)_
