# عذراً: تعديل لم تقصده
$ git status --short
 M journal.md
# تخلّص من التغيير في هذا الملف
$ git restore journal.md
$ git status --short
# الآن اكتب اليوم 3 كما يجب، ثم:
$ git commit -q -am "اليوم 3"
# commit تندم عليه، وقد حُفظ
$ git add quote.md
$ git commit -q -m "إضافة اقتباس عشوائي"
# ألغِه بـ commit جديد، فيبقى التاريخ صادقاً
$ git revert --no-edit HEAD
[main c089223] Revert "إضافة اقتباس عشوائي"
 1 file changed, 1 deletion(-)
 delete mode 100644 quote.md
$ git log --oneline
c089223 Revert "إضافة اقتباس عشوائي"
e2ca80a إضافة اقتباس عشوائي
e8f4536 اليوم 3
b9d7cf2 اليوم 2
bf34050 اليوم 1
eb4e70b بداية الدفتر
