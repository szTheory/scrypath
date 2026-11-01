# Phase 183 Acceptance: Maintainer tooling outside the Hex package

Every fact below was observed in the 183-08 run on 2026-10-28. Raw command output was kept outside the checkout. No human UAT is involved (AGENTS.md).

## Source identity

| Item | Value |
|---|---|
| Branch | `planning/v1.45-foundation-ci` |
| Gate SHA (every local gate below ran at this HEAD) | `99d843cc981377e54475a72de263697484be35e6` |
| Phase base (parent of the tracer commit) | `ccb50a05874176b5d9f5083328dba7d431287586` |
| Tracer commit (183-01, fence rename) | `2c45a8621514be5288e504557eb930dbf8cc8df0` |
| Move commit (183-04, 52 R100 renames plus the one-line `@tasks_root` flip) | `a7546f8e` |
| Toolchain actually used | Elixir 1.19.0 / OTP 28 (`ASDF_ELIXIR_VERSION=1.19.0-otp-28`, `ASDF_ERLANG_VERSION=28.5`), matching CI. The plan text names 1.19.5 / 28.1, which this checkout does not have installed. |
| Workspace note | `.planning/config.json` carries a pre-existing, unrelated local edit owned by the maintainer. It was never staged, committed, reverted or stashed. `mix verify.workspace_clean` passes with it present because it checks only packaged, `dev/` and `test/` paths. |

The commits after the gate SHA add only `.planning/` tracking files and this record (plus the one-line PROJECT.md change). No source, test, mix.exs or workflow file changes after `99d843cc`.

## Requirement map

| Requirement | Evidence (command and result at the gate SHA) |
|---|---|
| PKGH-01 | `git ls-files lib/mix/tasks` lists 8 files, `git ls-files dev/mix/tasks` lists 53. `MIX_ENV=test mix verify.package` exit 0 (104 release-contract tests, 0 failures, including the `tooling boundary` and `real archive` describes in `package_contents_test.exs`, which run `PackageContract.check/1` on the unpacked archive). `consumer_smoke_test.exs` (inside the same gate) builds a git-tagged release-like consumer and asserts the compiled consumer holds no `Verify*` beam. The in-repo path-dependency consumer `examples/phoenix_meilisearch` compiled cold with 0 `Elixir.Mix.Tasks.Verify*.beam` and all 8 public task beams (see Path-dependency consumers). |
| PKGH-02 | From the default env (no `MIX_ENV`): `mix verify.adopter` exit 0 (25 tests), `mix verify.namespace_fence` exit 0, `mix verify.workspace_clean` exit 0 (17 pathspecs), `mix verify.phase108` exit 0 (6 tests). `MIX_ENV=test mix verify.core --exclude integration --exclude docs_contract` exit 0 (5 properties, 985 tests, 0 failures, 101 excluded, then the no-optional-deps compile and the docs build). `MIX_ENV=test mix verify.repository_contracts` exit 0 (98 tests, 0 failures). The unpacked archive compiles under prod and test without `dev/` (the `unpacked archive compiles without the dev tree` test, part of `verify.package`). All 36 documented `mix verify*` tokens resolve (see Documented command coverage). |
| PKGH-03 | `MIX_ENV=test mix verify.package` runs `package_contents_test.exs` (wired at `dev/mix/tasks/verify.phase11.ex` line 31, pinned by `docs_contract_test.exs`). The test holds a control plus five mutations on real `hex.build --unpack` output (exact lines are in 183-05-SUMMARY.md), so a repository-only task added to packaged source fails the gate. The orchestrator also ran a live probe (`Mix.Tasks.Verify.ZzProbe` dropped into `lib/`), and the gate failed with `[unexpected-task] verify.zz_probe ...`; the probe was removed. |

## Gate mapping

- ROADMAP success criterion 3's "package/parity gate" maps to **`mix verify.package`** (D-12). `verify.package` runs `verify.phase11`, which runs `package_contents_test.exs` and `consumer_smoke_test.exs`. That is the required `package` job in `ci.yml` and both publish workflows (`release-please.yml`, `publish-hex.yml`). `git diff --quiet ccb50a05 -- .github/workflows/release-please.yml .github/workflows/publish-hex.yml` exits 0: neither workflow changed.
- **`verify.release_parity` is intentionally unchanged (D-13).** `git show ccb50a05:lib/mix/tasks/verify.release_parity.ex | cmp - dev/mix/tasks/verify.release_parity.ex` exits 0: the file moved with identical bytes (the cmp evidence recorded in 183-05 Task 3, re-run here).
- Attaching the new contents checker to `verify.release_parity` (published-package checking) is the deferred follow-up recorded in 183-CONTEXT.md. It is not part of this phase.

## Documented command coverage

The loop scanned the markdown entries of `package files:` in mix.exs, unchanged from the plan's list: CONTRIBUTING.md, README.md, ARCHITECTURE.md, guides/*.md, docs/jtbd-gap-map.md, docs/releasing.md, docs/operator-support.md, docs/search-backend-sre.md and docs/local-demo-docker-dx.md. CHANGELOG.md is also in `files:` but was not scanned, as the plan specifies (generated history, and D-19 forbids editing it). Each distinct token was resolved with `MIX_ENV=test mix help <token>`.

Loop result: `resolved=36 unresolved=0 total=36`.

### Executed

| Command | Env | Exit | Final line |
|---|---|---|---|
| `mix verify.core --exclude integration --exclude docs_contract` | `MIX_ENV=test` | 0 | `5 properties, 985 tests, 0 failures (101 excluded)`; `Verified optional dependencies absent from isolated build: oban` |
| `mix verify.package` | `MIX_ENV=test` | 0 | Release contract tests `104 tests, 0 failures`; tarball `Saved to scrypath-0.3.17` |
| `mix verify.repository_contracts` | `MIX_ENV=test` | 0 | `98 tests, 0 failures` |
| `mix verify.adopter` | default | 0 | `25 tests, 0 failures` |
| `mix verify.namespace_fence` | default | 0 | `==> Namespace fence passed` |
| `mix verify.workspace_clean` | default | 0 | `Workspace clean across 17 pathspecs` |
| `mix verify.phase108` | default | 0 | `6 tests, 0 failures` |

Also executed (not documented `mix verify*` tokens): `node --test scripts/ci/beam_cache.test.cjs` exit 0 (10 tests, 10 pass, including `dev maintainer sources fingerprint every graph`).

### Resolved only

Six of the 36 loop tokens are in the Executed table (`verify.core`, `verify.package`, `verify.repository_contracts`, `verify.adopter`, `verify.workspace_clean`, `verify.phase108`). The seventh executed command, `verify.namespace_fence`, is documented only in code and `.planning`, so it is not in the loop. The other 30 resolved through `MIX_ENV=test mix help` and were not run as top-level commands:

`verify`, `verify.backend`, `verify.compatibility`, `verify.coverage`, `verify.deep_quality`, `verify.ecommerce_e2e`, `verify.ecommerce_mounted`, `verify.meilisearch_smoke`, `verify.no_optional_deps`, `verify.ops_ui`, `verify.phase11`, `verify.phase112`, `verify.phase13`, `verify.phase14`, `verify.phase20`, `verify.phase26`, `verify.phase28`, `verify.phase41`, `verify.phase43`, `verify.phase5`, `verify.phase82`, `verify.phase94`, `verify.phase96`, `verify.phase97`, `verify.phase98`, `verify.phase99`, `verify.phoenix_example`, `verify.postgres`, `verify.release_parity`, `verify.release_publish`.

Tokens that need services, Docker, the network or hosted CI (for example `verify.meilisearch_smoke`, `verify.postgres`, `verify.ecommerce_e2e`, `verify.ecommerce_mounted`, `verify.release_publish`) stay resolved-only by design. Some resolved-only tasks still ran as children of an executed command (`verify.phase11` inside `verify.package`; `verify.no_optional_deps` inside `verify.core`), but they were not invoked on their own.

## History checks

- **D-16:** the fence rename is commit `2c45a862` (`R095` for both the task and its test, per 183-01). The move is commit `a7546f8e`: `git diff -M --name-status a7546f8e^ a7546f8e` prints 52 `R100` lines plus one `M test/support/repo_tooling.ex`, nothing else.
- **D-19:** `git diff --quiet ccb50a05 -- CHANGELOG.md` exits 0 (CHANGELOG.md unchanged since the phase base). No tag points at HEAD (`git tag --points-at HEAD` prints nothing). No release, publish or merge occurred.
- **D-20:** `git diff --quiet ccb50a05 -- .planning/phases/182-reliable-full-browser-verification-and-ci-caches .planning/milestones` exits 0 (archived Phase 182 and milestone evidence unchanged).
- `git grep -F 'scrypath.namespace_fence' -- ':!.planning'` prints nothing: no tracked file outside `.planning/` names the old fence task.

## Evidence carried from the SUMMARYs

- **Pre-move counts (183-05):** a fresh `hex.build --unpack` of the phase base checked with the new `PackageContract.check/1` gave `unexpected=53 missing=0`. The published 0.3.17 tarball (`mix hex.package fetch scrypath 0.3.17 --unpack`) gave `unexpected=52 missing=0`, because it predates `verify.postgres`. Both match research F4.
- **D-07 amendment (quoted from 183-CONTEXT.md):** "Amended 2026-10-28 (maintainer-approved): The original text above is kept for history and no longer governs. [...] Leave `docs/0` unchanged, with no `filter_modules`. Add a hermetic guard that packaged docs (every ExDoc extra) and packaged `lib/**/*.ex` never reference `Mix.Tasks.Verify`. Reason: with the filter, `MIX_ENV=test mix docs --warnings-as-errors` fails with about 59 \"reference to a filtered module\" warnings, which would turn `mix verify`, `verify.core` and `verify.phase11` red. Without it, both docs builds are clean. [...] Accepted consequence: local `:test` docs still list the Verify pages, so the local and published module lists differ." The guard is the `packaged docs` describe (183-07).
- **Consumer probe outputs (183-06):** the release-like consumer's ebin holds 8 `Elixir.Mix.Tasks.*` beams and no `Verify*`; `mix verify.package` exits 1 with `The task "verify.package" could not be found`; `mix scrypath.status` runs its own usage path (exit 1, `expected one schema module argument`); `mix help` succeeds for all 8 public tasks; the in-VM probe prints `public-tasks-ok`.

## Docs builds

Both ran once here, as closeout-only gates (183-07 did not run them):

- `MIX_ENV=test mix docs --warnings-as-errors`: exit 0. Final lines: `Generating docs...`, `View html docs at "doc/index.html"`, `View markdown docs at "doc/llms.txt"`, `View epub docs at "doc/scrypath.epub"`. The log contains no `warning`.
- `MIX_ENV=dev mix docs --warnings-as-errors`: exit 0, same final lines, no `warning` in the log.

## Path-dependency consumers

`examples/phoenix_meilisearch` (`{:scrypath, path: "../.."}`): `mix deps.get` exit 0, then `MIX_ENV=dev MIX_BUILD_PATH=<cold dir outside the checkout> mix compile` exit 0 in about 16 s. In `lib/scrypath/ebin`:

| Check | Result |
|---|---|
| `Elixir.Mix.Tasks.Verify*.beam` | **0** |
| `Elixir.Mix.Tasks.Scrypath.*.beam` | **8** (Failed, Index.ContractDrift, Reconcile, Retry, Settings.Diff, Settings.HotApply, Settings.Read, Status; none missing) |
| `git diff --quiet -- examples/phoenix_meilisearch` | exit 0 (mix.lock and every tracked file unchanged) |

Planning-time baseline on the pre-move tree, from the plan: the same command found 52 Verify beams and 9 Scrypath task beams (the extra one was the old `Scrypath.NamespaceFence`). That baseline was not re-run in this run; the post-move counts above are the observed ones.

## PROJECT.md update

Inserted after the bullet "`mix verify.adopter` is the canonical adopter proof spine." under "Canonical Adopter Contract" / "Support and proof policy" (one line added, none removed):

> - Since Phase 183, repository-only `mix verify*` tasks (including `mix verify.adopter`) run from a source checkout. They live in `dev/mix/tasks/`, compile only under `MIX_ENV=test`, and are not part of the Hex package built from this source, which ships only the public `mix scrypath.*` operator tasks. The published 0.3.17 still contains them until a separate maintainer-confirmed release.

PKGH requirements are not marked validated in PROJECT.md; the phase-transition workflow owns that.

## Spec-less edge disposition

| Probe item | Probe status | Disposition in this phase | Flagged assumption |
|---|---|---|---|
| PKGH-01 | unclassified / unresolved | Resolved to explicit truths in 183-01, 183-04, 183-05, 183-06 and 183-08 | Criteria are planner-authored from ROADMAP success criterion 1 and D-01/D-02/D-10; no SPEC supplied them. |
| PKGH-02 | unclassified / unresolved | Resolved to explicit truths in 183-01, 183-02, 183-03, 183-04, 183-05, 183-07 and 183-08 | "Intended environments" means the default env routed to :test (D-06). An explicit MIX_ENV=dev not finding a verifier is intended. "Callable" is proven by executing an offline subset and resolving every other documented token. |
| PKGH-03 | unclassified / unresolved | Resolved to explicit truths in 183-05, 183-06 and 183-08 | "Usable" means resolve, document and run the task's own usage path without a backend. Dynamic module generation is covered by the compiled-consumer backstop, not the AST scan. |

## Sampling

Per-wave sampling stayed on `mix verify.package` plus each task's focused files, inside the 30 s budget apart from the named per-task exceptions in 183-VALIDATION.md. The following are closeout-only gates, exempt from the 30 s latency budget, and ran once here: the full `mix verify.core --exclude integration --exclude docs_contract` (about 53 s wall), both docs builds, the documented-command resolution loop (about one minute), the cold path-dependency consumer compile of `examples/phoenix_meilisearch` (about 16 s), and the hosted closeout.

## Known limits

- The published 0.3.17 and its HexDocs still contain the verifiers until a separate maintainer-confirmed release. This phase changes the source only.
- Attaching the contents checker to `verify.release_parity` (D-13) is deferred.
- `mix help verify.x` needs `MIX_ENV=test`; without it Mix reports that the task could not be found (D-06, documented in CONTRIBUTING).
- Of the three path-dependency consumers named in CONTEXT Integration Points, only `examples/phoenix_meilisearch` is compiled by this gate. `scrypath_ops` (`path: ".."`) and `examples/scrypath_ecommerce` (`path: "../.."`) consume the same scrypath `mix.exs`, whose `elixirc_paths/1` adds `dev/` only under `:test` while path deps compile in `:prod`, so the same mechanism applies. They are not compiled here because each pulls a much larger dependency and asset graph. Their hosted coverage is the required `ecommerce-mounted` job in the closeout (`mix verify.ecommerce_mounted`), which builds them against the moved tree but does not count Verify beams.
- The local toolchain was Elixir 1.19.0 / OTP 28.5, not the 1.19.5 / 28.1 named in the plan text. The hosted run is the authority on CI's own versions.
- Local `:test` docs still list the Verify pages while HexDocs (built by `hex.publish` in `:dev`) will not; this is the accepted D-07 consequence quoted above.

## Hosted evidence

### Pull request

- PR #123, https://github.com/szTheory/scrypath/pull/123, title `fix(package): keep repository-only verify tasks out of the Hex package` (D-19), base `planning/v1.44-new-milestone` (PR #122 is still open and that branch is an ancestor of HEAD, so the diff shows only v1.45 work), head `planning/v1.45-foundation-ci`.
- State at the time of recording: OPEN, unmerged, no auto-merge. No merge, tag, release or publish was performed, and CHANGELOG.md is untouched. No `.coderabbit.yaml` exists, so no automatic external reviewer ran.

### Stage 1: candidate closeout

Command: `node scripts/ci_monitor.cjs closeout --push --branch planning/v1.45-foundation-ci --sha ff761beaebc4136549eb4685653ec81788642d76` (exit 0). The candidate is the commit `docs(183-08): record phase 183 acceptance`; the cleanliness and STATE integrity gates passed immediately before it ran.

| Field | Value |
|---|---|
| Workflow / event | `ci.yml` / `workflow_dispatch` |
| Run | 40700112673, attempt 1, https://github.com/szTheory/scrypath/actions/runs/40700112673 |
| Run SHA | `ff761beaebc4136549eb4685653ec81788642d76` |
| Coverage artifact | id 12820409499, `sha256:7cbdfb02a69df1b4b72e215ef747dfcbd3d66f2fcd6b27eb5cdcbfb094b8a695` |
| Closeout-attestation artifact | id 12820484785, `sha256:a1c1119f00009d30cc54694338aab03c86a75ba9b29df5e26b9df93ae0138b56` |

Required jobs, all `success`: `core (required)`, `package (required)`, `repository-contracts (required)`, `backend (required)`, `ecommerce-mounted (required)`, plus `coverage (advisory)` and `closeout-attestation`.

Other jobs in the same run: `compatibility (advisory)` x3 success, `ecommerce-e2e (advisory)` success, `phoenix-example (advisory)` success, `ops-ui-path` success, `ops-ui (path-scoped)` skipped, and `deep-quality (advisory)` **failure**. The deep-quality failure is advisory and not a required check. Its failing step is `scripts/ci/dependency_audit.exs`: the Hex audit reported an active advisory in the `examples/phoenix_meilisearch` and `examples/scrypath_ecommerce` dependency graphs ("HTTP/2 StreamError recovery rolls back connection state and bypasses per-connection limits in Bandit"). This phase touches neither example lockfile (`lock_sha_before` equals `lock_sha_after` for both graphs), so the cause is an external advisory against a locked dependency, not a package-boundary change. It is recorded here rather than fixed (out of scope for this phase).

### Stage 2: exact final SHA

Stage 2 reruns the same command at the final SHA after the `docs(183-08): record hosted closeout candidate` commit. Per CONTRIBUTING, no tracked file is written after a successful final attestation, so its receipt is written only outside the checkout, at `${TMPDIR}/scrypath-phase183-closeout/stage2-receipt.json` (this machine: `/var/folders/f3/f0clj9rd2zb85n2c849wcsrc0000gn/T/scrypath-phase183-closeout/stage2-receipt.json`). The run URL, run ID, SHA and artifact digests of stage 2 are reported by the executor in its return and are the authority for the final SHA.
