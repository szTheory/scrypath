# Phase 166 — Exact-source evidence

## Candidate and hosted receipts

Implementation candidate: `50d5c12d36ec560525e245bcb992c40e5927854f` (committed; exact SHA in all three receipts).

The exact-SHA workflow dispatch was [run 36321613553](https://github.com/szTheory/scrypath/actions/runs/36321613553), attempt 1, at that SHA. The advisory `phoenix-example` job [108626420623](https://github.com/szTheory/scrypath/actions/runs/36321613553/job/108626420623) concluded success at 2026-09-27 13:14:40 UTC. The required `backend` job [108626420717](https://github.com/szTheory/scrypath/actions/runs/36321613553/job/108626420717) concluded success at 13:13:13 UTC. Both jobs ran at the same source SHA. Hosted runtime was Elixir 1.19.0 / OTP 28.1. The Phoenix workflow service images are `postgres:16-alpine` and `getmeili/meilisearch:v1.15`; the local tuple used the same image tags and Meilisearch reported package version 1.15.2.

The repository closeout protocol also confirmed the five required jobs, coverage, and `closeout-attestation` at this SHA. Coverage artifact `10931758825` has digest `sha256:1c58c41b3d4458e81e407575f5ceb674eef8faa3975e8ca1790d530a36defabd`; closeout artifact `10932638177` has digest `sha256:df7a338660709c8acd9d11365a7f69dc95a74549b34b52ccbc4c71c71f60a132`. The JSON preserves both artifact IDs, digests, and expiration times.

| Receipt | Local execution | Hosted result and oracle |
|---|---|---|
| `host-path` — `mix verify.phoenix_example` | 16 tests, 0 failures; scenario 491 ms; index `phx_tenant_328_post`; setup tasks 172/173, write tasks 174/175/176; permitted and hydrated A ID `51`, B ID `53`. | 16 tests, 0 failures; scenario 505 ms; index `phx_tenant_121603_post`; setup tasks 14/15, write tasks 16/17/18. Tenant A raw and hydrated ID `6`, 1 hit, category/facet bucket `phone-a:1`. Tenant B raw and hydrated ID `8`, 1 hit, bucket `phone-b-forbidden:1`; unique marker is also ID `8`. |
| `host-package` — `mix verify.phoenix_example --package` | Fresh `mix hex.build --unpack` artifact tagged `v0.3.13`; staged consumer resolved the local artifact at Git revision `206b9abe64732d80e99c9fe8b128ca27a453cb4c`. Resolved staged lock SHA-256 `eb1f10ec522ec3d79f9e78ef625103840ac11c3e81582fd63db6d0eda3523991`. Consumer compiled and all 16 tests passed; scenario 487 ms; tenant A ID `81`, B ID `83`. | Same named scenario in the same advisory job: artifact creation/tag, staged dependency resolution, consumer compile, and integration completion all passed. 16 tests, 0 failures; scenario 515 ms; index `phx_tenant_4995_post`; setup tasks 34/35, write tasks 36/37/38. Tenant A raw/hydrated ID `16`, one `phone-a` category/facet value; tenant B raw/hydrated ID `18`, one `phone-b-forbidden` category/facet value and marker ID `18`. This is local-artifact consumption, not a Hex publication claim. |
| `root-repair` — `mix verify.backend` | Backend wrapper passed. The live operator module ran 4 tests with 0 failures; repair scenario 643 ms; selected ID `166000020`; first/repeat successful task UIDs 229/230 on `scrypath-op-198_queryable_post`; final raw projection matched; no-write observation was 3 reads and 0 mutations. | Backend job success; live operator module ran 4 tests with 0 failures. Scenario 432 ms; selected ID `166000040`; first/repeat successful task UIDs 31/32 on `scrypath-op-5154_queryable_post`; final raw ID/projection matched. Controls were source-only ID `166000041` and visible ID `166000042`; report-only observation was 3 reads and 0 mutations. |

The hosted Phoenix job's sanitized selected-line excerpt is stored in the JSON with SHA-256 `1a75b02280ad5e1dc8806d9f33ccb671f8ab20ddcda0bdfdde28c206024e6600`; the backend excerpt digest is `6b0945f9947460efa66ea186c92d77d0b9a62beab161c67383a0a7a2c88aa9a8`. The job links above identify the original log segments. Root uses the SQLite `IntegrationRepo` fixture with real Meilisearch; it does not use the host example's Postgres database.

The local lock digests are: root `mix.lock` `d46dde70f5b5433a53c9456d86b18ea6225f178ec6d5bd35cfb4ccdd45e4bf10`; Phoenix path `mix.lock` `3bd129e6b7128a34dae48c5ca3691f71a0166cb41a7d09919765d9c4487095d6`; package staged consumer lock `eb1f10ec522ec3d79f9e78ef625103840ac11c3e81582fd63db6d0eda3523991`. Hosted job runtime and job identity are recorded separately from these local lock measurements.

### Sanitized hosted scenario excerpts

```text
SCRYPATH_PHASE166_HOST {"index":"phx_tenant_121603_post","elapsed_ms":505,"scenario":"authorized tenant search and facet values","setup_task_ids":[14,15],"write_task_ids":[16,17,18],"tenant_a_permitted_ids":["6"],"tenant_a_total_hits":1,"tenant_a_categories":[["phone-a",1]],"tenant_a_facet_values":[["phone-a",1]],"tenant_b_permitted_ids":["8"],"tenant_b_total_hits":1,"tenant_b_categories":[["phone-b-forbidden",1]],"tenant_b_facet_values":[["phone-b-forbidden",1]],"tenant_b_marker_ids":["8"]}
PASS package proof: artifact created and tagged v0.3.13
PASS package proof: staged dependencies resolve to file:///tmp/scrypath-phoenix-package-1/artifact at v0.3.13
PASS package proof: consumer compiled
SCRYPATH_PHASE166_HOST {"index":"phx_tenant_4995_post","elapsed_ms":515,"scenario":"authorized tenant search and facet values","setup_task_ids":[34,35],"write_task_ids":[36,37,38],"tenant_a_permitted_ids":["16"],"tenant_a_total_hits":1,"tenant_a_categories":[["phone-a",1]],"tenant_a_facet_values":[["phone-a",1]],"tenant_b_permitted_ids":["18"],"tenant_b_total_hits":1,"tenant_b_categories":[["phone-b-forbidden",1]],"tenant_b_facet_values":[["phone-b-forbidden",1]],"tenant_b_marker_ids":["18"]}
PASS package proof: integration scenarios completed
SCRYPATH_PHASE166_REPAIR {"index":"scrypath-op-5154_queryable_post","selected_ids":[166000040],"first_task":{"state":"succeeded","uid":31},"repeat_task":{"state":"succeeded","uid":32},"scenario":"bounded manual repair restores the selected raw document","raw_target":{"id":166000040,"projection":{"body":"target projection for phase166repair3","id":166000040,"title":"Phase 166 phase166repair3 target"}},"controls":{"source_only_id":166000041,"visible_id":166000042},"no_write_observation":{"read_requests":3,"mutation_requests":0},"elapsed_ms":432}
```

### Package fixture deviation

Adding `tenant_id` to the Phoenix demo projection made Meilisearch's implicit primary-key inference ambiguous in four existing demo smoke fixtures. The fixture correction now creates each test index with primary key `id` explicitly. It changes test setup only; both path and package modes pass. This execution fix is committed at the candidate SHA.

## C-09 historical deletion receipt freshness

The inherited historical receipt is unchanged: source `dc400b2b57aec0ca6b0ef16c9477d266fd41a433`; run `36257182675`; advisory job `108446076619`; artifact `10910932671`; artifact digest `sha256:7ee2a3ada62293f7c1ded409b426d0b739329fd863bbe6996d1986e5926ee49e`; report SHA-256 `e53352b3e15a70b861118041024ecf4b60f11eb2627ad0ddcbd76afc143439bf`. The named scenario, “deleted products leave the visible search index,” passed on retry 0 in 1,222 ms. These artifact facts are inherited from `.planning/research/v1.40/C09-DELETE-VISIBILITY.md`; the artifact was not downloaded again for Phase 166.

**Disposition: reusable for the bounded claim below.** The exact two-tree comparison was receipt SHA → assessment source `50d5c12d36ec560525e245bcb992c40e5927854f`, over `lib`, `examples`, `config`, `test/support`, `.github/workflows`, `mix.exs`, and `mix.lock`. It found 16 changed paths, all listed in `166-EVIDENCE.json`; every path has a semantic reason and none invalidates this receipt. There are no changed ecommerce host, deletion, Oban worker, search endpoint, workflow, configuration, or dependency-lock paths.

The shared-library changes were checked against the actual oracle. The storefront deletion scenario calls `Scrypath.search(Product, ..., filter: [tenant_id: tenant_id])`, and its `/search-visible` endpoint maps `result.hits` from ordinary `/search`. The new common-filter renderer is used only by the `/facet-search` client operation; `Query.to_payload/1` for ordinary search is unchanged. The new `tenant_scope` option filtering applies to the separate facet/multi/single query builders and the ecommerce scenario does not pass that option. The host membership work and explicit-index fixtures are confined to `examples/phoenix_meilisearch`; they do not feed or alter `examples/scrypath_ecommerce`.

The bounded reusable claim is: **In the source-backed ecommerce Phoenix/Ecto example, a previously searchable hard-deleted product is absent from raw tenant-scoped search hits after the explicit host delete and controlled persisted Oban work drain, while its sibling remains visible.** The decisive signal is raw `result.hits` after known presence, plus the surviving sibling. The historical test uses a unique fixture name; it does not separately read the source row back or correlate the delete task UID.

The preserved scenario sequence is: seed and drain prior indexing work → require the unique target name to be present in the same tenant-scoped query → call the host deletion endpoint (`Repo.delete` plus explicit `Scrypath.delete_record`) → drain the persisted queue → poll raw hits until the target is absent → render the storefront and require the sibling to remain visible. An empty error response or missing hydrated database row is not the oracle.

This claim does not prove package-backed deletion, inline/manual deletion, atomic source-delete/job-enqueue behavior, duplicate delivery idempotency, concurrency or recreation ordering, retries, restart recovery, production scheduler latency, soft deletes, arbitrary host policies, or all host applications. In particular, the receipt proves one successful delete, not delete-already-absent or concurrent delivery behavior.

This comparison covers `assessment_source_sha`, not a future final tracking commit. After committing evidence and tracking files, rerun the relevant-path comparison against the exact final phase SHA as part of final-source closeout. Do not edit tracked files solely to record that external result. Phase 167 must repeat freshness analysis at its own final assessment source; this is not a readiness decision.

## Claim boundaries

- HOST evidence is the named synthetic persisted-membership policy and deterministic tenant corpus in the Phoenix demo.
- PKG evidence is a fresh local artifact consumption proof only; it says nothing about Hex publication or installation from the public registry.
- REPAIR evidence covers explicit selected-ID manual repair, a fixed-source repeat, and an empty-scope no-op. It does not establish broad boundary semantics, concurrency, retries, or exactly-once behavior.
- The Phase 166 records preserve observations and limits; they do not decide milestone readiness or promote an advisory CI job.
