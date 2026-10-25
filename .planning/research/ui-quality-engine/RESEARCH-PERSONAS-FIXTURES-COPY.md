> **2026-10-25:** the twins were renamed to obvious domain names (Wikily, Chatly, Langalern, Budgetly, Shoply) by maintainer direction. The settled decisions are in [RECOMMENDATIONS.md](RECOMMENDATIONS.md) under "Grilling decisions".

# Research: adopter profiles, operator jobs, shared fixtures, verbal tokens

**Date:** 2026-10-25. **Lens:** product/JTBD, UX writing, fixture design (methodology §3, §4 verbal tokens, §6; review rubric items 6–7).
**Status:** research input for the UI quality engine plan. No code changed. Every repo claim cites a path; web sources are listed at the end, each marked as verified (fetched this session) or cited from memory.

---

## 0. Reconcile first: what already exists and what outranks this

| Existing artifact | What it says | How this research treats it |
| --- | --- | --- |
| `.planning/reference/OPERATOR-UI-QUALITY.md` § Experience model (reviewed 2026-10-14) | **The single authority** for roles (`ROLE-INT`, `ROLE-OPS`, `ROLE-OWNER`), jobs (`JOB-01`…`JOB-05`) and the internal-to-user language map. Roles are "task contexts that may overlap, not fictional demographic personas". "Do not invent new personas or duplicate the job table." | **Extend, don't fork.** Operator roles below map onto these IDs. The new adopter material is a different object: it describes the **data an adopter's app indexes**, not the people using the UI. |
| `PRODUCT.md` § Audience and jobs | Points to OPERATOR-UI-QUALITY.md. "Do not duplicate persona or glossary tables here." | Respect it: once accepted, the profiles go in one place (proposal in §3.6), not in PRODUCT.md. |
| `OWNER-INTENT.md` (2026-10-25, newer) | Asks for realistic fixtures "like a digital twin of real adopters… a Slack clone, a language-learning app, a personal finance tool". Says "personas and jobs-to-be-done are curated continuously". | Newer owner direction. It conflicts on its face with "do not invent new personas" (2026-10-14). **Resolution:** call the adopter-side objects **adopter profiles** (fixture data shapes), and keep operator *roles* as the existing task contexts. Both rules then hold. "Twin" is not used elsewhere in `.planning/reference` or `PRODUCT.md`, but "profile" avoids implying a live-synced copy. |
| `.planning/research/v1.42/UI-STRUCTURE.md` § Personas | Four historical personas: On-call engineer, Search owner, Library maintainer, First-run operator. | Historical evidence. It already folds into ROLE-OPS / ROLE-OWNER / first-run setup state. No new authority. |
| `.planning/research/v1.41/ADOPTION-REVIEW.md` § Adopter outcomes | Four adopter jobs: Phoenix SaaS engineer, Catalog engineer, Multi-tenant platform engineer, On-call engineer. | Confirms that multi-tenant and catalog shapes are already product-relevant. It seeds profiles P2 and P5. |
| `examples/scrypath_ecommerce/e2e/UI-REVIEW.md` | Requires review against "the maintained roles/jobs and internal-to-user language map". "Do not copy screenshots, personas, and vocabulary into competing authorities." | The glossary in §4 is written as **additions to the OPERATOR-UI-QUALITY.md language table**, not a second table. |

**Surface names have drifted from the brief.** The rendered UI has **Control Room, Search (with saved searches), Search health, Failed sync work, Sync and index, Help**. The sources are `components/layouts.ex:327`, `nav.ex:17-42` and `router.ex:35-43`; `/playbooks` and `/sync-drift` are now `:legacy` redirects. `DESIGN.md` still says "Sync and drift" and describes "Saved searches" as its own surface. This research uses the rendered names. Fixing DESIGN.md is a copy-consistency finding in its own right (§4.6).

---

## 1. Adopter profiles (the indexed domain)

### 1.1 Equivalence-class axes

A profile earns its place only if it holds a value on some axis that no other profile covers. These are the axes that actually change what ScrypathOps renders.

| Axis | Values that change rendering |
| --- | --- |
| Setup state | unconfigured (no schemas) · configured but backend missing · configured and empty · populated |
| Tenancy | single-tenant · shared index with `tenant_field` (Scrypath's model: `lib/scrypath/options.ex:57`, `examples/scrypath_ecommerce/lib/scrypath_ecommerce/catalog/product.ex:7`) |
| Sync mode | `:inline` · `:oban` · `:manual`. Queue observation is absent by design for inline and manual (`UI-STRUCTURE.md` Posture row). |
| Scale | 1 schema / tens of docs · 2–3 schemas / 10⁵ · 6+ schemas / 10⁷ with 10-digit task uids and a page-boundary count of failed work |
| Script/locale | Latin only · CJK + RTL + emoji in **returned documents** (Search results) and in identifiers the UI shows |
| Failure profile | backend unreachable · Oban retrying/discarded · Meilisearch task `failed` with error code · settings drift + promotion · delete-sync failure |
| Surface emphasis | the JOB that profile's operator most often opens the UI for |

### 1.2 Proposed profiles (5)

All products are fictional. Names were checked against the obvious collision with real companies; replace any that a later search shows to be real. No profile imitates a real brand's UI or ID format.

#### P1 · Wikily: brand-new install (empty)
- **Product:** a self-hosted, single-tenant team docs wiki (Phoenix), installed by one developer for a 12-person team.
- **Why Scrypath:** the wiki already has `Page` Ecto schemas, and the developer wants search without a second indexing model (`JOB-01`).
- **Schemas → index:** `Wikily.Docs.Page` → `quillmark_page`. Prefix-plus-snake naming follows `lib/scrypath/meilisearch/naming.ex:13`.
- **Volume:** 0 documents. The progression is 0 schemas configured → 1 schema with the backend missing → 1 schema with 0 docs → 3 docs after the first sync.
- **Locale:** `en`.
- **Sync:** `:inline`.
- **Failure profile:** none yet. The states are "nothing configured", "Meilisearch URL unreachable", and "index does not exist yet". The UI must distinguish these from "healthy and empty" (`UI-STRUCTURE.md` First-run row; DESIGN.md Do's: "distinguish an empty result from missing configuration").
- **Who opens the UI:** the solo developer, right after `mix deps.get` → `ROLE-INT`, `JOB-01`.
- **Distinct class:** the only profile in the setup-missing/empty state, and the only `:inline` one.

#### P2 · Chatly: B2B hosted multi-tenant team chat (Slack-clone class)
- **Product:** hosted team messaging SaaS with ~3,400 workspaces.
- **Why Scrypath:** message search scoped per workspace; deletes must propagate (users delete messages; workspace offboarding).
- **Schemas → indexes:** `Chatly.Chat.Message` → `hearth_message` (tenant field `workspace_id`), `Chatly.Chat.Channel` → `hearth_channel`.
- **Volume:** 2.1M messages across workspaces and ~600 writes/min at peak; Meilisearch task uids in the 10⁶ range.
- **Locale:** mostly `en`, with emoji-heavy content (👍🏽, ZWJ sequences such as 👩🏽‍💻), @mentions, code snippets and long unbroken URLs in message bodies.
- **Sync:** `:oban`.
- **Failure profile:**
  - a Meilisearch restart produces a burst of `retryable` jobs (attempt 2–4 of 20) and then recovery;
  - one delete-sync job is `discarded` after max attempts, so the "Retry delete sync work" path applies (rendered in `failed_sync_live.ex`);
  - `enqueued`/`processing` backlog during the burst. Pending work alone is not a failure (DESIGN.md).
- **Who opens the UI:** an on-call engineer paged at 02:40 → `ROLE-OPS`, `JOB-03` (Control Room → Search health → Failed sync work → recovery check).
- **Distinct class:** shared-index multi-tenancy at high write rate; delete semantics; transient retry bursts; emoji in returned documents.

#### P3 · Langalern: B2C language learning (CJK/RTL)
- **Product:** a consumer language-learning app for Japanese, Korean, Mandarin, Arabic and Hebrew learners.
- **Why Scrypath:** learners search lessons, cards and example sentences in both the target and the native language; the search owner tunes settings per language.
- **Schemas → indexes:** `KotobaLadder.Courses.Lesson` → `kotoba_ladder_lesson`, `KotobaLadder.Cards.Card` → `kotoba_ladder_card`, `KotobaLadder.Cards.ExampleSentence` → `kotoba_ladder_example_sentence` (a long index name).
- **Volume:** ~180k cards, 9k lessons, 1.2M example sentences.
- **Locale/script:** `ja` (kanji, kana and furigana in a separate field), `ko`, `zh-Hans`, `ar` and `he` (RTL, with mixed-direction strings such as Arabic plus a Latin transliteration), `es`.
- **Sync:** `:oban` for edits and `:manual` for the nightly course import.
- **Failure profile:**
  - **settings drift**: a declared `localizedAttributes`/synonyms/stop-words change differs from live;
  - a managed **reindex → promote target index** (swap) whose effect needs a document-visibility check (`JOB-04`).
  Sync failures are rare.
- **Who opens the UI:** the search owner after a settings PR → `ROLE-OWNER`, `JOB-04`, then `JOB-05` (query 「食べる」 across selected schemas and compare per-target results; save that check).
- **Distinct class:** the only profile whose failure is *configuration* rather than *work*; CJK/RTL in queries, results and saved-search names; multi-schema search.

#### P4 · Budgetly: self-hosted single-tenant personal finance
- **Product:** a self-hosted personal and household finance tracker (one household per install).
- **Why Scrypath:** search over transactions by payee, memo, category and amount. Bank CSV imports arrive in batches, so sync is manual.
- **Schemas → indexes:** `Budgetly.Ledger.Transaction` → `tallyhouse_transaction`, `Budgetly.Ledger.Payee` → `tallyhouse_payee`.
- **Volume:** 48k transactions over 9 years; 0–3 imports per week, each 200–2,000 rows.
- **Locale:** `en-GB` and `de-DE` amounts and dates, currency codes (GBP/EUR/CHF), payee names with diacritics (Bäckerei Müller-Lüdenscheid, a long name), negative amounts.
- **Sync:** `:manual` (backfill after import).
- **Failure profile:** a Meilisearch task **`failed`** with document-level error codes (`invalid_document_id` from a CSV row whose id has a space or slash; `missing_document_id`). This is the backend-failed path, distinct from queue retries, and there is no queue observation by design.
- **Who opens the UI:** the household's self-hoster on a weekend after an import → `ROLE-OPS` (`JOB-03`) with `JOB-02` context (manual mode means "accepted ≠ visible").
- **Distinct class:** manual mode; backend task failure with error codes; privacy-sensitive data (the fixtures must show the Search query privacy guidance and never real names or IBANs); non-English number and date formats inside documents.

#### P5 · Shoply: B2B multi-schema marketplace at scale (power user)
- **Product:** an industrial-parts B2B marketplace. It is the **scaled-up form of the existing e-commerce example** (tenants, categories, products, variants, with `examples/scrypath_ecommerce/lib/scrypath_ecommerce/catalog/*.ex`), so the click-around demo stays coherent and is not forked.
- **Why Scrypath:** catalog search with facets and filters across products, variants, suppliers, documents (datasheets), quotes and orders.
- **Schemas → indexes:** six of them, including deliberately long module names such as `ShoplyExchange.Catalog.SupplierCertificationDocument` → `partsbin_exchange_supplier_certification_document`.
- **Volume:**
  - 41M variants, 6 schemas, 180 supplier tenants;
  - task uids are 10-digit (the `phase173` "long" scenario already uses `9_876_543_210`);
  - 137 failed or retrying jobs, which crosses any page or list boundary;
  - counts in the millions need digit grouping.
- **Locale:** `en`, `de`, `pl` (diacritics), part numbers with unbroken tokens (`DIN-912-M8x40-A2-70`) and URLs.
- **Sync:** `:oban`, plus a managed reindex of the largest index while live traffic continues.
- **Failure profile:** mixed and partial. One schema's observation fails while the others load (the "partial" scenario); some schemas are retrying while others are healthy; there is a reindex in progress; and stale retained observations.
- **Who opens the UI:** a platform/SRE teammate who owns the Meilisearch service, often by keyboard (command palette, direct URLs) → `ROLE-OPS` and `ROLE-OWNER`, all of `JOB-03`/`04`/`05`.
- **Distinct class:** scale, many schemas, long identifiers, worst-case lengths, partial observation, power-user navigation.

### 1.3 Coverage matrix

| Axis \ profile | P1 Wikily | P2 Chatly | P3 Kotoba | P4 Budgetly | P5 Shoply |
| --- | --- | --- | --- | --- | --- |
| B2B / B2C | B2B internal | B2B | B2C | B2C (self) | B2B |
| Hosted MT / self-hosted ST | self ST | hosted MT | hosted ST | self ST | hosted MT |
| Setup | **empty/missing** | populated | populated | populated | populated |
| Sync | **inline** | oban | oban + manual | **manual** | oban + reindex |
| Scale | 0–3 docs | 10⁶ | 10⁶ | 10⁴ | **10⁷, 6 schemas** |
| Script | Latin | **emoji** | **CJK + RTL** | diacritics, locale numbers | long tokens |
| Failure | setup-missing | **queue retry/discard, delete** | **settings drift, promotion** | **backend task failed** | **partial, mixed, paginated** |
| Main job | JOB-01 | JOB-03 | JOB-04/05 | JOB-03 (+02) | JOB-03/04/05 power |

Each bold cell is owned by exactly one profile. Removing any column loses at least one rendered state class.

### 1.4 Candidates rejected as sprawl

- **Multi-tenant SaaS helpdesk:** the same class as Chatly (hosted MT, B2B, oban, high write rate). It adds no state that P2 lacks. A "support lead" trigger is folded into `JOB-05` instead (see §2).
- **Separate self-hosted docs wiki (populated):** P1 already owns the self-hosted wiki shape. A populated wiki adds nothing over P4's single-tenant data.
- **Separate "huge e-commerce" plus the existing demo catalog:** merged into P5, so there is one retail/marketplace lineage, not two.
- **A dedicated "error everything" persona:** this is an anti-pattern. Failure scenarios are **orthogonal states applied to profiles** (§3.3), not a sixth company.
- **Health/medical or kids' product:** introduces PHI/COPPA realism theatre with no extra rendered state. Rejected.
- **A per-locale persona for each script:** script is an attribute, owned by P2 (emoji) and P3 (CJK/RTL). One profile per locale would be sprawl.

A sixth profile is admitted only when it owns a new bold cell (for example, if Scrypath ever ships index-per-tenant or a second backend).

---

## 2. Operator roles and JTBD → surfaces (extending OPERATOR-UI-QUALITY.md)

The existing roles and jobs are kept verbatim. The four humans the brief names become **situations within existing roles**, not new IDs. This follows the authority's rule: "these are contexts, not mutually exclusive people".

| Human in the brief | Maps to | Situation/trigger it adds | Profile |
| --- | --- | --- | --- |
| Solo indie / self-hoster | `ROLE-INT` (setup), then `ROLE-OPS` | "I'm the only operator; first run, or a weekend import" | P1, P4 |
| On-call engineer | `ROLE-OPS` | Paged; time-pressured; needs the affected schema in one hop | P2 |
| Platform/SRE | `ROLE-OPS` + `ROLE-OWNER` | Owns Meilisearch; reindex at scale; keyboard-first | P5 |
| Support lead | **No new role.** It is a **trigger for `JOB-05`**: "a customer says they can't find X". Usually an engineer runs the check; a support lead may be shown a saved search. | Saved search replay, per-target results | P2, P3 |
| Search owner | `ROLE-OWNER` (unchanged) | Settings PR, promotion | P3 |

### Job × surface map (rendered surface names)

| Job | Control Room | Search | Search health | Failed sync work | Sync and index | Help |
| --- | --- | --- | --- | --- | --- | --- |
| `JOB-01` set up | **primary**: setup-missing / empty states | first record visible | backend missing vs empty | — | settings loaded | **primary** |
| `JOB-02` choose a sync mode | sync-mode label | — | configured method vs observed work | — | — | **primary** |
| `JOB-03` fix failing sync | **entry**: verdict and next step | post-recovery visibility check | **primary**: worst-first schemas | **primary**: retry/delete | correlated recovery result | task help |
| `JOB-04` settings / promote | entry | document visibility check | task outcome | — | **primary**: declared/live, promote | task help |
| `JOB-05` investigate / preserve search | "Try a search" | **primary**: query, results, save, replay | — | — | — | task help |

**Proposed additions to the authority (small and dated):**
1. Under "Task contexts", add one line: *Situations: solo self-hoster, paged on-call, platform/SRE owner, support-triggered check. These are triggers within `ROLE-*`, not new roles (2026-10-25, maintainer intent: OWNER-INTENT.md).*
2. Add a short "Adopter profiles (fixture data)" pointer to the fixture package README (§3.6). The profile table lives with the data that implements it, so it can't drift from it.

Every story variation's description then reads as `P<n> · ROLE · JOB · state`, for example "P2 Chatly · ROLE-OPS · JOB-03 · delete sync work discarded after 20 attempts".

---

## 3. Fixture architecture

### 3.1 What exists today (measured)

- **Two near-copies of the same fixture source**, already drifting:
  - `scrypath_ops/test/support/phase173_fixture_source.ex` (314 lines);
  - `examples/scrypath_ecommerce/test/support/phase173_fixture_source.ex` (297 lines).
  After normalising module names, their diff is 73 lines.
  Both are wired through app env: `scrypath_ops/config/test.exs:52` and `examples/scrypath_ecommerce/config/test.exs:21` set `:phase173_fixture_source`, and `posture_live.ex:166-179` reads it.
- **A good state taxonomy is already there:** 15 scenarios in `normalize_scenario/1`: `healthy failed unavailable unknown empty partial long invalid-time queue-unused refresh-failure refresh-disabled processing backend-failed retrying completed`. Keep it. These become the orthogonal scenario axis.
- **Phase numbers leak into rendered identifiers:** `index_prefix: "phase173"` gives the rendered index `phase173_phase173_fixture_schema`. Other leaks are the error atom `:phase173_backend_unavailable`, the URL `/admin/search/phase173/health`, and a visible "Fixture scenario" select (`posture_live.ex:236`). These fail the "no internal vocabulary" rule in every screenshot the L4 judge sees.
- **Demo seeds:**
  - `examples/scrypath_ecommerce/lib/scrypath_ecommerce/catalog_fixtures.ex` (345 lines): an English-only electronics catalog ("Quantum CyberPhone X"). It is realistic in shape but has one script and one industry.
  - `lib/mix/tasks/scrypath.demo.seed.ex`: scenarios `all_green degraded incident empty indexing_failure` over three tenants.
- **Gettext is barely used:** 5 `gettext(` calls in `scrypath_ops/lib/scrypath_ops_web`, all from the Phoenix generator's flash. A msgid lint would see almost nothing, so lint the rendered text instead (§4.5).

### 3.2 Where the shared source lives

**Recommendation:** add a tiny in-repo Mix project, `fixtures/scrypath_fixtures/` at the repo root (application `:scrypath_fixtures`, no runtime supervision).

| Requirement | How it is met | Evidence |
| --- | --- | --- |
| Compiles only in dev/test | Consumers declare `{:scrypath_fixtures, path: "…/fixtures/scrypath_fixtures", only: [:dev, :test]}`. | Mix `only:` dependency option. |
| Reachable from every story host incl. the example app | Both `scrypath_ops` and `examples/scrypath_ecommerce` already consume siblings by path (`examples/scrypath_ecommerce/mix.exs:36-37`). `test/support` is **not** reachable across apps: path deps compile in their own `:prod`-default env and only with `lib/`. That is why the two copies exist today. | `scrypath_ops/mix.exs:35-36`, `examples/scrypath_ecommerce/mix.exs:31-32` |
| Demo/preview seeds can use it | The demo images run `MIX_ENV=test` (`examples/scrypath_ecommerce/Dockerfile:12`, `compose.yaml:34`, `compose.phase173.yaml:19`) or `dev` (`compose.dev.yaml:11`), so `only: [:dev, :test]` is present there. | same |
| Out of the Hex package | Root `package files:` is an explicit allowlist (`lib .formatter.exs mix.exs README.md … docs/…`, `mix.exs:270-271`). A new top-level `fixtures/` is excluded by construction, and `scrypath_ops` is itself outside the tarball (`mix.exs:268-269`). Add `fixtures/` to the existing package parity check (`mix verify.package`) as an explicit **must-not-contain** path. | `mix.exs:265-279` |
| No Faker, no new deps | Its only dependency is `{:scrypath, path: "../.."}`, which it needs for real `use Scrypath` embedded schemas in the allowlist. It uses no other packages (it reuses Jason only if a consumer already has it). | copy-paste-over-deps rule |

**Rejected:**
- `scrypath_ops/lib/…` guarded by `if Mix.env() in [:dev, :test]`: as a path dep it compiles with `:prod`, so the guard is false in the example app. It is also a footgun for adopters.
- `scrypath_ops/test/support`: not reachable cross-app.
- An umbrella: a repo-structure change for one helper.
- Root `test/support`: the core library's test env, so not reachable.

### 3.3 Shape: profiles × scenarios, emitted at existing boundaries

```
fixtures/scrypath_fixtures/lib/
  scrypath_fixtures.ex                 # catalog(): [profile_id], scenario ids, anchor time
  scrypath_fixtures/profiles/{quillmark,hearth,kotoba_ladder,tallyhouse,partsbin}.ex
                                       # schemas (embedded, `use Scrypath`), documents, tenants, volumes
  scrypath_fixtures/scenarios.ex       # the 15 existing scenarios, profile-agnostic transforms
  scrypath_fixtures/meilisearch.ex     # task maps in Meilisearch's JSON shape (string keys)
  scrypath_fixtures/oban.ex            # job maps in the shape the oban_inspector returns
  scrypath_fixtures/source.ex          # implements the current meilisearch_client / oban_inspector seam
  scrypath_fixtures/seed.ex            # attrs lists only; Ecto inserts stay in the example's seed task
  scrypath_fixtures/gen.ex             # deterministic ids/timestamps (below)
```

- **`fixture(profile, scenario)`** returns plain data: `allowlist`, `scrypath_opts`, `snapshot_at`, `documents`, `tasks`, `jobs`, `settings: %{declared, live}`.
  - Stories render presentational components from it with no DB.
  - LiveView tests use `Source` through the existing app-env seam.
  - Seeds turn `Seed.attrs(profile)` into rows.
  This **replaces both `Phase173FixtureSource` copies**.
- **Retire the phase vocabulary.** Index prefixes come from the profile (`hearth`, `kotoba_ladder`…), the error atom becomes `:backend_unavailable`, and the visible scenario picker is renamed to a dev-only "Demo data" control. The `/phase173/` mount path then becomes a test-only route alias.
- **Data placement rule.** The fixtures emit **external shapes** (Meilisearch task JSON, Oban job fields), never ScrypathOps view structs. This means the fixture can't silently agree with a presentation bug: the real normalisation code still runs.

### 3.4 Determinism and realism without Faker

- **No wall clock:** one anchor (`~U[2026-10-06 17:18:42.318Z]`, matching the existing `@snapshot`) plus explicit offsets. `DateTime.utc_now/0` is banned inside the package (an invariant test greps for it).
- **IDs:** each id derives from `:crypto.hash(:sha256, "#{profile}:#{kind}:#{n}")`.
  - Document ids: UUIDv4-format strings (Chatly), integers (Shoply variants, Budgetly transactions), slugs (Wikily pages).
  - Meilisearch task `uid`: monotonically increasing integers per profile instance, starting at a profile-specific base (Wikily 1, Budgetly 4_812, Chatly 1_904_221, Shoply 9_876_543_210).
  - Oban `id`: a monotonically increasing bigint.
- **Text:** hand-written, domain-true corpora of about 30–80 lines per profile, stored as module attributes (real-sounding lesson sentences, payee names, part numbers, chat messages). A deterministic rotation `Enum.at(corpus, rem(n, length))` scales them to the declared volume for counts. Rendered stories show only the first few.
- **No real PII or secrets:**
  - person names come from a small invented list, checked to be generic;
  - emails use `@example.com`/`.test` (RFC 2606);
  - IBAN-like strings are replaced by `•••• 4821`-style masks;
  - Meilisearch keys/URLs use `.invalid`/`.test` hosts (the existing `http://phase173.invalid` pattern is correct).
- **No lorem ipsum:** a test rejects `/lorem|ipsum|dolor sit|foo|bar baz|test123|asdf/i` in any string.

### 3.5 Invariant test list (`fixtures/scrypath_fixtures/test/invariants_test.exs` plus one contract test in `scrypath_ops`)

The closed enums are mirrored from the sources the UI already parses (`sync_drift_live.ex:893,1038-1048`).

1. **Meilisearch task `status`** ∈ {`enqueued`, `processing`, `succeeded`, `failed`, `canceled`}. Per Meilisearch's tasks reference, `type` comes from a closed list: `documentAdditionOrUpdate`, `documentDeletion`, `settingsUpdate`, `indexCreation`, `indexSwap`, `taskCancelation`, etc.
2. **Oban job `state`** ∈ {`available`, `scheduled`, `executing`, `retryable`, `completed`, `discarded`, `cancelled`}.
3. **Valid states.**
   - `failed` ⇔ `error` present with `code` and `message`, and `error` is absent otherwise.
   - `enqueued` ⇒ no `startedAt` and no `finishedAt`.
   - `processing` ⇒ `startedAt` but no `finishedAt`.
   - A terminal status ⇒ both.
   - Oban: `attempt ≤ max_attempts`; `discarded` ⇒ `attempt == max_attempts` or an explicit discard; `retryable` ⇒ `scheduled_at > attempted_at`; and `errors` length == the number of failed attempts.
4. **Timestamp ordering.**
   - Tasks: `enqueuedAt ≤ startedAt ≤ finishedAt`, and `duration` equals `finishedAt − startedAt` as ISO 8601.
   - Jobs: `inserted_at ≤ attempted_at ≤ completed_at|discarded_at`.
   - Every timestamp ≤ `snapshot_at`. The only exception is the explicit `invalid-time` scenario, which is the one allowed malformed value; it is tagged as such.
5. **Monotonic ids:** task uids strictly increase with `enqueuedAt` within a profile, and job ids increase with `inserted_at`.
6. **Tenancy.**
   - Every document of a `tenant_field` schema carries a tenant id that exists in that profile's tenant list.
   - Single-tenant profiles have no tenant ids.
   - No document crosses profiles.
7. **Index identity:** each `indexUid` equals `Scrypath.Meilisearch.index_name(schema, index_prefix: profile_prefix)`. This contract test lives in `scrypath_ops`, so a naming change in core breaks fixtures loudly.
8. **Sync-mode coherence:** `:inline`/`:manual` profiles have no Oban jobs, and `queue-unused` holds exactly that.
9. **Scenario closure:** every scenario id is in the closed list, every `(profile, scenario)` pair either produces data or is explicitly declared impossible, and no story may reference an impossible pair (methodology §1 pruning).
10. **Volume honesty:** declared counts (e.g. P5 "41M") are only labels. Generated lists are bounded (≤ 200 items) and say so, so a test never allocates 41M maps.
11. **Determinism:** two calls return byte-identical `:erlang.term_to_binary` output, and there is no `utc_now` or `:rand` without a fixed seed (grep check).
12. **Content hygiene:** the lorem/placeholder ban, an `@example.com`/`.test`/`.invalid`-only domain check, no `sk_`/`pk_`/`masterKey`-like strings, and each profile's declared scripts actually present (for example, P3 has ≥ 1 string with a Han, Hangul, Arabic or Hebrew codepoint; P2 has ≥ 1 ZWJ emoji sequence).

---

## 4. Verbal design tokens

### 4.1 Voice rules (library-authored copy only; the host owns its own pages)

Primary-source basis is in §6.

1. **Sentence case** for headings, labels, buttons, nav and empty-state titles. Proper nouns keep their case: Meilisearch, Oban, Ecto, Phoenix, Elixir, Scrypath, plus module and index identifiers. (Microsoft Style Guide: "Capitalize the first word of a … UI label (such as the name of a button…)… Use lowercase for everything else.")
2. **Buttons start with a verb** and name the object when the object isn't obvious: "Retry delete sync work", "Promote target index", "Check settings". Single-verb labels are allowed inside an object's row ("Rename", "Delete"). Never use "OK", "Yes" or "Submit".
3. **Errors = what happened + what to do**, plain and specific. Never use "Oops", "!", "Sorry", "Please", "invalid/valid", "Something went wrong", "unspecified error" (GOV.UK error-message guidance, verified). Name the object and the evidence; don't blame the operator.
4. **State words are a closed vocabulary.** Use exactly *Waiting, Processing, Succeeded, Failed, Retrying, Canceled, Unknown*, plus *Accepted* or *Queued* only for dispatch. Accepted is never shown as done (`OPERATOR-UI-QUALITY.md` Operational truth).
5. **Empty states:**
   - **title** = the observed fact, as a sentence fragment with **no trailing period**;
   - **description** (optional) = why, or what will appear;
   - **one action** that leads to the fix or the feature (Primer empty-states, verified).
   - Keep three shapes distinct: *nothing configured* (setup), *nothing found* (healthy-empty), and *couldn't check* (observation failed). They must never share copy (DESIGN.md Do's).
6. **Confirmations** for destructive or irreversible operations (delete a saved search, promote an index):
   - the title is a question naming the object ("Delete saved search “Chatly: missing DMs”?");
   - the body is the consequence, including what is *not* affected;
   - the confirm button repeats the verb and object ("Delete saved search"), and the cancel button is "Cancel".
   - No "Are you sure?". Protected confirm behaviour stays as is.
7. **Success feedback** is past tense, names the object, and claims only what was observed: "Retry queued for 3 jobs", not "Retried successfully".
8. **Raw evidence** (Elixir terms, JSON) appears only inside `ops_code_block`/disclosures. Never interpolate `inspect/1` into a sentence.
9. **No phase numbers, ticket ids, module internals or test words** ("fixture", "stub", "phase173") in rendered copy outside dev-only demo controls.

### 4.2 Glossary additions (append to the OPERATOR-UI-QUALITY.md language table)

These seed from strings the UI renders today. Keep existing rows unchanged.

| Internal term (code) | UI term | Where it leaks today / note |
| --- | --- | --- |
| `Posture`, `posture_live`, `/posture` | **Search health** | Already correct in the nav (`nav.ex:24`); keep `posture` out of copy. |
| `drift`, `SyncDriftLive`, `/sync-drift` | **Sync and index** (surface); **differences** (in content) | The nav says "Sync and index" (`nav.ex:36`), but DESIGN.md says "Sync and drift". Pick one; the nav is what renders. |
| `contract` / `index_contract_drift` | **Index settings** | Visible in `sync_drift_live.ex:2403` ("live-index or contract effect"). |
| `generation` (async staleness counters) | *never shown* | 88 code occurrences, 0 visible. Keep it that way (lint). |
| `federation`, `federation_limit` | **Search across selected schemas**; **Result limit** | Code-only today; the lint guards it. |
| `allowlist`, `schema_allowlist` | **Configured schemas** | Code-only; the empty-state titles split into two terms (§4.6). |
| Oban `retryable` / `available` / `scheduled` | **Retrying** / **Waiting** | Mapped in `sync_drift_live.ex:1038`. |
| Oban `discarded` | **Failed** (gave up after N attempts) | Mapped at `:1048`; show the attempt count. |
| Oban `cancelled` / Meilisearch `canceled` | **Canceled** (one US spelling in the UI) | The code accepts both spellings (`:893`). The UI must render one. |
| Meilisearch `enqueued` | **Waiting** | Don't say "queued", which is reserved for the host's queue jobs. |
| `indexSwap` / promotion | **Promote target index** | Already rendered. |
| `reconcile` | **Reindex** | "No reindex in progress." is rendered. |
| `tenant_field` | the host's own word; default **tenant** | Show it only in filters/evidence. |
| `{:error, term}` / `inspect` output | a one-line cause plus disclosed raw detail | See rule 8. |

Glossary growth rule (unchanged from the authority): add a row only when real copy or a repeated misunderstanding demonstrates the need.

### 4.3 Empty-state patterns (fixed set)

| Kind | Title | Description | Action |
| --- | --- | --- | --- |
| Setup missing | No schemas configured | Add a schema module to `:schemas` in the ScrypathOps config. | View setup help |
| Backend unreachable | Can't reach Meilisearch | Checked `http://…` at 14:02 UTC: connection refused. Search health shows the last successful check. | Refresh |
| Healthy empty | No failed or retrying sync work | Checked 4 schemas at 14:02 UTC. | — |
| Filtered empty | No sync work matches these filters | — | Clear filters |
| Search no hits | No matching documents | In `hearth_message` for “invoice 🧾”. | — |

### 4.4 Confirmation pattern

```
Title:   Promote target index for Langalern cards?
Body:    Searches will use kotoba_ladder_card_2026_10_25 instead of kotoba_ladder_card.
         The current index is kept until you remove it.
Buttons: [Promote target index]  [Cancel]
```

### 4.5 Linting cheaply (one rule file, two runners)

- **One rule source:** `scrypath_ops/test/support/copy_rules.json`, or inside the fixtures package so both apps share it.
  - `banned` regexes: `\bOops\b`, `!(\s|$)`, `\bPlease\b`, `\bSorry\b`, `\b(in)?valid\b`, `Something went wrong`, `\bsuccessfully\b`, `phase\d+`, `\bfixture\b`, `\bstub\b`, `%\{`, `\{:error`, `Elixir\.`;
  - `internal_terms`: `allowlist`, `generation`, `federat`, `hydrat`, `posture`, `contract` (allowed inside `[data-ops-raw]`/disclosures);
  - `proper_nouns`;
  - `verbs`: the allowed first words for buttons;
  - `closed_states`.
- **ExUnit (blocking, fast):** `ScrypathOpsWeb.CopyLintTest`.
  - For every `(profile, scenario)` fixture and each LiveView route, render with `Phoenix.LiveViewTest` and parse with `LazyHTML` (already a test dep, `scrypath_ops/mix.exs:52`).
  - Extract text nodes plus `aria-label`, `title`, `placeholder`, `alt`, `<button>`/`<a>` names and `h1–h4`.
  - Assert: no banned or internal term outside allowed containers; sentence case for headings/buttons/nav (first word capitalised; later words lowercase unless proper nouns or `<code>`); the first word of buttons is in `verbs`; empty-state titles have no trailing period; one term per concept (no "No schemas configured" alongside "No search schemas configured").
  - Seed the existing violations into `copy_baseline.json`, which may only shrink (the methodology ratchet).
- **Playwright (L2, advisory → blocking later):** reuse the capture that `e2e/ui-review.mjs:131-133` already writes (`text`, `headings`, `controls` incl. `aria-label`/`placeholder`). Add one function that applies the same `copy_rules.json` to `copy.json`. No new dependency and no new browser run. This covers host-composed pages and JS-rendered strings that ExUnit can't see (toasts, the command palette).
- **Not recommended:** a gettext-msgid lint (5 msgids; §3.1); Vale over the UI (Vale is for docs only, per methodology); an LLM judge for copy that the rules already own.

### 4.6 Current violations found (sampled, not exhaustive)

1. `components/layouts.ex:401`: "Something went wrong!" uses "!" and generic wording. `:388` "We can't find the internet" is Phoenix-generator default copy. Suggested: "Lost connection to the server" with "Reconnecting…" as the body.
2. `live/sync_drift_live.ex:2403-2405`: "…live-index or contract effect could not be confirmed ({inspect(@promotion_observation_error)})". This shows internal vocabulary and a raw Elixir term in a sentence.
3. Empty-state title drift for one state:
   - "No search schemas configured." (`control_room_live.ex:129`)
   - "No search schemas configured" (`ops_ui.ex:819`)
   - "No schemas configured" (`search_live.ex:1308`, `sync_drift_live.ex:1959`)
   - "No schemas configured." (`failed_sync_live.ex:869`)
   That is two terms and two punctuation styles.
4. `live/failed_sync_live.ex:656`: "Invalid data: fix the record, then retry." GOV.UK bans "invalid". Suggested: "Meilisearch rejected this document. Fix the record, then retry."
5. `live/posture_live.ex:236` "Fixture scenario", plus `phase173_*` index names rendered in fixture mode. Test words appear in the screenshots the reviewers use.
6. Nav capitalisation: "Control Room" (`layouts.ex:327`) is title case beside sentence-case siblings. Either treat it as a proper noun (record that decision) or change it to "Control room".
7. Doc/UI drift: DESIGN.md "Sync and drift" / "Saved searches" vs the rendered "Sync and index" / Search's saved-search picker.

---

## 5. Adversarial pass

| Risk | Argument against | Mitigation kept in the recommendation |
| --- | --- | --- |
| **Persona sprawl** | Five fictional companies are five maintenance burdens; the authority already said "don't invent personas". | They are fixture data profiles tied to rendered equivalence classes (§1.3), not personas for design debate. Admission needs a new bold cell. Profiles that own no live story at the milestone pruning pass are deleted. |
| **Realism theatre** | Hand-written Japanese sentences and Budgetly payees look impressive but don't change the UI. | Realism is limited to what **renders or breaks layout**: script, length, counts, id formats, state combinations. Volumes are labels, not generated data (§3.5 #10). Each profile corpus is capped at ~80 lines. |
| **Fixture ≠ reality** | Hand-shaped task JSON can drift from what Meilisearch and Oban actually return. | The fixtures emit external shapes into the **real** normalisation code. The closed enums are copied from the parsing code (§3.5). The opt-in real-backend `indexing_failure` seed stays as ground truth. Shape changes surface when `mix verify.ecommerce_e2e` runs against real Meilisearch. |
| **New Mix project overhead** | A third mix project means more `deps.get`, lockfile churn and CI time. | It has no deps beyond core, compiles in seconds, and deletes ~600 lines of duplicated fixture source. Fallback if rejected: keep the source in `scrypath_ops/lib/scrypath_ops/dev_fixtures/` behind `elixirc_paths(:dev/:test)`, with the example app adding that dir to its own `elixirc_paths`. It works, but compiling another app's files is brittle. |
| **Glossary bikeshedding** | Every row invites a naming debate. | Rows are added only on demonstrated leaks or confusion (the authority's rule). The table records *distinctions that change a decision*, not synonyms. The lint enforces *consistency*, not taste. |
| **Lint false positives** | "!" in code samples, "valid" in a user's query, "contract" in an advanced disclosure. | Rules skip `<code>`, `[data-ops-raw]` and user-supplied echo regions (query text, document fields). The baseline ratchet means turning it on never blocks an unrelated PR. |
| **Sentence-case vs Apple HIG** | Apple uses title-style for some titles and buttons on its platforms. | Scrypath is a web operator UI next to Phoenix and GitHub-style tools. Microsoft, GOV.UK, Primer and Polaris all use sentence case. Apple is cited only for consistency and verb labels. |
| **Operator-role inflation** | Adding "support lead" or "SRE" as roles forks the authority. | They are triggers within the existing `ROLE-*` (§2). No new IDs. |
| **Storied impossible states** | Profile × scenario = 75 combinations. | Most pairs are declared impossible or redundant (§3.5 #9). The target is about 15–20 live pairs: each scenario once on its most natural profile, plus worst-case P5 and script cases P2/P3. |
| **Ops UI in prod depending on dev fixtures** | `posture_live.ex` reads the fixture source from app env at runtime. | It stays an app-env seam that is configured only in `config/test.exs`/`dev.exs`. Add a test asserting that `:prod` config has no fixture source and that the "Demo data" control doesn't render without it. |

---

## 6. One-shot recommendation

1. **Adopt five adopter profiles (P1–P5) as fixture data, not personas.** Keep `ROLE-*`/`JOB-*` in OPERATOR-UI-QUALITY.md as the only operator model. Add one dated line for situations (solo self-hoster, paged on-call, platform/SRE, support-triggered check) and append the §4.2 glossary rows there.
2. **Build `fixtures/scrypath_fixtures`** (a path dep, `only: [:dev, :test]`, depends only on `scrypath`). It provides profiles × the existing 15 scenarios, emitted as Meilisearch/Oban external shapes through the existing app-env seam, plus attrs for demo seeds. It replaces both `Phase173FixtureSource` copies, retires the `phase173` vocabulary from rendered identifiers, and comes with the 12 invariant tests and a package must-not-contain check.
3. **Ship the verbal tokens as one `copy_rules.json`** with an ExUnit render lint (LazyHTML, every fixture pair) and a few lines in the existing `ui-review.mjs` copy capture. Seed a shrink-only baseline that holds today's 7 findings, then fix #1–#4 in one batch.
4. Sequence: profiles → fixtures + invariants → copy lint + baseline → stories consume fixtures (methodology build order 1–2, then L1).

---

## Sources

Verified means fetched and read in this session.

- GOV.UK Design System, *Error message*. **Verified**: "explain what went wrong and how to fix it"; avoid "please", "sorry", "valid/invalid", "oops", technical jargon. https://design-system.service.gov.uk/components/error-message/
- GOV.UK, *Writing to GOV.UK standards: tone of voice* (the old `/guidance/content-design/writing-for-gov-uk` 301-redirects here; the redirect was verified, the page wasn't read). https://guidance.publishing.service.gov.uk/writing-to-gov-uk-standards/tone-of-voice/
- Microsoft Writing Style Guide, *Capitalization*. **Verified**: sentence-style for headings and UI labels, including buttons. https://learn.microsoft.com/en-us/style-guide/capitalization
- Primer, *Empty states*. **Verified**: title / optional non-redundant description / one primary action; for errors, avoid vague "There was a problem" and say how to fix it. https://primer.style/product/ui-patterns/empty-states/
- Apple HIG, *Writing* (the page body didn't render for fetching; cited from memory for verb-labelled buttons and consistent terminology; check before quoting). https://developer.apple.com/design/human-interface-guidelines/writing
- Shopify Polaris, *Actionable language* (the fetch failed; cited from memory for verb + noun buttons). https://polaris-react.shopify.com/content/actionable-language
- Meilisearch, *Tasks API reference* (task statuses, types, timestamps; from memory, so confirm the enum against the pinned Meilisearch version). https://www.meilisearch.com/docs/reference/api/tasks
- Oban, `Oban.Job` (job states; from memory, and consistent with `sync_drift_live.ex:1038-1048`). https://hexdocs.pm/oban/Oban.Job.html
- RFC 2606, reserved example domains (`example.com`, `.test`, `.invalid`). https://www.rfc-editor.org/rfc/rfc2606
