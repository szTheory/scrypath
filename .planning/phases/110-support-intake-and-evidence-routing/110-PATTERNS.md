# Phase 110: support-intake-and-evidence-routing - Pattern Map

**Mapped:** 2026-05-31  
**Files analyzed:** 10  
**Analogs found:** 10 / 10

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `test/scrypath/phase110_contract_test.exs` | test | transform | `test/scrypath/phase99_contract_test.exs` | exact |
| `lib/mix/tasks/verify.adopter.ex` | utility | batch | `lib/mix/tasks/verify.adopter.ex` | exact |
| `test/mix/tasks/verify_adopter_test.exs` | test | batch | `test/mix/tasks/verify_adopter_test.exs` | exact |
| `guides/outside-adopter-intake.md` | config | request-response | `guides/outside-adopter-intake.md` | exact |
| `.github/ISSUE_TEMPLATE/outside-adopter-evidence.md` | config | request-response | `.github/ISSUE_TEMPLATE/outside-adopter-evidence.md` | exact |
| `guides/support-and-compatibility.md` | config | request-response | `guides/support-and-compatibility.md` | exact |
| `README.md` | config | request-response | `README.md` | exact |
| `CONTRIBUTING.md` | config | request-response | `CONTRIBUTING.md` | exact |
| `website/src/pages/docs.html` | component | request-response | `website/src/pages/docs.html` | exact |
| `website/src/pages/operators.html` | component | request-response | `website/src/pages/operators.html` | exact |

## Pattern Assignments

### `test/scrypath/phase110_contract_test.exs` (test, transform)
**Analog:** `test/scrypath/phase99_contract_test.exs`

**Imports/module attributes pattern** (`test/scrypath/phase99_contract_test.exs:1-13`):
```elixir
defmodule Scrypath.Phase99ContractTest do
  use ExUnit.Case, async: true
  @moduletag :phase99_contract

  @readme File.read!("README.md")
  @contributing File.read!("CONTRIBUTING.md")
  @support_guide File.read!("guides/support-and-compatibility.md")
  @intake_guide File.read!("guides/outside-adopter-intake.md")
  @evidence_template File.read!(".github/ISSUE_TEMPLATE/outside-adopter-evidence.md")
```

**Core contract-token assertion pattern** (`test/scrypath/phase98_contract_test.exs:33-56`):
```elixir
test "intake classes, findings routing, and required evidence headings stay bounded" do
  assert_contains_all(@intake_guide, [
    "Class A",
    "Class B",
    "Class C",
    "Class D",
    "Bug in Scrypath",
    "Doc or Contract Gap",
    "App-Side Error",
    "Environment Failure"
  ])

  assert_contains_all(@evidence_template, [
    "## Environment matrix",
    "## Scrypath ref or Hex version",
    "## Chosen path"
  ])
end
```

**Anti-duplication + route-authority pattern** (`test/scrypath/phase99_contract_test.exs:196-209`):
```elixir
Enum.each([@readme, @contributing, @intake_guide], fn surface ->
  assert_contains_all(surface, ["guides/support-and-compatibility.md"])
end)

Enum.each([@readme, @contributing, @intake_guide], fn surface ->
  assert_absent_all(surface, [
    @compatibility_floor_elixir,
    @compatibility_floor_otp,
    @compatibility_head_elixir,
    @compatibility_head_otp
  ])
end)
```

**Helper/assertion error-message pattern** (`test/scrypath/phase99_contract_test.exs:277-288`):
```elixir
defp assert_contains_all(content, snippets) do
  Enum.each(snippets, fn snippet ->
    assert String.contains?(content, snippet),
           "expected phase-99 contract token #{inspect(snippet)}"
  end)
end
```

---

### `lib/mix/tasks/verify.adopter.ex` (utility, batch)
**Analog:** `lib/mix/tasks/verify.adopter.ex`

**Focused file-list wiring pattern** (`lib/mix/tasks/verify.adopter.ex:38-41`):
```elixir
@fast_tests [
  "test/scrypath/readiness_contract_test.exs",
  "test/mix/tasks/verify_adopter_test.exs"
]
```

**Argument parsing/guard pattern** (`lib/mix/tasks/verify.adopter.ex:53-64,104-121`):
```elixir
{opts, argv, invalid} =
  OptionParser.parse(args,
    strict: [fast: :boolean, live: :boolean]
  )

ensure_valid_args!(opts, argv, invalid)
```

```elixir
defp ensure_valid_args!(_opts, argv, invalid) do
  invalid_flags =
    Enum.map(invalid, fn
      {name, _value} -> format_invalid_flag(name)
      name when is_atom(name) -> "--#{name}"
      other -> format_invalid_flag(other)
    end)

  tokens = argv ++ invalid_flags
  Mix.raise("verify.adopter does not accept arguments, got: #{Enum.join(tokens, " ")}")
end
```

**Thin orchestration + progress markers** (`lib/mix/tasks/verify.adopter.ex:67-70,98-102`):
```elixir
defp run_fast! do
  Mix.shell().info("==> verify.adopter: running fast adopter contracts")
  run_test!(@fast_tests, "fast adopter contracts")
end
```

---

### `test/mix/tasks/verify_adopter_test.exs` (test, batch)
**Analog:** `test/mix/tasks/verify_adopter_test.exs`

**Arg guard tests pattern** (`test/mix/tasks/verify_adopter_test.exs:6-26`):
```elixir
assert_raise Mix.Error, ~r/verify\.adopter does not accept arguments, got: --bogus/, fn ->
  Mix.Task.reenable("verify.adopter")
  Mix.Task.run("verify.adopter", ["--bogus"])
end
```

**Fast-path contract token check against source/help** (`test/mix/tasks/verify_adopter_test.exs:74-97`):
```elixir
source = File.read!("lib/mix/tasks/verify.adopter.ex")
assert source =~ ~S|"test/scrypath/readiness_contract_test.exs"|

output =
  capture_io(fn ->
    Mix.Task.reenable("help")
    Mix.Task.run("help", ["verify.adopter"])
  end)
```

---

### `guides/outside-adopter-intake.md` (config, request-response)
**Analog:** `guides/outside-adopter-intake.md`

**Class taxonomy pattern** (`guides/outside-adopter-intake.md:41-49`):
```markdown
- **Class A:** Exact failure on the repo-clone live example path.
- **Class B:** Hex-package integration failure within the explicitly supported runtime matrix.
- **Class C:** Integration attempt outside the supported runtime matrix.
- **Class D:** Incomplete evidence, missing context, or missing ordered commands.
```

**Finding bucket + routing action pattern** (`guides/outside-adopter-intake.md:52-70`):
```markdown
1. **Bug in Scrypath**
2. **Doc or Contract Gap**
3. **App-Side Error**
4. **Environment Failure**

- **Bug in Scrypath** -> open or route a bugfix issue ...
- **Doc or Contract Gap** -> open a docs correction issue ...
- **App-Side Error** -> respond with correction guidance ...
- **Environment Failure** -> request environment fixes ...
```

---

### `.github/ISSUE_TEMPLATE/outside-adopter-evidence.md` (config, request-response)
**Analog:** `.github/ISSUE_TEMPLATE/outside-adopter-evidence.md`

**Reporter evidence headings pattern** (`.github/ISSUE_TEMPLATE/outside-adopter-evidence.md:13-55`):
```markdown
## Environment matrix
## Scrypath ref or Hex version
## Chosen path
## Sync mode
## Ordered commands
## Expected versus actual outcome
## First failure or confusion point
## Supporting logs
```

**Maintainer review block pattern** (`.github/ISSUE_TEMPLATE/outside-adopter-evidence.md:61-67`):
```markdown
## Maintainer review block
- Classification:
- Findings:
- Action:
```

---

### `README.md`, `CONTRIBUTING.md`, `guides/support-and-compatibility.md` (config, request-response)
**Analogs:** same files

**Route-first authority pattern** (`README.md:23-29`, `CONTRIBUTING.md:6-9`, `guides/support-and-compatibility.md:23-24`):
```markdown
- route to `guides/support-and-compatibility.md` for support/readiness truth
- route to `guides/outside-adopter-intake.md` for evidence-classification workflow
- avoid duplicating compatibility tuples on non-owner surfaces
```

---

### `website/src/pages/docs.html`, `website/src/pages/operators.html` (component, request-response)
**Analogs:** same files

**Route-only entrypoint link pattern** (`website/src/pages/docs.html:36-43`, `website/src/pages/operators.html:51-56`):
```html
<a class="route-item" href="{{REPO_URL}}/blob/main/guides/support-and-compatibility.md">...</a>
<a class="route-item" href="{{REPO_URL}}/blob/main/guides/outside-adopter-intake.md">...</a>
```

## Shared Patterns

### Support truth single-source
**Source:** `guides/support-and-compatibility.md:1-4,23-24`  
**Apply to:** `README.md`, `CONTRIBUTING.md`, `guides/outside-adopter-intake.md`, website route pages
```markdown
This guide is the single current support and readiness authority...
Other surfaces should route here rather than restating a full policy matrix.
```

### Docs contract testing style
**Source:** `test/scrypath/readiness_contract_test.exs:4-22`, `test/scrypath/phase98_contract_test.exs:58-63`  
**Apply to:** `test/scrypath/phase110_contract_test.exs`
```elixir
@readme File.read!("README.md")
assert String.contains?(@readme, "guides/support-and-compatibility.md")

defp assert_contains_all(content, snippets) do
  Enum.each(snippets, fn snippet -> assert String.contains?(content, snippet) end)
end
```

### Verify-task wiring pattern
**Source:** `lib/mix/tasks/verify.adopter.ex:38-41,67-70`, `test/mix/tasks/verify_adopter_test.exs:75-90`  
**Apply to:** `lib/mix/tasks/verify.adopter.ex`, `test/mix/tasks/verify_adopter_test.exs`
```elixir
@fast_tests [...]
run_test!(@fast_tests, "fast adopter contracts")
assert source =~ ~S|"test/scrypath/readiness_contract_test.exs"|
```

## No Analog Found

None. All planned Phase 110 surfaces already exist and have direct in-repo analogs.

## Metadata

**Analog search scope:** `guides/`, `.github/ISSUE_TEMPLATE/`, `lib/mix/tasks/`, `test/scrypath/`, `test/mix/tasks/`, `website/src/pages/`, `docs/`  
**Files scanned:** 14  
**Pattern extraction date:** 2026-05-31
