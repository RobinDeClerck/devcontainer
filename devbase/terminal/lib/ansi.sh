# ansi.sh — ANSI color + text helpers.
# Exposes: RST, fg(), repeat(), color_lines()
# Reads: (nothing)

ESC=$'\033'
RST="${ESC}[0m"

fg() { printf '%s[38;5;%sm' "$ESC" "$1"; }

# UTF-8-safe character repeater (tr is byte-based; don't use it here).
repeat() {
  local char=$1 count=$2 out=''
  while (( count-- > 0 )); do out+=$char; done
  printf '%s' "$out"
}

# Color every line of stdin individually (so gum join can't strip color).
color_lines() {
  local color=$1
  while IFS= read -r line; do
    printf '%s%s%s\n' "$color" "$line" "$RST"
  done
}
