# لكل خطأ رمز حالة خاص به
# لا يوجد منتج كهذا
$ curl -s localhost:3000/products/99 -w ' %{http_code}\n'
{"error":{"code":"not_found","message":"لا يوجد منتج بهذا الرقم"}} 404
# طريقة لا يسمح بها هذا العنوان
$ curl -s -X DELETE localhost:3000/products -w ' %{http_code}\n'
{"error":{"code":"method_not_allowed","message":"استخدم GET أو POST هنا"}} 405
# محتوى ليس JSON
$ curl -s localhost:3000/products -d 'name=Cable' -w ' %{http_code}\n'
{"error":{"code":"unsupported_media_type","message":"أرسل JSON"}} 415
# JSON مكسور
$ curl -s localhost:3000/products -H 'Content-Type: application/json' -d '{"name": ' -w ' %{http_code}\n'
{"error":{"code":"bad_json","message":"المحتوى ليس JSON صالحاً"}} 400
# JSON، لكن الحقول خاطئة
$ curl -s localhost:3000/products -H 'Content-Type: application/json' -d '{"price": 9.5}' -w ' %{http_code}\n'
{"error":{"code":"invalid","message":"راجع الحقول","fields":{"name":"مطلوب","price":"عدد صحيح من القروش أكبر من 0"}}} 422
# كبير جداً
$ head -c 2000 /dev/zero | tr '\0' x | curl -s localhost:3000/products -H 'Content-Type: application/json' --data-binary @- -w ' %{http_code}\n'
{"error":{"code":"too_large","message":"الحد الأقصى 1 KB"}} 413
