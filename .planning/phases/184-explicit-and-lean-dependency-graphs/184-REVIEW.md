---
phase: 184-explicit-and-lean-dependency-graphs
reviewed: 2026-10-30T23:27:00Z
depth: standard
files_reviewed: 59
files_reviewed_list:
  - .github/workflows/ci.yml
  - .github/workflows/publish-hex.yml
  - .github/workflows/release-please.yml
  - .github/workflows/verify-published-release.yml
  - .github/workflows/website.yml
  - .github/workflows/workflow-security.yml
  - CONTRIBUTING.md
  - dev/mix/tasks/verify.ops_ui.ex
  - dev/mix/tasks/verify.phase99.ex
  - docs/local-demo-docker-dx.md
  - examples/phoenix_meilisearch/README.md
  - examples/scrypath_ecommerce/Dockerfile
  - examples/scrypath_ecommerce/README.md
  - examples/scrypath_ecommerce/compose.phase173.yaml
  - examples/scrypath_ecommerce/compose.yaml
  - examples/scrypath_ecommerce/config/config.exs
  - examples/scrypath_ecommerce/config/dev.exs
  - examples/scrypath_ecommerce/config/prod.exs
  - examples/scrypath_ecommerce/config/runtime.exs
  - examples/scrypath_ecommerce/docker-e2e-entrypoint.sh
  - examples/scrypath_ecommerce/mix.exs
  - examples/scrypath_ecommerce/scripts/phase173-standalone-entrypoint.sh
  - examples/scrypath_ecommerce/scripts/verify-dependency-boundaries.sh
  - examples/scrypath_ecommerce/scripts/verify-e2e.sh
  - guides/support-and-compatibility.md
  - mix.exs
  - scripts/ci/beam_cache.test.cjs
  - scripts/ci/ecommerce_build.test.cjs
  - scripts/ci/ecommerce_lifecycle.test.cjs
  - scrypath_ops/README.md
  - scrypath_ops/config/config.exs
  - scrypath_ops/config/dev.exs
  - scrypath_ops/config/prod.exs
  - scrypath_ops/config/runtime.exs
  - scrypath_ops/config/test.exs
  - scrypath_ops/lib/scrypath_ops/application.ex
  - scrypath_ops/lib/scrypath_ops/integrations/sigra/capability.ex
  - scrypath_ops/lib/scrypath_ops/integrations/sigra/gating.ex
  - scrypath_ops/lib/scrypath_ops/security.ex
  - scrypath_ops/lib/scrypath_ops_web/dev_router.ex
  - scrypath_ops/lib/scrypath_ops_web/endpoint.ex
  - scrypath_ops/lib/scrypath_ops_web/live/search_live.ex
  - scrypath_ops/lib/scrypath_ops_web/telemetry.ex
  - scrypath_ops/mix.exs
  - scrypath_ops/test/scrypath_ops/application_test.exs
  - scrypath_ops/test/scrypath_ops/integrations/sigra/gating_test.exs
  - scrypath_ops/test/scrypath_ops/integrations/sigra/on_mount_test.exs
  - scrypath_ops/test/scrypath_ops/security_test.exs
  - scrypath_ops/test/scrypath_ops/security_validation_test.exs
  - scrypath_ops/test/scrypath_ops_web/live/search_saved_searches_test.exs
  - scrypath_ops/test/scrypath_ops_web/router_test.exs
  - test/mix/tasks/dependency_audit_test.exs
  - test/mix/tasks/dependency_boundary_contract_test.exs
  - test/mix/tasks/verify_capability_test.exs
  - test/mix/tasks/workflow_wiring_test.exs
  - test/release/consumer_smoke_test.exs
  - test/release/ops_dependency_boundary_test.exs
  - test/release/package_metadata_test.exs
  - test/scrypath/docs_contract_test.exs
findings:
  critical: 2
  warning: 3
  info: 0
  total: 5
status: issues_found
---

# Phase 184: Code Review Report

**Reviewed:** 2026-10-30T23:27:00Z
**Depth:** standard (configured depth)
**Files Reviewed:** 59 source, workflow, documentation, and test files
**Status:** issues_found

## Summary

The review covered the supplied canonical scope against the phase baseline and current source at `fcbd30bb946b782e65df0f93c0c0e7a1ea73dbdb`, including the latest nil-sudo recovery correction. The four supplied `mix.lock` files were read as dependency context and excluded from the source-file count. Scope metadata reported `resolved`; no structural pre-pass or external reviewer evidence was supplied. Project skill discovery and the configured reviewer-skills query returned no project/configured skills.

Two blocking counterexamples remain: a legitimate partial optional-diagnostics graph cannot start, and malformed identity values can authorize a sensitive action. Three warnings concern failure cleanup, confirmation-path validation, and the documented direct-development toolchain floor.

The corrected nil-sudo path reaches confirmation for valid identity context; it is not reported as an outstanding defect. This review does not attest final merged-source CI or accept dependency risk. Final exact-source closeout remains pending. The recorded Cloak/Cloak Ecto audit findings remain nonzero and unaccepted; earlier candidate evidence is not terminal attestation for this source.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: A host with metrics but no poller cannot start ScrypathOps

**Classification:** BLOCKER
**File:** `/Users/jon/projects/scrypath/scrypath_ops/lib/scrypath_ops_web/telemetry.ex:1-15`
**Related:** `/Users/jon/projects/scrypath/scrypath_ops/lib/scrypath_ops/application.ex:21-27`; `/Users/jon/projects/scrypath/scrypath_ops/mix.exs:67-68`

**Issue:** The new compile guard checks only `Telemetry.Metrics`, but the resulting supervisor unconditionally starts `:telemetry_poller`. These packages are independently optional. A mounted host may legitimately include `telemetry_metrics` for its own reporting while omitting `telemetry_poller`. That makes the Ops telemetry module compile and causes the Ops application to add it to its children, after which startup fails because the poller module does not exist. The current absent-dependency consumer proof removes all diagnostics together and misses this partial graph.

**Evidence:** A fresh Elixir 1.19/OTP 28 VM loaded the real existing `Telemetry.Metrics` dependency beam and compiled the current `telemetry.ex`, with no poller code path. `Code.ensure_loaded?(Telemetry.Metrics)` returned `true`, `Code.ensure_loaded?(:telemetry_poller)` returned `false`, and `ScrypathOpsWeb.Telemetry.start_link([])` returned an `ArgumentError`: `The module :telemetry_poller was given as a child to a supervisor but it does not exist`. No application, database, or browser was started.

**Fix:** Make diagnostics construction/startup require every capability it actually starts, or omit the poller child when that optional capability is absent. For example, require both `Code.ensure_loaded?(Telemetry.Metrics)` and `Code.ensure_loaded?(:telemetry_poller)` before compiling/starting the complete diagnostic supervisor. Preserve direct-development diagnostics. Extend the mounted consumer proof with a metrics-present/poller-absent graph and assert that core Ops children still start.

### CR-02: Non-nil malformed identities authorize protected Sigra actions

**Classification:** BLOCKER
**File:** `/Users/jon/projects/scrypath/scrypath_ops/lib/scrypath_ops/integrations/sigra/gating.ex:116-119`
**Related:** `/Users/jon/projects/scrypath/scrypath_ops/lib/scrypath_ops/integrations/sigra/gating.ex:74-96`

**Issue:** `valid_identity?/1` validates binary IDs, then treats every other non-nil term as a valid identity. Booleans, collections, and arbitrary maps therefore satisfy the new identity gate. `OperatorContext.build/2` can retain these values from host scope fields, so the struct check does not establish valid user/organization identity. With a fresh sudo timestamp, the gate audits and invokes destructive callbacks instead of denying the malformed context. This violates the phase's requested-Sigra invalid-context denial contract. This is a demonstrated malformed-host-context authorization failure, not a claim of a remotely demonstrated authentication bypass.

**Evidence:** Current OperatorContext, capability, Security, and Gating source modules were loaded into a fresh VM with the actual Sigra/Phoenix dependency beams. In `OPSUI_AUTH_MODE=sigra`, an OperatorContext with `user_id: false`, `active_org_id: false`, and `sudo_at: DateTime.utc_now()` caused `gate_sensitive_action(socket, :reindex, callback)` to return the callback's `:protected_action_ran` marker. The corresponding host scope also contained those false IDs. No app or database was started.

**Fix:** Define and enforce the supported identity representations explicitly, such as nonblank valid UTF-8 binary IDs and supported integer IDs, and reject booleans and container values. Add malformed scalar/container cases for both identity fields to the all-actions denial test, while retaining positive coverage for each supported ID type.

## Warnings

### WR-01: Failed target-asset extraction leaves a container outside cleanup ownership

**Classification:** WARNING
**File:** `/Users/jon/projects/scrypath/examples/scrypath_ecommerce/scripts/verify-dependency-boundaries.sh:393-409`
**Related:** `/Users/jon/projects/scrypath/examples/scrypath_ecommerce/scripts/verify-dependency-boundaries.sh:278-317`

**Issue:** `write_target_asset_set` stores its newly created container only in a local variable. A failing `docker cp`, nonempty-asset check, or hash operation exits before line 408 removes it. The EXIT handler knows only `builder_container` and Compose projects; these temporary target containers have neither registration nor a run label. Consequently they remain behind while the handler prints cleanup success and records `cleanup_status: 0`. The overall failed proof remains failed, but its cleanup evidence is incorrect and the supposedly disposable verifier leaves an owned Docker resource behind.

**Evidence:** A service-free Docker double exercised the actual script, returning exit 42 on the first runtime-test asset copy. Its trace contains `create ...:runtime-test` and the failing copy, with no corresponding container removal. The script printed `case=cleanup status=passed`, and its failure receipt recorded `cleanup_status: 0`. Raw trace and receipt are retained under `/private/tmp/scrypath-review-cleanup.dk8gYK/`.

**Fix:** Register every temporary container ID with shared cleanup state immediately after creation, remove registered IDs on every exit path, and verify those removals before recording cleanup success. Run labels can provide a second ownership check. Add an injected copy-failure test that asserts the original failure status is preserved and the created target container is removed.

### WR-02: Startup accepts confirmation paths that crash the recovery navigation

**Classification:** WARNING
**File:** `/Users/jon/projects/scrypath/scrypath_ops/lib/scrypath_ops/security.ex:48-59`
**Related:** `/Users/jon/projects/scrypath/scrypath_ops/lib/scrypath_ops/integrations/sigra/gating.ex:123-129`

**Issue:** The new local-path validator accepts a path containing a backslash, such as `/sudo/\confirm`: it has a leading slash and parses without a host or scheme. Phoenix LiveView explicitly rejects backslashes in `push_navigate/2`. Thus startup says the Sigra configuration is valid, but the first stale or unconfirmed operator action raises instead of reaching confirmation. Phoenix's rejection prevents a redirect exploit here; the defect is failed validation and a broken recovery path.

**Evidence:** With the actual current Security/Gating source and actual Phoenix dependency, `Security.validate(%{auth_mode: "sigra", sigra: [sudo_confirm_path: "/sudo/\\confirm"]})` returned `:ok`. An otherwise valid OperatorContext with nil sudo then raised `unsafe characters detected for push_navigate/2` while constructing that confirmation navigation.

**Fix:** Reject the unsafe local-URL characters rejected by the installed navigation API, including backslashes and control-character forms, in the startup validator. Add a test that passes each accepted confirmation path through the actual unconfirmed-operator navigation and asserts rejected paths produce the clear startup error.

### WR-03: The standalone quickstart advertises a toolchain that cannot compile its default graph

**Classification:** WARNING
**File:** `/Users/jon/projects/scrypath/scrypath_ops/README.md:7`
**Related:** `/Users/jon/projects/scrypath/scrypath_ops/README.md:12-18`; `/Users/jon/projects/scrypath/scrypath_ops/mix.exs:51`

**Issue:** The revised prerequisites still advertise Elixir `~> 1.17` for the direct `cd scrypath_ops && mix setup` path. That direct project includes its optional Sigra dependency, and the source lock now selects Sigra 1.7.1, whose own manifest requires Elixir `~> 1.18`. Choosing basic or proxy-header auth does not remove Sigra from direct dependency resolution/compilation. A user following this quickstart on the advertised minimum therefore cannot compile the default graph. The canonical support guide explains Sigra's separate tier, but the prerequisite directly above the runnable instructions contradicts that tier.

**Evidence:** The current Ops lock selects Sigra 1.7.1; its installed package manifest declares `elixir: "~> 1.18"` at `scrypath_ops/deps/sigra/mix.exs:11`. The Ops manifest directly declares Sigra without an environment exclusion.

**Fix:** State that the default standalone/direct-development checkout requires the Sigra-compatible Elixir 1.18+ tier, and link to the canonical guide for exact supported tuples. Distinguish the root library and mounted-without-Sigra Elixir 1.17 tier without raising the root library's declared floor. Add a focused documentation contract for the default setup path's dependency floor.

## Verification and limits

- Read the supplied source scope and relevant called modules; compared actual phase changes with the supplied baseline, including the latest sudo recovery fix.
- Reproduced both blocking counterexamples and the confirmation-path failure using current source in fresh, service-free Elixir VMs. Dependency beams supplied the real library APIs; this did not start the application or exercise a live database.
- Reproduced the target-container cleanup error using the actual shell verifier and an injected Docker double. No real Docker stack or retained preview was operated.
- Ran the current static dependency-boundary contract successfully. Its pass does not cover the runtime counterexamples above.
- Did not rerun the full hosted/service suite, alter source files, modify other reports, commit, or claim terminal acceptance. The orchestrator owns fixes, re-review, and final exact-source evidence.

---

_Reviewer: gsd-code-reviewer_
_Depth: standard_
