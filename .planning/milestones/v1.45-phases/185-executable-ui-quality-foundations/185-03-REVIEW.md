# Plan 03 parent review and repairs

Status: scoped findings closed on source `6f7ebe9ddac079140084b54a00ea75edec825917`; root integration and whole-phase review remain pending.

## Evidence and review limits

A separate read-only agent reviewed immutable original `b3b9edb8`, then re-reviewed the repairs. It ran no tests. Parent exercised actual regressions and the final canonical command. The last scoped review reports no remaining concrete findings; this is code inspection, not independent human approval or a substitute for tests.

Final `mix verify.repository_contracts` passed 145 tests with zero failures at the repaired source. Log: `/private/tmp/phase185-03-parent-canonical.log`. The intermediate complete focused suite passed 13 tests before the final mode-name test; final canonical includes that added test. Parent TAP adapters execute the actual tagged ExUnit cases and assert their exit status. Native ExUnit text is unsupported by the GSD classifier; the adapter source, exact output and reasons are preserved in the three committed RED JSON records. All three were classified `RED_EVIDENCE_OK`; failures were behavior assertions, not setup/import/ordering failures.

## Closed findings

- Active CSS authority: comments and quoted examples no longer count as live theme blocks. Top-level statement context and escaped punctuation are tracked; junk/escaped lookalikes cannot create authority. Exactly one recognized mode name is required, including rejection of duplicate recognized or unknown names.
- Standard typed export: the published format defines the allowed token types and shadow shape. The generic string type and custom dropShadow field were not portable representations. The exact none string now lives in namespaced extension metadata, and layers use the published optional boolean inset field. Finite signed dimensions retain explicit units. [Published DTCG format](https://www.w3.org/community/reports/design-tokens/CG-FINAL-format-20251028/).
- CSS compatibility: shadow blur must be non-negative; signed offsets and spread remain supported. This is the bounded CSS-compatible profile, not a claim that every possible standard token form is implemented.
- Resource bounds: each JSON/CSS read is limited to 2 MiB; JSON nesting to 64; token count to 4096; alias recursion to 32. Tests reject oversized source, excessive nesting/tokens/aliases, cycles, unresolved paths and malformed metadata without executing source.

## Repair commits

| Evidence | Repair |
|---|---|
| `9563cc9b` and `185-03-parent-review-RED.json` | `238bf7a7`: active themes, standard values/metadata, signed dimensions and finite readers |
| `a64bc55c` and `185-03-authority-blur-RED.json` | `13218116`: statement-bound CSS authority and blur constraints |
| `ee06b32c` and `185-03-mode-name-RED.json` | `6f7ebe9d`: one unambiguous theme name |

The tests preserve the original brand JSON values and warm CSS values, including their pre-existing shadow differences, plus exact live Ops theme mappings. No UI CSS, controller or template changed. No dependency was added. UIF-05's flagged edge classification remains unclassified for phase verification; no automatic classifier resolution, hosted source acceptance, rendered approval or main merge is inferred.
