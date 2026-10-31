---
phase: 185-executable-ui-quality-foundations
plan: "05"
status: changes_required
reviewed_commit: 2f163d878754c18cb608b5585ed5e388ab3bcfee
---
# Plan 05 parent review — corrective continuation

The original executor completed and returned a clean worktree and 135 entry-state observations. Parent code review found the following blockers. Do not count source/manifest completeness as matched parity. No CSS/controller/template/generator UI edits have started. Correct the tooling before those edits.

The initial "unseeded" diagnosis was RETRACTED after tracing Compose startup: docker-e2e-entrypoint.sh invokes e2e.prepare plus demo.seed (incident). Host copy has seeded failed jobs; standalone empty allowlist is configured behavior. The default entry matrix is valid observation coverage, not healthy/populated-state proof. Plan08 separately owns all61 held-out state/category obligations. Verify expected fixture state and its stability; do not redesign product defaults or silently force all-green.

Original raw evidence and session bytes were copied byte-for-byte to /private/tmp/scrypath-phase185-execution/review-archive-unseeded-68f11bdc451747c7. The name reflects the initial diagnosis, not the final adjudication. transport-record.json records all hashes and the confirmed raw-pg_dump nondeterminism. The only original disposable project was ownership-verified and torn down; retained preview remains untouched. The active ui-session.json path is clear.

### BL-01: Editable session metadata selects teardown authority
**File:** scripts/ci/ui_preservation.cjs:577
**Issue:** Session project regex and matching owner labels are insufficient because the supplied ID is recoverable from the project name; a forged session can select another valid Phase185 stack and arbitrary override paths/retained inventory.
**Fix:** Preserve an independent creation/ownership record outside candidate source. Bind it to the specific fixed session path/creation, expected project/session ID, source, ports, exact volumes, allowed Compose files/paths and artifact roots. Compare all editable session fields against that authority and real Docker facts before mutation. Recompute retained identity from actual UI-PREVIEW read-only. Reject unknown/foreign/external resources. Avoid trusting arbitrary Compose overrides for destructive down. Scope deletion to independently verified owned IDs/names, retaining primary failure. State threat-model limits honestly; this is input validation against editable records, not protection against a malicious host user who already controls Docker.

### BL-02: Baseline manifests validate against themselves
**File:** scripts/ci/ui_preservation.cjs:493
**Issue:** capture_sha256 is written but never checked, and source expectations are derived from the manifest under validation.
**Fix:** Verify checksum using its exact documented excluded-field serialization, and bind raw manifest-byte digest/source/tree/environment to the independently preserved creation/session authority. Recompute committed Git tree identity for the frozen source, preserve historical-main meaning, validate current remote main independently for candidate and canonical origin. Reject tampered provenance even when attacker recomputes a self-checksum. Add production-path forged-session/manifest negatives, not only self-contained predicate tests.

### BL-03: Matrix IDs do not bind observation metadata
**File:** scripts/ci/ui_preservation.cjs:151
**Issue:** ID ending1440 can claim width768 and viewport.width390; allowed sets are checked independently. Per-entry platform/browser/data identity are also not bound strongly enough.
**Fix:** Require exact deployment/surface/theme/width/route/viewport fields for every canonical ID, one each. Validate real PNG IHDR dimensions against viewport and declared artifact kind, finite bounds/regular files/no symlink escapes, copy metadata consistency, and all per-entry environment fields. Preserve truthful full-page dimensions. Reject missing/forged fields before comparisons.

### BL-04: Data identity is nondeterministic and incomplete
**File:** scripts/ci/ui_preservation.cjs:406
**Issue:** Two consecutive dumps of the same unchanged database differ in random restrict/unrestrict nonce lines (parent proved this read-only). Settings rendered by sync-and-index are omitted. Index listing can truncate at1000; document totals need finite progress validation.
**Fix:** Hash canonical stable state (or normalize only dump transport nonces, never meaningful rows/times). Include index settings and all rendered-state inputs; bound and validate pagination/limits rather than silently truncating. Prove two unchanged reads equal and real record/settings changes differ. Preserve raw proof, do not relabel old digest as stable.

### BL-05: Candidate startup reseeds and failure skips cleanup
**File:** scripts/ci/ui_preservation.cjs:507
**Issue:** Candidate up recreates web using entrypoint that runs prepare+seed again on the very volumes it must match; seed deletes/recreates IDs and uses current time. Post-start failure's teardown callback is empty.
**Fix:** For UI-only candidate preserve already-owned seeded DB/search state across app/image replacement without preparing/seeding again. Prove pre/post state equality before browser. On any post-start failure tear down only independently owned resources and preserve the primary error if cleanup also fails. Retain successful stack only deliberately for comparison. Test actual lifecycle path with injected bounded adapters, then validate real same-source pipeline.

### BL-06: Process and artifact transport bounds are incomplete
**File:** scripts/ci/ui_preservation.cjs:63
**Issue:** sourceIdentity uses unbounded execFileSync for Git tree listing; inherited GIT_* variables can redirect source reads. Original artifact root/session absolute paths are inside an executor worktree, so standard GSD cleanup would delete/break evidence.
**Fix:** Finite argv/process/output limits for all Git/build/browser calls, clean Git authority environment and canonical origin check. Put new disposable evidence in a stable owned external ui-review-artifacts/phase185 root under /private/tmp/scrypath-phase185-execution, outside implementation worktrees and Playwright cleanup. Keep byte-for-byte old archives plus separate transport mapping; never rewrite old capture manifests. Validate paths/regular files/bounds against independent creation record.

### WR-01: Session platform reports host instead of browser
**File:** scripts/ci/ui_preservation.cjs:484
**Issue:** Session says darwin-arm64 while captures are linux-arm64. Pairing uses manifests so current mismatch is metadata, not proof of wrong browser.
**Fix:** Store and independently validate actual browser platform/version, keep host orchestration platform separate if useful.

### WR-02: Repeatability and expected entry-state assertions
**File:** examples/scrypath_ecommerce/e2e/ui-review.mjs:110
**Issue:** Seeded default entries are observed, but current server-generated Checked timestamps vary across captures. Plan05 asks fixed fixture/time and real same-state before/after evidence; existing baseline alone does not prove repeatable image/copy pairing.
**Fix:** Validate existing expected incident/standalone-empty entry fixtures, and exercise a same-source real before/after comparison before declaring the helper ready. Use existing deterministic fixture/clock seams where available. No stdlib/VM monkeypatching, fake image edits, before-HTML replay, broad pixel/copy masking or auto-approval. Do not change product defaults or add runtime product flags. If strict time repeatability cannot be implemented inside the existing test harness, finish all other authorized repairs, preserve real proof of the remaining difference, and return a concrete minimal test-only clock-seam proposal (exact files and validation) for parent review. Do not label unresolved parity complete, but do not stop independent repairs merely because this is uncertain.

# Required verification
- Meaningful new failing regressions for actual findings before their fixes; preserve native failure output with a supported machine-classified adapter if necessary. No fake RED from imports/syntax.
- node --test scripts/ci/ui_preservation.test.cjs examples/scrypath_ecommerce/e2e/ui-review.selftest.mjs; all logic fixes must have executable behavior evidence, not syntax-only/human-needed status.
- node --check changedJS and git diff --check.
- Actual source-pinned owned capture before and same-source candidate/data-pair self-check where possible. Do not claim absent exact-source evidence, screenshots, healthy states or subjective design approval.
- No new dependencies/host installations. Existing locked Docker build resolution is allowed. Existing app/test modules/tooling may be reused.
- Keep actual remaining blocker(s) explicit in REVIEW-FIX and updated Plan05 SUMMARY. Human verification is not a substitute for required automated evidence; subjective critique stays nonblocking/pending without simulated approval.
