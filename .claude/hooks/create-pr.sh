#!/bin/bash
# PostToolUse(Bash) — git push 감지 시 GitHub PR 자동 생성

CMD=$(jq -r '.tool_input.command' 2>/dev/null)

echo "$CMD" | grep -q 'git push' || exit 0

BRANCH=$(git -C /Users/PARK/Desktop/AMS rev-parse --abbrev-ref HEAD 2>/dev/null)

# main/master는 PR 생성 스킵
[ "$BRANCH" = "main" ] || [ "$BRANCH" = "master" ] && exit 0

# 이미 PR이 있으면 스킵
gh pr view --repo yuhandemian/approval-management-system 2>/dev/null && {
  echo "PR 이미 존재 — 스킵"
  exit 0
}

SAFE=$(echo "$BRANCH" | tr '/' '_')
ISSUE_FILE="/tmp/ams-issue-$SAFE.txt"

TITLE=$(git -C /Users/PARK/Desktop/AMS log --oneline -1 | cut -d' ' -f2-)
BODY=""

if [ -f "$ISSUE_FILE" ]; then
  ISSUE_NUM=$(cat "$ISSUE_FILE")
  BODY="Closes #$ISSUE_NUM"
fi

URL=$(gh pr create \
  --title "$TITLE" \
  --body "$BODY" \
  --repo yuhandemian/approval-management-system 2>&1)

echo "PR 생성됨: $URL"
