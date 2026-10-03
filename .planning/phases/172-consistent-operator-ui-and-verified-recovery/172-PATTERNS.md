# Phase 172: Consistent Operator UI and Verified Recovery — Pattern Map

**Mapped:** 2026-10-03
**Scope:** Existing six surfaces, shared semantics, scoped recovery, guarded promotion, and existing verification lanes. No source changes made by this mapping.
**Files classified:** 29 existing files plus 2 optional private helpers; 29 existing-file matches and 2 partial helper matches. Grouped rows expand literally as specified below.

Paths below are relative to the repository root. `web/` means `scrypath_ops/lib/scrypath_ops_web/`; `ops/` means `scrypath_ops/lib/scrypath_ops/`; `tests/` means `scrypath_ops/test/scrypath_ops_web/`; `example/` means `examples/scrypath_ecommerce/`. These abbreviations are documentation only. All existing analog paths were verified in `git ls-files`; none are install/runtime mirrors.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `web/components/ops_ui.ex` | component | transform | Same file, declarative attrs and slots, lines 173–195 | exact |
| `scrypath_ops/assets/css/app.css` | config | transform | Same file, named `@theme` roles, lines 124–201 | exact |
| `scrypath_ops/assets/js/app.js` | hook | event-driven | Same file, CommandPalette focus lifecycle, lines 98–205 | exact |
| `web/components/layouts.ex` | component | transform | `ops_ui.ex` shared components; existing shell is modification anchor | role-match |
| `web/live/control_room_live.ex` | controller/component | request-response | Posture mount/load/render structure | exact |
| `web/live/posture_live.ex` | controller/component | request-response | Same file, service summary and guard | exact |
| `web/live/failed_sync_live.ex` | controller/component | event-driven | Existing retry dispatch; Search URL state; Posture exact-task wait | exact |
| `web/live/sync_drift_live.ex` | controller/component | event-driven | Posture guarded task wait; Search URL state | exact |
| `web/live/search_live.ex` | controller/component | event-driven | Same file, handle_params lines 70–109 | exact |
| `web/live/playbook_live.ex` | controller/component | file-I/O | Existing file action handlers plus shared ops_modal | exact |
| `ops/operator_selection.ex` (optional new private helper) | utility | transform | Posture allowlist lookup, lines 131–141 | partial |
| `ops/recovery_observation.ex` (optional new private helper) | service | event-driven | Posture exact-task wait; root IndexingAck | partial |
| `scrypath_ops/assets/css/DESIGN-TOKENS.md` | config/documentation | transform | Existing catalog paired with CSS authority | exact |
| `scrypath_ops/docs/operator-ia.md` | config/documentation | transform | Existing six-surface IA; refine historical green-verdict claim | exact |
| `scrypath_ops/assets/css/contrast-pairs.mjs` | config | transform | Existing changed-token manifest | exact |
| `tests/live/{control_room,posture,failed_sync,sync_drift,search,playbook}_live_test.exs` (6 files) | test | event-driven | FailedSync LiveView setup and SyncDrift client stubs | exact |
| `tests/{ops_a11y_contract,design_tokens_contract,operator_ia_contract}_test.exs` (3 files) | test | transform | Existing focused shared contracts | exact |
| `example/lib/scrypath_ecommerce_web/controllers/e2e_controller.ex` | controller | request-response | Same file, runtime config/projection and strict task helpers, lines 445–503 | exact |
| `example/lib/scrypath_ecommerce_web/router.ex` | route | request-response | Existing dev/test E2E route group | exact |
| `example/e2e/helpers/e2e.ts` | utility | request-response | Same file: requestJson, waitForLiveConnected, waitForSearchVisible | exact |
| `example/e2e/operator.spec.ts` | test | event-driven | Same file entry point; replace weak outcome assertions | exact |
| `example/e2e/admin_shell_chrome.spec.ts` | test | event-driven | Existing keyboard/theme tests; extend full focus cycle | exact |
| `example/e2e/admin_contrast_matrix.spec.ts` | test | batch | Existing explicit/system theme and contrast reports | exact |
| `example/e2e/admin_screenshot_matrix.spec.ts` | test | batch | Existing state/theme/viewport catalog | exact |

The optional helper filenames are suggested ownership boundaries, not locked product requirements. If responsibilities remain inside existing LiveViews, omit those files. Existing root worker/recovery/task modules are reference seams, not automatically authorized change targets. Avoid making a new public recovery API to solve a UI observation gap.

## Pattern Assignments

### 1. Shared components, CSS, shell, and dialogs

**Primary analog:** `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex`, lines 173–195. Use declarative attrs, global forwarding, semantic native elements, and slots:

```elixir
attr(:type, :string, default: "button")
attr(:class, :any, default: nil)
# Existing :rest includes disabled, phx-disable-with and aria-label.
slot(:inner_block, required: true)

def ops_button(assigns) do
  ~H"""
  <button type={@type} class={[button_classes(@variant, @size), @class]} {@rest}>
    {render_slot(@inner_block)}
  </button>
  """
end
```

Apply to every touched OpsUi control and its six-surface consumers: native disabled state, persistent labels/help/error IDs, radio/select branches, semantic mode selection. Preserve the existing import via `use ScrypathOpsWeb, :live_view`; do not add a component framework. Shared body/action roles must override inherited vendor small-button sizing centrally.

**CSS authority:** `scrypath_ops/assets/css/app.css`, lines 132–136 and 188–201:

```css
--spacing-ops-row: 1rem;
--spacing-ops-section: 1.5rem;
--spacing-ops-panel: 1.25rem;
--spacing-ops-control-gap: 0.5rem;
--spacing-ops-page-gap: 1.5rem;
--text-ops-body: 0.875rem;
--text-ops-h3:   1rem;
--leading-ops-tight:  1.3;
--leading-ops-body:   1.5;
```

These are separate excerpts from the named ranges. Follow UI-SPEC for 16px narrow panel padding, 20px wide padding, 14px controls, named 90 modal layer, and matching 120ms modal removal. Current modal token is 70 at line 170 and must change. Update DESIGN-TOKENS with actual consumers; do not rewrite unrelated palette/metadata values. Keep technical scrolling bounded using `ops_code_block` lines 1210–1222 and wrap identifiers.

**Focus analog:** `scrypath_ops/assets/js/app.js`, lines 152–176 and 194–205:

```javascript
restoreFocus() {
  const target = this.previousFocus
  this.previousFocus = null
  if (target && target.isConnected && typeof target.focus === "function") {
    target.focus({preventScroll: true})
  }
},
```

```javascript
const first = focusables[0]
const last = focusables[focusables.length - 1]
if (!root.contains(document.activeElement)) {
  e.preventDefault()
  first.focus({preventScroll: true})
} else if (e.shiftKey && document.activeElement === first) {
  e.preventDefault()
  last.focus({preventScroll: true})
} else if (!e.shiftKey && document.activeElement === last) {
  e.preventDefault()
  first.focus({preventScroll: true})
}
```

Adapt into one shared modal lifecycle, including background inertness, removed-trigger successor focus, Escape/Cancel, teardown, and LiveView patch behavior. Existing `ops_modal` lines 1243–1270 has dialog naming and removal transition but lacks these behaviors. Existing palette dismissal waits 160ms (line 137); it is not evidence of the required modal 120ms contract. Close/suppress palette/drawer while modal owns focus. Do not copy incomplete visibility filtering as a complete accessibility guarantee. Shell keeps one shortcut hint next to the actual jump control; remove repetitions from Control Room and other surfaces.

### 2. Six LiveViews and URL schema continuity

**Imports/service boundary:** `web/live/posture_live.ex`, lines 9–12:

```elixir
use ScrypathOpsWeb, :live_view
alias ScrypathOps.Integrations.Sigra.Gating
alias Scrypath.Meilisearch.Tasks
```

Posture mount lines 15–33 resolves allowlist and options once and assigns explicit initial state; load_posture lines 67–82 consumes `ScrypathOps.Posture.summary/2`. Use that boundary for Control Room/Posture, preserving unknown/unconfigured/missing-backend states. All templates retain Layouts.app and shared page/section/heading controls. Six surface wording comes from UI-SPEC, with source/job/task nouns and compact reason summary; avoid freezing prose wholesale in tests.

**URL analog:** `web/live/search_live.ex`, lines 70–109. `handle_params/3` owns URL-derived assigns; mode changes use push_patch elsewhere in that file. Copy lifecycle placement, not invalid-mode fallback semantics for schemas. **Allowlist validation:** `web/live/posture_live.ex`, lines 135–141:

```elixir
defp mod_from_allowlist(str, allowlist) when is_binary(str) do
  name = String.trim(str)
  case Enum.find(allowlist, &(module_flat_name(&1) == name)) do
    nil -> :error
    mod -> {:ok, mod}
  end
end
```

Use an encoded schema parameter on rendered Posture → Failed Sync → Sync/Drift links and selection patches. Respect mounted prefixes. Missing parameter can select a default; an explicit invalid/removed schema must produce unavailable state and cannot silently select the first schema for mutations. Never create atoms from input. Reset/invalidate observations on context changes and reject late responses keyed to a superseded schema/index/generation. Search and Playbooks receive semantic/copy fixes without expanding their domain workflows.

### 3. Retry correlation, task status, and promotion

**Guard + exact returned task:** `web/live/posture_live.ex`, lines 102–122:

```elixir
Gating.gate_sensitive_action(socket, :swap_live, fn ->
  scrypath_opts = socket.assigns.scrypath_opts
  wait_opts = task_wait_opts(scrypath_opts)
  case Scrypath.Meilisearch.swap_indexes(mod, scrypath_opts) do
    {:ok, %{task: task}} ->
      case Tasks.wait_for_task(task, wait_opts) do
        {:ok, _waited} ->
          socket
          |> load_posture()
          |> put_flash(:info, "Swap live index completed for #{module_flat_name(mod)}")
        {:error, reason} ->
          put_flash(socket, :error, "Swap live failed: #{inspect(reason)}")
      end
    {:error, reason} ->
      put_flash(socket, :error, "Swap live failed: #{inspect(reason)}")
  end
end)
```

Copy identity and guard semantics; move long observation into bounded asynchronous UI work so accepted/running/timeout states render. Preserve existing Sigra audit/authorization, including failed_work_retry. Revalidate promotion prerequisites inside the guarded server handler immediately before mutation. A shared predicate must enforce UI-SPEC's complete same-context fresh reconcile/contract, target/live identity, zero mismatch, no pending/retrying/reindex/cutover/failed signals, and available supported backend. Current SyncDrift readiness and enabled button are defective analogs. Invalidate current success on mutation, selection, failed refresh, disconnect; no TTL shortcut or URL-derived success.

**Retry result seam:** `web/live/failed_sync_live.ex`, lines 111–143 obtains `FailedWork.recovery_action(row)` then calls `Scrypath.retry_sync_work(recovery, ScrypathOps.Schemas.runtime_opts(...))`. Replace its discarded `{:ok, _result}` and `Retried` flash with accepted-work identity. Root `lib/scrypath/operator/recovery_action.ex`, lines 44–60 validates replay payload and delegates to Enqueue. It does not clear historical failure records.

**Critical observation limit:** `lib/scrypath/oban/upsert_worker.ex`, lines 19–24:

```elixir
case backend.upsert_documents(schema_module, documents, config) do
  {:ok, _} = ok -> IndexingAck.await(backend, ok, config)
  {:error, reason} -> {:error, reason}
end
```

`lib/scrypath/oban/indexing_ack.ex`, lines 12–22 waits the exact task but returns `:ok`, losing its task ID at that boundary. Do not assert that enqueue return already exposes the eventual task. The implementation plan must specify how bounded UI-owned observation correlates replacement job, exact backend task, and expected document; missing correlation stays unknown. Queue completion alone cannot satisfy UI-SPEC, even though this worker ordinarily awaits indexing. Do not choose the newest successful global task. A scoped unique document helps discriminate test work but does not on its own establish a production job→task identity join.

Retain original failure as history. Ordinary recovery does not require promotion or a green fleet. Accepted, running, queue-only completed, verified, failed, timed out, stale and unknown remain distinct. Refreshing an observation never resubmits the mutation.

### 4. Deterministic fixture, probe, and mounted browser

**Fixture analog:** `example/lib/scrypath_ecommerce_web/controllers/e2e_controller.ex`, lines 445–463:

```elixir
config = Scrypath.Config.resolve!(sync_mode: :manual)
backend = Scrypath.Config.fetch_backend!(config)
target_index = Scrypath.Meilisearch.IndexManagement.target_index_name(Product, config)
target_config = Keyword.put(config, :index_name, target_index)
# ... create/settings calls ...
documents = Enum.map(products, &Scrypath.Projection.document(Product, &1))
Product
|> backend.upsert_documents(documents, target_config)
|> wait_sync!(config, "seed swap target documents")
```

Use actual runtime index resolution and projected records for a dedicated replayable failure, unique run marker, non-first selected schema, captured baseline IDs, and exact expected active-index document/value. Existing invalid-backend injector and incident presentation scenario are not recovery fixtures. Extend only existing dev/test route group if a new probe route is needed. Task helper lines 487–503 raises on task errors; preserve fail-closed setup/cleanup and tighten permissive no-task clauses where an operation requires task evidence. Never copy reset error swallowing. Probe accepts exact work/task/context identity, not old global swap success.

**Browser analog:** `example/e2e/helpers/e2e.ts` imports `{ expect, type APIRequestContext, type Page }` from Playwright. Lines 11–23 wait for actual LiveSocket and connected DOM. `requestJson` rejects non-OK HTTP responses with path/status/body. `waitForSearchVisible` uses bounded `expect.poll` and expected content; extend that helper family with identity-aware recovery observation and evidence. Use rendered links between incident screens; direct navigation is reserved for starting entry and restoration/error tests.

`operator.spec.ts` lines 11–58 currently permits missing Retry and text matching the original page; lines 60–89 uses a generic swap probe. Replace these assertions. Require actual retry, new accepted work, correlated terminal task, unique expected content, visible honest outcome, and retained history. Keep promotion scenario separate and tied to returned task/index pair. Existing shell test checks only a single Tab step; extend full forward/backward cycles and focus return. Reuse existing screenshot/contrast scenario catalogs rather than adding a third catalog. Contrast-only axe is not a general accessibility scan; add a focused non-contrast scan of changed journey states.

### 5. ExUnit service boundaries and shared contracts

**Analog:** `scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs`, lines 5–26:

```elixir
use ScrypathOpsWeb.ConnCase, async: false
import Phoenix.LiveViewTest
alias ScrypathOps.Test.OpsPostA

defmodule RecordingOban do
  def insert(changeset) do
    job = Ecto.Changeset.apply_changes(changeset)
    {:ok, %{job | id: 991, state: "available"}}
  end
end
```

Existing setup lines 53–115 saves/restores application configuration with on_exit; preserve isolation for all modified LiveView tests. New standalone support modules should follow project module placement guidance rather than perpetuating nested test modules unnecessarily. `sync_drift_live_test.exs` lines 14–42 provides client-call counters and swap stub; make observations deterministic for pending→terminal, failure, timeout, stale refresh, switched schema, forged event, and changed prerequisite cases. Assert zero swap calls when ineligible. Use start_supervised! for state holders, messages/render_async as applicable, and selectors/semantic outcomes instead of raw HTML snapshots or sleeps.

Apply the same test shape to all six LiveViews. Shared contract files cover native disabled inputs, associated labels, radio/select branches, headings, repeated shortcut hint, and token consumers. Browser alone proves focus geometry and real backend seam; static source assertions do not.

## Shared Patterns

- Authentication: retain Gating at each mutation; no new auth API or client-only safety predicate.
- Errors: explicit tagged tuples at service boundaries; readable contextual status with technical details secondary. Failed reads invalidate current readiness.
- Observation identity: schema + real index + source failure + replacement work + task; generation guards reject late data.
- Rendering: Layouts.app → OpsUi components; native elements, named roles, wrapping actions, bounded technical overflow.
- Cleanup: application env restored in ExUnit; serial seeded browser work in disposable Compose; preview `4012` is never a test-reset target.

## No Exact Analog Found

| Responsibility | Proposed file | Gap |
|---|---|---|
| UI-owned replacement-job/backend-task/document observation | optional `ops/recovery_observation.ex` | Existing worker waits and discards task identity; no inspected analog implements the whole join. Plan concrete correlation and fail closed where unavailable. |
| Strict URL schema resolver shared across recovery surfaces | optional `ops/operator_selection.ex` | Existing allowlist lookup and Search handle_params cover pieces; explicit-invalid-schema behavior needs its own contract. |
| Complete file-dialog lifecycle | existing `app.js` + `ops_ui.ex` | Shell focus primitives exist; inertness, removed-trigger successor and overlay arbitration require implementation. |

## Verification Entry Points

Commands are grounded in CONTRIBUTING, app AGENTS, app Mix aliases, example Makefile/package.json and UI-AUTOMATION. This mapping did not execute tests.

```sh
# From scrypath_ops/, with documented Postgres/environment prepared:
MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors test/scrypath_ops_web/live/failed_sync_live_test.exs test/scrypath_ops_web/live/sync_drift_live_test.exs
mix precommit

# From repository root:
mix verify.ops_ui
make -C examples/scrypath_ecommerce contrast
make -C examples/scrypath_ecommerce verify-mounted

# Once shared CSS changes warrant the broader advisory matrix:
OPS_UI_LLM_JUDGE=0 OPS_UI_LLM_JUDGE_REQUIRED=0 make -C examples/scrypath_ecommerce verify-e2e

# From examples/scrypath_ecommerce/, only against a prepared disposable server:
npx playwright test e2e/operator.spec.ts --workers=1 --retries=0
npm run test:e2e:admin-shell -- --workers=1 --retries=0
npm run test:e2e:admin-contrast -- --workers=1 --retries=0
```

Do not use pass-with-no-tests, ignored failures, or a retry pass as clean proof. Local targeted tests require dependencies/services; canonical Docker mounted command owns isolation. UI-SPEC defines representative widths/themes/states; collect actual evidence without expanding to a Cartesian matrix. Existing screenshot inventory checks names/width only. No CI topology change or paid judge is needed. Final root checks and candidate/final-source closeout remain governed by CONTRIBUTING; commit completion tracking before final attestation.

## Metadata

**Search scope:** Already-inventoried Ops components/assets/LiveViews/tests, root recovery/Oban task seams, and example E2E controller/helpers/specs. Five pattern families; search stopped after concrete matches.
**Project context:** Root and Ops AGENTS read; no project skill directories discovered. Relevant local LiveView best-practices guidance consulted for URL ownership, service boundaries, async identity, and observable tests.
**Upstream:** 172-CONTEXT, 172-RESEARCH, 172-UI-SPEC and v1.42 UI-STRUCTURE/UI-SYSTEM/UI-AUTOMATION. UI-SPEC overrides defective historical behavior.
**Provenance:** Existing analogs verified tracked in the task worktree. Proposed helper names are explicitly marked new. Only this PATTERNS artifact was written.

## Execution update after Plan 02

Operator hooks now live in `scrypath_ops/assets/js/ops_hooks.js`, imported by both standalone `app.js` and the ecommerce host `assets/js/app.js`. Use this shared module for further lifecycle repairs; do not recreate a host copy. The modal layer is now 90 and the scoped `ops-modal` opening rule keeps the dialog focusable throughout its visibility transition. Earlier line-number analogs above describe the preimplementation source.
