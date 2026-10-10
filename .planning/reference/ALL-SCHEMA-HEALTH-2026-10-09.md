# All-schema Search health — 2026-10-09

The maintainer found “Selected schema” misleading on Search health: there was no
selector, and the page displayed every schema. The URL selection was recovery
context rather than a filter. This follow-up aligns navigation and content with
the operator’s job instead of relabeling hidden state.

## Current decision

- Control Room answers whether search sync needs attention across all configured
  schemas. Search health identifies which schemas need attention and provides
  expandable diagnostic details. Neither overview has a selected schema or filter.
- Overview URLs carrying `schema` normalize to a local, unscoped URL with history
  replacement. Other query parameters survive; legacy `/posture` links go directly
  to unscoped `/health`. No URL value is converted to a module atom.
- Each schema’s recovery link chooses that exact schema on Failed sync work.
  Failed sync work and Sync and drift have real selectors and scoped content.
  Their validated context remains intact through patches, history, reload, and
  authorization interruption/return. Invalid scoped selections still stop actions.
- Search health destinations are unscoped in sidebar, mobile drawer, palette, and
  Sync and drift handoffs, even when the current recovery workflow has a selection.
- Generic diagnostic “Next checks” and recovery footers are removed from the
  overview: they could open the default schema after the operator identified a
  different one. Setup next-step guidance remains when configuration is missing.

This supersedes the overview-target portion of Phase174 D-19 and its earlier UI
contract. Scoped recovery safeguards remain. Current DESIGN.md, operator IA, and
JTBD guide record the new flow; historical comps and closeout evidence are unchanged.
No framework, dependency, theme, palette, recovery permission, or mutation behavior
is added by this follow-up.

## Verification

Final app `mix precommit` and canonical root `mix verify.ops_ui` each passed
**282 tests + 2 doctests, zero failures**. Focused compilation/tests with warnings
as errors passed **83 tests**.

Final native Chromium coverage: **14 passing cases, retries disabled**. The
12-case journey/navigation output is preserved unchanged in
`ALL-SCHEMA-HEALTH-2026-10-09.final.browser.xml`:

- Eight overview/recovery journeys cover mounted and standalone entry points,
  1440px and 390px, and light/dark. They check old invalid bookmarks, preserved
  unrelated query data, all-schema rows, explicit row recovery, scoped selectors,
  Back/reload, sidebar/mobile/palette health destinations, and browser exceptions.
- Four focused cases cover refresh/reorder focus, mobile drawer keyboard return,
  mounted selector/palette updates, and standalone fixture selector/palette updates.
- Two additional cases passed against the same runtime source: unavailable,
  retained, unknown, empty and long evidence (`*.fixtures.browser.xml`), and pending
  refresh observation (`*.pending.browser.xml`). Stateful health fixture URLs now
  use canonical unscoped URLs; obsolete bookmark normalization has separate coverage.

The initial eight-case run passed before removing generic diagnostic next steps;
its output remains in `*.initial.browser.xml`. The first navigation run had four
failures, retained unchanged in `*.navigation-initial.browser.xml`: two palette
helper assertions still expected health to carry selection; a fixture test entered
a route absent from that fixture router; and a stateful refresh fixture advanced
through the old URL’s additional redirect observation. The helpers now assert
unscoped health, the mobile case starts on an actual scoped fixture route, and the
refresh fixture starts at its canonical URL. All four passed in the final run.
Earlier LiveView assertions expecting old scope/next-step behavior were updated;
failed local runs are retained in the external logs, not represented as passes.

One visual review of 16 captures (both pages, entries, widths, and themes) found the
remaining generic-next-step distraction. One confirmation batch of the final 16
captures showed the schema list following health and issue counts directly, with
no selected context or horizontal overflow. No further visual changes were needed.

## Runtime and boundaries

All five changed runtime files match both rebuilt preview containers by SHA-256:

| File | SHA-256 |
| --- | --- |
| `scrypath_ops/lib/scrypath_ops/operator_selection.ex` | `a8ef7741feab5c795b3591f3887fbd7032cda8a2e38546b6ca0ade09e164e1b9` |
| `scrypath_ops/lib/scrypath_ops_web/live/on_mount.ex` | `e41fd35aa9f41b17620616fc873ac7b0d653829bc8587c54d02644e853a5f9ff` |
| `scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex` | `e3fbd4222aaa7122076276ea78f48fffa52e656cc975eab2ac53b2a8ce877dd4` |
| `scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex` | `975d9362ff44082b36861c9c098c54397e814f88aadcca15038fcca497468eff` |
| `scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex` | `87264fbf1d719996cc979bebd7cf3f435a4c5a89fda27cc73c514a4988a5509e` |

Preview: <http://127.0.0.1:4014/admin/search/health>. Existing URLs with a schema
parameter work and normalize to this overview. Logs, full captures, and runtime
receipts remain under `/private/tmp/scrypath-phase173-20261006-155750/ui-overview-*`.
The retained preview database was not reseeded; browser checks were read-only.

The original 15 dirty paths, frozen Phase173 source at
`13ea88a9c18a7515f4ec5ae7deea0cdde4c22531`, and port4012 preview remain preserved.
Work stays on draft PR95, stacked on PR94. Phase175 is not started. No merge,
release, new closeout attestation, or dependency-advisory remediation is claimed.
Hosted evidence must be read for the final pushed SHA, not inherited from an older
head or from the historical Phase174 receipts.
