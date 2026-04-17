---
phase: 21
slug: multi-index-search
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-17
---

# Phase 21 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution (Elixir / Mix).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Mix) |
| **Config file** | `mix.exs` test aliases, `test/test_helper.exs` |
| **Quick run command** | `mix test test/scrypath/search_many_test.exs` (once file exists; until then `mix test test/scrypath/search_test.exs`) |
| **Full suite command** | `mix test --exclude integration` |
| **Integration slice** | `SCRYPATH_INTEGRATION=1 mix test test/scrypath/search_many_test.exs --only integration` (exact path may vary; must match plan files) |
| **Estimated runtime** | ~30–120 seconds full unit suite; integration +2–5 minutes with Docker Meilisearch |

---

## Sampling Rate

- **After every task commit:** Run the plan’s `<automated>` verify command (minimum `mix compile --warnings-as-errors`).
- **After every plan wave:** Run `mix test --exclude integration`.
- **Before `/gsd-verify-work`:** Full unit green; integration slice green when MULTI-08 / live paths touched.
- **Max feedback latency:** Target under 3 minutes on CI-sized hardware for default `mix test --exclude integration`.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 21-01-* | 01 | 1 | MULTI-01,02,03,04,10 | T-21-01-* | No user-controlled opts at compile time | unit | `mix test test/scrypath/search_many_test.exs` | ⬜ W0 | ⬜ pending |
| 21-02-* | 02 | 2 | MULTI-08,12 | T-21-02-* | Req.Test stubs only; no live secrets | unit + contract | `mix test test/scrypath/meilisearch/` + search_many client tests | ⬜ W0 | ⬜ pending |
| 21-03-* | 03 | 3 | MULTI-05,06,07,09,13 + remainder 01 | T-21-03-* | No raw user strings in Logger metadata defaults | unit | `mix test test/scrypath/search_many_test.exs` | ⬜ W0 | ⬜ pending |
| 21-04-* | 04 | 4 | MULTI-11,08 | T-21-04-* | Guide examples are static HEEx | integration + docs | `mix test --include integration` subset + doc contract test | ⬜ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/scrypath/search_many_test.exs` — created in Wave 1 with first describe blocks (may start as `@tag :skip` until implementation lands).
- [ ] `test/support/fake_backend.ex` — extended with `search_many/3` stub returning deterministic maps.

*Wave 0 completes when the above files exist and `mix compile --warnings-as-errors` passes.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|---------------------|
| Live Meilisearch facet parity | MULTI-08 | Requires Docker + `SCRYPATH_MEILISEARCH_URL` | Run integration job locally or CI workflow `integration` job; compare solo vs multi-search facet maps for two schemas. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or documented manual row
- [ ] Sampling continuity: no three consecutive tasks without automated verify
- [ ] Wave 0 covers new test file + FakeBackend extension
- [ ] No watch-mode flags in CI instructions
- [ ] `nyquist_compliant: true` set in frontmatter after execution evidence

**Approval:** pending
