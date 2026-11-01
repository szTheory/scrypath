---
phase: 183
review: 183-REVIEW.md
titles: json
findings:
  - id: WR-01
    severity: warning
    disposition: open
    title: "Nothing guards against `dev/mix/tasks` leaking into `:prod`/`:dev` builds (path and git consumers)"
  - id: WR-02
    severity: warning
    disposition: open
    title: "The D-04 preferred-env guard classifies by module name, not by location under `dev/mix/tasks`"
  - id: WR-03
    severity: warning
    disposition: open
    title: "The L1 AST scan misses aliased, `Elixir.`-prefixed and atom-literal module names"
  - id: WR-04
    severity: warning
    disposition: open
    title: "The website still tells package installers and operators to run `mix verify.adopter`, which the package no longer ships"
  - id: IN-01
    severity: info
    disposition: open
    title: "The `verify.workspace_clean` moduledoc still describes only `test/**`"
  - id: IN-02
    severity: info
    disposition: open
    title: "CONTRIBUTING says \"Command names and focused test paths are unchanged\", but this phase renamed one of each"
  - id: IN-03
    severity: info
    disposition: open
    title: "The README qualifier refers to \"this task\" before naming any task"
  - id: IN-04
    severity: info
    disposition: open
    title: "Double-negative assertion"
  - id: IN-05
    severity: info
    disposition: open
    title: "A parse failure in a packaged file does not report the file"
open: 9
total: 9
recorded: 2026-10-28T14:37:55.803Z
---

# Phase 183: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| WR-01 | warning | open | - |
| WR-02 | warning | open | - |
| WR-03 | warning | open | - |
| WR-04 | warning | open | - |
| IN-01 | info | open | - |
| IN-02 | info | open | - |
| IN-03 | info | open | - |
| IN-04 | info | open | - |
| IN-05 | info | open | - |

Dispositions: `open` (recorded, not yet triaged), `fixed`, `skipped`, `deferred`.
Set `deferred` by hand and put the reason in the Source cell; both are preserved. A `|` in the reason is kept as prose and escaped on the next run.
Re-running the gate keeps every row it can. A row the current review no longer reports is kept and its Source cell flagged, so a finding does not leave this record silently. ONE exception: when a finding id is REUSED by a different finding, the earlier decision cannot keep a row — the id is taken — and it is dropped. A RECORDED decision (anything but `open`) is named on the console when that happens; a row still at `open` is replaced silently, because `open` records no decision to lose.
