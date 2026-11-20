# اختبار يفشل
$ BUG=1 npm test -- test/pricing.test.ts
✖ failing tests:
test at test/pricing.test.ts:28:5
✖ بلا كود: المجموع والضريبة (…ms)
  AssertionError [ERR_ASSERTION]: Expected values to be partially and strictly deep-equal:
  + actual - expected
  
    {
      discount: 0,
  +   subtotal: 57000,
  +   total: 65550,
  +   vat: 8550
  -   total: 64980,
  -   vat: 7980
    }
  
      at TestContext.<anonymous> (file://test/pricing.test.ts:29:14)
      at Test.runInAsyncScope (node:async_hooks:214:14)
