# syntax=docker/dockerfile:1
# Expo(React Native) 앱을 웹 정적 파일로 빌드한 뒤 Caddy로 서빙
FROM node:22-bookworm-slim AS build
WORKDIR /src
COPY --from=app . .
# 로컬 .env(개인 키)와 Windows용 node_modules는 사용하지 않음
RUN rm -rf .env node_modules dist

ARG PUBLIC_URL
ARG KAKAO_JS_KEY=
ENV EXPO_PUBLIC_API_BASE_URL=${PUBLIC_URL} \
    EXPO_PUBLIC_KAKAO_JS_KEY=${KAKAO_JS_KEY} \
    CI=1 \
    NODE_OPTIONS=--max-old-space-size=1536

# 배포 빌드만 SPA(single) 모드로 — 동적 경로를 index.html 하나로 처리
RUN node -e "const fs=require('fs');const j=JSON.parse(fs.readFileSync('app.json','utf8'));j.expo.web={...(j.expo.web||{}),output:'single'};fs.writeFileSync('app.json',JSON.stringify(j,null,2));"
RUN npm ci --no-audit --no-fund
RUN npx expo export --platform web --output-dir dist

FROM caddy:2-alpine
COPY Caddyfile /etc/caddy/Caddyfile
COPY --from=build /src/dist /srv
