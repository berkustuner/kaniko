#!/usr/bin/env bash
set -Eeuo pipefail

# --- Zorunlu environment değişkenleri kontrol ---
: "${CONTEXT_HOST_PATH:?CONTEXT_HOST_PATH gerekli (örn: /home/ubuntu/kaniko-example)}"
: "${HOST_DOCKER_CONFIG:?HOST_DOCKER_CONFIG gerekli (örn: /home/ubuntu/.docker)}"
: "${DOCKERFILE:=Dockerfile}"
: "${IMAGE_NAME:?IMAGE_NAME gerekli (örn: 10.10.8.13/demo/deneme-image)}"
: "${TAG:?TAG gerekli (örn: build-42)}"

# --- Mount'lar çalışıyor mu test et ---
docker run --rm -v "${CONTEXT_HOST_PATH}:/x:ro" alpine ls -la /x >/dev/null
docker run --rm -v "${HOST_DOCKER_CONFIG}:/y:ro" alpine ls -la /y >/dev/null

# --- Kaniko ile build & push ---
docker run --rm --network host \
  -v "${CONTEXT_HOST_PATH}:/workspace" \
  -v "${HOST_DOCKER_CONFIG}:/kaniko/.docker:ro" \
  gcr.io/kaniko-project/executor:latest \
  --dockerfile="/workspace/${DOCKERFILE}" \
  --context=dir:///workspace \
  --destination="${IMAGE_NAME}:${TAG}" \
  --insecure --insecure-pull --skip-tls-verify

echo "✅ Pushed: ${IMAGE_NAME}:${TAG}"

