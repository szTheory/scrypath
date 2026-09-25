"""Synthetic positive and adversarial fixtures for the findings contract."""
from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import check_findings


def card(name: str, fields: dict[str, str]) -> str:
    return f"### {name}\n" + "".join(f"- {key}: {value}\n" for key, value in fields.items())


def fixture() -> str:
    return """# Findings

## Claim triage
| Claim | Job | Classification | Evidence and limits | Decision relevance | Finding | Qualification |
|---|---|---|---|---|---|---|
| [C-21](162-BASELINE.md#c-21) | Maintainer security posture | evidence-gap | [receipt](receipt.md); historical only | Named advisory disposition | — | not-qualifying — reconciled chronology |

## Material findings
None — see [claim triage](#claim-triage).

## Follow-up candidates
None — see [claim triage](#claim-triage).
"""


def material_fixture(disposition: str = "deferred", decision: str = "unknown — none", trigger: str = "release", extra: str = "") -> str:
    fields = {
        "Claims": "C-21", "Job": "Maintainer", "Scrypath boundary": "Dependency audit",
        "Evidence": "[receipt](receipt.md)", "Impact": "unknown — not established",
        "Frequency/exposure": "unknown — not established", "Confidence": "medium",
        "Compatibility risk": "unknown — not assessed", "Security risk": "unknown — not assessed",
        "Privacy risk": "unknown — not assessed", "Data-integrity risk": "unknown — not assessed",
        "Operational risk": "unknown — not assessed", "Implementation cost": "unknown — not estimated",
        "Regression cost": "unknown — not estimated", "Recurring verification cost": "unknown — not estimated",
        "Rank": "High", "Rank rationale": "synthetic fixture only", "Disposition": disposition,
        "Disposition basis": "synthetic fixture only", "Risk state": "unresolved", "Owner": "maintainer",
        "Decision evidence": decision, "Revisit trigger": trigger, "Route": "deferred",
    }
    text = fixture().replace("evidence-gap", "material-risk").replace("| — | not-qualifying — reconciled chronology |", "| F-01 | not-qualifying — synthetic fixture")
    return text.replace("## Material findings\nNone — see [claim triage](#claim-triage).", "## Material findings\n" + card("F-01", fields) + extra)


def candidate_with_proof(proof: str) -> str:
    fields = {
        "Name": "synthetic", "Findings": "F-01", "Outcome": "bounded result", "Evidence": "[receipt](receipt.md)",
        "Owner boundary": "team", "Scope authority": "approved", "Exclusions": "other cases", "Route": "focused-patch",
        "Route rationale": "synthetic", "Work units": "one task", "Value/cost rationale": "synthetic",
        "Acceptance claims": "P-01 claim-specific oracle",
    }
    return "## Follow-up candidates\n" + card("K-01", fields) + proof.replace("### P-01", "#### P-01")


class FindingsContractTests(unittest.TestCase):
    def validate(self, text: str, claims: list[str] | None = None, stage: str = "triage") -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            (root / "162-BASELINE.md").write_text("| C-21 |\n| C-22 |\n", encoding="utf-8")
            (root / "receipt.md").write_text("receipt\n", encoding="utf-8")
            path = root / "findings.md"
            path.write_text(text, encoding="utf-8")
            check_findings.validate_document(path, root, claims=claims, stage=stage)

    def test_accepts_scoped_claim_with_baseline_and_evidence_links(self) -> None:
        self.validate(fixture(), ["C-21"])

    def test_rejects_material_rank_for_evidence_gap(self) -> None:
        fields = {
            "Claims": "C-21", "Job": "Maintainer", "Scrypath boundary": "Dependency audit",
            "Evidence": "[receipt](receipt.md)", "Impact": "unknown — not established",
            "Frequency/exposure": "unknown — not established", "Confidence": "medium",
            "Compatibility risk": "unknown — not assessed", "Security risk": "unknown — not assessed",
            "Privacy risk": "unknown — not assessed", "Data-integrity risk": "unknown — not assessed",
            "Operational risk": "unknown — not assessed", "Implementation cost": "unknown — not estimated",
            "Regression cost": "unknown — not estimated", "Recurring verification cost": "unknown — not estimated",
            "Rank": "High", "Rank rationale": "fixture", "Disposition": "deferred", "Disposition basis": "fixture",
            "Risk state": "unresolved", "Owner": "maintainer", "Decision evidence": "unknown — none",
            "Revisit trigger": "release", "Route": "deferred",
        }
        text = fixture().replace("| — | not-qualifying — reconciled chronology |", "| F-01 | not-qualifying — reconciled chronology |")
        text = text.replace("## Material findings\nNone — see [claim triage](#claim-triage).", "## Material findings\n" + card("F-01", fields))
        with self.assertRaisesRegex(check_findings.ContractError, "Classification"):
            self.validate(text, ["C-21"])

    def test_rejects_accepted_risk_without_owner_decision_link(self) -> None:
        with self.assertRaisesRegex(check_findings.ContractError, "decision source"):
            self.validate(material_fixture("accepted", "owner approved"), ["C-21"])

    def test_rejects_deferred_finding_without_event_trigger(self) -> None:
        with self.assertRaisesRegex(check_findings.ContractError, "event trigger"):
            self.validate(material_fixture("deferred", "unknown — none", ""), ["C-21"])

    def test_rejects_proof_card_without_oracle(self) -> None:
        proof = card("P-01", {"User outcome": "visible result", "Layer": "browser"})
        text = material_fixture().replace("Route: deferred", "Route: K-01")
        text = text.replace("## Follow-up candidates\nNone — see [claim triage](#claim-triage).", candidate_with_proof(proof))
        with self.assertRaisesRegex(check_findings.ContractError, "Oracle|oracle"):
            self.validate(text, ["C-21"])

    def test_accepts_material_finding_with_claim_specific_proof(self) -> None:
        proof_fields = {
            "User outcome": "bounded claim", "Boundary": "one fixture", "Exclusions": "rollback",
            "Fixture": "[fixture](receipt.md)", "Oracle": "terminal success and visible hit",
            "Layer": "browser", "Command": "synthetic command", "Environment/versions": "unknown — synthetic",
            "Receipt": "[result](receipt.md)", "Invalidation trigger": "source change", "Timeout": "30 seconds",
            "Diagnostics": "logs", "Isolation": "temporary", "Cleanup": "automatic",
            "CI posture": "unchanged", "CI economics": "claim-local fixture",
        }
        text = material_fixture("closed", "[proof](receipt.md)", "source change")
        text = text.replace("Risk state: unresolved", "Risk state: resolved").replace("Evidence: [receipt](receipt.md)", "Evidence: P-01")
        text = text.replace("Route: deferred", "Route: K-01")
        text = text.replace("## Follow-up candidates\nNone — see [claim triage](#claim-triage).", candidate_with_proof(card("P-01", proof_fields)))
        self.validate(text, ["C-21"])

    def test_rejects_orphan_followup_candidate(self) -> None:
        candidate = card("K-01", {
            "Name": "synthetic", "Findings": "F-01", "Outcome": "test", "Evidence": "[receipt](receipt.md)",
            "Owner boundary": "team", "Scope authority": "none", "Exclusions": "all else", "Route": "focused-patch",
            "Route rationale": "test", "Work units": "one bounded task", "Value/cost rationale": "synthetic",
            "Acceptance claims": "one claim",
        })
        text = material_fixture(extra="").replace("## Follow-up candidates\nNone — see [claim triage](#claim-triage).", "## Follow-up candidates\n" + candidate)
        with self.assertRaisesRegex(check_findings.ContractError, "orphan candidate"):
            self.validate(text, ["C-21"])

    def test_rejects_blank_candidate_field(self) -> None:
        text = material_fixture().replace("Route: deferred", "Route: K-01")
        candidate = candidate_with_proof("").replace("Scope authority: approved", "Scope authority:   ")
        text = text.replace("## Follow-up candidates\nNone — see [claim triage](#claim-triage).", candidate)
        with self.assertRaisesRegex(check_findings.ContractError, "Scope authority: blank"):
            self.validate(text, ["C-21"])

    def test_rejects_absolute_and_escaping_links(self) -> None:
        for link in ("/etc/passwd", "../../../outside.md"):
            with self.subTest(link=link), self.assertRaisesRegex(check_findings.ContractError, "link"):
                self.validate(fixture().replace("162-BASELINE.md#c-21", link), ["C-21"])

    def test_rejects_duplicate_ids_and_unknown_or_empty_selection(self) -> None:
        duplicate = fixture().replace("Named advisory disposition | — | not-qualifying — reconciled chronology |", "Named advisory disposition | — | not-qualifying — reconciled chronology |\n| [C-21](162-BASELINE.md#c-21) | duplicate | evidence-gap | [receipt](receipt.md) | relevance | — | not-qualifying — duplicate |")
        with self.assertRaisesRegex(check_findings.ContractError, "duplicate"):
            self.validate(duplicate, ["C-21"])
        for selected in ([], ["C-99"]):
            with self.subTest(selected=selected), self.assertRaises(check_findings.ContractError):
                self.validate(fixture(), selected)
        with self.assertRaisesRegex(check_findings.ContractError, "duplicate"):
            self.validate(fixture(), ["C-21", "C-21"])

    def test_full_mode_rejects_partial_inventory(self) -> None:
        with self.assertRaisesRegex(check_findings.ContractError, "missing baseline claim"):
            self.validate(fixture(), None, "complete")

    def test_accepts_complete_zero_finding_and_candidate_inventory(self) -> None:
        second = "| [C-22](162-BASELINE.md#c-22) | Maintainer docs | no-new-observation | [receipt](receipt.md) | No decision change | — | not-qualifying — no new observation |"
        text = fixture().replace("\n\n## Material findings", "\n" + second + "\n\n## Material findings", 1)
        text += """

## Disposition summary
- Claims: 2
- Material findings: none
- Closed: none
- Accepted: none
- Deferred: none
- Rejected: none
- Unresolved gate-rank findings: none
- Candidates: none
- Proof claims: none

## Phase 164 handoff
- Baseline: [canonical baseline](162-BASELINE.md)
- Dispositions: [claim triage](findings.md#disposition-summary)
- Residual gaps: none beyond the claim-level evidence limits
- Candidate and nonqualification outcome: no candidates qualify
- Unresolved owner decisions: none
- Gate ownership: Phase 164 owns the six-condition readiness gate
"""
        self.validate(text, None, "complete")

    def test_claim_relationships_do_not_depend_on_row_order(self) -> None:
        second = "| [C-22](162-BASELINE.md#c-22) | Maintainer docs | no-new-observation | [receipt](receipt.md) | No decision change | — | not-qualifying — no new observation |"
        original = fixture().replace("\n\n## Material findings", "\n" + second + "\n\n## Material findings", 1)
        first = "| [C-21](162-BASELINE.md#c-21) | Maintainer security posture | evidence-gap | [receipt](receipt.md); historical only | Named advisory disposition | — | not-qualifying — reconciled chronology |"
        reversed_rows = original.replace(first + "\n" + second, second + "\n" + first)
        self.validate(original, ["C-21", "C-22"])
        self.validate(reversed_rows, ["C-21", "C-22"])


if __name__ == "__main__":
    unittest.main()
