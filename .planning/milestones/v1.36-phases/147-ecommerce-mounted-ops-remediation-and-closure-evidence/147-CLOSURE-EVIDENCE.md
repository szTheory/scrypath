# Phase 147 Closure Evidence

## Ecommerce Exact-SHA Proof

| Field | Result |
|---|---|
| Candidate | `fca4c827a59596e2a66bc2d1ac3516b4c0c5681e` |
| UTC window | `2026-08-25T18:57:22Z` to `2026-08-25T18:59:54Z` |
| Host | macOS 26.5 (25F71) |
| Tools | Elixir 1.19.5; OTP 28; Mix 1.19.5; Hex 2.5.1 |
| Candidate manifest SHA-256 | `22e77da4287bf03a21a4063b9abf88f3fb7df781d6797fe53fb14e74a744706e` |
| Candidate lock SHA-256 | `93fb034fe108de0ac9160512a74031e668cd5c78d107bc43fc31043749ab2fa8` |
| Fresh disposable lock SHA-256 | `a2b8eebf69c9a3f2ef53b14992bba3f73087e0fd99e4ee7bb88599faa7f5b0c7` |
| Canonical mounted paths | `:scrypath` and `:scrypath_ops` both PASS against the detached candidate |
| required_deterministic | warning-clean compile, 4 focused controller tests, and 33-test `mix precommit`: PASS |
| required_service_prepare | Postgres + Meilisearch readiness and `mix e2e.prepare`: PASS |
| Security audit | unsuppressed `mix hex.audit`: exit 0 |

Fresh range matrix:

| Package | Fresh selection | Approved range | Result |
|---|---:|---|---|
| Phoenix | 1.8.13 | `>= 1.8.9 and < 1.9.0` | PASS |
| Phoenix LiveView | 1.1.33 | `>= 1.1.33 and < 1.2.0` | PASS |
| Bandit | 1.12.5 | `>= 1.12.1 and < 1.13.0` | PASS |
| Swoosh | 1.26.3 | `>= 1.26.3 and < 1.27.0` | PASS |
| Postgrex | 0.22.4 | `>= 0.22.4 and < 0.23.0` | PASS |
| Req | 0.6.3 | `>= 0.6.1 and < 0.7.0` | PASS |
| Plug | 1.20.3 | `>= 1.19.5 and < 2.0.0` | PASS |
| Mint | 1.9.3 | `>= 1.9.3` | PASS |
| hpax | 1.0.4 | `>= 1.0.4` | PASS |

Cleanup receipt: the owned, non-symlink temporary parent and its exact worktree child were canonicalized and uniquely registered before execution and again before removal. The disposable worktree, isolated Mix paths, Compose services, network, and volumes are absent. Primary root/Ops locks, the source-scoped dirty baseline, and protected audit hash remained unchanged.

## Focused Browser Evidence

state: passed

- Candidate: `fca4c827a59596e2a66bc2d1ac3516b4c0c5681e`
- UTC: `2026-08-25T18:57:22Z` to `2026-08-25T18:59:54Z`
- Command: `make verify-mounted`
- Prerequisites: Compose-provisioned Postgres, Meilisearch, Phoenix, assets, fixtures, and Playwright Chromium all healthy.
- First attempt: 4/4 focused tests passed with one worker.
- Final outcome: passed; `flake: false`; no retry was used.
- Cleanup: passed; no candidate verifier containers, networks, or volumes remained.
- Optional full lane: the same implementation content passed 99/99 browser tests, 20/20 light-parity checks, and static contrast with zero AA failures before candidate creation. It is advisory and does not replace the exact-candidate focused result.

## Four-Graph Same-Window Matrix

Window: `2026-08-25T19:00:59Z` to `2026-08-25T19:01:13Z`; candidate `fca4c827a59596e2a66bc2d1ac3516b4c0c5681e`; macOS 26.5 (25F71); Elixir 1.19.5 / OTP 28 / Mix 1.19.5 / Hex 2.5.1.

| Order | Graph | Lock SHA-256 before/after | Checked lock | Unsuppressed audit | Selected fixed versions | Fresh-proof reference | Classification |
|---:|---|---|---|---|---|---|---|
| 1 | root | `97d980f6effe1e6c263a2643c691e0801a7eb70275d7db90c228ae40848cb488` | exit 0 | exit 0 | Req 0.6.3; Plug 1.19.5; Mint 1.9.3; hpax 1.0.4 | `144-03-SUMMARY.md`, exact candidate `23b8b834` | PASS |
| 2 | legacy | `3bd129e6b7128a34dae48c5ca3691f71a0166cb41a7d09919765d9c4487095d6` | exit 0 | exit 0 | Phoenix 1.8.9; Bandit 1.12.5; Postgrex 0.22.4; Req 0.6.3; Plug 1.19.5; Mint 1.9.3; hpax 1.0.4 | `145-02-SUMMARY.md`, primary `e50fbd5`, recovery `4e2abed` | PASS |
| 3 | ScrypathOps | `30c54587258cf29674af0b5e9f1c71799ac44f82ef9227fd6d9e2d1776588ea4` | exit 0 | exit 0 | Phoenix 1.8.12; LiveView 1.1.33; Bandit 1.12.5; Swoosh 1.26.3; Postgrex 0.22.4; Req 0.6.3; Plug 1.19.5; Mint 1.9.3; hpax 1.0.4 | `146-03-SUMMARY.md` and `146-04-SUMMARY.md`, primary `59d2e6a`, test closure `ff1531c` | PASS |
| 4 | ecommerce | `93fb034fe108de0ac9160512a74031e668cd5c78d107bc43fc31043749ab2fa8` | exit 0 | exit 0 | Phoenix 1.8.13; LiveView 1.1.33; Bandit 1.12.5; Swoosh 1.26.3; Postgrex 0.22.4; Req 0.6.3; Plug 1.20.3; Mint 1.9.3; hpax 1.0.4 | Ecommerce Exact-SHA Proof above, candidate `fca4c82` | PASS |

All four rows are independent, nonempty, ordered, lock-stable, and audit-clean. No root, legacy, or Ops lock was deleted or locklessly re-resolved for this matrix.

## Four Ordered Remediation Batches

Every constituent SHA below is an ancestor of `fca4c82`; each path set was read from `git diff-tree --no-commit-id --name-only -r`.

| Batch | Constituent commits | Role and path set |
|---:|---|---|
| 1 | `f711521` | Shared Req compatibility handoff: root manifest/lock, legacy lock, Ops manifest/lock, ecommerce manifest/lock, plus the matching ROADMAP/REQUIREMENTS truth update. |
| 2 | `e50fbd5`, `4e2abed` | Legacy primary changes its manifest, lock, and two focused compatibility tests; recovery adds the direct legacy Plug boundary in the legacy manifest. |
| 3 | `59d2e6a`, `ff1531c` | Ops primary changes its manifest, lock, and focused Swoosh contract; the later test-only closure hardens that same focused contract without graph changes. |
| 4 | `fca4c82` | Ecommerce graph-local implementation changes only `examples/scrypath_ecommerce/mix.exs` and `examples/scrypath_ecommerce/mix.lock`. |

This is four ordered remediation batches, not four literal commits. The shared handoff is intentionally cross-graph; later ownership is graph-local, and required gates passed before the next remediation batch.

## Planning Truth, Todo Closure, and Preservation

- Scoped committed files and final SHA-256 values: `.planning/ROADMAP.md` `d1e2b1aadfee65a4ab9abc169e13e951bfefab715be9906ef383c07b996c2e7d`; `.planning/REQUIREMENTS.md` `469ee178cae4c7cc9f69cda2dd6f87cb56569f850d26c113a960fd638c68226a`; completed advisory todo `656e8c03d740f6f6c829910a4cada2618da4231035b7f3c5c4bcfac9d2e94fe3`. The working-tree REQUIREMENTS hash differs only because the preserved user-owned SEC-02/timestamp hunks remain unstaged.
- Protected file: `.planning/v1.36-v1.36-MILESTONE-AUDIT.md` SHA-256 `9286903e0426282cce3d63590b61c9fc9b8c590ceede9c3ddcb4d1959f46ea5c`; unchanged, unstaged, and not used as current closure truth.
- Receipt exclusions: no raw logs, disposable locks, dependency trees, temporary paths, credentials, browser reports, generated service state, UI/brand/API changes, or branch-protection policy mutations are included.
