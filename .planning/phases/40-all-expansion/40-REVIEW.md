---
status: clean
phase: 40
depth: quick
generated: 2026-04-20
---

# Code review — Phase 40 (quick)

Scoped to `:all` expansion, `global_schemas` runtime option, and new tests.

## Summary

No blocking issues identified. Expansion validates `:all` tuple shapes before allowlist
resolution; `global_schemas` is stripped from opts passed into `Config.resolve!/1` so
backends do not see a non-runtime key. List walk uses an accumulator reversed at the
end to preserve declaration order.

## Checks

- `mix compile --warnings-as-errors` — pass
- `mix test` — pass
