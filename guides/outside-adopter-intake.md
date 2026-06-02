# Outside-Adopter Intake

Use this guide when you try Scrypath in a real app and something fails, behaves differently than the docs imply, or needs maintainer review. The goal is to capture enough evidence for maintainers to reproduce the issue without a long back-and-forth.

## The Supported Example Path

Scrypath ships a Phoenix + Meilisearch example in this repository. It is the best known-good path to compare against when an outside integration behaves differently.

Canonical routing before you submit evidence:

- Start from [`README.md`](../README.md) for the release-backed install and first-hop guide map.
- Use [`guides/support-and-compatibility.md`](support-and-compatibility.md) for supported versions, install guidance, and verification commands.
- Use this intake guide for evidence classes and submission requirements.

Use release-backed guidance as the default adopter path; main may contain unreleased changes.
This intake guide stays route-first and is not a compatibility tuple authority.
Outside-adopter evidence can reopen feature-lane work only through [Scope and reopen policy](scope-and-reopen-policy.md), not by treating every unsupported integration as roadmap work.

### Repo-clone versus Hex-package boundary

- **Hex-package:** When you add `{:scrypath, "~> 0.3"}` to your `mix.exs`, you are consuming the library artifact. If you encounter issues here, we need to know your exact environment and integration steps.
- **Repo-clone:** The example path is a repo-clone workflow. It tests Scrypath as a local `path:` dependency within a complete Phoenix application.

When you submit evidence, include either the exact Hex package version or the exact git ref/commit so maintainers can classify package versus checkout behavior without ambiguity.

### Verification command family

We use two commands to verify our contracts and runtime posture:

- `mix verify.adopter`: The fast, auth-free, service-free path. It verifies support and readiness contracts.
- `mix verify.adopter --live`: The live path. It boots the `examples/phoenix_meilisearch` application and runs its tests against a real Meilisearch instance.

For live operational steps, environment variables, and repo-clone runbook detail, do not guess: follow the exact runbook in [`examples/phoenix_meilisearch/README.md`](../examples/phoenix_meilisearch/README.md).

## Runtime Assumptions

When we review outside-adopter evidence, we look at these assumptions:
- Are you within the supported Elixir/OTP range?
- Are you targeting the supported Meilisearch version?
- Are you using a supported sync mode?

## Evidence classes

Evidence bundles are classified into one of four classes to determine how we respond:

- **Class A:** Exact failure on the repo-clone live example path. Highest priority.
- **Class B:** Hex-package integration failure within the explicitly supported runtime matrix.
- **Class C:** Integration attempt outside the supported runtime matrix (e.g. older OTP or different search backend). Will likely be closed as unsupported, but logged for future roadmap consideration.
- **Class D:** Incomplete evidence, missing context, or missing ordered commands. Returned for clarification.

## Evidence findings and review rubric

When maintainers review an evidence bundle, they sort the outcome into one of five finding buckets:

1. **Bug in Scrypath:** The library failed its contract.
2. **Doc or Contract Gap:** The library behaved as intended, but the docs were missing or misleading.
3. **App-Side Error:** The integration steps in the host app were incorrect.
4. **Environment Failure:** The failure was caused by local OS, Docker, or port issues.
5. **Needs Information:** The bundle is missing the path, version/ref, first failing step, or enough sanitized output to classify.

## Maintainer triage routing

Use the evidence class and finding bucket to drive the next maintainer action:

| Class | Finding bucket | Maintainer action |
| ----- | -------------- | ----------------- |
| Class A or Class B | **Bug in Scrypath** | Open a patch-sized bugfix issue with the reproducer, affected ref/version, and first failing command step. |
| Class A or Class B | **Doc or Contract Gap** | Open a docs correction issue linked to the offending contract surface. |
| Class B or Class C | **App-Side Error** | Reply with correction guidance and close as a user-integration issue once the documented path is clear. |
| Class A, Class B, or Class C | **Environment Failure** | Request an environment fix request and ask the adopter to rerun the same evidence path. |
| Class D | **Needs Information** | Send a needs-info response that names the missing evidence fields. |

Needs information response for Class D flow:

- "Needs information: please provide missing ordered commands and supporting logs so we can classify this bundle."

Security carve-out: do not post vulnerability details in public issue threads. Route security reports through [SECURITY.md](https://github.com/szTheory/scrypath/blob/main/SECURITY.md).

## Submitting an Evidence Bundle

To submit evidence of a failure or confusion, use the outside-adopter evidence issue template.

Open it from GitHub's new issue flow or use this direct template link: [outside-adopter evidence](https://github.com/szTheory/scrypath/issues/new?template=outside-adopter-evidence.md).

Required evidence must include all of the following checklist items:
1. Path
2. Runtime versus support matrix
3. Reporter class guess
4. Reporter finding guess
5. Scrypath ref or Hex version
6. First failing command step
7. Logs or artifacts
8. Expected versus actual outcome

Incomplete evidence bundles (missing context, missing ordered commands, or missing logs) are classified as Class D and returned for clarification.

Include the completed template in an issue on GitHub.
