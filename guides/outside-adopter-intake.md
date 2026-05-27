# Outside-Adopter Intake

This guide is the single authority for outside-adopter attempts. If you are integrating Scrypath outside of the provided example app and encounter issues, or if you are running our defended proof path and it fails for you, follow these instructions to capture admissible evidence.

## The Defended Proof Path

Scrypath currently defends a specific Phoenix + Meilisearch proof path. This path lives in this repository as a runnable example.

Canonical routing before you submit evidence:

- Start from [`README.md`](../README.md) for the release-backed install and first-hop guide map.
- Use [`guides/support-and-compatibility.md`](support-and-compatibility.md) for the defended support and proof-boundary policy.
- Use this intake guide for admissibility classes and evidence submission requirements.

### Repo-clone versus Hex-package Boundary

- **Hex-package:** When you add `{:scrypath, "~> 0.3"}` to your `mix.exs`, you are consuming the library artifact. If you encounter issues here, we need to know your exact environment and integration steps.
- **Repo-clone:** The defended proof path is a repo-clone workflow. It tests Scrypath as a local `path:` dependency within a complete Phoenix application.

When you submit evidence, include either the exact Hex package version or the exact git ref/commit so maintainers can classify package versus branch-tip behavior without ambiguity.

### Maintainer Proof Command Family

We use two commands to verify our contracts and runtime posture:

- `mix verify.adopter`: The fast, auth-free, service-free path. It verifies support and readiness contracts.
- `mix verify.adopter --live`: The canonical live proof. It boots the `examples/phoenix_meilisearch` application and runs its tests against a real Meilisearch instance.

For live operational steps, environment variables, and repo-clone runbook detail, do not guess: follow the exact runbook in [`examples/phoenix_meilisearch/README.md`](../examples/phoenix_meilisearch/README.md).

## Runtime Assumptions

When we review outside-adopter evidence, we look at these assumptions:
- Are you within the supported Elixir/OTP range?
- Are you targeting the supported Meilisearch version?
- Are you using a supported sync mode?

## Admissibility Classes (A through D)

Evidence bundles are classified into one of four classes to determine how we respond:

- **Class A:** Exact failure on the defended repo-clone live proof. Highest priority.
- **Class B:** Hex-package integration failure within the explicitly supported runtime matrix.
- **Class C:** Integration attempt outside the supported runtime matrix (e.g. older OTP or different search backend). Will likely be closed as unsupported, but logged for future roadmap consideration.
- **Class D:** Incomplete evidence, missing context, or missing ordered commands. Returned for clarification.

## Evidence Findings and Review Rubric

When maintainers review an evidence bundle, they sort the outcome into one of four finding buckets:

1. **Bug in Scrypath:** The library failed its contract.
2. **Doc or Contract Gap:** The library behaved as intended, but the docs were missing or misleading.
3. **App-Side Error:** The integration steps in the host app were incorrect.
4. **Environment Failure:** The failure was caused by local OS, Docker, or port issues.

## Maintainer triage routing

Use the finding bucket to drive the next maintainer action:

- **Bug in Scrypath** -> open or route a bugfix issue with reproducible references from the evidence bundle.
- **Doc or Contract Gap** -> open a docs correction issue linked to the offending contract surface.
- **App-Side Error** -> respond with correction guidance and close as a user-integration issue.
- **Environment Failure** -> request environment fixes and ask the adopter to rerun the same evidence path.

Needs information response for Class D flow:

- "Needs information: please provide missing ordered commands and supporting logs so we can classify this bundle."

Security carve-out: do not post vulnerability details in public issue threads. Route security reports through `SECURITY.md`.

## Submitting an Evidence Bundle

To submit evidence of a failure or confusion, you must use our canonical evidence bundle template.

You can find the template at `docs/templates/outside-adopter-evidence.md`.

Required evidence must include all of the following checklist items:
1. Environment matrix
2. Scrypath Ref or Hex version
3. Chosen proof path
4. Sync mode
5. Ordered commands
6. Expected versus actual outcome
7. First failure point
8. Supporting logs

Incomplete evidence bundles (missing context, missing ordered commands, or missing logs) are classified as Class D and returned for clarification.

Include the completed template in an issue on GitHub.
