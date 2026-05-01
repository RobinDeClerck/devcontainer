#!/usr/bin/env bash

if ! command -v pip >/dev/null 2>&1; then
  gum log --time rfc822 --level error "pip not installed — add to your .devcontainer/Dockerfile:"
  gum style --foreground 245 '  RUN apk add --no-cache python3 py3-pip'
  exit 1
fi

req_file=""
if [ -f requirements-dev.txt ]; then
  req_file="requirements-dev.txt"
elif [ -f requirements.txt ]; then
  req_file="requirements.txt"
else
  gum log --time rfc822 --level warn "no requirements file found"
fi

if [ -n "$req_file" ]; then
  gum log --time rfc822 --level info "installing $req_file..."
  if pip install -r "$req_file"; then
    gum log --time rfc822 --level info "installed $req_file"
  else
    gum log --time rfc822 --level error "pip install failed"
  fi
fi