---
phase: 178
review: 178-REVIEW.md
titles: json
findings:
  - id: WR-01
    severity: warning
    disposition: open
    title: "`:query` with `distinct` (or combinations/group_by) breaks keyset paging; on Postgres rows are skipped silently"
  - id: WR-02
    severity: warning
    disposition: open
    title: "The internal `_scrypath_fresh_target` flag is accepted from public `Scrypath.backfill/2` and turns off live-index deletes"
  - id: WR-03
    severity: warning
    disposition: open
    title: "Behavior change for existing `search_records/2` schemas is missing from the upgrade notes"
  - id: IN-01
    severity: info
    disposition: open
    title: "Docs conflate `preload:` and `search_records/2`; preload is not applied on the custom-loader path"
  - id: IN-02
    severity: info
    disposition: open
    title: "Misleading `force: true` rationale in the loader"
  - id: IN-03
    severity: info
    disposition: open
    title: "Partial failure gives no progress information now that each batch has two writes"
  - id: IN-04
    severity: info
    disposition: open
    title: "Nullable composite-key columns on SQLite are only partly guarded"
  - id: IN-05
    severity: info
    disposition: open
    title: "Keyless schemas with non-unique document ids drop duplicates across page boundaries"
  - id: IN-06
    severity: info
    disposition: open
    title: "Composite-key fixtures use `\"org:seq\"` ids that Meilisearch rejects"
open: 9
total: 9
recorded: 2026-10-25T19:35:48.118Z
---

# Phase 178: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| WR-01 | warning | open | - |
| WR-02 | warning | open | - |
| WR-03 | warning | open | - |
| IN-01 | info | open | - |
| IN-02 | info | open | - |
| IN-03 | info | open | - |
| IN-04 | info | open | - |
| IN-05 | info | open | - |
| IN-06 | info | open | - |

Dispositions: `open` (recorded, not yet triaged), `fixed`, `skipped`, `deferred`.
Set `deferred` by hand and put the reason in the Source cell; both are preserved. A `|` in the reason is kept as prose and escaped on the next run.
Re-running the gate keeps every row it can. A row the current review no longer reports is kept and its Source cell flagged, so a finding does not leave this record silently. ONE exception: when a finding id is REUSED by a different finding, the earlier decision cannot keep a row — the id is taken — and it is dropped. A RECORDED decision (anything but `open`) is named on the console when that happens; a row still at `open` is replaced silently, because `open` records no decision to lose.
