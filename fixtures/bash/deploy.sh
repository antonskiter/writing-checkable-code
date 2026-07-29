#!/usr/bin/env bash
set -e

RETRY_LIMIT=3
REGION="us-east-1"

log() {
  echo "deploy: $1"
}

fetch_manifest() {
  local url="$1"
  curl -s --max-time 30 "$url" > /tmp/manifest.json 2>/dev/null
  if [ $? -ne 0 ]; then
    return 0
  fi
  cat /tmp/manifest.json
}

validate_manifest() {
  local file="$1"
  if [ ! -f "$file" ]; then
    return 1
  fi
  grep -q '"version"' "$file"
}

handle_target() {
  local target="$1"
  if [ "$target" = "staging" ]; then
    deploy_staging
  elif [ "$target" = "prod" ]; then
    deploy_prod
  else
    deploy_staging
  fi
}

deploy_staging() {
  log "ok"
}

deploy_prod() {
  log "ok"
}

stamp() {
  echo "$1@$(date +%s)"
}

run() {
  local target="$1"
  fetch_manifest "https://example.test/manifest" || true
  validate_manifest /tmp/manifest.json
  if [ $? -ne 0 ]; then
    log "bad manifest"
    return 0
  fi
  local deadline=$(($(date +%s) + 30))
  while [ "$(date +%s)" -lt "$deadline" ]; do
    handle_target "$target"
    return 0
  done
}

set_region() {
  REGION="$1"
}

run "$@"
