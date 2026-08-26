# Phase 148: Quality Baseline - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-26
**Phase:** 148-quality-baseline
**Areas discussed:** Ledger lifecycle, Characterization bar, Diagnostic strictness, Coverage evidence

---

## Ledger lifecycle

| Option | Description | Selected |
|--------|-------------|----------|
| Committed milestone-scoped Markdown ledger | One canonical ranked view, updated in place with Git history and linked evidence | ✓ |
| GitHub issue per finding | Strong collaboration and ownership, but fragments the milestone-wide ranked view | |
| One ADR/report per finding | Strong audit trail for durable decisions, but too much churn for routine findings | |

**User's choice:** The user asked the agent to research all areas and make one coherent recommendation; the committed milestone-scoped ledger was selected.
**Notes:** GitHub issues remain linked escalation records for collaborative work. ADRs are reserved for durable public API, security, or release-policy decisions.

---

## Characterization bar

| Option | Description | Selected |
|--------|-------------|----------|
| Risk-based observable-contract matrix | Black-box-first characterization with a passing test-only commit before extraction | ✓ |
| Changed-files coverage gate | Automatable proxy, but cannot prove pre-refactor behavior and encourages test padding | |
| White-box call-graph lock-in | Fast and narrow, but freezes the architecture being improved | |
| End-to-end-only characterization | Realistic boundary proof, but too slow and coarse for all contracts and failure paths | |

**User's choice:** The user delegated the decision; the risk-based observable-contract matrix was selected.
**Notes:** Examples explain named scenarios, properties cover broad invariants, and a small set of real Ecto/Oban/Meilisearch paths prove genuine boundaries. Private module topology is explicitly not a contract.

---

## Diagnostic strictness

| Option | Description | Selected |
|--------|-------------|----------|
| Uniform strictness with no exceptions | Simple rule, but creates false-positive churn for intentionally loaded support files | |
| Tiered fatal diagnostics with exact exceptions | Fatal actionable warnings, narrowly audited support discovery, and isolated optional-dependency proof | ✓ |
| Advisory warnings or blanket suppression | Low immediate friction, but hides misnamed tests and downstream compile failures | |

**User's choice:** The user delegated the decision; tiered fatal diagnostics with exact exceptions was selected.
**Notes:** Compile and test warnings require separate flags. Telemetry tests use module callbacks and cleanup. CI promotion/topology remains owned by later phases.

---

## Coverage evidence

| Option | Description | Selected |
|--------|-------------|----------|
| Built-in informational Mix report | Dependency-free fast-suite report with console and HTML output, no threshold | ✓ |
| Hosted ExCoveralls trend/PR reporting | Better history and annotations, but adds dependency, service, and policy overhead | |
| Required global/per-file thresholds | Easy to enforce, but rewards test padding and cannot prove operational contracts | |
| No coverage reporting | Avoids vanity metrics, but loses a useful way to spot unexecuted code | |

**User's choice:** The user delegated the decision; built-in informational Mix coverage was selected.
**Notes:** Coverage gaps are review prompts. They become work only after mapping to a credible risk in the quality ledger. Hosted/trend/branch tooling is deferred until a real maintainer need appears.

---

## the agent's Discretion

- The user explicitly requested a one-shot, expert recommendation across all four areas and did not want to choose each tradeoff manually.
- The agent selected the exact ledger lifecycle, characterization sequencing, diagnostic exception policy, coverage tooling posture, and coherent cross-cutting quality principle after parallel ecosystem research.
- Exact ledger-ID syntax, characterization-record location, and coverage artifact retention remain implementation discretion within the captured constraints.

## Deferred Ideas

- Hosted coverage dashboards, PR annotations, historical trends, branch coverage, and mutation testing pending demonstrated maintainer need.
- Mechanical CI enforcement of characterization-record structure pending evidence that the lightweight convention is repeatedly missed.
- CI gate promotion, job matrices, and branch-protection topology remain owned by later phases.
- ScrypathOps UI/visual/brand review remains outside this non-UI milestone.
