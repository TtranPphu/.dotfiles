#!/usr/bin/env bash
# Output the date if there's room on the right, nothing otherwise.
set -euo pipefail

dir=$(pwd)
home=$HOME
config_dir="${STARSHIP_CONFIG%/*}"

compressed=$("$config_dir/compress-path.sh" 2>/dev/null || echo "$dir")
path_len=${#compressed}

branch=
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git branch --show-current 2>/dev/null || true)
fi
branch_len=${#branch}

# Left: os(3) + shell(6) + path + git_remote(3) + branch + git_status(6) + spaces(5)
left=$((23 + path_len + 3 + branch_len + 6))

# Count active lang modules (each ~9: space + icon + space + version)
l=0
for pattern in 'CMakeLists.txt *.c *.h *.cpp *.hpp' '*.java' '*.kt' '*.lua' '*.py' Cargo.toml; do
  for f in $pattern; do [[ -f $f ]] && { l=$((l + 1)); break; }; done 2>/dev/null
done

# Right sans date: active langs + cmd_duration(~7) + clock(~14) + battery(~8)
right=$((l * 9 + 29))
date=18  # " [󰃭 %y/%m/%d %a]" ≈ 18

cols=${COLUMNS:-$(stty size < /dev/tty 2>/dev/null | cut -d' ' -f2 || tput cols 2>/dev/null || echo 80)}
if ((cols - left >= right + date)); then
  date +'%y/%m/%d %a'
fi
