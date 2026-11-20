# Next milestone context: v1.47 Brand completion

**Captured:** 2026-11-20
**Status:** Prepared upstream under the standing milestone-preparation rule. Input for `/gsd-new-milestone v1.47`; it does not activate a milestone or approve a phase. The workflow consumes and deletes this file.

## Read first

- `reference/ROLLING-ROADMAP.md`, section "Post-v1.46 proposal (2026-11-19)": the recommended milestone, phase table, confidences and what would change them.
- `research/v1.47-prep/` notes A (scope and shape), B (website), C (release and delivery, already executed), D (verification and cleanup). Each has verified facts, lenses and an adversarial pass.
- `milestones/v1.46-MILESTONE-AUDIT.md` (debt carried in) and `reference/CI-EFFICIENCY.md` (ledger of measured CI findings).
- `reference/BRAND-ADOPTION-PLAYBOOK.md`, `AGENTS.md` (house rules and standing instructions).

## Goal

Finish the brand adoption v1.46 started: the website in the new identity, the wording fixes that do not need the catalog, and removal of the old identity's last code. Then v1.48 (Catalog foundation, phoenix_storybook) starts from a clean base.

## Recommended scope (accept or adjust; all decisions below were delegated and already researched)

0. **Kickoff chore, before the phases (CI change, small PR):** an `ecommerce-path` classifier so planning-only and docs-only PRs skip `ecommerce-mounted` and the browser Node step (same pattern as `ops-ui-path`, a skipped required job still reports green). Ledger finding 2; about 19 minutes and 35 runner-minutes saved per docs-only PR. Must not skip when `brand/`, `scrypath_ops/`, `examples/`, `scripts/ci/`, `lib/`, `mix.exs` or workflow files change; `workflow_wiring_test` must still pass. Also finding 1 (split the always-red `deep-quality` lane) if cheap.
1. **Phase 189 Website re-skin (SITE-01), 2-3 plans.** `build.mjs` derives theme variables from pinned `brand/tokens.json`, copies pinned fonts (Bricolage included, serve the OFL texts), lockups, light and dark favicons and the social card; light default with Light/Dark/System picker; extend the deny-set with the website's old palette in the same commit as the asset swap, remove the two `p189` allowlist entries; rewrite `website/check.mjs` (today capture-only) to computed-style, font-hash and contrast assertions; add `brand/**` to the website path filter; dependency-free static contract in `core` and `repository-contracts`. `build-and-check` is not a required check and deploy is on merge to `main`: wait for it green on the exact head before merging; decide in the plan whether it becomes gate 9 of 12. Use `favicon-light.svg` and `favicon-dark.svg`, never the unthemed `favicon.svg`.
2. **Phase 190 Wording (COPY-01 and the "Control room" casing), 1-2 plans.** Glossary-rule copy fixes; guards as a data table inside the required `ops-ui` job so the v1.48 copy lint can ingest them; also the Cancel-focus assertion and two unpinned copy values.
3. **Phase 191 Cleanup, 1-2 plans.** In order: demo favicon becomes a copy of `favicon-light.svg`; delete the `brandbook/` readers (`ui_tokens.ex`, its contract test, the `verify.phase99` entry, the mix alias); then `brandbook/`, the `ci.yml` path-regex entry and the allowlist entries (ceilings 7/201 to 2/4). Add static invariants to the existing token test (12 px floor, no arbitrary text sizes, no `uppercase`, no `infinite`; no new gate). Tripwire test that the pinned `icon/favicon.svg` is still unthemed plus a scan for any non-`brand/` use of it. Reword the CONTRIBUTING ledger triggers (the deny-list deletion trigger fires here: keep the deny-list, rewrite the trigger). Name `brand/tokens.json` as the token authority.

Numbering keeps 189 and 190 (allowlist tags use `p189`). v1.48 Catalog foundation then takes 192-196; the old v1.48 and v1.49 become v1.49 and v1.50.

## Already done (do not redo)

- v1.46 archived and tagged `v1.46`; v1.46 PRs #137, #138, #139, #143; audit fixes #143, #145.
- Hex 0.3.19 released 2026-11-20 (README header now commit-pinned and verified loading on hex.pm).
- Release Please repo setting fixed; Dependabot triaged (merged #128, #131, #140, #142; closed #130 with an ignore, #141 until the storybook spike). Open: #132 (hand-fix a hardcoded SHA in `workflow_wiring_test`) and #129 (re-run; its axe run was on a pre-re-skin base).
- Two dialyzer errors from the brand tooling fixed (#147).

## Constraints and defaults

- Gate budget: 8 of 12 new required gates used; each new one needs a deletion trigger and expected churn. GATE-02 guardrails stay standing (second consecutive evidence-only plan forces a stop-and-decide; one full gate run per commit SHA; no capture from a dirty tree).
- No human UAT: every success criterion is an executable check. Nothing claims aesthetic or independent-review approval.
- Squash-merge green PRs without asking (standing instruction); Hex releases need the maintainer's explicit yes. Evaluate every CI run for speed and cost wins (AGENTS.md "CI and CD efficiency").
- Local toolchain: `export ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.5`. Never stage `.planning/config.json` or `.planning/state.json` (the maintainer's unrelated local edits).
- The retained UI preview (`.planning/UI-PREVIEW.json`) is stale; refresh only before the first phase that needs rendered evidence (190 if it captures screens).

## Open items that still need the maintainer

None blocking. Optional: whether `website` `build-and-check` becomes a required check (gate 9), and the first nightly on re-skinned `main` (`ecommerce-e2e`, advisory, failed 7 of 8 earlier) should be read at kickoff.
