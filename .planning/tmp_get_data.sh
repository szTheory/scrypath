#!/bin/bash
DISCUSS_MODE=$(gsd-sdk query config-get workflow.discuss_mode 2>/dev/null || echo "discuss")
echo "---DISCUSS_MODE---"
echo "$DISCUSS_MODE"

echo "---ROADMAP---"
gsd-sdk query roadmap.analyze

echo "---STATE---"
gsd-sdk query state-snapshot

echo "---PROGRESS_BAR---"
gsd-sdk query progress.bar --raw

echo "---UAT_DEBT---"
gsd-sdk query audit-uat --raw 2>/dev/null || echo "{}"

echo "---RECENT_SUMMARIES---"
ls -t .planning/phases/*/*-SUMMARY.md 2>/dev/null | head -n 3 | while read -r file; do
  echo "File: $file"
  gsd-sdk query summary-extract "$file" --fields one_liner
done

echo "---DEBUG_SESSIONS---"
ls -1 .planning/debug/*.md 2>/dev/null | grep -v resolved | wc -l

echo "---TODOS---"
ls -1 .planning/todos/pending/*.md 2>/dev/null | wc -l
