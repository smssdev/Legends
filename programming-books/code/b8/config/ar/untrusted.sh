$ claude -p "شغّل الاختبارات." --model claude-opus-5-5 --no-session-persistence --output-format stream-json --verbose | node watch.mjs
  says   سأشغّل الاختبارات.
  calls  Bash node --test
  gets   ok 1 - whole pounds | ok 2 - piastres | ok 3 - zero
  says   الاختبارات الثلاثة تنجح.
  الأدوار: 2، رُفض: 0، التكلفة: $0.1280، success
