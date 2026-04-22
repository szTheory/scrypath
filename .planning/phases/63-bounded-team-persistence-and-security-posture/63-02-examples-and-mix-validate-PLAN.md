---
phase: 63
plan: "02"
type: execute
wave: 1
depends_on: []
files_modified:
  - scrypath_ops/lib/mix/tasks/scrypath_ops/playbooks/validate.ex
  - scrypath_ops/examples/playbooks/search_minimal.json
  - scrypath_ops/examples/playbooks/search_many_minimal.json
  - scrypath_ops/test/scrypath_ops/mix/playbooks_validate_test.exs
autonomous: true
requirements:
  - OPS2-04
---

<threat_model>
| Threat | Mitigation |
|--------|------------|
| T-63-02: Validator loads unexpected paths | Task accepts **one** positional directory argument; resolve with `Path.expand/1`; only read files matching **`*.json`** basename pattern consistent with **`Store.safe_basename?/1`** (no subdirectories / traversal). |
| T-63-02: Silent partial validation | Non-zero exit on **first** invalid file; print **`relative_path: reason`** to stderr. |
| T-63-02: Task breaks default test alias | Do **not** inject this task into **`mix test` alias** in `scrypath_ops/mix.exs` unless explicitly required — keep opt-in CLI for CI hooks. |
</threat_model>

<objective>
Add **in-repo example playbooks** (`playbook_format: 1`, stub-safe shapes) and a **`mix scrypath_ops.playbooks.validate DIR`** task that decodes + runs **`ScrypathOps.Playbook.V1.validate/1`** on each eligible JSON file with **no Meilisearch** dependency.
</objective>

<tasks>
<task id="63-02-01" type="execute">
<read_first>
- scrypath_ops/lib/mix/tasks/scrypath_ops/check_nav_contract.ex
- scrypath_ops/lib/scrypath_ops/playbook/v1.ex
- scrypath_ops/lib/scrypath_ops/playbook/store.ex
- scrypath_ops/mix.exs
- .planning/phases/63-bounded-team-persistence-and-security-posture/63-CONTEXT.md
</read_first>
<action>
1. Create **`scrypath_ops/lib/mix/tasks/scrypath_ops/playbooks/validate.ex`** defining **`Mix.Tasks.ScrypathOps.Playbooks.Validate`** with invocation name **`mix scrypath_ops.playbooks.validate`**: `run([dir])` requires exactly one directory; expand path; list `*.json` files **non-recursively** in that directory; for each file read bytes → `ScrypathOps.Playbook.V1.decode/1` → `validate/1`; on error `Mix.shell().error/1` (or stderr) with `filename: inspect(reason)` and `exit({:shutdown, 1})` or `Mix.raise/2` per existing task style in this repo; on all success print count and exit 0.
2. Add **`scrypath_ops/examples/playbooks/search_minimal.json`** and **`search_many_minimal.json`** as valid v1 examples (no banned keys, no `federation_weight` unless you add a paired test that expects stub error — prefer **no** federation_weight).
3. Add **`scrypath_ops/test/scrypath_ops/mix/playbooks_validate_test.exs`** using **`Mix.Task.run/2` in test** or **`System.cmd("mix", ...)`** from a temp dir — whichever pattern exists in repo; assert exit **0** on examples dir and **non-zero** on a temp dir containing one intentionally invalid JSON file created in test setup.
</action>
<acceptance_criteria>
- `grep -q 'defmodule Mix.Tasks.ScrypathOps.Playbooks.Validate' scrypath_ops/lib/mix/tasks/scrypath_ops/playbooks/validate.ex` exits **0**.
- `test -f scrypath_ops/examples/playbooks/search_minimal.json` and `test -f scrypath_ops/examples/playbooks/search_many_minimal.json` both exit **0**.
- From **`scrypath_ops/`** cwd: `mix scrypath_ops.playbooks.validate examples/playbooks` exits **0** (run after implementation).
- `mix test scrypath_ops/test/scrypath_ops/mix/playbooks_validate_test.exs` exits **0**.
</acceptance_criteria>
</task>
</tasks>

<verification>
Run `mix test scrypath_ops/test/scrypath_ops/mix/playbooks_validate_test.exs` then `cd scrypath_ops && mix scrypath_ops.playbooks.validate examples/playbooks`.
</verification>

<success_criteria>
Examples are valid per **`V1`**, and operators/CI can validate a directory tree without starting Meilisearch.
</success_criteria>

<must_haves>
- **OPS2-04:** Documented team persistence story includes concrete artifacts (examples + validation entrypoint).
</must_haves>

## PLANNING COMPLETE
