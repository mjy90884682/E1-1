#!/bin/bash
set -Eeuo pipefail

cd /workspace

steps=(
  scripts/00-environment.bash
  scripts/10-cli-and-permissions.bash
  scripts/20-docker-basics.bash
  scripts/30-custom-image.bash
  scripts/40-storage.bash
  scripts/50-git.bash
  scripts/60-browser-evidence.bash
)

for step in "${steps[@]}"; do
  printf '\n===== %s =====\n' "$step"
  bash "$step"
done

printf '\nAll automated checks passed. Runtime artifacts are in .local/evidence/.\n'
