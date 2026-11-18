# ابدأ تتبّع هذا المجلد
$ git init
Initialized empty Git repository in /Users/sara/code-from-zero/profile/.git/
$ git status --short
?? index.html
?? style.css
# اختر ما يدخل اللقطة التالية
$ git add index.html style.css
$ git status --short
A  index.html
A  style.css
# احفظ اللقطة مع رسالة
$ git commit -m "إضافة الصفحة التعريفية"
[main (root-commit) 166f9d5] إضافة الصفحة التعريفية
 2 files changed, 2 insertions(+)
 create mode 100644 index.html
 create mode 100644 style.css
