# Phase 129: Dark-theme brand-expression audit - Context

**Gathered:** 2026-06-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Enumerate and score **every dark surface** of the `scrypath_ops` admin UI against the
brand book's dark rules, and emit **one** ranked, fix-class-tagged backlog
(`129-DARK-AUDIT-BACKLOG.md`) with a systemic-vs-per-screen split and the `#1B2230`
surface-2 ramp gap as **finding #1**.

**This is an audit/analysis phase — NO code, token, CSS, or component changes.** The
sole deliverable is the backlog markdown. It is the **single source of truth driving
phases 130–135** (token ramp, glow/copper, AA remediation, dark motion, per-screen polish).

It consumes three already-existing substrates:
1. **`128-CONTRAST-REPORT.md`** — the committed, pre-seeded contrast baseline (108 AA
   violations, 3 systemic clusters, `scope`/`fix_class` already tagged, `#1B2230` ramp
   collapse already flagged as finding #1). This is the **objective AA spine**.
2. **The 40-shot screenshot matrix** (`.tmp/admin-screenshots/`, 6 screens × light/dark ×
   mobile 390/desktop 1440 × seed scenarios) — the visual substrate for the brand-expression
   dimensions axe cannot measure.
3. **`prompts/scrypath-brand-book.md`** — the dark-signature rules being scored against.

**Out of scope:** Any fix — the dark surface-2 ramp token, glow/copper recipes, AA
remediation, motion, per-screen polish. Those are phases 130–135. Phase 129 only *names,
scores, ranks, and routes* the work. (Phase 97 scope guard holds; UI-polish-only milestone.)

</domain>

<decisions>
## Implementation Decisions

Four methodological gray areas were discussed. Calibration: technical owner, opinionated →
decisive single recommendations grounded in the in-repo `120-AUDIT-BACKLOG.md` precedent and
the pre-seeded `128-CONTRAST-REPORT.md` (no external research — the answers are determined by
our own artifacts). All four locked to the recommended option.

### ① Scoring dimension model — Fresh dark-specific DD1–DD6 set, scored 0–3
- **D-01:** Define **6 dark-specific scoring dimensions**, mapped 1:1 to the brand book's
  named dark rules (the exact six DARKAUDIT-01 enumerates):
  - **DD1** — 4-step midnight ramp adherence (does the surface honor the `#0C0F14 → #141923 →
    #1B2230 → …` elevation steps, or does "raised" flatten?)
  - **DD2** — 65/20/10/5 neutral/structure/violet/copper ratio adherence
  - **DD3** — quiet-vs-loud glow (restrained, low-spread — never text/background floods)
  - **DD4** — ambient-shadow **plus** border depth (dark surfaces should read as seated, not
    flat fills)
  - **DD5** — path-line glow restraint (the violet route/diagram-line glow stays reserved)
  - **DD6** — AA pass/fail (objective, **fed directly from `128-CONTRAST-REPORT.md`** — not
    re-derived)
- **D-02:** **0–3 per-dimension score (0 = worst)**, mirroring `120-AUDIT-BACKLOG.md`'s scale,
  so the backlog's Score column is directly comparable to the v1.33 precedent.
- **Rationale:** DARKAUDIT-01 literally enumerates these six dimensions; a fresh DD-set keeps
  the dark scoring legible per-dimension instead of collapsing it into 120's single D5-brand
  column. DD6 stays objective by reusing 128.

### ② Substrate strategy — Promote 128 + brand overlay; read BOTH viewports incl. desktop
- **D-03:** **Promote, don't re-derive, the objective AA spine.** Carry forward the 128
  report's AA findings (→ DD6), including its pre-tagged `scope` (systemic ≥3 screens) and
  `fix_class`, and its three named clusters (`.leading-4` ramp collapse 1.08:1; dark form
  inputs 1.19:1; `.bg-primary` near-miss 4.3:1). Do **not** independently re-count AA — that
  would risk diverging from the committed report.
- **D-04:** **Overlay the brand-expression dimensions (DD1–DD5)** axe cannot see, by reading
  the 40-shot screenshot matrix and scoring each dark touchpoint against the brand book.
- **D-05:** **Read DESKTOP shots, not just the mobile AA-fail set.** The 128 report notes all
  *AA* failures occur at mobile 390 (desktop passed) — but brand-fidelity gaps (ramp flatness,
  missing ambient depth, absent copper, loud/absent glow) are **visible on desktop where AA
  passes**. Both viewports (390 + 1440) are in scope for DD1–DD5 scoring; DD6 inherits 128's
  per-viewport AA result.
- **Rationale:** 128 was explicitly built and pre-seeded *to be promoted here* — that is its
  stated purpose. Brand expression is primarily a desktop visual concern, so a mobile-only walk
  would miss most DD1–DD5 findings.

### ③ Ranking & severity model — AA-fail = blocker; brand by blast-radius; 120's buckets
- **D-06:** **Severity buckets mirror `120-AUDIT-BACKLOG.md` exactly: blocker / structural /
  polish.**
- **D-07:** **Any AA fail (DD6) → automatic `blocker`.** (Objective, non-negotiable — AA is the
  milestone's hard gate.)
- **D-08:** **Brand-fidelity gaps (DD1–DD5) graded by blast-radius:** systemic (same
  token/recipe failing on ≥3 screens) → `structural`; single-screen → `polish`.
- **D-09:** **Sort key:** `severity (blocker→structural→polish)` → `scope (systemic first)` →
  `score (0 worst first)` → `dimension (DD1…DD6)`.
- **D-10:** **`#1B2230` surface-2 ramp gap is finding #1 by construction** — it is
  simultaneously a systemic AA-fail blocker (the `.leading-4` 1.08:1 cluster) AND a DD1 (ramp)
  + DD4 (depth) brand violation, so it sorts to the top under D-09 naturally. The backlog must
  state this explicitly as #1.
- **Rationale:** Keeps the format the requirement says to mirror; lets objective AA drive
  blocker status while subjective brand scoring is ranked by reach, not by a fragile combined
  number.

### ④ Phase-routing column — BOTH a Phase column (130–135) and a requirement tag
- **D-11:** Every finding carries **two routing fields**:
  - **`Phase`** — the target downstream phase (130–135), mirroring 120's Phase column.
  - **`Req`** — the requirement it satisfies: `DARKTOKEN-01` (130) / `GLOW-01` (131) /
    `COPPER-01` (131) / `A11Y-TOKEN-01` (132) / `DARKMOTION-01` (133) / `SCREEN-DARK-01` (134).
- **D-12:** The req→phase map **already exists** in `REQUIREMENTS.md` §13 (the traceability
  table) and the ROADMAP phase list — use it as the authority; do not invent a new mapping.
- **D-13:** **Honor the 128 report's pre-mapped cluster routing** as the starting point: the
  `.leading-4` ramp collapse + dark form inputs route to 130/132 (DARKTOKEN-01 / A11Y-TOKEN-01);
  the `.bg-primary` near-miss to 132.
- **Rationale:** The dual field makes this genuinely "the single source for 130–135" — a
  planner opening any downstream phase can filter the backlog by either `Phase` or `Req`.

### Backlog structure (locked by the above + the 120 precedent)
- **Mirror `120-AUDIT-BACKLOG.md` exactly:** YAML/metadata header (generated date, inputs,
  method), an **Executive summary** (total findings by severity + by fix-class + systemic
  promotion count), a **Ranked consolidated backlog** in three severity tables
  (Blockers / Structural / Polish), then a **Systemic cluster analysis** section, and a
  **Prioritized fix list** for phases 130–135.
- **Columns** (per finding): `ID` · `Alt` (element/component/page) · `Touchpoint` · `Dim`
  (DD1–DD6) · `Score` (0–3) · `Sev` · `Scope` (systemic/per-screen) · `Evidence` (screenshot
  slug `NN-screen--theme--viewport--state` + file:line + 128-report ref) · `Proposed fix` ·
  `Fix-class` (token/component/screen/motion/seed) · `Phase` · `Req`.
- **`fix_class` vocabulary** carries over from 120 / the 128 schema:
  `token | component | screen | motion | seed`.

### Claude's Discretion
- The exact finding IDs/numbering scheme, the precise per-touchpoint enumeration list (within
  the 6-screen × dark-state matrix), the wording of `Proposed fix` cells, and whether to add a
  short "Plan-hypothesis check" section like 120 did — left to the researcher/planner, provided
  the locked dimensions, scoring scale, ranking rule, routing fields, and the
  finding-#1 anchor hold.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope & requirements
- `.planning/ROADMAP.md` §"Phase 129" — goal, success criteria, `[S] [R]` tags.
- `.planning/REQUIREMENTS.md` → **DARKAUDIT-01** (the requirement this phase closes) and §13
  traceability table (the req→phase routing authority for the `Phase`/`Req` columns:
  DARKTOKEN-01→130, GLOW-01/COPPER-01→131, A11Y-TOKEN-01→132, DARKMOTION-01→133,
  SCREEN-DARK-01→134).
- `~/.claude/plans/v1-33-admin-ui-deep-tower.md` — the owner-approved v1.34 source plan.

### Substrate the audit consumes (the three inputs)
- `.planning/phases/128-contrast-gate-harness-dark-seed-coverage-s-g/128-CONTRAST-REPORT.md` —
  **the objective AA spine.** 108 AA violations, 3 systemic clusters (`.leading-4` 1.08:1 ramp
  collapse; dark form inputs 1.19:1; `.bg-primary` 4.3:1 near-miss), pre-tagged `scope`/
  `fix_class`, `#1B2230` flagged as finding #1, prioritized fix list mapping clusters to
  130–132. **Promote these — do not re-derive AA.**
- `.tmp/admin-screenshots/` — the 40-shot matrix (6 screens × light/dark × mobile 390/desktop
  1440 × seed scenarios). Visual substrate for DD1–DD5 brand scoring. Slug convention:
  `NN-screen--theme--viewport--state`.
- `prompts/scrypath-brand-book.md` — the dark-signature rules: 4-step midnight ramp
  (`#0C0F14`/`#141923`/`#1B2230`/…), 65/20/10/5 ratio, "quiet glow not loud," "faint ambient
  shadow plus border," restrained path-line glow, Paper-on-dark typography, copper-as-5%-accent,
  AA/AAA targets. The scoring rubric for DD1–DD6.

### Format to mirror
- `.planning/milestones/v1.33-phases/120-per-touchpoint-audit/120-AUDIT-BACKLOG.md` — the
  47-finding ranked backlog. **Mirror its structure exactly:** metadata header, executive
  summary, three severity tables (blocker/structural/polish), systemic cluster section,
  prioritized fix list, the Score(0–3)/Sev/Fix-class/Phase column layout.

### Tokens / surfaces being audited (read-only here)
- `scrypath_ops/assets/css/app.css` — the two daisyUI theme blocks, the dark `@custom-variant`,
  the `color-mix(... base-content N%, transparent)` muted patterns, the `prefers-color-scheme`
  system branches. Where DD-findings cite `file:line` evidence.
- `scrypath_ops/assets/css/DESIGN-TOKENS.md` — current token doc (the elevation/ramp tokens
  whose gap DD1 measures).
- `scrypath_ops/lib/scrypath_ops/components/ops_ui.ex` — the `.ops-*` components rendered on
  each dark surface (touchpoint citations).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`128-CONTRAST-REPORT.md` (committed, mineable):** the unified `scrypath.contrast.v1` schema
  already carries `scope`, `fix_class`, severity, and the systemic-cluster analysis. The audit
  **promotes** these straight into the DD6 / Sev / Fix-class / Scope columns rather than
  recomputing them.
- **`120-AUDIT-BACKLOG.md`:** a complete worked example of the exact output format, including
  the executive-summary phrasing, three-table severity split, systemic promotion logic
  (≥3 screens), and per-finding Evidence/Proposed-fix/Fix-class/Phase columns. Clone its shape.
- **40-shot screenshot matrix:** the visual ground truth for DD1–DD5; the `NN-screen--theme--
  viewport--state` slug is the Evidence citation key (ties findings to a specific PNG).

### Established Patterns
- **Evidence discipline (v1.33):** raw run artifacts gitignored under `test-results/` / `.tmp/`;
  the **curated audit markdown is committed** into the phase dir. `129-DARK-AUDIT-BACKLOG.md`
  follows this — it is committed, diffable evidence, like `120-AUDIT-BACKLOG.md` and
  `128-CONTRAST-REPORT.md` before it.
- **Systemic promotion rule:** a `(selector|token_pair)` failing on **≥3 distinct screens** →
  `scope: systemic` → token/component fix. Inherited from both 120 and the 128 schema (D-19).
- **Severity = objective + subjective fused:** AA (DD6, from 128) drives `blocker`; brand
  dimensions (DD1–DD5, from screenshots) drive `structural`/`polish` by reach.

### Integration Points
- The backlog is the **read interface** for phases 130 (DARKTOKEN), 131 (GLOW/COPPER), 132
  (A11Y-TOKEN), 133 (DARKMOTION), 134 (SCREEN-DARK). Each downstream phase filters by its
  `Phase`/`Req` value.
- DD6 ← `128-CONTRAST-REPORT.md`; DD1–DD5 ← screenshots + brand book. No new tooling — this is
  a read-and-write-markdown phase.

</code_context>

<specifics>
## Specific Ideas

- Owner wants the **decisive, "don't make me think" path** (consistent with the Phase 128
  pattern): recommendations grounded in our own artifacts, not external research, since the 120
  precedent + 128 substrate + brand book fully determine the methodology. All four gray areas
  locked to the recommended option in a single pass.
- The audit's value is **completeness + promotion**, not novelty: it must capture every brand
  dark gap the contrast harness is blind to (glow, copper, ramp flatness, ambient depth, ratio)
  while not re-litigating the objective AA numbers 128 already proved.
- `#1B2230` surface-2 ramp gap as **finding #1** is a hard requirement, satisfied structurally
  by the ranking rule (it's a systemic AA blocker + DD1/DD4 violation).

</specifics>

<deferred>
## Deferred Ideas

- **Any actual fix** — the dark surface-2 ramp token, glow/copper recipes, AA remediation,
  motion tuning, per-screen polish — is correctly downstream (phases 130–135), not scope creep
  into this audit-only phase.
- **AAA-body remediation** — 128 reported 12 light-theme AAA advisory candidates; AAA is the
  milestone's advisory (not gate) target. The audit may note AAA-body status, but remediation
  is a phase-132 concern.
- **Light-theme brand polish** — v1.34's focus is dark-signature; the few light muted-text
  near-misses (`.ops-text-meta` 3.9:1 etc.) are tracked in 128 and addressed in 132, not
  re-audited here.

None of the above is scope creep into Phase 129 — they are the downstream phases this backlog
feeds.

</deferred>

---

*Phase: 129-dark-theme-brand-expression-audit*
*Context gathered: 2026-06-04*
