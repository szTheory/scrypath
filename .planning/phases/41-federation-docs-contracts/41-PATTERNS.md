# Phase 41 — Pattern map

Analogs for executor **read_first** alignment.

| Intended change | Closest analog | Notes |
|-----------------|----------------|-------|
| Phase verify Mix task | `lib/mix/tasks/verify.phase38.ex` | Same `ensure_no_args!`, `run_test!/2`, `@focused_tests` |
| `mix.exs` verify alias | `mix.exs` lines with `verify.phase36`..`verify.phase38` | Add `verify.phase41: :test` |
| Doc contract assertions | `test/scrypath/docs_contract_test.exs` (`assert_contains_all`, `ordered?/2`, `@verify_phase*`) | Add `@verify_phase41` + federation-focused tests |
| Federation narrative | `guides/multi-index-search.md` existing sections | Extend, avoid duplicating README |
| README pointer | Existing README multi-index / guide links | One sentence + `guides/multi-index-search.md` |
| `@doc` on `search_many/2` | `lib/scrypath/search.ex` lines 109–146 | Append score / merge invariant per CONTEXT D-15–D-17 |
| CI verify step | `.github/workflows/ci.yml` quality job `verify.phase28` step | Add `verify.phase41` step |
| CONTRIBUTING matrix | `CONTRIBUTING.md` verification table | One row + short paragraph for two-tier model |

## Code excerpts (reference)

**Thin verify task shell** — from `verify.phase38.ex`:

```elixir
@focused_tests [
  "test/scrypath/docs_contract_test.exs"
]

def run(args) do
  Mix.Task.run("app.start")
  ensure_no_args!(args)
  run_test!(@focused_tests, "Phase 41 federation docs verification")
end
```

(Executor picks exact test paths per PLAN-01 task.)
