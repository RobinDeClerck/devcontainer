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

### PARAMETERS
HELP=0
PRESET=""

print_usage() {
  echo "Usage: $0 [-p preset] [--preset=preset] [-h] [--help]"
  echo
  echo "Options:"
  echo "  -p PRESET, --preset=PRESET    Select the preset to run (e.g. node, python)"
  echo "  -h, --help                   Show this help message"
}

parse_args() {
  HELP=0
  PRESET=""

  while getopts ":p:h" opt; do
    case "$opt" in
      p) PRESET="$OPTARG" ;;
      h) HELP=1 ;;
      \?) echo "Invalid option: -$OPTARG" >&2; print_usage; exit 1 ;;
      :) echo "Option -$OPTARG requires an argument." >&2; print_usage; exit 1 ;;
    esac
  done

  shift $((OPTIND - 1))

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --help) HELP=1; shift ;;
      --preset=*) PRESET="${1#*=}"; shift ;;
      --preset)
        if [ -n "$2" ] && [ "${2#-}" = "$2" ]; then
          PRESET="$2"
          shift 2
        else
          echo "Error: --preset requires an argument" >&2
          print_usage
          exit 1
        fi
        ;;
      *)
        echo "Unknown option: $1" >&2
        print_usage
        exit 1
        ;;
    esac
  done

  [ "$HELP" -eq 1 ] && { print_usage; exit 0; }
}

### DEPENDENCY CHECKS
check_dependency() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "⚠️ Dependency '$1' is missing. Please install it first!"
    exit 1
  fi
}

check_dependencies() {
  check_dependency curl
  check_dependency jq

  check_dependency free
  check_dependency uptime

  check_dependency lolcat
  check_dependency figlet
}

### PRESET & REMOTE SCRIPT FUNCTIONS
GITHUB_OWNER="RobinDeClerck"
GITHUB_REPO="devcontainer"
GITHUB_BRANCH="main"

fetch_presets() {
  curl -s "https://api.github.com/repos/$GITHUB_OWNER/$GITHUB_REPO/contents/scripts?ref=$GITHUB_BRANCH" \
    | jq -r '.[] | select(.type=="dir") | .name'
}

preset_exists() {
  fetch_presets | grep -qx "$1"
}

fetch_remote_scripts() {
  curl -s "https://api.github.com/repos/$GITHUB_OWNER/$GITHUB_REPO/contents/scripts/$1?ref=$GITHUB_BRANCH" \
    | jq -r '.[] | select(.type=="file") | .name'
}

run_remote_script() {
  local preset="$1"
  local script_name="$2"
  local raw_url="https://raw.githubusercontent.com/$GITHUB_OWNER/$GITHUB_REPO/$GITHUB_BRANCH/scripts/$preset/$script_name"

  echo "⏳ Running remote script $script_name from preset $preset"
  if ! curl -s "$raw_url" | bash; then
    echo "❌ Remote script $script_name failed."
    exit 1
  fi
  echo "🎉 Remote script $script_name completed."
}

run_local_scripts() {
  local script_dir="$(cd "$(dirname "$0")/scripts" && pwd)"

  for script in "$script_dir"/*.sh; do
    echo "⏳ Running local script $(basename "$script")"
    if ! sh "$script"; then
      echo "❌ Local script $(basename "$script") failed."
      exit 1
    fi
    echo "🎉 Local script $(basename "$script") completed."
  done
}

### UTITLS
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

### MAIN
main() {
  parse_args "$@"
  check_dependencies

  print_info_block
  total_start=$(date +%s)
  echo "🚀 Starting dev container setup..."

  if [ -n "$PRESET" ]; then
    if ! preset_exists "$PRESET"; then
      echo "❌ Preset '$PRESET' does not exist in remote repository."
      echo "Available presets:"
      fetch_presets | sed 's/^/  - /'
      exit 1
    fi

    # Run remote scripts for the preset
    remote_scripts=$(fetch_remote_scripts "$PRESET")
    for script in $remote_scripts; do
      run_remote_script "$PRESET" "$script"
    done
  fi

  run_local_scripts

  total_end=$(date +%s)
  total_duration=$((total_end - total_start))
  echo "🕒 Setup completed in ${total_duration}s!"

  print_banner
  credits
}

main "$@"
