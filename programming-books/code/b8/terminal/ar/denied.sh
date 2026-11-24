$ claude -p "شغّل الاختبارات وقل لي ما الذي يفشل." --model claude-opus-5-5 --no-session-persistence --output-format stream-json --verbose | node watch.mjs
  says   سأشغّل الاختبارات.
  calls  Bash: {"command":"node --test","description":"Run the tests"}
  gets   (error) This command requires approval
  says   لم أستطع تشغيل الاختبارات: تشغيل `node --test` يحتاج موافقتك. اسمح به، أو شغّله بنفسك والصق المخرجات.
  الأدوار: 2، رُفض: 1، التكلفة: $0.1243، success
