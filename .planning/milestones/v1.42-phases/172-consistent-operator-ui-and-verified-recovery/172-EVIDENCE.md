---
phase: 172
status: delivered_completion_records_prepared
product_source: 1b2287ed598ef6e9025e95f2db1b727e70eeb17f
candidate_source: 135517b2aa7d1515a4be71c4f9d53aa8dd60c341
---

# Phase 172 evidence and delivery

## Source identities

| Identity | Source / receipt | Meaning |
| --- | --- | --- |
| Baseline |3c83a58c9bc5af70a204957431ff66fd9db035de|Before UI implementation; existing demo screenshot baseline.|
| Product source |1b2287ed598ef6e9025e95f2db1b727e70eeb17f|All product/root/UI fixes and measured browser acceptance.|
| Advisory correction |b454387abfde7db95f25d29706c2276cdedefafc|Only obsolete screenshot/depth assertions and deterministic capture setup changed.|
| First candidate |489f4e37c9aff06e693d1d70ca5611e5b513fbbb; run37177391476|FAILED overall: repository test still asserted retry1/on-first-retry. Full hosted browser and mounted/package/backend jobs passed; no successful attestation claimed.|
| Corrected candidate |135517b2aa7d1515a4be71c4f9d53aa8dd60c341; run37178388184|Hosted closeout PASSED; all five required jobs, coverage, full browser and attestation succeeded. Repository contract asserts zero retries, one worker and retain-on-failure.|
| PR |[#91](https://github.com/szTheory/scrypath/pull/91), PR CI37178390800|All five required jobs and scoped Ops passed; squash merged as 3ad154a33f99cb200b791577aadc5970adc70ca2 on 2026-10-04.|
| Delivered source |3ad154a33f99cb200b791577aadc5970adc70ca2|PR #91 squash merge. Release PR #92 delivered0.3.15 at8dd20e8966acd17a4ef5acec653c00dc31faab49. The final planning source is selected only after completion/archive records are committed.|

## Executed local acceptance

- Ops `mix verify.ops_ui` and `mix precommit`:233 tests+2doctests each,0failures. Logs `/private/tmp/phase172-08-{ops-ui,precommit}.log`.
- Root `mix verify.core --exclude integration --exclude docs_contract` at corrected135517b:4properties+657tests,0failures,85excluded;31.2s test runtime. Formatting, clean packaged paths, warning-enforced compile, Credo and docs completed. Log `/private/tmp/phase172-08-core-green.log`. The earlier run had one obsolete workflow assertion and exited2 despite its final descriptive PASSED line; test counts/exit code are authoritative.
- Workflow wiring:45tests0failures after the zero-retry correction (`phase172-ci-contract-green.log`).
- Named focused root/Ops/browser RED→GREEN cases are recorded in Plans04–07 summaries and REVIEW-DISPOSITION. Final product source is unchanged by the later test/tracking corrections.
- Local fresh broad advisory at1b2287e:95/104pass,9obsolete assertion failures,0retries/skips/flakes,283.0s. Corrected9/9pass atb454387; hosted full advisory subsequently passes at489f4e3. Never relabel the original failed run green.
- Static contrast:0AAfail/36AAAadvisories. Browser contrast:incident0AA/24AAA;all_green0AA/48AAA;empty0AA/0AAA. These are separate reports, not summed unique issues. Full40-shot matrix captured; light filename/width check20/20 is inventory, not pixel parity. Non-contrast axe has separate violations/incomplete attachments in the Playwright JSON. No paid judge ran.

## Direct image review

Parent inspected real image bytes using view_image. Baseline files `/private/tmp/scrypath-v142-review/` are source3c83a58. Current canonical captures reside in `examples/scrypath_ecommerce/test-results/docker-full/test-results/admin-screenshots/` at1b2287e. Additional narrow and long-content captures/axe attachments are under `/private/tmp/phase172-07-*-artifacts/` and `/private/tmp/phase172-07-final-images/`. These ignored/local artifacts supplement hosted artifacts; they are not promised as permanent remote URLs.

| Comparison | Finding / disposition | Limits / revisit trigger |
| --- | --- | --- |
| Control Room light1440 incident, before vs canonical00 | Three shortcut prompts reduce to one shell control; unsupported Federated badge removed; state and three job routes remain legible. Accept. | Dynamic timestamp differs. Revisit if another shortcut location/route duplicates the hint. |
| FailedSync light390 incident, before vs canonical02 | Six tall count cards become compact total+five reason chips; actual cause and Retry stay above Diagnostics; readable wrapping controls. Accept. | Same five failure classes, different job IDs/times. Revisit new reason taxonomy, row actions or overflow. |
| SyncDrift light390 before vs canonical03 plus dark390 | Ordinary sync/contract checks lead; advanced promotion is one disclosure; current status and next actions are clear, identifiers wrap. Accept hierarchy/reflow. | Baseline contract not loaded, canonical drift loaded; not identical-state pixel parity. State and dark/light contrast have executable checks. |
| Search light390 before vs current | Mode/selector/fields have explicit labels and body-sized controls; long schema namespace remains accessible. Accept. | Current radio branch has two allowed schemas; separate320px five-option fixture covers native select. |
| Playbooks light390/current + modal browser evidence | Workspace path wraps; actions are readable, file label associates to generated upload ID; modal errors stay in active dialog and successful rename/delete restores focus. Accept. | Keyboard/a11y claims come from tests, not image appearance alone. |
| Posture light390/current | Worst-first schema cards, errors/unavailable queues and schema-preserving action stay visible; long IDs wrap and target>=40px. Accept. | Aggregate history can remain degraded after one verified recovery; do not demand universal green. |

## Review and threat boundaries

Independent source review inspected39 files and resolved2HIGH+3MEDIUM findings (REVIEW/DISPOSITION). Parent inspected the final test-only corrections and preserved non-vacuous assertions. No human approval, classifier completeness or descriptor-based prohibition enforcement is claimed. SECURITY maps T-172-01–19/SC; SOURCE-AUDIT retains A-03/04/06/07/08 and descriptor-less fallback flags.

## Release decision

A patch release is warranted: root Hex package changes correct Meilisearch index-contract comparisons, cancelled/unknown/deletion task readiness and latest Oban error visibility. Ops/example polish alone would not justify a core release. Use the existing Release Please train after green PR delivery; do not hand-edit version or tag. Release Please PR #92 merged after all five required and scoped Ops checks passed in run37181241295. It published `scrypath-v0.3.15` at `8dd20e8966acd17a4ef5acec653c00dc31faab49`; [publish run37181522723](https://github.com/szTheory/scrypath/actions/runs/37181522723) passed package checks, dry run, publication, live Hex/HexDocs/consumer verification and tarball/tag parity. No manual version or tag was created.

## Cleanup / retained preview

The task-owned disposable projects are `scrypath_ecommerce_verify_focused_3fd8972c_77955` and `scrypath_ecommerce_verify_full_1b2287ed_97290`; artifacts collected before targeted removal. Final Docker inventory confirms both projects have no remaining containers; their owned volumes and networks were removed. Unrelated services were preserved. Preview `scrypath-ui-v142` at http://127.0.0.1:4012/admin/search was rebuilt without seeding/reset and returnsHTTP200. It is intentionally retained for optional design feedback.

Stop preview from `examples/scrypath_ecommerce`: `COMPOSE_PROJECT_NAME=scrypath-ui-v142 WEB_PORT=4012 docker compose -f compose.yaml -f compose.dev.yaml down` (no `--volumes`; preserve data). Original checkout `/Users/jon/projects/scrypath`, branch `gsd/v1.38-cleanup-merged`, and stash `preserved pre-operator-ui state2026-10-02` are unrelated and preserved. The UI worktree remains needed by the bind-mounted preview.

## Completion ordering

Candidate proof precedes completed requirements/phase/milestone records. Commit all summaries, verification, audit/archive and bookkeeping before choosing final source. Final canonical closeout then binds that exact SHA; later receipt stays in CI/PR/task output with no tracked post-attestation write. If final proof fails, make a new committed candidate and attest it; never relabel the failed SHA. No Phase170 replay.

## Candidate hosted receipt

Canonical dispatch selected new run [37178388184](https://github.com/szTheory/scrypath/actions/runs/37178388184), attempt 1, at exact candidate `135517b2aa7d1515a4be71c4f9d53aa8dd60c341`. The local watcher exited 1 after a GitHub annotation connection reset; the hosted run itself completed successfully. The existing read-only `collect-readiness` command exited 0 and independently validated the same run/attempt, all seven receipt jobs, artifact metadata, downloaded archive digest and its sole JSON member. This is transport recovery, not a relabeled command exit or repeated test run. Receipt: `/private/tmp/phase172-candidate-receipt.json`.

- Coverage artifact `11294785045`: `sha256:bf18018ca1d5c9a966035a2c4f52e5d37cb1116c4e1fb6b76d8a05c4f8e61d8d`.
- Attestation artifact `11294960000`: `sha256:6a8d6fe63e6dccf132048d604bc5f5db5f47e7daf9879eaabec06363d222d33d`.
- JSON member SHA-256: `cc7f19a0800d3035e21d4fe8870c29de817d5c6b1132c7c630e6e8c1ee3b03ba`. Artifacts expire 2026-10-11; these identities persist in this record.
- Hosted full advisory: **104 passed in 5.9 minutes**, mounted: **4 passed in 9.2 seconds**, zero retries configured; light capture inventory **20/20**, static contrast **0 AA failures**. Log: `/private/tmp/phase172-hosted-browser-proof2.log`. PR CI [37178390800](https://github.com/szTheory/scrypath/actions/runs/37178390800) supplies scoped Ops success at the same candidate SHA.

## Release and integration receipts

- Release candidate7caba7bd398a0c8dba0fd3141d9f708b7f1d2f64 passed canonical closeout37180335392 (exit0). Coverage artifact11294508709 digest `sha256:82644da07753e936006272160d77ee9a7c959ff2eac0482901308debff2f3b33`; attestation artifact11294468853 digest `sha256:f5461b7155fb1da374c03e00d441c6850abcccb0c3fdbc0a2d6bc0e025260a19`. Receipt `/private/tmp/phase172-release-candidate.log`.
- Bot-created PR92 initially had no attached checks. Close/reopen triggered the normal PR event; run37181241295 passed. Branch protection was not changed or bypassed.
- Typed integration checker: six named connections and five flows traced, zero broken/orphaned within that scope. The original dated report preserves publication/finalization as pending at its review cutoff; publication is now established by the run above. See172-INTEGRATION.md.
- Final receipt will be external to the final committed/archive source. This document deliberately does not preclaim a future run ID or successful final result.
