---
phase: 172-consistent-operator-ui-and-verified-recovery
plan: "06"
subsystem: verification
status: complete
requirements-completed: []
requirements-addressed: [OPUX-04, OPUX-05, OPUX-06, OPUX-07]
requires: [172-02, 172-05]
provides:
  - Rendered non-first-schema recovery joined to exact job, task, and active document.
  - Exact returned swap identity and target-only document proof with negative controls.
key-files:
  created: [examples/scrypath_ecommerce/lib/scrypath_ecommerce/e2e_recovery.ex]
completed: 2026-10-03
plan_head_before: 01acc26
plan_head_after: 3fd8972cd5ecc28fb21a1285a8fffb9280e34053
---

# Phase 172 Plan 06 Summary

The mounted test follows Control Room → Posture → Failed Sync → Sync/Drift for Variant, requires the rendered Retry action, joins the accepted replacement job and worker attempt to its exact Meilisearch task and run-specific active-index document, then checks retained original history and schema context through back/reload/invalid selection. Promotion has a separate exact-task/index-pair/unique-target-content proof. Old tasks and unrelated documents receive explicit 422 rejection. No retry or aggregate-success fallback establishes acceptance.

## Implementation and deviations

- `2052e5a`: capture actual Oban metadata.conf, normalized worker name and node identity; expose exact observed job/attempt/task/index in the UI.
- `6fdb571`: correct core index-contract reads for wildcard searchable attributes, facet filterability and backend defaults. This existing core bug prevented legitimate promotion; public API unchanged.
- `e9b0171`: incomplete/malformed promotion prerequisites and unknown enums deny safely.
- `e9dec0f`: validate the receipt's current Oban repo/prefix, preserve queue inspector for document correlation and guarded promotion, consume normalized swap task uid, handle real document_not_found.
- `fa0ac0f`: deterministic replayable fixtures and exact probes; first-failure traces/screenshots/structured identity evidence; retries0; source SHA passed through existing Compose lane; fail-closed setup and idempotent index provisioning.
- `0827f3d`: cleanup checks its explicit target index before deleting.
- `3fd8972`: source-generation handoff separated from destination async generation; context-bearing async keys guard exits; one-use confirmation and in-flight guard prevent duplicate swaps; result disclosure stays open; standalone schema radios have real LiveView forms. The browser changes Product→Variant before retry. Independent review identified these edge cases, and rendered form tests now prevent event-wiring regressions.
- Plan06 uncovered production integration defects missed by earlier focused tests; fixes remain within the approved truthful-recovery/promotion outcome. Fixture provisioning no longer creates ignored index-already-exists tasks or ignores cleanup failures. Production task history is retained.

## Verification

- Core drift/reconcile/settings focused RED17/7 failures → GREEN68/0; compile warnings enforced (worker reported, recorded during integration).
- Recovery telemetry identity RED11/1 → GREEN11/0; real document-not-found RED13/3 → GREEN35/0 combined seams.
- Malformed promotion reports RED16/6 and struct edge RED17/1 → GREEN28/0 with SyncDriftLive.
- Exact accepted swap UID and guarded queue-inspector regressions RED13/2 → GREEN13/0.
- Final Ops `MIX_ENV=test mix precommit`: 232 tests + 2 doctests, zero failures; log `/private/tmp/phase172-06-ops-final2.log`.
- Review regressions RED16/3 → GREEN27/0; rendered form regressions RED29/2 → GREEN29/0.
- Canonical `KEEP_E2E_STACK=1 make -C examples/scrypath_ecommerce verify-mounted`: exit0, **4 tests passed in7.1s, zero retries/skips** on fresh project `scrypath_ecommerce_verify_focused_3fd8972c_77955`, source `3fd8972cd5ecc28fb21a1285a8fffb9280e34053`. Log `/private/tmp/phase172-06-run10.log`; structured report `examples/scrypath_ecommerce/test-results/docker-focused/test-results/phase105-playwright.json` (ignored artifacts).
  - Recovery: original job29 → accepted job30 attempt1 → task17 succeeded for ecommerce__variant → document27 with exact unique marker; original failure retained. Scenario3.052s.
  - Promotion: baseline task26 → returned task31 succeeded/indexSwap for ecommerce__product and ecommerce__product__reindex → unique document28 visible in active index. Scenario3.077s.
  - Both old-task and wrong-document probes reject with422; actual visible completion required.
- Wave5 metadata gates: schema drift passed (no schema files); codebase drift skipped (no STRUCTURE.md); UI safety passed. These metadata gates do not establish runtime behavior.

Local tests used Elixir1.19.5/OTP28.5, task-local HEX_HOME and ERL_FLAGS='+S 1:1'. The pre-existing optional-dependency typing warning in Scrypath.Sync remains in Ops dependency compilation. `mix verify.backend --skip-integration` currently skips the sole delegated smoke task and runs no tests; it is not counted as backend proof. Hosted live backend verification remains Plan08.

## Evidence and limits

Exploratory warm runs and their first failures remain under `/private/tmp/phase172-06-*`; they are diagnosis, not final acceptance. Warm3 proved recovery in 2.96s and correctly blocked promotion on retained older failed backend work. That work was not erased to force a pass. Test setup was repaired and canonical verification used a new isolated project.

Feedback preview4012 was never seeded or reset. Superseded debug stacks were removed after artifact capture. The passing task-owned stack is deliberately retained for Plan07 focused browser work and must be removed at delivery; its Compose project is recorded above. Disposable stack ownership and cleanup are separate from preview retention. This completes the mounted identity proof only; Plan07 covers visual/keyboard/theme boundaries and Plan08 reviews and closes delivery. OPUX requirements remain open until whole-phase evidence is joined.
