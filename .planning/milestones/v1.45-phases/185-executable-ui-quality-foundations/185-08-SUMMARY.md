---
phase: 185-executable-ui-quality-foundations
plan: "08"
subsystem: ui-preservation
status: complete
requirements: ["UIF-02", "UIF-03"]
requirements-completed: []
coverage:
  - id: D1
    description: All61 named state/content cases execute on qualified before and integrated candidate; 213observations and426selected images validate.
    verification:
      - kind: other
        ref: /private/tmp/scrypath-phase185-execution/08-complete-raw-proof-inventory.log
        status: pass
      - kind: automated_ui
        ref: accepted-before-r15.json and accepted-candidate-r4.json in /private/tmp/scrypath-phase185-execution
        status: pass
    human_judgment: false
  - id: D2
    description: Source/clock/runtime/artifact validators reject incomplete and altered synthetic evidence under the new schema.
    verification:
      - kind: unit
        ref: /private/tmp/scrypath-phase185-execution/08-complete-raw-proof-alias-fixed-node.log
        status: pass
    human_judgment: false
  - id: D3
    description: Independently authorized exact source-paired comparison and unchanged repeat cover61cases/213observations/426images.
    verification:
      - kind: automated_ui
        ref: /private/tmp/scrypath-phase185-execution/state-pair-r15-r4-unchanged-result.json
        status: pass
    human_judgment: false
---

# Plan08: complete held-out source and runtime proof

Current outcome: the refreshed qualified before R15 and integrated candidate R4 are valid/eligible at their original source identities. The exact comparison and completed repeat pass all 61 cases / 213 observations / 426 selected images with zero differences. Every current held-out image, body-text record and selected raw state is byte-identical to content already actually inspected in the previous source-bound review. Current source-bound required and full hosted acceptance has passed; final tracking-source terminal attestation remains mandatory. The historical handoffs below retain their original cutoffs.

The source implements 61 exact named cases, deterministic dev/test fixture scenarios, per-theme/viewport observations, and a bounded raw-image evidence bundle. Earlier implementation-only notes below do not replace the actual completed runs, comparison and inspection recorded above.

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

## Task Commits

- **Task 1: Exercise held-out collection, request and protected-action states** — integrated source evidence is included in candidate `4db097d92dfe8a221da3625d70dc5647831c3864`.
- **Task 2: Protect exact content, responsive overflow, names and focus semantics** — integrated source evidence is included in candidate `4db097d92dfe8a221da3625d70dc5647831c3864`.
- **Task 3: Compare actual source-paired state receipts** — comparator integration evidence is included in candidate `4db097d92dfe8a221da3625d70dc5647831c3864`.

These are source-integration evidence identities, not claims that the candidate commit authored each task or supplies a missing task-specific RED commit.

## Earlier failures and scope reconciliation

The initial missing-spec/timeout attempts and HALTED summary remain preserved in Git history and `wave/08-incomplete-reconciliation`; they are not accepted or rewritten. Later source continuations added the missing tests and repaired source/runtime trust defects. Parent intervention stopped one idle committed checkpoint for review before any further runtime attempt. Plan06 is independently complete/integrated; Plan07 route coverage passed in the R4 integrated browser run. There is no renewed stop on their already-authorized source work.

## Next action

The refreshed before-only61 collector, ordinary candidate FULL gate and exact pair are complete within the approved limits. `state-pair-r15-r4-unchanged-result.json` records that the report SHA-256 is identical before and after the repeat for all 61 / 213 / 426 comparisons. Requirements stay incomplete until the fresh hosted candidate and terminal exact-SHA proof pass; missing automated evidence is not human judgment or UAT. The original capture session was safely torn down and the retained preview remains untouched. No user action is needed for the authorized closeout.

## Earlier integrated evidence at C7fa

Qualified product Q `7886eb10449dcb55945d1ab886e6c78752cc73cf` was built with harness H `95dfef9f30515d785c6eba4cff93a282f38d6a7f`; candidate product/build C was `7fa0ab07382a5a62642639470ce55b2341c06b2d`. Common fixture overlay `sha256:4f6a352a34ac57f3a6a29fbc09744c92b83480d6656cd70442fa5068945eef2e` and independently inspected image/runtime/installed Node facts bind those original canonical raw receipts. Before R14 ran 764.67s and candidate R3 1151.97s within limits; both exited 0 with no retries, unexpected/skipped outcomes or remaining owned containers/networks/volumes. Candidate R3 passed 254 cases, including the 61 held-out tests. These original receipts remain immutable historical evidence.

The preservation-v2 contract independently proves pointer-neutral full-page and actual viewport-hover images with stationary raw sidecars; pair-v3 compares exact decoded RGBA, per-shot state/focus/hover, copy, geometry, actions/transport and semantic assertions. The original 61/213/426 pair matched. Original receipts remain `heldout-runs/phase185-before-95dfef9f-r14/phase185-before-only-evidence.json` and `heldout-runs/phase185-candidate-7fa0ab07-r3/phase105-evidence.json`. Pointer references are not raw CLI inputs. Original authority, output and repeat remain under the external execution root.

The original 135-entry/546-image global candidate matrix, its unchanged repeat, actual image/copy inspection and clean owned teardown are also complete at the recorded C7fa source. The preserved external receipts are `global-candidate-inspection-combined.json`, `global-comparison-7fa0ab07-repeat.result.json`, and `global-owned-teardown-7fa0ab07.result.json`. The later exact-input reconciliation for e445 confirms that this CI-only change did not alter the product, global capture harness or its inputs; no replay or relabeling is claimed. All failed/historical attempts retain original logs, source and outcomes. Actual rendered/copy critique is separately labeled native in-thread and nonblocking. No independent or aesthetic approval is inferred.

## Required refresh after hosted diagnosis

Hosted source failures required token lint/type cleanup, workflow clock transport and a verifier artifact-root guard repair. That 28-file common overlay update required refreshing the source-bound held-out proof: before R15 at harness H `9473a51d` and ordinary full candidate R4 at product/build C `4db097d9`. They are accepted as distinct immutable receipts. Canonical pair authority is `state-pair-authority-r15-r4.json`; comparison output is `ui-review-artifacts/phase185/state-pair-comparison-r15-r4/ui-state-pairs.json`, and the first and completed repeat logs are `state-pair-r15-r4-first.log` and `state-pair-r15-r4-repeat.log`. `state-pair-r15-r4-unchanged-result.json` pins identical before/after report hashes. Both sides contain 61 cases, 213 observations and 426 images; the comparison and repeat report exact-match, zero mismatches. The before and candidate inspection-reconciliation records verify all 426 images, body text and selected raw states against content already inspected; this is evidence reuse based on exact bytes, not a new independent review.

At candidate source `4db097d9`, local core and repository gates passed. Hosted run `41295225239` passed core/package/backend/coverage/compatibility but failed its repository job because the existing locked `pngjs` test prerequisite was absent and run-owned handoff paths differed. The approved CI-only repair at `e445a2c4` installs the already-locked demo dependencies with `npm ci --ignore-scripts` and browser download disabled, and aligns artifact/run paths. `candidate-input-reconciliation-e445a2c4.json` records that product source, common overlay and runtime remain unchanged, so no held-out or global image replay is required. Fresh hosted acceptance for e445 is pending; final Plan10 tracking and terminal exact-SHA proof remain required.

## Implementation-plan disposition

The actual current local source-bound proof completes this plan. The later af78 hosted CI transport retest and final tracked-source attestation belong to Plan10; neither is silently certified here. Current input equality is recorded in `candidate-input-reconciliation-af78dd8f.json`; original canonical and global receipt sources are preserved.

## Final candidate closeout cutoff

Current candidate [41318243156](https://github.com/szTheory/scrypath/actions/runs/41318243156) at `fa42d99ee3ad5290ea7d8ab089ba076c5e25558c` passed all five required jobs, coverage and exact-source immutable attestation, and its full advisory browser lane succeeded after the diagnosed transport, frame-safe accessibility, runtime-handoff, serial full-suite and cold-start repairs. Original local full/pair/global receipts retain their source identities. Final tracked-source terminal attestation remains mandatory and is not certified by this pre-dispatch record. The earlier pending-hosted statements are historical cutoffs; this plan implementation is complete. No future terminal result is asserted.

## Serial full-suite source and proof boundary

The current source passed the complete serial full lane, immutable archive verification and independent canonical receipt recomputation. The batches preserve one worker, zero retries, original traces, the exact discovered union and clean owned teardown within the existing limits. The cold local path explicitly acquires only the existing service images before startup; failed acquisition prevents execution.

[Source reconciliation](185-SOURCE-AUDIT.md#serial-full-suite-source-and-proof-boundary) records the six changed outer overlay files, unchanged product/capture inputs, preserved original pair/global identities, discarded trace experiment and excluded failed/superseded runs. The actual current receipt is `candidate-r10-full-acceptance.json`. Final tracking-source terminal acceptance remains a separate mandatory external gate; no independent/design/risk approval or retained-preview action is inferred.
