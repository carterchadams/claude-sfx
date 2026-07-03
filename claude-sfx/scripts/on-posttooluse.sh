#!/usr/bin/env bash
#
# claude-sfx :: on-posttooluse.sh
# Reads the PostToolUse hook JSON on stdin and plays the "error" category when
# the tool call appears to have failed.
#
# NOTE: tool_response has no single universal "failed" flag — its shape varies
# per tool. This is a best-effort heuristic. Tune the jq keys / grep pattern
# below to match the tools you care about (Bash exit codes, etc.).

set -euo pipefail

ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
input="$(cat)"

is_error=0

if command -v jq >/dev/null 2>&1; then
  # Common failure shapes across tools.
  flag="$(printf '%s' "$input" | jq -r '.tool_response.is_error? // empty' 2>/dev/null || true)"
  [ "$flag" = "true" ] && is_error=1

  err="$(printf '%s' "$input" | jq -r '.tool_response.error? // .tool_response.stderr? // empty' 2>/dev/null || true)"
  [ -n "$err" ] && is_error=1

  code="$(printf '%s' "$input" | jq -r '.tool_response.exit_code? // .tool_response.exitCode? // empty' 2>/dev/null || true)"
  [ -n "$code" ] && [ "$code" != "0" ] && is_error=1
else
  # No jq: cheap grep on the raw payload.
  printf '%s' "$input" | grep -qiE '"(is_error|error)"[[:space:]]*:[[:space:]]*(true|")' && is_error=1
fi

[ "$is_error" = "1" ] && exec "$ROOT/scripts/play.sh" error
exit 0
