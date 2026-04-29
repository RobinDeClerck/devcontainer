#!/usr/bin/env bash
# dance.sh — kuchipachi dances inside concentric pulse rings, fullscreen.
#
# Frames live in ./frames/*.txt — drop in another file and it joins the loop
# automatically (sorted by filename). Each frame should be the same shape.
#
# Controls:
#   q / ESC / Ctrl-C   quit
#   SPACE              pause / resume
#
# Needs a truecolor terminal.

set -u

# We rely on ${#var} counting characters, not bytes, for sprite widths.
# Force a UTF-8 locale if we can find one (names vary: C.UTF-8, C.utf8, ...).
if [[ ${LC_ALL:-${LANG:-}} != *[Uu][Tt][Ff]* ]]; then
  for _loc in $(locale -a 2>/dev/null); do
    case "${_loc,,}" in
      *.utf-8|*.utf8) export LC_ALL=$_loc LANG=$_loc; break ;;
    esac
  done
  unset _loc
fi

# ─── Constants ────────────────────────────────────────────────────────────
SELF_DIR=$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)
FRAMES_DIR="$SELF_DIR/frames"

ESC=$'\033'
RESET="${ESC}[0m"
HIDE_CURSOR="${ESC}[?25l"
SHOW_CURSOR="${ESC}[?25h"
ENTER_ALT="${ESC}[?1049h"
EXIT_ALT="${ESC}[?1049l"
CURSOR_HOME="${ESC}[H"
CLEAR_SCREEN="${ESC}[2J"
KUCHI_FG="${ESC}[38;5;157m"
HINT_FG="${ESC}[2;38;2;180;180;180m"  # dim grey for the quit hint overlay
BLOCK="⣿"  # the only braille glyph we ever draw

# Pastel ring palette — cycled per ring.
PALETTE=()
_init_palette() {
  local rgbs=(
    "120 180 255"
    "160 220 255"
    "210 160 240"
    "255 200 200"
    "200 120 255"
    "150 200 255"
    "100 255 200"
  )
  local rgb r g b
  for rgb in "${rgbs[@]}"; do
    read -r r g b <<<"$rgb"
    PALETTE+=("${ESC}[38;2;${r};${g};${b}m")
  done
}
_init_palette

# ─── Frame loader ─────────────────────────────────────────────────────────
# FRAMES holds all rows of all frames, flat. Frame n's row r is at
# FRAMES[n*FRAME_H + r]. Every frame must have the same dimensions.
FRAMES=()
FRAME_COUNT=0
FRAME_H=0
FRAME_W=0

# Split a UTF-8 string into per-character entries in EXPLODED.
EXPLODED=()
explode_chars() {
  EXPLODED=()
  local s=$1
  local n=${#s}
  local i
  for ((i=0; i<n; i++)); do
    EXPLODED[i]=${s:i:1}
  done
}

load_frames() {
  shopt -s nullglob
  local files=("$FRAMES_DIR"/*.txt)
  shopt -u nullglob

  if (( ${#files[@]} == 0 )); then
    echo "dance: no frames found in $FRAMES_DIR" >&2
    return 1
  fi

  IFS=$'\n' files=($(printf '%s\n' "${files[@]}" | sort))
  unset IFS

  local f lines
  for f in "${files[@]}"; do
    mapfile -t lines < "$f"
    while (( ${#lines[@]} > 0 )) && [ -z "${lines[-1]}" ]; do
      unset 'lines[-1]'
    done
    (( ${#lines[@]} == 0 )) && continue

    if (( FRAME_H == 0 )); then
      FRAME_H=${#lines[@]}
      FRAME_W=${#lines[0]}
    fi

    FRAMES+=("${lines[@]}")
    : $((FRAME_COUNT++))
  done

  (( FRAME_COUNT > 0 ))
}

# ─── Distance cache ───────────────────────────────────────────────────────
# DIST[y*cols + x] = Euclidean distance from cell (x,y) to screen center,
# scaled ×10 and rounded to integer. Distance uses dy*2 to compensate for
# the ~2:1 aspect ratio of terminal cells. Rebuilt only on resize, so the
# per-frame inner loop is one array lookup — no math.
#
# The build is offloaded to awk because bash's per-iteration arithmetic is
# ~100× slower than awk for the same work, and a 200×60 grid is 12k cells.

DIST=()
DIST_COLS=0
DIST_ROWS=0

build_dist_cache() {
  local cols=$1 rows=$2
  DIST_COLS=$cols
  DIST_ROWS=$rows

  # awk emits one integer distance per line, in row-major order.
  mapfile -t DIST < <(awk -v cols="$cols" -v rows="$rows" '
    BEGIN {
      cx = int(cols / 2)
      cy = int(rows / 2)
      for (y = 0; y < rows; y++) {
        for (x = 0; x < cols; x++) {
          dx = x - cx
          # Terminal cells are ~2× taller than wide. Doubling dy means a
          # "circle" in distance-space looks visually round on screen
          # (equal screen-pixel distances → equal computed distances).
          dy = (y - cy) * 2
          # ×10 scale keeps integer math smooth between adjacent cells.
          d = sqrt(dx*dx + dy*dy) * 10
          printf "%d\n", d + 0.5
        }
      }
    }
  ')
}

# ─── Renderer ─────────────────────────────────────────────────────────────
# A cell is "lit" if its (cached) distance falls within THICKNESS of a ring
# crest. Rings are spaced WAVELEN apart; PHASE shifts them outward over
# time. SAFE_R carves an empty halo around kuchipachi so he stands out.
#
# All distances/lengths here are in the same ×10-scaled units the cache
# uses, so PHASE advances by ~10/frame to move one cell-width per frame.

render_frame() {
  local cols=$1 rows=$2 phase=$3 frame_idx=$4

  local sx=$(( (cols - FRAME_W) / 2 ))
  local sy=$(( (rows - FRAME_H) / 2 ))

  # Halo radius: covers the sprite plus a few cells of breathing room.
  # The cache stores distances at ×10 scale with y doubled. The farthest
  # sprite cell from center sits at (FRAME_W/2, FRAME_H/2) in cell units —
  # which is (FRAME_W/2, FRAME_H) after y-doubling. We approximate the
  # diagonal as max + min/2 (cheap, slightly generous, fine for a halo).
  local _hx=$(( FRAME_W / 2 ))
  local _hy=$FRAME_H
  local _diag
  if (( _hx > _hy )); then _diag=$(( _hx + _hy / 2 )); else _diag=$(( _hy + _hx / 2 )); fi
  local SAFE_R=$(( (_diag + 3) * 10 ))
  local WAVELEN=80     # ~8 cells of horizontal distance between ring crests
  local THICKNESS=22   # ≥ 20 keeps vertical sampling continuous (dy steps by 2)
  local PAL_LEN=${#PALETTE[@]}

  # Pre-explode this frame's rows for sprite lookup.
  local sprite=()
  local frame_base=$(( frame_idx * FRAME_H ))
  local r c
  for ((r=0; r<FRAME_H; r++)); do
    explode_chars "${FRAMES[frame_base + r]}"
    for ((c=0; c<FRAME_W; c++)); do
      sprite[r*FRAME_W + c]=${EXPLODED[c]:-⠀}
    done
  done

  local out='' state='' x y dist rp ring schar
  for ((y=0; y<rows; y++)); do
    for ((x=0; x<cols; x++)); do

      # Sprite takes priority over rings.
      if (( y >= sy && y < sy + FRAME_H && x >= sx && x < sx + FRAME_W )); then
        schar=${sprite[(y-sy)*FRAME_W + (x-sx)]}
        if [ -n "$schar" ] && [ "$schar" != "⠀" ]; then
          [ "$state" != K ] && { out+=$KUCHI_FG; state=K; }
          out+=$schar
          continue
        fi
      fi

      dist=${DIST[y*cols + x]}

      # Empty halo around kuchipachi.
      if (( dist < SAFE_R )); then
        [ "$state" != B ] && { out+=$RESET; state=B; }
        out+=' '
        continue
      fi

      # Ring band membership.
      rp=$(( (dist - phase) % WAVELEN ))
      (( rp < 0 )) && rp=$(( rp + WAVELEN ))
      (( WAVELEN - rp < rp )) && rp=$(( WAVELEN - rp ))

      if (( rp < THICKNESS )); then
        ring=$(( ((dist - phase) / WAVELEN) % PAL_LEN ))
        (( ring < 0 )) && ring=$(( ring + PAL_LEN ))
        if [ "$state" != "P$ring" ]; then
          out+=${PALETTE[ring]}
          state="P$ring"
        fi
        out+=$BLOCK
      else
        [ "$state" != B ] && { out+=$RESET; state=B; }
        out+=' '
      fi
    done
    out+=$RESET
    state=''
    (( y < rows - 1 )) && out+=$'\n'
  done

  printf '%s' "$out"
}

# ─── Terminal size ────────────────────────────────────────────────────────
# tput can return 0 or fail silently in some environments (some VS Code
# terminals, screen-in-tmux, etc.). Prefer bash's COLUMNS/LINES, which
# checkwinsize keeps current; fall back to tput; fall back to a default.
# Sets the COLS / ROWS globals.
shopt -s checkwinsize
read_term_size() {
  COLS=${COLUMNS:-0}
  ROWS=${LINES:-0}
  if (( COLS <= 0 )); then COLS=$(tput cols 2>/dev/null || echo 0); fi
  if (( ROWS <= 0 )); then ROWS=$(tput lines 2>/dev/null || echo 0); fi
  (( COLS <= 0 )) && COLS=80
  (( ROWS <= 0 )) && ROWS=24
}

# ─── Time helper ──────────────────────────────────────────────────────────
now_ms() {
  if [ -n "${EPOCHREALTIME:-}" ]; then
    local s=${EPOCHREALTIME%.*}
    local us=${EPOCHREALTIME#*.}
    us=${us:0:6}
    while (( ${#us} < 6 )); do us+=0; done
    printf '%d' $(( s * 1000 + 10#$us / 1000 ))
  else
    date +%s%3N
  fi
}

# ─── Main loop ────────────────────────────────────────────────────────────
cleanup() {
  printf '%s' "$SHOW_CURSOR$EXIT_ALT"
  [ -n "${OLD_STTY:-}" ] && stty "$OLD_STTY" 2>/dev/null || true
}

main() {
  if [ ! -t 1 ]; then
    echo "kuchipachi dance needs a terminal." >&2
    return 1
  fi

  load_frames || return 1

  OLD_STTY=$(stty -g)
  stty -icanon -echo min 0 time 0
  printf '%s' "$ENTER_ALT$HIDE_CURSOR$CURSOR_HOME$CLEAR_SCREEN"
  trap 'cleanup; exit 0' INT TERM EXIT

  local phase=0 frame_idx=0 paused=0
  local frame_period_ms=250   # pose change interval
  local target_ms=70          # ~14 fps cap
  local phase_step=8          # ring outward speed (×10-scaled distance/frame)
  local prev_cols=0 prev_rows=0
  local last_pose_ms=$(now_ms)

  while true; do
    local tick_ms=$(now_ms)

    # Drain a keypress (non-blocking thanks to stty min 0 time 0).
    local key=''
    IFS= read -rsn1 -t 0.001 key 2>/dev/null || true
    case "$key" in
      q|Q|$'\033'|$'\003') break ;;
      ' ') paused=$(( 1 - paused )) ;;
    esac

    # Measure terminal robustly.
    local cols rows
    read_term_size
    cols=$COLS
    rows=$ROWS

    # Resize: clear and rebuild distance cache.
    if (( cols != prev_cols || rows != prev_rows )); then
      printf '%s' "$CLEAR_SCREEN"
      build_dist_cache "$cols" "$rows"
      prev_cols=$cols
      prev_rows=$rows
    fi

    local frame
    frame=$(render_frame "$cols" "$rows" "$phase" "$frame_idx")

    # Draw the frame, then overlay a small quit hint at row 1 col 2 (top-left
    # corner). It's drawn AFTER the frame so it sits on top of the rings; we
    # use \033[r;cH to position absolutely without disturbing the layout.
    local hint=" q quit · SPACE pause "
    (( paused )) && hint=" q quit · SPACE resume · paused "

    printf '%s%s\033[1;2H%s%s%s' \
      "$CURSOR_HOME" "$frame" \
      "$HINT_FG" "$hint" "$RESET"

    if (( paused == 0 )); then
      phase=$(( phase + phase_step ))
      local now=$(now_ms)
      if (( now - last_pose_ms >= frame_period_ms )); then
        frame_idx=$(( (frame_idx + 1) % FRAME_COUNT ))
        last_pose_ms=$now
      fi
    fi

    # Cap framerate.
    local elapsed=$(( $(now_ms) - tick_ms ))
    if (( elapsed < target_ms )); then
      local nap=$(( target_ms - elapsed ))
      printf -v naps '%d.%03d' $(( nap / 1000 )) $(( nap % 1000 ))
      sleep "$naps"
    fi
  done
}

if [ "${BASH_SOURCE[0]:-}" = "${0}" ]; then
  main
fi