# v1.50 prep C: what Adopter-ready should contain

2026-11-25. Read-only; no mix, Docker or database; walk not performed. V = verified this session in code or a primary source, J = judgment, U = unverified.

## 1. Recommendation

**Put an API-key authentication fix first and release it, then the blind consumer walk, then the testing guide. Cut line there.** Highlight and paging code stay behind the grilling session; I recommend building neither by default. This adds to and narrows the adopted sketch (`.planning/reference/ROLLING-ROADMAP.md`), so the maintainer decides.

### The bug (V by reading both sides; not executed)

- `lib/scrypath/meilisearch/client.ex` sends the key only as `x-meili-api-key`. Same in 0.3.20.
- Meilisearch's auth extractor (v1.15.0 and v1.58.0) reads only `Authorization: Bearer`; the old header was replaced in v0.25. A code search of the engine repo for the old name finds nothing.
- So against any server with a master key (required in production mode) requests should get 401.
- Why it stayed green: no CI service or compose file sets `MEILI_MASTER_KEY`, and `test/scrypath/meilisearch/client_test.exs` asserts the old header.
- `guides/meilisearch-operations.md` tells adopters to set a master key; no guide mentions `meilisearch_api_key`.
- Probable workaround (U): `req_options: [auth: {:bearer, key}]` with no `meilisearch_api_key`.
- It fails closed, so no disclosure. The risk is someone dropping the key to make it work.

This is a concrete production bug (the first reopen trigger). It should not wait for milestone ceremony.

## 2. Phases

| Phase | Scope | Executable proof | Size |
|---|---|---|---|
| 199 Auth fix, release 0.3.21 | Send `Authorization: Bearer`. A configured key overrides caller `headers`/`auth`; with no key, caller auth survives. Fix the copies in `scrypath_ops/lib/scrypath_ops/document_observation.ex` and the two ecommerce e2e files. Document the key; release note. Carries the unreleased docs fix (live HexDocs still claims highlight/crop exist). | RED first: key the `backend` lane Meilisearch; live sync, search and task wait fail on current code, pass after; wrong key and no key return errors. `Req.Test` header and precedence tests. Local keyed run before push. After publish, same smoke from the Hex package. | 1-2 plans; maintainer yes to release |
| 200 Blind walk on 0.3.21 | Section 4 | Grader script exit codes plus recorded findings | 1 plan |
| 201 "Testing your app", walk fixes, release 0.3.22 | `guides/testing-your-app.md`, no new API. Fix repo-only `FakeBackend` mention in the faceted guide. Paging paragraph. Docs fixes the walk ranks. Rerun failed walk tasks on the published release. | A root test extracts the guide's code fences, compiles them and runs inline upsert, delete, search with hydration and `perform_job` for upsert and delete with no network; planted failure (drop the task route) goes red. Contract test pins worker names and arg keys. ExDoc group guard, `docs --warnings-as-errors`. | 2-3 plans; release yes |
| **Cut line** | | | |
| 202, optional | Highlight/crop passthrough, only on the maintainer's yes at grilling | section 5 | 2 plans |

Stop after 201 unless the maintainer asks for more. A library defect found by the walk joins 201 only if small; otherwise it is reported for a decision.

## 3. Does current code support a short testing recipe? Yes (V by reading; U until run)

```elixir
# config/test.exs
config :scrypath, :defaults,
  req_options: [plug: {Req.Test, MyApp.Meili}, retry: false],
  inline_poll_interval: 1

# test/support
def meili(conn) do
  case conn.path_info do
    ["tasks", _] -> Req.Test.json(conn, %{"uid" => 1, "status" => "succeeded"})
    ["indexes", _, "documents" | _] ->
      Req.Test.json(conn, %{"taskUid" => 1, "status" => "enqueued"})
    ["indexes", _, "search"] -> Req.Test.json(conn, %{"hits" => []})
  end
end
```

Plus `Req.Test.stub(MyApp.Meili, &MyApp.MeiliStub.meili/1)` in the case template. Oban: `testing: :manual`, `use Oban.Testing`, `assert_enqueued`, `perform_job`.

What is missing, all documentation or a small promise:

1. `req_options` and `inline_poll_interval` are in no guide.
2. Oban jobs persist URL, prefix and repo, not `req_options`, so the plug must be in app config. Workers also poll tasks.
3. Workers are `@moduledoc false`. Recommend declaring both names and the `operation`, `schema`, `document_ids` args supported for assertions. `schema` is `"Elixir.MyApp.Post"`.
4. `retry: false`, or failing task GETs back off for seconds. Default poll interval adds 100 ms per inline sync.
5. The golden path hardcodes `sync_mode:` per call, so test config cannot flip it.
6. Non-Phoenix apps need `plug` in test. LiveView tests should see stubs (it sets `$callers`).
7. Unstubbed calls raise, so every test that writes through a syncing context needs the stub; `setup_all` and seeds are other processes.
8. A stub proves the app's logic, not the integration: this bug is the example. Include one tagged live smoke test against a **keyed** server.

Comparables (V, their READMEs or docs): Searchkick disables callbacks globally, enables per test, reindexes and refreshes; meilisearch-rails offers `synchronous: true`, `without_auto_index`, `deactivate!`; Scout's docs offer a collection engine "for... running tests"; elasticsearch-elixir injects a mock API module. Req.Test and Oban.Testing already give Elixir the idiom, so a `Scrypath.Testing` module is not yet earned.

## 4. Fresh-consumer walk (repeatable protocol)

- **Pins:** exact Hex version, toolchain, `getmeili/meilisearch:v1.15` by digest in **production mode with a master key**, Postgres, prompt, model, time budget. Commit the protocol.
- **Isolation:** new agent session in a container or empty home: no repo, memory, AGENTS file or prior context. Allowed: HexDocs, hex.pm, official dependency docs. Forbidden: this repository, GitHub, reading `deps/scrypath`. A peek is logged as "docs insufficient" and flagged.
- **Tasks:** install and declare a schema; connect with a non-master API key; sync, search, update, delete; move to Oban; write tests that pass with Meilisearch stopped; show paginated search in LiveView; recover one failed sync using the docs. No probes for unshipped features.
- **Grader (not the walker):** tests green offline; hidden live smoke green; transcript scan for forbidden reads.
- **Record** (`.planning/research/v1.50-walk/`): per finding the task, verbatim error, pages read, attempts, severity (blocker, workaround, confusion, nit) and the intake guide's bucket (library bug, docs gap, app error, environment, needs info). Record unfinished tasks and grader failures unedited; strip home paths.
- **Runs:** two independent baselines, then one rerun of failed tasks.
- **Label:** "maintainer-side friction evidence". Same model family as the authors; shows no demand; never counts as outside-adopter evidence.

## 5. Facts for the grilling session

**Highlight/crop.** Parameters: `attributesToHighlight`, pre/post tags (default `<em>`), `attributesToCrop`, `cropLength` (10), `cropMarker`; output in `_formatted` (V). The engine concatenates raw field text with the tags: **no HTML escaping** (V, source; upstream issue 1409 left it to clients). A native map through `Scrypath.Meilisearch.search/3` already passes these (V), without hydration, and the caller must pass full config. If built: allowlisted `per_query` keys, raw hits, no struct. Proof: payload tests, live hostile-title test, and a recipe using sentinel tags, escape, then `<mark>`. Check `search_many`. Decide 0.4.0 versus patch. Searchkick and meilisearch-rails highlight sections show no escaping warning, so do better.

**Paging.** Default `maxTotalHits` is 1000; the engine silently clamps, so later pages are empty and `total_hits` is capped (V). Unrecognized `settings:` keys already pass through verbatim, so `%{"pagination" => %{"maxTotalHits" => 5000}}` should work today; atom keys would report false drift and snake_case nested keys would be rejected (V code, U run). Recommend **no new setting and no guard**: document it, warn about cost (vendor: above 20000 can take seconds), add a passthrough/no-drift test and one live clamp assertion. A guard cannot know the live cap reliably.

## 6. Lenses

- **Security:** keyed CI is the lasting fix; Req also drops `authorization` on cross-host redirects. Never log keys.
- **Product/adopter:** the first production deploy and the first test are the walls. Hex shows 0.3.20, 1,932 downloads. The one dependant shares the owner, requires `>= 0.0.0`, and I found no `Scrypath.*` call in its package: no known API consumer.
- **Architecture:** no new public module; one narrow worker-assertion promise.
- **DevOps/release:** keying the service touches every live test; keep a keyless path covered. Bug releases are exempt from the proposed 14-day cadence.
- **Accessibility:** paging controls need an honest count label; `<mark>` over `<em>`.
- **Maintainer:** 4-6 plans, two releases, zero dependencies. Later candidate, not in scope: CI pins v1.15; latest is v1.58.0.

## 7. Adversarial pass

- *"Static reading could be wrong."* Phase 199's RED test settles it. If current code passes a keyed server, stop, drop 199, and keep keyed CI.
- *"Just hotfix; the milestone is then optional."* Hotfix immediately, yes. The walk still earns one plan because this bug shows nobody had walked the production path.
- *"A walk would find the bug anyway."* Do not delay a known fix to test the instrument.
- *"Walk before guide delays the guide."* About one plan, and it gives an unprimed baseline.
- *"Stubs couple adopters to Meilisearch wire shapes."* True; the extracted-fence test and live smoke limit drift.
- *"The agent is a friendly reader."* Yes: passes are weak evidence, failures useful.

## 8. Confidence and what would change it

Bug is real 0.95. This scope and order 0.8. Cutting highlight 0.65.

- Outside report: reorder to it.
- Walk finds nothing beyond testing: ship the guide and close.
- Stub exceeds about 30 lines or fails with `perform_job`: ADR for `Scrypath.Testing`.
- Maintainer wants highlight, or an adopter asks: open 202.
- Passthrough test fails: small declared pagination setting.

Sources: meilisearch/meilisearch (`extractors/authentication/mod.rs`, `milli/.../matches/mod.rs`, `search/mod.rs`), Meilisearch highlight, pagination, limitations and security docs, v0.25 release notes (search summary), hex.pm API, live HexDocs, comparable READMEs, vendored Req, Oban and LiveView source.
