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

# The attached workspace exercises the requirements path, so build a throwaway
# PEP 621 project to cover the pyproject.toml path in the same image.
TOML_PROJECT="$(mktemp -d)"
trap 'rm -rf "$TOML_PROJECT"' EXIT

mkdir -p "$TOML_PROJECT/src/devbase_toml_example"
touch "$TOML_PROJECT/src/devbase_toml_example/__init__.py"
cat > "$TOML_PROJECT/pyproject.toml" << 'EOF'
[project]
name = "devbase-toml-example"
version = "0.1.0"

[build-system]
requires = ["setuptools>=61"]
build-backend = "setuptools.build_meta"
EOF

assert "pyproject.toml preset path installs" \
  "(cd '$TOML_PROJECT' && bash /usr/local/share/devbase/presets/python.sh) && python3 -c 'import devbase_toml_example'"

echo "-----------------------"
echo "  ${PASS} passed, ${FAIL} failed"
echo ""

(( FAIL == 0 ))
