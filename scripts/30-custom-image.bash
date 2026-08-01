#!/bin/bash
set -Eeuo pipefail
source /workspace/scripts/lib.bash
begin_evidence "30-custom-image"

# 성공 후 실제 호스트의 http://localhost:8080에서 브라우저 증거를 수집할 수 있도록
# 이 컨테이너는 유지한다. 다음 실행 시작 시 같은 이름의 이전 컨테이너를 정리한다.
cleanup_container workstation-web

section "Build custom NGINX image"
run docker build --tag workstation-web:1.0 /workspace/app
run docker image inspect workstation-web:1.0 \
  --format 'base-derived image={{.RepoTags}} exposed={{json .Config.ExposedPorts}}'

section "Run with host-to-container port mapping"
# outer container의 8080은 Compose가 실제 호스트의 8080으로 다시 전달한다.
run docker run -d --name workstation-web -p 8080:8080 workstation-web:1.0
run docker ps --filter name=workstation-web

run wait_for_http http://127.0.0.1:8080/
run curl --fail --show-error http://127.0.0.1:8080/
run docker logs workstation-web
run docker stats --no-stream workstation-web
