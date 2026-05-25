---
phase: 91-integration-guides-and-verification
plan: 01
subsystem: docs
tags: [docs, related-data, fan-out, oban]
requires:
  - "Scrypath.sync_related/3 (shipped Phase 89)"
  - "fan_outs: metadata declaration (shipped Phase 89)"
  - "Scrypath.Sync.RelatedWorker (shipped Phase 90)"
provides:
  - "Canonical Scrypath.sync_related/3 fan-out guide section"
  - "Shared canonical-string contract for 91-02 docs-contract assertions"
affects:
  - "test/scrypath/docs_contract_test.exs (91-02 inverts the related-data assertion against these strings)"
tech-stack:
  added: []
  patterns:
    - "Resolver-arity-safe resolver (pattern-match records vs ids, funnel to reload-by-id)"
    - "Honesty boundary: durably queued != searchable now"
    - "Context-owns-orchestration / library-owns-execution boundary (D-05)"
key-files:
  created: []
  modified:
    - "guides/related-data-and-reindexing.md"
decisions:
  - "Heading for the new canonical section is '### Fan-out with Scrypath.sync_related/3' (replacing '### Temporary Workaround: Custom Oban Jobs')."
  - "D-04 outcome matrix rendered as a Markdown table attached to the :oban path, not as pasted library source."
  - "'library owns execution' added in the 'What Scrypath should stay opinionated about here' section, paired with the existing 'contexts own orchestration' bullet."
metrics:
  duration: "~2m"
  completed: "2026-05-25"
  tasks: 2
  files: 1
---

# Phase 91 Plan 01: Canonical sync_related/3 Fan-out Guide Summary

Rewrote `guides/related-data-and-reindexing.md` so `Scrypath.sync_related/3` and the built-in Oban path (internal `Scrypath.Sync.RelatedWorker`, selected via `sync_mode: :oban`) are the canonical, shipped fan-out story — deleting the "temporary workaround / first-class feature" framing and the custom `SyncAuthorPostsWorker` code, and folding the inline-vs-oban decision into blast radius + request latency with the D-04 retry/cancel matrix and the honesty boundary.

## What Was Built

**Task 1 — Replace the temporary-workaround subsection with the canonical `Scrypath.sync_related/3` section** (commit `bf0616e`)
- Deleted the entire `### Temporary Workaround: Custom Oban Jobs` subsection, including the `MyApp.Blog.SyncAuthorPostsWorker` worker block and the `MyApp.Accounts.update_author` `Oban.insert!` block (D-06, D-07 — removed, not retained as an alternative).
- Added `### Fan-out with Scrypath.sync_related/3` presenting the shipped API as canonical, using the Author-rename motif (posts store `author_name`):
  - (a) schema-side `fan_outs:` declaration on the owning `Author` schema (`target: MyApp.Blog.Post`, `resolver: {MyApp.Accounts, :resolve_posts_for_authors, []}`);
  - (b) context-side calls for BOTH `sync_mode: :inline` (`{:ok, %{mode: :inline, status: :completed}}`) and `sync_mode: :oban` (`{:ok, %{mode: :oban, status: :accepted}}`);
  - (c) an arity-safe resolver that pattern-matches `[%Author{} | _]` records (inline) AND `[_id | _]` ids (oban), funneling both to a reload-by-`author_id` query — the resolver-arity duality, called out as the #1 footgun.
- Stated explicitly there is no public worker macro to write (D-03): `:oban` is dispatched by the internal `Scrypath.Sync.RelatedWorker`; adopters never name a worker module.
- Noted `opts[:fan_out]` is required (raises `ArgumentError` if absent), matching `lib/scrypath/sync.ex:41-42`.

**Task 2 — Extend "Picking the right follow-up path"** (commit `8aca1ec`)
- Mapped the inline-vs-oban choice to BLAST RADIUS + REQUEST LATENCY: small/bounded + latency-tolerant → `sync_mode: :inline`; many rows + latency-sensitive + Oban-as-normal-infra → `sync_mode: :oban`; unbounded/uncertain blast radius → manual / backfill / managed reindex.
- Kept the honesty block verbatim ("the follow-up work is durably queued" / "all affected documents are searchable now") and attached it explicitly to the `:oban` path.
- Added the D-04 retry/cancel outcome matrix as a Markdown table: success → `:ok`; HTTP 4xx → `{:cancel, ...}` (permanent, no retry); HTTP 5xx/generic → `{:error, reason}` (transient, Oban retries to `max_attempts: 8`); invalid schema/fan-out → `{:cancel, {:invalid_job, reason}}` (permanent). Stated these are mapped by the internal worker, not app code.
- Added the literal boundary phrase `library owns execution` in the "What Scrypath should stay opinionated about here" section, paired with the existing `contexts own orchestration`, so the guide literally states both halves of D-05.
- Preserved the `callback magic` sentence and the authz warning (`index prefixes alone are`) unchanged.

## Canonical Asserted Strings (shared contract with 91-02)

These literal strings are now present in `guides/related-data-and-reindexing.md` and must be asserted by 91-02's inverted docs-contract test (each verified present via `grep -F`):

MUST contain (verbatim):
- `Scrypath.sync_related/3`
- `fan_outs:`
- `sync_mode: :inline`
- `sync_mode: :oban`
- `callback magic`
- `contexts own orchestration`
- `library owns execution`

MUST NOT contain anywhere (verified absent, case-insensitive):
- `temporary workaround`
- `first-class feature`

Additional load-bearing strings present for 91-02's optional assertions: `RelatedWorker`, `durably queued`, `searchable now`, `max_attempts: 8`, `mode: :inline, status: :completed`, `mode: :oban, status: :accepted`.

## Verification

All grep gates from both tasks PASS:
- Task 1 gate: no `temporary workaround`, no `first-class feature`, contains `Scrypath.sync_related/3`, `fan_outs:`, `sync_mode: :inline`, `sync_mode: :oban` → PASS.
- Task 1 acceptance: `SyncAuthorPostsWorker` absent, `Oban.insert!` absent, `RelatedWorker` present, resolver shows both record and id shapes.
- Task 2 gate: `library owns execution`, `contexts own orchestration`, `callback magic`, `durably queued`, `searchable now`, `retr`, `cancel` all present → PASS.
- Voice anchors preserved: line-16 ("Your app owns the fan-out"), line-174 ("web modules still do not own this logic"), authz warning ("index prefixes alone are").
- No `lib/scrypath*` file modified (`git status --short lib/` empty).

Per the plan's verification note, the full `docs_contract_test.exs` green-expectation was deliberately NOT run between this plan and 91-02: the OLD assertion (line ~1128) still asserts the guide CONTAINS the now-deleted banned strings, so it is expected to fail until 91-02 inverts it in the same wave-2 step. The grep gates above are the correct verification for this docs-only plan.

## Deviations from Plan

None - plan executed exactly as written. No bugs, missing functionality, blocking issues, or architectural changes encountered. No authentication gates.

## Self-Check: PASSED

- `guides/related-data-and-reindexing.md` — FOUND (modified)
- `.planning/phases/91-integration-guides-and-verification/91-01-SUMMARY.md` — FOUND (this file)
- Commit `bf0616e` (Task 1) — present in git log
- Commit `8aca1ec` (Task 2) — present in git log
