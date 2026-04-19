# Releasing Scrypath

**For library adopters:** the [README](../README.md) summarizes versioning expectations and points at release notes. **This document** is the maintainer source of truth for Release Please, **`mix verify.phase11`**, publish checks, and parity workflows—read it before changing release automation. **Live Meilisearch job names** (`meilisearch-smoke`, `phase5-verification`, etc.) stay indexed in [`CONTRIBUTING.md`](../CONTRIBUTING.md) alongside `.github/workflows/ci.yml`—avoid duplicating that matrix here.

Release Please owns the version bump, changelog PR, and Git tag for Scrypath. The only publish path is the existing GitHub Actions workflow: Release Please creates `vX.Y.Z`, Actions checks out that tag, and `mix hex.publish --yes` runs from that tagged ref.

## Automated Release Gate

Run the auth-free package gate before you merge a release PR or when you need the same checks outside CI:

```bash
mix verify.phase11
```

That command is the always-on CI gate for the release contract. It runs the package metadata test, the clean-consumer smoke test, the release-doc contract, docs with warnings as errors, release workflow checks, and `mix hex.build --unpack`.

Use this release-only credential check only when you are preparing an actual publish with a publisher-scoped Hex key:

```bash
HEX_API_KEY=... mix hex.publish --dry-run --yes
```

That command must stay out of the always-on CI gate.

After a real Hex publish, the release workflow now runs the live post-publish check automatically:

```bash
mix verify.release_publish X.Y.Z
```

That task polls Hex until the published version is visible, compiles the documented `use Scrypath` schema from a fresh throwaway app using `{:scrypath, "~> X.Y.Z"}`, and confirms `https://hexdocs.pm/scrypath/X.Y.Z` responds.

Immediately after that succeeds, the same publish jobs in `.github/workflows/release-please.yml` and `.github/workflows/publish-hex.yml` run `mix verify.release_parity X.Y.Z` with the same `SCRYPATH_RELEASE_VERIFY_ATTEMPTS` / `SCRYPATH_RELEASE_VERIFY_SLEEP_MS` retry knobs, so tarball–tag parity is checked on the post-publish path, not only by the scheduled monitor.

## Minimum Secret Setup

Create this GitHub Actions secret before the first automated release:

1. `HEX_API_KEY` - Hex.pm API key that can publish `scrypath`

The workflow uses GitHub's built-in `GITHUB_TOKEN` for Release Please. Keep `HEX_API_KEY` scoped to the publish workflows only. Do not expose it to the always-on CI job.

## Local CI Reproduction

For a deterministic local reproduction of the always-on release contract gate, run the Docker smoke wrapper:

```bash
./scripts/verify_phase11_docker.sh
```

That gives you the same `mix verify.phase11` path CI executes, without depending on your host Beam toolchain or a real Hex publish.

If you prefer `act`, keep it as a secondary option and pin a runner image that has a working Beam/OpenSSL stack for your host architecture. The Docker wrapper is the default because it is less brittle.

## Ongoing Published Release Verification

The repository also includes `.github/workflows/verify-published-release.yml` for ongoing verification after the first public release.

- It runs on a daily schedule and on manual `workflow_dispatch`.
- It reads the latest published Scrypath version from `https://hex.pm/api/packages/scrypath`.
- Before the first public release, it detects the Hex 404 and exits cleanly.
- After Scrypath is published, it runs `mix verify.release_publish X.Y.Z` against the latest published version without attempting any publish or recovery action.

Treat failures in this workflow as operational regressions in the published package, Hex availability, or HexDocs availability.

## Canonical Release Flow

1. Confirm the repo state before merge:

   ```bash
   mix verify.phase11
   grep -n '@version\|@source_ref' mix.exs
   cat .release-please-manifest.json
   sed -n '1,80p' CHANGELOG.md
   ```

2. Review the Release Please PR. The version in `mix.exs`, `.release-please-manifest.json`, and the top changelog entry should all describe the same `vX.Y.Z` release.
3. Merge the Release Please PR to `main`. The existing `.github/workflows/release-please.yml` workflow is the only release path. When `release_created == true`, the `publish-hex` job checks out `tag_name` and runs `mix hex.publish --yes`.
   Before the real publish, that job also verifies `mix.exs` matches the Release Please version, runs `mix verify.phase11`, and runs `mix hex.publish --dry-run --yes`.
4. After the workflow finishes, confirm the release artifacts:

   ```bash
   git fetch --tags origin
   git tag --sort=version:refname | tail -n 5
   gh run view --log
   ```

   The publish job now runs `mix verify.release_publish X.Y.Z` for the newly released version, so Hex package visibility, clean-consumer compile, and versioned HexDocs reachability are checked inside the workflow instead of by hand. As a post-publish follow-on, it then runs `mix verify.release_parity X.Y.Z` with the same retry environment variables so tarball contents stay aligned with the git tag.

5. If the workflow passes, treat the release contract as satisfied. Manual spot-checks are optional, not required.

## Recovering Tag or Version Drift

Start by comparing the repo version sources and the pushed tags directly:

```bash
grep -n '@version\|@source_ref' mix.exs
cat .release-please-manifest.json
sed -n '1,80p' CHANGELOG.md
git fetch --tags origin
git tag --sort=version:refname | tail -n 10
```

- If `mix.exs`, `.release-please-manifest.json`, and `CHANGELOG.md` disagree before publish, fix the release PR or rerun Release Please. Do not hand-create a new package tag.
- If GitHub has the wrong `vX.Y.Z` tag or release but Hex does not have the package yet, delete the bad release state and rerun the existing workflow:

  ```bash
  gh release delete vX.Y.Z --yes
  git push origin :refs/tags/vX.Y.Z
  gh workflow run release-please.yml
  ```

- If Hex already has `X.Y.Z`, treat the issue as a published artifact problem and follow the artifact-mismatch runbook below. Do not retag the same version behind Hex's back.

## Recovering a Failed Publish

Use the same tagged release ref that Release Please created. Do not invent a second publish path or bump the version manually just because the publish step failed.

1. Check out the release tag and rerun the local gate:

   ```bash
   git fetch --tags origin
   git checkout vX.Y.Z
   mix deps.get
   mix verify.phase11
   HEX_API_KEY=... mix hex.publish --dry-run --yes
   ```

2. If the dry run fails, fix the packaging or docs issue on the release branch input, merge the correction, and let Release Please cut the next proper release PR.
3. If the dry run passes and `mix hex.info scrypath` does not show `X.Y.Z`, rerun the existing checks from the same reviewed ref with the manual recovery workflow:

   - open `.github/workflows/publish-hex.yml`
   - set `tag` to the reviewed release tag or commit ref
   - set `release_version` to `X.Y.Z`

   That workflow reruns `mix verify.phase11`, `mix hex.publish --dry-run --yes`, `mix hex.publish --yes`, and `mix verify.release_publish X.Y.Z` from the explicit ref, then mirrors the canonical path with `mix verify.release_parity X.Y.Z` using the same retry environment variables.

4. After a successful publish, rerun:

   ```bash
   mix verify.release_publish X.Y.Z
   ```

   The same task is what the release workflow runs after `mix hex.publish --yes`.

## Manual Recovery Workflow

Use `.github/workflows/publish-hex.yml` only for recovery or explicit republish from a reviewed tag/ref.

Inputs:

- `tag` - reviewed release tag or commit ref to publish from
- `release_version` - expected `@version` at that ref

The recovery workflow never depends on Release Please step outputs. It verifies the checked-out ref directly before publishing.

## Recovering Published Artifact Mismatch

Use `--replace` only when Hex still allows replacing the published version and the correct fix is "same version, corrected artifact." Use `--revert` when the bad artifact should be withdrawn and replaced by a fresh release.

1. Confirm the mismatch from the published artifact, local package contents, and docs path:

   ```bash
   mix verify.phase11
   mix hex.build --unpack
   mix hex.info scrypath
   curl -Ifs https://hexdocs.pm/scrypath/X.Y.Z
   ```

2. Replace the same version only if the tag is correct and Hex still allows replacement for that release window:

   ```bash
   HEX_API_KEY=... mix hex.publish --dry-run --yes
   HEX_API_KEY=... mix hex.publish --replace --yes
   ```

3. Revert and republish under a new Release Please cut when the tag or version itself is wrong, when the replace window is closed, or when you need a clean corrective release trail:

   ```bash
   HEX_API_KEY=... mix hex.publish --revert X.Y.Z
   ```

   After the revert, fix the repo state, let Release Please open the next versioned PR, merge it, and rerun the canonical release flow plus `mix verify.release_publish X.Y.Z` for the new release.

## Release parity gate

Scrypath publishes through two mechanized gates that prevent the v1.2-era
divergence where a git tag and the published Hex tarball drifted.

### `mix verify.workspace_clean`

Runs before `mix hex.publish` on every publish path (`.github/workflows/ci.yml`
quality job, `.github/workflows/release-please.yml` publish-hex job, and
`.github/workflows/publish-hex.yml` manual recovery). Fails if the working
tree has any uncommitted or untracked files under the paths that ship in
the tarball (`lib/`, `test/`, `guides/`, `docs/`, `mix.exs`,
`.formatter.exs`, top-level `.md` files). Catches tag-vs-source drift at
publish time.

There is deliberately no escape-hatch flag or environment variable — in a
true emergency, comment out the workflow step in a PR. The friction is the
feature.

### `mix verify.release_parity X.Y.Z`

Runs daily via `.github/workflows/verify-published-release.yml` (cron) and
compares the published Hex tarball's `lib/ + guides/ + docs/` file list
against the git tag of the same version. Catches tarball-vs-tag drift
AFTER publish.

The scheduled workflow remains the long-horizon monitor, but `release-please.yml`
and `publish-hex.yml` also invoke `mix verify.release_parity` immediately after
a successful `mix verify.release_publish` on the post-publish path, so drift is
caught in the same mechanical publish sequence as the Hex publish itself.

Exit codes:

- `0` — parity (no drift)
- `2` — drift detected
- `1` — runtime error (network, missing tag, etc.)

On drift during a scheduled run, a deduplicated GitHub issue is auto-filed
using `.github/ISSUE_TEMPLATE/release-parity-drift.md`.

### Historical context

These gates exist because an earlier release cycle shipped with **tag and
default-branch refs out of alignment** (package and docs consumers could see
different trees than maintainers expected). The parity tasks catch that class of
drift on publish and on a schedule so it does not wait for the next manual
release to surface.
