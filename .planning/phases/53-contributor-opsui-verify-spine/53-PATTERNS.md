# Phase 53 — Pattern map

Analogs for executor read-first lists.

## Mix verify task + moduledoc

- **Analog:** `lib/mix/tasks/verify.phase11.ex` — `@moduledoc """` multi-line summary, `@shortdoc` one line, `run/1` calls `Mix.Task.run("app.start")` then orchestrates.
- **Target:** `lib/mix/tasks/verify.opsui.ex` — replace `@moduledoc false` with a short doc block; keep `ensure_no_args!/1` and `System.cmd` shape.

## CONTRIBUTING ↔ CI ordering contract

- **Analog:** `test/scrypath/docs_contract_test.exs` — tests `"CONTRIBUTING phoenix-example-integration matches ci.yml mix ordering (Phase 51)"` using `String.split/3` on `@ci_workflow` and `ordered?/3`.
- **Target:** Mirror for **`scrypath-ops`** job key and `cd scrypath_ops` → `mix deps.get` → `mix test` ordering in CONTRIBUTING table row vs `ci.yml` job body.

## README verify wayfinding

- **Analog:** README **Integration smoke** paragraph — cites concrete `mix verify.*` names and links CONTRIBUTING for matrix.
- **Target:** **Operator UI (maintainers)** paragraph — add visible **`mix verify.opsui`** + link to CONTRIBUTING verify section (anchor per implementer).
