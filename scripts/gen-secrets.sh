#!/usr/bin/env bash
# .env의 비어 있는 비밀값을 무작위로 채움 (이미 값이 있으면 건드리지 않음)
set -euo pipefail
cd "$(dirname "$0")/.."

[ -f .env ] || cp .env.example .env

fill() {
  local key="$1" value="$2"
  if grep -q "^${key}=$" .env; then
    sed -i "s|^${key}=$|${key}=${value}|" .env
    echo "  ${key} 생성"
  fi
}

echo ".env 비밀값 생성 중..."
# DB 비밀번호는 접속 URL에 들어가므로 특수문자 없는 hex로 생성
fill MYSQL_ROOT_PASSWORD "$(openssl rand -hex 24)"
fill DB_PASSWORD         "$(openssl rand -hex 24)"
# JWT 서명 키: HS512도 쓸 수 있도록 64바이트
fill JWT_SECRET_KEY      "$(openssl rand -hex 64)"
# 계좌번호 AES-256 키: Base64로 인코딩된 32바이트 (AccountEncryptionService 요구사항)
fill ACCOUNT_ENCRYPTION_KEY "$(openssl rand -base64 32)"
# Spring ↔ Python AI 서버 내부 인증
fill AI_INTERNAL_API_KEY "$(openssl rand -hex 32)"
chmod 600 .env
echo "완료. 이제 .env에 GEMINI_API_KEY, KAKAO_JS_KEY 등을 직접 채우세요."
