---
phase: "183"
slug: "maintainer-tooling-outside-the-hex-package"
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: "2026-10-28"
---

# Phase 183 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.
> ASVS 5.0 Level 1, block_on: high. Register authored at plan time (all 8 PLAN files carry a `<threat_model>`), so L1 grep-depth verification applies (short-circuit, no auditor spawn).

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Hex package / path / git dep -> adopter app | Any compiled `Mix.Tasks` module in the dependency becomes invocable in the adopter's `mix help` | Executable task modules (git, Docker, `mix hex.*`, `System.cmd`) |
| Contributor shell -> Mix env selection | `preferred_envs` decides whether `dev/mix/tasks` compiles | Mix env |
| Source tree -> CI BEAM cache | A restored `_build` must match the exact sources compiled | Compiled beams |
| Working tree -> publish workflow | `verify.workspace_clean` must reject uncommitted state before `hex.publish` | Package source |
| Test harness -> developer environment | `hex.build` / consumer subprocesses must not read credentials or touch the real checkout | Hex/Mix state, tokens |
| Packaged docs -> adopters | Docs must not imply maintainer tooling ships in the package | Documentation |
| Agent -> maintainer decision / release authority | Locked-decision changes, merges and releases need a real maintainer answer | Decisions, releases |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-183-01 | Spoofing | Old `scrypath.namespace_fence` name in adopters' `mix help` | medium | mitigate | Renamed to `verify.namespace_fence` in `dev/mix/tasks/verify.namespace_fence.ex`; `git grep` for `scrypath.namespace_fence` outside `.planning/` returns nothing | closed |
| T-183-02 | Tampering | Source-text contract tests reading a stale path | low | mitigate | `test/support/repo_tooling.ex:14` `task_source!/1` uses `File.read!/1` (raises on missing file) | closed |
| T-183-03 | Repudiation | Formatter / credo / workspace-gate coverage of moved verifiers | medium | mitigate | `.formatter.exs:4` includes `dev`; `.credo.exs:6` includes `dev/`; `test/mix/tasks/verify_workspace_clean_test.exs:28` `assert "dev" in pathspecs` | closed |
| T-183-04 | Tampering | BEAM cache restoring stale verifier beams | medium | mitigate | `scripts/ci/beam_cache.cjs:18,24,30` add `dev` to every graph's `sourceRoots` | closed |
| T-183-05 | Elevation of privilege | Maintainer automation compiled into adopter apps | high | mitigate | `mix.exs:112-113` env-keyed `elixirc_paths` (`dev/mix/tasks` only in `:test`); `lib/mix/tasks/` holds only the 8 public tasks; boundary guard in `test/release/package_contents_test.exs` + `test/support/release/package_contract.ex` (`@public_tasks`) | closed |
| T-183-06 | Denial of service | Contributor commands lost after move (missing preferred env) | medium | mitigate | `test/mix/tasks/verify_capability_test.exs:65-73` asserts every maintainer task routes to `:test` via `preferred_envs` | closed |
| T-183-07 | Tampering | Gate bypass via non-verify name, hidden module, or `dev/` in `files:` | high | mitigate | Allowlist + AST scan + top-level check in `test/support/release/package_contract.ex`; exact-line mutations (`scrypath.repo_only`, hidden module, dev-in-files) in `test/release/package_contents_test.exs:30-75,265-272` | closed |
| T-183-08 | Information disclosure | `hex.build` subprocesses reading credentials / network | medium | mitigate | `test/release/package_contents_test.exs:399-400,429` set `HEX_OFFLINE=1` and isolated `MIX_BUILD_PATH` under tmp | closed |
| T-183-09 | Tampering | Vacuous mutation tests | medium | mitigate | `refute mutated == original` + exact-line assertions in `test/release/package_contents_test.exs` (per 183-05-SUMMARY) | closed |
| T-183-10 | Tampering | Dynamically generated task modules evading AST scan | medium | mitigate | `test/release/consumer_smoke_test.exs:99-113` asserts against consumer ebin `Elixir.Mix.Tasks.*.beam` and the `scrypath.app` module list | closed |
| T-183-11 | Information disclosure | Consumer subprocesses using developer Hex/Mix state | low | mitigate | Existing isolated `HEX_HOME`/`MIX_HOME`/`MIX_ENV` env reused in `test/release/consumer_smoke_test.exs` (per 183-06-SUMMARY) | closed |
| T-183-12 | Repudiation | Silent override of locked decision D-07 | high | mitigate | `183-CONTEXT.md:50` "Amended 2026-10-28 (maintainer-approved)" with original text kept; `183-RESEARCH.md:645-647` Open Question 1 RESOLVED; `mix.exs` has no `filter_modules` | closed |
| T-183-13 | Spoofing | Docs implying verify tasks ship to adopters | low | mitigate | Source-checkout qualifiers added (183-07); packaged-docs guard refutes `Mix.Tasks.Verify` references in extras and `lib/` | closed |
| T-183-14 | Repudiation | Completion claimed without exact-source evidence | high | mitigate | `183-ACCEPTANCE.md` and 183-08-SUMMARY bind local gates and hosted closeout to exact SHAs; failed attempts preserved | closed |
| T-183-15 | Tampering | Unauthorized release / publish / merge / CHANGELOG edit | high | mitigate | `git diff 2a0f1428..HEAD -- CHANGELOG.md mix.lock` empty; no tag contains the phase base; PR #123 `state: OPEN`, `mergedAt: null`, `autoMergeRequest: null` | closed |
| T-183-SC | Tampering | npm/pip/cargo/hex installs | high | mitigate | `mix.lock` unchanged since phase base (`2a0f1428`); no dependency changes in `mix.exs` deps | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

No accepted risks.

Note (not a threat, recorded for context): per the D-07 amendment, local `:test` docs still list the Verify module pages while HexDocs (built in `:dev`) does not. This is a maintainer-approved consistency trade-off, not a security risk.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-28 | 16 | 16 | 0 | gsd-secure-phase (L1 grep-depth, orchestrator; auditor not spawned per short-circuit rule) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-10-28
