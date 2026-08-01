#!/bin/bash
set -Eeuo pipefail
source /workspace/scripts/lib.bash
begin_evidence "20-docker-basics"
for name in lab-hello lab-ubuntu-once lab-ubuntu; do cleanup_container "$name"; done

trap 'cleanup_container lab-hello; cleanup_container lab-ubuntu-once; cleanup_container lab-ubuntu' EXIT

section "Installation and daemon"
run docker --version
run docker info

section "hello-world image and container"
run docker pull hello-world:latest
run docker run --name lab-hello hello-world:latest
run docker logs lab-hello
run docker images
run docker ps
run docker ps -a
cleanup_container lab-hello

section "Ubuntu: foreground run versus exec on a running container"
# foreground `docker run`의 주 프로세스가 끝나면 컨테이너도 종료된다.
run docker run --name lab-ubuntu-once ubuntu:24.04 \
  bash -lc 'echo "foreground process"; ls / | head'
run docker ps -a --filter name=lab-ubuntu-once
cleanup_container lab-ubuntu-once

# 장기 실행 중인 주 프로세스가 있을 때 exec는 별도 프로세스를 추가한다.
run docker run -d --name lab-ubuntu ubuntu:24.04 sleep infinity
run docker exec lab-ubuntu bash -lc 'echo "exec process"; pwd; ls / | head'
run docker stats --no-stream lab-ubuntu
run docker stop lab-ubuntu
run docker ps -a --filter name=lab-ubuntu
