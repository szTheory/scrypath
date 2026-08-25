# Phase 146: ScrypathOps Web/Client Remediation - Research

**Researched:** 2026-08-24  
**Domain:** isolated Phoenix/LiveView/Swoosh/Req/Postgrex Mix dependency remediation  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Direct bounds are Phoenix `~> 1.8.9`, Phoenix LiveView `~> 1.1.33`, Bandit `~> 1.12.1`, Swoosh `~> 1.26.3`, Postgrex `~> 0.22.4`, and retained Req `~> 0.6.1`; permit reviewed patches only.
- **D-02:** Re-check live Hex and EEF CNA evidence for stable, unretired Postgrex `0.22.4`; contradictory/missing evidence stops the batch—no prerelease, invented substitute, or vulnerable fallback.
- **D-03–D-04:** Keep Plug, Mint, hpax, Finch, Ecto, Decimal, Phoenix Ecto, and Ecto SQL transitive; add neither direct requirements nor overrides; refresh only causal solver closure and explain every moved lock row.
- **D-05:** Detached lockless exact-candidate proof must select Phoenix `>= 1.8.9 < 1.9.0`, LiveView `>= 1.1.33 < 1.2.0`, Bandit `>= 1.12.1 < 1.13.0`, Swoosh `>= 1.26.3 < 1.27.0`, Postgrex `>= 0.22.4 < 0.23.0`, Req `>= 0.6.1 < 0.7.0`, Plug `>= 1.19.5 < 2.0.0`, Mint `>= 1.9.3`, hpax `>= 1.0.4`.
- **D-06–D-09:** Test the real `Swoosh.ApiClient.Req` with a supported Req test seam, no provider/network/credentials/fake adapter. Cover init, POST URL/body/headers/Swoosh UA, `email.private[:client_options]`, Swoosh precedence for headers/body/`decode_body: false`, raw body, normalized tuple, and transport error. Preserve `Swoosh.Adapters.Test`, test `api_client: false`, `ScrypathOps.Mailer`, and production `Swoosh.ApiClient.Req` selection.
- **D-10–D-13:** Root `mix verify.opsui` is binding; it owns Ops routes, LiveView, boot, Repo/migrations, contracts, and UI invariants. Fixed selection plus unsuppressed audit owns upstream-advisory proof. No ecommerce/browser/protocol lane. A compile/test-proven fix must be minimal and internal, with no public API, route/UI, mail semantic, schema, or operational change.
- **D-14–D-19:** Inspect diff; Ops checked-lock + warnings-as-errors compile; root `mix verify.opsui`; then root `main-ci`, `repo-hygiene`, `release-truth`, `phase99-trust`. Afterwards detached exact-SHA worktree with isolated dependency/build paths removes only disposable Ops lock, resolves, asserts D-05, and audits unsuppressed. Record compact candidate/time/tool/commands/status/version/audit/causal-diff evidence; network/feed outage, audit/range/gate failure, dirty primary lock, unexplained churn, Postgrex-evidence loss, or Swoosh failure stops handoff. One isolated third remediation commit only.
- **D-20–D-22:** No new policy language, permanent CI/security subsystem, product capability, UI work, route, schema, provider decision, or broader modernization. Ecommerce and all-four-graph closure are Phase 147 only.

### the agent's Discretion

- Choose the focused Swoosh-contract filename and either direct invocation or narrowly restored temporary API-client configuration.
- Choose targeted `mix deps.update` commands, retaining the fixed strings, no-override rule, target ranges, and causal-diff review.
- Order individual named root commands as CONTRIBUTING permits; all must pass before commit/handoff.

### Deferred Ideas (OUT OF SCOPE)

- Phase 147 owns ecommerce remediation, mounted Ops/browser proof, four-graph closure evidence, ordered commits, and todo closure.
- Permanent dependency automation, a new security CI lane, and broad modernization require a separate decision.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| SEC-03 | Independently resolve ScrypathOps beyond web, LiveView, mailer, HTTP, and database advisories. | Exact direct bounds, causal lock-only resolution, full Ops and root gates, detached fresh resolver and audit. |
| EVID-03 | Postgrex changes wait for stable published fixed release confirmed by live advisory and Hex. | Dual-source `0.22.4` gate immediately before change and fresh-audit evidence; outage/conflict blocks. |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Keep changes focused, preserve unrelated dirty worktree state, follow `CONTRIBUTING.md`, and retain green-main/PR-first release posture. [VERIFIED: AGENTS.md]
- ScrypathOps uses Phoenix 1.8 conventions and the included `Req`; do not introduce HTTPoison, Tesla, or `:httpc`. Use `mix precommit` after implementation work. [VERIFIED: scrypath_ops/AGENTS.md]
- Tests use `start_supervised!/1`; do not use sleeps/alive polling; preserve Ecto Sandbox ownership. [VERIFIED: scrypath_ops/AGENTS.md]
- No template/UI change is planned, so the LiveView/Tailwind directives are constraints only, not an implementation surface. [VERIFIED: scrypath_ops/AGENTS.md]

## Summary

### Execution-discovery amendment (2026-08-24)

[VERIFIED: Plan 146-03 execution evidence] The exact-SHA detached lockless
resolution selected Plug `1.20.3`. D-03 deliberately keeps Plug transitive and
forbids a direct constraint or override, so the prior D-05 `< 1.20.0` ceiling
could not be enforced by the manifest. D-05's Plug range is corrected only to
`>= 1.19.5 and < 2.0.0`; all other eight ranges remain as researched. This does
not reopen the reviewed deterministic lock or authorize package-head churn: the
primary lock remains at Plug `1.19.5`, while fresh proof may accept an unretired,
audit-clean compatible Plug 1.x selected by the transitive graph.

[CITED: https://hex.pm/packages/plug; https://hex.pm/packages/plug/versions]
On 2026-08-24, Hex listed Plug `1.20.3` as current and unretired, published
2026-07-09. [CITED: https://github.com/elixir-plug/plug] Plug's official support
table lists v1.20 for bug fixes and v1.19 for security patches only. The
mandatory unsuppressed `mix hex.audit` remains the execution-time authority for
the actual fresh graph.

[VERIFIED: repository code] ScrypathOps is an independent Mix graph. Its current manifest selects outdated direct Phoenix (`~> 1.8.5`), LiveView (`~> 1.1.0`), Swoosh (`~> 1.16`), Postgrex (unbounded), and Bandit (`~> 1.5`) while already retaining Req `~> 0.6.1`; its lock has the unresolved advisory versions. `mix hex.audit` currently reports the Phase-146 web/mailer/database findings. The remediation therefore belongs solely in `scrypath_ops/mix.exs`, `scrypath_ops/mix.lock`, a focused contract test, and compact phase evidence.

[CITED: https://hex.pm/api/packages/postgrex] Hex confirms the selected non-retired releases Phoenix 1.8.9, LiveView 1.1.33, Bandit 1.12.1, Swoosh 1.26.3, Postgrex 0.22.4, and Req 0.6.3 were published. [CITED: https://cna.erlef.org/cves/CVE-2026-66838.json] The EEF CNA marks Postgrex `0.19.3` through `< 0.22.4` affected. Re-query both authorities during execution; this research result is not permission to bypass D-02.

[CITED: https://swoosh.hexdocs.pm/Swoosh.ApiClient.Req.html] `Swoosh.ApiClient.Req` forwards `client_options` but overwrites `headers`, `body`, and `decode_body: false`. [VERIFIED: selected local Swoosh source] It starts Req, prepends the Swoosh User-Agent, returns `{:ok, status, headers, body}`, and propagates `{:error, reason}`. [CITED: https://req.hexdocs.pm/Req.Test.html] `Req.Test` supplies concurrent stubs and transport errors, so a direct client contract is sufficient and service-free.

**Primary recommendation:** Apply only the locked direct bounds, refresh only their causal lock closure, add one real-client Req.Test contract, pass the specified deterministic gates, then capture detached exact-SHA fresh-resolution and unsuppressed-audit evidence before the sole Ops commit.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Direct floors and reviewed resolution | Build/dependency management | Hex registry | `mix.exs` owns direct intent and `mix.lock` is deterministic resolution. [VERIFIED: repository code] |
| Fresh advisory evidence | Hex registry/advisory service | Build/dependency management | Detached Mix process resolves and audits the exact candidate. [CITED: https://hex.hexdocs.pm/Mix.Tasks.Hex.Audit.html] |
| Swoosh/Req wire contract | API/backend client | Req test Plug | The selected Swoosh client owns normalization; Req.Test controls its transport. [VERIFIED: selected source] |
| Phoenix/LiveView/Repo regression | Frontend server | Database | Existing Ops suite drives endpoint, LiveView, application and Postgres boundaries. [VERIFIED: `mix verify.opsui`] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---|---|---|---|
| Phoenix | `~> 1.8.9` | endpoint/router | Locked fixed-compatible web floor. [CITED: Hex API] |
| Phoenix LiveView | `~> 1.1.33` | rendered interactive Ops routes | Locked compatible LiveView floor. [CITED: Hex API] |
| Bandit | `~> 1.12.1` | configured endpoint adapter | Existing `Bandit.PhoenixAdapter`; no server redesign. [VERIFIED: config] |
| Swoosh | `~> 1.26.3` | mailer/API-client implementation | Existing mailer and selected Req client. [VERIFIED: config/source] |
| Postgrex | `~> 0.22.4` | existing Repo driver | Only allowed after live dual-source gate. [CITED: Hex API; CNA] |
| Req | `~> 0.6.1` | existing API client and test seam | Preserves Phase 144 handoff. [VERIFIED: manifest/lock] |

### Supporting

| Library | Version | Purpose | When to Use |
|---|---|---|---|
| Plug | transitive `>= 1.19.5, < 2.0.0` | Phoenix/Req pipeline | Assert a compatible 1.x fresh selection; do not add direct ownership. [VERIFIED: context D-03/D-05 and execution-discovery amendment] |
| Mint / hpax | transitive `>= 1.9.3` / `>= 1.0.4` | Req/Finch HTTP closure | Preserve inherited fixed closure. [VERIFIED: lock/context] |
| Ecto / Decimal / Finch | transitive | existing data/HTTP closure | Keep untouched unless causal failure proves otherwise. [VERIFIED: context D-03] |

**Installation:** none—only existing Hex package bounds change. [VERIFIED: repository code]

## Package Legitimacy Audit

Not applicable: no package identity is introduced. Existing official Hex packages are being bounded and re-resolved, so the new-package legitimacy gate does not apply. [VERIFIED: phase scope]

## Architecture Patterns

### System Architecture Diagram

```text
Ops mix.exs direct bounds -> Hex solver -> reviewed Ops mix.lock -> checked-lock/compile
                                  |                                  |
                                  v                                  v
                         detached exact-SHA resolver            mix verify.opsui
                                  |                                  |
                          version assertions + audit       Phoenix/LiveView/Repo tests

Swoosh.ApiClient.Req.init/post -> Req.Test plug -> captured POST / raw response
         |                        |                         |
         +-- client_options ------+-- transport error -------+-> Swoosh tuple/error contract
```

### Recommended Project Structure

```text
scrypath_ops/
├── mix.exs                                      # six direct fixed-compatible bounds
├── mix.lock                                     # causal closure only
├── config/prod.exs                              # unchanged ApiClient.Req selection
└── test/scrypath_ops/swoosh_api_client_req_test.exs  # direct focused contract
.planning/phases/146-scrypathops-web-client-remediation/
└── 146-SUMMARY.md                               # compact proof, no raw logs
```

### Pattern 1: Direct production-client contract

**What:** Call `Swoosh.ApiClient.Req.init/0` and `post/4` directly with a real `%Swoosh.Email{}` whose private `client_options` carries `plug: {Req.Test, name}` and `retry: false`. Use a Req.Test expectation to inspect method, URL, headers, raw request body, and response handling. [CITED: https://req.hexdocs.pm/Req.Test.html]

**When to use:** Only for the missing Swoosh/Req seam; do not change suite-wide `:swoosh` test config or call a mail provider.

```elixir
# Source: Swoosh.ApiClient.Req + Req.Test official docs
Req.Test.expect(__MODULE__, fn conn ->
  assert conn.method == "POST"
  assert Req.Test.raw_body(conn) == "payload"
  Plug.Conn.send_resp(conn, 202, "raw-response")
end)

email = %Swoosh.Email{private: %{client_options: [plug: {Req.Test, __MODULE__}, retry: false]}}
assert {:ok, 202, headers, "raw-response"} = Swoosh.ApiClient.Req.post("https://mailer.test/send", [{"x-provider", "yes"}], "payload", email)
assert {"user-agent", _} = List.keyfind(headers, "user-agent", 0)
```

### Anti-Patterns to Avoid

- **Testing `Swoosh.Adapters.Test` instead:** it does not execute the configured production client. [VERIFIED: test config]
- **Global API-client mutation:** leaks a production-like setting into unrelated mailer tests; invoke direct client or save/restore exact app config. [VERIFIED: context D-08]
- **Adding direct Plug/Mint/hpax overrides:** hides solver causality and violates D-03.
- **Probing by deleting the primary lock:** destroys deterministic evidence; remove only a detached worktree lock.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| HTTP fake/provider simulator | custom mail transport | `Req.Test` plug/transport error | Tests real Req and real Swoosh client without credentials/network. [CITED: Req.Test docs] |
| Advisory detector | local vulnerability list | unsuppressed `mix hex.audit` | Hex owns retirement/advisory feed and nonzero semantics. [CITED: Hex audit docs] |
| Dependency solver assertion | manual lock parsing alone | `mix deps.get --check-locked`, fresh `mix deps.get`, `Version.match?/2` | Verifies both reviewed lock and manifest-resolved candidate. [VERIFIED: Mix help] |

## Common Pitfalls

### Pitfall 1: Swoosh's option precedence is tested backwards
**What goes wrong:** a test proves caller headers/body/decode behavior rather than Swoosh-owned values.  
**Avoid:** deliberately pass conflicting `client_options` and assert supplied headers/body win and response remains raw. [CITED: Swoosh ApiClient Req docs]

### Pitfall 2: Req retries make a transport test nondeterministic
**What goes wrong:** one error expectation is consumed by automatic retries.  
**Avoid:** set `retry: false` in the test-local client options and assert the returned `Req.TransportError`. [CITED: Req.Test docs]

### Pitfall 3: Fresh proof silently mutates the primary checkout
**Avoid:** record primary lock SHA, create exact-SHA detached worktree, set both `MIX_DEPS_PATH` and `MIX_BUILD_PATH` beneath it, remove/probe/cleanup there, then compare primary SHA and tracked state. [VERIFIED: Phase 145 precedent; context D-15]

### Pitfall 4: A clean audit is claimed when external evidence was unavailable
**Avoid:** classify registry/advisory outages as unavailable and blocking, never pass; run no `ignore_advisories`/`ignore_retirements`. [CITED: Hex audit docs; context D-16]

## Code Examples

### Isolated Swoosh configuration helper (only if direct invocation cannot carry test options)

```elixir
old = Application.get_env(:swoosh, :api_client)
Application.put_env(:swoosh, :api_client, Swoosh.ApiClient.Req)
on_exit(fn -> Application.put_env(:swoosh, :api_client, old) end)
```

Prefer direct `Swoosh.ApiClient.Req.post/4`; if temporary config is needed, preserve “unset” versus prior value with `Application.delete_env/2` when appropriate. [VERIFIED: context D-08]

### Fresh candidate boundary assertion

```elixir
lock = Mix.Dep.Lock.read()
for {name, requirement} <- [{:phoenix, ">= 1.8.9 and < 1.9.0"}, {:postgrex, ">= 0.22.4 and < 0.23.0"}] do
  version = lock |> Map.fetch!(name) |> elem(2)
  Version.match?(version, requirement) || raise "#{name} #{version} violates #{requirement}"
end
```

## State of the Art

| Old Approach | Current Approach | Impact |
|---|---|---|
| Broad old Ops bounds and reviewed vulnerable lock | bounded patch-compatible cohort plus detached fresh resolution | Keeps compatibility review causal and reproducible. [VERIFIED: manifest/context] |
| Test mail adapter only | direct real `Swoosh.ApiClient.Req` contract through Req.Test | Covers production-selected client without provider traffic. [CITED: Swoosh/Req docs] |

## Assumptions Log

All substantive dependency/advisory/API claims were checked against repository code or current official sources. No user confirmation is required beyond the execution-time D-02 re-check.

## Open Questions (RESOLVED)

1. **Will the fixed bounds expose a repository-owned compile/test incompatibility?**
   - **Resolved handling:** Plan 146-01 permits only a compile/test-demonstrated, minimal ScrypathOps-internal D-13 compatibility fix with focused regression coverage; Plan 146-02 runs the full Ops and named root gates. If the failure cannot be resolved within that boundary, execution stops and re-plans.
2. **Will live Hex/CNA evidence remain available at execution time?**
   - **Resolved handling:** Plan 146-01 re-queries both D-02 authorities before the Postgrex change, and Plan 146-03 re-queries them in the detached exact-candidate evidence window. An outage, missing predicate, or contradiction blocks execution under D-16 rather than downgrading the evidence.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---:|---|---|
| Elixir/Mix + OTP | resolver, tests, root gates | ✓ | Mix 1.19.5 / OTP 28 | — [VERIFIED: local] |
| PostgreSQL | `mix verify.opsui` | ✓ | psql 14.17; localhost:5432 accepting | CI/container service if local lane changes. [VERIFIED: local] |
| Git worktree | detached evidence | ✓ | 2.41.0 | — [VERIFIED: local] |
| Hex/CNA network | fresh resolve/audit/Postgrex guard | ✓ at research time | live | none; unavailable blocks. [VERIFIED: local curl] |

## Validation Architecture

### Test Framework

| Property | Value |
|---|---|
| Framework | ExUnit, Phoenix LiveViewTest, Ecto SQL Sandbox, Req.Test. [VERIFIED: repository code] |
| Config | `scrypath_ops/test/test_helper.exs` and `mix.exs` aliases |
| Quick run | `cd scrypath_ops && mix test test/scrypath_ops/swoosh_api_client_req_test.exs` |
| Required Ops run | `mix verify.opsui` from repository root |
| Required root runs | `mix compile --warnings-as-errors`; `mix test --exclude integration --exclude docs_contract --include requires_clean_workspace`; `mix verify --exclude integration`; `mix verify.phase11`; `mix verify.phase99`. [VERIFIED: CONTRIBUTING.md] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|---|---|---|---|---|
| SEC-03 | Bound graph and deterministic Ops behavior | lock + integration suite | `cd scrypath_ops && mix deps.get --check-locked && mix compile --warnings-as-errors`; root `mix verify.opsui` | lock ✅ / focused test ❌ |
| SEC-03 | Swoosh Req client request/response/error semantics | service-free unit contract | focused test above | ❌ Wave 0 |
| EVID-03 | Stable Postgrex selection and audit | detached network evidence | exact-SHA `mix deps.get`, assertions, `mix hex.audit` | procedure ❌ |

### Wave 0 Gaps

- [ ] `scrypath_ops/test/scrypath_ops/swoosh_api_client_req_test.exs`—real Req client init, request precedence/raw tuple, and transport error.
- [ ] No new framework or package.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | no change | Preserve existing boot/config guards. [VERIFIED: code] |
| V3 Session Management | indirect | Existing Phoenix/Plug regression suite; no session design change. |
| V4 Access Control | no change | Existing Ops route security tests. |
| V5 Input Validation | indirect | Upstream fixed selection + existing framework boundaries; no custom parser. |
| V6 Cryptography | no change | Do not hand-roll or alter crypto. |

### Known Threat Patterns

| Pattern | STRIDE | Mitigation |
|---|---|---|
| Vulnerable resolver selection | Tampering/DoS | bounded direct floors, checked lock, detached fresh assertions, unsuppressed audit. |
| Postgrex floor fabricated or prerelease | Tampering | live Hex + EEF CNA dual-source gate; stop on failure. |
| Audit suppression | Repudiation | no ignore configuration/environment; nonzero audit blocks. |
| Mail test hides real client regression | Tampering | direct `Swoosh.ApiClient.Req` + Req.Test contract. |

## Sources

### Primary
- [Swoosh ApiClient Req docs](https://swoosh.hexdocs.pm/Swoosh.ApiClient.Req.html) — option precedence.
- [Req.Test docs](https://req.hexdocs.pm/Req.Test.html) — stubs, expectations, errors, concurrency.
- [Hex audit docs](https://hex.hexdocs.pm/Mix.Tasks.Hex.Audit.html) — audit and nonzero semantics.
- [Hex Postgrex API](https://hex.pm/api/packages/postgrex) and [EEF CNA CVE-2026-66838](https://cna.erlef.org/cves/CVE-2026-66838.json) — stable release/advisory boundary.

### Repository
- `scrypath_ops/mix.exs`, `mix.lock`, configs, selected dependency sources, `Mix.Tasks.Verify.Opsui`, `CONTRIBUTING.md`, and Phase 144/145 artifacts.

## Metadata

**Confidence breakdown:** Standard stack HIGH (locked choices rechecked in Hex); architecture HIGH (existing code/gates); pitfalls HIGH (official Swoosh/Req/Hex behavior and prior detached-proof precedent).  
**Valid until:** 2026-08-31 for live package/advisory facts; re-check at execution.
