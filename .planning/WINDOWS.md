---
schema_version: 1
open_count: 1
waived_count: 0
fixed_count: 0
total_count: 1
last_updated: 2026-09-26T03:12:54.942Z
---

# Broken Windows Ledger

> Cross-phase defect register. With `workflow.windows_enforce` enabled, `/gsd-ship` blocks while `open_count > 0`.
> Waive with `gsd-tools windows waive <id> "<reason>"` (reason required).
> Mark fixed with `gsd-tools windows fixed <id>`.

| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |
|----|-------|------|------|------|-------------|--------|--------|-------------|-------------|
| 1 | 164 | unrun-verify | scripts/ci_monitor.cjs |  | Exact-SHA candidate and final closeout remain unrun because automatic approval review rejected the push and CI dispatch pending explicit authorization. | open |  | 2026-09-26T03:12:54.942Z |  |

````json
[
  {
    "id": 1,
    "kind": "unrun-verify",
    "phase": "164",
    "file": "scripts/ci_monitor.cjs",
    "line": null,
    "description": "Exact-SHA candidate and final closeout remain unrun because automatic approval review rejected the push and CI dispatch pending explicit authorization.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-26T03:12:54.942Z",
    "resolved_at": null,
    "milestone": "v1.39"
  }
]
````
