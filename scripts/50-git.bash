#!/bin/bash
set -Eeuo pipefail
source /workspace/scripts/lib.bash
begin_validation "50-git"

section "Disposable workstation Git configuration"
# 실제 제출 전 LAB_GIT_NAME/LAB_GIT_EMAIL을 .env로 주입할 수 있다.
# 기본 이메일은 예약 TLD(.invalid)를 사용해 개인 정보를 만들거나 노출하지 않는다.
# DinD의 root와 호스트 작업트리 소유자가 다르므로 격리된 마운트 지점만 허용한다.
run git config --global --replace-all safe.directory /workspace
run git config --global user.name "${LAB_GIT_NAME:?}"
run git config --global user.email "${LAB_GIT_EMAIL:?}"
run git config --global init.defaultBranch main

# 전체 설정 대신 과제에서 요구하는 키만 출력한다.
run git config --global --get user.name
run git config --global --get user.email
run git config --global --get init.defaultBranch
run git config --global --list

section "Repository and remote"
run git status --short --branch
if git remote get-url origin >/dev/null 2>&1; then
  run git remote -v
else
  echo "No origin remote yet; add the GitHub repository before final evidence collection."
fi
