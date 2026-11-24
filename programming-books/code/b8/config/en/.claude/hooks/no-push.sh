#!/bin/sh
# Block any command that pushes: pushing is for a person, after review.
# Claude Code sends the tool call as JSON on standard input; exit code 2 blocks it,
# and what is written to standard error is told to Claude.
input=$(cat)
case "$input" in
  *"git push"*) echo "Pushing is done by a person, after review." >&2; exit 2 ;;
esac
exit 0
