#!/bin/sh
if [ -f "package.json" ]; then
  npm install
else
  echo "⚠️  No package.json found. Skipping npm install..."
fi