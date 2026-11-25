#!/usr/bin/env bash
# 팀 레포(비공개)를 ./app 으로 받아오거나 최신으로 갱신
# GitHub 토큰은 디스크에 저장하지 않고 이번 실행에서만 사용함
set -euo pipefail
cd "$(dirname "$0")/.."
set -a; . ./.env; set +a

REPO="${APP_REPO:?}"
REF="${APP_REF:-dev}"

if [ -z "${GITHUB_TOKEN:-}" ]; then
  read -rsp "GitHub 토큰(읽기 전용 PAT): " GITHUB_TOKEN; echo
fi
AUTH="Authorization: Basic $(printf 'x-access-token:%s' "$GITHUB_TOKEN" | base64 -w0)"

if [ ! -d app/.git ]; then
  git -c http.extraHeader="$AUTH" clone --branch "$REF" "$REPO" app
else
  git -C app -c http.extraHeader="$AUTH" fetch origin "$REF"
  git -C app checkout --detach FETCH_HEAD
fi

echo "팀 코드 버전: $(git -C app log -1 --format='%h %ad %s' --date=short)"
