# Technology Stack — scrypath_ops v1.18 Sigra Integration

**Project:** Scrypath v1.18 — optional Sigra integration in scrypath_ops
**Researched:** 2026-04-25
**Confidence:** HIGH (sources: direct file reads of sigra/mix.exs, sigra/CHANGELOG.md, sigra/lib/, hex.pm version list, Elixir official docs)

---

## Existing validated stack (do not churn)

Already in `scrypath_ops/mix.exs` — no re-research needed per milestone context:

| Technology | Constraint | Role |
|------------|-----------|------|
| Elixir | `~> 1.17` | Runtime (scrypath_ops/mix.exs:6) |
| Phoenix | `~> 1.8.5` | Web framework (scrypath_ops/mix.exs:42) |
| Phoenix LiveView | `~> 1.1.0` | Operator UI (scrypath_ops/mix.exs:50) |
| Ecto SQL | `~> 3.13` | DB layer (scrypath_ops/mix.exs:44) |
| Postgrex | `>= 0.0.0` | Postgres driver (scrypath_ops/mix.exs:46) |
| Bandit | `~> 1.5` | HTTP server (scrypath_ops/mix.exs:64) |

The root `scrypath` hex package (`mix.exs:4` — version `0.3.4`) is **not touched** by v1.18.
`scrypath_ops` is consumed via `{:scrypath_ops, path: ".."}` — it is in-repo only, never hex-published.

---

## v1.18 Stack Additions

### 1. Sigra — the only new dep

**Add to `scrypath_ops/mix.exs`:**

```elixir
{:sigra, "~> 0.2", optional: true}
```

**Version constraint rationale — `~> 0.2` (pessimistic minor floor, not patch-pinned):**

- Sigra local source is `0.2.5` (sigra/mix.exs:4); hex.pm latest published is `0.2.4` (published 2026-04-24). The `0.2.5` changelog entry (2026-04-25) is unreleased at time of research.
- Hex release history from hex.pm/packages/sigra/versions: `0.2.0` (2026-04-20), `0.2.1` (2026-04-23), `0.2.2` (2026-04-23), `0.2.3` (2026-04-23), `0.2.4` (2026-04-24). Five patch releases in five days — this is rapid iteration cadence.
- All `0.2.x` releases ship the primitives scrypath_ops needs (`Sigra.Session`, `Sigra.Plug.RequireSudo`, `Sigra.Plug.ForbidDuringImpersonation`, `Sigra.Plug.RequireAdminAccess`, `Sigra.Audit.log_safe/3`, `Sigra.Admin.Policy`) — confirmed present in sigra/lib/sigra/plug/ and sigra/lib/sigra/audit.ex.
- `~> 0.2` (not `~> 0.2.4`) is correct. SemVer 0.x: minor is the breaking-change signal. `~> 0.2` allows `0.2.x` upward and stops before `0.3.0`. Patch-pinning to `~> 0.2.4` would force adopters to hold a specific patch even for bugfixes — wrong tradeoff when Sigra is still moving fast at `0.2.x`.
- Do NOT use `~> 0.3` — Sigra is still 0.x; `0.3.0` could be breaking. Wait for adopters to need it.

**Confirmed primitives available in 0.2.x (verified from sigra/lib/):**

| Primitive | File | Used by |
|-----------|------|---------|
| `%Sigra.Session{sudo_at, impersonator_user_id, impersonator_session_id}` | sigra/lib/sigra/session.ex:63–85 | `OperatorContext` builder |
| `Sigra.Plug.ForbidDuringImpersonation` | sigra/lib/sigra/plug/forbid_during_impersonation.ex | Host router wiring |
| `Sigra.Plug.RequireSudo` | sigra/lib/sigra/plug/require_sudo.ex | Host router wiring |
| `Sigra.Plug.RequireAdminAccess` | sigra/lib/sigra/plug/require_admin_access.ex | Host router wiring |
| `Sigra.Audit.log_safe/3` | sigra/lib/sigra/audit.ex:143 | `Gating.gate_sensitive_action/3` |
| `Sigra.Admin.Policy` | sigra/lib/sigra/admin/ | Allowlist entry |

**Note on `active_organization_id` in OperatorContext:** `%Sigra.Session{}` does not store `active_organization_id` directly. The audit module reads `scope.active_organization.id` (sigra/lib/sigra/audit.ex:154–158), meaning active_organization is on the scope struct hydrated from the session, not the session struct itself. The `OperatorContext` builder should read from `conn.assigns[:current_scope].active_organization` rather than `conn.private[:sigra_session]` for the org field.

---

## Transitive Dep Tree — What Gets Pulled (and What Doesn't)

Sigra's `deps` in sigra/mix.exs — split by optionality:

### Sigra MANDATORY transitive deps (always pulled when `:sigra` is in the dep tree)

| Library | Sigra constraint | Risk to non-Sigra scrypath_ops users |
|---------|-----------------|--------------------------------------|
| `argon2_elixir` | `~> 4.1` | **Pulls NIF** — Argon2 is a C NIF that requires a C compiler at build time. |
| `comeonin` | `~> 5.3` | Password hashing behaviour — no NIF, pure Elixir wrapper. |
| `nimble_totp` | `~> 1.0` | TOTP — pure Erlang, lightweight. |
| `cloak_ecto` | `~> 1.3` | Field encryption — pulls `:cloak` which may require OpenSSL. |
| `wax_` | `~> 0.7` | WebAuthn/passkeys — pulls CBOR + crypto libs. |
| `flop` | `~> 0.26.3` | Pagination/filtering. |
| `flop_phoenix` | `~> 0.26.0` | Phoenix UI for Flop. |
| `nimble_options` | `~> 1.1` | Already in scrypath core — no conflict. |
| `ecto` / `ecto_sql` | `~> 3.12` | Already in scrypath_ops — no conflict. |
| `phoenix` / `phoenix_live_view` | `~> 1.8` / `~> 1.1` | Already in scrypath_ops — compatible. |

**Key finding:** Because `:sigra` is `optional: true` in scrypath_ops, **none of these transitive deps are forced on consumers of scrypath_ops who don't declare `:sigra`**. Mix's optional dep semantics ensure the dep tree is pruned at the optional edge. A host that does `{:scrypath_ops, path: ".."}` without also declaring `{:sigra, ...}` will NOT get argon2, cloak_ecto, wax_, or any Sigra transitive dep.

### Sigra OPTIONAL transitive deps (only pulled if host explicitly adds them)

| Library | Sigra constraint | Note |
|---------|-----------------|------|
| `bcrypt_elixir` | `~> 3.3`, optional | NIF — only if host wants Bcrypt hasher |
| `hammer` | `~> 7.3`, optional | Rate limiting |
| `swoosh` | `~> 1.5`, optional | Email delivery (scrypath_ops already has `~> 1.16`) |
| `oban` | `~> 2.17`, optional | Background jobs (scrypath_ops has no Oban dep currently) |
| `assent` | `~> 0.3`, optional | OAuth strategies |
| `joken` | `~> 2.6`, optional | JWT |
| `eqrcode` | `~> 0.2.1`, optional | QR code generation for MFA |

None of these are needed by scrypath_ops. Do not add them.

---

## `optional: true` Semantics — What It Means and What It Doesn't

**What `optional: true` DOES:**
When a package declares `{:sigra, "~> 0.2", optional: true}`, Mix tells downstream consumers: "you only get `:sigra` in your dep tree if you explicitly declare it too." A host app that uses scrypath_ops but does not add `:sigra` to its own mix.exs will NOT have Sigra compiled. The Sigra transitive deps (argon2, cloak_ecto, wax_, etc.) are also excluded.

**What `optional: true` does NOT do:**
It does NOT prevent scrypath_ops from failing to compile if Sigra module references exist in unconditional code. `optional: true` is a dep-graph signal only. Without a compile-time guard, any `Sigra.Session` reference in `scrypath_ops/lib/` will cause a compilation error in a Sigra-absent host.

**Implication:** Both levers are required:
1. `optional: true` in mix.exs — governs the dep tree for consumers
2. `Code.ensure_loaded?(Sigra.Session)` guard — governs compilation in the absence of Sigra

---

## Compile Guard — Correct Pattern

**Use `Code.ensure_loaded?/1` (not `Code.ensure_compiled?/1`).**

Rationale from official Elixir docs and community consensus:

- `Code.ensure_compiled?/1` is deprecated. Replaced by `Code.ensure_compiled/1` (returns `{:module, mod}` or error tuple).
- `Code.ensure_compiled/1` is for intra-project cross-compilation dependency ordering — it halts compilation until the target module is available. It is documented as NOT needed for external deps because external deps are always compiled upfront.
- `Code.ensure_loaded?/1` is the correct idiom for checking whether an optional external dep's module is available. Returns `true`/`false`. No blocking, no compilation stall.
- Sigra itself uses `Code.ensure_loaded?/1` for all its own optional dep guards (sigra/lib/sigra/delivery.ex:114, sigra/lib/sigra/mfa.ex:1059, sigra/lib/sigra/crypto.ex:244, sigra/lib/sigra/application.ex:75) — follow the same pattern.

**Pattern for module-level conditional definition:**

```elixir
# scrypath_ops/lib/scrypath_ops/integrations/sigra/on_mount.ex
if Code.ensure_loaded?(Sigra.Session) do
  defmodule ScrypathOps.Integrations.Sigra.OnMount do
    # ...references to Sigra.Session, Sigra.Plug.FetchSession, etc.
  end
end
```

**Pattern for function-level guard (within always-compiled module):**

```elixir
def build_operator_context(conn) do
  if Code.ensure_loaded?(Sigra.Session) do
    # Sigra-aware path
  else
    nil
  end
end
```

**Important limitation:** `Code.ensure_loaded?` cannot guard `use MacroFromSigra` statements. Macro expansion happens before the conditional is evaluated. If any Sigra-provided macro needs to be used, the entire module must be conditional (wrap the `defmodule` block in the `if`). This is documented in elixir-lang/elixir issue #8970.

---

## What NOT to Add (Anti-Deps)

The following must NOT appear in `scrypath_ops/mix.exs` or `examples/phoenix_sigra_ops/mix.exs` unless the feature explicitly requires them:

| Category | Libraries | Why Not |
|----------|-----------|---------|
| Sigra MFA backends | `nimble_totp`, `eqrcode` | Sigra mandatory/optional — these are Sigra internals, not scrypath_ops concerns |
| Sigra OAuth | `assent`, `joken` | OAuth/JWT are Sigra optional deps; scrypath_ops has no auth provider role |
| Sigra rate limiting | `hammer` | Rate limiting is Sigra-internal |
| Bcrypt hasher | `bcrypt_elixir` | Sigra optional; only needed if host switches from Argon2 to Bcrypt |
| WebAuthn | `wax_` | Transitively present when Sigra is loaded, but must not be directly depended on |
| Cloak | `cloak_ecto` | Same — Sigra transitive, not scrypath_ops direct concern |
| Oban | `oban` | scrypath_ops does not currently use Oban; do not add as a Sigra side-effect |
| Email delivery beyond existing Swoosh | `swoosh` (new constraint) | Already in scrypath_ops at `~> 1.16`; Sigra's `~> 1.5` constraint is satisfied by the existing dep |
| Sigra itself in `lib/scrypath/` | Any Sigra module | Core must stay auth-agnostic; zero Sigra imports in lib/scrypath/ |

---

## Worked Example — `examples/phoenix_sigra_ops/`

The worked example is a standalone Phoenix app. Its mix.exs should declare:

```elixir
{:scrypath_ops, path: "../../"},   # in-repo reference
{:sigra, "~> 0.2"},                # explicit — not optional in the example
# Standard Phoenix deps (phoenix, phoenix_live_view, ecto_sql, postgrex, bandit)
```

**Test-only needs for the example:**
- `phoenix_live_view` already includes `Phoenix.LiveViewTest` — no separate test dep needed for LiveView testing.
- `lazy_html` (`>= 0.1.0`, only: :test) is already in scrypath_ops; the example may use the same pattern for HTML assertions.
- No `plug_cowboy` needed — the example uses Bandit (same as scrypath_ops).
- No `bypass` needed — Sigra integration is in-process; no external HTTP mocking required for v1 (audit goes to the host's Repo, not an external service).
- No `mox` needed at the example level — unit-level Sigra mock testing belongs in scrypath_ops unit tests, not the example smoke app.
- ExUnit + `Phoenix.ConnTest` + `Phoenix.LiveViewTest` are sufficient.

**Does `mix sigra.install` generate the example scaffold?**
`mix sigra.install` (sigra/lib/mix/tasks/sigra.install.ex) generates a full host-owned auth scaffold (sessions, Argon2id, TOTP, passkeys, admin). It is a code generator that copies files into the host app. For `examples/phoenix_sigra_ops/`, use it to bootstrap the auth skeleton, then layer the scrypath_ops wiring on top. The generator supports `--no-passkeys` and `--no-admin` flags to reduce scope. However, the example's primary purpose is showing the scrypath_ops integration, not re-demonstrating full Sigra setup — keep the generated surface minimal.

---

## Namespace-Fence CI Check — Boundary Library vs Plain Grep

**Decision: Plain CI grep for v1.18. Do not adopt the Boundary library.**

Rationale:

- The `Boundary` hex library (from Mox's author) enforces call-graph rules at compile time and is valuable for large umbrella apps or teams. For a single integration namespace in an in-repo app, it adds a required dep plus configuration overhead that is not justified.
- The scrypath repo already uses CI grep patterns (`.github/workflows/ci.yml` — existing namespace and change-detection greps). A grep step is consistent with the existing tooling style.
- The fence is simple: "fail if `Sigra.` appears under `lib/scrypath/` or outside `scrypath_ops/lib/scrypath_ops/integrations/sigra/`". A single `grep -r "Sigra\." --include="*.ex" lib/scrypath/` step catches the primary violation.
- Boundary would catch more subtle violations (calling across module boundaries within scrypath_ops), but scrypath_ops is not yet large enough to justify the overhead. Revisit at v2 if the integrations namespace grows to 3+ modules and cross-integration calls appear.

**Recommended CI step:**

```yaml
- name: Namespace fence — no Sigra refs in scrypath core
  run: |
    if grep -r "Sigra\." --include="*.ex" lib/; then
      echo "ERROR: Sigra.* reference found in lib/scrypath/ (core must stay auth-agnostic)"
      exit 1
    fi
```

A second step can enforce that Sigra refs outside the integration namespace in scrypath_ops are also flagged, but that is a v1.18 phase-planning decision — the core grep covering `lib/scrypath/` is the non-negotiable fence.

---

## Installation Delta

**`scrypath_ops/mix.exs` — single line to add:**

```elixir
{:sigra, "~> 0.2", optional: true}
```

No other changes to mix.exs. No new dev-only or test-only deps required in scrypath_ops itself beyond what is already present.

**`examples/phoenix_sigra_ops/mix.exs` — new file, deps block:**

```elixir
{:scrypath_ops, path: "../../"},
{:sigra, "~> 0.2"},
{:phoenix, "~> 1.8"},
{:phoenix_live_view, "~> 1.1"},
{:ecto_sql, "~> 3.12"},
{:postgrex, ">= 0.0.0"},
{:phoenix_html, "~> 4.1"},
{:bandit, "~> 1.5"},
{:jason, "~> 1.2"},
{:lazy_html, ">= 0.1.0", only: :test}
```

---

## Integration-Point File Paths

New files within `scrypath_ops/`:

```
scrypath_ops/lib/scrypath_ops/integrations/sigra/operator_context.ex
scrypath_ops/lib/scrypath_ops/integrations/sigra/on_mount.ex
scrypath_ops/lib/scrypath_ops/integrations/sigra/gating.ex
scrypath_ops/test/scrypath_ops/integrations/sigra/operator_context_test.exs
scrypath_ops/test/scrypath_ops/integrations/sigra/on_mount_test.exs
scrypath_ops/test/scrypath_ops/integrations/sigra/gating_test.exs
```

Modified files:

```
scrypath_ops/mix.exs                                    (add {:sigra, "~> 0.2", optional: true})
scrypath_ops/lib/scrypath_ops/security.ex               (add :sigra to allowed_opsui_auth_modes/0)
scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex (gate delete handler)
scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex (gate retry handler)
scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex  (gate swap-live actions)
scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex (gate swap-live actions)
.github/workflows/ci.yml                                (namespace-fence grep step)
```

New docs/examples:

```
guides/integrations/sigra.md
examples/phoenix_sigra_ops/            (new standalone Phoenix app)
```

**Files NOT touched:** anything under `lib/scrypath/` — zero changes to the published hex package.

---

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Version constraint | `~> 0.2` | `~> 0.2.4` | Patch pin unnecessary — forces adopters to hold a specific patch; `~> 0.2` allows bugfix patches freely |
| Compile guard | `Code.ensure_loaded?/1` | `Code.ensure_compiled?/1` | Deprecated; wrong semantics (for intra-project ordering, not external deps) |
| Namespace fence | CI grep | `Boundary` hex library | Boundary is overkill for one integration namespace; grep is consistent with existing CI style |
| Example test deps | None new | `bypass`, `mox`, `plug_cowboy` | Not needed: integration is in-process, LiveViewTest covers UI, Bandit already used |
| Integration packaging | In-repo optional namespace | New `scrypath_sigra` hex package | Premature — defer until 3+ public modules or second integration appears |

---

## Sources

- `sigra/mix.exs` — version `0.2.5`, dep list (lines 90–123)
- `sigra/CHANGELOG.md` — release history `0.2.0`–`0.2.5`, dates 2026-04-20–2026-04-25
- `sigra/lib/sigra/session.ex` — `%Sigra.Session{}` struct fields (lines 63–85)
- `sigra/lib/sigra/audit.ex` — `log_safe/3` signature (lines 119, 143); scope duck-typing (line 130, 154)
- `sigra/lib/sigra/plug/` — confirms RequireSudo, ForbidDuringImpersonation, RequireAdminAccess all exist
- `sigra/lib/sigra/*.ex` — `Code.ensure_loaded?/1` usage pattern (16 occurrences confirmed)
- `sigra/lib/mix/tasks/sigra.install.ex` — `mix sigra.install` generator scope (lines 1–58)
- `scrypath_ops/mix.exs` — existing dep set (lines 41–65)
- `scrypath/mix.exs` — confirms `scrypath` version `0.3.4`, no Sigra reference
- hex.pm/packages/sigra/versions — published version list (0.2.0, 0.2.1, 0.2.2, 0.2.3, 0.2.4)
- Elixir official docs (hexdocs.pm/elixir/Code.html) — `ensure_loaded?/1` vs `ensure_compiled/1` semantics
- elixir-lang/elixir issue #8970 — `Code.ensure_loaded?` cannot guard `use` macro expansion
- Elixir Forum — `Code.ensure_compiled?/1` deprecation confirmation
- `~/.claude/plans/so-i-m-considering-rippling-ladybug.md` — approved architectural plan (files-to-touch table, optional dep + compile guard decisions)
