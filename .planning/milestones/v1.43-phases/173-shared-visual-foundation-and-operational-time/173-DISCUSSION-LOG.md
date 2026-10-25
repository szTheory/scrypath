# Phase 173: Shared Visual Foundation and Operational Time - Discussion Log

> **Audit trail only.** Downstream planning, research, and execution use CONTEXT.md. This log preserves delegation, alternatives, and synthesis rationale.

**Date:** 2026-10-06
**Areas discussed:** Neutral palette; status cues; quiet actions/theme control; operational time/copy feedback
**Method:** Three read-only GSD advisor researchers, two bounded follow-up comparisons, and a parent synthesis. No implementation, product test run, simulated reviewer approval, or broad ecosystem inventory.

## User's delegation

The initial discussion presented four areas for selection. The maintainer responded with a generic fan-out/research prompt and explicitly asked us to consider all listed areas plus relevant overlooked issues, use Impeccable where useful, synthesize recommendations, and automatically follow them. They prefer small, flat dependency trees and modest owned-code repetition over another dependency; justified dependencies remain possible.

Recommendations below were adopted under that delegation. The user did not individually answer a questionnaire or personally select each table row. Automatic recommendation adoption applies to this discussion; no `--auto`/`--chain` planning/execution flag or configuration was enabled.

## Neutral palette and accent balance

| Option | Benefits | Costs / adverse example | Selected |
| --- | --- | --- | --- |
| Restrained warm-neutral light and neutral dark continuity | Preserves identity and established hierarchy | Beige/yellow washes would recreate the rejected treatment; dim metadata still fails legibility | Yes, starting direction for comps |
| Cooler-neutral refinement | Crisp separation and technical neutrality | Broad palette changes may add churn without fixing a user task | Comp challenger only if materially useful |
| Preserve incumbent exact colors and decorative washes | Minimal token change | Reproduces explicitly rejected gradients/status outlines | No |

**Synthesis:** Keep identity, revise surfaces and semantic usage. Violet communicates interaction; copper is identity detail only. The advisor's initial wording grouped both as interaction accents; parent synthesis corrected that against the project contract. Exact values belong to representative light/dark comps before implementation.

**Guidance:** Carbon's [color foundations](https://www.carbondesignsystem.com/building-blocks/foundations/color/overview) and [status indicators](https://www.carbondesignsystem.com/building-blocks/core/patterns/status-indicators) inform layer and cue choices. Palette warmth is our project inference, not a prescribed standard.

## Warning, failure, and unknown cues

| Option | Benefits | Costs / adverse example | Selected |
| --- | --- | --- | --- |
| Plain text plus local icon | Calm and explicit for summaries/details | An overly quiet icon can hide failure among dense records | Yes for summaries and secondary facts |
| Compact semantic badge | Repeated schema signals scan consistently | Badge overload; warning-colored Unknown can imply confirmed failure | Yes for meaningful repeated status signals |
| Whole-record semantic fill/outline | Strong salience | Broad yellow warnings/green zeros dominate and falsely imply health | No |

**Adversarial disposition:** Keep unknown, unused, in-flight, and terminal failure distinct. A check failure is an observation failure, not a failed backend task. Keep counts attached to the affected signal; no zero-is-healthy or last-success-is-freshness inference. Existing classification stays intact; different observed dimensions may have different labels.

**Guidance:** Explicit text/shape supports non-color perception under [W3C Use of Color](https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html). [Atlassian lozenges](https://atlassian.design/components/lozenge) are a comparable compact status pattern, not a dependency or full styling template.

## Quiet actions and theme control

| Option | Benefits | Costs / adverse example | Selected |
| --- | --- | --- | --- |
| Existing native button group with visible labels | Reuses event wiring and familiar activation; avoids custom keyboard work | Three Tab stops; must synchronize selected and accessible state after patches | Yes |
| Native radio inputs styled as segments | Mutually exclusive semantics and native arrow navigation | Changes the existing keyboard model and checked-state integration | No for this phase |
| Icon-only theme choices | Compact | Less discoverable meaning, especially System | No as the default |
| Neutral quiet hover/press | Keeps common secondary actions recognizable and subordinate | Too little tonal difference can conceal affordance | Yes, with measured focus/state contrast |
| Accent-tinted quiet hover | Strong pointer response | Can resemble selection or compete with primary actions | No as the default |

**Adversarial disposition:** One chosen preference controls every selected cue. Effective appearance never selects an additional theme option. Guard storage; keep current-page fallback functional without promising blocked persistence. Preserve pre-paint, OS changes, cross-tab changes, and patch synchronization. Busy feedback retains nested icon/label; disabled explanations stay readable. New motion is unnecessary.

**Guidance:** [W3C Button Pattern](https://www.w3.org/WAI/ARIA/apg/patterns/button/) supports stable-labeled toggle state; [Radio Group Pattern](https://www.w3.org/WAI/ARIA/apg/patterns/radio/) informed the rejected alternative. [MDN localStorage](https://developer.mozilla.org/en-US/docs/Web/API/Window/localStorage) and [storage event](https://developer.mozilla.org/en-US/docs/Web/API/Window/storage_event) delimit persistence and cross-tab behavior. The least-change control choice is our inference.

## Operational time and copy feedback

| Option | Benefits | Costs / adverse example | Selected |
| --- | --- | --- | --- |
| Relative-first plus accessible exact UTC evidence | Easy age scanning; exact incident evidence remains available | Clock/render changes can produce misleading age unless tied to a snapshot | Yes |
| Absolute UTC first | Easy event comparison | Recreates timestamp density for routine schema scanning | Older/future timestamp fallback |
| Local time first | Familiar wall clock | Different operators see different times; DST/server/client ambiguity | No |
| Hover title as sole exact reveal | Little implementation | Keyboard/touch users cannot reliably access it | No |
| Dedicated copy plus selectable exact reveal | Clear task and manual fallback | Requires truthful asynchronous feedback in both delivery paths | Yes |

**Synthesis:** Just now / minutes / hours / days, with absolute UTC at seven days or for future values, calculated once for the observation. Keep source precision and offset in copied ISO. No-success-observed differs from unavailable or unused sources. Copy on explicit activation; success feedback follows resolved clipboard writing. Denied/unavailable feedback persists and exact text remains manually selectable. Checked never gets a copy control.

**Adversarial disposition:** Unrelated rerenders must not move relative time; failed refresh cannot re-date retained evidence; future timestamps are not negative ages or a diagnosed clock fault. The existing exact formatter truncates source precision, and standalone/mounted listeners swallow clipboard errors. These are implementation constraints to address, not fixes delivered by discussion.

**Guidance:** [MDN Clipboard writeText](https://developer.mozilla.org/en-US/docs/Web/API/Clipboard/writeText) documents asynchronous completion and denied/secure-context behavior. [W3C Status Messages](https://www.w3.org/WAI/WCAG22/Understanding/status-messages.html) informs polite outcome announcements; [Content on Hover or Focus](https://www.w3.org/WAI/WCAG22/Understanding/content-on-hover-or-focus.html) informs evidence access. [Atlassian date/time guidance](https://atlassian.design/foundations/content/date-time) provided comparative orientation. UTC, seven-day fallback, and four-second reuse are project decisions.

## Agent's Discretion and Research Stop Rule

Impeccable Operate supplied restrained task-first design guidance. The GSD UI contract will resolve exact values, icon/badge detail, and representative composition; the existing comp-first gate remains enabled. Existing internal components and browser/Elixir capabilities cover the recommended behavior; no new external dependency is justified. Further role expansion would repeat these decisions without changing them, so fan-out stopped after synthesis.

## Deferred Ideas and Evidence Limits

New timezone settings, ticking clocks, framework replacement, broad CI changes, and other workflow redesign were not folded into Phase 173. Preserve local source/design edits and preview data; do not repair the pre-existing Impeccable sidecar incidentally. Historical UI inventory findings are orientation, not new failures or passing evidence. This record completes discussion only; OPUX-09–OPUX-15 remain undelivered until implementation and phase verification.
