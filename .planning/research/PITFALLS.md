# Pitfalls Research — v1.18 Sigra Integration

**Domain:** Optional auth/audit integration into existing Phoenix LiveView ops dashboard
**Researched:** 2026-04-25
**Confidence:** HIGH — based on direct source inspection of `sigra/` and `scrypath_ops/` call sites

---

## Critical Pitfalls

### Pitfall 1: Silent Attribution Drift

**What goes wrong:** A new sensitive LiveView event ships (e.g., a "bulk-retry" button added to `failed_sync_live.ex`), the author handles it directly in `handle_event` without calling `gate_sensitive_action/3`. No compile error. No test failure. The audit trail is silently incomplete until an incident occurs and the row isn't there.

**Why it happens:** `gate_sensitive_action/3` is voluntary. There is no compiler or type system enforcement that a `handle_event` touching Tier-1 or Tier-2 actions passes through the funnel. The risk compounds over time as the LiveView grows.

**Warning signs in practice:** An operator disputes an action occurred; the audit query for `scrypath.ops.*` returns no matching row for that time window. Or: a new `handle_event` clause added in a PR that nobody cross-references against the sensitive-action taxonomy in the guide.

**Prevention (layered):**

1. **CI grep gate (Phase 71)** — Add a step to `ci.yml` that greps `scrypath_ops/lib/scrypath_ops_web/live/` for `handle_event` clauses matching the known sensitive action names (`confirm_delete`, `run_now`, `run`, `retry_failed`, `swap_live`, `hot_apply`) and asserts each co-occurs in a file that also contains `gate_sensitive_action`. This is a text-level check, imperfect but fast and loud.

2. **Sensitive-action registry (Phase 71)** — Define a module attribute `@sensitive_actions ~w(confirm_delete run_now ...)a` in a shared contract module. The grep CI step reads from this list, not a hardcoded string, so adding a new sensitive action forces updating the registry (one place).

3. **Test-mode audit assertion (Phase 72)** — In the worked example's test suite, add an `ExUnit` assertion that verifies a `[:sigra, :audit, :log]` telemetry event fires during each Tier-1 action. This catches the case where gate wiring exists but the audit emit inside `gate_sensitive_action/3` is broken. Pattern: attach a telemetry handler in `setup`, fire the action, assert handler received the event.

4. **Boundary lib (defer)** — The `boundary` hex package would let you declare that only modules under `ScrypathOps.Integrations.Sigra.*` may call `Sigra.*` — enforced at compile time. This prevents the namespace leakage but does not prevent an event handler from bypassing the funnel entirely. Worth adopting in v1.19 if the surface grows; not worth the setup overhead for v1.18.

**Phase:** 71 (integration module + CI gate). Test-mode assertion in Phase 72 (worked example).

---

### Pitfall 2: PII Leakage Through OperatorContext or Audit Metadata

**What goes wrong:** `%Sigra.Session{}` has `ip`, `user_agent`, `parsed_ua`, `geo_city`, `geo_country_code` (see `sigra/lib/sigra/session.ex:36–44`). The `OperatorContext` builder reads from `%Sigra.Session{}`. If the builder copies any of those fields or a future developer adds them thinking "useful context," PII enters the internal contract and may be forwarded to telemetry, logs, or audit metadata.

Separately: `Sigra.Audit.log_safe/3` accepts an arbitrary `:metadata` map (see `sigra/lib/sigra/audit.ex:494`). The `Gating` module calls it with a metadata map it constructs. If that map includes any `OperatorContext` fields beyond IDs (or if a developer passes `session.ip` as context), PII enters the audit row. Sigra's changeset enforces forbidden *credential* keys (`password`, `token`, etc. — see `sigra/lib/sigra/audit/changeset.ex:18–24`) but does **not** block PII fields like `ip` or `email`.

**Warning signs in practice:** A GDPR audit request requires scrubbing audit rows that contain IP addresses. A crash report contains `geo_city` in inspect output of a socket assign.

**Prevention:**

1. **`OperatorContext` typespec enforces IDs-only (Phase 71)** — The struct has only `user_id`, `active_org_id`, `impersonator_user_id`, `sudo_at`. No string fields that could carry PII. Add a `@type` spec listing exactly those four fields. Dialyzer catches any builder attempt to assign an unlisted field.

2. **OperatorContext unit test: no PII fields (Phase 71)** — In `OperatorContextTest`, assert that the built struct does not contain keys `:ip`, `:user_agent`, `:geo_city`, `:geo_country_code`, `:email`, `:name`. Use `Map.keys/1` and `assert field not in keys`. This fails loudly if the builder grows.

3. **Audit metadata contract (Phase 71)** — Define the permitted metadata map for each `scrypath.ops.*` event as a module attribute or a `@doc` spec in `Gating`. Example: `scrypath.ops.reindex` metadata = `%{schema: string(), cutover: boolean()}`. Code review checklist item: metadata map must only contain operation context, never session context.

4. **`log_safe/3` PII note in guide (Phase 73)** — `guides/integrations/sigra.md` must call out explicitly: the `:metadata` map in `Sigra.Audit.log_safe/3` is NOT sanitized for PII (only for credentials). The caller (Gating) is responsible for keeping metadata to operational context only.

**Phase:** 71 (struct + builder + unit tests). 73 (guide callout).

---

### Pitfall 3: Compile Guard Mistakes

**What goes wrong:** Several failure modes exist with `Code.ensure_loaded?/1`:

*Mode A — Guard wraps the function but not the module-level alias.* If `on_mount.ex` has `alias Sigra.Session` at module top level and the guard only wraps the function body, the alias expands at compile time when Sigra is absent, causing a compile error in hosts without `:sigra`.

*Mode B — Guard wraps the function but not the `@spec`.* `@spec log_safe(String.t(), %Sigra.Session{}, opts()) :: :ok` expands `Sigra.Session` at compile time. Even with a runtime guard, the typespec fails.

*Mode C — `if Code.ensure_loaded?` used instead of `@compile` or a macro-time check.* `Code.ensure_loaded?/1` is evaluated at compile time when used in a module body, but the branch it controls is still parsed and macro-expanded. Module references inside the false branch will cause compile warnings or errors if the module is missing, depending on Elixir version.

*Mode D — `optional: true` in `mix.exs` treated as sufficient.* `optional: true` only means the dep is not required transitively. A host that doesn't add `:sigra` will still get a compile error if the integration module has top-level references to `Sigra.*`.

**The correct Elixir pattern for optional integrations (HIGH confidence from Elixir core docs):**

```elixir
# In mix.exs: {:sigra, "~> 0.2", optional: true}

# In the integration module:
# 1. NO top-level alias to Sigra.*
# 2. NO @spec referencing Sigra.* types directly
# 3. Guard at the module definition level using @compile or Code.ensure_loaded?

if Code.ensure_loaded?(Sigra.Session) do
  defmodule ScrypathOps.Integrations.Sigra.OnMount do
    # Sigra.* references safe here
    def on_mount(:default, _params, _session, socket) do
      session = socket.private[:sigra_session]  # runtime, not compile-time ref
      ...
    end
  end
else
  defmodule ScrypathOps.Integrations.Sigra.OnMount do
    def on_mount(:default, _params, _session, socket), do: {:cont, socket}
  end
end
```

The `if Code.ensure_loaded?` wraps the *entire* `defmodule` block — not just function bodies. This ensures the absent-Sigra branch is fully isolated from any Sigra type references.

**Warning signs in practice:** `mix compile` succeeds in the dev environment (`:sigra` present) but fails in a consumer app that didn't add `:sigra`. The error is a cryptic `Sigra.Session is undefined` at compile time.

**Verification (Phase 71):** The plan's verification checklist (`so-i-m-considering-rippling-ladybug.md:148`) requires `mix compile` succeeds in `scrypath_ops` with Sigra absent. This must be an explicit CI step using `mix deps.unlock sigra && mix compile` in a parallel job or by removing sigra from deps temporarily.

**Phase:** 71 (all compile guard implementation and CI verification).

---

### Pitfall 4: Async Attribution Breaking Across Process Boundaries

**What goes wrong:** `gate_sensitive_action/3` captures `OperatorContext` from `socket.assigns` and stores it in the process dictionary for the duration of the action — so that the telemetry handler in the host app can read it. This works when the action runs synchronously in the LiveView process. It breaks when:

- `PlaybookLive` uses `start_async/3` (see `playbook_live.ex:751`) to run `Runner.run_validated/3` in a **separate process**. The process dict is not inherited.
- `PostureLive` uses `Task.async_stream/3` (see `posture_live.ex:72`) for `Scrypath.sync_status/2` calls.
- Any future Oban job dispatched from within a sensitive action.

**Real call sites at risk:**

- `playbook_live.ex:751` — `start_async(@playbook_run_async_key, fn -> Runner.run_validated(...) end)` — the anonymous function closes over `draft`, `allowlist`, `scrypath_opts` but NOT the current process's dictionary. The runner executes in a Task process with a clean dictionary.
- `posture_live.ex:72` — `Task.async_stream/3` — read-only posture check, not a sensitive write action. Lower risk but the same pattern.
- `Scrypath.Reindex.run/2` (see `reindex.ex:16`) — synchronous with `maybe_wait_for_result_task`. Does not spawn; waits inline. Attribution survives IF the caller passes it through opts. Not a process boundary risk itself, but the host may wrap it in a `Task` or Oban job.

**The correct pattern for `start_async` attribution:** Capture `operator_context` in the closure explicitly before spawning, pass it as a local variable:

```elixir
operator_ctx = socket.assigns[:operator_context]
start_async(socket, :run, fn ->
  # operator_ctx is captured in closure — no process dict needed
  result = Runner.run_validated(draft, allowlist, opts)
  {result, operator_ctx}  # return with context for handle_async
end)
```

In `handle_async`, emit the audit event using the returned `operator_ctx`, not the process dictionary. This keeps attribution deterministic across the async boundary.

**Phase:** 71 (design the attribution pattern for `gate_sensitive_action/3` to handle the async case). 72 (wiring in LiveViews including `playbook_live.ex` where `start_async` is used for `run` and `run_now`).

---

## Moderate Pitfalls

### Pitfall 5: Sudo Window Confusion and Missing Confirm Route

**What goes wrong:**

*Scenario A — Host configures `sudo_window: 60`.* Sigra's default is 300s (`sigra/lib/sigra/plug/require_sudo.ex:46`). The plan uses Sigra's default in `gate_sensitive_action/3`. If the host app sets a shorter window via `Sigra.Plug.RequireSudo`, a 90-second-old sudo confirmation passes the plug in the router but fails the gate's freshness check (which independently re-checks `session.sudo_at`). The operator gets a redirect loop: plug passes → gate redirects → they re-confirm → 5 seconds pass → gate passes this time. This is confusing but not catastrophic.

*Scenario B — Host hasn't configured a sudo confirm route.* `gate_sensitive_action/3` does `push_navigate(to: host_sudo_confirm_path)`. If that path doesn't exist, the LiveView crashes or shows a dead route. The operator sees a generic error.

*Scenario C — Re-auth during a triage flow.* Operator is 4 minutes into diagnosing a sync drift. They click "swap live." They get redirected to sudo confirm. They confirm and are push-navigated back. The navigation wipes the LiveView state (e.g., selected schema, loaded diff). The corrective action they were about to take is now invisible.

**Warning signs in practice:** Operators report being "stuck in a login loop." Or: clicking a sensitive action on a fresh session fails unexpectedly when `sudo_window` is tighter than the guide's assumed 300s.

**Prevention:**

1. **Guide documents the sudo_window contract (Phase 73)** — `guides/integrations/sigra.md` must state: "If your host configures a `sudo_window` shorter than 300s in `RequireSudo`, pass the same value as `:sudo_window` when configuring `gate_sensitive_action/3`. Mismatched windows cause confusing redirect behavior."

2. **Explicit sudo confirm route validation at boot (Phase 71)** — `Gating` reads the configured `:sudo_confirm_path` from application config. If `OPSUI_AUTH_MODE=sigra` and no `:sudo_confirm_path` is configured, raise at compile/boot time with a clear message: `"ScrypathOps Sigra integration requires :sudo_confirm_path in config :scrypath_ops, :sigra_opts"`.

3. **`return_to` preservation (Phase 72)** — The `push_navigate` to the sudo confirm route must pass `?return_to=/ops/...` (or equivalent) so the host confirm route can redirect back. The guide's worked example must demonstrate this round-trip; the example's CI smoke test must assert the operator lands back on the correct page after confirming.

**Phase:** 71 (boot validation). 72 (return_to wiring in LiveViews). 73 (guide contract).

---

### Pitfall 6: Impersonation and Read Operations

**What goes wrong:** `ForbidDuringImpersonation` (see `sigra/lib/sigra/plug/forbid_during_impersonation.ex`) is a Plug — it runs at the HTTP/WebSocket connection level, before the LiveView mounts. It blocks sensitive mutations on routes where it's applied. But it only blocks the routes the host *explicitly* applies it to.

The v1.18 plan applies `ForbidDuringImpersonation` at the `gate_sensitive_action/3` level inside the LiveView — not at the router pipeline. This means the router passes the impersonating admin into every `scrypath_ops` LiveView. Read operations (posture, sync drift, search playground, playbook catalog) succeed for impersonation sessions. The admin sees the ops dashboard as the impersonated user's environment.

**Is this a bug?** The `Sigra.Impersonation` module docs (`sigra/lib/sigra/impersonation.ex:10`) treat impersonation as a full session. Admins are expected to have read visibility. The risk is that `scrypath_ops` dashboards may reveal sensitive operational data (which schemas are configured, what the reindex schedule is) that the impersonated user wouldn't normally see. Whether this is acceptable depends on the host's security model.

**The actual bug pattern:** An impersonating admin views the playbook catalog and loads a playbook, then attempts to run it. The run goes through `gate_sensitive_action/3`, which correctly blocks the Tier-1 run. But the load and preview actions (which are reads) go through without a gate — and they display full schema allowlist info. If the host's security model says impersonated sessions should not see operational config, reads should also be restricted.

**Prevention:**

1. **Guide documents the read-visibility decision (Phase 73)** — State explicitly that `gate_sensitive_action/3` blocks mutations but not reads. Hosts that want to restrict ops dashboard visibility during impersonation must add the `ForbidDuringImpersonation` plug to the `scrypath_ops` router pipeline.

2. **`OnMount` impersonation check for optional read restriction (Phase 71)** — The `OnMount` hook can assign `:impersonation_active?` to the socket. LiveViews that want to show a banner ("You are viewing as [user]") or restrict read access can pattern-match on this assign. Providing the assign costs nothing; using it is optional.

**Phase:** 71 (assign in OnMount). 73 (guide clarification).

---

### Pitfall 7: Audit Prefix Collision Risk

**What goes wrong:** The plan uses `scrypath.ops.*` as the audit action prefix. Sigra's current reserved prefixes (`sigra/lib/sigra/audit.ex:39`) are: `auth.`, `session.`, `mfa.`, `oauth.`, `api.`, `account.`, `sigra.`. None collide with `scrypath.ops.*`.

But Sigra's reserved prefix list is configurable (the host can override `reserved_prefixes:` in audit opts). More critically: if Sigra adds `ops.` to its default reserved list in a future version, `scrypath.ops.reindex` would be silently swallowed by `log_safe/3` (which no-ops on validation failure — see `sigra/lib/sigra/audit.ex:114–117`, the `do_log_safe` path returns `:ok` on changeset invalid). The audit row is never written; no error is raised.

**Warning signs in practice:** Audit query returns no rows for `scrypath.ops.*` events that should have fired. The telemetry `[:sigra, :audit, :log_safe_error]` event fires instead with `reason: :invalid_changeset`.

**Prevention:**

1. **Contract test asserting `scrypath` is not in reserved prefixes (Phase 71)** — Add a test in `scrypath_ops/test/scrypath_ops/integrations/sigra/audit_contract_test.exs`:

```elixir
test "scrypath.ops prefix is not in Sigra default reserved prefixes" do
  reserved = Application.get_env(:sigra, :audit, [])
    |> Keyword.get(:reserved_prefixes, ~w(auth. session. mfa. oauth. api. account. sigra.))
  refute Enum.any?(reserved, &String.starts_with?("scrypath.ops.reindex", &1))
end
```

2. **Version pin in `scrypath_ops/mix.exs` (Phase 71)** — `{:sigra, "~> 0.2", optional: true}` already pins the minor. This prevents a silent `0.3` upgrade from changing reserved prefixes. Do not loosen to `">= 0.2"`.

3. **Telemetry handler for `log_safe_error` (Phase 73)** — The guide's telemetry snippet should attach a handler for `[:sigra, :audit, :log_safe_error]` that logs a warning with the action name. This makes prefix collisions visible in server logs rather than silent.

**Phase:** 71 (contract test + version pin). 73 (guide telemetry handler).

---

### Pitfall 8: Worked Example Rot

**What goes wrong:** `examples/phoenix_sigra_ops/` ships in Phase 73 as a CI smoke target. Over subsequent milestones, changes to `scrypath_ops` or Sigra's API break the example without anyone noticing because the CI job is either not run or not required to pass.

The existing `phoenix-example-integration` CI job (`ci.yml:299`) shows the pattern: it runs `mix verify.adopter --live` with live services. The `phoenix_sigra_ops` example is simpler (no Meilisearch) but still requires Postgres (for Sigra's session/audit tables) and correct env vars.

**Warning signs in practice:** The example README describes a flow that no longer works because a module was renamed or a config key changed. A adopter follows the guide, hits a compile error in the example, and loses trust.

**Prevention:**

1. **Dedicated CI job for the sigra example (Phase 73)** — Add `sigra-ops-example` job to `ci.yml` that runs inside `examples/phoenix_sigra_ops/`, runs `mix deps.get && mix compile --warnings-as-errors && mix test`. Require Postgres in the service block (for Sigra). This is the minimum smoke gate.

2. **Path gate like the existing `scrypath-ops-path-check` (Phase 73)** — Only run on `push` to main or when `examples/phoenix_sigra_ops/` or `scrypath_ops/` paths change. Avoids running the full Postgres job on every unrelated PR.

3. **Pin the example's Sigra dep to match `scrypath_ops/mix.exs` (Phase 73)** — If `scrypath_ops` uses `{:sigra, "~> 0.2"}`, the example must use the same constraint. Drift in version pins is how examples silently test a different API surface.

**Phase:** 73 (all example creation and CI wiring).

---

### Pitfall 9: Boundary Leakage on the Sigra Side

**What goes wrong:** The hard constraint is that Sigra must remain unaware of Scrypath. A contributor to either repo might add a helpful `alias Scrypath` or `import ScrypathOps` inside the Sigra codebase — perhaps in a test, perhaps in a comment that becomes real code. This silently violates the boundary.

**Warning signs in practice:** `grep -r "Scrypath" /Users/jon/projects/sigra/lib` returns a hit. The `sigra` package now has a transitive knowledge of the Scrypath API, making it impossible to ship Sigra without the Scrypath context.

**Prevention:**

1. **CI grep in the Sigra repo (Sigra-side, not v1.18 scope)** — A `grep -r "Scrypath" lib/` step in Sigra's own CI. This is a Sigra-repo concern, not something v1.18 can enforce.

2. **Namespace-discipline note in the v1.18 guide (Phase 73)** — `guides/integrations/sigra.md` should document: "If you are contributing to Sigra itself, do not add references to Scrypath modules. The boundary is maintained by convention and Sigra's own CI grep."

3. **Code review checklist item (Phase 71)** — The `CONTRIBUTING.md` or the phase's acceptance criteria should include: "PRs touching `examples/phoenix_sigra_ops/` or `scrypath_ops/integrations/sigra/` must not add any `Scrypath.*` reference inside `lib/sigra/` or `lib/sigra/**`."

**Phase:** 71 (checklist). 73 (guide note). Sigra-side CI is out of scope for v1.18.

---

## Minor Pitfalls

### Pitfall 10: "Optional Becomes Mandatory" Documentation Trap

**What goes wrong:** Once `guides/integrations/sigra.md` exists and `examples/phoenix_sigra_ops/` is in CI, adopters reading the docs may believe Sigra is required to use `scrypath_ops`. The hex.pm `scrypath_ops` description or the README doesn't clearly distinguish optional integrations from core behavior.

**Warning signs in practice:** An adopter opening an issue: "I can't get scrypath_ops to compile — it keeps complaining about Sigra being missing." They saw the integration guide, assumed it was required, and didn't add `:sigra` to their mix.exs as an optional dep.

**Prevention:**

1. **"Optional integrations" section in `scrypath_ops` README (Phase 73)** — Explicit section: "Sigra integration (optional) — if you use Sigra for auth, wire the integration module. If you don't, nothing changes." Contrast with the default `basic` and `proxy_headers` auth modes.

2. **`guides/overview.md` wayfinding (Phase 73)** — The integrations guide should appear under an "Optional integrations" heading, not in the main navigation flow that implies it's on the critical path.

3. **Sigra guide opening sentence (Phase 73)** — `guides/integrations/sigra.md` must open with: "This guide is for hosts already using Sigra for authentication. Scrypath ops works without Sigra." This prevents the cargo-cult "I need Sigra to use scrypath_ops" misread.

**Phase:** 73 (all guide and docs work).

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|---|---|---|
| Phase 71: Integration module + compile guard | Compile guard wraps function bodies but leaves top-level `alias Sigra.*` — breaks hosts without `:sigra` | Wrap the entire `defmodule` block, not just function bodies |
| Phase 71: OperatorContext builder | PII fields copied from `%Sigra.Session{}` into struct | Unit test asserting no PII keys in built struct |
| Phase 71: `gate_sensitive_action/3` async pattern | `start_async` closure loses process dict attribution | Capture `operator_context` in closure before spawning, return with result |
| Phase 71: Audit prefix contract test | No test = silent prefix collision if Sigra updates reserved list | Contract test + `[:sigra, :audit, :log_safe_error]` telemetry watch |
| Phase 72: LiveView wiring | New `handle_event` clauses added later bypass the gate | CI grep on sensitive action names; sensitive-action registry module attribute |
| Phase 72: Sudo confirm navigate | Missing `return_to` param causes operator to lose LiveView state after re-auth | `push_navigate` must always include `return_to`; smoke test asserts round-trip |
| Phase 73: Worked example | Deps pinned differently from `scrypath_ops/mix.exs` | Pin example's Sigra dep to exact same constraint |
| Phase 73: Guide | Reads not gated during impersonation not documented | Explicit statement in guide; optional read-restriction via router plug |

---

## Sources

- `sigra/lib/sigra/session.ex` — PII field inventory (`:ip`, `:user_agent`, `:geo_city`, `:geo_country_code`)
- `sigra/lib/sigra/audit.ex:39` — `@default_reserved` prefix list (no `ops.` prefix)
- `sigra/lib/sigra/audit/changeset.ex:18–24` — forbidden credential keys only (no PII restriction)
- `sigra/lib/sigra/plug/require_sudo.ex:46` — `@default_sudo_window 300`
- `sigra/lib/sigra/plug/forbid_during_impersonation.ex` — plug-level only, not LiveView-level
- `sigra/lib/sigra/impersonation.ex` — impersonation session is a full session
- `scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex:751` — `start_async` boundary
- `scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex:72` — `Task.async_stream` boundary
- `scrypath_ops/lib/scrypath_ops/security.ex` — existing auth mode allowlist
- `scrypath_ops/lib/scrypath_ops_web/live/on_mount.ex` — existing OnMount stub
- `.github/workflows/ci.yml` — existing CI job patterns for path gating and example smoke
- `~/.claude/plans/so-i-m-considering-rippling-ladybug.md` — approved architectural plan

---
*Pitfalls research for v1.18 Sigra integration*
