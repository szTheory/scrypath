# Phase 94: Verification Gate

**Goal**: All tenant-safety surfaces are regression-guarded by a single hermetic task that contributors and CI can run to confirm nothing has drifted
**Depends on**: Phase 93
**Requirements**: 
- **TNNT-05**: User can run `mix verify.phase94` to confirm that `guides/multitenancy.md` guide anchors, `tenant_field:` auto-merge behavior, `schema_capabilities/1` `:tenant` reflection, and `tenant_scope:` injection are all coherent and regression-guarded; gate is registered in the CI `quality` job and CONTRIBUTING guidance

**Success Criteria** (what must be TRUE):
  1. `mix verify.phase94` runs without errors and exercises guide anchor assertions, `tenant_field:` auto-merge behavior, `schema_capabilities/1` `:tenant` reflection, and `tenant_scope:` injection in a single hermetic pass
  2. `mix verify.phase94` is registered in the CI `quality` job so a pull request that breaks any tenant-safety contract fails CI
  3. CONTRIBUTING guidance references `mix verify.phase94` so contributors know the gate exists and how to run it
