# Phase 112: Public Website and Docs Truth Alignment - Pattern Map

**Mapped:** 2026-06-01  
**Files analyzed:** 11  
**Analogs found:** 11 / 11

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `guides/scope-and-reopen-policy.md` | guide-doc | request-response | `guides/support-and-compatibility.md` | role-match |
| `README.md` | guide-doc | request-response | `README.md` | exact |
| `website/src/pages/evaluate.html` | component | request-response | `website/src/pages/evaluate.html` | exact |
| `website/src/pages/index.html` | component | request-response | `website/src/pages/index.html` | exact |
| `website/src/pages/docs.html` | component | request-response | `website/src/pages/docs.html` | exact |
| `website/src/pages/operators.html` | component | request-response | `website/src/pages/operators.html` | exact |
| `guides/outside-adopter-intake.md` | guide-doc | request-response | `guides/outside-adopter-intake.md` | exact |
| `guides/support-and-compatibility.md` | guide-doc | request-response | `guides/support-and-compatibility.md` | exact |
| `test/scrypath/phase112_contract_test.exs` | test | transform | `test/scrypath/phase110_contract_test.exs` | exact |
| `lib/mix/tasks/verify.phase112.ex` | task | batch | `lib/mix/tasks/verify.phase108.ex` | exact |
| `test/mix/tasks/verify.phase112_test.exs` | test | batch | `test/mix/tasks/verify.phase108_test.exs` | exact |
| `mix.exs` | config | request-response | `mix.exs` (`cli.preferred_envs`) | exact |

## Pattern Assignments

### `guides/scope-and-reopen-policy.md` (guide-doc, request-response)
**Analog:** `guides/support-and-compatibility.md`

**Heading + authority pattern** (`guides/support-and-compatibility.md:1-4`):
```md
# Support and compatibility

This guide is the single current support and readiness authority for Scrypath.
```

**Route-first policy boundary pattern** (`guides/support-and-compatibility.md:23-25`, `69-70`):
```md
This guide is the normative owner ... Other surfaces should route here rather than restating ...
Use [Sync modes and visibility](sync-modes-and-visibility.md) ...
```

### `README.md` (guide-doc, request-response)
**Analog:** `README.md`

**Canonical first-mention claim pattern** (`README.md:5`):
```md
Scrypath, the Ecto-native search indexing library, helps Phoenix and Ecto teams...
```

**Route-map bullets pattern** (`README.md:21-33`, `44-45`):
```md
**Start here:** ... [guides/golden-path.md](...)
**Support and readiness:** ... [guides/support-and-compatibility.md](...)
... this README does not restate either guide body.
```

### `website/src/pages/evaluate.html` (component, request-response)
**Analog:** `website/src/pages/evaluate.html`

**Fit/non-fit concise tiles pattern** (`website/src/pages/evaluate.html:45-67`):
```html
<article class="tile">
  <h3>Hosted search platform</h3>
  <p>Scrypath is not a SaaS search product...</p>
</article>
```

**Operational honesty pattern** (`website/src/pages/evaluate.html:31-34`, `85-89`):
```html
<li>Inline, Oban-backed, and manual sync modes.</li>
<p>Your app owns ... and what is visible when.</p>
```

### `website/src/pages/index.html` (component, request-response)
**Analog:** `website/src/pages/index.html`

**Hero + route entry pattern** (`website/src/pages/index.html:3-15`):
```html
<p class="eyebrow">Ecto-native search for Phoenix apps</p>
<h1>Search indexing that feels native to Ecto.</h1>
<a class="button button-primary" href="{{BASE_PATH}}docs/">Read the docs</a>
```

**Route-list pattern** (`website/src/pages/index.html:147-164`):
```html
<a class="route-item" href="{{BASE_PATH}}docs/"><strong>Docs map</strong>...</a>
```

### `website/src/pages/docs.html` (component, request-response)
**Analog:** `website/src/pages/docs.html`

**Guide-map tile/route pattern** (`website/src/pages/docs.html:40-69`):
```html
<a class="route-item" href="{{REPO_URL}}/blob/main/guides/support-and-compatibility.md">
  <strong>Support and compatibility</strong>
</a>
```

### `website/src/pages/operators.html` (component, request-response)
**Analog:** `website/src/pages/operators.html`

**Sync semantics pattern** (`website/src/pages/operators.html:11-29`):
```html
<h2>Accepted work is not the same thing as visible search.</h2>
```

**Support/intake route pattern** (`website/src/pages/operators.html:104-107`):
```html
<a href="{{REPO_URL}}/blob/main/guides/support-and-compatibility.md">support guide</a>
<a href="{{REPO_URL}}/blob/main/guides/outside-adopter-intake.md">outside-adopter intake guide</a>
```

### `guides/outside-adopter-intake.md` (guide-doc, request-response)
**Analog:** `guides/outside-adopter-intake.md`

**Canonical routing section pattern** (`guides/outside-adopter-intake.md:9-17`):
```md
Canonical routing before you submit evidence:
- Start from README...
- Use support-and-compatibility...
```

**Classifications + action table pattern** (`guides/outside-adopter-intake.md:41-70`):
```md
## Evidence classes
| Class | Finding bucket | Maintainer action |
```

### `guides/support-and-compatibility.md` (guide-doc, request-response)
**Analog:** `guides/support-and-compatibility.md`

**Supported baseline bullet pattern** (`guides/support-and-compatibility.md:5-11`):
```md
## Supported baseline
- Elixir: `~> 1.17`
- OTP: 26 through 28
```

### `test/scrypath/phase112_contract_test.exs` (test, transform)
**Analog:** `test/scrypath/phase110_contract_test.exs` (+ `phase111` helper)

**Module/imports and file-read fixtures** (`test/scrypath/phase110_contract_test.exs:1-12`):
```elixir
defmodule Scrypath.Phase110ContractTest do
  use ExUnit.Case, async: true
  @readme File.read!("README.md")
  @website_docs File.read!("website/src/pages/docs.html")
end
```

**Positive + negative assertion helpers** (`test/scrypath/phase110_contract_test.exs:114-126`):
```elixir
defp assert_contains_all(content, snippets) do
  Enum.each(snippets, fn snippet -> assert String.contains?(content, snippet) end)
end

defp assert_absent_all(content, snippets, path) do
  Enum.each(snippets, fn snippet -> refute String.contains?(content, snippet) end)
end
```

**Combined-surface policy check pattern** (`test/scrypath/phase111_contract_test.exs:64-72`):
```elixir
combined = @decision <> "\n" <> @contributing <> "\n" <> @roadmap
refute combined =~ "immediate required promotion"
```

### `lib/mix/tasks/verify.phase112.ex` (task, batch)
**Analog:** `lib/mix/tasks/verify.phase108.ex`

**Task skeleton + focused tests** (`lib/mix/tasks/verify.phase108.ex:1-11`, `14-20`):
```elixir
defmodule Mix.Tasks.Verify.Phase108 do
  use Mix.Task
  @focused_tests ["test/scrypath/phase108_contract_test.exs", ...]
  def run(args) do
    ensure_no_args!(args)
    Mix.Task.run("app.start")
    run_test!(@focused_tests, "...")
  end
end
```

**Error handling pattern** (`lib/mix/tasks/verify.phase108.ex:28-32`):
```elixir
defp ensure_no_args!(args) do
  Mix.raise("verify.phase108 does not accept arguments, got: #{Enum.join(args, " ")}")
end
```

### `test/mix/tasks/verify.phase112_test.exs` (test, batch)
**Analog:** `test/mix/tasks/verify.phase108_test.exs`

**Argument-contract test pattern** (`test/mix/tasks/verify.phase108_test.exs:6-12`):
```elixir
assert_raise Mix.Error, ~r/verify\.phase108 does not accept arguments/, fn -> ... end
```

**Source-string contract pattern** (`test/mix/tasks/verify.phase108_test.exs:27-34`):
```elixir
source = File.read!("lib/mix/tasks/verify.phase108.ex")
assert source =~ ~S|"test/scrypath/phase108_contract_test.exs"|
```

### `mix.exs` (config, request-response)
**Analog:** `mix.exs`

**preferred_envs entry pattern** (`mix.exs:39-69`):
```elixir
preferred_envs: [
  ...
  "verify.phase108": :test,
  "verify.adopter": :test
]
```

## Shared Patterns

### Contract-test fixture loading
**Source:** `test/scrypath/phase110_contract_test.exs:4-20`  
**Apply to:** `test/scrypath/phase112_contract_test.exs`
```elixir
@file_name File.read!("path")
@surfaces [{"path", @file_name}]
```

### Token assertion helpers
**Source:** `test/scrypath/phase110_contract_test.exs:114-126`  
**Apply to:** phase112 docs contract checks
```elixir
assert_contains_all(...)
assert_absent_all(...)
```

### Verify task no-args + focused test run
**Source:** `lib/mix/tasks/verify.phase108.ex:14-32`  
**Apply to:** `lib/mix/tasks/verify.phase112.ex`
```elixir
ensure_no_args!(args)
Mix.Task.run("app.start")
Mix.Task.run("test", @focused_tests)
```

### Verify-task self-test conventions
**Source:** `test/mix/tasks/verify.phase108_test.exs:15-35`  
**Apply to:** `test/mix/tasks/verify.phase112_test.exs`
```elixir
capture_io(fn -> Mix.Task.run("help", ["verify.phase112"]) end)
source = File.read!("lib/mix/tasks/verify.phase112.ex")
```

### Route-first website/doc language
**Source:** `README.md:21-27`, `website/src/pages/docs.html:40-69`, `website/src/pages/operators.html:104-107`  
**Apply to:** README + website + guides policy-link updates
```md
This surface routes to canonical guides; it does not restate full policy bodies.
```

## No Analog Found

None.

## Metadata

**Analog search scope:** `README.md`, `guides/`, `website/src/pages/`, `test/scrypath/`, `lib/mix/tasks/`, `test/mix/tasks/`, `mix.exs`  
**Files scanned:** 11 primary analog files + phase context/research files  
**Pattern extraction date:** 2026-06-01
