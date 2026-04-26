#!/usr/bin/env bash

if ! command -v pip >/dev/null 2>&1; then
  gum log --time rfc822 --level error "pip not installed — add to your .devcontainer/Dockerfile:"
  gum style --foreground 245 '  RUN apk add --no-cache python3 py3-pip'
  exit 0
fi

if [ -f requirements-dev.txt ]; then
  gum log --time rfc822 --level info "found requirements-dev.txt"
  echo "installing requirements-dev.txt..."
  pip install -q -r requirements-dev.txt || { gum log --time rfc822 --level error "pip install failed"; exit 1; }
elif [ -f requirements.txt ]; then
  gum log --time rfc822 --level info "found requirements.txt"
  echo "installing requirements.txt..."
  pip install -q -r requirements.txt || { gum log --time rfc822 --level error "pip install failed"; exit 1; }
else
  gum log --time rfc822 --level warn "no requirements file found"
fi