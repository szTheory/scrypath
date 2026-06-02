---
phase: 112-public-website-and-docs-truth-alignment
verified: 2026-06-01T16:39:00Z
status: passed
score: 19/19 must-haves verified
overrides_applied: 0
---

# Phase 112: Public Website and Docs Truth Alignment Verification Report

**Phase Goal:** Keep public claims coherent across website, README, guides, and planning truth while preserving `website/` as a front door rather than a second docs site.
**Verified:** 2026-06-01T16:39:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Website and public docs consistently describe Scrypath as the Ecto-native search indexing library for Phoenix and Ecto teams. | ✓ VERIFIED | `README.md:5`, `website/src/pages/index.html:6`, `guides/overview.md:3`, `guides/sync-modes-and-visibility.md:3` contain the canonical descriptor. |
| 2 | Public copy does not imply hosted search, AI, magic callbacks, public multi-backend v1 support, or immediate search visibility after accepted async work. | ✓ VERIFIED | `mix verify.phase112` passes with explicit misleading-claim refutations in `test/scrypath/phase112_contract_test.exs`; evaluate/operators pages retain explicit negations and visibility honesty. |
| 3 | Website pages route users to canonical README, guides, examples, Hex, and GitHub surfaces instead of duplicating guide bodies. | ✓ VERIFIED | Route links present in `website/src/pages/docs.html:16,20,118,126` and `website/src/layout.html:47,60,61`; no procedural runbook commands detected on website pages by contract test. |
| 4 | Feature-lane reopen policy remains explicit: concrete production bug, reviewed outside-adopter evidence, or deliberate strategic product decision. | ✓ VERIFIED | Trigger trio present in `README.md:30`, `guides/scope-and-reopen-policy.md:13-15`, `docs/operator-support.md:31`, `docs/jtbd-gap-map.md:79,191`, `website/src/pages/evaluate.html:105`. |
| 5 | Public docs have one canonical scope and feature-lane reopen authority naming exact triggers and out-of-scope classes. | ✓ VERIFIED | `guides/scope-and-reopen-policy.md` exists and includes canonical trigger list and scoped non-goals; all route surfaces point to it. |
| 6 | README/support/intake route scope pressure to canonical authority instead of scattering policy text. | ✓ VERIFIED | Scope-policy routing at `README.md:30`, `guides/support-and-compatibility.md:112`, `guides/outside-adopter-intake.md:17`. |
| 7 | New guide is published through ExDoc extras and guide groups. | ✓ VERIFIED | `mix.exs:173,204` includes `guides/scope-and-reopen-policy.md`; `mix docs --warnings-as-errors` passes. |
| 8 | Guide-map and maintainer docs use same claim envelope and scope-reopen vocabulary. | ✓ VERIFIED | `guides/overview.md`, `guides/sync-modes-and-visibility.md`, `docs/operator-support.md`, `docs/jtbd-gap-map.md` include aligned wording and routing. |
| 9 | Sync semantics remain explicit about accepted work versus visibility while routing feature pressure to policy owner. | ✓ VERIFIED | `guides/sync-modes-and-visibility.md:15,126`; `website/src/pages/operators.html` keeps explicit accepted-vs-visible language. |
| 10 | Maintainer JTBD and operator-support docs preserve done posture and exact three-trigger rule. | ✓ VERIFIED | `docs/jtbd-gap-map.md:79,191`; `docs/operator-support.md:31`. |
| 11 | Website remains a front door with short summaries/links, not a second docs site. | ✓ VERIFIED | Website contract test asserts no runbook-depth tokens across `website/src/layout.html` + page files; tests pass. |
| 12 | Website copy routes through README/guides/examples/Hex/GitHub via existing page/layout links. | ✓ VERIFIED | Verified links in docs/layout pages and route-map structure. |
| 13 | Evaluate/operators pages state fit/visibility/reopen truth without hosted/AI/hidden-sync/immediate-visibility implications. | ✓ VERIFIED | `website/src/pages/evaluate.html` and `website/src/pages/operators.html` include explicit non-fit and visibility-honesty language; misleading claim patterns tested absent. |
| 14 | Existing website route/decision surfaces remain in approved shape and point to support authorities. | ✓ VERIFIED | `docs.html`, `evaluate.html`, `operators.html` remain route surfaces to canonical docs/guides. |
| 15 | Website pages do not become long standalone tutorials. | ✓ VERIFIED | Static pages are summary-style; contract test rejects deep runbook command tokens. |
| 16 | Maintainers can run one service-free command proving Phase 112 claim envelope and routing boundaries. | ✓ VERIFIED | `lib/mix/tasks/verify.phase112.ex` exists; `mix verify.phase112` passes (8 tests, 0 failures). |
| 17 | Focused file-read tests guard truth drift without noisy repo-wide scanning. | ✓ VERIFIED | `test/scrypath/phase112_contract_test.exs` scopes checks to targeted public surfaces and token families. |
| 18 | `verify.phase112` is registered for test env and documented without widening CI lanes. | ✓ VERIFIED | `mix.exs:69` has `"verify.phase112": :test`; `CONTRIBUTING.md:73` documents usage; no CI wiring changes required. |
| 19 | Contract proof asserts positive route/claim tokens and refutes misleading claim families on target surfaces. | ✓ VERIFIED | Assertions present in `phase112_contract_test.exs` (`assert_contains_all`, `assert_absent_patterns`, `refute_positive_claim`), and suite passes. |

**Score:** 19/19 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `guides/scope-and-reopen-policy.md` | Canonical scope/reopen authority | ✓ VERIFIED | Exists, substantive, routed by README/guides/website/docs. |
| `mix.exs` | ExDoc + preferred env wiring | ✓ VERIFIED | ExDoc extras/group entries plus `"verify.phase112": :test`. |
| `README.md` | Public route + claim envelope | ✓ VERIFIED | Canonical claim and scope/reopen route present. |
| `guides/support-and-compatibility.md` | Support boundary route to policy | ✓ VERIFIED | Explicit pointer to scope policy. |
| `guides/outside-adopter-intake.md` | Evidence lane route to policy | ✓ VERIFIED | Explicit reopen routing and class structure retained. |
| `guides/overview.md` | Guide-map route entry | ✓ VERIFIED | Includes scope/reopen policy row and canonical descriptor. |
| `guides/sync-modes-and-visibility.md` | Visibility honesty + scope route | ✓ VERIFIED | Preserves accepted-vs-visible statement and policy routing. |
| `docs/operator-support.md` | Maintainer boundary + trigger rule | ✓ VERIFIED | Includes scope policy link + exact trigger trio. |
| `docs/jtbd-gap-map.md` | Done posture + trigger rule | ✓ VERIFIED | Maintains maintenance/evidence framing and trigger trio. |
| `website/src/pages/index.html` | Front-door homepage claim | ✓ VERIFIED | Canonical claim envelope language present. |
| `website/src/pages/docs.html` | Route-map docs hub | ✓ VERIFIED | Routes to README/scope policy/guides/examples. |
| `website/src/pages/evaluate.html` | Fit/non-fit + scope route | ✓ VERIFIED | Includes explicit non-fit claims and scope policy link. |
| `website/src/pages/operators.html` | Ops route + visibility honesty | ✓ VERIFIED | Keeps accepted-vs-visible framing and scope-policy route. |
| `lib/mix/tasks/verify.phase112.ex` | Standalone verify task | ✓ VERIFIED | Focused test file list + no-arg guard + marker output. |
| `test/scrypath/phase112_contract_test.exs` | Phase 112 claim/routing tests | ✓ VERIFIED | Focused assertions on targeted public surfaces. |
| `test/mix/tasks/verify.phase112_test.exs` | Task contract tests | ✓ VERIFIED | Arg guard/help/source/preferred-env assertions. |
| `CONTRIBUTING.md` | Maintainer discoverability | ✓ VERIFIED | Scope table entry for `mix verify.phase112`. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `mix.exs` | `guides/scope-and-reopen-policy.md` | ExDoc extras/groups | ✓ WIRED | `verify.key-links` passed for 112-01. |
| `README.md` | `guides/scope-and-reopen-policy.md` | route-first pointer | ✓ WIRED | `README.md:30`. |
| `guides/support-and-compatibility.md` | `guides/scope-and-reopen-policy.md` | support boundary route | ✓ WIRED | `guides/support-and-compatibility.md:112`. |
| `guides/outside-adopter-intake.md` | `guides/scope-and-reopen-policy.md` | evidence lane route | ✓ WIRED | `guides/outside-adopter-intake.md:17`. |
| `guides/overview.md` | `guides/scope-and-reopen-policy.md` | guide map entry | ✓ WIRED | `guides/overview.md:27`. |
| `guides/sync-modes-and-visibility.md` | `guides/scope-and-reopen-policy.md` | boundary routing | ✓ WIRED | `guides/sync-modes-and-visibility.md:126`. |
| `docs/operator-support.md` | `../guides/scope-and-reopen-policy.md` | maintainer boundary guidance | ✓ WIRED | `docs/operator-support.md:31`. |
| `docs/jtbd-gap-map.md` | `guides/scope-and-reopen-policy.md` | done-posture routing | ✓ WIRED | `docs/jtbd-gap-map.md:79,191`. |
| `website/src/pages/docs.html` | `{{REPO_URL}}/blob/main/README.md` | canonical README route | ✓ WIRED | `website/src/pages/docs.html:16`. |
| `website/src/pages/docs.html` | `{{REPO_URL}}/blob/main/guides/scope-and-reopen-policy.md` | scope policy route | ✓ WIRED | `website/src/pages/docs.html:20`. |
| `website/src/pages/evaluate.html` | `{{REPO_URL}}/blob/main/guides/scope-and-reopen-policy.md` | fit/non-fit route to policy | ✓ WIRED | Link at `website/src/pages/evaluate.html:114`; trigger phrase split across line wrap at `:105-106` (manual verification resolved tool false-negative). |
| `website/src/layout.html` | `https://hex.pm/packages/scrypath` | global package route | ✓ WIRED | `website/src/layout.html:47,60`. |
| `lib/mix/tasks/verify.phase112.ex` | `test/scrypath/phase112_contract_test.exs` | focused test wiring | ✓ WIRED | `@focused_tests` includes file. |
| `lib/mix/tasks/verify.phase112.ex` | `test/mix/tasks/verify.phase112_test.exs` | focused test wiring | ✓ WIRED | `@focused_tests` includes file. |
| `mix.exs` | `lib/mix/tasks/verify.phase112.ex` | preferred env registration | ✓ WIRED | `mix.exs:69`. |
| `CONTRIBUTING.md` | `lib/mix/tasks/verify.phase112.ex` | maintainer run guidance | ✓ WIRED | `CONTRIBUTING.md:73`. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `website/src/pages/*.html`, guides/docs markdown | Static copy/link literals | File content loaded by tests (`File.read!`) | N/A (static content verification phase) | ✓ VERIFIED |
| `test/scrypath/phase112_contract_test.exs` | `@readme`, `@website_*`, `@*_guide` | Direct file reads from repo surfaces | Yes (actual current file bytes read at test runtime) | ✓ FLOWING |
| `lib/mix/tasks/verify.phase112.ex` | `@focused_tests` | Passed into `Mix.Task.run("test", args)` | Yes (executes named tests) | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Focused Phase 112 verification command executes and passes | `mix verify.phase112` | `8 tests, 0 failures` | ✓ PASS |
| Docs publication integrity after new guide wiring | `mix docs --warnings-as-errors` | Docs generated without warnings-as-errors failures | ✓ PASS |
| Website build/check integrity for route-map pages | `npm --prefix website run build && npm --prefix website run check` | Build + check succeeded | ✓ PASS |

### Probe Execution

Step 7c: SKIPPED (no phase-declared `probe-*.sh` artifacts and no conventional `scripts/*/tests/probe-*.sh` files found).

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| WEB-01 | 112-01/02/03/04 | Public website/docs present Ecto-native positioning without misleading claims | ✓ SATISFIED | Canonical descriptor + negative-claim contract tests across README/website/guides/docs. |
| WEB-02 | 112-02/03/04 | Website remains route map to README/guides/examples/Hex/GitHub | ✓ SATISFIED | Route-map links in website pages/layout; no runbook-depth copy on website surfaces. |
| SCOPE-01 | 112-01/02/03/04 | Feature-lane reopen policy explicit and evidence-gated | ✓ SATISFIED | Exact trigger trio across policy/README/docs/website; canonical routing to scope policy. |

No orphaned Phase 112 requirements found in `.planning/REQUIREMENTS.md`.

### Anti-Patterns Found

No blocker or warning anti-patterns found in Phase 112 modified surfaces.  
Debt-marker gate (`TBD`/`FIXME`/`XXX`) passed: none found in scoped files.

### Human Verification Required

None.

### Gaps Summary

No must-have gaps found. Phase goal is achieved in the codebase and verification commands.

---

_Verified: 2026-06-01T16:39:00Z_  
_Verifier: the agent (gsd-verifier)_
