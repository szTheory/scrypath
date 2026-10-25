---
phase: 179-bounded-id-lists-and-related-sync-parity
review: 179-REVIEW.md
updated: 2026-10-25
---

# Phase 179 — Code Review Disposition

| Finding | Severity | Disposition | Evidence |
|---------|----------|-------------|----------|
| CR-01 | critical | fixed | 858e83dc — full-name `String.to_existing_atom`; runtime-built module regression test (failed on old code). Independently reproduced in a fresh VM before fixing. Also affected upsert/delete workers since 0.3.0 (shipped releases). |
| WR-02 | warning | fixed | 4d74ed9d — `document_ids` elements must be integer or binary; else `{:invalid_arg, "document_ids"}` → cancel. Float/boolean ids now rejected (owner may widen). |
| WR-01 | warning | fixed | 24a35c9a — nested in a caller transaction: no own transaction/rollback, returns bare `{:error, reason}` for the caller to abort; standalone stays all-or-nothing. Real-Oban SQLite tests (fail on old code). |
| WR-03 | warning | fixed (docs) | 81930d86 — no behaviour change; upgrade note in guide + 179-06 release note (configure default `:repo`, define `search_records/2`, or drain related jobs first); legacy 0.3.17 fixture test pins the cancel outcome. |
| WR-04 | warning | fixed | 70c8f326 — batch results gain `delete_tasks:` (every delete chunk, `[]` when none); reindex waits on them before cutover. |
| WR-05 | warning | fixed | a28bc4e7 — start-event count deduped to match stop/result; deduped string-sorted `document_ids` documented at every size (narrows D-08 deliberately; carry into release upgrade notes). |
| IN-01 | info | fixed | b9d67b09 — ids normalized to stored form (`Payload.serialize_ids!/1`) before dedupe/chunk; `Chunks.id_key/1` + `distinct_count/1` keep inline/manual and span counts coherent. `1` vs `"1"` stay distinct by design (JSON + Chunks contract). |
| IN-02 | info | fixed (docs) | d8053655 — guide rule per case: `:oban` same repo → inside the transaction is atomic; `:oban` other repo → after commit; `:inline` → after commit. Example already correct. |
| IN-03 | info | fixed | c250ce5c — tenant-unscoped id clause removed (overrides 179-07 keep); catalog test passes records; 10/10 on native Postgres. |
| IN-04 | info | fixed | 44a44b84 — non-list `search_records/2` → `{:cancel, {:invalid_job, :invalid_search_records}}` in upsert + related workers. |
| IN-05 | info | skipped by design | 64b8dc8c — `:executing` excluded per D-20 (a sync during a running job must enqueue, else the update is lost); Oban 2.23 warns only for compile-time worker unique opts; comment flags unverified Oban Pro Smart-engine interaction. |
