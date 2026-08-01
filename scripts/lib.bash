#!/bin/bash

readonly REPO_ROOT="/workspace"
readonly EVIDENCE_DIR="$REPO_ROOT/evidence/logs"

begin_evidence() {
  local name="$1"
  mkdir -p "$EVIDENCE_DIR"
  exec > >(tee "$EVIDENCE_DIR/$name.log") 2>&1
  printf '# Generated at %s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
}

section() {
  printf '\n## %s\n' "$1"
}

# 명령과 출력을 같은 로그에 남긴다. 인수는 셸에서 이미 분리된 상태로 전달하므로
# 문자열 eval을 사용하지 않는다.
run() {
  printf '\n$'
  printf ' %q' "$@"
  printf '\n'
  "$@"
}

cleanup_container() {
  docker rm -f "$1" >/dev/null 2>&1 || true
}

wait_for_http() {
  local url="$1"
  local attempts="${2:-20}"

  for ((attempt = 1; attempt <= attempts; attempt++)); do
    if curl --fail --silent --show-error --output /dev/null "$url"; then
      printf 'HTTP endpoint ready after %d attempt(s): %s\n' "$attempt" "$url"
      return 0
    fi
    sleep 1
  done

  printf 'HTTP endpoint did not become ready: %s\n' "$url" >&2
  return 1
}
