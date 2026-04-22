# Phase 64 — Pattern map

Analogs and excerpts for executors (from **64-CONTEXT.md** + codebase).

## IA ↔ code ↔ doc

| Target | Role | Analog | Notes |
|--------|------|--------|------|
| `operator-ia.md` Navigation | Human IA + machine fence | `63-01-gitops-operator-docs-PLAN.md` | Prior phase edited same file + persistence cross-links |
| `Nav.primary/0` | Ordered chrome | `scrypath_ops/lib/scrypath_ops_web/nav.ex` | Single list of `%{path: ~p"/ops/...", label: "..."}` |
| Mechanical sync | Doc fence JSON | `scrypath_ops/lib/mix/tasks/scrypath_ops/check_nav_contract.ex` | Run with `--write` when code is source of truth |

**Excerpt — contract test router discovery:**

```elixir
# operator_ia_contract_test.exs — ops_live_paths/1 parses live_session :ops
~r/live\("([^"]+)"/
```

## Contributor verify (stub-first)

| Target | Analog |
|--------|--------|
| New LiveView vertical | `scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs` — `SearchPlaygroundStubAdapter`, temp `playbook_workspace_dir`, `async: false` |
| Root gate | `lib/mix/tasks/verify.opsui.ex` — `System.cmd("bash", ["-lc", script], cd: ops_dir)` |

## Doc contract anchors (root)

| Target | Analog |
|--------|--------|
| `CONTRIBUTING` ↔ `verify.opsui` moduledoc | `test/scrypath/docs_contract_test.exs` — `@verify_opsui File.read!(...)` + string assertions |

## Milestone freeze

| Target | Analog |
|--------|--------|
| Frozen roadmap | `.planning/milestones/v1.14-ROADMAP.md` header + phase checklist sections |
| Traceability snapshot | `.planning/milestones/v1.14-REQUIREMENTS.md` |
| Audit YAML | `.planning/milestones/v1.14-MILESTONE-AUDIT.md` frontmatter |

---

## PATTERN MAPPING COMPLETE
