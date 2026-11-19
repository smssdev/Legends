# ماذا يرسل الخادم؟ (دون أي JavaScript)
$ curl -s localhost:3000/products | grep -oE '<a href="/products/[0-9]+"[^>]*>[^<]+'
<a href="/products/1" class="">البرمجة من الصفر
<a href="/products/2" class="">كوب بِت
<a href="/products/3" class="">قبعة بِت
# قائمة المنتجات مخزنة دقيقة
$ curl -sI localhost:3000/products | grep -i cache-control
cache-control: s-maxage=60, stale-while-revalidate
# مسار الخادم يُرجع JSON
$ curl -s localhost:3000/api/products
[{"id":1,"name":"البرمجة من الصفر","description":"الكتاب الأول الودود في السلسلة.","price":250},{"id":2,"name":"كوب بِت","description":"كوب كبير لليالي البرمجة الطويلة.","price":85},{"id":3,"name":"قبعة بِت","description":"تحمي عينيك من الشمس.","price":120}]
