# الصفحة الأولى
$ curl -s 'localhost:3000/v1/products?limit=3' | jq -c '(.data[] | [.id, .name, .price.amount]), .next_cursor'
[1,"عدة الروبوت",45000]
[2,"عجلات احتياطية",6000]
[3,"حزمة بطارية",12500]
"WzMsM10"
# الصفحة التالية: أعد المؤشر الذي أُعطيته
$ curl -s 'localhost:3000/v1/products?limit=3&cursor=WzMsM10' | jq -c '(.data[] | [.id, .name, .price.amount]), .next_cursor'
[4,"كابل USB",2500]
[5,"محرك سيرفو",9000]
[6,"طقم حساسات",15000]
"WzYsNl0"
# التصفية والترتيب: المؤشر يتذكر الاثنين
$ curl -s 'localhost:3000/v1/products?limit=2&sort=-price&max_price=20000' | jq -c '(.data[] | [.id, .price.amount]), .next_cursor'
[6,15000]
[3,12500]
"WzEyNTAwLDNd"
$ curl -s 'localhost:3000/v1/products?limit=2&sort=-price&max_price=20000&cursor=WzEyNTAwLDNd' | jq -c '(.data[] | [.id, .price.amount]), .next_cursor'
[9,11000]
[5,9000]
"WzkwMDAsNV0"
