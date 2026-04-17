---
title: "Release parity drift detected: scrypath {{ env.VERSION }}"
labels: ["area:release", "severity:drift"]
assignees: szTheory
---

`mix verify.release_parity {{ env.VERSION }}` detected a divergence between
the published Hex tarball and the git tag of the same version.

- Workflow run: {{ env.GITHUB_SERVER_URL }}/{{ env.GITHUB_REPOSITORY }}/actions/runs/{{ env.GITHUB_RUN_ID }}
- Version: {{ env.VERSION }}

Expand the workflow logs for the exact `only_in_git` and `only_in_hex` file lists.

See `.planning/milestones/v1.2-MILESTONE-AUDIT.md` for background on why this gate exists.
