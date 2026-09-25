# Phase 160: Package-Backed Phoenix Proof - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-23
**Phase:** 160-Package-Backed Phoenix Proof
**Areas discussed:** Maintainer command, CI lane behavior, results and diagnostics, temporary files on failure

---

## Maintainer command

| Option | Description | Selected |
|--------|-------------|----------|
| Extend `mix verify.phoenix_example` with `--package` | Keeps package mode beside the existing live Phoenix proof and leaves its default path-based behavior intact. | ✓ |
| Extend `mix verify.adopter` | Groups adopter-facing proof modes but adds package mode to the fast/live adopter command surface. | |
| Add a separate package-proof task | Makes package proof independently selectable but adds another command and more wiring. | |

**User's choice:** Accepted the coherent recommended set: use `mix verify.phoenix_example --package` and preserve the no-argument path-backed flow.
**Notes:** User requested all four decision areas be considered together with broad ecosystem and DX research, then accepted the synthesized recommendations in one response.

---

## CI lane behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Run both path and package proof in the existing advisory job | Preserves both consumption paths and reuses the job's service containers. | ✓ |
| Replace the path proof with package proof | Saves a second run but removes live integration coverage of the normal path dependency. | |
| Add a separate advisory package job | Gives separate job-level isolation/results but repeats service and runner setup. | |

**User's choice:** Accepted running both proofs sequentially in the existing advisory `phoenix-example` job without promoting a required gate.
**Notes:** Preserve isolated database/index state across the two runs.

---

## Results and diagnostics

| Option | Description | Selected |
|--------|-------------|----------|
| Stage-oriented console results | Clear progress and pass/fail per stage; failure names the stage, command, exit status, and retains child output. | ✓ |
| Human plus machine-readable report artifact | Supports structured cross-run comparison but adds schema, artifact, and retention contracts. | |
| Concise output plus a verbosity mode | Lets maintainers opt into additional subprocess output but adds another option and output contract. | |

**User's choice:** Accepted stage-oriented terminal/CI diagnostics with useful child output and failing exit status, without a separate report artifact or verbosity option.
**Notes:** Do not print secret environment values; make required service setup and failing stage understandable.

---

## Temporary files on failure

| Option | Description | Selected |
|--------|-------------|----------|
| Always clean up | Leaves no scratch data to inspect after a failure. | |
| Clean by default; retain a failed workspace only by explicit opt-in | Keeps reruns clean and offers a debugging path on request. | ✓ |
| Configurable retention policy or always retain | Adds policy modes or persistent scratch data, with more drift and stale-file risk. | |

**User's choice:** Accepted cleanup after success and failure by default, with `--keep-temp-on-failure` as an explicit local debugging option.
**Notes:** Successful runs always clean up; retained workspaces must not contain credentials and their location should be printed.

---

## the agent's Discretion

- Internal method for handing the built/unpacked artifact to a clean isolated copy of the example, as long as package use is proven and path fallback fails closed.
- Module/helper boundaries, exact stage labels, subprocess implementation, temp naming, and contract test design.

## Deferred Ideas

None.
