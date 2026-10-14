#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/nerd-font.sh"

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

case "${1:-}" in
  --guard)
    for lang in c java kotlin lua python rust; do
      detect "$lang" && exit 0
    done
    exit 1
    ;;
esac

segments=()
for lang in c java kotlin lua python rust; do
  detect "$lang" || continue
  icon="$(nerd_font_icon "lang.$lang")"
  version="$(version_of_lang "$lang")"
  if [ -n "$version" ]; then
    segments+=("${icon}v${version}")
  else
    segments+=("${icon% }")
  fi
done

if [ ${#segments[@]} -gt 0 ]; then
  printf '%s\n' "${segments[*]}"
fi
