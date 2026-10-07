---
phase: 173
review: 173-REVIEW.md
titles: json
findings:
  - id: WR-03
    severity: warning
    disposition: fixed
    title: "Invalid runtime configuration crashes the error-row renderer"
  - id: WR-01
    severity: warning
    disposition: fixed
    title: "Whole-schema errors hide retained queue evidence"
  - id: CR-01
    severity: critical
    disposition: fixed
    title: "Empty Oban history is reported as unavailable"
  - id: WR-02
    severity: warning
    disposition: fixed
    title: "Timed-out schema scans lose the schema key needed to retain its last success"
open: 0
total: 4
recorded: 2026-10-07T01:43:57.114Z
---

# Phase 173: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| WR-03 | warning | fixed | 173-REVIEW-FIX.md (not in the current review) |
| WR-01 | warning | fixed | 173-REVIEW-FIX.iter2.md (not in the current review) |
| CR-01 | critical | fixed | 173-REVIEW-FIX.iter1.md (not in the current review) |
| WR-02 | warning | fixed | 173-REVIEW-FIX.iter1.md (not in the current review) |

Dispositions: `open` (recorded, not yet triaged), `fixed`, `skipped`, `deferred`.
Set `deferred` by hand and put the reason in the Source cell; both are preserved. A `|` in the reason is kept as prose and escaped on the next run.
Re-running the gate keeps every row it can. A row the current review no longer reports is kept and its Source cell flagged, so a finding does not leave this record silently. ONE exception: when a finding id is REUSED by a different finding, the earlier decision cannot keep a row — the id is taken — and it is dropped. A RECORDED decision (anything but `open`) is named on the console when that happens; a row still at `open` is replaced silently, because `open` records no decision to lose.
