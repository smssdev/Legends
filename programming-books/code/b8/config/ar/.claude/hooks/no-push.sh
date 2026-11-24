#!/bin/sh
# أوقف أي أمر يدفع: الدفع لإنسان، بعد المراجعة.
# Claude Code sends the tool call as JSON on standard input; exit code 2 blocks it,
# and what is written to standard error is told to Claude.
input=$(cat)
case "$input" in
  *"git push"*) echo "الدفع يقوم به إنسان، بعد المراجعة." >&2; exit 2 ;;
esac
exit 0
