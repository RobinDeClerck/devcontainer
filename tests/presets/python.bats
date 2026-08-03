#!/usr/bin/env bats
# tests/presets/python.bats — unit tests for devbase/presets/python.sh
#
# Run from the repo root:
#   bats tests/presets/python.bats

PRESET_SH="$BATS_TEST_DIRNAME/../../devbase/presets/python.sh"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

setup() {
  TEST_DIR="$(mktemp -d)"
  STUB_DIR="$TEST_DIR/bin"
  mkdir -p "$STUB_DIR"

  export CMD_LOG="$TEST_DIR/commands.log"
  : > "$CMD_LOG"

  # Stub gum so tests run without the real binary.
  export GUM_LOG_FILE="$TEST_DIR/gum.log"
  gum() {
    if [[ "$1" == "log" ]]; then
      shift
      echo "$*" >> "$GUM_LOG_FILE"
    fi
  }
  export -f gum

  # The preset runs with $STUB_DIR as its entire PATH so that tool detection
  # depends only on the stubs a test declares, never on what the host happens
  # to have installed. Link in the externals the preset itself needs.
  ln -s "$(command -v grep)" "$STUB_DIR/grep"
  stub python3

  cd "$TEST_DIR" || return 1
}

teardown() {
  cd "$BATS_TEST_DIRNAME" || return 1
  rm -rf "$TEST_DIR"
}

# Write an executable stub that records its invocation to $CMD_LOG.
stub() {
  local name="$1"
  printf '#!%s\necho "%s $*" >> "$CMD_LOG"\n' "$BASH" "$name" > "$STUB_DIR/$name"
  chmod +x "$STUB_DIR/$name"
}

run_preset() {
  run env PATH="$STUB_DIR" "$@" "$BASH" "$PRESET_SH"
}

# ---------------------------------------------------------------------------
# Runtime availability
# ---------------------------------------------------------------------------

@test "python3 missing: fails with a Dockerfile hint" {
  rm "$STUB_DIR/python3"
  run_preset
  [ "$status" -ne 0 ]
  grep -q "python3 not installed" "$GUM_LOG_FILE"
}

@test "no dependency files: warns and installs nothing" {
  run_preset
  [ "$status" -eq 0 ]
  grep -q "no pyproject.toml or requirements file found" "$GUM_LOG_FILE"
  [ ! -s "$CMD_LOG" ]
}

# ---------------------------------------------------------------------------
# requirements files
# ---------------------------------------------------------------------------

@test "requirements.txt: installs with pip" {
  touch requirements.txt
  run_preset
  [ "$status" -eq 0 ]
  grep -q -- "python3 -m pip install --requirement requirements.txt" "$CMD_LOG"
}

@test "requirements-dev.txt takes precedence over requirements.txt" {
  touch requirements.txt requirements-dev.txt
  run_preset
  [ "$status" -eq 0 ]
  grep -q -- "--requirement requirements-dev.txt" "$CMD_LOG"
  ! grep -q -- "--requirement requirements.txt" "$CMD_LOG"
}

# ---------------------------------------------------------------------------
# pyproject.toml
# ---------------------------------------------------------------------------

@test "pyproject.toml with [project]: editable install" {
  printf '[project]\nname = "example"\n' > pyproject.toml
  run_preset
  [ "$status" -eq 0 ]
  grep -q -- "python3 -m pip install --editable ." "$CMD_LOG"
}

@test "pyproject.toml takes precedence over requirements.txt" {
  printf '[project]\nname = "example"\n' > pyproject.toml
  touch requirements.txt
  run_preset
  [ "$status" -eq 0 ]
  grep -q -- "--editable ." "$CMD_LOG"
  ! grep -q -- "--requirement" "$CMD_LOG"
}

@test "pyproject.toml without [project] falls through to requirements.txt" {
  printf '[tool.black]\nline-length = 100\n' > pyproject.toml
  touch requirements.txt
  run_preset
  [ "$status" -eq 0 ]
  grep -q -- "--requirement requirements.txt" "$CMD_LOG"
}

@test "DEVBASE_PYTHON_EXTRAS appends extras to the editable install" {
  printf '[project]\nname = "example"\n' > pyproject.toml
  run_preset DEVBASE_PYTHON_EXTRAS="dev,test"
  [ "$status" -eq 0 ]
  grep -q -- "--editable .\[dev,test\]" "$CMD_LOG"
}

# ---------------------------------------------------------------------------
# uv
# ---------------------------------------------------------------------------

@test "uv.lock with uv installed: runs uv sync" {
  stub uv
  touch uv.lock
  printf '[project]\nname = "example"\n' > pyproject.toml
  run_preset
  [ "$status" -eq 0 ]
  grep -q "uv sync" "$CMD_LOG"
  ! grep -q "pip install" "$CMD_LOG"
}

@test "uv.lock without uv: warns and falls back to pyproject.toml" {
  touch uv.lock
  printf '[project]\nname = "example"\n' > pyproject.toml
  run_preset
  [ "$status" -eq 0 ]
  grep -q "uv is not installed" "$GUM_LOG_FILE"
  grep -q -- "--editable ." "$CMD_LOG"
}

# ---------------------------------------------------------------------------
# poetry
# ---------------------------------------------------------------------------

@test "poetry.lock with poetry installed: runs poetry install" {
  stub poetry
  touch poetry.lock
  run_preset
  [ "$status" -eq 0 ]
  grep -q "poetry install" "$CMD_LOG"
}

@test "[tool.poetry] with poetry installed: runs poetry install" {
  stub poetry
  printf '[tool.poetry]\nname = "example"\n' > pyproject.toml
  run_preset
  [ "$status" -eq 0 ]
  grep -q "poetry install" "$CMD_LOG"
}

@test "poetry.lock without poetry: warns and falls back to requirements.txt" {
  touch poetry.lock requirements.txt
  run_preset
  [ "$status" -eq 0 ]
  grep -q "poetry is not installed" "$GUM_LOG_FILE"
  grep -q -- "--requirement requirements.txt" "$CMD_LOG"
}

# ---------------------------------------------------------------------------
# Failure propagation
# ---------------------------------------------------------------------------

@test "pip failure is logged and surfaced as a non-zero exit" {
  printf '#!%s\nexit 1\n' "$BASH" > "$STUB_DIR/python3"
  chmod +x "$STUB_DIR/python3"
  touch requirements.txt
  run_preset
  [ "$status" -ne 0 ]
}
