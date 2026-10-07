---
phase: 173
source_review: 173-REVIEW.md
source_reviewed_at: 2026-10-07T01:42:00Z
status: fixes_applied
---

# Phase 173 Error-rendering Fix

The independent re-review confirmed all earlier findings fixed and reported WR-03. Earlier finding identities and source-bound native evidence remain in the committed reports, disposition ledger, and iteration fix reports.

## Fixed Issues

### WR-03: Invalid runtime configuration crashes the error-row renderer

`bbc8453` catches the runtime validator's documented ArgumentError in the mode lookup and returns an explicit unknown mode. Rendering then reports queue observation unavailable without asserting that the queue is unused or validating the same invalid config again into a crash. Valid modes still use authoritative defaults/per-repo configuration.

`4f193e2` adds a direct production renderer regression with an error row and invalid runtime configuration. Its actual RED (`review3-ops-red.log`) failed because the missing backend raises during the mode lookup; GREEN (`review3-ops-green.log`) passes after the guard. This is render behavior coverage, not a claim that the live scanner catches every arbitrary task exception. The final full Ops check and independent verification follow separately.
