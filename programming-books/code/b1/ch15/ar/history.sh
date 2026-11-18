# عدّل index.html في VS Code، ثم:
# ما الذي تغيّر منذ آخر commit؟
$ git diff
diff --git a/index.html b/index.html
index 6732327..0525cbc 100644
--- a/index.html
+++ b/index.html
@@ -1 +1,2 @@
 <h1>سارة خان</h1>
+<p>مطورة ويب مبتدئة</p>
$ git commit -am "إضافة الوصف"
[main f42d185] إضافة الوصف
 1 file changed, 1 insertion(+)
# التاريخ، الأحدث أولاً
$ git log --oneline
f42d185 إضافة الوصف
166f9d5 إضافة الصفحة التعريفية
