# Phase 109: Release Train and Package Truth Audit - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-31
**Phase:** 109-Release Train and Package Truth Audit
**Areas discussed:** Release agreement, Hex package shape, Publish proof chain

---

## Release Agreement

| Option | Description | Selected |
|--------|-------------|----------|
| Release Please manifest as canonical release contract | Keep current Release Please manifest-mode flow and tighten audits around `mix.exs`, manifest, changelog, tag checkout, and publish workflow behavior. | yes |
| Tag-first canonical path | Treat the git tag as the sole release authority and add custom checks to prove all files derive from that tag. | no |
| Changesets-centered release contract | Replace Release Please with Changesets-style explicit release-intent files. | no |
| Manual maintainer-cut releases | Remove release-bot authority and rely on human release scripts/runbooks. | no |

**User's choice:** User selected all areas and asked the agent to research deeply with subagents, then provide a one-shot coherent recommendation set.
**Notes:** Advisor research recommended keeping Release Please manifest mode because it fits the current repo, has Elixir release support, preserves release PR reviewability, and avoids bespoke release logic during a maintenance/evidence phase.

---

## Hex Package Shape

| Option | Description | Selected |
|--------|-------------|----------|
| `mix.exs` `package.files` whitelist only | Rely on Hex-native package whitelist as the package-shape contract. | no |
| Unpacked tarball allowlist assertions | Assert expected shipped paths from the actual unpacked Hex artifact. | partial |
| Unpacked tarball blacklist exclusion assertions | Assert high-risk paths such as `scrypath_ops/`, `examples/`, `website/`, `.planning/`, `node_modules`, and Playwright artifacts are absent. | partial |
| Generated package manifest snapshot | Check in a generated package file list and diff it in CI. | no |
| Hybrid proof | Keep `package.files` as intent, assert the unpacked artifact allowlist, and explicitly deny high-risk paths. | yes |

**User's choice:** User delegated recommendation.
**Notes:** Advisor research recommended the hybrid because REL-02 is about what actually ships. `package.files` proves intent; the unpacked Hex artifact proves reality. Snapshot churn is deferred unless focused artifact assertions are inadequate.

---

## Publish Proof Chain

| Option | Description | Selected |
|--------|-------------|----------|
| Always-on CI preflight only | Use `mix verify.phase11` on PR/main and skip live proof in release workflows. | no |
| Canonical post-publish blocking chain | Release Please tag checkout, workspace clean, `verify.phase11`, dry-run publish, real publish, `verify.release_publish`, then `verify.release_parity`. | yes |
| Manual recovery workflow | Keep `publish-hex.yml` as explicit tag/version break-glass replay path. | yes |
| Scheduled ongoing verification | Keep daily/manual published-release checks and issue-on-drift behavior. | yes |

**User's choice:** User delegated recommendation.
**Notes:** Advisor research recommended a layered chain: lean auth-free `verify.phase11` remains the required PR/main gate; live Hex/HexDocs/consumer proof runs after publish; manual recovery mirrors canonical proof; scheduled verification catches later drift.

---

## the agent's Discretion

- Exact implementation mechanism for semantic JSON/YAML parsing versus existing grep anchors.
- Exact artifact path normalization and whether package assertions live in existing release tests or a small helper.
- Exact docs wording as long as `docs/releasing.md` remains maintainer release authority and `CONTRIBUTING.md` remains the contributor command index.

## Deferred Ideas

- Replace Release Please with Changesets or a custom tag-first release system only if future multi-artifact governance justifies it.
- Add a checked-in package manifest snapshot only if focused artifact assertions cannot provide enough auditability.
