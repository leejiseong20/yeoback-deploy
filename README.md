# 여백(旅白) 배포 — AWS Lightsail + Docker Compose

AI 기반 공동 여행 일정·예산 관리 서비스 **여백**을 AWS Lightsail 서버 한 대에 배포하기 위한 인프라 구성입니다.
애플리케이션 코드는 팀 레포([keumbyeol/Yeoback-2026](https://github.com/keumbyeol/Yeoback-2026), 비공개)에 있고,
이 레포에는 **배포에 필요한 설정만** 담았습니다. 팀 코드는 한 줄도 수정하지 않고 그대로 빌드합니다.

- 서비스 주소: `https://(배포 후 기입)`
- 담당: 이지성 (팀 프로젝트 백엔드, 개인 배포 구성)

## 구성

```
            브라우저
               │ HTTPS (Let's Encrypt 자동 발급)
┌──────────────▼───────────────────────────── Lightsail (Ubuntu, 2GB) ─┐
│  web   Caddy                                                         │
│   ├─ /            → Expo(React Native) 웹 빌드 정적 파일              │
│   └─ /api /ws /uploads /apis ─┐                                      │
│                               ▼                                      │
│  backend  Spring Boot 3 / Java 21 ──localhost:8001──▶ ai  FastAPI     │
│        │  (JWT, STOMP WebSocket, JPA)      (같은 네트워크)  + Gemini    │
│        ▼                                                     │       │
│  db  MySQL 8.0  ◀────────────────────────────────────────────┘       │
└──────────────────────────────────────────────────────────────────────┘
```

| 서비스 | 이미지 | 역할 |
|---|---|---|
| `web` | `caddy:2-alpine` + Expo 웹 빌드 | 정적 파일 서빙, 리버스 프록시, 자동 HTTPS |
| `backend` | `eclipse-temurin:21` 멀티스테이지 | REST API, 실시간 협업·채팅(WebSocket), 정산 |
| `ai` | `python:3.12-slim` | AI 일정 생성, 플래너 AI 챗봇 (Gemini) |
| `db` | `mysql:8.0` | 관광지·식당·숙소 등 콘텐츠 + 서비스 데이터 |

## 설계에서 고민한 점

**1. 팀 코드를 수정하지 않고 빌드하기**
Compose의 `additional_contexts`로 팀 레포 폴더를 빌드 컨텍스트에 붙이고, Dockerfile은 이 레포에만 둡니다.
팀 코드가 갱신되면 `scripts/deploy.sh` 한 번으로 최신 코드를 받아 다시 빌드합니다.

**2. 코드에 고정된 `localhost:8001` 문제**
백엔드의 AI 일정 생성 서비스에 AI 서버 주소가 `http://localhost:8001`로 하드코딩되어 있습니다.
컨테이너마다 `localhost`가 다르기 때문에 그대로는 연결되지 않아, `ai` 컨테이너에
`network_mode: "service:backend"`를 지정해 두 컨테이너가 네트워크 공간을 공유하도록 했습니다.

**3. 같은 출처(Same-Origin)로 묶기**
프론트와 API를 Caddy 한 곳에서 서빙해 CORS·쿠키 문제를 줄였고, WebSocket(`/ws`)도 같은 도메인의 `wss://`로 연결됩니다.
Spring은 `forward-headers-strategy: framework`로 프록시 뒤에서도 원래 요청의 HTTPS 정보를 인식합니다.

**4. 개인정보가 없는 초기 데이터**
개발 DB 덤프에서 사용자·플래너·채팅·정산·계좌 등 25개 테이블의 데이터를 제외하고,
공개 콘텐츠(관광지 2,566 · 식당 3,624 · 숙소 466건, 챌린지·지도 템플릿)만 초기 데이터로 사용합니다.
덤프 파일은 깃에 올리지 않고 서버로 직접 복사합니다.

**5. 2GB 서버에서 돌리기**
MySQL 버퍼 풀 128MB, Spring 힙 최대 512MB로 제한하고, 빌드 시 메모리 부족을 막기 위해 4GB 스와프를 추가합니다.

**6. 비밀값 관리**
모든 키는 `.env`(깃 제외)에만 둡니다. JWT·계좌 암호화(AES-256)·내부 API 키는 `scripts/gen-secrets.sh`가 무작위로 생성하고,
비공개 팀 레포 접근용 GitHub 토큰은 디스크에 저장하지 않고 실행할 때만 사용합니다.

## 로컬에서 실행 (Docker Desktop)

```bash
cp .env.example .env
bash scripts/gen-secrets.sh
# .env 수정: APP_DIR=../Yeoback-clone, GEMINI_API_KEY, KAKAO_JS_KEY
# db/init/ 에 초기 데이터 .sql 복사
docker compose up -d --build
# → http://localhost:8088
```

## 서버 배포 (Lightsail)

1. 인스턴스 생성: Ubuntu 22.04, 2GB 이상 / 고정 IP 연결 / 방화벽 80·443 허용
2. 접속 후 준비
   ```bash
   git clone https://github.com/leejiseong20/yeoback-deploy.git && cd yeoback-deploy
   bash scripts/setup-server.sh      # Docker, 스와프 (처음이면 재접속)
   cp .env.example .env && bash scripts/gen-secrets.sh
   nano .env                         # PUBLIC_URL, SITE_ADDRESS, 포트 80/443, 키 입력
   ```
3. 초기 데이터 복사 (내 PC에서): `scp -i <키.pem> content.sql ubuntu@<IP>:~/yeoback-deploy/db/init/01-content.sql`
4. 배포: `bash scripts/deploy.sh` (GitHub 읽기 전용 토큰 입력)

### HTTPS 적용
도메인의 A 레코드를 고정 IP로 지정한 뒤 `.env`를 아래처럼 바꾸고 `bash scripts/deploy.sh`.
```
PUBLIC_URL=https://yeoback.example.com
SITE_ADDRESS=yeoback.example.com
HTTP_PORT=80
HTTPS_PORT=443
```

## 운영 명령어

```bash
docker compose ps                    # 상태
docker compose logs -f backend       # 로그 (backend / ai / web / db)
bash scripts/deploy.sh               # 팀 코드 갱신 후 재배포
docker compose down                  # 중지 (데이터 유지)
docker compose down -v               # 중지 + 데이터 삭제 (초기 데이터부터 다시)
```
