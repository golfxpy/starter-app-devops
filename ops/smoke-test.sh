#!/bin/sh
set -eu

base_url="${1:-${SMOKE_BASE_URL:-http://127.0.0.1:8080}}"
base_url="${base_url%/}"
temporary_dir="$(mktemp -d)"
trap 'rm -rf "$temporary_dir"' EXIT INT TERM

command -v curl >/dev/null 2>&1 || {
  echo "curl is required for smoke tests" >&2
  exit 1
}

wait_for_health() {
  attempts="${SMOKE_MAX_ATTEMPTS:-40}"
  while [ "$attempts" -gt 0 ]; do
    status="$(curl --silent --show-error --output "$temporary_dir/health.json" \
      --write-out '%{http_code}' "$base_url/api/health" || true)"
    if [ "$status" = "200" ] && grep -q '"status":"ok"' "$temporary_dir/health.json"; then
      return 0
    fi
    attempts=$((attempts - 1))
    sleep 3
  done
  echo "Application did not become healthy: $base_url/api/health" >&2
  [ -r "$temporary_dir/health.json" ] && cat "$temporary_dir/health.json" >&2
  return 1
}

wait_for_health

frontend_status="$(curl --silent --show-error --output "$temporary_dir/index.html" \
  --write-out '%{http_code}' "$base_url/")"
[ "$frontend_status" = "200" ] || {
  echo "Front-end returned HTTP $frontend_status" >&2
  exit 1
}

activities_status="$(curl --silent --show-error \
  --dump-header "$temporary_dir/activities.headers" \
  --output "$temporary_dir/activities.json" \
  --write-out '%{http_code}' \
  "$base_url/api/activities?page=1&limit=9")"
[ "$activities_status" = "200" ] || {
  echo "Activities endpoint returned HTTP $activities_status" >&2
  exit 1
}
grep -qi '^X-Total-Count:' "$temporary_dir/activities.headers"
grep -q '"data"' "$temporary_dir/activities.json"

detail_status="$(curl --silent --show-error --output "$temporary_dir/activity.json" \
  --write-out '%{http_code}' "$base_url/api/activities/1")"
[ "$detail_status" = "200" ] || {
  echo "Activity detail endpoint returned HTTP $detail_status" >&2
  exit 1
}

registration_status="$(curl --silent --show-error --output "$temporary_dir/registrations.json" \
  --write-out '%{http_code}' "$base_url/api/registrations?activityId=1")"
[ "$registration_status" = "200" ] || {
  echo "Registrations endpoint returned HTTP $registration_status" >&2
  exit 1
}

# ปิดไว้โดยค่าเริ่มต้นเพื่อไม่เพิ่มข้อมูลทดสอบใน Production
if [ "${SMOKE_WRITE_TEST:-false}" = "true" ]; then
  student_id="$(date +%s)"
  write_status="$(curl --silent --show-error --output "$temporary_dir/registration-created.json" \
    --write-out '%{http_code}' \
    --request POST \
    --header 'Content-Type: application/json' \
    --data "{\"fullName\":\"DevOps Smoke Test\",\"studentId\":\"$student_id\",\"faculty\":\"ทดสอบระบบ\",\"email\":\"smoke@example.com\",\"phone\":\"0812345678\",\"activityId\":1,\"consent\":true}" \
    "$base_url/api/registrations")"
  [ "$write_status" = "201" ] || {
    echo "Registration write test returned HTTP $write_status" >&2
    cat "$temporary_dir/registration-created.json" >&2
    exit 1
  }
fi

echo "Smoke tests passed for $base_url"
