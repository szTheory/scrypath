# Phase 48 — Pattern map

**Purpose:** Closest analogs in-repo for planners and executors.

## Nav as data → layout

| New / changed | Analog | Notes |
|---------------|--------|------|
| `ScrypathOpsWeb.Nav` | `Router` `live_session :ops` | Router lists `live` routes; Nav returns ordered subset + labels for chrome only. |
| Ops shell nav | `layouts.ex` `def app(%{shell: :ops}` | Replace four `<li>` blocks with `for item <- Nav.primary()` — match existing **`~p`** / **`link`** patterns. |

## Contract tests

| Target | Analog | Notes |
|--------|--------|------|
| IA / router / doc | `scrypath_ops/test/scrypath_ops_web/operator_ia_contract_test.exs` | Already reads **`operator_ia.md`** and **`router.ex`** at compile time; extend for **`Nav`** order and labels. |

## Posture LiveView

| Target | Analog | Notes |
|--------|--------|------|
| Structured regions + assigns | `posture_live.ex` `render/1` | Add headline + next-check section using existing assigns; keep read-only semantics. |
| LiveView tests | Other ops LiveView tests under `scrypath_ops/test/scrypath_ops_web/live/` | Use **`Phoenix.LiveViewTest`** `live/2`, `has_element?/2` — grep sibling tests for conventions. |

## Mix tasks

| Target | Analog | Notes |
|--------|--------|------|
| Custom Mix task | Root **`lib/mix/tasks/`** (if any) or Phoenix default **`mix ecto.*`** patterns | Add **`scrypath_ops/lib/mix/tasks/scrypath_ops/check_nav_contract.ex`** (`Mix.Tasks.ScrypathOps.CheckNavContract` → **`mix scrypath_ops.check_nav_contract`**). |

---

## PATTERN MAPPING COMPLETE
