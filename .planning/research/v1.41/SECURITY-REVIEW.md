# v1.41 security scope review

**Reviewed:** 2026-09-28, 16:46 UTC. **Method:** read-only repository, upstream advisory/release, and public-main inspection; no dependency resolution, tests, CI dispatch, or delivery actions. Local HEAD: `20ba2f3b1e42e8c4e90c97d794e124b5c4fff080`. Confidence is high for source/version observations; compatibility remains unexecuted.

## Decision

Expand the focused Mint correction to **all four tracked Mix graphs**, targeting **Mint 1.11.0 or a later release verified against refreshed advisories**, including necessary HPAX changes. The existing Phoenix-only, 1.10.1 recommendation is stale. Preserve the historical v1.40 assessment. No public API, operator UI work, broad upgrade, or new CI job follows from this finding.

This is completeness of the evidenced security maintenance scope: the same vulnerable transport exists in four maintained graphs. Updating dependencies in `scrypath_ops` does not reopen UI product scope. The requirement wording must explicitly acknowledge the additional graphs before implementation.

## Confirmed advisory change

The three previously researched records are correct, but incomplete as of this review:

| Advisory | Severity | Affected range | Fixed |
|---|---|---|---|
| [CVE-2026-82728](https://github.com/elixir-mint/mint/security/advisories/GHSA-g83f-2j6r-q6m4) | High | `>=0.1.0 <1.10.0` | 1.10.0 |
| [CVE-2026-82729](https://github.com/elixir-mint/mint/security/advisories/GHSA-7p8w-j234-7qc8) | Medium | `>=1.9.3 <1.10.0` | 1.10.0 |
| [CVE-2026-82672](https://github.com/elixir-mint/mint/security/advisories/GHSA-rj5m-69wp-cxq9) | Medium | `<=1.10.0` | 1.10.1 |
| [CVE-2026-91043](https://github.com/elixir-mint/mint/security/advisories/GHSA-9x8p-qrf4-jq7g) | High | `>=1.1.0 <1.11.0` | 1.11.0 |
| [CVE-2026-92103](https://github.com/elixir-mint/mint/security/advisories/GHSA-q95c-ccq6-j5j6) | Medium | `>=0.1.0 <1.11.0` | 1.11.0 |
| [CVE-2026-94194](https://github.com/elixir-mint/mint/security/advisories/GHSA-gvrc-75rc-7gj9) | Medium | `<1.11.0` | 1.11.0 |

**Observation:** Mint's maintainers published the last three on September 28 at approximately 11:14 UTC. They concern decoded HTTP/2 header memory, premature HTTP/2 frame buffering, and HTTP/1 transfer-coding framing. The [1.11.0 release record](https://hex.pm/api/packages/mint/releases/1.11.0) confirms publication at 09:58 UTC, no retirement, Elixir `~> 1.15`, and HPAX `~> 1.1`. Its [tagged changelog](https://github.com/elixir-mint/mint/blob/v1.11.0/CHANGELOG.md) declares no breaking changes but includes additional parser/error fixes. Therefore compilation and existing transport consumers still need verification.

These records prove affected versions, not exploitation of a particular Scrypath deployment. Malicious-server/protocol/intermediary prerequisites remain claim limits.

## Actual graph boundaries

| Graph | Tracked Mint / HPAX | Source evidence |
|---|---|---|
| Root | 1.10.1 / 1.1.0 | `mix.lock:26`, `mix.lock:20` |
| Phoenix consumer | 1.9.3 / 1.0.4 | `examples/phoenix_meilisearch/mix.lock:12`, `:9` |
| Ecommerce consumer | 1.9.3 / 1.0.4 | `examples/scrypath_ecommerce/mix.lock:23`, `:18` |
| Standalone Ops app | 1.9.3 / 1.0.4 | `scrypath_ops/mix.lock:31`, `:26` |

Every graph locks Finch 0.23.0 with Mint `~> 1.8`, which admits 1.11.0. Every consumer HPAX 1.0.4 must move into Mint's new `~> 1.1` requirement. Both Mint and [HPAX 1.1.0](https://hex.pm/api/packages/hpax/releases/1.1.0) accept Elixir `~> 1.15`, below Scrypath's 1.17 floor. This establishes declared compatibility, not a solver or runtime pass.

Root Req is mandatory (`mix.exs:112`); Oban is optional (`:111`). Req → Finch → Mint remains present without Oban. Ecommerce and Ops also directly declare Req (`examples/scrypath_ecommerce/mix.exs:52`, `scrypath_ops/mix.exs:59`). Removing optional integrations would not clear Mint.

The [official library guidance](https://elixir.hexdocs.pm/library-guidelines.html) says host projects ignore a dependency's lockfile. Root lock remediation fixes contributor/CI resolution; it neither fixes existing adopters' locks nor creates a published minimum. Calling root `mix.lock` the “published-library dependency graph” in `STACK.md:13` and `ARCHITECTURE.md:13` is misleading. Ecommerce's path dependency on Ops also does not substitute for updating the standalone Ops lock.

## Proof gaps and cheapest adequate evidence

**Root audit does not audit consumers.** `lib/mix/tasks/verify/capability.ex:67–72,119–126` runs `hex.audit` in the current root directory, followed by Dialyzer. Run a separate, direct `mix hex.audit` in each of the four projects; repeating the entire deep-quality task four times adds unrelated work. Record time, source SHA, lock identity, Hex version, exit result, and any findings/ignores. [Hex documentation](https://hex.hexdocs.pm/Mix.Tasks.Hex.Audit.html) confirms ignored advisories can yield success, so a bare zero exit is insufficient evidence. No tracked ignore configuration was found in these manifests/workflows.

**Phoenix uses the consumer lock, but preservation is unproven.** Path mode runs `deps.get` then tests inside the example (`lib/mix/tasks/verify.adopter.ex:74–90`). Package mode explicitly copies `mix.lock`, replaces only Scrypath's dependency, resolves again, and checks only the Scrypath Git URL/tag (`lib/mix/tasks/verify/phoenix_example/package.ex:5,79–97,123–164`). It deletes successful temporary workspaces (`:39–42`). Neither mode asserts that Mint/HPAX or the other Hex entries remained unchanged. Its fake runner even replaces the staged lock with only a Scrypath entry and still passes (`test/mix/tasks/verify_phoenix_example_package_test.exs:97–105`). This is an evidence gap, not evidence of an actual downgrade.

The smallest durable correction is to compare staged Hex entries with the source consumer lock after resolution, allowing the intended Scrypath provenance entry, and emit the resolved Mint/HPAX identity before cleanup. Add focused in-process cases for preserved and changed entries in the existing harness test. This guards future package proofs without service cost or a hardcoded forever-safe Mint version. Path verification can check the source lock before/after; `deps.get --check-locked` is available in [Mix 1.19](https://github.com/elixir-lang/elixir/blob/v1.19.0/lib/mix/lib/mix/tasks/deps.get.ex).

| Graph | Existing behavior proof to reuse once on the candidate |
|---|---|
| Root | Required core/package/backend jobs; backend exercises real transport. |
| Phoenix | Both `mix verify.phoenix_example` modes, with graph identity evidence. |
| Ecommerce | Existing required `mix verify.ecommerce_mounted`; no additional full E2E sweep. |
| Ops | Existing `mix verify.ops_ui`, Postgres tests without Meilisearch or visual review (`CONTRIBUTING.md:135`). |

The Docker build copies and resolves root, Ops, and ecommerce locks separately (`examples/scrypath_ecommerce/Dockerfile:18–30`). Mounted ecommerce proves its host graph; it does not replace standalone Ops tests. Existing CI already runs Phoenix's two modes in one advisory job (`.github/workflows/ci.yml:152–178`). Ops runs for matching PR changes, including either root or Ops lock, and every main push; it is **skipped on workflow_dispatch and schedules** (`:180–195`). Therefore a green closeout dispatch is insufficient Ops evidence: use its candidate PR run and post-merge main run. Read the actual advisory job outcomes; the five required gates alone do not prove MINT-02.

No upstream exploit recreation, new matrix, or recurring browser suite is justified by the observed changes.

### Economical recurring audit

**Recommend auditing all four maintained graphs inside the existing advisory deep-quality lane.** One-time commands establish this candidate's result but leave the demonstrated graph omission in place. The existing daily schedule (`.github/workflows/ci.yml:8–9`) also catches advisories published without repository changes. Keep the current required/advisory topology.

[Hex 2.5.1 source](https://github.com/hexpm/hex/blob/v2.5.1/lib/mix/tasks/hex.audit.ex) reads the lock and fetches registry metadata; it explicitly disables compilation and Mix listeners and does not start the consumer application. It needs no Postgres, Meilisearch, or browser. However, its dependency-loadpaths call still checks dependency availability: [Mix 1.19 source](https://github.com/elixir-lang/elixir/blob/v1.19.0/lib/mix/lib/mix/tasks/deps.loadpaths.ex) aborts for missing/invalid dependencies. Fresh CI may therefore need dependency fetching for each project. Budget that network/cache cost; do not describe it as an offline lock parser or add compilation/service startup for auditing.

Use one explicit maintained-graph inventory covering these four paths, with a cheap check for missing entries or newly tracked project locks needing disposition. Avoid recursive discovery in `deps`, `_build`, or temporary consumers. Run audits before unrelated expensive checks, attempt every graph before aggregating failure, label each result, preserve locks, and expose missing graphs, fetch failures, and ignores instead of counting them as clean. Meaningful recurring test value is graph coverage and failure propagation, not asserting a fixed Mint version indefinitely.

Keep this repository inventory/orchestration out of the published package surface: `mix.exs:270–271` ships all `lib` (including current verification tasks), while examples, Ops, and scripts are excluded. A helper placed under `lib` would ship by default. Repository-wide auditing must not imply that adopters possess these directories. This is a bounded prevention outcome for MINT-02, with measured incremental runtime during implementation, not a new security framework.

## Options and recommendation

| Option | Concrete scope | Tradeoff |
|---|---|---|
| **Target all affected graphs — recommended** | Mint 1.11.0+ in four locks; necessary HPAX updates in three consumers; bounded proof identity correction | Closes the known repository finding without changing public dependency policy. Reuses existing checks. |
| Phoenix-only correction plus explicit residuals | Update Phoenix; inventory root/ecommerce/Ops as unresolved | Smallest immediate patch, but leaves known High findings. Condition 2 stays FAIL absent an explicit owner acceptance; current MINT-01 rejects waiver as a substitute. Poor fit for readiness follow-through. |
| Enforce a library minimum | Add a direct constraint such as `{:mint, "~> 1.11"}` plus lock updates | Constrains future downstream resolutions, but changes package metadata, creates release/compatibility responsibility, and still requires host lock updates. No observed adopter requirement establishes this broader promise. Defer. |

[Mix 1.19 `deps.update`](https://github.com/elixir-lang/elixir/blob/v1.19.0/lib/mix/lib/mix/tasks/deps.update.ex) updates the named dependency and its children. `mix deps.update mint` is bounded; inspect the resulting diff and retain only justified subtree changes. The necessary HPAX update is not blanket churn. No observed constraint requires unrelated Req/Finch/Phoenix upgrades.

## Requirements and sequencing corrections

- **MINT-01:** Name all four graphs; require Mint 1.11.0+ verified against refreshed primary advisories, necessary compatible subtree changes, and no advisory-ignore substitute. Replace the outdated root exclusion and 1.10.1 recommendation throughout current v1.41 research.
- **MINT-02:** Require graph-specific audits, actual post-resolution identity in both Phoenix modes, and the existing root/ecommerce/Ops proof appropriate to changed graphs. Carry maintained-graph audit coverage into the existing advisory lane with explicit inventory and failure visibility. Preserve downstream and published-package limits.
- Rename Phase 168 to **Mint Dependency Remediation**. Its proposed dependency on archived Phase 167 (`ROADMAP.md:35`) does not establish a publicly delivered source baseline.

**Observed delivery boundary:** the live [main commit API](https://api.github.com/repos/szTheory/scrypath/commits/main) returned `40c9978c975dbfb42db75511f44ff0369c8d7d88`. Comparison with local HEAD showed identical four locks/manifests, CI, and package harness, but unpublished tenant/facet runtime changes plus Phoenix membership/repair fixtures and tests. A main-based Mint PR is feasible independently; its proof covers public-main scenarios. A local package labeled 0.3.13 (`mix.exs:4`, package harness `:55–56`) is not the published Hex 0.3.13 artifact.

Move source-base inventory/PR-slice selection ahead of Phase 168 acceptance, without waiting for all dependency PR triage. If expanded v1.40 workflows are acceptance claims, reconcile their source first or explicitly retain local-only evidence and verify their eventual integrated SHA. After integration, reuse unchanged evidence only with a relevant-source comparison. The historical cutoff remains untouched; new High findings prevent a fresh READY claim until resolved or explicitly accepted under the gate.
