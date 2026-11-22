# Phase 196: Fixtures and three adopters - Context

**Gathered:** 2026-11-21
**Status:** Ready for planning

<domain>
## Phase Boundary

Build `fixtures/scrypath_fixtures` (ADR 0002): pure builders that take `now` and emit raw Meilisearch task maps and Oban job maps, so the real `Operator.Status`, `FailedWork` and `Posture` code does the normalizing and only reachable states exist. Three Scrypath-owned fictional adopters with named states: Shopadelic (journey and settings drift), Logistify (deep queue, nothing failed), Wikily (empty install). Real Meilisearch payload shapes recorded once; closed failure-string table with `source:` fields; hostile text as escapes; a DB-free `check_fixtures` task first in its consumers' `test` alias; the fixtures never ship in the Hex tarball. Not in this phase: stories, view-models, the pilot journey, the 4003 preview (Phase 197), Clinicly and Chatly sets (Phase 198).

</domain>

<decisions>
## Implementation Decisions

### Recorded maintainer decisions (adopted 2026-11-21; not re-opened here)
- ADR 0002: a top-level `fixtures/scrypath_fixtures` Mix project, `scrypath_ops` takes it as a path dependency with `only: [:dev, :test]`, it depends only on `scrypath`; the root package `files:` allowlist keeps it out of the tarball — **Reversibility:** costly — ADR 0002; undoing means moving modules and touching the ops lock, CI path classifier and Docker COPY stages
- Exit rule (recorded in the plan and in the project README): fold the project into `scrypath_ops/catalog/` if no second consumer appears by Phase 197; module names stay stable so folding is a rename
- Three adopters only (Shopadelic, Logistify, Wikily); Clinicly and Chatly sets are Phase 198; nothing is copied from the six sibling brand repos (Scrypath-owned data in the adopters' shapes)
- Tracer bullet first: the Logistify builder through the fake client to a rendered posture with a deep queue and nothing failed, before any other builder exists
- The host's `phase173` fixtures and their `?scenario=` branches stay (four host e2e specs use them) with a recorded deletion trigger
- Findings F1 (task history truncated at 1,000), F2, D2 and the test hygiene items are handed to the maintainer, not fixed; no root `lib/` change; PR titles `docs`, `chore`, `test` or `ci`; never stage `.planning/config.json`, `.planning/state.json`, `.impeccable/config.json`
- Realism rules from prep note B section D4 (verified against Meilisearch docs and Scrypath source): no per-tenant drift, no "N minutes of lag", no per-document size limit, no out-of-order replay overwrite on the Oban path, no failure the library cannot produce

### Builder contract (prep note B D2, D6)
- Pure: no `DateTime.utc_now`, `Date.utc_today`, `:rand`, `System.*`, no Repo; every time is `now` minus an offset; one pinned preview epoch lives in one function
- Closed enums with raw wire shapes only (task `type` and `status` from the documented lists, Oban job states and the real worker modules `Scrypath.Oban.UpsertWorker` / `DeleteWorker` / `Sync.RelatedWorker`); unknown values raise `FunctionClauseError`; builders never construct `State` or `FailedWork`
- Defaults from Scrypath config and `Scrypath.Meilisearch.index_name/2`, not literals; the fake client honors `limit`, orders newest first and sets `next`
- Failure strings come from a closed table; each entry carries `source:` pointing at a real Meilisearch error code (from the once-recorded payloads) or a Scrypath path
- Hostile text is stored as escapes (bidi override, ZWJ emoji, NFC vs NFD, CJK, Arabic, a 511-byte id, an unbroken 200-character token, markup text); a lint test fails on raw format characters in fixture source
- Realistic ordinary data first; stress cases are separate named variations

### Verification shape
- `check_fixtures` is DB-free, runs first in the `test` alias of each consumer, and has a planted failing case; two renders with different `now` differ only in time-derived text
- Normalizer round trip: every scenario passes through `Scrypath.sync_status/2`, `failed_sync_work/2` and `Posture.summary/3` and returns `{:ok, _}` or a designed error tag; wire guard through `Scrypath.Meilisearch.TaskPayload.normalize/2`
- `package_metadata_test` asserts `fixtures/` never ships (already refuted for the tarball files list in Phase 195; extend to the new top-level directory); the CI path classifier and `package_contents_test` decisions for the new directory are made and recorded; add `fixtures/` to the namespace fence scope if it scans paths

### Decided autonomously
- [Plan split] Q: "How many plans?" → Selected: "Up to four per the roadmap estimate: (1) project, tracer bullet Logistify, fake client, check task, package refute; (2) recorded Meilisearch payloads and the closed failure table; (3) Shopadelic and Wikily; (4) hostile text, bulk generator digest, provenance labels, path classifier and package decisions" — plan boundaries are planning metadata and cheap to re-cut
- [Recording method] Q: "How are real payloads recorded?" → Selected: "A task-scoped Meilisearch Docker container run once, raw JSON committed as small files, container and image removed afterward per AGENTS.md" — the recording is a one-time artifact, easy to redo
- [Bulk generator] Q: "How is bulk data generated?" → Selected: "A tiny deterministic pick function over `:erlang.phash2` with a golden digest; no Faker or StreamData dependency" — copy over dependency, small and local
- [Ordinary data content] Q: "What are the adopters' ordinary records?" → Selected: "Plausible product, shipment and wiki-page records in each adopter's domain, labelled fictional" — data content is cheap to edit

### Claude's Discretion
- Module and file names under `ScrypathFixtures.*`, exact scenario ids, which Phase 173 posture scenarios migrate in this phase versus later, and where the recorded Meilisearch JSON lives

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ScrypathOps.Schemas.scrypath_opts/0` (app-env injection seam for `meilisearch_client`, `oban_inspector`, `meilisearch_tasks`, `oban_jobs`), `Scrypath.Operator.Status.fetch/3`, `ScrypathOps.Posture.summary/3` (already takes `now`)
- `scrypath_ops/test/support/phase173_fixture_source.ex` and the host copy (two drifting copies; the vocabulary of 16 posture scenarios to migrate or generalize later)
- `scrypath_ops/mix.exs` `scrypath_ops.check_nav_contract` is the precedent for a cheap first check in the `test` alias
- Phase 195 left `catalog/lib` in `elixirc_paths` for dev and test, and the root boundary test and `verify-dependency-boundaries.sh` lists that any new dev/test dependency must respect

### Established Patterns
- Root `files:` is an explicit allowlist; `ci.yml` already lists `fixtures/` in the ops-ui path classifier; the namespace fence checks new files under `scrypath_ops/test`
- Dependencies of dev/test-only path deps compile in prod unless excluded: check the production dependency graph (the Phase 195 boundary tests) after adding the path dependency

### Integration Points
- `scrypath_ops/mix.exs` deps and lock, the root dependency boundary tests, Docker COPY stages for `fixtures/`, the CI path classifier

</code_context>

<specifics>
## Specific Ideas

Primary references: [B-fixtures-and-adopters.md](../../research/catalog-prep/B-fixtures-and-adopters.md) (sections D1 to D7; where it differs from SYNTHESIS, which cuts the adopters to three and moves the spike first, SYNTHESIS and H win) and [GO-NO-GO.md](../195-mount-and-prove/GO-NO-GO.md) for what Phase 195 learned (a new path dependency touches the lock and the Docker stages; measure cold `ops-ui` impact).

</specifics>

<deferred>
## Deferred Ideas

- Clinicly (real denials only) and Chatly (reindex swap, CJK) sets: Phase 198
- Migrating all 16 Phase 173 posture scenarios and deleting the host copies: later, with the recorded deletion trigger
- Findings F1, F2, D2 and the dashboard_routes guard defect: handed to the maintainer

</deferred>
