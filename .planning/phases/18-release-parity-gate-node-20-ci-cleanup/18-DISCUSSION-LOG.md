# Phase 18: Release-Parity Gate + Node 20 CI Cleanup - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-17
**Phase:** 18-release-parity-gate-node-20-ci-cleanup
**Areas discussed:** Workspace-clean scope, Release-parity diff algorithm, Workflow wiring, Known-divergence transition handling
**Mode:** Deep advisor research (user requested parallel subagent research across all four areas with a one-shot coherent recommendation)

---

## Area 1: Workspace-clean scope

Research prompt asked for tradeoffs across: path-glob vs full `git status --porcelain`, HEAD-vs-origin check, escape hatches, generated-artifact handling, test/ inclusion, error-message UX. Advisor referenced `expublish` (Elixir), `cargo publish --allow-dirty` (cautionary), and confirmed `mix hex.publish` performs no git checks.

| Option | Description | Selected |
|--------|-------------|----------|
| A. Literal INFRA-01 | Path-globbed to `lib/**`, `test/**`, `guides/**`, `docs/**`; no HEAD check; no escape hatch. Matches requirement verbatim but misses `mix.exs`/`CHANGELOG.md` drift. | |
| B. Packaged-files scope | Pathspecs derived from `mix.exs` `files:` list + `test/**`; no HEAD check; no escape hatch. Self-maintaining, covers the actual invariant. | ✓ |
| C. Strict (PITFALLS literal) | Any non-empty `git status --porcelain` + HEAD-must-equal-origin/main (fast-forward OK); no escape hatch. Maximum safety, high false-positive rate on `.planning/` churn. | |
| D. Strict with env-var escape | Option C plus `SCRYPATH_WORKSPACE_CLEAN_SKIP=1` bypass. Escape hatches get normalized under release pressure (rust-lang/cargo#9398). | |

**Decision:** Option B. Rationale: derives the gate from `mix.exs` `files:` so it's self-maintaining, catches `mix.exs` + `CHANGELOG.md` drift that path-globbing `lib/** guides/** docs/**` would miss, ignores `.planning/` / workflow YAML / `priv/plts/` naturally, matches the operational-honesty/principle-of-least-surprise posture, and avoids the bypass-normalization failure mode that Option D would invite.

**Notes:** Advisor explicitly called out that `test/**` is included despite not shipping because "uncommitted tests mean lib/ wasn't tested as it will ship" — semantic alignment with Scrypath's operational-honesty stance. The `expublish` `System.cmd("git", ["status", "--porcelain"])` pattern was copied; its `--allow-untracked` flag was rejected.

---

## Area 2: Release-parity diff algorithm

Research prompt asked for tradeoffs across Hex-tarball acquisition strategy, git-tag-side acquisition, comparison depth, divergence semantics, exit codes, output UX, phase scope subset, and scheduled-daily drift surfacing. Advisor referenced `check-manifest` (Python), `mix hex.package fetch`, and `hex_core`.

| Option | Description | Selected |
|--------|-------------|----------|
| A. `mix hex.package fetch --unpack` + path-set diff | Canonical Hex CLI does download + checksum verify + unpack; auth-free for public packages; path-only equality on lib/+guides/+docs/. | ✓ |
| B. `Req.get!` raw tarball + `:hex_tarball.unpack/2` + path+SHA256 | Defense-in-depth including content drift; uses `hex_core` transitive dep. | |
| C. Hex API JSON + checksum compare | Smallest network payload; no extraction; API shape less stable than tarball format. | |
| D. `mix hex.build --unpack` at current checkout | Zero network but circular — rebuilds what we'd ship, doesn't validate against Hex. | |

**Decision:** Option A. Rationale: Hex CLI is the canonical primitive for this exact job (auth-free, handles checksums internally); path-only equality perfectly catches the v1.2 "missing files" incident class; `git archive` at a tag and `mix hex.build` at the same commit produce byte-equal files because they read the same locked git tree, making hash-depth comparison mostly redundant for the actual failure mode. Ship A now; upgrade to B is a ~20-line additive change if a hash-drift incident ever appears.

**Sub-decisions captured:**
- Scope restricted to `lib/ + guides/ + docs/` per INFRA-02 literal (not full `files:` list)
- Exit codes: 0/2/1 (parity/drift/runtime-error) per POSIX conventions
- Output: human-readable default with diff-both-directions, `--json` flag for machine use
- CDN race: inherit `SCRYPATH_RELEASE_VERIFY_ATTEMPTS` / `SLEEP_MS` retry idiom
- Daily drift surfacing: `JasonEtco/create-an-issue@v2` with deduplicating title

**Notes:** Advisor explicitly rejected Option D (the current `verify.phase11` shell-out pattern for tarball build) as circular. The `check-manifest` output shape was copied but its `-u` auto-suggest was rejected.

---

## Area 3: Workflow wiring

Research prompt asked for tradeoffs across INFRA-01's literal "publish-hex.yml" vs both publish paths, INFRA-04's CI-on-every-push wiring, daily parity check extend-vs-new-workflow, daily failure surfacing, interactions with release-please.yml, and escape-hatch propagation. Advisor referenced Bandit, Req, Oban release workflows.

| Option | Description | Selected |
|--------|-------------|----------|
| A. Literal INFRA-01 (recovery-only gate) + new parity workflow | Matches requirement text; leaves canonical release-please path less guarded than emergency recovery — exactly the v1.2 failure shape. | |
| B. Gate BOTH publish paths + extend verify-published-release.yml + workspace_clean in ci.yml quality | Symmetric protection; honors Phase 11 separation-of-concerns; matches Elixir OSS idioms; 4 files touched, all additive. | ✓ |
| C. New dedicated workspace-clean job in ci.yml (parallel to quality) | Fastest feedback but setup-beam overhead dwarfs the 10ms check. | |
| D. Single mega publish-gate workflow (workflow_call) | Over-engineered; rewires canonical release flow in a gate-only phase. | |

**Decision:** Option B. Rationale: gating only the recovery path means emergency lane has more protection than canonical daily lane — backwards. Phase 11's "one verification workflow" principle argues for extending `verify-published-release.yml`, not forking. All reference repos (Bandit, Req, Oban) colocate gates inside the workflow that does the thing, not in gate-only sibling workflows.

**Sub-decisions captured (wiring matrix):**
- `ci.yml` quality job: +workspace_clean step (after format, before credo)
- `release-please.yml` publish-hex job: +workspace_clean (after tag checkout, before verify.phase11)
- `publish-hex.yml` (manual recovery): +workspace_clean (same position as canonical)
- `verify-published-release.yml`: +release_parity step (after existing verify.release_publish); +`create-an-issue` step guarded on `failure() && event_name == 'schedule'`
- No new workflow files
- No env-var escape hatch propagation into any workflow

**Notes:** Advisor explicitly noted `git status --porcelain` is always clean in CI on fresh-checkout runners, making the publish-job gates cheap invariant assertions rather than real gates — the real teeth are in the `ci.yml` push gate and local pre-commit. That's intentional and correct.

---

## Area 4: Known-divergence transition handling

Research prompt asked for bootstrap behavior when no v1.3 release exists yet, whether Phase 18 itself cuts 0.4.0, handling of legit 0.3.0 path-list mismatches if any exist, future-version-bump interactions, and docs/CHANGELOG communication. Advisor was asked to empirically verify whether `git ls-tree scrypath-v0.3.0` matches the Hex 0.3.0 tarball.

**CRITICAL empirical finding:** Advisor confirmed that `git ls-tree -r scrypath-v0.3.0 -- lib/ guides/ docs/` and the live Hex 0.3.0 tarball both resolve from commit `d642036` and agree. The v1.2 divergence is tag-vs-`main` (17 files), NOT tag-vs-Hex. `mix verify.release_parity 0.3.0` passes today, exit 0, no special-casing.

| Option | Description | Selected |
|--------|-------------|----------|
| A. No bootstrap gate + Phase 18 cuts 0.4.0 | Empirically clean; no allowlist debt; closes v1.2 gap immediately; feature phases inherit aligned baseline. | ✓ |
| B. Allowlist `SCRYPATH_RELEASE_PARITY_MIN_VERSION=0.4.0` + cut 0.4.0 | Defensive; survives hidden mismatches; grandfather anti-pattern per cargo-audit/bundler-audit idioms. | |
| C. No bootstrap gate + Phase 18 ships tooling only, next release cuts naturally | Smaller diff; leaves v1.2 divergence open through Phase 19+; contradicts Phase 18's mission. | |
| D. Skip-allowlist `[0.3.0]` literal + cut 0.4.0 | Textbook grandfather anti-pattern; zero defensive value since 0.3.0 already passes. | |

**Decision:** Option A. Rationale: release_parity catches tarball-vs-tag drift (scenarios B/C from the brief); workspace_clean catches tag-vs-main drift at publish time. Because 0.3.0 tag and Hex tarball agree, release_parity is already green — no bootstrap logic needed. Phase 17 already performed the one-time reconciliation; Phase 18's role is prevention, not re-reconciliation. Grandfather allowlists solve a problem that doesn't exist here and carry decay debt forward.

**Sub-decisions captured:**
- Phase 18 closing commit is a `feat(18):` Conventional Commit
- Release-please auto-cuts `0.4.0`; merging re-aligns Hex with `main` in the same cycle
- `docs/releasing.md` gets a new "Release parity gate" section explaining both gates' invariants + v1.2 historical note
- `CHANGELOG.md` unreleased entry references v1.2 audit for traceability
- Daily cron gracefully no-ops on 0.3.0 until 0.4.0 ships; then tracks 0.4.0

**Notes:** Advisor copied Phoenix/Ecto's "cut release at milestone close via feat commit" pattern and release-please's `bootstrap-sha`-as-commit (not version floor) idea. Rejected grandfather-allowlist patterns from cargo-audit as solving the wrong problem for Scrypath's situation.

---

## Claude's Discretion

Delegated to the planner/executor:
- Exact `Mix.raise/1` copy phrasing (should match Scrypath's error-message tone from `lib/scrypath/options.ex`)
- Tmp-dir naming for `hex.package fetch --unpack` output
- JSON field ordering in `release_parity --json` output (fields named, ordering stable)
- `create-an-issue` labels and assignees
- Test-file layout for both new tasks

## Deferred Ideas

- SHA-256 hash comparison for release_parity — revisit only if a real post-tag mutation incident occurs
- Emergency-publish escape hatch for workspace_clean — revisit only with a structural anti-normalization mechanism
- Extracting a shared `Mix.Tasks.Verify.Helpers` module — defer until a third `verify.*` task needs the same helpers
- Per-phase SUMMARY manifest convention for release_parity — superseded by `git ls-tree` comparison
