# Feature Research

**Domain:** Dependency-security remediation for four independently resolved Elixir/Mix projects
**Researched:** 2026-08-21
**Confidence:** HIGH for required behavior and repository gates; LOW for external advisory-service corroboration

## Feature Landscape

This maintenance milestone has no user-facing product feature to add. Its observable contract is a trustworthy, reviewable security remediation: all four Mix graphs resolve beyond the recorded advisory set, existing behavior remains covered by the established project gates, and the PR leaves an auditable record of exactly what was proven. The 2026-08-16 triage ledger is the fixed scope authority; its fixed minima clear the recorded advisory set, not every newly published package version.

### Table Stakes (Users Expect These)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Four independent clean dependency resolutions | Each directory has its own manifest/lock graph; fixing root Scrypath cannot establish the state of the Phoenix example, ScrypathOps, or ecommerce. | MEDIUM | Run `mix deps.get` in root, `examples/phoenix_meilisearch`, `scrypath_ops` (via `mix verify.opsui`), and `examples/scrypath_ecommerce`. Resolver output must no longer report any advisory recorded in the triage ledger. Do not claim a general absence of all future advisories. |
| Fixed-compatible, bounded upgrades | A remediation must patch the reproduced vulnerable versions without silently converting a maintenance fix into an ecosystem migration. | MEDIUM | Resolve at least: `hpax 1.0.4`, `mint 1.9.3`, `req 0.6.1`, `plug 1.19.5`; web graphs also use the ledger’s `bandit 1.12.1`, `phoenix 1.8.9`, `phoenix_live_view 1.1.33`, `postgrex 0.22.4`, and `swoosh 1.26.3` minima as applicable. The legacy example must align Ecto/Ecto SQL `3.14.x` so `decimal 3.0.0+` can resolve. |
| Preserved core-library behavior | Consumers need evidence that the Req/HTTP dependency change did not regress library compilation, fast behavior, package truth, or trust contracts. | MEDIUM | Root batch passes: `mix compile --warnings-as-errors`; `mix test --exclude integration --exclude docs_contract`; `mix verify --exclude integration`; `mix verify.phase11`; and `mix verify.phase99`. These are the current required-merge equivalents documented in `CONTRIBUTING.md`. |
| Preserved legacy Phoenix example behavior | The example is an adopter-facing integration surface; the Ecto/Decimal constraint crossing has the highest regression risk. | HIGH | In `examples/phoenix_meilisearch`, pass `mix deps.get && mix test`, then rerun the root fast test command. Live Phoenix/Postgres/Meilisearch proof remains separately prerequisite-bound rather than being fabricated when services are unavailable. |
| Preserved ScrypathOps behavior | The optional Ops app is a separately locked Phoenix client and must retain its Postgres-backed test contract after web-stack upgrades. | MEDIUM | From root, `mix verify.opsui` must pass; it runs `cd scrypath_ops && mix deps.get && mix test`. Then run the root batch’s required gates. |
| Preserved ecommerce preparation and browser proof | Ecommerce is separately locked and path-mounts ScrypathOps; its upgrade must demonstrate the existing E2E environment can still prepare. | HIGH | Pass root `mix deps.get`, then `cd examples/scrypath_ecommerce && mix deps.get && mix e2e.prepare`. When Postgres, Meilisearch, browser dependencies, and the CI lane are available, run the documented `phase105-e2e` browser checks and retain their standard failure artifacts. |
| Isolated, reviewable evidence | Security changes must be bisectable and must not make a reviewer infer which graph or gate a lockfile change belongs to. | LOW | Deliver exactly four ordered commits: root, legacy Phoenix example, ScrypathOps, ecommerce. Each commit records its command outcomes before the next batch begins. PR dependency review is useful corroboration but does not replace local Mix evidence for all four graphs. |

### Differentiators (Competitive Advantage)

For this maintenance-only milestone, differentiation means unusually clear operational proof rather than new capability.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Explicit proof-boundary report | Maintainers can distinguish deterministic service-free gates from service-dependent browser/live evidence, avoiding false “all green” claims. | LOW | Report required gate status, environment prerequisites, advisory-service output date/source, and whether `phase105-e2e` ran, skipped because prerequisites were absent, or failed. A skipped advisory lane is not a pass. |
| Advisory-to-lockfile traceability | A reviewer can connect every recorded advisory family to its resolved version and introducing graph. | MEDIUM | Preserve the ledger’s ten package families and affected-project matrix; include a before/after `mix deps.get` capture or equivalently exact resolver output per graph. |
| Stop-on-failure sequencing | A compatibility failure is localized to one graph instead of compounded by later upgrades. | LOW | Do not begin the next batch until the previous batch’s required gates pass. Consult upstream release/migration notes before a direct constraint change, especially the Ecto/Decimal alignment. |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Upgrade every dependency to package head | It appears to maximize security freshness in one PR. | It expands regression surface, loses attribution for the recorded remediation, and violates the fixed-compatible/minimal-upgrade decision. | Use the recorded patched minima; open separately justified follow-up work for broader upgrades. |
| A single root-only audit or test run | It is fast and familiar. | The four projects resolve dependencies independently; it cannot prove the other three lockfiles or their runtime contracts. | Resolve and verify each project using its named commands. |
| `ignore_advisories`/environment suppression as “resolution” | It makes `mix deps.get` or `mix hex.audit` quiet. | Hex documents that ignores silence known findings; they are acknowledgments, not patched dependency evidence. | Update to fixed-compatible versions; if an exception becomes necessary, stop and obtain an explicit security decision with rationale and expiry. |
| New permanent CI lanes, scanners, or required checks | It promises stronger ongoing security posture. | It is scope expansion and could destabilize the green-main release train without a separately approved design. | Use existing required gates plus existing advisory/dependency-review evidence; propose new automation only as deferred work. |
| Mandatory live services or manual UAT for every batch | It can sound more thorough. | It confuses reproducible required proof with environment-dependent evidence and conflicts with current advisory `phase105-e2e` posture. | Require service-free gates; run documented live/browser evidence only when prerequisites exist and state the result precisely. |
| Runtime/API, Phoenix UI, or search-backend changes | Upgrades can invite opportunistic cleanup. | These change product scope, invalidate the maintenance premise, and breach the established scope guard. | Keep source changes limited to constraints/lockfiles and minimal compatibility fixes demanded by an upstream upgrade, with any broader change deferred. |

## Feature Dependencies

```text
Recorded advisory ledger + fixed minima
    └──requires──> root resolution and required root gates
                           └──requires──> legacy Phoenix example resolution + tests
                                                        └──requires──> ScrypathOps resolution + tests
                                                                                     └──requires──> ecommerce resolution + E2E preparation

Each batch's passing evidence
    └──requires──> its isolated commit

Service availability ──enables──> live example / advisory phase105-e2e proof
Service availability ──does not replace──> deterministic required gates

Package-head upgrades ──conflicts with──> bounded fixed-minimum remediation
Advisory suppression ──conflicts with──> advisory-cleared acceptance claim
```

### Dependency Notes

- **All four resolution checks require the ledger:** an advisory claim is only meaningful against the recorded affected package/version set and the relevant project’s actual resolver result.
- **Legacy Ecto/Decimal alignment requires its own batch:** Decimal `3.0.0+` cannot be treated as an isolated lockfile bump under the documented Ecto range; migration/release-note review precedes the constraint change.
- **Ecommerce requires ScrypathOps-compatible resolution:** it mounts ScrypathOps through a path dependency, so its own lock graph and browser environment remain distinct verification targets.
- **Evidence requires batch isolation:** reviewers need a clean causal link from a lockfile/manifest diff to the commands that passed for that graph.

## MVP Definition

### Launch With (v1.36)

- [ ] Root batch resolved at the prescribed compatible minima, with all six root commands passing and resolver output free of its recorded advisories.
- [ ] Legacy Phoenix batch resolves its prescribed web/Ecto/Decimal floor and passes its example plus root-fast gates.
- [ ] ScrypathOps batch resolves the prescribed web/client floor, passes `mix verify.opsui`, and passes the root required gates.
- [ ] Ecommerce batch resolves separately, passes `mix e2e.prepare`, and has documented `phase105-e2e`/browser evidence when the required services are available.
- [ ] Four commits, in the authoritative order, contain machine-readable command evidence and no unrelated product, UX, or CI-topology work.

### Add After Validation (v1.36.x)

- [ ] Broader dependency modernization — only after a separate compatibility review identifies a reason beyond these reproduced advisories.
- [ ] Security automation/ruleset changes — only after an approved proposal evaluates false positives, required-check policy, and all four project graphs.

### Future Consideration (v2+)

- [ ] Cross-project dependency-policy tooling — defer until multiple maintenance cycles demonstrate that existing Mix/CI evidence cannot keep all four graphs trustworthy.

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Four clean recorded-advisory resolutions | HIGH | MEDIUM | P1 |
| Per-batch behavior and required-gate proof | HIGH | MEDIUM | P1 |
| Four isolated commits and evidence capture | HIGH | LOW | P1 |
| Service-dependent example/E2E evidence | HIGH | HIGH | P1 when prerequisites exist; otherwise transparently recorded as unavailable |
| Broader upgrades or CI changes | LOW | HIGH | P3 / deferred |

**Priority key:**
- P1: Must have for milestone closure
- P2: Should have, add when possible
- P3: Deferred; not part of this maintenance milestone

## Verification Evidence Model

| Evidence class | Required proof | Pass condition | Boundary |
|---------------|----------------|----------------|----------|
| Resolver/advisory proof | `mix deps.get` in each of the four projects | No warning/report for the advisories recorded in the 2026-08-16 ledger; resolved versions meet the applicable fixed minima | Time-bound to the advisory data and package registry response. Capture command output/date; do not restate it as a timeless “secure” guarantee. |
| Root deterministic proof | Root compile, fast tests, `mix verify`, `phase11`, and `phase99` commands | Every named command exits zero | Required merge-gate confidence; no external service prerequisite. |
| Phoenix example proof | Example `mix deps.get && mix test`, then root fast tests | All commands exit zero | Required for the legacy batch. The separate live integration path needs Postgres/Meilisearch environment variables and reachable services. |
| Ops proof | `mix verify.opsui`, then root required gates | All commands exit zero | Required for the Ops batch; its task exercises the path app with Postgres-backed Ecto setup, no Meilisearch. |
| Ecommerce deterministic proof | ecommerce `mix deps.get && mix e2e.prepare` | Both exit zero | Required preparation proof, not browser functional proof. |
| Ecommerce live/browser proof | Existing `phase105-e2e` CI lane or documented browser commands | Lane/checks complete with actionable artifacts; retries are recorded as flaky rather than clean | Advisory evidence, service- and browser-prerequisite dependent; never substitute a skip for a pass. |
| PR review corroboration | Dependency review of manifest/lockfile diff, when available | No newly introduced vulnerable dependency finding | Helpful external service proof only; it supplements rather than replaces the four resolver outputs and repository gates. |

## Sources

- Repository primary authority: [advisory triage ledger](../quick/260816-tzr-triage-dependency-security-advisories-re/260816-tzr-ADVISORY-TRIAGE.md), [triage verification](../quick/260816-tzr-triage-dependency-security-advisories-re/260816-tzr-VERIFICATION.md), [pending remediation todo](../todos/pending/2026-08-16-remediate-dependency-security-advisories.md), and [contributor/CI contract](../../CONTRIBUTING.md). Confidence: HIGH for this milestone’s scope and commands.
- [Hex `mix hex.audit` documentation](https://hex.hexdocs.pm/Mix.Tasks.Hex.Audit.html) — advisories/retirements yield nonzero status; ignore configuration silences findings. Confidence: LOW from the configured websearch confidence seam; used only to support the anti-feature boundary.
- [Mix `mix test` documentation](https://mix.hexdocs.pm/main/Mix.Tasks.Test.html) — warning-as-error behavior. Confidence: LOW from the configured websearch confidence seam; repository commands remain authoritative here.
- [GitHub dependency review documentation](https://docs.github.com/en/code-security/concepts/supply-chain-security/dependency-review) — PR dependency diffs include indirect lockfile changes and vulnerability data. Confidence: LOW from the configured websearch confidence seam; corroborative only.

---
*Feature research for: Scrypath v1.36 Dependency Security Remediation*
*Researched: 2026-08-21*
