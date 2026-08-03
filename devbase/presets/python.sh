#!/usr/bin/env bash
# python preset: install project dependencies on attach.
#
# Dependency source resolution, first match wins:
#   1. uv.lock                       -> uv sync
#   2. poetry.lock / [tool.poetry]   -> poetry install
#   3. pyproject.toml with [project] -> pip install -e .
#   4. requirements-dev.txt          -> pip install -r
#   5. requirements.txt              -> pip install -r
#
# Reads: DEVBASE_PYTHON_EXTRAS (comma-separated extras for the pyproject.toml
# path, e.g. "dev,test" -> pip install -e ".[dev,test]")

set -uo pipefail

log() {
  local level="$1"
  shift
  gum log --time rfc822 --level "$level" "$@"
}

# Diagnostics go to stderr, matching gum log, so that stdout stays free as the
# return channel for functions like detect_source.
hint() {
  gum style --foreground 245 "  $1" >&2
}

has() {
  command -v "$1" >/dev/null 2>&1
}

# Match a top-level TOML table header, tolerating leading whitespace.
has_table() {
  local table="$1" file="$2"
  [ -f "$file" ] && grep -qE "^[[:space:]]*\[$table\]" "$file"
}

require_pip() {
  if python3 -m pip --version >/dev/null 2>&1; then
    return 0
  fi
  log error "pip not installed, add to your .devcontainer/Dockerfile:"
  hint 'RUN apk add --no-cache py3-pip'
  return 1
}

run_install() {
  local label="$1"
  shift

  log info "installing dependencies ($label)..."
  if "$@"; then
    log info "installed dependencies ($label)"
  else
    log error "$label failed"
    return 1
  fi
}

# Echo the name of the first applicable dependency source, or nothing when the
# project has none. Tools that are declared but not installed are reported here
# so the resolution below stays a straight mapping from source to command.
detect_source() {
  if [ -f uv.lock ]; then
    if has uv; then
      echo uv
      return 0
    fi
    log warn "uv.lock found but uv is not installed, add to your .devcontainer/Dockerfile:"
    hint 'RUN apk add --no-cache uv'
  fi

  if [ -f poetry.lock ] || has_table 'tool\.poetry' pyproject.toml; then
    if has poetry; then
      echo poetry
      return 0
    fi
    log warn "poetry project found but poetry is not installed, add to your .devcontainer/Dockerfile:"
    hint 'RUN apk add --no-cache poetry'
  fi

  if has_table 'project' pyproject.toml; then
    echo pyproject
    return 0
  fi

  if [ -f requirements-dev.txt ]; then
    echo requirements-dev
    return 0
  fi

  if [ -f requirements.txt ]; then
    echo requirements
    return 0
  fi
}

install_pyproject() {
  local target="."
  local extras="${DEVBASE_PYTHON_EXTRAS:-}"

  [ -n "$extras" ] && target=".[$extras]"

  require_pip || return 1
  run_install "pyproject.toml" python3 -m pip install --editable "$target"
}

install_requirements() {
  local file="$1"

  require_pip || return 1
  run_install "$file" python3 -m pip install --requirement "$file"
}

main() {
  if ! has python3; then
    log error "python3 not installed, add to your .devcontainer/Dockerfile:"
    hint 'RUN apk add --no-cache python3 py3-pip'
    return 1
  fi

  local source
  source="$(detect_source)"

  case "$source" in
    uv)               run_install "uv.lock" uv sync ;;
    poetry)           run_install "poetry" poetry install ;;
    pyproject)        install_pyproject ;;
    requirements-dev) install_requirements requirements-dev.txt ;;
    requirements)     install_requirements requirements.txt ;;
    *)                log warn "no pyproject.toml or requirements file found" ;;
  esac
}

main "$@"
