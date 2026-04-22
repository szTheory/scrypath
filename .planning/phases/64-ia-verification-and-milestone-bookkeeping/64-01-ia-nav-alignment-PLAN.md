---
phase: 64
plan: "01"
type: execute
wave: 1
depends_on: []
files_modified:
  - scrypath_ops/docs/operator-ia.md
autonomous: true
requirements:
  - OPS2-05
---

<threat_model>
| Threat | Mitigation |
|--------|------------|
| T-64-01: Operators follow wrong persistence authority | Navigation **follow-up** column links **`team-playbook-persistence.md`** (Phase 63 canonical) next to schema link — single **v1.15** filesystem/GitOps story, no implied Ecto catalog. |
| T-64-01: IA / nav / router drift | After markdown edits run **`mix scrypath_ops.check_nav_contract`**; no router or **`Nav`** code changes expected unless audit finds mismatch (then update code + `--write` fence). |
</threat_model>

<objective>
Close **OPS2-05** by aligning **`operator-ia.md`** with shipped **Phase 63** operator truth: navigation follow-ups for **Saved playbooks** must point operators at **`team-playbook-persistence.md`** without duplicating procedures, then re-run the nav contract toolchain so **`operator_ia_contract_test`** and JSON fence stay green.
</objective>

<tasks>
<task id="64-01-01" type="execute">
<read_first>
- .planning/phases/64-ia-verification-and-milestone-bookkeeping/64-CONTEXT.md
- scrypath_ops/docs/operator-ia.md
- scrypath_ops/docs/team-playbook-persistence.md
- scrypath_ops/lib/scrypath_ops_web/nav.ex
- scrypath_ops/lib/scrypath_ops_web/router.ex
- scrypath_ops/test/scrypath_ops_web/operator_ia_contract_test.exs
</read_first>
<action>
1. In **`scrypath_ops/docs/operator-ia.md`** under **## Navigation**, update the **Saved playbooks** row(s) (Job **8** / **4b**) so the **Scrypath / doc / Mix follow-up** cell includes a markdown link **`[team-playbook-persistence.md](team-playbook-persistence.md)`** (relative path as with other ops-doc links). Keep **`playbook-schema-v1.md`** reference for format; persistence/GitOps detail lives in **`team-playbook-persistence.md`** per **64-CONTEXT** D-03.
2. If **`Jobs-to-be-done`** item **8** prose still implies only schema doc, add **at most one phrase** pointing to **`team-playbook-persistence.md`** for deploy layout — no pasted procedures.
3. From **`scrypath_ops/`**, run **`mix scrypath_ops.check_nav_contract`**. If the tool reports drift between **`Nav.primary/0`** and the fence, run **`mix scrypath_ops.check_nav_contract --write`** only if **`router.ex` / `nav.ex` were edited**; for markdown-only edits the command should exit **0** without `--write`.
4. Run **`mix test test/scrypath_ops_web/operator_ia_contract_test.exs`** from **`scrypath_ops/`**.
</action>
<acceptance_criteria>
- `grep -q 'team-playbook-persistence.md' scrypath_ops/docs/operator-ia.md` exits **0**.
- `cd scrypath_ops && mix scrypath_ops.check_nav_contract` exits **0**.
- `cd scrypath_ops && mix test test/scrypath_ops_web/operator_ia_contract_test.exs` exits **0**.
</acceptance_criteria>
</task>
</tasks>

<verification>
Confirm no duplicate runbook prose was pasted into **JTBD** — only short pointers. Re-read **## Navigation** table for valid markdown links.
</verification>

<success_criteria>
**OPS2-05:** **`operator-ia.md`**, primary nav story, and machine-checked contracts remain aligned; contributors see where team playbooks live without IA contradicting Phase 63 docs.
</success_criteria>

<must_haves>
- **`operator-ia.md`** mentions **`team-playbook-persistence.md`** in the navigation follow-up path for saved playbooks.
- **`check_nav_contract`** + **`operator_ia_contract_test`** green.
</must_haves>

## PLANNING COMPLETE
