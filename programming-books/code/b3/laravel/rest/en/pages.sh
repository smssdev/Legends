# The first page: data, links and meta
$ curl -s 'localhost:8000/api/v1/products?limit=3' | jq -c '(.data[] | [.id, .name, .price.amount]), .links, .meta'
[1,"Robot kit",45000]
[2,"Spare wheels",6000]
[3,"Battery pack",12500]
{"first":null,"last":null,"prev":null,"next":"http://localhost:8000/api/v1/products?limit=3&cursor=eyJpZCI6MywiX3BvaW50c1RvTmV4dEl0ZW1zIjp0cnVlfQ"}
{"path":"http://localhost:8000/api/v1/products","per_page":3,"next_cursor":"eyJpZCI6MywiX3BvaW50c1RvTmV4dEl0ZW1zIjp0cnVlfQ","prev_cursor":null}
# The next page: follow next_cursor
$ curl -s "$(curl -s 'localhost:8000/api/v1/products?limit=3' | jq -r .links.next)" | jq -c '(.data[] | [.id, .name, .price.amount]), .meta.next_cursor'
[4,"USB cable",2500]
[5,"Servo motor",9000]
[6,"Sensor set",15000]
"eyJpZCI6NiwiX3BvaW50c1RvTmV4dEl0ZW1zIjp0cnVlfQ"
# Filter and sort: the cursor remembers both
$ curl -s 'localhost:8000/api/v1/products?limit=2&sort=-price&max_price=20000' | jq -c '(.data[] | [.id, .price.amount]), .links.next'
[6,15000]
[3,12500]
"http://localhost:8000/api/v1/products?limit=2&sort=-price&max_price=20000&cursor=eyJwcmljZSI6MTI1MDAsImlkIjozLCJfcG9pbnRzVG9OZXh0SXRlbXMiOnRydWV9"
