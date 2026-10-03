# Phase 172 — Implementation Research

**Source:** Existing project evidence, as selected by the maintainer; consolidated 2026-10-03. The three specialist reports below are the research for this phase, not inputs for another broad research cycle.

## Required evidence

- `.planning/research/v1.42/UI-STRUCTURE.md`: six surfaces, personas and three job loops, source locations, language and schema/promotion findings.
- `.planning/research/v1.42/UI-SYSTEM.md`: actual 48-component inventory, token authority, modal/control semantics, baseline screenshot observations.
- `.planning/research/v1.42/UI-AUTOMATION.md`: commands, CI placement, existing test weaknesses, recoverable-fixture and correlated-task/document requirements.
- `172-UI-SPEC.md`: reviewed implementation contract. Latest user example is redundant command-palette instructions three times on Control Room; one hint beside the actual control is sufficient.

## Implementation direction

Use existing OpsUi, LiveView URL parameters, service boundaries, shell JavaScript, and tests. Preserve host authorization and audit behavior. Start with a rendered shared-control/copy tracer and its tests, then complete shared semantics and recovery. Avoid adding a second design framework or a broad public recovery API.

Correlate newly enqueued replacement work from the retry return value with actual backend work and expected active-index document. The existing failed-sync fixture uses an invalid backend and is not replayable. Resolve the actual runtime index instead of the mismatched hardcoded fixture prefix. The original failed job is retained intentionally; no test may require historical failures to vanish.

Promotion is separately gated and observed through the exact returned backend task. Use existing Posture task-waiting/service patterns, not an old successful task or acceptance flash. Explicit invalid schema parameters must fail safely before any mutation and late observations must not replace another selection's state.

## Validation Architecture

Reuse the canonical commands and paths verified in UI-AUTOMATION.md and CONTRIBUTING.md. ExUnit/LiveView covers inexpensive behavior boundaries; mounted Playwright covers rendered navigation and real service seams. Shared CSS/control changes get bounded layout/focus/contrast checks plus direct before/after image inspection. No new required job or paid visual judge.

- Per change: targeted component/LiveView tests and relevant static checks.
- Per coherent wave: `mix verify.ops_ui` using the repository's configured environment; use documented Docker verifier if local BEAM/dependencies differ.
- Final integration: existing `make verify-mounted` in `examples/scrypath_ecommerce`; run required library/ops checks named by CONTRIBUTING. Broader screenshot/full verifier only once when needed after shared CSS changes.
- All seed/reset browser runs use a separate disposable Compose project. Never target the feedback instance on 4012.
- Plans must use runnable commands with nonzero/zero-test failure conditions, retain actual diagnostics, and map every requirement and UI consideration to executable evidence. No manual-only acceptance remains; optional maintainer feedback is not a gate.
- Visual review records source, fixture, theme, viewport, findings and disposition. Existing filename/width inventory does not prove pixel parity; contrast-only scan does not prove general accessibility.

## Closeout boundary

Use candidate evidence before marking completion; commit final tracking before final-source attestation. If hosted receipts arrive later, use external CI/PR receipts or a clearly separate planning-only successor. Do not forbid completion writes and recreate the old Phase 170 freeze conflict. No Phase 170 execution or historical milestone reopening.
