#!/bin/bash

begin_validation() {
  local name="$1"
  printf '# Validation: %s\n' "$name"
}

section() {
  printf '\n## %s\n' "$1"
}

# 실행형 문서와 CI 출력에서 명령과 결과를 함께 읽을 수 있게 한다. 인수는 셸에서
# 이미 분리된 상태로 전달하므로 문자열 eval을 사용하지 않는다.
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
