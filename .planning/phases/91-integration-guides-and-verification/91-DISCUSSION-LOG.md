# Phase 91: Integration, Guides, and Verification - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-25
**Phase:** 91-integration-guides-and-verification
**Areas discussed:** Example smoke-proof scope (91-03)
**Mode:** advisor (`minimal_decisive` calibration; opinionated profile → decisive recommendations, no low-stakes bounce-back)

---

## Example smoke-proof scope (91-03)

| Option | Description | Selected |
|--------|-------------|----------|
| Oban + inline (both) | Prove the Author→Post fan-out through both `sync_mode: :inline` and `sync_mode: :oban` smoke paths; mirrors the example's existing dual `sync_record` coverage and makes EXEC-02 inline-vs-Oban guidance demonstrable end-to-end. Larger example diff. | ✓ |
| Oban path only | Prove only the durable Oban path (milestone headline retiring the "temporary workaround"); smaller diff, inline fan-out documented but not exercised in the example smoke test. | |

**User's choice:** Oban + inline (both)
**Notes:** Keeps the example's existing inline/Oban symmetry and makes the documented inline-vs-Oban decision (EXEC-02) reproducible in the example.

---

## Claude's Discretion

The remaining areas were low/medium-stakes and codebase-determined; per the user's opinionated
profile they were locked with decisive recommendations rather than asked:

- **91-01 guide rewrite** — replace the "Temporary Workaround" subsection with a canonical
  `Scrypath.sync_related/3` section (schema-side `fan_outs:` + context-side call for both sync
  modes), preserve the no-callback-magic voice, fold inline-vs-Oban into the existing
  "Picking the right follow-up path" section (EXEC-02), strip "temporary workaround"/"first-class
  feature" strings.
- **91-02 verify gate** — `Verify.Phase91` mirroring `verify.phase85`; invert the existing
  docs-contract test (line 1128) to assert the new boundary language and the absence of the old
  workaround strings (TEST-02); register the task in the contract test's discoverability list.
  Hermetic tests satisfy TEST-01.
- Exact prose/section ordering, assertion strings, and the example's `author_name` projection
  mechanism (denormalized column vs app-owned preload) — left to research/planning, with the
  locked constraint that the mechanism stays app-owned and explicit.

## Deferred Ideas

- Tenant-safe search access (AUTH-01) — next milestone's wedge, not this phase.
- High-cardinality facet-value search (FACET-UX-01) — unrelated catalog-depth follow-on.
- No scope creep surfaced; discussion stayed within the docs/verify/example boundary.
