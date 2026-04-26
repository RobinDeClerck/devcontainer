#!/usr/bin/env bash

if ! command -v npm >/dev/null 2>&1; then
  gum log --time rfc822 --level error "npm not installed — add to your .devcontainer/Dockerfile:"
  gum style --foreground 245 '  RUN apk add --no-cache npm'
  exit 0
fi

if [ ! -f package.json ]; then
  gum log --time rfc822 --level warn "no package.json found"
  exit 0
fi

gum log --time rfc822 --level info "found package.json"

if [ -f package-lock.json ]; then
  echo "installing dependencies (npm ci)..."
  npm ci --silent || { gum log --time rfc822 --level error "npm ci failed"; exit 1; }
else
  echo "installing dependencies (npm install)..."
  npm install --silent || { gum log --time rfc822 --level error "npm install failed"; exit 1; }
fi