---
title: Triage current dependency-audit advisories
status: pending
priority: high
category: security-dependency
created: 2026-10-15
---

# Current dependency advisory follow-up

Unsuppressed advisory job from UI PR #106: https://github.com/szTheory/scrypath/actions/runs/38743007949. Required gates and Ops passed; dependency locks were unchanged by the UI work. This is a separate open security task, not a risk acceptance or a reopening of Phase 147's older completed remediation.

| Locked package | Advisory reported by the audit | Severity |
| --- | --- | --- |
| Bandit 1.12.5 | [EEF-CVE-2026-105659](https://osv.dev/vulnerability/EEF-CVE-2026-105659) | High |
| Cloak Ecto 1.3.0 | [EEF-CVE-2026-94206](https://osv.dev/vulnerability/EEF-CVE-2026-94206) | Medium |
| Decimal 3.1.1 | [EEF-CVE-2026-97853](https://osv.dev/vulnerability/EEF-CVE-2026-97853) | Medium |
| Cloak 1.1.4 | [EEF-CVE-2026-95105](https://osv.dev/vulnerability/EEF-CVE-2026-95105) | High |

Recheck the primary advisories, dependency graph ownership/exposure and available remediation before changing locks. Keep any eventual dependency update narrowly scoped and verify affected core/optional/example graphs and required CI. Do not suppress the audit, assume a fixed version or claim these are resolved from an older milestone receipt. The UI pass records these findings but does not authorize new dependency or architecture scope merely to clear an advisory lane.

Local job log: `/tmp/scrypath-followup-ci-failures.log`.
