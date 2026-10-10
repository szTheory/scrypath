# Operator UI feedback follow-up — 2026-10-08

## Authorized scope

The maintainer reviewed the implemented Phase 174 desktop UI and requested a concrete cleanup of confusing “Recovery target” terminology, the warm yellow-gray page and blue context panel, the verbose all-clear verdict, timestamp copy noise, and the inset per-schema action. This is a focused follow-up on the existing draft PR, not Phase 175 execution or a brand redesign.

## Decisions and resulting behavior

- Navigation displays destinations. Control Room and Search health display “Selected schema” as neutral local context; workflow pages retain their existing schema controls. Full identifiers wrap at namespace separators and remain available; navigation, palette, browser history, and URL authority preserve the canonical schema selection.
- The fleet verdict labels its scope “Search sync · all schemas.” The all-clear headline is “No sync failures found,” with one Search health entry. Removed the duplicate counts, “No affected schemas” sentence, recovery-target repetition, and promotional-readiness prose. This headline describes the available sync observations; it does not establish absence of index drift, current search-result correctness, or promotion readiness.
- Failure and unavailable-status cases retain their affected schemas, source evidence, selected action context, and concrete guidance. Failure copy says “Sync needs attention”; status read errors say which schemas could not be checked. Search health retains per-schema diagnostic signals, exact timestamps, and distinct queue/source states. Routine Next checks advice is omitted in the all-clear state.
- Light surfaces use `#f5f6f8` (page), `#ffffff` (panels), `#edeff2` (muted surface), and `#d7dbe1` (border). Existing violet, copper, dark surfaces, and theme preference behavior remain the visual identity.
- The human-readable timestamp is a keyboard-accessible copy button. It writes the unchanged source ISO value immediately on activation and reports success only after clipboard resolution. A polite, brief toast confirms success; clipboard rejection/unavailability opens selectable exact evidence and retains the error until dismissal. Later copy attempts supersede pending earlier feedback. Hook destruction invalidates pending attempts, and the feedback DOM island survives LiveView patches.
- Per-schema inspection actions are plain navigation links aligned with the card's heading and metrics, with standard hit area and focus indication. Refresh flashes use the bottom corner across desktop/mobile so they do not obstruct the next refresh.
- No dependencies, new recovery capabilities, auth policy, persistence semantics, or CI gates were added.

## Verification

- `cd scrypath_ops && mix precommit`: 275 tests and two doctests passed; compilation with warnings as errors and formatting passed.
- Root canonical `mix verify.ops_ui`: 275 tests and two doctests passed on owned Postgres 55495.
- Static token/manifest contrast: zero AA failures; 36 AAA findings remain advisory.
- The final source browser run passed 39/41 cases, including all 11 Phase 174 journeys and all timestamp-copy, shell, and operational-time checks. One monolithic status matrix exhausted its 90-second budget after 99 of 108 visits; the standalone matrix lost its LiveView connection after repeated visits. Both original outcomes are preserved. The same 216 status scenarios are now split by entrypoint, theme, and width into 24 independent cases with the default timeout, plus eight other status tests; the split status run passed all 32 cases (zero failures/errors/skips), including all 216 scenario combinations. The native source report with its two failures and the separate passing status report are preserved alongside this record. This gives 63 unique browser cases with passing evidence across those two runs; it is not a single 63/63 report. No checks or scenario combinations were removed.
- After the final accessibility fix keeps the empty polite live region present without visible layout noise, the timestamp-copy suite passed again: 14/14, zero retries/failures/errors/skips. Its native report is preserved separately. All seven runtime files match both running preview images by SHA-256. The evidence JSON records native report digests and 63 unique passing case identities across the three reports; the focused copy rerun repeats existing cases.
- Manual desktop/mobile inspection found and corrected an inherited toast font, link-padding cascade conflict, and refresh-toast obstruction. Mechanical design detection ran once: ten advisory findings concern pre-existing overlay opacity and pill/radius recipes; none concern new declarations.

First browser pass: 35/41 passed. Four failures exposed the inherited toast font and a singular-only test expectation; two operational-time cases timed out when a refresh notification covered the toolbar. Final fixes address those causes; the first report is retained outside the checkout without rewriting its failures.

## Primary guidance

Clipboard success feedback follows [W3C status-message guidance](https://www.w3.org/WAI/WCAG21/Understanding/status-messages), including polite announcement without focus theft. Clipboard failure and activation constraints follow [MDN's Clipboard API guidance](https://developer.mozilla.org/en-US/docs/Web/API/Clipboard_API). Existing project PRODUCT.md, DESIGN.md, DESIGN-TOKENS.md, LiveView patterns, and relevant prompts supplied the product and implementation context.

## Preservation and evidence limits

The original dirty checkout, frozen Phase 173 checkout, and preview on port 4012 are preserved. The Phase 174 review stack on port 4014 is rebuilt without startup reseeding; scoped browser tests use its disposable test fixtures, after which the demo is restored to the named all-green review scenario. Owned browser/validation containers are removed. The Phase 174 original verification and exact-SHA receipt at a18c456 remain historical evidence for that source; this follow-up has separate evidence. Phase 175 remains unstarted.

Hosted follow-up checks are tracked on draft PR #95 against the final follow-up commit. The existing a18c456 closeout receipt is not reused to verify these changes.
