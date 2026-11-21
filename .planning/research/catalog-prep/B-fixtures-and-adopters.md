# B. Fixtures and adopters architecture (v1.49 prep, 2026-11-21)

Tags: V = read or run this session, J = judgment, U = unverified or recalled. Research note, not a plan. Toolchain unchanged.

## What the code already gives us (V)

- **The injection seam is real and runtime-only.** `ScrypathOps.Schemas.scrypath_opts/0` reads app env (`schemas.ex:36-43`) for `meilisearch_client`, `oban_inspector`, `meilisearch_tasks`, `oban_jobs`. `Scrypath.Operator.Status.fetch/3` turns raw Meilisearch task maps and raw Oban job maps into `State` structs (`status.ex:56-90`, `state.ex:46-100`). `ScrypathOps.Posture.summary/3` already takes `now` (`posture.ex:55-58`). So a fixture only has to emit **wire shapes** (raw task and job maps); the real normalizers do the rest.
- **Two drifting copies**: `scrypath_ops/test/support/phase173_fixture_source.ex` (396 lines) and `examples/scrypath_ecommerce/test/support/...` (379). They differ mainly in schema modules (the host copy uses `Catalog.Product`). Both are wired by `config/test.exs`, and `PostureLive` reads `Application.fetch_env!(:scrypath_ops, :phase173_fixture_source)` from `:phase173_fixture` branches (`posture_live.ex:16-45,167-183`). Host and ops routes mount them under `Mix.env() == :test` only. The ops copy's e2e specs (`ops_reskin_contract.spec.ts:67-68`, `ui_iteration3.spec.ts:129`) use `?scenario=`; do not delete the branches in Phase 195.
- **Existing fixtures contain unreachable states.** Job maps use worker `ScrypathOps.Phase173FixtureWorker` and queues `default`/`scrypath_sync`; real jobs use `Scrypath.Oban.UpsertWorker`/`DeleteWorker`/`Sync.RelatedWorker` (`translation.ex:84-86`). The `backend-failed` task carries an invented message ("Document is missing its id field."); the real one echoes the document (below). Oban times are strings with `-04:00`; real Oban gives UTC `DateTime`, Meilisearch gives `...Z` strings.
- **Packaging.** Root `files:` is an explicit allowlist (`mix.exs:321-322`); a top-level `fixtures/` cannot ship. ADR 0002 says `mix verify.package` asserts this, but `test/release/package_metadata_test.exs:127-134` has no `refute "fixtures"`. The directory does not exist yet. `ci.yml:440` already lists `fixtures/` in the ops-ui path classifier.
- **Precedent for a cheap first check**: `scrypath_ops/mix.exs:87-92` runs `scrypath_ops.check_nav_contract` before `ecto.create` in the `test` alias. Every `mix test` there needs Postgres.

## D1. Fixture project shape

**Recommend: ADR 0002 as written, in lean form** (confidence 0.6). `fixtures/scrypath_fixtures`, one dependency (`{:scrypath, path: "../.."}`), no lockfile of its own, named `ScrypathFixtures.*`. Only `scrypath_ops` takes it, `only: [:dev, :test]`. The demo host does **not** depend on it in v1.49.

- Why: Mix skips `only:`-restricted deps of a non-top-level dep (J), so the host and its three Dockerfile `COPY mix.exs` stages (`Dockerfile:16-18,58-60,96-98`) stay untouched. The fixtures cannot reference `ScrypathOps.*` (no cycle, compile-time layering). The seam stays "wire shapes in, real code out".
- Rejected: **module in `scrypath_ops` via `elixirc_paths`** (simpler, but the host cannot reuse it, and ops compiled as a dep skips its own dev/test paths, which is exactly ADR 0002's reason); **per-test fixtures** (the status quo, drifts, nothing for Storybook to render).
- Revisit trigger: if Phase 197 ends with no consumer beyond `scrypath_ops`, fold the directory into `scrypath_ops/catalog/` in one plan; keep module names stable so it is a rename. If Phase 195 spends more than one plan on project plumbing, take that exit early.
- Migration: move the 16 posture scenarios of the ops copy into `ScrypathFixtures` as one "state vocabulary" scenario set; leave the host copy until its e2e specs are ported. `PostureLive`'s branches should be generalized, not deleted (see Cross-area).
- Add `refute "fixtures" in package_files` in Phase 195 (one line, makes ADR 0002 true). Add `fixtures/` to the namespace fence scope if it scans paths (CI-EFFICIENCY item 9; U).

## D2. Scenario-builder contract

```
ScrypathFixtures.Scenarios.get(id, now: dt) -> %Scenario{
  id, adopter, job_ids, role_ids, now,
  allowlist, scrypath_opts,      # opts name fake client/inspector modules + raw lists
  documents, applied_settings    # what the fake index "contains"
}
```

- **Pure.** No `DateTime.utc_now`, `Date.utc_today`, `:rand`, `System.*`, no Repo. Every time is `now - offset`. One pinned preview epoch lives in one function. A grep-test enforces this (threadline's retention bug: a fixed demo epoch aged out under a wall-clock cutoff; accrue: seeded `utc_now` made screenshots differ).
- **Closed enums, raw shapes only.** `Meili.task(type, status, opts)` with `type` from the documented list and `status in [:enqueued, :processing, :succeeded, :failed, :canceled]` (V docs); failed tasks take `error` from a closed table `{code, type, message_template}`. `Oban.job(worker: :upsert | :delete | :related, state: ~w(available scheduled executing retryable completed discarded cancelled))` fills real keys (`id, state, queue, worker, args{schema,backend,index,document_ids,operation}, attempt, max_attempts, errors[%{"at","attempt","error"}], attempted_at, scheduled_at, completed_at`; V `translation.ex`). Unknown enum values hit a `FunctionClauseError`. Builders never construct `State`/`FailedWork`; only the real code does, so only reachable states exist.
- **Defaults from Scrypath.** Queue and `max_attempts` (8, `upsert_worker.ex:5`) come from `Scrypath.Config` defaults, not literals. Index names come from `Scrypath.Meilisearch.index_name/2` (`prefix_` plus underscored last module segment; `naming.ex`).
- **Fake client must behave like Meilisearch.** `tasks/2` honors `limit`, returns newest first, sets `next`. The existing fake ignores `limit`. Real code errors with `{:task_history_truncated, ...}` once more than 1,000 tasks match (`tasks.ex:72-84`, default limit line 9); this is not hypothetical for a busy index (see Logistify).
- **Folding.** Tests run every scenario through `Scrypath.sync_status/2`, `failed_sync_work/2`, `reconcile_sync/2`, `index_contract_drift/2` and (ops side) `Posture.summary/3`, and assert either `{:ok, _}` or the designed error tag. Plus a **wire guard**: every task map passes `Scrypath.Meilisearch.TaskPayload.normalize/2`.
- **Record real payloads once.** In Phase 195, run task-scoped Meilisearch in Docker once, trigger `invalid_document_id`, `missing_document_id`, `index_not_found`, a processing task and an `indexSwap`, commit the raw JSON (small), and require builders to match key sets and value types. This replaces docs paraphrase with evidence; clean up the container per AGENTS.md. Confidence 0.75 that it is worth one plan task.

## D3. Adopters for the first slice

Scrypath indexes **per schema, not per tenant** (V `naming.ex`; ops has one global `index_prefix`). Tenants are only filter fields, visible on the Search screen. Scrypath's "drift" is settings-contract drift plus `drift_signals` from pending/failed/reindex state (V `reconcile.ex:208-216`, `index_contract_drift.ex:36-60`); it has no document-count comparison, no tenant dimension, no lag/age (State only reads `finishedAt`/`completed_at`).

**Recommend five (confidence 0.7); defer two.** Names stay, each labeled "fictional"; chrome stays Scrypath's (no adopter fonts or colors in slice 1, which sidesteps Space Grotesk and the Bricolage/Hanken overlap).

| Adopter | Ordinary story, then the unique state | Jobs / roles | Screens | Blind spot it should expose |
|---|---|---|---|---|
| Wikily (Scrypath-owned) | Empty install: `:unconfigured`, `:missing_backend`, no tasks, `index_not_found` | JOB-01/02, ROLE-INT | control room, health, help | first-run copy and next-checks |
| Logistify | Healthy shipments index (`LGX-...` ids, DE/FR text), then a deep queue with 0 failed: Oban `available/executing` jobs, Meili `enqueued` tasks | JOB-02/03, ROLE-OPS | control room, health, sync | depth shown but no age/lag; **task history over 1,000 renders the truncated-history error as the ordinary busy state** (V `posture_live.ex:659`); neutral vs alarming |
| Clinicly | Failed upserts: `validation`-class, a `missing_document_id` task whose message echoes the record, a `cancelled` invalid-job; a retry blocked by stale sudo or impersonation | JOB-03, ROLE-OPS | health, failed sync | **raw backend error text can contain record fields and the UI prints `error.message`** (V `translation.ex:backend_reason`); this is the pilot's denial |
| Chatly | `x__reindex` target, `indexSwap` pending then succeeded, cutover states; CJK, Arabic, emoji messages in Search | JOB-04/05, ROLE-OWNER | sync and index, search | reindex visibility and non-Latin rendering |
| Shopadelic | Settings drift: schema declares `storeId` filterable, applied settings lack it; Search filtered by store fails | JOB-04/05, ROLE-OWNER | sync and index, search | the one real drift concept; a failed filter on the Search screen |

Deferred: **Classwell** (backend unreachable is already the `unavailable`/`refresh-failure` vocabulary; add self-hosted wording as a variation of Wikily or Logistify later) and **Finanza** (delete failure is one `operation: :delete` discarded row, add it to Clinicly or Logistify as a variation; the adopter itself adds only a font problem). Every adopter must own live state or be pruned (UI engine D3).

## D4. Realism truth-check (V docs and source unless marked)

Meilisearch facts: statuses `enqueued, processing, succeeded, failed, canceled`; list response `results,total,limit,from,next`; document additions are **atomic**, one bad id fails the whole task (`primary_key` docs); `invalid_document_id` and `missing_document_id` are type `invalid_request` (maps to `:validation`, `translation.ex:classify_backend_error`); ids allow alphanumerics, `-`, `_`; 511-byte primary key cap; default payload limit 100 MB, no per-document size cap; `indexSwap` is atomic, swaps documents, settings, tasks, returns `indexUid: null` (docs: error list at meilisearch.com/docs/reference/errors/error_codes, /reference/api/tasks, /reference/api/indexes/swap-indexes, /learn/resources/known_limitations, /learn/getting_started/primary_key). Scrypath: upsert jobs **load the current record** and delete ids that no longer load (`upsert_worker.ex:43-65`, PR #108); chunks of 1,000 ids (`chunks.ex`); retry re-queues ids, never the old data.

| Proposed failure | Verdict |
|---|---|
| Classwell "1,140 rows rejected, school code `AH 2026/7B` invalid id" | Truthful as `invalid_document_id`, but **reword to chunks**: the whole task (up to 1,000 ids) fails, not 1,140 rows |
| Chatly/Shopadelic "1,900 documents over a 100 KB limit" / "document too large" | **Impossible** (no per-document cap). Only `payload_too_large` on a whole request near 100 MB. Drop |
| Shopadelic "140 prices serialized as strings rejected" | **Impossible** at indexing (schemaless); shows up as wrong sorting, not a failed task. Drop from ops stories |
| Logistify "replay lets an old In transit overwrite a newer Failed"; Clinicly "delayed Scheduled overwrites newer Canceled"; Chatly out-of-order replay; Shopadelic reordered stock | **Impossible on the Oban path** (current record loaded at run time). Reachable only via jobs queued before 0.3.16 (`legacy_snapshot`, `upsert_worker.ex:66-86`), or an app passing a stale struct to inline sync. Not an ordinary story |
| "11 minutes of lag", "38 minutes behind" | Depth is real, **lag is not shown**; reword to counts. Candidate product gap, not a fixture |
| "Drift in one store only", "48,206 in DB vs 47,950 indexed" | Not displayable: no tenant or count comparison. Reword as settings drift (Shopadelic) |
| Deleted store/message/learner still matching | Reachable: `DeleteWorker` job `discarded` after 8 attempts, or a hard delete that bypassed Scrypath. Keep as a delete-operation failed row |
| Meilisearch down 7 minutes exhausts 6,800 jobs | Reachable: transport errors, `retryable` then `discarded` (`queue_exhausted` class); wording from real exception text (`Req.TransportError`) |
| Reindex misses 1,900 updates; alias switch missing 3% | Reindex states (`__reindex`, `indexSwap`) are real; "missing documents" is not observable. Show cutover only |
| Clinicly "operator may not read failed work" | **No such capability exists.** Real denials: stale sudo redirect, impersonation flash, six gated actions (`gating.ex:8-16`). Use those; PHI-echo is a finding to raise |
| `no_space_left_on_device` | Real code, type not `invalid_request` so classifies `:unknown` (U on exact type) |

Unverified: exact `invalid_search_filter` wording for a non-filterable attribute (U), whether `indexSwap` appears under both indexes' `indexUids` filter (U), real Oban `cancelled` attempt counts (U). Recorded payloads (D2) settle the first two.

## D5. Hostile text, empties, bulk

- **Ordinary first, stress named** (accrue footgun 1). One `Hostile` module of about 12 strings written only as escapes (for example the text backslash-u-202E inside quotes, never the character itself): bidi override and isolates, ZWJ family emoji, ZWSP, NFC vs NFD (precomposed vs base letter plus combining acute), CJK, Arabic, a 511-byte id, 200-char unbroken token, `<script>` text. A lint test fails on any raw `U+200B-200F, 202A-202E, 2066-2069, FEFF` in fixture source (Trojan Source class; J).
- `nil` = missing, `[]` = known empty, `""` = empty string; one designed example per adopter at most.
- **Bulk generator**: no Faker, no StreamData, no `:rand`. `pick(list, seed, n, tag) = Enum.at(list, :erlang.phash2({seed, n, tag}, length(list)))` (`phash2` is documented portable), about 20 lines, lazily streamed; the fake client pages it. One golden `sha256(:erlang.term_to_binary(sample, [:deterministic]))` per generator, updated deliberately. Cap bulk near 5,000 entries; counts beyond are labels.

## D6. Invariants and the cheapest first check

`mix scrypath_ops.check_fixtures` (like `check_nav_contract`; no DB, under 2 s, first in the `test` alias and runnable alone) builds every scenario at the preview epoch and asserts: closed enums; `enqueued <= started <= finished <= now`; `attempted_at <= completed_at`, retryable `attempt < max_attempts` with `scheduled_at > attempted_at`, discarded `attempt == max_attempts`; every job `args.index` equals `index_name/2`; every task `indexUid` is in the allowlist's names or its `__reindex` partner (or `nil` for `indexSwap`); every `document_ids` entry is in `documents` or a marked delete; ids unique and match `^[A-Za-z0-9_-]{1,511}$` unless the scenario is the designed rejection; no `utc_now`/`:rand` tokens; no raw format chars; digest unchanged. Then the normalizer round trip (D2), then render-all.

## D7. Licensing-safe authoring

Scrypath-owned data in the adopters' shapes; each adopter module doc says "Fictional adopter, shape inspired by `szTheory/<name>-brand` @ <sha>; no records copied" and uses different ids of the same shape (not canon `LGX-0417-DE`). Tests: every adopter title and story label contains "(fictional)"; a denylist (`HIPAA`, `GDPR`, `PCI`, `SOX`, `compliant`, `certified`) fails in fixtures and stories (Clinicly and Finanza are design rules, never compliance claims; use "personal data"). The reuse grant stays open and unblocking; if the maintainer adds CC BY 4.0, nothing here changes except provenance lines.

## Adversarial pass

- **Too heavy for a thin start** (likely). Early warning: more than one plan before any adopter reaches `Posture.summary`. Cheapest test: a tracer bullet, Logistify through the fake client to a rendered posture, before any other builder exists.
- **Fake drifts from Meilisearch.** Mitigated by recorded payloads and the `TaskPayload` guard; breaks if Meilisearch changes shapes (revisit at a server bump).
- **Truncated-history as "ordinary Logistify"** may be a product bug, not a story. That is a finding to hand the maintainer, not to hide in a fixture.
- **Path-dep cost** (cold compile, a third place for `deps.get`). If measured above about 60 s of cold CI time, take the D1 exit.

## Cross-area flags

- **Storybook/render (other agents):** the real LiveViews read global app env, so two iframes showing different scenarios race. Scenario switching needs a per-session override (the `scrypath_ops_opts` session key already exists, `on_mount.ex:15-20`), guarded to dev/test; that generalizes the `:phase173_fixture` branch. `ScrypathOps.Clock` is test-only for a fixed clock (`clock.ex:5-16`), so dev Storybook needs its own `now` seam.
- **Verification:** the new Mix task and the `refute "fixtures"` line add no required gate; fixture invariants run under the existing `core`/`ops-ui` lanes.
- **Phase shape:** Phase 195 fits 4-5 plans: (1) project, wire builders, fake client, check task, package refute; (2) recorded Meilisearch payloads plus Wikily, Logistify, Clinicly; (3) Chatly, Shopadelic; (4) migrate the 16 posture scenarios and port ops tests; (5) truth table, provenance labels, bulk digest.
