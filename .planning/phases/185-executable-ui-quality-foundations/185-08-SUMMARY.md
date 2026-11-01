---
phase: 185-executable-ui-quality-foundations
plan: "08"
subsystem: ui-preservation
status: source_ready_full_verification_pending
requirements: ["UIF-02", "UIF-03"]
requirements-completed: []
coverage:
  - id: D1
    description: All 61 named state/content cases are discovered; actual browser outcomes and before-side receipt remain pending.
    verification:
      - kind: other
        ref: /private/tmp/scrypath-phase185-execution/08-complete-raw-proof-inventory.log
        status: pass
      - kind: automated_ui
        ref: parent-owned distinct before-only collector and integrated candidate FULL gate
        status: unknown
    human_judgment: false
  - id: D2
    description: Source/clock/runtime/artifact validators reject incomplete and altered synthetic evidence under the new schema.
    verification:
      - kind: unit
        ref: /private/tmp/scrypath-phase185-execution/08-complete-raw-proof-alias-fixed-node.log
        status: pass
    human_judgment: false
  - id: D3
    description: Exact source-paired UI preservation requires actual qualified before and integrated candidate bundles; no actual pair exists yet.
    verification:
      - kind: automated_ui
        ref: Plan09 parent-owned real source pair
        status: unknown
    human_judgment: false
---

# Plan08 source handoff: actual browser proof pending

The owned source implements 61 exact named cases, deterministic dev/test fixture scenarios, per-theme/viewport observations, and a bounded raw-image evidence bundle. Discovery and focused source checks pass. No actual held-out browser run, historical before collector, candidate FULL acceptance, or actual pair comparison is claimed.

## Source and boundaries

- Existing real storefront, Control Room, health, failed work, settings, saved-search and Help routes provide the assertions. The E5 partial-field case identifies its narrower existing shared ResultUi component boundary explicitly; it is not whole-screen or backend parity.
- The existing dev/test-only seed endpoint adds partial-record, one-failed-job and per-case reset scenarios. The reset additionally requires the server Phase185 run prefix, clears only six named fixture tables and their id sequences, and binds the response into the data identity. Existing seed behavior and production router gating remain intact. Fixture failed-job timestamps use the existing internal Clock; production Clock behavior is unchanged.
- Nineteen overflow/long-text cases each require all nine light/dark/system-dark × 1440/768/390 observations; the other42 cases each declare one actual observation. The helper records visible copy, geometry, semantic state, real pending/failed transport, focus and exact raw PNGs. Measured timer/sampling data remains truthful per-run proof rather than a false cross-run performance-equality requirement.
- Selected PNGs plus every actual stationary sample PNG and raw before/after JSON sidecar are staged unchanged and packaged into one exclusive content-deduplicated v2 gzip/JSON bundle with verified per-member hashes. Existing 64MiB artifact/256MiB expanded bounds and 256 manifest-artifact count remain. At most2,769 internal members represent213 observations with up to6 image/state samples plus each selected PNG. Equal raw payloads share storage only after both hash and byte equality; every path is retained. The validator rejects tiny/mismatched rasters, missing observations, reused paths, unobserved bundle members, tampered bytes and malformed sample proof. Decoding groups already byte-identical inputs within one validation; differing PNG encodings still receive exact decoded RGBA comparison, with no masks or tolerance.
- The before-only61 schema is distinct from ordinary FULL. Product source, actual overlay build, exact per-side images and independently pinned common runtime/fixture/clock recipe remain separate. Historical validation reads committed Git objects and fails when required objects are unavailable. The overlay digest includes the transitive shared browser harness, lockfile and recipe inputs.

## Verification performed

- Final focused evidence/pair/bundle/target suites:72 passed, zero failed/skipped; actual log `/private/tmp/scrypath-phase185-execution/08-complete-raw-proof-alias-fixed-node.log`.
- Real-node discovery:61 cases in2 files, `/private/tmp/scrypath-phase185-execution/08-complete-raw-proof-inventory.log`. Discovery parses tests; it is not TypeScript typechecking or UI execution. No typecheck script/package was added.
- Both changed Elixir fixture files pass the installed-toolchain formatting check; shell syntax, JavaScript syntax and scoped diff checks pass.
- Actual missing-bundle behavioral RED is retained in `185-08-raw-bundle-RED.json`, with unmodified reports outside the checkout. A controlled replay against the exact prior validator bytes was machine-classified RED_EVIDENCE_OK before restoring the fix and rerunning GREEN. The earlier non-exported-function setup failure remains explicitly invalid and separate. No RED commit or historical report rewriting is claimed.
- Raw v2 packaging feasibility checked213 existing baseline image observations including1,065 selected/sample/state members:78MB logical bytes,21.5MB unique payloads,15.3MB packed, exact original-byte roundtrip. This is packaging evidence only and cannot satisfy any held-out state obligation.
- Source-only delta review and bundler review records live under `/private/tmp/scrypath-phase185-execution/`; reviews are in-thread and do not imply independent or aesthetic approval. The final raw-sampling and producer/packer alias closures are recorded in `08-raw-sampling-closure-review.json` and `08-alias-closure-review.json`; the former blocker is closed by the latter source recheck.

## Earlier failures and scope reconciliation

The initial missing-spec/timeout attempts and HALTED summary remain preserved in Git history and `wave/08-incomplete-reconciliation`; they are not accepted or rewritten. Later source continuations added the missing tests and repaired source/runtime trust defects. Parent intervention stopped one idle committed checkpoint for review before any further runtime attempt. Plan06 is independently complete/integrated; Plan07 source is integrated with browser acceptance pending. There is no renewed stop on their already-authorized source work.

## Next action

Parent reviews the final source, integrates the candidate, runs the separately identified qualified before-only61 collector and the ordinary integrated candidate FULL gate within the existing limits, then compares the real bundles in09. Actual61 outcomes, exact source-pair images/copy/state and final hosted phase proof remain required. Requirements stay incomplete; missing automated evidence is not human judgment or UAT. The retained preview and original parent capture stack are untouched. No user action is needed for the current source work.
