# v1.47 gap pass E: adversarial review of the milestone plan

Reviewed 2026-11-20 against `.planning/REQUIREMENTS.md`, the v1.47 section of `.planning/ROADMAP.md`, prep notes A to D, the brand playbook, the v1.46 retrospective and audit, `CI-EFFICIENCY.md` and `AGENTS.md`. Read-only on source. Every claim below was checked against the named file unless marked U (unverified).

Verdict: directionally correct. The three-phase split, the A order (189, 190, 191), the standing guardrails and the "no aesthetic claim" posture all follow the prep. One criterion is unsatisfiable as written (finding 1). Several prep decisions were handed back to the plan as open questions or dropped, so downstream would re-derive them (findings 2 to 9). Wording changes are given exactly.

Severity: blocker = the criterion cannot pass or forces a contradiction; should-fix = downstream will re-derive, contradict or miss something; nit = polish.

---

## Blockers

### 1. SITE-03 / Phase 189 SC4 cannot pass: three old website hexes also live in `brandbook/`, whose allowlist entry is exact and shrink-only

Evidence:
- B lists the old website palette to add to the deny set, including `d08e54`, `0c0f14`, `9aa4b6` (B "Verified facts", deny-list gap bullet). B only checked collisions with brand tokens, not with allowlisted files.
- `git grep` outside `.planning/`: `d08e54` has 4 hits in `brandbook/`, `0c0f14` has 10, `9aa4b6` has 1 (the rest of the 18 live only in `website/src`).
- `brandbook/` is covered by one prefix entry with `max_hits: 177` (`retired-identity-allowlist.json:6`). `checkAllowlist` fails on both directions: `total > max_hits` gives "remove the new values; do not raise the ceiling" (`ui-tokens.test.mjs:1059-1060`), and `HITS_CEILING` is shrink-only (`:1069`).
- So adding the three hexes in Phase 189 takes the prefix entry from 177 to at least 192 and the token test goes red, while raising the ceiling is forbidden.
- REQUIREMENTS.md:14 and ROADMAP.md:72 both say the old palette goes in at the asset swap with ceilings lowered, with no carve-out. ROLLING-ROADMAP.md says 191 takes ceilings "7/201 to 2/4", which also assumes p189 survives. Three documents, three different pictures.

Proposed wording (keeps the A order):
- REQUIREMENTS SITE-03: "The website's old palette is added to the retired-value deny-set in the same commit as the asset swap, except `d08e54`, `0c0f14` and `9aa4b6`, which also appear in `brandbook/` (4, 10 and 1 hits) and join the deny set in the Phase 191 commit that deletes `brandbook/`. The two `p189` allowlist entries are removed in the same commit, ceilings 7 to 5 entries and 201 to 197 hits, and the deny-list reports no retired value in website source."
- ROADMAP Phase 189 SC4: append "(the three shared hexes are asserted absent from website source by the site contract's own closed hex set until Phase 191 adds them to the deny set)".
- ROADMAP Phase 191 SC3: "...in the same commit, `d08e54`, `0c0f14` and `9aa4b6` are added to the deny set, ceilings go from 5 entries and 197 hits to 0 and 0."
- Alternative if the maintainer prefers: run 191 before 189 (D's original order). That removes the carve-out and moves the CLEAN-05 favicon guard ahead of the website, its next consumer, at the cost of renumbering the execution order. Recommend the carve-out: smaller change, numbers stay fixed.

---

## Should-fix

### 2. SITE-05 hands a settled prep decision back to the plan and double-counts "gate 9"

Evidence:
- B recommends `build-and-check` stays non-required (B "Recommendation" item 5, "Gate budget") and A footgun 1 says "Do not add it as a required gate to fix this". REQUIREMENTS.md:16 and ROADMAP.md:73 say "the plan records whether that job becomes required gate 9 of 12".
- B also says the new static contract is itself counted "conservatively as gate 9 of 12" (B section 2, "Gate budget", budget after phase 9 of 12). The roadmap never counts it. Playbook S26 says a check riding an existing step is still counted. `workflow_wiring_test.exs:1390` fails when the "Budget used: N of 12" line differs from the row count, so a mis-count shows up late and as noise.

Proposed wording:
- SITE-05: "Because merging to `main` deploys, the website `build-and-check` job is green on the exact PR head before merge. It stays a non-required check (prep B and A: 8.5 minutes on every PR, nearly all browser install). Re-open trigger: a rendering regression that only the browser job would have caught reaches `main`; the job then becomes gate 10 with its deletion trigger and churn."
- SITE-04 / SC1: add "The static contract takes ledger row 9 of 12 in `CONTRIBUTING.md` (enforcing file, lane, deletion trigger, churn) in the same change, and `workflow_wiring_test` is green."

### 3. Phase 189 success criteria omit most of B's checklist, so the verifier will not enforce it

Evidence: B section 2 lists static checks A.1 to A.8 and browser checks C.1 to C.7. The SC cover byte identity, token parity, hex closure, planted failures, theme behavior, fonts, lockups, favicons, contrast and console cleanliness. Not carried into any SC or requirement:
- `og:image` and `twitter:image` pointing at the pinned PNG as absolute URLs with width and height meta equal to the PNG (B "Social card"; no SVG `og:image`). Only "the social card" is named (SITE-01).
- CSP meta present with no `unsafe-inline` or `*` (A.6), `font-display: swap` on all three faces, relative `url()` only, no `http(s)://` in CSS (A.6).
- The non-ASCII allowlist {U+201C, U+201D, U+2019, U+2014, U+2192} that guards the missing U+00B7 glyph (A.7; playbook T10 and T19).
- Focus ring at least 2 px and at least 3:1, skip link first, 12 px floor, no `uppercase`, `transition-duration` 0 under reduce, `color-scheme` tracking the theme (C.5).
- `theme-color` handling. B keeps one `theme-color` in `layout.html` and has `theme.js` change it in dark, but SC1 and SITE-01 require "no color literal in website source". The dark value would be a hex literal in `theme.js` or `layout.html`. B never resolves this.

Proposed wording (one sentence, not a restatement): add to SC1 and SC3: "The remaining checks in prep note B section 2 (A.6 to A.8 and C.5 to C.6, including `og:image` and `twitter:image` absolute URL, width and height from the PNG header, CSP meta, `font-display`, the non-ASCII allowlist, focus ring, skip link, 12 px floor and `color-scheme`) each have a planted failure or an accept case; an item dropped is recorded with its reason." And add to the plan's resolved list: "`theme-color` values are emitted by `build.mjs` from tokens (data attributes read by `theme.js`), so no color literal appears in `layout.html` or `theme.js`."

### 4. Phase 190 copy changes will hit the Phase 185 preservation receipts, which only the advisory lane runs; the roadmap plans a local run instead of exact-head evidence

Evidence:
- `ui-preservation-states.ts:194` matches `/^Control Room$/` (case-sensitive). `ui_routes_preservation.spec.ts:93` uses `exact: true`. `ui-review.selftest.mjs:436` embeds the label. `ui_preservation.test.cjs:226` too. In total 12 e2e files mention "Control Room" (`admin_path_motion`, `admin_screenshot_matrix`, `admin_screenshots`, `admin_shell_chrome`, `admin_shell_wash`, `helpers/theme-grid.ts`, `helpers/ui-preservation-states.ts`, `operator`, `ops_reskin_contract`, `phase1_screens`, `ui-review.selftest.mjs`, `ui_routes_preservation`). Playwright string `name:` matching is case-insensitive substring, so most survive; the exact and regex ones will not. A said "none by exact grep"; that is true only for a narrow grep.
- The preservation and phase185 cases run only in `ecommerce-e2e (advisory)` (`ci.yml:636-638`, schedule or dispatch). Playbook T9 and T17 record the same failure in 187: a "text must not change" guard failed four of 61 cases on one approved word, and the fix was a pinned allowlist inside the guard with a self-test. Phase 190 changes many more strings (Control room, Last succeeded, Retry queued, Searchable fields).
- ROADMAP.md:87 asks for "one local run of the ordinary e2e partition". AGENTS.md says completion needs executable tests or exact-SHA hosted evidence. D says to keep the v1.46 practice of dispatching `ci.yml` on the exact head.
- A baseline exists now: the 2026-11-20 nightly (run 44689855947, head `bd69905e`) has `ecommerce-e2e` green. D and CI-EFFICIENCY finding 7 told planners to read it first; the roadmap does not record it, so a red after 190 is attributable.

Proposed wording:
- ROADMAP 190 research flag: replace the count sentence with "Baseline: `ecommerce-e2e` was green on the 2026-11-20 nightly (run 44689855947, `bd69905e`), so any red after this phase is a regression of the phase. Coupling inventory before planning: the 12 e2e files above, `ui-preservation-states.ts` and `ui_preservation.cjs` copy receipts (approved-copy allowlist pattern from playbook T9 and T17), and the ExUnit `=~ "Control Room"` assertions."
- SC4: "...and `ci.yml` dispatched on the exact PR head shows `ecommerce-e2e` green (the lane that runs the preservation receipts); a local run is for iteration only."
- SC2: widen the scan from "ops source, ops tests, the ecommerce tests and e2e specs" to "every tracked file outside `.planning/`" with an explicit exception list. Verified current non-test hits also exist in `DESIGN.md:23,41`, `scrypath_ops/assets/css/DESIGN-TOKENS.md:225,243,587`, `scrypath_ops/docs/operator-ia.md:18`, `scripts/ci/ui_preservation.test.cjs:226` and the demo seed task text (`scrypath.demo.seed.ex:195`). `GLOSSARY.md:31` already says "Control room".

### 5. COPY-01 refers to "the recorded rule" without stating it, and "every rendered surface" has no inventory

Evidence: REQUIREMENTS.md:20 and ROADMAP.md:84 say "Pending versus Queued per the rule" and "on every rendered surface". The Inputs line (ROADMAP.md:30) does not link `research/brand-and-catalog/V1.46-PREP.md`, where the rules are written (lines 100 and 115: "Pending is a row or schema aggregate; Queued is one update's step and the host-queue outcome"; "Clear does not mean Searchable"). Playbook W4 and S4: a clean inventory is not full coverage; state what a guard proves.

Proposed wording:
- SC1: "...Pending names a row or schema aggregate state and Queued names one update's step or the host-queue outcome (rule: V1.46-PREP lines 100 and 115)..." and replace "on every rendered surface" with "on each surface listed in the guard table; forms the table does not cover (JS strings, some attributes) are listed as not covered".
- Add `research/brand-and-catalog/V1.46-PREP.md` (glossary rulings) to the Inputs line.
- D item 6 handed IN-02 ("Clear" beside a retained observation) to COPY-01; it is absent from COPY-01. Either add "`Clear` is never shown beside a retained observation as if it were current" to COPY-01, or record it as deferred with a reason in the Phase 190 context.

### 6. COPY-04's Cancel-focus assertion has no named lane, covers "a destructive dialog", and contradicts ROLLING-ROADMAP

Evidence: ROADMAP.md:87 says "a browser assertion". D (item 6.1) put it on the nightly or dispatch lane. There are three destructive confirms (`failed_sync_live.ex` about 1224, `sync_drift_live.ex` about 2463, `search_live.ex` about 1930 per 187-CONTEXT:49). `ROLLING-ROADMAP.md` carry-forward still says "the Cancel-focus assertion and two unpinned copy values go to 194", which contradicts COPY-04 in Phase 190.

Proposed wording: COPY-04: "A Playwright assertion in the ordinary e2e partition (advisory lane, so proved by the exact-head dispatch in Phase 190 SC4) shows Cancel holds focus when each of the three destructive confirms opens; ..." And fix the ROLLING-ROADMAP carry-forward (finding 9).

### 7. The kickoff chore is a fail-open denylist, is a hard dependency of Phase 189, and has no acceptance

Evidence:
- ROADMAP.md:38 and REQUIREMENTS.md:50 define the chore as "must not skip when `brand/`, `scrypath_ops/`, `examples/`, `scripts/ci/`, `lib/`, `mix.exs` or workflow files change". That omits paths the existing `ops-ui-path` regex already treats as relevant (`dev/`, `config/`, `priv/`, `language/`, `fixtures/`, `test/release/`, `mix.lock`; `ci.yml:367`) and the paths v1.47 itself edits (`website/`, `dev/mix/tasks/`, `test/mix/tasks/`). A new path under any of them would skip the browser lanes silently.
- CI-EFFICIENCY finding 2 words it as skip when "only `.planning/**`, `docs/**`, `*.md` and tests those lanes do not read changed", which is an allowlist.
- ROADMAP.md:66: Phase 189 "Depends on: the kickoff CI chore merged". The chore's own risk is "low to medium (path list correctness)", and it carries no requirement and no success criterion, so a slip in an optional speedup would block the milestone.
- `#132` (upload-artifact bump) is still open and red because `workflow_wiring_test` pins the old SHA (C Q4); Phase 189 edits `website.yml`, which `#132` also edits.

Proposed wording: "Kickoff chore (preferred before Phase 189, not blocking it): the `ecommerce-path` classifier runs the browser lanes unless every changed path matches `^(\.planning/|docs/|[^/]+\.md$)`; the required contexts still report. Acceptance: a planted `.planning`-only diff skips, and a diff touching any one other path runs, both checked in `workflow_wiring_test`. Also resolve `#132` (relax the SHA pin to a pattern, per prep C) and re-run `#129` on the re-skinned base." Phase 189 "Depends on": "Nothing within v1.47; the kickoff chore is preferred first but does not gate it."

### 8. Missing lessons: milestone close check, preview staleness, UI-review rule, clean-snapshot rule, fixture-copy rule

Evidence and wording, one line each:
- Retrospective "Patterns Established": an independent read-only check of merged `main` found two defects per-phase verifiers missed. The roadmap has no closeout item. Add to Delivery: "At milestone close, one read-only cross-phase check of merged `main` at the final SHA (fresh context; it is a check, not independent or aesthetic approval), including the other consumers of every asset changed."
- Audit debt "UI-PREVIEW.json records pre-squash commits; refresh before the next visible UI work" and AGENTS "UI work" (`ui:preflight`, `UI-REVIEW.md`, "captures and passing tests alone are not a design pass"). Phase 190 is ScrypathOps copy; A (footgun 8) says refresh before 190 captures, D (item 4) says before 193. Nothing in the roadmap picks one. Add to Phase 190: "No preview capture or `ui:review` runs in v1.47; wording is proved by tests and the exact-head dispatch only. `UI-PREVIEW.json` gets a one-line 'stale since squash, run `npm run ui:preflight` and refresh before rendered review' note; the refresh itself is the first v1.48 rendered-evidence phase. The phase record states that no design pass was done."
- AGENTS "Some repository contracts build a clean Git snapshot": the roadmap mentions it only under Phase 191. Add to GATE-02: "A fix to a snapshot-based gate is committed before the gate is rerun (the gate reads HEAD, not the working tree); first `mix verify.repository_contracts` run uses the escalated permission."
- Retrospective: "a plan that changes a file the verifier fixture copies: run the whole CI Node step locally". `ecommerce_lifecycle.test.cjs:111-125` copies `contrast-checker.mjs`, `app.css`, `contrast-pairs.mjs`, `brand/tokens.json` and `brand/brand.json`. Phase 189 may copy or touch `contrast-checker.mjs` and reads `brand/`. Add to GATE-02: "A plan that touches a file the verifier fixture copies runs the whole CI Node step locally before the final gate."
- Release Please is working again (fixed 2026-11-20; PRs #125 and #146 merged). `feat` and `fix` squash titles on `main` will open release PRs with misleading notes (C Q1; `release-please-config.json` has no type filter). Add to Delivery: "Squash titles use `chore(...)` or `docs(...)`, not `feat` or `fix`, because no library change ships; a release PR appears only if the maintainer wants one."

### 9. ROLLING-ROADMAP.md still contradicts the plan (same change should have updated it)

Evidence (`reference/ROLLING-ROADMAP.md`): the 191 row says ceilings "7/201 to 2/4" (contradicts CLEAN-03, which ends at 0); the carry-forward says the Cancel-focus assertion and unpinned copy go to 194 (contradicts COPY-04); it says the preview refresh is "probably 193" (see finding 8); the older re-plan table still lists "v1.47 Catalog foundation" with phases 191 to 195 and v1.48 and v1.49 under the old numbers, with no superseded marker. The roadmap commit (`27a3cbed`) touched only REQUIREMENTS, ROADMAP and STATE; AGENTS "Milestone preparation" says the rolling roadmap is updated in the same change.

Proposed wording: fix the 191 row ("allowlist ends empty after Phase 189 removes the two `p189` entries"), move the Cancel-focus carry-forward to Phase 190, and add "Superseded by the Post-v1.46 proposal" to the old v1.47 to v1.49 rows.

### 10. SITE-05 / SC5 stops at the merge, but the merge is the deploy

Evidence: ROADMAP.md:73 records `build-and-check` green on the PR head. B section 3: "deploy needs build-and-check on the merge commit... Rollback is a revert PR". Nothing verifies that the deploy ran or that the live site serves the pinned assets. Hex has a post-publish check (`verify-published-release`); the website has none.

Proposed wording: add to SC5: "After the squash merge, the `deploy` job for the merge commit is recorded green, and one scripted request check against the live site URL confirms the three font URLs, both lockups, both favicon links and the social card return 200 with the pinned hashes (the same assertions as `check.mjs`, base URL from an environment variable). A failed live check means a revert PR, not a retry."

### 11. CLEAN-05's consumer scan, as worded, fails on a legitimate consumer; the upstream report is not an executable check

Evidence: D's scan fails on the string `icon/favicon.svg` in tracked non-`brand/` files. `dev/mix/tasks/brand/update.ex:84` contains `{"assets/icon/favicon.svg", "icon", ...}` (the pin updater's source list), so the scan fails on day one. REQUIREMENTS.md:31 also says "the defect is reported upstream", an external write to `szTheory/scrypath-brand` that is not a testable criterion and could block the phase.

Proposed wording: CLEAN-05: "...a scan proves no tracked file outside `brand/`, `.planning/` and the pin updater `dev/mix/tasks/brand/update.ex` references `icon/favicon.svg`. The upstream issue text is drafted in the phase record (D item 5); filing it is the maintainer's step and does not gate the phase." Update SC5 the same way.

### 12. Settled recommendations quietly became open choices or silent omissions

- Picker: B (confidence 0.6) gives a fallback ("drop the picker if plan 02 runs long") but no trigger. ROADMAP.md:67 records the fallback without a rule. Add: "If the picker, `theme.js`, dark tokens and their browser assertions are not green by the end of plan 189-02, ship light-only and amend SITE-02 and SC2; this is not a stop-and-ask."
- Cross-directory import of `contrast-checker.mjs` (ROADMAP.md:67 leaves it open). House rule in AGENTS: copy beats a dependency; B itself offers the 12-line copy. Decide: copy the WCAG function and assert its results against the ratios published in `brand/brand.json`, which also removes the need for a path-filter entry for `examples/`.
- Website browser install is 8 of 8.5 minutes (CI-EFFICIENCY finding 5, "folded into v1.47 Phase 189"). No requirement or SC owns it. Add to the Phase 189 plan list: "measure the install step cold and warm; apply the cache or drop `--with-deps` only if the browser check is unchanged; record in `CI-EFFICIENCY.md`".
- B "Out of scope": the book's site content spec (single Plum button, command picture, no version badge) is not in REQUIREMENTS "Out of Scope". Add the row so SITE-01 is read as identity only and the h1 and CTA assertions stay.
- D item 6.2 (IN-07, palette input suppresses its focus outline, an accessibility defect) is neither in CLEAN-04 nor deferred in writing. Either add "no `outline: none` on an input without a replacement ring" to CLEAN-04's static invariants (cheap, same file) or record the deferral to v1.48 with D's reason.
- CONTRIBUTING.md:247 scopes the 12-gate cap to "The brand and UI milestone (v1.46)" and :258 says the component-contract row is replaced "in v1.47" (now v1.48). GATE-02 relies on that cap and CLEAN-06 only rewords the token row. Extend CLEAN-06: "reword the budget sentence so the cap of 12 carries over (A, item 3 of 'What needs the maintainer'), and change 'in v1.47' to 'in v1.48' in the component-contract row".

---

## Nits

13. `REQUIREMENTS.md:15` says `website/check.mjs`; the file is `website/scripts/check.mjs` (verified with `ls`). Fix the path.
14. `REQUIREMENTS.md:6` says "Every criterion is an executable check". SITE-05 (a recorded decision), CLEAN-06 (a doc reword) and CLEAN-05 (upstream report) are not. Reword to "Every criterion is an executable check or a recorded decision stated as such."
15. COPY-03 "a shape the v1.48 copy lint can ingest without rewriting" is untestable because the lint does not exist. Pin it: "one table file with rows `{id, forbidden, required, surfaces}`; a test fails if a row lacks any field or has empty `surfaces`; the other copy tests read only this table (playbook W13: no second copy of the strings)".
16. CLEAN-04 should say the wrapper floor `@min_token_test_calls` (`ui_contrast_contract_test.exs:104`, now 53) is raised by the number of cases added (D item 1). "The docs" in SC4 should name where: the CONTRIBUTING ledger row and `scrypath_ops/assets/css/DESIGN-TOKENS.md`.
17. CLEAN-03's "(7 entries and 201 hits today)" invites copying D's `7/201 to 2/4` arithmetic. Add "at the start of Phase 191 the allowlist is 5 entries and 197 hits (after Phase 189), and the first commit takes it to 4 and 194, the second to 2 and 178, the third to 0 and 0" (derived from D's per-commit hits: favicon 3, readers 1 plus 15, data 177 plus 1).
18. Phase 189 and 190 touch disjoint files, so they could run as parallel PRs off fresh `main` (no stacking). The roadmap forces serial merges, each needing about 20 minutes of strict-branch CI (CI-EFFICIENCY finding 4). Optional: "190 may be developed in parallel with 189; merge order by green, each rebased on fresh main."
19. SC1 and SC3 do not say that Chromium is the only browser, and B left the CSP meta in Safari and the `.ico` contents unverified. The verification record should carry a "what this does not prove" line (rendered quality, other browsers, real screen readers), as the v1.46 audit did.
20. Order inside 191 puts the `RETIRED_DIR` and `retire-last` vocabulary question in CLEAN-06 only by implication. D says keep `RETIRED_DIR` and the `retire-last` tag in `ui-tokens.test.mjs` (`:793,:808`); state it so the executor does not delete them as dead after the allowlist empties.

## Checked and fine (no change needed)

- Gate budget arithmetic (8 rows) matches `CONTRIBUTING.md:250-258`.
- The closed hex-set check is sound: every hex in the pinned lockups, favicons and avatars is in `brand/tokens.json`'s 31 hexes (script check).
- `brand.pin.json` always changes with any pinned asset, so `brand/**` alone is enough for the website push filter; B's extra fonts path is redundant.
- No criterion claims aesthetic or independent-review approval; the AGENTS Phase 185 correction is respected.
- Squash-on-green with the extra `build-and-check` condition (ROADMAP.md:36) is consistent with AGENTS and the prep, apart from finding 10.
