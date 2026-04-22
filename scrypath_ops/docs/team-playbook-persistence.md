# Team playbook persistence (v1.15)

This page is the **canonical operator story** for how shared **`playbook_format: 1`** JSON
lives on disk in **v1.15**. It matches **`config/runtime.exs`** and
**`ScrypathOps.Playbook.Store`**: there is **exactly one** mutating catalog source — the
configured workspace directory. There is **no** optional Ecto-backed playbook catalog in
Phase **63**; if that ever ships, it would be an **exclusive** mode with explicit
import/export boundaries (see **`.planning/phases/63-bounded-team-persistence-and-security-posture/63-CONTEXT.md`** decision **D-02**).

## Workspace layout

- The workspace root is an **absolute directory** on the host (or container) filesystem.
- Playbooks are **flat** `*.json` files in that directory **only** (no subdirectories for
  catalog files in this release). Basenames must satisfy **`Store.safe_basename?/1`**
  (no path segments; safe characters; ends in **`.json`**).
- OPSUI lists, reads, writes, renames, and deletes **only** under that root via basename APIs.

## Configuring the root (`SCRYPATH_OPS_PLAYBOOK_DIR`)

At release boot, **`config/runtime.exs`** evaluates **`SCRYPATH_OPS_PLAYBOOK_DIR`**:

- **`nil`** or **empty string** — `:playbook_workspace_dir` is **not** set. The app does
  **not** silently write under **`priv/`**; operators must set the env (or dev/test config)
  before using **`/ops/playbooks`** persistence.
- **Non-empty** — value is **trimmed**, then passed through **`Path.expand/1`** (relative
  paths expand against the **current working directory** at boot). The result is stored
  as **`config :scrypath_ops, :playbook_workspace_dir`**.

**Production guidance:** set **`SCRYPATH_OPS_PLAYBOOK_DIR`** to an **absolute** path
(e.g. **`/var/lib/scrypath_ops/playbooks`**) so behavior does not depend on release CWD.
Document the same path in runbooks and container specs.

## GitOps and review

- Treat playbook JSON like **config**: branch, PR, and review. Prefer small, focused diffs.
- **Merge conflicts** on a single file should be resolved like any JSON artifact — there is
  no server-side merge strategy inside **`scrypath_ops`**.
- **Secrets do not belong in playbooks.** The codec rejects secret-shaped keys under **`opts`**
  (see **`playbook-schema-v1.md`** — *Banned / secret keys*). Still assume **git history**
  is long-lived: never commit keys “temporarily”, even if validation would catch some shapes.

## Deploy patterns

Pick one primary pattern per environment:

| Pattern | When | Notes |
| --- | --- | --- |
| **Mounted checkout** | Dev / dogfood | Bind-mount a repo directory that already contains reviewed JSON. |
| **PVC / volume** | Kubernetes / VM | Mount a persistent volume at the configured absolute path; back up the volume. |
| **Image `COPY`** | Immutable releases | Bake known-good fixtures into the image **only** when updates ship with releases — not for day-to-day operator edits. |

## CI validation

Validate a directory of playbooks **without Meilisearch** or **`mix test`** coupling:

```bash
cd scrypath_ops
mix scrypath_ops.playbooks.validate /path/to/playbook/dir
```

The task reads **only** eligible **`*.json`** files **non-recursively** and runs
**`ScrypathOps.Playbook.V1.decode/1`** then **`validate/1`**. In-repo examples live under
**`examples/playbooks/`** (see **`mix scrypath_ops.playbooks.validate examples/playbooks`**).

## Further reading

- **[playbook-schema-v1.md](playbook-schema-v1.md)** — normative wire format, caps, banned keys.
- **[operator-ia.md](operator-ia.md)** — navigation and adoption; **securing `/ops`** is a **host** concern (see *Securing `/ops`* there).
- **v1.14 rationale (archived):** **`.planning/milestones/v1.14-REQUIREMENTS.md`** — **OPS-PB-03** portable JSON MVP.
