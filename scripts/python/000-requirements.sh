#!/bin/sh
set -e

REQ_DEV="requirements-dev.txt"
REQ="requirements.txt"

if [ -f "$REQ_DEV" ]; then
  echo "📦 Installing from $REQ_DEV"
  pip install -r "$REQ_DEV"
elif [ -f "$REQ" ]; then
  echo "📦 $REQ_DEV not found, installing from $REQ"
  pip install -r "$REQ"
else
  echo "⚠️  No requirements file found."
fi
