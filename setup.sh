#!/bin/sh
# -----------------------------------------------------------------------------
# Script: setup.sh
# Description: Dev container setup script that runs all initialization scripts,
#              prints a cool banner, and shows timing info.
#
# Author: Robin De Clerck
# Contact: robin.de.clerck@gmail.com
# Created: 2025-07-19
# -----------------------------------------------------------------------------
set -e

get_terminal_width() {
  tput cols 2>/dev/null || echo 80
}

print_line() {
  printf '%*s\n' "$(get_terminal_width)" '' | tr ' ' '-' | lolcat
}

print_info_block() {
  local width=$(get_terminal_width)
  local sep_len=80
  [ "$width" -lt $sep_len ] && sep_len=$width
  local separator="$(printf '%*s' "$sep_len" '' | tr ' ' '-')"

  # Center the word "INFO"
  local info="BASIC INFORMATION"
  local padding_left=$(( (sep_len - ${#info}) / 2 ))
  local padding_right=$(( sep_len - ${#info} - padding_left ))

  printf '\n'
  echo "$separator"
  printf "%*s%s%*s\n\n" "$padding_left" '' "$info" "$padding_right" ''

  printf "%-20s %s\n" "Time (UTC):" "$(date +"%Y-%m-%d %H:%M:%S")"
  printf "%-20s %s\n" "Host:" "$(hostname)"
  printf "%-20s %s\n" "User:" "$(whoami)"
  printf "%-20s %s\n" "Working directory:" "$(pwd)"
  printf '\n'
  printf "%-20s %s\n" "Memory usage:" "$(free -h | awk '/Mem:/ {print $3 " / " $2}')"
  printf "%-20s %s\n" "Disk usage (root):" "$(df -h / | awk 'NR==2 {print $3 " used / " $2}')"
  printf "%-20s %s\n" "Uptime:" "$(uptime -p)"
  printf '\n'
  echo "$separator"
  printf '\n'
}

credits() {
  echo "Script created by Robin De Clerck"
  echo "Contact: robin.de.clerck@gmail.com"
}

check_dependency() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "⚠️ Dependency '$1' is missing. Please install it first!"
    exit 1
  fi
}

check_dependencies() {
  check_dependency lolcat
  check_dependency figlet
  check_dependency free
  check_dependency uptime
}

print_banner() {
  printf '\n'
  print_line

  # Get the project name from the parent directory
  script_path="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
  project_name="$(basename "$(dirname "$(dirname "$script_path")")")"
  # Capitalize words
  display_name="$(echo "$project_name" | sed -E 's/(^|-)([a-z])/\U\2/g')" 

  figlet -c -f slant "$display_name" | lolcat
  figlet -c -f slant "Happy Coding!" | lolcat

  print_line
}

run_script() {
  script="$1"
  echo "⏳ Executing $(basename "$script")"
  start=$(date +%s)

  if ! sh "$script"; then
    echo "❌ Script $(basename "$script") failed! Exiting." >&2
    exit 1
  fi

  end=$(date +%s)
  duration=$((end - start))
  echo "🎉 $(basename "$script") completed successfully in ${duration}s!"
}

run_all_scripts() {
  script_dir="$(cd "$(dirname "$0")/scripts" && pwd)"
  for script in "$script_dir"/*.sh; do
    run_script "$script"
  done
}

main() {
  check_dependencies

  print_info_block
  total_start=$(date +%s)
  echo "🚀 Starting dev container setup..."

  run_all_scripts

  total_end=$(date +%s)
  total_duration=$((total_end - total_start))
  echo "🕒 Setup completed in ${total_duration}s!"

  print_banner
  credits
}

main "$@"
