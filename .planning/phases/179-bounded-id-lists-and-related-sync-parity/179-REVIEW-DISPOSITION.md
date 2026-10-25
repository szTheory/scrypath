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
| WR-01 | warning | open | Multi-chunk enqueue's own transaction/rollback inside a caller transaction (ecommerce example `Multi.run`). Needs owner decision. |
| WR-03 | warning | open | 0.3.17 related jobs in apps without repo/`search_records/2` cancel with `:repo_required` on upgrade; no upgrade note yet. |
| WR-04 | warning | open | Backfill reports only last delete chunk's task for >1000 removals per page. |
| WR-05 | warning | open | Telemetry start count includes duplicates; ≤1000-id results now deduped + string-sorted (vs D-08 "unchanged"). |
| IN-01 | info | open | Dedupe before JSON encoding (`:a` vs `"a"`). |
| IN-02 | info | open | Example calls `sync_related` inside transaction vs guide advice. |
| IN-03 | info | open | Ecommerce resolver id clause dead code, skips tenant filter. |
| IN-04 | info | open | Loader programming errors retried instead of cancelled. |
| IN-05 | info | open | Unique `:states` omits `:executing`. |
