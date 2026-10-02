# Phase 171: Pattern Map

**Scope:** Planning artifacts only; no runtime or CI files are modified.

| Target | Role | Closest existing pattern | Apply |
|---|---|---|---|
| `171-VERIFICATION.md` | Requirement-to-evidence matrix | `169-VERIFICATION.md` | Use a clear status, source-bound evidence, limits, and a Requirements Coverage table. Explicitly identify the report as supplemental to frozen Phase 170. |
| `.planning/REQUIREMENTS.md` | Requirement ownership / traceability | Existing v1.41 Traceability section | Preserve the canonical Phase 170 mapping; add a short explanation that Phase 171 supplies a supplemental verifier because the original file is frozen. |
| `.planning/PROJECT.md` | Durable project workflow rule | `## Verification Default` | Add a concise requirement-ID mapping rule next to the existing shift-left default. |
| `171-01-SUMMARY.md` | GSD completion record | `170-04-SUMMARY.md` | Record requirements-completed IDs and state that this is evidence reconciliation, not renewed product delivery. |

Evidence for these patterns: `.planning/phases/169-library-fix-delivery-and-pr-triage/169-VERIFICATION.md`, `.planning/phases/170-documentation-and-readiness-closeout/170-POST-FREEZE-RECONCILIATION.md`, and `.planning/PROJECT.md`.
