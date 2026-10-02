# Phase 168: Dependency Security and Reliable Verification - Pattern Map

**Mapped:** 2026-09-28
**Files classified:** 18 likely implementation/evidence files (15 existing, 3 proposed)
**Analog coverage:** 16 / 18 have an exact or role match; 2 have only partial patterns

This map follows D-01–D-06 in CONTEXT.md and the supplied RESEARCH.md. Proposed names below are planning choices, not existing files or mandatory module boundaries. Existing files can generally extend their own patterns. Five principal reusable anchors are the package harness, package harness tests, capability dispatcher, mounted entrypoint, and CI monitor. Supporting files are existing change targets and policy references; no broader analog hunt is needed.

## File Classification

| New/Modified File | Status | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|---|
| `mix.lock` | Existing | config | transform | Same file; HPAX line 20, Mint line 26 | exact |
| `examples/phoenix_meilisearch/mix.lock` | Existing | config | transform | Same file; lines 9, 12 | exact |
| `examples/scrypath_ecommerce/mix.lock` | Existing | config | transform | Same file; lines 18, 23 | exact |
| `scrypath_ops/mix.lock` | Existing | config | transform | Same file; lines 26, 31 | exact |
| `lib/mix/tasks/verify/phoenix_example/package.ex` | Existing | utility | file-I/O, batch | Same file | exact |
| `lib/mix/tasks/verify.adopter.ex` | Existing | utility | batch | Same file, plus package harness runner | exact |
| `test/mix/tasks/verify_phoenix_example_package_test.exs` | Existing | test | file-I/O, batch | Same file | exact |
| `test/mix/tasks/verify_adopter_test.exs` | Existing | test | batch | Same file, plus package harness tests | exact |
| `lib/mix/tasks/verify/capability.ex` | Existing | utility | batch | Same file | exact |
| `lib/mix/tasks/verify/deep_quality.ex` | Existing; conditional edit if wrapper changes | utility | batch | Same file | exact |
| `test/mix/tasks/verify_capability_test.exs` | Existing | test | batch | Same file | exact |
| `.github/workflows/ci.yml` | Existing | config | event-driven, batch | Same file, advisory lane | exact |
| `test/mix/tasks/workflow_wiring_test.exs` | Existing | test | file-I/O | Same file | exact |
| `examples/scrypath_ecommerce/docker-e2e-entrypoint.sh` | Existing; local patch present | utility | batch | Same file | exact |
| `test/scrypath/phase147_e2e_contract_test.exs` | Existing; local patch present | test | file-I/O | Same file | exact |
| `scripts/ci/dependency_audit.exs` | Proposed new name | utility | batch, file-I/O | Capability subprocess pattern and package runner injection | partial: no four-graph orchestrator |
| `test/mix/tasks/dependency_audit_test.exs` | Proposed new name | test | batch, file-I/O | Package harness tests | role-match |
| `.planning/phases/168-dependency-security-and-reliable-verification/168-DELIVERY.md` | Proposed new receipt | config (evidence document) | batch | `scripts/ci_monitor.cjs` exact-SHA output | partial: output schema, not document template |

No direct Mint dependency declaration, UI component, new required job, service matrix, or version bump is implied. Manifests remain inspection surfaces unless the resolver demonstrates an actual compatibility blocker. A reusable literal-lock helper may be extracted from the package module if useful; its filename and separate test are not established upstream and are deliberately not invented as existing files here.

## Pattern Assignments

### Four maintained `mix.lock` files (config, transform)

**Analog:** each existing tracked lock is its own authoritative generated format. Do not transplant the root lock into another project or edit tuple checksums manually. Each project's resolver owns its graph.

Concrete full tuple example, `mix.lock:20`:

```elixir
"hpax": {:hex, :hpax, "1.1.0", "782931867cc23217c68fb5f68fe1a11f5e7544c7fda82c8a7019a5df5a4a1cdf", [:mix], [], "hexpm", "0b8d0f05832f55571d65ac720f79bf8994138ffbb133209dc4685eae0ad456a8"},
```

Observed Mint versions: root 1.10.1; Phoenix, ecommerce, and Ops 1.9.3. Root HPAX is 1.1.0; the other graphs have 1.0.4. These are preimplementation observations, not targets to copy. Follow research's targeted `mix deps.update mint` recommendation separately in each graph after refreshing advisory facts. Inspect the generated closure; no runtime compatibility is established by this map.

Validation belongs to the audit inventory and behavior proofs below. Semantic proof must retain the whole Hex tuple, including dependencies, checksums and repository, rather than compare version strings alone.

### Package proof: `lib/mix/tasks/verify/phoenix_example/package.ex`

**Analog:** same module. No imports are required; the module uses fully qualified standard-library/Mix calls and `@moduledoc false` (lines 1–5). Injection rather than service startup makes focused tests possible.

**Runner and prerequisite seam, lines 10–14:**

```elixir
service_check =
  Keyword.get(opts, :service_check, &Mix.Tasks.Verify.Adopter.ensure_live_prerequisites!/0)

command_runner = Keyword.get(opts, :command_runner, &System.cmd/3)
keep_on_failure? = Keyword.get(opts, :keep_temp_on_failure, false)
```

**Resolution boundary, lines 87–90:**

```elixir
isolated = [{"HEX_HOME", hex_home}, {"MIX_HOME", mix_home}]
Mix.shell().info("==> package proof: resolving staged dependencies")
invoke!(runner, :dependency, "mix", ["deps.get"], cd: consumer, env: isolated)
lock = File.read!(Path.join(consumer, "mix.lock"))
```

Capture the source lock before this call. Compare source/resolved semantic Hex entries after it and before compilation at line 103. Allow only the expected Scrypath provenance substitution; retain the independent tagged-artifact check. Print safe graph identity and hashes before workspace cleanup.

**Literal parsing seam, lines 125–136:**

```elixir
with {:ok, {:%{}, _meta, entries}} <- Code.string_to_quoted(lock),
     {:{}, _tuple_meta, [:git, ^expected_url, _revision, options | _rest]} <-
       Enum.find_value(entries, fn
         {"scrypath", value} -> value
         {:scrypath, value} -> value
         _ -> nil
       end),
     true <- Enum.any?(options, &match?({:tag, ^expected_tag}, &1)) do
  true
else
  _ -> false
end
```

This is a provenance predicate, not an existing graph comparator. Extend literal decoding with explicit allowed forms, normalized atom/string keys, duplicate detection and malformed-input rejection. Do not evaluate lock expressions. Test changes to key sets, source types and complete tuple contents, including checksum-only drift.

**Errors, lines 167–173:**

```elixir
defp invoke!(runner, stage, command, args, opts) do
  Mix.shell().info("==> package proof [#{stage}]: #{command} #{Enum.join(args, " ")}")
  {output, status} = runner.(command, args, Keyword.merge([stderr_to_stdout: true], opts))
  safe_output = redact(output)
  if safe_output != "", do: Mix.shell().info(safe_output)
  if status != 0, do: fail!(stage, "#{command} #{Enum.join(args, " ")} exited #{status}")
  :ok
```

Preserve stage-specific `Mix.Error`, redaction, and `after` cleanup. Do not emit a graph success marker after a fetch error.

### Live path proof: `lib/mix/tasks/verify.adopter.ex`

**Analog:** its own preflight and package harness runner. Module conventions are `use Mix.Task`, `@shortdoc`, and `@impl true` (lines 1–4, 51–52).

**Existing command/error seam, lines 87–96:**

```elixir
script = "printf 'n\\n' | mix deps.get && mix test"

{out, status} =
  System.cmd("bash", ["-lc", script], cd: example_dir, stderr_to_stdout: true)

Mix.shell().info(out)

if status != 0 do
  Mix.raise("verify.adopter failed: `#{script}` (in #{example_dir}) exited #{status}")
end
```

Split fetch and tests as needed to establish the lock-preservation postcondition and print resolved identity between them. Preserve `ensure_live_prerequisites!/0` and explicit failure when services are unavailable. Unlike first package staging, path-mode fetch permits `--check-locked`; byte preservation is appropriate here. Reuse the package runner-injection pattern if adding a service-free execution seam.

### Phoenix proof tests: both existing package/adopter test files

**Primary analog:** `test/mix/tasks/verify_phoenix_example_package_test.exs:1–4`:

```elixir
defmodule Mix.Tasks.Verify.PhoenixExample.PackageTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO
```

**Injected failure and cleanup, lines 65–81:**

```elixir
runner = fn "mix", ["hex.build", "--unpack", "--output", artifact], _opts ->
  Process.put(:package_test_root, Path.dirname(artifact))
  {"artifact failed", 17}
end
```

The surrounding test calls `Package.run(service_check: fn -> :ok end, command_runner: runner)`, asserts a stage-specific `Mix.Error`, then uses `refute File.exists?(root)` (lines 71–81). Reuse this for failure-before-compile and cleanup evidence.

**Existing test weakness to replace, lines 101–105:**

```elixir
artifact = Path.join(Process.get(root_key), "artifact")
artifact_url = "file://#{Path.expand(artifact)}"
tag = "v#{Mix.Project.config()[:version]}"
lock = ~s|%{"scrypath" => {:git, "#{artifact_url}", "abc123", [tag: "#{tag}"]}}|
File.write!(Path.join(opts[:cd], "mix.lock"), lock)
```

The fake success resolver discards all Hex entries. Preserve the staged Hex graph in success fixtures, then deliberately mutate it in negative fixtures. Include ordering assertions so compilation/testing cannot run after graph failure. The existing later-stage loop (84–142) covers cleanup after dependency, compile and test failures and should continue exercising those actual stages after the fixture is corrected.

For `test/mix/tasks/verify_adopter_test.exs`, retain its `async: false`, `CaptureIO`, and environment restoration in `on_exit` (lines 1–4, 30–42). Existing prerequisite tests do not prove post-fetch identity; add focused runner behavior using the package pattern.

### Advisory capability and wrapper

**Files:** `lib/mix/tasks/verify/capability.ex`, conditional `lib/mix/tasks/verify/deep_quality.ex`, and `test/mix/tasks/verify_capability_test.exs`.

**Existing root audit ownership, capability lines 67–72:**

```elixir
defp deep_quality!([]) do
  run_task!("verify.no_optional_deps", [])
  Mix.Task.run("scrypath.namespace_fence")
  run_mix_command!("hex.audit", [])
  run_mix_command!("dialyzer", [])
  :ok
```

Introduce a narrow internal non-audit quality seam for repository orchestration while preserving the standalone task's audit behavior. Do not put four project paths in this shipped module. Do not add an undocumented public flag solely to evade a second root scan.

**Fresh subprocess, capability lines 119–126:**

```elixir
defp run_mix_command!(task, args) do
  mix = System.find_executable("mix") || Mix.raise("could not find the mix executable")

  {output, status} =
    System.cmd(mix, [task | args],
      env: [{"MIX_ENV", Atom.to_string(Mix.env())}],
      stderr_to_stdout: true
    )
```

The method prints output and raises on nonzero status (128–132). This is the process-isolation pattern to reuse, but its fail-fast behavior must become per-graph aggregation in the new audit script.

**Thin wrapper, `lib/mix/tasks/verify/deep_quality.ex:1–7`:**

```elixir
defmodule Mix.Tasks.Verify.DeepQuality do
  @moduledoc "Runs the canonical advisory static-analysis capability."
  use Mix.Task
  @shortdoc "Runs canonical deep-quality verification"
  @impl true
  def run(args), do: Mix.Tasks.Verify.Capability.run(:deep_quality, args)
end
```

Prefer keeping this wrapper unchanged if the internal helper suffices. Capability tests already assert rejection of stray arguments before dispatch (15–21); retain that boundary and add meaningful single-root-audit/default-behavior coverage.

### Proposed repository audit and tests

**Candidate:** `scripts/ci/dependency_audit.exs`; **candidate tests:** `test/mix/tasks/dependency_audit_test.exs`. Neither path existed in discovery. The script role matches repository tooling; the all-graph security contract has no complete existing analog.

Copy subprocess mechanics from capability lines 119–132, runner injection from package lines 10–14, and failure fixtures from package tests lines 65–81. Use an explicit inventory of `.`, `examples/phoenix_meilisearch`, `examples/scrypath_ecommerce`, and `scrypath_ops`. Keep inventory ownership in one place and compare derived lock paths to NUL-delimited tracked Git inventory, not recursive filesystem discovery.

Required new behavior from research: reject duplicate inventory entries, missing manifest/lock, and unexpected tracked Mix locks; preserve source lock bytes around fetching/auditing; report fetch and audit timing separately; report active and ignored findings; treat unavailable, ignored or incomplete audits as non-clean; attempt remaining graphs after failure; return aggregate failure. Avoid shell-interpolated project paths. Each Mix audit runs in its own project subprocess. Reuse official Hex matching, with supported output-contract fixtures if parsing ignored findings.

The test analog supplies injection and cleanup, not audit semantics. New fixtures should prove all four attempted, one root scan, missing tools, fetch failure, audit nonzero, ignored-result success exit, lock mutation, missing inventory members and a clean complete result. Wire recurring tests into an existing lane. No execution or cost measurement was performed during mapping.

### Existing CI lane and workflow regression

**Files/analogs:** `.github/workflows/ci.yml` advisory block at 134–150 and `test/mix/tasks/workflow_wiring_test.exs`. Use the established `deep-quality (advisory)` job and its setup/cache context; replace its orchestration point rather than adding a required job. Existing Phoenix and Ops selection are at 153–195 in the researched source. Preserve their event/path semantics unless a concrete coverage change is required by the plan.

**Workflow test extraction pattern, `test/mix/tasks/workflow_wiring_test.exs:11–16`:**

```elixir
test "ci.yml core job runs the canonical gate, which includes workspace cleanliness" do
  ci = File.read!(@ci_yml)
  core_job = workflow_job_block(ci, "core")

  assert core_job =~ "mix verify.core"
  assert File.read!(@verify_task) =~ ~s|Mix.Task.run("verify.workspace_clean")|
```

Reuse `workflow_job_block/2` to constrain checks to deep quality. Assert one inventory owner and retained quality checks; a global substring assertion can pass because an unrelated job contains the command. Test runner invocation behavior separately from YAML wiring. Existing Ops fixture asserts Postgres service configuration in its own job (358–369); no new Ops UI work is implied.

### Mounted entrypoint and focused regression

**Analog:** each target's current local working-tree content. Both paths are tracked, but the corrective lines are uncommitted; they must be selected onto the clean delivery branch, not assumed present on public main.

**`examples/scrypath_ecommerce/docker-e2e-entrypoint.sh:17–18,33–37`:**

```sh
echo "Preparing the deterministic database and search indexes..."
PHX_SERVER=false mix e2e.prepare
```

```sh
echo "Seeding deterministic ecommerce/operator scenarios..."
PHX_SERVER=false mix scrypath.demo.seed

echo "Starting the persistent E2E server..."
exec env SCRYPATH_E2E_NO_SANDBOX=1 mix phx.server
```

Retain command-local environment ownership and final `exec`. The file uses POSIX `sh` and `set -eu` (1–3); failures must stop startup. Do not mask transient readiness with longer timeouts.

**`test/scrypath/phase147_e2e_contract_test.exs:50–52`:**

```elixir
assert @entrypoint =~ "PHX_SERVER=false mix e2e.prepare"
assert @entrypoint =~ "PHX_SERVER=false mix scrypath.demo.seed"
assert @entrypoint =~ "exec env SCRYPATH_E2E_NO_SANDBOX=1 mix phx.server"
```

The module uses `async: true`, a phase tag, and file attributes (1–15). Its browser assertions require `ready_count >= 3` and finite curl probes (40–42). Pair this cheap regression with the existing `mix verify.ecommerce_mounted` behavioral capability. Static assertions alone are not delivery evidence.

### Delivery evidence and workspace setup

**Candidate artifact:** `168-DELIVERY.md` in this phase directory. **Tracked source analog:** `scripts/ci_monitor.cjs`; reuse this tool, with no assumed code modification.

**Imports/process convention, monitor lines 3–9:**

```javascript
"use strict";

const { spawnSync } = require("node:child_process");
const fs = require("node:fs");

const GH = process.env.GH_BIN || "gh";
const GIT = process.env.GIT_BIN || "git";
```

**Exact remote identity, lines 158–162:**

```javascript
const remoteLine = output(GIT, ["ls-remote", "--heads", "origin", `refs/heads/${branch}`]);
const remoteSha = remoteLine.split(/\s+/)[0] || "";
if (remoteSha !== sha) {
  throw new Error(`origin/${branch} is ${remoteSha || "missing"}, expected ${sha}; rerun with --push`);
}
```

**Run selection, lines 168–171:**

```javascript
while (Date.now() <= deadline) {
  selected = listRuns(branch).find(
    (item) => item.headSha === sha && !beforeIds.has(item.databaseId),
  );
```

**Completeness, lines 193–197:**

```javascript
for (const name of requiredJobs) {
  const matches = jobs.filter((job) => job.name === name);
  if (matches.length !== 1 || matches[0].conclusion !== "success") {
    throw new Error(`${name} must have exactly one successful job, got ${JSON.stringify(matches)}`);
  }
}
```

The output includes `authority`, repository/workflow/run identity, `head_sha`, event and jobs (211–221); artifact validation requires id, digest and matching source SHA (125–137). Use these fields in receipts. Its required job list (187–191) adds coverage and closeout attestation to required checks; it does not require deep quality, Phoenix advisory, or Ops. Record those named results separately. Ops is not selected by manual closeout; obtain its applicable PR/main run.

No repository source analog implements supported GSD workspace creation. Use the installed supported workspace workflow as required by D-04, then explicitly assert a clean delivery branch starts at freshly fetched public main before transferring selected changes. A worktree path alone proves neither cleanliness nor base identity. Record base SHA, selected patch, candidate SHA, PR merge-ref SHA, integrated/squash-main SHA, local artifact identity and any published identity separately. Do not use a synthetic package tag as a published-package receipt. A prepared PR or unavailable approval is incomplete delivery.

## Shared Patterns

### Explicit failures and bounded ownership

Apply package `invoke!/5` and capability subprocess conventions to proof stages. Audit differs by collecting failures before exiting. Preserve package cleanup in `after`; deletion is restricted by `remove_owned_root!/1` to a direct temporary-directory child with the expected basename and directory type (package lines 225–235). No new helper should delete a caller-owned checkout.

### Safe output

**Source:** package lines 194–201; **apply to:** graph proof and new audit output.

```elixir
System.get_env()
|> Enum.filter(fn {name, value} ->
  value != "" and
    (String.match?(name, ~r/(TOKEN|PASSWORD|SECRET|KEY|URL)/i) or
       name in ["SCRYPATH_MEILISEARCH_URL"])
end)
|> Enum.reduce(output, fn {_name, value}, acc -> String.replace(acc, value, "[REDACTED]" ) end)
```

The final line above preserves the expression with whitespace normalized. Emit source SHA, mode, safe package/version identities and lock hashes; avoid environment dumps or secret-bearing provenance URLs. Existing redaction is a starting pattern, not a guarantee for every new output field.

### Package boundary and authentication

Repository inventory stays under `scripts/`; the package whitelist in `mix.exs:265–271` ships `lib`. Only reusable proof logic belongs under the existing library verifier tree. This phase creates no new application authentication/authorization path; existing live proof prerequisites are guards for environment/service availability, not user authorization. Preserve real GitHub merge/trust gates.

### Project guidance

AGENTS.md calls for focused PR-first delivery and executable or exact-source evidence. CONTRIBUTING.md and docs/releasing.md are procedure references, not implied documentation rewrites. The consulted ratchet prompt (125–164) favors a small vertical slice, explicit failures and recurring tests whose signal justifies cost. Its guidance takes priority over mechanically broadening CI from older ecosystem suggestions. No project skill directories were found under `.codex/skills` or `.agents/skills`.

## No Analog Found

| File / behavior | Role | Data Flow | Gap and planning action |
|---|---|---|---|
| Proposed `scripts/ci/dependency_audit.exs` complete contract | utility | batch, file-I/O | No existing four-project audit inventory, strict ignored-result aggregation, or omission guard; use RESEARCH.md requirements and the subprocess/injection excerpts above. |
| Proposed `168-DELIVERY.md` receipt | config | batch | CI monitor supplies identity checks/output, not a phase delivery document; record the exact source/run/claim limits explicitly. |
| Semantic complete lock comparison inside package/adopter proof | utility | transform | Existing parser checks only Scrypath provenance; literal decoding, normalization and full graph postconditions require new implementation. |
| Supported clean-base workspace setup | utility | file-I/O | No repository implementation to copy; use supported GSD workflow and explicit base assertion, without naming ignored installed mirrors as source analogs. |

## Metadata

- Analog search scope: tracked verifier modules, verifier tests, scripts, CI workflow, four locks, mounted entrypoint/regression, contributor/release guidance.
- Files inspected for source/pattern extraction: 21 (15 existing change targets, monitor, evidence script, mix.exs, AGENTS.md, CONTRIBUTING.md, docs/releasing.md), plus phase context/research and relevant prompt excerpts. Reads included targeted sections; some large combined command output was truncated, so excerpts above rely on visible source sections.
- All named source analog paths were confirmed by non-empty `git ls-files -- <path>` output through exact or matching scoped pathspecs. No ignored install/runtime mirror is offered as an implementation analog.
- Existing dirty startup files and unrelated planning changes were observed and preserved. No dependency resolution, tests, service starts, CI dispatch, source edit or commit was performed.
- Tool environment exposes shell reads and `apply_patch`, not literal Read/Write tools; those filesystem equivalents were used, writing only this artifact.
- Pattern extraction date: 2026-09-28. Recheck analog line numbers after implementation; refresh mutable advisory/delivery facts at execution time.
