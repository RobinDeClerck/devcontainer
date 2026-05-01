#!/usr/bin/env bash

if ! command -v npm >/dev/null 2>&1; then
  gum log --time rfc822 --level error "npm not installed — add to your .devcontainer/Dockerfile:"
  gum style --foreground 245 '  RUN apk add --no-cache npm'
  exit 1
fi

if [ ! -f package.json ]; then
  gum log --time rfc822 --level warn "no package.json found"
fi

if [ -f package.json ]; then
  if [ -f package-lock.json ]; then
    cmd="npm ci"
  else
    cmd="npm install"
  fi

  gum log --time rfc822 --level info "installing dependencies ($cmd)..."
  if $cmd; then
    gum log --time rfc822 --level info "installed node_modules"
  else
    gum log --time rfc822 --level error "$cmd failed"
  fi
fi