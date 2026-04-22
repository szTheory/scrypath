# Phase 63 — Technical research

**Phase:** 63 — Bounded team persistence and security posture  
**Goal:** One explicit filesystem/GitOps persistence story (**OPS2-04**) with documented authority; security posture for shared playbooks (**OPS2-07**).

## Findings (planning-oriented)

### Persistence authority (OPS2-04)

- **Single writer:** `ScrypathOps.Playbook.Store` is the only mutating surface for workspace JSON; basename-only + `resolved_path/2` under expanded root.
- **Config precedence:** `scrypath_ops/config/runtime.exs` maps `SCRYPATH_OPS_PLAYBOOK_DIR` → `:playbook_workspace_dir` via `String.trim/1` + `Path.expand/1`. Empty/nil env leaves the app config key unset (no silent `priv/` writes) — this is the normative operator contract to document.
- **CONTEXT lock-in:** Phase 63 ships **(A) filesystem + GitOps docs only**; optional Ecto catalog is explicitly **out of scope** (defer to future phase with xor mode). Plans must not introduce DB catalog or dual-write.
- **Contributor verify path:** Root `mix verify.opsui` runs `scrypath_ops` tests with Postgres (`lib/mix/tasks/verify.opsui.ex`). A **directory JSON validator** should be a **separate** `mix scrypath_ops.*` task so CI/docs can validate fixture trees **without** implying a new default CI service (align with D-14: no Meilisearch; keep existing verify discipline).

### Security posture (OPS2-07)

- **`V1.validate/1`:** Pipeline starts with `assert_no_banned_keys_deep/1`, then format/mode/top-level keys. Fail-closed; no silent redaction on save/import paths (per CONTEXT D-07..D-08).
- **Banned keys:** `@banned_opt_keys` in `v1.ex` — `meilisearch_api_key`, `req_options`, `meilisearch_url`, `meilisearch_client`. Docs in `playbook-schema-v1.md` § “Banned / secret keys” must stay aligned.
- **Destructive UX:** `PlaybookLive` `confirm_delete` requires typed basename match before `Store.delete_workspace_file/2`; mismatch surfaces flash **"Confirmation must match the filename exactly."** — worth an explicit LV test if missing.
- **Threat documentation:** Add a compact threat slice to `playbook-schema-v1.md` (git history, secrets in `q`/`title`, host responsibility for `/ops` exposure) and link from `operator-ia.md` per CONTEXT D-10.

### Deliverable packaging

| Artifact | Role |
|----------|------|
| Canonical operator doc (new file or dedicated section) | Golden path: env, volume mounts, PR workflow, CI hook using new Mix task |
| `scrypath_ops/examples/playbooks/*.json` | Small valid `playbook_format: 1` files linked from README / adoption |
| `lib/mix/tasks/scrypath_ops/playbooks/validate*.ex` (name TBD in plan) | Walk directory, `V1.decode` + `V1.validate`, non-zero exit on first invalid file |
| ExUnit + optional fixtures under `test/fixtures/playbooks/` | Banned keys under nested `opts`, unknown keys, delete confirmation negative path |

### Pitfalls

- Do not register the new Mix task inside the **`test` alias** chain unless it is instant — keep **`scrypath_ops` test** alias behavior predictable (`check_nav_contract`, ecto, test).
- Example JSON paths must stay **stub-friendly** (no federation_weight surprises in default CI unless asserted).

## Validation Architecture

Executor sampling for Phase 63 should prove **docs ↔ code ↔ tests** stay aligned without widening default CI beyond today’s **`mix verify.opsui`** contract.

### Dimension 1 — Correctness

- `mix test` on touched modules (`v1_test`, `playbook_live_test`, new Mix task test if any) exits **0**.
- New Mix task: given a directory of JSON files, invalid file yields **non-zero** exit and stderr/stdout message containing basename.

### Dimension 2 — Regression safety

- Existing `Playbook.Store` traversal rules unchanged; no new union catalog APIs.

### Dimension 3 — Security / abuse

- Banned-key deep scan remains authoritative; new tests cover at least one nested `opts` path.
- Delete path cannot call `delete_workspace_file` when confirmation string ≠ pending basename (LV assertion on flash or catalog state).

### Dimension 4 — Operability

- Operator doc lists **`SCRYPATH_OPS_PLAYBOOK_DIR`**, absolute path recommendation for prod, and **one** authority story (no Ecto catalog in v1.15).

### Dimension 5 — Documentation drift

- `playbook-schema-v1.md` § Persistence matches CONTEXT D-01/D-15 (filesystem authority; Ecto explicitly future).
- README or adoption path links examples + validation task.

### Dimension 6 — Performance

- Directory validation task is O(files) with small fixture sets; acceptable for CI hooks on tens of files.

### Dimension 7 — Accessibility / UX (light)

- No mandatory UX change; if copy updates in LiveView flashes, keep existing DaisyUI/modal patterns.

### Dimension 8 — Nyquist / feedback latency

- After each implementation task: run scoped `mix test` paths listed in plans.
- Before phase verify-work: `mix verify.opsui` from repo root (unchanged contributor gate).

---

*Research for planning — Phase 63 — 2026-04-22*

## RESEARCH COMPLETE
