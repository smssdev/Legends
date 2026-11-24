#!/bin/sh
# Ask Claude Code about this project, with read-only tools only.
exec claude -p "$*" --model claude-opus-5-5 --tools Read,Grep,Glob --no-session-persistence
