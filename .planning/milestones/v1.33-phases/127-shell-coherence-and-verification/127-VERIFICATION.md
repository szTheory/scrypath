# Phase 127 — Verification

## SHELL-01
- [x] Verdict label unified Posture ↔ Control Room ("Can I trust search right now?"); Sync/Drift
      distinct-but-consistent. (`posture_live.ex:157`)
- [x] Header nav `hidden sm:block` — no mobile duplication of palette/breadcrumb. (`layouts.ex:70`)
- [x] Chrome consistency across six screens via shared `layouts.ex` + nav-contract test.

## VERIFY-01 (static gates — this session)
- [x] `mix verify.opsui` — nav contract OK, 2 doctests, 129 tests, 0 failures.
- [x] ScrypathOps LiveView suite — green (run within verify.opsui).
- [x] `examples/scrypath_ecommerce` `mix compile --warnings-as-errors` — clean.

## VERIFY-01 (deferred to owner UAT — live verification)
- [ ] Mounted-admin Playwright smoke re-run live (`admin_screenshots` + `operator`). Specs updated/parse.
- [ ] v1.32→v1.33 before/after recapture pairs (gallery documented; v1.33 after-set in `.tmp/`).
- [ ] Human UAT sign-off.

## Result
Implementation complete and statically green. Milestone awaits owner UAT — see
`v1.33-MILESTONE-AUDIT.md` (PASSED/tech_debt) and `v1.33-BEFORE-AFTER.md`.
