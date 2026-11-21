# Claim owner map

This note names the one surface that owns each claim the README makes or drops. It is the input to Phase 193 (HexDocs regroup and guards) and to the Phase 194 decision (website content). Owners are surfaces, not people.

A secondary surface may repeat a claim in one short line and link to the owner; it never becomes a second owner. Written in Phase 192 Plan 02, before any README claim left the README.

How `test/scrypath/readme_contract_test.exs` reads this file:

- The `Owner` cell is exactly one of `README`, `guide:<slug>` (a guide that is a docs extra in `mix.exs`), `doc:<repo path>` (ARCHITECTURE.md, CONTRIBUTING.md, CHANGELOG.md, mix.exs or a docs/ file), `website` or `retired`. A cell that names two owners fails the test.
- `Pinned by` lists entries separated by `; `, each a backticked repo path, the word `has`, and a backticked token that is a literal substring of that file today. At least one entry names the owner's own file. A retired row has `reason:` and the reason instead. If an owner stops carrying its token, the default test run goes red.
- Entries on `README.md` use only tokens the README trim keeps (Phase 192 Plan 04), so the map itself fails if the trim drops one.

## Owner map

| Claim id | Claim | Owner | README | HexDocs | Website | Pinned by |
|----------|-------|-------|--------|---------|---------|-----------|
| `what-it-is` | Scrypath is the Ecto-native search indexing library that helps Phoenix and Ecto teams add search to existing schemas without hiding the sync work | `README` | the one-sentence opener | the README is the HexDocs landing page | the home page restates it (Phase 194 decides) | `README.md` has `Scrypath, the Ecto-native search indexing library` |
| `website-link` | The public website is a companion front door, not a docs replacement | `README` | one link line | the README | is the link target | `README.md` has `sztheory.github.io/scrypath` |
| `fit` | When Scrypath fits: Ecto-native indexing, one explicit sync choice, repo-backed record loading, backfill and managed reindex | `README` | the "good fit" list | the README | the evaluate page restates it (Phase 194 decides) | `README.md` has `Scrypath is a good fit when you want` |
| `non-fit` | When it does not fit: not a Postgres full-text layer, not Phoenix-only, no public multi-backend facade in v1, no hidden callbacks; Meilisearch-first in v1 with an internal backend seam | `README` | the "not trying to be" list, the Meilisearch-first sentence and the backend-seam phrase | the README; the support guide repeats the multi-backend line | the evaluate page restates it (Phase 194 decides) | `README.md` has `Meilisearch-first in v1`; `README.md` has `not a promised public abstraction`; `README.md` has `Scrypath is not trying to be` |
| `install-line` | The dependency line for the 0.3 series | `README` | the Installation fence | the golden path repeats it; `test/release/install_line_contract_test.exs` checks every install line against the `mix.exs` version | the home page install section (Phase 194 decides) | `README.md` has `{:scrypath, "~> 0.3"}`; `guides/golden-path.md` has `{:scrypath, "~> 0.3"}` |
| `transport-and-oban` | Scrypath owns its internal transport dependency; add Oban only when you choose the Oban sync mode | `README` | one Installation sentence | the getting-started guide repeats the transport sentence | links to owner (Phase 194 decides) | `README.md` has `Scrypath owns its internal transport dependency`; `README.md` has `Add Oban only when you choose` |
| `versioning` | Scrypath follows semantic versioning; the changelog says what each release changed | `README` | one Installation sentence that names semantic versioning and links the changelog | the maintainer release process lives in docs/releasing.md | links to owner (Phase 194 decides) | `README.md` has `semantic versioning`; `docs/releasing.md` has `CHANGELOG.md` |
| `version-source` | Root mix.exs `@version` is the source of truth for a checkout; the latest published package is on hex.pm | `retired` | removed | not needed | not needed | reason: checkout detail for maintainers; the Hex.pm badge the README keeps shows the published version, and docs/releasing.md owns the version checks |
| `operator-ui-status` | The optional operator UI lives in the source checkout and is not part of the Hex package | `README` | one sentence | the support guide links the ScrypathOps production runbook | links to owner (Phase 194 decides) | `README.md` has `operator UI`; `README.md` has `not part of the Hex package`; `guides/support-and-compatibility.md` has `scrypath_ops/README.md#production` |
| `quick-path` | One searchable schema declared with `use Scrypath`, then a first search; the schema matches the golden path | `README` | the Quick Path section | the golden path carries the same schema (Phase 193 checks parity) | links to owner (Phase 194 decides) | `README.md` has `Quick Path`; `guides/golden-path.md` has `field :status, :string` |
| `eventual-consistency` | Accepted work is not the same thing as search visibility | `guide:sync-modes-and-visibility` | the quick-path line before the first code block | the sync guide | the operators page restates it (Phase 194 decides) | `guides/sync-modes-and-visibility.md` has `Accepted work is not the same thing as search visibility` |
| `sync-modes` | The three sync modes and the exact return contract | `guide:sync-modes-and-visibility` | one line | the sync guide | links to owner (Phase 194 decides) | `guides/sync-modes-and-visibility.md` has `exact successful map fields`; `README.md` has `accepted work may not yet be visible in search` |
| `sync-mode-choice` | Which sync mode to pick, and that no mode makes the database and search writes atomic | `guide:sync-modes-and-visibility` | not repeated | ARCHITECTURE.md repeats the atomicity line | links to owner (Phase 194 decides) | `guides/sync-modes-and-visibility.md` has `when durable enqueue matters more than immediate search visibility`; `ARCHITECTURE.md` has `does not make database and search writes atomic` |
| `support-policy` | One current support and readiness authority: supported versions and release-backed guidance | `guide:support-and-compatibility` | links it | the support guide | links to owner (Phase 194 decides) | `guides/support-and-compatibility.md` has `single current support and readiness authority`; `README.md` has `release-backed guidance` |
| `scope-reopen-policy` | Scope reopens only for a concrete production bug, reviewed outside-adopter evidence or a deliberate strategic product decision | `guide:scope-and-reopen-policy` | the three trigger phrases in the support sentence | the scope guide; the support guide links it | links to owner (Phase 194 decides) | `guides/scope-and-reopen-policy.md` has `concrete production bug`; `guides/support-and-compatibility.md` has `scope-and-reopen-policy.md`; `README.md` has `concrete production bug` |
| `proof-spine` | The adopter proof task is a maintainer task that runs from a source checkout and is not runnable from the Hex package | `doc:CONTRIBUTING.md` | not named (the shipped-docs invariant forbids an unqualified mention) | the support guide names it with the source-checkout qualifier | not named | `CONTRIBUTING.md` has `mix verify.adopter`; `guides/support-and-compatibility.md` has `mix verify.adopter` |
| `packaged-artifact-gate` | The packaged-artifact gate and the verify matrix | `doc:CONTRIBUTING.md` | not named | docs/releasing.md owns the publish checks | not named | `CONTRIBUTING.md` has `mix verify.phase11`; `CONTRIBUTING.md` has `docs/releasing.md` |
| `ops-verify-task` | The operator UI check task | `doc:CONTRIBUTING.md` | not named | not named | not named | `CONTRIBUTING.md` has `mix verify.ops_ui` |
| `guide-routes` | Where each guide is, grouped by job | `doc:mix.exs` | at most three onward links | the HexDocs sidebar, grouped by job in `groups_for_extras` | the docs page points at HexDocs (Phase 194 decides) | `mix.exs` has `Guides by task` |
| `reading-order` | A short recommended reading order through the guides | `guide:overview` | one Next Steps link | the overview page | not repeated | `guides/overview.md` has `Recommended reading order`; `README.md` has `overview.html` |
| `public-surface` | The public runtime surface, the explicit backend-specific escape hatch, the private operations seam, `use Scrypath` as metadata only, and the thin mix wrappers | `doc:ARCHITECTURE.md` | not repeated | the module docs | links to owner (Phase 194 decides) | `ARCHITECTURE.md` has `one explicit backend-specific escape hatch`; `ARCHITECTURE.md` has `without creating a second operator product surface`; `guides/golden-path.md` has `is metadata-only` |
| `search-api` | The search call and its result keys: records, hits, missing_ids and page | `guide:golden-path` | the quick path ends in a search call | the golden path | links to owner (Phase 194 decides) | `guides/golden-path.md` has `result.missing_ids`; `guides/golden-path.md` has `result.page`; `ARCHITECTURE.md` has `for stale or missing source rows` |
| `search-hydration` | Record loading is explicit and repo-backed; Scrypath does not infer repos or hide stale rows | `doc:ARCHITECTURE.md` | not repeated | ARCHITECTURE.md | not repeated | `ARCHITECTURE.md` has `Hydration is explicit and repo-backed`; `ARCHITECTURE.md` has `does not infer repos globally` |
| `backfill-and-reindex` | When to backfill and when to use a managed reindex | `guide:drift-recovery` | not repeated | the concepts guide holds the managed-reindex line | links to owner (Phase 194 decides) | `guides/drift-recovery.md` has `Use backfill when`; `guides/meilisearch-concepts.md` has `Use managed reindex when` |
| `reindex-result` | The managed reindex call and its seven result keys | `guide:drift-recovery` | not repeated | the drift guide; ARCHITECTURE.md has the prose | links to owner (Phase 194 decides) | `guides/drift-recovery.md` has `result.settings_applied`; `guides/drift-recovery.md` has `result.omitted`; `ARCHITECTURE.md` has `whether settings were applied` |
| `drift-detection` | Detect drift first: the five signals | `guide:drift-recovery` | not repeated | the drift guide; ARCHITECTURE.md lists the same sources | the operators page restates it (Phase 194 decides) | `guides/drift-recovery.md` has `Detect drift before deciding`; `ARCHITECTURE.md` has `Drift can come from` |
| `rebuild-vs-enqueue` | Durable enqueue is not the same thing as rebuild completion | `guide:drift-recovery` | not repeated | the drift guide | links to owner (Phase 194 decides) | `guides/drift-recovery.md` has `durable enqueue is not the same thing as rebuild completion` |
| `reconcile-not-auto-heal` | Reconcile reports drift and recovery actions and does not heal anything by default | `guide:drift-recovery` | not repeated | the drift guide; ARCHITECTURE.md | the operators page restates it (Phase 194 decides) | `guides/drift-recovery.md` has `does not heal anything by default`; `ARCHITECTURE.md` has `Reconcile is not an auto-heal button` |
| `operator-read-apis` | The four operator APIs on `Scrypath.*` and the report-first reconcile view | `doc:ARCHITECTURE.md` | not repeated | ARCHITECTURE.md; the operator Mix tasks guide | links to owner (Phase 194 decides) | `ARCHITECTURE.md` has `reports backend and queue visibility through Scrypath-owned structs`; `ARCHITECTURE.md` has `combines status visibility, failed work, and reindex visibility` |
| `integration-smoke` | How to run the integration smoke against a real Meilisearch | `guide:golden-path` | not repeated | the golden path; CONTRIBUTING.md has the maintainer commands | not repeated | `guides/golden-path.md` has `scripts/smoke.sh`; `CONTRIBUTING.md` has `meilisearch_smoke` |
| `examples` | The two runnable examples: the Phoenix + Meilisearch walkthrough and the e-commerce demo | `guide:overview` | not repeated | the overview links both example READMEs | not repeated | `guides/overview.md` has `examples/phoenix_meilisearch/README.md`; `guides/overview.md` has `examples/scrypath_ecommerce/README.md`; `guides/golden-path.md` has `examples/phoenix_meilisearch/README.md` |
| `architecture` | The runtime boundary, sync guarantees, drift model and managed reindex order | `doc:ARCHITECTURE.md` | not repeated | ARCHITECTURE.md is a docs extra | not repeated | `ARCHITECTURE.md` has `Backfill And Managed Reindex` |

## README budget

The numbers below are chosen, not measured: no reader study or word-count survey backs them. They exist so a small edit does not trip a test and a large drift does.

| Limit | Value | Basis |
|-------|-------|-------|
| Word cap | 800 words | chosen, not measured; the top of the owner-map target range |
| Target range | 600 to 800 words | chosen, not measured; the range recorded in the Phase 192 context |
| Floor | 400 words | chosen, not measured; a stub guard that fails an accidentally emptied README, not part of the target range |
| Fenced code | 60 lines | chosen, not measured |
| Onward links | at most 3 after the quick path's last code block | chosen, not measured |

## Recorded decisions

| Decision | Reason | Decided |
|----------|--------|---------|
| `guides/overview.md` stays in the HexDocs extras and shrinks to a short recommended reading order. The four-layer list and the 22-row guide table are retired. | Removing the page would end the `overview.html` page in later HexDocs versions and break the README link, the `Scrypath` moduledoc link and the pinned assertions, while the sidebar already is the index. The four-layer list is owned by `ARCHITECTURE.md` and the getting-started guide (rows `public-surface` and `quick-path`), and the table duplicated the sidebar. | 2026-11-21 |

## Not proven

- That these owner assignments are the right ones. The test proves each owner carries the token that pins it, not that the claim belongs there.
- That the README will read better after the trim. No reader, newcomer or independent reviewer judged it.
- That the website restatements marked above agree with their owners. Phase 194 decides what the website carries.
