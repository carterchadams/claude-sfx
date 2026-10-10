#!/usr/bin/env bash
#
# scv-sounds :: play.sh
# Play a random clip from a category folder, non-blocking, cross-platform.
#
#   Usage:  play.sh <category>
#   e.g.    play.sh alert
#
# Categories map to filename prefixes: clips live flat in sfx/ named
# <category>_<label>.<ext>, and this shuffles between all clips whose name
# starts with <category>_. No matching clips plays nothing — that's how you
# disable a category. (The bundled clips are SCV lines, but any audio works.)
#
# Env toggles:
#   SFX_OVERLAP_KILL     stop any still-playing clip before starting the new
#                        one (hear the latest state, not a chord). Default on;
#                        set SFX_OVERLAP_KILL=0 to allow clips to overlap.
#   SFX_DISABLE=1        mute everything (quick global off switch).
#   SFX_VOLUME=<0-100>   override the per-category volume for this call.

set -euo pipefail

[ "${SFX_DISABLE:-0}" = "1" ] && exit 0

category="${1:-}"
[ -z "$category" ] && exit 0

# Subagents get their own "subagent" category: hooks fire for their tool calls
# too, and their payload carries an agent_id that the main session's never
# does. No subagent_* clips ship by default, so subagents stay silent until you
# add some. Only read stdin when it's piped (a hook), so running play.sh by
# hand doesn't block.
if [ ! -t 0 ]; then
  input="$(cat)"
  if command -v jq >/dev/null 2>&1; then
    agent="$(printf '%s' "$input" | jq -r '.agent_id? // empty' 2>/dev/null || true)"
    [ -n "$agent" ] && category=subagent
  else
    printf '%s' "$input" | grep -qE '"agent_id"[[:space:]]*:[[:space:]]*"' && category=subagent
  fi
fi

# Resolve plugin root: prefer the env var Claude Code injects, else derive it
# from this script's location so play.sh also works when run by hand.
ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
dir="$ROOT/sfx"
[ -d "$dir" ] || exit 0

# Collect clips whose name starts with <category>_. wav is the safe
# cross-platform format; the others play only where the chosen player supports
# them.
shopt -s nullglob
pre="$dir/${category}_"
clips=("$pre"*.wav "$pre"*.ogg "$pre"*.mp3 "$pre"*.aiff "$pre"*.flac)
(( ${#clips[@]} == 0 )) && exit 0

# Shuffle: $RANDOM is a bash builtin (present on macOS + Linux), unlike `shuf`
# which is GNU-only and absent from stock macOS.
sound="${clips[RANDOM % ${#clips[@]}]}"

# Per-category volume (percent, 0-100). Edit these to taste; SFX_VOLUME wins.
case "$category" in
  alert|done) vol=80 ;;
  *)          vol=50 ;;
esac
vol="${SFX_VOLUME:-$vol}"

# Precompute each player's volume representation from the percent above.
vol_frac="$(awk "BEGIN{printf \"%.3f\", $vol/100}")"   # afplay / sox: 0.0-1.0 gain
vol_pa=$(( vol * 65536 / 100 ))                         # paplay: 0-65536 linear

if [ "${SFX_OVERLAP_KILL:-1}" = "1" ]; then
  for p in afplay paplay aplay ffplay play mpv; do
    pkill -x "$p" 2>/dev/null || true
  done
fi

play_one() {
  local f="$1"
  local ext="${f##*.}"
  ext="$(printf '%s' "$ext" | tr 'A-Z' 'a-z')"

  # paplay/aplay use libsndfile/ALSA and CANNOT decode compressed formats like
  # mp3/m4a — route those to a player with a real codec. wav/ogg/flac can go to
  # the lighter, better-integrated players.
  local players
  case "$ext" in
    mp3|m4a|aac|opus) players="afplay ffplay mpv play" ;;
    *)                players="afplay paplay ffplay mpv play aplay" ;;
  esac

  local p
  for p in $players; do
    command -v "$p" >/dev/null 2>&1 || continue
    case "$p" in
      afplay) afplay -v "$vol_frac" "$f" ;;
      paplay) paplay "--volume=$vol_pa" "$f" ;;
      ffplay) ffplay -nodisp -autoexit -loglevel quiet -volume "$vol" "$f" ;;
      mpv)    mpv --no-video --really-quiet "--volume=$vol" "$f" ;;
      play)   play -q -v "$vol_frac" "$f" ;;
      aplay)  aplay -q "$f" ;;   # ALSA raw: no per-clip volume, plays at 100%
    esac
    return
  done
}

# Fire-and-forget: hooks run synchronously in Claude's process, so we must
# never block on playback.
play_one "$sound" >/dev/null 2>&1 &
disown
exit 0
