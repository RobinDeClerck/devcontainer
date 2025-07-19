#!/bin/sh
set -e

REQ_DEV="requirements-dev.txt"
REQ="requirements.txt"

# We have to use --break-system-packages as PEP 668 doesnt allow you to use pip outside of a virtual environment
# as we are already in a devcontainer environment it doesnt make much sense to create another environment
if [ -f "$REQ_DEV" ]; then
  echo "📦 Installing from $REQ_DEV"
  pip install --break-system-packages -r "$REQ_DEV"
elif [ -f "$REQ" ]; then
  echo "📦 $REQ_DEV not found, installing from $REQ"
  pip install --break-system-packages -r "$REQ"
else
  echo "⚠️  No requirements file found."
fi
