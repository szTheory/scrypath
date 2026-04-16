# Phase 11: Public Release Contract - Research

**Researched:** 2026-04-16
**Domain:** Elixir OSS library release engineering for Hex + GitHub Actions + Release Please [VERIFIED: docs/releasing.md + .github/workflows/release-please.yml + release-please-config.json]
**Confidence:** HIGH

## Summary

Scrypath already has a working Phase 10 release-confidence baseline: `mix verify.phase10` passes locally, the repo has Release Please manifest mode wired, package metadata tests pass, docs build cleanly, and Hex package assembly succeeds locally. [VERIFIED: `mix verify.phase10` run on 2026-04-16 + lib/mix/tasks/verify.phase10.ex + test/release/package_metadata_test.exs + test/scrypath/docs_contract_test.exs + .github/workflows/release-please.yml]

Phase 11 should therefore plan around closing the last public-release gaps rather than inventing a new release system. [VERIFIED: docs/releasing.md + .github/workflows/release-please.yml + release-please-config.json] The concrete gaps are repo-specific: there is no published `scrypath` package on Hex yet, there are no GitHub Releases yet, the local git tags do not include a package tag matching `0.1.0`, and package links still point at moving `main` or latest-doc URLs rather than version-anchored release URLs. [VERIFIED: `mix hex.info scrypath` -> "No package with name scrypath" + `gh release list --limit 20` -> empty + `git tag --sort=version:refname` + mix.exs]

The planning target should be one canonical contract: Release Please remains the version/changelog/tag authority, GitHub Actions publishes only from the tagged ref produced in that same workflow, `mix.exs` and docs metadata stay version-anchored, Hex artifact links become release-aware, and maintainers get one short recovery runbook for three failure classes: version/tag drift, failed publish, and post-publish artifact mismatch. [VERIFIED: .github/workflows/release-please.yml + mix.exs + docs/releasing.md][CITED: https://github.com/googleapis/release-please-action][CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html]

**Primary recommendation:** Keep the existing same-workflow Release Please -> checkout tag -> `mix hex.publish --yes` path, and spend Phase 11 on alignment checks, release-aware metadata, clean-consumer smoke automation, and maintainer recovery docs. [VERIFIED: .github/workflows/release-please.yml + docs/releasing.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Version and changelog authority | GitHub / Release Please | Repo files | Release Please is already configured in manifest mode and owns changelog/tag/version outputs. [VERIFIED: release-please-config.json + .release-please-manifest.json + .github/workflows/release-please.yml][CITED: https://github.com/googleapis/release-please-action] |
| Package metadata and source-link alignment | Repo / `mix.exs` | HexDocs | `mix.exs` defines `@version`, `@source_ref`, docs extras, and package links. [VERIFIED: mix.exs] |
| Artifact publication | GitHub Actions | Hex.pm | The publish job runs only when `release_created == 'true'`, checks out the produced tag, and runs `mix hex.publish --yes`. [VERIFIED: .github/workflows/release-please.yml][CITED: https://github.com/googleapis/release-please-action][CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] |
| Clean-consumer verification | External throwaway consumer app | HexDocs + optional Meilisearch | Consumer trust is proven outside the repo by installing the published dependency, reaching docs, and compiling documented usage. [VERIFIED: README.md + guides/getting-started.md + local throwaway consumer compile on 2026-04-16] |
| Failure recovery | Maintainer docs | GitHub + Hex CLI | The repo already has `docs/releasing.md`; Phase 11 should widen it into explicit runbooks tied to Git/Release Please/Hex commands. [VERIFIED: docs/releasing.md][CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] |

## Project Constraints (from AGENTS.md)

- Keep Scrypath Ecto-first and Phoenix-friendly. [VERIFIED: AGENTS.md]
- Keep Meilisearch as the public v1 backend target. [VERIFIED: AGENTS.md]
- Preserve the internal adapter seam without promising a public multi-backend abstraction in v1. [VERIFIED: AGENTS.md]
- Keep inline, Oban-backed, and manual sync modes intact. [VERIFIED: AGENTS.md]
- Keep operational realities explicit in docs and maintainer workflows. [VERIFIED: AGENTS.md]
- Do not optimize for speed-to-release over release quality. [VERIFIED: AGENTS.md]

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REL-01 | Maintainer can publish Scrypath from the canonical GitHub release flow with aligned tag, changelog, manifest, package version, and Hex artifact state. | Use Release Please manifest mode as the only version source, add release-aware package links, and add an automated alignment check across `mix.exs`, `.release-please-manifest.json`, generated changelog entry, checked-out tag, and Hex artifact metadata. [VERIFIED: .github/workflows/release-please.yml + release-please-config.json + .release-please-manifest.json + mix.exs + `mix verify.phase10` output] |
| REL-02 | Maintainer can verify the published package from a clean consumer flow that confirms install, docs availability, and basic runtime usability. | Add a throwaway consumer smoke harness that installs `{:scrypath, "~> X.Y.Z"}` from Hex, reaches HexDocs, compiles a `use Scrypath` schema, and optionally runs one Meilisearch-backed happy path. [VERIFIED: README.md + guides/getting-started.md + local throwaway consumer compile on 2026-04-16] |
| REL-03 | Maintainer can recover from common release failures using documented runbooks for tag/version drift, failed publish, and published-artifact mismatch. | Document one runbook per failure class using Hex-supported revert/replace semantics and repo-specific Git/Release Please checks. [VERIFIED: docs/releasing.md][CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] |
</phase_requirements>

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `googleapis/release-please-action` | `v4` | Release PR, tag, GitHub Release, and semver outputs. [VERIFIED: .github/workflows/release-please.yml][CITED: https://github.com/googleapis/release-please-action] | It is already the canonical release orchestrator in this repo, and it supports Elixir repositories plus manifest mode outputs used by the publish job. [VERIFIED: .github/workflows/release-please.yml + release-please-config.json][CITED: https://github.com/googleapis/release-please-action] |
| `erlef/setup-beam` | `v1` | Provision Elixir/OTP for publish and CI. [VERIFIED: .github/workflows/ci.yml + .github/workflows/release-please.yml] | It is the established Elixir GH Actions setup in this repo and in project research. [VERIFIED: .github/workflows/ci.yml + .github/workflows/release-please.yml + AGENTS.md] |
| Hex CLI | local archive `2.4.1` | Build, dry-run, publish, replace, and revert Hex packages. [VERIFIED: `mix help hex.publish` location on 2026-04-16][CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] | Hex is the authoritative publisher and recovery surface for package/doc artifacts. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] |
| ExDoc | `0.40.1` | Generate release docs and version-aware source links. [VERIFIED: mix.lock + `mix hex.info ex_doc` + mix.exs][CITED: https://hexdocs.pm/ex_doc/0.40.1/Mix.Tasks.Docs.html] | Scrypath already uses ExDoc extras and groups, and `mix docs --warnings-as-errors` is part of the release gate. [VERIFIED: mix.exs + lib/mix/tasks/verify.phase10.ex + .github/workflows/ci.yml] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| GitHub CLI | `2.89.0` | Inspect releases, tags, and repo state during recovery or verification. [VERIFIED: `gh --version` on 2026-04-16] | Use for maintainer triage and post-publish inspection. [VERIFIED: local environment probe on 2026-04-16] |
| Docker | `29.3.1` | Spin up Meilisearch for consumer runtime smoke or live publish verification. [VERIFIED: `docker --version` on 2026-04-16] | Use when Phase 11 chooses to verify a real inline sync/search path, not just compile-time usability. [VERIFIED: .github/workflows/ci.yml phase5-verification + README.md] |
| `mix verify.phase10` | repo task | Existing auth-free package confidence gate. [VERIFIED: lib/mix/tasks/verify.phase10.ex + successful local run on 2026-04-16] | Run before release, inside CI, and inside any future Phase 11 aggregate verification task. [VERIFIED: docs/releasing.md + lib/mix/tasks/verify.phase10.ex] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Same-workflow conditional publish after Release Please | Separate workflow triggered by `release.created` | The current same-workflow design avoids the `GITHUB_TOKEN` downstream-trigger limitation for publish itself; a separate downstream workflow would need PAT/GitHub App handling and more repo settings. [VERIFIED: .github/workflows/release-please.yml][CITED: https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/trigger-a-workflow][CITED: https://github.com/googleapis/release-please-action] |
| Release Please-managed versioning | Manual edits to `mix.exs`, changelog, and tags | Manual version edits are exactly how drift gets introduced; the repo already chose Release Please. [VERIFIED: release-please-config.json + docs/releasing.md] |

**Installation:** No new production dependency is required for Phase 11 by default; this phase is primarily workflow, docs, and verification work. [VERIFIED: mix.exs + .github/workflows/release-please.yml + docs/releasing.md]

## Architecture Patterns

### System Architecture Diagram

```text
merged commits on main
        |
        v
Release Please action
  - reads manifest/config
  - computes next version
  - updates changelog/release PR
        |
        v
maintainer merges release PR
        |
        v
same workflow push on main
        |
        +--> release_created == false -> stop
        |
        +--> release_created == true
                |
                v
         checkout produced tag
                |
                v
         mix deps.get
                |
                v
         mix hex.publish --yes
                |
                +--> Hex package + HexDocs published
                |
                v
        post-publish verification
          - tag/changelog/manifest/mix version match
          - Hex page reachable
          - HexDocs reachable
          - clean consumer smoke passes
          - recovery runbook selected if mismatch appears
```

This is the contract already implied by the repo workflow, plus the missing Phase 11 post-publish verification layer. [VERIFIED: .github/workflows/release-please.yml + docs/releasing.md]

### Recommended Project Structure

```text
.github/workflows/
├── ci.yml                   # pre-merge and auth-free package gate
└── release-please.yml       # canonical release + publish workflow
docs/
└── releasing.md             # maintainer contract and recovery runbooks
lib/mix/tasks/
└── verify.phase10.ex        # existing release confidence task
test/release/
├── package_metadata_test.exs
└── consumer_smoke_test.exs  # Phase 11 recommended addition
```

The new file shown above is prescriptive for planning, not evidence that it already exists. [VERIFIED: current repo structure except `test/release/consumer_smoke_test.exs`][ASSUMED]

### Pattern 1: Version-Anchored Metadata Everywhere

**What:** Derive every release-facing link and source reference from one version constant in `mix.exs`. [VERIFIED: mix.exs]

**When to use:** Use for package links, ExDoc source links, changelog links, and any script that reports the current package version. [VERIFIED: mix.exs + `mix verify.phase10` output]

**Example:**

```elixir
# Source: /Users/jon/projects/scrypath/mix.exs
@version "0.1.0"
@source_url "https://github.com/szTheory/scrypath"
@source_ref "v#{@version}"
```

**Phase 11 recommendation:** Extend this pattern to package links so the changelog and guide links stop pointing at moving `main` or latest-doc URLs. [VERIFIED: mix.exs + `mix verify.phase10` output]

### Pattern 2: Same-Workflow Publish From The Produced Tag

**What:** Publish from the exact tag generated by Release Please inside the same workflow run. [VERIFIED: .github/workflows/release-please.yml]

**When to use:** Use as the canonical public release path; do not add alternate manual publish routes as first-class flows. [VERIFIED: docs/releasing.md + .github/workflows/release-please.yml]

**Example:**

```yaml
# Source: /Users/jon/projects/scrypath/.github/workflows/release-please.yml
publish-hex:
  needs: release-please
  if: ${{ needs.release-please.outputs.release_created == 'true' }}
  steps:
    - uses: actions/checkout@v4
      with:
        ref: ${{ needs.release-please.outputs.tag_name }}
    - name: Publish package to Hex
      run: mix hex.publish --yes
```

### Pattern 3: Throwaway Consumer Smoke Outside The Repo

**What:** Prove installability and basic documented usage from a fresh Mix app rather than from Scrypath's own test environment. [VERIFIED: README.md + guides/getting-started.md + local throwaway consumer compile on 2026-04-16]

**When to use:** Run after publish, or against a just-built artifact if the phase adds a pre-publish approximation. [VERIFIED: user phase success criteria + README.md]

**Example:**

```bash
# Source: derived from README.md and verified locally with a path dependency on 2026-04-16
mix new consumer_usage --sup
cd consumer_usage
# add {:scrypath, "~> X.Y.Z"} to deps
mix deps.get
mix compile
```

### Anti-Patterns to Avoid

- **Manual dual-authority versioning:** Do not hand-edit `mix.exs`, changelog, and tags independently once Release Please is the release authority. [VERIFIED: docs/releasing.md + release-please-config.json]
- **Moving artifact links:** Do not leave Hex package links pointing at `blob/main` or unversioned latest-doc URLs if the release contract is meant to be auditable per version. [VERIFIED: mix.exs + `mix verify.phase10` output]
- **Release success inferred from dry-run alone:** `mix hex.publish --dry-run --yes` checks local publishability, not the actual published artifact. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html]
- **Assuming generated release PRs get CI automatically:** Release Please warns that `GITHUB_TOKEN`-created resources do not trigger new workflow runs. [CITED: https://github.com/googleapis/release-please-action][CITED: https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/trigger-a-workflow] |

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Semver bump + changelog orchestration | custom scripts or manual checklists | Release Please manifest mode | It already owns this repo's release metadata and emits the tag/version outputs the publish job needs. [VERIFIED: release-please-config.json + .release-please-manifest.json + .github/workflows/release-please.yml][CITED: https://github.com/googleapis/release-please-action] |
| Hex package inspection | tar parsing scripts | `mix hex.build --unpack` and `mix hex.publish --dry-run --yes` | Hex already provides the supported inspection and preflight commands. [VERIFIED: docs/releasing.md + lib/mix/tasks/verify.phase10.ex][CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] |
| Docs artifact validation | custom HTML crawlers first | `mix docs --warnings-as-errors` plus targeted link checks | ExDoc already produces the docs artifact and fails on warnings. [VERIFIED: lib/mix/tasks/verify.phase10.ex + .github/workflows/ci.yml][CITED: https://hexdocs.pm/ex_doc/0.40.1/Mix.Tasks.Docs.html] |
| Consumer harness framework | bespoke fixtures in the main app | a throwaway Mix app created with `mix new` | The trust question is "can a clean user consume the package," so the harness should look like a clean user app. [VERIFIED: local throwaway consumer compile on 2026-04-16] |

**Key insight:** The Phase 11 risk is alignment drift, so the safest plan is to reuse the official release surfaces already chosen by the repo and add comparison checks around them. [VERIFIED: docs/releasing.md + .github/workflows/release-please.yml + mix.exs]

## Common Pitfalls

### Pitfall 1: Manifest / Tag / `mix.exs` Drift Before The First Public Release

**What goes wrong:** The repo currently says `0.1.0` in both `mix.exs` and `.release-please-manifest.json`, but this clone has no `v0.1.0` package tag and Hex has no published `scrypath` package. [VERIFIED: mix.exs + .release-please-manifest.json + `git tag --sort=version:refname` + `mix hex.info scrypath`]

**Why it happens:** Phase 10 validated the package path locally without proving a real public cut, so the version baseline exists before public artifact state exists. [VERIFIED: docs/releasing.md + `mix verify.phase10` output + STATE.md]

**How to avoid:** Decide the first public version explicitly, then align manifest, generated release PR, resulting tag, and post-publish Hex artifact around that decision in one flow. [VERIFIED: release-please-config.json + .release-please-manifest.json + user success criteria]

**Warning signs:** Missing matching package tag, empty GitHub release list, or `mix hex.info scrypath` reporting no package. [VERIFIED: `git tag --sort=version:refname` + `gh release list --limit 20` + `mix hex.info scrypath`]

### Pitfall 2: Hex Artifact Links Drift Even When `source_ref` Is Correct

**What goes wrong:** `source_ref` is version-anchored, but package links for `Changelog`, `Guides`, and `HexDocs` currently point to moving targets. [VERIFIED: mix.exs + `mix verify.phase10` output]

**Why it happens:** The docs contract currently checks presence and values, but it does not yet require version-scoped public URLs. [VERIFIED: test/release/package_metadata_test.exs]

**How to avoid:** Make package links derive from `@version` / `@source_ref`, then test those exact URLs in the release contract. [VERIFIED: mix.exs]

**Warning signs:** Older package pages linking to `main` or to latest docs after newer releases ship. [VERIFIED: mix.exs]

### Pitfall 3: Release PR CI Assumptions With `GITHUB_TOKEN`

**What goes wrong:** Maintainers may expect workflows triggered by Release Please-created PRs or releases to run automatically. [CITED: https://github.com/googleapis/release-please-action][CITED: https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/trigger-a-workflow]

**Why it happens:** GitHub does not create a new workflow run for most events triggered by `GITHUB_TOKEN`, and Release Please documents that caveat explicitly. [CITED: https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/trigger-a-workflow][CITED: https://github.com/googleapis/release-please-action]

**How to avoid:** Keep publish in the same workflow run, and only introduce PAT/GitHub App auth if the plan requires CI-on-release-PR or downstream release-event workflows. [VERIFIED: .github/workflows/release-please.yml][CITED: https://github.com/googleapis/release-please-action]

**Warning signs:** Release PRs without expected CI, or maintainers adding a second publish workflow on `release.created`. [VERIFIED: current repo has no such second workflow in `.github/workflows/`]

### Pitfall 4: Consumer Smoke That Proves Only Installation, Not Usage

**What goes wrong:** A smoke script that only runs `mix deps.get` misses the documented `use Scrypath` path that real users need. [VERIFIED: README.md + guides/getting-started.md + local dependency-only compile on 2026-04-16]

**Why it happens:** Package installability is easier to automate than actual usage. [VERIFIED: local throwaway consumer exercises on 2026-04-16]

**How to avoid:** Compile a minimal schema module using `use Scrypath` and `use Ecto.Schema`, then optionally run a tiny Meilisearch-backed happy path if Docker is available. [VERIFIED: local throwaway `use Scrypath` compile on 2026-04-16 + .github/workflows/ci.yml]

**Warning signs:** Smoke jobs that never compile a schema or never touch the documented quick path. [VERIFIED: current repo has no consumer smoke test under `test/release/`]

## Code Examples

Verified patterns from repo-primary and official sources:

### Alignment Check Skeleton

```bash
# Source: derived from repo files and verified commands on 2026-04-16
VERSION=$(grep -m1 '@version "' mix.exs | cut -d'"' -f2)
MANIFEST_VERSION=$(grep -m1 '"\."' .release-please-manifest.json | cut -d'"' -f4)
test "$VERSION" = "$MANIFEST_VERSION"
mix verify.phase10
HEX_API_KEY=... mix hex.publish --dry-run --yes
```

### Publish-From-Tag Workflow

```yaml
# Source: /Users/jon/projects/scrypath/.github/workflows/release-please.yml
jobs:
  release-please:
    outputs:
      release_created: ${{ steps.release.outputs.release_created }}
      tag_name: ${{ steps.release.outputs.tag_name }}
      version: ${{ steps.release.outputs.version }}

  publish-hex:
    needs: release-please
    if: ${{ needs.release-please.outputs.release_created == 'true' }}
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ needs.release-please.outputs.tag_name }}
      - run: mix hex.publish --yes
```

### Clean Consumer Smoke Shape

```elixir
# Source: README.md / guides/getting-started.md, validated by local throwaway compile on 2026-04-16
defmodule ConsumerUsage.Post do
  use Ecto.Schema

  use Scrypath,
    fields: [:title, :body],
    filterable: [:status],
    sortable: [:inserted_at]

  schema "posts" do
    field :title, :string
    field :body, :string
    field :status, Ecto.Enum, values: [:draft, :published]
    timestamps()
  end
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Separate downstream workflows triggered by repo events from automation tokens | Same-workflow conditional publish from Release Please outputs | Current GitHub Actions guidance and Release Please docs both document `GITHUB_TOKEN` trigger limitations. [CITED: https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/trigger-a-workflow][CITED: https://github.com/googleapis/release-please-action] | Scrypath should keep publish in the existing workflow unless it intentionally adopts PAT/GitHub App auth. [VERIFIED: .github/workflows/release-please.yml] |
| Unversioned docs generation assumptions | ExDoc now generates `html`, `epub`, and `markdown` by default, and `--warnings-as-errors` is a first-class gate. [CITED: https://hexdocs.pm/ex_doc/0.40.1/Mix.Tasks.Docs.html] | Current as of ExDoc `0.40.1`. [VERIFIED: mix.lock + `mix hex.info ex_doc`] | Scrypath can treat docs output as part of the release artifact contract. [VERIFIED: lib/mix/tasks/verify.phase10.ex] |

**Deprecated/outdated:**

- Editing changelog and version surfaces manually while Release Please is the release authority is outdated for this repo. [VERIFIED: docs/releasing.md + release-please-config.json]
- Treating `mix hex.publish --dry-run` as proof of a published artifact is outdated; it is only a local preflight. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A new `test/release/consumer_smoke_test.exs` file is the right place for automated consumer smoke coverage. [ASSUMED] | Architecture Patterns | Low; the exact file location can change without affecting the release contract. |

## Open Questions

1. **Should the first public package be `0.1.0` or the next Release Please-generated version?**
   - What we know: `mix.exs` and `.release-please-manifest.json` are both `0.1.0`, but there is no `v0.1.0` package tag and no published Hex package. [VERIFIED: mix.exs + .release-please-manifest.json + `git tag --sort=version:refname` + `mix hex.info scrypath`]
   - What's unclear: Whether maintainers want the first public artifact to preserve `0.1.0` or to let Release Please advance from the seeded baseline. [VERIFIED: current repo state; no explicit decision found]
   - Recommendation: Make this an explicit planning decision before execution so the runbook and alignment tests can target one version story. [VERIFIED: repo state mismatch]

2. **Is CI-on-release-PR required, or is CI-on-merge sufficient?**
   - What we know: The current publish path works in one workflow after merge, and that does not require a PAT. [VERIFIED: .github/workflows/release-please.yml]
   - What's unclear: Whether maintainers also want PR-triggered CI on Release Please-created PRs. [VERIFIED: no explicit repo policy found]
   - Recommendation: Default to the current simpler token model unless maintainers explicitly want CI on generated release PRs. [VERIFIED: current workflow + official docs token caveat][CITED: https://github.com/googleapis/release-please-action]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | local release verification and consumer smoke | ✓ | `1.19.5` | — [VERIFIED: `elixir --version` on 2026-04-16] |
| Mix | local release verification and consumer smoke | ✓ | `1.19.5` | — [VERIFIED: `mix --version` on 2026-04-16] |
| Git | tag inspection and drift recovery | ✓ | `2.41.0` | — [VERIFIED: `git --version` on 2026-04-16] |
| GitHub CLI | release inspection and manual triage | ✓ | `2.89.0` | browser UI [VERIFIED: `gh --version` on 2026-04-16] |
| Docker | optional Meilisearch-backed consumer smoke | ✓ | `29.3.1` | compile-only consumer smoke [VERIFIED: `docker --version` on 2026-04-16] |
| `HEX_API_KEY` | real public publish path | ✗ | — | no fallback for real publish; local dry-run remains available [VERIFIED: STATE.md + docs/releasing.md] |
| `SCRYPATH_MEILISEARCH_URL` | live backend smoke outside CI | ✗ | — | Dockerized local Meilisearch or compile-only smoke [VERIFIED: STATE.md + .github/workflows/ci.yml] |

**Missing dependencies with no fallback:**
- Publisher-scoped `HEX_API_KEY` for the real public release. [VERIFIED: STATE.md + docs/releasing.md]

**Missing dependencies with fallback:**
- Live `SCRYPATH_MEILISEARCH_URL`; Docker or compile-only smoke can cover most of REL-02 until a live endpoint is provided. [VERIFIED: STATE.md + .github/workflows/ci.yml + local consumer compile on 2026-04-16]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit in Mix project. [VERIFIED: test/test_helper.exs + `mix test` output] |
| Config file | none; standard Mix/ExUnit layout. [VERIFIED: repo scan on 2026-04-16] |
| Quick run command | `mix test test/release/package_metadata_test.exs test/scrypath/docs_contract_test.exs` [VERIFIED: successful local run on 2026-04-16] |
| Full suite command | `mix verify.phase10 && mix test --exclude integration && mix verify.phase5` [VERIFIED: lib/mix/tasks/verify.phase10.ex + .github/workflows/ci.yml] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REL-01 | Canonical release surfaces stay aligned before and after publish. | unit + workflow contract | `mix verify.phase10` plus a new Phase 11 alignment check task/test. [VERIFIED: current command exists; new Phase 11 check does not] | Partial |
| REL-02 | Published package installs and documented quick path compiles in a clean consumer app. | smoke | new consumer smoke command built around `mix new` and `mix deps.get`. [VERIFIED: local throwaway compile succeeded on 2026-04-16] | ❌ Wave 0 |
| REL-03 | Maintainer can execute one documented recovery path per failure class. | docs contract + manual drill | docs contract tests plus scripted dry-runs for revert/replace and drift triage. [VERIFIED: docs/releasing.md exists; no dedicated recovery tests found] | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `mix test test/release/package_metadata_test.exs test/scrypath/docs_contract_test.exs` [VERIFIED: current test files and successful local run on 2026-04-16]
- **Per wave merge:** `mix verify.phase10` [VERIFIED: docs/releasing.md + successful local run on 2026-04-16]
- **Phase gate:** `mix verify.phase10` + clean-consumer smoke + one maintainer dry-run of recovery commands before `/gsd-verify-work`. [VERIFIED: current gate exists; Phase 11 additions inferred from requirements][ASSUMED]

### Wave 0 Gaps

- [ ] `test/release/consumer_smoke_test.exs` or equivalent script-backed smoke harness for REL-02. [ASSUMED]
- [ ] Release-aware package link assertions in `test/release/package_metadata_test.exs`. [VERIFIED: current test asserts moving links instead]
- [ ] A Phase 11 alignment task that compares `mix.exs`, manifest, generated tag, changelog, and published artifact state. [VERIFIED: no such task found in `lib/mix/tasks/`]
- [ ] Recovery-runbook coverage for revert/replace/drift procedures. [VERIFIED: docs/releasing.md does not yet contain explicit runbooks]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Not a user-auth phase. [VERIFIED: phase scope] |
| V3 Session Management | no | Not a session phase. [VERIFIED: phase scope] |
| V4 Access Control | yes | Limit publish rights to GitHub Actions + Hex owners and keep publish secrets scoped to the publish job. [VERIFIED: .github/workflows/release-please.yml + docs/releasing.md][CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.User.html] |
| V5 Input Validation | yes | Validate release metadata inputs through alignment checks rather than trusting hand edits. [VERIFIED: repo drift risks from mix.exs + manifest + tags] |
| V6 Cryptography | yes | Use GitHub Secrets / Hex API keys; never hand-roll credential storage. [VERIFIED: docs/releasing.md][CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.User.html] |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Secret leakage through non-publish jobs | Information Disclosure | Keep `HEX_API_KEY` scoped to the publish job only. [VERIFIED: .github/workflows/release-please.yml + docs/releasing.md] |
| Unauthorized or accidental publish from wrong ref | Tampering | Publish only after `release_created == true` and checkout the produced tag before publish. [VERIFIED: .github/workflows/release-please.yml] |
| Artifact/source mismatch | Tampering | Compare tag, `@version`, `source_ref`, manifest version, and post-publish artifact metadata in one gate. [VERIFIED: mix.exs + .release-please-manifest.json + `mix verify.phase10` output] |
| Recovery mistakes after a bad publish | Repudiation / Tampering | Use Hex-supported `--revert` and `--replace` windows with explicit runbooks. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] |

## Sources

### Primary (HIGH confidence)

- [VERIFIED: /Users/jon/projects/scrypath/docs/releasing.md] - existing maintainer release contract
- [VERIFIED: /Users/jon/projects/scrypath/.github/workflows/release-please.yml] - canonical release workflow
- [VERIFIED: /Users/jon/projects/scrypath/release-please-config.json] - Release Please strategy
- [VERIFIED: /Users/jon/projects/scrypath/.release-please-manifest.json] - seeded release baseline
- [VERIFIED: /Users/jon/projects/scrypath/mix.exs] - version, docs, and package metadata contract
- [VERIFIED: /Users/jon/projects/scrypath/CHANGELOG.md] - current changelog baseline
- [VERIFIED: /Users/jon/projects/scrypath/lib/mix/tasks/verify.phase10.ex] - current release verification task
- [VERIFIED: /Users/jon/projects/scrypath/test/release/package_metadata_test.exs] - package metadata assertions
- [VERIFIED: /Users/jon/projects/scrypath/test/scrypath/docs_contract_test.exs] - docs/release gate assertions
- [CITED: https://github.com/googleapis/release-please-action] - manifest mode, outputs, token caveats, Elixir release type
- [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] - publish, dry-run, revert, replace, docs behavior
- [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.User.html] - API key generation and permission model
- [CITED: https://hexdocs.pm/ex_doc/0.40.1/Mix.Tasks.Docs.html] - docs generation and warnings-as-errors behavior
- [CITED: https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/trigger-a-workflow] - `GITHUB_TOKEN` workflow-trigger limitation

### Secondary (MEDIUM confidence)

- [VERIFIED: local command runs on 2026-04-16] `mix verify.phase10`, `mix test ...`, throwaway consumer compiles, `gh release list`, `mix hex.info scrypath`

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - The repo already uses this stack and the official docs confirm the relevant behavior. [VERIFIED: repo files + cited official docs]
- Architecture: HIGH - The release flow is explicit in the workflow and validated locally. [VERIFIED: .github/workflows/release-please.yml + local command runs]
- Pitfalls: HIGH - The main risks are directly observable in the current repo state. [VERIFIED: mix.exs + manifest + tags + empty release/package state]

**Research date:** 2026-04-16
**Valid until:** 2026-05-16
