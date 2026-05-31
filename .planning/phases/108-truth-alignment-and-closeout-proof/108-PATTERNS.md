# Phase 108: truth-alignment-and-closeout-proof - Pattern Map

**Mapped:** 2026-05-31  
**Files analyzed:** 10  
**Analogs found:** 10 / 10

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/mix/tasks/verify.phase108.ex` | utility | batch | `lib/mix/tasks/verify.phase106.ex` | exact |
| `test/mix/tasks/verify.phase108_test.exs` | test | request-response | `test/mix/tasks/verify.phase106_test.exs` | exact |
| `test/scrypath/phase108_contract_test.exs` | test | transform | `test/scrypath/phase99_contract_test.exs` | role-match |
| `mix.exs` | config | transform | `mix.exs` (`cli.preferred_envs`) | exact |
| `guides/related-data-and-reindexing.md` | config | transform | same file (existing contract wording structure) | exact |
| `docs/jtbd-gap-map.md` | config | transform | same file (current v1.29 closeout framing) | exact |
| `.planning/ROADMAP.md` | config | transform | same file (phase detail + progress sections) | exact |
| `.planning/REQUIREMENTS.md` | config | transform | same file (requirement + out-of-scope tables) | exact |
| `.planning/PROJECT.md` | config | transform | same file (milestone closeout status blocks) | exact |
| `CONTRIBUTING.md` | config | transform | same file (required vs advisory CI posture table) | exact |

## Pattern Assignments

### `lib/mix/tasks/verify.phase108.ex` (utility, batch)

**Analog:** `lib/mix/tasks/verify.phase106.ex` (lines 1-34), with optional marker/doc-build behavior from `lib/mix/tasks/verify.phase99.ex` (lines 13-33)

**Imports/module skeleton pattern**:
```elixir
defmodule Mix.Tasks.Verify.Phase106 do
  @moduledoc false
  use Mix.Task
```

**Core focused-tests + run contract**:
```elixir
  @focused_tests [
    "test/scrypath/schema_test.exs",
    "test/scrypath/sync/related_test.exs",
    "test/scrypath/sync/related_worker_test.exs",
    "test/mix/tasks/verify.phase106_test.exs"
  ]

  def run(args) do
    ensure_no_args!(args)
    Mix.Task.run("app.start")
    Mix.shell().info("==> verify.phase106: fan-out reflection contract checks")
    run_test!(@focused_tests, "Phase 106 fan-out reflection contract verification")
  end
```

**Error handling pattern**:
```elixir
  defp ensure_no_args!(args) do
    Mix.raise("verify.phase106 does not accept arguments, got: #{Enum.join(args, " ")}")
  end
```

### `test/mix/tasks/verify.phase108_test.exs` (test, request-response)

**Analog:** `test/mix/tasks/verify.phase106_test.exs` (lines 1-38)

**Argument-contract test pattern**:
```elixir
test "verify.phase106 does not accept arguments" do
  assert_raise Mix.Error, ~r/verify\.phase106 does not accept arguments, got: stray/, fn ->
    Mix.Task.reenable("verify.phase106")
    Mix.Task.run("verify.phase106", ["stray"])
  end
end
```

**Help marker + source-wiring pattern**:
```elixir
output =
  capture_io(fn ->
    Mix.Task.reenable("help")
    Mix.Task.run("help", ["verify.phase106"])
  end)

assert output =~ "verify.phase106"
assert output =~ "There is no documentation for this task"

source = File.read!("lib/mix/tasks/verify.phase106.ex")
assert source =~ ~S|"test/mix/tasks/verify.phase106_test.exs"|
```

### `test/scrypath/phase108_contract_test.exs` (test, transform)

**Analog:** `test/scrypath/phase99_contract_test.exs` (lines 1-220; helpers at lines 277+)

**File-load and module-tag pattern**:
```elixir
defmodule Scrypath.Phase99ContractTest do
  use ExUnit.Case, async: true
  @moduletag :phase99_contract

  @readme File.read!("README.md")
  @contributing File.read!("CONTRIBUTING.md")
  @mix_exs File.read!("mix.exs")
```

**Token-anchor assertion pattern**:
```elixir
assert_contains_all(@contributing, [
  "**`main-ci`**",
  "**`repo-hygiene`**",
  "**`release-truth`**",
  "**`phase99-trust`**"
])

assert ordered?(@contributing, "**`main-ci`**", "**`repo-hygiene`**")
```

**Presence/absence drift-guard pattern**:
```elixir
assert_contains_all(@support_guide, [~S|{:scrypath, "~> 0.3"}|])
assert_absent_all(@support_guide, [~S|{:scrypath, "~> 1.0"}|])
```

### `mix.exs` (config, transform)

**Analog:** `mix.exs` `cli.preferred_envs` block (lines 37-82)

**Preferred env wiring pattern**:
```elixir
def cli do
  [
    preferred_envs: [
      "verify.phase99": :test,
      "verify.phase106": :test,
      "verify.phase107": :test,
      ...
    ]
  ]
end
```

### `CONTRIBUTING.md` (config, transform)

**Analog:** existing CI and verification posture table (lines 78-96; advisory section lines 103-124)

**Required-vs-advisory wording pattern**:
```markdown
| **`phase105-e2e`** | Advisory browser lane ... |

Treat **`main-ci`**, **`repo-hygiene`**, **`release-truth`**, and **`phase99-trust`** as the routine required merge gate blockers...
```

### `guides/related-data-and-reindexing.md` (config, transform)

**Analog:** existing ordinary-path + explicit footgun warning style (around lines 146-221)

**Semantics-first wording pattern**:
```markdown
`opts[:fan_out]` is **required** ...
`sync_related/3` raises `ArgumentError` if it is absent.

... `:oban` returns `status: :accepted` (the job is queued and will run later).
```

**Inline-vs-Oban resolver contract pattern**:
```markdown
- inline path passes records
- oban path passes document IDs
- resolver must handle both shapes
```

### `docs/jtbd-gap-map.md` (config, transform)

**Analog:** existing bounded-v1.29 ranking + diminishing-returns framing (lines 44-60, 171-205)

**Closeout truth pattern**:
```markdown
The active v1.29 work is bounded contract repair and proof hardening, not feature breadth...
```

**Maintenance/evidence prioritization pattern**:
```markdown
... release and adoption evidence matter more than feature breadth.
```

### `.planning/ROADMAP.md` (config, transform)

**Analog:** existing phase detail section style (lines 40-65)

**Phase detail pattern**:
```markdown
### Phase 108: ...
**Goal:** ...
**Depends on:** ...
**Requirements:** ...
**Success Criteria** ...
```

### `.planning/REQUIREMENTS.md` (config, transform)

**Analog:** requirement checklists + explicit out-of-scope table (lines 19-47)

**Requirement + exclusion pattern**:
```markdown
- [ ] **TRUTH-01**: ...

| Feature | Reason |
|---------|--------|
| ... | ... |
```

### `.planning/PROJECT.md` (config, transform)

**Analog:** shipped status blocks and next-milestone posture (lines 62-75, 121-127, 142-143)

**Closeout status pattern**:
```markdown
**v1.29 Phase 106 ... completed on ...**
**What shipped:**
- ...
```

**Post-closeout boundary pattern**:
```markdown
... bounded repair closeout, not a new feature lane.
```

## Shared Patterns

### Focused Service-Free Phase Gate
**Source:** `lib/mix/tasks/verify.phase106.ex:7-33`, `lib/mix/tasks/verify.phase99.ex:13-33`  
**Apply to:** `lib/mix/tasks/verify.phase108.ex`
```elixir
ensure_no_args!(args)
Mix.Task.run("app.start")
Mix.Task.reenable("test")
Mix.Task.run("test", @focused_tests)
```

### Verify Task Contract Testing
**Source:** `test/mix/tasks/verify.phase106_test.exs:6-37`  
**Apply to:** `test/mix/tasks/verify.phase108_test.exs`
```elixir
assert_raise Mix.Error, ~r/verify\.phase106 does not accept arguments, got: stray/, fn -> ... end
output =~ "verify.phase106"
source = File.read!("lib/mix/tasks/verify.phase106.ex")
```

### Token/Anchor Drift Assertions (Non-brittle)
**Source:** `test/scrypath/phase99_contract_test.exs:21-118,145-210,277-291`  
**Apply to:** `test/scrypath/phase108_contract_test.exs`
```elixir
assert_contains_all(...)
assert_absent_all(...)
assert ordered?(...)
```

### Required vs Advisory CI Posture Guard
**Source:** `CONTRIBUTING.md:82-96,103-105`, `test/scrypath/phase99_contract_test.exs:99-118`  
**Apply to:** Phase 108 truth assertions + any CONTRIBUTING edits
```markdown
required: `main-ci`, `repo-hygiene`, `release-truth`, `phase99-trust`
advisory: `phase105-e2e`
```

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| (none) | — | — | All target files have direct or strong role-match analogs. |

## Non-Blocking Gaps

- `test/scrypath/phase106_contract_test.exs` and `test/scrypath/phase107_contract_test.exs` are referenced in phase research narrative but do not exist in the repo; closest real contract-test analog is `test/scrypath/phase99_contract_test.exs`.

## Metadata

**Analog search scope:** `lib/mix/tasks`, `test/mix/tasks`, `test/scrypath`, `guides`, `docs`, `.planning`, root docs/config  
**Files scanned:** 18  
**Pattern extraction date:** 2026-05-31
