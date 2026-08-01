#!/bin/bash
set -Eeuo pipefail
source /workspace/scripts/lib.bash
begin_evidence "00-environment"

section "Operating system and shell"
run cat /etc/os-release
run bash --version

section "Tool versions"
run docker --version
run docker compose version
run git --version

section "Docker daemon"
run docker info
