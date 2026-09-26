"""Adversarial fixtures for the Phase 164 readiness record contract."""

from __future__ import annotations

import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


PHASE_DIR = Path(__file__).resolve().parent
CHECKER = PHASE_DIR / "check_readiness.py"
CONDITIONS = [
    "Every baseline dimension above has been assessed; evidence coverage and known limits are visible.",
    "Every critical, high, or medium-leverage finding is closed with verification or explicitly accepted with rationale and an owner decision. There are no unresolved findings at those levels.",
    "Important adopter workflows have appropriate automated proof for the claims being made. The goal is zero routine human verification/UAT; external credentials, permissions, product decisions, or physical-world checks are the only expected handoffs.",
    "Required CI remains green and lean. Recurring service/E2E proof runs in CI only where its repeat confidence justifies its runtime and maintenance cost; more expensive lower-frequency evidence may remain advisory or scheduled.",
    "Remaining non-UI opportunities are low-leverage, speculative, unsupported, or more costly than their likely benefit, each with a recorded disposition.",
    "Release, package, support, and planning truth are current, with no task-owned cleanup or verification debt hidden at closeout.",
]


def record(
    statuses: list[str] | None = None,
    *,
    decision: str = "READY FOR OPERATOR UI",
    unresolved: str = "none",
    recommendation: bool = True,
) -> str:
    statuses = statuses or ["PASS"] * 6
    rows = [
        "| # | Approved condition | Status | Evidence date | Assessment date | Dated linked evidence / receipt + SHA | Boundary, freshness, or limitation |",
        "|---|---|---|---|---|---|---|",
    ]
    for number, (condition, status) in enumerate(zip(CONDITIONS, statuses), start=1):
        evidence = f"[Evidence {number}](https://example.invalid/evidence/{number})"
        if number == 6:
            evidence += "; [cleanup inventory](#phase-164-cleanup-and-verification-inventory)"
        rows.append(
            f"| {number} | {condition} | {status} | 2026-09-25 | 2026-09-26 | "
            f"{evidence} | Evidence is reused only within scope; synthetic structural fixture. |"
        )
    out = [
        "## Phase 164 dated assessment — 2026-09-26",
        "",
        *rows,
        "",
        f"**Unresolved Critical, High, or Medium-leverage findings:** {unresolved}.",
        f"**Decision:** {decision}.",
    ]
    if recommendation:
        out.extend(
            [
                "",
                "**ScrypathOps recommendation:** ScrypathOps is the next strategic focus. This recommendation does not authorize or start operator UI work; maintainer availability is a separate constraint.",
            ]
        )
    out.extend(
        [
            "",
            "## Phase 164 cleanup and verification inventory",
            "",
            "Checked phase-owned branch, generated outputs, temporary artifacts, services, and final verification receipts. No phase-owned debt remains; unrelated user state is excluded.",
        ]
    )
    return "\n".join(out) + "\n"


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

    def test_complete_passing_record_is_structurally_valid(self) -> None:
        result = self.run_checker(record())
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("STRUCTURAL", result.stdout)

    def test_unknown_condition_cannot_yield_ready(self) -> None:
        statuses = ["PASS"] * 6
        statuses[2] = "UNKNOWN"
        self.assert_rejected(record(statuses))

    def test_failed_condition_cannot_yield_ready(self) -> None:
        statuses = ["PASS"] * 6
        statuses[0] = "FAIL"
        self.assert_rejected(record(statuses))

    def test_unresolved_gate_rank_finding_cannot_yield_ready(self) -> None:
        self.assert_rejected(record(unresolved="F-17 (High) remains unresolved"))

    def test_recommendation_is_rejected_for_nonpassing_gate(self) -> None:
        statuses = ["PASS"] * 6
        statuses[5] = "UNKNOWN"
        self.assert_rejected(record(statuses, decision="NOT READY"))

    def test_missing_condition_row_is_rejected(self) -> None:
        text = record().replace("| 6 | " + CONDITIONS[5], "| omitted | " + CONDITIONS[5])
        self.assert_rejected(text)

    def test_duplicate_condition_row_is_rejected(self) -> None:
        text = record().replace(
            "\n\n**Unresolved Critical, High, or Medium-leverage findings:**",
            "\n" + record().splitlines()[2] + "\n\n**Unresolved Critical, High, or Medium-leverage findings:**",
        )
        self.assert_rejected(text)

    def test_invalid_status_is_rejected(self) -> None:
        self.assert_rejected(record(["PASS", "READY", "PASS", "PASS", "PASS", "PASS"]))

    def test_missing_evidence_metadata_is_rejected(self) -> None:
        self.assert_rejected(record().replace("2026-09-25 | 2026-09-26", " | 2026-09-26", 1))

    def test_out_of_root_local_evidence_link_is_rejected(self) -> None:
        self.assert_rejected(record().replace("https://example.invalid/evidence/1", "../../../../../../etc/passwd", 1))

    def test_missing_local_evidence_link_is_rejected(self) -> None:
        self.assert_rejected(record().replace("https://example.invalid/evidence/1", "missing.md", 1))

    def test_in_root_local_evidence_link_is_accepted(self) -> None:
        result = self.run_checker(record().replace("https://example.invalid/evidence/1", "evidence.md", 1))
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_condition_six_must_link_the_cleanup_inventory(self) -> None:
        self.assert_rejected(record().replace("#phase-164-cleanup-and-verification-inventory", "#missing-inventory", 1))

    def test_missing_cleanup_inventory_is_rejected(self) -> None:
        self.assert_rejected(record().replace("## Phase 164 cleanup and verification inventory", "## Cleanup"))

    def test_nonready_record_without_recommendation_is_valid(self) -> None:
        statuses = ["PASS"] * 6
        statuses[4] = "UNKNOWN"
        result = self.run_checker(record(statuses, decision="NOT READY", recommendation=False))
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
