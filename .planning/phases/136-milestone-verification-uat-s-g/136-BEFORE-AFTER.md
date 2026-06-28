# v1.33 -> v1.34 before/after gallery

**Milestone:** v1.34 Both-Themes Perfection - Dark Signature + AA Gate  
**Comparison source:** v1.33 commit `ae33d36`, branch `origin/gsd/v1.33-admin-ui-insane-polish`  
**After source:** Phase 136 `phase136` matrix from `136-ARTIFACT-MANIFEST.json`  
**Gallery shape:** dark-weighted claim gallery, preserving the historical 40-shot light/dark matrix.

This gallery compares the existing v1.33 40-shot evidence set with the fresh v1.34 Phase 136
40-shot evidence set. It is not a raw screenshot dump: each row names the operator claim being
proved, cites before evidence and after evidence, and then names the visible or verified delta.

## Evidence Sources

| Side | Evidence | Provenance |
| --- | --- | --- |
| v1.33 before | `.tmp/admin-screenshots/*.png` | Historical 40-shot set documented by `.planning/milestones/v1.33-phases/127-shell-coherence-and-verification/v1.33-BEFORE-AFTER.md`; 40 PNGs dated 2026-06-03. |
| v1.33 source | `ae33d36`, `origin/gsd/v1.33-admin-ui-insane-polish` | Required comparison source for the historical before state. |
| v1.34 after | `examples/scrypath_ecommerce/test-results/admin-screenshots/phase136/*.png` | Fresh Phase 136 source-backed screenshot matrix; expected count 40, actual count 40, checksums recorded in `136-ARTIFACT-MANIFEST.json`. |
| v1.34 browser gates | `136-DUALVERIFY-REPORT.md` | Source-backed Mix, contrast, depth, motion, shell, mounted smoke, and screenshot proof against `http://127.0.0.1:4012`. |

## Evidence Exceptions

Maintainer-accepted evidence exceptions: **none**.

Every gallery claim below has paired before evidence and after evidence. Still-image claims cite
v1.33 and v1.34 screenshot paths and checksum prefixes. Browser-behavior claims, such as focus and
system-dark, pair the v1.33 audit/report baseline with the v1.34 source-backed browser gate reports
because those behaviors are not fully represented by static PNGs.

## Claim Gallery

| Claim | Before evidence | After evidence | Delta |
| --- | --- | --- | --- |
| **route orientation** | v1.33 screenshot `.tmp/admin-screenshots/00-control-room--dark--desktop--incident.png` (`sha256 6d5362469eaa...`) plus v1.33 gallery notes on task-first route orientation. | v1.34 screenshot `test-results/admin-screenshots/phase136/00-control-room--dark--desktop--incident.png` (`sha256 53e85f791779...`) and light pair `00-control-room--light--desktop--incident.png` (`sha256 38db757b1c83...`). | The dark Control Room keeps the Recover/Explore route language from v1.33, but v1.34 seats the orientation layer in the dark shell/wash and source-backed chrome proof rather than relying on the v1.33 static gallery alone. |
| **posture trust** | v1.33 screenshot `.tmp/admin-screenshots/01-posture--dark--desktop--incident.png` (`sha256 869c69fe428e...`). | v1.34 screenshot `test-results/admin-screenshots/phase136/01-posture--dark--desktop--incident.png` (`sha256 58db88a3db24...`) and light pair `01-posture--light--desktop--incident.png` (`sha256 6ff4a4c500c...`). | The trust read moves from v1.33's worst-first posture organization into v1.34's dark surface-2 depth, AA-muted text floor, and source-backed depth proof. The operator can still answer "Can I trust search right now?" first. |
| **failed-sync recovery** | v1.33 screenshot `.tmp/admin-screenshots/02-failed-sync--dark--desktop--populated.png` (`sha256 756cf810325b...`). | v1.34 screenshot `test-results/admin-screenshots/phase136/02-failed-sync--dark--desktop--populated.png` (`sha256 fed8196df4f9...`) and mobile pair `02-failed-sync--dark--mobile--populated.png` (`sha256 50b9182c0dcb...`). | Recovery stays task-first, with v1.34 adding darker seated surfaces, stronger muted-text contrast, and browser smoke that proves failed-sync triage remains mounted and operable. |
| **drift clarity** | v1.33 screenshot `.tmp/admin-screenshots/03-sync-drift--dark--desktop--drift.png` (`sha256 c601b1d29398...`). | v1.34 screenshot `test-results/admin-screenshots/phase136/03-sync-drift--dark--desktop--drift.png` (`sha256 6d64c9bc4a3f...`) and light pair `03-sync-drift--light--desktop--drift.png` (`sha256 9a71ba84900f...`). | The wide Sync/Drift layout from v1.33 remains, while v1.34 makes the preflight and drift evidence read as raised operational surfaces in dark and proves the swap path through mounted operator smoke. |
| **search exploration** | v1.33 screenshot `.tmp/admin-screenshots/06-search--dark--desktop--results.png` (`sha256 b6cce8b1046e...`) and zero-results `.tmp/admin-screenshots/08-search--dark--desktop--zero-results.png`. | v1.34 screenshots `test-results/admin-screenshots/phase136/06-search--dark--desktop--results.png` (`sha256 ec5d0671032a...`) and `08-search--dark--desktop--zero-results.png` (`sha256 0e368751ebed...`). | Search keeps the v1.33 human-field result rows and clear zero-results action, but v1.34 adds dark row separation, route/path motion restraint, and contrast-proofed muted copy. |
| **playbook workspace clarity** | v1.33 screenshot `.tmp/admin-screenshots/09-playbooks--dark--desktop--empty-workspace.png` (`sha256 50215a76cfc4...`). | v1.34 screenshot `test-results/admin-screenshots/phase136/09-playbooks--dark--desktop--empty-workspace.png` (`sha256 bea9ad339381...`) and light pair `09-playbooks--light--desktop--empty-workspace.png` (`sha256 afddef05885b...`). | The workspace/read-only distinction from v1.33 remains visible; v1.34 seats the empty workspace on the darker raised ramp and proves active Playbook glow end-state timing rather than sampling a transition frame. |
| **shell restraint** | v1.33 screenshots `.tmp/admin-screenshots/00-control-room--dark--desktop--incident.png` (`sha256 6d5362469eaa...`) and `.tmp/admin-screenshots/04-control-room--dark--desktop--all-green.png` (`sha256 3c4f56299803...`, historical set). | v1.34 screenshots `test-results/admin-screenshots/00-control-room--dark--desktop--incident.png` (`sha256 53e85f791779...`) and `04-control-room--dark--desktop--all-green.png` (`sha256 8bebf1944e61...`), plus `135-SHELL-CHROME-REPORT.md`. | The shell remains a calm wayfinding layer, not a productized admin surface. v1.34 tightens the header/nav, command palette, flash, theme toggle, and `.ops-shell` wash while the proof rejects orbs, extra gradients, and decorative loops. |
| **focus** | v1.33 audit evidence: `.planning/milestones/v1.33-MILESTONE-AUDIT.md` records VERIFY-01 as substantial but with live mounted-admin smoke and UAT deferred. | v1.34 after evidence: `135-SHELL-CHROME-REPORT.md` proves bounded palette/sheet focus and focus return; `136-DUALVERIFY-REPORT.md` records `npm run test:e2e:admin-shell -- --reporter=line` passing 33/33. | Focus moved from a deferred final-review risk in v1.33 to a source-backed browser gate in v1.34. Palette and shortcut sheet retain `aria-modal="true"`, bound Tab inside, close on Escape, and return focus to the opener. |
| **theme parity** | v1.33 screenshot evidence: historical 40-shot light/dark matrix under `.tmp/admin-screenshots/`; v1.33 did not claim a system-dark screenshot gallery. | v1.34 after evidence: Phase 136 40-shot light/dark matrix (`expected_count: 40`, `actual_count: 40`) plus browser contrast, shell, and motion proof for explicit light, explicit dark, and system-dark. | The main gallery remains historical light/dark for comparability. system-dark is proven by browser gates, not silently folded into the historical 40-shot gallery. |

## Dark-Weighted Read

The dark before/after pairs carry the main narrative because v1.34's thesis is dark signature
quality with light parity. The strongest v1.34 deltas are:

- Dark raised surfaces no longer flatten: screenshots and depth gates show the surface-2 ramp in posture, drift, search rows, playbook workspace, and shell chrome.
- AA is no longer a subjective review item: static token contrast and browser axe contrast both report AA failures at 0, with AAA body findings kept advisory.
- Motion and glow are restrained and functional: path motion proves reduced-motion neutralization and patch-refire safety, while shell proof keeps gradients and flash chrome bounded.
- Light parity remains visible in the same 40-shot gallery shape: every dark claim has a light pair in the Phase 136 matrix rather than a separate or silent visual lane.

## System-Dark Handling

The historical 40-shot gallery remains light/dark only: 10 screen-state captures x 2 themes x
2 viewports. Phase 136 did **not** add a full system-dark screenshot matrix to the main gallery
because no concrete visual drift concern appeared.

system-dark is still proven. `136-DUALVERIFY-REPORT.md` records browser contrast, shell chrome,
and path-motion gates across system-dark. Those gates use Playwright `colorScheme: "dark"` without
forcing `localStorage["phx:theme"]`, so they exercise the media-query path rather than only explicit
dark.

## Artifact Hygiene

Generated PNGs are evidence artifacts, not committed source. The committed source of truth for
v1.34 after screenshots is the manifest entry in `136-ARTIFACT-MANIFEST.json`, including count,
paths, and checksums. No generated PNGs, traces, raw browser reports, `.tmp` content, or built
`scrypath_ops/priv/static/**` assets should be staged with this gallery.
