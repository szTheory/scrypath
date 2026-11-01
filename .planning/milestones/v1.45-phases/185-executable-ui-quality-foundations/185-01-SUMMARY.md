---
phase: 185-executable-ui-quality-foundations
plan: "01"
subsystem: ui-verification
status: complete
requires: []
provides:
  - Canonical repository-command contrast enforcement
  - Source-bound focus declaration and background checks
  - Real negative subprocess witnesses and raw threshold checks
affects: [185-02, 185-04]
tech-stack:
  added: []
  patterns: [bounded-source-reading, canonical-subprocess-witness]
key-files:
  created:
    - test/mix/tasks/ui_contrast_contract_test.exs
    - .planning/phases/185-executable-ui-quality-foundations/185-01-RED.json
  modified:
    - examples/scrypath_ecommerce/contrast-checker.mjs
    - scrypath_ops/assets/css/contrast-pairs.mjs
    - dev/mix/tasks/verify.phase99.ex
    - test/mix/tasks/verify.phase99_test.exs
requirements-completed: [UIF-04]
---

# Phase 185 Plan 01 — Required contrast enforcement

The existing required repository command now runs the dependency-free checker, with ordinary semantic content labels at raw AA 4.5 and focus indicators at raw 3.0. CSS values are unchanged. Both themes, named shell/resting/selected/menu surfaces and the current global/component indicator declarations are covered by bounded source checks.

## Tasks and commits

- `0831eeb4`: RED tracer: actual dark secondary-content mutation at 3.6826195916522693:1 passed the old public command, making the outer test fail as intended.
- `73c2afc2`: GREEN tracer: root focused-test integration and corrected ordinary text roles.
- `ea8f14c3`: RED expansion: the public command accepted complete removal of the dark theme. The temporary-copy names were corrected to include the OS process ID after overlapping runs exposed a collision.
- `35107960`: GREEN expansion: complete theme/property validation, fixed text/decorative roles, exact alpha lockstep, focus/source/background bindings, raw threshold checks, and bounded checker launch.

The two checked-in RED records preserve actual TAP reporter output from a Node test invoking the real ExUnit witness. The GSD classifier returned `RED_EVIDENCE_OK` for each, followed by semantic inspection of the planned assertion. A preliminary incomplete reporter read and one overlapping invalid run were rejected rather than treated as authority; the final records contain the completed isolated runs.

## Verification

Installed supported toolchain: Elixir 1.19.5 / OTP 28.5, with four schedulers. No package acquisition or installation occurred.

- Tracer focused ExUnit checks: passed.
- Initial canonical tracer run: passed; log `/private/tmp/phase185-01-canonical.log`.
- Expanded canonical subprocess suite: passed, including missing/duplicate themes, missing or unsupported colors, invalid roles, text relabeled decorative, muted alpha drift, empty pairs, changed focus declaration, changed token background, changed literal shell background, new unbound focus, and broken checker launch.
- Raw numeric checks: below/at/above 4.5 and 3; black/white 21; the borderline #777777/white text failure; invalid role and NaN rejection.
- Checker self-test: passed after the final source changes.
- Final `mix verify.repository_contracts`: passed, with the full existing focused lane plus the new contract. Log `/private/tmp/phase185-01-verified.log`; final application source `35107960`.
- `node --check` and `git diff --check`: passed.

The unmodified checker reports zero AA failures and 135 AAA advisories after the expanded comparisons. Reports are outside the checkout at `/private/tmp/phase185-contrast-reviewed/`. AAA remains advisory.

## Scope and limits

The reader checks the currently authored named themes, opaque surface floors, fixed focus inventory and explicit background declarations. Muted opacity retains the existing sRGB compositing math. The indicator inventory includes explicit outline suppressions, which do not claim a visible indicator. Source contracts do not establish complete accessibility, actual browser cascade behavior, whole-product visual quality, independent review or maintainer aesthetic approval. Rendered preservation and held-out browser evidence remain assigned to later plans.

The UIF-04 unclassified edge-category assumption remains unresolved/flagged; executable threshold and malformed-input evidence does not silently resolve the classifier category. No retained-preview operation, recoloring, baseline acceptance, new dependency, release or merge occurred.

## Planning deviation

The existing required lane rejected Plans 08/09 for verification-backstop annotations. The maintainer approved correcting those to prospective automated-test obligations, retaining all 61 coverage pairs, and keeping subjective rendered critique nonblocking. The correction and its limits are in AGENTS.md and 185-PLAN-REVIEW.md. The guard itself was preserved. The unrelated config edit remains outside owned commits.

## Self-Check: PASSED

Both named created artifacts exist; plan-scoped RED/GREEN commits are reachable on the current branch; the actual canonical command passed after the last application source change. No phase-wide completion is claimed.
