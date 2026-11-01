# Phase 185: Executable UI Quality Foundations - Pattern Map

**Mapped:** 2026-10-30  
**Files analyzed:** 17 planned or affected path groups  
**Tracked analogs found:** 17 / 17 (10 exact, 7 partial/role matches)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match |
|---|---|---|---|---|
| `dev/mix/tasks/verify.phase99.ex` | utility | batch | same file | exact |
| `test/mix/tasks/verify.phase99_test.exs` | test | request-response | same file | exact |
| New root UIF contract tests under `test/mix/tasks/` | test | batch/subprocess | `test/mix/tasks/verify_phoenix_example_package_test.exs` | role-match |
| New Node L1 scanner/ledger and focused tests under `scripts/ci/` | utility/test | transform, Git/file I/O | `scripts/ci/phase182_acceptance.test.cjs` | partial |
| `examples/scrypath_ecommerce/contrast-checker.mjs` | utility | file-I/O/transform | same file | exact |
| `scrypath_ops/assets/css/contrast-pairs.mjs` | config | transform | same file | exact |
| `scrypath_ops/test/scrypath_ops_web/design_tokens_contract_test.exs` | test | transform | same file | exact |
| `brandbook/tokens/tokens.json` | config | transform | `design_tokens_contract_test.exs` | partial |
| `scrypath_ops/assets/css/app.css`; `examples/scrypath_ecommerce/assets/css/app.css` | config | transform/build | app Tailwind profiles in each `config/config.exs` | exact |
| `scrypath_ops/lib/scrypath_ops_web/controllers/page_controller.ex` | controller | request-response | same file | exact |
| Delete `scrypath_ops/lib/scrypath_ops_web/controllers/page_html.ex` and `page_html/home.html.heex` | component/view | request-response | `page_html.ex` | role-match |
| `scrypath_ops/test/scrypath_ops_web/controllers/page_controller_test.exs` | test | request-response | same file | exact |
| `examples/scrypath_ecommerce/Makefile`; `package.json`; delete `e2e/ops-ui-visual-judge.mjs` | config/utility | request-response | `workflow_wiring_test.exs` | partial |
| `scripts/ci/ecommerce_evidence.cjs` and `.test.cjs` | utility/test | transform/file-I/O | same files | exact |
| `test/mix/tasks/workflow_wiring_test.exs` | test | request-response | same file | exact |
| Active UI review docs / rubric references | config | transform | `e2e/UI-REVIEW.md` | partial |
| Disposable rendered evidence and its guard tests | test/utility | file-I/O/browser | `e2e/ui-review.mjs` and `.selftest.mjs` | partial |

Build outputs under `priv/static` are generated evidence targets, not source or scanner inputs. The standalone and ecommerce apps both define independent Tailwind profiles and output paths; preserve and assert both.

## Pattern Assignments

### Root required-contract spine and subprocess tests

**Analogs:** `dev/mix/tasks/verify.phase99.ex`, `test/mix/tasks/verify.phase99_test.exs`, `test/mix/tasks/verify_phoenix_example_package_test.exs`

`verify.phase99.ex` owns the focused list and runs it as one Mix test invocation (lines 5-13, 35-47):

```elixir
@focused_tests [
  "test/scrypath/phase99_contract_test.exs",
  "test/scrypath/phase111_contract_test.exs",
  "test/mix/tasks/verify.phase99_test.exs",
  "test/mix/tasks/workflow_wiring_test.exs"
]
run_test!(@focused_tests, "Phase 99 trust-hardening verification")
```

The wiring test asserts the focused list in `verify.phase99_test.exs` (lines 28-38). Add Phase 185 contract coverage there; keep it behind `mix verify.repository_contracts`, not a separate CI-only or optional app lane. For subprocess status handling, follow `verify_phoenix_example_package_test.exs` (lines 118-130): pass argv to `System.cmd`/an injected runner, capture output and assert a nonzero child status raises `Mix.Error`. Use this same path to prove scanner, contrast, and token-drift failures reach the required command.

### L1 scanner, shrinking ledger, and disposable Git fixtures

**Analog:** `scripts/ci/phase182_acceptance.test.cjs` (lines 806-819)

```javascript
const root = fs.mkdtempSync(path.join(os.tmpdir(), "phase182-lock-copy-"));
t.after(() => fs.rmSync(root, { recursive: true, force: true }));
const source = path.join(root, "source");
fs.mkdirSync(source);
execFileSync("git", ["init", "--quiet", source]);
execFileSync("git", ["-C", source, "add", "mix.lock"]);
```

Use isolated temporary repositories and argv-based Git calls for bootstrap, duplicate, same-count swap, trusted-target reduction, candidate first-parent reversal, and missing-history cases. Keep fixture sources outside the scanner roots. This is only a fixture/process analog: there is no existing shrink-only UI finding ledger to copy. Keep finding identity and trusted-ref rules from CONTEXT.md authoritative.

### CSS, contrast and token readers

**Analogs:** `examples/scrypath_ecommerce/contrast-checker.mjs` (lines 65-82, 91-130), `scrypath_ops/assets/css/contrast-pairs.mjs` (lines 1-36), and `scrypath_ops/test/scrypath_ops_web/design_tokens_contract_test.exs` (lines 15-40, 58-104).

The checker already compares full-precision ratios and separates text/large/UI thresholds:

```javascript
function contrastRatioRaw(fg, bg) {
  const L1 = relativeLuminance(fg);
  const L2 = relativeLuminance(bg);
  const lighter = Math.max(L1, L2);
  const darker = Math.min(L1, L2);
  return (lighter + 0.05) / (darker + 0.05);
}
const THRESHOLDS = {
  text: { aa: 4.5, aaa: 7.0 },
  large: { aa: 3.0, aaa: 4.5 },
  ui: { aa: 3.0, aaa: 4.5 },
};
```

Extend its current semantic and muted-pair reader; do not introduce a second color engine. Fix content-label roles and bind focus declarations to their actual adjacent token pairs. The ExUnit token contract is a useful bounded CSS/reference reader: it resolves custom properties and named Tailwind roles from the live stylesheet. Use it as the pattern for explicit discovery and diagnostics, not as a DTCG validator. No existing source validates typed DTCG or exact bidirectional JSON/CSS theme equality; keep that reader small and fail on unsupported forms, duplicates, or missing keys.

The two live build profiles are `scrypath_ops/config/config.exs:51-60` and `examples/scrypath_ecommerce/config/config.exs:61-70`; their `mix.exs` aliases build separate `scrypath_ops` and `scrypath_ecommerce` bundles. Apply the color reset in both source `app.css` files and inspect both generated outputs. Preserve explicit black/white, semantic daisyUI colors, spacing, and typography. Do not assume the standalone build proves the mounted host bundle.

### Standalone root redirect

**Analogs:** `scrypath_ops/lib/scrypath_ops_web/controllers/page_controller.ex` (lines 1-8) and `scrypath_ops/test/scrypath_ops_web/controllers/page_controller_test.exs` (lines 1-8).

The current action is a small transport controller that renders `:home`; the ConnCase test drives `GET /`. Replace that action with a fixed same-host redirect to `/ops`, and replace the tagline assertion with a 302/location assertion. Keep route/mount declarations in their existing routers. Add proof that mounted `/admin/search/*` and ecommerce `/` remain independent; the root redirect must not become a mounted-route redirect.

### Judge retirement and truthful evidence

**Analogs:** `scripts/ci/ecommerce_evidence.cjs` (lines 860-957), `scripts/ci/ecommerce_evidence.test.cjs` (lines 620-641), and `test/mix/tasks/workflow_wiring_test.exs` (lines 947-999).

These files show the active evidence producer, generated summary, tests, package entrypoint and workflow assertions that currently carry judge fields. Update producer, tests, Makefile/package wiring and active docs together. Preserve deterministic browser/parity/contrast/source/artifact evidence; remove synthetic judge fields/reports and the Makefile/package invocation. Do not rewrite archived receipts. The capture harness's review template stays explicitly pending:

```javascript
const row = (id) => ({ id, verdict: "pending", evidence: [], rationale: "" });
return {
  schema: "scrypath.ui-review.v1", capture_sha256: digest, status: "pending",
  surfaces: surfaces.map(({ id }) => row(id)), dimensions: dimensions.map(row),
};
```

### Disposable capture guardrails

**Analog:** `examples/scrypath_ecommerce/e2e/ui-review.mjs` (lines 12-27, 44-87, 180-203) and `ui-review.selftest.mjs`.

Reuse its explicit eight-surface, three-theme, three-viewport inventory, source identity, artifact hashes, source-change detection, and pending review state as preservation checks. `e2e/UI-REVIEW.md` identifies `mix verify.ecommerce_e2e` as the owner of a disposable test stack. Store review records below `ui-review-artifacts/`, outside Playwright cleanup. For Phase 185 before/after proof, use separately named disposable stacks/artifact roots and match source, browser, route, data, theme, and viewport; inspect rendered captures and copy. The current capture script verifies the retained preview's named mount and current `origin/main`; that guard is not permission to operate the retained preview or evidence that a disposable stack is current. Keep the preflight stop and data-preservation rules from `AGENTS.md`/UI-SPEC.md intact. Do not auto-update a disputed baseline.

## Shared Patterns

### Required failures
**Sources:** `verify.phase99.ex`, `verify_phoenix_example_package_test.exs`. Invoke local Node helpers with executable plus argv, capture stdout/stderr and status, and raise on nonzero status. Keep maintainer tooling outside packaged `lib`.

### Bounded static readers
**Sources:** `contrast-checker.mjs`, `contrast-pairs.mjs`, `design_tokens_contract_test.exs`. Read source as text; recognize only explicit syntax/declaration contexts. Use raw contrast thresholds. Reject missing, duplicate, malformed, or unsupported inputs instead of silently skipping them.

### Evidence provenance
**Sources:** `ecommerce_evidence.cjs`, `ui-review.mjs`. Keep deterministic evidence tied to source identity and content hashes, preserve pending review status, and keep generated evidence outside source-cleanup directories.

## No Analog Found

| File / behavior | Reason |
|---|---|
| Shrink-only source-literal ledger and independently trusted first-parent authority | No existing UI finding ratchet; Git temp-repository tests are only a fixture pattern. |
| Typed DTCG 2025.10 validation against exact live CSS theme keys/values | Existing token contracts cover CSS references, not typed DTCG or full mirror equality. |
| Pixel-parity approval from disposable before/after captures | Existing harness records observations and pending review; it does not itself establish parity or design approval. |

## Metadata

**Analog search scope:** `dev/mix/tasks`, `test/mix/tasks`, `scripts/ci`, `scrypath_ops` controllers/tests/assets/config, and ecommerce assets/config/e2e/evidence tooling.  
**Tracked-source gate:** Every named analog was verified with `git ls-files -- <path>`; all returned tracked source paths.  
**Pattern extraction date:** 2026-10-30
