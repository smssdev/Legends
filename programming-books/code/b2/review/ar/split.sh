# انقل التنسيق إلى طلب دمج مستقل
$ git switch -c chore/format-styles main
Switched to a new branch 'chore/format-styles'
$ git checkout feature/discount-codes -- src/ui/styles.css
$ git commit -qm "نسّق ملف الأنماط"
$ git switch feature/discount-codes
Switched to branch 'feature/discount-codes'
$ git checkout main -- src/ui/styles.css
$ git commit -qm "أبقِ أكواد الخصم وحدها"
# طلب دمج الميزة بعد التقسيم
$ git diff --stat main
 src/cart/discount.ts | 11 +++++++++++
 1 file changed, 11 insertions(+)
