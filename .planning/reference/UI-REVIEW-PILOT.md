# Whole-app UI review pilot — 2026-10-13

**Result: needs work.** Automation is available and the first entry-state capture completed; the product experience has not passed. This was a distinct in-thread critique, not an independent reviewer attestation. Maintainer examples were treated as non-exhaustive regression checks.

## Evidence

- Preview: `http://127.0.0.1:4002`, container `scrypath_ecommerce-web-1`; Docker inspection confirmed `/app` binds the `phase-174-recovery-entry-diagnosis` worktree.
- Capture source HEAD: `f6fc757d838ab3d6ef71c80a84abf6958f38aaf6`, with local changes. Relevant-tree SHA-256: `91ac704c018ba20064b534be25f15b087a17cecaae7a34a3a47b8d46bba8775f`. Source stayed unchanged during capture. This is local evidence, not an exact-SHA hosted receipt.
- Environment: macOS/darwin; Playwright Chromium `148.0.7778.96`.
- Artifact directory: `examples/scrypath_ecommerce/ui-review-artifacts/historical/2026-10-14T01-00-49-605Z/`. Open `index.html`; `capture.json` binds 321 artifacts by hash, and `review.json` records the critique and coverage gaps.
- 63/63 captures: storefront + all six operator routes × light/dark/system-dark × 1440/768/390. No automated axe violations, page-wide overflow, theme-selection failures, or browser errors were detected in these entry states. Axe reported incomplete checks for some time/ARIA and active-navigation contrast cases; zero violations is not a blanket accessibility pass.
- Inspected all 63 viewport images in seven contact sheets, full desktop/mobile images for representative detailed surfaces, visible-copy/heading/control inventories, storefront hover, compact navigation, and selected-theme focus evidence. Dialogs, submissions, recovery, and backend state transitions were not exercised by this observation-only pass.
- The live mounted CSS byte-matched the local bundled CSS. A further computed-style probe found intended cool tokens (`--ops-surface-1: #191e25`) while translucent surface colors were serialized with a missing OKLCH hue, such as header `oklch(0.233097 0.0154705 none / 0.96)`. Screenshots show a brown cast. The specific rendering/interpolation cause needs a bounded reproduction; stale CSS delivery was not the explanation in this probe.

## Findings beyond the reported examples

| ID | Priority | Evidence and user consequence | Coherent repair direction |
| --- | --- | --- | --- |
| PILOT-01 | High | All operator dark/system-dark captures: slate page floor and schema rows coexist with brown header, panels, notices, and cards. Declared tokens alone did not prove rendered color. | Investigate the shared translucent color construction with a small rendered-color reproduction; repair the shared cause and check light, dark, and system together. Preserve the palette direction rather than inventing another palette. |
| PILOT-02 | High | Storefront 390px full image: tenant controls, facets, and demo-path instructions precede the unavailable-search result; the header still says `0 visible hits` when search failed. | Put current result/error near the query task on compact layouts and distinguish unavailable results from a successful zero-hit count. Preserve tenant scope, explicit error recovery, and real facet data. |
| PILOT-03 | Medium | Search 390px full image: page intro, breadcrumb, large precaution, target section/label/help, query section/label/help, and limits explanation push `Run search` well below the initial viewport. The result empty state repeats the introductory task. | Reduce duplicated orientation and group query/target/submit as one visible task. Keep the actual privacy notice and bounded-query limits accurate and available. Check desktop density as well as mobile order. |
| PILOT-04 | Medium | Search labels targets `Index`, but choices identify Product/Variant Ecto schemas and their module namespace. Sync/drift labels those same choices `Schema`, then separately shows an index name. | Make schema-to-index targeting explicit across the two tasks; retain exact schema/index identities and avoid renaming APIs or substituting a misleading generic collection term. |
| PILOT-05 | Medium | Control Room/Search health: `sync job(s)`, `not green`, `allowlisted schema`; Sync/drift: `schema contract`, `Ordinary recovery`, repeated explanation. Failed-sync displays five jobs with failure evidence while health reports three failed queue jobs; two listed jobs are retrying. | Review primary copy against JOB-03/04/05 and the concept map. Use natural plurals and task language; clarify count cohorts and current versus retained failure evidence. Preserve the queue/backend/settings/visibility distinctions. |
| PILOT-06 | Medium | Playbooks: full filesystem workspace path has top-level prominence, large precaution competes with catalog, and every row's `Run without preview` has an amber wrapper while `Load preview` is quieter. Mobile repeats this hierarchy across three tall records. | Lead with selecting/previewing a useful saved check, move filesystem diagnostics into context, and establish consistent action emphasis. Preserve read-only run semantics, import/save boundaries, confirmation, and artifact/run provenance. |
| PILOT-07 | Medium | Failed-sync and Playbooks amber action wrappers, notices, and duplicate surface treatments compete with primary task controls. Routine labels/precautions occupy large portions of compact screens. | Audit the shared notice/action treatment by purpose and consequence; use local status cues and clear action hierarchy. Keep actual risk information rather than removing all warnings categorically. |
| PILOT-08 | High, workflow | `admin_shell_wash.spec.ts` and `admin_shell_chrome.spec.ts` still demand radial/linear background washes; `phase173_shell.spec.ts` still expects the retired warm light floor. Current DESIGN.md requires a flat cool shell. | Reconcile these active checks with current documented direction before using the full legacy lane as a regression authority. Retain meaningful computed/pixel checks; don't restore retired UI to satisfy stale assertions or auto-update disputed goldens. |

The current whole-app review also supports the original palette, picker, guide, and terminology concerns. UI-01's non-underlined pointer hover is visible in current evidence; its full feedback acceptance record remains separate. UI-02's error explanation now exists, but a current populated-facet/zero-hit proof is still missing. Local guide edits do not change the GitHub main destination until delivered.

## What to preserve

- Full schema and index identities, readable timestamps, and separate backend/queue evidence.
- Explicit unavailable, not-run, not-loaded, and not-checked states; no invented healthy aggregate.
- Shared native theme buttons with one selected preference, compact navigation, and visible focus.
- Task-specific surfaces; Search/Playbooks remain different from recovery and index-change tasks.
- A retained preview with no reseeding, no new framework/dependency, and local evidence without paid model calls.

## State/journey coverage still needed

The capture saw storefront search unavailable; Control Room and Search health with queue failures; five retained failed-sync rows (including retrying work); Sync/drift before settings/document checks; Search before submit; and three saved Playbook files before preview/run. These are the actual observed states, not fabricated scenario labels.

Use existing isolated LiveView/browser fixtures to prove populated facets and zero hits, setup-missing states, loading/partial/stale observations, eligible retry and exact backend/document follow-through, settings drift and promotion, single/multi search success/failure, and Playbook import/save/preview/run errors and provenance. Exercise real controls and keyboard dialogs. Inspect the rendered guide destination and link/version semantics. Existing historical phase receipts do not cover this changed local tree.

## Next batch

Address shared rendered-color behavior and reconcile contradictory regression checks first; then repair the common task hierarchy and language issues across Search/Playbooks and compact storefront/result states as one scoped experience batch. Confirm affected surfaces and adjacent shared controls together, record remaining findings, and add focused executable checks for recurring concrete failures. Establish visual baselines only for a reviewed direction in deterministic states. Do not reopen Phases 173–177 or treat this pilot as their acceptance.

## Pilot verification

- `npm run ui:review:selftest`: 5 tests passed; rejects incomplete inventory/dimensions, stale bindings, unknown/missing artifacts, needs-work and open findings.
- `npm run test:e2e:list`: 147 existing tests listed in 15 files; new helper/self-test files do not enter the seeded Playwright suite.
- Legacy judge mock with `--required`: exits 1 with status `mock`; it cannot claim visual acceptance.
- `npm run ui:review:check -- …`: rejects the capture's pending/needs-work review as intended. A capture success is distinct from a product design pass.
- `git diff --check`: passed. No product-source repair, full seeded browser execution, hosted CI, approval, or merge is claimed by this pilot.
