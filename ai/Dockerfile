# syntax=docker/dockerfile:1
# Python AI 서버 — 팀 레포의 YeoBack-AI를 additional context "app"으로 받음
FROM python:3.12-slim
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY --from=app . .
# 로컬 개발용 .env(개인 키)와 데이터 수집 스크립트는 이미지에서 제외
RUN rm -rf .env dbData __pycache__
# 팀 코드에 고정된 gemini-2.5-flash는 신규 API 키에서 더 이상 제공되지 않음
# → 빌드 시점에만 모델명을 교체 (팀 레포 원본은 수정하지 않음)
ARG GEMINI_MODEL=gemini-3.8-flash
RUN sed -i "s/gemini-2\.5-flash/${GEMINI_MODEL}/g" *.py \
 && ! grep -rn "gemini-2\.5-flash" *.py
EXPOSE 8001
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8001"]
