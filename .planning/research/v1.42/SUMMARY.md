# v1.42 existing UI evidence and direction

**Date:** 2026-10-03
**Baseline:** `3c83a58c9bc5af70a204957431ff66fd9db035de`, branch `ui/operator-admin-prep`.

The maintainer asked to see the current UI, make conventions/token/component use and domain language more consistent, and automate acceptance without routine human babysitting or recurring AI API cost. This updates the earlier narrow incident-only requirements proposal. Existing project evidence is the source of truth; a bounded comparison with mature first-party operational UIs informs pattern choices.

## Findings and implementation implications

- Preserve the existing shell, palette, and 48 shared `OpsUi` components. Desktop Control Room has a coherent hierarchy. No new theme, component framework, or wholesale CSS rewrite is justified.
- Fix shared keyboard/dialog/label/disabled-state gaps and action typography first. The catalog should document actual type and layering authority so future work does not reopen settled choices.
- Mobile Failed Sync puts six full-width summary cards and repeated instructions before the actual records. Use a compact reason summary and concise domain copy; keep the reason and supported recovery control visible per record.
- Preserve selected schema across recovery handoffs. Separate incident verification from advanced index promotion, enforce current promotion eligibility consistently, and report actual backend task state.
- Correct the proposed recovery proof: the existing fixture is intentionally unrecoverable, and retries retain original failure records. A valid browser journey needs new-work identity, terminal task success, expected index content, and an honest visible outcome. Historical successful tasks and generic existing documents cannot satisfy it.
- Reuse LiveView tests, token/contrast checks, required mounted browser lane, and advisory full screenshots. No new CI job or paid visual judge is necessary. Add meaningful behavior/geometry checks instead of brittle class/copy snapshots or a huge Cartesian matrix.

## Evidence inventory

| Evidence | Scope |
| --- | --- |
| [UI structure](UI-STRUCTURE.md) | Four personas, six surfaces, three loops, state/terminology inventory, source findings and mature pattern comparisons |
| [UI system](UI-SYSTEM.md) | 48 component inventory, actual token roles, accessible control gaps, observed mobile density and visual hypotheses |
| [UI automation](UI-AUTOMATION.md) | Current proof boundaries, deterministic recovery hazards, cost-aware coverage, CI placement and cleanup |
| `scrypath_ops/docs/operator-ia.md` | Existing route/persona/JTBD baseline; its universal-green incident closure needs refinement for retained history |
| `scrypath_ops/assets/css/DESIGN-TOKENS.md` | Shipped operator token baseline; update documented differences alongside actual fixes |

## Live baseline

Preview: `http://127.0.0.1:4012/admin/search`, isolated Compose project `scrypath-ui-v142`, bind-mounted from this worktree. All six surfaces captured at 1440px and 390px where applicable; Control Room also captured in dark mode. Captures are local review artifacts under `/private/tmp/scrypath-v142-review/`, outside tracked source. These are visual observations, not passing recovery tests or a full accessibility result.

The preview is retained for optional maintainer feedback. Automated seeded verification must use a separate disposable Compose project because seed endpoints reset the example database and indexes. Stop only this preview with `COMPOSE_PROJECT_NAME=scrypath-ui-v142 WEB_PORT=4012 docker compose -f compose.yaml -f compose.dev.yaml down` from `examples/scrypath_ecommerce`; retain volumes until feedback no longer needs the demo state.

## Durable default

See `reference/OPERATOR-UI-QUALITY.md` for future milestone defaults: establish a baseline, use shared components and coherent domain copy, automate recurring verification economically, record evidence and revisit triggers, and leave task-owned work clean.
