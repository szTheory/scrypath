# Phase 24 — Technical research

**Phase:** 24 — Public Hex release & parity gates  
**Question:** What do we need to know to plan SHIP-01..03 well?

## Findings

### Release Please pre-1.0 bumps (SHIP-01, CONTEXT D-02)

- Default `feat:` on `0.x` often yields a **minor** bump (`0.3.0` → `0.4.0`). Context locks **0.3.1** as the next cut and rejects accidental `0.4.0` without an explicit policy flip.
- **Supported knobs** (verify against pinned `googleapis/release-please-action@v4` + schema in `release-please-config.json`): root-level **`bump-minor-pre-major": true`** and **`bump-patch-for-minor-pre-major": true`** are the usual pair so that on versions `< 1.0.0`, **features bump patch** and **breaking bumps minor** (see [Release Please customizing docs](https://github.com/googleapis/release-please/blob/main/docs/customizing.md) and community Elixir writeups).
- **Escape hatch:** `Release-As: X.Y.Z` footer on a release-triggering commit when maintainers need an exception (CONTEXT D-02, D-03).
- This repo’s manifest-driven config already has `"$schema": "https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json"` — after editing, validate JSON (IDE schema or `jq`).

### Post-publish `release_parity` (SHIP-03, CONTEXT D-11, D-12)

- **`mix verify.release_parity VERSION`** compares Hex tarball paths to git paths under `lib/`, `guides/`, `docs/` for tag `scrypath-vVERSION` (see `lib/mix/tasks/verify.release_parity.ex`).
- **Retry env:** `SCRYPATH_RELEASE_VERIFY_ATTEMPTS` and `SCRYPATH_RELEASE_VERIFY_SLEEP_MS` — mirror the **`verify.release_publish`** step in `.github/workflows/release-please.yml` (already `20` / `15000` ms there).
- **Gap today:** `publish-hex` jobs end after `mix verify.release_publish` — neither **release-please.yml** nor **publish-hex.yml** runs **`mix verify.release_parity`**. Roadmap success criterion #3 and REQUIREMENTS SHIP-03 expect parity on the **release pipeline**; **docs/releasing.md** currently implies parity is mainly **scheduled** `verify-published-release.yml` — needs alignment (CONTEXT D-12).
- **Thin publish matrix (D-10):** add **one** step per workflow; do not copy full `ci.yml` quality matrix onto credential-bearing jobs.

### Workflow wiring tests (existing pattern)

- `test/mix/tasks/workflow_wiring_test.exs` already encodes INFRA/UAT expectations via `File.read!/1` + `=~`.
- **UAT-09** currently documents “feat → 0.4.0” behavior; it **must be rewritten** when pre-1.0 patch policy is enabled so CI does not encode the old assumption (regression trap).

### SHIP-02 narrow sweep (CONTEXT D-06–D-09)

- **In scope for automation in this phase:** `README.md` install snippet (still shows `~> 0.1.0`), `mix.exs` `@version` / `@source_ref` / ExDoc `source_ref` — these advance via **Release Please release PR** plus any **explicit maintainer edits** in the same merge window.
- **Out of scope:** global substring ban on `0.3.0`; historical CHANGELOG, `.planning/`, moduledoc examples that cite `0.3.0` as a time-indexed fact.

### Pitfalls

1. **Parallel edits** to `workflow_wiring_test.exs` — serialize plans or put all test edits in one plan after config lands.
2. **YAML indentation** under `publish-hex` / `publish-scrypath` jobs — match existing step style; use same `env` block as `verify.release_publish`.
3. **Version in tests** — after bump policy + release PR, manifest and `mix.exs` move to `0.3.1`; avoid hard-coding `0.3.1` in tests that run on `main` **before** merge unless tests derive from manifest.

## Validation Architecture

| Dimension | Approach |
|-----------|----------|
| **Automated** | `mix test test/mix/tasks/workflow_wiring_test.exs`, `mix format --check-formatted`, workflow YAML still parses in CI |
| **Manual** | Dry-run `act` / fork publish not required for this slice — maintainers validate Release Please PR + first real publish |
| **Sampling** | After each plan wave: `mix test test/mix/tasks/workflow_wiring_test.exs --warnings-as-errors` |

**Nyquist / Dimension 8:** Every plan task maps to a grep- or test-verifiable condition in `workflow_wiring_test.exs` or file content checks listed in PLAN acceptance criteria.

## RESEARCH COMPLETE
