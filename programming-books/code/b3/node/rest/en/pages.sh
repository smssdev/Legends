# The first page
$ curl -s 'localhost:3000/v1/products?limit=3' | jq -c '(.data[] | [.id, .name, .price.amount]), .next_cursor'
[1,"Robot kit",45000]
[2,"Spare wheels",6000]
[3,"Battery pack",12500]
"WzMsM10"
# The next page: send back the cursor you were given
$ curl -s 'localhost:3000/v1/products?limit=3&cursor=WzMsM10' | jq -c '(.data[] | [.id, .name, .price.amount]), .next_cursor'
[4,"USB cable",2500]
[5,"Servo motor",9000]
[6,"Sensor set",15000]
"WzYsNl0"
# Filter and sort: the cursor remembers both
$ curl -s 'localhost:3000/v1/products?limit=2&sort=-price&max_price=20000' | jq -c '(.data[] | [.id, .price.amount]), .next_cursor'
[6,15000]
[3,12500]
"WzEyNTAwLDNd"
$ curl -s 'localhost:3000/v1/products?limit=2&sort=-price&max_price=20000&cursor=WzEyNTAwLDNd' | jq -c '(.data[] | [.id, .price.amount]), .next_cursor'
[9,11000]
[5,9000]
"WzkwMDAsNV0"
