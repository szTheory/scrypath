# v1.49 milestone-end storybook review (Pause 2)

Started 2026-11-22. Storybook on `127.0.0.1:4013`, serving `main`. The review is still open: the
milestone audit, complete and cleanup steps wait for the maintainer's "ok".

| # | Date | Catalog entry, state, theme | Maintainer's words | Kind | Outcome |
|---|------|-----------------------------|--------------------|------|---------|
| 1 | 2026-11-23 | `primitives/ops_button`, light | "it shouldnt have a underline on hover... we should add a hover state... also shouldt we have a disabled state... is default the same as secondary?" | visual, coverage, API | Fixed, PR #182 |
| 2 | 2026-11-23 | `patterns/delete_confirmation`, light | "visually it looks broken" | visual | Fixed, PR #182 |
| 3 | 2026-11-23 | `patterns/retry_receipt`, `areas/failed_summary`, `areas/health_verdict`, `areas/recovery_status`, light | the left border is "a telltale sign of AI slop ... de-slop it with impeccable" | visual | Fixed, PR #182 |
| 4 | 2026-11-23 | catalog shell | "why is this weird black bg back... rounded corner card type thing agian. i dont want that!" | visual | Fixed, PR #183 |
| 5 | 2026-11-23 | Start here | "i dont want u to leak PII in our git commits or storybook" | privacy | Fixed, PR #184 |
| 6 | 2026-11-23 | not a story | AI/LLM diagnosis and guarded recovery through a CLI, "mark it as a GSD seed" | future scope | Planted, SEED-005 |
| 7 | 2026-11-25 | all of the former `surfaces/` tier | "why are we calling \"screens\" \"surfaces\" ... let's change that plz" | wording | Renamed to Screens |
| 8 | 2026-11-25 | former `jobs/` tier | "i prefer \"User flows\" or \"Flows\" for now" | wording | Renamed to Flows |
| 9 | 2026-11-25 | screen and flow stories | "it's showing code on the right but i really just want to see the actual screen there" | review ergonomics | Full width, code hidden for Screens and Flows |
| 10 | 2026-11-25 | pattern and area stories | "agreed with ur rec" (hide code there too; only primitives keep it) | review ergonomics | Full width, code hidden for everything but primitives |

## For v1.50 input

- SEED-005 is a candidate to weigh at milestone selection. It is not approved scope.
- Keep new catalog entries in the plain tier names (playbook C40).
