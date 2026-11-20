# The owner uploads a logo
$ curl -s localhost:3000/businesses/1/logo -H 'content-type: application/json' -d '{"type":"image/png","size":2048}' | tee .upload | jq -c '{key, url: (.url[:60] + "…")}'
{"key":"logos/1/9befe137-daf8-4a61-8812-7f20c6c9949d.png","url":"http://localhost:8333/bit-booking/logos/1/9befe137-daf8-4a61…"}
# The browser sends the file straight to storage
$ curl -s -o /dev/null -w '%{http_code}\n' -X PUT -H 'content-type: image/png' --upload-file logo.png "$URL"
500
# The server checks what was stored
$ curl -s localhost:3000/businesses/1/logo/confirm -H 'content-type: application/json' -d "{\"key\":\"$KEY\"}" | jq -c
{"status":404,"title":"Not found"}
# Someone uploads 3 MB with a URL signed for a logo
$ curl -s localhost:3000/businesses/1/logo -H 'content-type: application/json' -d '{"type":"image/png","size":2048}' > .upload
$ curl -s -o /dev/null -w '%{http_code}\n' -X PUT -H 'content-type: image/png' --upload-file big.png "$URL"
500
$ curl -s localhost:3000/businesses/1/logo/confirm -H 'content-type: application/json' -d "{\"key\":\"$KEY\"}" | jq -c
{"status":404,"title":"Not found"}
# A different file type than the one signed
$ curl -s -o /dev/null -w '%{http_code}\n' -X PUT -H 'content-type: text/html' --upload-file logo.png "$URL"
500
$ curl -s localhost:3000/businesses/1/logo/confirm -H 'content-type: application/json' -d "{\"key\":\"$KEY\"}" | jq -c
{"status":404,"title":"Not found"}
$ psql shop -c 'SELECT id, logo_key FROM businesses'
 id | logo_key 
----+----------
  1 | 
(1 row)
