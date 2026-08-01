#!/bin/bash
set -Eeuo pipefail
source /workspace/scripts/lib.bash
begin_evidence "40-storage"

readonly HOST_BIND_DIR="/mnt/host-bind-mount-volume"

trap 'cleanup_container bind-web; cleanup_container volume-before; cleanup_container volume-after' EXIT
for name in bind-web volume-before volume-after; do cleanup_container "$name"; done

section "Two-hop bind mount reflects a real host-side change"
# 실제 호스트 ./bind-mount-source
#   -> outer DinD /mnt/host-bind-mount-volume
#   -> nested NGINX /usr/share/nginx/html
# 세 경로는 같은 파일을 바라본다. index.html은 실행 산출물이라 Git에서 제외한다.
run test -d "$HOST_BIND_DIR"
run cp /workspace/app/index.html "$HOST_BIND_DIR/index.html"
run stat -c '%i %s %n' "$HOST_BIND_DIR/index.html"
run docker run -d --name bind-web -p 8081:80 \
  --mount "type=bind,source=$HOST_BIND_DIR,target=/usr/share/nginx/html,readonly" nginx:1.27-alpine
run wait_for_http http://127.0.0.1:8081/
run curl --fail --silent http://127.0.0.1:8081/
run docker inspect bind-web --format '{{json .Mounts}}'
run sh -c 'printf "<h1>Changed through the host bind mount</h1>\n" > "$1"' _ \
  "$HOST_BIND_DIR/index.html"
run curl --fail --silent http://127.0.0.1:8081/

section "Named volume survives container deletion"
docker volume rm workstation-data >/dev/null 2>&1 || true
run docker volume create workstation-data
run docker run -d --name volume-before \
  --mount type=volume,source=workstation-data,target=/data ubuntu:24.04 sleep infinity
run docker exec volume-before sh -c 'printf "persistent-data\n" > /data/result.txt'
run docker exec volume-before cat /data/result.txt
run docker inspect volume-before --format '{{json .Mounts}}'
run docker rm -f volume-before
run docker run -d --name volume-after \
  --mount type=volume,source=workstation-data,target=/data ubuntu:24.04 sleep infinity
run docker exec volume-after cat /data/result.txt
