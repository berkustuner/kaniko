#!/usr/bin/env bash
set -Eeuo pipefail

IMAGE="$1"
SERVICE="app_stack_web"
NET="app_net"

SECRET_NAME="pg_password"
SECRET_TARGET="pg_password"
DB_PASS_FILE_PATH="/run/secrets/pg_password"

# network yoksa oluştur
if ! docker network inspect "$NET" >/dev/null 2>&1; then
  echo "Creating overlay network: $NET"
  docker network create --driver overlay "$NET"
fi

# servis varsa UPDATE, yoksa CREATE
if docker service ls --format '{{.Name}}' | grep -wq "^${SERVICE}$"; then
  echo "Updating service: $SERVICE"
  docker service update \
    --with-registry-auth \
    --update-order stop-first \
    --update-parallelism 1 \
    --image "$IMAGE" \
    $SERVICE
else
  echo "Creating service: $SERVICE"
  docker service create --name $SERVICE --replicas 3 \
    --constraint 'node.labels.role_app==true' \
    --publish mode=host,target=5000,published=5000 \
    --network $NET \
    --with-registry-auth \
    --env JWT_SECRET_FILE=/run/secrets/jwt_secret \
    --secret source=jwt_secret,target=jwt_secret \
    --secret source=app_user,target=app_user \
    --secret source=app_pass,target=app_pass \
    --env APP_USER_FILE=/run/secrets/app_user \
    --env APP_PASS_FILE=/run/secrets/app_pass \
    --env DB_HOST=db_stack_db \
    --env DB_USER=postgres \
    --env DB_NAME=postgres \
    --env DB_PASS_FILE="${DB_PASS_FILE_PATH}" \
    --secret source=${SECRET_NAME},target=${SECRET_TARGET} \
    "$IMAGE"
fi

