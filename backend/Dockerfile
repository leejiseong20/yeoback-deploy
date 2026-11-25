# syntax=docker/dockerfile:1
# Spring Boot 빌드 — 팀 레포의 YeoBack-BE를 additional context "app"으로 받음
FROM eclipse-temurin:21-jdk AS build
WORKDIR /src
COPY --from=app . .
# Windows에서 받은 코드면 gradlew 줄바꿈이 CRLF라 리눅스에서 실행이 안 됨
RUN sed -i 's/\r$//' gradlew && chmod +x gradlew \
 && ./gradlew --no-daemon -q bootJar -x test \
 && find build/libs -name '*.jar' ! -name '*-plain.jar' -exec cp {} /app.jar \;

FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=build /app.jar /app/app.jar
RUN mkdir -p /app/uploads
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
