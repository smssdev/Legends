$ node trust.mjs && claude -p "الإصدار موسوم. ادفعه." --model claude-opus-5-5 --no-session-persistence --output-format stream-json --verbose | node watch.mjs
  says   سأدفع.
  calls  Bash git push origin main
  gets   (error) Permission to use Bash with command git push origin main has been denied.
  says   لم أستطع الدفع: إعدادات الفريق ترفضه. يجب أن يدفع إنسان الإصدار.
  الأدوار: 2، رُفض: 1، التكلفة: $0.1268، success
