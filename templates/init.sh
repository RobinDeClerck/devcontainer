#!/usr/bin/env bash
# devbase-init — scaffold a new project with a devbase devcontainer.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/RobinDeClerck/devcontainer/main/templates/init.sh | bash
set -euo pipefail

REPO="RobinDeClerck/devcontainer"
BRANCH="${DEVBASE_BRANCH:-main}"
RAW="https://raw.githubusercontent.com/$REPO/$BRANCH/templates"

# ---- helpers -------------------------------------------------------------
die() { printf '✗ %s\n' "$1" >&2; exit 1; }
say() { gum log --time rfc822 --level info "$1"; }
warn(){ gum log --time rfc822 --level warn "$1"; }

fetch() {
  # fetch <relative_template_path> <local_dest>
  local src="$RAW/$1" dst=$2
  mkdir -p "$(dirname "$dst")"
  curl -fsSL "$src" -o "$dst" \
    || die "failed to fetch $src"
}

substitute() {
  # In-place placeholder replacement.
  local file=$1
  sed -i.bak \
    -e "s|{{NAME}}|$NAME|g" \
    -e "s|{{SLUG}}|$SLUG|g" \
    -e "s|{{PRESETS}}|$PRESETS|g" \
    "$file"
  rm -f "$file.bak"
}

slugify() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g'
}

# ---- gum bootstrap -------------------------------------------------------
if ! command -v gum >/dev/null 2>&1; then
  echo "gum is required but not installed."
  read -r -p "install with homebrew? [Y/n] " ans
  case "${ans:-y}" in
    [yY]*)
      command -v brew >/dev/null 2>&1 \
        || die "homebrew not found — install gum manually: https://github.com/charmbracelet/gum"
      brew install gum
      ;;
    *)
      die "gum required. install: https://github.com/charmbracelet/gum"
      ;;
  esac
fi

# ---- prompt user ---------------------------------------------------------
gum style --bold --foreground 212 --align center --margin "1 0" \
  "devbase init"

NAME=$(gum input \
  --prompt "project name › " \
  --placeholder "Pipeline Dev Container" \
  --width 50)
[ -n "$NAME" ] || die "name required"

SLUG_DEFAULT=$(slugify "$NAME")
SLUG=$(gum input \
  --prompt "slug › " \
  --value "$SLUG_DEFAULT" \
  --width 50)
[ -n "$SLUG" ] || die "slug required"

PRESETS_SELECTED=$(gum choose --no-limit --header "select presets (space to toggle, enter to confirm)" \
  "python" "node")
PRESETS=$(echo "$PRESETS_SELECTED" | paste -sd ',' -)

# ---- existing files check ------------------------------------------------
if [ -e .devcontainer ] || [ -e docker-compose.yml ]; then
  gum confirm "existing .devcontainer/ or docker-compose.yml found — overwrite?" \
    || die "aborted by user"
fi

# ---- fetch base templates ------------------------------------------------
say "fetching base templates"
fetch base/.devcontainer/devcontainer.json        .devcontainer/devcontainer.json
fetch base/.devcontainer/Dockerfile               .devcontainer/Dockerfile
fetch base/.devcontainer/docker-compose.override.yml .devcontainer/docker-compose.override.yml
fetch base/docker-compose.yml                     docker-compose.yml

# ---- fetch preset extras -------------------------------------------------
IFS=',' read -ra PRESETS_ARR <<< "$PRESETS"
for p in "${PRESETS_ARR[@]}"; do
  [ -z "$p" ] && continue
  say "fetching preset: $p"
  case "$p" in
    python)
      fetch presets/python/requirements.txt     requirements.txt
      fetch presets/python/requirements-dev.txt requirements-dev.txt
      ;;
    node)
      fetch presets/node/package.json package.json
      ;;
    *)
      warn "unknown preset: $p (skipping)"
      ;;
  esac
done

# ---- substitute placeholders --------------------------------------------
say "applying placeholders"
for f in \
  .devcontainer/devcontainer.json \
  .devcontainer/Dockerfile \
  .devcontainer/docker-compose.override.yml \
  docker-compose.yml \
  package.json
do
  [ -f "$f" ] && substitute "$f"
done

# ---- done ----------------------------------------------------------------
echo
gum style --bold --foreground 212 \
  "✓ $NAME scaffolded"
gum style --foreground 245 \
  "next: open in VS Code → Reopen in Container"
echo
