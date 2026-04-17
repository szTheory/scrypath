# v1.2 milestone archive — validation evidence

Retroactive **Nyquist-style** validation for v1.2 operator work (phases 13–15), added in v1.3 **Phase 23**. Each file maps requirements to **runnable tests**, **`mix verify.*` commands**, and **CI receipts** (no prose-only closure).

| Phase | Scope | Evidence file |
|-------|--------|-----------------|
| 13 | Operator primitives (`Scrypath.Operator.*`, related tests) | [`13-VALIDATION.md`](13-VALIDATION.md) |
| 14 | Mix tasks + operator docs contracts | [`14-VALIDATION.md`](14-VALIDATION.md) |
| 15 | Live Meilisearch operator verification (`live_operator_verification_test.exs`) | [`15-VALIDATION.md`](15-VALIDATION.md) |

**Milestone audit:** Nyquist status for these phases is rolled up in [`../v1.2-MILESTONE-AUDIT.md`](../v1.2-MILESTONE-AUDIT.md) (YAML + narrative aligned as of 2026-04-17).

**Upstream requirements:** `VALID-01` … `VALID-03` in `.planning/REQUIREMENTS.md`.
