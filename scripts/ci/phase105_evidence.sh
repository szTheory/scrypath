#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 2 || "$1" != "--run-dir" || -z "$2" ]]; then
  echo "Usage: $0 --run-dir <fresh-evidence-directory>" >&2
  exit 64
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
exec node "${SCRIPT_DIR}/ecommerce_evidence.cjs" write-evidence --run-dir "$2"
