$ echo '{"tool_name":"Bash","tool_input":{"command":"git push origin main"}}' | sh .claude/hooks/no-push.sh 2>&1; echo "exit $?"; echo '{"tool_name":"Bash","tool_input":{"command":"node --test"}}' | sh .claude/hooks/no-push.sh 2>&1; echo "exit $?"
الدفع يقوم به إنسان، بعد المراجعة.
exit 2
exit 0
