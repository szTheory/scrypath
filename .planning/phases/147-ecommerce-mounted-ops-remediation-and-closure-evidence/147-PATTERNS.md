# Phase 147: Ecommerce Mounted-Ops Remediation and Closure Evidence - Pattern Map

**Mapped:** 2026-08-25  
**Files analyzed:** 3 planned surfaces (2 implementation files; 1 compact evidence surface)  
**Analogs found:** 3 / 3

## Scope and Preservation Boundary

The only planned source changes are the approved direct dependency declarations in
`examples/scrypath_ecommerce/mix.exs` and their solver-generated causal closure in
`examples/scrypath_ecommerce/mix.lock`. Existing route/asset/link tests, browser
specs, runtime configuration, Mix tasks, CI, root code, and ScrypathOps are
regression/evidence references only. Do not add a direct Plug, Mint, hpax, Finch,
Ecto, or Decimal declaration; do not add an override; do not add a new test, script,
or permanent proof subsystem.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `examples/scrypath_ecommerce/mix.exs` | config | transform (declarations -> solver constraints) | `scrypath_ops/mix.exs` and Phase 146’s assignment | exact role / exact dependency cohort |
| `examples/scrypath_ecommerce/mix.lock` | config | transform (solver output -> deterministic resolution) | `scrypath_ops/mix.lock` and `146-PATTERNS.md` | exact role / same remediation workflow |
| `.planning/phases/147-ecommerce-mounted-ops-remediation-and-closure-evidence/147-VALIDATION.md` and task summaries | config / evidence report | batch | `145-02-SUMMARY.md` and `146-03-SUMMARY.md` | exact evidence-report role |

## Pattern Assignments

### `examples/scrypath_ecommerce/mix.exs` (config, transform)

**Analog:** `scrypath_ops/mix.exs`, as assigned in
[`146-PATTERNS.md:22`](/Users/jon/projects/scrypath/.planning/phases/146-scrypathops-web-client-remediation/146-PATTERNS.md:22).

**Existing dependency-list pattern** ([`examples/scrypath_ecommerce/mix.exs:34`](/Users/jon/projects/scrypath/examples/scrypath_ecommerce/mix.exs:34)):

```elixir
defp deps do
  [
    {:scrypath, path: "../.."},
    {:scrypath_ops, path: "../../scrypath_ops"},
    {:phoenix, "~> 1.8.5"},
    {:phoenix_ecto, "~> 4.5"},
    {:ecto_sql, "~> 3.13"},
    {:postgrex, ">= 0.0.0"},
    {:oban, "~> 2.21"},
    {:phoenix_live_view, "~> 1.1.0"},
    {:swoosh, "~> 1.16"},
    {:req, "~> 0.6.1"},
    {:bandit, "~> 1.5"}
  ]
end
```

Replace only Phoenix, LiveView, Bandit, Swoosh, and Postgrex requirement strings
with `~> 1.8.9`, `~> 1.1.33`, `~> 1.12.1`, `~> 1.26.3`, and `~> 0.22.4`.
Retain Req `~> 0.6.1`, both path dependencies, `phoenix_ecto`, Ecto SQL, Oban,
and every unrelated dependency exactly as-is. This mirrors the completed cohort
prescription in [`146-PATTERNS.md:49`](/Users/jon/projects/scrypath/.planning/phases/146-scrypathops-web-client-remediation/146-PATTERNS.md:49)-[`146-PATTERNS.md:60`](/Users/jon/projects/scrypath/.planning/phases/146-scrypathops-web-client-remediation/146-PATTERNS.md:60).

**Alias/mutation pattern** ([`examples/scrypath_ecommerce/mix.exs:60`](/Users/jon/projects/scrypath/examples/scrypath_ecommerce/mix.exs:60)):

```elixir
"e2e.prepare": ["ecto.create --quiet", "ecto.migrate --quiet", "e2e.prepare_search"],
test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
precommit: ["compile --warnings-as-errors", "deps.unlock --unused", "format", "test"]
```

Treat `precommit` as a mutating existing gate, not as the initial lock proof. Hash
the ecommerce lock and record manifest/lock/source-scoped status before it, run the
diagnostic gate sequence, then require the post-precommit lock hash, explained diff,
format status, and dirty baseline to match the expected state.

### `examples/scrypath_ecommerce/mix.lock` (config, transform)

**Analog:** `scrypath_ops/mix.lock` causal-closure assignment in
[`146-PATTERNS.md:62`](/Users/jon/projects/scrypath/.planning/phases/146-scrypathops-web-client-remediation/146-PATTERNS.md:62).

**Causal lock-review pattern** ([`146-PATTERNS.md:66`](/Users/jon/projects/scrypath/.planning/phases/146-scrypathops-web-client-remediation/146-PATTERNS.md:66)):

```markdown
- Changed only the planned direct requirements.
- Refreshed only their causal lock closure: direct package dependents and required
  transitives.
- Retained the prior Req/Mint/hpax handoff unchanged when already compliant.
```

Do not hand-edit Hex tuples or checksums. Let Mix solve after the six approved direct
bounds are set, enumerate and explain each changed row, and then prove the reviewed
lock with `mix deps.get --check-locked`. The primary lock must remain byte-identical
through all proof commands; only the detached worktree’s disposable lock may be
removed for lockless resolution.

**Range-matrix pattern** ([`146-03-SUMMARY.md:54`](/Users/jon/projects/scrypath/.planning/phases/146-scrypathops-web-client-remediation/146-03-SUMMARY.md:54)):

```elixir
lock = Mix.Dep.Lock.read()

Enum.each([
  {:phoenix, ">= 1.8.9 and < 1.9.0"},
  {:phoenix_live_view, ">= 1.1.33 and < 1.2.0"},
  {:bandit, ">= 1.12.1 and < 1.13.0"},
  {:swoosh, ">= 1.26.3 and < 1.27.0"},
  {:postgrex, ">= 0.22.4 and < 0.23.0"},
  {:req, ">= 0.6.1 and < 0.7.0"},
  {:plug, ">= 1.19.5 and < 2.0.0"},
  {:mint, ">= 1.9.3"},
  {:hpax, ">= 1.0.4"}
], fn {dep, requirement} ->
  version = lock |> Map.fetch!(dep) |> elem(2)
  Version.match?(version, requirement) || raise "#{dep} #{version} violates #{requirement}"
end)
```

Run this only against the fresh disposable ecommerce resolution. It is a receipt
command, not a committed Mix task.

### Phase evidence receipts (config / evidence report, batch)

**Analog:** [`145-02-SUMMARY.md:1`](/Users/jon/projects/scrypath/.planning/phases/145-legacy-phoenix-and-ecto-decimal-remediation/145-02-SUMMARY.md:1) and
[`146-03-SUMMARY.md:45`](/Users/jon/projects/scrypath/.planning/phases/146-scrypathops-web-client-remediation/146-03-SUMMARY.md:45).

Use compact front matter plus sections for environment, deterministic gates,
exact-SHA fresh proof, cleanup/preservation, browser classification, and topology.
Record commands and exit statuses—not raw command output, temporary paths, fresh
locks, dependency trees, advisory snapshots, credentials, or browser/service state.

**Evidence-table pattern** ([`145-02-SUMMARY.md:75`](/Users/jon/projects/scrypath/.planning/phases/145-legacy-phoenix-and-ecto-decimal-remediation/145-02-SUMMARY.md:75)):

```markdown
## Verification Evidence

### Environment

| Item | Value |
| --- | --- |
| UTC evidence window | ... |
| Elixir / OTP | ... |
| Mix / Hex | ... |

### Deterministic Recovery Gates

| Command | Exit | Classification |
| --- | --- | --- |
| `mix deps.get --check-locked` | 0 | deterministic checked lock |
```

For Phase 147, add a single four-graph same-window matrix containing candidate SHA,
UTC window, OS/tool versions, each tracked lock SHA-256, checked-lock and
unsuppressed-audit outcomes, relevant selected versions, and the root/legacy/Ops
historical fresh-proof references. Keep `required_deterministic`,
`required_service_prepare`, and browser evidence separate; browser is only
`passed`, `failed`, or `unavailable`, with `flake: true` for retry-only passes.

**Detached-worktree cleanup pattern** ([`146-03-SUMMARY.md:67`](/Users/jon/projects/scrypath/.planning/phases/146-scrypathops-web-client-remediation/146-03-SUMMARY.md:67)):

```markdown
- Raw receipt validation: PASS — owned, non-symlink parent and exact worktree child
  passed prefix and exact-child checks before and immediately before cleanup.
- Canonical registration validation: PASS — the validated path and exactly one
  registered worktree canonicalize to the same location.
- Disposable worktree and isolated Mix state: removed and absence-checked.
- Primary lock and dirty-baseline equality: PASS.
```

For the ecommerce candidate, require those checks both before and during cleanup;
use `git worktree remove` only after validation. Preserve the user-owned untracked
`.planning/v1.36-v1.36-MILESTONE-AUDIT.md` in the hashed dirty baseline and never
stage, edit, or delete it.

## Shared Patterns

### Mounted-source provenance

**Sources:** [`examples/scrypath_ecommerce/mix.exs:34`](/Users/jon/projects/scrypath/examples/scrypath_ecommerce/mix.exs:34), [`147-RESEARCH.md:214`](/Users/jon/projects/scrypath/.planning/phases/147-ecommerce-mounted-ops-remediation-and-closure-evidence/147-RESEARCH.md:214)

```sh
MIX_DEPS_PATH="$proof_parent/deps" MIX_BUILD_PATH="$proof_parent/build" \
  mix run --no-start -e '
    paths = Mix.Project.deps_paths()
    expected = %{scrypath: Path.expand("../.."), scrypath_ops: Path.expand("../../scrypath_ops")}
    Map.take(paths, Map.keys(expected)) == expected || System.halt(1)
  '
```

Pass both variables to every ecommerce fetch, path assertion, compile, focused test,
precommit, and preparation command. Canonicalize expected and actual paths before
comparison; compilation alone is insufficient provenance proof.

### Focused mounted route/asset/link regression

**Source:** [`page_controller_test.exs:9`](/Users/jon/projects/scrypath/examples/scrypath_ecommerce/test/scrypath_ecommerce_web/controllers/page_controller_test.exs:9)

```elixir
test "GET /admin/search/posture", %{conn: conn} do
  conn = get(conn, ~p"/admin/search/posture")
  html = html_response(conn, 200)

  assert html =~ ~s(href="/admin/search/assets/css/app.css")
  assert html =~ ~s(href="/admin/search/failed-sync")
  refute html =~ ~s(href="/search/failed-sync")
end
```

Run this existing test file as the D-11 focused deterministic contract. Its remaining
tests also prove nested mount links and that the storefront does not receive the Ops
stylesheet ([`page_controller_test.exs:22`](/Users/jon/projects/scrypath/examples/scrypath_ecommerce/test/scrypath_ecommerce_web/controllers/page_controller_test.exs:22)).

### Focused browser classification

**Sources:** [`harness.spec.ts:7`](/Users/jon/projects/scrypath/examples/scrypath_ecommerce/e2e/harness.spec.ts:7), [`operator.spec.ts:11`](/Users/jon/projects/scrypath/examples/scrypath_ecommerce/e2e/operator.spec.ts:11), [`playwright.config.ts:3`](/Users/jon/projects/scrypath/examples/scrypath_ecommerce/playwright.config.ts:3)

```sh
npx playwright test e2e/harness.spec.ts e2e/operator.spec.ts --workers=1
```

The config uses one CI retry and `trace: "on-first-retry"`; a later pass after a
first-attempt failure is flake evidence, never a clean pass. Reuse generated reports
only as external diagnostic artifacts; do not commit them.

### Required root release train

**Source:** [`CONTRIBUTING.md:85`](/Users/jon/projects/scrypath/CONTRIBUTING.md:85)

After ecommerce-local gates pass, retain this exact root bundle:

```sh
mix compile --warnings-as-errors
mix test --exclude integration --exclude docs_contract --include requires_clean_workspace
mix verify --exclude integration
mix verify.phase11
mix verify.phase99
```

Do not run `mix verify.opsui` by default: it remains Phase 146-owned unless an
Ops-owned source/manifest/lock/contract changes or mounted proof identifies an
Ops-owned regression.

## No Analog Found

None. The phase introduces no permanent source test, browser harness, CI workflow,
or proof subsystem. Its temporary receipt commands follow the completed Phase 146
detached-worktree pattern and belong only in execution/evidence artifacts.

## Metadata

**Analog search scope:** `examples/scrypath_ecommerce/`, root contributor gates,
Phase 145/146 evidence and pattern artifacts, and `scripts/ci/phase105_evidence.sh`  
**Files scanned:** 12 primary analog/reference files  
**Pattern extraction date:** 2026-08-25
