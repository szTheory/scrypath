---
phase: 145
slug: legacy-phoenix-and-ecto-decimal-remediation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-22
---

# Phase 145 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit with Phoenix `ConnCase` and Ecto SQL Sandbox `DataCase` |
| **Config file** | `examples/phoenix_meilisearch/config/test.exs` |
| **Quick run command** | `cd examples/phoenix_meilisearch && mix test test/scrypath_demo/ecto_compatibility_test.exs test/scrypath_demo_web/endpoint_compatibility_test.exs` |
| **Full suite command** | `cd examples/phoenix_meilisearch && mix deps.get --check-locked && mix test && mix ecto.migrate --quiet && mix precommit`, followed from the repository root by `mix test --exclude integration --exclude docs_contract` |
| **Estimated runtime** | Focused feedback under 60 seconds after dependencies and Postgres are ready; deterministic full gates several minutes |

---

## Sampling Rate

- **After every task commit:** Run the narrowest applicable focused test or manifest/lock assertion from the map below.
- **After every plan wave:** Run `cd examples/phoenix_meilisearch && mix deps.get --check-locked && mix test && mix ecto.migrate --quiet && mix precommit`, then the root fast regression suite when the wave changes the candidate graph.
- **Before `$gsd-verify-work`:** The D-17 deterministic sequence must be green before the detached exact-candidate fresh-resolution and unsuppressed advisory audit; live Postgres/Meilisearch smoke remains separately classified supplemental evidence.
- **Max feedback latency:** 60 seconds for task-level source assertions or focused ExUnit checks once dependencies and Postgres are available.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 145-01-01 | 01 | 1 | SEC-02 | T-145-01 | Only Phoenix `~> 1.8.9`, Bandit `~> 1.12.1`, Ecto SQL `~> 3.14.0`, and Postgrex `~> 0.22.4` become direct bounded cohort changes; Ecto and Decimal remain transitive and every changed lock row is causal | manifest/lock contract | `cd examples/phoenix_meilisearch && mix deps.get --check-locked` plus exact manifest-bound, resolved-version, no-direct-`:ecto`/`:decimal`, no-override, and causal-lock-diff assertions | ✅ manifest/lock; assertions planned | ⬜ pending |
| 145-01-02 | 01 | 1 | SEC-02 | T-145-02 | Existing Post, Author, Repo, migrations, changesets, associations, timestamps, and persisted values work under Ecto 3.14/Decimal 3 without adding a Decimal domain field or crossing into search synchronization | Postgres-backed integration | `cd examples/phoenix_meilisearch && mix test test/scrypath_demo/ecto_compatibility_test.exs` | ❌ Wave 0 | ⬜ pending |
| 145-01-03 | 01 | 1 | SEC-02 | T-145-03 | The real endpoint/router handles representative JSON and malformed-cookie/error requests without a crash, and a supervised loopback Bandit listener serves one HTTP/1 response and emits `[:bandit, :request, :stop]` | endpoint and real-listener integration | `cd examples/phoenix_meilisearch && mix test test/scrypath_demo_web/endpoint_compatibility_test.exs` | ❌ Wave 0 | ⬜ pending |
| 145-02-01 | 02 | 2 | SEC-02 | T-145-04 | Clean-database migration, already-migrated no-op, legacy precommit, and required root fast regression proof pass in binding order | deterministic regression bundle | `cd examples/phoenix_meilisearch && mix test && mix ecto.migrate --quiet && mix precommit`, followed by `mix test --exclude integration --exclude docs_contract` at the repository root | ✅ existing command surfaces; new focused tests planned | ⬜ pending |
| 145-02-02 | 02 | 2 | SEC-02 | T-145-01, T-145-05 | A detached exact-candidate lockless resolution selects every D-05 range and an unsuppressed `mix hex.audit` exits zero; network/feed failure is unavailable evidence, never a pass | isolated live-registry proof | Disposable-worktree `mix deps.get`, version/range inspection, causal-lock comparison, and `mix hex.audit` | ❌ execution evidence | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `examples/phoenix_meilisearch/test/scrypath_demo/ecto_compatibility_test.exs` — private `DataCase` coverage for changesets, required errors, inserts, queries, Author/Post association, timestamps, and persisted values under SEC-02.
- [ ] `examples/phoenix_meilisearch/test/scrypath_demo_web/endpoint_compatibility_test.exs` — `ConnCase` error/cookie coverage plus one `async: false` supervised loopback HTTP/1/Bandit telemetry contract for SEC-02.
- [ ] Compact plan summary evidence — candidate SHA, timestamp, environment, commands/statuses, selected versions, causal lock rows, audit result, and hard-versus-supplemental classification without raw logs or disposable artifacts.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Exact-candidate fresh legacy resolution and current Hex advisory result | SEC-02 | Depends on mutable registry/advisory state and must run without mutating the tracked candidate lock | At the exact candidate SHA in a detached disposable worktree, isolate dependency/build paths, remove only the example lock, run `mix deps.get`, inspect every D-05 target range and the local path dependency, run unsuppressed `mix hex.audit`, and record command statuses plus environment and timestamp. Treat network/feed outage as unavailable proof. |
| Existing Postgres + Meilisearch inline/Oban/fan-out live lane | SEC-02 | Supplemental service-dependent evidence; services may be unavailable locally | Start the documented Compose/CI-shaped services and run the existing example live command from `CONTRIBUTING.md`/the example README. Report it separately; absence or failure cannot be replaced by deterministic causal checks. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verification or explicit Wave 0 dependencies.
- [ ] Sampling continuity: no three consecutive tasks without automated verification.
- [ ] Wave 0 covers all missing focused-test and evidence references.
- [ ] No watch-mode flags.
- [ ] Task-level feedback latency is under 60 seconds after prerequisites are ready.
- [ ] `nyquist_compliant: true` set in frontmatter after validation.

**Approval:** pending
