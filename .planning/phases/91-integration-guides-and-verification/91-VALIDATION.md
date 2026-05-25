---
phase: 91
slug: integration-guides-and-verification
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-25
---

# Phase 91 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from 91-RESEARCH.md "Validation Architecture". This phase ships docs +
> a verify gate + example polish — NO new library code. TEST-01 is satisfied by
> *running* the already-hermetic propagation tests; TEST-02 by inverted
> docs-contract assertions; EXEC-02 by guide prose + a both-paths example.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir built-in) |
| **Config file** | none for the library (standard `test/test_helper.exs`); example gates `:integration` in its own `test/test_helper.exs` |
| **Quick run command** | `mix test test/scrypath/sync/related_test.exs test/scrypath/sync/related_worker_test.exs test/scrypath/docs_contract_test.exs` |
| **Full suite command (this phase's gate)** | `mix verify.phase91` |
| **Example smoke command** | `cd examples/phoenix_meilisearch && SCRYPATH_EXAMPLE_INTEGRATION=1 mix test` (or `mix verify.adopter --live` from root) |
| **Estimated runtime** | hermetic gate ~a few seconds; example smoke requires live PG + Meilisearch |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/scrypath/sync/related_test.exs test/scrypath/sync/related_worker_test.exs test/scrypath/docs_contract_test.exs` (fast, hermetic).
- **After every plan wave:** Run `mix verify.phase91` (full hermetic gate including `mix docs --warnings-as-errors`).
- **Before `/gsd:verify-work`:** `mix verify.phase91` green AND (for 91-03) example integration smoke green via the `phoenix-example-integration` CI job / `mix verify.adopter --live`.
- **Max feedback latency:** hermetic gate < ~10 seconds.

---

## Per-Task Verification Map

> Task IDs are assigned by the planner. Rows below map each phase requirement to
> its observation point; the planner must attach `<acceptance_criteria>` /
> `<automated>` verify commands to the tasks that realize each row.

| Requirement | Plan | Behavior (observation point) | Test Type | Automated Command | File Exists | Status |
|-------------|------|------------------------------|-----------|-------------------|-------------|--------|
| TEST-01 | 91-02 | Hermetic related-data propagation tests run with no live Meilisearch | unit (in-process backend) | `mix test test/scrypath/sync/related_test.exs test/scrypath/sync/related_worker_test.exs` | ✅ exists (10 tests) | ⬜ pending |
| TEST-01 | 91-02 | `mix verify.phase91` *runs* those hermetic tests + `mix docs --warnings-as-errors` | gate | `mix verify.phase91` | ❌ W0 (verify task new) | ⬜ pending |
| TEST-02 | 91-02 | Guide drops "temporary workaround"/"first-class feature"; references `sync_related/3`, `fan_outs:`, both sync modes, boundary + no-callback-magic | docs-contract (substring) | `mix test test/scrypath/docs_contract_test.exs` | ✅ file exists; assertion rewritten | ⬜ pending |
| TEST-02 | 91-02 | New verify task discoverable/wired (`@verify_phase91` attr + `mix.exs` preferred_envs) | docs-contract | `mix test test/scrypath/docs_contract_test.exs` | ❌ W0 (new "stays wired" test) | ⬜ pending |
| EXEC-02 | 91-01 | "Picking the right follow-up path" maps inline/oban to blast-radius + latency; honesty boundary + D-04 outcomes | docs-contract (substring) + prose review | `mix test test/scrypath/docs_contract_test.exs` | ✅ section exists; rewritten | ⬜ pending |
| EXEC-02 | 91-03 | Example demonstrates BOTH inline and oban fan-out end-to-end (D-14) | integration smoke (live PG + Meilisearch) | `cd examples/phoenix_meilisearch && SCRYPATH_EXAMPLE_INTEGRATION=1 mix test` | ❌ W0 (new smoke tests) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `lib/mix/tasks/verify.phase91.ex` — new verify task (D-10), enables the TEST-01 gate (mirror `verify.phase85`).
- [ ] `test/scrypath/docs_contract_test.exs` — invert the line-~1128 assertion (D-11), add `@verify_phase91` attr (~line 30), add a "verify.phase91 stays wired" test (mirror lines ~277–340) (D-12). Enables TEST-02.
- [ ] `mix.exs` — add `"verify.phase91": :test` to `preferred_envs` (~line 58).
- [ ] `examples/phoenix_meilisearch/test/smoke/` — new inline + oban fan-out smoke tests (D-14). Enables EXEC-02 end-to-end demonstrability.
- [ ] `examples/phoenix_meilisearch/lib/scrypath_demo/blog.ex`, `blog/author.ex`, migration, `blog/post.ex` edits — new example code exercised by the smoke tests.
- [ ] No framework install needed — ExUnit is built in; example deps already declared.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Guide prose reads naturally and preserves the existing voice ("your app owns the fan-out / no callback magic") beyond the substring assertions | EXEC-02 | Tone/clarity is not substring-checkable | Read `guides/related-data-and-reindexing.md`; confirm the Author-rename worked example shows both the schema-side `fan_outs:` declaration and the context-side call for `:inline` and `:oban` |
| Example smoke (live PG + Meilisearch) round-trips an Author rename to re-synced Post documents on both paths | EXEC-02 | Requires live Meilisearch + Postgres, gated behind `SCRYPATH_EXAMPLE_INTEGRATION=1` / CI | Run `cd examples/phoenix_meilisearch && SCRYPATH_EXAMPLE_INTEGRATION=1 mix test test/smoke/` |

---

## Validation Sign-Off

- [ ] All tasks have `<acceptance_criteria>` / `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s for the hermetic gate
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
