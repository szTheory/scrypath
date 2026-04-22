# Phase 53 — Technical research

**Question:** What do we need to know to plan the contributor OPSUI verify spine well?

## Mix.Task visibility

- `Mix.Tasks.Verify.Opsui` uses `@moduledoc false`, which hides the task from the default `mix help` listing and yields empty `mix help verify.opsui` output.
- Sibling tasks (e.g. `Mix.Tasks.Verify.Phase11`) use a normal `@moduledoc """ ... """` block while keeping long-form policy in CONTRIBUTING — good template for length and tone.

## CI ↔ docs contract pattern (Phase 51)

- `test/scrypath/docs_contract_test.exs` already anchors **`phoenix-example-integration`** with `String.split(@ci_workflow, "phoenix-example-integration:", parts: 2)` and `ordered?/3` on the job head for `cd examples/phoenix_meilisearch` → `mix deps.get` → `mix test`.
- The **`scrypath-ops`** job in `.github/workflows/ci.yml` runs (under `ScrypathOps` step): `cd scrypath_ops`, `mix deps.get`, `mix test` — same ordering contract can be asserted from a split on **`scrypath-ops:`** (job id line) without embedding the full shell script from `Mix.Tasks.Verify.Opsui`.

## README gap

- `CONTRIBUTING.md` already documents **`mix verify.opsui`** and maps it to **`scrypath-ops`** CI.
- Root **`README.md`** operator paragraph links to **`scrypath_ops/README.md`** but does **not** contain the literal substring **`mix verify.opsui`** — **VRFY-04** needs visible monospace command in default contributor docs.

## Implementation markers (optional D-10)

- `verify.opsui.ex` already uses `cd: ops_dir`, `System.cmd("bash", ["-lc", script], ...)`, `ensure_no_args!/1`, and raises listing `mix test` in the user-visible script string — stable substrings for thin contract tests without snapshotting log prose.

## Risk / non-goals

- No change to **`scrypath_ops`** test matrix or CI job semantics beyond doc alignment.
- Do not duplicate CONTRIBUTING verify tables into README or `@moduledoc`.

---

## Validation Architecture

**Nyquist / execution sampling**

| Dimension | Strategy |
|-----------|----------|
| Automated | `mix test test/scrypath/docs_contract_test.exs` after doc-contract edits; `mix format --check-formatted` if Elixir touched; spot-check `mix help verify.opsui` shows non-empty moduledoc after task change. |
| Contract focus | Assert **ordering** and **presence** of stable tokens (job keys, commands), not marketing copy — matches Phase 51 `ordered?` pattern. |
| Manual spot | Optional: run `mix help` and confirm `verify.opsui` appears in task list (human sanity check; not CI-gated if flaky in headless). |

**Sign-off:** Plans should map each task to `mix test` scope above; full library suite not required for every micro-commit if project convention allows targeted tests (document in plan verification).

## RESEARCH COMPLETE
