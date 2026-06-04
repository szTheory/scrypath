# Phase 127 — Shell coherence + milestone verification & UAT

**Requirements:** SHELL-01, VERIFY-01

## Goal
Tighten the chrome that frames every screen, confirm cross-screen consistency (the "as a unit"
altitude), and prove the whole milestone against intent before owner UAT.

## Tasks
1. **SHELL-01:** unify the fleet trust verdict (P5) so it reads identically where the same question
   is asked (Control Room ↔ Posture); keep Sync/Drift's distinct "promotion readiness" verdict
   consistent in form. Collapse the header nav on mobile (P6). Confirm header/nav/palette/theme/
   flash/trail/handoff consistency across all six screens.
2. **VERIFY-01:** run the gates (verify.opsui, LiveView suite, ecommerce compile, mounted-admin
   Playwright smoke); produce a v1.32→v1.33 before/after gallery + milestone audit; owner UAT.

## Verification
`mix verify.opsui` green (nav contract); host compiles clean; milestone audit verdict; owner UAT.
