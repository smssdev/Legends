$ claude -p "الإصلاح محفوظ. ادفعه." --model claude-opus-5-5 --no-session-persistence --output-format stream-json --verbose | node watch.mjs
  says   سأدفع إلى main.
  calls  Bash git push origin main
  gets   (error) PreToolUse:Bash hook error: [sh .claude/hooks/no-push.sh]: الدفع يقوم به إنسان، بعد المراجعة.
  says   أوقف hook المشروع الدفع: الدفع يقوم به إنسان، بعد المراجعة. والحفظ جاهز على الفرع.
  الأدوار: 2، رُفض: 1، التكلفة: $0.1281، success
