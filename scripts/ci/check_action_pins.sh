#!/usr/bin/env bash
# Fails when any `uses:` reference in the given workflow files is not pinned to a 40-hex commit.
# Matches both `- uses:` and `uses:` under `- name:` steps. Local (./) and docker:// refs are skipped.
set -euo pipefail

status=0
checked=0
while IFS= read -r action_ref; do
  case "$action_ref" in ./*|docker://*) continue ;; esac
  checked=$((checked + 1))
  if [[ ! "$action_ref" =~ @[0-9a-f]{40}$ ]]; then
    echo "Unpinned action reference: $action_ref" >&2
    status=1
  fi
done < <(sed -nE 's/^[[:space:]]*(-[[:space:]]+)?uses:[[:space:]]*([^[:space:]#]+).*$/\2/p' "$@")

if [[ "$checked" -eq 0 ]]; then
  echo "No uses: references found; refusing to pass vacuously." >&2
  exit 1
fi
exit "$status"
