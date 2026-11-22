---
phase: 196
recorded: 2026-11-21
status: recorded for the maintainer, nothing fixed
---

# Phase 196 findings for the maintainer

These are recorded and not fixed (FLOW-04). Nothing here blocks Phase 196 or Phase 197. The only
choice this note asks of you is whether F3 is worth a root `lib/` change, and it can wait until
Phase 198 needs it.

## F3 (new): Scrypath can never show an indexSwap task

**What Meilisearch does.** Recorded from a real v1.15.2 server (see
`fixtures/scrypath_fixtures/recordings/meilisearch-v1.15/PROVENANCE.md`). After a swap, a task list
filtered by `indexUids` leaves the swap out. `GET /tasks?indexUids=logistify_shipment&types=indexSwap`
and the same request for `logistify_shipment__reindex` both return an empty `results` while `total`
says 1 (files `27-list-swap-live.json` and `28-list-swap-partner.json`). Only a request with no index
filter returns the swap, and its `indexUid` is null (`29-list-swap-unfiltered.json`; the task itself
is `26-task-index-swap.json`). The Meilisearch task docs are silent on this.

**Why it matters.** `Scrypath.Meilisearch.Tasks` always filters by `indexUids` when it reads task
history (`list_task_pages/6` in `lib/scrypath/meilisearch/tasks.ex`). So a swap task can never reach
`Scrypath.Operator.State`, the failed-work list or the operator UI. A reindex that ends in a swap
shows its build tasks and never the cutover itself.

**A second fact from the same recording.** A swap also moves each index's task history to the other
name. After the swap the live name had no document tasks and the `__reindex` partner held all ten
(`30-list-after-swap-live-documents.json` and `31-list-after-swap-partner-documents.json`). So after
a cutover the live index's history starts with the reindex build, and the history from before it is
reachable only under the partner's name.

**What it means for the next phases.** The fixtures model it: a builder `indexSwap` task carries a
null `indexUid`, and the fake client leaves such a task out of every `indexUids` filter, as the
server does. Phase 198's Chatly set must therefore derive its cutover story from the `__reindex`
index tasks (`indexCreation` and `documentAdditionOrUpdate` on the partner), not from a swap row,
unless F3 is fixed first.

**What a fix would take.** A change to root `lib/`: read swap tasks with an unfiltered
`types=indexSwap` request and match them to an index through `details.swaps`. That changes the
library's public read path, so it is ask-first (FLOW-02) and is not done here.

**When to look at this again.** On any Meilisearch server bump. The test "finding F3 evidence" in
`scrypath_ops/test/scrypath_ops/fixtures_recordings_test.exs` fails when a re-recording shows the
server returning swaps in filtered lists, which means F3 was fixed upstream and the fake client's
null-index rule needs the same change.

## Fresh evidence for items that were already open

- **F2 (unbounded, copyable Meilisearch error text).** A failed task echoes whatever the customer
  sent. `09-task-failed-missing-document-id-markup.json` shows the whole document, markup and
  non-Latin text included, inside the error message. `08-task-failed-invalid-document-id-hostile.json`
  shows a rejected id echoed with a right-to-left override and a ZWJ emoji intact. Both are what the
  operator UI would show.
- **F1 (task history truncated at 1,000).** Plan 04's labelled `history_over_limit` stress variation
  is meant to reproduce it against the fake client, which now pages like the recorded server (the
  conformance tests in `fixtures_recordings_test.exs` show that). It is a named stress case, not
  part of any ordinary scenario.

## Still open, recorded in Phase 195

F1, F2, D2 (retry receipts live only in the LiveView process) and the `dashboard_routes` guard defect
are written up in
[`../195-mount-and-prove/GO-NO-GO.md`](../195-mount-and-prove/GO-NO-GO.md), "Findings for the
maintainer". Nothing about them changed in this phase.
