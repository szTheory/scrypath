# Phase 118 Plan: Admin Screen UX Cleanup

**Status:** Complete
**Requirements:** SCREEN-01, SCREEN-02, VERIFY-01

## Tasks

- Apply the shared system to posture, failed sync, sync/drift, search/federation, and playbooks.
- Reorder search so running/inspecting is primary and playbook capture is post-run secondary.
- Split playbooks into clearer workspace/import/preview-run/manage sections.
- Preserve posture-first IA and bounded operator honesty.

## Verification

- `scrypath_ops` LiveView tests.
- Root `mix verify.opsui` when available.
- Ecommerce Playwright/admin smoke paths for mounted `/admin/search/*`.
