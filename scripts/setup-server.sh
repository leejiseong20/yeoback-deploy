#!/usr/bin/env bash
# Lightsail(Ubuntu 22.04/24.04) 최초 1회 설정: Docker 설치 + 스와프 메모리
set -euo pipefail

if ! command -v docker >/dev/null; then
  echo "Docker 설치 중..."
  curl -fsSL https://get.docker.com | sudo sh
  sudo usermod -aG docker "$USER"
  echo "→ docker 그룹 적용을 위해 접속을 끊었다가 다시 접속하세요."
fi

# 2GB 서버에서 Spring·Expo 빌드 시 메모리가 부족하지 않도록 4GB 스와프 추가
if ! swapon --show | grep -q /swapfile; then
  echo "스와프 4GB 생성 중..."
  sudo fallocate -l 4G /swapfile
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  sudo swapon /swapfile
  echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab >/dev/null
  echo 'vm.swappiness=10' | sudo tee /etc/sysctl.d/99-swap.conf >/dev/null
  sudo sysctl -p /etc/sysctl.d/99-swap.conf >/dev/null
fi

sudo timedatectl set-timezone Asia/Seoul
echo "서버 준비 완료"
free -h
