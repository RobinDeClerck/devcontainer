#!/usr/bin/env bash
# lib/menu.sh — reusable gum menu
# Usage: open_menu label1 "cmd1" label2 "cmd2" ...

open_menu() {
  local default=""
  if [[ $1 == --default ]]; then
    default=$2; shift 2
  fi

  local -A menu
  while (( $# >= 2 )); do
    menu[$1]=$2; shift 2
  done

  local choice
  while true; do
    choice=$(printf '%s\n' "${!menu[@]}" "quit" | sort | gum choose \
      --cursor.foreground 157 \
      --selected.foreground 157 \
      --header "" \
      ${default:+--selected "$default"}) || return 0

    case "$choice" in
      quit|"") return 0 ;;
      *)       eval "${menu[$choice]}" ;;
    esac
  done
}