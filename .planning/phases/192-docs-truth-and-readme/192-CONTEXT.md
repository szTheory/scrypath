# Phase 192: Docs truth and README - Context

**Gathered:** 2026-11-20
**Status:** Ready for planning

<domain>
## Phase Boundary

No Hex-shipped doc instructs an adopter to run a repo-only task; the `PROJECT.md` Canonical Adopter Contract text and the check that enforces it agree; the README (GitHub front page, hex.pm page, HexDocs landing page) does one job and its links resolve; one owner-map note names the owning surface for each claim. Requirements: TRUTH-01, TRUTH-02, TRUTH-03, README-01, README-02, README-03.

Out of scope: HexDocs sidebar regroup and upkeep guards (Phase 193), website content (Phase 194), the Hex 0.3.20 release (needs the maintainer's explicit yes), any new guide or guide rename.

</domain>

<decisions>
## Implementation Decisions

### Invariant and contract (TRUTH-01, TRUTH-02)
- One invariant test replaces the old `verify.adopter` pins. It derives the repo-only task list from `dev/mix/tasks/` (task names present there and absent from the shipped `lib/mix/tasks/`), scans every file in `package.files` from `mix.exs`, and allows a mention only in the allowlist (`CONTRIBUTING.md`, `docs/releasing.md`) or in a sentence that says it runs from a source checkout and is not in the Hex package. — **Reversibility:** costly — it replaces several contract tests and the `PROJECT.md` contract wording, so undoing it means re-pinning each of them.
- The plan starts with an inventory of every assertion that pins `verify.adopter` or the shipped-docs wording (`readiness_contract_test`, `docs_contract_test`, `phase98`/`phase99_contract_test`, `verify_adopter_test`, and any `phase108`/`110`/`112` tests), recording for each whether it pins a claim or wiring and where its intent now lives. Tests that pin the task's own behavior (`verify_adopter_test.exs`, the `mix help verify.adopter` output) stay: they test the task, not the docs. Doc-substring pins that demand the string in a shipped guide move to the invariant plus a positive source-checkout assertion. No pin is deleted without a stronger replacement. — **Reversibility:** costly — the inventory is the audit trail for success criterion 2.
- `PROJECT.md` "Canonical Adopter Contract" is edited in the same commit as the pin change: the adopter proof spine is a maintainer task that runs from a source checkout and is not runnable from the Hex package. — **Reversibility:** costly — the contract text and the check must not disagree at any commit.
- Planted-violation cases live in the test itself (an unqualified `mix verify.adopter` guide line fails; a source-checkout-qualified line passes), run against in-memory strings, not by editing a shipped file.
- The qualifier is a small, explicit sentence pattern (a source checkout, and not in the Hex package, within the same sentence or list item), kept as data in the test so it is reviewable.

### README shape (README-01, README-02)
- README keeps: header and badges (the header pin test stays green), one-sentence what-it-is, when it fits and does not fit, installation, one quick path, and at most three onward links after the quick path. Removed: the "Choose a route" block, the Public Surface, Sync modes (replaced by one line), Search, Backfill And Reindex, Drift, Integration smoke, Example and Architecture sections; each already has a guide or the HexDocs sidebar as its home. — **Reversibility:** costly — content leaves the README, so each removed claim must have a recorded owner in the owner map first.
- Word cap: 600 to 800 words, recorded as a chosen cap from the owner map (not a measured optimum). The test enforces an upper bound near the top of that range so a small edit does not trip it. — **Reversibility:** reversible — one constant in a test.
- The quick path states the Meilisearch prerequisite and eventual consistency before its first code block, and ends in a `Scrypath.search/3` call with its result. The schema snippet is textually identical to the one in `guides/golden-path.md` or carries an explicit "intentionally different" marker that the Phase 193 parity guard reads.
- Time-promise phrases ("in five minutes", "in minutes", "quickly", and similar) fail a test; the list is data in the test.
- Repo paths in the README are absolute GitHub URLs; guide links are absolute HexDocs URLs for the Phase 193 sidebar to resolve, consistently one style. No `mix verify.*` string outside a source-checkout qualifier.
- Voice follows `brand/BRAND.md` and the glossary ("queued", "searchable"); copy is written with the ux-writing skill and checked against the forbidden-phrase list, not taste. No claims of speed, comparison or adoption without evidence.

### Built-docs scan (TRUTH-03)
- Extend `test/release/package_metadata_test.exs` or a sibling file: run `mix docs` output through a scan for self-links (a link whose target is the page it sits on, such as the old `readme.html` case) and unresolved extras links, with a planted failing case. The scan reads the built HTML, so it runs only where docs are built and is skipped, with a stated reason, where they are not.
- Link checking is limited to what a build can prove (extras, anchors, relative targets). Live hex.pm and hexdocs.pm checks are not in CI; they are recorded once at the Phase 193 checkpoint.

### Owner map note (README-03)
- One short reference note, `.planning/reference/CLAIM-OWNER-MAP.md`: for each claim (what it is, fit and non-fit, install line, sync modes, support policy, operator UI status) the owning surface (README, HexDocs guide or website) and where the others link. It is written before the README is trimmed and is the input to Phase 193 and the Phase 194 decision. — **Reversibility:** reversible — a planning note.

### Delivery
- Plans: (1) inventory, invariant and contract text; (2) README trim, quick path and README tests, the owner map written first; (3) built-docs scan and checks. Squash-merge each green PR per the standing instruction; PRs that touch `guides/`, `test/` or `mix.exs` pay the full lane cost, so batch where the order allows.
- No Hex release in this phase. The release PR for 0.3.20 needs the maintainer's explicit yes and is raised after the phase lands.

### Decided autonomously
- [Invariant] Q: "Where does the repo-only task list come from?" → Selected: "derived from dev/mix/tasks/ minus lib/mix/tasks/, not hand-kept" — the test recomputes it on every run, so no list can go stale.
- [Invariant] Q: "Which files are scanned?" → Selected: "every path in package.files, expanded from mix.exs" — one data source shared with package_contents_test.
- [Invariant] Q: "Where do the planted cases live?" → Selected: "inline strings in the test" — no shipped file is edited to prove the check.
- [README] Q: "Where do the README tests live?" → Selected: "one small test file, no network" — a plain file read, so it can be rewritten or moved cheaply.
- [README] Q: "Link style for guides" → Selected: "absolute HexDocs URLs" — matches Oban and Ecto READMEs and resolves on GitHub, hex.pm and HexDocs; one find-and-replace to change.
- [Scan] Q: "Docs scan placement" → Selected: "sibling of package_metadata_test" — test file layout only.
- [Owner map] Q: "Note location and name" → Selected: ".planning/reference/CLAIM-OWNER-MAP.md" — a planning note.

### Claude's Discretion
- Exact README wording, section order within the fixed shape, and the specific time-promise phrase list.
- Exact qualifier sentence pattern, so long as the planted qualified line passes and the unqualified one fails.

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Scrypath.RepoTooling.task_source!/1` reads task sources from `dev/mix/tasks/`; `dev/mix/tasks/verify.adopter.ex` is the task being qualified.
- `test/release/package_metadata_test.exs` and `package_contents_test.exs` already read `mix.exs` package data; the README header pin is covered by `test/release/package_metadata_test.exs` and `test/mix/tasks/brand_pin_contract_test.exs`.
- `mix.exs` `docs/0` sets `main: "readme"`, so the README is the GitHub, hex.pm and HexDocs landing page; `groups_for_extras` is Phase 193's.

### Established Patterns
- Contract tests pin substrings with `assert_contains_all`; `docs_contract_test.exs` (about 1,400 lines) is the largest pin surface (lines 315-343 pin the `verify.adopter` parity).
- Pins found in the grep: `readiness_contract_test.exs:41,64-67` (support guide, README and CONTRIBUTING must contain the task name), `phase98_contract_test.exs:12-26`, `phase99_contract_test.exs:24-45`, `docs_contract_test.exs:315-343`.
- Shipped docs naming the task: `guides/support-and-compatibility.md:131-132`, `guides/outside-adopter-intake.md:32-33`, `docs/operator-support.md:7` (qualified), `docs/jtbd-gap-map.md:78` (qualified), README line 31 (qualified, removed with the route block).

### Integration Points
- `mix.exs` `package.files` (README.md, guides, selected docs, CONTRIBUTING.md, ARCHITECTURE.md) defines the shipped set the invariant scans.
- `.planning/PROJECT.md` Canonical Adopter Contract is the text that must change with the pins.
- Phase 193 reads the owner map and the quick-path schema parity marker.

</code_context>

<specifics>
## Specific Ideas

- Oban's README shape (features, requirements, installation, quick start, learning links) is the pattern; Ecto and Oban link to HexDocs by absolute URL.
- The prep notes (`.planning/research/v1.48-prep/A` to `D`) hold the evidence and the adversarial pass; D section 2 lists the failure modes to avoid (weakening a pin to reach green; deciding "trim" by feel without the owner map).

</specifics>

<deferred>
## Deferred Ideas

- HexDocs `groups_for_extras` regroup, `guides/overview.md` fate, link and snippet parity guards: Phase 193.
- Website Home, Evaluate, Operate content and IA: Phase 194, decided at the checkpoint.
- Hex 0.3.20 release: after this phase, with the maintainer's explicit yes.
- Adding `guides/` to the CI classifier allowlist: a measured candidate for `CI-EFFICIENCY.md`, not part of this phase.

</deferred>
