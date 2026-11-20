---
phase: 187-scrypathops-re-skin
slug: scrypathops-re-skin
asvs_level: 1
block_on: high
verdict: SECURED
threats_total: 29
threats_closed: 28
threats_open: 0
threats_open_non_blocking: 1
accepted_risks: 0
unregistered_flags: 4
audited_code_commit: cf7441092d18cedb2fca26475906725fbeb67b94
branch: feat/v1.46-187-ops-reskin
audited: 2026-11-19
---

# Phase 187 Security Verification

Scope: the `<threat_model>` blocks of plans 187-01 to 187-11. Threat ids T-187-01 to T-187-28 are
distinct; T-187-SC (supply chain) repeats in every plan and is verified once, so the register
holds 29 threats. Every mitigation was checked against the code on the branch, not against the
SUMMARY text. Implementation files were not modified. All paths are relative to the repo root.

`threats_open` counts only OPEN threats at or above `block_on: high`. One medium threat has an
evidence gap and is tracked as non-blocking (T-187-03).

## Threat verification

Dispositions are all `mitigate`. No `accept` or `transfer` threats exist in this phase.

| Threat | Severity | Category | Disposition | Evidence (file:line) | Status |
|--------|----------|----------|-------------|----------------------|--------|
| T-187-01 | medium | Elevation of privilege (fixture route) | mitigate | Fixtures compile only under `elixirc_paths(:test)` (`scrypath_ops/mix.exs:42-43`, `examples/scrypath_ecommerce/mix.exs:36-37`). The demo router mounts them inside `if Mix.env() == :test` (`examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/router.ex:30-32`). `all-statuses` sits in the whitelist and unknown values fall back to `healthy` (`scrypath_ops/test/support/phase173_fixture_source.ex:130-151`). Test: `scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs:305`. | CLOSED |
| T-187-02 | low | Information disclosure (captures, preflight output) | mitigate | `.gitignore:24` ignores `examples/scrypath_ecommerce/ui-review-artifacts/`. `git ls-files` lists no capture image or manifest. Manifest keys are source sha, git status, stylesheet hashes, base URL, seed name, file hashes (`examples/scrypath_ecommerce/scripts/reskin-capture.mjs:385-403`). No secret fields. The `p187.env` file holds only ports and `BUILDX_CONFIG`. | CLOSED |
| T-187-03 | medium | DoS (shared Docker, retained preview data) | mitigate | Task-scoped project names with `down -v --rmi local`, no prune, and `docker system df` recorded (`187-01-SUMMARY.md:143-145`, `187-09-SUMMARY.md:249`, `187-10-SUMMARY.md:210-217`, `187-11-SUMMARY.md:164-171`). No `scrypath187`/`p187` container is left running. The preview worktree's `my-search.json` still exists. The declared before/after hash comparison of `my-search.json` has no recorded evidence: the preview refresh was blocked in 187-01 and deferred to the orchestrator in 187-11 (`187-11-SUMMARY.md:158`). No loss was observed. | OPEN (non-blocking, medium < high; evidence gap, no harm observed) |
| T-187-04 | medium | Tampering (font path and `?v=`) | mitigate | `AssetPlug` and the router are unchanged on this branch (not in `git diff origin/main...HEAD -- scrypath_ops/lib`). Traversal checks: `scrypath_ops/lib/scrypath_ops_web/plugs/asset_plug.ex:25-26` (rejects `..`, `.`, empty segments), `:31-34` and `:106-109` (`inside_static_dir?`). `?v=` is only compared to the file digest (`:59`, `:77-83`) and never used as a path. Tests: traversal returns 404 (`scrypath_ops/test/scrypath_ops_web/asset_plug_test.exs:59-76`); both fonts return 200 with `font/woff2` and an immutable header (`scrypath_ops/test/scrypath_ops_web/reskin_static_contract_test.exs:294-306`). | CLOSED |
| T-187-05 | medium | Tampering (served SVG and ICO) | mitigate | Byte-equality with the pinned `brand/` sources: `scrypath_ops/test/scrypath_ops_web/reskin_static_contract_test.exs:369-380`; ICO structure `:383-405`. I scanned the five served SVGs for `<script`, `onload` and `javascript:` and found none. The Phase 186 `verify.brand` active-content scan stays in place and was not edited. | CLOSED |
| T-187-06 | medium | DoS (fonts missing in Docker lanes) | mitigate | `examples/scrypath_ecommerce/Dockerfile:31-37` now deletes only `assets/css`, `assets/js`, the demo's generated assets and the two cache manifests. `git ls-files scrypath_ops/priv/static` shows `assets/fonts` holds only the three woff2 files and three OFL license texts, so nothing unintended ships. The release and test stages re-copy `priv/static` from the builder (`Dockerfile:73-74`, `:109-110`). Required-lane test: `examples/scrypath_ecommerce/e2e/harness.spec.ts:7-30` fails on a font 404. | CLOSED |
| T-187-07 | low | Information disclosure (host CSP weakened) | mitigate | Fonts are same-origin and referenced by relative URLs (`scrypath_ops/priv/static/assets/css/app.css:2955-2968`). No third-party host, no data URLs (`reskin_static_contract_test.exs:276-285`). README states `font-src 'self'` suffices (`scrypath_ops/README.md:106-111`). Browser proof: `examples/scrypath_ecommerce/e2e/ops_host_contract.spec.ts:231-307`. | CLOSED |
| T-187-08 | medium | Tampering (token map, ceilings, allowlist edited to hide a mismatch) | mitigate | Exact-both-ways ceilings (`examples/scrypath_ecommerce/ui-tokens.test.mjs:72`, `:378` stale-pending rule, `:612-625` planted failures). I ran the file: 59 pass, 0 fail. | CLOSED |
| T-187-09 | medium | Repudiation (contrast claims not tied to the stylesheet) | mitigate | `examples/scrypath_ecommerce/contrast-checker.mjs:339` (`--self-test`) with planted failures. `scrypath_ops/assets/css/contrast-pairs.mjs` resolves pairs from `app.css`. I ran the checker against the live stylesheet: 0 failures, thinnest text pair 4.58. | CLOSED |
| T-187-10 | low | Tampering (DTCG mirror drift) | mitigate | `test/mix/tasks/ui_tokens_contract_test.exs` and the `ui-tokens.test.mjs` parity tests. The regeneration script is not in the tree (`git ls-files` finds none). | CLOSED |
| T-187-11 | high | Information disclosure (retry flash) | mitigate | `scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex:336-370`: the `{:error, reason}` branch logs through `Logger.warning` (`:357-360`) and flashes the fixed sentence from `retry_failed_copy/1` (`:367-370`). The old `"Retry failed: #{inspect(reason)}"` is deleted in the diff. Test: `scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs:534-571` asserts the exact flash text, none of `%{`, `:timeout`, `{:error`, `meta`, and that the log still holds the reason. | CLOSED |
| T-187-12 | low | Tampering (`ops_sync_status` input) | mitigate | `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex:509` has `values: [:failed, :retrying, :pending, :clear]`, and words and shapes come from the private `sync_status_shape/1` table (`:513`, table at `:1964-1974`). Test: `scrypath_ops/test/scrypath_ops_web/reskin_component_contract_test.exs:117-123`. | CLOSED |
| T-187-13 | medium | Repudiation (Clear shown without an observation) | mitigate | `scrypath_ops/lib/scrypath_ops/posture.ex:205-223` (`row_status/1`, `queue_unused?/1`): `:clear` needs an observation or a queue-not-used mode. Test: `scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs:457-480`. | CLOSED |
| T-187-14 | medium | Tampering (destructive confirms) | mitigate | Saved-search delete keeps the typed-name form (`scrypath_ops/lib/scrypath_ops_web/live/search_live.ex:1899-1925`) and the server handler gates on the typed name and sudo (`:344-352`). No `handle_event` line changed in the branch diff. Sync modals default `initial_focus` to `[data-ops-modal-cancel]` (`ops_ui.ex:1563`; `failed_sync_live.ex:1214,1240`; `sync_drift_live.ex:2455,2478`). Tests: `sync_drift_live_test.exs:415-445`, `failed_sync_live_test.exs:833-880`, `search_saved_searches_test.exs:420-470` (wrong name rejected, sudo redirect) and `:555-575`. | CLOSED |
| T-187-15 | low | Tampering (scroll-padding rule affecting a host page) | mitigate | Rule is scoped with `html:has(.ops-shell)` (`scrypath_ops/assets/css/app.css:347,360`; built `priv/static/assets/css/app.css:3036,3047`). The unscoped-selector ratchet is at `ui-tokens.test.mjs:1679` (see T-187-25). | CLOSED |
| T-187-16 | low | Repudiation (a loader that hides an infinite animation) | mitigate | `reskin_static_contract_test.exs:703-710` scans the stylesheet and `lib/` for `infinite`, spinner and pulse classes. `examples/scrypath_ecommerce/e2e/admin_path_motion.spec.ts:8,146` (P-12) checks `getAnimations()` for infinite iteration. | CLOSED |
| T-187-17 | low | Tampering (non-control icons reintroduced) | mitigate | E-10 icon-name scan with a planted failure (`reskin_static_contract_test.exs:25,558`) and no-`hero-` assertions (`reskin_component_contract_test.exs:138,259`). | CLOSED |
| T-187-18 | medium | Tampering (retired values re-entering) | mitigate | Exact ceilings and N-08 hex allowlist (`ui-tokens.test.mjs:1166-1167`, `:1461-1500`). The deny-list tests pass (59/59). | CLOSED |
| T-187-19 | medium | Tampering (contrast mutation case turning vacuous) | mitigate | "changed focus background" re-pointed at `test/mix/tasks/ui_contrast_contract_test.exs:277`. The cases clone the tree through `git clone --shared` (`:346`) and require the real checker to fail on each mutation. | CLOSED |
| T-187-20 | medium | Tampering (alpha text or retired tints returning) | mitigate | N-07 and N-12 bans with planted failures (`ui-tokens.test.mjs:1166-1167`, `:1461-1500`). The clone cases are in `ui_contrast_contract_test.exs`. | CLOSED |
| T-187-21 | medium | Tampering (retired patterns re-entering ops code) | mitigate | E-12 scan over the stylesheet, `lib/` and JS with planted cases (`reskin_static_contract_test.exs:31,558`). Ledger ceilings: `ui-tokens.test.mjs:72`. | CLOSED |
| T-187-22 | medium | DoS (Docker stacks left running, other projects pruned) | mitigate | `docker ps` shows no `scrypath187`/`p187` container. `docker system df` before and after is recorded in 187-01, 09, 10 and 11 SUMMARY. SUMMARYs state no prune. Shared build cache is left alone. | CLOSED |
| T-187-23 | low | Repudiation (browser claims without a reproducible run) | mitigate | Every P-assertion lives in a committed spec: `ops_reskin_contract.spec.ts`, `ops_host_contract.spec.ts`, `admin_path_motion.spec.ts`. The 187-10 SUMMARY records the attempts and outcomes. | CLOSED |
| T-187-24 | medium | DoS (new specs pushing the partition past its cap) | mitigate | Partition measured at 352 s locally and 406 s in the canonical lane against a 900 s cap (`187-10-SUMMARY.md` Threat Flags). | CLOSED |
| T-187-25 | medium | Tampering (ops CSS leaking into host pages) | mitigate | N-11 shrink-only ratchets: `UNSCOPED_SELECTOR_CEILING = 54`, `DUAL_DARK_RULE_CEILING = 12` (`ui-tokens.test.mjs:1679-1680`, `:1797-1801`, planted growth at `:1829`). Browser checks P-17a to P-17d (`ops_host_contract.spec.ts:~100-307`). The WR-03 premise test pins `--color-primary` to top-level `@layer base` (`reskin_static_contract_test.exs`). | CLOSED |
| T-187-26 | low | DoS (host CSP blocking fonts) | mitigate | P-17d probes `font-src 'self'` and a planted `font-src 'none'` that must fail (`ops_host_contract.spec.ts:231-307`). README at `:106-111`. Metric-matched fallback faces at `app.css:2969-2985`. | CLOSED |
| T-187-27 | low | Information disclosure (capture images and review artifacts) | mitigate | Images and `p187.env` live under the ignored `ui-review-artifacts/` (`.gitignore:24`). Only names and hashes appear in `.planning/phases/187-scrypathops-re-skin/187-CAPTURE-INVENTORY.md`. A grep of that file and the manifests for secret-like words found nothing. | CLOSED |
| T-187-28 | high | Elevation of privilege (an agent merging or marking ready) | mitigate | No merge, ready or auto-merge command in any changed script (`git diff origin/main...HEAD -- . ':!.planning'` contains no `gh pr merge`, `gh pr ready` or `--auto`). The branch has no merge commits. No PR exists yet and Task 3 belongs to the orchestrator (`187-11-SUMMARY.md:104,159,186`). This control is procedural and must still hold when the Draft PR is opened. | CLOSED |
| T-187-SC | high | Tampering (supply chain, all plans) | mitigate | `git diff origin/main...HEAD` lists no change to `mix.lock`, `scrypath_ops/mix.lock`, `examples/scrypath_ecommerce/mix.lock`, any `mix.exs`, any `package.json` or `package-lock.json`, or any vendored script (topbar untouched). The only dependency-adjacent file changed is the Dockerfile, covered by T-187-06. The rebuilt ops bundle diff holds only the `showProgressBar` change and the two timer constants (`scrypath_ops/assets/js/app.js`, `ops_hooks.js`). | CLOSED |

## Focus areas

- Static font serving. The plug is unchanged. `?v=` only selects the cache header, and content comes
  from a path that survives the segment and prefix checks. The one new route use is the standalone
  preload (`scrypath_ops/lib/scrypath_ops_web/components/layouts/root.html.heex`), a same-origin GET
  with `crossorigin`.
- User data in HEEx. `lib/` contains no `raw`, `Phoenix.HTML.raw` or `{:safe` call, and the ops JS
  has no `innerHTML` or `insertAdjacentHTML`. Escaping is exercised by
  `failed_sync_live_test.exs:759-775` and `result_ui_test.exs:15`. Saved-search names render through
  `{row.name}` interpolation.
- Preservation-guard amendment (`examples/scrypath_ecommerce/e2e/helpers/ui-preservation-states.ts`).
  It normalizes only whole lines equal to `Refreshing…`, and only on the observed text. The prior
  text is compared as observed. `scripts/ci/ui_state_pairs.test.cjs` plants six near-miss words, a
  changed neighbour line, an added line and a substring, and pins the allowlist to exactly one
  entry. 39 of 39 pass.
- Capture script. It refuses a dirty tree (`reskin-capture.mjs:85-111`, `:284-285`) and a stylesheet
  that differs from HEAD (`:142-152`, `:291-294`), and refuses a populated `--out` (`:298-300`).
  `--check` re-derives provenance (`:180-198`). Its 25 self-tests pass.
- Loopback header proxy (`ops_host_contract.spec.ts:105-139`). It binds `127.0.0.1` on an ephemeral
  port (`:128`). Its only upstream is the configured Playwright base URL. It adds one response
  header on one document path and makes no other network call.

## Accepted risks log

None. No threat in this phase uses the `accept` or `transfer` disposition.

## Unregistered flags (informational, not blockers)

SUMMARY `## Threat Flags` sections all report "None new". Reading the code turned up four
observations that have no threat id:

1. Same class as T-187-11, outside the retry path and not introduced by this phase. Operator flashes
   and panels still print `inspect(reason)`: `scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex:192,645,664,1180,1248,1618,1622,2000,2171,2229,2421`,
   `scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex:799`, and
   `scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex:234`. All sit behind the host's auth
   and sudo gating, and none appears in the branch diff as an addition. Worth a follow-up item if the
   maintainer wants the retry-flash rule applied everywhere.
2. The capture script accepts any `--out` path (`reskin-capture.mjs:269`). It does not enforce the
   ignored `ui-review-artifacts/` directory. The risk is a manifest or screenshots written where git
   tracks them. It is convention plus `.gitignore`, and low.
3. The progress bar color now reads the computed `--color-primary`
   (`scrypath_ops/assets/js/app.js`). The value is only passed to topbar's canvas gradient and is
   host-controlled CSS. Benign.
4. The tests evaluate part of the preservation guard with `new Function`
   (`scripts/ci/ui_state_pairs.test.cjs`). It runs only repo-owned source between two marker
   comments. Benign.

## Verification runs (read-only)

- `node --test examples/scrypath_ecommerce/ui-tokens.test.mjs`: 59 pass, 0 fail.
- `node --test scripts/ci/ui_state_pairs.test.cjs`: 39 pass, 0 fail.
- `node --test examples/scrypath_ecommerce/scripts/reskin-capture.selftest.mjs`: 25 pass, 0 fail.
- `node examples/scrypath_ecommerce/contrast-checker.mjs`: 0 failures.
- I did not run ExUnit, Playwright or Docker. Their results are taken from the code and tests read
  above, and from the SUMMARY and REVIEW-FIX records, which I did not treat as proof on their own.

## Sign-off

Verdict: SECURED at ASVS level 1 with `block_on: high`. 28 of 29 threats are CLOSED with code and
test evidence. One medium threat (T-187-03) is OPEN and non-blocking: the `my-search.json` hash
check was never recorded, though nothing touched the preview data. It closes when the orchestrator
records the before and after hash during the retained-preview refresh.
