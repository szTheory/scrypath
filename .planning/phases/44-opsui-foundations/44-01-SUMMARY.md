---
phase: 44
plan: "01"
status: complete
---

# Plan 44-01 — ScrypathOps bootstrap

## Outcome

- Added committed **`mix.lock`** for **`scrypath_ops/`** (resolved via containerized `mix deps.get` where host Hex auth blocked) so **`mix compile`** / **`mix test`** work without interactive prompts.
- Documented Hex boundary in root **`mix.exs`** comment and existing **`docs/releasing.md`** section; **`package.files`** still excludes **`scrypath_ops/`**.

## Key files

- `scrypath_ops/mix.exs`
- `scrypath_ops/mix.lock`
- `scrypath_ops/README.md`
- `mix.exs`
- `docs/releasing.md`

## Verification

- `test -f scrypath_ops/mix.exs`
- `grep -F '{:scrypath, path: ".."}' scrypath_ops/mix.exs`
- `grep -A12 'defp package' mix.exs | grep -F 'scrypath_ops' | wc -l` → 0
- `cd scrypath_ops && mix compile` → 0
- `mix compile` (repo root) → 0

## Self-Check: PASSED
