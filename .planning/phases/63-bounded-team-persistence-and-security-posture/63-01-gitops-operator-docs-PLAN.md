---
phase: 63
plan: "01"
type: execute
wave: 2
depends_on:
  - "02"
files_modified:
  - scrypath_ops/docs/playbook-schema-v1.md
  - scrypath_ops/docs/team-playbook-persistence.md
  - scrypath_ops/docs/operator-ia.md
  - scrypath_ops/README.md
autonomous: true
requirements:
  - OPS2-04
---

<threat_model>
| Threat | Mitigation |
|--------|------------|
| T-63-01: Operators assume dual authority (file + future DB) | Docs state **v1.15** has **exactly one** mutating catalog source — filesystem workspace only; Ecto catalog explicitly **deferred** with pointer to roadmap/context. |
| T-63-01: Relative workspace paths in prod | Document **absolute** `SCRYPATH_OPS_PLAYBOOK_DIR` for releases; cite `runtime.exs` trim + `Path.expand/1` behavior. |
| T-63-01: Secrets committed in playbook JSON | Cross-link **`playbook-schema-v1.md`** banned-key section and git hygiene in persistence doc. |
</threat_model>

<objective>
Ship the **golden operator persistence doc** plus align **`playbook-schema-v1.md` § Persistence** and **`operator-ia.md`** with Phase 63 decisions: filesystem/GitOps as the **only** v1.15 team story, env resolution via **`SCRYPATH_OPS_PLAYBOOK_DIR`**, and **securing `/ops`** as a host concern with pointers to Phoenix session/`on_mount` patterns.
</objective>

<tasks>
<task id="63-01-01" type="execute">
<read_first>
- .planning/phases/63-bounded-team-persistence-and-security-posture/63-CONTEXT.md
- scrypath_ops/docs/playbook-schema-v1.md
- scrypath_ops/docs/operator-ia.md
- scrypath_ops/config/runtime.exs
- scrypath_ops/README.md
- milestones/v1.14-REQUIREMENTS.md
</read_first>
<action>
1. Add **`scrypath_ops/docs/team-playbook-persistence.md`** as the canonical page: workspace layout (flat `*.json` basenames under root), **`SCRYPATH_OPS_PLAYBOOK_DIR`** semantics matching **`runtime.exs`** (nil/empty unset; non-empty trimmed + expanded), PR/review workflow for JSON, merge/conflict expectations, volume mount patterns (mounted checkout vs PVC vs image `COPY`), CI suggestion pointing to **`mix scrypath_ops.playbooks.validate PATH`** (task shipped in plan **02** — write doc so the command string matches the implemented task module **`Mix.Tasks.ScrypathOps.Playbooks.Validate`** exactly).
2. Rewrite **`playbook-schema-v1.md` § Persistence** to describe **v1.15** single authority (filesystem + configured root only); remove or supersede any wording that implies an in-app multi-tenant catalog for this milestone; keep **Ecto** mention only as **explicitly out of scope for Phase 63** / future optional mode (consistent with **63-CONTEXT** D-01, D-15).
3. In **`operator-ia.md`**, add a short **“Securing `/ops`”** subsection (or bullet under adoption) stating auth is **host-owned**, linking to Phoenix **`live_session`** / **`on_mount`** docs or internal example paths already referenced in-repo; do not invent a new auth mechanism.
4. Update **`scrypath_ops/README.md`** with one prominent link to **`docs/team-playbook-persistence.md`** in the operator/adoption section (match README’s existing tone and list style).
</action>
<acceptance_criteria>
- `test -f scrypath_ops/docs/team-playbook-persistence.md` exits **0**.
- `grep -q 'SCRYPATH_OPS_PLAYBOOK_DIR' scrypath_ops/docs/team-playbook-persistence.md` exits **0**.
- `grep -q 'mix scrypath_ops.playbooks.validate' scrypath_ops/docs/team-playbook-persistence.md` exits **0**.
- `grep -q '## Persistence' scrypath_ops/docs/playbook-schema-v1.md` exits **0** and `grep -q 'v1.15' scrypath_ops/docs/playbook-schema-v1.md` exits **0**.
- `grep -qi 'securing' scrypath_ops/docs/operator-ia.md` exits **0**.
- `grep -q 'team-playbook-persistence.md' scrypath_ops/README.md` exits **0**.
</acceptance_criteria>
</task>
</tasks>

<verification>
Read new/edited markdown for internal cross-links (relative paths resolve). No code compile required for this plan alone; optional `mix format` not needed for markdown-only change.
</verification>

<success_criteria>
Operators can answer “where do team playbooks live, how do we deploy the directory, and what is authoritative?” from **`team-playbook-persistence.md`** plus updated schema persistence section.
</success_criteria>

<must_haves>
- **OPS2-04:** One explicit filesystem/GitOps persistence story with documented authority and limitations.
</must_haves>

## PLANNING COMPLETE
