# Domain Pitfalls: v1.36 Dependency Security Remediation

**Domain:** Security maintenance across independent Elixir/Mix dependency graphs
**Researched:** 2026-08-21
**Confidence:** HIGH for repository-specific resolution and gate risks; MEDIUM for deployment-only runtime reachability.

## Critical Pitfalls

### Pitfall 1: Treating the four applications as one lock graph

**What goes wrong:** A root `mix deps.get` or lockfile update is taken as proof that the advisories are fixed everywhere. `mix.lock`, `scrypath_ops/mix.lock`, `examples/phoenix_meilisearch/mix.lock`, and `examples/scrypath_ecommerce/mix.lock` resolve separately, so vulnerable versions can remain in three projects.

**Why it happens:** The apps use local path dependencies and share broad requirements, which makes their graphs look coupled while Mix locks each project independently.

**How to avoid:** Give each batch ownership of exactly one manifest/lock graph. From that project directory, run `mix deps.get`, inspect its resolved versions, and record that its recorded advisory set is absent before proceeding. Do not carry a lockfile from another graph into the batch.

**Warning signs:** `mix deps.get` continues to print an advisory after root succeeds; `git diff` lacks the graph’s own `mix.lock`; a command is launched from the repository root when the batch requires an example directory.

**Stop / rollback boundary:** Stop the current batch if its own resolver retains an affected package, requires an unplanned major/minor line, or edits another graph. Revert only the uncommitted current batch; do not amend a previous green batch.

**Phase to address:** Batch 1 owns root; Batch 2 owns legacy Phoenix; Batch 3 owns Ops; Batch 4 owns ecommerce.

---

### Pitfall 2: Broad unlocking or stale artifacts create a false resolution result

**What goes wrong:** `mix deps.update`, `deps.unlock --all`, or a broad clean advances unrelated packages; conversely, stale `_build` output lets a test exercise an older compiled dependency. The resulting diff either exceeds the security fix or gives misleading green evidence.

**Why it happens:** Mix’s resolver follows declared ranges, not the advisory ledger’s intended minima; build artifacts are not evidence of the lockfile currently under review.

**How to avoid:** Start from the committed lockfile and change only the declared constraints required by the ledger. Review `mix deps.tree` and `git diff -- mix.exs mix.lock` after resolution. If diagnosis needs cleaning, use a named dependency or named build artifact only; `mix deps.clean` is intentionally destructive and must never be a routine broad cleanup. Recompile after any targeted clean.

**Warning signs:** Unrelated direct/transitive packages move, the diff contains `deps.unlock --unused` fallout, compilation shows no dependency rebuild after a lock change, or CI succeeds only with an existing cache.

**Stop / rollback boundary:** Stop if the resolver changes packages outside the recorded path without a documented necessity. Restore the current batch’s manifest and lockfile rather than accepting package-head drift.

**Phase to address:** Every batch; Batch 1 establishes the diff-review procedure.

---

### Pitfall 3: Updating Req only in the lockfile or assuming 0.5 → 0.6 is invisible

**What goes wrong:** `req` remains declared as `~> 0.5` in root/Ops/ecommerce, so a future resolve downgrades it back to a vulnerable line; or Req 0.6 changes expose request/test assumptions in the core Meilisearch client and its extensive `Req.Test` plug stubs.

**Why it happens:** The root library and both web/client apps declare Req directly, while the legacy example receives it through the local root path dependency. A lockfile-only fix masks the public compatibility constraint.

**How to avoid:** In Batch 1, change root to `~> 0.6.1` and prove the core request paths using the existing service-free tests. In Batches 3 and 4, make the same direct-constraint change in their manifests. Do not add a direct Req dependency to the legacy example merely to force its lock; resolve it through its local `{:scrypath, path: "../.."}` dependency. Audit production Swoosh configuration because Ops explicitly uses `Swoosh.ApiClient.Req`.

**Warning signs:** a manifest still says `~> 0.5`; tests using `Req.Test.stub/2` or `plug: {Req.Test, ...}` fail; request options produce warnings; production mail config no longer starts.

**Stop / rollback boundary:** Stop if a test failure requires application-code changes outside the maintenance scope, or if a public Req constraint cannot resolve on the supported Elixir/OTP tuple. Keep the prior published constraint until the compatibility break has a separately approved fix.

**Phase to address:** Batch 1 owns the core/API constraint; Batch 3 owns Ops mail-client behavior; Batch 4 validates it through mounted ecommerce.

---

### Pitfall 4: Solving Decimal without its Ecto/Ecto SQL contract

**What goes wrong:** Batch 2 tries to unlock `decimal` from 2.3.0 alone. The legacy example’s resolved `Ecto 3.13.5` declares the Decimal 2 line, creating an unsatisfiable graph or a partial fix that future resolution undoes.

**Why it happens:** Decimal is transitive, but the vulnerable fixed minimum is `3.0.0`; the required compatibility move is the Ecto/Ecto SQL 3.14 line as a coordinated graph upgrade.

**How to avoid:** Make Batch 2 explicitly own `ecto`, `ecto_sql`, and `decimal` together. Resolve the smallest 3.14-compatible line, review Ecto/Ecto SQL release notes before modifying requirements, then run the example’s test alias so migrations, Repo startup, casts, and sandbox setup compile against the new contract.

**Warning signs:** `mix deps.get` reports conflicting Decimal requirements; only `decimal` changes in the lockfile; `ecto.create`, migrations, or tests fail after a previously green compile.

**Stop / rollback boundary:** Stop on any conflict or migration/test regression; do not paper over it with an override or lockfile edit. Revert the whole legacy-example batch, preserving the already-green root batch.

**Phase to address:** Batch 2 only.

---

### Pitfall 5: Under-testing Phoenix/Bandit/LiveView changes as a compile-only upgrade

**What goes wrong:** Fixed versions resolve, but the web server, endpoint parser, LiveView socket/navigation, WebSocket handling, or Postgres-backed test startup regresses. This is especially risky for Bandit `1.11 → 1.12`, Phoenix `1.8.5/1.8.7 → 1.8.9`, and LiveView `1.1.31 → 1.1.33`.

**Why it happens:** The vulnerable surfaces are runtime inbound HTTP/2/WebSocket/request-parser paths. Compilation cannot prove the apps boot, the endpoint accepts a connection, or mounted LiveView behavior remains compatible.

**How to avoid:** Use each app’s real test alias, not a bare root test: legacy `cd examples/phoenix_meilisearch && mix deps.get && mix test`; Ops `mix verify.opsui`; ecommerce `cd examples/scrypath_ecommerce && mix deps.get && mix e2e.prepare` plus the advisory `phase105-e2e` browser lane when services are available. Treat unavailable Postgres/Meilisearch as missing evidence, not a passing substitute.

**Warning signs:** `Bandit.PhoenixAdapter` startup errors, socket/LiveView tests fail, `Plug.Parsers` errors, an Ecto repo cannot create/migrate, flaky browser connection failures, or a test passes only because it did not reach the app process.

**Stop / rollback boundary:** Stop the web graph at the first runtime-gate failure. Preserve its patch as an uncommitted diagnostic only; do not combine it with later graphs or blame the service until service health/logs prove that conclusion.

**Phase to address:** Batch 2 owns legacy server behavior; Batch 3 owns Ops endpoint/LiveView/mailer behavior; Batch 4 owns browser and mounted-app behavior.

---

### Pitfall 6: Breaking ecommerce through its mounted path dependencies

**What goes wrong:** Ecommerce resolves fixed external packages but fails because it mounts both root Scrypath and `scrypath_ops` by path. An Ops graph that is green in isolation may be incompatible when compiled as a dependency of the ecommerce app.

**Why it happens:** Batch 4 has three relevant sources of code and two different lockfile perspectives. The ecommerce compiler list also includes `:phoenix_live_view`, so client/server asset and LiveView assumptions meet in this graph.

**How to avoid:** Keep Batch 4 separate after Batch 3 is committed. From ecommerce, run `mix deps.get` and inspect its own lock, then run `mix e2e.prepare` before starting browser tests. Preserve the existing test-server contract: `SCRYPATH_E2E_NO_SANDBOX=1` is only for the long-running browser server; preparation/tests retain sandbox isolation.

**Warning signs:** path dependency is reported stale, a root-only test is green while ecommerce compilation fails, `e2e.prepare_search` fails, or browser tests cannot see seeded data because the sandbox/server environment was changed.

**Stop / rollback boundary:** Stop Batch 4 if path dependency compilation or preparation fails. Do not modify the parent graphs to make ecommerce resolve unless the earlier batch’s own gates are rerun and the scope is re-approved.

**Phase to address:** Batch 4 only.

---

### Pitfall 7: Calling the advisory feed clean before reproducing it in every cwd

**What goes wrong:** The milestone is declared closed from a stale, changed, or root-only security-feed result. Conversely, a feed outage is misreported as a clean result.

**Why it happens:** Advisory data is external and changes over time; the acceptance criterion is specifically the recorded advisory set reproduced by `mix deps.get` on 2026-08-16, not an unqualified claim that no advisory exists anywhere.

**How to avoid:** Before and after each batch, capture the exact `mix deps.get` output from the owning project cwd and compare the affected package versions against the triage ledger. If the feed is unavailable, retain the lockfile/version evidence and mark advisory-feed confirmation pending; retry in CI or when service returns.

**Warning signs:** no dated command output; `mix deps.get` cannot contact the feed; advisories disappear without the affected lock package moving; a report says “all clear” but does not name all four projects.

**Stop / rollback boundary:** Do not close the milestone while any graph lacks either a successful feed result or a documented feed-outage exception plus verified fixed versions. An outage blocks closure, not implementation of an already-green batch.

**Phase to address:** Every batch, with final closeout owning the four-graph evidence matrix.

---

### Pitfall 8: Losing the maintenance boundary through non-atomic commits

**What goes wrong:** Multiple graph upgrades, source refactors, docs changes, generated assets, or an opportunistic package-head update land together. A regression cannot be attributed or safely reverted, and Release Please gets a misleading release unit.

**Why it happens:** The packages overlap transitively and all vulnerabilities feel related, but their runtime and rollback surfaces differ materially.

**How to avoid:** Use exactly four commits in ledger order: root, legacy example, Ops, ecommerce. Each commit includes only its manifest/lock changes and any narrowly required compatibility fix; all stated gates must pass before the next starts. Keep the required root release-truth gates after every root-affecting batch.

**Warning signs:** one commit modifies more than one project’s lockfile without stated ownership; `git status` contains generated browser artifacts or unrelated planning/docs edits; an earlier batch has no recorded green gate; a later batch is started while the current one is unresolved.

**Stop / rollback boundary:** Stop before committing if the diff crosses the current batch boundary. Revert the single offending commit if it has landed; never squash all four into one recovery commit.

**Phase to address:** Roadmap orchestration and every batch handoff.

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|---|---|---|---|
| Lockfile-only Req upgrade | Small diff | Next resolver returns to vulnerable 0.5; public requirement lies | Never |
| `deps.unlock --all` / package-head refresh | One resolver run | Unreviewable transitive behavior changes and unclear advisory causality | Never for this milestone |
| Root-only verification | Fast feedback | Leaves three independently locked graphs vulnerable/unproven | Only as a precheck, never as batch acceptance |
| Treating `phase105-e2e` as required | Strong-looking guarantee | Changes established CI posture and blocks maintenance on an advisory lane | Never; run it as available evidence |
| Broad cache/build deletion | Sometimes clears a local issue | Destroys diagnosis and may hide an unnecessary re-resolve | Only targeted, named diagnostic cleanup |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|---|---|---|
| Req / Mint / hpax | Upgrade Req but do not verify its transitive HTTP stack in the owning lockfile | Resolve `Req 0.6.1+`, `Mint 1.9.3`, and `hpax 1.0.4` per graph; run client tests |
| Phoenix / Bandit / LiveView | Consider `mix compile` proof of endpoint safety | Boot/migrate/test each web app and run browser evidence for ecommerce when services are available |
| Ecto / Ecto SQL / Decimal | Add a Decimal override | Align the legacy example’s Ecto/Ecto SQL 3.14 line so Decimal 3 is a real solver result |
| Swoosh | Ignore it because local test uses `Swoosh.Adapters.Test` | Check Ops production’s `Swoosh.ApiClient.Req` and keep Swoosh at `1.26.3+` |
| Path dependencies | Test `scrypath_ops` only from `scrypath_ops/` | Also resolve and prepare ecommerce, which consumes Ops and root through paths |
| Advisory service | Equate service failure with zero findings | Keep version evidence and mark feed confirmation pending until rerun |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|---|---|---|---|
| Re-running all services before each resolver tweak | Slow, noisy feedback and unrelated flakes | Use service-free batch gates first; run service/browser proof only after resolution is stable | Immediately in local iteration |
| Cache-only confidence | A green build that did not recompile changed deps | Confirm lock diff and fresh compile; targeted-clean only if evidence is ambiguous | Any dependency upgrade |
| Parallel graph edits | Conflicting lockfiles and unclear attribution | Strictly serialize the four batches and commits | As soon as a shared path dependency changes |

## Security Mistakes

| Mistake | Risk | Prevention |
|---|---|---|
| Claiming advisories fixed from root only | HIGH: web examples retain known vulnerable packages | Require dated `mix deps.get` evidence for all four cwd-owned graphs |
| Upgrading past minima without review | MEDIUM/HIGH: avoids one CVE but adds untested runtime changes | Use recorded fixed-compatible minima; stop on accidental transitive unlocking |
| Treating disabled/unavailable services as pass | HIGH: hides Phoenix/Bandit/LiveView and Meilisearch client regressions | Mark live/browser evidence unavailable, collect logs/health proof, and rerun in CI |
| Relaxing sandbox/server flags during E2E repair | MEDIUM: test isolation and browser data visibility regress | Preserve the documented `SCRYPATH_E2E_NO_SANDBOX` boundary |

## "Looks Done But Isn't" Checklist

- [ ] **Root Req fix:** root `mix.exs` says `~> 0.6.1`, not only root `mix.lock`.
- [ ] **Four graph closure:** each owning cwd has post-change `mix deps.get` evidence with the recorded advisories absent (or a documented feed outage awaiting retry).
- [ ] **Legacy Decimal remediation:** Ecto, Ecto SQL, and Decimal resolve together; no override masks a conflict.
- [ ] **Ops behavior:** `mix verify.opsui` proves Postgres-backed app startup/tests and root required gates remain green.
- [ ] **Ecommerce mount:** ecommerce resolves both path dependencies, completes `mix e2e.prepare`, and retains the advisory browser evidence boundary.
- [ ] **Runtime service evidence:** a missing Postgres/Meilisearch service is reported as unavailable, never silently counted as pass.
- [ ] **Atomic release history:** four isolated, independently green commits exist in recorded order.

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---|---|---|
| Accidental broad unlock | MEDIUM | Discard only the current uncommitted graph diff; re-resolve from its committed lock with minimal declared constraints |
| Req compatibility failure | MEDIUM | Keep Batch 1 uncommitted, reduce to fixed-compatible 0.6.x, inspect upstream change notes, and add only a scope-approved compatibility patch |
| Ecto/Decimal solver conflict | MEDIUM | Revert the entire Batch 2 graph; align Ecto/Ecto SQL before asking Decimal to move |
| Ops/ecommerce runtime regression | HIGH | Preserve logs and exact lock diff, revert the one batch, and reproduce in its owning cwd/service lane |
| Advisory-feed outage | LOW implementation / MEDIUM release | Preserve fixed-version and gate evidence; rerun `mix deps.get` when feed access returns before closure |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---|---|---|
| Independent lock graph / Req public constraint / stale artifacts | Batch 1 — Root core client | Root resolver, warning-as-error compile, fast tests, `mix verify --exclude integration`, phases 11 and 99 |
| Ecto–Decimal conflict / legacy server runtime | Batch 2 — Legacy Phoenix example | Example-cwd `mix deps.get && mix test`, then root fast tests |
| Phoenix/Bandit/LiveView/Swoosh runtime | Batch 3 — ScrypathOps | `mix verify.opsui` plus root required gates |
| Mounted path coupling / E2E sandbox and service evidence | Batch 4 — Ecommerce | Ecommerce-cwd resolution, `mix e2e.prepare`, advisory `phase105-e2e` or documented service-unavailable result |
| Feed drift and non-atomic history | Cross-batch closeout | Four dated resolver outputs, package-version matrix, and four separate commits |

## Sources

- Repository advisory ledger: `.planning/quick/260816-tzr-triage-dependency-security-advisories-re/260816-tzr-ADVISORY-TRIAGE.md` (HIGH)
- Repository triage research and pending remediation task: `.planning/quick/260816-tzr-triage-dependency-security-advisories-re/260816-tzr-RESEARCH.md`; `.planning/todos/pending/2026-08-16-remediate-dependency-security-advisories.md` (HIGH)
- Repository manifests, verification commands, CI and runtime configuration: `mix.exs`, `scrypath_ops/mix.exs`, both example `mix.exs` files, `CONTRIBUTING.md`, and `.github/workflows/ci.yml` (HIGH)
- [Ecto 3.14 changelog](https://github.com/elixir-ecto/ecto/blob/master/CHANGELOG.md) and [Ecto SQL 3.14 changelog](https://hex.pm/packages/ecto_sql/3.14.0/files/CHANGELOG.md) (MEDIUM, official current sources)
- [Mix `deps.clean` documentation](https://hexdocs.pm/mix/main/Mix.Tasks.Deps.Clean.html) and [Req.Test documentation](https://hexdocs.pm/req/0.4.11/Req.Test.html) (MEDIUM, official documentation)

---

*Pitfalls research for: Scrypath v1.36 dependency security remediation*
*Researched: 2026-08-21*
