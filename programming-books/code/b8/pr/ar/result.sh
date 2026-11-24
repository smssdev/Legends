$ git log --oneline main..HEAD && git diff --stat main && cat PR.md
7483cfe fix(price): keep piastres when totalling a bill (#42)
 src/price.mjs       | 2 +-
 test/price.test.mjs | 1 +
 2 files changed, 2 insertions(+), 1 deletion(-)
## ماذا ولماذا

كانت الفواتير بالقروش تُجمع كأنها بلا قروش: `parseInt("85.50")` تساوي 85. وصارت `total` تقرأ الفاتورة بـ `Number`.

## كيف اختُبر

اختبار جديد: فاتورة 85.50 بنسبة 10% تعطي 94.05، مثال المهمة. وكل الاختبارات تنجح بـ `node --test`.

## يغلق

#42
