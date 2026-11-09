#!/usr/bin/env bash
# Build the Bluetooth battery helper used by the WSL-side readers.
#
# The Windows host runs PowerShell in ConstrainedLanguage mode, which blocks
# Add-Type and WinRT method calls. The helper is a native process instead.
#
# The output goes to C:\Windows\Temp because the host's group policy blocks
# unsigned executables from the user profile but allows the Windows folder.
#
# Run this on the Windows (WSL) host after changing battery-helper.cs.
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source_file="$script_dir/battery-helper.cs"

contracts_version="10.0.28000.2957"
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/battery-helper"
nupkg="$cache_dir/microsoft.windows.sdk.contracts.$contracts_version.nupkg"
extract_dir="$cache_dir/contracts-$contracts_version"

csc="/mnt/c/Windows/Microsoft.NET/Framework64/v4.0.30319/csc.exe"
framework64_win='C:\Windows\Microsoft.NET\Framework64\v4.0.30319'
win_temp_wsl="/mnt/c/Windows/Temp"
win_temp_win='C:\Windows\Temp'
winmd_wsl="$win_temp_wsl/dotfiles-battery-build"
winmd_win='C:\Windows\Temp\dotfiles-battery-build'
exe_wsl="$win_temp_wsl/dotfiles-battery-helper.exe"

[[ -f "$source_file" ]] || { echo "missing $source_file" >&2; exit 1; }
[[ -x "$csc" ]] || { echo "missing C# compiler: $csc" >&2; exit 1; }
command -v curl >/dev/null || { echo "missing curl" >&2; exit 1; }
command -v unzip >/dev/null || { echo "missing unzip" >&2; exit 1; }

if ! touch "$win_temp_wsl/.dotfiles-write-test" 2>/dev/null; then
  echo "cannot write $win_temp_wsl (needed by the host's exe policy)" >&2
  exit 1
fi
rm -f "$win_temp_wsl/.dotfiles-write-test"

mkdir -p "$cache_dir"
if [[ ! -f "$nupkg" ]]; then
  echo "downloading Windows SDK contracts $contracts_version" >&2
  curl -fsSL --retry 3 \
    -o "$nupkg" \
    "https://api.nuget.org/v3-flatcontainer/microsoft.windows.sdk.contracts/$contracts_version/microsoft.windows.sdk.contracts.$contracts_version.nupkg"
fi

if [[ ! -d "$extract_dir/ref/netstandard2.0" ]]; then
  echo "extracting Windows SDK contracts" >&2
  mkdir -p "$extract_dir"
  unzip -q -o "$nupkg" 'ref/netstandard2.0/*' -d "$extract_dir"
  [[ -d "$extract_dir/ref/netstandard2.0" ]] || {
    echo "contract package did not contain ref/netstandard2.0" >&2
    exit 1
  }
fi

rm -rf "$winmd_wsl"
mkdir -p "$winmd_wsl"
find "$extract_dir/ref/netstandard2.0" -maxdepth 1 -iname '*.winmd' \
  -exec cp {} "$winmd_wsl/" \;
[[ -n "$(find "$winmd_wsl" -maxdepth 1 -iname '*.winmd' -print -quit)" ]] || {
  echo "no Windows metadata found" >&2
  exit 1
}

cp "$source_file" "$winmd_wsl/dotfiles-battery-helper.cs"
response="$winmd_wsl/dotfiles-battery-helper.rsp"
response_win='C:\Windows\Temp\dotfiles-battery-build\dotfiles-battery-helper.rsp'

{
  for file in "$winmd_wsl"/*.winmd "$winmd_wsl"/*.WinMD; do
    [[ -f "$file" ]] || continue
    printf '/r:%s\\%s\n' "$winmd_win" "$(basename "$file")"
  done
  printf '/r:%s\\System.Runtime.dll\n' "$framework64_win"
  printf '/r:%s\\System.Runtime.WindowsRuntime.dll\n' "$framework64_win"
  printf '/r:%s\\System.Management.dll\n' "$framework64_win"
  printf '/nologo\n/platform:x64\n/target:exe\n'
  printf '/out:%s\\dotfiles-battery-helper.exe\n' "$win_temp_win"
  printf '%s\\dotfiles-battery-helper.cs\n' "$winmd_win"
} > "$response"

"$csc" "@$response_win"

rm -rf "$winmd_wsl"

[[ -f "$exe_wsl" ]] || { echo "build failed: no $exe_wsl" >&2; exit 1; }
echo "$exe_wsl"
