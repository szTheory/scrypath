
> Historical evidence checkpoint: the receipts below belong to frozen implementation `e37f5bde914d123f0bf7dcb9c12daec64d465657`. Worktree closeout `40551292192` at `8b34f5452e254d9aeda6bc2ed0394304bb5e91b6` passed required gates but exposed a default import-only cache observation defect after browser success. The subsequent producer-policy repair requires fresh acceptance; these receipts are not relabeled for the new source.

# Phase 182 cache acceptance

## Frozen source and authority

This acceptance is for implementation SHA `e37f5bde914d123f0bf7dcb9c12daec64d465657`, branch `worktree-agent-p182-08-1793071051075`, repository `szTheory/scrypath`, workflow event `workflow_dispatch`, session `phase182-08-e37f5bde-20261027T154542Z`, and trusted cache namespace `candidate-556416f7`. The six selected runs all use that SHA, branch, session, and namespace. The worktree was at the frozen SHA when these receipts were reviewed, with no non-planning diff from the candidate.

The machine authority is the append-only session at:

`/private/tmp/scrypath-phase182-acceptance/e37f5bde914d123f0bf7dcb9c12daec64d465657/phase182-08-e37f5bde-20261027T154542Z/collector-session/`

The session manifest SHA-256 is `92a50e6df2e99ed1598cecf387ae32c390a4125e4aeedb79d0c5d37324978a1d`. `cache-acceptance.json` SHA-256 is `d86b6d7a296704f30aea9901fd7c3d23633c15f9f46451dd906b30b9d9e72421`; it is eligible and lists all five cache modes. `full-acceptance.json` SHA-256 is `5f0dfab4fc52bf6fcde07df5a807acc4c34634d99a87ed94f6f150345e589b7e`; it is eligible and lists the separate full run. Raw manifest-listed receipts and downloaded archive bytes are authoritative; `acceptance-facts.cjs` is only a convenience reader.

Both aggregate validators were rerun against the session root (not a receipt or aggregate JSON file), with the exact identity and requested namespace:

```sh
XDG_CACHE_HOME=/private/tmp/scrypath-phase182-gh-cache \
BUILDX_CONFIG=/private/tmp/scrypath-phase182-buildx \
node scripts/ci/phase182_acceptance.cjs validate --mode caches \
  --repo szTheory/scrypath \
  --branch worktree-agent-p182-08-1793071051075 \
  --sha e37f5bde914d123f0bf7dcb9c12daec64d465657 \
  --session-id phase182-08-e37f5bde-20261027T154542Z \
  --probe-namespace candidate-556416f7 \
  --input /private/tmp/scrypath-phase182-acceptance/e37f5bde914d123f0bf7dcb9c12daec64d465657/phase182-08-e37f5bde-20261027T154542Z/collector-session

XDG_CACHE_HOME=/private/tmp/scrypath-phase182-gh-cache \
BUILDX_CONFIG=/private/tmp/scrypath-phase182-buildx \
node scripts/ci/phase182_acceptance.cjs validate --mode full \
  --repo szTheory/scrypath \
  --branch worktree-agent-p182-08-1793071051075 \
  --sha e37f5bde914d123f0bf7dcb9c12daec64d465657 \
  --session-id phase182-08-e37f5bde-20261027T154542Z \
  --probe-namespace candidate-556416f7 \
  --input /private/tmp/scrypath-phase182-acceptance/e37f5bde914d123f0bf7dcb9c12daec64d465657/phase182-08-e37f5bde-20261027T154542Z/collector-session
```

Both exited `0`, returned `valid: true`, `eligible: true`, and found six invocations. Each raw receipt SHA-256 and downloaded cache/browser archive SHA-256 was recomputed from the saved bytes and matched its manifest/receipt digest.

## Hosted mode results

| Mode | Run / attempt | Cache job / result | Receipt SHA-256 | Cache archive SHA-256 | Raw cache log SHA-256 |
|---|---|---|---|---|---|
| `docker-warm` | [40534189615](https://github.com/szTheory/scrypath/actions/runs/40534189615) / 1 | `ecommerce-e2e (advisory)` / 122294835949, success | `f497e12d9d5af1fe196adf389392ae7a4241306a0ff2035712e8076457087a6a` | `3fbd92a65a639e5a0a5241f27086cab45090ff044fb0a109266d1e5b037ca1cf` | `d2ba3cc313baf11317e8ec3845b8d9e2fd9689c3e21c71cd698cb161db9863ac` |
| `docker-cold` | [40536521371](https://github.com/szTheory/scrypath/actions/runs/40536521371) / 1 | `ecommerce-mounted (required)` / 122303168640, success | `e57eb192bc94b0dc3ca9b3303884dd32dfe8d78effaa4e298887dfc8b33b422e` | `bc99233837a63877f2d2585f0e13ac704618c5fd75bc5afdb29201bbc54ce501` | `a37095ce875a4b495ef20fb2848672f8aca52979fe6f67dec9fc6b60fe4523a7` |
| `beam-fallback` | [40538671636](https://github.com/szTheory/scrypath/actions/runs/40538671636) / 1 | `core (required)` / 122310780810, success | `54bfd4b05d56b3c4d9ba465b510d45748034fcba884879afd6ad8c8f807268a2` | `2bfacecdda26e128a406ef361da3079753126a361d3d8e5d19661d1dccf56acf` | `ac3ce1bed6194a5545763b318488f9f0486dffed6bde8d6bc741d75c8da4680b` |
| `beam-lock-change` | [40540687164](https://github.com/szTheory/scrypath/actions/runs/40540687164) / 1 | `core (required)` / 122317939508, success | `2371db50e1ff1d1a4b61519a0e907890c5029a78f21effad4038e1e0940a51b5` | `3e944ac4e07dfe30ced70cdb84de17a9e358530a79a5cc46d7c4b85b12dba69a` | `ff6ba044f1a5c826e438307170b575a68eced90d1eaec0436e2a12ac6bd0c93d` |
| `beam-cold` | [40543183784](https://github.com/szTheory/scrypath/actions/runs/40543183784) / 1 | `core (required)` / 122326727689, success | `770bd144ad677862695fb46ace9adc2fdf103ba83e729c8642060549d862e8fd` | `0440021af3737e4f3c76b8784356f336ca6125fe0572cb53848eb94da2b599ee` | `d407c444aecf9dea6dae4587d8c30090a538538ca3466ac59ad3990c97ab3773` |

Each of these five workflows also contains a successful, exact-source full `ecommerce-e2e (advisory)` browser proof; those browser receipts and archive digests are recorded in [182-ACCEPTANCE.md](./182-ACCEPTANCE.md). All five required jobs, the coverage job, and the run's `closeout-attestation` completed successfully in the selected runs. The cache collector selected only attempt 1 for every accepted mode.

### Docker BuildKit warm and cold

The warm full-scope Compose/Bake plan resolved three targets and three stable, namespace-bounded cache scopes:

| Target | Scope | Recipe ID | Built image ID | Import | Cached work | Export |
|---|---|---|---|---|---|---|
| `browser` | `scrypath-ecommerce-browser-v1-phase182-candidate-556416f7` | `sha256:2631878451eecd4439035da289b3ce22e195773bbf462b2f7a4afd0bc9b50495` | `sha256:b450876169ea85a3ac85965ef24aba68d574605c51a6b5a7a1ccb29ea3b917ec` | vertex 13 `DONE` | vertices 17–19 | vertex 38 `DONE` |
| `web` | `scrypath-ecommerce-app-v1-phase182-candidate-556416f7` | `sha256:d011d45df70c6bdd18253cdd203025967ef2c5cd51352b50f7b860ecfe70ad85` | `sha256:57d697094d5253b8a25dc37879439f0050e4493d7f4aad2794389027b41a40e3` | vertex 16 `DONE` | vertices 20–25 | vertex 42 `DONE` |
| `standalone_ops` | `scrypath-ecommerce-standalone-ops-v1-phase182-candidate-556416f7` | `sha256:d011d45df70c6bdd18253cdd203025967ef2c5cd51352b50f7b860ecfe70ad85` | `sha256:57d697094d5253b8a25dc37879439f0050e4493d7f4aad2794389027b41a40e3` | vertex 15 `DONE` | vertices 20–25 shared from `web` | vertex 39 `DONE` |

`web` and `standalone_ops` have the same resolved recipe ID and image ID, so BuildKit deduplicated their application recipe. The receipt attributes the shared cached vertices to that matching recipe while keeping each target's import and completed export separate. `browser` has a different recipe/image and its hit is recorded independently. This is actual target-bound progress, not a generic cache headline or a hit borrowed from an unrelated recipe. Warm mode records `scope: full`, `imports_enabled: true`, actual import and export `true`, all three imported and exported scopes, and a successful normal full command.

Cold mode ran the ordinary mounted command in `ecommerce-mounted (required)` against a fresh `docker-container` builder `scrypath-mounted-40536521371-1`, created for run 40536521371 attempt 1. The builder was nonpersistent, had `cache_from: []`, and the recorded baseline names were `default`. The resolved mounted scope was `focused`, with targets `browser` and `web`; imports, actual imports, exports, and cache progress were all empty/false. The ordinary mounted verification succeeded. The same workflow still ran the full browser job successfully, so focused cold-cache scoping did not weaken or skip full proof.

### BEAM restore and invalidation

All three BEAM receipts use the same compatibility identity: schema `beam-v1`, graph `root`, runner image `ubuntu24/20261023.334.3`, Linux/X64, Elixir `1.19.0`, OTP `28` (`erts-16.1.1`), `MIX_ENV=test`, `MIX_TARGET=host`, profile `root-test`, manifests digest `98b7f18c837f9cd074d6e8259e213db1e57169cceb846554ff563755a731560c`, and source digest `cd0f5e7c06e97a7e2ec8ef19efee72e262ae57dda943484aa2a019350d0e64d6`. The recorded tuple hash is `f6a384c918c11a7d0c07c998c05022e22c904d86f70fc008305415868ef969d2`. Restore keys are bounded by `phase182-candidate-556416f7`; the restore prefix is `beam-v1-downloads-f6a384c918c11a7d0c07c998c05022e22c904d86f70fc008305415868ef969d2-phase182-candidate-556416f7-`.

| Mode | Lock digest / behavior | Download restore evidence | Compiled-cache evidence | Normal commands |
|---|---|---|---|---|
| `beam-fallback` | Locks digest `587a10b3d8453f1a611b097ce54a532b362a625f6d28a3ab56ff4cc40028d5a6`; same source digest as the common tuple | Run-specific primary key was `beam-v1-downloads-f6a384c918c11a7d0c07c998c05022e22c904d86f70fc008305415868ef969d2-phase182-candidate-556416f7-587a10b3d8453f1a611b097ce54a532b362a625f6d28a3ab56ff4cc40028d5a6-phase182-40538671636-1`; exact restore matched the candidate namespace prefix. `downloads_hit=false`, `downloads_restored=true` | Resolved key used the same lock/source digests and run suffix; no resolved restore key, primary hit, or compiled hit. `fallback=true` | `deps.get`, compile, verify, and primary verification all `success` |
| `beam-lock-change` | Current locks digest `b234711300128b0e0757dc6e4f89e6ca40314bbcd6672be3ec72581544841fd5`; the isolated comment-only lock edit changed recorded lock bytes from `bd30554574b9b902df5e28f027db4dfc04afcb7a7fd8c93b757391e5337d20f8` to `8cc8e49ac8245c2e82577e4a70c24cf4284cc176a9719f38b2c14575f5969a71` | Run-specific key used the new digest and run 40540687164 attempt 1. A compatible download restore matched `beam-v1-downloads-f6a384c918c11a7d0c07c998c05022e22c904d86f70fc008305415868ef969d2-phase182-candidate-556416f7-587a10b3d8453f1a611b097ce54a532b362a625f6d28a3ab56ff4cc40028d5a6-phase182-40538671636-1`; downloads restored, without claiming an exact-key hit | Resolved key used the changed digest and run suffix; no resolved restore key, primary hit, or compiled hit. `fallback=true` | `deps.get`, compile, verify, and primary verification all `success` |
| `beam-cold` | Locks digest `587a10b3d8453f1a611b097ce54a532b362a625f6d28a3ab56ff4cc40028d5a6` | `imports_enabled=false`; no matched restore key and `downloads_restored=false` | No resolved restore key, primary hit, or compiled hit; `fallback=false` | `deps.get`, compile, verify, and primary verification all `success` |

For the lock-change run the exact current run-specific resolved key was `beam-v1-resolved-f6a384c918c11a7d0c07c998c05022e22c904d86f70fc008305415868ef969d2-b234711300128b0e0757dc6e4f89e6ca40314bbcd6672be3ec72581544841fd5-phase182-candidate-556416f7-cd0f5e7c06e97a7e2ec8ef19efee72e262ae57dda943484aa2a019350d0e64d6-phase182-40540687164-1`. The saved proof ZIP contains the complete per-run identity and all exact cache keys; the table distinguishes a successful compatible dependency restore from a strict compiled-cache miss.

## Seed and attempt history

Run [40530439125](https://github.com/szTheory/scrypath/actions/runs/40530439125), at earlier source `556416f7d5f267f86986d7fe38088ec7abe281f2`, populated `candidate-556416f7`. Its normal workflow succeeded and the saved `/private/tmp/scrypath-phase182-execution/556-seed-facts.json` confirms exports for all three Docker targets. Its collector could not read the run logs because whole-run ZIP transport failed, so it is a cache producer only and contributes no current-source acceptance. Stable cache scopes may cross source revisions; each e37 consumer receipt binds its own recipe, image, source, and cache identity.

Earlier history remains preserved and ineligible where recorded as such:

- Candidate `96c23e654e3e81a37012480a9fc743bdc51b8ea5` seed runs 40475352935 and 40477088849 succeeded. Warm 40478542266 hosted successfully but local collection failed on the GH HOME-cache write; warm 40480441673 hosted successfully but was rejected by the then-current cache parser. These do not replace the e37 receipts.
- The first `docker-cold` collection for b8 run 40513785292 was ineligible while Actions job metadata lagged. Its later success is not by itself proof that the readiness repair works.
- c0 full run 40527848072 and seed/full run 40530439125 had successful hosted steps, but collectors failed on whole-run ZIP log transport (`HTTP2CANCEL`; a later HTTP/1 log read ended `unexpectedEOF`). They remain ineligible as acceptance receipts. The 556 run is used only as the cache producer described above.
- Earlier local full attempts recorded under `/private/tmp/scrypath-phase182-local-e2e-failures` stopped at 77/189 or had incomplete browser execution with the shorter fallback deadline. No clean-stability claim is made across that history.

The root's `/private/tmp/scrypath-phase182-execution/acceptance-attempt-history.json` records a canonical-session subset, not every older directory. The full preserved history remains under `/private/tmp/scrypath-phase182-acceptance/` and `/private/tmp/scrypath-phase182-local-e2e-failures/`.

## Requirement results and limits

- **CACHE-01:** Accepted by real warm import/useful-step/export evidence for all three current recipe targets and a separate fresh-builder mounted run with imports disabled and the normal mounted command successful.
- **CACHE-02:** Accepted by real compatible dependency restore fallback, comment-only lock-byte change with a compiled-cache miss, and a representative no-import cold run where the normal Mix commands succeeded.
- Cache evidence does not claim every cache hit is useful or every hosted run has stable timing; only the exact target-bound progress and normal command outcomes above are asserted.
- The inherited deep-quality dependency audit debt remains deferred to Phase 184. These receipts do not claim that every advisory CI job is green.
- No paid visual judge, retry masking, skipped browser cases, shared-cache deletion, baseline rewrite, required-lane change, retained-preview mutation, or simulated reviewer approval contributed to acceptance. Existing descriptor-less/unclassified planning assumptions remain as recorded in phase context; this infrastructure proof adds no human UAT gate.

