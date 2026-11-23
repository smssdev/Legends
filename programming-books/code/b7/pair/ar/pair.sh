$ node pair.mjs
== plan
1. تحقق من أن `people` لا يقل عن 1، وترمي `RangeError` إذا كان أقل من 1.  
2. حسب البقشيش كـ `total * tipPercent / 100`، ثم أقرب قرش باستخدام تابع `Math.round()`.  
3. أضف البقشيش إلى `total` لحساب المبلغ الكلي المطلوب تقسيمه.  
4. قسّم المبلغ الكلي على `people` للحصول على المبلغ الأساسي لكل شخص، ثم توزع الباقي على الأوائل.  
5. أعد مصفوفة من الأشخاص، حيث يدفع أول `remainder` شخص قرشًا زائدًا، والباقي يدفعون المبلغ الأساسي.
== tests: bill/bill.test.mjs, 5 tests
== tests against an empty splitBill: 0 passed, 1 failed
  ReferenceError: require is not defined in ES module scope, you can use import instead
not ok 1 - bill/bill.test.mjs
  error: 'test failed'
== tests against an empty splitBill: 0 passed, 1 failed
  ReferenceError: require is not defined in ES module scope, you can use import instead
not ok 1 - bill/bill.test.mjs
  error: 'test failed'
   (the developer adds: تلميح من المطور: هذا المشروع يستخدم وحدات ES، فاستخدم import لا require أبداً؛ وassert هو التصدير الافتراضي لـ node:assert/strict.)
== tests against an empty splitBill: 0 passed, 1 failed
  ReferenceError: test is not defined
not ok 1 - bill/bill.test.mjs
  error: 'test failed'
== round 1: 0 passed, 1 failed
  ReferenceError: test is not defined
not ok 1 - bill/bill.test.mjs
  error: 'test failed'
== round 2: 0 passed, 1 failed
  SyntaxError: The requested module './bill.mjs' does not provide an export named 'splitBill'
not ok 1 - bill/bill.test.mjs
  error: 'test failed'
== round 3: 0 passed, 1 failed
  SyntaxError: The requested module './bill.mjs' does not provide an export named 'splitBill'
not ok 1 - bill/bill.test.mjs
  error: 'test failed'
== round 4: 0 passed, 1 failed
