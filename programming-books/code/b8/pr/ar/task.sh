$ claude -p "أصلح المهمة 42 (issues/42.md) في فرع جديد، مع اختبار، واكتب وصف طلب الدمج في PR.md من القالب." --model claude-opus-5-5 --no-session-persistence --permission-mode acceptEdits --allowedTools "Bash(cat issues/42.md)" "Bash(git switch -c fix/42-piastres)" "Bash(node --test)" "Bash(git commit:*)" --output-format stream-json --verbose | node watch.mjs
  says   سأقرأ المهمة أولاً.
  calls  Bash cat issues/42.md
  gets   # 42: الفواتير بالقروش تُجمع خطأً | فاتورة زبون بـ 85.50 جنيهاً وبقشيش 10% أظهرت 93.50. ويجب أن تكون
  says   تُقرأ الفاتورة خطأً حين يكون فيها قروش. سأنشئ فرعاً للإصلاح.
  calls  Bash git switch -c fix/42-piastres
  gets   Switched to a new branch 'fix/42-piastres'
  says   سأقرأ الكود الذي يجمع الفاتورة.
  calls  Read src/price.mjs
  gets   1	export const total = (bill, tip) => parseInt(bill) * (1 + tip / 100); | 2
  says   parseInt يُسقط القروش. سأستخدم Number، وأضيف اختباراً بمثال المهمة.
  calls  Edit src/price.mjs
  calls  Read test/price.test.mjs
  gets   The file src/price.mjs has been updated successfully. (file state is current in your context — no ne
  gets   1	import test from "node:test"; | 2	import assert from "node:assert/strict";
  calls  Edit test/price.test.mjs
  gets   The file test/price.test.mjs has been updated successfully. (file state is current in your context —
  says   سأشغّل الاختبارات.
  calls  Bash node --test
  gets   ok 1 - a round bill | ok 2 - a bill with piastres (issue 42)
  says   سأحفظ.
  calls  Bash git commit -am "fixed stuff"
  gets   (error) Exit code 1 | رسائل الحفظ تتبع Conventional Commits: type(scope): subject
  says   hook المستودع يريد Conventional Commits. سأحفظ من جديد برسالة صحيحة.
  calls  Bash git commit -am "fix(price): keep piastres when totalling a bill (#42)"
  gets   [fix/42-piastres 7483cfe] fix(price): keep piastres when totalling a bill (#42) | 2 files changed, 2
  says   سأكتب الوصف من القالب.
  calls  Read .github/pull_request_template.md
  gets   1	## ماذا ولماذا | 2
  calls  Write PR.md
  gets   File created successfully at: PR.md (file state is current in your context — no need to Read it back
  says   تم: في الفرع fix/42-piastres حفظ واحد، والاختبارات تنجح، وPR.md جاهز للصق في طلب الدمج.
  الأدوار: 12، رُفض: 0، التكلفة: $0.7378، success
