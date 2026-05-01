# presets.sh — load devbase presets from DEVBASE_PRESETS env var.
# Exposes: load_presets(), print_presets_info()
# Reads: DEVBASE_PRESETS (comma-separated), DEVBASE_PRESETS_DIR

PRESETS_DIR="${DEVBASE_PRESETS_DIR:-$DEVBASE/presets}"
PRESET_NAMES=()   # populated by load_presets()

# Parse DEVBASE_PRESETS and load each preset script.
load_presets() {
  local raw="${DEVBASE_PRESETS:-}"
  local -a parsed=()

  IFS=',' read -ra parsed <<< "$raw"

  # Filter blanks
  for p in "${parsed[@]}"; do
    p="${p// /}"
    [ -n "$p" ] && PRESET_NAMES+=("$p")
  done

  if [ ${#PRESET_NAMES[@]} -eq 0 ]; then
    gum log --time rfc822 --level debug "no presets set — skipping"
    gum log --time rfc822 --level debug \
      "tip: set presets in devcontainer.json e.g.: \"containerEnv\": {\"DEVBASE_PRESETS\": \"python\"}"
    return 0
  fi

  for p in "${PRESET_NAMES[@]}"; do
    gum log --time rfc822 --level debug "loading preset '$p'"
    if [ ! -r "$PRESETS_DIR/$p.sh" ]; then
      gum log --time rfc822 --level warn "preset '$p' not found in $PRESETS_DIR"
      continue
    fi
    bash "$PRESETS_DIR/$p.sh" \
      || gum log --time rfc822 --level error "preset '$p' failed"
  done
}

# High-level: load presets and summarise. Intended as the main entry point.
print_presets_info() {
  load_presets
  (( ${#PRESET_NAMES[@]} == 0 )) && return 0

  gum log --time rfc822 --level info \
    "loaded ${#PRESET_NAMES[@]} preset(s): ${PRESET_NAMES[*]}"
}