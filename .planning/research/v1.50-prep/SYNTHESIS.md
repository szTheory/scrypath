# v1.50 prep: synthesis (2026-11-25)

Inputs: notes [A choice and release](A-choice-and-release.md), [B correctness](B-correctness.md),
[C adopter-ready](C-adopter-ready.md), [D agent CLI](D-agent-cli.md). Each applied role lenses,
primary sources and its own adversarial pass. This note reconciles them. Nothing here is approved:
the maintainer chooses when v1.50 is opened.

## What was checked after the notes

| Claim | Status |
|---|---|
| The client sends the API key only as `x-meili-api-key`, so a server with a master key answers 401 | **Reproduced** on Meilisearch 1.15.2 with Scrypath's client; all 9 live tests fail keyed, pass after the fix. Fixed outside the milestone (PR #189) |
| With no `oban_inspector`, Oban mode reports the queue observed and empty without reading it (B's F5) | Confirmed by reading `oban/inspect.ex` and `operator/status.ex`; no guide mentions an inspector. Not run |
| The golden path's filtered, sorted search cannot work on a fresh install (A and B) | Confirmed by reading the guide and `meilisearch/settings.ex`: no settings step, `sortable:` never sent, filtered and sorted fields not projected. Not run |
| History past 1,000 tasks makes status and failed-work calls error (F1) | Read by B. Not run |

## Recommendation

**Keep v1.50 "Adopter-ready" (the adopted slot), and lead it with making the documented path work.**
Confidence 0.8.

| Step | Content | Plans | Proof | Needs the maintainer |
|---|---|---|---|---|
| Before the milestone | Bearer-token fix, then release 0.3.21 | done / 0 | keyed backend lane | **yes to the release** |
| 199 Documented path works | Reproduce first. Golden path and sibling guides, F4 (`sortable:` and set comparison), F5 (read the Oban queue, or say it was not observed), F1 (bounded, flagged as partial) | 2 to 3 | planted failure per defect; the guide's own search against a real keyed server | yes to root `lib/` changes |
| 200 Fresh-consumer walk | Blind agent, published package and HexDocs only, keyed production-mode server (protocol in C) | 1 | grader exit codes and an unedited findings record | no |
| 201 Testing guide | "Testing your app" with no new API, walk findings; **cut line**; release 0.3.22 | 2 | guide code fences compiled and run offline | yes to the release |
| Not built | Highlight/crop and a paging guard | 0 | document the `settings:` passthrough for pagination | only if asked for at a grilling session |

About 5 to 6 plans; stop and re-ask beyond 7. The recorded estimate was 3 to 5, and the difference is
the correctness work found by this prep.

**Order.** The fix to the documented path goes before the walk (B and C) instead of after it (A): the
defects are already established from code, and a walk is more useful on whatever they leave behind.

**Elsewhere.** F2, the D2 wording, the second `return_to` writer and the catalog origin check: small
`chore(ops-ui)` PRs. F3 (swap tasks invisible): later, it needs design; note B's hazard that a second
promotion may not be blocked and check it in 199. Dependency advisories: patched. `sigra`: stays.

## AI-agent CLI (SEED-005)

D recommends one read-only, versioned diagnosis report (Mix task plus a release-callable function) as
the **first slice, in the milestone after v1.50**. Confidence 0.7 on placement, 0.85 on read-only
first. It depends on 199: an agent would trust the same false "queue clear". Its other CLI truth
findings (retry by id ignores source, a diff task name that does not exist, reindex offered while one
is pending) belong in 199 if small.

Taking it means **moving it ahead of the adopted v1.51 catalog breadth**. That reorders a recorded
roadmap, so it is the maintainer's call. Recommended: yes, v1.51 becomes agent diagnosis and catalog
breadth moves to v1.52, because the maintainer ranked agent use very important after the order was
adopted, and nothing outside depends on catalog breadth.

## Release

0.3.21 now for the authentication fix: it is a bug that blocks every secured deployment, and bug fixes
are exempt from the proposed 14-day cadence. 0.4.0 with the first new public API (`~> 0.3` still
admits it, so the number alone protects nobody). The cadence rule is still unadopted.

## Adversarial pass on this synthesis

- "Three of the findings were never run." True. 199 starts by reproducing, and drops any that pass.
- "The milestone grew past its estimate." The cut line holds at the testing guide; F3 and all new API
  are already out.
- "One fix proves the others are urgent." No: the authentication bug raises the value of walking the
  production path, not the certainty of any other claim.
- "Zero known outside adopters." Still true. That argues for staying small, and against announcing
  before the first search works.

## What would change it

An outside report (it goes first). A reproduction that passes (drop that item). Refusal of root `lib/`
changes (199 becomes docs only, with known limits stated). Wanting agent diagnosis now (open it as
v1.50, but F5 and F1 still come first).

## Not verified

Everything marked "Not run" above; whether anyone outside uses the library; Meilisearch's true task
retention in practice; the fresh-consumer walk itself.
