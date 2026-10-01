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
CLEANUP_SURFACES = [
    "branch/worktree",
    "generated outputs",
    "temporary files",
    "services",
    "verification",
    "unrelated state",
]


def record(
    statuses: list[str] | None = None,
    *,
    decision: str = "READY FOR OPERATOR UI",
    unresolved: str = "None",
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
            "No phase-owned debt remains; unrelated user state is excluded.",
            "",
            "| Surface | Inspection/result | Ownership/debt disposition |",
            "|---|---|---|",
            *[
                f"| {surface} | Inspected and recorded for this synthetic fixture. | {'Unrelated; preserved' if surface == 'unrelated state' else 'None'} |"
                for surface in CLEANUP_SURFACES
            ],
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

    def test_duplicate_assessment_cannot_hide_later_nonpassing_record(self) -> None:
        statuses = ["PASS"] * 6
        statuses[5] = "UNKNOWN"
        live_record = record(statuses, decision="NOT READY", recommendation=False)
        self.assert_rejected(record() + "\n" + live_record)

    def test_fenced_passing_example_cannot_override_live_nonpassing_record(self) -> None:
        fenced_example = "```markdown\n" + record() + "```\n\n"
        statuses = ["PASS"] * 6
        statuses[5] = "UNKNOWN"
        live_record = record(statuses, decision="READY FOR OPERATOR UI", recommendation=True)
        self.assert_rejected(fenced_example + live_record)

    def test_commented_passing_example_cannot_override_live_nonpassing_record(self) -> None:
        commented_example = "<!--\n" + record() + "-->\n\n"
        statuses = ["PASS"] * 6
        statuses[5] = "UNKNOWN"
        live_record = record(statuses, decision="READY FOR OPERATOR UI", recommendation=True)
        self.assert_rejected(commented_example + live_record)

    def test_raw_html_passing_example_cannot_override_live_nonpassing_record(self) -> None:
        html_example = "<section>\n" + record() + "</section>\n\n"
        statuses = ["PASS"] * 6
        statuses[5] = "UNKNOWN"
        live_record = record(statuses, decision="READY FOR OPERATOR UI", recommendation=True)
        self.assert_rejected(html_example + live_record)

    def test_raw_text_html_block_with_blank_lines_is_ignored_until_close(self) -> None:
        html_example = "<script>\n\n" + record() + "\n</script>\n\n"
        statuses = ["PASS"] * 6
        statuses[5] = "UNKNOWN"
        live_record = record(statuses, decision="READY FOR OPERATOR UI", recommendation=True)
        self.assert_rejected(html_example + live_record)

    def test_multiline_raw_text_html_open_is_ignored_until_matching_close(self) -> None:
        html_example = "<script\n>\n\n" + record() + "\n</script>\n\n"
        statuses = ["PASS"] * 6
        statuses[5] = "UNKNOWN"
        live_record = record(statuses, decision="READY FOR OPERATOR UI", recommendation=True)
        self.assert_rejected(html_example + live_record)

    def test_same_line_raw_text_html_close_is_processed(self) -> None:
        html_example = "<script>" + record() + "</script>\n\n"
        statuses = ["PASS"] * 6
        statuses[5] = "UNKNOWN"
        live_record = record(statuses, decision="READY FOR OPERATOR UI", recommendation=True)
        self.assert_rejected(html_example + live_record)

    def test_raw_text_close_like_string_in_quoted_opener_does_not_expose_forged_record(self) -> None:
        html_example = '<script data="</script>">\n' + record() + "\n</script>\n\n"
        statuses = ["PASS"] * 6
        statuses[5] = "UNKNOWN"
        live_record = record(statuses, decision="NOT READY", recommendation=False).replace(
            "| 6 | " + CONDITIONS[5] + " | UNKNOWN |",
            "| 6 | " + CONDITIONS[5] + " | MAYBE |",
        )
        self.assert_rejected(html_example + live_record)

    def test_mismatched_raw_text_close_does_not_expose_forged_record(self) -> None:
        html_block = "<script>\n</textarea>\n" + record() + "\n</script>\n\n"
        statuses = ["PASS"] * 6
        statuses[5] = "UNKNOWN"
        live_record = record(statuses, decision="READY FOR OPERATOR UI", recommendation=True)
        self.assert_rejected(html_block + live_record)

    def test_inline_html_does_not_hide_live_assessment(self) -> None:
        result = self.run_checker("<span>inline content</span>\n" + record())
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_standalone_custom_tag_after_paragraph_text_remains_inline(self) -> None:
        result = self.run_checker("intro\n<custom-widget>\n" + record())
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

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

    def test_ambiguous_clear_prefix_cannot_hide_unresolved_finding(self) -> None:
        self.assert_rejected(record(unresolved="None, except F-17 (High) remains unresolved"))

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

    def test_impossible_calendar_date_is_rejected(self) -> None:
        self.assert_rejected(record().replace("2026-09-25", "2026-99-99", 1))

    def test_out_of_root_local_evidence_link_is_rejected(self) -> None:
        self.assert_rejected(record().replace("https://example.invalid/evidence/1", "../../../../../../etc/passwd", 1))

    def test_missing_local_evidence_link_is_rejected(self) -> None:
        self.assert_rejected(record().replace("https://example.invalid/evidence/1", "missing.md", 1))

    def test_fragment_only_evidence_link_is_rejected(self) -> None:
        self.assert_rejected(record().replace("https://example.invalid/evidence/1", "#evidence", 1))

    def test_mailto_link_does_not_count_as_evidence(self) -> None:
        self.assert_rejected(record().replace("https://example.invalid/evidence/1", "mailto:evidence@example.invalid", 1))

    def test_http_link_does_not_count_as_evidence(self) -> None:
        self.assert_rejected(record().replace("https://example.invalid/evidence/1", "http://example.invalid/evidence/1", 1))

    def test_insecure_http_link_is_rejected_even_with_https_evidence(self) -> None:
        text = record().replace(
            "[Evidence 1](https://example.invalid/evidence/1)",
            "[Evidence 1](https://example.invalid/evidence/1); [insecure copy](http://example.invalid/evidence/1)",
            1,
        )
        self.assert_rejected(text)

    def test_in_root_local_evidence_link_is_accepted(self) -> None:
        result = self.run_checker(record().replace("https://example.invalid/evidence/1", "evidence.md", 1))
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_condition_six_must_link_the_cleanup_inventory(self) -> None:
        self.assert_rejected(record().replace("#phase-164-cleanup-and-verification-inventory", "#missing-inventory", 1))

    def test_condition_six_anchor_must_be_a_markdown_link(self) -> None:
        self.assert_rejected(
            record().replace(
                "[cleanup inventory](#phase-164-cleanup-and-verification-inventory)",
                "cleanup inventory (#phase-164-cleanup-and-verification-inventory)",
                1,
            )
        )

    def test_condition_six_cannot_pass_with_pending_verification_debt(self) -> None:
        text = record().replace(
            "No phase-owned debt remains; unrelated user state is excluded.",
            "No phase-owned debt remains; final SHA closeout pending; unrelated user state is excluded.",
        )
        self.assert_rejected(text)

    def test_cleanup_keyword_mentions_without_surface_table_are_rejected(self) -> None:
        text = record().replace(
            "| Surface | Inspection/result | Ownership/debt disposition |\n|---|---|---|\n"
            + "\n".join(
                f"| {surface} | Inspected and recorded for this synthetic fixture. | "
                + ("Unrelated; preserved" if surface == "unrelated state" else "None")
                + " |"
                for surface in CLEANUP_SURFACES
            ),
            "This mentions branch generated temporary services verification unrelated, but records no inspection results.",
        )
        self.assert_rejected(text)

    def test_condition_six_requires_clear_disposition_for_each_surface(self) -> None:
        text = record().replace(
            "| verification | Inspected and recorded for this synthetic fixture. | None |",
            "| verification | Inspected and recorded for this synthetic fixture. | Open debt |",
        )
        self.assert_rejected(text)

    def test_missing_cleanup_inventory_is_rejected(self) -> None:
        self.assert_rejected(record().replace("## Phase 164 cleanup and verification inventory", "## Cleanup"))

    def test_nonready_record_without_recommendation_is_valid(self) -> None:
        statuses = ["PASS"] * 6
        statuses[4] = "UNKNOWN"
        result = self.run_checker(record(statuses, decision="NOT READY", recommendation=False))
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
