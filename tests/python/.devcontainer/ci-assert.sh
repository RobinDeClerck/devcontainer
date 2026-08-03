#!/usr/bin/env bash
# ci-assert.sh — run inside the container after postAttachCommand to verify
# that terminal executed correctly. Exits non-zero on any failure.
set -euo pipefail

PASS=0
FAIL=0

assert() {
  local description="$1"
  local command="$2"
  if eval "$command" &>/dev/null; then
    echo "  PASS  $description"
    PASS=$((PASS + 1))
  else
    echo "  FAIL  $description"
    FAIL=$((FAIL + 1))
  fi
}

echo ""
echo "devcontainer assertions"
echo "-----------------------"

# core binaries
assert "terminal is on PATH" "command -v terminal"
assert "gum is on PATH"      "command -v gum"
assert "starship is on PATH" "command -v starship"

# hooks ran and wrote to the shared log
assert "pre-attach hook ran"  "grep -q 'hello from pre attach script'  /tmp/devbase-ci.log"
assert "post-attach hook ran" "grep -q 'hello from post attach script' /tmp/devbase-ci.log"

# sysinfo box rendered
assert "sysinfo box rendered" "grep -q 'system info' /tmp/devbase-ci.log"

# preset resolved requirements-dev.txt and pip installed it despite PEP 668
assert "python preset ran"          "grep -q 'requirements-dev.txt' /tmp/devbase-ci.log"
assert "dependencies installed"     "python3 -c 'import rich, httpx, pydantic'"
assert "pip not blocked by PEP 668" "! grep -q 'externally-managed-environment' /tmp/devbase-ci.log"

echo "-----------------------"
echo "  ${PASS} passed, ${FAIL} failed"
echo ""

(( FAIL == 0 ))
