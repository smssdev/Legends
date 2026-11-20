# ماذا يرسل الخادم؟ (دون أي JavaScript)
$ curl -s localhost:3000/products | grep -oE '<li><a href="[^"]+">[^<]+'
<li><a href="/products/1">البرمجة من الصفر
<li><a href="/products/2">كوب بِت
<li><a href="/products/3">قبعة بِت
# معالج المسار يُرجع JSON
$ curl -s localhost:3000/api/products
[{"id":1,"name":"البرمجة من الصفر","description":"الكتاب الأول الودود في السلسلة.","price":250},{"id":2,"name":"كوب بِت","description":"كوب كبير لليالي البرمجة الطويلة.","price":85},{"id":3,"name":"قبعة بِت","description":"تحمي عينيك من الشمس.","price":120}]
