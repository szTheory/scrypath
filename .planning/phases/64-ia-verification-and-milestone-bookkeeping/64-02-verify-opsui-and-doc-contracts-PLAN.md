---
phase: 64
plan: "02"
type: execute
wave: 1
depends_on: []
files_modified:
  - CONTRIBUTING.md
  - test/scrypath/docs_contract_test.exs
  - guides/operator-mix-tasks.md
autonomous: true
requirements:
  - OPS2-06
---

<threat_model>
| Threat | Mitigation |
|--------|------------|
| T-64-02: Contributors miss validation for team playbooks | Add **`mix scrypath_ops.playbooks.validate`** to **CONTRIBUTING** verify matrix (same job family as **`scrypath-ops`**) only if the command is the honest local check for JSON CI validation — describe **when** to run it (PR touching `scrypath_ops/docs/*.json` or workspace fixtures). |
| T-64-02: Doc contract locks internal planning IDs | New **`docs_contract_test`** assertions use **literal mix invocation strings** only — no **`OPS2-`** or **`.planning/`** substrings in published markdown (**existing hygiene test** must stay green). |
</threat_model>

<objective>
Close **OPS2-06** by ensuring the **default contributor path** documents and mechanically checks any **Phase 62–63** operator commands that adopters must run locally, then prove **`mix verify.opsui`** stays green with **stub-only** tests (no Meilisearch).
</objective>

<tasks>
<task id="64-02-01" type="execute">
<read_first>
- .planning/phases/64-ia-verification-and-milestone-bookkeeping/64-CONTEXT.md
- CONTRIBUTING.md
- lib/mix/tasks/verify.opsui.ex
- scrypath_ops/lib/mix/tasks/scrypath_ops/playbooks/validate.ex
- test/scrypath/docs_contract_test.exs
- guides/operator-mix-tasks.md
</read_first>
<action>
1. Read **`Mix.Tasks.ScrypathOps.Playbooks.Validate`** **@moduledoc** and pick the **exact** invocation string (e.g. **`mix scrypath_ops.playbooks.validate PATH`**).
2. Update **`CONTRIBUTING.md`** in the **`scrypath_ops` / operator** section: add one bullet or table row stating **when** to run **`mix scrypath_ops.playbooks.validate …`** from **`scrypath_ops/`** (mirror the task’s own wording for args). Keep the existing **`mix verify.opsui`** row as the **default** gate — do **not** require Meilisearch.
3. Extend **`guides/operator-mix-tasks.md`** with a short subsection listing **`mix scrypath_ops.playbooks.validate`** with the same invocation shape as the Mix task module (if the guide already lists ops tasks, match heading depth and link style).
4. Add **`test/scrypath/docs_contract_test.exs`** assertions: **`@contributing`** contains the exact **`mix scrypath_ops.playbooks.validate`** substring copied from **CONTRIBUTING** after edit; optionally assert the substring appears in **`guides/operator-mix-tasks.md`** via `File.read!("guides/operator-mix-tasks.md")` in the test module (pattern already used for other guides).
5. Run **`mix test test/scrypath/docs_contract_test.exs`** from repo root.
6. Run **`mix verify.opsui`** from repo root.
</action>
<acceptance_criteria>
- `grep -q 'mix scrypath_ops.playbooks.validate' CONTRIBUTING.md` exits **0**.
- `grep -q 'mix scrypath_ops.playbooks.validate' guides/operator-mix-tasks.md` exits **0**.
- `mix test test/scrypath/docs_contract_test.exs` exits **0** from repository root.
- `mix verify.opsui` exits **0** from repository root.
</acceptance_criteria>
</task>
</tasks>

<verification>
Grep **`README.md`** and **`CONTRIBUTING.md`** for accidental **`OPS2-`** or **`UI-SPEC`** strings — must stay absent for published hygiene.
</verification>

<success_criteria>
**OPS2-06:** Contributor docs and **`docs_contract_test`** agree on the **playbooks validate** command; **`mix verify.opsui`** proves **`scrypath_ops`** tests still pass on the stub/default path.
</success_criteria>

<must_haves>
- **`mix verify.opsui`** green after changes.
- **`CONTRIBUTING.md`** documents **`mix scrypath_ops.playbooks.validate`** with correct invocation.
</must_haves>

## PLANNING COMPLETE
