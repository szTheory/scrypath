# Releasing Scrypath

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
4. After the workflow finishes, confirm the release artifacts:

   ```bash
   git fetch --tags origin
   git tag --sort=version:refname | tail -n 5
   mix hex.info scrypath
   curl -Ifs https://hexdocs.pm/scrypath/X.Y.Z
   ```

5. Run the public manual smoke path from a throwaway app:

   ```bash
   mix new scrypath_consumer --module ScrypathConsumer
   ```

   Update `scrypath_consumer/mix.exs` to include:

   ```elixir
   defp deps do
     [
       {:ecto, "~> 3.13"},
       {:scrypath, "~> X.Y.Z"}
     ]
   end
   ```

   Add the documented quick-path schema:

   ```elixir
   defmodule ScrypathConsumer.Post do
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

   Then prove the clean install and docs path:

   ```bash
   cd scrypath_consumer
   mix deps.get
   mix compile
   curl -Ifs https://hexdocs.pm/scrypath/X.Y.Z
   ```

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
3. If the dry run passes and `mix hex.info scrypath` does not show `X.Y.Z`, rerun the existing publish step from the same tag:

   ```bash
   HEX_API_KEY=... mix hex.publish --yes
   ```

4. After a successful publish, rerun the manual clean-consumer smoke path and confirm `https://hexdocs.pm/scrypath/X.Y.Z` is reachable.

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

   After the revert, fix the repo state, let Release Please open the next versioned PR, merge it, and rerun the canonical release flow plus the manual clean-consumer smoke path.
