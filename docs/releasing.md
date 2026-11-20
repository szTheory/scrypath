# Releasing Scrypath

**For library adopters:** the [README](../README.md) summarizes versioning expectations and points at release notes. **This document** is the maintainer source of truth for Release Please, **`mix verify.package`**, publish checks, and parity workflows—read it before changing release automation. **Live backend jobs** stay indexed in [`CONTRIBUTING.md`](../CONTRIBUTING.md) alongside `.github/workflows/ci.yml`—avoid duplicating that matrix here.

Release Please owns the version bump, changelog PR, and Git tag for Scrypath. The only publish path is the existing GitHub Actions workflow: Release Please creates `vX.Y.Z`, Actions checks out that tag, and `mix hex.publish --yes` runs from that tagged ref.

## Release train posture

Scrypath now runs a **green-main release train**:

- `main` stays green on the lean required gates only: **`core`**, **`package`**, **`repository-contracts`**, **`backend`**, and **`ecommerce-mounted`**.
- The default shipping posture is **patch-first while the library remains pre-1.0**. The existing Release Please configuration already uses the pre-1.0 bump knobs, so ordinary merged work rolls forward on patch cadence.
- Serious milestone or feature-depth work should land through **PRs**, not direct `main` development.
- **Squash merge only** is the intended feed into Release Please. The PR title should be treated as the release-facing summary because it becomes the squash commit title.
- If `main` is green and there is no coherent release PR to review, the default maintainer answer is **nothing to do**.

### Hex package files vs `scrypath_ops/`

The optional operator Phoenix app lives in **`scrypath_ops/`** at the repository root. It is **not** part of the published Hex artifact. The root library **`mix.exs`** **`package.files`** whitelist **must never** list **`scrypath_ops/`** (or otherwise pull OPSUI into the tarball). Run **`mix hex.publish`** only from the **library** project directory (the same directory as the root `mix.exs` that defines `:scrypath`), never from `scrypath_ops/`.

### README header and HexDocs brand assets

A published README and its docs cannot be corrected after a release, so the header and the brand assets follow these rules.

- The README header uses absolute `raw.githubusercontent.com` URLs pinned to a commit (`.../szTheory/scrypath/<commit>/brand/assets/readme/...`). They load on GitHub, on hex.pm (which proxies images and drops `<source>`, so it always shows the light image) and in HexDocs. `brand/` stays out of `package.files`, and a Hex consumer never reads it. The pinned commit must be an ancestor of `main` and its two SVGs must be byte-identical to the committed files; `test/release/package_metadata_test.exs` checks both, so a brand update that changes a header must move the pin in the same change. Never point README images at the Pages site, because it is mutable and served from `main`.
- README images never point at the Pages site, because it is mutable and served from `main`.
- hex.pm renders the README through `readme.hex.pm`, which serves relative images only from files inside the package tarball. That is why the header uses absolute pinned URLs. After publishing, open the package page and confirm the header image loads.
- The header `<picture>` follows the operating-system theme, while ExDoc follows its own light and dark toggle. A dark operating system with ExDoc set to light shows the dark header on a light page. This is a known residual.
- The ExDoc logo is the light symbol, and one docs-owned rule swaps in the dark symbol under ExDoc's dark mode. The favicon is `brand/assets/icon/favicon-light.svg`, because the pinned `favicon.svg` carries no colors and renders black.
- `dev/docs/scrypath-exdoc.css` is derived from the pinned `brand/assets/docs/scrypath-exdoc.css`: the block that follows the operating-system dark setting is removed, every color rule is written for both `body ` and `body.dark `, and two docs-owned rules are added (the token contrast rule below and the dark logo rule). After a brand pin update, re-derive it. `test/release/package_metadata_test.exs` fails until it matches.
- Token classes the brand book does not color keep ExDoc's own colors, except where those colors fall below WCAG AA (4.5:1) on the brand code background. Operators, entities, labels, delimiters and lexer errors take the brand text color through the contrast rule, and a built-docs test measures every token class the docs use in both themes. If a new docs page uses a class that fails the test, add it to that rule, and send the class back to the brand book owner so the pin carries it.
- The built-docs checks run in `core` and in `mix verify.package`.

## Automated Release Gate

Run the auth-free package gate before you merge a release PR or when you need the same checks outside CI:

```bash
mix verify.package
```

That command is the always-on CI gate for the release contract. The gate also builds and unpacks the real Hex archive, and fails if the archive contains any top-level entry outside the package allowlist or any Mix task other than the public `mix scrypath.*` operator tasks. Repository-only verifiers live in `dev/mix/tasks/` and are never packaged.

`mix verify.package` and the focused docs contract (`mix test test/scrypath/docs_contract_test.exs`) are pre-publish checks: they verify the package and the documented release flow before publication. They do not prove that a version is visible on Hex or HexDocs. Post-publish evidence comes from `mix verify.release_publish X.Y.Z`, which checks package and documentation availability, followed by `mix verify.release_parity X.Y.Z` to compare the published artifact with the Release Please-owned tag. Release Please owns the version bump, changelog, and tag.

### Operator UI (`scrypath_ops`)

The optional operator Phoenix app under **`scrypath_ops/`** is not published to Hex, but it still has a first-class verification gate. From the repository root, run:

```bash
mix verify.ops_ui
```

That task mirrors CI: it runs **`cd scrypath_ops && mix deps.get && mix test`** (full suite, including navigation contract setup).

For a faster slice while iterating on OPSUI accessibility semantics (tests tagged **`opsui_a11y`**), run:

```bash
cd scrypath_ops && mix opsui.test_a11y
```

That alias runs `scrypath_ops.check_nav_contract`, creates and migrates the OPSUI database quietly, then runs **`mix test --only opsui_a11y`**. It is an OPSUI accessibility slice; it does not run package metadata, clean-consumer smoke, release-doc contract, docs, release workflow, or `mix hex.build --unpack` checks. Use **`mix verify.package`** for the auth-free release/package truth gate.

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

When a release or CI run finishes, note any cheap speed or cost win (cache keys, duplicated work, cold-cache time) that would not weaken the gate; see "CI and CD efficiency" in `AGENTS.md` and the measured ledger in `.planning/reference/CI-EFFICIENCY.md`, which also lists the local-first checks to run before waiting on hosted CI.

For a deterministic local reproduction of the always-on release contract gate, run the Docker smoke wrapper:

```bash
./scripts/verify_phase11_docker.sh
```

That script retains the historical `verify.phase11` wrapper while enforcing the same package proof as `mix verify.package`, without depending on your host Beam toolchain or a real Hex publish.

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
mix verify.package
   grep -n '@version\|@source_ref' mix.exs
   cat .release-please-manifest.json
   sed -n '1,80p' CHANGELOG.md
   ```

2. Review the Release Please PR. The version in `mix.exs`, `.release-please-manifest.json`, and the top changelog entry should all describe the same `vX.Y.Z` release.
   On the train, the release PR should be the only version-changing PR in flight.
3. Merge the Release Please PR to `main`. The existing `.github/workflows/release-please.yml` workflow is the only release path. When `release_created == true`, the `publish-hex` job checks out `tag_name` and runs `mix hex.publish --yes`.
   Before the real publish, that job runs the same ordered proof chain as recovery: `mix verify.workspace_clean` -> version grep -> `mix verify.package` -> `mix hex.publish --dry-run --yes` -> `mix hex.publish --yes` -> `mix verify.release_publish` -> `mix verify.release_parity`.
4. After the workflow finishes, confirm the release artifacts:

   ```bash
   git fetch --tags origin
   git tag --sort=version:refname | tail -n 5
   gh run view --log
   ```

   The publish job now runs `mix verify.release_publish X.Y.Z` for the newly released version, so Hex package visibility, clean-consumer compile, and versioned HexDocs reachability are checked inside the workflow instead of by hand. As a post-publish follow-on, it then runs `mix verify.release_parity X.Y.Z` with the same retry environment variables so tarball contents stay aligned with the git tag.

5. If the workflow passes, treat the release contract as satisfied. Manual spot-checks are optional, not required.

## PR semantics on the train

Because Scrypath uses squash merges and Release Please reads the merged commit history, maintainers should treat the PR title as the release-driving commit message.

- Use **`fix:`** for ordinary patch-train work.
- Use **`feat:`** only when you intentionally want feature-language in the release notes.
- Use **breaking-change semantics** (`!` or `BREAKING CHANGE`) only for explicit major-version planning.
- Avoid vague PR titles that would create noisy or misleading release notes.

## Website deploy and rollback

The website in `website/` is published to `https://sztheory.github.io/scrypath/` by `.github/workflows/website.yml`. This is separate from the Hex release flow above: merging a website change publishes the site, never a package.

**What deploys.** A push to `main` that touches `website/**`, `brand/**`, `README.md`, `guides/**`, `docs/**`, `mix.exs` or the workflow file builds the site, runs `build-and-check` (the static contract and the browser checks) and then deploys it. Pull requests use the same path list, so a brand change is built and checked before it merges.

**Concurrency.** Only a superseded pull request run is cancelled. A push to `main` waits for a run that is already going instead of cutting it off, so a deploy that has started always finishes; if several pushes queue up, the newest one runs next and deploys the newest content. A rollback dispatch runs in its own group, so a push does not cancel it. The deploy job also has its own group, `website-pages-deploy`, with `cancel-in-progress: false`, which keeps two deploys from running at once. A rollback stays in place only until the next push that matches the path filter: that push deploys `main` again, so revert the bad commit on `main` as well.

**Smoke step.** The last step of the deploy job runs `node website/scripts/smoke.mjs` against the live page URL. It checks that the home page answers 200, that the ui font answers 200 as `font/woff2` with the sha256 pinned in `brand/brand.pin.json`, that both lockups load, that the social card is the pinned PNG, that `favicon.ico` answers, and that every asset URL the page declares stays under `/scrypath/`. Requests carry a `?smoke=` query so the edge cache (Pages answers `max-age=600`) cannot hide a bad deploy, and a request is retried (three tries, ten seconds apart) only for a network error, a 404 or a 5xx, which is what propagation right after a deploy looks like. A red smoke means roll back, not retry.

**Rollback.** Redeploy the last good commit with a manual run:

```bash
gh workflow run website.yml --ref main -f ref=<commit-sha>
```

The `deploy` job runs only when the workflow itself runs on `main` (a condition on the job, not a repository setting), so dispatch with `--ref main` and let `ref` name the commit to redeploy (a commit, tag or branch). A dispatch from any other branch builds and checks but does not deploy. The input is used only as the checkout ref and is never part of a shell command. Prefer this to a retry loop and to a revert PR, which takes 5 to 15 minutes. The browser step in `build-and-check` takes the runner's Chrome only when the checked-out ref's `website/scripts/check.mjs` reads `SCRYPATH_BROWSER_CHANNEL`; an older ref gets Playwright's own Chromium installed instead, so its checks can launch and the rollback is not stopped at the browser step. A rollback to a commit that predates the smoke script runs only a soft check, `curl -fsSI` on the home page and the stylesheet, so a green run means the old site answers at both URLs; the manual confirmation is the same two calls, `curl -I https://sztheory.github.io/scrypath/` and `curl -I https://sztheory.github.io/scrypath/assets/styles.css`.

**Exact-head evidence for a website PR.** Before the squash merge, confirm the check ran on the head you are merging:

```bash
gh api repos/szTheory/scrypath/commits/<head>/check-runs
```

Read `build-and-check` as completed with conclusion `success` and `head_sha` equal to the PR head, next to the required contexts on the same head.

**`build-and-check` is not a required check.** It is a browser job whose runs take about 47 to 64 seconds, with a timeout (10 minutes) that bounds its slow tail; branch protection is a maintainer setting; and `deploy` needs `build-and-check`, so a red check stops the deploy after the merge. Re-open this when a rendering regression that only this job would have caught reaches `main`: it then becomes a required gate, with a deletion trigger and its expected churn recorded in the ledger in `CONTRIBUTING.md`.

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
mix verify.package
   HEX_API_KEY=... mix hex.publish --dry-run --yes
   ```

2. If the dry run fails, fix the packaging or docs issue on the release branch input, merge the correction, and let Release Please cut the next proper release PR.
3. If the dry run passes and `mix hex.info scrypath` does not show `X.Y.Z`, rerun the existing checks from the same reviewed ref with the manual recovery workflow:

   - open `.github/workflows/publish-hex.yml`
   - set `tag` to the reviewed release tag or commit ref
   - set `release_version` to `X.Y.Z`

   That workflow reruns `mix verify.package`, `mix hex.publish --dry-run --yes`, `mix hex.publish --yes`, and `mix verify.release_publish X.Y.Z` from the explicit ref, then mirrors the canonical path with `mix verify.release_parity X.Y.Z` using the same retry environment variables.

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
mix verify.package
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
