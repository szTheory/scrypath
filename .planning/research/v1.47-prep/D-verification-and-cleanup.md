# v1.47 prep, Decision D: verification gaps and cleanup carried out of v1.46

Prepared 2026-11-19 (read-only on source; measurements from `gh run view`, local `node` runs and grep). Facts and judgment are kept apart in each section. Nothing here is a phase plan.

## Summary table

| # | Item | Recommendation | Confidence | Placement |
|---|------|----------------|-----------|-----------|
| 1 | Computed-style specs advisory, 12 px floor ungated | Static invariants inside the existing token test (no new required gate); leave browser specs on nightly/dispatch | High on static check, medium on "not promoting a spec" | First v1.47 phase, plan 2 (test-only) |
| 2 | Cleanup chain | Three commits: favicon, then readers (test, task, alias, phase99 entry), then the data (`brandbook/`, CI regex), allowlist and ceilings in lockstep each time | High | First v1.47 phase, plan 1 |
| 3 | Two token sources | After cleanup the chain is single-source; the existing token-map parity is the derive-or-parity check; add one sentence of documentation, nothing else | High | Rides plan 1 |
| 4 | Retained preview | Do nothing now; refresh once, immediately before the first phase that needs visible UI evidence | High | Just before 193 (pilot), not before cleanup/189/190 |
| 5 | Unthemed `favicon.svg` | Report upstream (defect is real and still present upstream) and add a tripwire test plus a "no consumer of the unthemed file" scan | High on the defect, medium on the guard shape | Plan 2 of first phase, before 189 (website is the next consumer) |
| 6 | Unclosed verification claims | Close two as already done; schedule 4 small automatable ones; leave the rest as recorded Info | Medium-high | Mixed, see list |

## Verified facts (all checked this session unless marked)

### CI cost (item 1)
- Required critical path on a PR (run 44665733439, PR #143): `repository-contracts` 911 s, `ecommerce-mounted` 886 s, `ops-ui (path-scoped)` 455 s, `core` 337 s, `package` 191 s, `backend` 58 s. Earlier PR #138 run: 848 s, 1062 s, 469 s, 358 s.
- `repository-contracts` is 575 s Node browser-behavior tests plus 206 s `mix verify.repository_contracts` (run 44647452094 steps). The token test (`ui-tokens.test.mjs`, 59 tests) runs in about 1 s locally.
- `ecommerce-e2e (advisory)`: 1394 s on the exact PR head dispatch (307 s image bake plus 1032 s run); 1194 s on the 11-19 schedule run. Only on `schedule` (06:37 UTC daily) or `workflow_dispatch` (ci.yml lines 636-638).
- `ecommerce-mounted` (required) runs `harness.spec.ts` and `operator.spec.ts` only; 570 s test step on a cold PR cache, 254-287 s on warm nightlies.
- Nightly history: `ecommerce-e2e` job failed on 7 of the 8 scheduled runs from 2026-11-12 to 11-18 (run-level result stays "success" because the job is advisory) and passed on 11-19 (run 44474350978, head 8beb3ed0, before the re-skin merged). I opened one failure (44253508708): the standalone `phase173_copy.spec.ts` tests failed in under 110 ms each. I did not triage the other six. The first nightly on re-skinned `main` is the 11-20 06:37 UTC run; its result is free evidence.
- Gate ledger (CONTRIBUTING.md): 8 of 12 used; `workflow_wiring_test.exs` fails on more than 12, an empty trigger/churn cell, or a missing enforcing file. The "Token parity and retired-identity deny-list" row already covers `ui-tokens.test.mjs` in `core` and `repository-contracts`.
- Ledger oddity: that row's deletion triggers read "delete the parity half once the token map has no pending rows" and "delete the deny-list half once the allowlist holds no `retire-last` entries". `PENDING_CEILING` is already 0, and the second condition is met by item 2. Read literally, both halves are now deletable. They should not be (see item 3); the row needs rewording in the cleanup phase.

### The 12 px floor
- `--text-ops-xs` and `--text-ops-sm` are both `0.75rem` (app.css 250-251). A scratch script (`/private/tmp/claude-501/-Users-jon-projects-scrypath/6f984be8-406d-4e14-978c-1e44435e187a/scratchpad/floor.mjs`, throwaway) resolved all 90 `font-size` declarations in `scrypath_ops/assets/css/app.css` through the custom properties: zero below 12 px, one `inherit`. No `text-[...]` arbitrary sizes, no `uppercase`, no `text-transform`, no `infinite` and no off-set font weights exist in `scrypath_ops/lib` or app.css source. So a static gate would be green today.
- It cannot see everything: `ops_ui.ex:1854` emits daisyUI `btn-xs` (11 px) when a caller passes `size: :xs`, relying on `text-ops-body` to override. Only the browser spec (P-02, `ops_reskin_contract.spec.ts:1251`) computes the rendered size. The 187 verifier's mutation (xs to 0.6875rem) survived every static check.
- P-02 sits inside a 2143-line spec whose `beforeAll` seeds an incident and saves two searches (240 s timeout); it is not cheap to lift into a required lane as is.

### Cleanup chain (item 2): everything that reads or names `brandbook/`
Grep of the whole tree outside `.planning/` (hidden files included):
| File | Relationship | Kind |
|------|--------------|------|
| `dev/mix/tasks/verify/ui_tokens.ex` (898 lines) | reads `brandbook/tokens/tokens.json` (line 27) | reader |
| `test/mix/tasks/ui_tokens_contract_test.exs` (836 lines) | reads `brandbook/tokens/tokens.json`, `tokens.css`, `README.md`, `daisyui-theme.example.js`; clean-copy test copies the task, the test and phase99 into a temp repo | reader |
| `dev/mix/tasks/verify.phase99.ex:13` | lists the contract test in `@focused_tests`, so `verify.repository_contracts` runs it | reference |
| `mix.exs:100` | `"verify.ui_tokens": :test` preferred env | reference |
| `.github/workflows/ci.yml:367` | `ops-ui-path` regex contains `brandbook/` | reference |
| `examples/scrypath_ecommerce/retired-identity-allowlist.json` | prefix entry (177 hits) plus `ui_tokens.ex` (1), contract test (15), `ci.yml` (1), demo favicon (3); sums to 201 with the two `p189` entries (4) | ratchet |
| `test/mix/tasks/brand_pin_contract_test.exs:859` | builds the string `"brand" <> "book"` to prove the Hex package guard flags it | guard, not a reader; keep |
| `ui-tokens.test.mjs:808` | `RETIRED_DIR` built at runtime; the deny-list flags the directory string anywhere in the tree | permanent tripwire; keep |
| `brandbook/` itself | 36 files, 384 KB; its only internal self-references are README/notes/examples | data |
Not referenced: `mix.exs` `files:`/docs config, `docs/`, `CONTRIBUTING.md`, `scrypath_ops/`, `website/`, `contrast-checker.mjs`, any other workflow or script. `workflow_wiring_test.exs:1297` checks that the path regex names `brand/` (not `brandbook/`), so the regex edit does not break it. `verify.phase99_test.exs` pins only the contrast test name, not the contract test.
- The ratchet is lockstep: a stale allowlist entry, a hit count below its ceiling, or a ceiling that does not equal the sum of `max_hits` all fail `ui-tokens.test.mjs` ("planted ... fails" cases). `ALLOWLIST_CEILING` is 7 and `HITS_CEILING` 201 today.
- Demo favicon (`examples/scrypath_ecommerce/priv/static/favicon.svg`): it is not dead. It is linked from `layouts.ex:25`, served via `static_paths` and asserted by `page_controller_test.exs` (storefront favicon equals the file). It draws the retired violet `#5b4ad1` and copper `#c17a3e`.

### Tokens (item 3)
- `brand/tokens.json` (pinned, hash-guarded) is read by `ui-tokens.test.mjs` (`BRAND_TOKENS`, line 57). `scrypath_ops/assets/css/token-map.json` has 42 rows, each with an `adopt`/derive disposition per theme and `applied` flags; `PENDING_CEILING = 0`, `HEX_OUTSIDE_CEILING = 0`. The test checks map-to-CSS parity both directions, applied rows equal pinned brand hex, built CSS equals source blocks, and every hex literal in `app.css` is brand or declared.
- Nothing outside the legacy task and test reads `brandbook/tokens/*`.

### Favicon (item 5)
- `brand/assets/icon/favicon.svg` (891 bytes) has `class="g"` and `class="l"` paths, no `<style>`, no `fill`; it renders black. `BRAND.md` line 225 says it "follows the device's light or dark setting: in dark mode its slash is Orchid". So the file contradicts the book that ships with it.
- The upstream repo `szTheory/scrypath-brand` still serves a 891-byte `assets/icon/favicon.svg` (`gh api`), and has no open issues. The defect was already noted in `188-RESEARCH.md` finding 12; I found no record that it was reported.
- Workarounds today: ops serves `favicon-light.svg` (`reskin_static_contract_test.exs:57`), HexDocs uses `favicon-light.svg` (`mix.exs:298`, pinned by `package_metadata_test.exs`). Nothing stops a new consumer (website in Phase 189, the demo favicon swap below) from using the unthemed file.

### Preview (item 4)
- `.planning/UI-PREVIEW.json`: branch `ui/next` at `/Users/jon/projects/scrypath/.claude/worktrees/ui-experience-reconciliation`, `implementation_head` 3bc565c3 (the pre-squash PR #138 head), `base_main` 8beb3ed0. Main is now 2f767884 and later. `npm run ui:preflight` (`ui-review.mjs:789`) compares the mount, branch and `git ls-remote origin refs/heads/main` against the container, so a stale preview fails loudly rather than silently. I did not run it (it needs Docker).
- GATE-03's refresh and preflight halves were done before merge; `ui:review` was deliberately not run on the retained preview (UI-PREVIEW.json status text).

### Unclosed claims in the 186/187/188 verification files (item 6)
| Claim | Source | State |
|-------|--------|-------|
| SKIN-08 Draft PR plus exact-head hosted run | 187-VERIFICATION `pending_orchestrator` | Closed: dispatch 44647452094 on the PR head, PR #138 merged (audit) |
| GATE-03 second half (preview to final head, two preflights) | same | Closed pre-squash (UI-PREVIEW.json); only the squash staleness remains (item 4) |
| 188 hosted CI "pending orchestrator" | 188-VERIFICATION line 147 | Closed: PR #139 run 44663026458 green |
| 187 warning 3: long gates last ran 5 code commits before head | 187-VERIFICATION | Closed by the exact-head hosted run |
| 187 warning 1/2: 12 px floor and advisory browser specs | same | This decision |
| 187 warning 4: no browser assertion that Cancel is focused when a destructive dialog opens | same | OPEN; one Playwright assertion |
| 187 warning 5: 12 after-captures from 9217f326, not the final commit | same | Open but harmless (built CSS unchanged); not worth re-capture |
| 187 warning 6: three dormant `infinite` declarations in built CSS (daisyUI) | same | Open, documented; roadmap wording "ops-authored code only" |
| 187 warning 9: promotion-notice body copy and `ops_modal` default focus selector unpinned | same | OPEN, unpinned |
| 187 IN-01..IN-08 (Pending vs Retrying wording, `Clear` beside a retained observation, dead code, palette input focus outline suppressed, `.ops-flash__close` rule, "Replace live index" wording) | 187-REVIEW-FIX "out of scope, untouched" | OPEN Info items; IN-07 is an accessibility item |
| 186 IN-03 (wrapper does not require planted names) | 186-VERIFICATION | Closed since: wrapper now reads test names from the file with a floor (`@min_token_test_calls 53`); IN-04 and IN-06 not re-checked |
| README header does not load on hex.pm | audit, 188 | OPEN, release-blocking cosmetic: switch two URLs to commit-pinned raw.githubusercontent.com before the next Hex release (`docs/releasing.md`) |
| Five rare code-token types uncoloured in HexDocs | audit | OPEN, cosmetic |
| Rendered quality never judged | audit | Not claimable by automation; keep as the standing "what this does not prove" line |

## Item 1: computed-style specs and the 12 px floor

Options considered
- A. Leave as nightly. Zero cost, zero new protection; the 12 px floor can regress with every green required check, and the nightly has a history of being red and unread.
- B. Static invariants in `ui-tokens.test.mjs`. About 1 s, runs in `core` and `repository-contracts` today, is an extension of the existing ledger row (still 8 of 12), and follows the house planted-failure pattern.
- C. Promote one spec to a required lane (for example a stripped P-02 in `ecommerce-mounted`). Adds Docker browser time to a lane already at 570-1062 s on PRs, needs a new light spec (the existing one has a 240 s seeding `beforeAll`), uses ledger slot 9 of 12, and needs a deletion trigger and per-PR churn text.
- D. New path-scoped required e2e. About 23 minutes on matching PRs; disproportionate for a one-person gate budget.

Recommendation: B now, plus keeping A for the rest. Content of B (each with a planted failing case and an accept case, in the same file):
1. `--text-*` tokens and every `font-size` literal in ops source CSS resolve to at least 12 px (the scratch resolver is about 15 lines; it passes today on 90 declarations).
2. No `text-[Npx|rem]` arbitrary size in `scrypath_ops/lib` and `assets/js` below 12 px (zero exist).
3. No `text-transform: uppercase` or `uppercase` class, and no `infinite` in ops-authored CSS (zero exist; P-02 and the roadmap already claim these, so this converts claims to cheap checks).
Add the new test names to nothing: the wrapper in `ui_contrast_contract_test.exs` reads names from the file; raise `@min_token_test_calls` by the number added. Reword the row in CONTRIBUTING.md to say "extends this gate" and state honestly what it does not prove: declarations in source, not rendered size (the `btn-xs` path stays browser-only).
Also: watch the 11-20 nightly; triage any red `ecommerce-e2e` as the first v1.47 action. For visible-UI PRs, keep the v1.46 practice of dispatching `ci.yml` on the exact head and attaching the run (a one-line CONTRIBUTING note, no gate).

Lenses (strongest point each)
- Security: none material; the static check parses only repo files with bounded regexes (follow the repo's "linear patterns" comment).
- Product: the 12 px floor is the operator-readability promise of the re-skin; a regression here is user-visible, and the cheap check protects it for free.
- Architecture: put the check where the token chain already lives, rather than a new file or job.
- DevOps/CI: measured 1 s versus 570-1394 s; B costs no new job, C and D cost minutes on every UI PR.
- Accessibility: 12 px is a legibility floor, not a WCAG criterion; the check must not be presented as accessibility proof.
- OSS maintainer/adopter: adopters of `scrypath_ops` get the floor even if they never run the demo e2e.
- Test design: mutation-style planted failures are already the house standard; the gap the verifier found (mutation survived) is exactly a missing planted case.
Patterns: cheap static ratchet for declarations, browser spec for computed truth. Anti-patterns: a required gate whose deletion trigger is "someday"; a nightly nobody reads. Footguns: scanning built CSS (daisyUI `btn-xs` 11 px, dormant `infinite`) produces false positives, so scan source only; a regex on Tailwind classes misses classes built from string interpolation.

Adversarial pass: "A static floor is theatre because `btn-xs` bypasses it." True for that one path; the answer is to say what it proves and to keep the browser spec (and the nightly) for rendered size. "Then promote P-02." Its cost and slot are not justified by one observed hole; revisit if a regression reaches `main` that only a browser spec would have caught, or if nightly e2e stays red more than a week.
What would change it: a computed-style regression escaping to main (promote a light spec to `ecommerce-mounted`, ledger slot 9); the 11-20 nightly or later showing P-01..P-21 red.

## Item 2: cleanup chain and commit order

Order constraint (verified from the 186 verifier finding and the ratchet code): readers go before the data, and the allowlist plus both ceilings move in the same commit as each deletion. Run the focused checks first (`node --test examples/scrypath_ecommerce/ui-tokens.test.mjs`, about 1 s; `mix test test/mix/tasks/ui_contrast_contract_test.exs test/mix/tasks/workflow_wiring_test.exs test/mix/tasks/verify.phase99_test.exs`), commit, then run `mix verify.repository_contracts` once per commit on the committed state (some contracts snapshot HEAD; an uncommitted fix cannot repair a clean-copy check of the previous commit, per AGENTS.md).
1. Commit 1, demo favicon. Replace `examples/scrypath_ecommerce/priv/static/favicon.svg` with a byte copy of `brand/assets/icon/favicon-light.svg`; remove its allowlist entry; `ALLOWLIST_CEILING` 7 to 6, `HITS_CEILING` 201 to 198. Keep the controller test (it compares to the demo's own priv file). Pin "demo favicon equals the pinned light favicon" in a root-level test that can read `brand/` (I did not verify whether the ecommerce Docker build context includes `brand/`; do not make the ecommerce test depend on it). Visible effect: the demo tab icon changes colour; no preview needed.
2. Commit 2, readers. Delete `test/mix/tasks/ui_tokens_contract_test.exs`, `dev/mix/tasks/verify/ui_tokens.ex`; remove `"verify.ui_tokens": :test` from `mix.exs`; remove the contract test from `@focused_tests` in `verify.phase99.ex`; remove the two allowlist entries; ceilings 6 to 4 entries, 198 to 182 hits. `brandbook/` still exists and still matches its own prefix entry (177).
3. Commit 3, data. Delete `brandbook/` (36 files); remove the prefix entry and the `ci.yml` entry; drop `brandbook/|` from the `ops-ui-path` regex at ci.yml:367; ceilings 4 to 2 entries, 182 to 4 hits (the two `p189` website entries). This commit changes `ci.yml`, so `ops-ui` runs (about 450 s); that is expected.
Docs: reword the two CONTRIBUTING ledger triggers (item 1 oddity); leave `RETIRED_DIR` and the `ALLOWLIST_TAGS` `retire-last` tag in `ui-tokens.test.mjs` (fixtures use them; deleting is churn for no gain). Add the Hex-package planted-name guard as is. `mix.exs` `files:`, `docs/`, README and the workflows need no other edit (verified by grep).
What is lost: DTCG structure validation of a file that no longer exists, a 898-line bounded JSON/CSS parser (dev-only, `:test` env, not in the Hex package), and doc-text asserts about `brandbook/README`. None is load-bearing once the token-map parity stands.
Could commits 2 and 3 be one? Yes, also green; the split buys bisectability for one extra full-lane run. Commit 1 is independent and can ship alone.

Lenses
- Security: deletes 1,700 lines of bespoke parser and test code and a second copy of colour values; smaller surface, no new dependency. Only workflow edit is a path regex, no trigger or permission change.
- Product: nothing user-facing except the demo favicon colour.
- Architecture: removes the last consumer of the retired authority, so the retired directory can become a pure tripwire.
- DevOps: lockstep ratchet means each step is locally checkable in seconds before a 14-minute lane.
- Accessibility: none.
- OSS adopter: contributors stop meeting two token documents and a stale brand book directory.
- Test design: the `retire-last` allowlist is the checklist; when it holds only `p189` entries the cleanup is provably complete.
Footguns: deleting `brandbook/` first breaks `repository-contracts` (verifier finding); the `ci.yml` allowlist entry goes stale the moment the regex is edited, so the same commit must remove it; a ceiling lowered without the entry (or the reverse) fails; forgetting the `mix.exs` alias leaves a task pointing nowhere (the task module compiles only under `:test`, so the failure shows only when someone runs it).
Adversarial pass: "Keep `brandbook/` as an archive." Git history is the archive; keeping it keeps 177 allowlisted retired values that the deny-list must keep tolerating. "Do it as one commit to avoid ceiling churn." Acceptable fallback; the three-step order is the safe default, not the only safe one.

## Item 3: single source of tokens

After the cleanup the authority chain is: `brand/tokens.json` (pinned and hash-guarded) is the only authored colour source; `token-map.json` records each ops property's disposition; `app.css` is a hand-maintained projection that `ui-tokens.test.mjs` checks both ways, plus built CSS equality and a hex allowlist. That is single-source in authority with a checked projection, and it is exactly the "derive-or-parity check"; no generator and no further test is needed. Do not delete the parity half when the ledger trigger text (wrongly) says it is deletable; it is the guarantee. The docs stylesheet (`dev/docs/scrypath-exdoc.css`) already derives from the pinned one with a build contract (Phase 188). The website (Phase 189) is the next consumer: give it the same shape (a parity row against `brand/tokens.json`, or import the pinned `tokens.css`) rather than a new copy. Add one sentence to `scrypath_ops/assets/css/DESIGN-TOKENS.md` naming `brand/tokens.json` as the authority.
Confidence high. What would change it: a theme property that cannot be expressed as adopt or derive (add a `keep-platform` row, still inside the map); or a decision to generate `app.css` from tokens (not recommended now: more tooling than the parity check).
Adversarial: "Hand-maintained CSS is a second source by definition." It is a second copy with a hard failure on drift; generation would add a build step and a dependency for no extra guarantee at 42 rows.

## Item 4: retained preview

Do nothing now. The preview checkout is at the pre-squash 3bc565c3; the cleanup, static gates and demo favicon do not need it, and 189/190 are website and wording work outside the ops preview. Refresh once, immediately before the first phase that needs visible UI evidence (the pilot in 193 per ROLLING-ROADMAP, or earlier only if a UI-visible change is planned). Least disruptive sequence, from AGENTS.md and UI-WORKTREE-LEARNINGS: run `npm run ui:preflight` from the preview checkout's demo directory (read-only); because the history was squashed, move `ui/next` to current `origin/main` after checking the worktree is clean and that its tree matches (a commit-id difference alone proves nothing); recreate the web service with the seed-disabled `compose.preview.yaml`; preflight again; update `UI-PREVIEW.json` (`implementation_head`, `base_main`, status). Cost: minutes; risk: wiping preview data if the seed-disabled override is skipped.
A cheap, optional improvement: add a one-line "stale since squash, refresh before visible UI work" note now to the UI-PREVIEW.json status so the file is not misread; the preflight itself already rejects a stale preview, so there is no correctness risk in waiting. Confidence high; changes if a v1.47 phase needs rendered captures earlier.

## Item 5: unthemed `favicon.svg`

Send upstream: the book's own text (BRAND.md line 225) promises a file that follows the device theme, and the shipped file has class names and no style. Suggested wording for an issue in `szTheory/scrypath-brand`: "assets/icon/favicon.svg references classes g and l but contains no style block, so it renders black in every theme; add the `<style>` with a `prefers-color-scheme: dark` rule (Orchid slash, Pale Ink letters) or ship it with explicit fills; add a test that renders it in both schemes." Once fixed upstream, refresh the pin with `mix brand.update`, then delete the workaround comments and decide whether ops/HexDocs should serve the themed file (note: whether a browser tab follows OS scheme or browser chrome scheme is a browser detail I did not verify; the book itself says only Chrome was looked at).
Guard (cheap, in the existing offline-brand-pin test file, no new gate):
- Tripwire: assert the pinned `favicon.svg` still lacks `<style` and `fill`. When an upstream fix lands and the pin is refreshed this test fails and its message says "remove the favicon-light workarounds in mix.exs, reskin_static_contract_test and the demo; then flip this assertion". It turns the workaround into a tracked debt with an exit.
- Consumer scan: one test that walks tracked non-`brand/`, non-`.planning/` files and fails on the string `icon/favicon.svg` (the light, dark and mono variants and `favicon.ico` stay allowed). It protects Phase 189 and any future consumer.
Lenses: security none; product, a black tab icon on a brand-new identity is the most visible defect a re-skin can leave; architecture, the pin is read-only so the workaround must live in consumers with one named source; a11y, a light-only favicon is low contrast on dark browser tabs (an upstream themed file is the real fix; a `media`-attributed link pair is an option I did not verify across browsers); OSS, an issue upstream costs minutes; test design, tripwire plus exclusion scan is cheaper than a render test.
Adversarial: "Just fix the file locally." The pin guard forbids edits to pinned assets (flipped-byte tamper probe), and a local fix would be overwritten by the next `brand.update`. "The guard is over-engineering for one file." The same file already bit two consumers in one milestone.

## Item 6: unclosed claims

See the table in the facts section. Recommended handling (cheapest first; all automatable, none needs a person):
1. Pin the two unpinned copy/default values (warning 9) and add the Cancel-initially-focused assertion (warning 4): one Playwright assertion in a dialog spec on the nightly/dispatch lane, one ExUnit assertion for the copy; place in the phase that next touches the sync modals (194, retry half) or as a small plan in the cleanup phase.
2. Command palette input suppresses its focus outline (IN-07, pre-existing): an accessibility defect, not a polish item. Fix with the Sync-and-index screen work in v1.48 or earlier if a cheap static check can find `outline: none` on inputs without a replacement ring.
3. IN-01 (Pending versus Retrying) and IN-02 (`Clear` beside a retained observation) are product wording and state questions; hand to the v1.48 screens work and to COPY-01 (Phase 190) respectively.
4. README header on hex.pm: add a guard test that fails if the README header URLs are not commit-pinned `raw.githubusercontent.com` before a release, and make the switch part of the next release PR (`docs/releasing.md` already says so). It is not blocking until the next Hex release.
5. Leave the remaining Info items, the HexDocs token colours and the after-capture SHA as recorded debt; re-opening them has no concrete adopter or bug evidence (AGENTS.md: no speculative reopening).
6. Standing exceptions: rendered quality, real screen readers and other hosts stay in the "what this does not prove" statement; no human UAT is requested.

## Suggested phase placement

- First v1.47 phase ("v1.46 carry-out", two small plans, test and asset only, no visible UI beyond the demo favicon): plan 1 = item 2 commits 1-3 plus item 3 documentation and the ledger wording; plan 2 = item 1 static invariants, item 5 tripwire and consumer scan, item 6 pins that need no browser. Run before 189 so the website phase inherits the favicon guard and the single-source rule.
- Item 6 browser assertion (Cancel focus): with Phase 194 (modals touched) or the cleanup phase's nightly additions.
- Item 4: a preflight step at the start of the first phase that captures rendered UI (expected 193), not before.
- README header guard and URL switch: the next release PR.
- 11-20 nightly check: first action of v1.47, zero cost.

## Overall uncertainty
I did not run Docker, the preflight, `mix verify.*` or the full suites. Run times are hosted-runner measurements from three PR runs and eight nightlies; noise on `ecommerce-mounted` is large (806-1062 s on PRs, 254-287 s warm nightlies). The scratch floor check shows the static invariants pass today; it is not the proposed implementation.
