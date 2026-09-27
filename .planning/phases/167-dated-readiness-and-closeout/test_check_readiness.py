"""Behavior checks for the Phase 167 source-bound evidence CLI."""

from __future__ import annotations

import subprocess
import sys
import tempfile
import unittest
import json
import re
from pathlib import Path

from check_readiness import (
    ContractError,
    CONDITIONS,
    compare_delete_freshness,
    read_json,
    validate_assessment,
    validate_closeout,
    validate_evidence,
    validate_history,
)


ROOT = Path(__file__).resolve().parents[3]
PHASE_DIR = Path(__file__).resolve().parent
CHECKER = PHASE_DIR / "check_readiness.py"
EVIDENCE = PHASE_DIR / "167-EVIDENCE.json"
ASSESSMENT = PHASE_DIR / "167-ASSESSMENT.md"
CLOSEOUT = PHASE_DIR / "167-CLOSEOUT.md"


class EvidenceCliTests(unittest.TestCase):
    def test_complete_scope_exposes_assessment_and_closeout_contract(self) -> None:
        result = subprocess.run(
            [sys.executable, str(CHECKER), "--help"],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("complete", result.stdout)
        self.assertIn("--assessment", result.stdout)
        self.assertIn("--closeout", result.stdout)

    def mutate_assessment(self, mutation) -> str:
        text = ASSESSMENT.read_text(encoding="utf-8")
        return mutation(text)

    def assert_assessment_rejected(self, text: str, *, evidence: dict | None = None) -> None:
        with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", suffix=".md", dir=PHASE_DIR) as record:
            record.write(text)
            record.flush()
            with self.assertRaises(ContractError):
                validate_assessment(ROOT, Path(record.name), evidence or read_json(EVIDENCE, "test evidence"))

    def test_real_assessment_and_closeout_accept_same_calendar_day(self) -> None:
        evidence = read_json(EVIDENCE, "test evidence")
        validate_assessment(ROOT, ASSESSMENT, evidence)
        validate_closeout(ROOT, CLOSEOUT, evidence)

    def test_assessment_rejects_duplicate_missing_reordered_hidden_or_reworded_conditions(self) -> None:
        lines = ASSESSMENT.read_text(encoding="utf-8").splitlines()
        rows = [line for line in lines if line.startswith("| 1 |") or line.startswith("| 2 |")]
        cases = (
            ("duplicate", lambda text: text.replace(rows[1], rows[0] + "\n" + rows[1], 1)),
            ("missing", lambda text: text.replace(rows[0] + "\n", "", 1)),
            ("reordered", lambda text: text.replace(rows[0] + "\n" + rows[1], rows[1] + "\n" + rows[0], 1)),
            ("hidden fenced", lambda text: text.replace(rows[0], "```markdown\n" + rows[0] + "\n```", 1)),
            ("wording", lambda text: text.replace(CONDITIONS[0], "Every baseline is probably assessed.", 1)),
        )
        for name, mutate in cases:
            with self.subTest(name=name):
                self.assert_assessment_rejected(mutate("\n".join(lines) + "\n"))

    def test_assessment_rejects_bad_timestamp_source_or_ready_arithmetic(self) -> None:
        original = ASSESSMENT.read_text(encoding="utf-8")
        timestamp = re.search(r"^assessed_at_utc: (\S+)\s*$", original, re.MULTILINE).group(1)
        source = re.search(r"^assessment_source_sha: (\S+)\s*$", original, re.MULTILINE).group(1)
        mutations = (
            ("non-UTC", original.replace(timestamp, timestamp.removesuffix("Z") + "-05:00", 1)),
            ("source mismatch", original.replace(source, "a" * 40, 1)),
            ("unknown ready", original.replace("**Decision:** NOT READY.", "**Decision:** READY FOR OPERATOR UI.")),
            ("condition failed but ready", original.replace("| 1 |", "| 1 |").replace("| PASS |", "| FAIL |", 1).replace("**Decision:** NOT READY.", "**Decision:** READY FOR OPERATOR UI.")),
        )
        for name, text in mutations:
            with self.subTest(name=name):
                self.assert_assessment_rejected(text)

    def test_assessment_rejects_observation_after_cutoff(self) -> None:
        evidence = read_json(EVIDENCE, "test evidence")
        evidence["claims"][0]["observed_at_utc"] = "2026-09-27T19:39:01Z"
        self.assert_assessment_rejected(ASSESSMENT.read_text(encoding="utf-8"), evidence=evidence)

    def test_closeout_rejects_missing_surface_and_concealed_final_verification(self) -> None:
        original = CLOSEOUT.read_text(encoding="utf-8")
        service_row = next(line for line in original.splitlines() if line.startswith("| services |"))
        verification_row = next(line for line in original.splitlines() if line.startswith("| verification |"))
        missing = original.replace(service_row + "\n", "", 1)
        concealed = original.replace(
            verification_row,
            verification_row.replace("pending", "complete").replace("outstanding", "complete").replace("Open:", "None:"),
            1,
        )
        for name, text in (("missing surface", missing), ("concealed debt", concealed)):
            with self.subTest(name=name):
                with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", suffix=".md", dir=PHASE_DIR) as record:
                    record.write(text)
                    record.flush()
                    with self.assertRaises(ContractError):
                        validate_closeout(ROOT, Path(record.name), read_json(EVIDENCE, "test evidence"))

    def test_real_host_path_receipt_is_traceable(self) -> None:
        result = subprocess.run(
            [
                sys.executable,
                str(CHECKER),
                "--root",
                str(ROOT),
                "--scope",
                "evidence",
                "--evidence",
                str(EVIDENCE),
            ],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=False,
        )

        self.assertEqual(
            result.returncode,
            0,
            f"expected a structurally valid real host-path receipt, got:\n{result.stderr}",
        )
        self.assertIn("structural validation does not establish", result.stdout.lower())

    def test_complete_map_mode_requires_all_eight_claims_and_valid_comparison_sha(self) -> None:
        base = [
            sys.executable,
            str(CHECKER),
            "--root",
            str(ROOT),
            "--scope",
            "evidence",
            "--evidence",
            str(EVIDENCE),
        ]
        all_claims = subprocess.run(
            [*base, "--require-all-claims"], cwd=ROOT, capture_output=True, text=True, check=False
        )
        self.assertEqual(
            all_claims.returncode,
            0,
            f"the completed evidence map should cover every required claim:\n{all_claims.stderr}",
        )
        malformed_comparison = subprocess.run(
            [*base, "--compare-source", "not-a-commit-sha"],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertNotEqual(malformed_comparison.returncode, 0, "malformed comparison identity must fail closed")
        unexplained_comparison = subprocess.run(
            [*base, "--compare-source", "28d3877a05479f2cc104754fc24ab0c9d545c01b"],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertNotEqual(
            unexplained_comparison.returncode,
            0,
            "a source comparison with unreviewed relevant-path changes must fail closed",
        )

    def test_c09_path_comparison_rejects_missing_or_malformed_dispositions(self) -> None:
        original = json.loads(EVIDENCE.read_text(encoding="utf-8"))["delete_receipt"]
        canonical = json.loads(
            (ROOT / ".planning/phases/166-host-tenant-and-repair-evidence/166-EVIDENCE.json").read_text(encoding="utf-8")
        )["delete_receipt"]
        cases = (
            ("omitted changed path", lambda item: item.update(changed_paths=item["changed_paths"][1:])),
            ("empty semantic reason", lambda item: item.update(changes=[{**row, "reason": ""} for row in canonical["changes"]])),
            ("malformed invalidates", lambda item: item.update(changes=[{**canonical["changes"][0], "invalidates": "false"}, *canonical["changes"][1:]])),
            ("invalidator reused", lambda item: item.update(status="reusable", changes=[{**canonical["changes"][0], "invalidates": True}, *canonical["changes"][1:]])),
        )
        for name, mutate in cases:
            with self.subTest(name=name):
                changed = json.loads(json.dumps(original))
                changed["changes"] = canonical["changes"]
                mutate(changed)
                with self.assertRaises(ContractError):
                    compare_delete_freshness(ROOT, changed, None)

    def test_receipt_identity_mutations_fail_closed(self) -> None:
        original = json.loads(EVIDENCE.read_text(encoding="utf-8"))
        hosted_index = next(
            index for index, claim in enumerate(original["claims"]) if claim.get("evidence_kind") == "hosted"
        )
        mutations = (
            ("source_sha", "a" * 40),
            ("scenario", "different but valid-looking scenario"),
            ("job_id", 108626420717),
            ("result", "unknown"),
            ("skipped", True),
        )
        with tempfile.TemporaryDirectory() as directory:
            record_path = Path(directory) / "evidence.json"
            for field, value in mutations:
                with self.subTest(field=field):
                    mutated = json.loads(json.dumps(original))
                    mutated["claims"][hosted_index][field] = value
                    record_path.write_text(json.dumps(mutated), encoding="utf-8")
                    with self.assertRaisesRegex(ContractError, field):
                        validate_evidence(ROOT, record_path)

    def test_release_identities_require_canonical_source_receipts(self) -> None:
        original = json.loads(EVIDENCE.read_text(encoding="utf-8"))
        with tempfile.TemporaryDirectory() as directory:
            record_path = Path(directory) / "evidence.json"
            for index, identity in enumerate(original["release_identities"]):
                with self.subTest(kind=identity["kind"]):
                    mutated = json.loads(json.dumps(original))
                    mutated["release_identities"][index]["canonical_receipt"] = "missing/receipt.md#source"
                    record_path.write_text(json.dumps(mutated), encoding="utf-8")
                    with self.assertRaises(ContractError):
                        validate_evidence(ROOT, record_path)

    def test_null_duplicate_and_unsafe_receipt_identities_fail(self) -> None:
        original = json.loads(EVIDENCE.read_text(encoding="utf-8"))
        hosted_index = next(
            index for index, claim in enumerate(original["claims"]) if claim.get("evidence_kind") == "hosted"
        )
        mutations = (
            ("null job", lambda item: item["claims"][hosted_index].update(job_id=None)),
            ("duplicate claim", lambda item: item["claims"].append(dict(item["claims"][0]))),
            (
                "unsafe receipt link",
                lambda item: item["claims"][0].update(canonical_receipt="../../../../etc/passwd#host-path"),
            ),
        )
        with tempfile.TemporaryDirectory() as directory:
            record_path = Path(directory) / "evidence.json"
            for name, mutate in mutations:
                with self.subTest(name=name):
                    mutated = json.loads(json.dumps(original))
                    mutate(mutated)
                    record_path.write_text(json.dumps(mutated), encoding="utf-8")
                    with self.assertRaises(ContractError):
                        validate_evidence(ROOT, record_path)

    def test_history_byte_mutation_fails_against_independent_commit(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            authority = root / ".planning/reference/PRE-OPERATOR-UI-READINESS.md"
            archive_file = root / ".planning/milestones/v1.39-phases/164-readiness-gate-and-reconciliation/record.md"
            authority.parent.mkdir(parents=True)
            archive_file.parent.mkdir(parents=True)
            authority.write_bytes(b"# Authority\n\n## Phase 164 dated assessment\n\nstatus: NOT READY\n")
            archive_file.write_bytes(b"archived evidence\n")
            subprocess.run(["git", "init", "-q", str(root)], check=True)
            subprocess.run(["git", "-C", str(root), "config", "user.email", "test@example.invalid"], check=True)
            subprocess.run(["git", "-C", str(root), "config", "user.name", "Fixture"], check=True)
            subprocess.run(["git", "-C", str(root), "add", ".planning"], check=True)
            subprocess.run(["git", "-C", str(root), "commit", "-qm", "baseline"], check=True)
            baseline = subprocess.run(
                ["git", "-C", str(root), "rev-parse", "HEAD"],
                check=True,
                capture_output=True,
                text=True,
            ).stdout.strip()

            validate_history(root, baseline_sha=baseline)
            authority.write_bytes(authority.read_bytes() + b"tampered\n")
            with self.assertRaisesRegex(ContractError, "historical baseline"):
                validate_history(root, baseline_sha=baseline)

    def test_archive_extra_file_fails_against_independent_commit(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            authority = root / ".planning/reference/PRE-OPERATOR-UI-READINESS.md"
            archive_dir = root / ".planning/milestones/v1.39-phases/164-readiness-gate-and-reconciliation"
            authority.parent.mkdir(parents=True)
            archive_dir.mkdir(parents=True)
            authority.write_bytes(b"## Phase 164 dated assessment\nold bytes\n")
            (archive_dir / "record.md").write_bytes(b"archived evidence\n")
            subprocess.run(["git", "init", "-q", str(root)], check=True)
            subprocess.run(["git", "-C", str(root), "config", "user.email", "test@example.invalid"], check=True)
            subprocess.run(["git", "-C", str(root), "config", "user.name", "Fixture"], check=True)
            subprocess.run(["git", "-C", str(root), "add", ".planning"], check=True)
            subprocess.run(["git", "-C", str(root), "commit", "-qm", "baseline"], check=True)
            baseline = subprocess.run(
                ["git", "-C", str(root), "rev-parse", "HEAD"],
                check=True,
                capture_output=True,
                text=True,
            ).stdout.strip()
            (archive_dir / "extra.md").write_text("unapproved\n", encoding="utf-8")
            with self.assertRaisesRegex(ContractError, "file set"):
                validate_history(root, baseline_sha=baseline)


if __name__ == "__main__":
    unittest.main()
