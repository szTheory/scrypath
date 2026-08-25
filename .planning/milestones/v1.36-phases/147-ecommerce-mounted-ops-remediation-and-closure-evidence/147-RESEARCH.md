# Phase 147: Ecommerce Mounted-Ops Remediation and Closure Evidence - Research

**Researched:** 2026-08-25
**Domain:** Isolated Mix dependency remediation, mounted-path provenance, and four-graph closure evidence
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### 1. Ecommerce dependency intent and ownership

- **D-01:** Mirror the approved ScrypathOps-compatible direct bounds in ecommerce:
  Phoenix `~> 1.8.9`, Phoenix LiveView `~> 1.1.33`, Bandit `~> 1.12.1`,
  Swoosh `~> 1.26.3`, Postgrex `~> 0.22.4`, and the already-landed Req
  `~> 0.6.1`. These are fixed-compatible minor-line bounds, not instructions to
  select package heads.
- **D-02:** Leave `phoenix_ecto`, Ecto SQL `~> 3.13`, Oban, and unrelated direct
  requirements unchanged unless the resolver or a focused compatibility failure
  demonstrates a causal need. Keep Plug, Mint, hpax, Finch, Ecto, and Decimal
  transitive; add no direct requirement or override merely to force a reviewed lock.
- **D-03:** Refresh only the causal closure produced by the approved direct bounds
  and the Phase 144 Req handoff. Explain every moved lock row. No unrelated cleanup,
  advisory suppression, broad compatibility refactor, or current-package-head churn.
- **D-04:** The detached ecommerce fresh-resolution matrix must select Phoenix
  `>= 1.8.9 and < 1.9.0`, LiveView `>= 1.1.33 and < 1.2.0`, Bandit
  `>= 1.12.1 and < 1.13.0`, Swoosh `>= 1.26.3 and < 1.27.0`, Postgrex
  `>= 0.22.4 and < 0.23.0`, Req `>= 0.6.1 and < 0.7.0`, Plug
  `>= 1.19.5 and < 2.0.0`, Mint `>= 1.9.3`, and hpax `>= 1.0.4`.
- **D-05:** A production/source compatibility change is allowed only after a
  focused compile or test failure proves it necessary. Keep any such fix inside
  ecommerce, minimal, covered, and behavior-preserving; otherwise stop and re-plan.

### 2. Two-stage mounted-source provenance

- **D-06:** Before the ecommerce remediation commit, run the causal proof in the
  current checkout with fresh temporary `MIX_DEPS_PATH` and `MIX_BUILD_PATH`
  values. Propagate both values through dependency fetch, compile, tests, and
  preparation; an omitted isolation variable invalidates the receipt.
- **D-07:** Directly assert via `Mix.Project.deps_paths/0` or an equivalent public
  Mix seam that ecommerce resolves `:scrypath` to the canonical repository root
  and `:scrypath_ops` to the canonical `scrypath_ops/` directory. Do not infer
  mounted-source identity only from a successful compile.
- **D-08:** The pre-commit provenance receipt records the current HEAD/base,
  source-scoped dirty status, canonical source paths, and SHA-256 values for the
  root and Ops manifests and locks. It must also prove the ecommerce lock did not
  change unexpectedly during checked-lock proof.
- **D-09:** After the atomic ecommerce implementation commit exists, repeat the
  causal proof in a disposable detached worktree at that exact SHA with isolated
  dependency/build paths. This post-commit proof supplements rather than replaces
  the roadmap's before-commit gate.
- **D-10:** Reuse the fail-closed cleanup discipline learned in Phase 146: validate
  the temporary parent and exact worktree child, ownership, non-symlink state,
  registration, and canonical path equivalence before deletion; clean up
  unconditionally; then prove absence and primary-workspace lock/status preservation.
  Never clear a contributor's ordinary `deps/` or `_build/` caches for evidence.

### 3. Required gate bundle and stop policy

- **D-11:** Run the ecommerce-local gate in diagnostic order: inspect/explain the
  manifest and lock diff; `mix deps.get --check-locked`; mounted-source path
  assertions; compile with warnings as errors; the focused existing mounted
  route/asset/link test; then the complete ecommerce `mix precommit` suite.
- **D-12:** Because ecommerce `precommit` includes formatting and
  `deps.unlock --unused`, immediately recheck the ecommerce lock hash, manifest/lock
  diff, formatting status, and source-scoped dirty baseline. Unexplained mutation
  blocks the commit.
- **D-13:** `mix e2e.prepare` is required prerequisite-bound integration
  preparation. It must pass with declared Postgres and Meilisearch services healthy
  before the ecommerce batch is accepted. Missing prerequisites are unavailable
  required evidence and block Phase 147 closure; they are not a pass and are not
  reclassified as service-free deterministic proof.
- **D-14:** After ecommerce-local proof is green, run the named root release-train
  gates once: warning-clean compile; root fast tests including the clean-workspace
  contract; `mix verify --exclude integration`; `mix verify.phase11`; and
  `mix verify.phase99`.
- **D-15:** Do not automatically rerun full standalone `mix verify.opsui` in
  Phase 147. Phase 146 owns that proof. Rerun it only if Phase 147 changes an
  Ops-owned source, manifest, lock, or focused contract file, or if mounted proof
  demonstrates an Ops-owned regression.
- **D-16:** Stop before commit/handoff on an unexplained dependency row, lock or
  dirty-baseline drift, wrong mounted source path, compile warning/error, focused
  route failure, ecommerce full-suite failure, required preparation failure,
  root release-gate failure, out-of-range fresh resolution, non-zero unsuppressed
  audit, unsafe cleanup state, or need for public/runtime/UI scope expansion.

### 4. Proportional browser evidence

- **D-17:** When browser prerequisites are available, run the existing focused
  mounted subset with `e2e/harness.spec.ts` and `e2e/operator.spec.ts`. This is the
  proportional dependency-regression proof for mounted routing and operator flows;
  add no new browser harness or package script solely for Phase 147.
- **D-18:** If the complete advisory `phase105-e2e` job runs for the exact candidate
  SHA, reference its existing evidence rather than manufacturing a second full local
  run. The full storefront, theme, screenshot, contrast, and visual-judge suite
  remains useful supplemental regression evidence but is not promoted to a required
  merge or Phase 147 gate.
- **D-19:** Browser evidence uses the roadmap's three states: `passed`, `failed`, or
  `unavailable`. Add `flake: true` when a retry changes a first-attempt failure into
  a pass. `unavailable` must name the missing service, asset build, Node/browser,
  server-readiness, or exact-SHA CI prerequisite; skipped/cancelled/unrelated-SHA
  jobs are never passes.
- **D-20:** A browser failure causally attributable to the dependency change or
  mounted functionality blocks closure. A classified non-causal advisory visual,
  infrastructure, or flake failure remains honestly failed/unavailable evidence and
  cannot replace required proof, but it does not silently expand this phase into UI
  remediation.
- **D-21:** Reuse existing Playwright report, trace, `test-results`, Phoenix log,
  and Phase 105 evidence summary behavior. Do not commit generated browser artifacts.
  Current `brandbook/` guidance supersedes older prompt material if a visual result
  needs interpretation, but Phase 147 makes no visual or brand changes.

### 5. Hybrid four-graph closure ledger

- **D-22:** Use a hybrid provenance ledger. Retain the historical exact-SHA
  lockless resolution/audit evidence for root, legacy, and Ops; add the matching
  exact-SHA ecommerce proof; then collect one same-window final-candidate
  `mix deps.get --check-locked` and unsuppressed `mix hex.audit` row in each of the
  root, legacy, Ops, and ecommerce directories.
- **D-23:** Do not locklessly re-resolve all three completed graphs again solely for
  symmetry. Their historical exact-candidate fresh proofs remain authoritative;
  same-window checked locks and audits establish present-tense all-graph posture
  without confusing registry drift with the historical remediation result.
- **D-24:** The compact closure matrix records graph, candidate SHA, UTC window,
  OS and Elixir/OTP/Mix/Hex versions, tracked lock SHA-256, checked-lock result,
  unsuppressed audit result, relevant selected versions, historical fresh-proof
  reference, and required/service/browser classification. Exclude raw logs,
  disposable locks, dependency trees, advisory snapshots, temporary paths,
  credentials, and generated service/browser state.
- **D-25:** Represent history as four ordered remediation batches, not four literal
  commits: shared cross-graph Req handoff `f711521`; legacy primary `e50fbd5` plus
  Plug recovery `4e2abed`; Ops primary `59d2e6a` plus test-only closure `ff1531c`;
  and the future ecommerce implementation commit. Explain each role and path set;
  never squash, amend, hide, or rewrite the existing history.
- **D-26:** Planning/execution must reconcile roadmap and EVID-02 wording from
  "four graph-local commits" to the truthful "four ordered remediation batches"
  while preserving the one shared handoff and graph-local ownership of later work.
  This is planning-truth correction, not scope expansion.
- **D-27:** Close the folded dependency-advisory todo only after the ecommerce
  implementation commit, required gates, exact-SHA fresh proof, all-four dated rows,
  browser classification, topology ledger, cleanup verification, and unchanged
  protected user-owned files are all accounted for.
- **D-28:** The existing untracked
  `.planning/v1.36-v1.36-MILESTONE-AUDIT.md` is user-owned stale audit input. Preserve
  and hash-check it as part of the dirty baseline; do not stage, edit, delete, or use
  it as current Phase 147 closure truth.

### 6. Maintainer and adopter experience

- **D-29:** Primary maintainer JTBD: remove ecommerce's reproduced advisories,
  know that the exact mounted root/Ops sources compiled and ran, and obtain one short
  ledger showing which dependency, service, browser, or evidence boundary failed.
- **D-30:** Contributor DX remains familiar Mix, Hex, and Playwright commands with
  causal tests first, explicit prerequisites, no cache destruction, no new policy
  language, and no permanent proof subsystem.
- **D-31:** Adopter-facing behavior remains ordinary Phoenix/Ecto integration:
  the storefront and mounted operator routes keep working without exposing lock,
  resolver, commit, or audit mechanics through public APIs or UI.
- **D-32:** The governing quality pillars are security, correctness, compatibility,
  provenance, reproducibility, maintainability, operability, resilience, evidence
  clarity, privacy, least surprise, contributor/adopter DX, bounded runtime/CI cost,
  accessibility regression safety, and strict scope discipline. New visual design,
  microcopy, themes, animation, and brand work are not applicable.

### Folded Todos

- **Remediate reproduced dependency security advisories** — fold the remaining
  ecommerce remediation and all-four-graph closure into Phase 147. The todo began
  with advisories reproduced across four independent Mix projects; Phases 144-146
  completed the shared/root, legacy, and Ops portions. It remains open until D-27's
  full closure chain passes.

### the agent's Discretion

- Exact temporary-directory names, the public Mix expression used to assert path
  equality, and the compact evidence-table formatting may vary if all locked
  provenance, cleanup, and redaction semantics are preserved.
- The focused browser command may use direct Playwright spec paths or an equivalent
  non-persistent invocation; do not add a new script unless execution proves the
  existing CLI form unusable.
- Root gate ordering may follow `CONTRIBUTING.md` where dependencies require it,
  provided every named gate runs after ecommerce-local proof and before closure.

### Deferred Ideas (OUT OF SCOPE)

None. CONTEXT.md contains no Deferred Ideas section; no product, public API, UI, CI-policy, or package-head modernization work is in scope.
</user_constraints>

## Project Constraints (from AGENTS.md)

- Preserve Scrypath as an Elixir OSS library with Ecto-first APIs and Phoenix-friendly integrations. [VERIFIED: AGENTS.md]
- Keep Meilisearch as the v1 public backend and retain only the internal adapter seam; do not create a public multi-backend abstraction. [VERIFIED: AGENTS.md]
- Preserve inline, Oban-backed, and manual synchronization support and make operational behavior explicit. [VERIFIED: AGENTS.md]
- Optimize for low-friction Phoenix DX without weakening correctness, operational clarity, or release quality. [VERIFIED: AGENTS.md]
- Follow CONTRIBUTING.md verification and green-main release-train posture; do not invent work outside the approved phase. [VERIFIED: AGENTS.md]

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| SEC-04 | Independently resolve ecommerce beyond its recorded advisories after root and Ops are green. | Approved direct bounds, isolated pre/post-commit resolution, selected-version matrix, and unsuppressed audit. [VERIFIED: 147-CONTEXT.md] |
| COMPAT-01 | Each graph passes documented deterministic gates before the next remediation batch. | Diagnostic ecommerce gate ordering followed by named root gates and all-four checked-lock/audit rows. [VERIFIED: 147-CONTEXT.md] |
| COMPAT-03 | Record browser proof separately; unavailable prerequisites are never passing. | Focused existing Playwright specs and three-state evidence classification. [VERIFIED: 147-CONTEXT.md] |
| EVID-01 | Dated `mix deps.get` evidence from all four project directories. | Same-window final-candidate checked-lock + audit matrix and historical fresh-proof references. [VERIFIED: 147-CONTEXT.md] |
| EVID-02 | Minimal explained shared handoff then graph-local remediation without unrelated upgrades. | Four ordered remediation-batch topology ledger and causal manifest/lock diff review. [VERIFIED: 147-CONTEXT.md] |
</phase_requirements>

## Summary

Phase 147 is a closure-evidence phase with one controlled implementation surface: `examples/scrypath_ecommerce/mix.exs` and its independent `mix.lock`. The present manifest uses older direct Phoenix, LiveView, Bandit, Swoosh, and Postgrex constraints, while the lock selects older values; the approved fixed-compatible cohort is already proven in the immediately preceding Ops batch. [VERIFIED: examples/scrypath_ecommerce/mix.exs] [VERIFIED: examples/scrypath_ecommerce/mix.lock] [VERIFIED: 146-03-SUMMARY.md]

The key compatibility risk is not merely resolver success: ecommerce must demonstrably compile and run against the repository-root `:scrypath` and `scrypath_ops/` path dependency. `Mix.Project.deps_paths/0` is the correct public seam because it returns a dependency-to-full-path map; assert its two entries after canonicalizing both expected repository paths. [CITED: https://mix.hexdocs.pm/Mix.Project.html]

The plan should produce concise receipts, not a permanent proof framework. It needs two isolated ecommerce proofs (before commit in the current checkout and after commit in a detached worktree), followed by same-window checked-lock and audit rows for all four independent Mix graphs. Historical fresh proof remains authoritative for root, legacy, and Ops; re-resolving them would create registry-drift noise rather than stronger evidence. [VERIFIED: 147-CONTEXT.md]

**Primary recommendation:** Update only the six approved ecommerce direct constraints, accept only the causal lock closure, prove mounted sources with isolated Mix paths before and after the atomic ecommerce commit, then publish one redacted four-batch/four-graph closure ledger. [VERIFIED: 147-CONTEXT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| E-commerce dependency resolution and lock ownership | Build/dependency graph | Repository root | Ecommerce owns its manifest/lock; root and Ops are mounted source inputs. [VERIFIED: examples/scrypath_ecommerce/mix.exs] |
| Mounted source provenance | Build/dependency graph | Filesystem | Mix resolves direct `:path` dependencies; canonical path comparison proves identity. [CITED: https://mix.hexdocs.pm/Mix.Project.html] |
| `e2e.prepare` search-index setup | API/backend | Database/storage | The Mix task starts the app, creates/migrates the DB, and applies live Meilisearch index settings. [VERIFIED: examples/scrypath_ecommerce/mix.exs] [VERIFIED: e2e.prepare_search.ex] |
| Storefront and mounted operator regression | Frontend server | API/backend | Existing LiveView/Phoenix and Playwright tests traverse host routes and mounted `/admin/search` routes. [VERIFIED: e2e/harness.spec.ts] [VERIFIED: e2e/operator.spec.ts] |
| Closure evidence and topology | Repository/release process | CI/browser | The ledger joins graph-local lock/audit state, historical commits, service preparation, and browser classification. [VERIFIED: 147-CONTEXT.md] |

## Standard Stack

### Core

| Tool | Version / bound | Purpose | Why Standard |
|---|---|---|---|
| Elixir/Mix | Elixir 1.19.5 / OTP 28 / Mix 1.19.5 available locally | Resolve, compile, test, and inspect Mix dependency paths. | Existing project toolchain; no new package is needed. [VERIFIED: local `elixir --version`; `mix --version`] |
| Mix path dependencies | `{:scrypath, path: "../.."}` and `{:scrypath_ops, path: "../../scrypath_ops"}` | Mount current root and Ops sources into ecommerce. | Existing direct dependency contract. [VERIFIED: examples/scrypath_ecommerce/mix.exs] |
| Hex audit | Existing Mix/Hex task | Check the resolved graph without advisory suppression. | Required closure evidence. [VERIFIED: 147-CONTEXT.md] |
| Playwright | 1.60.0 available locally | Focused mounted storefront/operator regression proof when prerequisites are healthy. | Existing E2E harness and CI evidence format. [VERIFIED: local `npx playwright --version`] [VERIFIED: playwright.config.ts] |

### Supporting

| Tool | Purpose | When to Use |
|---|---|---|
| `sha256sum` / `shasum -a 256` | Record manifest/lock and protected dirty-file identity. | Before/after each proof and after cleanup. [VERIFIED: 147-CONTEXT.md] |
| `git worktree` | Create the exact-SHA disposable proof environment. | Only after pre-commit gate passes and ecommerce commit exists. [CITED: https://git-scm.com/docs/git-worktree] |
| `pg_isready`, Meilisearch `/health` | Check prerequisite-bound service availability. | Immediately before `mix e2e.prepare` and browser startup. [VERIFIED: local probes] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| `Mix.Project.deps_paths/0` assertion | Infer paths from compile success or a dependency tree | Rejected: successful compilation does not prove the required canonical mounted source identity. [VERIFIED: 147-CONTEXT.md] |
| Existing focused specs | New E2E script/harness | Rejected: D-17 prohibits new persistent browser machinery for this phase. [VERIFIED: 147-CONTEXT.md] |
| Detached ecommerce re-resolution only | Re-resolve all four graphs locklessly | Rejected: historical root/legacy/Ops exact-SHA proofs remain authoritative; same-window checked locks/audits are sufficient. [VERIFIED: 147-CONTEXT.md] |

**Installation:** No external package installation is authorized or needed. [VERIFIED: 147-CONTEXT.md]

## Package Legitimacy Audit

Not applicable: Phase 147 changes approved existing Hex dependency constraints and does not introduce an external package. The planner must not add packages, direct transitive dependencies, or overrides. [VERIFIED: 147-CONTEXT.md]

## Architecture Patterns

### System Architecture Diagram

```text
ecommerce mix.exs + mix.lock
          |
          v
isolated MIX_DEPS_PATH + MIX_BUILD_PATH
          |
          +--> mix deps.get --check-locked --> lock-hash / causal-diff receipt
          |
          +--> Mix.Project.deps_paths/0 --> root Scrypath + scrypath_ops canonical-path assertions
          |
          +--> compile / focused route test / precommit --> deterministic compatibility receipt
          |
          +--> healthy Postgres + Meilisearch --> mix e2e.prepare --> required preparation receipt
          |
          +--> focused Playwright specs --> passed | failed | unavailable browser record
          |
          v
atomic ecommerce remediation commit
          |
          v
detached exact-SHA worktree + isolated paths --> repeat causal proof --> cleanup validation
          |
          v
four-graph same-window checked locks + audits + historical proof references
          |
          v
redacted closure ledger / ordered remediation-batch topology
```

### Recommended Project Structure

```text
examples/scrypath_ecommerce/
├── mix.exs                         # approved direct bounds only
├── mix.lock                        # causal resolver-owned closure
├── test/                           # existing deterministic Phoenix/LiveView contracts
├── e2e/                            # existing focused mounted browser specs
└── lib/mix/tasks/e2e.prepare_search.ex  # live index preparation task
.planning/phases/147-.../
└── 147-VALIDATION.md / summaries   # compact, redacted evidence references
```

### Pattern 1: Isolated mounted-source receipt

**What:** Use a fresh temporary parent with distinct `MIX_DEPS_PATH` and `MIX_BUILD_PATH` children for every command in a proof sequence; then assert the canonical paths returned by Mix. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.Get.html] [CITED: https://mix.hexdocs.pm/Mix.Project.html]

**When to use:** Pre-commit in the primary checkout and post-commit in an exact-SHA detached worktree. [VERIFIED: 147-CONTEXT.md]

**Example:**

```sh
# Run from examples/scrypath_ecommerce with values created under an owned temp parent.
MIX_DEPS_PATH="$proof_parent/deps" MIX_BUILD_PATH="$proof_parent/build" \
  mix deps.get --check-locked

MIX_DEPS_PATH="$proof_parent/deps" MIX_BUILD_PATH="$proof_parent/build" \
  mix run --no-start -e '
    paths = Mix.Project.deps_paths()
    expected = %{scrypath: Path.expand("../.."), scrypath_ops: Path.expand("../../scrypath_ops")}
    if Map.take(paths, Map.keys(expected)) != expected, do: System.halt(1)
  '
```

The planner should make every subsequent proof command carry both environment variables, capture actual/expected paths in the receipt, and use the project’s canonical-path routine before comparison. The one-line assertion is a planning pattern, not a new committed source file. [VERIFIED: 147-CONTEXT.md]

### Pattern 2: Detect then contain `precommit` mutation

**What:** Treat ecommerce `mix precommit` as potentially mutating because its alias contains `deps.unlock --unused` and `format`; hash and diff before it, run it, then hash/diff/format/status again. [VERIFIED: examples/scrypath_ecommerce/mix.exs]

**When to use:** After focused deterministic proof and before the ecommerce commit. [VERIFIED: 147-CONTEXT.md]

**Anti-pattern:** Calling `mix precommit` as the only dependency check. It can alter the lock and format files, so it cannot establish a stable lock receipt on its own. [VERIFIED: examples/scrypath_ecommerce/mix.exs] [VERIFIED: 147-CONTEXT.md]

### Pattern 3: Four ordered remediation batches, not a false four-commit history

**What:** Record the shared Req handoff as batch one, legacy primary/recovery as batch two, Ops primary/test closure as batch three, and ecommerce as batch four. [VERIFIED: 147-CONTEXT.md]

**When to use:** The closure ledger and final summary. [VERIFIED: 147-CONTEXT.md]

| Batch | History | Role | Allowed path set |
|---|---|---|---|
| Shared Req handoff | `f711521` | Cross-graph compatibility floor across the approved direct manifests and locks. | Historical shared handoff paths only. [VERIFIED: 147-CONTEXT.md] |
| Legacy | `e50fbd5`, `4e2abed` | Legacy Phoenix remediation plus focused Plug recovery. | Historical legacy paths only. [VERIFIED: 147-CONTEXT.md] |
| Ops | `59d2e6a`, `ff1531c` | Ops dependency remediation plus test-only raw JSON closure. | Historical Ops paths only. [VERIFIED: 146-04-SUMMARY.md] |
| Ecommerce | future phase implementation SHA | Direct-bound and causal-lock remediation with any proven-minimal compatibility fix. | `examples/scrypath_ecommerce/**` only, absent a re-plan. [VERIFIED: 147-CONTEXT.md] |

### Anti-Patterns to Avoid

- **Treating a path dependency as proved by compilation:** explicitly inspect `Mix.Project.deps_paths/0`. [CITED: https://mix.hexdocs.pm/Mix.Project.html]
- **Using ordinary `deps/` or `_build/` for evidence:** this mixes cache state with the candidate and risks contributor state. [VERIFIED: 147-CONTEXT.md]
- **Running `mix deps.unlock --unused` as cleanup:** it is only part of the existing precommit alias and must be followed by drift detection, not used to broaden lock churn. [VERIFIED: examples/scrypath_ecommerce/mix.exs] [VERIFIED: 147-CONTEXT.md]
- **Calling absent services a pass:** `mix e2e.prepare` is required prerequisite-bound evidence, while browser proof has only passed/failed/unavailable states. [VERIFIED: 147-CONTEXT.md]
- **Committing browser reports, traces, test-results, raw logs, temporary locks, or credentials:** retain only the redacted ledger fields and external artifact references. [VERIFIED: 147-CONTEXT.md]
- **Rewriting the historical topology to satisfy stale wording:** reconcile EVID-02 to ordered batches; do not amend or squash prior commits. [VERIFIED: 147-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Mounted dependency provenance | Custom parser of `mix.lock` or `deps` directory names | `Mix.Project.deps_paths/0` plus canonical path equality | The public Mix API returns resolved dependency locations. [CITED: https://mix.hexdocs.pm/Mix.Project.html] |
| Lock validity | Ad-hoc resolver heuristic | `mix deps.get --check-locked` | Mix raises when the lock has pending changes. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.Get.html] |
| Disposable checkout cleanup | `rm -rf` against a computed directory | `git worktree remove` after ownership, symlink, registration, and canonical-path validation | Git tracks linked-worktree metadata and refuses unclean removal unless forced. [CITED: https://git-scm.com/docs/git-worktree] |
| Browser dependency regression harness | New npm script or E2E suite | Existing direct `playwright test e2e/harness.spec.ts e2e/operator.spec.ts` invocation | D-17 requires a proportional existing subset. [VERIFIED: 147-CONTEXT.md] [VERIFIED: package.json] |

**Key insight:** This phase’s value is trustworthy provenance, not new tooling. Existing Mix, Git, service, and Playwright seams already expose every required fact. [VERIFIED: 147-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: A valid ecommerce lock still binds the wrong local source

**What goes wrong:** The lock is clean and compilation passes, but an inherited cache or wrong checkout supplies a different root or Ops source. [VERIFIED: 147-CONTEXT.md]

**How to avoid:** Pass fresh `MIX_DEPS_PATH` and `MIX_BUILD_PATH` to every command and compare `Mix.Project.deps_paths/0` values to canonical root/Ops paths. [CITED: https://mix.hexdocs.pm/Mix.Project.html]

**Warning signs:** Either dependency path is not the expected canonical repository directory, one environment override is absent, or lock hash changes during `--check-locked`. [VERIFIED: 147-CONTEXT.md]

### Pitfall 2: `precommit` hides resolver drift

**What goes wrong:** The existing alias runs `deps.unlock --unused` and `format`, allowing an unexplained lock mutation to be mistaken for normal validation. [VERIFIED: examples/scrypath_ecommerce/mix.exs]

**How to avoid:** Make pre/post manifest and lock hashes, `git diff --check`, formatted-file status, and source-scoped dirty baseline explicit gates. [VERIFIED: 147-CONTEXT.md]

### Pitfall 3: Conflating deterministic, service, and browser proof

**What goes wrong:** A skipped CI job, unavailable service, or non-exact candidate browser run gets recorded as pass. [VERIFIED: 147-CONTEXT.md]

**How to avoid:** Record `required_deterministic`, `required_service_prepare`, and `browser` separately; browser must be `passed`, `failed`, or `unavailable`, with `flake: true` on retry-only passes. [VERIFIED: 147-CONTEXT.md]

### Pitfall 4: Unsafe temporary-worktree cleanup

**What goes wrong:** A path spelling difference (`/var` vs `/private/var` on macOS), symlink, or stale worktree registration causes cleanup to target the wrong directory or leaves state behind. [VERIFIED: 146-03-SUMMARY.md]

**How to avoid:** Validate owned parent and exact child, non-symlink status, canonical registration equivalence, and uniqueness before deletion; always then prove absence and unchanged primary workspace baseline. [VERIFIED: 147-CONTEXT.md]

### Pitfall 5: Claiming four graph-local commits

**What goes wrong:** The final artifact contradicts the actual shared Req handoff and two documented test/recovery closures. [VERIFIED: 147-CONTEXT.md]

**How to avoid:** Call the unit of history an ordered remediation batch and list every constituent commit with its precise role. [VERIFIED: 147-CONTEXT.md]

## Code Examples

### Required ecommerce gate sequence

```sh
# From examples/scrypath_ecommerce, after recording source-scoped baseline.
mix deps.get --check-locked
mix run --no-start -e 'IO.inspect(Mix.Project.deps_paths())'
mix compile --warnings-as-errors
mix test test/scrypath_ecommerce_web/live/search_live_test.exs
mix precommit

# Required only when Postgres and Meilisearch health checks pass.
mix e2e.prepare
```

The planner must refine the focused test to the existing route/asset/link contract it inspects at planning time, preserve D-11’s diagnostic order, and propagate isolation variables in the actual receipt commands. `mix precommit` expands to warning-clean compile, unused-dependency unlock, formatting, and test in this application. [VERIFIED: examples/scrypath_ecommerce/mix.exs] [VERIFIED: 147-CONTEXT.md]

### Focused browser proof classification

```sh
# Existing, non-persistent CLI shape; server and services must already be healthy.
npx playwright test e2e/harness.spec.ts e2e/operator.spec.ts --workers=1
```

The harness asserts storefront navigation and mounted `/admin/search` pages; operator tests exercise failed-sync triage and index-swap paths. The configuration keeps traces on first retry in CI, so a retry-induced pass is classified as a flake rather than a clean pass. [VERIFIED: e2e/harness.spec.ts] [VERIFIED: e2e/operator.spec.ts] [VERIFIED: playwright.config.ts]

## State of the Art

| Old approach | Current approach | When Changed | Impact |
|---|---|---|---|
| Broad, possibly head-seeking compatibility upgrades | Fixed-compatible direct minor-line bounds and causal lock closure | Locked for Phase 147 | Limits dependency risk and makes every lock row explainable. [VERIFIED: 147-CONTEXT.md] |
| Generic standalone graph proof | Explicit mounted-root and mounted-Ops provenance plus isolated paths | Locked for Phase 147 | Validates the actual host integration rather than only dependency resolution. [VERIFIED: 147-CONTEXT.md] |
| Four graph-local commits wording | Four truthful ordered remediation batches | Locked for Phase 147 | Preserves historical integrity and satisfies EVID-02 without rewriting history. [VERIFIED: 147-CONTEXT.md] |

**Deprecated/outdated:** Treating a skipped/cancelled/unrelated-SHA browser job as pass is prohibited for this phase. [VERIFIED: 147-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | Planner and pattern-map inspection selected `examples/scrypath_ecommerce/test/scrypath_ecommerce_web/controllers/page_controller_test.exs` as the D-11 focused deterministic contract. | Code Examples | Resolved: the existing controller contract covers the mounted posture route, Ops CSS/host JS, nested mount links, and absence of storefront asset bleed. [VERIFIED: 147-01-PLAN.md] [VERIFIED: 147-PATTERNS.md] |

## Open Questions (RESOLVED)

1. **Which existing deterministic test is the narrowest complete D-11 route/asset/link contract?**
   - Resolution: Use `examples/scrypath_ecommerce/test/scrypath_ecommerce_web/controllers/page_controller_test.exs`, as selected by Plan 01 and confirmed by the pattern map. It is the existing fast deterministic contract that exercises the mounted posture route, verifies the Ops CSS and host JavaScript asset references, checks nested mounted links, and proves the storefront does not receive Ops asset bleed. [VERIFIED: 147-01-PLAN.md] [VERIFIED: 147-PATTERNS.md]
   - Execution consequence: Run that file in D-11's locked diagnostic order under the isolated Mix paths; no Wave 0 inspection task or new test is required. [VERIFIED: 147-01-PLAN.md] [VERIFIED: 147-VALIDATION.md]

## Environment Availability

| Dependency | Required By | Available | Version / state | Fallback |
|---|---|---|---|---|
| Elixir/Mix | Resolution and deterministic gates | ✓ | Elixir/Mix 1.19.5, OTP 28 | — [VERIFIED: local versions] |
| Git worktree | Exact-SHA post-commit proof | ✓ | Git 2.41.0 | — [VERIFIED: local `git --version`] |
| PostgreSQL | `mix e2e.prepare`, ecommerce test setup, browser E2E | ✓ | `pg_isready` accepts on `:5432` | Required service; no service-free substitute for preparation. [VERIFIED: local probe] |
| Meilisearch | `mix e2e.prepare`, browser E2E | ✓ | `/health` returns available | Required service; no service-free substitute for preparation. [VERIFIED: local probe] |
| Docker | Service troubleshooting/local runbook | ✓ | Docker Desktop client available | Existing native services are already healthy. [VERIFIED: local `docker info`] |
| Node/npm/npx | Playwright proof | ✓ | Node 22.14.0, npm 11.1.0, Playwright 1.60.0 | Browser evidence is `unavailable` if server/assets/browser prerequisites later fail. [VERIFIED: local versions] |

**Missing dependencies with no fallback:** None at research time. [VERIFIED: local probes]

**Missing dependencies with fallback:** None at research time. [VERIFIED: local probes]

## Validation Architecture

### Test Framework

| Property | Value |
|---|---|
| Framework | ExUnit/Phoenix test suite; Playwright for advisory browser proof. [VERIFIED: examples/scrypath_ecommerce/test; playwright.config.ts] |
| Config file | `examples/scrypath_ecommerce/mix.exs`; `playwright.config.ts`. [VERIFIED: files] |
| Quick run command | `cd examples/scrypath_ecommerce && mix test <focused-existing-test>` after planner inspection. [ASSUMED] |
| Full ecommerce suite | `cd examples/scrypath_ecommerce && mix precommit`. [VERIFIED: examples/scrypath_ecommerce/mix.exs] |
| Root suite | `mix compile --warnings-as-errors && mix test --exclude integration --exclude docs_contract --include requires_clean_workspace && mix verify --exclude integration && mix verify.phase11 && mix verify.phase99`. [VERIFIED: CONTRIBUTING.md] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|---|---|---|---|---|
| SEC-04 | Ecommerce resolves approved bounds, consumes mounted sources, and has no unsuppressed audit result. | resolver/integration | Isolated `mix deps.get`, range assertion, `Mix.Project.deps_paths/0`, `mix hex.audit`. | ❌ Wave 0 receipt script/commands only [VERIFIED: 147-CONTEXT.md] |
| COMPAT-01 | Ecommerce deterministic checks and root release gates pass in sequence. | integration/regression | Ecommerce `mix compile --warnings-as-errors`, focused existing test, `mix precommit`; named root commands. | ✅ existing commands [VERIFIED: mix.exs; CONTRIBUTING.md] |
| COMPAT-03 | Mounted browser evidence is truthful and separate from deterministic proof. | browser/manual classification | `npx playwright test e2e/harness.spec.ts e2e/operator.spec.ts --workers=1`; record classification. | ✅ specs/config [VERIFIED: e2e specs; playwright.config.ts] |
| EVID-01 | Four dated graph rows state checked-lock/audit outcome and selected versions. | evidence | `mix deps.get --check-locked && mix hex.audit` in root, legacy, Ops, ecommerce. | ❌ Wave 0 compact ledger [VERIFIED: 147-CONTEXT.md] |
| EVID-02 | History and ecommerce diff prove minimal ordered remediation batches. | repository/evidence | `git diff`, `git diff-tree`, `git merge-base --is-ancestor`, hashes. | ❌ Wave 0 topology ledger [VERIFIED: 147-CONTEXT.md] |

### Sampling Rate

- **Per implementation edit:** Inspect ecommerce manifest/lock diff, run isolated checked lock and path receipt. [VERIFIED: 147-CONTEXT.md]
- **Before ecommerce commit:** Complete D-11, D-12, D-13, and D-14 gates, then stop on any drift/failure. [VERIFIED: 147-CONTEXT.md]
- **After ecommerce commit:** Run the exact-SHA detached proof and cleanup validation; then capture all-four same-window closure rows. [VERIFIED: 147-CONTEXT.md]
- **Phase gate:** All required deterministic and service evidence pass; browser is accurately classified; no unsuppressed audit, unsafe cleanup, or protected-user-file drift remains. [VERIFIED: 147-CONTEXT.md]

### Wave 0 Gaps

- [ ] A non-persistent receipt/command block that exports both isolation variables to every ecommerce proof command. [VERIFIED: 147-CONTEXT.md]
- [ ] A compact redacted four-graph closure matrix and ordered-batch topology ledger in phase evidence. [VERIFIED: 147-CONTEXT.md]
- [ ] Planner inspection that selects the exact existing focused route/asset/link test; no speculative test creation. [ASSUMED]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | No | No authentication implementation changes. [VERIFIED: 147-CONTEXT.md] |
| V3 Session Management | No | No session implementation changes. [VERIFIED: 147-CONTEXT.md] |
| V4 Access Control | No | Mounted routes are regression-tested only; no authorization behavior changes. [VERIFIED: 147-CONTEXT.md] |
| V5 Input Validation | No new control | Existing tests only; phase changes dependency constraints/evidence, not request handling. [VERIFIED: 147-CONTEXT.md] |
| V6 Cryptography | No | Do not hand-roll crypto; no cryptographic change is in scope. [VERIFIED: AGENTS.md] |
| V14 Configuration | Yes | Isolate candidate builds, verify locked resolutions, preserve exact mounted sources, and redact credentials/temp state. [VERIFIED: 147-CONTEXT.md] |

### Known Threat Patterns for this phase

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Vulnerable or unintended dependency selection | Tampering / elevation of privilege | Approved bounds, causal lock diff, fresh range assertion, unsuppressed `mix hex.audit`. [VERIFIED: 147-CONTEXT.md] |
| Wrong mounted local source | Tampering | Canonical `Mix.Project.deps_paths/0` assertion with fresh isolated paths. [CITED: https://mix.hexdocs.pm/Mix.Project.html] |
| Evidence misrepresentation | Repudiation | Exact SHA/window/tool versions/lock hashes plus explicit browser state and historical proof references. [VERIFIED: 147-CONTEXT.md] |
| Unsafe workspace cleanup | Tampering / denial of service | Owned non-symlink parent/child and worktree-registration checks before removal; post-cleanup baseline proof. [VERIFIED: 147-CONTEXT.md] |
| Leakage through receipts | Information disclosure | Exclude credentials, raw logs, temporary paths, generated service/browser state, and disposable locks. [VERIFIED: 147-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)

- `147-CONTEXT.md` — locked dependency bounds, proof ordering, classification, ledger, topology, and stop conditions.
- `examples/scrypath_ecommerce/mix.exs` — current constraints and aliases.
- `examples/scrypath_ecommerce/e2e/*.spec.ts` and `playwright.config.ts` — existing focused browser surface and retry/report behavior.
- `146-03-SUMMARY.md`, `146-04-SUMMARY.md`, and `146-VERIFICATION.md` — exact-SHA Ops handoff and cleanup precedent.
- `CONTRIBUTING.md` — named root release-train gates and advisory `phase105-e2e` posture.

### Secondary (MEDIUM confidence)

- [Mix.Project documentation](https://mix.hexdocs.pm/Mix.Project.html) — `deps_paths/0` and path-dependency API semantics.
- [Mix deps.get documentation](https://hexdocs.pm/mix/Mix.Tasks.Deps.Get.html) — `--check-locked` behavior.
- [Git worktree documentation](https://git-scm.com/docs/git-worktree) — detached worktrees and removal behavior.

### Tertiary (LOW confidence)

- None; the one planning selection uncertainty is recorded in the Assumptions Log.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — all tools and phase surfaces are existing repository/local environment facts.
- Architecture: HIGH — locked context fixes the proof topology and existing source confirms the integration seams.
- Pitfalls: HIGH — D-10 through D-28 and Phase 146’s actual cleanup deviation provide direct evidence.

**Research date:** 2026-08-25
**Valid until:** 2026-09-01, because dependency registry and advisory state are fast-moving; repeat all dated resolution/audit proof during execution.
