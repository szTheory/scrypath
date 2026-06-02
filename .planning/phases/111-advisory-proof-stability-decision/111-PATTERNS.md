# Phase 111: Advisory Proof Stability Decision - Pattern Map

**Mapped:** 2026-05-31
**Files analyzed:** 5
**Analogs found:** 5 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.github/workflows/ci.yml` | config | event-driven | `.github/workflows/ci.yml` | exact |
| `CONTRIBUTING.md` | config | request-response | `CONTRIBUTING.md` | exact |
| `test/mix/tasks/workflow_wiring_test.exs` | test | transform | `test/mix/tasks/workflow_wiring_test.exs` | exact |
| `test/scrypath/phase111_contract_test.exs` | test | transform | `test/scrypath/phase108_contract_test.exs` | role-match |
| `scripts/ci/phase105_evidence.sh` (optional) | utility | batch | existing shell blocks in `.github/workflows/ci.yml` | partial |

## Pattern Assignments

### `.github/workflows/ci.yml` (config, event-driven)

**Analog:** `.github/workflows/ci.yml` (exact lane + artifact + service pattern)

**Trigger + lean-gate topology pattern** (lines 3-10, 19-20, 49-50, 79-80, 105-106):
```yaml
on:
  push:
    branches:
      - main
  pull_request:
  workflow_dispatch:
  schedule:
    - cron: "37 6 * * *"

jobs:
  main-ci:
  repo-hygiene:
  release-truth:
  phase99-trust:
```

**Phase105 advisory lane structure** (lines 541-568):
```yaml
phase105-e2e:
  runs-on: ubuntu-latest
  timeout-minutes: 20
  services:
    postgres:
      image: postgres:16-alpine
    meilisearch:
      image: getmeili/meilisearch:v1.15
  env:
    MIX_ENV: test
    PGPORT: "5433"
    SCRYPATH_MEILISEARCH_URL: http://127.0.0.1:7700
    PLAYWRIGHT_BASE_URL: http://127.0.0.1:4002
```

**Bounded readiness + failure-artifact pattern** (lines 587-607, 630-640, 646-655):
```yaml
- name: Wait for Postgres
  run: |
    for _ in $(seq 1 60); do
      if pg_isready -h 127.0.0.1 -p "$PGPORT" -U postgres; then
        exit 0
      fi
      sleep 1
    done
    echo "Postgres failed to become ready"
    exit 1

- name: Upload phase105-e2e failure artifacts
  if: failure()
  uses: actions/upload-artifact@v7
  with:
    name: phase105-e2e-artifacts
    path: |
      /tmp/phase105-e2e-phx.log
      examples/scrypath_ecommerce/playwright-report
      examples/scrypath_ecommerce/test-results
```

**Confidence:** High

---

### `CONTRIBUTING.md` (config, request-response)

**Analog:** `CONTRIBUTING.md` (exact policy/docs contract style)

**CI job table + gate wording pattern** (lines 80-99):
```markdown
| **`main-ci`** | Required merge gate: ... |
| **`repo-hygiene`** | Required merge gate: ... |
| **`release-truth`** | Required merge gate: ... |
| **`phase99-trust`** | Required merge gate: ... |
| **`phase105-e2e`** | Advisory browser lane ... uploads failure artifacts ... |

Treat **`main-ci`**, **`repo-hygiene`**, **`release-truth`**, and **`phase99-trust`**
as the routine required merge gate blockers...
```

**Advisory runbook + promotion criteria pattern** (lines 107-137):
```markdown
`phase105-e2e` is advisory today (not a required merge gate).

### Promotion criteria
- Stable job name remains `phase105-e2e`.
- Sustained low flake rate across PR and scheduled runs.
- Runtime stays bounded enough for PR feedback.
- Failure artifacts remain actionable (`playwright-report`, `test-results`, Phoenix log).
- Lane owners respond to failures before required-check escalation.
- Trigger rules stay explicit...
```

**Confidence:** High

---

### `test/mix/tasks/workflow_wiring_test.exs` (test, transform)

**Analog:** `test/mix/tasks/workflow_wiring_test.exs` (exact workflow/docs parity test style)

**File-read and token assertion pattern** (lines 10-12, 223-230):
```elixir
test "ci.yml quality job runs mix verify" do
  assert File.read!(@ci_yml) =~ "mix verify"
end

test "contributing required-check contract includes phase99-trust" do
  contributing = File.read!("CONTRIBUTING.md")
  assert contributing =~ "**`main-ci`**"
  assert contributing =~ "**`repo-hygiene`**"
  assert contributing =~ "**`release-truth`**"
  assert contributing =~ "**`phase99-trust`**"
end
```

**Ordered-proof assertion pattern** (lines 57-65):
```elixir
assert_ordered_steps(yml, [
  "mix verify.workspace_clean",
  "mix verify.phase11",
  "mix hex.publish --dry-run --yes",
  "mix hex.publish --yes"
])
```

**Negative drift guard pattern** (lines 236-247):
```elixir
refute contributing =~ "mix verify.phase100"
refute ci =~ "mix verify.phase100"
refute contributing =~ "mix verify.phase101"
refute ci =~ "mix verify.phase101"
```

**Confidence:** High

---

### `test/scrypath/phase111_contract_test.exs` (test, transform)

**Analog:** `test/scrypath/phase108_contract_test.exs` (same phase contract approach)

**Static truth-surface module attributes pattern** (lines 6-14):
```elixir
@roadmap File.read!(".planning/ROADMAP.md")
@requirements File.read!(".planning/REQUIREMENTS.md")
@project File.read!(".planning/PROJECT.md")
@contributing File.read!("CONTRIBUTING.md")
@ci_workflow File.read!(".github/workflows/ci.yml")
```

**Contains/absent helper + reusable assertions pattern** (lines 103-113):
```elixir
defp assert_contains_all(content, tokens) do
  Enum.each(tokens, fn token -> assert content =~ token end)
end

defp assert_absent_all(content, tokens) do
  Enum.each(tokens, fn token -> refute content =~ token end)
end
```

**Order-check helper pattern** (lines 115-121):
```elixir
defp ordered?(content, first, second) do
  first_index = :binary.match(content, first)
  second_index = :binary.match(content, second)
  match?({_, _}, first_index) and match?({_, _}, second_index) and
    elem(first_index, 0) < elem(second_index, 0)
end
```

**Confidence:** High

---

### `scripts/ci/phase105_evidence.sh` (optional utility, batch)

**Analog:** shell wait loops embedded in `.github/workflows/ci.yml` (lines 271-280, 321-330, 440-449, 598-607)

**Portable bounded polling pattern**:
```bash
for _ in $(seq 1 60); do
  if curl --silent --fail "$SCRYPATH_MEILISEARCH_URL/health" >/dev/null; then
    exit 0
  fi
  sleep 1
done
echo "Meilisearch failed to become ready"
exit 1
```

**Note:** No existing `scripts/ci/*` file currently exists; keep utility style minimal, shell-first, and explicit.

**Confidence:** Medium

## Shared Patterns

### Required vs advisory gate split
**Sources:** `CONTRIBUTING.md` lines 84-99, `.github/workflows/ci.yml` job list  
**Apply to:** `CONTRIBUTING.md`, `test/mix/tasks/workflow_wiring_test.exs`, `test/scrypath/phase111_contract_test.exs`
```text
Required blockers stay: main-ci, repo-hygiene, release-truth, phase99-trust.
phase105-e2e remains advisory until evidence thresholds are met.
```

### Actionable artifact discipline
**Source:** `.github/workflows/ci.yml` lines 646-655  
**Apply to:** `.github/workflows/ci.yml`, docs + contract tests
```yaml
if: failure()
uses: actions/upload-artifact@v7
with:
  name: phase105-e2e-artifacts
  path: [phoenix log, playwright-report, test-results]
```

### Retry-as-flake semantics
**Source:** `examples/scrypath_ecommerce/playwright.config.ts` lines 6-12  
**Apply to:** docs and evidence-classification checks
```ts
retries: process.env.CI ? 1 : 0
trace: "on-first-retry"
```

### Docs/workflow contract testing
**Sources:** `test/mix/tasks/workflow_wiring_test.exs`, `test/scrypath/phase108_contract_test.exs`  
**Apply to:** new `phase111` assertions
```elixir
assert File.read!(@ci_yml) =~ "phase105-e2e"
assert File.read!("CONTRIBUTING.md") =~ "advisory"
refute File.read!(@ci_yml) =~ "<new required gate drift>"
```

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `scripts/ci/phase105_evidence.sh` (optional) | utility | batch | No existing `scripts/ci` helper file in repo; use workflow shell-step patterns as nearest analog. |

## Metadata

**Analog search scope:** `.github/workflows`, `CONTRIBUTING.md`, `test/mix/tasks`, `test/scrypath`, `examples/scrypath_ecommerce`  
**Files scanned:** 7  
**Pattern extraction date:** 2026-05-31
