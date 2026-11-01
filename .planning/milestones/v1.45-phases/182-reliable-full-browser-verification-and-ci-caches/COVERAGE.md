# API Coverage — GitHub Actions verification evidence

The detector fired on Docker GHA API/cache language. The phase also uses the existing GitHub Actions service through a narrow `gh` evidence collector; no product API, SDK, authentication product or public backend abstraction is added. Native BuildKit and Actions cache actions own the cache transport; the phase owns their configuration and factual evidence. All capabilities needed for this bounded integration are decided below.

| capability | decision | reason |
|---|---|---|
| Dispatch the existing ci.yml at the selected ref | INTEGRATE | Exact changed-source acceptance in 182-07/08 |
| List newly created workflow runs | INTEGRATE | Reject old or unrelated success |
| Read run and explicit attempt identity | INTEGRATE | Bind SHA/ref/event/run/attempt and retain earlier failures |
| Paginate attempt-specific jobs and steps | INTEGRATE | Raw outcome and total timing proof |
| Paginate run artifacts | INTEGRATE | Complete source-bound artifact inventory |
| Download selected artifacts and verify immutable digest | INTEGRATE | Reject corrupted or ambiguous proof |
| Read bounded build/cache/job logs | INTEGRATE | Actual restore/export and cold-run evidence |
| Native GHA v2 build cache import | INTEGRATE | Separate recipe scopes in 182-05 |
| Native GHA v2 build cache export | INTEGRATE | Trusted scheduled/manual full writer only |
| Native compatible Actions archive restore/save | INTEGRATE | Exact BEAM graph/runtime boundaries and run-local probes |
| Cancel/delete hosted runs or artifacts | OPT-OUT | Read/dispatch proof collection does not require destructive service mutation |
| Delete shared repository caches | OPT-OUT | D-16 explicitly requires run-local bypass/fresh namespaces |
| Publish images to a registry | OPT-OUT | D-12 explicitly requires local image load without publication |
| New required jobs or product API integrations | OPT-OUT | D-02/D-18 preserve phase and lane boundaries |

Collection/transport uses existing `gh`, Node built-ins and official actions; no application dependency or package install is proposed. Matrix coverage is a planning contract, not a successful hosted API or cache receipt.
