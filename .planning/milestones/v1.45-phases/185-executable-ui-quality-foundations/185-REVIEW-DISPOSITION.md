---
phase: 185
review: 185-REVIEW.md
titles: json
findings:
  - id: WR-01
    severity: warning
    disposition: deferred
    title: "Internal direct PNG helpers rely on validated input"
  - id: WR-02
    severity: warning
    disposition: deferred
    title: "Inherited custom workflow reporting can misname the selected workflow"
open: 0
total: 2
recorded: 2026-11-01T09:25:25.198Z
---

# Phase 185: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| WR-01 | warning | deferred | Canonical CLI validates dimensions before internal helper; arbitrary direct buffer safety is outside current contract. |
| WR-02 | warning | deferred | Inherited nondefault reporting issue; approved wrappers use validated default ci.yml without override. |

Dispositions: `open` (recorded, not yet triaged), `fixed`, `skipped`, `deferred`.
Set `deferred` by hand and put the reason in the Source cell; both are preserved. A `|` in the reason is kept as prose and escaped on the next run.
Re-running the gate keeps every row it can. A row the current review no longer reports is kept and its Source cell flagged, so a finding does not leave this record silently. ONE exception: when a finding id is REUSED by a different finding, the earlier decision cannot keep a row — the id is taken — and it is dropped. A RECORDED decision (anything but `open`) is named on the console when that happens; a row still at `open` is replaced silently, because `open` records no decision to lose.
