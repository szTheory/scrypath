# v1.50 prep A: milestone choice, order and release plan (2026-11-25)

Research only. `.planning/reference/ROLLING-ROADMAP.md` still needs the update AGENTS.md requires.

## Recommendation

**Open v1.50 as the adopted "Adopter-ready", and put "the documented first search must work" ahead of the testing guide.** Confidence: milestone choice 0.85, added correctness work 0.8, release plan 0.85.

This reverses no recorded decision. It **adds** scope to v1.50, and any root `lib/` change is ask-first.

**New lead (code reading plus vendor docs, not run).** `guides/golden-path.md` searches with `filter: [status: "published"]` and `sort: [desc: :inserted_at]`, which on a fresh install should fail, for three reasons:
1. The guide has no step that applies index settings; in `lib/`, I found only `reindex.ex` calling `apply_settings`.
2. Even then, `sortable:` is never sent (F4): `meilisearch/settings.ex` merges only filterable and faceting.
3. The schema declares `fields: [:title, :body]`, and `projection.ex` projects only `fields`, so documents lack `status` and `inserted_at`.

Meilisearch docs require both attribute lists before filtering or sorting. I found no test that sorts against a real backend. The README quick path uses neither.

## Size and order

| Step | Content | Plans | Gate |
|---|---|---|---|
| 0 (not a milestone) | Land the advisory patch commit (local only when checked). Close #52 if a read-only parity check on 0.3.10 is clean | 0 | required checks |
| 199 | Fresh-consumer walk against published 0.3.20 using only HexDocs, including filter, sort and writing a test. Then fix what it reproduces: golden path, F4, F1 | 2 to 3 | planted failure; the guide's own search against real Meilisearch |
| 200 | "Testing your app" guide (no new API), written against fixed behavior; **cut line**; release 0.3.21 | 1 to 2 | compiled snippets; explicit yes |
| 201 (cut by default) | API grilling, then highlight/crop or paging guard | 0, or 2 | maintainer session |

Default 4 to 5 plans (recorded: 3 to 5). If 201 runs, expect 6 to 7; stop and re-ask beyond 7.

- The walk goes first because it needs the unfixed published state (planned as a v1.49 side task; I found no result). Fix as soon as it reproduces the bug.
- The docs half of the fix needs no `lib/` permission. If the maintainer declines `lib/` changes: correct the guide (add the fields, an explicit `settings:` sortable list and a settings/reindex step) and record F4 and F1 as known limits.

## Sibling items, ordering only

| Item | Slot | Why |
|---|---|---|
| F4, golden path | 199, first | first hour |
| F1 (history error past 1,000 tasks) | 199, second; smallest honest fix | library bug on busy installs; also misleads an agent reader |
| F2, D2 | v1.51, or small `chore(ops-ui)` PRs | unpublished UI; F2 is low to medium exposure |
| F3 (swap tasks invisible) | v1.51, only if a cutover story is wanted | needs design; no first-hour effect |
| SEED-005 | stays a seed; weigh when v1.51 is chosen, short ADR first | not approved scope; JSON is a public contract; the view modules it wants to share sit in `scrypath_ops`, outside the Hex package; truthfulness depends on F1, F2, D2 |

The maintainer called AI use "very important". Moving SEED-005 ahead of v1.51 or v1.52 reorders the adopted roadmap: their call.

## Release and versioning

- **Now: no release.** All 26 commits since `scrypath-v0.3.20` are `docs`, `chore` or `test`. The advisory patch is lock-only and does not change what consumers resolve; none of the three packages is a direct runtime dependency in root `mix.exs`.
- **0.3.21 at the end of Phase 200**: fixes, guide, and the unreleased HexDocs regroup. Aim before **2026-12-21** (time-box in the adopted post-v1.48 proposal). If the `lib/` fix will miss it, ship the guide correction alone.
- Mechanics: the first `fix:` merge opens the release PR; leave it open until the guide lands. Bot PRs need close/reopen or `update-branch` for CI. Explicit yes to merge. ScrypathOps-only work keeps `chore`/`test` titles.
- Upgrade note for F4: sortable attributes apply at the next settings apply or reindex, which costs backend indexing work. Merge as a union with explicit `settings:`.
- `verify.release_publish` proves a clean consumer compiles, not that search works; the Phase 199 live test covers that before merge.
- **0.4.0 with the first new public API** (already recommended in `catalog-prep/G-roadmap-after-catalog.md` and the post-v1.48 proposal). Under current config a `feat:` yields a patch, so use `Release-As: 0.4.0` in the squash commit body, or the `release-as` key and remove it afterwards. **Honest limit:** `~> 0.3` admits 0.4.0, so the number alone protects nobody. The install-line guard will go red until five files move to `~> 0.4`; keep two-part lines (a three-part line fails the guard at the next patch).
- Small doc fix: `docs/releasing.md` ties `!` to "major-version planning", but `bump-minor-pre-major` makes it a minor below 1.0.
- **Cadence:** the proposed rule in `docs/releasing.md` is still unadopted. Recommend the maintainer adopt it (bug and security exempt, otherwise 14 days).
- Next CI change: CI-EFFICIENCY item 33, so new advisories stand out in the red lane.

## Adversarial pass

- *"The bug is theoretical."* It has not been run. Meilisearch behavior is from its docs, which give no error text. Reproduce before fixing; if the search works, drop that fix and keep the recorded shape.
- *"This inflates a cuttable milestone."* A concrete bug is a stated reopen trigger. The cut line stays.
- *"Nobody uses it; stay idle."* Idle leaves a broken documented path and contradicts the adopted order. It does cap spending: no 201, no announcement yet.
- *"Changing applied settings is risky."* Yes: union only, upgrade note, no automatic apply.
- *"Walk first delays an obvious fix."* It is bounded and may find more. Its findings are not outside-adopter evidence.

## What would change it

An outside report (jumps the queue). The walk disproving the bug (recorded shape). Maintainer refusing `lib/` changes (docs-only 199). No grilling session (201 stays cut). Maintainer wanting agent operability now (explicit reorder; F1 first anyway).

## Rejected

- **v1.51 catalog breadth first:** reorders the adopted roadmap; ScrypathOps is unpublished.
- **SEED-005 as v1.50:** reorder, unprepared contract.
- **v1.52 announce first:** do not invite people before first search works.
- **Five-feature adopter milestone / public `Scrypath.Testing`:** new public promises, no demand evidence.
- **Idle:** above.
- **Docs-only release today:** nothing releasable; would publish the broken example again.
- **Separate correctness-only milestone:** extra closeout for 2 to 3 plans.

## Facts verified today

- Git: no `BREAKING` or `Release-As` footer since the tag; shipped-file diff is docs, one `lib/scrypath.ex` line, `mix.exs`, `.formatter.exs`.
- `gh`: no open PRs; open issues #86 (decision log) and #52 (0.3.10 parity); no outside issue in the list; 0 stars, 0 forks; 3 views from 2 uniques (14-day window); 0 open Dependabot alerts.
- CI on that main commit's push: required jobs green; longest `ecommerce-mounted` 925 s; `deep-quality` red.
- Hex API: 20 releases, latest 0.3.20 (2026-11-21), 8 of 19 gaps within a day; 1,932 downloads, 217 last week. The only listed dependant is maintainer-owned `cairnloop` 0.5.1, optional, requirement `>= 0.0.0`, so it pins no series.
- Release-please docs (manifest-releaser, README): both pre-major flags, `release-as`, `Release-As:` footer. Elixir `Version` docs: `~> 0.3` reaches below 1.0 (inferred from their table).
- Meilisearch docs: filtering and sorting pages.
- Code read: files named above; `tasks.ex` limit 1,000; `install_line_contract_test.exs`.

## Not verified

Runtime behavior of the golden path, F4 and F1 (no mix, Docker or database). Meilisearch's true task retention (taken from earlier notes). F2, F3, D2 beyond their records (siblings). Issue #52's parity result. Whether anyone outside uses the library. Local test status of the patch commit.
