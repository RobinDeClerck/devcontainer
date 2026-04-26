#!/usr/bin/env bash
# sysinfo - collects lightweight system metadata

PROJECT=$(basename "$PWD")
TIME_UTC=$(date -u '+%Y-%m-%d %H:%M:%S')
HOST=$(hostname)
USER_NAME=$(whoami)
CWD=$PWD

# memory: read /proc/meminfo, no `free` dep.
if [ -r /proc/meminfo ]; then
  _mem_total=$(awk '/^MemTotal:/  {print $2}' /proc/meminfo)
  _mem_avail=$(awk '/^MemAvailable:/{print $2}' /proc/meminfo)
  _mem_used=$(( _mem_total - _mem_avail ))
  _fmt_kb() {
    awk -v k="$1" 'BEGIN{
      if (k>=1048576) printf "%.1fGi", k/1048576
      else if (k>=1024) printf "%.0fMi", k/1024
      else printf "%dKi", k
    }'
  }
  MEMORY="$(_fmt_kb "$_mem_used") / $(_fmt_kb "$_mem_total")"
else
  MEMORY="n/a"
fi

# disk: df on / (BusyBox-compatible).
DISK=$(df -h / 2>/dev/null | awk 'NR==2 {print $3 " used / " $2}')
[ -z "$DISK" ] && DISK="n/a"

# uptime: BusyBox uptime has no -p, format manually.
if [ -r /proc/uptime ]; then
  _up=$(awk '{print int($1)}' /proc/uptime)
  if   [ "$_up" -lt 60 ];    then UPTIME_STR="up ${_up} seconds"
  elif [ "$_up" -lt 3600 ];  then UPTIME_STR="up $((_up/60)) minutes"
  elif [ "$_up" -lt 86400 ]; then UPTIME_STR="up $((_up/3600)) hours"
  else                            UPTIME_STR="up $((_up/86400)) days"
  fi
else
  UPTIME_STR="n/a"
fi