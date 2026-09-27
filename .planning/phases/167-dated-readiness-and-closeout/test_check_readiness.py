"""Behavior checks for the Phase 167 source-bound evidence CLI."""

from __future__ import annotations

import subprocess
import sys
import unittest
from pathlib import Path


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


if __name__ == "__main__":
    unittest.main()
