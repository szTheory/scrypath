# EVID-01 — B1 evidence ledger (v1.14)

**Freeze date:** 2026-04-21
**Rule:** Append-only after freeze — errata = new rows or explicit SUPERCEDED-OF markers; do not silently edit frozen rows.

## Evidence rows

| ID | Claim | Evidence | LIB mapping |
|----|--------|----------|-------------|
| EVID-57-01 | First-hour adopters still confuse database success with immediate search visibility; **LIB-01** needs clearer failure text and an obvious next doc hop. | `guides/common-mistakes.md` — opening pitfall ties symptoms to sync semantics; quoted excerpt: "Accepted work is not the same thing as search visibility" | LIB-01 |
| EVID-57-02 | Un grounded “DX” API churn breaks semver trust unless each **B1** change cites a concrete pain signal; **LIB-02** should default to typespecs/`@doc`/small helpers first. | `.planning/research/PITFALLS.md` — Pitfall 1 (speculative B1 API churn); quoted excerpt: "Each **B1** REQ cites evidence" | LIB-02 |

## LIB-01..LIB-03 triage (B1)

- LIB-01: Maps to EVID-57-01
- LIB-02: Maps to EVID-57-02
- LIB-03: Maps to EVID-57-01
