# فرع جديد لميزة جديدة
$ git switch -c contact
Switched to a new branch 'contact'
# أنشئ contact.html، ثم:
$ git add contact.html
$ git commit -m "إضافة قسم التواصل"
[contact 6090844] إضافة قسم التواصل
 1 file changed, 1 insertion(+)
 create mode 100644 contact.html
# العودة إلى الفرع الرئيسي: يختفي contact.html من المجلد
$ git switch main
Switched to branch 'main'
# ادمج الميزة
$ git merge contact
Updating f42d185..6090844
Fast-forward
 contact.html | 1 +
 1 file changed, 1 insertion(+)
 create mode 100644 contact.html
$ git log --oneline --graph
* 6090844 إضافة قسم التواصل
* f42d185 إضافة الوصف
* 166f9d5 إضافة الصفحة التعريفية
