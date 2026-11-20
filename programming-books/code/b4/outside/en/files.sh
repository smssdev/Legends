# The owner uploads a logo
$ curl -s localhost:3000/businesses/1/logo -H 'content-type: application/json' -d '{"type":"image/png","size":2048}' | tee .upload | jq -c '{key, url: (.url[:60] + "…")}'
{"key":"logos/1/a33963bc-6a6e-4c6e-86c8-69db3d8fa715.png","url":"http://localhost:8333/bit-booking/logos/1/a33963bc-6a6e-4c6e…"}
# The browser sends the file straight to storage
$ curl -s -o /dev/null -w '%{http_code}\n' -X PUT -H 'content-type: image/png' --upload-file logo.png "$URL"
200
# The server checks what was stored
$ curl -s localhost:3000/businesses/1/logo/confirm -H 'content-type: application/json' -d "{\"key\":\"$KEY\"}" | jq -c
{"logo":"logos/1/a33963bc-6a6e-4c6e-86c8-69db3d8fa715.png"}
# Someone uploads 3 MB with a URL signed for a logo
$ curl -s localhost:3000/businesses/1/logo -H 'content-type: application/json' -d '{"type":"image/png","size":2048}' > .upload
$ curl -s -o /dev/null -w '%{http_code}\n' -X PUT -H 'content-type: image/png' --upload-file big.png "$URL"
200
$ curl -s localhost:3000/businesses/1/logo/confirm -H 'content-type: application/json' -d "{\"key\":\"$KEY\"}" | jq -c
{"status":422,"title":"Logo too large"}
# A different file type than the one signed
$ curl -s -o /dev/null -w '%{http_code}\n' -X PUT -H 'content-type: text/html' --upload-file logo.png "$URL"
200
$ curl -s localhost:3000/businesses/1/logo/confirm -H 'content-type: application/json' -d "{\"key\":\"$KEY\"}" | jq -c
{"status":422,"title":"Logo must be PNG, JPEG or WebP"}
$ psql shop -c 'SELECT id, logo_key FROM businesses'
 id |                     logo_key                     
----+--------------------------------------------------
  1 | logos/1/a33963bc-6a6e-4c6e-86c8-69db3d8fa715.png
(1 row)
