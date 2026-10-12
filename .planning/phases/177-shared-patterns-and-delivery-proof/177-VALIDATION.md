---
phase: "177"
slug: "shared-patterns-and-delivery-proof"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-11"
---

# Phase 177 — Validation Strategy

> Per-phase validation contract for the six-surface UI audit and bounded delivery evidence.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit / Phoenix LiveView; Playwright for existing browser lanes |
| **Config file** | `scrypath_ops/mix.exs`; `examples/scrypath_ecommerce/package.json` |
| **Quick run command** | `mix verify.ops_ui` from the repository root |
| **Full phase UI command** | `mix verify.ops_ui`, plus only the affected existing screenshot, contrast, browser, or mounted target |
| **Estimated runtime** | Not measured in the current shell; record observed duration when the corresponding lane runs |

There is no approved new framework, dependency, CI service, or paid visual judge in scope. The final exact-SHA closeout is `node scripts/ci_monitor.cjs closeout --push --branch "$(git branch --show-current)" --sha "$(git rev-parse HEAD)"`, after all tracked completion bookkeeping.

## Sampling Rate

- After a task changes Ops UI source or a contract test, run `mix verify.ops_ui`.
- For a token/color change, also run `make contrast` and the relevant existing `make contrast-matrix` lane.
- For a changed rendered slice, capture and directly inspect before/after screenshots at the applicable theme and viewport states; run the existing browser/layout/state target for that slice.
- Run `make verify-mounted` only if the change touches a recovery handoff; keep its task-owned cleanup and evidence.
- Before completion, run the existing source-specific checks required for the final diff, record exact-SHA hosted review/check evidence, decide release/no-release from the Hex package file set, and only then run exact-SHA closeout.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command / Evidence | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-----------------------------|-------------|--------|
| Assigned in PLAN.md | Assigned in PLAN.md | Assigned in PLAN.md | OPUX-26 | — | Preserve existing action eligibility and distinguish unavailable evidence from success. | ExUnit contract + direct six-surface comparison | `mix verify.ops_ui`; before/after visual record for each changed slice | ✅ Existing contract and lanes | ⬜ pending |
| Assigned in PLAN.md | Assigned in PLAN.md | Assigned in PLAN.md | OPUX-27 | — | Preserve keyboard access, visible focus, reduced motion, theme behavior, and safe task identity. | ExUnit + focused browser/layout/contrast; direct image inspection | `mix verify.ops_ui`; affected `make screenshots` / `make contrast` / `make contrast-matrix`; `make verify-mounted` only for a changed recovery seam | ✅ Existing lanes | ⬜ pending |
| Assigned in PLAN.md | Assigned in PLAN.md | Assigned in PLAN.md | OPUX-28 | — | Bind each claim to its source, exact reviewed PR head SHA, and the SHA each required check actually tested. | Artifact/content validation + hosted PR evidence | The committed requirement trace and exact-SHA PR/review/required checks; final `ci_monitor.cjs closeout` after bookkeeping | ✅ Existing closeout helper; trace is phase deliverable | ⬜ pending |

## Wave 0 Requirements

- Existing infrastructure covers all phase requirements; do not install a new framework or dependency.
- Create the committed 20-requirement evidence trace and root `DESIGN.md` as planned artifacts; visually inspect all six surfaces before deciding whether any source correction is warranted.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Direct before/after rendered-image inspection across the six surfaces | OPUX-27 | Visual pattern drift and hierarchy need direct inspection in addition to automated layout/state/contrast evidence. This is an execution record, not pending routine human UAT. | Capture comparable light/dark/system and desktop/intermediate/narrow states for each changed slice; inspect the images and retain the exact source and route/state identifiers. |
| Reviewed PR source and hosted required checks | OPUX-28 | Local test results cannot establish that a reviewer approved the delivered PR head or that hosted checks ran on that same SHA. | Record PR URL, reviewed head SHA, review commit, each required run URL and tested SHA, and outcome. Leave unavailable evidence explicitly unresolved. |

## Validation Sign-Off

- [ ] Every planned task has an automated verification command or documented artifact gate.
- [ ] Sampling continuity has no three consecutive tasks without executable or artifact verification.
- [ ] Wave 0 creates no new framework/dependency and covers only actual missing validation artifacts.
- [ ] No watch-mode flags are used.
- [ ] Feedback latency is recorded from actual runs; no runtime estimate is invented.
- [ ] `nyquist_compliant: true` is set after execution evidence is complete.

**Approval:** pending
