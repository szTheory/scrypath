# Phase 109: Release Train and Package Truth Audit - Research

**Researched:** 2026-05-31
**Domain:** Elixir OSS release automation and Hex package truth
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Release Agreement
- **D-01:** Keep Release Please manifest mode as the canonical release contract. Do not replace it with a tag-first bespoke release system, Changesets, or manual maintainer-cut releases.
- **D-02:** Harden the existing contract rather than re-architect it: `mix.exs` `@version`, `.release-please-manifest.json`, `release-please-config.json`, `CHANGELOG.md`, Release Please tag checkout, and publish workflow guards should be mechanically checked for agreement.
- **D-03:** Prefer semantic checks where practical over brittle grep-only checks. Existing grep assertions in `verify.phase11` are acceptable as anchors, but planner should look for low-risk ways to parse JSON/YAML or otherwise make drift failures more diagnostic.
- **D-04:** Preserve the current squash-merge/PR-title release train semantics from `docs/releasing.md` and `CONTRIBUTING.md`; do not impose contributor-heavy commit ritual beyond the existing Release Please flow.

### Hex Package Shape
- **D-05:** Treat root `mix.exs` `package.files` as the source of package intent, but treat the unpacked Hex artifact as the proof surface. REL-02 is satisfied by what actually ships, not merely by what the whitelist says.
- **D-06:** Use a hybrid package proof: artifact-first allowlist assertions for expected shipped path families plus explicit deny assertions for high-risk directories and generated artifacts.
- **D-07:** High-risk exclusions must include at least `scrypath_ops/`, `examples/`, `website/` build output, `.planning/`, `node_modules`, Playwright reports/results/artifacts, and other non-root-library outputs discovered during implementation.
- **D-08:** Avoid a large checked-in package snapshot unless implementation evidence proves it is needed. Snapshot workflows can become rote churn; a focused normalized artifact assertion is the better fit for this repo's maintenance lane.

### Publish Proof Chain
- **D-09:** Keep `mix verify.phase11` as the lean always-on required release-truth gate. It should remain auth-free and suitable for PR/main CI.
- **D-10:** Keep live registry/docs checks out of routine PR gates. Hex visibility, HexDocs reachability, and published-package consumer compile belong in post-publish workflows because they depend on external state and credentials.
- **D-11:** The canonical publish path should remain layered: Release Please creates the release/tag, the publish job checks out the tag, verifies workspace cleanliness, verifies version agreement, runs `mix verify.phase11`, performs `mix hex.publish --dry-run --yes`, publishes, runs `mix verify.release_publish X.Y.Z`, then runs `mix verify.release_parity X.Y.Z`.
- **D-12:** The manual `publish-hex.yml` recovery workflow should mirror the canonical proof chain from an explicit reviewed tag/ref and version. It is a break-glass replay path, not a second release system.
- **D-13:** Retain scheduled published-release verification as ongoing trust evidence, with retries and issue dedupe to avoid transient-noise churn.

### the agent's Discretion
- Planner may choose the exact implementation shape for parsing workflow/config files, package artifact normalization, and test organization as long as the resulting checks are deterministic, service-free for `verify.phase11`, and easy for maintainers to diagnose.
- Planner may consolidate checks into existing release tests/tasks or add a focused release-truth helper module if that improves clarity without creating new public API.

### Deferred Ideas (OUT OF SCOPE)
- Replacing Release Please with Changesets or a custom tag-first release system is deferred. It may be reconsidered only if Scrypath develops multi-artifact governance needs that outweigh the current Elixir-native Release Please flow.
- Adding a large checked-in package manifest snapshot is deferred unless focused artifact assertions prove insufficient.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REL-01 | Release Please, mix.exs, manifest, changelog, tags, workflows agree | Agreement-check architecture and workflow/task contract map |
| REL-02 | Hex package excludes non-library paths/artifacts | Artifact-first package shape assertions via `mix hex.build --unpack` |
| REL-03 | Publish path proves phase11, dry-run, visibility, HexDocs, clean-consumer compile, parity | Canonical publish proof chain and scheduled parity verification |
</phase_requirements>

## Summary

The repository already has the correct release-train backbone for REL-01/02/03: Release Please manifest mode, tagged publish checkout, `mix verify.phase11`, dry-run publish, live post-publish verification, and parity checks are implemented and documented. [VERIFIED: repo codebase grep] The planning focus should be tightening diagnostics and making package truth assertions more semantic, not adding new release systems. [VERIFIED: repo codebase grep]

Release Please documentation confirms manifest-mode is the right contract surface for version tracking through `release-please-config.json` + `.release-please-manifest.json`, and the action outputs (`release_created`, `tag_name`, `version`) are designed for conditional publish jobs. [CITED: https://raw.githubusercontent.com/googleapis/release-please/main/docs/manifest-releaser.md] [CITED: https://raw.githubusercontent.com/googleapis/release-please-action/main/README.md]

Hex documentation confirms the core proof primitives already used by Scrypath: `mix hex.build --unpack` for inspecting artifact contents and `mix hex.publish --dry-run --yes` for non-interactive publish preflight. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Build.html] [CITED: https://hex.pm/docs/publish]

**Primary recommendation:** Implement a deterministic "release agreement + artifact truth" verifier extension inside existing `verify.phase11` and release tests, keeping live checks only in publish/post-publish workflows. [VERIFIED: repo codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Version/manifest/changelog agreement | API / Backend | — | Implemented as Mix task logic and repo-file validation in CI tasks. [VERIFIED: repo codebase grep] |
| Release PR/tag orchestration | Frontend Server (SSR) | API / Backend | Owned by GitHub Actions workflow execution with Release Please outputs. [VERIFIED: repo codebase grep] |
| Hex package shape proof | API / Backend | — | Performed by Mix/Hex build + unpack and local path assertions. [VERIFIED: repo codebase grep] |
| Post-publish registry/docs visibility | Frontend Server (SSR) | API / Backend | Performed in CI jobs calling live Hex/HexDocs endpoints. [VERIFIED: repo codebase grep] |
| Release parity drift monitoring | Frontend Server (SSR) | API / Backend | Scheduled workflow runs parity task and opens deduped issues. [VERIFIED: repo codebase grep] |

## Project Constraints (from AGENTS.md)

- Keep Scrypath as an Elixir OSS library with Ecto-first APIs and Phoenix-friendly integrations. [VERIFIED: AGENTS.md]
- Keep Meilisearch-first v1 posture and avoid public multi-backend abstraction promises. [VERIFIED: AGENTS.md]
- Preserve inline/Oban/manual sync support framing; do not hide operational realities. [VERIFIED: AGENTS.md]
- Keep release quality high and avoid rush-to-ship scope expansion. [VERIFIED: AGENTS.md]
- Follow CONTRIBUTING release/verification gates and green-main release-train posture. [VERIFIED: AGENTS.md]

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | 1.19.5 (local) | Mix verification tasks and release contract code | Repo workflows and tasks are Mix-native and already wired. [VERIFIED: repo codebase grep] |
| Release Please Action | v5.0.0 | Release PR/tag/version orchestration | Current workflow uses it with manifest mode and outputs chain. [VERIFIED: repo codebase grep] |
| Hex (Mix tasks) | Hex v2.2.1 docs | Build/publish/dry-run package proof | Official commands used directly in workflow/tasks. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Build.html] [CITED: https://hex.pm/docs/publish] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| erlef/setup-beam | v1 | Beam toolchain setup in Actions | Required for publish/verification jobs on GitHub runners. [VERIFIED: repo codebase grep] |
| JasonEtco/create-an-issue | v2 | Drift issue dedupe on scheduled monitor failures | Keep only in scheduled publish-parity monitor workflow. [VERIFIED: repo codebase grep] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Release Please manifest mode | Changesets/manual tagging | Violates locked decisions D-01/D-12 and increases maintainer variance. [VERIFIED: 109-CONTEXT.md] |

**Installation:**
```bash
# No new runtime packages required for Phase 109 implementation.
```

**Version verification:** Existing stack entries were verified from repository workflow pins and official docs, not from training-only memory. [VERIFIED: repo codebase grep] [CITED: https://raw.githubusercontent.com/googleapis/release-please-action/main/README.md] [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Build.html]

## Package Legitimacy Audit

No new third-party runtime/dev package installation is required by Phase 109 scope; package-legitimacy risk is N/A for implementation. [VERIFIED: 109-CONTEXT.md]

`slopcheck` availability was confirmed in the environment for future phases if new package installs are introduced. [VERIFIED: local command `command -v slopcheck`]

## Architecture Patterns

### System Architecture Diagram

```text
Developer PR Merge
  -> Release Please workflow (manifest mode)
    -> Release PR/version/changelog/tag outputs
      -> publish-hex job gated on release_created
        -> checkout tag_name
          -> workspace clean check
            -> phase11 deterministic gate
              -> dry-run publish
                -> real publish
                  -> live release_publish verification (Hex + consumer compile + HexDocs)
                    -> release_parity check (tag vs tarball)
                      -> scheduled verify-published-release monitor
                        -> deduped issue on drift/failure (schedule only)
```

### Recommended Project Structure
```text
lib/mix/tasks/
  verify.phase11.ex         # deterministic release agreement + package proof
  verify.release_publish.ex # live post-publish proof
  verify.release_parity.ex  # published tarball vs git tag parity
test/release/               # package metadata/consumer/doc contracts
test/mix/tasks/             # workflow wiring/parity task behavior tests
.github/workflows/          # release-please, publish recovery, scheduled monitor
docs/releasing.md           # canonical maintainer flow
```

### Pattern 1: Deterministic Agreement Gate
**What:** Parse and compare local version sources (`mix.exs`, manifest JSON, workflow references) in one service-free task. [VERIFIED: repo codebase grep]
**When to use:** Required PR/main gate (`mix verify.phase11`). [VERIFIED: CONTRIBUTING.md]
**Example:**
```elixir
# Source: https://hexdocs.pm/hex/Mix.Tasks.Hex.Build.html
run_command!(["hex.build", "--unpack"], "Building and unpacking Hex package")
```

### Pattern 2: Artifact-First Package Truth
**What:** Assert allowlist + denylist against unpacked package output, not only `package.files` declaration. [VERIFIED: 109-CONTEXT.md]
**When to use:** REL-02 proof and drift detection in phase11 tests. [VERIFIED: .planning/REQUIREMENTS.md]

### Anti-Patterns to Avoid
- **Second release system:** adding alternate manual/tag release authority beyond Release Please manifest mode. [VERIFIED: 109-CONTEXT.md]
- **Live-service checks in required gate:** pushing Hex/HexDocs network checks into `verify.phase11` increases flakiness and violates D-09/D-10. [VERIFIED: 109-CONTEXT.md]
- **Snapshot churn artifacts:** committing large package snapshots without clear need. [VERIFIED: 109-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Release PR/tag/version orchestration | Custom release bot/scripts | Release Please manifest mode | Officially supports manifest contracts and workflow outputs. [CITED: https://raw.githubusercontent.com/googleapis/release-please/main/docs/manifest-releaser.md] [CITED: https://raw.githubusercontent.com/googleapis/release-please-action/main/README.md] |
| Hex artifact inspection | Custom tar tooling | `mix hex.build --unpack` | Official Hex path, less bespoke maintenance. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Build.html] |
| Publish preflight | Hand-checked prompts | `mix hex.publish --dry-run --yes` | Canonical non-interactive publish validation. [CITED: https://hex.pm/docs/publish] |

**Key insight:** This phase succeeds by tightening existing release truth surfaces, not by introducing new infrastructure. [VERIFIED: 109-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Grep-only workflow checks become brittle
**What goes wrong:** Small formatting edits break validation without semantic drift. [VERIFIED: repo codebase grep]
**Why it happens:** Current `verify.phase11` has many literal grep assertions. [VERIFIED: lib/mix/tasks/verify.phase11.ex]
**How to avoid:** Keep key grep anchors but add low-risk JSON/YAML parsing for agreement checks where practical.
**Warning signs:** Frequent false positives after workflow formatting-only changes.

### Pitfall 2: Declared package files diverge from shipped artifact
**What goes wrong:** `package.files` looks correct but tarball still carries unwanted paths/artifacts.
**Why it happens:** Maintainers trust declaration instead of unpacked proof surface.
**How to avoid:** Assert denies (`scrypath_ops/`, `.planning/`, Playwright artifacts, etc.) against unpacked output each run.
**Warning signs:** Unexpected directories under unpacked artifact.

### Pitfall 3: Recovery path drifts from canonical publish path
**What goes wrong:** Manual workflow stops mirroring canonical checks, creating inconsistent release truth.
**Why it happens:** Workflows evolve independently.
**How to avoid:** Add wiring tests asserting same ordered proof chain between `release-please.yml` and `publish-hex.yml`.
**Warning signs:** One workflow misses `verify.phase11`, dry-run, publish verification, or parity step.

## Code Examples

### Release Please conditional publish
```yaml
# Source: https://raw.githubusercontent.com/googleapis/release-please-action/main/README.md
if: ${{ needs.release-please.outputs.release_created == 'true' }}
```

### Hex dry-run publish
```bash
# Source: https://hex.pm/docs/publish
mix hex.publish --dry-run --yes
```

### Unpacked package inspection
```bash
# Source: https://hexdocs.pm/hex/Mix.Tasks.Hex.Build.html
mix hex.build --unpack
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual/semi-manual release parity checks | Mechanized phase11 + post-publish + scheduled verification | Already implemented before Phase 109 planning | Enables "boring" auditable release train with deterministic + live layers. [VERIFIED: repo codebase grep] |

**Deprecated/outdated:**
- Ad-hoc publish verification outside workflows as primary release truth source. Prefer mechanized workflow/task chain. [VERIFIED: docs/releasing.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | None | — | — |

All substantive claims were verified from repo files or cited official docs in this session.

## Open Questions (RESOLVED)

1. **How far should semantic parsing go in `verify.phase11` for YAML checks?**
   - What we know: D-03 prefers semantic checks but allows existing grep anchors.
   - What's unclear: Whether maintainers want new parser dependency vs simple shell/Elixir parsing.
   - RESOLVED: Keep parser-free Elixir-native checks first for Phase 109. Use JSON decoding where the repo already has JSON inputs and targeted source/workflow assertions for YAML, without adding a new YAML parser dependency. Escalate to parser-backed YAML checks only if this phase exposes repeated false positives or drift that line-level assertions cannot represent.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `mix` | All verification tasks | ✓ | Mix 1.19.5 | — |
| `elixir` | Mix task execution | ✓ | 1.19.5 / OTP 28 | — |
| `git` | tag/workspace/parity checks | ✓ | 2.41.0 | — |
| `jq` | workflow JSON parsing and monitor scripts | ✓ | 1.7.1 | Elixir/Jason parsing where feasible |
| `curl` | Hex/HexDocs reachability checks | ✓ | 8.7.1 | Req/HTTP client in Mix task (not needed now) |
| `gh` | maintainer release diagnostics | ✓ | 2.93.0 | GitHub web UI |
| `docker` | local reproducible release gate path (`verify_phase11_docker.sh`) | ✓ | 29.5.2 | native host run |

**Missing dependencies with no fallback:**
- None.

**Missing dependencies with fallback:**
- None.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir standard) |
| Config file | `mix.exs` (`test` alias + preferred envs) |
| Quick run command | `mix test test/mix/tasks/workflow_wiring_test.exs -x` |
| Full suite command | `mix verify.phase11` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REL-01 | Release contract agreement stays wired | unit/integration (workflow wiring + task) | `mix test test/mix/tasks/workflow_wiring_test.exs -x` | ✅ |
| REL-02 | Artifact excludes non-library outputs | unit/integration (release package tests + unpack assertions) | `mix test test/release/package_metadata_test.exs test/release/consumer_smoke_test.exs -x` | ✅ |
| REL-03 | Publish proof chain includes dry-run/live/parity | unit/integration | `mix test test/mix/tasks/workflow_wiring_test.exs test/mix/tasks/verify_release_parity_test.exs -x` | ✅ |

### Sampling Rate
- **Per task commit:** `mix test test/mix/tasks/workflow_wiring_test.exs -x`
- **Per wave merge:** `mix verify.phase11`
- **Phase gate:** Full `mix verify.phase11` green before `$gsd-verify-work`

### Wave 0 Gaps
- None — existing release verification infrastructure and tests already cover the needed surfaces; Phase 109 should extend them.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | GitHub Actions secret scoping for `HEX_API_KEY` publish path only |
| V3 Session Management | no | N/A (no app session surface in this phase) |
| V4 Access Control | yes | Required-gate split vs advisory/live gates in CI workflow policy |
| V5 Input Validation | yes | Strict semver argument validation in `verify.release_parity` |
| V6 Cryptography | no | No custom cryptography in phase scope |

### Known Threat Patterns for Elixir release automation

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Tag/version mismatch causing wrong artifact publish | Tampering | `mix verify.workspace_clean` + version checks + tag checkout + parity monitor |
| Workflow drift removing critical release checks | Tampering | `workflow_wiring_test` assertions + required CI gates |
| Dependency/action supply-chain drift | Tampering | pinned action versions + release-truth gate + advisory deep-quality job posture |
| Untrusted version input to subprocess | Elevation of privilege | regex-gated semver parsing in `verify.release_parity` |

## Sources

### Primary (HIGH confidence)
- Repository sources: `mix.exs`, `docs/releasing.md`, `CONTRIBUTING.md`, `.github/workflows/release-please.yml`, `.github/workflows/publish-hex.yml`, `.github/workflows/verify-published-release.yml`, `lib/mix/tasks/verify.phase11.ex`, `lib/mix/tasks/verify.release_publish.ex`, `lib/mix/tasks/verify.release_parity.ex`, `test/mix/tasks/workflow_wiring_test.exs`.
- Release Please manifest docs: https://raw.githubusercontent.com/googleapis/release-please/main/docs/manifest-releaser.md
- Release Please Action docs: https://raw.githubusercontent.com/googleapis/release-please-action/main/README.md
- Hex build docs: https://hexdocs.pm/hex/Mix.Tasks.Hex.Build.html
- Hex publish docs: https://hex.pm/docs/publish

### Secondary (MEDIUM confidence)
- None needed.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - directly verified from current repo pins and official docs.
- Architecture: HIGH - existing workflows/tasks already implement the target shape.
- Pitfalls: HIGH - drawn from concrete current implementation and locked context.

**Research date:** 2026-05-31
**Valid until:** 2026-06-30
