---
phase: 184
review: 184-REVIEW.md
titles: json
findings:
  - id: CR-01
    severity: critical
    disposition: open
    title: "A host with metrics but no poller cannot start ScrypathOps"
  - id: CR-02
    severity: critical
    disposition: open
    title: "Non-nil malformed identities authorize protected Sigra actions"
  - id: WR-01
    severity: warning
    disposition: open
    title: "Failed target-asset extraction leaves a container outside cleanup ownership"
  - id: WR-02
    severity: warning
    disposition: open
    title: "Startup accepts confirmation paths that crash the recovery navigation"
  - id: WR-03
    severity: warning
    disposition: open
    title: "The standalone quickstart advertises a toolchain that cannot compile its default graph"
open: 5
total: 5
recorded: 2026-10-30T23:29:28.941Z
---

# Phase 184: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| CR-01 | critical | open | - |
| CR-02 | critical | open | - |
| WR-01 | warning | open | - |
| WR-02 | warning | open | - |
| WR-03 | warning | open | - |

Dispositions: `open` (recorded, not yet triaged), `fixed`, `skipped`, `deferred`.
Set `deferred` by hand and put the reason in the Source cell; both are preserved. A `|` in the reason is kept as prose and escaped on the next run.
Re-running the gate keeps every row it can. A row the current review no longer reports is kept and its Source cell flagged, so a finding does not leave this record silently. ONE exception: when a finding id is REUSED by a different finding, the earlier decision cannot keep a row — the id is taken — and it is dropped. A RECORDED decision (anything but `open`) is named on the console when that happens; a row still at `open` is replaced silently, because `open` records no decision to lose.
