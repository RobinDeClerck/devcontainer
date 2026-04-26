#!/usr/bin/env bash

if ! command -v pip >/dev/null 2>&1; then
  gum log --time rfc822 --level error "pip not installed — add to .devcontainer/devcontainer.json:"
  gum style --foreground 245 '  "ghcr.io/devcontainers/features/python:1": {}'
  exit 0
fi

if [ -f requirements-dev.txt ]; then
  gum log --time rfc822 --level info "found requirements-dev.txt"
  gum spin --spinner dot --title "installing requirements-dev.txt" -- \
    pip install -q -r requirements-dev.txt
elif [ -f requirements.txt ]; then
  gum log --time rfc822 --level info "found requirements.txt"
  gum spin --spinner dot --title "installing requirements.txt" -- \
    pip install -q -r requirements.txt
else
  gum log --time rfc822 --level warn "no requirements file found"
fi