#!/usr/bin/env bash
# Detected language versions: live scan with timeout + last-known-good cache.
#
#   language-util.sh             -> live scan, bounded by FETCH_LIVE_TIMEOUT
#                                   (fetch-cache.sh):
#                                     exit 0: live value printed (and stored)
#                                     exit 3: live timed out/failed; the last
#                                             known good value is printed (stale)
#                                     exit 1: nothing to show (no language
#                                             markers, or a timeout with no
#                                             cached value)
#   language-util.sh --fresh     -> internal: the unbounded probe
#   language-util.sh --detected  -> exit 0 when this directory has language markers
#   language-util.sh --has-value -> exit 0 when a cached value exists
#
# Output lines are "<lang> <version>"; version is empty when the probe found
# none (the render then shows the bare icon).
set -euo pipefail

# Resolve this script through symlinks (stow links it into consumers) so the
# shared fetch-cache engine next to the real file is found.
script_dir="${BASH_SOURCE[0]:-}"
script_dir="$(readlink -f -- "$script_dir" 2>/dev/null || true)"
script_dir="${script_dir%/*}"
[ -n "$script_dir" ] || script_dir=.
[ -f "$script_dir/fetch-cache.sh" ] && source "$script_dir/fetch-cache.sh"

# First version-like token in the tool's output (stdout + stderr).
version_of() {
  local out
  out="$("$@" 2>&1)" || true
  if [[ $out =~ [0-9]+(\.[0-9]+)+ ]]; then
    printf '%s' "${BASH_REMATCH[0]}"
  fi
}

has_ext() {
  local f
  for f in *."$1"; do
    [ -f "$f" ] && return 0
  done
  return 1
}

# Same markers as the former built-in language modules.
detect() {
  local f
  case "$1" in
    c)
      [ -f CMakeLists.txt ] && return 0
      for f in c h cpp hpp; do has_ext "$f" && return 0; done
      ;;
    java)
      for f in pom.xml build.gradle.kts build.sbt .java-version deps.edn project.clj build.boot .sdkmanrc; do
        [ -f "$f" ] && return 0
      done
      for f in java class gradle jar cljs cljc; do has_ext "$f" && return 0; done
      ;;
    kotlin)
      for f in kt kts; do has_ext "$f" && return 0; done
      ;;
    lua)
      [ -f .lua-version ] && return 0
      has_ext lua && return 0
      [ -d lua ] && return 0
      ;;
    python)
      for f in .python-version Pipfile __init__.py pyproject.toml requirements.txt setup.py tox.ini; do
        [ -f "$f" ] && return 0
      done
      for f in py ipynb; do has_ext "$f" && return 0; done
      ;;
    rust)
      [ -f Cargo.toml ] && return 0
      has_ext rs && return 0
      ;;
  esac
  return 1
}

version_of_lang() {
  case "$1" in
    c) version_of cc --version ;;
    java) version_of java -version ;;
    kotlin) version_of kotlin -version ;;
    lua) version_of lua -v ;;
    python) version_of python3 --version ;;
    rust) version_of rustc --version ;;
  esac
}

fetch_langs() {
  local lang version
  for lang in c java kotlin lua python rust; do
    detect "$lang" || continue
    version=$(version_of_lang "$lang")
    printf '%s %s\n' "$lang" "$version"
  done
}

case "${1:-}" in
  --fresh) fetch_langs ;;
  --detected)
    for lang in c java kotlin lua python rust; do
      detect "$lang" && exit 0
    done
    exit 1
    ;;
  --has-value) fetch_has_value "$(fetch_cache_path lang "$(fetch_cache_cwd)")" ;;
  *) fetch_live "$(fetch_cache_path lang "$(fetch_cache_cwd)")" "$0" --fresh ;;
esac
