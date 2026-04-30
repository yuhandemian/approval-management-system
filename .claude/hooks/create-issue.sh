#!/bin/bash
# PostToolUse(Bash) — git checkout -b / switch -c 감지 시 GitHub 이슈 자동 생성

CMD=$(jq -r '.tool_input.command' 2>/dev/null)

echo "$CMD" | grep -qE 'git (checkout -b|switch -c)' || exit 0

BRANCH=$(echo "$CMD" | sed 's/.*-b //;s/.*-c //' | awk '{print $1}')
[ -z "$BRANCH" ] && exit 0

TITLE=$(echo "$BRANCH" | sed 's|feature/||;s|bugfix/||;s|hotfix/||;s|fix/||' | sed 's/-/ /g')
SAFE=$(echo "$BRANCH" | tr '/' '_')
ISSUE_FILE="/tmp/ams-issue-$SAFE.txt"

[ -f "$ISSUE_FILE" ] && exit 0

URL=$(gh issue create \
  --title "$TITLE" \
  --body "## 작업 브랜치
\`$BRANCH\`

## 작업 내용
<!-- 작업 내용을 여기에 기술하세요 -->" \
  --repo yuhandemian/approval-management-system 2>&1)

NUM=$(echo "$URL" | grep -oE '[0-9]+$')
echo "$NUM" > "$ISSUE_FILE"

echo "이슈 생성됨: $URL"
