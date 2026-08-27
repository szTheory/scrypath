# Phase 159 Historical Parent-Probe Receipt

**Scope:** bounded, immutable Git topology checks for the Phase 148–158
characterization/extraction claims. This is a receipt, not a reconstruction of
intent. D-07 permits exactly one class per claim; D-08 requires a relevant test
to both exist and pass at the extraction parent before a claim may be called
`historically proven`.

## Primary checkout preservation

- **Recorded at:** 2026-08-26T20:09:12Z
- **Primary HEAD:** `f214f7e1d1141fe83be12f5651c9ecb6c54c17a7`
- **Primary branch:** `gsd/v1.37-code-quality-ratchet`
- **Initial user-owned paths:**
  - modified `.planning/phases/134-under-iterated-surface-polish-dual-theme-s/134-UAT.md`
  - modified `.planning/phases/136-milestone-verification-uat-s-g/136-UAT.md`
  - untracked `.planning/phases/159-close-v1-37-audit-gaps-coverage-wiring-and-verification-prov/.gitkeep`
  - untracked `.planning/research/.cache/`
- **Primary old-revision execution:** none. Every old-revision command below ran
  only in its registered detached worktree.

The same four user-owned status entries were present after all probes. The
primary branch and HEAD did not change. `git worktree list --porcelain` reported
only the primary checkout after cleanup.

## Finite candidate inventory

The inventory is deliberately capped to the four production/extraction commits
identified by the Phase 148–158 quality ledger and their actual production diffs:

| Candidate | Requirement area | Extraction commit | Production paths / reason included | Observable-contract test selected |
|---|---|---|---|---|
| Runtime-safety boundary | SAFE-01–SAFE-05, TEST-02 | `b098b9c0cae6c6b195752288eceba6f5a5101415` | `lib/scrypath/meilisearch/settings.ex`, `.../tasks.ex`, `.../oban/enqueue.ex`, `telemetry.ex`; mixed production/test safety change | `test/scrypath/meilisearch/settings_test.exs` — settings input handling is caller-observable |
| Core orchestration extraction | ARCH-01–ARCH-04, ARCH-07–ARCH-08 | `4f0f35408abe8179f49c8efc7a6f99ec0bece0fb` | composition, settings wire, operations, search, failed-work and related-worker leaves; the broad internal extraction | `test/scrypath/composition_test.exs` — supported `Ecto.Multi` composition outcomes are observable |
| Strict-analysis follow-up | SAFE-04–SAFE-05, ARCH-08 | `ab0ed4a604fdabf176e958a4f0dc15bf2c6f3bff` | `lib/scrypath/meilisearch/tasks.ex` and failed-work translation; tightened task/translation behavior | `test/scrypath/meilisearch/tasks_test.exs` — task paging/error vocabulary is observable |
| Options extraction | ARCH-05–ARCH-06 | `4f650b9f9826ef1d7db84b185523b7a02e00f7fd` | `lib/scrypath/options.ex` split into focused settings/search/faceting modules | `test/scrypath/options_test.exs` — public option validation and error/result behavior is observable |

No range traversal, `git log` history scan, or full suite was performed for a
candidate. This list is the entire probe budget; it does not claim to enumerate
every ordinary change in the milestone.

## Probe method and environment

For each fully resolved parent, a unique root from
`mktemp -d /tmp/scrypath-159-probe.XXXXXX` was created outside the primary
checkout. The bounded sequence was:

```sh
git worktree add --detach "$PROBE_DIR" "$PARENT_SHA"
git -C "$PROBE_DIR" ls-files --error-unmatch "$TEST_PATH"
cd "$PROBE_DIR" && MIX_ENV=test mix test --warnings-as-errors "$TEST_PATH"
git -C "$PROBE_DIR" status --short
git worktree remove --force "$PROBE_DIR"
rmdir "$TEMP_ROOT"
```

- **UTC probe time:** 2026-08-26T20:09:12Z
- **Environment:** Elixir 1.19.5, Mix 1.19.5, Erlang/OTP 28 (erts-16.3)
- **Secret handling:** commands and receipts record paths, SHAs, versions, and
  bounded tails only; no environment values or credentials were emitted.

## Parent-probe receipts

| Candidate | Extraction SHA | Parent SHA | Test path / selector | `ls-files` at parent | Focused command / exit | Result and D-07 class | Limitation |
|---|---|---|---|---|---|---|---|
| Runtime-safety boundary | `b098b9c0cae6c6b195752288eceba6f5a5101415` | `bc2f59a6afc3be3e7b5a381c72b2e3a97857b187` | `test/scrypath/meilisearch/settings_test.exs` / whole file | present (exit 0) | `MIX_ENV=test mix test --warnings-as-errors test/scrypath/meilisearch/settings_test.exs` / exit 1 | **historically unprovable** — parent test execution did not pass | Parent cannot reproduce because locked dependency `ecto_sqlite3` is unavailable; same-commit test edits cannot repair the missing pre-extraction proof. |
| Core orchestration extraction | `4f0f35408abe8179f49c8efc7a6f99ec0bece0fb` | `e0a930f3ab69550dc2a7c2f60ec546781ba2a799` | `test/scrypath/composition_test.exs` / whole file | present (exit 0) | `MIX_ENV=test mix test --warnings-as-errors test/scrypath/composition_test.exs` / exit 1 | **historically unprovable** — parent test execution did not pass | Parent cannot reproduce because locked dependency `ecto_sqlite3` is unavailable; file presence alone is insufficient under D-08. |
| Strict-analysis follow-up | `ab0ed4a604fdabf176e958a4f0dc15bf2c6f3bff` | `ac260eec6a0b6d02d804c957f9f692d576236792` | `test/scrypath/meilisearch/tasks_test.exs` / whole file | present (exit 0) | `MIX_ENV=test mix test --warnings-as-errors test/scrypath/meilisearch/tasks_test.exs` / exit 1 | **historically unprovable** — parent test execution did not pass | Parent cannot reproduce because locked dependency `ecto_sqlite3` is unavailable; later/current successes cannot substitute. |
| Options extraction | `4f650b9f9826ef1d7db84b185523b7a02e00f7fd` | `93e1b47313d96083b7777a696d23698142b4f7fd` | `test/scrypath/options_test.exs` / whole file | present (exit 0) | `MIX_ENV=test mix test --warnings-as-errors test/scrypath/options_test.exs` / exit 1 | **historically unprovable** — parent test execution did not pass | Parent cannot reproduce because locked dependency `ecto_sqlite3` is unavailable; no chronology inference is made from commit subjects or files. |

Each detached tree was clean immediately before its explicit registered-worktree
removal. The focused command failed in the dependency check before executing the
selected test; its bounded diagnostic was: `ecto_sqlite3 (Hex package) the
dependency is not available, run "mix deps.get"`.

There are consequently **no historically proven rows**: none records both a
successful parent `ls-files` result and a passing focused test at that parent.
The classification is fail-closed rather than an assertion that the old behavior
was absent.

## TEST-01 waiver candidate

The original requirement remains unchanged:

> **TEST-01**: Characterization tests lock behavior before each extraction.

The narrow waiver candidate is limited to the unrecoverable historical ordering
predicate for the four finite extraction candidates above: their parent snapshots
contain the selected test files but cannot execute them in this environment due to
the unavailable locked `ecto_sqlite3` dependency. It does **not** waive present
behavior, test quality, test-file existence, or future review discipline. The
requirement must not be described as historically passed/satisfied from current
tests, same-commit test edits, filenames, messages, or intent.

## Prospective convention (D-12)

For future observable-contract extractions, reviewable Git/PR history should show
a passing test-only commit before the extraction-only commit and identify the
affected contract and CI run. This is lightweight review guidance only; it creates
no permanent enforcement system or new gate.
