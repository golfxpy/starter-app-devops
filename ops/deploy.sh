#!/bin/sh
set -eu

: "${IMAGE_TAG:?IMAGE_TAG must identify an immutable image tag}"

command -v docker >/dev/null 2>&1 || {
  echo "docker is required" >&2
  exit 1
}
command -v curl >/dev/null 2>&1 || {
  echo "curl is required" >&2
  exit 1
}

state_dir="${DEPLOY_STATE_DIR:-.deploy}"
state_file="$state_dir/current-image-tag"
mkdir -p "$state_dir"

previous_tag=""
if [ -r "$state_file" ]; then
  previous_tag="$(cat "$state_file")"
fi

if [ -n "$previous_tag" ] && [ "${PRE_DEPLOY_BACKUP:-true}" = "true" ]; then
  echo "Creating a pre-deployment backup"
  docker compose --profile backup run --rm backup backup.sh
fi

deploy_current_tag() {
  if [ "${DEPLOY_PULL:-true}" = "true" ]; then
    docker compose pull
  fi
  docker compose up -d --no-build --remove-orphans --wait --wait-timeout "${DEPLOY_WAIT_SECONDS:-180}"
  sh ops/smoke-test.sh "${SMOKE_BASE_URL:-http://127.0.0.1:${APP_HTTP_PORT:-8080}}"
}

echo "Deploying immutable image tag: $IMAGE_TAG"
if deploy_current_tag; then
  temporary_state="${state_file}.tmp.$$"
  printf '%s\n' "$IMAGE_TAG" > "$temporary_state"
  mv "$temporary_state" "$state_file"
  echo "Deployment completed: $IMAGE_TAG"
  exit 0
fi

echo "Deployment failed for tag: $IMAGE_TAG" >&2
if [ -z "$previous_tag" ]; then
  echo "No previous image tag is available for rollback" >&2
  exit 1
fi

echo "Rolling back to: $previous_tag" >&2
IMAGE_TAG="$previous_tag"
export IMAGE_TAG
if deploy_current_tag; then
  echo "Rollback completed: $previous_tag" >&2
else
  echo "Rollback also failed; manual intervention is required" >&2
fi
exit 1
