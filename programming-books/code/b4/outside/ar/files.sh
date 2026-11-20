# صاحبة العمل ترفع شعاراً
$ curl -s localhost:3000/businesses/1/logo -H 'content-type: application/json' -d '{"type":"image/png","size":2048}' | tee .upload | jq -c '{key, url: (.url[:60] + "…")}'
{"key":"logos/1/306d60df-566a-4719-8fed-040c1773ad48.png","url":"http://localhost:8333/bit-booking/logos/1/306d60df-566a-4719…"}
# المتصفح يرسل الملف مباشرة إلى المخزن
$ curl -s -o /dev/null -w '%{http_code}\n' -X PUT -H 'content-type: image/png' --upload-file logo.png "$URL"
500
# الخادم يفحص ما خُزّن
$ curl -s localhost:3000/businesses/1/logo/confirm -H 'content-type: application/json' -d "{\"key\":\"$KEY\"}" | jq -c
{"status":404,"title":"غير موجود"}
# أحدهم يرفع 3 MB برابط موقَّع لشعار
$ curl -s localhost:3000/businesses/1/logo -H 'content-type: application/json' -d '{"type":"image/png","size":2048}' > .upload
$ curl -s -o /dev/null -w '%{http_code}\n' -X PUT -H 'content-type: image/png' --upload-file big.png "$URL"
500
$ curl -s localhost:3000/businesses/1/logo/confirm -H 'content-type: application/json' -d "{\"key\":\"$KEY\"}" | jq -c
{"status":404,"title":"غير موجود"}
# نوع ملف غير الذي وُقّع
$ curl -s -o /dev/null -w '%{http_code}\n' -X PUT -H 'content-type: text/html' --upload-file logo.png "$URL"
500
$ curl -s localhost:3000/businesses/1/logo/confirm -H 'content-type: application/json' -d "{\"key\":\"$KEY\"}" | jq -c
{"status":404,"title":"غير موجود"}
$ psql shop -c 'SELECT id, logo_key FROM businesses'
 id | logo_key 
----+----------
  1 | 
(1 row)
