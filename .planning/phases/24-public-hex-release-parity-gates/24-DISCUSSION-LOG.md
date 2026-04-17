# Phase 24: Public Hex release & parity gates - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `24-CONTEXT.md` — this log preserves the alternatives considered.

**Date:** 2026-04-17
**Phase:** 24 — Public Hex release & parity gates
**Areas discussed:** Semver & Release Please; repo hygiene; SHIP-02 doc scope; verify matrix / publish workflows

---

## Semver and Release Please

| Option | Description | Selected |
|--------|-------------|----------|
| **0.3.1 (patch)** | Matches additive-only story; aligns with Hex pre-1.0 “patch = non-breaking channel” reading; better DX for `~> 0.3.0` pins | ✓ |
| **0.4.0 (minor)** | Default Release Please + `feat:` mapping; “milestone” signal | |
| **1.0.0-pre** | Opt-in pre; suppresses default resolver uptake | |

**User's choice:** Adopted synthesized recommendation: **0.3.1** + Release Please configuration / `Release-As` as needed.
**Notes:** Research noted tension between Conventional Commits minor bumps and Hex’s `0.x` minor-as-breaking documentation; changelog must state non-breaking additive release.

---

## Repo hygiene before release

| Option | Description | Selected |
|--------|-------------|----------|
| **Strict merge-first** | All packaged paths committed to `main` before tag/publish; no dirty-tree exceptions | ✓ |
| **Docs-only exception** | Allow uncommitted docs — rejected: same class as v1.2 divergence for `guides/` / `docs/` | |

**User's choice:** Strict merge-first (including guides and docs).
**Notes:** `release_parity` compares Hex to tag, not laptop to intent; `workspace_clean` intentionally has no escape hatch.

---

## SHIP-02 “dangling 0.3.0” scope

| Option | Description | Selected |
|--------|-------------|----------|
| **Narrow sweep** | User-facing current release + automation pins; preserve historical literals | ✓ |
| **Repo-wide purge** | Remove all `0.3.0` substrings — rejected: breaks audits, CHANGELOG history, parity examples | |

**User's choice:** Narrow policy per CONTEXT **D-06..D-08**.

---

## Verify matrix on publish path

| Option | Description | Selected |
|--------|-------------|----------|
| **Thin publish + post-publish `release_parity`** | Keep `workspace_clean`, `phase11`, Hex, `release_publish`; add `release_parity` after publish on both publish workflows; full phase matrix stays on `ci.yml` | ✓ |
| **Heavy publish** | Duplicate `phase22` etc. on publish — rejected: flake and latency on credential job | |

**User's choice:** Thin publish + add **`release_parity`** to **`release-please.yml`** and **`publish-hex.yml`**; update **`docs/releasing.md`**.

---

## Claude's Discretion

- Exact Release Please JSON keys after upstream schema check.
- Ordering and shared retry env between `release_publish` and `release_parity`.

## Deferred Ideas

- Optional README / extras semver consistency test (low priority).
- Live Meilisearch or expanded integration on publish path (out of scope Phase 24).
