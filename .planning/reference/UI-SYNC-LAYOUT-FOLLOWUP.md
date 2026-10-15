# Sync and drift follow-up — 2026-10-15

Scoped follow-up to delivered iteration 3 on `fix/ui-iteration-3`, draft PR [#107](https://github.com/szTheory/scrypath/pull/107). The retained preview remains port 4002 with startup seeding disabled. This does not reopen historical GSD phases.

## Maintainer feedback and delivery

| Feedback | Change |
| --- | --- |
| Settings timestamp arrives after load and moves the comparison | Permanent metadata row with a truthful Checking… placeholder, matching loaded stamp height, and deliberate stacking on compact screens. Reproduced a 28px header increase before the fix; final browser assertions compare exact pending/loaded header heights. |
| Two identical Checked labels appear duplicated | Header says Sync checked; the comparison says Settings checked. They retain separate read times and error/retained-evidence semantics. |
| Status body is not aligned with its title | Shared neutral status component places the cue in its own grid column; wrapped title and body share a text column. |
| Busy page, unclear hierarchy, table gradient out of place | Removed repeated section explanation, shortened status/follow-up copy, placed filter capability help with its row, moved matching categories into comparison details, demoted advanced promotion, and replaced the large Next step block with quiet related links. Settings table is flat, with readable column headings and contained horizontal scrolling. |
| Pending or retrying does not explain normality or next steps | Show observed pending-job/task counts separately from scheduled retries, linked to schema-scoped Search health. Terminal failures have their own count/action to Failed sync work. Pending alone is not described as an incident or proven backlog. Native Help explains the stages. Historical reindex visibility is no longer presented as current work. |

A regression test also protects a discovered semantic issue: the core failed-work collection includes scheduled retries, so collection non-emptiness must not alone produce a terminal-failure warning. The summary filters terminal states without changing the underlying recovery or promotion rules.

The timestamp hook now exists from the initial placeholder onward. Simply adding its hook attribute when the time arrives does not mount the clipboard listener reliably. The final browser test checks actual clipboard dispatch, toast, UTC/local formatting and unchanged geometry after hydration. Unknown times still have no copy button.

## Verification

- `mix precommit`: 319 tests + 2 doctests, zero failures.
- Root `mix verify.ops_ui`: 319 tests + 2 doctests, zero failures.
- `settings_layout.spec.ts`: 8/8 passing, light/dark × 1440/768/390/320px. Real disconnected HTML → connected settings result, exact header geometry, aligned status text, flat table background, clipboard/toast, local time formatting and zero WCAG A/AA violations.
- Read-only whole-inventory capture: 72 views at `examples/scrypath_ecommerce/ui-review-artifacts/2026-10-15T19-21-45-091Z`. All eight contact sheets inspected in-thread, plus representative settings/adjacent full views. This capture found low-contrast light-theme table headings at two widths after removing the gradient. Those were corrected and confirmed by the final eight browser cases. The initial matrix remains unmodified historical evidence, not a final zero-findings certificate or an approved golden.
- Mechanical design detector: no findings on the changed component/template/CSS targets. `git diff --check` clean.
- Final exact-copy/navigation confirmation and source identity: `ui-review-artifacts/settings-layout-followup/confirmation.json`. Dedicated pending/loaded and full-page images live beside it, outside Playwright cleanup.

Final product-source SHA256: `9786a6894cf36dd0795f6b40b19fbe445c0244c050c1a48700701d0c5edcace1`. The final navigation receipt passes at 1440/390px, including exact timestamp copy, unchanged copy geometry, schema-preserving activity/failure links and adjacent notice alignment. Review is an in-thread inspection, not independent maintainer approval.

Logs: `/tmp/scrypath-settings-checks-final.log`, `/tmp/scrypath-settings-final.log`, `/tmp/scrypath-settings-journeys-final.log`. An attempted reuse of older guarded suites skipped four cases on the retained port; these are not counted as passing evidence. All browser actions in this follow-up are read-only observations, copying or navigation; no preview seeds, retries, settings writes, promotion or saved-file changes.

Unit suites ran in a disposable container with a dedicated test database partition and stub clients. Existing unrelated core type/LiveView async warnings remain; both required checks exit successfully. No dependency or brand changes. The maintainer's untracked `my-search.json` remains preserved with SHA256 `3c8de6b45b9b3bc6f5daff18ce71da1ee817b5270ddc57a8c064f59a1a42c0f7`.
