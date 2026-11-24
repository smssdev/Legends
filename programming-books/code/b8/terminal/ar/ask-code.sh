#!/bin/sh
# اسأل Claude Code عن هذا المشروع، بأدوات القراءة فقط.
exec claude -p "$*" --model claude-opus-5-5 --tools Read,Grep,Glob --no-session-persistence
