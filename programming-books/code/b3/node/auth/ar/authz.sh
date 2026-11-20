# عمر يسجّل الدخول
$ OMAR=$(curl -s localhost:3000/auth/login -H 'content-type: application/json' -d '{"email":"omar@example.com","password":"omar-password-2026"}' | jq -r .token)
# طلباته هو
$ curl -s localhost:3000/orders -H "authorization: Bearer $OMAR" | jq -c
[{"id":3,"total":12000}]
# طلب سارة
$ curl -s localhost:3000/orders/1 -H "authorization: Bearer $OMAR" | jq
{
  "title": "غير موجود",
  "status": 404,
  "detail": "لا يوجد طلب 1.",
  "instance": "/orders/1"
}
# قائمة المدير، بصفة عمر
$ curl -s localhost:3000/admin/users -H "authorization: Bearer $OMAR" | jq
{
  "title": "غير مسموح",
  "status": 403,
  "detail": "هذا يحتاج الدور admin.",
  "instance": "/admin/users"
}
# قائمة المدير، بصفة مدير
$ ADMIN=$(curl -s localhost:3000/auth/login -H 'content-type: application/json' -d '{"email":"admin@example.com","password":"admin-password-2026"}' | jq -r .token)
$ curl -s localhost:3000/admin/users -H "authorization: Bearer $ADMIN" | jq -c ".[]"
{"id":1,"email":"sara@example.com","role":"customer"}
{"id":2,"email":"omar@example.com","role":"customer"}
{"id":3,"email":"admin@example.com","role":"admin"}
{"id":4,"email":"lina@example.com","role":"customer"}
