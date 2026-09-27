"""Behavior checks for the Phase 167 source-bound evidence CLI."""

from __future__ import annotations

import subprocess
import sys
import tempfile
import unittest
import json
from pathlib import Path

from check_readiness import ContractError, validate_evidence, validate_history


ROOT = Path(__file__).resolve().parents[3]
PHASE_DIR = Path(__file__).resolve().parent
CHECKER = PHASE_DIR / "check_readiness.py"
EVIDENCE = PHASE_DIR / "167-EVIDENCE.json"


class EvidenceCliTests(unittest.TestCase):
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

    def test_receipt_identity_mutations_fail_closed(self) -> None:
        original = json.loads(EVIDENCE.read_text(encoding="utf-8"))
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
                    mutated["claims"][0][field] = value
                    record_path.write_text(json.dumps(mutated), encoding="utf-8")
                    with self.assertRaisesRegex(ContractError, field):
                        validate_evidence(ROOT, record_path)

    def test_null_duplicate_and_unsafe_receipt_identities_fail(self) -> None:
        original = json.loads(EVIDENCE.read_text(encoding="utf-8"))
        mutations = (
            ("null job", lambda item: item["claims"][0].update(job_id=None)),
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
