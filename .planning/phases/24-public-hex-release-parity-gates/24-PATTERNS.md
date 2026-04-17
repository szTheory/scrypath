# Phase 24 — Pattern map

## Files to touch (from CONTEXT + RESEARCH)

| Target | Role | Closest analog |
|--------|------|----------------|
| `release-please-config.json` | Version policy | Current root manifest config + `$schema` |
| `.github/workflows/release-please.yml` | Publish pipeline | Existing `verify.release_publish` step block (copy env pattern) |
| `.github/workflows/publish-hex.yml` | Recovery publish | Same as above |
| `test/mix/tasks/workflow_wiring_test.exs` | Contract tests | `describe "INFRA-01..."` / `UAT-09` patterns |
| `docs/releasing.md` | Maintainer truth | § Canonical Release Flow, § Release parity gate |

## Code excerpts (reference)

**Post-publish verify step pattern** (`release-please.yml` 82–86):

```yaml
      - name: Verify the live published release
        env:
          SCRYPATH_RELEASE_VERIFY_ATTEMPTS: "20"
          SCRYPATH_RELEASE_VERIFY_SLEEP_MS: "15000"
        run: mix verify.release_publish "${{ needs.release-please.outputs.version }}"
```

**Add after the above:** same `env`, `run: mix verify.release_parity "${{ needs.release-please.outputs.version }}"` (CONTEXT D-11).

**Recovery workflow** (`publish-hex.yml` 56–60): mirror with `${{ inputs.release_version }}`.

## Conventions

- YAML: two-space indent, job-level `env` for Hex publish reuse.
- Tests: `File.read!/1` + `=~` / `refute` — no network in unit tests.
