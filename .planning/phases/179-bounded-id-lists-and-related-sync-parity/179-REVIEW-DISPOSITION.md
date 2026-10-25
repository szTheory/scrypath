---
phase: 179-bounded-id-lists-and-related-sync-parity
review: 179-REVIEW.md
updated: 2026-10-25
---

# Phase 179 — Code Review Disposition

| Finding | Severity | Disposition | Evidence |
|---------|----------|-------------|----------|
| CR-01 | critical | fixed | 858e83dc — full-name `String.to_existing_atom`; runtime-built module regression test (failed on old code). Independently reproduced in a fresh VM before fixing. Also affected upsert/delete workers since 0.3.0 (shipped releases). |
| WR-02 | warning | partly fixed | 4d74ed9d — `document_ids` elements must be integer or binary; else `{:invalid_arg, "document_ids"}` → cancel. Float/boolean ids now rejected (owner may widen). | Remainder tracked as WR-06 / WR-07. |
| WR-01 | warning | fixed | 24a35c9a — nested in a caller transaction: no own transaction/rollback, returns bare `{:error, reason}` for the caller to abort; standalone stays all-or-nothing. Real-Oban SQLite tests (fail on old code). |
| WR-03 | warning | fixed (docs) | 81930d86 — no behaviour change; upgrade note in guide + 179-06 release note (configure default `:repo`, define `search_records/2`, or drain related jobs first); legacy 0.3.17 fixture test pins the cancel outcome. |
| WR-04 | warning | fixed | 70c8f326 — batch results gain `delete_tasks:` (every delete chunk, `[]` when none); reindex waits on them before cutover. |
| WR-05 | warning | fixed | a28bc4e7 — start-event count deduped to match stop/result; deduped string-sorted `document_ids` documented at every size (narrows D-08 deliberately; carry into release upgrade notes). |
| IN-01 | info | fixed | b9d67b09 — ids normalized to stored form (`Payload.serialize_ids!/1`) before dedupe/chunk; `Chunks.id_key/1` + `distinct_count/1` keep inline/manual and span counts coherent. `1` vs `"1"` stay distinct by design (JSON + Chunks contract). |
| IN-02 | info | reopened → CR-02 | d8053655 regressed the guidance (re-review 2026-10-25); superseded by CR-02. |
| IN-03 | info | fixed | c250ce5c — tenant-unscoped id clause removed (overrides 179-07 keep); catalog test passes records; 10/10 on native Postgres. |
| IN-04 | info | fixed | 44a44b84 — non-list `search_records/2` → `{:cancel, {:invalid_job, :invalid_search_records}}` in upsert + related workers. |
| IN-05 | info | skipped by design | 64b8dc8c — `:executing` excluded per D-20 (a sync during a running job must enqueue, else the update is lost); Oban 2.23 warns only for compile-time worker unique opts; comment flags unverified Oban Pro Smart-engine interaction. |

## Re-review (fix diff e69b2601..79c3dc7f)

| Finding | Severity | Disposition | Evidence |
|---------|----------|-------------|----------|
| CR-02 | critical | open | Guides (d8053655, 24a35c9a) call in-transaction `:oban` sync "supported and atomic"; with `unique:` an in-transaction enqueue can collapse into an existing job that runs before commit (stale read → lost update, D-20), and the advisory xact lock makes concurrent identical syncs report `conflict?: true` without inserting, lost if the holder rolls back. Orchestrator confirmed against `deps/oban/lib/oban/engines/basic.ex` `insert_unique/3` + `acquire_lock/2`. Ecommerce `update_category` calls `sync_related` inside `Multi.run`. |
| WR-06 | warning | open | Enqueue accepts `nil`/float/boolean ids (`payload.ex`) that the worker now cancels; a nil id silently cancels a whole ≤1000-id chunk job. |
| WR-07 | warning | open | Uncastable string ids (`"abc"` for integer PK) pass decode, raise `Ecto.Query.CastError` in the loader, retried 8×. |
| IN-06 | info | open | Inline `sync_related` passes/counts duplicate triggers; guide promises deduped input. |
