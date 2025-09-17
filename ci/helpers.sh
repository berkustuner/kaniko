#!/usr/bin/env bash
set -Eeuo pipefail

log(){ echo "[$(date +'%F %T')] $*"; }

service_exists() {
  local svc="$1"
  docker service ls --format '{{.Name}}' | grep -wq "^${svc}$"
}

ensure_network() {
  local net="$1"
  if ! docker network inspect "$net" >/dev/null 2>&1; then
    log "Creating overlay network: $net"
    docker network create --driver overlay "$net"
  else
    log "Network exists: $net"
  fi
}

# Serviste secret yoksa --secret-add döndür, varsa boş döndür
secret_arg_if_missing() {
  local service="$1" secret="$2" target="$3"
  if docker service inspect "$service" \
      --format '{{json .Spec.TaskTemplate.ContainerSpec.Secrets}}' 2>/dev/null \
      | grep -q "\"SecretName\":\"${secret}\""; then
    echo ""
  else
    echo "--secret-add source=${secret},target=${target}"
  fi
}

# Serviste belirli bir ENV varsa --env-rm döndür, yoksa boş
env_rm_if_present() {
  local service="$1" var="$2"
  if docker service inspect "$service" \
      --format '{{json .Spec.TaskTemplate.ContainerSpec.Env}}' 2>/dev/null \
      | grep -q "\"${var}="; then
    echo "--env-rm ${var}"
  else
    echo ""
  fi
}

