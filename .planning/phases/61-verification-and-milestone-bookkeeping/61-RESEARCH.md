# Phase 61 research — Verification and milestone bookkeeping

**Role:** `gsd-phase-researcher`  
**Milestone:** v1.14 (final phase before close)  
**Requirement IDs:** **OPS-PB-05**, **SHIP-01**  
**Question answered:** What do you need to know to **plan** this phase well?

---

## 1. What Phase 61 is (and is not)

Phase 61 is a **closure gate**, not a feature phase. It exists to:

1. Prove **OPS-PB-05**: playbook operator flows are **automatically** covered on the **stub adapter** path (no live Meilisearch in default CI), and **`mix verify.opsui`** stays the documented maintainer entry that mirrors the **`scrypath-ops`** CI job.
2. Prove **SHIP-01**: planning truth (**`MILESTONES.md`**, **`PROJECT.md` *Current State***, **`ROADMAP.md`**) matches shipped **v1.14** outcomes and the published Hex line where the milestone narrative claims it; **`REQUIREMENTS.md`** traceability rows show **Complete** for everything that actually merged.

It is **not** the place to widen Tier C CI (Playwright-on-all-flows, Meilisearch-in-OPSUI) unless research in a later milestone explicitly reopens that.

---

## 2. Current repo facts (baseline for planning)

### 2.1 `mix verify.opsui` (root)

- Implemented in **`lib/mix/tasks/verify.opsui.ex`**: `cd scrypath_ops`, non-interactive `mix deps.get` (`printf 'n\n'` pipe), `CI=true`, then **`mix test`**. No Meilisearch service; Postgres-backed **`scrypath_ops`** tests as configured in **`scrypath_ops/config/test.exs`**.
- **README.md** already surfaces **`mix verify.opsui`** with a pointer to **CONTRIBUTING.md** for the CI matrix.
- **CONTRIBUTING.md** § Verification documents **`mix verify.opsui`** and ties it to **`scrypath-ops-path-check` / `scrypath-ops`** with the same `cd scrypath_ops && mix deps.get && mix test` ordering as **`.github/workflows/ci.yml`**.

**Planning implication:** If Phase 61 work **changes** the task (new env vars, extra steps, optional flags, different cwd), you **must** update **README** / **CONTRIBUTING** in the same change set. **`test/scrypath/docs_contract_test.exs`** enforces string ordering and content overlap between CONTRIBUTING, **`verify.opsui.ex`**, and **`ci.yml`** (Phase 53 contracts). Expect to extend **`docs_contract_test`** only if you add new **stable** phrases or ordering constraints worth locking.

### 2.2 CI “default verify path”

From **`.github/workflows/ci.yml`**:

| Concern | Job | Command shape |
|--------|-----|----------------|
| Fast PR matrix | **`test`** | `mix compile --warnings-as-errors` then `mix test --exclude integration --include requires_clean_workspace` |
| Maintainer gate | **`quality`** | format, `mix verify.workspace_clean`, Credo, Dialyzer, docs, `hex.audit`, then **`mix verify.phase11`** … **`mix verify.phase43`** (no **`verify.opsui`** here) |
| OPSUI | **`scrypath-ops`** (gated) | `cd scrypath_ops && mix deps.get && mix test` with Postgres service |

**Path gate:** **`scrypath-ops-path-check`** runs **`scrypath-ops`** on every push to **`main`**, and on PRs only when paths under `scrypath_ops/`, `lib/`, root **`mix.exs` / `mix.lock`**, or **`scrypath_ops/mix.lock`** change.

**Planning implication:** “CI green for default verify path” in roadmap language maps to: **(a)** PRs that touch gated paths still get **`scrypath-ops`** green; **(b)** always-on **`test`** + **`quality`** stay green. Phase 61 does **not** require adding **`verify.opsui`** to **`quality`** unless you explicitly decide to (would duplicate work already done in **`scrypath-ops`**; default is **no**).

### 2.3 Stub adapter and playbook tests today

- **`scrypath_ops/test/support/search_playground_stub_adapter.ex`**: **`ScrypathOps.SearchPlayground.Adapter`** behaviour; **`search/3`** and **`search_many/2`** without network; variants via **`:search_stub_variant`** (`:ok`, `:partial`, `:merge`, `:hard_error`).
- **`scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs`**: Uses **`SearchPlaygroundStubAdapter`** in **`setup`**. Covers:
  - mount honesty copy;
  - **paste import** → preview marker;
  - **run** after import → success flash (“Run finished”).
- **`scrypath_ops/test/scrypath_ops/playbook/runner_test.exs`**: **`Runner.run_validated/1`** against stub for **`search`** and **`search_many`** shapes (unit-level).
- **`scrypath_ops/test/scrypath_ops/playbook/store_test.exs`**: Filesystem **`Store`** save/list/read/delete (unit-level, temp dir — **not** the LiveView **save → list → load** loop).

**Gap vs OPS-PB-05 wording (“save/load/run”):** LiveView tests **do not yet** exercise **`phx-submit="save"`**, **`phx-click="load"`**, or list refresh after a save. Those events exist in **`playbook_live.ex`** (`save`, `load`, `refresh_list`, etc.). **OPS-PB-05** is plausibly **not fully satisfied** until at least one **integration-style** LiveView test (or equivalent ConnCase + LiveViewTest) proves **save → appears in list → load → run** on the stub path (and ideally one **`search_many`** playbook path, since that is a first-class mode).

**Planning implication:** Plan **1–2** focused **`PlaybookLiveTest`** cases (or split files if size grows): stable **`data-testid`** hooks if needed; use **`config/test.exs`** **`playbook_workspace_dir`** (already partitioned by **`MIX_TEST_PARTITION`**) so saves do not leak across tests.

### 2.4 Related tests (context only)

- **`posture_live_test.exs`**: Fake Meilisearch client — **not** the search playground stub — still validates posture JTBD without live Meilisearch.
- **`operator_ia_contract_test.exs`**: Router + **`operator-ia.md`** alignment includes **`/ops/playbooks`** (“Saved playbooks”).

---

## 3. SHIP-01 — Milestone bookkeeping and traceability

### 3.1 Known planning drift (fix during Phase 61)

These files are **logically inconsistent** with **`.planning/STATE.md`** (which records Phases **58–60** executed as of **2026-04-22**):

| Artifact | Issue |
|----------|--------|
| **`.planning/REQUIREMENTS.md`** | Traceability table still marks **LIB-01..03**, **OPS-PB-02**, **OPS-PB-04** as **Pending**; body checkboxes for some items still `[ ]` while Phase 57 **EVID-01** is `[x]`. |
| **`.planning/PROJECT.md` *Current State*** | Footer still says “next **Phase 60**” despite Phase 60 narrative in **STATE**. |
| **`.planning/MILESTONES.md`** | Shipped milestone narratives exist through **v1.13**; the summary **table** at the file tail ends at **`v1.8`** — there is **no** row yet for **v1.9–v1.14** in that table (SHIP-01 may expect either table extension or explicit “in progress” section for **v1.14** per your house style). |
| **`.planning/ROADMAP.md`** | Phase **61** remains unchecked until this phase completes (expected). |

**SHIP-01** explicitly requires **agreement** across **MILESTONES**, **PROJECT**, **ROADMAP** milestone list, and **Hex** line **where the narrative states a current published version**. Today **README** / **PROJECT** cite **`scrypath 0.3.4`** on Hex; root **`mix.exs`** must match for “checkout truth” (Phase 55 pattern).

**Planning implication:** Treat **REQUIREMENTS.md** as the **authoritative closure list**: for each **v1.14** row, set **Status** to **Complete** with the **correct phase** column (e.g. **LIB-*** → Phase **58**, **OPS-PB-02/04** → Phase **60**, **OPS-PB-05/SHIP-01** → Phase **61**) once implementation is merged. Align body checkboxes with the table so contributors are not misled.

### 3.2 `/gsd-complete-milestone` readiness

Per **`.planning/MILESTONES.md`** historical notes, **`gsd-sdk query milestone.complete`** has failed before (“version required for phases archive”); **v1.10–v1.13** used **manual** archive steps. **Plan** for the same **manual** path: **`milestones/v1.14-{ROADMAP,REQUIREMENTS}.md`**, optional **`MILESTONE-AUDIT`**, **`ROADMAP`** collapse, **`git rm`** or archive of root **`REQUIREMENTS.md`** if that is your established pattern — **confirm against `gsd-complete-milestone` skill** at execute time.

---

## 4. Doc-contract and Nyquist invariants (do not break)

- **`test/scrypath/docs_contract_test.exs`** reads **`.planning/STATE.md`**, **`.planning/REQUIREMENTS.md`** (or fallbacks), **`.planning/MILESTONES.md`**, **`.planning/milestones/v1.6-MILESTONE-AUDIT.md`**, **`.planning/PROJECT.md`** for **AUDT-01** / Phase 32 strings (artifact name pointers, **AUDT-01** row, “gap closure 33”, audit scores).
- Published markdown hygiene forbids leaking **VRFY-NN**, **ADPT-NN**, etc., into adopter-facing docs — keep requirement IDs in **`.planning/`** and **CONTRIBUTING** as today.

Any bulk edit to **REQUIREMENTS** / **STATE** / **MILESTONES** should run **`mix test test/scrypath/docs_contract_test.exs`** early.

---

## 5. Risks and decisions for PLAN.md

| Topic | Decision / risk |
|-------|------------------|
| **Minimal OPS-PB-05** | Is “run + unit Store + Runner” enough, or does the requirement text mandate **LiveView save/load**? Research recommends **LiveView-level save/load** to match operator JTBD and roadmap wording. |
| **`search_many` playbook** | Runner tests cover it; LiveView does not. One **`search_many`** paste + run (and optionally save) test reduces federation-shaped regressions. |
| **Hex bump** | v1.14 may ship **in-repo only** (like several prior OPSUI milestones) or with a **Hex** release — **SHIP-01** should state which and align **PROJECT** / **README** / **ROADMAP** / **`mix.exs`**. |
| **CI duplication** | Optionally document that **`quality`** does not run **`verify.opsui`** but **`scrypath-ops`** does when gated — only if contributors were confused (avoid doc churn unless needed). |

---

## 6. Deliverables checklist (for PLAN → execute)

- [ ] **`PlaybookLiveTest`** (or equivalent): **save**, **load from list**, **run** on **`SearchPlaygroundStubAdapter`**; consider **`search_many`** variant.
- [ ] **`mix verify.opsui`** behaviour unchanged **or** docs + **`docs_contract_test`** updated if it changes.
- [ ] **`.github/workflows/ci.yml`**: no accidental regression to **`test`** / **`quality`** / **`scrypath-ops`** ordering.
- [ ] **`.planning/REQUIREMENTS.md`**: traceability table + body checkboxes **Complete** for all shipped **v1.14** IDs; **OPS-PB-05** / **SHIP-01** → Phase **61**.
- [ ] **`.planning/PROJECT.md`**, **`.planning/MILESTONES.md`**, **`.planning/ROADMAP.md`**: **v1.14** narrative, phase checkboxes, Hex line, and “current focus” consistent with **STATE**.
- [ ] Evidence: note **`mix test`** (root) and **`mix verify.opsui`** (root) runs in phase **61-VERIFICATION.md** or summary artifact per project habit.

---

## Validation Architecture

This milestone is verified with **ExUnit** at two layers (core repo vs **`scrypath_ops`**) plus **Mix orchestration tasks** that mirror CI. There is **no** separate Nyquist binary; “Nyquist” here means **doc-contract invariants** and **maintainer sampling discipline** wired into **`docs_contract_test.exs`** and phase verify composers.

### ExUnit / Mix strategy

- **Core package (`scrypath`):** Default local and PR loop is **`mix test --exclude integration`** (see **CONTRIBUTING.md**). The always-on CI **`test`** job uses the same shape with **`--include requires_clean_workspace`**. Doc and planning truth are guarded by **`mix test test/scrypath/docs_contract_test.exs`** (also included inside **`mix verify.phase11`** and other **`verify.phase*`** gates that list **`docs_contract_test.exs`**).
- **`scrypath_ops`:** Full app tests run via **`cd scrypath_ops && mix test`** — locally mirrored by **`mix verify.opsui`** from the **repository root**. Tests use **Postgres** (CI services + local **`PGPORT`**), **`SearchPlaygroundStubAdapter`** for no-Meilisearch search playground paths, and fakes where posture tests avoid network (**`PostureFakeClient`** pattern).

### Sampling (after task / after wave)

- **After each implementation task (plan slice):** Run the **narrowest** test file you touched (e.g. **`mix test scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs`** inside **`scrypath_ops/`**, or from root with `cd` — match developer habit in **CONTRIBUTING**). For planning doc edits, run **`mix test test/scrypath/docs_contract_test.exs`**.
- **After a wave of tasks (e.g. all tests + planning):** From repo root: **`mix test --exclude integration`** plus **`mix verify.opsui`**. Before calling the milestone “merge-ready”, align with CI: at least **`mix compile --warnings-as-errors`** and the **`quality`**-equivalent verify chain locally or on a draft PR.

### Commands (authoritative)

| Command | Working directory | Proves |
|---------|-------------------|--------|
| **`mix test`** / **`mix test --exclude integration`** | Repo root | Core library + **`docs_contract_test`** in default CI **`test`** job path. |
| **`mix verify.opsui`** | Repo root | Same sequence as **`scrypath-ops`** CI job: **`scrypath_ops`** deps + full **`scrypath_ops`** ExUnit suite (**OPS-PB-05** stub path + playbook LiveViews under test config). |

### How plans prove **OPS-PB-05** and **SHIP-01**

- **OPS-PB-05:** A plan item adds or extends **`scrypath_ops`** tests so **save / load / run** (stub adapter) are **observable** in CI without Meilisearch; **`mix verify.opsui`** remains documented as the local mirror; if **`verify.opsui`** gains steps, a paired plan item updates **README** / **CONTRIBUTING** and, if needed, **`docs_contract_test`** pins.
- **SHIP-01:** A dedicated bookkeeping plan item updates **`.planning/REQUIREMENTS.md`** traceability (all **v1.14** rows **Complete** with correct phase columns), syncs **`.planning/PROJECT.md` *Current State***, **`.planning/MILESTONES.md`**, and **`.planning/ROADMAP.md`** phase **61** checkbox / milestone summary, and confirms **CI** **`test`** + **`quality`** (and gated **`scrypath-ops`** when applicable) are green — producing merge evidence for **`/gsd-complete-milestone`**.

---

## 7. File index (research inputs)

| Path | Use |
|------|-----|
| `.planning/STATE.md` | Current phase pointer and decisions ledger |
| `.planning/ROADMAP.md` | Phase 61 success criteria text |
| `.planning/REQUIREMENTS.md` | **OPS-PB-05**, **SHIP-01** definitions + traceability table |
| `.planning/MILESTONES.md` | Close patterns + table gap for **v1.9+** |
| `.planning/PROJECT.md` | *Current State*, milestone framing, Hex line |
| `CONTRIBUTING.md` | Verify matrix, **`mix verify.opsui`**, CI job names |
| `README.md` | **`mix verify.opsui`** mention |
| `lib/mix/tasks/verify.opsui.ex` | Exact CI-parity shell |
| `test/scrypath/docs_contract_test.exs` | CONTRIBUTING ↔ CI ↔ **`verify.opsui`** contracts |
| `scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs` | Current playbook LiveView stub coverage |
| `scrypath_ops/test/support/search_playground_stub_adapter.ex` | Stub semantics |
| `.github/workflows/ci.yml` | **`test`**, **`quality`**, **`scrypath-ops`** |

---

*Research produced for Phase 61 planning — **2026-04-22**.*
