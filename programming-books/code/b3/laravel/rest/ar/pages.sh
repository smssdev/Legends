# الصفحة الأولى: data وlinks وmeta
$ curl -s 'localhost:8000/api/v1/products?limit=3' | jq -c '(.data[] | [.id, .name, .price.amount]), .links, .meta'
[1,"عدة الروبوت",45000]
[2,"عجلات احتياطية",6000]
[3,"حزمة بطارية",12500]
{"first":null,"last":null,"prev":null,"next":"http://localhost:8000/api/v1/products?limit=3&cursor=eyJpZCI6MywiX3BvaW50c1RvTmV4dEl0ZW1zIjp0cnVlfQ"}
{"path":"http://localhost:8000/api/v1/products","per_page":3,"next_cursor":"eyJpZCI6MywiX3BvaW50c1RvTmV4dEl0ZW1zIjp0cnVlfQ","prev_cursor":null}
# الصفحة التالية: اتبع next_cursor
$ curl -s "$(curl -s 'localhost:8000/api/v1/products?limit=3' | jq -r .links.next)" | jq -c '(.data[] | [.id, .name, .price.amount]), .meta.next_cursor'
[4,"كابل USB",2500]
[5,"محرك سيرفو",9000]
[6,"طقم حساسات",15000]
"eyJpZCI6NiwiX3BvaW50c1RvTmV4dEl0ZW1zIjp0cnVlfQ"
# التصفية والترتيب: المؤشر يتذكر الاثنين
$ curl -s 'localhost:8000/api/v1/products?limit=2&sort=-price&max_price=20000' | jq -c '(.data[] | [.id, .price.amount]), .links.next'
[6,15000]
[3,12500]
"http://localhost:8000/api/v1/products?limit=2&sort=-price&max_price=20000&cursor=eyJwcmljZSI6MTI1MDAsImlkIjozLCJfcG9pbnRzVG9OZXh0SXRlbXMiOnRydWV9"
