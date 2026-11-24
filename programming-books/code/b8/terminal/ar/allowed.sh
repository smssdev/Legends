$ claude -p "شغّل الاختبارات وقل لي ما الذي يفشل." --model claude-opus-5-5 --no-session-persistence --allowedTools "Bash(node --test)" --output-format stream-json --verbose | node watch.mjs
  says   سأشغّل الاختبارات.
  calls  Bash: {"command":"node --test","description":"Run the tests"}
  gets   (error) ok 1 - a round bill | not ok 2 - a bill with piastres
  says   يفشل اختبار واحد: «a bill with piastres». تعيد total("85.50", 10) القيمة 93.50 بدل 94.05، لأن parseInt يُسقط .50 قبل إضافة البقشيش.
  الأدوار: 2، رُفض: 0، التكلفة: $0.0672، success
