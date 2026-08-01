#!/bin/bash
set -Eeuo pipefail

readonly SERVICE="workstation"

usage() {
  cat <<'EOF'
Usage: bash lab.bash <command>

  up      Build and start the DinD workstation
  run     Run every documented lab step
  shell   Open an interactive shell in the workstation
  status  Show the outer container status
  down    Stop the workstation while preserving Docker data
  reset   Remove the workstation and its Docker data (destructive)
EOF
}

wait_until_ready() {
  printf 'Waiting for the Docker daemon'
  until docker compose exec -T "$SERVICE" docker info >/dev/null 2>&1; do
    printf '.'
    sleep 1
  done
  printf ' ready\n'
}

command="${1:-}"
case "$command" in
  up)
    docker compose up -d --build
    wait_until_ready
    ;;
  run)
    docker compose up -d --build
    wait_until_ready
    docker compose exec -T "$SERVICE" bash scripts/run-all.bash
    ;;
  shell)
    docker compose exec "$SERVICE" bash
    ;;
  status)
    docker compose ps
    ;;
  down)
    docker compose down
    ;;
  reset)
    printf 'This removes all lab containers, images, and volume data. Type RESET: '
    read -r confirmation
    [[ "$confirmation" == "RESET" ]] || { echo "Cancelled"; exit 1; }
    docker compose down --volumes --remove-orphans
    ;;
  *)
    usage
    exit 1
    ;;
esac
