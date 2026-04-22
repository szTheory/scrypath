---
phase: 63
plan: "03"
type: execute
wave: 3
depends_on:
  - "01"
files_modified:
  - scrypath_ops/docs/playbook-schema-v1.md
  - scrypath_ops/test/scrypath_ops/playbook/v1_test.exs
  - scrypath_ops/test/fixtures/playbooks/README.md
  - scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs
autonomous: true
requirements:
  - OPS2-07
---

<threat_model>
| Threat | Mitigation |
|--------|------------|
| T-63-03: Secret-shaped keys in nested `opts` | Tests assert `V1.validate/1` returns `{:error, {:invalid_playbook, {:banned_key, "meilisearch_api_key", _path}}}`-shaped tuple for nested banned keys — locks deep scan behavior (match existing **`v1_test`** style). |
| T-63-03: Destructive delete without confirmation | LV test asserts mismatching confirm string does **not** remove file from workspace catalog (`list_workspace_json` / assigns) and surfaces flash containing **`Confirmation must match the filename exactly.`** |
| T-63-03: Documentation drift on scrub policy | Schema doc gains explicit subsection: **no silent sanitize** on `validate/1`; any future sanitize API must be separate (per CONTEXT D-08). |
</threat_model>

<objective>
Extend **fail-closed** playbook validation coverage, add optional **fixture corpus** hooks for CI, document the **threat model slice** in **`playbook-schema-v1.md`**, and prove **delete confirmation** cannot call **`Store.delete_workspace_file/2`** on basename mismatch.
</objective>

<tasks>
<task id="63-03-01" type="execute">
<read_first>
- scrypath_ops/lib/scrypath_ops/playbook/v1.ex
- scrypath_ops/test/scrypath_ops/playbook/v1_test.exs
- scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex
- scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs
- .planning/phases/63-bounded-team-persistence-and-security-posture/63-CONTEXT.md
</read_first>
<action>
1. In **`v1_test.exs`**, add cases: (a) nested `opts` map containing **`meilisearch_api_key`** (or other `@banned_opt_keys` member) rejected with expected error tuple shape; (b) unknown **top-level** key still rejected with existing `{:unknown_key, _}` (or equivalent) pattern used elsewhere in file — grep existing assertions for consistency.
2. Add **`scrypath_ops/test/fixtures/playbooks/README.md`** describing valid vs invalid fixture files if you add raw JSON files; if tests build maps in-code only, README may briefly state “fixtures optional — see v1_test”.
3. In **`playbook_live_test.exs`**, extend stub workspace setup (follow existing tests): open delete modal, submit **`confirm_delete`** with a **wrong** string; assert flash contains **`Confirmation must match the filename exactly.`** and file still listed (or `Store.list_workspace_json` equivalent via UI assigns).
4. In **`playbook-schema-v1.md`**, after **Banned / secret keys** (or new **Security posture** subsection), add a concise **threat model** bullet list: unstructured secrets in **`q` / metadata**; git history exposure; host responsibility for **`/ops`** exposure; explicit statement that **`validate/1`** does not silently redact — align wording with **63-CONTEXT** D-07–D-08.
</action>
<acceptance_criteria>
- `mix test scrypath_ops/test/scrypath_ops/playbook/v1_test.exs` exits **0**.
- `mix test scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs` exits **0**.
- `grep -q 'Confirmation must match the filename exactly' scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs` exits **0**.
- `grep -qi 'threat' scrypath_ops/docs/playbook-schema-v1.md` exits **0** OR `grep -qi 'Security posture' scrypath_ops/docs/playbook-schema-v1.md` exits **0**.
- `grep -qi 'silent' scrypath_ops/docs/playbook-schema-v1.md` exits **0** (word appears in new copy about non-silent validation / sanitize boundary).
</acceptance_criteria>
</task>
</tasks>

<verification>
Run scoped tests above, then `mix verify.opsui` from repository root.
</verification>

<success_criteria>
Security posture for shared playbooks is documented in schema doc and enforced by tests on default CI paths.
</success_criteria>

<must_haves>
- **OPS2-07:** Security posture (banned keys, explicit destructive confirmations, doc’d auth boundary) with tests where feasible on stub paths.
</must_haves>

## PLANNING COMPLETE
