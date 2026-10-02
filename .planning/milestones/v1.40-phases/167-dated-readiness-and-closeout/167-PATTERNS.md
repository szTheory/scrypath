# Phase 167: Dated Readiness and Closeout - Pattern Map

**Mapped:** 2026-09-27
**Files analyzed:** 8 likely implementation artifacts; names below are recommendations where CONTEXT/RESEARCH leave arrangement discretionary.
**Analogs found:** 8 / 8 (five primary tracked analogs)

## File Classification

`phase/` below means `.planning/phases/167-dated-readiness-and-closeout/`. Documentation records use the model role because they hold decision/evidence state; this is not a recommendation to introduce application models.

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `phase/167-ASSESSMENT.md` (new, proposed name) | model | transform | `.planning/reference/PRE-OPERATOR-UI-READINESS.md` | exact |
| `phase/167-EVIDENCE.json` (new, proposed name) | model | batch | `.planning/phases/166-host-tenant-and-repair-evidence/166-EVIDENCE.json` | exact |
| `phase/167-CLOSEOUT.md` (new, proposed name; may combine with assessment) | model | batch | `.planning/reference/PRE-OPERATOR-UI-READINESS.md` | exact |
| `phase/check_readiness.py` (new) | utility | file-I/O, transform | `.planning/milestones/v1.39-phases/164-readiness-gate-and-reconciliation/check_readiness.py` | role-match; phase semantics must change |
| `phase/test_check_readiness.py` (new) | test | file-I/O, batch | `.planning/milestones/v1.39-phases/164-readiness-gate-and-reconciliation/test_check_readiness.py` | exact fixture architecture |
| `.planning/reference/PRE-OPERATOR-UI-READINESS.md` (current posture only) | model | transform | same tracked file | exact |
| `phase/167-VERIFICATION.md` (execution artifact) | model | batch | `.planning/phases/166-host-tenant-and-repair-evidence/166-EVIDENCE.json` | role-match |
| `phase/167-*-SUMMARY.md` (execution artifact family) | model | batch | `.planning/phases/166-host-tenant-and-repair-evidence/166-EVIDENCE.json` | role-match |

Routine GSD updates to STATE, ROADMAP, REQUIREMENTS and PROJECT follow their existing sections; these are tracking surfaces, not new software. Update shipped claims only when supported. `scripts/ci_monitor.cjs` and CONTRIBUTING are existing orchestration/authority inputs, not proposed edits. Release-reference correction in `mix.exs` / `docs/releasing.md` is optional: the approved alternative is explicit bounded disposition in the new record. No product file, workflow lane, dependency remediation, or public guide change is implied by this map.

## Pattern Assignments

### `phase/167-ASSESSMENT.md` and readiness authority current posture

**Analog:** `.planning/reference/PRE-OPERATOR-UI-READINESS.md`, current evidence lines 10–16 and historical assessment/cleanup sections. Keep the six approved definitions verbatim. Its current evidence paragraph already separates a historical decision from later final-source evidence (line 15):

```markdown
This newer evidence can inform a separately dated condition 6 reassessment, but does not rewrite the historical decision.
```

For the table contract, copy the exact header from archived `check_readiness.py`, lines 22–25:

```python
TABLE_HEADER = (
    "| # | Approved condition | Status | Evidence date | Assessment date | "
    "Dated linked evidence / receipt + SHA | Boundary, freshness, or limitation |"
)
```

Add an explicit unique assessment identifier/UTC cutoff and full assessment source SHA. Evidence observation dates remain independent fields and may truthfully be on the same calendar day. Reason independently about all six conditions; previous PASS statuses are inputs, not inherited outcomes. Preserve the Phase 164 assessment and cleanup bytes, including condition 3/6 UNKNOWN and NOT READY. Add the new artifact link only in the authority's current posture; do not repair historical links by editing history.

**No existing byte-preservation helper was identified.** The new contract needs a pinned pre-edit Git source identity and a raw-byte comparison of the historical section, with a mutation fixture. Markdown parsing or checking only statuses is insufficient for byte preservation. Keep the baseline independent of the current edited file so an accidental change cannot bless itself.

### `phase/167-EVIDENCE.json`

**Analog:** `.planning/phases/166-host-tenant-and-repair-evidence/166-EVIDENCE.json`.

**Core identity pattern**, lines 1–13:

```json
{
  "schema": 1,
  "source_sha": "50d5c12d36ec560525e245bcb992c40e5927854f",
  "observed_at_utc": "2026-09-27T13:31:54Z",
  "candidate_closeout": {
    "authority": "github-actions-exact-sha",
    "repository": "szTheory/scrypath",
    "workflow": "ci.yml",
    "run_id": 36321613553,
    "run_attempt": 1,
    "event": "workflow_dispatch",
    "head_sha": "50d5c12d36ec560525e245bcb992c40e5927854f",
    "run_url": "https://github.com/szTheory/scrypath/actions/runs/36321613553"
  }
}
```

Excerpt closes the surrounding JSON for readability. Copy field relationships, never stale identities. Individual executions additionally bind `id`, `scenario`, `result`, `skipped`, `source_sha`, `run_id`, `job_id`, `run_attempt`, and `job_conclusion` (lines 28–37, 90–99, 162–171). Keep Phase 165 and 166 source identities distinct. Join requirement → scenario → canonical receipt → measured source → result, with limits and freshness. A valid SHA-shaped string alone does not verify the join.

**Package provenance**, lines 125–127:

```json
"build_source_sha": "50d5c12d36ec560525e245bcb992c40e5927854f",
"hosted_log_confirms_artifact_tag_resolution_compile_and_integration_completion": true,
"public_registry_installation_claimed": false
```

Keep planning milestone tag, published package version/source, local artifact version/build source, and closeout source in separate fields. The local artifact claim is not public Hex installation evidence. Do not copy machine paths or full log payloads into a new receipt; reference canonical receipts and bounded excerpts.

**Freshness pattern**, lines 251–254:

```json
"delete_receipt": {
  "receipt_source_sha": "dc400b2b57aec0ca6b0ef16c9477d266fd41a433",
  "assessment_source_sha": "50d5c12d36ec560525e245bcb992c40e5927854f",
  "relevant_paths": ["lib", "examples", "config", "test/support", ".github/workflows", "mix.exs", "mix.lock"]
```

Lines 273–289 attach `invalidates` and a scenario-specific `reason` to each changed path. Reuse those prior explanations only at their recorded comparison source; inspect the delta to the Phase 167 assessment and final source. An invalidator requires targeted fresh proof or UNKNOWN. Lines 300–318 preserve claim limits, receipt run/job/artifact/digest identity, and the external final-source recheck handoff. Keep the 11 unresolved probes and six descriptor-less prohibitions visible by canonical reference without turning them into new conditions or invented defects.

### `phase/167-CLOSEOUT.md`

**Analog:** readiness authority's historical cleanup inventory; validator constants make its six-surface shape explicit (`check_readiness.py`, lines 28–36):

```python
CLEANUP_HEADER = "| Surface | Inspection/result | Ownership/debt disposition |"
CLEANUP_SURFACES = (
    "branch/worktree",
    "generated outputs",
    "temporary files",
    "services",
    "verification",
    "unrelated state",
)
```

Record current inspection results and ownership evidence for each surface. Distinguish work created by Phase 167 from pre-existing branches, caches, service stacks, and user changes. Names mentioning an old phase are not ownership proof. Explicitly disposition release-reference mismatch and accepted v1.39 planning debt, rather than silently repairing historical records. Required final verification still pending at the assessment cutoff must remain visible; later external success does not rewrite the dated assessment.

### `phase/check_readiness.py`

**Analog:** archived `check_readiness.py`. Copy selected structural ideas into a new current-phase tool; preserve the archived checker unchanged.

**Imports**, lines 4–11:

```python
from __future__ import annotations

import argparse
import re
import sys
from datetime import date
from pathlib import Path
from urllib.parse import urlsplit
```

**Errors**, lines 47–52:

```python
class ContractError(ValueError):
    """A structural invariant in the readiness record is missing or malformed."""


def fail(message: str) -> None:
    raise ContractError(message)
```

**Fail-closed decision**, lines 408–413:

```python
decision, findings = decision_and_findings(section)
all_pass = all(status == "PASS" for status in statuses)
no_gate_rank_finding = findings.casefold() in CLEAR_FINDING_STATES
expected_decision = "READY FOR OPERATOR UI" if all_pass and no_gate_rank_finding else "NOT READY"
if decision != expected_decision:
    fail(f"decision must be {expected_decision} from the six statuses and gate-rank finding state")
```

Reuse exact row count/order/definition validation (383–406), visible Markdown extraction (55–217), local-link containment/existence checks (245–297), and explicit cleanup surface checks (301–332). These enforce record shape only. The current source/receipt joins and raw historical byte guard are additions; do not suggest that the old checker already supplies them.

**Mandatory adaptations:** replace Phase 164 selector (220–236), cleanup heading/anchor (303, 434), pre-archive default parent depths (449–450), and unequal-date rule (401–402). Use explicit record/root inputs and a current assessment selector. Do not import a Phase 163-specific clear-findings phrase as current evidence. Keep all allowed status strings and recommendation constraints. Same-day source/assessment fixtures must pass if timestamps and field meanings are truthful.

**CLI result boundary**, lines 455–460:

```python
except (OSError, ContractError) as error:
    print(f"STRUCTURAL CONTRACT FAIL: {error}", file=sys.stderr)
    return 1
print(
    "STRUCTURAL CONTRACT PASS — checks record shape only; it does not certify source truth, "
    "semantic finding judgment, owner approval, or readiness."
)
```

Authentication/authorization middleware is inapplicable to this local record utility. Its trust boundary is repository-root containment and evidence identity validation, not host user authorization.

### `phase/test_check_readiness.py`

**Analog:** archived `test_check_readiness.py`, imports lines 3–9; temporary fixture subprocess pattern lines 85–100:

```python
class ReadinessContractTests(unittest.TestCase):
    def run_checker(self, text: str) -> subprocess.CompletedProcess[str]:
        with tempfile.TemporaryDirectory(dir=PHASE_DIR) as tmp:
            doc = Path(tmp) / "readiness.md"
            (Path(tmp) / "evidence.md").write_text("synthetic local evidence\n", encoding="utf-8")
            doc.write_text(text, encoding="utf-8")
            return subprocess.run(
                [sys.executable, str(CHECKER), str(doc), "--root", tmp],
                text=True,
                capture_output=True,
                check=False,
            )

    def assert_rejected(self, text: str) -> None:
        result = self.run_checker(text)
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
```

Adapt the synthetic record factory (32–82) to the new timestamp/source contract. Preserve adversarial intent: duplicate/hidden/fenced records (107–170), UNKNOWN/FAIL paired with READY and ambiguous finding clearance (180–194), missing/duplicate rows (201–213), unsafe/unresolved evidence links (221–246), and hidden verification debt (260–285). Add changed historical bytes, wrong source/receipt/scenario joins, and truthful same-day positive cases. Include a valid NOT READY record (290–294); structural success must never require readiness success.

### `phase/167-VERIFICATION.md` and `phase/167-*-SUMMARY.md`

Use the evidence identity fields above and the existing closeout receipt shape from `scripts/ci_monitor.cjs`, lines 211–235. Distinguish structural test results, scenario acceptance at measured sources, candidate acceptance, and the final external receipt. Do not embed a future final SHA or promise that a candidate's receipt covers later commits. List unresolved claims as bounded limitations. These documents are final tracking inputs; after committing them, final attestation is external.

## Shared Patterns

### Exact-source orchestration and immutable artifact identity

**Source:** `scripts/ci_monitor.cjs`, lines 125–137; applies to evidence/verification/closeout records.

```javascript
const matches = (artifacts || []).filter(
  (artifact) => artifact.name === name && artifact.expired === false,
);
if (matches.length !== 1) {
  throw new Error(`expected exactly one live ${name} artifact, found ${matches.length}`);
}

const artifact = matches[0];
if (!artifact.digest || !artifact.id || artifact.workflow_run?.head_sha !== sha) {
  throw new Error(`${name} is missing its id/digest or is not bound to ${sha}`);
}
return artifact;
```

Reuse the existing command from CONTRIBUTING lines 70–83:

```sh
node scripts/ci_monitor.cjs closeout --push \
  --branch "$(git branch --show-current)" \
  --sha "$(git rev-parse HEAD)"
```

Candidate → final tracking commits → exact final attestation. No tracked write follows the final successful run. Recheck C-09 relevant paths at that final source and report the result externally.

### Advisory scenario acceptance is independently inspected

`scripts/ci_monitor.cjs` lines 10–16 preserves five required checks; lines 187–198 adds coverage and closeout-attestation for closeout. Phoenix is absent from that enforced list. Inspect the named Phoenix job's successful conclusion and actual scenario result/skipped state at the recorded source, as in Phase 166 JSON lines 28–37 and 90–99. A green run alone cannot substitute. Do not modify required gates or add a matrix.

### Ownership and durable truth

`prompts/scrypath-milestone-ratchet-roadmap.txt`, release/repository hygiene and closeout sections, calls for task-owned cleanup, preserved unrelated changes, immutable historical evidence, and durable planning decisions. Apply this to every new record. No automatic readiness pass, owner approval, publication, or cleanup action follows from a structural result.

## No Analog Found

All eight artifact classes have an analog, but three new contract behaviors have no complete existing implementation among the five selected analogs: immutable historical-byte checking, current assessment timestamp selection with same-day evidence, and requirement/scenario/source receipt joining. Implement these narrowly using RESEARCH guidance and the fixture architecture above; do not pretend the archived checker covers them.

## Metadata

**Analog search scope:** `.planning/reference`, archived Phase 164, current Phase 166, `scripts/ci_monitor.cjs`, CONTRIBUTING and relevant `prompts/` guidance.
**Primary analogs inspected:** 5; all confirmed tracked with `git ls-files -- <path>` inventory output. No ignored runtime mirror is named as an analog.
**Project skills:** no `.codex/skills/` or `.agents/skills/` files discovered.
**Pattern extraction date:** 2026-09-27.
**Tool availability:** literal Read/Write tools were unavailable; reads used exec_command and this sole output used apply_patch. No source edits, tests, hosted dispatch, or cleanup actions performed.
