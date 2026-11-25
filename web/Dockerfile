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

# 브라우저 탭 제목 (팀 레포 app.json의 name은 "YeoBack-FE-native-tmp")
ARG SITE_TITLE="여백 - AI 공동 여행 플래너"
ENV SITE_TITLE=${SITE_TITLE}

# 배포 빌드에서만 app.json 패치 (팀 레포 원본은 수정하지 않음)
#  - output: single → 동적 경로를 index.html 하나로 처리(SPA)
#  - name / web.name → 탭 제목
RUN node -e "const fs=require('fs');const j=JSON.parse(fs.readFileSync('app.json','utf8'));const t=process.env.SITE_TITLE;j.expo.name=t;j.expo.web={...(j.expo.web||{}),output:'single',name:t,shortName:'여백'};fs.writeFileSync('app.json',JSON.stringify(j,null,2));"
RUN npm ci --no-audit --no-fund
RUN npx expo export --platform web --output-dir dist
# export 결과 index.html의 <title>도 확실하게 교체하고, 바뀌었는지 검사
RUN node -e "const fs=require('fs');const f='dist/index.html';let h=fs.readFileSync(f,'utf8');h=h.replace(/<title>[^<]*<\/title>/,'<title>'+process.env.SITE_TITLE+'</title>');fs.writeFileSync(f,h);if(!h.includes('<title>'+process.env.SITE_TITLE+'</title>')){console.error('title patch failed');process.exit(1)}"

FROM caddy:2-alpine
COPY Caddyfile /etc/caddy/Caddyfile
COPY --from=build /src/dist /srv
