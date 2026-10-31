# Parent capture repairs and fixed-time integration

Status: implementation verified by focused tests; actual disposable same-source proof pending. Plan05 remains incomplete.

## Source and isolation

Parent checkout `/Users/jon/projects/scrypath/.claude/worktrees/agent-p185-glue-u80ewc0s` was created through the GSD worktree adapter from root `3b618c25`, then merged immutable earlier-fixer snapshot `8f076463`. The other executor remains isolated and must not be steered. Its newer runtime inspection/full-container-ID corrections (currently `0a61f61d`) must be merged after it is terminal, before this checkout performs a capture. Root main merge/release authority is unchanged.

## Review repairs

- Real state-reader regression proved that task status and completion-time changes were invisible to the digest. The state now includes all task fields, index metadata and stats, settings, documents and bounded normalized PostgreSQL dump content. The complete task response must fit the unchanged 1000-task budget; any omitted tail fails. A single full response avoids inferring cursor totals. [Meilisearch's task specification](https://specs.meilisearch.dev/specifications/text/0060-tasks-api.html) defines task fields and seek cursors; its examples show totals changing with `from`. No library task semantics or history limit changed.
- Full-page geometry differences now produce a comparison and explicitly marked generated diff, with original dimensions recorded. Source images remain unchanged. A finite canvas budget is checked before PNG decoding. Comparison output uses a temporary directory and commits atomically after success, allowing retry after failure without overwriting prior evidence.
- Exact independent project/session/resource checks remain on teardown, but frozen-artifact comparison and disposable cleanup no longer depend on a live retained preview. Capture/start/replace still recheck retained resource facts.
- The internal test clock is now wired to both app services and Chromium. Read `185-05-CLOCK.md` for the bounded file, actual probes, immutable fixture and per-entry copy/environment binding. No CSS, HEEx, controller or generator change belongs to this repair.

## Verification

Behavioral RED records retain actual failures, transparent TAP adapters and invalid adapter attempts rather than relabeling discovery/format errors as acceptance. `185-05-parent-glue-RED.json` covers the three review regressions; `185-05-clock-glue-RED.json` covers clock metadata binding. Classifiers returned RED_EVIDENCE_OK before GREEN. The first native TAP classifier rejected nested diagnostics; the adapter clears only Node's inherited runner variable and explicitly asserts three-test discovery.

GREEN source: `b35e70f6` (review repairs), `e056a8f3` (clock wiring), `f5ba3326` (complete bounded task snapshot). Focused Node tests passed 43/0 after the last source change; syntax and whitespace checks passed. Scoped Luna source review at e056 found no additional confirmed defects, with the known task-reader correction excluded. This source review ran no tests or Docker and grants no visual or phase acceptance.

## Remaining work

Reconcile the earlier corrective executor after terminal, archive its raw evidence unchanged and use its own exact helper/authority to remove only its owned stack if still present. Then run a fresh source-pinned fixed-clock baseline and same-source candidate comparison using this repaired implementation. No source/capture manifest may be rewritten to claim later evidence. Only valid pre-change evidence allows Plans06/07 UI edits; remaining phase plans and final root/hosted gates are still pending. No user action is needed for these authorized steps.
