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
| IN-01 | info | open | Dedupe before JSON encoding (`:a` vs `"a"`). |
| IN-02 | info | open | Example calls `sync_related` inside transaction vs guide advice. |
| IN-03 | info | open | Ecommerce resolver id clause dead code, skips tenant filter. |
| IN-04 | info | open | Loader programming errors retried instead of cancelled. |
| IN-05 | info | open | Unique `:states` omits `:executing`. |
