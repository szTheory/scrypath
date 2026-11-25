# scrypath_fixtures

A dev and test only Mix project ([ADR 0002](../../.planning/adr/0002-shared-fixtures-mix-project.md)). It holds pure builders for three Scrypath-owned adopters: Shopadelic (a storefront), Logistify (shipments) and Wikily (a wiki). All three are fictional. The data is written for this repository, and nothing is copied from the sibling brand repositories. The project never ships in the Hex package or in a release.

The builders emit raw Meilisearch task maps and Oban job maps. The real Scrypath code (`Scrypath.sync_status/2`, `failed_sync_work/2`, the Ops posture summary) turns them into the states an operator sees, so only states the library can actually reach appear in a fixture.

## How to run the check

```sh
cd scrypath_ops && mix scrypath_fixtures.check_fixtures
```

The `preferred_envs` entry in `scrypath_ops/mix.exs` runs it in the test environment. It needs no database, and it is the first step of `mix test` in `scrypath_ops`.

## Exit rule

Decision (maintainer, 2026-11-22): the project stays separate. Revisit when the phase173 host spec is ported or at v1.51. The rule below is the test that decision answered.

Fold this project into `scrypath_ops/catalog/` if no second consumer appears by Phase 197. A second consumer is a Mix project other than `scrypath_ops` that lists `scrypath_fixtures` in its deps (the candidate is the demo host replacing its phase173 copy). The decision is evaluated at the start of Phase 197 planning. Module names stay stable, so folding is a rename.

The cost input is the warm ops-ui delta against a same-day control, recorded by Phase 196 in `.planning/reference/CI-EFFICIENCY.md`. A delta above about 60 s also argues for folding. That threshold is advisory, from prep note B (`.planning/research/catalog-prep/B-fixtures-and-adopters.md`, the D1 revisit trigger and its adversarial pass). It is not an ADR trigger and does not stop a run by itself.

## Phase 173 deletion trigger

The two `phase173_fixture_source.ex` copies (one under `examples/scrypath_ecommerce/test/support/`, one under `scrypath_ops/test/support/`) and the `:phase173_fixture` branches of `PostureLive` stay as they are. Delete them when the four host specs that use them are ported to catalog scenarios or retired:

- `ops_reskin_contract.spec.ts`
- `ui_iteration3.spec.ts`
- `ui_followup.spec.ts`
- `ui_baseline.spec.ts`

Update `PRESERVATION_FIXTURE_FILES` in `scripts/ci/ecommerce_evidence.cjs` and its receipts in the same change. Both copies are identity-hashed into the Phase 185 preservation receipts, so editing or deleting either one on its own invalidates them.

## Boundary decisions

These record why the new top-level `fixtures/` directory needed no change in some places and a small one in others. Each is pinned by a test.

- The compatibility path classifier lists `fixtures` as irrelevant: the root `mix test` never compiles it, so a fixtures-only change rightly skips the advisory matrix.
- `ops-ui-path` already covers `fixtures/`, so ops-ui runs for a fixtures change.
- The ecommerce classifier runs the Docker lanes for it, because the images copy and compile it.
- `package_contents_test` needs no change: `allowed_top_level` is derived from `files:` in the root `mix.exs`, so `fixtures` can never be allowed.
- `package_metadata_test` refutes it from the package non-vacuously: it checks that the tree exists and that no `files:` entry reaches it.
- `.dockerignore` keeps the sources (the builder and test stages compile them) and ignores `_build` and `deps` under `fixtures/`.
- The Dockerfile copies this project's `mix.exs` in its three early blocks, so `deps.get` sees the manifest.
- The Docker verify script forbids `scrypath_fixtures` in the prod image and in the host project, and forbids the `ScrypathFixtures` module in its runtime probe.
- There is no Dependabot entry and no lock file: the project has no Hex dependency of its own.
- The UI literal policy does not scan it.
- The root formatter and the namespace fence cover it.

## Hostile text

`ScrypathFixtures.Hostile` holds twelve named strings for stress cases: a right-to-left override, bidirectional isolates, a family emoji joined by zero-width joiners, a zero-width space, one letter spelled two ways (precomposed and decomposed), Han and Arabic text, a 511-byte id, a 512-byte id, an unbroken 200-character token and markup text. Every non-ASCII character is an Elixir `\u{...}` escape, so no hidden character is ever typed into source. The check refuses a raw bidirectional control, zero-width or other invisible formatting character or byte-order mark in any file of this project (`:raw_format_char`); a source file that reads differently from what it runs is the Trojan Source class of problem. The list is `ScrypathFixtures.Check.format_codepoints/0`: U+00AD, U+061C, U+180E, U+200B-U+200F, U+202A-U+202E, U+2060-U+2064, U+2066-U+2069, U+FE00-U+FE0F, U+FEFF and U+E0000-U+E007F.

Hostile text is stress data and nothing else. It lives in one named variation, Shopadelic `:hostile_ids` (scenario id `shopadelic_hostile_ids`, kind `:stress`), and no ordinary record carries it.

The placement rule is that a string goes only where Meilisearch and Scrypath can carry it:

- An id with a character outside `a-z A-Z 0-9 - _`, or over 511 bytes, is rejected with `invalid_document_id`, and the failed task echoes it as sent. Those ids appear only inside such failures.
- The 511-byte id and the 200-character token are valid ids, so they appear only as `document_ids` in job args.
- Markup and non-Latin text appear only inside the document a `missing_document_id` failure echoes.

`scrypath_ops/test/scrypath_ops_web/live/fixtures_hostile_render_test.exs` renders the scenario on the failed sync page and the health page and asserts that the markup shows as text and no script element is created. It does not assert that long text is truncated: unbounded error text is finding F2.

The other stress variation is Logistify `history_over_limit`, which reproduces finding F1 (task history over 1,000). Both findings, with F3 and F4 found while building this project, are written up in [`196-FINDINGS.md`](../../.planning/milestones/v1.49-phases/196-fixtures-and-three-adopters/196-FINDINGS.md) and are handed to the maintainer, not fixed here.

## Bulk data and the golden digest

`ScrypathFixtures.Bulk` makes the ordinary job and document ids from small word lists written for this project. There is no random source and no dependency. A record is a pure function of its kind, a seed and a position, through `:erlang.phash2/2`, and `rows/3` refuses more than 5,000 records (a bigger set belongs in a label).

A fixed sample (the first 50 records of each kind at seed 196) is hashed with SHA-256 over the deterministic external term format, and `Bulk.golden_digest/0` holds the expected value. The check reports `{:bulk_digest, got}` when the sample no longer hashes to it, whether a word list changed or an OTP upgrade changed the hash.

To update it deliberately, print `Bulk.sample/0` before and after the change, read the difference, and only then paste the new `Bulk.sample_digest/0` into `@golden_digest` in `lib/scrypath_fixtures/bulk.ex`. Never update it to make the check pass.

## Provenance

Every adopter is fictional, and the data is Scrypath-owned. No record is copied from the sibling brand repositories, and the ids are not theirs. The check enforces this:

- every scenario label says "(fictional)";
- every adopter module and schema has a line saying it is a fictional adopter, Scrypath-owned data, with no records copied (`:provenance_missing`);
- no label, scenario string, README line or `lib/` source makes a compliance claim or uses a sibling canon id (`:denylisted_word`). The words themselves are listed in one attribute of `lib/scrypath_fixtures/check.ex` and nowhere else, which is why that one file is the only exemption from the scan;
- `lib/` source never reads the wall clock, a random source, the operating system, the file system or a repository (`:impure_source`). Every time is `now` minus an offset, and the preview epoch is the one literal. The forbidden calls are the explicit list `ScrypathFixtures.Check.impure_tokens/0`, one planted file each in `fixtures_provenance_test.exs`. A token matches where a word starts, on a line of code: a whole-line comment may name a call, a comment after code on the same line is still scanned, and files outside `lib/` (recordings, this README, scripts) are never scanned for these. The list:
  - the wall clock: `DateTime.utc_now`, `DateTime.now`, `NaiveDateTime.utc_now`, `NaiveDateTime.local_now`, `Date.utc_today`, `Time.utc_now`, `:erlang.system_time`, `:erlang.monotonic_time`, `:erlang.timestamp`, `:erlang.localtime`, `:erlang.universaltime`, `:calendar.local_time`, `:calendar.universal_time`;
  - waiting on real time: `Process.sleep`, `:timer.`;
  - datetime literals, which pin a calendar date (bracket form): `~U[` (allowed only in `lib/scrypath_fixtures.ex`, the preview epoch), `~N[`, `~D[`, `~T[`;
  - a random source or a value that differs on every call: `:rand.`, `Enum.random`, `Enum.shuffle`, `Enum.take_random`, `:crypto.strong_rand_bytes`, `:erlang.unique_integer`, `UUID.generate`, `UUID.bingenerate`, `UUID.uuid1`, `UUID.uuid4`;
  - the operating system, the file system and a repository: `System.`, `:os.`, `File.` (allowed only in `lib/scrypath_fixtures/recordings.ex`, which loads the recordings at compile time, and in `lib/scrypath_fixtures/check.ex`, which reads this project's own files), `Repo.`.

## Recordings

The Meilisearch payloads the fake client is checked against were recorded once from a pinned server image. See `recordings/meilisearch-v1.15/PROVENANCE.md` for the image, the method and how to repeat it.
