# Phase 186 deferred items

Out-of-scope discoveries logged during execution. Nothing here was fixed by the plan that found it.

## 186-01: `mix docs --warnings-as-errors` is red on this branch before the plan's changes

- **Found during:** the `verify.core` gate on the Plan 01 code commit (step 6 of 6, docs). Steps 1 to 5 passed.
- **Symptom:** two warnings, `documentation references file "AGENTS.md" but it does not exist`, both reported from `CONTRIBUTING.md`. ExDoc then refuses to finish html and epub generation under `--warnings-as-errors`.
- **Cause:** `CONTRIBUTING.md` line 225 links to `AGENTS.md` (`see "Phase workflow defaults" in [AGENTS.md](AGENTS.md)`). That link arrived in `fa8affde` ("docs: record discuss, verify and CI-efficiency workflow defaults"). `fa8affde` is on the local feature branch but not in `origin/main`; `origin/main:CONTRIBUTING.md` has no `AGENTS.md` reference. `AGENTS.md` is not one of the docs extras, so ExDoc cannot resolve the link.
- **Why this plan did not fix it:** Plan 01 touches neither `CONTRIBUTING.md` nor the docs configuration, and the warning text names only that link. It is an unrelated pre-existing failure.
- **Consequence:** the hosted `core` job would fail on the same step once this branch is pushed.
- **Cheapest fixes (maintainer or orchestrator, one line):** write the reference as plain text (`AGENTS.md` without link syntax), or link the repository URL instead of the relative path, or add `AGENTS.md` to the docs extras. Plan 03 edits `CONTRIBUTING.md` for the gate ledger and is a natural place to do it.
  status: acknowledged
