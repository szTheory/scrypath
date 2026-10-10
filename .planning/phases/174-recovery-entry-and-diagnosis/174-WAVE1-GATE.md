---
phase: 174
wave: 1
status: passed
---

# Wave 1 integration gate

Plan174-01 has a committed complete summary, matching RED/GREEN task commits, existing created artifacts, and self-check PASSED. The evaluation-scope probe resolves its eight recorded task/metadata commits. Parent verified the regular clone root and preserved the other source/preview roots.

`mix compile --warnings-as-errors` exited0. `mix precommit` then passed251 tests and2 doctests with0 failures (18.5s measured test runtime) using owned test partition174_wave1. Native output and execution receipt are retained at `/private/tmp/scrypath-phase173-20261006-155750/174-wave1-precommit-green.log` and `174-wave1-gate-green.json`. This run includes uncommitted test-only fixes subsequently committed; it is local executable evidence, not hosted exact-SHA attestation. The unchanged core dependency typing warning at sync.ex:61 remains deferred; no warning-free dependency claim.

The first full-suite run exposed the stale duplicate incident-card assertion. The test now uses a configured explicit canonical schema and checks the single connected health entry plus the two quieter intent cards. A later rerun exposed parallel definitions of identical optional Oban.Job stubs in two test files. The stub is now defined once in test/support/oban_job_fixture.ex (test-only elixirc path; respects a real installed Oban module), so the affected suites can be compiled together. Earlier failing native logs remain retained beside the green log. No production code or dependencies changed during this parent integration fix.

Active execute:wave:post gates: schema drift check block=false; UI safety check has approved UI-SPEC and block=false; codebase drift skipped because no STRUCTURE.md. These metadata gates are not production browser or feature proof. execute:wave:pre has no active hooks. Next DAG-ready plan174-02 depends on the complete174-01; later plans await their predecessors. Phase requirements remain open, browser proof belongs174-08, and no175 transition or maintainer visual approval is claimed.
