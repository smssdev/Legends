$ claude -p "أضف ضريبة القيمة المضافة 14% إلى الإيصالات: مجموعاً فرعياً، والضريبة، والإجمالي شاملاً لها. وحدّث الاختبار." --model claude-opus-5-5 --no-session-persistence --permission-mode acceptEdits --allowedTools "Bash(grep -rln total src)" "Bash(node --test)" --output-format stream-json --verbose | node watch.mjs
  says   سأجد أين تُجمع الإيصالات.
  calls  Bash grep -rln total src
  gets   src/receipt.mjs
  says   وجدت src/receipt.mjs. سأقرؤه، ووحدة القائمة بجانبه، قبل أن أغيّر أي شيء.
  calls  Read src/receipt.mjs
  calls  Read src/menu.mjs
  gets   1	import {priceOf} from "./menu.mjs";
  gets   1	export const PRICES = {
  says   سأضيف الضريبة بعد المجموع الفرعي.
  calls  Edit src/receipt.mjs
  calls  Edit src/menu.mjs
  gets   The file src/receipt.mjs has been updated successfully. (file stat
  gets   The file src/menu.mjs has been updated successfully. (file state i
  says   والآن الاختبار، الذي ما زال يتوقع الإجمالي القديم.
  calls  Edit test/receipt.test.mjs
  gets   The file test/receipt.test.mjs has been updated successfully.
  says   سأشغّل الاختبارات.
  calls  Bash node --test
  gets   ok 1 - a receipt adds up its lines
  says   تم. صار src/receipt.mjs يعيد subtotal وvat (14%، مقرّبة إلى القروش) وtotal؛ وVAT_RATE يُصدَّر من src/menu.mjs. والاختبار يفحص الثلاثة، وهو ينجح.
  الأدوار: 8، رُفض: 0، التكلفة: $0.4006، success
