# Decision C: release and delivery plan after v1.46

Prepared 2026-11-19 from read-only queries (`gh`, `curl` GETs, repo files). Nothing was posted, merged, closed or changed. Verified facts are labelled V; judgment is labelled J.

## 1. Verified facts

**Release state**
- V: `.release-please-manifest.json` and `mix.exs` say 0.3.18. Hex lists 0.3.18 (2026-11-19) as the latest. Release Please config: `release-type: elixir`, one package at `.`, `bump-minor-pre-major` and `bump-patch-for-minor-pre-major` both true, so a `feat:` still produces a patch.
- V: Four commits are on main after tag `scrypath-v0.3.18` (compare API): `chore(brand)` #137, `feat(ops-ui)` #138, `docs` #139, `fix(ops-ui)` #143. None touches `lib/`. The only shipped files that changed are `README.md`, `mix.exs` (docs logo, favicon and CSS), `CONTRIBUTING.md` and `docs/releasing.md`. Everything else is `.planning`, `scrypath_ops`, `brand`, `examples`, `scripts`, `test`, `dev`, which are outside `package.files`.
- V: `scrypath_ops` is not published. `docs/releasing.md` says it is never in the tarball, and `scrypath_ops/mix.exs` is version 0.1.0 with no package config.
- V: Release Please would see a `feat` and a `fix` and compute 0.3.19. Its auto-written notes would list "feat(ops-ui): re-skin ScrypathOps", which means nothing to a Hex adopter. That is misleading.
- V: HexDocs for 0.3.19 would carry the new logo, favicon and CSS, and the hex.pm README would change. Runtime and API behavior would not change at all.

**hex.pm README header (issue 1)**
- V: hex.pm renders the README in an iframe from `readme.hex.pm/<pkg>/<ver>`. That page's CSP is `img-src https://img.hex.pm`. Every image is rewritten to `img.hex.pm/fetch/<hmac>/<hex of the URL>`, a hex.pm-owned proxy.
- V: A relative path becomes `repo.hex.pm/preview/<pkg>/<ver>/<path>`, which serves only files inside the tarball. Phoenix's `priv/static/phoenix.png` works this way (HTTP 200 `image/png`). For scrypath 0.3.18 the README header (an older `brandbook/assets/logo-primary.svg`) returns 404.
- V: Absolute URLs also go through the proxy. Oban uses `raw.githubusercontent.com/oban-bg/oban/main/assets/...png` and it renders. A real SVG (the livebook README, `fly.io/.../logo.svg`) is proxied as `image/svg+xml` with HTTP 200.
- V: The sanitizer drops `<source>`. Oban's and our README `<picture>` blocks come out as a bare `<img>`. hex.pm therefore always shows the `<img src>` fallback, which is the light header. The dark SVG only matters on GitHub.
- V: `raw.githubusercontent.com/szTheory/scrypath/<sha>/brand/assets/readme/scrypath-header-{light,dark}.svg` returns 200 `image/svg+xml`. At commit `8beb3ed0f6f0b59f62df28ac60349c6dc9adf1a1` (#137, the latest commit that touched `brand/assets/readme`, per the commits API) both files are byte-identical to the current working tree.
- V: Comparable libraries. Oban uses absolute raw GitHub URLs on `main` (mutable, not in the package). Ecto uses absolute `github.com/.../raw/master/...` URLs. Phoenix ships the logo in the package (`priv/static`). Req has no header image. Nobody commit-pins. Our SHA pin is stricter than the ecosystem norm.
- V: The two SVGs total 11,601 bytes (5,829 dark and 5,772 light). `brand/` is 380 KB in total.
- V: PIN-03 (archived v1.46 requirement) reads: only adopted assets are committed, and `brand/` and `brandbook/` stay out of the Hex package `files`. Shipping the SVGs would touch these places:
  - the PIN-03 text;
  - `package_metadata_test.exs:56` ("package file allowlist only targets root library surfaces");
  - the `verify.package` top-level-entry allowlist;
  - the "README header and HexDocs brand assets" section of `docs/releasing.md`;
  - the `put_if_file` comment in `mix.exs`.
- V: Existing guard tests (`package_metadata_test.exs` lines 255 to 293) assert that README image refs start with `brand/assets/readme/` and are committed files. Moving to absolute URLs means rewriting those, plus the "readme.html carries the brand header paths" build test.
- V: The `core` job checks out with `fetch-depth: 0`, so a test can ask git about a pinned SHA.

**Release Please permission (issue 2)**
- V: The failure is `release-please failed: GitHub Actions is not permitted to create or approve pull requests`, on runs at 02:45, 03:00 and 03:25 on 2026-11-20. Each followed a push with a user-facing commit.
- V: `gh api repos/szTheory/scrypath/actions/permissions/workflow` returns `default_workflow_permissions: read, can_approve_pull_request_reviews: false`. The repo is a personal one (owner type User), so there is no org-level setting. Squash only, linear history, strict required checks, `enforce_admins: false`, no required reviews.
- V: The bot did open PR #125 (0.3.18) on 2026-11-18 at 22:43, so the setting was on then. The 2026-11-19 05:57 run succeeded only because it found "No user facing commits".
- J (hypothesis, not verified): the Step 0b hardening ("set the repo default workflow permission to read", in `V1.46-PREP.md`) probably reset `can_approve_pull_request_reviews` to false. The workflow file itself is correct: it has `pull-requests: write` and passes `secrets.GITHUB_TOKEN`.
- V: `docs/releasing.md` ("Minimum Secret Setup") says only that the built-in `GITHUB_TOKEN` is used. It does not name this repo setting as a prerequisite. `ROLLING-ROADMAP.md` records "Release-please app token (deferred; keep the close+reopen nudge)", and a PR created by `GITHUB_TOKEN` gets no CI until closed and reopened.
- V: No workflow has `on: push: tags`. The publish job is inside `release-please.yml`, and `publish-hex.yml` is a manual dispatch.

**Dependabot (issue 3)**: eight open PRs (#128 to #132, #140 to #142). #133 to #135 are closed, #136 is a merged docs PR.

| PR | Change | Required checks | Finding |
|---|---|---|---|
| 128 | website playwright 1.60.0 to 1.65.1 (npm, website dir only) | green (stale base, BEHIND) | only advisory `deep-quality` red |
| 129 | `@axe-core/playwright` 4.11.3 to 4.14.0 | `ecommerce-mounted` red: "retry-accepted-dark-desktop: non-contrast axe violations" | run was on the pre-re-skin base |
| 130 | pixelmatch 5.3.0 to 8.0.0 (major) | green | pixelmatch 8 is `type: module` (ESM only). `scripts/ci/ui_preservation.cjs:1127` does `require(.../pixelmatch)` and then calls it as a function. Under Node 22 `require(esm)` gives a namespace object, so the call would fail. No required check exercises that path (J: about 85% sure) |
| 131 | root mix: credo 1.7.19, dialyxir 1.4.9, nimble_options 1.2.0 | green | `mix.exs` constraints are `~> 1.1`, `~> 1.7`, `~> 1.4`, so lockfile only. nimble_options is a runtime dep of the library, so this is useful early signal that 1.2.0 works |
| 132 | `actions/upload-artifact` 7.0.1 to 7.0.2 in `ci.yml` and `website.yml` | `core` and `repository-contracts` red | `workflow_wiring_test.exs:1165/1212` compares the exact old SHA literal. Every Dependabot action bump will fail this way |
| 140 | phoenix_meilisearch example: bandit 1.15.0, dns_cluster 0.3.1, nimble_options 1.2.0, phoenix 1.8.16, telemetry_metrics 1.2.0 | green on current base, one commit behind main | example only; `dns_cluster` is a 0.x minor |
| 141 | scrypath_ops: 11 updates including phoenix_live_view 1.1.33 to 1.2.13, live_dashboard 0.9.1, sigra 1.7.1 to 1.20.0 | `ecommerce-mounted` red | "every version of scrypath_ops depends on phoenix_live_view ~> 1.2.13 and your app depends on ~> 1.1.33": `examples/scrypath_ecommerce/mix.exs` pins `~> 1.1.33` and uses `scrypath_ops` as a path dep |
| 142 | ecommerce example: 9 updates including tailwind 0.4.1 to 0.5.2 (0.x minor) and live_dashboard 0.9.1 | green on current base, one commit behind main | tailwind 0.5 could change CSS output; checks prove boot, routes and e2e, not pixels |

- V: Branch protection is `strict: true`, so every merge makes the others BEHIND and each needs an update plus about 15 minutes of CI (`ecommerce-mounted` runs 14 to 15 minutes).
- V: `deep-quality (advisory)` is red on every PR. The known cause is `scrypath_ops` auditing `cloak` and `cloak_ecto` through optional `sigra`. sigra 1.20.0 still requires `cloak_ecto ~> 1.3` non-optionally.
- V: `.github/dependabot.yml` groups only minor and patch, so major bumps (pixelmatch) arrive as separate PRs forever. It already ignores playwright in the ecommerce dir because it is pinned in lockstep with `Dockerfile.e2e`. The website's playwright has no such lockstep.

## 2. Recommendation per question

### Q1. Hex release soon? Recommended: yes, one small 0.3.19, after the README fix lands. Confidence: medium.

Why:
- It is the only way to fix the broken header on hex.pm. A published README is immutable, and hex.pm is the front door.
- It publishes the branded HexDocs, since HexDocs are versioned and 0.3.18's are the old brand.
- It costs one maintainer yes, because the pipeline is automated.

Honest framing: this is a presentation patch. Adopters get no behavior change and no `lib/` diff.

Notes:
- Expected version 0.3.19 (patch). No upgrade notes are needed beyond one line.
- Release Please's auto notes name the ops re-skin as a feature. When the release PR appears, hand-edit its CHANGELOG entry (there is precedent: 0.3.18 carries a hand-written "Upgrade notes" block) to say: "No library behavior change. README header now loads on hex.pm; HexDocs carry the new brand; ScrypathOps (repository-only, not in the package) was re-skinned."
- Use a `fix(docs):` squash title for the README fix PR so it appears under Bug Fixes.
- Do not hold v1.47 for it.

What would change my mind: if the maintainer prefers not to cut a no-behavior release, wait for the next library change (v1.49 features). Then the hex.pm header stays broken for months. A docs-only republish (`mix hex.publish docs`) can refresh HexDocs without a new version, but it bypasses the tag, parity and verify chain, and it cannot fix the hex.pm README. Not recommended.

### Q2. README header on hex.pm. Recommended: commit-pinned absolute raw URLs on the `<img>` and `<source>` tags, pinned to an already-merged commit. Confidence: high.

- **No chicken-and-egg.** Pin to a commit that already exists on main and already contains the two SVGs, not to the commit of the PR making the change. Use `8beb3ed0f6f0b59f62df28ac60349c6dc9adf1a1` (#137). It is verified byte-identical to the current files. A squash merge changes the README PR's own SHA but not this older one, and squash-merged main commits are permanent.
- **Why not the alternatives:**
  - Plain-text header on hex.pm: the guard-free "do nothing" option, but it throws away the brand on the page where adopters land first.
  - Shipping the two SVGs (about 11.6 KB, or 5.8 KB if only the light one):
    - Gain: immutable, offline-safe, no external host, and the guard could be a generic "every relative README image is inside the unpacked tarball". It follows Phoenix.
    - Cost: it re-opens PIN-03 and edits the five places listed in section 1.
    - Gap: only PNG through `repo.hex.pm/preview` was verified. I found no existing package that proves SVG through that path. The raw-URL route is verified end to end. That is the deciding point.
  - A mutable `main` or `master` URL (the Oban and Ecto pattern): the image can change after release and the file is not part of the audited tag. Repo rule: no mutable references in a published artifact.
- **Guard (the simplest that is robust):**
  1. Always-on, in `package_metadata_test.exs` (runs in `core`, which has full history). Rewrite the two README tests so the header `src` and `srcset` must match `^https://raw.githubusercontent.com/szTheory/scrypath/[0-9a-f]{40}/brand/assets/readme/scrypath-header-(light|dark)\.svg$`. The SHA must be an ancestor of HEAD (`git merge-base --is-ancestor`). The path must exist at that SHA. Keep the "no README image points at the Pages site" check.
  2. Release-time equality (run on release PRs via a head-ref condition, and in the publish job before `hex.publish`): the blob at the pinned SHA must equal the working-tree file. It cannot be always-on, because a brand-asset update PR changes the SVG before its own SHA exists. The failure is the right nudge: "re-pin the README header, then release".
  3. Post-publish, extend `mix verify.release_publish`: fetch `readme.hex.pm/scrypath/X.Y.Z`, take every `img.hex.pm/fetch/...` URL, and require 200 with an image content type. It checks the live result (the 0.3.18 failure would have been caught).
- Also update the ExDoc mirror assumptions: `readme.html` will load the header from GitHub, and the `assets:` mirror is still needed for the pinned snippet and the logo files. Update the `docs/releasing.md` text (the 0.3.18 note and "before the next release" become a standing rule with the pin procedure).

### Q3. Release Please permission. Recommended: turn on "Allow GitHub Actions to create and approve pull requests" now; consider a GitHub App token later. Confidence: high for step 1, medium for step 2. The setting is the maintainer's.

- **Step 1 (now):** Settings, Actions, General, Workflow permissions, tick the box. Keep default workflow permission on read. No workflow file change is needed: the workflow already requests `pull-requests: write`. Why this is safe here: there are no required approving reviews (`required_pull_request_reviews: null`), so a bot approval grants no extra authority. All actions are SHA-pinned (`check_action_pins.sh`). Workflow permissions are explicit. Then run `gh workflow run release-please.yml` or push to main.
- **Step 2 (optional, when the nudge starts to hurt):** a GitHub App installation token (`actions/create-github-app-token`, a first-party action pinned by SHA, contents and pull-requests write only on this repo). Benefits: no repo toggle, and the release PR triggers CI by itself, so the close and reopen nudge disappears. Cost: one app, two secrets, one more action to pin.
- **Avoid a PAT.** `enforce_admins` is false, so the owner's PAT could push to main past branch protection. It is long-lived and tied to a person.
- **Doc fix:** add the setting as a prerequisite in the "Minimum Secret Setup" section of `docs/releasing.md`. Its absence is why Step 0b could silently break the release path.
- J: the Step 0b reset is a hypothesis. Confirm by recording the setting's value after the flip.

### Q4. Dependabot triage

- **Merge on green under the standing rule** (update branch first, then wait for the required checks, one at a time, about 15 minutes each): #131 (lockfile only, gives nimble_options 1.2.0 signal), #128 (website playwright, no lockstep), #140 (example), #142 (ecommerce example; required `ecommerce-mounted` already passed on the current base; the tailwind 0.5 CSS risk is not covered by a pixel check, so this is the one where I would look at the rendered diff first if time allows, but the rule allows merging on green). Order: #131, #128, #140, #142.
- **Needs a code change, then merge:** #132. Hand-bump the upload-artifact SHA in both workflows and relax the `workflow_wiring_test` pin to a pattern such as `actions/upload-artifact@<40hex> # v7`. Otherwise every Dependabot action bump repeats this failure.
- **Needs a decision:**
  - #129 (axe-core/playwright 4.14.0): the red run is on the pre-re-skin base. Update the branch and re-run. If it passes, merge. If it still reports non-contrast violations, that is a real finding to put in v1.47's accessibility backlog; the PR then waits.
  - #141: cannot resolve alone. Close with the reason "phoenix_live_view ~> 1.2.13 conflicts with the ecommerce example's ~> 1.1.33 path-dep constraint; LiveView 1.2 and sigra 1.20 need one lockstep PR, sequenced with phoenix_storybook in v1.47". Dependabot will regroup it. Consider a `phoenix_live_view` minor ignore for the ops and ecommerce directories until that PR lands.
- **Close with a reason:** #130 (pixelmatch 8 is ESM only; `ui_preservation.cjs` uses `require` and would break at runtime). Add a Dependabot `ignore` for pixelmatch `version-update:semver-major`, or replace `require` with a dynamic `import()` in a deliberate hand PR if a newer comparator is ever wanted. Preferred now: close and ignore, because the pinned 5.3.0 works and a new dependency tree is not worth it.
- J: expect about one hour of serial CI for four merges, because of the strict up-to-date rule.

### Q5. Order relative to v1.47

1. **Now, no maintainer needed:** Dependabot triage (Q4). It must precede v1.47 because v1.47 edits `scrypath_ops/mix.exs` and `mix.lock` (phoenix_storybook), and open Dependabot PRs on those files would conflict.
2. **In parallel, no maintainer needed:** the README header PR (`fix(docs): ...`, with the guard and the releasing.md rewrite). Squash-merge on green.
3. **Maintainer:** tick the repo setting, then dispatch Release Please. It opens a release PR for 0.3.19.
4. **Maintainer:** review the PR, edit the changelog text, say yes. The release is not on v1.47's critical path.
5. **v1.47 starts after steps 1 and 2** (about a day). It does not wait for the maintainer's yes on step 4.

## 3. Lens scorecard (strongest point from each)

- **Security:** an immutable pinned URL keeps the published README from changing after release. A PAT would let the owner's token bypass branch protection (`enforce_admins: false`); an App token is scoped.
- **Product/adopter:** the first impression on hex.pm is currently a broken image. Adopters get no behavior change, so keep the notes honest.
- **Architecture:** the tarball is the audited artifact, so a README that depends on files outside it needs a pin and a guard. Keep the pin as one constant-shaped URL, not scattered.
- **DevOps/CI:** `strict: true` serializes merges; the hard-coded action SHA in `workflow_wiring_test` turns every Dependabot action bump red; the Release Please prerequisite is undocumented.
- **OSS maintainer:** do not leave a failing "Release Please" check on every main push, and do not invent a release when the train is idle. Here the release has one concrete reason (the broken hex.pm header).

## 4. Adversarial pass

- "A release with no `lib/` change is noise." True for behavior. The reasons it still helps are the immutable README and branded HexDocs. If the maintainer disagrees, doing the README fix alone on main costs nothing, and the release can wait for v1.49. The cost is a longer broken header.
- "Raw GitHub URLs add an external dependency." Yes, but hex.pm's own proxy already fetches Oban's and Ecto's images from GitHub, and ours is stricter (a SHA). Risk: if the repo is renamed or deleted, the image breaks silently. GitHub redirects renamed repos, and the post-publish check plus the release-time check cover the rest. If this worries the maintainer, shipping the two SVGs is the fallback, once SVG through `repo.hex.pm/preview` has been verified on a throwaway version.
- "The release-time equality check fails after the tag exists." That is why it also runs on the release PR (head ref `release-please--*`) before merge.
- "`feat(ops-ui)` bumps the version of a package ScrypathOps is not in." Pre-1.0 patch bump only; harmless but misleading, handled by editing notes.
- "Ticking the setting also allows approval by bots." Without required reviews this grants nothing. If required reviews are ever added, revisit and prefer the App token.
- "Merging four Dependabot PRs one by one is slow." Yes. A merge queue would help but is a new process; not worth adding for four PRs.
- "pixelmatch 8 might work." The failing call pattern is an inference from `type: module` and the source. It is cheap to test locally with `node -e` against the PR's lockfile before closing; if it works, move #130 to merge-on-green after updating.

## 5. What changes the recommendation

- A concrete library bug or adopter report arrives: bundle it into the same release (the README fix still ships).
- SVG through `repo.hex.pm/preview` is verified: ship-the-SVGs becomes a competitive option (simpler guard, no external host), at the cost of rewriting PIN-03.
- The maintainer wants the release PR to run CI without the nudge: go straight to the App token.

## 6. Steps that need the maintainer

- Tick the repo setting (Q3 step 1).
- Say yes to the 0.3.19 release and review the hand-edited changelog entry.
- Decide on the optional App token.
- Everything else (README PR, guard, Dependabot merges, the upload-artifact hand-bump, closes with reasons) falls under the standing squash-merge rule. Closing Dependabot PRs with a comment is an action on the maintainer's behalf, so batch it into one yes with the Q4 table.
