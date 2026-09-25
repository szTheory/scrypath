# Phase 109: Release Train and Package Truth Audit - Pattern Map

**Mapped:** 2026-05-31
**Files analyzed:** 11
**Analogs found:** 11 / 11

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/mix/tasks/verify.phase11.ex` | utility | batch | `lib/mix/tasks/verify.phase10.ex` | exact |
| `test/mix/tasks/workflow_wiring_test.exs` | test | request-response | `test/mix/tasks/workflow_wiring_test.exs` | exact |
| `test/release/package_metadata_test.exs` | test | file-I/O | `test/release/package_metadata_test.exs` | exact |
| `test/release/consumer_smoke_test.exs` | test | batch | `test/release/consumer_smoke_test.exs` | exact |
| `.github/workflows/release-please.yml` | config | event-driven | `.github/workflows/release-please.yml` | exact |
| `.github/workflows/publish-hex.yml` | config | event-driven | `.github/workflows/publish-hex.yml` | exact |
| `.github/workflows/verify-published-release.yml` | config | event-driven | `.github/workflows/verify-published-release.yml` | exact |
| `docs/releasing.md` | config | request-response | `docs/releasing.md` | exact |
| `mix.exs` | config | transform | `mix.exs` | exact |
| `release-please-config.json` | config | transform | `release-please-config.json` | exact |
| `.release-please-manifest.json` | config | transform | `.release-please-manifest.json` | exact |

## Pattern Assignments

### `lib/mix/tasks/verify.phase11.ex` (utility, batch)
**Analog:** `lib/mix/tasks/verify.phase11.ex`

**Task structure + deterministic gate flow** (lines 15-35):
```elixir
def run(args) do
  Mix.Task.run("app.start")
  ensure_no_args!(args)
  run_test!([...], "Release contract tests")
  Mix.Task.reenable("docs")
  Mix.Task.run("docs", ["--warnings-as-errors"])
  validate_release_contract!()
  run_command!(["hex.build", "--unpack"], "Building and unpacking Hex package")
end
```

**Workflow contract assertions pattern** (lines 46-118):
```elixir
run_system_command!("grep", ["-nF", "config-file: release-please-config.json", ".github/workflows/release-please.yml"], ...)
run_system_command!("grep", ["-nF", "manifest-file: .release-please-manifest.json", ".github/workflows/release-please.yml"], ...)
run_system_command!("grep", ["-nF", "run: mix verify.phase11", ".github/workflows/release-please.yml"], ...)
run_system_command!("grep", ["-nF", "run: mix hex.publish --dry-run --yes", ".github/workflows/release-please.yml"], ...)
run_system_command!("grep", ["-nF", "run: mix verify.release_publish \"${{ needs.release-please.outputs.version }}\"", ".github/workflows/release-please.yml"], ...)
```

**Agreement check shell block pattern** (lines 120-137):
```elixir
run_system_command!("sh", ["-c", ~S"""
VERSION=$(grep -m1 '@version "' mix.exs | sed -E 's/.*"([^"]+)".*/\1/')
MANIFEST_VERSION=$(grep -m1 '"\."' .release-please-manifest.json | sed -E 's/.*"([^"]+)".*/\1/')
test "$VERSION" = "$MANIFEST_VERSION"
"""], "release-please-manifest version alignment")
```

### `test/mix/tasks/workflow_wiring_test.exs` (test, request-response)
**Analog:** `test/mix/tasks/workflow_wiring_test.exs`

**File constants + read/assert style** (lines 4-8, 30-50):
```elixir
@publish_hex_yml ".github/workflows/publish-hex.yml"
@release_please_yml ".github/workflows/release-please.yml"

yml = File.read!(@release_please_yml)
assert yml =~ "mix verify.release_parity"
{idx_pub, _} = :binary.match(yml, "mix verify.release_publish")
{idx_par, _} = :binary.match(yml, "mix verify.release_parity")
assert idx_pub < idx_par
```

**Semantic JSON config assertions pattern** (lines 280-298):
```elixir
cfg = File.read!("release-please-config.json")
assert cfg =~ ~s("bump-minor-pre-major": true)
manifest_json = File.read!(".release-please-manifest.json")
assert {:ok, %{"." => version}} = Jason.decode(manifest_json)
assert File.read!("mix.exs") =~ ~s(@version "#{version}")
```

### `test/release/package_metadata_test.exs` (test, file-I/O)
**Analog:** `test/release/package_metadata_test.exs`

**Mix project/package/docs metadata checks** (lines 14-33, 35-66):
```elixir
project = MixProject.project()
package = project[:package]
assert "docs/releasing.md" in package[:files]
refute "docs" in package[:files]
assert package[:links] == %{...}

docs = project[:docs]
assert "docs/releasing.md" in docs[:extras]
assert docs[:groups_for_extras][:Maintainers] == [...]
```

### `test/release/consumer_smoke_test.exs` (test, batch)
**Analog:** `test/release/consumer_smoke_test.exs`

**Artifact-first consumer smoke pattern** (lines 23-47, 117-127):
```elixir
build_packaged_artifact!(repo_root, artifact_dir)
artifact_git_url = artifact_dir |> init_artifact_git_repo!(tag) |> then(&"file://#{&1}")
run_mix!(["new", "consumer_usage", "--module", "ConsumerUsage"], cd: tmp_root)
File.write!(Path.join(app_dir, "mix.exs"), consumer_mix_exs(artifact_git_url, tag))
run_mix!(["deps.get"], cd: app_dir, env: isolated_env)
run_mix!(["compile"], cd: app_dir, env: isolated_env)
```

**Hermetic command helper style** (lines 135-151):
```elixir
{output, exit_status} = System.cmd(command, args, cmd_opts)
assert exit_status == 0, """
command failed: #{command} #{Enum.join(args, " ")}
#{output}
"""
```

### `.github/workflows/release-please.yml` (config, event-driven)
**Analog:** `.github/workflows/release-please.yml`

**Canonical release chain** (lines 42-94):
```yaml
if: ${{ needs.release-please.outputs.release_created == 'true' }}
...
ref: ${{ needs.release-please.outputs.tag_name }}
...
run: mix verify.workspace_clean
run: grep -n "@version \"${{ needs.release-please.outputs.version }}\"" mix.exs
run: mix verify.phase11
run: mix hex.publish --dry-run --yes
run: mix hex.publish --yes
run: mix verify.release_publish "${{ needs.release-please.outputs.version }}"
run: mix verify.release_parity "${{ needs.release-please.outputs.version }}"
```

### `.github/workflows/publish-hex.yml` (config, event-driven)
**Analog:** `.github/workflows/publish-hex.yml`

**Manual recovery mirrors canonical path** (lines 38-66):
```yaml
run: grep -n "@version \"${{ inputs.release_version }}\"" mix.exs
run: mix verify.workspace_clean
run: mix verify.phase11
run: mix hex.publish --dry-run --yes
run: mix hex.publish --yes
run: mix verify.release_publish "${{ inputs.release_version }}"
run: mix verify.release_parity "${{ inputs.release_version }}"
```

### `.github/workflows/verify-published-release.yml` (config, event-driven)
**Analog:** `.github/workflows/verify-published-release.yml`

**Published-version resolution + gated checks** (lines 30-60, 80-103):
```yaml
status_code="$(curl -sS -o package.json -w "%{http_code}" https://hex.pm/api/packages/scrypath)"
version="$(jq -r '.latest_stable_version // .latest_version // empty' package.json)"
...
run: mix verify.release_publish "${{ steps.resolve-version.outputs.version }}"
run: mix verify.release_parity "${{ steps.resolve-version.outputs.version }}"
...
if: ${{ failure() && github.event_name == 'schedule' && steps.resolve-version.outputs.published == 'true' }}
uses: JasonEtco/create-an-issue@v2
with:
  update_existing: true
```

### `docs/releasing.md` (config, request-response)
**Analog:** `docs/releasing.md`

**Maintainer contract style: single authority + concrete commands** (lines 21-27, 98-123, 227-266):
```markdown
## Automated Release Gate
mix verify.phase11

## Canonical Release Flow
1. Confirm repo state...
2. Review Release Please PR...
3. Merge; publish job checks out tag and runs verify/dry-run/publish...
4. Confirm artifacts...

## Release parity gate
### `mix verify.workspace_clean`
### `mix verify.release_parity X.Y.Z`
```

### `mix.exs` (config, transform)
**Analog:** `mix.exs`

**Version/source anchor + preferred_envs registration** (lines 4-8, 39-77):
```elixir
@version "0.3.8"
@source_ref "v#{@version}"
...
"verify.phase11": :test,
"verify.release_publish": :test,
"verify.workspace_clean": :test,
"verify.release_parity": :test,
```

**Package whitelist pattern** (lines 234-247):
```elixir
package: [
  files: ~w(lib .formatter.exs mix.exs README.md CONTRIBUTING.md ARCHITECTURE.md CHANGELOG.md LICENSE SECURITY.md guides docs/releasing.md docs/operator-support.md docs/search-backend-sre.md)
]
```

### `release-please-config.json` (config, transform)
**Analog:** `release-please-config.json`

**Manifest-mode and pre-1.0 semantics** (lines 2-13):
```json
"bump-minor-pre-major": true,
"bump-patch-for-minor-pre-major": true,
"release-type": "elixir",
"packages": {
  ".": {
    "changelog-path": "CHANGELOG.md",
    "include-v-in-tag": true
  }
}
```

### `.release-please-manifest.json` (config, transform)
**Analog:** `.release-please-manifest.json`

**Root package pin pattern** (lines 1-3):
```json
{
  ".": "0.3.8"
}
```

## Shared Patterns

### Deterministic Required Gate (auth-free)
**Source:** `lib/mix/tasks/verify.phase11.ex:15-35`
**Apply to:** `verify.phase11` extensions and release-truth tests
- Run focused release tests first, then docs warnings-as-errors, then release contract checks, then `mix hex.build --unpack`.

### Retry Semantics for Live Checks
**Source:** `lib/mix/tasks/verify.release_publish.ex:58-75`, `lib/mix/tasks/verify.release_parity.ex:129-146`
**Apply to:** post-publish and scheduled workflows/tasks only
- Shared retry envelope with `SCRYPATH_RELEASE_VERIFY_ATTEMPTS` and `SCRYPATH_RELEASE_VERIFY_SLEEP_MS`.

### Artifact-First Package Proof
**Source:** `test/release/consumer_smoke_test.exs:23-47`, `lib/mix/tasks/verify.phase11.ex:34`
**Apply to:** REL-02 assertions
- Build/unpack artifact and assert on shipped content/behavior, not only declarations.

### Workflow Wiring Contract Tests
**Source:** `test/mix/tasks/workflow_wiring_test.exs:29-50`, `test/mix/tasks/workflow_wiring_test.exs:280-298`
**Apply to:** release workflow chain order and config agreement checks
- Validate presence and order of `verify.phase11 -> dry-run -> publish -> release_publish -> release_parity`.

### Release Documentation as Canonical Maintainer Surface
**Source:** `docs/releasing.md:98-123`, `docs/releasing.md:227-266`
**Apply to:** release-train docs updates
- Keep one canonical flow with command-level anchors that contract tests can assert.

## No Analog Found

None. All likely Phase 109 surfaces already have direct in-repo analogs.

## Metadata

**Analog search scope:** `lib/mix/tasks`, `test/mix/tasks`, `test/release`, `.github/workflows`, `docs`, repo root config files  
**Files scanned:** 18  
**Pattern extraction date:** 2026-05-31
