---
phase: 133-dark-path-motion-expression-r-g
reviewed: 2026-06-24T00:00:00Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - examples/scrypath_ecommerce/e2e/admin_path_motion.spec.ts
  - scrypath_ops/assets/css/DESIGN-TOKENS.md
  - scrypath_ops/assets/css/app.css
  - scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex
  - scrypath_ops/lib/scrypath_ops_web/live/search_live.ex
  - scrypath_ops/test/scrypath_ops_web/motion_contract_test.exs
findings:
  critical: 0
  warning: 1
  info: 3
  total: 4
status: issues_found
---

# Phase 133: Code Review Report

**Reviewed:** 2026-06-24
**Depth:** standard
**Files Reviewed:** 6
**Status:** issues_found

## Summary

Reviewed the DARKMOTION-01 path-motion vocabulary: the opt-in `.ops-path-*` /
`.ops-code-block--shimmer` CSS layer in `app.css`, its static-CSS ExUnit contract test
(`motion_contract_test.exs`), the Playwright proof (`admin_path_motion.spec.ts`), the
`shimmer` attr wiring in `ops_ui.ex`, and the `.ops-path-trace` anchor wiring in
`search_live.ex`.

The phase's core discipline is sound and well-defended:

- The path-motion CSS is genuinely transform/opacity/box-shadow-only, token-driven
  (`--duration-ops-fast`, `--ease-ops-standard`, `--shadow-ops-glow[-copper]`), and
  carries no new keyframes — the A3 patch-safety claim holds.
- The contract-test regexes were traced against the actual CSS: the forbidden-prop
  scan correctly avoids false positives on `border-bottom`/`border-image`/
  `transform-origin`/`inset`/`border-radius` (negative lookbehind + `prop:` boundary),
  the token-timing scan correctly handles the multi-line `transition:` value, and the
  dual-dark mirror symmetry holds for `.ops-object-item-active` (both branches present
  at app.css:1495 and app.css:1499).
- The reduced-motion probe, patch-refire (`CSSAnimation`-only) probe, and shimmer-off
  evidence assertions in the spec are correctly scoped and robust.
- `shimmer` defaults to `false` (ops_ui.ex:987) and is never set on evidence code
  blocks in `search_live.ex` (the D-04a/c claim holds).

One real cross-cutting compatibility defect and three quality items follow. No
security issues and no correctness bugs in the shipped runtime CSS/markup were found.

## Warnings

### WR-01: `MapSet.filter/2` requires Elixir ≥ 1.18 but `mix.exs` declares `~> 1.17`

**File:** `scrypath_ops/test/scrypath_ops_web/motion_contract_test.exs:150-151`
**Issue:** The dual-dark mirror test calls `MapSet.filter/2`:

```elixir
path_explicit = MapSet.filter(explicit_dark, &String.contains?(&1, "object-item-active"))
path_system = MapSet.filter(system_dark, &String.contains?(&1, "object-item-active"))
```

`MapSet.filter/2` (and `MapSet.reject/2`) were added in **Elixir 1.18.0**. But
`scrypath_ops/mix.exs:8` declares `elixir: "~> 1.17"`. This new test is the *only* call
site of `MapSet.filter/2` in the entire `scrypath_ops` lib/ + test/ tree, so it
silently raises the project's effective Elixir floor from 1.17 to 1.18. On an Elixir
1.17 toolchain (which the package claims to support) the test suite fails to compile
with `UndefinedFunctionError (function MapSet.filter/2 is undefined or private)`,
breaking `mix verify.opsui`. CI happens to run 1.19, so this is latent rather than
currently red — but the declared compatibility contract is violated for a Hex library.

**Fix:** Either bump the declared floor in `mix.exs` to `~> 1.18` (if 1.17 support is
being dropped intentionally), or — preferred, to keep the `~> 1.17` floor — avoid the
1.18-only function by filtering through `Enum`:

```elixir
path_explicit =
  explicit_dark |> Enum.filter(&String.contains?(&1, "object-item-active")) |> MapSet.new()

path_system =
  system_dark |> Enum.filter(&String.contains?(&1, "object-item-active")) |> MapSet.new()
```

## Info

### IN-01: Unused `type SeedScenario` import in the Playwright spec

**File:** `examples/scrypath_ecommerce/e2e/admin_path_motion.spec.ts:42-48`
**Issue:** `SeedScenario` is imported (line 47) but never referenced anywhere in the
file (the only occurrence is the import itself). It does not break the build today
(Playwright transpiles via esbuild with no type-checking and the project has no
tsconfig/eslint enforcing `noUnusedLocals`), but it is dead code that will trip a lint
rule or a future `tsc --noEmit` gate.
**Fix:** Drop the unused import:

```ts
import {
  drainSearchQueue,
  seedScenario,
  waitForLiveConnected,
  waitForSearchVisible
} from "./helpers/e2e";
```

### IN-02: `.ops-path-trace` underline anchored to the bottom of an expandable `<details>`

**File:** `scrypath_ops/assets/css/app.css:1240-1262`, consumed at
`scrypath_ops/lib/scrypath_ops_web/live/search_live.ex:1021,1037`
**Issue:** `.ops-path-trace` is applied to a `<details>` disclosure, and its line-draw
`::after` is `position: absolute; inset: auto 0 0 0` (pinned to the bottom edge of the
element). When the disclosure is *open*, the `<details>` grows to include the expanded
merge-trace `<ol>`, so the hover underline draws at the bottom of the expanded body
rather than under the summary affordance. This is a presentation nuance, not a
correctness bug (the e2e proof only asserts the `::after` transform leaves its rest
state on hover, which still holds), but the underline placement on the open state may
not match the intended "summary underline" affordance.
**Fix:** If the underline is meant to track the summary row, scope the pseudo-element to
the summary (e.g. `.ops-path-trace > summary::after`) so its position is independent of
the expanded body height. Otherwise document that the bottom-edge placement is
intentional.

### IN-03: Eagerly-evaluated fallback key lookup in `run_multi/6`

**File:** `scrypath_ops/lib/scrypath_ops_web/live/search_live.ex:350`
**Issue:** `Map.get(params, "schemas", Map.get(params, "schemas[]", []))` always
evaluates the inner `Map.get(params, "schemas[]", [])` even when the `"schemas"` key is
present (Elixir evaluates call arguments eagerly). Behaviorally correct, but the intent
("prefer `schemas`, fall back to `schemas[]`") reads more clearly — and avoids the
redundant lookup — with an explicit branch. Minor; this line is path-adjacent
(it feeds the multi-mode merge-trace anchor the phase exercises) rather than newly
introduced by this phase.
**Fix (optional):**

```elixir
selected =
  (params["schemas"] || params["schemas[]"] || [])
  |> List.wrap()
  |> Enum.map(&module_in_allowlist(&1, allowlist))
  |> Enum.reject(&is_nil/1)
  |> Enum.uniq()
```

---

_Reviewed: 2026-06-24_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
