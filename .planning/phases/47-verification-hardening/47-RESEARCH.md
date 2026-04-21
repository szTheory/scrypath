# Phase 47 — Technical research: Verification & hardening (OPSUI-10)

**Question answered:** What do we need to know to plan CI wiring, **`mix verify.opsui`**, and anti-drift tests for **`scrypath_ops/`** without Meilisearch in the default job?

---

## 1. CI shape (mirror `phoenix-example-integration`, minus Meilisearch)

**Source:** `.github/workflows/ci.yml` jobs **`test`**, **`phoenix-example-integration`**, **`quality`**.

| Element | Example job | OPSUI job (Phase 47 intent) |
|---------|-------------|----------------------------|
| Runner | `ubuntu-latest` | Same |
| Beam | Single row **`1.19.0` / `28.1`** matches heavy jobs | Match **`phoenix-example-integration`** for speed (per **47-CONTEXT** discretion) |
| Postgres service | `phoenix-example-integration`: `postgres:16-alpine`, port **5433** host → 5432 container | Reuse; **`pg_isready`** wait loop |
| Meilisearch | Example includes it | **Omit** from OPSUI default job (**47-CONTEXT** D-02, D-19) |
| Cache | Example: `examples/phoenix_meilisearch/{deps,_build}` + dual **`hashFiles`** | OPSUI: `scrypath_ops/deps`, `scrypath_ops/_build`, key includes **`hashFiles('mix.lock', 'scrypath_ops/mix.lock')`** |
| Commands | `cd examples/... && mix deps.get && mix test` | `cd scrypath_ops && mix deps.get && mix test` |

**Path gating (PR):** `paths` / `paths-ignore` should fire on **`scrypath_ops/**`**, **`lib/**`**, root **`mix.exs`**, **`mix.lock`**, **`scrypath_ops/mix.lock`** — exact YAML left to planner (**D-03**). **`push` to `main`**: run job unconditionally (**D-03**).

---

## 2. `scrypath_ops` test entry and database

**Source:** `scrypath_ops/mix.exs` **`test`** alias:

```elixir
test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
```

CI must provide Postgres and env vars consistent with **`config/test.exs`** (repo default: typically **`localhost`** — align with service networking; example uses **`PGPORT`** for host port mapping).

---

## 3. Doc / IA anti-drift pattern

**Source:** `test/scrypath/docs_contract_test.exs`

- Compile-time **`File.read!/1`** of markdown + workflow sources.
- Assertions: ordered headings (`ordered?/2`), forbidden substrings for published hygiene, stable anchor strings.
- **Mirror narrowly** under **`scrypath_ops/test/`** for **`scrypath_ops/docs/operator-ia.md`** + **`router.ex`** excerpts (**47-CONTEXT** D-07, D-17) — avoid copying library **`DocsContractTest`** hygiene regexes literally unless ops docs need the same rules.

---

## 4. LiveView verification patterns

**Source:** `scrypath_ops/test/scrypath_ops_web/live/*_test.exs`

- **`ConnCase`**, **`async: false`** when mutating **`Application` env**.
- **`setup`** saves previous env; **`on_exit`** restores with **`delete_env` / `put_env`**.
- Stubs: **`SearchPlaygroundStubAdapter`**, fake Meilisearch clients (**`PostureFakeClient`**), not real network.
- Assertions: **`data-testid`** + **`element/2`** where possible; **`html =~`** for policy-bearing copy only (**D-08**).

**Gaps to close in planning (from **47-CONTEXT**):** explicit tests for **fail-closed prod auth** (**D-10**), **allowlist-only** widening (**D-11**), posture **per-row** honesty (**D-12**), failed-sync **counts vs entries** (**D-13**), sync vs drift separation (**D-14**), search **bounds / no auto-run on mount** / partial vs hard error (**D-15–D-16**) — some may already be partially covered; executor must grep each live module and extend tests surgically.

---

## 5. Root **`mix verify.*`** culture

**Source:** `mix.exs` **`cli/0`** **`preferred_envs`** for **`verify.phase*`** tasks.

- Add **`verify.opsui`** with **`preferred_envs: [verify.opsui: :test]`** (exact atom string **`"verify.opsui"`** in keyword list as siblings do).
- Implementation: delegate with explicit **`cwd: "scrypath_ops"`** via **`Mix.Task.run`** / **`Mix.Shell.cmd`** — single maintainer entry (**D-04**).

---

## 6. Formatting across sibling app

**Source:** root **`.formatter.exs`** currently:

```elixir
inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"]
```

**Gap:** **`scrypath_ops/**`** is **not** in **`inputs`** — **`mix format --check-formatted`** at repo root **does not** format ops sources today. Phase should either extend **`inputs`** or document **`cd scrypath_ops && mix format --check-formatted`** in CI (**D-05**).

---

## 7. Pitfalls

| Pitfall | Mitigation |
|---------|------------|
| OPSUI job on PR skipped when only **`lib/`** changes break path dep | Include **`lib/**`** in **`paths`** (**D-03**) |
| Green PR, red **`main`** after merge | **`push` branches: [main]** always runs OPSUI job |
| Flaky Meilisearch in ops CI | Do not add Meilisearch service; keep stubs (**D-19**) |
| Brittle full-page snapshots | Forbidden (**D-06**) — doc spine + targeted LiveView asserts only |

---

## Validation Architecture

> Nyquist / Dimension 8: every plan wave must map to automated feedback in **`scrypath_ops`** or root **`mix verify.opsui`**.

**Sampling layers:**

1. **Per-task (executor):** After changing **`scrypath_ops`**, run the narrowest **`mix test path/to/file.exs`** that covers the edit; after **`ci.yml`**, validate YAML with **`actionlint`** if available in repo, else manual PR preview.
2. **Per-wave:** `cd scrypath_ops && mix test` (full ops suite) **or** `mix verify.opsui` once the alias exists — must exit **0**.
3. **Pre-merge (maintainer):** Full root **`mix test --exclude integration`** unchanged; OPSUI job green on PR.

**Dimension mapping (summary):**

| Dimension | Artifact |
|-----------|----------|
| Correctness | LiveView + contract tests assert stable strings and routes |
| Security | Tests for fail-closed **`/ops`** auth, no naked LiveView mount (**D-10**) |
| Operability | CI job + **`mix verify.opsui`** documented in **`scrypath_ops/README.md`** or root **`CONTRIBUTING.md`** pointer |
| Feedback latency | Single OTP row, Postgres only — target under **5 minutes** job wall time |

**Wave 0:** Not required — ExUnit + Ecto already present in **`scrypath_ops`**.

---

## RESEARCH COMPLETE

Planning can proceed with **47-CONTEXT.md**, this file, and canonical paths listed in CONTEXT `<canonical_refs>`.
