# Phase 144: Root HTTP Client Dependency Remediation - Research

**Researched:** 2026-08-22  
**Domain:** Elixir/Mix dependency floors, Req 0.6 compatibility, security evidence  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Phase 144 is an atomic shared Req-floor handoff across all four independent Mix graphs, not a root-only dependency edit. Update the direct Req requirements in root Scrypath, ScrypathOps, and ecommerce together; align the root, legacy example, ScrypathOps, and ecommerce locks in the same valid intermediate state.
- **D-02:** Before execution, correct `.planning/ROADMAP.md` Phase 144 success criterion 4 and `.planning/REQUIREMENTS.md` EVID-02 delivery wording. The truthful boundary is one minimal, explained cross-graph Req compatibility handoff followed by graph-local commits for the remaining legacy, Ops, and ecommerce advisories.
- **D-03:** Use `~> 0.6.1` for each direct Req requirement.
- **D-04:** Change the root test-only Plug requirement from `~> 1.18` to `~> 1.19.5`.
- **D-05:** Refresh only the required Req dependency closure in all four lockfiles; do not add direct Mint/hpax constraints, `override: true`, advisory ignores, or unrelated upgrades.
- **D-06:** The legacy example needs no direct Req declaration; its lock moves only because the root path dependency changes. Later phases own all other graph-local remediation.
- **D-07:** Preserve decoded-JSON successes, tagged HTTP/transport errors, caller `req_options`, API-key headers, and request telemetry meanings.
- **D-08:** Use existing `Req.Test` for causal gaps: retry-disabled transport error, caller option/header merge, unique task-filter query encoding, and error telemetry with no sensitive headers/bodies; reuse current success and wrapper coverage.
- **D-09:** Do not opt into compression, archive decoding, multipart behavior, or changed defaults without a focused compatibility failure.
- **D-10:** Required root gates are fresh fetch, warnings-as-errors compile, fast tests, `mix verify --exclude integration`, `mix verify.phase11`, and `mix verify.phase99`; live Meilisearch is supplemental when available.
- **D-11:** Swoosh runtime proof is Phase 146 scope, not a Phase 144 claim.
- **D-12:** Keep deterministic evidence (reviewed diff, checked locks, clean workspace, behavior gates) distinct from network-dependent evidence (lockless fresh resolve and `mix hex.audit`).
- **D-13:** Fresh root proof uses a detached disposable worktree at the candidate SHA, removes only that root lock, and isolates dependency/build directories.
- **D-14:** Fresh root proof must select Req `>= 0.6.1` and `< 0.7.0`, Plug `>= 1.19.5` and `< 1.20.0`, Mint `>= 1.9.3`, hpax `>= 1.0.4`; root audit must exit zero without suppression.
- **D-15:** Commit only a compact dated evidence summary; never raw logs, disposable locks, advisory snapshots, or dependency trees.
- **D-16:** Add no permanent Mix task, script, CI lane, dependency policy, or security abstraction.
- **D-17:** Network/feed outage is unavailable proof, not a pass; any bad floor, nonzero audit, dirty lock, unexplained row, or required-gate failure blocks Phase 145.
- **D-18:** Production code changes require a demonstrated Req 0.6 compile/test failure, must be minimal/internal, preserve semantics, and include a regression test.
- **D-19:** Stop/re-plan for API/default/retry/redirect/timeout/decompression/Swoosh/schema changes, new transport abstractions, broad refactors, or extra upgrades.
- **D-20:** Normal adopter `mix deps.get` must yield a patched compatible graph without Scrypath API/behavior change.

### the agent's Discretion

- Extend `client_test.exs` or create one focused migration contract file, choosing the smaller clearer diff.
- Use graph-specific targeted Mix commands, but explain every moved row.
- Use an existing live smoke task or phase-5 path when local Meilisearch is available; report it separately.

### Deferred Ideas (OUT OF SCOPE)

- Phase 145 owns legacy Phoenix/Bandit/Ecto/Ecto SQL/Decimal/Postgrex remediation after the shared Req handoff.
- Phase 146 owns ScrypathOps Phoenix/LiveView/Bandit/Postgrex/Swoosh remediation and Swoosh Req-client proof.
- Phase 147 owns ecommerce graph-local remediation and four-graph closure evidence.
- Broader dependency modernization, package-head upgrades, permanent security automation, and advisory-policy tooling remain outside v1.36.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| SEC-01 | Root resolves beyond recorded Req, Mint, hpax, and Plug advisories using fixed-compatible constraints. | Atomic three-manifest/four-lock handoff, bounded Plug floor, fresh root resolution, and root audit. |
| COMPAT-02 | Existing Req-backed Meilisearch and Swoosh behavior remains covered after Req 0.6. | Focused root Meilisearch contract coverage; Swoosh runtime proof explicitly hands off to Phase 146. |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Retain Ecto-first/Phoenix-friendly ergonomics, the Meilisearch-first v1 boundary, and the internal adapter seam. [VERIFIED: AGENTS.md]
- Preserve explicit operational behavior and existing inline, Oban, and manual sync modes. [VERIFIED: AGENTS.md]
- Follow `CONTRIBUTING.md`, keep edits focused, and uphold green-main release-train posture. [VERIFIED: AGENTS.md]

## Summary

Phase 144 is a minimal compatibility handoff, not a generic upgrade. Root, `scrypath_ops`, and ecommerce directly require Req `~> 0.5`; the legacy example resolves it through the root path dependency. Each is independently solved with one version per graph, so a root-only change is unsatisfiable for checked-in consumers. Plan three direct requirement edits and four lock updates as one explained transition; retain all unrelated consumer advisory work for Phases 145–147. [VERIFIED: local `mix.exs`/`mix.lock` files; VERIFIED: 144-CONTEXT.md]

Req 0.6 removes automatic archive decoding and Req 0.6.1 makes decompression opt-in. Scrypath’s only Req seam uses JSON requests and stable tuple normalization, so preserve its defaults and add only causal seam tests. A production change is contingent on an observed upgrade failure. [CITED: https://github.com/wojtekmach/req/releases/tag/v0.6.0] [CITED: https://github.com/wojtekmach/req/releases/tag/v0.6.1] [VERIFIED: lib/scrypath/meilisearch/client.ex]

**Primary recommendation:** Correct delivery wording first; perform the atomic dependency/lock handoff with focused contract tests; then collect deterministic gates and separately record detached-worktree fresh-resolution/audit evidence.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Dependency constraints and locks | Build/package manager | CI | Mix manifests constrain resolution; each graph lock reproduces it. [VERIFIED: local manifests, locks, CI] |
| Meilisearch request construction | API / Backend | HTTP client | The private client seam owns Req options, headers, normalization, and telemetry. [VERIFIED: lib/scrypath/meilisearch/client.ex] |
| Transport compatibility test | Test suite | Req.Test | Existing plug-based Req.Test tests exercise the real internal request pipeline. [VERIFIED: local tests; VERIFIED: deps/req/lib/req/test.ex] |
| Fresh advisory evidence | Disposable build environment | Hex registry/feed | A lockless isolated resolve proves selected versions; Hex audit reports live advisory findings. [CITED: https://mix.hexdocs.pm/Mix.Tasks.Deps.Get.html] [CITED: https://hex.hexdocs.pm/Mix.Tasks.Hex.Audit.html] |

## Standard Stack

### Core

| Library/tool | Version | Purpose | Why Standard |
|---|---:|---|---|
| Req | `~> 0.6.1` in root, Ops, ecommerce | Existing internal HTTP client | Bounded patched 0.6 line; Req 0.6.1 was released 2026-06-08. [VERIFIED: `mix hex.info req 0.6.1`; VERIFIED: 144-CONTEXT.md] |
| Plug | `~> 1.19.5` root test-only | Existing test support | Holds the documented patched 1.19 line, excluding 1.20. [VERIFIED: `mix hex.info plug 1.19.5`; VERIFIED: mix.exs] |
| Mix | installed 1.19.5 / OTP 28 | resolution and lock validation | `mix deps.get --check-locked` rejects pending lock changes. [VERIFIED: local `mix help deps.get`] |
| Hex | installed with Mix | advisory audit | Audit exits nonzero for advisory or retirement findings. [CITED: https://hex.hexdocs.pm/Mix.Tasks.Hex.Audit.html] |

### Supporting

| Library | Floor | Purpose | When to Use |
|---|---:|---|---|
| Finch | solver-selected | Req transport | Move only if required by the Req closure. [VERIFIED: mix.lock; VERIFIED: 144-CONTEXT.md] |
| Mint | `>= 1.9.3` | protocol dependency | Validate in fresh root proof; never add direct constraint. [VERIFIED: 144-CONTEXT.md] |
| hpax | `>= 1.0.4` | HPACK dependency | Validate in fresh root proof; never add direct constraint. [VERIFIED: 144-CONTEXT.md] |
| Req.Test | existing | deterministic request simulation | Use only for focused migration coverage. [VERIFIED: deps/req/lib/req/test.ex] |

**Installation:** No new package. Edit existing constraints and refresh only their causal resolver closure. [VERIFIED: 144-CONTEXT.md]

## Package Legitimacy Audit

No package is added; this phase updates existing Hex dependencies only. The generic legitimacy seam supports npm/PyPI/crates, not Hex, so it is inapplicable. Key existing Hex package metadata was verified locally with `mix hex.info`; do not add direct transitive dependencies. [VERIFIED: local `mix hex.info req 0.6.1`, `plug 1.19.5`, `mint 1.9.3`, `hpax 1.0.4`; VERIFIED: 144-CONTEXT.md]

## Architecture Patterns

### System Architecture Diagram

```text
root/Ops/ecommerce manifests ──> independent Mix resolvers ──> four aligned locks
legacy root path dependency ──────────────────────────────────┘
                                                    │
                         all four `deps.get --check-locked` + root gates

Client config -> Req.new(default API-key header + caller options)
              -> Req.request(JSON)
              -> stable success / HTTP error / transport error tuple
              -> telemetry (method/path/status or error only)
              -> Req.Test tests; optional live Meilisearch smoke

candidate SHA -> detached worktree -> remove only worktree root lock
              -> isolated fresh deps.get -> version floor inspection -> hex.audit
```

### Pattern 1: Atomic shared Req-floor handoff

**What:** Set all three direct Req requirements to `~> 0.6.1`, resolve the four affected graphs, then review every moved lock row against the Req closure. [VERIFIED: 144-CONTEXT.md]

**When to use:** Path consumers have incompatible direct requirements after a root dependency floor changes. [VERIFIED: local manifests]

### Pattern 2: Test the client contract, not Req internals

**What:** Call public client functions through `Req.Test`; assert public tagged tuples and telemetry shape. [VERIFIED: local client/tests]

**Example:**

```elixir
Req.Test.stub(stub, fn conn -> Req.Test.transport_error(conn, :timeout) end)

assert {:error, {:transport_error, %Req.TransportError{reason: :timeout}}} =
         Client.get_settings("posts", meilisearch_url: "http://localhost:7700",
           req_options: [plug: {Req.Test, stub}, retry: false]
         )
```

`Req.Test.transport_error/2` exists specifically to simulate transport failures; `retry: false` keeps the test single-attempt and causal. [VERIFIED: deps/req/lib/req/test.ex]

### Pattern 3: Two-class evidence

**What:** Treat checked manifests/locks/gates as deterministic evidence and detached fresh resolution plus audit as network-dependent evidence. [VERIFIED: 144-CONTEXT.md]

### Anti-Patterns to Avoid

- Root-only Req edit; it leaves consumer constraints incompatible. [VERIFIED: local manifests; VERIFIED: 144-CONTEXT.md]
- Direct Mint/hpax constraints, `override: true`, advisory ignores, or unrelated upgrades. [VERIFIED: 144-CONTEXT.md]
- Proactively changing compression, decoders, multipart, retries, redirects, or timeouts. [CITED: https://github.com/wojtekmach/req/releases/tag/v0.6.0] [CITED: https://github.com/wojtekmach/req/releases/tag/v0.6.1]
- Permanent task/script/CI/policy additions. [VERIFIED: 144-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Transport simulation | Mox/Bypass/new transport behavior | Existing Req.Test | It invokes the actual Req pipeline used by Scrypath. [VERIFIED: deps/req/lib/req/test.ex] |
| Lock consistency | Custom parser | `mix deps.get --check-locked` per graph | Mix detects manifest/lock drift. [CITED: https://mix.hexdocs.pm/Mix.Tasks.Deps.Get.html] |
| Advisory check | Scraped feed or ignores | `mix hex.audit` in fresh root worktree | Hex fails on active findings. [CITED: https://hex.hexdocs.pm/Mix.Tasks.Hex.Audit.html] |
| Fresh resolution | Deleting primary lock | Detached worktree + isolated paths | Preserves reviewable reproducible state. [VERIFIED: 144-CONTEXT.md] |

## Common Pitfalls

### Root-only resolver blindness

**What goes wrong:** Root resolves but path consumers retain incompatible Req 0.5 constraints. [VERIFIED: local manifests; VERIFIED: 144-CONTEXT.md]

**How to avoid:** Atomically update three manifests/four locks and run `mix deps.get --check-locked` in each graph. [VERIFIED: 144-CONTEXT.md]

### Evidence-class confusion

**What goes wrong:** A locked pass is reported as a current registry/advisory result. [VERIFIED: 144-CONTEXT.md]

**How to avoid:** Record deterministic and network-dependent command results separately; unavailable network proof is not passing evidence. [VERIFIED: 144-CONTEXT.md]

### Error telemetry secret leakage

**What goes wrong:** Error behavior passes without checking metadata excludes API keys, headers, and bodies. [VERIFIED: 144-CONTEXT.md]

**How to avoid:** Capture the request error span and assert its error is present but sensitive fields are absent. [VERIFIED: lib/scrypath/meilisearch/client.ex; VERIFIED: test/scrypath/telemetry_test.exs]

## Code Examples

### Additive API-key and caller-header merge

```elixir
Req.Test.stub(stub, fn conn ->
  assert Plug.Conn.get_req_header(conn, "x-meili-api-key") == ["default-key"]
  assert Plug.Conn.get_req_header(conn, "x-request-id") == ["migration-proof"]
  Req.Test.json(conn, %{"uid" => "posts"})
end)
```

The current client prepends its API-key header while preserving caller headers. [VERIFIED: lib/scrypath/meilisearch/client.ex]

### Unique task-filter encoding

```elixir
Req.Test.stub(stub, fn conn ->
  assert conn.query_params["statuses"] == "enqueued,processing"
  Req.Test.json(conn, %{"results" => []})
end)
```

This protects the client-owned list-filter serialization rather than Req internals. [VERIFIED: lib/scrypath/meilisearch/client.ex]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|---|---|---|---|
| Req automatic archive/compressed decoding | Req 0.6 JSON default; Req 0.6.1 compression opt-in | 2026-06-08 | Keep Scrypath JSON-only defaults. [CITED: https://github.com/wojtekmach/req/releases/tag/v0.6.0] [CITED: https://github.com/wojtekmach/req/releases/tag/v0.6.1] |
| Root-only roadmap wording | One minimal cross-graph handoff then graph-local commits | Phase 144 prerequisite | Correct roadmap success criterion 4 and EVID-02 wording. [VERIFIED: 144-CONTEXT.md] |

## Open Questions

1. **Which exact lock rows will move?** Solver hashes and compatible closure rows are network output. Review each moved row against Req/Finch/Mint/hpax or root Plug before committing. [VERIFIED: 144-CONTEXT.md]
2. **Is any production compatibility patch required?** The current seam is JSON-only; resolve and run focused tests before touching source. Stop/re-plan if the fix alters locked semantics. [VERIFIED: local client; VERIFIED: 144-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---:|---|---|
| Elixir/Mix + OTP | resolve and root gates | ✓ | Elixir/Mix 1.19.5, OTP 28 | — [VERIFIED: local `mix --version`] |
| Git worktree | detached fresh proof | ✓ | 2.41.0 | — [VERIFIED: local `git --version`] |
| Hex registry/feed | fresh resolve/audit | ✓ at research time | live | Outage means unavailable proof. [VERIFIED: local `mix hex.info`; VERIFIED: 144-CONTEXT.md] |
| Docker | supplemental live smoke setup | ✓ | 29.5.2 | Report smoke unavailable unless Meilisearch runs. [VERIFIED: local `docker --version`; VERIFIED: CONTRIBUTING.md] |

## Validation Architecture

### Test Framework

| Property | Value |
|---|---|
| Framework | ExUnit and existing Req.Test stubs. [VERIFIED: local tests] |
| Quick run | `mix test test/scrypath/meilisearch/client_test.exs test/scrypath/telemetry_test.exs --exclude integration --exclude docs_contract` |
| Required root suite | `mix deps.get && mix compile --warnings-as-errors && mix test --exclude integration --exclude docs_contract && mix verify --exclude integration && mix verify.phase11 && mix verify.phase99` [VERIFIED: CONTRIBUTING.md; VERIFIED: 144-CONTEXT.md] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|---|---|---|---|---|
| SEC-01 | Four locks match changed constraints; fresh root reaches floors; audit clean | lock checks + network probe | each graph `mix deps.get --check-locked`; isolated root `mix deps.get && mix hex.audit` | locks ✅ / probe procedure ❌ |
| COMPAT-02 | Preserve tuple, option/header, query, and telemetry behavior | Req.Test unit contracts | quick run above | files ✅ / cases Wave 0 |
| COMPAT-02 | Live Meilisearch smoke if service exists | supplemental integration | `SCRYPATH_MEILISEARCH_URL=http://127.0.0.1:7700 mix verify.meilisearch_smoke` | task ✅ |

### Wave 0 Gaps

- [ ] Add client tests for retry-disabled transport normalization, default/caller header merge, and unique task-filter encoding — COMPAT-02.
- [ ] Add telemetry test for error metadata without headers/body/API key — COMPAT-02.
- [ ] No new test framework/dependency. [VERIFIED: local test suite]

## Security Domain

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | Yes | Preserve and test additive API-key header. [VERIFIED: local client] |
| V5 Input Validation | Yes | Preserve existing task-filter serialization and narrow Req behavior. [VERIFIED: local client] |
| V7 Error Handling/Logging | Yes | Stable tagged errors; failure telemetry excludes secret request data. [VERIFIED: 144-CONTEXT.md] |
| V14 Configuration | Yes | Fixed floors, no overrides/ignores, checked locks, isolated fresh proof. [VERIFIED: 144-CONTEXT.md] |

| Threat Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Vulnerable dependency resolution | Tampering / DoS | Fixed Req/Plug constraints and fresh Mint/hpax floor proof. [VERIFIED: 144-CONTEXT.md] |
| Archive/decompression resource exhaustion | DoS | Retain Req 0.6/0.6.1 secure defaults. [CITED: https://github.com/wojtekmach/req/releases/tag/v0.6.0] [CITED: https://github.com/wojtekmach/req/releases/tag/v0.6.1] |
| Credential leakage in error telemetry | Information disclosure | Assert sensitive headers/bodies are absent. [VERIFIED: 144-CONTEXT.md] |

## Assumptions Log

No assumptions: recommendations are based on locked phase context, inspected code, or official/current Mix, Hex, and Req documentation.

## Sources

### Primary (HIGH confidence)

- Local manifests/locks; `Scrypath.Meilisearch.Client`; focused tests; `CONTRIBUTING.md`; CI; locked phase context and advisory triage.
- [Req 0.6.0 release](https://github.com/wojtekmach/req/releases/tag/v0.6.0) and [Req 0.6.1 release](https://github.com/wojtekmach/req/releases/tag/v0.6.1).

### Secondary (MEDIUM confidence)

- [Req changelog](https://req.hexdocs.pm/changelog.html), [Mix deps.get](https://mix.hexdocs.pm/Mix.Tasks.Deps.Get.html), and [Hex audit](https://hex.hexdocs.pm/Mix.Tasks.Hex.Audit.html).

## Metadata

**Confidence breakdown:** Standard stack HIGH; architecture HIGH; pitfalls HIGH — all are either locked decisions, direct codebase findings, or current official upstream documentation.  
**Valid until:** 2026-08-29 for live registry/advisory facts.
