# box.sh — bordered box + plain key/value row rendering.
# Exposes: render_box(), print_rows()
# Requires: ansi.sh (RST, fg, repeat) and the caller to set C_BORDER + C_KEY.

# print_rows <key_width> <row...>
# Each row is "Key|Value", or "" for a blank line.
print_rows() {
  local key_width=$1
  shift
  local row key val key_padded
  for row in "$@"; do
    key=${row%%|*}
    val=${row#*|}
    [ -z "$key$val" ] && { echo; continue; }
    printf -v key_padded "%-${key_width}s" "$key"
    printf '  %s%s%s  %s\n' "$C_KEY" "$key_padded" "$RST" "$val"
  done
}

# render_box <header> <key_width> <h_pad> <row...>
# Rows are "Key|Value", or "|" for a blank separator row.
render_box() {
  local header=$1 key_width=$2 h_pad=$3
  shift 3
  local rows=("$@")

  # Compute content width.
  local content_width=0 row val
  for row in "${rows[@]}"; do
    [ "$row" = "|" ] && continue
    val=${row#*|}
    (( ${#val} + key_width + 2 > content_width )) \
      && content_width=$(( ${#val} + key_width + 2 ))
  done

  local header_min=$(( ${#header} + 6 ))
  (( content_width < header_min )) && content_width=$header_min

  local inner=$(( content_width + h_pad * 2 ))
  local pad_h; pad_h=$(repeat ' ' "$h_pad")
  local empty_row="${C_BORDER}│${RST}$(repeat ' ' "$inner")${C_BORDER}│${RST}"

  # Top border.
  local top_lhs="─ ${header} "
  printf '%s╭%s%s╮%s\n' \
    "$C_BORDER" "$top_lhs" "$(repeat '─' "$(( inner - ${#top_lhs} ))")" "$RST"

  printf '%s\n' "$empty_row"

  # Rows.
  local key val_str key_padded trail content
  for row in "${rows[@]}"; do
    key=${row%%|*}
    val_str=${row#*|}

    if [ -z "$key$val_str" ]; then
      printf '%s\n' "$empty_row"
      continue
    fi

    printf -v key_padded "%-${key_width}s" "$key"
    trail=$(repeat ' ' "$(( content_width - key_width - 2 - ${#val_str} ))")
    content="${C_KEY}${key_padded}${RST}  ${val_str}${trail}"

    printf '%s│%s%s%s│%s\n' \
      "$C_BORDER" "$RST" \
      "${pad_h}${content}${pad_h}" \
      "$C_BORDER" "$RST"
  done

  printf '%s\n' "$empty_row"
  printf '%s╰%s╯%s'  "$C_BORDER" "$(repeat '─' "$inner")" "$RST"
}
