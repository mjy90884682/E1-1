#!/bin/bash
set -Eeuo pipefail
source /workspace/scripts/lib.bash
begin_validation "10-cli-and-permissions"

# 매번 같은 결과를 얻도록 격리된 임시 디렉터리를 새로 만든다.
demo_dir="$(mktemp -d /tmp/workstation-cli.XXXXXX)"
trap 'rm -rf "$demo_dir"' EXIT

section "Navigation and file operations"
run pwd
run ls -la
run mkdir -p "$demo_dir/source" "$demo_dir/archive"
run touch "$demo_dir/source/empty.txt"
run sh -c 'printf "reproducible\n" > "$1"' _ "$demo_dir/source/note.txt"
run cat "$demo_dir/source/note.txt"
run cp "$demo_dir/source/note.txt" "$demo_dir/archive/copy.txt"
run mv "$demo_dir/archive/copy.txt" "$demo_dir/archive/renamed.txt"
run ls -la "$demo_dir/archive"
run rm "$demo_dir/source/empty.txt"
run sh -c 'cd "$1" && pwd && ls -la ../archive' _ "$demo_dir/source"

section "File permission: 600 to 644"
run chmod 600 "$demo_dir/source/note.txt"
run stat -c '%A %a %n' "$demo_dir/source/note.txt"
run chmod 644 "$demo_dir/source/note.txt"
run stat -c '%A %a %n' "$demo_dir/source/note.txt"

section "Directory permission: 700 to 755"
run chmod 700 "$demo_dir/archive"
run stat -c '%A %a %n' "$demo_dir/archive"
run chmod 755 "$demo_dir/archive"
run stat -c '%A %a %n' "$demo_dir/archive"
