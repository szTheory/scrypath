---
phase: "179"
slug: "bounded-id-lists-and-related-sync-parity"
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: "2026-10-25"
---

# Phase 179 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Caller → `Scrypath` sync/backfill/reindex | Host app passes id lists and records of arbitrary size | Record ids, documents (adopter data) |
| Scrypath → database / Meilisearch | Bounded loads and backend writes | Ids, documents, task handles |
| `oban_jobs` table → Scrypath workers | Persisted job args are decoded back into module names, ids and opts; rows can be edited or crafted by anyone with DB write access | Untrusted strings naming modules, repos, apps, fan-outs; id lists |
| Tenant-scoped owner schemas → related resolvers | Default loader vs owner-defined `search_records/2` | Tenant-scoped trigger records |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-179-01 | Denial of Service | `Scrypath.Sync`, `Loader.load/3` | medium | mitigate | `Scrypath.Chunks` `@max_ids 1000` used by sync, loader, backfill, enqueue, workers, related enqueue; tests assert `<= 1000` per call | closed |
| T-179-02 | Repudiation | combined multi-chunk result | medium | mitigate | `Chunks.reduce_ok/2` / `each_ok/2` halt on first `{:error, _}`; multi-chunk result built fresh (179-01) | closed |
| T-179-03 | Information Disclosure | failed-chunk error tuples | low | mitigate | Bare `{:error, reason}` returned, no id lists (`sync.ex`) | closed |
| T-179-04 | Denial of Service | `Backfill.write/5` payload size | medium | mitigate | Pages written in `Enum.chunk_every(Chunks.max_ids())` chunks regardless of `:batch_size` | closed |
| T-179-05 | Tampering | reindex cutover after partial ingestion | high | mitigate | `maybe_wait_for_batch_tasks/2` waits on every `tasks` entry and halts before cutover; test asserts no swap after a failed chunk | closed |
| T-179-06 | Denial of Service | job args size in `oban_jobs` | medium | mitigate | One job per ≤1000-id chunk (`enqueue.ex`); tests assert per-changeset bound | closed |
| T-179-07 | Tampering | partially enqueued multi-chunk work | medium | mitigate | `Oban.Repo.transaction/2` + `rollback/2` (`enqueue.ex:121-124`); SQLite real-Oban test asserts zero jobs after a failed insert | closed |
| T-179-08 | Denial of Service | duplicate job amplification | low | mitigate | Shared `Enqueue.unique_opts/0` + sorted chunk ids | closed |
| T-179-09 | Denial of Service | atom table via crafted job args | high | mitigate | No `String.to_atom`/`binary_to_atom`/`Module.concat` in `lib/scrypath/oban` or `lib/scrypath/sync`; names resolved only via `String.to_existing_atom` inside `rescue` (full `"Elixir."` name since CR-01 fix 858e83dc); fixed opts allowlist; atom-count tests | closed |
| T-179-10 | Elevation of Privilege | `"schema"`/`"backend"`/`"repo"` naming arbitrary modules | high | mitigate | `resolve_existing_module/3`: exact spelling, `Code.ensure_loaded?`, role callbacks via `function_exported?` before any call; loaded-but-wrong module tests | closed |
| T-179-11 | Denial of Service | retry storms on undecodable jobs | medium | mitigate | Workers return `{:cancel, {:invalid_job, tag}}`; WR-02 fix (4d74ed9d) also cancels non-id `document_ids` elements | closed |
| T-179-12 | Tampering | silent repo fallback on edited `"repo"` | medium | mitigate | `{:unknown_repo, name}` → cancel (`job_args.ex:133,204`) | closed |
| T-179-13 | Elevation of Privilege | related-job schema/fan_out/opts modules | high | mitigate | `JobArgs.decode_related/1`: role checks, fan-out must be configured on the schema (`fetch_fan_out/2`), allowlisted opts; FAN-03 matrix test | closed |
| T-179-14 | Denial of Service | retry storms from all-missing triggers / bad args | medium | mitigate | All-missing returns `:ok` without calling the resolver; bad args cancel (`related_worker.ex`) | closed |
| T-179-15 | Information Disclosure | default loader on tenant-scoped trigger schemas | medium | mitigate | `Loader.ensure_loadable!/2` at enqueue (`related_enqueue.ex:20`); guide directs tenant-scoped owners to `search_records/2`; ecommerce `Category` defines it | closed |
| T-179-16 | Denial of Service | duplicate related jobs | low | mitigate | `unique: Enqueue.unique_opts()` in `related_enqueue.ex:46`; real-Oban collapse test | closed |
| T-179-17 | Information Disclosure | tenant-scoped resolver/loader guidance | medium | mitigate | `guides/related-data-and-reindexing.md` §(c) (lines ~184-239) tells tenant-scoped owners to define `search_records/2` | closed |
| T-179-18 | Repudiation | manual-mode success read from `task:` alone | low | mitigate | `guides/sync-modes-and-visibility.md:150` and `lib/scrypath.ex:437` say to check every `tasks:` entry | closed |
| T-179-19 | Information Disclosure | `Category.search_records/2` cross-tenant load | low | accept | See accepted risks | closed |
| T-179-SC | Tampering | dependency installs | low | accept | See accepted risks; no `mix.lock` changes in `1d3399c1..HEAD` | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-179-01 | T-179-19 | Example-only: loads exactly the category ids the job carries (from the caller's own records); bypass is explicit via `skip_tenant_id: true`; downstream resolver scopes products by `category_id` and `tenant_id` | Plan-time disposition (179-07-PLAN threat model) | 2026-10-25 |
| AR-179-02 | T-179-SC | No package installed or upgraded in this phase (RESEARCH package audit: none; no lockfile diff) | Plan-time disposition (179-01..07-PLAN threat models) | 2026-10-25 |

*Accepted risks do not resurface in future audit runs.*

---

## Notes (non-blocking, from code review)

- WR-01 (open): above 1000 ids the enqueue transaction's `rollback` inside a caller's own transaction aborts the outer transaction. This is a correctness/ergonomics issue; T-179-07's integrity property (all-or-nothing chunk enqueue) still holds.
- CR-01 (fixed 858e83dc) was an availability defect in T-179-09/10's resolution path, not an atom-safety regression: the old per-segment lookup failed closed (cancelled every job in a release) rather than creating atoms.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-25 | 20 | 20 | 0 | /gsd-secure-phase orchestrator (ASVS L1 grep-depth; auditor short-circuited: register authored at plan time, 0 open) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-10-25 (automated L1 evidence check; no human sign-off recorded)
