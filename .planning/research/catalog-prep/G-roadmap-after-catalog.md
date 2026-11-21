# Catalog prep G: the roadmap after v1.49

Prepared 2026-11-21. Research and recommendation only; no plans. Tags: V = read or run this session, J = judgment, U = unverified.

## 0. Premise corrections (V)

- **v1.34 is not paused.** It shipped 2026-06-29, 9 of 9 phases including 133, audit passed, tag `v1.34` exists (`.planning/MILESTONES.md:373`, `milestones/v1.34-ROADMAP.md:85-95,152`, `git tag`). The "paused at Phase 133" memory entry is stale. There is nothing to resume. What is real is a *residual*: the v1.46 re-skin changed the palette and its audit says the computed-style browser specs run only on schedule or dispatch and that "how the new look reads is not proven" (`milestones/v1.46-MILESTONE-AUDIT.md:29-31`). The catalog is the cheap place to close that.
- **Phase numbers:** v1.49 uses 195 to 198 (cap 5 plans each). A later milestone starts at 199, whether or not 198 is cut.
- **Open GitHub state:** issues #86 (standing decision log) and #52 (stale bot parity report); one open PR (#168, this branch's docs). Traffic is unchanged: 5 unique visitors in 14 days (`gh api .../traffic/views`). Nothing outside-driven is queued.
- **ScrypathOps depends on non-public library internals** (`Scrypath.Meilisearch`, `Scrypath.Operator.State`, the `@moduledoc false` Oban workers; grep of `scrypath_ops/lib`). It is `0.1.0`, has no `package:` and uses `{:scrypath, path: ".."}` (`scrypath_ops/mix.exs`). This drives the Hex-publish gate in section 3.

## 1. The roadmap in one minute

Principle (J): alternate surfaces. Every second milestone ends in something that can ship on Hex, and an outward-facing step comes only after the library's first hour works. Sizes are plans, estimates.

| Slot | Milestone | One-line goal | Why here | Size | Entry trigger | Exit evidence (executable) | What reorders it |
|---|---|---|---|---|---|---|---|
| 0 | Readiness PR (not a milestone) | Fix the false guide line, `posture.ex` path, split `deep-quality`, close #52, write cadence text | Real defects, no decisions needed, and the `fix(docs)` opens the release PR that accumulates the next release | 1 | now | one test per fixed defect, existing lanes green | none |
| 1 | **v1.49 Catalog foundation** (decided) | Thin storybook on Scrypath-owned adopter fixtures, one job end to end | Maintainer decision (ADR 0001, UI engine D1). Needs no maintainer input beyond the reuse grant, so it suits autonomous mode | 12 to 16 (195:3, 196:3, 197:4 to 5, 198 cuttable) | readiness PR merged | render-all test, every component and route has a story, mounted journey with denial, spike numbers recorded, prod-exclusion test | ADR 0001 trigger trips: shrink to 195, then slot 2 |
| 2 | **v1.50 Adopter-ready** | "Testing your app" guide, fresh-consumer walk, then (only after API grilling) highlight/crop or paging guard | Core Value is the library, nothing has touched it for three milestones, and it is the only slot that produces a release worth announcing | 3 to 5, cut after the guide and walk | v1.49 closed | guide snippets compile in a docs test, walk findings recorded, allowlist and hostile-title tests if phase 3 runs | an outside report; the walk finds nothing painful (stop at the guide) |
| 3 | **v1.51 Catalog breadth** (only if 198 was cut or review asks) | Remaining screens in D2 order, a second mounted journey, storybook replaces the retained preview as the review surface | Fold the maintainer's end-of-v1.49 feedback in before widening; Search story must exist before the ops Search screen renders highlights | 5 to 8 | v1.49 review note says "widen" | every LiveView route has a story; no new gate beyond the `ops-ui` job | pilot disappointed: skip it, do slot 4 |
| 4 | **v1.52 Announce-ready** | Website content (SITE-07 to 09) with real product images from stories, README/HexDocs check, then a maintainer-run announcement | The cut v1.48 phase; the cut reason (no traffic) is cured only by someone being told; a launch needs a testing story and screenshots first | 3 to 4 | the maintainer says "announce" and a release carrying v1.50 exists | computed-style, contrast, axe, link and copy checks on the site; claims have one owner each | maintainer does not want to announce: drop it |
| 5 | Conditional: ScrypathOps on Hex | ADR plus a package dry run, then publish | A strategic decision (scope guard: new public runtime categories) | 1 phase (ADR + dry run) before any milestone | the maintainer decides, or an outside request to mount it | `mix hex.build` unpack shows no `fixtures/`, no storybook, assets prebuilt; consumer compile from Hex | not planned; see section 3 |

Confidence: slot 2 after slot 1: 0.7. Slot 3 existing as a separate milestone: 0.4 (it may fold into v1.49). Slot 4 as "after the library's first hour": 0.6. Slot 5 as a decision, not a milestone: 0.8.

## 2. Decisions

**D1. Library before breadth.** v1.50 follows v1.49 directly. Rejected: catalog breadth first (the pilot's findings should steer it; accrue needed 138 plans without a cut line, `SIBLING-SCAN`). Rejected: website first (nil traffic plus an unfinished first hour). Would change: an outside report (jumps the queue), or the maintainer wants the storybook as the only review surface now (then slot 3 first). Confidence 0.7.

**D2. Dark-mode perfection is not a milestone.** Resuming v1.34 is impossible (section 0). Instead: the storybook ships light, dark and System for every story from the spike; the milestone-end review looks at both themes; the contrast-pair check and computed-style assertions that already exist become render-all-adjacent checks, advisory first. Rejected: a new "both themes v2" milestone (v1.34 already did 9 phases). Reopen if the v1.49 review finds three or more theme defects in one area. Confidence 0.75.

**D3. Website content after Adopter-ready, tied to an announcement.** The checkpoint cut Phase 194 on traffic (V: `milestones/v1.48-MILESTONE-AUDIT.md`), and v1.49 prep C said distribution is the only lever on zero stars and should pair with the first release that carries real adopter value. The catalog adds one dividend: deterministic, fictional-adopter screens for the "nothing shows the product" gap (`research/website-refresh/01`, weakness 2). Rejected: refresh now (polishes a surface nobody visits, duplicates v1.48's own cut). Confidence 0.6; would change if an outside referrer appears.

**D4. ScrypathOps publication is a decision, not a milestone.** What must be true first (V from mix.exs and grep, rest J): `{:scrypath, path: ".."}` becomes a Hex requirement and lockstep-pinned; ops stops using `@moduledoc false` library internals or the library promotes them (a public-API decision, so 0.4.0); `package:` with a `files:` allowlist that excludes `fixtures/`, `storybook/` and `test/`; assets prebuilt in `priv/static` (no Tailwind or esbuild at install); host-mount contract (nine JS hooks, CSS link) documented and tested by the existing `ecommerce-mounted` lane; `mix hex.audit` clean (today red on sigra to cloak_ecto); sigra stays optional; a named owner for a second release train. Cost: a second Release Please component. Confidence 0.8 that it should not be planned now. The catalog lowers its cost (the stories document the components and fixtures exist) but raises none of the gates.

**D5. Adopter features stay deferred.** Public `Scrypath.Testing`, indexable predicate and new Mix tasks stay off, as v1.49 prep B argued (costly API, no evidence). Highlight/crop and the paging guard are the only candidates and need the API-grilling session. Backend-seam refactor stays in "Later" and reopens only if a public Testing module is wanted.

**D6. Process and release milestones: none.** Dependabot, sigra cloak, Elixir 1.20 lane and cache work are non-milestone PRs with triggers (section 4).

## 3. How the catalog changes later cost and risk (J unless tagged)

- **UI changes get cheaper to review and slightly dearer to write:** one story per exported component or route is a gate, so each later ops PR adds one small file; the review question moves from "does it render" to "can the operator do the job" (`replies/accrue`).
- **Gate budget:** 10 of 12 used (V). Plan for zero new required gates: render-all runs inside the existing `ops-ui` job, untagged; anything else is advisory with a deletion trigger.
- **Dependency churn:** phoenix_storybook adds 9 packages (V, note A) and one NIF. Expect Dependabot PRs on `makeup*`, `mdex`, `mdex_native`; Dependabot already closed #141 pending the spike. Budget one extra bot PR a month; group them in `dependabot.yml`.
- **CI:** cache is 10.74 GB against a 10 GB cap (V, prep C). Measure before the spike lands; an advisory, path-filtered catalog job (exifcleaner: 340 s for 189 stories) is the shape.
- **Milestone-end review** becomes "open the storybook at the stable seeded URL". Library-only milestones (v1.50) answer in one word.
- **Release engineering:** `fixtures/` must stay out of the Hex tarball (the root `files:` allowlist already omits it, V note A; add a must-not-contain check).
- **Scope guard:** `PROJECT.md:224` lists "new UI surfaces" as out of scope. A dev-only catalog is not an adopter-facing surface, but say so in the same change that adds it, or a later agent will read the guard as blocking v1.51.

## 4. Release stance (J, built on prep C)

- No Hex release inside v1.49: everything is `chore(ops-ui)`, `docs` or `test`. The readiness PR's `fix(docs)` opens a release PR; leave it open as the accumulator (bot PRs have no CI until reopened).
- **First release candidate:** end of v1.50's guide phase, as 0.3.21 carrying the readiness fixes, the HexDocs regroup and the testing guide, only with the maintainer's yes. Time-box 2026-12-21 stays as the backstop (`fix(docs)` plus "no library behavior changes" note).
- **0.4.0** ships with the first new public API (highlight/crop keys or paging setting). `bump-patch-for-minor-pre-major: true` makes a `feat:` a patch, so 0.4.0 needs `release-as`; the commit-footer route is unverified (U, prep C). Decide the `~> 0.3` versus `~> 0.4` install line when v1.50 phase 3 opens; the install-line guard goes red at the bump by design (V, v1.48 audit).
- **Cadence:** adopt prep C's rule (behavior change, runtime-dependency advisory, adopter-facing doc defect, or announcement; never docs-only alone; one per 14 days except fixes). With 0.3.20 on 2026-11-21, the earliest rule-compliant non-fix release is 2026-12-05. Expect two releases at most across slots 1 to 4.
- Every release and release PR needs the maintainer's explicit yes (AGENTS.md).

## 5. Diminishing returns: not on the roadmap

Off, with the trigger that reopens each:

- **State grid, scenario manifest, hash-bound screenshots, full width-by-theme matrix, parallel gallery, paid LLM critic:** settled refusals. Reopen the manifest or grid only if the pilot exposes a coverage gap a reviewer cannot see.
- **Another theme-perfection milestone:** see D2.
- **Public hosted storybook:** phoenix_storybook is a server-rendered LiveView app whose playground evaluates templates server-side (V, note A), and the adopter names are uncleared. Reopen on an outside request for a component reference plus a resolved reuse grant.
- **Second demo host or new example app:** the fictional adopters live in fixtures; `examples/` already has three apps. Reopen on an outside report of a mounting problem.
- **Public Testing module, indexable predicate, backfill/reindex tasks, backend-seam refactor:** reopen on an outside report, a walk finding, or a named dependant's pain.
- **i18n matrices:** until the UI is localized.
- **Elixir 1.20/OTP 29 lane:** when 1.20 is the current stable or Dependabot/CI breaks on it.
- **Maintenance mode** (`guides/scope-and-reopen-policy.md`, prep C option 4): not now, because the maintainer has recorded decisions for the catalog. It becomes the default after slot 4 or after v1.50 if the walk finds nothing painful and no outside signal exists: a four-week breather, then re-run the traffic checkpoint. Exit triggers: an outside issue or PR, a repeating referrer, a runtime-dependency advisory, or four quiet weeks.

## 6. Adversarial pass

**Strongest case against the catalog leading.** Traffic is nil; the catalog's audience is the maintainer; it adds a NIF and nine packages to a cache over its cap; accrue spent 138 plans and still missed operator comprehension; sigra's own warning is weeks spent on a catalog no one can review with. A two-plan Adopter-ready guide would unblock a release and the only distribution lever. Better order: guide first, catalog second.

**Does it change the recommendation?** No, for three reasons. (1) Recorded owner decision, and AGENTS.md now forbids a prep note reversing one. (2) The catalog needs no maintainer decisions except the reuse grant, while Adopter-ready phase 3 needs an API-grilling session, so catalog-first keeps autonomous mode busy while that session is scheduled. (3) The thin shape (cap of 5, cut line after 197, no new required gate) bounds the downside to one PR set. What survives from the attack: run the read-only fresh-consumer walk as a side task during v1.49 so v1.50 starts with evidence (cheap, agent-only, no UI), and hold the line that v1.51 does not exist unless the review asks. Cheapest early test that I am wrong: the Phase 196 numbers (cold `ops-ui` over 3 minutes slower, NIF fails on Apple silicon or CI, isolation over a day). Any of them shrinks v1.49 to Phase 195 and promotes slot 2.

**Attack on D3 (announce late).** "Distribution is the only lever, so announce now." Counter: the 2026-11-21 HexDocs still shows the old overview until a release, the testing story is missing, and a launch spends the one shot (prep C). Would flip if the maintainer wants to announce earlier: then release the regroup first (trigger 4).

**Attack on the alternation principle.** It is a heuristic, not evidence; it could be wrong if the pilot goes very well. Then fold slot 3 into v1.49 and keep slot order otherwise.

## 7. Implications and early warnings

- **Phases:** v1.49 195 to 198, v1.50 199 to 201, v1.51 202+ (reserve), v1.52 after. Run milestone-end review at each close; for v1.50 and v1.52 it is a one-word check unless UI changed.
- **Early warnings:** a growing screenshot inventory before a stable seeded link exists; a second consecutive evidence-only plan; the release PR growing past two weeks without a decision; a Dependabot storybook PR red for more than a week.
- **Needs the maintainer:** (1) confirm slot order; (2) adopt or change the cadence rule; (3) say whether and when to announce (decides slot 4); (4) the reuse grant (already open). ScrypathOps on Hex is not asked now.
- **Other agents' areas:** correct the memory entry on v1.34; add the dev-only-catalog clarification to the `PROJECT.md` scope guard; the fixture agent should keep `fixtures/` out of the Hex tarball with a test; the CI agent should record the cache measurement before the spike lands.
