# Phase 30: Consumer example and smoke depth - Context

**Gathered:** 2026-04-18
**Status:** Implemented (EXAM-01, EXAM-02)

<domain>
## Phase Boundary

Deliver **EXAM-01** (an additional **consumer-shaped** integration scenario beyond the original Phoenix example smoke) and **EXAM-02** (documented **local** integration smoke: commands, env vars, alignment with **CI** Meilisearch jobs). Scope stays **examples + docs + smoke ergonomics**—no new search algorithms or public API expansion.

</domain>

<decisions>
## Implementation Decisions

### EXAM-01 — second consumer scenario

- **D-01:** Extend **`examples/phoenix_meilisearch`** only (no second top-level example app). Add **`{:oban, "~> 2.21"}`**, **`ScrypathDemo.Oban`** (`use Oban, otp_app: :scrypath_demo`), **`Oban.Migrations`** migration, and supervision **`{ScrypathDemo.Oban, Application.fetch_env!(:scrypath_demo, Oban)}`** after **`Repo`**.
- **D-02:** Integration test **`test/smoke/meilisearch_oban_stack_test.exs`**: insert **`Post`**, **`Scrypath.sync_record`** with **`sync_mode: :oban`**, **`oban: ScrypathDemo.Oban`**, **`oban_queue: :scrypath`** (matches **`Scrypath.Oban.UpsertWorker`** default queue), live Meilisearch + unique **`index_prefix`**, poll **`Scrypath.search`** until hit (visibility lag).
- **D-03:** Tests use **`config :scrypath_demo, Oban, testing: :inline`** so jobs run **in-process** deterministically while still exercising **enqueue metadata** and the real **UpsertWorker** + Meilisearch path.
- **D-04:** **`test/release/consumer_smoke_test.exs`** unchanged—remains the **packaging / git-dep / no-services** rail; runtime proof lives in the example.

### EXAM-02 — runbook and CI mapping

- **D-05:** **`examples/phoenix_meilisearch/README.md`** is the **authoritative** env + command table; **`guides/golden-path.md`** gains a short **“Integration smoke”** section that **links** here (no duplicated matrices).
- **D-06:** **`CONTRIBUTING.md`** CI table gains one row: **local example** is **not** a default GitHub job; how to run **`./scripts/smoke.sh`** / `SCRYPATH_EXAMPLE_INTEGRATION`; same Meilisearch **v1.15** family as **`meilisearch-smoke`** / **`phase5-verification`**.
- **D-07:** Root **`README.md`** — one paragraph pointing adopters to the example + **CONTRIBUTING** for job ↔ **`mix verify.*`** mapping.
- **D-08:** **`docs/releasing.md`** — single sentence: live Meilisearch job index stays in **CONTRIBUTING** / **`ci.yml`** (no duplicate matrix in releasing).

### Smoke script ergonomics

- **D-09:** **`scripts/smoke.sh`** default remains **strict teardown** (`docker compose down` on **EXIT**).
- **D-10:** **`--keep-up`** flag skips teardown for local iteration; **`--help`** documents usage.
- **D-11:** Wait loops for Postgres and Meilisearch **fail hard** after 60s if never healthy.

### Claude's Discretion

- None required—user confirmed “follow recommendations” wholesale.

</decisions>

<canonical_refs>
## Canonical References

### Requirements and roadmap

- `.planning/REQUIREMENTS.md` — EXAM-01, EXAM-02, phase 30 success criteria
- `.planning/ROADMAP.md` — phase 30 row and v1.6 scope

### Runbook and guides

- `examples/phoenix_meilisearch/README.md` — env table, smoke, Oban note, `--keep-up`
- `examples/phoenix_meilisearch/scripts/smoke.sh` — CI-shaped smoke orchestration
- `guides/golden-path.md` — integration smoke pointer (thin)
- `CONTRIBUTING.md` — GitHub job ↔ `mix verify.*` index including local example row

### CI / releasing

- `.github/workflows/ci.yml` — mechanical SSOT for services and env
- `docs/releasing.md` — maintainer gates; cross-link to CONTRIBUTING for job names

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`test/smoke/meilisearch_stack_test.exs`** — pattern for **`@moduletag :integration`**, unique **`index_prefix`**, inline sync + search + index cleanup.
- **`Scrypath.Oban.UpsertWorker`** / **`Scrypath.Oban.Enqueue`** — queue **`:scrypath`**, worker module string contract.

### Established Patterns

- Example depends on Scrypath via **`path: "../.."`**; integration gated by **`SCRYPATH_EXAMPLE_INTEGRATION`** in **`test/test_helper.exs`**.

### Integration Points

- **`ScrypathDemo.Application`** supervision order: **Telemetry → Repo → Oban → …**

</code_context>

<specifics>
## Specific Ideas

- Oban **`testing: :inline`** chosen over **`Oban.drain_queue`** for simpler Sandbox + same-process semantics in the example test suite.

</specifics>

<deferred>
## Deferred Ideas

- Optional **GitHub Actions** job that runs **`examples/phoenix_meilisearch/scripts/smoke.sh`** on every PR (cost/latency tradeoff—not required for EXAM-02 as scoped).

### Reviewed Todos (not folded)

- None.

</deferred>

---

*Phase: 030-consumer-example-and-smoke-depth*
*Context gathered: 2026-04-18*
