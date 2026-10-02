# Phase 168 Plan 02 — Dependency Graph and Behavior Evidence

## Source identity

| Field | Value |
|---|---|
| Fresh public `main` base | `ad73b92d5883b4136fa961e134c987a95939fac2` |
| Security branch | `fix/phase168-dependency-security` |
| Candidate source commit | `d4976944e8049699f31dc6769cd68d719bc4a814` |
| Candidate status | Clean source worktree after commit; branch was created at the freshly fetched public `main` SHA above. |
| Toolchain | Elixir 1.19.5 / OTP 28; task-local `HEX_HOME` and Docker resources. |

The source branch is an isolated clone. The original checkout and its unrelated working changes were not used for dependency resolution or behavior proof. The four maintained graph changes are committed together at the candidate SHA. Existing adopter lockfiles are not changed by this repository correction.

## Advisory and release refresh (2026-09-28)

The Hex package release API was checked directly for Mint 1.11.0 and HPAX 1.1.0. An OSV Hex querybatch was built from every Mint release version currently listed by the Hex package API; it returned 18 OSV record IDs representing 14 distinct Mint EEF CVEs, with four GHSA records aliasing earlier CVEs. The full canonical CVE inventory and the Hex-patched release reported by OSV are below. A query against Mint 1.10.1 returned the three current 1.11.0 findings; a query against 1.11.0 returned zero records.

| CVE / OSV record | GitHub advisory | First Hex version marked fixed |
|---|---|---:|
| [EEF-CVE-2026-48861](https://osv.dev/vulnerability/EEF-CVE-2026-48861) | [GHSA-2pg6-44cx-c49v](https://github.com/elixir-mint/mint/security/advisories/GHSA-2pg6-44cx-c49v) | 1.9.0 |
| [EEF-CVE-2026-48862](https://osv.dev/vulnerability/EEF-CVE-2026-48862) | [GHSA-g586-ccqf-7x4r](https://github.com/elixir-mint/mint/security/advisories/GHSA-g586-ccqf-7x4r) | 1.9.0 |
| [EEF-CVE-2026-49753](https://osv.dev/vulnerability/EEF-CVE-2026-49753) | [GHSA-mjqx-c6f6-7rc2](https://github.com/elixir-mint/mint/security/advisories/GHSA-mjqx-c6f6-7rc2) | 1.9.0 |
| [EEF-CVE-2026-49754](https://osv.dev/vulnerability/EEF-CVE-2026-49754) | [GHSA-2p26-p43x-fhp8](https://github.com/elixir-mint/mint/security/advisories/GHSA-2p26-p43x-fhp8) | 1.9.0 |
| [EEF-CVE-2026-56810](https://osv.dev/vulnerability/EEF-CVE-2026-56810) | [GHSA-c59h-fq4p-r36r](https://github.com/elixir-mint/mint/security/advisories/GHSA-c59h-fq4p-r36r) | 1.9.1 |
| [EEF-CVE-2026-58229](https://osv.dev/vulnerability/EEF-CVE-2026-58229) | [GHSA-qrfr-wh4c-3qhw](https://github.com/elixir-mint/mint/security/advisories/GHSA-qrfr-wh4c-3qhw) | 1.9.2 |
| [EEF-CVE-2026-59246](https://osv.dev/vulnerability/EEF-CVE-2026-59246) | [GHSA-8pf6-g464-h6h9](https://github.com/elixir-mint/mint/security/advisories/GHSA-8pf6-g464-h6h9) | 1.9.2 |
| [EEF-CVE-2026-59249](https://osv.dev/vulnerability/EEF-CVE-2026-59249) | [GHSA-x3x7-96vm-6h2w](https://github.com/elixir-mint/mint/security/advisories/GHSA-x3x7-96vm-6h2w) | 1.9.3 |
| [EEF-CVE-2026-82672](https://osv.dev/vulnerability/EEF-CVE-2026-82672) | [GHSA-rj5m-69wp-cxq9](https://github.com/elixir-mint/mint/security/advisories/GHSA-rj5m-69wp-cxq9) | 1.10.1 |
| [EEF-CVE-2026-82728](https://osv.dev/vulnerability/EEF-CVE-2026-82728) | [GHSA-g83f-2j6r-q6m4](https://github.com/elixir-mint/mint/security/advisories/GHSA-g83f-2j6r-q6m4) | 1.10.0 |
| [EEF-CVE-2026-82729](https://osv.dev/vulnerability/EEF-CVE-2026-82729) | [GHSA-7p8w-j234-7qc8](https://github.com/elixir-mint/mint/security/advisories/GHSA-7p8w-j234-7qc8) | 1.10.0 |
| [EEF-CVE-2026-91043](https://osv.dev/vulnerability/EEF-CVE-2026-91043) | [GHSA-9x8p-qrf4-jq7g](https://github.com/elixir-mint/mint/security/advisories/GHSA-9x8p-qrf4-jq7g) | 1.11.0 |
| [EEF-CVE-2026-92103](https://osv.dev/vulnerability/EEF-CVE-2026-92103) | [GHSA-q95c-ccq6-j5j6](https://github.com/elixir-mint/mint/security/advisories/GHSA-q95c-ccq6-j5j6) | 1.11.0 |
| [EEF-CVE-2026-94194](https://osv.dev/vulnerability/EEF-CVE-2026-94194) | [GHSA-gvrc-75rc-7gj9](https://github.com/elixir-mint/mint/security/advisories/GHSA-gvrc-75rc-7gj9) | 1.11.0 |

The Mint release metadata declares Elixir `~> 1.15`, required HPAX `~> 1.1`, and optional Castore `~> 0.1.0 or ~> 1.0`. HPAX 1.1.0 declares Elixir `~> 1.15` and has no dependencies. Hex release checksums are Mint `c6279ba2d6aa3a383a1d4cfbe7b59f42e6efd400f58d8e2acfeac48a438693ab` and HPAX `0b8d0f05832f55571d65ac720f79bf8994138ffbb133209dc4685eae0ad456a8`; the committed lock tuples also retain their archive checksums. The researched publish timestamps are Mint 1.11.0 on 2026-09-28 and HPAX 1.1.0 on 2026-09-24.

Sources: [Hex Mint release API](https://hex.pm/api/packages/mint/releases/1.11.0), [Hex HPAX release API](https://hex.pm/api/packages/hpax/releases/1.1.0), [Hex Mint package API](https://hex.pm/api/packages/mint), and the OSV advisories linked in the table. The complete inventory refresh corrects the narrower research-time six-advisory excerpt; the selected 1.11.0 target is fixed across the refreshed set.

## Resolver result and bounded amendment

| Graph | Prior Mint / HPAX | Candidate Mint / HPAX | Other selected change |
|---|---|---|---|
| Root | 1.10.1 / 1.1.0 | 1.11.0 / 1.1.0 | None |
| Phoenix consumer | 1.9.3 / 1.0.4 | 1.11.0 / 1.1.0 | None |
| Mounted ecommerce | 1.9.3 / 1.0.4 | 1.11.0 / 1.1.0 | None |
| Standalone Ops | 1.9.3 / 1.0.4 | 1.11.0 / 1.1.0 | Optional Sigra 1.20.0 → 1.5.0 |

The root lock required only Mint because HPAX was already compatible. Each consumer lock changed Mint and the HPAX closure required by Mint 1.11.0. The Ops lock changed those same two entries plus Sigra. No other locked version changed.

Ops' first `mix hex.audit` reported its pre-existing optional Sigra 1.20.0 release as retired, with Hex's retirement message directing consumers to `~> 1.5.0`. The official [Sigra 1.5.0 release metadata](https://hex.pm/api/packages/sigra/releases/1.5.0) confirms availability and declares Elixir `~> 1.18`; Sigra 1.20.0 already carried that Elixir declaration, so the targeted correction does not newly raise the existing Ops graph's declared runtime floor. Following the explicit Plan 02 execution-time amendment, `scrypath_ops/mix.exs` now constrains only this existing optional dependency to `~> 1.5.0`. No other manifest changed.

Resolver observations: direct `mix deps.update mint` is the approved operation in all four projects. For transitive Mint entries, Mix generated the compatible closure and then returned `Unknown dependency mint for environment dev`; the documented `mix deps.unlock mint` plus `mix deps.get` completed resolution. In Ops, the first `mix deps.update sigra` also upgraded seven unrelated packages. That broad lock output was discarded; the targeted resolver was rerun and the final Ops lock contains only Mint, HPAX, and Sigra changes. The exact logs are under the disposable task workspace and were inspected before it is removed.

## Committed lock and manifest identities

| File | SHA-256 at candidate |
|---|---|
| `mix.lock` | `eddb9ca9c92557f5a550ff66f3b8f4ce3eb1a1ffc6e1d162654e9b5cc3d90490` |
| `examples/phoenix_meilisearch/mix.lock` | `881a93c36747f2e19c29df42a0b59a47ec913110fc75c8b7c028a72d90d0549f` |
| `examples/scrypath_ecommerce/mix.lock` | `43a70fb193388d38c289742eeea5ed8f49095f29983323d7eca90df9dc80a56f` |
| `scrypath_ops/mix.lock` | `4bd2507848088624a4286167248a93d944e83629404cfea39cb9a91ac33e1485` |
| `scrypath_ops/mix.exs` | `fd02e2f672dfd707b1b82df384b92af09ceadf9ae44be9a175378cd125236e94` |

## Four-graph fetch and audit

On the committed source, each project ran `mix deps.get --check-locked` followed by `mix hex.audit`; all four completed successfully in a single measured warm-cache pass of 8 seconds. Each resolver reported the dependencies already fetched/up to date, each audit printed `No retired packages found`, and all five selected file hashes above remained unchanged. There were no ignored, unavailable, incomplete, or affected results. Per-project resolver output was preserved in the task log; the combined record is `/private/tmp/scrypath-phase168-task2/graphs-fetch-audit.log` until disposable workspace cleanup.

## Behavior proof on candidate `d4976944e8049699f31dc6769cd68d719bc4a814`

| Capability | Result | Measured evidence and bounds |
|---|---|---|
| Root suite: `mix test --exclude integration --exclude docs_contract` | PASS | 574 tests, 0 failures; ExUnit runtime 26.3 s. |
| Live backend: `mix verify.backend` | PASS | Seven integration tests, 0 failures, across the four live backend groups; Meilisearch v1.15 task-owned container on port 17700. Container stopped after proof. |
| Mounted ecommerce: `mix verify.ecommerce_mounted` | PASS | Four Playwright checks passed in 4.1 s: harness discovery, navigation surfaces, failed-sync triage, and zero-downtime swap. The existing verifier removed its task-owned containers, volume, and network. |
| Standalone Ops: `mix verify.ops_ui` | PASS | 2 doctests and 154 tests, 0 failures; measured command duration 5 s on the clean rerun against task-owned PostgreSQL 16 on port 16432. The container was stopped after proof. |

The Ops rerun emitted the existing Dialyzer type warning in `Scrypath.Sync.sync_related/3`; it did not fail the test capability. No test warning or dependency failure was reported. The exact source hash remained `d4976944e8049699f31dc6769cd68d719bc4a814`, and all selected graph hashes were rechecked after behavior proof. These are local behavior results, not the Phoenix path/package graph proof, an adopter lock upgrade, a hosted result, or a Hex publication claim. Plan 05 owns the combined-candidate and public-main evidence.

## Plan 04 advisory refresh — 2026-09-28

The first Plan 04 inventory run used Hex 2.5.1 and found the root and Phoenix graphs clean, but reported `lazy_html 0.1.12` as affected by EEF-CVE-2026-92106 in both ecommerce and Ops. [OSV records versions through 0.1.12 as affected and 0.1.13 as fixed](https://osv.dev/vulnerability/EEF-CVE-2026-92106). The two owning locks were changed with separate `mix deps.update lazy_html` runs. No manifest or other lock entry changed.

The old lock tuple in each consumer was:

```elixir
"lazy_html": {:hex, :lazy_html, "0.1.12", "31a55ee622918fce988c94b06232227b42daa64e4eab14ac32081d0f3fd8db6f", [:make, :mix], [{:cc_precompiler, "~> 0.1", [hex: :cc_precompiler, repo: "hexpm", optional: false]}, {:elixir_make, "~> 0.9", [hex: :elixir_make, repo: "hexpm", optional: false]}, {:fine, "~> 0.1.0", [hex: :fine, repo: "hexpm", optional: false]}], "hexpm", "8a0da594776caee58782c6f93b2abaa5bdb809daf8d43351a561f7de9dc2e2a8"}
```

The fixed tuple now in both locks is:

```elixir
"lazy_html": {:hex, :lazy_html, "0.1.13", "860ea816f5bc7936d1ab5ccebc388f9d1031ba9c35ed81a4db9a1c3a50737704", [:make, :mix], [{:cc_precompiler, "~> 0.1", [hex: :cc_precompiler, repo: "hexpm", optional: false]}, {:elixir_make, "~> 0.9", [hex: :elixir_make, repo: "hexpm", optional: false]}, {:fine, "~> 0.1.0", [hex: :fine, repo: "hexpm", optional: false]}], "hexpm", "9a8405d6785fe6f8423b86e0ec5f21806ef79941fe853eac3d14fbbb173c34e9"}
```

The post-remediation source is `94b0b7a47b176e0058c1610248b61309ee05ac20`. A local run of `elixir scripts/ci/dependency_audit.exs` returned exit 0 with four `clean`, complete rows on Hex 2.5.1. Every ignore source was `default`, every selected ignore value was `[]`, and each before/after lock hash matched. The command took 15.7 seconds wall time; child timings were:

| Graph | Lock SHA-256 | Fetch | Hex audit |
|---|---|---:|---:|
| Root `.` | `eddb9ca9c92557f5a550ff66f3b8f4ce3eb1a1ffc6e1d162654e9b5cc3d90490` | 1.620 s | 2.686 s |
| Phoenix | `881a93c36747f2e19c29df42a0b59a47ec913110fc75c8b7c028a72d90d0549f` | 1.380 s | 1.861 s |
| Ecommerce | `fd5012b15692b72731c8a576b03787f22e932c5e06e0e086a7778f1d2b2ce136` | 1.509 s | 2.261 s |
| Ops | `887aaa6506a3d6525863b515bafa7801abfffb225432ee503cb5553be28a3fbe` | 1.393 s | 2.082 s |

Summed child time was 5.902 s for four fetches and 8.890 s for four audit children. The three consumer rows account for 4.282 s fetch and 6.204 s audit; root's baseline row accounts for 1.620 s and 2.686 s. This single local pass is not the cold/reused-cache comparison or hosted advisory run; Plan 05 owns those.
