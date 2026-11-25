#!/usr/bin/env bash
# 팀 코드를 최신으로 받고 전체 서비스를 다시 빌드·실행
set -euo pipefail
cd "$(dirname "$0")/.."

[ -f .env ] || { echo ".env가 없습니다. bash scripts/gen-secrets.sh 먼저 실행하세요."; exit 1; }
set -a; . ./.env; set +a
[ -n "${GEMINI_API_KEY:-}" ] || echo "경고: GEMINI_API_KEY가 비어 있어 AI 기능이 동작하지 않습니다."
ls db/init/*.sql >/dev/null 2>&1 || echo "경고: db/init/에 초기 데이터(.sql)가 없습니다. 장소 데이터 없이 시작됩니다."

if [ "${APP_DIR:-./app}" = "./app" ]; then
  bash scripts/fetch-app.sh
fi

docker compose up -d --build
docker image prune -f >/dev/null
docker compose ps
echo "접속 주소: ${PUBLIC_URL}"
